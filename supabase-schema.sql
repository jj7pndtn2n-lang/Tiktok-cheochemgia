-- ============================================================
-- SKINTOOLS V3 - SUPABASE DATABASE
-- ============================================================

create extension if not exists pgcrypto;


-- ============================================================
-- 1. ADMIN
-- ============================================================

create table if not exists public.admins (
    user_id uuid primary key references auth.users(id) on delete cascade,
    created_at timestamptz default now()
);


-- ============================================================
-- 2. CATALOG ITEMS
--    Nội dung skin / súng / nhân vật / hiệu ứng
-- ============================================================

create table if not exists public.catalog_items (
    id uuid primary key default gen_random_uuid(),

    name text not null,

    type text not null
        check (type in ('gun', 'character', 'other')),

    game text not null default 'FF'
        check (game in ('FF', 'FFMAX')),

    icon text default '🎮',

    image_url text,

    badge text default 'NEW',

    detail_url text,

    active boolean default true,

    sort_order integer default 0,

    created_at timestamptz default now()
);


-- ============================================================
-- 3. KEY
-- ============================================================

create table if not exists public.sim_keys (
    id uuid primary key default gen_random_uuid(),

    key_code text unique not null,

    active boolean default true,

    expires_at timestamptz,

    max_uses integer default 1,

    used_count integer default 0,

    created_at timestamptz default now()
);


-- ============================================================
-- 4. ENABLE RLS
-- ============================================================

alter table public.admins enable row level security;

alter table public.catalog_items enable row level security;

alter table public.sim_keys enable row level security;


-- ============================================================
-- 5. ADMIN POLICIES
-- ============================================================

drop policy if exists "admin read self"
on public.admins;

create policy "admin read self"
on public.admins
for select
to authenticated
using (
    user_id = auth.uid()
);


-- ============================================================
-- 6. PUBLIC CATALOG
-- ============================================================

drop policy if exists "public catalog"
on public.catalog_items;

create policy "public catalog"
on public.catalog_items
for select
to anon, authenticated
using (
    active = true
);


-- ============================================================
-- 7. ADMIN ADD CATALOG
-- ============================================================

drop policy if exists "admin insert catalog"
on public.catalog_items;

create policy "admin insert catalog"
on public.catalog_items
for insert
to authenticated
with check (
    exists (
        select 1
        from public.admins
        where user_id = auth.uid()
    )
);


-- ============================================================
-- 8. ADMIN UPDATE CATALOG
-- ============================================================

drop policy if exists "admin update catalog"
on public.catalog_items;

create policy "admin update catalog"
on public.catalog_items
for update
to authenticated
using (
    exists (
        select 1
        from public.admins
        where user_id = auth.uid()
    )
)
with check (
    exists (
        select 1
        from public.admins
        where user_id = auth.uid()
    )
);


-- ============================================================
-- 9. ADMIN DELETE CATALOG
-- ============================================================

drop policy if exists "admin delete catalog"
on public.catalog_items;

create policy "admin delete catalog"
on public.catalog_items
for delete
to authenticated
using (
    exists (
        select 1
        from public.admins
        where user_id = auth.uid()
    )
);


-- ============================================================
-- 10. KHÓA TRUY CẬP TRỰC TIẾP BẢNG KEY
-- ============================================================

revoke all
on public.sim_keys
from anon, authenticated;


-- ============================================================
-- 11. FUNCTION XÁC THỰC KEY
-- ============================================================

create or replace function public.redeem_key(
    p_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$

declare
    k public.sim_keys;

begin

    select *
    into k
    from public.sim_keys
    where key_code = trim(p_key)
      and active = true
    for update;


    -- Không tìm thấy key
    if not found then

        return jsonb_build_object(
            'ok', false,
            'message', 'Key không hợp lệ'
        );

    end if;


    -- Key hết hạn
    if k.expires_at is not null
       and k.expires_at <= now() then

        return jsonb_build_object(
            'ok', false,
            'message', 'Key đã hết hạn'
        );

    end if;


    -- Key hết lượt sử dụng
    if k.used_count >= k.max_uses then

        return jsonb_build_object(
            'ok', false,
            'message', 'Key đã hết lượt sử dụng'
        );

    end if;


    -- Tăng số lượt sử dụng
    update public.sim_keys

    set
        used_count = used_count + 1,

        active =
            case
                when used_count + 1 >= max_uses
                then false
                else active
            end

    where id = k.id;


    return jsonb_build_object(
        'ok', true,
        'message', 'Key hợp lệ'
    );

end;

$$;


-- Cho phép người dùng gọi function
grant execute
on function public.redeem_key(text)
to anon, authenticated;


-- ============================================================
-- 12. ADMIN TẠO KEY
-- ============================================================

create or replace function public.admin_create_key(
    p_key text,
    p_max_uses integer default 1
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$

begin

    -- Kiểm tra quyền admin

    if not exists (
        select 1
        from public.admins
        where user_id = auth.uid()
    ) then

        return jsonb_build_object(
            'ok', false,
            'message', 'Bạn không có quyền admin'
        );

    end if;


    -- Kiểm tra key rỗng

    if trim(p_key) = '' then

        return jsonb_build_object(
            'ok', false,
            'message', 'Key không được để trống'
        );

    end if;


    -- Tạo key

    insert into public.sim_keys (
        key_code,
        max_uses
    )

    values (
        trim(p_key),
        greatest(1, p_max_uses)
    );


    return jsonb_build_object(
        'ok', true,
        'message', 'Đã tạo key thành công'
    );


exception

    when unique_violation then

        return jsonb_build_object(
            'ok', false,
            'message', 'Key đã tồn tại'
        );

end;

$$;


grant execute
on function public.admin_create_key(text, integer)
to authenticated;


-- ============================================================
-- 13. STORAGE BUCKET CHO ẢNH SKIN
-- ============================================================

insert into storage.buckets (
    id,
    name,
    public
)

values (
    'catalog-images',
    'catalog-images',
    true
)

on conflict (id)
do nothing;


-- ============================================================
-- 14. PUBLIC XEM ẢNH
-- ============================================================

drop policy if exists "public catalog images"
on storage.objects;

create policy "public catalog images"
on storage.objects
for select
to public
using (
    bucket_id = 'catalog-images'
);


-- ============================================================
-- 15. ADMIN UPLOAD ẢNH
-- ============================================================

drop policy if exists "admin upload catalog images"
on storage.objects;

create policy "admin upload catalog images"
on storage.objects
for insert
to authenticated
with check (
    bucket_id = 'catalog-images'

    and exists (
        select 1
        from public.admins
        where user_id = auth.uid()
    )
);


-- ============================================================
-- 16. ADMIN XÓA ẢNH
-- ============================================================

drop policy if exists "admin delete catalog images"
on storage.objects;

create policy "admin delete catalog images"
on storage.objects
for delete
to authenticated
using (
    bucket_id = 'catalog-images'

    and exists (
        select 1
        from public.admins
        where user_id = auth.uid()
    )
);


-- ============================================================
-- HOÀN TẤT
-- ============================================================
