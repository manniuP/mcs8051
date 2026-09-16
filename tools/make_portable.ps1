# make_portable.ps1 - extract a self-contained minimal toolchain set from the main project.
#
# Output: <Out> directory containing a bundled zig.exe + lib, SDCC mcs251 (with runtime
#         libs), chip headers, example sources and build.cmd/build.zig.
#         Copy it to a machine with no toolchain installed and run build.cmd.
#
# Usage (from mcs251/): powershell -File tools\make_portable.ps1 [-Out <dir>]
param(
    [string]$Out = "<workspace>\portable\ai8051u_usb_cdc"
)
$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot            # .../mcs251
$zigBin = Join-Path $repo "compiler\zig-out\bin\zig.exe"
$zigLib = Join-Path $repo "compiler\lib"
$sdcc   = Join-Path $repo "tools\sdcc-mcs251-windows-x64\sdcc-mcs251"
$inc    = Join-Path $repo "lib\include"
$ex     = Join-Path $repo "examples\ai8051u_usb_cdc"
$port   = Join-Path $ex "portable"

foreach ($p in @($zigBin, $zigLib, $sdcc, $inc, $port)) {
    if (-not (Test-Path -LiteralPath $p)) { throw "missing: $p" }
}

New-Item -ItemType Directory -Force -Path $Out | Out-Null
foreach ($d in @("toolchain\zig\bin", "toolchain\zig\lib", "include", "src")) {
    New-Item -ItemType Directory -Force -Path (Join-Path $Out $d) | Out-Null
}

# zig (build driver): exe + lib (std etc.)
Copy-Item -LiteralPath $zigBin (Join-Path $Out "toolchain\zig\bin\zig.exe") -Force
robocopy $zigLib (Join-Path $Out "toolchain\zig\lib") /E /XD .zig-cache zig-out /NFL /NDL /NJH /NJS /NP | Out-Null

# SDCC mcs251 (bin/lib/include)
robocopy (Join-Path $sdcc "bin")     (Join-Path $Out "toolchain\sdcc\bin")     /E /NFL /NDL /NJH /NJS /NP | Out-Null
robocopy (Join-Path $sdcc "lib")     (Join-Path $Out "toolchain\sdcc\lib")     /E /NFL /NDL /NJH /NJS /NP | Out-Null
robocopy (Join-Path $sdcc "include") (Join-Path $Out "toolchain\sdcc\include") /E /NFL /NDL /NJH /NJS /NP | Out-Null

# chip headers
foreach ($h in @("ai8051u_sfr.h", "c51.h", "mcs_intrins.h")) {
    Copy-Item -LiteralPath (Join-Path $inc $h) (Join-Path $Out "include\$h") -Force
}

# example sources (sources only, no .rel/.asm/.lst intermediates)
Copy-Item -Path (Join-Path $ex "src\*.c") (Join-Path $Out "src\") -Force
Copy-Item -Path (Join-Path $ex "src\*.h") (Join-Path $Out "src\") -Force

# build scripts and docs
Copy-Item -LiteralPath (Join-Path $port "build.zig")   $Out -Force
Copy-Item -LiteralPath (Join-Path $port "build.cmd")   $Out -Force
Copy-Item -LiteralPath (Join-Path $port "README.md")   $Out -Force

$mb = [math]::Round((Get-ChildItem $Out -Recurse -File | Measure-Object Length -Sum).Sum / 1MB, 1)
Write-Output "OK -> $Out  ($mb MB)"
Write-Output "On the target machine run: $Out\build.cmd"
