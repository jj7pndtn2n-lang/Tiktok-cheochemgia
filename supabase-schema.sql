create extension if not exists pgcrypto;

create table if not exists public.admins(
 user_id uuid primary key references auth.users(id) on delete cascade,
 created_at timestamptz not null default now()
);

create table if not exists public.catalog_items(
 id uuid primary key default gen_random_uuid(),
 type text not null check(type in('gun','character','other')),
 game text not null default 'FF' check(game in('FF','FFMAX')),
 name text not null,
 icon text not null default '🎮',
 image_url text,
 badge text not null default 'NEW',
 detail_url text,
 active boolean not null default true,
 sort_order integer not null default 0,
 created_at timestamptz not null default now()
);

create table if not exists public.sim_keys(
 id uuid primary key default gen_random_uuid(),
 key_code text unique not null,
 active boolean not null default true,
 expires_at timestamptz,
 max_uses integer not null default 1,
 used_count integer not null default 0,
 created_at timestamptz not null default now()
);

alter table public.admins enable row level security;
alter table public.catalog_items enable row level security;
alter table public.sim_keys enable row level security;

drop policy if exists "admin self read" on public.admins;
create policy "admin self read" on public.admins for select to authenticated using(user_id=auth.uid());

drop policy if exists "public active catalog" on public.catalog_items;
create policy "public active catalog" on public.catalog_items for select to anon,authenticated using(active=true);

drop policy if exists "admin insert catalog" on public.catalog_items;
create policy "admin insert catalog" on public.catalog_items for insert to authenticated
with check(exists(select 1 from public.admins where user_id=auth.uid()));

drop policy if exists "admin update catalog" on public.catalog_items;
create policy "admin update catalog" on public.catalog_items for update to authenticated
using(exists(select 1 from public.admins where user_id=auth.uid()))
with check(exists(select 1 from public.admins where user_id=auth.uid()));

drop policy if exists "admin delete catalog" on public.catalog_items;
create policy "admin delete catalog" on public.catalog_items for delete to authenticated
using(exists(select 1 from public.admins where user_id=auth.uid()));

revoke all on public.sim_keys from anon,authenticated;

create or replace function public.redeem_key(p_key text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare k public.sim_keys;
begin
 select * into k from public.sim_keys where key_code=trim(p_key) and active=true for update;
 if not found then return jsonb_build_object('ok',false,'message','Key không hợp lệ'); end if;
 if k.expires_at is not null and k.expires_at<=now() then return jsonb_build_object('ok',false,'message','Key đã hết hạn'); end if;
 if k.used_count>=k.max_uses then return jsonb_build_object('ok',false,'message','Key đã hết lượt sử dụng'); end if;
 update public.sim_keys set used_count=used_count+1,
 active=case when used_count+1>=max_uses then false else active end where id=k.id;
 return jsonb_build_object('ok',true,'message','Key hợp lệ');
end $$;

create or replace function public.admin_create_key(p_key text,p_max_uses integer default 1)
returns jsonb language plpgsql security definer set search_path=public as $$
begin
 if not exists(select 1 from public.admins where user_id=auth.uid()) then
  return jsonb_build_object('ok',false,'message','Không có quyền admin');
 end if;
 insert into public.sim_keys(key_code,max_uses) values(trim(p_key),greatest(1,p_max_uses));
 return jsonb_build_object('ok',true,'message','Đã tạo key');
exception when unique_violation then
 return jsonb_build_object('ok',false,'message','Key đã tồn tại');
end $$;

revoke all on function public.redeem_key(text) from public;
grant execute on function public.redeem_key(text) to anon,authenticated;
revoke all on function public.admin_create_key(text,integer) from public;
grant execute on function public.admin_create_key(text,integer) to authenticated;

insert into storage.buckets(id,name,public) values('catalog-images','catalog-images',true)
on conflict(id) do update set public=true;

drop policy if exists "public read catalog images" on storage.objects;
create policy "public read catalog images" on storage.objects for select
to anon,authenticated using(bucket_id='catalog-images');

drop policy if exists "admin upload catalog images" on storage.objects;
create policy "admin upload catalog images" on storage.objects for insert
to authenticated with check(bucket_id='catalog-images' and exists(select 1 from public.admins where user_id=auth.uid()));

drop policy if exists "admin update catalog images" on storage.objects;
create policy "admin update catalog images" on storage.objects for update
to authenticated using(bucket_id='catalog-images' and exists(select 1 from public.admins where user_id=auth.uid()))
with check(bucket_id='catalog-images' and exists(select 1 from public.admins where user_id=auth.uid()));

drop policy if exists "admin delete catalog images" on storage.objects;
create policy "admin delete catalog images" on storage.objects for delete
to authenticated using(bucket_id='catalog-images' and exists(select 1 from public.admins where user_id=auth.uid()));

insert into public.catalog_items(type,game,name,icon,badge,sort_order) values
('gun','FF','Cyber Rifle','🔫','NEW',10),
('gun','FF','Golden Eagle','💛','NEW',20),
('character','FF','Crimson Warrior','🔥','NEW',30),
('character','FFMAX','Cyber Phantom','🤖','NEW',40),
('other','FF','Gold Aura','✨','NEW',50)
on conflict do nothing;
