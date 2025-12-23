<#
    TOOL CUU HO MAY TINH - PHAT TAN PC (MODERN UI EDITION)
    Author:  Phat Tan
    Version: 12.0 (Professional UI Overhaul)
    Github:  https://github.com/Hello2k2/Kho-Do-Nghe
#>

# --- 1. ADMIN CHECK ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- 2. INIT & CONFIG ---
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"

$BaseUrl = "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/"
$RawUrl  = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/"
$JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/apps.json"
$TempDir = "$env:TEMP\PhatTan_Tool"

# Tao folder
if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }
# Fix TLS
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13

# --- 3. MODERN THEME ENGINE (COLOR PALETTE) ---
$Global:DarkMode = $true 

$Theme = @{
    Dark = @{
        FormBack    = [System.Drawing.Color]::FromArgb(32, 33, 36)      # Màu nền chính tối
        SideBar     = [System.Drawing.Color]::FromArgb(25, 25, 25)      # Màu menu trái
        PanelBack   = [System.Drawing.Color]::FromArgb(45, 45, 48)      # Màu nền thẻ
        TextMain    = [System.Drawing.Color]::FromArgb(240, 240, 240)   # Chữ trắng
        TextDim     = [System.Drawing.Color]::FromArgb(160, 160, 160)   # Chữ xám
        Accent      = [System.Drawing.Color]::FromArgb(0, 120, 215)     # Xanh Win 10
        ButtonBack  = [System.Drawing.Color]::FromArgb(60, 60, 60)      # Nền nút
        ButtonHover = [System.Drawing.Color]::FromArgb(80, 80, 80)
        Success     = [System.Drawing.Color]::FromArgb(40, 167, 69)     # Màu xanh lá (Nút cài)
        Warning     = [System.Drawing.Color]::FromArgb(255, 193, 7)
    }
    Light = @{
        FormBack    = [System.Drawing.Color]::FromArgb(243, 243, 243)
        SideBar     = [System.Drawing.Color]::FromArgb(255, 255, 255)
        PanelBack   = [System.Drawing.Color]::FromArgb(255, 255, 255)
        TextMain    = [System.Drawing.Color]::FromArgb(30, 30, 30)
        TextDim     = [System.Drawing.Color]::FromArgb(100, 100, 100)
        Accent      = [System.Drawing.Color]::FromArgb(0, 120, 215)
        ButtonBack  = [System.Drawing.Color]::FromArgb(230, 230, 230)
        ButtonHover = [System.Drawing.Color]::FromArgb(210, 210, 210)
        Success     = [System.Drawing.Color]::FromArgb(40, 167, 69)
        Warning     = [System.Drawing.Color]::FromArgb(255, 193, 7)
    }
}

# --- 4. CORE FUNCTIONS (LOGIC GIỮ NGUYÊN) ---
function Set-Status($Text) { $LblStatus.Text = " ➤ $Text"; $Form.Refresh() }

function Tai-Va-Chay {
    param ($Link, $Name, $Type)
    Set-Status "Đang tải: $Name..."
    if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }
    if ($Link -notmatch "^http") { $Link = "$BaseUrl$Link" }
    $Dest = "$TempDir\$Name"
    try {
        (New-Object System.Net.WebClient).DownloadFile($Link, $Dest)
        if (Test-Path $Dest) {
            Set-Status "Đang chạy: $Name..."
            if ($Type -eq "Msi") { Start-Process "msiexec.exe" "/i `"$Dest`" /quiet /norestart" -Wait }
            else { Start-Process $Dest -Wait }
            Set-Status "Hoàn tất: $Name"
        }
    } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi tải file: $Name", "Error"); Set-Status "Lỗi: $Name" }
}

function Load-Module ($ScriptName) {
    Set-Status "Đang tải Module: $ScriptName..."
    if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }
    $LocalPath = "$TempDir\$ScriptName"
    $Ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $Url = "$RawUrl$ScriptName" + "?t=$Ts"
    try {
        $WebClient = New-Object System.Net.WebClient; $WebClient.Encoding = [System.Text.Encoding]::UTF8
        $Content = $WebClient.DownloadString($Url)
        [System.IO.File]::WriteAllText($LocalPath, $Content)
        if (Test-Path $LocalPath) { 
            Set-Status "Đang thực thi: $ScriptName..."
            Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$LocalPath`"" 
            Set-Status "Module đã chạy xong."
        }
    } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi tải Module: $ScriptName", "Lỗi Kết Nối"); Set-Status "Lỗi kết nối." }
}

