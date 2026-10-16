# Carga de Dim_Sucursal

Paquete del issue #9: `Dim_Sucursal.dtsx`. Usa las columnas y tipos del DDL del issue #4 y se incorpora al proyecto compartido del issue #8 mediante **SSIS Packages > Add Existing Package > File System**.

## Requisitos

- SQL Server con las bases `Albarran` y `Albarran_DW` en la misma instancia.
- DDL del issue #4 ejecutado y miembro desconocido `Sucursal_SK = -1` presente.
- Visual Studio 2022 con la extensión SSIS y proveedor Microsoft OLE DB x64 instalado.
- Permisos de lectura en la fuente y lectura/escritura en el destino.

## Conexiones

El paquete contiene dos administradores locales, sin contraseñas guardadas:

| Administrador | Base |
|---|---|
| `Origen_Albarran` | `Albarran` |
| `Destino_Albarran_DW` | `Albarran_DW` |

Ambos usan `Data Source=.` como ejemplo. Cambiar el servidor y probar ambas conexiones antes de ejecutar. Para el contenedor de Marcelo, usar su host y puerto reales, autenticación SQL y la contraseña del entorno local. No guardar credenciales en Git. Si está instalado OLE DB Driver 19, seleccionar `MSOLEDBSQL19` desde el editor de conexiones en lugar de `MSOLEDBSQL`.

## Flujo de control y datos

1. **Validar origen:** detecta claves repetidas, comunas inexistentes, nombres vacíos y textos que excedan el ancho del destino.
2. **Cargar sucursales:** Data Flow con OLE DB Source y OLE DB Destination. La consulta une `sucursales` y `comunas`, aplica `LTRIM/RTRIM` y devuelve `Sucursal_BK INT`, `Nombre_Sucursal VARCHAR(100)` y `Nombre_Comuna VARCHAR(100)`.
3. **Validar dimensión:** compara claves y nombres con el origen, detecta duplicados y verifica la conservación del miembro desconocido.

`Sucursal_SK` no se mapea: SQL Server la genera con IDENTITY. Los errores de conversión, truncamiento o inserción hacen fallar el componente. La validación usa la intercalación del destino para evitar el conflicto entre `Modern_Spanish_CI_AS` del respaldo y la intercalación predeterminada de otra instancia.

La extracción omite las claves de negocio ya cargadas. Al repetirla con la misma fuente no inserta duplicados y conserva las claves usadas por la tabla de hechos. No trunca la dimensión ni elimina el registro `-1`. Si cambia el nombre de una sucursal existente, la validación lo detecta y hay que acordar su actualización; este paquete no implementa cambios históricos de atributos. Ejecutar una carga a la vez.

Las consultas están también en `consultas/` para revisarlas en SSMS. El paquete las lleva incorporadas y no depende de una ruta local a esos archivos.

## Comprobaciones realizadas

- Compilación con la herramienta oficial SSISBuild: correcta.
- Consultas y metadatos ejecutados contra el respaldo y el DDL real: correctos.
- Resultado SQL contrastado: tres sucursales reales más el miembro desconocido.
- Segunda extracción con la misma fuente: cero filas nuevas.
- Mapeo de las tres columnas del flujo revisado contra los tipos reales.

**Pendiente para cerrar #9:** ejecutar `Dim_Sucursal.dtsx` en SSIS Windows, guardar captura de las tres tareas correctas y mostrar el resultado de `consultas/validar_dim_sucursal.sql`. La compilación y la prueba SQL no sustituyen esa ejecución. La evidencia de pruebas disponible está en `docs/evidencias/validacion_sucursales.json`.

## Explicación para la defensa

La fuente guarda por separado las sucursales y las comunas. Las unimos para que cada fila de la dimensión tenga el nombre de la tienda y su comuna. Limpiamos espacios y ajustamos los textos al tamaño del destino. Conservamos el ID original como clave de negocio y dejamos que SQL Server genere la clave sustituta. Las ventas usarán esa clave sustituta para analizar resultados por sucursal.
