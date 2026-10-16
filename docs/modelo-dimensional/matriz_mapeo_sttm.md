# Matriz de Mapeo ETL Origen $\rightarrow$ Destino (Source-to-Target Mapping - STTM)
## Certamen 2 - Inteligencia de Negocios (Mueblería Albarrán)

Esta matriz técnica define las reglas de extracción, transformación y carga (ETL) desde la base de datos transaccional relacional (`Albarran`) hacia el Data Warehouse dimensional (`Albarran_DW`), sirviendo como guía directa para la construcción de los paquetes en **SQL Server Integration Services (SSIS)**.

---

## 1. Paquete SSIS: Carga de `Dim_Sucursal`
* **Paquete sugerido:** `Dim_Sucursal.dtsx`
* **Estrategia de carga:** Truncate & Load (o validación por clave natural `sucursal_id`).

| Campo Origen (`Albarran`) | Tipo Origen | Campo Destino (`Albarran_DW.Dim_Sucursal`) | Tipo Destino | Componente SSIS | Regla de Transformación / Expresión SSIS |
| :--- | :--- | :--- | :--- | :--- | :--- |
| N/A | N/A | `Sucursal_SK` | `INT` | OLE DB Destination | Generado automáticamente por SQL Server (`IDENTITY(1,1)`). |
| `sucursales.sucursal_id` | `INT` | `Sucursal_BK` | `INT` | Data Flow Task | Mapeo directo de la clave de negocio relacional. |
| `sucursales.sucursal` | `VARCHAR(50)` | `Nombre_Sucursal` | `VARCHAR(100)` | Derived Column | `TRIM(sucursal)` para limpiar espacios residuales. |
| `sucursales.comuna_id` $\rightarrow$ `comunas.comuna` | `INT` $\rightarrow$ `VARCHAR(50)` | `Nombre_Comuna` | `VARCHAR(100)` | Lookup (OLE DB) / SQL Query | Join entre `sucursales` y `comunas` por `comuna_id`. Extraer `comuna`. |

---

## 2. Paquete SSIS: Carga de `Dim_Cliente`
* **Paquete sugerido:** `Dim_Cliente.dtsx`
* **Estrategia de carga:** Truncate & Load.

| Campo Origen (`Albarran`) | Tipo Origen | Campo Destino (`Albarran_DW.Dim_Cliente`) | Tipo Destino | Componente SSIS | Regla de Transformación / Expresión SSIS |
| :--- | :--- | :--- | :--- | :--- | :--- |
| N/A | N/A | `Cliente_SK` | `INT` | OLE DB Destination | Generado automáticamente por SQL Server (`IDENTITY(1,1)`). |
| `clientes.cliente_id` | `INT` | `Cliente_BK` | `INT` | Data Flow Task | Mapeo directo de la clave de negocio relacional. |
| `nombre`, `appaterno`, `apmaterno` | `VARCHAR(50)` cada uno | `Nombre_Completo` | `VARCHAR(150)` | Derived Column | `TRIM(nombre) + " " + TRIM(appaterno) + (ISNULL(apmaterno) ? "" : (" " + TRIM(apmaterno)))` |
| `clientes.sexo` | `VARCHAR(1)` | `Sexo` | `VARCHAR(20)` | Derived Column | `UPPER(TRIM(sexo)) == "M" ? "Masculino" : (UPPER(TRIM(sexo)) == "F" ? "Femenino" : "No Informado")` |
| `clientes.fecha_nacimiento` | `DATE` | `Fecha_Nacimiento` | `DATE` | Data Conversion | Mapeo directo (o conversión explícita `DT_DBDATE`). |
| `clientes.estado_civil` | `VARCHAR(50)` | `Estado_Civil` | `VARCHAR(50)` | Derived Column | `ISNULL(estado_civil) ? "No Informado" : TRIM(estado_civil)` |

---

## 3. Paquete SSIS: Carga de `Dim_Empleado`
* **Paquete sugerido:** `Dim_Empleado.dtsx`
* **Estrategia de carga:** Truncate & Load.