# --- 5. GUI CONSTRUCTION (MODERN LAYOUT) ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "PHAT TAN PC TOOLKIT - PROFESSIONAL EDITION"
$Form.Size = New-Object System.Drawing.Size(1100, 700)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "Sizable" # Cho phép resize
$Form.MinimumSize = New-Object System.Drawing.Size(1000, 650)

# --- FONT ---
$FontTitle = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$FontHead  = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$FontNorm  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$FontIcon  = New-Object System.Drawing.Font("Segoe UI Symbol", 14) # Font cho icon unicode

# --- MAIN CONTAINERS ---
# Sidebar (Left)
$PnlSide = New-Object System.Windows.Forms.Panel; $PnlSide.Dock = "Left"; $PnlSide.Width = 240; $Form.Controls.Add($PnlSide)

# Content (Right)
$PnlContent = New-Object System.Windows.Forms.Panel; $PnlContent.Dock = "Fill"; $Form.Controls.Add($PnlContent)

# Status Bar (Bottom of Content)
$PnlStatus = New-Object System.Windows.Forms.Panel; $PnlStatus.Dock = "Bottom"; $PnlStatus.Height = 30; $PnlContent.Controls.Add($PnlStatus)
$LblStatus = New-Object System.Windows.Forms.Label; $LblStatus.Text = " ➤ Sẵn sàng phục vụ."; $LblStatus.Dock="Fill"; $LblStatus.TextAlign="MiddleLeft"; $LblStatus.Font=$FontNorm; $PnlStatus.Controls.Add($LblStatus)

# Header (Top of Content)
$PnlHeader = New-Object System.Windows.Forms.Panel; $PnlHeader.Dock = "Top"; $PnlHeader.Height = 70; $PnlContent.Controls.Add($PnlHeader)

# Title in Header
$LblAppTitle = New-Object System.Windows.Forms.Label; $LblAppTitle.Text = "DASHBOARD"; $LblAppTitle.AutoSize=$true; $LblAppTitle.Location="20, 20"; $LblAppTitle.Font=$FontTitle; $PnlHeader.Controls.Add($LblAppTitle)

# Theme Toggle
$BtnTheme = New-Object System.Windows.Forms.Button; $BtnTheme.Size="100,35"; $BtnTheme.Location="720, 20"; $BtnTheme.FlatStyle="Flat"; $BtnTheme.Anchor="Top, Right"
$BtnTheme.Add_Click({ $Global:DarkMode = -not $Global:DarkMode; Apply-Theme })
$PnlHeader.Controls.Add($BtnTheme)

# --- HELPER: CREATE MODERN BUTTON ---
function Add-ModernBtn {
    param($Parent, $Text, $Icon, $Cmd, $ColorType="Normal")
    $Btn = New-Object System.Windows.Forms.Button
    $Btn.Text = "  $Icon  $Text"
    $Btn.Size = New-Object System.Drawing.Size(180, 50) # Nút to hơn
    $Btn.Margin = New-Object System.Windows.Forms.Padding(5)
    $Btn.FlatStyle = "Flat"; $Btn.FlatAppearance.BorderSize = 0
    $Btn.Font = $FontNorm; $Btn.TextAlign = "MiddleLeft"
    $Btn.Cursor = "Hand"
    $Btn.Tag = $ColorType # Lưu loại màu để theme xử lý
    $Btn.Add_Click($Cmd)
    
    # Hiệu ứng Hover đơn giản
    $Btn.Add_MouseEnter({ 
        $T = if ($Global:DarkMode) { $Theme.Dark } else { $Theme.Light }
        $this.BackColor = $T.ButtonHover
    })
    $Btn.Add_MouseLeave({ 
        $T = if ($Global:DarkMode) { $Theme.Dark } else { $Theme.Light }
        if ($this.Tag -eq "Success") { $this.BackColor = $T.Success } else { $this.BackColor = $T.ButtonBack }
    })
    
    $Parent.Controls.Add($Btn)
    return $Btn
}

