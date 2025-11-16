-- =====================================================
-- CORRECCIÓN FINAL DE TODOS LOS ENDPOINTS ORDS
-- Sistema Académico - 100% Funcional
-- =====================================================

SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT =====================================================
PROMPT CORRECCIÓN FINAL DE ENDPOINTS ORDS - 100%
PROMPT =====================================================
PROMPT ''

-- =====================================================
-- 1. FIX: GET /estudiantes/:codigo/matriculas (403)
-- =====================================================
PROMPT 'Corrigiendo GET /estudiantes/:codigo/matriculas...'

BEGIN
    -- Eliminar template y handler existentes
    BEGIN
        ORDS.DELETE_TEMPLATE(
            p_module_name => 'estudiantes',
            p_pattern     => ':codigo/matriculas'
        );
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
    
    -- Recrear template
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'estudiantes',
        p_pattern     => ':codigo/matriculas'
    );
    
    -- Crear handler corregido
    ORDS.DEFINE_HANDLER(
        p_module_name => 'estudiantes',
        p_pattern     => ':codigo/matriculas',
        p_method      => 'GET',
        p_source_type => 'json/collection',
        p_source      => 'SELECT 
                            m.cod_matricula,
                            m.cod_periodo,
                            p.nombre_periodo,
                            TO_CHAR(m.fecha_matricula, ''YYYY-MM-DD'') as fecha_matricula,
                            m.estado_matricula,
                            m.total_creditos,
                            COUNT(dm.cod_detalle_matricula) as total_asignaturas
                         FROM MATRICULA m
                         JOIN PERIODO_ACADEMICO p ON m.cod_periodo = p.cod_periodo
                         LEFT JOIN DETALLE_MATRICULA dm ON m.cod_matricula = dm.cod_matricula
                         WHERE m.cod_estudiante = :codigo
                         GROUP BY m.cod_matricula, m.cod_periodo, p.nombre_periodo, 
                                  m.fecha_matricula, m.estado_matricula, m.total_creditos
                         ORDER BY m.fecha_matricula DESC'
    );
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /estudiantes/:codigo/matriculas corregido');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Error: ' || SQLERRM);
END;
/

-- =====================================================
-- 2. FIX: GET /registro_materias/disponibles/:cod_estudiante
-- =====================================================
PROMPT ''
PROMPT 'Corrigiendo GET /registro_materias/disponibles/:cod_estudiante...'

BEGIN
    -- Eliminar y recrear
    BEGIN
        ORDS.DELETE_TEMPLATE(
            p_module_name => 'registro_materias',
            p_pattern     => 'disponibles/:cod_estudiante'
        );
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
    
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'registro_materias',
        p_pattern     => 'disponibles/:cod_estudiante'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'registro_materias',
        p_pattern     => 'disponibles/:cod_estudiante',
        p_method      => 'GET',
        p_source_type => 'json/collection',
        p_source      => 'SELECT 
                            a.cod_asignatura,
                            a.nombre_asignatura,
                            a.creditos,
                            a.semestre_sugerido,
                            a.tipo_asignatura,
                            CASE 
                                WHEN EXISTS (
                                    SELECT 1 FROM PRERREQUISITO pr
                                    WHERE pr.cod_asignatura = a.cod_asignatura
                                ) THEN ''SI'' ELSE ''NO''
                            END as tiene_prerequisitos
                        FROM ASIGNATURA a
                        WHERE a.cod_programa = (
                            SELECT cod_programa 
                            FROM ESTUDIANTE 
                            WHERE cod_estudiante = :cod_estudiante
                        )
                        AND a.estado = ''ACTIVO''
                        AND NOT EXISTS (
                            SELECT 1 
                            FROM NOTA_DEFINITIVA nd
                            JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
                            JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
                            JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
                            WHERE m.cod_estudiante = :cod_estudiante
                            AND g.cod_asignatura = a.cod_asignatura
                            AND nd.resultado = ''APROBADO''
                        )
                        ORDER BY a.semestre_sugerido, a.cod_asignatura'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /registro_materias/disponibles/:cod_estudiante corregido');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Error: ' || SQLERRM);
