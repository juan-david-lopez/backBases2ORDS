-- Auditoría y logger para TRG_VALIDAR_CARGA_DOCENTE
SET SERVEROUTPUT ON

-- Tabla de auditoría para registrar advertencias/errores del trigger
CREATE TABLE TRG_CARGA_AUDIT (
    cod_audit NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fecha TIMESTAMP DEFAULT SYSTIMESTAMP,
    docente VARCHAR2(50),
    periodo VARCHAR2(20),
    severidad VARCHAR2(10),
    mensaje VARCHAR2(4000),
    contexto VARCHAR2(4000)
);

-- Paquete logger con transacción autónoma
CREATE OR REPLACE PACKAGE pkg_trg_carga_logger IS
    PROCEDURE log(p_docente VARCHAR2, p_periodo VARCHAR2, p_severity VARCHAR2, p_message VARCHAR2, p_context VARCHAR2);
END pkg_trg_carga_logger;
/

CREATE OR REPLACE PACKAGE BODY pkg_trg_carga_logger IS
    PROCEDURE log(p_docente VARCHAR2, p_periodo VARCHAR2, p_severity VARCHAR2, p_message VARCHAR2, p_context VARCHAR2) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO TRG_CARGA_AUDIT(docente, periodo, severidad, mensaje, contexto)
        VALUES(p_docente, p_periodo, p_severity, SUBSTR(p_message,1,4000), SUBSTR(p_context,1,4000));
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            NULL; -- do not raise from logger
    END log;
END pkg_trg_carga_logger;
/

PROMPT 'Auditoría y logger para TRG_VALIDAR_CARGA_DOCENTE creados'
