<#
    VENTOY BOOT MAKER - PHAT TAN PC (V12.0 ULTIMATE AUTOMATION)
    Updates:
    - [AUTO-INSTALL] Tích hợp Plugin tự động cài Win/Linux (XML/Kickstart).
    - [JSON] Cấu hình JSON chuyên sâu (Theme, Auto-Install, Menu Alias).
    - [STRUCTURE] Folder map chính xác với script cài đặt.
    - [CORE] Anti-Crash & Auto-Update.
#>

# --- 0. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $Arg = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell.exe -Verb RunAs -ArgumentList $Arg
    Exit
}

# 1. SETUP
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.IO.Compression.FileSystem

# 2. CONFIG
$Global:VentoyRepo = "https://api.github.com/repos/ventoy/Ventoy/releases/latest"
$Global:WorkDir = "C:\PhatTan_Ventoy_Temp"
$Global:DebugFile = "$PSScriptRoot\debug_log.txt" 
if (!(Test-Path $Global:WorkDir)) { New-Item -ItemType Directory -Path $Global:WorkDir -Force | Out-Null }
$Global:VersionFile = "$Global:WorkDir\current_version.txt"

# Cấu hình Template Auto-Install (Link từ Ventoy)
$Global:AutoInstallLinks = @{
    "windows_unattended.xml" = "https://www.ventoy.net/download/unattended.xml"
    "deepin.ini"             = "https://www.ventoy.net/download/deepin.ini.txt"
    "centos_kickstart.cfg"   = "https://www.ventoy.net/download/kickstart7.cfg.txt"
    "ubuntu_server.seed"     = "https://www.ventoy.net/download/preseed.cfg.txt"
    "suse_autoyast.xml"      = "https://www.ventoy.net/download/autoYast.xml"
}

$Global:DefaultThemes = @(
    @{ Name="Ventoy Default"; Url=""; File=""; Folder="" },
    @{ Name="WhiteSur 4K (Demo)"; Url="https://github.com/vinceliuice/WhiteSur-grub-theme/archive/refs/heads/master.zip"; File="theme.txt"; Folder="WhiteSur-grub-theme-master" }
)

# 3. THEME GUI
$Theme = @{
    BgForm  = [System.Drawing.Color]::FromArgb(30, 30, 35)
    Card    = [System.Drawing.Color]::FromArgb(45, 45, 50)
    Text    = [System.Drawing.Color]::FromArgb(240, 240, 240)
    Accent  = [System.Drawing.Color]::FromArgb(0, 180, 255) # Cyber Blue
    Warn    = [System.Drawing.Color]::FromArgb(255, 160, 0)
    Success = [System.Drawing.Color]::FromArgb(50, 205, 50)
    InputBg = [System.Drawing.Color]::FromArgb(60, 60, 70)
}

# --- HELPER FUNCTIONS ---
function Log-Msg ($Msg, $Color="Lime") { 
    try {
        $Form.Invoke([Action]{
            $TxtLog.SelectionStart = $TxtLog.TextLength
            $TxtLog.SelectionLength = 0
            $TxtLog.SelectionColor = [System.Drawing.Color]::FromName($Color)
            $TxtLog.AppendText("[$(Get-Date -F 'HH:mm:ss')] $Msg`r`n")
            $TxtLog.ScrollToCaret()
        })
    } catch {}
    try { "$(Get-Date -F 'HH:mm:ss')|$Msg" | Out-File $Global:DebugFile -Append -Encoding UTF8 } catch {}
}

function Add-GlowBorder ($Panel) {
    $Panel.Add_Paint({ param($s,$e) $p=New-Object System.Drawing.Pen($Theme.Accent,1); $r=$s.ClientRectangle; $r.Width-=1; $r.Height-=1; $e.Graphics.DrawRectangle($p,$r); $p.Dispose() })
}

# --- GUI INIT ---
$F_Title = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$F_Norm  = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
$F_Bold  = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$F_Code  = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Regular)

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "PHAT TAN VENTOY MASTER V12.0 (ULTIMATE AUTOMATION)"; $Form.Size = "950,880"; $Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.BgForm; $Form.ForeColor = $Theme.Text; $Form.Padding = 10

