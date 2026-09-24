USE SubastasPrivadas_DB;
GO

-- 1. Procediemento Almacenado: Motor de Pujas (CONCURRENCIA Y VALIDACIÓN)***
IF OBJECT_ID('sp_RealizarPuja', 'P') IS NOT NULL
    DROP PROCEDURE sp_RealizarPuja;
GO

CREATE PROCEDURE sp_RealizarPuja
    @SubastaID INT,
    @PostorID INT,
    @MontoOferta DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Manejo estricto de transacciones para control de concurrencia
    BEGIN TRANSACTION;

    BEGIN TRY
        DECLARE @Estado NVARCHAR(20);
        DECLARE @FechaFin DATETIME;
        DECLARE @PrecioActual DECIMAL(12,2);
        DECLARE @IncrementoMinimo DECIMAL(10,2);

        -- Bloqueo de lectura exclusiva (XLOCK) para evitar condiciones de carrera (Race Conditions)
        SELECT 
            @Estado = Estado,
            @FechaFin = FechaFin,
            @PrecioActual = PrecioActual,
            @IncrementoMinimo = IncrementoMinimo
        FROM Subastas WITH (XLOCK, ROWLOCK)
        WHERE SubastaID = @SubastaID;

        -- Validaciones de Negocio
        IF @Estado IS NULL
        BEGIN
            RAISERROR('La subasta especificada no existe.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @Estado <> 'Activa' OR GETDATE() > @FechaFin
        BEGIN
            RAISERROR('La subasta no se encuentra activa o el tiempo ha expirado.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @MontoOferta < (@PrecioActual + @IncrementoMinimo)
        BEGIN
            DECLARE @ErrorMsg NVARCHAR(250) = CONCAT('El monto debe ser al menos ', @PrecioActual + @IncrementoMinimo);
            RAISERROR(@ErrorMsg, 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Registrar la puja
        INSERT INTO Pujas (SubastaID, PostorID, MontoOferta, FechaPuja)
        VALUES (@SubastaID, @PostorID, @MontoOferta, GETDATE());

        -- Actualizar el precio actual de la subasta
        UPDATE Subastas
        SET PrecioActual = @MontoOferta
        WHERE SubastaID = @SubastaID;

        COMMIT TRANSACTION;
        PRINT 'Puja registrada exitosamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- 2. Procedimiento Almacendado: LIQUIDACIÓN Y COBRO AUTOMÁTICO ****

IF OBJECT_ID('sp_LiquidarSubasta', 'P') IS NOT NULL
    DROP PROCEDURE sp_LiquidarSubasta;
GO

CREATE PROCEDURE sp_LiquidarSubasta
    @SubastaID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;

    BEGIN TRY
        DECLARE @Estado NVARCHAR(20);
        DECLARE @GanadorID INT;
        DECLARE @MontoGanador DECIMAL(12,2);
        DECLARE @PorcentajeComision DECIMAL(5,4);
        DECLARE @Comision DECIMAL(12,2);
        DECLARE @CertificadoID INT;

        -- Obtener estado de la subasta
        SELECT @Estado = Estado FROM Subastas WHERE SubastaID = @SubastaID;

        IF @Estado <> 'Activa'
        BEGIN
            RAISERROR('Solo se pueden liquidar subastas en estado Activa.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Determinar la puja mas alta
        SELECT TOP 1 
            @GanadorID = PostorID,
            @MontoGanador = MontoOferta
        FROM Pujas
        WHERE SubastaID = @SubastaID
        ORDER BY MontoOferta DESC, FechaPuja ASC;

        -- Si no hubo pujas, declarar desierta
        IF @GanadorID IS NULL
        BEGIN
            UPDATE Subastas SET Estado = 'Desierta' WHERE SubastaID = @SubastaID;
            COMMIT TRANSACTION;
            PRINT 'Subasta finalizada sin ofertas (Desierta).';
            RETURN;
        END

        -- Obtener porcentaje de comision global
        SELECT @PorcentajeComision = CAST(Valor AS DECIMAL(5,4)) 
        FROM ParametrosSistema 
        WHERE Clave = 'PorcentajeComision';

        IF @PorcentajeComision IS NULL SET @PorcentajeComision = 0.05;

        SET @Comision = @MontoGanador * @PorcentajeComision;

        -- 1. Cambiar estado de la subasta
        UPDATE Subastas SET Estado = 'Finalizada' WHERE SubastaID = @SubastaID;

        -- 2. Emitir Certificado de Adjudicacion
        INSERT INTO Certificados (SubastaID, GanadorID, MontoFinal)
        VALUES (@SubastaID, @GanadorID, @MontoGanador);

        SET @CertificadoID = SCOPE_IDENTITY();

        -- 3. Generar Orden de Pago y Comision
        INSERT INTO Ordenes (CertificadoID, CompradorID, MontoSubtotal, MontoComision, MontoTotal)
        VALUES (@CertificadoID, @GanadorID, @MontoGanador, @Comision, @MontoGanador + @Comision);

        COMMIT TRANSACTION;
        PRINT 'Subasta liquidada exitosamente. Certificado y Orden de pago generados.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- 3. Trigger de auditoría de posturas 

IF OBJECT_ID('trg_AuditoriaPujas', 'TR') IS NOT NULL
    DROP TRIGGER trg_AuditoriaPujas;
GO

CREATE TRIGGER trg_AuditoriaPujas
ON Pujas
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO LogsAuditoria (UsuarioID, Accion, TablaAfectada, Detalle)
    SELECT 
        i.PostorID,
        'NUEVA_PUJA',
        'Pujas',
        CONCAT('Puja registrada por ', i.MontoOferta, ' en Subasta ID ', i.SubastaID)
    FROM inserted i;
END;
GO

-- 4. Vistas Gerenciales

-- Vista de Subastas Activas
CREATE OR ALTER VIEW vw_SubastasActivas AS
SELECT 
    s.SubastaID,
    a.Titulo AS Articulo,
    s.PrecioInicial,
    s.PrecioActual,
    s.FechaInicio,
    s.FechaFin,
    COUNT(p.PujaID) AS TotalOfertas
FROM Subastas s
JOIN Articulos a ON s.ArticuloID = a.ArticuloID
LEFT JOIN Pujas p ON s.SubastaID = p.SubastaID
WHERE s.Estado = 'Activa'
GROUP BY s.SubastaID, a.Titulo, s.PrecioInicial, s.PrecioActual, s.FechaInicio, s.FechaFin;
GO

-- Vista de Reporte de Comisiones
CREATE OR ALTER VIEW vw_ReporteComisiones AS
SELECT 
    o.OrdenID,
    c.CertificadoID,
    u.Nombre + ' ' + u.Apellido AS Comprador,
    o.MontoSubtotal AS Venta,
    o.MontoComision AS GananciaPlataforma,
    o.MontoTotal,
    o.FechaCreacion
FROM Ordenes o
JOIN Certificados c ON o.CertificadoID = c.CertificadoID
JOIN Usuarios u ON o.CompradorID = u.UsuarioID;
GO