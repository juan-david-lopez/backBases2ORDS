-- Script idempotente para insertar/actualizar docentes de producción
-- Uso: ejecutar con SERVEROUTPUT ON
SET SERVEROUTPUT ON SIZE 1000000;

BEGIN
  -- Cada MERGE usa num_documento como clave preferida; si cod_docente es provisto y existe, lo mantiene
  -- Formato de datos: cod_docente, num_documento, primer_nombre, primer_apellido

  -- Lista de docentes proporcionada
  FOR r IN (
    SELECT * FROM (
      SELECT 'D-100342' AS cod_docente, '2000001' AS num_documento, 'Docente1' AS primer_nombre, 'Apellido1' AS primer_apellido FROM dual UNION ALL
      SELECT 'D-100343','2000002','Docente2','Apellido2' FROM dual UNION ALL
      SELECT 'D-100344','2000003','Docente3','Apellido3' FROM dual UNION ALL
      SELECT 'D-100345','2000004','Docente4','Apellido4' FROM dual UNION ALL
      SELECT 'D-100346','2000005','Docente5','Apellido5' FROM dual UNION ALL
      SELECT 'D-100347','2000006','Docente6','Apellido6' FROM dual UNION ALL
      SELECT 'D-100348','2000007','Docente7','Apellido7' FROM dual UNION ALL
      SELECT 'D-100349','2000008','Docente8','Apellido8' FROM dual UNION ALL
      SELECT 'D-100350','2000009','Docente9','Apellido9' FROM dual UNION ALL
      SELECT 'D-100351','2000010','Docente10','Apellido10' FROM dual UNION ALL
      SELECT 'D-100352','2000011','Docente11','Apellido11' FROM dual UNION ALL
      SELECT 'D-100353','2000012','Docente12','Apellido12' FROM dual UNION ALL
      SELECT 'D-100354','2000013','Docente13','Apellido13' FROM dual UNION ALL
      SELECT 'D-100355','2000014','Docente14','Apellido14' FROM dual UNION ALL
      SELECT 'D-100356','2000015','Docente15','Apellido15' FROM dual UNION ALL
      SELECT 'D-100357','2000016','Docente16','Apellido16' FROM dual UNION ALL
      SELECT 'D-100358','2000017','Docente17','Apellido17' FROM dual UNION ALL
      SELECT 'D-100359','2000018','Docente18','Apellido18' FROM dual UNION ALL
      SELECT 'D-100360','2000019','Docente19','Apellido19' FROM dual UNION ALL
      SELECT 'D-100361','2000020','Docente20','Apellido20' FROM dual UNION ALL
      SELECT 'D-100370','20001','DocGrupo1','Apellido1' FROM dual UNION ALL
      SELECT 'D-100371','20002','DocGrupo2','Apellido2' FROM dual UNION ALL
      SELECT 'D-100372','20003','DocGrupo3','Apellido3' FROM dual UNION ALL
      SELECT 'D-100373','20004','DocGrupo4','Apellido4' FROM dual UNION ALL
      SELECT 'D-100374','20005','DocGrupo5','Apellido5' FROM dual UNION ALL
      SELECT 'D-100375','20006','DocGrupo6','Apellido6' FROM dual UNION ALL
      SELECT 'D-100376','20007','DocGrupo7','Apellido7' FROM dual UNION ALL
      SELECT 'D-100377','20008','DocGrupo8','Apellido8' FROM dual UNION ALL
      SELECT 'D-100378','20009','DocGrupo9','Apellido9' FROM dual UNION ALL
      SELECT 'D-100379','200010','DocGrupo10','Apellido10' FROM dual
    )
  ) LOOP
      BEGIN
        -- Primero intentar actualizar por cod_docente o num_documento
        UPDATE docente
        SET primer_nombre = r.primer_nombre,
            primer_apellido = r.primer_apellido,
            estado_docente = NVL(estado_docente,'ACTIVO')
        WHERE cod_docente = r.cod_docente
           OR num_documento = r.num_documento;

        IF SQL%ROWCOUNT = 0 THEN
          -- Insertar nuevo docente (asegurando valores no nulos)
          INSERT INTO docente (
            cod_docente, tipo_documento, num_documento, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, titulo_academico, nivel_formacion, tipo_vinculacion, correo_institucional, correo_personal, telefono, cod_facultad, estado_docente, fecha_vinculacion, fecha_registro
          ) VALUES (
            r.cod_docente, 'CC', r.num_documento, r.primer_nombre, NULL, r.primer_apellido, NULL, 'No informado', 'PROFESIONAL', 'PLANTA', r.num_documento||'@correo.com', NULL, NULL, (SELECT cod_facultad FROM facultad WHERE ROWNUM = 1), 'ACTIVO', TRUNC(SYSDATE)-365, SYSTIMESTAMP
          );
        END IF;

        DBMS_OUTPUT.PUT_LINE('Upsert docente '||r.num_documento||' -> '||r.primer_nombre||' '||r.primer_apellido);
      EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR upsert docente '||r.num_documento||' - '||SQLERRM);
      END;
  END LOOP;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('FIN: poblacion docentes completada');
END;
/

-- Verificacion
SELECT COUNT(*) AS total_docentes FROM ACADEMICO.DOCENTE;
COMMIT;
