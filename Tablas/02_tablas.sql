-- =====================================================
-- SISTEMA ACADÉMICO - ORACLE DATABASE 19c
-- Script: 02_tablas.sql
-- Propósito: Creación de todas las tablas del sistema
-- Autor: Sistema Académico
-- Fecha: 28/10/2025
-- =====================================================

-- =====================================================
-- TABLA: FACULTAD
-- Tablespace: TBS_MAESTROS
-- Justificación: Datos maestros de estructura organizacional
-- =====================================================
CREATE TABLE FACULTAD (
    cod_facultad NUMBER(5) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_facultad VARCHAR2(100) NOT NULL,
    sigla VARCHAR2(10) NOT NULL UNIQUE,
    fecha_creacion DATE NOT NULL,
    decano_actual VARCHAR2(100),
    estado VARCHAR2(10) DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'INACTIVO')),
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP
) TABLESPACE TBS_MAESTROS;

COMMENT ON TABLE FACULTAD IS 'Almacena las facultades de la institución';
COMMENT ON COLUMN FACULTAD.cod_facultad IS 'Código único de la facultad (generado automáticamente)';
COMMENT ON COLUMN FACULTAD.nombre_facultad IS 'Nombre completo de la facultad';
COMMENT ON COLUMN FACULTAD.sigla IS 'Sigla o abreviatura única de la facultad';
COMMENT ON COLUMN FACULTAD.estado IS 'Estado actual: ACTIVO o INACTIVO';

-- =====================================================
-- TABLA: PROGRAMA_ACADEMICO
-- Tablespace: TBS_MAESTROS
-- Justificación: Catálogo de programas académicos ofertados
-- =====================================================
CREATE TABLE PROGRAMA_ACADEMICO (
    cod_programa NUMBER(8) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_programa VARCHAR2(150) NOT NULL,
    tipo_programa VARCHAR2(20) NOT NULL CHECK (tipo_programa IN ('PREGRADO', 'POSGRADO', 'TECNICO', 'TECNOLOGICO')),
    nivel_formacion VARCHAR2(30) CHECK (nivel_formacion IN ('PROFESIONAL', 'ESPECIALIZACION', 'MAESTRIA', 'DOCTORADO', 'TECNICO', 'TECNOLOGO')),
    cod_facultad NUMBER(5) NOT NULL,
    creditos_totales NUMBER(3),
    duracion_semestres NUMBER(2),
    codigo_snies VARCHAR2(15) UNIQUE,
    estado VARCHAR2(10) DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'INACTIVO', 'SUSPENDIDO')),
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT FK_PROGRAMA_FACULTAD FOREIGN KEY (cod_facultad) REFERENCES FACULTAD(cod_facultad)
) TABLESPACE TBS_MAESTROS;

COMMENT ON TABLE PROGRAMA_ACADEMICO IS 'Programas académicos ofertados por la institución';
COMMENT ON COLUMN PROGRAMA_ACADEMICO.codigo_snies IS 'Código único SNIES del Ministerio de Educación';
COMMENT ON COLUMN PROGRAMA_ACADEMICO.creditos_totales IS 'Total de créditos académicos requeridos para graduación';

-- =====================================================
-- TABLA: ESTUDIANTE
-- Tablespace: TBS_MAESTROS
-- Justificación: Registro de estudiantes activos e históricos
-- =====================================================
CREATE TABLE ESTUDIANTE (
    cod_estudiante VARCHAR2(15) PRIMARY KEY,
    tipo_documento VARCHAR2(5) NOT NULL CHECK (tipo_documento IN ('CC', 'TI', 'CE', 'PAS', 'RC')),
    num_documento VARCHAR2(20) NOT NULL UNIQUE,
    primer_nombre VARCHAR2(50) NOT NULL,
    segundo_nombre VARCHAR2(50),
    primer_apellido VARCHAR2(50) NOT NULL,
    segundo_apellido VARCHAR2(50),
    fecha_nacimiento DATE NOT NULL,
    genero VARCHAR2(1) CHECK (genero IN ('M', 'F', 'O')),
    correo_institucional VARCHAR2(100) NOT NULL UNIQUE,
    correo_personal VARCHAR2(100),
    telefono VARCHAR2(15),
    direccion VARCHAR2(200),
    cod_programa NUMBER(8) NOT NULL,
    estado_estudiante VARCHAR2(15) DEFAULT 'ACTIVO' CHECK (estado_estudiante IN ('ACTIVO', 'INACTIVO', 'GRADUADO', 'RETIRADO', 'SUSPENDIDO')),
    fecha_ingreso DATE NOT NULL,
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT FK_ESTUDIANTE_PROGRAMA FOREIGN KEY (cod_programa) REFERENCES PROGRAMA_ACADEMICO(cod_programa)
) TABLESPACE TBS_MAESTROS;

