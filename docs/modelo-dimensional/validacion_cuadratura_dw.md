# Protocolo de Validación, Cuadratura Contable y Backup del Data Warehouse
## Certamen 2 - Inteligencia de Negocios (Mueblería Albarrán)

Este documento describe el protocolo formal de auditoría y certificación de calidad de datos implementado en el script SQL [`database/scripts/04_validacion_cuadratura_dw.sql`](../../database/scripts/04_validacion_cuadratura_dw.sql). Su propósito es garantizar la reconciliación matemática, volumétrica y referencial estricta entre la fuente relacional transaccional (`Albarran`) y el Data Warehouse dimensional (`Albarran_DW`).

---

### 1. Marco Teórico y Justificación Metodológica

En proyectos de Business Intelligence bajo la metodología de Ralph Kimball, la etapa de **Aseguramiento de Calidad y Cuadratura (Data Quality & Reconciliation)** es crítica para certificar que el proceso ETL no altere los números contables ni extravíe registros de ventas.

El principio rector es **Tolerancia Cero a la Discrepancia Financiera**:
$$\sum \text{Monto\_Neto}_{\text{DW}} \equiv \sum (\text{Cantidad} \times \text{Precio\_Unitario} - \text{Descuento})_{\text{OLTP}} = \$414.022.446\text{ CLP}$$

Cualquier diferencia, por mínima que sea, invalida el proceso ETL y compromete la veracidad de los dashboards analíticos posteriores.

---

### 2. Matriz de Pruebas de Auditoría Automatizada

El script ejecuta 9 pruebas independientes organizadas en cuatro dimensiones de calidad:

| ID | Categoría | Prueba de Control | Fórmula / Consulta de Validación | Valor Esperado (Benchmark) | Criterio de Aprobación |
| :-: | :--- | :--- | :--- | :--- | :--- |
| **01** | Volumetría | Conteo de Transacciones | `COUNT(*) FROM Fact_Ventas` vs `COUNT(DISTINCT venta_id) FROM ventas` | **365 transacciones** | Igualdad exacta (0 diferencia). |
| **02** | Volumetría | Unidades Físicas Vendidas | `SUM(Cantidad) FROM Fact_Ventas` vs `SUM(cantidad) FROM detalle_ventas` | **724 unidades** | Igualdad exacta (0 diferencia). |
| **03** | Financiero | Facturación Bruta Total | `SUM(Monto_Bruto) FROM Fact_Ventas` vs `SUM(cantidad * precio_unitario)` | **$ 414.022.446 CLP** | Diferencia = $0 CLP. |
| **04** | Financiero | Monto Total de Descuentos | `SUM(Monto_Descuento) FROM Fact_Ventas` vs `SUM(bruto * descuento)` | **$ 0 CLP** | Descuento total = $0.00. |
| **05** | Financiero | Facturación Neta Total | `SUM(Monto_Neto) FROM Fact_Ventas` vs `SUM(bruto - desc)` | **$ 414.022.446 CLP** | Diferencia = $0 CLP. |
| **06** | Integridad FK | Cero Huérfanos en Hechos | `SUM(CASE WHEN _SK = -1 THEN 1 ELSE 0 END) FROM Fact_Ventas` | **0 huérfanos** | Ninguna transacción asignada a miembro desconocido. |
| **07** | Calidad Datos | Nulos en Descripción | `COUNT(*) FROM Dim_Producto WHERE Descripcion IS NULL` | **0 registros** | Todo nulo transformado a `'Sin descripción'`. |
| **08** | Modelo Kimball | Miembros Desconocidos (-1) | Comprobar existencia de fila `SK = -1` en las 5 dimensiones | **5 dimensiones** | 100% de dimensiones con fila `-1`. |
| **09** | Modelo Kimball | Calendario en `Dim_Tiempo` | `COUNT(*) FROM Dim_Tiempo WHERE Fecha_SK <> -1` | **3.652 días** | Rango `2017-01-01` a `2026-12-31` completo. |

---

### 3. Estados de la Auditoría: Pre-ETL vs Post-ETL

#### 3.1 Estado Inicial (Pre-ETL en macOS / Desarrollo)
Antes de ejecutar los paquetes SSIS en Visual Studio, el script audita la infraestructura física y DDL de `Albarran_DW`:
* **Resultado:** Las pruebas de esquema DDL (miembros `-1`, manejo de nulos) aprueban (`APROBADO [PASS]`), mientras que las métricas volumétricas y financieras se marcan como `PENDIENTE (Requiere ETL SSIS)`, confirmando que la base no ha sido "rellenada" con datos sintéticos y espera la ejecución limpia de SSIS.

#### 3.2 Estado Final Esperado (Post-ETL en Windows)
Una vez que el equipo ejecute el paquete `00_Master_ETL.dtsx` en Visual Studio 2022:
* Todas las 9 pruebas deben arrojar **`APROBADO [PASS]`**.
* El mensaje de salida en la consola de SSMS debe certificar:
  `>> ÉXITO TOTAL: Todas las pruebas de cuadratura contable y volumetría fueron APROBADAS.`

---

### 4. Procedimiento Operativo de Backup Final (`Albarran_DW.bak`)

Una vez superada la auditoría con 100% de éxito, se genera el respaldo oficial de la base dimensional solicitado en las instrucciones del certamen:

#### 4.1 Script T-SQL de Generación
```sql
USE master;
GO

BACKUP DATABASE [Albarran_DW]
TO DISK = N'/var/opt/mssql/backup/Albarran_DW.bak' -- En Windows: N'C:\...\database\backup\Albarran_DW.bak'
WITH FORMAT,
     INIT,
     NAME = N'Albarran_DW-Full-Backup-PostETL',
     COMPRESSION,
     CHECKSUM,
     STATS = 10;
GO
```

#### 4.2 Verificación de Integridad del Archivo
Para asegurar que el archivo `.bak` no esté corrupto y pueda ser restaurado por el profesor o cualquier evaluador:
```sql
RESTORE VERIFYONLY
FROM DISK = N'/var/opt/mssql/backup/Albarran_DW.bak'
WITH CHECKSUM;
GO
```

Si el motor devuelve `The backup set on file 1 is valid`, el archivo queda certificado para entrega.
El archivo generado se almacena en la carpeta `database/backup/Albarran_DW.bak`.