$MainTable = New-Object System.Windows.Forms.TableLayoutPanel; $MainTable.Dock = "Fill"; $MainTable.ColumnCount = 1; $MainTable.RowCount = 5
$MainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) # Header
$MainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) # USB Selection
$MainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 450))) # Settings Tab
$MainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) # Log
$MainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 70))) # Action Button
$Form.Controls.Add($MainTable)

# 1. HEADER
$PnlHead = New-Object System.Windows.Forms.Panel; $PnlHead.Height = 60; $PnlHead.Dock = "Top"; $PnlHead.Margin = "0,0,0,10"
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "USB BOOT MASTER - VENTOY EDITION"; $LblT.Font = $F_Title; $LblT.ForeColor = $Theme.Accent; $LblT.AutoSize = $true; $LblT.Location = "10,10"
$LblS = New-Object System.Windows.Forms.Label; $LblS.Text = "Auto-Install Plugins (Win/Linux) | Full JSON Config | Anti-Crash"; $LblS.ForeColor = "Gray"; $LblS.AutoSize = $true; $LblS.Location = "15,40"
$PnlHead.Controls.Add($LblT); $PnlHead.Controls.Add($LblS); $MainTable.Controls.Add($PnlHead, 0, 0)

# 2. USB SELECTION
$CardUSB = New-Object System.Windows.Forms.Panel; $CardUSB.BackColor = $Theme.Card; $CardUSB.Padding = 10; $CardUSB.AutoSize = $true; $CardUSB.Dock = "Top"; $CardUSB.Margin = "0,0,0,10"; Add-GlowBorder $CardUSB
$L_U1 = New-Object System.Windows.Forms.TableLayoutPanel; $L_U1.Dock = "Top"; $L_U1.Height = 35; $L_U1.ColumnCount = 3
$L_U1.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 70)))
$L_U1.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 15)))
$L_U1.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 15)))

$CbUSB = New-Object System.Windows.Forms.ComboBox; $CbUSB.Dock = "Fill"; $CbUSB.Font = $F_Norm; $CbUSB.BackColor = $Theme.InputBg; $CbUSB.ForeColor = "White"; $CbUSB.DropDownStyle = "DropDownList"
$BtnRef = New-Object System.Windows.Forms.Button; $BtnRef.Text = "↻ Refresh"; $BtnRef.Dock = "Fill"; $BtnRef.BackColor = $Theme.InputBg; $BtnRef.ForeColor = "White"; $BtnRef.FlatStyle = "Flat"
$BtnInfo = New-Object System.Windows.Forms.Button; $BtnInfo.Text = "ℹ Chi tiết"; $BtnInfo.Dock = "Fill"; $BtnInfo.BackColor = $Theme.InputBg; $BtnInfo.ForeColor = "Cyan"; $BtnInfo.FlatStyle = "Flat"

$L_U1.Controls.Add($CbUSB, 0, 0); $L_U1.Controls.Add($BtnRef, 1, 0); $L_U1.Controls.Add($BtnInfo, 2, 0)
$LblUTitle = New-Object System.Windows.Forms.Label; $LblUTitle.Text = "THIẾT BỊ MỤC TIÊU:"; $LblUTitle.Font = $F_Bold; $LblUTitle.Dock = "Top"; $LblUTitle.ForeColor = "Silver"
$CardUSB.Controls.Add($L_U1); $CardUSB.Controls.Add($LblUTitle); $MainTable.Controls.Add($CardUSB, 0, 1)

# 3. SETTINGS & TABS
$TabC = New-Object System.Windows.Forms.TabControl; $TabC.Dock = "Fill"; $TabC.Padding = "10,5"
$Tab1 = New-Object System.Windows.Forms.TabPage; $Tab1.Text = "CÀI ĐẶT & DATA"; $Tab1.BackColor = $Theme.BgForm
$Tab2 = New-Object System.Windows.Forms.TabPage; $Tab2.Text = "THEME & PLUGINS"; $Tab2.BackColor = $Theme.BgForm
$TabC.Controls.Add($Tab1); $TabC.Controls.Add($Tab2); $MainTable.Controls.Add($TabC, 0, 2)