COMMENT ON TABLE ESTUDIANTE IS 'Información completa de estudiantes matriculados';
COMMENT ON COLUMN ESTUDIANTE.cod_estudiante IS 'Código único institucional del estudiante';
COMMENT ON COLUMN ESTUDIANTE.tipo_documento IS 'CC=Cédula, TI=Tarjeta Identidad, CE=Cédula Extranjería, PAS=Pasaporte';
COMMENT ON COLUMN ESTUDIANTE.estado_estudiante IS 'Estado académico actual del estudiante';

-- =====================================================
-- TABLA: DOCENTE
-- Tablespace: TBS_MAESTROS
-- Justificación: Registro de docentes de planta y cátedra
-- =====================================================
CREATE TABLE DOCENTE (
    cod_docente VARCHAR2(15) PRIMARY KEY,
    tipo_documento VARCHAR2(5) NOT NULL CHECK (tipo_documento IN ('CC', 'CE', 'PAS')),
    num_documento VARCHAR2(20) NOT NULL UNIQUE,
    primer_nombre VARCHAR2(50) NOT NULL,
    segundo_nombre VARCHAR2(50),
    primer_apellido VARCHAR2(50) NOT NULL,
    segundo_apellido VARCHAR2(50),
    titulo_academico VARCHAR2(100) NOT NULL,
    nivel_formacion VARCHAR2(30) CHECK (nivel_formacion IN ('PROFESIONAL', 'ESPECIALIZACION', 'MAESTRIA', 'DOCTORADO', 'POSTDOCTORADO')),
    tipo_vinculacion VARCHAR2(20) CHECK (tipo_vinculacion IN ('PLANTA', 'CATEDRA', 'OCASIONAL', 'HONORARIOS')),
    correo_institucional VARCHAR2(100) NOT NULL UNIQUE,
    correo_personal VARCHAR2(100),
    telefono VARCHAR2(15),
    cod_facultad NUMBER(5),
    estado_docente VARCHAR2(10) DEFAULT 'ACTIVO' CHECK (estado_docente IN ('ACTIVO', 'INACTIVO', 'RETIRADO', 'COMISION')),
    fecha_vinculacion DATE NOT NULL,
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT FK_DOCENTE_FACULTAD FOREIGN KEY (cod_facultad) REFERENCES FACULTAD(cod_facultad)
) TABLESPACE TBS_MAESTROS;

COMMENT ON TABLE DOCENTE IS 'Docentes vinculados a la institución';
COMMENT ON COLUMN DOCENTE.tipo_vinculacion IS 'Tipo de contratación del docente';
COMMENT ON COLUMN DOCENTE.estado_docente IS 'COMISION indica licencia o comisión de estudios';

-- =====================================================
-- TABLA: ASIGNATURA
-- Tablespace: TBS_CATALOGOS
-- Justificación: Catálogo de asignaturas ofertadas
-- =====================================================
CREATE TABLE ASIGNATURA (
    cod_asignatura VARCHAR2(10) PRIMARY KEY,
    nombre_asignatura VARCHAR2(150) NOT NULL,
    creditos NUMBER(2) NOT NULL CHECK (creditos > 0),
    horas_teoricas NUMBER(2) DEFAULT 0,
    horas_practicas NUMBER(2) DEFAULT 0,
    tipo_asignatura VARCHAR2(20) CHECK (tipo_asignatura IN ('OBLIGATORIA', 'ELECTIVA', 'OPTATIVA', 'TRABAJO_GRADO')),
    cod_programa NUMBER(8) NOT NULL,
    semestre_sugerido NUMBER(2),
    requiere_prerrequisito VARCHAR2(1) DEFAULT 'N' CHECK (requiere_prerrequisito IN ('S', 'N')),
    estado VARCHAR2(10) DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'INACTIVO')),
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT FK_ASIGNATURA_PROGRAMA FOREIGN KEY (cod_programa) REFERENCES PROGRAMA_ACADEMICO(cod_programa)
) TABLESPACE TBS_CATALOGOS;

