# Documentación de Endpoints ORDS para el Frontend

A continuación se describe cada endpoint disponible, qué recibe, qué devuelve y qué acción realiza. Útil para desarrolladores frontend.

---

## 1. Autenticación

### POST /auth/login
- **Recibe:**
  ```json
  {
    "email": "usuario@universidad.edu",
    "password": "clave"
  }
  ```
- **Devuelve:**
  - Éxito:
    ```json
    {
      "success": true,
      "message": "Autenticación exitosa",
      "token": "Bearer_...",
      "role": "ESTUDIANTE|DOCENTE|ADMIN",
      "usuario": {
        "cod_usuario": ..., 
        "username": "usuario@universidad.edu",
        "tipo_usuario": "...",
        "cod_referencia": "...",
        "nombre_completo": "..."
      }
    }
    ```
  - Error:
    ```json
    {
      "success": false,
      "message": "Usuario o contraseña incorrectos",
      "role": null
    }
    ```
- **Acción:** Verifica credenciales y devuelve token y datos del usuario.

---

## 2. Estudiantes

### GET /estudiantes/
- **Recibe:** Nada
- **Devuelve:** Listado de estudiantes (JSON array)
- **Acción:** Lista todos los estudiantes registrados.

### GET /estudiantes/:codigo
- **Recibe:** Nada
- **Devuelve:** Datos completos de un estudiante
- **Acción:** Obtiene los datos de un estudiante por código.

### POST /estudiantes/
- **Recibe:**
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
- **Devuelve:**
  ```json
  {
    "success": true,
    "message": "Estudiante creado exitosamente",
    "cod_estudiante": "..."
  }
  ```
- **Acción:** Crea un nuevo estudiante.

### PUT /estudiantes/:codigo
- **Recibe:**
  ```json
  {
    "correo_institucional": "nuevo@universidad.edu",
    "correo_personal": "nuevo@gmail.com",
    "telefono": "3007654321",
    "direccion": "Calle 456",
    "estado_estudiante": "ACTIVO"
  }
  ```
- **Devuelve:**
  ```json
  {
    "success": true,
    "message": "Estudiante actualizado exitosamente"
  }
  ```
- **Acción:** Actualiza los datos de un estudiante.

### GET /estudiantes/:codigo/matriculas
- **Recibe:** Nada
- **Devuelve:** Listado de matrículas del estudiante
- **Acción:** Lista todas las matrículas de un estudiante.

---

## 3. Matrículas

### POST /matriculas/
- **Recibe:**
  ```json
  {
    "cod_estudiante": "202500002",
    "cod_periodo": "2025A"
  }
  ```
- **Devuelve:**
  ```json
  {
    "success": true,
    "message": "Matrícula creada exitosamente",
    "cod_matricula": "..."
  }
  ```
- **Acción:** Crea una matrícula para un estudiante en un periodo.

### POST /matriculas/:cod_matricula/asignaturas
- **Recibe:**
  ```json
  {
    "cod_grupo": 101
  }
  ```
- **Devuelve:**
  ```json
  {
    "success": true,
    "message": "Asignatura agregada exitosamente"
  }
  ```
- **Acción:** Agrega una asignatura (grupo) a la matrícula.

### GET /matriculas/:cod_matricula
- **Recibe:** Nada
- **Devuelve:** Detalle completo de la matrícula (incluye asignaturas)
- **Acción:** Obtiene los datos de una matrícula específica.

### PUT /matriculas/:cod_matricula/estado
- **Recibe:**
  ```json
  {
    "nuevo_estado": "ACTIVO"
  }
  ```
- **Devuelve:**
  ```json
  {
    "success": true,
    "message": "Estado actualizado exitosamente"
  }
  ```
- **Acción:** Cambia el estado de una matrícula.

### GET /matriculas/periodo/:cod_periodo
- **Recibe:** Nada
- **Devuelve:** Listado de matrículas del periodo
- **Acción:** Lista todas las matrículas de un periodo académico.

---

## 4. Registro de Materias

### GET /registro-materias/disponibles/:cod_estudiante
- **Recibe:** Nada
- **Devuelve:** Listado de asignaturas disponibles para inscribir
- **Acción:** Muestra las materias que el estudiante puede inscribir.

### GET /registro-materias/grupos/:cod_asignatura
- **Recibe:** Nada
- **Devuelve:** Listado de grupos disponibles para una asignatura
- **Acción:** Muestra los grupos activos y cupos disponibles de una asignatura.

### POST /registro-materias/inscribir
- **Recibe:**
  ```json
  {
    "cod_estudiante": "202500002",
    "cod_grupo": 101
  }
  ```
- **Devuelve:**
  ```json
  {
    "success": true,
    "message": "Inscripción exitosa",
    "cod_matricula": "..."
  }
  ```
- **Acción:** Inscribe al estudiante en el grupo indicado.

### DELETE /registro-materias/retirar/:cod_detalle_matricula
- **Recibe:**
  ```json
  {
    "motivo": "RETIRO VOLUNTARIO"
  }
  ```
- **Devuelve:**
  ```json
  {
    "success": true,
    "message": "Retiro exitoso"
  }
  ```
- **Acción:** Retira al estudiante de la asignatura indicada.

### GET /registro-materias/mi-horario/:cod_estudiante
- **Recibe:** Nada
- **Devuelve:** Horario actual del estudiante
- **Acción:** Muestra el horario de clases inscritas.

### GET /registro-materias/resumen/:cod_estudiante
- **Recibe:** Nada
- **Devuelve:** Resumen de matrícula (créditos, riesgo, promedio)
- **Acción:** Muestra el resumen académico del estudiante.

---

## 5. Calificaciones

### POST /calificaciones/
- **Recibe:**
  ```json
  {
    "cod_detalle": 123,
    "cod_actividad": 1,
    "nota": 4.5,
    "observaciones": "Buen trabajo"
  }
  ```
- **Devuelve:**
  ```json
  {
    "success": true,
    "message": "Calificación registrada"
  }
  ```
- **Acción:** Registra una calificación para una actividad.

### GET /calificaciones/estudiante/:cod_estudiante
- **Recibe:** Nada
- **Devuelve:** Listado de notas del estudiante
- **Acción:** Muestra todas las calificaciones del estudiante.

### GET /calificaciones/grupo/:cod_grupo
- **Recibe:** Nada
- **Devuelve:** Listado de notas por grupo
- **Acción:** Muestra las calificaciones de todos los estudiantes de un grupo.

### PUT /calificaciones/:cod_calificacion
- **Recibe:**
  ```json
  {
    "nota": 4.0,
    "observaciones": "Actualización"
  }
  ```
- **Devuelve:**
  ```json
  {
    "success": true,
    "message": "Calificación actualizada y nota definitiva recalculada"
  }
  ```
- **Acción:** Actualiza una calificación y recalcula la nota definitiva.

### GET /calificaciones/historial/:cod_estudiante
- **Recibe:** Nada
- **Devuelve:** Resumen académico del estudiante (promedio, aprobadas, reprobadas, créditos)
- **Acción:** Muestra el historial académico completo del estudiante.

---

## Notas
- Todos los endpoints devuelven errores en formato JSON si ocurre algún problema.
- Los endpoints GET no requieren body, solo parámetros en la URL.
- Los endpoints POST/PUT/DELETE requieren body en formato JSON.
- El token devuelto en login puede usarse para autenticación si el backend lo requiere.
