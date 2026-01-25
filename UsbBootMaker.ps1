<#
    VENTOY BOOT MAKER - PHAT TAN PC (V7.1 STABLE FIX)
    Updates:
    - [CRASH FIX] Bọc Try/Catch toàn bộ thao tác sau cài đặt để chống văng App.
    - [WAIT] Tăng thời gian chờ USB mount lại sau khi Format.
    - [AIO] Giữ nguyên tính năng tự tạo thư mục và tải LiveCD.
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
Add-Type -AssemblyName System.IO.Compression.FileSystem

# 2. CONFIG
$Global:VentoyRepo = "https://api.github.com/repos/ventoy/Ventoy/releases/latest"
$Global:ThemeJsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/themes_ventoy.json" 
$Global:WorkDir = "C:\PhatTan_Ventoy_Temp"
if (!(Test-Path $Global:WorkDir)) { New-Item -ItemType Directory -Path $Global:WorkDir -Force | Out-Null }
$Global:VersionFile = "$Global:WorkDir\current_version.txt"

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
$Form.Text = "PHAT TAN VENTOY MASTER V7.1 (STABLE FIX)"; $Form.Size = "950,850"; $Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.BgForm; $Form.ForeColor = $Theme.Text; $Form.Padding = 10

$MainTable = New-Object System.Windows.Forms.TableLayoutPanel; $MainTable.Dock = "Fill"; $MainTable.ColumnCount = 1; $MainTable.RowCount = 5
$MainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) # Header
$MainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) # USB Selection
$MainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 380))) # Settings Tab
$MainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) # Log
$MainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 70))) # Action Button
$Form.Controls.Add($MainTable)

# 1. HEADER
$PnlHead = New-Object System.Windows.Forms.Panel; $PnlHead.Height = 60; $PnlHead.Dock = "Top"; $PnlHead.Margin = "0,0,0,10"
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "USB BOOT MASTER - VENTOY EDITION"; $LblT.Font = $F_Title; $LblT.ForeColor = $Theme.Accent; $LblT.AutoSize = $true; $LblT.Location = "10,10"
$LblS = New-Object System.Windows.Forms.Label; $LblS.Text = "Anti-Crash Fix | Auto ISO Folder | Download LiveCD"; $LblS.ForeColor = "Gray"; $LblS.AutoSize = $true; $LblS.Location = "15,40"
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
$Tab2 = New-Object System.Windows.Forms.TabPage; $Tab2.Text = "THEME & JSON"; $Tab2.BackColor = $Theme.BgForm
$TabC.Controls.Add($Tab1); $TabC.Controls.Add($Tab2); $MainTable.Controls.Add($TabC, 0, 2)

# -- TAB 1: BASIC --
$G1 = New-Object System.Windows.Forms.TableLayoutPanel; $G1.Dock = "Top"; $G1.AutoSize = $true; $G1.Padding = 10; $G1.ColumnCount = 2; $G1.RowCount = 7
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

$ChkLive = New-Object System.Windows.Forms.CheckBox; $ChkLive.Text = "Tải & Cài Ventoy LiveCD ISO (Newest)"; $ChkLive.Checked = $true; $ChkLive.ForeColor = "Yellow"; $ChkLive.AutoSize = $true
$G1.Controls.Add($ChkLive, 0, 4); $G1.SetColumnSpan($ChkLive, 2)

$ChkDir = New-Object System.Windows.Forms.CheckBox; $ChkDir.Text = "Tạo bộ lọc thư mục (Windows/Linux/Rescue...)"; $ChkDir.Checked = $true; $ChkDir.ForeColor = "Lime"; $ChkDir.AutoSize = $true
$G1.Controls.Add($ChkDir, 0, 5); $G1.SetColumnSpan($ChkDir, 2)

