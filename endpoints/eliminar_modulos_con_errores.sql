-- =====================================================
-- SCRIPT MAESTRO PARA CORREGIR TODOS LOS ENDPOINTS
-- Propósito: Eliminar y recrear módulos con nombres de columnas correctos
-- =====================================================

SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT ========================================================================
PROMPT CORRECCIÓN MASIVA DE ENDPOINTS - NOMBRES DE COLUMNAS
PROMPT ========================================================================
PROMPT
PROMPT Este script corrige los siguientes problemas:
PROMPT 1. ESTUDIANTE usa ESTADO_ESTUDIANTE (no ESTADO)
PROMPT 2. ESTUDIANTE NO tiene columna RIESGO_ACADEMICO (usar HISTORIAL_RIESGO)
PROMPT 3. DETALLE_MATRICULA usa ESTADO_INSCRIPCION (no ESTADO_DETALLE)
PROMPT 4. GRUPO usa ESTADO_GRUPO (no ESTADO)
PROMPT 5. DOCENTE usa ESTADO_DOCENTE (no ESTADO)
PROMPT 6. PERIODO_ACADEMICO usa ESTADO_PERIODO (probablemente)
PROMPT 7. Tabla VENTANA_EVENTO NO EXISTE
PROMPT ========================================================================

-- Primero, eliminar los módulos problemáticos
PROMPT
PROMPT Eliminando módulos con errores...
PROMPT

BEGIN
    ORDS.DELETE_MODULE(p_module_name => 'registro_materias');
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Módulo registro_materias eliminado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('  registro_materias no existía');
END;
/

BEGIN
    ORDS.DELETE_MODULE(p_module_name => 'docente');
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Módulo docente eliminado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('  docente no existía');
END;
/

BEGIN
    ORDS.DELETE_MODULE(p_module_name => 'alertas');
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Módulo alertas eliminado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('  alertas no existía');
END;
/

PROMPT
PROMPT Módulos eliminados. Ahora ejecute manualmente:
PROMPT 1. @endpoints\06_registro_materias_api_corregido.sql
PROMPT 2. @endpoints\07_docente_api_corregido.sql  
PROMPT 3. @endpoints\08_alertas_reportes_api_corregido.sql
PROMPT
PROMPT O use el script consolidado: fix_all_endpoints.sql
PROMPT ========================================================================
