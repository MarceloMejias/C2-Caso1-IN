# Dimensión tiempo

El script `database/scripts/03_poblar_dim_tiempo.sql` corresponde al issue #6. Genera un calendario diario desde el 1 de enero de 2017 hasta el 31 de diciembre de 2026. El intervalo contiene **3.652 fechas**, incluidos los días sin ventas y el 29 de febrero de 2020 y 2024.

## Uso

1. Ejecutar el DDL del issue #4 para crear `Albarran_DW.dbo.Dim_Tiempo`.
2. Ejecutar `03_poblar_dim_tiempo.sql` en la misma instancia de SQL Server.
3. Revisar el resumen final: 3.652 fechas en el intervalo; 366 días en 2020 y 2024, y 365 en los demás años.
4. Repetir el script: debe indicar cero fechas insertadas y conservar los mismos totales.

El script no crea tablas del modelo ni reemplaza registros existentes. Conserva el miembro desconocido `-1` definido en el DDL, que debe tener una fecha fuera del intervalo o nula. Si encuentra atributos de calendario inconsistentes, revierte la inserción y muestra un error.

## Columnas requeridas por el issue #6

| Columna | Ejemplo para 2024-02-29 | Significado |
|---|---|---|
| `Fecha_SK` | 20240229 | Clave numérica YYYYMMDD |
| `Fecha` | 2024-02-29 | Fecha del calendario |
| `Anio` | 2024 | Año |
| `Semestre` | 1 | Enero-junio: 1; julio-diciembre: 2 |
| `Trimestre` | 1 | Trimestre de 1 a 4 |
| `Mes` | 2 | Mes de 1 a 12 |
| `Nombre_Mes` | Febrero | Nombre en español |
| `Dia` | 29 | Día del mes |
| `Dia_Semana` | 4 | Lunes: 1; domingo: 7 |
| `Nombre_Dia_Semana` | Jueves | Nombre en español |
| `Es_Fin_De_Semana` | 0 | Sábado/domingo: 1; resto: 0 |

Los nombres se fijan expresamente en español y el número de día se calcula a partir de un lunes conocido. Así no dependen del idioma de SQL Server ni de `SET DATEFIRST`.

La carga inserta solo las claves ausentes y valida las fechas y sus atributos dentro de una transacción. Admite `Fecha_SK` con o sin `IDENTITY`; cuando existe esa propiedad, habilita temporalmente `IDENTITY_INSERT` para conservar YYYYMMDD.

## Coordinación con el DDL

La tabla definitiva pertenece al issue #4. Debe exponer las columnas anteriores y aceptar esos valores. Los textos de nombres de mes y día requieren Unicode (`NVARCHAR`) para conservar tildes. Si el DDL incorpora otras columnas obligatorias sin valor predeterminado, hay que acordar su carga antes de integrar este script.

La prueba en una tabla de ensayo verifica la lógica del calendario. La integración final debe repetirse sobre el DDL publicado por Marcelo antes de dar por terminado el issue #6.

## Explicación para la defensa

Cada fila representa un día. Las ventas guardan una clave que apunta a ese día y sus atributos permiten agrupar por mes, trimestre o año. Cargamos también fechas sin ventas para disponer de un calendario continuo. Generar fechas hasta 2026 no crea ventas futuras: solo deja disponible el calendario.
