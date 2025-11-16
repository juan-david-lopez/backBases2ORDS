SET PAGESIZE 1000
SET LINESIZE 200
COLUMN name FORMAT A25
COLUMN type FORMAT A15
COLUMN text FORMAT A80

SELECT name, type, line, position, text 
FROM user_errors 
WHERE name IN ('PKG_MATRICULA', 'PKG_RIESGO_ACADEMICO') 
ORDER BY name, type, line, position;

EXIT