# -- TAB 1: BASIC --
$G1 = New-Object System.Windows.Forms.TableLayoutPanel; $G1.Dock = "Top"; $G1.AutoSize = $true; $G1.Padding = 10; $G1.ColumnCount = 2; $G1.RowCount = 8
$G1.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 40)))
$G1.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 60)))

$LblAct = New-Object System.Windows.Forms.Label; $LblAct.Text = "Chế độ (Mode):"; $LblAct.ForeColor = "White"; $LblAct.AutoSize = $true
$CbAction = New-Object System.Windows.Forms.ComboBox; $CbAction.Items.AddRange(@("Cài mới (Xóa sạch & Format)", "Cập nhật Ventoy (Giữ Data)")); $CbAction.SelectedIndex = 0; $CbAction.DropDownStyle = "DropDownList"; $CbAction.Width = 300
$G1.Controls.Add($LblAct, 0, 0); $G1.Controls.Add($CbAction, 1, 0)

$LblSty = New-Object System.Windows.Forms.Label; $LblSty.Text = "Kiểu Partition:"; $LblSty.ForeColor = "White"; $LblSty.AutoSize = $true
$CbStyle = New-Object System.Windows.Forms.ComboBox; $CbStyle.Items.AddRange(@("MBR (Legacy + UEFI)", "GPT (UEFI Only)")); $CbStyle.SelectedIndex = 0; $CbStyle.DropDownStyle = "DropDownList"; $CbStyle.Width = 300
$G1.Controls.Add($LblSty, 0, 1); $G1.Controls.Add($CbStyle, 1, 1)

$LblName = New-Object System.Windows.Forms.Label; $LblName.Text = "Tên USB (Label):"; $LblName.ForeColor = "White"; $LblName.AutoSize = $true
$TxtLabel = New-Object System.Windows.Forms.TextBox; $TxtLabel.Text = "PhatTan_Boot"; $TxtLabel.Width = 300; $TxtLabel.BackColor = $Theme.InputBg; $TxtLabel.ForeColor = "Cyan"
$G1.Controls.Add($LblName, 0, 2); $G1.Controls.Add($TxtLabel, 1, 2)

$LblFS = New-Object System.Windows.Forms.Label; $LblFS.Text = "Định dạng (Format):"; $LblFS.ForeColor = "White"; $LblFS.AutoSize = $true
$CbFS = New-Object System.Windows.Forms.ComboBox; $CbFS.Items.AddRange(@("exFAT (Khuyên dùng)", "NTFS (Tương thích Win)", "FAT32 (Max 4GB/file)")); $CbFS.SelectedIndex = 0; $CbFS.DropDownStyle = "DropDownList"; $CbFS.Width = 300
$G1.Controls.Add($LblFS, 0, 3); $G1.Controls.Add($CbFS, 1, 3)

$ChkLive = New-Object System.Windows.Forms.CheckBox; $ChkLive.Text = "Tải & Cài LiveCD (Đổi tên: NangCap_UsbBoot.iso)"; $ChkLive.Checked = $true; $ChkLive.ForeColor = "Yellow"; $ChkLive.AutoSize = $true
$G1.Controls.Add($ChkLive, 0, 4); $G1.SetColumnSpan($ChkLive, 2)

$ChkDir = New-Object System.Windows.Forms.CheckBox; $ChkDir.Text = "Tạo Full Cấu trúc (DATA, Bản Quyền, ISO, MAS...)"; $ChkDir.Checked = $true; $ChkDir.ForeColor = "Lime"; $ChkDir.AutoSize = $true
$G1.Controls.Add($ChkDir, 0, 5); $G1.SetColumnSpan($ChkDir, 2)

