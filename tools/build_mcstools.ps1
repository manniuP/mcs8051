# build_mcstools.ps1 - freeze the build-layer Python tools into ONE standalone exe.
#
# The portable toolchain set must work on a machine without Python installed, so the
# post-processing tools (fix_mcs_labels / mcs_opt / mcs_ir / mcs_overlay / mcs_dce) are
# bundled by PyInstaller into a single console program, "mcstools.exe".
#
# Usage (from mcs251/):
#   powershell -File tools\build_mcstools.ps1 [-Out <exe path>] [-Python <python.exe>]
#
# Requires: pip install pyinstaller
param(
    [string]$Out = "",
    [string]$Python = "python"
)
$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrEmpty($Out)) {
    $Out = Join-Path $repo "tools\out\mcstools.exe"
}
$entry = Join-Path $repo "tools\mcstools.py"
if (-not (Test-Path -LiteralPath $entry)) { throw "missing: $entry" }

$outDir = Split-Path -Parent $Out
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$work = Join-Path ([System.IO.Path]::GetTempPath()) ("mcstools_build_" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $work | Out-Null
Push-Location $repo
try {
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"   # PyInstaller writes progress to stderr; don't treat it as terminating
    & $Python -m PyInstaller --onefile --name mcstools `
        --distpath (Join-Path $work "dist") `
        --workpath (Join-Path $work "build") `
        --specpath $work --noconfirm $entry
    $pyiRc = $LASTEXITCODE
    $ErrorActionPreference = $prevEap
    if ($pyiRc -ne 0) { throw "PyInstaller failed with rc=$pyiRc" }
    Copy-Item -LiteralPath (Join-Path $work "dist\mcstools.exe") $Out -Force
} finally {
    Pop-Location
    Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
}

$kb = [math]::Round((Get-Item -LiteralPath $Out).Length / 1KB, 0)
Write-Output "OK -> $Out ($kb KB)"
& $Out --version
