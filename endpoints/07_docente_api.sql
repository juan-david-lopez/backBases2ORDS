-- =====================================================
-- API DE GESTIÓN DOCENTE
-- Archivo: 07_docente_api.sql
-- Propósito: Endpoints para que docentes gestionen grupos y calificaciones
-- Ejecutar como: ACADEMICO
-- =====================================================

SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT =====================================================
PROMPT Creando módulo GESTIÓN DOCENTE
PROMPT =====================================================

-- =====================================================
-- MÓDULO: docente
-- =====================================================

BEGIN
    ORDS.DEFINE_MODULE(
        p_module_name    => 'docente',
        p_base_path      => '/docente/',
        p_items_per_page => 0,
        p_status         => 'PUBLISHED',
        p_comments       => 'Módulo de gestión para docentes'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Módulo docente creado');
END;
/

-- =====================================================
-- ENDPOINT 1: GET /docente/mis-grupos/:cod_docente
-- Descripción: Obtiene los grupos asignados al docente
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'docente',
        p_pattern     => 'mis-grupos/:cod_docente'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'docente',
        p_pattern     => 'mis-grupos/:cod_docente',
        p_method      => 'GET',
        p_source_type => 'plsql/block',
        p_source      => q'[
BEGIN
    FOR rec IN (
        SELECT 
            g.cod_grupo,
            g.codigo_grupo,
            a.cod_asignatura,
            a.nombre_asignatura,
            a.creditos,
            pa.nombre_periodo,
            pa.cod_periodo,
            g.cupo_maximo,
            g.cupo_actual,
            (SELECT COUNT(*) 
             FROM DETALLE_MATRICULA dm 
             WHERE dm.cod_grupo = g.cod_grupo 
             AND dm.estado_detalle = 'ACTIVO') as estudiantes_activos,
            g.estado as estado_grupo,
            -- Horarios del grupo
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
        JOIN PERIODO_ACADEMICO pa ON g.cod_periodo = pa.cod_periodo
        WHERE g.cod_docente = :cod_docente
        AND pa.estado = 'ACTIVO'
        ORDER BY a.nombre_asignatura, g.codigo_grupo
    ) LOOP
        HTP.PRINT(JSON_OBJECT(
            'cod_grupo' VALUE rec.cod_grupo,
            'codigo_grupo' VALUE rec.codigo_grupo,
            'cod_asignatura' VALUE rec.cod_asignatura,
            'asignatura' VALUE rec.nombre_asignatura,
            'creditos' VALUE rec.creditos,
            'periodo' VALUE rec.nombre_periodo,
            'cod_periodo' VALUE rec.cod_periodo,
            'cupo_maximo' VALUE rec.cupo_maximo,
            'cupo_actual' VALUE rec.cupo_actual,
            'estudiantes_activos' VALUE rec.estudiantes_activos,
            'estado' VALUE rec.estado_grupo,
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
    DBMS_OUTPUT.PUT_LINE('✓ GET /mis-grupos/:cod_docente creado');
END;
/

-- =====================================================
-- ENDPOINT 2: GET /docente/estudiantes/:cod_grupo
-- Descripción: Lista estudiantes matriculados en un grupo
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'docente',
        p_pattern     => 'estudiantes/:cod_grupo'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'docente',
        p_pattern     => 'estudiantes/:cod_grupo',
        p_method      => 'GET',
        p_source_type => 'plsql/block',
        p_source      => q'[
BEGIN
    FOR rec IN (
        SELECT 
            e.cod_estudiante,
            e.primer_nombre || ' ' || e.primer_apellido as nombre_completo,
            e.correo_institucional,
            e.riesgo_academico,
            dm.cod_detalle_matricula,
            dm.estado_detalle,
            -- Notas del estudiante en este grupo
            (SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'cod_calificacion' VALUE c.cod_calificacion,
                    'actividad' VALUE ta.nombre_actividad,
                    'porcentaje' VALUE re.porcentaje,
                    'nota' VALUE c.nota_obtenida,
                    'fecha_registro' VALUE TO_CHAR(c.fecha_registro, 'YYYY-MM-DD'),
                    'observaciones' VALUE c.observaciones
                )
            )
            FROM CALIFICACION c
            JOIN REGLA_EVALUACION re ON c.cod_regla = re.cod_regla
            JOIN TIPO_ACTIVIDAD_EVALUATIVA ta ON re.cod_tipo_actividad = ta.cod_tipo_actividad
            WHERE c.cod_detalle_matricula = dm.cod_detalle_matricula
            ORDER BY re.porcentaje DESC) as calificaciones,
            -- Nota definitiva si existe
            (SELECT nota_final FROM NOTA_DEFINITIVA nd
             WHERE nd.cod_estudiante = e.cod_estudiante
             AND nd.cod_asignatura = (SELECT cod_asignatura FROM GRUPO WHERE cod_grupo = :cod_grupo)
             AND nd.cod_periodo = (SELECT cod_periodo FROM GRUPO WHERE cod_grupo = :cod_grupo)) as nota_definitiva
        FROM DETALLE_MATRICULA dm
        JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
        JOIN ESTUDIANTE e ON m.cod_estudiante = e.cod_estudiante
        WHERE dm.cod_grupo = :cod_grupo
        AND dm.estado_detalle = 'ACTIVO'
        ORDER BY e.primer_apellido, e.primer_nombre
    ) LOOP
        HTP.PRINT(JSON_OBJECT(
            'cod_estudiante' VALUE rec.cod_estudiante,
            'nombre' VALUE rec.nombre_completo,
            'correo' VALUE rec.correo_institucional,
            'riesgo_academico' VALUE rec.riesgo_academico,
            'cod_detalle_matricula' VALUE rec.cod_detalle_matricula,
            'estado' VALUE rec.estado_detalle,
            'calificaciones' VALUE rec.calificaciones FORMAT JSON,
            'nota_definitiva' VALUE rec.nota_definitiva
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
    DBMS_OUTPUT.PUT_LINE('✓ GET /estudiantes/:cod_grupo creado');
END;
/

-- =====================================================
-- ENDPOINT 3: GET /docente/reglas-evaluacion/:cod_grupo
-- Descripción: Obtiene las reglas de evaluación del grupo
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'docente',
        p_pattern     => 'reglas-evaluacion/:cod_grupo'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'docente',
        p_pattern     => 'reglas-evaluacion/:cod_grupo',
        p_method      => 'GET',
        p_source_type => 'plsql/block',
        p_source      => q'[
DECLARE
    v_suma_porcentajes NUMBER;
BEGIN
    FOR rec IN (
        SELECT 
            re.cod_regla,
            ta.cod_tipo_actividad,
            ta.nombre_actividad,
            ta.descripcion as descripcion_actividad,
            re.porcentaje,
            re.fecha_inicio,
            re.fecha_fin,
            g.codigo_grupo,
            a.nombre_asignatura
        FROM REGLA_EVALUACION re
        JOIN TIPO_ACTIVIDAD_EVALUATIVA ta ON re.cod_tipo_actividad = ta.cod_tipo_actividad
        JOIN GRUPO g ON re.cod_grupo = g.cod_grupo
        JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
        WHERE re.cod_grupo = :cod_grupo
        ORDER BY re.fecha_inicio, ta.nombre_actividad
    ) LOOP
        HTP.PRINT(JSON_OBJECT(
            'cod_regla' VALUE rec.cod_regla,
            'cod_tipo_actividad' VALUE rec.cod_tipo_actividad,
            'nombre_actividad' VALUE rec.nombre_actividad,
            'descripcion' VALUE rec.descripcion_actividad,
            'porcentaje' VALUE rec.porcentaje,
            'fecha_inicio' VALUE TO_CHAR(rec.fecha_inicio, 'YYYY-MM-DD'),
            'fecha_fin' VALUE TO_CHAR(rec.fecha_fin, 'YYYY-MM-DD'),
            'grupo' VALUE rec.codigo_grupo,
            'asignatura' VALUE rec.nombre_asignatura
        ) || ',');
    END LOOP;
    
    -- Verificar que suma 100%
    SELECT SUM(porcentaje) INTO v_suma_porcentajes
    FROM REGLA_EVALUACION
    WHERE cod_grupo = :cod_grupo;
    
    :status_code := 200;
    
EXCEPTION
    WHEN OTHERS THEN
        :status_code := 500;
        HTP.PRINT('{"error": "' || REPLACE(SQLERRM, '"', '\"') || '"}');
END;
]'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /reglas-evaluacion/:cod_grupo creado');
END;
/

-- =====================================================
-- ENDPOINT 4: POST /docente/registrar-nota
-- Descripción: Registra una calificación para un estudiante
-- Request: {cod_detalle_matricula, cod_tipo_actividad, nota, observaciones}
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'docente',
        p_pattern     => 'registrar-nota'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'docente',
        p_pattern     => 'registrar-nota',
        p_method      => 'POST',
        p_source_type => 'plsql/block',
        p_source      => q'[
DECLARE
    v_cod_calificacion NUMBER;
    v_cod_regla NUMBER;
    v_cod_grupo NUMBER;
    v_fecha_fin DATE;
    v_nota_valida NUMBER;
BEGIN
    -- Obtener grupo del detalle de matrícula
    SELECT dm.cod_grupo INTO v_cod_grupo
    FROM DETALLE_MATRICULA dm
    WHERE dm.cod_detalle_matricula = :cod_detalle_matricula;
    
    -- Obtener regla de evaluación
    SELECT cod_regla, fecha_fin INTO v_cod_regla, v_fecha_fin
    FROM REGLA_EVALUACION
    WHERE cod_grupo = v_cod_grupo
    AND cod_tipo_actividad = :cod_tipo_actividad;
    
    -- Validar que está dentro de la ventana
    IF SYSDATE > v_fecha_fin + 7 THEN -- 7 días de gracia
        :status_code := 400;
        HTP.PRINT('{"success": false, "message": "Fuera del período de registro de notas para esta actividad"}');
        RETURN;
    END IF;
    
    -- Validar rango de nota
    IF :nota < 0 OR :nota > 5 THEN
        :status_code := 400;
        HTP.PRINT('{"success": false, "message": "La nota debe estar entre 0.0 y 5.0"}');
        RETURN;
    END IF;
    
    -- Insertar calificación
    INSERT INTO CALIFICACION (
        cod_detalle_matricula,
        cod_regla,
        nota_obtenida,
        observaciones,
        fecha_registro
    ) VALUES (
        :cod_detalle_matricula,
        v_cod_regla,
        :nota,
        :observaciones,
        SYSDATE
    ) RETURNING cod_calificacion INTO v_cod_calificacion;
    
    -- Recalcular nota definitiva (trigger lo hace automáticamente)
    COMMIT;
    
    :status_code := 201;
    HTP.PRINT(JSON_OBJECT(
        'success' VALUE TRUE,
        'message' VALUE 'Nota registrada exitosamente',
        'cod_calificacion' VALUE v_cod_calificacion
    ));
    
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        :status_code := 400;
        HTP.PRINT('{"success": false, "message": "Ya existe una calificación para esta actividad"}');
    WHEN NO_DATA_FOUND THEN
        :status_code := 404;
        HTP.PRINT('{"success": false, "message": "Regla de evaluación no encontrada"}');
    WHEN OTHERS THEN
        ROLLBACK;
        :status_code := 400;
        HTP.PRINT('{"success": false, "message": "' || REPLACE(SQLERRM, '"', '\"') || '"}');
END;
]'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ POST /registrar-nota creado');
END;
/

