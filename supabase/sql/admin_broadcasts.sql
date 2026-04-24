-- =====================================================================
-- Admin Broadcasts: composable push notifications from the admin panel.
-- Run this whole file in your Supabase project's SQL editor.
-- =====================================================================

-- 1) Table that stores every broadcast (pending, sent, failed)
create table if not exists public.admin_broadcasts (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete set null,
  title text not null,
  body text not null,
  -- audience: 'all' | 'drivers' | 'stores' | 'user'
  audience text not null default 'all',
  -- when audience = 'user', this is the target user id
  target_user_id uuid null references auth.users(id) on delete cascade,
  -- when null => send immediately. when set => send at/after this timestamp.
  send_at timestamptz null,
  status text not null default 'pending', -- pending | sent | failed
  recipients_count integer not null default 0,
  error text null,
  created_at timestamptz not null default now(),
  sent_at timestamptz null
);

create index if not exists admin_broadcasts_pending_idx
  on public.admin_broadcasts (status, send_at);

-- 2) RLS — admins only
alter table public.admin_broadcasts enable row level security;

drop policy if exists "Admins manage broadcasts" on public.admin_broadcasts;
create policy "Admins manage broadcasts"
  on public.admin_broadcasts
  for all
  to authenticated
  using (public.has_role(auth.uid(), 'admin'))
  with check (public.has_role(auth.uid(), 'admin'));

-- 3) pg_cron: dispatch due broadcasts every minute via the edge function.
create extension if not exists pg_cron;
create extension if not exists pg_net;

do $$
begin
  if exists(select 1 from cron.job where jobname = 'dispatch-admin-broadcasts') then
    perform cron.unschedule('dispatch-admin-broadcasts');
  end if;
end $$;

select cron.schedule(
  'dispatch-admin-broadcasts',
  '* * * * *',
  $$
  select net.http_post(
    url := 'https://eurjdhzdqlurvbgyeqgg.supabase.co/functions/v1/dispatch-broadcasts',
    headers := jsonb_build_object(
      'Content-Type','application/json',
      'Authorization','Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV1cmpkaHpkcWx1cnZiZ3llcWdnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NTk1MzIsImV4cCI6MjA5MDEzNTUzMn0.dGq-sgGBAnE3lnyvMgxHyCRkra8vohqJlX3jVnzzbS4'
    ),
    body := jsonb_build_object('source','cron')
  );
  $$
);

-- =====================================================================
-- 4) Make YOUR account an admin. Replace the email below with your own.
--    (Sign up via the app first using the same email, then run this.)
-- =====================================================================
-- insert into public.user_roles (user_id, role)
-- select id, 'admin'::app_role from auth.users where email = 'you@example.com'
-- on conflict do nothing;
