# Script para verificar CORS despues de reiniciar ORDS
Write-Host "`n=== PRUEBA DE CORS ===" -ForegroundColor Cyan

Write-Host "`n1. Probando peticion OPTIONS (preflight):" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/ords/academico/auth/login" -Method Options -Headers @{"Origin" = "http://localhost:5173"; "Access-Control-Request-Method" = "POST"; "Access-Control-Request-Headers" = "Content-Type"}
    
    Write-Host "   Status: $($response.StatusCode)" -ForegroundColor Green
    
    $corsHeaders = $response.Headers.GetEnumerator() | Where-Object { $_.Key -like "Access-Control-*" }
    
    if ($corsHeaders) {
        Write-Host "`n   Headers CORS encontrados:" -ForegroundColor Green
        $corsHeaders | ForEach-Object {
            Write-Host "   OK $($_.Key): $($_.Value)" -ForegroundColor White
        }
    } else {
        Write-Host "`n   No se encontraron headers CORS" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n2. Probando peticion POST con Origin:" -ForegroundColor Yellow
try {
    $body = @{email = "juan.nuevo@universidad.edu"; password = "1234567890"} | ConvertTo-Json
    
    $response = Invoke-WebRequest -Uri "http://localhost:8080/ords/academico/auth/login" -Method Post -Body $body -ContentType "application/json" -Headers @{"Origin" = "http://localhost:5173"}
    
    Write-Host "   Status: $($response.StatusCode)" -ForegroundColor Green
    
    $allowOrigin = $response.Headers["Access-Control-Allow-Origin"]
    if ($allowOrigin) {
        Write-Host "   OK Access-Control-Allow-Origin: $allowOrigin" -ForegroundColor Green
    } else {
        Write-Host "   Falta header Access-Control-Allow-Origin" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Cyan
