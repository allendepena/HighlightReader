param([switch]$ShowSettings)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type -ReferencedAssemblies @('System.Windows.Forms', 'System.Drawing') -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class HotkeyWindow : Form
{
    const int WM_HOTKEY = 0x0312;
    const int HOTKEY_ID = 7419;
    const uint MOD_CONTROL = 0x0002;
    const uint MOD_SHIFT = 0x0004;
    const uint MOD_NOREPEAT = 0x4000;

    [DllImport("user32.dll", SetLastError=true)]
    static extern bool RegisterHotKey(IntPtr hWnd, int id, uint modifiers, uint key);
    [DllImport("user32.dll", SetLastError=true)]
    static extern bool UnregisterHotKey(IntPtr hWnd, int id);
    [DllImport("user32.dll")]
    static extern short GetAsyncKeyState(int key);

    public static bool ModifiersAreDown()
    {
        return (GetAsyncKeyState((int)Keys.ControlKey) & 0x8000) != 0 ||
               (GetAsyncKeyState((int)Keys.ShiftKey) & 0x8000) != 0;
    }

    public event EventHandler HotkeyPressed;
    public bool HotkeyRegistered { get; private set; }

    public HotkeyWindow()
    {
        ShowInTaskbar = false;
        FormBorderStyle = FormBorderStyle.FixedToolWindow;
        WindowState = FormWindowState.Minimized;
        Opacity = 0;
    }

    protected override void SetVisibleCore(bool value) { base.SetVisibleCore(false); }

    protected override void OnHandleCreated(EventArgs e)
    {
        base.OnHandleCreated(e);
        HotkeyRegistered = RegisterHotKey(Handle, HOTKEY_ID, MOD_CONTROL | MOD_SHIFT | MOD_NOREPEAT, (uint)Keys.R);
    }

    protected override void OnHandleDestroyed(EventArgs e)
    {
        if (HotkeyRegistered) UnregisterHotKey(Handle, HOTKEY_ID);
        base.OnHandleDestroyed(e);
    }

    protected override void WndProc(ref Message m)
    {
        if (m.Msg == WM_HOTKEY && m.WParam.ToInt32() == HOTKEY_ID && HotkeyPressed != null)
            HotkeyPressed(this, EventArgs.Empty);
        base.WndProc(ref m);
    }
}
'@

$appName = 'Highlight Reader'
$appDir = Join-Path $env:LOCALAPPDATA 'HighlightReader'
$settingsPath = Join-Path $appDir 'settings.json'
$audioPath = Join-Path $appDir 'speech.wav'
$logPath = Join-Path $appDir 'HighlightReader.log'
$startupPath = Join-Path ([Environment]::GetFolderPath('Startup')) 'Highlight Reader.lnk'
$launcherPath = Join-Path $PSScriptRoot 'Start Highlight Reader.vbs'
if (-not (Test-Path $appDir)) { New-Item -ItemType Directory -Path $appDir -Force | Out-Null }
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Write-Log([string]$message) {
    try { Add-Content -Encoding UTF8 -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $message" } catch { }
}

function Repair-WavHeader([string]$path) {
    $bytes = [IO.File]::ReadAllBytes($path)
    if ($bytes.Length -lt 44 -or [Text.Encoding]::ASCII.GetString($bytes, 0, 4) -ne 'RIFF') { return }
    [Array]::Copy([BitConverter]::GetBytes([uint32]($bytes.Length - 8)), 0, $bytes, 4, 4)
    for ($i = 12; $i -le $bytes.Length - 8; $i++) {
        if ($bytes[$i] -eq 100 -and $bytes[$i+1] -eq 97 -and $bytes[$i+2] -eq 116 -and $bytes[$i+3] -eq 97) {
            [Array]::Copy([BitConverter]::GetBytes([uint32]($bytes.Length - ($i + 8))), 0, $bytes, $i + 4, 4)
            break
        }
    }
    [IO.File]::WriteAllBytes($path, $bytes)
}

function Get-Settings {
    $result = [ordered]@{ EncryptedApiKey=''; Voice='nova'; Model='tts-1'; Speed=1.0; StartWithWindows=$false }
    if (Test-Path $settingsPath) {
        try {
            $saved = Get-Content -Raw $settingsPath | ConvertFrom-Json
            foreach ($name in @($result.Keys)) {
                if ($null -ne $saved.$name) { $result[$name] = $saved.$name }
            }
        } catch { }
    }
    return $result
}

function Protect-Key([string]$plain) {
    if ([string]::IsNullOrWhiteSpace($plain)) { return '' }
    ConvertFrom-SecureString (ConvertTo-SecureString $plain -AsPlainText -Force)
}

function Unprotect-Key([string]$encrypted) {
    if ([string]::IsNullOrWhiteSpace($encrypted)) { return '' }
    try {
        $secure = ConvertTo-SecureString $encrypted
        $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer) }
        finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
    } catch { '' }
}

