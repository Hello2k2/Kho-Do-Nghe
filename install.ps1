<#
    TOOL CUU HO MAY TINH - PHAT TAN PC
    Author:  Phat Tan
    Version: 12.2 (Cyberpunk UI & Layout Fix)
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

# --- 3. THEME ENGINE (CYBERPUNK STYLE) ---
$Global:DarkMode = $true

$Colors = @{
    Dark = @{
        FormBack   = [System.Drawing.Color]::FromArgb(15, 15, 20)       # Đen cực sâu
        PanelBack  = [System.Drawing.Color]::FromArgb(30, 30, 35)       # Card nổi nhẹ
        Text       = [System.Drawing.Color]::FromArgb(240, 240, 240)    # Chữ trắng
        Accent     = [System.Drawing.Color]::FromArgb(0, 255, 255)      # Cyan Neon (Màu chủ đạo)
        Secondary  = [System.Drawing.Color]::FromArgb(255, 0, 128)      # Hồng Neon (Điểm nhấn)
        BtnBack    = [System.Drawing.Color]::FromArgb(45, 45, 50)       # Nền nút
        BtnHover   = [System.Drawing.Color]::FromArgb(60, 60, 70)       # Nền nút khi hover
        Success    = [System.Drawing.Color]::FromArgb(0, 255, 127)      # Xanh lá Matrix
    }
}

# --- 4. GRAPHICS FUNCTIONS ---

# Hàm vẽ bo tròn xịn
function Get-RoundedRectPath ($Rect, $Radius) {
    $Path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $Path.AddArc($Rect.X, $Rect.Y, $Radius, $Radius, 180, 90)
    $Path.AddArc($Rect.Right - $Radius, $Rect.Y, $Radius, $Radius, 270, 90)
    $Path.AddArc($Rect.Right - $Radius, $Rect.Bottom - $Radius, $Radius, $Radius, 0, 90)
    $Path.AddArc($Rect.X, $Rect.Bottom - $Radius, $Radius, $Radius, 90, 90)
    $Path.CloseFigure()
    return $Path
}

# Sự kiện vẽ nền Card (Hiệu ứng viền Neon)
$Paint_Card = {
    param($sender, $e)
    $G = $e.Graphics
    $G.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $Rect = $sender.ClientRectangle
    $Rect.Width -= 2; $Rect.Height -= 2; $Rect.X += 1; $Rect.Y += 1
    
    # Vẽ nền
    $Brush = New-Object System.Drawing.SolidBrush($Colors.Dark.PanelBack)
    $Path = Get-RoundedRectPath $Rect 20
    $G.FillPath($Brush, $Path)
    
    # Vẽ viền Neon mờ
    $Pen = New-Object System.Drawing.Pen($Colors.Dark.Accent, 1)
    $G.DrawPath($Pen, $Path)
    
    $Brush.Dispose(); $Pen.Dispose(); $Path.Dispose()
}

# --- 5. CORE LOGIC ---
function Tai-Va-Chay {
    param ($Link, $Name, $Type)
    $StatusLabel.Text = ">> ĐANG TẢI: $Name ..."
    $StatusLabel.ForeColor = "Yellow"
    $Form.Refresh()
    if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }
    if ($Link -notmatch "^http") { $Link = "$BaseUrl$Link" }
    $Dest = "$TempDir\$Name"
    try {
        (New-Object System.Net.WebClient).DownloadFile($Link, $Dest)
        if (Test-Path $Dest) {
            $StatusLabel.Text = ">> ĐANG CHẠY: $Name ..."
            $StatusLabel.ForeColor = "Cyan"
            if ($Type -eq "Msi") { Start-Process "msiexec.exe" "/i `"$Dest`" /quiet /norestart" -Wait } else { Start-Process $Dest -Wait }
            $StatusLabel.Text = ">> HOÀN TẤT: $Name"
            $StatusLabel.ForeColor = "Lime"
        }
    } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi tải file!", "Error"); $StatusLabel.Text = "!! LỖI !!" }
}

function Load-Module ($ScriptName) {
    $StatusLabel.Text = ">> LOADING MODULE: $ScriptName ..."
    $StatusLabel.ForeColor = "Yellow"
    $Form.Refresh()
    if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }
    $LocalPath = "$TempDir\$ScriptName"
    $Ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $Url = "$RawUrl$ScriptName" + "?t=$Ts"
    try {
        $Web = New-Object System.Net.WebClient; $Web.Encoding = [System.Text.Encoding]::UTF8
        $Web.DownloadString($Url) | Out-File -FilePath $LocalPath -Encoding UTF8
        if (Test-Path $LocalPath) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$LocalPath`"" }
        $StatusLabel.Text = ">> MODULE READY: $ScriptName"
        $StatusLabel.ForeColor = "Lime"
    } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi tải Module!", "Lỗi Kết Nối"); $StatusLabel.Text = "!! DISCONNECTED !!" }
}

