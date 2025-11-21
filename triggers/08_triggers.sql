-- =====================================================
-- SISTEMA ACADÉMICO - ORACLE DATABASE 19c
-- Script: 08_triggers.sql
-- Propósito: Triggers para auditoría y control automático
-- Autor: Sistema Académico
-- Fecha: 28/10/2025
-- =====================================================

-- =====================================================
-- TRIGGER: TRG_AUDITORIA_ESTUDIANTE
-- Propósito: Audita cambios en la tabla ESTUDIANTE
-- Tipo: AFTER INSERT, UPDATE, DELETE
-- =====================================================
CREATE OR REPLACE TRIGGER TRG_AUDITORIA_ESTUDIANTE
AFTER INSERT OR UPDATE OR DELETE ON ESTUDIANTE
FOR EACH ROW
DECLARE
    v_operacion VARCHAR2(20);
    v_valores_anteriores CLOB;
    v_valores_nuevos CLOB;
BEGIN
    -- Determinar tipo de operación
    IF INSERTING THEN
        v_operacion := 'INSERT';
        v_valores_nuevos := '{"cod_estudiante":"' || :NEW.cod_estudiante || 
                           '","nombres":"' || :NEW.primer_nombre || ' ' || :NEW.primer_apellido ||
                           '","programa":"' || :NEW.cod_programa ||
                           '","estado":"' || :NEW.estado_estudiante || '"}';
    ELSIF UPDATING THEN
        v_operacion := 'UPDATE';
        v_valores_anteriores := '{"cod_estudiante":"' || :OLD.cod_estudiante || 
                                '","nombres":"' || :OLD.primer_nombre || ' ' || :OLD.primer_apellido ||
                                '","programa":"' || :OLD.cod_programa ||
                                '","estado":"' || :OLD.estado_estudiante || '"}';
        v_valores_nuevos := '{"cod_estudiante":"' || :NEW.cod_estudiante || 
                           '","nombres":"' || :NEW.primer_nombre || ' ' || :NEW.primer_apellido ||
                           '","programa":"' || :NEW.cod_programa ||
                           '","estado":"' || :NEW.estado_estudiante || '"}';
    ELSIF DELETING THEN
        v_operacion := 'DELETE';
        v_valores_anteriores := '{"cod_estudiante":"' || :OLD.cod_estudiante || 
                                '","nombres":"' || :OLD.primer_nombre || ' ' || :OLD.primer_apellido ||
                                '","programa":"' || :OLD.cod_programa ||
                                '","estado":"' || :OLD.estado_estudiante || '"}';
    END IF;
    
    -- Registrar en auditoría
    PKG_AUDITORIA.registrar_auditoria(
        p_tabla => 'ESTUDIANTE',
        p_operacion => v_operacion,
        p_usuario => USER,
        p_valores_anteriores => v_valores_anteriores,
        p_valores_nuevos => v_valores_nuevos
    );
END;
/

PROMPT 'Trigger TRG_AUDITORIA_ESTUDIANTE creado'

-- =====================================================
-- TRIGGER: TRG_AUDITORIA_MATRICULA
-- Propósito: Audita operaciones de matrícula
-- =====================================================
CREATE OR REPLACE TRIGGER TRG_AUDITORIA_MATRICULA
AFTER INSERT OR UPDATE OR DELETE ON MATRICULA
FOR EACH ROW
DECLARE
    v_operacion VARCHAR2(20);
    v_valores_anteriores CLOB;
    v_valores_nuevos CLOB;
