CREATE OR REPLACE PACKAGE pkg_poblar_academico AS
  PROCEDURE poblar_todo;
END pkg_poblar_academico;
/

CREATE OR REPLACE PACKAGE BODY pkg_poblar_academico AS

  g_cod_facultad facultad.cod_facultad%TYPE;
  g_cod_programa programa_academico.cod_programa%TYPE;

  PROCEDURE poblar_facultad IS
  BEGIN
    FOR i IN 1..20 LOOP
      BEGIN
        MERGE INTO facultad f
        USING (SELECT 'Facultad '||i AS nombre_facultad FROM dual) src
        ON (f.nombre_facultad = src.nombre_facultad)
        WHEN NOT MATCHED THEN
          INSERT (nombre_facultad, sigla, fecha_creacion, decano_actual, estado, fecha_registro)
          VALUES ('Facultad '||i, 'F'||i, DATE '1990-01-01', 'Decano '||i, 'ACTIVO', SYSTIMESTAMP);
      EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR poblar_facultad i='||i||' - '||SQLERRM);
      END;
    END LOOP;

    SELECT cod_facultad INTO g_cod_facultad FROM facultad WHERE nombre_facultad='Facultad 1';
  END poblar_facultad;

  PROCEDURE poblar_programa IS
  BEGIN
    FOR i IN 1..20 LOOP
      BEGIN
        MERGE INTO programa_academico p
        USING (SELECT 'Programa '||i AS nombre_programa FROM dual) src
        ON (p.nombre_programa = src.nombre_programa)
        WHEN NOT MATCHED THEN
          INSERT (nombre_programa, tipo_programa, nivel_formacion, cod_facultad, creditos_totales, duracion_semestres, codigo_snies, estado, fecha_registro)
          VALUES ('Programa '||i,'PREGRADO','PROFESIONAL',g_cod_facultad,160,10,'SN'||i,'ACTIVO',SYSTIMESTAMP);
      EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR poblar_programa i='||i||' - '||SQLERRM);
      END;
    END LOOP;

    SELECT cod_programa INTO g_cod_programa FROM programa_academico WHERE nombre_programa='Programa 1';
    DBMS_OUTPUT.PUT_LINE('DEBUG: g_cod_programa='||NVL(TO_CHAR(g_cod_programa),'NULL'));
  END poblar_programa;

  PROCEDURE poblar_periodo IS
  BEGIN
    FOR i IN 1..20 LOOP
      BEGIN
        MERGE INTO periodo_academico pa
        USING (SELECT '2025-'||i AS cod_periodo FROM dual) src
        ON (pa.cod_periodo = src.cod_periodo)
        WHEN NOT MATCHED THEN
          INSERT (cod_periodo, nombre_periodo, anio, periodo, fecha_inicio, fecha_fin, estado_periodo, fecha_registro)
          VALUES ('2025-'||i,'Periodo '||i,2025,i,DATE '2025-01-01',DATE '2025-12-31','EN_CURSO',SYSTIMESTAMP);
      EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR poblar_periodo i='||i||' - '||SQLERRM);
      END;
    END LOOP;
  END poblar_periodo;

  PROCEDURE poblar_tipo_actividad IS
  BEGIN
    FOR i IN 1..20 LOOP
      BEGIN
        MERGE INTO tipo_actividad_evaluativa ta
        USING (SELECT 'Actividad '||i AS nombre_actividad FROM dual) src
        ON (ta.nombre_actividad = src.nombre_actividad)
        WHEN NOT MATCHED THEN
          INSERT (nombre_actividad, descripcion, estado, fecha_registro)
          VALUES ('Actividad '||i,'Descripción '||i,'ACTIVO',SYSTIMESTAMP);
      EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR poblar_tipo_actividad i='||i||' - '||SQLERRM);
      END;
    END LOOP;
  END poblar_tipo_actividad;

  PROCEDURE poblar_asignaturas IS
  BEGIN
    -- Asegurar que exista un programa válido en g_cod_programa
    IF g_cod_programa IS NULL THEN
      BEGIN
        SELECT cod_programa INTO g_cod_programa FROM (
          SELECT cod_programa FROM programa_academico ORDER BY cod_programa FETCH FIRST 1 ROWS ONLY
        );
      EXCEPTION WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('AVISO: No hay programas disponibles para asignar a asignaturas');
        RETURN;
      END;
    END IF;
    DBMS_OUTPUT.PUT_LINE('START poblar_asignaturas - g_cod_programa='||NVL(TO_CHAR(g_cod_programa),'NULL'));
    FOR i IN 1..20 LOOP
      DECLARE
        v_cod_asig VARCHAR2(30) := 'ASIG' || LPAD(i,5,'0');
      BEGIN
        DBMS_OUTPUT.PUT_LINE('DEBUG: intentando upsert asignatura i='||i||' cod='||v_cod_asig||' programa='||NVL(TO_CHAR(g_cod_programa),'NULL'));
        BEGIN
          MERGE INTO asignatura a
          USING (SELECT v_cod_asig AS cod_asig FROM dual) src
          ON (a.cod_asignatura = src.cod_asig)
          WHEN NOT MATCHED THEN
            INSERT (cod_asignatura, nombre_asignatura, creditos, horas_teoricas, horas_practicas, tipo_asignatura, cod_programa, semestre_sugerido, requiere_prerrequisito, estado, fecha_registro)
            VALUES (src.cod_asig, 'Asignatura '||i, 2, 3, 3, 'OBLIGATORIA', g_cod_programa, MOD(i,10)+1, 'N', 'ACTIVO', SYSTIMESTAMP);
        EXCEPTION WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('ERROR en MERGE asignatura i='||i||' cod='||v_cod_asig||' - '||SQLERRM);
          RAISE; -- re-raise so caller can see the root cause during debugging
        END;

        DBMS_OUTPUT.PUT_LINE('DEBUG: upsert exitoso asignatura '||v_cod_asig);
      EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR poblar_asignaturas i='||i||' cod='||v_cod_asig||' - '||SQLERRM);
        RAISE; -- re-raise to surface errors
      END;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('END poblar_asignaturas');
  END poblar_asignaturas;

  PROCEDURE poblar_grupos IS
    v_docente docente.cod_docente%TYPE;
  BEGIN
    FOR i IN 1..20 LOOP
      BEGIN
        -- obtener docente i (si existe)
        SELECT cod_docente INTO v_docente FROM (
          SELECT cod_docente, ROW_NUMBER() OVER (ORDER BY cod_docente) rn FROM docente
        ) WHERE rn = i;

        INSERT INTO grupo (
          cod_asignatura, cod_periodo, numero_grupo, cod_docente, cupo_maximo, cupo_disponible, modalidad, aula, estado_grupo, fecha_registro
        ) VALUES (
          'ASIG' || LPAD(i,5,'0'), '2025-1', i, v_docente, 30, 30, 'PRESENCIAL', 'Aula '||i, 'ACTIVO', SYSTIMESTAMP
        );
      EXCEPTION WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN OTHERS THEN
        NULL;
      END;
    END LOOP;
  END poblar_grupos;

  PROCEDURE poblar_matriculas IS
    v_estudiante estudiante.cod_estudiante%TYPE;
  BEGIN
    FOR i IN 1..20 LOOP
      BEGIN
        SELECT cod_estudiante INTO v_estudiante FROM (
          SELECT cod_estudiante, ROW_NUMBER() OVER (ORDER BY cod_estudiante) rn FROM estudiante
        ) WHERE rn = i;

        INSERT INTO matricula (
          cod_estudiante, cod_periodo, tipo_matricula, fecha_matricula, estado_matricula, total_creditos, valor_matricula, fecha_registro
        ) VALUES (
          v_estudiante, '2025-1', 'ORDINARIA', SYSDATE, 'ACTIVA', 16, 1000000, SYSTIMESTAMP
        );
      EXCEPTION WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN OTHERS THEN
        NULL;
      END;
    END LOOP;
  END poblar_matriculas;

  PROCEDURE poblar_estudiantes IS
  BEGIN
    FOR i IN 1..20 LOOP
      BEGIN
        INSERT INTO estudiante (
          tipo_documento, num_documento, primer_nombre, segundo_nombre,
          primer_apellido, segundo_apellido, fecha_nacimiento, genero,
          correo_institucional, correo_personal, telefono, direccion,
          cod_programa, estado_estudiante, fecha_ingreso, fecha_registro
        )
        SELECT
          'CC','1000'||i,'Nombre'||i,'Segundo'||i,'Apellido'||i,'Ape2_'||i,
          DATE '2000-01-01'+i,
          CASE MOD(i,3) WHEN 0 THEN 'M' WHEN 1 THEN 'F' ELSE 'O' END,
          'est'||i||'@correo.com','pers'||i||'@correo.com',
          '3000'||LPAD(i,3,'0'),'Dirección '||i,
          g_cod_programa,'ACTIVO',DATE '2021-01-01'+i,SYSTIMESTAMP
        FROM dual
        WHERE NOT EXISTS (
          SELECT 1 FROM estudiante WHERE num_documento='1000'||i
        );
      EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR poblar_estudiantes i='||i||' - '||SQLERRM);
      END;
    END LOOP;

    FOR i IN 1..3 LOOP
      DECLARE
        v_cod_estudiante estudiante.cod_estudiante%TYPE;
      BEGIN
        SELECT cod_estudiante INTO v_cod_estudiante 
        FROM estudiante WHERE num_documento = '1000'||i;

        INSERT INTO historial_riesgo (
          cod_estudiante, cod_periodo, nivel_riesgo, observaciones, fecha_registro
        )
        SELECT v_cod_estudiante, '2025-1',
               CASE i WHEN 1 THEN 'ALTO' WHEN 2 THEN 'MEDIO' ELSE 'ALTO' END,
               'Riesgo académico ejemplo '||i, SYSTIMESTAMP
        FROM dual
        WHERE NOT EXISTS (
          SELECT 1 FROM historial_riesgo WHERE cod_estudiante = v_cod_estudiante
        );
      EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR poblar_estudiantes insertar historial i='||i||' - '||SQLERRM);
      END;
    END LOOP;
  END poblar_estudiantes;

  PROCEDURE poblar_docentes IS
  BEGIN
    FOR i IN 1..20 LOOP
      BEGIN
        INSERT INTO docente (
          tipo_documento, num_documento, primer_nombre, segundo_nombre,
          primer_apellido, segundo_apellido, titulo_academico, nivel_formacion,
          tipo_vinculacion, correo_institucional, correo_personal,
          telefono, cod_facultad, estado_docente, fecha_vinculacion, fecha_registro
        )
        SELECT
          'CC','2000'||i,'Docente'||i,'Segundo'||i,'Apellido'||i,'Ape2_'||i,
          'Licenciado','PROFESIONAL','PLANTA','doc'||i||'@correo.com','per'||i||'@correo.com',
          '3100'||LPAD(i,3,'0'), g_cod_facultad,'ACTIVO',DATE '2020-01-01'+i,SYSTIMESTAMP
        FROM dual
        WHERE NOT EXISTS (
          SELECT 1 FROM docente WHERE num_documento='2000'||i
        );
      EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR poblar_docentes i='||i||' - '||SQLERRM);
      END;
    END LOOP;
  END poblar_docentes;

  PROCEDURE poblar_intermedias IS
    v_estudiante estudiante.cod_estudiante%TYPE;
    v_docente docente.cod_docente%TYPE;
    v_cod_matricula matricula.cod_matricula%TYPE;
    v_cod_grupo grupo.cod_grupo%TYPE;
    v_cod_detalle detalle_matricula.cod_detalle_matricula%TYPE;
  BEGIN
    FOR i IN 1..10 LOOP
      BEGIN
        -- Obtener i-ésima matrícula y grupo (orden por PK)
        SELECT cod_matricula INTO v_cod_matricula FROM (
          SELECT cod_matricula, ROW_NUMBER() OVER (ORDER BY cod_matricula) rn FROM matricula
        ) WHERE rn = i;

        SELECT cod_grupo INTO v_cod_grupo FROM (
          SELECT cod_grupo, ROW_NUMBER() OVER (ORDER BY cod_grupo) rn FROM grupo
        ) WHERE rn = i;

        -- Insertar detalle_matricula y capturar PK generado
        INSERT INTO detalle_matricula (cod_matricula, cod_grupo, fecha_inscripcion, estado_inscripcion, fecha_registro)
        VALUES (v_cod_matricula, v_cod_grupo, SYSDATE, 'INSCRITO', SYSTIMESTAMP)
        RETURNING cod_detalle_matricula INTO v_cod_detalle;

        -- Insertar nota_definitiva vinculada al detalle
        BEGIN
          INSERT INTO nota_definitiva (cod_detalle_matricula, nota_final, resultado, fecha_calculo, fecha_registro)
          VALUES (v_cod_detalle, ROUND(DBMS_RANDOM.VALUE(2,5),2), 'APROBADO', SYSDATE, SYSTIMESTAMP);
        EXCEPTION WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('ERROR poblar_intermedias insertar nota_definitiva i='||i||' - '||SQLERRM);
        END;

        -- Insertar una calificación de ejemplo
        BEGIN
          INSERT INTO calificacion (cod_detalle_matricula, cod_tipo_actividad, numero_actividad, nota, porcentaje_aplicado, fecha_calificacion, observaciones, fecha_registro)
          VALUES (v_cod_detalle, 1, 1, ROUND(DBMS_RANDOM.VALUE(2,5),2), 10, SYSDATE, 'Calificación ejemplo', SYSTIMESTAMP);
        EXCEPTION WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('ERROR poblar_intermedias insertar calificacion i='||i||' - '||SQLERRM);
        END;

        -- Asignar director de trabajo de grado si existe docente para la posición
        BEGIN
          SELECT cod_docente INTO v_docente FROM (
            SELECT cod_docente, ROW_NUMBER() OVER (ORDER BY cod_docente) rn FROM docente
          ) WHERE rn = i;
        EXCEPTION WHEN OTHERS THEN
          v_docente := NULL;
        END;

        IF v_docente IS NOT NULL THEN
          BEGIN
            INSERT INTO director_trabajo_grado (cod_docente, cod_estudiante, titulo_trabajo, fecha_registro)
            VALUES (v_docente,
                    (SELECT cod_estudiante FROM (
                       SELECT cod_estudiante, ROW_NUMBER() OVER (ORDER BY cod_estudiante) rn FROM estudiante
                     ) WHERE rn = i),
                    'Trabajo e jemplo '||i, SYSTIMESTAMP);
          EXCEPTION WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR poblar_intermedias director_trabajo i='||i||' - '||SQLERRM);
          END;
        END IF;

      EXCEPTION WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR poblar_intermedias (outer) i='||i||' - '||SQLERRM);
      END;
    END LOOP;
  END poblar_intermedias;

  PROCEDURE poblar_todo IS
  BEGIN
    poblar_facultad;
    poblar_programa;
    poblar_periodo;
    poblar_tipo_actividad;
    poblar_asignaturas;
    poblar_docentes;
    poblar_estudiantes;
    poblar_grupos;
    poblar_matriculas;
    poblar_intermedias;
  END poblar_todo;

