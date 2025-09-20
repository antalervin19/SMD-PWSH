param (
    [string]$Action
)

$gameExePath = $env:SteamGamePath
$gameDir = [System.IO.Path]::GetDirectoryName($gameExePath)
$valveDll = "steam_api64.dll"
$customDllUrl = "https://github.com/antalervin19/SMD-PWSH/raw/main/steam_api64.dll"
$customDllPath = Join-Path $gameDir $valveDll
$backupDllPath = Join-Path $gameDir "steam_api64_real.dll"
$markerFile = Join-Path $gameDir "installed.txt"

function Rename-ValveDll {
    $existingDll = Join-Path $gameDir $valveDll
    if (Test-Path $existingDll) {
        Rename-Item -Path $existingDll -NewName "steam_api64_real.dll" -Force
        Write-Host "Valve DLL renamed to steam_api64_real.dll."
    } else {
        Write-Host "No existing Valve DLL found."
    }
}

function Download-CustomDll {
    if (-not (Test-Path $customDllPath)) {
        Invoke-WebRequest -Uri $customDllUrl -OutFile $customDllPath
        Write-Host "Custom DLL downloaded successfully."
    } else {
        Write-Host "Custom DLL already exists."
    }
}

function Create-MarkerFile {
    if (-not (Test-Path $markerFile)) {
        New-Item -Path $markerFile -ItemType File -Force
        Write-Host "Marker file created."
    } else {
        Write-Host "Marker file already exists."
    }
}

function Launch-Game {
    if (Test-Path $gameExePath) {
        Start-Process $gameExePath
    } else {
        Write-Host "Game executable not found."
    }
}

switch ($Action) {
    'install' {
        if (-not (Test-Path $markerFile)) {
            Rename-ValveDll
            Download-CustomDll
            Create-MarkerFile
            Launch-Game
        } else {
            Write-Host "Installation has already been performed."
        }
        break
    }
    'uninstall' {
        if (Test-Path $markerFile) {
            Remove-Item -Path $markerFile -Force
            Rename-Item -Path $backupDllPath -NewName $valveDll -Force
            Write-Host "Uninstallation complete."
        } else {
            Write-Host "No installation found to uninstall."
        }
        break
    }
    default {
        Write-Host "Invalid action specified."
        break
    }
}
