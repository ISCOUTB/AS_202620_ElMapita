# Registro de Uso de IA — El Mapita UTB

> Trazabilidad del apoyo de IA en el proyecto. Este archivo documenta prompts, artefactos generados y decisiones verificadas.

---

## 2026-08-31 — Sesión de trabajo con Muse Spark (OpenCode)

### Instrucciones del día (resumen)

1. **Análisis del proyecto raíz** — Inventario de `backend` (NestJS), `frontend` (Flutter), `docs` (arc42/ADR/C4) y stack Supabase.
2. **Generar diagramas C4 Nivel 1 y Nivel 2** — Tomando como referencia https://dev.to/ajcastillo/c4-model-documentacion-clara-y-efectiva-para-arquitecturas-de-software-43od (Contexto = ¿Dónde encaja? / Contenedor = ¿Qué contenedores y con qué tecnología?).
3. **Migrar diagramas a Mermaid `.md` y conservar solo PNG** — Eliminar `.puml`/`.svg`, mantener `.png` como artefacto binario.
4. **Minimizar texto del Nivel 1 y regenerar PNG** — Reducir descripciones a etiqueta mínima.
5. **Ajustar Nivel 1: agrupar actores y reubicar externos** — Juntar `Estudiante + Visitante` → `Estudiante / Visitante`, `Docentes + Admin` → `Docente / Admin`; mover `Supabase` y `Ubicación SO` a la parte inferior (debajo de `UTB`).
6. **Forzar externos debajo de UTB Enterprise** — Corregir layout para que `Sistemas Externos` quede estrictamente debajo del boundary `UTB`.
7. **Mantener estilo y formato pero con la ubicación generada** — Conservar `flowchart TB` con `classDef` C4 (person/system/ext) y leyenda.
8. **Generar pipeline de CI** — Crear `.github/workflows/ci.yml` con jobs `backend`/`frontend`/`docs`/`quality-gate` y explicar configuración manual requerida en GitHub/Supabase.
9. **Corregir C1 según checklist** — Etiquetas en relaciones, notación Person vs System estándar, descripción del sistema y leyenda; regenerar PNG.

### Artefactos generados / modificados hoy

| Artefacto | Acción |
|---|---|
| `docs/c4/C4_L1_Context.md` | Creado y refinado 5 veces: PlantUML → Mermaid `C4Context` → `flowchart TB` mínimo → 2 actores → flowchart con `classDef` + etiquetas + descripciones + leyenda |
| `docs/c4/C4_L2_Container.md` | Creado en Mermaid `C4Container` (App Flutter, API NestJS, Hive/Filesystem, Supabase Auth/DB/Storage/Realtime, Ubicación SO) |
| `docs/c4/C4_L1_Context.png` / `C4_L2_Container.png` | Renderizados vía `mermaid.ink` + conversión JPEG→PNG con `Pillow`; validados `137,80,78,71` PNG |
| `docs/c4/contexto.md` | Reescrito como índice N1+N2 con tablas, trazabilidad arc42 y cómo regenerar |
| `docs/arc42/arc42-template-EN.md#3.4` | Actualizado a tabla N1+N2 con links Mermaid |
| `README.md` / `docs/adr/0001-estilo-arquitectonico-propuesto.md` | Referencias C4 actualizadas a `.md`/`.png` |
| `docs/aspectos.md` | Tabla 1 fila A-01 → 4 filas EC-01..EC-04 hasta columna `Pruebas` |
| `.github/workflows/ci.yml` | Pipeline CI con 4 jobs, `concurrency`, `lychee`, verificación C4 y gate EC-01..EC-04 |
| `docs/c4/*.svg` / `*.puml` | Eliminados (solo PNG conservado) |

### Herramientas y verificación

