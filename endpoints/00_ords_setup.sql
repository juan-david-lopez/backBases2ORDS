-- =====================================================
-- CONFIGURACIÓN INICIAL DE ORDS
-- Archivo: 00_ords_setup.sql
-- Propósito: Habilitar esquema y crear módulos REST
-- Ejecutar como: ACADEMICO
-- =====================================================

SET SERVEROUTPUT ON
SET ECHO ON

PROMPT '========================================='
PROMPT 'CONFIGURACIÓN DE ORDS PARA ACADEMICO'
PROMPT '========================================='
PROMPT ''

-- =====================================================
-- PASO 1: HABILITAR ESQUEMA PARA REST
-- =====================================================

PROMPT 'Habilitando esquema ACADEMICO para REST...'

BEGIN
    ORDS.ENABLE_SCHEMA(
        p_enabled             => TRUE,
        p_schema              => 'ACADEMICO',
        p_url_mapping_type    => 'BASE_PATH',
        p_url_mapping_pattern => 'academico',
        p_auto_rest_auth      => FALSE
    );
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('✓ Esquema habilitado para REST');
    DBMS_OUTPUT.PUT_LINE('✓ URL Base: /ords/academico/');
END;
/

PROMPT ''
PROMPT '========================================='
PROMPT 'ESQUEMA HABILITADO EXITOSAMENTE'
PROMPT '========================================='
PROMPT ''
PROMPT 'URL Base: http://localhost:8080/ords/academico/'
PROMPT ''

-- =====================================================
-- NOTA: Los siguientes scripts crearán los módulos
-- específicos para cada entidad del sistema
-- =====================================================

PROMPT 'Ejecute los siguientes scripts en orden:'
PROMPT '  1. @01_estudiantes_api.sql'
PROMPT '  2. @02_docentes_api.sql'
PROMPT '  3. @03_matriculas_api.sql'
PROMPT '  4. @04_calificaciones_api.sql'
PROMPT '  5. @05_consultas_api.sql'
PROMPT ''


