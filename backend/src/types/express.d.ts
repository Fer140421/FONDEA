import type { SupabaseClient } from '@supabase/supabase-js';
import type { AuthenticatedUser } from '../integrations/supabase.js';

declare global {
  namespace Express {
    interface Request {
      user?: AuthenticatedUser;
      supabase?: SupabaseClient;
    }
  }
}
