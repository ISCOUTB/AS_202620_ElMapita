import type { CachePort } from './cache.port';

/**
 * Cache-aside. Solo se cachean valores presentes: `null`/`undefined` (no
 * encontrado) no se guardan, y si el `loader` lanza, no queda nada en caché.
 */
export async function getOrLoad<T>(
  cache: CachePort,
  key: string,
  ttlMs: number,
  loader: () => Promise<T>,
): Promise<T> {
  const hit = await cache.get<T>(key);
  if (hit !== undefined) return hit;
  const value = await loader();
  if (value !== null && value !== undefined) {
    await cache.set(key, value, ttlMs);
  }
  return value;
}