BEGIN
    IF INSERTING THEN
        v_operacion := 'INSERT';
        v_valores_nuevos := '{"cod_matricula":"' || :NEW.cod_matricula ||
                           '","estudiante":"' || :NEW.cod_estudiante ||
                           '","periodo":"' || :NEW.cod_periodo ||
                           '","estado":"' || :NEW.estado_matricula || '"}';
    ELSIF UPDATING THEN
        v_operacion := 'UPDATE';
        v_valores_anteriores := '{"cod_matricula":"' || :OLD.cod_matricula ||
                                '","estado":"' || :OLD.estado_matricula ||
                                '","creditos":"' || :OLD.total_creditos || '"}';
        v_valores_nuevos := '{"cod_matricula":"' || :NEW.cod_matricula ||
                           '","estado":"' || :NEW.estado_matricula ||
                           '","creditos":"' || :NEW.total_creditos || '"}';
    ELSIF DELETING THEN
        v_operacion := 'DELETE';
        v_valores_anteriores := '{"cod_matricula":"' || :OLD.cod_matricula ||
                                '","estudiante":"' || :OLD.cod_estudiante ||
                                '","periodo":"' || :OLD.cod_periodo || '"}';
    END IF;
    
    PKG_AUDITORIA.registrar_auditoria(
        p_tabla => 'MATRICULA',
        p_operacion => v_operacion,
        p_usuario => USER,
        p_valores_anteriores => v_valores_anteriores,
        p_valores_nuevos => v_valores_nuevos
    );
END;
/

PROMPT 'Trigger TRG_AUDITORIA_MATRICULA creado'

-- =====================================================
-- TRIGGER: TRG_AUDITORIA_CALIFICACION
-- Propósito: Audita cambios en calificaciones
-- =====================================================
CREATE OR REPLACE TRIGGER TRG_AUDITORIA_CALIFICACION
AFTER INSERT OR UPDATE OR DELETE ON CALIFICACION
FOR EACH ROW
DECLARE
    v_operacion VARCHAR2(20);
    v_valores_anteriores CLOB;
    v_valores_nuevos CLOB;
BEGIN
    IF INSERTING THEN
        v_operacion := 'INSERT';
        v_valores_nuevos := '{"cod_calificacion":"' || :NEW.cod_calificacion ||
                           '","detalle":"' || :NEW.cod_detalle_matricula ||
                           '","nota":"' || :NEW.nota || '"}';
    ELSIF UPDATING THEN
        v_operacion := 'UPDATE';
        v_valores_anteriores := '{"nota_anterior":"' || :OLD.nota ||
                                '","fecha":"' || TO_CHAR(:OLD.fecha_calificacion, 'DD/MM/YYYY') || '"}';
        v_valores_nuevos := '{"nota_nueva":"' || :NEW.nota ||
                           '","fecha":"' || TO_CHAR(:NEW.fecha_calificacion, 'DD/MM/YYYY') || '"}';
    ELSIF DELETING THEN
        v_operacion := 'DELETE';
        v_valores_anteriores := '{"cod_calificacion":"' || :OLD.cod_calificacion ||
                                '","nota":"' || :OLD.nota || '"}';
    END IF;
    
    PKG_AUDITORIA.registrar_auditoria(
        p_tabla => 'CALIFICACION',
        p_operacion => v_operacion,
        p_usuario => USER,
        p_valores_anteriores => v_valores_anteriores,
        p_valores_nuevos => v_valores_nuevos
    );
END;
/

PROMPT 'Trigger TRG_AUDITORIA_CALIFICACION creado'

-- =====================================================
-- TRIGGER: TRG_VALIDAR_NOTA
-- Propósito: Valida que las notas estén en rango válido
-- Tipo: BEFORE INSERT OR UPDATE
-- =====================================================
CREATE OR REPLACE TRIGGER TRG_VALIDAR_NOTA
BEFORE INSERT OR UPDATE ON CALIFICACION
FOR EACH ROW
BEGIN
    -- Validar rango de nota (0.0 a 5.0)
    IF :NEW.nota < 0 OR :NEW.nota > 5 THEN
        RAISE_APPLICATION_ERROR(-20600, 'La nota debe estar entre 0.0 y 5.0');
    END IF;
    
    -- Validar porcentaje si está asignado
    IF :NEW.porcentaje_aplicado IS NOT NULL THEN
        IF :NEW.porcentaje_aplicado < 0 OR :NEW.porcentaje_aplicado > 100 THEN
            RAISE_APPLICATION_ERROR(-20601, 'El porcentaje debe estar entre 0 y 100');
        END IF;
    END IF;
END;
/

PROMPT 'Trigger TRG_VALIDAR_NOTA creado'

