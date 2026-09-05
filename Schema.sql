USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'SubastasPrivadas_DB')
BEGIN
    ALTER DATABASE SubastasPrivadas_DB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SubastasPrivadas_DB;
END
GO

CREATE DATABASE SubastasPrivadas_DB;
GO

USE SubastasPrivadas_DB;
GO

-- ============================================================================
-- MÓDULO 1: ROLES, USUARIOS Y AUTENTICACIÓN (5 Tablas)
-- ============================================================================

-- 1. Roles del Sistema
CREATE TABLE Roles (
    RolID INT IDENTITY(1,1) PRIMARY KEY,
    NombreRol NVARCHAR(50) UNIQUE NOT NULL,
    Descripcion NVARCHAR(200)
);

-- 2. Usuarios Principales
CREATE TABLE Usuarios (
    UsuarioID INT IDENTITY(1,1) PRIMARY KEY,
    RolID INT NOT NULL,
    Nombre NVARCHAR(100) NOT NULL,
    Apellido NVARCHAR(100) NOT NULL,
    Correo NVARCHAR(150) UNIQUE NOT NULL,
    Telefono NVARCHAR(20),
    EstadoCuenta NVARCHAR(20) DEFAULT 'Activo' CHECK (EstadoCuenta IN ('Pendiente', 'Activo', 'Suspendido', 'Bloqueado')),
    FechaRegistro DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (RolID) REFERENCES Roles(RolID)
);

-- 3. Credenciales y Contraseñas (Hash seguro)
CREATE TABLE Credenciales (
    CredencialID INT IDENTITY(1,1) PRIMARY KEY,
    UsuarioID INT UNIQUE NOT NULL,
    PasswordHash NVARCHAR(256) NOT NULL,
    PasswordSalt NVARCHAR(128) NOT NULL,
    UltimoCambio DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID)
);

-- 4. Historial de Inicios de Sesión (Log de Autenticación)
CREATE TABLE HistorialSesiones (
    SesionID INT IDENTITY(1,1) PRIMARY KEY,
    UsuarioID INT NOT NULL,
    FechaIngreso DATETIME DEFAULT GETDATE(),
    DireccionIP NVARCHAR(45),
    UserAgent NVARCHAR(255),
    Exitoso BIT NOT NULL,
    FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID)
);

-- 5. Solicitudes de Recuperación de Contraseña
CREATE TABLE TokensRecuperacion (
    TokenID INT IDENTITY(1,1) PRIMARY KEY,
    UsuarioID INT NOT NULL,
    TokenHash NVARCHAR(256) NOT NULL,
    FechaCreacion DATETIME DEFAULT GETDATE(),
    FechaExpiracion DATETIME NOT NULL,
    Utilizado BIT DEFAULT 0,
    FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID)
);


-- ============================================================================
-- MÓDULO 2: CATÁLOGO, CATEGORÍAS Y ARTÍCULOS (4 Tablas)
-- ============================================================================

-- 6. Categorías de Bienes
CREATE TABLE Categorias (
    CategoriaID INT IDENTITY(1,1) PRIMARY KEY,
    NombreCategoria NVARCHAR(100) NOT NULL,
    Descripcion NVARCHAR(255)
);

-- 7. Subcategorías
CREATE TABLE Subcategorias (
    SubcategoriaID INT IDENTITY(1,1) PRIMARY KEY,
    CategoriaID INT NOT NULL,
    NombreSubcategoria NVARCHAR(100) NOT NULL,
    FOREIGN KEY (CategoriaID) REFERENCES Categorias(CategoriaID)
);

-- 8. Artículos / Lotes
CREATE TABLE Articulos (
    ArticuloID INT IDENTITY(1,1) PRIMARY KEY,
    VendedorID INT NOT NULL,
    SubcategoriaID INT NOT NULL,
    Titulo NVARCHAR(150) NOT NULL,
    Descripcion NVARCHAR(MAX),
    PrecioBase DECIMAL(12,2) NOT NULL,
    EstadoConservacion NVARCHAR(50),
    FOREIGN KEY (VendedorID) REFERENCES Usuarios(UsuarioID),
    FOREIGN KEY (SubcategoriaID) REFERENCES Subcategorias(SubcategoriaID)
);

-- 9. Galería de Imágenes de Artículos
CREATE TABLE ImagenesArticulo (
    ImagenID INT IDENTITY(1,1) PRIMARY KEY,
    ArticuloID INT NOT NULL,
    URLImagen NVARCHAR(500) NOT NULL,
    EsPrincipal BIT DEFAULT 0,
    FOREIGN KEY (ArticuloID) REFERENCES Articulos(ArticuloID)
);