-- =====================================================
-- ENDPOINT 5: PUT /docente/actualizar-nota/:cod_calificacion
-- Descripción: Actualiza una calificación existente
-- Request: {nota, observaciones}
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'docente',
        p_pattern     => 'actualizar-nota/:cod_calificacion'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'docente',
        p_pattern     => 'actualizar-nota/:cod_calificacion',
        p_method      => 'PUT',
        p_source_type => 'plsql/block',
        p_source      => q'[
DECLARE
    v_cerrado VARCHAR2(1);
    v_fecha_fin DATE;
BEGIN
    -- Verificar si el período está cerrado
    SELECT pa.notas_cerradas, re.fecha_fin
    INTO v_cerrado, v_fecha_fin
    FROM CALIFICACION c
    JOIN REGLA_EVALUACION re ON c.cod_regla = re.cod_regla
    JOIN GRUPO g ON re.cod_grupo = g.cod_grupo
    JOIN PERIODO_ACADEMICO pa ON g.cod_periodo = pa.cod_periodo
    WHERE c.cod_calificacion = :cod_calificacion;
    
    IF v_cerrado = 'S' THEN
        :status_code := 403;
        HTP.PRINT('{"success": false, "message": "Las notas están cerradas para este período"}');
        RETURN;
    END IF;
    
    -- Validar ventana de tiempo (14 días de gracia)
    IF SYSDATE > v_fecha_fin + 14 THEN
        :status_code := 400;
        HTP.PRINT('{"success": false, "message": "Fuera del período de modificación de notas"}');
        RETURN;
    END IF;
    
    -- Validar rango
    IF :nota < 0 OR :nota > 5 THEN
        :status_code := 400;
        HTP.PRINT('{"success": false, "message": "La nota debe estar entre 0.0 y 5.0"}');
        RETURN;
    END IF;
    
    -- Actualizar calificación
    UPDATE CALIFICACION
    SET nota_obtenida = :nota,
        observaciones = :observaciones,
        fecha_modificacion = SYSDATE
    WHERE cod_calificacion = :cod_calificacion;
    
    -- Recalcular nota definitiva (trigger lo hace)
    COMMIT;
    
    :status_code := 200;
    HTP.PRINT('{"success": true, "message": "Nota actualizada exitosamente"}');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        :status_code := 404;
        HTP.PRINT('{"success": false, "message": "Calificación no encontrada"}');
    WHEN OTHERS THEN
        ROLLBACK;
        :status_code := 400;
        HTP.PRINT('{"success": false, "message": "' || REPLACE(SQLERRM, '"', '\"') || '"}');
