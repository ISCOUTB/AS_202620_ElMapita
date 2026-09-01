---
date: Agosto de 2026
title: "Arquitectura de El Mapita UTB"
---

# Arquitectura de El Mapita UTB

**About arc42**

arc42, the template for documentation of software and system architecture.
Template Version 9.0-EN. (based upon AsciiDoc version), July 2025.
Created, maintained and © by Dr. Peter Hruschka, Dr. Gernot Starke and contributors. See <https://arc42.org>.

---

<a id="section-introduction-and-goals"></a>
# 1. Introducción y objetivos

## 1.1 Resumen de requisitos

El Mapita UTB es una aplicación móvil que ayuda a estudiantes, visitantes y personal a orientarse dentro del campus de la Universidad Tecnológica de Bolívar (UTB). El sistema presenta edificios y pisos mediante un mapa 3D interactivo, permite localizar puntos de interés —salones, laboratorios, baños, cafeterías, bibliotecas, escaleras y ascensores— y muestra la ubicación estimada del usuario o un punto de partida seleccionado manualmente.

El primer corte vertical del producto es el aspecto **A-01: visualización del mapa 3D y ubicación del usuario**, asociado con el requisito funcional **RF-01**. Este aspecto incluye la carga del modelo, su navegación táctil, el cambio de piso, la consulta de puntos de interés y el tratamiento explícito de la incertidumbre de la ubicación en interiores.

El alcance inicial no promete navegación interior de precisión centimétrica ni rutas paso a paso. Cuando la señal de ubicación no sea suficiente, el sistema debe comunicarlo y permitir que el usuario establezca manualmente su posición.

## 1.2 Objetivos de calidad

| Prioridad | Objetivo de calidad | Criterio de éxito |
|---|---|---|
| 1 | **Usabilidad y confiabilidad de la orientación** | El usuario distingue su ubicación estimada, conoce el nivel de precisión y dispone de selección manual cuando la señal no es confiable. |
| 2 | **Rendimiento de la experiencia 3D** | Los mapas cargan dentro del umbral acordado y las interacciones de rotación, zoom y cambio de piso se mantienen fluidas en el dispositivo de referencia. |
| 3 | **Disponibilidad ante conectividad variable** | Un mapa consultado previamente continúa disponible para orientación básica cuando la red es intermitente o está ausente. |
| 4 | **Privacidad de la ubicación** | La ubicación se usa únicamente para orientar al usuario y no se conserva como historial por defecto en el servidor. |

