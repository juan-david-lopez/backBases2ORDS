-- Trigger para crear un usuario automáticamente al insertar un docente
CREATE OR REPLACE TRIGGER trg_crear_usuario_docente
AFTER INSERT ON DOCENTE
FOR EACH ROW
DECLARE
    v_password_hash VARCHAR2(200);
BEGIN
    -- Generar el hash de la contraseña usando el número de documento
    v_password_hash := DBMS_CRYPTO.HASH(UTL_I18N.STRING_TO_RAW(:NEW.num_documento, 'AL32UTF8'), 2);

    -- Intentar insertar el usuario; si ya existe, evitamos error por duplicado
    BEGIN
        INSERT INTO USUARIO_SISTEMA (username, password_hash, tipo_usuario, cod_referencia, correo_electronico, estado)
        VALUES (:NEW.correo_institucional, v_password_hash, 'DOCENTE', :NEW.cod_docente, :NEW.correo_institucional, 'ACTIVO');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            NULL; -- El usuario ya existe, no hacemos nada
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error al crear usuario docente: ' || SQLERRM);
    END;
END;
/ 
