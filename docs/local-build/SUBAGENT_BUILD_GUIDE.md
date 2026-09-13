# Hướng Dẫn Build Nhanh Cho Subagent (Windows x64)

> Bản tổng quát hoá từ máy gốc (đường dẫn gốc `E:\TBuild` đã thay bằng
> `<TBUILD>` = thư mục cha của repo clone `tdesktop`).
> Chi tiết toolchain đầy đủ: xem `ENV_LOCK.md`.

## 1. Môi trường

- **Thư mục làm việc:** `<TBUILD>\tdesktop\Telegram`
- **Thư mục build (output):** `<TBUILD>\tdesktop\out` (solution `Telegram.sln`)
- **Công cụ:** CMake + MSBuild (Visual Studio 2022). Không cần `vcvars64`
  nếu solution đã configure — dùng `cmake --build`.

## 2. Lệnh build chuẩn (PowerShell, phân tách lệnh bằng `;`)

```powershell
cd "<TBUILD>\tdesktop\Telegram"; cmake --build ../out --config Release --target Telegram
```

Log nên đổ ra file ngoài git (đã gitignore):

```powershell
cd "<TBUILD>\tdesktop\Telegram"; cmake --build ../out --config Release --target Telegram > build_output.log 2>&1
```

## 3. Build full từ đầu (lần đầu trên máy mới)

Mở **x64 Native Tools Command Prompt for VS 2022** rồi chạy:

```cmd
tools\win\full-build.bat Release
```

Script này tự lo: `vcvars64` → `prepare\win.bat` → `configure.bat`
(API keys lấy từ env `TDESKTOP_API_ID`/`TDESKTOP_API_HASH`, mặc định là
test credentials công khai của upstream) → `msbuild` Release/x64.

## 4. Troubleshooting

### A. LNK1104: cannot open file AyuGram.exe

App đang chạy giữ lock file. Tắt trước rồi build lại:

```powershell
taskkill /F /IM AyuGram.exe
```

### B. C3859 / C1076: hết bộ nhớ cho PCH

- Không chạy nhiều build song song.
- Đóng app nặng rồi build lại.

### C. `msbuild` not recognized

Dùng `cmake --build` (mục 2) — an toàn nhất vì MSBuild đã ghim trong `out/`.

### D. Prepare fail (`IP not allowed`, openssl3 FAILED...)

- Bật VPN rồi chạy lại `Telegram\build\prepare\win.bat` (tự SKIP phần đã xong).
- Xem `ENV_LOCK.md` mục 6.
