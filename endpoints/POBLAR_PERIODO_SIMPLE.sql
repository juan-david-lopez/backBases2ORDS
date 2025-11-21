-- Simple idempotent script to create PERIODO_ACADEMICO entries
-- Usage: run in SQL*Plus/SQLcl/SQL Developer with DBMS_OUTPUT enabled
SET SERVEROUTPUT ON SIZE 1000000;

DECLARE
  v_year NUMBER := EXTRACT(YEAR FROM SYSDATE);
  v_cod VARCHAR2(10);
  v_start DATE;
  v_end DATE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Inicio: crear/actualizar periodos para año '||v_year);

  -- Period 1: Primero semestre (enero - junio)
  v_cod := TO_CHAR(v_year)||'-1';
  v_start := TO_DATE(TO_CHAR(v_year)||'-01-01','YYYY-MM-DD');
  v_end   := TO_DATE(TO_CHAR(v_year)||'-06-30','YYYY-MM-DD');
  MERGE INTO periodo_academico p
  USING (SELECT v_cod AS cod_periodo FROM dual) src
  ON (p.cod_periodo = src.cod_periodo)
  WHEN MATCHED THEN
    UPDATE SET nombre_periodo = TO_CHAR(v_year)||' Primer Semestre', anio = v_year, periodo = 1, fecha_inicio = v_start, fecha_fin = v_end, estado_periodo = CASE WHEN TRUNC(SYSDATE) BETWEEN v_start AND v_end THEN 'EN_CURSO' ELSE 'PROGRAMADO' END, fecha_registro = SYSTIMESTAMP
  WHEN NOT MATCHED THEN
    INSERT (cod_periodo, nombre_periodo, anio, periodo, fecha_inicio, fecha_fin, estado_periodo, fecha_registro)
    VALUES (v_cod, TO_CHAR(v_year)||' Primer Semestre', v_year, 1, v_start, v_end, CASE WHEN TRUNC(SYSDATE) BETWEEN v_start AND v_end THEN 'EN_CURSO' ELSE 'PROGRAMADO' END, SYSTIMESTAMP);
  DBMS_OUTPUT.PUT_LINE('Upsert periodo: '||v_cod||' ['||TO_CHAR(v_start,'DD/MM/YYYY')||' - '||TO_CHAR(v_end,'DD/MM/YYYY')||']');

  -- Period 2: Segundo semestre (julio - diciembre)
  v_cod := TO_CHAR(v_year)||'-2';
  v_start := TO_DATE(TO_CHAR(v_year)||'-07-01','YYYY-MM-DD');
  v_end   := TO_DATE(TO_CHAR(v_year)||'-12-31','YYYY-MM-DD');
  MERGE INTO periodo_academico p
  USING (SELECT v_cod AS cod_periodo FROM dual) src
  ON (p.cod_periodo = src.cod_periodo)
  WHEN MATCHED THEN
    UPDATE SET nombre_periodo = TO_CHAR(v_year)||' Segundo Semestre', anio = v_year, periodo = 2, fecha_inicio = v_start, fecha_fin = v_end, estado_periodo = CASE WHEN TRUNC(SYSDATE) BETWEEN v_start AND v_end THEN 'EN_CURSO' ELSE 'PROGRAMADO' END, fecha_registro = SYSTIMESTAMP
  WHEN NOT MATCHED THEN
    INSERT (cod_periodo, nombre_periodo, anio, periodo, fecha_inicio, fecha_fin, estado_periodo, fecha_registro)
    VALUES (v_cod, TO_CHAR(v_year)||' Segundo Semestre', v_year, 2, v_start, v_end, CASE WHEN TRUNC(SYSDATE) BETWEEN v_start AND v_end THEN 'EN_CURSO' ELSE 'PROGRAMADO' END, SYSTIMESTAMP);
  DBMS_OUTPUT.PUT_LINE('Upsert periodo: '||v_cod||' ['||TO_CHAR(v_start,'DD/MM/YYYY')||' - '||TO_CHAR(v_end,'DD/MM/YYYY')||']');

  -- Period 3: Intersemestral (set a short window within the year, make it PROGRAMADO by default)
  v_cod := TO_CHAR(v_year)||'-3';
  v_start := TO_DATE(TO_CHAR(v_year)||'-03-15','YYYY-MM-DD');
  v_end   := TO_DATE(TO_CHAR(v_year)||'-03-31','YYYY-MM-DD');
  MERGE INTO periodo_academico p
  USING (SELECT v_cod AS cod_periodo FROM dual) src
  ON (p.cod_periodo = src.cod_periodo)
  WHEN MATCHED THEN
    UPDATE SET nombre_periodo = TO_CHAR(v_year)||' Intersemestral', anio = v_year, periodo = 3, fecha_inicio = v_start, fecha_fin = v_end, estado_periodo = CASE WHEN TRUNC(SYSDATE) BETWEEN v_start AND v_end THEN 'EN_CURSO' ELSE 'PROGRAMADO' END, fecha_registro = SYSTIMESTAMP
  WHEN NOT MATCHED THEN
    INSERT (cod_periodo, nombre_periodo, anio, periodo, fecha_inicio, fecha_fin, estado_periodo, fecha_registro)
    VALUES (v_cod, TO_CHAR(v_year)||' Intersemestral', v_year, 3, v_start, v_end, CASE WHEN TRUNC(SYSDATE) BETWEEN v_start AND v_end THEN 'EN_CURSO' ELSE 'PROGRAMADO' END, SYSTIMESTAMP);
  DBMS_OUTPUT.PUT_LINE('Upsert periodo: '||v_cod||' ['||TO_CHAR(v_start,'DD/MM/YYYY')||' - '||TO_CHAR(v_end,'DD/MM/YYYY')||']');

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('FIN: creación/actualización de periodos completada');
END;
/

-- Verificación rápida
SELECT cod_periodo, nombre_periodo, anio, periodo, estado_periodo, TO_CHAR(fecha_inicio,'DD/MM/YYYY') fecha_inicio, TO_CHAR(fecha_fin,'DD/MM/YYYY') fecha_fin FROM ACADEMICO.PERIODO_ACADEMICO WHERE anio = EXTRACT(YEAR FROM SYSDATE) ORDER BY periodo;
commit;