- Render: `https://mermaid.ink/img/<base64>` + `Pillow` para PNG verdadero; `kroki.io/plantuml` probado para PlantUML.
- Validación: `grep "| EC-0" aspectos.md ==4`, `test -f docs/c4/*.png`, `! ls *.svg`, cabecera PNG `89 50 4E 47`.
- Estilo C4 Nivel 1 final: `flowchart TB` con `classDef person #08427B / system #1168BD / ext #999999`, `<<Person>>/<<System>>/<<External>>`, relaciones etiquetadas `Usa / HTTPS` etc., y `subgraph Leyenda`.

---

## 2026-08-30 — Sesión de trabajo con Claude Code

### Instrucciones del día (resumen)

1. **Justificar ADR-0001** — Por qué se adoptó Monolito Modular como estilo arquitectónico.
2. **Profundizar el ADR por secciones** — Contexto, alternativas, decisión y consecuencias.
3. **Comparar frente a Hexagonal** — Por qué no se eligió Hexagonal aun con mayor puntaje (68 vs 67).
4. **Contextualizar la aplicación** — arc42 S1-S3 + descripción breve del proyecto.
5. **Consolidar en documento de resumen** — Word con todo lo anterior.

### Artefactos y resultados

| Resultado | Contenido clave |
|---|---|
| **ADR-0001: Monolito Modular** | Backend NestJS + Frontend Flutter por feature (`mapas`, `ubicacion`, `auth`, `pois`) con capas `domain / application / infrastructure`. Contexto: equipo 3 junior/medio (onboarding días), Supabase con riesgo lock-in, testabilidad 3D/Geo sin device farm, entrega con un solo comando. |
| **Alternativas** | Capas: overhead mínimo pero acopla Supabase y mezcla 3D/Geo → tests frágiles. Hexagonal: aislamiento total y tests deterministas pero curva alta + boilerplate excesivo. Monolito Modular: ownership por feature, fakes en `domain`, Supabase en `infrastructure`, carpetas conocidas. |
| **Consecuencias** | Positivas: onboarding rápido, EC-01/02/03 testeables, Supabase aislado, paralelismo 3 devs, OpenAPI, deploy simple (1 contenedor + build Flutter). Trade-offs: disciplina de límites (ESLint boundaries), riesgo `shared kernel` descontrolado, no es DDD puro. |
| **Matriz comparativa** | Capas 51 · Hexagonal 68 · Monolito Modular 67 (`docs/comparativa-de-arquitecturas.md`). No se siguió el puntaje literal: C1/C4 Hexagonal 2/5 implica 1-2 sprints perdidos; A-01 Semana 4 hace el retraso no lineal; Monolito ya cubre C2/C3 suficiente (3/4 vs 5/5 = suficiente vs excelente); 10-15% de pureza no compensa riesgo. |
| **Contexto arc42 S1-S3** | **S1:** App móvil mapa 3D + POIs + ubicación; corte A-01/RF-01. **S2:** 4 interesados (estudiante principal, visitante, docente/admin, equipo) y 4 objetivos (orientación, rendimiento 3D, disponibilidad, privacidad). **S3:** Límites App + API; externos Supabase (Auth/DB PostGIS/Storage/Realtime) + SO Location; RES-01 arc42/C4/ADR, RES-02 GPS indoor, RES-03 conectividad; técnico Flutter ↔ HTTPS/JSON ↔ NestJS ↔ Supabase (frontera credenciales). |
| **Descripción breve** | Navegación interior 3D UTB, monolito modular sobre Supabase, A-01: carga/navegación .glb por piso, POIs, geolocalización con incertidumbre + fallback manual, caché offline; proyecto académico 3 devs con arc42/C4/ADR. |
| **Documento** | Word de resumen consolidado con los 3 resultados anteriores. |

### Conclusión de la sesión

Criterio pragmático: no optimizar por pureza técnica sino por viabilidad real de 3 junior/medio en plazo A-01, sin sacrificar testabilidad ni aislamiento de Supabase — Monolito Modular equilibra ambos frentes.

### Fuentes

`docs/adr/0001-estilo-arquitectonico-propuesto.md` · `docs/arc42/arc42-template-EN.md` S1-S3 · `docs/comparativa-de-arquitecturas.md`
