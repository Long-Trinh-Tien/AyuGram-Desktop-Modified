# Log thao tác debug & Build AyuGramDesktop

## Các bước đã thực hiện:
1. Đọc file `README.md` và `docs/building-win-x64.md` để lấy hướng dẫn chính thức từ mã nguồn.
2. Kiểm tra môi trường trên máy Windows (`win32`):
   - Git: `2.41.0.windows.1`
   - Python: `3.10.6`
   - Visual Studio 2022: Đã tìm thấy tại `C:\Program Files\Microsoft Visual Studio\2022\Community`
3. Nhận thấy script `Telegram\build\prepare\prepare.py` đi lùi 4 thư mục (`../../../..`) để đặt thư mục `Libraries` và `ThirdParty`. Việc chạy trực tiếp ở `E:\Hoc\clone_github\AyuGramDesktop` sẽ gây rác thư mục cha. Do đó, đã tạo môi trường sạch tại `E:\TBuild`.
4. Tạo thư mục cấu trúc:
   ```cmd
   mkdir E:\TBuild
   mkdir E:\TBuild\Libraries
   mkdir E:\TBuild\ThirdParty
   ```
5. Clone source code AyuGramDesktop vào `E:\TBuild\tdesktop` bằng tham số `--recursive` để lấy tất cả các submodule.
6. Khởi tạo script build thông qua file `build.bat` bao gồm môi trường `vcvars64.bat`:
   ```bat
   call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
   cd /d E:\TBuild\tdesktop
   call Telegram\build\prepare\win.bat
   ```
7. Chạy tiến trình ngầm (Background process PID: 6724) để thực thi script build thư viện và ghi log ra `E:\TBuild\build_log.txt`.
8. Đọc log thực tế từ background, quá trình clone patches (`[1/33](Libraries/patches)`) đã chạy thành công, project đang tiếp tục tải và build các thư viện bên thứ ba. Quá trình này sẽ diễn ra liên tục.

*(Hoàn tất việc log các thao tác debug và xác minh luồng build khởi chạy chuẩn xác).*