END;
/

-- =====================================================
-- 3. FIX: GET /registro_materias/grupos/:cod_asignatura
-- =====================================================
PROMPT ''
PROMPT 'Corrigiendo GET /registro_materias/grupos/:cod_asignatura...'

BEGIN
    BEGIN
        ORDS.DELETE_TEMPLATE(
            p_module_name => 'registro_materias',
            p_pattern     => 'grupos/:cod_asignatura'
        );
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
    
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'registro_materias',
        p_pattern     => 'grupos/:cod_asignatura'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'registro_materias',
        p_pattern     => 'grupos/:cod_asignatura',
        p_method      => 'GET',
        p_source_type => 'json/collection',
        p_source      => 'SELECT 
                            g.cod_grupo,
                            g.numero_grupo,
                            g.cupo_maximo,
                            g.cupo_disponible,
                            g.modalidad,
                            d.primer_nombre || '' '' || d.primer_apellido as docente,
                            p.nombre_periodo,
                            a.nombre_asignatura,
                            a.creditos
                        FROM GRUPO g
                        JOIN DOCENTE d ON g.cod_docente = d.cod_docente
                        JOIN PERIODO_ACADEMICO p ON g.cod_periodo = p.cod_periodo
                        JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
                        WHERE g.cod_asignatura = :cod_asignatura
                        AND g.estado_grupo = ''ACTIVO''
                        AND p.estado_periodo = ''ACTIVO''
                        AND g.cupo_disponible > 0
                        ORDER BY g.numero_grupo'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /registro_materias/grupos/:cod_asignatura corregido');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Error: ' || SQLERRM);
END;
/

-- =====================================================
-- 4. FIX: GET /registro_materias/mi-horario/:cod_estudiante
-- =====================================================
PROMPT ''
PROMPT 'Corrigiendo GET /registro_materias/mi-horario/:cod_estudiante...'

BEGIN
    BEGIN
        ORDS.DELETE_TEMPLATE(
            p_module_name => 'registro_materias',
            p_pattern     => 'mi-horario/:cod_estudiante'
        );
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
    
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'registro_materias',
        p_pattern     => 'mi-horario/:cod_estudiante'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'registro_materias',
        p_pattern     => 'mi-horario/:cod_estudiante',
        p_method      => 'GET',
        p_source_type => 'json/collection',
        p_source      => 'SELECT 
                            a.cod_asignatura,
                            a.nombre_asignatura,
                            g.numero_grupo,
                            h.dia_semana,
                            h.hora_inicio,
                            h.hora_fin,
                            h.aula,
                            d.primer_nombre || '' '' || d.primer_apellido as docente
                        FROM DETALLE_MATRICULA dm
                        JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
                        JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
                        JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
                        JOIN DOCENTE d ON g.cod_docente = d.cod_docente
                        JOIN HORARIO h ON g.cod_grupo = h.cod_grupo
                        JOIN PERIODO_ACADEMICO p ON m.cod_periodo = p.cod_periodo
                        WHERE m.cod_estudiante = :cod_estudiante
                        AND p.estado_periodo = ''ACTIVO''
                        AND dm.estado_inscripcion = ''INSCRITO''
                        ORDER BY 
                            CASE h.dia_semana
                                WHEN ''LUNES'' THEN 1
                                WHEN ''MARTES'' THEN 2
                                WHEN ''MIERCOLES'' THEN 3
                                WHEN ''JUEVES'' THEN 4
                                WHEN ''VIERNES'' THEN 5
                                WHEN ''SABADO'' THEN 6
                                ELSE 7
                            END,
                            h.hora_inicio'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /registro_materias/mi-horario/:cod_estudiante corregido');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Error: ' || SQLERRM);
END;
/

