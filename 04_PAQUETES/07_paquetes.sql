-- =====================================================
-- SISTEMA ACADÉMICO - ORACLE DATABASE 19c
-- Script: 07_paquetes.sql
-- Propósito: Paquetes PL/SQL para lógica de negocio
-- Autor: Sistema Académico
-- Fecha: 28/10/2025
-- =====================================================

-- =====================================================
-- PAQUETE: PKG_AUDITORIA
-- Propósito: Gestión centralizada de auditoría
-- =====================================================

CREATE OR REPLACE PACKAGE PKG_AUDITORIA AS
    -- Procedimiento para registrar operaciones de auditoría
    PROCEDURE registrar_auditoria(
        p_tabla IN VARCHAR2,
        p_operacion IN VARCHAR2,
        p_usuario IN VARCHAR2,
        p_valores_anteriores IN CLOB DEFAULT NULL,
        p_valores_nuevos IN CLOB DEFAULT NULL,
        p_sentencia_sql IN VARCHAR2 DEFAULT NULL
    );
    
    -- Función para obtener IP del cliente
    FUNCTION obtener_ip_cliente RETURN VARCHAR2;
    
    -- Procedimiento para limpiar auditoría antigua
    PROCEDURE limpiar_auditoria_antigua(
        p_dias_retencion IN NUMBER DEFAULT 365
    );
END PKG_AUDITORIA;
/

CREATE OR REPLACE PACKAGE BODY PKG_AUDITORIA AS
    
    -- ==================================================
    -- Función: obtener_ip_cliente
    -- Propósito: Obtiene la dirección IP del cliente
    -- ==================================================
    FUNCTION obtener_ip_cliente RETURN VARCHAR2 IS
        v_ip VARCHAR2(45);
    BEGIN
        SELECT SYS_CONTEXT('USERENV', 'IP_ADDRESS')
        INTO v_ip
        FROM DUAL;
        
        RETURN v_ip;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'UNKNOWN';
    END obtener_ip_cliente;
    
    -- ==================================================
    -- Procedimiento: registrar_auditoria
    -- Propósito: Registra operaciones DML en la tabla AUDITORIA
    -- ==================================================
    PROCEDURE registrar_auditoria(
        p_tabla IN VARCHAR2,
        p_operacion IN VARCHAR2,
        p_usuario IN VARCHAR2,
        p_valores_anteriores IN CLOB DEFAULT NULL,
        p_valores_nuevos IN CLOB DEFAULT NULL,
        p_sentencia_sql IN VARCHAR2 DEFAULT NULL
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        v_ip VARCHAR2(45);
    BEGIN
        -- Obtener IP del cliente
        v_ip := obtener_ip_cliente();
        
        -- Insertar registro de auditoría
        INSERT INTO AUDITORIA (
            tabla_afectada,
            operacion,
            usuario_bd,
            fecha_operacion,
            ip_origen,
            valores_anteriores,
            valores_nuevos,
            sentencia_sql
        ) VALUES (
            p_tabla,
            p_operacion,
            p_usuario,
            SYSTIMESTAMP,
            v_ip,
            p_valores_anteriores,
            p_valores_nuevos,
            SUBSTR(p_sentencia_sql, 1, 4000)
        );
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            -- Registrar error en log pero no abortar operación principal
            DBMS_OUTPUT.PUT_LINE('Error en auditoría: ' || SQLERRM);
            ROLLBACK;
    END registrar_auditoria;
    
    -- ==================================================
    -- Procedimiento: limpiar_auditoria_antigua
    -- Propósito: Elimina registros de auditoría antiguos
    -- ==================================================
    PROCEDURE limpiar_auditoria_antigua(
        p_dias_retencion IN NUMBER DEFAULT 365
    ) IS
        v_registros_eliminados NUMBER;
    BEGIN
        DELETE FROM AUDITORIA
        WHERE fecha_operacion < SYSTIMESTAMP - p_dias_retencion;
        
        v_registros_eliminados := SQL%ROWCOUNT;
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Registros de auditoría eliminados: ' || v_registros_eliminados);
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20001, 'Error al limpiar auditoría: ' || SQLERRM);
    END limpiar_auditoria_antigua;
    
END PKG_AUDITORIA;
/

PROMPT 'Paquete PKG_AUDITORIA creado exitosamente'

-- =====================================================
-- PAQUETE: PKG_MATRICULA
-- Propósito: Gestión de matrículas académicas
-- =====================================================

