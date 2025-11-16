# =====================================================
# TEST ENDPOINTS: Verificar datos poblados
# =====================================================

$baseUrl = "http://localhost:8080/ords/academico"
$headers = @{
    "Content-Type" = "application/json"
}

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "PRUEBA DE ENDPOINTS REST - DATOS POBLADOS" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Listar todos los estudiantes
Write-Host "1. GET /estudiantes/ - Listar estudiantes" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/estudiantes/" -Method GET -Headers $headers
    Write-Host "   ✓ Estudiantes encontrados: $($response.count)" -ForegroundColor Green
    if ($response.items) {
        $response.items | ForEach-Object {
            Write-Host "     - $($_.cod_estudiante): $($_.primer_nombre) $($_.primer_apellido)" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "   ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 2: Obtener detalle del estudiante
Write-Host "2. GET /estudiantes/202500001 - Detalle estudiante" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/estudiantes/202500001" -Method GET -Headers $headers
    Write-Host "   ✓ Estudiante: $($response.primer_nombre) $($response.primer_apellido)" -ForegroundColor Green
    Write-Host "     Estado: $($response.estado_estudiante)" -ForegroundColor Gray
    Write-Host "     Email: $($response.correo_institucional)" -ForegroundColor Gray
} catch {
    Write-Host "   ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 3: Obtener matrículas del estudiante
Write-Host "3. GET /estudiantes/202500001/matriculas - Matrículas" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/estudiantes/202500001/matriculas" -Method GET -Headers $headers
    Write-Host "   ✓ Matrículas encontradas: $($response.count)" -ForegroundColor Green
    if ($response.items) {
        $response.items | ForEach-Object {
            Write-Host "     - Periodo: $($_.cod_periodo), Estado: $($_.estado_matricula), Créditos: $($_.total_creditos)" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "   ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 4: Obtener detalle de la matrícula
Write-Host "4. GET /matriculas/1 - Detalle matrícula con asignaturas" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/matriculas/1" -Method GET -Headers $headers
    Write-Host "   ✓ Matrícula #$($response.cod_matricula)" -ForegroundColor Green
    Write-Host "     Estudiante: $($response.estudiante)" -ForegroundColor Gray
    Write-Host "     Periodo: $($response.periodo)" -ForegroundColor Gray
    Write-Host "     Total créditos: $($response.total_creditos)" -ForegroundColor Gray
    Write-Host "     Asignaturas:" -ForegroundColor Gray
    if ($response.asignaturas) {
        $response.asignaturas | ForEach-Object {
            Write-Host "       * $($_.nombre_asignatura) ($($_.creditos) créditos) - $($_.estado_inscripcion)" -ForegroundColor DarkGray
        }
    }
} catch {
    Write-Host "   ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 5: Obtener matrículas por periodo
Write-Host "5. GET /matriculas/periodo/2025-1 - Matrículas del periodo" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/matriculas/periodo/2025-1" -Method GET -Headers $headers
    Write-Host "   ✓ Matrículas en periodo: $($response.count)" -ForegroundColor Green
    if ($response.items) {
        $response.items | ForEach-Object {
            Write-Host "     - $($_.estudiante): $($_.total_creditos) créditos" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "   ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "PRUEBAS COMPLETADAS" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
