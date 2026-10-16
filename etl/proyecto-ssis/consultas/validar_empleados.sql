IF NOT EXISTS(SELECT 1 FROM dbo.Dim_Empleado WHERE Empleado_SK=-1 AND Empleado_BK=-1)
 THROW 51000,'Falta el miembro desconocido -1.',1;
IF EXISTS(SELECT Empleado_BK FROM dbo.Dim_Empleado GROUP BY Empleado_BK HAVING COUNT(*)>1)
 THROW 51000,'Claves de negocio duplicadas en destino.',1;
IF EXISTS(SELECT e.empleado_id,CAST(LTRIM(RTRIM(COALESCE(e.nombre,N'')))+N' '+LTRIM(RTRIM(COALESCE(e.appaterno,N'')))+CASE WHEN NULLIF(LTRIM(RTRIM(e.apmaterno)),N'') IS NULL THEN N'' ELSE N' '+LTRIM(RTRIM(e.apmaterno)) END AS varchar(150)) COLLATE DATABASE_DEFAULT,
 CAST(UPPER(LTRIM(RTRIM(c.nombre))) AS varchar(100)) COLLATE DATABASE_DEFAULT,
 CAST(e.sueldo_base AS numeric(12,2)),CAST(e.fecha_contrato AS date)
 FROM Albarran.dbo.empleados e JOIN Albarran.dbo.cargos c ON c.cargo_id=e.cargo_id
 EXCEPT SELECT Empleado_BK,Nombre_Completo COLLATE DATABASE_DEFAULT,Nombre_Cargo COLLATE DATABASE_DEFAULT,Sueldo_Base,Fecha_Contrato FROM dbo.Dim_Empleado WHERE Empleado_SK<>-1) OR EXISTS(SELECT Empleado_BK,Nombre_Completo COLLATE DATABASE_DEFAULT,Nombre_Cargo COLLATE DATABASE_DEFAULT,Sueldo_Base,Fecha_Contrato FROM dbo.Dim_Empleado WHERE Empleado_SK<>-1
 EXCEPT SELECT e.empleado_id,CAST(LTRIM(RTRIM(COALESCE(e.nombre,N'')))+N' '+LTRIM(RTRIM(COALESCE(e.appaterno,N'')))+CASE WHEN NULLIF(LTRIM(RTRIM(e.apmaterno)),N'') IS NULL THEN N'' ELSE N' '+LTRIM(RTRIM(e.apmaterno)) END AS varchar(150)) COLLATE DATABASE_DEFAULT,
 CAST(UPPER(LTRIM(RTRIM(c.nombre))) AS varchar(100)) COLLATE DATABASE_DEFAULT,
 CAST(e.sueldo_base AS numeric(12,2)),CAST(e.fecha_contrato AS date)
 FROM Albarran.dbo.empleados e JOIN Albarran.dbo.cargos c ON c.cargo_id=e.cargo_id)
 THROW 51000,'La dimension no coincide con la transformacion del origen.',1;
