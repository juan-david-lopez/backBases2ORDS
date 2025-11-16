-- =====================================================
-- API REST - ESTUDIANTES
-- Archivo: 01_estudiantes_api.sql
-- Módulo: Gestión de Estudiantes
-- =====================================================

SET SERVEROUTPUT ON

PROMPT '========================================='
PROMPT 'CREANDO API REST - ESTUDIANTES'
PROMPT '========================================='

-- =====================================================
-- MÓDULO: ESTUDIANTES
-- =====================================================

BEGIN
    ORDS.DEFINE_MODULE(
        p_module_name    => 'estudiantes',
        p_base_path      => '/estudiantes/',
        p_items_per_page => 25,
        p_status         => 'PUBLISHED',
        p_comments       => 'API para gestión de estudiantes'
    );
    
    COMMIT;
END;
/

PROMPT 'Módulo "estudiantes" creado'

-- =====================================================
-- ENDPOINT: GET /estudiantes/ - Listar todos los estudiantes
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'estudiantes',
        p_pattern        => '.',
        p_priority       => 0,
        p_etag_type      => 'HASH',
        p_etag_query     => NULL,
        p_comments       => 'Listado de estudiantes'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'estudiantes',
        p_pattern        => '.',
        p_method         => 'GET',
        p_source_type    => 'json/collection',
          p_source         => 'SELECT 
                                          cod_estudiante,
                                          cod_programa,
                                          tipo_documento,
                                          num_documento,
                                          primer_nombre,
                                          segundo_nombre,
                                          primer_apellido,
                                          segundo_apellido,
                                          correo_institucional,
                                          correo_personal,
                                          telefono,
                                          direccion,
                                          estado_estudiante,
                                          fecha_ingreso
                                      FROM ESTUDIANTE
                                      ORDER BY fecha_ingreso DESC',
        p_items_per_page => 25,
        p_comments       => 'Lista todos los estudiantes'
    );
    
    COMMIT;
END;
/

PROMPT '✓ GET /estudiantes/ - Listar estudiantes'

-- =====================================================
-- ENDPOINT: GET /estudiantes/:codigo - Obtener estudiante por código
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'estudiantes',
        p_pattern        => ':codigo',
        p_priority       => 0,
        p_etag_type      => 'HASH',
        p_comments       => 'Estudiante por código'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'estudiantes',
        p_pattern        => ':codigo',
        p_method         => 'GET',
        p_source_type    => 'json/item',
          p_source         => 'SELECT 
                                          e.cod_estudiante,
                                          e.cod_programa,
                                          p.nombre_programa,
                                          e.tipo_documento,
                                          e.num_documento,
                                          e.primer_nombre,
                                          e.segundo_nombre,
                                          e.primer_apellido,
                                          e.segundo_apellido,
                                          e.correo_institucional,
                                          e.correo_personal,
                                          e.telefono,
                                          e.direccion,
                                          e.fecha_nacimiento,
                                          e.genero,
                                          e.estado_estudiante,
                                          e.fecha_ingreso
                                      FROM ESTUDIANTE e
                                      LEFT JOIN PROGRAMA_ACADEMICO p ON e.cod_programa = p.cod_programa
                                      WHERE e.cod_estudiante = :codigo',
        p_comments       => 'Obtiene un estudiante específico'
    );
    
    COMMIT;
END;
/

PROMPT '✓ GET /estudiantes/:codigo - Obtener estudiante'

-- =====================================================
-- ENDPOINT: POST /estudiantes/ - Crear nuevo estudiante
-- =====================================================

BEGIN
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'estudiantes',
        p_pattern        => '.',
        p_method         => 'POST',
        p_source_type    => 'plsql/block',
        p_source         => 'DECLARE
                                v_cod_estudiante VARCHAR2(20);
                            BEGIN
                                INSERT INTO ESTUDIANTE (
                                    cod_programa,
                                    tipo_documento,
                                    num_documento,
                                    primer_nombre,
                                    segundo_nombre,
                                    primer_apellido,
                                    segundo_apellido,
                                    correo_institucional,
                                    correo_personal,
                                    telefono,
                                    direccion,
                                    fecha_nacimiento,
                                    genero,
                                    estado_estudiante,
                                    fecha_ingreso
                                ) VALUES (
                                    :cod_programa,
                                    :tipo_documento,
                                    :num_documento,
                                    :primer_nombre,
                                    :segundo_nombre,
                                    :primer_apellido,
                                    :segundo_apellido,
                                    :correo_institucional,
                                    :correo_personal,
                                    :telefono,
                                    :direccion,
                                    TO_DATE(:fecha_nacimiento, ''YYYY-MM-DD''),
                                    :genero,
                                    ''ACTIVO'',
                                    TO_DATE(:fecha_ingreso, ''YYYY-MM-DD'')
                                ) RETURNING cod_estudiante INTO v_cod_estudiante;
                                
                                :status_code := 201;
                                :response := JSON_OBJECT(
                                    ''success'' VALUE TRUE,
                                    ''message'' VALUE ''Estudiante creado exitosamente'',
                                    ''cod_estudiante'' VALUE v_cod_estudiante
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
        p_comments       => 'Crea un nuevo estudiante'
    );
    
    COMMIT;