COMMENT ON TABLE ASIGNATURA IS 'Catálogo de asignaturas por programa académico';
COMMENT ON COLUMN ASIGNATURA.creditos IS 'Número de créditos académicos de la asignatura';
COMMENT ON COLUMN ASIGNATURA.semestre_sugerido IS 'Semestre recomendado en el plan de estudios';

-- =====================================================
-- TABLA: PRERREQUISITO
-- Tablespace: TBS_CATALOGOS
-- Justificación: Define dependencias entre asignaturas
-- =====================================================
CREATE TABLE PRERREQUISITO (
    cod_prerrequisito NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cod_asignatura VARCHAR2(10) NOT NULL,
    cod_asignatura_requisito VARCHAR2(10) NOT NULL,
    tipo_requisito VARCHAR2(15) DEFAULT 'OBLIGATORIO' CHECK (tipo_requisito IN ('OBLIGATORIO', 'ALTERNATIVO')),
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT FK_PREREQ_ASIGNATURA FOREIGN KEY (cod_asignatura) REFERENCES ASIGNATURA(cod_asignatura),
    CONSTRAINT FK_PREREQ_REQUISITO FOREIGN KEY (cod_asignatura_requisito) REFERENCES ASIGNATURA(cod_asignatura),
    CONSTRAINT CHK_PREREQ_DISTINTO CHECK (cod_asignatura != cod_asignatura_requisito)
) TABLESPACE TBS_CATALOGOS;

COMMENT ON TABLE PRERREQUISITO IS 'Relación de prerrequisitos entre asignaturas';
COMMENT ON COLUMN PRERREQUISITO.tipo_requisito IS 'OBLIGATORIO: debe cursarse antes; ALTERNATIVO: una de varias opciones';

-- =====================================================
-- TABLA: PERIODO_ACADEMICO
-- Tablespace: TBS_CATALOGOS
-- Justificación: Define periodos académicos (semestres/trimestres)
-- =====================================================
CREATE TABLE PERIODO_ACADEMICO (
    cod_periodo VARCHAR2(10) PRIMARY KEY,
    nombre_periodo VARCHAR2(50) NOT NULL,
    anio NUMBER(4) NOT NULL,
    periodo NUMBER(1) NOT NULL CHECK (periodo BETWEEN 1 AND 3),
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    estado_periodo VARCHAR2(15) DEFAULT 'PROGRAMADO' CHECK (estado_periodo IN ('PROGRAMADO', 'EN_CURSO', 'FINALIZADO', 'CANCELADO')),
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT CHK_FECHAS_PERIODO CHECK (fecha_fin > fecha_inicio)
) TABLESPACE TBS_CATALOGOS;

COMMENT ON TABLE PERIODO_ACADEMICO IS 'Periodos académicos de la institución';
COMMENT ON COLUMN PERIODO_ACADEMICO.periodo IS '1=Primer semestre, 2=Segundo semestre, 3=Intersemestral';
COMMENT ON COLUMN PERIODO_ACADEMICO.cod_periodo IS 'Formato sugerido: AAAA-P (ej: 2025-1)';

