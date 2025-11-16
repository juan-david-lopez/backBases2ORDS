SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 200;
SET PAGESIZE 1000;

PROMPT ============================================================
PROMPT VERIFICACIÓN COMPLETA DE REQUISITOS DEL SISTEMA
PROMPT ============================================================

-- ============================================================
-- 1. VERIFICACIÓN DE TABLAS PRINCIPALES
-- ============================================================
PROMPT 
PROMPT ============================================================
PROMPT 1. TABLAS PRINCIPALES DEL SISTEMA
PROMPT ============================================================

SELECT table_name, num_rows
FROM USER_TABLES
WHERE table_name IN (
    'PROGRAMA', 'ESTUDIANTE', 'ASIGNATURA', 'DOCENTE', 'GRUPO',
    'PERIODO_ACADEMICO', 'MATRICULA', 'DETALLE_MATRICULA',
    'NOTA_DEFINITIVA', 'CALIFICACION_PARCIAL', 'PRERREQUISITO',
    'REGLA_EVALUACION', 'HISTORIAL_ACADEMICO', 'RIESGO_ACADEMICO',
    'VENTANA_CALENDARIO', 'SALON', 'HORARIO_GRUPO', 'FORMACION_ACADEMICA_DOCENTE'
)
ORDER BY table_name;

-- ============================================================
-- 2. TRIGGERS IMPLEMENTADOS
-- ============================================================
PROMPT 
PROMPT ============================================================
PROMPT 2. TRIGGERS IMPLEMENTADOS (Por Categoría)
PROMPT ============================================================

PROMPT 
PROMPT 2.1 TRIGGERS DE MATRÍCULA Y CARGA ACADÉMICA:
SELECT trigger_name, status, triggering_event, table_name
FROM USER_TRIGGERS
WHERE trigger_name IN (
    'TRG_VALIDAR_MATRICULA',
    'TRG_VALIDAR_CREDITOS_RIESGO',
    'TRG_VALIDAR_VENTANA_CALENDARIO',
    'TRG_VALIDAR_CHOQUE_HORARIO',
    'TRG_VALIDAR_CUPO_GRUPO',
    'TRG_VALIDAR_CANCELACION_MATERIA'
)
ORDER BY trigger_name;

PROMPT 
PROMPT 2.2 TRIGGERS DE PRERREQUISITOS:
SELECT trigger_name, status, triggering_event, table_name
FROM USER_TRIGGERS
WHERE trigger_name IN (
    'TRG_VALIDAR_PRERREQUISITOS',
    'TRG_VALIDAR_TRABAJO_GRADO'
)
ORDER BY trigger_name;

PROMPT 
PROMPT 2.3 TRIGGERS DE CALIFICACIONES:
SELECT trigger_name, status, triggering_event, table_name
FROM USER_TRIGGERS
WHERE trigger_name IN (
    'TRG_VALIDAR_REGLA_EVALUACION',
    'TRG_VALIDAR_NOTA_PARCIAL',
    'TRG_CALCULAR_NOTA_DEFINITIVA',
    'TRG_ACTUALIZAR_HISTORIAL',
    'TRG_BLOQUEAR_NOTAS_CERRADAS'
)
ORDER BY trigger_name;

PROMPT 
PROMPT 2.4 TRIGGERS DE RIESGO ACADÉMICO:
SELECT trigger_name, status, triggering_event, table_name
FROM USER_TRIGGERS
WHERE trigger_name IN (
    'TRG_CLASIFICAR_RIESGO',
    'TRG_ALERTAS_TEMPRANAS'
)
ORDER BY trigger_name;

PROMPT 
PROMPT 2.5 TRIGGERS DE GESTIÓN DOCENTE:
SELECT trigger_name, status, triggering_event, table_name
FROM USER_TRIGGERS
WHERE trigger_name IN (
    'TRG_VALIDAR_CARGA_DOCENTE',
    'TRG_VALIDAR_HORARIO_DOCENTE'
)
ORDER BY trigger_name;

PROMPT 
PROMPT 2.6 TRIGGERS DE AUDITORÍA:
SELECT trigger_name, status, triggering_event, table_name
FROM USER_TRIGGERS
WHERE trigger_name IN (
    'TRG_AUDITORIA_MATRICULA',
    'TRG_AUDITORIA_NOTAS',
    'TRG_AUDITORIA_CIERRE'
)
ORDER BY trigger_name;

-- ============================================================
-- 3. PROCEDIMIENTOS ALMACENADOS
-- ============================================================
PROMPT 
PROMPT ============================================================
PROMPT 3. PROCEDIMIENTOS ALMACENADOS IMPLEMENTADOS
PROMPT ============================================================

SELECT object_name, object_type, status
FROM USER_OBJECTS
WHERE object_type IN ('PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY')
AND object_name LIKE '%PKG%'
ORDER BY object_type, object_name;

-- ============================================================
-- 4. FUNCIONES DE VALIDACIÓN
-- ============================================================
PROMPT 
PROMPT ============================================================
PROMPT 4. FUNCIONES DE VALIDACIÓN
PROMPT ============================================================

