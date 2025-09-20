param(
    [string] $GameExe,
    [string] $Action
)

#-Ben what are you looking for here? GO BACK TO STEAM!

if (-not $GameExe -or -not (Test-Path $GameExe)) {
    Write-Host "GameExe not provided. Attempting to detect Scrap Mechanic install folder from Steam..."
    
    $steamPaths = @(
        "$env:ProgramFiles(x86)\Steam",
        "$env:ProgramFiles\Steam"
    )

    $found = $false
    foreach ($steamPath in $steamPaths) {
        $manifestPath = Join-Path $steamPath "steamapps\appmanifest_387990.acf"
        if (Test-Path $manifestPath) {
            $content = Get-Content $manifestPath | Out-String
            if ($content -match '"installdir"\s+"(.+)"') {
                $gameDir = Join-Path (Join-Path $steamPath "steamapps\common") $matches[1]
                $GameExe = Join-Path $gameDir "Release\Scrap Mechanic.exe"
                if (Test-Path $GameExe) {
                    Write-Host "Detected game exe at: $GameExe"
                    $found = $true
                    break
                }
            }
        }
    }

    if (-not $found) {
        Write-Error "Could not detect Scrap Mechanic install folder. Exiting."
        Read-Host "Press Enter to exit..."
        exit 1
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
