# Certamen 2 - Inteligencia de Negocios

## Caso seleccionado

**Caso 1: Mueblería Albarrán**

## Integrantes y sección

- **Integrantes:**
  - Marcelo Mejías Caviedes — paralelo 301


**Profesor:** Hernán Saavedra

---

## Descripción del problema

La Mueblería Albarrán es una empresa innovadora en el rubro de la mueblería que ha experimentado un crecimiento acelerado en los últimos años. Con sucursales comerciales y una diversidad de líneas de productos (arrimos, banquetas, comedores, bares, entre otros), su propietario requiere incorporar Inteligencia de Negocios para analizar la información operativa, evaluar el desempeño de ventas y apoyar la toma de decisiones estratégicas.

---

## Objetivo del proyecto

Diseñar e implementar una solución integral de Inteligencia de Negocios basada en la metodología de Ralph Kimball, que permita extraer, transformar y cargar los datos desde la base transaccional (`Albarran`) hacia un Data Warehouse dimensional en SQL Server, facilitando el análisis multidimensional y la visualización de indicadores de gestión clave (KPIs).

---

## KPI definidos

A partir de la exploración de datos en [notebooks/modelo_de_negocios.ipynb](notebooks/modelo_de_negocios.ipynb), se definieron 6 KPIs clave para el seguimiento del negocio:

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

- **Herramienta:** Visual Studio Community 2026 + SQL Server Integration Services Projects 2022+.
- **Ubicación del proyecto:** `etl/Albarran/` ([Albarran.slnx](etl/Albarran/Albarran.slnx)).
- **Conexiones compartidas:** `Albarran_OLTP.conmgr` (origen `Albarran`) y `Albarran_DW.conmgr` (destino `Albarran_DW`).

### Calendario de `Dim_Tiempo`

El script [03_poblar_dim_tiempo.sql](database/scripts/03_poblar_dim_tiempo.sql) genera el calendario de **3.652 fechas entre 2017 y 2026**, con año, semestre, trimestre, mes, día y marca de fin de semana. Conserva el miembro desconocido `-1` y permite ejecutar la carga sin duplicados. Documentación técnica: [dimension_tiempo.md](docs/modelo-dimensional/dimension_tiempo.md).

### Paquetes SSIS implementados y validados

| Orden | Paquete | Filas cargadas | Descripción |
| :---: | :--- | ---: | :--- |
| 1 | `Dim_Sucursal.dtsx` | 3 (+ `-1`) | Une `sucursales` y `comunas`, aplica `LTRIM/RTRIM` y valida origen/destino. |
| 2 | `Dim_Producto.dtsx` | 20 (+ `-1`) | Une `productos` y `categorias`, reemplaza descripciones `NULL` por `Sin descripción`. |
| 3 | `Dim_Empleado.dtsx` | 15 (+ `-1`) | Une `empleados` y `cargos`, normaliza `Nombre_Completo` y `Nombre_Cargo`. |
| 4 | `Dim_Cliente.dtsx` | 20 (+ `-1`) | Normaliza `Nombre_Completo`, `Sexo` (`Masculino`/`Femenino`) y `Estado_Civil`. |
| 5 | `Fact_Ventas.dtsx` | 365 | Resuelve las 5 claves sustitutas (`SK`, usando `-1` si falta) y calcula `Monto_Bruto`, `Monto_Descuento` y `Monto_Neto`. |

Todos los paquetes incluyen tareas **Execute SQL Task** de validación previa en origen y validación posterior en destino, y evitan duplicados al re-ejecutarse.

### Validación de cuadratura

Tras ejecutar los 5 paquetes SSIS en Visual Studio 2026, el script [04_validacion_cuadratura_dw.sql](database/scripts/04_validacion_cuadratura_dw.sql) aprobó las **9 pruebas de cuadratura (`APROBADO [PASS]`)**:
- **Volumetría:** 365 transacciones y 724 unidades vendidas.
- **Financiero:** `$414.022.446` CLP de facturación bruta y neta (`$0` de descuento).
- **Integridad y calidad:** 0 claves huérfanas (`SK = -1`), 0 nulos en `Dim_Producto.Descripcion`, miembros `-1` presentes en las 5 dimensiones y 3.652 días en `Dim_Tiempo`.

