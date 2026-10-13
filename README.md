# Voxel Survival — Godot 4

Prototype game voxel sinh tồn lấy cảm hứng từ Minecraft, viết bằng GDScript cho Godot 4.x.

## Tính năng hiện có

- Trang chủ trước khi vào game: Chơi đơn, Máy chủ, Cài đặt, Thoát game.
- Màn hình Máy chủ có mục thế giới thử nghiệm và thông báo rõ đây hiện là chơi cục bộ; multiplayer online chưa được triển khai.
- Thế giới voxel 64 × 64, sinh địa hình theo noise với đồi/núi, lớp cỏ/đất/đá, hang động đơn giản và cây.
- Góc nhìn người thứ nhất, di chuyển WASD, nhảy, trọng lực và va chạm địa hình.
- Phá/đặt khối, túi đồ, máu/đói, slime đuổi theo và gây sát thương.
- Chế tạo ván, que, cuốc gỗ, kiếm gỗ, cuốc đá, kiếm đá và đuốc.
- F5 lưu và F9 tải thế giới.

## Cách chạy trên Windows

1. Tải Godot Engine bản thường (không phải .NET) từ https://godotengine.org/download/.
2. Tải ZIP repository và giải nén.
3. Mở Godot Project Manager → **Import** → chọn file `project.godot`.
4. Nhấn **F5**. Game sẽ mở trang chủ trước.
5. Chọn **Chơi đơn** để vào thế giới, hoặc **Máy chủ** để mở màn hình lựa chọn thế giới thử nghiệm.

## Điều khiển trong game

| Phím | Tác dụng |
|---|---|
| W / A / S / D | Di chuyển |
| Space | Nhảy |
| Chuột | Nhìn xung quanh |
| Chuột trái | Phá khối hoặc đánh slime |
| Chuột phải | Đặt khối đang chọn |
| 1–6 | Chọn khối |
| 7 / 8 | Chọn kiếm gỗ / kiếm đá |
| E | Mở túi đồ và công thức |
| C / V | Chế tạo ván / que |
| B / N | Chế tạo cuốc gỗ / kiếm gỗ |
| M / J | Chế tạo cuốc đá / kiếm đá |
| K | Chế tạo đuốc |
| F5 / F9 | Lưu / tải thế giới |
| Esc | Thả chuột |

## Lưu ý và kiểm thử

Màn hình Máy chủ hiện chỉ là giao diện chọn thế giới thử nghiệm cục bộ; kết nối máy chủ trực tuyến, tạo phòng mạng và đồng bộ nhiều người chơi chưa được triển khai. Hãy thử F5, chọn Chơi đơn, quay lại bằng cách đóng game và chạy lại để kiểm tra trang chủ; sau đó thử Máy chủ → Vào thế giới thử nghiệm. Chưa thể chạy trực tiếp Godot trong môi trường cập nhật này, nên cần kiểm tra thực tế trong Godot 4.7.2.
