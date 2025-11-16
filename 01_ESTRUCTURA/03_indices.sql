-- =====================================================
-- SISTEMA ACADÉMICO - ORACLE DATABASE 19c
-- Script: 03_indices.sql
-- Propósito: Creación de índices para optimización
-- Autor: Sistema Académico
-- Fecha: 28/10/2025
-- =====================================================

-- =====================================================
-- ÍNDICES DE CLAVES PRIMARIAS (UNIQUE)
-- Justificación: Oracle crea automáticamente índices únicos
-- cuando se define una constraint PRIMARY KEY en 02_tablas.sql.
-- No es necesario (ni posible) crearlos explícitamente.
-- Intentar recrearlos causaría error ORA-00955: el nombre ya está siendo usado.
-- Oracle Database 19c gestiona estos índices automáticamente.
-- =====================================================

-- IMPORTANTE: Oracle crea automáticamente índices únicos para PRIMARY KEY
-- No crear explícitamente: PK_FACULTAD, PK_PROGRAMA_ACADEMICO, PK_ESTUDIANTE,
-- PK_DOCENTE, PK_ASIGNATURA, PK_MATRICULA, PK_GRUPO, PK_DETALLE_MATRICULA,
-- PK_CALIFICACION, PK_AUDITORIA, etc.
-- Los índices PK ya existen en el tablespace por defecto del usuario

-- =====================================================
-- ÍNDICES DE CLAVES FORÁNEAS (NO UNIQUE)
-- Justificación: Mejoran drásticamente el rendimiento de JOIN
-- y queries con WHERE sobre relaciones
-- =====================================================

-- Relación PROGRAMA_ACADEMICO -> FACULTAD
CREATE INDEX IDX_PROGRAMA_FACULTAD ON PROGRAMA_ACADEMICO(cod_facultad)
TABLESPACE TBS_INDICES;
-- Justificación: Acelera consultas de programas por facultad

-- Relación ESTUDIANTE -> PROGRAMA_ACADEMICO
CREATE INDEX IDX_ESTUDIANTE_PROGRAMA ON ESTUDIANTE(cod_programa)
TABLESPACE TBS_INDICES;
-- Justificación: Optimiza reportes de estudiantes por programa

-- Relación DOCENTE -> FACULTAD
CREATE INDEX IDX_DOCENTE_FACULTAD ON DOCENTE(cod_facultad)
TABLESPACE TBS_INDICES;
-- Justificación: Mejora consultas de docentes por facultad

-- Relación ASIGNATURA -> PROGRAMA_ACADEMICO
CREATE INDEX IDX_ASIGNATURA_PROGRAMA ON ASIGNATURA(cod_programa)
TABLESPACE TBS_INDICES;
-- Justificación: Acelera consultas de plan de estudios

-- Relación PRERREQUISITO -> ASIGNATURA
CREATE INDEX IDX_PREREQ_ASIGNATURA ON PRERREQUISITO(cod_asignatura)
TABLESPACE TBS_INDICES;
-- Justificación: Optimiza validación de prerrequisitos al matricular

CREATE INDEX IDX_PREREQ_REQUISITO ON PRERREQUISITO(cod_asignatura_requisito)
TABLESPACE TBS_INDICES;
-- Justificación: Permite búsqueda inversa de asignaturas que dependen de otra

-- Relación GRUPO -> ASIGNATURA, PERIODO, DOCENTE
CREATE INDEX IDX_GRUPO_ASIGNATURA ON GRUPO(cod_asignatura)
TABLESPACE TBS_INDICES;
-- Justificación: Acelera consultas de grupos por asignatura

CREATE INDEX IDX_GRUPO_PERIODO ON GRUPO(cod_periodo)
TABLESPACE TBS_INDICES;
-- Justificación: Optimiza listado de grupos ofertados por periodo

CREATE INDEX IDX_GRUPO_DOCENTE ON GRUPO(cod_docente)
TABLESPACE TBS_INDICES;
-- Justificación: Mejora consultas de carga académica por docente

