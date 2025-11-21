-- =====================================================
-- API DE ALERTAS Y REPORTES - VERSIÓN CORREGIDA
-- Archivo: 08_alertas_reportes_api_FIXED.sql
-- Propósito: Endpoints de alertas tempranas y reportes académicos
-- Ejecutar como: ACADEMICO
-- CORRECCIONES: Usa nombres de columnas reales de la BD
-- =====================================================

SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT =====================================================
PROMPT Creando módulo ALERTAS Y REPORTES (CORREGIDO)
PROMPT =====================================================

-- =====================================================
-- MÓDULO: alertas
-- =====================================================

BEGIN
    ORDS.DEFINE_MODULE(
        p_module_name    => 'alertas',
        p_base_path      => '/alertas/',
        p_items_per_page => 0,
        p_status         => 'PUBLISHED',
        p_comments       => 'Módulo de alertas tempranas y reportes'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Módulo alertas creado');
END;
/

-- =====================================================
-- ENDPOINT 1: GET /alertas/riesgo-academico
-- Descripción: Lista estudiantes en riesgo académico
-- CORRECCIONES: Usa HISTORIAL_RIESGO, estado_estudiante, estado_inscripcion
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'alertas',
        p_pattern     => 'riesgo-academico'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'alertas',
        p_pattern     => 'riesgo-academico',
        p_method      => 'GET',
        p_source_type => 'plsql/block',
        p_source      => q'!
BEGIN
    HTP.PRINT('[');
    FOR rec IN (
        SELECT 
            e.cod_estudiante,
            e.primer_nombre || ' ' || e.primer_apellido as nombre_completo,
            e.correo_institucional,
            hr.nivel_riesgo,
            p.nombre_programa,
            -- Promedio acumulado
            (SELECT COALESCE(AVG(nd.nota_final), 0)
             FROM NOTA_DEFINITIVA nd
             JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
             JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
             WHERE m.cod_estudiante = e.cod_estudiante) as promedio_acumulado,
            -- Asignaturas reprobadas
            (SELECT COUNT(*)
             FROM NOTA_DEFINITIVA nd
             JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
             JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
             WHERE m.cod_estudiante = e.cod_estudiante
             AND nd.resultado IN ('REPROBADO','PERDIDA')) as asignaturas_reprobadas,
            -- Créditos actuales
            (SELECT COALESCE(SUM(a.creditos), 0)
             FROM DETALLE_MATRICULA dm
             JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
             JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
             JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
             JOIN PERIODO_ACADEMICO pa ON m.cod_periodo = pa.cod_periodo
             WHERE m.cod_estudiante = e.cod_estudiante
             AND pa.estado_periodo = 'ACTIVO'
             AND dm.estado_inscripcion = 'INSCRITO') as creditos_matriculados,
            ROW_NUMBER() OVER (PARTITION BY e.cod_estudiante ORDER BY hr.fecha_deteccion DESC) as rn
        FROM ESTUDIANTE e
        JOIN PROGRAMA_ACADEMICO p ON e.cod_programa = p.cod_programa
        LEFT JOIN HISTORIAL_RIESGO hr ON e.cod_estudiante = hr.cod_estudiante
        WHERE e.estado_estudiante = 'ACTIVO'
        AND hr.nivel_riesgo IN ('MEDIO', 'ALTO')
    ) 
    WHERE rec.rn = 1
    LOOP
        HTP.PRINT(JSON_OBJECT(
            'cod_estudiante' VALUE rec.cod_estudiante,
            'nombre' VALUE rec.nombre_completo,
            'correo' VALUE rec.correo_institucional,
            'riesgo' VALUE rec.nivel_riesgo,
            'programa' VALUE rec.nombre_programa,
            'promedio_acumulado' VALUE ROUND(rec.promedio_acumulado, 2),
            'asignaturas_reprobadas' VALUE rec.asignaturas_reprobadas,
            'creditos_matriculados' VALUE rec.creditos_matriculados
        ) || ',');
    END LOOP;
    HTP.PRINT('{}]');
    
    :status_code := 200;
    
EXCEPTION
    WHEN OTHERS THEN
        :status_code := 500;
        HTP.PRINT('{\"error\": \"' || REPLACE(SQLERRM, '\"', '\\\"') || '\"}');
END;
!'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /alertas/riesgo-academico creado');
END;
/

