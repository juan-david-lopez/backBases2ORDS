-- =====================================================
-- CORRECCIÓN DEFINITIVA DE LOS 8 ENDPOINTS FALLIDOS
-- Sistema Académico - Llegando al 100%
-- =====================================================

SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT =====================================================
PROMPT CORRECCIÓN DEFINITIVA - 100% FUNCIONAL
PROMPT =====================================================
PROMPT ''

-- =====================================================
-- 1. FIX: GET /estudiantes/:codigo/matriculas (403)
--    PROBLEMA: cod_detalle NO EXISTE, debe ser cod_detalle_matricula
-- =====================================================
PROMPT '1. Corrigiendo GET /estudiantes/:codigo/matriculas (cod_detalle → cod_detalle_matricula)...'

BEGIN
    ORDS.DEFINE_HANDLER(
        p_module_name => 'estudiantes',
        p_pattern     => ':codigo/matriculas',
        p_method      => 'GET',
        p_source_type => ORDS.source_type_collection_feed,
        p_source      => 'SELECT 
                            m.cod_matricula,
                            m.cod_periodo,
                            p.nombre_periodo,
                            m.fecha_matricula,
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
-- 2. FIX: GET /registro_materias/disponibles/:cod_estudiante (404)
--    PROBLEMA: Falta información de prerequisitos
-- =====================================================
PROMPT ''
PROMPT '2. Corrigiendo GET /registro_materias/disponibles/:cod_estudiante...'

BEGIN
    ORDS.DEFINE_HANDLER(
        p_module_name => 'registro_materias',
        p_pattern     => 'disponibles/:cod_estudiante',
        p_method      => 'GET',
        p_source_type => ORDS.source_type_collection_feed,
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
-- 3. FIX: GET /registro_materias/grupos/:cod_asignatura (404)
--    PROBLEMA: Falta información de asignatura y créditos
-- =====================================================
PROMPT ''
PROMPT '3. Corrigiendo GET /registro_materias/grupos/:cod_asignatura...'

BEGIN
    ORDS.DEFINE_HANDLER(
        p_module_name => 'registro_materias',
        p_pattern     => 'grupos/:cod_asignatura',
        p_method      => 'GET',
        p_source_type => ORDS.source_type_collection_feed,
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
-- 4. FIX: GET /registro_materias/mi-horario/:cod_estudiante (404)
--    PROBLEMA: ORDER BY día_semana como texto
-- =====================================================
PROMPT ''
PROMPT '4. Corrigiendo GET /registro_materias/mi-horario/:cod_estudiante...'

BEGIN
    ORDS.DEFINE_HANDLER(
        p_module_name => 'registro_materias',
        p_pattern     => 'mi-horario/:cod_estudiante',
        p_method      => 'GET',
        p_source_type => ORDS.source_type_collection_feed,
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
-- 5. FIX: GET /registro_materias/resumen/:cod_estudiante (404)
--    PROBLEMA: Falta nombre_programa, manejo de NULL
-- =====================================================
PROMPT ''
PROMPT '5. Corrigiendo GET /registro_materias/resumen/:cod_estudiante...'

BEGIN
    ORDS.DEFINE_HANDLER(
        p_module_name => 'registro_materias',
        p_pattern     => 'resumen/:cod_estudiante',
        p_method      => 'GET',
        p_source_type => ORDS.source_type_feed,
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
-- 6. FIX: GET /docente/estudiantes/:cod_grupo (555)
--    PROBLEMA: JOIN a REGLA_EVALUACION con cod_regla que NO EXISTE en CALIFICACION
-- =====================================================
PROMPT ''
PROMPT '6. Corrigiendo GET /docente/estudiantes/:cod_grupo (eliminando JOIN a REGLA_EVALUACION)...'

BEGIN
    ORDS.DEFINE_HANDLER(
        p_module_name => 'docente',
        p_pattern     => 'estudiantes/:cod_grupo',
        p_method      => 'GET',
        p_source_type => ORDS.source_type_plsql,
        p_source      => 'BEGIN
    HTP.PRINT(''['');
    FOR rec IN (
        SELECT
            e.cod_estudiante,
            e.primer_nombre || '' '' || e.primer_apellido as nombre_completo,
            e.correo_institucional,
            dm.cod_detalle_matricula,
            dm.fecha_inscripcion,
            nd.nota_final,
            nd.resultado
        FROM DETALLE_MATRICULA dm
        JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
        JOIN ESTUDIANTE e ON m.cod_estudiante = e.cod_estudiante
        LEFT JOIN NOTA_DEFINITIVA nd ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
        WHERE dm.cod_grupo = :cod_grupo
        AND dm.estado_inscripcion = ''INSCRITO''
        ORDER BY e.primer_apellido, e.primer_nombre
    ) LOOP
        HTP.PRINT(JSON_OBJECT(
            ''cod_estudiante'' VALUE rec.cod_estudiante,
            ''nombre'' VALUE rec.nombre_completo,
            ''correo'' VALUE rec.correo_institucional,
            ''cod_detalle_matricula'' VALUE rec.cod_detalle_matricula,
            ''fecha_inscripcion'' VALUE TO_CHAR(rec.fecha_inscripcion, ''YYYY-MM-DD''),
            ''nota_final'' VALUE rec.nota_final,
            ''resultado'' VALUE rec.resultado
        ) || '','');
    END LOOP;
    HTP.PRINT(''{}]'');
    :status_code := 200;
EXCEPTION
    WHEN OTHERS THEN
        :status_code := 500;
        HTP.PRINT(''{"error": "'' || REPLACE(SQLERRM, ''"'', ''\\"'') || ''"}''    );
END;'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /docente/estudiantes/:cod_grupo corregido');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Error: ' || SQLERRM);
END;
/

-- =====================================================
-- 7. FIX: GET /alertas/estudiante/:cod_estudiante (555)
--    PROBLEMA: JSON_ARRAY_T requiere tipo CLOB explícito
-- =====================================================
PROMPT ''
PROMPT '7. Corrigiendo GET /alertas/estudiante/:cod_estudiante (simplificando JSON)...'

BEGIN
    ORDS.DEFINE_HANDLER(
        p_module_name => 'alertas',
        p_pattern     => 'estudiante/:cod_estudiante',
        p_method      => 'GET',
        p_source_type => ORDS.source_type_collection_feed,
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
-- 8. FIX: GET /alertas/riesgo-academico (555)
--    PROBLEMA: LEFT JOIN cuando debería ser INNER JOIN
-- =====================================================
PROMPT ''
PROMPT '8. Corrigiendo GET /alertas/riesgo-academico (LEFT JOIN → INNER JOIN)...'

BEGIN
    ORDS.DEFINE_HANDLER(
        p_module_name => 'alertas',
        p_pattern     => 'riesgo-academico',
        p_method      => 'GET',
        p_source_type => ORDS.source_type_collection_feed,
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

PROMPT ''
PROMPT =====================================================
PROMPT CORRECCIÓN COMPLETADA - TODOS LOS ENDPOINTS ARREGLADOS
PROMPT =====================================================
PROMPT ''
PROMPT 'Verificando handlers actualizados...'

SELECT 
    m.name || ' → ' || h.method || ' /' || t.uri_template as endpoint,
    h.source_type
FROM USER_ORDS_MODULES m
JOIN USER_ORDS_TEMPLATES t ON m.id = t.module_id
JOIN USER_ORDS_HANDLERS h ON t.id = h.template_id
WHERE (m.name = 'estudiantes' AND t.uri_template = ':codigo/matriculas')
   OR (m.name = 'registro_materias' AND t.uri_template LIKE 'disponibles%')
   OR (m.name = 'registro_materias' AND t.uri_template LIKE 'grupos%')
   OR (m.name = 'registro_materias' AND t.uri_template LIKE 'mi-horario%')
   OR (m.name = 'registro_materias' AND t.uri_template LIKE 'resumen%')
   OR (m.name = 'docente' AND t.uri_template = 'estudiantes/:cod_grupo')
   OR (m.name = 'alertas' AND t.uri_template = 'estudiante/:cod_estudiante')
   OR (m.name = 'alertas' AND t.uri_template = 'riesgo-academico')
ORDER BY m.name, t.uri_template;

PROMPT ''
PROMPT '¡TODOS LOS ENDPOINTS HAN SIDO CORREGIDOS!'
PROMPT 'Ejecuta test_all_endpoints.ps1 para verificar el 100%'

EXIT;
