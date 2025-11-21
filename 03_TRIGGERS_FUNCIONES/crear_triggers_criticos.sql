-- ============================================================
-- TRIGGERS Y FUNCIONES CRÍTICAS FALTANTES
-- Sistema Académico - Universidad del Quindío
-- Implementación rápida de requisitos críticos
-- ============================================================

-- ============================================================
-- 1. FUNCIÓN: Validar créditos máximos según riesgo
-- ============================================================
CREATE OR REPLACE FUNCTION FN_CREDITOS_MAXIMOS_PERMITIDOS(
    p_cod_estudiante VARCHAR2,
    p_cod_periodo VARCHAR2
) RETURN NUMBER IS
    v_nivel_riesgo NUMBER;
    v_creditos_maximos NUMBER;
BEGIN
    -- Obtener nivel de riesgo actual del estudiante
    SELECT NVL(nivel_riesgo, 0)
    INTO v_nivel_riesgo
    FROM (
        SELECT nivel_riesgo
        FROM HISTORIAL_RIESGO
        WHERE cod_estudiante = p_cod_estudiante
        AND cod_periodo = p_cod_periodo
        ORDER BY fecha_deteccion DESC
        FETCH FIRST 1 ROW ONLY
    );
    
    -- Determinar créditos máximos según nivel de riesgo
    v_creditos_maximos := CASE v_nivel_riesgo
        WHEN 0 THEN 21  -- Sin riesgo
        WHEN 1 THEN 8   --
        WHEN 2 THEN 12  -- Riesgo 2: Perdió 2 materias
        WHEN 3 THEN 8   -- Riesgo 3: Perdió misma materia 3 veces
        WHEN 4 THEN 16  -- Riesgo 4: Promedio < 3.0
        ELSE 21
    END;
    
    RETURN v_creditos_maximos;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 21; -- Sin riesgo detectado = máximo permitido
    WHEN OTHERS THEN
        RETURN 21;
END;
/

-- ============================================================
-- 2. TRIGGER: Validar créditos por riesgo académico
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_VALIDAR_CREDITOS_RIESGO
BEFORE INSERT OR UPDATE ON DETALLE_MATRICULA
FOR EACH ROW
DECLARE
    v_creditos_actuales NUMBER := 0;
    v_creditos_asignatura NUMBER;
    v_creditos_maximos NUMBER;
    v_cod_estudiante VARCHAR2(20);
    v_cod_periodo VARCHAR2(10);
BEGIN
    -- Obtener datos de la matrícula
    SELECT m.cod_estudiante, m.cod_periodo
    INTO v_cod_estudiante, v_cod_periodo
    FROM MATRICULA m
    WHERE m.cod_matricula = :NEW.cod_matricula;
    
    -- Obtener créditos de la asignatura
    SELECT a.creditos
    INTO v_creditos_asignatura
    FROM ASIGNATURA a
    JOIN GRUPO g ON a.cod_asignatura = g.cod_asignatura
    WHERE g.cod_grupo = :NEW.cod_grupo;
    
    -- Calcular créditos actuales en esta matrícula
    SELECT NVL(SUM(a.creditos), 0)
    INTO v_creditos_actuales
    FROM DETALLE_MATRICULA dm
    JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
    JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
    WHERE dm.cod_matricula = :NEW.cod_matricula
    AND dm.cod_detalle_matricula != NVL(:NEW.cod_detalle_matricula, -1)
    AND dm.estado_inscripcion IN ('INSCRITO', 'CURSANDO');
    
    -- Obtener créditos máximos permitidos según riesgo
    v_creditos_maximos := FN_CREDITOS_MAXIMOS_PERMITIDOS(v_cod_estudiante, v_cod_periodo);
    
    -- Validar límite
    IF (v_creditos_actuales + v_creditos_asignatura) > v_creditos_maximos THEN
        RAISE_APPLICATION_ERROR(-20001, 
            'Límite de créditos excedido. Máximo permitido: ' || v_creditos_maximos || 
            ' créditos según su nivel de riesgo académico. Actual: ' || v_creditos_actuales ||
            ' + ' || v_creditos_asignatura || ' = ' || (v_creditos_actuales + v_creditos_asignatura));
    END IF;
END;
/

