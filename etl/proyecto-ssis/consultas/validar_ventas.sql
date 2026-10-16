IF EXISTS(SELECT Fecha_SK,Cliente_SK,Empleado_SK,Producto_SK,Sucursal_SK,Venta_ID,Cantidad,Precio_Unitario,Monto_Bruto,Porcentaje_Descuento,Monto_Descuento,Monto_Neto,COUNT_BIG(*) Repeticiones FROM (SELECT ISNULL(t.Fecha_SK,-1) Fecha_SK,ISNULL(c.Cliente_SK,-1) Cliente_SK,
 ISNULL(e.Empleado_SK,-1) Empleado_SK,ISNULL(p.Producto_SK,-1) Producto_SK,
 ISNULL(s.Sucursal_SK,-1) Sucursal_SK,v.venta_id Venta_ID,d.cantidad Cantidad,
 CAST(d.precio_unitario AS numeric(12,2)) Precio_Unitario,
 m.Monto_Bruto,CAST(d.descuento AS numeric(5,4)) Porcentaje_Descuento,
 x.Monto_Descuento,CAST(m.Monto_Bruto-x.Monto_Descuento AS numeric(14,2)) Monto_Neto
 FROM Albarran.dbo.ventas v JOIN Albarran.dbo.detalle_ventas d ON d.venta_id=v.venta_id
 LEFT JOIN dbo.Dim_Cliente c ON c.Cliente_BK=v.cliente_id
 LEFT JOIN dbo.Dim_Empleado e ON e.Empleado_BK=v.vendedor_id
 LEFT JOIN dbo.Dim_Producto p ON p.Producto_BK=d.producto_id
 LEFT JOIN dbo.Dim_Sucursal s ON s.Sucursal_BK=v.sucursal_id
 LEFT JOIN dbo.Dim_Tiempo t ON t.Fecha_SK=CONVERT(int,CONVERT(char(8),v.fecha,112))
 CROSS APPLY(SELECT CAST(CAST(d.cantidad AS decimal(20,0))*CAST(d.precio_unitario AS decimal(12,2)) AS numeric(14,2)) Monto_Bruto) m
 CROSS APPLY(SELECT CAST(m.Monto_Bruto*CAST(d.descuento AS numeric(5,4)) AS numeric(14,2)) Monto_Descuento) x) esperado GROUP BY Fecha_SK,Cliente_SK,Empleado_SK,Producto_SK,Sucursal_SK,Venta_ID,Cantidad,Precio_Unitario,Monto_Bruto,Porcentaje_Descuento,Monto_Descuento,Monto_Neto
 EXCEPT SELECT Fecha_SK,Cliente_SK,Empleado_SK,Producto_SK,Sucursal_SK,Venta_ID,Cantidad,Precio_Unitario,Monto_Bruto,Porcentaje_Descuento,Monto_Descuento,Monto_Neto,COUNT_BIG(*) FROM dbo.Fact_Ventas GROUP BY Fecha_SK,Cliente_SK,Empleado_SK,Producto_SK,Sucursal_SK,Venta_ID,Cantidad,Precio_Unitario,Monto_Bruto,Porcentaje_Descuento,Monto_Descuento,Monto_Neto)
 OR EXISTS(SELECT Fecha_SK,Cliente_SK,Empleado_SK,Producto_SK,Sucursal_SK,Venta_ID,Cantidad,Precio_Unitario,Monto_Bruto,Porcentaje_Descuento,Monto_Descuento,Monto_Neto,COUNT_BIG(*) FROM dbo.Fact_Ventas GROUP BY Fecha_SK,Cliente_SK,Empleado_SK,Producto_SK,Sucursal_SK,Venta_ID,Cantidad,Precio_Unitario,Monto_Bruto,Porcentaje_Descuento,Monto_Descuento,Monto_Neto
 EXCEPT SELECT Fecha_SK,Cliente_SK,Empleado_SK,Producto_SK,Sucursal_SK,Venta_ID,Cantidad,Precio_Unitario,Monto_Bruto,Porcentaje_Descuento,Monto_Descuento,Monto_Neto,COUNT_BIG(*) FROM (SELECT ISNULL(t.Fecha_SK,-1) Fecha_SK,ISNULL(c.Cliente_SK,-1) Cliente_SK,
 ISNULL(e.Empleado_SK,-1) Empleado_SK,ISNULL(p.Producto_SK,-1) Producto_SK,
 ISNULL(s.Sucursal_SK,-1) Sucursal_SK,v.venta_id Venta_ID,d.cantidad Cantidad,
 CAST(d.precio_unitario AS numeric(12,2)) Precio_Unitario,
 m.Monto_Bruto,CAST(d.descuento AS numeric(5,4)) Porcentaje_Descuento,
 x.Monto_Descuento,CAST(m.Monto_Bruto-x.Monto_Descuento AS numeric(14,2)) Monto_Neto
 FROM Albarran.dbo.ventas v JOIN Albarran.dbo.detalle_ventas d ON d.venta_id=v.venta_id
 LEFT JOIN dbo.Dim_Cliente c ON c.Cliente_BK=v.cliente_id
 LEFT JOIN dbo.Dim_Empleado e ON e.Empleado_BK=v.vendedor_id
 LEFT JOIN dbo.Dim_Producto p ON p.Producto_BK=d.producto_id
 LEFT JOIN dbo.Dim_Sucursal s ON s.Sucursal_BK=v.sucursal_id
 LEFT JOIN dbo.Dim_Tiempo t ON t.Fecha_SK=CONVERT(int,CONVERT(char(8),v.fecha,112))
 CROSS APPLY(SELECT CAST(CAST(d.cantidad AS decimal(20,0))*CAST(d.precio_unitario AS decimal(12,2)) AS numeric(14,2)) Monto_Bruto) m
 CROSS APPLY(SELECT CAST(m.Monto_Bruto*CAST(d.descuento AS numeric(5,4)) AS numeric(14,2)) Monto_Descuento) x) esperado GROUP BY Fecha_SK,Cliente_SK,Empleado_SK,Producto_SK,Sucursal_SK,Venta_ID,Cantidad,Precio_Unitario,Monto_Bruto,Porcentaje_Descuento,Monto_Descuento,Monto_Neto)
 THROW 51000,'Fact_Ventas difiere del origen: filas, claves, importes o multiplicidad. No se modifica una carga existente.',1;
IF EXISTS(SELECT 1 FROM dbo.Fact_Ventas f
 LEFT JOIN dbo.Dim_Cliente c ON c.Cliente_SK=f.Cliente_SK
 LEFT JOIN dbo.Dim_Empleado e ON e.Empleado_SK=f.Empleado_SK
 LEFT JOIN dbo.Dim_Producto p ON p.Producto_SK=f.Producto_SK
 LEFT JOIN dbo.Dim_Sucursal s ON s.Sucursal_SK=f.Sucursal_SK
 LEFT JOIN dbo.Dim_Tiempo t ON t.Fecha_SK=f.Fecha_SK
 WHERE c.Cliente_SK IS NULL OR e.Empleado_SK IS NULL OR p.Producto_SK IS NULL OR s.Sucursal_SK IS NULL OR t.Fecha_SK IS NULL)
 THROW 51000,'Clave dimensional huerfana en Fact_Ventas.',1;
