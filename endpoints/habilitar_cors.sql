-- =====================================================
-- HABILITAR CORS EN ORDS PARA DESARROLLO
-- Ejecutar como ACADEMICO
-- =====================================================

SET SERVEROUTPUT ON;

-- Habilitar CORS en el módulo de autenticación
BEGIN
    ORDS.DEFINE_MODULE(
        p_module_name => 'auth',
        p_base_path => '/auth/',
        p_items_per_page => 0,
        p_status => 'PUBLISHED',
        p_comments => 'API de autenticación'
    );
    
    -- Configurar CORS para el módulo
    ORDS.DEFINE_PRIVILEGE(
        p_privilege_name => 'auth.cors',
        p_roles => NULL,
        p_patterns => '/auth/*',
        p_label => 'CORS for Auth',
        p_description => 'Enable CORS for authentication endpoints'
    );
    
    DBMS_OUTPUT.PUT_LINE('CORS configurado para módulo auth');
    COMMIT;
END;
/

-- Verificar configuración
SELECT name, uri_prefix, status 
FROM USER_ORDS_MODULES 
WHERE name = 'auth';

EXIT;
