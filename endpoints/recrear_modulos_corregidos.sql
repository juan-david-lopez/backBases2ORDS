-- =====================================================
-- RECREAR MÓDULOS CON CORRECCIONES DE COLUMNAS
-- Ejecutar como: sqlplus sys/tu_password@localhost:1521/xepdb1 as sysdba
-- =====================================================

   SET SERVEROUTPUT ON
SET VERIFY OFF

PROMPT ========================================
PROMPT ELIMINANDO MÓDULOS EXISTENTES
PROMPT ========================================

-- Conectar al usuario ACADEMICO
alter session set current_schema = academico;

-- Eliminar módulos
begin
   ords.delete_module(p_module_name => 'docente');
   dbms_output.put_line('✓ Módulo docente eliminado');
exception
   when others then
      dbms_output.put_line('⚠ Módulo docente no existe o ya fue eliminado');
end;
/

begin
   ords.delete_module(p_module_name => 'alertas');
   dbms_output.put_line('✓ Módulo alertas eliminado');
exception
   when others then
      dbms_output.put_line('⚠ Módulo alertas no existe o ya fue eliminado');
end;
/

commit;

PROMPT
PROMPT ========================================
PROMPT RECREANDO MÓDULO: DOCENTE
PROMPT ========================================

-- Crear módulo docente
begin
   ords.create_module(
      p_module_name    => 'docente',
      p_base_path      => '/docente/',
      p_items_per_page => 25,
      p_status         => 'PUBLISHED',
      p_comments       => 'API para gestion de grupos y calificaciones por docentes'
   );
   commit;
   dbms_output.put_line('✓ Módulo docente creado');
end;
/

-- ENDPOINT: GET /reglas-evaluacion/:cod_grupo (CORREGIDO)
begin
   ords.define_template(
      p_module_name => 'docente',
      p_pattern     => 'reglas-evaluacion/:cod_grupo'
   );
   ords.define_handler(
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
            re.porcentaje,
            re.cantidad_actividades,
            re.descripcion
        FROM REGLA_EVALUACION re
        JOIN TIPO_ACTIVIDAD_EVALUATIVA ta ON re.cod_tipo_actividad = ta.cod_tipo_actividad
        WHERE re.cod_asignatura = v_cod_asignatura
        ORDER BY ta.cod_tipo_actividad
    ) LOOP
        HTP.PRINT(JSON_OBJECT(
            'cod_regla' VALUE rec.cod_regla,
            'actividad' VALUE rec.nombre_actividad,
            'descripcion' VALUE rec.descripcion,
            'porcentaje' VALUE rec.porcentaje,
            'cantidad' VALUE rec.cantidad_actividades
        ) || ',');
    END LOOP;
    HTP.PRINT('{}], "suma_porcentajes": ' || v_suma_porcentajes || ', "valido": ' || 
              CASE WHEN v_suma_porcentajes = 100 THEN 'true' ELSE 'false' END || '}');
    
    :status_code := 200;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        :status_code := 404;
        HTP.PRINT('{"error": "Grupo no encontrado"}');
    WHEN OTHERS THEN
        :status_code := 500;
        HTP.PRINT('{"error": "' || REPLACE(SQLERRM, '"', '\"') || '"}');
END;
]'
   );
   commit;
   dbms_output.put_line('✓ GET /reglas-evaluacion/:cod_grupo creado');
end;
/

PROMPT
PROMPT ========================================
PROMPT RECREANDO MÓDULO: ALERTAS
PROMPT ========================================

-- Crear módulo alertas
begin
   ords.create_module(
      p_module_name    => 'alertas',
      p_base_path      => '/alertas/',
      p_items_per_page => 25,
      p_status         => 'PUBLISHED',
      p_comments       => 'API para alertas tempranas y reportes academicos'
   );
   commit;
   dbms_output.put_line('✓ Módulo alertas creado');
end;
/

