#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Uninstalls FileDonkey from Windows.

.DESCRIPTION
    Runs the FileDonkey uninstaller, removes leftover application data,
    and cleans up the Windows Firewall rule that was added during installation.

.EXAMPLE
    .\uninstall.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$appName   = 'FileDonkey'
$installDir = Join-Path $env:ProgramFiles $appName
$uninstaller = Join-Path $installDir 'uninstall.exe'

Write-Host "=== $appName Uninstaller ===" -ForegroundColor Cyan

# Run the bundled uninstaller if it exists
if (Test-Path $uninstaller) {
    Write-Host "Running $appName uninstaller..." -ForegroundColor Yellow
    $process = Start-Process -FilePath $uninstaller -ArgumentList '/S' -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        Write-Warning "Uninstaller exited with code $($process.ExitCode)."
    }
} else {
    Write-Warning "Uninstaller not found at '$uninstaller'. Skipping."
}

# Remove install directory if it still exists
if (Test-Path $installDir) {
    # Safety check: only remove if this directory looks like a FileDonkey install
    $expectedMarker = Join-Path $installDir 'FileDonkey.exe'
    $uninstallerMark = Join-Path $installDir 'uninstall.exe'
    if ((Test-Path $expectedMarker) -or (Test-Path $uninstallerMark)) {
        Write-Host "Removing '$installDir'..." -ForegroundColor Yellow
        Remove-Item -Path $installDir -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-Warning "Unexpected contents in '$installDir'. Skipping directory removal."
    }
}

# Remove application data
$appDataPath = Join-Path $env:LOCALAPPDATA $appName
if (Test-Path $appDataPath) {
    # Safety check: only remove if the path is directly under LOCALAPPDATA and named FileDonkey
    $expectedParent = [System.IO.Path]::GetFullPath($env:LOCALAPPDATA)
    $resolvedPath   = [System.IO.Path]::GetFullPath($appDataPath)
    if ($resolvedPath.StartsWith($expectedParent + [System.IO.Path]::DirectorySeparatorChar) -and
        [System.IO.Path]::GetFileName($resolvedPath) -eq $appName) {
        Write-Host "Removing application data from '$appDataPath'..." -ForegroundColor Yellow
        Remove-Item -Path $appDataPath -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-Warning "Unexpected application data path '$appDataPath'. Skipping removal."
    }
}

# Remove Windows Firewall rule
$ruleName = "$appName Local Network"
if (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue) {
    Write-Host "Removing Windows Firewall rule '$ruleName'..." -ForegroundColor Yellow
    Remove-NetFirewallRule -DisplayName $ruleName
}

Write-Host "$appName has been uninstalled." -ForegroundColor Green
