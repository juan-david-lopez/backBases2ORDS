-- =====================================================
-- SISTEMA ACADÉMICO - ORACLE DATABASE 19c
-- Script: 05_vistas.sql
-- Propósito: Creación de vistas de seguridad y reportes
-- Autor: Sistema Académico
-- Fecha: 28/10/2025
-- =====================================================

-- =====================================================
-- VISTA 1: VW_ESTUDIANTES_PUBLICO
-- Tipo: Ocultamiento de datos sensibles
-- Justificación: Permite consultas públicas sin exponer
-- datos personales como documento, dirección, teléfono
-- =====================================================
CREATE OR REPLACE VIEW VW_ESTUDIANTES_PUBLICO AS
SELECT 
    e.cod_estudiante,
    e.primer_nombre || ' ' || e.primer_apellido AS nombre_completo,
    e.correo_institucional,
    p.nombre_programa,
    p.tipo_programa,
    e.estado_estudiante,
    e.fecha_ingreso
FROM ESTUDIANTE e
INNER JOIN PROGRAMA_ACADEMICO p ON e.cod_programa = p.cod_programa
WHERE e.estado_estudiante IN ('ACTIVO', 'GRADUADO');

COMMENT ON TABLE VW_ESTUDIANTES_PUBLICO IS 'Vista pública de estudiantes sin datos sensibles';

-- =====================================================
-- VISTA 2: VW_DOCENTES_PUBLICO
-- Tipo: Ocultamiento de datos sensibles
-- Justificación: Información básica de docentes sin
-- exponer datos personales ni información laboral sensible
-- =====================================================
CREATE OR REPLACE VIEW VW_DOCENTES_PUBLICO AS
SELECT 
    d.cod_docente,
    d.primer_nombre || ' ' || d.primer_apellido AS nombre_completo,
    d.titulo_academico,
    d.nivel_formacion,
    d.correo_institucional,
    f.nombre_facultad,
    d.estado_docente
FROM DOCENTE d
LEFT JOIN FACULTAD f ON d.cod_facultad = f.cod_facultad
WHERE d.estado_docente = 'ACTIVO';

COMMENT ON TABLE VW_DOCENTES_PUBLICO IS 'Vista pública de docentes activos sin datos sensibles';

-- =====================================================
-- VISTA 3: VW_CALIFICACIONES_ANONIMAS
-- Tipo: Ocultamiento y análisis
-- Justificación: Permite análisis estadístico de notas
-- sin revelar identidad de estudiantes
-- =====================================================
CREATE OR REPLACE VIEW VW_CALIFICACIONES_ANONIMAS AS
SELECT 
    a.cod_asignatura,
    a.nombre_asignatura,
    a.creditos,
    p.nombre_programa,
    pe.cod_periodo,
    pe.nombre_periodo,
    c.cod_tipo_actividad,
    ta.nombre_actividad,
    ROUND(AVG(c.nota), 2) AS promedio_actividad,
    ROUND(MIN(c.nota), 2) AS nota_minima,
    ROUND(MAX(c.nota), 2) AS nota_maxima,
    COUNT(c.cod_calificacion) AS total_estudiantes,
    COUNT(CASE WHEN c.nota >= 3.0 THEN 1 END) AS aprobados,
    COUNT(CASE WHEN c.nota < 3.0 THEN 1 END) AS reprobados,
    ROUND(COUNT(CASE WHEN c.nota >= 3.0 THEN 1 END) * 100.0 / COUNT(*), 2) AS porcentaje_aprobacion
FROM CALIFICACION c
INNER JOIN DETALLE_MATRICULA dm ON c.cod_detalle_matricula = dm.cod_detalle_matricula
INNER JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
INNER JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
INNER JOIN PROGRAMA_ACADEMICO p ON a.cod_programa = p.cod_programa
INNER JOIN PERIODO_ACADEMICO pe ON g.cod_periodo = pe.cod_periodo
INNER JOIN TIPO_ACTIVIDAD_EVALUATIVA ta ON c.cod_tipo_actividad = ta.cod_tipo_actividad
GROUP BY 
    a.cod_asignatura, a.nombre_asignatura, a.creditos,
    p.nombre_programa, pe.cod_periodo, pe.nombre_periodo,
    c.cod_tipo_actividad, ta.nombre_actividad;

