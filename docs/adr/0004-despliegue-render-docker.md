---
number: 0004
date: 2026-09-27
title: "Despliegue y Operación: Render + Contenedor Docker, IaC versionada y Señales Mínimas de Operación"
status: Accepted
deciders: ["Diego Rosales Garza", "Rodrigo Vazquez Rico", "Angel Fabian Gutierrez Gomez"]
technical-story: "Semana 8 exige una URL pública del sistema alcanzable fuera de la red UTB, infraestructura como código versionada, pipeline en verde que bloquee el merge, health check honesto, logs estructurados, una métrica consultable ligada a un escenario de calidad, evidencia de secretos fuera del código, y una estimación de costo mensual con supuestos explícitos."
---

# ADR-0004: Despliegue y Operación — Render + Docker, IaC versionada, señales mínimas

## Contexto

El backend NestJS de El Mapita UTB nunca se ha desplegado fuera de `localhost`. No existe Dockerfile, IaC, logging estructurado ni métricas, y el health check (`backend/src/health.controller.ts`) **mentía**: siempre respondía `200 OK` con el cuerpo `{"status":"degraded"}` aunque Supabase estuviera inaccesible — exactamente el antipatrón que la Semana 8 pide detectar ("apaguen la base de datos y miren qué devuelve").

**El modelo de las seis piezas de la S08** (Sitio, API, Base de datos, Archivos, Trabajos, Pipeline) obliga a decidir cada pieza por separado. Para El Mapita UTB hoy:

| Pieza | Estado | Decisión de esta ADR |
|---|---|---|
| API | NestJS, monolito modular (DEC-01) | **Proceso en contenedor** — ver Decisión |
| Base de datos | Supabase (Postgres+PostGIS) | Ya gestionado, fuera de alcance |
| Archivos | Supabase Storage | Ya gestionado, fuera de alcance |
| Pipeline | GitHub Actions (`ci.yml`) | Se refuerza con gate real (branch protection) + secretos + build de imagen |
| Sitio | No existe | Fuera de alcance — no hay landing page separada |
| Trabajos | Pipeline de optimización de mallas 3D (RSK-01), sin implementar aún | Candidato futuro a función — no se implementa en esta ADR |

**Restricciones clave:**
- Proyecto académico, 3 desarrolladores, sin presupuesto — el despliegue debe caber en un tier gratuito real.
- El repositorio es público (`ISCOUTB/AS_202620_ElMapita`), así que GitHub Actions no tiene límite de minutos.
- No existe la "Guía de despliegue y costos" del curso al momento de esta decisión — la estimación de costo (sección más abajo) usa una metodología estándar y se reconciliará si esa guía aparece.
- El equipo hace push directo a `main` desde el inicio del semestre — activar un gate real de CI cambia ese flujo.

## Alternativas Consideradas (plataforma de despliegue)

| Alternativa | Descripción | Pros | Contras |
|-------------|-------------|------|---------|
| **1. Render** ✅ **SELECCIONADA** | Free tier real para *web services*; Blueprint (`render.yaml`) versionable como IaC nativa del proveedor; build desde Dockerfile. | IaC de un archivo, sin tarjeta de crédito requerida para el free tier; `healthCheckPath` nativo; logs de stdout capturados automáticamente. | Se duerme tras ~15 min de inactividad; primera petición tras dormir sufre cold start de decenas de segundos (ver RSK-05). |
| **2. Fly.io** | `fly.toml` como IaC, más control de red/regiones. | Despliegue rápido, buen soporte Docker. | Requiere tarjeta registrada aunque el tier gratuito no cobre — fricción para un proyecto académico sin ese dato a la mano hoy. |
| **3. Railway** | Config-as-code, buena DX. | Fácil de usar. | El tier gratuito es crédito por tiempo limitado, no permanente — riesgo real de que el servicio deje de estar arriba antes de que el evaluador lo revise. |
| **4. Servidor del laboratorio UTB** | El propio deck de la S08 lo menciona como opción, con una pregunta crítica sin responder: "si el despliegue abre desde fuera de la universidad". | Sin costo, sin proveedor externo. | La alcanzabilidad externa (requisito explícito de esta entrega: "el evaluador la abre desde su casa") **no está confirmada** — no hay NAT/dominio público verificado. Se descarta hasta que esa pregunta tenga respuesta institucional. |

