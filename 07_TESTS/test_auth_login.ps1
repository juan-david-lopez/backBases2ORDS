# Test endpoint /auth/login
$body = @{
    email = "juan.nuevo@universidad.edu"
    password = "1234567890"
} | ConvertTo-Json

Write-Host "Testing POST /auth/login..." -ForegroundColor Cyan
Write-Host "Body: $body" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/ords/academico/auth/login" `
                                  -Method Post `
                                  -Body $body `
                                  -ContentType "application/json" `
                                  -ErrorAction Stop
    
    Write-Host "`n[SUCCESS] Login exitoso!" -ForegroundColor Green
    Write-Host "Status: $($response.status)" -ForegroundColor Green
    Write-Host "Message: $($response.message)" -ForegroundColor Green
    Write-Host "Token: $($response.token)" -ForegroundColor Yellow
    Write-Host "Role: $($response.role)" -ForegroundColor Cyan
    Write-Host "Usuario: $($response.usuario_nombre) ($($response.usuario_codigo))" -ForegroundColor Cyan
    
    Write-Host "`nRespuesta completa:" -ForegroundColor Gray
    $response | ConvertTo-Json -Depth 3
    
} catch {
    Write-Host "`n[ERROR] Falló la prueba" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.ErrorDetails.Message) {
        Write-Host "`nDetalles del error:" -ForegroundColor Yellow
        $_.ErrorDetails.Message | ConvertFrom-Json | ConvertTo-Json -Depth 5
    }
}