-- =====================================================
-- ENDPOINT 2: GET /alertas/estudiante/:cod_estudiante
-- Descripción: Alertas personalizadas para un estudiante
-- CORRECCIONES: Usa HISTORIAL_RIESGO, estado_inscripcion
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'alertas',
        p_pattern     => 'estudiante/:cod_estudiante'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'alertas',
        p_pattern     => 'estudiante/:cod_estudiante',
        p_method      => 'GET',
        p_source_type => 'plsql/block',
        p_source      => q'!
DECLARE
    v_cod_estudiante VARCHAR2(15);
    v_riesgo VARCHAR2(20) := 'BAJO';
    v_promedio NUMBER;
    v_reprobadas NUMBER;
    v_creditos_max NUMBER;
    v_creditos_actuales NUMBER;
    v_alertas JSON_ARRAY_T := JSON_ARRAY_T();
    v_alerta JSON_OBJECT_T;
BEGIN
    v_cod_estudiante := :cod_estudiante;
    
    -- Obtener riesgo más reciente del estudiante
    BEGIN
        SELECT nivel_riesgo INTO v_riesgo
        FROM (
            SELECT nivel_riesgo
            FROM HISTORIAL_RIESGO
            WHERE cod_estudiante = v_cod_estudiante
            ORDER BY fecha_deteccion DESC
        )
        WHERE ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_riesgo := 'BAJO';
    END;

    -- Obtener información académica
    SELECT
        (SELECT COALESCE(AVG(nd.nota_final), 0)
         FROM NOTA_DEFINITIVA nd
         JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
         JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
         WHERE m.cod_estudiante = v_cod_estudiante),
        (SELECT COUNT(*)
         FROM NOTA_DEFINITIVA nd
         JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
         JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
         WHERE m.cod_estudiante = v_cod_estudiante
         AND nd.resultado IN ('REPROBADO','PERDIDA'))
    INTO v_promedio, v_reprobadas
    FROM DUAL;

    -- Créditos máximos según riesgo
    v_creditos_max := CASE v_riesgo
        WHEN 'ALTO' THEN 12
        WHEN 'MEDIO' THEN 16
        ELSE 20
    END;

    -- Créditos actuales
    SELECT COALESCE(SUM(a.creditos), 0)
    INTO v_creditos_actuales
    FROM DETALLE_MATRICULA dm
    JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
    JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
    JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
    JOIN PERIODO_ACADEMICO pa ON m.cod_periodo = pa.cod_periodo
    WHERE m.cod_estudiante = v_cod_estudiante
    AND pa.estado_periodo = 'ACTIVO'
    AND dm.estado_inscripcion = 'INSCRITO';

    -- Generar alertas

    -- Alerta 1: Riesgo académico
    IF v_riesgo IN ('MEDIO', 'ALTO') THEN
        v_alerta := JSON_OBJECT_T();
        v_alerta.put('tipo', 'RIESGO_ACADEMICO');
        v_alerta.put('nivel', v_riesgo);
        v_alerta.put('mensaje', 'Estudiante en riesgo academico ' || v_riesgo);
        v_alerta.put('recomendacion', CASE v_riesgo
            WHEN 'ALTO' THEN 'Maximo 12 creditos. Se recomienda tutoria academica.'
            ELSE 'Maximo 16 creditos. Monitorear desempeno.'
        END);
        v_alertas.append(v_alerta.to_clob());
    END IF;

    -- Alerta 2: Promedio bajo
    IF v_promedio < 3.0 AND v_promedio > 0 THEN
        v_alerta := JSON_OBJECT_T();
        v_alerta.put('tipo', 'PROMEDIO_BAJO');
        v_alerta.put('nivel', 'ADVERTENCIA');
        v_alerta.put('promedio', ROUND(v_promedio, 2));
        v_alerta.put('mensaje', 'Promedio acumulado por debajo de 3.0');
        v_alerta.put('recomendacion', 'Buscar apoyo academico y mejorar habitos de estudio');
        v_alertas.append(v_alerta.to_clob());
    END IF;

    -- Alerta 3: Asignaturas reprobadas
    IF v_reprobadas > 0 THEN
        v_alerta := JSON_OBJECT_T();
        v_alerta.put('tipo', 'ASIGNATURAS_REPROBADAS');
        v_alerta.put('nivel', CASE WHEN v_reprobadas >= 3 THEN 'CRITICO' ELSE 'ADVERTENCIA' END);
        v_alerta.put('cantidad', v_reprobadas);
        v_alerta.put('mensaje', v_reprobadas || ' asignatura(s) reprobada(s)');
        v_alerta.put('recomendacion', 'Debe inscribir asignaturas perdidas prioritariamente');
        v_alertas.append(v_alerta.to_clob());
    END IF;

    -- Alerta 4: Cerca del límite de créditos
    IF v_creditos_actuales >= v_creditos_max * 0.9 THEN
        v_alerta := JSON_OBJECT_T();
        v_alerta.put('tipo', 'LIMITE_CREDITOS');
        v_alerta.put('nivel', 'INFO');
        v_alerta.put('creditos_actuales', v_creditos_actuales);
        v_alerta.put('creditos_maximos', v_creditos_max);
        v_alerta.put('mensaje', 'Cerca del limite de creditos permitidos');
        v_alerta.put('recomendacion', 'Quedan ' || (v_creditos_max - v_creditos_actuales) || ' creditos disponibles');
        v_alertas.append(v_alerta.to_clob());
    END IF;

    :status_code := 200;
    HTP.PRINT(JSON_OBJECT(
        'cod_estudiante', v_cod_estudiante,
        'riesgo_academico', v_riesgo,
        'promedio_acumulado', ROUND(v_promedio, 2),
        'asignaturas_reprobadas', v_reprobadas,
        'creditos_matriculados', v_creditos_actuales,
        'creditos_maximos', v_creditos_max,
        'total_alertas', v_alertas.get_size(),
        'alertas', v_alertas
    ));

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        :status_code := 404;
        HTP.PRINT('{"error": "Estudiante no encontrado"}');
    WHEN OTHERS THEN
        :status_code := 500;
        HTP.PRINT('{"error": "' || REPLACE(SQLERRM, '"', '\\"') || '"}');
