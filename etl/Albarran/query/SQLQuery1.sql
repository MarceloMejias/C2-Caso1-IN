-- ==============================================================================
-- Certamen 2 - Inteligencia de Negocios (Mueblería Albarrán)
-- Script 04: Validación de Carga, Cuadratura Contable y Backup de Albarran_DW
-- Motor: Microsoft SQL Server 2022
-- ==============================================================================
-- Este script realiza una auditoría cruzada entre la base relacional (Albarran)
-- y el Data Warehouse dimensional (Albarran_DW) para certificar que el proceso
-- ETL en SSIS no produjo pérdidas de datos, discrepancias financieras ni
-- registros huérfanos.
-- ==============================================================================

USE Albarran_DW;
GO

SET NOCOUNT ON;

PRINT '==============================================================================';
PRINT '  AUDITORÍA DE CUADRATURA Y CALIDAD DE DATOS: ALBARRAN vs ALBARRAN_DW';
PRINT '  Fecha de Ejecución: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '==============================================================================';
PRINT '';

-- 1. Tabla temporal para consolidar los resultados de la auditoría
IF OBJECT_ID('tempdb..#Resultados_Auditoria') IS NOT NULL 
    DROP TABLE #Resultados_Auditoria;

CREATE TABLE #Resultados_Auditoria (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Categoria VARCHAR(30),
    Prueba VARCHAR(80),
    Valor_Origen_Esperado VARCHAR(50),
    Valor_Destino_Obtenido VARCHAR(50),
    Diferencia VARCHAR(50),
    Estado VARCHAR(30)
);

-- Variables para métricas origen (Albarran OLTP)
DECLARE @Origen_Transacciones INT;
DECLARE @Origen_Unidades INT;
DECLARE @Origen_Monto_Bruto NUMERIC(14,2);
DECLARE @Origen_Descuentos NUMERIC(14,2);
DECLARE @Origen_Monto_Neto NUMERIC(14,2);
DECLARE @Origen_Clientes INT;
DECLARE @Origen_Productos INT;
DECLARE @Origen_Sucursales INT;
DECLARE @Origen_Empleados INT;

-- Variables para métricas destino (Albarran_DW OLAP)
DECLARE @Destino_Transacciones INT;
DECLARE @Destino_Unidades INT;
DECLARE @Destino_Monto_Bruto NUMERIC(14,2);
DECLARE @Destino_Descuentos NUMERIC(14,2);
DECLARE @Destino_Monto_Neto NUMERIC(14,2);
DECLARE @Destino_Clientes INT;
DECLARE @Destino_Productos INT;
DECLARE @Destino_Sucursales INT;
DECLARE @Destino_Empleados INT;
DECLARE @Destino_Fechas INT;

-- Variables de huérfanos / claves no mapeadas (-1) en Fact_Ventas
DECLARE @Huerfanos_Cliente INT = 0;
DECLARE @Huerfanos_Empleado INT = 0;
DECLARE @Huerfanos_Producto INT = 0;
DECLARE @Huerfanos_Sucursal INT = 0;
DECLARE @Huerfanos_Fecha INT = 0;

-- Calidad en dimensiones
DECLARE @Productos_Desc_Nula INT = 0;
DECLARE @Miembros_MenosUno_Presentes INT = 0;

-- 2. Extracción de cifras de control desde la fuente relacional (Albarran)
SELECT 
    @Origen_Transacciones = COUNT(DISTINCT v.venta_id),
    @Origen_Unidades = ISNULL(SUM(d.cantidad), 0),
    @Origen_Monto_Bruto = ISNULL(SUM(CAST(d.cantidad AS NUMERIC(14,2)) * CAST(d.precio_unitario AS NUMERIC(14,2))), 0),
    @Origen_Descuentos = ISNULL(SUM(CAST(d.cantidad AS NUMERIC(14,2)) * CAST(d.precio_unitario AS NUMERIC(14,2)) * CAST(d.descuento AS NUMERIC(14,2))), 0),
    @Origen_Monto_Neto = ISNULL(SUM((CAST(d.cantidad AS NUMERIC(14,2)) * CAST(d.precio_unitario AS NUMERIC(14,2))) - (CAST(d.cantidad AS NUMERIC(14,2)) * CAST(d.precio_unitario AS NUMERIC(14,2)) * CAST(d.descuento AS NUMERIC(14,2)))), 0)
FROM Albarran.dbo.ventas v
INNER JOIN Albarran.dbo.detalle_ventas d ON v.venta_id = d.venta_id;

