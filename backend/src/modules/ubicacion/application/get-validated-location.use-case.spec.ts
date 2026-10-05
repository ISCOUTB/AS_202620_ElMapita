import { GetValidatedLocationUseCase } from './get-validated-location.use-case';
import { evaluateAccuracy } from '../domain/accuracy-policy';
import type { LocationProvider, UserLocation } from '../domain';

const loc = (precisionMeters: number): UserLocation => ({
  coordinates: { latitude: 10.3932, longitude: -75.5144 },
  precisionMeters,
  source: 'gps',
  timestamp: new Date(),
  uncertaintyShown: false,
});

const providerOf = (impl: () => Promise<UserLocation>): LocationProvider => ({
  getCurrentLocation: impl,
  watchLocation: () => () => {},
  requestPermission: () => Promise.resolve(true),
  isPermissionGranted: () => Promise.resolve(true),
});

describe('EC-03 evaluateAccuracy', () => {
  it('acepta accuracy menor al umbral', () => {
    expect(evaluateAccuracy(loc(5)).accepted).toBe(true);
  });
  it('acepta exactamente 15 m (umbral inclusivo: accuracy <= 15 m)', () => {
    expect(evaluateAccuracy(loc(15)).accepted).toBe(true);
  });
  it('rechaza 15.01 m como imprecisa', () => {
    expect(evaluateAccuracy(loc(15.01))).toEqual({
      accepted: false,
      reason: 'imprecise',
    });
  });
  it.each([NaN, Infinity, -1])('rechaza accuracy inválida (%p)', (v) => {
    expect(evaluateAccuracy(loc(v))).toEqual({
      accepted: false,
      reason: 'invalid',
    });
  });
});

describe('EC-03 GetValidatedLocationUseCase', () => {
  afterEach(() => jest.useRealTimers());

  it('devuelve la ubicación cuando es precisa', async () => {
    const uc = new GetValidatedLocationUseCase(
      providerOf(() => Promise.resolve(loc(8))),
    );
    expect((await uc.execute()).accepted).toBe(true);
  });

  it('pide fallback manual si es imprecisa y no expone la posición', async () => {
    const uc = new GetValidatedLocationUseCase(
      providerOf(() => Promise.resolve(loc(40))),
    );
    const verdict = await uc.execute();
    expect(verdict).toEqual({ accepted: false, reason: 'imprecise' });
    expect(verdict).not.toHaveProperty('location');
  });

  it('pide fallback manual tras timeout de 10 s', async () => {
    jest.useFakeTimers();
    const uc = new GetValidatedLocationUseCase(
      providerOf(() => new Promise(() => {})),
    );
    const pending = uc.execute();
    await jest.advanceTimersByTimeAsync(10_000);
    expect(await pending).toEqual({ accepted: false, reason: 'timeout' });
  });

  it('pide fallback manual si el proveedor falla (permiso denegado)', async () => {
    const uc = new GetValidatedLocationUseCase(
      providerOf(() => Promise.reject(new Error('permission denied'))),
    );
    expect(await uc.execute()).toEqual({ accepted: false, reason: 'error' });
  });
});