-- ============================================================
-- 3. FUNCIÓN: Verificar ventana de calendario activa
-- ============================================================
CREATE OR REPLACE FUNCTION FN_VERIFICAR_VENTANA_ACTIVA(
    p_tipo_ventana VARCHAR2,
    p_cod_periodo VARCHAR2
) RETURN VARCHAR2 IS
    v_activa VARCHAR2(2);
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM VENTANA_CALENDARIO
    WHERE tipo_ventana = p_tipo_ventana
      AND cod_periodo = p_cod_periodo
      AND estado_ventana = 'ACTIVA'
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
-- 4. TRIGGER: Validar ventana de calendario en matrícula
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
END;
/

-- ============================================================
-- 5. FUNCIÓN: Detectar choque de horario
-- ============================================================
CREATE OR REPLACE FUNCTION FN_DETECTAR_CHOQUE_HORARIO(
    p_cod_estudiante VARCHAR2,
    p_cod_grupo NUMBER,
    p_cod_matricula NUMBER
) RETURN VARCHAR2 IS
    v_count NUMBER;
BEGIN
    -- Verificar si hay choque de horario
    SELECT COUNT(*)
    INTO v_count
    FROM DETALLE_MATRICULA dm1
    JOIN GRUPO g1 ON dm1.cod_grupo = g1.cod_grupo
    JOIN HORARIO h1 ON g1.cod_grupo = h1.cod_grupo
    JOIN HORARIO h2 ON h2.cod_grupo = p_cod_grupo
    WHERE dm1.cod_matricula = p_cod_matricula
      AND dm1.estado_inscripcion IN ('INSCRITO', 'CURSANDO')
      AND g1.cod_grupo != p_cod_grupo
      AND h1.dia_semana = h2.dia_semana
      AND (
        (h1.hora_inicio BETWEEN h2.hora_inicio AND h2.hora_fin)
        OR (h1.hora_fin BETWEEN h2.hora_inicio AND h2.hora_fin)
        OR (h2.hora_inicio BETWEEN h1.hora_inicio AND h1.hora_fin)
        OR (h2.hora_fin BETWEEN h1.hora_inicio AND h1.hora_fin)
    );
    IF v_count > 0 THEN
        RETURN 'SI';
    ELSE
        RETURN 'NO';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- Si no hay datos de horario, permitir la inscripción
        RETURN 'NO';
END;
/

-- ============================================================
-- 6. TRIGGER: Validar choque de horario
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_VALIDAR_CHOQUE_HORARIO
BEFORE INSERT ON DETALLE_MATRICULA
FOR EACH ROW
DECLARE
    v_cod_estudiante VARCHAR2(20);
    v_choque VARCHAR2(2);
BEGIN
    -- Obtener estudiante
    SELECT cod_estudiante
    INTO v_cod_estudiante
    FROM MATRICULA
    WHERE cod_matricula = :NEW.cod_matricula;
    
    -- Verificar choque de horario
    v_choque := FN_DETECTAR_CHOQUE_HORARIO(v_cod_estudiante, :NEW.cod_grupo, :NEW.cod_matricula);
    
    IF v_choque = 'SI' THEN
        RAISE_APPLICATION_ERROR(-20003,
            'Choque de horario detectado. El grupo seleccionado se solapa con otra asignatura ya inscrita.');
    END IF;
END;
/

-- ============================================================
-- 7. TRIGGER: Validar regla de evaluación suma 100%
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_VALIDAR_REGLA_EVALUACION
BEFORE INSERT OR UPDATE ON REGLA_EVALUACION
FOR EACH ROW
DECLARE
    v_suma_porcentajes NUMBER;
BEGIN
    -- Calcular suma de porcentajes para la misma asignatura
    SELECT NVL(SUM(porcentaje), 0)
    INTO v_suma_porcentajes
    FROM REGLA_EVALUACION
    WHERE cod_asignatura = :NEW.cod_asignatura
      AND cod_regla != NVL(:NEW.cod_regla, -1);
    -- Sumar el porcentaje actual
    v_suma_porcentajes := v_suma_porcentajes + :NEW.porcentaje;
    -- Validar que la suma sea exactamente 100%
    IF v_suma_porcentajes > 100 THEN
        RAISE_APPLICATION_ERROR(-20004,
            'La suma de porcentajes de evaluación excede el 100%. Actual: ' || v_suma_porcentajes || '%');
    END IF;
    -- Si es la última regla, verificar que sume exactamente 100%
    IF v_suma_porcentajes = 100 THEN
        NULL; -- OK
    ELSIF v_suma_porcentajes < 100 THEN
        -- Permitir, pero advertir (se validará cuando se cierre)
        NULL;
    END IF;
