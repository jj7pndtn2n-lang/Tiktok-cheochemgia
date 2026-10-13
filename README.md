# MOON HUNT — game săn mồi multiplayer

Bản khởi đầu có bản đồ chung, nhặt lưỡi dao để tăng sức mạnh, săn người chơi yếu hơn, Top 10 trực tuyến, điều khiển cảm ứng và bàn phím. Người chơi bị hạ gục có thể vào lại bằng nút chơi lại.

## Cần chuẩn bị
- Tài khoản Supabase (gói miễn phí dùng để thử nghiệm được).
- Tài khoản GitHub và Vercel.
- iPhone có Safari để thao tác; tốt nhất tạo file bằng GitHub web.

## Bước 1 — Tạo database
1. Vào https://supabase.com và tạo project.
2. Mở **SQL Editor** → **New query**.
3. Mở file `supabase.sql`, sao chép toàn bộ nội dung, dán vào SQL Editor và bấm **Run**.
4. Vào **Project Settings → API** (hoặc Connect), sao chép **Project URL** và **anon/public key**. Không bao giờ đưa `service_role` key vào website.

## Bước 2 — Cấu hình game
1. Mở `index.html` trong GitHub hoặc trình soạn thảo.
2. Tìm hai dòng:
   `const SUPABASE_URL = "PASTE_SUPABASE_URL_HERE";`
   `const SUPABASE_ANON_KEY = "PASTE_SUPABASE_ANON_KEY_HERE";`
3. Thay phần trong dấu ngoặc kép bằng Project URL và anon/public key của project bạn.
4. Lưu file.

## Bước 3 — Đưa lên GitHub bằng iPhone
1. Vào https://github.com → đăng nhập → dấu `+` → **New repository**.
2. Đặt tên `moon-hunt-game`, chọn **Public** hoặc Private, tạo repository.
3. Chọn **Add file → Create new file**. Tạo `index.html`, dán nội dung file `index.html`, commit.
4. Làm tương tự với `supabase.sql` và `README.md`. (Có thể tải ZIP về, giải nén trên máy tính rồi upload cả ba file sẽ nhanh hơn.)

## Bước 4 — Deploy Vercel
1. Vào https://vercel.com → đăng nhập bằng GitHub.
2. Chọn **Add New → Project**, import `moon-hunt-game`.
3. Bấm **Deploy**. Đây là website tĩnh, không cần build command.
4. Mở link `.vercel.app` trên hai điện thoại/trình duyệt khác nhau để thử.

## Lưu ý quan trọng
- Đây là MVP để kiểm tra ý tưởng, chưa phải game chống gian lận ở quy mô lớn. Bản demo dùng anon key và chính sách database mở để dễ thử; người lạ có thể giả mạo điểm/vị trí. Trước khi công khai rộng, cần thêm xác thực, giới hạn tần suất, kiểm tra khoảng cách và chuyển toàn bộ logic di chuyển/chiến đấu sang máy chủ đáng tin cậy.
- Multiplayer hoạt động khi Supabase được cấu hình đúng và có internet. Nếu chưa nhập URL/key, game sẽ không cho vào.
- Bảng xếp hạng Top 10 đang sắp theo sức mạnh, rồi đến điểm.
- Bản đầu tạo dao và xử lý hạ gục qua RPC. Bản nâng cấp nên thêm phòng, tên hiển thị an toàn, hồi sinh, chống giả mạo và tối ưu đồng bộ.
