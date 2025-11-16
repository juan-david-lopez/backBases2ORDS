-- =====================================================
-- SISTEMA ACADÉMICO - ORACLE DATABASE 19c
-- Script: 09_datos_prueba.sql
-- Propósito: Datos de prueba completos para el sistema
-- Autor: Sistema Académico
-- Fecha: 28/10/2025
-- =====================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

PROMPT '========================================='
PROMPT 'Cargando Datos de Prueba del Sistema'
PROMPT '========================================='

-- =====================================================
-- 1. FACULTADES
-- =====================================================

PROMPT ''
PROMPT 'Insertando Facultades...'

INSERT INTO FACULTAD (nombre_facultad, sigla, fecha_creacion, decano_actual, estado)
VALUES ('Facultad de Ingeniería', 'FI', TO_DATE('2000-01-15', 'YYYY-MM-DD'), 'Dr. Carlos Méndez', 'ACTIVO');

INSERT INTO FACULTAD (nombre_facultad, sigla, fecha_creacion, decano_actual, estado)
VALUES ('Facultad de Ciencias Económicas', 'FCE', TO_DATE('1998-03-20', 'YYYY-MM-DD'), 'Dra. María González', 'ACTIVO');

INSERT INTO FACULTAD (nombre_facultad, sigla, fecha_creacion, decano_actual, estado)
VALUES ('Facultad de Ciencias de la Salud', 'FCS', TO_DATE('2002-06-10', 'YYYY-MM-DD'), 'Dr. Luis Ramírez', 'ACTIVO');

BEGIN
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ 3 Facultades insertadas');
END;
/

-- =====================================================
-- 2. PROGRAMAS ACADÉMICOS
-- =====================================================

PROMPT ''
PROMPT 'Insertando Programas Académicos...'

DECLARE
    v_cod_facultad_ing NUMBER;
    v_cod_facultad_eco NUMBER;
BEGIN
    SELECT cod_facultad INTO v_cod_facultad_ing FROM FACULTAD WHERE sigla = 'FI';
    SELECT cod_facultad INTO v_cod_facultad_eco FROM FACULTAD WHERE sigla = 'FCE';
    
    INSERT INTO PROGRAMA_ACADEMICO (nombre_programa, tipo_programa, nivel_formacion, cod_facultad, creditos_totales, duracion_semestres, codigo_snies, estado)
    VALUES ('Ingeniería de Sistemas', 'PREGRADO', 'PROFESIONAL', v_cod_facultad_ing, 160, 10, '12345', 'ACTIVO');
    
    INSERT INTO PROGRAMA_ACADEMICO (nombre_programa, tipo_programa, nivel_formacion, cod_facultad, creditos_totales, duracion_semestres, codigo_snies, estado)
    VALUES ('Ingeniería Industrial', 'PREGRADO', 'PROFESIONAL', v_cod_facultad_ing, 155, 10, '12346', 'ACTIVO');
    
    INSERT INTO PROGRAMA_ACADEMICO (nombre_programa, tipo_programa, nivel_formacion, cod_facultad, creditos_totales, duracion_semestres, codigo_snies, estado)
    VALUES ('Administración de Empresas', 'PREGRADO', 'PROFESIONAL', v_cod_facultad_eco, 150, 9, '12347', 'ACTIVO');
    
    INSERT INTO PROGRAMA_ACADEMICO (nombre_programa, tipo_programa, nivel_formacion, cod_facultad, creditos_totales, duracion_semestres, codigo_snies, estado)
    VALUES ('Maestría en Ingeniería de Software', 'POSGRADO', 'MAESTRIA', v_cod_facultad_ing, 50, 4, '12348', 'ACTIVO');
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ 4 Programas Académicos insertados');
END;
/

-- =====================================================
-- 3. PERIODOS ACADÉMICOS
-- =====================================================

PROMPT ''
PROMPT 'Insertando Periodos Académicos...'

INSERT INTO PERIODO_ACADEMICO (cod_periodo, nombre_periodo, anio, periodo, fecha_inicio, fecha_fin, estado_periodo)
VALUES ('2024-2', 'SEGUNDO SEMESTRE 2024', 2024, 2, TO_DATE('2024-08-01', 'YYYY-MM-DD'), TO_DATE('2024-12-15', 'YYYY-MM-DD'), 'FINALIZADO');

