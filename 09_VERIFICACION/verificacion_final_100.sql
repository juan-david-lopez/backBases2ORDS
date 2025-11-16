-- ============================================================
-- VERIFICACIÓN FINAL COMPLETA DEL SISTEMA
-- Sistema de Gestión Académica - 100% Completitud
-- ============================================================

SET SERVEROUTPUT ON
SET LINESIZE 200
SET PAGESIZE 1000

PROMPT ============================================================
PROMPT 1. VERIFICACIÓN DE TABLAS (Objetivo: 26 tablas)
PROMPT ============================================================

SELECT COUNT(*) as total_tablas
FROM USER_TABLES;

SELECT table_name, num_rows
FROM USER_TABLES
ORDER BY table_name;

PROMPT 
PROMPT ============================================================
PROMPT 2. VERIFICACIÓN DE TRIGGERS (Objetivo: 40+ triggers)
PROMPT ============================================================

SELECT 
    status,
    COUNT(*) as cantidad
FROM USER_TRIGGERS
GROUP BY status
ORDER BY status;

PROMPT 
PROMPT Triggers críticos nuevos:
SELECT trigger_name, status, trigger_type
FROM USER_TRIGGERS
WHERE trigger_name IN (
    'TRG_VALIDAR_CREDITOS_RIESGO',
    'TRG_VALIDAR_VENTANA_CALENDARIO',
    'TRG_VALIDAR_CHOQUE_HORARIO',
    'TRG_VALIDAR_REGLA_EVALUACION',
    'TRG_VALIDAR_TRABAJO_GRADO',
    'TRG_BLOQUEAR_NOTAS_CERRADAS',
    'TRG_VALIDAR_CANCELACION_MATERIA',
    'TRG_VALIDAR_CARGA_DOCENTE',
    'TRG_VALIDAR_HORARIO_DOCENTE',
    'TRG_ALERTAS_TEMPRANAS'
)
ORDER BY trigger_name;

PROMPT 
PROMPT ============================================================
PROMPT 3. VERIFICACIÓN DE FUNCIONES (Objetivo: 9 funciones)
PROMPT ============================================================

SELECT 
    object_name,
    status
FROM USER_OBJECTS
WHERE object_type = 'FUNCTION'
AND (object_name LIKE 'FN_%' OR object_name LIKE 'F_%')
ORDER BY object_name;

SELECT 
    status,
    COUNT(*) as cantidad
FROM USER_OBJECTS
WHERE object_type = 'FUNCTION'
AND (object_name LIKE 'FN_%' OR object_name LIKE 'F_%')
GROUP BY status;

PROMPT 
PROMPT ============================================================
PROMPT 4. VERIFICACIÓN DE PAQUETES (Objetivo: 4 paquetes)
PROMPT ============================================================

SELECT 
    object_name,
    object_type,
    status
FROM USER_OBJECTS
WHERE object_type IN ('PACKAGE', 'PACKAGE BODY')
AND object_name LIKE 'PKG_%'
ORDER BY object_name, object_type;

PROMPT 
PROMPT ============================================================
PROMPT 5. VERIFICACIÓN DE VISTAS/REPORTES (Objetivo: 18+ vistas)
PROMPT ============================================================

SELECT COUNT(*) as total_vistas
FROM USER_VIEWS;

PROMPT 
PROMPT Vistas analíticas creadas:
SELECT view_name
FROM USER_VIEWS
WHERE view_name LIKE 'VW_%'
ORDER BY view_name;

PROMPT 
PROMPT ============================================================
PROMPT 6. VERIFICACIÓN DE SECUENCIAS
PROMPT ============================================================

SELECT 
    sequence_name,
    last_number
FROM USER_SEQUENCES
ORDER BY sequence_name;

PROMPT 
PROMPT ============================================================
PROMPT 7. VERIFICACIÓN DE CONSTRAINTS
PROMPT ============================================================

SELECT 
    constraint_type,
    CASE constraint_type
        WHEN 'P' THEN 'Primary Key'
        WHEN 'R' THEN 'Foreign Key'
        WHEN 'C' THEN 'Check/Not Null'
        WHEN 'U' THEN 'Unique'
        ELSE 'Other'
    END as tipo_descripcion,
    COUNT(*) as cantidad
