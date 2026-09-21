# Registro de Uso de IA — El Mapita UTB

> Trazabilidad del apoyo de IA en el proyecto. Este archivo documenta prompts, artefactos generados y decisiones verificadas.

---

## 2026-09-13 — Sesión de trabajo con Antigravity

### Instrucciones del día (resumen)

1. **Revisar y estructurar la carpeta `docs/c4` (C4 Nivel 3 — Diagrama de Componentes)** — Revisar y expandir el contenedor `Backend API` (NestJS) por módulos funcionales (`Auth`, `Mapas`, `POIs`, `Ubicación`) y capas arquitectónicas sencillas y claras para entorno escolar (Controladores REST $\rightarrow$ Servicios de Negocio $\rightarrow$ Entidades $\rightarrow$ Adaptadores de Datos).
2. **Generar y refinar el render gráfico PNG (`C4_L3_Component_Backend.png`)** — Diseñar la disposición visual sin solapamientos ni desbordamientos de bordes. Asegurar que el 100% de los componentes del backend queden encapsulados dentro del límite del contenedor `Backend API [Contenedor]`, ubicando los sistemas externos (`Supabase Cloud` y `Plataforma Ubicación SO`) a la derecha.
3. **Limpieza de archivos y formatos** — Eliminar archivos borradores en SVG (`.svg`) manteniendo únicamente archivos `.md` e imágenes `.png`. Reemplazar cualquier ruta absoluta local (`file:///d:/...`) en el código Markdown por rutas relativas limpias del proyecto (`backend/src/...`).
4. **Verificación técnica de trazabilidad contra el código** — Comprobar y justificar que cada uno de los componentes/cuadrados en el diagrama responde a una necesidad real de la aplicación **El Mapita UTB** y se mapea a un archivo de código existente en `backend/src/...`.
5. **Integración y sincronización Git** — Realizar commit local, merge automático con los cambios concurrentes de la rama `origin/main` y push exitoso al repositorio remoto.

### Artefactos y resultados

| Resultado | Contenido clave |
|---|---|
| **`docs/c4/C4_L3_Component_Backend.png`** | Diagrama C4 Nivel 3 renderizado en PNG de alta resolución con diseño por capas y módulos impecables sin cruces. |
| **`docs/c4/C4_L3_Component_Backend.md`** | Documentación especificación del C4 Nivel 3 con el render PNG incrustado directamente y tabla de trazabilidad 1:1 hacia el código en `backend/src/...`. |
| **`docs/c4/contexto.md`** | Índice general del Modelo C4 actualizado para integrar el Nivel 3 junto con Nivel 1 y Nivel 2. |
| **`docs/ia.md`** | Esta entrada de registro de IA. |

### Decisiones y aclaraciones

- **Formato gráfico único (PNG):** A petición del usuario, se descartó el formato vectorial `.svg` y los bloques de código textual de Mermaid no compatibles en visores estándar, dejando como artefacto visual oficial el render `.png`.
- **Adaptación a ámbito escolar:** Se simplificó la terminología de arquitectura limpia (reemplazando jerga como *Shared Kernel* o *Domain Entities*) por nombres directos y explicables para evaluación escolar (`Controladores REST`, `Servicios de Negocio`, `Entidades de Dominio`, `Adaptadores de Infraestructura`, `Configuración y Cliente Supabase`).
- **Rutas de código limpias:** Se sustituyeron las URLs de archivos locales de Windows por rutas relativas puras dentro del repositorio (`backend/src/...`).

### Fuentes

`backend/src/...` · `docs/c4/C4_L1_Context.md` · `docs/c4/C4_L2_Container.md` · `docs/c4/contexto.md` · `README.md`

---

## 2026-09-13 — Sesión de trabajo con Claude Code

### Instrucciones del día (resumen)