-- Relación HORARIO -> GRUPO
CREATE INDEX IDX_HORARIO_GRUPO ON HORARIO(cod_grupo)
TABLESPACE TBS_INDICES;
-- Justificación: Acelera consultas de horarios por grupo

-- Relación MATRICULA -> ESTUDIANTE, PERIODO
CREATE INDEX IDX_MATRICULA_ESTUDIANTE ON MATRICULA(cod_estudiante)
TABLESPACE TBS_INDICES;
-- Justificación: Acelera consultas de historial de matrícula por estudiante

CREATE INDEX IDX_MATRICULA_PERIODO ON MATRICULA(cod_periodo)
TABLESPACE TBS_INDICES;
-- Justificación: Optimiza reportes de matrícula por periodo

-- Relación DETALLE_MATRICULA -> MATRICULA, GRUPO
CREATE INDEX IDX_DETALLE_MATRICULA ON DETALLE_MATRICULA(cod_matricula)
TABLESPACE TBS_INDICES;
-- Justificación: Mejora acceso a asignaturas matriculadas

CREATE INDEX IDX_DETALLE_GRUPO ON DETALLE_MATRICULA(cod_grupo)
TABLESPACE TBS_INDICES;
-- Justificación: Optimiza consultas de estudiantes por grupo

-- Relación REGLA_EVALUACION -> ASIGNATURA, TIPO_ACTIVIDAD
CREATE INDEX IDX_REGLA_ASIGNATURA ON REGLA_EVALUACION(cod_asignatura)
TABLESPACE TBS_INDICES;
-- Justificación: Acelera consulta de reglas de evaluación por asignatura

CREATE INDEX IDX_REGLA_TIPO_ACTIVIDAD ON REGLA_EVALUACION(cod_tipo_actividad)
TABLESPACE TBS_INDICES;
-- Justificación: Permite búsqueda de asignaturas por tipo de evaluación

-- Relación CALIFICACION -> DETALLE_MATRICULA, TIPO_ACTIVIDAD
CREATE INDEX IDX_CALIFICACION_DETALLE ON CALIFICACION(cod_detalle_matricula)
TABLESPACE TBS_INDICES;
-- Justificación: Mejora velocidad en reportes de calificaciones por estudiante

CREATE INDEX IDX_CALIFICACION_TIPO ON CALIFICACION(cod_tipo_actividad)
TABLESPACE TBS_INDICES;
-- Justificación: Optimiza consultas de notas por tipo de actividad

-- Relación NOTA_DEFINITIVA -> DETALLE_MATRICULA
CREATE INDEX IDX_NOTA_DEF_DETALLE ON NOTA_DEFINITIVA(cod_detalle_matricula)
TABLESPACE TBS_INDICES;
-- Justificación: Acelera cálculo de promedio general del estudiante

-- Relación HISTORIAL_RIESGO -> ESTUDIANTE, PERIODO
CREATE INDEX IDX_RIESGO_ESTUDIANTE ON HISTORIAL_RIESGO(cod_estudiante)
TABLESPACE TBS_INDICES;
-- Justificación: Mejora consultas de historial de riesgo académico

CREATE INDEX IDX_RIESGO_PERIODO ON HISTORIAL_RIESGO(cod_periodo)
TABLESPACE TBS_INDICES;
-- Justificación: Optimiza reportes de riesgo por periodo

-- Relación USUARIO_SISTEMA (sin FK pero con búsquedas frecuentes)
CREATE INDEX IDX_USUARIO_TIPO ON USUARIO_SISTEMA(tipo_usuario)
TABLESPACE TBS_INDICES;
-- Justificación: Acelera búsquedas de usuarios por rol

-- Relación LOG_ACCESO -> USUARIO_SISTEMA
CREATE INDEX IDX_LOG_USUARIO ON LOG_ACCESO(cod_usuario)
TABLESPACE TBS_INDICES;
-- Justificación: Optimiza consultas de histórico de acceso por usuario

