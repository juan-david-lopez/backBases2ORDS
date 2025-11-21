CREATE OR REPLACE PACKAGE PKG_ORDS_BRIDGE IS
  PROCEDURE inscribir_simple(
    p_cod_estudiante IN VARCHAR2,
    p_cod_grupo IN NUMBER,
    p_status OUT NUMBER,
    p_response OUT CLOB
  );
  -- Handler callable without ORDS binds: reads QUERY_STRING and calls inscribir_simple
  PROCEDURE ords_inscribir_handler;
END PKG_ORDS_BRIDGE;
/

CREATE OR REPLACE PACKAGE BODY PKG_ORDS_BRIDGE IS
  PROCEDURE inscribir_simple(
    p_cod_estudiante IN VARCHAR2,
    p_cod_grupo IN NUMBER,
    p_status OUT NUMBER,
    p_response OUT CLOB
  ) IS
    v_cod_matricula NUMBER;
    v_cod_periodo VARCHAR2(50);
  BEGIN
    IF p_cod_estudiante IS NULL OR p_cod_grupo IS NULL THEN
      p_status := 400;
      p_response := '{"error":"Se requieren cod_estudiante y cod_grupo"}';
      RETURN;
    END IF;

    BEGIN
      SELECT cod_periodo INTO v_cod_periodo FROM GRUPO WHERE cod_grupo = p_cod_grupo;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      p_status := 404;
      p_response := '{"error":"Grupo no encontrado"}';
      RETURN;
    END;

    BEGIN
      SELECT cod_matricula INTO v_cod_matricula
      FROM MATRICULA
      WHERE cod_estudiante = p_cod_estudiante
        AND cod_periodo = v_cod_periodo;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      PKG_MATRICULA.crear_matricula(
        p_cod_estudiante => p_cod_estudiante,
        p_cod_periodo => v_cod_periodo,
        p_tipo_matricula => 'ORDINARIA',
        p_valor_matricula => NULL,
        p_cod_matricula => v_cod_matricula
      );
    END;

    PKG_MATRICULA.inscribir_asignatura(
      p_cod_matricula => v_cod_matricula,
      p_cod_grupo => p_cod_grupo
    );

    p_status := 201;
    p_response := JSON_OBJECT('success' VALUE TRUE, 'message' VALUE 'Inscripción exitosa', 'cod_matricula' VALUE v_cod_matricula);

  EXCEPTION WHEN OTHERS THEN
    ROLLBACK;
    IF SQLCODE = -20206 THEN
      p_status := 403; p_response := '{"error":"Ventana de matrícula cerrada"}';
    ELSIF SQLCODE = -20202 THEN
      p_status := 409; p_response := '{"error":"No hay cupos disponibles"}';
    ELSIF SQLCODE = -20207 THEN
      p_status := 403; p_response := '{"error":"Excede el límite de créditos permitidos"}';
    ELSIF SQLCODE = -20203 THEN
      p_status := 400; p_response := '{"error":"No cumple los prerrequisitos"}';
    ELSIF SQLCODE = -20204 THEN
      p_status := 409; p_response := '{"error":"Conflicto de horario"}';
    ELSIF SQLCODE = -20201 THEN
      p_status := 409; p_response := '{"error":"Ya está inscrito en esta asignatura"}';
    ELSE
      p_status := 500; p_response := '{"error":"' || REPLACE(SQLERRM, '"', '\"') || '"}';
    END IF;
  END inscribir_simple;

  PROCEDURE ords_inscribir_handler IS
    v_cod_est VARCHAR2(4000) := NULL;
    v_cod_grp NUMBER := NULL;
    v_qs VARCHAR2(4000);
    v_match VARCHAR2(4000);
    v_status NUMBER;
    v_response CLOB;
  BEGIN
    BEGIN
      v_qs := OWA_UTIL.get_cgi_env('QUERY_STRING');
    EXCEPTION WHEN OTHERS THEN
      v_qs := NULL;
    END;

    IF v_qs IS NOT NULL THEN
      v_match := REGEXP_SUBSTR(v_qs, 'cod_estudiante=([^&]+)', 1, 1, 'i', 1);
      IF v_match IS NOT NULL THEN
        v_cod_est := v_match;
      END IF;
      v_match := REGEXP_SUBSTR(v_qs, 'cod_grupo=([0-9]+)', 1, 1, 'i', 1);
      IF v_match IS NOT NULL THEN
        v_cod_grp := TO_NUMBER(v_match);
      END IF;
    END IF;

    -- Call core logic
    inscribir_simple(v_cod_est, v_cod_grp, v_status, v_response);

    -- Print response
    HTP.PRINT(v_response);
  EXCEPTION WHEN OTHERS THEN
    HTP.PRINT('{"error":"' || REPLACE(SQLERRM, '"', '\"') || '"}');
  END ords_inscribir_handler;
END PKG_ORDS_BRIDGE;
/