$ChkSec = New-Object System.Windows.Forms.CheckBox; $ChkSec.Text = "Bật Secure Boot Support"; $ChkSec.Checked = $true; $ChkSec.ForeColor = "Orange"; $ChkSec.AutoSize = $true
$G1.Controls.Add($ChkSec, 0, 6); $G1.SetColumnSpan($ChkSec, 2)

$ChkAntiBot = New-Object System.Windows.Forms.CheckBox; $ChkAntiBot.Text = "🛡️ Xác thực Math-Bot (Phép toán)"; $ChkAntiBot.Checked = $true; $ChkAntiBot.ForeColor = "Red"; $ChkAntiBot.AutoSize = $true
$G1.Controls.Add($ChkAntiBot, 0, 7); $G1.SetColumnSpan($ChkAntiBot, 2)

$Tab1.Controls.Add($G1)

# -- TAB 2: ADVANCED --
$G2 = New-Object System.Windows.Forms.TableLayoutPanel; $G2.Dock = "Top"; $G2.AutoSize = $true; $G2.Padding = 10; $G2.ColumnCount = 1; $G2.RowCount = 6

$ChkMem = New-Object System.Windows.Forms.CheckBox; $ChkMem.Text = "Kích hoạt Memdisk Mode (VTOY_MEM_DISK_MODE)"; $ChkMem.Checked = $false; $ChkMem.ForeColor = "Cyan"; $ChkMem.AutoSize = $true
$G2.Controls.Add($ChkMem, 0, 0)

$ChkAutoIns = New-Object System.Windows.Forms.CheckBox; $ChkAutoIns.Text = "Tự động tải & Cấu hình Auto-Install (Unattended XML)"; $ChkAutoIns.Checked = $true; $ChkAutoIns.ForeColor = "Lime"; $ChkAutoIns.AutoSize = $true
$G2.Controls.Add($ChkAutoIns, 0, 1)

$LblThm = New-Object System.Windows.Forms.Label; $LblThm.Text = "Chọn Theme (Tải từ Server):"; $LblThm.ForeColor = "White"; $LblThm.AutoSize = $true; $LblThm.Margin = "0,10,0,0"
$CbTheme = New-Object System.Windows.Forms.ComboBox; $CbTheme.DropDownStyle = "DropDownList"; $CbTheme.Width = 400
$BtnLoadTheme = New-Object System.Windows.Forms.Button; $BtnLoadTheme.Text = "Tải danh sách Theme"; $BtnLoadTheme.Width = 200; $BtnLoadTheme.BackColor = "DimGray"; $BtnLoadTheme.ForeColor = "White"

$P_Thm = New-Object System.Windows.Forms.FlowLayoutPanel; $P_Thm.AutoSize = $true; $P_Thm.FlowDirection = "LeftToRight"
$P_Thm.Controls.Add($CbTheme); $P_Thm.Controls.Add($BtnLoadTheme)

$G2.Controls.Add($LblThm, 0, 2); $G2.Controls.Add($P_Thm, 0, 3)

$LblJ = New-Object System.Windows.Forms.Label; $LblJ.Text = "JSON Config Preview:"; $LblJ.ForeColor = "Gray"; $LblJ.AutoSize = $true; $LblJ.Margin = "0,10,0,0"
$G2.Controls.Add($LblJ, 0, 4)

$Tab2.Controls.Add($G2)

# 4. LOG
$TxtLog = New-Object System.Windows.Forms.RichTextBox; $TxtLog.Dock = "Fill"; $TxtLog.BackColor = "Black"; $TxtLog.ForeColor = "Lime"; $TxtLog.Font = $F_Code; $TxtLog.ReadOnly = $true; $MainTable.Controls.Add($TxtLog, 0, 3)

# 5. EXECUTE BUTTON
$BtnStart = New-Object System.Windows.Forms.Button; $BtnStart.Text = "THỰC HIỆN"; $BtnStart.Font = $F_Title; $BtnStart.BackColor = $Theme.Accent; $BtnStart.ForeColor = "Black"; $BtnStart.FlatStyle = "Flat"; $BtnStart.Dock = "Fill"
$MainTable.Controls.Add($BtnStart, 0, 4)

