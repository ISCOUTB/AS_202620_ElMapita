import { NonRetryableError } from '../../../shared/messaging/message-bus.port';

/** Contrato `poi.created.v1`: ver docs/mensajeria/contrato-mensajes.md. */
export const POI_CREATED_V1 = 'poi.created.v1';

export interface PoiCreatedV1 {
  poiId: string;
  pisoId: string;
  tipo: string;
  nombre: string;
}

/**
 * Valida solo lo que el consumidor necesita y deja pasar campos desconocidos:
 * así un productor puede añadir campos opcionales sin romper a nadie
 * (cambio compatible dentro de v1). Un mensaje sin los campos requeridos
 * no se arregla reintentando, por eso es NonRetryableError.
 */
export function parsePoiCreatedV1(payload: unknown): PoiCreatedV1 {
  const p = payload as Partial<Record<keyof PoiCreatedV1, unknown>> | null;
  for (const field of ['poiId', 'pisoId', 'tipo', 'nombre'] as const) {
    if (typeof p?.[field] !== 'string' || p[field] === '') {
      throw new NonRetryableError(
        `${POI_CREATED_V1}: falta el campo requerido '${field}'`,
      );
    }
  }
  const ok = p as unknown as PoiCreatedV1;
  return {
    poiId: ok.poiId,
    pisoId: ok.pisoId,
    tipo: ok.tipo,
    nombre: ok.nombre,
  };
}
