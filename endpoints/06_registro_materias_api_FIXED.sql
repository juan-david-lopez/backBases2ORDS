-- =====================================================
    ORDS.DEFINE_HANDLER(
        p_module_name => 'registro_materias',
        p_pattern     => 'inscribir',
        p_method      => 'POST',
        p_source_type => 'plsql/block',
        p_source      => q'![
DECLARE
    v_status NUMBER;
    v_response CLOB;
BEGIN
    -- Delegar parsing e inserción al paquete puente
    PKG_ORDS_BRIDGE.inscribir_from_json(:body, v_status, v_response);
    :status_code := v_status;
    HTP.PRINT(v_response);
EXCEPTION
    WHEN OTHERS THEN
        :status_code := 500;
        HTP.PRINT('{"error":"' || REPLACE(SQLERRM, '"', '\"') || '"}');
END;
]!'
    );
            -- Verificar si ya está inscrito
            CASE 
                WHEN EXISTS (
                    SELECT 1 FROM DETALLE_MATRICULA dm2
                    JOIN MATRICULA m2 ON dm2.cod_matricula = m2.cod_matricula
                    JOIN GRUPO g2 ON dm2.cod_grupo = g2.cod_grupo
                    JOIN PERIODO_ACADEMICO pa2 ON m2.cod_periodo = pa2.cod_periodo
                    WHERE m2.cod_estudiante = :cod_estudiante
                    AND g2.cod_asignatura = a.cod_asignatura
                    AND pa2.estado_periodo = 'ACTIVO'
                    AND dm2.estado_inscripcion = 'INSCRITO'
                ) THEN 'SI'
                ELSE 'NO'
            END as ya_inscrito,
            -- Verificar si ya la aprobó
            CASE 
                WHEN EXISTS (
                    SELECT 1 FROM NOTA_DEFINITIVA nd
                    JOIN DETALLE_MATRICULA dm_nd2 ON nd.cod_detalle_matricula = dm_nd2.cod_detalle_matricula
                    JOIN MATRICULA m_nd2 ON dm_nd2.cod_matricula = m_nd2.cod_matricula
                    JOIN GRUPO g_nd2 ON dm_nd2.cod_grupo = g_nd2.cod_grupo
                    WHERE m_nd2.cod_estudiante = :cod_estudiante
                    AND g_nd2.cod_asignatura = a.cod_asignatura
                    AND nd.resultado = 'APROBADO'
                ) THEN 'SI'
                ELSE 'NO'
            END as ya_aprobada,
            -- Verificar si excedería límite de créditos
            CASE 
                WHEN v_creditos_actuales + a.creditos <= v_creditos_max THEN 'SI'
                ELSE 'NO'
            END as dentro_limite_creditos
        FROM ASIGNATURA a
        WHERE a.cod_programa = v_cod_programa
        AND a.estado_asignatura = 'ACTIVO'
    ) LOOP
        -- Solo mostrar si cumple todos los criterios
        IF rec.cumple_prerequisitos = 'SI' 
           AND rec.ya_inscrito = 'NO' 
           AND rec.ya_aprobada = 'NO'
           AND rec.dentro_limite_creditos = 'SI' THEN
            
            HTP.PRINT(JSON_OBJECT(
                'cod_asignatura' VALUE rec.cod_asignatura,
                'nombre' VALUE rec.nombre_asignatura,
                'creditos' VALUE rec.creditos,
                'nivel' VALUE rec.nivel,
                'prerequisitos' VALUE rec.prerequisitos,
                'puede_inscribir' VALUE 'SI',
                'creditos_disponibles' VALUE (v_creditos_max - v_creditos_actuales)
            ) || ',');
        END IF;
    END LOOP;
    HTP.PRINT('{}]');
    
    :status_code := 200;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        :status_code := 404;
        HTP.PRINT('{"error": "Estudiante no encontrado"}');
    WHEN OTHERS THEN
        :status_code := 500;
        HTP.PRINT('{"error": "' || REPLACE(SQLERRM, '"', '\"') || '"}');
END;
]!'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /disponibles/:cod_estudiante creado');
END;
/