-- =====================================================
-- TABLA: GRUPO
-- Tablespace: TBS_TRANSACCIONAL
-- Justificación: Grupos de asignaturas por periodo
-- =====================================================
CREATE TABLE GRUPO (
    cod_grupo NUMBER(12) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cod_asignatura VARCHAR2(10) NOT NULL,
    cod_periodo VARCHAR2(10) NOT NULL,
    numero_grupo NUMBER(3) NOT NULL,
    cod_docente VARCHAR2(15),
    cupo_maximo NUMBER(3) DEFAULT 30 CHECK (cupo_maximo > 0),
    cupo_disponible NUMBER(3) DEFAULT 30,
    modalidad VARCHAR2(15) CHECK (modalidad IN ('PRESENCIAL', 'VIRTUAL', 'HIBRIDO')),
    aula VARCHAR2(20),
    estado_grupo VARCHAR2(15) DEFAULT 'ACTIVO' CHECK (estado_grupo IN ('ACTIVO', 'CERRADO', 'CANCELADO')),
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT FK_GRUPO_ASIGNATURA FOREIGN KEY (cod_asignatura) REFERENCES ASIGNATURA(cod_asignatura),
    CONSTRAINT FK_GRUPO_PERIODO FOREIGN KEY (cod_periodo) REFERENCES PERIODO_ACADEMICO(cod_periodo),
    CONSTRAINT FK_GRUPO_DOCENTE FOREIGN KEY (cod_docente) REFERENCES DOCENTE(cod_docente),
    CONSTRAINT UK_GRUPO_PERIODO UNIQUE (cod_asignatura, cod_periodo, numero_grupo),
    CONSTRAINT CHK_CUPO_DISPONIBLE CHECK (cupo_disponible >= 0 AND cupo_disponible <= cupo_maximo)
) TABLESPACE TBS_TRANSACCIONAL;

COMMENT ON TABLE GRUPO IS 'Grupos de asignaturas ofertados por periodo';
COMMENT ON COLUMN GRUPO.cupo_disponible IS 'Se actualiza automáticamente al registrar matrículas';

-- =====================================================
-- TABLA: HORARIO
-- Tablespace: TBS_TRANSACCIONAL
-- Justificación: Horarios de cada grupo
-- =====================================================
CREATE TABLE HORARIO (
    cod_horario NUMBER(12) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cod_grupo NUMBER(12) NOT NULL,
    dia_semana VARCHAR2(10) NOT NULL CHECK (dia_semana IN ('LUNES', 'MARTES', 'MIERCOLES', 'JUEVES', 'VIERNES', 'SABADO', 'DOMINGO')),
    hora_inicio VARCHAR2(5) NOT NULL,
    hora_fin VARCHAR2(5) NOT NULL,
    aula VARCHAR2(20),
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT FK_HORARIO_GRUPO FOREIGN KEY (cod_grupo) REFERENCES GRUPO(cod_grupo) ON DELETE CASCADE,
    CONSTRAINT CHK_HORA_FIN CHECK (hora_fin > hora_inicio)
) TABLESPACE TBS_TRANSACCIONAL;

COMMENT ON TABLE HORARIO IS 'Horarios asignados a cada grupo';
COMMENT ON COLUMN HORARIO.hora_inicio IS 'Formato HH24:MI (ej: 08:00)';

-- =====================================================
-- TABLA: MATRICULA
-- Tablespace: TBS_TRANSACCIONAL
-- Justificación: Registro de matrículas por periodo
-- =====================================================
CREATE TABLE MATRICULA (
    cod_matricula NUMBER(12) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cod_estudiante VARCHAR2(15) NOT NULL,
    cod_periodo VARCHAR2(10) NOT NULL,
    tipo_matricula VARCHAR2(20) CHECK (tipo_matricula IN ('ORDINARIA', 'EXTRAORDINARIA', 'RENOVACION', 'REINGRESO')),
    fecha_matricula DATE DEFAULT SYSDATE NOT NULL,
    estado_matricula VARCHAR2(20) DEFAULT 'ACTIVA' CHECK (estado_matricula IN ('ACTIVA', 'CANCELADA', 'CONGELADA', 'FINALIZADA')),
    total_creditos NUMBER(3) DEFAULT 0,
    valor_matricula NUMBER(12,2),
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT FK_MATRICULA_ESTUDIANTE FOREIGN KEY (cod_estudiante) REFERENCES ESTUDIANTE(cod_estudiante),
    CONSTRAINT FK_MATRICULA_PERIODO FOREIGN KEY (cod_periodo) REFERENCES PERIODO_ACADEMICO(cod_periodo),
    CONSTRAINT UK_MATRICULA_EST_PER UNIQUE (cod_estudiante, cod_periodo)
) TABLESPACE TBS_TRANSACCIONAL;

