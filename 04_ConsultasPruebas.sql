USE SubastasPrivadas_DB;
GO

PRINT '====================================================================';
PRINT '1. VERIFICACIÓN DE ROLES Y USUARIOS';
PRINT '====================================================================';

-- 1.1. Validar la distribución de usuarios por Rol
SELECT 
    R.NombreRol,
    COUNT(U.UsuarioID) AS TotalUsuarios,
    STRING_AGG(CONCAT(U.Nombre, ' ', U.Apellido), ', ') AS Integrantes
FROM Roles R
LEFT JOIN Usuarios U ON R.RolID = U.RolID
GROUP BY R.RolID, R.NombreRol;

-- 1.2. Consultar el Auditor asignado
SELECT 
    U.UsuarioID, 
    CONCAT(U.Nombre, ' ', U.Apellido) AS Auditor, 
    U.Correo, 
    R.NombreRol
FROM Usuarios U
INNER JOIN Roles R ON U.RolID = R.RolID
WHERE R.NombreRol = 'Auditor';


PRINT '====================================================================';
PRINT '2. RESUMEN DE SUBASTAS Y PUJAS';
PRINT '====================================================================';

-- 2.1. Ver todas las subastas con su vendedor, artículo, categoría y estado
SELECT 
    S.SubastaID,
    A.Titulo AS Articulo,
    C.NombreCategoria AS Categoria,
    CONCAT(V.Nombre, ' ', V.Apellido) AS Vendedor,
    S.PrecioInicial,
    S.PrecioActual,
    S.Estado
FROM Subastas S
INNER JOIN Articulos A ON S.ArticuloID = A.ArticuloID
INNER JOIN Subcategorias SC ON A.SubcategoriaID = SC.SubcategoriaID
INNER JOIN Categorias C ON SC.CategoriaID = C.CategoriaID
INNER JOIN Usuarios V ON A.VendedorID = V.UsuarioID;

-- 2.2. Historial de Pujas por Subasta (Mostrando la oferta más alta primero)
SELECT 
    P.SubastaID,
    A.Titulo AS Articulo,
    CONCAT(U.Nombre, ' ', U.Apellido) AS Postor,
    P.MontoOferta,
    P.FechaPuja
FROM Pujas P
INNER JOIN Subastas S ON P.SubastaID = S.SubastaID
INNER JOIN Articulos A ON S.ArticuloID = A.ArticuloID
INNER JOIN Usuarios U ON P.PostorID = U.UsuarioID
ORDER BY P.SubastaID ASC, P.MontoOferta DESC;


PRINT '====================================================================';
PRINT '3. FLUJO COMPLETO DE VENTAS Y AUDITORÍA (CERTIFICADOS -> ÓRDENES -> ENVÍOS)';
PRINT '====================================================================';

-- 3.1. Detalle de órdenes generadas y su estado de pago/envío
SELECT 
    O.OrdenID,
    CONCAT(C.Nombre, ' ', C.Apellido) AS Comprador,
    O.MontoSubtotal,
    O.MontoComision,
    O.MontoTotal,
    O.EstadoOrden,
    E.EmpresaTransporte,
    E.NumeroRastreo,
    E.EstadoEnvio
FROM Ordenes O
INNER JOIN Usuarios C ON O.CompradorID = C.UsuarioID
LEFT JOIN Envios E ON O.OrdenID = E.OrdenID;

-- 3.2. Historial de Logs de Auditoría (Acciones registradas)
SELECT 
    L.LogID,
    CONCAT(U.Nombre, ' ', U.Apellido) AS RealizadoPor,
    R.NombreRol,
    L.Accion,
    L.TablaAfectada,
    L.Detalle,
    L.FechaAccion
FROM LogsAuditoria L
INNER JOIN Usuarios U ON L.UsuarioID = U.UsuarioID
INNER JOIN Roles R ON U.RolID = R.RolID
ORDER BY L.FechaAccion DESC;


PRINT '====================================================================';
PRINT '4. ESTADO DE BILLETERAS VIRTUALES (CLIENTES)';
PRINT '====================================================================';

-- 4.1. Consultar el saldo disponible y bloqueado de los Compradores/Clientes
SELECT 
    U.UsuarioID,
    CONCAT(U.Nombre, ' ', U.Apellido) AS Cliente,
    U.Correo,
    BV.SaldoDisponible,
    BV.SaldoBloqueado
FROM BilleteraVirtual BV
INNER JOIN Usuarios U ON BV.UsuarioID = U.UsuarioID
INNER JOIN Roles R ON U.RolID = R.RolID
WHERE R.NombreRol = 'Comprador'
ORDER BY BV.SaldoDisponible DESC;