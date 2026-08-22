---
date: Agosto 2026
title: "Matriz Comparativa de Estilos Arquitectónicos — El Mapita UTB"
---

# Matriz Comparativa: Capas vs. Hexagonal vs. Monolito Modular

> **Contexto:** Aplicación móvil Flutter + API NestJS (TypeScript) para mapa 3D interactivo de campus UTB con geolocalización, POIs, caché offline y sincronización Supabase. Equipo: 3 desarrolladores. Corte vertical inicial: A-01 (mapa 3D + ubicación).

---

## Criterios de Evaluación

| # | Criterio | Descripción | Peso |
|---|----------|-------------|------|
| C1 | **Facilidad de desarrollo (equipo 3 personas)** | Curva de aprendizaje, onboarding, productividad inmediata, bajo overhead de coordinación | **Alto** |
| C2 | **Acoplamiento con Supabase** | Grado de dependencia directa al SDK/cliente de Supabase; facilidad para mockear, testear o migrar | **Alto** |
| C3 | **Testabilidad del renderizado 3D / geolocalización** | Aislamiento de lógica de negocio de Flutter widgets, platform channels, GPS nativo, WebGL/Flame/three.dart | **Alto** |
| C4 | **Curva de aprendizaje** | Tiempo para que el equipo sea productivo; complejidad conceptual vs. pragmatismo | **Medio** |
| C5 | **Escalabilidad y evolución** | Capacidad de crecer en módulos (nuevos features: routing, AR, analytics) sin reestructurar | **Medio** |
| C6 | **Separación frontend/backend** | Claridad de contratos, independencia de despliegue, ownership de equipos | **Medio** |
| C7 | **Mantenibilidad a largo plazo** | Localización de cambios, bajo acoplamiento, alta cohesión, deuda técnica controlada | **Medio** |

Escala de puntuación: **5 = Muy favorable**, **3 = Neutral / Aceptable**, **1 = Desfavorable**

---

## Comparativa Detallada

| Criterio | **Arquitectura en Capas (Layered)** | **Arquitectura Hexagonal (Ports & Adapters)** | **Monolito Modular (Modular Monolith)** |
|----------|--------------------------------------|-----------------------------------------------|------------------------------------------|
| **C1: Facilidad desarrollo (3 pers.)** | **5** — Estructura conocida, separación clara Controller/Service/Repository, bajo overhead, onboarding rápido | **2** — Conceptos (puertos/adaptadores, domain-driven) requieren disciplina y discusión inicial; más boilerplate | **4** — Módulos por feature (mapas, ubicacion, auth) son intuitivos; cada dev puede owning un módulo; shared kernel mínimo |
| **C2: Acoplamiento Supabase** | **2** — Repositories acoplados a Supabase client; difícil mockear sin abstracción extra; migración costosa | **5** — Puerto `SupabaseRepository` + adaptador real; dominio puro sin dependencia a Supabase; testable con fakes en memoria | **3** — Módulo `infrastructure/supabase` encapsula cliente; dominio usa interfaces; pero módulos internos pueden filtrar dependencias si no hay disciplina |
| **C3: Testabilidad 3D / Geo** | **2** — Servicios mezclan lógica de negocio + llamadas a platform channels; widgets difíciles de testear unitariamente | **5** — Casos de uso (application) puros; puertos `LocationProvider`, `MapRenderer`; fakes deterministas para GPS, sensores, frames 3D | **4** — Módulo `domain` con puertos; `infrastructure` con adaptadores Flutter/Platform; tests unitarios en domain; tests de integración en infrastructure |
| **C4: Curva de aprendizaje** | **5** — Patrones familiares (MVC-ish); cualquier dev junior lo entiende en días | **2** — DDD táctico, puertos/adaptadores, inversión de dependencias; requiere mentoría o estudio previo | **4** — Estructura por features conocida (feature folders); límites de módulo claros; menos dogma que Hexagonal |
| **C5: Escalabilidad / evolución** | **2** — Capas transversales crecen juntas; changes en dominio afectan múltiples capas; "spaghetti" risk | **5** — Dominio estable; nuevos adaptadores (p.ej. nuevo proveedor mapas, nuevo auth) sin tocar dominio; módulos aislados | **4** — Nuevos features = nuevos módulos; shared kernel controlado; refactor a microservicios viable si crece |
| **C6: Separación FE/BE** | **3** — Backend layered; frontend suele ser "capas por tipo" (widgets, models, services) — no siempre alineadas | **4** — Ambos lados pueden usar hexagonal; contratos via puertos compartidos (DTOs); alineación natural | **5** — **Backend**: módulos NestJS (`@Module`) por feature. **Frontend**: `lib/features/*` + `lib/shared`; contratos OpenAPI compartidos; ownership por feature end-to-end |
| **C7: Mantenibilidad** | **2** — Acoplamiento horizontal (services llaman services); cambios propagados; tests de integración pesados | **5** — Dominio inmutable; adaptadores intercambiables; tests unitarios rápidos; cambios localizados | **4** — Límites de módulo enforcados (public API, private internals); tests por módulo; shared kernel versionado |

