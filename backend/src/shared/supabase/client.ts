import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { ConfigService } from '@nestjs/config';

let supabaseClient: SupabaseClient | null = null;

export function getSupabaseClient(configService: ConfigService): SupabaseClient {
  if (!supabaseClient) {
    const url = configService.get<string>('SUPABASE_URL');
    const serviceKey = configService.get<string>('SUPABASE_SERVICE_ROLE_KEY');
    
    if (!url || !serviceKey) {
      throw new Error('Supabase configuration missing: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY required');
    }
    
    supabaseClient = createClient(url, serviceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });
  }
  
  return supabaseClient;
}

export function resetSupabaseClient(): void {
  supabaseClient = null;
}