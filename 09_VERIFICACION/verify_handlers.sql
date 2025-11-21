-- Verificar si los handlers de registro_materias existen
SELECT 
    m.name as module,
    t.uri_template,
    h.method,
    LENGTH(h.source) as source_length,
    CASE 
        WHEN h.source IS NOT NULL AND LENGTH(h.source) > 0 THEN 'CON SQL'
        ELSE 'SIN SQL'
    END as estado_sql
FROM USER_ORDS_MODULES m
JOIN USER_ORDS_TEMPLATES t ON m.id = t.module_id
JOIN USER_ORDS_HANDLERS h ON t.id = h.template_id
WHERE m.name = 'registro_materias'
AND t.uri_template IN (
    'disponibles/:cod_estudiante',
    'grupos/:cod_asignatura',
    'mi-horario/:cod_estudiante',
    'resumen/:cod_estudiante'
)
AND h.method = 'GET'
ORDER BY t.uri_template;


EXIT;