-- =====================================================
-- TRIGGER: TRG_ACTUALIZAR_CUPO_GRUPO
-- Propósito: Actualiza automáticamente cupos al inscribir/retirar
-- Tipo: AFTER INSERT, UPDATE, DELETE
-- Nota: Se desactiva porque PKG_MATRICULA ya lo maneja
-- =====================================================
/*
CREATE OR REPLACE TRIGGER TRG_ACTUALIZAR_CUPO_GRUPO
AFTER INSERT OR UPDATE OR DELETE ON DETALLE_MATRICULA
FOR EACH ROW
BEGIN
    IF INSERTING AND :NEW.estado_inscripcion = 'INSCRITO' THEN
        UPDATE GRUPO
        SET cupo_disponible = cupo_disponible - 1
        WHERE cod_grupo = :NEW.cod_grupo;
    ELSIF UPDATING AND :OLD.estado_inscripcion = 'INSCRITO' AND :NEW.estado_inscripcion = 'RETIRADO' THEN
        UPDATE GRUPO
        SET cupo_disponible = cupo_disponible + 1
        WHERE cod_grupo = :NEW.cod_grupo;
    ELSIF DELETING AND :OLD.estado_inscripcion = 'INSCRITO' THEN
        UPDATE GRUPO
        SET cupo_disponible = cupo_disponible + 1
        WHERE cod_grupo = :OLD.cod_grupo;
    END IF;
END;
/
*/

-- =====================================================
-- TRIGGER: TRG_DETECTAR_RIESGO_ACADEMICO
-- Propósito: Detecta automáticamente estudiantes en riesgo
-- Tipo: AFTER INSERT OR UPDATE
-- Nota: Calcula el promedio directamente sin dependencia del paquete
-- para evitar dependencias circulares
-- =====================================================
CREATE OR REPLACE TRIGGER TRG_DETECTAR_RIESGO_ACADEMICO
AFTER INSERT OR UPDATE ON NOTA_DEFINITIVA
FOR EACH ROW
DECLARE
    v_cod_estudiante VARCHAR2(15);
    v_cod_periodo VARCHAR2(10);
    v_promedio_periodo NUMBER;
    v_asignaturas_reprobadas NUMBER;
    v_tipo_riesgo VARCHAR2(30);
    v_nivel_riesgo VARCHAR2(10);
    v_riesgo_existente NUMBER;
