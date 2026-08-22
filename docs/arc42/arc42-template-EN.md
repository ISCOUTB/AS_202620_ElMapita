---
date: Agosto de 2026
title: "Arquitectura de El Mapita UTB"
---

# 

**About arc42**

arc42, the template for documentation of software and system
architecture.

Template Version 9.0-EN. (based upon AsciiDoc version), July 2025

Created, maintained and © by Dr. Peter Hruschka, Dr. Gernot Starke and
contributors. See <https://arc42.org>.

<a id="section-introduction-and-goals"></a>
# 1. Introducción y objetivos

## 1.1 Resumen de requisitos

El Mapita UTB es una aplicación móvil que ayuda a estudiantes, visitantes y personal a orientarse dentro del campus de la Universidad Tecnológica de Bolívar. El sistema presenta edificios y pisos mediante un mapa 3D interactivo, permite localizar puntos de interés —salones, laboratorios, baños, cafeterías, bibliotecas, escaleras y ascensores— y muestra la ubicación estimada del usuario o un punto de partida seleccionado manualmente.

El primer corte vertical del producto es el aspecto **A-01: visualización del mapa 3D y ubicación del usuario**, asociado con el requisito funcional **RF-01**. Este aspecto incluye la carga del modelo, su navegación táctil, el cambio de piso, la consulta de puntos de interés y el tratamiento explícito de la incertidumbre de la ubicación en interiores.

El alcance inicial no promete navegación interior de precisión centimétrica ni rutas paso a paso. Cuando la señal de ubicación no sea suficiente, el sistema debe comunicarlo y permitir que el usuario establezca manualmente su posición.

## 1.2 Objetivos de calidad

| Prioridad | Objetivo de calidad | Criterio de éxito |
|---|---|---|
| 1 | **Usabilidad y confiabilidad de la orientación** | El usuario distingue su ubicación estimada, conoce el nivel de precisión y dispone de selección manual cuando la señal no es confiable. |
| 2 | **Rendimiento de la experiencia 3D** | Los mapas cargan dentro del umbral acordado y las interacciones de rotación, zoom y cambio de piso se mantienen fluidas en el dispositivo de referencia. |
| 3 | **Disponibilidad ante conectividad variable** | Un mapa consultado previamente continúa disponible para orientación básica cuando la red es intermitente o está ausente. |
| 4 | **Privacidad de la ubicación** | La ubicación se usa únicamente para orientar al usuario y no se conserva como historial por defecto. |

