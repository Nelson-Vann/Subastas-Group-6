CREATE OR ALTER VIEW vw_ResumenSubastasActivas AS
SELECT 
    S.SubastaID,
    A.Titulo AS Producto,
    C.NombreCategoria AS Categoria,
    S.PrecioActual,
    S.FechaFin,
    CONCAT(U.Nombre, ' ', U.Apellido) AS Vendedor
FROM Subastas S
INNER JOIN Articulos A ON S.ArticuloID = A.ArticuloID
INNER JOIN Subcategorias SC ON A.SubcategoriaID = SC.SubcategoriaID
INNER JOIN Categorias C ON SC.CategoriaID = C.CategoriaID
INNER JOIN Usuarios U ON A.VendedorID = U.UsuarioID
WHERE S.Estado = 'Activa';