BEGIN
    -- Solo procesar si la nota es reprobada/perdida o muy baja
    IF :NEW.resultado IN ('REPROBADO','PERDIDA') OR :NEW.nota_final < 3.5 THEN
        
        -- Obtener información del estudiante y periodo
        SELECT m.cod_estudiante, m.cod_periodo
        INTO v_cod_estudiante, v_cod_periodo
        FROM DETALLE_MATRICULA dm
        INNER JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
        WHERE dm.cod_detalle_matricula = :NEW.cod_detalle_matricula;
        
        -- Calcular promedio del periodo directamente (sin usar paquete)
        BEGIN
            SELECT ROUND(AVG(nd.nota_final), 2)
            INTO v_promedio_periodo
            FROM NOTA_DEFINITIVA nd
            INNER JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
            INNER JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
            WHERE m.cod_estudiante = v_cod_estudiante
            AND m.cod_periodo = v_cod_periodo
            AND nd.resultado IN ('APROBADO', 'REPROBADO', 'PERDIDA');
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_promedio_periodo := 0;
        END;
        
        -- Contar asignaturas reprobadas en el periodo
        SELECT COUNT(*)
        INTO v_asignaturas_reprobadas
        FROM NOTA_DEFINITIVA nd
        INNER JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
        INNER JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
        WHERE m.cod_estudiante = v_cod_estudiante
        AND m.cod_periodo = v_cod_periodo
        AND nd.resultado IN ('REPROBADO','PERDIDA');
        
        -- Determinar tipo y nivel de riesgo
        IF v_promedio_periodo < 2.5 THEN
            v_tipo_riesgo := 'PERDIDA_CALIDAD';
            v_nivel_riesgo := 'CRITICO';
        ELSIF v_asignaturas_reprobadas >= 3 THEN
            v_tipo_riesgo := 'REPROBACION_MULTIPLE';
            v_nivel_riesgo := 'ALTO';
        ELSIF v_promedio_periodo < 3.0 THEN
            v_tipo_riesgo := 'BAJO_RENDIMIENTO';
            v_nivel_riesgo := 'MEDIO';
        ELSE
            v_tipo_riesgo := 'BAJO_RENDIMIENTO';
            v_nivel_riesgo := 'BAJO';
        END IF;
        
        -- Verificar si ya existe registro de riesgo para este periodo
        SELECT COUNT(*)
        INTO v_riesgo_existente
        FROM HISTORIAL_RIESGO
        WHERE cod_estudiante = v_cod_estudiante
        AND cod_periodo = v_cod_periodo;
        
        IF v_riesgo_existente = 0 THEN
            -- Insertar nuevo registro de riesgo
            INSERT INTO HISTORIAL_RIESGO (
                cod_estudiante,
                cod_periodo,
                tipo_riesgo,
                nivel_riesgo,
                promedio_periodo,
                asignaturas_reprobadas,
                fecha_deteccion,
                estado_seguimiento,
                observaciones
            ) VALUES (
                v_cod_estudiante,
                v_cod_periodo,
                v_tipo_riesgo,
                v_nivel_riesgo,
                v_promedio_periodo,
                v_asignaturas_reprobadas,
                SYSDATE,
                'PENDIENTE',
                'Detección automática por rendimiento académico'
            );
        ELSE
            -- Actualizar registro existente
            UPDATE HISTORIAL_RIESGO
            SET tipo_riesgo = v_tipo_riesgo,
                nivel_riesgo = v_nivel_riesgo,
                promedio_periodo = v_promedio_periodo,
                asignaturas_reprobadas = v_asignaturas_reprobadas,
                fecha_deteccion = SYSDATE
            WHERE cod_estudiante = v_cod_estudiante
            AND cod_periodo = v_cod_periodo;
        END IF;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- No abortar la transacción principal
        DBMS_OUTPUT.PUT_LINE('Error en detección de riesgo: ' || SQLERRM);
END;
/

PROMPT 'Trigger TRG_DETECTAR_RIESGO_ACADEMICO creado'

-- =====================================================
-- TRIGGER: TRG_VALIDAR_PERIODO_VIGENTE
-- Propósito: Valida que las fechas del periodo sean coherentes
-- Tipo: BEFORE INSERT OR UPDATE
-- =====================================================
CREATE OR REPLACE TRIGGER TRG_VALIDAR_PERIODO_VIGENTE
BEFORE INSERT OR UPDATE ON PERIODO_ACADEMICO
FOR EACH ROW
BEGIN
    -- Validar que fecha_fin sea posterior a fecha_inicio
    IF :NEW.fecha_fin <= :NEW.fecha_inicio THEN
        RAISE_APPLICATION_ERROR(-20700, 'La fecha de fin debe ser posterior a la fecha de inicio');
    END IF;
    
    -- Validar que el número de periodo esté entre 1 y 3
    IF :NEW.periodo NOT BETWEEN 1 AND 3 THEN
        RAISE_APPLICATION_ERROR(-20701, 'El periodo debe ser 1, 2 o 3');
    END IF;
    
    -- Si está en curso, validar que las fechas sean coherentes con la fecha actual
    IF :NEW.estado_periodo = 'EN_CURSO' THEN
        IF TRUNC(SYSDATE) < :NEW.fecha_inicio OR TRUNC(SYSDATE) > :NEW.fecha_fin THEN
            RAISE_APPLICATION_ERROR(-20702, 
                'Un periodo EN_CURSO debe contener la fecha actual entre inicio y fin');
        END IF;
    END IF;
END;
/

PROMPT 'Trigger TRG_VALIDAR_PERIODO_VIGENTE creado'

