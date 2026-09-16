@echo off
rem uart_echo portable build driver (pure Zig, UART1 RX-interrupt echo). Uses only ..\toolchain\.
rem No system toolchain, no Python and no pre-set environment variables are required.
rem
rem Usage:  build.cmd [-Dmcs-small=true] [-Dcode-loc=0x0000] [extra zig args]
setlocal

set "HERE=%~dp0"
for %%I in ("%HERE%..") do set "ROOT=%%~fI"
set "ZIG=%ROOT%\toolchain\zig\bin\zig.exe"
if not exist "%ZIG%" (
    echo [ERROR] bundled zig not found: %ZIG%
    exit /b 2
)

rem Self-contained cache/lib: do not rely on LOCALAPPDATA or pre-set env vars.
set "ZIG_GLOBAL_CACHE_DIR=%ROOT%\.cache\zig"
set "ZIG_LIB_DIR=%ROOT%\toolchain\zig\lib"
if not exist "%ROOT%\.cache\zig" mkdir "%ROOT%\.cache\zig"
rem SDCC's sdcpp needs cc1 on PATH.
set "PATH=%ROOT%\toolchain\sdcc\bin;%ROOT%\toolchain\zig\bin;%PATH%"

pushd "%HERE%"
"%ZIG%" build %*
set RC=%ERRORLEVEL%
popd
if "%RC%"=="0" ( echo [OK] uart_echo.ihx ) else ( echo [FAIL] rc=%RC% )
exit /b %RC%
