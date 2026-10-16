IF EXISTS(SELECT cliente_id FROM dbo.clientes GROUP BY cliente_id HAVING COUNT(*)>1)
 THROW 51000,'Cliente duplicado en origen.',1;
IF EXISTS(SELECT 1 FROM dbo.clientes e WHERE e.cliente_id IS NULL OR e.cliente_id=-1
 OR NULLIF(LTRIM(RTRIM(e.nombre)),N'') IS NULL OR NULLIF(LTRIM(RTRIM(e.appaterno)),N'') IS NULL
 OR LEN(LTRIM(RTRIM(COALESCE(e.nombre,N'')))+N' '+LTRIM(RTRIM(COALESCE(e.appaterno,N'')))+CASE WHEN NULLIF(LTRIM(RTRIM(e.apmaterno)),N'') IS NULL THEN N'' ELSE N' '+LTRIM(RTRIM(e.apmaterno)) END)>150 OR LEN(e.estado_civil)>50)
 THROW 51000,'Cliente o textos fuera de los limites del destino.',1;
