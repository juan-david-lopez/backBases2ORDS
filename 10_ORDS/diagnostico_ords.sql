-- =====================================================
-- DIAGNÓSTICO DE ENDPOINTS ORDS
-- Ejecutar como: ACADEMICO
-- =====================================================

SET SERVEROUTPUT ON
SET LINESIZE 200

PROMPT '========================================='
PROMPT 'VERIFICANDO OBJETOS Y PRIVILEGIOS'
PROMPT '========================================='
PROMPT ''

-- 1. Verificar que las tablas existen
PROMPT '1. TABLAS PRINCIPALES:'
SELECT table_name, status 
FROM user_tables 
WHERE table_name IN ('ESTUDIANTE', 'MATRICULA', 'CALIFICACION', 'DETALLE_MATRICULA')
ORDER BY table_name;

PROMPT ''
PROMPT '2. PAQUETES PL/SQL:'
SELECT object_name, status 
FROM user_objects 
WHERE object_type = 'PACKAGE'
AND object_name IN ('PKG_MATRICULA', 'PKG_CALIFICACION', 'PKG_AUDITORIA')
ORDER BY object_name;

PROMPT ''
PROMPT '3. VISTAS:'
SELECT view_name, status 
FROM user_views
ORDER BY view_name;

PROMPT ''
PROMPT '4. PRIVILEGIOS:'
SELECT privilege, grantee 
FROM user_tab_privs 
WHERE grantee = 'ACADEMICO'
ORDER BY privilege;

PROMPT ''
PROMPT '5. OBJETOS INVÁLIDOS:'
SELECT object_name, object_type, status 
FROM user_objects 
WHERE status != 'VALID'
ORDER BY object_type, object_name;

PROMPT ''
PROMPT '========================================='
PROMPT 'VERIFICACIÓN COMPLETADA'
PROMPT '========================================='

EXIT;
