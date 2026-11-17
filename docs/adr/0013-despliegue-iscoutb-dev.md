---
number: 0013
date: 2026-11-16
title: "Despliegue del backend en el servidor de la materia (iscoutb.dev)"
status: Proposed
deciders: ["Diego Rosales Garza", "Rodrigo Vazquez Rico", "Angel Fabian Gutierrez Gomez"]
technical-story: "La evidencia S8, el Corte 2 y el proyecto final exigen una URL pública con HTTPS alcanzable fuera de la universidad, infraestructura como código versionada, secretos fuera del repositorio, health check, logs y una métrica consultable. El despliegue del backend de El Mapita UTB en el servidor de la materia es un requerimiento académico; la dirección asignada al equipo es https://elmapita.iscoutb.dev."
---

# ADR-0013: Despliegue del backend en iscoutb.dev

## Contexto

El backend NestJS de El Mapita UTB debe estar disponible públicamente con HTTPS para cumplir los requisitos de la evidencia S8, el Corte 2 y el proyecto final. El servidor de la materia `iscoutb.dev` es el entorno designado para este despliegue.

Según la documentación del servidor:

- Las apps móviles (Flutter, Kotlin) **no se despliegan allí**; el frontend móvil apunta a la URL pública de la API.
- El backend debe describirse con **Docker Compose** en `deploy/compose.lab.yaml`.
- Cuota por equipo: **4 contenedores y 512 MB de memoria en total**, 0,5 CPU por contenedor.
- Los servicios externos (Supabase) están permitidos: El Mapita usa Supabase como base de datos externa, por lo que el compose no necesita servicio `db` local.

## Decisión

1. Desplegar únicamente el **backend NestJS** en el servidor `iscoutb.dev`.
2. Crear `deploy/compose.lab.yaml` con el servicio `api`, construido desde `../backend` (relativo a la carpeta `deploy/`).
3. Usar Supabase como base de datos externa (no hay servicio `db` ni volúmenes con nombre locales).
4. Configurar en el panel el servicio `sistema` en entorno `production`, rama `main`, Compose Path `./deploy/compose.lab.yaml`, con Isolated Deployment activado.
5. Agregar el dominio `elmapita.iscoutb.dev` apuntando al servicio `api`, puerto `3000`, Internal Path vacío, Strip Path no, HTTPS con Let's Encrypt.
6. Almacenar secretos únicamente en el panel del servidor, nunca en el repositorio.

## Consecuencias

### Positivas

| Área | Impacto |
|---|---|
| URL pública con HTTPS | `https://elmapita.iscoutb.dev` accesible desde fuera de la universidad. |
| Infraestructura como código versionada | `deploy/compose.lab.yaml` y `backend/Dockerfile` versionados en la rama `main`. |
| Secretos fuera del código | `${VARIABLE}` en el compose; valores reales solo en el panel. |
| Health check honesto | `GET /health` responde 200 solo si Supabase está disponible; 503 si no. |
| Métrica consultable | `GET /metrics` expone Prometheus en la raíz del contenedor. |

### Negativas / Trade-offs

| Compromiso | Mitigación |
|---|---|
| Solo se despliega el backend | El frontend Flutter no se despliega en este servidor; apunta a la URL pública de la API. |
| Dependencia de Supabase externo | Si Supabase no es alcanzable desde la red del servidor, `/health` devuelve 503 (comportamiento correcto). |

## Referencias

- [`deploy/compose.lab.yaml`](../../deploy/compose.lab.yaml)
- [`deploy/.env.example`](../../deploy/.env.example)
- [`backend/Dockerfile`](../../backend/Dockerfile)
- Documentación del servidor: `Dockploymd.md`
