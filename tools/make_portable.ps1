# make_portable.ps1 - extract a self-contained minimal toolchain set from the main project.
#
# Output layout (shared toolchain + isolated examples):
#   <Out>\toolchain\            bundled zig.exe+lib (MCS-251 backend), SDCC mcs251, mcstools.exe
#   <Out>\usb_cdc\              C USB-CDC example  (build.zig / build.cmd / include / src)
#   <Out>\ziglog\               pure-Zig COBS log example (build.zig / build.cmd / decode.*)
#   <Out>\build.cmd             dispatcher: build.cmd [usb_cdc|ziglog|all]
#   <Out>\README.md .gitignore .gitattributes
#
# Copy it to a machine with no toolchain, no Python and no env vars, then run
#   build.cmd   (or: build.cmd usb_cdc / build.cmd ziglog).
#
# Usage (from mcs251/):
#   powershell -File tools\make_portable.ps1 [-Out <dir>] [-Python <python.exe>] [-SkipTools]
#
# NOTE: keep this file ASCII-only. PS 5.1 reads BOM-less files as GBK, so Chinese
#       comments here would be mis-decoded and can break parsing.
param(
    [string]$Out = "",
    [string]$Device = "devices\stc\ai8051u-34k64.toml",
    [string]$Python = "python",
    [switch]$SkipTools
)
$ErrorActionPreference = "Stop"

$repo     = Split-Path -Parent $PSScriptRoot            # .../mcs251
# Default output: a sibling "portable\ai8051u" next to the repo (no hard-coded absolute path).
if ([string]::IsNullOrEmpty($Out)) { $Out = Join-Path (Split-Path -Parent $repo) "portable\ai8051u" }
$zigBin   = Join-Path $repo "compiler\zig-out\bin\zig.exe"
$zigLib   = Join-Path $repo "compiler\lib"
$sdcc     = Join-Path $repo "tools\sdcc-mcs251-windows-x64\sdcc-mcs251"
$inc      = Join-Path $repo "lib\include"
$exUsb    = Join-Path $repo "examples\ai8051u_usb_cdc"
$exLog    = Join-Path $repo "examples\ai8051u_zig_log"
$exT0     = Join-Path $repo "examples\ai8051u_zig_t0print"
$exUe     = Join-Path $repo "examples\ai8051u_zig_uart_echo"
$portRoot = Join-Path $repo "examples\portable"
$portUsb  = Join-Path $exUsb "portable"
$portLog  = Join-Path $exLog "portable"
$portT0   = Join-Path $exT0 "portable"
$portUe   = Join-Path $exUe "portable"
$cobs     = Join-Path $repo "lib\cobs\cobs.zig"
$mcsLib   = Join-Path $repo "lib\mcs251.zig"

foreach ($p in @($zigBin, $zigLib, $sdcc, $inc, $exUsb, $exLog, $exT0, $exUe,
                 $portRoot, $portUsb, $portLog, $portT0, $portUe, $cobs, $mcsLib)) {
    if (-not (Test-Path -LiteralPath $p)) { throw "missing: $p" }
}

# Layout of the portable set.
New-Item -ItemType Directory -Force -Path $Out | Out-Null
foreach ($d in @("toolchain\zig\bin", "toolchain\zig\lib", "toolchain\sdcc\bin",
                 "toolchain\sdcc\lib", "toolchain\sdcc\include", "toolchain\mcstools",
                 "usb_cdc\include", "usb_cdc\src", "ziglog", "t0print", "uart_echo")) {
    New-Item -ItemType Directory -Force -Path (Join-Path $Out $d) | Out-Null
}

# [1] zig (build driver + MCS backend): exe + lib (std etc.)
Copy-Item -LiteralPath $zigBin (Join-Path $Out "toolchain\zig\bin\zig.exe") -Force
robocopy $zigLib (Join-Path $Out "toolchain\zig\lib") /E /XD .zig-cache zig-out /NFL /NDL /NJH /NJS /NP | Out-Null