CREATE OR REPLACE PACKAGE PKG_MATRICULA AS
    -- Excepción personalizada
    ex_periodo_no_activo EXCEPTION;
    ex_estudiante_ya_matriculado EXCEPTION;
    ex_sin_cupos_disponibles EXCEPTION;
    ex_prerrequisito_faltante EXCEPTION;
    ex_conflicto_horario EXCEPTION;
    ex_creditos_excedidos EXCEPTION;
    ex_ventana_cerrada EXCEPTION;
    
    -- Procedimiento para crear matrícula
    PROCEDURE crear_matricula(
        p_cod_estudiante IN VARCHAR2,
        p_cod_periodo IN VARCHAR2,
        p_tipo_matricula IN VARCHAR2 DEFAULT 'ORDINARIA',
        p_valor_matricula IN NUMBER DEFAULT NULL,
        p_cod_matricula OUT NUMBER
    );
    
    -- Procedimiento para inscribir asignatura
    PROCEDURE inscribir_asignatura(
        p_cod_matricula IN NUMBER,
        p_cod_grupo IN NUMBER
    );
    
    -- Procedimiento para retirar asignatura
    PROCEDURE retirar_asignatura(
        p_cod_detalle_matricula IN NUMBER,
        p_motivo_retiro IN VARCHAR2
    );
    
    -- Función para validar prerrequisitos
    FUNCTION validar_prerrequisitos(
        p_cod_estudiante IN VARCHAR2,
        p_cod_asignatura IN VARCHAR2
    ) RETURN BOOLEAN;
    
    -- Función para validar conflicto de horario
    FUNCTION validar_conflicto_horario(
        p_cod_matricula IN NUMBER,
        p_cod_grupo IN NUMBER
    ) RETURN BOOLEAN;
    
    -- Función para validar ventana calendario activa
    FUNCTION ventana_activa(
        p_tipo_proceso IN VARCHAR2,
        p_fecha_actual IN DATE DEFAULT SYSDATE
    ) RETURN BOOLEAN;
    
    -- Función para validar créditos disponibles por riesgo
    FUNCTION validar_creditos_disponibles(
        p_cod_estudiante IN VARCHAR2,
        p_creditos_solicitud IN NUMBER
    ) RETURN BOOLEAN;
    
    -- Función para verificar cumplimiento de prerrequisitos
    FUNCTION cumple_prerequisitos(
        p_cod_estudiante IN VARCHAR2,
        p_cod_asignatura IN VARCHAR2
    ) RETURN BOOLEAN;
    
    -- Función para verificar choque de horario
    FUNCTION tiene_choque_horario(
        p_cod_matricula IN NUMBER,
        p_cod_grupo IN NUMBER
    ) RETURN BOOLEAN;
    
    -- Procedimiento para cancelar matrícula
    PROCEDURE cancelar_matricula(
        p_cod_matricula IN NUMBER
    );
    
    -- Función para calcular total de créditos matriculados
    FUNCTION calcular_creditos_matriculados(
        p_cod_matricula IN NUMBER
    ) RETURN NUMBER;
    
END PKG_MATRICULA;
/

