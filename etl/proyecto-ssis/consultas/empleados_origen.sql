SELECT e.empleado_id AS Empleado_BK,
 CAST(e.nombre AS varchar(150)) Nombre,CAST(e.appaterno AS varchar(150)) ApPaterno,
 CAST(e.apmaterno AS varchar(150)) ApMaterno,CAST(c.nombre AS varchar(100)) Nombre_Cargo,
 CAST(e.sueldo_base AS numeric(12,2)) Sueldo_Base,CAST(e.fecha_contrato AS date) Fecha_Contrato
FROM dbo.empleados e JOIN dbo.cargos c ON c.cargo_id=e.cargo_id
WHERE NOT EXISTS(SELECT 1 FROM Albarran_DW.dbo.Dim_Empleado d WHERE d.Empleado_BK=e.empleado_id);
