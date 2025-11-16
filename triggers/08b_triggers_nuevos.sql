-- =====================================================
-- SCRIPT PARA EJECUTAR SOLO LOS NUEVOS TRIGGERS
-- Archivo: 08b_triggers_nuevos.sql
-- Ejecutar como: ACADEMICO
-- =====================================================

SET SERVEROUTPUT ON
SET ECHO ON

PROMPT '========================================='
PROMPT 'INSTALANDO 3 NUEVOS TRIGGERS'
PROMPT '========================================='
PROMPT ''

-- =====================================================
-- TRIGGER 1: TRG_VALIDAR_FECHA_MATRICULA
-- Propósito: Validar que las materias se registren dentro del período de matrícula
-- =====================================================
PROMPT ''
PROMPT 'Creando trigger TRG_VALIDAR_FECHA_MATRICULA...'

CREATE OR REPLACE TRIGGER TRG_VALIDAR_FECHA_MATRICULA
BEFORE INSERT OR UPDATE ON DETALLE_MATRICULA
FOR EACH ROW
DECLARE
    v_fecha_inicio DATE;
    v_fecha_fin DATE;
    v_estado_periodo VARCHAR2(20);
    v_nombre_periodo VARCHAR2(50);
BEGIN
    -- Obtener información del período académico
    SELECT pa.fecha_inicio, pa.fecha_fin, pa.estado_periodo, pa.nombre_periodo
    INTO v_fecha_inicio, v_fecha_fin, v_estado_periodo, v_nombre_periodo
    FROM MATRICULA m
    JOIN PERIODO_ACADEMICO pa ON m.cod_periodo = pa.cod_periodo
    WHERE m.cod_matricula = :NEW.cod_matricula;
    
    -- Validar que el período esté en estado ACTIVO o PROGRAMADO
    IF v_estado_periodo NOT IN ('ACTIVO', 'PROGRAMADO') THEN
        RAISE_APPLICATION_ERROR(-20800,
            'No se puede registrar materias. El período ' || v_nombre_periodo || 
            ' está en estado: ' || v_estado_periodo);
    END IF;
    
    -- Validar que la fecha actual esté dentro del rango permitido
    IF SYSDATE < v_fecha_inicio THEN
        RAISE_APPLICATION_ERROR(-20801,
            'No se puede registrar materias. El período de matrícula aún no ha iniciado.' || CHR(10) ||
            'Fecha de inicio: ' || TO_CHAR(v_fecha_inicio, 'DD/MM/YYYY'));
    END IF;
    
    IF SYSDATE > v_fecha_fin THEN
        RAISE_APPLICATION_ERROR(-20802,
            'No se puede registrar materias. El período de matrícula ha finalizado.' || CHR(10) ||
            'Fecha de cierre: ' || TO_CHAR(v_fecha_fin, 'DD/MM/YYYY'));
    END IF;
    
    -- Si todas las validaciones pasan, permitir la inserción
    DBMS_OUTPUT.PUT_LINE('Validacion de fecha correcta para matricula ' || :NEW.cod_matricula);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20803,
            'No se encontro informacion del periodo academico para esta matricula');
    WHEN OTHERS THEN
        RAISE;
END;
/

PROMPT 'Trigger TRG_VALIDAR_FECHA_MATRICULA creado'

-- =====================================================
-- TRIGGER 2: TRG_VALIDAR_PREREQUISITOS
-- Propósito: Validar que el estudiante haya aprobado los prerequisitos
-- =====================================================
PROMPT ''
PROMPT 'Creando trigger TRG_VALIDAR_PREREQUISITOS...'

CREATE OR REPLACE TRIGGER TRG_VALIDAR_PREREQUISITOS
BEFORE INSERT ON DETALLE_MATRICULA
FOR EACH ROW
DECLARE
    v_cod_asignatura NUMBER;
    v_cod_estudiante VARCHAR2(20);
    v_nombre_asignatura VARCHAR2(200);
    v_prerequisitos_pendientes NUMBER := 0;
    v_prerequisito_nombre VARCHAR2(200);
    
    CURSOR cur_prerequisitos IS
        SELECT pr.cod_asignatura_prerequisito, a.nombre_asignatura, pr.tipo_requisito
        FROM PRERREQUISITO pr
        JOIN ASIGNATURA a ON pr.cod_asignatura_prerequisito = a.cod_asignatura
        WHERE pr.cod_asignatura = v_cod_asignatura
        AND pr.estado = 'ACTIVO';