1. **Reescribir por completo `docs/TablaModulos_ElMapitaUTB.docx`** — Reemplazar el catálogo de no conformidades inventado el día anterior por una lista real de 10 hallazgos (H-01…H-10) reportados por el panel de análisis estático de seguridad y confiabilidad del repositorio ("Security snapshot" / "Reliability snapshot"), suministrada íntegramente por el usuario.
2. **Verificar cada hallazgo contra el código antes de escribirlo** — Se abrió cada archivo y línea señalados (`.github/workflows/ci.yml`, `frontend/android/app/build.gradle.kts`, `frontend/android/app/src/main/AndroidManifest.xml`, `frontend/android/build.gradle.kts`, `scripts/dev.sh`, `frontend/web/index.html`) para confirmar que el patrón reportado existe realmente antes de incluirlo en el documento.
3. **Clasificar cada hallazgo como corrección real o falso positivo** — Para los reales, redactar un plan de corrección técnico y accionable; para los que resultaran falsos positivos, redactar una justificación en su lugar.
4. **Dar formato académico al documento** — Títulos y subtítulos en negro (no en el azul institucional usado el día anterior), formato de reporte sobrio.

### Artefactos y resultados

| Resultado | Contenido clave |
|---|---|
| **`docs/TablaModulos_ElMapitaUTB.docx`** (reescrito por completo) | Tabla 1: 14 filas módulo × capa con dueño único; la columna "Hallazgos" ahora referencia los códigos H-01…H-10 en las dos únicas filas donde aplican (`infraestructura/CI-CD` y la nueva fila `configuración de plataforma Android/Web`), y "Sin hallazgos en este corte" en el resto. Tabla 2: resumen de hallazgos por dueño. Sección 3: ficha individual por hallazgo (archivo, línea, severidad, esfuerzo, descripción y plan de corrección o justificación) |
| **`docs/ia.md`** | Esta entrada |

### Hallazgos verificados y su clasificación

| Código | Archivo | Severidad | Clasificación |
|---|---|---|---|
| H-01 | `.github/workflows/ci.yml` L90 | Alta (Seguridad) | Corrección real — pin del hash SHA de `subosito/flutter-action` |
| H-02 | `.github/workflows/ci.yml` L134 | Alta (Seguridad) | Corrección real — pin del hash SHA de `lychee-action` |
| H-03 | `frontend/android/app/build.gradle.kts` L29 | Alta (Seguridad) | Corrección real — habilitar ofuscación/minificación en `release` |
| H-04 | `.github/workflows/ci.yml` L44 | Media (Seguridad) | Corrección real — `npm ci --ignore-scripts` (verificado: sin scripts `prepare`/`postinstall` en `backend/package.json`) |
| H-05 | `.github/workflows/ci.yml` L100 | Media (Seguridad) | Corrección real — `flutter pub get --enforce-lockfile` |
| H-06 | `AndroidManifest.xml` L2 | Media (Seguridad) | Corrección real — declarar `android:allowBackup="false"` explícitamente |
| H-07 | `frontend/android/build.gradle.kts` | Media (Seguridad) | Corrección real — falta `gradle.lockfile` |
| H-08 | `AndroidManifest.xml` L2 | Baja (Seguridad) | Corrección real — se comprobó que agrava el riesgo: `dio_client.dart` usa `http://localhost:3000/api` como URL base por defecto y `ci.yml` no la sobreescribe en el build web |
| H-09 | `scripts/dev.sh` L21, L26, L32, L64 | Alta (Confiabilidad) | **Falso positivo** — las cuatro variables evaluadas con `[ ]` están citadas o son un contador numérico seguro; sin escenario de falla real en este script de desarrollo local |
| H-10 | `frontend/web/index.html` L1 | Media (Confiabilidad) | Corrección real — falta atributo `lang` en `<html>` (WCAG 2.1 3.1.1) |

### Decisiones y aclaraciones

- **Mapeo de hallazgos a módulos/dueños:** ninguno de los 10 hallazgos toca código de dominio de `auth`/`mapas`/`pois`/`ubicacion`/`campus`; todos están en configuración de CI/CD o de plataforma (Android/Web), que ADR-0001 ya asigna a "Dev 3" (Angel Fabian Gutierrez Gomez). Se agregó una fila nueva a la Tabla 1, "configuración de plataforma (Android / Web)", para no forzar estos hallazgos dentro de una fila de módulo funcional a la que no pertenecen.
- **Único falso positivo (H-09):** se documentó con justificación técnica verificada línea por línea, en vez de un plan de corrección, siguiendo la instrucción explícita del usuario de distinguir hallazgos reales de falsos errores.
- **Se descartó** un catálogo de no conformidades anterior (redactado el 2026-09-12 a partir de inspección manual del código) al no ser la fuente que el usuario pidió reflejar en este documento; ese catálogo permanece únicamente en el historial de esta conversación, no en el repositorio.

