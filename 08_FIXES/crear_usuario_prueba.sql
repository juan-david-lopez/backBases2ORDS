SET SERVEROUTPUT ON

DECLARE
    v_password_hash VARCHAR2(200);
    v_email VARCHAR2(100) := 'juan.nuevo@universidad.edu';
    v_password VARCHAR2(50) := '1234567890'; -- Contraseña = num_documento
    v_cod_estudiante VARCHAR2(15) := '202500001';
BEGIN
    -- Generar hash SHA-256 de la contraseña (usando constante 2 = SHA256)
    v_password_hash := RAWTOHEX(
        DBMS_CRYPTO.HASH(
            UTL_I18N.STRING_TO_RAW(v_password, 'AL32UTF8'),
            2
        )
    );
    
    -- Insertar usuario
    INSERT INTO USUARIO_SISTEMA (
        username,
        password_hash,
        tipo_usuario,
        cod_referencia,
        correo_electronico,
        estado,
        intentos_fallidos,
        cuenta_bloqueada
    ) VALUES (
        v_email,
        v_password_hash,
        'ESTUDIANTE',
        v_cod_estudiante,
        v_email,
        'ACTIVO',
        0,
        'N'
    );
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Usuario creado exitosamente');
    DBMS_OUTPUT.PUT_LINE('Email: ' || v_email);
    DBMS_OUTPUT.PUT_LINE('Hash: ' || v_password_hash);
END;
/

-- Verificar
SELECT cod_usuario, username, tipo_usuario, cod_referencia, estado
FROM USUARIO_SISTEMA
WHERE correo_electronico = 'juan.nuevo@universidad.edu';

exit;
