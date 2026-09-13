# Phân Tích Cách AyuGram Xử Lý Việc Copy/Save Tin Nhắn Trong Channel/Group Bị Restrict

Dựa vào việc đọc lịch sử commit (`git log` và `git show`) của dự án **AyuGramDesktop**, AyuGram xử lý việc bypass (vượt mặt) các hạn chế copy, forward và save tin nhắn từ các channel/group thông qua các phương pháp can thiệp trực tiếp vào mã nguồn Telegram gốc như sau:

## 1. Bypass Cờ Hạn Chế Nội Dung (Content Restrictions Bypass)
*Commit liên quan:* `53392d6e5d` ("feat: bypass client-side restrictions & minor adjustments")

Telegram sử dụng lớp `Data::UnavailableReason` để trả về các lý do nội dung bị khóa (ví dụ: vi phạm bản quyền, nhạy cảm, chặn nền tảng). AyuGram đã ghi đè logic này:
- Thay vì lấy danh sách lý do từ server gửi về (`MTPRestrictionReason`), các hàm như `Extract` và `Compute` trong `Telegram/SourceFiles/data/data_peer.cpp` được sửa lại để luôn trả về giá trị **rỗng** (empty).
- Hệ quả là client "nghĩ" rằng không có bất kỳ lệnh cấm nào từ server, hiển thị nội dung bình thường thay vì che đi hoặc hiện thông báo "This message is unavailable".

## 2. Tách Biệt Trạng Thái "No-Forwards" Thành 2 Cờ Riêng Biệt
*Commit liên quan:* `12879207ef` ("fix: restrict saving content toggle") & `0813121f58` ("feat: ignore restrictions")

Khi chủ group/channel bật tính năng "Restrict saving content" (Cấm copy/forward), server Telegram sẽ trả về cờ `noforwards`. AyuGram đã thay thế thư viện Type Language (TL) của Telegram bằng một bản fork riêng (`AyuGram/lib_tl`) và tách cờ này thành 2 giá trị trong `data_session.cpp` và `PeerData`:
- **`Flag::NoForwards`**: Đây là cờ định đoạt việc client có cho phép copy/forward hay không. AyuGram luôn ép cờ này để hàm `allowsForwarding()` trả về `true` (cho phép sao chép tự do).
- **`Flag::AyuNoForwards`**: Lưu lại trạng thái *thật* của server. Việc này rất tinh tế vì nó giúp giao diện Cài đặt Nhóm/Kênh (Group Settings) vẫn hiển thị đúng trạng thái On/Off của nút "Restrict saving content" dành cho Admin, giúp Admin biết được group này có đang bị giới hạn với người thường hay không.

## 3. Khôi Phục Liên Tục Các Tính Năng Bị Upstream Telegram Chặn
*Các commit liên quan:* `224fdc1864` ("Returned back freedom to copy links even in non-forwardable histories"), `b64c610abb` ("Fixed ability to copy shared links for channels with select restriction.")

Khi Telegram Desktop bản gốc (upstream) bổ sung thêm các dòng code chặn UI như vô hiệu hóa Context Menu (chuột phải) hoặc chặn bôi đen chữ trong các group bị cấm:
- AyuGram tạo các bản vá (patch) để xóa bỏ các điều kiện chặn (ví dụ: `if (!_provider->hasSelectRestriction())`).
- Bổ sung lại các nút "Copy Link", "Save Media" vào Menu kể cả khi thuộc tính của tin nhắn bị đánh dấu là `forbidsForward`.

---
**Tóm lại:** Thay vì phải sửa từng UI một một cách thủ công, AyuGram chọn cách đánh chặn từ tầng nhận Data của Server (TL Parser & Data Peer). Nó lừa UI của Telegram Desktop rằng đoạn chat này "Không hề bị chặn", đồng thời lưu riêng 1 biến ẩn để giữ đúng trạng thái logic cho người dùng Admin.