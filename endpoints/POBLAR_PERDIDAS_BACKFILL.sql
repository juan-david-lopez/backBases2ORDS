-- Backfill idempotente: marca detalles como PERDIDA cuando nota_final < 3.0
SET SERVEROUTPUT ON;
DECLARE
  CURSOR c_perdidas IS
    SELECT cod_detalle_matricula, nota_final FROM nota_definitiva WHERE nota_final < 3.0;
  v_count PLS_INTEGER := 0;
BEGIN
  FOR r IN c_perdidas LOOP
    BEGIN
      UPDATE detalle_matricula
      SET estado_inscripcion = 'PERDIDA'
      WHERE cod_detalle_matricula = r.cod_detalle_matricula
        AND NVL(estado_inscripcion,'') <> 'PERDIDA';

      IF SQL%ROWCOUNT > 0 THEN
        v_count := v_count + 1;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('ERROR backfill cod_detalle='||r.cod_detalle_matricula||' - '||SQLERRM);
    END;
  END LOOP;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('POBLAR_PERDIDAS_BACKFILL: filas actualizadas='||v_count);
END;
/ 
