# =====================================================
# SCRIPT DE VERIFICACIÓN COMPLETA DE ENDPOINTS ORDS
# =====================================================

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "   VERIFICACIÓN DE ENDPOINTS ORDS" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Función auxiliar para probar endpoints
function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Method = "GET",
        [object]$Body = $null
    )
    
    Write-Host "🔍 Probando: $Name" -ForegroundColor Yellow
    Write-Host "   URL: $Url" -ForegroundColor Gray
    Write-Host "   Método: $Method" -ForegroundColor Gray
    
    try {
        $params = @{
            Uri = $Url
            Method = $Method
            ErrorAction = "Stop"
        }
        
        if ($Body) {
            $params.Body = ($Body | ConvertTo-Json)
            $params.ContentType = "application/json"
        }
        
        $response = Invoke-RestMethod @params
        Write-Host "   ✅ OK" -ForegroundColor Green
        
        # Mostrar preview de la respuesta
        if ($response.items) {
            Write-Host "   📦 Items: $($response.items.Count)" -ForegroundColor Cyan
        } elseif ($response.message) {
            Write-Host "   💬 $($response.message)" -ForegroundColor Cyan
        }
        
        return $true
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode) {
            Write-Host "   ❌ Error HTTP $statusCode" -ForegroundColor Red
        } else {
            Write-Host "   ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        }
        return $false
    }
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "1️⃣  VERIFICANDO METADATA CATALOG" -ForegroundColor White
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

try {
    $catalog = Invoke-RestMethod -Uri "http://localhost:8080/ords/academico/metadata-catalog/"
    Write-Host "✅ Metadata Catalog OK" -ForegroundColor Green
    Write-Host "📊 Total de módulos: $($catalog.items.Count)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Módulos registrados:" -ForegroundColor Yellow
    $catalog.items | ForEach-Object {
        Write-Host "   ✓ $($_.name)" -ForegroundColor White
    }
    Write-Host ""
}
catch {
    Write-Host "❌ ORDS no está respondiendo" -ForegroundColor Red
    Write-Host "   Asegúrate de que ORDS esté corriendo en otra terminal" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Presiona Enter para salir"
    exit 1
}

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "2️⃣  PROBANDO MÓDULO: ESTUDIANTES" -ForegroundColor White
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$estudiantes = 0
$estudiantes += Test-Endpoint "GET /estudiantes/" "http://localhost:8080/ords/academico/estudiantes/"
Write-Host ""

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "3️⃣  PROBANDO MÓDULO: AUTH" -ForegroundColor White
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$auth = 0
$auth += Test-Endpoint "POST /auth/login" "http://localhost:8080/ords/academico/auth/login" "POST" @{email="test@test.com"; password="test"}
Write-Host ""

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "4️⃣  PROBANDO MÓDULO: MATRICULAS" -ForegroundColor White
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$matriculas = 0
$matriculas += Test-Endpoint "GET /matriculas/test" "http://localhost:8080/ords/academico/matriculas/test"
Write-Host ""

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "5️⃣  PROBANDO MÓDULO: CALIFICACIONES" -ForegroundColor White
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$calificaciones = 0
$calificaciones += Test-Endpoint "GET /calificaciones/test" "http://localhost:8080/ords/academico/calificaciones/test"
Write-Host ""

# RESUMEN FINAL
Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "   📊 RESUMEN DE PRUEBAS" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$total = $estudiantes + $auth + $matriculas + $calificaciones
$totalPosible = 4

Write-Host "Endpoints probados: $total / $totalPosible" -ForegroundColor White
Write-Host ""

if ($estudiantes -gt 0) { Write-Host "✅ Estudiantes: OK" -ForegroundColor Green } else { Write-Host "❌ Estudiantes: FALLÓ" -ForegroundColor Red }
if ($auth -gt 0) { Write-Host "✅ Auth: OK" -ForegroundColor Green } else { Write-Host "❌ Auth: FALLÓ" -ForegroundColor Red }
if ($matriculas -gt 0) { Write-Host "✅ Matriculas: OK" -ForegroundColor Green } else { Write-Host "❌ Matriculas: FALLÓ" -ForegroundColor Red }
if ($calificaciones -gt 0) { Write-Host "✅ Calificaciones: OK" -ForegroundColor Green } else { Write-Host "❌ Calificaciones: FALLÓ" -ForegroundColor Red }

Write-Host ""

if ($total -eq $totalPosible) {
    Write-Host "🎉 ¡TODOS LOS ENDPOINTS FUNCIONANDO!" -ForegroundColor Green -BackgroundColor Black
    Write-Host ""
    Write-Host "Base URL: http://localhost:8080/ords/academico/" -ForegroundColor Cyan
} else {
    Write-Host "⚠️  Algunos endpoints tienen problemas" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Read-Host "Presiona Enter para salir"
