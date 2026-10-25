import { ServiceUnavailableException } from '@nestjs/common';
import type { PostgrestError } from '@supabase/supabase-js';
import { assertQueryOk } from './query-result';

const err = (code: string) =>
  ({ code, message: 'boom' }) as unknown as PostgrestError;

describe('assertQueryOk', () => {
  it('sin error no hace nada', () => {
    expect(() => assertQueryOk(null, 'ctx')).not.toThrow();
  });

  it('"ninguna fila" (PGRST116) se trata como no encontrado, no como fallo', () => {
    expect(() => assertQueryOk(err('PGRST116'), 'ctx')).not.toThrow();
  });

  it('cualquier otro error de BD se propaga como 503, no como vacío', () => {
    expect(() => assertQueryOk(err('08006'), 'ctx')).toThrow(
      ServiceUnavailableException,
    );
  });
});
