-- Idempotent script to assign DIRECTOR_TRABAJO_GRADO entries linking DOCENTE -> ESTUDIANTE
-- Usage: run in SQL*Plus / SQLcl / SQL Developer with DBMS_OUTPUT enabled
SET SERVEROUTPUT ON SIZE 1000000;

DECLARE
  v_needed NUMBER := 20;
  v_num_doc NUMBER := 0;
  v_num_est NUMBER := 0;
  v_doc DOCENTE.cod_docente%TYPE;
  v_est ESTUDIANTE.cod_estudiante%TYPE;
  v_i NUMBER := 0;
BEGIN
  -- Ensure there are some docentes
  SELECT COUNT(*) INTO v_num_doc FROM docente;
  IF v_num_doc < v_needed THEN
    DBMS_OUTPUT.PUT_LINE('Creando docentes de apoyo hasta '||v_needed);
    FOR i IN v_num_doc+1..v_needed LOOP
      BEGIN
        INSERT INTO docente (
          cod_docente, tipo_documento, num_documento, primer_nombre, segundo_nombre,
          primer_apellido, segundo_apellido, titulo_academico, nivel_formacion,
          tipo_vinculacion, correo_institucional, correo_personal, telefono, cod_facultad, estado_docente, fecha_vinculacion, fecha_registro
        ) VALUES (
          'D-AUTO'||LPAD(i,5,'0'), 'CC', '9000'||LPAD(i,4,'0'), 'DocAuto'||i, 'Segundo', 'Auto'||i, 'Ape'||i,
          'Magister','PROFESIONAL','PLANTA','docauto'||i||'@correo.com','perauto'||i||'@correo.com','3200'||LPAD(i,3,'0'),
          (SELECT cod_facultad FROM facultad WHERE ROWNUM = 1), 'ACTIVO', TRUNC(SYSDATE)-365, SYSTIMESTAMP
        );
      EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('WARN: no se pudo crear docente auto i='||i||' - '||SQLERRM);
      END;
    END LOOP;
    COMMIT;
  END IF;

  -- Ensure there are some estudiantes
  SELECT COUNT(*) INTO v_num_est FROM estudiante;
  IF v_num_est < v_needed THEN
    DBMS_OUTPUT.PUT_LINE('Creando estudiantes de apoyo hasta '||v_needed);
    FOR i IN v_num_est+1..v_needed LOOP
      BEGIN
        INSERT INTO estudiante (
          cod_estudiante, tipo_documento, num_documento, primer_nombre, segundo_nombre,
          primer_apellido, segundo_apellido, fecha_nacimiento, genero, correo_institucional,
          correo_personal, telefono, direccion, cod_programa, estado_estudiante, fecha_ingreso, fecha_registro
        ) VALUES (
          TO_CHAR(EXTRACT(YEAR FROM SYSDATE))||LPAD(1000+i,6,'0'), 'CC', '7000'||LPAD(i,4,'0'), 'EstAuto'||i, 'Segundo', 'Auto'||i, 'Ape'||i,
          DATE '2000-01-01' + i, CASE MOD(i,2) WHEN 0 THEN 'M' ELSE 'F' END, 'estauto'||i||'@correo.com', 'perauto'||i||'@correo.com', '3300'||LPAD(i,3,'0'), 'Dir Auto '||i,
          (SELECT cod_programa FROM programa_academico WHERE ROWNUM = 1), 'ACTIVO', TRUNC(SYSDATE)-365, SYSTIMESTAMP
        );
      EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('WARN: no se pudo crear estudiante auto i='||i||' - '||SQLERRM);
      END;
    END LOOP;
    COMMIT;
  END IF;

  -- Count again
  SELECT COUNT(*) INTO v_num_doc FROM docente;
  SELECT COUNT(*) INTO v_num_est FROM estudiante;

  v_i := LEAST(v_num_doc, v_num_est, v_needed);
  DBMS_OUTPUT.PUT_LINE('Asignando directores para '||v_i||' pares docente->estudiante');

  FOR idx IN 1..v_i LOOP
    BEGIN
      -- pick idx-th docente and estudiante
      SELECT cod_docente INTO v_doc FROM (
        SELECT cod_docente, ROW_NUMBER() OVER (ORDER BY cod_docente) rn FROM docente
      ) WHERE rn = idx;

      SELECT cod_estudiante INTO v_est FROM (
        SELECT cod_estudiante, ROW_NUMBER() OVER (ORDER BY cod_estudiante) rn FROM estudiante
      ) WHERE rn = idx;

      MERGE INTO director_trabajo_grado d
      USING (SELECT v_doc AS cod_docente, v_est AS cod_estudiante FROM dual) src
      ON (d.cod_docente = src.cod_docente AND d.cod_estudiante = src.cod_estudiante)
      WHEN NOT MATCHED THEN
        INSERT (cod_docente, cod_estudiante, titulo_trabajo, fecha_inicio, fecha_registro, estado_trabajo)
        VALUES (src.cod_docente, src.cod_estudiante, 'Trabajo de grado ejemplo '||idx, SYSDATE, SYSTIMESTAMP, 'EN_PROCESO');

      DBMS_OUTPUT.PUT_LINE('OK: director asignado docente='||v_doc||' estudiante='||v_est);
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR asignando director idx='||idx||' - '||SQLERRM);
        -- continue with next
    END;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('FIN: asignación de directores completada');
END;
/

-- Verificación
SELECT COUNT(*) AS total_directores FROM ACADEMICO.DIRECTOR_TRABAJO_GRADO;
COMMIT;