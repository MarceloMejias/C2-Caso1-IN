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
├── docs/                              # Documentos del certamen y entregables
│   ├── C2-Instrucciones.pdf           # Pauta de evaluación oficial
│   ├── Caso1.pdf                      # Enunciado del caso Mueblería Albarrán
│   ├── modelo-dimensional/            # Diagramas y especificación dimensional
│   └── presentacion/                  # Diapositivas para la defensa de las fases
├── database/
│   ├── backup/
│   │   └── Albarran.bak               # Base de datos transaccional original
│   └── scripts/                       # Scripts DDL de creación del modelo dimensional
├── docker/                            # Entorno SQL Server exclusivo para macOS (ARM64) / Linux
│   ├── docker-compose.yml             # Contenedor SQL Server 2022 con plataforma linux/amd64
│   └── restore.sh                     # Script para iniciar Docker y restaurar Albarran.bak en 1 clic
├── notebooks/
│   └── modelo_de_negocios.ipynb       # Notebook de análisis con conexión directa integrada y reset Docker
├── etl/
│   └── proyecto-ssis/                 # Proyecto SSIS de Visual Studio (Fase 1)
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

### Opción B: Windows 11 x64 (Entorno Nativo de Compañeros)

En Windows 11 la restauración se realiza directamente sobre la instancia local de SQL Server:

1. Abrir **SQL Server Management Studio (SSMS)**.
2. En el explorador de objetos, clic derecho en **Databases** > **Restore Database...**
3. Seleccionar **Device** > buscar el archivo `database/backup/Albarran.bak` y hacer clic en **OK**.
4. La base de datos `Albarran` quedará disponible de inmediato para Visual Studio (SSIS) y consultas locales.

---

## Distribución de responsabilidades y aportes
