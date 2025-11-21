-- ============================================================
-- REPORTERÍA ANALÍTICA COMPLETA - 18 REPORTES SQL
-- Sistema de Gestión Académica
-- ============================================================

-- ============================================================
-- CATEGORÍA 1: MATRÍCULA Y CARGA ACADÉMICA (6 reportes)
-- ============================================================

-- REPORTE 1: Estadísticas de matrícula por periodo y programa
CREATE OR REPLACE VIEW VW_ESTADISTICAS_MATRICULA AS
SELECT 
    m.cod_periodo,
    p.nombre_programa,
    p.nivel_academico,
    COUNT(DISTINCT m.cod_estudiante) as total_estudiantes_matriculados,
    COUNT(dm.cod_detalle_matricula) as total_inscripciones,
    ROUND(AVG(creditos_grupo.creditos), 2) as promedio_creditos_por_estudiante,
    COUNT(CASE WHEN dm.estado_inscripcion = 'CURSANDO' THEN 1 END) as materias_activas,
    COUNT(CASE WHEN dm.estado_inscripcion = 'RETIRADO' THEN 1 END) as materias_retiradas,
    COUNT(CASE WHEN dm.estado_inscripcion = 'CANCELADO' THEN 1 END) as materias_canceladas
FROM MATRICULA m
JOIN ESTUDIANTE e ON m.cod_estudiante = e.cod_estudiante
JOIN PROGRAMA_ACADEMICO p ON e.cod_programa = p.cod_programa
LEFT JOIN DETALLE_MATRICULA dm ON m.cod_matricula = dm.cod_matricula
LEFT JOIN (
    SELECT g.cod_grupo, a.creditos
    FROM GRUPO g
    JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
) creditos_grupo ON dm.cod_grupo = creditos_grupo.cod_grupo
GROUP BY m.cod_periodo, p.nombre_programa, p.nivel_academico;

-- REPORTE 2: Ocupación de grupos por asignatura y periodo
CREATE OR REPLACE VIEW VW_OCUPACION_GRUPOS AS
SELECT 
    g.cod_periodo,
    a.cod_asignatura,
    a.nombre_asignatura,
    g.numero_grupo,
    d.primer_nombre || ' ' || d.primer_apellido as nombre_docente,
    g.cupo_maximo,
    (g.cupo_maximo - NVL(g.cupo_disponible, g.cupo_maximo)) as estudiantes_inscritos,
    g.cupo_disponible,
    CASE 
        WHEN g.cupo_disponible = 0 THEN 'LLENO'
        WHEN g.cupo_disponible <= 3 THEN 'CASI_LLENO'
        WHEN g.cupo_disponible > (g.cupo_maximo * 0.5) THEN 'BAJA_OCUPACION'
        ELSE 'DISPONIBLE'
    END as estado_ocupacion,
    ROUND(((g.cupo_maximo - NVL(g.cupo_disponible, g.cupo_maximo)) / g.cupo_maximo) * 100, 2) as porcentaje_ocupacion,
    g.modalidad,
    g.estado_grupo
FROM GRUPO g
JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
LEFT JOIN DOCENTE d ON g.cod_docente = d.cod_docente
WHERE g.estado_grupo = 'ACTIVO';

-- REPORTE 3: Carga académica detallada por estudiante
CREATE OR REPLACE VIEW VW_CARGA_ACADEMICA_ESTUDIANTE AS
SELECT 
    e.cod_estudiante,
    e.primer_nombre || ' ' || e.primer_apellido as nombre_estudiante,
    m.cod_periodo,
    p.nombre_programa,
    COUNT(dm.cod_detalle_matricula) as total_asignaturas,
    SUM(a.creditos) as total_creditos_inscritos,
    SUM(a.horas_teoricas + NVL(a.horas_practicas, 0)) as total_horas_semanales,
    hr.nivel_riesgo,
    hr.promedio_acumulado,
    CASE 
        WHEN hr.nivel_riesgo = 'ALTO' THEN 12
        WHEN hr.nivel_riesgo = 'MEDIO' THEN 15
        ELSE 18
    END as creditos_maximos_permitidos,
    CASE 
        WHEN SUM(a.creditos) > CASE 
            WHEN hr.nivel_riesgo = 'ALTO' THEN 12
            WHEN hr.nivel_riesgo = 'MEDIO' THEN 15
            ELSE 18
        END THEN 'EXCEDE_LIMITE'
        ELSE 'OK'
    END as estado_carga
