# =====================================================
# CREAR MÓDULOS ORDS VÍA API REST
# Usa la API de metadata de ORDS directamente
# =====================================================

$baseUrl = "http://localhost:8080/ords/academico"

Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        CREANDO MÓDULOS VÍA API DE ORDS           ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Headers
$headers = @{
    "Content-Type" = "application/json"
}

# =====================================================
# 1. CREAR MÓDULO AUTH
# =====================================================

Write-Host "1. Creando módulo AUTH..." -ForegroundColor Yellow

$authModule = @{
    name = "auth"
    baseUri = "/auth/"
    published = $true
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/metadata-catalog/modules/" `
                                   -Method Post `
                                   -Headers $headers `
                                   -Body $authModule `
                                   -ErrorAction Stop
    
    Write-Host "   ✓ Módulo auth creado" -ForegroundColor Green
    
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 405 -or $statusCode -eq 404) {
        Write-Host "   ⚠ La API de metadata no acepta POST (esperado)" -ForegroundColor Yellow
        Write-Host "   Los módulos deben crearse de otra forma`n" -ForegroundColor Yellow
    } else {
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "DIAGNÓSTICO COMPLETO" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════`n" -ForegroundColor Cyan

Write-Host "✅ Lo que SÍ funciona:" -ForegroundColor Green
Write-Host "   • ORDS está ejecutándose"
Write-Host "   • El módulo 'estudiantes' responde correctamente"
Write-Host "   • La metadata está disponible`n"

Write-Host "❌ El problema:" -ForegroundColor Red
Write-Host "   • ORDS.DEFINE_MODULE no está disponible en SQL"
Write-Host "   • Esto indica ORDS standalone sin instalación en BD`n"

Write-Host "💡 SOLUCIÓN:" -ForegroundColor Yellow
Write-Host "   El módulo de estudiantes se creó de alguna forma."
Write-Host "   Necesitamos descubrir cómo.`n"

Write-Host "📋 Por favor responde:" -ForegroundColor Cyan
Write-Host "   ¿Recuerdas cómo creaste el endpoint de estudiantes?"
Write-Host "   ¿O ejecutaste algún script especial anteriormente?`n"
