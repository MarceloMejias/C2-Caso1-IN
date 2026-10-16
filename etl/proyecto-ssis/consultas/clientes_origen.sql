SELECT e.cliente_id AS Cliente_BK,CAST(e.nombre AS nvarchar(150)) Nombre,
 CAST(e.appaterno AS nvarchar(150)) ApPaterno,CAST(e.apmaterno AS nvarchar(150)) ApMaterno,
 CAST(e.sexo AS nvarchar(1)) Sexo_Origen,CAST(e.fecha_nacimiento AS date) Fecha_Nacimiento,
 CAST(e.estado_civil AS nvarchar(50)) Estado_Civil
FROM dbo.clientes e
WHERE NOT EXISTS(SELECT 1 FROM Albarran_DW.dbo.Dim_Cliente d WHERE d.Cliente_BK=e.cliente_id);
