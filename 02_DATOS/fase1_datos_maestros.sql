-- =====================================================
-- POBLAMIENTO DE DATOS MAESTROS - FASE 1
-- Sistema Académico
-- =====================================================

PROMPT =====================================================
PROMPT INICIANDO POBLAMIENTO DE DATOS MAESTROS
PROMPT =====================================================

-- =====================================================
-- 1. DOCENTES
-- =====================================================
PROMPT
PROMPT Insertando docentes...

INSERT INTO DOCENTE (cod_docente, tipo_documento, num_documento, primer_nombre, segundo_nombre, 
    primer_apellido, segundo_apellido, titulo_academico, nivel_formacion, tipo_vinculacion,
    correo_institucional, correo_personal, telefono, cod_facultad, fecha_vinculacion)
VALUES ('DOC001', 'CC', '12345678', 'Carlos', 'Alberto', 'Rodríguez', 'Martínez',
    'Ingeniero de Sistemas', 'MAESTRIA', 'PLANTA', 'carlos.rodriguez@universidad.edu',
    'carlos.r@gmail.com', '3101234567', 1, TO_DATE('2020-01-15', 'YYYY-MM-DD'));

INSERT INTO DOCENTE (cod_docente, tipo_documento, num_documento, primer_nombre, segundo_nombre,
    primer_apellido, segundo_apellido, titulo_academico, nivel_formacion, tipo_vinculacion,
    correo_institucional, telefono, cod_facultad, fecha_vinculacion)
VALUES ('DOC002', 'CC', '23456789', 'María', 'Fernanda', 'López', 'García',
    'Matemática', 'DOCTORADO', 'PLANTA', 'maria.lopez@universidad.edu',
    '3201234567', 1, TO_DATE('2018-08-01', 'YYYY-MM-DD'));

INSERT INTO DOCENTE (cod_docente, tipo_documento, num_documento, primer_nombre,
    primer_apellido, segundo_apellido, titulo_academico, nivel_formacion, tipo_vinculacion,
    correo_institucional, telefono, cod_facultad, fecha_vinculacion)
VALUES ('DOC003', 'CC', '34567890', 'Jorge', 'Ramírez', 'Silva',
    'Ingeniero Electrónico', 'MAESTRIA', 'CATEDRA', 'jorge.ramirez@universidad.edu',
    '3301234567', 1, TO_DATE('2021-02-10', 'YYYY-MM-DD'));

PROMPT Docentes insertados: 3

-- =====================================================
-- 2. ASIGNATURAS
-- =====================================================
PROMPT
PROMPT Insertando asignaturas...

-- Primer semestre (1 crédito = 3 horas semanales)
INSERT INTO ASIGNATURA (cod_asignatura, nombre_asignatura, creditos, horas_teoricas, horas_practicas,
    tipo_asignatura, cod_programa, semestre_sugerido, requiere_prerrequisito)
VALUES ('IS101', 'Introducción a la Programación', 4, 8, 4, 'OBLIGATORIA', 1, 1, 'N');

INSERT INTO ASIGNATURA (cod_asignatura, nombre_asignatura, creditos, horas_teoricas, horas_practicas,
    tipo_asignatura, cod_programa, semestre_sugerido, requiere_prerrequisito)
VALUES ('IS102', 'Cálculo Diferencial', 4, 10, 2, 'OBLIGATORIA', 1, 1, 'N');

INSERT INTO ASIGNATURA (cod_asignatura, nombre_asignatura, creditos, horas_teoricas, horas_practicas,
    tipo_asignatura, cod_programa, semestre_sugerido, requiere_prerrequisito)
VALUES ('IS103', 'Álgebra Lineal', 3, 7, 2, 'OBLIGATORIA', 1, 1, 'N');

INSERT INTO ASIGNATURA (cod_asignatura, nombre_asignatura, creditos, horas_teoricas, horas_practicas,
    tipo_asignatura, cod_programa, semestre_sugerido, requiere_prerrequisito)
VALUES ('IS104', 'Fundamentos de Ingeniería', 3, 6, 3, 'OBLIGATORIA', 1, 1, 'N');

-- Segundo semestre
INSERT INTO ASIGNATURA (cod_asignatura, nombre_asignatura, creditos, horas_teoricas, horas_practicas,
    tipo_asignatura, cod_programa, semestre_sugerido, requiere_prerrequisito)
VALUES ('IS201', 'Estructura de Datos', 4, 8, 4, 'OBLIGATORIA', 1, 2, 'S');

INSERT INTO ASIGNATURA (cod_asignatura, nombre_asignatura, creditos, horas_teoricas, horas_practicas,
    tipo_asignatura, cod_programa, semestre_sugerido, requiere_prerrequisito)
VALUES ('IS202', 'Bases de Datos I', 4, 8, 4, 'OBLIGATORIA', 1, 2, 'N');

PROMPT Asignaturas insertadas: 6

