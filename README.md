# RUBU SCRIPT

Website thư viện bài viết/script Roblox với:
- Người dùng không cần đăng ký/đăng nhập.
- Admin đăng nhập tại `/admin.html`.
- Thêm/sửa/xóa bài viết trực tiếp trên web.
- Upload thumbnail lên Supabase Storage.
- Tìm kiếm + lọc danh mục.
- Lượt xem.
- Trang chi tiết + nút Copy Script.
- Responsive cho điện thoại.

## 1. Tạo Supabase

1. Tạo project trên Supabase.
2. Vào SQL Editor và chạy toàn bộ `schema.sql`.
3. Vào Authentication > Users và tạo user Admin bằng email + password.
4. Lấy UUID của user vừa tạo.
5. Chạy SQL:

```sql
insert into public.admins (user_id)
values ('UUID_CUA_ADMIN');
```

## 2. Cấu hình website

Mở `config.js`:

```js
window.SUPABASE_URL = "https://xxxxx.supabase.co";
window.SUPABASE_ANON_KEY = "eyJ...";
```

Chỉ dùng Publishable/Anon key. Không dùng `service_role`.

## 3. Deploy Vercel

Upload các file lên GitHub, sau đó import repository vào Vercel.

Các file chính:
- index.html: trang chủ
- article.html: trang chi tiết
- admin.html: dashboard
- app.js: logic trang chủ
- article.js: logic bài viết
- admin.js: logic admin
- style.css: giao diện
- config.js: cấu hình Supabase
- schema.sql: database + RLS + storage

## 4. Thêm bài

Mở:
`https://TEN-MIEN-CUA-BAN/admin.html`

Đăng nhập Admin -> + Bài mới -> nhập thông tin -> Lưu bài viết.

Người dùng không có tài khoản và không thấy màn hình Admin trừ khi họ biết URL.

## Lưu ý

Website chỉ lưu/hiển thị nội dung văn bản và code do bạn đăng. Không chạy code Roblox trên website.