INSERT INTO PERIODO_ACADEMICO (cod_periodo, nombre_periodo, anio, periodo, fecha_inicio, fecha_fin, estado_periodo)
VALUES ('2025-1', 'PRIMER SEMESTRE 2025', 2025, 1, TO_DATE('2025-01-15', 'YYYY-MM-DD'), TO_DATE('2025-06-15', 'YYYY-MM-DD'), 'EN_CURSO');

INSERT INTO PERIODO_ACADEMICO (cod_periodo, nombre_periodo, anio, periodo, fecha_inicio, fecha_fin, estado_periodo)
VALUES ('2025-2', 'SEGUNDO SEMESTRE 2025', 2025, 2, TO_DATE('2025-08-01', 'YYYY-MM-DD'), TO_DATE('2025-12-15', 'YYYY-MM-DD'), 'PROGRAMADO');

BEGIN
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ 3 Periodos Académicos insertados');
END;
/

-- =====================================================
-- 4. DOCENTES
-- =====================================================

PROMPT ''
PROMPT 'Insertando Docentes...'

DECLARE
    v_cod_facultad_ing NUMBER;
BEGIN
    SELECT cod_facultad INTO v_cod_facultad_ing FROM FACULTAD WHERE sigla = 'FI';
    
    INSERT INTO DOCENTE (cod_docente, tipo_documento, num_documento, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, titulo_academico, nivel_formacion, tipo_vinculacion, correo_institucional, correo_personal, telefono, cod_facultad, estado_docente, fecha_vinculacion)
    VALUES ('D-000001', 'CC', '52123456', 'Jorge', 'Alberto', 'Martínez', 'López', 'Magíster en Ingeniería de Software', 'MAESTRIA', 'PLANTA', 'jorge.martinez@universidad.edu.co', 'jorge.m@gmail.com', '3101234567', v_cod_facultad_ing, 'ACTIVO', TO_DATE('2015-02-01', 'YYYY-MM-DD'));
    
    INSERT INTO DOCENTE (cod_docente, tipo_documento, num_documento, primer_nombre, primer_apellido, titulo_academico, nivel_formacion, tipo_vinculacion, correo_institucional, cod_facultad, estado_docente, fecha_vinculacion)
    VALUES ('D-000002', 'CC', '52234567', 'Ana', 'García', 'Doctor en Ciencias de la Computación', 'DOCTORADO', 'PLANTA', 'ana.garcia@universidad.edu.co', v_cod_facultad_ing, 'ACTIVO', TO_DATE('2018-03-15', 'YYYY-MM-DD'));
    
    INSERT INTO DOCENTE (cod_docente, tipo_documento, num_documento, primer_nombre, primer_apellido, titulo_academico, nivel_formacion, tipo_vinculacion, correo_institucional, cod_facultad, estado_docente, fecha_vinculacion)
    VALUES ('D-000003', 'CC', '52345678', 'Carlos', 'Rodríguez', 'Ingeniero de Sistemas', 'PROFESIONAL', 'CATEDRA', 'carlos.rodriguez@universidad.edu.co', v_cod_facultad_ing, 'ACTIVO', TO_DATE('2020-08-01', 'YYYY-MM-DD'));
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ 3 Docentes insertados');
END;
/

-- =====================================================
-- 5. ESTUDIANTES
-- =====================================================

PROMPT ''
PROMPT 'Insertando Estudiantes...'

DECLARE
    v_cod_programa NUMBER;
