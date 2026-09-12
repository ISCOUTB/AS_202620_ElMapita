# Registro de Uso de IA — El Mapita UTB

> Trazabilidad del apoyo de IA en el proyecto. Este archivo documenta prompts, artefactos generados y decisiones verificadas.

---

## 2026-09-12 — Sesión de trabajo con Claude Code

### Instrucciones del día (resumen)

1. **Crear un glosario de términos del proyecto** — Diccionario en `docs/glosario.md` con las palabras más prudentes del dominio, la arquitectura y el proceso, sin notas ni comentarios, en el mismo formato de tabla que el glosario existente en `docs/arc42/arc42-template-EN.md` sección 12 (al que amplía sin contradecirlo). Las definiciones se verificaron contra la evidencia real del repositorio: tipos de dominio (`backend/src/modules/*/domain/index.ts`, `frontend/lib/features/*/domain/entities.dart`), `shared/kernel`, ADRs, `aspectos.md` y `.github/workflows/ci.yml`.
2. **Crear una tabla de módulos en Word** — Documento con dueño único y no conformidades por módulo. Antes de escribirlo se verificó cada hallazgo directamente contra el código (conteo exacto de `any` en los adaptadores de Supabase, archivos de prueba existentes, discrepancia de rutas REST documentadas vs. reales, `FLUTTER_VERSION` de `ci.yml` vs. `pubspec.yaml`/`pubspec.lock`, módulo `campus` no documentado, módulo `pois` del frontend incompleto) para que cada fila tuviera evidencia trazable a archivo y línea.
3. **Convertir también el glosario a `.docx`** — A pedido del usuario, para poder abrirlo y corregirlo en Word.

### Artefactos y resultados

| Resultado | Contenido clave |
|---|---|
| **`docs/glosario.md`** | Diccionario de 121 términos en 9 secciones (dominio y negocio, entidades y tipos del modelo, arquitectura y patrones, documentación arquitectónica, identificadores del proyecto, tecnologías y herramientas, 3D y rendimiento, geolocalización, proceso y evaluación) |
| **`docs/glosario.docx`** | Mismo contenido que `docs/glosario.md`, generado a partir de él (fuente única) con `python-docx`, con encabezados por sección y tabla Término/Definición en cada una |
| **`docs/TablaModulos_ElMapitaUTB.docx`** | Tabla 1: 13 filas módulo × capa (auth, mapas, pois, ubicacion, campus, shared/core, infraestructura-CI/CD, documentación) con ruta, dueño único propuesto y no conformidades. Tabla 2: catálogo NC-01…NC-12 con descripción y evidencia archivo:línea. Tabla 3: resumen de no conformidades por dueño |
| **`docs/ia.md`** | Esta entrada |

### Decisiones y aclaraciones

- **Dueño único por módulo:** no existe `CODEOWNERS` ni nombres explícitos por "Dev N" en el repositorio; la asignación propuesta en `docs/TablaModulos_ElMapitaUTB.docx` parte del reparto ya declarado en `docs/adr/0001-estilo-arquitectonico-propuesto.md` ("Dev 1: `mapas` + `pois` | Dev 2: `ubicacion` + `auth` | Dev 3: `core`/`shared` + CI/CD + adaptador de render 3D"), cruzado con la autoría real en `git log`. Queda marcada en el propio documento como propuesta corregible por el equipo.
- **Granularidad de la tabla de módulos:** una fila por módulo y por capa de despliegue (backend/frontend por separado), en vez de una fila unificada por módulo funcional, para reflejar fielmente la estructura real del código.
- **Herramienta de generación de `.docx`:** Python 3.13 + `python-docx` (ya instalados en el equipo), invocado con ruta absoluta al ejecutable porque el alias de Microsoft Store intercepta `python` en el PATH de Windows. El script generador no se versionó en el repositorio, solo los `.docx` resultantes.

### Conclusión de la sesión

Se agregaron tres artefactos nuevos de documentación (`docs/glosario.md`, `docs/glosario.docx`, `docs/TablaModulos_ElMapitaUTB.docx`) sin modificar código, configuración ni documentos existentes. Ningún archivo fue comiteado en esta sesión; queda pendiente que el equipo revise y corrija el contenido en Word antes de integrarlo al repositorio.

### Fuentes

