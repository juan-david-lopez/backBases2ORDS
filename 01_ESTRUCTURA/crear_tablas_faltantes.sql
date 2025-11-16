-- ============================================================
-- CREAR 4 TABLAS FALTANTES DEL MODELO
-- Sistema de Gestión Académica
-- ============================================================

-- ============================================================
-- 1. TABLA SALON (Aulas/Salones de clase)
-- ============================================================
CREATE TABLE SALON (
    cod_salon NUMBER(8) NOT NULL,
    nombre_salon VARCHAR2(50) NOT NULL,
    edificio VARCHAR2(50) NOT NULL,
    capacidad NUMBER(4) NOT NULL,
    tipo_salon VARCHAR2(30), -- TEORICA, LABORATORIO, AUDITORIO, etc.
    equipamiento VARCHAR2(500), -- Descripción del equipamiento
    estado_salon VARCHAR2(15) DEFAULT 'DISPONIBLE', -- DISPONIBLE, OCUPADO, MANTENIMIENTO
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT PK_SALON PRIMARY KEY (cod_salon),
    CONSTRAINT CHK_CAPACIDAD_SALON CHECK (capacidad > 0),
    CONSTRAINT CHK_ESTADO_SALON CHECK (estado_salon IN ('DISPONIBLE', 'OCUPADO', 'MANTENIMIENTO', 'INACTIVO'))
);

-- ============================================================
-- 2. TABLA HORARIO_GRUPO (Horarios detallados por grupo)
-- ============================================================
CREATE TABLE HORARIO_GRUPO (
    cod_horario_grupo NUMBER(15) NOT NULL,
    cod_grupo NUMBER(12) NOT NULL,
    cod_salon NUMBER(8),
    dia_semana VARCHAR2(15) NOT NULL,
    hora_inicio VARCHAR2(5) NOT NULL, -- Formato HH24:MI
    hora_fin VARCHAR2(5) NOT NULL,
    tipo_sesion VARCHAR2(20) DEFAULT 'TEORICA', -- TEORICA, PRACTICA, LABORATORIO
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT PK_HORARIO_GRUPO PRIMARY KEY (cod_horario_grupo),
    CONSTRAINT FK_HORARIO_GRUPO FOREIGN KEY (cod_grupo) REFERENCES GRUPO(cod_grupo),
    CONSTRAINT FK_HORARIO_SALON FOREIGN KEY (cod_salon) REFERENCES SALON(cod_salon),
    CONSTRAINT CHK_DIA_SEMANA_HORARIO CHECK (dia_semana IN ('LUNES', 'MARTES', 'MIERCOLES', 'JUEVES', 'VIERNES', 'SABADO', 'DOMINGO')),
    CONSTRAINT CHK_TIPO_SESION CHECK (tipo_sesion IN ('TEORICA', 'PRACTICA', 'LABORATORIO', 'VIRTUAL'))
);

-- ============================================================
-- 3. TABLA FORMACION_ACADEMICA_DOCENTE
-- ============================================================
CREATE TABLE FORMACION_ACADEMICA_DOCENTE (
    cod_formacion NUMBER(10) NOT NULL,
    cod_docente VARCHAR2(15) NOT NULL,
    nivel_formacion VARCHAR2(30) NOT NULL, -- PREGRADO, ESPECIALIZACION, MAESTRIA, DOCTORADO
    titulo_obtenido VARCHAR2(150) NOT NULL,
    institucion VARCHAR2(150) NOT NULL,
    pais VARCHAR2(50) DEFAULT 'COLOMBIA',
    fecha_inicio DATE,
    fecha_finalizacion DATE,
    en_curso VARCHAR2(1) DEFAULT 'N',
    area_conocimiento VARCHAR2(100),
    documento_soporte VARCHAR2(200), -- Ruta o referencia al documento
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT PK_FORMACION_DOCENTE PRIMARY KEY (cod_formacion),
    CONSTRAINT FK_FORMACION_DOCENTE FOREIGN KEY (cod_docente) REFERENCES DOCENTE(cod_docente),
    CONSTRAINT CHK_NIVEL_FORMACION CHECK (nivel_formacion IN ('PREGRADO', 'ESPECIALIZACION', 'MAESTRIA', 'DOCTORADO', 'POSTDOCTORADO')),
    CONSTRAINT CHK_EN_CURSO CHECK (en_curso IN ('S', 'N')),
    CONSTRAINT CHK_FECHAS_FORMACION CHECK (fecha_finalizacion IS NULL OR fecha_finalizacion >= fecha_inicio)
);

