-- Script para crear entradas en USUARIO_SISTEMA para ESTUDIANTE y DOCENTE existentes
SET SERVEROUTPUT ON
PROMPT 'Iniciando poblado de usuarios existentes (ESTUDIANTE y DOCENTE)'

DECLARE
    v_password_hash VARCHAR2(200);
    v_count NUMBER;
BEGIN
    -- ESTUDIANTES
    FOR r IN (SELECT cod_estudiante, correo_institucional, num_documento FROM ESTUDIANTE) LOOP
        BEGIN
            SELECT COUNT(*) INTO v_count FROM USUARIO_SISTEMA
            WHERE cod_referencia = r.cod_estudiante AND tipo_usuario = 'ESTUDIANTE';
            IF v_count = 0 THEN
                v_password_hash := DBMS_CRYPTO.HASH(UTL_I18N.STRING_TO_RAW(r.num_documento, 'AL32UTF8'), 2);
                INSERT INTO USUARIO_SISTEMA (username, password_hash, tipo_usuario, cod_referencia, correo_electronico, estado)
                VALUES (r.correo_institucional, v_password_hash, 'ESTUDIANTE', r.cod_estudiante, r.correo_institucional, 'ACTIVO');
                DBMS_OUTPUT.PUT_LINE('Usuario creado para ESTUDIANTE: ' || r.cod_estudiante || ' -> ' || r.correo_institucional);
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error creando usuario estudiante ' || r.cod_estudiante || ': ' || SQLERRM);
        END;
    END LOOP;

    -- DOCENTES
    FOR r IN (SELECT cod_docente, correo_institucional, num_documento FROM DOCENTE) LOOP
        BEGIN
            SELECT COUNT(*) INTO v_count FROM USUARIO_SISTEMA
            WHERE cod_referencia = r.cod_docente AND tipo_usuario = 'DOCENTE';
            IF v_count = 0 THEN
                v_password_hash := DBMS_CRYPTO.HASH(UTL_I18N.STRING_TO_RAW(r.num_documento, 'AL32UTF8'), 2);
                INSERT INTO USUARIO_SISTEMA (username, password_hash, tipo_usuario, cod_referencia, correo_electronico, estado)
                VALUES (r.correo_institucional, v_password_hash, 'DOCENTE', r.cod_docente, r.correo_institucional, 'ACTIVO');
                DBMS_OUTPUT.PUT_LINE('Usuario creado para DOCENTE: ' || r.cod_docente || ' -> ' || r.correo_institucional);
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error creando usuario docente ' || r.cod_docente || ': ' || SQLERRM);
        END;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Poblado de usuarios existentes completado.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error general en poblado de usuarios: ' || SQLERRM);
        ROLLBACK;
END;
/ 
commit;