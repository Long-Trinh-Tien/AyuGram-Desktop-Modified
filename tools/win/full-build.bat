@echo off
REM =====================================================================
REM  AyuGram full prepare + build (Windows x64)
REM  Repo clone phai nam tai: <TBUILD>\tdesktop   (git clone --recursive)
REM  Script tu suy ra <TBUILD> = thu muc cha cua repo, chay duoc o o dia/
REM  thu muc bat ky (khong cung E:\TBuild nhu ban goc).
REM
REM  Usage (trong "x64 Native Tools Command Prompt for VS 2022"):
REM      tools\win\full-build.bat [Release^|Debug]
REM
REM  API keys: lay tu env TDESKTOP_API_ID / TDESKTOP_API_HASH.
REM  Neu khong dat, dung TEST credentials cong khai cua upstream
REM  (docs/building-win-x64.md). Muon release that thi export key rieng:
REM      set TDESKTOP_API_ID=123456
REM      set TDESKTOP_API_HASH=xxxx
REM =====================================================================
setlocal

set BUILD_TYPE=%~1
if "%BUILD_TYPE%"=="" set BUILD_TYPE=Release
if /I not "%BUILD_TYPE%"=="Release" if /I not "%BUILD_TYPE%"=="Debug" (
    echo Usage: %~nx0 [Release^|Debug]
    exit /b 2
)

if "%TDESKTOP_API_ID%"=="" set TDESKTOP_API_ID=2040
if "%TDESKTOP_API_HASH%"=="" set TDESKTOP_API_HASH=b18441a1ff607e10a989891a5462e627

REM Repo root = 2 cap tren script (tools\win\ -> repo root)
pushd "%~dp0..\.." || ( echo [!] Khong xac dinh duoc repo root & exit /b 1 )
set REPO=%CD%
for %%I in ("%REPO%\..") do set TBUILD=%%~fI
popd

echo [*] REPO   = %REPO%
echo [*] TBUILD = %TBUILD%
echo [*] BUILD  = %BUILD_TYPE%

REM 1. VS x64 toolchain
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
if errorlevel 1 ( echo [!] vcvars64.bat THAT BAI & exit /b 1 )

REM 2. Thu muc prepare can (win.bat cung tu tao, mkdir truoc cho chac)
if not exist "%TBUILD%\ThirdParty" mkdir "%TBUILD%\ThirdParty"
if not exist "%TBUILD%\Libraries"  mkdir "%TBUILD%\Libraries"

REM 3. Prepare: build/tai 33 packages (tu SKIP phan xong nho cache_keys)
cd /d "%REPO%"
call Telegram\build\prepare\win.bat
if errorlevel 1 ( echo [!] prepare THAT BAI - xem ENV_LOCK muc 6 (VPN / chay lai) & exit /b 1 )

REM 4. Configure (can khi out\Telegram.sln chua co hoac them file moi)
if not exist "%REPO%\out\Telegram.sln" (
    echo [*] Configure lan dau...
    cd /d "%REPO%\Telegram"
    call .\configure.bat x64 -D TDESKTOP_API_ID=%TDESKTOP_API_ID% -D TDESKTOP_API_HASH=%TDESKTOP_API_HASH%
    if errorlevel 1 ( echo [!] configure THAT BAI & exit /b 1 )
) else (
    echo [*] Da co out\Telegram.sln - bo qua configure.
)

REM 5. Build
cd /d "%REPO%\out"
msbuild Telegram.sln /p:Configuration=%BUILD_TYPE% /p:Platform=x64 /maxcpucount /t:Build
if errorlevel 1 ( echo [!] Build THAT BAI & exit /b 1 )

echo.
echo [!] THANH CONG: %REPO%\out\%BUILD_TYPE%\AyuGram.exe
endlocal
