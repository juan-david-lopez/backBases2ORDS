-- POBLAR_CALIFICACION_SIMPLE.sql
-- Idempotent script: inserta CALIFICACION hasta tener al menos 10 filas.
SET SERVEROUTPUT ON SIZE 1000000;

DECLARE
  v_total NUMBER;
  v_needed NUMBER;
  v_cod_detalle NUMBER;
  v_cod_tipo NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_total FROM calificacion;
  DBMS_OUTPUT.PUT_LINE('CALIFICACION - registros actuales: '||v_total);
  IF v_total >= 10 THEN
    DBMS_OUTPUT.PUT_LINE('Ya hay >=10 calificaciones; nada por hacer');
    RETURN;
  END IF;

  -- asegurar al menos un tipo de actividad
  BEGIN
    SELECT cod_tipo_actividad INTO v_cod_tipo FROM tipo_actividad_evaluativa WHERE ROWNUM = 1;
  EXCEPTION WHEN NO_DATA_FOUND THEN
    INSERT INTO tipo_actividad_evaluativa (nombre_actividad, descripcion) VALUES ('PARCIAL_AUTOMATICO', 'Tipo creado por poblador') RETURNING cod_tipo_actividad INTO v_cod_tipo;
    DBMS_OUTPUT.PUT_LINE('Tipo de actividad creado: '||v_cod_tipo);
  END;

  v_needed := 10 - v_total;

  FOR r IN (
    SELECT dm.cod_detalle_matricula FROM (
      SELECT dm.cod_detalle_matricula, ROW_NUMBER() OVER (ORDER BY dm.cod_detalle_matricula) rn
      FROM detalle_matricula dm
      LEFT JOIN calificacion c ON dm.cod_detalle_matricula = c.cod_detalle_matricula
      WHERE c.cod_calificacion IS NULL
    ) WHERE rn <= v_needed
  ) LOOP
    BEGIN
      v_cod_detalle := r.cod_detalle_matricula;
      INSERT INTO calificacion (cod_detalle_matricula, cod_tipo_actividad, numero_actividad, nota, porcentaje_aplicado, fecha_calificacion, fecha_registro)
      VALUES (v_cod_detalle, v_cod_tipo, 1, ROUND(DBMS_RANDOM.VALUE(2.0,5.0) * 10)/10, 100, SYSDATE, SYSTIMESTAMP);
      DBMS_OUTPUT.PUT_LINE('Inserted CALIFICACION for detalle='||v_cod_detalle);
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('ERROR insertar CALIFICACION detalle='||v_cod_detalle||' - '||SQLERRM);
    END;
  END LOOP;

  COMMIT;
  SELECT COUNT(*) INTO v_total FROM calificacion;
  DBMS_OUTPUT.PUT_LINE('CALIFICACION - registros finales: '||v_total);
END;
/ 

-- Verificación
SELECT COUNT(*) AS total_calificaciones FROM ACADEMICO.CALIFICACION;
COMMIT;
