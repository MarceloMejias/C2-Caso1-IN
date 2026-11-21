# Informe Técnico y de Negocio — Certamen 2 (Caso 1: Mueblería Albarrán)

**Autor:** Marcelo Mejías Caviedes  
**Asignatura:** Inteligencia de Negocios — Universidad Técnica Federico Santa María  
**Repositorio:** `C2-Caso1-IN`

---

## 1. Resumen Ejecutivo

El presente informe documenta el diseño, implementación y validación de una solución integral de Inteligencia de Negocios para **Mueblería Albarrán**, construida en dos fases bajo la metodología dimensional de **Ralph Kimball**:

- **Fase 1:** Análisis exploratorio sobre la base transaccional `Albarran`, definición de 6 KPIs estratégicos, diseño e implementación del Data Warehouse `Albarran_DW` en SQL Server 2022, y construcción del proceso ETL en **SQL Server Integration Services (SSIS)** con auditoría de cuadratura (`9/9` pruebas aprobadas).
- **Fase 2:** Construcción y procesamiento del cubo multidimensional `Cubo_Ventas_Albarran` en **SQL Server Analysis Services (SSAS)** y desarrollo del dashboard ejecutivo en **Power BI Desktop** (`powerbi/dashboard.pbix`) mediante conexión dinámica (*Live Connection*).

Los resultados consolidados para el período analizado (año **2017**) registran **365 transacciones**, **724 unidades vendidas**, una facturación neta total de **$414.022.446 CLP** y un ticket promedio de **$1.134.308 CLP**.

---

## 2. Análisis Exploratorio y Diagnóstico de Calidad de Datos

A partir de la exploración realizada en [notebooks/modelo_de_negocios.ipynb](../../notebooks/modelo_de_negocios.ipynb) sobre las 9 tablas de la base de datos transaccional `Albarran`, se identificaron los siguientes hallazgos críticos que guiaron el modelado y las reglas de transformación en ETL:

1. **Valores nulos en productos:** La columna `descripcion` de la tabla `productos` presenta **20 valores `NULL` de un total de 20 registros (100% nula)**.
   - *Regla ETL:* En `Dim_Producto.dtsx` se sustituye `NULL` por `"Sin descripción"` para evitar nulos en el Data Warehouse.
2. **Fuerza de ventas concentrada:** De los **15 empleados** registrados, exactamente **6 corresponden al cargo `vendedor` (IDs 1 al 6)** y concentran el **100% de las 365 ventas**. Los 9 restantes (cajeros, mueblistas, bodegueros, encargados de despacho) registran 0 ventas.
   - *Impacto en modelado:* `Dim_Empleado` incorpora `Nombre_Cargo` y `Sueldo_Base` para analizar tanto productividad comercial como estructura de costos.
3. **Período temporal acotado:** Todas las transacciones corresponden al **año 2017** (del 1 de enero al 30 de diciembre de 2017, en 227 días con actividad).
   - *Impacto en modelado:* `Dim_Tiempo` se pobló con calendario completo (2017–2026, 3.652 días + miembro desconocido `SK = -1`).
4. **Consistencia financiera y granularidad:**
   - El precio cobrado en `detalle_ventas` coincide exactamente con el precio de lista en `productos`.
   - El campo `descuento` es `0.0` en todas las ventas (`Monto_Descuento = $0`).
   - Existe una relación 1 a 1 entre `ventas` y `detalle_ventas` (365 registros en ambas tablas).
   - La facturación total de control es **$414.022.446 CLP**.

---

## 3. KPIs Definidos y Principales Hallazgos de Negocio

| KPI | Nombre | Fórmula | Resultado Observado | Utilidad para la Toma de Decisiones |
| :--- | :--- | :--- | :--- | :--- |
| **KPI-01** | **Ingresos Totales por Ventas** | $\sum (\text{Cantidad} \times \text{Precio Unitario})$ | **$414.022.446 CLP** | Monitorear el volumen total de ingresos y su evolución mensual. |
| **KPI-02** | **Ticket Promedio** | $\frac{\text{Monto Neto}}{\text{Total Ventas}}$ | **$1.134.308 CLP** (`365` ventas) | Evaluar el gasto promedio por compra y estrategias de venta cruzada. |
| **KPI-03** | **Unidades por Categoría** | $\sum \text{Cantidad}$ por categoría | **724 unidades** | Planificar compras, reposición y stock según rotación por línea. |
| **KPI-04** | **Ventas por Sucursal** | $\sum \text{Monto Neto}$ por tienda | Manquehue **$149,3M**, Viña **$134,5M**, Franklin **$130,2M** | Comparar desempeño comercial entre tiendas físicas. |
| **KPI-05** | **Rendimiento por Vendedor** | Monto vendido y N° de ventas vs. `Sueldo_Base` | `6` vendedores (`>$63M`/año c/u; sueldo base `$255.000`/mes) | Evaluar productividad comercial y esquemas de incentivos. |
| **KPI-06** | **Perfil de Clientes** | $\% \text{ ventas}$ por estado civil y sexo | **89,4%** casados (`$370M`), **68,7%** masculino | Enfocar campañas de marketing y catálogo en el público objetivo. |

