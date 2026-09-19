# Install the "mcs251" VSCode debug extension.
# Prefers the VSCode CLI (package a .vsix with npx vsce and install it); falls
# back to copying the folder into the user extensions dir.
# ASCII only: PowerShell 5.1 reads .ps1 using the system code page.
#
# A workspace may be bound to a VSCode *profile* (settings/preferences icon ->
# Profiles). Extensions are per-profile, so an install into the default profile
# is invisible inside that workspace. Pass the profile name to target it:
#   powershell -File install_vscode_ext.ps1 -Profile "<profile-name>"
param(
    [string]$Profile = ''
)
$src = Join-Path $PSScriptRoot 'vscode-mcs251'
if (-not (Test-Path -LiteralPath $src)) {
    Write-Error "not found: $src"
    exit 1
}

function Find-CodeCli {
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin\code.cmd'),
        (Join-Path $env:ProgramFiles 'Microsoft VS Code\bin\code.cmd')
    )
    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) { return $c }
    }
    $cmd = Get-Command code -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

$code = Find-CodeCli
$installed = $false

if ($code -and (Get-Command npx -ErrorAction SilentlyContinue)) {
    $vsix = Join-Path $env:TEMP 'mcs251-debug.vsix'
    Push-Location $src
    try {
        & npx --yes @vscode/vsce package --allow-missing-repository --skip-license -o $vsix 2>$null | Out-Null
    } catch {
        Write-Host "[WARN] vsce packaging failed: $($_.Exception.Message)"
    } finally {
        Pop-Location
    }
    if (Test-Path -LiteralPath $vsix) {
        try {
            $cliArgs = @()
            if ($Profile -ne '') { $cliArgs += @('--profile', $Profile) }
            $cliArgs += @('--install-extension', $vsix, '--force')
            & $code @cliArgs 2>$null | Out-Null
            $installed = $true
            if ($Profile -ne '') {
                Write-Host "[OK] installed via VSCode CLI into profile: $Profile"
            } else {
                Write-Host "[OK] installed via VSCode CLI (default profile)."
                Write-Host "[!] if the workspace uses a profile, rerun with -Profile <name>."
            }
        } catch {
            Write-Host "[WARN] CLI install failed: $($_.Exception.Message)"
        }
        Remove-Item -LiteralPath $vsix -Force -ErrorAction SilentlyContinue
    }
}

if (-not $installed) {
    $dstRoot = Join-Path $env:USERPROFILE '.vscode\extensions'
    $dst = Join-Path $dstRoot 'manniu.mcs251-debug-0.0.1'
    if (Test-Path -LiteralPath $dst) {
        Remove-Item -LiteralPath $dst -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    Copy-Item -Path (Join-Path $src '*') -Destination $dst -Recurse -Force
    Write-Host "[OK] copied to: $dst"
}

if (Get-Process Code -ErrorAction SilentlyContinue) {
    Write-Host "[!] VSCode is running. Fully QUIT VSCode and reopen it to load the extension."
} else {
    Write-Host "Start VSCode to load the extension."
}
