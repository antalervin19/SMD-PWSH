param (
    [string]$Action = 'install'
)

$gameExePath = (Get-Command "steam://rungameid/387990").Source
$gameDir = [System.IO.Path]::GetDirectoryName($gameExePath)
$valveDllPath = Join-Path $gameDir 'steam_api64.dll'
$backupDllPath = Join-Path $gameDir 'steam_api64_real.dll'
$customDllUrl = 'https://github.com/antalervin19/SMD-PWSH/raw/main/steam_api64.dll'
$markerFile = Join-Path $gameDir 'installed.txt'

function Install-Mod {
    if (-not (Test-Path $markerFile)) {
        if (Test-Path $valveDllPath) {
            Rename-Item -Path $valveDllPath -NewName 'steam_api64_real.dll' -Force
            Write-Host 'Renamed original DLL to steam_api64_real.dll'
        }
        Invoke-WebRequest -Uri $customDllUrl -OutFile $valveDllPath
        Write-Host 'Downloaded custom DLL to steam_api64.dll'
        New-Item -Path $markerFile -ItemType File -Force
        Write-Host 'Created installation marker file'
    } else {
        Write-Host 'Mod is already installed. Skipping installation.'
    }
}

function Uninstall-Mod {
    if (Test-Path $markerFile) {
        Remove-Item -Path $markerFile -Force
        if (Test-Path $valveDllPath) {
            Remove-Item -Path $valveDllPath -Force
            Write-Host 'Removed custom DLL'
        }
        if (Test-Path $backupDllPath) {
            Rename-Item -Path $backupDllPath -NewName 'steam_api64.dll' -Force
            Write-Host 'Restored original DLL'
        }
    } else {
        Write-Host 'Mod is not installed. Nothing to uninstall.'
    }
}

switch ($Action) {
    'install' { Install-Mod }
    'uninstall' { Uninstall-Mod }
    default { Write-Host 'Invalid action specified. Use "install" or "uninstall".' }
}
