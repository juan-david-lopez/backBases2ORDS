# Documentación de Endpoints ORDS para el Frontend

A continuación se describe cada endpoint disponible, qué recibe, qué devuelve (código HTTP, headers y body) y qué acción realiza. Útil para desarrolladores frontend.

---

## Convención de Autenticación
- Los endpoints protegidos esperan el header `Authorization: Bearer <token>`.
- El endpoint de login devuelve el token dentro del body JSON bajo la propiedad `token`. El cliente puede opcionalmente establecerlo en un header `Authorization` para llamadas subsecuentes.
- Respuestas de error devuelven JSON con al menos `{ "success": false, "message": "..." }` y códigos HTTP apropiados (401, 404, 400, 500).

---

## 1. Autenticación

### POST /auth/login
- URL: `/ords/auth/login` (módulo `auth`, POST)
- Headers: `Content-Type: application/json`
- Body (JSON):
  ```json
  {
    "email": "usuario@universidad.edu",
    "password": "clave"
  }
  ```
- Respuestas:
  - 200 OK (éxito):
    - Headers: `Content-Type: application/json`
    - Body:
      ```json
      {
        "success": true,
        "message": "Autenticación exitosa",
        "token": "Bearer_<valor>",
        "role": "ESTUDIANTE|DOCENTE|ADMINISTRADOR|REGISTRO",
        "usuario": {
          "cod_usuario": 123,
          "username": "usuario@universidad.edu",
          "tipo_usuario": "ESTUDIANTE",
          "cod_referencia": "202500001",
          "nombre_completo": "Juan Perez"
        }
      }
      ```
  - 401 Unauthorized (credenciales inválidas) — Body con `success:false` y `message` explicando el error.
- Acción: verifica credenciales y devuelve token + datos del usuario. El frontend debe guardar `token` y enviarlo en `Authorization` para endpoints protegidos.

  **Ejemplo real (respuesta raw observada desde Postman/Kong):**

  Headers (respuesta):
  - `Content-Type: application/json`
  - `Transfer-Encoding: chunked`

  Body (JSON):
  ```json
  {"success": true, "message": "Autenticación exitosa", "token": "Bearer_281_20251120230817", "role": "ESTUDIANTE", "usuario": {"cod_usuario":281, "username":"est1@correo.com", "tipo_usuario":"ESTUDIANTE", "cod_referencia":"202500001", "nombre_completo":"Nombre1 Apellido1"}}
  ```

  - Status HTTP observado: `200 OK`
  - Nota: el token se devuelve en el body bajo la propiedad `token`. Para llamadas protegidas, el frontend debe enviar:

    Header: `Authorization: Bearer_281_20251120230817`

    (o más genérico: `Authorization: Bearer <token>`)

  - Consejo: guardar `token` en memoria segura (no en localStorage sin protección) y añadirlo a cada request protegida en el header `Authorization`.

---

## 2. Estudiantes

### GET /estudiantes/
- URL: `/ords/estudiantes/` (GET)
- Headers: `Authorization: Bearer <token>` (si el endpoint está protegido)
- Devuelve 200 OK con body `[{...}, {...}]` (array de estudiantes).

### GET /estudiantes/:codigo
- URL params: `:codigo` = `cod_estudiante`
- Headers: `Authorization: Bearer <token>`
- Devuelve 200 OK con objeto JSON del estudiante, o 404 si no existe.

### POST /estudiantes/
- Body JSON (ejemplo):
  ```json
  {
    "cod_programa": 1,
    "tipo_documento": "CC",
    "num_documento": "12345678",
    "primer_nombre": "Juan",
    "segundo_nombre": "David",
    "primer_apellido": "Lopez",
    "segundo_apellido": "Perez",
    "correo_institucional": "juan.lopez@universidad.edu",
    "correo_personal": "juan@gmail.com",
    "telefono": "3001234567",
    "direccion": "Calle 123",
    "fecha_nacimiento": "2000-01-01",
    "genero": "M",
    "fecha_ingreso": "2021-01-15"
  }
  ```