**Análisis:** la 4 se descarta por incumplir directamente el requisito de alcanzabilidad externa mientras esa pregunta siga sin respuesta. Entre 2 y 3, ambas añaden fricción (tarjeta) o riesgo (crédito no permanente) que Render no tiene para el caso de uso puntual de este proyecto.

## Decisión

### 1. Contenedor + IaC versionada

- **`backend/Dockerfile`** — build multi-stage: `deps` (`npm ci`) → `build` (`npm run build` + `npm prune --omit=dev`) → `runtime` (solo `dist/`, `node_modules` de producción y `package.json`, usuario no-root). Verificado localmente: `docker build` + `docker run` exitosos, `/health` y `/metrics` responden correctamente **dentro del contenedor contra el proyecto real de Supabase**, no solo con datos falsos o en el Node local del equipo.
- **Base `node:22-slim`, no `node:20-alpine` ni `node:20-slim`.** El deploy real en Render pasó por tres causas de fondo, encontradas una tras otra solo al desplegar de verdad (ninguna aparecía en local ni en CI, y las dos primeras eran reales pero no la causa final):
  1. Esquema de Supabase vacío (el health check honesto marcó 503 correctamente) — resuelto con el DDL manual.
  2. Se sospechó de `node:20-alpine` (Alpine usa `musl`, con un bug conocido de resolución DNS que cuelga peticiones salientes en redes de nube) y se cambió a `node:20-slim` — mejora real pero no resolvió el síntoma.
  3. **Causa raíz definitiva**, encontrada instrumentando `/health` con logging de tiempos (ver sección 2): `@supabase/supabase-js` lanza `"Node.js detected but native WebSocket not found"` en cada consulta bajo Node 20 — no es el warning `EBADENGINE` de npm, es una excepción real en cada request, silenciosamente atrapada por nuestro propio `try/catch` y reportada como `503`, por lo que Render nunca veía un `200`. Se resolvió subiendo la imagen a `node:22-slim` (Node 22 trae `WebSocket` nativo). Verificado: mismo contenedor, mismas credenciales reales, `/health` responde `200` en ~1.2s (primera conexión) en vez de `503`/colgado.