COMMENT ON TABLE VW_CALIFICACIONES_ANONIMAS IS 'Estadísticas de calificaciones sin identificar estudiantes';

-- =====================================================
-- VISTA 4: VW_AUDITORIA_RESUMIDA
-- Tipo: Control y seguridad
-- Justificación: Muestra resumen de auditoría sin
-- exponer datos completos de valores sensibles
-- =====================================================
CREATE OR REPLACE VIEW VW_AUDITORIA_RESUMIDA AS
SELECT 
    a.cod_auditoria,
    a.tabla_afectada,
    a.operacion,
    a.usuario_bd,
    a.fecha_operacion,
    a.ip_origen,
    CASE 
        WHEN LENGTH(a.valores_anteriores) > 100 THEN SUBSTR(a.valores_anteriores, 1, 100) || '...'
        ELSE a.valores_anteriores
    END AS valores_anteriores_resumido,
    CASE 
        WHEN LENGTH(a.valores_nuevos) > 100 THEN SUBSTR(a.valores_nuevos, 1, 100) || '...'
        ELSE a.valores_nuevos
    END AS valores_nuevos_resumido
FROM AUDITORIA a
WHERE a.fecha_operacion >= SYSDATE - 90;

COMMENT ON TABLE VW_AUDITORIA_RESUMIDA IS 'Resumen de auditoría de los últimos 90 días';

-- =====================================================
-- VISTA 5: VW_ESTUDIANTES_POR_PROGRAMA
-- Tipo: Reporte administrativo
-- Justificación: Consolidado de estudiantes por programa
-- con información de estado y riesgo académico
-- =====================================================
CREATE OR REPLACE VIEW VW_ESTUDIANTES_POR_PROGRAMA AS
SELECT 
    f.nombre_facultad,
    p.cod_programa,
    p.nombre_programa,
    p.tipo_programa,
    COUNT(DISTINCT e.cod_estudiante) AS total_estudiantes,
    COUNT(DISTINCT CASE WHEN e.estado_estudiante = 'ACTIVO' THEN e.cod_estudiante END) AS estudiantes_activos,
    COUNT(DISTINCT CASE WHEN e.estado_estudiante = 'SUSPENDIDO' THEN e.cod_estudiante END) AS estudiantes_suspendidos,
    COUNT(DISTINCT CASE WHEN e.estado_estudiante = 'RETIRADO' THEN e.cod_estudiante END) AS estudiantes_retirados,
    COUNT(DISTINCT CASE WHEN e.estado_estudiante = 'GRADUADO' THEN e.cod_estudiante END) AS graduados,
    COUNT(DISTINCT hr.cod_estudiante) AS estudiantes_en_riesgo,
    ROUND(COUNT(DISTINCT hr.cod_estudiante) * 100.0 / NULLIF(COUNT(DISTINCT e.cod_estudiante), 0), 2) AS porcentaje_riesgo
FROM PROGRAMA_ACADEMICO p
INNER JOIN FACULTAD f ON p.cod_facultad = f.cod_facultad
LEFT JOIN ESTUDIANTE e ON p.cod_programa = e.cod_programa
LEFT JOIN HISTORIAL_RIESGO hr ON e.cod_estudiante = hr.cod_estudiante 
    AND hr.estado_seguimiento IN ('PENDIENTE', 'EN_SEGUIMIENTO')
GROUP BY f.nombre_facultad, p.cod_programa, p.nombre_programa, p.tipo_programa
ORDER BY f.nombre_facultad, p.nombre_programa;

COMMENT ON TABLE VW_ESTUDIANTES_POR_PROGRAMA IS 'Consolidado de estudiantes por programa académico';

