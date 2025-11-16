-- =====================================================
-- FASE 2: Registrar calificaciones para las asignaturas
-- =====================================================

SET SERVEROUTPUT ON

PROMPT =====================================================
PROMPT Registrando calificaciones por asignatura
PROMPT =====================================================

-- Calificaciones para IS101 - Introducción a la Programación (cod_detalle_matricula: 12)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Registrando calificaciones para IS101...');
    
    -- Parcial 1: 4.2
    INSERT INTO CALIFICACION (cod_detalle_matricula, cod_tipo_actividad, numero_actividad, nota, porcentaje_aplicado, fecha_calificacion)
    VALUES (12, 1, 1, 4.2, 30.00, SYSDATE - 15);
    
    -- Quiz 1: 4.5
    INSERT INTO CALIFICACION (cod_detalle_matricula, cod_tipo_actividad, numero_actividad, nota, porcentaje_aplicado, fecha_calificacion)
    VALUES (12, 2, 1, 4.5, 20.00, SYSDATE - 10);
    
    -- Taller 1: 4.8
    INSERT INTO CALIFICACION (cod_detalle_matricula, cod_tipo_actividad, numero_actividad, nota, porcentaje_aplicado, fecha_calificacion)
    VALUES (12, 3, 1, 4.8, 20.00, SYSDATE - 5);
    
    -- Proyecto final: 4.6
    INSERT INTO CALIFICACION (cod_detalle_matricula, cod_tipo_actividad, numero_actividad, nota, porcentaje_aplicado, fecha_calificacion)
    VALUES (12, 4, 1, 4.6, 30.00, SYSDATE);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('  ✓ 4 calificaciones registradas');
END;
/

-- Calificaciones para IS102 - Cálculo Diferencial (cod_detalle_matricula: 13)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Registrando calificaciones para IS102...');
    
    -- Parcial 1: 3.8
    INSERT INTO CALIFICACION (cod_detalle_matricula, cod_tipo_actividad, numero_actividad, nota, porcentaje_aplicado, fecha_calificacion)
    VALUES (13, 1, 1, 3.8, 30.00, SYSDATE - 15);
    
    -- Quiz 1: 4.0
    INSERT INTO CALIFICACION (cod_detalle_matricula, cod_tipo_actividad, numero_actividad, nota, porcentaje_aplicado, fecha_calificacion)
    VALUES (13, 2, 1, 4.0, 20.00, SYSDATE - 10);
    
    -- Taller 1: 3.5
    INSERT INTO CALIFICACION (cod_detalle_matricula, cod_tipo_actividad, numero_actividad, nota, porcentaje_aplicado, fecha_calificacion)
    VALUES (13, 3, 1, 3.5, 20.00, SYSDATE - 5);
    
    -- Proyecto final: 4.2
    INSERT INTO CALIFICACION (cod_detalle_matricula, cod_tipo_actividad, numero_actividad, nota, porcentaje_aplicado, fecha_calificacion)
    VALUES (13, 4, 1, 4.2, 30.00, SYSDATE);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('  ✓ 4 calificaciones registradas');
END;
/

-- Calificaciones para IS103 - Álgebra Lineal (cod_detalle_matricula: 14)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Registrando calificaciones para IS103...');
    
    -- Parcial 1: 4.5
    INSERT INTO CALIFICACION (cod_detalle_matricula, cod_tipo_actividad, numero_actividad, nota, porcentaje_aplicado, fecha_calificacion)
    VALUES (14, 1, 1, 4.5, 30.00, SYSDATE - 15);
    
    -- Quiz 1: 4.7
    INSERT INTO CALIFICACION (cod_detalle_matricula, cod_tipo_actividad, numero_actividad, nota, porcentaje_aplicado, fecha_calificacion)
    VALUES (14, 2, 1, 4.7, 20.00, SYSDATE - 10);
    
    -- Taller 1: 4.3
    INSERT INTO CALIFICACION (cod_detalle_matricula, cod_tipo_actividad, numero_actividad, nota, porcentaje_aplicado, fecha_calificacion)
    VALUES (14, 3, 1, 4.3, 20.00, SYSDATE - 5);
    
    -- Proyecto final: 4.8
    INSERT INTO CALIFICACION (cod_detalle_matricula, cod_tipo_actividad, numero_actividad, nota, porcentaje_aplicado, fecha_calificacion)
    VALUES (14, 4, 1, 4.8, 30.00, SYSDATE);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('  ✓ 4 calificaciones registradas');
END;
/

