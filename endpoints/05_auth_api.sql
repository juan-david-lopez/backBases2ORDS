
SET SERVEROUTPUT ON
SET ECHO ON
DECLARE
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
    v_response_json CLOB;
    v_email VARCHAR2(200);
    v_password VARCHAR2(200);
BEGIN
    v_email := :email;
    v_password := :password;
    v_password_hash := DBMS_CRYPTO.HASH(
        UTL_I18N.STRING_TO_RAW(v_password, 'AL32UTF8'), 2
    );
    BEGIN
        SELECT cod_usuario, tipo_usuario, cod_referencia, intentos_fallidos
        INTO v_cod_usuario, v_tipo_usuario, v_cod_referencia, v_intentos_fallidos
        FROM USUARIO_SISTEMA
        WHERE username = v_email
        AND estado = 'ACTIVO';
        IF v_intentos_fallidos >= 3 THEN
            v_response_json := JSON_OBJECT(
                'success' VALUE FALSE,
                'message' VALUE 'Cuenta bloqueada por múltiples intentos fallidos. Contacte al administrador.'
            );
            OWA_UTIL.MIME_HEADER('application/json', FALSE);
            HTP.PRINT(v_response_json);
            RETURN;
        END IF;
        SELECT COUNT(*) INTO v_count
        FROM USUARIO_SISTEMA
        WHERE username = v_email
        AND password_hash = v_password_hash
        AND estado = 'ACTIVO';
        IF v_count > 0 THEN
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
            UPDATE USUARIO_SISTEMA
            SET intentos_fallidos = 0,
                ultimo_acceso = SYSTIMESTAMP
            WHERE cod_usuario = v_cod_usuario;
            INSERT INTO LOG_ACCESO (
                cod_usuario, fecha_acceso, RESULTADO_ACCESO, ip_origen
            ) VALUES (
                v_cod_usuario, SYSTIMESTAMP, 'EXITOSO', 'SISTEMA'
            );
            COMMIT;
            v_response_json := JSON_OBJECT(
                'success' VALUE TRUE,
                'message' VALUE 'Autenticación exitosa',
                'token' VALUE 'Bearer_' || v_cod_usuario || '_' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISS'),
                'role' VALUE v_tipo_usuario,
                'usuario' VALUE JSON_OBJECT(
                    'cod_usuario' VALUE v_cod_usuario,
                    'username' VALUE v_email,
                    'tipo_usuario' VALUE v_tipo_usuario,
                    'cod_referencia' VALUE v_cod_referencia,
                    'nombre_completo' VALUE v_nombre_completo
                )
            );
            OWA_UTIL.MIME_HEADER('application/json', FALSE);
            HTP.PRINT(v_response_json);
        ELSE
            UPDATE USUARIO_SISTEMA
            SET intentos_fallidos = intentos_fallidos + 1
            WHERE cod_usuario = v_cod_usuario;
            INSERT INTO LOG_ACCESO (
                cod_usuario, fecha_acceso, RESULTADO_ACCESO, ip_origen
            ) VALUES (
                v_cod_usuario, SYSTIMESTAMP, 'FALLIDO', 'SISTEMA'
            );
            COMMIT;
            OWA_UTIL.STATUS_LINE(401, 'Unauthorized');
            v_response_json := JSON_OBJECT(
                'success' VALUE FALSE,
                'message' VALUE 'Usuario o contraseña incorrectos. Intento ' || (v_intentos_fallidos + 1) || ' de 3.',
                'role' VALUE v_tipo_usuario
            );
            OWA_UTIL.MIME_HEADER('application/json', FALSE);
            HTP.PRINT(v_response_json);
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            OWA_UTIL.STATUS_LINE(401, 'Unauthorized');
            v_response_json := JSON_OBJECT(
                'success' VALUE FALSE,
                'message' VALUE 'Usuario o contraseña incorrectos',
                'role' VALUE NULL
            );
            OWA_UTIL.MIME_HEADER('application/json', FALSE);
            HTP.PRINT(v_response_json);
    END;
EXCEPTION
    WHEN OTHERS THEN
        v_response_json := JSON_OBJECT(
            'success' VALUE FALSE,
            'message' VALUE 'Error en autenticación: ' || SQLERRM,
            'role' VALUE NULL
        );
        OWA_UTIL.MIME_HEADER('application/json', FALSE);
        HTP.PRINT(v_response_json);
END;
}'
);
        DBMS_OUTPUT.PUT_LINE('ADMIN: ' || v_email || ' / claveAdm' || v_num);
    END LOOP;
    COMMIT;
END;
/ 
-- =============================================
-- FIN USUARIOS DE PRUEBA
-- =============================================
-- =============================================