CREATE OR REPLACE PACKAGE BODY PKG_MATRICULA AS
    
    -- ==================================================
    -- Función: ventana_activa
    -- Propósito: Verifica si hay ventana de calendario activa para proceso
    -- ==================================================
    FUNCTION ventana_activa(
        p_tipo_proceso IN VARCHAR2,
        p_fecha_actual IN DATE DEFAULT SYSDATE
    ) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM VENTANA_CALENDARIO
        WHERE tipo_ventana = p_tipo_proceso
        AND estado_ventana = 'ACTIVO'
        AND p_fecha_actual BETWEEN fecha_inicio AND fecha_fin;
        
        RETURN (v_count > 0);
    END ventana_activa;
    
    -- ==================================================
    -- Función: validar_creditos_disponibles
    -- Propósito: Verifica límite de créditos según nivel de riesgo
    -- ==================================================
    FUNCTION validar_creditos_disponibles(
        p_cod_estudiante IN VARCHAR2,
        p_creditos_solicitud IN NUMBER
    ) RETURN BOOLEAN IS
        v_nivel_riesgo VARCHAR2(20);
        v_creditos_maximos NUMBER;
        v_creditos_actuales NUMBER;
    BEGIN
        -- Obtener nivel de riesgo actual (más reciente)
        BEGIN
            SELECT nivel_riesgo
            INTO v_nivel_riesgo
            FROM (
                SELECT nivel_riesgo
                FROM HISTORIAL_RIESGO
                WHERE cod_estudiante = p_cod_estudiante
                ORDER BY fecha_deteccion DESC
            )
            WHERE ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_nivel_riesgo := 'BAJO'; -- Por defecto sin riesgo
        END;
        
        -- Determinar límite de créditos según riesgo
        CASE v_nivel_riesgo
            WHEN 'ALTO' THEN v_creditos_maximos := 12;
            WHEN 'MEDIO' THEN v_creditos_maximos := 16;
            ELSE v_creditos_maximos := 20; -- BAJO o sin registro
        END CASE;
        
        -- Obtener créditos ya matriculados en periodo actual
        BEGIN
            SELECT NVL(SUM(a.creditos), 0)
            INTO v_creditos_actuales
            FROM DETALLE_MATRICULA dm
            INNER JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
            INNER JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
            INNER JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
            INNER JOIN PERIODO_ACADEMICO pa ON m.cod_periodo = pa.cod_periodo
            WHERE m.cod_estudiante = p_cod_estudiante
            AND dm.estado_inscripcion = 'INSCRITO'
            AND pa.estado_periodo = 'EN_CURSO';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_creditos_actuales := 0;
        END;
        
        -- Verificar si solicitud excede límite
        RETURN ((v_creditos_actuales + p_creditos_solicitud) <= v_creditos_maximos);
    END validar_creditos_disponibles;
    
    -- ==================================================
    -- Función: cumple_prerequisitos
    -- Propósito: Verifica cumplimiento de prerrequisitos (alias)
    -- ==================================================
    FUNCTION cumple_prerequisitos(
        p_cod_estudiante IN VARCHAR2,
        p_cod_asignatura IN VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN validar_prerrequisitos(p_cod_estudiante, p_cod_asignatura);
    END cumple_prerequisitos;
    
    -- ==================================================
    -- Función: tiene_choque_horario
    -- Propósito: Verifica conflicto de horario (alias)
    -- ==================================================
    FUNCTION tiene_choque_horario(
        p_cod_matricula IN NUMBER,
        p_cod_grupo IN NUMBER
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN NOT validar_conflicto_horario(p_cod_matricula, p_cod_grupo);
    END tiene_choque_horario;
    
    -- ==================================================
    -- Función: validar_prerrequisitos
    -- Propósito: Verifica que el estudiante cumpla prerrequisitos
    -- ==================================================
    FUNCTION validar_prerrequisitos(
        p_cod_estudiante IN VARCHAR2,
        p_cod_asignatura IN VARCHAR2
    ) RETURN BOOLEAN IS
        v_prerrequisitos_pendientes NUMBER;
    BEGIN
        -- Contar prerrequisitos no cumplidos
        SELECT COUNT(*)
        INTO v_prerrequisitos_pendientes
        FROM PRERREQUISITO pr
        WHERE pr.cod_asignatura = p_cod_asignatura
        AND pr.tipo_requisito = 'OBLIGATORIO'
        AND NOT EXISTS (
            SELECT 1
            FROM DETALLE_MATRICULA dm
            INNER JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
            INNER JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
            INNER JOIN NOTA_DEFINITIVA nd ON dm.cod_detalle_matricula = nd.cod_detalle_matricula
            WHERE m.cod_estudiante = p_cod_estudiante
            AND g.cod_asignatura = pr.cod_asignatura_requisito
            AND nd.resultado = 'APROBADO'
        );
        
        RETURN (v_prerrequisitos_pendientes = 0);
    END validar_prerrequisitos;
    
    -- ==================================================
    -- Función: validar_conflicto_horario
    -- Propósito: Verifica que no haya cruce de horarios
    -- ==================================================
    FUNCTION validar_conflicto_horario(
        p_cod_matricula IN NUMBER,
        p_cod_grupo IN NUMBER
    ) RETURN BOOLEAN IS
        v_conflictos NUMBER;
    BEGIN
        -- Verificar conflictos de horario
        SELECT COUNT(*)
        INTO v_conflictos
        FROM HORARIO h1
        INNER JOIN GRUPO g1 ON h1.cod_grupo = g1.cod_grupo
        WHERE g1.cod_grupo = p_cod_grupo
        AND EXISTS (
            SELECT 1
            FROM DETALLE_MATRICULA dm
            INNER JOIN GRUPO g2 ON dm.cod_grupo = g2.cod_grupo
            INNER JOIN HORARIO h2 ON g2.cod_grupo = h2.cod_grupo
            WHERE dm.cod_matricula = p_cod_matricula
            AND dm.estado_inscripcion = 'INSCRITO'
            AND h1.dia_semana = h2.dia_semana
            AND (
                (h1.hora_inicio BETWEEN h2.hora_inicio AND h2.hora_fin)
                OR (h1.hora_fin BETWEEN h2.hora_inicio AND h2.hora_fin)
                OR (h2.hora_inicio BETWEEN h1.hora_inicio AND h1.hora_fin)
            )
        );
        
        RETURN (v_conflictos = 0);
    END validar_conflicto_horario;
    
    -- ==================================================
    -- Función: calcular_creditos_matriculados
    -- Propósito: Calcula total de créditos de una matrícula
    -- ==================================================
    FUNCTION calcular_creditos_matriculados(
        p_cod_matricula IN NUMBER
    ) RETURN NUMBER IS
        v_total_creditos NUMBER;
    BEGIN
        SELECT NVL(SUM(a.creditos), 0)
        INTO v_total_creditos
        FROM DETALLE_MATRICULA dm
        INNER JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
        INNER JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
        WHERE dm.cod_matricula = p_cod_matricula
        AND dm.estado_inscripcion IN ('INSCRITO', 'APROBADO', 'REPROBADO', 'PERDIDA');
        
        RETURN v_total_creditos;
    END calcular_creditos_matriculados;
    
    -- ==================================================
    -- Procedimiento: crear_matricula
    -- Propósito: Crea una nueva matrícula para un estudiante
    -- ==================================================
    PROCEDURE crear_matricula(
        p_cod_estudiante IN VARCHAR2,
        p_cod_periodo IN VARCHAR2,
        p_tipo_matricula IN VARCHAR2 DEFAULT 'ORDINARIA',
        p_valor_matricula IN NUMBER DEFAULT NULL,
        p_cod_matricula OUT NUMBER
    ) IS
        v_estado_periodo VARCHAR2(15);
        v_matricula_existente NUMBER;
        v_estado_estudiante VARCHAR2(15);
    BEGIN
        -- Validar que el periodo esté activo
        BEGIN
            SELECT estado_periodo
            INTO v_estado_periodo
            FROM PERIODO_ACADEMICO
            WHERE cod_periodo = p_cod_periodo;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20100, 'El periodo académico no existe');
        END;
        
        IF v_estado_periodo NOT IN ('PROGRAMADO', 'EN_CURSO') THEN
            RAISE ex_periodo_no_activo;
        END IF;
        
        -- Validar estado del estudiante
        BEGIN
            SELECT estado_estudiante
            INTO v_estado_estudiante
            FROM ESTUDIANTE
            WHERE cod_estudiante = p_cod_estudiante;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20101, 'El estudiante no existe');
        END;
        
        IF v_estado_estudiante NOT IN ('ACTIVO') THEN
            RAISE_APPLICATION_ERROR(-20102, 'El estudiante no está activo');
        END IF;
        
        -- Verificar que no exista matrícula para este periodo
        SELECT COUNT(*)
        INTO v_matricula_existente
        FROM MATRICULA
        WHERE cod_estudiante = p_cod_estudiante
        AND cod_periodo = p_cod_periodo
        AND estado_matricula != 'CANCELADA';
        
        IF v_matricula_existente > 0 THEN
            RAISE ex_estudiante_ya_matriculado;
        END IF;
        
        -- Crear matrícula
        INSERT INTO MATRICULA (
            cod_estudiante,
            cod_periodo,
            tipo_matricula,
            fecha_matricula,
            estado_matricula,
            total_creditos,
            valor_matricula
        ) VALUES (
            p_cod_estudiante,
            p_cod_periodo,
            p_tipo_matricula,
            SYSDATE,
            'ACTIVA',
            0,
            p_valor_matricula
        ) RETURNING cod_matricula INTO p_cod_matricula;
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Matrícula creada exitosamente: ' || p_cod_matricula);
        
    EXCEPTION
        WHEN ex_periodo_no_activo THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20103, 'El periodo académico no está activo para matrículas');
        WHEN ex_estudiante_ya_matriculado THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20104, 'El estudiante ya tiene matrícula activa para este periodo');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20105, 'Error al crear matrícula: ' || SQLERRM);
    END crear_matricula;
    
    -- ==================================================
    -- Procedimiento: inscribir_asignatura
    -- Propósito: Inscribe una asignatura a una matrícula
    -- ==================================================
    PROCEDURE inscribir_asignatura(
        p_cod_matricula IN NUMBER,
        p_cod_grupo IN NUMBER
    ) IS
        v_cupo_disponible NUMBER;
        v_cod_asignatura VARCHAR2(10);
        v_cod_estudiante VARCHAR2(15);
        v_inscripcion_existente NUMBER;
        v_total_creditos NUMBER;
        v_creditos_asignatura NUMBER;
    BEGIN
        -- Obtener información del grupo y matrícula
        BEGIN
            SELECT g.cupo_disponible, g.cod_asignatura, m.cod_estudiante, a.creditos
            INTO v_cupo_disponible, v_cod_asignatura, v_cod_estudiante, v_creditos_asignatura
            FROM GRUPO g
            INNER JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
            CROSS JOIN MATRICULA m
            WHERE g.cod_grupo = p_cod_grupo
            AND m.cod_matricula = p_cod_matricula;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20200, 'Grupo o matrícula no encontrados');
        END;
        
        -- Verificar ventana calendario activa
        IF NOT ventana_activa('MATRICULA') THEN
            RAISE ex_ventana_cerrada;
        END IF;
        
        -- Verificar cupos disponibles
        IF v_cupo_disponible <= 0 THEN
            RAISE ex_sin_cupos_disponibles;
        END IF;
        
        -- Verificar que no esté ya inscrito
        SELECT COUNT(*)
        INTO v_inscripcion_existente
        FROM DETALLE_MATRICULA
        WHERE cod_matricula = p_cod_matricula
        AND cod_grupo = p_cod_grupo;
        
        IF v_inscripcion_existente > 0 THEN
            RAISE_APPLICATION_ERROR(-20201, 'Ya está inscrito en este grupo');
        END IF;
        
        -- Validar créditos disponibles según riesgo
        IF NOT validar_creditos_disponibles(v_cod_estudiante, v_creditos_asignatura) THEN
            RAISE ex_creditos_excedidos;
        END IF;
        
        -- Validar prerrequisitos
        IF NOT validar_prerrequisitos(v_cod_estudiante, v_cod_asignatura) THEN
            RAISE ex_prerrequisito_faltante;
        END IF;
        
        -- Validar conflicto de horario
        IF NOT validar_conflicto_horario(p_cod_matricula, p_cod_grupo) THEN
            RAISE ex_conflicto_horario;
        END IF;
        
        -- Inscribir asignatura
        INSERT INTO DETALLE_MATRICULA (
            cod_matricula,
            cod_grupo,
            fecha_inscripcion,
            estado_inscripcion
        ) VALUES (
            p_cod_matricula,
            p_cod_grupo,
            SYSDATE,
            'INSCRITO'
        );
        
        -- Actualizar cupo disponible del grupo
        UPDATE GRUPO
        SET cupo_disponible = cupo_disponible - 1
        WHERE cod_grupo = p_cod_grupo;
        
        -- Actualizar total de créditos de la matrícula
        v_total_creditos := calcular_creditos_matriculados(p_cod_matricula);
        
        UPDATE MATRICULA
        SET total_creditos = v_total_creditos
        WHERE cod_matricula = p_cod_matricula;
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Asignatura inscrita exitosamente');
        
    EXCEPTION
        WHEN ex_ventana_cerrada THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20206, 'Ventana de matrícula cerrada');
        WHEN ex_sin_cupos_disponibles THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20202, 'El grupo no tiene cupos disponibles');
        WHEN ex_creditos_excedidos THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20207, 'Excede el límite de créditos permitidos según su nivel de riesgo');
        WHEN ex_prerrequisito_faltante THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20203, 'No cumple con los prerrequisitos de la asignatura');
        WHEN ex_conflicto_horario THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20204, 'Existe conflicto de horario con otra asignatura matriculada');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20205, 'Error al inscribir asignatura: ' || SQLERRM);
    END inscribir_asignatura;
    
    -- ==================================================
    -- Procedimiento: retirar_asignatura
    -- Propósito: Retira una asignatura de la matrícula
    -- ==================================================
    PROCEDURE retirar_asignatura(
        p_cod_detalle_matricula IN NUMBER,
        p_motivo_retiro IN VARCHAR2
    ) IS
        v_cod_grupo NUMBER;
        v_cod_matricula NUMBER;
        v_estado_actual VARCHAR2(20);
        v_total_creditos NUMBER;
    BEGIN
        -- Obtener información del detalle
        BEGIN
            SELECT cod_grupo, cod_matricula, estado_inscripcion
            INTO v_cod_grupo, v_cod_matricula, v_estado_actual
            FROM DETALLE_MATRICULA
            WHERE cod_detalle_matricula = p_cod_detalle_matricula;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20300, 'Detalle de matrícula no encontrado');
        END;
        
        -- Validar que esté inscrito
        IF v_estado_actual != 'INSCRITO' THEN
            RAISE_APPLICATION_ERROR(-20301, 'Solo se pueden retirar asignaturas en estado INSCRITO');
        END IF;
        
        -- Actualizar estado a retirado
        UPDATE DETALLE_MATRICULA
        SET estado_inscripcion = 'RETIRADO',
            fecha_retiro = SYSDATE,
            motivo_retiro = p_motivo_retiro
        WHERE cod_detalle_matricula = p_cod_detalle_matricula;
        
        -- Devolver cupo al grupo
        UPDATE GRUPO
        SET cupo_disponible = cupo_disponible + 1
        WHERE cod_grupo = v_cod_grupo;
        
        -- Actualizar total de créditos
        v_total_creditos := calcular_creditos_matriculados(v_cod_matricula);
        
        UPDATE MATRICULA
        SET total_creditos = v_total_creditos
        WHERE cod_matricula = v_cod_matricula;
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Asignatura retirada exitosamente');
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20302, 'Error al retirar asignatura: ' || SQLERRM);
    END retirar_asignatura;
    
    -- ==================================================
    -- Procedimiento: cancelar_matricula
    -- Propósito: Cancela una matrícula completa
    -- ==================================================
    PROCEDURE cancelar_matricula(
        p_cod_matricula IN NUMBER
    ) IS
        v_estado_actual VARCHAR2(20);
    BEGIN
        -- Obtener estado actual
        BEGIN
            SELECT estado_matricula
            INTO v_estado_actual
            FROM MATRICULA
            WHERE cod_matricula = p_cod_matricula;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20400, 'Matrícula no encontrada');
        END;
        
        IF v_estado_actual = 'CANCELADA' THEN
            RAISE_APPLICATION_ERROR(-20401, 'La matrícula ya está cancelada');
        END IF;
        
        -- Devolver cupos de todos los grupos
        UPDATE GRUPO g
        SET g.cupo_disponible = g.cupo_disponible + 1
        WHERE g.cod_grupo IN (
            SELECT dm.cod_grupo
            FROM DETALLE_MATRICULA dm
            WHERE dm.cod_matricula = p_cod_matricula
            AND dm.estado_inscripcion = 'INSCRITO'
        );
        
        -- Marcar detalle como retirado
        UPDATE DETALLE_MATRICULA
        SET estado_inscripcion = 'RETIRADO',
            fecha_retiro = SYSDATE,
            motivo_retiro = 'CANCELACIÓN DE MATRÍCULA'
        WHERE cod_matricula = p_cod_matricula
        AND estado_inscripcion = 'INSCRITO';
        
        -- Cancelar matrícula
        UPDATE MATRICULA
        SET estado_matricula = 'CANCELADA',
            total_creditos = 0
        WHERE cod_matricula = p_cod_matricula;
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Matrícula cancelada exitosamente');
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20402, 'Error al cancelar matrícula: ' || SQLERRM);
    END cancelar_matricula;
    
