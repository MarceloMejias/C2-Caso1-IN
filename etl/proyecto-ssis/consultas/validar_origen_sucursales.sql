IF EXISTS(SELECT sucursal_id FROM dbo.sucursales GROUP BY sucursal_id HAVING COUNT(*)>1)
 THROW 51000,'Sucursal duplicada en origen.',1;
IF EXISTS(SELECT 1 FROM dbo.sucursales s LEFT JOIN dbo.comunas c ON c.comuna_id=s.comuna_id
 WHERE s.sucursal_id IS NULL OR s.sucursal_id=-1 OR c.comuna_id IS NULL
 OR NULLIF(LTRIM(RTRIM(s.sucursal)),'') IS NULL OR NULLIF(LTRIM(RTRIM(c.comuna)),'') IS NULL
 OR LEN(s.sucursal)>100 OR LEN(c.comuna)>100)
 THROW 51000,'Sucursal o comuna inexistente, vacia o demasiado larga.',1;
