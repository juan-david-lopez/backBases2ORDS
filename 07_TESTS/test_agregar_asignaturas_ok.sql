-- =====================================================
-- TEST: Agregar asignaturas después de corregir fechas
-- =====================================================

SET SERVEROUTPUT ON

PROMPT =====================================================
PROMPT Agregando asignaturas a matrícula #1
PROMPT =====================================================

-- Agregar IS101 (Grupo 7)
DECLARE
    v_mensaje VARCHAR2(500);
BEGIN
    DBMS_OUTPUT.PUT_LINE('Agregando IS101 (Grupo 7)...');
    PKG_MATRICULA.agregar_asignatura(
        p_cod_matricula => 1,
        p_cod_grupo => 7,
        p_mensaje => v_mensaje
    );
    DBMS_OUTPUT.PUT_LINE('  ' || v_mensaje);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('  ✗ Error: ' || SQLERRM);
        ROLLBACK;
END;
/

-- Agregar IS102 (Grupo 8)
DECLARE
    v_mensaje VARCHAR2(500);
BEGIN
    DBMS_OUTPUT.PUT_LINE('Agregando IS102 (Grupo 8)...');
    PKG_MATRICULA.agregar_asignatura(
        p_cod_matricula => 1,
        p_cod_grupo => 8,
        p_mensaje => v_mensaje
    );
    DBMS_OUTPUT.PUT_LINE('  ' || v_mensaje);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('  ✗ Error: ' || SQLERRM);
        ROLLBACK;
END;
/

-- Agregar IS103 (Grupo 9)
DECLARE
    v_mensaje VARCHAR2(500);
BEGIN
    DBMS_OUTPUT.PUT_LINE('Agregando IS103 (Grupo 9)...');
    PKG_MATRICULA.agregar_asignatura(
        p_cod_matricula => 1,
        p_cod_grupo => 9,
        p_mensaje => v_mensaje
    );
    DBMS_OUTPUT.PUT_LINE('  ' || v_mensaje);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('  ✗ Error: ' || SQLERRM);
        ROLLBACK;
END;
/

-- Agregar IS104 (Grupo 10)
DECLARE
    v_mensaje VARCHAR2(500);
BEGIN
    DBMS_OUTPUT.PUT_LINE('Agregando IS104 (Grupo 10)...');
    PKG_MATRICULA.agregar_asignatura(
        p_cod_matricula => 1,
        p_cod_grupo => 10,
        p_mensaje => v_mensaje
    );
    DBMS_OUTPUT.PUT_LINE('  ' || v_mensaje);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('  ✗ Error: ' || SQLERRM);
        ROLLBACK;
END;
/

PROMPT
PROMPT =====================================================
PROMPT Verificando resultados
PROMPT =====================================================

COLUMN nombre_asignatura FORMAT A30
COLUMN estado_inscripcion FORMAT A20

SELECT 
    dm.cod_detalle_matricula,
    a.cod_asignatura,
    a.nombre_asignatura,
    a.creditos,
    dm.estado_inscripcion,
    g.cupo_disponible
FROM DETALLE_MATRICULA dm
JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
WHERE dm.cod_matricula = 1
ORDER BY a.cod_asignatura;

PROMPT
PROMPT =====================================================
PROMPT Estado de la matrícula
PROMPT =====================================================

SELECT 
    cod_matricula,
    cod_estudiante,
    total_creditos,
    estado_matricula,
    TO_CHAR(fecha_matricula, 'DD/MM/YYYY') AS fecha_matricula
FROM MATRICULA
WHERE cod_matricula = 1;

EXIT;