-- ============================================================
-- 4. TABLA HISTORIAL_ACADEMICO (Registro completo del estudiante)
-- ============================================================
CREATE TABLE HISTORIAL_ACADEMICO (
    cod_historial NUMBER(15) NOT NULL,
    cod_estudiante VARCHAR2(20) NOT NULL,
    cod_periodo VARCHAR2(20) NOT NULL,
    cod_asignatura VARCHAR2(10) NOT NULL,
    nombre_asignatura VARCHAR2(150) NOT NULL,
    creditos NUMBER(2) NOT NULL,
    nota_final NUMBER(3,1),
    resultado VARCHAR2(15), -- APROBADO, REPROBADO, CURSO, VALIDADO, HOMOLOGADO
    numero_intento NUMBER(1) DEFAULT 1,
    tipo_registro VARCHAR2(20) DEFAULT 'NORMAL', -- NORMAL, VALIDACION, HOMOLOGACION, SUFICIENCIA
    cod_docente VARCHAR2(15),
    nombre_docente VARCHAR2(150),
    observaciones VARCHAR2(500),
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT PK_HISTORIAL_ACADEMICO PRIMARY KEY (cod_historial),
    CONSTRAINT FK_HISTORIAL_ESTUDIANTE FOREIGN KEY (cod_estudiante) REFERENCES ESTUDIANTE(cod_estudiante),
    CONSTRAINT FK_HISTORIAL_ASIGNATURA FOREIGN KEY (cod_asignatura) REFERENCES ASIGNATURA(cod_asignatura),
    CONSTRAINT CHK_RESULTADO_HISTORIAL CHECK (resultado IN ('APROBADO', 'REPROBADO', 'CURSO', 'VALIDADO', 'HOMOLOGADO', 'RETIRADO')),
    CONSTRAINT CHK_NUMERO_INTENTO CHECK (numero_intento BETWEEN 1 AND 3),
    CONSTRAINT CHK_TIPO_REGISTRO CHECK (tipo_registro IN ('NORMAL', 'VALIDACION', 'HOMOLOGACION', 'SUFICIENCIA', 'TRANSFERENCIA'))
);

-- ============================================================
-- SECUENCIAS PARA LAS NUEVAS TABLAS
-- ============================================================
CREATE SEQUENCE SEQ_SALON START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_HORARIO_GRUPO START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_FORMACION_DOCENTE START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_HISTORIAL_ACADEMICO START WITH 1 INCREMENT BY 1 NOCACHE;

-- ============================================================
-- ÍNDICES PARA OPTIMIZAR CONSULTAS
-- ============================================================
CREATE INDEX IDX_HORARIO_GRUPO_DIA ON HORARIO_GRUPO(dia_semana, hora_inicio);
CREATE INDEX IDX_HORARIO_SALON ON HORARIO_GRUPO(cod_salon, dia_semana);
CREATE INDEX IDX_FORMACION_DOCENTE ON FORMACION_ACADEMICA_DOCENTE(cod_docente, nivel_formacion);
CREATE INDEX IDX_HISTORIAL_ESTUDIANTE ON HISTORIAL_ACADEMICO(cod_estudiante, cod_periodo);
CREATE INDEX IDX_HISTORIAL_ASIGNATURA ON HISTORIAL_ACADEMICO(cod_asignatura, resultado);

-- ============================================================
-- DATOS DE PRUEBA - SALONES
-- ============================================================
INSERT INTO SALON VALUES (1, 'A-101', 'Bloque A', 40, 'TEORICA', 'Tablero, Proyector, 40 sillas', 'DISPONIBLE', SYSTIMESTAMP);
INSERT INTO SALON VALUES (2, 'A-102', 'Bloque A', 35, 'TEORICA', 'Tablero, Proyector, 35 sillas', 'DISPONIBLE', SYSTIMESTAMP);
INSERT INTO SALON VALUES (3, 'B-201', 'Bloque B', 30, 'LABORATORIO', 'Computadores, Proyector, Red', 'DISPONIBLE', SYSTIMESTAMP);
INSERT INTO SALON VALUES (4, 'B-202', 'Bloque B', 25, 'LABORATORIO', 'Equipos especializados', 'DISPONIBLE', SYSTIMESTAMP);
INSERT INTO SALON VALUES (5, 'C-301', 'Bloque C', 100, 'AUDITORIO', 'Sistema de sonido, Proyector', 'DISPONIBLE', SYSTIMESTAMP);

-- ============================================================
-- DATOS DE PRUEBA - HORARIOS (Ejemplo para grupos existentes)
-- ============================================================
BEGIN
    -- Obtener grupos existentes y asignar horarios
    FOR grupo IN (SELECT cod_grupo FROM GRUPO WHERE estado_grupo = 'ACTIVO' AND ROWNUM <= 5) LOOP
        -- Lunes y Miércoles 7-9am
        INSERT INTO HORARIO_GRUPO VALUES (
            SEQ_HORARIO_GRUPO.NEXTVAL,
            grupo.cod_grupo,
            1, -- Salón A-101
            'LUNES',
            '07:00',
            '09:00',
            'TEORICA',
            SYSTIMESTAMP
        );
        
        INSERT INTO HORARIO_GRUPO VALUES (
            SEQ_HORARIO_GRUPO.NEXTVAL,
            grupo.cod_grupo,
            1,
            'MIERCOLES',
            '07:00',
            '09:00',
            'TEORICA',
            SYSTIMESTAMP
        );
    END LOOP;