COMMENT ON TABLE MATRICULA IS 'Matrículas de estudiantes por periodo académico';
COMMENT ON COLUMN MATRICULA.total_creditos IS 'Total de créditos matriculados en el periodo';

-- =====================================================
-- TABLA: DETALLE_MATRICULA
-- Tablespace: TBS_TRANSACCIONAL
-- Justificación: Asignaturas específicas matriculadas
-- =====================================================
CREATE TABLE DETALLE_MATRICULA (
    cod_detalle_matricula NUMBER(15) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cod_matricula NUMBER(12) NOT NULL,
    cod_grupo NUMBER(12) NOT NULL,
    fecha_inscripcion DATE DEFAULT SYSDATE,
    estado_inscripcion VARCHAR2(20) DEFAULT 'INSCRITO' CHECK (estado_inscripcion IN ('INSCRITO', 'RETIRADO', 'APROBADO', 'REPROBADO', 'VALIDADO')),
    fecha_retiro DATE,
    motivo_retiro VARCHAR2(200),
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT FK_DETALLE_MATRICULA FOREIGN KEY (cod_matricula) REFERENCES MATRICULA(cod_matricula) ON DELETE CASCADE,
    CONSTRAINT FK_DETALLE_GRUPO FOREIGN KEY (cod_grupo) REFERENCES GRUPO(cod_grupo),
    CONSTRAINT UK_DETALLE_MAT_GRUPO UNIQUE (cod_matricula, cod_grupo)
) TABLESPACE TBS_TRANSACCIONAL;

COMMENT ON TABLE DETALLE_MATRICULA IS 'Detalle de grupos matriculados por estudiante';
COMMENT ON COLUMN DETALLE_MATRICULA.estado_inscripcion IS 'Estado de la inscripción a la asignatura';

-- =====================================================
-- TABLA: TIPO_ACTIVIDAD_EVALUATIVA
-- Tablespace: TBS_CATALOGOS
-- Justificación: Catálogo de tipos de evaluación
-- =====================================================
CREATE TABLE TIPO_ACTIVIDAD_EVALUATIVA (
    cod_tipo_actividad NUMBER(5) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_actividad VARCHAR2(50) NOT NULL UNIQUE,
    descripcion VARCHAR2(200),
    estado VARCHAR2(10) DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'INACTIVO')),
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP
) TABLESPACE TBS_CATALOGOS;

COMMENT ON TABLE TIPO_ACTIVIDAD_EVALUATIVA IS 'Tipos de actividades evaluativas (Parcial, Quiz, Taller, Proyecto, etc.)';

-- =====================================================
-- TABLA: REGLA_EVALUACION
-- Tablespace: TBS_CATALOGOS
-- Justificación: Porcentajes de evaluación por asignatura
-- =====================================================
CREATE TABLE REGLA_EVALUACION (
    cod_regla NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cod_asignatura VARCHAR2(10) NOT NULL,
    cod_tipo_actividad NUMBER(5) NOT NULL,
    porcentaje NUMBER(5,2) NOT NULL CHECK (porcentaje > 0 AND porcentaje <= 100),
    cantidad_actividades NUMBER(2) DEFAULT 1,
    descripcion VARCHAR2(200),
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT FK_REGLA_ASIGNATURA FOREIGN KEY (cod_asignatura) REFERENCES ASIGNATURA(cod_asignatura),
    CONSTRAINT FK_REGLA_TIPO_ACTIVIDAD FOREIGN KEY (cod_tipo_actividad) REFERENCES TIPO_ACTIVIDAD_EVALUATIVA(cod_tipo_actividad)
) TABLESPACE TBS_CATALOGOS;

COMMENT ON TABLE REGLA_EVALUACION IS 'Configura porcentajes de evaluación por asignatura';
COMMENT ON COLUMN REGLA_EVALUACION.porcentaje IS 'Porcentaje que representa en la nota final';

