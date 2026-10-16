# Proyecto SSIS Albarran_ETL — Fase 1

Solución de Visual Studio 2022 con destino SQL Server 2022. El #8 aporta la solución y las conexiones; los issues #9–#13 aportan sus cinco paquetes. La integración del #13 completa el manifiesto del proyecto, incluye el archivo .database referenciado y registra los nombres reales de los paquetes.

## Dependencias entre ramas

Integrar primero las cuatro ramas de dimensiones en main y después la rama de ventas. Mientras falte alguna, el proyecto conjunto puede mostrar archivos ausentes. La compilación conjunta se verificó en una copia que reúne los cinco archivos reales; eso no significa que los PR pendientes ya estén integrados en main.

| Issue | Archivo | Rama |
|---|---|---|
| #9 | Dim_Sucursal.dtsx | feature/carga-sucursales |
| #10 | Dim_Cliente.dtsx | feature/carga-clientes |
| #11 | Dim_Empleado.dtsx | feature/carga-empleados |
| #12 | Dim_Producto.dtsx | feature/carga-productos |
| #13 | Fact_Ventas.dtsx | feature/carga-ventas |

No existe un paquete 00_Master_ETL.dtsx en esta entrega. La secuencia se ejecuta manualmente en Visual Studio. No crear referencias a paquetes inexistentes para representar tareas pendientes.

## Preparar Windows

Se necesita Visual Studio 2022 con [SQL Server Integration Services Projects](https://marketplace.visualstudio.com/items?itemName=SSIS.MicrosoftDataToolsIntegrationServices), controlador Microsoft OLE DB x64 y acceso a una instancia con Albarran y Albarran_DW. Las consultas usan ambas bases en la misma instancia.

1. Restaurar database/backup/Albarran.bak como Albarran.
2. Ejecutar 02_crear_modelo_dimensional.sql sobre el destino preparado para la carga y luego 03_poblar_dim_tiempo.sql. El DDL elimina tablas existentes: no repetirlo después de cargar dimensiones si se quiere conservar su contenido.
3. Abrir Albarran_ETL.sln y comprobar que estén los cinco paquetes.
4. Probar las conexiones locales de cada paquete: Origen_Albarran y Destino_Albarran_DW. El ejemplo usa servidor . y autenticación integrada. Ajustar servidor, puerto y autenticación según el entorno; no guardar contraseñas en Git.
5. Seleccionar el proveedor realmente instalado mediante el editor: MSOLEDBSQL o MSOLEDBSQL19. Comprobar ambas conexiones antes de ejecutar.

Las conexiones compartidas Albarran_OLTP.conmgr y Albarran_DW.conmgr se conservan del #8. Los paquetes incluyen conexiones locales y no se vinculan automáticamente a ellas. Para centralizarlas, actualizar también las referencias de las tareas Execute SQL y de los componentes del Data Flow. El parámetro ServerName del #8 no modifica automáticamente las conexiones locales.

## Orden de ejecución

1. Calendario #6: 3.652 días de 2017 a 2026 y miembro desconocido -1.
2. Los cuatro paquetes de dimensiones. Pueden ejecutarse en cualquier orden entre ellos, uno a la vez.
3. Fact_Ventas.dtsx, cuando las dimensiones hayan terminado correctamente.
4. database/scripts/04_validacion_cuadratura_dw.sql del #14, desde SSMS sobre la misma instancia.
5. Generar y verificar el respaldo final siguiendo docs/modelo-dimensional/validacion_cuadratura_dw.md, después de comprobar todos los resultados.

Los paquetes de dimensiones insertan claves ausentes; no usan Truncate & Load. Ventas implementa un snapshot inicial: si el contenido existente coincide con la fuente, repetir extrae cero filas; si está incompleto o cambió la fuente, se detiene. Consultar [Fact_Ventas.md](Fact_Ventas.md) antes de recuperar una carga interrumpida. No ejecutar cargas concurrentes ni modificar origen/dimensiones durante el proceso.

## Resultado esperado con el respaldo entregado

| Tabla | Filas reales | Miembro desconocido adicional |
|---|---:|---:|
| Dim_Sucursal | 3 | 1 |
| Dim_Cliente | 20 | 1 |
| Dim_Empleado | 15 | 1 |
| Dim_Producto | 20 | 1 |
| Dim_Tiempo | 3.652 | 1 |
| Fact_Ventas | 365 | No corresponde |

Las ventas contienen 724 unidades y 414.022.446,00 de bruto y neto, con descuento total cero en este respaldo. Las claves sustitutas no tienen por qué coincidir numéricamente entre equipos; importa que las relaciones y atributos correspondan.

## Qué está comprobado y qué falta

Las pruebas en una instancia SQL de ensayo contrastan las transformaciones con el respaldo y el DDL del proyecto. Las nueve pruebas del #14 pasan en esa carga de ensayo. SSISBuild compila los paquetes individuales y la copia integrada de los cinco paquetes para SQL Server 2022.

**Todavía se requiere ejecución real en SSIS Windows.** Guardar capturas de tareas y Data Flow correctos, repetir las cargas, ejecutar la cuadratura y generar el backup final del grupo. La evidencia SQL no es una captura de ejecución SSIS y el respaldo de ensayo no sustituye el entregable final.

Guías por paquete: [Sucursal](Dim_Sucursal.md), [Cliente](Dim_Cliente.md), [Empleado](Dim_Empleado.md), [Producto](Dim_Producto.md), [Ventas](Fact_Ventas.md). Evidencias disponibles en docs/evidencias/.
