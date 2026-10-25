import { randomUUID } from 'crypto';

/**
 * Sobre común de todos los mensajes. El `type` lleva la versión mayor del
 * contrato (`poi.created.v1`); ver docs/mensajeria/contrato-mensajes.md para
 * el criterio de compatibilidad.
 */
export interface Message<T = unknown> {
  /** Identidad del mensaje; es la llave de deduplicación en los consumidores. */
  eventId: string;
  type: string;
  occurredAt: string;
  /** Une productor y consumidor en logs y métricas. */
  correlationId: string;
  payload: T;
}

export function newMessage<T>(
  type: string,
  payload: T,
  correlationId: string = randomUUID(),
): Message<T> {
  return {
    eventId: randomUUID(),
    type,
    occurredAt: new Date().toISOString(),
    correlationId,
    payload,
  };
}
