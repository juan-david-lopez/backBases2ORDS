-- =====================================================
-- SISTEMA ACADEMICO - ORACLE DATABASE 19c
-- Script: sys.sql
-- Proposito: Configuracion inicial del sistema
-- DEBE EJECUTARSE COMO: SYS o SYSTEM
-- Autor: Sistema Academico
-- Fecha: 28/10/2025
-- =====================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET ECHO ON
SET TIMING ON
SET FEEDBACK ON

PROMPT '========================================='
PROMPT 'CONFIGURACION INICIAL DEL SISTEMA'
PROMPT 'Sistema Academico - Oracle Database 19c'
PROMPT '========================================='
PROMPT ''

-- =====================================================
-- VERIFICAR QUE SE EJECUTA COMO SYS O SYSTEM
-- =====================================================

PROMPT 'Verificando privilegios de usuario...'

DECLARE
    v_user VARCHAR2(30);
    v_con_name VARCHAR2(30);
BEGIN
    SELECT USER INTO v_user FROM DUAL;
    SELECT SYS_CONTEXT('USERENV', 'CON_NAME') INTO v_con_name FROM DUAL;
    
    IF v_user NOT IN ('SYS', 'SYSTEM') THEN
        RAISE_APPLICATION_ERROR(-20001, 
            'ERROR: Este script debe ejecutarse como SYS o SYSTEM' || CHR(10) ||
            'Usuario actual: ' || v_user || CHR(10) ||
            'Conectese como: sqlplus sys/password@XE as sysdba');
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('Usuario actual: ' || v_user);
    DBMS_OUTPUT.PUT_LINE('Contenedor actual: ' || v_con_name);
    DBMS_OUTPUT.PUT_LINE('Privilegios adecuados para continuar');
END;
/

PROMPT ''
PROMPT '========================================='
PROMPT 'PASO 0: CAMBIAR A PLUGGABLE DATABASE'
PROMPT '========================================='
PROMPT ''

-- Cambiar al PDB XEPDB1 (Oracle 21c XE usa arquitectura multitenant)
PROMPT 'Cambiando a la base de datos XEPDB1...'
ALTER SESSION SET CONTAINER = XEPDB1;
PROMPT 'Conectado a XEPDB1 correctamente'
PROMPT ''

PROMPT ''
PROMPT '========================================='
PROMPT 'PASO 1: ELIMINAR USUARIO EXISTENTE'
PROMPT '========================================='
PROMPT ''

-- Eliminar usuario si existe (para reinstalacion limpia)
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count 
    FROM dba_users 
    WHERE username = 'ACADEMICO';
    
    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Usuario ACADEMICO existe. Eliminando...');
        EXECUTE IMMEDIATE 'DROP USER ACADEMICO CASCADE';
        DBMS_OUTPUT.PUT_LINE('Usuario ACADEMICO eliminado correctamente');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Usuario ACADEMICO no existe. Continuando...');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ADVERTENCIA: ' || SQLERRM);
END;
/

PROMPT ''
PROMPT '========================================='
PROMPT 'PASO 2: CREAR USUARIO PROPIETARIO'
PROMPT '========================================='
PROMPT ''

-- Crear usuario propietario del sistema academico
CREATE USER ACADEMICO IDENTIFIED BY Academico123#
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON USERS;

PROMPT 'Usuario ACADEMICO creado exitosamente'
PROMPT '  - Usuario: ACADEMICO'
PROMPT '  - Password: Academico123#'
PROMPT '  - Tablespace por defecto: USERS'
PROMPT ''

PROMPT '========================================='
PROMPT 'PASO 3: OTORGAR PRIVILEGIOS BASICOS'
PROMPT '========================================='
PROMPT ''

-- Privilegios de conexion y recursos
GRANT CONNECT TO ACADEMICO;
PROMPT 'Privilegio CONNECT otorgado'

GRANT RESOURCE TO ACADEMICO;
PROMPT 'Privilegio RESOURCE otorgado'

GRANT CREATE SESSION TO ACADEMICO;
PROMPT 'Privilegio CREATE SESSION otorgado'

PROMPT ''
PROMPT '========================================='
PROMPT 'PASO 4: PRIVILEGIOS DE OBJETOS DDL'
PROMPT '========================================='
PROMPT ''

-- Privilegios para crear objetos de base de datos
GRANT CREATE TABLE TO ACADEMICO;
PROMPT 'Privilegio CREATE TABLE otorgado'

GRANT CREATE VIEW TO ACADEMICO;
PROMPT 'Privilegio CREATE VIEW otorgado'

GRANT CREATE PROCEDURE TO ACADEMICO;
PROMPT 'Privilegio CREATE PROCEDURE otorgado'

GRANT CREATE TRIGGER TO ACADEMICO;
PROMPT 'Privilegio CREATE TRIGGER otorgado'

GRANT CREATE SEQUENCE TO ACADEMICO;
PROMPT 'Privilegio CREATE SEQUENCE otorgado'

GRANT CREATE SYNONYM TO ACADEMICO;
PROMPT 'Privilegio CREATE SYNONYM otorgado'

