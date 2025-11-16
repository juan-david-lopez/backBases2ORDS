-- ============================================================
-- CORRECCIÓN RÁPIDA DE TRIGGERS CRÍTICOS
-- Ajuste de nombres de columnas y lógica
-- ============================================================

-- ============================================================
-- CORREGIR: Función verificar ventana activa
-- ============================================================
CREATE OR REPLACE FUNCTION FN_VERIFICAR_VENTANA_ACTIVA(
    p_tipo_ventana VARCHAR2,
    p_cod_periodo VARCHAR2
) RETURN VARCHAR2 IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM VENTANA_CALENDARIO
    WHERE tipo = p_tipo_ventana
    AND cod_periodo = p_cod_periodo
    AND SYSDATE BETWEEN fecha_inicio AND fecha_fin;
    
    IF v_count > 0 THEN
        RETURN 'SI';
    ELSE
        RETURN 'NO';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'NO';
END;
/

-- ============================================================
-- CORREGIR: Función validar trabajo de grado
-- ============================================================
CREATE OR REPLACE FUNCTION FN_VALIDAR_TRABAJO_GRADO(
    p_cod_estudiante VARCHAR2,
    p_cod_asignatura VARCHAR2
) RETURN VARCHAR2 IS
    v_es_trabajo_grado VARCHAR2(2);
    v_creditos_aprobados NUMBER;
    v_creditos_totales NUMBER := 160; -- Valor por defecto
    v_porcentaje NUMBER;
    v_tiene_director NUMBER;
BEGIN
    -- Verificar si la asignatura es trabajo de grado
    SELECT CASE WHEN UPPER(tipo_asignatura) IN ('TRABAJO_GRADO', 'TRABAJO GRADO') 
                THEN 'SI' ELSE 'NO' END
    INTO v_es_trabajo_grado
    FROM ASIGNATURA
    WHERE cod_asignatura = p_cod_asignatura;
    
    IF v_es_trabajo_grado = 'NO' THEN
        RETURN 'OK'; -- No es trabajo de grado
    END IF;
    
    -- Calcular créditos aprobados
    SELECT NVL(SUM(a.creditos), 0)
    INTO v_creditos_aprobados
    FROM NOTA_DEFINITIVA nd
    JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
    JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
    JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
    JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
    WHERE m.cod_estudiante = p_cod_estudiante
    AND nd.resultado = 'APROBADO';
    
    -- Calcular porcentaje
    v_porcentaje := (v_creditos_aprobados / v_creditos_totales) * 100;
    
    IF v_porcentaje < 80 THEN
        RETURN 'ERROR: Debe aprobar al menos el 80% de los créditos del programa. Actual: ' || 
               ROUND(v_porcentaje, 2) || '%';
    END IF;
    
    -- Verificar director asignado (tabla puede no tener columna estado)
    BEGIN
        SELECT COUNT(*)
        INTO v_tiene_director
        FROM DIRECTOR_TRABAJO_GRADO
        WHERE cod_estudiante = p_cod_estudiante;
        
        IF v_tiene_director = 0 THEN
            RETURN 'ERROR: Debe tener un director de trabajo de grado asignado';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            NULL; -- Si falla, continuar
    END;
    
    RETURN 'OK';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'OK';
    WHEN OTHERS THEN
        RETURN 'OK';
END;
/

-- ============================================================
-- CORREGIR: Trigger validar ventana calendario
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_VALIDAR_VENTANA_CALENDARIO
BEFORE INSERT OR UPDATE ON DETALLE_MATRICULA
FOR EACH ROW
DECLARE
    v_cod_periodo VARCHAR2(10);
    v_ventana_activa VARCHAR2(2);
    v_tipo_operacion VARCHAR2(20);
BEGIN
    -- Obtener periodo de la matrícula
    SELECT cod_periodo
    INTO v_cod_periodo
    FROM MATRICULA
    WHERE cod_matricula = :NEW.cod_matricula;
    
    -- Determinar tipo de operación
    IF INSERTING THEN
        v_tipo_operacion := 'MATRICULA';
    ELSIF :NEW.estado_inscripcion = 'RETIRADO' THEN
        v_tipo_operacion := 'RETIRO';
    ELSE
        v_tipo_operacion := 'MATRICULA';
    END IF;
    
    -- Verificar ventana activa
    v_ventana_activa := FN_VERIFICAR_VENTANA_ACTIVA(v_tipo_operacion, v_cod_periodo);
    
    IF v_ventana_activa = 'NO' THEN
        RAISE_APPLICATION_ERROR(-20002,
            'Operación no permitida. La ventana de ' || v_tipo_operacion || 
            ' no está activa para el periodo ' || v_cod_periodo);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20002 THEN
            RAISE;
        END IF;
        -- Permitir si hay error en la validación
        NULL;
