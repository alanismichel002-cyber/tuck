-- Tuck user profiles.
-- Run this once in Supabase: Dashboard > SQL Editor > New query > paste > Run.
-- Safe to run again: it only adds what is missing.

-- 1. The profiles table: one row per user, linked to Supabase's auth.users.
create table if not exists public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  full_name    text,
  username     text unique,
  savings_goal text,
  bio          text,
  avatar_url   text,
  updated_at   timestamptz not null default now()
);

-- Columns added for Google sign-in, in case the table already existed without them.
alter table public.profiles add column if not exists bio text;
alter table public.profiles add column if not exists avatar_url text;

-- Basic limits, matching the form on profile.html.
do $$ begin
  alter table public.profiles add constraint username_format
    check (username is null or username ~ '^[A-Za-z0-9_]{3,30}$');
exception when duplicate_object or check_violation then null; end $$;
do $$ begin
  alter table public.profiles add constraint field_lengths check (
    coalesce(length(full_name), 0) <= 80 and coalesce(length(savings_goal), 0) <= 120
    and coalesce(length(bio), 0) <= 300 and coalesce(length(avatar_url), 0) <= 500);
exception when duplicate_object or check_violation then null; end $$;

-- 2. Row Level Security: each person can only see and edit their own profile.
alter table public.profiles enable row level security;

drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile" on public.profiles
  for select using (auth.uid() = id);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile" on public.profiles
  for insert with check (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- 3. Create a profile automatically when someone signs up (email or Google).
--    Google sign-ups start with their Google name and photo.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    coalesce(new.raw_user_meta_data ->> 'avatar_url', new.raw_user_meta_data ->> 'picture')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