END PKG_MATRICULA;
/

PROMPT 'Paquete PKG_MATRICULA creado exitosamente'

-- =====================================================
-- PAQUETE: PKG_CALIFICACION
-- Propósito: Gestión de calificaciones y notas definitivas
-- =====================================================

CREATE OR REPLACE PACKAGE PKG_CALIFICACION AS
    -- Procedimiento para registrar calificación
    PROCEDURE registrar_calificacion(
        p_cod_detalle_matricula IN NUMBER,
        p_cod_tipo_actividad IN NUMBER,
        p_numero_actividad IN NUMBER,
        p_nota IN NUMBER,
        p_observaciones IN VARCHAR2 DEFAULT NULL
    );
    
    -- Procedimiento para actualizar calificación
    PROCEDURE actualizar_calificacion(
        p_cod_calificacion IN NUMBER,
        p_nota IN NUMBER,
        p_observaciones IN VARCHAR2 DEFAULT NULL
    );
    
    -- Función para calcular nota definitiva
    FUNCTION calcular_nota_definitiva(
        p_cod_detalle_matricula IN NUMBER
    ) RETURN NUMBER;
    
    -- Procedimiento para generar nota definitiva
    PROCEDURE generar_nota_definitiva(
        p_cod_detalle_matricula IN NUMBER
    );
    
    -- Procedimiento para calcular notas de un grupo (cerrar notas)
    PROCEDURE calcular_notas_grupo(
        p_cod_grupo IN NUMBER
    );
    
    -- Procedimiento para cerrar notas de grupo (alias)
    PROCEDURE cerrar_notas_grupo(
        p_cod_grupo IN NUMBER
    );
    
    -- Función para validar reglas de evaluación (suma 100%)
    FUNCTION validar_reglas_evaluacion(
        p_cod_asignatura IN VARCHAR2
    ) RETURN BOOLEAN;
    
    -- Función para obtener promedio del estudiante
    FUNCTION obtener_promedio_estudiante(
        p_cod_estudiante IN VARCHAR2,
        p_cod_periodo IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER;
    
END PKG_CALIFICACION;
/

CREATE OR REPLACE PACKAGE BODY PKG_CALIFICACION AS
    
    -- ==================================================
    -- Función: validar_reglas_evaluacion
    -- Propósito: Verifica que reglas de evaluación sumen 100%
    -- ==================================================
    FUNCTION validar_reglas_evaluacion(
        p_cod_asignatura IN VARCHAR2
    ) RETURN BOOLEAN IS
        v_suma_porcentajes NUMBER;
    BEGIN
        SELECT NVL(SUM(porcentaje), 0)
        INTO v_suma_porcentajes
        FROM REGLA_EVALUACION
        WHERE cod_asignatura = p_cod_asignatura;
        
        RETURN (v_suma_porcentajes = 100);
    END validar_reglas_evaluacion;
    
    -- ==================================================
    -- Procedimiento: cerrar_notas_grupo
    -- Propósito: Alias para calcular_notas_grupo
    -- ==================================================
    PROCEDURE cerrar_notas_grupo(
        p_cod_grupo IN NUMBER
    ) IS
    BEGIN
        calcular_notas_grupo(p_cod_grupo);
    END cerrar_notas_grupo;
    
    -- ==================================================
    -- Procedimiento: registrar_calificacion
    -- Propósito: Registra una calificación individual
    -- ==================================================
    PROCEDURE registrar_calificacion(
        p_cod_detalle_matricula IN NUMBER,
        p_cod_tipo_actividad IN NUMBER,
        p_numero_actividad IN NUMBER,
        p_nota IN NUMBER,
        p_observaciones IN VARCHAR2 DEFAULT NULL
    ) IS
        v_cod_asignatura VARCHAR2(10);
        v_porcentaje NUMBER;
        v_estado_inscripcion VARCHAR2(20);
    BEGIN
        -- Validar nota (0.0 a 5.0)
        IF p_nota < 0 OR p_nota > 5 THEN
            RAISE_APPLICATION_ERROR(-20500, 'La nota debe estar entre 0.0 y 5.0');
        END IF;
        
        -- Obtener asignatura y validar estado
        SELECT g.cod_asignatura, dm.estado_inscripcion
        INTO v_cod_asignatura, v_estado_inscripcion
        FROM DETALLE_MATRICULA dm
        INNER JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
        WHERE dm.cod_detalle_matricula = p_cod_detalle_matricula;
        
        IF v_estado_inscripcion NOT IN ('INSCRITO') THEN
            RAISE_APPLICATION_ERROR(-20501, 'Solo se pueden calificar asignaturas en estado INSCRITO');
        END IF;
        
        -- Obtener porcentaje de la regla de evaluación
        BEGIN
            SELECT porcentaje
            INTO v_porcentaje
            FROM REGLA_EVALUACION
            WHERE cod_asignatura = v_cod_asignatura
            AND cod_tipo_actividad = p_cod_tipo_actividad;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_porcentaje := NULL;
        END;
        
        -- Insertar calificación
        INSERT INTO CALIFICACION (
            cod_detalle_matricula,
            cod_tipo_actividad,
            numero_actividad,
            nota,
            porcentaje_aplicado,
            fecha_calificacion,
            observaciones
        ) VALUES (
            p_cod_detalle_matricula,
            p_cod_tipo_actividad,
            p_numero_actividad,
            p_nota,
            v_porcentaje,
            SYSDATE,
            p_observaciones
        );
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Calificación registrada exitosamente');
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20502, 'Error al registrar calificación: ' || SQLERRM);
    END registrar_calificacion;
    
    -- ==================================================
    -- Procedimiento: actualizar_calificacion
    -- Propósito: Actualiza una calificación existente
    -- ==================================================
    PROCEDURE actualizar_calificacion(
        p_cod_calificacion IN NUMBER,
        p_nota IN NUMBER,
        p_observaciones IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        -- Validar nota
        IF p_nota < 0 OR p_nota > 5 THEN
            RAISE_APPLICATION_ERROR(-20510, 'La nota debe estar entre 0.0 y 5.0');
        END IF;
        
        -- Actualizar calificación
        UPDATE CALIFICACION
        SET nota = p_nota,
            observaciones = NVL(p_observaciones, observaciones),
            fecha_calificacion = SYSDATE
        WHERE cod_calificacion = p_cod_calificacion;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20511, 'Calificación no encontrada');
        END IF;
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Calificación actualizada exitosamente');
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20512, 'Error al actualizar calificación: ' || SQLERRM);
    END actualizar_calificacion;
    
    -- ==================================================
    -- Función: calcular_nota_definitiva
    -- Propósito: Calcula la nota definitiva ponderada
    -- ==================================================
    FUNCTION calcular_nota_definitiva(
        p_cod_detalle_matricula IN NUMBER
    ) RETURN NUMBER IS
        v_nota_definitiva NUMBER;
    BEGIN
        -- Calcular promedio ponderado
        SELECT NVL(SUM(c.nota * c.porcentaje_aplicado / 100), 0)
        INTO v_nota_definitiva
        FROM CALIFICACION c
        WHERE c.cod_detalle_matricula = p_cod_detalle_matricula;
        
        RETURN ROUND(v_nota_definitiva, 1);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END calcular_nota_definitiva;
    
    -- ==================================================
    -- Procedimiento: generar_nota_definitiva
    -- Propósito: Genera o actualiza la nota definitiva
    -- ==================================================
    PROCEDURE generar_nota_definitiva(
        p_cod_detalle_matricula IN NUMBER
    ) IS
        v_nota_final NUMBER;
        v_resultado VARCHAR2(15);
        v_nota_existente NUMBER;
    BEGIN
        -- Calcular nota definitiva
        v_nota_final := calcular_nota_definitiva(p_cod_detalle_matricula);
        
        -- Determinar resultado
        IF v_nota_final >= 3.0 THEN
            v_resultado := 'APROBADO';
        ELSE
            v_resultado := 'PERDIDA';
        END IF;
        
        -- Verificar si ya existe registro
        BEGIN
            SELECT cod_nota_definitiva
            INTO v_nota_existente
            FROM NOTA_DEFINITIVA
            WHERE cod_detalle_matricula = p_cod_detalle_matricula;
            
            -- Actualizar existente
            UPDATE NOTA_DEFINITIVA
            SET nota_final = v_nota_final,
                resultado = v_resultado,
                fecha_calculo = SYSDATE
            WHERE cod_detalle_matricula = p_cod_detalle_matricula;
            
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- Insertar nuevo registro
                INSERT INTO NOTA_DEFINITIVA (
                    cod_detalle_matricula,
                    nota_final,
                    resultado,
                    fecha_calculo
                ) VALUES (
                    p_cod_detalle_matricula,
                    v_nota_final,
                    v_resultado,
                    SYSDATE
                );
        END;
        
        -- Actualizar estado de inscripción
        UPDATE DETALLE_MATRICULA
        SET estado_inscripcion = v_resultado
        WHERE cod_detalle_matricula = p_cod_detalle_matricula;
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Nota definitiva: ' || v_nota_final || ' - ' || v_resultado);
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20520, 'Error al generar nota definitiva: ' || SQLERRM);
    END generar_nota_definitiva;
    
    -- ==================================================
    -- Procedimiento: calcular_notas_grupo
    -- Propósito: Calcula notas definitivas de todo un grupo
    -- ==================================================
    PROCEDURE calcular_notas_grupo(
        p_cod_grupo IN NUMBER
    ) IS
        CURSOR cur_detalles IS
            SELECT cod_detalle_matricula
            FROM DETALLE_MATRICULA
            WHERE cod_grupo = p_cod_grupo
            AND estado_inscripcion = 'INSCRITO';
        
        v_contador NUMBER := 0;
    BEGIN
        FOR rec IN cur_detalles LOOP
            generar_nota_definitiva(rec.cod_detalle_matricula);
            v_contador := v_contador + 1;
        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE('Notas calculadas para ' || v_contador || ' estudiantes');
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20530, 'Error al calcular notas del grupo: ' || SQLERRM);
    END calcular_notas_grupo;
    
    -- ==================================================
    -- Función: obtener_promedio_estudiante
    -- Propósito: Calcula el promedio general del estudiante
    -- ==================================================
    FUNCTION obtener_promedio_estudiante(
        p_cod_estudiante IN VARCHAR2,
        p_cod_periodo IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER IS
        v_promedio NUMBER;
    BEGIN
        IF p_cod_periodo IS NULL THEN
            -- Promedio general
            SELECT ROUND(AVG(nd.nota_final), 2)
            INTO v_promedio
            FROM NOTA_DEFINITIVA nd
            INNER JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
            INNER JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
            WHERE m.cod_estudiante = p_cod_estudiante
            AND nd.resultado IN ('APROBADO', 'REPROBADO', 'PERDIDA');
        ELSE
            -- Promedio por periodo
            SELECT ROUND(AVG(nd.nota_final), 2)
            INTO v_promedio
            FROM NOTA_DEFINITIVA nd
            INNER JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
            INNER JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
            WHERE m.cod_estudiante = p_cod_estudiante
            AND m.cod_periodo = p_cod_periodo
            AND nd.resultado IN ('APROBADO', 'REPROBADO', 'PERDIDA');
        END IF;
        
        RETURN NVL(v_promedio, 0);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END obtener_promedio_estudiante;
    
END PKG_CALIFICACION;
/

PROMPT 'Paquete PKG_CALIFICACION creado exitosamente'

-- =====================================================
-- PAQUETE: PKG_RIESGO_ACADEMICO
-- Propósito: Gestión de riesgo académico y clasificación
-- =====================================================

CREATE OR REPLACE PACKAGE PKG_RIESGO_ACADEMICO AS
    -- Procedimiento para clasificar riesgo de estudiante
    PROCEDURE clasificar_riesgo(
        p_cod_estudiante IN VARCHAR2
    );
    
    -- Procedimiento para actualizar riesgo de todos los estudiantes
    PROCEDURE actualizar_riesgo_todos;
    
    -- Función para calcular nivel de riesgo
    FUNCTION calcular_nivel_riesgo(
        p_promedio IN NUMBER,
        p_materias_reprobadas IN NUMBER
    ) RETURN VARCHAR2;
    
    -- Función para obtener nivel de riesgo actual
    FUNCTION obtener_riesgo_actual(
        p_cod_estudiante IN VARCHAR2
    ) RETURN VARCHAR2;
    
END PKG_RIESGO_ACADEMICO;
/

CREATE OR REPLACE PACKAGE BODY PKG_RIESGO_ACADEMICO AS
    
    -- ==================================================
    -- Función: calcular_nivel_riesgo
    -- Propósito: Determina nivel de riesgo según promedio y reprobadas
    -- ==================================================
    FUNCTION calcular_nivel_riesgo(
        p_promedio IN NUMBER,
        p_materias_reprobadas IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
        -- Riesgo alto: promedio < 3.0 o más de 2 materias reprobadas
        IF p_promedio < 3.0 OR p_materias_reprobadas > 2 THEN
            RETURN 'ALTO';
        -- Riesgo medio: promedio entre 3.0 y 3.5 o 1-2 materias reprobadas
        ELSIF p_promedio BETWEEN 3.0 AND 3.5 OR p_materias_reprobadas BETWEEN 1 AND 2 THEN
            RETURN 'MEDIO';
        -- Riesgo bajo: promedio > 3.5 y sin reprobadas
        ELSE
            RETURN 'BAJO';
        END IF;
    END calcular_nivel_riesgo;
    
    -- ==================================================
    -- Función: obtener_riesgo_actual
    -- Propósito: Obtiene nivel de riesgo más reciente
    -- ==================================================
    FUNCTION obtener_riesgo_actual(
        p_cod_estudiante IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_nivel_riesgo VARCHAR2(20);
    BEGIN
        SELECT nivel_riesgo
        INTO v_nivel_riesgo
        FROM (
            SELECT nivel_riesgo
            FROM HISTORIAL_RIESGO
            WHERE cod_estudiante = p_cod_estudiante
            ORDER BY fecha_deteccion DESC
        )
        WHERE ROWNUM = 1;
        
        RETURN v_nivel_riesgo;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'BAJO'; -- Sin historial = sin riesgo
    END obtener_riesgo_actual;
    
    -- ==================================================
    -- Procedimiento: clasificar_riesgo
    -- Propósito: Calcula y registra riesgo académico de un estudiante
    -- ==================================================
    PROCEDURE clasificar_riesgo(
        p_cod_estudiante IN VARCHAR2
    ) IS
        v_promedio NUMBER;
        v_materias_reprobadas NUMBER;
        v_nivel_riesgo VARCHAR2(20);
        v_riesgo_anterior VARCHAR2(20);
        v_cod_periodo VARCHAR2(10);
    BEGIN
        -- Obtener periodo actual activo
        BEGIN
            SELECT cod_periodo
            INTO v_cod_periodo
            FROM (
                SELECT cod_periodo
                FROM PERIODO_ACADEMICO
                WHERE estado_periodo = 'EN_CURSO'
                ORDER BY fecha_inicio DESC
            )
            WHERE ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- Si no hay periodo activo, usar el más reciente
                SELECT cod_periodo
                INTO v_cod_periodo
                FROM (
                    SELECT cod_periodo
                    FROM PERIODO_ACADEMICO
                    ORDER BY fecha_inicio DESC
                )
                WHERE ROWNUM = 1;
        END;
        
        -- Calcular promedio general
            SELECT NVL(ROUND(AVG(nd.nota_final), 2), 0)
        INTO v_promedio
        FROM NOTA_DEFINITIVA nd
        INNER JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
        INNER JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
        WHERE m.cod_estudiante = p_cod_estudiante
        AND nd.resultado IN ('APROBADO', 'REPROBADO', 'PERDIDA');
        
        -- Contar materias reprobadas
        SELECT NVL(COUNT(*), 0)
        INTO v_materias_reprobadas
        FROM NOTA_DEFINITIVA nd
        INNER JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
        INNER JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
        WHERE m.cod_estudiante = p_cod_estudiante
        AND nd.resultado IN ('REPROBADO', 'PERDIDA');
        
        -- Calcular nivel de riesgo
        v_nivel_riesgo := calcular_nivel_riesgo(v_promedio, v_materias_reprobadas);
        
        -- Obtener riesgo anterior
        BEGIN
            v_riesgo_anterior := obtener_riesgo_actual(p_cod_estudiante);
        EXCEPTION
            WHEN OTHERS THEN
                v_riesgo_anterior := NULL;
        END;
        
        -- Solo insertar si cambió el nivel o es la primera vez
        IF v_riesgo_anterior IS NULL OR v_riesgo_anterior != v_nivel_riesgo THEN
            INSERT INTO HISTORIAL_RIESGO (
                cod_estudiante,
                cod_periodo,
                tipo_riesgo,
                nivel_riesgo,
                promedio_periodo,
                asignaturas_reprobadas,
                estado_seguimiento,
                observaciones
            ) VALUES (
                p_cod_estudiante,
                v_cod_periodo,
                'ACADEMICO',
                v_nivel_riesgo,
                v_promedio,
                v_materias_reprobadas,
                'ACTIVO',
                'Actualización automática'
            );
            
            COMMIT;
            
            DBMS_OUTPUT.PUT_LINE('Riesgo actualizado: ' || v_nivel_riesgo || ' (Promedio: ' || v_promedio || ')');
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20600, 'Error al clasificar riesgo: ' || SQLERRM);
    END clasificar_riesgo;
    
    -- ==================================================
    -- Procedimiento: actualizar_riesgo_todos
    -- Propósito: Actualiza riesgo de todos los estudiantes activos
    -- ==================================================
    PROCEDURE actualizar_riesgo_todos IS
        CURSOR cur_estudiantes IS
            SELECT cod_estudiante
            FROM ESTUDIANTE
            WHERE estado_estudiante = 'ACTIVO';
        
        v_contador NUMBER := 0;
    BEGIN
        FOR rec IN cur_estudiantes LOOP
            clasificar_riesgo(rec.cod_estudiante);
            v_contador := v_contador + 1;
        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE('Riesgo actualizado para ' || v_contador || ' estudiantes');
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20601, 'Error al actualizar todos los riesgos: ' || SQLERRM);
    END actualizar_riesgo_todos;
    
END PKG_RIESGO_ACADEMICO;
/

PROMPT 'Paquete PKG_RIESGO_ACADEMICO creado exitosamente'

-- =====================================================
-- ASIGNACIÓN DE PRIVILEGIOS DE EJECUCIÓN
-- =====================================================

GRANT EXECUTE ON PKG_AUDITORIA TO ROL_ADMINISTRADOR;
GRANT EXECUTE ON PKG_MATRICULA TO ROL_REGISTRO_ACADEMICO;
GRANT EXECUTE ON PKG_MATRICULA TO ROL_COORDINADOR_ACADEMICO;
GRANT EXECUTE ON PKG_CALIFICACION TO ROL_DOCENTE;
GRANT EXECUTE ON PKG_CALIFICACION TO ROL_COORDINADOR_ACADEMICO;
GRANT EXECUTE ON PKG_CALIFICACION TO ROL_ADMINISTRADOR;
GRANT EXECUTE ON PKG_RIESGO_ACADEMICO TO ROL_COORDINADOR_ACADEMICO;
GRANT EXECUTE ON PKG_RIESGO_ACADEMICO TO ROL_ADMINISTRADOR;

PROMPT '========================================='
PROMPT 'Paquetes PL/SQL creados exitosamente'
PROMPT 'PKG_AUDITORIA - Gestión de auditoría'
PROMPT 'PKG_MATRICULA - Gestión de matrículas'
PROMPT 'PKG_CALIFICACION - Gestión de calificaciones'
PROMPT 'PKG_RIESGO_ACADEMICO - Clasificación de riesgo'
PROMPT '========================================='
