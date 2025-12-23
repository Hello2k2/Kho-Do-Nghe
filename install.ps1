<#
    TOOL CUU HO MAY TINH - PHAT TAN PC
    Author:  Phat Tan
    Version: 12.0 (Ultimate UI Overhaul)
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

# --- 3. THEME ENGINE & ASSETS ---
$Global:DarkMode = $true

# Màu sắc chủ đạo (Cyan Neon Theme)
$Colors = @{
    Dark = @{
        FormBack   = [System.Drawing.Color]::FromArgb(25, 25, 30)       # Nền đen sâu
        PanelBack  = [System.Drawing.Color]::FromArgb(35, 35, 40)       # Nền Card
        Text       = [System.Drawing.Color]::FromArgb(240, 240, 240)    # Chữ trắng
        Accent     = [System.Drawing.Color]::FromArgb(0, 255, 213)      # Cyan Neon (Màu chủ đạo)
        BtnBack    = [System.Drawing.Color]::FromArgb(50, 50, 60)       # Nền nút
        BtnHover   = [System.Drawing.Color]::FromArgb(70, 70, 80)       # Nền nút khi hover
        Success    = [System.Drawing.Color]::FromArgb(46, 204, 113)     # Màu xanh lá
        Warning    = [System.Drawing.Color]::FromArgb(241, 196, 15)     # Màu vàng
        Danger     = [System.Drawing.Color]::FromArgb(231, 76, 60)      # Màu đỏ
    }
}

# Icon Unicode (An toàn, không lỗi font)
$I = @{
    Info = [char]0xE946; Clean = [char]0xE9A9; Disk = [char]0xE9CA; Scan = [char]0xE99A
    Key  = [char]0xE928; Update = [char]0xE9D5; Shield = [char]0xEA18; Lock = [char]0xEA1D
    Web  = [char]0xE9CB; Win = [char]0xE90D; Office = [char]0xE93E; Tool = [char]0xE995
    Ai   = [char]0xEA39; Cloud = [char]0xE931; Usb = [char]0xE95F; Shop = [char]0xE93A
    Down = [char]0xE960; Rocket = [char]0xEA0B; Zap = [char]0xE945; Check = [char]0xE932
}
# Fallback icon nếu font Segoe MDL2 không có (Dùng ký tự cơ bản)
if ($PSVersionTable.PSVersion.Major -lt 5) {
    $I = @{ Info="i"; Clean="x"; Disk="D"; Scan="S"; Key="K"; Update="U"; Shield="P"; Lock="L"; Web="W"; Win="W"; Office="O"; Tool="T"; Ai="A"; Cloud="C"; Usb="U"; Shop="S"; Down="D"; Rocket="R"; Zap="Z"; Check="V" }
}

# --- 4. GRAPHICS FUNCTIONS ---

# Hàm vẽ bo tròn (Rounded Rectangle)
function Get-RoundedRectPath ($Rect, $Radius) {
    $Path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $Path.AddArc($Rect.X, $Rect.Y, $Radius, $Radius, 180, 90)
    $Path.AddArc($Rect.Right - $Radius, $Rect.Y, $Radius, $Radius, 270, 90)
    $Path.AddArc($Rect.Right - $Radius, $Rect.Bottom - $Radius, $Radius, $Radius, 0, 90)
    $Path.AddArc($Rect.X, $Rect.Bottom - $Radius, $Radius, $Radius, 90, 90)
    $Path.CloseFigure()
    return $Path
}

# Sự kiện vẽ nền Card (Panel)
$Paint_Card = {
    param($sender, $e)
    $G = $e.Graphics
    $G.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $Rect = $sender.ClientRectangle
    $Rect.Width -= 1; $Rect.Height -= 1
    
    # Vẽ nền bo tròn
    $Brush = New-Object System.Drawing.SolidBrush($Colors.Dark.PanelBack)
    $Path = Get-RoundedRectPath $Rect 15
    $G.FillPath($Brush, $Path)
    
    # Vẽ viền mờ
    $Pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(60, 255, 255, 255), 1)
    $G.DrawPath($Pen, $Path)
    
    $Brush.Dispose(); $Pen.Dispose(); $Path.Dispose()
}