-- ============================================================================
-- MÓDULO 3: EVENTOS DE SUBASTA Y PUJAS (4 Tablas)
-- ============================================================================

-- 10. Subastas
CREATE TABLE Subastas (
    SubastaID INT IDENTITY(1,1) PRIMARY KEY,
    ArticuloID INT NOT NULL,
    FechaInicio DATETIME NOT NULL,
    FechaFin DATETIME NOT NULL,
    PrecioInicial DECIMAL(12,2) NOT NULL,
    PrecioActual DECIMAL(12,2) NOT NULL,
    IncrementoMinimo DECIMAL(10,2) NOT NULL DEFAULT 50.00,
    Estado NVARCHAR(20) DEFAULT 'Programada' CHECK (Estado IN ('Programada', 'Activa', 'Finalizada', 'Cancelada', 'Desierta')),
    FOREIGN KEY (ArticuloID) REFERENCES Articulos(ArticuloID)
);

-- 11. Historial de Pujas (Ofertas)
CREATE TABLE Pujas (
    PujaID INT IDENTITY(1,1) PRIMARY KEY,
    SubastaID INT NOT NULL,
    PostorID INT NOT NULL,
    MontoOferta DECIMAL(12,2) NOT NULL,
    FechaPuja DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (SubastaID) REFERENCES Subastas(SubastaID),
    FOREIGN KEY (PostorID) REFERENCES Usuarios(UsuarioID)
);

-- 12. Pujas Automáticas (Auto-bidding)
CREATE TABLE PujasAutomaticas (
    AutoPujaID INT IDENTITY(1,1) PRIMARY KEY,
    SubastaID INT NOT NULL,
    PostorID INT NOT NULL,
    MontoMaximo DECIMAL(12,2) NOT NULL,
    Activo BIT DEFAULT 1,
    FOREIGN KEY (SubastaID) REFERENCES Subastas(SubastaID),
    FOREIGN KEY (PostorID) REFERENCES Usuarios(UsuarioID)
);

-- 13. Lista de Favoritos / Seguimiento
CREATE TABLE Favoritos (
    FavoritoID INT IDENTITY(1,1) PRIMARY KEY,
    UsuarioID INT NOT NULL,
    SubastaID INT NOT NULL,
    FechaAgregado DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID),
    FOREIGN KEY (SubastaID) REFERENCES Subastas(SubastaID)
);


-- ============================================================================
-- MÓDULO 4: PAGOS, BILLETERA Y TRANSACCIONES (5 Tablas)
-- ============================================================================

-- 14. Métodos de Pago Registrados
CREATE TABLE MetodosPago (
    MetodoPagoID INT IDENTITY(1,1) PRIMARY KEY,
    UsuarioID INT NOT NULL,
    TipoMetodo NVARCHAR(50) CHECK (TipoMetodo IN ('Tarjeta_Credito', 'Tarjeta_Debito', 'Transferencia_Bancaria', 'Billetera_Digital')),
    Proveedor NVARCHAR(50), -- Ej. Visa, Mastercard, BAC
    UltimosDigitos VARCHAR(4),
    TokenPasarela NVARCHAR(255),
    EsPredeterminado BIT DEFAULT 0,
    FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID)
);

-- 15. Certificados de Adjudicación
CREATE TABLE Certificados (
    CertificadoID INT IDENTITY(1,1) PRIMARY KEY,
    SubastaID INT NOT NULL UNIQUE,
    GanadorID INT NOT NULL,
    MontoFinal DECIMAL(12,2) NOT NULL,
    FechaEmision DATETIME DEFAULT GETDATE(),
    CodigoVerificacion UNIQUEIDENTIFIER DEFAULT NEWID(),
    FOREIGN KEY (SubastaID) REFERENCES Subastas(SubastaID),
    FOREIGN KEY (GanadorID) REFERENCES Usuarios(UsuarioID)
);

-- 16. Facturas / Ordenes de Compra
CREATE TABLE Ordenes (
    OrdenID INT IDENTITY(1,1) PRIMARY KEY,
    CertificadoID INT NOT NULL UNIQUE,
    CompradorID INT NOT NULL,
    MontoSubtotal DECIMAL(12,2) NOT NULL,
    MontoComision DECIMAL(12,2) NOT NULL,
    MontoTotal DECIMAL(12,2) NOT NULL,
    EstadoOrden NVARCHAR(20) DEFAULT 'Pendiente' CHECK (EstadoOrden IN ('Pendiente', 'Pagado', 'Cancelado')),
    FechaCreacion DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (CertificadoID) REFERENCES Certificados(CertificadoID),
    FOREIGN KEY (CompradorID) REFERENCES Usuarios(UsuarioID)
);