-- =====================================================
-- ENDPOINT 2: GET /grupos/:cod_asignatura
-- Descripción: Grupos disponibles de una asignatura
-- CORRECCIONES: Usa estado_grupo
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
        p_source      => q'![
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
            (g.cupo_maximo - g.cupo_disponible) as cupo_ocupado,
            a.nombre_asignatura,
            a.creditos,
            -- Información del docente
            d.primer_nombre || ' ' || d.primer_apellido as nombre_docente,
            d.titulo_academico,
            -- Horarios del grupo
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
        JOIN DOCENTE d ON g.cod_docente = d.cod_docente
        JOIN PERIODO_ACADEMICO pa ON g.cod_periodo = pa.cod_periodo
        WHERE g.cod_asignatura = :cod_asignatura
        AND pa.estado_periodo = 'ACTIVO'
        AND g.estado_grupo = 'ACTIVO'
        AND g.cupo_disponible > 0
        ORDER BY g.numero_grupo
    ) LOOP
        HTP.PRINT(JSON_OBJECT(
            'cod_grupo' VALUE rec.cod_grupo,
            'numero_grupo' VALUE rec.numero_grupo,
            'asignatura' VALUE rec.nombre_asignatura,
            'creditos' VALUE rec.creditos,
            'modalidad' VALUE rec.modalidad,
            'aula' VALUE rec.aula,
            'docente' VALUE rec.nombre_docente,
            'titulo_docente' VALUE rec.titulo_academico,
            'cupo_maximo' VALUE rec.cupo_maximo,
            'cupo_ocupado' VALUE rec.cupo_ocupado,
            'cupo_disponible' VALUE rec.cupo_disponible,
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
]!'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /grupos/:cod_asignatura creado');
END;
/

-- =====================================================
-- ENDPOINT 3: POST /inscribir
-- Descripción: Inscribir estudiante en un grupo
-- CORRECCIONES: Usa estado_inscripcion
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
        p_source      => q'![
BEGIN
  PKG_ORDS_BRIDGE.ords_inscribir_handler;
END;
]!'
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ POST /inscribir (proc) creado');
END;
/

-- =====================================================
-- ENDPOINT 4: DELETE /retirar/:cod_detalle_matricula
-- Descripción: Retirar estudiante de una asignatura
-- CORRECCIONES: Usa estado_inscripcion, elimina validación de VENTANA_EVENTO
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
        p_source      => q'![
DECLARE
    v_motivo VARCHAR2(200);
BEGIN
    -- Parsear motivo del body (opcional)
    BEGIN
        v_motivo := JSON_VALUE(:body, '$.motivo');
    EXCEPTION
        WHEN OTHERS THEN
            v_motivo := 'RETIRO VOLUNTARIO';
    END;
    
    -- Usar paquete para retirar (incluye validaciones)
    PKG_MATRICULA.retirar_asignatura(
        p_cod_detalle_matricula => :cod_detalle_matricula,
        p_motivo_retiro => v_motivo
    );
    
    :status_code := 200;
    HTP.PRINT('{"success": true, "message": "Retiro exitoso"}');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        IF SQLCODE = -20300 THEN
            :status_code := 404;
            HTP.PRINT('{"error": "Detalle de matrícula no encontrado"}');
        ELSIF SQLCODE = -20301 THEN
            :status_code := 400;
            HTP.PRINT('{"error": "Solo se pueden retirar asignaturas en estado INSCRITO"}');
        ELSE
            :status_code := 500;
            HTP.PRINT('{"error": "' || REPLACE(SQLERRM, '"', '\"') || '"}');
        END IF;
END;
]!'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ DELETE /retirar/:cod_detalle_matricula creado');
END;
/

-- =====================================================
-- ENDPOINT 5: GET /mi-horario/:cod_estudiante
-- Descripción: Horario actual del estudiante
-- CORRECCIONES: Usa estado_inscripcion, estado_grupo
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
        p_source      => q'![
BEGIN
    HTP.PRINT('[');
    FOR rec IN (
        SELECT 
            h.dia_semana,
            TO_CHAR(h.hora_inicio, 'HH24:MI') as hora_inicio,
            TO_CHAR(h.hora_fin, 'HH24:MI') as hora_fin,
            h.aula,
            a.nombre_asignatura,
            a.creditos,
            g.numero_grupo,
            g.modalidad,
            d.primer_nombre || ' ' || d.primer_apellido as nombre_docente
        FROM DETALLE_MATRICULA dm
        JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
        JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
        JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
        JOIN DOCENTE d ON g.cod_docente = d.cod_docente
        JOIN HORARIO h ON g.cod_grupo = h.cod_grupo
        JOIN PERIODO_ACADEMICO pa ON m.cod_periodo = pa.cod_periodo
        WHERE m.cod_estudiante = :cod_estudiante
        AND pa.estado_periodo = 'ACTIVO'
        AND dm.estado_inscripcion = 'INSCRITO'
        ORDER BY 
            CASE h.dia_semana
                WHEN 'LUNES' THEN 1
                WHEN 'MARTES' THEN 2
                WHEN 'MIERCOLES' THEN 3
                WHEN 'JUEVES' THEN 4
                WHEN 'VIERNES' THEN 5
                WHEN 'SABADO' THEN 6
                WHEN 'DOMINGO' THEN 7
            END,
            h.hora_inicio
    ) LOOP
        HTP.PRINT(JSON_OBJECT(
            'dia' VALUE rec.dia_semana,
            'hora_inicio' VALUE rec.hora_inicio,
            'hora_fin' VALUE rec.hora_fin,
            'aula' VALUE rec.aula,
            'asignatura' VALUE rec.nombre_asignatura,
            'creditos' VALUE rec.creditos,
            'grupo' VALUE rec.numero_grupo,
            'modalidad' VALUE rec.modalidad,
            'docente' VALUE rec.nombre_docente
        ) || ',');
    END LOOP;
    HTP.PRINT('{}]');
    
    :status_code := 200;
    
