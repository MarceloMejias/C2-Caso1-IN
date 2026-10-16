-- Issue #6. Ejecutar despues del DDL del issue #4, en SQL Server.
-- Este script carga el calendario; no crea ni reemplaza la tabla dimensional.
USE Albarran_DW;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.Dim_Tiempo', N'U') IS NULL
    THROW 51000, 'Falta dbo.Dim_Tiempo. Ejecutar primero el DDL del issue #4.', 1;

IF EXISTS (
    SELECT 1
    FROM (VALUES
        (N'Fecha_SK'), (N'Fecha'), (N'Anio'), (N'Semestre'), (N'Trimestre'),
        (N'Mes'), (N'Nombre_Mes'), (N'Dia'), (N'Dia_Semana'),
        (N'Nombre_Dia_Semana'), (N'Es_Fin_De_Semana')
    ) AS requerido(Columna)
    WHERE NOT EXISTS (
        SELECT 1 FROM sys.columns AS c
        WHERE c.object_id = OBJECT_ID(N'dbo.Dim_Tiempo')
          AND c.name = requerido.Columna
    )
)
    THROW 51000, 'Dim_Tiempo no coincide con las columnas del issue #6. Revisar el DDL.', 1;

DECLARE @Desde date = '20170101';
DECLARE @Hasta date = '20261231';
DECLARE @FechasEsperadas int = DATEDIFF(day, @Desde, @Hasta) + 1;
DECLARE @UsaIdentity bit = CONVERT(bit, COLUMNPROPERTY(
    OBJECT_ID(N'dbo.Dim_Tiempo'), N'Fecha_SK', 'IsIdentity'
));
DECLARE @IdentityActivo bit = 0;
DECLARE @Insertadas int;

-- Una tabla temporal evita depender del idioma o DATEFIRST de la sesion.
DROP TABLE IF EXISTS #Calendario;
;WITH Fechas AS (
    SELECT @Desde AS Fecha
    UNION ALL
    SELECT DATEADD(day, 1, Fecha) FROM Fechas WHERE Fecha < @Hasta
)
SELECT
    YEAR(Fecha) * 10000 + MONTH(Fecha) * 100 + DAY(Fecha) AS Fecha_SK,
    Fecha,
    YEAR(Fecha) AS Anio,
    CASE WHEN MONTH(Fecha) <= 6 THEN 1 ELSE 2 END AS Semestre,
    DATEPART(quarter, Fecha) AS Trimestre,
    MONTH(Fecha) AS Mes,
    CHOOSE(MONTH(Fecha), N'Enero', N'Febrero', N'Marzo', N'Abril', N'Mayo',
        N'Junio', N'Julio', N'Agosto', N'Septiembre', N'Octubre', N'Noviembre', N'Diciembre') AS Nombre_Mes,
    DAY(Fecha) AS Dia,
    DATEDIFF(day, CONVERT(date, '19000101', 112), Fecha) % 7 + 1 AS Dia_Semana,
    CHOOSE(DATEDIFF(day, CONVERT(date, '19000101', 112), Fecha) % 7 + 1,
        N'Lunes', N'Martes', N'Miércoles', N'Jueves', N'Viernes', N'Sábado', N'Domingo') AS Nombre_Dia_Semana,
    CONVERT(bit, CASE WHEN DATEDIFF(day, CONVERT(date, '19000101', 112), Fecha) % 7 + 1 IN (6, 7)
        THEN 1 ELSE 0 END) AS Es_Fin_De_Semana
INTO #Calendario
FROM Fechas
OPTION (MAXRECURSION 0);

BEGIN TRY
    BEGIN TRANSACTION;

    -- Fecha_SK es YYYYMMDD, incluso si el DDL la declara como IDENTITY.
    IF @UsaIdentity = 1
    BEGIN
        SET IDENTITY_INSERT dbo.Dim_Tiempo ON;
        SET @IdentityActivo = 1;
    END;

    INSERT INTO dbo.Dim_Tiempo (
        Fecha_SK, Fecha, Anio, Semestre, Trimestre, Mes, Nombre_Mes,
        Dia, Dia_Semana, Nombre_Dia_Semana, Es_Fin_De_Semana
    )
    SELECT c.Fecha_SK, c.Fecha, c.Anio, c.Semestre, c.Trimestre, c.Mes, c.Nombre_Mes,
        c.Dia, c.Dia_Semana, c.Nombre_Dia_Semana, c.Es_Fin_De_Semana
    FROM #Calendario AS c
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.Dim_Tiempo AS d WITH (UPDLOCK, HOLDLOCK)
        WHERE d.Fecha_SK = c.Fecha_SK
    );
    SET @Insertadas = @@ROWCOUNT;

    IF @IdentityActivo = 1
    BEGIN
        SET IDENTITY_INSERT dbo.Dim_Tiempo OFF;
        SET @IdentityActivo = 0;
    END;

    IF (SELECT COUNT_BIG(*) FROM dbo.Dim_Tiempo WHERE Fecha BETWEEN @Desde AND @Hasta) <> @FechasEsperadas
        THROW 51000, 'El conteo del calendario no coincide con el intervalo solicitado.', 1;

    -- Compara tambien atributos: no basta con que exista la clave de la fecha.
    IF EXISTS (
        SELECT Fecha_SK, Fecha, Anio, Semestre, Trimestre, Mes, Nombre_Mes,
            Dia, Dia_Semana, Nombre_Dia_Semana, Es_Fin_De_Semana
        FROM #Calendario
        EXCEPT
        SELECT Fecha_SK, Fecha, Anio, Semestre, Trimestre, Mes, Nombre_Mes,
            Dia, Dia_Semana, Nombre_Dia_Semana, Es_Fin_De_Semana
        FROM dbo.Dim_Tiempo
    )
        THROW 51000, 'Hay fechas o atributos inconsistentes. Revisar los registros existentes.', 1;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    IF @IdentityActivo = 1 SET IDENTITY_INSERT dbo.Dim_Tiempo OFF;
    THROW;
END CATCH;

SELECT @Insertadas AS Fechas_Insertadas, @FechasEsperadas AS Fechas_Del_Intervalo;
SELECT Anio, COUNT(*) AS Dias
FROM dbo.Dim_Tiempo
WHERE Fecha BETWEEN @Desde AND @Hasta
GROUP BY Anio
ORDER BY Anio;
DROP TABLE #Calendario;
GO
