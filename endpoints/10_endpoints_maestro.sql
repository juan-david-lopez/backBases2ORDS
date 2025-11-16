-- =====================================================
-- SCRIPT MAESTRO PARA ENDPOINTS
-- Archivo: 10_endpoints_maestro.sql
-- Propósito: Ejecutar todos los scripts de endpoints en orden
-- Ejecutar como: ACADEMICO
-- =====================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET ECHO ON
SET TIMING ON
SET FEEDBACK ON

PROMPT '========================================='
PROMPT 'INSTALACIÓN DE ENDPOINTS REST CON ORDS'
PROMPT 'Sistema Académico - Oracle Database'
PROMPT '========================================='
PROMPT ''

-- Verificar que estamos como ACADEMICO
DECLARE
    v_user VARCHAR2(30);
BEGIN
    SELECT USER INTO v_user FROM DUAL;
    
    IF v_user != 'ACADEMICO' THEN
        RAISE_APPLICATION_ERROR(-20001, 
            'ERROR: Este script debe ejecutarse como ACADEMICO' || CHR(10) ||
            'Usuario actual: ' || v_user);
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('✓ Usuario actual: ' || v_user);
END;
/

PROMPT ''
PROMPT 'IMPORTANTE: Asegúrese de que ORDS esté instalado y corriendo'
PROMPT 'Si no tiene ORDS, revise: endpoints/README_ORDS.md'
PROMPT ''
PROMPT 'Presione Enter para continuar o Ctrl+C para cancelar...'
-- PAUSE

-- =====================================================
-- PASO 1: CONFIGURACIÓN INICIAL
-- =====================================================

PROMPT ''
PROMPT '========================================='
PROMPT 'PASO 1: CONFIGURACIÓN INICIAL DE ORDS'
PROMPT '========================================='
PROMPT ''

@@endpoints/00_ords_setup.sql

-- =====================================================
-- PASO 2: API DE ESTUDIANTES
-- =====================================================

PROMPT ''
PROMPT '========================================='
PROMPT 'PASO 2: CREANDO API DE ESTUDIANTES'
PROMPT '========================================='
PROMPT ''

@@endpoints/01_estudiantes_api.sql

-- =====================================================
-- PASO 3: API DE MATRÍCULAS
-- =====================================================

PROMPT ''
PROMPT '========================================='
PROMPT 'PASO 3: CREANDO API DE MATRÍCULAS'
PROMPT '========================================='
PROMPT ''

@@endpoints/03_matriculas_api.sql

-- =====================================================
-- PASO 4: API DE CALIFICACIONES
-- =====================================================

PROMPT ''
PROMPT '========================================='
PROMPT 'PASO 4: CREANDO API DE CALIFICACIONES'
PROMPT '========================================='
PROMPT ''

@@endpoints/04_calificaciones_api.sql

-- =====================================================
-- VERIFICACIÓN FINAL
-- =====================================================

PROMPT ''
PROMPT '========================================='
PROMPT 'VERIFICACIÓN DE ENDPOINTS CREADOS'
PROMPT '========================================='
PROMPT ''

-- Listar módulos creados
SELECT 
    name as modulo,
    base_path as ruta_base,
    status as estado,
    items_per_page as items_por_pagina
FROM user_ords_modules
ORDER BY name;

PROMPT ''
PROMPT 'Templates y Handlers creados:'

SELECT 
    m.name as modulo,
    t.uri_template as template,
    COUNT(h.id) as num_handlers
FROM user_ords_modules m
LEFT JOIN user_ords_templates t ON m.id = t.module_id
LEFT JOIN user_ords_handlers h ON t.id = h.template_id
GROUP BY m.name, t.uri_template
ORDER BY m.name, t.uri_template;

-- =====================================================
-- RESUMEN FINAL
-- =====================================================

PROMPT ''
PROMPT '========================================='
PROMPT 'INSTALACIÓN DE ENDPOINTS COMPLETADA'
PROMPT '========================================='
PROMPT ''
PROMPT 'Endpoints REST disponibles en:'
PROMPT '  URL Base: http://localhost:8080/ords/academico/'
PROMPT ''
PROMPT 'Módulos creados:'
PROMPT '  ✓ /estudiantes/     - Gestión de estudiantes'
PROMPT '  ✓ /matriculas/      - Gestión de matrículas'
PROMPT '  ✓ /calificaciones/  - Gestión de calificaciones'
PROMPT ''
PROMPT 'Documentación Swagger:'
PROMPT '  http://localhost:8080/ords/academico/metadata-catalog/'
PROMPT ''
PROMPT 'Para probar los endpoints:'
PROMPT '  1. Asegúrese de que ORDS esté corriendo'
PROMPT '  2. Abra en navegador: http://localhost:8080/ords/academico/estudiantes/'
PROMPT '  3. Use Postman o curl para probar POST/PUT'
PROMPT ''
PROMPT 'Ejemplo con curl:'
PROMPT '  curl http://localhost:8080/ords/academico/estudiantes/'
PROMPT ''
PROMPT 'Guía completa: endpoints/README_ORDS.md'
PROMPT ''
PROMPT '========================================='

SET TIMING OFF
SET ECHO OFF
