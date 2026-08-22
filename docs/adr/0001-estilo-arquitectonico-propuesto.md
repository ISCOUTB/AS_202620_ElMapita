---
number: 0001
date: 2026-08-22
title: "Estilo Arquitectónico: Monolito Modular para Backend (NestJS) y Frontend (Flutter)"
status: Accepted
deciders: ["Diego Rosales Garza", "Rodrigo Vazquez Rico", "Angel Fabian Gutierrez Gomez"]
technical-story: "Definir la estructura base del proyecto para que el equipo de 3 personas inicie desarrollo del corte vertical A-01 (mapa 3D + geolocalización) con testabilidad, bajo acoplamiento a Supabase y onboarding inmediato."
---

# ADR-0001: Estilo Arquitectónico Monolito Modular para Backend y Frontend

## Contexto

El Mapita UTB es una aplicación móvil (Flutter) con API backend (NestJS/TypeScript) que consume Supabase (Auth, Database/PostGIS, Storage, Realtime). El primer corte vertical (Aspecto A-01) exige:

- Renderizado 3D de modelos .glb/.gltf con navegación táctil (rotación, zoom, cambio de piso) — **EC-01, EC-02**
- Geolocalización en tiempo real con incertidumbre y fallback manual — **EC-03**
- Caché offline versionada para disponibilidad — **EC-04**

**Restricciones clave:**
- Equipo de **3 desarrolladores** (junior/medio), onboarding en días, no semanas
- **Supabase** como BaaS: riesgo de vendor lock-in; necesitamos aislar su cliente para testear y poder migrar
- **Testabilidad crítica**: lógica 3D (carga, parsing, coordenadas) y geo (GPS, precision, floor detection) deben ser testeables unitariamente sin device farm
- Entrega continua: un solo comando para levantar todo (`npm run start:dev` + `flutter run`)

## Alternativas Consideradas

| Alternativa | Descripción | Pros | Contras |
|-------------|-------------|------|---------|
| **1. Arquitectura en Capas (Layered)** | Controller → Service → Repository → Entity (backend); Widget → Model → Service (frontend) | Mínimo overhead, onboarding inmediato, familiar para cualquier dev | Acopla Supabase en Repositories; lógica 3D/Geo mezclada con framework; tests lentos/frágiles; deuda técnica crece rápido |
| **2. Arquitectura Hexagonal (Ports & Adapters)** | Dominio puro + puertos (interfaces) + adaptadores (Supabase, GPS, Flutter widgets, Map renderer) | Aislamiento total de Supabase/framework; tests unitarios puros y rápidos; contratos FE/BE alineados por puertos | Curva alta (DDD táctico, inversión de dependencias); boilerplate excesivo para MVP; 3 devs pierden 1-2 sprints en "arquitectura" |
| **3. Monolito Modular (Modular Monolith)** ✅ **SELECCIONADA** | Módulos por feature (`mapas`, `ubicacion`, `auth`, `pois`) cada uno con `domain/`, `application/`, `infrastructure/` interno; `shared/kernel` mínimo | Ownership por feature; testabilidad práctica (domain puro + fakes); Supabase encapsulado en `infrastructure`; onboarding rápido (estructura `features/` idiomática); evolución natural a microservicios; un solo deploy | Requiere disciplina de límites (no cruzar `private` entre módulos); shared kernel puede crecer sin control |

**Análisis detallado en:** [`docs/comparativa-de-arquitecturas.md`](comparativa-de-arquitecturas.md)

## Decisión

**Adoptamos Monolito Modular para ambos lados:**