-- =====================================================
-- TABLA: CALIFICACION
-- Tablespace: TBS_TRANSACCIONAL
-- Justificación: Calificaciones individuales por actividad
-- =====================================================
CREATE TABLE CALIFICACION (
    cod_calificacion NUMBER(15) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cod_detalle_matricula NUMBER(15) NOT NULL,
    cod_tipo_actividad NUMBER(5) NOT NULL,
    numero_actividad NUMBER(2) DEFAULT 1,
    nota NUMBER(3,1) NOT NULL CHECK (nota >= 0 AND nota <= 5),
    porcentaje_aplicado NUMBER(5,2),
    fecha_calificacion DATE DEFAULT SYSDATE,
    observaciones VARCHAR2(300),
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT FK_CALIF_DETALLE FOREIGN KEY (cod_detalle_matricula) REFERENCES DETALLE_MATRICULA(cod_detalle_matricula) ON DELETE CASCADE,
    CONSTRAINT FK_CALIF_TIPO_ACTIVIDAD FOREIGN KEY (cod_tipo_actividad) REFERENCES TIPO_ACTIVIDAD_EVALUATIVA(cod_tipo_actividad)
) TABLESPACE TBS_TRANSACCIONAL;

COMMENT ON TABLE CALIFICACION IS 'Calificaciones individuales por actividad evaluativa';
COMMENT ON COLUMN CALIFICACION.nota IS 'Nota de 0.0 a 5.0 (escala colombiana)';

-- =====================================================
-- TABLA: NOTA_DEFINITIVA
-- Tablespace: TBS_TRANSACCIONAL
-- Justificación: Consolidado de notas finales por asignatura
-- =====================================================
CREATE TABLE NOTA_DEFINITIVA (
    cod_nota_definitiva NUMBER(15) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cod_detalle_matricula NUMBER(15) NOT NULL UNIQUE,
    nota_final NUMBER(3,1) CHECK (nota_final >= 0 AND nota_final <= 5),
    resultado VARCHAR2(15) CHECK (resultado IN ('APROBADO', 'REPROBADO', 'PENDIENTE', 'VALIDADO')),
    fecha_calculo DATE DEFAULT SYSDATE,
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT FK_NOTA_DEF_DETALLE FOREIGN KEY (cod_detalle_matricula) REFERENCES DETALLE_MATRICULA(cod_detalle_matricula) ON DELETE CASCADE
) TABLESPACE TBS_TRANSACCIONAL;

COMMENT ON TABLE NOTA_DEFINITIVA IS 'Nota definitiva consolidada por asignatura';
COMMENT ON COLUMN NOTA_DEFINITIVA.nota_final IS 'Promedio ponderado de todas las calificaciones';

-- =====================================================
-- TABLA: HISTORIAL_RIESGO
-- Tablespace: TBS_AUDITORIA
-- Justificación: Seguimiento de estudiantes en riesgo académico
-- =====================================================
CREATE TABLE HISTORIAL_RIESGO (
    cod_historial_riesgo NUMBER(15) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cod_estudiante VARCHAR2(15) NOT NULL,
    cod_periodo VARCHAR2(10) NOT NULL,
    tipo_riesgo VARCHAR2(30) CHECK (tipo_riesgo IN ('BAJO_RENDIMIENTO', 'PERDIDA_CALIDAD', 'REPROBACION_MULTIPLE', 'REINCIDENCIA')),
    nivel_riesgo VARCHAR2(10) CHECK (nivel_riesgo IN ('BAJO', 'MEDIO', 'ALTO', 'CRITICO')),
    promedio_periodo NUMBER(3,1),
    asignaturas_reprobadas NUMBER(2),
    observaciones VARCHAR2(500),
    fecha_deteccion DATE DEFAULT SYSDATE,
    estado_seguimiento VARCHAR2(20) DEFAULT 'PENDIENTE' CHECK (estado_seguimiento IN ('PENDIENTE', 'EN_SEGUIMIENTO', 'SUPERADO', 'RETIRADO')),
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT FK_RIESGO_ESTUDIANTE FOREIGN KEY (cod_estudiante) REFERENCES ESTUDIANTE(cod_estudiante),
    CONSTRAINT FK_RIESGO_PERIODO FOREIGN KEY (cod_periodo) REFERENCES PERIODO_ACADEMICO(cod_periodo)
) TABLESPACE TBS_AUDITORIA;