# --- 5. CORE LOGIC (GIỮ NGUYÊN) ---
function Tai-Va-Chay {
    param ($Link, $Name, $Type)
    $StatusLabel.Text = "Đang tải: $Name ..."
    $Form.Refresh()
    if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }
    if ($Link -notmatch "^http") { $Link = "$BaseUrl$Link" }
    $Dest = "$TempDir\$Name"
    try {
        (New-Object System.Net.WebClient).DownloadFile($Link, $Dest)
        if (Test-Path $Dest) {
            $StatusLabel.Text = "Đang chạy: $Name ..."
            if ($Type -eq "Msi") { Start-Process "msiexec.exe" "/i `"$Dest`" /quiet /norestart" -Wait } else { Start-Process $Dest -Wait }
            $StatusLabel.Text = "Hoàn tất: $Name"
        }
    } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi tải file!", "Error"); $StatusLabel.Text = "Lỗi!" }
}

function Load-Module ($ScriptName) {
    $StatusLabel.Text = "Đang kích hoạt Module: $ScriptName ..."
    $Form.Refresh()
    if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }
    $LocalPath = "$TempDir\$ScriptName"
    $Ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $Url = "$RawUrl$ScriptName" + "?t=$Ts"
    try {
        $Web = New-Object System.Net.WebClient; $Web.Encoding = [System.Text.Encoding]::UTF8
        $Web.DownloadString($Url) | Out-File -FilePath $LocalPath -Encoding UTF8
        if (Test-Path $LocalPath) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$LocalPath`"" }
        $StatusLabel.Text = "Module đã chạy: $ScriptName"
    } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi tải Module!", "Lỗi Kết Nối"); $StatusLabel.Text = "Lỗi kết nối!" }
}

# --- 6. GUI BUILDER ---

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "PHAT TAN PC TOOLKIT V12.0"
$Form.Size = New-Object System.Drawing.Size(1100, 750)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false
$Form.BackColor = $Colors.Dark.FormBack
$Form.ForeColor = $Colors.Dark.Text

# --- HEADER SECTION ---
$PnlHeader = New-Object System.Windows.Forms.Panel; $PnlHeader.Size = "1100, 80"; $PnlHeader.Dock = "Top"; $PnlHeader.BackColor = [System.Drawing.Color]::Transparent
$Form.Controls.Add($PnlHeader)

$LblLogo = New-Object System.Windows.Forms.Label
$LblLogo.Text = "PHAT TAN PC"
$LblLogo.Font = New-Object System.Drawing.Font("Segoe UI", 24, [System.Drawing.FontStyle]::Bold)
$LblLogo.ForeColor = $Colors.Dark.Accent
$LblLogo.AutoSize = $true
$LblLogo.Location = "30, 15"
$PnlHeader.Controls.Add($LblLogo)

$LblVer = New-Object System.Windows.Forms.Label
$LblVer.Text = "TOOLKIT v12.0 ULTIMATE"
$LblVer.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Italic)
$LblVer.ForeColor = [System.Drawing.Color]::Gray
$LblVer.AutoSize = $true
$LblVer.Location = "35, 55"
$PnlHeader.Controls.Add($LblVer)

# --- MAIN TAB CONTROL ---
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = "20, 90"
$TabControl.Size = "1045, 500"
$TabControl.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$TabControl.Appearance = "FlatButtons"
$TabControl.SizeMode = "Fixed"
$TabControl.ItemSize = New-Object System.Drawing.Size(150, 40)
$Form.Controls.Add($TabControl)

# > TAB ADVANCED (Cái quan trọng nhất)
$AdvTab = New-Object System.Windows.Forms.TabPage; $AdvTab.Text = "CÔNG CỤ NÂNG CAO"; $AdvTab.BackColor = $Colors.Dark.FormBack; $TabControl.Controls.Add($AdvTab)

# GRID LAYOUT (3 CỘT)
$Grid = New-Object System.Windows.Forms.TableLayoutPanel
$Grid.Dock = "Fill"
$Grid.ColumnCount = 3
$Grid.RowCount = 1
$Grid.Padding = New-Object System.Windows.Forms.Padding(10)
# Chia 3 cột đều nhau (33%)
$Grid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33.33))) | Out-Null
$Grid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33.33))) | Out-Null
$Grid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33.33))) | Out-Null
$AdvTab.Controls.Add($Grid)

