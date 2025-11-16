-- Listar todos los endpoints creados en ORDS
SET LINESIZE 200
SET PAGESIZE 1000
COLUMN module_name FORMAT A25
COLUMN template_name FORMAT A50
COLUMN method FORMAT A10
COLUMN status FORMAT A10

SELECT 
    m.name AS module_name,
    t.uri_template AS template_name,
    h.method,
    CASE WHEN h.source IS NOT NULL THEN 'ACTIVO' ELSE 'INACTIVO' END AS status
FROM user_ords_modules m
JOIN user_ords_templates t ON m.id = t.module_id
LEFT JOIN user_ords_handlers h ON t.id = h.template_id
WHERE m.name IN ('auth', 'estudiantes', 'calificaciones', 'matriculas', 'registro_materias', 'docente', 'alertas')
ORDER BY m.name, t.uri_template, h.method;

EXIT;