FROM ESTUDIANTE e
JOIN MATRICULA m ON e.cod_estudiante = m.cod_estudiante
JOIN PROGRAMA_ACADEMICO p ON e.cod_programa = p.cod_programa
JOIN DETALLE_MATRICULA dm ON m.cod_matricula = dm.cod_matricula
JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
LEFT JOIN HISTORIAL_RIESGO hr ON e.cod_estudiante = hr.cod_estudiante 
    AND hr.cod_periodo = m.cod_periodo
WHERE dm.estado_inscripcion = 'CURSANDO'
GROUP BY e.cod_estudiante, e.primer_nombre, e.primer_apellido, m.cod_periodo, 
         p.nombre_programa, hr.nivel_riesgo, hr.promedio_acumulado;

-- REPORTE 4: Intentos fallidos de matrícula (prerequisitos)
CREATE OR REPLACE VIEW VW_INTENTOS_FALLIDOS_PRERREQUISITOS AS
SELECT 
    a.cod_auditoria,
    a.fecha_operacion,
    a.usuario_bd,
    REGEXP_SUBSTR(a.sentencia_sql, 'Estudiante: ([A-Z0-9]+)', 1, 1, NULL, 1) as cod_estudiante,
    REGEXP_SUBSTR(a.sentencia_sql, 'Asignatura: ([A-Z0-9]+)', 1, 1, NULL, 1) as cod_asignatura,
    asig.nombre_asignatura,
    a.sentencia_sql as mensaje_error,
    COUNT(*) OVER (PARTITION BY REGEXP_SUBSTR(a.sentencia_sql, 'Estudiante: ([A-Z0-9]+)', 1, 1, NULL, 1),
                                REGEXP_SUBSTR(a.sentencia_sql, 'Asignatura: ([A-Z0-9]+)', 1, 1, NULL, 1)) as intentos
FROM AUDITORIA a
LEFT JOIN ASIGNATURA asig ON REGEXP_SUBSTR(a.sentencia_sql, 'Asignatura: ([A-Z0-9]+)', 1, 1, NULL, 1) = asig.cod_asignatura
WHERE a.operacion = 'ERROR_PREREQUISITO'
OR a.sentencia_sql LIKE '%prerequisito%'
OR a.sentencia_sql LIKE '%prerrequisito%';

-- REPORTE 5: Asignaturas más inscritas por periodo
CREATE OR REPLACE VIEW VW_ASIGNATURAS_MAS_INSCRITAS AS
SELECT 
    g.cod_periodo,
    a.cod_asignatura,
    a.nombre_asignatura,
    a.tipo_asignatura,
    a.creditos,
    COUNT(DISTINCT dm.cod_detalle_matricula) as total_inscripciones,
    COUNT(DISTINCT g.cod_grupo) as numero_grupos_abiertos,
    ROUND(COUNT(DISTINCT dm.cod_detalle_matricula) / COUNT(DISTINCT g.cod_grupo), 2) as promedio_estudiantes_por_grupo,
    SUM(CASE WHEN dm.estado_inscripcion = 'CURSANDO' THEN 1 ELSE 0 END) as estudiantes_activos,
    SUM(CASE WHEN dm.estado_inscripcion = 'RETIRADO' THEN 1 ELSE 0 END) as estudiantes_retirados,
    ROUND((SUM(CASE WHEN dm.estado_inscripcion = 'RETIRADO' THEN 1 ELSE 0 END) / 
           NULLIF(COUNT(dm.cod_detalle_matricula), 0)) * 100, 2) as porcentaje_desercion