-- =====================================================
-- VISTA 6: VW_MATRICULAS_POR_PERIODO
-- Tipo: Reporte administrativo
-- Justificación: Consolidado de matrículas por periodo
-- académico con estadísticas de cobertura
-- =====================================================
CREATE OR REPLACE VIEW VW_MATRICULAS_POR_PERIODO AS
SELECT 
    pe.cod_periodo,
    pe.nombre_periodo,
    pe.anio,
    pe.estado_periodo,
    COUNT(DISTINCT m.cod_matricula) AS total_matriculas,
    COUNT(DISTINCT m.cod_estudiante) AS total_estudiantes_matriculados,
    COUNT(DISTINCT dm.cod_detalle_matricula) AS total_inscripciones_asignaturas,
    SUM(m.total_creditos) AS total_creditos_matriculados,
    ROUND(AVG(m.total_creditos), 2) AS promedio_creditos_estudiante,
    SUM(m.valor_matricula) AS ingresos_matricula,
    COUNT(DISTINCT CASE WHEN m.estado_matricula = 'ACTIVA' THEN m.cod_matricula END) AS matriculas_activas,
    COUNT(DISTINCT CASE WHEN m.estado_matricula = 'CANCELADA' THEN m.cod_matricula END) AS matriculas_canceladas,
    COUNT(DISTINCT CASE WHEN m.tipo_matricula = 'ORDINARIA' THEN m.cod_matricula END) AS matriculas_ordinarias,
    COUNT(DISTINCT CASE WHEN m.tipo_matricula = 'EXTRAORDINARIA' THEN m.cod_matricula END) AS matriculas_extraordinarias
FROM PERIODO_ACADEMICO pe
LEFT JOIN MATRICULA m ON pe.cod_periodo = m.cod_periodo
LEFT JOIN DETALLE_MATRICULA dm ON m.cod_matricula = dm.cod_matricula
GROUP BY pe.cod_periodo, pe.nombre_periodo, pe.anio, pe.estado_periodo
ORDER BY pe.anio DESC, pe.periodo DESC;

COMMENT ON TABLE VW_MATRICULAS_POR_PERIODO IS 'Consolidado de matrículas por periodo académico';

-- =====================================================
-- VISTA 7: VW_RENDIMIENTO_POR_ASIGNATURA
-- Tipo: Reporte académico
-- Justificación: Análisis de rendimiento académico por
-- asignatura con tasas de aprobación y deserción
-- =====================================================
CREATE OR REPLACE VIEW VW_RENDIMIENTO_POR_ASIGNATURA AS
SELECT 
    a.cod_asignatura,
    a.nombre_asignatura,
    a.creditos,
    p.nombre_programa,
    pe.cod_periodo,
    pe.nombre_periodo,
    d.primer_nombre || ' ' || d.primer_apellido AS nombre_docente,
    g.numero_grupo,
    COUNT(DISTINCT dm.cod_detalle_matricula) AS total_inscritos,
    COUNT(DISTINCT CASE WHEN dm.estado_inscripcion = 'RETIRADO' THEN dm.cod_detalle_matricula END) AS total_retirados,
    COUNT(DISTINCT nd.cod_nota_definitiva) AS total_calificados,
    ROUND(AVG(nd.nota_final), 2) AS promedio_asignatura,
    ROUND(MIN(nd.nota_final), 2) AS nota_minima,
    ROUND(MAX(nd.nota_final), 2) AS nota_maxima,
    COUNT(CASE WHEN nd.resultado = 'APROBADO' THEN 1 END) AS total_aprobados,
    COUNT(CASE WHEN nd.resultado = 'REPROBADO' THEN 1 END) AS total_reprobados,
    ROUND(COUNT(CASE WHEN nd.resultado = 'APROBADO' THEN 1 END) * 100.0 / 
          NULLIF(COUNT(nd.cod_nota_definitiva), 0), 2) AS porcentaje_aprobacion,
    ROUND(COUNT(DISTINCT CASE WHEN dm.estado_inscripcion = 'RETIRADO' THEN dm.cod_detalle_matricula END) * 100.0 / 
          NULLIF(COUNT(DISTINCT dm.cod_detalle_matricula), 0), 2) AS porcentaje_desercion
