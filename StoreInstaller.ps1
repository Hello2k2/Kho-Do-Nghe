# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "MICROSOFT STORE INSTALLER (LTSC) - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(600, 400)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedToolWindow"

# Header
$LblT = New-Object System.Windows.Forms.Label
$LblT.Text = "LTSC STORE INSTALLER"; $LblT.Font = "Impact, 20"; $LblT.ForeColor="Cyan"; $LblT.AutoSize=$true; $LblT.Location="20,15"; $Form.Controls.Add($LblT)

$LblS = New-Object System.Windows.Forms.Label
$LblS.Text = "Ho tro: Windows 10 Enterprise LTSC 2019, 2021 & Windows 11 IoT Enterprise LTSC"; $LblS.ForeColor="Gray"; $LblS.AutoSize=$true; $LblS.Location="25,50"; $Form.Controls.Add($LblS)

# LOG BOX
$TxtLog = New-Object System.Windows.Forms.TextBox
$TxtLog.Multiline=$true; $TxtLog.ScrollBars="Vertical"; $TxtLog.Location="20,90"; $TxtLog.Size="545,180"
$TxtLog.BackColor="Black"; $TxtLog.ForeColor="Lime"; $TxtLog.Font="Consolas, 9"; $TxtLog.ReadOnly=$true
$Form.Controls.Add($TxtLog)

function Log ($M) { $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $M`r`n"); $TxtLog.ScrollToCaret(); [System.Windows.Forms.Application]::DoEvents() }

# --- LOGIC INSTALL ---
function Install-Store {
    $BtnInstall.Enabled = $false
    Log "Khoi dong quy trinh cai dat Store..."
    
    $WorkDir = "$env:TEMP\LTSC_Store_Install"
    if (Test-Path $WorkDir) { Remove-Item $WorkDir -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
    
    # 1. DOWNLOAD
    $Url = "https://github.com/kkkgo/LTSC-Add-MicrosoftStore/archive/refs/heads/master.zip"
    $ZipPath = "$WorkDir\Store.zip"
    
    try {
        Log "Dang tai bo cai tu Github (kkkgo)..."
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        (New-Object System.Net.WebClient).DownloadFile($Url, $ZipPath)
        Log " [OK] Tai thanh cong."
    } catch {
        Log " [ERR] Loi tai file: $($_.Exception.Message)"
        $BtnInstall.Enabled = $true; return
    }
    
    # 2. EXTRACT
    try {
        Log "Dang giai nen..."
        Expand-Archive -Path $ZipPath -DestinationPath $WorkDir -Force
        Log " [OK] Giai nen xong."
    } catch {
        Log " [ERR] Loi giai nen."
        $BtnInstall.Enabled = $true; return
    }
    
    # 3. INSTALL
    $ScriptDir = "$WorkDir\LTSC-Add-MicrosoftStore-master"
    $CmdFile = "$ScriptDir\Add-Store.cmd"
    
    if (Test-Path $CmdFile) {
        Log "Dang chay script cai dat (Add-Store.cmd)..."
        Log "Vui long cho 1-2 phut..."
        
        # Chạy CMD ngầm
        $Proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$CmdFile`"" -Verb RunAs -PassThru -Wait
        
        Log " [OK] Quy trinh hoan tat."
        [System.Windows.Forms.MessageBox]::Show("Da cai dat xong Microsoft Store!`nHay kiem tra trong Start Menu.", "Success")
    } else {
        Log " [ERR] Khong tim thay file Add-Store.cmd"
    }
    
    # Cleanup
    Remove-Item $WorkDir -Recurse -Force -ErrorAction SilentlyContinue
    $BtnInstall.Enabled = $true
}

# --- BUTTONS ---
$BtnInstall = New-Object System.Windows.Forms.Button
$BtnInstall.Text = "BAT DAU CAI STORE (DOWNLOAD & INSTALL)"
$BtnInstall.Location="20,290"; $BtnInstall.Size="545,50"; $BtnInstall.BackColor="Green"; $BtnInstall.ForeColor="White"; $BtnInstall.Font="Segoe UI, 12, Bold"; $BtnInstall.FlatStyle="Flat"
$BtnInstall.Add_Click({ Install-Store })
$Form.Controls.Add($BtnInstall)

$Form.ShowDialog() | Out-Null
