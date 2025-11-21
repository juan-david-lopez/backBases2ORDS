CREATE OR REPLACE PACKAGE pkg_estudiante AS
  -- Devuelve 1 si el estudiante es considerado de primer semestre en el periodo indicado, 0 en caso contrario
  FUNCTION es_primer_semestre(p_cod_estudiante IN NUMBER, p_cod_periodo IN VARCHAR2) RETURN NUMBER;
END pkg_estudiante;
/

CREATE OR REPLACE PACKAGE BODY pkg_estudiante AS

  FUNCTION es_primer_semestre(p_cod_estudiante IN NUMBER, p_cod_periodo IN VARCHAR2) RETURN NUMBER IS
    v_fecha_ingreso DATE;
    v_fecha_periodo_inicio DATE;
    v_year_ing NUMBER;
    v_year_period NUMBER;
  BEGIN
    BEGIN
      SELECT fecha_ingreso INTO v_fecha_ingreso FROM estudiante WHERE cod_estudiante = p_cod_estudiante;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      RETURN 0;
    END;

    BEGIN
      SELECT fecha_inicio INTO v_fecha_periodo_inicio FROM periodo_academico WHERE cod_periodo = p_cod_periodo;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      v_fecha_periodo_inicio := SYSDATE;
    END;

    v_year_ing := EXTRACT(YEAR FROM v_fecha_ingreso);
    v_year_period := EXTRACT(YEAR FROM v_fecha_periodo_inicio);

    IF v_year_ing = v_year_period THEN
      RETURN 1; -- primer semestre
    ELSE
      RETURN 0;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RETURN 0;
  END es_primer_semestre;

END pkg_estudiante;
/