END;
!'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /estudiante/:cod_estudiante creado');
END;
/

-- =====================================================
-- ENDPOINT 3: GET /alertas/asistencia-baja/:cod_grupo
-- Descripción: Placeholder para asistencia (feature futuro)
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'alertas',
        p_pattern     => 'asistencia-baja/:cod_grupo'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'alertas',
        p_pattern     => 'asistencia-baja/:cod_grupo',
        p_method      => 'GET',
        p_source_type => 'plsql/block',
        p_source      => q'!
BEGIN
    :status_code := 200;
    HTP.PRINT('{\"message\": \"Funcionalidad de asistencia pendiente\", \"estudiantes\": []}');
END;
!'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /asistencia-baja/:cod_grupo creado (placeholder)');
END;
/

-- =====================================================
-- ENDPOINT 4: GET /alertas/reporte-general
-- Descripción: Estadísticas generales del sistema
-- CORRECCIONES: Usa estado_estudiante, estado_grupo, estado_docente
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'alertas',
        p_pattern     => 'reporte-general'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'alertas',
        p_pattern     => 'reporte-general',
        p_method      => 'GET',
        p_source_type => 'plsql/block',
        p_source      => q'!
DECLARE
    v_total_estudiantes NUMBER;
    v_estudiantes_activos NUMBER;
    v_riesgo_alto NUMBER := 0;
    v_riesgo_medio NUMBER := 0;
    v_riesgo_bajo NUMBER := 0;
    v_total_grupos NUMBER;
    v_grupos_activos NUMBER;
    v_total_docentes NUMBER;
    v_promedio_general NUMBER;
