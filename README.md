# Certamen 2 - Inteligencia de Negocios

## Caso seleccionado

**Caso 1: Mueblería Albarrán**

## Integrantes y sección

- **Integrantes:**
  - Marcelo Mejías Caviedes — paralelo 301
  - Mishas Silva — paralelo 300
  - Natalia Cárdenas — paralelo 301

**Profesor:** Hernán Saavedra

---

## Descripción del problema

La Mueblería Albarrán es una empresa innovadora en el rubro de la mueblería que ha experimentado un crecimiento acelerado en los últimos años. Con sucursales comerciales y una diversidad de líneas de productos (arrimos, banquetas, comedores, bares, entre otros), su propietario requiere incorporar Inteligencia de Negocios para analizar la información operativa, evaluar el desempeño de ventas y apoyar la toma de decisiones estratégicas.

---

## Objetivo del proyecto

Diseñar e implementar una solución integral de Inteligencia de Negocios basada en la metodología de Ralph Kimball, que permita extraer, transformar y cargar los datos desde la base transaccional (`Albarran`) hacia un Data Warehouse dimensional en SQL Server, facilitando el análisis multidimensional y la visualización de indicadores de gestión clave (KPIs).

---

## KPI definidos

A partir de la exploración de datos en [notebooks/modelo_de_negocios.ipynb](file:///notebooks/modelo_de_negocios.ipynb), se definieron 6 KPIs clave para el seguimiento del negocio:

| KPI | Nombre | Fórmula | ¿Para qué le sirve al dueño? |
| :---: | :--- | :--- | :--- |
| **KPI-01** | **Ingresos Totales por Ventas** | $\sum (\text{Cantidad} \times \text{Precio Unitario})$ | Mide cuánto dinero entra al negocio ($414.022.446 CLP en 2017) para ver la evolución mes a mes. |
| **KPI-02** | **Ticket Promedio** | $\frac{\text{Ingreso Total}}{\text{Total de Ventas}}$ | Muestra el gasto promedio por compra ($1.134.308 CLP) para evaluar venta de complementos. |
| **KPI-03** | **Unidades por Categoría** | $\sum \text{Cantidad por Categoría}$ | Identifica los muebles con mayor salida (Comedores y Bares) para planificar compras y stock. |
| **KPI-04** | **Ventas por Sucursal** | $\sum \text{Venta Neta por Tienda}$ | Compara la facturación de las tiendas: Manquehue ($149,3M), Viña del Mar ($134,5M) y Franklin ($130,2M). |
| **KPI-05** | **Rendimiento por Vendedor** | $\text{Monto Vendido y N° de Ventas}$ | Evalúa el desempeño de los 6 vendedores frente a su sueldo base ($255.000 CLP mensual). |
| **KPI-06** | **Perfil de Clientes** | $\% \text{ de ventas por grupo}$ | Revela que el 89% de las ventas son a clientes casados, orientando la publicidad a familias. |



---

## Modelo dimensional

_(Desarrollado según la metodología de Ralph Kimball en 4 pasos)_

### Proceso de negocio

Proceso comercial de ventas de Mueblería Albarrán.

### Granularidad

Una fila por cada línea de detalle de producto vendido en cada transacción de venta individual.

### Dimensiones

- `Dim_Cliente`: Datos demográficos (`Cliente_SK`, `Cliente_BK`, `Nombre_Completo`, `Sexo`, `Fecha_Nacimiento`, `Estado_Civil`).
- `Dim_Empleado`: Colaboradores y rol (`Empleado_SK`, `Empleado_BK`, `Nombre_Completo`, `Nombre_Cargo`, `Sueldo_Base`, `Fecha_Contrato`).
- `Dim_Producto`: Catálogo de muebles (`Producto_SK`, `Producto_BK`, `Nombre_Producto`, `Nombre_Categoria`, `Precio_Catalogo`, `Descripcion`).
- `Dim_Sucursal`: Locales de venta (`Sucursal_SK`, `Sucursal_BK`, `Nombre_Sucursal`, `Nombre_Comuna`).
- `Dim_Tiempo`: Calendario analítico (`Fecha_SK` formato `YYYYMMDD`, `Fecha`, `Anio`, `Semestre`, `Trimestre`, `Mes`, `Dia`, `Es_Fin_De_Semana`).

### Tabla de hechos y medidas

- **Tabla de Hechos:** `Fact_Ventas`
- **Granularidad:** Una fila por cada producto vendido en cada transacción (`detalle_ventas`).
- **Dimensión Degenerada:** `Venta_ID` (número original del comprobante).
- **Métricas:** `Cantidad`, `Precio_Unitario`, `Monto_Bruto`, `Monto_Descuento`, `Monto_Neto`.


---

## Proceso ETL - Fase 1

- Herramienta: Visual Studio + SQL Server Integration Services (SSIS).
- Ubicación del proyecto: `etl/proyecto-ssis/`

### Calendario de Dim_Tiempo (issue #6)

El script `database/scripts/03_poblar_dim_tiempo.sql` genera el calendario de **3.652 fechas entre 2017 y 2026**, con año, semestre, trimestre, mes, día y marca de fin de semana. Conserva el miembro desconocido `-1` y permite ejecutar la carga sin duplicados. Documentación técnica: `docs/modelo-dimensional/dimension_tiempo.md`.

---

### Paquetes de dimensiones (issues #9–#12)

| Issue | Paquete | Filas reales verificadas | Guía |
|---|---|---:|---|
| #9 | Dim_Sucursal.dtsx | 3 | [Sucursal](etl/proyecto-ssis/Dim_Sucursal.md) |
| #10 | Dim_Cliente.dtsx | 20 | [Cliente](etl/proyecto-ssis/Dim_Cliente.md) |
| #11 | Dim_Empleado.dtsx | 15 | [Empleado](etl/proyecto-ssis/Dim_Empleado.md) |
| #12 | Dim_Producto.dtsx | 20 | [Producto](etl/proyecto-ssis/Dim_Producto.md) |

Todos conservan el miembro desconocido adicional -1 y extraen cero filas al repetir sobre la misma fuente. Clientes transforma nombres y sexo con textos Unicode y convierte al VARCHAR del DDL; empleados une cargos y normaliza nombres; productos sustituye las 20 descripciones nulas por Sin descripción. Las guías incluyen conexiones, consultas y evidencias SQL. La ejecución real en SSIS Windows sigue pendiente.

### Carga de Fact_Ventas e integración SSIS (issue #13)

[Fact_Ventas.dtsx](etl/proyecto-ssis/Fact_Ventas.dtsx) resuelve las cinco claves dimensionales con Lookup, asigna el miembro -1 cuando no encuentra coincidencias y calcula bruto, descuento y neto mediante Derived Column. [Configuración, dependencias y explicación](etl/proyecto-ssis/Fact_Ventas.md).

El proyecto SSIS registra los nombres reales de los cinco paquetes. Integrar primero los PR de #9–#12 y después #13. La copia conjunta de integración compila para SQL Server 2022; la carga SQL equivalente de ensayo produce 365 ventas, 724 unidades y 414.022.446 de bruto/neto, sin nuevas filas al repetir. Las nueve pruebas SQL del #14 pasan en ese ensayo. Evidencias en `docs/evidencias/validacion_ventas.json`, `compilacion_proyecto_ssis.json` y `cuadratura_sql_ensayo.json`.

**Pendiente:** ejecución real de los cinco paquetes en SSIS Windows, capturas de resultados y respaldo final del grupo. Las cargas SQL de ensayo y la compilación no sustituyen esa ejecución.

---

## Cubo OLAP - Fase 2

_(Corresponde a la Fase 2 del certamen)_

- Herramienta: SQL Server Analysis Services (SSAS).
- Ubicación: `olap/proyecto-ssas/`

---

## Dashboard Power BI - Fase 2

_(Corresponde a la Fase 2 del certamen)_

- Herramienta: Microsoft Power BI Desktop.
- Ubicación: `powerbi/dashboard.pbix`

---

## Tecnologías utilizadas (Versiones Específicas)

- **Motor de Base de Datos:** Microsoft SQL Server 2022 Developer Edition (RTM-CU27-GDR, v16.0.4305.5, x64).
- **Gestor de Base de Datos (Windows):** SQL Server Management Studio (SSMS) v19.3 o superior / v20.x.
- **Entorno de Virtualización (macOS ARM64 / Linux):** Docker Desktop v29.8.1 con emulación `linux/amd64` (Rosetta 2).
- **Entorno Analítico y Conectividad (Python):**
  - Python v3.14.8 (o compatible >=3.11).
  - Gestor de entornos y paquetes: `uv` v0.12.2.
  - Conector nativo SQL Server: `pymssql` v2.4.4.
  - ORM / Conexión SQL: `SQLAlchemy` v2.1.4.
  - Procesamiento de datos: `pandas` v3.0.6 y `numpy` v2.5.4.
  - Visualización: `matplotlib` v3.11.2 y `seaborn` v0.13.2.
  - Notebook interactivo: `jupyterlab` v4.6.4 / `notebook` v7.6.3 / `ipykernel` v7.4.0.
- **Herramienta ETL (Fase 1 - Windows 11):** Visual Studio 2022 (v17.x Community/Professional) + extensión _SQL Server Integration Services Projects_ (SSIS v16.x).
- **Herramienta OLAP (Fase 2 - Windows 11):** Visual Studio 2022 + extensión _Microsoft Analysis Services Projects_ (SSAS).
- **Dashboard y BI (Fase 2 - Windows 11):** Microsoft Power BI Desktop (Versión 2.128+ / 2026 x64).

---

## Estructura del repositorio

Siguiendo la estructura sugerida en la sección 6.1 de las bases del certamen:

```text
C2-Caso1-IN/
├── README.md                          # Documentación del proyecto (plantilla oficial 7.1)
├── .gitignore                         # Configurado para Python, SSIS, VS, macOS y Windows
├── .env.example                       # Variables de conexión a SQL Server
├── requirements.txt                   # Dependencias de Python gestionadas con uv
├── docs/                              # Documentos del certamen y especificaciones técnicas
│   ├── C2-Instrucciones.pdf           # Pauta de evaluación oficial
│   ├── Caso1.pdf                      # Enunciado del caso Mueblería Albarrán
│   ├── modelo-dimensional/            # Especificación técnica dimensional
│   │   ├── diagrama_modelo_dimensional.md # Diagrama estrella (Mermaid) y diccionario de datos
│   │   ├── matriz_mapeo_sttm.md       # Matriz Source-to-Target Mapping para SSIS
│   │   ├── dimension_tiempo.md        # Documentación de generación del calendario
│   │   └── validacion_cuadratura_dw.md # Protocolo de auditoría y respaldo Albarran_DW.bak
│   └── presentacion/                  # Diapositivas para la defensa de las fases
├── database/
│   ├── backup/
│   │   ├── Albarran.bak               # Base transaccional original (entregable)
│   │   └── Albarran_DW.bak            # Data Warehouse final post-ETL (entregable)
│   └── scripts/                       # Scripts SQL del Data Warehouse
│       ├── 02_crear_modelo_dimensional.sql # DDL físico, PKs, FKs, índices y miembros -1
│       ├── 03_poblar_dim_tiempo.sql   # Poblado de Dim_Tiempo (2017-2026)
│       └── 04_validacion_cuadratura_dw.sql # Auditoría cruzada contable y backup
├── docker/                            # Entorno SQL Server exclusivo para macOS (ARM64) / Linux
│   ├── docker-compose.yml             # Contenedor SQL Server 2022 con plataforma linux/amd64
│   └── restore.sh                     # Script para iniciar Docker y restaurar Albarran.bak en 1 clic
├── notebooks/
│   └── modelo_de_negocios.ipynb       # EDA, 6 KPIs formulados y simulación Kimball en Pandas
├── etl/
│   └── proyecto-ssis/                 # Solución oficial SSIS en Visual Studio 2022
│       ├── Albarran_ETL.sln           # Solución de Visual Studio 2022
│       ├── Albarran_ETL.dtproj        # Proyecto SSIS (SQLServer2022)
│       ├── Albarran_OLTP.conmgr       # Conexión OLE DB a Albarran (Origen)
│       ├── Albarran_DW.conmgr         # Conexión OLE DB a Albarran_DW (Destino)
│       ├── Project.params             # Parámetros del proyecto
│       └── README.md                  # Guía paso a paso para desarrollo en Windows
├── olap/
│   └── proyecto-ssas/                 # Proyecto SSAS de Visual Studio (Fase 2)
└── powerbi/
    └── dashboard.pbix                 # Dashboard final de Power BI (Fase 2)
```

---

## Instrucciones de ejecución / revisión

### Opción A: macOS Apple Silicon (ARM64) / Linux (con Docker)

El script `restore.sh` está diseñado exclusivamente para este entorno:

1. Asegurarse de tener Docker Desktop abierto.
2. Iniciar el contenedor y restaurar la base transaccional ejecutando:
   ```bash
   chmod +x docker/restore.sh
   ./docker/restore.sh
   ```
3. Iniciar el entorno Python y abrir el notebook de análisis:
   ```bash
   uv run jupyter lab notebooks/modelo_de_negocios.ipynb
   ```
4. Ejecutar el script DDL de creación de `Albarran_DW`:
   ```bash
   docker exec -i sqlserver_albarran /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'StrongPassword123!' -C < database/scripts/02_crear_modelo_dimensional.sql
   ```
5. Poblar el calendario en `Dim_Tiempo`:
   ```bash
   docker exec -i sqlserver_albarran /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'StrongPassword123!' -C < database/scripts/03_poblar_dim_tiempo.sql
   ```
6. Ejecutar la auditoría de cuadratura (validación pre-ETL):
   ```bash
   docker exec -i sqlserver_albarran /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'StrongPassword123!' -C < database/scripts/04_validacion_cuadratura_dw.sql
   ```

### Opción B: Windows 11 x64 (Entorno Nativo de Compañeros con Visual Studio)

1. Abrir **SQL Server Management Studio (SSMS)** y restaurar `database/backup/Albarran.bak`.
2. Ejecutar los scripts `02_crear_modelo_dimensional.sql` y `03_poblar_dim_tiempo.sql`.
3. Abrir la solución SSIS en Visual Studio 2022: `etl/proyecto-ssis/Albarran_ETL.sln`.
4. Verificar las conexiones OLE DB en `Albarran_OLTP.conmgr` y `Albarran_DW.conmgr`.
5. Ejecutar los paquetes SSIS de dimensiones y hechos según la secuencia documentada en `etl/proyecto-ssis/README.md`.
6. En SSMS, ejecutar `04_validacion_cuadratura_dw.sql` para comprobar que las 9 pruebas de cuadratura financiera y volumétrica resulten **`APROBADO [PASS]`**.
7. Generar el backup final `database/backup/Albarran_DW.bak` ejecutando el comando de backup documentado.
