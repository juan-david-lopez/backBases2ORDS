-- Crear credenciales de login para docente
SET SERVEROUTPUT ON

PROMPT =====================================================
PROMPT Creando usuario DOCENTE para login
PROMPT =====================================================

DECLARE
    v_password_hash RAW(2000);
    v_count NUMBER;
BEGIN
    -- Generar hash SHA256 para password123
    v_password_hash := DBMS_CRYPTO.HASH(
        UTL_I18N.STRING_TO_RAW('password123', 'AL32UTF8'), 
        2  -- HASH_SH256
    );
    
    -- Verificar si ya existe
    SELECT COUNT(*) INTO v_count
    FROM USUARIO_SISTEMA
    WHERE username = 'carlos.rodriguez@universidad.edu';
    
    IF v_count = 0 THEN
        -- Insertar nuevo usuario docente (sin cod_usuario - es IDENTITY)
        INSERT INTO USUARIO_SISTEMA (
            username, password_hash, tipo_usuario,
            cod_referencia, correo_electronico, estado, 
            intentos_fallidos, cuenta_bloqueada, fecha_creacion
        ) VALUES (
            'carlos.rodriguez@universidad.edu', v_password_hash, 'DOCENTE',
            'DOC001', 'carlos.rodriguez@universidad.edu', 'ACTIVO',
            0, 'N', SYSDATE
        );
        DBMS_OUTPUT.PUT_LINE('✓ Usuario docente DOC001 creado');
    ELSE
        -- Actualizar usuario existente
        UPDATE USUARIO_SISTEMA 
        SET password_hash = v_password_hash,
            estado = 'ACTIVO',
            cod_referencia = 'DOC001',
            tipo_usuario = 'DOCENTE',
            intentos_fallidos = 0,
            cuenta_bloqueada = 'N'
        WHERE username = 'carlos.rodriguez@universidad.edu';
        DBMS_OUTPUT.PUT_LINE('✓ Usuario docente actualizado');
    END IF;
    
    COMMIT;
END;
/

PROMPT =====================================================
PROMPT Verificando usuario creado
PROMPT =====================================================

SELECT cod_usuario, username, tipo_usuario, cod_referencia, estado
FROM USUARIO_SISTEMA
WHERE tipo_usuario = 'DOCENTE';

PROMPT =====================================================
PROMPT Credenciales docente:
PROMPT Email: carlos.rodriguez@universidad.edu
PROMPT Password: password123
PROMPT =====================================================

EXIT;