# --- FUNCTION TẠO CỘT (CARD) & NÚT ---
function New-GroupCard ($Title, $ColIndex) {
    $Panel = New-Object System.Windows.Forms.Panel
    $Panel.Dock = "Fill"
    $Panel.Margin = New-Object System.Windows.Forms.Padding(10)
    $Panel.Padding = New-Object System.Windows.Forms.Padding(2)
    $Panel.Add_Paint($Paint_Card) # Bo tròn
    
    # Title
    $Lbl = New-Object System.Windows.Forms.Label
    $Lbl.Text = $Title.ToUpper()
    $Lbl.Dock = "Top"
    $Lbl.Height = 40
    $Lbl.TextAlign = "MiddleCenter"
    $Lbl.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $Lbl.ForeColor = $Colors.Dark.Accent
    $Lbl.BackColor = [System.Drawing.Color]::Transparent
    $Panel.Controls.Add($Lbl)

    # Container cho nút
    $Flow = New-Object System.Windows.Forms.FlowLayoutPanel
    $Flow.Dock = "Fill"
    $Flow.FlowDirection = "TopDown"
    $Flow.WrapContents = $false
    $Flow.BackColor = [System.Drawing.Color]::Transparent
    $Flow.Padding = New-Object System.Windows.Forms.Padding(15, 5, 15, 15)
    
    # Canh giữa nút trong Flow
    $Flow.Add_SizeChanged({ 
        foreach($c in $Flow.Controls){ $c.Width = $Flow.Width - 30 } 
    })
    
    $Panel.Controls.Add($Flow)
    $Grid.Controls.Add($Panel, $ColIndex, 0)
    return $Flow
}

function Add-StyledBtn ($Parent, $Text, $SubText, $Cmd) {
    $Btn = New-Object System.Windows.Forms.Button
    $Btn.Text = "  $Text" 
    $Btn.Height = 45
    $Btn.FlatStyle = "Flat"
    $Btn.BackColor = $Colors.Dark.BtnBack
    $Btn.ForeColor = $Colors.Dark.Text
    $Btn.TextAlign = "MiddleLeft"
    $Btn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $Btn.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 8)
    $Btn.Cursor = "Hand"
    $Btn.FlatAppearance.BorderSize = 0
    
    # Hiệu ứng Glow & Levitate
    $Btn.Add_MouseEnter({ 
        $this.BackColor = $Colors.Dark.BtnHover
        $this.ForeColor = $Colors.Dark.Accent
        $this.FlatAppearance.BorderColor = $Colors.Dark.Accent
        $this.FlatAppearance.BorderSize = 1
        $this.Padding = New-Object System.Windows.Forms.Padding(5,0,0,0) # Đẩy chữ sang phải tí
    })
    $Btn.Add_MouseLeave({ 
        $this.BackColor = $Colors.Dark.BtnBack
        $this.ForeColor = $Colors.Dark.Text
        $this.FlatAppearance.BorderSize = 0
        $this.Padding = New-Object System.Windows.Forms.Padding(0,0,0,0)
    })
    $Btn.Add_Click($Cmd)
    
    # Tooltip (Mô tả)
    $Tip = New-Object System.Windows.Forms.ToolTip
    $Tip.SetToolTip($Btn, $SubText)
    
    $Parent.Controls.Add($Btn)
}

# --- CỘT 1: HỆ THỐNG ---
$G1 = New-GroupCard "🔧 HỆ THỐNG & BẢO TRÌ" 0
Add-StyledBtn $G1 "CHECK INFO" "Xem thông tin phần cứng chi tiết" { Load-Module "SystemInfo.ps1" }
Add-StyledBtn $G1 "DỌN RÁC PRO" "Xóa file tạm, cache update sạch sẽ" { Load-Module "SystemCleaner.ps1" }
Add-StyledBtn $G1 "QUẢN LÝ Ổ ĐĨA" "Chia ổ, gộp ổ không mất dữ liệu" { Load-Module "DiskManager.ps1" }
Add-StyledBtn $G1 "QUÉT TOÀN DIỆN" "Kiểm tra lỗi Win và phần cứng" { Load-Module "SystemScan.ps1" }
Add-StyledBtn $G1 "TĂNG TỐC RAM" "Giải phóng RAM bị chiếm dụng" { Load-Module "RamBooster.ps1" }
Add-StyledBtn $G1 "KÍCH HOẠT WIN" "Active bản quyền số vĩnh viễn" { Load-Module "WinActivator.ps1" }
Add-StyledBtn $G1 "CỨU DỮ LIỆU" "Khôi phục file đã xóa (DiskGenius)" { Tai-Va-Chay "Disk.Genius.rar" "DiskGenius.rar" "Portable" }
Add-StyledBtn $G1 "DEBLOAT WIN" "Gỡ bỏ app rác mặc định của Win" { Load-Module "Debloater.ps1" }

