-- =====================================================
-- SISTEMA ACADÉMICO - ORACLE DATABASE 19c
-- Script: 04_secuencias.sql
-- Propósito: Creación de secuencias para claves primarias
-- Autor: Sistema Académico
-- Fecha: 28/10/2025
-- Nota: Oracle 19c soporta columnas IDENTITY, pero estas
-- secuencias permiten control manual cuando sea necesario
-- =====================================================

-- =====================================================
-- SECUENCIA: SEQ_FACULTAD
-- Justificación: Generación de códigos de facultad
-- =====================================================
CREATE SEQUENCE SEQ_FACULTAD
START WITH 1
INCREMENT BY 1
MINVALUE 1
MAXVALUE 99999
NOCYCLE
CACHE 20;

-- Secuencia para códigos de facultad

-- =====================================================
-- SECUENCIA: SEQ_PROGRAMA_ACADEMICO
-- Justificación: Generación de códigos de programas
-- =====================================================
CREATE SEQUENCE SEQ_PROGRAMA_ACADEMICO
START WITH 10000000
INCREMENT BY 1
MINVALUE 10000000
MAXVALUE 99999999
NOCYCLE
CACHE 50;

-- Secuencia para códigos de programa académico

-- =====================================================
-- SECUENCIA: SEQ_PRERREQUISITO
-- Justificación: Generación de IDs de prerrequisitos
-- =====================================================
CREATE SEQUENCE SEQ_PRERREQUISITO
START WITH 1
INCREMENT BY 1
MINVALUE 1
MAXVALUE 9999999999
NOCYCLE
CACHE 20;

-- Secuencia para IDs de prerrequisitos

-- =====================================================
-- SECUENCIA: SEQ_GRUPO
-- Justificación: Generación de códigos de grupos
-- Cache mayor por alta frecuencia de creación
-- =====================================================
CREATE SEQUENCE SEQ_GRUPO
START WITH 100000000000
INCREMENT BY 1
MINVALUE 100000000000
MAXVALUE 999999999999
NOCYCLE
CACHE 100;

-- Secuencia para códigos de grupos académicos

-- =====================================================
-- SECUENCIA: SEQ_HORARIO
-- Justificación: Generación de IDs de horarios
-- =====================================================
CREATE SEQUENCE SEQ_HORARIO
START WITH 100000000000
INCREMENT BY 1
MINVALUE 100000000000
MAXVALUE 999999999999
NOCYCLE
CACHE 100;

-- Secuencia para IDs de horarios

-- =====================================================
-- SECUENCIA: SEQ_MATRICULA
-- Justificación: Generación de códigos de matrícula
-- Alta concurrencia en periodo de matrículas
-- =====================================================
CREATE SEQUENCE SEQ_MATRICULA
START WITH 202500000001
INCREMENT BY 1
MINVALUE 202500000001
MAXVALUE 999999999999
NOCYCLE
CACHE 200;

-- Secuencia para códigos de matrícula (formato: AAAANNNNNNN)

-- =====================================================
-- SECUENCIA: SEQ_DETALLE_MATRICULA
-- Justificación: Generación de IDs de detalle de matrícula
-- Muy alta frecuencia durante matrículas
-- =====================================================
CREATE SEQUENCE SEQ_DETALLE_MATRICULA
START WITH 1000000000000000
INCREMENT BY 1
MINVALUE 1000000000000000
MAXVALUE 9999999999999999
NOCYCLE
CACHE 500;

-- Secuencia para IDs de detalle de matrícula

-- =====================================================
-- SECUENCIA: SEQ_TIPO_ACTIVIDAD
-- Justificación: Generación de códigos de tipo actividad
-- =====================================================
CREATE SEQUENCE SEQ_TIPO_ACTIVIDAD
START WITH 1
INCREMENT BY 1
MINVALUE 1
MAXVALUE 99999
NOCYCLE
CACHE 10;

-- Secuencia para tipos de actividad evaluativa

-- =====================================================
-- SECUENCIA: SEQ_REGLA_EVALUACION
-- Justificación: Generación de IDs de reglas de evaluación
-- =====================================================
CREATE SEQUENCE SEQ_REGLA_EVALUACION
START WITH 1
INCREMENT BY 1
MINVALUE 1
MAXVALUE 9999999999
NOCYCLE
CACHE 50;

-- Secuencia para reglas de evaluación

