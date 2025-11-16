# =====================================================
# PRUEBAS DE ENDPOINTS - POBLAMIENTO VÍA REST API
# Sistema Académico - ORDS
# =====================================================

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "PRUEBAS DE ENDPOINTS REST - SISTEMA ACADÉMICO" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:8080/ords/academico"

# =====================================================
# FUNCIONES AUXILIARES
# =====================================================

function Show-Response {
    param($response, $title)
    Write-Host ""
    Write-Host "=== $title ===" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 10
}

function Show-Error {
    param($error, $title)
    Write-Host ""
    Write-Host "=== ERROR: $title ===" -ForegroundColor Red
    Write-Host $error.Exception.Message
}

# =====================================================
# 1. VERIFICAR ESTUDIANTES EXISTENTES
# =====================================================
Write-Host "1. VERIFICANDO ESTUDIANTES EXISTENTES..." -ForegroundColor Yellow
try {
    $estudiantes = Invoke-RestMethod -Uri "$baseUrl/estudiantes/" -Method GET
    Show-Response $estudiantes "Estudiantes Actuales"
    Write-Host "Total de estudiantes: $($estudiantes.count)" -ForegroundColor Cyan
} catch {
    Show-Error $_ "Verificar Estudiantes"
}

Read-Host "`nPresiona Enter para continuar con la creación de estudiantes..."

# =====================================================
# 2. CREAR NUEVOS ESTUDIANTES
# =====================================================
Write-Host "`n2. CREANDO NUEVOS ESTUDIANTES..." -ForegroundColor Yellow

# Estudiante 2: María González
Write-Host "`nCreando estudiante: María Fernanda González..." -ForegroundColor Cyan
$estudiante2 = @{
    cod_programa = 1
    tipo_documento = "CC"
    numero_documento = "9876543210"
    primer_nombre = "María"
    segundo_nombre = "Fernanda"
    primer_apellido = "González"
    segundo_apellido = "Ramírez"
    fecha_nacimiento = "2003-08-15"
    genero = "F"
    correo_institucional = "maria.gonzalez@universidad.edu"
    correo_personal = "mariafgr@gmail.com"
    telefono = "3112345678"
    direccion = "Calle 50 #30-20"
    fecha_ingreso = "2025-01-15"
} | ConvertTo-Json

