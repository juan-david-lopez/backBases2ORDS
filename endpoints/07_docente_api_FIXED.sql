-- =====================================================
-- API DE GESTIÓN DOCENTE - VERSIÓN CORREGIDA
-- Archivo: 07_docente_api_FIXED.sql
-- Propósito: Endpoints para gestión de grupos y calificaciones por docentes
-- Ejecutar como: ACADEMICO
-- CORRECCIONES: Usa nombres de columnas reales de la BD
-- =====================================================

SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT =====================================================
PROMPT Creando módulo GESTIÓN DOCENTE (CORREGIDO)
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
-- ENDPOINT 1: GET /mis-grupos/:cod_docente
-- Descripción: Grupos asignados a un docente
-- CORRECCIONES: Usa estado_grupo, estado_inscripcion
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
    HTP.PRINT('[');
    FOR rec IN (
        SELECT 
            g.cod_grupo,
            g.numero_grupo,
            g.modalidad,
            g.aula,
            g.cupo_maximo,
            g.cupo_disponible,
            a.cod_asignatura,
            a.nombre_asignatura,
            a.creditos,
            pa.nombre_periodo,
            pa.fecha_inicio,
            pa.fecha_fin,
            -- Contar estudiantes activos
            (SELECT COUNT(*)
             FROM DETALLE_MATRICULA dm2
             WHERE dm2.cod_grupo = g.cod_grupo
             AND dm2.estado_inscripcion = 'INSCRITO') as estudiantes_activos,
            -- Horarios
            (SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'dia' VALUE h.dia_semana,
                    'hora_inicio' VALUE TO_CHAR(h.hora_inicio, 'HH24:MI'),
                    'hora_fin' VALUE TO_CHAR(h.hora_fin, 'HH24:MI'),
                    'aula' VALUE h.aula
                )
             )
             FROM HORARIO h
             WHERE h.cod_grupo = g.cod_grupo) as horarios
        FROM GRUPO g
        JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
        JOIN PERIODO_ACADEMICO pa ON g.cod_periodo = pa.cod_periodo
        WHERE g.cod_docente = :cod_docente
        AND pa.estado_periodo = 'ACTIVO'
        ORDER BY a.nombre_asignatura, g.numero_grupo
    ) LOOP
        HTP.PRINT(JSON_OBJECT(
            'cod_grupo' VALUE rec.cod_grupo,
            'numero_grupo' VALUE rec.numero_grupo,
            'asignatura' VALUE rec.nombre_asignatura,
            'cod_asignatura' VALUE rec.cod_asignatura,
            'creditos' VALUE rec.creditos,
            'modalidad' VALUE rec.modalidad,
            'aula' VALUE rec.aula,
            'periodo' VALUE rec.nombre_periodo,
            'fecha_inicio' VALUE TO_CHAR(rec.fecha_inicio, 'YYYY-MM-DD'),
            'fecha_fin' VALUE TO_CHAR(rec.fecha_fin, 'YYYY-MM-DD'),
            'cupo_maximo' VALUE rec.cupo_maximo,
            'cupo_disponible' VALUE rec.cupo_disponible,
            'estudiantes_activos' VALUE rec.estudiantes_activos,
            'horarios' VALUE rec.horarios
        ) || ',');
    END LOOP;
    HTP.PRINT('{}]');
    
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
-- ENDPOINT 2: GET /estudiantes/:cod_grupo
-- Descripción: Lista de estudiantes de un grupo con sus calificaciones
-- CORRECCIONES: Usa estado_inscripcion
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
    HTP.PRINT('[');
    FOR rec IN (
        SELECT 
            e.cod_estudiante,
            e.primer_nombre || ' ' || e.primer_apellido as nombre_completo,
            e.correo_institucional,
            dm.cod_detalle_matricula,
            dm.fecha_inscripcion,
            -- Calificaciones del estudiante en este grupo
            (SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'cod_calificacion' VALUE c.cod_calificacion,
                    'actividad' VALUE ta.nombre_actividad,
                    'porcentaje' VALUE re.porcentaje_nota,
                    'nota' VALUE c.nota,
                    'fecha_calificacion' VALUE TO_CHAR(c.fecha_calificacion, 'YYYY-MM-DD'),
                    'observaciones' VALUE c.observaciones
                )
             )
             FROM CALIFICACION c
             JOIN REGLA_EVALUACION re ON c.cod_regla = re.cod_regla
             JOIN TIPO_ACTIVIDAD_EVALUATIVA ta ON re.cod_tipo_actividad = ta.cod_tipo_actividad
             WHERE c.cod_detalle_matricula = dm.cod_detalle_matricula
             ORDER BY ta.cod_tipo_actividad) as calificaciones,
            -- Nota definitiva si existe
            nd.nota_final,
            nd.resultado
        FROM DETALLE_MATRICULA dm
        JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
        JOIN ESTUDIANTE e ON m.cod_estudiante = e.cod_estudiante
        LEFT JOIN NOTA_DEFINITIVA nd ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
        WHERE dm.cod_grupo = :cod_grupo
        AND dm.estado_inscripcion = 'INSCRITO'
        ORDER BY e.primer_apellido, e.primer_nombre
    ) LOOP
        HTP.PRINT(JSON_OBJECT(
            'cod_estudiante' VALUE rec.cod_estudiante,
            'nombre' VALUE rec.nombre_completo,
            'correo' VALUE rec.correo_institucional,
            'cod_detalle_matricula' VALUE rec.cod_detalle_matricula,
            'fecha_inscripcion' VALUE TO_CHAR(rec.fecha_inscripcion, 'YYYY-MM-DD'),
            'calificaciones' VALUE rec.calificaciones,
            'nota_final' VALUE rec.nota_final,
            'resultado' VALUE rec.resultado
        ) || ',');
    END LOOP;
    HTP.PRINT('{}]');
    
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
-- ENDPOINT 3: GET /reglas-evaluacion/:cod_grupo
-- Descripción: Reglas de evaluación de un grupo
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
    v_cod_asignatura VARCHAR2(10);
