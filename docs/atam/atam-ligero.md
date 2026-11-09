# Evaluación de arquitectura ATAM ligera — El Mapita UTB

Fecha de la evaluación: 2026-11-09. Alcance: monolito modular NestJS + app Flutter + Supabase, desplegado como contenedor Docker en Dokploy (`iscoutb.dev`).

## 1. Método (ATAM adaptado al tamaño del proyecto)

Se conserva el núcleo de ATAM y se omiten los talleres con stakeholders externos, que no aplican a un equipo de tres personas:

| Paso ATAM | Adaptación aquí |
|---|---|
| Presentar la arquitectura y los drivers | Sección 2, a partir de C4, arc42 y los ADR. |
| Árbol de utilidad y escenarios | EC-01 a EC-04 de arc42 §10, más dos escenarios propuestos en esta evaluación: SEG-01 (seguridad) y MAN-01 (mantenibilidad). |
| Analizar decisiones frente a escenarios | Secciones 4 y 5: puntos de sensibilidad, compromisos y riesgos. |
| Medir contra el umbral | Sección 3: umbral del escenario frente a lo medido, con la fecha y el archivo de evidencia. |
| Registrar resultados | arc42 §11 (riesgos RSK-10 a RSK-17 y subsección 11.3). |

Regla de honestidad: un escenario sin medición reciente se califica **«sin medir»**, nunca «cumple». Cuando el dato existente no es interpretable, se dice así.

## 2. Arquitectura evaluada y drivers

- **Estilo:** monolito modular con módulos `mapas`, `pois`, `auth` y `ubicacion` ([ADR-0005](../adr/0005-reemplazo-adr-0001-estilo-arquitectonico.md), [ADR-0008](../adr/0008-decision-extraccion.md)).
- **Datos:** PostgreSQL/PostGIS en Supabase como fuente de verdad ([ADR-0010](../adr/0010-postgresql-postgis-fuente-de-verdad.md)); modelos `.glb` versionados en Storage; caché del servidor en memoria con TTL.
- **Cliente:** Flutter con BLoC, caché local en Hive y disco, visor 3D en WebView.
- **Despliegue:** contenedor Docker en Dokploy (`iscoutb.dev`) desde el 2026-10-28, con límites de 256 MB y 0,5 CPU (`deploy/compose.lab.yaml`). Render ([ADR-0012](../adr/0012-reemplazo-adr-0004-despliegue-render-docker.md)) fue el despliegue anterior y la documentación aún lo describe (RSK-17).
- **Drivers de calidad:** rendimiento en móviles de gama media, uso con conectividad degradada, orientación aun con ubicación imprecisa, y un equipo pequeño que necesita simplicidad operativa.

## 3. Resultado de la medición frente al umbral