`docs/arc42/arc42-template-EN.md` · `docs/aspectos.md` · `docs/adr/0001-estilo-arquitectonico-propuesto.md` · `docs/adr/0002-restriccion-rendimiento-compatibilidad-dispositivos.md` · `correcciones.md` · `.github/workflows/ci.yml` · `backend/src/modules/*/domain/index.ts` · `frontend/lib/features/*/domain/entities.dart`

---

## 2026-09-07 — Sesión de trabajo con Claude Code

### Instrucciones del día (resumen)

1. **Diagnosticar la matriz de correcciones del corte 1** — El docente evaluó 12 criterios; 8 en "No cumple" y 3 en "No verificado". Se auditó cada uno contra el estado real del repositorio antes de responder.
2. **Verificar el tag `corte-1` contra la observación del docente** — `git ls-remote --tags origin` confirma que el tag existe local y remotamente sobre el commit `d3be514`; la observación de que "no existe ninguna etiqueta" es incorrecta. Se distingue explícitamente el *mensaje* de commit `corte-1` (en `4806374`) de la *etiqueta* Git `corte-1` (en `d3be514`).
3. **Verificar el PDF versionado** — `git ls-files docs/cortes/` confirma `docs/cortes/corte-1.pdf` (274 445 bytes) tracked en el repositorio; la observación de que no existe es incorrecta.
4. **Diagnosticar la causa raíz del pipeline en rojo** — Vía `gh run view --log-failed` sobre la corrida `33520904103`: el job frontend falla en `flutter pub get` porque `.github/workflows/ci.yml` fija `FLUTTER_VERSION: "3.22.0"` (Dart 3.4) contra `frontend/pubspec.yaml` (`sdk: ^3.12.0`) y `frontend/pubspec.lock` (`flutter >=3.44.0`); el job backend falla en `npm run lint` porque `tseslint.configs.recommendedTypeChecked` marca como error ~10 usos de `any` en los adaptadores de Supabase (`supabase-repositories.ts`, controllers). Por decisión del equipo, no se corrige código ni configuración en este corte — el diagnóstico completo queda registrado en `correcciones.md` como deuda declarada.
5. **Formalizar la restricción de rendimiento como reto del corte (RES-04)** — El equipo propone que la app funcione en el mayor rango posible de dispositivos móviles, incluyendo gama de entrada. Se documentó en `docs/arc42/arc42-template-EN.md` sección 2 junto con su impacto en requisitos (EC-01/EC-02), límites C4 (sin cambios) y código (deuda pendiente).
6. **Redactar el ADR-0002** — Registrar la decisión de arquitectura que gobierna RES-04 (LOD + degradación progresiva a vista esquemática), contrastada contra dos alternativas, enlazando con el riesgo ya declarado RSK-02.
7. **Reescribir `correcciones.md` como documento formal de réplica y deuda declarada** — Responder los 12 criterios de la matriz: rebatir 1 y 2 con evidencia ejecutable, señalar 3/5/7/11 como resueltos por los artefactos de hoy, y justificar técnicamente por qué 4/6/8/9/10 quedan pendientes sin tocar código en esta etapa de pruebas.

### Artefactos y resultados

| Resultado | Contenido clave |
|---|---|
| **`docs/arc42/arc42-template-EN.md`** | Fila `RES-04` en la tabla de restricciones (sección 2) + subsección "Impacto de RES-04" (requisitos, C4, código) |
| **`docs/adr/0002-restriccion-rendimiento-compatibilidad-dispositivos.md`** | ADR nuevo: LOD + degradación progresiva como estrategia para RES-04, alternativas contrastadas, consecuencias con estado de implementación pendiente declarado explícitamente |
| **`correcciones.md`** | Reescrito de un borrador de 4 líneas a la réplica formal y tabla de deuda declarada para los 12 criterios de la matriz |
| **`docs/ia.md`** | Esta entrada |

### Conclusión de la sesión

Ningún archivo de código, configuración ni CI fue modificado en esta sesión — se acordó explícitamente con el equipo mantener el alcance en documentación mientras el proyecto sigue en etapa de estabilización del esqueleto. Los criterios que exigen código o mediciones (4, 6, 8, 9, 10) quedan como deuda declarada con diagnóstico técnico verificable, no como omisiones sin explicar.

### Fuentes

`docs/aspectos.md` · `docs/arc42/arc42-template-EN.md` · `docs/adr/0001-estilo-arquitectonico-propuesto.md` · `.github/workflows/ci.yml` · `correcciones.md`

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