FROM USER_CONSTRAINTS
GROUP BY constraint_type
ORDER BY constraint_type;

PROMPT 
PROMPT ============================================================
PROMPT 8. VERIFICACIÓN DE ÍNDICES
PROMPT ============================================================

SELECT 
    table_name,
    COUNT(*) as num_indices
FROM USER_INDEXES
WHERE table_name NOT LIKE 'BIN$%'
GROUP BY table_name
ORDER BY num_indices DESC;

PROMPT 
PROMPT ============================================================
PROMPT 9. VERIFICACIÓN DE DATOS (Tablas con registros)
PROMPT ============================================================

DECLARE
    v_count NUMBER;
    TYPE t_tabla IS RECORD (nombre VARCHAR2(50));
    TYPE t_tablas IS TABLE OF t_tabla INDEX BY PLS_INTEGER;
    v_tablas t_tablas;
    v_sql VARCHAR2(1000);
BEGIN
    -- Lista de tablas principales
    v_tablas(1).nombre := 'ESTUDIANTE';
    v_tablas(2).nombre := 'DOCENTE';
    v_tablas(3).nombre := 'ASIGNATURA';
    v_tablas(4).nombre := 'PROGRAMA_ACADEMICO';
    v_tablas(5).nombre := 'GRUPO';
    v_tablas(6).nombre := 'MATRICULA';
    v_tablas(7).nombre := 'DETALLE_MATRICULA';
    v_tablas(8).nombre := 'CALIFICACION';
    v_tablas(9).nombre := 'NOTA_DEFINITIVA';
    v_tablas(10).nombre := 'VENTANA_CALENDARIO';
    v_tablas(11).nombre := 'HISTORIAL_RIESGO';
    v_tablas(12).nombre := 'AUDITORIA';
    v_tablas(13).nombre := 'SALON';
    v_tablas(14).nombre := 'HORARIO_GRUPO';
    v_tablas(15).nombre := 'FORMACION_ACADEMICA_DOCENTE';
    v_tablas(16).nombre := 'HISTORIAL_ACADEMICO';
    
    DBMS_OUTPUT.PUT_LINE(RPAD('TABLA', 40) || RPAD('REGISTROS', 15));
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 40, '-') || RPAD('-', 15, '-'));
    
    FOR i IN 1..v_tablas.COUNT LOOP
        BEGIN
            v_sql := 'SELECT COUNT(*) FROM ' || v_tablas(i).nombre;
            EXECUTE IMMEDIATE v_sql INTO v_count;
            DBMS_OUTPUT.PUT_LINE(RPAD(v_tablas(i).nombre, 40) || RPAD(v_count, 15));
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE(RPAD(v_tablas(i).nombre, 40) || 'ERROR/NO EXISTE');
        END;
    END LOOP;
END;
/

PROMPT 
PROMPT ============================================================
PROMPT 10. VERIFICACIÓN ORDS (Endpoints habilitados)
PROMPT ============================================================

SELECT 
    module_name,
    COUNT(*) as templates
FROM USER_ORDS_MODULES
GROUP BY module_name
ORDER BY module_name;

PROMPT 
PROMPT Total módulos ORDS:
SELECT COUNT(DISTINCT module_name) as total_modulos
FROM USER_ORDS_MODULES;

PROMPT 
PROMPT ============================================================
PROMPT 11. OBJETOS INVÁLIDOS (Debe ser 0)
PROMPT ============================================================

SELECT 
    object_type,
    object_name,
    status
FROM USER_OBJECTS
WHERE status = 'INVALID'
ORDER BY object_type, object_name;

SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN 'OK - NO HAY OBJETOS INVALIDOS'
        ELSE 'ADVERTENCIA - HAY ' || COUNT(*) || ' OBJETOS INVALIDOS'
    END as estado_validacion
FROM USER_OBJECTS
WHERE status = 'INVALID';

PROMPT 
PROMPT ============================================================
PROMPT 12. RESUMEN EJECUTIVO
PROMPT ============================================================