BEGIN
    -- Obtener cod_asignatura del grupo
    SELECT cod_asignatura INTO v_cod_asignatura
    FROM GRUPO WHERE cod_grupo = :cod_grupo;
    
    -- Calcular suma de porcentajes
    SELECT COALESCE(SUM(porcentaje), 0)
    INTO v_suma_porcentajes
    FROM REGLA_EVALUACION
    WHERE cod_asignatura = v_cod_asignatura;
    
    HTP.PRINT('{"reglas": [');
    FOR rec IN (
        SELECT 
            re.cod_regla,
            ta.nombre_actividad,
            ta.descripcion,
            re.porcentaje,
            re.cantidad_actividades,
            re.descripcion as regla_descripcion
        FROM REGLA_EVALUACION re
        JOIN TIPO_ACTIVIDAD_EVALUATIVA ta ON re.cod_tipo_actividad = ta.cod_tipo_actividad
        WHERE re.cod_asignatura = v_cod_asignatura
        ORDER BY ta.cod_tipo_actividad
    ) LOOP
        HTP.PRINT(JSON_OBJECT(
            'cod_regla' VALUE rec.cod_regla,
            'actividad' VALUE rec.nombre_actividad,
            'descripcion' VALUE rec.regla_descripcion,
            'porcentaje' VALUE rec.porcentaje,
            'cantidad' VALUE rec.cantidad_actividades
        ) || ',');
    END LOOP;
    HTP.PRINT('{}], "suma_porcentajes": ' || v_suma_porcentajes || ', "valido": ' || 
              CASE WHEN v_suma_porcentajes = 100 THEN 'true' ELSE 'false' END || '}');
    
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
-- ENDPOINT 4: POST /registrar-nota
-- Descripción: Registrar calificación parcial
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
    v_cod_detalle NUMBER;
    v_cod_tipo_actividad NUMBER;
    v_nota NUMBER;
    v_observaciones VARCHAR2(500);
    v_cod_regla NUMBER;
    v_cod_calificacion NUMBER;
    v_fecha_fin DATE;
