-- RUBU SCRIPT / Supabase schema
-- Chạy toàn bộ file này trong Supabase SQL Editor.
-- KHÔNG đưa service_role key vào website.

create extension if not exists pgcrypto;

create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text not null unique,
  category text not null,
  image_url text,
  external_link text,
  description text,
  content text,
  code text,
  views bigint not null default 0,
  featured boolean not null default false,
  published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists posts_published_idx on public.posts(published);
create index if not exists posts_category_idx on public.posts(category);
create index if not exists posts_created_at_idx on public.posts(created_at desc);
create index if not exists posts_slug_idx on public.posts(slug);

alter table public.posts enable row level security;
alter table public.admins enable row level security;

-- SECURITY DEFINER để kiểm tra admin mà không tạo vòng lặp RLS.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admins
    where user_id = auth.uid()
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

-- Người dùng không đăng nhập: chỉ đọc bài công khai.
drop policy if exists "public read published posts" on public.posts;
create policy "public read published posts"
on public.posts for select
to anon, authenticated
using (published = true or public.is_admin());

-- Chỉ Admin được thêm/sửa/xóa.
drop policy if exists "admins insert posts" on public.posts;
create policy "admins insert posts"
on public.posts for insert
to authenticated
with check (public.is_admin());

drop policy if exists "admins update posts" on public.posts;
create policy "admins update posts"
on public.posts for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "admins delete posts" on public.posts;
create policy "admins delete posts"
on public.posts for delete
to authenticated
using (public.is_admin());

-- RPC tăng view: khách không cần đăng nhập.
-- Mỗi lần mở trang chi tiết sẽ +1.
create or replace function public.increment_post_view(p_post_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.posts
  set views = views + 1,
      updated_at = now()
  where id = p_post_id
    and published = true;
end;
$$;

grant execute on function public.increment_post_view(uuid) to anon, authenticated;

-- Storage: bucket public để thumbnail có URL xem trực tiếp.
insert into storage.buckets (id, name, public)
values ('post-images', 'post-images', true)
on conflict (id) do update set public = true;

drop policy if exists "public read post images" on storage.objects;
create policy "public read post images"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'post-images');

drop policy if exists "admins upload post images" on storage.objects;
create policy "admins upload post images"
on storage.objects for insert
to authenticated
with check (bucket_id = 'post-images' and public.is_admin());

drop policy if exists "admins update post images" on storage.objects;
create policy "admins update post images"
on storage.objects for update
to authenticated
using (bucket_id = 'post-images' and public.is_admin())
with check (bucket_id = 'post-images' and public.is_admin());

drop policy if exists "admins delete post images" on storage.objects;
create policy "admins delete post images"
on storage.objects for delete
to authenticated
using (bucket_id = 'post-images' and public.is_admin());

-- Tự cập nhật updated_at.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists posts_set_updated_at on public.posts;
create trigger posts_set_updated_at
before update on public.posts
for each row execute function public.set_updated_at();