-- Relación DIRECTOR_TRABAJO_GRADO -> ESTUDIANTE, DOCENTE
CREATE INDEX IDX_TRABAJO_ESTUDIANTE ON DIRECTOR_TRABAJO_GRADO(cod_estudiante)
TABLESPACE TBS_INDICES;
-- Justificación: Acelera consulta de trabajos por estudiante

CREATE INDEX IDX_TRABAJO_DOCENTE ON DIRECTOR_TRABAJO_GRADO(cod_docente)
TABLESPACE TBS_INDICES;
-- Justificación: Mejora consultas de trabajos dirigidos por docente

-- =====================================================
-- ÍNDICES DE CAMPOS ÚNICOS ADICIONALES (UNIQUE)
-- Justificación: Garantizan integridad y aceleran búsquedas
-- =====================================================

-- FACULTAD: Sigla única
CREATE UNIQUE INDEX UK_FACULTAD_SIGLA ON FACULTAD(sigla)
TABLESPACE TBS_INDICES;
-- Justificación: Permite búsqueda rápida por sigla

-- PROGRAMA_ACADEMICO: Código SNIES único
CREATE UNIQUE INDEX UK_PROGRAMA_SNIES ON PROGRAMA_ACADEMICO(codigo_snies)
TABLESPACE TBS_INDICES;
-- Justificación: Validación contra registro SNIES

-- ESTUDIANTE: Número de documento único
CREATE UNIQUE INDEX UK_ESTUDIANTE_DOC ON ESTUDIANTE(num_documento)
TABLESPACE TBS_INDICES;
-- Justificación: Evita duplicación de estudiantes

CREATE UNIQUE INDEX UK_ESTUDIANTE_EMAIL ON ESTUDIANTE(correo_institucional)
TABLESPACE TBS_INDICES;
-- Justificación: Garantiza unicidad de correos institucionales

-- DOCENTE: Número de documento único
CREATE UNIQUE INDEX UK_DOCENTE_DOC ON DOCENTE(num_documento)
TABLESPACE TBS_INDICES;
-- Justificación: Previene duplicación de docentes

CREATE UNIQUE INDEX UK_DOCENTE_EMAIL ON DOCENTE(correo_institucional)
TABLESPACE TBS_INDICES;
-- Justificación: Asegura unicidad de correos institucionales

-- TIPO_ACTIVIDAD_EVALUATIVA: Nombre único
CREATE UNIQUE INDEX UK_TIPO_ACTIVIDAD ON TIPO_ACTIVIDAD_EVALUATIVA(nombre_actividad)
TABLESPACE TBS_INDICES;
-- Justificación: Evita duplicación de tipos de actividad

-- USUARIO_SISTEMA: Username único
CREATE UNIQUE INDEX UK_USUARIO_USERNAME ON USUARIO_SISTEMA(username)
TABLESPACE TBS_INDICES;
-- Justificación: Acelera autenticación

CREATE UNIQUE INDEX UK_USUARIO_EMAIL ON USUARIO_SISTEMA(correo_electronico)
TABLESPACE TBS_INDICES;
-- Justificación: Recuperación de contraseña y notificaciones

-- MATRICULA: Estudiante-Periodo único
CREATE UNIQUE INDEX UK_MATRICULA_EST_PER ON MATRICULA(cod_estudiante, cod_periodo)
TABLESPACE TBS_INDICES;
-- Justificación: Previene múltiples matrículas en el mismo periodo

-- GRUPO: Asignatura-Periodo-Número único
CREATE UNIQUE INDEX UK_GRUPO_UNICO ON GRUPO(cod_asignatura, cod_periodo, numero_grupo)
TABLESPACE TBS_INDICES;
-- Justificación: Garantiza numeración única de grupos