-- =====================================================
-- 5. FIX: GET /registro_materias/resumen/:cod_estudiante
-- =====================================================
PROMPT ''
PROMPT 'Corrigiendo GET /registro_materias/resumen/:cod_estudiante...'

BEGIN
    BEGIN
        ORDS.DELETE_TEMPLATE(
            p_module_name => 'registro_materias',
            p_pattern     => 'resumen/:cod_estudiante'
        );
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
    
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'registro_materias',
        p_pattern     => 'resumen/:cod_estudiante'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'registro_materias',
        p_pattern     => 'resumen/:cod_estudiante',
        p_method      => 'GET',
        p_source_type => 'json/object',
        p_source      => 'SELECT 
                            e.cod_estudiante,
                            e.primer_nombre || '' '' || e.primer_apellido as nombre_completo,
                            prog.nombre_programa,
                            NVL(m.cod_matricula, 0) as cod_matricula,
                            NVL(m.total_creditos, 0) as creditos_matriculados,
                            NVL(COUNT(dm.cod_detalle_matricula), 0) as total_asignaturas,
                            NVL(p.nombre_periodo, ''Sin matrícula activa'') as periodo
                        FROM ESTUDIANTE e
                        JOIN PROGRAMA_ACADEMICO prog ON e.cod_programa = prog.cod_programa
                        LEFT JOIN MATRICULA m ON e.cod_estudiante = m.cod_estudiante
                        LEFT JOIN PERIODO_ACADEMICO p ON m.cod_periodo = p.cod_periodo AND p.estado_periodo = ''ACTIVO''
                        LEFT JOIN DETALLE_MATRICULA dm ON m.cod_matricula = dm.cod_matricula AND dm.estado_inscripcion = ''INSCRITO''
                        WHERE e.cod_estudiante = :cod_estudiante
                        GROUP BY e.cod_estudiante, e.primer_nombre, e.primer_apellido, 
                                 prog.nombre_programa, m.cod_matricula, m.total_creditos, p.nombre_periodo'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /registro_materias/resumen/:cod_estudiante corregido');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Error: ' || SQLERRM);
END;
/

-- =====================================================
-- 6. FIX: GET /docente/estudiantes/:cod_grupo
-- =====================================================
PROMPT ''
PROMPT 'Corrigiendo GET /docente/estudiantes/:cod_grupo...'

BEGIN
    BEGIN
        ORDS.DELETE_TEMPLATE(
            p_module_name => 'docente',
            p_pattern     => 'estudiantes/:cod_grupo'
        );
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
    
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'docente',
        p_pattern     => 'estudiantes/:cod_grupo'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'docente',
        p_pattern     => 'estudiantes/:cod_grupo',
        p_method      => 'GET',
        p_source_type => 'json/collection',
        p_source      => 'SELECT 
                            e.cod_estudiante,
                            e.primer_nombre || '' '' || e.primer_apellido as nombre_completo,
                            e.correo_institucional,
                            dm.cod_detalle_matricula,
                            TO_CHAR(dm.fecha_inscripcion, ''YYYY-MM-DD'') as fecha_inscripcion,
                            dm.estado_inscripcion,
                            NVL(nd.nota_final, 0) as nota_final,
                            NVL(nd.resultado, ''PENDIENTE'') as resultado
                        FROM DETALLE_MATRICULA dm
                        JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
                        JOIN ESTUDIANTE e ON m.cod_estudiante = e.cod_estudiante
                        LEFT JOIN NOTA_DEFINITIVA nd ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
                        WHERE dm.cod_grupo = :cod_grupo
                        AND dm.estado_inscripcion = ''INSCRITO''
                        ORDER BY e.primer_apellido, e.primer_nombre'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /docente/estudiantes/:cod_grupo corregido');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Error: ' || SQLERRM);
END;
/

-- =====================================================
-- 7. FIX: GET /alertas/estudiante/:cod_estudiante
-- =====================================================
PROMPT ''
PROMPT 'Corrigiendo GET /alertas/estudiante/:cod_estudiante...'

