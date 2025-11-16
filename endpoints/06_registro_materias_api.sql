-- =====================================================
-- API DE REGISTRO DE MATERIAS (ESTUDIANTES)
-- Archivo: 06_registro_materias_api.sql
-- Propósito: Endpoints para que estudiantes gestionen su matrícula
-- Ejecutar como: ACADEMICO
-- =====================================================

SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT =====================================================
PROMPT Creando módulo REGISTRO DE MATERIAS
PROMPT =====================================================

-- =====================================================
-- MÓDULO: registro_materias
-- =====================================================

BEGIN
    ORDS.DEFINE_MODULE(
        p_module_name    => 'registro_materias',
        p_base_path      => '/registro-materias/',
        p_items_per_page => 0,
        p_status         => 'PUBLISHED',
        p_comments       => 'Módulo de registro de materias para estudiantes'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Módulo registro_materias creado');
END;
/

-- =====================================================
-- ENDPOINT 1: GET /registro-materias/disponibles/:cod_estudiante
-- Descripción: Obtiene asignaturas disponibles para matricular
-- Valida: prerrequisitos, ya matriculadas, riesgo académico
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'registro_materias',
        p_pattern     => 'disponibles/:cod_estudiante'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'registro_materias',
        p_pattern     => 'disponibles/:cod_estudiante',
        p_method      => 'GET',
        p_source_type => 'plsql/block',
        p_source      => q'[
DECLARE
    v_riesgo VARCHAR2(20);
    v_creditos_maximos NUMBER;
    v_creditos_actuales NUMBER;
    v_cod_programa VARCHAR2(10);
BEGIN
    -- Obtener información del estudiante
    SELECT e.cod_programa, COALESCE(e.riesgo_academico, 'BAJO')
    INTO v_cod_programa, v_riesgo
    FROM ESTUDIANTE e
    WHERE e.cod_estudiante = :cod_estudiante;
    
    -- Determinar créditos máximos según riesgo
    v_creditos_maximos := CASE v_riesgo
        WHEN 'ALTO' THEN 12
        WHEN 'MEDIO' THEN 16
        ELSE 20
    END;
    
    -- Obtener créditos actuales del período activo
    SELECT COALESCE(SUM(a.creditos), 0)
    INTO v_creditos_actuales
    FROM DETALLE_MATRICULA dm
    JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
    JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
    JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
    JOIN PERIODO_ACADEMICO pa ON m.cod_periodo = pa.cod_periodo
    WHERE m.cod_estudiante = :cod_estudiante
    AND pa.estado = 'ACTIVO'
    AND dm.estado_detalle = 'ACTIVO';
    
    -- Retornar asignaturas disponibles
    FOR rec IN (
        SELECT 
            a.cod_asignatura,
            a.nombre_asignatura,
            a.creditos,
            a.nivel_asignatura,
            a.tipo_asignatura,
            (SELECT COUNT(*) 
             FROM PRERREQUISITO pr 
             WHERE pr.cod_asignatura = a.cod_asignatura) as tiene_prerrequisitos,
            (SELECT LISTAGG(pa.nombre_asignatura, ', ') WITHIN GROUP (ORDER BY pa.nombre_asignatura)
             FROM PRERREQUISITO pr
             JOIN ASIGNATURA pa ON pr.cod_prerrequisito = pa.cod_asignatura
             WHERE pr.cod_asignatura = a.cod_asignatura) as prerrequisitos,
            (SELECT COUNT(*) FROM GRUPO WHERE cod_asignatura = a.cod_asignatura AND estado = 'ACTIVO') as grupos_disponibles
        FROM ASIGNATURA a
        WHERE a.cod_programa = v_cod_programa
        AND a.estado = 'ACTIVO'
        -- No debe estar matriculada actualmente
        AND NOT EXISTS (
            SELECT 1 FROM DETALLE_MATRICULA dm2
            JOIN MATRICULA m2 ON dm2.cod_matricula = m2.cod_matricula
            JOIN GRUPO g2 ON dm2.cod_grupo = g2.cod_grupo
            JOIN PERIODO_ACADEMICO pa2 ON m2.cod_periodo = pa2.cod_periodo
            WHERE m2.cod_estudiante = :cod_estudiante
            AND g2.cod_asignatura = a.cod_asignatura
            AND pa2.estado = 'ACTIVO'
            AND dm2.estado_detalle = 'ACTIVO'
        )
        -- No debe estar aprobada
        AND NOT EXISTS (
            SELECT 1 FROM NOTA_DEFINITIVA nd
            WHERE nd.cod_estudiante = :cod_estudiante
            AND nd.cod_asignatura = a.cod_asignatura
            AND nd.resultado = 'APROBADO'
        )
        -- Debe cumplir prerrequisitos
        AND NOT EXISTS (
            SELECT 1 FROM PRERREQUISITO pr
            WHERE pr.cod_asignatura = a.cod_asignatura
            AND NOT EXISTS (
                SELECT 1 FROM NOTA_DEFINITIVA nd2
                WHERE nd2.cod_estudiante = :cod_estudiante
                AND nd2.cod_asignatura = pr.cod_prerrequisito
                AND nd2.resultado = 'APROBADO'
            )
        )
        -- Verificar que no exceda créditos máximos
        AND a.creditos <= (v_creditos_maximos - v_creditos_actuales)
        ORDER BY a.nivel_asignatura, a.nombre_asignatura
    ) LOOP
        HTP.PRINT(JSON_OBJECT(
            'cod_asignatura' VALUE rec.cod_asignatura,
            'nombre_asignatura' VALUE rec.nombre_asignatura,
            'creditos' VALUE rec.creditos,
            'nivel' VALUE rec.nivel_asignatura,
            'tipo' VALUE rec.tipo_asignatura,
            'tiene_prerrequisitos' VALUE rec.tiene_prerrequisitos,
            'prerrequisitos' VALUE rec.prerrequisitos,
            'grupos_disponibles' VALUE rec.grupos_disponibles
        ) || ',');
    END LOOP;
    
    -- Información adicional
    :status_code := 200;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        :status_code := 404;
        HTP.PRINT('{"error": "Estudiante no encontrado"}');
    WHEN OTHERS THEN
        :status_code := 500;
        HTP.PRINT('{"error": "' || REPLACE(SQLERRM, '"', '\"') || '"}');
END;
]'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /disponibles/:cod_estudiante creado');
END;
/

