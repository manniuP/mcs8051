@echo off
rem Portable build dispatcher for the AI8051U examples (shared toolchain/).
rem Uses ONLY the bundled toolchain under toolchain\ (zig + sdcc + mcstools).
rem No system toolchain and no pre-set environment variables are required.
rem
rem Usage:
rem   build.cmd                 :: build all examples (default: all)
rem   build.cmd usb_cdc         :: build USB-CDC only -> usb_cdc\usb_cdc.ihx
rem   build.cmd ziglog          :: build ziglog only  -> ziglog\log.ihx
rem   build.cmd t0print         :: build t0print only -> t0print\t0print.ihx
rem   build.cmd uart_echo       :: build uart_echo only -> uart_echo\uart_echo.ihx
rem   build.cmd ziglog -Dmcs-small=true    (extra args are forwarded as-is)
setlocal

set "HERE=%~dp0"

rem Parse the RAW command line (%*) instead of %1: cmd splits %1 on '=' (so
rem "-Dmcs-small=true" would arrive as two tokens), but %* preserves it.
set "WHAT="
set "REST="
for /f "tokens=1,*" %%a in ("%*") do (
    set "WHAT=%%a"
    set "REST=%%b"
)
if "%WHAT%"=="" set "WHAT=all"

if /I "%WHAT%"=="usb_cdc"   goto one
if /I "%WHAT%"=="ziglog"    goto one
if /I "%WHAT%"=="t0print"   goto one
if /I "%WHAT%"=="uart_echo" goto one
if /I "%WHAT%"=="all"       goto all
echo usage: build.cmd [usb_cdc^|ziglog^|t0print^|uart_echo^|all] [extra zig args]
exit /b 2

:one
if not exist "%HERE%%WHAT%\build.cmd" (
    echo [ERROR] unknown example: %WHAT%
    exit /b 2
)
call "%HERE%%WHAT%\build.cmd" %REST%
exit /b %ERRORLEVEL%

:all
call "%HERE%usb_cdc\build.cmd" %REST%
if errorlevel 1 exit /b 1
call "%HERE%ziglog\build.cmd" %REST%
if errorlevel 1 exit /b 1
call "%HERE%t0print\build.cmd" %REST%
if errorlevel 1 exit /b 1
call "%HERE%uart_echo\build.cmd" %REST%
exit /b %ERRORLEVEL%
