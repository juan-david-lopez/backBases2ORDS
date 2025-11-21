-- Deploy script: registers the registro_materias module and POST /inscribir handler
-- Run this in SQLcl/SQL*Plus connected to the schema used by ORDS (where PKG_ORDS_BRIDGE and PKG_MATRICULA exist).
BEGIN
  -- Create module (idempotent if already exists)
  BEGIN
    ORDS.DEFINE_MODULE(
      p_module_name => 'registro_materias',
      p_base_path   => 'registro-materias/',
      p_items_per_page => 0
    );
  EXCEPTION WHEN OTHERS THEN
    NULL; -- ignore if already defined
  END;

  -- Create template for inscribir
  BEGIN
    ORDS.DEFINE_TEMPLATE(
      p_module_name => 'registro_materias',
      p_pattern     => 'inscribir'
    );
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  -- Define handler: call compiled procedure directly to avoid anonymous-block bind issues
  BEGIN
    ORDS.DEFINE_HANDLER(
      p_module_name => 'registro_materias',
      p_pattern     => 'inscribir',
      p_method      => 'POST',
      p_source_type => 'plsql/proc',
      p_source      => 'PKG_ORDS_BRIDGE.inscribir_simple'
    );
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  COMMIT;
END;
/

PROMPT Deployment of POST /registro-materias/inscribir complete.
