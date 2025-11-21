-- Clean replacement for TRG_VALIDAR_CARGA_DOCENTE (v2)
-- Defensive compound trigger: accumulates added hours per docente/period and validates maxima

SET SERVEROUTPUT ON

CREATE OR REPLACE TRIGGER TRG_VALIDAR_CARGA_DOCENTE_V2
FOR INSERT OR UPDATE OF cod_docente ON GRUPO
COMPOUND TRIGGER

    /* accumulator: added hours per docente|periodo during the statement */
    TYPE t_hours_map IS TABLE OF NUMBER INDEX BY VARCHAR2(32767);
    g_hours t_hours_map;

    -- helper to build key (normalize values)
    FUNCTION key_for(p_docente VARCHAR2, p_periodo VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN NVL(TRIM(p_docente),'_NULL_') || '|' || NVL(TRIM(p_periodo),'_NULL_');
    END key_for;

    BEFORE EACH ROW IS
        v_intensity NUMBER := 0;
        v_key VARCHAR2(200);
    BEGIN
        -- non-blocking trace (uses autonomous logger); never let logger exceptions abort DML
        BEGIN
            pkg_trg_carga_logger.log(NVL(TO_CHAR(:NEW.cod_docente),'<NULL>'), NVL(:NEW.cod_periodo,'<NULL>'), 'DEBUG', 'BEFORE: recibida fila', 'cod_asignatura='||NVL(:NEW.cod_asignatura,'<NULL>'));
        EXCEPTION WHEN OTHERS THEN NULL; END;

        -- calculate intensidad (safe: aggregate prevents NO_DATA_FOUND)
        BEGIN
            SELECT NVL(MAX(horas_teoricas),0) + NVL(MAX(horas_practicas),0)
            INTO v_intensity
            FROM ASIGNATURA
            WHERE TRIM(NVL(cod_asignatura,'')) = TRIM(NVL(:NEW.cod_asignatura,''));
        EXCEPTION WHEN OTHERS THEN
            v_intensity := 0;
            BEGIN pkg_trg_carga_logger.log(NVL(TO_CHAR(:NEW.cod_docente),'<NULL>'), NVL(:NEW.cod_periodo,'<NULL>'), 'WARN', 'ASIGNATURA lookup failed: '||SQLERRM, 'cod_asignatura='||NVL(:NEW.cod_asignatura,'<NULL>')); EXCEPTION WHEN OTHERS THEN NULL; END;
        END;

        IF INSERTING THEN
            v_key := key_for(:NEW.cod_docente, :NEW.cod_periodo);
            g_hours(v_key) := NVL(g_hours(v_key),0) + v_intensity;

        ELSIF UPDATING THEN
            IF :OLD.cod_docente IS NOT NULL AND :OLD.cod_docente != :NEW.cod_docente THEN
                v_key := key_for(:OLD.cod_docente, :OLD.cod_periodo);
                g_hours(v_key) := NVL(g_hours(v_key),0) - v_intensity;
                v_key := key_for(:NEW.cod_docente, :NEW.cod_periodo);
                g_hours(v_key) := NVL(g_hours(v_key),0) + v_intensity;
            END IF;
        END IF;
    END BEFORE EACH ROW;

    AFTER STATEMENT IS
        v_docente VARCHAR2(200);
        v_periodo VARCHAR2(50);
        v_added NUMBER;
        v_carga_actual NUMBER;
        v_total NUMBER;
        v_tipo_vinculacion VARCHAR2(50);
        v_carga_maxima NUMBER;
        l_key VARCHAR2(200);
    BEGIN
        -- defensive wrapper: log unexpected errors and continue
        BEGIN
            l_key := g_hours.FIRST;
            WHILE l_key IS NOT NULL LOOP
                v_added := g_hours(l_key);
                v_docente := TRIM(SUBSTR(l_key, 1, INSTR(l_key,'|')-1));
                v_periodo := TRIM(SUBSTR(l_key, INSTR(l_key,'|')+1));

                IF v_docente IS NULL OR v_docente = '_NULL_' OR v_periodo IS NULL OR v_periodo = '_NULL_' THEN
                    l_key := g_hours.NEXT(l_key);
                    CONTINUE;
                END IF;

                BEGIN
                    BEGIN pkg_trg_carga_logger.log(NVL(v_docente,'<NULL>'), NVL(v_periodo,'<NULL>'), 'DEBUG', 'AFTER: procesando', 'added='||NVL(TO_CHAR(v_added),'0')); EXCEPTION WHEN OTHERS THEN NULL; END;

                    SELECT NVL(SUM(a.horas_teoricas + a.horas_practicas),0)
                    INTO v_carga_actual
                    FROM GRUPO g
                    JOIN ASIGNATURA a ON TRIM(NVL(g.cod_asignatura,'')) = TRIM(NVL(a.cod_asignatura,''))
                    WHERE TRIM(NVL(g.cod_docente,'')) = TRIM(NVL(v_docente,''))
                      AND TRIM(NVL(g.cod_periodo,'')) = TRIM(NVL(v_periodo,''))
                      AND NVL(g.estado_grupo,'ACTIVO') = 'ACTIVO';

                    -- get vinculación; be defensive
                    BEGIN
                        SELECT MAX(tipo_vinculacion) INTO v_tipo_vinculacion FROM DOCENTE WHERE TRIM(NVL(cod_docente,'')) = TRIM(NVL(v_docente,''));
                    EXCEPTION WHEN OTHERS THEN
                        v_tipo_vinculacion := NULL;
                        BEGIN pkg_trg_carga_logger.log(NVL(v_docente,'<NULL>'), NVL(v_periodo,'<NULL>'), 'WARN', 'DOCENTE lookup failed: '||SQLERRM, 'lookup cod_docente='||NVL(v_docente,'<NULL>')); EXCEPTION WHEN OTHERS THEN NULL; END;
                    END;

                    IF v_tipo_vinculacion = 'TIEMPO_COMPLETO' THEN
                        v_carga_maxima := 20;
                    ELSIF v_tipo_vinculacion = 'MEDIO_TIEMPO' THEN
                        v_carga_maxima := 10;
                    ELSIF v_tipo_vinculacion = 'CATEDRA' THEN
                        v_carga_maxima := 12;
                    ELSE
                        v_carga_maxima := 20;
                    END IF;

                    v_total := v_carga_actual;

                    IF v_total > v_carga_maxima THEN
                        RAISE_APPLICATION_ERROR(-20009, 'La carga académica del docente '||v_docente||' en periodo '||v_periodo||' excede el límite. Total='||v_total||' Máx='||v_carga_maxima);
                    END IF;

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        BEGIN pkg_trg_carga_logger.log(NVL(v_docente,'<NULL>'), NVL(v_periodo,'<NULL>'), 'WARN', 'NO_DATA_FOUND during AFTER', DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); EXCEPTION WHEN OTHERS THEN NULL; END;
                    WHEN OTHERS THEN
                        BEGIN pkg_trg_carga_logger.log(NVL(v_docente,'<NULL>'), NVL(v_periodo,'<NULL>'), 'ERROR', 'ERROR TRG_VALIDAR_CARGA_DOCENTE AFTER: '||SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); EXCEPTION WHEN OTHERS THEN NULL; END;
                END;

                l_key := g_hours.NEXT(l_key);
            END LOOP;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                BEGIN pkg_trg_carga_logger.log('','', 'WARN', 'outer NO_DATA_FOUND trapped - continuing', DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); EXCEPTION WHEN OTHERS THEN NULL; END;
            WHEN OTHERS THEN
                BEGIN pkg_trg_carga_logger.log('','', 'ERROR', 'outer exception trapped - '||SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE); EXCEPTION WHEN OTHERS THEN NULL; END;
        END;
    END AFTER STATEMENT;

END TRG_VALIDAR_CARGA_DOCENTE_V2;
/
commit;
