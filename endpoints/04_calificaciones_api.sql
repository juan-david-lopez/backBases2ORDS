-- =====================================================
-- API REST - CALIFICACIONES
-- Archivo: 04_calificaciones_api.sql
-- Módulo: Gestión de Calificaciones
-- Ejecutar como: ACADEMICO
-- =====================================================

SET SERVEROUTPUT ON
SET ECHO ON

PROMPT '========================================='
PROMPT 'CREANDO API REST - CALIFICACIONES'
PROMPT '========================================='

-- =====================================================
-- MÓDULO: CALIFICACIONES
-- =====================================================

BEGIN
    ORDS.DEFINE_MODULE(
        p_module_name    => 'calificaciones',
        p_base_path      => '/calificaciones/',
        p_items_per_page => 25,
        p_status         => 'PUBLISHED',
        p_comments       => 'API para gestión de calificaciones'
    );
    
    COMMIT;
END;
/

PROMPT 'Módulo "calificaciones" creado'

-- =====================================================
-- ENDPOINT: POST /calificaciones/ - Registrar calificación
-- Usa PKG_CALIFICACION
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'calificaciones',
        p_pattern        => '.',
        p_priority       => 0,
        p_comments       => 'Operaciones de calificación'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'calificaciones',
        p_pattern        => '.',
        p_method         => 'POST',
        p_source_type    => 'plsql/block',
        p_source         => 'DECLARE
                                v_mensaje VARCHAR2(500);
                            BEGIN
                                PKG_CALIFICACION.registrar_calificacion(
                                    p_cod_detalle => :cod_detalle,
                                    p_cod_actividad => :cod_actividad,
                                    p_nota => :nota,
                                    p_observaciones => :observaciones,
                                    p_mensaje => v_mensaje
                                );
                                
                                :status_code := 201;
                                :response := JSON_OBJECT(
                                    ''success'' VALUE TRUE,
                                    ''message'' VALUE v_mensaje
                                );
                                
                                COMMIT;
                            EXCEPTION
                                WHEN OTHERS THEN
                                    :status_code := 400;
                                    :response := JSON_OBJECT(
                                        ''success'' VALUE FALSE,
                                        ''error'' VALUE SQLERRM
                                    );
                                    ROLLBACK;
                            END;',
        p_comments       => 'Registra una calificación'
    );
    
    COMMIT;
END;
/

PROMPT '✓ POST /calificaciones/ - Registrar calificación'

-- =====================================================
-- ENDPOINT: GET /calificaciones/estudiante/:cod_estudiante - Notas del estudiante
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'calificaciones',
        p_pattern        => 'estudiante/:cod_estudiante',
        p_priority       => 0,
        p_comments       => 'Calificaciones por estudiante'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'calificaciones',
        p_pattern        => 'estudiante/:cod_estudiante',
        p_method         => 'GET',
        p_source_type    => 'json/collection',
          p_source         => 'SELECT 
                                          nd.cod_nota_definitiva,
                                          p.nombre_periodo,
                                          a.cod_asignatura,
                                          a.nombre_asignatura,
                                          nd.nota_final,
                                          nd.resultado,
                                          nd.fecha_registro
                                      FROM NOTA_DEFINITIVA nd
                                      JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
                                      JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
                                      JOIN PERIODO_ACADEMICO p ON m.cod_periodo = p.cod_periodo
                                      JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
                                      JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
                                      WHERE m.cod_estudiante = :cod_estudiante
                                      ORDER BY p.anio DESC, p.periodo DESC, a.nombre_asignatura',
        p_items_per_page => 50,
        p_comments       => 'Lista todas las notas de un estudiante'
    );
    
    COMMIT;
END;
/

PROMPT '✓ GET /calificaciones/estudiante/:cod_estudiante - Notas del estudiante'

-- =====================================================
-- ENDPOINT: GET /calificaciones/asignatura/:cod_grupo - Notas por grupo
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'calificaciones',
        p_pattern        => 'grupo/:cod_grupo',
        p_priority       => 0,
        p_comments       => 'Calificaciones por grupo'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'calificaciones',
        p_pattern        => 'grupo/:cod_grupo',
        p_method         => 'GET',
        p_source_type    => 'json/collection',
        p_source         => 'SELECT 
                                e.cod_estudiante,
                                e.primer_nombre || '' '' || e.primer_apellido as estudiante,
                                nd.nota_final,
                                nd.resultado,
                                (SELECT JSON_ARRAYAGG(
                                    JSON_OBJECT(
                                        ''actividad'' VALUE ta.nombre_actividad,
                                        ''nota'' VALUE c.nota,
                                        ''porcentaje'' VALUE re.porcentaje,
                                        ''fecha'' VALUE c.fecha_registro
                                    ) ORDER BY c.fecha_registro
                                 )
                                 FROM CALIFICACION c
                                 JOIN REGLA_EVALUACION re ON c.cod_tipo_actividad = re.cod_tipo_actividad
                                 JOIN TIPO_ACTIVIDAD_EVALUATIVA ta ON re.cod_tipo_actividad = ta.cod_tipo_actividad
                                 WHERE c.cod_detalle_matricula = dm.cod_detalle_matricula
                                ) as detalle_calificaciones
                             FROM DETALLE_MATRICULA dm
                             JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
                             JOIN ESTUDIANTE e ON m.cod_estudiante = e.cod_estudiante
                             LEFT JOIN NOTA_DEFINITIVA nd ON dm.cod_detalle_matricula = nd.cod_detalle_matricula
                             WHERE dm.cod_grupo = :cod_grupo
                             ORDER BY e.primer_apellido, e.primer_nombre',
        p_items_per_page => 100,
        p_comments       => 'Lista calificaciones de todos los estudiantes de un grupo'
    );
    
    COMMIT;
