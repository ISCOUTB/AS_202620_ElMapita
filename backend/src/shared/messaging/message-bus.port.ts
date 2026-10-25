import type { Message } from './message';

export type MessageHandler = (message: Message) => Promise<void>;

/** Mensaje que agotó sus reintentos (o falló sin remedio) en una suscripción. */
export interface DeadLetter {
  message: Message;
  subscription: string;
  attempts: number;
  error: string;
  failedAt: string;
}

/**
 * Error que un consumidor lanza cuando reintentar no puede arreglar nada
 * (mensaje mal formado, versión no soportada): va directo a la cola de fallidos.
 */
export class NonRetryableError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'NonRetryableError';
  }
}

/**
 * Puerto de mensajería. La implementación actual es un simulador en memoria
 * (ADR-0009); el contrato es el mismo que tendría RabbitMQ o similar:
 * entrega al-menos-una-vez, con suscripciones nombradas e independientes.
 */
export interface MessageBus {
  publish(message: Message): Promise<void>;
  /** `subscription` nombra al consumidor: cada una recibe, deduplica y falla por separado. */
  subscribe(type: string, subscription: string, handler: MessageHandler): void;
  deadLetters(): readonly DeadLetter[];
}

export const MESSAGE_BUS = 'MessageBus';
