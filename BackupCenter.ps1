# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"

# --- THEME NEON ---
$Theme = @{
    Back      = [System.Drawing.Color]::FromArgb(30, 30, 35)
    Card      = [System.Drawing.Color]::FromArgb(40, 40, 45)
    Text      = [System.Drawing.Color]::FromArgb(240, 240, 240)
    BtnBack   = [System.Drawing.Color]::FromArgb(60, 60, 65)
    Accent    = [System.Drawing.Color]::FromArgb(0, 255, 127) # SpringGreen
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "BACKUP & RESTORE CENTER PRO (V2.0)"
$Form.Size = New-Object System.Drawing.Size(800, 600)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back; $Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "DATA RESCUE CENTER"; $LblT.Font = "Impact, 20"; $LblT.ForeColor = $Theme.Accent; $LblT.AutoSize = $true; $LblT.Location = "20,10"
$Form.Controls.Add($LblT)

# --- TAB CONTROL ---
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = "20, 60"; $TabControl.Size = "745, 350"
$Form.Controls.Add($TabControl)

# Helper UI
function Add-Page ($Title) { $p=New-Object System.Windows.Forms.TabPage; $p.Text=$Title; $p.BackColor=$Theme.Card; $p.ForeColor=$Theme.Text; $TabControl.Controls.Add($p); return $p }
function Add-Chk ($P, $T, $X, $Y, $Tag) { $c=New-Object System.Windows.Forms.CheckBox; $c.Text=$T; $c.Location="$X,$Y"; $c.AutoSize=$true; $c.Tag=$Tag; $c.Font="Segoe UI, 10"; $P.Controls.Add($c); return $c }

# ==========================================
# TAB 1: BACKUP (SAO LƯU)
# ==========================================
$TabBackup = Add-Page "  1. BACKUP (SAO LƯU)  "

$LblB1 = New-Object System.Windows.Forms.Label; $LblB1.Text = "Nơi lưu trữ (Destination):"; $LblB1.Location = "20,20"; $LblB1.AutoSize = $true; $TabBackup.Controls.Add($LblB1)
$TxtDest = New-Object System.Windows.Forms.TextBox; $TxtDest.Location = "20,45"; $TxtDest.Size = "550,25"; $TabBackup.Controls.Add($TxtDest)
if(Test-Path "D:\"){$TxtDest.Text="D:\PhatTan_Backup"}else{$TxtDest.Text="C:\PhatTan_Backup"}

$BtnBrowseB = New-Object System.Windows.Forms.Button; $BtnBrowseB.Text="..."; $BtnBrowseB.Location="580,43"; $BtnBrowseB.Size="40,27"; $BtnBrowseB.FlatStyle="Flat"; $TabBackup.Controls.Add($BtnBrowseB)
$BtnBrowseB.Add_Click({ $F=New-Object System.Windows.Forms.FolderBrowserDialog; if($F.ShowDialog() -eq "OK"){$TxtDest.Text=$F.SelectedPath+"\PhatTan_Backup"} })

$GbItems = New-Object System.Windows.Forms.GroupBox; $GbItems.Text="Chọn dữ liệu cần Backup"; $GbItems.Location="20,90"; $GbItems.Size="690,150"; $GbItems.ForeColor="Cyan"; $TabBackup.Controls.Add($GbItems)

# Checkboxes Backup
$cB_Wifi = Add-Chk $GbItems "Wifi Passwords" 30 30 "Wifi"
$cB_Drv  = Add-Chk $GbItems "Drivers (Full)" 30 60 "Driver"
$cB_Lic  = Add-Chk $GbItems "Windows License" 30 90 "License"

$cB_Data = Add-Chk $GbItems "User Data (Desktop, Doc...)" 250 30 "UserData"
$cB_Zalo = Add-Chk $GbItems "Zalo PC Data" 250 60 "Zalo"
$cB_Fonts= Add-Chk $GbItems "Installed Fonts" 250 90 "Fonts"

$cB_Chrome = Add-Chk $GbItems "Chrome Profile" 500 30 "Chrome"
$cB_Edge   = Add-Chk $GbItems "Edge Profile" 500 60 "Edge"

$BtnRunBackup = New-Object System.Windows.Forms.Button; $BtnRunBackup.Text="CHẠY BACKUP NGAY"; $BtnRunBackup.Location="20,260"; $BtnRunBackup.Size="690,45"; $BtnRunBackup.BackColor="Green"; $BtnRunBackup.ForeColor="White"; $BtnRunBackup.FlatStyle="Flat"; $BtnRunBackup.Font="Segoe UI, 12, Bold"
$TabBackup.Controls.Add($BtnRunBackup)


# ==========================================
# TAB 2: RESTORE (KHÔI PHỤC)
# ==========================================
$TabRestore = Add-Page "  2. RESTORE (KHÔI PHỤC)  "

$LblR1 = New-Object System.Windows.Forms.Label; $LblR1.Text = "Chọn thư mục chứa Backup:"; $LblR1.Location = "20,20"; $LblR1.AutoSize = $true; $TabRestore.Controls.Add($LblR1)
$TxtSource = New-Object System.Windows.Forms.TextBox; $TxtSource.Location = "20,45"; $TxtSource.Size = "550,25"; $TabRestore.Controls.Add($TxtSource)

$BtnBrowseR = New-Object System.Windows.Forms.Button; $BtnBrowseR.Text="CHỌN..."; $BtnBrowseR.Location="580,43"; $BtnBrowseR.Size="80,27"; $BtnBrowseR.FlatStyle="Flat"; $TabRestore.Controls.Add($BtnBrowseR)
$BtnBrowseR.Add_Click({ $F=New-Object System.Windows.Forms.FolderBrowserDialog; if($F.ShowDialog() -eq "OK"){$TxtSource.Text=$F.SelectedPath} })

$GbResItems = New-Object System.Windows.Forms.GroupBox; $GbResItems.Text="Chọn mục cần Khôi phục"; $GbResItems.Location="20,90"; $GbResItems.Size="690,150"; $GbResItems.ForeColor="Orange"; $TabRestore.Controls.Add($GbResItems)

# Checkboxes Restore
$cR_Wifi = Add-Chk $GbResItems "Wifi Passwords" 30 30 "Wifi"
$cR_Drv  = Add-Chk $GbResItems "Install Drivers" 30 60 "Driver"
$cR_Lic  = Add-Chk $GbResItems "Restore License" 30 90 "License" # Risk

$cR_Data = Add-Chk $GbResItems "User Data (Ghi đè)" 250 30 "UserData"
$cR_Zalo = Add-Chk $GbResItems "Zalo PC (Ghi đè)" 250 60 "Zalo"
$cR_Fonts= Add-Chk $GbResItems "Install Fonts" 250 90 "Fonts"

$cR_Chrome = Add-Chk $GbResItems "Chrome Profile" 500 30 "Chrome"
$cR_Edge   = Add-Chk $GbResItems "Edge Profile" 500 60 "Edge"

$BtnRunRestore = New-Object System.Windows.Forms.Button; $BtnRunRestore.Text="TIẾN HÀNH KHÔI PHỤC (RESTORE)"; $BtnRunRestore.Location="20,260"; $BtnRunRestore.Size="690,45"; $BtnRunRestore.BackColor="Firebrick"; $BtnRunRestore.ForeColor="White"; $BtnRunRestore.FlatStyle="Flat"; $BtnRunRestore.Font="Segoe UI, 12, Bold"
$TabRestore.Controls.Add($BtnRunRestore)


# --- COMMON LOG AREA ---
$TxtLog = New-Object System.Windows.Forms.TextBox; $TxtLog.Multiline=$true; $TxtLog.Location="20,430"; $TxtLog.Size="745,110"; $TxtLog.BackColor="Black"; $TxtLog.ForeColor="Lime"; $TxtLog.ReadOnly=$true; $TxtLog.ScrollBars="Vertical"
$Form.Controls.Add($TxtLog)

function Log ($M) { $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm'))] $M`r`n"); $TxtLog.ScrollToCaret(); [System.Windows.Forms.Application]::DoEvents() }

# ==========================================
# LOGIC BACKUP
# ==========================================
function Robo-Copy ($Src, $Dst, $Name) {
    if (Test-Path $Src) {
        Log ">> Backup: $Name..."
        Start-Process "robocopy.exe" -ArgumentList "`"$Src`" `"$Dst`" /E /MT:16 /R:0 /W:0 /NFL /NDL" -NoNewWindow -Wait
    } else { Log "Skip: $Name (Not Found)" }
}

$BtnRunBackup.Add_Click({
    $Dst = "$($TxtDest.Text)\Backup_$(Get-Date -F 'ddMM_HHmm')"
    New-Item -ItemType Directory -Path $Dst -Force | Out-Null
    
    # 1. WIFI
    if ($cB_Wifi.Checked) { 
        Log "Exporting Wifi..."
        New-Item "$Dst\Wifi" -ItemType Directory -Force | Out-Null
        netsh wlan export profile key=clear folder="$Dst\Wifi" | Out-Null
    }
    # 2. DRIVER
    if ($cB_Drv.Checked) {
        Log "Exporting Drivers (DISM)..."
        New-Item "$Dst\Drivers" -ItemType Directory -Force | Out-Null
        Start-Process "dism.exe" "/online /export-driver /destination:`"$Dst\Drivers`"" -NoNewWindow -Wait
    }
    # 3. USER DATA
    if ($cB_Data.Checked) {
        $Folders = @("Desktop", "Documents", "Downloads", "Pictures", "Videos", "Music")
        foreach ($F in $Folders) { Robo-Copy "$env:USERPROFILE\$F" "$Dst\UserData\$F" $F }
    }
    # 4. ZALO
    if ($cB_Zalo.Checked) { Robo-Copy "$env:APPDATA\ZaloPC" "$Dst\Apps\ZaloPC" "ZaloPC" }
    # 5. CHROME/EDGE
    if ($cB_Chrome.Checked) { Robo-Copy "$env:LOCALAPPDATA\Google\Chrome\User Data" "$Dst\Apps\Chrome" "Chrome" }
    if ($cB_Edge.Checked) { Robo-Copy "$env:LOCALAPPDATA\Microsoft\Edge\User Data" "$Dst\Apps\Edge" "Edge" }
    
    Log "--- BACKUP COMPLETE ---"
    Invoke-Item $Dst
})

# ==========================================
# LOGIC RESTORE
# ==========================================
function Restore-Copy ($Src, $Dst, $Name) {
    if (Test-Path $Src) {
        Log ">> Restoring: $Name..."
        Start-Process "robocopy.exe" -ArgumentList "`"$Src`" `"$Dst`" /E /MT:16 /R:0 /W:0 /NFL /NDL" -NoNewWindow -Wait
    } else { Log "Skip: $Name (No Backup Found)" }
}

$BtnRunRestore.Add_Click({
    $Src = $TxtSource.Text
    if (!(Test-Path $Src)) { [System.Windows.Forms.MessageBox]::Show("Thu muc Backup khong ton tai!", "Loi"); return }
    
    if ([System.Windows.Forms.MessageBox]::Show("BAN CO CHAC MUON KHOI PHUC?`nDu lieu hien tai se bi ghi de!", "Canh bao", "YesNo", "Warning") -eq "No") { return }

    # 1. WIFI
    if ($cR_Wifi.Checked) {
        $WifiFiles = Get-ChildItem "$Src\Wifi\*.xml"
        if ($WifiFiles) {
            Log "Restoring Wifi..."
            foreach ($F in $WifiFiles) { netsh wlan add profile filename="$($F.FullName)" | Out-Null }
        }
    }
    # 2. DRIVER
    if ($cR_Drv.Checked) {
        if (Test-Path "$Src\Drivers") {
            Log "Installing Drivers (Pnputil)..."
            Start-Process "pnputil.exe" "/add-driver `"$Src\Drivers\*.inf`" /subdirs /install" -NoNewWindow -Wait
        }
    }
    # 3. ZALO (Kill process first)
    if ($cR_Zalo.Checked) {
        Stop-Process -Name "Zalo" -ErrorAction SilentlyContinue
        Restore-Copy "$Src\Apps\ZaloPC" "$env:APPDATA\ZaloPC" "ZaloData"
    }
    # 4. BROWSERS (Kill process)
    if ($cR_Chrome.Checked) {
        Stop-Process -Name "chrome" -ErrorAction SilentlyContinue
        Restore-Copy "$Src\Apps\Chrome" "$env:LOCALAPPDATA\Google\Chrome\User Data" "Chrome"
    }
    if ($cR_Edge.Checked) {
        Stop-Process -Name "msedge" -ErrorAction SilentlyContinue
        Restore-Copy "$Src\Apps\Edge" "$env:LOCALAPPDATA\Microsoft\Edge\User Data" "Edge"
    }
    # 5. USER DATA
    if ($cR_Data.Checked) {
        $Folders = @("Desktop", "Documents", "Downloads", "Pictures", "Videos", "Music")
        foreach ($F in $Folders) { Restore-Copy "$Src\UserData\$F" "$env:USERPROFILE\$F" $F }
    }

    Log "--- RESTORE COMPLETE ---"
    [System.Windows.Forms.MessageBox]::Show("Da khoi phuc xong! Vui long Restart may.", "Thanh Cong")
})

$Form.ShowDialog() | Out-Null