FROM GRUPO g
INNER JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
INNER JOIN PROGRAMA_ACADEMICO p ON a.cod_programa = p.cod_programa
INNER JOIN PERIODO_ACADEMICO pe ON g.cod_periodo = pe.cod_periodo
LEFT JOIN DOCENTE d ON g.cod_docente = d.cod_docente
LEFT JOIN DETALLE_MATRICULA dm ON g.cod_grupo = dm.cod_grupo
LEFT JOIN NOTA_DEFINITIVA nd ON dm.cod_detalle_matricula = nd.cod_detalle_matricula
GROUP BY 
    a.cod_asignatura, a.nombre_asignatura, a.creditos,
    p.nombre_programa, pe.cod_periodo, pe.nombre_periodo,
    d.primer_nombre, d.primer_apellido, g.numero_grupo
ORDER BY pe.cod_periodo DESC, a.nombre_asignatura;

COMMENT ON TABLE VW_RENDIMIENTO_POR_ASIGNATURA IS 'Análisis de rendimiento académico por asignatura';

-- =====================================================
-- VISTA 8: VW_CARGA_DOCENTE
-- Tipo: Control administrativo
-- Justificación: Calcula carga académica semanal de
-- docentes para control de horas y distribución equitativa
-- =====================================================
CREATE OR REPLACE VIEW VW_CARGA_DOCENTE AS
SELECT 
    d.cod_docente,
    d.primer_nombre || ' ' || d.primer_apellido AS nombre_docente,
    d.tipo_vinculacion,
    d.estado_docente,
    f.nombre_facultad,
    pe.cod_periodo,
    pe.nombre_periodo,
    COUNT(DISTINCT g.cod_grupo) AS total_grupos,
    SUM(a.creditos) AS total_creditos,
    SUM(a.horas_teoricas + a.horas_practicas) AS total_horas_semanales,
    COUNT(DISTINCT g.cod_asignatura) AS asignaturas_distintas,
    SUM(g.cupo_maximo - g.cupo_disponible) AS total_estudiantes_atendidos
FROM DOCENTE d
LEFT JOIN FACULTAD f ON d.cod_facultad = f.cod_facultad
INNER JOIN GRUPO g ON d.cod_docente = g.cod_docente
INNER JOIN PERIODO_ACADEMICO pe ON g.cod_periodo = pe.cod_periodo
INNER JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
WHERE g.estado_grupo = 'ACTIVO'
    AND pe.estado_periodo IN ('PROGRAMADO', 'EN_CURSO')
GROUP BY 
    d.cod_docente, d.primer_nombre, d.primer_apellido,
    d.tipo_vinculacion, d.estado_docente, f.nombre_facultad,
    pe.cod_periodo, pe.nombre_periodo
ORDER BY pe.cod_periodo DESC, total_horas_semanales DESC;

COMMENT ON TABLE VW_CARGA_DOCENTE IS 'Carga académica semanal por docente';

-- =====================================================
-- VISTA 9: VW_ESTUDIANTES_RIESGO
-- Tipo: Seguimiento académico
-- Justificación: Identifica estudiantes en riesgo para
-- intervención temprana y seguimiento personalizado
-- =====================================================
CREATE OR REPLACE VIEW VW_ESTUDIANTES_RIESGO AS
SELECT 
    e.cod_estudiante,
    e.primer_nombre || ' ' || e.primer_apellido AS nombre_estudiante,
    e.correo_institucional,
    p.nombre_programa,
    hr.cod_periodo,
    hr.tipo_riesgo,
    hr.nivel_riesgo,
    hr.promedio_periodo,
    hr.asignaturas_reprobadas,
    hr.fecha_deteccion,
    hr.estado_seguimiento,
    hr.observaciones,
    TRUNC(SYSDATE - hr.fecha_deteccion) AS dias_desde_deteccion