### Backend (NestJS) — Estructura
```
backend/
├── src/
│   ├── modules/
│   │   ├── mapas/           # Edificios, pisos, modelos 3D, versiones
│   │   │   ├── domain/      # Entidades, value objects, repository interfaces (puertos)
│   │   │   ├── application/ # Casos de uso (GetBuilding, GetFloorModel, ListPois)
│   │   │   ├── infrastructure/
│   │   │   │   ├── persistence/  # Supabase/PostGIS adapters (implementan puertos)
│   │   │   │   └── storage/      # Supabase Storage adapter para modelos 3D
│   │   │   ├── interfaces/  # Controllers HTTP, DTOs, OpenAPI
│   │   │   └── mapas.module.ts
│   │   ├── ubicacion/       # Geolocalización, precision, fallback manual
│   │   │   ├── domain/      # UserLocation, LocationProvider (puerto)
│   │   │   ├── application/ # GetCurrentLocation, SetManualLocation
│   │   │   ├── infrastructure/
│   │   │   │   └── platform/     # Adapter para geolocator/platform channels
│   │   │   └── ubicacion.module.ts
│   │   ├── auth/            # Supabase Auth integration, JWT validation, roles
│   │   │   ├── domain/
│   │   │   ├── application/
│   │   │   ├── infrastructure/
│   │   │   │   └── supabase/     # Supabase Auth client adapter
│   │   │   └── auth.module.ts
│   │   └── pois/            # Puntos de interés (CRUD admin, consultas públicas)
│   │       ├── domain/
│   │       ├── application/
│   │       ├── infrastructure/
│   │       └── pois.module.ts
│   ├── shared/
│   │   ├── kernel/          # Tipos base: Entity, ValueObject, DomainEvent, Result<T>
│   │   ├── supabase/        # Cliente Supabase configurado (singleton) — SOLO para adapters
│   │   ├── errors/          # AppError, DomainError, InfrastructureError
│   │   └── config/          # ConfigModule, validación env
│   ├── app.module.ts        # Importa todos los feature modules
│   └── main.ts              # Bootstrap, OpenAPI, global pipes, filters
├── test/                    # Tests de integración (e2e)
├── package.json
└── tsconfig.json
```

### Frontend (Flutter) — Estructura
```
frontend/
├── lib/
│   ├── features/
│   │   ├── mapas/
│   │   │   ├── domain/      # Entidades (Building, Floor, Model3D), Repository interfaces
│   │   │   ├── application/ # Use cases (LoadBuilding, SwitchFloor, DownloadModel)
│   │   │   ├── infrastructure/
│   │   │   │   ├── api/         # Dio/HTTP client + generated DTOs (OpenAPI)
│   │   │   │   ├── storage/     # Local cache (Hive/SharedPreferences) para modelos
│   │   │   │   └── renderer/    # Adapter para Flutter 3D (flame/three.dart) — puerto MapRenderer
│   │   │   ├── presentation/  # Widgets, Cubits/Blocs, Pages
│   │   │   └── mapas_feature.dart  # Public API del módulo
│   │   ├── ubicacion/
│   │   │   ├── domain/      # UserLocation, LocationProvider (puerto), PrecisionLevel
│   │   │   ├── application/ # WatchLocation, RequestPermission, SetManualLocation
│   │   │   ├── infrastructure/
│   │   │   │   └── platform/    # geolocator plugin adapter (implementa LocationProvider)
│   │   │   ├── presentation/
│   │   │   └── ubicacion_feature.dart
│   │   ├── auth/
│   │   │   ├── domain/
│   │   │   ├── application/
│   │   │   ├── infrastructure/  # Supabase Flutter SDK adapter
│   │   │   ├── presentation/
│   │   │   └── auth_feature.dart
│   │   └── pois/
│   │       ├── domain/
│   │       ├── application/
│   │       ├── infrastructure/
│   │       ├── presentation/
│   │       └── pois_feature.dart
│   ├── core/
│   │   ├── kernel/          # Base classes: Entity, ValueObject, UseCase, Result<Either>
│   │   ├── di/              # Service locator / get_it registration por feature
│   │   ├── network/         # Dio client, interceptors (auth, logging, errors)
│   │   ├── storage/         # Hive boxes, secure storage abstraction
│   │   └── platform/        # MethodChannel wrappers, permissions helper
│   ├── shared/
│   │   ├── widgets/         # UI kit: Botones, Loaders, ErrorViews, MapControls
│   │   ├── theme/           # AppTheme, Colors, Typography
│   │   └── extensions/      # Dart extensions (context, string, num)
│   ├── app.dart             # MaterialApp + providers + routing (go_router)
│   └── main.dart            # Entry point, init DI, flavor config
├── test/                    # Unit tests (domain/application) + widget tests
├── integration_test/        # Integration tests (flutter drive)
├── pubspec.yaml
└── analysis_options.yaml
```

### Reglas de Límites (Enforced by Tooling)

| Regla | Backend (ESLint + ArchUnitTS) | Frontend (dart_analyzer + custom lints) |
|-------|-------------------------------|------------------------------------------|
| **No importar `private` de otro módulo** | `src/modules/*/infrastructure/**` → `private` | `lib/features/*/infrastructure/**` → `private` |
| **Domain puro = cero dependencias externas** | `domain/**` no importa `@nestjs/*`, `supabase`, `typeorm` | `domain/**` no importa `flutter`, `dio`, `hive`, `geolocator` |
| **Application solo usa domain + interfaces** | `application/**` importa `domain`, `interfaces` (puertos) | `application/**` importa `domain`, `infrastructure` (solo interfaces) |
| **Shared kernel = solo tipos base** | `shared/kernel/**` = interfaces, base classes, errors | `core/kernel/**` = base classes, Result/Either, UseCase abstracto |