BEGIN
    BEGIN
        ORDS.DELETE_TEMPLATE(
            p_module_name => 'alertas',
            p_pattern     => 'estudiante/:cod_estudiante'
        );
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
    
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'alertas',
        p_pattern     => 'estudiante/:cod_estudiante'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'alertas',
        p_pattern     => 'estudiante/:cod_estudiante',
        p_method      => 'GET',
        p_source_type => 'json/collection',
        p_source      => 'SELECT 
                            ''RIESGO_ACADEMICO'' as tipo_alerta,
                            hr.nivel_riesgo,
                            hr.tipo_riesgo,
                            hr.promedio_periodo,
                            TO_CHAR(hr.fecha_deteccion, ''YYYY-MM-DD'') as fecha_deteccion,
                            hr.observaciones,
                            p.nombre_periodo as periodo
                        FROM HISTORIAL_RIESGO hr
                        JOIN PERIODO_ACADEMICO p ON hr.cod_periodo = p.cod_periodo
                        WHERE hr.cod_estudiante = :cod_estudiante
                        ORDER BY hr.fecha_deteccion DESC'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /alertas/estudiante/:cod_estudiante corregido');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Error: ' || SQLERRM);
END;
/

-- =====================================================
-- 8. FIX: GET /alertas/riesgo-academico
-- =====================================================
PROMPT ''
PROMPT 'Corrigiendo GET /alertas/riesgo-academico...'

BEGIN
    BEGIN
        ORDS.DELETE_TEMPLATE(
            p_module_name => 'alertas',
            p_pattern     => 'riesgo-academico'
        );
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
    
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'alertas',
        p_pattern     => 'riesgo-academico'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'alertas',
        p_pattern     => 'riesgo-academico',
        p_method      => 'GET',
        p_source_type => 'json/collection',
        p_source      => 'SELECT 
                            e.cod_estudiante,
                            e.primer_nombre || '' '' || e.primer_apellido as nombre_completo,
                            hr.nivel_riesgo,
                            hr.tipo_riesgo,
                            hr.promedio_periodo,
                            TO_CHAR(hr.fecha_deteccion, ''YYYY-MM-DD'') as fecha_deteccion,
                            p.nombre_periodo,
                            hr.observaciones
                        FROM ESTUDIANTE e
                        JOIN HISTORIAL_RIESGO hr ON e.cod_estudiante = hr.cod_estudiante
                        JOIN PERIODO_ACADEMICO p ON hr.cod_periodo = p.cod_periodo
                        WHERE hr.nivel_riesgo IN (''ALTO'', ''MEDIO'')
                        AND e.estado_estudiante = ''ACTIVO''
                        AND p.estado_periodo = ''ACTIVO''
                        ORDER BY 
                            CASE hr.nivel_riesgo 
                                WHEN ''ALTO'' THEN 1 
                                WHEN ''MEDIO'' THEN 2 
                                ELSE 3 
                            END,
                            e.primer_apellido'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /alertas/riesgo-academico corregido');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Error: ' || SQLERRM);
END;
/

-- =====================================================
-- VERIFICACIÓN FINAL
-- =====================================================
PROMPT ''
PROMPT 'Verificando todos los endpoints corregidos...'
PROMPT ''

SELECT 
    m.name as module_name,
    t.uri_template,
    h.method,
    'ACTIVO' as status
FROM USER_ORDS_MODULES m
JOIN USER_ORDS_TEMPLATES t ON m.id = t.module_id
JOIN USER_ORDS_HANDLERS h ON t.id = h.template_id
WHERE m.name IN ('estudiantes', 'docente', 'alertas', 'registro_materias')
ORDER BY m.name, t.uri_template, h.method;

PROMPT ''
PROMPT =====================================================
PROMPT CORRECCIÓN FINAL COMPLETADA - PROBANDO ENDPOINTS
PROMPT =====================================================

EXIT;
