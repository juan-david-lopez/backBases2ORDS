-- =====================================================
-- SISTEMA ACADÉMICO - ORACLE DATABASE 19c
-- Script: 01_tablespaces.sql
-- Propósito: Creación de tablespaces especializados
-- Autor: Sistema Académico
-- =====================================================

-- =====================================================
-- TABLESPACE: TBS_MAESTROS
-- Justificación: Almacena datos maestros estáticos que 
-- cambian con poca frecuencia (FACULTAD, PROGRAMA_ACADEMICO, 
-- DOCENTE, ESTUDIANTE). Se configura con AUTOEXTEND para 
-- crecimiento controlado y LOGGING para recuperación completa.
-- Tamaño inicial: 100MB, incrementos de 50MB
-- =====================================================
CREATE TABLESPACE TBS_MAESTROS
DATAFILE 'C:\APP\MURDE\PRODUCT\21C\DBHOMEXE\DATABASE\tbs_maestros01.dbf' 
SIZE 100M
AUTOEXTEND ON NEXT 50M MAXSIZE 2G
LOGGING
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
SEGMENT SPACE MANAGEMENT AUTO;

-- =====================================================
-- TABLESPACE: TBS_TRANSACCIONAL
-- Justificación: Diseñado para operaciones de alta frecuencia
-- como MATRICULA, CALIFICACION, DETALLE_MATRICULA, GRUPO.
-- Requiere mayor capacidad inicial y rápido crecimiento.
-- Optimizado para INSERT/UPDATE masivos.
-- Tamaño inicial: 200MB, incrementos de 100MB
-- =====================================================
CREATE TABLESPACE TBS_TRANSACCIONAL
DATAFILE 'C:\APP\MURDE\PRODUCT\21C\DBHOMEXE\DATABASE\tbs_transaccional01.dbf' 
SIZE 200M
AUTOEXTEND ON NEXT 100M MAXSIZE 5G
LOGGING
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
SEGMENT SPACE MANAGEMENT AUTO;

-- =====================================================
-- TABLESPACE: TBS_CATALOGOS
-- Justificación: Almacena configuración institucional y
-- parámetros del sistema (ASIGNATURA, PERIODO_ACADEMICO,
-- REGLA_EVALUACION, TIPO_ACTIVIDAD). Datos de tamaño moderado
-- con actualizaciones periódicas controladas.
-- Tamaño inicial: 50MB, incrementos de 25MB
-- =====================================================
CREATE TABLESPACE TBS_CATALOGOS
DATAFILE 'C:\APP\MURDE\PRODUCT\21C\DBHOMEXE\DATABASE\tbs_catalogos01.dbf' 
SIZE 50M
AUTOEXTEND ON NEXT 25M MAXSIZE 1G
LOGGING
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
SEGMENT SPACE MANAGEMENT AUTO;

-- =====================================================
-- TABLESPACE: TBS_AUDITORIA
-- Justificación: Almacena histórico de operaciones (AUDITORIA,
-- HISTORIAL_RIESGO). Diseñado para INSERT constante sin UPDATE.
-- Requiere alta capacidad de almacenamiento para retención
-- de registros históricos con fines de compliance y análisis.
-- Tamaño inicial: 150MB, incrementos de 100MB
-- =====================================================
CREATE TABLESPACE TBS_AUDITORIA
DATAFILE 'C:\APP\MURDE\PRODUCT\21C\DBHOMEXE\DATABASE\tbs_auditoria01.dbf' 
SIZE 150M
AUTOEXTEND ON NEXT 100M MAXSIZE 10G
LOGGING
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
SEGMENT SPACE MANAGEMENT AUTO;

-- =====================================================
-- TABLESPACE: TBS_SEGURIDAD
-- Justificación: Almacena control de acceso y usuarios del
-- sistema (USUARIO_SISTEMA, LOG_ACCESO). Datos críticos que
-- requieren segregación física por seguridad y auditoría.
-- Tamaño reducido pero con alta disponibilidad.
-- Tamaño inicial: 50MB, incrementos de 25MB
-- =====================================================
CREATE TABLESPACE TBS_SEGURIDAD
DATAFILE 'C:\APP\MURDE\PRODUCT\21C\DBHOMEXE\DATABASE\tbs_seguridad01.dbf' 
SIZE 50M
AUTOEXTEND ON NEXT 25M MAXSIZE 500M
LOGGING
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
SEGMENT SPACE MANAGEMENT AUTO;

-- =====================================================
-- TABLESPACE: TBS_INDICES
-- Justificación: Separa físicamente todos los índices del
-- sistema para optimizar I/O. Reduce contención con tablas
-- y facilita operaciones de mantenimiento (REBUILD INDEX).
-- Mejora el rendimiento en operaciones de búsqueda y JOIN.
-- Tamaño inicial: 150MB, incrementos de 75MB
-- =====================================================
CREATE TABLESPACE TBS_INDICES
DATAFILE 'C:\APP\MURDE\PRODUCT\21C\DBHOMEXE\DATABASE\tbs_indices01.dbf' 
SIZE 150M
AUTOEXTEND ON NEXT 75M MAXSIZE 3G
LOGGING
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
SEGMENT SPACE MANAGEMENT AUTO;

-- =====================================================
-- TABLESPACE TEMPORAL: TBS_TEMP_ACADEMICO
-- Justificación: Espacio temporal dedicado para operaciones
-- académicas que requieren ordenamiento, agrupación y joins
-- complejos (reportes, consolidados, cálculos de promedios).
-- Evita competencia con el TEMP del sistema.
-- Tamaño inicial: 200MB, incrementos de 100MB
-- =====================================================
CREATE TEMPORARY TABLESPACE TBS_TEMP_ACADEMICO
TEMPFILE 'C:\APP\MURDE\PRODUCT\21C\DBHOMEXE\DATABASE\tbs_temp_academico01.dbf' 
SIZE 200M
AUTOEXTEND ON NEXT 100M MAXSIZE 2G
EXTENT MANAGEMENT LOCAL UNIFORM SIZE 1M;

-- =====================================================
-- TABLESPACE: TBS_ESPECIALES
-- Justificación: Almacena módulos independientes y opcionales
-- como DIRECTOR_TRABAJO_GRADO, PROYECTO_INVESTIGACION,
-- CONVENIO_INSTITUCIONAL. Permite modularidad y posible
-- migración/desactivación sin afectar el core del sistema.
-- Tamaño inicial: 50MB, incrementos de 25MB
-- =====================================================
CREATE TABLESPACE TBS_ESPECIALES
DATAFILE 'C:\APP\MURDE\PRODUCT\21C\DBHOMEXE\DATABASE\tbs_especiales01.dbf' 
SIZE 50M
AUTOEXTEND ON NEXT 25M MAXSIZE 1G
LOGGING
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
SEGMENT SPACE MANAGEMENT AUTO;

-- =====================================================
-- VERIFICACIÓN DE TABLESPACES CREADOS
-- =====================================================
SELECT 
    tablespace_name,
    status,
    contents,
    extent_management,
    segment_space_management
FROM dba_tablespaces
WHERE tablespace_name LIKE 'TBS_%'
ORDER BY tablespace_name;

-- =====================================================
-- COMENTARIOS DE DOCUMENTACIÓN
-- =====================================================
-- Nota: Los comentarios de tablespaces se omiten por compatibilidad con algunos parsers SQL
-- Los tablespaces están documentados en el README.md y en los comentarios de este script

PROMPT '========================================='
PROMPT 'Tablespaces creados exitosamente'
PROMPT '========================================='
SELECT file_name FROM dba_data_files;
