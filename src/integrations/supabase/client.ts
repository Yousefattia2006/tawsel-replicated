import { createClient } from '@supabase/supabase-js';
import type { Database } from './types';

const SUPABASE_URL = "https://eurjdhzdqlurvbgyeqgg.supabase.co";
const SUPABASE_PUBLISHABLE_KEY = "sb_publishable_Z-Jq5BPS8vVZJWCZLUXqDA_OnuWk0cg";

// Import the supabase client like this:
// import { supabase } from "@/integrations/supabase/client";

export const supabase = createClient<Database>(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
  auth: {
    storage: localStorage,
    persistSession: true,
    autoRefreshToken: true,
  }
});