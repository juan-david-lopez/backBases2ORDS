-- =====================================================
-- RECREAR ENDPOINT DE LOGIN (CORREGIDO)
-- =====================================================

SET SERVEROUTPUT ON

-- Eliminar handler y template existentes
BEGIN
    ORDS.DELETE_HANDLER(
        p_module_name => 'auth',
        p_pattern => 'login',
        p_method => 'POST'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Handler DELETE eliminado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('No handler to delete');
END;
/

BEGIN
    ORDS.DELETE_TEMPLATE(
        p_module_name => 'auth',
        p_pattern => 'login'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Template eliminado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('No template to delete');
END;
/

-- Recrear template
BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'auth',
        p_pattern => 'login'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Template creado');
END;
/

-- Recrear handler con código corregido y simplificado
BEGIN
    ORDS.DEFINE_HANDLER(
        p_module_name => 'auth',
        p_pattern => 'login',
        p_method => 'POST',
        p_source_type => ORDS.SOURCE_TYPE_PLSQL,
        p_source => 'DECLARE
    v_count NUMBER;
    v_password_hash VARCHAR2(200);
    v_cod_usuario NUMBER;
    v_tipo_usuario VARCHAR2(50);
    v_cod_referencia VARCHAR2(50);
    v_nombre_completo VARCHAR2(200);
    v_intentos_fallidos NUMBER;
BEGIN
    -- Generar hash SHA-256
    v_password_hash := RAWTOHEX(DBMS_CRYPTO.HASH(UTL_I18N.STRING_TO_RAW(:password, ' || q'['AL32UTF8']' || '), 2));
    
    -- Buscar usuario
    BEGIN
        SELECT cod_usuario, tipo_usuario, cod_referencia, intentos_fallidos
        INTO v_cod_usuario, v_tipo_usuario, v_cod_referencia, v_intentos_fallidos
        FROM USUARIO_SISTEMA
        WHERE username = :email
        AND estado = ' || q'['ACTIVO']' || ';
        
        -- Verificar bloqueo
        IF v_intentos_fallidos >= 3 THEN
            :status := 423;
            :message := ' || q'['Cuenta bloqueada. Contacte al administrador']' || ';
            RETURN;
        END IF;
        
        -- Verificar password
        SELECT COUNT(*) INTO v_count
        FROM USUARIO_SISTEMA
        WHERE username = :email
        AND password_hash = v_password_hash
        AND estado = ' || q'['ACTIVO']' || ';
        
        IF v_count > 0 THEN
            -- Login exitoso
            IF v_tipo_usuario = ' || q'['ESTUDIANTE']' || ' THEN
                SELECT primer_nombre || ' || q'[' ']' || ' || primer_apellido
                INTO v_nombre_completo
                FROM ESTUDIANTE
                WHERE cod_estudiante = v_cod_referencia;
            ELSIF v_tipo_usuario = ' || q'['DOCENTE']' || ' THEN
                SELECT primer_nombre || ' || q'[' ']' || ' || primer_apellido
                INTO v_nombre_completo
                FROM DOCENTE
                WHERE cod_docente = v_cod_referencia;
            ELSE
                v_nombre_completo := ' || q'['Administrador']' || ';
            END IF;
            
            -- Actualizar último acceso y resetear intentos
            UPDATE USUARIO_SISTEMA
            SET intentos_fallidos = 0, ultimo_acceso = SYSTIMESTAMP
            WHERE cod_usuario = v_cod_usuario;
            
            -- Registrar acceso exitoso
            INSERT INTO LOG_ACCESO (cod_usuario, ip_origen, resultado_acceso)
            VALUES (v_cod_usuario, ' || q'['ORDS_API']' || ', ' || q'['EXITOSO']' || ');
            
            COMMIT;
            
            :status := 200;
            :message := ' || q'['Login exitoso']' || ';
            :token := ' || q'['Bearer_']' || ' || v_cod_usuario || ' || q'['_']' || ' || TO_CHAR(SYSTIMESTAMP, ' || q'['YYYYMMDDHH24MISS']' || ');
            :role := v_tipo_usuario;
            :usuario_id := v_cod_usuario;
            :usuario_nombre := v_nombre_completo;
            :usuario_codigo := v_cod_referencia;
        ELSE
            -- Password incorrecto
            UPDATE USUARIO_SISTEMA 
            SET intentos_fallidos = intentos_fallidos + 1 
            WHERE cod_usuario = v_cod_usuario;
            
            -- Registrar intento fallido
            INSERT INTO LOG_ACCESO (cod_usuario, ip_origen, resultado_acceso, motivo_fallo)
            VALUES (v_cod_usuario, ' || q'['ORDS_API']' || ', ' || q'['FALLIDO']' || ', ' || q'['Password incorrecto']' || ');
            
            COMMIT;
            
            :status := 401;
            :message := ' || q'['Usuario o password incorrectos']' || ';
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            :status := 401;
            :message := ' || q'['Credenciales inválidas']' || ';
    END;
EXCEPTION
    WHEN OTHERS THEN
        :status := 500;
        :message := ' || q'['Error: ']' || ' || SQLERRM;
END;'
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Handler POST /auth/login actualizado exitosamente');
END;
/

PROMPT Endpoint corregido y listo para probar
exit;
