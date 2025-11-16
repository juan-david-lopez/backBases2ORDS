-- =====================================================
-- TEST MANUAL: Diagnosticar problemas con matrículas
-- =====================================================

SET SERVEROUTPUT ON

-- Verificar datos iniciales
PROMPT =====================================================
PROMPT ESTADO INICIAL
PROMPT =====================================================

SELECT 'MATRICULA' AS origen, cod_matricula, cod_estudiante, cod_periodo, estado_matricula, total_creditos
FROM MATRICULA WHERE cod_matricula = 1;

SELECT 'GRUPOS' AS origen, cod_grupo, cod_asignatura, numero_grupo, cupo_disponible
FROM GRUPO WHERE cod_grupo BETWEEN 7 AND 12;

SELECT 'DETALLE_MATRICULA' AS origen, COUNT(*) AS total_registros
FROM DETALLE_MATRICULA WHERE cod_matricula = 1;

-- Test 1: Inserción directa
PROMPT
PROMPT =====================================================
PROMPT TEST 1: Inserción directa en DETALLE_MATRICULA
PROMPT =====================================================

BEGIN
    INSERT INTO DETALLE_MATRICULA (cod_matricula, cod_grupo, fecha_inscripcion, estado_inscripcion)
    VALUES (1, 7, SYSDATE, 'INSCRITO');
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Inserción directa exitosa - Grupo 7 agregado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Error en inserción directa: ' || SQLERRM);
        ROLLBACK;
END;
/

SELECT 'DETALLE_MATRICULA' AS origen, cod_detalle_matricula, cod_matricula, cod_grupo, estado_inscripcion
FROM DETALLE_MATRICULA WHERE cod_matricula = 1;

-- Test 2: Usando el procedimiento del paquete
PROMPT
PROMPT =====================================================
PROMPT TEST 2: Usando PKG_MATRICULA.agregar_asignatura
PROMPT =====================================================

DECLARE
    v_mensaje VARCHAR2(500);
BEGIN
    PKG_MATRICULA.agregar_asignatura(
        p_cod_matricula => 1,
        p_cod_grupo => 8,
        p_mensaje => v_mensaje
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Mensaje: ' || v_mensaje);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Error: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Trace: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        ROLLBACK;
END;
/

SELECT 'DETALLE_MATRICULA' AS origen, cod_detalle_matricula, cod_matricula, cod_grupo, estado_inscripcion
FROM DETALLE_MATRICULA WHERE cod_matricula = 1;

-- Test 3: Usando inscribir_asignatura original
PROMPT
PROMPT =====================================================
PROMPT TEST 3: Usando PKG_MATRICULA.inscribir_asignatura
PROMPT =====================================================

DECLARE
    v_cod_detalle NUMBER;
BEGIN
    PKG_MATRICULA.inscribir_asignatura(
        p_cod_matricula => 1,
        p_cod_grupo => 9,
        p_cod_detalle => v_cod_detalle
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Código detalle: ' || v_cod_detalle);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Error: ' || SQLERRM);
        ROLLBACK;
END;
/

-- Estado final
PROMPT
PROMPT =====================================================
PROMPT ESTADO FINAL - Resumen
PROMPT =====================================================

SELECT 
    dm.cod_detalle_matricula,
    dm.cod_matricula,
    g.cod_grupo,
    a.cod_asignatura,
    a.nombre_asignatura,
    a.creditos,
    dm.estado_inscripcion
FROM DETALLE_MATRICULA dm
JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
WHERE dm.cod_matricula = 1;

SELECT cod_matricula, total_creditos, estado_matricula
FROM MATRICULA WHERE cod_matricula = 1;

PROMPT
PROMPT =====================================================
PROMPT Verificar triggers activos
PROMPT =====================================================

SELECT trigger_name, status, triggering_event
FROM USER_TRIGGERS
WHERE table_name IN ('DETALLE_MATRICULA', 'MATRICULA')
ORDER BY table_name;

EXIT;