SELECT object_name, status
FROM USER_OBJECTS
WHERE object_type = 'FUNCTION'
AND object_name IN (
    'FN_VALIDAR_PRERREQUISITOS',
    'FN_VALIDAR_CREDITOS_TRABAJO_GRADO',
    'FN_CALCULAR_RIESGO_ACADEMICO',
    'FN_VERIFICAR_VENTANA_ACTIVA',
    'FN_VALIDAR_CHOQUE_HORARIO',
    'FN_CONTAR_CANCELACIONES',
    'FN_CALCULAR_NOTA_FINAL'
)
ORDER BY object_name;

-- ============================================================
-- 5. RESTRICCIONES Y CONSTRAINTS
-- ============================================================
PROMPT 
PROMPT ============================================================
PROMPT 5. CONSTRAINTS IMPLEMENTADOS (Por Tipo)
PROMPT ============================================================

SELECT constraint_type, COUNT(*) as total
FROM USER_CONSTRAINTS
WHERE table_name IN (
    'PROGRAMA', 'ESTUDIANTE', 'ASIGNATURA', 'DOCENTE', 'GRUPO',
    'PERIODO_ACADEMICO', 'MATRICULA', 'DETALLE_MATRICULA',
    'NOTA_DEFINITIVA', 'CALIFICACION_PARCIAL', 'PRERREQUISITO',
    'REGLA_EVALUACION', 'HISTORIAL_ACADEMICO', 'RIESGO_ACADEMICO',
    'VENTANA_CALENDARIO', 'SALON', 'HORARIO_GRUPO'
)
GROUP BY constraint_type
ORDER BY constraint_type;

-- ============================================================
-- 6. VERIFICACIÓN DE DATOS DE PRUEBA
-- ============================================================
PROMPT 
PROMPT ============================================================
PROMPT 6. DATOS DE PRUEBA CARGADOS
PROMPT ============================================================

SELECT 'PROGRAMAS' as tabla, COUNT(*) as registros FROM PROGRAMA
UNION ALL
SELECT 'ESTUDIANTES', COUNT(*) FROM ESTUDIANTE
UNION ALL
SELECT 'ASIGNATURAS', COUNT(*) FROM ASIGNATURA
UNION ALL
SELECT 'DOCENTES', COUNT(*) FROM DOCENTE
UNION ALL
SELECT 'GRUPOS', COUNT(*) FROM GRUPO
UNION ALL
SELECT 'PERIODOS', COUNT(*) FROM PERIODO_ACADEMICO
UNION ALL
SELECT 'MATRÍCULAS', COUNT(*) FROM MATRICULA
UNION ALL
SELECT 'DETALLES MATRÍCULA', COUNT(*) FROM DETALLE_MATRICULA
UNION ALL
SELECT 'PRERREQUISITOS', COUNT(*) FROM PRERREQUISITO
UNION ALL
SELECT 'NOTAS DEFINITIVAS', COUNT(*) FROM NOTA_DEFINITIVA
UNION ALL
SELECT 'VENTANAS CALENDARIO', COUNT(*) FROM VENTANA_CALENDARIO
UNION ALL
SELECT 'SALONES', COUNT(*) FROM SALON
UNION ALL
SELECT 'HORARIOS GRUPO', COUNT(*) FROM HORARIO_GRUPO
UNION ALL
SELECT 'FORMACIÓN DOCENTE', COUNT(*) FROM FORMACION_ACADEMICA_DOCENTE;

-- ============================================================
-- 7. VERIFICACIÓN DE REGLAS DE NEGOCIO
-- ============================================================
PROMPT 
PROMPT ============================================================
PROMPT 7. VERIFICACIÓN DE REGLAS DE NEGOCIO IMPLEMENTADAS
PROMPT ============================================================

PROMPT 
PROMPT 7.1 Validación de límites de créditos por riesgo:
DECLARE
    v_existe NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_existe
    FROM USER_TRIGGERS
    WHERE trigger_name = 'TRG_VALIDAR_CREDITOS_RIESGO';
    
    IF v_existe > 0 THEN
        DBMS_OUTPUT.PUT_LINE('✓ IMPLEMENTADO: Trigger de validación de créditos por riesgo');
    ELSE
        DBMS_OUTPUT.PUT_LINE('✗ FALTA: Trigger de validación de créditos por riesgo');
    END IF;
END;
/

PROMPT 
PROMPT 7.2 Inscripción automática primer semestre:
DECLARE
    v_existe NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_existe
    FROM USER_OBJECTS
    WHERE object_name = 'PKG_MATRICULA'
    AND object_type = 'PACKAGE BODY';
    
    IF v_existe > 0 THEN
        DBMS_OUTPUT.PUT_LINE('✓ IMPLEMENTADO: Paquete de matrícula con inscripción automática');
    ELSE
        DBMS_OUTPUT.PUT_LINE('✗ FALTA: Paquete de matrícula');
    END IF;
END;
/

