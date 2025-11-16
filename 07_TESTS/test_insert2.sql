-- Insertar con valores válidos comunes
INSERT INTO HISTORIAL_RIESGO (
    cod_estudiante, cod_periodo, 
    nivel_riesgo,
    fecha_deteccion
) VALUES (
    '202500001', '2025-1',
    'ALTO',
    SYSDATE
);

-- Segundo intento
INSERT INTO HISTORIAL_RIESGO (
    cod_estudiante, cod_periodo, 
    nivel_riesgo
) VALUES (
    '202500001', '2025-1',
    'MEDIO'
);

COMMIT;
SELECT COUNT(*) FROM HISTORIAL_RIESGO;
EXIT;
