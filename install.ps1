<#
    TOOL CUU HO MAY TINH - PHAT TAN PC
    Author:  Phat Tan
    Version: 12.3 (Vietnamese Material UI)
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

# Cấu hình đường dẫn
$BaseUrl = "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/"
$RawUrl  = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/"
$JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/apps.json"
$TempDir = "$env:TEMP\PhatTan_Tool"

# Fix TLS & Folder Temp
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13
if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }

# --- 3. THEME ENGINE (MATERIAL DARK) ---
$Colors = @{
    Back      = [System.Drawing.Color]::FromArgb(32, 33, 36)       # Xám đen lì (Google Dark)
    Card      = [System.Drawing.Color]::FromArgb(48, 49, 52)       # Card nổi nhẹ
    Text      = [System.Drawing.Color]::FromArgb(232, 234, 237)    # Trắng dịu
    Accent    = [System.Drawing.Color]::FromArgb(138, 180, 248)    # Xanh dương pastel (Điểm nhấn)
    BtnBack   = [System.Drawing.Color]::FromArgb(60, 64, 67)       # Nền nút
    BtnHover  = [System.Drawing.Color]::FromArgb(80, 84, 87)       # Nền nút khi hover
    Green     = [System.Drawing.Color]::FromArgb(129, 201, 149)    # Xanh lá dịu
    Red       = [System.Drawing.Color]::FromArgb(242, 139, 130)    # Đỏ dịu
}

# --- 4. CORE LOGIC ---
function Tai-Va-Chay {
    param ($Link, $Name, $Type)
    $StatusLabel.Text = ">> Đang tải: $Name ..."
    $Form.Refresh()
    if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }
    if ($Link -notmatch "^http") { $Link = "$BaseUrl$Link" }
    $Dest = "$TempDir\$Name"
    try {
        (New-Object System.Net.WebClient).DownloadFile($Link, $Dest)
        if (Test-Path $Dest) {
            $StatusLabel.Text = ">> Đang chạy: $Name ..."
            if ($Type -eq "Msi") { Start-Process "msiexec.exe" "/i `"$Dest`" /quiet /norestart" -Wait } else { Start-Process $Dest -Wait }
            $StatusLabel.Text = ">> Hoàn tất: $Name"
        }
    } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi tải file!", "Error"); $StatusLabel.Text = "!! LỖI !!" }
}

function Load-Module ($ScriptName) {
    $StatusLabel.Text = ">> Đang mở Module: $ScriptName ..."
    $Form.Refresh()
    if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }
    $LocalPath = "$TempDir\$ScriptName"
    $Ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $Url = "$RawUrl$ScriptName" + "?t=$Ts"
    try {
        $Web = New-Object System.Net.WebClient; $Web.Encoding = [System.Text.Encoding]::UTF8
        $Web.DownloadString($Url) | Out-File -FilePath $LocalPath -Encoding UTF8
        if (Test-Path $LocalPath) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$LocalPath`"" }
        $StatusLabel.Text = ">> Module sẵn sàng: $ScriptName"
    } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi tải Module!", "Lỗi Kết Nối"); $StatusLabel.Text = "!! MẤT KẾT NỐI !!" }
}

# --- 5. GUI BUILDER ---

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "PHAT TAN PC TOOLKIT V12.3"
$Form.Size = New-Object System.Drawing.Size(1050, 720) # Kích thước chuẩn
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false
$Form.BackColor = $Colors.Back
$Form.ForeColor = $Colors.Text

# --- HEADER ---
$PnlHeader = New-Object System.Windows.Forms.Panel; $PnlHeader.Size = "1050, 70"; $PnlHeader.Dock = "Top"; $PnlHeader.BackColor = [System.Drawing.Color]::Transparent
$Form.Controls.Add($PnlHeader)

$LblLogo = New-Object System.Windows.Forms.Label
$LblLogo.Text = "PHAT TAN PC"
$LblLogo.Font = New-Object System.Drawing.Font("Segoe UI", 24, [System.Drawing.FontStyle]::Bold)
$LblLogo.ForeColor = $Colors.Accent
$LblLogo.AutoSize = $true
$LblLogo.Location = "20, 10"
$PnlHeader.Controls.Add($LblLogo)

$LblSub = New-Object System.Windows.Forms.Label
$LblSub.Text = "Bộ Công Cụ Cứu Hộ Máy Tính Chuyên Nghiệp"
$LblSub.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Italic)
$LblSub.ForeColor = "Gray"
$LblSub.AutoSize = $true
$LblSub.Location = "25, 48"
$PnlHeader.Controls.Add($LblSub)

