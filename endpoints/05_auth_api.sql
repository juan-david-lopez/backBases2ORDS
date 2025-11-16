-- =====================================================
-- API DE AUTENTICACIÓN
-- Archivo: 05_auth_api.sql
-- Propósito: Endpoints para login y gestión de usuarios
-- Ejecutar como: ACADEMICO
-- =====================================================

SET SERVEROUTPUT ON
SET ECHO ON

PROMPT '========================================='
PROMPT 'CREANDO MÓDULO DE AUTENTICACIÓN'
PROMPT '========================================='
PROMPT ''

-- =====================================================
-- MÓDULO: AUTENTICACIÓN
-- =====================================================

BEGIN
    ORDS.DEFINE_MODULE(
        p_module_name => 'auth',
        p_base_path => 'auth/',
        p_items_per_page => 0
    );
    
    DBMS_OUTPUT.PUT_LINE('✓ Módulo auth creado');
END;
/

-- =====================================================
-- ENDPOINT: POST /auth/login
-- Autenticación de usuarios
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'auth',
        p_pattern => 'login'
    );

    ORDS.DEFINE_HANDLER(
        p_module_name => 'auth',
        p_pattern => 'login',
        p_method => 'POST',
        p_source_type => ORDS.SOURCE_TYPE_PLSQL,
        p_source => q'{
DECLARE
    v_count NUMBER;
    v_password_hash VARCHAR2(200);
    v_cod_usuario NUMBER;
    v_tipo_usuario VARCHAR2(50);
    v_cod_referencia VARCHAR2(50);
    v_nombre_completo VARCHAR2(200);
    v_intentos_fallidos NUMBER;
BEGIN
    -- Generar hash de la contraseña enviada
    v_password_hash := DBMS_CRYPTO.HASH(
        UTL_I18N.STRING_TO_RAW(:password, ''AL32UTF8''), 2
    );
    
    -- Verificar si el usuario existe y obtener datos
    BEGIN
        SELECT 
            cod_usuario,
            tipo_usuario,
            cod_referencia,
            intentos_fallidos
        INTO 
            v_cod_usuario,
            v_tipo_usuario,
            v_cod_referencia,
            v_intentos_fallidos
        FROM USUARIO_SISTEMA
        WHERE username = :email
        AND estado = ''ACTIVO'';
        
        -- Verificar si la cuenta está bloqueada
        IF v_intentos_fallidos >= 3 THEN
            :status := 423;
            :message := ''Cuenta bloqueada por múltiples intentos fallidos. Contacte al administrador.'';
            RETURN;
        END IF;
        
        -- Verificar contraseña
        SELECT COUNT(*) INTO v_count
        FROM USUARIO_SISTEMA
        WHERE username = :email
        AND password_hash = v_password_hash
        AND estado = ''ACTIVO'';
        
        IF v_count > 0 THEN
            -- Autenticación exitosa
            -- Obtener nombre del estudiante o docente
            IF v_tipo_usuario = ''ESTUDIANTE'' THEN
                SELECT primer_nombre || '' '' || primer_apellido
                INTO v_nombre_completo
                FROM ESTUDIANTE
                WHERE cod_estudiante = v_cod_referencia;
            ELSIF v_tipo_usuario = ''DOCENTE'' THEN
                SELECT primer_nombre || '' '' || primer_apellido
                INTO v_nombre_completo
                FROM DOCENTE
                WHERE cod_docente = v_cod_referencia;
            ELSE
                v_nombre_completo := ''Administrador'';
            END IF;
            
            -- Resetear intentos fallidos
            UPDATE USUARIO_SISTEMA
            SET intentos_fallidos = 0,
                ultimo_acceso = SYSTIMESTAMP
            WHERE cod_usuario = v_cod_usuario;
            
            -- Registrar acceso exitoso
            INSERT INTO LOG_ACCESO (
                cod_usuario,
                fecha_acceso,
                tipo_acceso,
                resultado,
                ip_origen
            ) VALUES (
                v_cod_usuario,
                SYSTIMESTAMP,
                ''LOGIN'',
                ''EXITOSO'',
                ''SISTEMA''
            );
            
            COMMIT;
            
            :status := 200;
            :message := ''Autenticación exitosa'';
            :token := ''Bearer_'' || v_cod_usuario || ''_'' || TO_CHAR(SYSTIMESTAMP, ''YYYYMMDDHH24MISS'');
            :role := v_tipo_usuario;
            :usuario_id := v_cod_usuario;
            :usuario_nombre := v_nombre_completo;
            :usuario_codigo := v_cod_referencia;
        ELSE
            -- Contraseña incorrecta
            UPDATE USUARIO_SISTEMA
            SET intentos_fallidos = intentos_fallidos + 1
            WHERE cod_usuario = v_cod_usuario;
            
            -- Registrar intento fallido
            INSERT INTO LOG_ACCESO (
                cod_usuario,
                fecha_acceso,
                tipo_acceso,
                resultado,
                ip_origen
            ) VALUES (
                v_cod_usuario,
                SYSTIMESTAMP,
                ''LOGIN'',
                ''FALLIDO'',
                ''SISTEMA''
            );
            
            COMMIT;
            
            :status := 401;
            :message := ''Usuario o contraseña incorrectos. Intento '' || (v_intentos_fallidos + 1) || '' de 3.'';
        END IF;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            :status := 401;
            :message := ''Usuario o contraseña incorrectos'';
    END;
    
EXCEPTION
    WHEN OTHERS THEN
        :status := 500;
        :message := ''Error en autenticación: '' || SQLERRM;
END;
        }'
    );
    
    DBMS_OUTPUT.PUT_LINE('✓ Endpoint POST /auth/login creado');
