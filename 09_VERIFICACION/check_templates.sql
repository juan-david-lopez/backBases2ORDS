-- Verificar templates existentes
SELECT m.name as module, t.uri_template
FROM user_ords_modules m
JOIN user_ords_templates t ON m.id = t.module_id
WHERE m.name IN ('registro_materias', 'alertas')
ORDER BY m.name, t.uri_template;

EXIT;