---

## Consecuencias

### Positivas (Beneficios Esperados)

| Área | Impacto |
|------|---------|
| **Onboarding** | Dev nuevo clona → `npm install && flutter pub get` → entiende `features/mapas` en horas, no días |
| **Testabilidad A-01 (EC-01/EC-02/EC-03)** | `domain/application` testables con fakes: `FakeLocationProvider`, `FakeMapModelLoader`, `FakePoiRepository` — tests unitarios < 50ms |
| **Acoplamiento Supabase** | Cliente Supabase **solo** en `infrastructure/supabase` (backend) y `infrastructure/supabase` (frontend). Domain/application ignoran su existencia. Migración a Postgres directo o Firebase = cambiar adaptador, no tocar casos de uso. |
| **Paralelismo 3 devs** | Dev 1: `mapas` + `pois` | Dev 2: `ubicacion` + `auth` | Dev 3: `core`/`shared` + CI/CD + 3D renderer adapter. Mínimos conflictos de merge. |
| **Contratos FE/BE** | OpenAPI generado desde NestJS DTOs → `openapi-generator` → tipos Dart tipados. Breaking changes detectados en `npm run test:contracts`. |
| **Evolución** | Nuevo feature (routing, AR, analytics) = nuevo módulo. Si el proyecto escala >10 devs, extraer módulo a microservicio es viable (ya tiene puertos definidos). |
| **Despliegue simple** | Un contenedor Docker backend + build Flutter web/iOS/Android. Sin orquestación compleja. |

### Negativas / Compromisos Técnicos (Trade-offs)

| Compromiso | Mitigación |
|------------|------------|
| **Disciplina de límites no es automática** | Configurar `eslint-plugin-boundaries` (backend) y `custom_lint` rules (frontend) en CI. Code review obligatorio para imports cross-module. |
| **Shared kernel puede crecer descontrolado** | Revisar en retrospectiva cada sprint: "¿Esto pertenece a shared o a un feature?". Mover a feature si solo lo usa uno. |
| **No es "puro" DDD/Hexagonal** | Aceptado: pragmatismo > pureza. Los puertos existen **dentro de cada módulo** (domain ↔ infrastructure), no a nivel global. Suficiente para testabilidad y aislamiento Supabase. |
| **Duplicación de boilerplate por módulo** | Usar schematics/generators: `nest g module mapas --flat` + plantilla interna; `very_good_cli` o brick para Flutter features. |
| **Testing de integración 3D/Geo requiere device/emulador** | Tests unitarios (domain/application) en CI (GitHub Actions). Tests de integración (renderer, GPS real) en `integration_test/` ejecutados manualmente o en device farm semanal. |
| **Supabase Realtime WebSocket en módulo `mapas`** | Encapsular en `infrastructure/realtime/` con puerto `ModelVersionNotifier`. Frontend suscribe via `MapasBloc`. |

---

## Plan de Implementación Inmediata (Semana 4)

1. **Crear repositorios/proyectos base** (backend NestJS + frontend Flutter) con estructura de carpetas arriba
2. **Configurar tooling de límites** (ESLint boundaries, dart analyze custom rules)
3. **Implementar `shared/kernel` + `core/kernel`** (Result/Either, UseCase abstracto, base Entity/VO)
4. **Configurar Supabase client singleton** en `shared/supabase` (BE) y `core/network/supabase` (FE)
5. **Generar OpenAPI + tipos Dart** → verificar `npm run test:contracts` en verde
6. **Smoke test**: Health check endpoint (`GET /health`) + widget test `App loads` → ambos en CI
7. **Documentar comando único** en `README.md`: `./scripts/dev.sh` (levanta backend:3000 + flutter run)

---

## Referencias

- [Matriz Comparativa Completa](comparativa-de-arquitecturas.md)
- [arc42 Sección 4: Contexto y Fronteras](../arc42/arc42-template-EN.md#section-context-and-boundaries)
- [C4 Nivel 1 - Contexto](../c4/C4_Contexto.png)
- [Escenarios de Calidad EC-01 a EC-04](../arc42/arc42-template-EN.md#section-quality-scenarios)