# Mensajería asíncrona: contrato, entrega y operación

Implementación: `backend/src/shared/messaging/` (bus) y `backend/src/modules/pois/application/` (evento, consumidor). Decisión y alternativa síncrona: [ADR-0009](../adr/0009-mensajeria-asincrona-simulador-en-memoria.md).

## Tecnología: simulador en memoria

`InMemoryMessageBus` implementa el puerto `MessageBus` con la misma semántica que tendría un broker (suscripciones nombradas, entrega al-menos-una-vez, reintentos, cola de fallidos). Se eligió un simulador porque hay una sola instancia sin presupuesto (ADR-0004) y porque permite **verificar las propiedades** con pruebas deterministas (el `sleep` se inyecta). Cambiarlo por RabbitMQ no toca los casos de uso: solo se reimplementa el puerto.

## 1. Contrato del mensaje y compatibilidad

Sobre común (`shared/messaging/message.ts`):

| Campo | Tipo | Significado |
|---|---|---|
| `eventId` | uuid | Identidad del mensaje. **Llave de deduplicación.** |
| `type` | string | Nombre del evento con su versión mayor: `poi.created.v1` |
| `occurredAt` | ISO-8601 | Cuándo ocurrió el hecho |
| `correlationId` | string | Une productor y consumidor en logs y métricas |
| `payload` | objeto | Cuerpo del evento |

Evento `poi.created.v1` — se publica cuando `CreatePoi` guardó un POI:

| Campo | Tipo | Requerido |
|---|---|---|
| `poiId` | string | sí |
| `pisoId` | string | sí |
| `tipo` | string | sí |
| `nombre` | string | sí |

**Criterio de compatibilidad.**

| Cambio | Compatible | Qué se hace |
|---|---|---|
| Añadir un campo **opcional** al payload | Sí | Se queda en `v1`. Los consumidores **deben ignorar campos desconocidos** (`parsePoiCreatedV1` lo hace y está probado). |
| Quitar un campo, renombrarlo, cambiar su tipo o volverlo requerido | **No** | Se crea `poi.created.v2` como `type` nuevo. El productor publica ambos durante la transición; `v1` se retira cuando ya no tenga suscriptores. |
| Cambiar el significado de un campo | **No** | Igual que el anterior. |

Un consumidor valida solo lo que usa. Un mensaje al que le falta un campo requerido lanza `NonRetryableError`: reintentar no lo arregla, así que va directo a la cola de fallidos.

## 2. Garantía de entrega elegida: al-menos-una-vez

El bus puede entregar un mensaje más de una vez (reintentos y redeliveries), nunca lo descarta en silencio mientras el proceso viva.

**Consecuencias asumidas:**

- **Duplicados posibles** → los consumidores deben ser idempotentes (punto 3).
- **Sin garantía de orden** entre mensajes distintos. Hoy no importa: el único evento es de creación.
- **Pérdida si el proceso se reinicia:** la cola y los mensajes pendientes viven en memoria.
- **Escritura doble:** guardar el POI y publicar el evento no son atómicos. Si el proceso muere entre ambos, el POI existe y el evento nunca se publica. Mitigación elegida: la **reconciliación** (sección 7), no un *outbox*; el outbox queda como opción si algún día el evento no puede perderse.
- **Un fallo al publicar no falla la petición:** el POI ya está guardado; se registra el error.

## 3. Duplicados: deduplicación por `eventId`

- **En el bus:** cada suscripción reclama `suscripcion:eventId` antes de procesar. Una segunda copia, incluso **simultánea**, se descarta y se cuenta como `duplicate_skipped`.
- **En el consumidor (`PoiAuditConsumer`):** además es idempotente por `poiId`, porque dos eventos *distintos* del mismo POI (p. ej. un reintento del cliente) no deben auditarse dos veces.
- **Límite:** el bus recuerda los últimos 10 000 `eventId`; los más viejos se olvidan.
- Si una entrega termina en la cola de fallidos, la reclamación se libera para que un reproceso pueda intentarlo de nuevo.

## 4. Reintentos, backoff y cola de mensajes fallidos

| Parámetro | Valor por defecto |
|---|---|
| Intentos totales por mensaje y suscripción | 3 |
| Espera tras el intento *n* | `200 ms × 2^(n-1)`, tope 5000 ms → 200 ms, 400 ms |
| Error `NonRetryableError` | Sin reintentos, directo a la cola de fallidos |
| Tras el último intento | Se guarda en la cola de fallidos con `subscription`, `attempts`, `error`, `failedAt` |

Cada suscripción falla de forma independiente: un consumidor roto no impide que los demás reciban el mensaje.