# --- TABS ---
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = "15, 80"
$TabControl.Size = "1005, 520"
$TabControl.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 11)
$TabControl.Appearance = "FlatButtons"
$TabControl.SizeMode = "Fixed"
$TabControl.ItemSize = New-Object System.Drawing.Size(180, 40)
$Form.Controls.Add($TabControl)

# > TAB 1: CÔNG CỤ
$AdvTab = New-Object System.Windows.Forms.TabPage; $AdvTab.Text = "🔧 CÔNG CỤ HỆ THỐNG"; $AdvTab.BackColor = $Colors.Back; $TabControl.Controls.Add($AdvTab)

# GRID LAYOUT (3 CỘT)
$Grid = New-Object System.Windows.Forms.TableLayoutPanel
$Grid.Dock = "Fill"
$Grid.ColumnCount = 3
$Grid.RowCount = 1
$Grid.Padding = New-Object System.Windows.Forms.Padding(5)
$Grid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33.33))) | Out-Null
$Grid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33.33))) | Out-Null
$Grid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33.33))) | Out-Null
$AdvTab.Controls.Add($Grid)

# FUNCTION VẼ CARD
function New-GroupCard ($Title, $ColIndex) {
    $Panel = New-Object System.Windows.Forms.Panel
    $Panel.Dock = "Fill"
    $Panel.Margin = New-Object System.Windows.Forms.Padding(8)
    $Panel.Padding = New-Object System.Windows.Forms.Padding(1, 45, 1, 1) # Chừa chỗ cho Title
    $Panel.BackColor = $Colors.Card # Màu nền Card
    
    # Title
    $Lbl = New-Object System.Windows.Forms.Label
    $Lbl.Text = $Title.ToUpper()
    $Lbl.Dock = "Top"
    $Lbl.Height = 40
    $Lbl.TextAlign = "MiddleCenter"
    $Lbl.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $Lbl.ForeColor = $Colors.Accent
    $Panel.Controls.Add($Lbl)

    # Container
    $Flow = New-Object System.Windows.Forms.FlowLayoutPanel
    $Flow.Dock = "Fill"
    $Flow.FlowDirection = "TopDown"
    $Flow.WrapContents = $false
    $Flow.AutoScroll = $true 
    $Flow.Padding = New-Object System.Windows.Forms.Padding(10, 0, 0, 0) # Padding trái để nút không sát lề
    
    # Auto Resize Button Width
    $Flow.Add_SizeChanged({ foreach($c in $Flow.Controls){ $c.Width = $Flow.Width - 25 } })
    
    $Panel.Controls.Add($Flow)
    $Grid.Controls.Add($Panel, $ColIndex, 0)
    return $Flow
}

function Add-Btn ($Parent, $Text, $Cmd, $Icon) {
    $Btn = New-Object System.Windows.Forms.Button
    $Btn.Text = "  $Icon  $Text" 
    $Btn.Height = 48 # Chiều cao vừa phải
    $Btn.Width = 280 
    $Btn.FlatStyle = "Flat"
    $Btn.FlatAppearance.BorderSize = 0
    $Btn.BackColor = $Colors.BtnBack
    $Btn.ForeColor = $Colors.Text
    $Btn.TextAlign = "MiddleLeft"
    $Btn.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $Btn.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 8)
    $Btn.Cursor = "Hand"
    
    # Hiệu ứng Hover (Đổi màu + Thụt vào)
    $Btn.Add_MouseEnter({ 
        $this.BackColor = $Colors.BtnHover
        $this.ForeColor = $Colors.Accent
        $this.Padding = New-Object System.Windows.Forms.Padding(10,0,0,0) 
    })
    $Btn.Add_MouseLeave({ 
        $this.BackColor = $Colors.BtnBack
        $this.ForeColor = $Colors.Text
        $this.Padding = New-Object System.Windows.Forms.Padding(0,0,0,0)
    })
    $Btn.Add_Click($Cmd)
    $Parent.Controls.Add($Btn)
}

# --- CỘT 1: HỆ THỐNG ---
$G1 = New-GroupCard "HỆ THỐNG & BẢO TRÌ" 0
Add-Btn $G1 "Kiểm Tra Cấu Hình"     { Load-Module "SystemInfo.ps1" } "ℹ"
Add-Btn $G1 "Dọn Rác Sạch Sẽ"       { Load-Module "SystemCleaner.ps1" } "♻"
Add-Btn $G1 "Quản Lý Ổ Đĩa"         { Load-Module "DiskManager.ps1" } "💾"
Add-Btn $G1 "Quét Lỗi Toàn Diện"    { Load-Module "SystemScan.ps1" } "🔍"
Add-Btn $G1 "Giải Phóng RAM"        { Load-Module "RamBooster.ps1" } "⚡"
Add-Btn $G1 "Kích Hoạt Windows"     { Load-Module "WinActivator.ps1" } "🗝"
Add-Btn $G1 "Cứu Dữ Liệu (DiskGenius)" { Tai-Va-Chay "Disk.Genius.rar" "DiskGenius.rar" "Portable" } "🚑"
Add-Btn $G1 "Gỡ App Rác (Debloat)"  { Load-Module "Debloater.ps1" } "🗑"

