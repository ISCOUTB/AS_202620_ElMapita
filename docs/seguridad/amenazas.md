# S11 — Tabla de amenazas priorizadas (STRIDE)

> Modelo del sistema: [`dfd.md`](./dfd.md). Alcance de esta versión: backend, autenticación, mensajería, despliegue y cliente. La cadena de suministro y la privacidad se desarrollan en documentos aparte (pasos 3 y 4 del plan S11).

**Escala.** Probabilidad (P) e Impacto (I) de 1 a 5. Riesgo = P × I. Prioridad: **Crítica** ≥ 20, **Alta** 12-19, **Media** 6-11, **Baja** ≤ 5.

**Responsables.** Se asigna por rol (Backend, Frontend, DevOps); los nombres de los integrantes se confirman en la reunión del equipo.

**Estado de verificación.** "Verificado" = leído en el código citado. "Por probar" = la amenaza sigue de la lectura, pero falta una prueba que la reproduzca.

## 1. Amenazas

| ID | STRIDE | Escenario (quién, por dónde, qué gana) | Evidencia | P×I | Prioridad | Mitigación concreta | Verificación de la mitigación | Resp. |
|----|--------|----------------------------------------|-----------|-----|-----------|---------------------|-------------------------------|-------|
| T-01 | Elevación de privilegios | Un anónimo llama `POST /v1/auth/users/<id>/role` con `{"userId":"…","role":"admin_utb"}` y se convierte en administrador. El endpoint dice "solo admin" pero no tiene guard. La doc (`C4_L2_Container.md:17`) afirma "RBAC JWT": hoy es falso. | `auth.controller.ts:87-94`; `use-cases.ts:155-157` | 5×5=25 | **Crítica** | `AuthGuard` global que valida el JWT con Supabase y `RolesGuard` con `@Roles('admin_utb')`; rutas públicas marcadas con `@Public()` (deny by default). | Prueba e2e: sin token → 401; con rol `estudiante` → 403; con `admin_utb` → 200. | Backend |
| T-02 | Elevación de privilegios | Un usuario registrado cambia su propio `role` con el SDK de Supabase (`auth.updateUser(data: {role})`) porque el rol se lee de `user_metadata`, que el usuario puede escribir. Se vuelve admin sin tocar el backend. | `supabase-auth-client.ts:102-115` (línea 110); `supabase_auth_client.dart:40` | 4×5=20 | **Crítica** | Guardar el rol en `app_metadata` (solo escribible con service key) y leerlo de ahí en backend y app. Migrar usuarios existentes. | Prueba de regresión: con un JWT de usuario normal, `updateUser` con `role` no cambia lo que lee el backend. | Backend |
| T-03 | Manipulación | Un anónimo crea POIs falsos (`POST /v1/pois`) y desinforma sobre ubicaciones del campus; el dato se guarda, invalida la caché y publica un evento. | `pois.controller.ts:43-49`; `pois/application/use-cases.ts:101` | 5×3=15 | **Alta** | El mismo `AuthGuard` + `@Roles('admin_staff','admin_utb')` de T-01. | e2e: `POST /v1/pois` sin token → 401, con rol insuficiente → 403. | Backend |
| T-04 | Manipulación | Los cuerpos de entrada son `interface`/`import type`, sin decoradores de `class-validator`. `ValidationPipe` (`whitelist`, `forbidNonWhitelisted`) no puede validar un tipo que desaparece al compilar, así que entra cualquier JSON (campos extra, tipos erróneos, rol inválido) a casos de uso y a PostGIS. | `main.ts:17-24`; `pois/domain/index.ts:63-69`; `auth.controller.ts:17-22` | 4×3=12 | **Alta** (por probar) | Convertir los DTO de entrada a clases con `class-validator` (`@IsEmail`, `@IsIn(roles)`, `@IsLatitude`, `@Length`). Mantener los tipos de dominio aparte. | Prueba e2e: body con campo extra o `role:"x"` → 400. Confirmar primero con un caso que hoy pasa. | Backend |
| T-05 | Suplantación | Credential stuffing y fuerza bruta contra `POST /v1/auth/signin`, sin límite de intentos propio. | `auth.controller.ts:36-42` | 4×3=12 | **Alta** | `@nestjs/throttler` con límite estricto en `/auth/*` (p. ej. 5/min por IP); confirmar los límites de Supabase Auth. | Prueba e2e: el intento n+1 devuelve 429. | Backend |
| T-06 | Denegación de servicio | Inundación de peticiones a cualquier endpoint público contra una instancia de 256 MB / 0,5 CPU (y plan free de Render); sin rate limit global. | `compose.lab.yaml:32-35`; `render.yaml` (`plan: free`) | 4×3=12 | **Alta** | Throttler global (p. ej. 100/min por IP), límite de tamaño de body, timeouts. | Prueba de carga corta (k6/autocannon) con evidencia en `docs/evidencia/`. | Backend / DevOps |
| T-07 | Divulgación de información | `/docs` (Swagger) y `/metrics` (Prometheus) quedan públicos en producción: el atacante obtiene el mapa completo de endpoints (incluidos los sin guard) y datos de operación. | `main.ts:35-36, 43` | 5×2=10 | **Media** | Deshabilitar Swagger si `NODE_ENV=production`; proteger `/metrics` con token o red interna. | e2e en modo producción: `/docs` → 404; `/metrics` sin credencial → 401/403. | Backend / DevOps |
| T-08 | Divulgación / Elevación | El backend usa siempre la `service_role` key, que omite RLS. Cualquier falla de autorización en la API equivale a acceso total a la base. | `shared/supabase/client.ts:11, 19` | 3×5=15 | **Alta** | Mínimo privilegio: lecturas con la anon key y el JWT del usuario (RLS aplica); `service_role` solo en las pocas operaciones administrativas. Rotar la key. | Revisión de código: listar usos de `getSupabaseClient`; prueba con un JWT de usuario que no pueda leer/escribir lo que RLS niega. | Backend |
| T-09 | Divulgación / Manipulación | La anon key viaja en el bundle de Flutter web (`--dart-define`), por diseño. La defensa real es RLS, y en el repo no hay SQL versionado con `ENABLE ROW LEVEL SECURITY` ni `CREATE POLICY`, así que no se puede comprobar. | `ci.yml:211`; búsqueda de `POLICY`/`ROW LEVEL` sin resultados | 3×4=12 | **Alta** (por verificar) | Versionar el esquema y las políticas RLS en el repo (`db/` o ADR-0010) y activar RLS en todas las tablas. | Script que consulta `pg_tables.rowsecurity` y falla en CI si alguna tabla pública no lo tiene. | Backend |
| T-10 | Repudio | Cambios de rol y altas de POI no dejan rastro de quién los hizo: los logs no incluyen identidad del usuario porque no hay middleware de autenticación. | `logger.module.ts:15-19`; `auth.controller.ts:92` | 3×3=9 | **Media** | Con el guard de T-01, añadir `userId` al contexto de pino y registrar eventos de auditoría (`role.changed`, `poi.created`). | Prueba: tras cambiar un rol, el log contiene actor, objetivo y valor. | Backend |
| T-11 | Divulgación (privacidad) | `pino-http` registra IP y cabeceras de cada petición; `redact` cubre solo `authorization`. Quedan `cookie`, IP y otras cabeceras en los logs de Render. | `logger.module.ts:18` | 4×2=8 | **Media** | Ampliar `redact` (`cookie`, `x-forwarded-for`, `*.password`, `*.email`) y definir retención de logs. Ver `privacidad.md`. | Prueba unitaria del logger: una petición con cookie no la deja en el log. | Backend |
| T-12 | Divulgación / Suplantación | Errores sin tratar: `throw new Error(...)` produce HTTP 500 en vez de 401, y el mensaje de Supabase llega al cliente (`Sign in failed: …`). Dificulta la defensa y filtra detalles. | `supabase-auth-client.ts:27-29`; `auth.controller.ts:81`; `use-cases.ts:133` | 4×2=8 | **Media** | `ExceptionFilter` global con errores tipados (`UnauthorizedException`, etc.) y mensajes genéricos al cliente. | e2e: credenciales inválidas → 401 con cuerpo genérico, sin texto de Supabase. | Backend |
| T-13 | Cadena de suministro | Imágenes y herramientas flotantes: `node:22-slim` sin digest, `gitleaks:latest`, `@redocly/cli@latest`, actions por tag. Una actualización maliciosa llega a CI sin revisión. | `Dockerfile:18, 28`; `ci.yml:100, 148` | 3×4=12 | **Alta** | Fijar por digest/SHA, Dependabot, escaneo de imagen y de dependencias. Detalle en el paso 3. | Job `deps-audit` en CI con umbral High/Critical. | DevOps |
| T-14 | Denegación de servicio | La lista `dead` del bus crece sin límite y los mensajes pendientes se pierden al reiniciar. Con 256 MB de memoria, un flujo constante de fallos agota el proceso. | `in-memory-message-bus.ts:61, 139-145`; ADR-0009 | 2×2=4 | **Baja** | Tope de capacidad (como `dedupCapacity`) para `dead`, con descarte del más antiguo y métrica. | Prueba unitaria: tras N+1 fallos la lista no supera N. | Backend |
| T-15 | Suplantación | CORS con un único origen y `credentials: true`; si `FRONTEND_URL` queda mal configurada, otro origen podría actuar con las credenciales. La app móvil no depende de CORS. | `main.ts:12-15` | 2×3=6 | **Media** | Validar `FRONTEND_URL` con Joi (URL https explícita, sin `*`) y fallar al arrancar si no cumple. | Prueba de configuración: valor inválido → el arranque aborta. | Backend |
| T-16 | Divulgación (privacidad) | La ubicación del usuario es dato personal. **Verificado: no sale del dispositivo ni se persiste** (se convierte a coordenadas del modelo 3D y se inyecta en el visor). El riesgo residual es que una función futura la envíe sin evaluarlo. | `campus_model_page.dart:177-203`; `location-adapter.ts:6-27`; `privacidad.md` §1 | 1×4=4 | **Baja** (verificado) | Mantenerlo como decisión DP-1 y exigir un ADR antes de enviar ubicación (DP-4). | Prueba automatizada que falle si algún cliente HTTP o canal recibe coordenadas. | Frontend |
| T-17 | IA en el desarrollo | El asistente de IA lee el repo: un archivo con instrucciones ocultas (inyección indirecta), una dependencia con nombre inventado o un secreto pegado en el prompt llegan al código o a un tercero. | `docs/ia.md` | 2×3=6 | **Media** | Revisión humana de cada dependencia nueva; gitleaks ya activo (`ci.yml:135-148`); regla de no pegar `.env` en el asistente. | Checklist en la plantilla de PR + gitleaks en verde. | Equipo |

