-- =====================================================
-- COMPLETAR ESQUEMA Y DATOS PARA 100% FUNCIONALIDAD
-- =====================================================

SET SERVEROUTPUT ON

PROMPT =====================================================
PROMPT 1. Creando tabla VENTANA_CALENDARIO
PROMPT =====================================================

CREATE TABLE VENTANA_CALENDARIO (
    cod_ventana_calendario NUMBER PRIMARY KEY,
    cod_periodo VARCHAR2(20) NOT NULL,
    tipo_ventana VARCHAR2(50) NOT NULL,
    nombre_ventana VARCHAR2(100) NOT NULL,
    descripcion VARCHAR2(500),
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    estado_ventana VARCHAR2(20) DEFAULT 'ACTIVA',
    fecha_registro DATE DEFAULT SYSDATE,
    CONSTRAINT fk_ventana_periodo FOREIGN KEY (cod_periodo) 
        REFERENCES PERIODO_ACADEMICO(cod_periodo)
);

PROMPT ✓ Tabla VENTANA_CALENDARIO creada

PROMPT =====================================================
PROMPT 2. Insertando datos de prueba
PROMPT =====================================================

-- Datos para HISTORIAL_RIESGO (sin cod_historial_riesgo porque es IDENTITY)
INSERT INTO HISTORIAL_RIESGO (
    cod_estudiante, cod_periodo, 
    tipo_riesgo, nivel_riesgo, promedio_periodo, 
    asignaturas_reprobadas, observaciones, 
    fecha_deteccion, estado_seguimiento
) VALUES (
    '202500001', '2025-1',
    'ACADEMICO', 'MEDIO', 2.8,
    1, 'Estudiante con promedio bajo en matemáticas',
    SYSDATE - 10, 'PENDIENTE'
);

INSERT INTO HISTORIAL_RIESGO (
    cod_estudiante, cod_periodo,
    tipo_riesgo, nivel_riesgo, promedio_periodo,
    asignaturas_reprobadas, observaciones,
    fecha_deteccion, estado_seguimiento
) VALUES (
    '202500001', '2025-1',
    'ASISTENCIA', 'ALTO', 2.5,
    2, 'Múltiples faltas sin justificar',
    SYSDATE - 5, 'PENDIENTE'
);

PROMPT ✓ Datos insertados en HISTORIAL_RIESGO

-- Datos para VENTANA_CALENDARIO
INSERT INTO VENTANA_CALENDARIO (
    cod_ventana_calendario, cod_periodo, tipo_ventana,
    nombre_ventana, descripcion, fecha_inicio, fecha_fin,
    estado_ventana
) VALUES (
    1, '2025-1', 'MATRICULA',
    'Inscripción de Asignaturas', 
    'Periodo de inscripción ordinaria de asignaturas',
    SYSDATE - 5, SYSDATE + 30,
    'ACTIVA'
);

INSERT INTO VENTANA_CALENDARIO (
    cod_ventana_calendario, cod_periodo, tipo_ventana,
    nombre_ventana, descripcion, fecha_inicio, fecha_fin,
    estado_ventana
) VALUES (
    2, '2025-1', 'RETIRO',
    'Retiro de Asignaturas',
    'Periodo para retirar asignaturas sin penalización',
    SYSDATE + 10, SYSDATE + 45,
    'ACTIVA'
);

INSERT INTO VENTANA_CALENDARIO (
    cod_ventana_calendario, cod_periodo, tipo_ventana,
    nombre_ventana, descripcion, fecha_inicio, fecha_fin,
    estado_ventana
) VALUES (
    3, '2025-1', 'EVALUACION',
    'Registro de Notas Finales',
    'Periodo para que docentes registren calificaciones finales',
    SYSDATE + 80, SYSDATE + 95,
    'ACTIVA'
);

PROMPT ✓ Datos insertados en VENTANA_CALENDARIO

COMMIT;

PROMPT =====================================================
PROMPT 3. Verificando datos insertados
PROMPT =====================================================

SELECT 'HISTORIAL_RIESGO' as tabla, COUNT(*) as registros FROM HISTORIAL_RIESGO;
SELECT 'VENTANA_CALENDARIO' as tabla, COUNT(*) as registros FROM VENTANA_CALENDARIO;

PROMPT =====================================================
PROMPT Esquema y datos completados exitosamente
PROMPT =====================================================

EXIT;
