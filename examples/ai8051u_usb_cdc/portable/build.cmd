@echo off
setlocal
set "HERE=%~dp0"
set "ZIG=%HERE%toolchain\zig\bin\zig.exe"
if not exist "%ZIG%" ( echo [ERROR] not found: %ZIG% ^(run tools\make_portable.ps1 first^) & exit /b 2 )
set "ZIG_LIB_DIR=%HERE%toolchain\zig\lib"
set "PATH=%HERE%toolchain\sdcc\bin;%HERE%toolchain\zig\bin;%PATH%"
"%ZIG%" build --zig-lib-dir "%ZIG_LIB_DIR%" %*
set RC=%ERRORLEVEL%
if "%RC%"=="0" ( echo [OK] usb_cdc.ihx ) else ( echo [FAIL] rc=%RC% )
exit /b %RC%
