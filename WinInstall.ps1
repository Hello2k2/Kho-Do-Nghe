# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- CONFIG ---
$RawUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/"
$TempDir = "$env:TEMP\PhatTan_Tool"
if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir | Out-Null }

# --- GUI ---
try { Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing } catch { Exit }
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "PHAT TAN PC - WIN INSTALLER MANAGER"
$Form.Size = New-Object System.Drawing.Size(500, 300); $Form.StartPosition = "CenterScreen"; $Form.BackColor = "#2D2D30"; $Form.ForeColor = "White"

function Load-Mod ($Name) {
    $P = "$TempDir\$Name"
    try { 
        [System.Net.ServicePointManager]::SecurityProtocol = 3072
        (New-Object Net.WebClient).DownloadFile("$RawUrl$Name", $P)
        Start-Process powershell "-Ex Bypass -File `"$P`"" 
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi tai Module: $Name", "Error") }
}

# Font Chuan
$FontBold = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)

$BtnCfg = New-Object System.Windows.Forms.Button
$BtnCfg.Text = "1. CAU HINH TU DONG (XML)"; $BtnCfg.Location = "50,30"; $BtnCfg.Size = "380,60"; $BtnCfg.BackColor = "Cyan"; $BtnCfg.ForeColor = "Black"
$BtnCfg.Font = $FontBold
$BtnCfg.Add_Click({ Load-Mod "WinInstall_Config.ps1" })
$Form.Controls.Add($BtnCfg)

$BtnRun = New-Object System.Windows.Forms.Button
$BtnRun.Text = "2. TIEN HANH CAI DAT (CORE)"; $BtnRun.Location = "50,110"; $BtnRun.Size = "380,60"; $BtnRun.BackColor = "LimeGreen"; $BtnRun.ForeColor = "Black"
$BtnRun.Font = $FontBold
$BtnRun.Add_Click({ Load-Mod "WinInstall_Core.ps1" })
$Form.Controls.Add($BtnRun)

$Form.ShowDialog() | Out-Null