COMMENT ON TABLE HISTORIAL_RIESGO IS 'Registro histórico de estudiantes en riesgo académico';
COMMENT ON COLUMN HISTORIAL_RIESGO.tipo_riesgo IS 'Clasificación del tipo de riesgo detectado';

-- =====================================================
-- TABLA: AUDITORIA
-- Tablespace: TBS_AUDITORIA
-- Justificación: Registro de todas las operaciones críticas
-- =====================================================
CREATE TABLE AUDITORIA (
    cod_auditoria NUMBER(15) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tabla_afectada VARCHAR2(50) NOT NULL,
    operacion VARCHAR2(20) NOT NULL CHECK (operacion IN ('INSERT', 'UPDATE', 'DELETE')),
    usuario_bd VARCHAR2(50) NOT NULL,
    fecha_operacion TIMESTAMP DEFAULT SYSTIMESTAMP,
    ip_origen VARCHAR2(45),
    valores_anteriores CLOB,
    valores_nuevos CLOB,
    sentencia_sql VARCHAR2(4000),
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP
) TABLESPACE TBS_AUDITORIA;

COMMENT ON TABLE AUDITORIA IS 'Registro completo de auditoría de operaciones DML';
COMMENT ON COLUMN AUDITORIA.valores_anteriores IS 'Valores antes de la operación (formato JSON)';
COMMENT ON COLUMN AUDITORIA.valores_nuevos IS 'Valores después de la operación (formato JSON)';

-- =====================================================
-- TABLA: USUARIO_SISTEMA
-- Tablespace: TBS_SEGURIDAD
-- Justificación: Gestión de usuarios del sistema académico
-- =====================================================
CREATE TABLE USUARIO_SISTEMA (
    cod_usuario NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR2(50) NOT NULL UNIQUE,
    password_hash VARCHAR2(128) NOT NULL,
    tipo_usuario VARCHAR2(20) NOT NULL CHECK (tipo_usuario IN ('ADMINISTRADOR', 'COORDINADOR', 'DOCENTE', 'ESTUDIANTE', 'REGISTRO')),
    cod_referencia VARCHAR2(15),
    correo_electronico VARCHAR2(100) NOT NULL UNIQUE,
    ultimo_acceso TIMESTAMP,
    intentos_fallidos NUMBER(2) DEFAULT 0,
    cuenta_bloqueada VARCHAR2(1) DEFAULT 'N' CHECK (cuenta_bloqueada IN ('S', 'N')),
    fecha_creacion DATE DEFAULT SYSDATE,
    fecha_expiracion DATE,
    estado VARCHAR2(10) DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'INACTIVO', 'BLOQUEADO')),
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP
) TABLESPACE TBS_SEGURIDAD;

COMMENT ON TABLE USUARIO_SISTEMA IS 'Usuarios con acceso al sistema académico';
COMMENT ON COLUMN USUARIO_SISTEMA.cod_referencia IS 'Código del estudiante o docente asociado';
COMMENT ON COLUMN USUARIO_SISTEMA.password_hash IS 'Hash SHA-256 de la contraseña';

-- =====================================================
-- TABLA: LOG_ACCESO
-- Tablespace: TBS_SEGURIDAD
-- Justificación: Registro de accesos al sistema
-- =====================================================
CREATE TABLE LOG_ACCESO (
    cod_log NUMBER(15) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cod_usuario NUMBER(10) NOT NULL,
    fecha_acceso TIMESTAMP DEFAULT SYSTIMESTAMP,
    ip_origen VARCHAR2(45),
    navegador VARCHAR2(100),
    resultado_acceso VARCHAR2(20) CHECK (resultado_acceso IN ('EXITOSO', 'FALLIDO', 'BLOQUEADO')),
    motivo_fallo VARCHAR2(200),
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT FK_LOG_USUARIO FOREIGN KEY (cod_usuario) REFERENCES USUARIO_SISTEMA(cod_usuario)
) TABLESPACE TBS_SEGURIDAD;

COMMENT ON TABLE LOG_ACCESO IS 'Histórico de accesos al sistema';

