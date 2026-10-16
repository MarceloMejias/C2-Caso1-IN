SELECT s.sucursal_id AS Sucursal_BK,
 CAST(LTRIM(RTRIM(s.sucursal)) AS varchar(100)) AS Nombre_Sucursal,
 CAST(LTRIM(RTRIM(c.comuna)) AS varchar(100)) AS Nombre_Comuna
FROM dbo.sucursales AS s
INNER JOIN dbo.comunas AS c ON c.comuna_id=s.comuna_id
WHERE NOT EXISTS(SELECT 1 FROM Albarran_DW.dbo.Dim_Sucursal AS d WHERE d.Sucursal_BK=s.sucursal_id);
