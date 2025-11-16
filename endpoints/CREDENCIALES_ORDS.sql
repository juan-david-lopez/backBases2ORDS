-- =====================================================
-- CREDENCIALES Y URLS PARA PROBAR ORDS
-- =====================================================

-- =====================================================
-- 1. ENDPOINTS REST (NO REQUIEREN LOGIN)
-- =====================================================

-- Abre directamente en el navegador (GET requests):

http://localhost:8080/ords/academico/estudiantes/
http://localhost:8080/ords/academico/matriculas/periodo/2025-1
http://localhost:8080/ords/academico/calificaciones/estudiante/2025000001

-- Estos endpoints NO requieren autenticación (por defecto)
-- Solo devuelven JSON con los datos

-- =====================================================
-- 2. DOCUMENTACIÓN SWAGGER (NO REQUIERE LOGIN)
-- =====================================================

http://localhost:8080/ords/academico/metadata-catalog/

-- Aquí puedes ver y probar todos los endpoints interactivamente

-- =====================================================
-- 3. SI APARECE PANTALLA DE LOGIN (APEX o SQL Developer Web)
-- =====================================================

-- OPCIÓN A: Oracle APEX
-- URL: http://localhost:8080/ords/apex
-- Workspace: INTERNAL
-- Usuario: ADMIN
-- Contraseña: [La que configuraste en APEX]

-- OPCIÓN B: SQL Developer Web
-- URL: http://localhost:8080/ords/sql-developer
-- Usuario: ACADEMICO
-- Contraseña: Academico123#

-- OPCIÓN C: Para habilitar SQL Developer Web para ACADEMICO:
-- Ejecuta como SYS:

BEGIN
    ORDS.ENABLE_SCHEMA(
        p_enabled             => TRUE,
        p_schema              => 'ACADEMICO',
        p_url_mapping_type    => 'BASE_PATH',
        p_url_mapping_pattern => 'academico',
        p_auto_rest_auth      => FALSE
    );
    
    ORDS_ADMIN.ENABLE_SCHEMA(
        p_enabled => TRUE,
        p_schema => 'ACADEMICO',
        p_url_mapping_type => 'BASE_PATH',
        p_url_mapping_pattern => 'academico'
    );
    
    COMMIT;
END;
/

-- =====================================================
-- 4. PRUEBAS SIN NAVEGADOR (PowerShell)
-- =====================================================

-- Si no puedes acceder por navegador, usa PowerShell:

-- Listar estudiantes:
Invoke-RestMethod -Uri "http://localhost:8080/ords/academico/estudiantes/" -Method Get | ConvertTo-Json

-- Ver estructura de respuesta:
(Invoke-RestMethod -Uri "http://localhost:8080/ords/academico/estudiantes/").items

-- Crear estudiante:
$estudiante = @{
    cod_programa = 1
    tipo_documento = "CC"
    numero_documento = "1234567890"
    nombre_estudiante = "Test"
    apellido_estudiante = "Usuario"
    email = "test@universidad.edu"
    telefono = "3001234567"
    direccion = "Test Address"
    fecha_nacimiento = "2000-01-01"
    genero = "M"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8080/ords/academico/estudiantes/" `
    -Method Post `
    -Body $estudiante `
    -ContentType "application/json"

-- =====================================================
-- 5. VERIFICAR QUE ORDS ESTÉ CORRIENDO
-- =====================================================

-- En PowerShell:
Test-NetConnection -ComputerName localhost -Port 8080

-- O:
netstat -an | findstr "8080"

-- Si no está corriendo:
cd C:\Users\murde\Downloads\ords-25.3.1.289.1312
java -jar ords.war standalone --port 8080

-- =====================================================
-- 6. VERIFICAR ENDPOINTS CREADOS
-- =====================================================

-- Conectar como ACADEMICO:
sqlplus ACADEMICO/Academico123#@localhost:1521/XEPDB1

-- Ver módulos REST:
SELECT name, base_path, status 
FROM user_ords_modules;

-- Resultado esperado:
-- NAME           BASE_PATH            STATUS
-- estudiantes    /estudiantes/        PUBLISHED
-- matriculas     /matriculas/         PUBLISHED
-- calificaciones /calificaciones/     PUBLISHED

-- Ver templates (endpoints):
SELECT 
    m.name as modulo,
    t.uri_template as endpoint
FROM user_ords_modules m
JOIN user_ords_templates t ON m.id = t.module_id
ORDER BY m.name, t.uri_template;

-- =====================================================
-- 7. DESHABILITAR AUTENTICACIÓN (Si te pide login)
-- =====================================================

-- Si los endpoints te piden autenticación, deshabilitala:

BEGIN
    ORDS.DELETE_PRIVILEGE(
        p_name => 'estudiantes.privilege'
    );
    
    ORDS.DELETE_PRIVILEGE(
        p_name => 'matriculas.privilege'
    );
    
    ORDS.DELETE_PRIVILEGE(
        p_name => 'calificaciones.privilege'
    );
    
    COMMIT;
END;
/

-- =====================================================
-- RESUMEN DE URLs ÚTILES
-- =====================================================

-- Endpoints REST (tus APIs):
-- http://localhost:8080/ords/academico/estudiantes/
-- http://localhost:8080/ords/academico/matriculas/
-- http://localhost:8080/ords/academico/calificaciones/

-- Documentación Swagger:
-- http://localhost:8080/ords/academico/metadata-catalog/

-- APEX (si está instalado):
-- http://localhost:8080/ords/apex

-- SQL Developer Web:
-- http://localhost:8080/ords/sql-developer

-- =====================================================

-- Endpoint para login
BEGIN
    ORDS.ENABLE_SCHEMA(
        p_enabled => TRUE,
        p_schema => 'TU_ESQUEMA',
        p_url_mapping_type => 'BASE_PATH',
        p_url_mapping_pattern => 'auth',
        p_auto_rest_auth => FALSE
    );

    ORDS.DEFINE_MODULE(
        p_module_name => 'auth',
        p_base_path => 'auth/',
        p_items_per_page => 25
    );

    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'auth',
        p_pattern => 'login'
    );

    ORDS.DEFINE_HANDLER(
        p_module_name => 'auth',
        p_pattern => 'login',
        p_method => 'POST',
        p_source_type => ORDS.SOURCE_TYPE_PLSQL,
        p_source => q'{
            BEGIN
                -- Lógica para autenticar usuario
                :response := 'Usuario autenticado';
            END;
        }'
    );
END;
/
