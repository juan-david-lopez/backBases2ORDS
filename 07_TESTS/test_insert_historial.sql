-- Probar insertar en HISTORIAL_RIESGO manualmente
-- Primero verificar qué periodo existe
SELECT cod_periodo FROM PERIODO_ACADEMICO WHERE ROWNUM = 1;

-- Ver estructura completa
DESC HISTORIAL_RIESGO;

-- Intentar INSERT simple con promedio válido (0-5)
INSERT INTO HISTORIAL_RIESGO (
    cod_estudiante, cod_periodo, 
    tipo_riesgo, nivel_riesgo, promedio_periodo, 
    asignaturas_reprobadas, 
    fecha_deteccion, estado_seguimiento
) VALUES (
    '202500001', (SELECT cod_periodo FROM PERIODO_ACADEMICO WHERE ROWNUM = 1),
    'ACADEMICO', 'MEDIO', 3.5,
    1,
    SYSDATE - 10, 'PENDIENTE'
);

-- Segundo registro
INSERT INTO HISTORIAL_RIESGO (
    cod_estudiante, cod_periodo,
    tipo_riesgo, nivel_riesgo, promedio_periodo,
    asignaturas_reprobadas,
    fecha_deteccion, estado_seguimiento
) VALUES (
    '202500001', (SELECT cod_periodo FROM PERIODO_ACADEMICO WHERE ROWNUM = 1),
    'ASISTENCIA', 'ALTO', 3.0,
    2,
    SYSDATE - 5, 'PENDIENTE'
);

COMMIT;

SELECT COUNT(*) FROM HISTORIAL_RIESGO;

EXIT;
