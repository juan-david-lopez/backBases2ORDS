-- =====================================================
-- API DE ALERTAS Y REPORTES
-- Archivo: 08_alertas_reportes_api.sql
-- Propósito: Endpoints de alertas tempranas y reportes académicos
-- Ejecutar como: ACADEMICO
-- =====================================================

SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT =====================================================
PROMPT Creando módulo ALERTAS Y REPORTES
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
        p_source      => q'[
BEGIN
    FOR rec IN (
        SELECT 
            e.cod_estudiante,
            e.primer_nombre || ' ' || e.primer_apellido as nombre_completo,
            e.correo_institucional,
            e.riesgo_academico,
            p.nombre_programa,
            -- Promedio acumulado
            (SELECT COALESCE(AVG(nota_final), 0)
             FROM NOTA_DEFINITIVA
             WHERE cod_estudiante = e.cod_estudiante) as promedio_acumulado,
            -- Asignaturas reprobadas
            (SELECT COUNT(*)
             FROM NOTA_DEFINITIVA
             WHERE cod_estudiante = e.cod_estudiante
             AND resultado = 'REPROBADO') as asignaturas_reprobadas,
            -- Créditos actuales
            (SELECT COALESCE(SUM(a.creditos), 0)
             FROM DETALLE_MATRICULA dm
             JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
             JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
             JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
             JOIN PERIODO_ACADEMICO pa ON m.cod_periodo = pa.cod_periodo
             WHERE m.cod_estudiante = e.cod_estudiante
             AND pa.estado = 'ACTIVO'
             AND dm.estado_detalle = 'ACTIVO') as creditos_matriculados
        FROM ESTUDIANTE e
        JOIN PROGRAMA_ACADEMICO p ON e.cod_programa = p.cod_programa
        WHERE e.riesgo_academico IN ('MEDIO', 'ALTO')
        AND e.estado = 'ACTIVO'
        ORDER BY 
            CASE e.riesgo_academico 
                WHEN 'ALTO' THEN 1 
                WHEN 'MEDIO' THEN 2 
                ELSE 3 
            END,
            e.primer_apellido
    ) LOOP
        HTP.PRINT(JSON_OBJECT(
            'cod_estudiante' VALUE rec.cod_estudiante,
            'nombre' VALUE rec.nombre_completo,
            'correo' VALUE rec.correo_institucional,
            'riesgo' VALUE rec.riesgo_academico,
            'programa' VALUE rec.nombre_programa,
            'promedio_acumulado' VALUE ROUND(rec.promedio_acumulado, 2),
            'asignaturas_reprobadas' VALUE rec.asignaturas_reprobadas,
            'creditos_matriculados' VALUE rec.creditos_matriculados
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
    DBMS_OUTPUT.PUT_LINE('✓ GET /riesgo-academico creado');
END;
/

-- =====================================================
-- ENDPOINT 2: GET /alertas/estudiante/:cod_estudiante
-- Descripción: Alertas específicas de un estudiante
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
        p_source      => q'[
DECLARE
    v_riesgo VARCHAR2(20);
    v_promedio NUMBER;
    v_reprobadas NUMBER;
    v_creditos_max NUMBER;
    v_creditos_actuales NUMBER;
    v_alertas JSON_ARRAY_T := JSON_ARRAY_T();
    v_alerta JSON_OBJECT_T;
BEGIN
    -- Obtener información del estudiante
    SELECT 
        COALESCE(riesgo_academico, 'BAJO'),
        (SELECT COALESCE(AVG(nota_final), 0) 
         FROM NOTA_DEFINITIVA 
         WHERE cod_estudiante = :cod_estudiante),
        (SELECT COUNT(*) 
         FROM NOTA_DEFINITIVA 
         WHERE cod_estudiante = :cod_estudiante 
         AND resultado = 'REPROBADO')
    INTO v_riesgo, v_promedio, v_reprobadas
    FROM ESTUDIANTE
    WHERE cod_estudiante = :cod_estudiante;
    
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
    WHERE m.cod_estudiante = :cod_estudiante
    AND pa.estado = 'ACTIVO'
    AND dm.estado_detalle = 'ACTIVO';
    
    -- Generar alertas
    
    -- Alerta 1: Riesgo académico
    IF v_riesgo IN ('MEDIO', 'ALTO') THEN
        v_alerta := JSON_OBJECT_T();
        v_alerta.put('tipo', 'RIESGO_ACADEMICO');
        v_alerta.put('nivel', v_riesgo);
        v_alerta.put('mensaje', 'Estudiante en riesgo académico ' || v_riesgo);
        v_alerta.put('recomendacion', CASE v_riesgo
            WHEN 'ALTO' THEN 'Máximo 12 créditos. Se recomienda tutoría académica.'
            ELSE 'Máximo 16 créditos. Monitorear desempeño.'
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
        v_alerta.put('recomendacion', 'Buscar apoyo académico y mejorar hábitos de estudio');
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
        v_alerta.put('mensaje', 'Cerca del límite de créditos permitidos');
        v_alerta.put('recomendacion', 'Quedan ' || (v_creditos_max - v_creditos_actuales) || ' créditos disponibles');
        v_alertas.append(v_alerta.to_clob());
    END IF;
    
    :status_code := 200;
    HTP.PRINT(JSON_OBJECT(
        'cod_estudiante' VALUE :cod_estudiante,
        'riesgo_academico' VALUE v_riesgo,
        'promedio_acumulado' VALUE ROUND(v_promedio, 2),
        'asignaturas_reprobadas' VALUE v_reprobadas,
        'creditos_matriculados' VALUE v_creditos_actuales,
        'creditos_maximos' VALUE v_creditos_max,
        'total_alertas' VALUE v_alertas.get_size(),
        'alertas' VALUE v_alertas
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
    DBMS_OUTPUT.PUT_LINE('✓ GET /estudiante/:cod_estudiante creado');
END;
/

-- =====================================================
-- ENDPOINT 3: GET /alertas/asistencia-baja/:cod_grupo
-- Descripción: Estudiantes con asistencia baja (futuro)
-- Por ahora retorna placeholder
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
        p_source      => q'[
BEGIN
    :status_code := 200;
    HTP.PRINT('{"message": "Funcionalidad de asistencia pendiente de implementación", "estudiantes": []}');
EXCEPTION
    WHEN OTHERS THEN
        :status_code := 500;
        HTP.PRINT('{"error": "' || REPLACE(SQLERRM, '"', '\"') || '"}');
END;
]'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /asistencia-baja/:cod_grupo creado (placeholder)');
END;
/

-- =====================================================
-- ENDPOINT 4: GET /alertas/ventanas-calendario
-- Descripción: Ventanas de calendario activas
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'alertas',
        p_pattern     => 'ventanas-calendario'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'alertas',
        p_pattern     => 'ventanas-calendario',
        p_method      => 'GET',
        p_source_type => 'plsql/block',
        p_source      => q'[
BEGIN
    FOR rec IN (
        SELECT 
            ve.cod_ventana,
            ve.tipo_evento,
            ve.fecha_inicio,
            ve.fecha_fin,
            pa.nombre_periodo,
            pa.cod_periodo,
            CASE 
                WHEN SYSDATE < ve.fecha_inicio THEN 'PENDIENTE'
                WHEN SYSDATE BETWEEN ve.fecha_inicio AND ve.fecha_fin THEN 'ACTIVA'
                ELSE 'CERRADA'
            END as estado_ventana,
            CASE 
                WHEN SYSDATE < ve.fecha_inicio THEN ve.fecha_inicio - SYSDATE
                WHEN SYSDATE BETWEEN ve.fecha_inicio AND ve.fecha_fin THEN ve.fecha_fin - SYSDATE
                ELSE 0
            END as dias_restantes
        FROM VENTANA_EVENTO ve
        JOIN PERIODO_ACADEMICO pa ON ve.cod_periodo = pa.cod_periodo
        WHERE pa.estado = 'ACTIVO'
        ORDER BY ve.fecha_inicio
    ) LOOP
        HTP.PRINT(JSON_OBJECT(
            'cod_ventana' VALUE rec.cod_ventana,
            'tipo_evento' VALUE rec.tipo_evento,
            'fecha_inicio' VALUE TO_CHAR(rec.fecha_inicio, 'YYYY-MM-DD'),
            'fecha_fin' VALUE TO_CHAR(rec.fecha_fin, 'YYYY-MM-DD'),
            'periodo' VALUE rec.nombre_periodo,
            'estado' VALUE rec.estado_ventana,
            'dias_restantes' VALUE FLOOR(rec.dias_restantes)
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
    DBMS_OUTPUT.PUT_LINE('✓ GET /ventanas-calendario creado');
END;
/

-- =====================================================
-- ENDPOINT 5: GET /alertas/reporte-general
-- Descripción: Reporte general del sistema
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
        p_source      => q'[
DECLARE
    v_total_estudiantes NUMBER;
    v_estudiantes_activos NUMBER;
    v_riesgo_alto NUMBER;
    v_riesgo_medio NUMBER;
    v_riesgo_bajo NUMBER;
    v_total_grupos NUMBER;
    v_grupos_activos NUMBER;
    v_total_docentes NUMBER;
    v_promedio_general NUMBER;
BEGIN
    -- Estadísticas de estudiantes
    SELECT 
        COUNT(*),
        COUNT(CASE WHEN estado = 'ACTIVO' THEN 1 END),
        COUNT(CASE WHEN riesgo_academico = 'ALTO' THEN 1 END),
        COUNT(CASE WHEN riesgo_academico = 'MEDIO' THEN 1 END),
        COUNT(CASE WHEN riesgo_academico = 'BAJO' OR riesgo_academico IS NULL THEN 1 END)
    INTO v_total_estudiantes, v_estudiantes_activos, 
         v_riesgo_alto, v_riesgo_medio, v_riesgo_bajo
    FROM ESTUDIANTE;
    
    -- Estadísticas de grupos
    SELECT 
        COUNT(*),
        COUNT(CASE WHEN estado = 'ACTIVO' THEN 1 END)
    INTO v_total_grupos, v_grupos_activos
    FROM GRUPO;
    
    -- Total docentes activos
    SELECT COUNT(*) INTO v_total_docentes
    FROM DOCENTE WHERE estado = 'ACTIVO';
    
    -- Promedio general
    SELECT COALESCE(AVG(nota_final), 0)
    INTO v_promedio_general
    FROM NOTA_DEFINITIVA;
    
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
        HTP.PRINT('{"error": "' || REPLACE(SQLERRM, '"', '\"') || '"}');
END;
]'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /reporte-general creado');
END;
/

PROMPT
PROMPT =====================================================
PROMPT Módulo ALERTAS Y REPORTES creado exitosamente
PROMPT =====================================================
PROMPT
PROMPT Endpoints disponibles:
PROMPT   GET /alertas/riesgo-academico
PROMPT   GET /alertas/estudiante/:cod_estudiante
PROMPT   GET /alertas/asistencia-baja/:cod_grupo
PROMPT   GET /alertas/ventanas-calendario
PROMPT   GET /alertas/reporte-general
PROMPT
PROMPT =====================================================

exit;
