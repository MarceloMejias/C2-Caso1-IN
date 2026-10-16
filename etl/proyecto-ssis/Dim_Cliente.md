# Carga de Dim_Cliente (issue #10)

## Flujo implementado

OLE DB Source extrae los clientes con sus textos Unicode. Derived Column forma `Nombre_Completo`, omite el apellido materno nulo o vacío y convierte M/F en Masculino/Femenino. Un código distinto o nulo queda como No Informado. Estado civil nulo o vacío queda como No Informado.

La transformación conserva los textos como DT_WSTR (Unicode). Data Conversion los convierte a DT_STR con página de códigos 1252 y longitudes 150/20/50 para coincidir con el DDL del proyecto, que usa VARCHAR, aunque el issue menciona NVARCHAR. No se cambió el esquema de Marcelo. Los errores y truncamientos detienen el flujo. Si el destino cambia a NVARCHAR, deben revisarse los metadatos y retirarse esa conversión final. Las tildes de los 20 registros reales se contrastaron con la fuente.

El flujo de control valida el origen, ejecuta el Data Flow y valida el destino. Las tareas siguen ese orden y cualquier error detiene el paquete. La clave sustituta IDENTITY no se mapea: la genera SQL Server. Se carga la clave de negocio y se conserva el miembro desconocido -1.

La extracción inserta únicamente claves de negocio ausentes. Repetirla con la misma fuente devuelve cero filas y conserva las claves sustitutas existentes. No trunca tablas ni actualiza atributos; un cambio en los atributos ya cargados se detecta como discrepancia. No implementa historia SCD. Ejecutar una carga a la vez.

## Incorporación a la solución del #8

1. Abrir `Albarran_ETL.sln` en Visual Studio con la extensión SSIS y OLE DB Driver instalado.
2. Si el proyecto muestra la referencia prevista `02_Carga_Dim_Cliente.dtsx` y no existe ese archivo, quitar solo esa referencia. Agregar `Dim_Cliente.dtsx` mediante **SSIS Packages > Add Existing Package > File System** y guardar el proyecto.
3. Configurar y probar las conexiones locales `Origen_Albarran` y `Destino_Albarran_DW`. El ejemplo usa servidor `.` y autenticación integrada. Ambas bases deben estar en la misma instancia porque las consultas de control acceden a origen y destino.
4. Adaptar el proveedor al instalado: MSOLEDBSQL en el ejemplo o MSOLEDBSQL19 para Driver 19. No guardar contraseñas en Git. Las conexiones compartidas del #8 no sustituyen automáticamente las conexiones locales; para usarlas, actualizar las referencias de las tareas y componentes.
5. Con `Albarran` restaurada y el DDL #4 ejecutado, iniciar el paquete. No volver a ejecutar el DDL si se quieren conservar cargas anteriores: el DDL elimina las tablas.
6. Ejecutar de nuevo: deben conservarse 20 filas reales más el miembro desconocido.

## Consultas y verificación

En `consultas/` se incluyen `clientes_origen.sql`, `validar_origen_clientes.sql` y `validar_clientes.sql`. El paquete lleva las consultas incorporadas. `clientes_transformados_control.sql` es una consulta SQL equivalente para contrastar los resultados de las expresiones; no reemplaza el Data Flow SSIS.

Pruebas realizadas con el respaldo y el DDL real en una instancia de ensayo:

- Compilación SSISBuild para SQL Server 2022 correcta.
- Metadatos de origen y componentes nativos comprobados.
- Transformaciones contrastadas en Python y SQL para las 20 filas.
- Carga SQL de 20 filas más el miembro desconocido; segunda extracción vacía y claves conservadas.
- Discrepancia artificial detectada por la validación y cambio de prueba revertido.

Evidencia: `docs/evidencias/validacion_clientes.json`. **Estas cargas se ejecutaron mediante SQL; no se ejecutó el DTSX en un runtime SSIS.**

**Pendiente antes de cerrar #10:** incorporar el paquete al proyecto compartido, probar las conexiones y ejecutarlo en SSIS Windows. Guardar capturas de las tareas correctas y de la consulta de destino:

```sql
USE Albarran_DW;
SELECT * FROM dbo.Dim_Cliente ORDER BY Cliente_SK;
```

## Explicación para la defensa

Limpiamos los nombres y reunimos los apellidos en un nombre completo. Convertimos M y F en etiquetas claras y tratamos los datos faltantes. Conservamos el ID del cliente como clave de negocio y dejamos que SQL Server genere la clave sustituta para relacionarlo con las ventas.