SELECT @Origen_Clientes = COUNT(*) FROM Albarran.dbo.clientes;
SELECT @Origen_Productos = COUNT(*) FROM Albarran.dbo.productos;
SELECT @Origen_Sucursales = COUNT(*) FROM Albarran.dbo.sucursales;
SELECT @Origen_Empleados = COUNT(*) FROM Albarran.dbo.empleados;

-- 3. Extracción de cifras desde el Data Warehouse (Albarran_DW)
SELECT 
    @Destino_Transacciones = COUNT(*),
    @Destino_Unidades = ISNULL(SUM(Cantidad), 0),
    @Destino_Monto_Bruto = ISNULL(SUM(Monto_Bruto), 0),
    @Destino_Descuentos = ISNULL(SUM(Monto_Descuento), 0),
    @Destino_Monto_Neto = ISNULL(SUM(Monto_Neto), 0),
    @Huerfanos_Cliente = ISNULL(SUM(CASE WHEN Cliente_SK = -1 THEN 1 ELSE 0 END), 0),
    @Huerfanos_Empleado = ISNULL(SUM(CASE WHEN Empleado_SK = -1 THEN 1 ELSE 0 END), 0),
    @Huerfanos_Producto = ISNULL(SUM(CASE WHEN Producto_SK = -1 THEN 1 ELSE 0 END), 0),
    @Huerfanos_Sucursal = ISNULL(SUM(CASE WHEN Sucursal_SK = -1 THEN 1 ELSE 0 END), 0),
    @Huerfanos_Fecha = ISNULL(SUM(CASE WHEN Fecha_SK = -1 THEN 1 ELSE 0 END), 0)
FROM dbo.Fact_Ventas;

SELECT @Destino_Clientes = COUNT(*) - 1 FROM dbo.Dim_Cliente; -- Descontando miembro -1
SELECT @Destino_Productos = COUNT(*) - 1 FROM dbo.Dim_Producto;
SELECT @Destino_Sucursales = COUNT(*) - 1 FROM dbo.Dim_Sucursal;
SELECT @Destino_Empleados = COUNT(*) - 1 FROM dbo.Dim_Empleado;
SELECT @Destino_Fechas = COUNT(*) - 1 FROM dbo.Dim_Tiempo;

SELECT @Productos_Desc_Nula = COUNT(*) FROM dbo.Dim_Producto WHERE Descripcion IS NULL;

-- Conteo de miembros -1 existentes
SELECT @Miembros_MenosUno_Presentes = 
    (CASE WHEN EXISTS (SELECT 1 FROM dbo.Dim_Cliente WHERE Cliente_SK = -1) THEN 1 ELSE 0 END) +
    (CASE WHEN EXISTS (SELECT 1 FROM dbo.Dim_Empleado WHERE Empleado_SK = -1) THEN 1 ELSE 0 END) +
    (CASE WHEN EXISTS (SELECT 1 FROM dbo.Dim_Producto WHERE Producto_SK = -1) THEN 1 ELSE 0 END) +
    (CASE WHEN EXISTS (SELECT 1 FROM dbo.Dim_Sucursal WHERE Sucursal_SK = -1) THEN 1 ELSE 0 END) +
    (CASE WHEN EXISTS (SELECT 1 FROM dbo.Dim_Tiempo WHERE Fecha_SK = -1) THEN 1 ELSE 0 END);

-- ==============================================================================
-- 4. Inserción de Evaluaciones en la Tabla de Auditoría
-- ==============================================================================

-- 4.1 Volumetría Transaccional
INSERT INTO #Resultados_Auditoria (Categoria, Prueba, Valor_Origen_Esperado, Valor_Destino_Obtenido, Diferencia, Estado)
VALUES (
    'Volumetría',
    'Conteo de Transacciones en Fact_Ventas',
    CAST(@Origen_Transacciones AS VARCHAR),
    CAST(@Destino_Transacciones AS VARCHAR),
    CAST((@Destino_Transacciones - @Origen_Transacciones) AS VARCHAR),
    CASE 
        WHEN @Destino_Transacciones = 0 THEN 'PENDIENTE (Requiere ETL SSIS)'
        WHEN @Destino_Transacciones = @Origen_Transacciones THEN 'APROBADO [PASS]'
        ELSE 'DISCREPANCIA [FAIL]'
    END
);

