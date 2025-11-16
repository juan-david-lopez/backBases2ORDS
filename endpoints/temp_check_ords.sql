-- Verificar usuarios existentes
SET PAGESIZE 100
SELECT username FROM dba_users 
WHERE username IN ('ACADEMICO', 'ORDS_PUBLIC_USER', 'ORDS_METADATA')
ORDER BY username;

-- Verificar esquemas ORDS
SELECT owner, object_name, object_type 
FROM dba_objects 
WHERE object_name = 'ORDS' 
AND object_type = 'PACKAGE';

EXIT;
