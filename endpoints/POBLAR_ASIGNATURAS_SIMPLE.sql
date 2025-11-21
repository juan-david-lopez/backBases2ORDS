-- Simple idempotent script to register ASIGNATURA rows
-- Usage: run this in SQL*Plus/SQLcl/SQL Developer with DBMS_OUTPUT enabled
SET SERVEROUTPUT ON SIZE 1000000;

DECLARE
  v_cod_programa PROGRAMA_ACADEMICO.cod_programa%TYPE;
  v_cod_facultad FACULTAD.cod_facultad%TYPE;
BEGIN
  -- Ensure we have a program to link asignaturas to. If none exists, attempt to use/create a faculty+program.
  BEGIN
    SELECT cod_programa INTO v_cod_programa FROM programa_academico WHERE ROWNUM = 1;
    DBMS_OUTPUT.PUT_LINE('Usando programa existente: '||NVL(TO_CHAR(v_cod_programa),'NULL'));
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('No existe programa; intentando crear uno de apoyo');
      BEGIN
        SELECT cod_facultad INTO v_cod_facultad FROM facultad WHERE ROWNUM = 1;
      EXCEPTION WHEN NO_DATA_FOUND THEN
        -- create a minimal faculty if none exists
        INSERT INTO facultad (nombre_facultad, sigla, fecha_creacion, decano_actual, estado, fecha_registro)
        VALUES ('Facultad Auto','FAU',DATE '2000-01-01','Decano Auto','ACTIVO',SYSTIMESTAMP)
        RETURNING cod_facultad INTO v_cod_facultad;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Facultad creada: '||v_cod_facultad);
      END;

      INSERT INTO programa_academico (nombre_programa, tipo_programa, nivel_formacion, cod_facultad, creditos_totales, duracion_semestres, codigo_snies, estado, fecha_registro)
      VALUES ('Programa Auto','PREGRADO','PROFESIONAL', v_cod_facultad, 160, 10, 'SN-AUTO', 'ACTIVO', SYSTIMESTAMP)
      RETURNING cod_programa INTO v_cod_programa;
      COMMIT;
      DBMS_OUTPUT.PUT_LINE('Programa de apoyo creado: '||v_cod_programa);
  END;

  -- Insert 20 asignaturas idempotentemente, choosing hours/credits consistent with trigger validation
  FOR i IN 1..20 LOOP
    DECLARE
      v_cod_asig VARCHAR2(10) := 'ASIG' || LPAD(i,5,'0');
      v_nombre VARCHAR2(150) := 'Asignatura '||i;
      v_creditos NUMBER := 3; -- for horas 3+3, creditos=3 fits validation
      v_ht NUMBER := 3;
      v_hp NUMBER := 3;
      v_tipo VARCHAR2(20) := 'OBLIGATORIA';
      v_sem NUMBER := MOD(i-1,10)+1;
    BEGIN
      MERGE INTO asignatura a
      USING (SELECT v_cod_asig AS cod_asig FROM dual) src
      ON (a.cod_asignatura = src.cod_asig)
      WHEN NOT MATCHED THEN
        INSERT (cod_asignatura, nombre_asignatura, creditos, horas_teoricas, horas_practicas, tipo_asignatura, cod_programa, semestre_sugerido, requiere_prerrequisito, estado, fecha_registro)
        VALUES (src.cod_asig, v_nombre, v_creditos, v_ht, v_hp, v_tipo, v_cod_programa, v_sem, 'N', 'ACTIVO', SYSTIMESTAMP);

      DBMS_OUTPUT.PUT_LINE('OK: upsert asignatura '||v_cod_asig||' -> '||v_nombre);
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: upsert asignatura '||v_cod_asig||' - '||SQLERRM);
        -- continue with next
    END;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('FIN: registro de asignaturas completado');
END;
/

-- Verificación rápida
SELECT COUNT(*) AS total_asignaturas FROM ACADEMICO.ASIGNATURA;
COMMIT;