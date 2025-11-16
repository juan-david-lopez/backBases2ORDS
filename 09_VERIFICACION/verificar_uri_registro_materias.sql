SET SERVEROUTPUT ON;
SET LINESIZE 200;
SET PAGESIZE 1000;

PROMPT ============================================================
PROMPT VERIFICACIÓN COMPLETA - MÓDULO REGISTRO_MATERIAS
PROMPT ============================================================

PROMPT 
PROMPT 1. Verificando módulo registro_materias...
SELECT 
    m.id AS module_id,
    m.name AS module_name,
    m.uri_prefix,
    m.status,
    m.items_per_page
FROM USER_ORDS_MODULES m
WHERE UPPER(m.name) = 'REGISTRO_MATERIAS';

PROMPT 
PROMPT 2. Templates con URIs completas...
SELECT 
    t.id AS template_id,
    t.uri_template,
    m.uri_prefix || t.uri_template AS uri_completa
FROM USER_ORDS_TEMPLATES t
JOIN USER_ORDS_MODULES m ON t.module_id = m.id
WHERE UPPER(m.name) = 'REGISTRO_MATERIAS'
ORDER BY t.uri_template;

PROMPT 
PROMPT 3. Handlers con métodos HTTP...
SELECT 
    m.uri_prefix || t.uri_template AS uri_completa,
    h.method AS metodo_http,
    h.source_type,
    LENGTH(h.source) AS tam_sql,
    CASE WHEN h.source IS NOT NULL THEN 'SI' ELSE 'NO' END AS tiene_sql
FROM USER_ORDS_HANDLERS h
JOIN USER_ORDS_TEMPLATES t ON h.template_id = t.id
JOIN USER_ORDS_MODULES m ON t.module_id = m.id
WHERE UPPER(m.name) = 'REGISTRO_MATERIAS'
ORDER BY uri_completa, metodo_http;

PROMPT 
PROMPT 4. Verificando SQL de handler disponibles (completo)...
DECLARE
    v_source CLOB;
BEGIN
    SELECT h.source INTO v_source
    FROM USER_ORDS_HANDLERS h
    JOIN USER_ORDS_TEMPLATES t ON h.template_id = t.id
    JOIN USER_ORDS_MODULES m ON t.module_id = m.id
    WHERE UPPER(m.name) = 'REGISTRO_MATERIAS'
    AND t.uri_template = 'disponibles/:cod_estudiante'
    AND h.method = 'GET';
    
    DBMS_OUTPUT.PUT_LINE('SQL del handler disponibles/:cod_estudiante:');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    DBMS_OUTPUT.PUT_LINE(v_source);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Handler no encontrado');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

PROMPT 
PROMPT 5. Verificando función PKG_REGISTRO_MATERIAS.obtener_asignaturas_disponibles...
SELECT object_name, object_type, status
FROM USER_OBJECTS
WHERE object_name = 'PKG_REGISTRO_MATERIAS'
AND object_type IN ('PACKAGE', 'PACKAGE BODY');

PROMPT 
PROMPT 6. Probando llamada directa a la función...
DECLARE
    v_result SYS_REFCURSOR;
    v_cod VARCHAR2(50);
    v_nombre VARCHAR2(200);
    v_creditos NUMBER;
BEGIN
    v_result := PKG_REGISTRO_MATERIAS.obtener_asignaturas_disponibles('202500001');
    
    DBMS_OUTPUT.PUT_LINE('Función ejecutada correctamente. Resultados:');
    LOOP
        FETCH v_result INTO v_cod, v_nombre, v_creditos;
        EXIT WHEN v_result%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('  - ' || v_cod || ': ' || v_nombre || ' (' || v_creditos || ' créditos)');
    END LOOP;
    CLOSE v_result;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al ejecutar función: ' || SQLERRM);
END;
/

PROMPT 
PROMPT ============================================================
PROMPT Finalizando verificación...
PROMPT ============================================================
EXIT;