-- =====================================================
-- SECUENCIA: SEQ_CALIFICACION
-- Justificación: Generación de IDs de calificaciones
-- Altísima frecuencia durante periodo académico
-- =====================================================
CREATE SEQUENCE SEQ_CALIFICACION
START WITH 1000000000000000
INCREMENT BY 1
MINVALUE 1000000000000000
MAXVALUE 9999999999999999
NOCYCLE
CACHE 1000;

-- Secuencia para IDs de calificaciones individuales

-- =====================================================
-- SECUENCIA: SEQ_NOTA_DEFINITIVA
-- Justificación: Generación de IDs de notas definitivas
-- =====================================================
CREATE SEQUENCE SEQ_NOTA_DEFINITIVA
START WITH 1000000000000000
INCREMENT BY 1
MINVALUE 1000000000000000
MAXVALUE 9999999999999999
NOCYCLE
CACHE 500;

-- Secuencia para IDs de notas definitivas

-- =====================================================
-- SECUENCIA: SEQ_HISTORIAL_RIESGO
-- Justificación: Generación de IDs de historial de riesgo
-- =====================================================
CREATE SEQUENCE SEQ_HISTORIAL_RIESGO
START WITH 100000000000000
INCREMENT BY 1
MINVALUE 100000000000000
MAXVALUE 999999999999999
NOCYCLE
CACHE 100;

-- Secuencia para IDs de historial de riesgo académico

-- =====================================================
-- SECUENCIA: SEQ_AUDITORIA
-- Justificación: Generación de IDs de auditoría
-- Muy alta frecuencia por triggers automáticos
-- =====================================================
CREATE SEQUENCE SEQ_AUDITORIA
START WITH 1000000000000000
INCREMENT BY 1
MINVALUE 1000000000000000
MAXVALUE 9999999999999999
NOCYCLE
CACHE 2000;

-- Secuencia para IDs de registros de auditoría

-- =====================================================
-- SECUENCIA: SEQ_USUARIO_SISTEMA
-- Justificación: Generación de IDs de usuarios
-- =====================================================
CREATE SEQUENCE SEQ_USUARIO_SISTEMA
START WITH 1
INCREMENT BY 1
MINVALUE 1
MAXVALUE 9999999999
NOCYCLE
CACHE 50;

-- Secuencia para IDs de usuarios del sistema

-- =====================================================
-- SECUENCIA: SEQ_LOG_ACCESO
-- Justificación: Generación de IDs de log de acceso
-- Alta frecuencia por cada inicio de sesión
-- =====================================================
CREATE SEQUENCE SEQ_LOG_ACCESO
START WITH 1000000000000000
INCREMENT BY 1
MINVALUE 1000000000000000
MAXVALUE 9999999999999999
NOCYCLE
CACHE 1000;

-- Secuencia para IDs de log de acceso

-- =====================================================
-- SECUENCIA: SEQ_DIRECTOR_TRABAJO_GRADO
-- Justificación: Generación de IDs de dirección de trabajos
-- =====================================================
CREATE SEQUENCE SEQ_DIRECTOR_TRABAJO_GRADO
START WITH 1
INCREMENT BY 1
MINVALUE 1
MAXVALUE 9999999999
NOCYCLE
CACHE 20;

-- Secuencia para IDs de dirección de trabajos de grado

-- =====================================================
-- SECUENCIAS AUXILIARES PARA CÓDIGOS PERSONALIZADOS
-- =====================================================

-- Secuencia para códigos de estudiante (si no se usa formato predefinido)
CREATE SEQUENCE SEQ_COD_ESTUDIANTE
START WITH 202500001
INCREMENT BY 1
MINVALUE 202500001
MAXVALUE 999999999
NOCYCLE
CACHE 100;

-- Secuencia auxiliar para generación de códigos de estudiante

-- Secuencia para códigos de docente (si no se usa formato predefinido)
CREATE SEQUENCE SEQ_COD_DOCENTE
START WITH 100001
INCREMENT BY 1
MINVALUE 100001
MAXVALUE 999999
NOCYCLE
CACHE 50;

-- Secuencia auxiliar para generación de códigos de docente

-- =====================================================
-- FUNCIONES AUXILIARES PARA GENERACIÓN DE CÓDIGOS
-- =====================================================

-- Función para generar código de estudiante con formato AAAANNNNN
-- Esta función genera códigos que se reinician cada año académico
CREATE OR REPLACE FUNCTION FN_GENERAR_COD_ESTUDIANTE
RETURN VARCHAR2
IS
    v_anio VARCHAR2(4);
    v_secuencia_anual NUMBER;
    v_codigo VARCHAR2(15);
