-- =====================================================
-- API REST - MATRICULAS
-- Archivo: 03_matriculas_api.sql
-- Módulo: Gestión de Matrículas
-- Ejecutar como: ACADEMICO
-- =====================================================

SET SERVEROUTPUT ON
SET ECHO ON

PROMPT '========================================='
PROMPT 'CREANDO API REST - MATRÍCULAS'
PROMPT '========================================='

-- =====================================================
-- MÓDULO: MATRICULAS
-- =====================================================

BEGIN
    ORDS.DEFINE_MODULE(
        p_module_name    => 'matriculas',
        p_base_path      => '/matriculas/',
        p_items_per_page => 25,
        p_status         => 'PUBLISHED',
        p_comments       => 'API para gestión de matrículas'
    );
    
    COMMIT;
END;
/

PROMPT 'Módulo "matriculas" creado'

-- =====================================================
-- ENDPOINT: POST /matriculas/ - Crear nueva matrícula
-- Usa el paquete PKG_MATRICULA
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'matriculas',
        p_pattern        => '.',
        p_priority       => 0,
        p_comments       => 'Operaciones de matrícula'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'matriculas',
        p_pattern        => '.',
        p_method         => 'POST',
        p_source_type    => 'plsql/block',
        p_source         => 'DECLARE
                                v_cod_matricula NUMBER;
                                v_resultado VARCHAR2(500);
                            BEGIN
                                -- Usar el paquete existente
                                PKG_MATRICULA.crear_matricula(
                                    p_cod_estudiante => :cod_estudiante,
                                    p_cod_periodo => :cod_periodo,
                                    p_cod_matricula => v_cod_matricula
                                );
                                
                                :status_code := 201;
                                :response := JSON_OBJECT(
                                    ''success'' VALUE TRUE,
                                    ''message'' VALUE ''Matrícula creada exitosamente'',
                                    ''cod_matricula'' VALUE v_cod_matricula
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
        p_comments       => 'Crea nueva matrícula usando PKG_MATRICULA'
    );
    
    COMMIT;
END;
/

PROMPT '✓ POST /matriculas/ - Crear matrícula'

-- =====================================================
-- ENDPOINT: POST /matriculas/:cod_matricula/asignaturas - Agregar asignatura
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'matriculas',
        p_pattern        => ':cod_matricula/asignaturas',
        p_priority       => 0,
        p_comments       => 'Gestión de asignaturas en matrícula'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'matriculas',
        p_pattern        => ':cod_matricula/asignaturas',
        p_method         => 'POST',
        p_source_type    => 'plsql/block',
        p_source         => 'DECLARE
                                v_mensaje VARCHAR2(500);
                            BEGIN
                                PKG_MATRICULA.agregar_asignatura(
                                    p_cod_matricula => :cod_matricula,
                                    p_cod_grupo => :cod_grupo,
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
        p_comments       => 'Agrega asignatura a matrícula'
    );
    
    COMMIT;
END;
/

PROMPT '✓ POST /matriculas/:cod_matricula/asignaturas - Agregar asignatura'

-- =====================================================
-- ENDPOINT: GET /matriculas/:cod_matricula - Detalle de matrícula
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'matriculas',
        p_pattern        => ':cod_matricula',
        p_priority       => 0,
        p_comments       => 'Detalle de matrícula'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'matriculas',
        p_pattern        => ':cod_matricula',
        p_method         => 'GET',
        p_source_type    => 'json/item',
        p_source         => 'SELECT 
                                m.cod_matricula,
                                m.cod_estudiante,
                                e.primer_nombre || '' '' || e.primer_apellido as estudiante,
                                m.cod_periodo,
                                p.nombre_periodo,
                                m.fecha_matricula,
                                m.estado_matricula,
                                m.total_creditos,
                                (SELECT JSON_ARRAYAGG(
                                    JSON_OBJECT(
                                        ''cod_detalle_matricula'' VALUE dm.cod_detalle_matricula,
                                        ''cod_grupo'' VALUE dm.cod_grupo,
                                        ''asignatura'' VALUE a.nombre_asignatura,
                                        ''codigo_asignatura'' VALUE a.cod_asignatura,
                                        ''creditos'' VALUE a.creditos,
                                        ''estado_inscripcion'' VALUE dm.estado_inscripcion
                                    )
                                 )
                                 FROM DETALLE_MATRICULA dm
                                 JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
                                 JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
                                 WHERE dm.cod_matricula = m.cod_matricula
                                ) as asignaturas
                             FROM MATRICULA m
                             JOIN ESTUDIANTE e ON m.cod_estudiante = e.cod_estudiante
                             JOIN PERIODO_ACADEMICO p ON m.cod_periodo = p.cod_periodo
                             WHERE m.cod_matricula = :cod_matricula',
        p_comments       => 'Obtiene detalle completo de matrícula'
    );
    
    COMMIT;
