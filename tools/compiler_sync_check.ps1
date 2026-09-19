# compiler_sync_check.ps1 - report our delta vs upstream and flag unregistered upstream changes.
#
# Follows docs/27-上游迁移协定.md: our code must stay in known paths; upstream files only in the
# registered integration set. This prints the delta classified into OUR / INTEGRATION / REPO /
# UNEXPECTED so violations are visible.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools\compiler_sync_check.ps1
#   powershell -ExecutionPolicy Bypass -File tools\compiler_sync_check.ps1 -Fork <path> -Base <commit>
#
# Default fork dir = <repo>\compiler (the submodule = the fork working tree). ASCII only.
param(
    [string]$Fork,
    [string]$Base
)
$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
if (-not $Fork) { $Fork = Join-Path $repo "compiler" }
if (-not (Test-Path -LiteralPath $Fork)) {
    Write-Host ("fork not found: " + $Fork + " (pass -Fork <path>)") -ForegroundColor Red
    exit 2
}

Write-Host "== fork commit stack (our delta on top of upstream) ==" -ForegroundColor Cyan
git -C $Fork log --oneline -8

if (-not $Base) {
    # Prefer the fetched upstream tip's merge-base; else use the parent of our first backend commit.
    try { $Base = (git -C $Fork merge-base HEAD mirror/master 2>$null) } catch { $Base = $null }
    if (-not $Base) {
        $mcsCommits = @(git -C $Fork log --format=%H --grep "feat(mcs)" 2>$null)
        $first = $null
        if ($mcsCommits.Count -gt 0) { $first = $mcsCommits[$mcsCommits.Count - 1] }
        if ($first) { $Base = (git -C $Fork rev-parse "$first^" 2>$null) }
    }
}
if (-not $Base) {
    Write-Host ""
    Write-Host "== delta: skipped (no upstream base; fetch 'mirror' or pass -Base <commit>) ==" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host ("== delta vs upstream base " + $Base.Substring(0, 12) + " ==") -ForegroundColor Cyan
$files = git -C $Fork -c core.quotepath=false diff --name-only "$Base..HEAD"

$our     = @()
$inter   = @()
$repoLvl = @()
$unexp   = @()

$interSet = @(
  "src/codegen.zig", "src/target.zig", "src/Zcu.zig", "src/Sema.zig", "src/Type.zig",
  "src/dev.zig", "src/link.zig", "src/codegen/llvm.zig", "src/codegen/spirv/Module.zig",
  "lib/std/Target.zig", "lib/std/builtin.zig"
)
foreach ($f in $files) {
    if ($f -match '^src/codegen/mcs/' -or $f -eq 'src/link/Asx.zig' -or
        $f -eq 'lib/std/Target/mcs51.zig' -or $f -eq 'lib/std/Target/mcs251.zig') { $our += $f; continue }
    if ($interSet -contains $f) { $inter += $f; continue }
    if ($f -match '^(experimental/|doc/|ci/|README|\.github/|build\.zig$|\.gitmodules$|\.gitignore$|\.gitattributes$)') { $repoLvl += $f; continue }
    $unexp += $f
}

function Show($name, $arr) {
    Write-Host ("  " + $name.PadRight(12) + $arr.Count)
    foreach ($x in $arr) { Write-Host ("      " + $x) }
}
Show "OUR" $our
Show "INTEGRATION" $inter
Show "REPO" $repoLvl
if ($unexp.Count -gt 0) {
    Write-Host ("  UNEXPECTED   " + $unexp.Count + "  <-- review vs docs/27 (upstream file changed without registration?)") -ForegroundColor Red
    foreach ($x in $unexp) { Write-Host ("      " + $x) -ForegroundColor Red }
    exit 1
} else {
    Write-Host "  UNEXPECTED   0  (all changes are in registered paths)" -ForegroundColor Green
}
