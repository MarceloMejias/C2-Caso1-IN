SELECT Empleado_BK,Nombre_Completo,Nombre_Cargo,Sueldo_Base,Fecha_Contrato FROM (SELECT e.empleado_id,CAST(LTRIM(RTRIM(COALESCE(e.nombre,N'')))+N' '+LTRIM(RTRIM(COALESCE(e.appaterno,N'')))+CASE WHEN NULLIF(LTRIM(RTRIM(e.apmaterno)),N'') IS NULL THEN N'' ELSE N' '+LTRIM(RTRIM(e.apmaterno)) END AS varchar(150)) COLLATE DATABASE_DEFAULT,
 CAST(UPPER(LTRIM(RTRIM(c.nombre))) AS varchar(100)) COLLATE DATABASE_DEFAULT,
 CAST(e.sueldo_base AS numeric(12,2)),CAST(e.fecha_contrato AS date)
 FROM dbo.empleados e JOIN dbo.cargos c ON c.cargo_id=e.cargo_id WHERE NOT EXISTS(SELECT 1 FROM Albarran_DW.dbo.Dim_Empleado d WHERE d.Empleado_BK=e.empleado_id)) transformed(Empleado_BK,Nombre_Completo,Nombre_Cargo,Sueldo_Base,Fecha_Contrato);
