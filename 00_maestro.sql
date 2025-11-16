-- ============================================================
-- SCRIPT MAESTRO - SISTEMA DE GESTIÓN ACADÉMICA
-- Universidad del Quindío
-- Base de Datos II - Proyecto Final
-- ============================================================
-- 
-- Este script ejecuta todos los componentes del sistema en el orden correcto
-- Prerequisitos: Oracle 21c XE, usuario ACADEMICO creado con privilegios
-- 
-- EJECUCIÓN: sqlplus ACADEMICO/Academico123#@localhost:1521/xepdb1 @00_maestro.sql
-- 
-- ============================================================

SET SERVEROUTPUT ON
SET VERIFY OFF
SET FEEDBACK ON
SET ECHO ON

PROMPT ============================================================
PROMPT SISTEMA DE GESTIÓN ACADÉMICA - UNIVERSIDAD DEL QUINDÍO
PROMPT Instalación Completa del Sistema
PROMPT ============================================================
PROMPT 
PROMPT Fecha: 
SELECT TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') as fecha_instalacion FROM DUAL;
PROMPT 

-- ============================================================
-- FASE 1: ESTRUCTURA DE BASE DE DATOS
-- ============================================================
PROMPT 
PROMPT ============================================================
PROMPT FASE 1: CREANDO ESTRUCTURA DE BASE DE DATOS
PROMPT ============================================================

-- Tablespaces (opcional, requiere privilegios DBA)
-- @01_ESTRUCTURA/01_tablespaces.sql

-- Índices
PROMPT Creando índices...
@01_ESTRUCTURA/03_indices.sql

-- Secuencias
PROMPT Creando secuencias...
@01_ESTRUCTURA/04_secuencias.sql

-- Tablas adicionales
PROMPT Creando tablas faltantes...
@01_ESTRUCTURA/crear_tablas_faltantes.sql

-- ============================================================
-- FASE 2: CARGA DE DATOS
-- ============================================================
PROMPT 
PROMPT ============================================================
PROMPT FASE 2: CARGANDO DATOS MAESTROS Y DE PRUEBA
PROMPT ============================================================

PROMPT Cargando datos maestros...
@02_DATOS/fase1_datos_maestros.sql

PROMPT Completando esquema de datos...
@02_DATOS/completar_esquema_datos.sql

PROMPT Cargando datos de prueba...
@02_DATOS/09_datos_prueba.sql

-- ============================================================
-- FASE 3: TRIGGERS Y FUNCIONES
-- ============================================================
PROMPT 
PROMPT ============================================================
PROMPT FASE 3: CREANDO TRIGGERS Y FUNCIONES DE NEGOCIO
PROMPT ============================================================

PROMPT Creando triggers críticos batch 1...
@03_TRIGGERS_FUNCIONES/crear_triggers_criticos.sql

PROMPT Creando triggers críticos batch 2...
@03_TRIGGERS_FUNCIONES/crear_batch2_triggers.sql

-- ============================================================
-- FASE 4: PAQUETES PL/SQL
-- ============================================================
PROMPT 
PROMPT ============================================================
PROMPT FASE 4: CREANDO PAQUETES PL/SQL
PROMPT ============================================================

PROMPT Creando paquetes del sistema...
@04_PAQUETES/07_paquetes.sql

-- ============================================================
-- FASE 5: VISTAS Y REPORTES
-- ============================================================
PROMPT 
PROMPT ============================================================
PROMPT FASE 5: CREANDO VISTAS Y REPORTES ANALÍTICOS
PROMPT ============================================================

PROMPT Creando vistas base...
@05_VISTAS_REPORTES/05_vistas.sql

PROMPT Creando reportes analíticos completos...
@05_VISTAS_REPORTES/reportes_analiticos_completos.sql

-- ============================================================
-- FASE 6: SEGURIDAD
-- ============================================================
PROMPT 
PROMPT ============================================================
PROMPT FASE 6: CONFIGURANDO SEGURIDAD Y PRIVILEGIOS
PROMPT ============================================================

PROMPT Creando roles y privilegios...
@06_SEGURIDAD/06_roles_privilegios.sql

-- Permisos ORDS (requiere usuario ORDS_PUBLIC_USER)
-- @06_SEGURIDAD/OTORGAR_PERMISOS_ORDS.sql

-- ============================================================
-- FASE 7: HABILITACIÓN ORDS (OPCIONAL)
-- ============================================================
PROMPT 
PROMPT ============================================================
PROMPT FASE 7: HABILITANDO ORACLE REST DATA SERVICES
PROMPT ============================================================

-- Requiere ORDS instalado y configurado
-- @10_ORDS/habilitarORDS.sql

-- ============================================================
-- VERIFICACIÓN FINAL
-- ============================================================
PROMPT 
PROMPT ============================================================
PROMPT VERIFICACIÓN FINAL DEL SISTEMA
PROMPT ============================================================

@09_VERIFICACION/verificacion_final_100.sql

PROMPT 
PROMPT ============================================================
PROMPT INSTALACIÓN COMPLETADA
PROMPT ============================================================
PROMPT 
PROMPT Sistema académico instalado exitosamente
PROMPT Para iniciar ORDS ejecute: .\10_ORDS\INICIAR_ORDS.ps1
PROMPT Para ejecutar pruebas: .\07_TESTS\test_all_endpoints.ps1
PROMPT 
PROMPT ============================================================

EXIT
