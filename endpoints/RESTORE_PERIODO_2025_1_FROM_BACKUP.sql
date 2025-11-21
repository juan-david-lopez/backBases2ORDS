-- RESTORE_PERIODO_2025_1_FROM_BACKUP.sql
-- Restaura el registro de PERIODO_ACADEMICO para '2025-1' desde la tabla de respaldo

SET SERVEROUTPUT ON SIZE 1000000;

PROMPT Restaurando periodo '2025-1' desde respaldo (si existe)

DECLARE
  PRAGMA AUTONOMOUS_TRANSACTION;
  v_cod_periodo PERIODO_ACADEMICO.cod_periodo%TYPE := '2025-1';
  v_fecha_inicio POBLAR_PERIODOS_BACKUP.fecha_inicio%TYPE;
  v_fecha_fin POBLAR_PERIODOS_BACKUP.fecha_fin%TYPE;
  v_estado POBLAR_PERIODOS_BACKUP.estado_periodo%TYPE;
  v_cnt NUMBER;
BEGIN
  -- verificar existencia de respaldo
  SELECT COUNT(*) INTO v_cnt FROM user_tables WHERE table_name = 'POBLAR_PERIODOS_BACKUP';
  IF v_cnt = 0 THEN
    DBMS_OUTPUT.PUT_LINE('No existe tabla de respaldo; nada que restaurar');
    RETURN;
  END IF;

  BEGIN
    SELECT fecha_inicio, fecha_fin, estado_periodo INTO v_fecha_inicio, v_fecha_fin, v_estado
    FROM POBLAR_PERIODOS_BACKUP WHERE cod_periodo = v_cod_periodo;

    UPDATE periodo_academico SET fecha_inicio = v_fecha_inicio, fecha_fin = v_fecha_fin, estado_periodo = v_estado, fecha_registro = SYSTIMESTAMP
    WHERE cod_periodo = v_cod_periodo;

    DELETE FROM POBLAR_PERIODOS_BACKUP WHERE cod_periodo = v_cod_periodo;
    DBMS_OUTPUT.PUT_LINE('Periodo '||v_cod_periodo||' restaurado desde respaldo');
  EXCEPTION WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('No existe respaldo para '||v_cod_periodo||'; nada que restaurar');
  END;

  COMMIT;
END;
/