END;
/

-- =====================================================
-- ENDPOINT: PUT /auth/cambiar-password
-- Cambio de contraseña
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'auth',
        p_pattern => 'cambiar-password'
    );

    ORDS.DEFINE_HANDLER(
        p_module_name => 'auth',
        p_pattern => 'cambiar-password',
        p_method => 'PUT',
        p_source_type => ORDS.SOURCE_TYPE_PLSQL,
        p_source => q'{
DECLARE
    v_password_hash_old VARCHAR2(200);
    v_password_hash_new VARCHAR2(200);
    v_count NUMBER;
BEGIN
    -- Generar hashes
    v_password_hash_old := DBMS_CRYPTO.HASH(
        UTL_I18N.STRING_TO_RAW(:password_actual, ''AL32UTF8''), 2
    );
    v_password_hash_new := DBMS_CRYPTO.HASH(
        UTL_I18N.STRING_TO_RAW(:password_nueva, ''AL32UTF8''), 2
    );
    
    -- Verificar contraseña actual
    SELECT COUNT(*) INTO v_count
    FROM USUARIO_SISTEMA
    WHERE username = :email
    AND password_hash = v_password_hash_old
    AND estado = ''ACTIVO'';
    
    IF v_count = 0 THEN
        :status := 401;
        :message := ''Contraseña actual incorrecta'';
        RETURN;
    END IF;
    
    -- Actualizar contraseña
    UPDATE USUARIO_SISTEMA
    SET password_hash = v_password_hash_new,
        fecha_cambio_password = SYSTIMESTAMP,
        requiere_cambio_password = 0
    WHERE username = :email;
    
    COMMIT;
    
    :status := 200;
    :message := ''Contraseña actualizada correctamente'';
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        :status := 404;
        :message := ''Usuario no encontrado'';
    WHEN OTHERS THEN
        :status := 500;
        :message := ''Error al actualizar contraseña: '' || SQLERRM;
END;
        }'
    );
    
    DBMS_OUTPUT.PUT_LINE('✓ Endpoint PUT /auth/cambiar-password creado');
END;
/

-- =====================================================
-- ENDPOINT: POST /auth/logout
-- Cerrar sesión
-- =====================================================

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'auth',
        p_pattern => 'logout'
    );

    ORDS.DEFINE_HANDLER(
        p_module_name => 'auth',
        p_pattern => 'logout',
        p_method => 'POST',
        p_source_type => ORDS.SOURCE_TYPE_PLSQL,
        p_source => q'{
DECLARE
    v_cod_usuario NUMBER;
BEGIN
    -- Obtener código de usuario
    SELECT cod_usuario INTO v_cod_usuario
    FROM USUARIO_SISTEMA
    WHERE username = :email;
    
    -- Registrar logout
    INSERT INTO LOG_ACCESO (
        cod_usuario,
        fecha_acceso,
        tipo_acceso,
        resultado,
        ip_origen
    ) VALUES (
        v_cod_usuario,
        SYSTIMESTAMP,
        ''LOGOUT'',
        ''EXITOSO'',
        ''SISTEMA''
    );
    
    COMMIT;
    
    :status := 200;
    :message := ''Sesión cerrada correctamente'';
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        :status := 404;
        :message := ''Usuario no encontrado'';
    WHEN OTHERS THEN
        :status := 500;
        :message := ''Error al cerrar sesión: '' || SQLERRM;
END;
        }'
    );
    
    DBMS_OUTPUT.PUT_LINE('✓ Endpoint POST /auth/logout creado');
END;
/

PROMPT ''
PROMPT '========================================='
PROMPT 'MÓDULO DE AUTENTICACIÓN CREADO'
PROMPT '========================================='
PROMPT ''
PROMPT 'Endpoints disponibles:'
PROMPT '  POST   /ords/academico/auth/login'
PROMPT '  PUT    /ords/academico/auth/cambiar-password'
PROMPT '  POST   /ords/academico/auth/logout'
PROMPT ''
