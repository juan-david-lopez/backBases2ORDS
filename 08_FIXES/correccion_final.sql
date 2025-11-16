-- ============================================================
-- CORRECCIÓN FINAL - NOMBRES DE COLUMNAS EXACTOS
-- ============================================================

-- ============================================================
-- CORREGIR: Función verificar ventana activa (columna TIPO_VENTANA)
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
    WHERE TIPO_VENTANA = p_tipo_ventana
    AND COD_PERIODO = p_cod_periodo
    AND SYSDATE BETWEEN FECHA_INICIO AND FECHA_FIN
    AND ESTADO_VENTANA = 'ACTIVA';
    
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
-- CORREGIR: Trigger validar regla evaluación (columna COD_REGLA)
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_VALIDAR_REGLA_EVALUACION
BEFORE INSERT OR UPDATE ON REGLA_EVALUACION
FOR EACH ROW
DECLARE
    v_suma_porcentajes NUMBER;
    v_cod_asignatura VARCHAR2(10);
    v_cod_regla NUMBER;
BEGIN
    v_cod_asignatura := :NEW.COD_ASIGNATURA;
    v_cod_regla := NVL(:NEW.COD_REGLA, -1);
    
    -- Calcular suma de porcentajes para la misma asignatura
    SELECT NVL(SUM(PORCENTAJE), 0)
    INTO v_suma_porcentajes
    FROM REGLA_EVALUACION
    WHERE COD_ASIGNATURA = v_cod_asignatura
    AND COD_REGLA != v_cod_regla;
    
    -- Sumar el porcentaje actual
    v_suma_porcentajes := v_suma_porcentajes + :NEW.PORCENTAJE;
    
    -- Validar que la suma no exceda 100%
    IF v_suma_porcentajes > 100 THEN
        RAISE_APPLICATION_ERROR(-20004,
            'La suma de porcentajes de evaluación excede el 100%. Actual: ' || v_suma_porcentajes || '%');
    END IF;
END;
/

-- ============================================================
-- Recompilar triggers dependientes
-- ============================================================
ALTER TRIGGER TRG_VALIDAR_VENTANA_CALENDARIO COMPILE;
ALTER TRIGGER TRG_BLOQUEAR_NOTAS_CERRADAS COMPILE;

-- ============================================================
-- VERIFICAR TODOS LOS OBJETOS
-- ============================================================
PROMPT ============================================================
PROMPT Estado de todos los triggers críticos:
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
PROMPT Total objetos VALID vs INVALID:
PROMPT ============================================================

SELECT status, COUNT(*) as cantidad
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
GROUP BY status
ORDER BY status;

COMMIT;
EXIT