### Conclusión de la sesión

Se reescribió `docs/TablaModulos_ElMapitaUTB.docx` en su totalidad a partir de una fuente externa (panel de análisis estático) verificada contra el código real, no comiteado todavía. `docs/glosario.md` y `docs/glosario.docx` no se modificaron en esta sesión.

### Fuentes

Panel de análisis estático de seguridad y confiabilidad del repositorio (snapshot suministrado por el usuario) · `.github/workflows/ci.yml` · `frontend/android/app/build.gradle.kts` · `frontend/android/app/src/main/AndroidManifest.xml` · `frontend/android/build.gradle.kts` · `frontend/lib/core/network/dio_client.dart` · `scripts/dev.sh` · `frontend/web/index.html` · `backend/package.json` · `docs/adr/0001-estilo-arquitectonico-propuesto.md`

### Ajuste de formato posterior (misma sesión)

Tras la primera versión de la Sección 3, se corrigió un detalle menor de redacción en la ficha de cada hallazgo: el encabezado mostraba "(línea L90)" en vez de "(L90)" (la etiqueta "línea" quedaba duplicada con el prefijo "L" del propio dato), y el hallazgo H-07 (sin línea específica) mostraba "(línea —)" en vez de omitir el paréntesis. Se regeneró `docs/TablaModulos_ElMapitaUTB.docx` con ambos ajustes; el contenido técnico de los 10 hallazgos no cambió.

### Incidencia detectada y corregida: `docs/glosario.docx` desaparecido del disco

Al revisar el estado de `docs/` tras la reescritura de `TablaModulos_ElMapitaUTB.docx`, se detectó que `docs/glosario.docx` — comiteado por el usuario el 2026-09-12 en el commit `3bdc57d` ("actualizacion de documentos para S06") — ya no existía en el sistema de archivos, aunque seguía tracked en Git (aparecía como `deleted` en `git status`). Esta sesión no había tocado ese archivo. Se restauró de forma no destructiva con `git checkout HEAD -- docs/glosario.docx`, recuperando exactamente el contenido ya comiteado, sin pérdida de información. Con esto, la afirmación de la sección "Conclusión de la sesión" de que `docs/glosario.docx` "no se modificó en esta sesión" se mantiene válida en cuanto a contenido (se recuperó el mismo binario comiteado, no se generó uno nuevo).

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

---

## 2026-09-20 — Sesión de trabajo con Claude Code

### Instrucciones del día (resumen)

1. **Elegir entre OpenAPI y AsyncAPI versionado** para el contrato de integración FE-BE, con contexto de la presentación "Introducción a WWW" del curso.
2. **Escribir el contrato versionado** como archivo en el repositorio (no solo Swagger en memoria).
3. **Añadir prueba de contrato en el pipeline** (CI).
4. **Redactar un ADR que justifique la estrategia de integración elegida.**

### Exploración previa a la propuesta

Antes de proponer un plan, se inspeccionó el backend real (`backend/src/main.ts`, los 5 controladores, `package.json`, `.github/workflows/ci.yml`) para fundamentar la elección en el código existente, no en una preferencia genérica. Esa exploración encontró que el frontend (`dio_client.dart` + `*_api.dart`) y el backend estaban desalineados en producción: el backend expone `/api/api/v1/...` y `/api/health` (prefijo `api` duplicado por `setGlobalPrefix` + prefijo de controlador) donde el frontend y la documentación (README, C4 Nivel 3) esperan `/api/v1/...` y `/health`.

### Decisiones tomadas con el usuario (`AskUserQuestion`)

- **Estándar:** OpenAPI 3.1 (no AsyncAPI) — la integración real es 100% REST síncrona; AsyncAPI se reserva para cuando Supabase Realtime deje de ser deuda (ADR-0002).
- **Profundidad de la prueba de contrato:** las tres capas (lint del contrato, deriva contrato↔código generado desde NestJS, y contrato↔runtime real con fakes sobre los puertos ya desacoplados por DEC-02).
- **Desajuste de prefijo de ruta encontrado:** documentar como deuda (RSK-04), sin corregir código de la aplicación en esta entrega.