$ChkSec = New-Object System.Windows.Forms.CheckBox; $ChkSec.Text = "Bật Secure Boot Support"; $ChkSec.Checked = $true; $ChkSec.ForeColor = "Orange"; $ChkSec.AutoSize = $true
$G1.Controls.Add($ChkSec, 0, 6); $G1.SetColumnSpan($ChkSec, 2)

$Tab1.Controls.Add($G1)

# -- TAB 2: ADVANCED --
$G2 = New-Object System.Windows.Forms.TableLayoutPanel; $G2.Dock = "Top"; $G2.AutoSize = $true; $G2.Padding = 10; $G2.ColumnCount = 1; $G2.RowCount = 6

$ChkMem = New-Object System.Windows.Forms.CheckBox; $ChkMem.Text = "Kích hoạt Memdisk Mode (VTOY_MEM_DISK_MODE)"; $ChkMem.Checked = $false; $ChkMem.ForeColor = "Cyan"; $ChkMem.AutoSize = $true
$G2.Controls.Add($ChkMem, 0, 0)

$LblThm = New-Object System.Windows.Forms.Label; $LblThm.Text = "Chọn Theme (Tải từ Server):"; $LblThm.ForeColor = "White"; $LblThm.AutoSize = $true; $LblThm.Margin = "0,10,0,0"
$CbTheme = New-Object System.Windows.Forms.ComboBox; $CbTheme.DropDownStyle = "DropDownList"; $CbTheme.Width = 400
$BtnLoadTheme = New-Object System.Windows.Forms.Button; $BtnLoadTheme.Text = "Tải danh sách Theme"; $BtnLoadTheme.Width = 200; $BtnLoadTheme.BackColor = "DimGray"; $BtnLoadTheme.ForeColor = "White"

$P_Thm = New-Object System.Windows.Forms.FlowLayoutPanel; $P_Thm.AutoSize = $true; $P_Thm.FlowDirection = "LeftToRight"
$P_Thm.Controls.Add($CbTheme); $P_Thm.Controls.Add($BtnLoadTheme)

$G2.Controls.Add($LblThm, 0, 1); $G2.Controls.Add($P_Thm, 0, 2)

$LblJ = New-Object System.Windows.Forms.Label; $LblJ.Text = "JSON Config Preview:"; $LblJ.ForeColor = "Gray"; $LblJ.AutoSize = $true; $LblJ.Margin = "0,10,0,0"
$G2.Controls.Add($LblJ, 0, 3)

$Tab2.Controls.Add($G2)

# 4. LOG
$TxtLog = New-Object System.Windows.Forms.RichTextBox; $TxtLog.Dock = "Fill"; $TxtLog.BackColor = "Black"; $TxtLog.ForeColor = "Lime"; $TxtLog.Font = $F_Code; $TxtLog.ReadOnly = $true; $MainTable.Controls.Add($TxtLog, 0, 3)

# 5. EXECUTE BUTTON
$BtnStart = New-Object System.Windows.Forms.Button; $BtnStart.Text = "THỰC HIỆN"; $BtnStart.Font = $F_Title; $BtnStart.BackColor = $Theme.Accent; $BtnStart.ForeColor = "Black"; $BtnStart.FlatStyle = "Flat"; $BtnStart.Dock = "Fill"
$MainTable.Controls.Add($BtnStart, 0, 4)

# ==========================================
# ⚡ CORE LOGIC
# ==========================================

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

function Get-DriveLetter-WMI ($DiskIndex) {
    try {
        $EscapedIndex = "\\\\.\\PHYSICALDRIVE$DiskIndex"
        $Query = "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$EscapedIndex'} WHERE AssocClass=Win32_DiskDriveToDiskPartition"
        $Partitions = Get-WmiObject -Query $Query -ErrorAction SilentlyContinue
        foreach ($Part in $Partitions) {
            $Query2 = "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($Part.DeviceID)'} WHERE AssocClass=Win32_LogicalDiskToPartition"
            $LogDisk = Get-WmiObject -Query $Query2 -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($LogDisk.DeviceID) { return $LogDisk.DeviceID }
        }
    } catch {}
    return $null
}

