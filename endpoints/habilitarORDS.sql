-- =====================================================
-- HABILITAR ORDS PARA EL ESQUEMA ACADEMICO
-- Ejecutar como SYS
-- =====================================================

SET SERVEROUTPUT ON

PROMPT ''
PROMPT '========================================='
PROMPT 'HABILITANDO ORDS PARA ACADEMICO'
PROMPT '========================================='
PROMPT ''

-- Habilitar ORDS REST para el esquema
BEGIN
    ORDS.ENABLE_SCHEMA(
        p_enabled => TRUE,
        p_schema => 'ACADEMICO',
        p_url_mapping_type => 'BASE_PATH',
        p_url_mapping_pattern => 'academico',
        p_auto_rest_auth => FALSE
    );
    
    DBMS_OUTPUT.PUT_LINE('✓ ORDS habilitado para esquema ACADEMICO');
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('Esto puede significar que:');
        DBMS_OUTPUT.PUT_LINE('1. ORDS no está instalado en la base de datos');
        DBMS_OUTPUT.PUT_LINE('2. Estás usando ORDS standalone (no requiere esto)');
END;
/

PROMPT ''
PROMPT 'Verificando habilitación...'

SELECT schema_name, url_mapping_pattern 
FROM DBA_ORDS_SCHEMAS
WHERE schema_name = 'ACADEMICO';

PROMPT ''
PROMPT '✓ Proceso completado'
PROMPT ''

EXIT;
