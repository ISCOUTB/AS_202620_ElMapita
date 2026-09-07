# Correcciones y réplica — Corte 1 (El Mapita UTB)

> Responde a la matriz de evaluación del corte 1, sobre el commit `4806374` ("corte-1") y el tag `corte-1` (apuntando a `d3be514`). Fecha: 2026-09-07.

Cada criterio se responde en una de tres categorías: **réplica** (la observación del docente es incorrecta, se rebate con evidencia ejecutable), **resuelto** (este documento y los artefactos que acompaña lo cierran), o **deuda declarada** (no se puede cumplir hoy sin tocar código, y se justifica por qué, qué lo desbloquea y cuándo).

Decisión de alcance para esta tanda de correcciones: **no se modifica ningún archivo de código, configuración ni pipeline**. El proyecto sigue en etapa de estabilización del esqueleto (ver `docs/ia.md`, entradas de agosto), y mover código ahora mezclaría dos tipos de cambio distintos. Todo lo que exige código queda aquí como deuda explícita, no como omisión silenciosa.

---

## 1. Réplicas — observaciones incorrectas

### Criterio 1 — Etiqueta `corte-1` sobre un commit anterior al cierre

**Réplica: la etiqueta sí existe.** La observación se originó por confundir el *mensaje* de un commit con una *etiqueta* (tag) de Git — son dos objetos distintos en el repositorio.

```
git ls-remote --tags origin
# d3be5145afc9a14111a22e2185a0dad4fe29fefb  refs/tags/corte-1
```

El tag ligero `corte-1` existe tanto local como en el remoto de GitHub, apunta al commit `d3be514` (`Merge branch 'main' of https://github.com/ISCOUTB/AS_202620_ElMapita`, 2026-09-01 08:06:53 -0600), que es anterior al commit de cierre `4806374` (cuyo *mensaje* también dice "corte-1", pero eso es un texto de commit, no un tag). Ambos objetos existen; la etiqueta cumple lo que pedía el criterio.

### Criterio 2 — PDF de dos páginas

**Réplica: el archivo sí está versionado en la ruta esperada.**

```
git ls-files docs/cortes/
# docs/cortes/corte-1.pdf
```

`docs/cortes/corte-1.pdf` (274 445 bytes) está tracked en el repositorio desde el commit de cierre. Queda pendiente solo la comprobación cruzada contra lo subido a Moodle/SAVIO, que es responsabilidad de la plataforma del curso, no del repositorio.

---

## 2. Resuelto en esta tanda

### Criterio 3 — Impacto de la restricción en requisitos, C4 y código

El equipo formalizó el reto del corte como **RES-04** (rendimiento en el mayor rango posible de dispositivos móviles, incluyendo gama de entrada) en `docs/arc42/arc42-template-EN.md`, sección 2. La misma sección incluye ahora la subsección **"Impacto de RES-04"**, que cubre explícitamente los tres ejes que pedía el criterio:
- **Requisitos:** EC-01/EC-02 conservan sus umbrales, extendiendo su entorno de referencia a gama de entrada; EC-04 gana prioridad.
- **C4:** sin cambios en los límites de Nivel 1 ni Nivel 2 — la estrategia vive dentro del contenedor `App Móvil Flutter` ya existente.
- **Código:** puntos de aterrizaje identificados (`build.gradle.kts`, `pubspec.yaml`, adaptador de render, `model_cache.dart`), todos pendientes de implementación (ver deuda del criterio 6).

### Criterio 5 — ADR del reto

Se redactó **`docs/adr/0002-restriccion-rendimiento-compatibilidad-dispositivos.md`**, siguiendo la misma plantilla del ADR-0001: contexto, alternativas consideradas (tres, con pros/contras), decisión (LOD + degradación progresiva a vista esquemática bajo 20 FPS, enlazando con el riesgo ya declarado RSK-02) y consecuencias — incluyendo, de forma explícita, que la implementación está pendiente.

### Criterio 7 — Límites C4 conservados

Verificado y documentado: `docs/c4/C4_L1_Context.md` y `C4_L2_Container.md` no cambiaron, y el nuevo ADR-0002 declara explícitamente que la estrategia elegida (LOD/degradación) no requiere contenedores ni relaciones nuevos — se implementa dentro de `App Móvil Flutter`.

### Criterio 11 — Salida de IA con motivo técnico de este corte

Se agregó la entrada `## 2026-09-07 — Sesión de trabajo con Claude Code` en `docs/ia.md`, con el motivo técnico de cada acción de esta sesión (diagnóstico del pipeline, verificación de tag/PDF, RES-04, ADR-0002, este documento).

---

## 3. Deuda declarada — justificación técnica

### Criterio 4 — Línea base medida y verificable

