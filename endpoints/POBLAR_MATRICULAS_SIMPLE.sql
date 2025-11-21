-- Simple idempotent script to register MATRICULA rows
-- Usage: run this in SQL*Plus/SQLcl/SQL Developer with DBMS_OUTPUT enabled
SET SERVEROUTPUT ON SIZE 1000000;

DECLARE
  v_cod_periodo PERIODO_ACADEMICO.cod_periodo%TYPE;
  v_cnt NUMBER := 0;
  v_estudiante ESTUDIANTE.cod_estudiante%TYPE;
BEGIN
  -- Ensure there's an active period that includes today
  BEGIN
    SELECT cod_periodo INTO v_cod_periodo
    FROM periodo_academico
    WHERE estado_periodo = 'EN_CURSO'
      AND TRUNC(SYSDATE) BETWEEN fecha_inicio AND fecha_fin
    AND ROWNUM = 1;
    DBMS_OUTPUT.PUT_LINE('Usando periodo existente: '||v_cod_periodo);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('No hay periodo EN_CURSO válido; creando uno temporal');
      v_cod_periodo := TO_CHAR(EXTRACT(YEAR FROM SYSDATE))||'-1';
      INSERT INTO periodo_academico (cod_periodo, nombre_periodo, anio, periodo, fecha_inicio, fecha_fin, estado_periodo, fecha_registro)
      VALUES (v_cod_periodo, TO_CHAR(EXTRACT(YEAR FROM SYSDATE))||' Periodo Auto', EXTRACT(YEAR FROM SYSDATE), 1, TRUNC(SYSDATE)-1, TRUNC(SYSDATE)+365, 'EN_CURSO', SYSTIMESTAMP);
      COMMIT;
      DBMS_OUTPUT.PUT_LINE('Periodo creado: '||v_cod_periodo);
  END;

  -- Ensure there are students; if none, create a few minimal students
  SELECT COUNT(*) INTO v_cnt FROM estudiante;
  IF v_cnt = 0 THEN
    DBMS_OUTPUT.PUT_LINE('No hay estudiantes; creando 10 estudiantes de prueba');
    FOR i IN 1..10 LOOP
      BEGIN
        INSERT INTO estudiante (
          tipo_documento, num_documento, primer_nombre, segundo_nombre,
          primer_apellido, segundo_apellido, fecha_nacimiento, genero,
          correo_institucional, correo_personal, telefono, direccion,
          cod_programa, estado_estudiante, fecha_ingreso, fecha_registro
        ) VALUES (
          'CC','3000'||LPAD(i,3,'0'),'Est'||i,'Segundo'||i,'Prueba'||i,'Ape2_'||i,
          DATE '2000-01-01' + i,
          CASE MOD(i,2) WHEN 0 THEN 'M' ELSE 'F' END,
          'est_auto'||i||'@correo.com','pers_auto'||i||'@correo.com','3200'||LPAD(i,3,'0'),'Dir Auto '||i,
          (SELECT cod_programa FROM programa_academico WHERE ROWNUM = 1), 'ACTIVO', TRUNC(SYSDATE)-365, SYSTIMESTAMP
        );
      EXCEPTION
        WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('ERROR crear estudiante i='||i||' - '||SQLERRM);
      END;
    END LOOP;
    COMMIT;
  END IF;

  -- Insert matriculas idempotently: one per student for the selected period
  FOR i IN 1..20 LOOP
    BEGIN
      SELECT cod_estudiante INTO v_estudiante FROM (
        SELECT cod_estudiante, ROW_NUMBER() OVER (ORDER BY cod_estudiante) rn FROM estudiante
      ) WHERE rn = i;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No hay más estudiantes disponibles al i='||i||'; deteniendo');
        EXIT;
    END;

    BEGIN
      MERGE INTO matricula m
      USING (SELECT v_estudiante AS cod_estudiante, v_cod_periodo AS cod_periodo FROM dual) src
      ON (m.cod_estudiante = src.cod_estudiante AND m.cod_periodo = src.cod_periodo)
      WHEN NOT MATCHED THEN
        INSERT (cod_estudiante, cod_periodo, tipo_matricula, fecha_matricula, estado_matricula, total_creditos, valor_matricula, fecha_registro)
        VALUES (src.cod_estudiante, src.cod_periodo, 'ORDINARIA', SYSDATE, 'ACTIVA', 16, 1000000, SYSTIMESTAMP);

      DBMS_OUTPUT.PUT_LINE('OK: upsert matricula estudiante='||v_estudiante||' periodo='||v_cod_periodo);
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR upsert matricula estudiante='||v_estudiante||' - '||SQLERRM);
        -- continue
    END;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('FIN: registro de matriculas completado');
END;
/

-- Verificación rápida
SELECT COUNT(*) AS total_matriculas FROM ACADEMICO.MATRICULA;
COMMIT;