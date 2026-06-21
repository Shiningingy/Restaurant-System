<#
.SYNOPSIS
    Builds a release of the merchant and/or customer (client) app and copies the
    output into a clean, easy-to-navigate folder under  release/<platform>/.

.DESCRIPTION
    Flutter's default output is buried (e.g. apps/merchant/build/windows/x64/runner/Release).
    This script runs the build and then copies the finished bundle to:

        Windows :  release/windows/merchant/   (run merchant.exe inside)
                   release/windows/client/      (run customer.exe inside)
        Android :  release/android/merchant.apk
                   release/android/client.apk

    The whole  release/  folder is git-ignored, so it never gets committed.

.PARAMETER App
    Which app to build: merchant | client | both   (default: both)

.PARAMETER Platform
    Target platform: windows | android             (default: windows)

.EXAMPLE
    .\tools\build_release.ps1                       # both apps, Windows
    .\tools\build_release.ps1 merchant              # just the POS, Windows
    .\tools\build_release.ps1 both -Platform android
#>
[CmdletBinding()]
param(
    [ValidateSet('merchant', 'client', 'both')]
    [string]$App = 'both',

    [ValidateSet('windows', 'android')]
    [string]$Platform = 'windows'
)

$ErrorActionPreference = 'Stop'

# Repo root = parent folder of this script's  tools/  directory.
$root = Split-Path -Parent $PSScriptRoot
$releaseRoot = Join-Path $root "release\$Platform"

# Map the friendly name the user types to the actual app folder + exe name.
#   "client"  ->  apps/customer , customer.exe
$apps = @{
    merchant = @{ dir = 'merchant'; exe = 'merchant.exe' }
    client   = @{ dir = 'customer'; exe = 'customer.exe' }
}

$targets = if ($App -eq 'both') { @('merchant', 'client') } else { @($App) }

function Build-One {
    param([string]$name)

    $info = $apps[$name]
    $appDir = Join-Path $root "apps\$($info.dir)"
    Write-Host ""
    Write-Host "=== Building '$name'  ($($info.dir))  for $Platform ===" -ForegroundColor Cyan

    Push-Location $appDir
    try {
        if ($Platform -eq 'windows') {
            & flutter build windows --release
            if ($LASTEXITCODE -ne 0) { throw "flutter build windows failed for '$name'" }

            $src = Join-Path $appDir 'build\windows\x64\runner\Release'
            if (-not (Test-Path $src)) { throw "Build output not found: $src" }

            $dest = Join-Path $releaseRoot $name
            if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
            New-Item -ItemType Directory -Path $dest -Force | Out-Null
            Copy-Item -Path (Join-Path $src '*') -Destination $dest -Recurse -Force

            Write-Host "  -> $dest" -ForegroundColor Green
            Write-Host "     run: $(Join-Path $dest $info.exe)" -ForegroundColor Green
        }
        else {
            & flutter build apk --release
            if ($LASTEXITCODE -ne 0) { throw "flutter build apk failed for '$name'" }

            $src = Join-Path $appDir 'build\app\outputs\flutter-apk\app-release.apk'
            if (-not (Test-Path $src)) { throw "APK not found: $src" }

            New-Item -ItemType Directory -Path $releaseRoot -Force | Out-Null
            $dest = Join-Path $releaseRoot "$name.apk"
            Copy-Item -Path $src -Destination $dest -Force

            Write-Host "  -> $dest" -ForegroundColor Green
        }
    }
    finally {
        Pop-Location
    }
}

foreach ($t in $targets) { Build-One -name $t }

Write-Host ""
Write-Host "Done. Output is under:  $releaseRoot" -ForegroundColor Cyan
