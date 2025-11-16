# =====================================================
# SCRIPT DE VERIFICACIÓN Y PRUEBA - VERSION RÁPIDA
# Verifica que todos los endpoints estén funcionando
# =====================================================

$baseUrl = "http://localhost:8080/ords/academico"

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "VERIFICACIÓN DE ENDPOINTS" -ForegroundColor Cyan
Write-Host "=========================================`n" -ForegroundColor Cyan

$exitosos = 0
$fallidos = 0

# Función de prueba simple
function Test-Endpoint {
    param([string]$Name, [string]$Url)
    
    Write-Host "Probando: $Name" -ForegroundColor White
    try {
        $response = Invoke-RestMethod -Uri $Url -Method Get -ErrorAction Stop
        Write-Host "  ✓ OK" -ForegroundColor Green
        $script:exitosos++
        return $true
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        Write-Host "  ✗ Error ($code)" -ForegroundColor Red
        $script:fallidos++
        return $false
    }
}

# =====================================================
# 1. METADATA CATALOG
# =====================================================

Write-Host "`n1. METADATA CATALOG" -ForegroundColor Yellow
Write-Host "-------------------" -ForegroundColor Yellow

try {
    $modules = Invoke-RestMethod -Uri "$baseUrl/metadata-catalog/" -Method Get
    Write-Host "Módulos encontrados: $($modules.count)" -ForegroundColor Cyan
    
    $modules.items | ForEach-Object {
        Write-Host "  - $($_.name)" -ForegroundColor White
    }
    
    $exitosos++
} catch {
    Write-Host "✗ Error al obtener metadata-catalog" -ForegroundColor Red
    $fallidos++
}

# =====================================================
# 2. ESTUDIANTES
# =====================================================

Write-Host "`n2. ESTUDIANTES" -ForegroundColor Yellow
Write-Host "--------------" -ForegroundColor Yellow

Test-Endpoint -Name "GET /estudiantes/" -Url "$baseUrl/estudiantes/"

# Obtener un estudiante si existe
try {
    $estudiantes = Invoke-RestMethod -Uri "$baseUrl/estudiantes/" -Method Get
    if ($estudiantes.items -and $estudiantes.items.Count -gt 0) {
        $codEst = $estudiantes.items[0].cod_estudiante
        Test-Endpoint -Name "GET /estudiantes/$codEst" -Url "$baseUrl/estudiantes/$codEst"
        Test-Endpoint -Name "GET /estudiantes/$codEst/matriculas" -Url "$baseUrl/estudiantes/$codEst/matriculas"
    }
} catch {
    Write-Host "No se pudieron probar endpoints específicos de estudiantes" -ForegroundColor Gray
}

# =====================================================
# 3. AUTENTICACIÓN
# =====================================================

Write-Host "`n3. AUTENTICACIÓN" -ForegroundColor Yellow
Write-Host "----------------" -ForegroundColor Yellow

$loginData = @{
    email = "juan.perez@universidad.edu.co"
    password = "1234567890"
} | ConvertTo-Json

Write-Host "Probando: POST /auth/login" -ForegroundColor White
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/auth/login" `
                                   -Method Post `
                                   -Body $loginData `
                                   -ContentType "application/json" `
                                   -ErrorAction Stop
    
    if ($response.status -eq 200 -or $response.message) {
        Write-Host "  ✓ OK - Endpoint responde" -ForegroundColor Green
        $exitosos++
    } else {
        Write-Host "  ⚠ Respuesta inesperada" -ForegroundColor Yellow
        $fallidos++
    }
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    if ($code -eq 404) {
        Write-Host "  ✗ Endpoint NO EXISTE (404)" -ForegroundColor Red
    } elseif ($code -eq 401) {
        Write-Host "  ✓ OK - Endpoint existe (credenciales incorrectas es esperado)" -ForegroundColor Green
        $exitosos++
    } else {
        Write-Host "  ✗ Error ($code)" -ForegroundColor Red
    }
    $fallidos++
}

# =====================================================
# 4. MATRÍCULAS
# =====================================================

Write-Host "`n4. MATRÍCULAS" -ForegroundColor Yellow
Write-Host "-------------" -ForegroundColor Yellow

Write-Host "Probando: GET /matriculas/periodo/2025-1" -ForegroundColor White
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/matriculas/periodo/2025-1" -Method Get -ErrorAction Stop
    Write-Host "  ✓ OK" -ForegroundColor Green
    $exitosos++
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    if ($code -eq 404) {
        Write-Host "  ✗ Endpoint NO EXISTE (404)" -ForegroundColor Red
    } else {
        Write-Host "  ⚠ Error ($code) - pero el endpoint existe" -ForegroundColor Yellow
        $exitosos++
    }
    $fallidos++
}

# =====================================================
# 5. CALIFICACIONES
# =====================================================

Write-Host "`n5. CALIFICACIONES" -ForegroundColor Yellow
Write-Host "-----------------" -ForegroundColor Yellow

if ($codEst) {
    Test-Endpoint -Name "GET /calificaciones/estudiante/$codEst" -Url "$baseUrl/calificaciones/estudiante/$codEst"
} else {
    Write-Host "No hay código de estudiante para probar" -ForegroundColor Gray
}

# =====================================================
# RESUMEN
# =====================================================

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "RESUMEN" -ForegroundColor Cyan
Write-Host "=========================================`n" -ForegroundColor Cyan

$total = $exitosos + $fallidos
$porcentaje = if ($total -gt 0) { [math]::Round(($exitosos / $total) * 100, 2) } else { 0 }

Write-Host "Total de pruebas: $total" -ForegroundColor White
Write-Host "Exitosas: $exitosos" -ForegroundColor Green
Write-Host "Fallidas: $fallidos" -ForegroundColor Red
Write-Host "Porcentaje de éxito: $porcentaje%" -ForegroundColor $(if ($porcentaje -ge 80) { "Green" } else { "Yellow" })

Write-Host ""

if ($fallidos -eq 0) {
    Write-Host "🎉 ¡Todos los endpoints funcionan!" -ForegroundColor Green
} elseif ($exitosos -eq 1) {
    Write-Host "⚠ Solo el endpoint de estudiantes funciona" -ForegroundColor Yellow
    Write-Host "   Necesitas ejecutar los scripts SQL para crear los demás" -ForegroundColor Yellow
} else {
    Write-Host "⚠ Algunos endpoints faltan, verifica la instalación" -ForegroundColor Yellow
}

Write-Host ""