BEGIN
    -- Estadísticas de estudiantes
    SELECT COUNT(*),
           COUNT(CASE WHEN estado_estudiante = 'ACTIVO' THEN 1 END)
    INTO v_total_estudiantes, v_estudiantes_activos
    FROM ESTUDIANTE;

    -- Riesgo académico (de HISTORIAL_RIESGO más reciente)
    SELECT 
        COUNT(CASE WHEN nivel_riesgo = 'ALTO' THEN 1 END),
        COUNT(CASE WHEN nivel_riesgo = 'MEDIO' THEN 1 END),
        COUNT(CASE WHEN nivel_riesgo = 'BAJO' OR nivel_riesgo IS NULL THEN 1 END)
    INTO v_riesgo_alto, v_riesgo_medio, v_riesgo_bajo
    FROM (
        SELECT cod_estudiante, nivel_riesgo,
               ROW_NUMBER() OVER (PARTITION BY cod_estudiante ORDER BY fecha_deteccion DESC) as rn
        FROM HISTORIAL_RIESGO
    ) WHERE rn = 1;

    -- Estadísticas de grupos
    SELECT COUNT(*),
           COUNT(CASE WHEN estado_grupo = 'ACTIVO' THEN 1 END)
    INTO v_total_grupos, v_grupos_activos
    FROM GRUPO;

    -- Total docentes activos
    SELECT COUNT(*) INTO v_total_docentes
    FROM DOCENTE WHERE estado_docente = 'ACTIVO';

    -- Promedio general
    SELECT COALESCE(AVG(nd.nota_final), 0)
    INTO v_promedio_general
    FROM NOTA_DEFINITIVA nd;

    :status_code := 200;
    HTP.PRINT(JSON_OBJECT(
        'estudiantes' VALUE JSON_OBJECT(
            'total' VALUE v_total_estudiantes,
            'activos' VALUE v_estudiantes_activos,
            'riesgo_alto' VALUE v_riesgo_alto,
            'riesgo_medio' VALUE v_riesgo_medio,
            'riesgo_bajo' VALUE v_riesgo_bajo
        ),
        'grupos' VALUE JSON_OBJECT(
            'total' VALUE v_total_grupos,
            'activos' VALUE v_grupos_activos
        ),
        'docentes' VALUE JSON_OBJECT(
            'activos' VALUE v_total_docentes
        ),
        'academico' VALUE JSON_OBJECT(
            'promedio_general' VALUE ROUND(v_promedio_general, 2)
        )
    ));

EXCEPTION
    WHEN OTHERS THEN
        :status_code := 500;
        HTP.PRINT('{"error": "' || REPLACE(SQLERRM, '"', '\\"') || '"}');
END;
!'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /reporte-general creado');
END;
/

PROMPT =====================================================
PROMPT Módulo alertas completado
PROMPT =====================================================
PROMPT Total de endpoints: 4
PROMPT - GET /alertas/riesgo-academico
PROMPT - GET /alertas/estudiante/:cod_estudiante
PROMPT - GET /alertas/asistencia-baja/:cod_grupo (placeholder)
PROMPT - GET /alertas/reporte-general
PROMPT =====================================================
PROMPT
PROMPT NOTA: Endpoint de ventanas-calendario eliminado
PROMPT (requiere crear tabla VENTANA_EVENTO)
PROMPT =====================================================
