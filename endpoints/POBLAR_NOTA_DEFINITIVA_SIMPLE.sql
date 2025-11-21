-- POBLAR_NOTA_DEFINITIVA_SIMPLE.sql
-- Idempotent script: inserta NOTA_DEFINITIVA hasta tener al menos 20 filas.
SET SERVEROUTPUT ON SIZE 1000000;

DECLARE
  v_total NUMBER;
  v_needed NUMBER;
  CURSOR c_detalles(p_limit NUMBER) IS
    SELECT cod_detalle_matricula FROM (
      SELECT dm.cod_detalle_matricula, ROW_NUMBER() OVER (ORDER BY dm.cod_detalle_matricula) rn
      FROM detalle_matricula dm
      LEFT JOIN nota_definitiva nd ON dm.cod_detalle_matricula = nd.cod_detalle_matricula
      WHERE nd.cod_detalle_matricula IS NULL
    ) WHERE rn <= p_limit;
  v_cod_detalle detalle_matricula.cod_detalle_matricula%TYPE;
  v_nota NUMBER(3,1);
BEGIN
  SELECT COUNT(*) INTO v_total FROM nota_definitiva;
  DBMS_OUTPUT.PUT_LINE('NOTA_DEFINITIVA - registros actuales: '||v_total);
  IF v_total >= 20 THEN
    DBMS_OUTPUT.PUT_LINE('Ya hay >=20 notas definitivas; nada por hacer');
    RETURN;
  END IF;

  v_needed := 20 - v_total;

  FOR r IN c_detalles(v_needed) LOOP
    BEGIN
      v_cod_detalle := r.cod_detalle_matricula;
      v_nota := ROUND(DBMS_RANDOM.VALUE(2.0, 5.0) * 10) / 10; -- 1 decimal
      INSERT INTO nota_definitiva (cod_detalle_matricula, nota_final, resultado, fecha_calculo, fecha_registro)
      VALUES (v_cod_detalle, v_nota, CASE WHEN v_nota >= 3 THEN 'APROBADO' ELSE 'PERDIDA' END, SYSDATE, SYSTIMESTAMP);
      DBMS_OUTPUT.PUT_LINE('Inserted NOTA_DEFINITIVA for detalle='||v_cod_detalle||' nota='||v_nota);
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('ERROR insertar NOTA_DEFINITIVA detalle='||v_cod_detalle||' - '||SQLERRM);
    END;
  END LOOP;

  COMMIT;
  SELECT COUNT(*) INTO v_total FROM nota_definitiva;
  DBMS_OUTPUT.PUT_LINE('NOTA_DEFINITIVA - registros finales: '||v_total);
END;
/ 

-- Verificación
SELECT COUNT(*) AS total_notas FROM ACADEMICO.NOTA_DEFINITIVA;
COMMIT;