PROMPT '========================================='
PROMPT 'RECREANDO MÓDULO DE AUTENTICACIÓN'
PROMPT '========================================='

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
    v_response_json CLOB;
    v_email VARCHAR2(200);
    v_password VARCHAR2(200);
BEGIN
    v_email := :email;
    v_password := :password;
    v_password_hash := DBMS_CRYPTO.HASH(
        UTL_I18N.STRING_TO_RAW(v_password, 'AL32UTF8'), 2
    );
    BEGIN
        SELECT cod_usuario, tipo_usuario, cod_referencia, intentos_fallidos
        INTO v_cod_usuario, v_tipo_usuario, v_cod_referencia, v_intentos_fallidos
        FROM USUARIO_SISTEMA
        WHERE username = v_email
        AND estado = 'ACTIVO';
        IF v_intentos_fallidos >= 3 THEN
            v_response_json := JSON_OBJECT(
                'success' VALUE FALSE,
                'message' VALUE 'Cuenta bloqueada por múltiples intentos fallidos. Contacte al administrador.'
            );
            OWA_UTIL.MIME_HEADER('application/json', FALSE);
            HTP.PRINT(v_response_json);
            RETURN;
        END IF;
        SELECT COUNT(*) INTO v_count
        FROM USUARIO_SISTEMA
        WHERE username = v_email
        AND password_hash = v_password_hash
        AND estado = 'ACTIVO';
        IF v_count > 0 THEN
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
            UPDATE USUARIO_SISTEMA
            SET intentos_fallidos = 0,
                ultimo_acceso = SYSTIMESTAMP
            WHERE cod_usuario = v_cod_usuario;
            INSERT INTO LOG_ACCESO (
                cod_usuario, fecha_acceso, RESULTADO_ACCESO, ip_origen
            ) VALUES (
                v_cod_usuario, SYSTIMESTAMP, 'EXITOSO', 'SISTEMA'
            );
            COMMIT;
            v_response_json := JSON_OBJECT(
                'success' VALUE TRUE,
                'message' VALUE 'Autenticación exitosa',
                'token' VALUE 'Bearer_' || v_cod_usuario || '_' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISS'),
                'role' VALUE v_tipo_usuario,
                'usuario' VALUE JSON_OBJECT(
                    'cod_usuario' VALUE v_cod_usuario,
                    'username' VALUE v_email,
                    'tipo_usuario' VALUE v_tipo_usuario,
                    'cod_referencia' VALUE v_cod_referencia,
                    'nombre_completo' VALUE v_nombre_completo
                )
            );
            OWA_UTIL.MIME_HEADER('application/json', FALSE);
            HTP.PRINT(v_response_json);
        ELSE
            UPDATE USUARIO_SISTEMA
            SET intentos_fallidos = intentos_fallidos + 1
            WHERE cod_usuario = v_cod_usuario;
            INSERT INTO LOG_ACCESO (
                cod_usuario, fecha_acceso, RESULTADO_ACCESO, ip_origen
            ) VALUES (
                v_cod_usuario, SYSTIMESTAMP, 'FALLIDO', 'SISTEMA'
            );
            COMMIT;
            OWA_UTIL.STATUS_LINE(401, 'Unauthorized');
            v_response_json := JSON_OBJECT(
                'success' VALUE FALSE,
                'message' VALUE 'Usuario o contraseña incorrectos. Intento ' || (v_intentos_fallidos + 1) || ' de 3.',
                'role' VALUE v_tipo_usuario
            );
            OWA_UTIL.MIME_HEADER('application/json', FALSE);
            HTP.PRINT(v_response_json);
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            OWA_UTIL.STATUS_LINE(401, 'Unauthorized');
            v_response_json := JSON_OBJECT(
                'success' VALUE FALSE,
                'message' VALUE 'Usuario o contraseña incorrectos',
                'role' VALUE NULL
            );
            OWA_UTIL.MIME_HEADER('application/json', FALSE);
            HTP.PRINT(v_response_json);
    END;
EXCEPTION
    WHEN OTHERS THEN
        v_response_json := JSON_OBJECT(
            'success' VALUE FALSE,
            'message' VALUE 'Error en autenticación: ' || SQLERRM,
            'role' VALUE NULL
        );
        OWA_UTIL.MIME_HEADER('application/json', FALSE);
        HTP.PRINT(v_response_json);
END;
}'
);
-- Repite el mismo patrón para los otros endpoints (cambiar-password, logout) si lo necesitas.

PROMPT '========================================='
PROMPT 'MÓDULO DE AUTENTICACIÓN RECREADO'
PROMPT '========================================='
PROMPT 'Endpoints disponibles:'
PROMPT '  POST   /ords/auth/login'
PROMPT ''
