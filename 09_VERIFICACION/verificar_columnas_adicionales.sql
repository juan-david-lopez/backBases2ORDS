SET PAGESIZE 100
SET LINESIZE 200
COLUMN column_name FORMAT A30
COLUMN data_type FORMAT A20

PROMPT === Columnas de PERIODO_ACADEMICO ===
SELECT column_name, data_type 
FROM user_tab_columns 
WHERE table_name = 'PERIODO_ACADEMICO' 
ORDER BY column_id;

PROMPT
PROMPT === Columnas de GRUPO (verificación adicional) ===
SELECT column_name, data_type 
FROM user_tab_columns 
WHERE table_name = 'GRUPO' 
ORDER BY column_id;

PROMPT
PROMPT === Columnas de MATRICULA ===
SELECT column_name, data_type 
FROM user_tab_columns 
WHERE table_name = 'MATRICULA' 
ORDER BY column_id;

EXIT;
