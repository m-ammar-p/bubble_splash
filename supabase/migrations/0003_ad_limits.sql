-- Bubble Splash — server-authoritative rewarded-ad limits (anti-spoof, Piece 1).
--
-- The app enforces rewarded-ad caps locally in SharedPreferences
-- (RewardedAdMeta), which a determined user can edit to reset the daily cap /
-- home cooldown. This migration moves the authoritative copy server-side for
-- SIGNED-IN users: the daily view count + rolling window live on `profiles`, and
-- every grant decision runs through a SECURITY-INVOKER RPC that uses the
-- **server clock** (`now()`) — so client-side timestamp tampering does nothing.
--
-- Local prefs stays the source of truth for guests / offline play; when online
-- and signed in, the app hydrates its counters FROM the server on load and asks
-- the server to authorize each completed view. Reward = lives only (no money),
-- so a re-anon / offline edge is acceptable — see REWARDED_ADS.md.
--
-- Limits mirror lib/domain/services/rewarded_ad_limits.dart:
--   daily view cap = 20 (rolling 24h), home cooldown = 30 min.
-- The per-death revive cap (3) stays a runtime client concern — it isn't
-- persisted anywhere, so there's nothing to spoof.

-- Home cooldown reuses the existing `free_life_last_claim_ms` column (added in
-- 0001, previously unused). Add the two daily-window counters.
alter table public.profiles
  add column if not exists ad_daily_count           integer not null default 0
    check (ad_daily_count >= 0),
  add column if not exists ad_daily_window_start_ms  bigint  not null default 0;

-- ---------------------------------------------------------------------------
-- Shared limits (keep in sync with RewardedAdLimits). Inlined as constants in
-- the functions below; changing a cap means editing both here and Dart.
-- ---------------------------------------------------------------------------

-- Normalizes the rolling daily window against the server clock, forward-only:
-- opens a fresh window (count 0) once a full 24h has elapsed. Returns the
-- effective (count, window_start) and persists any roll. No tamper guards are
-- needed — the server clock only moves forward and the client can't set it.
create or replace function public._ad_normalize_window(p_uid uuid)
returns table (v_count integer, v_wstart bigint, v_home bigint)
language plpgsql
security invoker
as $$
declare
  v_now        bigint := (extract(epoch from now()) * 1000)::bigint;
  v_window_ms  bigint := 24 * 60 * 60 * 1000;  -- RewardedAdLimits.dailyWindow
  r            record;
begin
  select ad_daily_count, ad_daily_window_start_ms, free_life_last_claim_ms
    into r
    from public.profiles
   where id = p_uid
     for update;

  v_count  := coalesce(r.ad_daily_count, 0);
  v_wstart := coalesce(r.ad_daily_window_start_ms, 0);
  v_home   := coalesce(r.free_life_last_claim_ms, 0);

  if v_wstart = 0 then
    v_wstart := v_now;
  elsif v_now - v_wstart >= v_window_ms then
    v_count  := 0;
    v_wstart := v_now;
  end if;

  update public.profiles
     set ad_daily_count = v_count,
         ad_daily_window_start_ms = v_wstart
   where id = p_uid;

  return query select v_count, v_wstart, v_home;
end;
$$;

-- Read-only-ish hydration: returns the current server-authoritative ad state so
-- the app can overwrite its local counters on load (a prefs edit gets replaced
-- by server truth). Persists a window roll as a side effect; never grants.
create or replace function public.ad_limit_state()
returns json
language plpgsql
security invoker
as $$
declare
  v_uid uuid := auth.uid();
  n     record;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;
  select * into n from public._ad_normalize_window(v_uid);
  return json_build_object(
    'granted',                false,
    'daily_count',            n.v_count,
    'daily_window_start_ms',  n.v_wstart,
    'home_last_claim_ms',     n.v_home
  );
end;
$$;

-- Authorizes and records ONE completed rewarded view, atomically, on the server
-- clock. p_kind is 'home' (Free Life — also enforces the 30-min cooldown) or
-- 'revive' (in-round — daily cap only). Returns { granted, ...state }; the app
-- grants a life only when granted = true. Never grants a life itself — it just
-- moves the authoritative counters and reports the verdict.
create or replace function public.claim_ad_view(p_kind text)
returns json
language plpgsql
security invoker
as $$
declare
  v_uid         uuid   := auth.uid();
  v_now         bigint := (extract(epoch from now()) * 1000)::bigint;
  v_cap         integer := 20;              -- RewardedAdLimits.dailyViewCap
  v_cooldown_ms bigint  := 30 * 60 * 1000;  -- RewardedAdLimits.homeCooldown
  n             record;
  v_granted     boolean := false;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;
  if p_kind not in ('home', 'revive') then
    raise exception 'invalid kind: %', p_kind;
  end if;

  select * into n from public._ad_normalize_window(v_uid);

  if n.v_count < v_cap then
    if p_kind = 'home' then
      v_granted := (n.v_home = 0 or v_now - n.v_home >= v_cooldown_ms);
    else
      v_granted := true;
    end if;
  end if;

  if v_granted then
    update public.profiles
       set ad_daily_count = n.v_count + 1,
           free_life_last_claim_ms =
             case when p_kind = 'home' then v_now else n.v_home end
     where id = v_uid;
    return json_build_object(
      'granted',                true,
      'daily_count',            n.v_count + 1,
      'daily_window_start_ms',  n.v_wstart,
      'home_last_claim_ms',     case when p_kind = 'home' then v_now else n.v_home end
    );
  end if;

  return json_build_object(
    'granted',                false,
    'daily_count',            n.v_count,
    'daily_window_start_ms',  n.v_wstart,
    'home_last_claim_ms',     n.v_home
  );
end;
$$;

revoke all on function public._ad_normalize_window(uuid) from public, anon, authenticated;
grant execute on function public.ad_limit_state()          to authenticated;
grant execute on function public.claim_ad_view(text)       to authenticated;
