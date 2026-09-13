# ENV_LOCK — môi trường build đã xác minh trên máy gốc

> Mục đích: AI chỉ cần repo này + file này là dựng lại được môi trường build
> tương đương (không bit-identical: `Libraries/` 19GB và `out/` 15GB phải build
> lại bằng `Telegram\build\prepare\win.bat`, mất 1–vài tiếng).
> Ngày chốt: 2026-09-14. Máy gốc: Windows 11/10 x64, repo đặt tại `E:\TBuild\tdesktop`.

## 1. Layout bắt buộc (do `prepare.py` lùi 4 thư mục `../../../..`)

```text
<TBUILD>\tdesktop      <- repo này (clone với --recursive)
<TBUILD>\ThirdParty    <- tool build (gyp, jom, msys64, NuGet, python) do win.bat tải
<TBUILD>\Libraries     <- 31 lib prebuilt (Qt, ffmpeg, openssl3, tg_owt...) do win.bat build
```

`CMakeCache.txt` trên máy gốc ghim path tuyệt đối (`E:/TBuild/...`), nên clone
sang ổ/thư mục khác thì phải chạy lại `configure.bat` (xem mục 5).

## 2. Source

* Base: upstream `AyuGramDesktop` tag `v6.3.10`, commit `b495e37130`.
* Branch này: `feature/enhanced-copy`, hơn base 2 commits:
  * `327325af22` feat: enhance multi-message copy functionality with media support
  * `69aa0285e7` fix: keep PhotoMedia shared_ptr alive to prevent async download data loss
* Submodules: clone **bắt buộc** với `--recursive` (32 entries, chốt trong
  `submodule-pins.txt`).

## 3. Toolchain đã đo trên máy gốc

| Tool | Version |
|---|---|
| Visual Studio 2022 Community | 17.14.13 (Aug 2025), generator `Visual Studio 17 2022` |
| MSVC | 14.44.35207 (`cl.exe` 19.44.35215, x64) |
| MSBuild | 17.14.19.38001 (chỉ có trong môi trường VS — chạy `vcvars64.bat` trước) |
| Windows SDK | 10.0.26100.0 (đã cài thêm 10.0.19041.0) |
| VS components | `Desktop development with C++`, `C++ MFC for latest v143 (x86 & x64)`, `C++ ATL for latest v143 (x86 & x64)` |
| Python | 3.10.6, cài kèm PATH |
| CMake | 3.28.2 |
| Git | 2.41.0.windows.1 |
| Qt (do prepare build) | 5.15.18 (`Libraries/win64/Qt-5.15.18`) |

## 4. Libraries / ThirdParty (do `win.bat` tạo, KHÔNG nằm trong git)

* Danh sách 31 thư mục `Libraries/win64`: xem `libraries-inventory.txt`
  (ada, breakpad, dav1d, ffmpeg, libavif, libde265, libheif, libjxl, liblcms2,
  libvpx, libwebp, lzma, mozjpeg, nv-codec-headers, openal-soft, openh264,
  openssl3, opus, protobuf, Qt-5.15.18, regex, rnnoise, tde2e, tg_angle,
  tg_owt, zlib, ...).
* `ThirdParty`: `gyp`, `jom`, `msys64`, `NuGet`, `python` (+ `cache_keys` để SKIP khi chạy lại).

## 5. Configure & build (x64 Native Tools Command Prompt, KHÔNG dùng PowerShell/CMD thường)

```cmd
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
cd /d <TBUILD>\tdesktop
call Telegram\build\prepare\win.bat
cd Telegram
.\configure.bat x64 -D TDESKTOP_API_ID=%TDESKTOP_API_ID% -D TDESKTOP_API_HASH=%TDESKTOP_API_HASH%
cd ..\out
msbuild Telegram.sln /p:Configuration=Release /p:Platform=x64 /maxcpucount /t:Build
```

* Mặc định dùng **test credentials công khai của upstream** (`ID=2040`,
  `HASH=b18441a1ff607e10a989891a5462e627`, cũng ghi trong
  `docs/building-win-x64.md`). Muốn release thật thì export env
  `TDESKTOP_API_ID` / `TDESKTOP_API_HASH` của riêng bạn — script
  `tools/win/full-build.bat` đã hỗ trợ.
* Output máy gốc: `out\Release\AyuGram.exe` (xác minh build OK ngày 2026-04-19).
* Build nhanh cho agent (không cần vcvars, dùng cache có sẵn):
  xem `docs/local-build/SUBAGENT_BUILD_GUIDE.md`.

## 6. Vấn đề đã biết trên máy gốc

1. `build_log.txt` từng báo `[10/33](Libraries/openssl3): FAILED`, nhưng build
   Release sau đó vẫn ra `AyuGram.exe` OK — nếu prepare fail thì chạy lại
   `win.bat` (tự SKIP phần xong), bật VPN nếu lỗi `IP not allowed`.
2. Patch local duy nhất ngoài code: `patches/cmake-options_win.debug-none.patch`
   (ép `/DEBUG:NONE` trong submodule `cmake`, để tiết kiệm link-time/disk).
   Muốn build giống hệt máy gốc thì apply patch này sau khi init submodule;
   không thì bỏ qua vẫn build được.
3. `LNK1104 cannot open AyuGram.exe`: tắt app đang chạy trước (`taskkill /F /IM AyuGram.exe`).
4. `C3859/C1076` (hết PCH/virtual memory): đóng app nặng, không build song song.

## 7. Quy trình tái tạo cho AI (tóm tắt)

1. `git clone --recursive <repo-url> -b feature/enhanced-copy tdesktop` vào `<TBUILD>`.
2. Tạo `<TBUILD>\ThirdParty`, `<TBUILD>\Libraries`.
3. (Tuỳ chọn, giống hệt máy gốc) apply `patches/cmake-options_win.debug-none.patch` vào submodule `cmake`.
4. Chạy `tools/win/full-build.bat Release` trong x64 Native Tools env.
5. Kiểm tra `out\Release\AyuGram.exe`.
