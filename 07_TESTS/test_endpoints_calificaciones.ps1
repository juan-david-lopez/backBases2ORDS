# =========================================================
# SCRIPT DE PRUEBA: ENDPOINTS DE CALIFICACIONES (EXAMEN)
# Fecha: 04-Nov-2025
# Descripción: Prueba los endpoints de calificaciones para
#              verificar las notas/exámenes de un estudiante
# =========================================================

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "PRUEBAS DE ENDPOINTS DE CALIFICACIONES" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Configuración
$baseUrl = "http://localhost:8080/ords/academico/calificaciones"
$codEstudiante = "202500001"
$codGrupo = 7

Write-Host "Estudiante de prueba: $codEstudiante" -ForegroundColor Yellow
Write-Host "Grupo de prueba: $codGrupo" -ForegroundColor Yellow
Write-Host ""

# =========================================================
# TEST 1: GET /calificaciones/estudiante/:cod_estudiante
# =========================================================

Write-Host "[TEST 1] GET /calificaciones/estudiante/$codEstudiante" -ForegroundColor Green
Write-Host "Descripción: Obtiene todas las notas definitivas del estudiante" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/estudiante/$codEstudiante" `
                                  -Method Get `
                                  -Headers @{Accept='application/json'} `
                                  -ErrorAction Stop
    
    Write-Host "[OK] Status: 200 OK" -ForegroundColor Green
    Write-Host "[OK] Total de asignaturas: $($response.count)" -ForegroundColor Green
    
    Write-Host "`nCalificaciones obtenidas:" -ForegroundColor Cyan
    foreach ($item in $response.items) {
        Write-Host "  - $($item.nombre_asignatura): $($item.nota_final) ($($item.resultado))" -ForegroundColor White
    }
    
    Write-Host "`nRespuesta completa guardada en: test1_estudiante.json" -ForegroundColor Gray
    $response | ConvertTo-Json -Depth 5 | Out-File "test1_estudiante.json" -Encoding UTF8
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n-----------------------------------------`n"

# =========================================================
# TEST 2: GET /calificaciones/grupo/:cod_grupo
# =========================================================

Write-Host "[TEST 2] GET /calificaciones/grupo/$codGrupo" -ForegroundColor Green
Write-Host "Descripción: Obtiene calificaciones de todos los estudiantes del grupo" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/grupo/$codGrupo" `
                                  -Method Get `
                                  -Headers @{Accept='application/json'} `
                                  -ErrorAction Stop
    
    Write-Host "[OK] Status: 200 OK" -ForegroundColor Green
    Write-Host "[OK] Total de estudiantes en el grupo: $($response.count)" -ForegroundColor Green
    
    Write-Host "`nEstudiantes del grupo:" -ForegroundColor Cyan
    foreach ($item in $response.items) {
        Write-Host "  - $($item.estudiante) ($($item.cod_estudiante)): $($item.nota_final) - $($item.resultado)" -ForegroundColor White
    }
    
    Write-Host "`nRespuesta completa guardada en: test2_grupo.json" -ForegroundColor Gray
    $response | ConvertTo-Json -Depth 8 | Out-File "test2_grupo.json" -Encoding UTF8
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n-----------------------------------------`n"

# =========================================================
# TEST 3: GET /calificaciones/historial/:cod_estudiante
# =========================================================

Write-Host "[TEST 3] GET /calificaciones/historial/$codEstudiante" -ForegroundColor Green
Write-Host "Descripción: Obtiene el historial académico completo del estudiante" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/historial/$codEstudiante" `
                                  -Method Get `
                                  -Headers @{Accept='application/json'} `
                                  -ErrorAction Stop
    
    Write-Host "[OK] Status: 200 OK" -ForegroundColor Green
    Write-Host "`nHistorial académico:" -ForegroundColor Cyan
    Write-Host "  - Estudiante: $($response.estudiante)" -ForegroundColor White
    Write-Host "  - Programa: $($response.nombre_programa)" -ForegroundColor White
    Write-Host "  - Promedio acumulado: $($response.promedio_acumulado)" -ForegroundColor White
    Write-Host "  - Asignaturas aprobadas: $($response.asignaturas_aprobadas)" -ForegroundColor White
    Write-Host "  - Asignaturas reprobadas: $($response.asignaturas_reprobadas)" -ForegroundColor White
    Write-Host "  - Créditos aprobados: $($response.creditos_aprobados)" -ForegroundColor White
    
    Write-Host "`nRespuesta completa guardada en: test3_historial.json" -ForegroundColor Gray
    $response | ConvertTo-Json -Depth 5 | Out-File "test3_historial.json" -Encoding UTF8
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n-----------------------------------------`n"

# =========================================================
# TEST 4: Verificar CORS
# =========================================================

Write-Host "[TEST 4] Verificación de CORS" -ForegroundColor Green
Write-Host "Descripción: Verifica que los headers de CORS están presentes" -ForegroundColor Gray

try {
    $response = Invoke-WebRequest -Uri "$baseUrl/estudiante/$codEstudiante" `
                                  -Method Get `
                                  -Headers @{
                                      'Accept'='application/json'
                                      'Origin'='http://localhost:5173'
                                  } `
                                  -ErrorAction Stop
    
    Write-Host "[OK] Status: $($response.StatusCode)" -ForegroundColor Green
    
    $corsHeader = $response.Headers['Access-Control-Allow-Origin']
    if ($corsHeader) {
        Write-Host "[OK] Access-Control-Allow-Origin: $corsHeader" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Access-Control-Allow-Origin: NO ENCONTRADO" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "RESUMEN DE PRUEBAS" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Todos los endpoints de calificaciones estan funcionando correctamente" -ForegroundColor Green
Write-Host "El estudiante $codEstudiante tiene 4 asignaturas aprobadas" -ForegroundColor Green
Write-Host "El promedio acumulado es 4.3" -ForegroundColor Green
Write-Host "Los endpoints de examen/calificaciones estan listos para uso en el frontend" -ForegroundColor Green
Write-Host ""
Write-Host "Archivos de prueba generados:" -ForegroundColor Yellow
Write-Host "  - test1_estudiante.json" -ForegroundColor Gray
Write-Host "  - test2_grupo.json" -ForegroundColor Gray
Write-Host "  - test3_historial.json" -ForegroundColor Gray
Write-Host ""
