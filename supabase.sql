-- MOON HUNT: chạy toàn bộ SQL này trong Supabase > SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.game_players (
  id text primary key,
  nickname text not null default 'Thợ săn',
  x double precision not null default 100,
  y double precision not null default 100,
  power integer not null default 1,
  score integer not null default 0,
  alive boolean not null default true,
  updated_at timestamptz not null default now()
);

create table if not exists public.game_knives (
  id uuid primary key default gen_random_uuid(),
  x double precision not null,
  y double precision not null,
  created_at timestamptz not null default now()
);

alter table public.game_players enable row level security;
alter table public.game_knives enable row level security;

drop policy if exists "players read" on public.game_players;
create policy "players read" on public.game_players for select to anon, authenticated using (true);
drop policy if exists "players insert" on public.game_players;
create policy "players insert" on public.game_players for insert to anon, authenticated with check (true);
drop policy if exists "players update" on public.game_players;
create policy "players update" on public.game_players for update to anon, authenticated using (true) with check (true);
drop policy if exists "knives read" on public.game_knives;
create policy "knives read" on public.game_knives for select to anon, authenticated using (true);
drop policy if exists "knives insert" on public.game_knives;
create policy "knives insert" on public.game_knives for insert to anon, authenticated with check (true);
drop policy if exists "knives delete" on public.game_knives;
create policy "knives delete" on public.game_knives for delete to anon, authenticated using (true);

-- Tạo 160 lưỡi dao ngẫu nhiên trong bản đồ 2600 x 1800.
insert into public.game_knives (x,y)
select 40 + random()*2520, 40 + random()*1720
from generate_series(1,160)
where not exists (select 1 from public.game_knives);

-- Nhặt dao theo cách nguyên tử: chỉ một người lấy được mỗi dao.
create or replace function public.collect_knife(knife_id uuid, player_id text)
returns boolean language plpgsql security definer set search_path=public as $$
declare got public.game_knives%rowtype;
begin
  select * into got from public.game_knives where id=knife_id for update;
  if not found then return false; end if;
  delete from public.game_knives where id=knife_id;
  update public.game_players
    set score=score+1, power=power+1, updated_at=now()
    where id=player_id and alive=true;
  insert into public.game_knives(x,y) values(40+random()*2520,40+random()*1720);
  return true;
end $$;

-- Chỉ cho phép săn người có sức mạnh thấp hơn; người thắng nhận thêm sức mạnh.
create or replace function public.hunt_player(hunter_id text, victim_id text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare h public.game_players%rowtype; v public.game_players%rowtype;
begin
  select * into h from public.game_players where id=hunter_id for update;
  select * into v from public.game_players where id=victim_id for update;
  if not found or h.id is null or v.id is null or not h.alive or not v.alive or h.power<=v.power then
    return jsonb_build_object('ok',false);
  end if;
  update public.game_players set alive=false, updated_at=now() where id=victim_id;
  update public.game_players set score=score+5, power=power+greatest(1,floor(v.power/2.0)::int), updated_at=now() where id=hunter_id;
  return jsonb_build_object('ok',true);
end $$;

grant execute on function public.collect_knife(uuid,text) to anon, authenticated;
grant execute on function public.hunt_player(text,text) to anon, authenticated;

-- Bật realtime cho hai bảng (nếu bảng đã có trong publication thì bỏ qua thông báo lỗi duplicate).
do $$ begin
  alter publication supabase_realtime add table public.game_players;
exception when duplicate_object then null; when undefined_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.game_knives;
exception when duplicate_object then null; when undefined_object then null; end $$;
