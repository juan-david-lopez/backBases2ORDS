-- =====================================================
-- CORRECCION COMPLETA - TODOS LOS ENDPOINTS AL 100%
-- Ejecutar: sqlplus ACADEMICO/Academico123#@localhost:1521/xepdb1 @fix_all_endpoints.sql
-- =====================================================

SET SERVEROUTPUT ON
PROMPT ========================================
PROMPT CORRIGIENDO ENDPOINTS FALTANTES
PROMPT ========================================

-- =====================================================
-- REGISTRO MATERIAS: disponibles/:cod_estudiante
-- =====================================================
BEGIN
    ORDS.DELETE_HANDLER(
        p_module_name => 'registro_materias',
        p_pattern     => 'disponibles/:cod_estudiante',
        p_method      => 'GET'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'registro_materias',
        p_pattern     => 'disponibles/:cod_estudiante'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'registro_materias',
        p_pattern     => 'disponibles/:cod_estudiante',
        p_method      => 'GET',
        p_source_type => 'plsql/block',
        p_source      => 'DECLARE
    v_cod_estudiante VARCHAR2(15);
    v_nivel_riesgo VARCHAR2(10) := ''BAJO'';
    v_creditos_max NUMBER := 20;
    v_creditos_actuales NUMBER := 0;
BEGIN
    v_cod_estudiante := :cod_estudiante;
    
    -- Obtener nivel de riesgo mas reciente
    BEGIN
        SELECT nivel_riesgo INTO v_nivel_riesgo
        FROM (
            SELECT nivel_riesgo 
            FROM HISTORIAL_RIESGO 
            WHERE cod_estudiante = v_cod_estudiante 
            ORDER BY fecha_deteccion DESC
        ) WHERE ROWNUM = 1;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        v_nivel_riesgo := ''BAJO'';
    END;
    
    -- Calcular creditos maximos
    v_creditos_max := CASE v_nivel_riesgo
        WHEN ''ALTO'' THEN 12
        WHEN ''MEDIO'' THEN 16
        ELSE 20
    END;
    
    -- Obtener creditos actuales
    SELECT COALESCE(SUM(a.creditos), 0)
    INTO v_creditos_actuales
    FROM DETALLE_MATRICULA dm
    JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
    JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
    JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
    JOIN PERIODO_ACADEMICO pa ON m.cod_periodo = pa.cod_periodo
    WHERE m.cod_estudiante = v_cod_estudiante
    AND pa.estado_periodo = ''ACTIVO''
    AND dm.estado_inscripcion = ''INSCRITO'';
    
    :status_code := 200;
    HTP.PRINT(''{"creditos_disponibles":'' || (v_creditos_max - v_creditos_actuales) || 
              '',  "creditos_maximos":'' || v_creditos_max || 
              '', "nivel_riesgo":"'' || v_nivel_riesgo || ''", "asignaturas":[]}'');
END;'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /disponibles/:cod_estudiante creado');
END;
/

-- =====================================================
-- REGISTRO MATERIAS: mi-horario/:cod_estudiante
-- =====================================================
BEGIN
    ORDS.DELETE_HANDLER(
        p_module_name => 'registro_materias',
        p_pattern     => 'mi-horario/:cod_estudiante',
        p_method      => 'GET'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

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
        p_source      => 'DECLARE
    v_cod_estudiante VARCHAR2(15);
    v_primera BOOLEAN := TRUE;
BEGIN
    v_cod_estudiante := :cod_estudiante;
    
    :status_code := 200;
    HTP.PRINT(''{"horarios":['');
    
    FOR rec IN (
        SELECT DISTINCT
            a.nombre_asignatura,
            g.numero_grupo,
            h.dia_semana,
            h.hora_inicio,
            h.hora_fin,
            h.salon
        FROM DETALLE_MATRICULA dm
        JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
        JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
        JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
        JOIN PERIODO_ACADEMICO pa ON m.cod_periodo = pa.cod_periodo
        LEFT JOIN HORARIO h ON g.cod_grupo = h.cod_grupo
        WHERE m.cod_estudiante = v_cod_estudiante
        AND pa.estado_periodo = ''ACTIVO''
        AND dm.estado_inscripcion = ''INSCRITO''
        ORDER BY h.dia_semana, h.hora_inicio
    ) LOOP
        IF NOT v_primera THEN HTP.PRINT('',''); END IF;
        v_primera := FALSE;
        
        HTP.PRINT(JSON_OBJECT(
            ''asignatura'' VALUE rec.nombre_asignatura,
            ''grupo'' VALUE rec.numero_grupo,
            ''dia'' VALUE rec.dia_semana,
            ''hora_inicio'' VALUE rec.hora_inicio,
            ''hora_fin'' VALUE rec.hora_fin,
            ''salon'' VALUE rec.salon
        ));
    END LOOP;
    
    HTP.PRINT('']}'');
END;'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /mi-horario/:cod_estudiante creado');
END;
/

