USE master;
GO

-- 1. Cerrar conexiones y reiniciar la base de datos
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

-- 2. Tabla de Usuarios (Postores y Vendedores/Administradores)
CREATE TABLE Usuarios (
    UsuarioID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL,
    Correo NVARCHAR(100) UNIQUE NOT NULL,
    Rol NVARCHAR(20) NOT NULL CHECK (Rol IN ('Postor', 'Vendedor', 'Administrador')),
    FechaRegistro DATETIME DEFAULT GETDATE()
);

-- 3. Categorías de Artículos (Arte, Joyería, Vehículos de Colección, etc.)
CREATE TABLE Categorias (
    CategoriaID INT IDENTITY(1,1) PRIMARY KEY,
    NombreCategoria NVARCHAR(100) NOT NULL,
    Descripcion NVARCHAR(255)
);

-- 4. Artículos / Lotes a Subastar
CREATE TABLE Articulos (
    ArticuloID INT IDENTITY(1,1) PRIMARY KEY,
    Titulo NVARCHAR(150) NOT NULL,
    Descripcion NVARCHAR(MAX),
    PrecioBase DECIMAL(12,2) NOT NULL,
    CategoriaID INT NOT NULL,
    VendedorID INT NOT NULL,
    FOREIGN KEY (CategoriaID) REFERENCES Categorias(CategoriaID),
    FOREIGN KEY (VendedorID) REFERENCES Usuarios(UsuarioID)
);

-- 5. Subastas (Eventos activos)
CREATE TABLE Subastas (
    SubastaID INT IDENTITY(1,1) PRIMARY KEY,
    ArticuloID INT NOT NULL,
    FechaInicio DATETIME NOT NULL,
    FechaFin DATETIME NOT NULL,
    PrecioActual DECIMAL(12,2) NOT NULL,
    Estado NVARCHAR(20) NOT NULL DEFAULT 'Programada' CHECK (Estado IN ('Programada', 'Activa', 'Finalizada', 'Cancelada')),
    FOREIGN KEY (ArticuloID) REFERENCES Articulos(ArticuloID)
);

-- 6. Historial de Pujas (Ofertas en tiempo real)
CREATE TABLE Pujas (
    PujaID INT IDENTITY(1,1) PRIMARY KEY,
    SubastaID INT NOT NULL,
    PostorID INT NOT NULL,
    MontoOferta DECIMAL(12,2) NOT NULL,
    FechaPuja DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (SubastaID) REFERENCES Subastas(SubastaID),
    FOREIGN KEY (PostorID) REFERENCES Usuarios(UsuarioID)
);

-- 7. Certificados / Adjudicaciones
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
GO

-- =============================================
-- DATOS DE PRUEBA DE SUBASTAS
-- =============================================

INSERT INTO Categorias (NombreCategoria, Descripcion) VALUES 
('Arte y Pintura', 'Obras de arte clasico y contemporaneo'),
('Relojería fina', 'Piezas de alta relojería y coleccionismo');

INSERT INTO Usuarios (Nombre, Correo, Rol) VALUES 
('Galería Central', 'contacto@galeriacentral.com', 'Vendedor'),
('Carlos Mendoza', 'cmendoza@cliente.com', 'Postor'),
('Admin Subastas', 'admin@subastas.com', 'Administrador');

INSERT INTO Articulos (Titulo, Descripcion, PrecioBase, CategoriaID, VendedorID) VALUES 
('Óleo sobre lienzo - Siglo XIX', 'Obra original restaurada con certificado de autenticidad.', 5000.00, 1, 1);

INSERT INTO Subastas (ArticuloID, FechaInicio, FechaFin, PrecioActual, Estado) VALUES 
(1, GETDATE(), DATEADD(day, 7, GETDATE()), 5000.00, 'Activa');

INSERT INTO Pujas (SubastaID, PostorID, MontoOferta) VALUES 
(1, 2, 5500.00);

-- Actualizar el precio de la subasta tras la puja
UPDATE Subastas SET PrecioActual = 5500.00 WHERE SubastaID = 1;
GO

-- Consulta de Verificación
SELECT 
    s.SubastaID,
    a.Titulo AS Articulo,
    c.NombreCategoria,
    s.PrecioActual,
    s.Estado,
    u.Nombre AS UltimoPostor,
    p.FechaPuja
FROM Subastas s
JOIN Articulos a ON s.ArticuloID = a.ArticuloID
JOIN Categorias c ON a.CategoriaID = c.CategoriaID
LEFT JOIN Pujas p ON s.SubastaID = p.SubastaID AND p.MontoOferta = s.PrecioActual
LEFT JOIN Usuarios u ON p.PostorID = u.UsuarioID;
GO