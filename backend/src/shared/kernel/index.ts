export interface Entity<T> {
  id: T;
  createdAt: Date;
  updatedAt: Date;
}

export interface ValueObject {
  equals(other: ValueObject): boolean;
}

export interface DomainEvent {
  eventName: string;
  occurredAt: Date;
  payload: Record<string, unknown>;
}

export interface Repository<T, ID> {
  findById(id: ID): Promise<T | null>;
  findAll(): Promise<T[]>;
  save(entity: T): Promise<T>;
  delete(id: ID): Promise<void>;
}

export interface UseCase<Input, Output> {
  execute(input: Input): Promise<Output>;
}

export abstract class BaseEntity<T> implements Entity<T> {
  constructor(
    public readonly id: T,
    public readonly createdAt: Date = new Date(),
    public readonly updatedAt: Date = new Date()
  ) {}

  protected abstract validate(): void;
}