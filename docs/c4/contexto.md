# C4 Model — El Mapita UTB (Niveles 1 y 2)

> Referencia metodológica: [C4 Model: Documentación Clara y Efectiva para Arquitecturas de Software](https://dev.to/ajcastillo/c4-model-documentacion-clara-y-efectiva-para-arquitecturas-de-software-43od) — Aj Castillo (DEV.to).  
> Trazabilidad: `docs/arc42/arc42-template-EN.md` S3 (Contexto) y S5 (Bloques), `docs/comparativa-de-arquitecturas.md`.

---

## Convenciones

| Nivel | Pregunta clave (artículo) | Interlocutores | Qué muestra |
|-------|---------------------------|----------------|-------------|
| **N1 Contexto** | *¿Dónde encaja este sistema dentro del ecosistema?* | Stakeholders no técnicos, gerencia, soporte | Actores + sistema + sistemas externos |
| **N2 Contenedor** | *¿Cuáles son los contenedores principales? ¿Cómo se comunican? ¿Qué tecnologías?* | Equipos técnicos y gerentes de proyecto | Apps, servicios, BDs y sus protocolos |

Fuentes generativas: **Mermaid C4** (`.md` con `C4Context`/`C4Container`) → render nativo GitHub + export PNG. Solo se conserva PNG como artefacto binario.

---

## Nivel 1 — Diagrama de Contexto del Sistema

Define los límites de **El Mapita UTB**, sus actores humanos y los sistemas externos (Supabase BaaS y plataforma de ubicación del SO). Monolito Modular `NestJS + Flutter` encapsulado como un único `System`.

### Archivos

| Artefacto | Ruta |
|-----------|------|
| Mermaid fuente | [`C4_L1_Context.md`](./C4_L1_Context.md) |
| Render PNG | [`C4_L1_Context.png`](./C4_L1_Context.png) |
| Legacy PNG (pre-existente) | [`C4_Contexto.png`](./C4_Contexto.png) |

### Render estático

![C4 L1 Contexto](./C4_L1_Context.png)

### Diagrama en Mermaid — Texto mínimo, 2 actores, externos debajo de UTB (estilo C4 con notación estándar)

```mermaid
flowchart TB
    classDef person fill:#08427B,stroke:#073B6F,color:#FFFFFF
    classDef system fill:#1168BD,stroke:#3C7FC0,color:#FFFFFF
    classDef ext fill:#999999,stroke:#8A8A8A,color:#FFFFFF

    A["Estudiante / Visitante<br><i>&lt;&lt;Person&gt;&gt;</i>"]:::person
    B["Docente / Admin<br><i>&lt;&lt;Person&gt;&gt;</i>"]:::person

    subgraph UTB ["UTB"]
        C["El Mapita UTB<br>Mapa 3D interactivo<br><i>&lt;&lt;System&gt;&gt;</i><br>Modelos .glb + geolocalizacion"]:::system
    end

    subgraph Externos ["Sistemas Externos"]
        D["Supabase<br>Auth, DB PostGIS, Storage, Realtime<br><i>&lt;&lt;External&gt;&gt;</i>"]:::ext
        E["Ubicacion SO<br>CoreLocation / FusedLocation<br><i>&lt;&lt;External&gt;&gt;</i>"]:::ext
    end

    A -- "Usa<br>HTTPS" --> C
    B -- "Usa / Administra<br>HTTPS/JWT" --> C
    C -- "Consulta datos<br>HTTPS/WSS/PostgREST" --> D
    C -- "Obtiene ubicacion<br>MethodChannels" --> E

    subgraph Leyenda ["Leyenda"]
        direction LR
        L1["Person<br>Usuario"]:::person
        L2["System<br>El Mapita"]:::system
        L3["External<br>Supabase/Ubicacion"]:::ext
    end
```

### Descripción de elementos (Nivel 1)

| Elemento | Tipo |
|----------|------|
| Estudiante / Visitante | Person |
| Docente / Admin | Person |
| El Mapita UTB | System (UTB) |
| Supabase | System_Ext |
| Ubicacion SO | System_Ext |

> Detalle completo de roles y responsabilidades: `C4_L1_Context.md` (mermaid) y `arc42 S3.1/S3.2`.

---

## Nivel 2 — Diagrama de Contenedores

Desglosa **El Mapita UTB** en contenedores desplegables, sus tecnologías y protocolos. Responde a las preguntas del artículo: *contenedores, comunicación y stack por contenedor*. Mantiene la decisión **DEC-01 Monolito Modular**.

### Archivos

| Artefacto | Ruta |
|-----------|------|
| Mermaid fuente | [`C4_L2_Container.md`](./C4_L2_Container.md) |
| Render PNG | [`C4_L2_Container.png`](./C4_L2_Container.png) |

### Render estático

![C4 L2 Contenedores](./C4_L2_Container.png)

### Diagrama en Mermaid (C4Container)

```mermaid
C4Container
    title Diagrama de Contenedores (C4 Nivel 2) - El Mapita UTB

    Person(estudiante, "Estudiante / Visitante", "Navega mapa 3D público")
    Person(docente, "Docente / Admin UTB", "Usuario autenticado")

    System_Boundary(c1, "El Mapita UTB") {
        Container(mobileApp, "App Móvil Flutter", "Dart, Flutter 3.19, BLoC, get_it, Dio, Hive, SecureStorage", "Renderiza .glb Draco, gestiona pisos/POIs, geoloc accuracy≤15m + fallback 10s→2s (EC-03), caché Hive+Filesystem (EC-04).")
        Container(backendApi, "Backend API", "NestJS 11, TypeScript, Swagger/OpenAPI, Joi, Docker Node18+", "Monolito Modular: módulos mapas/ubicación/auth/pois, valida versiones modelos, expone REST /api/*, RBAC JWT.")
        ContainerDb(localCacheMeta, "Caché Local Metadatos", "Hive (key-value Dart)", "Edificios/pisos/POIs + versiones semver. Offline <5s EC-04.")
        ContainerDb(localCacheModels, "Caché Local Modelos 3D", "Filesystem (path_provider)", "Binarios .glb por edificio/piso indexados por versionModelo3D.")
    }

    System_Boundary(supabase, "Supabase Cloud (BaaS)") {
        Container(supabaseAuth, "Supabase Auth", "GoTrue, JWT", "Roles: estudiante/visitante/docente/admin_staff/admin_utb.")
        ContainerDb(supabaseDb, "Supabase DB", "PostgreSQL 15 + PostGIS", "Edificios Polygon, Pisos, POIs Point, versiones.")
        Container(supabaseStorage, "Supabase Storage", "S3-compatible bucket modelos-3d", "Almacena .glb/.gltf, entrega URLs firmadas.")
        Container(supabaseRealtime, "Supabase Realtime", "WSS Pub/Sub", "Notifica cambios POIs e invalidación versiones.")
    }

    System_Ext(osLocation, "Plataforma Ubicación SO", "iOS CoreLocation / Android FusedLocation", "Sensores lat/long + accuracy (m)")

    Rel(estudiante, mobileApp, "Usa", "UI Táctil, EC-02 ≥30fps")
    Rel(docente, mobileApp, "Usa autenticado", "HTTPS Bearer JWT")
    Rel(mobileApp, backendApi, "Consulta edificios/pisos/POIs + health", "HTTPS/JSON REST GET /api/mapas/*")
    Rel(mobileApp, backendApi, "Auth login/refresh", "HTTPS POST /api/auth/*")
    Rel(mobileApp, supabaseStorage, "Descarga .glb vía URL firmada del Backend", "HTTPS S3 signed URL")
    Rel(mobileApp, supabaseRealtime, "Suscribe canal POIs", "WSS")
    Rel(mobileApp, osLocation, "Permisos + watchLocation", "MethodChannels geolocator")
    Rel(mobileApp, localCacheMeta, "Lee/escribe", "Hive")
    Rel(mobileApp, localCacheModels, "Lee/escribe", "Filesystem")
    Rel(backendApi, supabaseAuth, "Valida JWT/roles", "HTTPS REST")
    Rel(backendApi, supabaseDb, "CRUD geoespacial", "PG Wire / PostgREST")
    Rel(backendApi, supabaseStorage, "Genera URLs firmadas / upload admin", "S3 API")
```

### Tabla de contenedores

| Contenedor | Tipo | Stack | Responsabilidad | EC / RES |
|------------|------|-------|-----------------|----------|
| **App Móvil Flutter** | Container (cliente) | Flutter, BLoC, Dio, get_it, Hive, SecureStorage, geolocator | `features/mapas` (MapasBloc, ModelCache), `features/ubicacion` (UbicacionBloc, LocationService) | EC-01/02/03/04, RES-02/03 |
| **Backend API** | Container (servidor) | NestJS, TypeScript, Swagger, Joi, `shared/kernel/errors/config/supabase` | `modules/mapas/pois/auth/ubicacion` (domain/application/infrastructure/interfaces), `HealthController /health` | S4 tácticas |
| **Caché Local Metadatos** | ContainerDb | Hive | POIs/edificios/pisos versionados | EC-04 (<5s offline) |
| **Caché Local Modelos 3D** | ContainerDb | Filesystem | `.glb` Draco por `versionModelo3D` | EC-01 (<5s p95) |
| **Supabase Auth** | Container (externo) | GoTrue | JWT, roles `estudiante/visitante/docente/admin_staff/admin_utb` | S3.2 Media |
| **Supabase DB** | ContainerDb (externo) | PostgreSQL+PostGIS | `Building {Polygon}`, `Floor`, `Poi {Point}` | S3.2 Alta |
| **Supabase Storage** | Container (externo) | S3 bucket `modelos-3d` | Artefactos 3D firmados | S3.2 Alta |
| **Supabase Realtime** | Container (externo) | WSS | Invalidación caché, cambios POIs | S3.2 Baja/Media |
| **Plataforma Ubicación SO** | System_Ext | CoreLocation/FusedLocation | `accuracy`, permisos, stream | RES-02, EC-03 |

### Decisiones visibles en el diagrama

* **DEC-01 Monolito Modular** — un solo deploy backend + un solo binary móvil; fronteras por feature (`modules/*`, `features/*`), `shared kernel` mínimo (`backend/src/shared:15`, `frontend/lib/core:12`).
* **DEC-02 Desacoplo Supabase** — SDK solo en `infrastructure/adapters`; dominio usa `BuildingRepository/FloorRepository/PoiRepository/LocationProvider` (fakes en tests EC-03).
* **DEC-04 Caché 2 niveles** — Hive + Filesystem versionados, recuperación offline directa desde `mobileApp` sin pasar por `backendApi` cuando `DioClient` falla.

---

## Cómo regenerar los diagramas

Los diagramas fuente son **Mermaid** (`.md`). El PNG se genera exportando el bloque `C4Context`/`C4Container` con cualquier renderer Mermaid (ej. [Mermaid Live Editor](https://mermaid.live), `mermaid-cli` o `Kroki`):

```bash
# Opción A — mermaid-cli (recomendado, solo PNG)
npx -y @mermaid-js/mermaid-cli -i docs/c4/C4_L1_Context.md -o docs/c4/C4_L1_Context.png
npx -y @mermaid-js/mermaid-cli -i docs/c4/C4_L2_Container.md -o docs/c4/C4_L2_Container.png

# Opción B — Kroki (sin instalación)
curl -X POST https://kroki.io/mermaid/png --data-binary @docs/c4/C4_L1_Context.md -H "Content-Type: text/plain" -o docs/c4/C4_L1_Context.png
```

---

## Trazabilidad

* **Contexto de negocio** `arc42 S3.1` → actores del Nivel 1.
* **Contexto técnico** `arc42 S3.2` → sistemas externos y criticidad.
* **Bloques Nivel 1** `arc42 S5.1` y **S5.2** → mapeo directo a contenedores del Nivel 2.
* **Escenarios** `arc42 S6.1/6.2/6.3` → flujos que atraviesan `mobileApp ↔ backendApi ↔ Supabase* ↔ localCache* ↔ osLocation`.
