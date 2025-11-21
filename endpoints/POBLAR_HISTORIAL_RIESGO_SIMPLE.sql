-- Idempotent script to create 10 HISTORIAL_RIESGO records
-- Run with DBMS_OUTPUT enabled
SET SERVEROUTPUT ON SIZE 1000000;

DECLARE
  v_periodo PERIODO_ACADEMICO.cod_periodo%TYPE;
  v_cnt NUMBER;
  v_estudiante ESTUDIANTE.cod_estudiante%TYPE;
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

  -- Ensure at least 10 students exist
  SELECT COUNT(*) INTO v_cnt FROM estudiante;
  IF v_cnt < 10 THEN
    DBMS_OUTPUT.PUT_LINE('Menos de 10 estudiantes encontrados; creando estudiantes adicionales');
    FOR i IN v_cnt+1..10 LOOP
      BEGIN
        INSERT INTO estudiante (
          cod_estudiante, tipo_documento, num_documento, primer_nombre, primer_apellido, fecha_nacimiento, genero, correo_institucional, cod_programa, estado_estudiante, fecha_ingreso, fecha_registro
        ) VALUES (
          TO_CHAR(EXTRACT(YEAR FROM SYSDATE))||LPAD(5000+i,6,'0'), 'CC', '5000'||LPAD(i,4,'0'), 'EstRiesgo'||i, 'ApRiesgo'||i, DATE '2000-01-01'+i, 'M', 'estriesgo'||i||'@correo.com', (SELECT cod_programa FROM programa_academico WHERE ROWNUM = 1), 'ACTIVO', TRUNC(SYSDATE)-365, SYSTIMESTAMP
        );
      EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('WARN: crear estudiante adicional i='||i||' - '||SQLERRM);
      END;
    END LOOP;
    COMMIT;
  END IF;

  -- Insert 10 historial_riesgo records idempotently, one per first 10 students
  FOR i IN 1..10 LOOP
    BEGIN
      SELECT cod_estudiante INTO v_estudiante FROM (
        SELECT cod_estudiante, ROW_NUMBER() OVER (ORDER BY cod_estudiante) rn FROM estudiante
      ) WHERE rn = i;

      -- Only insert if no existing record for that student+period
      SELECT COUNT(*) INTO v_cnt FROM historial_riesgo hr WHERE hr.cod_estudiante = v_estudiante AND hr.cod_periodo = v_periodo;
      IF v_cnt = 0 THEN
        INSERT INTO historial_riesgo (
          cod_estudiante, cod_periodo, tipo_riesgo, nivel_riesgo, promedio_periodo, asignaturas_reprobadas, observaciones, fecha_deteccion, estado_seguimiento, fecha_registro
        ) VALUES (
          v_estudiante, v_periodo,
          CASE WHEN MOD(i,4)=0 THEN 'PERDIDA_CALIDAD' WHEN MOD(i,4)=1 THEN 'REPROBACION_MULTIPLE' WHEN MOD(i,4)=2 THEN 'BAJO_RENDIMIENTO' ELSE 'REINCIDENCIA' END,
          CASE WHEN i<=3 THEN 'ALTO' WHEN i<=6 THEN 'MEDIO' ELSE 'BAJO' END,
          ROUND(DBMS_RANDOM.VALUE(1.5,4.5),2),
          TRUNC(DBMS_RANDOM.VALUE(0,4)),
          'Registro de riesgo automático ejemplo '||i,
          SYSDATE, 'PENDIENTE', SYSTIMESTAMP
        );
        DBMS_OUTPUT.PUT_LINE('Inserted historial_riesgo for estudiante='||v_estudiante||' periodo='||v_periodo);
      ELSE
        DBMS_OUTPUT.PUT_LINE('Skipped existing historial_riesgo for estudiante='||v_estudiante||' periodo='||v_periodo);
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No student for index '||i||'; skipping');
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR insertar historial i='||i||' - '||SQLERRM);
    END;
  END LOOP;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('FIN: inserción de historial_riesgo completada');
END;
/

-- Verificación
SELECT COUNT(*) AS total_historial FROM ACADEMICO.HISTORIAL_RIESGO;
commit;