IF NOT EXISTS(SELECT 1 FROM dbo.Dim_Cliente WHERE Cliente_SK=-1 AND Cliente_BK=-1)
 THROW 51000,'Falta miembro desconocido en Dim_Cliente.',1;
IF EXISTS(SELECT Cliente_BK FROM dbo.Dim_Cliente GROUP BY Cliente_BK HAVING COUNT(*)>1)
 THROW 51000,'Clave de negocio duplicada en Dim_Cliente.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.Dim_Cliente WHERE Cliente_SK<>-1)
 THROW 51000,'Cargar Dim_Cliente antes de Fact_Ventas.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.Dim_Empleado WHERE Empleado_SK=-1 AND Empleado_BK=-1)
 THROW 51000,'Falta miembro desconocido en Dim_Empleado.',1;
IF EXISTS(SELECT Empleado_BK FROM dbo.Dim_Empleado GROUP BY Empleado_BK HAVING COUNT(*)>1)
 THROW 51000,'Clave de negocio duplicada en Dim_Empleado.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.Dim_Empleado WHERE Empleado_SK<>-1)
 THROW 51000,'Cargar Dim_Empleado antes de Fact_Ventas.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.Dim_Producto WHERE Producto_SK=-1 AND Producto_BK=-1)
 THROW 51000,'Falta miembro desconocido en Dim_Producto.',1;
IF EXISTS(SELECT Producto_BK FROM dbo.Dim_Producto GROUP BY Producto_BK HAVING COUNT(*)>1)
 THROW 51000,'Clave de negocio duplicada en Dim_Producto.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.Dim_Producto WHERE Producto_SK<>-1)
 THROW 51000,'Cargar Dim_Producto antes de Fact_Ventas.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.Dim_Sucursal WHERE Sucursal_SK=-1 AND Sucursal_BK=-1)
 THROW 51000,'Falta miembro desconocido en Dim_Sucursal.',1;
IF EXISTS(SELECT Sucursal_BK FROM dbo.Dim_Sucursal GROUP BY Sucursal_BK HAVING COUNT(*)>1)
 THROW 51000,'Clave de negocio duplicada en Dim_Sucursal.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.Dim_Sucursal WHERE Sucursal_SK<>-1)
 THROW 51000,'Cargar Dim_Sucursal antes de Fact_Ventas.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.Dim_Tiempo WHERE Fecha_SK=-1 AND Fecha_SK=-1)
 THROW 51000,'Falta miembro desconocido en Dim_Tiempo.',1;
IF EXISTS(SELECT Fecha_SK FROM dbo.Dim_Tiempo GROUP BY Fecha_SK HAVING COUNT(*)>1)
 THROW 51000,'Clave de negocio duplicada en Dim_Tiempo.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.Dim_Tiempo WHERE Fecha_SK<>-1)
 THROW 51000,'Cargar Dim_Tiempo antes de Fact_Ventas.',1;
IF EXISTS(SELECT 1 FROM dbo.Fact_Ventas)
BEGIN
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
END;
