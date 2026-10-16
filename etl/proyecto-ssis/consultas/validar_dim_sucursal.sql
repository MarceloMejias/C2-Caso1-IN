IF NOT EXISTS(SELECT 1 FROM dbo.Dim_Sucursal WHERE Sucursal_SK=-1 AND Sucursal_BK=-1)
 THROW 51000,'Falta el miembro desconocido -1.',1;
IF EXISTS(SELECT Sucursal_BK FROM dbo.Dim_Sucursal GROUP BY Sucursal_BK HAVING COUNT(*)>1)
 THROW 51000,'Hay claves de negocio duplicadas.',1;
IF EXISTS(SELECT s.sucursal_id,CAST(LTRIM(RTRIM(s.sucursal)) AS varchar(100)) COLLATE DATABASE_DEFAULT,CAST(LTRIM(RTRIM(c.comuna)) AS varchar(100)) COLLATE DATABASE_DEFAULT
 FROM Albarran.dbo.sucursales s JOIN Albarran.dbo.comunas c ON c.comuna_id=s.comuna_id
 EXCEPT SELECT Sucursal_BK,Nombre_Sucursal COLLATE DATABASE_DEFAULT,Nombre_Comuna COLLATE DATABASE_DEFAULT FROM dbo.Dim_Sucursal WHERE Sucursal_SK<>-1)
 OR EXISTS(SELECT Sucursal_BK,Nombre_Sucursal COLLATE DATABASE_DEFAULT,Nombre_Comuna COLLATE DATABASE_DEFAULT FROM dbo.Dim_Sucursal WHERE Sucursal_SK<>-1
 EXCEPT SELECT s.sucursal_id,CAST(LTRIM(RTRIM(s.sucursal)) AS varchar(100)) COLLATE DATABASE_DEFAULT,CAST(LTRIM(RTRIM(c.comuna)) AS varchar(100)) COLLATE DATABASE_DEFAULT
 FROM Albarran.dbo.sucursales s JOIN Albarran.dbo.comunas c ON c.comuna_id=s.comuna_id)
 THROW 51000,'La dimension no coincide con sucursales y comunas de origen.',1;
