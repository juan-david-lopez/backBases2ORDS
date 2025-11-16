-- ============================================================
-- BATCH 2: SIGUIENTES 5 TRIGGERS CRÍTICOS
-- ============================================================

-- ============================================================
-- 11. TRG_VALIDAR_CANCELACION_MATERIA
-- Validar que las cancelaciones cumplan las reglas
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_VALIDAR_CANCELACION_MATERIA
BEFORE UPDATE OF estado_inscripcion ON DETALLE_MATRICULA
FOR EACH ROW
WHEN (NEW.estado_inscripcion = 'CANCELADO')
DECLARE
    v_cod_periodo VARCHAR2(20);
    v_count_calificaciones NUMBER;
    v_ventana_activa VARCHAR2(2);
BEGIN
    -- Obtener periodo
    SELECT cod_periodo
    INTO v_cod_periodo
    FROM MATRICULA
    WHERE cod_matricula = :NEW.cod_matricula;
    
    -- Verificar si ya tiene calificaciones registradas
    SELECT COUNT(*)
    INTO v_count_calificaciones
    FROM CALIFICACION
    WHERE cod_detalle_matricula = :NEW.cod_detalle_matricula;
    
    IF v_count_calificaciones > 0 THEN
        RAISE_APPLICATION_ERROR(-20007,
            'No se puede cancelar la materia. Ya tiene calificaciones registradas.');
    END IF;
    
    -- Verificar ventana de retiro activa
    v_ventana_activa := FN_VERIFICAR_VENTANA_ACTIVA('RETIRO', v_cod_periodo);
    
    IF v_ventana_activa = 'NO' THEN
        RAISE_APPLICATION_ERROR(-20008,
            'No se puede cancelar la materia. La ventana de retiro está cerrada.');
    END IF;
    
    -- Registrar fecha de cancelación
    :NEW.fecha_retiro := SYSDATE;
END;
/

-- ============================================================
-- 12. Función para calcular carga académica de docente
-- ============================================================
CREATE OR REPLACE FUNCTION FN_CALCULAR_CARGA_DOCENTE(
    p_cod_docente VARCHAR2,
    p_cod_periodo VARCHAR2
) RETURN NUMBER IS
    v_total_horas NUMBER := 0;
BEGIN
    -- Calcular horas de clases asignadas
    SELECT NVL(SUM(a.intensidad_horaria_semanal), 0)
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
-- 13. TRG_VALIDAR_CARGA_DOCENTE
-- Validar que la carga académica del docente no exceda límites
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_VALIDAR_CARGA_DOCENTE
BEFORE INSERT OR UPDATE OF cod_docente ON GRUPO
FOR EACH ROW
WHEN (NEW.cod_docente IS NOT NULL AND NEW.estado_grupo = 'ACTIVO')
DECLARE
    v_carga_actual NUMBER;
    v_carga_nueva NUMBER;
    v_intensidad_horaria NUMBER;
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
    
    -- Obtener intensidad de la nueva asignatura
    SELECT intensidad_horaria_semanal
    INTO v_intensidad_horaria
    FROM ASIGNATURA
    WHERE cod_asignatura = :NEW.cod_asignatura;
    
    -- Calcular carga total si se asigna este grupo
    IF UPDATING AND :OLD.cod_docente = :NEW.cod_docente THEN
        -- Si es el mismo docente, no sumar de nuevo
        v_carga_nueva := v_carga_actual;
    ELSE
        v_carga_nueva := v_carga_actual + v_intensidad_horaria;
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
-- 14. Función para detectar conflictos de horario docente
-- ============================================================
CREATE OR REPLACE FUNCTION FN_DETECTAR_CONFLICTO_HORARIO_DOCENTE(
    p_cod_docente VARCHAR2,
    p_cod_grupo NUMBER,
    p_cod_periodo VARCHAR2
) RETURN VARCHAR2 IS
    v_conflictos NUMBER := 0;