- Respuestas:
  - 201 Created / 200 OK: `{ "success": true, "message": "Estudiante creado exitosamente", "cod_estudiante": "..." }`
  - 400 Bad Request: JSON con `success:false` y detalle del error.

### PUT /estudiantes/:codigo
- Body JSON con campos a actualizar. Devuelve 200 OK con `{ "success": true, "message": "Estudiante actualizado exitosamente" }`.

### GET /estudiantes/:codigo/matriculas
- Devuelve 200 OK con array de matrículas del estudiante.

---

## 3. Matrículas

### POST /matriculas/
- Body ejemplo:
  ```json
  {
    "cod_estudiante": "202500002",
    "cod_periodo": "2025-1"
  }
  ```
- Respuestas:
  - 201 Created: `{ "success": true, "message": "Matrícula creada exitosamente", "cod_matricula": 123 }`
  - 400 / 409: en caso de conflicto o ventana de matrícula no activa.

### POST /matriculas/:cod_matricula/asignaturas
- Body: `{ "cod_grupo": 101 }` — agrega un `DETALLE_MATRICULA`.
- Respuesta: 200 OK `{ "success": true, "message": "Asignatura agregada exitosamente" }`.

### GET /matriculas/:cod_matricula
- Devuelve detalle completo (matrícula + lista de asignaturas inscritas).

### PUT /matriculas/:cod_matricula/estado
- Body: `{ "nuevo_estado": "ACTIVO" }` — cambia estado de la matrícula.

### GET /matriculas/periodo/:cod_periodo
- Devuelve todas las matrículas para el periodo.

---

## 4. Registro de Materias

### GET /registro-materias/disponibles/:cod_estudiante
- Devuelve 200 OK con array de asignaturas que el estudiante puede inscribir.

### GET /registro-materias/grupos/:cod_asignatura
- Devuelve 200 OK con array de grupos disponibles para esa asignatura (incluye `cupo_disponible`).

### POST /registro-materias/inscribir
- Body ejemplo:
  ```json
  {
    "cod_estudiante": "202500002",
    "cod_grupo": 101
  }
  ```
- Respuesta: 200 OK `{ "success": true, "message": "Inscripción exitosa", "cod_matricula": ... }`.

### DELETE /registro-materias/retirar/:cod_detalle_matricula
- Body: `{ "motivo": "RETIRO VOLUNTARIO" }` — Respuesta 200 OK `{ "success": true, "message": "Retiro exitoso" }`.

### GET /registro-materias/mi-horario/:cod_estudiante
- Devuelve horario vigente del estudiante.

### GET /registro-materias/resumen/:cod_estudiante
- Devuelve resumen académico (créditos, riesgo, promedio).

---

## 5. Calificaciones

### POST /calificaciones/
- Body ejemplo:
  ```json
  {
    "cod_detalle": 123,
    "cod_actividad": 1,
    "nota": 4.5,
    "observaciones": "Buen trabajo"
  }
  ```
- Respuesta: 200 OK `{ "success": true, "message": "Calificación registrada" }`.

### GET /calificaciones/estudiante/:cod_estudiante
- Devuelve listado de calificaciones del estudiante.

### GET /calificaciones/grupo/:cod_grupo
- Devuelve listado de calificaciones por grupo.

### PUT /calificaciones/:cod_calificacion
- Body: `{ "nota": 4.0, "observaciones": "Actualización" }` — Respuesta 200 OK con mensaje de éxito; la nota definitiva puede recalcularse automáticamente.

### GET /calificaciones/historial/:cod_estudiante
- Devuelve resumen académico (promedios, asignaturas aprobadas/reprobadas, créditos).

---

## Notas adicionales para Frontend
- Siempre comprobar `status` HTTP además del body JSON para manejo de errores.
- El token devuelto en `/auth/login` es el que debe enviarse en `Authorization` para endpoints protegidos.
- Para endpoints que crean recursos, revisar código 201 vs 200; el body normalmente incluye `success` y `message`.
- Si quieres, puedo generar una tabla con todos los endpoints, métodos, parámetros y ejemplos de request/response en formato más consumible (JSON o CSV) para integrarlo en la documentación del frontend.
