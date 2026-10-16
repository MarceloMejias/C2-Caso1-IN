IF NOT EXISTS(SELECT 1 FROM dbo.Dim_Cliente WHERE Cliente_SK=-1 AND Cliente_BK=-1)
 THROW 51000,'Falta el miembro desconocido -1.',1;
IF EXISTS(SELECT Cliente_BK FROM dbo.Dim_Cliente GROUP BY Cliente_BK HAVING COUNT(*)>1)
 THROW 51000,'Claves de negocio duplicadas en destino.',1;
IF EXISTS(SELECT e.cliente_id,CAST(LTRIM(RTRIM(COALESCE(e.nombre,N'')))+N' '+LTRIM(RTRIM(COALESCE(e.appaterno,N'')))+CASE WHEN NULLIF(LTRIM(RTRIM(e.apmaterno)),N'') IS NULL THEN N'' ELSE N' '+LTRIM(RTRIM(e.apmaterno)) END AS varchar(150)) COLLATE DATABASE_DEFAULT,
 CAST(CASE WHEN UPPER(LTRIM(RTRIM(e.sexo)))='M' THEN 'Masculino' WHEN UPPER(LTRIM(RTRIM(e.sexo)))='F' THEN 'Femenino' ELSE 'No Informado' END AS varchar(20)) COLLATE DATABASE_DEFAULT,
 CAST(e.fecha_nacimiento AS date),CAST(COALESCE(NULLIF(LTRIM(RTRIM(e.estado_civil)),N''),N'No Informado') AS varchar(50)) COLLATE DATABASE_DEFAULT
 FROM Albarran.dbo.clientes e
 EXCEPT SELECT Cliente_BK,Nombre_Completo COLLATE DATABASE_DEFAULT,Sexo COLLATE DATABASE_DEFAULT,Fecha_Nacimiento,Estado_Civil COLLATE DATABASE_DEFAULT FROM dbo.Dim_Cliente WHERE Cliente_SK<>-1) OR EXISTS(SELECT Cliente_BK,Nombre_Completo COLLATE DATABASE_DEFAULT,Sexo COLLATE DATABASE_DEFAULT,Fecha_Nacimiento,Estado_Civil COLLATE DATABASE_DEFAULT FROM dbo.Dim_Cliente WHERE Cliente_SK<>-1
 EXCEPT SELECT e.cliente_id,CAST(LTRIM(RTRIM(COALESCE(e.nombre,N'')))+N' '+LTRIM(RTRIM(COALESCE(e.appaterno,N'')))+CASE WHEN NULLIF(LTRIM(RTRIM(e.apmaterno)),N'') IS NULL THEN N'' ELSE N' '+LTRIM(RTRIM(e.apmaterno)) END AS varchar(150)) COLLATE DATABASE_DEFAULT,
 CAST(CASE WHEN UPPER(LTRIM(RTRIM(e.sexo)))='M' THEN 'Masculino' WHEN UPPER(LTRIM(RTRIM(e.sexo)))='F' THEN 'Femenino' ELSE 'No Informado' END AS varchar(20)) COLLATE DATABASE_DEFAULT,
 CAST(e.fecha_nacimiento AS date),CAST(COALESCE(NULLIF(LTRIM(RTRIM(e.estado_civil)),N''),N'No Informado') AS varchar(50)) COLLATE DATABASE_DEFAULT
 FROM Albarran.dbo.clientes e)
 THROW 51000,'La dimension no coincide con la transformacion del origen.',1;