### Síntesis de hallazgos por indicador
- **Categorías líderes (KPI-03):** **Comedores** es la categoría estrella con **194 unidades vendidas** y **$119,2M CLP** (~30% de la facturación). Junto a **Sofás** (`$68,1M`) y **Dormitorio** (`$55,3M`), explican el **58,6%** de los ingresos totales.
- **Desempeño por tienda (KPI-04):** Las tres sucursales presentan un volumen parejo de transacciones (entre 113 y 129 ventas al año). **Manquehue (Las Condes)** lidera en ingresos con **$149,3M CLP (36,1%)** por su mayor ticket promedio (`$1,21M`), mientras **Viña del Mar** lidera en número de compras (**129 transacciones**, `$134,5M`) y **Franklin** aporta `$130,2M`.
- **Productividad del equipo comercial (KPI-05):** Con un sueldo base de **$255.000 CLP mensuales**, cada vendedor generó más de **$63M CLP** en el año. **Romina Vásquez** (`$77M`) y **Pamela Cortez** (`$76M`) encabezan la facturación, mientras **Javier Contreras** registró la mayor cantidad de transacciones (**69 compras**).

---

## 4. Diseño del Modelo Dimensional (Metodología de Kimball)

El diseño de `Albarran_DW` sigue los 4 pasos de Ralph Kimball en un **esquema estrella**:

1. **Proceso de negocio:** Proceso comercial de ventas en tiendas físicas de Mueblería Albarrán.
2. **Granularidad:** Nivel atómico — una fila por cada línea de producto vendida dentro de una transacción (`detalle_ventas`).
3. **Dimensiones (con claves sustitutas `SK`, claves de negocio `BK` y miembro desconocido `SK = -1`):**
   - `Dim_Tiempo` (`Fecha_SK` `YYYYMMDD`, `Fecha`, `Anio`, `Semestre`, `Trimestre`, `Mes`, `Nombre_Mes`, `Dia`, `Dia_Semana`, `Nombre_Dia_Semana`, `Es_Fin_De_Semana`).
   - `Dim_Sucursal` (`Sucursal_SK`, `Sucursal_BK`, `Nombre_Sucursal`, `Nombre_Comuna`).
   - `Dim_Producto` (`Producto_SK`, `Producto_BK`, `Nombre_Producto`, `Nombre_Categoria`, `Precio_Catalogo`, `Descripcion`).
   - `Dim_Empleado` (`Empleado_SK`, `Empleado_BK`, `Nombre_Completo`, `Nombre_Cargo`, `Sueldo_Base`, `Fecha_Contrato`).
   - `Dim_Cliente` (`Cliente_SK`, `Cliente_BK`, `Nombre_Completo`, `Sexo`, `Fecha_Nacimiento`, `Estado_Civil`).
4. **Tabla de hechos (`Fact_Ventas`):**
   - **Claves foráneas:** `Fecha_SK`, `Cliente_SK`, `Empleado_SK`, `Producto_SK`, `Sucursal_SK`.
   - **Dimensión degenerada:** `Venta_ID` (folio de boleta/comprobante).
   - **Métricas aditivas:** `Cantidad`, `Precio_Unitario`, `Monto_Bruto`, `Descuento`, `Monto_Descuento`, `Monto_Neto`.

---

## 5. Implementación Fase 1: Data Warehouse y ETL (SSIS)

- **Scripts SQL (`database/scripts/`):**
  - `02_crear_modelo_dimensional.sql`: Creación de `Albarran_DW`, tablas dimensionales, `Fact_Ventas`, restricciones de clave foránea e inserción de miembros `SK = -1`.
  - `03_poblar_dim_tiempo.sql`: Carga del calendario completo 2017–2026 (`3.652` días + `SK = -1` = `3.653` filas).
  - `04_validacion_cuadratura_dw.sql`: Auditoría automática origen vs. destino.
