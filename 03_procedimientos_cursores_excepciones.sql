SET SERVEROUTPUT ON;

-- REQUERIMIENTO 1
CREATE OR REPLACE PROCEDURE SP_CALCULA_PESOS_COMPRAS
IS
    -- Cursor explícito: recorre todas las facturas
    CURSOR c_facturas IS
        SELECT id_cliente, nro_factura, monto_total
        FROM   FACTURA;

    v_pesos_factura NUMBER;
BEGIN
    FOR fac IN c_facturas LOOP
        v_pesos_factura := ROUND(fac.monto_total * 0.125);

        INSERT INTO DETALLE_PESOS_COMPRAS (id_cliente, nro_factura, pesos_factura)
        VALUES (fac.id_cliente, fac.nro_factura, v_pesos_factura);
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Detalle de pesos por compra calculado y grabado correctamente.');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error al calcular el detalle de pesos: ' || SQLERRM);
END SP_CALCULA_PESOS_COMPRAS;
/


CREATE OR REPLACE PROCEDURE SP_GRABA_TOTAL_PESOS_COMPRAS
IS
    -- Cursor explícito: agrupa el detalle por cliente
    CURSOR c_totales IS
        SELECT id_cliente, SUM(pesos_factura) AS total_pesos
        FROM   DETALLE_PESOS_COMPRAS
        GROUP BY id_cliente;
BEGIN
    FOR tot IN c_totales LOOP
        INSERT INTO TOTAL_PESOS_COMPRAS (id_cliente, total_pesos)
        VALUES (tot.id_cliente, tot.total_pesos);
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Total de pesos por cliente calculado y grabado correctamente.');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error al calcular el total de pesos: ' || SQLERRM);
END SP_GRABA_TOTAL_PESOS_COMPRAS;
/

-- Ejecución de ambos procedimientos, en orden

BEGIN
    SP_CALCULA_PESOS_COMPRAS;
    SP_GRABA_TOTAL_PESOS_COMPRAS;
END;
/

-- Verificación:
SELECT * FROM DETALLE_PESOS_COMPRAS ORDER BY id_cliente, nro_factura;
SELECT * FROM TOTAL_PESOS_COMPRAS ORDER BY id_cliente;


-- REQUERIMIENTO 2

CREATE OR REPLACE FUNCTION FN_CALCULA_COMISION(p_rut_empleado NUMBER)
RETURN NUMBER
IS
    v_total_monto NUMBER := 0;
    v_comision    NUMBER := 0;
BEGIN
    SELECT NVL(SUM(monto_total), 0)
    INTO   v_total_monto
    FROM   FACTURA
    WHERE  rut_empleado = p_rut_empleado;

    IF v_total_monto = 0 THEN
        v_comision := 0;
    ELSE
        v_comision := ROUND(v_total_monto * 0.183);
    END IF;

    RETURN v_comision;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al calcular la comisión: ' || SQLERRM);
        RETURN 0;
END FN_CALCULA_COMISION;
/

-- Ejecución de la función a través de un SELECT sobre EMPLEADO:
SELECT rut_empleado AS "RUT EMPLEADO",
       FN_CALCULA_COMISION(rut_empleado) AS "COMISION"
FROM   EMPLEADO;