# [2] SDCC mcs251: copy the WHOLE tree. bin/lib/include alone are NOT enough:
#     sdcpp needs libexec\sdcc\<host>\<ver>\cc1.exe, and there are also x86_64-w64-mingw32,
#     locale, doc, info, COPYING*. A partial copy makes sdcc fail with
#     "sdcpp.exe: fatal error: cannot execute 'cc1'".
#     Skip listing/debug artifacts (*.lst/*.rst/*.sym, ~47MB) - not used at build time.
robocopy $sdcc (Join-Path $Out "toolchain\sdcc") /E /XF *.lst *.rst *.sym /NFL /NDL /NJH /NJS /NP | Out-Null

# [3] mcstools.exe (frozen build-layer Python tools; target machine needs no Python)
$mcstoolsDst = Join-Path $Out "toolchain\mcstools\mcstools.exe"
if ($SkipTools) {
    if (-not (Test-Path -LiteralPath $mcstoolsDst)) { throw "-SkipTools set but no existing $mcstoolsDst" }
} else {
    & (Join-Path $PSScriptRoot "build_mcstools.ps1") -Out $mcstoolsDst -Python $Python
    if ($LASTEXITCODE -ne 0) { throw "build_mcstools.ps1 failed" }
}

# [4] usb_cdc example: chip headers + C sources + build scripts
foreach ($h in @("ai8051u_sfr.h", "c51.h", "mcs_intrins.h")) {
    Copy-Item -LiteralPath (Join-Path $inc $h) (Join-Path $Out "usb_cdc\include\$h") -Force
}
Copy-Item -Path (Join-Path $exUsb "src\*.c") (Join-Path $Out "usb_cdc\src\") -Force
Copy-Item -Path (Join-Path $exUsb "src\*.h") (Join-Path $Out "usb_cdc\src\") -Force
foreach ($f in @("build.zig", "build.cmd")) {
    Copy-Item -LiteralPath (Join-Path $portUsb $f) (Join-Path $Out "usb_cdc\$f") -Force
}

# [5] ziglog example: program + hardware/COBS libs + host decoder + crt0 + build scripts
Copy-Item -LiteralPath (Join-Path $exLog "log.zig")    (Join-Path $Out "ziglog\log.zig") -Force
Copy-Item -LiteralPath (Join-Path $exLog "crt0.asm")   (Join-Path $Out "ziglog\crt0.asm") -Force
Copy-Item -LiteralPath (Join-Path $exLog "decode.py")  (Join-Path $Out "ziglog\decode.py") -Force
Copy-Item -LiteralPath (Join-Path $exLog "decode.ps1") (Join-Path $Out "ziglog\decode.ps1") -Force
Copy-Item -LiteralPath $mcsLib                          (Join-Path $Out "ziglog\mcs251.zig") -Force
Copy-Item -LiteralPath $cobs                            (Join-Path $Out "ziglog\cobs.zig") -Force
foreach ($f in @("build.zig", "build.cmd")) {
    Copy-Item -LiteralPath (Join-Path $portLog $f) (Join-Path $Out "ziglog\$f") -Force
}

# [5b] t0print example: program + hardware lib + crt0 + build scripts
Copy-Item -LiteralPath (Join-Path $exT0 "t0print.zig") (Join-Path $Out "t0print\t0print.zig") -Force
Copy-Item -LiteralPath (Join-Path $exT0 "crt0.asm")    (Join-Path $Out "t0print\crt0.asm") -Force
Copy-Item -LiteralPath (Join-Path $exT0 "crt0_mcs51.asm") (Join-Path $Out "t0print\crt0_mcs51.asm") -Force
Copy-Item -LiteralPath $mcsLib                          (Join-Path $Out "t0print\mcs251.zig") -Force
foreach ($f in @("build.zig", "build.cmd")) {
    Copy-Item -LiteralPath (Join-Path $portT0 $f) (Join-Path $Out "t0print\$f") -Force
}

# [5d] uart_echo example: program + hardware lib + crt0 + build scripts
Copy-Item -LiteralPath (Join-Path $exUe "uart_echo.zig") (Join-Path $Out "uart_echo\uart_echo.zig") -Force
Copy-Item -LiteralPath (Join-Path $exUe "crt0.asm")      (Join-Path $Out "uart_echo\crt0.asm") -Force
Copy-Item -LiteralPath (Join-Path $exUe "crt0_mcs51.asm") (Join-Path $Out "uart_echo\crt0_mcs51.asm") -Force
Copy-Item -LiteralPath $mcsLib                            (Join-Path $Out "uart_echo\mcs251.zig") -Force
foreach ($f in @("build.zig", "build.cmd")) {
    Copy-Item -LiteralPath (Join-Path $portUe $f) (Join-Path $Out "uart_echo\$f") -Force
}

# [5c] device memory model JSON for the Zig examples. It is used two ways:
#      - build.zig embeds it via @embedFile("device.json") (optional `zig build` path);
#      - the default build.cmd loads it with `set /p MCS_DEVICE=<device.json`, which
#        reads exactly one line, so emit it as a SINGLE LINE (no CR/LF).
#      Values are unchanged, so variable placement still matches the main (xmake) build
#      byte-for-byte.
$devToml = Join-Path $repo $Device
if (-not (Test-Path -LiteralPath $devToml)) { throw "missing device: $devToml" }
$deviceJson = ((& $Python (Join-Path $repo "tools\mcs_device.py") $devToml --emit compiler-json) -join "`n") -replace "`r?`n", ""
foreach ($d in @("ziglog", "t0print", "uart_echo")) {
    [System.IO.File]::WriteAllText((Join-Path $Out "$d\device.json"), $deviceJson,
                                   (New-Object System.Text.ASCIIEncoding))
}

# [5e] Prebuilt build runner for the Zig examples (option 2). `build.cmd --runner`
#      runs this instead of `zig build`, so the target machine never compiles host
#      x86_64 code with the self-hosted backend (avoids 0xC0000094 / exit code 148).
#      Build it here with a host zig that has LLVM (prefer `zig` on PATH); the bundled
#      zig would itself go through the fragile self-hosted backend. `zig build -l`
#      only configures and compiles the runner, it does not run the MCS build steps.
$hostZig = $null
$zigCmd = Get-Command zig -ErrorAction SilentlyContinue
if ($zigCmd) { $hostZig = $zigCmd.Source }
if (-not $hostZig) {
    Write-Warning "no system 'zig' on PATH; falling back to the bundled zig for build_runner.exe"
    $hostZig = $zigBin
}
foreach ($d in @("ziglog", "t0print", "uart_echo")) {
    $dir = Join-Path $Out $d
    Push-Location $dir
    try { & $hostZig build -l 2>&1 | Out-Null } catch {}
    Pop-Location
    $runner = Get-ChildItem -Recurse (Join-Path $dir ".zig-cache") -Filter build.exe -ErrorAction SilentlyContinue |
              Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($runner) {
        Copy-Item -LiteralPath $runner.FullName (Join-Path $dir "build_runner.exe") -Force
        Remove-Item -Recurse -Force (Join-Path $dir ".zig-cache")
    } else {
        Write-Warning "could not build build_runner.exe for $d (build.cmd --runner will be unavailable)"
    }
}

# [6] root dispatcher, docs, git config
foreach ($f in @("build.cmd", "README.md", ".gitignore", ".gitattributes")) {
    Copy-Item -LiteralPath (Join-Path $portRoot $f) (Join-Path $Out $f) -Force
}

# Normalize every .cmd to CRLF + ASCII (cmd.exe is picky about line endings / code page).
Get-ChildItem $Out -Recurse -Filter *.cmd | ForEach-Object {
    $t = [System.IO.File]::ReadAllText($_.FullName)
    $t = ($t -replace "`r`n", "`n") -replace "`n", "`r`n"
    [System.IO.File]::WriteAllText($_.FullName, $t, (New-Object System.Text.ASCIIEncoding))
}

$mb = [math]::Round((Get-ChildItem $Out -Recurse -File | Measure-Object Length -Sum).Sum / 1MB, 1)
Write-Output "OK -> $Out  ($mb MB)"
Write-Output "On the target machine run: $Out\build.cmd  (or: build.cmd usb_cdc / ziglog / t0print / uart_echo)"