-- ENDPOINT: GET /estudiante/:cod_estudiante (CORREGIDO)
begin
   ords.define_template(
      p_module_name => 'alertas',
      p_pattern     => 'estudiante/:cod_estudiante'
   );
   ords.define_handler(
      p_module_name => 'alertas',
      p_pattern     => 'estudiante/:cod_estudiante',
      p_method      => 'GET',
      p_source_type => 'plsql/block',
      p_source      => q'[
DECLARE
    v_riesgo VARCHAR2(20) := 'BAJO';
    v_promedio NUMBER;
    v_reprobadas NUMBER;
    v_creditos_max NUMBER;
    v_creditos_actuales NUMBER;
    v_alertas JSON_ARRAY_T := JSON_ARRAY_T();
    v_alerta JSON_OBJECT_T;
BEGIN
    -- Obtener riesgo mas reciente (CORREGIDO: fecha_deteccion)
    BEGIN
        SELECT nivel_riesgo INTO v_riesgo
        FROM (
            SELECT nivel_riesgo
            FROM HISTORIAL_RIESGO
            WHERE cod_estudiante = :cod_estudiante
            ORDER BY fecha_deteccion DESC
        )
        WHERE ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_riesgo := 'BAJO';
    END;

    -- Obtener informacion academica
    SELECT
        (SELECT COALESCE(AVG(nota_final), 0)
         FROM NOTA_DEFINITIVA
         WHERE cod_estudiante = :cod_estudiante),
        (SELECT COUNT(*)
         FROM NOTA_DEFINITIVA
         WHERE cod_estudiante = :cod_estudiante
         AND resultado = 'REPROBADO')
    INTO v_promedio, v_reprobadas
    FROM DUAL;

    -- Creditos maximos segun riesgo
    v_creditos_max := CASE v_riesgo
        WHEN 'ALTO' THEN 12
        WHEN 'MEDIO' THEN 16
        ELSE 20
    END;

    -- Creditos actuales
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

    -- Generar alertas
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

    IF v_promedio < 3.0 AND v_promedio > 0 THEN
        v_alerta := JSON_OBJECT_T();
        v_alerta.put('tipo', 'PROMEDIO_BAJO');
        v_alerta.put('nivel', 'ADVERTENCIA');
        v_alerta.put('promedio', ROUND(v_promedio, 2));
        v_alerta.put('mensaje', 'Promedio acumulado por debajo de 3.0');
        v_alerta.put('recomendacion', 'Buscar apoyo academico y mejorar habitos de estudio');
        v_alertas.append(v_alerta.to_clob());
    END IF;

    IF v_reprobadas > 0 THEN
        v_alerta := JSON_OBJECT_T();
        v_alerta.put('tipo', 'ASIGNATURAS_REPROBADAS');
        v_alerta.put('nivel', CASE WHEN v_reprobadas >= 3 THEN 'CRITICO' ELSE 'ADVERTENCIA' END);
        v_alerta.put('cantidad', v_reprobadas);
        v_alerta.put('mensaje', v_reprobadas || ' asignatura(s) reprobada(s)');
        v_alerta.put('recomendacion', 'Debe inscribir asignaturas perdidas prioritariamente');
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
   commit;
   dbms_output.put_line('✓ GET /estudiante/:cod_estudiante creado');
end;
/

-- ENDPOINT: GET /reporte-general (CORREGIDO)
begin
   ords.define_template(
      p_module_name => 'alertas',
      p_pattern     => 'reporte-general'
   );
   ords.define_handler(
      p_module_name => 'alertas',
      p_pattern     => 'reporte-general',
      p_method      => 'GET',
      p_source_type => 'plsql/block',
      p_source      => q'[
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
    -- Estadisticas de estudiantes
    SELECT COUNT(*),
           COUNT(CASE WHEN estado_estudiante = 'ACTIVO' THEN 1 END)
    INTO v_total_estudiantes, v_estudiantes_activos
    FROM ESTUDIANTE;

    -- Riesgo academico (CORREGIDO: fecha_deteccion)
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

    -- Estadisticas de grupos
    SELECT COUNT(*),
           COUNT(CASE WHEN estado_grupo = 'ACTIVO' THEN 1 END)
    INTO v_total_grupos, v_grupos_activos
    FROM GRUPO;

    -- Total docentes activos
    SELECT COUNT(*) INTO v_total_docentes
    FROM DOCENTE WHERE estado_docente = 'ACTIVO';

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
   commit;
   dbms_output.put_line('✓ GET /reporte-general creado');
end;
/

commit;

PROMPT
PROMPT ========================================
PROMPT CORRECCIONES APLICADAS:
PROMPT ========================================
PROMPT 1. REGLA_EVALUACION: usa cod_asignatura (no cod_grupo)
PROMPT 2. HISTORIAL_RIESGO: usa fecha_deteccion (no fecha_evaluacion)
PROMPT 3. REGLA_EVALUACION: columna porcentaje (no porcentaje_nota)
PROMPT
PROMPT ✓ Módulos recreados exitosamente
PROMPT ========================================