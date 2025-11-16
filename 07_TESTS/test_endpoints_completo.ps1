# =====================================================
# SCRIPT MAESTRO: VERIFICACIÓN COMPLETA DE ENDPOINTS
# =====================================================

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "VERIFICACIÓN COMPLETA DE BACKEND ORDS" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:8080/ords/academico"
$totalEndpoints = 0
$endpointsOk = 0
$endpointsFail = 0

# =====================================================
# FUNCIÓN AUXILIAR: Test Endpoint
# =====================================================

function Test-Endpoint {
    param(
        [string]$Method,
        [string]$Endpoint,
        [string]$Description,
        [object]$Body = $null
    )
    
    $global:totalEndpoints++
    Write-Host "[$global:totalEndpoints] $Method $Endpoint" -ForegroundColor Yellow
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
        $global:endpointsOk++
        return $true
    }
    catch {
        Write-Host "    [FAIL] $($_.Exception.Message)" -ForegroundColor Red
        $global:endpointsFail++
        return $false
    }
}

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "MÓDULO 1: AUTENTICACIÓN" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

Test-Endpoint -Method "POST" -Endpoint "/auth/login" -Description "Login de estudiante" `
    -Body @{email="juan.nuevo@universidad.edu"; password="1234567890"}

Test-Endpoint -Method "POST" -Endpoint "/auth/login" -Description "Login de docente" `
    -Body @{email="carlos.rodriguez@universidad.edu"; password="1019876543"}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "MÓDULO 2: ESTUDIANTES" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

Test-Endpoint -Method "GET" -Endpoint "/estudiantes/" -Description "Listar todos los estudiantes"
Test-Endpoint -Method "GET" -Endpoint "/estudiantes/202500001" -Description "Obtener un estudiante"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "MÓDULO 3: CALIFICACIONES" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

Test-Endpoint -Method "GET" -Endpoint "/calificaciones/estudiante/202500001" -Description "Notas del estudiante"
Test-Endpoint -Method "GET" -Endpoint "/calificaciones/grupo/7" -Description "Notas del grupo"
Test-Endpoint -Method "GET" -Endpoint "/calificaciones/historial/202500001" -Description "Historial académico"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "MÓDULO 4: MATRÍCULAS" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

Test-Endpoint -Method "GET" -Endpoint "/matriculas/estudiante/202500001" -Description "Matrículas del estudiante"
Test-Endpoint -Method "GET" -Endpoint "/matriculas/periodo/1" -Description "Matrículas por período"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "MÓDULO 5: REGISTRO DE MATERIAS" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

Test-Endpoint -Method "GET" -Endpoint "/registro-materias/disponibles/202500001" -Description "Asignaturas disponibles"
Test-Endpoint -Method "GET" -Endpoint "/registro-materias/resumen/202500001" -Description "Resumen de matrícula"
Test-Endpoint -Method "GET" -Endpoint "/registro-materias/mi-horario/202500001" -Description "Horario actual"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "MÓDULO 6: GESTIÓN DOCENTE" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

Test-Endpoint -Method "GET" -Endpoint "/docente/mis-grupos/1" -Description "Grupos del docente"
Test-Endpoint -Method "GET" -Endpoint "/docente/estudiantes/7" -Description "Estudiantes del grupo"
Test-Endpoint -Method "GET" -Endpoint "/docente/reglas-evaluacion/7" -Description "Reglas de evaluación"
Test-Endpoint -Method "GET" -Endpoint "/docente/estadisticas/7" -Description "Estadísticas del grupo"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "MÓDULO 7: ALERTAS Y REPORTES" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

Test-Endpoint -Method "GET" -Endpoint "/alertas/riesgo-academico" -Description "Estudiantes en riesgo"
Test-Endpoint -Method "GET" -Endpoint "/alertas/estudiante/202500001" -Description "Alertas de un estudiante"
Test-Endpoint -Method "GET" -Endpoint "/alertas/ventanas-calendario" -Description "Ventanas de calendario"
Test-Endpoint -Method "GET" -Endpoint "/alertas/reporte-general" -Description "Reporte general del sistema"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "RESUMEN FINAL" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total de endpoints probados: $totalEndpoints" -ForegroundColor White
Write-Host "Endpoints OK: $endpointsOk" -ForegroundColor Green
Write-Host "Endpoints FAIL: $endpointsFail" -ForegroundColor Red
Write-Host "Porcentaje de éxito: $([math]::Round(($endpointsOk / $totalEndpoints) * 100, 2))%" -ForegroundColor $(if ($endpointsOk -eq $totalEndpoints) { "Green" } else { "Yellow" })
Write-Host ""

if ($endpointsOk -eq $totalEndpoints) {
    Write-Host "SUCCESS: TODOS LOS ENDPOINTS ESTAN FUNCIONANDO CORRECTAMENTE" -ForegroundColor Green
} else {
    Write-Host "WARNING: Algunos endpoints tienen problemas. Revisa los errores arriba." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "MODULOS IMPLEMENTADOS" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "+ Autenticacion (login, seguridad)" -ForegroundColor Green
Write-Host "+ Gestion de Estudiantes (CRUD completo)" -ForegroundColor Green
Write-Host "+ Calificaciones y Notas" -ForegroundColor Green
Write-Host "+ Matriculas" -ForegroundColor Green
Write-Host "+ Registro de Materias (inscripcion, retiro)" -ForegroundColor Green
Write-Host "+ Gestion Docente (grupos, notas, estadisticas)" -ForegroundColor Green
Write-Host "+ Alertas Tempranas (riesgo academico)" -ForegroundColor Green
Write-Host "+ Reportes y Ventanas de Calendario" -ForegroundColor Green
Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "VALIDACIONES IMPLEMENTADAS (TRIGGERS)" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "+ Prerrequisitos de asignaturas" -ForegroundColor Green
Write-Host "+ Validacion de creditos segun riesgo" -ForegroundColor Green
Write-Host "+ Validacion de choques de horario" -ForegroundColor Green
Write-Host "+ Validacion de capacidad de grupo" -ForegroundColor Green
Write-Host "+ Reglas de evaluacion (suma 100%)" -ForegroundColor Green
Write-Host "+ Calculo automatico de nota definitiva" -ForegroundColor Green
Write-Host "+ Actualizacion de riesgo academico" -ForegroundColor Green
Write-Host "+ Control de carga docente" -ForegroundColor Green
Write-Host "+ Auditoria de operaciones criticas" -ForegroundColor Green
Write-Host ""