Las medidas verificables y su priorización por impacto y riesgo se encuentran en la [sección 10](#section-quality-scenarios).

## 1.3 Interesados

| Interesado | Responsabilidad o relación | Preocupaciones y expectativas |
|---|---|---|
| Estudiante de nuevo ingreso | Usuario principal | Encontrar destinos rápidamente, comprender el mapa y no perderse entre edificios o pisos. |
| Visitante o padre de familia | Usuario ocasional | Usar la aplicación sin conocer previamente el campus ni requerir capacitación. |
| Personal docente y administrativo | Usuario recurrente | Consultar ubicaciones confiables y cambios recientes en espacios del campus. |
| Equipo de desarrollo | Construcción y evolución | Requisitos verificables, límites claros entre componentes y decisiones trazables. |

<a id="section-architecture-constraints"></a>
# 2. Restricciones de arquitectura

Las siguientes condiciones reducen el espacio de solución y provienen de fuentes externas al diseño. Flutter, NestJS y Supabase no se incluyen como restricciones porque fueron elegidos libremente por el equipo; son decisiones arquitectónicas que deberán justificarse mediante ADR.

| ID | Tipo y origen | Restricción | Justificación y consecuencia arquitectónica |
|---|---|---|---|
| RES-01 | Académica — consigna de la asignatura | La arquitectura debe documentarse con arc42, C4, ADR y trazabilidad desde los aspectos hasta evidencia automatizada. | Es un formato de entrega impuesto. La documentación y los identificadores deben permanecer enlazables desde el repositorio. |
| RES-02 | Física y tecnológica — dispositivos móviles | La ubicación depende de los sensores y permisos del dispositivo; el GPS puede degradarse en interiores y entre edificios. | No se puede garantizar precisión interior solo con GPS. La interfaz debe mostrar incertidumbre y ofrecer selección manual, sin presentar una estimación imprecisa como posición exacta. |
| RES-03 | Operacional — campus y red móvil | La conectividad, latencia y capacidad de los teléfonos de los usuarios son variables. | Los modelos deben optimizarse y almacenarse en caché; los fallos de red deben producir estados comprensibles y no bloquear la orientación básica ya descargada. |

<a id="section-context-and-scope"></a>
# 3. Contexto y alcance

## 3.1 Contexto de negocio

El límite del sistema comprende la aplicación móvil, la API de El Mapita y la lógica necesaria para consultar, preparar y presentar mapas, pisos, modelos 3D y puntos de interés. Supabase y los servicios de ubicación del dispositivo se consideran sistemas externos porque pueden evolucionar o fallar de manera independiente.

| Actor o sistema externo | Entrada hacia El Mapita | Salida de El Mapita |
|---|---|---|
| Estudiante, visitante o personal UTB | Consultas, gestos táctiles, edificio/piso/destino seleccionado y autorización de ubicación | Mapa 3D, puntos de interés, ubicación estimada, precisión y mensajes de degradación |
| Plataforma de ubicación del dispositivo | Coordenadas, precisión, estado del permiso y disponibilidad del sensor | Solicitud de permiso o lectura de ubicación durante la sesión |
| Supabase | Datos geoespaciales, identidades, modelos 3D, eventos y estado del servicio | Consultas autenticadas y solicitudes de archivos |

El diagrama normativo de contexto se encuentra en [C4 nivel 1 — Contexto de El Mapita](../c4/contexto.md).

## 3.2 Contexto técnico

| Canal | Tecnología prevista | Uso |
|---|---|---|
| Usuario ↔ aplicación móvil | Flutter sobre Android/iOS | Interacción táctil, representación 3D, consulta y selección manual de ubicación |
| Aplicación móvil ↔ API El Mapita | HTTPS/JSON | Consulta de edificios, pisos, puntos de interés, versiones y referencias de modelos |
| Aplicación móvil ↔ plataforma de ubicación | API de ubicación del sistema operativo | Coordenadas, precisión y permisos; no constituye posicionamiento interior garantizado |
| API El Mapita ↔ Supabase | Conexión cifrada y SDK/API del proveedor | PostgreSQL/PostGIS, Auth, Storage y Realtime según la responsabilidad de cada caso de uso |

El backend NestJS actúa como frontera de aplicación para reglas, autorización y desacoplamiento del proveedor. Las credenciales privilegiadas de Supabase no deben incluirse en el cliente móvil. Los detalles de contenedores, componentes y despliegue pertenecen a niveles posteriores del modelo C4.

# Solution Strategy {#section-solution-strategy}

# Building Block View {#section-building-block-view}

## Whitebox Overall System {#_whitebox_overall_system}

***\<Overview Diagram\>***

Motivation

:   *\<text explanation\>*

Contained Building Blocks

:   *\<Description of contained building block (black boxes)\>*

Important Interfaces

:   *\<Description of important interfaces\>*

### \<Name black box 1\> {#_name_black_box_1}

*\<Purpose/Responsibility\>*

*\<Interface(s)\>*

*\<(Optional) Quality/Performance Characteristics\>*

*\<(Optional) Directory/File Location\>*

*\<(Optional) Fulfilled Requirements\>*

*\<(optional) Open Issues/Problems/Risks\>*

### \<Name black box 2\> {#_name_black_box_2}

*\<black box template\>*

### \<Name black box n\> {#_name_black_box_n}

*\<black box template\>*

### \<Name interface 1\> {#_name_interface_1}

...​

### \<Name interface m\> {#_name_interface_m}

## Level 2 {#_level_2}

### White Box *\<building block 1\>* {#_white_box_building_block_1}

*\<white box template\>*

### White Box *\<building block 2\>* {#_white_box_building_block_2}

*\<white box template\>*

...​

### White Box *\<building block m\>* {#_white_box_building_block_m}

*\<white box template\>*

## Level 3 {#_level_3}

### White Box \<\_building block x.1\_\> {#_white_box_building_block_x_1}

*\<white box template\>*

### White Box \<\_building block x.2\_\> {#_white_box_building_block_x_2}

*\<white box template\>*

### White Box \<\_building block y.1\_\> {#_white_box_building_block_y_1}

*\<white box template\>*

# Runtime View {#section-runtime-view}

## \<Runtime Scenario 1\> {#_runtime_scenario_1}

-   *\<insert runtime diagram or textual description of the scenario\>*

-   *\<insert description of the notable aspects of the interactions
    between the building block instances depicted in this diagram.\>*

## \<Runtime Scenario 2\> {#_runtime_scenario_2}

## ...​

## \<Runtime Scenario n\> {#_runtime_scenario_n}

# Deployment View {#section-deployment-view}

## Infrastructure Level 1 {#_infrastructure_level_1}

***\<Overview Diagram\>***

Motivation

:   *\<explanation in text form\>*

Quality and/or Performance Features

:   *\<explanation in text form\>*

Mapping of Building Blocks to Infrastructure

:   *\<description of the mapping\>*

## Infrastructure Level 2 {#_infrastructure_level_2}

### *\<Infrastructure Element 1\>* {#_infrastructure_element_1}

*\<diagram + explanation\>*

### *\<Infrastructure Element 2\>* {#_infrastructure_element_2}

*\<diagram + explanation\>*

...​

### *\<Infrastructure Element n\>* {#_infrastructure_element_n}

*\<diagram + explanation\>*

# Cross-cutting Concepts {#section-concepts}

## *\<Concept 1\>* {#_concept_1}

*\<explanation\>*

## *\<Concept 2\>* {#_concept_2}

*\<explanation\>*

...​

## *\<Concept n\>* {#_concept_n}

*\<explanation\>*

# Architecture Decisions {#section-design-decisions}

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
│       └── EC-02: 95 % de fotogramas ≤ 33,3 ms ............... [A/A]
├── Confiabilidad y usabilidad
│   └── Manejo de incertidumbre de ubicación
│       └── EC-03: alternativa manual ante señal insuficiente . [A/A]
└── Disponibilidad
    └── Continuidad con conectividad degradada
        └── EC-04: apertura de contenido local < 5 s .......... [A/M]
```

Los escenarios EC-01, EC-02 y EC-03 orientan primero el análisis porque combinan impacto y riesgo altos. La privacidad es un objetivo transversal y una restricción legal; cuando se diseñe persistencia de ubicación deberá añadirse un escenario específico y su ADR.

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
| Medida | Se acepta la posición automática únicamente cuando la precisión reportada es **≤ 15 m**. Si en **10 segundos** no existe una lectura aceptable, la opción manual aparece en **≤ 2 segundos**, sin mostrar una posición como exacta. |
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

## 10.3 Trade-offs principales

| Decisión o táctica candidata | Mejora | Puede afectar | Criterio para evaluarla |
|---|---|---|---|
| Reducir geometría y texturas de modelos | Carga, fluidez y consumo de memoria | Fidelidad visual | Cumplir EC-01 y EC-02 conservando elementos necesarios para orientarse. |
| Mantener caché local versionada | Disponibilidad y tiempo de carga | Almacenamiento local y frescura | Cumplir EC-04 e indicar versión/estado sin conexión. |
| Actualizar ubicación con alta frecuencia | Sensación de tiempo real | Batería, privacidad y estabilidad visual | Usar la menor frecuencia que permita cumplir EC-03. |
| Centralizar acceso a Supabase detrás de la API | Seguridad y desacoplamiento | Latencia y costo operativo | Comparar el riesgo de exposición/acoplamiento con los umbrales de EC-01. |

# 4. Contexto y Fronteras (System Scope and Context) {#section-context-and-boundaries}

## 4.1 Contexto de Negocio — Actores e Interacciones

| Actor | Rol | Interacciones principales con El Mapita | Permisos / Accesos |
|-------|-----|------------------------------------------|---------------------|
| **Estudiante de nuevo ingreso** | Usuario principal | Buscar salones, laboratorios, baños, cafeterías, bibliotecas; ver ubicación en tiempo real; navegar entre pisos; seleccionar punto de partida manual | Acceso completo a mapas 3D y POIs; ubicación opcional (consentimiento) |
| **Visitante / Padre de familia** | Usuario ocasional | Consultar mapa del campus; localizar edificio de evento o reunión; orientación básica sin cuenta | Acceso de solo lectura a mapas públicos; sin autenticación requerida |
| **Personal docente** | Usuario recurrente | Consultar ubicación de salones asignados; verificar cambios de aula; acceso a información actualizada de espacios | Acceso a mapas + datos de asignación de salones (vía Supabase Auth) |
| **Personal administrativo** | Usuario recurrente | Gestionar solicitudes de espacios; consultar disponibilidad; reportar incidencias en señalética | Acceso a panel de administración (roles elevados en Supabase Auth) |
| **Administración UTB (Dirección de Tecnología)** | Stakeholder / Owner | Supervisar uso de la app; analizar métricas de adopción; aprobar actualizaciones de mapas y POIs | Acceso a dashboard de métricas y panel de gestión de contenido (CMS interno) |

## 4.2 Sistemas Externos y Dependencias

| Sistema Externo | Tipo | Qué provee a El Mapita | Protocolo / Interfaz | Criticidad |
|-----------------|------|------------------------|----------------------|------------|
| **Supabase Auth** | IAM / AuthN/AuthZ | Autenticación (email, magic link, OAuth), gestión de roles (estudiante, staff, admin), JWT para API | HTTPS / REST + WebSocket (Realtime) | **Alta** — sin auth no hay personalización ni roles |
| **Supabase Database (PostgreSQL + PostGIS)** | Persistencia geoespacial | Edificios, pisos, modelos 3D (referencias), POIs (salones, baños, etc.), geometrías, versiones de caché | HTTPS / PostgREST (REST) + pg driver (backend) | **Alta** — fuente de verdad de datos espaciales |
| **Supabase Storage** | Almacenamiento de blobs | Archivos .glb/.gltf de modelos 3D, texturas, assets de pisos, imágenes de POIs | HTTPS / S3-compatible REST | **Media** — modelos pueden cacharse localmente |
| **Supabase Realtime** | Pub/Sub | Notificaciones de cambios en POIs, edificios, versiones de modelos (invalidación de caché) | WebSocket (WSS) | **Media** — mejora frescura, no bloquea funcionamiento |
| **Plataforma de ubicación del dispositivo (iOS CoreLocation / Android Fused Location)** | Sensor / OS Service | Coordenadas lat/long, precisión (horizontal accuracy), floor level (cuando disponible), estado de permisos | API nativa del SO (no red) | **Alta** — core de geolocalización en tiempo real |
| **APIs de mapas base (Mapbox / Google Maps / OpenStreetMap)** | Servicio de mapas | Tiles de mapa base (opcional, para vista 2D de contexto), geocodificación inversa, routing exterior | HTTPS / REST (Vector tiles, GeoJSON) | **Baja** — el core 3D es propio; solo contexto exterior |
| **Servicio de notificaciones push (FCM / APNs)** | Mensajería | Alertas de emergencia, cambios de salón, eventos de campus | HTTPS / REST | **Baja** — funcionalidad futura |


> **Nota:** La autenticación (Supabase Auth) delimita el acceso a capacidades de escritura y administración. Usuarios no autenticados operan en modo "visitante" (solo lectura, mapas públicos).


### 4.3.1 Esquemas de Datos Clave (Referencia)

**Edificio (Building)**
```json
{
  "id": "uuid",
  "nombre": "string",
  "codigo": "string",
  "geometria": "Polygon (PostGIS)",
  "pisos": ["PisoRef"],
  "versionModelo3D": "string (semver)",
  "actualizadoEn": "timestamp"
}
```

**Piso (Floor)**
```json
{
  "id": "uuid",
  "edificioId": "uuid",
  "numero": "integer",
  "nombre": "string",
  "modelo3DUrl": "string (Supabase Storage signed URL)",
  "modelo3DVersion": "string",
  "alturaMetros": "number",
  "pois": ["PoiRef"]
}
```

**Punto de Interés (POI)**
```json
{
  "id": "uuid",
  "pisoId": "uuid",
  "tipo": "enum: salon|laboratorio|bano|cafeteria|biblioteca|escalera|ascensor|otro",
  "nombre": "string",
  "geometria": "Point (PostGIS) / x,y en coordenadas modelo 3D",
  "metadatos": "jsonb (capacidad, horario, accesibilidad, etc.)"
}
```

**Ubicación de Usuario (UserLocation — solo en memoria cliente, no persistida)**
```json
{
  "latitud": "number",
  "longitud": "number",
  "precisionMetros": "number",
  "pisoEstimado": "integer?",
  "fuente": "enum: gps|wifi|ble|manual",
  "timestamp": "ISO8601",
  "incertidumbreMostrada": "boolean"
}
```

## 4.4 Diagrama de Contexto (Referencia Visual)

El diagrama C4 Nivel 1 (Contexto) en [`../c4/C4_Contexto.png`](../c4/C4_Contexto.png) representa gráficamente:
- El sistema **El Mapita** (App Flutter + API NestJS) como contenedor central
- Actores humanos (Estudiante, Visitante, Personal, Admin UTB)
- Sistemas externos (Supabase Auth/DB/Storage/Realtime, OS Location, Map Tiles)
- Flujos de datos y protocolos en cada frontera

---

# Risks and Technical Debts {#section-technical-risks}

# Glossary {#section-glossary}

+----------------------+-----------------------------------------------+
| Term                 | Definition                                    |
+======================+===============================================+
| *\<Term-1\>*         | *\<definition-1\>*                            |
+----------------------+-----------------------------------------------+
| *\<Term-2\>*         | *\<definition-2\>*                            |
+----------------------+-----------------------------------------------+
