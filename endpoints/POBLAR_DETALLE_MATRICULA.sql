-- Script: POBLAR_DETALLE_MATRICULA.sql
-- Propósito: poblador idempotente y defensivo para la tabla DETALLE_MATRICULA
-- Inserta hasta N filas emparejando matrículas y grupos existentes.

SET SERVEROUTPUT ON

DECLARE
  v_cod_matricula  MATRICULA.cod_matricula%TYPE;
  v_cod_grupo      GRUPO.cod_grupo%TYPE;
  v_cod_detalle    DETALLE_MATRICULA.cod_detalle_matricula%TYPE;
  v_exists         NUMBER;
  v_limit          PLS_INTEGER := 50; -- número máximo de inserciones a intentar
BEGIN
  DBMS_OUTPUT.PUT_LINE('START POBLAR_DETALLE_MATRICULA: intentando hasta '||v_limit||' inscripciones');

  FOR i IN 1..v_limit LOOP
    BEGIN
      -- obtener i-ésima matrícula y i-ésimo grupo (orden por PK)
      SELECT cod_matricula INTO v_cod_matricula FROM (
        SELECT cod_matricula, ROW_NUMBER() OVER (ORDER BY cod_matricula) rn FROM matricula
      ) WHERE rn = i;

      SELECT cod_grupo INTO v_cod_grupo FROM (
        SELECT cod_grupo, ROW_NUMBER() OVER (ORDER BY cod_grupo) rn FROM grupo
      ) WHERE rn = i;

    EXCEPTION WHEN NO_DATA_FOUND THEN
      -- no hay más matrículas o grupos suficientes; terminar el loop
      DBMS_OUTPUT.PUT_LINE('DEBUG: no hay matricula o grupo para i='||i||' - terminado');
      EXIT;
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('ERROR obtener ids i='||i||' - '||SQLERRM);
      EXIT;
    END;

    -- comprobar existencia: evitar duplicados (misma matrícula y grupo)
    BEGIN
      SELECT 1 INTO v_exists FROM DETALLE_MATRICULA dm
       WHERE dm.cod_matricula = v_cod_matricula AND dm.cod_grupo = v_cod_grupo AND NVL(dm.estado_inscripcion,'INSCRITO') <> 'RETIRADO';

      -- si llega aquí, ya existe una inscripción activa -> saltar
      DBMS_OUTPUT.PUT_LINE('SKIP: detalle ya existe para matricula='||v_cod_matricula||' grupo='||v_cod_grupo);

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- insertar detalle_matricula
        BEGIN
          INSERT INTO DETALLE_MATRICULA (cod_matricula, cod_grupo, fecha_inscripcion, estado_inscripcion, fecha_registro)
          VALUES (v_cod_matricula, v_cod_grupo, SYSDATE, 'INSCRITO', SYSTIMESTAMP)
          RETURNING cod_detalle_matricula INTO v_cod_detalle;

          DBMS_OUTPUT.PUT_LINE('INSERT: cod_detalle_matricula='||NVL(TO_CHAR(v_cod_detalle),'<NULL>')||' matricula='||v_cod_matricula||' grupo='||v_cod_grupo);

          -- opcional: insertar una nota_definitiva y una calificación de ejemplo
          BEGIN
            INSERT INTO NOTA_DEFINITIVA (cod_detalle_matricula, nota_final, resultado, fecha_calculo, fecha_registro)
            VALUES (v_cod_detalle, ROUND(DBMS_RANDOM.VALUE(2,5),2), 'APROBADO', SYSDATE, SYSTIMESTAMP);
          EXCEPTION WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('WARN: no pudo insertar NOTA_DEFINITIVA para detalle='||v_cod_detalle||' - '||SQLERRM);
          END;

          BEGIN
            INSERT INTO CALIFICACION (cod_detalle_matricula, cod_tipo_actividad, numero_actividad, nota, porcentaje_aplicado, fecha_calificacion, observaciones, fecha_registro)
            VALUES (v_cod_detalle, 1, 1, ROUND(DBMS_RANDOM.VALUE(2,5),2), 10, SYSDATE, 'Calif. ejemplo', SYSTIMESTAMP);
          EXCEPTION WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('WARN: no pudo insertar CALIFICACION para detalle='||v_cod_detalle||' - '||SQLERRM);
          END;

        EXCEPTION WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('ERROR insertar detalle i='||i||' matricula='||v_cod_matricula||' grupo='||v_cod_grupo||' - '||SQLERRM);
        END;
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR comprobar existencia i='||i||' - '||SQLERRM);
    END;

  END LOOP;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('END POBLAR_DETALLE_MATRICULA');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('FATAL POBLAR_DETALLE_MATRICULA - '||SQLERRM);
  ROLLBACK;
  RAISE;
END;
/
commit;

-- Fin POBLAR_DETALLE_MATRICULA.sql