-- =====================================================
-- TRIGGER: TRG_VALIDAR_CUPO_GRUPO
-- Propósito: Valida que el cupo disponible no sea negativo
-- Tipo: BEFORE INSERT OR UPDATE
-- =====================================================
CREATE OR REPLACE TRIGGER TRG_VALIDAR_CUPO_GRUPO
BEFORE INSERT OR UPDATE ON GRUPO
FOR EACH ROW
BEGIN
    -- Validar que cupo_disponible no sea negativo
    IF :NEW.cupo_disponible < 0 THEN
        RAISE_APPLICATION_ERROR(-20710, 'El cupo disponible no puede ser negativo');
    END IF;
    
    -- Validar que cupo_disponible no supere cupo_maximo
    IF :NEW.cupo_disponible > :NEW.cupo_maximo THEN
        RAISE_APPLICATION_ERROR(-20711, 'El cupo disponible no puede superar el cupo máximo');
    END IF;
    
    -- Validar que cupo_maximo sea positivo
    IF :NEW.cupo_maximo <= 0 THEN
        RAISE_APPLICATION_ERROR(-20712, 'El cupo máximo debe ser mayor a cero');
    END IF;
    
    -- Al insertar, inicializar cupo_disponible igual a cupo_maximo si no está definido
    IF INSERTING AND :NEW.cupo_disponible IS NULL THEN
        :NEW.cupo_disponible := :NEW.cupo_maximo;
    END IF;
END;
/

PROMPT 'Trigger TRG_VALIDAR_CUPO_GRUPO creado'

-- =====================================================
-- TRIGGER: TRG_GENERAR_CODIGO_ESTUDIANTE
-- Propósito: Genera automáticamente código de estudiante
-- Tipo: BEFORE INSERT
-- Nota: Solo si no se proporciona código
-- =====================================================
CREATE OR REPLACE TRIGGER TRG_GENERAR_CODIGO_ESTUDIANTE
BEFORE INSERT ON ESTUDIANTE
FOR EACH ROW
BEGIN
    -- Si no se proporciona código, generarlo automáticamente
    IF :NEW.cod_estudiante IS NULL THEN
        :NEW.cod_estudiante := FN_GENERAR_COD_ESTUDIANTE();
    END IF;
    
    -- Validar formato de correo institucional
    IF :NEW.correo_institucional NOT LIKE '%@%' THEN
        RAISE_APPLICATION_ERROR(-20720, 'El correo institucional debe tener formato válido');
    END IF;
END;
/

PROMPT 'Trigger TRG_GENERAR_CODIGO_ESTUDIANTE creado'

-- =====================================================
-- TRIGGER: TRG_GENERAR_CODIGO_DOCENTE
-- Propósito: Genera automáticamente código de docente
-- Tipo: BEFORE INSERT
-- =====================================================
CREATE OR REPLACE TRIGGER TRG_GENERAR_CODIGO_DOCENTE
BEFORE INSERT ON DOCENTE
FOR EACH ROW
BEGIN
    -- Si no se proporciona código, generarlo automáticamente
    IF :NEW.cod_docente IS NULL THEN
        :NEW.cod_docente := FN_GENERAR_COD_DOCENTE();
    END IF;
    
    -- Validar formato de correo institucional
    IF :NEW.correo_institucional NOT LIKE '%@%' THEN
        RAISE_APPLICATION_ERROR(-20730, 'El correo institucional debe tener formato válido');
    END IF;
END;
/

PROMPT 'Trigger TRG_GENERAR_CODIGO_DOCENTE creado'

-- =====================================================
-- TRIGGER: TRG_LOG_ACCESO_USUARIO
-- Propósito: Registra intentos de acceso al sistema
-- Tipo: AFTER UPDATE
-- =====================================================
CREATE OR REPLACE TRIGGER TRG_LOG_ACCESO_USUARIO
AFTER UPDATE ON USUARIO_SISTEMA
FOR EACH ROW
WHEN (NEW.ultimo_acceso IS NOT NULL AND NEW.ultimo_acceso != OLD.ultimo_acceso)
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_resultado VARCHAR2(20);
BEGIN
    -- Determinar si fue exitoso o fallido
    IF :NEW.cuenta_bloqueada = 'S' THEN
        v_resultado := 'BLOQUEADO';
    ELSIF :NEW.intentos_fallidos > :OLD.intentos_fallidos THEN
        v_resultado := 'FALLIDO';
    ELSE
        v_resultado := 'EXITOSO';
    END IF;
    
    -- Registrar acceso
    INSERT INTO LOG_ACCESO (
        cod_usuario,
        fecha_acceso,
        ip_origen,
        resultado_acceso
    ) VALUES (
        :NEW.cod_usuario,
        :NEW.ultimo_acceso,
        PKG_AUDITORIA.obtener_ip_cliente(),
        v_resultado
    );
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
END;
/

