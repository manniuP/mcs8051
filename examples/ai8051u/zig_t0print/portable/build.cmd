@echo off
rem t0print portable build driver (pure Zig Timer0 ISR -> UART1). Uses only ..\toolchain\.
rem No system toolchain, no Python and no pre-set environment variables are required.
rem
rem This driver deliberately does NOT use `zig build`. The bundled zig is a
rem have_llvm=false build, so compiling the x86_64 build runner (build.exe) goes
rem through the self-hosted backend, which can hard-crash with 0xC0000094
rem (reported as exit code 148) when the cache is cold. Every step is invoked
rem directly here, so no host x86_64 code is ever generated.
rem
rem --runner : run the bundled prebuilt build_runner.exe instead (same steps as
rem            `zig build`, but the host runner is NOT compiled on this machine),
rem            for when you want the exact build.zig semantics.
rem
rem Usage:  build.cmd [-Darch=mcs51] [-Dmcs-small=true] [-Dcode-loc=0x0000] [--runner]
rem         arch defaults to mcs251 (AI8051U 32-bit); mcs51 selects 8-bit.
setlocal enabledelayedexpansion

set "HERE=%~dp0"
for %%I in ("%HERE%..") do set "ROOT=%%~fI"
for %%I in ("%HERE%.") do set "BUILDDIR=%%~fI"
set "ZIG=%ROOT%\toolchain\zig\bin\zig.exe"
set "MCSTOOLS=%ROOT%\toolchain\mcstools\mcstools.exe"
set "SDCC=%ROOT%\toolchain\sdcc\bin\sdcc.exe"
if not exist "%ZIG%" (
    echo [ERROR] bundled zig not found: %ZIG%
    exit /b 2
)
if not exist "%MCSTOOLS%" (
    echo [ERROR] bundled mcstools not found: %MCSTOOLS%
    exit /b 2
)

rem Self-contained cache/lib: do not rely on LOCALAPPDATA or pre-set env vars.
set "ZIG_GLOBAL_CACHE_DIR=%ROOT%\.cache\zig"
set "ZIG_LIB_DIR=%ROOT%\toolchain\zig\lib"
if not exist "%ROOT%\.cache\zig" mkdir "%ROOT%\.cache\zig"
rem SDCC's sdcpp needs cc1.exe on PATH.
set "PATH=%ROOT%\toolchain\sdcc\bin;%ROOT%\toolchain\zig\bin;%PATH%"

rem Options: -Darch=mcs251|mcs51, -Dmcs-small=true, -Dcode-loc=...
set "ARCH=mcs251"
set "SMALL="
set "CODE_LOC="
set "RUNNER="
set "PASSTHRU="
set "REST=%*"
:parse
for /f "tokens=1,*" %%A in ("!REST!") do (
    set "ARG=%%A"
    set "REST=%%B"
    if /i "!ARG!"=="--runner" (
        set "RUNNER=1"
    ) else (
        set "PASSTHRU=!PASSTHRU! !ARG!"
        if /i "!ARG:~0,7!"=="-Darch=" set "ARCH=!ARG:~7!"
        if /i "!ARG:~0,12!"=="-Dmcs-small=" set "SMALL=!ARG:~12!"
        if /i "!ARG:~0,11!"=="-Dcode-loc=" set "CODE_LOC=!ARG:~11!"
    )
    if not "!REST!"=="" goto :parse
)

rem Per-arch: target triple / assembler / sdcc model / startup file / link extras.
set "TARGET=mcs251-freestanding"
set "SDAS=%ROOT%\toolchain\sdcc\bin\sdas251.exe"
set "MODEL=-mmcs251"
set "CRT0=crt0.asm"
set "LINKOPT=--data-loc 0x30 --idata-loc 0x80"
set "DEFLOC=0xff0000"
if /i "!ARCH!"=="mcs51" (
    set "TARGET=mcs51-freestanding"
    set "SDAS=%ROOT%\toolchain\sdcc\bin\sdas8051.exe"
    set "MODEL=-mmcs51"
    set "CRT0=crt0_mcs51.asm"
    set "LINKOPT="
    set "DEFLOC=0x0000"
)
if not defined CODE_LOC set "CODE_LOC=!DEFLOC!"
if /i "!SMALL!"=="true" ( set "OPT=-OReleaseSmall" ) else ( set "OPT=-ODebug" )

rem Prebuilt build runner (same effect as `zig build`, no host codegen here).
if defined RUNNER (
    if not exist "!BUILDDIR!\build_runner.exe" (
        echo [ERROR] --runner: build_runner.exe not found ^(regenerate the portable set^)
        exit /b 2
    )
    pushd "%HERE%"
    "build_runner.exe" "%ZIG%" "%ZIG_LIB_DIR%" "!BUILDDIR!" "!BUILDDIR!\.zig-cache" "%ZIG_GLOBAL_CACHE_DIR%"!PASSTHRU!
    set "RC=!ERRORLEVEL!"
    popd
    if "!RC!"=="0" ( echo [OK] t0print.ihx ) else ( echo [FAIL] rc=!RC! )
    exit /b !RC!
)

pushd "%HERE%"
if not exist "device.json" ( echo [ERROR] missing device.json & popd & exit /b 2 )
if not exist "!CRT0!"      ( echo [ERROR] missing !CRT0!      & popd & exit /b 2 )
rem Device storage table -> MCS_DEVICE (single-line JSON; same values as the main project).
set /p MCS_DEVICE=<device.json

rem [1/5] Zig -> asm
"%ZIG%" build-obj !OPT! -target !TARGET! --dep mcs -Mroot=t0print.zig -Mmcs=mcs251.zig -femit-bin=t0print.asm || goto :fail
rem [2/5] fix label collisions
"%MCSTOOLS%" fix t0print.asm || goto :fail
rem [3/5] shrink
"%MCSTOOLS%" opt t0print.asm || goto :fail
rem [4/5] dead-store elimination
"%MCSTOOLS%" ir t0print.asm || goto :fail
rem [4b/5] overlay pass (no-op for mcs251; normalizes line endings for byte-identical output)
"%MCSTOOLS%" overlay t0print.asm || goto :fail
rem [5/5] asm -> rel -> ihx
"!SDAS!" -plosgffw t0print.rel t0print.asm || goto :fail
"!SDAS!" -plosgffw crt0.rel !CRT0! || goto :fail
"%SDCC%" !MODEL! --model-large --code-loc !CODE_LOC! !LINKOPT! crt0.rel t0print.rel -o t0print.ihx || goto :fail
popd
echo [OK] t0print.ihx
exit /b 0

:fail
set "RC=%ERRORLEVEL%"
popd
echo [FAIL] rc=%RC%
exit /b %RC%
