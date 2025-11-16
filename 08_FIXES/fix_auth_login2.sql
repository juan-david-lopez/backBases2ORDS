-- =====================================================
-- ENDPOINT DE LOGIN (versión con JSON directo)
-- =====================================================

SET SERVEROUTPUT ON

BEGIN
    ORDS.DEFINE_HANDLER(
        p_module_name => 'auth',
        p_pattern => 'login',
        p_method => 'POST',
        p_source_type => 'plsql/block',
        p_mimes_allowed => 'application/json',
        p_source => q'[
DECLARE
    v_count NUMBER;
    v_password_hash VARCHAR2(200);
    v_cod_usuario NUMBER;
    v_tipo_usuario VARCHAR2(50);
    v_cod_referencia VARCHAR2(50);
    v_nombre_completo VARCHAR2(200);
    v_intentos_fallidos NUMBER;
    v_response_json CLOB;
BEGIN
    -- Generar hash SHA-256
    v_password_hash := RAWTOHEX(DBMS_CRYPTO.HASH(UTL_I18N.STRING_TO_RAW(:password, 'AL32UTF8'), 2));
    
    -- Buscar usuario
    BEGIN
        SELECT cod_usuario, tipo_usuario, cod_referencia, intentos_fallidos
        INTO v_cod_usuario, v_tipo_usuario, v_cod_referencia, v_intentos_fallidos
        FROM USUARIO_SISTEMA
        WHERE username = :email
        AND estado = 'ACTIVO';
        
        -- Verificar bloqueo
        IF v_intentos_fallidos >= 3 THEN
            :status_code := 423;
            HTP.PRINT('{"success": false, "message": "Cuenta bloqueada. Contacte al administrador"}');
            RETURN;
        END IF;
        
        -- Verificar password
        SELECT COUNT(*) INTO v_count
        FROM USUARIO_SISTEMA
        WHERE username = :email
        AND password_hash = v_password_hash
        AND estado = 'ACTIVO';
        
        IF v_count > 0 THEN
            -- Login exitoso - obtener nombre
            IF v_tipo_usuario = 'ESTUDIANTE' THEN
                SELECT primer_nombre || ' ' || primer_apellido
                INTO v_nombre_completo
                FROM ESTUDIANTE
                WHERE cod_estudiante = v_cod_referencia;
            ELSIF v_tipo_usuario = 'DOCENTE' THEN
                SELECT primer_nombre || ' ' || primer_apellido
                INTO v_nombre_completo
                FROM DOCENTE
                WHERE cod_docente = v_cod_referencia;
            ELSE
                v_nombre_completo := 'Administrador';
            END IF;
            
            -- Actualizar
            UPDATE USUARIO_SISTEMA
            SET intentos_fallidos = 0, ultimo_acceso = SYSTIMESTAMP
            WHERE cod_usuario = v_cod_usuario;
            
            -- Log
            INSERT INTO LOG_ACCESO (cod_usuario, ip_origen, resultado_acceso)
            VALUES (v_cod_usuario, 'ORDS_API', 'EXITOSO');
            
            COMMIT;
            
            -- Construir respuesta JSON
            v_response_json := JSON_OBJECT(
                'success' VALUE TRUE,
                'message' VALUE 'Login exitoso',
                'token' VALUE 'Bearer_' || v_cod_usuario || '_' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISS'),
                'usuario' VALUE JSON_OBJECT(
                    'cod_usuario' VALUE v_cod_usuario,
                    'username' VALUE :email,
                    'tipo_usuario' VALUE v_tipo_usuario,
                    'cod_referencia' VALUE v_cod_referencia,
                    'nombre_completo' VALUE v_nombre_completo
                )
            );
            
            :status_code := 200;
            HTP.PRINT(v_response_json);
        ELSE
            -- Password incorrecto
            UPDATE USUARIO_SISTEMA 
            SET intentos_fallidos = intentos_fallidos + 1 
            WHERE cod_usuario = v_cod_usuario;
            
            INSERT INTO LOG_ACCESO (cod_usuario, ip_origen, resultado_acceso, motivo_fallo)
            VALUES (v_cod_usuario, 'ORDS_API', 'FALLIDO', 'Password incorrecto');
            
            COMMIT;
            
            :status_code := 401;
            HTP.PRINT('{"success": false, "message": "Usuario o password incorrectos"}');
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            :status_code := 401;
            HTP.PRINT('{"success": false, "message": "Credenciales inválidas"}');
    END;
    
EXCEPTION
    WHEN OTHERS THEN
        :status_code := 500;
        HTP.PRINT('{"success": false, "message": "Error: ' || REPLACE(SQLERRM, '"', '\"') || '"}');
END;
]'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Endpoint /auth/login actualizado con JSON directo');
END;
/

exit;
