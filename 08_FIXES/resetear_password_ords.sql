-- ============================================
-- RESETEAR PASSWORD DE ORDS_PUBLIC_USER
-- Ejecutar como SYS
-- ============================================

-- Conectar como:
-- sqlplus sys/tu_password@//localhost:1521/xepdb1 as SYSDBA

SET SERVEROUTPUT ON;

PROMPT ============================================
PROMPT VERIFICANDO ESTADO DE ORDS_PUBLIC_USER
PROMPT ============================================

SELECT 
    username,
    account_status,
    lock_date,
    expiry_date,
    created
FROM dba_users 
WHERE username = 'ORDS_PUBLIC_USER';

PROMPT
PROMPT ============================================
PROMPT DESBLOQUEANDO Y RESETEANDO PASSWORD
PROMPT ============================================

-- Desbloquear cuenta
ALTER USER ORDS_PUBLIC_USER ACCOUNT UNLOCK;
PROMPT ✅ Cuenta desbloqueada

-- Establecer nueva contraseña simple
ALTER USER ORDS_PUBLIC_USER IDENTIFIED BY Oracle123;
PROMPT ✅ Password establecido: Oracle123

-- Verificar permisos críticos
PROMPT
PROMPT ============================================
PROMPT PERMISOS DEL USUARIO
PROMPT ============================================

SELECT privilege 
FROM dba_sys_privs 
WHERE grantee = 'ORDS_PUBLIC_USER'
ORDER BY privilege;

PROMPT
PROMPT ============================================
PROMPT ROLES ASIGNADOS
PROMPT ============================================

SELECT granted_role 
FROM dba_role_privs 
WHERE grantee = 'ORDS_PUBLIC_USER';

PROMPT
PROMPT ============================================
PROMPT ✅ CONFIGURACIÓN COMPLETADA
PROMPT ============================================
PROMPT
PROMPT Usa estas credenciales en ORDS:
PROMPT   Username: ORDS_PUBLIC_USER
PROMPT   Password: Oracle123
PROMPT
PROMPT Para configurar en ORDS ejecuta:
PROMPT   .\bin\ords.exe --config .\config config set db.username ORDS_PUBLIC_USER
PROMPT   .\bin\ords.exe --config .\config config set db.password Oracle123
PROMPT
PROMPT ============================================

EXIT;