BEGIN
    SELECT cod_programa INTO v_cod_programa FROM PROGRAMA_ACADEMICO WHERE nombre_programa = 'Ingeniería de Sistemas';
    
    INSERT INTO ESTUDIANTE (cod_estudiante, tipo_documento, num_documento, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, fecha_nacimiento, genero, correo_institucional, correo_personal, telefono, direccion, cod_programa, estado_estudiante, fecha_ingreso)
    VALUES ('2025000001', 'CC', '1001234567', 'Juan', 'Carlos', 'Pérez', 'Gómez', TO_DATE('2003-05-15', 'YYYY-MM-DD'), 'M', 'juan.perez@est.universidad.edu.co', 'juan.perez@gmail.com', '3201234567', 'Calle 10 #20-30', v_cod_programa, 'ACTIVO', TO_DATE('2025-01-15', 'YYYY-MM-DD'));
    
    INSERT INTO ESTUDIANTE (cod_estudiante, tipo_documento, num_documento, primer_nombre, primer_apellido, segundo_apellido, fecha_nacimiento, genero, correo_institucional, cod_programa, estado_estudiante, fecha_ingreso)
    VALUES ('2025000002', 'CC', '1001234568', 'María', 'López', 'Martínez', TO_DATE('2003-08-20', 'YYYY-MM-DD'), 'F', 'maria.lopez@est.universidad.edu.co', v_cod_programa, 'ACTIVO', TO_DATE('2025-01-15', 'YYYY-MM-DD'));
    
    INSERT INTO ESTUDIANTE (cod_estudiante, tipo_documento, num_documento, primer_nombre, primer_apellido, fecha_nacimiento, genero, correo_institucional, cod_programa, estado_estudiante, fecha_ingreso)
    VALUES ('2025000003', 'CC', '1001234569', 'Pedro', 'González', TO_DATE('2003-03-10', 'YYYY-MM-DD'), 'M', 'pedro.gonzalez@est.universidad.edu.co', v_cod_programa, 'ACTIVO', TO_DATE('2025-01-15', 'YYYY-MM-DD'));
    
    INSERT INTO ESTUDIANTE (cod_estudiante, tipo_documento, num_documento, primer_nombre, primer_apellido, fecha_nacimiento, genero, correo_institucional, cod_programa, estado_estudiante, fecha_ingreso)
    VALUES ('2024000001', 'CC', '1001234570', 'Laura', 'Ramírez', TO_DATE('2002-11-25', 'YYYY-MM-DD'), 'F', 'laura.ramirez@est.universidad.edu.co', v_cod_programa, 'ACTIVO', TO_DATE('2024-01-15', 'YYYY-MM-DD'));
    
    INSERT INTO ESTUDIANTE (cod_estudiante, tipo_documento, num_documento, primer_nombre, primer_apellido, fecha_nacimiento, genero, correo_institucional, cod_programa, estado_estudiante, fecha_ingreso)
    VALUES ('2024000002', 'CC', '1001234571', 'Andrés', 'Torres', TO_DATE('2002-07-18', 'YYYY-MM-DD'), 'M', 'andres.torres@est.universidad.edu.co', v_cod_programa, 'ACTIVO', TO_DATE('2024-01-15', 'YYYY-MM-DD'));
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ 5 Estudiantes insertados');
END;
/

-- =====================================================
-- 6. ASIGNATURAS
-- =====================================================

PROMPT ''
PROMPT 'Insertando Asignaturas...'

DECLARE
    v_cod_programa NUMBER;
BEGIN
    SELECT cod_programa INTO v_cod_programa FROM PROGRAMA_ACADEMICO WHERE nombre_programa = 'Ingeniería de Sistemas';
    
    INSERT INTO ASIGNATURA (cod_asignatura, nombre_asignatura, creditos, horas_teoricas, horas_practicas, tipo_asignatura, cod_programa, semestre_sugerido, estado)
    VALUES ('IS101', 'Introducción a la Programación', 4, 3, 2, 'OBLIGATORIA', v_cod_programa, 1, 'ACTIVO');
    
    INSERT INTO ASIGNATURA (cod_asignatura, nombre_asignatura, creditos, horas_teoricas, horas_practicas, tipo_asignatura, cod_programa, semestre_sugerido, estado)
    VALUES ('IS102', 'Matemáticas Discretas', 3, 3, 0, 'OBLIGATORIA', v_cod_programa, 1, 'ACTIVO');
    
    INSERT INTO ASIGNATURA (cod_asignatura, nombre_asignatura, creditos, horas_teoricas, horas_practicas, tipo_asignatura, cod_programa, semestre_sugerido, estado)
    VALUES ('IS201', 'Estructuras de Datos', 4, 3, 2, 'OBLIGATORIA', v_cod_programa, 2, 'ACTIVO');
    
    INSERT INTO ASIGNATURA (cod_asignatura, nombre_asignatura, creditos, horas_teoricas, horas_practicas, tipo_asignatura, cod_programa, semestre_sugerido, requiere_prerrequisito, estado)
    VALUES ('IS301', 'Bases de Datos', 4, 3, 2, 'OBLIGATORIA', v_cod_programa, 3, 'S', 'ACTIVO');
    
    INSERT INTO ASIGNATURA (cod_asignatura, nombre_asignatura, creditos, horas_teoricas, horas_practicas, tipo_asignatura, cod_programa, semestre_sugerido, estado)
    VALUES ('IS302', 'Ingeniería de Software', 4, 3, 2, 'OBLIGATORIA', v_cod_programa, 3, 'ACTIVO');
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ 5 Asignaturas insertadas');
END;
/

