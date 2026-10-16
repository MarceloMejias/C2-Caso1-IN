IF EXISTS(SELECT producto_id FROM dbo.productos GROUP BY producto_id HAVING COUNT(*)>1)
 THROW 51000,'Producto duplicado en origen.',1;
IF EXISTS(SELECT 1 FROM dbo.productos p LEFT JOIN dbo.categorias c ON c.categoria_id=p.categoria_id
 WHERE p.producto_id IS NULL OR p.producto_id=-1 OR c.categoria_id IS NULL
 OR NULLIF(LTRIM(RTRIM(p.nombre)),'') IS NULL OR NULLIF(LTRIM(RTRIM(c.categoria)),'') IS NULL
 OR LEN(p.nombre)>100 OR LEN(c.categoria)>100 OR p.precio IS NULL OR p.precio<0)
 THROW 51000,'Producto, categoria o precio invalido; revisar origen.',1;