END;
/

PROMPT '✓ GET /calificaciones/grupo/:cod_grupo - Notas por grupo'

-- =====================================================
-- ENDPOINT: PUT /calificaciones/:cod_calificacion - Actualizar nota
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'calificaciones',
        p_pattern        => ':cod_calificacion',
        p_priority       => 0,
        p_comments       => 'Actualizar calificación'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'calificaciones',
        p_pattern        => ':cod_calificacion',
        p_method         => 'PUT',
        p_source_type    => 'plsql/block',
        p_source         => 'BEGIN
                                UPDATE CALIFICACION
                                SET nota = :nota,
                                    observaciones = :observaciones
                                WHERE cod_calificacion = :cod_calificacion;
                                
                                IF SQL%ROWCOUNT > 0 THEN
                                    -- Recalcular nota definitiva
                                    DECLARE
                                        v_cod_detalle NUMBER;
                                    BEGIN
                                        SELECT cod_detalle INTO v_cod_detalle
                                        FROM CALIFICACION
                                        WHERE cod_calificacion = :cod_calificacion;
                                        
                                        PKG_CALIFICACION.calcular_nota_definitiva(v_cod_detalle);
                                    END;
                                    
                                    :status_code := 200;
                                    :response := JSON_OBJECT(
                                        ''success'' VALUE TRUE,
                                        ''message'' VALUE ''Calificación actualizada y nota definitiva recalculada''
                                    );
                                    COMMIT;
                                ELSE
                                    :status_code := 404;
                                    :response := JSON_OBJECT(
                                        ''success'' VALUE FALSE,
                                        ''error'' VALUE ''Calificación no encontrada''
                                    );
                                END IF;
                            EXCEPTION
                                WHEN OTHERS THEN
                                    :status_code := 400;
                                    :response := JSON_OBJECT(
                                        ''success'' VALUE FALSE,
                                        ''error'' VALUE SQLERRM
                                    );
                                    ROLLBACK;
                            END;',
        p_comments       => 'Actualiza una calificación y recalcula nota definitiva'
    );
    
    COMMIT;
END;
/

PROMPT '✓ PUT /calificaciones/:cod_calificacion - Actualizar nota'

-- =====================================================
-- ENDPOINT: GET /calificaciones/historial/:cod_estudiante - Historial académico
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'calificaciones',
        p_pattern        => 'historial/:cod_estudiante',
        p_priority       => 0,
        p_comments       => 'Historial académico completo'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'calificaciones',
        p_pattern        => 'historial/:cod_estudiante',
        p_method         => 'GET',
        p_source_type    => 'json/item',
          p_source         => 'SELECT 
                                          e.cod_estudiante,
                                          e.primer_nombre || '' '' || e.primer_apellido as estudiante,
                                          p.nombre_programa,
                                          (SELECT AVG(nd.nota_final)
                                            FROM NOTA_DEFINITIVA nd
                                            JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
                                            JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
                                            WHERE m.cod_estudiante = e.cod_estudiante
                                            AND nd.resultado IN (''APROBADO'', ''REPROBADO'')
                                          ) as promedio_acumulado,
                                          (SELECT COUNT(*)
                                            FROM NOTA_DEFINITIVA nd
                                            JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
                                            JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
                                            WHERE m.cod_estudiante = e.cod_estudiante
                                            AND nd.resultado = ''APROBADO''
                                          ) as asignaturas_aprobadas,
                                          (SELECT COUNT(*)
                                            FROM NOTA_DEFINITIVA nd
                                            JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
                                            JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
                                            WHERE m.cod_estudiante = e.cod_estudiante
                                            AND nd.resultado = ''REPROBADO''
                                          ) as asignaturas_reprobadas,
                                          (SELECT SUM(a.creditos)
                                            FROM NOTA_DEFINITIVA nd
                                            JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
                                            JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
                                            JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
                                            JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
                                            WHERE m.cod_estudiante = e.cod_estudiante
                                            AND nd.resultado = ''APROBADO''
                                          ) as creditos_aprobados
                                      FROM ESTUDIANTE e
                                      LEFT JOIN PROGRAMA_ACADEMICO p ON e.cod_programa = p.cod_programa
                                      WHERE e.cod_estudiante = :cod_estudiante',
        p_comments       => 'Resumen completo del historial académico'
    );
    
    COMMIT;
END;
/

PROMPT '✓ GET /calificaciones/historial/:cod_estudiante - Historial académico'

-- =====================================================
-- RESUMEN
-- =====================================================

PROMPT ''
PROMPT '========================================='
PROMPT 'API CALIFICACIONES CREADA EXITOSAMENTE'
PROMPT '========================================='
PROMPT ''
PROMPT 'Endpoints disponibles:'
PROMPT '  POST   /calificaciones/                      - Registrar calificación'
PROMPT '  GET    /calificaciones/estudiante/:cod       - Notas del estudiante'
PROMPT '  GET    /calificaciones/grupo/:cod            - Notas por grupo'
PROMPT '  PUT    /calificaciones/:cod                  - Actualizar nota'
PROMPT '  GET    /calificaciones/historial/:cod        - Historial académico'
PROMPT ''
PROMPT 'URL Base: http://localhost:8080/ords/academico/calificaciones/'
PROMPT ''