END;
]'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ PUT /actualizar-nota/:cod_calificacion creado');
END;
/

-- =====================================================
-- ENDPOINT 6: POST /docente/cerrar-notas/:cod_grupo
-- Descripción: Cierra las notas de un grupo (solo coordinador)
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'docente',
        p_pattern     => 'cerrar-notas/:cod_grupo'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'docente',
        p_pattern     => 'cerrar-notas/:cod_grupo',
        p_method      => 'POST',
        p_source_type => 'plsql/block',
        p_source      => q'[
DECLARE
    v_cod_periodo NUMBER;
    v_total_estudiantes NUMBER;
    v_estudiantes_sin_nota NUMBER;
BEGIN
    -- Obtener período del grupo
    SELECT cod_periodo INTO v_cod_periodo
    FROM GRUPO WHERE cod_grupo = :cod_grupo;
    
    -- Verificar que todos los estudiantes tengan notas
    SELECT COUNT(*) INTO v_total_estudiantes
    FROM DETALLE_MATRICULA
    WHERE cod_grupo = :cod_grupo
    AND estado_detalle = 'ACTIVO';
    
    SELECT COUNT(*) INTO v_estudiantes_sin_nota
    FROM DETALLE_MATRICULA dm
    WHERE dm.cod_grupo = :cod_grupo
    AND dm.estado_detalle = 'ACTIVO'
    AND NOT EXISTS (
        SELECT 1 FROM NOTA_DEFINITIVA nd
        WHERE nd.cod_detalle_matricula = dm.cod_detalle_matricula
    );
    
    IF v_estudiantes_sin_nota > 0 THEN
        :status_code := 400;
        HTP.PRINT(JSON_OBJECT(
            'success' VALUE FALSE,
            'message' VALUE 'Hay ' || v_estudiantes_sin_nota || ' estudiantes sin nota definitiva',
            'estudiantes_sin_nota' VALUE v_estudiantes_sin_nota,
            'total_estudiantes' VALUE v_total_estudiantes
        ));
        RETURN;
    END IF;
    
    -- Marcar período como cerrado (solo afecta al grupo)
    UPDATE GRUPO
    SET estado = 'CERRADO'
    WHERE cod_grupo = :cod_grupo;
    
    COMMIT;
    
    :status_code := 200;
    HTP.PRINT('{"success": true, "message": "Notas cerradas exitosamente para este grupo"}');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        :status_code := 404;
        HTP.PRINT('{"success": false, "message": "Grupo no encontrado"}');
    WHEN OTHERS THEN
        ROLLBACK;
        :status_code := 500;
        HTP.PRINT('{"success": false, "message": "' || REPLACE(SQLERRM, '"', '\"') || '"}');
