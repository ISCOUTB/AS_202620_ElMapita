---
number: 0015
date: 2026-11-22
title: "Reemplazo de ADR-0012: despliegue del backend en Dokploy (iscoutb.dev) en lugar de Render"
status: Accepted
supersedes: "ADR-0012"
deciders: ["Diego Rosales Garza", "Rodrigo Vazquez Rico", "Angel Fabian Gutierrez Gomez"]
technical-story: "El commit ddcfbbc (2026-10-28) añadió deploy/compose.lab.yaml y el backend pasó a desplegarse en Dokploy. La documentación siguió describiendo Render (RSK-17) y las mediciones de EC-01 apuntaban a un servicio que ya no es el vigente (RSK-10)."
---

# ADR-0015: Reemplazo de ADR-0012 — despliegue en Dokploy

## Contexto

> Relacionado: [ADR-0013](0013-despliegue-iscoutb-dev.md) (propuesta de Diego, 2026-11-16) describe el despliegue en el servidor de la materia; este ADR registra el reemplazo de Render y la evidencia que lo respalda.

[ADR-0004](0004-despliegue-render-docker.md) eligió Render con contenedor Docker, y [ADR-0012](0012-reemplazo-adr-0004-despliegue-render-docker.md) corrigió sus causas de fondo (Node 22, imagen `slim`, health check con timeout, `gitleaks` por CLI). Desde el 2026-10-28 el repositorio despliega el mismo contenedor con Docker Compose en un panel Dokploy del servidor de laboratorio (`iscoutb.dev`, `deploy/compose.lab.yaml`).

Dos problemas se acumularon por no registrar el cambio:

- La documentación vigente (arc42 DEC-08 y RSK-05, aspectos, glosario, seguridad) describía Render (RSK-17).
- Las mediciones de EC-01 del 2026-10-04, 2026-11-09 y 2026-11-22 se hicieron contra Render, no contra el despliegue vigente. En las tres, los endpoints de detalle respondieron HTTP 500 (RSK-10).

## Alternativas

| Opción | Consecuencia |
|---|---|
| A. Seguir en Render | Free tier con arranque en frío medido en 18,8 s (2026-11-22, `docs/evidencia/final-mediciones-2026-11-22.md`) y 500 persistente en los endpoints de detalle. |
| B. Dokploy en el servidor de laboratorio (decisión) | Contenedor siempre activo (`restart: unless-stopped`), sin arranque en frío por inactividad; límites del servidor: 256 MB y 0,5 CPU por servicio, sin `ports`, sin `container_name`, secretos solo en el panel. |

La motivación original del cambio no quedó escrita en el repositorio; el único registro es el mensaje del commit `ddcfbbc`. El equipo debe confirmarla aquí. **Pendiente de confirmar por el equipo.**

## Decisión

El backend se despliega con `deploy/compose.lab.yaml` en Dokploy. Se retira `render.yaml`. Siguen vigentes del ADR-0012 la base `node:22-slim`, el health check con tope de 4 s y `gitleaks` por CLI, porque son propiedades del contenedor y no de la plataforma. Siguen vigentes del ADR-0004 el contenedor Docker, `GET /health`, los logs estructurados y la métrica `/metrics`.

## Consecuencias

- **RSK-05** (arranque en frío de Render) deja de aplicar al despliegue vigente; se conserva como histórico.
- **Presupuesto:** 256 MB y 0,5 CPU por contenedor. Es una restricción nueva frente a Render (T-06 en `docs/seguridad/amenazas.md`).
- **Una sola instancia:** la caché y el bus en memoria siguen siendo válidos, igual que con Render.
- **EC-01 sin medir en el despliegue vigente** hasta ejecutar `backend/scripts/bench-ec01.mjs <url-de-la-API-en-Dokploy>`. La URL pública se configura en el panel y no está en el repositorio. Si responde 500, se diagnostica con los logs del contenedor.
- **Evidencia histórica:** las mediciones en Render (`s9-ec01-benchmark.json`, `atam-ec01-benchmark-2026-11-09.json`, `final-ec01-benchmark-2026-11-22.json`) se conservan como línea base del servicio anterior.
- Los ADR-0004 y ADR-0012 no se editan, salvo el `status` del ADR-0012, que pasa a `Superseded by ADR-0015`.