-- =====================================================
-- 3. GRUPOS
-- =====================================================
PROMPT
PROMPT Insertando grupos para periodo 2025-1...

INSERT INTO GRUPO (cod_asignatura, cod_periodo, numero_grupo, cod_docente, cupo_maximo, 
    cupo_disponible, modalidad, aula)
VALUES ('IS101', '2025-1', 1, 'DOC001', 30, 30, 'PRESENCIAL', 'A-201');

INSERT INTO GRUPO (cod_asignatura, cod_periodo, numero_grupo, cod_docente, cupo_maximo,
    cupo_disponible, modalidad, aula)
VALUES ('IS102', '2025-1', 1, 'DOC002', 30, 30, 'PRESENCIAL', 'A-202');

INSERT INTO GRUPO (cod_asignatura, cod_periodo, numero_grupo, cod_docente, cupo_maximo,
    cupo_disponible, modalidad, aula)
VALUES ('IS103', '2025-1', 1, 'DOC002', 30, 30, 'PRESENCIAL', 'A-203');

INSERT INTO GRUPO (cod_asignatura, cod_periodo, numero_grupo, cod_docente, cupo_maximo,
    cupo_disponible, modalidad, aula)
VALUES ('IS104', '2025-1', 1, 'DOC003', 25, 25, 'HIBRIDO', 'A-301');

INSERT INTO GRUPO (cod_asignatura, cod_periodo, numero_grupo, cod_docente, cupo_maximo,
    cupo_disponible, modalidad, aula)
VALUES ('IS201', '2025-1', 1, 'DOC001', 25, 25, 'PRESENCIAL', 'A-204');

INSERT INTO GRUPO (cod_asignatura, cod_periodo, numero_grupo, cod_docente, cupo_maximo,
    cupo_disponible, modalidad, aula)
VALUES ('IS202', '2025-1', 1, 'DOC003', 30, 30, 'PRESENCIAL', 'LAB-01');

PROMPT Grupos insertados: 6

-- =====================================================
-- 4. TIPOS DE ACTIVIDAD EVALUATIVA
-- =====================================================
PROMPT
PROMPT Insertando tipos de actividad evaluativa...

INSERT INTO TIPO_ACTIVIDAD_EVALUATIVA (nombre_actividad, descripcion)
VALUES ('Parcial', 'Evaluación parcial escrita');

INSERT INTO TIPO_ACTIVIDAD_EVALUATIVA (nombre_actividad, descripcion)
VALUES ('Quiz', 'Evaluación corta de conocimientos');

INSERT INTO TIPO_ACTIVIDAD_EVALUATIVA (nombre_actividad, descripcion)
VALUES ('Taller', 'Trabajo práctico individual o en grupo');

INSERT INTO TIPO_ACTIVIDAD_EVALUATIVA (nombre_actividad, descripcion)
VALUES ('Proyecto', 'Proyecto de desarrollo o investigación');

INSERT INTO TIPO_ACTIVIDAD_EVALUATIVA (nombre_actividad, descripcion)
VALUES ('Exposición', 'Presentación oral de tema asignado');

PROMPT Tipos de actividad insertados: 5

-- =====================================================
-- 5. CONFIRMAR CAMBIOS
-- =====================================================
COMMIT;

PROMPT
PROMPT =====================================================
PROMPT DATOS MAESTROS INSERTADOS EXITOSAMENTE
PROMPT =====================================================
PROMPT
PROMPT Resumen:
PROMPT - Docentes: 3
PROMPT - Asignaturas: 6
PROMPT - Grupos: 6
PROMPT - Tipos de Actividad: 5
PROMPT
PROMPT Ahora puedes probar los endpoints REST
PROMPT =====================================================

-- =====================================================
-- 6. VERIFICACIÓN RÁPIDA
-- =====================================================
PROMPT
PROMPT Verificando datos insertados...
PROMPT

SELECT 'DOCENTES' AS TIPO, COUNT(*) AS CANTIDAD FROM DOCENTE
UNION ALL
SELECT 'ASIGNATURAS', COUNT(*) FROM ASIGNATURA
UNION ALL
SELECT 'GRUPOS', COUNT(*) FROM GRUPO
UNION ALL
SELECT 'TIPOS ACTIVIDAD', COUNT(*) FROM TIPO_ACTIVIDAD_EVALUATIVA;

PROMPT
PROMPT =====================================================
PROMPT CONSULTA DE GRUPOS DISPONIBLES (Importante para endpoints)
PROMPT =====================================================

SELECT 
    g.cod_grupo,
    a.cod_asignatura,
    a.nombre_asignatura,
    g.numero_grupo,
    d.primer_nombre || ' ' || d.primer_apellido AS docente,
    g.cupo_disponible
FROM GRUPO g
JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
JOIN DOCENTE d ON g.cod_docente = d.cod_docente
ORDER BY g.cod_grupo;
