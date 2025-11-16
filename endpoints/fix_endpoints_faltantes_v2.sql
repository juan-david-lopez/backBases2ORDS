-- =====================================================
-- FIX: Endpoints faltantes - Version 2
-- =====================================================
-- Corrige 4 endpoints con errores 404
-- Usa enfoque sin DELETE_TEMPLATE
-- =====================================================

SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT =====================================================
PROMPT Creando endpoints faltantes (Intento 2)
PROMPT =====================================================

-- =====================================================
-- 1. /registro-materias/disponibles/:cod_estudiante
-- =====================================================

BEGIN
    ORDS.DEFINE_HANDLER(
        p_module_name => 'registro_materias',
        p_pattern     => 'disponibles/:cod_estudiante',
        p_method      => 'GET',
        p_source_type => 'plsql/block',
        p_source      => 'DECLARE
    v_cod_programa NUMBER;
    v_count NUMBER := 0;
BEGIN
    SELECT e.cod_programa INTO v_cod_programa
    FROM ESTUDIANTE e
    WHERE e.cod_estudiante = :cod_estudiante;
    
    HTP.PRINT(''['');
    FOR rec IN (
        SELECT 
            a.cod_asignatura,
            a.nombre_asignatura,
            a.creditos,
            a.nivel
        FROM ASIGNATURA a
        WHERE a.cod_programa = v_cod_programa
        AND a.estado_asignatura = ''ACTIVO''
    ) LOOP
        IF v_count > 0 THEN HTP.PRINT('',''); END IF;
        HTP.PRINT(''{''||
            ''"cod_asignatura":''||rec.cod_asignatura||'',''||
            ''"nombre":"''||rec.nombre_asignatura||''",''||
            ''"creditos":''||rec.creditos||'',''||
            ''"nivel":''||rec.nivel||
        ''}'');
        v_count := v_count + 1;
    END LOOP;
    HTP.PRINT('']'');
    :status_code := 200;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        :status_code := 404;
        HTP.PRINT(''{"error":"Estudiante no encontrado"}'');
    WHEN OTHERS THEN
        :status_code := 500;
        HTP.PRINT(''{"error":"''||SQLERRM||''"}'');
END;'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /disponibles/:cod_estudiante creado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Error en disponibles: ' || SQLERRM);
END;
/

-- =====================================================
-- 2. /registro-materias/mi-horario/:cod_estudiante
-- =====================================================

BEGIN
    ORDS.DEFINE_HANDLER(
        p_module_name => 'registro_materias',
        p_pattern     => 'mi-horario/:cod_estudiante',
        p_method      => 'GET',
        p_source_type => 'plsql/block',
        p_source      => 'DECLARE
    v_count NUMBER := 0;
BEGIN
    HTP.PRINT(''['');
    FOR rec IN (
        SELECT 
            a.nombre_asignatura,
            g.numero_grupo,
            h.dia_semana,
            TO_CHAR(h.hora_inicio, ''HH24:MI'') as hora_inicio,
            TO_CHAR(h.hora_fin, ''HH24:MI'') as hora_fin,
            h.aula
        FROM DETALLE_MATRICULA dm
        JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
        JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
        JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
        JOIN HORARIO h ON g.cod_grupo = h.cod_grupo
        JOIN PERIODO_ACADEMICO pa ON m.cod_periodo = pa.cod_periodo
        WHERE m.cod_estudiante = :cod_estudiante
        AND pa.estado_periodo = ''ACTIVO''
        AND dm.estado_inscripcion = ''INSCRITO''
    ) LOOP
        IF v_count > 0 THEN HTP.PRINT('',''); END IF;
        HTP.PRINT(''{''||
            ''"asignatura":"''||rec.nombre_asignatura||''",''||
            ''"grupo":''||rec.numero_grupo||'',''||
            ''"dia":"''||rec.dia_semana||''",''||
            ''"hora_inicio":"''||rec.hora_inicio||''",''||
            ''"hora_fin":"''||rec.hora_fin||''",''||
            ''"aula":"''||rec.aula||''"''||
        ''}'');
        v_count := v_count + 1;
    END LOOP;
    HTP.PRINT('']'');
    :status_code := 200;
EXCEPTION
    WHEN OTHERS THEN
        :status_code := 500;
        HTP.PRINT(''{"error":"''||SQLERRM||''"}'');
END;'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /mi-horario/:cod_estudiante creado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Error en mi-horario: ' || SQLERRM);
END;
/

