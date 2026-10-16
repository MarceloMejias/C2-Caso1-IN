# Carga de Dim_Producto (issue #12)

El paquete `Dim_Producto.dtsx` carga productos y categorías en el modelo del issue #4. Incluye una transformación **Derived Column** para reemplazar exclusivamente las descripciones nulas por `Sin descripción`. Una descripción existente se conserva, incluso si es una cadena vacía.

## Incorporación al proyecto compartido

1. Abrir la solución del issue #8 en Visual Studio con la extensión SSIS.
2. En **SSIS Packages > Add Existing Package > File System**, agregar `Dim_Producto.dtsx`. Si aparece la referencia prevista `04_Carga_Dim_Producto.dtsx`, quitar solo esa referencia al archivo ausente antes de agregar el paquete real. Guardar el proyecto para que registre el paquete.
3. Configurar y probar los administradores locales del paquete: `Origen_Albarran` y `Destino_Albarran_DW`. Ambos usan `Data Source=.` y autenticación integrada como ejemplo; cambiar servidor, puerto y autenticación según el entorno del grupo. No guardar contraseñas en Git.
4. Si se usa OLE DB Driver 19, seleccionar `MSOLEDBSQL19` en el editor de conexión. El ejemplo usa `MSOLEDBSQL`.
5. Ejecutar el paquete con las bases `Albarran` y `Albarran_DW` en la misma instancia y el DDL del issue #4 ya aplicado. El usuario de conexión requiere leer ambas bases e insertar en el destino.

El paquete mantiene conexiones locales para poder revisarse y compilarse por separado. El responsable del #8 puede sustituirlas por las conexiones compartidas, actualizando también las referencias de las dos tareas Execute SQL y del flujo de datos. No basta con cambiar el nombre del administrador.

## Pasos del paquete

1. **Validar origen:** detecta productos duplicados, categorías faltantes, nombres vacíos o demasiado largos y precios nulos o negativos. Si hay errores, detiene la carga.
2. **Cargar productos:**
   - OLE DB Source une `productos` con `categorias`, limpia espacios de nombres y ajusta los tipos al DDL.
   - Derived Column reemplaza `Descripcion` con `(DT_STR,255,1252)(ISNULL(Descripcion) ? "Sin descripción" : Descripcion)`.
   - OLE DB Destination inserta `Producto_BK`, `Nombre_Producto`, `Nombre_Categoria`, `Precio_Catalogo` y `Descripcion`. SQL Server genera `Producto_SK` con IDENTITY.
3. **Validar dimensión:** compara todas las columnas con la fuente, detecta claves de negocio repetidas y comprueba el miembro desconocido `-1`.

El destino actual usa `VARCHAR(100)`, `NUMERIC(12,2)` y `VARCHAR(255)`. Los textos del flujo usan página de códigos 1252 para corresponder al DDL. La comparación SQL aplica `COLLATE DATABASE_DEFAULT` porque el respaldo y el destino pueden tener intercalaciones distintas. Si se cambia el destino a Unicode, hay que actualizar los metadatos y la expresión del paquete.

La extracción omite las claves de negocio presentes. Repetirla con la misma fuente no agrega filas ni cambia claves sustitutas. No borra datos ni trunca la dimensión. Si cambia un atributo de un producto existente, la validación falla: este paquete no actualiza atributos ni implementa SCD. Ejecutar una carga a la vez. Si una ejecución se interrumpe después de insertar, se puede repetir: extraerá las claves todavía ausentes.

## Validación y evidencia

Las consultas están en `consultas/productos_origen.sql`, `consultas/validar_origen_productos.sql` y `consultas/validar_dim_producto.sql`; el paquete también las incorpora, sin depender de rutas locales.

Comprobaciones realizadas en una instancia de ensayo con el respaldo y el DDL del proyecto:

- Compilación con SSISBuild correcta y flujo nativo Source → Derived Column → Destination presente.
- Tipos de las cinco columnas contrastados con SQL Server.
- Carga SQL de 20 productos: las 20 descripciones originalmente nulas quedan como `Sin descripción`.
- Miembro desconocido conservado; 21 filas en total.
- Segunda extracción vacía y claves sustitutas conservadas.
- Validación que detecta una descripción alterada en el destino; cambio de prueba revertido.
- Casos adicionales de descripción nula, existente y vacía contrastados mediante SQL.

La evidencia está en `docs/evidencias/validacion_productos.json`. **La carga de ensayo se hizo mediante SQL: no equivale a ejecutar el DTSX.**

**Pendiente antes de cerrar #12:** ejecutar el paquete en SSIS Windows, comprobar las tres tareas y guardar capturas. Ejecutar también la consulta de validación del destino y revisar:

```sql
USE Albarran_DW;
SELECT Producto_SK, Producto_BK, Nombre_Producto, Nombre_Categoria,
       Precio_Catalogo, Descripcion
FROM dbo.Dim_Producto ORDER BY Producto_SK;
```

## Explicación para la presentación

Cada fila representa un producto. Unimos la categoría para tener los atributos de análisis en una sola dimensión. La fuente tiene 20 productos con descripción nula; la transformación los identifica y reemplaza ese valor por `Sin descripción`. Esto completa el atributo sin inventar características del producto. Conservamos el ID original como clave de negocio y SQL Server crea la clave sustituta que utilizarán las ventas.