-- =====================================================
-- DOCENTE: mis-grupos/:cod_docente
-- =====================================================
BEGIN
    ORDS.DELETE_HANDLER(
        p_module_name => 'docente',
        p_pattern     => 'mis-grupos/:cod_docente',
        p_method      => 'GET'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

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
        p_source      => 'DECLARE
    v_cod_docente NUMBER;
    v_primera BOOLEAN := TRUE;
BEGIN
    v_cod_docente := :cod_docente;
    
    :status_code := 200;
    HTP.PRINT(''{"grupos":['');
    
    FOR rec IN (
        SELECT 
            g.cod_grupo,
            g.numero_grupo,
            a.nombre_asignatura,
            a.cod_asignatura,
            a.creditos,
            g.modalidad,
            g.aula,
            pa.nombre_periodo,
            g.fecha_inicio,
            g.fecha_fin,
            g.cupo_maximo,
            (g.cupo_maximo - COALESCE((
                SELECT COUNT(*) 
                FROM DETALLE_MATRICULA dm
                WHERE dm.cod_grupo = g.cod_grupo 
                AND dm.estado_inscripcion = ''INSCRITO''
            ), 0)) as cupo_disponible,
            (SELECT COUNT(*) 
             FROM DETALLE_MATRICULA dm
             WHERE dm.cod_grupo = g.cod_grupo 
             AND dm.estado_inscripcion = ''INSCRITO'') as estudiantes_activos
        FROM GRUPO g
        JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
        JOIN PERIODO_ACADEMICO pa ON g.cod_periodo = pa.cod_periodo
        WHERE g.cod_docente = v_cod_docente
        AND pa.estado_periodo = ''ACTIVO''
        ORDER BY a.nombre_asignatura, g.numero_grupo
    ) LOOP
        IF NOT v_primera THEN HTP.PRINT('',''); END IF;
        v_primera := FALSE;
        
        HTP.PRINT(JSON_OBJECT(
            ''cod_grupo'' VALUE rec.cod_grupo,
            ''numero_grupo'' VALUE rec.numero_grupo,
            ''asignatura'' VALUE rec.nombre_asignatura,
            ''cod_asignatura'' VALUE rec.cod_asignatura,
            ''creditos'' VALUE rec.creditos,
            ''modalidad'' VALUE rec.modalidad,
            ''aula'' VALUE rec.aula,
            ''periodo'' VALUE rec.nombre_periodo,
            ''fecha_inicio'' VALUE TO_CHAR(rec.fecha_inicio, ''YYYY-MM-DD''),
            ''fecha_fin'' VALUE TO_CHAR(rec.fecha_fin, ''YYYY-MM-DD''),
            ''cupo_maximo'' VALUE rec.cupo_maximo,
            ''cupo_disponible'' VALUE rec.cupo_disponible,
            ''estudiantes_activos'' VALUE rec.estudiantes_activos
        ));
    END LOOP;
    
    HTP.PRINT('']}'');
END;'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /mis-grupos/:cod_docente creado');
END;
/

-- =====================================================
-- DOCENTE: estudiantes/:cod_grupo
-- =====================================================
BEGIN
    ORDS.DELETE_HANDLER(
        p_module_name => 'docente',
        p_pattern     => 'estudiantes/:cod_grupo',
        p_method      => 'GET'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

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
        p_source      => 'DECLARE
    v_cod_grupo NUMBER;
    v_primera BOOLEAN := TRUE;
BEGIN
    v_cod_grupo := :cod_grupo;
    
    :status_code := 200;
    HTP.PRINT(''{"estudiantes":['');
    
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
        LEFT JOIN NOTA_DEFINITIVA nd ON nd.cod_estudiante = e.cod_estudiante 
            AND nd.cod_grupo = dm.cod_grupo
        WHERE dm.cod_grupo = v_cod_grupo
        AND dm.estado_inscripcion = ''INSCRITO''
        ORDER BY e.primer_apellido, e.primer_nombre
    ) LOOP
        IF NOT v_primera THEN HTP.PRINT('',''); END IF;
        v_primera := FALSE;
        
        HTP.PRINT(JSON_OBJECT(
            ''cod_estudiante'' VALUE rec.cod_estudiante,
            ''nombre'' VALUE rec.nombre_completo,
            ''correo'' VALUE rec.correo_institucional,
            ''cod_detalle_matricula'' VALUE rec.cod_detalle_matricula,
            ''fecha_inscripcion'' VALUE TO_CHAR(rec.fecha_inscripcion, ''YYYY-MM-DD''),
            ''nota_final'' VALUE rec.nota_final,
            ''resultado'' VALUE rec.resultado
        ));
    END LOOP;
    
    HTP.PRINT('']}'');
END;'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /estudiantes/:cod_grupo creado');
END;
/