FROM GRUPO g
JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
LEFT JOIN DETALLE_MATRICULA dm ON g.cod_grupo = dm.cod_grupo
GROUP BY g.cod_periodo, a.cod_asignatura, a.nombre_asignatura, a.tipo_asignatura, a.creditos;

-- REPORTE 6: Histórico de matrículas por estudiante
CREATE OR REPLACE VIEW VW_HISTORICO_MATRICULAS_ESTUDIANTE AS
SELECT 
    e.cod_estudiante,
    e.primer_nombre || ' ' || e.primer_apellido as nombre_estudiante,
    e.correo_institucional,
    m.cod_periodo,
    COUNT(dm.cod_detalle_matricula) as asignaturas_inscritas,
    SUM(a.creditos) as creditos_periodo,
    SUM(CASE WHEN nd.resultado = 'APROBADO' THEN a.creditos ELSE 0 END) as creditos_aprobados,
    SUM(CASE WHEN nd.resultado IN ('REPROBADO','PERDIDA') THEN a.creditos ELSE 0 END) as creditos_reprobados,
    ROUND(AVG(nd.nota_final), 2) as promedio_periodo,
    SUM(CASE WHEN nd.resultado = 'APROBADO' THEN 1 ELSE 0 END) as materias_aprobadas,
    SUM(CASE WHEN nd.resultado IN ('REPROBADO','PERDIDA') THEN 1 ELSE 0 END) as materias_reprobadas
FROM ESTUDIANTE e
JOIN MATRICULA m ON e.cod_estudiante = m.cod_estudiante
JOIN DETALLE_MATRICULA dm ON m.cod_matricula = dm.cod_matricula
JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
LEFT JOIN NOTA_DEFINITIVA nd ON dm.cod_detalle_matricula = nd.cod_detalle_matricula
GROUP BY e.cod_estudiante, e.primer_nombre, e.primer_apellido, 
         e.correo_institucional, m.cod_periodo;

-- ============================================================
-- CATEGORÍA 2: RENDIMIENTO Y CALIFICACIONES (5 reportes)
-- ============================================================

-- REPORTE 7: Distribución de calificaciones por asignatura
CREATE OR REPLACE VIEW VW_DISTRIBUCION_CALIFICACIONES AS
SELECT 
    g.cod_periodo,
    a.cod_asignatura,
    a.nombre_asignatura,
    COUNT(DISTINCT nd.cod_nota_definitiva) as total_calificaciones,
    ROUND(AVG(nd.nota_final), 2) as nota_promedio,
    MIN(nd.nota_final) as nota_minima,
    MAX(nd.nota_final) as nota_maxima,
    ROUND(STDDEV(nd.nota_final), 2) as desviacion_estandar,
    SUM(CASE WHEN nd.nota_final >= 4.5 THEN 1 ELSE 0 END) as sobresalientes,
    SUM(CASE WHEN nd.nota_final >= 4.0 AND nd.nota_final < 4.5 THEN 1 ELSE 0 END) as buenos,
    SUM(CASE WHEN nd.nota_final >= 3.5 AND nd.nota_final < 4.0 THEN 1 ELSE 0 END) as aceptables,
    SUM(CASE WHEN nd.nota_final >= 3.0 AND nd.nota_final < 3.5 THEN 1 ELSE 0 END) as minimos,
    SUM(CASE WHEN nd.nota_final < 3.0 THEN 1 ELSE 0 END) as reprobados,
    ROUND((SUM(CASE WHEN nd.nota_final >= 3.0 THEN 1 ELSE 0 END) / 
           NULLIF(COUNT(nd.cod_nota_definitiva), 0)) * 100, 2) as porcentaje_aprobacion
FROM GRUPO g
JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
JOIN DETALLE_MATRICULA dm ON g.cod_grupo = dm.cod_grupo
LEFT JOIN NOTA_DEFINITIVA nd ON dm.cod_detalle_matricula = nd.cod_detalle_matricula
WHERE nd.nota_final IS NOT NULL
GROUP BY g.cod_periodo, a.cod_asignatura, a.nombre_asignatura;

