param(
    [string] $GameExe,
    [string] $Action
)

#-Ben what are you looking for here? GO BACK TO STEAM!

if (-not $GameExe -or -not (Test-Path $GameExe)) {
    $GameExe = "G:\SteamLibrary\steamapps\common\Scrap Mechanic\Release\Scrap Mechanic.exe"
    if (-not (Test-Path $GameExe)) {
        Write-Error "GameExe not provided and default path '$GameExe' not found. Exiting."
        Read-Host "Press Enter to exit..."
        exit 1
    } else {
        Write-Host "Using default game exe: $GameExe"
    }
}

$gameDir    = Split-Path $GameExe -Parent
$releaseDir = Join-Path $gameDir "Release"

if (-not (Test-Path $releaseDir)) {
    Write-Error "Release directory '$releaseDir' not found. Exiting."
    Read-Host "Press Enter to exit..."
    exit 1
}

$steamDll    = Join-Path $releaseDir "steam_api64.dll"
$valveDll    = Join-Path $releaseDir "steam_api64_real.dll"
$stateFile   = Join-Path $releaseDir "mod_state.txt"
$modUrl      = "https://raw.githubusercontent.com/antalervin19/SMD-PWSH/main/steam_api64.dll"

function Install-Mod {
    if (-not (Test-Path $valveDll)) {
        if (Test-Path $steamDll) {
            Rename-Item -Path $steamDll -NewName "steam_api64_real.dll" -Force
        } else {
            Write-Warning "Original steam_api64.dll not found; continuing with mod replace."
        }
    }

    try {
        Invoke-WebRequest -Uri $modUrl -OutFile $steamDll -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-Error "Failed to download mod DLL: $_"
        Read-Host "Press Enter to exit..."
        exit 1
    }

    "installed" | Out-File -FilePath $stateFile -Encoding ASCII
    Write-Host "Mod installed."
}

function Uninstall-Mod {
    if (Test-Path $valveDll) {
        if (Test-Path $steamDll) {
            Remove-Item $steamDll -Force
        }
        Rename-Item -Path $valveDll -NewName "steam_api64.dll" -Force
    } else {
        Write-Warning "Backup DLL ($valveDll) not found; cannot restore original."
    }

    if (Test-Path $stateFile) {
        Remove-Item $stateFile -Force
    }
    Write-Host "Mod uninstalled, game is vanilla."
}

function Run-Game {
    Start-Process -FilePath $GameExe -WorkingDirectory $gameDir
}

switch ($Action) {
    "install" {
        if (Test-Path $stateFile) {
            Write-Host "Mod already installed, skipping install."
        } else {
            Install-Mod
        }
        Run-Game
    }
    "uninstall" {
        if (Test-Path $stateFile) {
            Uninstall-Mod
        } else {
            Write-Host "Mod not installed, nothing to uninstall."
        }
        Run-Game
    }
    Default {
        Write-Host "Launching game normally..."
        Run-Game
    }
}

Read-Host "Press Enter to exit..."
