-- ==============================================================================
-- Script 05: Pipeline de Carga ETL Directa (T-SQL)
-- Entorno: DBeaver / SQL Server 2022 (macOS / Linux / Windows)
-- Objetivo: Ejecutar la extracción, transformación y carga (ETL) completa 
--           desde la base transaccional 'Albarran' hacia 'Albarran_DW',
--           aplicando la misma lógica de los paquetes SSIS (.dtsx).
-- ==============================================================================

USE Albarran_DW;
GO
SET NOCOUNT ON;

PRINT '==============================================================================';
PRINT '  INICIANDO PIPELINE DE CARGA ETL DIRECTA HACIA ALBARRAN_DW';
PRINT '==============================================================================';

-- ------------------------------------------------------------------------------
-- 1. Dim_Sucursal (Carga e integración de Comunas desnormalizadas)
-- ------------------------------------------------------------------------------
PRINT '>> 1. Cargando Dim_Sucursal...';
INSERT INTO dbo.Dim_Sucursal (Sucursal_BK, Nombre_Sucursal, Nombre_Comuna)
SELECT 
    s.sucursal_id AS Sucursal_BK,
    CAST(LTRIM(RTRIM(s.sucursal)) AS varchar(100)) AS Nombre_Sucursal,
    CAST(LTRIM(RTRIM(c.comuna)) AS varchar(100)) AS Nombre_Comuna
FROM Albarran.dbo.sucursales s
INNER JOIN Albarran.dbo.comunas c ON s.comuna_id = c.comuna_id
WHERE NOT EXISTS (SELECT 1 FROM dbo.Dim_Sucursal d WHERE d.Sucursal_BK = s.sucursal_id);

-- ------------------------------------------------------------------------------
-- 2. Dim_Cliente (Normalización de nombres y decodificación de género)
-- ------------------------------------------------------------------------------
PRINT '>> 2. Cargando Dim_Cliente...';
INSERT INTO dbo.Dim_Cliente (Cliente_BK, Nombre_Completo, Sexo, Fecha_Nacimiento, Estado_Civil)
SELECT 
    c.cliente_id AS Cliente_BK,
    CAST(LTRIM(RTRIM(COALESCE(c.nombre, ''))) + ' ' + LTRIM(RTRIM(COALESCE(c.appaterno, ''))) + 
        CASE WHEN NULLIF(LTRIM(RTRIM(c.apmaterno)), '') IS NULL THEN '' ELSE ' ' + LTRIM(RTRIM(c.apmaterno)) END AS varchar(150)) AS Nombre_Completo,
    CAST(CASE WHEN UPPER(LTRIM(RTRIM(c.sexo))) = 'M' THEN 'Masculino' 
              WHEN UPPER(LTRIM(RTRIM(c.sexo))) = 'F' THEN 'Femenino' 
              ELSE 'No Informado' END AS varchar(20)) AS Sexo,
    CAST(c.fecha_nacimiento AS date) AS Fecha_Nacimiento,
    CAST(COALESCE(NULLIF(LTRIM(RTRIM(c.estado_civil)), ''), 'No Informado') AS varchar(50)) AS Estado_Civil
FROM Albarran.dbo.clientes c
WHERE NOT EXISTS (SELECT 1 FROM dbo.Dim_Cliente d WHERE d.Cliente_BK = c.cliente_id);

-- ------------------------------------------------------------------------------
-- 3. Dim_Empleado (Desnormalización de Cargo y Sueldo Base)
-- ------------------------------------------------------------------------------
PRINT '>> 3. Cargando Dim_Empleado...';
INSERT INTO dbo.Dim_Empleado (Empleado_BK, Nombre_Completo, Nombre_Cargo, Sueldo_Base, Fecha_Contrato)
SELECT 
    e.empleado_id AS Empleado_BK,
    CAST(LTRIM(RTRIM(COALESCE(e.nombre, ''))) + ' ' + LTRIM(RTRIM(COALESCE(e.appaterno, ''))) + 
        CASE WHEN NULLIF(LTRIM(RTRIM(e.apmaterno)), '') IS NULL THEN '' ELSE ' ' + LTRIM(RTRIM(e.apmaterno)) END AS varchar(150)) AS Nombre_Completo,
    CAST(LTRIM(RTRIM(cg.nombre)) AS varchar(100)) AS Nombre_Cargo,
    CAST(e.sueldo_base AS numeric(12,2)) AS Sueldo_Base,
    CAST(e.fecha_contrato AS date) AS Fecha_Contrato
FROM Albarran.dbo.empleados e 
INNER JOIN Albarran.dbo.cargos cg ON e.cargo_id = cg.cargo_id
WHERE NOT EXISTS (SELECT 1 FROM dbo.Dim_Empleado d WHERE d.Empleado_BK = e.empleado_id);