---

## Puntuación Ponderada

| Criterio | Peso | Capas | Hexagonal | Monolito Modular |
|----------|------|-------|-----------|------------------|
| C1 Facilidad desarrollo | Alto (3) | 5×3=**15** | 2×3=**6** | 4×3=**12** |
| C2 Acoplamiento Supabase | Alto (3) | 2×3=**6** | 5×3=**15** | 3×3=**9** |
| C3 Testabilidad 3D/Geo | Alto (3) | 2×3=**6** | 5×3=**15** | 4×3=**12** |
| C4 Curva aprendizaje | Medio (2) | 5×2=**10** | 2×2=**4** | 4×2=**8** |
| C5 Escalabilidad | Medio (2) | 2×2=**4** | 5×2=**10** | 4×2=**8** |
| C6 Separación FE/BE | Medio (2) | 3×2=**6** | 4×2=**8** | 5×2=**10** |
| C7 Mantenibilidad | Medio (2) | 2×2=**4** | 5×2=**10** | 4×2=**8** |
| **TOTAL** | — | **51** | **68** | **67** |

---

## Análisis Cualitativo para El Mapita

| Estilo | Fortalezas para este proyecto | Riesgos / Debilidades |
|--------|-------------------------------|------------------------|
| **Capas** | ✅ Arranque inmediato, cero fricción conceptual, ideal para MVP rápido<br>✅ Equipo pequeño no necesita over-engineering | ❌ Supabase acoplado en repositorios → tests frágiles, migración dolorosa<br>❌ Lógica 3D/Geo mezclada con framework → tests lentos, flaky<br>❌ Escalabilidad limitada; technical debt crece rápido |
| **Hexagonal** | ✅ Dominio puro = tests unitarios rápidos y deterministas (crítico para GPS/3D)<br>✅ Supabase tras puerto → migración/mock trivial<br>✅ Separación FE/BE alineada por contratos (puertos compartidos) | ❌ Curva alta: 3 devs junior/medios pierden 1-2 sprints en "hacerlo bien"<br>❌ Boilerplate excesivo para MVP (puertos, adaptadores, mappers)<br>❌ Overhead de coordinación: decisiones de diseño en cada feature |
| **Monolito Modular** | ✅ **Equilibrio pragmático**: módulos por feature (mapas, ubicacion, auth, pois) = ownership claro<br>✅ **Testabilidad**: domain/infrastructure separados dentro de cada módulo = tests unitarios + fakes<br>✅ **Supabase encapsulado**: módulo `supabase-adapter` o `infrastructure` por módulo<br>✅ **Onboarding rápido**: estructura `features/` conocida en Flutter/NestJS<br>✅ **Evolución**: nuevo feature = nuevo módulo; shared kernel mínimo (`lib/core`, `src/shared`)<br>✅ **Despliegue**: un solo artefacto backend + uno frontend; CI simple | ⚠️ Requiere **disciplina de límites**: no importar `private` de otros módulos (enforcar con ESLint/ArchUnit)<br>⚠️ Shared kernel puede crecer sin control → revisar en retrospectivas<br>⚠️ No es "puro" DDD; dominio puede filtrar en application si no hay code review |

---

## Recomendación: **Monolito Modular** (para Backend NestJS y Frontend Flutter)

**Justificación ejecutiva:**

1. **Equipo de 3 personas** → Monolito Modular da ownership por feature sin overhead de coordinación de Hexagonal. Capas es más simple pero sacrifica testabilidad y acoplamiento Supabase (críticos para EC-01/EC-02/EC-03).
2. **Supabase como backend-as-a-service** → Encapsular cliente en módulo `infrastructure` por feature (o shared `supabase-client`) da aislamiento práctico sin purismo de puertos.
3. **Testabilidad 3D/Geo (EC-01, EC-02, EC-03)** → Módulos `domain` con puertos `LocationProvider`, `MapModelLoader`, `PoiRepository` permiten fakes deterministas. Tests unitarios corren en ms; tests de integración solo en CI.
4. **Curva de aprendizaje** → Estructura `features/` es idiomática en Flutter (package `very_good_analysis`, `flutter_modular`) y NestJS (`@Module` por feature). Equipo productivo desde día 1.
5. **Evolución realista** → Próximos cortes: routing interior (A-02), AR (A-03), analytics (A-04). Cada uno = nuevo módulo. Si el proyecto crece >10 devs, refactor a microservicios es viable (módulos ya desacoplados).
6. **Contratos FE/BE** → OpenAPI generado desde NestJS DTOs + `openapi-generator` para Dart = tipos compartidos, breaking changes detectados en CI.

> **Decisión registrada en:** [`adr/0001-estilo-arquitectonico-propuesto.md`](adr/0001-estilo-arquitectonico-propuesto.md)