FROM HISTORIAL_RIESGO hr
INNER JOIN ESTUDIANTE e ON hr.cod_estudiante = e.cod_estudiante
INNER JOIN PROGRAMA_ACADEMICO p ON e.cod_programa = p.cod_programa
WHERE hr.estado_seguimiento IN ('PENDIENTE', 'EN_SEGUIMIENTO')
    AND e.estado_estudiante = 'ACTIVO'
ORDER BY 
    CASE hr.nivel_riesgo 
        WHEN 'CRITICO' THEN 1
        WHEN 'ALTO' THEN 2
        WHEN 'MEDIO' THEN 3
        WHEN 'BAJO' THEN 4
    END,
    hr.fecha_deteccion DESC;

COMMENT ON TABLE VW_ESTUDIANTES_RIESGO IS 'Estudiantes activos en riesgo académico que requieren seguimiento';

-- =====================================================
-- VISTA 10: VW_GRUPOS_DISPONIBLES
-- Tipo: Gestión de matrícula
-- Justificación: Muestra grupos con cupos disponibles
-- para facilitar proceso de matrícula
-- =====================================================
CREATE OR REPLACE VIEW VW_GRUPOS_DISPONIBLES AS
SELECT 
    g.cod_grupo,
    g.numero_grupo,
    a.cod_asignatura,
    a.nombre_asignatura,
    a.creditos,
    a.tipo_asignatura,
    p.nombre_programa,
    pe.cod_periodo,
    pe.nombre_periodo,
    d.primer_nombre || ' ' || d.primer_apellido AS nombre_docente,
    g.cupo_maximo,
    g.cupo_disponible,
    g.cupo_maximo - g.cupo_disponible AS cupos_ocupados,
    ROUND((g.cupo_maximo - g.cupo_disponible) * 100.0 / g.cupo_maximo, 2) AS porcentaje_ocupacion,
    g.modalidad,
    g.aula,
    g.estado_grupo,
    LISTAGG(h.dia_semana || ' ' || h.hora_inicio || '-' || h.hora_fin, ', ') 
        WITHIN GROUP (ORDER BY 
            CASE h.dia_semana
                WHEN 'LUNES' THEN 1
                WHEN 'MARTES' THEN 2
                WHEN 'MIERCOLES' THEN 3
                WHEN 'JUEVES' THEN 4
                WHEN 'VIERNES' THEN 5
                WHEN 'SABADO' THEN 6
                WHEN 'DOMINGO' THEN 7
            END) AS horario
FROM GRUPO g
INNER JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
INNER JOIN PROGRAMA_ACADEMICO p ON a.cod_programa = p.cod_programa
INNER JOIN PERIODO_ACADEMICO pe ON g.cod_periodo = pe.cod_periodo
LEFT JOIN DOCENTE d ON g.cod_docente = d.cod_docente
LEFT JOIN HORARIO h ON g.cod_grupo = h.cod_grupo
WHERE g.estado_grupo = 'ACTIVO'
    AND g.cupo_disponible > 0
    AND pe.estado_periodo IN ('PROGRAMADO', 'EN_CURSO')
GROUP BY 
    g.cod_grupo, g.numero_grupo, a.cod_asignatura, a.nombre_asignatura,
    a.creditos, a.tipo_asignatura, p.nombre_programa, pe.cod_periodo,
    pe.nombre_periodo, d.primer_nombre, d.primer_apellido,
    g.cupo_maximo, g.cupo_disponible, g.modalidad, g.aula, g.estado_grupo
ORDER BY pe.cod_periodo DESC, a.nombre_asignatura, g.numero_grupo;

COMMENT ON TABLE VW_GRUPOS_DISPONIBLES IS 'Grupos activos con cupos disponibles para matrícula';