- **`render.yaml`** (raíz) — Blueprint de Render: un `web` service `runtime: docker` apuntando a ese Dockerfile, `healthCheckPath: /health`, `plan: free`. Los secretos (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY`, `FRONTEND_URL`) se declaran con `sync: false` — Render pide su valor una sola vez en su dashboard, nunca se escriben en este archivo ni en git.

### 2. Health check honesto

`HealthController.check()` ahora lanza `ServiceUnavailableException(checks)` cuando `supabase !== 'ok'`, en vez de devolver `200` con `"degraded"` en el cuerpo. Verificado: con `SUPABASE_URL` inválida, el endpoint responde **503** real (confirmado tanto en local como corriendo dentro del contenedor Docker). `render.yaml` usa este mismo path como `healthCheckPath`, así que Render deja de enviarle tráfico si el servicio se degrada de verdad — no solo si el proceso muere.

Dos refuerzos agregados al diagnosticar el deploy real: (1) la consulta a Supabase corre contra un **timeout explícito de 4s** (`Promise.race`, con `clearTimeout` en el `finally` para no dejar temporizadores colgados) — el endpoint nunca se cuelga indefinidamente sin importar la causa, siempre responde rápido aunque sea con 503; (2) **logging explícito de tiempos** en cada paso (petición recibida, duración de la consulta, status final), independiente del autologging de pino-http (que excluye `/health` a propósito para no generar ruido) — esto fue lo que permitió encontrar la causa raíz real (sección "Decisión" arriba) en vez de seguir adivinando.

### 3. Logs estructurados

`nestjs-pino` (`^4.6.1` — la serie `5.x` exige Node ≥22.12, incompatible con el Node 20 de `ci.yml`/Dockerfile; se detectó al construir la imagen con `npm warn EBADENGINE` y se fijó la versión compatible) + `pino-http`. Cada request produce una línea JSON con método/ruta/status/latencia automáticamente; se redactan las cabeceras `authorization`; `/health` y `/metrics` se excluyen del autologging para no generar ruido en cada poll del orquestador. Render captura stdout/stderr tal cual — sin sink adicional.

### 4. Métrica consultable ligada a EC-01

`@willsoto/nestjs-prometheus` expone `GET /metrics` (excluido del prefijo `/api`, igual que `/health`). Un interceptor global (`HttpMetricsInterceptor`) instrumenta `http_request_duration_seconds{method,route,status_code}` para las 17 operaciones del contrato — las que importan para **EC-01** son `GET /api/v1/map/buildings/{buildingId}` y `GET /api/v1/map/floors/{floorId}/model`. El status de error se toma de `HttpException.getStatus()`, no de `response.statusCode` leído antes de tiempo (bug propio detectado y corregido durante la verificación: el primer intento etiquetaba todas las respuestas 503 como 200, porque el interceptor leía el status antes de que el filtro de excepciones lo escribiera).

No se despliega Prometheus/Grafana — `curl <url>/metrics` devolviendo números reales es la evidencia suficiente para esta escala de proyecto.

### 5. Secretos fuera del código

- `render.yaml` declara los **nombres** de las env vars, no sus valores (`sync: false`).
- Job `secrets` nuevo en `ci.yml`: CLI de `gitleaks` vía Docker (`zricethezav/gitleaks:latest detect`) sobre todo el historial. Se descartó el Action oficial `gitleaks/gitleaks-action@v2`: desde un cambio reciente del proveedor, exige una licencia paga (`GITLEAKS_LICENSE`); el binario `gitleaks` en sí sigue siendo MIT/gratuito, así que se invoca directo.
- **La primera corrida encontró un hallazgo real** (no simulado): un parámetro de query con apariencia de credencial en el badge de CircleCI que trae por defecto la plantilla de `nest new`, en `backend/README.md` — apunta al repositorio oficial `nestjs/nest`, no a este proyecto, y la línea ni siquiera se usaba en el archivo. Se eliminó la línea y se agregó `.gitleaksignore` documentando el fingerprint histórico (el commit que lo introdujo sigue en el historial; el escaneo de historial completo seguiría marcándolo sin el allowlist explícito). Verificado: `no leaks found` tras el fix.
  > Nota de redacción: este párrafo evita citar el valor textual del hallazgo a propósito — hacerlo dispara `generic-api-key` de nuevo sobre este mismo archivo (ya ocurrió una vez).
- Verificación manual adicional: `git log --all --full-history -p -- backend/.env` no devuelve nada (el archivo nunca se commiteó, solo `.env.example` con placeholders).

### 6. Pipeline: gate real + build de imagen

- Job `docker` nuevo en `ci.yml`: construye `backend/Dockerfile` en cada push — si el Dockerfile se rompe, el pipeline lo detecta antes que Render.
- **Branch protection en `main`**: regla que exige que `quality-gate` pase antes de aceptar cambios. Esto es "bloquee el merge ante fallos" literalmente. Cambia el flujo del equipo: hasta ahora se hacía push directo a `main` sin PR; de ahora en adelante el check debe pasar.
- **Evidencia:** [run 36303969651](https://github.com/ISCOUTB/AS_202620_ElMapita/actions/runs/36303969651) — primer pipeline completo en verde del proyecto (7/7 jobs, incluido `Quality Gate`), tras dos iteraciones corrigiendo hallazgos reales de `gitleaks` (ver sección 5).

## RSK-05 (nuevo riesgo)

**Cold start del plan free de Render vs. p95 de EC-01.** El servicio se duerme tras ~15 min de inactividad; la primera petición tras dormir tarda decenas de segundos en responder — el mismo concepto "arranque en frío vs. p95" que enseña la S08, aplicado ahora al backend completo en vez de a una función individual. Esto puede violar el p95 de 5s de EC-01 en la primera carga tras inactividad. Mitigación: si el p95 medido en producción lo exige, subir a Render Starter (~$7/mes, sin cold start) — no se implementa un keep-alive artificial para esta entrega (sería ocultar el problema, no resolverlo, y contradice el punto de cruce de costo de la sección siguiente).

## Estimación de costo mensual (metodología estándar — no existe la guía del curso)

**Supuestos de tráfico:** proyecto académico, repositorio público, tráfico esperado bajo (equipo + evaluador, <100 peticiones/día durante la evaluación).

| Componente | Tier elegido | Costo/mes bajo los supuestos | Punto de cruce a plan pago |
|---|---|---|---|
| Render (API, contenedor) | Free | $0 | **Starter, $7/mes** — si se necesita always-on sin cold start (ver RSK-05) o más de 512MB RAM |
| Supabase (DB + Storage + Auth) | Free | $0 | **Pro, $25/mes** — si se excede 500MB de DB, 1GB de Storage o 5GB de egreso/mes |
| GitHub Actions (CI) | Ilimitado (repo público) | $0 | No aplica — solo si el repo se vuelve privado |
| Dominio | Subdominio `*.onrender.com` | $0 | Costo de un dominio propio si se quisiera una URL de marca (~$10-15/año), fuera de alcance |
| **Total estimado** | | **$0/mes** | Primer gasto real esperado: $7/mes (Render Starter) si el cold start resulta inaceptable para EC-01 en producción |

## Consecuencias

### Positivas

| Área | Impacto |
|---|---|
| **Health check confiable** | Render (y cualquier orquestador futuro) puede sacar tráfico automáticamente de una instancia degradada — antes era imposible, porque el health check siempre decía "estoy bien". |
| **Contrato de API + observabilidad coherentes** | La métrica de latencia se ligó explícitamente a EC-01 (ADR-0003), reforzando la trazabilidad ya existente en vez de crear un eje nuevo de evidencia. |
| **IaC realmente reproducible** | Cualquiera con acceso al repo puede recrear el despliegue completo importando `render.yaml` — no depende de configuración manual no documentada. |
| **Se encontraron y cerraron dos bugs reales al verificar, no al leer código** | (1) `tsconfig.build.json` no excluía `backend/scripts/`, lo que había roto silenciosamente `npm run start:prod` (`dist/main` no existía, quedaba en `dist/src/main`) desde que se agregaron esos scripts en la sesión anterior — nunca se había ejecutado el build empaquetado hasta ahora. (2) El interceptor de métricas etiquetaba mal las respuestas de error (ver sección 4). Ambos solo aparecieron al ejecutar de verdad la imagen Docker, no al compilar o testear en aislamiento. |

### Negativas / Trade-offs

| Compromiso | Mitigación |
|---|---|
| **Cold start en el plan free** | RSK-05, documentado arriba con punto de cruce explícito a plan pago. |
| **El proyecto subió a Node 22 en CI/Docker a mitad de esta entrega** | No fue una decisión de antemano — se descubrió que era obligatorio (`@supabase/supabase-js` falla en tiempo de ejecución en Node <22, no solo advierte). `nestjs-pino` había quedado fijado en `4.6.1` para evitar justo este salto; con Node 22 ya no es necesario mantenerlo así, pero tampoco hace daño (funciona en cualquier Node ≥14). |
| **Branch protection cambia el flujo del equipo** | De ahora en adelante un push a `main` que rompa `quality-gate` no se refleja como aceptado sin intervención — el equipo debe esperar a que el check pase o abrir PR. Documentado en `correcciones.md`. |
| **No hay Prometheus/Grafana desplegado** | Decisión de alcance explícita: `/metrics` crudo es evidencia suficiente para esta escala; se documenta como próximo paso natural si el proyecto creciera. |

## Runbook de despliegue (para quien ejecute el deploy real en Render)

1. Crear cuenta en [render.com](https://render.com) (gratis, sin tarjeta para el plan free).
2. "New +" → "Blueprint" → conectar el repositorio `ISCOUTB/AS_202620_ElMapita` → Render detecta `render.yaml` automáticamente.
3. Al crear el servicio, Render pedirá valor para cada env var con `sync: false`: pegar `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY` (los mismos del `.env` local) y `FRONTEND_URL` (la URL del frontend una vez desplegado, o `http://localhost:3000` mientras tanto).
4. Esperar el primer build (~2-3 min) — Render construye la imagen desde `backend/Dockerfile`.
5. Verificar: `curl https://<nombre-del-servicio>.onrender.com/health` → `200` con `"status":"ok"`; `curl .../metrics` → texto Prometheus con datos reales.
6. Pedir a alguien fuera del campus (o abrir desde datos móviles) que confirme que la URL carga — o simplemente confirmar que no es un dominio `.utb.edu.co`/IP interna, lo que ya garantiza alcance público.

## Referencias

- [ADR-0001: Estilo Arquitectónico Monolito Modular](0001-estilo-arquitectonico-propuesto.md)
- [ADR-0003: Contrato OpenAPI Versionado](0003-contrato-openapi-versionado.md) — EC-01 y las rutas que esta ADR instrumenta con métricas
- [`render.yaml`](../../render.yaml) · [`backend/Dockerfile`](../../backend/Dockerfile)
- [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) — jobs `secrets`, `docker`, `contract`
- [`correcciones.md`](../../correcciones.md) — cambio de flujo del equipo por branch protection
- [arc42 Sección 9: DEC-08](../arc42/arc42-template-EN.md#section-design-decisions) · [Sección 11: RSK-05](../arc42/arc42-template-EN.md#section-technical-risks)