EXCEPTION
    WHEN OTHERS THEN
        :status_code := 500;
        HTP.PRINT('{"error": "' || REPLACE(SQLERRM, '"', '\"') || '"}');
END;
]!'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /mi-horario/:cod_estudiante creado');
END;
/

-- =====================================================
-- ENDPOINT 6: GET /resumen/:cod_estudiante
-- Descripción: Resumen de matrícula del estudiante
-- CORRECCIONES: Usa HISTORIAL_RIESGO, estado_inscripcion
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
    v_periodo VARCHAR2(100);
    v_nivel_riesgo VARCHAR2(20) := 'BAJO';
    v_creditos_actuales NUMBER;
    v_creditos_maximos NUMBER;
    v_promedio NUMBER;
    v_materias_inscritas NUMBER;
BEGIN
    -- Obtener periodo activo
    BEGIN
        SELECT nombre_periodo INTO v_periodo
        FROM PERIODO_ACADEMICO
        WHERE estado_periodo = 'ACTIVO' AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_periodo := 'Sin periodo activo';
    END;
    
    -- Obtener nivel de riesgo más reciente
    BEGIN
        SELECT nivel_riesgo INTO v_nivel_riesgo
        FROM (
            SELECT nivel_riesgo 
            FROM HISTORIAL_RIESGO 
            WHERE cod_estudiante = :cod_estudiante
            ORDER BY fecha_deteccion DESC
        )
        WHERE ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_nivel_riesgo := 'BAJO';
    END;
    
    -- Créditos máximos según riesgo
    v_creditos_maximos := CASE v_nivel_riesgo
        WHEN 'ALTO' THEN 12
        WHEN 'MEDIO' THEN 16
        ELSE 20
    END;
    
    -- Créditos actuales inscritos
    SELECT COALESCE(SUM(a.creditos), 0)
    INTO v_creditos_actuales
    FROM DETALLE_MATRICULA dm
    JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
    JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
    JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
    JOIN PERIODO_ACADEMICO pa ON m.cod_periodo = pa.cod_periodo
    WHERE m.cod_estudiante = :cod_estudiante
    AND pa.estado_periodo = 'ACTIVO'
    AND dm.estado_inscripcion = 'INSCRITO';
    
    -- Contar materias inscritas
    SELECT COUNT(*)
    INTO v_materias_inscritas
    FROM DETALLE_MATRICULA dm
    JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
    JOIN PERIODO_ACADEMICO pa ON m.cod_periodo = pa.cod_periodo
    WHERE m.cod_estudiante = :cod_estudiante
    AND pa.estado_periodo = 'ACTIVO'
    AND dm.estado_inscripcion = 'INSCRITO';
    
    -- Promedio acumulado
    SELECT COALESCE(AVG(nota_final), 0)
    INTO v_promedio
    FROM NOTA_DEFINITIVA
    WHERE cod_estudiante = :cod_estudiante;
    
    :status_code := 200;
    HTP.PRINT(JSON_OBJECT(
        'periodo' VALUE v_periodo,
        'riesgo_academico' VALUE v_nivel_riesgo,
        'creditos_actuales' VALUE v_creditos_actuales,
        'creditos_maximos' VALUE v_creditos_maximos,
        'creditos_disponibles' VALUE (v_creditos_maximos - v_creditos_actuales),
        'materias_inscritas' VALUE v_materias_inscritas,
        'promedio_acumulado' VALUE ROUND(v_promedio, 2)
    ));
    
EXCEPTION
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

SELECT JSON_VALUE('{"cod_estudiante":"202500123","cod_grupo":301}', '$.cod_estudiante') FROM DUAL;
SELECT jt.cod_estudiante, jt.cod_grupo
FROM JSON_TABLE('{"cod_estudiante":"202500123","cod_grupo":301}',
                '$'
                COLUMNS (cod_estudiante VARCHAR2(50) PATH '$.cod_estudiante',
                         cod_grupo     NUMBER       PATH '$.cod_grupo')
               ) jt;
PROMPT =====================================================
PROMPT Módulo registro_materias completado
PROMPT =====================================================
PROMPT Total de endpoints: 6
PROMPT - GET /registro-materias/disponibles/:cod_estudiante
PROMPT - GET /registro-materias/grupos/:cod_asignatura
PROMPT - POST /registro-materias/inscribir
PROMPT - DELETE /registro-materias/retirar/:cod_detalle_matricula
PROMPT - GET /registro-materias/mi-horario/:cod_estudiante
PROMPT - GET /registro-materias/resumen/:cod_estudiante
PROMPT =====================================================
