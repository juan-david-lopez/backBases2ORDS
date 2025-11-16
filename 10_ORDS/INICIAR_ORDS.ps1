# =====================================================
# INICIAR ORDS - Sistema Académico
# =====================================================

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "INICIANDO ORACLE REST DATA SERVICES (ORDS)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "URL Base: http://localhost:8080/ords/" -ForegroundColor Yellow
Write-Host "Esquema: http://localhost:8080/ords/academico/" -ForegroundColor Yellow
Write-Host ""

Write-Host "Endpoints disponibles:" -ForegroundColor Green
Write-Host "  - Estudiantes:     http://localhost:8080/ords/academico/estudiantes/" -ForegroundColor White
Write-Host "  - Matriculas:      http://localhost:8080/ords/academico/matriculas/" -ForegroundColor White
Write-Host "  - Calificaciones:  http://localhost:8080/ords/academico/calificaciones/" -ForegroundColor White
Write-Host ""

Write-Host "⚠️  IMPORTANTE: Deja esta ventana abierta mientras uses los endpoints" -ForegroundColor Red
Write-Host "⚠️  Presiona Ctrl+C para detener ORDS" -ForegroundColor Red
Write-Host ""

Set-Location "C:\Users\murde\Downloads\ords-25.3.1.289.1312"

Write-Host "Iniciando servidor..." -ForegroundColor Yellow
Write-Host ""

.\bin\ords.exe --config .\config serve --port 8080