---

## Cubo OLAP - Fase 2

_(Corresponde a la Fase 2 del certamen)_

- Herramienta: SQL Server Analysis Services (SSAS).
- Ubicación: `olap/Albarran_OLAP (SSAS)/`

---

## Dashboard Power BI - Fase 2

_(Corresponde a la Fase 2 del certamen)_

- Herramienta: Microsoft Power BI Desktop.
- Ubicación: `powerbi/dashboard.pbix`

---

## Tecnologías utilizadas (Versiones Específicas)

- **Motor de Base de Datos:** Microsoft SQL Server 2022 Developer Edition / LocalDB.
- **Gestor de Base de Datos (Windows):** SQL Server Management Studio (SSMS) v22.
- **Entorno de Virtualización (macOS ARM64 / Linux):** Docker Desktop con emulación `linux/amd64` (Rosetta 2).
- **Entorno Analítico y Conectividad (Python):**
  - Python v3.13 (compatible `>=3.11`).
  - Gestor de entornos y paquetes: `uv`.
  - Conector nativo SQL Server: `pymssql`.
  - ORM / Conexión SQL: `SQLAlchemy`.
  - Procesamiento de datos: `pandas` y `numpy`.
  - Visualización: `matplotlib` y `seaborn`.
  - Notebook interactivo: `jupyterlab` / `notebook` / `ipykernel`.
- **Herramienta ETL (Fase 1 - Windows 11):** Visual Studio Community 2026 + extensión _SQL Server Integration Services Projects 2022+_.
- **Herramienta OLAP (Fase 2 - Windows 11):** Visual Studio + extensión _Microsoft Analysis Services Projects_.
- **Dashboard y BI (Fase 2 - Windows 11):** Microsoft Power BI Desktop.

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
│   └── Albarran/                      # Solución oficial SSIS en Visual Studio 2026
│       ├── Albarran.slnx              # Solución de Visual Studio 2026
│       ├── Albarran.dtproj            # Proyecto SSIS (SQLServer2022)
│       ├── Albarran_OLTP.conmgr       # Conexión OLE DB compartida a Albarran (Origen)
│       ├── Albarran_DW.conmgr         # Conexión OLE DB compartida a Albarran_DW (Destino)
│       ├── Dim_Sucursal.dtsx          # Carga de Dim_Sucursal
│       ├── Dim_Producto.dtsx          # Carga de Dim_Producto
│       ├── Dim_Empleado.dtsx          # Carga de Dim_Empleado
│       ├── Dim_Cliente.dtsx           # Carga de Dim_Cliente
│       ├── Fact_Ventas.dtsx           # Carga de Fact_Ventas
│       └── Project.params             # Parámetros del proyecto
├── olap/
│   └── Albarran_OLAP (SSAS)/          # Proyecto SSAS de Visual Studio (Fase 2)
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

### Opción B: Windows 11 x64 (Entorno Nativo con Visual Studio 2026)

1. Abrir **SQL Server Management Studio (SSMS 22)** y restaurar `database/backup/Albarran.bak`.
2. Ejecutar los scripts `02_crear_modelo_dimensional.sql` y `03_poblar_dim_tiempo.sql`.
3. Abrir la solución SSIS en Visual Studio 2026: `etl/Albarran/Albarran.slnx`.
4. Verificar las conexiones OLE DB compartidas en `Albarran_OLTP.conmgr` y `Albarran_DW.conmgr`.
5. Ejecutar los 4 paquetes de dimensiones (`Dim_Sucursal.dtsx`, `Dim_Producto.dtsx`, `Dim_Empleado.dtsx`, `Dim_Cliente.dtsx`) y luego `Fact_Ventas.dtsx`.
6. En SSMS, ejecutar `04_validacion_cuadratura_dw.sql` para comprobar que las 9 pruebas de cuadratura financiera y volumétrica resulten **`APROBADO [PASS]`**.
7. Generar el backup final `database/backup/Albarran_DW.bak`.