| Campo Origen (`Albarran`) | Tipo Origen | Campo Destino (`Albarran_DW.Dim_Empleado`) | Tipo Destino | Componente SSIS | Regla de Transformación / Expresión SSIS |
| :--- | :--- | :--- | :--- | :--- | :--- |
| N/A | N/A | `Empleado_SK` | `INT` | OLE DB Destination | Generado automáticamente por SQL Server (`IDENTITY(1,1)`). |
| `empleados.empleado_id` | `INT` | `Empleado_BK` | `INT` | Data Flow Task | Mapeo directo de la clave de negocio relacional. |
| `nombre`, `appaterno`, `apmaterno` | `VARCHAR(50)` cada uno | `Nombre_Completo` | `VARCHAR(150)` | Derived Column | `TRIM(nombre) + " " + TRIM(appaterno) + (ISNULL(apmaterno) ? "" : (" " + TRIM(apmaterno)))` |
| `empleados.cargo_id` $\rightarrow$ `cargos.nombre` | `INT` $\rightarrow$ `VARCHAR(50)` | `Nombre_Cargo` | `VARCHAR(100)` | Lookup (OLE DB) / SQL Query | Join entre `empleados` y `cargos` por `cargo_id`. Extraer `cargos.nombre`. |
| `empleados.sueldo_base` | `NUMERIC(10,2)` | `Sueldo_Base` | `NUMERIC(12,2)` | Data Conversion | Conversión a `NUMERIC(12,2)` para mantener precisión contable. |
| `empleados.fecha_contrato` | `DATE` | `Fecha_Contrato` | `DATE` | Data Conversion | Mapeo directo `DT_DBDATE`. |

---

## 4. Paquete SSIS: Carga de `Dim_Producto`
* **Paquete sugerido:** `Dim_Producto.dtsx`
* **Estrategia de carga:** Truncate & Load.

| Campo Origen (`Albarran`) | Tipo Origen | Campo Destino (`Albarran_DW.Dim_Producto`) | Tipo Destino | Componente SSIS | Regla de Transformación / Expresión SSIS |
| :--- | :--- | :--- | :--- | :--- | :--- |
| N/A | N/A | `Producto_SK` | `INT` | OLE DB Destination | Generado automáticamente por SQL Server (`IDENTITY(1,1)`). |
| `productos.producto_id` | `INT` | `Producto_BK` | `INT` | Data Flow Task | Mapeo directo de la clave de negocio relacional. |
| `productos.nombre` | `VARCHAR(100)` | `Nombre_Producto` | `VARCHAR(100)` | Derived Column | `TRIM(nombre)`. |
| `productos.categoria_id` $\rightarrow$ `categorias.categoria` | `INT` $\rightarrow$ `VARCHAR(50)` | `Nombre_Categoria` | `VARCHAR(100)` | Lookup (OLE DB) / SQL Query | Join entre `productos` y `categorias` por `categoria_id`. Extraer `categoria`. |
| `productos.precio` | `NUMERIC(10,2)` | `Precio_Catalogo` | `NUMERIC(12,2)` | Data Conversion | Conversión a `NUMERIC(12,2)` para consistencia financiera. |
| `productos.descripcion` | `VARCHAR(255)` | `Descripcion` | `VARCHAR(255)` | Derived Column | **Regla de Calidad Crítica:** `ISNULL(descripcion) ? "Sin descripción" : TRIM(descripcion)` |

---

## 5. Script SQL: Poblado de `Dim_Tiempo`
* **Procedimiento:** Ejecución del script `database/scripts/03_poblar_dim_tiempo.sql` (no requiere paquete SSIS complejo, se ejecuta mediante Execute SQL Task o directamente en SQL Server).
* **Rango:** `2017-01-01` a `2026-12-31` (3.652 días).

| Campo Calculado | Tipo Destino | Algoritmo / Fórmula T-SQL |
| :--- | :--- | :--- |
| `Fecha_SK` | `INT` | `YEAR(Fecha) * 10000 + MONTH(Fecha) * 100 + DAY(Fecha)` (ej. `20170101`). |
| `Fecha` | `DATE` | Fecha calendario iterativa. |
| `Anio` | `INT` | `YEAR(Fecha)` |
| `Semestre` | `TINYINT` | `CASE WHEN MONTH(Fecha) <= 6 THEN 1 ELSE 2 END` |
| `Trimestre` | `TINYINT` | `DATEPART(QUARTER, Fecha)` |
| `Mes` | `TINYINT` | `MONTH(Fecha)` |
| `Nombre_Mes` | `VARCHAR(20)` | Nombre en español (`'Enero'`, `'Febrero'`, etc.). |
| `Dia` | `TINYINT` | `DAY(Fecha)` |
| `Dia_Semana` | `TINYINT` | `DATEPART(WEEKDAY, Fecha)` (con `DATEFIRST 1`: 1=Lunes, 7=Domingo). |
| `Nombre_Dia_Semana` | `VARCHAR(20)` | `'Lunes'`, `'Martes'`, ..., `'Domingo'`. |
| `Es_Fin_De_Semana` | `BIT` | `CASE WHEN DATEPART(WEEKDAY, Fecha) IN (6, 7) THEN 1 ELSE 0 END` |