# --- CỘT 2: BẢO MẬT ---
$G2 = New-GroupCard "BẢO MẬT & MẠNG" 1
Add-Btn $G2 "Đổi DNS Siêu Tốc"      { Load-Module "NetworkMaster.ps1" } "🌐"
Add-Btn $G2 "Quản Lý Update Win"    { Load-Module "WinUpdatePro.ps1" } "↻"
Add-Btn $G2 "Bật/Tắt Diệt Virus"    { Load-Module "DefenderMgr.ps1" } "🛡"
Add-Btn $G2 "Khóa Ổ Cứng (BitLocker)" { Load-Module "BitLockerMgr.ps1" } "🔒"
Add-Btn $G2 "Chặn Web Độc/QC"       { Load-Module "BrowserPrivacy.ps1" } "⛔"
Add-Btn $G2 "Tắt Tường Lửa (Game)"  { netsh advfirewall set allprofiles state off; [System.Windows.Forms.MessageBox]::Show("Đã Tắt Firewall!") } "🔥"

# --- CỘT 3: CÀI ĐẶT ---
$G3 = New-GroupCard "CÀI ĐẶT & TIỆN ÍCH" 2
Add-Btn $G3 "Tải ISO Win/Office"    { Load-Module "ISODownloader.ps1" } "📥"
Add-Btn $G3 "Cài Win Tự Động"       { Load-Module "WinInstall.ps1" } "💿"
Add-Btn $G3 "Cài Office Bản Quyền"  { Load-Module "OfficeInstaller.ps1" } "📝"
Add-Btn $G3 "Tối Ưu Hóa Windows"    { Load-Module "WinModder.ps1" } "🚀"
Add-Btn $G3 "Đóng Gói ISO (AIO)"    { Load-Module "WinAIOBuilder.ps1" } "📦"
Add-Btn $G3 "Trợ Lý AI (Hỏi Đáp)"   { Load-Module "GeminiAI.ps1" } "🤖"
Add-Btn $G3 "Cài Lại Microsoft Store" { Load-Module "StoreInstaller.ps1" } "👜"
Add-Btn $G3 "Tạo USB Boot Cứu Hộ"   { Load-Module "UsbBootMaker.ps1" } "⚡"

# > TAB 2: KHO PHẦN MỀM
$SoftTab = New-Object System.Windows.Forms.TabPage; $SoftTab.Text = "📦 KHO PHẦN MỀM"; $SoftTab.BackColor = $Colors.Back; $TabControl.Controls.Add($SoftTab)
$SoftFlow = New-Object System.Windows.Forms.FlowLayoutPanel; $SoftFlow.Dock="Fill"; $SoftFlow.AutoScroll=$true; $SoftFlow.Padding="20,20,20,20"; $SoftTab.Controls.Add($SoftFlow)

try {
    $Ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $Data = Invoke-RestMethod -Uri "$($JsonUrl.Trim())?t=$Ts" -Headers @{"User-Agent"="PS";"Cache-Control"="no-cache"} -ErrorAction Stop
    $JsonTabs = $Data | Select -Expand tab -Unique
    foreach ($T in $JsonTabs) {
        $Grp = New-Object System.Windows.Forms.GroupBox; $Grp.Text = "  " + $T.ToUpper() + "  "; $Grp.Width = 950; $Grp.Height = 10; $Grp.AutoSize = $true; $Grp.ForeColor = $Colors.Accent; $Grp.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        $InFlow = New-Object System.Windows.Forms.FlowLayoutPanel; $InFlow.Dock="Fill"; $InFlow.AutoSize=$true; $Grp.Controls.Add($InFlow)
        $Apps = $Data | Where {$_.tab -eq $T}
        foreach ($A in $Apps) {
            $Chk = New-Object System.Windows.Forms.CheckBox; $Chk.Text=$A.name; $Chk.Tag=$A; $Chk.AutoSize=$true; $Chk.Margin="10,5,30,10"; $Chk.Font="Segoe UI", 10; $Chk.ForeColor="White"; $InFlow.Controls.Add($Chk)
        }
        $SoftFlow.Controls.Add($Grp)
    }
} catch { $LblErr = New-Object System.Windows.Forms.Label; $LblErr.Text = "Không kết nối được máy chủ!"; $LblErr.AutoSize=$true; $LblErr.ForeColor="Red"; $SoftFlow.Controls.Add($LblErr) }

