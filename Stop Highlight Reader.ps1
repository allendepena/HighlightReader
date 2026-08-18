$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms

try {
    $matches = @(Get-CimInstance Win32_Process | Where-Object {
        $_.Name -ieq 'powershell.exe' -and $_.CommandLine -match '[\\/]HighlightReader\.ps1'
    })
    foreach ($process in $matches) {
        Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
    }
    $message = if ($matches.Count -gt 0) {
        "Stopped $($matches.Count) Highlight Reader process(es). You can start the updated app now."
    } else {
        'No running Highlight Reader process was found. Restart Windows to release the hotkey, then start the updated app once.'
    }
    [System.Windows.Forms.MessageBox]::Show($message, 'Highlight Reader', 'OK', 'Information') | Out-Null
} catch {
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Could not stop Highlight Reader', 'OK', 'Error') | Out-Null
}