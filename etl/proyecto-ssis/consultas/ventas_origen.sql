-- Snapshot inicial: decidir antes de comenzar el flujo para no observar sus inserciones.
DECLARE @Cargar bit=CASE WHEN EXISTS(SELECT 1 FROM Albarran_DW.dbo.Fact_Ventas) THEN 0 ELSE 1 END;
SELECT v.venta_id AS Venta_ID,ISNULL(v.cliente_id,-1) AS Cliente_BK,
 ISNULL(v.vendedor_id,-1) AS Empleado_BK,ISNULL(d.producto_id,-1) AS Producto_BK,
 ISNULL(v.sucursal_id,-1) AS Sucursal_BK,
 ISNULL(CONVERT(int,CONVERT(char(8),v.fecha,112)),-1) AS Fecha_BK,
 d.cantidad AS Cantidad,CAST(d.precio_unitario AS numeric(12,2)) AS Precio_Unitario,
 CAST(d.descuento AS numeric(5,4)) AS Porcentaje_Descuento
FROM dbo.ventas v JOIN dbo.detalle_ventas d ON d.venta_id=v.venta_id
WHERE @Cargar=1;