# --- 6. GUI BUILDER ---

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "PHAT TAN PC TOOLKIT V12.2 - CYBER EDITION"
$Form.Size = New-Object System.Drawing.Size(1200, 850) # Form to rộng
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false
$Form.BackColor = $Colors.Dark.FormBack
$Form.ForeColor = $Colors.Dark.Text

# --- HEADER SECTION ---
$PnlHeader = New-Object System.Windows.Forms.Panel; $PnlHeader.Size = "1200, 90"; $PnlHeader.Dock = "Top"; $PnlHeader.BackColor = [System.Drawing.Color]::Transparent
$Form.Controls.Add($PnlHeader)

$LblLogo = New-Object System.Windows.Forms.Label
$LblLogo.Text = "PHAT TAN PC"
$LblLogo.Font = New-Object System.Drawing.Font("Segoe UI Black", 32, [System.Drawing.FontStyle]::Bold) # Font cực đậm
$LblLogo.ForeColor = $Colors.Dark.Accent
$LblLogo.AutoSize = $true
$LblLogo.Location = "40, 15"
$PnlHeader.Controls.Add($LblLogo)

$LblSub = New-Object System.Windows.Forms.Label
$LblSub.Text = "ULTIMATE RESCUE TOOLKIT v12.2"
$LblSub.Font = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Bold)
$LblSub.ForeColor = $Colors.Dark.Secondary
$LblSub.AutoSize = $true
$LblSub.Location = "50, 65"
$PnlHeader.Controls.Add($LblSub)

# --- MAIN TAB CONTROL ---
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = "20, 100"
$TabControl.Size = "1145, 600"
$TabControl.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$TabControl.Appearance = "FlatButtons"
$TabControl.SizeMode = "Fixed"
$TabControl.ItemSize = New-Object System.Drawing.Size(200, 45)
$Form.Controls.Add($TabControl)

# > TAB ADVANCED
$AdvTab = New-Object System.Windows.Forms.TabPage; $AdvTab.Text = "🛠 SYSTEM TOOLS"; $AdvTab.BackColor = $Colors.Dark.FormBack; $TabControl.Controls.Add($AdvTab)

# GRID LAYOUT (3 CỘT)
$Grid = New-Object System.Windows.Forms.TableLayoutPanel
$Grid.Dock = "Fill"
$Grid.ColumnCount = 3
$Grid.RowCount = 1
$Grid.Padding = New-Object System.Windows.Forms.Padding(15)
$Grid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33.33))) | Out-Null
$Grid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33.33))) | Out-Null
$Grid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33.33))) | Out-Null
$AdvTab.Controls.Add($Grid)