BEGIN
    -- Obtener el código de la asignatura y del estudiante
    SELECT g.cod_asignatura, m.cod_estudiante, a.nombre_asignatura
    INTO v_cod_asignatura, v_cod_estudiante, v_nombre_asignatura
    FROM GRUPO g
    JOIN MATRICULA m ON m.cod_matricula = :NEW.cod_matricula
    JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
    WHERE g.cod_grupo = :NEW.cod_grupo;
    
    -- Verificar cada prerequisito
    FOR prerequisito IN cur_prerequisitos LOOP
        DECLARE
            v_aprobado NUMBER := 0;
        BEGIN
            -- Verificar si el estudiante aprobó el prerequisito
            SELECT COUNT(*)
            INTO v_aprobado
            FROM NOTA_DEFINITIVA nd
            JOIN DETALLE_MATRICULA dm ON nd.cod_detalle = dm.cod_detalle
            JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
            JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
            WHERE m.cod_estudiante = v_cod_estudiante
            AND g.cod_asignatura = prerequisito.cod_asignatura_prerequisito
            AND nd.estado_nota = 'APROBADO';
            
            -- Si no ha aprobado el prerequisito
            IF v_aprobado = 0 THEN
                v_prerequisitos_pendientes := v_prerequisitos_pendientes + 1;
                v_prerequisito_nombre := prerequisito.nombre_asignatura;
                
                -- Lanzar error inmediatamente
                RAISE_APPLICATION_ERROR(-20810,
                    'No puede inscribir la asignatura: ' || v_nombre_asignatura || CHR(10) ||
                    'Prerequisito pendiente: ' || prerequisito.nombre_asignatura || CHR(10) ||
                    'Tipo: ' || prerequisito.tipo_requisito || CHR(10) ||
                    'Debe aprobar primero el prerequisito antes de inscribir esta materia.');
            END IF;
        END;
    END LOOP;
    
    -- Si pasó todas las validaciones
    DBMS_OUTPUT.PUT_LINE('Prerequisitos cumplidos para ' || v_nombre_asignatura);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        NULL; -- Si no hay prerequisitos, permitir la inscripción
    WHEN OTHERS THEN
        RAISE;
END;
/

PROMPT 'Trigger TRG_VALIDAR_PREREQUISITOS creado'

-- =====================================================
-- TRIGGER 3: TRG_ACUMULAR_NOTA_DEFINITIVA
-- Propósito: Acumular automáticamente las calificaciones en la nota definitiva
-- =====================================================
PROMPT ''
PROMPT 'Creando trigger TRG_ACUMULAR_NOTA_DEFINITIVA...'

CREATE OR REPLACE TRIGGER TRG_ACUMULAR_NOTA_DEFINITIVA
AFTER INSERT OR UPDATE OR DELETE ON CALIFICACION
FOR EACH ROW
DECLARE
    v_cod_detalle NUMBER;
    v_nota_acumulada NUMBER := 0;
    v_porcentaje_total NUMBER := 0;
    v_promedio_cortes NUMBER := 0;
    v_nota_final NUMBER := 0;
    v_estado_nota VARCHAR2(20);
    v_cod_nota NUMBER;
    
    CURSOR cur_calificaciones IS
        SELECT c.nota, re.porcentaje, re.corte
        FROM CALIFICACION c
        JOIN REGLA_EVALUACION re ON c.cod_regla = re.cod_regla
        WHERE c.cod_detalle = v_cod_detalle
        ORDER BY re.corte, c.fecha_registro;
