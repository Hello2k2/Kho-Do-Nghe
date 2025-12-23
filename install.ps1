<#
    TOOL CUU HO MAY TINH - PHAT TAN PC
    Author:  Phat Tan
    Version: 12.6 (Full Neon Footer)
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

if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13

# --- 3. THEME ENGINE ---
$Global:IsDarkMode = $true 

$Theme = @{
    Dark = @{
        Back      = [System.Drawing.Color]::FromArgb(25, 25, 30)
        Card      = [System.Drawing.Color]::FromArgb(40, 40, 45)
        Text      = [System.Drawing.Color]::WhiteSmoke
        System    = [System.Drawing.Color]::FromArgb(0, 190, 255)
        Security  = [System.Drawing.Color]::FromArgb(180, 80, 255)
        Install   = [System.Drawing.Color]::FromArgb(50, 230, 130)
        Select    = [System.Drawing.Color]::DeepSkyBlue
        Deselect  = [System.Drawing.Color]::Crimson
    }
    Light = @{
        Back      = [System.Drawing.Color]::FromArgb(245, 245, 250)
        Card      = [System.Drawing.Color]::White
        Text      = [System.Drawing.Color]::Black
        System    = [System.Drawing.Color]::FromArgb(0, 120, 215)
        Security  = [System.Drawing.Color]::FromArgb(138, 43, 226)
        Install   = [System.Drawing.Color]::FromArgb(34, 139, 34)
        Select    = [System.Drawing.Color]::DodgerBlue
        Deselect  = [System.Drawing.Color]::Red
    }
}

$Paint_Glow = {
    param($sender, $e)
    $Color = $sender.Tag 
    if (!$Color) { $Color = [System.Drawing.Color]::Gray }
    $Pen = New-Object System.Drawing.Pen($Color, 5)
    $Rect = $sender.ClientRectangle
    $Rect.X += 2; $Rect.Y += 2; $Rect.Width -= 4; $Rect.Height -= 4
    $e.Graphics.DrawRectangle($Pen, $Rect)
    $Pen.Dispose()
}

function Apply-Theme {
    $T = if ($Global:IsDarkMode) { $Theme.Dark } else { $Theme.Light }
    
    $Form.BackColor = $T.Back; $Form.ForeColor = $T.Text
    $PnlHeader.BackColor = if ($Global:IsDarkMode) { [System.Drawing.Color]::FromArgb(35,35,40) } else { [System.Drawing.Color]::FromArgb(230,230,230) }
    $BtnTheme.Text = if ($Global:IsDarkMode) { "☀ LIGHT MODE" } else { "🌙 DARK MODE" }
    $BtnTheme.BackColor = if ($Global:IsDarkMode) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::Black }
    $BtnTheme.ForeColor = if ($Global:IsDarkMode) { [System.Drawing.Color]::Black } else { [System.Drawing.Color]::White }

    foreach ($P in $TabControl.TabPages) {
        $P.BackColor = $T.Back; $P.ForeColor = $T.Text
        foreach ($C in $P.Controls) {
            if ($C -is [System.Windows.Forms.Panel] -and $C.Name -like "Card*") {
                $C.BackColor = $T.Card
                $GroupColor = $T.System
                if ($C.Name -match "SECURITY") { $GroupColor = $T.Security }
                if ($C.Name -match "INSTALL") { $GroupColor = $T.Install }
                
                $C.Tag = $GroupColor; $C.Invalidate()
                foreach ($Child in $C.Controls) {
                    if ($Child -is [System.Windows.Forms.Label]) { $Child.ForeColor = $GroupColor }
                    if ($Child -is [System.Windows.Forms.FlowLayoutPanel]) {
                        foreach ($Btn in $Child.Controls) {
                            $Btn.BackColor = $GroupColor; $Btn.ForeColor = "White"; $Btn.Tag = $GroupColor
                        }
                    }
                }
            }
            if ($C -is [System.Windows.Forms.FlowLayoutPanel]) {
                foreach ($Chk in $C.Controls) { $Chk.ForeColor = $T.Text }
            }
        }
    }
}

