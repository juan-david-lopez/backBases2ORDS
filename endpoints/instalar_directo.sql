-- =====================================================
-- INSTALACIÓN DIRECTA SIN PERMISOS ESPECIALES
-- Para Oracle 21c XE con ORDS standalone
-- =====================================================

SET SERVEROUTPUT ON
SET ECHO ON

PROMPT ''
PROMPT '========================================='
PROMPT 'CREANDO MÓDULOS ORDS DIRECTAMENTE'
PROMPT '========================================='
PROMPT ''

-- =====================================================
-- 1. MÓDULO DE AUTENTICACIÓN
-- =====================================================

PROMPT 'Creando módulo AUTH...'

BEGIN
    ORDS.DEFINE_MODULE(
        p_module_name => 'auth',
        p_base_path => '/auth/',
        p_items_per_page => 0,
        p_status => 'PUBLISHED',
        p_comments => 'API de autenticación'
    );
    DBMS_OUTPUT.PUT_LINE('✓ Módulo auth creado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Crear endpoint de login
BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'auth',
        p_pattern => 'login'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'auth',
        p_pattern => 'login',
        p_method => 'POST',
        p_source_type => ORDS.source_type_plsql,
        p_source => 'BEGIN
            :status := 200;
            :message := ''Login endpoint funcionando'';
            :token := ''test_token_'' || TO_CHAR(SYSTIMESTAMP, ''YYYYMMDDHH24MISS'');
        END;'
    );
    
    DBMS_OUTPUT.PUT_LINE('✓ POST /auth/login creado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error en login: ' || SQLERRM);
END;
/

-- =====================================================
-- 2. MÓDULO DE MATRÍCULAS
-- =====================================================

PROMPT ''
PROMPT 'Creando módulo MATRICULAS...'

BEGIN
    ORDS.DEFINE_MODULE(
        p_module_name => 'matriculas',
        p_base_path => '/matriculas/',
        p_items_per_page => 25,
        p_status => 'PUBLISHED',
        p_comments => 'API de matrículas'
    );
    DBMS_OUTPUT.PUT_LINE('✓ Módulo matriculas creado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Endpoint simple de prueba
BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'matriculas',
        p_pattern => 'test'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'matriculas',
        p_pattern => 'test',
        p_method => 'GET',
        p_source_type => 'json/collection',
        p_source => 'SELECT ''Matriculas API funcionando'' as mensaje FROM DUAL'
    );
    
    DBMS_OUTPUT.PUT_LINE('✓ GET /matriculas/test creado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- =====================================================
-- 3. MÓDULO DE CALIFICACIONES
-- =====================================================

PROMPT ''
PROMPT 'Creando módulo CALIFICACIONES...'

BEGIN
    ORDS.DEFINE_MODULE(
        p_module_name => 'calificaciones',
        p_base_path => '/calificaciones/',
        p_items_per_page => 25,
        p_status => 'PUBLISHED',
        p_comments => 'API de calificaciones'
    );
    DBMS_OUTPUT.PUT_LINE('✓ Módulo calificaciones creado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Endpoint simple de prueba
BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'calificaciones',
        p_pattern => 'test'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'calificaciones',
        p_pattern => 'test',
        p_method => 'GET',
        p_source_type => 'json/collection',
        p_source => 'SELECT ''Calificaciones API funcionando'' as mensaje FROM DUAL'
    );
    
    DBMS_OUTPUT.PUT_LINE('✓ GET /calificaciones/test creado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

COMMIT;

-- =====================================================
-- VERIFICACIÓN
-- =====================================================

PROMPT ''
PROMPT '========================================='
PROMPT 'VERIFICACIÓN DE MÓDULOS'
PROMPT '========================================='
PROMPT ''

SELECT name as "MÓDULO", uri_prefix as "PATH", status as "ESTADO"
FROM USER_ORDS_MODULES
ORDER BY name;

PROMPT ''
PROMPT '✓ Instalación completada'
PROMPT ''
PROMPT 'Espera 5 segundos y prueba:'
PROMPT 'http://localhost:8080/ords/academico/metadata-catalog/'
PROMPT ''

EXIT;