# --- HELPER: CONTENT PAGES ---
$Pages = @{}
function Create-Page ($ID, $Title) {
    $P = New-Object System.Windows.Forms.FlowLayoutPanel
    $P.Dock = "Fill"; $P.AutoScroll = $true; $P.Padding = "20,20,20,20"; $P.Visible = $false
    $PnlContent.Controls.Add($P); $P.BringToFront()
    $Pages[$ID] = @{ Panel=$P; Title=$Title }
    return $P
}

function Switch-Page ($ID) {
    foreach ($k in $Pages.Keys) { $Pages[$k].Panel.Visible = $false }
    $Pages[$ID].Panel.Visible = $true
    $LblAppTitle.Text = $Pages[$ID].Title.ToUpper()
}

# --- SIDEBAR MENU ITEMS ---
function Add-MenuBtn ($Text, $Icon, $TargetID) {
    $Btn = New-Object System.Windows.Forms.Button
    $Btn.Text = "   $Icon   $Text"; $Btn.Dock = "Top"; $Btn.Height = 55; $Btn.FlatStyle = "Flat"; $Btn.FlatAppearance.BorderSize = 0
    $Btn.Font = $FontHead; $Btn.TextAlign = "MiddleLeft"; $Btn.Cursor = "Hand"
    $Btn.Add_Click({ Switch-Page $TargetID })
    $PnlSide.Controls.Add($Btn); $Btn.SendToBack() # Đẩy xuống dưới để cái đầu tiên lên trên
    return $Btn
}

# --- LOGO AREA ---
$PnlLogo = New-Object System.Windows.Forms.Panel; $PnlLogo.Dock="Top"; $PnlLogo.Height=100; $PnlSide.Controls.Add($PnlLogo)
$LblLogo = New-Object System.Windows.Forms.Label; $LblLogo.Text="PHAT TAN`nPC TOOLS"; $LblLogo.Dock="Fill"; $LblLogo.TextAlign="MiddleCenter"; $LblLogo.Font=$FontTitle; $PnlLogo.Controls.Add($LblLogo)

# --- TẠO CÁC TRANG (PAGES) ---
# 1. SYSTEM
$PageSys = Create-Page "SYS" "Bảo Trì Hệ Thống"
Add-ModernBtn $PageSys "Check Info" "ℹ" { Load-Module "SystemInfo.ps1" }
Add-ModernBtn $PageSys "Dọn Rác Pro" "♻" { Load-Module "SystemCleaner.ps1" }
Add-ModernBtn $PageSys "Quản Lý Đĩa" "💾" { Load-Module "DiskManager.ps1" }
Add-ModernBtn $PageSys "Quét Hệ Thống" "🔍" { Load-Module "SystemScan.ps1" }
Add-ModernBtn $PageSys "Ram Booster" "⚡" { Load-Module "RamBooster.ps1" }
Add-ModernBtn $PageSys "Kích Hoạt Win" "🗝" { Load-Module "WinActivator.ps1" }
Add-ModernBtn $PageSys "Cứu Hộ HDD" "🚑" { Tai-Va-Chay "Disk.Genius.rar" "DiskGenius.rar" "Portable" }
Add-ModernBtn $PageSys "Gỡ App Rác" "🗑" { Load-Module "Debloater.ps1" }

# 2. NETWORK & SECURITY
$PageNet = Create-Page "NET" "Mạng & Bảo Mật"
Add-ModernBtn $PageNet "DNS Master" "🌐" { Load-Module "NetworkMaster.ps1" }
Add-ModernBtn $PageNet "Win Update" "↻" { Load-Module "WinUpdatePro.ps1" }
Add-ModernBtn $PageNet "Defender Mgr" "🛡" { Load-Module "DefenderMgr.ps1" }
Add-ModernBtn $PageNet "BitLocker" "🔒" { Load-Module "BitLockerMgr.ps1" }
Add-ModernBtn $PageNet "Chặn Web Độc" "⛔" { Load-Module "BrowserPrivacy.ps1" }
Add-ModernBtn $PageNet "Tắt Firewall" "🔥" { netsh advfirewall set allprofiles state off; [System.Windows.Forms.MessageBox]::Show("Đã Tắt Tường Lửa!") }