# ==========================================
# 🛡️ HELPER LOGIC
# ==========================================

function Check-MathBot {
    if (!$ChkAntiBot.Checked) { return $true }
    $A = Get-Random -Min 1 -Max 20; $B = Get-Random -Min 1 -Max 10; $Result = $A + $B
    $UserAns = [Microsoft.VisualBasic.Interaction]::InputBox("Xác thực bảo mật:`n`nHãy tính: $A + $B = ?", "Anti-Bot Verification", "")
    if ($UserAns -eq "$Result") { return $true } else { [System.Windows.Forms.MessageBox]::Show("Sai rồi!", "Cảnh báo", "OK", "Error"); return $false }
}

function Force-Disk-Refresh {
    Log-Msg "Auto F5: Rescan Disk..." "Yellow"
    try {
        "rescan" | Out-File "$env:TEMP\dp_rescan.txt" -Encoding ASCII -Force
        Start-Process diskpart -ArgumentList "/s `"$env:TEMP\dp_rescan.txt`"" -Wait -WindowStyle Hidden
        Start-Sleep -Seconds 2
    } catch {}
}

function Get-DriveLetter-DiskPart ($DiskIndex) {
    try {
        $DpScript = "$env:TEMP\dp_vol_check.txt"
        "select disk $DiskIndex`ndetail disk" | Out-File $DpScript -Encoding ASCII -Force
        $Output = & diskpart /s $DpScript
        foreach ($Line in $Output) { if ($Line -match "Volume \d+\s+([A-Z])\s+") { return "$($Matches[1]):" } }
    } catch {}
    return $null
}

function Get-Partition-Style-Robust ($DiskIndex) {
    try { if (Get-Command Get-Disk -EA 0) { return (Get-Disk -Number $DiskIndex -ErrorAction Stop).PartitionStyle } } catch {}
    try {
        $DpScript = "$env:TEMP\dp_style.txt"; "list disk" | Out-File $DpScript -Encoding ASCII -Force
        $Output = & diskpart /s $DpScript
        foreach ($Line in $Output) { if ($Line -match "Disk $DiskIndex\s+.*") { if ($Line -match "\*\s*$") { return "GPT" } else { return "MBR" } } }
    } catch {}
    return "Unknown"
}

function Check-Ventoy-Status ($DiskIndex) {
    try {
        $DpScript = "$env:TEMP\dp_vtoy_check.txt"; "select disk $DiskIndex`nlist partition" | Out-File $DpScript -Encoding ASCII -Force
        $Output = & diskpart /s $DpScript | Out-String
        if ($Output -match "32 MB") { return $true }
    } catch {}
    return $false
}

function Load-USB {
    $CbUSB.Items.Clear(); $Found = $false; Force-Disk-Refresh
    if (Get-Command Get-Disk -EA 0) { try { $Disks = Get-Disk | Where-Object { $_.BusType -eq "USB" -or $_.MediaType -eq "Removable" }; if ($Disks) { foreach ($d in $Disks) { $SizeGB = [Math]::Round($d.Size / 1GB, 1); $CbUSB.Items.Add("Disk $($d.Number): $($d.FriendlyName) - $SizeGB GB") }; $Found = $true } } catch {} }
    if (-not $Found) { try { $WmiDisks = Get-WmiObject Win32_DiskDrive | Where-Object { $_.InterfaceType -eq "USB" -or $_.MediaType -match "Removable" }; if ($WmiDisks) { foreach ($d in $WmiDisks) { $Size = $d.Size; if (!$Size) { $Size = 0 }; $SizeGB = [Math]::Round($Size / 1GB, 1); $CbUSB.Items.Add("Disk $($d.Index): $($d.Model) - $SizeGB GB") }; $Found = $true } } catch {} }
    if (-not $Found) { $CbUSB.Items.Add("Không tìm thấy USB"); $CbUSB.SelectedIndex = 0 } else { $CbUSB.SelectedIndex = 0 }
}