# --- CỘT 2: BẢO MẬT & MẠNG ---
$G2 = New-GroupCard "🛡️ BẢO MẬT & MẠNG" 1
Add-StyledBtn $G2 "ĐỔI DNS SIÊU TỐC" "Chuyển DNS 1.1.1.1 / 8.8.8.8" { Load-Module "NetworkMaster.ps1" }
Add-StyledBtn $G2 "QUẢN LÝ UPDATE" "Tắt/Bật Windows Update" { Load-Module "WinUpdatePro.ps1" }
Add-StyledBtn $G2 "ON/OFF DEFENDER" "Tắt trình diệt virus mặc định" { Load-Module "DefenderMgr.ps1" }
Add-StyledBtn $G2 "KHÓA BITLOCKER" "Quản lý mã hóa ổ cứng" { Load-Module "BitLockerMgr.ps1" }
Add-StyledBtn $G2 "CHẶN WEB ĐỘC" "Chặn web đen, quảng cáo" { Load-Module "BrowserPrivacy.ps1" }
Add-StyledBtn $G2 "TẮT TƯỜNG LỬA" "Tắt Firewall để chơi LAN/Game" { netsh advfirewall set allprofiles state off; [System.Windows.Forms.MessageBox]::Show("Đã Tắt Firewall!") }

# --- CỘT 3: CÔNG CỤ CÀI ĐẶT ---
$G3 = New-GroupCard "🚀 TRIỂN KHAI & TIỆN ÍCH" 2
Add-StyledBtn $G3 "TẢI ISO WINDOWS" "Tải Win 10/11/Office max speed (v2.6)" { Load-Module "ISODownloader.ps1" }
Add-StyledBtn $G3 "CÀI WIN TỰ ĐỘNG" "Cài lại Win không cần USB" { Load-Module "WinInstall.ps1" }
Add-StyledBtn $G3 "CÀI OFFICE 365" "Bộ cài Office tự động" { Load-Module "OfficeInstaller.ps1" }
Add-StyledBtn $G3 "TỐI ƯU HÓA WIN" "Tinh chỉnh Win mượt như Ngọc Trinh" { Load-Module "WinModder.ps1" }
Add-StyledBtn $G3 "ĐÓNG GÓI ISO" "Tự tạo bộ cài Win AIO" { Load-Module "WinAIOBuilder.ps1" }
Add-StyledBtn $G3 "TRỢ LÝ AI GEMINI" "Hỏi đáp lỗi máy tính với AI" { Load-Module "GeminiAI.ps1" }
Add-StyledBtn $G3 "CỬA HÀNG MICROSOFT" "Cài lại Store cho bản LTSC" { Load-Module "StoreInstaller.ps1" }
Add-StyledBtn $G3 "TẠO USB BOOT" "Tự làm USB cứu hộ 1 click" { Load-Module "UsbBootMaker.ps1" }

# > TAB KHO PHẦN MỀM (Auto load JSON)
$SoftTab = New-Object System.Windows.Forms.TabPage; $SoftTab.Text = "KHO PHẦN MỀM"; $SoftTab.BackColor = $Colors.Dark.FormBack; $TabControl.Controls.Add($SoftTab)
$SoftFlow = New-Object System.Windows.Forms.FlowLayoutPanel; $SoftFlow.Dock="Fill"; $SoftFlow.AutoScroll=$true; $SoftFlow.Padding="20,20,20,20"; $SoftTab.Controls.Add($SoftFlow)