### Artefactos y resultados

| Resultado | Contenido clave |
|---|---|
| **`docs/api/openapi.v1.yaml`** | Contrato OpenAPI 3.1 con las 16 operaciones reales de los 5 controladores, schemas derivados de los tipos de dominio existentes (`backend/src/modules/*/domain/index.ts`), regla de versionado MAJOR/MINOR/PATCH. |
| **`docs/api/README.md`** | Índice del contrato: regla de versionado, cómo correr las 3 capas de verificación en local, estado de RSK-04. |
| **`docs/adr/0003-contrato-openapi-versionado.md`** | ADR con la justificación completa: alternativas consideradas (statu quo, OpenAPI contract-first, AsyncAPI, code-first puro), decisión y consecuencias, incluyendo el hallazgo de deriva como evidencia. |
| **`backend/scripts/generate-openapi.ts`, `check-openapi-drift.ts`** | Generan el documento real desde los decoradores de NestJS (mismo bootstrap que `main.ts`) y lo comparan contra el contrato. |
| **`backend/test/contract/openapi.contract-spec.ts`** | Levanta la app completa con fakes sobre los 6 puertos hacia Supabase, ejerce las 16 rutas del contrato con supertest y valida respuestas con Ajv (JSON Schema 2020-12). Corrida localmente: falla en las 16, confirmando la deriva de prefijo — resultado esperado. |
| **`.github/workflows/ci.yml`** | Job `contract` nuevo (lint bloqueante + deriva/runtime informativos mientras RSK-04 esté abierto), agregado a `quality-gate.needs`. |
| **Trazabilidad** | `docs/arc42/arc42-template-EN.md` (DEC-07, RSK-04), `docs/glosario.md` (ADR-0003, OpenAPI, AsyncAPI, Ajv, Redocly CLI, contrato de API, deriva de contrato, prueba de contrato), `docs/aspectos.md` (sección de contrato del aspecto A-01), `correcciones.md` (deuda RSK-04 y criterio de cierre). |

### Decisiones y aclaraciones

- El PDF de origen (`Introducción a WWW.pdf`, en Descargas del usuario) no pudo abrirse por un nombre de archivo con acento en forma Unicode descompuesta que ninguna herramienta local resolvió; se contextualizó la elección directamente con el código del proyecto en su lugar.
- Se validó el contrato con `npx @redocly/cli lint` (0 errores, 14 advertencias de estilo no bloqueantes) y se ejecutaron las tres capas de verificación localmente antes de cerrar la sesión, confirmando que reproducen exactamente la deriva documentada.

### Seguimiento — lectura de la presentación fuente (mismo día)

El usuario renombró el archivo a `Introduccion a WWW.pdf` (sin tilde), lo que permitió leerlo. Contenido: "Arquitecturas de Aplicaciones Web — HTTP y WWW" (Jairo Serrano, PhD., UTB) — ciclo de petición/respuesta cliente-servidor, métodos HTTP (GET/POST/PUT/DELETE/HEAD), códigos de estado por familia (1xx-5xx) e introducción a Flask.

**Conclusión:** el material es fundamento conceptual de HTTP (no trata contratos de API versionados ni OpenAPI/AsyncAPI), por lo que confirma sin contradecir la decisión ya tomada — el contrato (`openapi.v1.yaml`) documenta exactamente esos mismos elementos (método, ruta, código de respuesta por familia) para cada operación real del backend. No se modificó ningún artefacto de la entrega a raíz de esta lectura.

### Fuentes

`backend/src/main.ts` · `backend/src/modules/*/interfaces/*.controller.ts` · `backend/src/modules/*/domain/index.ts` · `frontend/lib/core/network/dio_client.dart` · `frontend/lib/features/mapas/infrastructure/api/mapas_api.dart` · `docs/adr/0001-estilo-arquitectonico-propuesto.md` · `docs/adr/0002-restriccion-rendimiento-compatibilidad-dispositivos.md` · `.github/workflows/ci.yml` · `Introduccion a WWW.pdf` (presentación del curso, Jairo Serrano PhD.)