BEGIN
    -- Parsear JSON del body
    v_cod_detalle := JSON_VALUE(:body, '$.cod_detalle_matricula');
    v_cod_tipo_actividad := JSON_VALUE(:body, '$.cod_tipo_actividad');
    v_nota := JSON_VALUE(:body, '$.nota');
    v_observaciones := JSON_VALUE(:body, '$.observaciones');
    
    -- Validar rango de nota
    IF v_nota < 0 OR v_nota > 5 THEN
        :status_code := 400;
        HTP.PRINT('{"error": "La nota debe estar entre 0 y 5"}');
        RETURN;
    END IF;
    
    -- Obtener regla de evaluación
    SELECT re.cod_regla, re.fecha_fin
    INTO v_cod_regla, v_fecha_fin
    FROM REGLA_EVALUACION re
    JOIN DETALLE_MATRICULA dm ON re.cod_grupo = dm.cod_grupo
    WHERE dm.cod_detalle_matricula = v_cod_detalle
    AND re.cod_tipo_actividad = v_cod_tipo_actividad;
    
    -- Validar que esté dentro del periodo de calificación (fecha_fin + 7 días de gracia)
    IF SYSDATE > v_fecha_fin + 7 THEN
        :status_code := 400;
        HTP.PRINT('{"error": "Periodo de calificación cerrado"}');
        RETURN;
    END IF;
    
    -- Insertar calificación
    INSERT INTO CALIFICACION (cod_detalle_matricula, cod_regla, nota, observaciones)
    VALUES (v_cod_detalle, v_cod_regla, v_nota, v_observaciones)
    RETURNING cod_calificacion INTO v_cod_calificacion;
    
    COMMIT;
    
    :status_code := 201;
    HTP.PRINT(JSON_OBJECT(
        'success' VALUE true,
        'message' VALUE 'Calificación registrada exitosamente',
        'cod_calificacion' VALUE v_cod_calificacion
    ));
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        :status_code := 404;
        HTP.PRINT('{"error": "No se encontró la regla de evaluación"}');
    WHEN DUP_VAL_ON_INDEX THEN
        :status_code := 409;
        HTP.PRINT('{"error": "Ya existe una calificación para esta actividad"}');
    WHEN OTHERS THEN
        ROLLBACK;
        :status_code := 500;
        HTP.PRINT('{"error": "' || REPLACE(SQLERRM, '"', '\"') || '"}');
END;
]'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ POST /registrar-nota creado');
END;
/

-- =====================================================
-- ENDPOINT 5: PUT /actualizar-nota/:cod_calificacion
-- Descripción: Actualizar calificación existente
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
    v_nota NUMBER;
    v_observaciones VARCHAR2(500);
    v_fecha_fin DATE;
    v_notas_cerradas VARCHAR2(1);
BEGIN
    -- Parsear JSON del body
    v_nota := JSON_VALUE(:body, '$.nota');
    v_observaciones := JSON_VALUE(:body, '$.observaciones');
    
    -- Validar rango de nota
    IF v_nota < 0 OR v_nota > 5 THEN
        :status_code := 400;
        HTP.PRINT('{"error": "La nota debe estar entre 0 y 5"}');
        RETURN;
    END IF;
    
    -- Verificar que el periodo no esté cerrado y obtener fecha fin
    SELECT re.fecha_fin, g.notas_cerradas
    INTO v_fecha_fin, v_notas_cerradas
    FROM CALIFICACION c
    JOIN REGLA_EVALUACION re ON c.cod_regla = re.cod_regla
    JOIN GRUPO g ON re.cod_grupo = g.cod_grupo
    WHERE c.cod_calificacion = :cod_calificacion;
    
    IF v_notas_cerradas = 'S' THEN
        :status_code := 400;
        HTP.PRINT('{"error": "El periodo de notas está cerrado"}');
        RETURN;
    END IF;
    
    -- Validar periodo de modificación (fecha_fin + 14 días de gracia)
    IF SYSDATE > v_fecha_fin + 14 THEN
        :status_code := 400;
        HTP.PRINT('{"error": "Periodo de modificación cerrado"}');
        RETURN;
    END IF;
    
    -- Actualizar calificación
    UPDATE CALIFICACION
    SET nota = v_nota,
        observaciones = v_observaciones,
        fecha_modificacion = SYSDATE
    WHERE cod_calificacion = :cod_calificacion;
    
    COMMIT;
    
    :status_code := 200;
    HTP.PRINT('{"success": true, "message": "Calificación actualizada exitosamente"}');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        :status_code := 404;
        HTP.PRINT('{"error": "Calificación no encontrada"}');
    WHEN OTHERS THEN
        ROLLBACK;
        :status_code := 500;
        HTP.PRINT('{"error": "' || REPLACE(SQLERRM, '"', '\"') || '"}');
END;
]'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ PUT /actualizar-nota/:cod_calificacion creado');
END;
/

-- =====================================================
-- ENDPOINT 6: POST /cerrar-notas/:cod_grupo
-- Descripción: Cerrar calificaciones de un grupo
-- CORRECCIONES: Usa estado_grupo
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
    v_estudiantes_sin_nota NUMBER;