PROMPT 'Trigger TRG_LOG_ACCESO_USUARIO creado'

-- =====================================================
-- TRIGGER: TRG_VALIDAR_HORARIO
-- Propósito: Valida que el horario tenga formato correcto
-- Tipo: BEFORE INSERT OR UPDATE
-- =====================================================
CREATE OR REPLACE TRIGGER TRG_VALIDAR_HORARIO
BEFORE INSERT OR UPDATE ON HORARIO
FOR EACH ROW
BEGIN
    -- Validar formato de hora (HH24:MI)
    IF :NEW.hora_inicio NOT LIKE '__:__' OR :NEW.hora_fin NOT LIKE '__:__' THEN
        RAISE_APPLICATION_ERROR(-20740, 'El formato de hora debe ser HH24:MI (ejemplo: 08:00)');
    END IF;
    
    -- Validar que hora_fin sea posterior a hora_inicio
    IF :NEW.hora_fin <= :NEW.hora_inicio THEN
        RAISE_APPLICATION_ERROR(-20741, 'La hora de fin debe ser posterior a la hora de inicio');
    END IF;
    
    -- Validar día de la semana
    IF :NEW.dia_semana NOT IN ('LUNES', 'MARTES', 'MIERCOLES', 'JUEVES', 'VIERNES', 'SABADO', 'DOMINGO') THEN
        RAISE_APPLICATION_ERROR(-20742, 'Día de la semana no válido');
    END IF;
END;
/

PROMPT 'Trigger TRG_VALIDAR_HORARIO creado'

-- =====================================================
-- TRIGGER: TRG_BLOQUEAR_USUARIO
-- Propósito: Bloquea usuario después de 3 intentos fallidos
-- Tipo: BEFORE UPDATE
-- =====================================================
CREATE OR REPLACE TRIGGER TRG_BLOQUEAR_USUARIO
BEFORE UPDATE ON USUARIO_SISTEMA
FOR EACH ROW
WHEN (NEW.intentos_fallidos >= 3)
BEGIN
    :NEW.cuenta_bloqueada := 'S';
    :NEW.estado := 'BLOQUEADO';
END;
/

PROMPT 'Trigger TRG_BLOQUEAR_USUARIO creado'

-- =====================================================
-- TRIGGER: TRG_AUDITORIA_USUARIO_SISTEMA
-- Propósito: Audita cambios en usuarios del sistema
-- =====================================================
CREATE OR REPLACE TRIGGER TRG_AUDITORIA_USUARIO_SISTEMA
AFTER INSERT OR UPDATE OR DELETE ON USUARIO_SISTEMA
FOR EACH ROW
DECLARE
    v_operacion VARCHAR2(20);
    v_valores_anteriores CLOB;
    v_valores_nuevos CLOB;
BEGIN
    IF INSERTING THEN
        v_operacion := 'INSERT';
        v_valores_nuevos := '{"username":"' || :NEW.username ||
                           '","tipo_usuario":"' || :NEW.tipo_usuario ||
                           '","estado":"' || :NEW.estado || '"}';
    ELSIF UPDATING THEN
        v_operacion := 'UPDATE';
        v_valores_anteriores := '{"estado_anterior":"' || :OLD.estado ||
                                '","intentos_anteriores":"' || :OLD.intentos_fallidos || '"}';
        v_valores_nuevos := '{"estado_nuevo":"' || :NEW.estado ||
                           '","intentos_nuevos":"' || :NEW.intentos_fallidos || '"}';
    ELSIF DELETING THEN
        v_operacion := 'DELETE';
        v_valores_anteriores := '{"username":"' || :OLD.username ||
                                '","tipo_usuario":"' || :OLD.tipo_usuario || '"}';
    END IF;
    
    PKG_AUDITORIA.registrar_auditoria(
        p_tabla => 'USUARIO_SISTEMA',
        p_operacion => v_operacion,
        p_usuario => USER,
        p_valores_anteriores => v_valores_anteriores,
        p_valores_nuevos => v_valores_nuevos
    );
