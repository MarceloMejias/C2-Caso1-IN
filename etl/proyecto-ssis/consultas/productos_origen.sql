SELECT p.producto_id AS Producto_BK,
 CAST(LTRIM(RTRIM(p.nombre)) AS varchar(100)) AS Nombre_Producto,
 CAST(LTRIM(RTRIM(c.categoria)) AS varchar(100)) AS Nombre_Categoria,
 CAST(p.precio AS numeric(12,2)) AS Precio_Catalogo,
 CAST(p.descripcion AS varchar(255)) AS Descripcion
FROM dbo.productos p
INNER JOIN dbo.categorias c ON c.categoria_id=p.categoria_id
WHERE NOT EXISTS(SELECT 1 FROM Albarran_DW.dbo.Dim_Producto d WHERE d.Producto_BK=p.producto_id);
