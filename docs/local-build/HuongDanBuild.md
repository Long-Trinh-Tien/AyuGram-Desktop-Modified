# Hướng Dẫn Build AyuGramDesktop cho Windows 64-bit

Dưới đây là các bước chi tiết để build AyuGramDesktop từ mã nguồn trên môi trường Windows 11 / Windows 10, được đúc kết từ tài liệu chính thức và quá trình debug của dự án.

## 1. Yêu cầu phần mềm và công cụ (Prerequisites)
Bạn cần tải và cài đặt các phần mềm sau trước khi bắt đầu:
- **Visual Studio 2022**: Cần cài đặt cùng với các thành phần sau trong VS Build Tools:
  - `Desktop development with C++`
  - `C++ MFC for latest v143 build tools (x86 & x64)`
  - `C++ ATL for latest v143 build tools (x86 & x64)`
  - `Windows 11 SDK` (ví dụ bản 10.0.26100.0)
- **Python 3.10**: [Tải tại đây](https://www.python.org/downloads/) (Lưu ý: Check vào ô **"Add Python to PATH"** lúc cài đặt).
- **Git**: [Tải tại đây](https://git-scm.com/download/win) (cài đặt và thêm vào PATH bình thường).

## 2. Chuẩn bị thư mục Build
Script build tự động của dự án sẽ thiết lập các thư mục cha lùi `../../../..` để định vị chỗ chứa thư viện (ThirdParty / Libraries). Vì vậy, bạn cần chuẩn bị đúng cấu trúc thư mục để tránh việc file bị văng lộn xộn ra ngoài ổ đĩa.
1. Chọn một thư mục trống, ví dụ: `E:\TBuild` (hoặc `D:\TBuild`).
2. Mở thư mục đó và tạo sẵn hai thư mục con bên trong để chứa thư viện:
   - `ThirdParty`
   - `Libraries`

## 3. Lấy mã nguồn và tự động build các thư viện
Bạn **bắt buộc** phải sử dụng Command Prompt của Visual Studio để quá trình compile sử dụng đúng toolchain x64.
1. Mở **Start Menu**, tìm và chạy **"x64 Native Tools Command Prompt for VS 2022"**.
   *(Chú ý: KHÔNG dùng CMD thường hoặc PowerShell).*
2. Di chuyển đến thư mục build vừa tạo bằng lệnh:
   ```cmd
   cd /d E:\TBuild
   ```
3. Clone mã nguồn AyuGramDesktop bằng Git, và clone thẳng vào thư mục có tên là `tdesktop`:
   ```cmd
   git clone --recursive https://github.com/AyuGram/AyuGramDesktop.git tdesktop
   ```
   *(`--recursive` để lấy đầy đủ các submodule bắt buộc đi kèm).*
4. Chạy script chuẩn bị môi trường:
   ```cmd
   tdesktop\Telegram\build\prepare\win.bat
   ```
   *Lưu ý quan trọng: Quá trình này script tự động cấu hình và biên dịch cực kỳ nhiều thư viện lớn (như Qt, FFmpeg, OpenSSL, WebRTC, v.v.). Nó sẽ mất từ **1 đến vài tiếng** tùy thuộc vào số luồng CPU của máy bạn.*
   *Nếu gặp lỗi báo không tải được (IP not allowed), bạn hãy bật VPN rồi chạy lại tiến trình này.*

## 4. Cấu hình và Build Project
Sau khi script `win.bat` chạy thành công (tất cả 33 packages), bạn sẽ bắt đầu build file thực thi cuối cùng.
1. Vẫn trong **x64 Native Tools Command Prompt**, hãy vào thư mục Telegram:
   ```cmd
   cd tdesktop\Telegram
   ```
2. Chạy lệnh sinh file CMake và Visual Studio Solution:
   ```cmd
   .\configure.bat x64 -D TDESKTOP_API_ID=2040 -D TDESKTOP_API_HASH=b18441a1ff607e10a989891a5462e627
   ```
3. Mở file solution vừa được tạo ra: **`E:\TBuild\tdesktop\out\Telegram.sln`** bằng phần mềm **Visual Studio 2022**.
4. Trong phần mềm Visual Studio:
   - Tìm project có tên là **Telegram** ở bảng Solution Explorer.
   - Nhấp chuột phải chọn **Build** (hoặc dùng menu `Build > Build Telegram`).
   - Mặc định là cấu hình **Debug**, bạn có thể đổi sang **Release** ở thanh thả xuống phía trên cùng màn hình nếu muốn build bản nhẹ để sử dụng thực tế.
   
   - Build bằng terminal:
   x64 Native Tools Command Prompt:
   cd ..\out
   :: Thiết lập trình biên dịch chỉ dùng tối đa 4 luồng
   set CL=/MP4
   msbuild Telegram.sln /p:Configuration=Release /p:Platform=x64 /maxcpucount
   msbuild Telegram.sln /p:Configuration=Debug /p:Platform=x64 /maxcpucount
5. Thành quả:
   - File chạy `AyuGram.exe` (bản build của bạn) sẽ nằm ở thư mục: `E:\TBuild\tdesktop\out\Debug` (hoặc `E:\TBuild\tdesktop\out\Release`).

Chúc bạn cài đặt và build AyuGramDesktop thành công!