-- =====================================================
-- VISTA 11: VW_HISTORIAL_ACADEMICO
-- Tipo: Reporte individual
-- Justificación: Muestra historial académico completo
-- del estudiante con notas por periodo
-- =====================================================
CREATE OR REPLACE VIEW VW_HISTORIAL_ACADEMICO AS
SELECT 
    e.cod_estudiante,
    e.primer_nombre || ' ' || e.primer_apellido AS nombre_estudiante,
    p.nombre_programa,
    pe.cod_periodo,
    pe.nombre_periodo,
    a.cod_asignatura,
    a.nombre_asignatura,
    a.creditos,
    g.numero_grupo,
    d.primer_nombre || ' ' || d.primer_apellido AS nombre_docente,
    dm.estado_inscripcion,
    nd.nota_final,
    nd.resultado,
    CASE 
        WHEN nd.resultado = 'APROBADO' THEN a.creditos
        ELSE 0
    END AS creditos_aprobados,
    nd.fecha_calculo
FROM ESTUDIANTE e
INNER JOIN MATRICULA m ON e.cod_estudiante = m.cod_estudiante
INNER JOIN PROGRAMA_ACADEMICO p ON e.cod_programa = p.cod_programa
INNER JOIN PERIODO_ACADEMICO pe ON m.cod_periodo = pe.cod_periodo
INNER JOIN DETALLE_MATRICULA dm ON m.cod_matricula = dm.cod_matricula
INNER JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
INNER JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
LEFT JOIN DOCENTE d ON g.cod_docente = d.cod_docente
LEFT JOIN NOTA_DEFINITIVA nd ON dm.cod_detalle_matricula = nd.cod_detalle_matricula
ORDER BY e.cod_estudiante, pe.anio, pe.periodo, a.nombre_asignatura;

COMMENT ON TABLE VW_HISTORIAL_ACADEMICO IS 'Historial académico completo por estudiante';

-- =====================================================
-- VISTA 12: VW_CALENDARIO_VIGENTE
-- Tipo: Seguimiento de actividades
-- Justificación: Muestra actividades académicas del
-- periodo actual para planificación y seguimiento
-- =====================================================
CREATE OR REPLACE VIEW VW_CALENDARIO_VIGENTE AS
SELECT 
    pe.cod_periodo,
    pe.nombre_periodo,
    pe.fecha_inicio AS inicio_periodo,
    pe.fecha_fin AS fin_periodo,
    TRUNC(SYSDATE - pe.fecha_inicio) AS dias_transcurridos,
    TRUNC(pe.fecha_fin - SYSDATE) AS dias_restantes,
    ROUND((SYSDATE - pe.fecha_inicio) / (pe.fecha_fin - pe.fecha_inicio) * 100, 2) AS porcentaje_avance,
    COUNT(DISTINCT g.cod_grupo) AS total_grupos_activos,
    COUNT(DISTINCT m.cod_matricula) AS total_matriculas_activas,
    COUNT(DISTINCT c.cod_calificacion) AS total_calificaciones_registradas,
    SUM(CASE 
        WHEN UPPER(TRIM(TO_CHAR(SYSDATE, 'DAY', 'NLS_DATE_LANGUAGE=SPANISH'))) = UPPER(TRIM(h.dia_semana))
        THEN 1 
        ELSE 0 
    END) AS clases_hoy
FROM PERIODO_ACADEMICO pe
LEFT JOIN GRUPO g ON pe.cod_periodo = g.cod_periodo AND g.estado_grupo = 'ACTIVO'
LEFT JOIN MATRICULA m ON pe.cod_periodo = m.cod_periodo AND m.estado_matricula = 'ACTIVA'
LEFT JOIN DETALLE_MATRICULA dm ON m.cod_matricula = dm.cod_matricula
LEFT JOIN CALIFICACION c ON dm.cod_detalle_matricula = c.cod_detalle_matricula
LEFT JOIN HORARIO h ON g.cod_grupo = h.cod_grupo
WHERE pe.estado_periodo = 'EN_CURSO'
GROUP BY 
    pe.cod_periodo, pe.nombre_periodo, pe.fecha_inicio, pe.fecha_fin;