END;
/

PROMPT '✓ GET /matriculas/:cod_matricula - Detalle de matrícula'

-- =====================================================
-- ENDPOINT: PUT /matriculas/:cod_matricula/estado - Cambiar estado
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'matriculas',
        p_pattern        => ':cod_matricula/estado',
        p_priority       => 0,
        p_comments       => 'Cambiar estado de matrícula'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'matriculas',
        p_pattern        => ':cod_matricula/estado',
        p_method         => 'PUT',
        p_source_type    => 'plsql/block',
        p_source         => 'BEGIN
                                UPDATE MATRICULA
                                SET estado_matricula = :nuevo_estado
                                WHERE cod_matricula = :cod_matricula;
                                
                                IF SQL%ROWCOUNT > 0 THEN
                                    :status_code := 200;
                                    :response := JSON_OBJECT(
                                        ''success'' VALUE TRUE,
                                        ''message'' VALUE ''Estado actualizado exitosamente''
                                    );
                                    COMMIT;
                                ELSE
                                    :status_code := 404;
                                    :response := JSON_OBJECT(
                                        ''success'' VALUE FALSE,
                                        ''error'' VALUE ''Matrícula no encontrada''
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
        p_comments       => 'Cambia el estado de una matrícula'
    );
    
    COMMIT;
END;
/

PROMPT '✓ PUT /matriculas/:cod_matricula/estado - Cambiar estado'

-- =====================================================
-- ENDPOINT: GET /matriculas/periodo/:cod_periodo - Matrículas por período
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'matriculas',
        p_pattern        => 'periodo/:cod_periodo',
        p_priority       => 0,
        p_comments       => 'Matrículas por período'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'matriculas',
        p_pattern        => 'periodo/:cod_periodo',
        p_method         => 'GET',
        p_source_type    => 'json/collection',
          p_source         => 'SELECT 
                                          m.cod_matricula,
                                          m.cod_estudiante,
                                          e.primer_nombre || '' '' || e.primer_apellido as estudiante,
                                          e.cod_programa,
                                          p.nombre_programa,
                                          m.fecha_matricula,
                                          m.estado_matricula,
                                          m.total_creditos
                                      FROM MATRICULA m
                                      JOIN ESTUDIANTE e ON m.cod_estudiante = e.cod_estudiante
                                      LEFT JOIN PROGRAMA_ACADEMICO p ON e.cod_programa = p.cod_programa
                                      WHERE m.cod_periodo = :cod_periodo
                                      ORDER BY m.fecha_matricula DESC',
        p_items_per_page => 50,
        p_comments       => 'Lista matrículas de un período'
    );
    
    COMMIT;
END;
/

PROMPT '✓ GET /matriculas/periodo/:cod_periodo - Matrículas por período'

-- =====================================================
-- RESUMEN
-- =====================================================

PROMPT ''
PROMPT '========================================='
PROMPT 'API MATRÍCULAS CREADA EXITOSAMENTE'
PROMPT '========================================='
PROMPT ''
PROMPT 'Endpoints disponibles:'
PROMPT '  POST   /matriculas/                          - Crear matrícula'
PROMPT '  POST   /matriculas/:cod/asignaturas          - Agregar asignatura'
PROMPT '  GET    /matriculas/:cod                      - Detalle de matrícula'
PROMPT '  PUT    /matriculas/:cod/estado               - Cambiar estado'
PROMPT '  GET    /matriculas/periodo/:cod_periodo      - Matrículas por período'
PROMPT ''
PROMPT 'URL Base: http://localhost:8080/ords/academico/matriculas/'
PROMPT ''