-- =====================================================
-- ENDPOINT 2: GET /registro-materias/grupos/:cod_asignatura
-- Descripción: Obtiene grupos disponibles de una asignatura
-- Incluye: horarios, cupos, docente
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'registro_materias',
        p_pattern     => 'grupos/:cod_asignatura'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'registro_materias',
        p_pattern     => 'grupos/:cod_asignatura',
        p_method      => 'GET',
        p_source_type => 'plsql/block',
        p_source      => q'[
BEGIN
    FOR rec IN (
        SELECT 
            g.cod_grupo,
            g.codigo_grupo,
            g.cupo_maximo,
            g.cupo_actual,
            (g.cupo_maximo - g.cupo_actual) as cupos_disponibles,
            d.primer_nombre || ' ' || d.primer_apellido as docente,
            d.correo_institucional as correo_docente,
            a.nombre_asignatura,
            a.creditos,
            pa.nombre_periodo,
            -- Horarios del grupo (agregados)
            (SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'dia_semana' VALUE h.dia_semana,
                    'hora_inicio' VALUE TO_CHAR(h.hora_inicio, 'HH24:MI'),
                    'hora_fin' VALUE TO_CHAR(h.hora_fin, 'HH24:MI'),
                    'tipo_clase' VALUE h.tipo_clase,
                    'aula' VALUE h.aula
                )
            ) FROM HORARIO h WHERE h.cod_grupo = g.cod_grupo) as horarios
        FROM GRUPO g
        JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
        JOIN DOCENTE d ON g.cod_docente = d.cod_docente
        JOIN PERIODO_ACADEMICO pa ON g.cod_periodo = pa.cod_periodo
        WHERE g.cod_asignatura = :cod_asignatura
        AND g.estado = 'ACTIVO'
        AND pa.estado = 'ACTIVO'
        AND g.cupo_actual < g.cupo_maximo
        ORDER BY g.codigo_grupo
    ) LOOP
        HTP.PRINT(JSON_OBJECT(
            'cod_grupo' VALUE rec.cod_grupo,
            'codigo_grupo' VALUE rec.codigo_grupo,
            'cupo_maximo' VALUE rec.cupo_maximo,
            'cupo_actual' VALUE rec.cupo_actual,
            'cupos_disponibles' VALUE rec.cupos_disponibles,
            'docente' VALUE rec.docente,
            'correo_docente' VALUE rec.correo_docente,
            'asignatura' VALUE rec.nombre_asignatura,
            'creditos' VALUE rec.creditos,
            'periodo' VALUE rec.nombre_periodo,
            'horarios' VALUE rec.horarios FORMAT JSON
        ) || ',');
    END LOOP;
    
    :status_code := 200;
    