BEGIN
    -- Obtener año actual
    v_anio := TO_CHAR(SYSDATE, 'YYYY');
    
    -- Obtener el último número usado este año
    BEGIN
        SELECT NVL(MAX(TO_NUMBER(SUBSTR(cod_estudiante, 5))), 0) + 1
        INTO v_secuencia_anual
        FROM ESTUDIANTE
        WHERE SUBSTR(cod_estudiante, 1, 4) = v_anio
        AND REGEXP_LIKE(cod_estudiante, '^[0-9]+$');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_secuencia_anual := 1;
        WHEN OTHERS THEN
            v_secuencia_anual := 1;
    END;
    
    -- Generar código con formato: AAAA + 5 dígitos (ej: 202500001)
    v_codigo := v_anio || LPAD(v_secuencia_anual, 5, '0');
    RETURN v_codigo;
END;
/

-- Función para generar código de docente con formato D-NNNNNN
CREATE OR REPLACE FUNCTION FN_GENERAR_COD_DOCENTE
RETURN VARCHAR2
IS
    v_secuencia NUMBER;
    v_codigo VARCHAR2(15);
BEGIN
    v_secuencia := SEQ_COD_DOCENTE.NEXTVAL;
    v_codigo := 'D-' || LPAD(v_secuencia, 6, '0');
    RETURN v_codigo;
END;
/

-- Función para generar código de periodo académico formato AAAA-P
CREATE OR REPLACE FUNCTION FN_GENERAR_COD_PERIODO(
    p_anio IN NUMBER,
    p_periodo IN NUMBER
) RETURN VARCHAR2
IS
    v_codigo VARCHAR2(10);
BEGIN
    IF p_periodo NOT BETWEEN 1 AND 3 THEN
        RAISE_APPLICATION_ERROR(-20001, 'El periodo debe estar entre 1 y 3');
    END IF;
    
    v_codigo := TO_CHAR(p_anio) || '-' || TO_CHAR(p_periodo);
    RETURN v_codigo;
END;
/

-- =====================================================
-- VERIFICACIÓN DE SECUENCIAS CREADAS
-- =====================================================
SELECT 
    sequence_name,
    min_value,
    max_value,
    increment_by,
    cache_size,
    last_number
FROM user_sequences
WHERE sequence_name LIKE 'SEQ_%'
ORDER BY sequence_name;

-- =====================================================
-- SCRIPT DE PRUEBA DE SECUENCIAS
-- =====================================================
PROMPT '========================================='
PROMPT 'Probando secuencias creadas:'
PROMPT '========================================='

DECLARE
    v_seq_facultad NUMBER;
    v_seq_matricula NUMBER;
    v_seq_calificacion NUMBER;
    v_seq_auditoria NUMBER;
    v_cod_estudiante VARCHAR2(15);
    v_cod_docente VARCHAR2(15);
    v_cod_periodo VARCHAR2(10);
BEGIN
    -- Probar secuencias numéricas
    SELECT SEQ_FACULTAD.NEXTVAL INTO v_seq_facultad FROM DUAL;
    SELECT SEQ_MATRICULA.NEXTVAL INTO v_seq_matricula FROM DUAL;
    SELECT SEQ_CALIFICACION.NEXTVAL INTO v_seq_calificacion FROM DUAL;
    SELECT SEQ_AUDITORIA.NEXTVAL INTO v_seq_auditoria FROM DUAL;
    
    -- Probar funciones de generación de códigos
    v_cod_estudiante := FN_GENERAR_COD_ESTUDIANTE();
    v_cod_docente := FN_GENERAR_COD_DOCENTE();
    v_cod_periodo := FN_GENERAR_COD_PERIODO(2025, 1);
    
    -- Mostrar resultados
    DBMS_OUTPUT.PUT_LINE('SEQ_FACULTAD: ' || v_seq_facultad);
    DBMS_OUTPUT.PUT_LINE('SEQ_MATRICULA: ' || v_seq_matricula);
    DBMS_OUTPUT.PUT_LINE('SEQ_CALIFICACION: ' || v_seq_calificacion);
    DBMS_OUTPUT.PUT_LINE('SEQ_AUDITORIA: ' || v_seq_auditoria);
    DBMS_OUTPUT.PUT_LINE('Código Estudiante: ' || v_cod_estudiante);
    DBMS_OUTPUT.PUT_LINE('Código Docente: ' || v_cod_docente);
    DBMS_OUTPUT.PUT_LINE('Código Periodo: ' || v_cod_periodo);
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Todas las secuencias funcionan correctamente');
END;
/

PROMPT '========================================='
PROMPT 'Secuencias y funciones creadas exitosamente'
PROMPT '========================================='
