# Script simple de instalación de endpoints
Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "INSTALACIÓN DE ENDPOINTS" -ForegroundColor Cyan
Write-Host "=========================================`n" -ForegroundColor Cyan

# Solicitar credenciales
$academicoPassword = Read-Host "Contraseña de ACADEMICO"
$sysPassword = Read-Host "Contraseña de SYS"

Write-Host "`nCreando archivos SQL temporales..." -ForegroundColor Yellow

# Crear script de permisos
@"
SET SERVEROUTPUT ON
SET ECHO ON
GRANT INHERIT PRIVILEGES ON USER ORDS_METADATA TO ACADEMICO;
GRANT EXECUTE ON ORDS_METADATA.ORDS TO ACADEMICO;
GRANT EXECUTE ON ORDS_METADATA.ORDS_METADATA TO ACADEMICO;
EXIT;
"@ | Out-File -FilePath "temp_permisos.sql" -Encoding ASCII

# Crear script de endpoints básicos
@"
SET SERVEROUTPUT ON
SET ECHO ON

BEGIN
    ORDS.DEFINE_MODULE(
        p_module_name => 'auth',
        p_base_path => 'auth/',
        p_items_per_page => 0
    );
END;
/

BEGIN
    ORDS.DEFINE_TEMPLATE(p_module_name => 'auth', p_pattern => 'login');
    ORDS.DEFINE_HANDLER(
        p_module_name => 'auth',
        p_pattern => 'login',
        p_method => 'POST',
        p_source_type => ORDS.SOURCE_TYPE_PLSQL,
        p_source => 'BEGIN :status := 200; :message := ''OK''; END;'
    );
END;
/

BEGIN
    ORDS.DEFINE_MODULE(p_module_name => 'matriculas', p_base_path => 'matriculas/', p_items_per_page => 25);
END;
/

BEGIN
    ORDS.DEFINE_MODULE(p_module_name => 'calificaciones', p_base_path => 'calificaciones/', p_items_per_page => 25);
END;
/

COMMIT;

SELECT name, uri_prefix, status FROM USER_ORDS_MODULES ORDER BY name;

EXIT;
"@ | Out-File -FilePath "temp_endpoints.sql" -Encoding ASCII

Write-Host "`nPASO 1: Otorgando permisos (SYS)..." -ForegroundColor Yellow
$cmd = "sys/${sysPassword}@localhost:1521/XEPDB1 as sysdba"
& sqlplus -S $cmd "@temp_permisos.sql"

Write-Host "`nPASO 2: Creando endpoints (ACADEMICO)..." -ForegroundColor Yellow
$cmd = "academico/${academicoPassword}@localhost:1521/XEPDB1"
& sqlplus -S $cmd "@temp_endpoints.sql"

Write-Host "`nLimpiando archivos temporales..." -ForegroundColor Gray
Remove-Item "temp_permisos.sql" -ErrorAction SilentlyContinue
Remove-Item "temp_endpoints.sql" -ErrorAction SilentlyContinue

Write-Host "`nVerificando con PowerShell..." -ForegroundColor Cyan
Start-Sleep -Seconds 2

$modules = Invoke-RestMethod -Uri "http://localhost:8080/ords/academico/metadata-catalog/" -Method Get
Write-Host "`nMódulos instalados: $($modules.count)" -ForegroundColor Green
$modules.items | ForEach-Object { Write-Host "  - $($_.name)" -ForegroundColor White }

Write-Host "`n¡Listo! Ahora ejecuta: .\test_endpoints_completo.ps1`n" -ForegroundColor Green