# Load Apps
try {
    $Ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $Data = Invoke-RestMethod -Uri "$($JsonUrl.Trim())?t=$Ts" -Headers @{"User-Agent"="PS";"Cache-Control"="no-cache"} -ErrorAction Stop
    $JsonTabs = $Data | Select -Expand tab -Unique
    foreach ($T in $JsonTabs) {
        $Grp = New-Object System.Windows.Forms.GroupBox; $Grp.Text = $T.ToUpper(); $Grp.Width = 980; $Grp.Height = 10; $Grp.AutoSize = $true; $Grp.ForeColor = $Colors.Dark.Accent; $Grp.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        $InFlow = New-Object System.Windows.Forms.FlowLayoutPanel; $InFlow.Dock="Fill"; $InFlow.AutoSize=$true; $Grp.Controls.Add($InFlow)
        $Apps = $Data | Where {$_.tab -eq $T}
        foreach ($A in $Apps) {
            $Chk = New-Object System.Windows.Forms.CheckBox; $Chk.Text=$A.name; $Chk.Tag=$A; $Chk.AutoSize=$true; $Chk.Margin="10,5,20,5"; $Chk.Font="Segoe UI, 10"; $Chk.ForeColor="White"; $InFlow.Controls.Add($Chk)
        }
        $SoftFlow.Controls.Add($Grp)
    }
} catch { $LblErr = New-Object System.Windows.Forms.Label; $LblErr.Text = "Không tải được danh sách phần mềm!"; $LblErr.AutoSize=$true; $LblErr.ForeColor="Red"; $SoftFlow.Controls.Add($LblErr) }

# --- FOOTER SECTION ---
$PnlFooter = New-Object System.Windows.Forms.Panel; $PnlFooter.Size = "1100, 80"; $PnlFooter.Dock = "Bottom"; $PnlFooter.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
$Form.Controls.Add($PnlFooter)

# Nút Cài đặt (Big Button)
$BtnInstall = New-Object System.Windows.Forms.Button
$BtnInstall.Text = " TIẾN HÀNH CÀI ĐẶT (Đã chọn)"
$BtnInstall.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$BtnInstall.Size = "300, 50"
$BtnInstall.Location = "400, 15"
$BtnInstall.BackColor = $Colors.Dark.Success
$BtnInstall.ForeColor = "Black"
$BtnInstall.FlatStyle = "Flat"
$BtnInstall.Cursor = "Hand"
$BtnInstall.Add_Click({
    $BtnInstall.Enabled=$false; $BtnInstall.Text="ĐANG XỬ LÝ..."
    # Logic cài đặt (Loop qua checkbox)
    foreach($C in $SoftFlow.Controls){ foreach($I in $C.Controls){ foreach($K in $I.Controls){
        if($K -is [System.Windows.Forms.CheckBox] -and $K.Checked){
            $Obj = $K.Tag
            if($Obj.type -eq "Script"){ iex $Obj.irm } else { Tai-Va-Chay $Obj.link $Obj.filename $Obj.type; if($Obj.irm){ iex $Obj.irm } }
            $K.Checked=$false
        }
    }}}
    [System.Windows.Forms.MessageBox]::Show("Đã Xong!", "Thông báo"); $BtnInstall.Text=" TIẾN HÀNH CÀI ĐẶT"; $BtnInstall.Enabled=$true
})
$PnlFooter.Controls.Add($BtnInstall)

# Status Bar
$StatusStrip = New-Object System.Windows.Forms.StatusStrip; $StatusStrip.BackColor = [System.Drawing.Color]::Black; $StatusStrip.ForeColor = "Gray"
$StatusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel; $StatusLabel.Text = "Sẵn sàng phục vụ. PhatTanPC v12.0"; $StatusStrip.Items.Add($StatusLabel)
$Form.Controls.Add($StatusStrip)

# Nút Donate & Credit
$BtnDonate = New-Object System.Windows.Forms.Button; $BtnDonate.Text="☕ DONATE"; $BtnDonate.Location="950,20"; $BtnDonate.Size="100,40"; $BtnDonate.BackColor="Gold"; $BtnDonate.FlatStyle="Flat"; $PnlFooter.Controls.Add($BtnDonate)
$BtnDonate.Add_Click({ $D=New-Object System.Windows.Forms.Form;$D.Size="400,500";$D.StartPosition="CenterScreen";$P=New-Object System.Windows.Forms.PictureBox;$P.Dock="Fill";$P.SizeMode="Zoom";try{$P.Load("https://img.vietqr.io/image/970436-1055835227-print.png?addInfo=Donate%20PhatTanPC&accountName=DANG%20LAM%20TAN%20PHAT")}catch{};$D.Controls.Add($P);$D.ShowDialog() })

# Animation Fade-In
$Form.Opacity = 0
$Form.Add_Load({ 
    $Timer = New-Object System.Windows.Forms.Timer; $Timer.Interval = 20
    $Timer.Add_Tick({ if($Form.Opacity -lt 1){$Form.Opacity+=0.1}else{$Timer.Stop()} })
    $Timer.Start()
})

$Form.ShowDialog() | Out-Null
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