PROMPT 
PROMPT 7.3 Registro obligatorio de asignaturas perdidas:
DECLARE
    v_existe NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_existe
    FROM USER_TRIGGERS
    WHERE trigger_name LIKE '%PERDIDAS%' OR trigger_name LIKE '%REPROBADAS%';
    
    IF v_existe > 0 THEN
        DBMS_OUTPUT.PUT_LINE('✓ IMPLEMENTADO: Lógica de materias perdidas');
    ELSE
        DBMS_OUTPUT.PUT_LINE('⚠ REVISAR: Lógica de materias perdidas (puede estar en paquete)');
    END IF;
END;
/

PROMPT 
PROMPT 7.4 Validación de choques de horario:
DECLARE
    v_existe NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_existe
    FROM USER_TRIGGERS
    WHERE trigger_name = 'TRG_VALIDAR_CHOQUE_HORARIO';
    
    IF v_existe > 0 THEN
        DBMS_OUTPUT.PUT_LINE('✓ IMPLEMENTADO: Validación de choques de horario');
    ELSE
        DBMS_OUTPUT.PUT_LINE('✗ FALTA: Validación de choques de horario');
    END IF;
END;
/

PROMPT 
PROMPT 7.5 Validación de ventanas de calendario:
DECLARE
    v_existe NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_existe
    FROM USER_TRIGGERS
    WHERE trigger_name = 'TRG_VALIDAR_VENTANA_CALENDARIO';
    
    IF v_existe > 0 THEN
        DBMS_OUTPUT.PUT_LINE('✓ IMPLEMENTADO: Validación de ventanas de calendario');
    ELSE
        DBMS_OUTPUT.PUT_LINE('✗ FALTA: Validación de ventanas de calendario');
    END IF;
END;
/

PROMPT 
PROMPT 7.6 Límite de cancelación de materias:
DECLARE
    v_existe NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_existe
    FROM USER_TRIGGERS
    WHERE trigger_name = 'TRG_VALIDAR_CANCELACION_MATERIA';
    
    IF v_existe > 0 THEN
        DBMS_OUTPUT.PUT_LINE('✓ IMPLEMENTADO: Validación de cancelación de materias');
    ELSE
        DBMS_OUTPUT.PUT_LINE('✗ FALTA: Validación de cancelación de materias');
    END IF;
END;
/

PROMPT 
PROMPT 7.7 Verificación de prerrequisitos:
DECLARE
    v_existe NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_existe
    FROM USER_TRIGGERS
    WHERE trigger_name = 'TRG_VALIDAR_PRERREQUISITOS';
    
    IF v_existe > 0 THEN
        DBMS_OUTPUT.PUT_LINE('✓ IMPLEMENTADO: Validación de prerrequisitos');
    ELSE
        DBMS_OUTPUT.PUT_LINE('✗ FALTA: Validación de prerrequisitos');
    END IF;
END;
/

PROMPT 
PROMPT 7.8 Trabajo de fin de carrera (80% créditos):
DECLARE
    v_existe NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_existe
    FROM USER_TRIGGERS
    WHERE trigger_name = 'TRG_VALIDAR_TRABAJO_GRADO';
    
    IF v_existe > 0 THEN
        DBMS_OUTPUT.PUT_LINE('✓ IMPLEMENTADO: Validación de trabajo de grado');
    ELSE
        DBMS_OUTPUT.PUT_LINE('✗ FALTA: Validación de trabajo de grado');
    END IF;
END;
/

PROMPT 
PROMPT 7.9 Regla de evaluación suma 100%:
DECLARE
    v_existe NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_existe
    FROM USER_TRIGGERS
    WHERE trigger_name = 'TRG_VALIDAR_REGLA_EVALUACION';
    
    IF v_existe > 0 THEN
        DBMS_OUTPUT.PUT_LINE('✓ IMPLEMENTADO: Validación regla evaluación 100%');
    ELSE
        DBMS_OUTPUT.PUT_LINE('✗ FALTA: Validación regla evaluación 100%');
    END IF;
END;
/

PROMPT 
PROMPT 7.10 Control de carga docente (8-16 horas):
DECLARE
    v_existe NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_existe
    FROM USER_TRIGGERS
    WHERE trigger_name = 'TRG_VALIDAR_CARGA_DOCENTE';
    
    IF v_existe > 0 THEN
        DBMS_OUTPUT.PUT_LINE('✓ IMPLEMENTADO: Control de carga docente');
    ELSE
        DBMS_OUTPUT.PUT_LINE('✗ FALTA: Control de carga docente');
    END IF;
END;
/

-- ============================================================
-- 8. ENDPOINTS ORDS
-- ============================================================
PROMPT 
PROMPT ============================================================
PROMPT 8. ENDPOINTS ORDS REGISTRADOS
PROMPT ============================================================

SELECT 
    m.name as modulo,
    COUNT(DISTINCT t.id) as templates,
    COUNT(h.id) as handlers
FROM USER_ORDS_MODULES m
LEFT JOIN USER_ORDS_TEMPLATES t ON m.id = t.module_id
LEFT JOIN USER_ORDS_HANDLERS h ON t.id = h.template_id
GROUP BY m.name
ORDER BY m.name;

PROMPT 
PROMPT ============================================================
PROMPT VERIFICACIÓN COMPLETADA
PROMPT ============================================================

EXIT;
