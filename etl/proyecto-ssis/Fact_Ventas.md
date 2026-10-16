# Carga de Fact_Ventas (issue #13)

## Preparación y dependencias

Incorporar primero los paquetes de los issues #9, #10, #11 y #12. El proyecto actualizado en esta rama registra sus nombres reales: `Dim_Sucursal.dtsx`, `Dim_Cliente.dtsx`, `Dim_Empleado.dtsx`, `Dim_Producto.dtsx` y `Fact_Ventas.dtsx`. No incluye un paquete maestro ficticio. Ejecutar las dimensiones y el calendario #6 antes de las ventas.

La corrección de `Albarran_ETL.dtproj` completa el manifiesto de despliegue requerido por SSISBuild, declara SQLServer2022 e incluye los cinco paquetes y las dos conexiones compartidas del #8. Se agrega el archivo `.database` que el proyecto referencia. Los paquetes permanecen en ramas separadas: esta rama de ventas requiere integrar las cuatro dimensiones para compilar el proyecto desde el repositorio.

## Flujo implementado

1. **Validar origen:** comprueba ID de venta único, grano venta/producto sin repeticiones, ventas con detalle y detalles con cabecera. Rechaza cantidades no positivas, precios negativos, descuentos nulos o fuera de 0–1 y montos que exceden NUMERIC(14,2).
2. **Validar destino previo:** exige las cinco dimensiones cargadas, claves de negocio únicas y miembro desconocido -1 en cada dimensión. Si ya hay hechos, exige que coincidan exactamente con el snapshot de origen; una carga parcial o diferente produce error antes de insertar.
3. **Data Flow:**
   - OLE DB Source une `ventas` y `detalle_ventas`. Conserva `Venta_ID` y las claves de negocio; convierte la fecha a YYYYMMDD y usa -1 para claves nulas.
   - Cinco **Lookup** de caché completa buscan Cliente_SK, Empleado_SK, Producto_SK, Sucursal_SK y Fecha_SK en sus dimensiones. En tiempo se compara Fecha_BK con Fecha_SK, que tiene formato YYYYMMDD.
   - Los Lookup usan `NoMatchBehavior=0` y **Ignore failure** únicamente para las filas sin coincidencia en la salida de coincidencias. Sus claves de salida quedan nulas. Derived Column sustituye esas claves por -1; ningún registro se descarta por esa causa. Los errores de conexión, metadatos y duplicados no se convierten en miembros desconocidos.
   - Tres Derived Column consecutivos calculan bruto, descuento y neto. Separarlos permite usar la columna calculada en el paso anterior.
   - OLE DB Destination inserta las doce columnas del DDL. `Venta_SK` no se mapea: la genera SQL Server.
4. **Validar resultado:** compara todas las claves, atributos e importes con la fuente y verifica también la multiplicidad de filas, además de la ausencia de claves huérfanas.

## Medidas y supuestos

```text
Monto_Bruto     = Cantidad × Precio_Unitario
Monto_Descuento = redondear(Monto_Bruto × Porcentaje_Descuento, 2)
Monto_Neto      = Monto_Bruto − Monto_Descuento
```

Precio_Unitario usa NUMERIC(12,2), porcentaje NUMERIC(5,4) y montos NUMERIC(14,2), conforme al modelo. Se interpreta el descuento como fracción: 0,10 significa 10 %. El respaldo tiene todos sus descuentos en cero; se probó además un caso sintético no nulo para contrastar el redondeo. Si la fuente futura expresa 10 en vez de 0,10, esta carga falla y debe acordarse la conversión, no dividirlo silenciosamente.

El grano es un producto por venta. Actualmente hay 365 filas de detalle y 365 ventas distintas; esos números no tienen por qué ser iguales en otra fuente. El control rechaza repeticiones del par venta/producto porque el modelo actual no conserva un identificador de línea para distinguirlas.

## Repetición y recuperación

Este paquete carga un **snapshot inicial completo**, no es un ETL incremental:

