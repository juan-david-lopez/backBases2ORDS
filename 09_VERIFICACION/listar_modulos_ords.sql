SET LINESIZE 200
SET PAGESIZE 100
COLUMN name FORMAT A30
COLUMN uri_prefix FORMAT A40

PROMPT ============================================================
PROMPT MÓDULOS ORDS Y SUS URIs
PROMPT ============================================================

SELECT name, uri_prefix 
FROM USER_ORDS_MODULES 
ORDER BY name;

EXIT;