-- =====================================================
-- TABLA: DIRECTOR_TRABAJO_GRADO
-- Tablespace: TBS_ESPECIALES
-- Justificación: Módulo opcional de trabajos de grado
-- =====================================================
CREATE TABLE DIRECTOR_TRABAJO_GRADO (
    cod_direccion NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cod_estudiante VARCHAR2(15) NOT NULL,
    cod_docente VARCHAR2(15) NOT NULL,
    titulo_trabajo VARCHAR2(300) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin_estimada DATE,
    fecha_sustentacion DATE,
    nota_final NUMBER(3,1) CHECK (nota_final >= 0 AND nota_final <= 5),
    estado_trabajo VARCHAR2(20) DEFAULT 'EN_PROCESO' CHECK (estado_trabajo IN ('EN_PROCESO', 'SUSTENTADO', 'APROBADO', 'NO_APROBADO', 'CANCELADO')),
    observaciones VARCHAR2(1000),
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT FK_TRABAJO_ESTUDIANTE FOREIGN KEY (cod_estudiante) REFERENCES ESTUDIANTE(cod_estudiante),
    CONSTRAINT FK_TRABAJO_DOCENTE FOREIGN KEY (cod_docente) REFERENCES DOCENTE(cod_docente)
) TABLESPACE TBS_ESPECIALES;

COMMENT ON TABLE DIRECTOR_TRABAJO_GRADO IS 'Gestión de trabajos de grado y directores asignados';
COMMENT ON COLUMN DIRECTOR_TRABAJO_GRADO.estado_trabajo IS 'Estado del proceso de trabajo de grado';

-- Trigger para crear un usuario automáticamente al insertar un estudiante
CREATE OR REPLACE TRIGGER trg_crear_usuario_estudiante
AFTER INSERT ON ESTUDIANTE
FOR EACH ROW
DECLARE
    v_password_hash VARCHAR2(200);
BEGIN
    -- Generar el hash de la contraseña usando el identificador del estudiante
    v_password_hash := DBMS_CRYPTO.HASH(UTL_I18N.STRING_TO_RAW(:NEW.num_documento, 'AL32UTF8'), 2);

    -- Insertar el nuevo usuario en la tabla USUARIO_SISTEMA
    INSERT INTO USUARIO_SISTEMA (username, password_hash, tipo_usuario, cod_referencia, correo_electronico, estado)
    VALUES (:NEW.correo_institucional, v_password_hash, 'ESTUDIANTE', :NEW.cod_estudiante, :NEW.correo_institucional, 'ACTIVO');

    DBMS_OUTPUT.PUT_LINE('Usuario creado para el estudiante: ' || :NEW.primer_nombre || ' ' || :NEW.primer_apellido);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al crear el usuario: ' || SQLERRM);
END;
/

PROMPT '========================================='
PROMPT 'Tablas creadas exitosamente'
PROMPT '========================================='

-- Endpoint para actualizar la contraseña de un usuario
BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'USUARIOS_API',
        p_pattern => 'usuarios/{username}/actualizar-password'
    );

    ORDS.DEFINE_HANDLER(
        p_module_name => 'USUARIOS_API',
        p_pattern => 'usuarios/{username}/actualizar-password',
        p_method => 'PUT',
        p_source_type => ORDS.SOURCE_TYPE_PLSQL,
        p_source => q'{
            DECLARE
                v_password_hash VARCHAR2(200);
            BEGIN
                -- Generar el hash de la nueva contraseña
                v_password_hash := DBMS_CRYPTO.HASH(UTL_I18N.STRING_TO_RAW(:new_password, 'AL32UTF8'), 2);

                -- Actualizar la contraseña en la tabla USUARIO_SISTEMA
                UPDATE USUARIO_SISTEMA
                SET password_hash = v_password_hash
                WHERE username = :username;

                -- Confirmar la actualización
                :status := 200;
                :message := 'Contraseña actualizada correctamente';
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    :status := 404;
                    :message := 'Usuario no encontrado';
                WHEN OTHERS THEN
                    :status := 500;
                    :message := 'Error al actualizar la contraseña: ' || SQLERRM;
            END;
        }'
    );

    COMMIT;
END;
/