END;
/

PROMPT 'Trigger TRG_AUDITORIA_USUARIO_SISTEMA creado'

-- =====================================================
-- TRIGGER: TRG_VALIDAR_CREDITOS_ASIGNATURA
-- Propósito: Valida que los créditos sean coherentes con horas
-- Tipo: BEFORE INSERT OR UPDATE
-- =====================================================
CREATE OR REPLACE TRIGGER TRG_VALIDAR_CREDITOS_ASIGNATURA
BEFORE INSERT OR UPDATE ON ASIGNATURA
FOR EACH ROW
DECLARE
    v_total_horas NUMBER;
BEGIN
    -- Calcular total de horas
    v_total_horas := :NEW.horas_teoricas + :NEW.horas_practicas;
    
    -- Validar que los créditos sean proporcionales a las horas
    -- Regla: 1 crédito = aproximadamente 3 horas semanales
    IF v_total_horas > 0 THEN
        IF :NEW.creditos > CEIL(v_total_horas / 2) OR :NEW.creditos < FLOOR(v_total_horas / 4) THEN
            RAISE_APPLICATION_ERROR(-20750, 
                'Los créditos deben ser proporcionales a las horas (1 crédito ≈ 3 horas semanales)');
        END IF;
    END IF;
    
    -- Validar que creditos sea positivo
    IF :NEW.creditos <= 0 THEN
        RAISE_APPLICATION_ERROR(-20751, 'Los créditos deben ser mayores a cero');
    END IF;
END;
/

PROMPT 'Trigger TRG_VALIDAR_CREDITOS_ASIGNATURA creado'

-- =====================================================
-- RESUMEN DE TRIGGERS CREADOS
-- =====================================================
PROMPT '========================================='
PROMPT 'TRIGGERS CREADOS EXITOSAMENTE'
PROMPT '========================================='
PROMPT ''
PROMPT 'TRIGGERS DE AUDITORÍA:'
PROMPT '  - TRG_AUDITORIA_ESTUDIANTE'
PROMPT '  - TRG_AUDITORIA_MATRICULA'
PROMPT '  - TRG_AUDITORIA_CALIFICACION'
PROMPT '  - TRG_AUDITORIA_USUARIO_SISTEMA'
PROMPT ''
PROMPT 'TRIGGERS DE VALIDACIÓN:'
PROMPT '  - TRG_VALIDAR_NOTA'
PROMPT '  - TRG_VALIDAR_PERIODO_VIGENTE'
PROMPT '  - TRG_VALIDAR_CUPO_GRUPO'
PROMPT '  - TRG_VALIDAR_HORARIO'
PROMPT '  - TRG_VALIDAR_CREDITOS_ASIGNATURA'
PROMPT ''
PROMPT 'TRIGGERS DE NEGOCIO:'
PROMPT '  - TRG_DETECTAR_RIESGO_ACADEMICO'
PROMPT '  - TRG_GENERAR_CODIGO_ESTUDIANTE'
PROMPT '  - TRG_GENERAR_CODIGO_DOCENTE'
PROMPT '  - TRG_BLOQUEAR_USUARIO'
PROMPT '  - TRG_LOG_ACCESO_USUARIO'
PROMPT ''
PROMPT '========================================='

-- =====================================================
-- NUEVOS TRIGGERS ADICIONALES
-- =====================================================

-- =====================================================
-- TRIGGER: TRG_VALIDAR_FECHA_MATRICULA
-- Propósito: Validar que las materias se registren dentro del período de matrícula
-- Tipo: BEFORE INSERT OR UPDATE
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
    DBMS_OUTPUT.PUT_LINE('✓ Validación de fecha correcta para matrícula ' || :NEW.cod_matricula);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20803,
            'No se encontró información del período académico para esta matrícula');
    WHEN OTHERS THEN
        RAISE;
