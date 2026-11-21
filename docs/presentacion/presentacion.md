---
marp: true
theme: default
paginate: true
---

# Mueblería Albarrán
## Solución de Inteligencia de Negocios (Fase 1 y 2)

Marcelo Mejías Caviedes  
Certamen 2 — Caso 1

---

## 1. Problema y Objetivo

- **Situación:** Datos transaccionales en SQL Server (`Albarran`) sin trazabilidad histórica ni indicadores consolidados.
- **Objetivo:** Implementar un Data Warehouse (Kimball), proceso ETL, cubo OLAP y dashboard ejecutivo para monitorear ventas, sucursales, productos, vendedores y clientes.

---

## 2. Arquitectura de la Solución

```text
Albarran (OLTP) ──► SSIS (etl/Albarran) ──► Albarran_DW (Estrella) ──► SSAS (Albarran_OLAP) ──► Power BI (dashboard.pbix)
```

- **Motor SQL:** SQL Server 2022 (`localhost`)
- **ETL:** Visual Studio 2026 / SSIS (`Dim_Sucursal`, `Dim_Producto`, `Dim_Empleado`, `Dim_Cliente`, `Fact_Ventas`)
- **OLAP:** SSAS Multidimensional (`Cubo_Ventas_Albarran`)
- **BI:** Power BI Desktop en conexión dinámica (*Live Connection*)

---

## 3. Modelo Dimensional (Kimball)

- **Tabla de Hechos:** `Fact_Ventas` (granularidad: línea de detalle de venta)
- **Dimensiones:** `Dim_Tiempo`, `Dim_Sucursal`, `Dim_Producto`, `Dim_Empleado`, `Dim_Cliente`
- **Integridad:** Miembro desconocido (`SK = -1`) en las 5 dimensiones

---

## 4. Calidad de Datos y Cuadratura (9/9 Aprobadas)

| Prueba | Origen (`Albarran`) | Destino (`Albarran_DW`) | Estado |
| :--- | ---: | ---: | :---: |
| Transacciones (`Fact_Ventas`) | 365 | 365 | PASS |
| Unidades vendidas | 724 | 724 | PASS |
| Facturación neta (CLP) | $414.022.446 | $414.022.446 | PASS |
| Claves no mapeadas (`SK = -1`) | 0 | 0 | PASS |

---

## 5. Cubo OLAP y KPIs Clave

- **KPI-01 Ingresos Totales:** `$414.022.446` CLP
- **KPI-02 Ticket Promedio:** `$1.134.308` CLP (`365` ventas)
- **KPI-03 Unidades por Categoría:** `724` unidades (lideran Comedores y Bares)
- **KPI-04 Ventas por Sucursal:** Manquehue (`$149,3M`), Viña del Mar (`$134,5M`), Franklin (`$130,2M`)
- **KPI-05 Rendimiento Vendedores:** `6` vendedores evaluados frente a sueldo base (`$255.000`)
- **KPI-06 Perfil de Clientes:** `89%` de las ventas corresponden a clientes casados

---

## 6. Dashboard Power BI y Conclusiones

- **Dashboard:** Conexión en vivo a `Cubo_Ventas_Albarran` con tarjetas KPI, evolución mensual, ranking por sucursal/categoría/vendedor, perfil de clientes y segmentadores dinámicos.
- **Decisiones habilitadas:**
  - Priorizar stock en **Comedores y Bares**.
  - Potenciar campañas orientadas a **hogares/familias** (`89%` casados).
  - Monitorear metas comerciales por sucursal y vendedor.

