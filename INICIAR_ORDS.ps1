# INICIAR_ORDS.ps1
# Script para iniciar Oracle REST Data Services (ORDS) correctamente

# Ruta al archivo ords.war (ajusta según tu instalación)
$ordsWarPath = "C:\Users\murde\Downloads\ords-25.3.1.289.1312\ords.war"

# Puerto donde se iniciará ORDS
$ordsPort = 8080

# Verifica si el archivo existe
if (-Not (Test-Path $ordsWarPath)) {
    Write-Host "ERROR: No se encontró ords.war en $ordsWarPath" -ForegroundColor Red
    exit 1
}

Write-Host "Iniciando ORDS en modo standalone en el puerto $ordsPort..." -ForegroundColor Yellow
Start-Process -NoNewWindow -FilePath "java" -ArgumentList "-jar `"$ordsWarPath`" standalone --port $ordsPort"
Write-Host "ORDS iniciado. Accede a: http://localhost:$ordsPort/ords/" -ForegroundColor Green
