-- Desbloquear usuario ACADEMICO
ALTER USER ACADEMICO ACCOUNT UNLOCK;

-- Verificar estado
SELECT username, account_status FROM dba_users WHERE username = 'ACADEMICO';

-- Opcional: Resetear password si es necesario
-- ALTER USER ACADEMICO IDENTIFIED BY nueva_password;

EXIT;
