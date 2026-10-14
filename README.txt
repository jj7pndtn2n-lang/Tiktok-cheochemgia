# MOON HUNT — bản ZIP sẵn sàng tải lên

## Nội dung
- `index.html`: game hiện tại đã tích hợp sprite PNG rồng lửa.
- `assets/sprites/dragon-flame-purple-red.png`: hiệu ứng rồng tím đỏ chính.
- `assets/sprites/dragon-flame-level80.png`: hiệu ứng cấp 80 mạnh hơn, nhiều tia lửa.
- Các `dragon-flame-*.png`: biến thể màu cho cấp 41–79.
- `assets/sprites/dragon-embers.png`: atlas hạt lửa trong suốt dùng để mở rộng hiệu ứng.

## Cách đưa game lên hosting
1. Giải nén ZIP.
2. Tải lên **toàn bộ nội dung** trong thư mục, không chỉ riêng `index.html`.
3. Giữ nguyên thư mục `assets/sprites/` và cấu trúc đường dẫn.
4. Mở URL website và thử nhặt lưỡi liềm; ở 41 điểm trở lên sprite rồng xuất hiện, ở 80 điểm dùng sprite cấp tối đa.

## Lưu ý
Game vẫn sử dụng cấu trúc HTML/Canvas và cơ chế hiện có. Hiệu ứng PNG là lớp phủ trong suốt; hiệu ứng vẽ bằng Canvas cũ vẫn được giữ làm lớp chuyển động phụ/fallback.
