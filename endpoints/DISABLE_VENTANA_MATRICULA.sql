-- DISABLE_VENTANA_MATRICULA.sql
-- Desactiva la ventana de tipo 'MATRICULA' para el periodo '2025-1'

SET SERVEROUTPUT ON

PROMPT Deshabilitando ventana de MATRICULA para '2025-1'

UPDATE VENTANA_CALENDARIO
SET estado_ventana = 'INACTIVA',
    fecha_fin = LEAST(NVL(fecha_fin, SYSDATE), SYSDATE - 1),
    fecha_registro = SYSDATE
WHERE tipo_ventana = 'MATRICULA' AND cod_periodo = '2025-1';

COMMIT;

PROMPT Ventana de MATRICULA deshabilitada para '2025-1'.