-- =====================================================
-- 7. PRERREQUISITOS
-- =====================================================

PROMPT ''
PROMPT 'Insertando Prerrequisitos...'

INSERT INTO PRERREQUISITO (cod_asignatura, cod_asignatura_requisito, tipo_requisito)
VALUES ('IS201', 'IS101', 'OBLIGATORIO');

INSERT INTO PRERREQUISITO (cod_asignatura, cod_asignatura_requisito, tipo_requisito)
VALUES ('IS301', 'IS201', 'OBLIGATORIO');

BEGIN
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ 2 Prerrequisitos insertados');
END;
/

-- =====================================================
-- 8. TIPOS DE ACTIVIDAD EVALUATIVA
-- =====================================================

PROMPT ''
PROMPT 'Insertando Tipos de Actividad Evaluativa...'

INSERT INTO TIPO_ACTIVIDAD_EVALUATIVA (nombre_actividad, descripcion, estado)
VALUES ('PARCIAL', 'Examen parcial escrito', 'ACTIVO');

INSERT INTO TIPO_ACTIVIDAD_EVALUATIVA (nombre_actividad, descripcion, estado)
VALUES ('QUIZ', 'Evaluación corta de conocimientos', 'ACTIVO');

INSERT INTO TIPO_ACTIVIDAD_EVALUATIVA (nombre_actividad, descripcion, estado)
VALUES ('TALLER', 'Taller práctico individual o grupal', 'ACTIVO');

INSERT INTO TIPO_ACTIVIDAD_EVALUATIVA (nombre_actividad, descripcion, estado)
VALUES ('PROYECTO', 'Proyecto final de asignatura', 'ACTIVO');

INSERT INTO TIPO_ACTIVIDAD_EVALUATIVA (nombre_actividad, descripcion, estado)
VALUES ('EXPOSICION', 'Presentación oral de temas', 'ACTIVO');

BEGIN
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ 5 Tipos de Actividad insertados');
END;
/

-- =====================================================
-- 9. REGLAS DE EVALUACIÓN
-- =====================================================

PROMPT ''
PROMPT 'Insertando Reglas de Evaluación...'

DECLARE
    v_cod_tipo_parcial NUMBER;
    v_cod_tipo_quiz NUMBER;
    v_cod_tipo_proyecto NUMBER;
BEGIN
    SELECT cod_tipo_actividad INTO v_cod_tipo_parcial FROM TIPO_ACTIVIDAD_EVALUATIVA WHERE nombre_actividad = 'PARCIAL';
    SELECT cod_tipo_actividad INTO v_cod_tipo_quiz FROM TIPO_ACTIVIDAD_EVALUATIVA WHERE nombre_actividad = 'QUIZ';
    SELECT cod_tipo_actividad INTO v_cod_tipo_proyecto FROM TIPO_ACTIVIDAD_EVALUATIVA WHERE nombre_actividad = 'PROYECTO';
    
    -- Reglas para IS101
    INSERT INTO REGLA_EVALUACION (cod_asignatura, cod_tipo_actividad, porcentaje, cantidad_actividades, descripcion)
    VALUES ('IS101', v_cod_tipo_parcial, 40, 2, 'Dos parciales del 20% cada uno');
    
    INSERT INTO REGLA_EVALUACION (cod_asignatura, cod_tipo_actividad, porcentaje, cantidad_actividades, descripcion)
    VALUES ('IS101', v_cod_tipo_quiz, 30, 3, 'Tres quices del 10% cada uno');
    
    INSERT INTO REGLA_EVALUACION (cod_asignatura, cod_tipo_actividad, porcentaje, cantidad_actividades, descripcion)
    VALUES ('IS101', v_cod_tipo_proyecto, 30, 1, 'Proyecto final del curso');
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Reglas de Evaluación insertadas');
END;
/

-- =====================================================
-- 10. GRUPOS
-- =====================================================

PROMPT ''
PROMPT 'Insertando Grupos...'

