# Certamen 2 - Inteligencia de Negocios

## Caso seleccionado

**Caso 1: Mueblería Albarrán**

## Integrantes y sección

- **Integrantes:**
  - Marcelo Mejías Caviedes — paralelo 301
  - Mishas Silva — paralelo 300
  - Natalia Cárdenas — paralelo 301

**Profesor:** Hernán Saavedra.

---

## Descripción del problema

La Mueblería Albarrán es una empresa innovadora en el rubro de la mueblería que ha experimentado un crecimiento acelerado en los últimos años. Con sucursales comerciales y una diversidad de líneas de productos (arrimos, banquetas, comedores, bares, entre otros), su propietario requiere incorporar Inteligencia de Negocios para analizar la información operativa, evaluar el desempeño de ventas y apoyar la toma de decisiones estratégicas.

---

## Objetivo del proyecto

Diseñar e implementar una solución integral de Inteligencia de Negocios basada en la metodología de Ralph Kimball, que permita extraer, transformar y cargar los datos desde la base transaccional (`Albarran`) hacia un Data Warehouse dimensional en SQL Server, facilitando el análisis multidimensional y la visualización de indicadores de gestión clave (KPIs).

---

## KPI definidos

La sección 5 de `notebooks/modelo_de_negocios.ipynb` documenta fórmulas, utilidad, periodicidad, desagregación y cálculos sobre el respaldo real (issue #2).

| KPI | Definición | Decisión que apoya |
|---|---|---|
| 01. Ingreso bruto | Suma de cantidad × precio del detalle | Comparación temporal de ventas |
| 02. Ticket bruto promedio | Ingreso bruto / ventas distintas | Tamaño promedio de las compras |
| 03. Unidades por producto/categoría | Suma de cantidades | Demanda del mix comercial |
| 04. Ventas por sucursal/comuna | Ingreso bruto agrupado territorialmente | Desempeño de puntos de venta |
| 05. Rendimiento del vendedor | Ventas mensuales y sueldo base mostrado como referencia separada | Comparación comercial entre vendedores |
| 06. Ventas por segmento de clientes | Ingreso y participación por sexo, edad al vender y estado civil | Descripción de quienes compran |

Controles del respaldo: **365 ventas, 724 unidades, 414.022.446 de ingreso bruto y ticket global de 1.134.308,0712**. Los descuentos observados son cero. CLP es una convención del proyecto; la fuente no incluye un campo de moneda. No se calcula ventas/sueldo hasta confirmar periodicidad y vigencia del sueldo, ni se afirma rentabilidad sin costos. Las agrupaciones se validan para conservar el total.

---

## Modelo dimensional

_(Desarrollado según la metodología de Ralph Kimball en 4 pasos)_

### Proceso de negocio

Proceso comercial de ventas de Mueblería Albarrán.

### Granularidad

Una fila por cada línea de detalle de producto vendido en cada transacción de venta individual.

### Dimensiones

- `Dim_Cliente`: Datos demográficos del cliente.
- `Dim_Empleado`: Datos del colaborador y cargo.
- `Dim_Producto`: Información del producto y su categoría.
- `Dim_Sucursal`: Ubicación de la tienda y su comuna.
- `Dim_Tiempo`: Calendario multidimensional (año, semestre, trimestre, mes, día).

### Tabla de hechos y medidas

- **Tabla de Hechos:** `Fact_Ventas`
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
