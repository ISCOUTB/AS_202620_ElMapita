# El Mapita UTB

Aplicación móvil interactiva con mapa 3D de la Universidad Tecnológica de Bolívar (UTB), diseñada para guiar a estudiantes, visitantes y personal dentro del campus. Permite ubicar salones, baños, laboratorios, cafeterías, bibliotecas, escaleras y ascensores, e incluye un puntero de ubicación en tiempo real dentro de las instalaciones.

---

## 👥 Equipo de Desarrollo

- Diego Rosales Garza
- Rodrigo Vazquez Rico
- Angel Fabian Gutierrez Gomez

## 🎯 Stakeholders / Beneficiarios

- Estudiantes de nuevo ingreso
- Visitantes y padres de familia
- Personal administrativo y docente
- Dirección de Tecnología de la UTB

---

## 🛠 Stack Tecnológico

| Capa | Tecnología |
| :--- | :--- |
| **Frontend Móvil** | Flutter (Dart) |
| **Backend API** | NestJS (TypeScript) |
| **Base de Datos** | Supabase (PostgreSQL + PostGIS) |
| **Autenticación** | Supabase Auth |
| **Almacenamiento** | Supabase Storage |
| **Tiempo Real** | Supabase Realtime |

---

## 🏗 Arquitectura

**Estilo seleccionado:** **Monolito Modular** (para ambos backend y frontend)

> **Justificación:** Equilibrio pragmático entre testabilidad, bajo acoplamiento a Supabase, onboarding rápido para equipo de 3 personas, y evolución natural. Ver [ADR-0001](docs/adr/0001-estilo-arquitectonico-propuesto.md) y [Matriz Comparativa](docs/comparativa-de-arquitecturas.md).

### Estructura Backend (NestJS)
```
backend/src/
├── modules/
│   ├── mapas/          # Edificios, pisos, modelos 3D
│   ├── ubicacion/      # Geolocalización, fallback manual
│   ├── auth/           # Supabase Auth, JWT, roles
│   └── pois/           # Puntos de interés
├── shared/
│   ├── kernel/         # Entity, ValueObject, UseCase, Repository
│   ├── supabase/       # Cliente Supabase singleton
│   ├── errors/         # AppError, DomainError, InfrastructureError
│   └── config/         # ConfigModule con validación Joi
└── health.controller.ts
```

### Estructura Frontend (Flutter)
```
frontend/lib/
├── features/
│   ├── mapas/          # Domain, Application, Infrastructure, Presentation
│   ├── ubicacion/      # GPS, permisos, ubicación manual
│   ├── auth/           # Login, registro, tokens
│   └── pois/           # Puntos de interés
├── core/
│   ├── kernel/         # Result, UseCase, Entity, ValueObject
│   ├── di/             # get_it injector
│   ├── network/        # Dio client, interceptors
│   ├── storage/        # LocalStorage (Hive), SecureStorage
│   └── platform/       # Permissions, Location services
└── shared/
    ├── widgets/        # UI kit común
    ├── theme/          # AppTheme (light/dark)
    └── extensions/     # Dart extensions
```

---

## 📚 Documentación de Arquitectura

| Documento | Ubicación | Descripción |
|-----------|-----------|-------------|
| **arc42 Sección 4: Contexto y Fronteras** | `docs/arc42/arc42-template-EN.md#section-context-and-boundaries` | Actores, sistemas externos, fronteras de negocio y técnicas |
| **Matriz Comparativa de Patrones** | `docs/comparativa-de-arquitecturas.md` | Capas vs Hexagonal vs Monolito Modular con criterios ponderados |
| **ADR-0001: Estilo Arquitectónico** | `docs/adr/0001-estilo-arquitectonico-propuesto.md` | Decisión formal con consecuencias y plan de implementación |
| **C4 Nivel 1: Contexto** | `docs/c4/C4_Contexto.png` | Diagrama de contexto del sistema |
| **Escenarios de Calidad (EC-01 a EC-04)** | `docs/arc42/arc42-template-EN.md#section-quality-scenarios` | Rendimiento, fluidez, ubicación, disponibilidad |

---

## 🚀 Inicio Rápido

### Prerrequisitos

- **Node.js** ≥ 18 (para backend NestJS)
- **Flutter** ≥ 3.19 (para frontend)
- **Cuenta Supabase** con proyecto creado (PostgreSQL + PostGIS habilitado)

### 1. Clonar y configurar

```bash
git clone <repo-url>
cd AS_202620_ElMapita
```

### 2. Configurar variables de entorno

```bash
# Backend
cp backend/.env.example backend/.env
# Editar backend/.env con tus credenciales Supabase:
# SUPABASE_URL=https://tu-proyecto.supabase.co
# SUPABASE_SERVICE_ROLE_KEY=tu-service-role-key
# SUPABASE_ANON_KEY=tu-anon-key
```

### 3. Instalar dependencias

```bash
# Backend
cd backend && npm install

# Frontend
cd ../frontend && flutter pub get
```

### 4. Ejecutar en desarrollo

**Opción A: Script unificado (Linux/macOS/Git Bash)**
```bash
./scripts/dev.sh
```

**Opción B: Script unificado (Windows PowerShell)**
```powershell
.\scripts\dev.ps1
```

**Opción C: Terminales separadas**

*Terminal 1 - Backend:*
```bash
cd backend && npm run start:dev
# Backend en http://localhost:3000
# Swagger en http://localhost:3000/docs
```

*Terminal 2 - Frontend:*
```bash
cd frontend && flutter run
# Selecciona dispositivo/emulador
```

---

## ✅ Verificación (Smoke Tests)