-- =====================================================
-- 3. /alertas/riesgo-academico
-- =====================================================

BEGIN
    ORDS.DEFINE_HANDLER(
        p_module_name => 'alertas',
        p_pattern     => 'riesgo-academico',
        p_method      => 'GET',
        p_source_type => 'plsql/block',
        p_source      => 'DECLARE
    v_count NUMBER := 0;
BEGIN
    HTP.PRINT(''['');
    FOR rec IN (
        SELECT 
            e.cod_estudiante,
            e.nombre_estudiante || '' '' || e.apellido_estudiante as nombre,
            hr.nivel_riesgo,
            hr.tipo_riesgo,
            hr.promedio_periodo,
            TO_CHAR(hr.fecha_deteccion, ''YYYY-MM-DD'') as fecha
        FROM ESTUDIANTE e
        JOIN HISTORIAL_RIESGO hr ON e.cod_estudiante = hr.cod_estudiante
        WHERE hr.nivel_riesgo IN (''ALTO'', ''MEDIO'')
        AND e.estado_estudiante = ''ACTIVO''
        ORDER BY DECODE(hr.nivel_riesgo, ''ALTO'', 1, 2)
    ) LOOP
        IF v_count > 0 THEN HTP.PRINT('',''); END IF;
        HTP.PRINT(''{''||
            ''"cod_estudiante":''||rec.cod_estudiante||'',''||
            ''"nombre":"''||rec.nombre||''",''||
            ''"nivel_riesgo":"''||rec.nivel_riesgo||''",''||
            ''"tipo_riesgo":"''||rec.tipo_riesgo||''",''||
            ''"promedio":''||NVL(rec.promedio_periodo, 0)||'',''||
            ''"fecha":"''||rec.fecha||''"''||
        ''}'');
        v_count := v_count + 1;
    END LOOP;
    HTP.PRINT('']'');
    :status_code := 200;
EXCEPTION
    WHEN OTHERS THEN
        :status_code := 500;
        HTP.PRINT(''{"error":"''||SQLERRM||''"}'');
END;'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /riesgo-academico creado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Error en riesgo-academico: ' || SQLERRM);
END;
/

-- =====================================================
-- 4. /alertas/ventanas-calendario
-- =====================================================

BEGIN
    ORDS.DEFINE_HANDLER(
        p_module_name => 'alertas',
        p_pattern     => 'ventanas-calendario',
        p_method      => 'GET',
        p_source_type => 'plsql/block',
        p_source      => 'DECLARE
    v_count NUMBER := 0;
BEGIN
    HTP.PRINT(''['');
    FOR rec IN (
        SELECT 
            vc.cod_ventana_calendario,
            vc.tipo_ventana,
            vc.nombre_ventana,
            TO_CHAR(vc.fecha_inicio, ''YYYY-MM-DD'') as fecha_inicio,
            TO_CHAR(vc.fecha_fin, ''YYYY-MM-DD'') as fecha_fin
        FROM VENTANA_CALENDARIO vc
        WHERE vc.estado_ventana = ''ACTIVA''
        ORDER BY vc.fecha_inicio
    ) LOOP
        IF v_count > 0 THEN HTP.PRINT('',''); END IF;
        HTP.PRINT(''{''||
            ''"cod_ventana":''||rec.cod_ventana_calendario||'',''||
            ''"tipo":"''||rec.tipo_ventana||''",''||
            ''"nombre":"''||rec.nombre_ventana||''",''||
            ''"fecha_inicio":"''||rec.fecha_inicio||''",''||
            ''"fecha_fin":"''||rec.fecha_fin||''"''||
        ''}'');
        v_count := v_count + 1;
    END LOOP;
    HTP.PRINT('']'');
    :status_code := 200;
EXCEPTION
    WHEN OTHERS THEN
        :status_code := 500;
        HTP.PRINT(''{"error":"''||SQLERRM||''"}'');
END;'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /ventanas-calendario creado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ Error en ventanas-calendario: ' || SQLERRM);
END;
/

PROMPT =====================================================
PROMPT Proceso completado
PROMPT =====================================================

EXIT;