| Escenario | Umbral | Medido (fecha, evidencia) | Veredicto |
|---|---|---|---|
| **EC-01** Carga del mapa | p95 < 5 s en 30 cargas | Las dos mediciones disponibles son contra **Render**, que ya no es el despliegue vigente: 2026-10-04 (`evidencia/s9-ec01-benchmark.json`) y 2026-11-09 (`evidencia/atam-ec01-benchmark-2026-11-09.json`). En ambas, los endpoints de detalle respondieron **HTTP 500** en las 30 iteraciones y el p95 (1637 y 2840 ms) corresponde a respuestas de error. Desde el 2026-10-28 el repositorio despliega en Dokploy (`iscoutb.dev`, `deploy/compose.lab.yaml`) y ahí no hay medición. El script mide la secuencia de red, sin descarga del `.glb` ni render. | **Sin medir en el despliegue vigente** (último dato, en el despliegue anterior: no cumple) |
| **EC-02** Fluidez | ≥ 95 % de fotogramas ≤ 33,3 ms; cambio de piso ≤ 500 ms | 2026-10-05, SM A556E: 2398 fotogramas, 100 % ≤ 33,3 ms, p95 11 ms, **con carga sintética** (placeholder, no es renderizado 3D) (`evidencia/s9-ec02-fotogramas-dispositivo.txt`). El cambio de piso no se midió: no hay modelo por piso (RSK-09). | **Parcial** |
| **EC-03** Ubicación | Aceptar solo ≤ 15 m; a los 10 s sin lectura aceptable, selección manual en ≤ 2 s | La política de precisión está implementada con 10 pruebas (S9) y el cliente aplica un límite de 10 s y marca incertidumbre sobre 15 m. El módulo `ubicacion` del backend devuelve valores fijos (999 m, coordenadas 0,0) y la ubicación manual ignora sus entradas (`auditoria-erosion-s9.md`, hallazgo 3). El tiempo de aparición de la alternativa manual no se midió. | **Parcial** |
| **EC-04** Sin conexión | 20 de 20 pruebas con vista utilizable < 5 s y estado offline visible | 2026-10-05: **0/20** (`evidencia/s9-ec04-offline-dispositivo.txt`). El 2026-11-09 se implementó la copia local de metadatos y el banner «Offline» (4 pruebas unitarias en verde). **No se volvió a medir en dispositivo.** | **Sin medir tras la corrección** (última medición: no cumple) |
| **SEG-01** Autorización de escritura (propuesto) | 100 % de los intentos sin credencial o sin rol reciben 401/403 y no ejecutan el caso de uso; cero amenazas críticas abiertas | 2026-11-09: `guarded-endpoints.spec.ts` cubre 401, 403 y 2xx en `POST /pois` y en el cambio de rol (suite del backend: 85/85). T-01 y T-03 mitigadas; T-02 mitigada en backend, pendiente la migración de datos y el cliente. Siguen pendientes T-04, T-05, T-06, T-08 y T-09 (altas) ([ADR-0011](../adr/0011-modelado-de-amenazas-y-mitigaciones.md)). | **Cumple en autorización; parcial en el conjunto** |
| **MAN-01** Integridad de módulos (propuesto) | Cero hallazgos de severidad alta abiertos en límites de módulos y propiedad de datos; `tsc` sin errores | 2026-11-09: sigue abierto el cliente Supabase global con `service_role`, sin regla de lint que limite su uso; `FloorId` duplicado en `mapas` y `pois`, y `tsc` falla por ello (`test/contract/openapi.contract-spec.ts`). | **No cumple** |

Datos de la sesión (2026-11-09): backend 85/85 pruebas, frontend 39/39, `openapi:drift` sin deriva. `test:contracts` no se ejecutó por falta de `SUPABASE_URL` en este entorno.

## 4. Puntos de sensibilidad y de compromiso

**Puntos de sensibilidad** (un pequeño cambio en el parámetro mueve mucho la calidad):

| ID | Parámetro | Atributo afectado |
|---|---|---|
| S-1 | Tamaño del `.glb` de edificio o campus | EC-01 y EC-02: descarga, memoria y fotogramas. |
| S-2 | Umbral de precisión (15 m) y tiempo de espera (10 s) | EC-03: cuánto tarda el usuario en recibir una posición útil o la alternativa manual. |
| S-3 | TTL de caché del servidor (10 min mapas, 5 min POIs) | Frescura de datos frente a carga sobre Supabase. |
| S-4 | Criterio para activar el modo offline | EC-04: hoy cualquier fallo de la API activa la copia local, incluidos 404 y 5xx. |

**Puntos de compromiso** (una decisión mejora un atributo a costa de otro):

| ID | Decisión | Mejora | Cuesta |
|---|---|---|---|
| T-A | Caché local versionada de modelos y metadatos | EC-04 y tiempo de carga | Frescura: el usuario puede ver datos viejos (por eso el banner). |
| T-B | Todo el acceso a Supabase detrás de la API, con `service_role` | Desacoplamiento y control de acceso | Latencia adicional sobre EC-01 (y arranque en frío si el host lo tiene); si falla la autorización de la API, el acceso a la base es total (T-08). |
| T-C | Monolito modular ([ADR-0008](../adr/0008-decision-extraccion.md)) | Simplicidad operativa y menos puntos de fallo | Aislamiento: la propiedad de los datos entre módulos es solo convención (MAN-01). |
| T-D | Una instancia con caché y bus en memoria | Costo cero y simplicidad | Se pierden caché y mensajes pendientes en cada reinicio, y no hay *read-your-writes* con más de una instancia. |
| T-E | Un único modelo por edificio o campus | Menor esfuerzo de producción de contenido | Sin detalle interior ni descarga por piso (RSK-09). |

