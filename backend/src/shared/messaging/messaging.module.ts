import { Global, Logger, Module } from '@nestjs/common';
import { getToken, makeCounterProvider } from '@willsoto/nestjs-prometheus';
import type { Counter } from 'prom-client';
import { InMemoryMessageBus, type BusEvent } from './in-memory-message-bus';
import { MESSAGE_BUS } from './message-bus.port';

const MESSAGES = 'messages_total';
const logger = new Logger('MessageBus');

const OUTCOME: Record<BusEvent['kind'], string> = {
  published: 'published',
  delivered: 'delivered',
  duplicate: 'duplicate_skipped',
  retry: 'retried',
  dead_lettered: 'dead_lettered',
};

/** Una línea de log por transición, siempre con eventId y correlationId. */
function logEvent(e: BusEvent): void {
  const fields = {
    event: `msg.${OUTCOME[e.kind]}`,
    type: e.message.type,
    eventId: e.message.eventId,
    correlationId: e.message.correlationId,
    ...('subscription' in e ? { subscription: e.subscription } : {}),
    ...('attempt' in e ? { attempt: e.attempt } : {}),
    ...('error' in e ? { error: e.error } : {}),
    ...('delayMs' in e ? { delayMs: e.delayMs } : {}),
  };
  if (e.kind === 'dead_lettered') logger.error(fields);
  else if (e.kind === 'retry') logger.warn(fields);
  else logger.log(fields);
}

@Global()
@Module({
  providers: [
    makeCounterProvider({
      name: MESSAGES,
      help: 'Transiciones de mensajes del bus, por tipo, suscripción y resultado (published|delivered|duplicate_skipped|retried|dead_lettered).',
      labelNames: ['type', 'subscription', 'outcome'],
    }),
    {
      provide: MESSAGE_BUS,
      inject: [getToken(MESSAGES)],
      useFactory: (counter: Counter<'type' | 'subscription' | 'outcome'>) =>
        new InMemoryMessageBus({
          onEvent: (e) => {
            logEvent(e);
            counter.inc({
              type: e.message.type,
              subscription: 'subscription' in e ? e.subscription : 'none',
              outcome: OUTCOME[e.kind],
            });
          },
        }),
    },
  ],
  exports: [MESSAGE_BUS],
})
export class MessagingModule {}