function Set-Startup([bool]$enabled) {
    if ($enabled) {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($startupPath)
        $shortcut.TargetPath = $launcherPath
        $shortcut.WorkingDirectory = $PSScriptRoot
        $shortcut.Description = 'Read highlighted text with Ctrl+Shift+R'
        $shortcut.Save()
    } elseif (Test-Path $startupPath) {
        Remove-Item -LiteralPath $startupPath -Force
    }
}

$script:settings = Get-Settings
$script:player = New-Object System.Media.SoundPlayer
$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Text = 'Highlight Reader - Ctrl+Shift+R'
$notify.Icon = [System.Drawing.SystemIcons]::Information
$notify.Visible = $true

function Show-Notice([string]$title, [string]$message, [System.Windows.Forms.ToolTipIcon]$icon = [System.Windows.Forms.ToolTipIcon]::Info) {
    $notify.BalloonTipTitle = $title
    $notify.BalloonTipText = $message
    $notify.BalloonTipIcon = $icon
    $notify.ShowBalloonTip(3500)
}

function Show-SettingsWindow {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Highlight Reader settings'
    $form.Size = New-Object System.Drawing.Size(470, 425)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.Font = New-Object System.Drawing.Font('Segoe UI', 10)

    $title = New-Object System.Windows.Forms.Label
    $title.Text = 'Read anything you highlight'
    $title.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 16)
    $title.AutoSize = $true
    $title.Location = New-Object System.Drawing.Point(24, 20)
    $form.Controls.Add($title)

    $hint = New-Object System.Windows.Forms.Label
    $hint.Text = 'Highlight text in any app, then press Ctrl + Shift + R.'
    $hint.AutoSize = $true
    $hint.ForeColor = [System.Drawing.Color]::DimGray
    $hint.Location = New-Object System.Drawing.Point(27, 57)
    $form.Controls.Add($hint)

    $keyLabel = New-Object System.Windows.Forms.Label
    $keyLabel.Text = 'OpenAI API key'
    $keyLabel.AutoSize = $true
    $keyLabel.Location = New-Object System.Drawing.Point(27, 99)
    $form.Controls.Add($keyLabel)

    $keyBox = New-Object System.Windows.Forms.TextBox
    $keyBox.Location = New-Object System.Drawing.Point(30, 122)
    $keyBox.Size = New-Object System.Drawing.Size(395, 28)
    $keyBox.UseSystemPasswordChar = $true
    $keyBox.Text = Unprotect-Key ([string]$script:settings.EncryptedApiKey)
    $form.Controls.Add($keyBox)

    $voiceLabel = New-Object System.Windows.Forms.Label
    $voiceLabel.Text = 'Voice'
    $voiceLabel.AutoSize = $true
    $voiceLabel.Location = New-Object System.Drawing.Point(27, 166)
    $form.Controls.Add($voiceLabel)

    $voiceBox = New-Object System.Windows.Forms.ComboBox
    $voiceBox.Location = New-Object System.Drawing.Point(30, 189)
    $voiceBox.Size = New-Object System.Drawing.Size(185, 28)
    $voiceBox.DropDownStyle = 'DropDownList'
    [void]$voiceBox.Items.AddRange([object[]]@('alloy','echo','fable','onyx','nova','shimmer'))
    $voiceBox.SelectedItem = [string]$script:settings.Voice
    if ($voiceBox.SelectedIndex -lt 0) { $voiceBox.SelectedItem = 'nova' }
    $form.Controls.Add($voiceBox)

    $qualityLabel = New-Object System.Windows.Forms.Label
    $qualityLabel.Text = 'Quality'
    $qualityLabel.AutoSize = $true
    $qualityLabel.Location = New-Object System.Drawing.Point(237, 166)
    $form.Controls.Add($qualityLabel)

    $qualityBox = New-Object System.Windows.Forms.ComboBox
    $qualityBox.Location = New-Object System.Drawing.Point(240, 189)
    $qualityBox.Size = New-Object System.Drawing.Size(185, 28)
    $qualityBox.DropDownStyle = 'DropDownList'
    [void]$qualityBox.Items.AddRange([object[]]@('Fast','High quality'))
    $qualityBox.SelectedItem = $(if ([string]$script:settings.Model -eq 'tts-1-hd') { 'High quality' } else { 'Fast' })
    $form.Controls.Add($qualityBox)

    $speedLabel = New-Object System.Windows.Forms.Label
    $speedLabel.Text = 'Reading speed'
    $speedLabel.AutoSize = $true
    $speedLabel.Location = New-Object System.Drawing.Point(27, 235)
    $form.Controls.Add($speedLabel)

    $speedBox = New-Object System.Windows.Forms.NumericUpDown
    $speedBox.Location = New-Object System.Drawing.Point(145, 232)
    $speedBox.Size = New-Object System.Drawing.Size(70, 28)
    $speedBox.DecimalPlaces = 1
    $speedBox.Increment = [decimal]0.1
    $speedBox.Minimum = [decimal]0.5
    $speedBox.Maximum = [decimal]2.0
    $speedBox.Value = [decimal]$script:settings.Speed
    $form.Controls.Add($speedBox)

    $startupBox = New-Object System.Windows.Forms.CheckBox
    $startupBox.Text = 'Start Highlight Reader when I sign in'
    $startupBox.AutoSize = $true
    $startupBox.Location = New-Object System.Drawing.Point(30, 277)
    $startupBox.Checked = [bool]$script:settings.StartWithWindows
    $form.Controls.Add($startupBox)

    $privacy = New-Object System.Windows.Forms.Label
    $privacy.Text = 'Your key is encrypted for your Windows account. Highlighted text is sent to OpenAI to create the audio.'
    $privacy.ForeColor = [System.Drawing.Color]::DimGray
    $privacy.Location = New-Object System.Drawing.Point(27, 308)
    $privacy.Size = New-Object System.Drawing.Size(400, 40)
    $form.Controls.Add($privacy)

    $save = New-Object System.Windows.Forms.Button
    $save.Text = 'Save'
    $save.Size = New-Object System.Drawing.Size(95, 34)
    $save.Location = New-Object System.Drawing.Point(330, 350)
    $save.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $save
    $form.Controls.Add($save)

    if ($form.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        if ([string]::IsNullOrWhiteSpace($keyBox.Text)) {
            [System.Windows.Forms.MessageBox]::Show('Enter an OpenAI API key first.', $appName, 'OK', 'Warning') | Out-Null
            return Show-SettingsWindow
        }
        $script:settings.EncryptedApiKey = Protect-Key $keyBox.Text.Trim()
        $script:settings.Voice = [string]$voiceBox.SelectedItem
        $script:settings.Model = $(if ($qualityBox.SelectedItem -eq 'High quality') { 'tts-1-hd' } else { 'tts-1' })
        $script:settings.Speed = [double]$speedBox.Value
        $script:settings.StartWithWindows = $startupBox.Checked
        Set-Startup $startupBox.Checked
        $script:settings | ConvertTo-Json | Set-Content -Encoding UTF8 $settingsPath
        Show-Notice 'Highlight Reader is ready' 'Highlight text anywhere and press Ctrl+Shift+R.'
    }
}

