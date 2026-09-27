---
number: 0003
date: 2026-09-20
title: "Contrato de Integración FE-BE: OpenAPI 3.1 Versionado con Prueba de Contrato en el Pipeline"
status: Accepted
deciders: ["Diego Rosales Garza", "Rodrigo Vazquez Rico", "Angel Fabian Gutierrez Gomez"]
technical-story: "DEC-06 (arc42) declaró 'Contratos de API tipados mediante OpenAPI/Swagger' desde el ADR-0001, y este mismo ADR-0001 prometió un `npm run test:contracts` que nunca se implementó. Este ADR cierra esa brecha: fija el estándar de contrato (OpenAPI vs AsyncAPI), lo versiona como archivo en el repositorio y lo verifica en CI."
---

# ADR-0003: Contrato de Integración FE-BE — OpenAPI 3.1 Versionado con Prueba de Contrato en el Pipeline

## Contexto

El Mapita UTB tiene dos consumidores de la API backend en tensión constante de sincronización: el frontend Flutter (`frontend/lib/features/*/infrastructure/api/`) y el propio backend NestJS. Hasta ahora, el "contrato" entre ambos era implícito:

- `backend/src/main.ts` genera un documento Swagger **en memoria** al arrancar (`SwaggerModule.createDocument`), servido en `/docs`, pero **no se persiste versionado en el repositorio**. No hay forma de diffear un cambio de contrato en un PR ni de fijar qué versión del contrato corresponde a qué versión del frontend.
- El arc42 (DEC-06, línea 537) ya declara la intención — "Backend actúa como única fuente de verdad documental" — y el ADR-0001 (sección "Plan de Implementación Inmediata", paso 5) prometió `npm run test:contracts` "en verde". Ese script **nunca existió**.
- El equipo sigue siendo de 3 desarrolladores trabajando en paralelo por módulo (DEC-01); sin un contrato verificado automáticamente, un cambio de ruta o de forma de respuesta en un módulo solo se descubre cuando el otro lado falla en runtime.

**Esa falta de verificación ya tiene costo real, encontrado al preparar este ADR:** el backend expone sus rutas con el prefijo de ruta duplicado, y el frontend consume las rutas sin duplicar:

| Endpoint (ejemplo) | Frontend consume (`dio_client.dart:10` + `mapas_api.dart:14`) | Backend expone (`main.ts:9` `setGlobalPrefix('api')` + `mapas.controller.ts:7` `@Controller('api/v1/map')`) |
|---|---|---|
| Listar edificios | `GET /api/v1/map/buildings` | `GET /api/api/v1/map/buildings` |
| Health check | `GET /health` (`README.md:163`, C4 L3) | `GET /api/health` |

Los 4 controladores con prefijo de módulo (`auth`, `mapas`, `pois`, `ubicacion`) repiten `api/v1/...` sobre el `setGlobalPrefix('api')` global; `HealthController` no está excluido del prefijo global aunque toda la documentación (README, C4 Nivel 3) lo describe como `/health` sin prefijo. El e2e existente (`backend/test/app.e2e-spec.ts`) no lo detecta porque construye la app de pruebas sin replicar `setGlobalPrefix` del `main.ts` real: prueba una aplicación distinta a la que se despliega.

**Restricciones clave:**
- No hay presupuesto para introducir un broker de mensajería ni infraestructura de eventos propia en este corte.
- Supabase Realtime (canal de notificación de nueva versión de modelo 3D) sigue siendo **deuda declarada sin implementar** (ADR-0002, sección "Estado de implementación: pendiente").
- `@nestjs/swagger@11` ya está instalado y los 5 controladores ya están decorados (`@ApiTags`, `@ApiOperation`, `@ApiResponse`), así que cualquier generador de contrato puede apoyarse en ese trabajo existente.

