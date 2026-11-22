# Mediciones en el despliegue vigente (Dokploy) — 2026-11-22

Autorizadas por el equipo, solo lectura. Host: `https://elmapita.iscoutb.dev` (el dominio que documenta `deploy/compose.lab.yaml`). No se escribió ningún dato. Origen: una sola máquina y red doméstica, peticiones secuenciales.

## Resultados

| Medición | Resultado | Archivo |
|---|---|---|
| `GET /health` | 200, `supabase: ok`, 1.76 s (primera petición) | — |
| `GET /api/v1/map/buildings` | 200, 0.46 s (primera), 0.07 s de media en `/metrics` | — |
| **EC-01 vía API** (detalle de edificio + modelo de piso), n=30 | **30/30 respuestas 404**; p50 439 ms, p95 551 ms | `final-ec01-dokploy-2026-11-22.json` |
| **EC-01 ruta real de la app** (capas + `.glb`, sin caché), n=30 | **30/30 respuestas 200**; p50 590 ms, p95 1026 ms, máx 1295 ms; `.glb` de 3 819 344 B | `final-ec01-ruta-app-2026-11-22.json` |

## Lectura

1. **Medición válida:** la ruta real de la app cumple EC-01 (p95 1026 ms frente al umbral de 5000 ms) con respuestas exitosas. Es la primera medición de EC-01 con 200/200.
2. **Defecto en la ruta de la API, distinto al de Render:** en Dokploy los endpoints de detalle responden `404 "Modelo 3D no disponible (3f8634e7-…/v1.glb): Object not found"`. El backend busca el modelo en el bucket `modelos-3d` con la ruta `{edificioId}/{version}.glb`, y ese objeto no existe. El modelo del campus está en otro bucket (`mapa-campus/utb_campus.glb`). Es un problema de **datos**, no de código; con Render el fallo era 500 y su causa no se determinó. Corregirlo exige subir un archivo a Supabase.
3. **La app no usa esas rutas:** descarga el modelo y las capas directamente de Supabase. Por eso el defecto de la API no afecta al usuario hoy. Sí afecta a la prueba de contrato y a un futuro uso de la API.
4. **Comparación con la línea base:** Render devolvía 500 en 30/30 (p95 1637–2840 ms, no válido). Dokploy responde 404 (p95 551 ms, tampoco válido para la ruta API) y la ruta real de la app da 200/200 con p95 1026 ms.

## Límites

- La medición se hizo desde una red doméstica rápida. EC-01 exige 10 Mbps y gama media. Estimación, **no medición**: transferir 3.8 MB a 10 Mbps toma unos 3.1 s, más la consulta de capas (0.2–0.8 s). Quedaría cerca de 3.5–4 s, bajo el umbral pero con poco margen.
- No incluye el render 3D en el dispositivo ni la red móvil.
- No se midió el arranque en frío del contenedor de Dokploy (permanece activo, `restart: unless-stopped`).
- Una sola máquina y 30 repeticiones secuenciales; no hay carga concurrente.

## Pendiente

Subir el modelo a `modelos-3d/{edificioId}/v1.glb` (o ajustar el adaptador para usar `mapa-campus`) y repetir `bench-ec01.mjs` hasta tener 200/200 en la ruta API. Requiere una escritura en Supabase que el equipo no ha autorizado.