# --- 4. ANIMATION & HOVER ---
function Start-FadeIn {
    $Form.Opacity = 0
    $Script:AnimTimer = New-Object System.Windows.Forms.Timer; $Script:AnimTimer.Interval = 10
    $Script:AnimTimer.Add_Tick({
        try { $Form.Opacity += 0.08; if ($Form.Opacity -ge 1) { $Form.Opacity = 1; $Script:AnimTimer.Stop() } } catch { $Form.Opacity = 1; $Script:AnimTimer.Stop() }
    })
    $Script:AnimTimer.Start()
}

function Add-HoverEffect ($Btn) {
    $Btn.Add_MouseEnter({ $this.BackColor = [System.Windows.Forms.ControlPaint]::Light($this.Tag, 0.6) })
    $Btn.Add_MouseLeave({ $this.BackColor = $this.Tag })
}

# --- 5. CORE FUNCTIONS ---
function Tai-Va-Chay {
    param ($Link, $Name, $Type)
    if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }
    if ($Link -notmatch "^http") { $Link = "$BaseUrl$Link" }
    $Dest = "$TempDir\$Name"
    try {
        $Web = New-Object System.Net.WebClient; $Web.Headers.Add("User-Agent", "Mozilla/5.0")
        $Web.DownloadFile($Link, $Dest)
        if (Test-Path $Dest) {
            if ($Type -eq "Msi") { Start-Process "msiexec.exe" "/i `"$Dest`" /quiet /norestart" -Wait } else { Start-Process $Dest -Wait }
        }
    } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi tải file: $Name", "Error") }
}

function Load-Module ($ScriptName) {
    if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }
    $LocalPath = "$TempDir\$ScriptName"
    try {
        $Web = New-Object System.Net.WebClient; $Web.Headers.Add("User-Agent", "Mozilla/5.0"); $Web.Encoding = [System.Text.Encoding]::UTF8
        $Content = $Web.DownloadString("$RawUrl$ScriptName`?t=$(Get-Date -UFormat %s)")
        [System.IO.File]::WriteAllText($LocalPath, $Content, [System.Text.UTF8Encoding]$true)
        if (Test-Path $LocalPath) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$LocalPath`"" }
    } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi tải Module: $ScriptName", "Lỗi Mạng") }
}

# --- 6. GUI CONSTRUCTION ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "PHAT TAN PC TOOLKIT V12.6 (NEON FOOTER)"
$Form.Size = New-Object System.Drawing.Size(1080, 780)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false; $Form.Opacity = 0

# Header
$PnlHeader = New-Object System.Windows.Forms.Panel; $PnlHeader.Size="1080, 80"; $PnlHeader.Location="0,0"; $Form.Controls.Add($PnlHeader)
$LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text="PHAT TAN PC TOOLKIT"; $LblTitle.Font="Segoe UI, 24, Bold"; $LblTitle.AutoSize=$true; $LblTitle.Location="20,15"; $LblTitle.ForeColor=[System.Drawing.Color]::DeepSkyBlue; $PnlHeader.Controls.Add($LblTitle)
$LblSub = New-Object System.Windows.Forms.Label; $LblSub.Text="Professional IT Solutions"; $LblSub.ForeColor="Gray"; $LblSub.AutoSize=$true; $LblSub.Font="Segoe UI, 10, Italic"; $LblSub.Location="25,60"; $PnlHeader.Controls.Add($LblSub)

# Theme Button
$BtnTheme = New-Object System.Windows.Forms.Button; $BtnTheme.Location="900, 25"; $BtnTheme.Size="140, 35"; $BtnTheme.FlatStyle="Flat"; $BtnTheme.Font="Segoe UI, 9, Bold"; $BtnTheme.Cursor="Hand"
$BtnTheme.Add_Click({ $Global:IsDarkMode = -not $Global:IsDarkMode; Apply-Theme })
$PnlHeader.Controls.Add($BtnTheme)

# MAIN TAB
$TabControl = New-Object System.Windows.Forms.TabControl; $TabControl.Location="20,90"; $TabControl.Size="1020,520"; $TabControl.Font="Segoe UI, 10, Bold"
$TabControl.Multiline = $true; $TabControl.SizeMode = [System.Windows.Forms.TabSizeMode]::FillToRight; $TabControl.Padding = New-Object System.Drawing.Point(20, 5); $TabControl.ItemSize = New-Object System.Drawing.Size(0, 40)
$Form.Controls.Add($TabControl)

# > TAB 1: DASHBOARD
$AdvTab = New-Object System.Windows.Forms.TabPage; $AdvTab.Text = " DASHBOARD "; $AdvTab.AutoScroll = $true; $TabControl.Controls.Add($AdvTab)

function Add-Card ($Title, $NameID, $X, $Y, $W, $H) {
    $P = New-Object System.Windows.Forms.Panel; $P.Name = "Card_$NameID"; $P.Location = "$X,$Y"; $P.Size = "$W,$H"; $P.Padding = "7,7,7,7"
    $P.Add_Paint($Paint_Glow) # Glow Effect
    $L = New-Object System.Windows.Forms.Label; $L.Text=$Title; $L.Location="15,15"; $L.AutoSize=$true; $L.Font="Segoe UI, 13, Bold"; $P.Controls.Add($L)
    $F = New-Object System.Windows.Forms.FlowLayoutPanel; $F.Location="5,50"; $F.Size="$($W-10),$($H-60)"; $F.FlowDirection="TopDown"; $F.WrapContents=$true; $F.Padding="5,0,0,0"; $P.Controls.Add($F)
    $AdvTab.Controls.Add($P); return $F
}

function Add-Btn ($Panel, $Txt, $Cmd, $BaseColor) {
    $B = New-Object System.Windows.Forms.Button; $B.Text=$Txt; $B.Size="140,45"; $B.FlatStyle="Flat"; $B.Font="Segoe UI, 9, Bold"; $B.Margin="5,5,5,5"; $B.Cursor="Hand"
    $B.FlatAppearance.BorderSize = 0; $B.Add_Click($Cmd); Add-HoverEffect $B; $Panel.Controls.Add($B)
}

# COLUMNS
$P1 = Add-Card "HỆ THỐNG" "SYSTEM" 15 20 320 400
$ColSys = $Theme.Dark.System
Add-Btn $P1 "ℹ KIỂM TRA CẤU HÌNH"      { Load-Module "SystemInfo.ps1" } $ColSys
Add-Btn $P1 "♻ DỌN RÁC MÁY TÍNH"       { Load-Module "SystemCleaner.ps1" } $ColSys
Add-Btn $P1 "💾 QUẢN LÝ Ổ ĐĨA"    { Load-Module "DiskManager.ps1" } $ColSys
Add-Btn $P1 "🔍 QUÉT LỖI WINDOWS"     { Load-Module "SystemScan.ps1" } $ColSys
Add-Btn $P1 "⚡ TỐI ƯU RAM"       { Load-Module "RamBooster.ps1" } $ColSys
Add-Btn $P1 "🗝 KÍCH HOẠT BẢN QUYỀN"    { Load-Module "WinActivator.ps1" } $ColSys
Add-Btn $P1 "🚑 CỨU DỮ LIỆU(HDD)"      { Tai-Va-Chay "Disk.Genius.rar" "DiskGenius.rar" "Portable" } $ColSys
Add-Btn $P1 "🗑 GỠ APP RÁC"       { Load-Module "Debloater.ps1" } $ColSys

$P2 = Add-Card "BẢO MẬT" "SECURITY" 350 20 320 400
$ColSec = $Theme.Dark.Security
Add-Btn $P2 "🌐 ĐỔI DNS SIÊU TỐC"    { Load-Module "NetworkMaster.ps1" } $ColSec
Add-Btn $P2 "↻ QUẢN LÝ UPDATE"    { Load-Module "WinUpdatePro.ps1" } $ColSec
Add-Btn $P2 "🛡 DEFENDER ON/OFF"  { Load-Module "DefenderMgr.ps1" } $ColSec
Add-Btn $P2 "🛡 VÔ HIỆU HÓA EFSs"  { Load-Module "AntiEFS_GUI.ps1" } $ColSec
Add-Btn $P2 "🔒 KHÓA Ổ CỨNG (BITLOCKER)"  { Load-Module "BitLockerMgr.ps1" } $ColSec
Add-Btn $P2 "⛔ CHẶN WEB ĐỘC"     { Load-Module "BrowserPrivacy.ps1" } $ColSec
Add-Btn $P2 "🔥 TẮT TƯỜNG LỬA"    { netsh advfirewall set allprofiles state off; [System.Windows.Forms.MessageBox]::Show("Đã Tắt Firewall!") } $ColSec

$P3 = Add-Card "CÀI ĐẶT" "INSTALL" 685 20 320 400
$ColInst = $Theme.Dark.Install
Add-Btn $P3 "💿 CÀI WIN TỰ ĐỘNG"     { Load-Module "WinInstall.ps1" } $ColInst
Add-Btn $P3 "📝 CÀI OFFICE 365"   { Load-Module "OfficeInstaller.ps1" } $ColInst
Add-Btn $P3 "🔧 TỐI ƯU HÓA WIN"       { Load-Module "WinModder.ps1" } $ColInst
Add-Btn $P3 "📦 ĐÓNG GÓI ISO"     { Load-Module "WinAIOBuilder.ps1" } $ColInst
Add-Btn $P3 "🤖 TRỢ LÝ AI"        { Load-Module "GeminiAI.ps1" } $ColInst
Add-Btn $P3 "👜 CÀI STORE"        { Load-Module "StoreInstaller.ps1" } $ColInst
Add-Btn $P3 "📥 TẢI ISO GỐC"      { Load-Module "ISODownloader.ps1" } $ColInst
Add-Btn $P3 "⚡ TẠO USB BOOT"      { Load-Module "UsbBootMaker.ps1" } $ColInst
Add-Btn $P3 "🛒 KHO ỨNG DỤNG"     { Load-Module "AppStore.ps1" } $ColInst

# > TAB 2: KHO ỨNG DỤNG
try {
    $Ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $Data = Invoke-RestMethod -Uri "$($JsonUrl.Trim())?t=$Ts" -Headers @{"User-Agent"="PS"} -ErrorAction Stop
} catch { $Data = @() }

$JsonTabs = $Data | Select -Expand tab -Unique
foreach ($T in $JsonTabs) {
    $Page = New-Object System.Windows.Forms.TabPage; $Page.Text = " " + $T.ToUpper() + " "; $Page.AutoScroll = $true; $TabControl.Controls.Add($Page)
    $Flow = New-Object System.Windows.Forms.FlowLayoutPanel; $Flow.Dock="Fill"; $Flow.AutoScroll=$true; $Flow.Padding="20,20,20,20"; $Page.Controls.Add($Flow)
    $Apps = $Data | Where {$_.tab -eq $T}
    foreach ($A in $Apps) {
        $Chk = New-Object System.Windows.Forms.CheckBox; $Chk.Text=$A.name; $Chk.Tag=$A; $Chk.AutoSize=$true; $Chk.Margin="10,10,20,10"; $Chk.Font="Segoe UI, 11"; $Flow.Controls.Add($Chk)
    }
}

# --- FOOTER ---
$PnlFooter = New-Object System.Windows.Forms.Panel; $PnlFooter.Location="0,620"; $PnlFooter.Size="1080,120"; $PnlFooter.BackColor=[System.Drawing.Color]::FromArgb(25, 25, 30); $Form.Controls.Add($PnlFooter)

# Function tạo nút Neon ở Footer
function Add-NeonFooterBtn ($Parent, $Text, $X, $Y, $W, $H, $Color, $Cmd) {
    # 1. Tạo Panel bọc ngoài để vẽ viền Glow
    $P = New-Object System.Windows.Forms.Panel
    $P.Location = "$X,$Y"; $P.Size = "$W,$H"
    $P.Tag = $Color # Màu cho viền
    $P.Add_Paint($Paint_Glow)
    $P.Padding = "7,7,7,7" # Chừa chỗ cho viền
    
    # 2. Tạo Button bên trong
    $B = New-Object System.Windows.Forms.Button
    $B.Text = $Text
    $B.Dock = "Fill" # Lấp đầy Panel
    $B.FlatStyle = "Flat"
    $B.FlatAppearance.BorderSize = 0
    $B.BackColor = $Color
    $B.ForeColor = "White"
    $B.Font = "Segoe UI, 10, Bold"
    $B.Cursor = "Hand"
    $B.Tag = $Color # Màu cho Hover
    
    $B.Add_Click($Cmd)
    Add-HoverEffect $B # Hiệu ứng sáng khi hover
    
    $P.Controls.Add($B)
    $Parent.Controls.Add($P)
    return $B
}

# 1. Nút Chọn Hết (Màu Xanh Cyan - System)
$ColAll = $Theme.Dark.Select
Add-NeonFooterBtn $PnlFooter "CHỌN HẾT" 30 20 140 50 $ColAll { 
    foreach($P in $TabControl.TabPages){ foreach($F in $P.Controls){ foreach($C in $F.Controls){ if($C -is [System.Windows.Forms.CheckBox]){$C.Checked=$true} } } } 
}

# 2. Nút Bỏ Chọn (Màu Đỏ - Deselect)
$ColNone = $Theme.Dark.Deselect
Add-NeonFooterBtn $PnlFooter "BỎ CHỌN" 190 20 140 50 $ColNone { 
    foreach($P in $TabControl.TabPages){ foreach($F in $P.Controls){ foreach($C in $F.Controls){ if($C -is [System.Windows.Forms.CheckBox]){$C.Checked=$false} } } } 
}

# 3. Nút Cài Đặt (Màu Xanh Lá - Install)
$BtnInstall = Add-NeonFooterBtn $PnlFooter "TIẾN HÀNH CÀI ĐẶT" 380 15 350 60 $Theme.Dark.Install {
    $BtnInstall.Enabled=$false; $BtnInstall.Text="ĐANG XỬ LÝ..."
    foreach($P in $TabControl.TabPages){ foreach($F in $P.Controls){ foreach($C in $F.Controls){
        if($C -is [System.Windows.Forms.CheckBox] -and $C.Checked){
            $I = $C.Tag
            if($I.type -eq "Script"){ iex $I.irm } else { Tai-Va-Chay $I.link $I.filename $I.type; if($I.irm){ iex $I.irm } }
            $C.Checked=$false
        }
    }}}
    [System.Windows.Forms.MessageBox]::Show("Đã hoàn tất!", "Thông Báo"); $BtnInstall.Text="TIẾN HÀNH CÀI ĐẶT"; $BtnInstall.Enabled=$true
}

# --- NÚT DONATE & CREDITS (Giữ nguyên style cũ cho gọn) ---
$BtnDonate = New-Object System.Windows.Forms.Button; $BtnDonate.Text="☕ DONATE"; $BtnDonate.Location="900,20"; $BtnDonate.Size="120,45"; $BtnDonate.BackColor="Gold"; $BtnDonate.ForeColor="Black"; $BtnDonate.FlatStyle="Flat"; $BtnDonate.Font="Segoe UI, 10, Bold"
$BtnDonate.Add_Click({ 
    $D=New-Object System.Windows.Forms.Form;$D.Size="400,500";$D.StartPosition="CenterScreen";$P=New-Object System.Windows.Forms.PictureBox;$P.Dock="Fill";$P.SizeMode="Zoom"
    try{$P.Load("https://img.vietqr.io/image/970436-1055835227-print.png?addInfo=Donate%20PhatTanPC&accountName=DANG%20LAM%20TAN%20PHAT")}catch{};$D.Controls.Add($P);$D.ShowDialog() 
}); $PnlFooter.Controls.Add($BtnDonate)

$BtnCredit = New-Object System.Windows.Forms.Button; $BtnCredit.Text="ℹ TÁC GIẢ"; $BtnCredit.Location="770,20"; $BtnCredit.Size="120,45"; $BtnCredit.BackColor="DarkSlateBlue"; $BtnCredit.ForeColor="White"; $BtnCredit.FlatStyle="Flat"; $BtnCredit.Font="Segoe UI, 10, Bold"
$BtnCredit.Add_Click({
    [System.Windows.Forms.MessageBox]::Show("PHAT TAN PC TOOLKIT - 12.6 NEON FOOTER`n`nPhát triển bởi: PHÁT TẤN PC`nLiên hệ Zalo: 0823.883.028", "THÔNG TIN")
}); $PnlFooter.Controls.Add($BtnCredit)

Apply-Theme; $Form.Add_Load({ Start-FadeIn }); $Form.ShowDialog() | Out-Null
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