-- DETALLE_MATRICULA: Matrícula-Grupo único
CREATE UNIQUE INDEX UK_DETALLE_MAT_GRUPO ON DETALLE_MATRICULA(cod_matricula, cod_grupo)
TABLESPACE TBS_INDICES;
-- Justificación: Previene inscripción duplicada al mismo grupo

-- =====================================================
-- ÍNDICES COMPUESTOS PARA BÚSQUEDAS FRECUENTES
-- Justificación: Optimizan queries con múltiples condiciones
-- =====================================================

-- Búsqueda de estudiantes activos por programa
CREATE INDEX IDX_EST_PROGRAMA_ESTADO ON ESTUDIANTE(cod_programa, estado_estudiante)
TABLESPACE TBS_INDICES;
-- Justificación: Reportes de estudiantes activos por programa

-- Búsqueda de docentes activos por facultad
CREATE INDEX IDX_DOC_FACULTAD_ESTADO ON DOCENTE(cod_facultad, estado_docente)
TABLESPACE TBS_INDICES;
-- Justificación: Listado de docentes disponibles por facultad

-- Búsqueda de grupos por periodo y estado
CREATE INDEX IDX_GRUPO_PERIODO_ESTADO ON GRUPO(cod_periodo, estado_grupo)
TABLESPACE TBS_INDICES;
-- Justificación: Grupos disponibles para matrícula

-- Búsqueda de matrículas activas por periodo
CREATE INDEX IDX_MAT_PERIODO_ESTADO ON MATRICULA(cod_periodo, estado_matricula)
TABLESPACE TBS_INDICES;
-- Justificación: Consolidados de matrícula activa por periodo

-- Búsqueda de calificaciones para cálculo de definitiva
CREATE INDEX IDX_CALIF_DET_TIPO ON CALIFICACION(cod_detalle_matricula, cod_tipo_actividad)
TABLESPACE TBS_INDICES;
-- Justificación: Acelera cálculo de nota definitiva

-- Búsqueda de riesgo por nivel y periodo
CREATE INDEX IDX_RIESGO_NIVEL_PERIODO ON HISTORIAL_RIESGO(nivel_riesgo, cod_periodo)
TABLESPACE TBS_INDICES;
-- Justificación: Reportes de estudiantes en riesgo crítico

-- Búsqueda de auditoría por tabla y fecha
CREATE INDEX IDX_AUDITORIA_TABLA_FECHA ON AUDITORIA(tabla_afectada, fecha_operacion)
TABLESPACE TBS_INDICES;
-- Justificación: Consultas de auditoría por tabla específica

-- Búsqueda de accesos fallidos por fecha
CREATE INDEX IDX_LOG_RESULTADO_FECHA ON LOG_ACCESO(resultado_acceso, fecha_acceso)
TABLESPACE TBS_INDICES;
-- Justificación: Detección de intentos de intrusión

-- =====================================================
-- ÍNDICES FUNCIONALES (FUNCTION-BASED)
-- Justificación: Optimizan búsquedas case-insensitive
-- =====================================================

-- Búsqueda de estudiantes por nombre (case-insensitive)
CREATE INDEX IDX_EST_NOMBRE_UPPER ON ESTUDIANTE(UPPER(primer_nombre), UPPER(primer_apellido))
TABLESPACE TBS_INDICES;
-- Justificación: Búsqueda de estudiantes sin importar mayúsculas/minúsculas

-- Búsqueda de docentes por nombre (case-insensitive)
CREATE INDEX IDX_DOC_NOMBRE_UPPER ON DOCENTE(UPPER(primer_nombre), UPPER(primer_apellido))
TABLESPACE TBS_INDICES;
-- Justificación: Búsqueda de docentes sin importar mayúsculas/minúsculas

-- Búsqueda de asignaturas por nombre
CREATE INDEX IDX_ASIG_NOMBRE_UPPER ON ASIGNATURA(UPPER(nombre_asignatura))
TABLESPACE TBS_INDICES;
-- Justificación: Búsqueda de asignaturas por nombre parcial

