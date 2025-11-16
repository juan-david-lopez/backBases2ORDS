-- =====================================================
-- REINICIAR ORDS - Hacer que reconozca los cambios
-- =====================================================

-- Primero, verificar que los handlers estén allí
PROMPT 'Verificando handlers de registro_materias...'
SELECT 
    t.uri_template,
    h.method
FROM USER_ORDS_MODULES m
JOIN USER_ORDS_TEMPLATES t ON m.id = t.module_id
JOIN USER_ORDS_HANDLERS h ON t.id = h.template_id
WHERE m.name = 'registro_materias'
ORDER BY t.uri_template, h.method;

PROMPT ''
PROMPT 'Haciendo COMMIT final...'
COMMIT;

PROMPT ''
PROMPT 'LISTO - Ahora reinicia ORDS con el comando:'
PROMPT 'Stop-Process -Name java -Force; Start-Process powershell -ArgumentList ".\INICIAR_ORDS.ps1"'

EXIT;
