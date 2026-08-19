$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms

$expectedInstallDir = Join-Path $env:LOCALAPPDATA 'Programs\HighlightReader'
$installDir = [IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\')
$expected = [IO.Path]::GetFullPath($expectedInstallDir).TrimEnd('\')
$startMenuDir = Join-Path ([Environment]::GetFolderPath('Programs')) 'Highlight Reader'
$desktopShortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Highlight Reader.lnk'
$startupShortcut = Join-Path ([Environment]::GetFolderPath('Startup')) 'Highlight Reader.lnk'
$settingsDir = Join-Path $env:LOCALAPPDATA 'HighlightReader'
$uninstallRegistryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\HighlightReader'

try {
    if ($installDir -ine $expected) {
        throw "For safety, uninstall must be run from the installed folder: $expected"
    }

    $choice = [System.Windows.Forms.MessageBox]::Show(
        "Uninstall Highlight Reader?`n`nSelect Yes to also delete your saved settings and encrypted API key. Select No to keep them for a future reinstall. Select Cancel to stop.",
        'Uninstall Highlight Reader',
        'YesNoCancel',
        'Question'
    )
    if ($choice -eq [System.Windows.Forms.DialogResult]::Cancel) { exit }

    try {
        Get-CimInstance Win32_Process | Where-Object {
            $_.Name -ieq 'powershell.exe' -and
            $_.ProcessId -ne $PID -and
            $_.CommandLine -match '[\\/]HighlightReader\.ps1'
        } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    } catch { }

    foreach ($shortcut in @($desktopShortcut, $startupShortcut)) {
        if (Test-Path $shortcut) { Remove-Item -LiteralPath $shortcut -Force }
    }
    if (Test-Path $startMenuDir) { Remove-Item -LiteralPath $startMenuDir -Recurse -Force }
    if (Test-Path $uninstallRegistryPath) { Remove-Item -LiteralPath $uninstallRegistryPath -Recurse -Force }
    if ($choice -eq [System.Windows.Forms.DialogResult]::Yes -and (Test-Path $settingsDir)) {
        Remove-Item -LiteralPath $settingsDir -Recurse -Force
    }

    # A temporary cleanup script removes the installation directory after this
    # uninstaller process exits.
    $cleanupPath = Join-Path $env:TEMP "HighlightReader-cleanup-$PID.ps1"
    $escapedInstallDir = $installDir.Replace("'", "''")
    $cleanup = "Start-Sleep -Seconds 2`r`nRemove-Item -LiteralPath '$escapedInstallDir' -Recurse -Force`r`nRemove-Item -LiteralPath `$PSCommandPath -Force"
    [IO.File]::WriteAllText($cleanupPath, $cleanup, [Text.UTF8Encoding]::new($false))
    Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$cleanupPath)

    [System.Windows.Forms.MessageBox]::Show('Highlight Reader has been uninstalled.', 'Highlight Reader', 'OK', 'Information') | Out-Null
} catch {
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Uninstall failed', 'OK', 'Error') | Out-Null
    exit 1
}
