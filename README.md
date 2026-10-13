# Voxel Survival — Godot 4

Prototype game voxel sinh tồn lấy cảm hứng từ Minecraft, viết bằng GDScript cho Godot 4.x.

## Tính năng hiện có

- Thế giới voxel 64 × 64, sinh địa hình theo noise với đồi/núi, lớp cỏ/đất/đá, hang động đơn giản và cây.
- Mesh và va chạm được ghép theo chunk 16 × 16.
- Góc nhìn người thứ nhất, di chuyển WASD, nhảy, trọng lực và va chạm địa hình.
- Phá khối bằng chuột trái, nhặt khối vào túi đồ; đặt khối bằng chuột phải.
- Slime đuổi theo người chơi và gây sát thương; slime có 5 máu và rơi gel khi bị hạ.
- Hệ thống sinh tồn: 20 máu, 20 điểm đói; đói giảm theo thời gian, khi hết đói người chơi mất máu và hồi sinh khi gục.
- Chế tạo nhiều công thức: gỗ thành ván, ván thành que, cuốc gỗ, kiếm gỗ, cuốc đá, kiếm đá và đuốc.
- Kiếm gỗ gây 3 sát thương, kiếm đá gây 5 sát thương lên slime.
- Túi đồ E hiển thị số lượng khối/vật phẩm và danh sách công thức.
- F5 lưu và F9 tải thế giới, khối đã sửa, vị trí, máu, đói và túi đồ.
- Tệp lưu nằm trong `user://voxel_world.json` của Godot, không nằm trong thư mục repository.

## Cách chạy trên Windows

1. Tải Godot Engine bản thường (không phải .NET) từ https://godotengine.org/download/.
2. Tải ZIP của repository và giải nén, hoặc clone:
   ```bash
   git clone https://github.com/Noatich04/minecraft.git
   cd minecraft
   ```
3. Mở Godot Project Manager → **Import** → chọn file `project.godot`.
4. Nhấn **F5** để chạy project chính. Nhấp vào cửa sổ game để bắt chuột; nhấn **Esc** để thả chuột.

## Điều khiển

| Phím | Tác dụng |
|---|---|
| W / A / S / D | Di chuyển |
| Space | Nhảy |
| Chuột | Nhìn xung quanh |
| Chuột trái | Phá khối hoặc đánh slime |
| Chuột phải | Đặt khối đang chọn |
| 1–6 | Chọn cỏ / đất / đá / gỗ / lá / ván gỗ |
| 7 / 8 | Chọn kiếm gỗ / kiếm đá |
| E | Mở hoặc đóng túi đồ và danh sách công thức |
| C | 1 gỗ → 4 ván gỗ |
| V | 2 ván gỗ → 4 que gỗ |
| B | 3 ván + 2 que → cuốc gỗ |
| N | 2 ván + 1 que → kiếm gỗ |
| M | 3 đá + 2 que → cuốc đá |
| J | 2 đá + 1 que → kiếm đá |
| K | 1 gỗ + 1 que → 4 đuốc |
| F5 / F9 | Lưu / tải thế giới |
| Esc | Thả chuột |

## Checklist kiểm thử thủ công

- [ ] Nhấn F5 để chạy project, kiểm tra không có lỗi đỏ trong Output.
- [ ] Đi sát vách núi/cây và xác nhận nhân vật không xuyên qua địa hình.
- [ ] Để slime tiếp cận: máu giảm; đánh slime bằng chuột trái để hạ nó và nhận gel slime.
- [ ] Nhấn E để xem túi đồ/công thức.
- [ ] Nhấn C để đổi 1 gỗ thành 4 ván; số gỗ giảm và ván tăng.
- [ ] Nhấn V để đổi 2 ván thành 4 que; thử chế tạo cuốc/kiếm gỗ bằng B/N.
- [ ] Dùng đá và que chế tạo cuốc/kiếm đá bằng M/J; nhấn 7 hoặc 8 để chọn kiếm.
- [ ] Nhấn K để chế tạo đuốc nếu có gỗ và que.
- [ ] Thử chế tạo khi thiếu nguyên liệu; công thức không được trừ vật phẩm nếu chế tạo thất bại.
- [ ] Nhấn F5, thay đổi thế giới, nhấn F9 và kiểm tra trạng thái được khôi phục.

## Lưu ý

Đây vẫn là prototype, chưa phải bản sao hoàn chỉnh của Minecraft. Cuốc hiện là vật phẩm chế tạo để mở rộng hệ thống; đào khối vẫn đang thực hiện bằng một lần nhấp và chưa có độ bền công cụ, bàn chế tạo dạng lưới, chu kỳ ngày/đêm hoặc streaming thế giới vô hạn. Những thay đổi trên cần được chạy thử trong Godot 4.7.2; chưa có trình chạy Godot trong phiên cập nhật này nên chưa thể xác nhận biên dịch/runtime trực tiếp.
