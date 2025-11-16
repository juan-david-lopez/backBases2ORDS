# =====================================================
# SCRIPT DE EJECUCIÓN CON SQL*PLUS
# Ejecuta los scripts SQL necesarios
# =====================================================

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "INSTALACIÓN DE ENDPOINTS - SQL*PLUS" -ForegroundColor Cyan
Write-Host "=========================================`n" -ForegroundColor Cyan

# Solicitar credenciales
Write-Host "Necesitamos conectarnos a la base de datos..." -ForegroundColor Yellow
Write-Host ""

$academicoPassword = Read-Host "Ingresa la contraseña de ACADEMICO"
$sysPassword = Read-Host "Ingresa la contraseña de SYS (para permisos)" -AsSecureString
$sysPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sysPassword))

Write-Host "`n=========================================" -ForegroundColor Yellow
Write-Host "PASO 1: OTORGANDO PERMISOS (como SYS)" -ForegroundColor Yellow
Write-Host "=========================================`n" -ForegroundColor Yellow

# Crear script temporal para SYS
$sysTempScript = @"
WHENEVER SQLERROR EXIT SQL.SQLCODE
SET SERVEROUTPUT ON
SET ECHO ON

PROMPT 'Otorgando INHERIT PRIVILEGES...'
GRANT INHERIT PRIVILEGES ON USER ORDS_METADATA TO ACADEMICO;

PROMPT 'Otorgando EXECUTE ON ORDS_METADATA.ORDS...'
GRANT EXECUTE ON ORDS_METADATA.ORDS TO ACADEMICO;

PROMPT 'Otorgando permisos de ejecución en ORDS_METADATA...'
GRANT EXECUTE ON ORDS_METADATA.ORDS_METADATA TO ACADEMICO;

PROMPT 'Permisos otorgados exitosamente!'
EXIT;
"@

$sysTempScript | Out-File -FilePath "temp_permisos.sql" -Encoding ASCII

# Ejecutar como SYS
Write-Host "Ejecutando script de permisos..." -ForegroundColor Cyan
$result = & sqlplus -S "sys/$sysPasswordPlain@localhost:1521/XEPDB1 as sysdba" "@temp_permisos.sql" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Permisos otorgados exitosamente`n" -ForegroundColor Green
} else {
    Write-Host "⚠ Posible error al otorgar permisos:" -ForegroundColor Yellow
    Write-Host $result -ForegroundColor Gray
    Write-Host ""
}

# Limpiar archivo temporal
Remove-Item "temp_permisos.sql" -ErrorAction SilentlyContinue

Write-Host "`n=========================================" -ForegroundColor Yellow
Write-Host "PASO 2: CREANDO ENDPOINTS (como ACADEMICO)" -ForegroundColor Yellow
Write-Host "=========================================`n" -ForegroundColor Yellow

# Crear script temporal para ACADEMICO
$academicoTempScript = @"
WHENEVER SQLERROR CONTINUE
SET SERVEROUTPUT ON
SET ECHO ON
SET FEEDBACK ON

-- =====================================================
-- MÓDULO: AUTENTICACIÓN
-- =====================================================
PROMPT ''
PROMPT 'Creando módulo de autenticación...'

