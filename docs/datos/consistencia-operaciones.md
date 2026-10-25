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
| 7 | **Crear POI** | `POST /api/v1/pois` · `CreatePoiUseCase` → `save` (upsert) | `pois` | **Atómica por fila (ACID de Postgres)**; **no idempotente** | El UUID lo genera el servidor en cada petición: reintentar tras un timeout duplica el POI. No hay llave de idempotencia. Además no actualiza `pisos.pois[]` (array desnormalizado). Sin guard de rol pese a ser "admin" en Swagger. Tras guardar publica `poi.created.v1` (al-menos-una-vez, no duradero; ver [ADR-0009](../adr/0009-mensajeria-asincrona-simulador-en-memoria.md)). |
| 8 | Subir modelo 3D | `SupabaseModel3DStorage.uploadModel` (sin endpoint) | Storage | `upsert: false` (cambiado en esta entrega; antes `true`): **no sobrescribe** una versión publicada | Preserva la inmutabilidad por versión: subir de nuevo la misma versión falla en vez de dejar a los clientes con la v1 en caché sin ver el cambio. Para cambiar un modelo hay que publicar una versión nueva. |
| 9 | Auth: sign-in / sign-up / refresh / sign-out | `AuthController` → Supabase Auth | `auth.users` | **Fuerte**, delegada a Supabase Auth. **Nunca se cachea** | Dependencia total de un tercero (ver ADR-0010). |
| 10 | Cambiar rol de usuario | `POST /api/v1/auth/users/:id/role` | `auth.users.user_metadata` | Fuerte en el servidor; **eventual en el cliente** hasta que se refresque el JWT | Un rol revocado sigue vigente hasta que expire el token vigente. |
| 11 | Ubicación actual / manual | `GET /location/current`, `POST /location/manual` | Ninguno | No aplica (sin persistencia) | `manual` solo devuelve lo recibido. |
| 12 | Caché local del `.glb` (app) | `ModelCache`, `LocalStorage` | Disco + Hive | **Inmutable por versión**; sin TTL; la versión anterior se borra al bajar la nueva | Si la descarga de la versión nueva falla, se conserva la anterior (uso sin red). |
| 13 | Caché local de metadatos (app) | — | — | **No existe**: `LoadBuildingUseCase` consulta la API primero | Sin red, la app cae en `MapasError` (EC-04, 0/20). Es trabajo siguiente. |

## Propiedades transversales

- **Transacciones:** ninguna. Todas las escrituras del backend son de una sola fila.
- **Fallos de BD:** desde esta entrega un fallo real de Postgres se propaga como **503** y nunca se confunde con "no encontrado" ni con una lista vacía (antes los repositorios devolvían `null`/`[]`). Esto es lo que permite cachear con seguridad: ni los errores ni los vacíos entran a la caché.
- **RLS:** el backend usa la *service-role key*, que la omite. La seguridad de acceso depende del backend, no de Postgres.
- **Escalado:** una sola instancia (Render plan free). La caché es local; con más instancias la fila 5–6 pasaría a obsolescencia ≤ TTL entre instancias, sin read-your-writes global (ver [diseno-cache.md](diseno-cache.md#cuándo-pasar-a-redis)).
