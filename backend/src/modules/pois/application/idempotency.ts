import { createHash } from 'crypto';

export const IDEMPOTENCY_KEY_MAX_LENGTH = 128;

/** Llave de idempotencia y quién la envía: la llave solo vale por usuario. */
export interface IdempotencyContext {
  idempotencyKey: string;
  actorId: string;
}

/**
 * UUID estable (formato v5, SHA-1) derivado de usuario y llave. El POI se
 * guarda con ese id: reintentar la misma petición apunta a la misma fila, así
 * la deduplicación la garantiza la clave primaria y sobrevive a reinicios.
 */
export function idempotentPoiId({
  idempotencyKey,
  actorId,
}: IdempotencyContext): string {
  const bytes = createHash('sha1')
    .update(`poi:${actorId}:${idempotencyKey}`)
    .digest()
    .subarray(0, 16);
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = bytes.toString('hex');
  return [
    hex.slice(0, 8),
    hex.slice(8, 12),
    hex.slice(12, 16),
    hex.slice(16, 20),
    hex.slice(20, 32),
  ].join('-');
}
