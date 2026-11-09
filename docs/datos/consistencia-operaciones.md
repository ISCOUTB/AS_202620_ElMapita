# Operación → garantía de consistencia

Fuente: código en `backend/src/modules/*` y `frontend/lib/features/mapas`. Almacén de verdad: PostgreSQL (Supabase) + Storage (ver [ADR-0010](../adr/0010-postgresql-postgis-fuente-de-verdad.md)). La caché del servidor se describe en [diseno-cache.md](diseno-cache.md).

**Vocabulario.** *Read committed*: cada consulta ve solo datos confirmados, pero dos consultas seguidas pueden ver estados distintos (no hay snapshot entre ellas). *Obsolescencia acotada*: una lectura puede devolver un dato viejo, pero nunca más viejo que el TTL. *Read-your-writes*: tras escribir, la misma instancia lee lo escrito.

## Tabla

| # | Operación | Endpoint / código | Almacén | Garantía efectiva | Riesgo asumido y mitigación |
|---|---|---|---|---|---|
| 1 | Listar edificios | `GET /api/v1/map/buildings` · `ListBuildingsUseCase` | `edificios` + caché | Read committed + **obsolescencia ≤ 10 min** (TTL) | Una edición manual en Supabase tarda hasta 10 min en verse. Aceptable: los edificios cambian en semestres. |
| 2 | Detalle de edificio | `GET /api/v1/map/buildings/:id` · `GetBuildingUseCase` | `edificios`, `pisos`, Storage + caché | **Tres lecturas sin transacción**: sin snapshot entre ellas. Obsolescencia ≤ 10 min por pieza | Lectura "rasgada" posible (edificio nuevo con pisos viejos). Mitigación: la versión del modelo va en la ruta del `.glb`, de modo que la URL siempre apunta a un archivo coherente con la versión leída. |
| 3 | Modelo 3D de un piso | `GET /api/v1/map/floors/:id/model` · `GetFloorModelUseCase` | `pisos`, Storage + caché | Igual que la fila 2 | Firma la ruta con `floor.edificioId`, es decir, el modelo del edificio y no uno por piso (deuda conocida). |
| 4 | URL firmada del `.glb` | `SupabaseModel3DStorage.getSignedUrl` | Storage + caché | **Inmutable por versión**; válida 1 h; cacheada 50 min | El TTL de caché es menor que la expiración para no entregar URLs a punto de caducar. |
| 5 | Leer un POI | `GET /api/v1/pois/:id` · `GetPoiUseCase` | `pois` + caché | Read committed + **obsolescencia ≤ 5 min**; read-your-writes tras `CreatePoi` en la misma instancia | Ediciones hechas fuera de la API se ven tras ≤ 5 min. |
| 6 | Listar POIs de un piso | `GET /api/v1/pois/floor/:id` · `ListPoisByFloorUseCase` | `pois` + caché | Igual que la fila 5 | Igual que la fila 5. |
| 7 | **Crear POI** | `POST /api/v1/pois` · `CreatePoiUseCase` → `save` (upsert) | `pois` | **Atómica por fila (ACID de Postgres)**; **idempotente solo si el cliente envía `Idempotency-Key`** | Sin la cabecera, el UUID lo genera el servidor en cada petición y reintentar tras un timeout duplica el POI. Con `Idempotency-Key` (1 a 128 caracteres), el id se deriva de usuario y llave: el reintento devuelve el POI ya creado, sin guardar ni publicar de nuevo; la misma llave con un cuerpo distinto responde 409. Además no actualiza `pisos.pois[]` (array desnormalizado). Exige `AuthGuard` con rol `admin_staff` o `admin_utb` (401 sin token, 403 sin rol). Tras guardar publica `poi.created.v1` (al-menos-una-vez, no duradero; ver [ADR-0009](../adr/0009-mensajeria-asincrona-simulador-en-memoria.md)). |
| 8 | Subir modelo 3D | `SupabaseModel3DStorage.uploadModel` (sin endpoint) | Storage | `upsert: false` (cambiado en esta entrega; antes `true`): **no sobrescribe** una versión publicada | Preserva la inmutabilidad por versión: subir de nuevo la misma versión falla en vez de dejar a los clientes con la v1 en caché sin ver el cambio. Para cambiar un modelo hay que publicar una versión nueva. |
| 9 | Auth: sign-in / sign-up / refresh / sign-out | `AuthController` → Supabase Auth | `auth.users` | **Fuerte**, delegada a Supabase Auth. **Nunca se cachea** | Dependencia total de un tercero (ver ADR-0010). |
| 10 | Cambiar rol de usuario | `POST /api/v1/auth/users/:id/role` | `auth.users.app_metadata` | Fuerte en el servidor; **eventual en el cliente** hasta que se refresque el JWT. El backend relee el rol de Supabase en cada petición protegida (`AuthGuard`), no del token | Un rol revocado sigue vigente en la app hasta que expire el token vigente, pero el backend lo deja de aceptar de inmediato. El rol vive en `app_metadata` porque `user_metadata` lo edita el propio usuario ([ADR-0011](../adr/0011-modelado-de-amenazas-y-mitigaciones.md)). |
| 11 | Ubicación actual / manual | `GET /location/current`, `POST /location/manual` | Ninguno | No aplica (sin persistencia) | `manual` solo devuelve lo recibido. |
| 12 | Caché local del `.glb` (app) | `ModelCache`, `LocalStorage` | Disco + Hive | **Inmutable por versión**; sin TTL; la versión anterior se borra al bajar la nueva | Si la descarga de la versión nueva falla, se conserva la anterior (uso sin red). |
| 13 | Caché local de metadatos (app) | — | — | `LoadBuildingUseCase` guarda el payload del edificio en Hive (`building_meta_<id>`) tras cada carga con red | Con la API caída y copia local, la app responde con la copia y el banner «Offline» (`fromCache`). Cualquier fallo de la API activa la copia, incluidos 404 y 5xx. EC-04 sigue sin medirse en dispositivo. |