-- REPORTE 8: Rendimiento académico por docente
CREATE OR REPLACE VIEW VW_RENDIMIENTO_POR_DOCENTE AS
SELECT 
    d.cod_docente,
    d.primer_nombre || ' ' || d.primer_apellido as nombre_docente,
    d.tipo_vinculacion,
    d.titulo_academico,
    g.cod_periodo,
    COUNT(DISTINCT g.cod_grupo) as grupos_dictados,
    COUNT(DISTINCT dm.cod_estudiante) as total_estudiantes,
    ROUND(AVG(nd.nota_final), 2) as promedio_notas,
    SUM(CASE WHEN nd.resultado = 'APROBADO' THEN 1 ELSE 0 END) as estudiantes_aprobados,
    SUM(CASE WHEN nd.resultado IN ('REPROBADO','PERDIDA') THEN 1 ELSE 0 END) as estudiantes_reprobados,
    ROUND((SUM(CASE WHEN nd.resultado = 'APROBADO' THEN 1 ELSE 0 END) / 
           NULLIF(COUNT(nd.cod_nota_definitiva), 0)) * 100, 2) as tasa_aprobacion,
    SUM(CASE WHEN dm.estado_inscripcion = 'RETIRADO' THEN 1 ELSE 0 END) as estudiantes_retirados,
    ROUND((SUM(CASE WHEN dm.estado_inscripcion = 'RETIRADO' THEN 1 ELSE 0 END) / 
           NULLIF(COUNT(dm.cod_detalle_matricula), 0)) * 100, 2) as tasa_desercion
FROM DOCENTE d
JOIN GRUPO g ON d.cod_docente = g.cod_docente
LEFT JOIN DETALLE_MATRICULA dm ON g.cod_grupo = dm.cod_grupo
LEFT JOIN NOTA_DEFINITIVA nd ON dm.cod_detalle_matricula = nd.cod_detalle_matricula
WHERE g.estado_grupo = 'ACTIVO'
GROUP BY d.cod_docente, d.primer_nombre, d.primer_apellido, 
         d.tipo_vinculacion, d.titulo_academico, g.cod_periodo;

-- REPORTE 9: Top 10 estudiantes por programa
CREATE OR REPLACE VIEW VW_TOP_ESTUDIANTES_PROGRAMA AS
SELECT * FROM (
    SELECT 
        p.nombre_programa,
        e.cod_estudiante,
        e.primer_nombre || ' ' || e.primer_apellido as nombre_estudiante,
        ROUND(AVG(nd.nota_final), 2) as promedio_acumulado,
        SUM(CASE WHEN nd.resultado = 'APROBADO' THEN a.creditos ELSE 0 END) as creditos_aprobados,
        COUNT(DISTINCT m.cod_periodo) as semestres_cursados,
        SUM(CASE WHEN nd.resultado = 'APROBADO' THEN 1 ELSE 0 END) as materias_aprobadas,
        SUM(CASE WHEN nd.resultado IN ('REPROBADO','PERDIDA') THEN 1 ELSE 0 END) as materias_reprobadas,
        ROW_NUMBER() OVER (PARTITION BY p.cod_programa ORDER BY AVG(nd.nota_final) DESC) as ranking
    FROM ESTUDIANTE e
    JOIN PROGRAMA_ACADEMICO p ON e.cod_programa = p.cod_programa
    JOIN MATRICULA m ON e.cod_estudiante = m.cod_estudiante
    JOIN DETALLE_MATRICULA dm ON m.cod_matricula = dm.cod_matricula
    JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
    JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
    LEFT JOIN NOTA_DEFINITIVA nd ON dm.cod_detalle_matricula = nd.cod_detalle_matricula
    WHERE nd.nota_final IS NOT NULL
    AND e.estado_estudiante = 'ACTIVO'
    GROUP BY p.nombre_programa, p.cod_programa, e.cod_estudiante, 
             e.primer_nombre, e.primer_apellido
)
WHERE ranking <= 10;

