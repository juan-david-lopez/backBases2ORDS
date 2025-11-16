-- =====================================================
-- SCRIPT MAESTRO - CREAR TODOS LOS ENDPOINTS
-- Archivo: EJECUTAR_TODOS_ENDPOINTS.sql
-- Propósito: Ejecuta todos los scripts de endpoints en orden
-- Ejecutar como: ACADEMICO
-- =====================================================

SET SERVEROUTPUT ON
SET ECHO ON
SET VERIFY OFF
SET FEEDBACK ON

PROMPT ''
PROMPT '========================================='
PROMPT '    INSTALACIÓN COMPLETA DE ENDPOINTS'
PROMPT '========================================='
PROMPT ''
PROMPT 'Este script creará todos los módulos ORDS:'
PROMPT '  1. Setup y configuración CORS'
PROMPT '  2. API de Estudiantes'
PROMPT '  3. API de Matrículas'
PROMPT '  4. API de Calificaciones'
PROMPT '  5. API de Autenticación'
PROMPT ''
PROMPT 'Iniciando instalación en 3 segundos...'
PROMPT ''

-- =====================================================
-- 1. CONFIGURACIÓN INICIAL Y CORS
-- =====================================================

PROMPT ''
PROMPT '========================================='
PROMPT '1/5 - CONFIGURACIÓN INICIAL Y CORS'
PROMPT '========================================='
PROMPT ''

@@00_ords_setup.sql

-- =====================================================
-- 2. API DE ESTUDIANTES
-- =====================================================

PROMPT ''
PROMPT '========================================='
PROMPT '2/5 - API DE ESTUDIANTES'
PROMPT '========================================='
PROMPT ''

@@01_estudiantes_api.sql

-- =====================================================
-- 3. API DE MATRÍCULAS
-- =====================================================

PROMPT ''
PROMPT '========================================='
PROMPT '3/5 - API DE MATRÍCULAS'
PROMPT '========================================='
PROMPT ''

@@03_matriculas_api.sql

-- =====================================================
-- 4. API DE CALIFICACIONES
-- =====================================================

PROMPT ''
PROMPT '========================================='
PROMPT '4/5 - API DE CALIFICACIONES'
PROMPT '========================================='
PROMPT ''

@@04_calificaciones_api.sql

-- =====================================================
-- 5. API DE AUTENTICACIÓN
-- =====================================================

PROMPT ''
PROMPT '========================================='
PROMPT '5/5 - API DE AUTENTICACIÓN'
PROMPT '========================================='
PROMPT ''

@@05_auth_api.sql

-- =====================================================
-- VERIFICACIÓN FINAL
-- =====================================================

PROMPT ''
PROMPT '========================================='
PROMPT 'VERIFICACIÓN DE MÓDULOS INSTALADOS'
PROMPT '========================================='
PROMPT ''

SELECT 
    name as "MÓDULO",
    uri_prefix as "BASE PATH",
    status as "ESTADO",
    comments as "DESCRIPCIÓN"
FROM USER_ORDS_MODULES
ORDER BY name;

PROMPT ''
PROMPT '========================================='
PROMPT 'RESUMEN DE ENDPOINTS CREADOS'
PROMPT '========================================='
PROMPT ''

SELECT 
    m.name as "MÓDULO",
    COUNT(DISTINCT h.id) as "ENDPOINTS"
FROM USER_ORDS_MODULES m
LEFT JOIN USER_ORDS_TEMPLATES t ON m.id = t.module_id
LEFT JOIN USER_ORDS_HANDLERS h ON t.id = h.template_id
GROUP BY m.name
ORDER BY m.name;

PROMPT ''
PROMPT '========================================='
PROMPT '✓ INSTALACIÓN COMPLETADA'
PROMPT '========================================='
PROMPT ''
PROMPT 'URLs Base:'
PROMPT '  http://localhost:8080/ords/academico/estudiantes/'
PROMPT '  http://localhost:8080/ords/academico/matriculas/'
PROMPT '  http://localhost:8080/ords/academico/calificaciones/'
PROMPT '  http://localhost:8080/ords/academico/auth/'
PROMPT ''
PROMPT 'Catálogo de endpoints:'
PROMPT '  http://localhost:8080/ords/academico/metadata-catalog/'
PROMPT ''
PROMPT 'Próximos pasos:'
PROMPT '  1. Probar endpoints con PowerShell o Postman'
PROMPT '  2. Verificar CORS desde el frontend'
PROMPT '  3. Implementar autenticación en el cliente'
PROMPT ''
