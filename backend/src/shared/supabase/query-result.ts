import { ServiceUnavailableException } from '@nestjs/common';
import type { PostgrestError } from '@supabase/supabase-js';

// PostgREST responde PGRST116 cuando .single() no encuentra exactamente una fila.
const NO_ROWS_CODE = 'PGRST116';

/**
 * Distingue "no existe" de "la base falló". Un fallo se propaga como 503 para
 * que nunca se confunda con un resultado vacío (y, por tanto, nunca se cachee).
 */
export function assertQueryOk(
  error: PostgrestError | null,
  context: string,
): void {
  if (!error || error.code === NO_ROWS_CODE) return;
  throw new ServiceUnavailableException(
    `Error de base de datos en ${context}: ${error.message}`,
  );
}
