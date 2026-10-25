import { InMemoryMessageBus } from '../../../shared/messaging/in-memory-message-bus';
import { newMessage } from '../../../shared/messaging/message';
import { PoiAuditConsumer } from './poi-audit.consumer';
import { PoiAuditReconciler } from './poi-audit.reconciler';
import { POI_CREATED_V1 } from './poi-events';
import type { Poi, PoiRepository } from '../domain';

const poi = (id: string) =>
  ({ id, pisoId: 'f1', tipo: 'AULA', nombre: `POI ${id}` }) as unknown as Poi;

function setup(pois: Poi[]) {
  const bus = new InMemoryMessageBus({ sleep: () => Promise.resolve() });
  const consumer = new PoiAuditConsumer(bus);
  consumer.onModuleInit();
  const findAll = jest.fn().mockResolvedValue(pois);
  const repo = { findAll } as unknown as PoiRepository;
  const reconciler = new PoiAuditReconciler(repo, bus, consumer);
  return { bus, consumer, reconciler, findAll };
}

const audited = (c: PoiAuditConsumer) => c.entries().map((e) => e.poiId);

describe('PoiAuditReconciler', () => {
  it('publica solo los POIs que la auditoría no tiene', async () => {
    const { bus, consumer, reconciler } = setup([poi('p1'), poi('p2')]);
    // p1 sí llegó a auditarse; p2 es el evento que se perdió.
    await bus.publish(
      newMessage(POI_CREATED_V1, {
        poiId: 'p1',
        pisoId: 'f1',
        tipo: 'AULA',
        nombre: 'POI p1',
      }),
    );
    await bus.drain();

    const result = await reconciler.reconcile();
    await bus.drain();

    expect(result).toEqual({ checked: 2, missing: 1, published: 1 });
    expect(audited(consumer).sort()).toEqual(['p1', 'p2']);
  });

  it('recupera todo tras un reinicio (auditoría en memoria vacía)', async () => {
    const { bus, consumer, reconciler } = setup([poi('p1'), poi('p2')]);

    const result = await reconciler.reconcile();
    await bus.drain();

    expect(result.missing).toBe(2);
    expect(audited(consumer).sort()).toEqual(['p1', 'p2']);
  });

  it('es idempotente: una segunda corrida ya no encuentra nada que publicar', async () => {
    const { bus, consumer, reconciler } = setup([poi('p1')]);

    await reconciler.reconcile();
    await bus.drain();
    const second = await reconciler.reconcile();
    await bus.drain();

    expect(second).toEqual({ checked: 1, missing: 0, published: 0 });
    expect(consumer.entries()).toHaveLength(1);
  });

  it('republica un evento que había quedado en la cola de fallidos', async () => {
    const { bus, consumer, reconciler } = setup([poi('p1')]);
    // Evento mal formado: va a la cola de fallidos y el POI no se audita.
    await bus.publish(newMessage(POI_CREATED_V1, { poiId: 'p1' }));
    await bus.drain();
    expect(bus.deadLetters()).toHaveLength(1);
    expect(consumer.entries()).toHaveLength(0);

    await reconciler.reconcile();
    await bus.drain();

    expect(audited(consumer)).toEqual(['p1']);
  });

  it('todo lo republicado en una corrida comparte un correlationId de reconciliación', async () => {
    const { bus, consumer, reconciler } = setup([poi('p1'), poi('p2')]);
    await reconciler.reconcile();
    await bus.drain();

    const ids = new Set(consumer.entries().map((e) => e.correlationId));
    expect(ids.size).toBe(1);
    expect([...ids][0]).toMatch(/^reconcile-/);
  });

  describe('arranque automático', () => {
    const previous = process.env.NODE_ENV;
    afterEach(() => {
      process.env.NODE_ENV = previous;
      jest.useRealTimers();
    });

    it('en pruebas (NODE_ENV=test) no se lanza solo', () => {
      const { reconciler, findAll } = setup([poi('p1')]);
      reconciler.onApplicationBootstrap();
      expect(findAll).not.toHaveBeenCalled();
    });

    it('fuera de pruebas corre al arrancar y luego periódicamente; un fallo no lo detiene', async () => {
      process.env.NODE_ENV = 'production';
      jest.useFakeTimers();
      const { reconciler, findAll } = setup([poi('p1')]);
      findAll.mockRejectedValueOnce(new Error('BD caída'));

      reconciler.onApplicationBootstrap();
      await jest.advanceTimersByTimeAsync(0);
      expect(findAll).toHaveBeenCalledTimes(1); // al arrancar (y falló)

      await jest.advanceTimersByTimeAsync(10 * 60 * 1000);
      expect(findAll).toHaveBeenCalledTimes(2); // sigue intentando

      reconciler.onModuleDestroy();
      await jest.advanceTimersByTimeAsync(10 * 60 * 1000);
      expect(findAll).toHaveBeenCalledTimes(2); // ya no tras destruirlo
    });
  });
});
