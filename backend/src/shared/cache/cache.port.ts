/**
 * Puerto de caché del servidor. La implementación actual es local (memoria);
 * el contrato es asíncrono para poder cambiarla por Redis sin tocar los casos
 * de uso (ver docs/datos/diseno-cache.md).
 */
export interface CachePort {
  /** `undefined` si la clave no existe o expiró. */
  get<T>(key: string): Promise<T | undefined>;
  set<T>(key: string, value: T, ttlMs: number): Promise<void>;
  del(key: string): Promise<void>;
  delByPrefix(prefix: string): Promise<void>;
}

export const CACHE_PORT = 'CachePort';