-- =====================================================
-- ÍNDICES DE FECHA PARA REPORTES
-- Justificación: Optimizan queries de análisis temporal
-- =====================================================

-- Fecha de matrícula para reportes estadísticos
CREATE INDEX IDX_MATRICULA_FECHA ON MATRICULA(fecha_matricula)
TABLESPACE TBS_INDICES;
-- Justificación: Análisis de tendencias de matrícula

-- Fecha de operación en auditoría
CREATE INDEX IDX_AUDITORIA_FECHA ON AUDITORIA(fecha_operacion)
TABLESPACE TBS_INDICES;
-- Justificación: Consultas de auditoría por rango de fechas

-- Fecha de acceso al sistema
CREATE INDEX IDX_LOG_FECHA ON LOG_ACCESO(fecha_acceso)
TABLESPACE TBS_INDICES;
-- Justificación: Análisis de patrones de uso del sistema

-- Fecha de detección de riesgo
CREATE INDEX IDX_RIESGO_FECHA ON HISTORIAL_RIESGO(fecha_deteccion)
TABLESPACE TBS_INDICES;
-- Justificación: Seguimiento temporal de casos de riesgo

-- =====================================================
-- ÍNDICES BITMAP (para columnas de baja cardinalidad)
-- Justificación: Eficientes para columnas con pocos valores distintos
-- =====================================================

-- Estado de estudiante (solo 5 valores posibles)
CREATE BITMAP INDEX BMP_ESTUDIANTE_ESTADO ON ESTUDIANTE(estado_estudiante)
TABLESPACE TBS_INDICES;
-- Justificación: Filtros frecuentes por estado con baja cardinalidad

-- Estado de docente
CREATE BITMAP INDEX BMP_DOCENTE_ESTADO ON DOCENTE(estado_docente)
TABLESPACE TBS_INDICES;
-- Justificación: Eficiente para filtrar docentes activos/inactivos

-- Tipo de programa académico
CREATE BITMAP INDEX BMP_PROGRAMA_TIPO ON PROGRAMA_ACADEMICO(tipo_programa)
TABLESPACE TBS_INDICES;
-- Justificación: Reportes por tipo de programa (pregrado/posgrado)

-- Estado de grupo
CREATE BITMAP INDEX BMP_GRUPO_ESTADO ON GRUPO(estado_grupo)
TABLESPACE TBS_INDICES;
-- Justificación: Filtro de grupos disponibles

-- Estado de matrícula
CREATE BITMAP INDEX BMP_MATRICULA_ESTADO ON MATRICULA(estado_matricula)
TABLESPACE TBS_INDICES;
-- Justificación: Consultas de matrículas activas/canceladas

-- Resultado en LOG_ACCESO
CREATE BITMAP INDEX BMP_LOG_RESULTADO ON LOG_ACCESO(resultado_acceso)
TABLESPACE TBS_INDICES;
-- Justificación: Análisis de accesos exitosos vs fallidos

-- Nivel de riesgo
CREATE BITMAP INDEX BMP_RIESGO_NIVEL ON HISTORIAL_RIESGO(nivel_riesgo)
TABLESPACE TBS_INDICES;
-- Justificación: Filtros por nivel de riesgo académico

-- =====================================================
-- VERIFICACIÓN DE ÍNDICES CREADOS
-- =====================================================
SELECT 
    index_name,
    table_name,
    uniqueness,
    index_type,
    tablespace_name,
    status
FROM user_indexes
WHERE tablespace_name = 'TBS_INDICES'
ORDER BY table_name, index_name;

PROMPT '========================================='
PROMPT 'Índices creados exitosamente'
PROMPT 'Total de índices en TBS_INDICES:'
PROMPT '========================================='

SELECT COUNT(*) AS total_indices
FROM user_indexes
WHERE tablespace_name = 'TBS_INDICES';
