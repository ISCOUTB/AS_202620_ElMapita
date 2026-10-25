import type { Message } from './message';
import {
  NonRetryableError,
  type DeadLetter,
  type MessageBus,
  type MessageHandler,
} from './message-bus.port';

export type BusEvent =
  | { kind: 'published'; message: Message }
  | {
      kind: 'delivered' | 'duplicate';
      message: Message;
      subscription: string;
      attempt?: number;
    }
  | {
      kind: 'retry';
      message: Message;
      subscription: string;
      attempt: number;
      delayMs: number;
      error: string;
    }
  | {
      kind: 'dead_lettered';
      message: Message;
      subscription: string;
      attempt: number;
      error: string;
    };

export interface BusOptions {
  /** Intentos totales por mensaje y suscripción (el primero cuenta). */
  maxAttempts?: number;
  baseDelayMs?: number;
  maxDelayMs?: number;
  /** Cuántos eventId recuerda cada bus para deduplicar (los más viejos se olvidan). */
  dedupCapacity?: number;
  sleep?: (ms: number) => Promise<void>;
  onEvent?: (event: BusEvent) => void;
}

interface Subscription {
  name: string;
  handler: MessageHandler;
}

const realSleep = (ms: number) => new Promise<void>((r) => setTimeout(r, ms));

/**
 * Simulador local de un bus con entrega al-menos-una-vez:
 * - `publish` encola y vuelve; la entrega ocurre aparte (no bloquea al productor).
 * - Un fallo se reintenta con backoff exponencial; al agotarse va a la cola de fallidos.
 * - Cada suscripción deduplica por `eventId`, de modo que un mensaje repetido
 *   se procesa una sola vez (idempotencia del consumidor).
 * Todo vive en memoria: un reinicio pierde los mensajes pendientes (ADR-0009).
 */
export class InMemoryMessageBus implements MessageBus {
  private readonly subscriptions = new Map<string, Subscription[]>();
  private readonly dead: DeadLetter[] = [];
  private readonly claimed = new Set<string>();
  private readonly pending = new Set<Promise<void>>();
  private readonly maxAttempts: number;
  private readonly baseDelayMs: number;
  private readonly maxDelayMs: number;
  private readonly dedupCapacity: number;
  private readonly sleep: (ms: number) => Promise<void>;
  private readonly onEvent: (event: BusEvent) => void;

  constructor(options: BusOptions = {}) {
    this.maxAttempts = options.maxAttempts ?? 3;
    this.baseDelayMs = options.baseDelayMs ?? 200;
    this.maxDelayMs = options.maxDelayMs ?? 5000;
    this.dedupCapacity = options.dedupCapacity ?? 10_000;
    this.sleep = options.sleep ?? realSleep;
    this.onEvent = options.onEvent ?? (() => undefined);
  }

  subscribe(type: string, subscription: string, handler: MessageHandler): void {
    const list = this.subscriptions.get(type) ?? [];
    list.push({ name: subscription, handler });
    this.subscriptions.set(type, list);
  }

  publish(message: Message): Promise<void> {
    this.onEvent({ kind: 'published', message });
    for (const sub of this.subscriptions.get(message.type) ?? []) {
      // Se difiere un tick para que el productor nunca ejecute al consumidor en línea.
      const delivery = Promise.resolve().then(() => this.deliver(sub, message));
      this.pending.add(delivery);
      void delivery.finally(() => this.pending.delete(delivery));
    }
    return Promise.resolve();
  }

  deadLetters(): readonly DeadLetter[] {
    return this.dead;
  }

  /** Espera a que terminen las entregas en curso (para pruebas y apagado ordenado). */
  async drain(): Promise<void> {
    while (this.pending.size > 0) {
      await Promise.allSettled([...this.pending]);
    }
  }

  private claim(key: string): boolean {
    if (this.claimed.has(key)) return false;
    this.claimed.add(key);
    if (this.claimed.size > this.dedupCapacity) {
      this.claimed.delete(this.claimed.values().next().value as string);
    }
    return true;
  }

  private async deliver(sub: Subscription, message: Message): Promise<void> {
    // La reclamación se hace antes de procesar: dos copias simultáneas
    // tampoco se ejecutan a la vez.
    const key = `${sub.name}:${message.eventId}`;
    if (!this.claim(key)) {
      this.onEvent({ kind: 'duplicate', message, subscription: sub.name });
      return;
    }

    for (let attempt = 1; ; attempt++) {
      try {
        await sub.handler(message);
        this.onEvent({
          kind: 'delivered',
          message,
          subscription: sub.name,
          attempt,
        });
        return;
      } catch (e) {
        const error = e instanceof Error ? e.message : String(e);
        if (e instanceof NonRetryableError || attempt >= this.maxAttempts) {
          this.dead.push({
            message,
            subscription: sub.name,
            attempts: attempt,
            error,
            failedAt: new Date().toISOString(),
          });
          // Se libera la reclamación: una redelivery o reproceso posterior
          // desde la cola de fallidos podrá intentarlo de nuevo.
          this.claimed.delete(key);
          this.onEvent({
            kind: 'dead_lettered',
            message,
            subscription: sub.name,
            attempt,
            error,
          });
          return;
        }
        const delayMs = Math.min(
          this.maxDelayMs,
          this.baseDelayMs * 2 ** (attempt - 1),
        );
        this.onEvent({
          kind: 'retry',
          message,
          subscription: sub.name,
          attempt,
          delayMs,
          error,
        });
        await this.sleep(delayMs);
      }
    }
  }
}
