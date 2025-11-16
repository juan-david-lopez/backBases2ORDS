# =====================================================
# VERIFICACION COMPLETA DE ENDPOINTS ORDS
# =====================================================

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "   VERIFICACION DE ENDPOINTS ORDS" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:8080/ords/academico"
$testsPassed = 0
$testsTotal = 0

# Test 1: Metadata Catalog
Write-Host "1. Metadata Catalog" -ForegroundColor Yellow
try {
    $catalog = Invoke-RestMethod -Uri "$baseUrl/metadata-catalog/"
    Write-Host "   [OK] Modulos: $($catalog.items.Count)" -ForegroundColor Green
    $catalog.items | ForEach-Object { Write-Host "      - $($_.name)" -ForegroundColor White }
    $testsPassed++
} catch {
    Write-Host "   [ERROR] No responde" -ForegroundColor Red
}
$testsTotal++
Write-Host ""

# Test 2: Estudiantes
Write-Host "2. GET /estudiantes/" -ForegroundColor Yellow
try {
    $est = Invoke-RestMethod -Uri "$baseUrl/estudiantes/" -Method Get
    Write-Host "   [OK] Items: $($est.items.Count)" -ForegroundColor Green
    $testsPassed++
} catch {
    Write-Host "   [ERROR] $($_.Exception.Message)" -ForegroundColor Red
}
$testsTotal++
Write-Host ""

# Test 3: Auth Login
Write-Host "3. POST /auth/login" -ForegroundColor Yellow
try {
    $body = @{email="test@test.com"; password="test"} | ConvertTo-Json
    $auth = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $body -ContentType 'application/json'
    Write-Host "   [OK] Autenticacion funciona" -ForegroundColor Green
    if ($auth.token) {
        Write-Host "      Token: $($auth.token)" -ForegroundColor Gray
    }
    $testsPassed++
} catch {
    $status = $_.Exception.Response.StatusCode.value__
    Write-Host "   [ERROR] HTTP $status" -ForegroundColor Red
}
$testsTotal++
Write-Host ""

# Test 4: Matriculas
Write-Host "4. GET /matriculas/test" -ForegroundColor Yellow
try {
    $mat = Invoke-RestMethod -Uri "$baseUrl/matriculas/test" -Method Get
    Write-Host "   [OK] $($mat.items[0].mensaje)" -ForegroundColor Green
    $testsPassed++
} catch {
    Write-Host "   [ERROR] $($_.Exception.Message)" -ForegroundColor Red
}
$testsTotal++
Write-Host ""

# Test 5: Calificaciones
Write-Host "5. GET /calificaciones/test" -ForegroundColor Yellow
try {
    $cal = Invoke-RestMethod -Uri "$baseUrl/calificaciones/test" -Method Get
    Write-Host "   [OK] $($cal.items[0].mensaje)" -ForegroundColor Green
    $testsPassed++
} catch {
    Write-Host "   [ERROR] $($_.Exception.Message)" -ForegroundColor Red
}
$testsTotal++
Write-Host ""

# Resumen
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   RESUMEN DE PRUEBAS" -ForegroundColor White
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pruebas exitosas: $testsPassed / $testsTotal" -ForegroundColor White
Write-Host ""

if ($testsPassed -eq $testsTotal) {
    Write-Host "EXITO: Todos los endpoints funcionando!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Base URL: $baseUrl/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Modulos disponibles:" -ForegroundColor Yellow
    Write-Host "  - Estudiantes:     $baseUrl/estudiantes/" -ForegroundColor White
    Write-Host "  - Auth:            $baseUrl/auth/" -ForegroundColor White
    Write-Host "  - Matriculas:      $baseUrl/matriculas/" -ForegroundColor White
    Write-Host "  - Calificaciones:  $baseUrl/calificaciones/" -ForegroundColor White
} else {
    Write-Host "ATENCION: Algunos endpoints tienen problemas" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
