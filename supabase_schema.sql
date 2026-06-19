-- ============================================================
--  User Records — Supabase schema
--  Paste into Supabase SQL Editor and run once.
-- ============================================================

-- USERS ------------------------------------------------------
create table if not exists public.users (
  id            uuid        primary key default gen_random_uuid(),
  name          text        not null,
  phone_number  text        not null,
  created_at    timestamptz not null default now()
);

create index if not exists idx_users_phone on public.users(phone_number);

-- ITEMS ------------------------------------------------------
create table if not exists public.items (
  id          uuid        primary key default gen_random_uuid(),
  user_id     uuid        not null references public.users(id) on delete cascade,
  item_name   text        not null,
  quality     text,
  quantity    numeric     not null default 0,
  price       numeric     not null default 0,
  discount    numeric     not null default 0,
  remaining   numeric     not null default 0,
  balance     numeric     not null default 0,
  created_at  timestamptz not null default now()
);

create index if not exists idx_items_user_id on public.items(user_id);
create index if not exists idx_items_created_at on public.items(created_at desc);

-- DEVELOPMENT ACCESS -----------------------------------------
-- Disable Row Level Security so the anon key can read/write directly.
-- For production, turn RLS back on and write policies that scope rows
-- to an authenticated `auth.uid()`.
alter table public.users disable row level security;
alter table public.items disable row level security;