EXCEPTION
    WHEN OTHERS THEN
        :status_code := 500;
        HTP.PRINT('{"error": "' || REPLACE(SQLERRM, '"', '\"') || '"}');
END;
]'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /grupos/:cod_asignatura creado');
END;
/

-- =====================================================
-- ENDPOINT 3: POST /registro-materias/inscribir
-- Descripción: Inscribe un estudiante en un grupo
-- Valida: prerrequisitos, horarios, capacidad, créditos
-- Request: {cod_estudiante, cod_grupo}
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'registro_materias',
        p_pattern     => 'inscribir'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'registro_materias',
        p_pattern     => 'inscribir',
        p_method      => 'POST',
        p_source_type => 'plsql/block',
        p_source      => q'[
DECLARE
    v_cod_matricula NUMBER;
    v_cod_periodo NUMBER;
    v_cod_asignatura VARCHAR2(10);
    v_creditos NUMBER;
    v_result VARCHAR2(4000);
BEGIN
    -- Obtener período activo
    SELECT cod_periodo INTO v_cod_periodo
    FROM PERIODO_ACADEMICO
    WHERE estado = 'ACTIVO' AND ROWNUM = 1;
    
    -- Obtener asignatura del grupo
    SELECT cod_asignatura INTO v_cod_asignatura
    FROM GRUPO WHERE cod_grupo = :cod_grupo;
    
    -- Verificar si tiene matrícula activa
    BEGIN
        SELECT cod_matricula INTO v_cod_matricula
        FROM MATRICULA
        WHERE cod_estudiante = :cod_estudiante
        AND cod_periodo = v_cod_periodo;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Crear matrícula si no existe
            INSERT INTO MATRICULA (cod_estudiante, cod_periodo, estado_matricula)
            VALUES (:cod_estudiante, v_cod_periodo, 'ACTIVA')
            RETURNING cod_matricula INTO v_cod_matricula;
    END;
    
    -- Insertar detalle de matrícula (triggers validan todo)
    INSERT INTO DETALLE_MATRICULA (cod_matricula, cod_grupo, estado_detalle)
    VALUES (v_cod_matricula, :cod_grupo, 'ACTIVO');
    
    COMMIT;
    
    :status_code := 201;
    HTP.PRINT(JSON_OBJECT(
        'success' VALUE TRUE,
        'message' VALUE 'Asignatura inscrita exitosamente',
        'cod_matricula' VALUE v_cod_matricula,
        'cod_grupo' VALUE :cod_grupo
    ));
    
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        :status_code := 400;
        HTP.PRINT('{"success": false, "message": "Ya estás inscrito en esta asignatura"}');
    WHEN OTHERS THEN
        ROLLBACK;
        :status_code := 400;
        HTP.PRINT('{"success": false, "message": "' || REPLACE(SQLERRM, '"', '\"') || '"}');
END;
]'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ POST /inscribir creado');
END;
/

-- =====================================================
-- ENDPOINT 4: DELETE /registro-materias/retirar/:cod_detalle_matricula
-- Descripción: Retira una asignatura (valida ventana de retiro)
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'registro_materias',
        p_pattern     => 'retirar/:cod_detalle_matricula'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'registro_materias',
        p_pattern     => 'retirar/:cod_detalle_matricula',
        p_method      => 'DELETE',
        p_source_type => 'plsql/block',
        p_source      => q'[
DECLARE
    v_fecha_limite DATE;
    v_estado VARCHAR2(20);
