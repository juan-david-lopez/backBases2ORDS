-- Migración: añadir 'PERDIDA' al CHECK de la columna resultado en NOTA_DEFINITIVA
SET SERVEROUTPUT ON;
DECLARE
  v_cons_name  VARCHAR2(128);
  v_found      BOOLEAN := FALSE;
BEGIN
  -- Buscar constraints CHECK que afectan la columna RESULTADO en NOTA_DEFINITIVA
  FOR r IN (
    SELECT uc.constraint_name
    FROM user_constraints uc
    JOIN user_cons_columns ucc
      ON uc.constraint_name = ucc.constraint_name AND uc.table_name = ucc.table_name
    WHERE uc.table_name = 'NOTA_DEFINITIVA'
      AND uc.constraint_type = 'C'
      AND ucc.column_name = 'RESULTADO'
  ) LOOP
    v_found := TRUE;
    v_cons_name := r.constraint_name;
    DBMS_OUTPUT.PUT_LINE('Eliminando constraint: '||v_cons_name);
    EXECUTE IMMEDIATE 'ALTER TABLE nota_definitiva DROP CONSTRAINT "' || v_cons_name || '"';
  END LOOP;

  -- Crear nueva constraint si no existe
  BEGIN
    EXECUTE IMMEDIATE 'ALTER TABLE nota_definitiva ADD CONSTRAINT chk_nota_resultado CHECK (resultado IN (''APROBADO'',''REPROBADO'',''PERDIDA'',''PENDIENTE'',''VALIDADO''))';
    DBMS_OUTPUT.PUT_LINE('Constraint chk_nota_resultado creada/recreada aceptando PERDIDA');
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE = -2265 OR SQLCODE = -01430 THEN
      -- ya existe o conflicto de nombre; intentar crear con nombre dinámico
      BEGIN
        EXECUTE IMMEDIATE 'ALTER TABLE nota_definitiva ADD (dummy_col NUMBER)';
      EXCEPTION WHEN OTHERS THEN
        NULL;
      END;
      RAISE;
    ELSE
      RAISE;
    END IF;
  END;

  IF NOT v_found THEN
    DBMS_OUTPUT.PUT_LINE('Nota: no se encontraron CHECK constraints sobre RESULTADO; se añadió chk_nota_resultado.');
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('ERROR al modificar constraint: '||SQLERRM);
    RAISE;
END;
/
