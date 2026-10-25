import { InMemoryMessageBus } from '../../../shared/messaging/in-memory-message-bus';
import { newMessage } from '../../../shared/messaging/message';
import { InMemoryTtlCache } from '../../../shared/cache/in-memory-ttl-cache';
import { PoiAuditConsumer } from './poi-audit.consumer';
import { CreatePoiUseCase } from './use-cases';
import { POI_CREATED_V1, parsePoiCreatedV1 } from './poi-events';
import type { FloorId, GeoPoint, Poi, PoiRepository, PoiType } from '../domain';

const valid = { poiId: 'p1', pisoId: 'f1', tipo: 'AULA', nombre: 'Aula 101' };

function setup() {
  const bus = new InMemoryMessageBus({ sleep: () => Promise.resolve() });
  const consumer = new PoiAuditConsumer(bus);
  consumer.onModuleInit();
  return { bus, consumer };
}

describe('contrato poi.created.v1', () => {
  it('acepta campos desconocidos (cambio compatible hacia adelante)', () => {
    expect(parsePoiCreatedV1({ ...valid, nuevoCampo: 'x' })).toEqual(valid);
  });

  it.each(['poiId', 'pisoId', 'tipo', 'nombre'])(
    'rechaza como no recuperable si falta %s',
    (field) => {
      const payload: Record<string, unknown> = { ...valid };
      delete payload[field];
      expect(() => parsePoiCreatedV1(payload)).toThrow(field);
    },
  );
});

describe('PoiAuditConsumer', () => {
  it('registra el POI una sola vez aunque el evento se entregue dos veces', async () => {
    const { bus, consumer } = setup();
    const message = newMessage(POI_CREATED_V1, valid);

    await bus.publish(message);
    await bus.publish(message);
    await bus.drain();

    expect(consumer.entries()).toHaveLength(1);
    expect(consumer.entries()[0].correlationId).toBe(message.correlationId);
  });

  it('un mensaje mal formado va a la cola de fallidos en el primer intento', async () => {
    const { bus, consumer } = setup();
    await bus.publish(newMessage(POI_CREATED_V1, { poiId: 'p1' }));
    await bus.drain();

    expect(consumer.entries()).toHaveLength(0);
    expect(bus.deadLetters()).toHaveLength(1);
    expect(bus.deadLetters()[0].attempts).toBe(1);
  });

  it('CreatePoi publica poi.created.v1 y el consumidor lo registra (de punta a punta)', async () => {
    const { bus, consumer } = setup();
    const repo = {
      save: (poi: Poi) => Promise.resolve(poi),
    } as unknown as PoiRepository;
    const create = new CreatePoiUseCase(repo, new InMemoryTtlCache(), bus);

    const { poi } = await create.execute({
      pisoId: 'f1' as FloorId,
      tipo: 'AULA' as unknown as PoiType,
      nombre: 'Aula 101',
      geometria: { type: 'Point', coordinates: [0, 0] } as unknown as GeoPoint,
      metadatos: {},
    });
    await bus.drain();

    expect(consumer.entries().map((e) => e.poiId)).toEqual([poi.id]);
  });

  it('si el bus falla al publicar, CreatePoi igualmente responde con el POI creado', async () => {
    const { bus } = setup();
    jest.spyOn(bus, 'publish').mockRejectedValue(new Error('bus caído'));
    const repo = {
      save: (poi: Poi) => Promise.resolve(poi),
    } as unknown as PoiRepository;
    const create = new CreatePoiUseCase(repo, new InMemoryTtlCache(), bus);

    await expect(
      create.execute({
        pisoId: 'f1' as FloorId,
        tipo: 'AULA' as unknown as PoiType,
        nombre: 'Aula',
        geometria: {} as GeoPoint,
        metadatos: {},
      }),
    ).resolves.toBeDefined();
  });
});