**Vínculo con el escenario de calidad EC-01:** `GET /api/v1/map/buildings/{buildingId}` y `GET /api/v1/map/floors/{floorId}/model` son las llamadas que `LoadBuildingUseCase` invoca en el flujo de carga inicial documentado en [arc42 §6.1](../arc42/arc42-template-EN.md#61-escenario-1-carga-y-renderizado-inicial-de-un-edificio-3d-ec-01-y-ec-02) (ver también EC-01, [arc42 §10.2](../arc42/arc42-template-EN.md#section-quality-scenarios)). Antes de este ADR, esas dos rutas respondían `404` por RSK-04 — es decir, **EC-01 no podía cumplirse en absoluto** en un entorno con el backend desplegado como está en `main`, más allá de cualquier medición de tiempo. Cerrar RSK-04 (ver "Decisión", punto 4) es condición necesaria, aunque no suficiente, para que EC-01 y EC-02 sean medibles.

## Alternativas Consideradas

| Alternativa | Descripción | Pros | Contras |
|-------------|-------------|------|---------|
| **1. Mantener solo Swagger en runtime (statu quo)** | Seguir generando el documento en memoria vía `SwaggerModule`, sin archivo versionado ni verificación automática. | Cero esfuerzo adicional; ya funciona para explorar la API manualmente en `/docs`. | Sin archivo versionado no hay diff revisable en PR; sin verificación automática, la deriva de rutas (tabla arriba) queda invisible hasta que falla en producción — exactamente lo que ya ocurrió. |
| **2. OpenAPI 3.1 contract-first versionado, verificado en CI** ✅ **SELECCIONADA** | Un archivo `docs/api/openapi.v1.yaml` es la fuente de verdad; un job de CI genera el documento real desde los decoradores NestJS y lo compara contra el archivo, además de ejercer las rutas reales con supertest y validar las respuestas contra los schemas del contrato. | Aprovecha `@nestjs/swagger` ya instalado; OpenAPI 3.1 usa JSON Schema 2020-12 nativo (validación de respuestas sin capa de traducción); versión semántica explícita (`info.version`) y regla de evolución (MAJOR/MINOR/PATCH) documentada; detecta exactamente el tipo de deriva ya encontrado. | Requiere mantener el archivo sincronizado con los DTOs cuando cambian (mitigado por el paso de deriva en CI); tres capas de verificación (lint, deriva, runtime) añaden ~1 min al pipeline. |
| **3. AsyncAPI** | Documentar la integración como canales de eventos (p.ej. el canal de Supabase Realtime para notificación de nueva versión de modelo 3D). | Sería el estándar correcto **si** la integración fuera predominantemente asíncrona. | No aplica hoy: las 16 operaciones que consume el frontend son 100% HTTP REST síncronas; no existe broker propio; el único canal asíncrono candidato (Supabase Realtime) es protocolo de un tercero y es deuda sin implementar (ADR-0002). Adoptarlo ahora documentaría un canal que no existe en código. |
| **4. Code-first puro (confiar en los decoradores, sin archivo de contrato)** | Generar el documento desde NestJS en cada request a `/docs` y considerarlo la única fuente de verdad, sin comparar contra nada externo. | Sin mantenimiento de un archivo paralelo. | El "contrato" pasa a ser lo que el código *ya hace*, no lo que el código *debería hacer*. No hay forma de que una prueba distinga "cambié la API a propósito" de "rompí la API por accidente" — es exactamente la categoría de bug (prefijo duplicado) que este ADR busca prevenir. |

**Análisis:** la alternativa 1 es la que ya está en el repo y es la que permitió que el desajuste de rutas pasara inadvertido. La alternativa 3 resuelve un problema que el proyecto no tiene todavía. La alternativa 4 confunde "documentar el código" con "verificar el código contra una intención declarada". La alternativa 2 es la única que provee un punto de comparación independiente del código — condición necesaria para que una prueba de contrato tenga sentido.

## Decisión

**Adoptamos OpenAPI 3.1 contract-first, versionado en el repositorio y verificado en el pipeline en tres capas:**

1. **`docs/api/openapi.v1.yaml`** es la fuente de verdad del contrato REST v1. Declara las 16 operaciones de los 5 controladores (`Health`, `Autenticación`, `Mapas`, `POIs`, `Ubicación`) con los schemas derivados de los tipos de dominio ya existentes (`src/modules/*/domain/index.ts`). Las rutas se declaran como el frontend las consume hoy (`/api/v1/...`, `/health`), no como el backend las expone — el contrato fija la intención correcta.
2. **Regla de versionado:** MAJOR → nuevo archivo `openapi.v2.yaml` + prefijo `/api/v2` con ventana de convivencia; MINOR → `1.x.0` (campo/operación aditiva); PATCH → `1.0.x` (aclaración). Documentada en `info.description` del propio contrato y en `docs/api/README.md`.
3. **Prueba de contrato en el pipeline** (`.github/workflows/ci.yml`, job `contract`), en tres capas:
   - **Lint** (`@redocly/cli lint`) — el archivo es OpenAPI 3.1 válido. Bloqueante.
   - **Deriva** (`npm run openapi:drift`) — genera el documento real desde `AppModule` con el mismo `setGlobalPrefix` de `main.ts` y compara el conjunto de rutas contra el contrato. No bloqueante mientras RSK-04 esté abierto (ver Consecuencias).
   - **Runtime** (`npm run test:contracts`) — levanta la aplicación completa (mismo `ValidationPipe` y `setGlobalPrefix` de `main.ts`) con los 6 puertos hacia Supabase sustituidos por fakes en memoria (habilitado por DEC-02), ejerce cada operación del contrato con supertest y valida las respuestas 2xx contra los schemas del contrato con Ajv (JSON Schema 2020-12 nativo de OpenAPI 3.1). No bloqueante mientras RSK-04 esté abierto.
4. **Cierre de RSK-04.** El desajuste de rutas descrito arriba se corrigió como parte de este mismo ADR: se quitó el prefijo `api/` redundante de los 4 controladores de módulo (quedan como `@Controller('v1/map')`, `@Controller('v1/pois')`, `@Controller('v1/auth')`, `@Controller('v1/location')`, combinados con `setGlobalPrefix('api')` → `/api/v1/...`) y se excluyó `health` del prefijo global (`app.setGlobalPrefix('api', { exclude: ['health'] })`) para que coincida con lo que ya documentaban el README y el C4 Nivel 3. `npm run openapi:drift` reporta **0 rutas en deriva** y los pasos de deriva/runtime en `ci.yml` (job `contract`) ya no necesitan `continue-on-error`. El run de CI que capturó la deriva en rojo antes del fix ([run 35549974182](https://github.com/ISCOUTB/AS_202620_ElMapita/actions/runs/35549974182), job "Contrato API (OpenAPI 3.1)") queda como evidencia histórica de que la prueba de contrato detecta correctamente una incompatibilidad real.

5. **Hallazgo adicional durante el cierre de RSK-04: inyección de dependencias rota en 14 casos de uso.** Al corregir las rutas, las peticiones llegaron por primera vez a los controladores y expusieron que `GetBuildingUseCase`, `ListBuildingsUseCase`, `GetFloorModelUseCase` (mapas), `GetPoiUseCase`, `ListPoisByFloorUseCase`, `CreatePoiUseCase` (pois), `SignInUseCase`, `SignUpUseCase`, `RefreshTokenUseCase`, `SignOutUseCase`, `GetCurrentUserUseCase`, `UpdateUserRoleUseCase` (auth) y `GetCurrentLocationUseCase`, `RequestLocationPermissionUseCase` (ubicación) recibían sus dependencias tipadas por interfaz TypeScript (`BuildingRepository`, `PoiRepository`, `SupabaseAuthClient`, `LocationProvider`, etc.) **sin el decorador `@Inject('Token')`**. Como las interfaces se borran en tiempo de compilación, Nest no podía resolver el token y el parámetro llegaba `undefined` al constructor — cada endpoint real (crear/listar edificios, POIs, ubicación, login) respondía `500`. Nunca se detectó antes porque ningún test previo ejercía estas rutas de punta a punta, y el propio RSK-04 impedía que las peticiones llegaran siquiera al controlador. Se corrigió agregando `@Inject('Token')` + `@Injectable()` a los 14 sitios (`src/modules/{mapas,pois,auth,ubicacion}/application/use-cases.ts`); la prueba de contrato runtime ahora valida además el **cuerpo** de cada respuesta 2xx contra el schema del contrato (antes solo comprobaba que la ruta no fuera 404, lo que ocultaba este bug).

## Consecuencias

### Positivas (Beneficios Esperados)

| Área | Impacto |
|------|---------|
| **Detección temprana de deriva** | La prueba de contrato encontró, antes de este ADR llegar a producción, dos desajustes reales de ruta (`/api/api/v1/...` y `/api/health` vs `/health`) que el e2e existente no detectaba — y, al corregirlos, un bug de inyección de dependencias que dejaba 500 en casi toda la API real. Ambos quedaron cerrados en el mismo ADR. |
| **Contrato como PR revisable** | `docs/api/openapi.v1.yaml` es texto versionado: un cambio de forma de respuesta o de ruta ahora aparece como diff en el PR, no como incidente en producción. |
| **Cierra la promesa de ADR-0001** | `npm run test:contracts` (paso 5 del plan de implementación del ADR-0001) existe y corre en CI. |
| **Cero infraestructura nueva** | Se apoya en `@nestjs/swagger` (ya instalado) y en el desacoplo de Supabase (DEC-02) para los fakes de prueba; no se introduce broker ni servicio nuevo. |
| **Camino claro a AsyncAPI** | Cuando Supabase Realtime deje de ser deuda (ADR-0002), un ADR sucesor puede adoptar AsyncAPI específicamente para ese canal, sin reabrir esta decisión para el REST síncrono. |

### Negativas / Compromisos Técnicos (Trade-offs)

| Compromiso | Mitigación |
|------------|------------|
| **El contrato puede desincronizarse de los DTOs si no se actualiza a mano** | El paso de deriva en CI (`openapi:drift`) compara contra lo que NestJS genera realmente desde los decoradores; una discrepancia queda visible en cada corrida, aunque no bloquee todavía. |
| **El bug de DI (14 casos de uso) llevaba oculto desde el esqueleto inicial (agosto)** | No se detectó porque RSK-04 impedía que cualquier request real llegara al controlador. Mitigación aplicada: `@Inject('Token')` explícito en los 14 sitios; la prueba de contrato ahora valida el cuerpo de la respuesta, no solo el código de estado, para que un regreso a este patrón vuelva a fallar en CI. |
| **Tres capas de verificación añaden tiempo al pipeline** | Lint (~1 s) y deriva (~2 s) son rápidos; el runtime (`test:contracts`) reutiliza el mismo patrón de fakes que ya usa `test:cov`, sin overhead de red real. |
| **Ajv debe resolver `$ref` contra el documento OpenAPI completo, no JSON Schema puro** | Se registra el documento completo en Ajv (`addSchema`) y se referencian los schemas de operación por JSON Pointer (`contract#/components/schemas/X`), evitando duplicar definiciones entre el contrato y las pruebas. |

## Referencias

- [ADR-0001: Estilo Arquitectónico Monolito Modular](0001-estilo-arquitectonico-propuesto.md) — DEC-02 (desacoplo Supabase, habilita los fakes de la capa runtime), DEC-06 (origen de la intención de OpenAPI)
- [ADR-0002: Restricción de Rendimiento — LOD y Degradación Progresiva](0002-restriccion-rendimiento-compatibilidad-dispositivos.md) — estado de Supabase Realtime como deuda, razón para no adoptar AsyncAPI todavía
- [`docs/api/openapi.v1.yaml`](../api/openapi.v1.yaml) — el contrato
- [`docs/api/README.md`](../api/README.md) — cómo correr las tres capas de verificación localmente
- [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) — job `contract`
- [`correcciones.md`](../../correcciones.md) — deuda RSK-04 y su criterio de cierre
- [arc42 Sección 9: Decisiones de arquitectura — DEC-07](../arc42/arc42-template-EN.md#section-design-decisions)
- [arc42 Sección 11: Riesgos y deuda técnica — RSK-04](../arc42/arc42-template-EN.md#section-technical-risks)