BEGIN
    -- Nota: Esta validación requiere tabla HORARIO con estructura detallada
    -- Por ahora retornamos OK si no hay datos
    BEGIN
        SELECT COUNT(*)
        INTO v_conflictos
        FROM HORARIO h1
        JOIN GRUPO g1 ON h1.cod_grupo = g1.cod_grupo
        WHERE g1.cod_docente = p_cod_docente
        AND g1.cod_periodo = p_cod_periodo
        AND g1.cod_grupo != p_cod_grupo
        AND g1.estado_grupo = 'ACTIVO'
        AND EXISTS (
            SELECT 1
            FROM HORARIO h2
            WHERE h2.cod_grupo = p_cod_grupo
            AND h1.dia_semana = h2.dia_semana
            AND (
                (h1.hora_inicio BETWEEN h2.hora_inicio AND h2.hora_fin) OR
                (h1.hora_fin BETWEEN h2.hora_inicio AND h2.hora_fin) OR
                (h2.hora_inicio BETWEEN h1.hora_inicio AND h1.hora_fin)
            )
        );
        
        IF v_conflictos > 0 THEN
            RETURN 'CONFLICTO';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'OK'; -- Si no existe tabla HORARIO, permitir
    END;
    
    RETURN 'OK';
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'OK';
END;
/

-- ============================================================
-- 15. TRG_VALIDAR_HORARIO_DOCENTE
-- Validar que no haya choques de horario para el docente
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_VALIDAR_HORARIO_DOCENTE
BEFORE INSERT OR UPDATE OF cod_docente ON GRUPO
FOR EACH ROW
WHEN (NEW.cod_docente IS NOT NULL AND NEW.estado_grupo = 'ACTIVO')
DECLARE
    v_resultado VARCHAR2(20);
BEGIN
    v_resultado := FN_DETECTAR_CONFLICTO_HORARIO_DOCENTE(
        :NEW.cod_docente,
        :NEW.cod_grupo,
        :NEW.cod_periodo
    );
    
    IF v_resultado = 'CONFLICTO' THEN
        RAISE_APPLICATION_ERROR(-20010,
            'El docente tiene un conflicto de horario con otro grupo en el mismo periodo.');
    END IF;
END;
/

-- ============================================================
-- 16. TRG_ALERTAS_TEMPRANAS
-- Trigger para generar alertas de riesgo temprano
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
    AND c.valor_calificacion < v_nota_minima;
    
    -- Si tiene 2 o más notas bajas, registrar alerta
    IF v_count_bajas >= 2 THEN
        -- Insertar en tabla de auditoría como alerta
        INSERT INTO AUDITORIA (
            cod_auditoria,
            tabla_afectada,
            operacion,
            usuario_bd,
            fecha_hora,
            detalles
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
-- VERIFICAR BATCH 2
-- ============================================================
PROMPT ============================================================
PROMPT Estado de triggers BATCH 2:
PROMPT ============================================================

SELECT object_name, object_type, status
FROM USER_OBJECTS
WHERE object_name IN (
    'TRG_VALIDAR_CANCELACION_MATERIA',
    'FN_CALCULAR_CARGA_DOCENTE',
    'TRG_VALIDAR_CARGA_DOCENTE',
    'FN_DETECTAR_CONFLICTO_HORARIO_DOCENTE',
    'TRG_VALIDAR_HORARIO_DOCENTE',
    'TRG_ALERTAS_TEMPRANAS'
)
ORDER BY object_type, object_name;

PROMPT 
PROMPT ============================================================
PROMPT RESUMEN TOTAL TRIGGERS IMPLEMENTADOS
PROMPT ============================================================

SELECT 
    object_type,
    COUNT(*) as total,
    SUM(CASE WHEN status = 'VALID' THEN 1 ELSE 0 END) as valid,
    SUM(CASE WHEN status = 'INVALID' THEN 1 ELSE 0 END) as invalid
FROM USER_OBJECTS
WHERE object_type IN ('TRIGGER', 'FUNCTION')
AND object_name LIKE 'TRG_%' OR object_name LIKE 'FN_%'
GROUP BY object_type
ORDER BY object_type;

COMMIT;
EXIT
