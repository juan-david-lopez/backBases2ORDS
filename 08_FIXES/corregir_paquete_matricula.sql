-- =====================================================
-- CORRECCIÓN DEL PAQUETE PKG_MATRICULA
-- Agrega procedimiento agregar_asignatura que falta
-- =====================================================

PROMPT 'Agregando procedimiento agregar_asignatura al paquete PKG_MATRICULA...'

-- Agregar la especificación del procedimiento al package
CREATE OR REPLACE PACKAGE PKG_MATRICULA AS
    -- Excepciones personalizadas
    ex_periodo_no_activo EXCEPTION;
    ex_estudiante_ya_matriculado EXCEPTION;
    ex_sin_cupos_disponibles EXCEPTION;
    ex_prerrequisito_faltante EXCEPTION;
    ex_conflicto_horario EXCEPTION;
    
    -- Procedimiento para crear matrícula
    PROCEDURE crear_matricula(
        p_cod_estudiante IN VARCHAR2,
        p_cod_periodo IN VARCHAR2,
        p_tipo_matricula IN VARCHAR2 DEFAULT 'ORDINARIA',
        p_valor_matricula IN NUMBER DEFAULT NULL,
        p_cod_matricula OUT NUMBER
    );
    
    -- Procedimiento para inscribir asignatura (original)
    PROCEDURE inscribir_asignatura(
        p_cod_matricula IN NUMBER,
        p_cod_grupo IN NUMBER
    );
    
    -- *** NUEVO PROCEDIMIENTO *** wrapper para endpoints
    PROCEDURE agregar_asignatura(
        p_cod_matricula IN NUMBER,
        p_cod_grupo IN NUMBER,
        p_mensaje OUT VARCHAR2
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

PROMPT 'Especificación del paquete actualizada'

-- Actualizar el cuerpo del paquete con el nuevo procedimiento
CREATE OR REPLACE PACKAGE BODY PKG_MATRICULA AS
    
    -- ==================================================
    -- Función: validar_prerrequisitos
    -- ==================================================
    FUNCTION validar_prerrequisitos(
        p_cod_estudiante IN VARCHAR2,
        p_cod_asignatura IN VARCHAR2
    ) RETURN BOOLEAN IS
        v_prerrequisitos_pendientes NUMBER;
    BEGIN
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
    -- ==================================================
    FUNCTION validar_conflicto_horario(
        p_cod_matricula IN NUMBER,
        p_cod_grupo IN NUMBER
    ) RETURN BOOLEAN IS
        v_conflictos NUMBER;
    BEGIN
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
        AND dm.estado_inscripcion IN ('INSCRITO', 'APROBADO', 'REPROBADO');
        
        RETURN v_total_creditos;
    END calcular_creditos_matriculados;
    
    -- ==================================================
    -- Procedimiento: crear_matricula
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
        
        SELECT COUNT(*)
        INTO v_matricula_existente
        FROM MATRICULA
        WHERE cod_estudiante = p_cod_estudiante
        AND cod_periodo = p_cod_periodo
        AND estado_matricula != 'CANCELADA';
        
        IF v_matricula_existente > 0 THEN
            RAISE ex_estudiante_ya_matriculado;
        END IF;
        
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
    -- Procedimiento: inscribir_asignatura (ORIGINAL)
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
    BEGIN
        BEGIN
            SELECT g.cupo_disponible, g.cod_asignatura, m.cod_estudiante
            INTO v_cupo_disponible, v_cod_asignatura, v_cod_estudiante
            FROM GRUPO g, MATRICULA m
            WHERE g.cod_grupo = p_cod_grupo
            AND m.cod_matricula = p_cod_matricula;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20200, 'Grupo o matrícula no encontrados');
        END;
        
        IF v_cupo_disponible <= 0 THEN
            RAISE ex_sin_cupos_disponibles;
        END IF;
        
        SELECT COUNT(*)
        INTO v_inscripcion_existente
        FROM DETALLE_MATRICULA
        WHERE cod_matricula = p_cod_matricula
        AND cod_grupo = p_cod_grupo;
        
        IF v_inscripcion_existente > 0 THEN
            RAISE_APPLICATION_ERROR(-20201, 'Ya está inscrito en este grupo');
        END IF;
        
        IF NOT validar_prerrequisitos(v_cod_estudiante, v_cod_asignatura) THEN
            RAISE ex_prerrequisito_faltante;
        END IF;
        
        IF NOT validar_conflicto_horario(p_cod_matricula, p_cod_grupo) THEN
            RAISE ex_conflicto_horario;
        END IF;
        
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
        
        UPDATE GRUPO
        SET cupo_disponible = cupo_disponible - 1
        WHERE cod_grupo = p_cod_grupo;
        
        v_total_creditos := calcular_creditos_matriculados(p_cod_matricula);
        
        UPDATE MATRICULA
        SET total_creditos = v_total_creditos
        WHERE cod_matricula = p_cod_matricula;
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Asignatura inscrita exitosamente');
        
    EXCEPTION
        WHEN ex_sin_cupos_disponibles THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20202, 'El grupo no tiene cupos disponibles');
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
    -- *** NUEVO PROCEDIMIENTO: agregar_asignatura ***
    -- Wrapper para endpoints REST que devuelve mensaje
    -- ==================================================
    PROCEDURE agregar_asignatura(
        p_cod_matricula IN NUMBER,
        p_cod_grupo IN NUMBER,
        p_mensaje OUT VARCHAR2
    ) IS
        v_nombre_asignatura VARCHAR2(200);
        v_codigo_asignatura VARCHAR2(10);
    BEGIN
        -- Obtener información de la asignatura
        SELECT a.cod_asignatura, a.nombre_asignatura
        INTO v_codigo_asignatura, v_nombre_asignatura
        FROM GRUPO g
        JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
        WHERE g.cod_grupo = p_cod_grupo;
        
        -- Llamar al procedimiento original
        inscribir_asignatura(p_cod_matricula, p_cod_grupo);
        
        -- Construir mensaje de éxito
        p_mensaje := 'Asignatura ' || v_codigo_asignatura || ' - ' || 
                     v_nombre_asignatura || ' agregada exitosamente a la matrícula ' || 
                     p_cod_matricula;
                     
        DBMS_OUTPUT.PUT_LINE(p_mensaje);
        
    EXCEPTION
        WHEN OTHERS THEN
            p_mensaje := 'Error: ' || SQLERRM;
            RAISE;
    END agregar_asignatura;
    
    -- ==================================================
    -- Procedimiento: retirar_asignatura
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
        BEGIN
            SELECT cod_grupo, cod_matricula, estado_inscripcion
            INTO v_cod_grupo, v_cod_matricula, v_estado_actual
            FROM DETALLE_MATRICULA
            WHERE cod_detalle_matricula = p_cod_detalle_matricula;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20300, 'Detalle de matrícula no encontrado');
        END;
        
        IF v_estado_actual != 'INSCRITO' THEN
            RAISE_APPLICATION_ERROR(-20301, 'Solo se pueden retirar asignaturas en estado INSCRITO');
        END IF;
        
        UPDATE DETALLE_MATRICULA
        SET estado_inscripcion = 'RETIRADO',
            fecha_retiro = SYSDATE,
            motivo_retiro = p_motivo_retiro
        WHERE cod_detalle_matricula = p_cod_detalle_matricula;
        
        UPDATE GRUPO
        SET cupo_disponible = cupo_disponible + 1
        WHERE cod_grupo = v_cod_grupo;
        
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
    -- ==================================================
    PROCEDURE cancelar_matricula(
        p_cod_matricula IN NUMBER
    ) IS
        v_estado_actual VARCHAR2(20);
    BEGIN
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
        
        UPDATE GRUPO g
        SET g.cupo_disponible = g.cupo_disponible + 1
        WHERE g.cod_grupo IN (
            SELECT dm.cod_grupo
            FROM DETALLE_MATRICULA dm
            WHERE dm.cod_matricula = p_cod_matricula
            AND dm.estado_inscripcion = 'INSCRITO'
        );
        
        UPDATE DETALLE_MATRICULA
        SET estado_inscripcion = 'RETIRADO',
            fecha_retiro = SYSDATE,
            motivo_retiro = 'CANCELACIÓN DE MATRÍCULA'
        WHERE cod_matricula = p_cod_matricula
        AND estado_inscripcion = 'INSCRITO';
        
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

PROMPT ''
PROMPT '========================================='
PROMPT 'PAQUETE PKG_MATRICULA ACTUALIZADO'
PROMPT '========================================='
PROMPT ''
PROMPT 'Se agregó el procedimiento:'
PROMPT '  - agregar_asignatura(cod_matricula, cod_grupo, mensaje OUT)'
PROMPT ''
PROMPT 'Este procedimiento es un wrapper de inscribir_asignatura'
PROMPT 'que devuelve un mensaje de éxito para los endpoints REST'
PROMPT ''
PROMPT 'Ejecutando prueba...'
PROMPT ''

-- Probar el nuevo procedimiento
DECLARE
    v_mensaje VARCHAR2(500);
BEGIN
    PKG_MATRICULA.agregar_asignatura(
        p_cod_matricula => 1,
        p_cod_grupo => 7,
        p_mensaje => v_mensaje
    );
    
    DBMS_OUTPUT.PUT_LINE('✓ Prueba exitosa: ' || v_mensaje);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Error en prueba: ' || SQLERRM);
        ROLLBACK;
END;
/
