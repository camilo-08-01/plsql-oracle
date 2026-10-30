# PL/SQL en Oracle

Ejercicios de programación de bases de datos en **PL/SQL** (Oracle), desarrollados en el ramo *Programación de Base de Datos* del programa Analista Programador (IPLACEX).

Cada script resuelve un caso de negocio sobre un esquema entregado en el ramo. Las tablas y los datos de ejemplo no se incluyen en este repositorio, y los datos que aparecen en las pruebas son ficticios.

## Contenido

| Script | Qué muestra |
| --- | --- |
| `01_funcion_procedimiento_trigger.sql` | Función almacenada que calcula el promedio de notas, procedimiento que recorre un cursor, calcula la situación (aprobado/reprobado), actualiza tablas resumen y registra errores en una tabla `ERRORES` con secuencia, y trigger que restringe INSERT/UPDATE/DELETE a la jornada laboral con `RAISE_APPLICATION_ERROR`. |
| `02_cursores_anidados_y_trigger.sql` | Bloque anónimo con cursor parametrizado anidado para calcular el porcentaje de aumento de comisiones por rango, y trigger de horario laboral sobre una tabla de clientes. |
| `03_procedimientos_cursores_excepciones.sql` | Procedimientos con cursores explícitos, `COMMIT`/`ROLLBACK` y manejo de excepciones, y función que calcula comisiones. |

## Conceptos aplicados

Cursores explícitos y parametrizados · funciones y procedimientos almacenados · triggers de fila (`BEFORE INSERT OR UPDATE OR DELETE`) · `%TYPE` · manejo de excepciones (`EXCEPTION`, `SQLERRM`, `RAISE_APPLICATION_ERROR`) · secuencias · control de transacciones.

## Cómo ejecutarlos

Requieren Oracle Database (por ejemplo Oracle XE 18c) y un cliente como SQL Developer. Ejecuta primero el esquema y los datos del ejercicio, y luego el script con `SET SERVEROUTPUT ON`.
