-- Bubble Splash — player data schema.
--
-- One row per account, keyed to Supabase auth.users. Mirrors the Dart domain
-- models (PlayerProfile + LivesState + FreeLifeState) so the app can sync a
-- profile straight to/from a single row. Guests are local-only (no auth user),
-- so they never appear here.
--
-- Money-adjacent fields (coins) live server-side and are guarded by RLS: a
-- player may only read/write their OWN row. Everyone may read a narrow set of
-- columns for the leaderboard (via the leaderboard view below), never coins or
-- lives.
--
-- Skins are intentionally NOT stored: they aren't sold, so equipped/owned stay
-- fixed 'classic' defaults in the app and never become account state.

create table if not exists public.profiles (
  -- Supabase user uuid. Deleting the auth user cascades the profile away.
  id            uuid primary key references auth.users (id) on delete cascade,

  -- Identity (name carries the Discord-style "#1234" tag from the app).
  name          text not null default 'Player',
  country       text not null default '',          -- ISO-3166 alpha-2, '' unknown
  avatar_emoji  text not null default 'bubble',     -- Material icon KEY, not a glyph
  avatar_color  bigint not null default 4283417591, -- ARGB int (0xFF4FC3F7)

  -- Currency (purchasable, never earned by play).
  coins         integer not null default 0 check (coins >= 0),

  -- Progression / lifetime stats.
  xp                    bigint  not null default 0 check (xp >= 0),
  high_score            integer not null default 0 check (high_score >= 0),
  games_played          integer not null default 0 check (games_played >= 0),
  total_bubbles_popped  bigint  not null default 0 check (total_bubbles_popped >= 0),
  best_streak           integer not null default 0 check (best_streak >= 0),

  -- Achievements unlocked (ids from the app's kAchievements catalog).
  unlocked_achievement_ids  text[] not null default array[]::text[],

  -- Lives bank (in-round continues). Timestamp-based regen — see LivesState.
  lives_count           integer not null default 5 check (lives_count between 0 and 100),
  lives_last_regen_ms   bigint  not null default 0,

  -- Free Life ad-claim cooldown — see FreeLifeState.
  free_life_last_claim_ms bigint not null default 0,

  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- Leaderboard boards sort by these; index so ranking stays cheap as rows grow.
create index if not exists profiles_high_score_idx
  on public.profiles (high_score desc);
create index if not exists profiles_total_pops_idx
  on public.profiles (total_bubbles_popped desc);
create index if not exists profiles_country_idx
  on public.profiles (country);

-- ---------------------------------------------------------------------------
-- updated_at auto-touch
-- ---------------------------------------------------------------------------
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- Auto-create a profile row on sign up, seeding name + country from the
-- metadata the app passes to auth.signUp(data: {name, country}).
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, name, country)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'name', ''), 'Player'),
    coalesce(new.raw_user_meta_data ->> 'country', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Row-Level Security: a player owns exactly their row.
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own
  on public.profiles for insert
  with check (auth.uid() = id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- No delete policy: profiles vanish only when the auth user is deleted (cascade).

-- ---------------------------------------------------------------------------
-- Public leaderboard — narrow, read-only projection (never exposes coins,
-- lives, email or timestamps). Runs with the view owner's rights so it can
-- read across players for ranking; only these safe columns are surfaced.
-- ---------------------------------------------------------------------------
create or replace view public.leaderboard as
  select
    id,
    name,
    country,
    avatar_emoji,
    avatar_color,
    high_score,
    total_bubbles_popped
  from public.profiles;

grant select on public.leaderboard to anon, authenticated;
