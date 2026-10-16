IF NOT EXISTS(SELECT 1 FROM dbo.Dim_Producto WHERE Producto_SK=-1 AND Producto_BK=-1)
 THROW 51000,'Falta el miembro desconocido -1.',1;
IF EXISTS(SELECT Producto_BK FROM dbo.Dim_Producto GROUP BY Producto_BK HAVING COUNT(*)>1)
 THROW 51000,'Hay claves de negocio duplicadas.',1;
IF EXISTS(SELECT p.producto_id,
 CAST(LTRIM(RTRIM(p.nombre)) AS varchar(100)) COLLATE DATABASE_DEFAULT,
 CAST(LTRIM(RTRIM(c.categoria)) AS varchar(100)) COLLATE DATABASE_DEFAULT,
 CAST(p.precio AS numeric(12,2)),
 CAST(COALESCE(p.descripcion,N'Sin descripción') AS varchar(255)) COLLATE DATABASE_DEFAULT
 FROM Albarran.dbo.productos p JOIN Albarran.dbo.categorias c ON c.categoria_id=p.categoria_id
 EXCEPT SELECT Producto_BK,Nombre_Producto COLLATE DATABASE_DEFAULT,
 Nombre_Categoria COLLATE DATABASE_DEFAULT,Precio_Catalogo,Descripcion COLLATE DATABASE_DEFAULT
 FROM dbo.Dim_Producto WHERE Producto_SK<>-1) OR EXISTS(SELECT Producto_BK,Nombre_Producto COLLATE DATABASE_DEFAULT,
 Nombre_Categoria COLLATE DATABASE_DEFAULT,Precio_Catalogo,Descripcion COLLATE DATABASE_DEFAULT
 FROM dbo.Dim_Producto WHERE Producto_SK<>-1
 EXCEPT SELECT p.producto_id,
 CAST(LTRIM(RTRIM(p.nombre)) AS varchar(100)) COLLATE DATABASE_DEFAULT,
 CAST(LTRIM(RTRIM(c.categoria)) AS varchar(100)) COLLATE DATABASE_DEFAULT,
 CAST(p.precio AS numeric(12,2)),
 CAST(COALESCE(p.descripcion,N'Sin descripción') AS varchar(255)) COLLATE DATABASE_DEFAULT
 FROM Albarran.dbo.productos p JOIN Albarran.dbo.categorias c ON c.categoria_id=p.categoria_id)
 THROW 51000,'La dimension no coincide con productos y categorias del origen.',1;
