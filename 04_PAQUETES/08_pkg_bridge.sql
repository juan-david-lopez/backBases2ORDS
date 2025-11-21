-- Puente ORDS -> PKG_MATRICULA
-- Procedimiento: inscribir_from_json(p_body CLOB, p_status OUT NUMBER, p_response OUT CLOB)
-- Hace parsing básico del JSON recibido y delega a PKG_MATRICULA
SET SERVEROUTPUT ON
/
CREATE OR REPLACE PACKAGE PKG_ORDS_BRIDGE IS
  PROCEDURE inscribir_from_json(p_body CLOB, p_status OUT NUMBER, p_response OUT CLOB);
END PKG_ORDS_BRIDGE;
/
CREATE OR REPLACE PACKAGE BODY PKG_ORDS_BRIDGE IS

  PROCEDURE inscribir_from_json(p_body CLOB, p_status OUT NUMBER, p_response OUT CLOB) IS
    v_raw VARCHAR2(32767);
    v_cod_estudiante VARCHAR2(100);
    v_cod_grupo NUMBER;
    v_cod_periodo VARCHAR2(50);
    v_cod_matricula NUMBER;
    v_token VARCHAR2(4000);
    v_len PLS_INTEGER;
  BEGIN
    p_status := 500;
    p_response := '{"error":"Error interno"}';

    BEGIN
      v_raw := TO_CHAR(p_body);
    EXCEPTION WHEN OTHERS THEN
      v_raw := NULL;
    END;
    IF v_raw IS NULL THEN
      p_status := 400;
      p_response := '{"error":"Payload vacío"}';
      RETURN;
    END IF;

    v_len := LENGTH(v_raw);

    -- extraer cod_estudiante
    DECLARE
      p_pos PLS_INTEGER := INSTR(v_raw, '"cod_estudiante"');
      p_colon PLS_INTEGER;
      p_start PLS_INTEGER;
      p_end PLS_INTEGER;
    BEGIN
      IF p_pos > 0 THEN
        p_colon := INSTR(v_raw, ':', p_pos);
        IF p_colon > 0 THEN
          p_start := p_colon + 1;
          WHILE p_start <= v_len AND SUBSTR(v_raw, p_start, 1) IN (' ', CHR(9), CHR(10), CHR(13)) LOOP
            p_start := p_start + 1;
          END LOOP;
          IF SUBSTR(v_raw, p_start, 1) = '"' THEN
            p_start := p_start + 1;
            p_end := INSTR(v_raw, '"', p_start);
            IF p_end = 0 THEN p_end := v_len + 1; END IF;
            v_token := SUBSTR(v_raw, p_start, p_end - p_start);
          ELSE
            p_end := INSTR(v_raw, ',', p_start);
            IF p_end = 0 THEN p_end := INSTR(v_raw, '}', p_start); END IF;
            IF p_end = 0 THEN p_end := v_len + 1; END IF;
            v_token := TRIM(SUBSTR(v_raw, p_start, p_end - p_start));
          END IF;
          v_cod_estudiante := v_token;
        END IF;
      END IF;
    END;

    -- extraer cod_grupo
    DECLARE
      p_pos PLS_INTEGER := INSTR(v_raw, '"cod_grupo"');
      p_colon PLS_INTEGER;
      p_start PLS_INTEGER;
      p_end PLS_INTEGER;
    BEGIN
      IF p_pos > 0 THEN
        p_colon := INSTR(v_raw, ':', p_pos);
        IF p_colon > 0 THEN
          p_start := p_colon + 1;
          WHILE p_start <= v_len AND SUBSTR(v_raw, p_start, 1) IN (' ', CHR(9), CHR(10), CHR(13)) LOOP
            p_start := p_start + 1;
          END LOOP;
          p_end := INSTR(v_raw, ',', p_start);
          IF p_end = 0 THEN p_end := INSTR(v_raw, '}', p_start); END IF;
          IF p_end = 0 THEN p_end := v_len + 1; END IF;
          v_token := TRIM(SUBSTR(v_raw, p_start, p_end - p_start));
          v_token := REGEXP_REPLACE(v_token, '[^0-9]', '');
          IF v_token IS NOT NULL AND v_token <> '' THEN
            v_cod_grupo := TO_NUMBER(v_token);
          END IF;
        END IF;
      END IF;
    END;

    IF v_cod_estudiante IS NULL OR v_cod_grupo IS NULL THEN
      p_status := 400;
      p_response := '{"error":"Se requieren cod_estudiante y cod_grupo"}';
      RETURN;
    END IF;

    -- Obtener periodo del grupo
    BEGIN
      SELECT cod_periodo INTO v_cod_periodo FROM GRUPO WHERE cod_grupo = v_cod_grupo;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      p_status := 404;
      p_response := '{"error":"Grupo no encontrado"}';
      RETURN;
    END;

    -- Verificar/crear matrícula
    BEGIN
      SELECT cod_matricula INTO v_cod_matricula
      FROM MATRICULA
      WHERE cod_estudiante = v_cod_estudiante
        AND cod_periodo = v_cod_periodo;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      PKG_MATRICULA.crear_matricula(
        p_cod_estudiante => v_cod_estudiante,
        p_cod_periodo => v_cod_periodo,
        p_tipo_matricula => 'ORDINARIA',
        p_valor_matricula => NULL,
        p_cod_matricula => v_cod_matricula
      );
    END;

    -- Intentar inscribir y capturar errores específicos
    BEGIN
      PKG_MATRICULA.inscribir_asignatura(
        p_cod_matricula => v_cod_matricula,
        p_cod_grupo => v_cod_grupo
      );
      p_status := 201;
      p_response := JSON_OBJECT('success' VALUE TRUE, 'message' VALUE 'Inscripción exitosa', 'cod_matricula' VALUE v_cod_matricula);
      RETURN;
    EXCEPTION
      WHEN OTHERS THEN
        -- Mapear errores conocidos
        IF SQLCODE = -20206 THEN
          p_status := 403;
          p_response := '{"error":"Ventana de matrícula cerrada"}';
        ELSIF SQLCODE = -20202 THEN
          p_status := 409;
          p_response := '{"error":"No hay cupos disponibles"}';
        ELSIF SQLCODE = -20207 THEN
          p_status := 403;
          p_response := '{"error":"Excede el límite de créditos permitidos"}';
        ELSIF SQLCODE = -20203 THEN
          p_status := 400;
          p_response := '{"error":"No cumple los prerrequisitos"}';
        ELSIF SQLCODE = -20204 THEN
          p_status := 409;
          p_response := '{"error":"Conflicto de horario"}';
        ELSIF SQLCODE = -20201 THEN
          p_status := 409;
          p_response := '{"error":"Ya está inscrito en esta asignatura"}';
        ELSE
          p_status := 500;
          p_response := '{"error":"' || REPLACE(SQLERRM, '"', '\"') || '"}';
        END IF;
        RETURN;
    END;

  END inscribir_from_json;

END PKG_ORDS_BRIDGE;
/