-- REPORTE 10: Asignaturas con mayor índice de reprobación
CREATE OR REPLACE VIEW VW_ASIGNATURAS_MAYOR_REPROBACION AS
SELECT 
    a.cod_asignatura,
    a.nombre_asignatura,
    a.tipo_asignatura,
    a.creditos,
    COUNT(nd.cod_nota_definitiva) as total_evaluaciones,
    SUM(CASE WHEN nd.resultado IN ('REPROBADO','PERDIDA') THEN 1 ELSE 0 END) as total_reprobados,
    ROUND((SUM(CASE WHEN nd.resultado IN ('REPROBADO','PERDIDA') THEN 1 ELSE 0 END) / 
           NULLIF(COUNT(nd.cod_nota_definitiva), 0)) * 100, 2) as porcentaje_reprobacion,
    ROUND(AVG(nd.nota_final), 2) as nota_promedio,
    COUNT(DISTINCT g.cod_docente) as docentes_diferentes,
    COUNT(DISTINCT g.cod_periodo) as periodos_dictada
FROM ASIGNATURA a
JOIN GRUPO g ON a.cod_asignatura = g.cod_asignatura
JOIN DETALLE_MATRICULA dm ON g.cod_grupo = dm.cod_grupo
LEFT JOIN NOTA_DEFINITIVA nd ON dm.cod_detalle_matricula = nd.cod_detalle_matricula
WHERE nd.nota_final IS NOT NULL
GROUP BY a.cod_asignatura, a.nombre_asignatura, a.tipo_asignatura, a.creditos
HAVING COUNT(nd.cod_nota_definitiva) >= 5
ORDER BY porcentaje_reprobacion DESC;

-- REPORTE 11: Progreso académico por cohorte
CREATE OR REPLACE VIEW VW_PROGRESO_POR_COHORTE AS
SELECT 
    EXTRACT(YEAR FROM e.fecha_ingreso) as cohorte,
    p.nombre_programa,
    COUNT(DISTINCT e.cod_estudiante) as total_estudiantes,
    ROUND(AVG(creditos_est.creditos_aprobados), 2) as promedio_creditos_aprobados,
    ROUND(AVG(creditos_est.promedio_acumulado), 2) as promedio_general_cohorte,
    SUM(CASE WHEN e.estado_estudiante = 'ACTIVO' THEN 1 ELSE 0 END) as estudiantes_activos,
    SUM(CASE WHEN e.estado_estudiante = 'GRADUADO' THEN 1 ELSE 0 END) as estudiantes_graduados,
    SUM(CASE WHEN e.estado_estudiante = 'RETIRADO' THEN 1 ELSE 0 END) as estudiantes_retirados,
    ROUND((SUM(CASE WHEN e.estado_estudiante = 'GRADUADO' THEN 1 ELSE 0 END) / 
           NULLIF(COUNT(e.cod_estudiante), 0)) * 100, 2) as tasa_graduacion,
    ROUND((SUM(CASE WHEN e.estado_estudiante = 'RETIRADO' THEN 1 ELSE 0 END) / 
           NULLIF(COUNT(e.cod_estudiante), 0)) * 100, 2) as tasa_desercion
FROM ESTUDIANTE e
JOIN PROGRAMA_ACADEMICO p ON e.cod_programa = p.cod_programa
LEFT JOIN (
    SELECT 
        m.cod_estudiante,
        SUM(CASE WHEN nd.resultado = 'APROBADO' THEN a.creditos ELSE 0 END) as creditos_aprobados,
        ROUND(AVG(nd.nota_final), 2) as promedio_acumulado
    FROM MATRICULA m
    JOIN DETALLE_MATRICULA dm ON m.cod_matricula = dm.cod_matricula
    JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
    JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
    LEFT JOIN NOTA_DEFINITIVA nd ON dm.cod_detalle_matricula = nd.cod_detalle_matricula
    WHERE nd.nota_final IS NOT NULL
    GROUP BY m.cod_estudiante
) creditos_est ON e.cod_estudiante = creditos_est.cod_estudiante
GROUP BY EXTRACT(YEAR FROM e.fecha_ingreso), p.nombre_programa;

