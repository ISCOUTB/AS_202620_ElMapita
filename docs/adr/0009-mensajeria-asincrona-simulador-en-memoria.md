---
number: 0009
date: 2026-10-25
title: "Mensajería asíncrona con un simulador en memoria para efectos secundarios, frente a llamada síncrona"
status: Accepted
deciders: ["Diego Rosales Garza", "Rodrigo Vazquez Rico", "Angel Fabian Gutierrez Gomez"]
technical-story: "Taller de mensajería: demostrar contrato, garantía de entrega, idempotencia, reintentos con cola de fallidos, pruebas y trazabilidad, y comparar con una solución síncrona."
---

# ADR-0009: Mensajería asíncrona (simulador en memoria) para efectos secundarios

## Contexto

`CreatePoi` es la única escritura del backend. Al guardar un POI pueden ocurrir **efectos secundarios** que no son parte de la respuesta al cliente (hoy, una proyección de auditoría; mañana, notificaciones o sincronización con otro sistema). La pregunta es cómo invocarlos: dentro de la misma petición, o por un mensaje.

Restricciones: una sola instancia (Render plan free), sin presupuesto para un broker (ADR-0004), y la lectura inmediata del POI recién creado (*read-your-writes*) ya se resuelve con la invalidación de caché ([diseno-cache.md](../datos/diseno-cache.md)).

## Alternativas

| Alternativa | Latencia de la petición | Si el efecto secundario falla | Operación / costo | Garantías |
|---|---|---|---|---|
| A. **Síncrona**: `CreatePoi` llama al consumidor y espera | Suma la del consumidor | O falla la petición con el POI ya guardado (estado dudoso para el cliente) o se traga el error y se pierde el efecto | Ninguno | Simple y ordenada; el acoplamiento temporal es total |
| B. **Cola en memoria con simulador** (decisión) | Solo encolar | Reintento con backoff y cola de fallidos; la petición no se afecta | Ninguno: sin servicio nuevo | Al-menos-una-vez; **no duradera** |
| C. Broker real (RabbitMQ / Kafka) | Solo publicar | Igual que B, con persistencia | Un servicio más que operar, costo y punto de falla | Duradera; permite varias instancias |

## Decisión

**Se adopta B, solo para efectos secundarios.** La ruta principal (guardar + invalidar caché + responder) **sigue siendo síncrona**.

1. **Desacopla el éxito de la petición del efecto secundario.** Con A, un consumidor lento o roto degrada o rompe `POST /pois` después de haber guardado. Con B, la respuesta depende solo de la base de datos.
2. **Hace explícitas las propiedades** que importan (contrato versionado, idempotencia, reintentos, cola de fallidos, trazabilidad) y las vuelve **verificables** con pruebas deterministas, algo que A no necesita y C haría con infraestructura.
3. **No añade un servicio** (descarta C hoy): no hay segunda instancia, ni consumidor que justifique un broker. El puerto `MessageBus` deja el cambio a C como una reimplementación.
4. **Lo que se queda síncrono y por qué:** la invalidación de caché. Necesita *read-your-writes* inmediato; hacerla asíncrona dejaría una ventana en la que quien creó el POI no lo ve.

Honestidad sobre el alcance: el único consumidor actual es una proyección de auditoría en memoria, de demostración. El valor presente es el mecanismo probado; el valor de negocio aparece cuando haya un consumidor real.

## Consecuencias

**Asumidas:**
- **Entrega al-menos-una-vez** → duplicados posibles; los consumidores son idempotentes (por `eventId` en el bus y por `poiId` en el consumidor).
- **Pérdida ante reinicio:** cola, mensajes pendientes y cola de fallidos viven en memoria. En el plan free el servicio se duerme y reinicia, así que **un evento puede perderse**.
- **Escritura doble no atómica:** si el proceso muere entre guardar el POI y publicar, el evento no existe. Se mitigaría con un *outbox*.
- **Sin orden global** entre mensajes distintos; hoy irrelevante (solo hay eventos de creación).
- **Sin reproceso** de la cola de fallidos más que por código.
- Más piezas que entender que con A.

**Condición de revisión:** pasar a C (RabbitMQ) con *outbox* cuando ocurra **cualquiera** de: (a) un consumidor cuyo efecto no pueda perderse (notificaciones, integración con otro sistema); (b) más de una instancia; (c) la cola de fallidos reciba mensajes reales que haya que reprocesar. Mientras no ocurra, A seguiría siendo una opción válida si se retira el consumidor de demostración.

Detalle de contrato, reintentos, pruebas y trazabilidad: [contrato-mensajes.md](../mensajeria/contrato-mensajes.md).
