-- ============================================================
-- CORRECCIÓN BATCH 2 - NOMBRES EXACTOS DE COLUMNAS
-- ============================================================

-- ============================================================
-- CORREGIR: Función calcular carga docente
-- (ASIGNATURA no tiene intensidad_horaria_semanal, calcular con horas)
-- ============================================================
CREATE OR REPLACE FUNCTION FN_CALCULAR_CARGA_DOCENTE(
    p_cod_docente VARCHAR2,
    p_cod_periodo VARCHAR2
) RETURN NUMBER IS
    v_total_horas NUMBER := 0;
BEGIN
    -- Calcular horas de clases asignadas (suma de horas teóricas + prácticas)
    SELECT NVL(SUM(a.horas_teoricas + NVL(a.horas_practicas, 0)), 0)
    INTO v_total_horas
    FROM GRUPO g
    JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
    WHERE g.cod_docente = p_cod_docente
    AND g.cod_periodo = p_cod_periodo
    AND g.estado_grupo = 'ACTIVO';
    
    RETURN v_total_horas;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- ============================================================
-- CORREGIR: Trigger validar carga docente
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_VALIDAR_CARGA_DOCENTE
BEFORE INSERT OR UPDATE OF cod_docente ON GRUPO
FOR EACH ROW
WHEN (NEW.cod_docente IS NOT NULL AND NEW.estado_grupo = 'ACTIVO')
DECLARE
    v_carga_actual NUMBER;
    v_carga_nueva NUMBER;
    v_horas_asignatura NUMBER;
    v_carga_maxima NUMBER := 20; -- Máximo 20 horas semanales por defecto
    v_tipo_vinculacion VARCHAR2(50);
BEGIN
    -- Obtener tipo de vinculación del docente
    BEGIN
        SELECT tipo_vinculacion
        INTO v_tipo_vinculacion
        FROM DOCENTE
        WHERE cod_docente = :NEW.cod_docente;
        
        -- Ajustar carga máxima según tipo de vinculación
        IF v_tipo_vinculacion = 'TIEMPO_COMPLETO' THEN
            v_carga_maxima := 20;
        ELSIF v_tipo_vinculacion = 'MEDIO_TIEMPO' THEN
            v_carga_maxima := 10;
        ELSIF v_tipo_vinculacion = 'CATEDRA' THEN
            v_carga_maxima := 12;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_carga_maxima := 20;
    END;
    
    -- Calcular carga actual
    v_carga_actual := FN_CALCULAR_CARGA_DOCENTE(:NEW.cod_docente, :NEW.cod_periodo);
    
    -- Obtener horas de la nueva asignatura
    SELECT horas_teoricas + NVL(horas_practicas, 0)
    INTO v_horas_asignatura
    FROM ASIGNATURA
    WHERE cod_asignatura = :NEW.cod_asignatura;
    
    -- Calcular carga total si se asigna este grupo
    IF UPDATING AND :OLD.cod_docente = :NEW.cod_docente THEN
        -- Si es el mismo docente, no sumar de nuevo
        v_carga_nueva := v_carga_actual;
    ELSE
        v_carga_nueva := v_carga_actual + v_horas_asignatura;
    END IF;
    
    -- Validar que no exceda el límite
    IF v_carga_nueva > v_carga_maxima THEN
        RAISE_APPLICATION_ERROR(-20009,
            'La carga académica del docente excede el límite. ' ||
            'Actual: ' || v_carga_actual || ' horas. ' ||
            'Nueva: ' || v_carga_nueva || ' horas. ' ||
            'Máximo permitido: ' || v_carga_maxima || ' horas.');
    END IF;
END;
/

-- ============================================================
-- CORREGIR: Trigger alertas tempranas
-- (Columna NOTA en lugar de VALOR_CALIFICACION)
-- (Columna FECHA_OPERACION y SENTENCIA_SQL en lugar de FECHA_HORA y DETALLES)
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_ALERTAS_TEMPRANAS
AFTER INSERT OR UPDATE ON CALIFICACION
FOR EACH ROW
DECLARE
    v_cod_estudiante VARCHAR2(20);
    v_nota_minima NUMBER := 3.0;
    v_count_bajas NUMBER;
    v_periodo_actual VARCHAR2(20);
BEGIN
    -- Obtener estudiante y periodo
    SELECT e.cod_estudiante, m.cod_periodo
    INTO v_cod_estudiante, v_periodo_actual
    FROM DETALLE_MATRICULA dm
    JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
    JOIN ESTUDIANTE e ON m.cod_estudiante = e.cod_estudiante
    WHERE dm.cod_detalle_matricula = :NEW.cod_detalle_matricula;
    
    -- Contar calificaciones bajas en el periodo actual
    SELECT COUNT(*)
    INTO v_count_bajas
    FROM CALIFICACION c
    JOIN DETALLE_MATRICULA dm ON c.cod_detalle_matricula = dm.cod_detalle_matricula
    JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
    WHERE m.cod_estudiante = v_cod_estudiante
    AND m.cod_periodo = v_periodo_actual
    AND c.NOTA < v_nota_minima;
    
    -- Si tiene 2 o más notas bajas, registrar alerta
    IF v_count_bajas >= 2 THEN
        -- Insertar en tabla de auditoría como alerta
        INSERT INTO AUDITORIA (
            cod_auditoria,
            tabla_afectada,
            operacion,
            usuario_bd,
            fecha_operacion,
            sentencia_sql
        ) VALUES (
            SEQ_AUDITORIA.NEXTVAL,
            'CALIFICACION',
            'ALERTA_TEMPRANA',
            USER,
            SYSTIMESTAMP,
            'Estudiante ' || v_cod_estudiante || 
            ' tiene ' || v_count_bajas || 
            ' calificaciones bajas en periodo ' || v_periodo_actual
        );
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- No bloquear la operación principal
END;
/

-- ============================================================
-- VERIFICAR CORRECCIONES
-- ============================================================
PROMPT ============================================================
PROMPT Estado de triggers BATCH 2 corregidos:
PROMPT ============================================================

SELECT object_name, object_type, status
FROM USER_OBJECTS
WHERE object_name IN (
    'FN_CALCULAR_CARGA_DOCENTE',
    'TRG_VALIDAR_CARGA_DOCENTE',
    'TRG_ALERTAS_TEMPRANAS'
)
ORDER BY object_type, object_name;

PROMPT 
PROMPT ============================================================
PROMPT RESUMEN TOTAL DE TODOS LOS TRIGGERS Y FUNCIONES
PROMPT ============================================================

SELECT 
    object_type,
    COUNT(*) as total,
    SUM(CASE WHEN status = 'VALID' THEN 1 ELSE 0 END) as valid,
    SUM(CASE WHEN status = 'INVALID' THEN 1 ELSE 0 END) as invalid
FROM USER_OBJECTS
WHERE (object_name LIKE 'TRG_%' OR object_name LIKE 'FN_%')
AND object_type IN ('TRIGGER', 'FUNCTION')
GROUP BY object_type
ORDER BY object_type;

COMMIT;
EXIT