- Si Fact_Ventas está vacía, extrae todos los detalles. La decisión se guarda en una variable SQL local antes de leer filas, para no observar las inserciones del propio flujo.
- Si ya contiene el snapshot completo y correcto, valida el contenido y extrae cero filas. No cambia las claves existentes.
- Si contiene una carga parcial o la fuente cambió, se detiene. No borra hechos ni mezcla snapshots automáticamente. Revisar el error y acordar la recuperación; una reconstrucción exige vaciar exclusivamente Fact_Ventas de forma controlada después de respaldar lo necesario.
- No ejecutar dos cargas simultáneas ni modificar origen o dimensiones durante la carga. La inserción masiva usa un único lote, pero no se afirma una transacción distribuida para todas las tareas: si falla la validación final, revisar el estado antes de repetir.

## Configuración y ejecución en Windows

1. Integrar primero las ramas de las cuatro dimensiones y después esta rama. Abrir `Albarran_ETL.sln` en Visual Studio con la extensión SSIS y controlador OLE DB x64 instalados.
2. Restaurar `Albarran` y ejecutar el DDL #4 una sola vez en el destino preparado para la carga. El DDL elimina tablas existentes: no volver a ejecutarlo después de cargar dimensiones.
3. Ejecutar `03_poblar_dim_tiempo.sql` y los cuatro paquetes de dimensiones. El orden entre esas cuatro dimensiones es libre; todos deben terminar antes de los hechos.
4. Probar las conexiones locales `Origen_Albarran` y `Destino_Albarran_DW` de **cada paquete**. Usan servidor `.` y Windows Authentication como ejemplo. Configurar las bases en la misma instancia; adaptar servidor, puerto, proveedor y autenticación. No guardar contraseñas en Git. Configurar también las conexiones compartidas si se van a utilizar; no reemplazan automáticamente las locales.
5. Ejecutar `Fact_Ventas.dtsx`. Comprobar las cuatro tareas de control y los cinco Lookup del Data Flow.
6. Ejecutar `consultas/validar_ventas.sql` en Albarran_DW y después el script de cuadratura del #14. Este último debe dar nueve APROBADO [PASS]. Generar el respaldo final solo después de esa ejecución real del grupo.
7. Repetir el paquete: debe extraer cero filas y conservar 365 hechos en el respaldo actual.

## Evidencia disponible y pendiente

Las consultas incorporadas están también en `consultas/ventas_origen.sql`, `validar_origen_ventas.sql`, `validar_destino_previo_ventas.sql` y `validar_ventas.sql`. `ventas_transformadas_control.sql` es una consulta SQL equivalente para contrastar las transformaciones; no sustituye el Data Flow.

En una instancia aislada de ensayo con el respaldo original y el DDL del proyecto:

- Compilación individual y compilación conjunta de los cinco paquetes correctas con SSISBuild para SQL Server 2022.
- Transformaciones de claves y montos contrastadas entre SQL y Python para todas las filas.
- 365 hechos, 365 ventas distintas y 724 unidades. Bruto y neto: 414.022.446,00; descuento: 0,00.
- Segunda extracción vacía y claves sustitutas conservadas.
- Carga parcial y monto alterado detectados antes de cargar; cambios de prueba revertidos.
- Cinco pruebas retirando temporalmente una clave dimensional, una dimensión por vez: las filas correspondientes pasan a -1, sin pérdida de filas ni violación de FK. Todas las alteraciones se revirtieron.
- Caso sintético: 3 × 100,05 = 300,15; descuento 10 % redondeado a 30,02.
- Las nueve comprobaciones del script #14 pasan sobre esa carga SQL de ensayo.

Evidencias: `docs/evidencias/validacion_ventas.json`, `compilacion_proyecto_ssis.json` y `cuadratura_sql_ensayo.json`.

**Pendiente antes de cerrar #13:** ejecutar el DTSX en SSIS Windows y capturar tareas, Data Flow y resultados de cuadratura. Las cargas de ensayo se hicieron mediante SQL, no ejecutando SSIS. No se generó el respaldo final del grupo.

## Explicación para la defensa

Cada detalle de venta se conecta con sus dimensiones mediante sus claves sustitutas. Los Lookup buscan esas claves a partir de los identificadores del sistema original. Si una clave no tiene coincidencia, usamos el miembro desconocido -1 para conservar la venta y señalar el dato faltante. Después calculamos bruto, descuento y neto y contrastamos el resultado con la fuente, tanto por fila como en los totales.
