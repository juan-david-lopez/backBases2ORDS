# ========================================
# VERIFICACION COMPLETA DE ENDPOINTS ORDS
# ========================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "BACKEND ORDS - VERIFICACION COMPLETA" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:8080/ords/academico"
$script:totalEndpoints = 0
$script:endpointsOk = 0
$script:endpointsFail = 0

function Test-Endpoint {
    param(
        [string]$Method,
        [string]$Endpoint,
        [string]$Description,
        [object]$Body = $null
    )
    
    $script:totalEndpoints++
    $url = "$baseUrl$Endpoint"
    Write-Host "[$script:totalEndpoints] $Method $Endpoint" -ForegroundColor White
    Write-Host "    $Description" -ForegroundColor Gray
    
    try {
        $params = @{
            Uri = "$baseUrl$Endpoint"
            Method = $Method
            Headers = @{Accept='application/json'}
            ErrorAction = 'Stop'
        }
        
        if ($Body) {
            $params.Body = ($Body | ConvertTo-Json -Depth 5)
            $params.ContentType = 'application/json'
        }
        
        $response = Invoke-RestMethod @params
        Write-Host "    [OK] Status 200" -ForegroundColor Green
        $script:endpointsOk++
        return $true
    }
    catch {
        Write-Host "    [FAIL]" $_.Exception.Message -ForegroundColor Red
        $script:endpointsFail++
        return $false
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MODULO 1: AUTENTICACION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Test-Endpoint -Method "POST" -Endpoint "/auth/login" -Description "Login de estudiante" `
    -Body @{email="juan.nuevo@universidad.edu"; password="1234567890"}

Test-Endpoint -Method "POST" -Endpoint "/auth/login" -Description "Login de docente" `
    -Body @{email="carlos.rodriguez@universidad.edu"; password="password123"}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MODULO 2: ESTUDIANTES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Test-Endpoint -Method "GET" -Endpoint "/estudiantes/" -Description "Listar todos los estudiantes"
Test-Endpoint -Method "GET" -Endpoint "/estudiantes/202500001" -Description "Obtener un estudiante"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MODULO 3: CALIFICACIONES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Test-Endpoint -Method "GET" -Endpoint "/calificaciones/estudiante/202500001" -Description "Notas del estudiante"
Test-Endpoint -Method "GET" -Endpoint "/calificaciones/grupo/7" -Description "Notas del grupo"
Test-Endpoint -Method "GET" -Endpoint "/calificaciones/historial/202500001" -Description "Historial academico"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MODULO 4: MATRICULAS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Test-Endpoint -Method "GET" -Endpoint "/matriculas/estudiante/202500001" -Description "Matriculas del estudiante"
Test-Endpoint -Method "GET" -Endpoint "/matriculas/periodo/1" -Description "Matriculas por periodo"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MODULO 5: REGISTRO DE MATERIAS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Test-Endpoint -Method "GET" -Endpoint "/registro-materias/disponibles/202500001" -Description "Asignaturas disponibles"
Test-Endpoint -Method "GET" -Endpoint "/registro-materias/resumen/202500001" -Description "Resumen de matricula"
Test-Endpoint -Method "GET" -Endpoint "/registro-materias/mi-horario/202500001" -Description "Horario actual"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MODULO 6: GESTION DOCENTE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Test-Endpoint -Method "GET" -Endpoint "/docente/mis-grupos/1" -Description "Grupos del docente"
Test-Endpoint -Method "GET" -Endpoint "/docente/estudiantes/7" -Description "Estudiantes del grupo"
Test-Endpoint -Method "GET" -Endpoint "/docente/reglas-evaluacion/7" -Description "Reglas de evaluacion"
Test-Endpoint -Method "GET" -Endpoint "/docente/estadisticas/7" -Description "Estadisticas del grupo"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MODULO 7: ALERTAS Y REPORTES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Test-Endpoint -Method "GET" -Endpoint "/alertas/riesgo-academico" -Description "Estudiantes en riesgo"
Test-Endpoint -Method "GET" -Endpoint "/alertas/estudiante/202500001" -Description "Alertas de un estudiante"
Test-Endpoint -Method "GET" -Endpoint "/alertas/ventanas-calendario" -Description "Ventanas de calendario"
Test-Endpoint -Method "GET" -Endpoint "/alertas/reporte-general" -Description "Reporte general del sistema"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RESUMEN FINAL" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total de endpoints probados:" $script:totalEndpoints -ForegroundColor White
Write-Host "Endpoints OK:" $script:endpointsOk -ForegroundColor Green
Write-Host "Endpoints FAIL:" $script:endpointsFail -ForegroundColor Red

if ($script:totalEndpoints -gt 0) {
    $porcentaje = [math]::Round(($script:endpointsOk / $script:totalEndpoints) * 100, 2)
    Write-Host "Porcentaje de exito:" $porcentaje"%" -ForegroundColor $(if ($script:endpointsOk -eq $script:totalEndpoints) { "Green" } else { "Yellow" })
} else {
    Write-Host "Porcentaje de exito: 0%" -ForegroundColor Red
}
Write-Host ""

if ($script:endpointsOk -eq $script:totalEndpoints) {
    Write-Host "EXITO TOTAL - TODOS LOS ENDPOINTS FUNCIONAN" -ForegroundColor Green
} else {
    Write-Host "ATENCION - Algunos endpoints tienen problemas" -ForegroundColor Yellow
}

Write-Host ""
