-- =====================================================
-- DIAGNÓSTICO RÁPIDO - Verificar estado de ORDS
-- =====================================================

SET SERVEROUTPUT ON
SET LINESIZE 200
SET PAGESIZE 100

PROMPT ''
PROMPT '========================================='
PROMPT 'DIAGNÓSTICO DE MÓDULOS ORDS'
PROMPT '========================================='
PROMPT ''

-- Verificar si existen las vistas de ORDS
PROMPT 'Verificando acceso a USER_ORDS_MODULES...'
SELECT COUNT(*) as "TOTAL_MODULOS" FROM USER_ORDS_MODULES;

PROMPT ''
PROMPT 'Módulos registrados:'
SELECT name, uri_prefix, status FROM USER_ORDS_MODULES ORDER BY name;

PROMPT ''
PROMPT 'Templates registrados:'
SELECT COUNT(*) as "TOTAL_TEMPLATES" FROM USER_ORDS_TEMPLATES;

PROMPT ''
PROMPT 'Handlers registrados:'
SELECT COUNT(*) as "TOTAL_HANDLERS" FROM USER_ORDS_HANDLERS;

PROMPT ''
PROMPT '========================================='
PROMPT 'VERIFICANDO PERMISOS'
PROMPT '========================================='
PROMPT ''

-- Verificar permisos en ORDS_METADATA
SELECT 
    privilege,
    grantee
FROM USER_TAB_PRIVS
WHERE table_name = 'ORDS'
AND owner = 'ORDS_METADATA';

PROMPT ''
PROMPT '========================================='
PROMPT 'INTENTANDO CREAR MÓDULO DE PRUEBA'
PROMPT '========================================='
PROMPT ''

-- Intentar crear un módulo simple para probar permisos
BEGIN
    ORDS.DEFINE_MODULE(
        p_module_name => 'test_diagnostico',
        p_base_path => 'test/',
        p_items_per_page => 0
    );
    DBMS_OUTPUT.PUT_LINE('✓ Módulo de prueba creado exitosamente');
    DBMS_OUTPUT.PUT_LINE('✓ Los permisos están correctos');
    
    -- Eliminar el módulo de prueba
    ORDS.DELETE_MODULE(p_module_name => 'test_diagnostico');
    DBMS_OUTPUT.PUT_LINE('✓ Módulo de prueba eliminado');
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('Solución sugerida:');
        DBMS_OUTPUT.PUT_LINE('  Conectar como SYS y ejecutar:');
        DBMS_OUTPUT.PUT_LINE('  GRANT INHERIT PRIVILEGES ON USER ORDS_METADATA TO ACADEMICO;');
        DBMS_OUTPUT.PUT_LINE('  GRANT EXECUTE ON ORDS_METADATA.ORDS TO ACADEMICO;');
        ROLLBACK;
END;
/

PROMPT ''
PROMPT 'Diagnóstico completado.'
PROMPT ''

EXIT;
