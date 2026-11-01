-- Grafik przerw: konfiguracja bazy w Supabase.
-- Wklej całość w: Supabase → SQL Editor → New query → Run.
-- Dzień (i reset o północy) liczony jest wg strefy Europe/Warsaw.
-- Limit przerw na osobę: 2 (zmienna max_per_person poniżej).

create table if not exists public.slots (
  day  date not null,
  slot int  not null,      -- minuty od północy, np. 600 = 10:00
  name text not null,
  uid  text not null,      -- losowy identyfikator przeglądarki
  primary key (day, slot)
);

-- Tabela zamknięta dla publicznego dostępu: wszystko idzie przez funkcje poniżej.
alter table public.slots enable row level security;
revoke all on public.slots from anon, authenticated;

create or replace function public.get_state(p_uid text)
returns json language plpgsql security definer set search_path = public as $$
declare
  local_now timestamp := now() at time zone 'Europe/Warsaw';
  d date := (now() at time zone 'Europe/Warsaw')::date;
begin
  return json_build_object(
    'date',    to_char(d, 'YYYY-MM-DD'),
    'minutes', extract(hour from local_now)::int * 60 + extract(minute from local_now)::int,
    'max',     2,
    'slots',   coalesce((
                 select json_agg(json_build_object('slot', slot, 'name', name, 'mine', uid = p_uid) order by slot)
                 from slots where day = d
               ), '[]'::json)
  );
end $$;

create or replace function public.claim_slot(p_slot int, p_name text, p_uid text)
returns json language plpgsql security definer set search_path = public as $$
declare
  max_per_person int := 2;
  local_now timestamp := now() at time zone 'Europe/Warsaw';
  d date := (now() at time zone 'Europe/Warsaw')::date;
  mins int := extract(hour from local_now)::int * 60 + extract(minute from local_now)::int;
  nm text := left(btrim(regexp_replace(coalesce(p_name, ''), '\s+', ' ', 'g')), 24);
  cnt int;
begin
  if p_uid is null or p_uid !~ '^[A-Za-z0-9_-]{8,64}$' then
    return json_build_object('error', 'bad_client');
  end if;
  if p_slot is null or p_slot < 600 or p_slot >= 1200 or (p_slot - 600) % 15 <> 0 then
    return json_build_object('error', 'bad_slot');
  end if;
  if nm = '' then return json_build_object('error', 'no_name'); end if;
  if p_slot + 15 <= mins then return json_build_object('error', 'past'); end if;

  -- zapisy jednej osoby są szeregowane, żeby limit był niezawodny
  perform pg_advisory_xact_lock(hashtext(d::text || p_uid));

  if exists (select 1 from slots where day = d and slot = p_slot) then
    return json_build_object('error', 'taken');
  end if;

  select count(*) into cnt from slots where day = d and uid = p_uid;
  if cnt >= max_per_person then
    return json_build_object('error', 'limit');
  end if;

  insert into slots (day, slot, name, uid) values (d, p_slot, nm, p_uid)
  on conflict do nothing;
  if not found then return json_build_object('error', 'taken'); end if;

  delete from slots where day < d;   -- sprzątanie poprzednich dni
  return json_build_object('ok', true);
end $$;

create or replace function public.release_slot(p_slot int, p_uid text)
returns json language plpgsql security definer set search_path = public as $$
declare
  d date := (now() at time zone 'Europe/Warsaw')::date;
begin
  delete from slots where day = d and slot = p_slot and uid = p_uid;
  return json_build_object('ok', true);
end $$;

revoke all on function public.get_state(text) from public;
revoke all on function public.claim_slot(int, text, text) from public;
revoke all on function public.release_slot(int, text) from public;
grant execute on function public.get_state(text) to anon, authenticated;
grant execute on function public.claim_slot(int, text, text) to anon, authenticated;
grant execute on function public.release_slot(int, text) to anon, authenticated;