DECLARE
    v_tablas NUMBER;
    v_triggers NUMBER;
    v_funciones NUMBER;
    v_paquetes NUMBER;
    v_vistas NUMBER;
    v_invalidos NUMBER;
    v_estudiantes NUMBER;
    v_docentes NUMBER;
    v_grupos NUMBER;
    v_matriculas NUMBER;
    v_porcentaje_completo NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_tablas FROM USER_TABLES;
    SELECT COUNT(*) INTO v_triggers FROM USER_TRIGGERS WHERE status = 'ENABLED';
    SELECT COUNT(*) INTO v_funciones FROM USER_OBJECTS WHERE object_type = 'FUNCTION' AND status = 'VALID';
    SELECT COUNT(*) INTO v_paquetes FROM USER_OBJECTS WHERE object_type = 'PACKAGE' AND status = 'VALID';
    SELECT COUNT(*) INTO v_vistas FROM USER_VIEWS;
    SELECT COUNT(*) INTO v_invalidos FROM USER_OBJECTS WHERE status = 'INVALID';
    SELECT COUNT(*) INTO v_estudiantes FROM ESTUDIANTE;
    SELECT COUNT(*) INTO v_docentes FROM DOCENTE;
    SELECT COUNT(*) INTO v_grupos FROM GRUPO;
    SELECT COUNT(*) INTO v_matriculas FROM MATRICULA;
    
    -- Calcular porcentaje (basado en objetivos: 26 tablas, 40 triggers, 9 funciones, 4 paquetes, 18 vistas)
    v_porcentaje_completo := ROUND((
        (v_tablas / 26 * 100 * 0.15) +
        (v_triggers / 40 * 100 * 0.25) +
        (v_funciones / 9 * 100 * 0.15) +
        (v_paquetes / 4 * 100 * 0.15) +
        (v_vistas / 18 * 100 * 0.30)
    ), 2);
    
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('SISTEMA DE GESTION ACADEMICA');
    DBMS_OUTPUT.PUT_LINE('Reporte de Completitud Final');
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('ESTRUCTURA DE BASE DE DATOS:');
    DBMS_OUTPUT.PUT_LINE('  Tablas creadas: ' || v_tablas || ' de 26 (' || ROUND(v_tablas/26*100, 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('  Triggers activos: ' || v_triggers || ' de 40 (' || ROUND(v_triggers/40*100, 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('  Funciones válidas: ' || v_funciones || ' de 9 (' || ROUND(v_funciones/9*100, 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('  Paquetes válidos: ' || v_paquetes || ' de 4 (' || ROUND(v_paquetes/4*100, 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('  Vistas/Reportes: ' || v_vistas || ' de 18 (' || ROUND(v_vistas/18*100, 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('  Objetos inválidos: ' || v_invalidos);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('DATOS DEL SISTEMA:');
    DBMS_OUTPUT.PUT_LINE('  Estudiantes registrados: ' || v_estudiantes);
    DBMS_OUTPUT.PUT_LINE('  Docentes registrados: ' || v_docentes);
    DBMS_OUTPUT.PUT_LINE('  Grupos activos: ' || v_grupos);
    DBMS_OUTPUT.PUT_LINE('  Matrículas procesadas: ' || v_matriculas);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('COMPLETITUD ESTIMADA: ' || v_porcentaje_completo || '%');
    DBMS_OUTPUT.PUT_LINE('========================================');
    
    IF v_porcentaje_completo >= 95 THEN
        DBMS_OUTPUT.PUT_LINE('ESTADO: EXCELENTE - Sistema listo para producción');
    ELSIF v_porcentaje_completo >= 85 THEN
        DBMS_OUTPUT.PUT_LINE('ESTADO: BUENO - Sistema operativo con funcionalidad completa');
    ELSIF v_porcentaje_completo >= 75 THEN
        DBMS_OUTPUT.PUT_LINE('ESTADO: ACEPTABLE - Funciones core implementadas');
    ELSE
        DBMS_OUTPUT.PUT_LINE('ESTADO: EN DESARROLLO - Requiere más trabajo');
    END IF;
END;
/

PROMPT 
PROMPT ============================================================
PROMPT VERIFICACION COMPLETADA
PROMPT ============================================================

EXIT
