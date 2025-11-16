-- =====================================================
-- SCRIPT: OTORGAR PERMISOS ORDS A USUARIO ACADEMICO
-- Descripción: Otorga los privilegios necesarios para 
--              que ACADEMICO pueda crear módulos ORDS
-- Ejecutar como: SYS (con rol SYSDBA)
-- =====================================================

SET SERVEROUTPUT ON
SET ECHO ON

PROMPT '========================================='
PROMPT 'OTORGANDO PERMISOS ORDS A ACADEMICO'
PROMPT '========================================='

-- Otorgar privilegio INHERIT PRIVILEGES necesario para ORDS
GRANT INHERIT PRIVILEGES ON USER ORDS_METADATA TO ACADEMICO;

-- Verificar que el privilegio se otorgó correctamente
SELECT grantee, privilege, grantable
FROM dba_tab_privs
WHERE grantee = 'ACADEMICO'
  AND grantor = 'ORDS_METADATA';

PROMPT ''
PROMPT '✓ Privilegios ORDS otorgados exitosamente a ACADEMICO'
PROMPT ''

EXIT;