GRANT CREATE TYPE TO ACADEMICO;
PROMPT 'Privilegio CREATE TYPE otorgado'

PROMPT ''
PROMPT '========================================='
PROMPT 'PASO 5: PRIVILEGIOS DE TABLESPACES'
PROMPT '========================================='
PROMPT ''

-- Permitir uso ilimitado de tablespace
GRANT UNLIMITED TABLESPACE TO ACADEMICO;
PROMPT 'Privilegio UNLIMITED TABLESPACE otorgado'

PROMPT ''
PROMPT '========================================='
PROMPT 'PASO 6: PRIVILEGIOS DE CONSULTA'
PROMPT '========================================='
PROMPT ''

-- Privilegios para consultar vistas del sistema
GRANT SELECT ON DBA_TABLESPACES TO ACADEMICO;
PROMPT 'Acceso a DBA_TABLESPACES otorgado'

GRANT SELECT ON DBA_DATA_FILES TO ACADEMICO;
PROMPT 'Acceso a DBA_DATA_FILES otorgado'

GRANT SELECT ON DBA_TEMP_FILES TO ACADEMICO;
PROMPT 'Acceso a DBA_TEMP_FILES otorgado'

GRANT SELECT ON DBA_ROLES TO ACADEMICO;
PROMPT 'Acceso a DBA_ROLES otorgado'

GRANT SELECT ON DBA_USERS TO ACADEMICO;
PROMPT 'Acceso a DBA_USERS otorgado'

GRANT SELECT ON DBA_OBJECTS TO ACADEMICO;
PROMPT 'Acceso a DBA_OBJECTS otorgado'

GRANT SELECT ON DBA_TAB_COLUMNS TO ACADEMICO;
PROMPT 'Acceso a DBA_TAB_COLUMNS otorgado'

GRANT SELECT ON V_ TO ACADEMICO;
PROMPT 'Acceso a V otorgado'

GRANT SELECT ON V_ TO ACADEMICO;
PROMPT 'Acceso a V otorgado'

PROMPT ''
PROMPT '========================================='
PROMPT 'PASO 7: PRIVILEGIOS PARA ROLES'
PROMPT '========================================='
PROMPT ''

-- Privilegios para crear y administrar roles
GRANT CREATE ROLE TO ACADEMICO;
PROMPT 'Privilegio CREATE ROLE otorgado'

PROMPT ''
PROMPT '========================================='
PROMPT 'PASO 8: PRIVILEGIOS ADICIONALES'
PROMPT '========================================='
PROMPT ''

-- Privilegios para depuracion y analisis
GRANT DEBUG CONNECT SESSION TO ACADEMICO;
PROMPT 'Privilegio DEBUG CONNECT SESSION otorgado'

GRANT DEBUG ANY PROCEDURE TO ACADEMICO;
PROMPT 'Privilegio DEBUG ANY PROCEDURE otorgado'

PROMPT ''
PROMPT '========================================='
PROMPT 'VERIFICACION FINAL'
PROMPT '========================================='
PROMPT ''

-- Verificar usuario creado
SELECT 
    username,
    account_status,
    default_tablespace,
    temporary_tablespace,
    created
FROM dba_users
WHERE username = 'ACADEMICO';

PROMPT ''
PROMPT 'Privilegios otorgados al usuario ACADEMICO:'

SELECT 
    privilege,
    admin_option
FROM dba_sys_privs
WHERE grantee = 'ACADEMICO'
ORDER BY privilege;

PROMPT ''
PROMPT '========================================='
PROMPT 'RESUMEN DE CONFIGURACION'
PROMPT '========================================='
PROMPT ''
PROMPT 'Usuario ACADEMICO creado exitosamente'
PROMPT 'Todos los privilegios necesarios otorgados'
PROMPT ''
PROMPT 'Credenciales de acceso:'
PROMPT '  Usuario: ACADEMICO'
PROMPT '  Password: Academico123#'
PROMPT '  SID: XE'
PROMPT ''
PROMPT 'Para conectar desde SQL*Plus:'
PROMPT '  sqlplus ACADEMICO/Academico123#@XE'
PROMPT ''
PROMPT 'Para conectar desde aplicacion:'
PROMPT '  jdbc:oracle:thin:@localhost:1521:XE'
PROMPT ''
PROMPT '========================================='
PROMPT 'SIGUIENTE PASO'
PROMPT '========================================='
PROMPT ''
PROMPT 'Ahora debe ejecutar el script maestro como usuario ACADEMICO:'
PROMPT ''
PROMPT '1. Conectar como ACADEMICO:'
PROMPT '   CONNECT ACADEMICO/Academico123#@XE'
PROMPT ''
PROMPT '2. Ejecutar instalacion completa:'
PROMPT '   @00_maestro.sql'
PROMPT ''
PROMPT 'O ejecutar todo en un solo comando:'
PROMPT '   sqlplus ACADEMICO/Academico123#@XE @00_maestro.sql'
PROMPT ''
PROMPT '========================================='

PROMPT ''
PROMPT 'Configuracion inicial completada exitosamente'
PROMPT 'Fecha: 28/10/2025'
PROMPT ''