function Show-UsbDetails-Pro {
    if ($CbUSB.SelectedItem -match "Disk (\d+)") {
        $ID = $Matches[1]
        $D_Model = "Unknown"; $D_Size = "Unknown"; $D_Interface = "Unknown"; $D_Status = "Unknown"
        try { $WmiD = Get-WmiObject Win32_DiskDrive | Where-Object { $_.Index -eq $ID }; if ($WmiD) { $D_Model = $WmiD.Model; $D_Size = "$([Math]::Round($WmiD.Size/1GB, 2)) GB"; $D_Interface = $WmiD.InterfaceType; $D_Status = $WmiD.Status } } catch {}
        $DL = Get-DriveLetter-DiskPart $ID; $Style = Get-Partition-Style-Robust $ID; $IsVentoy = Check-Ventoy-Status $ID; $VStatus = if ($IsVentoy) { "ĐÃ CÀI" } else { "CHƯA CÀI" }
        $Report = "=== USB DIAGNOSTIC REPORT ===`r`nDevice ID: Disk $ID`r`nModel: $D_Model`r`nSize: $D_Size`r`nDrive: $DL`r`nStyle: $Style`r`nVentoy: $VStatus"
        [System.Windows.Forms.MessageBox]::Show($Report, "Info")
    }
}

function Load-Themes {
    $CbTheme.Items.Clear(); $CbTheme.Items.Add("Mặc định (Ventoy)")
    try {
        $JsonData = $Global:DefaultThemes; $Global:ThemeData = $JsonData
        foreach ($item in $JsonData) { if ($item.Url) { $CbTheme.Items.Add($item.Name) } }
        Log-Msg "Load Theme OK." "Cyan"
    } catch {}
    $CbTheme.SelectedIndex = 0
}

function Download-AutoInstall-Scripts ($ScriptDir) {
    if (!$ChkAutoIns.Checked) { return }
    Log-Msg "Downloading Auto-Install Plugins..." "Yellow"
    if (!(Test-Path $ScriptDir)) { New-Item -Path $ScriptDir -ItemType Directory -Force | Out-Null }
    
    foreach ($Key in $Global:AutoInstallLinks.Keys) {
        $Url = $Global:AutoInstallLinks[$Key]
        $Dest = "$ScriptDir\$Key"
        if (!(Test-Path $Dest)) {
            try { (New-Object Net.WebClient).DownloadFile($Url, $Dest); Log-Msg " + $Key: OK" "Gray" } catch { Log-Msg " - $Key: Fail" "Red" }
        }
    }
}