-- ============================================================
-- CATEGORÍA 3: RIESGO ACADÉMICO (4 reportes)
-- ============================================================

-- REPORTE 12: Estudiantes en riesgo académico
CREATE OR REPLACE VIEW VW_ESTUDIANTES_RIESGO AS
SELECT 
    e.cod_estudiante,
    e.primer_nombre || ' ' || e.primer_apellido as nombre_estudiante,
    e.correo_institucional,
    p.nombre_programa,
    hr.cod_periodo,
    hr.nivel_riesgo,
    hr.promedio_acumulado,
    hr.creditos_aprobados,
    hr.creditos_reprobados,
    hr.porcentaje_avance,
    hr.materias_perdidas_periodo,
    hr.descripcion_estado,
    hr.fecha_calculo,
    CASE 
        WHEN hr.nivel_riesgo = 'ALTO' THEN 'ASESORÍA INMEDIATA'
        WHEN hr.nivel_riesgo = 'MEDIO' THEN 'SEGUIMIENTO'
        ELSE 'MONITOREO'
    END as accion_recomendada
FROM ESTUDIANTE e
JOIN PROGRAMA_ACADEMICO p ON e.cod_programa = p.cod_programa
JOIN HISTORIAL_RIESGO hr ON e.cod_estudiante = hr.cod_estudiante
WHERE hr.nivel_riesgo IN ('ALTO', 'MEDIO')
AND e.estado_estudiante = 'ACTIVO'
ORDER BY 
    CASE hr.nivel_riesgo 
        WHEN 'ALTO' THEN 1 
        WHEN 'MEDIO' THEN 2 
        ELSE 3 
    END,
    hr.promedio_acumulado;

-- REPORTE 13: Evolución del riesgo por estudiante
CREATE OR REPLACE VIEW VW_EVOLUCION_RIESGO AS
SELECT 
    hr.cod_estudiante,
    e.primer_nombre || ' ' || e.primer_apellido as nombre_estudiante,
    hr.cod_periodo,
    hr.nivel_riesgo,
    hr.promedio_acumulado,
    LAG(hr.nivel_riesgo) OVER (PARTITION BY hr.cod_estudiante ORDER BY hr.cod_periodo) as riesgo_anterior,
    LAG(hr.promedio_acumulado) OVER (PARTITION BY hr.cod_estudiante ORDER BY hr.cod_periodo) as promedio_anterior,
    hr.promedio_acumulado - LAG(hr.promedio_acumulado) OVER (PARTITION BY hr.cod_estudiante ORDER BY hr.cod_periodo) as variacion_promedio,
    CASE 
        WHEN hr.nivel_riesgo = LAG(hr.nivel_riesgo) OVER (PARTITION BY hr.cod_estudiante ORDER BY hr.cod_periodo) 
        THEN 'ESTABLE'
        WHEN hr.nivel_riesgo < LAG(hr.nivel_riesgo) OVER (PARTITION BY hr.cod_estudiante ORDER BY hr.cod_periodo) 
        THEN 'MEJORA'
        ELSE 'DETERIORO'
    END as tendencia
FROM HISTORIAL_RIESGO hr
JOIN ESTUDIANTE e ON hr.cod_estudiante = e.cod_estudiante
WHERE e.estado_estudiante = 'ACTIVO';

-- REPORTE 14: Alertas tempranas por periodo
CREATE OR REPLACE VIEW VW_ALERTAS_TEMPRANAS AS
SELECT 
    TO_CHAR(a.fecha_operacion, 'YYYY-MM') as periodo_alerta,
    COUNT(*) as total_alertas,
    COUNT(DISTINCT REGEXP_SUBSTR(a.sentencia_sql, 'Estudiante ([A-Z0-9]+)', 1, 1, NULL, 1)) as estudiantes_afectados,
    SUM(CASE WHEN a.sentencia_sql LIKE '%2 calificaciones bajas%' THEN 1 ELSE 0 END) as alertas_2_materias,
    SUM(CASE WHEN a.sentencia_sql LIKE '%3 calificaciones bajas%' THEN 1 ELSE 0 END) as alertas_3_materias,
    SUM(CASE WHEN a.sentencia_sql LIKE '%4 calificaciones bajas%' OR a.sentencia_sql LIKE '%[4-9] calificaciones bajas%' THEN 1 ELSE 0 END) as alertas_criticas
