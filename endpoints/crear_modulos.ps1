# =====================================================
# SCRIPT PARA CREAR MÓDULOS ORDS
# =====================================================

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "   CREAR MÓDULOS ORDS FALTANTES" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Solicitar contraseña de forma segura
$password = Read-Host "Ingresa la contraseña del usuario ACADEMICO" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

Write-Host "`n📍 Conectando a la base de datos..." -ForegroundColor Yellow
Write-Host "   Usuario: ACADEMICO" -ForegroundColor White
Write-Host "   Service: xepdb1" -ForegroundColor White
Write-Host ""

# Cambiar al directorio de endpoints
Set-Location "C:\Users\murde\ProyectoFinalBases\scriptsBD\endpoints"

# Ejecutar el script SQL
$sqlCmd = "sqlplus -S academico/$plainPassword@//localhost:1521/xepdb1"
Write-Host "🔧 Ejecutando instalar_directo.sql...`n" -ForegroundColor Cyan

Get-Content instalar_directo.sql | & cmd /c $sqlCmd

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "   ✅ PROCESO COMPLETADO" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ahora verifica los endpoints en:" -ForegroundColor Yellow
Write-Host "http://localhost:8080/ords/academico/metadata-catalog/" -ForegroundColor White
Write-Host ""

# Limpiar la contraseña de memoria
$plainPassword = $null
[System.GC]::Collect()

Read-Host "Presiona Enter para salir"