BEGIN
    -- Verificar si está en ventana de retiro
    SELECT ve.fecha_fin, dm.estado_detalle
    INTO v_fecha_limite, v_estado
    FROM DETALLE_MATRICULA dm
    JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
    JOIN VENTANA_EVENTO ve ON m.cod_periodo = ve.cod_periodo
    WHERE dm.cod_detalle_matricula = :cod_detalle_matricula
    AND ve.tipo_evento = 'RETIRO_MATERIA';
    
    IF SYSDATE > v_fecha_limite THEN
        :status_code := 400;
        HTP.PRINT('{"success": false, "message": "Fuera de la ventana de retiro de materias"}');
        RETURN;
    END IF;
    
    IF v_estado != 'ACTIVO' THEN
        :status_code := 400;
        HTP.PRINT('{"success": false, "message": "Esta matrícula no está activa"}');
        RETURN;
    END IF;
    
    -- Marcar como retirada
    UPDATE DETALLE_MATRICULA
    SET estado_detalle = 'RETIRADA',
        fecha_retiro = SYSDATE
    WHERE cod_detalle_matricula = :cod_detalle_matricula;
    
    -- Actualizar cupo del grupo
    UPDATE GRUPO g
    SET cupo_actual = cupo_actual - 1
    WHERE cod_grupo = (
        SELECT cod_grupo FROM DETALLE_MATRICULA 
        WHERE cod_detalle_matricula = :cod_detalle_matricula
    );
    
    COMMIT;
    
    :status_code := 200;
    HTP.PRINT('{"success": true, "message": "Asignatura retirada exitosamente"}');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        :status_code := 404;
        HTP.PRINT('{"success": false, "message": "Detalle de matrícula no encontrado o ventana no configurada"}');
    WHEN OTHERS THEN
        ROLLBACK;
        :status_code := 500;
        HTP.PRINT('{"success": false, "message": "' || REPLACE(SQLERRM, '"', '\"') || '"}');
END;
]'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ DELETE /retirar/:cod_detalle_matricula creado');
END;
/

-- =====================================================
-- ENDPOINT 5: GET /registro-materias/mi-horario/:cod_estudiante
-- Descripción: Obtiene el horario actual del estudiante
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'registro_materias',
        p_pattern     => 'mi-horario/:cod_estudiante'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'registro_materias',
        p_pattern     => 'mi-horario/:cod_estudiante',
        p_method      => 'GET',
        p_source_type => 'plsql/block',
        p_source      => q'[
BEGIN
    FOR rec IN (
        SELECT 
            a.nombre_asignatura,
            a.cod_asignatura,
            g.codigo_grupo,
            d.primer_nombre || ' ' || d.primer_apellido as docente,
            h.dia_semana,
            TO_CHAR(h.hora_inicio, 'HH24:MI') as hora_inicio,
            TO_CHAR(h.hora_fin, 'HH24:MI') as hora_fin,
            h.tipo_clase,
            h.aula,
            dm.cod_detalle_matricula
        FROM DETALLE_MATRICULA dm
        JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
        JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
        JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
        JOIN DOCENTE d ON g.cod_docente = d.cod_docente
        JOIN HORARIO h ON g.cod_grupo = h.cod_grupo
        JOIN PERIODO_ACADEMICO pa ON m.cod_periodo = pa.cod_periodo
        WHERE m.cod_estudiante = :cod_estudiante
        AND pa.estado = 'ACTIVO'
        AND dm.estado_detalle = 'ACTIVO'
        ORDER BY 
            CASE h.dia_semana
                WHEN 'LUNES' THEN 1
                WHEN 'MARTES' THEN 2
                WHEN 'MIERCOLES' THEN 3
                WHEN 'JUEVES' THEN 4
                WHEN 'VIERNES' THEN 5
                WHEN 'SABADO' THEN 6
                ELSE 7
            END,
            h.hora_inicio
    ) LOOP
        HTP.PRINT(JSON_OBJECT(
            'asignatura' VALUE rec.nombre_asignatura,
            'cod_asignatura' VALUE rec.cod_asignatura,
            'grupo' VALUE rec.codigo_grupo,
            'docente' VALUE rec.docente,
            'dia' VALUE rec.dia_semana,
            'hora_inicio' VALUE rec.hora_inicio,
            'hora_fin' VALUE rec.hora_fin,
            'tipo_clase' VALUE rec.tipo_clase,
            'aula' VALUE rec.aula,
            'cod_detalle' VALUE rec.cod_detalle_matricula
        ) || ',');
    END LOOP;
    
    :status_code := 200;
    