FROM AUDITORIA a
WHERE a.operacion = 'ALERTA_TEMPRANA'
GROUP BY TO_CHAR(a.fecha_operacion, 'YYYY-MM')
ORDER BY periodo_alerta DESC;

-- REPORTE 15: Comparativo de riesgo por programa
CREATE OR REPLACE VIEW VW_RIESGO_POR_PROGRAMA AS
SELECT 
    p.nombre_programa,
    hr.cod_periodo,
    COUNT(DISTINCT hr.cod_estudiante) as total_estudiantes,
    SUM(CASE WHEN hr.nivel_riesgo = 'ALTO' THEN 1 ELSE 0 END) as riesgo_alto,
    SUM(CASE WHEN hr.nivel_riesgo = 'MEDIO' THEN 1 ELSE 0 END) as riesgo_medio,
    SUM(CASE WHEN hr.nivel_riesgo = 'BAJO' THEN 1 ELSE 0 END) as riesgo_bajo,
    SUM(CASE WHEN hr.nivel_riesgo = 'SIN_RIESGO' THEN 1 ELSE 0 END) as sin_riesgo,
    ROUND((SUM(CASE WHEN hr.nivel_riesgo = 'ALTO' THEN 1 ELSE 0 END) / 
           NULLIF(COUNT(hr.cod_estudiante), 0)) * 100, 2) as porcentaje_riesgo_alto,
    ROUND(AVG(hr.promedio_acumulado), 2) as promedio_programa
FROM PROGRAMA_ACADEMICO p
JOIN ESTUDIANTE e ON p.cod_programa = e.cod_programa
JOIN HISTORIAL_RIESGO hr ON e.cod_estudiante = hr.cod_estudiante
GROUP BY p.nombre_programa, hr.cod_periodo;

-- ============================================================
-- CATEGORÍA 4: DOCENTES Y RECURSOS (3 reportes)
-- ============================================================

-- REPORTE 16: Carga horaria docente
CREATE OR REPLACE VIEW VW_CARGA_HORARIA_DOCENTE AS
SELECT 
    d.cod_docente,
    d.primer_nombre || ' ' || d.primer_apellido as nombre_docente,
    d.tipo_vinculacion,
    g.cod_periodo,
    COUNT(DISTINCT g.cod_grupo) as grupos_asignados,
    SUM(a.horas_teoricas + NVL(a.horas_practicas, 0)) as total_horas_semanales,
    SUM(g.cupo_maximo - NVL(g.cupo_disponible, g.cupo_maximo)) as total_estudiantes,
    CASE 
        WHEN d.tipo_vinculacion = 'TIEMPO_COMPLETO' THEN 20
        WHEN d.tipo_vinculacion = 'MEDIO_TIEMPO' THEN 10
        WHEN d.tipo_vinculacion = 'CATEDRA' THEN 12
        ELSE 20
    END as horas_maximas,
    CASE 
        WHEN SUM(a.horas_teoricas + NVL(a.horas_practicas, 0)) >= 
            CASE 
                WHEN d.tipo_vinculacion = 'TIEMPO_COMPLETO' THEN 20
                WHEN d.tipo_vinculacion = 'MEDIO_TIEMPO' THEN 10
                WHEN d.tipo_vinculacion = 'CATEDRA' THEN 12
                ELSE 20
            END 
        THEN 'EN_LIMITE'
        WHEN SUM(a.horas_teoricas + NVL(a.horas_practicas, 0)) > 
            CASE 
                WHEN d.tipo_vinculacion = 'TIEMPO_COMPLETO' THEN 20
                WHEN d.tipo_vinculacion = 'MEDIO_TIEMPO' THEN 10
                WHEN d.tipo_vinculacion = 'CATEDRA' THEN 12
                ELSE 20
            END * 0.8
        THEN 'ALTA_CARGA'
        ELSE 'NORMAL'
    END as estado_carga,
    ROUND((SUM(a.horas_teoricas + NVL(a.horas_practicas, 0)) / 
           CASE 
               WHEN d.tipo_vinculacion = 'TIEMPO_COMPLETO' THEN 20
               WHEN d.tipo_vinculacion = 'MEDIO_TIEMPO' THEN 10
               WHEN d.tipo_vinculacion = 'CATEDRA' THEN 12
               ELSE 20
           END) * 100, 2) as porcentaje_carga
