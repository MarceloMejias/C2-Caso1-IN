IF EXISTS(SELECT venta_id FROM dbo.ventas GROUP BY venta_id HAVING COUNT(*)>1)
 THROW 51000,'ID de venta duplicado en origen.',1;
IF EXISTS(SELECT venta_id,producto_id FROM dbo.detalle_ventas GROUP BY venta_id,producto_id HAVING COUNT(*)>1)
 THROW 51000,'Grano venta/producto repetido; revisar antes de cargar.',1;
IF EXISTS(SELECT 1 FROM dbo.detalle_ventas d LEFT JOIN dbo.ventas v ON v.venta_id=d.venta_id
 WHERE v.venta_id IS NULL OR d.cantidad IS NULL OR d.cantidad<=0
 OR d.precio_unitario IS NULL OR d.precio_unitario<0 OR d.descuento IS NULL OR d.descuento<0 OR d.descuento>1
 OR TRY_CONVERT(numeric(14,2),CAST(d.cantidad AS decimal(20,0))*CAST(d.precio_unitario AS decimal(12,2))) IS NULL)
 THROW 51000,'Detalle huerfano, cantidad, precio, descuento o monto invalido.',1;
IF EXISTS(SELECT 1 FROM dbo.ventas v WHERE NOT EXISTS(SELECT 1 FROM dbo.detalle_ventas d WHERE d.venta_id=v.venta_id))
 THROW 51000,'Hay ventas sin detalle; resolver antes de cargar.',1;