> **Actualización 2026-11-01:** T-01, T-02 (backend), T-03 y T-11 quedaron mitigadas; ver el estado en [ADR-0011](../adr/0011-modelado-de-amenazas-y-mitigaciones.md).

## 2. Resumen por prioridad

| Prioridad | Cantidad | IDs |
|-----------|----------|-----|
| Crítica | 2 | T-01, T-02 |
| Alta | 7 | T-03, T-04, T-05, T-06, T-08, T-09, T-13 |
| Media | 6 | T-07, T-10, T-11, T-12, T-15, T-17 |
| Baja | 2 | T-14, T-16 |

## 3. IA generativa en el producto (OWASP Top 10 for LLM Applications)

El producto no incorpora un componente generativo (`docs/adr/0007-no-incorporar-componente-generativo.md`). Los riesgos de LLM01 (inyección de prompts), LLM02 (divulgación de información sensible), LLM06 (agencia excesiva) y el resto de la lista no aplican a la superficie desplegada. Se reabre el análisis si se cumple la condición de revisión del ADR-0007. La IA como **herramienta de desarrollo** sí tiene riesgo y queda cubierta en T-17.

## 4. Hallazgos de coherencia documentación–código

| Documento | Afirma | Código |
|-----------|--------|--------|
| `C4_L2_Container.md:17` | "RBAC JWT" en el backend | No hay guards (T-01, T-03) |
| `auth.controller.ts:89` | "Actualizar rol (solo admin)" | Sin comprobación de rol |
| `pois.controller.ts:44` | "Crear nuevo POI (admin)" | Sin comprobación de rol |
| `C4_L2_Container.md:17` | "Docker Node18+" | `Dockerfile` usa Node 22 |

## 5. Verificaciones pendientes antes de cerrar

1. Reproducir T-01, T-02 y T-04 en un entorno de pruebas (nunca contra producción) y guardar la salida en `docs/evidencia/`.
2. Confirmar el estado de RLS en Supabase (T-09) y exportar el esquema al repo.
3. T-16 quedó verificado por lectura de código; falta, si se quiere evidencia adicional, una captura del tráfico de red de la app.