-- 4.2 Unidades Físicas
INSERT INTO #Resultados_Auditoria (Categoria, Prueba, Valor_Origen_Esperado, Valor_Destino_Obtenido, Diferencia, Estado)
VALUES (
    'Volumetría',
    'Total Unidades Vendidas (Cantidad)',
    CAST(@Origen_Unidades AS VARCHAR),
    CAST(@Destino_Unidades AS VARCHAR),
    CAST((@Destino_Unidades - @Origen_Unidades) AS VARCHAR),
    CASE 
        WHEN @Destino_Transacciones = 0 THEN 'PENDIENTE (Requiere ETL SSIS)'
        WHEN @Destino_Unidades = @Origen_Unidades THEN 'APROBADO [PASS]'
        ELSE 'DISCREPANCIA [FAIL]'
    END
);

-- 4.3 Cuadratura Financiera Bruta
INSERT INTO #Resultados_Auditoria (Categoria, Prueba, Valor_Origen_Esperado, Valor_Destino_Obtenido, Diferencia, Estado)
VALUES (
    'Financiero',
    'Facturación Bruta Total (CLP)',
    '$ ' + FORMAT(@Origen_Monto_Bruto, 'N0', 'es-CL'),
    '$ ' + FORMAT(@Destino_Monto_Bruto, 'N0', 'es-CL'),
    '$ ' + FORMAT((@Destino_Monto_Bruto - @Origen_Monto_Bruto), 'N0', 'es-CL'),
    CASE 
        WHEN @Destino_Transacciones = 0 THEN 'PENDIENTE (Requiere ETL SSIS)'
        WHEN @Destino_Monto_Bruto = @Origen_Monto_Bruto THEN 'APROBADO [PASS]'
        ELSE 'DISCREPANCIA [FAIL]'
    END
);

-- 4.4 Cuadratura de Descuentos
INSERT INTO #Resultados_Auditoria (Categoria, Prueba, Valor_Origen_Esperado, Valor_Destino_Obtenido, Diferencia, Estado)
VALUES (
    'Financiero',
    'Monto Total Descuentos (CLP)',
    '$ ' + FORMAT(@Origen_Descuentos, 'N0', 'es-CL'),
    '$ ' + FORMAT(@Destino_Descuentos, 'N0', 'es-CL'),
    '$ ' + FORMAT((@Destino_Descuentos - @Origen_Descuentos), 'N0', 'es-CL'),
    CASE 
        WHEN @Destino_Transacciones = 0 THEN 'PENDIENTE (Requiere ETL SSIS)'
        WHEN @Destino_Descuentos = @Origen_Descuentos THEN 'APROBADO [PASS]'
        ELSE 'DISCREPANCIA [FAIL]'
    END
);

-- 4.5 Cuadratura Financiera Neta
INSERT INTO #Resultados_Auditoria (Categoria, Prueba, Valor_Origen_Esperado, Valor_Destino_Obtenido, Diferencia, Estado)
VALUES (
    'Financiero',
    'Facturación Neta Total (CLP)',
    '$ ' + FORMAT(@Origen_Monto_Neto, 'N0', 'es-CL'),
    '$ ' + FORMAT(@Destino_Monto_Neto, 'N0', 'es-CL'),
    '$ ' + FORMAT((@Destino_Monto_Neto - @Origen_Monto_Neto), 'N0', 'es-CL'),
    CASE 
        WHEN @Destino_Transacciones = 0 THEN 'PENDIENTE (Requiere ETL SSIS)'
        WHEN @Destino_Monto_Neto = @Origen_Monto_Neto THEN 'APROBADO [PASS]'
        ELSE 'DISCREPANCIA [FAIL]'
    END
);

-- 4.6 Integridad Referencial en Fact_Ventas (Cero Huérfanos)
INSERT INTO #Resultados_Auditoria (Categoria, Prueba, Valor_Origen_Esperado, Valor_Destino_Obtenido, Diferencia, Estado)
VALUES (
    'Integridad FK',
    'Claves No Mapeadas (SK = -1 en Fact_Ventas)',
    '0 (Cero)',
    CAST((@Huerfanos_Cliente + @Huerfanos_Empleado + @Huerfanos_Producto + @Huerfanos_Sucursal + @Huerfanos_Fecha) AS VARCHAR),
    CAST((@Huerfanos_Cliente + @Huerfanos_Empleado + @Huerfanos_Producto + @Huerfanos_Sucursal + @Huerfanos_Fecha) AS VARCHAR),
    CASE 
        WHEN @Destino_Transacciones = 0 THEN 'PENDIENTE (Requiere ETL SSIS)'
        WHEN (@Huerfanos_Cliente + @Huerfanos_Empleado + @Huerfanos_Producto + @Huerfanos_Sucursal + @Huerfanos_Fecha) = 0 THEN 'APROBADO [PASS]'
        ELSE 'DISCREPANCIA [FAIL]'
    END
);