-- 17. Historial de Transacciones / Cobros
CREATE TABLE Transacciones (
    TransaccionID INT IDENTITY(1,1) PRIMARY KEY,
    OrdenID INT NOT NULL,
    MetodoPagoID INT NOT NULL,
    Monto DECIMAL(12,2) NOT NULL,
    EstadoTransaccion NVARCHAR(20) CHECK (EstadoTransaccion IN ('Aprobada', 'Rechazada', 'En_Proceso', 'Reembolsada')),
    CodigoAutorizacion NVARCHAR(100),
    FechaTransaccion DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (OrdenID) REFERENCES Ordenes(OrdenID),
    FOREIGN KEY (MetodoPagoID) REFERENCES MetodosPago(MetodoPagoID)
);

-- 18. Saldo en Plataforma / Reembolsos (Billetera Interna)
CREATE TABLE BilleteraVirtual (
    BilleteraID INT IDENTITY(1,1) PRIMARY KEY,
    UsuarioID INT NOT NULL UNIQUE,
    SaldoDisponible DECIMAL(12,2) DEFAULT 0.00,
    SaldoBloqueado DECIMAL(12,2) DEFAULT 0.00, -- Retenido mientras la subasta está activa
    FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID)
);


-- ============================================================================
-- MÓDULO 5: LOGÍSTICA, RECLAMOS Y AUDITORÍA (7 Tablas)
-- ============================================================================

-- 19. Direcciones de Envío
CREATE TABLE Direcciones (
    DireccionID INT IDENTITY(1,1) PRIMARY KEY,
    UsuarioID INT NOT NULL,
    DireccionTexto NVARCHAR(255) NOT NULL,
    Ciudad NVARCHAR(100) NOT NULL,
    Departamento NVARCHAR(100) NOT NULL,
    CodigoPostal NVARCHAR(10),
    FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID)
);

-- 20. Envíos y Despacho
CREATE TABLE Envios (
    EnvioID INT IDENTITY(1,1) PRIMARY KEY,
    OrdenID INT NOT NULL UNIQUE,
    DireccionID INT NOT NULL,
    EmpresaTransporte NVARCHAR(100),
    NumeroRastreo NVARCHAR(100),
    EstadoEnvio NVARCHAR(20) DEFAULT 'Preparando' CHECK (EstadoEnvio IN ('Preparando', 'En_Transito', 'Entregado', 'Devuelto')),
    FechaEnvio DATETIME,
    FechaEntregaEstimada DATETIME,
    FOREIGN KEY (OrdenID) REFERENCES Ordenes(OrdenID),
    FOREIGN KEY (DireccionID) REFERENCES Direcciones(DireccionID)
);

-- 21. Notificaciones al Usuario
CREATE TABLE Notificaciones (
    NotificacionID INT IDENTITY(1,1) PRIMARY KEY,
    UsuarioID INT NOT NULL,
    Titulo NVARCHAR(100) NOT NULL,
    Mensaje NVARCHAR(MAX) NOT NULL,
    Leido BIT DEFAULT 0,
    FechaEnvio DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID)
);

-- 22. Valoraciones y Reseñas
CREATE TABLE Calificaciones (
    CalificacionID INT IDENTITY(1,1) PRIMARY KEY,
    OrdenID INT NOT NULL UNIQUE,
    CalificadorID INT NOT NULL,
    CalificadoID INT NOT NULL,
    Puntuacion INT CHECK (Puntuacion BETWEEN 1 AND 5),
    Comentario NVARCHAR(500),
    FechaCalificacion DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (OrdenID) REFERENCES Ordenes(OrdenID),
    FOREIGN KEY (CalificadorID) REFERENCES Usuarios(UsuarioID),
    FOREIGN KEY (CalificadoID) REFERENCES Usuarios(UsuarioID)
);

-- 23. Disputas / Reclamos
CREATE TABLE Disputas (
    DisputaID INT IDENTITY(1,1) PRIMARY KEY,
    OrdenID INT NOT NULL,
    ReclamanteID INT NOT NULL,
    Motivo NVARCHAR(100) NOT NULL,
    Descripcion NVARCHAR(MAX),
    EstadoDisputa NVARCHAR(20) DEFAULT 'Abierta' CHECK (EstadoDisputa IN ('Abierta', 'En_Revision', 'Resuelta', 'Cerrada')),
    FechaApertura DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (OrdenID) REFERENCES Ordenes(OrdenID),
    FOREIGN KEY (ReclamanteID) REFERENCES Usuarios(UsuarioID)
);

