SET LINESIZE 200
SET PAGESIZE 100
COLUMN table_name FORMAT A40

PROMPT ============================================================
PROMPT TODAS LAS TABLAS DEL ESQUEMA ACADEMICO
PROMPT ============================================================

SELECT table_name, num_rows 
FROM USER_TABLES 
ORDER BY table_name;

PROMPT 
PROMPT ============================================================
PROMPT VERIFICANDO EXISTENCIA DE TABLAS CRÍTICAS
PROMPT ============================================================

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM USER_TABLES WHERE table_name = 'PROGRAMA') 
        THEN 'SI' ELSE 'NO' 
    END AS "PROGRAMA",
    CASE 
        WHEN EXISTS (SELECT 1 FROM USER_TABLES WHERE table_name = 'SALON') 
        THEN 'SI' ELSE 'NO' 
    END AS "SALON",
    CASE 
        WHEN EXISTS (SELECT 1 FROM USER_TABLES WHERE table_name = 'HORARIO_GRUPO') 
        THEN 'SI' ELSE 'NO' 
    END AS "HORARIO_GRUPO",
    CASE 
        WHEN EXISTS (SELECT 1 FROM USER_TABLES WHERE table_name = 'HISTORIAL_ACADEMICO') 
        THEN 'SI' ELSE 'NO' 
    END AS "HISTORIAL_ACADEMICO",
    CASE 
        WHEN EXISTS (SELECT 1 FROM USER_TABLES WHERE table_name = 'REGLA_EVALUACION') 
        THEN 'SI' ELSE 'NO' 
    END AS "REGLA_EVALUACION"
FROM DUAL;

EXIT;