function Get-SelectedText {
    # Wait for the physical hotkey keys to be released before sending Ctrl+C.
    for ($wait = 0; $wait -lt 20 -and [HotkeyWindow]::ModifiersAreDown(); $wait++) {
        Start-Sleep -Milliseconds 50
    }
    $original = $null
    try { $original = [System.Windows.Forms.Clipboard]::GetDataObject() } catch { }
    try { [System.Windows.Forms.Clipboard]::Clear() } catch { }
    [System.Windows.Forms.SendKeys]::SendWait('^c')
    Start-Sleep -Milliseconds 250
    $text = ''
    for ($i = 0; $i -lt 5; $i++) {
        try {
            if ([System.Windows.Forms.Clipboard]::ContainsText()) {
                $text = [System.Windows.Forms.Clipboard]::GetText()
                break
            }
        } catch { }
        Start-Sleep -Milliseconds 80
    }
    if ($null -ne $original) {
        try { [System.Windows.Forms.Clipboard]::SetDataObject($original, $true) } catch { }
    }
    return $text.Trim()
}

function Read-HighlightedText {
    Write-Log 'Ctrl+Shift+R detected.'
    Show-Notice 'Hotkey detected' 'Copying your highlighted text...'
    $apiKey = Unprotect-Key ([string]$script:settings.EncryptedApiKey)
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        Show-Notice 'Setup needed' 'Open settings and add your OpenAI API key.' ([System.Windows.Forms.ToolTipIcon]::Warning)
        Show-SettingsWindow
        return
    }

    $text = Get-SelectedText
    if ([string]::IsNullOrWhiteSpace($text)) {
        Write-Log 'No selected text was copied.'
        Show-Notice 'Nothing selected' 'Highlight some text, then press Ctrl+Shift+R.' ([System.Windows.Forms.ToolTipIcon]::Warning)
        return
    }
    Write-Log "Copied $($text.Length) characters. Requesting speech."
    if ($text.Length -gt 4000) {
        $text = $text.Substring(0, 4000)
        Show-Notice 'Long selection' 'Reading the first 4,000 characters.'
    }

    $notify.Text = 'Highlight Reader - creating speech...'
    try {
        $script:player.Stop()
        $body = @{
            model = [string]$script:settings.Model
            voice = [string]$script:settings.Voice
            input = $text
            response_format = 'wav'
            speed = [double]$script:settings.Speed
        } | ConvertTo-Json -Compress
        $headers = @{ Authorization = "Bearer $apiKey" }
        Invoke-WebRequest -UseBasicParsing -Uri 'https://api.openai.com/v1/audio/speech' -Method Post -Headers $headers -ContentType 'application/json' -Body ([Text.Encoding]::UTF8.GetBytes($body)) -OutFile $audioPath
        Repair-WavHeader $audioPath
        $script:player.SoundLocation = $audioPath
        $script:player.Load()
        $script:player.Play()
        Write-Log "Speech started. Audio file size: $((Get-Item $audioPath).Length) bytes."
    } catch {
        $message = $_.Exception.Message
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
            try { $message = (($_.ErrorDetails.Message | ConvertFrom-Json).error.message) } catch { }
        }
        Write-Log "ERROR: $message"
        Show-Notice 'Could not create speech' $message ([System.Windows.Forms.ToolTipIcon]::Error)
        [System.Windows.Forms.MessageBox]::Show($message, 'Highlight Reader could not speak', 'OK', 'Error') | Out-Null
    } finally {
        $notify.Text = 'Highlight Reader - Ctrl+Shift+R'
    }
}

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$settingsItem = $menu.Items.Add('Settings...')
$stopItem = $menu.Items.Add('Stop speaking')
[void]$menu.Items.Add('-')
$exitItem = $menu.Items.Add('Exit')
$notify.ContextMenuStrip = $menu
$notify.Add_DoubleClick({ Show-SettingsWindow })
$settingsItem.Add_Click({ Show-SettingsWindow })
$stopItem.Add_Click({ try { $script:player.Stop() } catch { } })
$exitItem.Add_Click({ [System.Windows.Forms.Application]::Exit() })

$window = New-Object HotkeyWindow
$window.add_HotkeyPressed({ Read-HighlightedText })
$window.Add_FormClosed({ $notify.Visible = $false; $notify.Dispose() })

try {
    [void]$window.Handle
    if (-not $window.HotkeyRegistered) {
        throw 'Another Highlight Reader is already running. Exit the old copy from the taskbar tray, then start this one again.'
    }
    if ($ShowSettings -or [string]::IsNullOrWhiteSpace([string]$script:settings.EncryptedApiKey)) { Show-SettingsWindow }
    Write-Log 'Highlight Reader started and registered Ctrl+Shift+R.'
    Show-Notice 'Highlight Reader is running' 'Highlight text anywhere and press Ctrl+Shift+R.'
    [System.Windows.Forms.Application]::Run($window)
} catch {
    $notify.Visible = $false
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, $appName, 'OK', 'Error') | Out-Null
} finally {
    $notify.Visible = $false
    $notify.Dispose()
}
