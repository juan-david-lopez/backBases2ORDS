-- Insertar solo columnas requeridas (NOT NULL)
INSERT INTO HISTORIAL_RIESGO (cod_estudiante, cod_periodo) 
VALUES ('202500001', '2025-1');

COMMIT;
SELECT COUNT(*) FROM HISTORIAL_RIESGO;
EXIT;
