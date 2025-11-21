-- Idempotent script to create 20 GRUPO records (one per ASIGNATURA)
-- Run with DBMS_OUTPUT enabled
SET SERVEROUTPUT ON SIZE 1000000;

DECLARE
  v_periodo PERIODO_ACADEMICO.cod_periodo%TYPE;
  v_docente  DOCENTE.cod_docente%TYPE;
  v_cnt      NUMBER;
  v_cod_asig VARCHAR2(30);
  v_numero   NUMBER;
BEGIN
  -- Ensure a valid period exists (prefer EN_CURSO, else first available, else create one)
  BEGIN
    SELECT cod_periodo INTO v_periodo
    FROM periodo_academico
    WHERE estado_periodo = 'EN_CURSO' AND ROWNUM = 1;
    DBMS_OUTPUT.PUT_LINE('Usando periodo EN_CURSO: '||v_periodo);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      BEGIN
        SELECT cod_periodo INTO v_periodo FROM periodo_academico WHERE ROWNUM = 1;
        DBMS_OUTPUT.PUT_LINE('Usando primer periodo disponible: '||v_periodo);
      EXCEPTION WHEN NO_DATA_FOUND THEN
        -- create a fallback period
        v_periodo := TO_CHAR(EXTRACT(YEAR FROM SYSDATE))||'-1';
        INSERT INTO periodo_academico (cod_periodo, nombre_periodo, anio, periodo, fecha_inicio, fecha_fin, estado_periodo, fecha_registro)
        VALUES (v_periodo, TO_CHAR(EXTRACT(YEAR FROM SYSDATE))||' Periodo Auto', EXTRACT(YEAR FROM SYSDATE), 1, TRUNC(SYSDATE)-30, TRUNC(SYSDATE)+300, 'EN_CURSO', SYSTIMESTAMP);
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Periodo creado: '||v_periodo);
      END;
  END;

  -- Ensure at least 20 asignaturas exist; if not, warn and skip missing ones
  SELECT COUNT(*) INTO v_cnt FROM asignatura;
  IF v_cnt < 20 THEN
    DBMS_OUTPUT.PUT_LINE('Advertencia: solo '||v_cnt||' asignaturas existentes; crear asignaturas primero o ejecutar POBLAR_ASIGNATURAS_SIMPLE.sql');
  END IF;

  -- Create/merge groups for the first 20 (or fewer if asignaturas missing)
  FOR i IN 1..20 LOOP
    BEGIN
      v_numero := 1; -- you can adjust numbering per asignatura if you want multiple groups

      -- Pick the i-th asignatura by ordering to support different code formats (AS0001, ASIG00001, etc.)
      BEGIN
        SELECT cod_asignatura INTO v_cod_asig FROM (
          SELECT cod_asignatura, ROW_NUMBER() OVER (ORDER BY cod_asignatura) rn FROM asignatura
        ) WHERE rn = i;
      EXCEPTION WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Skip grupo: asignatura no existe index='||i);
        CONTINUE;
      END;

      -- Ensure a docente exists for this index; attempt to find by num_documento '2000'||i, else create
      BEGIN
        SELECT cod_docente INTO v_docente FROM docente WHERE num_documento = '2000'||i;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          BEGIN
            INSERT INTO docente (
              tipo_documento, num_documento, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, titulo_academico, nivel_formacion, tipo_vinculacion, correo_institucional, correo_personal, telefono, cod_facultad, estado_docente, fecha_vinculacion, fecha_registro
            ) VALUES (
              'CC','2000'||i,'DocGrupo'||i,'Seg'||i,'Apellido'||i,'Ape2_'||i,'Master','PROFESIONAL','PLANTA','docgrupo'||i||'@correo.com','persgrp'||i||'@correo.com','3200'||LPAD(i,3,'0'),
              (SELECT cod_facultad FROM facultad WHERE ROWNUM = 1), 'ACTIVO', TRUNC(SYSDATE)-365, SYSTIMESTAMP
            );
            COMMIT;
            SELECT cod_docente INTO v_docente FROM docente WHERE num_documento = '2000'||i;
          EXCEPTION WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('WARN: No se pudo crear docente para i='||i||' - '||SQLERRM);
            v_docente := NULL;
          END;
      END;

      -- v_cod_asig obtained above; proceed to merge group

      -- Merge group idempotently using (cod_asignatura, cod_periodo, numero_grupo) as uniqueness
      BEGIN
        MERGE INTO grupo g
        USING (SELECT v_cod_asig AS cod_asignatura, v_periodo AS cod_periodo, v_numero AS numero_grupo FROM dual) src
        ON (g.cod_asignatura = src.cod_asignatura AND g.cod_periodo = src.cod_periodo AND g.numero_grupo = src.numero_grupo)
        WHEN NOT MATCHED THEN
          INSERT (cod_asignatura, cod_periodo, numero_grupo, cod_docente, cupo_maximo, cupo_disponible, modalidad, aula, estado_grupo, fecha_registro)
          VALUES (src.cod_asignatura, src.cod_periodo, src.numero_grupo, v_docente, 30, 30, 'PRESENCIAL', 'Aula '||v_numero, 'ACTIVO', SYSTIMESTAMP);

        DBMS_OUTPUT.PUT_LINE('Upsert grupo for '||v_cod_asig||' period='||v_periodo||' num='||v_numero);
      EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR upsert grupo i='||i||' asig='||v_cod_asig||' - '||SQLERRM);
      END;

    EXCEPTION WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('No docente/asignatura found for i='||i||'; skipping');
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('ERROR outer loop grupo i='||i||' - '||SQLERRM);
    END;
  END LOOP;

  COMMIT;
  SELECT COUNT(*) INTO v_cnt FROM grupo;
  DBMS_OUTPUT.PUT_LINE('TOTAL_GRUPOS: '||v_cnt);

END;
/

-- Verification
SELECT COUNT(*) AS total_grupos FROM ACADEMICO.GRUPO;
COMMIT;
SET SERVEROUTPUT ON SIZE 1000000;
