import type { CachePort } from './cache.port';

interface Entry {
  value: unknown;
  expiresAt: number;
}

export interface CacheObserver {
  onLookup(key: string, hit: boolean): void;
  onInvalidate(reason: 'del' | 'prefix' | 'evict' | 'expired', n: number): void;
}

/**
 * Caché local con TTL y desalojo LRU. El orden de inserción del `Map` hace de
 * lista LRU: cada acierto reinserta la clave al final.
 */
export class InMemoryTtlCache implements CachePort {
  private readonly entries = new Map<string, Entry>();

  constructor(
    private readonly maxEntries = 500,
    private readonly observer?: CacheObserver,
  ) {}

  get<T>(key: string): Promise<T | undefined> {
    const entry = this.entries.get(key);
    if (entry && entry.expiresAt <= Date.now()) {
      this.entries.delete(key);
      this.observer?.onInvalidate('expired', 1);
      this.observer?.onLookup(key, false);
      return Promise.resolve(undefined);
    }
    if (!entry) {
      this.observer?.onLookup(key, false);
      return Promise.resolve(undefined);
    }
    this.entries.delete(key);
    this.entries.set(key, entry);
    this.observer?.onLookup(key, true);
    return Promise.resolve(entry.value as T);
  }

  set<T>(key: string, value: T, ttlMs: number): Promise<void> {
    this.entries.delete(key);
    this.entries.set(key, { value, expiresAt: Date.now() + ttlMs });
    while (this.entries.size > this.maxEntries) {
      const oldest = this.entries.keys().next().value as string;
      this.entries.delete(oldest);
      this.observer?.onInvalidate('evict', 1);
    }
    return Promise.resolve();
  }

  del(key: string): Promise<void> {
    if (this.entries.delete(key)) this.observer?.onInvalidate('del', 1);
    return Promise.resolve();
  }

  delByPrefix(prefix: string): Promise<void> {
    let n = 0;
    for (const key of [...this.entries.keys()]) {
      if (key.startsWith(prefix)) {
        this.entries.delete(key);
        n++;
      }
    }
    if (n > 0) this.observer?.onInvalidate('prefix', n);
    return Promise.resolve();
  }
}
