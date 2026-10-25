import { InMemoryTtlCache } from './in-memory-ttl-cache';
import { getOrLoad } from './get-or-load';

describe('InMemoryTtlCache', () => {
  beforeEach(() => jest.useFakeTimers());
  afterEach(() => jest.useRealTimers());

  it('devuelve el valor guardado y undefined si no existe', async () => {
    const cache = new InMemoryTtlCache();
    await cache.set('a', 1, 1000);
    expect(await cache.get('a')).toBe(1);
    expect(await cache.get('b')).toBeUndefined();
  });

  it('expira la entrada al cumplirse el TTL', async () => {
    const cache = new InMemoryTtlCache();
    await cache.set('a', 1, 1000);
    jest.advanceTimersByTime(999);
    expect(await cache.get('a')).toBe(1);
    jest.advanceTimersByTime(2);
    expect(await cache.get('a')).toBeUndefined();
  });

  it('delByPrefix borra solo las claves con ese prefijo', async () => {
    const cache = new InMemoryTtlCache();
    await cache.set('pois:floor:1', 1, 1000);
    await cache.set('pois:floor:2', 2, 1000);
    await cache.set('mapas:buildings:all', 3, 1000);
    await cache.delByPrefix('pois:');
    expect(await cache.get('pois:floor:1')).toBeUndefined();
    expect(await cache.get('pois:floor:2')).toBeUndefined();
    expect(await cache.get('mapas:buildings:all')).toBe(3);
  });

  it('desaloja la entrada menos recientemente usada al superar el límite', async () => {
    const cache = new InMemoryTtlCache(2);
    await cache.set('a', 1, 1000);
    await cache.set('b', 2, 1000);
    await cache.get('a'); // 'a' pasa a ser la más reciente
    await cache.set('c', 3, 1000);
    expect(await cache.get('b')).toBeUndefined();
    expect(await cache.get('a')).toBe(1);
    expect(await cache.get('c')).toBe(3);
  });

  it('notifica aciertos, fallos e invalidaciones al observador', async () => {
    const lookups: boolean[] = [];
    const invalidations: string[] = [];
    const cache = new InMemoryTtlCache(500, {
      onLookup: (_k, hit) => lookups.push(hit),
      onInvalidate: (reason) => invalidations.push(reason),
    });
    await cache.get('a');
    await cache.set('a', 1, 1000);
    await cache.get('a');
    await cache.del('a');
    expect(lookups).toEqual([false, true]);
    expect(invalidations).toEqual(['del']);
  });
});

describe('getOrLoad', () => {
  it('no cachea null: el siguiente intento vuelve a consultar la fuente', async () => {
    const cache = new InMemoryTtlCache();
    const loader = jest.fn().mockResolvedValue(null);
    await getOrLoad(cache, 'k', 1000, loader);
    await getOrLoad(cache, 'k', 1000, loader);
    expect(loader).toHaveBeenCalledTimes(2);
  });

  it('no cachea cuando el loader falla', async () => {
    const cache = new InMemoryTtlCache();
    const loader = jest
      .fn()
      .mockRejectedValueOnce(new Error('db caída'))
      .mockResolvedValueOnce('ok');
    await expect(getOrLoad(cache, 'k', 1000, loader)).rejects.toThrow();
    expect(await getOrLoad(cache, 'k', 1000, loader)).toBe('ok');
  });

  it('sirve de la caché sin invocar al loader en el segundo acceso', async () => {
    const cache = new InMemoryTtlCache();
    const loader = jest.fn().mockResolvedValue([1, 2]);
    await getOrLoad(cache, 'k', 1000, loader);
    expect(await getOrLoad(cache, 'k', 1000, loader)).toEqual([1, 2]);
    expect(loader).toHaveBeenCalledTimes(1);
  });
});