-- 24. Bitácora de Cambios / Auditoría General
CREATE TABLE LogsAuditoria (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    UsuarioID INT NULL,
    Accion NVARCHAR(100) NOT NULL,
    TablaAfectada NVARCHAR(50) NOT NULL,
    Detalle NVARCHAR(MAX),
    FechaAccion DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID)
);

-- 25. Configuración Global del Sistema
CREATE TABLE ParametrosSistema (
    ParametroID INT IDENTITY(1,1) PRIMARY KEY,
    Clave NVARCHAR(50) UNIQUE NOT NULL,
    Valor NVARCHAR(255) NOT NULL,
    Descripcion NVARCHAR(255)
);
GO

-- ============================================================================
-- DATOS INICIALES DE PRUEBA Y CONFIGURACIÓN
-- ============================================================================

INSERT INTO Roles (NombreRol, Descripcion) VALUES 
('Administrador', 'Control total de la plataforma'),
('Vendedor', 'Usuario verificado para publicar artículos'),
('Postor', 'Usuario registrado para realizar ofertas');

INSERT INTO ParametrosSistema (Clave, Valor, Descripcion) VALUES 
('PorcentajeComision', '0.05', 'Comisión del 5% por subasta ganada'),
('TiempoInactividadMinutos', '30', 'Tiempo de sesión antes de expiración');

INSERT INTO Categorias (NombreCategoria, Descripcion) VALUES 
('Arte y Coleccionables', 'Pinturas, esculturas y artefactos históricos'),
('Vehículos de Época', 'Automóviles clásicos y motocicletas de colección');

INSERT INTO Subcategorias (CategoriaID, NombreSubcategoria) VALUES 
(1, 'Óleos y Lienzos'),
(2, 'Autos Antiguos (Pre-1980)');

INSERT INTO Usuarios (RolID, Nombre, Apellido, Correo, Telefono, EstadoCuenta) VALUES 
(1, 'Admin', 'Sistema', 'admin@subastas.com', '55550000', 'Activo'),
(2, 'Galería', 'Nacional', 'contacto@galeria.com', '55551111', 'Activo'),
(3, 'Carlos', 'Mendoza', 'cmendoza@cliente.com', '55552222', 'Activo');

INSERT INTO Credenciales (UsuarioID, PasswordHash, PasswordSalt) VALUES 
(1, 'hash_admin_123', 'salt_123'),
(2, 'hash_galeria_123', 'salt_456'),
(3, 'hash_carlos_123', 'salt_789');

INSERT INTO BilleteraVirtual (UsuarioID, SaldoDisponible, SaldoBloqueado) VALUES 
(1, 0.00, 0.00),
(2, 0.00, 0.00),
(3, 10000.00, 0.00);

INSERT INTO Articulos (VendedorID, SubcategoriaID, Titulo, Descripcion, PrecioBase, EstadoConservacion) VALUES 
(2, 1, 'Óleo sobre lienzo - Siglo XIX', 'Obra original restaurada con certificado.', 5000.00, 'Excelente');

INSERT INTO Subastas (ArticuloID, FechaInicio, FechaFin, PrecioInicial, PrecioActual, Estado) VALUES 
(1, GETDATE(), DATEADD(day, 7, GETDATE()), 5000.00, 5500.00, 'Activa');

INSERT INTO Pujas (SubastaID, PostorID, MontoOferta) VALUES 
(1, 3, 5500.00);

GO

-- Consulta global de verificación
SELECT 
    s.SubastaID,
    a.Titulo AS Articulo,
    c.NombreCategoria,
    s.PrecioActual,
    u.Nombre + ' ' + u.Apellido AS UltimoPostor,
    p.FechaPuja
FROM Subastas s
JOIN Articulos a ON s.ArticuloID = a.ArticuloID
JOIN Subcategorias sub ON a.SubcategoriaID = sub.SubcategoriaID
JOIN Categorias c ON sub.CategoriaID = c.CategoriaID
LEFT JOIN Pujas p ON s.SubastaID = p.SubastaID AND p.MontoOferta = s.PrecioActual
LEFT JOIN Usuarios u ON p.PostorID = u.UsuarioID;
GO