END pkg_poblar_academico;
/

commit;
select * from ACADEMICO.ASIGNATURA; 
select * from Academico.DOCENTE;
select * from Academico.ESTUDIANTE; 
select * from Academico.HISTORIAL_RIESGO;
select * from Academico.MATRICULA;
select * from Academico.PERIODO_ACADEMICO;
select * from Academico.NOTA_DEFINITIVA;
select * from Academico.GRUPO; 
select * from Academico.DETALLE_MATRICULA;
select * from Academico.CALIFICACION;
select * from Academico.DIRECTOR_TRABAJO_GRADO;
select * from Academico.USUARIO_SISTEMA;
SELECT t.table_name,
       NVL(t.num_rows, -1) AS num_rows,
       NVL(c.comments, '(sin comentario)') AS comentario,
       (SELECT COUNT(*) 
        FROM all_tab_columns col 
        WHERE col.owner = 'ACADEMICO' 
          AND col.table_name = t.table_name) AS columnas,
       t.last_analyzed
FROM all_tables t
LEFT JOIN all_tab_comments c
  ON t.owner = c.owner AND t.table_name = c.table_name
WHERE t.owner = 'ACADEMICO'
ORDER BY t.table_name;
SELECT cod_periodo, estado_periodo, TO_CHAR(fecha_inicio,'DD/MM/YYYY') fecha_inicio, TO_CHAR(fecha_fin,'DD/MM/YYYY') fecha_fin
FROM PERIODO_ACADEMICO
WHERE cod_periodo IN ('2025-1','2025-2');
SELECT cod_ventana_calendario, cod_periodo, tipo_ventana, estado_ventana,
       TO_CHAR(fecha_inicio,'DD/MM/YYYY') fecha_inicio, TO_CHAR(fecha_fin,'DD/MM/YYYY') fecha_fin
FROM VENTANA_CALENDARIO
WHERE tipo_ventana = 'MATRICULA' AND cod_periodo IN ('2025-1','2025-2');


INSERT INTO nota_definitiva (cod_detalle_matricula, nota_final, resultado, fecha_calculo, fecha_registro)
VALUES (:COD, 2.5, 'PERDIDA', SYSDATE, SYSTIMESTAMP);
COMMIT;
SELECT cod_detalle_matricula, estado_inscripcion FROM detalle_matricula WHERE cod_detalle_matricula = :COD;