# --- FUNCTION TẠO CỘT (FIXED LAYOUT) ---
function New-GroupCard ($Title, $ColIndex) {
    $Panel = New-Object System.Windows.Forms.Panel
    $Panel.Dock = "Fill"
    $Panel.Margin = New-Object System.Windows.Forms.Padding(15)
    
    # [QUAN TRỌNG] Padding Top 60px để đẩy nút xuống dưới, không bị Title che mất
    $Panel.Padding = New-Object System.Windows.Forms.Padding(2, 60, 2, 2) 
    $Panel.Add_Paint($Paint_Card)
    
    # Title (Nằm đè lên trên Padding)
    $Lbl = New-Object System.Windows.Forms.Label
    $Lbl.Text = $Title.ToUpper()
    $Lbl.AutoSize = $false
    $Lbl.Size = New-Object System.Drawing.Size(300, 40)
    $Lbl.Location = "10, 15" # Vị trí cố định
    $Lbl.TextAlign = "MiddleCenter"
    $Lbl.Font = New-Object System.Drawing.Font("Segoe UI Black", 14, [System.Drawing.FontStyle]::Bold)
    $Lbl.ForeColor = $Colors.Dark.Accent
    $Lbl.BackColor = [System.Drawing.Color]::Transparent
    $Panel.Controls.Add($Lbl)

    # Container cho nút
    $Flow = New-Object System.Windows.Forms.FlowLayoutPanel
    $Flow.Dock = "Fill" # Nó sẽ nằm gọn trong phần Padding đã chừa ra
    $Flow.FlowDirection = "TopDown"
    $Flow.WrapContents = $false
    $Flow.BackColor = [System.Drawing.Color]::Transparent
    $Flow.Padding = New-Object System.Windows.Forms.Padding(10, 0, 10, 10)
    $Flow.AutoScroll = $true 
    
    # Resize nút khi form đổi kích thước
    $Flow.Add_SizeChanged({ foreach($c in $Flow.Controls){ $c.Width = $Flow.Width - 25 } })
    
    $Panel.Controls.Add($Flow)
    $Grid.Controls.Add($Panel, $ColIndex, 0)
    return $Flow
}

function Add-StyledBtn ($Parent, $Text, $SubText, $Cmd, $IconStr) {
    $Btn = New-Object System.Windows.Forms.Button
    $Btn.Text = "  $IconStr  $Text" 
    $Btn.Height = 60 # Nút cao to
    $Btn.Width = 300 
    $Btn.FlatStyle = "Flat"
    $Btn.BackColor = $Colors.Dark.BtnBack
    $Btn.ForeColor = $Colors.Dark.Text
    $Btn.TextAlign = "MiddleLeft"
    $Btn.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 11, [System.Drawing.FontStyle]::Bold)
    $Btn.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 12) # Khoảng cách giữa các nút
    $Btn.Cursor = "Hand"
    $Btn.FlatAppearance.BorderSize = 0
    
    # Hiệu ứng Hover xịn (Thanh màu bên trái)
    $Btn.Add_MouseEnter({ 
        $this.BackColor = $Colors.Dark.BtnHover
        $this.ForeColor = $Colors.Dark.Accent
        $this.FlatAppearance.BorderColor = $Colors.Dark.Accent
        $this.FlatAppearance.BorderSize = 1
        # Giả lập thanh bar bên trái bằng padding
        $this.Padding = New-Object System.Windows.Forms.Padding(10,0,0,0) 
    })
    $Btn.Add_MouseLeave({ 
        $this.BackColor = $Colors.Dark.BtnBack
        $this.ForeColor = $Colors.Dark.Text
        $this.FlatAppearance.BorderSize = 0
        $this.Padding = New-Object System.Windows.Forms.Padding(0,0,0,0)
    })
    $Btn.Add_Click($Cmd)
    
    $Tip = New-Object System.Windows.Forms.ToolTip
    $Tip.SetToolTip($Btn, $SubText)
    
    $Parent.Controls.Add($Btn)
}

# --- CỘT 1: HỆ THỐNG ---
$G1 = New-GroupCard "SYSTEM CORE" 0
Add-StyledBtn $G1 "CHECK INFO" "Xem cấu hình máy" { Load-Module "SystemInfo.ps1" } "ℹ"
Add-StyledBtn $G1 "CLEANER PRO" "Dọn rác sạch sẽ" { Load-Module "SystemCleaner.ps1" } "♻"
Add-StyledBtn $G1 "DISK MANAGER" "Quản lý chia ổ cứng" { Load-Module "DiskManager.ps1" } "💾"
Add-StyledBtn $G1 "SYSTEM SCAN" "Quét lỗi toàn diện" { Load-Module "SystemScan.ps1" } "🔍"
Add-StyledBtn $G1 "RAM BOOSTER" "Giải phóng RAM" { Load-Module "RamBooster.ps1" } "⚡"
Add-StyledBtn $G1 "ACTIVATION" "Kích hoạt bản quyền" { Load-Module "WinActivator.ps1" } "🗝"
Add-StyledBtn $G1 "DATA RECOVERY" "Cứu dữ liệu (DiskGenius)" { Tai-Va-Chay "Disk.Genius.rar" "DiskGenius.rar" "Portable" } "🚑"
Add-StyledBtn $G1 "DEBLOATER" "Gỡ app rác Windows" { Load-Module "Debloater.ps1" } "🗑"

