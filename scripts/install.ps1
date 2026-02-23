#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs FileDonkey on Windows.

.DESCRIPTION
    Downloads and installs the latest version of FileDonkey from https://filedonkey.app.
    After installation, FileDonkey will run in the system tray and be ready to use.

.EXAMPLE
    .\install.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$appName    = 'FileDonkey'
$downloadUrl = 'https://filedonkey.app/download/windows'
$installDir  = Join-Path $env:ProgramFiles $appName
$installer   = Join-Path $env:TEMP 'FileDonkeySetup.exe'

Write-Host "=== $appName Installer ===" -ForegroundColor Cyan

# Download
Write-Host "Downloading $appName..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installer -UseBasicParsing
} catch {
    Write-Error "Failed to download $appName. Please check your internet connection and try again."
    exit 1
}

# Verify the installer is a valid PE (portable executable) before running it
$bytes = [System.IO.File]::ReadAllBytes($installer)
if ($bytes.Length -lt 2 -or $bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) {
    Remove-Item -Path $installer -Force -ErrorAction SilentlyContinue
    Write-Error "Downloaded file does not appear to be a valid Windows executable. Aborting."
    exit 1
}

# Install silently
Write-Host "Installing $appName to '$installDir'..." -ForegroundColor Yellow
try {
    $process = Start-Process -FilePath $installer -ArgumentList '/S', "/D=$installDir" -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        Write-Error "Installer exited with code $($process.ExitCode)."
        exit $process.ExitCode
    }
} catch {
    Write-Error "Installation failed: $_"
    exit 1
} finally {
    Remove-Item -Path $installer -Force -ErrorAction SilentlyContinue
}

# Add firewall rule so FileDonkey can communicate on the local network
$exePath = Join-Path $installDir 'FileDonkey.exe'
if (Test-Path $exePath) {
    $ruleName = "$appName Local Network"
    if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
        Write-Host "Adding Windows Firewall rule for local network access..." -ForegroundColor Yellow
        New-NetFirewallRule `
            -DisplayName $ruleName `
            -Direction   Inbound `
            -Program     $exePath `
            -Action      Allow `
            -Profile     Private `
            -Protocol    TCP | Out-Null
    }
}

Write-Host "$appName installed successfully!" -ForegroundColor Green
Write-Host "Launch it from the Start Menu or from '$installDir'." -ForegroundColor Green
