-- Trigger: marca detalle_matricula como PERDIDA cuando la nota definitiva es menor que 3.0
CREATE OR REPLACE TRIGGER trg_marcar_perdidas
AFTER INSERT OR UPDATE ON nota_definitiva
FOR EACH ROW
BEGIN
  IF :NEW.nota_final IS NOT NULL AND :NEW.nota_final < 3.0 THEN
    UPDATE detalle_matricula dm
    SET estado_inscripcion = 'PERDIDA'
    WHERE dm.cod_detalle_matricula = :NEW.cod_detalle_matricula
      AND NVL(dm.estado_inscripcion,'') <> 'PERDIDA';

    -- Registrar auditoría si PKG_AUDITORIA está disponible
    BEGIN
      PKG_AUDITORIA.registrar_auditoria('NOTA_PERDIDA', 'Marcada PERDIDA por nota_final < 3.0', :NEW.cod_detalle_matricula);
    EXCEPTION WHEN OTHERS THEN
      NULL; -- no bloquear la operación por fallos en auditoría
    END;

  ELSIF :NEW.nota_final IS NOT NULL AND :NEW.nota_final >= 3.0 THEN
    -- Reparar estado si antes estuvo marcado como PERDIDA y ahora aprueba
    UPDATE detalle_matricula dm
    SET estado_inscripcion = 'APROBADO'
    WHERE dm.cod_detalle_matricula = :NEW.cod_detalle_matricula
      AND NVL(dm.estado_inscripcion,'') <> 'APROBADO';
  END IF;
END;
/