END;
/

PROMPT '✓ Trigger TRG_VALIDAR_FECHA_MATRICULA creado'

-- =====================================================
-- TRIGGER: TRG_VALIDAR_PREREQUISITOS
-- Propósito: Validar que el estudiante haya aprobado los prerequisitos
-- Tipo: BEFORE INSERT
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
    DBMS_OUTPUT.PUT_LINE('✓ Prerequisitos cumplidos para ' || v_nombre_asignatura);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        NULL; -- Si no hay prerequisitos, permitir la inscripción
    WHEN OTHERS THEN
        RAISE;
END;
/

PROMPT '✓ Trigger TRG_VALIDAR_PREREQUISITOS creado'

-- =====================================================
-- TRIGGER: TRG_ACUMULAR_NOTA_DEFINITIVA
-- Propósito: Acumular automáticamente las calificaciones en la nota definitiva
-- Tipo: AFTER INSERT OR UPDATE OR DELETE
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
            v_estado_nota := 'PERDIDA';
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
        
        DBMS_OUTPUT.PUT_LINE('✓ Nota definitiva actualizada: ' || v_nota_final || ' - Estado: ' || v_estado_nota);
        
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
            
            DBMS_OUTPUT.PUT_LINE('✓ Nota definitiva creada: ' || v_nota_final || ' - Estado: ' || v_estado_nota);
    END;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Registrar error pero no bloquear la operación
        DBMS_OUTPUT.PUT_LINE('Error al calcular nota definitiva: ' || SQLERRM);
        -- No lanzar excepción para no bloquear la inserción de calificaciones
END;
/

PROMPT '✓ Trigger TRG_ACUMULAR_NOTA_DEFINITIVA creado'

-- =====================================================
-- ACTUALIZAR RESUMEN DE TRIGGERS
-- =====================================================

PROMPT ''
PROMPT '========================================='
PROMPT 'TRIGGERS CREADOS EXITOSAMENTE'
PROMPT '========================================='
PROMPT ''
PROMPT 'TRIGGERS DE AUDITORÍA:'
PROMPT '  - TRG_AUDITORIA_ESTUDIANTE'
PROMPT '  - TRG_AUDITORIA_MATRICULA'
PROMPT '  - TRG_AUDITORIA_CALIFICACION'
PROMPT '  - TRG_AUDITORIA_USUARIO_SISTEMA'
PROMPT ''
PROMPT 'TRIGGERS DE VALIDACIÓN:'
PROMPT '  - TRG_VALIDAR_NOTA'
PROMPT '  - TRG_VALIDAR_PERIODO_VIGENTE'
PROMPT '  - TRG_VALIDAR_CUPO_GRUPO'
PROMPT '  - TRG_VALIDAR_HORARIO'
PROMPT '  - TRG_VALIDAR_CREDITOS_ASIGNATURA'
PROMPT '  - TRG_VALIDAR_FECHA_MATRICULA ← NUEVO'
PROMPT '  - TRG_VALIDAR_PREREQUISITOS ← NUEVO'
PROMPT ''
PROMPT 'TRIGGERS DE NEGOCIO:'
PROMPT '  - TRG_DETECTAR_RIESGO_ACADEMICO'
PROMPT '  - TRG_GENERAR_CODIGO_ESTUDIANTE'
PROMPT '  - TRG_GENERAR_CODIGO_DOCENTE'
PROMPT '  - TRG_BLOQUEAR_USUARIO'
PROMPT '  - TRG_LOG_ACCESO_USUARIO'
PROMPT '  - TRG_ACUMULAR_NOTA_DEFINITIVA ← NUEVO'
PROMPT ''
PROMPT '========================================='

-- Consultar todos los triggers creados
SELECT trigger_name, table_name, triggering_event, status
FROM user_triggers
WHERE trigger_name LIKE 'TRG_%'
ORDER BY trigger_name;
