-- ─────────────────────────────────────────────────────────────
--  Le Kreamery — Supabase setup
--  Run this ONCE in your Supabase project:
--  Dashboard → SQL Editor → New query → paste → Run.
-- ─────────────────────────────────────────────────────────────

-- 1. The table that holds every open table's bill (one row per table).
create table if not exists public.tabs (
  table_no   integer primary key,
  data       jsonb   not null,
  updated_at timestamptz default now()
);

-- 2. Turn on realtime so the till updates the instant an order lands.
alter publication supabase_realtime add table public.tabs;

-- 3. Access rules. This demo policy lets the app read/write freely
--    (fine for a pilot). Tighten before a public production launch.
alter table public.tabs enable row level security;

create policy "pilot_open_access"
  on public.tabs for all
  using (true)
  with check (true);
