import { Inject, Injectable, OnModuleInit } from '@nestjs/common';
import {
  MESSAGE_BUS,
  type MessageBus,
} from '../../../shared/messaging/message-bus.port';
import type { Message } from '../../../shared/messaging/message';
import { POI_CREATED_V1, parsePoiCreatedV1 } from './poi-events';

export interface PoiAuditEntry {
  poiId: string;
  pisoId: string;
  tipo: string;
  nombre: string;
  eventId: string;
  correlationId: string;
  recordedAt: string;
}

export const POI_AUDIT_SUBSCRIPTION = 'poi-audit';

/**
 * Consumidor de ejemplo: proyecta cada `poi.created.v1` en un registro de
 * auditoría. Es en memoria a propósito (demuestra las propiedades de entrega;
 * no es almacenamiento duradero). La deduplicación por eventId la hace el bus;
 * aquí además se protege por `poiId` porque dos eventos distintos del mismo POI
 * (p. ej. un reintento del cliente) no deben auditarse dos veces.
 */
@Injectable()
export class PoiAuditConsumer implements OnModuleInit {
  private readonly byPoi = new Map<string, PoiAuditEntry>();

  constructor(@Inject(MESSAGE_BUS) private readonly bus: MessageBus) {}

  onModuleInit(): void {
    this.bus.subscribe(POI_CREATED_V1, POI_AUDIT_SUBSCRIPTION, (m) =>
      this.handle(m),
    );
  }

  entries(): PoiAuditEntry[] {
    return [...this.byPoi.values()];
  }

  handle(message: Message): Promise<void> {
    const event = parsePoiCreatedV1(message.payload);
    if (!this.byPoi.has(event.poiId)) {
      this.byPoi.set(event.poiId, {
        ...event,
        eventId: message.eventId,
        correlationId: message.correlationId,
        recordedAt: new Date().toISOString(),
      });
    }
    return Promise.resolve();
  }
}