### Backend
```bash
cd backend
npm run test
# Health check: GET http://localhost:3000/health
```

### Frontend
```bash
cd frontend
flutter test
# Widget test: App loads correctly
```

---

## 🧪 Tests

| Proyecto | Comando | Qué prueba |
|----------|---------|------------|
| Backend | `npm run test` | Unit tests (Jest) |
| Backend | `npm run test:e2e` | Integration tests |
| Backend | `npm run test:cov` | Coverage report |
| Frontend | `flutter test` | Unit + Widget tests |
| Frontend | `flutter test integration_test/` | Integration tests |

---

## 📁 Estructura del Repositorio

```
AS_202620_ElMapita/
├── backend/                    # NestJS API
│   ├── src/
│   │   ├── modules/           # Feature modules (Monolito Modular)
│   │   ├── shared/            # Kernel, Supabase client, errors, config
│   │   ├── app.module.ts      # Root module
│   │   ├── main.ts            # Bootstrap + Swagger
│   │   └── health.controller.ts
│   ├── test/                  # E2E tests
│   ├── package.json
│   └── .env.example
├── frontend/                   # Flutter App
│   ├── lib/
│   │   ├── features/          # Feature modules (Monolito Modular)
│   │   ├── core/              # Kernel, DI, Network, Storage, Platform
│   │   ├── shared/            # Widgets, Theme, Extensions
│   │   ├── app.dart           # App root + routing
│   │   └── main.dart          # Entry point + Supabase init
│   ├── test/                  # Unit + Widget tests
│   ├── integration_test/      # Integration tests
│   └── pubspec.yaml
├── docs/
│   ├── arc42/
│   │   └── arc42-template-EN.md       # Documentación arc42 completa
│   ├── adr/
│   │   └── 0001-estilo-arquitectonico-propuesto.md
│   ├── c4/
│   │   └── C4_Contexto.png            # Diagrama C4 Nivel 1
│   └── comparativa-de-arquitecturas.md
├── scripts/
│   ├── dev.sh                   # Startup script (Unix)
│   └── dev.ps1                  # Startup script (Windows)
└── README.md
```

---

## 🔧 Configuración Supabase (Base de Datos)

### Tablas requeridas (SQL)

```sql
-- Extensiones
CREATE EXTENSION IF NOT EXISTS postgis;

-- Edificios
CREATE TABLE edificios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  codigo TEXT UNIQUE NOT NULL,
  geometria GEOMETRY(Polygon, 4326),
  version_modelo_3d TEXT DEFAULT '1.0.0',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Pisos
CREATE TABLE pisos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  edificio_id UUID REFERENCES edificios(id) ON DELETE CASCADE,
  numero INTEGER NOT NULL,
  nombre TEXT,
  modelo_3d_url TEXT,
  modelo_3d_version TEXT DEFAULT '1.0.0',
  altura_metros NUMERIC DEFAULT 3.5,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- POIs
CREATE TABLE pois (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  piso_id UUID REFERENCES pisos(id) ON DELETE CASCADE,
  tipo TEXT CHECK (tipo IN ('salon','laboratorio','bano','cafeteria','biblioteca','escalera','ascensor','otro')),
  nombre TEXT NOT NULL,
  geometria GEOMETRY(Point, 4326),
  metadatos JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices geoespaciales
CREATE INDEX idx_edificios_geom ON edificios USING GIST (geometria);
CREATE INDEX idx_pisos_edificio ON pisos (edificio_id);
CREATE INDEX idx_pois_piso ON pois (piso_id);
CREATE INDEX idx_pois_geom ON pois USING GIST (geometria);

-- RLS Policies (ejemplo)
ALTER TABLE edificios ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read edificios" ON edificios FOR SELECT USING (true);
```

### Storage Buckets

- `modelos-3d` — Archivos `.glb`/`.gltf` de modelos 3D por edificio/versión

---

## 🎯 Aspectos Implementados (Corte Vertical A-01)

| Aspecto | Descripción | Estado |
|---------|-------------|--------|
| **A-01: Mapa 3D + Ubicación** | Visualización interactiva campus 3D, navegación táctil, cambio de piso, POIs, geolocalización con incertidumbre y fallback manual | 🟡 Esqueleto listo |

### Escenarios de Calidad (Trazabilidad)

| ID | Escenario | Criterio | Endpoint/Feature Relacionado |
|----|-----------|----------|------------------------------|
| **EC-01** | Carga inicial mapa 3D < 5s p95 | `GET /api/v1/map/buildings/:id` + descarga modelo | `LoadBuildingUseCase`, `ModelCache` |
| **EC-02** | Fluidez 3D ≥ 30 FPS | Renderizado 3D (Flame/three.dart pendiente) | `MapPage`, `PoiMarker` |
| **EC-03** | Ubicación GPS ±15m o fallback manual < 10s | `LocationService`, `PrecisionIndicator` | `GetLocationUseCase`, `LocationPage` |
| **EC-04** | Modo offline < 5s con caché válida | `ModelCache` (Hive), `LocalStorage` | `LoadBuildingUseCase` con caché |

---

## 📦 Próximos Pasos (Semana 4+)

1. **Implementar renderizado 3D real** con `flame` o `three_dart` en `MapPage`
2. **Conectar Supabase real** configurando credenciales en `.env`
3. **Completar autenticación** flujo completo login/register/refresh
4. **Tests de integración** backend (e2e) y frontend (integration_test)
5. **CI/CD** GitHub Actions para lint, test, build
6. **Corte A-02:** Navegación interior paso a paso (routing)

---

## 📄 Licencia

Proyecto académico - Universidad Tecnológica de Bolívar (UTB)