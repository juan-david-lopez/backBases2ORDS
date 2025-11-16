# =====================================================
# PRUEBAS SIMPLES DE ENDPOINTS - POBLAMIENTO
# =====================================================

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "PRUEBAS SIMPLES DE ENDPOINTS" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

$baseUrl = "http://localhost:8080/ords/academico"

# =====================================================
# 1. AGREGAR ASIGNATURAS A MATRÍCULA DE JUAN
# =====================================================
Write-Host "`n1. AGREGANDO ASIGNATURAS A MATRÍCULA 1..." -ForegroundColor Yellow

# IS101 - Grupo 7
Write-Host "`nAgregando IS101 (Grupo 7)..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/matriculas/1/asignaturas" `
        -Method POST `
        -Body '{"cod_grupo": 7}' `
        -ContentType "application/json"
    Write-Host "✅ Agregada IS101" -ForegroundColor Green
    $response | ConvertTo-Json
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}

Start-Sleep -Seconds 1

# IS102 - Grupo 8
Write-Host "`nAgregando IS102 (Grupo 8)..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/matriculas/1/asignaturas" `
        -Method POST `
        -Body '{"cod_grupo": 8}' `
        -ContentType "application/json"
    Write-Host "✅ Agregada IS102" -ForegroundColor Green
    $response | ConvertTo-Json
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}

Start-Sleep -Seconds 1

# IS103 - Grupo 9
Write-Host "`nAgregando IS103 (Grupo 9)..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/matriculas/1/asignaturas" `
        -Method POST `
        -Body '{"cod_grupo": 9}' `
        -ContentType "application/json"
    Write-Host "✅ Agregada IS103" -ForegroundColor Green
    $response | ConvertTo-Json
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}

Start-Sleep -Seconds 1

# IS104 - Grupo 10
Write-Host "`nAgregando IS104 (Grupo 10)..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/matriculas/1/asignaturas" `
        -Method POST `
        -Body '{"cod_grupo": 10}' `
        -ContentType "application/json"
    Write-Host "✅ Agregada IS104" -ForegroundColor Green
    $response | ConvertTo-Json
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}

# =====================================================
# 2. CONSULTAR DETALLE DE MATRÍCULA
# =====================================================
Write-Host "`n2. CONSULTANDO DETALLE DE MATRÍCULA 1..." -ForegroundColor Yellow
try {
    $detalle = Invoke-RestMethod -Uri "$baseUrl/matriculas/1" -Method GET
    Write-Host "✅ Detalle obtenido" -ForegroundColor Green
    $detalle | ConvertTo-Json -Depth 5
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}

# =====================================================
# 3. CONSULTAR MATRÍCULAS POR PERIODO
# =====================================================
Write-Host "`n3. CONSULTANDO MATRÍCULAS DEL PERIODO 2025-1..." -ForegroundColor Yellow
try {
    $matriculas = Invoke-RestMethod -Uri "$baseUrl/matriculas/periodo/2025-1" -Method GET
    Write-Host "✅ Matrículas obtenidas" -ForegroundColor Green
    $matriculas | ConvertTo-Json -Depth 3
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}

Write-Host "`n=============================================" -ForegroundColor Green
Write-Host "PRUEBAS COMPLETADAS" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host "`nAhora ejecuta: sqlplus ACADEMICO/Academico123#@localhost:1521/XEPDB1 @consultas_tablas.sql" -ForegroundColor Yellow
