SET SERVEROUTPUT ON;
/*=============================================================================
  REQUERIMIENTO 1
  Funcion almacenada + Procedimiento principal + Manejo de errores + Trigger
=============================================================================*/

-- -----------------------------------------------------------------------
-- 1. FUNCION: obtiene el promedio de notas de un alumno en una asignatura
-- -----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FN_PROMEDIO_ASIGNATURA(
    p_cod_alumno     IN NOTA_ALUMNO.cod_alumno%TYPE,
    p_cod_asignatura IN NOTA_ALUMNO.cod_asignatura%TYPE
) RETURN NUMBER
IS
    v_promedio NUMBER;
BEGIN
    SELECT ROUND(
             (nota1 + nota2 + nota3 + NVL(nota4,0) + NVL(nota5,0))
             / (3 + CASE WHEN nota4 IS NOT NULL THEN 1 ELSE 0 END
                  + CASE WHEN nota5 IS NOT NULL THEN 1 ELSE 0 END)
           , 1)
    INTO v_promedio
    FROM NOTA_ALUMNO
    WHERE cod_alumno = p_cod_alumno
      AND cod_asignatura = p_cod_asignatura;

    RETURN v_promedio;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END;
/
-- -----------------------------------------------------------------------
-- 2. PROCEDIMIENTO PRINCIPAL: procesa a todos los alumnos, calcula
--    promedio y situacion, actualiza PROMEDIO_ASIG_ALUMNO y
--    RESUMEN_SITUACION_ASIG. Incluye manejo de errores hacia tabla ERRORES.
-- -----------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE PR_PROCESA_ALUMNOS
IS
    CURSOR c_notas IS
        SELECT cod_alumno, cod_asignatura
        FROM NOTA_ALUMNO;

    v_promedio     NUMBER;
    v_situacion    VARCHAR2(1);
    v_msg_error    VARCHAR2(500);
BEGIN
    FOR r_nota IN c_notas LOOP
        BEGIN
            -- Obtener promedio usando la funcion
            v_promedio := FN_PROMEDIO_ASIGNATURA(r_nota.cod_alumno, r_nota.cod_asignatura);

            -- Determinar situacion (aprobado si promedio >= 4.0)
            IF v_promedio >= 4.0 THEN
                v_situacion := 'A';
            ELSE
                v_situacion := 'R';
            END IF;

            -- Insertar en PROMEDIO_ASIG_ALUMNO
            INSERT INTO PROMEDIO_ASIG_ALUMNO (cod_alumno, cod_asignatura, promedio_asig, situacion_asig)
            VALUES (r_nota.cod_alumno, r_nota.cod_asignatura, v_promedio, v_situacion);

            -- Actualizar RESUMEN_SITUACION_ASIG
            IF v_situacion = 'A' THEN
                UPDATE RESUMEN_SITUACION_ASIG
                SET total_aprob = total_aprob + 1
                WHERE cod_asignatura = r_nota.cod_asignatura;
            ELSE
                UPDATE RESUMEN_SITUACION_ASIG
                SET total_reprob = total_reprob + 1
                WHERE cod_asignatura = r_nota.cod_asignatura;
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                v_msg_error := SQLERRM;
                INSERT INTO ERRORES (id_error, subprograma_error, descripcion_error)
                VALUES (SEQ_ERRORES.NEXTVAL, 'PR_PROCESA_ALUMNOS', v_msg_error);
        END;
    END LOOP;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        v_msg_error := SQLERRM;
        INSERT INTO ERRORES (id_error, subprograma_error, descripcion_error)
        VALUES (SEQ_ERRORES.NEXTVAL, 'PR_PROCESA_ALUMNOS', v_msg_error);
        COMMIT;
END;
/
-- -----------------------------------------------------------------------
-- 3. TRIGGER: restringe insercion, actualizacion y eliminacion de
--    alumnos a la jornada de trabajo (lunes a viernes, 08:00 a 18:00)
-- -----------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_JORNADA_ALUMNO
BEFORE INSERT OR UPDATE OR DELETE ON ALUMNO
FOR EACH ROW
DECLARE
    v_dia  VARCHAR2(3);
    v_hora NUMBER;
BEGIN
    v_dia  := TO_CHAR(SYSDATE, 'DY', 'NLS_DATE_LANGUAGE=SPANISH');
    v_hora := TO_NUMBER(TO_CHAR(SYSDATE, 'HH24'));

    IF v_dia IN ('SAB', 'DOM') OR v_hora < 8 OR v_hora >= 18 THEN
        IF INSERTING THEN
            RAISE_APPLICATION_ERROR(-20501, 'SE DEBE INSERTAR VALORES SOLO EN LA JORNADA DE TRABAJO');
        ELSIF UPDATING THEN
            RAISE_APPLICATION_ERROR(-20503, 'NO PUEDE MODIFICAR A LOS ALUMNOS FUERA DE LA JORNADA DE TRABAJO');
        ELSIF DELETING THEN
            RAISE_APPLICATION_ERROR(-20502, 'NO PUEDE ELIMINAR VALORES DE LA TABLA FUERA DE LA JORNADA DE TRABAJO');
        END IF;
    END IF;
END;
/
/*=============================================================================
  EJECUCION DEL PROCESO PRINCIPAL
=============================================================================*/
EXEC PR_PROCESA_ALUMNOS;

-- Verificacion de resultados
SELECT * FROM PROMEDIO_ASIG_ALUMNO ORDER BY cod_alumno, cod_asignatura;
SELECT * FROM RESUMEN_SITUACION_ASIG ORDER BY cod_asignatura;
/*=============================================================================
  PRUEBAS DEL TRIGGER TRG_JORNADA_ALUMNO
=============================================================================*/
-- 1. Ingresar un nuevo alumno
INSERT INTO ALUMNO VALUES (2222, 20111222, '5', 'CAMILA', 'ANDREA', 'SOTO', 'MUNOZ', 'S', 212);

-- 2. Eliminar un alumno
DELETE FROM ALUMNO WHERE cod_alumno = 2222;

-- 3. Actualizar el nombre de un alumno
UPDATE ALUMNO SET pnombre_alumno = 'JUAN CARLOS' WHERE cod_alumno = 2111;

COMMIT;

-- Verificacion de errores registrados (si el trigger bloqueo alguna operacion)
SELECT * FROM ERRORES ORDER BY id_error;
