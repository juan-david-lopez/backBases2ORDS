-- =====================================================
-- CORRECCIÓN DE TRIGGERS INVÁLIDOS
-- Archivo: fix_triggers_invalidos.sql
-- Propósito: Corregir TRG_VALIDAR_PREREQUISITOS y TRG_ACUMULAR_NOTA_DEFINITIVA
-- =====================================================

SET SERVEROUTPUT ON
PROMPT ''
PROMPT '====================================================='
PROMPT 'CORRECCIÓN DE TRIGGERS INVÁLIDOS'
PROMPT '====================================================='
PROMPT ''

-- =====================================================
-- TRIGGER 1: TRG_VALIDAR_PREREQUISITOS (CORREGIDO)
-- =====================================================
PROMPT 'Recreando trigger TRG_VALIDAR_PREREQUISITOS...'

CREATE OR REPLACE TRIGGER TRG_VALIDAR_PREREQUISITOS
BEFORE INSERT ON DETALLE_MATRICULA
FOR EACH ROW
DECLARE
    v_cod_asignatura VARCHAR2(20);
    v_cod_estudiante VARCHAR2(20);
    v_nombre_asignatura VARCHAR2(200);
    v_prerequisitos_pendientes NUMBER := 0;
    v_prerequisito_nombre VARCHAR2(200);
    
    CURSOR cur_prerequisitos IS
        SELECT pr.cod_asignatura_requisito, a.nombre_asignatura, pr.tipo_requisito
        FROM PRERREQUISITO pr
        JOIN ASIGNATURA a ON pr.cod_asignatura_requisito = a.cod_asignatura
        WHERE pr.cod_asignatura = v_cod_asignatura;
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
            JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
            JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
            JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
            WHERE m.cod_estudiante = v_cod_estudiante
            AND g.cod_asignatura = prerequisito.cod_asignatura_requisito
            AND nd.resultado = 'APROBADO';
            
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
    DBMS_OUTPUT.PUT_LINE('✓ Prerequisitos cumplidos para ' || v_nombre_asignatura);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        NULL; -- Si no hay prerequisitos, permitir la inscripción
    WHEN OTHERS THEN
        RAISE;
END;
/

PROMPT '✓ Trigger TRG_VALIDAR_PREREQUISITOS corregido'

-- =====================================================
-- TRIGGER 2: TRG_ACUMULAR_NOTA_DEFINITIVA (CORREGIDO)
-- =====================================================
PROMPT ''
PROMPT 'Recreando trigger TRG_ACUMULAR_NOTA_DEFINITIVA...'

CREATE OR REPLACE TRIGGER TRG_ACUMULAR_NOTA_DEFINITIVA
AFTER INSERT OR UPDATE OR DELETE ON CALIFICACION
FOR EACH ROW
DECLARE
    v_cod_detalle_matricula NUMBER;
    v_nota_acumulada NUMBER := 0;
    v_porcentaje_total NUMBER := 0;
    v_nota_final NUMBER := 0;
    v_estado_nota VARCHAR2(20);
    v_cod_nota NUMBER;
    
    CURSOR cur_calificaciones IS
        SELECT c.nota, c.porcentaje_aplicado
        FROM CALIFICACION c
        WHERE c.cod_detalle_matricula = v_cod_detalle_matricula
        ORDER BY c.fecha_registro;
BEGIN
    -- Determinar el cod_detalle_matricula según la operación
    IF DELETING THEN
        v_cod_detalle_matricula := :OLD.cod_detalle_matricula;
    ELSE
        v_cod_detalle_matricula := :NEW.cod_detalle_matricula;
    END IF;
    
    -- Calcular la nota acumulada ponderada
    FOR calificacion IN cur_calificaciones LOOP
        v_nota_acumulada := v_nota_acumulada + (calificacion.nota * calificacion.porcentaje_aplicado / 100);
        v_porcentaje_total := v_porcentaje_total + calificacion.porcentaje_aplicado;
    END LOOP;
    
    -- Calcular nota final
    IF v_porcentaje_total > 0 THEN
        v_nota_final := v_nota_acumulada;
        
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
        v_nota_final := 0;
        v_estado_nota := 'PENDIENTE';
    END IF;
    
    -- Verificar si ya existe una nota definitiva
    BEGIN
        SELECT cod_nota_definitiva INTO v_cod_nota
        FROM NOTA_DEFINITIVA
        WHERE cod_detalle_matricula = v_cod_detalle_matricula;
        
        -- Actualizar nota definitiva existente
        UPDATE NOTA_DEFINITIVA
        SET nota_final = v_nota_final,
            resultado = v_estado_nota,
            fecha_calculo = SYSDATE,
            fecha_registro = SYSTIMESTAMP
        WHERE cod_detalle_matricula = v_cod_detalle_matricula;
        
        DBMS_OUTPUT.PUT_LINE('✓ Nota definitiva actualizada: ' || v_nota_final || ' - Estado: ' || v_estado_nota);
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Crear nueva nota definitiva
            INSERT INTO NOTA_DEFINITIVA (
                cod_detalle_matricula,
                nota_final,
                resultado,
                fecha_calculo,
                fecha_registro
            ) VALUES (
                v_cod_detalle_matricula,
                v_nota_final,
                v_estado_nota,
                SYSDATE,
                SYSTIMESTAMP
            );
            
            DBMS_OUTPUT.PUT_LINE('✓ Nota definitiva creada: ' || v_nota_final || ' - Estado: ' || v_estado_nota);
    END;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Log del error pero no detener la ejecución
        DBMS_OUTPUT.PUT_LINE('⚠ Error al actualizar nota definitiva: ' || SQLERRM);
END;
/

PROMPT '✓ Trigger TRG_ACUMULAR_NOTA_DEFINITIVA corregido'

-- =====================================================
-- VERIFICACIÓN
-- =====================================================
PROMPT ''
PROMPT 'Verificando estado de los triggers...'
PROMPT ''

SELECT object_name, object_type, status
FROM user_objects
WHERE object_name IN ('TRG_VALIDAR_PREREQUISITOS', 'TRG_ACUMULAR_NOTA_DEFINITIVA')
ORDER BY object_name;

PROMPT ''
PROMPT '====================================================='
PROMPT 'CORRECCIÓN DE TRIGGERS COMPLETADA'
PROMPT '====================================================='

EXIT;