INSERT INTO GRUPO (cod_asignatura, cod_periodo, numero_grupo, cod_docente, cupo_maximo, cupo_disponible, modalidad, aula, estado_grupo)
VALUES ('IS101', '2025-1', 1, 'D-000001', 30, 27, 'PRESENCIAL', 'LAB-101', 'ACTIVO');

INSERT INTO GRUPO (cod_asignatura, cod_periodo, numero_grupo, cod_docente, cupo_maximo, cupo_disponible, modalidad, aula, estado_grupo)
VALUES ('IS102', '2025-1', 1, 'D-000002', 35, 35, 'PRESENCIAL', 'AUD-201', 'ACTIVO');

INSERT INTO GRUPO (cod_asignatura, cod_periodo, numero_grupo, cod_docente, cupo_maximo, cupo_disponible, modalidad, estado_grupo)
VALUES ('IS201', '2025-1', 1, 'D-000001', 25, 25, 'VIRTUAL', 'ACTIVO');

BEGIN
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ 3 Grupos insertados');
END;
/

-- =====================================================
-- 11. HORARIOS
-- =====================================================

PROMPT ''
PROMPT 'Insertando Horarios...'

DECLARE
    v_cod_grupo NUMBER;
BEGIN
    SELECT cod_grupo INTO v_cod_grupo FROM GRUPO WHERE cod_asignatura = 'IS101' AND cod_periodo = '2025-1';
    
    INSERT INTO HORARIO (cod_grupo, dia_semana, hora_inicio, hora_fin, aula)
    VALUES (v_cod_grupo, 'LUNES', '08:00', '10:00', 'LAB-101');
    
    INSERT INTO HORARIO (cod_grupo, dia_semana, hora_inicio, hora_fin, aula)
    VALUES (v_cod_grupo, 'MIERCOLES', '08:00', '10:00', 'LAB-101');
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Horarios insertados');
END;
/

-- =====================================================
-- 12. USUARIOS DEL SISTEMA
-- =====================================================

PROMPT ''
PROMPT 'Insertando Usuarios del Sistema...'

INSERT INTO USUARIO_SISTEMA (username, password_hash, tipo_usuario, cod_referencia, correo_electronico, estado)
VALUES ('admin', 'hash_admin_password', 'ADMINISTRADOR', NULL, 'admin@universidad.edu.co', 'ACTIVO');

INSERT INTO USUARIO_SISTEMA (username, password_hash, tipo_usuario, cod_referencia, correo_electronico, estado)
VALUES ('coordinador01', 'hash_coord_password', 'COORDINADOR', NULL, 'coordinador@universidad.edu.co', 'ACTIVO');

INSERT INTO USUARIO_SISTEMA (username, password_hash, tipo_usuario, cod_referencia, correo_electronico, estado)
VALUES ('docente.jorge', 'hash_doc_password', 'DOCENTE', 'D-000001', 'jorge.martinez@universidad.edu.co', 'ACTIVO');

INSERT INTO USUARIO_SISTEMA (username, password_hash, tipo_usuario, cod_referencia, correo_electronico, estado)
VALUES ('est.juan', 'hash_est_password', 'ESTUDIANTE', '2025000001', 'juan.perez@est.universidad.edu.co', 'ACTIVO');

BEGIN
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ 4 Usuarios del Sistema insertados');
END;
/

PROMPT ''
PROMPT '========================================='
PROMPT 'Datos de Prueba Cargados Exitosamente'
PROMPT '========================================='
PROMPT ''
PROMPT 'RESUMEN:'
PROMPT '  ✓ 3 Facultades'
PROMPT '  ✓ 4 Programas Académicos'
PROMPT '  ✓ 3 Periodos Académicos'
PROMPT '  ✓ 3 Docentes'
PROMPT '  ✓ 5 Estudiantes'
PROMPT '  ✓ 5 Asignaturas'
PROMPT '  ✓ 2 Prerrequisitos'
PROMPT '  ✓ 5 Tipos de Actividad'
PROMPT '  ✓ 3 Reglas de Evaluación'
PROMPT '  ✓ 3 Grupos'
PROMPT '  ✓ 2 Horarios'
PROMPT '  ✓ 4 Usuarios del Sistema'
PROMPT ''
PROMPT 'Los datos están listos para pruebas'
PROMPT '========================================='