BEGIN
    -- Verificar que todos los estudiantes tengan nota definitiva
    SELECT COUNT(*)
    INTO v_estudiantes_sin_nota
    FROM DETALLE_MATRICULA dm
    WHERE dm.cod_grupo = :cod_grupo
    AND dm.estado_inscripcion = 'INSCRITO'
    AND NOT EXISTS (
        SELECT 1 FROM NOTA_DEFINITIVA nd
        WHERE nd.cod_detalle_matricula = dm.cod_detalle_matricula
    );
    
    IF v_estudiantes_sin_nota > 0 THEN
        :status_code := 400;
        HTP.PRINT('{"error": "Hay ' || v_estudiantes_sin_nota || 
                  ' estudiante(s) sin nota definitiva", "estudiantes_sin_nota": ' || 
                  v_estudiantes_sin_nota || '}');
        RETURN;
    END IF;
    
    -- Cerrar el grupo
    UPDATE GRUPO
    SET estado_grupo = 'CERRADO',
        notas_cerradas = 'S'
    WHERE cod_grupo = :cod_grupo;
    
    COMMIT;
    
    :status_code := 200;
    HTP.PRINT('{"success": true, "message": "Notas cerradas exitosamente"}');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        :status_code := 500;
        HTP.PRINT('{"error": "' || REPLACE(SQLERRM, '"', '\"') || '"}');
END;
]'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ POST /cerrar-notas/:cod_grupo creado');
END;
/

-- =====================================================
-- ENDPOINT 7: GET /estadisticas/:cod_grupo
-- Descripción: Estadísticas de un grupo
-- CORRECCIONES: Usa estado_inscripcion
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
    v_total NUMBER;
    v_con_nota NUMBER;
    v_sin_nota NUMBER;
    v_aprobados NUMBER;
    v_reprobados NUMBER;
    v_promedio NUMBER;
    v_nota_max NUMBER;
    v_nota_min NUMBER;
    v_porcentaje_aprobacion NUMBER;
BEGIN
    -- Total de estudiantes
    SELECT COUNT(*)
    INTO v_total
    FROM DETALLE_MATRICULA
    WHERE cod_grupo = :cod_grupo
    AND estado_inscripcion = 'INSCRITO';
    
    -- Estudiantes con nota definitiva
    SELECT COUNT(*)
    INTO v_con_nota
    FROM DETALLE_MATRICULA dm
    JOIN NOTA_DEFINITIVA nd ON dm.cod_detalle_matricula = nd.cod_detalle_matricula
    WHERE dm.cod_grupo = :cod_grupo
    AND dm.estado_inscripcion = 'INSCRITO';
    
    v_sin_nota := v_total - v_con_nota;
    
    -- Estadísticas de notas
    SELECT 
        COUNT(CASE WHEN nd.resultado = 'APROBADO' THEN 1 END),
        COUNT(CASE WHEN nd.resultado IN ('REPROBADO','PERDIDA') THEN 1 END),
        COALESCE(AVG(nd.nota_final), 0),
        COALESCE(MAX(nd.nota_final), 0),
        COALESCE(MIN(nd.nota_final), 0)
    INTO v_aprobados, v_reprobados, v_promedio, v_nota_max, v_nota_min
    FROM DETALLE_MATRICULA dm
    JOIN NOTA_DEFINITIVA nd ON dm.cod_detalle_matricula = nd.cod_detalle_matricula
    WHERE dm.cod_grupo = :cod_grupo
    AND dm.estado_inscripcion = 'INSCRITO';
    
    -- Porcentaje de aprobación
    IF v_con_nota > 0 THEN
        v_porcentaje_aprobacion := ROUND((v_aprobados / v_con_nota) * 100, 2);
    ELSE
        v_porcentaje_aprobacion := 0;
    END IF;
    
    :status_code := 200;
    HTP.PRINT(JSON_OBJECT(
        'total_estudiantes' VALUE v_total,
        'con_nota' VALUE v_con_nota,
        'sin_nota' VALUE v_sin_nota,
        'aprobados' VALUE v_aprobados,
        'reprobados' VALUE v_reprobados,
        'promedio_grupo' VALUE ROUND(v_promedio, 2),
        'nota_maxima' VALUE v_nota_max,
        'nota_minima' VALUE v_nota_min,
        'porcentaje_aprobacion' VALUE v_porcentaje_aprobacion
    ));
    
EXCEPTION
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

PROMPT =====================================================
PROMPT Módulo docente completado
PROMPT =====================================================
PROMPT Total de endpoints: 7
PROMPT - GET /docente/mis-grupos/:cod_docente
PROMPT - GET /docente/estudiantes/:cod_grupo
PROMPT - GET /docente/reglas-evaluacion/:cod_grupo
PROMPT - POST /docente/registrar-nota
PROMPT - PUT /docente/actualizar-nota/:cod_calificacion
PROMPT - POST /docente/cerrar-notas/:cod_grupo
PROMPT - GET /docente/estadisticas/:cod_grupo
PROMPT =====================================================