END;
/

PROMPT '✓ POST /estudiantes/ - Crear estudiante'

-- =====================================================
-- ENDPOINT: PUT /estudiantes/:codigo - Actualizar estudiante
-- =====================================================

BEGIN
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'estudiantes',
        p_pattern        => ':codigo',
        p_method         => 'PUT',
        p_source_type    => 'plsql/block',
        p_source         => 'BEGIN
                                UPDATE ESTUDIANTE
                                SET correo_institucional = :correo_institucional,
                                    correo_personal = :correo_personal,
                                    telefono = :telefono,
                                    direccion = :direccion,
                                    estado_estudiante = :estado_estudiante
                                WHERE cod_estudiante = :codigo;
                                
                                IF SQL%ROWCOUNT > 0 THEN
                                    :status_code := 200;
                                    :response := JSON_OBJECT(
                                        ''success'' VALUE TRUE,
                                        ''message'' VALUE ''Estudiante actualizado exitosamente''
                                    );
                                    COMMIT;
                                ELSE
                                    :status_code := 404;
                                    :response := JSON_OBJECT(
                                        ''success'' VALUE FALSE,
                                        ''error'' VALUE ''Estudiante no encontrado''
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
        p_comments       => 'Actualiza un estudiante'
    );
    
    COMMIT;
END;
/

PROMPT '✓ PUT /estudiantes/:codigo - Actualizar estudiante'

-- =====================================================
-- ENDPOINT: GET /estudiantes/:codigo/matriculas - Matrículas del estudiante
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'estudiantes',
        p_pattern        => ':codigo/matriculas',
        p_priority       => 0,
        p_comments       => 'Matrículas de un estudiante'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'estudiantes',
        p_pattern        => ':codigo/matriculas',
        p_method         => 'GET',
        p_source_type    => 'json/collection',
        p_source         => 'SELECT 
                                m.cod_matricula,
                                m.cod_periodo,
                                p.nombre_periodo,
                                m.fecha_matricula,
                                m.estado_matricula,
                                m.total_creditos,
                                COUNT(dm.cod_detalle) as total_asignaturas
                             FROM MATRICULA m
                             JOIN PERIODO_ACADEMICO p ON m.cod_periodo = p.cod_periodo
                             LEFT JOIN DETALLE_MATRICULA dm ON m.cod_matricula = dm.cod_matricula
                             WHERE m.cod_estudiante = :codigo
                             GROUP BY m.cod_matricula, m.cod_periodo, p.nombre_periodo, 
                                      m.fecha_matricula, m.estado_matricula, m.total_creditos
                             ORDER BY m.fecha_matricula DESC',
        p_comments       => 'Lista las matrículas de un estudiante'
    );
    
    COMMIT;
END;
/

PROMPT '✓ GET /estudiantes/:codigo/matriculas - Matrículas del estudiante'

-- =====================================================
-- RESUMEN
-- =====================================================

PROMPT ''
PROMPT '========================================='
PROMPT 'API ESTUDIANTES CREADA EXITOSAMENTE'
PROMPT '========================================='
PROMPT ''
PROMPT 'Endpoints disponibles:'
PROMPT '  GET    /estudiantes/              - Lista todos los estudiantes'
PROMPT '  GET    /estudiantes/:codigo       - Obtiene un estudiante'
PROMPT '  POST   /estudiantes/              - Crea nuevo estudiante'
PROMPT '  PUT    /estudiantes/:codigo       - Actualiza estudiante'
PROMPT '  GET    /estudiantes/:codigo/matriculas - Matrículas del estudiante'
PROMPT ''
PROMPT 'URL Base: http://localhost:8080/ords/academico/estudiantes/'
PROMPT ''