try {
    $response2 = Invoke-RestMethod -Uri "$baseUrl/estudiantes/" `
        -Method POST `
        -Body $estudiante2 `
        -ContentType "application/json"
    Show-Response $response2 "Estudiante María Creada"
} catch {
    Show-Error $_ "Crear Estudiante María"
}

Start-Sleep -Seconds 2

# Estudiante 3: Carlos Rodríguez
Write-Host "`nCreando estudiante: Carlos Andrés Rodríguez..." -ForegroundColor Cyan
$estudiante3 = @{
    cod_programa = 1
    tipo_documento = "CC"
    numero_documento = "5555666677"
    primer_nombre = "Carlos"
    segundo_nombre = "Andrés"
    primer_apellido = "Rodríguez"
    segundo_apellido = "Martínez"
    fecha_nacimiento = "2002-03-10"
    genero = "M"
    correo_institucional = "carlos.rodriguez@universidad.edu"
    correo_personal = "carlosar@gmail.com"
    telefono = "3123456789"
    direccion = "Avenida 80 #45-12"
    fecha_ingreso = "2025-01-15"
} | ConvertTo-Json

try {
    $response3 = Invoke-RestMethod -Uri "$baseUrl/estudiantes/" `
        -Method POST `
        -Body $estudiante3 `
        -ContentType "application/json"
    Show-Response $response3 "Estudiante Carlos Creado"
} catch {
    Show-Error $_ "Crear Estudiante Carlos"
}

Read-Host "`nPresiona Enter para verificar todos los estudiantes..."

# =====================================================
# 3. VERIFICAR TODOS LOS ESTUDIANTES
# =====================================================
Write-Host "`n3. VERIFICANDO TODOS LOS ESTUDIANTES..." -ForegroundColor Yellow
try {
    $todosEstudiantes = Invoke-RestMethod -Uri "$baseUrl/estudiantes/" -Method GET
    Show-Response $todosEstudiantes "Lista Completa de Estudiantes"
    Write-Host "Total de estudiantes: $($todosEstudiantes.count)" -ForegroundColor Cyan
} catch {
    Show-Error $_ "Verificar Todos Estudiantes"
}

Read-Host "`nPresiona Enter para agregar asignaturas a la matrícula de Juan..."

# =====================================================
# 4. AGREGAR ASIGNATURAS A MATRÍCULA DE JUAN (cod_matricula=1)
# =====================================================
Write-Host "`n4. AGREGANDO ASIGNATURAS A MATRÍCULA DE JUAN..." -ForegroundColor Yellow

# Nota: Los cod_grupo son los generados en fase1_datos_maestros.sql
# Verificado: cod_grupo 7=IS101, 8=IS102, 9=IS103, 10=IS104

$grupos = @(7, 8, 9, 10)  # IS101, IS102, IS103, IS104
$nombreAsignaturas = @("IS101 - Introducción a la Programación", 
                       "IS102 - Cálculo Diferencial",
                       "IS103 - Álgebra Lineal",
                       "IS104 - Fundamentos de Ingeniería")

for ($i = 0; $i -lt $grupos.Length; $i++) {
    $grupo = $grupos[$i]
    $nombreAsig = $nombreAsignaturas[$i]
    
    Write-Host "`nAgregando $nombreAsig (Grupo $grupo)..." -ForegroundColor Cyan
    
    $asignatura = @{
        cod_grupo = $grupo
    } | ConvertTo-Json
    
    try {
        $responseAsig = Invoke-RestMethod -Uri "$baseUrl/matriculas/1/asignaturas" `
            -Method POST `
            -Body $asignatura `
            -ContentType "application/json"
        Show-Response $responseAsig "Asignatura Agregada"
    } catch {
        Show-Error $_ "Agregar Asignatura $nombreAsig"
    }
    
    Start-Sleep -Seconds 1
}

Read-Host "`nPresiona Enter para consultar detalle de matrícula de Juan..."

# =====================================================
# 5. CONSULTAR DETALLE DE MATRÍCULA
# =====================================================
Write-Host "`n5. CONSULTANDO DETALLE DE MATRÍCULA DE JUAN..." -ForegroundColor Yellow
try {
    $detalleMatricula = Invoke-RestMethod -Uri "$baseUrl/matriculas/1" -Method GET
    Show-Response $detalleMatricula "Detalle Matrícula Juan"
} catch {
    Show-Error $_ "Consultar Detalle Matrícula"
}

Read-Host "`nPresiona Enter para crear matrículas para María y Carlos..."

# =====================================================
# 6. CREAR MATRÍCULAS PARA NUEVOS ESTUDIANTES
# =====================================================
Write-Host "`n6. CREANDO MATRÍCULAS PARA NUEVOS ESTUDIANTES..." -ForegroundColor Yellow

# Matrícula para María
Write-Host "`nCreando matrícula para María (202500002)..." -ForegroundColor Cyan
$matriculaMaria = @{
    cod_estudiante = "202500002"
    cod_periodo = "2025-1"
} | ConvertTo-Json

try {
    $responseMaria = Invoke-RestMethod -Uri "$baseUrl/matriculas/" `
        -Method POST `
        -Body $matriculaMaria `
        -ContentType "application/json"
    Show-Response $responseMaria "Matrícula María Creada"
} catch {
    Show-Error $_ "Crear Matrícula María"
}

Start-Sleep -Seconds 2

# Matrícula para Carlos
Write-Host "`nCreando matrícula para Carlos (202500003)..." -ForegroundColor Cyan
$matriculaCarlos = @{
    cod_estudiante = "202500003"
    cod_periodo = "2025-1"
} | ConvertTo-Json

try {
    $responseCarlos = Invoke-RestMethod -Uri "$baseUrl/matriculas/" `
        -Method POST `
        -Body $matriculaCarlos `
        -ContentType "application/json"
    Show-Response $responseCarlos "Matrícula Carlos Creada"
} catch {
    Show-Error $_ "Crear Matrícula Carlos"
}

Read-Host "`nPresiona Enter para registrar calificaciones de prueba..."

# =====================================================
# 7. REGISTRAR CALIFICACIONES (Requiere cod_detalle_matricula)
# =====================================================
Write-Host "`n7. REGISTRANDO CALIFICACIONES DE PRUEBA..." -ForegroundColor Yellow

# Nota: Los cod_detalle_matricula se generan al agregar asignaturas
# Verifica con: SELECT cod_detalle_matricula, cod_matricula FROM DETALLE_MATRICULA;

# Parcial 1 para Juan en IS101 (asumiendo cod_detalle_matricula = 1)
Write-Host "`nRegistrando Parcial 1 - IS101 para Juan..." -ForegroundColor Cyan
$calificacion1 = @{
    cod_detalle_matricula = 1
    cod_tipo_actividad = 1  # Parcial
    numero_actividad = 1
    nota = 4.5
    porcentaje_aplicado = 30
    observaciones = "Excelente desempeño en el primer parcial"
} | ConvertTo-Json

try {
    $responseCalif1 = Invoke-RestMethod -Uri "$baseUrl/calificaciones/" `
        -Method POST `
        -Body $calificacion1 `
        -ContentType "application/json"
    Show-Response $responseCalif1 "Calificación Parcial Registrada"
} catch {
    Show-Error $_ "Registrar Calificación Parcial"
}

Start-Sleep -Seconds 1

# Quiz 1 para Juan en IS101
Write-Host "`nRegistrando Quiz 1 - IS101 para Juan..." -ForegroundColor Cyan
$calificacion2 = @{
    cod_detalle_matricula = 1
    cod_tipo_actividad = 2  # Quiz
    numero_actividad = 1
    nota = 4.0
    porcentaje_aplicado = 10
    observaciones = "Buen manejo de conceptos básicos"
} | ConvertTo-Json

try {
    $responseCalif2 = Invoke-RestMethod -Uri "$baseUrl/calificaciones/" `
        -Method POST `
        -Body $calificacion2 `
        -ContentType "application/json"
    Show-Response $responseCalif2 "Calificación Quiz Registrada"
} catch {
    Show-Error $_ "Registrar Calificación Quiz"
}

Start-Sleep -Seconds 1

# Taller 1 para Juan en IS101
Write-Host "`nRegistrando Taller 1 - IS101 para Juan..." -ForegroundColor Cyan
$calificacion3 = @{
    cod_detalle_matricula = 1
    cod_tipo_actividad = 3  # Taller
    numero_actividad = 1
    nota = 4.8
    porcentaje_aplicado = 20
    observaciones = "Excelente trabajo práctico"
} | ConvertTo-Json

try {
    $responseCalif3 = Invoke-RestMethod -Uri "$baseUrl/calificaciones/" `
        -Method POST `
        -Body $calificacion3 `
        -ContentType "application/json"
    Show-Response $responseCalif3 "Calificación Taller Registrada"
} catch {
    Show-Error $_ "Registrar Calificación Taller"
}

Read-Host "`nPresiona Enter para consultar calificaciones del estudiante..."

# =====================================================
# 8. CONSULTAR CALIFICACIONES POR ESTUDIANTE
# =====================================================
Write-Host "`n8. CONSULTANDO CALIFICACIONES DE JUAN..." -ForegroundColor Yellow
try {
    $calificacionesJuan = Invoke-RestMethod -Uri "$baseUrl/calificaciones/estudiante/202500001" -Method GET
    Show-Response $calificacionesJuan "Calificaciones de Juan"
} catch {
    Show-Error $_ "Consultar Calificaciones"
}

Read-Host "`nPresiona Enter para consultar historial académico..."

# =====================================================
# 9. CONSULTAR HISTORIAL ACADÉMICO
# =====================================================
Write-Host "`n9. CONSULTANDO HISTORIAL ACADÉMICO DE JUAN..." -ForegroundColor Yellow
try {
    $historialJuan = Invoke-RestMethod -Uri "$baseUrl/calificaciones/historial/202500001" -Method GET
    Show-Response $historialJuan "Historial Académico de Juan"
} catch {
    Show-Error $_ "Consultar Historial"
}

Read-Host "`nPresiona Enter para consultar matrículas por periodo..."

# =====================================================
# 10. CONSULTAR MATRÍCULAS POR PERIODO
# =====================================================
Write-Host "`n10. CONSULTANDO MATRÍCULAS DEL PERIODO 2025-1..." -ForegroundColor Yellow
try {
    $matriculasPeriodo = Invoke-RestMethod -Uri "$baseUrl/matriculas/periodo/2025-1" -Method GET
    Show-Response $matriculasPeriodo "Matrículas Periodo 2025-1"
} catch {
    Show-Error $_ "Consultar Matrículas por Periodo"
}

# =====================================================
# RESUMEN FINAL
# =====================================================
Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "PRUEBAS DE ENDPOINTS COMPLETADAS" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Acciones realizadas:" -ForegroundColor Cyan
Write-Host "- Creados 2 estudiantes nuevos (María y Carlos)" -ForegroundColor White
Write-Host "- Agregadas 4 asignaturas a matrícula de Juan" -ForegroundColor White
Write-Host "- Creadas matrículas para María y Carlos" -ForegroundColor White
Write-Host "- Registradas 3 calificaciones para Juan" -ForegroundColor White
Write-Host "- Consultados detalles de matrículas y calificaciones" -ForegroundColor White
Write-Host ""
Write-Host "Ejecuta consultas_tablas.sql para verificar todos los datos" -ForegroundColor Yellow
Write-Host ""
