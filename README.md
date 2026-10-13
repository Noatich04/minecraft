# Voxel Survival — Godot 4

Prototype game voxel sinh tồn lấy cảm hứng từ Minecraft, viết bằng GDScript cho Godot 4.3+.

## Tính năng hiện có

- Thế giới voxel 64 × 64, sinh địa hình theo noise với đồi/núi, lớp cỏ/đất/đá, hang động đơn giản và cây.
- Mesh và va chạm được ghép theo chunk 16 × 16 để tránh tạo một physics body cho từng khối.
- Góc nhìn người thứ nhất, di chuyển WASD, nhảy, trọng lực và va chạm với địa hình.
- Phá khối bằng chuột trái, nhặt khối vào túi đồ; đặt khối bằng chuột phải.
- Thanh chọn nhanh 1–5, giao diện túi đồ E và công thức chế tạo mẫu C (2 đất → 1 đá).
- Slime đuổi theo người chơi, gây sát thương; đánh slime bằng chuột trái.
- Máu, đói và hồi sinh; lưu/tải seed thế giới, các khối đã sửa, vị trí, máu, đói và túi đồ.
- Tệp lưu nằm trong `user://voxel_world.json` của Godot, không nằm trong thư mục repository.

## Cách chạy trên Windows

1. Cài Godot Engine **4.3 trở lên** từ https://godotengine.org/download/.
2. Mở Git Bash hoặc Terminal và chạy:

   ```bash
   git clone https://github.com/Noatich04/minecraft.git
   cd minecraft
   ```

3. Mở Godot Project Manager → **Import** → chọn file `project.godot` trong thư mục vừa tải.
4. Mở project, đợi import/scan hoàn tất rồi nhấn **F6** để chạy scene hiện tại hoặc **F5** để chạy project.
5. Nhấp vào cửa sổ game để bắt chuột. Nhấn **Esc** để thả chuột; nhấp lại để bắt chuột lần nữa.

## Điều khiển

| Phím | Tác dụng |
|---|---|
| W / A / S / D | Di chuyển |
| Space | Nhảy |
| Chuột | Nhìn xung quanh |
| Chuột trái | Phá khối hoặc đánh slime |
| Chuột phải | Đặt khối đang chọn |
| 1–5 | Chọn cỏ / đất / đá / gỗ / lá |
| E | Mở hoặc đóng túi đồ |
| C | Chế tạo công thức mẫu |
| F5 | Lưu thế giới |
| F9 | Tải lần lưu gần nhất |
| Esc | Thả chuột |

## Checklist kiểm thử thủ công

- [ ] Đi sát vách núi/cây và xác nhận nhân vật không xuyên qua địa hình.
- [ ] Nhảy lên khối, rơi xuống và xác nhận trọng lực/va chạm sàn hoạt động.
- [ ] Nhìn vào một khối ở trong tầm với và nhấn chuột trái: khối biến mất, số lượng trong túi đồ tăng.
- [ ] Chọn một loại khối có số lượng lớn hơn 0, nhìn vào mặt khối và nhấn chuột phải: khối mới xuất hiện, số lượng giảm.
- [ ] Thử đặt khối ngay trong người chơi: thao tác phải bị chặn.
- [ ] Để slime tiếp cận: máu giảm; đánh slime nhiều lần bằng chuột trái để hạ nó.
- [ ] Phá/đặt vài khối, di chuyển, nhấn F5; sau đó thay đổi thế giới và nhấn F9. Kiểm tra khối, vị trí và túi đồ quay lại trạng thái đã lưu.

## Lưu ý

Đây là **bản prototype có thể mở rộng**, chưa phải bản sao hoàn chỉnh của Minecraft. Chế tạo hiện chỉ có một công thức minh họa; chưa có bàn chế tạo, công cụ, âm thanh, hoạt ảnh, chu kỳ ngày/đêm, hệ thống lưu nhiều slot hoặc tối ưu hóa streaming thế giới vô hạn. Hãy chạy checklist trên bằng Godot sau khi clone để xác nhận theo máy của bạn; thay đổi code từ GitHub chưa được kiểm thử bằng cách chạy game trong phiên này.
