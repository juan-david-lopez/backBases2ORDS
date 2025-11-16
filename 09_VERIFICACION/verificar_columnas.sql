SET PAGESIZE 100
SET LINESIZE 200
COLUMN column_name FORMAT A30
COLUMN data_type FORMAT A20

PROMPT === Columnas de ESTUDIANTE ===
SELECT column_name, data_type 
FROM user_tab_columns 
WHERE table_name = 'ESTUDIANTE' 
ORDER BY column_id;

PROMPT
PROMPT === Columnas de DETALLE_MATRICULA ===
SELECT column_name, data_type 
FROM user_tab_columns 
WHERE table_name = 'DETALLE_MATRICULA' 
ORDER BY column_id;

PROMPT
PROMPT === Columnas de GRUPO ===
SELECT column_name, data_type 
FROM user_tab_columns 
WHERE table_name = 'ESTUDIANTE' 
ORDER BY column_id;

PROMPT
PROMPT === Columnas de DOCENTE ===
SELECT column_name, data_type 
FROM user_tab_columns 
WHERE table_name = 'DOCENTE' 
ORDER BY column_id;

PROMPT
PROMPT === Tablas que contienen VENTANA ===
SELECT table_name 
FROM user_tables 
WHERE table_name LIKE '%VENTANA%';

EXIT;