BEGIN
    -- Determinar el cod_detalle según la operación
    IF DELETING THEN
        v_cod_detalle := :OLD.cod_detalle;
    ELSE
        v_cod_detalle := :NEW.cod_detalle;
    END IF;
    
    -- Calcular la nota acumulada ponderada
    FOR calificacion IN cur_calificaciones LOOP
        v_nota_acumulada := v_nota_acumulada + (calificacion.nota * calificacion.porcentaje / 100);
        v_porcentaje_total := v_porcentaje_total + calificacion.porcentaje;
    END LOOP;
    
    -- Calcular promedio de cortes (si hay calificaciones)
    IF v_porcentaje_total > 0 THEN
        v_promedio_cortes := v_nota_acumulada;
        
        -- Si se ha evaluado el 100%, esa es la nota final
        IF v_porcentaje_total >= 100 THEN
            v_nota_final := v_nota_acumulada;
        ELSE
            -- Si aún faltan cortes, la nota final es proyectada
            v_nota_final := v_nota_acumulada;
        END IF;
        
        -- Determinar estado de la nota
        IF v_nota_final >= 3.0 THEN
            v_estado_nota := 'APROBADO';
        ELSIF v_porcentaje_total >= 100 THEN
            v_estado_nota := 'REPROBADO';
        ELSE
            v_estado_nota := 'EN_PROCESO';
        END IF;
    ELSE
        -- No hay calificaciones aún
        v_promedio_cortes := 0;
        v_nota_final := 0;
        v_estado_nota := 'PENDIENTE';
    END IF;
    
    -- Verificar si ya existe una nota definitiva
    BEGIN
        SELECT cod_nota INTO v_cod_nota
        FROM NOTA_DEFINITIVA
        WHERE cod_detalle = v_cod_detalle;
        
        -- Actualizar nota definitiva existente
        UPDATE NOTA_DEFINITIVA
        SET promedio_cortes = v_promedio_cortes,
            nota_final = v_nota_final,
            estado_nota = v_estado_nota,
            fecha_registro = SYSDATE
        WHERE cod_detalle = v_cod_detalle;
        
        DBMS_OUTPUT.PUT_LINE('Nota definitiva actualizada: ' || v_nota_final || ' - Estado: ' || v_estado_nota);
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Crear nueva nota definitiva
            INSERT INTO NOTA_DEFINITIVA (
                cod_detalle,
                promedio_cortes,
                nota_final,
                estado_nota,
                fecha_registro
            ) VALUES (
                v_cod_detalle,
                v_promedio_cortes,
                v_nota_final,
                v_estado_nota,
                SYSDATE
            );
            
            DBMS_OUTPUT.PUT_LINE('Nota definitiva creada: ' || v_nota_final || ' - Estado: ' || v_estado_nota);
    END;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Registrar error pero no bloquear la operación
        DBMS_OUTPUT.PUT_LINE('Error al calcular nota definitiva: ' || SQLERRM);
        -- No lanzar excepción para no bloquear la inserción de calificaciones
END;
/

PROMPT 'Trigger TRG_ACUMULAR_NOTA_DEFINITIVA creado'

-- =====================================================
-- RESUMEN Y VERIFICACIÓN
-- =====================================================

PROMPT ''
PROMPT '========================================='
PROMPT 'RESUMEN DE NUEVOS TRIGGERS'
PROMPT '========================================='
PROMPT ''
PROMPT '1. TRG_VALIDAR_FECHA_MATRICULA'
PROMPT '   - Valida que las materias se registren dentro del periodo'
PROMPT '   - Verifica estado del periodo (ACTIVO o PROGRAMADO)'
PROMPT '   - Valida fecha_inicio y fecha_fin del periodo'
PROMPT ''
PROMPT '2. TRG_VALIDAR_PREREQUISITOS'
PROMPT '   - Valida que el estudiante haya aprobado los prerequisitos'
PROMPT '   - Verifica cada prerequisito de la asignatura'
PROMPT '   - Impide inscripcion si falta algun prerequisito'
PROMPT ''
PROMPT '3. TRG_ACUMULAR_NOTA_DEFINITIVA'
PROMPT '   - Calcula automaticamente la nota definitiva'
PROMPT '   - Acumula notas ponderadas por porcentaje'
PROMPT '   - Actualiza estado: PENDIENTE, EN_PROCESO, APROBADO, REPROBADO'
PROMPT ''

-- Verificar que los triggers se crearon correctamente
PROMPT 'Verificando triggers creados...'
PROMPT ''

SELECT 
    trigger_name,
    table_name,
    triggering_event,
    status
FROM user_triggers
WHERE trigger_name IN (
    'TRG_VALIDAR_FECHA_MATRICULA',
    'TRG_VALIDAR_PREREQUISITOS',
    'TRG_ACUMULAR_NOTA_DEFINITIVA'
)
ORDER BY trigger_name;

PROMPT ''
PROMPT '========================================='
PROMPT 'INSTALACION COMPLETADA'
PROMPT '========================================='
PROMPT ''
