# ci.ps1 - mcs251 project CI: build all targets + host tests + 8-bit simulation.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools\ci.ps1
#   powershell -ExecutionPolicy Bypass -File tools\ci.ps1 -SkipUsb -SkipSim
#
# Covers:
#   1) mcs251: ziglog/zigled/zigasm/zigirq/zigmem/zigbuzz/ptrtest/uart/ccobs (+ usbcdc/usbhid)
#   2) mcs51 : simtest (then restore mcs251)
#   3) host  : cobs zig/c round-trip tests
#   4) 8-bit simulation: run simtest under WSL ucsim (needs WSL + built ucsim_51; -SkipSim to skip)
# NOTE: keep this file ASCII-only (PowerShell 5.1 reads .ps1 as ANSI unless UTF-8 BOM).
param(
    [switch]$SkipUsb,
    [switch]$SkipSim
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $root

$script:failed = 0
function Step([string]$name, [scriptblock]$body) {
    Write-Host ("== " + $name + " ==") -ForegroundColor Cyan
    $global:LASTEXITCODE = 0
    & $body
    if ($LASTEXITCODE -ne 0) {
        Write-Host ("FAIL: " + $name + " (exit " + $LASTEXITCODE + ")") -ForegroundColor Red
        $script:failed++
    }
}

# ---- 1) mcs251 targets ----
Step "xmake configure (mcs251)" { xmake f --mcs_arch=mcs251 }
# MCS_KEEP_BASE=1: also emit the pre-mcs_ir asm (base=fix+mcs_opt) as <x>.asm.base,
# used by the differential regression below. Reset before the mcs51 section.
$env:MCS_KEEP_BASE = "1"
$targets = @("ziglog","zigled","zigasm","zigirq","zigirqall","zigprint","ziguart","zigmem","zighotcold","zigrtindex","zigslice","zigrtslice","zigns","zigbuzz","ptrtest","uart","ccobs")
if (-not $SkipUsb) { $targets += @("usbcdc","usbhid","usbcdcobs") }
foreach ($t in $targets) { Step ("build " + $t) { xmake build $t } }

# ---- 1b) optimization regression (assertion budgets + E2 base/opt diff) ----
Step "regress: mcs_ir self-test" { python tools\mcs_ir.py --self-test }
Step "regress: mcs_opt self-test" { python tools\mcs_opt.py --self-test }
Step "regress: mcs_loop self-test" { python tools\mcs_loop.py --self-test }
Step "regress: mcs_regress self-test" { python tools\mcs_regress.py --self-test }
Step "regress: E2 base vs opt + budgets" {
    python tools\mcs_regress.py --auto `
        examples\ai8051u_zig_opt\opt.asm `
        examples\ai8051u_zig_ns\ns.asm `
        examples\ai8051u_zig_mem\mem.asm `
        examples\ai8051u_zig_slice\slice.asm `
        examples\ai8051u_zig_log\log.asm `
        examples\ai8051u_zig_buzz\buzzer.asm `
        examples\ai8051u_zig_rtindex\rtindex.asm `
        examples\ai8051u_zig_hotcold\hotcold.asm `
        --require-reduction
}
$env:MCS_KEEP_BASE = "0"

# ---- 2) mcs51 ----
Step "xmake configure (mcs51)" { xmake f --mcs_arch=mcs51 }
Step "build simtest" { xmake build simtest }
Step "build ccobs51" { xmake build ccobs51 }
Step "xmake configure (mcs251, restore)" { xmake f --mcs_arch=mcs251 }

# ---- 3) host tests ----
Step "host: cobs zig test" { zig run lib\cobs\cobs_zig_test.zig }
Step "host: cobs c test" {
    $exe = Join-Path $env:TEMP "cobs_c_test.exe"
    zig cc lib\cobs\cobs_c_test.c lib\cobs\cobs.c -o $exe
    if ($LASTEXITCODE -eq 0) { & $exe }
}

# ---- 4) 8-bit simulation (WSL ucsim runs simtest) ----
if (-not $SkipSim) {
    $cmd = Join-Path $env:TEMP "opencode\simtest.cmd"
    # WSL 镜像路径：C:\... -> /mnt/c/...
    $cmdWsl = "/mnt/" + $cmd.Substring(0, 1).ToLower() + ($cmd.Substring(2) -replace '\\', '/')
    $rootWsl = "/mnt/" + $root.Substring(0, 1).ToLower() + ($root.Substring(2) -replace '\\', '/')
    # STC15 ucsim（本机自建；可用环境变量 UCSIM51 覆盖）。
    $ucsim = if ($env:UCSIM51) { $env:UCSIM51 } else { "~/ucsim-stc/ucsim/src/sims/s51.src/ucsim_51" }
    if (Test-Path -LiteralPath $cmd) {
        Step "sim: ucsim simtest (expect 0x8000 = aa 00 02 04 08 10 20 40)" {
            $wslCmd = "cd $rootWsl && $ucsim -t STC15 -S in=/dev/null,out=- " +
                      "examples/at89c52_sim/simtest.ihx < $cmdWsl " +
                      "| grep -q 'aa 00 02 04 08 10 20 40'"
            wsl -e bash -lc $wslCmd
        }
        Step "sim: ccobs51 8-bit cobs (expect 03 7e 02 04 34 12 24 00)" {
            $wslCmd = "cd $rootWsl/examples/mcs51_c_cobs && $ucsim -t STC15 " +
                      "-S in=/dev/null,out=- ccobs51.ihx < sim.cmd | grep -q '03 7e 02 04 34 12 24'"
            wsl -e bash -lc $wslCmd
        }
    } else {
        Write-Host "skip sim: $cmd not found" -ForegroundColor Yellow
    }
}

Write-Host ""
if ($script:failed -eq 0) {
    Write-Host "CI OK" -ForegroundColor Green
    exit 0
} else {
    Write-Host ("CI FAILED: " + $script:failed + " step(s) failed") -ForegroundColor Red
    exit 1
}