COMMENT ON TABLE VW_CALENDARIO_VIGENTE IS 'Información del periodo académico vigente con estadísticas actualizadas';

-- =====================================================
-- VISTAS ADICIONALES PARA ANÁLISIS ESPECIALIZADO
-- =====================================================

-- Vista para detectar conflictos de horario
CREATE OR REPLACE VIEW VW_CONFLICTOS_HORARIO AS
SELECT 
    h1.cod_horario AS horario_1,
    h1.cod_grupo AS grupo_1,
    h2.cod_horario AS horario_2,
    h2.cod_grupo AS grupo_2,
    h1.dia_semana,
    h1.hora_inicio,
    h1.hora_fin,
    h1.aula
FROM HORARIO h1
INNER JOIN HORARIO h2 ON h1.dia_semana = h2.dia_semana
    AND h1.aula = h2.aula
    AND h1.cod_horario < h2.cod_horario
    AND (
        (h1.hora_inicio BETWEEN h2.hora_inicio AND h2.hora_fin)
        OR (h1.hora_fin BETWEEN h2.hora_inicio AND h2.hora_fin)
        OR (h2.hora_inicio BETWEEN h1.hora_inicio AND h1.hora_fin)
    );

COMMENT ON TABLE VW_CONFLICTOS_HORARIO IS 'Detecta conflictos de horario en la misma aula';

-- =====================================================
-- ESTADÍSTICAS DE VISTAS CREADAS
-- =====================================================
SELECT 
    view_name,
    text_length,
    type_text
FROM user_views
WHERE view_name LIKE 'VW_%'
ORDER BY view_name;

PROMPT '========================================='
PROMPT 'Vistas creadas exitosamente'
PROMPT 'Total de vistas del sistema:'
PROMPT '========================================='

SELECT COUNT(*) AS total_vistas
FROM user_views
WHERE view_name LIKE 'VW_%';
CREATE OR REPLACE VIEW VW_MATRICULAS_POR_PERIODO AS
SELECT 
    pe.cod_periodo,
    pe.nombre_periodo,
    pe.anio,
    pe.estado_periodo,
    pe.periodo, -- <--- Agrega esta columna
    COUNT(DISTINCT m.cod_matricula) AS total_matriculas,
    COUNT(DISTINCT m.cod_estudiante) AS total_estudiantes_matriculados,
    COUNT(DISTINCT dm.cod_detalle_matricula) AS total_inscripciones_asignaturas,
    SUM(m.total_creditos) AS total_creditos_matriculados,
    ROUND(AVG(m.total_creditos), 2) AS promedio_creditos_estudiante,
    SUM(m.valor_matricula) AS ingresos_matricula,
    COUNT(DISTINCT CASE WHEN m.estado_matricula = 'ACTIVA' THEN m.cod_matricula END) AS matriculas_activas,
    COUNT(DISTINCT CASE WHEN m.estado_matricula = 'CANCELADA' THEN m.cod_matricula END) AS matriculas_canceladas,
    COUNT(DISTINCT CASE WHEN m.tipo_matricula = 'ORDINARIA' THEN m.cod_matricula END) AS matriculas_ordinarias,
    COUNT(DISTINCT CASE WHEN m.tipo_matricula = 'EXTRAORDINARIA' THEN m.cod_matricula END) AS matriculas_extraordinarias
FROM PERIODO_ACADEMICO pe
LEFT JOIN MATRICULA m ON pe.cod_periodo = m.cod_periodo
LEFT JOIN DETALLE_MATRICULA dm ON m.cod_matricula = dm.cod_matricula
GROUP BY pe.cod_periodo, pe.nombre_periodo, pe.anio, pe.estado_periodo, pe.periodo
ORDER BY pe.anio DESC, pe.periodo DESC;
COMMENT ON TABLE VW_MATRICULAS_POR_PERIODO IS 'Consolidado de matrículas por periodo académico';