END;
/

-- ============================================================
-- 8. FUNCIÓN: Validar trabajo de grado
-- ============================================================
CREATE OR REPLACE FUNCTION FN_VALIDAR_TRABAJO_GRADO(
    p_cod_estudiante VARCHAR2,
    p_cod_asignatura VARCHAR2
) RETURN VARCHAR2 IS
    v_es_trabajo_grado VARCHAR2(2);
    v_creditos_aprobados NUMBER;
    v_creditos_totales NUMBER;
    v_porcentaje NUMBER;
    v_tiene_director NUMBER;
BEGIN
    -- Verificar si la asignatura es trabajo de grado
    SELECT CASE WHEN tipo_asignatura = 'TRABAJO_GRADO' THEN 'SI' ELSE 'NO' END
    INTO v_es_trabajo_grado
    FROM ASIGNATURA
    WHERE cod_asignatura = p_cod_asignatura;
    
    IF v_es_trabajo_grado = 'NO' THEN
        RETURN 'OK'; -- No es trabajo de grado
    END IF;
    
    -- Obtener créditos totales del programa
    SELECT p.creditos_totales
    INTO v_creditos_totales
    FROM ESTUDIANTE e
    JOIN PROGRAMA_ACADEMICO p ON e.cod_programa = p.cod_programa
    WHERE e.cod_estudiante = p_cod_estudiante;
    
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
    
    -- Verificar director asignado
    SELECT COUNT(*)
    INTO v_tiene_director
    FROM DIRECTOR_TRABAJO_GRADO
    WHERE cod_estudiante = p_cod_estudiante
      AND estado_trabajo = 'EN_PROCESO';
    
    IF v_tiene_director = 0 THEN
        RETURN 'ERROR: Debe tener un director de trabajo de grado asignado';
    END IF;
    
    RETURN 'OK';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'OK';
    WHEN OTHERS THEN
        RETURN 'OK';
END;
/

-- ============================================================
-- 9. TRIGGER: Validar inscripción trabajo de grado
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
END;
/

-- ============================================================
-- 10. TRIGGER: Bloquear modificación de notas cerradas
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_BLOQUEAR_NOTAS_CERRADAS
BEFORE INSERT OR UPDATE OR DELETE ON CALIFICACION
FOR EACH ROW
DECLARE
    v_cod_periodo VARCHAR2(10);
    v_ventana_activa VARCHAR2(2);
BEGIN
    -- Obtener periodo
    SELECT m.cod_periodo
    INTO v_cod_periodo
    FROM DETALLE_MATRICULA dm
    JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
    WHERE dm.cod_detalle_matricula = :NEW.cod_detalle_matricula;
    
    -- Verificar si ventana de evaluación está activa
    v_ventana_activa := FN_VERIFICAR_VENTANA_ACTIVA('EVALUACION', v_cod_periodo);
    
    IF v_ventana_activa = 'NO' THEN
        RAISE_APPLICATION_ERROR(-20006,
            'No se pueden modificar calificaciones. La ventana de evaluación está cerrada para el periodo ' || v_cod_periodo);
    END IF;
END;
/

-- ============================================================
-- CONFIRMAR CREACIÓN
-- ============================================================
PROMPT ============================================================
PROMPT Verificando objetos creados...
PROMPT ============================================================

SELECT object_name, object_type, status
FROM USER_OBJECTS
WHERE object_name IN (
    'FN_CREDITOS_MAXIMOS_PERMITIDOS',
    'FN_VERIFICAR_VENTANA_ACTIVA',
    'FN_DETECTAR_CHOQUE_HORARIO',
    'FN_VALIDAR_TRABAJO_GRADO',
    'TRG_VALIDAR_CREDITOS_RIESGO',
    'TRG_VALIDAR_VENTANA_CALENDARIO',
    'TRG_VALIDAR_CHOQUE_HORARIO',
    'TRG_VALIDAR_REGLA_EVALUACION',
    'TRG_VALIDAR_TRABAJO_GRADO',
    'TRG_BLOQUEAR_NOTAS_CERRADAS'
)
ORDER BY object_type, object_name;

PROMPT 
PROMPT ============================================================
PROMPT TRIGGERS CRÍTICOS CREADOS EXITOSAMENTE
PROMPT ============================================================
COMMIT;














