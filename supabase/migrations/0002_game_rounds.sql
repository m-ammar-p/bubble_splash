-- Bubble Splash — per-round score history.
--
-- One row per finished round (mirrors the app's GameResult). Lets you query a
-- user's individual scores over time (recent games, personal bests, charts),
-- which the aggregate columns on `profiles` (high_score, total_bubbles_popped)
-- can't give you. The app keeps writing those aggregates on `profiles`; this
-- table is the append-only log behind them.
--
-- Columns match GameResult exactly: score, bubbles_popped, max_combo,
-- golden_popped. No duration / streak — the game never reports those.

create table if not exists public.game_rounds (
  id              bigint generated always as identity primary key,
  user_id         uuid not null references public.profiles (id) on delete cascade,

  score           integer not null default 0 check (score >= 0),
  bubbles_popped  integer not null default 0 check (bubbles_popped >= 0),
  max_combo       integer not null default 0 check (max_combo >= 0),
  golden_popped   integer not null default 0 check (golden_popped >= 0),

  created_at      timestamptz not null default now()
);

-- "Recent games for this user, newest first" and "this user's top scores".
create index if not exists game_rounds_user_recent_idx
  on public.game_rounds (user_id, created_at desc);
create index if not exists game_rounds_user_score_idx
  on public.game_rounds (user_id, score desc);

-- ---------------------------------------------------------------------------
-- RLS: a player owns their own rounds. Rounds are immutable once written
-- (insert + read only — no update/delete policy), so a score can't be edited
-- after the fact.
-- ---------------------------------------------------------------------------
alter table public.game_rounds enable row level security;

drop policy if exists game_rounds_select_own on public.game_rounds;
create policy game_rounds_select_own
  on public.game_rounds for select
  using (auth.uid() = user_id);

drop policy if exists game_rounds_insert_own on public.game_rounds;
create policy game_rounds_insert_own
  on public.game_rounds for insert
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- record_round(): atomically log a round AND roll its numbers into the
-- player's profile aggregates (xp += score, high_score, games_played,
-- total_bubbles_popped). One round-trip from the client, no race between the
-- log row and the aggregate update. Runs as the caller, so RLS still enforces
-- "only your own row".
-- ---------------------------------------------------------------------------
create or replace function public.record_round(
  p_score          integer,
  p_bubbles_popped integer,
  p_max_combo      integer default 0,
  p_golden_popped  integer default 0
)
returns bigint
language plpgsql
security invoker
as $$
declare
  v_uid uuid := auth.uid();
  v_id  bigint;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  insert into public.game_rounds (user_id, score, bubbles_popped, max_combo, golden_popped)
  values (v_uid, p_score, p_bubbles_popped, p_max_combo, p_golden_popped)
  returning id into v_id;

  update public.profiles
     set xp                   = xp + p_score,
         high_score           = greatest(high_score, p_score),
         games_played         = games_played + 1,
         total_bubbles_popped = total_bubbles_popped + p_bubbles_popped
   where id = v_uid;

  return v_id;
end;
$$;

grant execute on function public.record_round(integer, integer, integer, integer)
  to authenticated;