## 5. Riesgos y no-riesgos

**Riesgos nuevos** (se incorporan a arc42 §11 como RSK-10 a RSK-17):

| ID | Riesgo | Escenario | Impacto |
|---|---|---|---|
| RSK-10 | EC-01 sin medir en el despliegue vigente; en el despliegue anterior (Render) los endpoints de detalle respondían 500 (2026-10-04 y 2026-11-09) y la causa no se determinó. | EC-01 | Alto |
| RSK-11 | EC-02 solo medido con carga sintética; el visor 3D real no tiene perfil de fotogramas. | EC-02 | Medio |
| RSK-12 | EC-03 incompleto: el módulo `ubicacion` del backend devuelve valores fijos y no se mide la alternativa manual. | EC-03 | Medio |
| RSK-13 | EC-04 corregido en código pero sin remedir en dispositivo; el modo offline se activa ante cualquier fallo de la API. | EC-04 | Medio |
| RSK-14 | La propiedad de datos entre módulos no se verifica: cliente Supabase global con `service_role`, sin regla de lint, `FloorId` duplicado. | MAN-01, SEG-01 | Alto |
| RSK-15 | Caché y bus en memoria: se pierden en cada reinicio del contenedor y no se comparten entre instancias. | EC-01, EC-04 | Medio |
| RSK-17 | La documentación de despliegue está desactualizada: arc42 DEC-08, RSK-05, ADR-0012 y `ia.md` describen Render; el repositorio despliega en Dokploy. Las pruebas y mediciones apuntaron al servicio anterior. | Todos | Medio |
| RSK-16 | Esquema SQL y RLS sin versionar; arrays desnormalizados `edificios.pisos` y `pisos.pois` sin sincronizar. | SEG-01 | Medio |

**No-riesgos** (decisiones que la evaluación respalda):

- La autorización de escritura (`AuthGuard` con roles) y su cobertura de pruebas HTTP.
- El contrato OpenAPI versionado, sin deriva respecto de las rutas reales.
- Los modelos inmutables por versión y el desalojo de versiones viejas de la caché local (corregido el 2026-11-09, con pruebas contra el `LocalStorage` real).
- La idempotencia opcional de `POST /pois` mediante `Idempotency-Key`.
- Mantener el monolito modular ([ADR-0008](../adr/0008-decision-extraccion.md)): ninguno de los hallazgos de esta evaluación depende de extraer módulos; los riesgos RSK-10 a RSK-17 se resuelven dentro del monolito.

## 6. Acciones recomendadas

| Prioridad | Acción | Cierra |
|---|---|---|
| 1 | Medir EC-01 con `backend/scripts/bench-ec01.mjs <url-de-la-API-en-Dokploy>`. Si responde 500, diagnosticar con los logs del contenedor en Dokploy. | RSK-10 |
| 1b | Actualizar la documentación de despliegue (arc42 DEC-08, RSK-05, ADR-0012 y `ia.md`), que sigue describiendo Render. | RSK-17 |
| 2 | Volver a ejecutar `integration_test/offline_map_test.dart` en dispositivo. | RSK-13 |
| 3 | Añadir una regla de lint que limite `shared/supabase/client` a `infrastructure/` y unificar `FloorId` en `shared/kernel`. | RSK-14 |
| 4 | Perfilar fotogramas con el modelo 3D real del campus y medir el tiempo de la alternativa manual de ubicación. | RSK-11, RSK-12 |
| 5 | Exportar el esquema de Supabase (`supabase db dump --schema public`) y versionar políticas RLS. | RSK-16 |

## 7. Limitaciones de esta evaluación

- Se hizo sin stakeholders externos; las prioridades salen de los documentos del proyecto.
- Los escenarios SEG-01 y MAN-01 y sus umbrales los propone esta evaluación; deben ser aceptados por el equipo antes de pasar a arc42 §10.
- Las mediciones de EC-02 y EC-04 son de octubre y no reflejan el código actual. El 2026-11-09 se ejecutaron la suite local y el benchmark de EC-01 contra la API desplegada (autorizado por el responsable).
- El benchmark del 2026-11-09 se ejecutó contra el servicio de Render, que ya no es el despliegue vigente; no valida el código actual. La URL de la API en Dokploy no está en el repositorio (se configura en el panel).
