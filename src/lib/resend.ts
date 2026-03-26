import { supabase } from '@/integrations/supabase/client';

export async function sendEmail({
  to,
  subject,
  html,
  from,
}: {
  to: string | string[];
  subject: string;
  html: string;
  from?: string;
}) {
  const { data, error } = await supabase.functions.invoke('send-email', {
    body: { to, subject, html, from },
  });

  if (error) throw error;
  return data;
}
