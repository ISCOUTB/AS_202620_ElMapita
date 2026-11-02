---
number: 0012
date: 2026-11-02
title: "Reemplazo de ADR-0004: runtime Node 22 con base slim, health check con timeout y gitleaks por CLI"
status: Accepted
supersedes: "ADR-0004"
deciders: ["Diego Rosales Garza", "Rodrigo Vazquez Rico", "Angel Fabian Gutierrez Gomez"]
technical-story: "ADR-0004 fue editado después de ser aceptado (commits 4532ed6 y b35f784) para registrar tres causas de fondo del deploy real. Se restaura su texto original y este ADR recoge formalmente esos cambios."
---

# ADR-0012: Reemplazo de ADR-0004

## Contexto

El ADR-0004 (aceptado el 2026-09-27, commit `30499d5`) decidía desplegar el backend en Render desde un contenedor Docker, con `render.yaml` como infraestructura como código y señales mínimas de operación. Al desplegar de verdad aparecieron causas que no se veían en local, y los commits `4532ed6` y `b35f784` reescribieron el ADR para reflejarlas. Eso contradice la regla de no reescritura: la decisión original quedó sustituida sin dejar rastro de qué se aceptó primero.

## Decisión

La estrategia de despliegue (Render, contenedor Docker, `render.yaml` versionado, `GET /health`, logs estructurados y métrica de latencia) **se mantiene tal cual en [ADR-0004](0004-despliegue-render-docker.md)**. Este ADR registra lo que cambió desde entonces y sustituye los puntos afectados:

1. **Base de imagen `node:22-slim` (reemplaza `node:20-alpine`).** El despliegue real pasó por tres causas, descubiertas una tras otra:
   1. Esquema de Supabase vacío: el health check honesto devolvió 503, que era lo correcto.
   2. Alpine usa `musl`, con un bug conocido de resolución DNS que cuelga peticiones salientes en ciertas redes de nube. Se pasó a `node:20-slim` (Debian, `glibc`): mejora real, pero no definitiva.
   3. Causa raíz definitiva: `@supabase/supabase-js` exige Node ≥ 22 en tiempo de ejecución (sin WebSocket nativo en Node 20 lanza `Node.js detected but native WebSocket not found` en cada consulta). El proyecto pasó a Node 22 en CI y Docker.
2. **Health check con timeout explícito.** La consulta a Supabase corre contra un tope de 4 s (`Promise.race`, con `clearTimeout` en el `finally`): el endpoint responde siempre rápido, aunque sea con 503. Se añadió logging de tiempos por paso, independiente del autologging de pino-http (que excluye `/health` a propósito). Implementación: `backend/src/health.controller.ts`.
3. **`gitleaks` por CLI, no por Action.** El job `secrets` ejecuta `zricethezav/gitleaks` vía Docker sobre todo el historial, porque `gitleaks/gitleaks-action@v2` pasó a exigir licencia de pago. Las excepciones viven en `.gitleaksignore`, una por línea y con su motivo. La primera corrida encontró un falso positivo real (un parámetro con apariencia de credencial en el badge por defecto de la plantilla de NestJS); este ADR no cita su valor a propósito, porque volver a escribirlo dispara la misma regla.
4. **`nestjs-pino` fijado en la serie 4.x.** La serie 5.x exige Node ≥ 22.12. Se revisa al evaluar una migración de la versión de Node de todo el proyecto.
5. **Evidencia.** [Run 36303969651](https://github.com/ISCOUTB/AS_202620_ElMapita/actions/runs/36303969651): primer pipeline completo en verde (7 de 7 jobs) tras dos iteraciones corrigiendo hallazgos reales de `gitleaks`.

## Consecuencias

- Los puntos del ADR-0004 sobre la base de imagen (`node:20-alpine`, mismo Node que `ci.yml`), el uso de `gitleaks-action@v2` y la versión de Node en CI/Docker quedan **reemplazados por este ADR**. El resto de ADR-0004 sigue vigente.
- El comentario del `backend/Dockerfile` ya documenta el motivo del cambio a Node 22 y de la base `slim`.
- El ADR-0004 se restauró a su versión aceptada (`30499d5`) y solo cambia su `status` a `Superseded by ADR-0012`.
- Regla para lo que sigue: un cambio posterior a un ADR aceptado se registra en un ADR nuevo con `supersedes`, nunca editando el anterior.