END;
/

-- ============================================================
-- DATOS DE PRUEBA - FORMACIÓN DOCENTE
-- ============================================================
BEGIN
    FOR docente IN (SELECT cod_docente, primer_nombre, primer_apellido FROM DOCENTE WHERE ROWNUM <= 5) LOOP
        -- Pregrado
        INSERT INTO FORMACION_ACADEMICA_DOCENTE VALUES (
            SEQ_FORMACION_DOCENTE.NEXTVAL,
            docente.cod_docente,
            'PREGRADO',
            'Ingeniero de Sistemas',
            'Universidad Nacional',
            'COLOMBIA',
            TO_DATE('2010-01-01', 'YYYY-MM-DD'),
            TO_DATE('2015-06-01', 'YYYY-MM-DD'),
            'N',
            'Ingeniería de Software',
            NULL,
            SYSTIMESTAMP
        );
        
        -- Maestría
        INSERT INTO FORMACION_ACADEMICA_DOCENTE VALUES (
            SEQ_FORMACION_DOCENTE.NEXTVAL,
            docente.cod_docente,
            'MAESTRIA',
            'Magíster en Ingeniería de Software',
            'Universidad de los Andes',
            'COLOMBIA',
            TO_DATE('2016-01-01', 'YYYY-MM-DD'),
            TO_DATE('2018-12-01', 'YYYY-MM-DD'),
            'N',
            'Ingeniería de Software',
            NULL,
            SYSTIMESTAMP
        );
    END LOOP;
END;
/

-- ============================================================
-- DATOS DE PRUEBA - HISTORIAL ACADÉMICO
-- ============================================================
BEGIN
    -- Copiar datos de NOTA_DEFINITIVA a HISTORIAL_ACADEMICO
    FOR nota IN (
        SELECT 
            e.cod_estudiante,
            m.cod_periodo,
            a.cod_asignatura,
            a.nombre_asignatura,
            a.creditos,
            nd.nota_final,
            nd.resultado,
            d.cod_docente,
            d.primer_nombre || ' ' || d.primer_apellido as nombre_docente
        FROM NOTA_DEFINITIVA nd
        JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
        JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
        JOIN ESTUDIANTE e ON m.cod_estudiante = e.cod_estudiante
        JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
        JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
        LEFT JOIN DOCENTE d ON g.cod_docente = d.cod_docente
        WHERE ROWNUM <= 50
    ) LOOP
        INSERT INTO HISTORIAL_ACADEMICO VALUES (
            SEQ_HISTORIAL_ACADEMICO.NEXTVAL,
            nota.cod_estudiante,
            nota.cod_periodo,
            nota.cod_asignatura,
            nota.nombre_asignatura,
            nota.creditos,
            nota.nota_final,
            nota.resultado,
            1, -- Primer intento
            'NORMAL',
            nota.cod_docente,
            nota.nombre_docente,
            NULL,
            SYSTIMESTAMP
        );
    END LOOP;
END;
/

-- ============================================================
-- VERIFICACIÓN
-- ============================================================
PROMPT ============================================================
PROMPT Tablas creadas:
PROMPT ============================================================

SELECT table_name, num_rows
FROM USER_TABLES
WHERE table_name IN ('SALON', 'HORARIO_GRUPO', 'FORMACION_ACADEMICA_DOCENTE', 'HISTORIAL_ACADEMICO')
ORDER BY table_name;

PROMPT 
PROMPT ============================================================
PROMPT Secuencias creadas:
PROMPT ============================================================

SELECT sequence_name, last_number
FROM USER_SEQUENCES
WHERE sequence_name IN ('SEQ_SALON', 'SEQ_HORARIO_GRUPO', 'SEQ_FORMACION_DOCENTE', 'SEQ_HISTORIAL_ACADEMICO')
ORDER BY sequence_name;

PROMPT 
PROMPT ============================================================
PROMPT Registros insertados:
PROMPT ============================================================

SELECT 'SALON' as tabla, COUNT(*) as registros FROM SALON
UNION ALL
SELECT 'HORARIO_GRUPO', COUNT(*) FROM HORARIO_GRUPO
UNION ALL
SELECT 'FORMACION_ACADEMICA_DOCENTE', COUNT(*) FROM FORMACION_ACADEMICA_DOCENTE
UNION ALL
SELECT 'HISTORIAL_ACADEMICO', COUNT(*) FROM HISTORIAL_ACADEMICO;

COMMIT;
