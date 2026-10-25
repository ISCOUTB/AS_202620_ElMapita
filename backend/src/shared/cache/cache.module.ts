import { Global, Module } from '@nestjs/common';
import { getToken, makeCounterProvider } from '@willsoto/nestjs-prometheus';
import type { Counter } from 'prom-client';
import { CACHE_PORT } from './cache.port';
import { InMemoryTtlCache } from './in-memory-ttl-cache';

const REQUESTS = 'cache_requests_total';
const INVALIDATIONS = 'cache_invalidations_total';

@Global()
@Module({
  providers: [
    makeCounterProvider({
      name: REQUESTS,
      help: 'Consultas a la caché del servidor, por familia de clave y resultado (hit|miss).',
      labelNames: ['cache', 'result'],
    }),
    makeCounterProvider({
      name: INVALIDATIONS,
      help: 'Entradas retiradas de la caché, por motivo (del|prefix|evict|expired).',
      labelNames: ['reason'],
    }),
    {
      provide: CACHE_PORT,
      inject: [getToken(REQUESTS), getToken(INVALIDATIONS)],
      useFactory: (
        requests: Counter<'cache' | 'result'>,
        invalidations: Counter<'reason'>,
      ) =>
        new InMemoryTtlCache(500, {
          onLookup: (key, hit) =>
            requests.inc({
              cache: key.split(':')[0],
              result: hit ? 'hit' : 'miss',
            }),
          onInvalidate: (reason, n) => invalidations.inc({ reason }, n),
        }),
    },
  ],
  exports: [CACHE_PORT],
})
export class CacheModule {}