# --- CỘT 2: BẢO MẬT & MẠNG ---
$G2 = New-GroupCard "SECURITY & NET" 1
Add-StyledBtn $G2 "DNS MASTER" "Đổi DNS Google/Cloudflare" { Load-Module "NetworkMaster.ps1" } "🌐"
Add-StyledBtn $G2 "WIN UPDATE" "Bật/Tắt Update" { Load-Module "WinUpdatePro.ps1" } "↻"
Add-StyledBtn $G2 "DEFENDER CTRL" "Bật/Tắt Diệt Virus" { Load-Module "DefenderMgr.ps1" } "🛡"
Add-StyledBtn $G2 "BITLOCKER" "Quản lý khóa ổ cứng" { Load-Module "BitLockerMgr.ps1" } "🔒"
Add-StyledBtn $G2 "BLOCK WEB" "Chặn web đen/quảng cáo" { Load-Module "BrowserPrivacy.ps1" } "⛔"
Add-StyledBtn $G2 "FIREWALL OFF" "Tắt tường lửa chơi game" { netsh advfirewall set allprofiles state off; [System.Windows.Forms.MessageBox]::Show("Firewall OFF!") } "🔥"

# --- CỘT 3: CÔNG CỤ CÀI ĐẶT ---
$G3 = New-GroupCard "DEPLOYMENT" 2
Add-StyledBtn $G3 "ISO DOWNLOAD" "Tải Win/Office Max Speed" { Load-Module "ISODownloader.ps1" } "📥"
Add-StyledBtn $G3 "AUTO INSTALL" "Cài Win tự động" { Load-Module "WinInstall.ps1" } "💿"
Add-StyledBtn $G3 "OFFICE 365" "Cài Office bản quyền" { Load-Module "OfficeInstaller.ps1" } "📝"
Add-StyledBtn $G3 "WIN OPTIMIZE" "Tối ưu hóa Windows" { Load-Module "WinModder.ps1" } "🚀"
Add-StyledBtn $G3 "AIO BUILDER" "Tự đóng gói ISO" { Load-Module "WinAIOBuilder.ps1" } "📦"
Add-StyledBtn $G3 "AI ASSISTANT" "Hỏi đáp lỗi với AI" { Load-Module "GeminiAI.ps1" } "🤖"
Add-StyledBtn $G3 "MS STORE" "Cài Store cho bản LTSC" { Load-Module "StoreInstaller.ps1" } "👜"
Add-StyledBtn $G3 "USB BOOT" "Tạo USB cứu hộ" { Load-Module "UsbBootMaker.ps1" } "⚡"

# > TAB KHO PHẦN MỀM
$SoftTab = New-Object System.Windows.Forms.TabPage; $SoftTab.Text = "📦 SOFTWARE STORE"; $SoftTab.BackColor = $Colors.Dark.FormBack; $TabControl.Controls.Add($SoftTab)
$SoftFlow = New-Object System.Windows.Forms.FlowLayoutPanel; $SoftFlow.Dock="Fill"; $SoftFlow.AutoScroll=$true; $SoftFlow.Padding="20,20,20,20"; $SoftTab.Controls.Add($SoftFlow)

try {
    $Ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $Data = Invoke-RestMethod -Uri "$($JsonUrl.Trim())?t=$Ts" -Headers @{"User-Agent"="PS";"Cache-Control"="no-cache"} -ErrorAction Stop
    $JsonTabs = $Data | Select -Expand tab -Unique
    foreach ($T in $JsonTabs) {
        $Grp = New-Object System.Windows.Forms.GroupBox; $Grp.Text = "  " + $T.ToUpper() + "  "; $Grp.Width = 1050; $Grp.Height = 10; $Grp.AutoSize = $true; $Grp.ForeColor = $Colors.Dark.Accent; $Grp.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $InFlow = New-Object System.Windows.Forms.FlowLayoutPanel; $InFlow.Dock="Fill"; $InFlow.AutoSize=$true; $Grp.Controls.Add($InFlow)
        $Apps = $Data | Where {$_.tab -eq $T}
        foreach ($A in $Apps) {
            $Chk = New-Object System.Windows.Forms.CheckBox; $Chk.Text=$A.name; $Chk.Tag=$A; $Chk.AutoSize=$true; $Chk.Margin="10,5,30,10"; $Chk.Font="Segoe UI", 11; $Chk.ForeColor="White"; $InFlow.Controls.Add($Chk)
        }
        $SoftFlow.Controls.Add($Grp)
    }
} catch { $LblErr = New-Object System.Windows.Forms.Label; $LblErr.Text = "Không kết nối được Server!"; $LblErr.AutoSize=$true; $LblErr.ForeColor="Red"; $SoftFlow.Controls.Add($LblErr) }

