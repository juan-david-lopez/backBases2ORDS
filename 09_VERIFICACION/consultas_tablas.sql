-- =====================================================
-- SCRIPT DE CONSULTAS PARA VERIFICAR DATOS
-- Sistema Académico - Base de Datos
-- =====================================================
SELECT * 
FROM all_tab_privs
WHERE table_name = 'USUARIO';

SET LINESIZE 200
SET PAGESIZE 100
COLUMN primer_nombre FORMAT A15
COLUMN primer_apellido FORMAT A15
COLUMN correo_institucional FORMAT A30
COLUMN nombre_periodo FORMAT A30
COLUMN nombre_programa FORMAT A30
COLUMN nombre_asignatura FORMAT A30
COLUMN nombre_facultad FORMAT A25

PROMPT =====================================================
PROMPT 1. ESTUDIANTES
PROMPT =====================================================
SELECT 
    cod_estudiante,
    primer_nombre,
    segundo_nombre,
    primer_apellido,
    segundo_apellido,
    correo_institucional,
    num_documento,
    estado_estudiante
FROM ESTUDIANTE
ORDER BY cod_estudiante;

PROMPT
PROMPT =====================================================
PROMPT 2. PERIODOS ACADÉMICOS
PROMPT =====================================================
SELECT 
    cod_periodo,
    nombre_periodo,
    anio,
    TO_CHAR(fecha_inicio, 'DD/MM/YYYY') AS fecha_inicio,
    TO_CHAR(fecha_fin, 'DD/MM/YYYY') AS fecha_fin,
    estado_periodo
FROM PERIODO_ACADEMICO
ORDER BY anio DESC;

PROMPT
PROMPT =====================================================
PROMPT 3. FACULTADES
PROMPT =====================================================
SELECT 
    cod_facultad,
    nombre_facultad,
    sigla,
    TO_CHAR(fecha_creacion, 'DD/MM/YYYY') AS fecha_creacion,
    decano_actual,
    estado
FROM FACULTAD
ORDER BY cod_facultad;

PROMPT
PROMPT =====================================================
PROMPT 4. PROGRAMAS ACADÉMICOS
PROMPT =====================================================
SELECT 
    p.cod_programa,
    p.nombre_programa,
    p.tipo_programa,
    p.nivel_formacion,
    f.nombre_facultad,
    p.creditos_totales,
    p.duracion_semestres,
    p.estado
FROM PROGRAMA_ACADEMICO p
LEFT JOIN FACULTAD f ON p.cod_facultad = f.cod_facultad
ORDER BY p.cod_programa;

PROMPT
PROMPT =====================================================
PROMPT 5. ASIGNATURAS
PROMPT =====================================================
SELECT 
    cod_asignatura,
    nombre_asignatura,
    creditos,
    horas_teoricas,
    horas_practicas,
    tipo_asignatura,
    semestre_sugerido,
    estado
FROM ASIGNATURA
ORDER BY cod_asignatura;

PROMPT
PROMPT =====================================================
PROMPT 6. MATRÍCULAS
PROMPT =====================================================
SELECT 
    m.cod_matricula,
    m.cod_estudiante,
    e.primer_nombre || ' ' || e.primer_apellido AS estudiante,
    m.cod_periodo,
    p.nombre_periodo,
    TO_CHAR(m.fecha_matricula, 'DD/MM/YYYY') AS fecha_matricula,
    m.estado_matricula,
    m.total_creditos,
    m.valor_matricula
FROM MATRICULA m
LEFT JOIN ESTUDIANTE e ON m.cod_estudiante = e.cod_estudiante
LEFT JOIN PERIODO_ACADEMICO p ON m.cod_periodo = p.cod_periodo
ORDER BY m.fecha_matricula DESC;

PROMPT
PROMPT =====================================================
PROMPT 7. DETALLE DE MATRÍCULAS (Asignaturas por Matrícula)
PROMPT =====================================================
SELECT 
    dm.cod_detalle_matricula,
    dm.cod_matricula,
    e.primer_nombre || ' ' || e.primer_apellido AS estudiante,
    a.nombre_asignatura,
    g.numero_grupo,
    TO_CHAR(dm.fecha_inscripcion, 'DD/MM/YYYY') AS fecha_inscripcion,
    dm.estado_inscripcion
FROM DETALLE_MATRICULA dm
LEFT JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
LEFT JOIN ESTUDIANTE e ON m.cod_estudiante = e.cod_estudiante
LEFT JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
LEFT JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
ORDER BY dm.cod_detalle_matricula;