# 3. TOOLS & DEPLOY
$PageTool = Create-Page "TOOL" "Công Cụ & Cài Đặt"
Add-ModernBtn $PageTool "Cài Windows" "💿" { Load-Module "WinInstall.ps1" }
Add-ModernBtn $PageTool "Cài Office" "📝" { Load-Module "OfficeInstaller.ps1" }
Add-ModernBtn $PageTool "Mod Windows" "🔧" { Load-Module "WinModder.ps1" }
Add-ModernBtn $PageTool "Tạo Bộ Cài AIO" "📦" { Load-Module "WinAIOBuilder.ps1" }
Add-ModernBtn $PageTool "Trợ lý AI" "🤖" { Load-Module "GeminiAI.ps1" }
Add-ModernBtn $PageTool "LTSC Store" "👜" { Load-Module "StoreInstaller.ps1" }
Add-ModernBtn $PageTool "Tải ISO Nhanh" "📥" { Load-Module "ISODownloader.ps1" }
Add-ModernBtn $PageTool "Backup Data" "☁" { Load-Module "BackupCenter.ps1" }
Add-ModernBtn $PageTool "Tạo USB Boot" "⚡" { Load-Module "UsbBootMaker.ps1" }

# 4. APP STORE (Dynamically Loaded)
$PageApp = Create-Page "APP" "Kho Phần Mềm (Auto Install)"
# Tạo Panel chứa Checkbox
$AppFlow = New-Object System.Windows.Forms.FlowLayoutPanel; $AppFlow.AutoSize=$true; $AppFlow.Width=800; $AppFlow.FlowDirection="TopDown"; $PageApp.Controls.Add($AppFlow)
# Tạo Panel chứa nút hành động
$AppActionPnl = New-Object System.Windows.Forms.FlowLayoutPanel; $AppActionPnl.AutoSize=$true; $AppActionPnl.Width=800; $PageApp.Controls.Add($AppActionPnl)

# Nút hành động cho App
$BtnAppInstall = Add-ModernBtn $AppActionPnl "CÀI ĐẶT ĐÃ CHỌN" "🚀" $null "Success"
$BtnAppInstall.Width = 250
$BtnAppInstall.Add_Click({
    $BtnAppInstall.Enabled=$false; $BtnAppInstall.Text="ĐANG XỬ LÝ..."
    foreach($C in $AppFlow.Controls){
        if($C -is [System.Windows.Forms.CheckBox] -and $C.Checked){
            $I = $C.Tag
            if($I.type -eq "Script"){ iex $I.irm } else { Tai-Va-Chay $I.link $I.filename $I.type; if($I.irm){ iex $I.irm } }
            $C.Checked=$false
        }
    }
    [System.Windows.Forms.MessageBox]::Show("Đã Xong!", "Info"); $BtnAppInstall.Text="  🚀  CÀI ĐẶT ĐÃ CHỌN"; $BtnAppInstall.Enabled=$true
})

# Load Json Apps
try {
    $Ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $Data = Invoke-RestMethod -Uri "$($JsonUrl.Trim())?t=$Ts" -Headers @{"User-Agent"="PS";"Cache-Control"="no-cache"} -ErrorAction Stop
    $JsonTabs = $Data | Select -Expand tab -Unique
    foreach ($T in $JsonTabs) {
        $Lbl = New-Object System.Windows.Forms.Label; $Lbl.Text=$T; $Lbl.Font=$FontHead; $Lbl.AutoSize=$true; $Lbl.ForeColor=[System.Drawing.Color]::Gray; $Lbl.Margin="0,15,0,5"; $AppFlow.Controls.Add($Lbl)
        $Apps = $Data | Where {$_.tab -eq $T}
        foreach ($A in $Apps) {
            $Chk = New-Object System.Windows.Forms.CheckBox; $Chk.Text=$A.name; $Chk.Tag=$A; $Chk.AutoSize=$true; $Chk.Font=$FontNorm; $Chk.Margin="20,2,0,2"; $AppFlow.Controls.Add($Chk)
        }
    }
} catch { $LblErr = New-Object System.Windows.Forms.Label; $LblErr.Text="Không tải được danh sách App."; $AppFlow.Controls.Add($LblErr) }