- **Proyecto SSIS (`etl/Albarran/`):**
  - Solución nativa para Visual Studio 2026 (`Albarran.slnx` / `Albarran.dtproj`) con conexiones de proyecto `Albarran_OLTP.conmgr` y `Albarran_DW.conmgr` (`MSOLEDBSQL19.1` hacia `localhost`, `Trust Server Certificate=True`).
  - Flujo de carga modular en 5 paquetes: `Dim_Sucursal.dtsx`, `Dim_Producto.dtsx`, `Dim_Empleado.dtsx`, `Dim_Cliente.dtsx` y `Fact_Ventas.dtsx`, todos ejecutados con resultado `DTSER_SUCCESS (0)`.
- **Validación de cuadratura (`04_validacion_cuadratura_dw.sql`):** **9 de 9 pruebas `APROBADO [PASS]`**:
  - Transacciones en `Fact_Ventas`: `365` vs `365` (diferencia `0`).
  - Unidades vendidas: `724` vs `724` (diferencia `0`).
  - Facturación bruta y neta: `$414.022.446` vs `$414.022.446` (diferencia `$0`).
  - Descuentos: `$0` vs `$0`.
  - Claves no mapeadas (`SK = -1` en `Fact_Ventas`): `0`.
  - Valores `NULL` en `Dim_Producto.Descripcion`: `0`.
  - Presencia de miembro `SK = -1` en las 5 dimensiones y calendario completo en `Dim_Tiempo` (`3.652` días).
- **Respaldo:** Generado y validado en `database/backup/Albarran_DW.bak` (SQL Server 2022).

---

## 6. Implementación Fase 2: Cubo OLAP (SSAS) y Dashboard (Power BI)

### 6.1 Cubo OLAP (`olap/Albarran_OLAP (SSAS)/`)
- **Base desplegada:** `Albarran_OLAP` en SQL Server Analysis Services (`localhost`), conectada a `Albarran_DW` con modo de suplantación `ImpersonateServiceAccount` (`NT Service\MSSQLServerOLAPService` con rol `db_datareader`).
- **Cubo:** `Cubo_Ventas_Albarran` (estado `Processed`).
- **Dimensiones y jerarquías:** `Dim Tiempo` (jerarquía `Calendario`), `Dim Sucursal`, `Dim Producto`, `Dim Empleado` y `Dim Cliente`.
- **Medidas y cálculo MDX:**
  - Medidas base: `Monto Neto`, `Monto Bruto`, `Monto Descuento`, `Cantidad`, `Precio Unitario`, `Fact Ventas Count`, `Total_Ventas` (`DistinctCount` de `Venta_ID`).
  - Medida calculada MDX en `Cubo_Ventas_Albarran.cube`:
    ```mdx
    CALCULATE;
    CREATE MEMBER CURRENTCUBE.[Measures].[Ticket Promedio]
     AS IIF([Measures].[Total_Ventas] = 0, NULL, [Measures].[Monto Neto] / [Measures].[Total_Ventas]),
    FORMAT_STRING = "Currency",
    VISIBLE = 1;
    ```
- **Verificación MDX directa sobre el cubo procesado:** `Monto Neto = 414.022.446`, `Total_Ventas = 365`, `Ticket Promedio = 1.134.308,07`, `Cantidad = 724`.

### 6.2 Dashboard Power BI (`powerbi/dashboard.pbix`)
- Conectado dinámicamente (*Live Connection*) a `Cubo_Ventas_Albarran` en `localhost`.
- Visualizaciones orientadas a los 6 KPIs: tarjetas ejecutivas, evolución temporal, comparativa por sucursal, rotación por categoría/producto, rendimiento por vendedor y segmentación demográfica de clientes, acompañadas de segmentadores interactivos.

---

## 7. Conclusiones y Recomendaciones

1. **Foco comercial en líneas de mayor tracción:** Asegurar disponibilidad de stock y exhibición prioritaria en **Comedores**, **Sofás** y **Dormitorio**, que concentran cerca del 59% de los ingresos.
2. **Estrategia de marketing dirigida:** Dado que el **89,4%** de las ventas proviene de clientes casados, orientar promociones y paquetes de amoblado integral hacia hogares y familias.
3. **Gestión diferenciada por sucursal:** Replicar en **Viña del Mar** y **Franklin** las prácticas de venta de productos de mayor valor o venta cruzada que explican el ticket promedio superior de **Manquehue**.
4. **Trazabilidad y reproducibilidad:** La solución completa (SQL, SSIS, SSAS, respaldo `.bak` y Power BI) queda documentada y versionada en GitHub con validación de cuadratura automatizada.