-- 4.7 Calidad en Dim_Producto (Tratamiento de Nulos en Descripción)
INSERT INTO #Resultados_Auditoria (Categoria, Prueba, Valor_Origen_Esperado, Valor_Destino_Obtenido, Diferencia, Estado)
VALUES (
    'Calidad Datos',
    'Valores NULL en Descripcion (Dim_Producto)',
    '0 (Sin nulos)',
    CAST(@Productos_Desc_Nula AS VARCHAR),
    CAST(@Productos_Desc_Nula AS VARCHAR),
    CASE 
        WHEN @Productos_Desc_Nula = 0 THEN 'APROBADO [PASS]'
        ELSE 'DISCREPANCIA [FAIL]'
    END
);

-- 4.8 Cobertura de Miembros Desconocidos (-1)
INSERT INTO #Resultados_Auditoria (Categoria, Prueba, Valor_Origen_Esperado, Valor_Destino_Obtenido, Diferencia, Estado)
VALUES (
    'Modelo Kimball',
    'Presencia Miembro SK = -1 en las 5 Dimensiones',
    '5 Dimensiones',
    CAST(@Miembros_MenosUno_Presentes AS VARCHAR) + ' Dimensiones',
    CAST((5 - @Miembros_MenosUno_Presentes) AS VARCHAR),
    CASE 
        WHEN @Miembros_MenosUno_Presentes = 5 THEN 'APROBADO [PASS]'
        ELSE 'DISCREPANCIA [FAIL]'
    END
);

-- 4.9 Cobertura de Dim_Tiempo (2017 a 2026)
INSERT INTO #Resultados_Auditoria (Categoria, Prueba, Valor_Origen_Esperado, Valor_Destino_Obtenido, Diferencia, Estado)
VALUES (
    'Modelo Kimball',
    'Registros Calendario en Dim_Tiempo (2017-2026)',
    '3652 días',
    CAST(CASE WHEN @Destino_Fechas < 0 THEN 0 ELSE @Destino_Fechas END AS VARCHAR) + ' días',
    CAST((3652 - CASE WHEN @Destino_Fechas < 0 THEN 0 ELSE @Destino_Fechas END) AS VARCHAR),
    CASE 
        WHEN @Destino_Fechas = 3652 THEN 'APROBADO [PASS]'
        WHEN @Destino_Fechas <= 0 THEN 'PENDIENTE (Ejecutar script 03)'
        ELSE 'DISCREPANCIA [FAIL]'
    END
);

-- ==============================================================================
-- 5. Salida de Resultados de la Auditoría
-- ==============================================================================
SELECT 
    ID,
    Categoria,
    Prueba,
    Valor_Origen_Esperado,
    Valor_Destino_Obtenido,
    Diferencia,
    Estado
FROM #Resultados_Auditoria
ORDER BY ID;

-- Mensaje resumen en consola
IF EXISTS (SELECT 1 FROM #Resultados_Auditoria WHERE Estado = 'DISCREPANCIA [FAIL]')
BEGIN
    PRINT '>> ALERTA: Se detectaron discrepancias en la auditoría. Revisa la tabla anterior.';
END
ELSE IF EXISTS (SELECT 1 FROM #Resultados_Auditoria WHERE Estado LIKE 'PENDIENTE%')
BEGIN
    PRINT '>> ESTADO: Esquema dimensional validado. Pendiente la ejecucion de los paquetes SSIS en Windows.';
END
ELSE
BEGIN
    PRINT '>> ÉXITO TOTAL: Todas las pruebas de cuadratura contable y volumetría fueron APROBADAS.';
END

DROP TABLE #Resultados_Auditoria;
GO

-- ==============================================================================
-- 6. Procedimiento Operativo: Generación de Backup Final de Albarran_DW
-- ==============================================================================
-- Una vez que todas las pruebas anteriores arrojen 'APROBADO [PASS]',
-- descomenta y ejecuta el siguiente bloque para crear el backup oficial:
/*
BACKUP DATABASE [Albarran_DW]
TO DISK = N'/var/opt/mssql/backup/Albarran_DW.bak' -- En Windows: N'C:\...\database\backup\Albarran_DW.bak'
WITH FORMAT,
     INIT,
     NAME = N'Albarran_DW-Full-Backup-PostETL',
     COMPRESSION,
     CHECKSUM,
     STATS = 10;
GO

-- Verificación de integridad del archivo de backup generado
RESTORE VERIFYONLY
FROM DISK = N'/var/opt/mssql/backup/Albarran_DW.bak'
WITH CHECKSUM;
GO
*/