function Load-USB {
    $CbUSB.Items.Clear(); $Found = $false; Force-Disk-Refresh
    if (Get-Command Get-Disk -ErrorAction SilentlyContinue) {
        try {
            $Disks = Get-Disk | Where-Object { $_.BusType -eq "USB" -or $_.MediaType -eq "Removable" }
            if ($Disks) {
                foreach ($d in $Disks) { $SizeGB = [Math]::Round($d.Size / 1GB, 1); $CbUSB.Items.Add("Disk $($d.Number): $($d.FriendlyName) - $SizeGB GB") }
                $Found = $true
            }
        } catch { Log-Msg "Get-Disk fail..." "Warn" }
    }
    if (-not $Found) {
        try {
            $WmiDisks = Get-WmiObject Win32_DiskDrive | Where-Object { $_.InterfaceType -eq "USB" -or $_.MediaType -match "Removable" }
            if ($WmiDisks) {
                foreach ($d in $WmiDisks) { $Size = $d.Size; if (!$Size) { $Size = 0 }; $SizeGB = [Math]::Round($Size / 1GB, 1); $CbUSB.Items.Add("Disk $($d.Index): $($d.Model) - $SizeGB GB") }
                $Found = $true
                Log-Msg "Mode: WMI (Win Lite)." "Cyan"
            }
        } catch {}
    }
    if (-not $Found) { $CbUSB.Items.Add("Không tìm thấy USB"); $CbUSB.SelectedIndex = 0 } else { $CbUSB.SelectedIndex = 0 }
}

function Show-UsbDetails {
    if ($CbUSB.SelectedItem -match "Disk (\d+)") {
        $ID = $Matches[1]
        try {
            $D = Get-WmiObject Win32_DiskDrive | Where-Object { $_.Index -eq $ID }
            $DL = Get-DriveLetter-DiskPart $ID
            $Msg = "Model: $($D.Model)`nSize: $([Math]::Round($D.Size/1GB, 2)) GB`nDrive Letter: $DL"
            [System.Windows.Forms.MessageBox]::Show($Msg, "Chi tiết")
        } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi đọc info", "Lỗi") }
    }
}

function Get-Latest-Assets {
    Log-Msg "Checking Updates..." "Yellow"
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $ApiUrl = "https://api.github.com/repos/ventoy/Ventoy/releases/latest"
        $Response = Invoke-RestMethod -Uri $ApiUrl -UseBasicParsing -TimeoutSec 10
        
        $WinZip = $Response.assets | Where-Object { $_.name -match "windows.zip" } | Select-Object -First 1
        $LiveIso = $Response.assets | Where-Object { $_.name -match "livecd.iso" } | Select-Object -First 1
        
        return @{ Version=$Response.tag_name; WinUrl=$WinZip.browser_download_url; LiveUrl=$LiveIso.browser_download_url }
    } catch { return $null }
}

function Load-Themes {
    $CbTheme.Items.Clear(); $CbTheme.Items.Add("Mặc định (Ventoy)")
    try {
        $JsonData = $Global:DefaultThemes 
        $Global:ThemeData = $JsonData
        foreach ($item in $JsonData) { if ($item.Url) { $CbTheme.Items.Add($item.Name) } }
        Log-Msg "Load Theme OK." "Cyan"
    } catch {}
    $CbTheme.SelectedIndex = 0
}

