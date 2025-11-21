-- ENABLE_2025_2_PERIOD_AND_WINDOW_FOR_TEST.sql
-- Crea o actualiza el periodo '2025-2' y la ventana de MATRICULA asociada
-- Fecha límite de prueba: 21/11/2025 (pasado mañana según petición)

SET SERVEROUTPUT ON

PROMPT Habilitando periodo '2025-2' y ventana MATRICULA hasta 21/11/2025

DECLARE
  v_periodo VARCHAR2(10) := '2025-2';
  v_fin DATE := TO_DATE('23/11/2025','DD/MM/YYYY');
BEGIN
  -- Asegurar periodo: fecha_inicio = ayer, fecha_fin = 23/11/2025, estado = 'PROGRAMADO'
  MERGE INTO PERIODO_ACADEMICO p
  USING (SELECT v_periodo cod_periodo FROM dual) src
  ON (p.cod_periodo = src.cod_periodo)
  WHEN MATCHED THEN
    UPDATE SET p.fecha_inicio = LEAST(NVL(p.fecha_inicio, TRUNC(SYSDATE)-1), TRUNC(SYSDATE)-1),
               p.fecha_fin = GREATEST(NVL(p.fecha_fin, v_fin), v_fin),
               p.estado_periodo = 'PROGRAMADO',
               p.fecha_registro = SYSTIMESTAMP
  WHEN NOT MATCHED THEN
    INSERT (cod_periodo, nombre_periodo, anio, periodo, fecha_inicio, fecha_fin, estado_periodo, fecha_registro)
    VALUES (v_periodo, 'Periodo Auto 2025-2', 2025, 2, TRUNC(SYSDATE)-1, v_fin, 'PROGRAMADO', SYSTIMESTAMP);

  COMMIT;

  -- Crear/actualizar ventana de MATRICULA para 2025-2, inicio = hoy-1, fin = v_fin (23/11/2025)
  MERGE INTO VENTANA_CALENDARIO vc
  USING (SELECT 'MATRICULA' tipo_ventana, v_periodo cod_periodo FROM dual) src
  ON (vc.tipo_ventana = src.tipo_ventana AND vc.cod_periodo = src.cod_periodo)
  WHEN MATCHED THEN
    UPDATE SET vc.nombre_ventana = 'Inscripción 2025-2 - PRUEBAS',
               vc.descripcion = 'Ventana temporal creada para pruebas hasta 21/11/2025',
               vc.fecha_inicio = TRUNC(SYSDATE)-1,
               vc.fecha_fin = v_fin,
               vc.estado_ventana = 'ACTIVA',
               vc.fecha_registro = SYSTIMESTAMP
  WHEN NOT MATCHED THEN
    INSERT (cod_ventana_calendario, cod_periodo, tipo_ventana, nombre_ventana, descripcion, fecha_inicio, fecha_fin, estado_ventana, fecha_registro)
    VALUES ((SELECT NVL(MAX(cod_ventana_calendario),0)+1 FROM VENTANA_CALENDARIO), v_periodo, 'MATRICULA', 'Inscripción 2025-2 - PRUEBAS', 'Ventana temporal creada para pruebas hasta 21/11/2025', TRUNC(SYSDATE)-1, v_fin, 'ACTIVA', SYSTIMESTAMP);

  COMMIT;

  DBMS_OUTPUT.PUT_LINE('Periodo '||v_periodo||' y ventana MATRICULA habilitados hasta '||TO_CHAR(v_fin,'DD/MM/YYYY'));
END;
/

-- Verificación rápida
SELECT cod_periodo, estado_periodo, TO_CHAR(fecha_inicio,'DD/MM/YYYY') fecha_inicio, TO_CHAR(fecha_fin,'DD/MM/YYYY') fecha_fin
FROM PERIODO_ACADEMICO WHERE cod_periodo = '2025-2';

SELECT cod_ventana_calendario, cod_periodo, tipo_ventana, estado_ventana, TO_CHAR(fecha_inicio,'DD/MM/YYYY') fecha_inicio, TO_CHAR(fecha_fin,'DD/MM/YYYY') fecha_fin
FROM VENTANA_CALENDARIO WHERE cod_periodo = '2025-2' AND tipo_ventana = 'MATRICULA';
