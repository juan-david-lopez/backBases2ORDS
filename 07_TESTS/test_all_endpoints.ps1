# =====================================================
# PRUEBA COMPLETA DE TODOS LOS ENDPOINTS ORDS
# Sistema Académico - Universidad del Quindío
# =====================================================

$baseUrl = "http://localhost:8080/ords/academico"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "PRUEBA DE ENDPOINTS ORDS" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Función auxiliar para mostrar resultados
function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Method = "GET",
        [object]$Body = $null
    )
    
    Write-Host "Probando: $Name" -ForegroundColor Yellow
    Write-Host "  URL: $Url" -ForegroundColor Gray
    Write-Host "  Método: $Method" -ForegroundColor Gray
    
    try {
        if ($Body) {
            $bodyJson = $Body | ConvertTo-Json
            Write-Host "  Body: $bodyJson" -ForegroundColor Gray
            $response = Invoke-RestMethod -Uri $Url -Method $Method -Body $bodyJson -ContentType "application/json"
        } else {
            $response = Invoke-RestMethod -Uri $Url -Method $Method
        }
        
        Write-Host "  [OK] SUCCESS" -ForegroundColor Green
        Write-Host "  Response:" -ForegroundColor Gray
        $response | ConvertTo-Json -Depth 5 | Write-Host
        Write-Host ""
        return $true
    } catch {
        Write-Host "  [X] FAILED" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        return $false
    }
}

$results = @{}

# =====================================================
# 1. ENDPOINTS DE ESTUDIANTES
# =====================================================
Write-Host "`n=== ESTUDIANTES ===" -ForegroundColor Cyan
$results['GET /estudiantes/'] = Test-Endpoint "Listar estudiantes" "$baseUrl/estudiantes/"
$results['GET /estudiantes/:codigo'] = Test-Endpoint "Obtener estudiante específico" "$baseUrl/estudiantes/202500001"
$results['GET /estudiantes/:codigo/matriculas'] = Test-Endpoint "Matrículas de estudiante" "$baseUrl/estudiantes/202500001/matriculas"

# =====================================================
# 2. ENDPOINTS DE MATRÍCULAS
# =====================================================
Write-Host "`n=== MATRÍCULAS ===" -ForegroundColor Cyan
$results['GET /matriculas/estudiante/:cod'] = Test-Endpoint "Matrículas por estudiante" "$baseUrl/matriculas/estudiante/202500001"
$results['GET /matriculas/:cod'] = Test-Endpoint "Detalle de matrícula" "$baseUrl/matriculas/1"
$results['GET /matriculas/periodo/:cod'] = Test-Endpoint "Matrículas por periodo" "$baseUrl/matriculas/periodo/2025-1"

# =====================================================
# 3. ENDPOINTS DE CALIFICACIONES
# =====================================================
Write-Host "`n=== CALIFICACIONES ===" -ForegroundColor Cyan
$results['GET /calificaciones/estudiante/:cod'] = Test-Endpoint "Calificaciones de estudiante" "$baseUrl/calificaciones/estudiante/202500001"
$results['GET /calificaciones/grupo/:cod'] = Test-Endpoint "Calificaciones por grupo" "$baseUrl/calificaciones/grupo/7"
$results['GET /calificaciones/historial/:cod'] = Test-Endpoint "Historial académico" "$baseUrl/calificaciones/historial/202500001"

# =====================================================
# 4. ENDPOINTS DE REGISTRO DE MATERIAS
# =====================================================
Write-Host "`n=== REGISTRO DE MATERIAS ===" -ForegroundColor Cyan
$results['GET /registro-materias/disponibles/:cod'] = Test-Endpoint "Asignaturas disponibles" "$baseUrl/registro-materias/disponibles/202500001"
$results['GET /registro-materias/grupos/:cod'] = Test-Endpoint "Grupos de asignatura" "$baseUrl/registro-materias/grupos/IS101"
$results['GET /registro-materias/mi-horario/:cod'] = Test-Endpoint "Mi horario" "$baseUrl/registro-materias/mi-horario/202500001"
$results['GET /registro-materias/resumen/:cod'] = Test-Endpoint "Resumen de matrícula" "$baseUrl/registro-materias/resumen/202500001"

# =====================================================
# 5. ENDPOINTS DE DOCENTE
# =====================================================
Write-Host "`n=== DOCENTE ===" -ForegroundColor Cyan
$results['GET /docente/mis-grupos/:cod'] = Test-Endpoint "Mis grupos (docente)" "$baseUrl/docente/mis-grupos/D001"
$results['GET /docente/estudiantes/:cod'] = Test-Endpoint "Estudiantes del grupo" "$baseUrl/docente/estudiantes/7"
$results['GET /docente/estadisticas/:cod'] = Test-Endpoint "Estadísticas del grupo" "$baseUrl/docente/estadisticas/7"
$results['GET /docente/reglas-evaluacion/:cod'] = Test-Endpoint "Reglas de evaluación" "$baseUrl/docente/reglas-evaluacion/7"

# =====================================================
# 6. ENDPOINTS DE ALERTAS
# =====================================================
Write-Host "`n=== ALERTAS ===" -ForegroundColor Cyan
$results['GET /alertas/estudiante/:cod'] = Test-Endpoint "Alertas de estudiante" "$baseUrl/alertas/estudiante/202500001"
$results['GET /alertas/riesgo-academico'] = Test-Endpoint "Estudiantes en riesgo" "$baseUrl/alertas/riesgo-academico"
$results['GET /alertas/asistencia-baja/:cod'] = Test-Endpoint "Asistencia baja en grupo" "$baseUrl/alertas/asistencia-baja/7"
$results['GET /alertas/reporte-general'] = Test-Endpoint "Reporte general de alertas" "$baseUrl/alertas/reporte-general"
$results['GET /alertas/ventanas-calendario'] = Test-Endpoint "Ventanas de calendario" "$baseUrl/alertas/ventanas-calendario"
$results['GET /alertas/ventana-activa/:tipo'] = Test-Endpoint "Ventana activa específica" "$baseUrl/alertas/ventana-activa/MATRICULA"

# =====================================================
# RESUMEN DE RESULTADOS
# =====================================================
Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host "RESUMEN DE PRUEBAS" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

$total = $results.Count
$success = ($results.Values | Where-Object { $_ -eq $true }).Count
$failed = $total - $success
$percentage = [math]::Round(($success / $total) * 100, 2)

Write-Host "`nTotal de endpoints probados: $total" -ForegroundColor White
Write-Host "Exitosos: $success" -ForegroundColor Green
Write-Host "Fallidos: $failed" -ForegroundColor Red
Write-Host "Porcentaje de éxito: $percentage%" -ForegroundColor $(if ($percentage -ge 80) { "Green" } elseif ($percentage -ge 50) { "Yellow" } else { "Red" })

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host "DETALLE DE RESULTADOS" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

foreach ($endpoint in $results.Keys | Sort-Object) {
    $status = if ($results[$endpoint]) { "[OK]" } else { "[FAIL]" }
    $color = if ($results[$endpoint]) { "Green" } else { "Red" }
    Write-Host "$status $endpoint" -ForegroundColor $color
}

Write-Host ""