FROM DOCENTE d
JOIN GRUPO g ON d.cod_docente = g.cod_docente
JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
WHERE g.estado_grupo = 'ACTIVO'
AND d.estado_docente = 'ACTIVO'
GROUP BY d.cod_docente, d.primer_nombre, d.primer_apellido, 
         d.tipo_vinculacion, g.cod_periodo;

-- REPORTE 17: Asignaturas sin docente asignado
CREATE OR REPLACE VIEW VW_GRUPOS_SIN_DOCENTE AS
SELECT 
    g.cod_periodo,
    a.cod_asignatura,
    a.nombre_asignatura,
    g.numero_grupo,
    g.cupo_maximo,
    g.modalidad,
    g.estado_grupo,
    CASE 
        WHEN g.cupo_disponible < g.cupo_maximo THEN 'CON_ESTUDIANTES'
        ELSE 'SIN_ESTUDIANTES'
    END as estado_inscripciones,
    g.fecha_registro
FROM GRUPO g
JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
WHERE g.cod_docente IS NULL
AND g.estado_grupo = 'ACTIVO'
ORDER BY g.cod_periodo DESC, g.fecha_registro;

-- REPORTE 18: Ventanas de calendario activas
CREATE OR REPLACE VIEW VW_VENTANAS_CALENDARIO_ACTIVAS AS
SELECT 
    vc.cod_ventana_calendario,
    vc.cod_periodo,
    vc.tipo_ventana,
    vc.nombre_ventana,
    vc.descripcion,
    vc.fecha_inicio,
    vc.fecha_fin,
    vc.estado_ventana,
    TRUNC(vc.fecha_fin - SYSDATE) as dias_restantes,
    CASE 
        WHEN SYSDATE < vc.fecha_inicio THEN 'PROXIMA'
        WHEN SYSDATE BETWEEN vc.fecha_inicio AND vc.fecha_fin THEN 'ACTIVA'
        WHEN SYSDATE > vc.fecha_fin THEN 'CERRADA'
        ELSE 'INDEFINIDA'
    END as estado_actual,
    CASE 
        WHEN SYSDATE BETWEEN vc.fecha_inicio AND vc.fecha_fin AND TRUNC(vc.fecha_fin - SYSDATE) <= 3 
        THEN 'POR_CERRAR'
        WHEN SYSDATE < vc.fecha_inicio AND TRUNC(vc.fecha_inicio - SYSDATE) <= 3 
        THEN 'POR_ABRIR'
        ELSE 'NORMAL'
    END as alerta
FROM VENTANA_CALENDARIO vc
WHERE vc.estado_ventana = 'ACTIVA'
OR SYSDATE BETWEEN vc.fecha_inicio AND vc.fecha_fin
ORDER BY vc.fecha_inicio;

-- ============================================================
-- VERIFICACIÓN DE VISTAS CREADAS
-- ============================================================
PROMPT ============================================================
PROMPT Vistas (Reportes) creadas exitosamente:
PROMPT ============================================================

SELECT view_name, text_length
FROM USER_VIEWS
WHERE view_name LIKE 'VW_%'
ORDER BY view_name;

PROMPT 
PROMPT ============================================================
PROMPT Total de reportes disponibles:
PROMPT ============================================================

SELECT COUNT(*) as total_reportes
FROM USER_VIEWS
WHERE view_name LIKE 'VW_%';

COMMIT;
