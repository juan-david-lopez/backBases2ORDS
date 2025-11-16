-- =====================================================
-- API DE VENTANAS DE CALENDARIO
-- Archivo: 09_ventanas_calendario_api.sql
-- Propósito: Endpoints para gestión de ventanas académicas
-- Ejecutar como: ACADEMICO
-- =====================================================

SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT =====================================================
PROMPT Creando módulo VENTANAS DE CALENDARIO
PROMPT =====================================================

-- =====================================================
-- ENDPOINT: GET /alertas/ventanas-calendario
-- Descripción: Obtener ventanas de calendario académico activas
-- =====================================================

BEGIN
    -- Verificar si el template ya existe antes de crearlo
    BEGIN
        ORDS.DEFINE_TEMPLATE(
            p_module_name => 'alertas',
            p_pattern     => 'ventanas-calendario'
        );
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -20102 THEN -- Ignorar si ya existe
                RAISE;
            END IF;
    END;
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'alertas',
        p_pattern     => 'ventanas-calendario',
        p_method      => 'GET',
        p_source_type => 'plsql/block',
        p_source      => q'!
DECLARE
    v_count NUMBER := 0;
BEGIN
    HTP.PRINT('[');
    FOR rec IN (
        SELECT 
            vc.cod_ventana_calendario,
            vc.tipo_ventana,
            vc.nombre_ventana,
            vc.descripcion,
            TO_CHAR(vc.fecha_inicio, 'YYYY-MM-DD HH24:MI:SS') as fecha_inicio,
            TO_CHAR(vc.fecha_fin, 'YYYY-MM-DD HH24:MI:SS') as fecha_fin,
            vc.estado_ventana,
            pa.nombre_periodo,
            pa.cod_periodo,
            -- Verificar si está activa (fecha actual entre inicio y fin)
            CASE 
                WHEN SYSDATE BETWEEN vc.fecha_inicio AND vc.fecha_fin 
                     AND vc.estado_ventana = 'ACTIVA' 
                THEN 'SI'
                ELSE 'NO'
            END as esta_activa,
            -- Calcular días restantes
            CASE 
                WHEN SYSDATE < vc.fecha_inicio 
                THEN TRUNC(vc.fecha_inicio - SYSDATE)
                WHEN SYSDATE BETWEEN vc.fecha_inicio AND vc.fecha_fin 
                THEN TRUNC(vc.fecha_fin - SYSDATE)
                ELSE 0
            END as dias_restantes
        FROM VENTANA_CALENDARIO vc
        JOIN PERIODO_ACADEMICO pa ON vc.cod_periodo = pa.cod_periodo
        WHERE vc.estado_ventana = 'ACTIVA'
        OR (SYSDATE BETWEEN vc.fecha_inicio AND vc.fecha_fin)
        ORDER BY vc.fecha_inicio
    ) LOOP
        IF v_count > 0 THEN 
            HTP.PRINT(','); 
        END IF;
        
        HTP.PRINT(JSON_OBJECT(
            'cod_ventana' VALUE rec.cod_ventana_calendario,
            'tipo' VALUE rec.tipo_ventana,
            'nombre' VALUE rec.nombre_ventana,
            'descripcion' VALUE rec.descripcion,
            'fecha_inicio' VALUE rec.fecha_inicio,
            'fecha_fin' VALUE rec.fecha_fin,
            'estado' VALUE rec.estado_ventana,
            'periodo' VALUE rec.nombre_periodo,
            'cod_periodo' VALUE rec.cod_periodo,
            'activa_ahora' VALUE rec.esta_activa,
            'dias_restantes' VALUE rec.dias_restantes
        ));
        
        v_count := v_count + 1;
    END LOOP;
    
    HTP.PRINT(']');
    
    :status_code := 200;
    
EXCEPTION
    WHEN OTHERS THEN
        :status_code := 500;
        HTP.PRINT('{"error": "' || REPLACE(SQLERRM, '"', '\"') || '"}');
END;
!'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /alertas/ventanas-calendario creado');
END;
/

-- =====================================================
-- ENDPOINT: GET /alertas/ventana-activa/:tipo_ventana
-- Descripción: Verificar si hay ventana activa de un tipo específico
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'alertas',
        p_pattern     => 'ventana-activa/:tipo_ventana'
    );
    
    ORDS.DEFINE_HANDLER(
        p_module_name => 'alertas',
        p_pattern     => 'ventana-activa/:tipo_ventana',
        p_method      => 'GET',
        p_source_type => 'plsql/block',
        p_source      => q'!
DECLARE
    v_ventana_activa NUMBER := 0;
    v_cod_ventana NUMBER;
    v_nombre VARCHAR2(200);
    v_fecha_fin DATE;
    v_dias_restantes NUMBER;
BEGIN
    -- Buscar ventana activa del tipo solicitado
    BEGIN
        SELECT 
            vc.cod_ventana_calendario,
            vc.nombre_ventana,
            vc.fecha_fin,
            TRUNC(vc.fecha_fin - SYSDATE)
        INTO v_cod_ventana, v_nombre, v_fecha_fin, v_dias_restantes
        FROM VENTANA_CALENDARIO vc
        WHERE vc.tipo_ventana = :tipo_ventana
        AND SYSDATE BETWEEN vc.fecha_inicio AND vc.fecha_fin
        AND vc.estado_ventana = 'ACTIVA'
        AND ROWNUM = 1
        ORDER BY vc.fecha_inicio DESC;
        
        v_ventana_activa := 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_ventana_activa := 0;
    END;
    
    IF v_ventana_activa = 1 THEN
        HTP.PRINT(JSON_OBJECT(
            'ventana_activa' VALUE 'SI',
            'cod_ventana' VALUE v_cod_ventana,
            'nombre' VALUE v_nombre,
            'fecha_fin' VALUE TO_CHAR(v_fecha_fin, 'YYYY-MM-DD HH24:MI:SS'),
            'dias_restantes' VALUE v_dias_restantes,
            'mensaje' VALUE 'Ventana de ' || :tipo_ventana || ' está activa'
        ));
    ELSE
        HTP.PRINT(JSON_OBJECT(
            'ventana_activa' VALUE 'NO',
            'mensaje' VALUE 'No hay ventana activa para ' || :tipo_ventana,
            'tipo_buscado' VALUE :tipo_ventana
        ));
    END IF;
    
    :status_code := 200;
    
EXCEPTION
    WHEN OTHERS THEN
        :status_code := 500;
        HTP.PRINT('{"error": "' || REPLACE(SQLERRM, '"', '\"') || '"}');
END;
!'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ GET /alertas/ventana-activa/:tipo_ventana creado');
END;
/

PROMPT =====================================================
PROMPT Módulo ventanas-calendario completado
PROMPT =====================================================
PROMPT Total de endpoints: 2
PROMPT - GET /alertas/ventanas-calendario
PROMPT - GET /alertas/ventana-activa/:tipo_ventana
PROMPT =====================================================
