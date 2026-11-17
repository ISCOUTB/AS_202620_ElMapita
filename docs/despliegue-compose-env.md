# Documentación de despliegue por Compose (iscoutb.dev)

## `deploy/compose.lab.yaml`

Archivo de infraestructura como código que describe el entorno de despliegue en el servidor de la materia. Sigue estas reglas obligatorias:

| Regla | Descripción |
|---|---|
| Sin `ports:` | Se usa `expose:` en su lugar. |
| Sin `container_name` | El servidor asigna los nombres automáticamente. |
| Sin bind mounts | Los datos van en volúmenes con nombre si fuera necesario. |
| Sin `privileged` | Ningún servicio se ejecuta con privilegios elevados. |
| Sin `/var/run/docker.sock` | No se monta el socket de Docker. |
| Sin redes externas | El servidor crea la red del equipo automáticamente. |
| Secretos como `${VARIABLE}` | Los valores reales se configuran en el panel, nunca en el repositorio. |
| Límites de recursos | Cada servicio define `deploy.resources.limits`. Suma del equipo ≤ 512 MB; 0.5 CPU por contenedor. |

### Contenido del archivo

Define un único servicio:

- **`api`**: imagen construida desde `../backend`, expone el puerto `3000`, conecta a Supabase mediante variables de entorno, incluye un `healthcheck` que consulta `http://localhost:3000/health` y límites de 0.5 CPU y 256 MB de memoria.

No incluye servicio `db` ni volúmenes con nombre porque El Mapita utiliza **Supabase** como base de datos externa.

## `deploy/.env.example`

Plantilla de variables de entorno para pruebas locales. Contiene únicamente valores de ejemplo o placeholders. **Nunca debe contener credenciales reales.**

Ejemplo:

```env
PORT=3000
NODE_ENV=production
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_SERVICE_ROLE_KEY=tu-service-role-key-de-ejemplo
SUPABASE_ANON_KEY=tu-anon-key-de-ejemplo
FRONTEND_URL=https://elmapita.iscoutb.dev
LOG_LEVEL=info
```

Para usarlo localmente:

```bash
cp deploy/.env.example deploy/.env
# Editar deploy/.env con los valores reales de prueba
docker compose --env-file deploy/.env -f deploy/compose.lab.yaml up --build
```

## `deploy/.env` (local, ignorado por git)

Este archivo se crea a partir de `.env.example` solo en el computador local para pruebas. Está listado en `.gitignore` y **nunca se sube al repositorio**. En el servidor, los valores de entorno se escriben directamente en la pestaña correspondiente del panel.