---

## 6. Paquete SSIS: Carga de `Fact_Ventas`
* **Paquete sugerido:** `Fact_Ventas.dtsx`
* **Origen de datos:** Consulta SQL unificada de detalle de transacciones:
  ```sql
  SELECT 
      v.venta_id,
      v.fecha,
      v.cliente_id,
      v.vendedor_id,
      v.sucursal_id,
      d.producto_id,
      d.cantidad,
      d.precio_unitario,
      d.descuento
  FROM dbo.ventas v
  INNER JOIN dbo.detalle_ventas d ON v.venta_id = d.venta_id;
  ```

| Campo Destino (`Fact_Ventas`) | Tipo Destino | Componente SSIS | Regla de Transformación / Lookup |
| :--- | :--- | :--- | :--- |
| `Venta_SK` | `BIGINT` | OLE DB Destination | Generado automáticamente por SQL Server (`IDENTITY(1,1)`). |
| `Fecha_SK` | `INT` | Derived Column | `YEAR(fecha) * 10000 + MONTH(fecha) * 100 + DAY(fecha)` |
| `Cliente_SK` | `INT` | Lookup (`Dim_Cliente`) | Búsqueda por `Cliente_BK = cliente_id`. Si no hay match, asignar `-1`. |
| `Empleado_SK` | `INT` | Lookup (`Dim_Empleado`) | Búsqueda por `Empleado_BK = vendedor_id`. Si no hay match, asignar `-1`. |
| `Producto_SK` | `INT` | Lookup (`Dim_Producto`) | Búsqueda por `Producto_BK = producto_id`. Si no hay match, asignar `-1`. |
| `Sucursal_SK` | `INT` | Lookup (`Dim_Sucursal`) | Búsqueda por `Sucursal_BK = sucursal_id`. Si no hay match, asignar `-1`. |
| `Venta_ID` | `INT` | Direct Mapping | Mapeo directo de `v.venta_id` como dimensión degenerada. |
| `Cantidad` | `INT` | Direct Mapping | Mapeo directo de `d.cantidad`. |
| `Precio_Unitario` | `NUMERIC(12,2)` | Data Conversion | Conversión de `d.precio_unitario` a tipo moneda decimal. |
| `Monto_Bruto` | `NUMERIC(14,2)` | Derived Column | `(DT_NUMERIC, 14, 2)(cantidad * precio_unitario)` |
| `Porcentaje_Descuento` | `NUMERIC(5,4)` | Data Conversion | Mapeo de `d.descuento` (valor `0.0`). |
| `Monto_Descuento` | `NUMERIC(14,2)` | Derived Column | `(DT_NUMERIC, 14, 2)(Monto_Bruto * Porcentaje_Descuento)` |
| `Monto_Neto` | `NUMERIC(14,2)` | Derived Column | `(DT_NUMERIC, 14, 2)(Monto_Bruto - Monto_Descuento)` |

---

## 7. Cifras de Control para la Validación de la Carga ETL
Al finalizar la ejecución de los paquetes SSIS en `Albarran_DW`, se deben ejecutar las siguientes consultas de validación en SQL Server para comprobar la integridad del proceso:

```sql
USE Albarran_DW;

-- 1. Control de cantidad de transacciones (debe ser 365)
SELECT COUNT(*) AS Total_Filas_Fact FROM dbo.Fact_Ventas;

-- 2. Control de unidades físicas vendidas (debe ser 724)
SELECT SUM(Cantidad) AS Total_Unidades FROM dbo.Fact_Ventas;

-- 3. Control de cuadratura financiera estricta (debe ser exactamente $414.022.446)
SELECT 
    SUM(Monto_Bruto) AS Facturacion_Bruta,
    SUM(Monto_Descuento) AS Descuentos_Totales,
    SUM(Monto_Neto) AS Facturacion_Neta
FROM dbo.Fact_Ventas;

-- 4. Verificación de ausencia de claves huérfanas (-1)
SELECT 
    SUM(CASE WHEN Cliente_SK = -1 THEN 1 ELSE 0 END) AS Clientes_No_Mapeados,
    SUM(CASE WHEN Empleado_SK = -1 THEN 1 ELSE 0 END) AS Empleados_No_Mapeados,
    SUM(CASE WHEN Producto_SK = -1 THEN 1 ELSE 0 END) AS Productos_No_Mapeados,
    SUM(CASE WHEN Sucursal_SK = -1 THEN 1 ELSE 0 END) AS Sucursales_No_Mapeadas
FROM dbo.Fact_Ventas;
```