function Process-Ventoy {
    param($DiskID, $Mode, $Style, $LabelName, $FSType, $IsLiveCD, $IsDir)
    
    # 1. GET ASSETS
    $Assets = Get-Latest-Assets
    if (!$Assets) { Log-Msg "Không kết nối được GitHub! Kiểm tra mạng." "Red"; return }
    
    Log-Msg "Version: $($Assets.Version)" "Cyan"
    
    # Download Ventoy Zip
    $ZipFile = "$Global:WorkDir\ventoy.zip"
    $ExtractPath = "$Global:WorkDir\Extracted"
    
    if (!(Test-Path "$ExtractPath\ventoy\Ventoy2Disk.exe")) {
        Log-Msg "Downloading Ventoy Tool..." "Yellow"
        (New-Object Net.WebClient).DownloadFile($Assets.WinUrl, $ZipFile)
        if (Test-Path $ExtractPath) { Remove-Item $ExtractPath -Recurse -Force }
        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $ExtractPath)
    }
    
    $Global:VentoyExe = Get-ChildItem -Path $ExtractPath -Filter "Ventoy2Disk.exe" -Recurse | Select -First 1 | %{$_.FullName}
    
    # 2. GET DRIVE LETTER
    Force-Disk-Refresh
    $DL = $null
    try { if (Get-Command Get-Partition -EA 0) { $Part = Get-Partition -DiskNumber $DiskID -EA 0 | Where-Object { $_.DriveLetter } | Select -First 1; if ($Part) { $DL = "$($Part.DriveLetter):" } } } catch {}
    if (!$DL) { $DL = Get-DriveLetter-WMI $DiskID }
    if (!$DL) { $DL = Get-DriveLetter-DiskPart $DiskID }
    
    if (!$DL) { Log-Msg "Lỗi: Không tìm thấy ký tự ổ đĩa!" "Red"; return }
    Log-Msg "Target: $DL" "Cyan"

    # 3. RUN VENTOY (ASYNC)
    $FlagMode = if ($Mode -eq "UPDATE") { "/U" } else { "/I" }
    $FlagStyle = if ($Style -match "GPT") { "/GPT" } else { "/MBR" }
    $FlagSecure = if ($ChkSec.Checked) { "/S" } else { "" }
    
    Log-Msg "Running Ventoy2Disk..." "Cyan"
    
    $PInfo = New-Object System.Diagnostics.ProcessStartInfo
    $PInfo.FileName = $Global:VentoyExe
    $PInfo.Arguments = "VTOYCLI $FlagMode /Drive:$DL /NoUsbCheck $FlagStyle $FlagSecure"
    $PInfo.RedirectStandardOutput = $true; $PInfo.RedirectStandardError = $true; $PInfo.UseShellExecute = $false; $PInfo.CreateNoWindow = $true
    
    $P = New-Object System.Diagnostics.Process; $P.StartInfo = $PInfo
    $P.Add_OutputDataReceived({ if (![string]::IsNullOrEmpty($_.Data)) { Log-Msg ">> $($_.Data)" "Gray" } })
    $P.EnableRaisingEvents = $true
    
    $P.Add_Exited({
        $ExitCode = $P.ExitCode
        $Form.Invoke([Action]{
            if ($ExitCode -eq 0) {
                # --- TRY/CATCH ĐỂ CHỐNG VĂNG APP ---
                try {
                    Log-Msg "VENTOY OK!" "Success"
                    Log-Msg "Đợi 5s để Windows nhận ổ đĩa..." "Yellow"
                    Start-Sleep 5
                    Force-Disk-Refresh
                    
                    $NewDL = Get-DriveLetter-DiskPart $DiskID
                    if ($NewDL) { $UsbRoot = $NewDL } else { $UsbRoot = $DL }
                    
                    if (Test-Path $UsbRoot) {
                        # --- 4. FORMAT & RENAME ---
                        if ($Mode -eq "INSTALL") {
                            $TargetFS = if ($FSType -match "NTFS") { "NTFS" } elseif ($FSType -match "FAT32") { "FAT32" } else { "exFAT" }
                            Log-Msg "Configuring: Label='$LabelName' FS=$TargetFS" "Yellow"
                            
                            try {
                                # Thử dùng lệnh label cmd cho an toàn nhất
                                cmd /c "label $UsbRoot $LabelName"
                                Log-Msg "Label Set OK." "Success"
                            } catch { Log-Msg "Lỗi đặt tên Label." "Warn" }
                        }

                        $VentoyDir = "$UsbRoot\ventoy"
                        if (!(Test-Path $VentoyDir)) { New-Item -Path $VentoyDir -ItemType Directory -Force | Out-Null }

                        # --- 5. FOLDER STRUCTURE ---
                        if ($IsDir) {
                            Log-Msg "Creating Folders..." "Yellow"
                            $Dirs = @(
                                "ISO_Windows\Win7", "ISO_Windows\Win10", "ISO_Windows\Win11", "ISO_Windows\LTSC", "ISO_Windows\Server",
                                "ISO_Linux\Ubuntu", "ISO_Linux\Kali", "ISO_Linux\CentOS",
                                "ISO_Rescue", "ISO_Android", "Tools_Drivers"
                            )
                            foreach ($d in $Dirs) { 
                                try { New-Item -Path "$UsbRoot\$d" -ItemType Directory -Force | Out-Null } catch {} 
                            }
                        }

                        # --- 6. LIVECD DOWNLOAD ---
                        if ($IsLiveCD -and $Assets.LiveUrl) {
                            Log-Msg "Downloading LiveCD (~180MB)..." "Yellow"
                            $LiveFile = "$UsbRoot\ISO_Rescue\ventoy-livecd.iso"
                            if (!(Test-Path "$UsbRoot\ISO_Rescue")) { New-Item "$UsbRoot\ISO_Rescue" -ItemType Directory -Force | Out-Null }
                            
                            try {
                                (New-Object Net.WebClient).DownloadFile($Assets.LiveUrl, $LiveFile)
                                Log-Msg "LiveCD Downloaded." "Success"
                            } catch { Log-Msg "Download LiveCD Failed." "Red" }
                        }

                        # --- 7. THEME & JSON ---
                        # (Giữ nguyên logic JSON cũ nhưng bọc try/catch)
                        try {
                            $J = @{
                                "control" = @(@{ "VTOY_DEFAULT_MENU_MODE" = "0" }, @{ "VTOY_FILT_DOT_UNDERSCORE_FILE" = "1" })
                                "theme" = @{ "display_mode" = "GUI"; "gfxmode" = "1920x1080" }
                                "menu_alias" = @( @{ "image" = "/ventoy/ventoy.png"; "alias" = "PHAT TAN RESCUE USB" } )
                            }
                            if ($ChkMem.Checked) { $J.control += @{ "VTOY_MEM_DISK_MODE" = "1" } }
                            $J | ConvertTo-Json -Depth 5 | Out-File "$VentoyDir\ventoy.json" -Encoding UTF8 -Force
                        } catch { Log-Msg "Lỗi tạo config JSON." "Red" }
                        
                        Log-Msg "DONE! Enjoy." "Success"
                        [System.Windows.Forms.MessageBox]::Show("HOÀN TẤT!", "Phat Tan PC")
                        Invoke-Item $UsbRoot
                    } else {
                        Log-Msg "Không thể truy cập USB (Cần rút ra cắm lại)." "Warn"
                        [System.Windows.Forms.MessageBox]::Show("Xong! Rút USB ra cắm lại để dùng.", "Thông báo")
                    }
                } catch {
                    Log-Msg "LỖI NGOẠI LỆ: $($_.Exception.Message)" "Red"
                    [System.Windows.Forms.MessageBox]::Show("Có lỗi xảy ra nhưng Ventoy đã cài xong.", "Lỗi nhẹ")
                }
            } else { Log-Msg "Error ExitCode: $ExitCode" "Red" }
            
            $BtnStart.Enabled = $true; $Form.Cursor = "Default"
        })
    })

    $P.Start() | Out-Null; $P.BeginOutputReadLine(); $P.BeginErrorReadLine()
}

$BtnRef.Add_Click({ Load-USB })
$BtnInfo.Add_Click({ Show-UsbDetails })
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
