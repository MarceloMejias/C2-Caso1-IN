# Proyecto OLAP: Cubo Multidimensional Mueblería Albarrán
## Certamen 2 - Inteligencia de Negocios (Fase 2)

Este módulo contiene la solución analítica multidimensional implementada en **SQL Server Analysis Services (SSAS)** sobre el Data Warehouse `Albarran_DW`.

---

## 1. Arquitectura de la Solución OLAP

La solución `Albarran_OLAP` implementa un cubo analítico que expone las transacciones de ventas consolidadas durante la Fase 1, permitiendo consultas multidimensionales de alta velocidad (*slicing, dicing, roll-up y drill-down*) para responder a los requerimientos estratégicos del dueño de la empresa.

```
olap/proyecto-ssas/
├── Albarran_OLAP.sln           # Solución de Visual Studio 2022
├── Albarran_OLAP.dwproj        # Proyecto Analysis Services Multidimensional
├── Albarran_DW.ds              # Data Source con conexión OLE DB a Albarran_DW
├── Albarran_DW.dsv             # Data Source View (Vista del Esquema Estrella)
├── README.md                   # Especificación técnica, MDX y guía de despliegue
```

---

## 2. Definición de Dimensiones y Jerarquías Analíticas

Conforme a la rúbrica oficial de la Fase 2, se formalizan las siguientes **jerarquías multinivel** en cada dimensión para habilitar la navegación analítica:

### 2.1 Dim_Tiempo (`Dim_Tiempo.dim`)
* **Clave de dimensión:** `Fecha_SK` (Formato entero `YYYYMMDD`).
* **Jerarquía Calendario (Drill-down):**
  $$\text{Anio} \longrightarrow \text{Semestre} \longrightarrow \text{Trimestre} \longrightarrow \text{Nombre\_Mes} \longrightarrow \text{Fecha}$$
* **Atributos adicionales:** `Dia_Semana`, `Nombre_Dia_Semana`, `Es_Fin_De_Semana`.

### 2.2 Dim_Sucursal (`Dim_Sucursal.dim`)
* **Clave de dimensión:** `Sucursal_SK`.
* **Jerarquía Geográfica:**
  $$\text{Nombre\_Comuna} \longrightarrow \text{Nombre\_Sucursal}$$
* **Cobertura:** Las Condes (Manquehue), Santiago (Franklin) y Viña del Mar (Viña del Mar).

### 2.3 Dim_Producto (`Dim_Producto.dim`)
* **Clave de dimensión:** `Producto_SK`.
* **Jerarquía de Catálogo:**
  $$\text{Nombre\_Categoria} \longrightarrow \text{Nombre\_Producto}$$
* **Atributos adicionales:** `Precio_Catalogo`, `Descripcion` (Tratamiento de nulos resuelto en Fase 1).

### 2.4 Dim_Empleado (`Dim_Empleado.dim`)
* **Clave de dimensión:** `Empleado_SK`.
* **Jerarquía Organizacional:**
  $$\text{Nombre\_Cargo} \longrightarrow \text{Nombre\_Completo}$$
* **Atributos de análisis:** `Sueldo_Base` ($255.000 CLP), `Fecha_Contrato`.

### 2.5 Dim_Cliente (`Dim_Cliente.dim`)
* **Clave de dimensión:** `Cliente_SK`.
* **Jerarquía Demográfica:**
  $$\text{Sexo} \longrightarrow \text{Estado\_Civil} \longrightarrow \text{Nombre\_Completo}$$
* **Atributos de análisis:** `Fecha_Nacimiento`.

---

## 3. Grupo de Medidas y Métricas del Negocio

El cubo se estructura sobre el grupo de medidas `Fact_Ventas` a nivel de línea atómica:

### 3.1 Medidas Base (Aditivas)
* **Cantidad Vendida:** $\sum \text{Cantidad}$ (Tipo: Suma, Integer).
* **Monto Bruto:** $\sum \text{Monto\_Bruto}$ (Tipo: Suma, Currency).
* **Monto Descuento:** $\sum \text{Monto\_Descuento}$ (Tipo: Suma, Currency).
* **Monto Neto (Facturación):** $\sum \text{Monto\_Neto}$ (Tipo: Suma, Currency).
* **Recuento de Líneas:** Conteo de filas de `Fact_Ventas`.
* **Total de Transacciones (Tickets):** `DistinctCount(Venta_ID)`.

---

## 4. Medidas Calculadas y Mapeo Formal de KPIs (MDX)

En la sección de cálculos del cubo (`Cube.Calculations`), se implementan formalmente las expresiones MDX que responden a los **6 KPIs del negocio**:

```mdx
/* ==============================================================================
   CÁLCULOS MDX PARA KPIs DE MUEBLERÍA ALBARRÁN
   ============================================================================== */

-- KPI-01: Ingreso Total Neto por Ventas
CREATE MEMBER CURRENTCUBE.[Measures].[KPI 01 - Ingreso Total Neto]
AS [Measures].[Monto Neto],
FORMAT_STRING = "$#,##0",
VISIBLE = 1,
ASSOCIATED_MEASURE_GROUP = 'Fact Ventas';

-- KPI-02: Ticket Promedio por Compra
CREATE MEMBER CURRENTCUBE.[Measures].[KPI 02 - Ticket Promedio]
AS IIF([Measures].[Total Transacciones] = 0, NULL,
       [Measures].[Monto Neto] / [Measures].[Total Transacciones]),
FORMAT_STRING = "$#,##0",
VISIBLE = 1,
ASSOCIATED_MEASURE_GROUP = 'Fact Ventas';

-- KPI-03: Unidades Vendidas por Categoría (Suma agregada sobre jerarquía)
CREATE MEMBER CURRENTCUBE.[Measures].[KPI 03 - Unidades Vendidas]
AS [Measures].[Cantidad],
FORMAT_STRING = "#,##0",
VISIBLE = 1,
ASSOCIATED_MEASURE_GROUP = 'Fact Ventas';

-- KPI-04: Facturación por Tienda / Comuna
CREATE MEMBER CURRENTCUBE.[Measures].[KPI 04 - Facturación Sucursal]
AS [Measures].[Monto Neto],
FORMAT_STRING = "$#,##0",
VISIBLE = 1,
ASSOCIATED_MEASURE_GROUP = 'Fact Ventas';

-- KPI-05: Productividad de la Fuerza de Ventas (Ratio Ventas / Sueldo Base)
CREATE MEMBER CURRENTCUBE.[Measures].[KPI 05 - Ratio Retorno Sobre Sueldo]
AS IIF(ISEMPTY([Dim Empleado].[Sueldo Base].CurrentMember) OR [Dim Empleado].[Sueldo Base].CurrentMember.Value = 0,
       NULL,
       [Measures].[Monto Neto] / ([Dim Empleado].[Sueldo Base].CurrentMember.Value * 12)),
FORMAT_STRING = "0.00x",
VISIBLE = 1,
ASSOCIATED_MEASURE_GROUP = 'Fact Ventas';

-- KPI-06: % Participación de Clientes Casados
CREATE MEMBER CURRENTCUBE.[Measures].[KPI 06 - % Ventas Clientes Casados]
AS ( [Measures].[Monto Neto], [Dim Cliente].[Estado Civil].[Estado Civil].[Casado] )
   / ( [Measures].[Monto Neto], [Dim Cliente].[Estado Civil].[All] ),
FORMAT_STRING = "0.00%",
VISIBLE = 1,
ASSOCIATED_MEASURE_GROUP = 'Fact Ventas';
```

---

## 5. Instrucciones de Despliegue y Procesamiento en Windows

Para desplegar y procesar el cubo en un entorno Windows 11 con SQL Server 2022 y Visual Studio 2022:

1. **Requisitos:**
   * SQL Server Analysis Services (Instancia Multidimensional activada, por defecto `localhost`).
   * Base de datos `Albarran_DW` creada y cargada (mediante script 02, 03 y SSIS / Script 05).
   * Extensión *Microsoft Analysis Services Projects* en Visual Studio 2022.

2. **Apertura de la solución:**
   * Abrir `olap/proyecto-ssas/Albarran_OLAP.sln` en Visual Studio 2022.

3. **Verificación de Conexión:**
   * Doble clic en `Albarran_DW.ds`.
   * Verificar la cadena de conexión hacia el servidor local (`Data Source=localhost;Initial Catalog=Albarran_DW`).
   * Probar conexión con el botón *Test Connection*.

4. **Despliegue (*Deploy*):**
   * En el Explorador de Soluciones, hacer clic derecho sobre el proyecto `Albarran_OLAP` $\rightarrow$ **Deploy** (o `Build` $\rightarrow$ `Deploy Albarran_OLAP`).
   * La ventana de salida confirmará: `Deploy: 1 succeeded, 0 failed`.

5. **Procesamiento del Cubo (*Process Full*):**
   * En Visual Studio o en SQL Server Management Studio (conectado a Analysis Services):
   * Clic derecho sobre el Cubo `Albarran_OLAP` $\rightarrow$ **Process**.
   * Modo de procesamiento: `Process Full`.
   * Clic en **Run**. El estado final debe indicar **Process succeeded**.

---

## 6. Consultas MDX de Validación para la Interrogación Individual

En SQL Server Management Studio (SSMS), conectándose al motor de *Analysis Services*, se pueden ejecutar estas consultas MDX para demostrar el correcto funcionamiento del cubo ante el profesor:

### Consulta A: Validación de Ventas Totales y Ticket Promedio (KPI-01 y KPI-02)
```mdx
SELECT 
    { [Measures].[KPI 01 - Ingreso Total Neto], 
      [Measures].[Total Transacciones], 
      [Measures].[KPI 02 - Ticket Promedio] } ON COLUMNS,
    [Dim Tiempo].[Jerarquia Calendario].[Nombre Mes].Members ON ROWS
FROM [Albarran_OLAP];
```
*Resultado esperado:* Total anual exacto de **$414.022.446 CLP** distribuido en los 12 meses de 2017.

### Consulta B: Desempeño por Sucursal y Comuna (KPI-04)
```mdx
SELECT 
    { [Measures].[Cantidad Vendida], [Measures].[Monto Neto] } ON COLUMNS,
    [Dim Sucursal].[Jerarquia Geografia].[Nombre Sucursal].Members ON ROWS
FROM [Albarran_OLAP];
```
*Resultado esperado:* Manquehue ($149.349.522 CLP), Viña del Mar ($134.453.794 CLP), Franklin ($130.219.130 CLP).

### Consulta C: Rendimiento de la Fuerza de Ventas (KPI-05)
```mdx
SELECT 
    { [Measures].[Total Transacciones], 
      [Measures].[Monto Neto],
      [Measures].[KPI 05 - Ratio Retorno Sobre Sueldo] } ON COLUMNS,
    NON EMPTY [Dim Empleado].[Jerarquia Organizacion].[Nombre Completo].Members ON ROWS
FROM [Albarran_OLAP];
```
*Resultado esperado:* 6 vendedores activos con ventas entre $59M y $82M cada uno, evidenciando un retorno superior a 19x sobre su costo de nómina anual ($3.060.000 CLP).