BEGIN
    ORDS.DEFINE_MODULE(
        p_module_name => 'auth',
        p_base_path => 'auth/',
        p_items_per_page => 0
    );
    DBMS_OUTPUT.PUT_LINE('✓ Módulo auth creado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('⚠ Error o módulo ya existe: ' || SQLERRM);
END;
/

-- =====================================================
-- ENDPOINT: POST /auth/login
-- =====================================================
PROMPT 'Creando endpoint POST /auth/login...'

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'auth',
        p_pattern => 'login'
    );

    ORDS.DEFINE_HANDLER(
        p_module_name => 'auth',
        p_pattern => 'login',
        p_method => 'POST',
        p_source_type => ORDS.SOURCE_TYPE_PLSQL,
        p_source => 'DECLARE
    v_count NUMBER;
    v_password_hash VARCHAR2(200);
BEGIN
    v_password_hash := DBMS_CRYPTO.HASH(
        UTL_I18N.STRING_TO_RAW(:password, ''AL32UTF8''), 2
    );
    
    SELECT COUNT(*) INTO v_count
    FROM USUARIO_SISTEMA
    WHERE username = :email
    AND password_hash = v_password_hash
    AND estado = ''ACTIVO'';
    
    IF v_count > 0 THEN
        :status := 200;
        :message := ''Autenticación exitosa'';
    ELSE
        :status := 401;
        :message := ''Usuario o contraseña incorrectos'';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        :status := 500;
        :message := ''Error: '' || SQLERRM;
END;'
    );
    
    DBMS_OUTPUT.PUT_LINE('✓ Endpoint POST /auth/login creado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('⚠ Error o endpoint ya existe: ' || SQLERRM);
END;
/

-- =====================================================
-- MÓDULO: MATRÍCULAS
-- =====================================================
PROMPT ''
PROMPT 'Creando módulo de matrículas...'

BEGIN
    ORDS.DEFINE_MODULE(
        p_module_name => 'matriculas',
        p_base_path => 'matriculas/',
        p_items_per_page => 25
    );
    DBMS_OUTPUT.PUT_LINE('✓ Módulo matriculas creado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('⚠ Error o módulo ya existe: ' || SQLERRM);
END;
/

-- =====================================================
-- ENDPOINT: GET /matriculas/periodo/:cod_periodo
-- =====================================================
PROMPT 'Creando endpoint GET /matriculas/periodo/:cod_periodo...'

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'matriculas',
        p_pattern => 'periodo/:cod_periodo'
    );

    ORDS.DEFINE_HANDLER(
        p_module_name => 'matriculas',
        p_pattern => 'periodo/:cod_periodo',
        p_method => 'GET',
        p_source_type => 'json/collection',
        p_source => 'SELECT 
            m.cod_matricula,
            m.cod_estudiante,
            e.primer_nombre || '' '' || e.primer_apellido as estudiante,
            m.fecha_matricula,
            m.estado_matricula,
            m.total_creditos
        FROM MATRICULA m
        JOIN ESTUDIANTE e ON m.cod_estudiante = e.cod_estudiante
        WHERE m.cod_periodo = :cod_periodo
        ORDER BY m.fecha_matricula DESC'
    );
    
    DBMS_OUTPUT.PUT_LINE('✓ Endpoint GET /matriculas/periodo/:cod_periodo creado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('⚠ Error o endpoint ya existe: ' || SQLERRM);
END;
/

-- =====================================================
-- MÓDULO: CALIFICACIONES
-- =====================================================
PROMPT ''
PROMPT 'Creando módulo de calificaciones...'

BEGIN
    ORDS.DEFINE_MODULE(
        p_module_name => 'calificaciones',
        p_base_path => 'calificaciones/',
        p_items_per_page => 25
    );
    DBMS_OUTPUT.PUT_LINE('✓ Módulo calificaciones creado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('⚠ Error o módulo ya existe: ' || SQLERRM);
END;
/

-- =====================================================
-- ENDPOINT: GET /calificaciones/estudiante/:cod_estudiante
-- =====================================================
PROMPT 'Creando endpoint GET /calificaciones/estudiante/:cod_estudiante...'

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'calificaciones',
        p_pattern => 'estudiante/:cod_estudiante'
    );

    ORDS.DEFINE_HANDLER(
        p_module_name => 'calificaciones',
        p_pattern => 'estudiante/:cod_estudiante',
        p_method => 'GET',
        p_source_type => 'json/collection',
        p_source => 'SELECT 
            nd.cod_nota_definitiva,
            a.nombre_asignatura,
            nd.nota_final,
            nd.resultado,
            nd.fecha_registro
        FROM NOTA_DEFINITIVA nd
        JOIN DETALLE_MATRICULA dm ON nd.cod_detalle_matricula = dm.cod_detalle_matricula
        JOIN MATRICULA m ON dm.cod_matricula = m.cod_matricula
        JOIN GRUPO g ON dm.cod_grupo = g.cod_grupo
        JOIN ASIGNATURA a ON g.cod_asignatura = a.cod_asignatura
        WHERE m.cod_estudiante = :cod_estudiante
        ORDER BY nd.fecha_registro DESC'
    );
    
    DBMS_OUTPUT.PUT_LINE('✓ Endpoint GET /calificaciones/estudiante/:cod_estudiante creado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('⚠ Error o endpoint ya existe: ' || SQLERRM);
END;
/

COMMIT;

-- =====================================================
-- VERIFICACIÓN FINAL
-- =====================================================
PROMPT ''
PROMPT '========================================='
PROMPT 'MÓDULOS INSTALADOS:'
PROMPT '========================================='

SELECT name, uri_prefix, status
FROM USER_ORDS_MODULES
ORDER BY name;

PROMPT ''
PROMPT '✓ Instalación completada!'
PROMPT ''

EXIT;
"@

$academicoTempScript | Out-File -FilePath "temp_endpoints.sql" -Encoding ASCII

# Ejecutar como ACADEMICO
Write-Host "Ejecutando script de endpoints..." -ForegroundColor Cyan
$result = & sqlplus -S "academico/$academicoPassword@localhost:1521/XEPDB1" "@temp_endpoints.sql" 2>&1

Write-Host $result
Write-Host ""

# Limpiar archivo temporal
Remove-Item "temp_endpoints.sql" -ErrorAction SilentlyContinue

Write-Host "`n=========================================" -ForegroundColor Green
Write-Host "VERIFICACIÓN CON POWERSHELL" -ForegroundColor Green
Write-Host "=========================================`n" -ForegroundColor Green

Start-Sleep -Seconds 2

# Verificar metadata-catalog
Write-Host "Verificando módulos disponibles..." -ForegroundColor Cyan
try {
    $modules = Invoke-RestMethod -Uri "http://localhost:8080/ords/academico/metadata-catalog/" -Method Get
    Write-Host "✓ Módulos encontrados: $($modules.count)" -ForegroundColor Green
    $modules.items | ForEach-Object {
        Write-Host "  - $($_.name)" -ForegroundColor White
    }
} catch {
    Write-Host "✗ Error al verificar módulos" -ForegroundColor Red
}

Write-Host "`n=========================================" -ForegroundColor Green
Write-Host "¡INSTALACIÓN COMPLETADA!" -ForegroundColor Green
Write-Host "=========================================`n" -ForegroundColor Green

Write-Host "Próximo paso: Ejecutar las pruebas completas" -ForegroundColor Yellow
Write-Host "Comando: .\test_endpoints_completo.ps1`n" -ForegroundColor Cyan
