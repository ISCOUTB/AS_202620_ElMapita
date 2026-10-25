import { InMemoryMessageBus, type BusEvent } from './in-memory-message-bus';
import { NonRetryableError } from './message-bus.port';
import { newMessage } from './message';

const TYPE = 'demo.happened.v1';

function setup(options: { maxAttempts?: number; maxDelayMs?: number } = {}) {
  const events: BusEvent[] = [];
  const sleeps: number[] = [];
  const bus = new InMemoryMessageBus({
    baseDelayMs: 100,
    sleep: (ms) => {
      sleeps.push(ms);
      return Promise.resolve();
    },
    onEvent: (e) => events.push(e),
    ...options,
  });
  return { bus, events, sleeps };
}

describe('InMemoryMessageBus', () => {
  it('entrega el mensaje al suscriptor sin ejecutarlo dentro de publish', async () => {
    const { bus } = setup();
    const handler = jest.fn().mockResolvedValue(undefined);
    bus.subscribe(TYPE, 'a', handler);

    const published = bus.publish(newMessage(TYPE, { n: 1 }));
    expect(handler).not.toHaveBeenCalled(); // el productor no ejecuta al consumidor en línea
    await published;
    await bus.drain();
    expect(handler).toHaveBeenCalledTimes(1);
  });

  describe('duplicados (idempotencia del consumidor)', () => {
    it('el mismo mensaje entregado dos veces se procesa una sola vez', async () => {
      const { bus, events } = setup();
      const handler = jest.fn().mockResolvedValue(undefined);
      bus.subscribe(TYPE, 'a', handler);
      const message = newMessage(TYPE, { n: 1 });

      await bus.publish(message);
      await bus.publish(message); // redelivery: mismo eventId
      await bus.drain();

      expect(handler).toHaveBeenCalledTimes(1);
      expect(events.filter((e) => e.kind === 'duplicate')).toHaveLength(1);
    });

    it('dos copias simultáneas tampoco se ejecutan a la vez', async () => {
      const { bus } = setup();
      let running = 0;
      let maxRunning = 0;
      bus.subscribe(TYPE, 'a', async () => {
        running++;
        maxRunning = Math.max(maxRunning, running);
        await new Promise((r) => setTimeout(r, 5));
        running--;
      });
      const message = newMessage(TYPE, {});
      await Promise.all([bus.publish(message), bus.publish(message)]);
      await bus.drain();
      expect(maxRunning).toBe(1);
    });

    it('mensajes distintos (otro eventId) sí se procesan ambos', async () => {
      const { bus } = setup();
      const handler = jest.fn().mockResolvedValue(undefined);
      bus.subscribe(TYPE, 'a', handler);
      await bus.publish(newMessage(TYPE, {}));
      await bus.publish(newMessage(TYPE, {}));
      await bus.drain();
      expect(handler).toHaveBeenCalledTimes(2);
    });
  });

  describe('fallo recuperable (reintentos con backoff)', () => {
    it('reintenta con backoff exponencial y termina entregando, sin cola de fallidos', async () => {
      const { bus, sleeps } = setup();
      const handler = jest
        .fn()
        .mockRejectedValueOnce(new Error('timeout'))
        .mockRejectedValueOnce(new Error('timeout'))
        .mockResolvedValueOnce(undefined);
      bus.subscribe(TYPE, 'a', handler);

      await bus.publish(newMessage(TYPE, {}));
      await bus.drain();

      expect(handler).toHaveBeenCalledTimes(3);
      expect(sleeps).toEqual([100, 200]);
      expect(bus.deadLetters()).toHaveLength(0);
    });

    it('el retardo no supera maxDelayMs', async () => {
      const { bus, sleeps } = setup({ maxAttempts: 5, maxDelayMs: 250 });
      bus.subscribe(TYPE, 'a', () => Promise.reject(new Error('x')));
      await bus.publish(newMessage(TYPE, {}));
      await bus.drain();
      expect(sleeps).toEqual([100, 200, 250, 250]);
    });
  });

  describe('cola de mensajes fallidos', () => {
    it('al agotar los intentos el mensaje queda en la cola con su causa', async () => {
      const { bus } = setup();
      const handler = jest.fn().mockRejectedValue(new Error('BD caída'));
      bus.subscribe(TYPE, 'a', handler);
      const message = newMessage(TYPE, { n: 1 });

      await bus.publish(message);
      await bus.drain();

      expect(handler).toHaveBeenCalledTimes(3);
      const [dead] = bus.deadLetters();
      expect(dead).toMatchObject({
        subscription: 'a',
        attempts: 3,
        error: 'BD caída',
      });
      expect(dead.message.eventId).toBe(message.eventId);
    });

    it('un error no recuperable va directo a la cola, sin reintentos', async () => {
      const { bus, sleeps } = setup();
      const handler = jest
        .fn()
        .mockRejectedValue(new NonRetryableError('mal formado'));
      bus.subscribe(TYPE, 'a', handler);

      await bus.publish(newMessage(TYPE, {}));
      await bus.drain();

      expect(handler).toHaveBeenCalledTimes(1);
      expect(sleeps).toHaveLength(0);
      expect(bus.deadLetters()[0].attempts).toBe(1);
    });

    it('un suscriptor que falla no afecta a los demás', async () => {
      const { bus } = setup();
      const ok = jest.fn().mockResolvedValue(undefined);
      bus.subscribe(TYPE, 'roto', () => Promise.reject(new Error('x')));
      bus.subscribe(TYPE, 'sano', ok);

      await bus.publish(newMessage(TYPE, {}));
      await bus.drain();

      expect(ok).toHaveBeenCalledTimes(1);
      expect(bus.deadLetters().map((d) => d.subscription)).toEqual(['roto']);
    });

    it('tras fallar definitivamente, una redelivery puede intentarlo de nuevo', async () => {
      const { bus } = setup({ maxAttempts: 1 });
      const handler = jest
        .fn()
        .mockRejectedValueOnce(new Error('x'))
        .mockResolvedValueOnce(undefined);
      bus.subscribe(TYPE, 'a', handler);
      const message = newMessage(TYPE, {});

      await bus.publish(message);
      await bus.drain();
      await bus.publish(message);
      await bus.drain();

      expect(handler).toHaveBeenCalledTimes(2);
    });
  });

  describe('trazabilidad de productor a consumidor', () => {
    it('todas las transiciones de un mensaje comparten eventId y correlationId', async () => {
      const { bus, events } = setup();
      bus.subscribe(
        TYPE,
        'a',
        jest
          .fn()
          .mockRejectedValueOnce(new Error('x'))
          .mockResolvedValueOnce(undefined),
      );
      const message = newMessage(TYPE, {}, 'corr-123');

      await bus.publish(message);
      await bus.drain();

      expect(events.map((e) => e.kind)).toEqual([
        'published',
        'retry',
        'delivered',
      ]);
      expect(new Set(events.map((e) => e.message.eventId))).toEqual(
        new Set([message.eventId]),
      );
      expect(new Set(events.map((e) => e.message.correlationId))).toEqual(
        new Set(['corr-123']),
      );
    });
  });
});
