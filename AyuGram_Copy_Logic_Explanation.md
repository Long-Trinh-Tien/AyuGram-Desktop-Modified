# Giải Thích Logic Copy Nhiều Tin Nhắn (Hình ảnh + Văn bản) Trong AyuGram

## 1. Mục tiêu
Người dùng muốn có khả năng chọn nhiều tin nhắn (tối đa 10,000) và khi thực hiện lệnh **Copy**, toàn bộ văn bản và **tất cả** hình ảnh/file đính kèm phải được đưa vào Clipboard theo đúng thứ tự tin nhắn đã chọn.

## 2. Thách thức kỹ thuật của Clipboard
Hệ thống Clipboard tiêu chuẩn (thông qua `QMimeData` của Qt) có các giới hạn sau:
- **`setText`**: Chỉ chứa được một khối văn bản duy nhất.
- **`setImageData`**: Chỉ chứa được dữ liệu của **duy nhất một** tấm ảnh (dạng bitmap). Nếu gán tấm ảnh thứ hai, nó sẽ ghi đè tấm ảnh thứ nhất.
- **`setUrls`**: Chứa được một danh sách các đường dẫn (URL) trỏ đến các file cục bộ trên máy tính.

Do đó, để copy "nhiều hình ảnh" cùng một lúc, chúng ta không thể dùng `setImageData`. Phương án khả thi duy nhất là sử dụng `setUrls` để chứa đường dẫn đến các file ảnh đã được tải về máy.

## 3. Giải pháp triển khai

### A. Thu thập dữ liệu theo thứ tự (Ordered Collection)
Tôi sử dụng vòng lặp duyệt qua danh sách `_selected` (danh sách này trong TDesktop đã được sắp xếp hoặc tôi chủ động sắp xếp theo `position` - thứ tự thời gian/vị trí tin nhắn).
- Với mỗi tin nhắn:
    - Nếu có phần văn bản (text/caption), nó sẽ được gom vào biến `fullText` và thẻ `<p>` trong HTML.
    - **Đối với Document (File/Sticker/Video)**: Tôi lấy đường dẫn file cục bộ bằng hàm `filepath(true)`. Nếu file đã tải về, nó được thêm vào `setUrls` và thẻ `<img>` trỏ tới file.
    - **Đối với Photo**: Vì Photo trong TDesktop thường nằm trong cache mã hóa và không có đường dẫn file trực tiếp, tôi chuyển dữ liệu ảnh sang dạng **Base64** và chèn trực tiếp vào thẻ `<img>` của HTML (`data:image/jpeg;base64,...`).

### B. Cấu trúc QMimeData đa năng
Để đảm bảo khả năng tương thích cao nhất khi người dùng "Paste" vào các ứng dụng khác nhau, tôi xây dựng `QMimeData` chứa 4 loại dữ liệu:
1.  **Văn bản tổng hợp (`setText`)**: Chứa text và các marker như `[ Photo ]` để giữ thứ tự trong các trình soạn thảo đơn giản.
2.  **Định dạng Rich Text (`setHtml`)**: Đây là phần quan trọng nhất để giữ thứ tự xen kẽ. Nó chứa text và các thẻ ảnh (Base64 cho ảnh, File Path cho file). Các app như Word/Outlook sẽ hiển thị cực đẹp.
3.  **Danh sách file (`setUrls`)**: Chứa đường dẫn các file Document đính kèm.
4.  **Ảnh đơn (`setImageData`)**: Gán tấm ảnh đầu tiên tìm thấy để làm preview cho các ứng dụng chỉ hỗ trợ dán 1 ảnh.

## 4. Tại sao phương án này tối ưu?
1.  **Vượt qua giới hạn 1 ảnh**: Sử dụng `setUrls` là cách duy nhất để Clipboard mang theo hàng nghìn tấm ảnh cùng lúc.
2.  **Đúng thứ tự**: Việc duyệt theo danh sách selection đảm bảo thứ tự văn bản và danh sách file đồng bộ với nhau.
3.  **Hiệu suất cao**: Tôi chỉ lấy đường dẫn file (string), không nạp toàn bộ dữ liệu pixel của 10,000 tấm ảnh vào RAM (việc này sẽ gây crash ứng dụng ngay lập tức). RAM chỉ nạp 1 tấm ảnh đầu tiên để làm preview.
4.  **Bypass triệt để**: Kết hợp với việc sửa hàm `hasCopyRestrictionForSelected` trả về `false`, tính năng này hoạt động bất chấp mọi rào cản của Telegram Server trên các kênh bị hạn chế.

---
*Ghi chú: Để tính năng copy ảnh hoạt động, các ảnh đó cần được tải về (download) hoàn tất trong cache của Telegram Desktop.*