# 5. INFO & DONATE
$PageInfo = Create-Page "INFO" "Thông Tin & Donate"
$TxtInfo = "PHAT TAN PC TOOLKIT`nPhiên bản: 12.0 UI Remastered`n`nCredits:`n- MMT (Ma Minh Toan)`n- Massgrave.dev`n- Community Modules`n`nLiên hệ: 0823.883.028"
$LblInfo = New-Object System.Windows.Forms.Label; $LblInfo.Text=$TxtInfo; $LblInfo.AutoSize=$true; $LblInfo.Font=$FontNorm; $PageInfo.Controls.Add($LblInfo)
Add-ModernBtn $PageInfo "Mở QR Donate" "☕" {
    $D=New-Object System.Windows.Forms.Form;$D.Size="400,500";$D.StartPosition="CenterScreen";$P=New-Object System.Windows.Forms.PictureBox;$P.Dock="Fill";$P.SizeMode="Zoom"
    try{$P.Load("https://img.vietqr.io/image/970436-1055835227-print.png?addInfo=Donate%20PhatTanPC&accountName=DANG%20LAM%20TAN%20PHAT")}catch{};$D.Controls.Add($P);$D.ShowDialog() 
}

# --- BUILD MENU (Thêm nút vào Sidebar) ---
# Lưu ý: Add ngược từ dưới lên do Dock=Top
Add-MenuBtn "Info & Donate" "☕" "INFO"
Add-MenuBtn "Kho Ứng Dụng" "🛒" "APP"
Add-MenuBtn "Công Cụ / ISO" "🛠" "TOOL"
Add-MenuBtn "Mạng / Bảo Mật" "🛡" "NET"
Add-MenuBtn "Hệ Thống" "💻" "SYS"

# --- APPLY THEME FUNCTION ---
function Apply-Theme {
    $T = if ($Global:DarkMode) { $Theme.Dark } else { $Theme.Light }
    
    # Form
    $Form.BackColor = $T.FormBack; $Form.ForeColor = $T.TextMain
    
    # SideBar
    $PnlSide.BackColor = $T.SideBar
    $PnlLogo.ForeColor = $T.Accent
    foreach ($C in $PnlSide.Controls) { if ($C -is [System.Windows.Forms.Button]) { $C.ForeColor = $T.TextMain } }
    
    # Content Areas
    $PnlHeader.BackColor = $T.FormBack
    $LblAppTitle.ForeColor = $T.Accent
    $PnlStatus.BackColor = $T.SideBar
    $LblStatus.ForeColor = $T.TextDim
    
    # Theme Button
    $BtnTheme.Text = if ($Global:DarkMode) { "☀ LIGHT" } else { "🌙 DARK" }
    $BtnTheme.BackColor = $T.ButtonBack; $BtnTheme.ForeColor = $T.TextMain
    
    # Content Pages & Buttons
    foreach ($page in $Pages.Values) {
        $page.Panel.BackColor = $T.FormBack
        foreach ($C in $page.Panel.Controls) {
            # Buttons
            if ($C -is [System.Windows.Forms.Button]) {
                if ($C.Tag -eq "Success") {
                    $C.BackColor = $T.Success; $C.ForeColor = [System.Drawing.Color]::White
                } else {
                    $C.BackColor = $T.ButtonBack; $C.ForeColor = $T.TextMain
                }
            }
            # Checkboxes inside Panels
            if ($C -is [System.Windows.Forms.FlowLayoutPanel]) {
                foreach ($SubC in $C.Controls) {
                     if ($SubC -is [System.Windows.Forms.CheckBox]) { $SubC.ForeColor = $T.TextMain }
                     if ($SubC -is [System.Windows.Forms.Label]) { 
                        if ($SubC.Font.Size -gt 10) { $SubC.ForeColor = $T.Accent } else { $SubC.ForeColor = $T.TextMain }
                     }
                     # Special install button inside panel
                     if ($SubC -is [System.Windows.Forms.Button]) {
                         $SubC.BackColor = $T.Success; $SubC.ForeColor = [System.Drawing.Color]::White
                     }
                }
            }
            # Labels
            if ($C -is [System.Windows.Forms.Label]) { $C.ForeColor = $T.TextMain }
        }
    }
}

# --- STARTUP ---
Apply-Theme
Switch-Page "SYS" # Mặc định mở trang Hệ Thống
$Form.Add_Load({ $Form.Opacity = 0; 
    $Timer = New-Object System.Windows.Forms.Timer; $Timer.Interval=20; 
    $Timer.Add_Tick({ $Form.Opacity+=0.1; if($Form.Opacity-ge 1){$Timer.Stop()} }); $Timer.Start() 
})
$Form.ShowDialog() | Out-Null
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