**Por qué no se puede hoy:** los cuatro escenarios de calidad (EC-01 carga de modelo 3D, EC-02 fluidez de render, EC-03 geolocalización, EC-04 caché offline) miden capacidades que **aún no están implementadas** en la aplicación — no existe todavía renderizado 3D real ni un `LocationProvider` conectado a sensores. Medir "carga" o "FPS" hoy produciría una cifra cosmética (por ejemplo, el tiempo de un splash screen estático), no una línea base del comportamiento que el escenario describe.

**Qué lo desbloquea:** la implementación del adaptador de render 3D (`MapRenderer`) y del `LocationProvider` real, ambos ya previstos en el ADR-0001 y referenciados en el ADR-0002.

### Criterio 6 — Cambio implementado extremo a extremo

**Por qué no se puede hoy:** el commit funcional del periodo (`f6956ad`, "Primer prueba codigo") y el trabajo de estabilización documentado en `docs/ia.md` (agosto) se dedicaron a que el esqueleto compilara y el flujo base (splash → aviso legal → pantalla principal, i18n, tema institucional) funcionara en dispositivo real. Ninguno de esos cambios implementa una restricción nueva de negocio de punta a punta — es trabajo de estabilización, no de feature.

**Qué lo desbloquea:** implementar RES-04 (LOD, detección de frame rate, caída a vista esquemática) como el primer cambio end-to-end sobre el esqueleto ya estable.

### Criterio 8 — Prueba que cubre el cambio, en verde en pipeline

**Diagnóstico técnico completo** (identificado, no solo detectado):

1. **Job frontend — falla determinista en `flutter pub get`.** `.github/workflows/ci.yml` fija `FLUTTER_VERSION: "3.22.0"` (trae Dart 3.4.x), pero `frontend/pubspec.yaml` declara `environment: sdk: ^3.12.0` y `frontend/pubspec.lock` resuelve a `flutter: ">=3.44.0"`. El *version solving* falla antes de llegar a `flutter analyze` o a los tests. Localmente el equipo compila con Flutter 3.44.0 / Dart 3.12.0 (`flutter --version`), que es la versión que habría que fijar en el workflow.
2. **Job backend — falla determinista en `npm run lint`.** `backend/eslint.config.mjs` activa `tseslint.configs.recommendedTypeChecked`, que convierte en **error** (no warning) reglas como `no-unsafe-assignment` y `no-unsafe-member-access`. Hay ~10 usos de `any` sin tipar en los adaptadores que mapean filas crudas de Supabase (`supabase-repositories.ts`, `supabase-poi-repository.ts`, `supabase-auth-client.ts`) y en tres controllers.
3. El job `quality-gate` depende de ambos (`needs: [backend, frontend, docs]`) y falla en cascada.

**Por qué no se corrige ahora:** corregirlo implica tocar `ci.yml` y/o código fuente (tipar las filas de Supabase, o relajar reglas de lint) — exactamente lo que el equipo decidió no hacer en esta tanda, reservada a documentación.

**Qué lo desbloquea:** alinear `FLUTTER_VERSION` en `ci.yml` con el SDK real del proyecto, y tipar las filas de Supabase en los seis archivos identificados.

### Criterio 9 — Resultado contrastado con umbral

Consecuencia directa del criterio 4: sin una medición ejecutada sobre una capacidad real, no hay resultado que contrastar contra los umbrales de EC-01–EC-04. Se desbloquea junto con el criterio 4.

### Criterio 10 — Cadena de trazabilidad navegable

La cadena `Aspecto → Requisito → Escenario de calidad → C4 → ADR → Código` está completa y navegable en `docs/aspectos.md` para las 4 filas EC-01–EC-04. Se rompe únicamente en las dos últimas columnas, `Pruebas` y `Evidencia`, marcadas "(pendiente)"/"Pendiente" — por la misma razón del criterio 4: no existen todavía las capacidades que esas pruebas ejercitarían. No es una omisión de trazabilidad sino consecuencia directa del estado de implementación.

### Criterio 12 — Sustentación del reto

Sin acción del equipo — lo resuelve el docente en la sesión de sustentación.

---

## 4. Compromisos para el siguiente corte

| Criterio | Qué se entrega | Depende de |
|---|---|---|
| 8 | `FLUTTER_VERSION` alineado a 3.44.0 en `ci.yml`; filas de Supabase tipadas (sin `any`) en los 6 archivos identificados | Ninguno — es el primer paso, habilita medir todo lo demás en CI |
| 6 | Implementación end-to-end de RES-04 (LOD + degradación progresiva) sobre el esqueleto ya estable | Adaptador `MapRenderer` |
| 4, 9 | Primera línea base medida de EC-01/EC-02 (carga y fluidez) sobre dispositivo real, contrastada contra los umbrales ya definidos | Renderizado 3D real implementado |
| 10 | Columnas `Pruebas` y `Evidencia` de `docs/aspectos.md` completas para las 4 filas | Resultado de 4, 6 y 9 |
