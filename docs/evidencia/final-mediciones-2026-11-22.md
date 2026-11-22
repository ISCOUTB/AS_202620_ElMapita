# Mediciones del proyecto final — 2026-11-22 (servicio anterior: Render)

> **Aviso:** estas mediciones son del despliegue en Render, reemplazado por Dokploy (ADR-0015). Sirven como línea base del servicio anterior, no validan el despliegue vigente.

Autorizadas por el equipo (solo lectura): API desplegada en Render (servicio anterior) y Supabase del proyecto, solo con endpoints públicos y la clave `publishable` que ya está en el cliente. No se escribió ningún dato.

## Método

- API: `node backend/scripts/bench-ec01.mjs https://elmapita-utb-api.onrender.com 30` (salida completa en `final-ec01-benchmark-2026-11-22.json`).
- Supabase: `curl -w "%{time_total}"` contra REST y Storage, 5 repeticiones en `mapa_capas`.
- Métricas del servidor: `GET /metrics` (histograma `http_request_duration_seconds`).
- Origen de las pruebas: una sola máquina, red doméstica. No son carga concurrente.

## Resultados

| Medición | Resultado | Umbral / línea base |
|---|---|---|
| `GET /health` en frío (primera petición tras inactividad) | 18.8 s, HTTP 200 | Sin umbral definido; es el arranque en frío del plan gratuito de Render |
| `GET /health` en caliente | `{"status":"ok","checks":{"supabase":"ok"}}` | — |
| `GET /api/v1/map/buildings` | HTTP 200, 0.27 s en `/metrics` (2 muestras, media 0.27 s) | — |
| EC-01 (edificio + modelo de piso), n=30 | p50 1282 ms, p95 2015 ms, máx 2293 ms | Umbral p95 < 5000 ms |
| EC-01, estado de las respuestas | **30/30 con HTTP 500 en ambas rutas** | Exigido: 200/200 |
| Línea base `s9-ec01-benchmark.json` (2026-10-04) | p95 1637 ms, también 500/500 | — |
| Supabase REST `mapa_capas` (5 muestras) | 0.19 – 0.80 s, todas 200 | — |
| Supabase Storage, `utb_campus.glb` (3.8 MB) | 1.04 s, HTTP 200 | — |

## Lectura

1. **Rendimiento:** el p95 de 2015 ms cumple el umbral de 5000 ms, pero esa latencia es la de **respuestas de error**, así que no valida EC-01.
2. **Defecto abierto:** `GET /api/v1/map/buildings/{id}` y `GET /api/v1/map/floors/{id}/model` responden `500 Internal server error` en el despliegue. El listado sí funciona. El mismo fallo ya estaba en la medición del 2026-10-04: no es nuevo, y `cumple: false` quedó sin resolver.
3. **Causa:** sin confirmar. Desde fuera se descarta que el servicio esté caído (`/health` OK, Supabase OK). La causa se identifica con los logs de Render.
4. **Mitigación existente:** la app no depende de esas rutas para el mapa del campus. Descarga el `.glb` y las capas directamente de Supabase, con caché local (probado offline en `s9-ec04-offline-dispositivo.txt`).
5. **Arranque en frío:** 18.8 s es una degradación real y medida. La app debe mostrar la pantalla de carga sin bloquearse.

## Límites

Una sola máquina y una sola red; muestra de 30 peticiones secuenciales; no se midió el dispositivo móvil en esta sesión; no se tuvo acceso a los logs de Render.
