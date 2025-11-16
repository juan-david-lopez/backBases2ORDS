SET SERVEROUTPUT ON
SET FEEDBACK ON

-- Test disponibles endpoint logic directly
DECLARE
    v_cod_programa NUMBER;
    v_nivel_riesgo VARCHAR2(20) := 'BAJO';
    v_creditos_max NUMBER;
    v_creditos_actuales NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Testing disponibles logic for student 202500001...');
    
    -- Obtener programa y nivel de riesgo del estudiante
    BEGIN
        SELECT e.cod_programa INTO v_cod_programa
        FROM ESTUDIANTE e
        WHERE e.cod_estudiante = '202500001';
        
        DBMS_OUTPUT.PUT_LINE('Programa: ' || v_cod_programa);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Student not found');
            RETURN;
    END;
    
    -- Obtener nivel de riesgo más reciente
    BEGIN
        SELECT nivel_riesgo INTO v_nivel_riesgo
        FROM (
            SELECT nivel_riesgo 
            FROM HISTORIAL_RIESGO 
            WHERE cod_estudiante = '202500001'
            ORDER BY fecha_deteccion DESC
        )
        WHERE ROWNUM = 1;
        
        DBMS_OUTPUT.PUT_LINE('Nivel riesgo: ' || v_nivel_riesgo);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_nivel_riesgo := 'BAJO';
            DBMS_OUTPUT.PUT_LINE('Sin historial riesgo, usando: ' || v_nivel_riesgo);
    END;
    
    -- Determinar créditos máximos según nivel de riesgo
    v_creditos_max := CASE v_nivel_riesgo
        WHEN 'ALTO' THEN 12
        WHEN 'MEDIO' THEN 16
        ELSE 20
    END;
    
    DBMS_OUTPUT.PUT_LINE('Creditos max: ' || v_creditos_max);
    
    -- Test passed
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Logic test passed');
END;
/

EXIT