-- Calificaciones para IS104 - Fundamentos de Ingeniería (cod_detalle_matricula: 15)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Registrando calificaciones para IS104...');
    
    -- Parcial 1: 4.0
    INSERT INTO CALIFICACION (cod_detalle_matricula, cod_tipo_actividad, numero_actividad, nota, porcentaje_aplicado, fecha_calificacion)
    VALUES (15, 1, 1, 4.0, 30.00, SYSDATE - 15);
    
    -- Quiz 1: 4.3
    INSERT INTO CALIFICACION (cod_detalle_matricula, cod_tipo_actividad, numero_actividad, nota, porcentaje_aplicado, fecha_calificacion)
    VALUES (15, 2, 1, 4.3, 20.00, SYSDATE - 10);
    
    -- Taller 1: 4.1
    INSERT INTO CALIFICACION (cod_detalle_matricula, cod_tipo_actividad, numero_actividad, nota, porcentaje_aplicado, fecha_calificacion)
    VALUES (15, 3, 1, 4.1, 20.00, SYSDATE - 5);
    
    -- Proyecto final: 4.4
    INSERT INTO CALIFICACION (cod_detalle_matricula, cod_tipo_actividad, numero_actividad, nota, porcentaje_aplicado, fecha_calificacion)
    VALUES (15, 4, 1, 4.4, 30.00, SYSDATE);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('  ✓ 4 calificaciones registradas');
END;
/

PROMPT
PROMPT =====================================================
PROMPT Calculando notas definitivas
PROMPT =====================================================

-- Calcular nota definitiva para cada asignatura
BEGIN
    DBMS_OUTPUT.PUT_LINE('Calculando notas definitivas...');
    
    -- IS101: (4.2*0.3 + 4.5*0.2 + 4.8*0.2 + 4.6*0.3) = 4.52
    INSERT INTO NOTA_DEFINITIVA (cod_detalle_matricula, nota_final, resultado, fecha_calculo)
    VALUES (12, 4.5, 'APROBADO', SYSDATE);
    
    -- IS102: (3.8*0.3 + 4.0*0.2 + 3.5*0.2 + 4.2*0.3) = 3.9
    INSERT INTO NOTA_DEFINITIVA (cod_detalle_matricula, nota_final, resultado, fecha_calculo)
    VALUES (13, 3.9, 'APROBADO', SYSDATE);
    
    -- IS103: (4.5*0.3 + 4.7*0.2 + 4.3*0.2 + 4.8*0.3) = 4.59
    INSERT INTO NOTA_DEFINITIVA (cod_detalle_matricula, nota_final, resultado, fecha_calculo)
    VALUES (14, 4.6, 'APROBADO', SYSDATE);
    
    -- IS104: (4.0*0.3 + 4.3*0.2 + 4.1*0.2 + 4.4*0.3) = 4.2
    INSERT INTO NOTA_DEFINITIVA (cod_detalle_matricula, nota_final, resultado, fecha_calculo)
    VALUES (15, 4.2, 'APROBADO', SYSDATE);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('  ✓ 4 notas definitivas calculadas');
END;
/

PROMPT
PROMPT =====================================================
PROMPT Verificando calificaciones registradas
PROMPT =====================================================

COLUMN estudiante FORMAT A20
COLUMN asignatura FORMAT A30
COLUMN tipo_actividad FORMAT A15
COLUMN nota FORMAT 9.9

SELECT 
    e.primer_nombre || ' ' || e.primer_apellido AS estudiante,
    a.nombre_asignatura AS asignatura,
    ta.nombre_actividad AS tipo_actividad,
    c.nota,
    c.porcentaje_aplicado || '%' AS porcentaje
FROM CALIFICACION c
JOIN DETALLE_MATRICULA dm ON c.cod_detalle_matricula = dm.cod_detalle_matricula
JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
JOIN ESTUDIANTE e ON m.cod_estudiante = e.cod_estudiante
JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
JOIN TIPO_ACTIVIDAD_EVALUATIVA ta ON c.cod_tipo_actividad = ta.cod_tipo_actividad
ORDER BY a.nombre_asignatura, c.fecha_calificacion;

PROMPT
PROMPT =====================================================
PROMPT Notas definitivas
PROMPT =====================================================

SELECT 
    e.primer_nombre || ' ' || e.primer_apellido AS estudiante,
    a.nombre_asignatura AS asignatura,
    nd.nota_final,
    nd.resultado
FROM NOTA_DEFINITIVA nd
JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
JOIN ESTUDIANTE e ON m.cod_estudiante = e.cod_estudiante
JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
ORDER BY a.nombre_asignatura;

PROMPT
PROMPT =====================================================
PROMPT CALIFICACIONES REGISTRADAS EXITOSAMENTE
PROMPT =====================================================

EXIT;
