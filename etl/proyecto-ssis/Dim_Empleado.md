# Carga de Dim_Empleado (issue #11)

## Flujo implementado

La fuente une `empleados` y `cargos`. Derived Column forma `Nombre_Completo` con nombre y apellidos, omite el apellido materno nulo o vacío, limpia espacios exteriores y convierte `Nombre_Cargo` a mayúsculas. Conserva `Sueldo_Base` como NUMERIC(12,2) y `Fecha_Contrato` como DATE. Carga los 15 empleados, no solamente los vendedores con ventas.

Los campos textuales del destino son VARCHAR(150) y VARCHAR(100); el flujo usa DT_STR con página de códigos 1252 para corresponder al DDL. La validación contrasta todos los nombres y atributos de la copia real, incluidas las tildes.

El flujo de control valida el origen, ejecuta el Data Flow y valida el destino. Las tareas siguen ese orden y cualquier error detiene el paquete. La clave sustituta IDENTITY no se mapea: la genera SQL Server. Se carga la clave de negocio y se conserva el miembro desconocido -1.

La extracción inserta únicamente claves de negocio ausentes. Repetirla con la misma fuente devuelve cero filas y conserva las claves sustitutas existentes. No trunca tablas ni actualiza atributos; un cambio en los atributos ya cargados se detecta como discrepancia. No implementa historia SCD. Ejecutar una carga a la vez.

## Incorporación a la solución del #8

1. Abrir `Albarran_ETL.sln` en Visual Studio con la extensión SSIS y OLE DB Driver instalado.
2. Si el proyecto muestra la referencia prevista `03_Carga_Dim_Empleado.dtsx` y no existe ese archivo, quitar solo esa referencia. Agregar `Dim_Empleado.dtsx` mediante **SSIS Packages > Add Existing Package > File System** y guardar el proyecto.
3. Configurar y probar las conexiones locales `Origen_Albarran` y `Destino_Albarran_DW`. El ejemplo usa servidor `.` y autenticación integrada. Ambas bases deben estar en la misma instancia porque las consultas de control acceden a origen y destino.
4. Adaptar el proveedor al instalado: MSOLEDBSQL en el ejemplo o MSOLEDBSQL19 para Driver 19. No guardar contraseñas en Git. Las conexiones compartidas del #8 no sustituyen automáticamente las conexiones locales; para usarlas, actualizar las referencias de las tareas y componentes.
5. Con `Albarran` restaurada y el DDL #4 ejecutado, iniciar el paquete. No volver a ejecutar el DDL si se quieren conservar cargas anteriores: el DDL elimina las tablas.
6. Ejecutar de nuevo: deben conservarse 15 filas reales más el miembro desconocido.

## Consultas y verificación

En `consultas/` se incluyen `empleados_origen.sql`, `validar_origen_empleados.sql` y `validar_empleados.sql`. El paquete lleva las consultas incorporadas. `empleados_transformados_control.sql` es una consulta SQL equivalente para contrastar los resultados de las expresiones; no reemplaza el Data Flow SSIS.

Pruebas realizadas con el respaldo y el DDL real en una instancia de ensayo:

- Compilación SSISBuild para SQL Server 2022 correcta.
- Metadatos de origen y componentes nativos comprobados.
- Transformaciones contrastadas en Python y SQL para las 15 filas.
- Carga SQL de 15 filas más el miembro desconocido; segunda extracción vacía y claves conservadas.
- Discrepancia artificial detectada por la validación y cambio de prueba revertido.

Evidencia: `docs/evidencias/validacion_empleados.json`. **Estas cargas se ejecutaron mediante SQL; no se ejecutó el DTSX en un runtime SSIS.**

**Pendiente antes de cerrar #11:** incorporar el paquete al proyecto compartido, probar las conexiones y ejecutarlo en SSIS Windows. Guardar capturas de las tareas correctas y de la consulta de destino:

```sql
USE Albarran_DW;
SELECT * FROM dbo.Dim_Empleado ORDER BY Empleado_SK;
```

## Explicación para la defensa

Unimos cada empleado con su cargo para disponer de sus atributos en una sola dimensión. Formamos el nombre completo, normalizamos el cargo y conservamos sueldo y fecha de contrato. El ID original es la clave de negocio; SQL Server genera la clave sustituta que luego usarán las ventas.
