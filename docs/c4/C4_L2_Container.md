# C4 Nivel 2 — Diagrama de Contenedores — El Mapita UTB

> Referencia: [C4 Model: Documentación Clara y Efectiva](https://dev.to/ajcastillo/c4-model-documentacion-clara-y-efectiva-para-arquitecturas-de-software-43od) — Nivel 2 responde *¿Cuáles son los contenedores principales? ¿Cómo se comunican? ¿Qué tecnologías?* Dirigido a equipos técnicos y gerentes de proyecto.  
> Fuente: `docs/arc42/arc42-template-EN.md` S5.1/S5.2/S7 | Render: [`C4_L2_Container.png`](./C4_L2_Container.png) | Estilo: **DEC-01 Monolito Modular** (NestJS + Flutter)

## Diagrama (Mermaid — C4Container)

```mermaid
C4Container
    title Diagrama de Contenedores (C4 Nivel 2) - El Mapita UTB

    Person(estudiante, "Estudiante / Visitante", "Navega mapa 3D público, usa GPS o fallback manual")
    Person(docente, "Docente / Admin UTB", "Usuario autenticado, consulta/gestiona POIs y modelos 3D")

    System_Boundary(c1, "El Mapita UTB") {
        Container(mobileApp, "App Móvil Flutter", "Dart, Flutter 3.19, BLoC, get_it, Dio, Hive, SecureStorage", "Renderiza .glb Draco, gestiona pisos/POIs, geoloc accuracy≤15m + fallback 10s→2s (EC-03), caché Hive+Filesystem <5s (EC-04).")
        Container(backendApi, "Backend API", "NestJS 11, TypeScript, Swagger/OpenAPI, Joi, Docker Node18+", "Monolito Modular: módulos mapas/ubicación/auth/pois, valida versiones modelos, expone REST /api/*, RBAC JWT.")
        ContainerDb(localCacheMeta, "Caché Local Metadatos", "Hive (key-value Dart)", "Edificios/pisos/POIs + versiones semver. Offline <5s EC-04.")
        ContainerDb(localCacheModels, "Caché Local Modelos 3D", "Filesystem (path_provider)", "Binarios .glb por edificio/piso indexados por versionModelo3D. EC-01 <5s p95.")
    }

    System_Boundary(supabase, "Supabase Cloud (BaaS Gestionado)") {
        Container(supabaseAuth, "Supabase Auth", "GoTrue, JWT", "Roles: estudiante/visitante/docente/admin_staff/admin_utb.")
        ContainerDb(supabaseDb, "Supabase DB", "PostgreSQL 15 + PostGIS", "Edificios Polygon, Pisos, POIs Point, versiones modelos.")
        Container(supabaseStorage, "Supabase Storage", "S3-compatible bucket modelos-3d", ".glb/.gltf por edificio/versión, URLs firmadas.")
        Container(supabaseRealtime, "Supabase Realtime", "WSS Pub/Sub", "Notifica cambios POIs e invalidación versiones.")
    }

    System_Ext(osLocation, "Plataforma Ubicación SO", "iOS CoreLocation / Android FusedLocation (Geolocator)", "Sensores lat/long + accuracy (m), permisos. RES-02.")

    Rel(estudiante, mobileApp, "Usa", "UI Táctil, EC-02 ≥30fps")
    Rel(docente, mobileApp, "Usa autenticado", "HTTPS Bearer JWT")
    Rel(mobileApp, backendApi, "Consulta edificios/pisos/POIs, health, versiones", "HTTPS/JSON REST GET /api/mapas/* /api/pois/*")
    Rel(mobileApp, backendApi, "Login/registro/refresh", "HTTPS/JSON POST /api/auth/*")
    Rel(mobileApp, supabaseStorage, "Descarga .glb vía URL firmada obtenida del Backend", "HTTPS S3 signed URL")
    Rel(mobileApp, supabaseAuth, "Auth directa opcional (SDK Flutter)", "HTTPS")
    Rel(mobileApp, supabaseRealtime, "Suscribe canal puntos_interes", "WSS Pub/Sub")
    Rel(mobileApp, osLocation, "requestPermission / getCurrentLocation / watch", "MethodChannels geolocator")
    Rel(mobileApp, localCacheMeta, "Lee/escribe", "Hive boxes")
    Rel(mobileApp, localCacheModels, "Lee/escribe", "Filesystem I/O")
    Rel(backendApi, supabaseAuth, "Valida JWT, gestiona roles", "HTTPS REST")
    Rel(backendApi, supabaseDb, "CRUD edificios/pisos/POIs geoespaciales", "PG Wire / PostgREST RLS")
    Rel(backendApi, supabaseStorage, "Genera URLs firmadas, upload modelos (admin)", "HTTPS S3 API")
    Rel(backendApi, supabaseRealtime, "Publica eventos cambios", "WSS")
    Rel(backendApi, mobileApp, "Responde DTOs tipados", "HTTPS/JSON OpenAPI 3.0")
```

## Contenedores

| Contenedor | Tipo | Stack | Responsabilidad | EC / RES |
|------------|------|-------|-----------------|----------|
| App Móvil Flutter | Container (cliente) | Flutter 3.19, BLoC, Dio, get_it, Hive, SecureStorage, geolocator | `features/mapas` (MapasBloc, ModelCache), `features/ubicacion` (UbicacionBloc) | EC-01/02/03/04, RES-02/03 |
| Backend API | Container (servidor) | NestJS 11, Swagger, Joi, Docker | `modules/mapas/pois/auth/ubicacion` + `HealthController /health` + `shared/kernel` | S4 tácticas |
| Caché Local Metadatos | ContainerDb | Hive | POIs/edificios/pisos versionados semver | EC-04 <5s offline |
| Caché Local Modelos 3D | ContainerDb | Filesystem | `.glb` Draco por `versionModelo3D` | EC-01 <5s p95 |
| Supabase Auth | Container (externo) | GoTrue | JWT, roles `estudiante/visitante/docente/admin_staff/admin_utb` | S3.2 Media |
| Supabase DB | ContainerDb (externo) | PostgreSQL 15 + PostGIS | Building Polygon, Floor, Poi Point | S3.2 Alta |
| Supabase Storage | Container (externo) | S3 bucket `modelos-3d` | Artefactos 3D firmados | S3.2 Alta |
| Supabase Realtime | Container (externo) | WSS | Invalidación caché, cambios POIs | S3.2 Baja/Media |
| Plataforma Ubicación SO | System_Ext | CoreLocation/FusedLocation | accuracy, permisos, stream | RES-02, EC-03 |

## Decisiones visibles

* **DEC-01 Monolito Modular** — un deploy backend + un binary móvil; fronteras por feature.
* **DEC-02 Desacoplo Supabase** — SDK solo en `infrastructure/adapters`; dominio con `Repository` fakes.
* **DEC-04 Caché 2 niveles** — Hive + Filesystem versionados, recuperación offline sin backend.