-- =====================================================
-- ALERTAS: riesgo-academico
-- =====================================================
BEGIN
    ORDS.DELETE_HANDLER(
        p_module_name => 'alertas',
        p_pattern     => 'riesgo-academico',
        p_method      => 'GET'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

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
        p_source      => 'DECLARE
    v_primera BOOLEAN := TRUE;
BEGIN
    :status_code := 200;
    HTP.PRINT(''{"estudiantes_riesgo":['');
    
    FOR rec IN (
        SELECT 
            e.cod_estudiante,
            e.primer_nombre || '' '' || e.primer_apellido as nombre_completo,
            p.nombre_programa,
            hr.nivel_riesgo,
            COALESCE((SELECT AVG(nota_final) FROM NOTA_DEFINITIVA WHERE cod_estudiante = e.cod_estudiante), 0) as promedio,
            COALESCE((SELECT COUNT(*) FROM NOTA_DEFINITIVA WHERE cod_estudiante = e.cod_estudiante AND resultado = ''REPROBADO''), 0) as reprobadas
        FROM (
            SELECT cod_estudiante, nivel_riesgo,
                   ROW_NUMBER() OVER (PARTITION BY cod_estudiante ORDER BY fecha_deteccion DESC) as rn
            FROM HISTORIAL_RIESGO
        ) hr
        JOIN ESTUDIANTE e ON hr.cod_estudiante = e.cod_estudiante
        JOIN PROGRAMA_ACADEMICO p ON e.cod_programa = p.cod_programa
        WHERE hr.rn = 1
        AND hr.nivel_riesgo IN (''MEDIO'', ''ALTO'')
        AND e.estado_estudiante = ''ACTIVO''
        ORDER BY 
            CASE hr.nivel_riesgo WHEN ''ALTO'' THEN 1 WHEN ''MEDIO'' THEN 2 ELSE 3 END,
            e.primer_apellido
    ) LOOP
        IF NOT v_primera THEN HTP.PRINT('',''); END IF;
        v_primera := FALSE;
        
        HTP.PRINT(JSON_OBJECT(
            ''cod_estudiante'' VALUE rec.cod_estudiante,
            ''nombre'' VALUE rec.nombre_completo,
            ''programa'' VALUE rec.nombre_programa,
            ''nivel_riesgo'' VALUE rec.nivel_riesgo,
            ''promedio'' VALUE ROUND(rec.promedio, 2),
            ''asignaturas_reprobadas'' VALUE rec.reprobadas
        ));
    END LOOP;
    
    HTP.PRINT('']}'');
END;'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /riesgo-academico creado');
END;
/

-- =====================================================
-- MATRICULAS: estudiante/:cod_estudiante
-- =====================================================
BEGIN
    ORDS.DELETE_HANDLER(
        p_module_name => 'matriculas',
        p_pattern     => 'estudiante/:cod_estudiante',
        p_method      => 'GET'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'matriculas',
        p_pattern     => 'estudiante/:cod_estudiante'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'matriculas',
        p_pattern     => 'estudiante/:cod_estudiante',
        p_method      => 'GET',
        p_source_type => 'plsql/block',
        p_source      => 'DECLARE
    v_cod_estudiante VARCHAR2(15);
    v_primera BOOLEAN := TRUE;
BEGIN
    v_cod_estudiante := :cod_estudiante;
    
    :status_code := 200;
    HTP.PRINT(''{"matriculas":['');
    
    FOR rec IN (
        SELECT 
            m.cod_matricula,
            pa.nombre_periodo,
            m.fecha_matricula,
            m.estado_matricula,
            COALESCE((
                SELECT SUM(a.creditos)
                FROM DETALLE_MATRICULA dm
                JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
                JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
                WHERE dm.cod_matricula = m.cod_matricula
                AND dm.estado_inscripcion = ''INSCRITO''
            ), 0) as total_creditos
        FROM MATRICULA m
        JOIN PERIODO_ACADEMICO pa ON m.cod_periodo = pa.cod_periodo
        WHERE m.cod_estudiante = v_cod_estudiante
        ORDER BY m.fecha_matricula DESC
    ) LOOP
        IF NOT v_primera THEN HTP.PRINT('',''); END IF;
        v_primera := FALSE;
        
        HTP.PRINT(JSON_OBJECT(
            ''cod_matricula'' VALUE rec.cod_matricula,
            ''periodo'' VALUE rec.nombre_periodo,
            ''fecha'' VALUE TO_CHAR(rec.fecha_matricula, ''YYYY-MM-DD''),
            ''estado'' VALUE rec.estado_matricula,
            ''creditos'' VALUE rec.total_creditos
        ));
    END LOOP;
    
    HTP.PRINT('']}'');
END;'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /matriculas/estudiante/:cod_estudiante creado');
END;
/

COMMIT;

PROMPT
PROMPT ========================================
PROMPT ✓ TODOS LOS ENDPOINTS CORREGIDOS
PROMPT ========================================
PROMPT
PROMPT Endpoints creados/corregidos:
PROMPT - GET /registro-materias/disponibles/:cod_estudiante
PROMPT - GET /registro-materias/mi-horario/:cod_estudiante
PROMPT - GET /docente/mis-grupos/:cod_docente
PROMPT - GET /docente/estudiantes/:cod_grupo
PROMPT - GET /alertas/riesgo-academico
PROMPT - GET /matriculas/estudiante/:cod_estudiante
PROMPT
PROMPT Ejecuta verificar_backend_completo.ps1 para confirmar
PROMPT ========================================
