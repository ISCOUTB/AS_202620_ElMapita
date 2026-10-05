import { Inject, Injectable } from '@nestjs/common';
import { UseCase } from '../../../shared/kernel';
import type { LocationProvider } from '../domain';
import {
  AccuracyVerdict,
  LOCATION_TIMEOUT_MS,
  evaluateAccuracy,
} from '../domain/accuracy-policy';

/**
 * EC-03: entrega la ubicación solo si es suficientemente precisa; en caso
 * contrario (imprecisa, inválida, timeout o error del proveedor) indica
 * fallback manual y nunca expone la posición imprecisa.
 */
@Injectable()
export class GetValidatedLocationUseCase implements UseCase<
  void,
  AccuracyVerdict
> {
  constructor(
    @Inject('LocationProvider')
    private readonly locationProvider: LocationProvider,
  ) {}

  async execute(): Promise<AccuracyVerdict> {
    let timer: NodeJS.Timeout | undefined;
    const timeout = new Promise<'timeout'>((resolve) => {
      timer = setTimeout(() => resolve('timeout'), LOCATION_TIMEOUT_MS);
    });
    try {
      const result = await Promise.race([
        this.locationProvider.getCurrentLocation(),
        timeout,
      ]);
      if (result === 'timeout') return { accepted: false, reason: 'timeout' };
      return evaluateAccuracy(result);
    } catch {
      return { accepted: false, reason: 'error' };
    } finally {
      clearTimeout(timer);
    }
  }
}