PROMPT
PROMPT =====================================================
PROMPT 8. GRUPOS
PROMPT =====================================================
SELECT 
    g.cod_grupo,
    g.numero_grupo,
    a.nombre_asignatura,
    p.nombre_periodo,
    d.primer_nombre || ' ' || d.primer_apellido AS docente,
    g.cupo_maximo,
    g.cupo_disponible,
    g.modalidad,
    g.aula,
    g.estado_grupo
FROM GRUPO g
LEFT JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
LEFT JOIN PERIODO_ACADEMICO p ON g.cod_periodo = p.cod_periodo
LEFT JOIN DOCENTE d ON g.cod_docente = d.cod_docente
ORDER BY g.cod_grupo;

PROMPT
PROMPT =====================================================
PROMPT 9. DOCENTES
PROMPT =====================================================
SELECT 
    cod_docente,
    primer_nombre,
    segundo_nombre,
    primer_apellido,
    segundo_apellido,
    correo_institucional,
    titulo_academico,
    nivel_formacion,
    tipo_vinculacion,
    estado_docente
FROM DOCENTE
ORDER BY cod_docente;

PROMPT
PROMPT =====================================================
PROMPT 10. CALIFICACIONES
PROMPT =====================================================
SELECT 
    c.cod_calificacion,
    e.primer_nombre || ' ' || e.primer_apellido AS estudiante,
    a.nombre_asignatura,
    ta.nombre_actividad,
    c.numero_actividad,
    c.nota,
    c.porcentaje_aplicado,
    TO_CHAR(c.fecha_calificacion, 'DD/MM/YYYY') AS fecha_calificacion
FROM CALIFICACION c
LEFT JOIN DETALLE_MATRICULA dm ON c.cod_detalle_matricula = dm.cod_detalle_matricula
LEFT JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
LEFT JOIN ESTUDIANTE e ON m.cod_estudiante = e.cod_estudiante
LEFT JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
LEFT JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
LEFT JOIN TIPO_ACTIVIDAD_EVALUATIVA ta ON c.cod_tipo_actividad = ta.cod_tipo_actividad
ORDER BY c.cod_calificacion;

PROMPT
PROMPT =====================================================
PROMPT 11. NOTAS DEFINITIVAS
PROMPT =====================================================
SELECT 
    nd.cod_nota_definitiva,
    e.primer_nombre || ' ' || e.primer_apellido AS estudiante,
    a.nombre_asignatura,
    nd.nota_final,
    nd.resultado,
    TO_CHAR(nd.fecha_calculo, 'DD/MM/YYYY') AS fecha_calculo
FROM NOTA_DEFINITIVA nd
LEFT JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
LEFT JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
LEFT JOIN ESTUDIANTE e ON m.cod_estudiante = e.cod_estudiante
LEFT JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
LEFT JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
ORDER BY nd.fecha_calculo DESC;

PROMPT
PROMPT =====================================================
PROMPT 12. RESUMEN GENERAL
PROMPT =====================================================
SELECT 'ESTUDIANTES' AS TABLA, COUNT(*) AS TOTAL_REGISTROS FROM ESTUDIANTE
UNION ALL
SELECT 'PERIODOS', COUNT(*) FROM PERIODO_ACADEMICO
UNION ALL
SELECT 'FACULTADES', COUNT(*) FROM FACULTAD
UNION ALL
SELECT 'PROGRAMAS', COUNT(*) FROM PROGRAMA_ACADEMICO
UNION ALL
SELECT 'ASIGNATURAS', COUNT(*) FROM ASIGNATURA
UNION ALL
SELECT 'DOCENTES', COUNT(*) FROM DOCENTE
UNION ALL
SELECT 'GRUPOS', COUNT(*) FROM GRUPO
UNION ALL
SELECT 'MATRÍCULAS', COUNT(*) FROM MATRICULA
UNION ALL
SELECT 'DETALLE_MATRICULA', COUNT(*) FROM DETALLE_MATRICULA
UNION ALL
SELECT 'CALIFICACIONES', COUNT(*) FROM CALIFICACION
UNION ALL
SELECT 'NOTAS_DEFINITIVAS', COUNT(*) FROM NOTA_DEFINITIVA;

PROMPT
PROMPT =====================================================
PROMPT SCRIPT DE CONSULTAS COMPLETADO
PROMPT =====================================================