**Límites de la cola de fallidos:** vive en memoria (se pierde al reiniciar), se consulta con `deadLetters()` y no hay herramienta de reproceso. Se acepta mientras el único consumidor sea de demostración.

## 5. Pruebas automatizadas

| Propiedad | Prueba |
|---|---|
| **Duplicado**: el mismo mensaje dos veces se procesa una vez | `in-memory-message-bus.spec.ts` → "el mismo mensaje entregado dos veces se procesa una sola vez"; y de punta a punta en `poi-events.spec.ts` → "registra el POI una sola vez…" |
| Duplicado simultáneo | `in-memory-message-bus.spec.ts` → "dos copias simultáneas tampoco se ejecutan a la vez" |
| **Fallo recuperable**: falla dos veces y entrega a la tercera, con backoff 100/200 | `in-memory-message-bus.spec.ts` → "reintenta con backoff exponencial y termina entregando" |
| Cola de fallidos al agotar intentos / error no recuperable | `in-memory-message-bus.spec.ts` → "al agotar los intentos…", "un error no recuperable va directo…" |
| Aislamiento entre suscriptores | `in-memory-message-bus.spec.ts` → "un suscriptor que falla no afecta a los demás" |
| Compatibilidad (campo desconocido aceptado, campo requerido ausente rechazado) | `poi-events.spec.ts` → "contrato poi.created.v1" |
| De punta a punta: `CreatePoi` → bus → consumidor; y fallo del bus no rompe la petición | `poi-events.spec.ts` |

## 6. Seguir un mensaje de productor a consumidor

Cada transición escribe **una línea de log estructurada** con `eventId` y `correlationId` (los mismos en todas) y suma a una métrica.

| Transición | Log (`event`) | Nivel | `outcome` en `messages_total` |
|---|---|---|---|
| Publicado | `msg.published` | log | `published` |
| Entregado | `msg.delivered` (con `attempt`) | log | `delivered` |
| Duplicado descartado | `msg.duplicate_skipped` | log | `duplicate_skipped` |
| Reintento | `msg.retried` (con `delayMs`, `error`) | warn | `retried` |
| A la cola de fallidos | `msg.dead_lettered` (con `error`) | error | `dead_lettered` |

Métrica: `messages_total{type, subscription, outcome}` en `/metrics`. Para seguir un mensaje basta filtrar los logs por su `eventId` o `correlationId`: aparecen `msg.published` (productor) y luego `msg.delivered` o `msg.retried`/`msg.dead_lettered` (consumidor).

**Límite:** el `correlationId` se genera al publicar; todavía no se propaga desde la petición HTTP que originó el POI.

## 7. Reconciliación: cierre de la brecha sin outbox

`PoiAuditReconciler` (`modules/pois/application/poi-audit.reconciler.ts`) compara la fuente de verdad (`pois`, vía `PoiRepository.findAll()`) con los POIs que la auditoría ya tiene, y publica `poi.created.v1` solo para los que faltan.

| Pérdida que cubre | Cómo |
|---|---|
| El proceso murió entre guardar y publicar | El POI existe en `pois` y no en la auditoría: se republica |
| Un reinicio vació la auditoría o la cola pendiente (ambas en memoria) | Al arrancar se reconcilia: se reconstruye la auditoría completa |
| El evento quedó en la cola de fallidos | El POI sigue sin estar auditado: se publica un evento nuevo |

- **Cuándo corre:** al arrancar y luego cada 10 min. No corre con `NODE_ENV=test`. Una falla se registra (`reconcile.failed`) y nunca tumba la aplicación.
- **Es idempotente:** publicar de más no duplica nada, porque el consumidor es idempotente por `poiId`. Dos corridas seguidas: la segunda no encuentra nada.
- **Trazabilidad:** cada corrida usa un `correlationId` con la forma `reconcile-<uuid>` y registra `reconcile.done` con `checked`, `missing` y `published`.
- **Pruebas:** `poi-audit.reconciler.spec.ts` (solo lo que falta, reinicio, idempotencia, cola de fallidos, correlationId, arranque y fallo de BD).

**Límites:**

- **Latencia de recuperación:** una pérdida se corrige en ≤ 10 min (o al reiniciar), no al instante.
- **Solo cubre la creación:** compara por existencia. Si algún día hubiera eventos de actualización o borrado, habría que comparar contenido (p. ej. `updated_at`).
- **Costo:** lee todos los POIs (paginado de 1000 en 1000) cada 10 min; razonable con cientos de filas, no con millones.
- **Con varias instancias** cada una reconcilia su propia auditoría en memoria; el problema real entonces es la auditoría en memoria, no la reconciliación.
