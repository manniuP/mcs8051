@echo off
rem USB-CDC portable build driver. Uses only the shared ..\toolchain\.
rem No system toolchain and no pre-set environment variables are required.
rem
rem usb_cdc is pure C, so it is built directly by the bundled SDCC.
rem No zig build runner (build.exe) is involved, which sidesteps the
rem intermittent 0xC0000094 crash of the self-built host backend.
rem
rem Usage:  build.cmd [-Darch=mcs51] [-Dcode-loc=0x0000]
rem         arch defaults to mcs251 (AI8051U 32-bit); mcs51 selects 8-bit.
setlocal enabledelayedexpansion

set "HERE=%~dp0"
for %%I in ("%HERE%..") do set "ROOT=%%~fI"
set "SDCC=%ROOT%\toolchain\sdcc\bin\sdcc.exe"
if not exist "%SDCC%" (
    echo [ERROR] bundled sdcc not found: %SDCC%
    exit /b 2
)

rem SDCC's sdcpp needs cc1.exe on PATH.
set "PATH=%ROOT%\toolchain\sdcc\bin;%PATH%"

rem Optional overrides: -Darch=mcs51|mcs251 (default mcs251), -Dcode-loc=...
set "ARCH=mcs251"
set "CODE_LOC="
set "REST=%*"
:parse
for /f "tokens=1,*" %%A in ("!REST!") do (
    set "ARG=%%A"
    set "REST=%%B"
    if /i "!ARG:~0,7!"=="-Darch=" set "ARCH=!ARG:~7!"
    if /i "!ARG:~0,11!"=="-Dcode-loc=" set "CODE_LOC=!ARG:~11!"
    if not "!REST!"=="" goto :parse
)

if /i "!ARCH!"=="mcs51" ( set "MODEL=-mmcs51" ) else ( set "MODEL=-mmcs251" )
if not defined CODE_LOC (
    if /i "!ARCH!"=="mcs51" ( set "CODE_LOC=0x0000" ) else ( set "CODE_LOC=0xff0000" )
)

pushd "%HERE%"
set "RC=0"
rem [1/2] C -> .rel (single translation unit: main + all ISRs, so SDCC emits the full vector table)
"%SDCC%" !MODEL! --model-large -I include -I src -c src/usb_cdc_all.c -o usb_cdc_all.rel
if errorlevel 1 set "RC=!ERRORLEVEL!"
rem [2/2] link -> .ihx
if "!RC!"=="0" (
    "%SDCC%" !MODEL! --model-large --code-loc !CODE_LOC! usb_cdc_all.rel -o usb_cdc.ihx
    if errorlevel 1 set "RC=!ERRORLEVEL!"
)
popd
if "!RC!"=="0" ( echo [OK] usb_cdc.ihx ) else ( echo [FAIL] rc=!RC! )
exit /b !RC!
