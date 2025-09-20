param(
    [string]$GameExe,
    [string]$Action
)

$gameDir    = Split-Path $GameExe -Parent
$releaseDir = Join-Path $gameDir "Release"
$steamDll   = Join-Path $releaseDir "steam_api64.dll"
$valveDll    = Join-Path $releaseDir "steam_api64_real.dll"
$stateFile  = Join-Path $releaseDir "mod_state.txt"

$modUrl     = "https://raw.githubusercontent.com/antalervin19/SMD-PWSH/main/steam_api64.dll"

function Install-Mod {
    if (!(Test-Path $valveDll)) {
        Rename-Item -Path $steamDll -NewName "steam_api64_real.dll" -Force
    }

    Invoke-WebRequest -Uri $modUrl -OutFile $steamDll -UseBasicParsing -Force
    "installed" | Out-File -FilePath $stateFile -Encoding ASCII
    Write-Host "Mod installed."
}

function Uninstall-Mod {
    if (Test-Path $valveDll) {
        if (Test-Path $steamDll) { Remove-Item $steamDll -Force }
        Rename-Item -Path $valveDll -NewName "steam_api64.dll" -Force
    }

    if (Test-Path $stateFile) { Remove-Item $stateFile -Force }
    Write-Host "🗑️ Mod uninstalled, game is vanilla."
}

function Run-Game {
    Start-Process -FilePath $GameExe -WorkingDirectory $gameDir
}

switch ($Action) {
    "install" {
        if (Test-Path $stateFile) {
            Write-Host "Mod already installed, skipping..."
        } else {
            Install-Mod
        }
        Run-Game
    }
    "uninstall" {
        if (Test-Path $stateFile) {
            Uninstall-Mod
        } else {
            Write-Host "Mod not installed, nothing to do."
        }
        Run-Game
    }
    Default {
        Write-Host "Launching game normally"
        Run-Game
    }
}