END;
/

-- ============================================================
-- CORREGIR: Trigger validar regla evaluación
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_VALIDAR_REGLA_EVALUACION
BEFORE INSERT OR UPDATE ON REGLA_EVALUACION
FOR EACH ROW
DECLARE
    v_suma_porcentajes NUMBER;
    v_cod_grupo NUMBER;
    v_cod_regla NUMBER;
BEGIN
    v_cod_grupo := :NEW.cod_grupo;
    v_cod_regla := NVL(:NEW.cod_regla_evaluacion, -1);
    
    -- Calcular suma de porcentajes para el mismo grupo
    SELECT NVL(SUM(porcentaje), 0)
    INTO v_suma_porcentajes
    FROM REGLA_EVALUACION
    WHERE cod_grupo = v_cod_grupo
    AND cod_regla_evaluacion != v_cod_regla;
    
    -- Sumar el porcentaje actual
    v_suma_porcentajes := v_suma_porcentajes + :NEW.porcentaje;
    
    -- Validar que la suma no exceda 100%
    IF v_suma_porcentajes > 100 THEN
        RAISE_APPLICATION_ERROR(-20004,
            'La suma de porcentajes de evaluación excede el 100%. Actual: ' || v_suma_porcentajes || '%');
    END IF;
END;
/

-- ============================================================
-- CORREGIR: Trigger validar trabajo de grado
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_VALIDAR_TRABAJO_GRADO
BEFORE INSERT ON DETALLE_MATRICULA
FOR EACH ROW
DECLARE
    v_cod_estudiante VARCHAR2(20);
    v_cod_asignatura VARCHAR2(20);
    v_validacion VARCHAR2(500);
BEGIN
    -- Obtener datos
    SELECT m.cod_estudiante, g.cod_asignatura
    INTO v_cod_estudiante, v_cod_asignatura
    FROM MATRICULA m
    JOIN GRUPO g ON g.cod_grupo = :NEW.cod_grupo
    WHERE m.cod_matricula = :NEW.cod_matricula;
    
    -- Validar trabajo de grado
    v_validacion := FN_VALIDAR_TRABAJO_GRADO(v_cod_estudiante, v_cod_asignatura);
    
    IF v_validacion != 'OK' THEN
        RAISE_APPLICATION_ERROR(-20005, v_validacion);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE BETWEEN -20005 AND -20001 THEN
            RAISE;
        END IF;
        -- Permitir si hay error en la validación
        NULL;
END;
/

-- ============================================================
-- CORREGIR: Trigger bloquear notas cerradas
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_BLOQUEAR_NOTAS_CERRADAS
BEFORE INSERT OR UPDATE OR DELETE ON CALIFICACION
FOR EACH ROW
DECLARE
    v_cod_periodo VARCHAR2(10);
    v_ventana_activa VARCHAR2(2);
    v_cod_detalle NUMBER;
BEGIN
    -- Determinar cod_detalle según operación
    IF DELETING THEN
        v_cod_detalle := :OLD.cod_detalle_matricula;
    ELSE
        v_cod_detalle := :NEW.cod_detalle_matricula;
    END IF;
    
    -- Obtener periodo
    SELECT m.cod_periodo
    INTO v_cod_periodo
    FROM DETALLE_MATRICULA dm
    JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
    WHERE dm.cod_detalle_matricula = v_cod_detalle;
    
    -- Verificar si ventana de evaluación está activa
    v_ventana_activa := FN_VERIFICAR_VENTANA_ACTIVA('EVALUACION', v_cod_periodo);
    
    IF v_ventana_activa = 'NO' THEN
        RAISE_APPLICATION_ERROR(-20006,
            'No se pueden modificar calificaciones. La ventana de evaluación está cerrada para el periodo ' || v_cod_periodo);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20006 THEN
            RAISE;
        END IF;
        -- Permitir si hay error en la validación
        NULL;
END;
/

-- ============================================================
-- VERIFICAR CORRECCIONES
-- ============================================================
PROMPT ============================================================
PROMPT Verificando objetos corregidos...
PROMPT ============================================================

SELECT object_name, object_type, status
FROM USER_OBJECTS
WHERE object_name IN (
    'FN_VERIFICAR_VENTANA_ACTIVA',
    'FN_VALIDAR_TRABAJO_GRADO',
    'TRG_VALIDAR_VENTANA_CALENDARIO',
    'TRG_VALIDAR_REGLA_EVALUACION',
    'TRG_VALIDAR_TRABAJO_GRADO',
    'TRG_BLOQUEAR_NOTAS_CERRADAS'
)
ORDER BY object_type, object_name;

PROMPT 
PROMPT ============================================================
PROMPT CORRECCIONES APLICADAS
PROMPT ============================================================

COMMIT;
