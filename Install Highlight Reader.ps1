$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms

$appName = 'Highlight Reader'
$sourceDir = $PSScriptRoot
$installDir = Join-Path $env:LOCALAPPDATA 'Programs\HighlightReader'
$startMenuDir = Join-Path ([Environment]::GetFolderPath('Programs')) 'Highlight Reader'
$desktopDir = [Environment]::GetFolderPath('Desktop')
$uninstallRegistryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\HighlightReader'

function New-Shortcut([string]$path, [string]$target, [string]$description) {
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($path)
    $shortcut.TargetPath = $target
    $shortcut.WorkingDirectory = $installDir
    $shortcut.Description = $description
    $shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,168"
    $shortcut.Save()
}

try {
    $answer = [System.Windows.Forms.MessageBox]::Show(
        'Install Highlight Reader for your Windows account? This adds a desktop settings icon and Start-menu shortcuts.',
        'Install Highlight Reader',
        'OKCancel',
        'Question'
    )
    if ($answer -ne [System.Windows.Forms.DialogResult]::OK) { exit }

    # Stop an older installed copy before replacing its files.
    try {
        Get-CimInstance Win32_Process | Where-Object {
            $_.Name -ieq 'powershell.exe' -and $_.CommandLine -match '[\\/]HighlightReader\.ps1'
        } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    } catch { }

    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    New-Item -ItemType Directory -Path $startMenuDir -Force | Out-Null

    $files = @(
        'HighlightReader.ps1',
        'Start Highlight Reader.vbs',
        'Edit Settings.vbs',
        'Stop Highlight Reader.ps1',
        'Stop Highlight Reader.vbs',
        'Uninstall Highlight Reader.ps1',
        'README.md'
    )
    foreach ($file in $files) {
        Copy-Item -LiteralPath (Join-Path $sourceDir $file) -Destination (Join-Path $installDir $file) -Force
    }

    $settingsLauncher = Join-Path $installDir 'Edit Settings.vbs'
    New-Shortcut (Join-Path $desktopDir 'Highlight Reader.lnk') $settingsLauncher 'Open Highlight Reader settings'
    New-Shortcut (Join-Path $startMenuDir 'Highlight Reader Settings.lnk') $settingsLauncher 'Open Highlight Reader settings'
    New-Shortcut (Join-Path $startMenuDir 'Start Highlight Reader.lnk') (Join-Path $installDir 'Start Highlight Reader.vbs') 'Start Highlight Reader in the system tray'

    $uninstallShortcut = Join-Path $startMenuDir 'Uninstall Highlight Reader.lnk'
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($uninstallShortcut)
    $shortcut.TargetPath = 'powershell.exe'
    $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -STA -File `"$(Join-Path $installDir 'Uninstall Highlight Reader.ps1')`""
    $shortcut.WorkingDirectory = $installDir
    $shortcut.Description = 'Uninstall Highlight Reader'
    $shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,131"
    $shortcut.Save()

    New-Item -Path $uninstallRegistryPath -Force | Out-Null
    New-ItemProperty -Path $uninstallRegistryPath -Name DisplayName -Value 'Highlight Reader' -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $uninstallRegistryPath -Name DisplayVersion -Value '1.0.0' -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $uninstallRegistryPath -Name Publisher -Value 'Allen Depena' -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $uninstallRegistryPath -Name InstallLocation -Value $installDir -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $uninstallRegistryPath -Name DisplayIcon -Value "$env:SystemRoot\System32\shell32.dll,168" -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $uninstallRegistryPath -Name UninstallString -Value "powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File `"$(Join-Path $installDir 'Uninstall Highlight Reader.ps1')`"" -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $uninstallRegistryPath -Name NoModify -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $uninstallRegistryPath -Name NoRepair -Value 1 -PropertyType DWord -Force | Out-Null

    Start-Process -FilePath (Join-Path $installDir 'Start Highlight Reader.vbs')
    [System.Windows.Forms.MessageBox]::Show(
        "Highlight Reader is installed.`n`nUse the desktop icon to change settings. The app runs from the system tray. Remove it from Windows Settings > Apps, or Start > Highlight Reader > Uninstall Highlight Reader.",
        'Installation complete',
        'OK',
        'Information'
    ) | Out-Null
} catch {
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Installation failed', 'OK', 'Error') | Out-Null
    exit 1
}
