import type { UserLocation } from './index';

/** EC-03: ubicación aceptada solo si accuracy <= 15 m. */
export const MAX_ACCURACY_METERS = 15;
/** EC-03: timeout de adquisición antes de pasar a fallback manual. */
export const LOCATION_TIMEOUT_MS = 10_000;

export type FallbackReason = 'imprecise' | 'invalid' | 'timeout' | 'error';

export type AccuracyVerdict =
  | { accepted: true; location: UserLocation }
  | { accepted: false; reason: FallbackReason };

export function evaluateAccuracy(
  location: UserLocation,
  maxMeters: number = MAX_ACCURACY_METERS,
): AccuracyVerdict {
  const accuracy = location.precisionMeters;
  if (!Number.isFinite(accuracy) || accuracy < 0) {
    return { accepted: false, reason: 'invalid' };
  }
  if (accuracy <= maxMeters) {
    return { accepted: true, location };
  }
  return { accepted: false, reason: 'imprecise' };
}