# --- FOOTER SECTION ---
$PnlFooter = New-Object System.Windows.Forms.Panel; $PnlFooter.Size = "1200, 90"; $PnlFooter.Dock = "Bottom"; $PnlFooter.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
$Form.Controls.Add($PnlFooter)

$BtnInstall = New-Object System.Windows.Forms.Button
$BtnInstall.Text = "START INSTALLATION"
$BtnInstall.Font = New-Object System.Drawing.Font("Segoe UI Black", 14, [System.Drawing.FontStyle]::Bold)
$BtnInstall.Size = "400, 60"
$BtnInstall.Location = "400, 10" # Center
$BtnInstall.BackColor = $Colors.Dark.Success
$BtnInstall.ForeColor = "Black"
$BtnInstall.FlatStyle = "Flat"
$BtnInstall.Cursor = "Hand"
$BtnInstall.Add_Click({
    $BtnInstall.Enabled=$false; $BtnInstall.Text="PROCESSING..."
    foreach($C in $SoftFlow.Controls){ foreach($I in $C.Controls){ foreach($K in $I.Controls){
        if($K -is [System.Windows.Forms.CheckBox] -and $K.Checked){
            $Obj = $K.Tag
            if($Obj.type -eq "Script"){ iex $Obj.irm } else { Tai-Va-Chay $Obj.link $Obj.filename $Obj.type; if($Obj.irm){ iex $Obj.irm } }
            $K.Checked=$false
        }
    }}}
    [System.Windows.Forms.MessageBox]::Show("All Tasks Completed!", "Success"); $BtnInstall.Text="START INSTALLATION"; $BtnInstall.Enabled=$true
})
$PnlFooter.Controls.Add($BtnInstall)

# Status Bar
$StatusStrip = New-Object System.Windows.Forms.StatusStrip; $StatusStrip.BackColor = [System.Drawing.Color]::Black; $StatusStrip.ForeColor = "Gray"
$StatusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel; $StatusLabel.Text = "READY | PhatTanPC Toolkit v12.2"; $StatusLabel.Font = "Consolas, 10"; $StatusStrip.Items.Add($StatusLabel)
$Form.Controls.Add($StatusStrip)

# Nút Donate & Credit
$BtnDonate = New-Object System.Windows.Forms.Button; $BtnDonate.Text="☕ SUPPORT ME"; $BtnDonate.Location="1000, 20"; $BtnDonate.Size="150, 45"; $BtnDonate.BackColor=$Colors.Dark.Secondary; $BtnDonate.ForeColor="White"; $BtnDonate.FlatStyle="Flat"; $PnlFooter.Controls.Add($BtnDonate)
$BtnDonate.Add_Click({ $D=New-Object System.Windows.Forms.Form;$D.Size="400,500";$D.StartPosition="CenterScreen";$P=New-Object System.Windows.Forms.PictureBox;$P.Dock="Fill";$P.SizeMode="Zoom";try{$P.Load("https://img.vietqr.io/image/970436-1055835227-print.png?addInfo=Donate%20PhatTanPC&accountName=DANG%20LAM%20TAN%20PHAT")}catch{};$D.Controls.Add($P);$D.ShowDialog() })

# Animation Fade-In
$Form.Opacity = 0
$Form.Add_Load({ 
    $Timer = New-Object System.Windows.Forms.Timer; $Timer.Interval = 15
    $Timer.Add_Tick({ if($Form.Opacity -lt 1){$Form.Opacity+=0.08}else{$Timer.Stop()} })
    $Timer.Start()
})

$Form.ShowDialog() | Out-Null
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