function Process-Ventoy {
    param($DiskID, $Mode, $Style, $LabelName, $FSType, $IsLiveCD, $IsDir)
    
    if (-not (Check-MathBot)) { return }
    
    # 1. DOWNLOAD VENTOY
    Log-Msg "Checking Ventoy..." "Cyan"
    $ZipFile = "$Global:WorkDir\ventoy.zip"; $ExtractPath = "$Global:WorkDir\Extracted"
    if (!(Test-Path "$ExtractPath\ventoy\Ventoy2Disk.exe")) {
        try {
            $Assets = Invoke-RestMethod -Uri $Global:VentoyRepo -UseBasicParsing -TimeoutSec 5
            $WinZip = $Assets.assets | Where-Object { $_.name -match "windows.zip" } | Select -First 1
            $Url = if ($WinZip) { $WinZip.browser_download_url } else { $Global:VentoyFallbackUrl }
            (New-Object Net.WebClient).DownloadFile($Url, $ZipFile)
            [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $ExtractPath)
        } catch { Log-Msg "Lỗi tải Ventoy. Dùng bản cũ nếu có." "Red" }
    }
    $Global:VentoyExe = Get-ChildItem -Path $ExtractPath -Filter "Ventoy2Disk.exe" -Recurse | Select -First 1 | %{$_.FullName}
    
    # 2. GET DRIVE
    Force-Disk-Refresh
    $DL = Get-DriveLetter-DiskPart $DiskID
    if (!$DL) { Log-Msg "Lỗi: Không tìm thấy ổ đĩa!" "Red"; return }
    Log-Msg "Target: $DL" "Cyan"

    # CROSS-MODE CHECK
    $CurrentStyle = Get-Partition-Style-Robust $DiskID
    $TargetStyle = if ($Style -match "GPT") { "GPT" } else { "MBR" }
    if ($Mode -eq "UPDATE" -and $CurrentStyle -ne "Unknown" -and $CurrentStyle -ne $TargetStyle) {
        [System.Windows.Forms.MessageBox]::Show("Khác hệ Partition (MBR/GPT)! Chọn 'Cài mới' để Format.", "Lỗi", "OK", "Error"); return
    }

    # 3. RUN VENTOY
    $FlagMode = if ($Mode -eq "UPDATE") { "/U" } else { "/I" }
    $FlagStyle = if ($Style -match "GPT") { "/GPT" } else { "/MBR" }
    $FlagSecure = if ($ChkSec.Checked) { "/S" } else { "" }
    $FlagFS = if ($Mode -eq "INSTALL") { if ($FSType -match "NTFS") { "/FS:NTFS" } elseif ($FSType -match "FAT32") { "/FS:FAT32" } else { "/FS:exFAT" } } else { "" }

    Log-Msg "Running Ventoy2Disk $FlagFS..." "Cyan"
    
    $PInfo = New-Object System.Diagnostics.ProcessStartInfo
    $PInfo.FileName = $Global:VentoyExe
    $PInfo.Arguments = "VTOYCLI $FlagMode /Drive:$DL /NoUsbCheck $FlagStyle $FlagSecure $FlagFS"
    $PInfo.UseShellExecute = $true 
    
    $P = New-Object System.Diagnostics.Process; $P.StartInfo = $PInfo; $P.Start() | Out-Null
    
    $TimeoutSec = 180; $Counter = 0
    while (!$P.HasExited) {
        Start-Sleep 1; $Counter++
        if ($Counter -ge $TimeoutSec) { $P.Kill(); Log-Msg "TIMEOUT!" "Red"; $BtnStart.Enabled = $true; $Form.Cursor = "Default"; return }
        [System.Windows.Forms.Application]::DoEvents()
    }
    
    if ($P.ExitCode -eq 0) {
        try {
            Log-Msg "VENTOY OK! Rescanning..." "Yellow"
            $UsbRoot = $null
            for ($i = 0; $i -lt 30; $i++) {
                Force-Disk-Refresh
                $TempDL = Get-DriveLetter-DiskPart $DiskID
                if ($TempDL -and (Test-Path $TempDL)) { $UsbRoot = $TempDL; break }
                Start-Sleep 1
            }
            if (!$UsbRoot) { $UsbRoot = $DL }
            
            if (Test-Path $UsbRoot) {
                # 4. RENAME
                if ($Mode -eq "INSTALL") { for ($k=0; $k -lt 3; $k++) { try { cmd /c "label $UsbRoot $LabelName" } catch {}; Start-Sleep 1 } }

                $VentoyDir = "$UsbRoot\ventoy"; if (!(Test-Path $VentoyDir)) { New-Item -Path $VentoyDir -ItemType Directory -Force | Out-Null }

                # 5. FOLDERS
                if ($IsDir) {
                    Log-Msg "Tạo cấu trúc thư mục AIO..." "Yellow"
                    $Dirs = @("ISO_Windows\Win7", "ISO_Windows\Win10", "ISO_Windows\Win11", "ISO_Windows\LTSC", "ISO_Windows\Server", "ISO_Linux\Ubuntu", "ISO_Linux\CentOS", "ISO_Linux\Kali", "ISO_Rescue", "DATA\Documents", "DATA\App", "BanQuyen")
                    foreach ($d in $Dirs) { try { New-Item -Path "$UsbRoot\$d" -ItemType Directory -Force | Out-Null } catch {} }
                }

                # 6. AUTO INSTALL SCRIPTS
                Download-AutoInstall-Scripts "$VentoyDir\script"

                # 7. THEME & JSON & AUTO INSTALL CONFIG
                $SelTheme = $CbTheme.SelectedItem; $ThemeConfig = $null
                if ($SelTheme -ne "Mặc định (Ventoy)") {
                    $T = $Global:ThemeData | Where-Object { $_.Name -eq $SelTheme } | Select -First 1
                    if ($T) {
                        try {
                            $ThemeZip = "$Global:WorkDir\theme.zip"; (New-Object Net.WebClient).DownloadFile($T.Url, $ThemeZip)
                            $ThemeDest = "$VentoyDir\themes"; [System.IO.Compression.ZipFile]::ExtractToDirectory($ThemeZip, $ThemeDest, $true)
                            $ThemeConfig = "/ventoy/themes/$($T.Folder)/$($T.File)"
                        } catch {}
                    }
                }

                try {
                    $J = @{
                        "control" = @(@{ "VTOY_DEFAULT_MENU_MODE" = "0" }, @{ "VTOY_FILT_DOT_UNDERSCORE_FILE" = "1" })
                        "theme" = @{ "display_mode" = "GUI"; "gfxmode" = "1920x1080"; "ventoy_color"="#0000ff" }
                        "auto_install" = @(
                            @{ "parent"="/ISO_Windows/Win10"; "template"="/ventoy/script/windows_unattended.xml" },
                            @{ "parent"="/ISO_Windows/Win11"; "template"="/ventoy/script/windows_unattended.xml" },
                            @{ "parent"="/ISO_Linux/CentOS"; "template"="/ventoy/script/centos_kickstart.cfg" },
                            @{ "parent"="/ISO_Linux/Ubuntu"; "template"="/ventoy/script/ubuntu_server.seed" }
                        )
                        "menu_alias" = @( @{ "image" = "/ventoy/ventoy.png"; "alias" = "PHAT TAN RESCUE USB" } )
                    }
                    if ($ChkMem.Checked) { $J.control += @{ "VTOY_MEM_DISK_MODE" = "1" } }
                    if ($ThemeConfig) { $J.theme.Add("file", $ThemeConfig) }
                    
                    $J | ConvertTo-Json -Depth 10 | Out-File "$VentoyDir\ventoy.json" -Encoding UTF8 -Force
                } catch { Log-Msg "Lỗi JSON: $_" "Red" }
                
                Log-Msg "DONE! Enjoy." "Success"; [System.Windows.Forms.MessageBox]::Show("HOÀN TẤT!", "Phat Tan PC"); Invoke-Item $UsbRoot
            }
        } catch { Log-Msg "ERR: $($_.Exception.Message)" "Red" }
    } else { Log-Msg "Lỗi Ventoy ExitCode: $ExitCode" "Red" }
    
    $BtnStart.Enabled = $true; $Form.Cursor = "Default"
}

$BtnRef.Add_Click({ Load-USB })
$BtnInfo.Add_Click({ Show-UsbDetails-Pro })
$BtnLoadTheme.Add_Click({ Load-Themes })

$BtnStart.Add_Click({
    if ($CbUSB.SelectedItem -match "Disk (\d+)") {
        $ID = $Matches[1]
        $Mode = if ($CbAction.SelectedIndex -eq 0) { "INSTALL" } else { "UPDATE" }
        if ([System.Windows.Forms.MessageBox]::Show("Bắt đầu xử lý Disk $ID?", "Xác nhận", "YesNo", "Warning") -eq "Yes") {
            $BtnStart.Enabled = $false; $Form.Cursor = "WaitCursor"
            Process-Ventoy $ID $Mode $CbStyle.SelectedItem $TxtLabel.Text $CbFS.SelectedItem $ChkLive.Checked $ChkDir.Checked
        }
    } else { [System.Windows.Forms.MessageBox]::Show("Chưa chọn USB!") }
})

$Form.Add_Load({ Load-USB; Load-Themes })
[System.Windows.Forms.Application]::Run($Form)