EXCEPTION
    WHEN OTHERS THEN
        :status_code := 500;
        HTP.PRINT('{"error": "' || REPLACE(SQLERRM, '"', '\"') || '"}');
END;
]'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /mi-horario/:cod_estudiante creado');
END;
/

-- =====================================================
-- ENDPOINT 6: GET /registro-materias/resumen/:cod_estudiante
-- Descripción: Resumen de matrícula actual (créditos, riesgo, límites)
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'registro_materias',
        p_pattern     => 'resumen/:cod_estudiante'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'registro_materias',
        p_pattern     => 'resumen/:cod_estudiante',
        p_method      => 'GET',
        p_source_type => 'plsql/block',
        p_source      => q'[
DECLARE
    v_riesgo VARCHAR2(20);
    v_creditos_actuales NUMBER;
    v_creditos_maximos NUMBER;
    v_materias_inscritas NUMBER;
    v_promedio NUMBER;
    v_periodo VARCHAR2(100);
BEGIN
    -- Información del estudiante
    SELECT 
        COALESCE(e.riesgo_academico, 'BAJO'),
        pa.nombre_periodo
    INTO v_riesgo, v_periodo
    FROM ESTUDIANTE e
    CROSS JOIN (
        SELECT nombre_periodo FROM PERIODO_ACADEMICO 
        WHERE estado = 'ACTIVO' AND ROWNUM = 1
    ) pa
    WHERE e.cod_estudiante = :cod_estudiante;
    
    -- Créditos máximos según riesgo
    v_creditos_maximos := CASE v_riesgo
        WHEN 'ALTO' THEN 12
        WHEN 'MEDIO' THEN 16
        ELSE 20
    END;
    
    -- Créditos actuales
    SELECT 
        COALESCE(SUM(a.creditos), 0),
        COUNT(DISTINCT dm.cod_detalle_matricula)
    INTO v_creditos_actuales, v_materias_inscritas
    FROM DETALLE_MATRICULA dm
    JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
    JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
    JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
    JOIN PERIODO_ACADEMICO pa ON m.cod_periodo = pa.cod_periodo
    WHERE m.cod_estudiante = :cod_estudiante
    AND pa.estado = 'ACTIVO'
    AND dm.estado_detalle = 'ACTIVO';
    
    -- Promedio acumulado
    SELECT COALESCE(AVG(nota_final), 0)
    INTO v_promedio
    FROM NOTA_DEFINITIVA
    WHERE cod_estudiante = :cod_estudiante;
    
    :status_code := 200;
    HTP.PRINT(JSON_OBJECT(
        'periodo' VALUE v_periodo,
        'riesgo_academico' VALUE v_riesgo,
        'creditos_actuales' VALUE v_creditos_actuales,
        'creditos_maximos' VALUE v_creditos_maximos,
        'creditos_disponibles' VALUE (v_creditos_maximos - v_creditos_actuales),
        'materias_inscritas' VALUE v_materias_inscritas,
        'promedio_acumulado' VALUE ROUND(v_promedio, 2)
    ));
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        :status_code := 404;
        HTP.PRINT('{"error": "Estudiante no encontrado"}');
    WHEN OTHERS THEN
        :status_code := 500;
        HTP.PRINT('{"error": "' || REPLACE(SQLERRM, '"', '\"') || '"}');
END;
]'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /resumen/:cod_estudiante creado');
END;
/

PROMPT
PROMPT =====================================================
PROMPT Módulo REGISTRO DE MATERIAS creado exitosamente
PROMPT =====================================================
PROMPT
PROMPT Endpoints disponibles:
PROMPT   GET    /registro-materias/disponibles/:cod_estudiante
PROMPT   GET    /registro-materias/grupos/:cod_asignatura
PROMPT   POST   /registro-materias/inscribir
PROMPT   DELETE /registro-materias/retirar/:cod_detalle_matricula
PROMPT   GET    /registro-materias/mi-horario/:cod_estudiante
PROMPT   GET    /registro-materias/resumen/:cod_estudiante
PROMPT
PROMPT =====================================================

exit;