END;
]'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ POST /cerrar-notas/:cod_grupo creado');
END;
/

-- =====================================================
-- ENDPOINT 7: GET /docente/estadisticas/:cod_grupo
-- Descripción: Estadísticas del grupo (promedio, aprobados, etc.)
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'docente',
        p_pattern     => 'estadisticas/:cod_grupo'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'docente',
        p_pattern     => 'estadisticas/:cod_grupo',
        p_method      => 'GET',
        p_source_type => 'plsql/block',
        p_source      => q'[
DECLARE
    v_total_estudiantes NUMBER;
    v_con_nota NUMBER;
    v_aprobados NUMBER;
    v_reprobados NUMBER;
    v_promedio NUMBER;
    v_nota_maxima NUMBER;
    v_nota_minima NUMBER;
    v_asignatura VARCHAR2(200);
    v_codigo_grupo VARCHAR2(10);
BEGIN
    -- Información básica del grupo
    SELECT a.nombre_asignatura, g.codigo_grupo
    INTO v_asignatura, v_codigo_grupo
    FROM GRUPO g
    JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
    WHERE g.cod_grupo = :cod_grupo;
    
    -- Total de estudiantes
    SELECT COUNT(*) INTO v_total_estudiantes
    FROM DETALLE_MATRICULA
    WHERE cod_grupo = :cod_grupo
    AND estado_detalle = 'ACTIVO';
    
    -- Estudiantes con nota definitiva
    SELECT COUNT(*) INTO v_con_nota
    FROM NOTA_DEFINITIVA nd
    JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
    WHERE dm.cod_grupo = :cod_grupo
    AND dm.estado_detalle = 'ACTIVO';
    
    -- Aprobados y reprobados
    SELECT 
        COUNT(CASE WHEN nd.resultado = 'APROBADO' THEN 1 END),
        COUNT(CASE WHEN nd.resultado IN ('REPROBADO','PERDIDA') THEN 1 END)
    INTO v_aprobados, v_reprobados
    FROM NOTA_DEFINITIVA nd
    JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
    WHERE dm.cod_grupo = :cod_grupo
    AND dm.estado_detalle = 'ACTIVO';
    
    -- Estadísticas de notas
    SELECT 
        COALESCE(AVG(nd.nota_final), 0),
        COALESCE(MAX(nd.nota_final), 0),
        COALESCE(MIN(nd.nota_final), 0)
    INTO v_promedio, v_nota_maxima, v_nota_minima
    FROM NOTA_DEFINITIVA nd
    JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
    WHERE dm.cod_grupo = :cod_grupo
    AND dm.estado_detalle = 'ACTIVO';
    
    :status_code := 200;
    HTP.PRINT(JSON_OBJECT(
        'asignatura' VALUE v_asignatura,
        'codigo_grupo' VALUE v_codigo_grupo,
        'total_estudiantes' VALUE v_total_estudiantes,
        'estudiantes_con_nota' VALUE v_con_nota,
        'estudiantes_sin_nota' VALUE (v_total_estudiantes - v_con_nota),
        'aprobados' VALUE v_aprobados,
        'reprobados' VALUE v_reprobados,
        'promedio_grupo' VALUE ROUND(v_promedio, 2),
        'nota_maxima' VALUE v_nota_maxima,
        'nota_minima' VALUE v_nota_minima,
        'porcentaje_aprobacion' VALUE CASE WHEN v_con_nota > 0 
            THEN ROUND((v_aprobados * 100.0 / v_con_nota), 2) 
            ELSE 0 END
    ));
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        :status_code := 404;
        HTP.PRINT('{"error": "Grupo no encontrado"}');
    WHEN OTHERS THEN
        :status_code := 500;
        HTP.PRINT('{"error": "' || REPLACE(SQLERRM, '"', '\"') || '"}');
END;
]'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /estadisticas/:cod_grupo creado');
END;
/

PROMPT
PROMPT =====================================================
PROMPT Módulo GESTIÓN DOCENTE creado exitosamente
PROMPT =====================================================
PROMPT
PROMPT Endpoints disponibles:
PROMPT   GET  /docente/mis-grupos/:cod_docente
PROMPT   GET  /docente/estudiantes/:cod_grupo
PROMPT   GET  /docente/reglas-evaluacion/:cod_grupo
PROMPT   POST /docente/registrar-nota
PROMPT   PUT  /docente/actualizar-nota/:cod_calificacion
PROMPT   POST /docente/cerrar-notas/:cod_grupo
PROMPT   GET  /docente/estadisticas/:cod_grupo
PROMPT
PROMPT =====================================================

exit;