-- ------------------------------------------------------------------------------
-- 4. Dim_Producto (Tratamiento de Nulos: sustitución de NULL por 'Sin descripción')
-- ------------------------------------------------------------------------------
PRINT '>> 4. Cargando Dim_Producto...';
INSERT INTO dbo.Dim_Producto (Producto_BK, Nombre_Producto, Nombre_Categoria, Precio_Catalogo, Descripcion)
SELECT 
    p.producto_id AS Producto_BK,
    CAST(LTRIM(RTRIM(p.nombre)) AS varchar(100)) AS Nombre_Producto,
    CAST(LTRIM(RTRIM(cat.categoria)) AS varchar(100)) AS Nombre_Categoria,
    CAST(p.precio AS numeric(12,2)) AS Precio_Catalogo,
    CAST(COALESCE(NULLIF(LTRIM(RTRIM(p.descripcion)), ''), 'Sin descripción') AS varchar(255)) AS Descripcion
FROM Albarran.dbo.productos p 
INNER JOIN Albarran.dbo.categorias cat ON p.categoria_id = cat.categoria_id
WHERE NOT EXISTS (SELECT 1 FROM dbo.Dim_Producto d WHERE d.Producto_BK = p.producto_id);

-- ------------------------------------------------------------------------------
-- 5. Fact_Ventas (Resolución de Lookups hacia SKs y Columnas Derivadas de Montos)
-- ------------------------------------------------------------------------------
PRINT '>> 5. Cargando Fact_Ventas con Lookups y Columnas Derivadas...';
INSERT INTO dbo.Fact_Ventas (
    Fecha_SK, Cliente_SK, Empleado_SK, Producto_SK, Sucursal_SK,
    Venta_ID, Cantidad, Precio_Unitario, Monto_Bruto,
    Porcentaje_Descuento, Monto_Descuento, Monto_Neto
)
SELECT 
    ISNULL(t.Fecha_SK, -1) AS Fecha_SK,
    ISNULL(c.Cliente_SK, -1) AS Cliente_SK,
    ISNULL(e.Empleado_SK, -1) AS Empleado_SK,
    ISNULL(p.Producto_SK, -1) AS Producto_SK,
    ISNULL(s.Sucursal_SK, -1) AS Sucursal_SK,
    v.venta_id AS Venta_ID,
    d.cantidad AS Cantidad,
    CAST(d.precio_unitario AS numeric(12,2)) AS Precio_Unitario,
    m.Monto_Bruto,
    CAST(d.descuento AS numeric(5,4)) AS Porcentaje_Descuento,
    x.Monto_Descuento,
    CAST(m.Monto_Bruto - x.Monto_Descuento AS numeric(14,2)) AS Monto_Neto
FROM Albarran.dbo.ventas v
INNER JOIN Albarran.dbo.detalle_ventas d ON v.venta_id = d.venta_id
LEFT JOIN dbo.Dim_Cliente c ON c.Cliente_BK = v.cliente_id
LEFT JOIN dbo.Dim_Empleado e ON e.Empleado_BK = v.vendedor_id
LEFT JOIN dbo.Dim_Producto p ON p.Producto_BK = d.producto_id
LEFT JOIN dbo.Dim_Sucursal s ON s.Sucursal_BK = v.sucursal_id
LEFT JOIN dbo.Dim_Tiempo t ON t.Fecha_SK = CONVERT(int, CONVERT(char(8), v.fecha, 112))
CROSS APPLY (
    SELECT CAST(CAST(d.cantidad AS decimal(20,0)) * CAST(d.precio_unitario AS decimal(12,2)) AS numeric(14,2)) AS Monto_Bruto
) m
CROSS APPLY (
    SELECT CAST(m.Monto_Bruto * CAST(d.descuento AS numeric(5,4)) AS numeric(14,2)) AS Monto_Descuento
) x
WHERE NOT EXISTS (SELECT 1 FROM dbo.Fact_Ventas f WHERE f.Venta_ID = v.venta_id);

-- ------------------------------------------------------------------------------
-- 6. Resumen de Carga Final
-- ------------------------------------------------------------------------------
PRINT '==============================================================================';
PRINT '  CARGA ETL COMPLETADA CON ÉXITO. REGISTROS POR TABLA:';
PRINT '==============================================================================';

SELECT 
    'Dim_Sucursal' AS Tabla, COUNT(*) AS Total_Registros, '3 sucursales + 1 miembro (-1)' AS Detalle FROM dbo.Dim_Sucursal
UNION ALL
SELECT 'Dim_Cliente', COUNT(*), '20 clientes + 1 miembro (-1)' FROM dbo.Dim_Cliente
UNION ALL
SELECT 'Dim_Empleado', COUNT(*), '15 empleados + 1 miembro (-1)' FROM dbo.Dim_Empleado
UNION ALL
SELECT 'Dim_Producto', COUNT(*), '20 productos + 1 miembro (-1)' FROM dbo.Dim_Producto
UNION ALL
SELECT 'Dim_Tiempo', COUNT(*), '3.652 días + 1 miembro (-1)' FROM dbo.Dim_Tiempo
UNION ALL
SELECT 'Fact_Ventas', COUNT(*), '365 ventas del año 2017' FROM dbo.Fact_Ventas;
GO