## Propiedades transversales

- **Transacciones:** ninguna. Todas las escrituras del backend son de una sola fila.
- **Fallos de BD:** desde esta entrega un fallo real de Postgres se propaga como **503** y nunca se confunde con "no encontrado" ni con una lista vacía (antes los repositorios devolvían `null`/`[]`). Esto es lo que permite cachear con seguridad: ni los errores ni los vacíos entran a la caché.
- **RLS:** el backend usa la *service-role key*, que la omite. La seguridad de acceso depende del backend, no de Postgres.
- **Escalado:** una sola instancia (Render plan free). La caché es local; con más instancias la fila 5–6 pasaría a obsolescencia ≤ TTL entre instancias, sin read-your-writes global (ver [diseno-cache.md](diseno-cache.md#cuándo-pasar-a-redis)).

## Verificación contra la implementación

Dos operaciones contrastadas línea por línea con el código. No se presume consistencia fuerte por usar PostgreSQL.

**Operación 2 — Detalle de edificio (lecturas separadas, sin transacción).**

- `GetBuildingUseCase.execute` (`backend/src/modules/mapas/application/use-cases.ts:62-87`) hace tres pasos independientes: `buildingRepository.findById` (:67), `floorRepository.findByBuildingId` (:77) y `getSignedUrl` (:79-84).
- En Postgres son dos consultas distintas: `edificios` por `id` (`supabase-repositories.ts:50-61`) y `pisos` por `edificio_id` (`supabase-repositories.ts:124-137`). No comparten transacción ni snapshot.
- Garantía real: *read committed* por consulta. Una escritura entre ambas produce una lectura rasgada (edificio viejo con pisos nuevos).
- La prueba `backend/src/modules/mapas/application/get-building.use-case.spec.ts` reproduce esa lectura rasgada y fija la mitigación: la URL firmada se calcula con la versión del edificio leído, no con la de los pisos.

**Operación 7 — Crear POI (una fila atómica, sin idempotencia).**

- `CreatePoiUseCase.execute` (`backend/src/modules/pois/application/use-cases.ts:101-113`) genera el UUID con `crypto.randomUUID()` en cada petición y llama `poiRepository.save`.
- `save` es un único `upsert` sobre `pois` (`supabase-poi-repository.ts:94-111`): atómico por fila (ACID de Postgres), sin transacción que lo agrupe con la invalidación de caché ni con la publicación de `poi.created.v1`.
- Garantía real: atómica por fila; **idempotente solo con `Idempotency-Key`** (sin ella, un reintento tras un timeout crea otro POI). Con llave, la deduplicación la da la clave primaria (id derivado de usuario y llave), así que sobrevive a reinicios; dos peticiones simultáneas con la misma llave guardan una sola fila, pero podrían publicar `poi.created.v1` dos veces (el consumidor deduplica por `eventId`, que aquí es distinto). Y *read-your-writes* solo en la misma instancia, porque la invalidación (`cache.del`, :110-111) es local.