Las medidas verificables y su priorización por impacto y riesgo se encuentran en la [sección 10](#section-quality-scenarios).

## 1.3 Interesados

| Interesado | Responsabilidad o relación | Preocupaciones y expectativas |
|---|---|---|
| Estudiante de nuevo ingreso | Usuario principal | Encontrar destinos rápidamente, comprender el mapa y no perderse entre edificios o pisos. |
| Visitante o padre de familia | Usuario ocasional | Usar la aplicación sin conocer previamente el campus ni requerir capacitación. |
| Personal docente y administrativo | Usuario recurrente | Consultar ubicaciones confiables y cambios recientes en espacios del campus. |
| Dirección de Tecnología de la UTB | Stakeholder / Sponsor | Adopción de la solución, bajo costo operativo y facilidad de mantenimiento de la cartografía. |
| Equipo de desarrollo | Construcción y evolución | Requisitos verificables, límites claros entre componentes y decisiones trazables. |

---

<a id="section-architecture-constraints"></a>
# 2. Restricciones de arquitectura

Las siguientes condiciones reducen el espacio de solución y provienen de fuentes externas al diseño.

| ID | Tipo y origen | Restricción | Justificación y consecuencia arquitectónica |
|---|---|---|---|
| RES-01 | Académica — consigna de la asignatura | La arquitectura debe documentarse con arc42, C4, ADR y trazabilidad desde los aspectos hasta evidencia automatizada. | Es un formato de entrega impuesto. La documentación y los identificadores deben permanecer enlazables desde el repositorio. |
| RES-02 | Física y tecnológica — dispositivos móviles | La ubicación depende de los sensores y permisos del dispositivo; el GPS se degrada severamente en interiores y entre edificios. | No se puede garantizar precisión interior solo con GPS. La interfaz debe mostrar incertidumbre y ofrecer selección manual, sin presentar una estimación imprecisa como posición exacta. |
| RES-03 | Operacional — campus y red móvil | La conectividad, latencia y capacidad de los teléfonos de los usuarios son variables en distintos puntos del campus. | Los modelos 3D deben optimizarse y almacenarse en caché local; los fallos de red deben producir estados comprensibles y no bloquear la orientación básica ya descargada. |

---

<a id="section-context-and-scope"></a>
<a id="section-context-and-boundaries"></a>
# 3. Contexto y alcance

## 3.1 Contexto de negocio — Actores e Interacciones

El límite del sistema comprende la aplicación móvil, la API backend de El Mapita y la lógica necesaria para consultar, preparar y presentar mapas, pisos, modelos 3D y puntos de interés. Supabase y los servicios de ubicación del dispositivo se consideran sistemas externos porque pueden evolucionar o fallar de manera independiente.

| Actor | Rol | Interacciones principales con El Mapita | Permisos / Accesos |
|---|---|---|---|
| **Estudiante de nuevo ingreso** | Usuario principal | Buscar salones, laboratorios, baños, cafeterías, bibliotecas; ver ubicación en tiempo real; navegar entre pisos; seleccionar punto de partida manual. | Acceso completo a mapas 3D y POIs públicos; ubicación opcional (consentimiento). |
| **Visitante / Padre de familia** | Usuario ocasional | Consultar mapa del campus; localizar edificio de evento o reunión; orientación básica sin cuenta. | Acceso de solo lectura a mapas públicos; sin autenticación requerida. |
| **Personal docente y administrativo** | Usuario recurrente | Consultar ubicación de salones asignados; verificar cambios de aula; acceso a información actualizada de espacios. | Acceso a mapas y datos de asignación de espacios (vía Supabase Auth). |
| **Dirección de Tecnología (UTB)** | Stakeholder / Admin | Supervisar uso de la app; actualizar mapas, versiones de modelos 3D y catálogo de POIs. | Acceso de administración y gestión de contenidos. |

## 3.2 Contexto técnico — Sistemas Externos y Dependencias

| Sistema Externo | Tipo | Qué provee a El Mapita | Protocolo / Interfaz | Criticidad |
|---|---|---|---|---|
| **Supabase Auth** | IAM / Autenticación | Identidad de usuarios (JWT), roles (estudiante, docente, admin), control de acceso. | HTTPS / REST | **Media** — Mapas públicos funcionan sin login; requerida para roles. |
| **Supabase Database (PostgreSQL + PostGIS)** | Persistencia geoespacial | Fuente de verdad de edificios, pisos, POIs, geometrías espaciales y versiones de modelos. | PostgreSQL Wire / PostgREST | **Alta** — Almacén principal de datos estructurados. |
| **Supabase Storage** | Almacenamiento de objetos | Archivos `.glb`/`.gltf` de modelos 3D por edificio/piso, texturas e imágenes de POIs. | HTTPS / S3-compatible API | **Alta** — Repositorio de artefactos 3D para descarga. |
| **Supabase Realtime** | Mensajería Pub/Sub | Notificaciones en tiempo real sobre cambios de POIs o invalidación de versiones de modelos. | WebSocket (WSS) | **Baja/Media** — Mejora reactividad; el sistema opera con polling/caché. |
| **Plataforma de ubicación del SO (CoreLocation / FusedLocation)** | Sensores nativos | Coordenadas lat/long, precisión estimada (radio horizontal en metros) y estado de permisos. | API Nativa (MethodChannels en Flutter) | **Alta** — Esencial para posicionamiento en tiempo real. |

### 3.3 Esquemas de Datos Clave

```json
// Edificio (Building)
{
  "id": "uuid",
  "nombre": "string",
  "codigo": "string",
  "geometria": "Polygon (PostGIS)",
  "pisos": ["PisoRef"],
  "versionModelo3D": "string (semver)",
  "actualizadoEn": "timestamp"
}

// Piso (Floor)
{
  "id": "uuid",
  "edificioId": "uuid",
  "numero": "integer",
  "nombre": "string",
  "modelo3DUrl": "string (URL firmada Supabase Storage)",
  "modelo3DVersion": "string",
  "alturaMetros": "number",
  "pois": ["PoiRef"]
}

// Punto de Interés (POI)
{
  "id": "uuid",
  "pisoId": "uuid",
  "tipo": "enum: salon | laboratorio | bano | cafeteria | biblioteca | escalera | ascensor | otro",
  "nombre": "string",
  "geometria": "Point (PostGIS) / x,y,z en espacio 3D",
  "metadatos": "jsonb (capacidad, horario, accesibilidad)"
}

// Ubicación de Usuario (UserLocation — procesada en memoria cliente)
{
  "latitud": "number",
  "longitud": "number",
  "precisionMetros": "number",
  "pisoEstimado": "integer?",
  "fuente": "enum: gps | wifi | ble | manual",
  "timestamp": "ISO8601",
  "incertidumbreMostrada": "boolean"
}
```

## 3.4 Diagramas C4 (Nivel 1 — Contexto y Nivel 2 — Contenedor)

Los diagramas C4 definen formalmente las fronteras del sistema, sus actores humanos, contenedores y conexiones con plataformas externas. Siguen el modelo [C4 de Aj Castillo](https://dev.to/ajcastillo/c4-model-documentacion-clara-y-efectiva-para-arquitecturas-de-software-43od) (Contexto = *¿Dónde encaja el sistema?* — stakeholders no técnicos; Contenedor = *¿Qué contenedores, cómo se comunican y con qué tecnología?* — equipos técnicos).

| Nivel | Diagrama | Fuente Mermaid | Render | Descripción |
|-------|----------|----------------|--------|-------------|
| **N1 Contexto** | ![C4 L1 Contexto](../c4/C4_L1_Context.png) | [`C4_L1_Context.md`](../c4/C4_L1_Context.md) | `docs/c4/C4_L1_Context.png` | Actores (Estudiante/Visitante, Docente/Admin, Dirección TI) + Sistema El Mapita UTB + Sistemas externos (Supabase BaaS, Plataforma Ubicación SO). Legacy: [`C4_Contexto.png`](../c4/C4_Contexto.png). |
| **N2 Contenedor** | ![C4 L2 Contenedor](../c4/C4_L2_Container.png) | [`C4_L2_Container.md`](../c4/C4_L2_Container.md) | `docs/c4/C4_L2_Container.png` | Desglose en contenedores: App Móvil Flutter (Hive + Filesystem), Backend API NestJS, Supabase (Auth/DB PostGIS/Storage/Realtime), Plataforma Ubicación SO. Detalle completo en [`docs/c4/contexto.md`](../c4/contexto.md). |

---

<a id="section-solution-strategy"></a>
# 4. Estrategia de solución

Para satisfacer los requisitos funcionales y los escenarios de calidad (EC-01 a EC-04) bajo las restricciones dadas, se adoptan las siguientes decisiones y tácticas fundamentales:

```text
Estrategia de Solución
├── Estilo Arquitectónico: Monolito Modular (NestJS + Flutter)
├── Desacoplamiento de Supabase mediante Patrón Adapter / Repository
├── Gestión de Renderizado 3D: Carga por piso + Caché local binaria en disco
├── Confiabilidad de Ubicación: Filtro de precisión (≤ 15 m) + Degradación a Fallback manual
├── Resiliencia sin Conexión: Caché versionada en dos niveles (Hive + Filesystem)
└── Contratos Estrictos: Especificación OpenAPI / Swagger tipada en Dart
```

### 4.1 Decisiones estratégicas y justificación

1. **Adopción de Monolito Modular en Backend y Frontend:**
   - **Justificación:** Un equipo de 3 desarrolladores requiere baja sobrecarga operativa y alta velocidad de desarrollo, pero con aislamiento suficiente para que la lógica de renderizado 3D y cálculo de coordenadas no se acople a frameworks o drivers de BD.
   - **Táctica:** División del sistema en módulos por característica (`mapas`, `ubicacion`, `auth`, `pois`), cada uno estructurado internamente en capas (`domain`, `application`, `infrastructure`, `presentation`/`interfaces`).

2. **Desacoplamiento del Backend-as-a-Service (Supabase):**
   - **Justificación:** Prevenir el vendor lock-in y permitir pruebas unitarias rápidas y deterministas en CI sin necesidad de instanciar un emulador de Supabase.
   - **Táctica:** El cliente SDK de Supabase reside exclusivamente en adaptadores de infraestructura (`infrastructure/persistence/` y `infrastructure/storage/`). La capa de dominio define interfaces/puertos puros (e.g. `PoiRepository`, `MapModelLoader`, `LocationProvider`).

3. **Estrategia de Carga y Renderizado 3D (Cumplimiento de EC-01 y EC-02):**
   - **Justificación:** Los modelos 3D pesados saturan la memoria y degradan la tasa de cuadros por segundo en teléfonos de gama media.
   - **Táctica:** Modelos optimizados en formato `.glb` comprimido con Draco, segmentados por edificio y piso. Descarga progresiva y renderizado lazy. Carga inicial optimizada para alcanzar el primer frame interactivo en menos de 5 segundos (p95) manteniendo ≥ 30 FPS continuos.

4. **Tratamiento de Incertidumbre de Ubicación y Fallback Manual (Cumplimiento de EC-03):**
   - **Justificación:** En interiores y zonas densas del campus, el GPS pierde precisión y confunde al usuario si se presenta como certeza.
   - **Táctica:** Se procesa la señal de ubicación evaluando su radio de incertidumbre horizontal (`accuracy`). Solo se acepta lectura automática si `accuracy ≤ 15 m`. Si tras un temporizador de 10 segundos no se obtiene señal adecuada o el usuario rechaza permisos, el sistema conmuta automáticamente en ≤ 2 segundos a un modo de selección manual de punto de partida (edificio, piso o toque en el mapa).

5. **Estrategia de Resiliencia Fuera de Línea (Cumplimiento de EC-04):**
   - **Justificación:** La conectividad móvil en el campus puede ser intermitente.
   - **Táctica:** Implementación de caché local versionada en dos niveles en el cliente móvil: metadatos y POIs en cajas locales (`Hive`), y archivos binarios `.glb` en el almacenamiento local del dispositivo (`ModelCache`). Permite visualización y navegación de edificios previamente visitados en < 5 segundos sin conexión activa.

6. **Contratos e Integración:**
   - **Táctica:** El backend en NestJS expone endpoints REST documentados vía OpenAPI (`@nestjs/swagger`). El frontend consume estos contratos mediante clientes tipados (`DioClient`), garantizando sincronía en los DTOs y detección temprana de cambios incompatibles.

---

<a id="section-building-block-view"></a>
# 5. Vista de bloques de construcción

La arquitectura de El Mapita UTB se organiza como un **Monolito Modular** tanto en el backend como en el frontend, garantizando límites claros entre dominios y alta cohesión interna.

## 5.1 Nivel 1: Vista de caja blanca del sistema global

```text
+-----------------------------------------------------------------------------------+
|                              EL MAPITA UTB (Sistema)                             |
|                                                                                   |
|  +-----------------------------------+     HTTPS/JSON     +--------------------+  |
|  |       Frontend Móvil              | <----------------> |    Backend API     |  |
|  |       (Flutter App)               |                    |    (NestJS API)    |  |
|  +-----------------------------------+                    +--------------------+  |
|          |                 |                                         |            |
|          | MethodChannels  | WSS / HTTPS                             | PG / HTTPS |
|          v                 v                                         v            |
+----------|-----------------|-----------------------------------------|------------+
           |                 |                                         |
           v                 v                                         v
+--------------------+ +------------------------------------------------------------+
| Plataforma del SO  | |                     BaaS Supabase                          |
| (GPS / Ubicación)  | |   [Supabase Auth] [PostgreSQL/PostGIS] [Storage] [Realtime]|
+--------------------+ +------------------------------------------------------------+
```

### Bloques de construcción de Nivel 1

| Bloque | Tipo | Responsabilidad principal |
|---|---|---|
| **Frontend Móvil (Flutter App)** | Aplicación cliente | Renderizado interactivo del mapa 3D, gestión de la interfaz de usuario, lectura de sensores de geolocalización, almacenamiento en caché local y soporte de navegación offline. |
| **Backend API (NestJS API)** | Monolito modular de servicios | Reglas de negocio del campus, orquestación de metadatos de edificios/pisos/POIs, validación de versiones de modelos 3D, agregación y seguridad de acceso. |
| **BaaS Supabase (Externo)** | Proveedor de infraestructura | Persistencia relacional y espacial (PostGIS), autenticación de usuarios (Auth JWT), almacenamiento de binarios 3D (Storage) y canal de eventos (Realtime). |
| **Plataforma del SO (Externo)** | Servicio nativo del dispositivo | Provisión de lecturas de hardware GPS, WiFi throttling y estado de permisos vía iOS CoreLocation o Android FusedLocation. |

### Interfaces de Nivel 1

| Interfaz | Origen / Destino | Protocolo | Descripción |
|---|---|---|---|
| **IF-01: API REST El Mapita** | Frontend → Backend | HTTPS / JSON | Consulta de edificios, pisos, versiones de modelos, catálogo de POIs y health check. |
| **IF-02: Supabase Storage API** | Frontend/Backend → Supabase | HTTPS | Descarga directa de modelos `.glb` vía URLs firmadas seguras. |
| **IF-03: Supabase Database** | Backend → Supabase PostGIS | PostgreSQL Wire / REST | Consultas espaciales y persistencia de catálogos y relaciones. |
| **IF-04: OS Location Channel** | Frontend → Plataforma SO | Dart MethodChannels | Obtención de coordenadas y precisión horizontal del hardware. |
| **IF-05: Realtime Stream** | Frontend/Backend → Supabase | WebSocket (WSS) | Suscripción a eventos de invalidación de caché y cambios de estado en POIs. |

---

## 5.2 Nivel 2: Descomposición de Subsistemas

### 5.2.1 Descomposición del Backend (NestJS)

El backend está organizado en módulos independientes con bajo acoplamiento y un kernel compartido:

```text
backend/src/
├── modules/
│   ├── mapas/               # Edificios, pisos, modelos 3D y versiones
│   │   ├── domain/          # Entidades (Building, Floor), Interfaces de repositorio
│   │   ├── application/     # Casos de uso (GetBuilding, ListFloors, GetModelVersion)
│   │   ├── infrastructure/  # Repositorios Supabase / Storage adapters
│   │   └── interfaces/      # MapasController, DTOs y Swagger specs
│   ├── ubicacion/           # Procesamiento de coordenadas y cálculo de precisión
│   │   ├── domain/          # Coordenadas, Entidad UserLocation
│   │   ├── application/     # ValidateLocationUseCase
│   │   ├── infrastructure/  # Adaptadores geoespaciales
│   │   └── interfaces/      # UbicacionController
│   ├── auth/                # Manejo de roles, sesiones y JWT de Supabase
│   │   ├── domain/          # Usuario, Rol
│   │   ├── application/     # ValidateTokenUseCase, GetProfileUseCase
│   │   ├── infrastructure/  # SupabaseAuthClient
│   │   └── interfaces/      # AuthController, Guards
│   └── pois/                # Catálogo de Puntos de Interés
│       ├── domain/          # Entidad POI, TipoPOI (Salón, Baño, Cafetería, etc.)
│       ├── application/     # ListPoisByFloorUseCase, SearchPoisUseCase
│       ├── infrastructure/  # SupabasePoiRepository
│       └── interfaces/      # PoisController
└── shared/
    ├── kernel/              # Clases base (Entity, ValueObject, Result, UseCase)
    ├── supabase/            # Cliente Supabase singleton (solo consumido por adapters)
    ├── errors/              # AppError, DomainError, InfrastructureError
    └── config/              # ConfigModule con validación Joi de variables de entorno
```

### 5.2.2 Descomposición del Frontend (Flutter)

El frontend sigue una arquitectura orientada a características (*Feature-Driven*) con aislamiento por capas y reactividad basada en BLoC:

```text
frontend/lib/
├── features/
│   ├── mapas/               # Visualización y navegación 3D
│   │   ├── domain/          # Building, Floor, Model3D, MapRepository interface
│   │   ├── application/     # LoadBuildingUseCase, SwitchFloorUseCase
│   │   ├── infrastructure/  # MapasApi, ModelCache (disco), RendererAdapter
│   │   └── presentation/    # MapasBloc, MapPage, FloorSelector, BuildingCard
│   ├── ubicacion/           # Sensor GPS, cálculo de incertidumbre y selección manual
│   │   ├── domain/          # UserLocation, LocationProvider interface, PrecisionLevel
│   │   ├── application/     # GetLocationUseCase, RequestPermissionUseCase
│   │   ├── infrastructure/  # LocationServiceImpl (Geolocator plugin)
│   │   └── presentation/    # UbicacionBloc, LocationPage, LocationButton
│   ├── auth/                # Gestión de sesión de usuario
│   │   ├── domain/          # AuthUser, AuthRepository interface
│   │   ├── application/     # SignInUseCase, SignOutUseCase
│   │   ├── infrastructure/  # SupabaseAuthClientAdapter
│   │   └── presentation/    # AuthBloc, LoginPage, RegisterPage
│   └── pois/                # Consulta y filtrado de puntos de interés
│       ├── domain/          # PoiEntity, CategoryEnum
│       ├── application/     # FilterPoisUseCase
│       ├── infrastructure/  # PoisApiClient
│       └── presentation/    # PoiMarker, PoiDetailsSheet
├── core/
│   ├── kernel/              # Result/Either, UseCase base, ValueObject
│   ├── di/                  # Inyector de dependencias (GetIt service locator)
│   ├── network/             # DioClient, interceptores de autenticación y logging
│   ├── storage/             # Hive boxes (metadatos) y SecureStorage (tokens)
│   └── platform/            # PlatformChannels, LocationService, PermissionService
└── shared/
    ├── widgets/             # UI kit común (botones, spinners, dialogs de error)
    ├── theme/               # Paleta de colores UTB, tipografía, temas Claro/Oscuro
    └── extensions/          # Extensiones Dart para context, strings y fechas
```

---

## 5.3 Nivel 3: Detalle de Bloques Críticos (Corte Vertical A-01)

### 5.3.1 Bloque: Módulo de Mapas (Frontend)

- **Propósito:** Descargar, almacenar en caché y gestionar el ciclo de vida del renderizado 3D de los edificios y pisos del campus.
- **Componentes internos:**
  - `MapasBloc`: Maneja los estados `MapLoading`, `MapLoaded`, `FloorChanging`, `MapError` y `MapOfflineMode`.
  - `LoadBuildingUseCase`: Orquesta la obtención de metadatos desde la API o la base de datos local y solicita la descarga o recuperación del modelo `.glb`.
  - `ModelCache`: Verifica la presencia del archivo binario 3D en el sistema de archivos local (`path_provider`) cotejando el hash/versión semántica.
  - `FloorSelector`: Widget interactivo que permite alternar entre pisos disparando eventos `SwitchFloorEvent`.

### 5.3.2 Bloque: Módulo de Ubicación y Fallback Manual

- **Propósito:** Proveer la estimación espacial del usuario en coordenadas del campus, garantizando la degradación transparente ante pérdida o degradación de señal.
- **Componentes internos:**
  - `UbicacionBloc`: Coordina los estados `LocationAcquiring`, `LocationAccurate` (con radio ≤ 15 m), `LocationDegraded` y `LocationManualSelection`.
  - `LocationProvider (Puerto)`: Contrato abstracto que desvincula la lógica de la implementación de `geolocator`.
  - `LocationServiceImpl (Adaptador)`: Implementación concreta que escucha el stream de geolocalización nativo y mapea errores de permiso o timeout.
  - `ManualLocationFallback`: Controlador que permite fijar la posición tocando un punto sobre el modelo 3D o seleccionando un salón de referencia cuando el GPS falla.

---

<a id="section-runtime-view"></a>
# 6. Vista de tiempo de ejecución

A continuación se detallan los escenarios dinámicos principales de interacción entre bloques de construcción, trazables a los requisitos y escenarios de calidad.

## 6.1 Escenario 1: Carga y Renderizado Inicial de un Edificio 3D (EC-01 y EC-02)

Representa el flujo cuando un usuario selecciona un edificio para visualización interactiva.

```text
Usuario            Flutter UI         MapasBloc        ModelCache       Backend API      Supabase Storage
   |                   |                  |                |                 |                  |
   |-- 1. Selecciona ->|                  |                |                 |                  |
   |   Edificio "L"    |-- 2. AddEvent -->|                |                 |                  |
   |                   |   (LoadBuilding) |                |                 |                  |
   |                   |                  |-- 3. GetMeta ->|                 |                  |
   |                   |                  |--------------------------------->|                  |
   |                   |                  |   GET /api/mapas/edificios/L     |                  |
   |                   |                  |<---------------------------------|                  |
   |                   |                  |   Retorna {version, modelUrl}    |                  |
   |                   |                  |                |                 |                  |
   |                   |                  |-- 4. Check --->|                 |                  |
   |                   |                  |   isCached(v)? |                 |                  |
   |                   |                  |<-- Retorna NO -|                 |                  |
   |                   |                  |                |                 |                  |
   |                   |                  |-- 5. Descargar .glb ------------>|                  |
   |                   |                  |      desde Storage signed URL                       |
   |                   |                  |<----------------------------------------------------|
   |                   |                  |   Retorna binario .glb           |                  |
   |                   |                  |                |                 |                  |
   |                   |                  |-- 6. Guardar ->|                 |                  |
   |                   |                  |   en disco     |                 |                  |
   |                   |                  |                |                 |                  |
   |                   |<-- 7. EmitState -|                |                 |                  |
   |                   |   (MapLoaded 3D) |                |                 |                  |
   |<-- 8. Visualiza --| (≤ 5s p95)       |                |                 |                  |
   |    y navega 30fps |                  |                |                 |                  |
```

1. El usuario selecciona un edificio desde el catálogo de la app.
2. `MapPage` emite `LoadBuildingEvent` a `MapasBloc`.
3. `LoadBuildingUseCase` invoca a la API Backend (`GET /mapas/edificios/:id`) para obtener metadatos actualizados y la URL del modelo 3D.
4. Se consulta `ModelCache` con la versión recibida; si el modelo ya reside localmente, se omite la descarga de red.
5. Si no está en caché, se descarga el archivo binario comprimido `.glb` directamente de Supabase Storage.
6. El archivo se persiste en el almacenamiento local del dispositivo indexado por su versión.
7. Se emite el estado `MapLoaded` con la referencia al modelo y sus puntos de interés.
8. La vista 3D renderiza el primer cuadro interactivo en **< 5 segundos (p95)** y sostiene la fluidez táctil a **≥ 30 FPS (fotogramas ≤ 33.3 ms)** cumpliendo **EC-01** y **EC-02**.

---

## 6.2 Escenario 2: Geolocalización en Tiempo Real y Degradación Controlada (EC-03)

Representa la gestión de la ubicación del usuario y la activación del fallback manual cuando la señal de GPS es imprecisa o inexistente.

```text
Usuario            Flutter UI       UbicacionBloc     LocationService   GPS / OS Platform
   |                   |                  |                  |                  |
   |-- 1. Presiona --->|                  |                  |                  |
   |   "Mi Ubicación"  |-- 2. AddEvent -->|                  |                  |
   |                   |  (TrackLocation) |-- 3. Start ----->|                  |
   |                   |                  |   Stream         |-- 4. Listen ---->|
   |                   |                  |                  |                  |
   |                   |                  |                  |<-- 5. Coord -----|
   |                   |                  |                  |   (acc = 35m)    |
   |                   |                  |<-- 6. Reading ---|                  |
   |                   |                  |   (acc > 15m)    |                  |
   |                   |                  | [Inicia Timer 10s]                  |
   |                   |                  |                  |                  |
   |                   |                  |                  | (No mejora acc)  |
   |                   |                  | [Timeout 10s expira]                |
   |                   |                  |                  |                  |
   |                   |<-- 7. EmitState -|                  |                  |
   |                   | (LocationDegraded|                  |                  |
   |                   |  + EnableManual) |                  |                  |
   |<-- 8. Diálogo ----| (en ≤ 2s post TO)|                  |                  |
   | "Señal baja: fija |                  |                  |                  |
   | tu posición"      |                  |                  |                  |
   |                   |                  |                  |                  |
   |-- 9. Selecciona ->|                  |                  |                  |
   |   Piso 2 / Salón  |-- 10. Manual --->|                  |                  |
   |                   |<-- 11. Updated --|                  |                  |
   |<-- 12. Marcador --|                  |                  |                  |
   |    fijado en 3D   |                  |                  |                  |
```

1. El usuario pulsa el botón flotante de geolocalización.
2. `UbicacionBloc` inicia la lectura del proveedor de sensores nativos.
3. Se evalúa la precisión horizontal devuelta por el sistema operativo.
4. Si la precisión es mayor a 15 metros, la lectura se considera preliminar y se arranca un temporizador de guarda de 10 segundos.
5. Si durante los 10 segundos no se estabiliza una señal con precisión ≤ 15 m (o si el permiso fue denegado):
   - El sistema conmuta automáticamente emitiendo `LocationDegradedState`.
   - En **≤ 2 segundos** tras el timeout, se despliega en pantalla la opción de **Selección Manual de Ubicación**.
6. El usuario pulsa sobre un piso/salón o indica su punto de partida en el mapa 3D.
7. El puntero de usuario se sitúa en la posición manual sin engañar al usuario con falsas lecturas de GPS, satisfaciendo estrictamente **EC-03**.

---

## 6.3 Escenario 3: Consulta en Modo Fuera de Línea con Conectividad Degradada (EC-04)

```text
Usuario            Flutter UI         MapasBloc        DioClient       Local Storage (Hive/Cache)
   |                   |                  |                |                       |
   |-- 1. Abre app --->|                  |                |                       |
   |   sin red         |-- 2. LoadBuilding|                |                       |
   |                   |                  |-- 3. Request ->|                       |
   |                   |                  |   API HTTP     |-- 4. Red no disp. --->|
   |                   |                  |                |<-- SocketException ---|
   |                   |                  |<-- Fail -------|                       |
   |                   |                  |                                        |
   |                   |                  |-- 5. Fallback a caché local ---------->|
   |                   |                  |      Leer metadatos POIs + .glb disco  |
   |                   |                  |<---------------------------------------|
   |                   |                  |      Retorna modelo + POIs cacheados   |
   |                   |                  |                                        |
   |                   |<-- 6. EmitState -|                                        |
   |                   |   (MapLoadedOffline)                                      |
   |<-- 7. Muestra ----| (en < 5s)        |                                        |
   |    Mapa 3D +      |                  |                                        |
   |    Banner "Offline"                  |                                        |
```

1. El usuario intenta abrir un edificio previamente navegado mientras transita por una zona sin cobertura celular o WiFi.
2. La llamada HTTP falla de inmediato por timeout o falta de interfaz de red.
3. `MapasRepository` intercepta el fallo y activa la estrategia de resiliencia local consultando las cajas de `Hive` (metadatos) y el directorio de modelos en disco.
4. Se recupera la escena 3D y se emite el estado `MapLoadedOffline`.
5. La interfaz renderiza el mapa 3D en **menos de 5 segundos**, permitiendo navegación completa entre pisos y búsqueda de POIs almacenados, mostrando un indicador claro de "Modo sin conexión" y satisfaciendo **EC-04**.

---

## 6.4 Escenario 4: Autenticación y Sincronización en Tiempo Real de POIs

1. El usuario con rol administrativo o docente inicia sesión mediante `AuthBloc` contra Supabase Auth.
2. Supabase devuelve un token JWT con los claims y roles del usuario, que se almacena de forma segura en `FlutterSecureStorage`.
3. Las peticiones subsecuentes al backend NestJS adjuntan el token `Bearer JWT` en los encabezados HTTP vía `ApiInterceptors`.
4. El cliente establece una conexión WebSocket persistente hacia Supabase Realtime suscribiéndose al canal de cambios de la tabla `puntos_interes`.
5. Cuando la administración modifica la disponibilidad de un espacio o la ubicación de un POI, el evento llega vía WebSocket al `PoisBloc`, el cual refresca en tiempo de ejecución los marcadores sobre el modelo 3D sin requerir recargar la aplicación.

---

<a id="section-deployment-view"></a>
# 7. Vista de despliegue

La infraestructura de despliegue separa la distribución de la aplicación cliente de la plataforma backend y los servicios BaaS gestionados.

```text
+-----------------------------------------------------------------------------------+
|                           DISPOSITIVOS CLIENTE (MÓVIL)                            |
|                                                                                   |
|  +-----------------------------------------------------------------------------+  |
|  | Dispositivo Android / iOS                                                   |  |
|  | - Flutter Application Binary (.apk / .aab / .ipa)                           |  |
|  | - SQLite / Hive Database (Caché local)                                      |  |
|  | - Filesystem Storage (Modelos .glb)                                         |  |
|  +-----------------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------------+
                               | HTTPS / WSS
                               v
+-----------------------------------------------------------------------------------+
|                            CLOUD / SERVICIOS BACKEND                              |
|                                                                                   |
|  +-------------------------------------+   +-----------------------------------+  |
|  | Servidor de Aplicación (NestJS)     |   | Supabase Cloud (BaaS Gestionado)  |  |
|  | - Contenedor Docker Node.js 18+     |   | - PostgreSQL 15+ con PostGIS      |  |
|  | - Host: Cloud Run / Render / VPS    |   | - Supabase Storage (Bucket 3D)    |  |
|  | - Escalamiento horizontal stateless |   | - Supabase Auth & Realtime Engine |  |
|  +-------------------------------------+   +-----------------------------------+  |
+-----------------------------------------------------------------------------------+
```

---

<a id="section-concepts"></a>
# 8. Conceptos transversales

- **Manejo global de errores:** Excepciones clasificadas en `DomainError` (reglas violadas), `InfrastructureError` (fallo de red/BD) y `PresentationError` (errores de renderizado/UI).
- **Seguridad y Privacidad:** Sin persistencia de historiales de ubicación del usuario en BD; credenciales de servicio Supabase restringidas al backend; cliente móvil usa exclusivamente clave pública anónima o tokens de usuario.
- **Internacionalización y Accesibilidad:** Soporte multilenguaje (español por defecto), textos descriptivos en POIs e indicadores visuales de accesibilidad (rutas con rampas y ascensores).

---

<a id="section-design-decisions"></a>
# 9. Decisiones de arquitectura

Las decisiones técnicas más relevantes tomadas por el equipo se encuentran formalizadas mediante registros ADR (*Architecture Decision Records*).

| ID | Título de la Decisión | Estado | Consecuencias e Impacto Principal | Referencia |
|---|---|---|---|---|
| **DEC-01** | Adopción de **Monolito Modular** en Backend (NestJS) y Frontend (Flutter) | Aceptada | Módulos cohesivos por feature (`mapas`, `ubicacion`, `auth`, `pois`). Facilita onboarding de 3 desarrolladores, división clara de trabajo y testabilidad unitaria sin la complejidad de microservicios. | [ADR-0001](../adr/0001-estilo-arquitectonico-propuesto.md) |
| **DEC-02** | Desacoplamiento del BaaS **Supabase** mediante patrón Repository/Adapter | Aceptada | El SDK de Supabase queda confinado a la capa de infraestructura. La lógica de dominio y aplicación se mantiene agnóstica a la base de datos y se prueba en milisegundos con fakes. | [ADR-0001](../adr/0001-estilo-arquitectonico-propuesto.md) |
| **DEC-03** | Gestión de Estado con **Flutter BLoC** en el Frontend Móvil | Aceptada | Separación estricta entre presentación y lógica de negocio; manejo predecible y reactivo de los estados de carga 3D, sensor de ubicación y transiciones sin conexión. | [ADR-0001](../adr/0001-estilo-arquitectonico-propuesto.md) |
| **DEC-04** | Estrategia de **Caché Local Versionada en Dos Niveles** (Hive + Filesystem) | Aceptada | Cumplimiento del escenario EC-04. Permite apertura de mapas y consulta de POIs en < 5 s sin conexión, utilizando versionamiento semántico para invalidación. | [ADR-0001](../adr/0001-estilo-arquitectonico-propuesto.md) |
| **DEC-05** | Tratamiento de Incertidumbre y **Fallback Manual de Ubicación** | Aceptada | Rechazo de estimaciones GPS con precisión > 15 m; activación de selección manual en ≤ 2 s tras timeout de 10 s para evitar orientar erróneamente al usuario en interiores. | [ADR-0001](../adr/0001-estilo-arquitectonico-propuesto.md) |
| **DEC-06** | Contratos de API tipados mediante **OpenAPI / Swagger** | Aceptada | Backend actúa como única fuente de verdad documental; generación de clientes Dart tipados que previenen inconsistencias en tiempo de compilación. | [ADR-0001](../adr/0001-estilo-arquitectonico-propuesto.md) |

---

<a id="section-quality-scenarios"></a>
# 10. Requisitos de calidad

## 10.1 Árbol de utilidad

La prioridad de cada hoja se expresa como **Impacto de negocio / Riesgo técnico**: Alto (A), Medio (M) o Bajo (B).

```text
Utilidad de El Mapita UTB
├── Rendimiento
│   ├── Tiempo de carga
│   │   └── EC-01: primera vista interactiva < 5 s p95 ........ [A/A]
│   └── Fluidez de interacción
│       └── EC-02: 95 % de fotogramas ≤ 33,3 ms (≥30 FPS) ..... [A/A]
├── Confiabilidad y usabilidad
│   └── Manejo de incertidumbre de ubicación
│       └── EC-03: alternativa manual ante señal insuficiente . [A/A]
└── Disponibilidad
    └── Continuidad con conectividad degradada
        └── EC-04: apertura de contenido local < 5 s .......... [A/M]
```

## 10.2 Escenarios de calidad

<a id="ec-01"></a>
### EC-01 — Carga inicial del mapa 3D

| Parte | Definición |
|---|---|
| Atributo | Rendimiento |
| Fuente | Usuario de la aplicación móvil |
| Estímulo | Selecciona un edificio cuyo modelo aún no está en la memoria de la aplicación. |
| Artefacto | Aplicación móvil, API, metadatos y modelo 3D del edificio |
| Entorno | Dispositivo de referencia de gama media, aplicación recién iniciada y red estable de al menos 10 Mbps |
| Respuesta | El sistema obtiene la versión vigente, descarga o recupera el modelo, lo procesa y muestra una primera vista interactiva. |
| Medida | En una prueba de 30 cargas, el tiempo desde la selección hasta la primera vista interactiva es **< 5 segundos en p95**; se registran dispositivo, tamaño del modelo, red y versión. |
| Prioridad | Impacto A / Riesgo A |
| Evidencia prevista | Prueba instrumentada de rendimiento y reporte de percentiles ejecutado en CI o laboratorio reproducible. |

<a id="ec-02"></a>
### EC-02 — Fluidez de interacción con el mapa

| Parte | Definición |
|---|---|
| Atributo | Rendimiento y usabilidad |
| Fuente | Usuario de la aplicación móvil |
| Estímulo | Rota, amplía, desplaza el mapa o cambia de piso. |
| Artefacto | Renderizador y escena 3D cargada |
| Entorno | Dispositivo de referencia de gama media, modelo de prueba de mayor complejidad admitida y sesión continua de 60 segundos |
| Respuesta | La vista responde a los gestos, conserva el punto de interés seleccionado y presenta el piso solicitado. |
| Medida | Al menos **95 % de los fotogramas se renderiza en ≤ 33,3 ms** (equivalente a 30 FPS) y ningún cambio de piso tarda más de **500 ms**. |
| Prioridad | Impacto A / Riesgo A |
| Evidencia prevista | Perfil de fotogramas y prueba automatizada o guion reproducible sobre el dispositivo de referencia. |

<a id="ec-03"></a>
### EC-03 — Ubicación y degradación controlada

| Parte | Definición |
|---|---|
| Atributo | Confiabilidad y usabilidad |
| Fuente | Usuario con el servicio de ubicación habilitado |
| Estímulo | Solicita ver su posición dentro del campus. |
| Artefacto | Aplicación móvil y adaptador del servicio de ubicación |
| Entorno | Uso exterior o interior, con precisión variable, posible pérdida de señal y permiso concedido |
| Respuesta | El sistema muestra la posición estimada junto con su precisión. Si no obtiene una lectura aceptable, informa la limitación y habilita la selección manual del punto de partida. |
| Medida | Se acepta la posición automática únicamente cuando la precisión reportada es **≤ 15 m**. Si en **10 segundos** no existe una lectura aceptable, la opción manual aparece en **≤ 2 segundos**, sin mostrar una posición imprecisa como exacta. |
| Prioridad | Impacto A / Riesgo A |
| Evidencia prevista | Pruebas con proveedor de ubicación simulado para precisión aceptable, imprecisa, permiso denegado, timeout y pérdida de señal. |

<a id="ec-04"></a>
### EC-04 — Consulta con conectividad degradada

| Parte | Definición |
|---|---|
| Atributo | Disponibilidad y resiliencia |
| Fuente | Usuario que ya consultó un edificio anteriormente |
| Estímulo | Abre nuevamente el edificio cuando la red está ausente o es intermitente. |
| Artefacto | Aplicación móvil y caché local versionada |
| Entorno | Sin conexión durante la sesión y con una copia válida previamente descargada |
| Respuesta | El sistema presenta el modelo y los puntos de interés almacenados, permite navegación manual e informa que el contenido puede no ser la versión más reciente. |
| Medida | En **100 % de 20 pruebas** con caché válida, la vista utilizable aparece en **< 5 segundos**, no se produce cierre inesperado y el estado sin conexión permanece visible. |
| Prioridad | Impacto A / Riesgo M |
| Evidencia prevista | Prueba de integración que precarga la caché, desactiva la red y valida contenido, tiempo y mensaje de estado. |

---

## 10.3 Matriz de Trazabilidad Arquitectónica

| Escenario | Requisito / Aspecto | Táctica Arquitectónica Aplicada | Bloques Responsables | Verificación |
|---|---|---|---|---|
| **EC-01** | RF-01 / A-01 | Modelos binarios `.glb` comprimidos con Draco + Descarga por pisos + Caché en disco | `backend/modules/mapas`, `frontend/features/mapas/infrastructure/storage/model_cache.dart` | Benchmark p95 en CI / Flutter Driver test |
| **EC-02** | RF-01 / A-01 | Renderizado eficiente en viewport móvil + Reducción de polígonos + Eventos BLoC no bloqueantes | `frontend/features/mapas/presentation/bloc/mapas_bloc.dart`, Renderizador 3D | Flutter Frame Timing Profile |
| **EC-03** | RF-01 / A-01 | Filtro de precisión `accuracy <= 15m` + Timer de guarda de 10s + Máquina de estados de degradación | `frontend/features/ubicacion`, `LocationServiceImpl`, `UbicacionBloc` | Unit tests con `FakeLocationProvider` |
| **EC-04** | RF-01 / A-01 | Almacenamiento local en dos niveles (`Hive` para DTOs + File cache para 3D) con versionado | `frontend/core/storage`, `ModelCache`, `MapasRepository` | Test de integración offline con mock de red |

---

## 10.4 Trade-offs principales

| Decisión o táctica candidata | Mejora | Puede afectar | Criterio para evaluarla |
|---|---|---|---|
| Reducir geometría y texturas de modelos | Carga, fluidez y consumo de memoria | Fidelidad visual | Cumplir EC-01 y EC-02 conservando elementos necesarios para orientarse. |
| Mantener caché local versionada | Disponibilidad y tiempo de carga | Almacenamiento local y frescura | Cumplir EC-04 e indicar versión/estado sin conexión. |
| Actualizar ubicación con moderada frecuencia | Batería y estabilidad visual | Sensación de tiempo real | Usar la menor frecuencia de muestreo que permita cumplir EC-03 sin drenar la batería. |
| Centralizar acceso a Supabase detrás de la API | Seguridad y desacoplamiento | Latencia adicional mínima | Comparar el riesgo de exposición/acoplamiento con los umbrales de EC-01. |

---

<a id="section-technical-risks"></a>
# 11. Riesgos y deuda técnica

| ID | Riesgo o Deuda | Impacto | Mitigación |
|---|---|---|---|
| **RSK-01** | Complejidad de modelos 3D provistos por la universidad excede límites de memoria móvil. | Alto | Pipeline automatizado de optimización y simplificación de mallas (Blender/gltf-transform) antes de publicar en Supabase Storage. |
| **RSK-02** | Disparidad de hardware y rendimiento de GPU entre dispositivos Android de gama de entrada. | Alto | Configuración de niveles de detalle (LOD) y fallback a vista esquemática si la tasa de cuadros cae por debajo de 20 FPS. |
| **RSK-03** | Dependencia del servicio gestionado Supabase (límites de cuota o indisponibilidad externa). | Medio | Caché local robusta en clientes móviles y abstracción de repositorios para permitir migración transparente. |

---

<a id="section-glossary"></a>
# 12. Glosario

| Término | Definición |
|---|---|
| **ADR (Architecture Decision Record)** | Documento formal y conciso que captura una decisión de diseño arquitectónico relevante, su contexto, alternativas evaluadas y consecuencias. |
| **BaaS (Backend as a Service)** | Modelo de computación en la nube donde los servicios de backend (autenticación, base de datos, almacenamiento de archivos) son provistos como servicios administrados (ej. Supabase). |
| **BLoC (Business Logic Component)** | Patrón de diseño de arquitectura de software para Flutter que separa la interfaz de usuario de la lógica de negocio mediante flujos de eventos (Events) y estados (States). |
| **Campus UTB** | Terreno, edificios e instalaciones físicas de la Universidad Tecnológica de Bolívar en Cartagena, Colombia. |
| **Corte Vertical (Aspecto A-01)** | Implementación funcional de una característica de extremo a extremo (desde la base de datos hasta la interfaz gráfica táctil) para validar la arquitectura tempranamente. |
| **Draco** | Biblioteca de compresión de código abierto desarrollada por Google para comprimir y descomprimir mallas geométricas 3D y nubes de puntos. |
| **Edificio (Building)** | Estructura física del campus que contiene uno o más pisos, identificada con nombre, código y coordenadas geoespaciales. |
| **Fallback Manual** | Mecanismo de degradación controlada que permite al usuario seleccionar manualmente su punto de partida (edificio, piso o salón) cuando la geolocalización automática no está disponible o es imprecisa. |
| **GLB / GLTF (Graphics Language Transmission Format)** | Formato estándar de archivo abierto para la transmisión y carga eficiente de escenas y modelos 3D. GLB es la versión binaria compacta de GLTF. |
| **Hive** | Base de datos clave-valor ligera, embebida y de alto rendimiento escrita puramente en Dart, utilizada para persistencia local en dispositivos móviles. |
| **Incertidumbre de Ubicación** | Representación probabilística del error en la estimación de la posición del usuario, ilustrada visualmente mediante un radio o círculo de precisión alrededor del marcador. |
| **Monolito Modular** | Estilo arquitectónico en el que toda la aplicación se empaqueta y despliega como una única unidad ejecutable, pero su código interno está rigurosamente dividido en módulos independientes con fronteras explícitas y kernel compartido. |
| **NestJS** | Framework progresivo de Node.js para la construcción de aplicaciones del lado del servidor escalables, estructurado con TypeScript e inyección de dependencias. |
| **OpenAPI / Swagger** | Estándar de especificación para describir, producir, consumir y visualizar servicios web RESTful. |
| **Piso (Floor)** | Nivel o planta horizontal dentro de un edificio que contiene salones, áreas comunes y puntos de interés específicos. |
| **POI (Punto de Interés / Point of Interest)** | Ubicación o elemento relevante dentro del campus o edificio (ej. aula, laboratorio, baño, cafetería, biblioteca, ascensor, escalera). |
| **PostGIS** | Extensión espacial para el sistema de base de datos relacional PostgreSQL que añade soporte para objetos geográficos permitiendo ejecutar consultas espaciales en SQL. |
| **PostgREST** | Servidor web independiente que transforma una base de datos PostgreSQL directamente en una API RESTful. |
| **Supabase** | Alternativa de código abierto a Firebase construida sobre PostgreSQL, que provee Auth, Database, Storage, Edge Functions y Realtime. |
