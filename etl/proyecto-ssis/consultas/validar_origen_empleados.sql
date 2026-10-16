IF EXISTS(SELECT empleado_id FROM dbo.empleados GROUP BY empleado_id HAVING COUNT(*)>1)
 THROW 51000,'Empleado duplicado en origen.',1;
IF EXISTS(SELECT 1 FROM dbo.empleados e LEFT JOIN dbo.cargos c ON c.cargo_id=e.cargo_id
 WHERE e.empleado_id IS NULL OR e.empleado_id=-1 OR c.cargo_id IS NULL
 OR NULLIF(LTRIM(RTRIM(e.nombre)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(e.appaterno)),N'') IS NULL
 OR LEN(LTRIM(RTRIM(COALESCE(e.nombre,N'')))+N' '+LTRIM(RTRIM(COALESCE(e.appaterno,N'')))+CASE WHEN NULLIF(LTRIM(RTRIM(e.apmaterno)),N'') IS NULL THEN N'' ELSE N' '+LTRIM(RTRIM(e.apmaterno)) END)>150 OR NULLIF(LTRIM(RTRIM(c.nombre)),N'') IS NULL
 OR LEN(UPPER(LTRIM(RTRIM(c.nombre))))>100 OR e.sueldo_base<0)
 THROW 51000,'Empleado, nombre completo, cargo o sueldo invalido.',1;