# --- FOOTER ---
$PnlFooter = New-Object System.Windows.Forms.Panel; $PnlFooter.Size = "1050, 80"; $PnlFooter.Dock = "Bottom"; $PnlFooter.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 25)
$Form.Controls.Add($PnlFooter)

# Nút Cài đặt (Giữa)
$BtnInstall = New-Object System.Windows.Forms.Button
$BtnInstall.Text = "TIẾN HÀNH CÀI ĐẶT"
$BtnInstall.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$BtnInstall.Size = "300, 50"
$BtnInstall.Location = "375, 15" # Căn giữa chuẩn (1050/2 - 300/2)
$BtnInstall.BackColor = $Colors.Accent
$BtnInstall.ForeColor = "Black" # Chữ đen trên nền xanh sáng cho dễ đọc
$BtnInstall.FlatStyle = "Flat"
$BtnInstall.Cursor = "Hand"
$BtnInstall.Add_Click({
    $BtnInstall.Enabled=$false; $BtnInstall.Text="ĐANG XỬ LÝ..."
    foreach($C in $SoftFlow.Controls){ foreach($I in $C.Controls){ foreach($K in $I.Controls){
        if($K -is [System.Windows.Forms.CheckBox] -and $K.Checked){
            $Obj = $K.Tag
            if($Obj.type -eq "Script"){ iex $Obj.irm } else { Tai-Va-Chay $Obj.link $Obj.filename $Obj.type; if($Obj.irm){ iex $Obj.irm } }
            $K.Checked=$false
        }
    }}}
    [System.Windows.Forms.MessageBox]::Show("Đã hoàn tất cài đặt!", "Thông báo"); $BtnInstall.Text="TIẾN HÀNH CÀI ĐẶT"; $BtnInstall.Enabled=$true
})
$PnlFooter.Controls.Add($BtnInstall)

# Nút Credits (Trái)
$BtnCredit = New-Object System.Windows.Forms.Button; $BtnCredit.Text="ℹ Tác Giả"; $BtnCredit.Location="20, 20"; $BtnCredit.Size="100, 40"; $BtnCredit.BackColor=$Colors.BtnBack; $BtnCredit.ForeColor="White"; $BtnCredit.FlatStyle="Flat"
$BtnCredit.Add_Click({
    [System.Windows.Forms.MessageBox]::Show("PHAT TAN PC TOOLKIT`nPhiên bản: 12.3`nPhát triển bởi: Phat Tan PC`nLiên hệ: 0823.883.028", "Thông tin tác giả")
})
$PnlFooter.Controls.Add($BtnCredit)

# Nút Donate (Phải)
$BtnDonate = New-Object System.Windows.Forms.Button; $BtnDonate.Text="☕ Donate"; $BtnDonate.Location="910, 20"; $BtnDonate.Size="100, 40"; $BtnDonate.BackColor=$Colors.BtnBack; $BtnDonate.ForeColor="Gold"; $BtnDonate.FlatStyle="Flat"
$BtnDonate.Add_Click({ 
    $D=New-Object System.Windows.Forms.Form;$D.Size="400,500";$D.StartPosition="CenterScreen";$P=New-Object System.Windows.Forms.PictureBox;$P.Dock="Fill";$P.SizeMode="Zoom"
    try{$P.Load("https://img.vietqr.io/image/970436-1055835227-print.png?addInfo=Donate%20PhatTanPC&accountName=DANG%20LAM%20TAN%20PHAT")}catch{};$D.Controls.Add($P);$D.ShowDialog() 
})
$PnlFooter.Controls.Add($BtnDonate)

# Status Bar
$StatusStrip = New-Object System.Windows.Forms.StatusStrip; $StatusStrip.BackColor = [System.Drawing.Color]::Black; $StatusStrip.ForeColor = "Gray"
$StatusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel; $StatusLabel.Text = "Sẵn sàng | PhatTanPC Toolkit v12.3"; $StatusStrip.Items.Add($StatusLabel)
$Form.Controls.Add($StatusStrip)

# Animation Fade-In
$Form.Opacity = 0
$Form.Add_Load({ 
    $Timer = New-Object System.Windows.Forms.Timer; $Timer.Interval = 10
    $Timer.Add_Tick({ if($Form.Opacity -lt 1){$Form.Opacity+=0.1}else{$Timer.Stop()} })
    $Timer.Start()
})

$Form.ShowDialog() | Out-Null
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
