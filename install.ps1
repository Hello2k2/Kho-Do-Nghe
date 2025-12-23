<#
    TOOL CUU HO MAY TINH - PHAT TAN PC
    Author:  Phat Tan
    Version: 11.7 Final (Classic Horizontal Tabs)
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

# Tao folder lan dau
if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }

# Fix TLS & SSL
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13

# --- 3. THEME ENGINE ---
$Global:DarkMode = $true 

$Theme = @{
    Dark = @{
        Back      = [System.Drawing.Color]::FromArgb(30, 30, 30)
        Card      = [System.Drawing.Color]::FromArgb(45, 45, 48)
        Text      = [System.Drawing.Color]::FromArgb(240, 240, 240)
        BtnBack   = [System.Drawing.Color]::FromArgb(60, 60, 60)
        BtnHover  = [System.Drawing.Color]::FromArgb(80, 80, 80)
        Accent    = [System.Drawing.Color]::FromArgb(0, 255, 255)
    }
    Light = @{
        Back      = [System.Drawing.Color]::FromArgb(245, 245, 245)
        Card      = [System.Drawing.Color]::White
        Text      = [System.Drawing.Color]::FromArgb(30, 30, 30)
        BtnBack   = [System.Drawing.Color]::FromArgb(230, 230, 230)
        BtnHover  = [System.Drawing.Color]::FromArgb(210, 210, 210)
        Accent    = [System.Drawing.Color]::FromArgb(0, 120, 215)
    }
}

function Apply-Theme {
    $T = if ($Global:DarkMode) { $Theme.Dark } else { $Theme.Light }
    
    $Form.BackColor = $T.Back; $Form.ForeColor = $T.Text
    $LblTitle.ForeColor = $T.Accent
    
    foreach ($P in $TabControl.TabPages) {
        $P.BackColor = $T.Back; $P.ForeColor = $T.Text
        foreach ($C in $P.Controls) {
            if ($C -is [System.Windows.Forms.Panel] -and $C.Name -like "Card*") {
                $C.BackColor = $T.Card
                foreach ($Child in $C.Controls) {
                    if ($Child -is [System.Windows.Forms.Label]) { $Child.ForeColor = $T.Accent }
                    if ($Child -is [System.Windows.Forms.FlowLayoutPanel]) {
                        foreach ($Btn in $Child.Controls) {
                            $Btn.BackColor = $T.BtnBack; $Btn.ForeColor = $T.Text
                            $Btn.Tag = @{ BaseColor = $T.BtnBack; HoverColor = $T.BtnHover }
                        }
                    }
                }
            }
            if ($C -is [System.Windows.Forms.FlowLayoutPanel]) {
                foreach ($Chk in $C.Controls) { $Chk.ForeColor = $T.Text }
            }
        }
    }
    $BtnTheme.Text = if ($Global:DarkMode) { "☀ SÁNG" } else { "🌙 TỐI" }
    $BtnTheme.BackColor = if ($Global:DarkMode) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::Black }
    $BtnTheme.ForeColor = if ($Global:DarkMode) { [System.Drawing.Color]::Black } else { [System.Drawing.Color]::White }
}

# --- 4. ANIMATION ---
function Start-FadeIn {
    $Form.Opacity = 0
    $Script:AnimTimer = New-Object System.Windows.Forms.Timer
    $Script:AnimTimer.Interval = 15
    $Script:AnimTimer.Add_Tick({
        try {
            $Form.Opacity += 0.08
            if ($Form.Opacity -ge 1) { 
                $Form.Opacity = 1; $Script:AnimTimer.Stop(); $Script:AnimTimer.Dispose()
            }
        } catch { $Form.Opacity = 1; $Script:AnimTimer.Stop() }
    })
    $Script:AnimTimer.Start()
}

function Add-HoverEffect ($Btn) {
    $Btn.Add_MouseEnter({ try { $this.BackColor = $this.Tag.HoverColor } catch {} })
    $Btn.Add_MouseLeave({ try { $this.BackColor = $this.Tag.BaseColor } catch {} })
}

# --- 5. CORE FUNCTIONS ---
function Tai-Va-Chay {
    param ($Link, $Name, $Type)
    if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }
    if ($Link -notmatch "^http") { $Link = "$BaseUrl$Link" }
    $Dest = "$TempDir\$Name"
    
    try {
        (New-Object System.Net.WebClient).DownloadFile($Link, $Dest)
        if (Test-Path $Dest) {
            if ($Type -eq "Msi") { Start-Process "msiexec.exe" "/i `"$Dest`" /quiet /norestart" -Wait }
            else { Start-Process $Dest -Wait }
        }
    } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi tải file: $Name", "Error") }
}

function Load-Module ($ScriptName) {
    if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }
    $LocalPath = "$TempDir\$ScriptName"
    $Ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $Url = "$RawUrl$ScriptName" + "?t=$Ts"
    
    try {
        $WebClient = New-Object System.Net.WebClient; $WebClient.Encoding = [System.Text.Encoding]::UTF8
        $Content = $WebClient.DownloadString($Url)
        $Stream = [System.IO.StreamWriter]::new($LocalPath, $false, [System.Text.Encoding]::UTF8)
        $Stream.Write($Content); $Stream.Close()
        if (Test-Path $LocalPath) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$LocalPath`"" }
    } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi tải Module: $ScriptName", "Lỗi Mạng") }
}

# --- 6. GUI CONSTRUCTION ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "PHAT TAN PC TOOLKIT V11.7 (CLASSIC)"
$Form.Size = New-Object System.Drawing.Size(1050, 750)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false; $Form.Opacity = 0

# Header
$LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text="PHAT TAN PC TOOLKIT"; $LblTitle.Font="Segoe UI, 22, Bold"; $LblTitle.AutoSize=$true; $LblTitle.Location="20,10"; $Form.Controls.Add($LblTitle)
$LblSub = New-Object System.Windows.Forms.Label; $LblSub.Text="BỘ CÔNG CỤ CỨU HỘ MÁY TÍNH CHUYÊN NGHIỆP"; $LblSub.ForeColor="Gray"; $LblSub.AutoSize=$true; $LblSub.Location="25,55"; $Form.Controls.Add($LblSub)
$BtnTheme = New-Object System.Windows.Forms.Button; $BtnTheme.Location="900,20"; $BtnTheme.Size="100,35"; $BtnTheme.FlatStyle="Flat"
$BtnTheme.Add_Click({ $Global:DarkMode = -not $Global:DarkMode; Apply-Theme })
$Form.Controls.Add($BtnTheme)

# MAIN TAB CONTROL (TAB NGANG)
$TabControl = New-Object System.Windows.Forms.TabControl; $TabControl.Location="20,95"; $TabControl.Size="990,480"; $TabControl.Font="Segoe UI, 10, Bold"
$TabControl.SizeMode=[System.Windows.Forms.TabSizeMode]::Fixed; $TabControl.ItemSize=New-Object System.Drawing.Size(150, 35)
$Form.Controls.Add($TabControl)

# > TAB 1: CÔNG CỤ CHUYÊN SÂU
$AdvTab = New-Object System.Windows.Forms.TabPage; $AdvTab.Text = " CÔNG CỤ CHUYÊN SÂU "; $AdvTab.AutoScroll = $true; $TabControl.Controls.Add($AdvTab)

function Add-Card ($Title, $X, $Y, $W, $H) {
    $P = New-Object System.Windows.Forms.Panel; $P.Name = "Card_$Title"; $P.Location = "$X,$Y"; $P.Size = "$W,$H"; $P.Padding = "1,1,1,1"
    $L = New-Object System.Windows.Forms.Label; $L.Text=$Title; $L.Location="15,15"; $L.AutoSize=$true; $L.Font="Segoe UI, 12, Bold"; $P.Controls.Add($L)
    $F = New-Object System.Windows.Forms.FlowLayoutPanel; $F.Location="2,50"; $F.Size="$($W-4),$($H-52)"; $F.FlowDirection="TopDown"; $F.WrapContents=$true; $F.Padding="10,0,0,0"; $P.Controls.Add($F)
    $AdvTab.Controls.Add($P); return $F
}

function Add-Btn ($Panel, $Txt, $Cmd) {
    $B = New-Object System.Windows.Forms.Button; $B.Text=$Txt; $B.Size="140,45"; $B.FlatStyle="Flat"; $B.Font="Segoe UI, 9"; $B.Margin="5,5,5,5"; $B.Cursor="Hand"
    $B.Add_Click($Cmd); Add-HoverEffect $B; $Panel.Controls.Add($B)
}

# --- CỘT 1: HỆ THỐNG & BẢO TRÌ ---
$P1 = Add-Card "HỆ THỐNG & BẢO TRÌ" 15 20 315 400
Add-Btn $P1 "ℹ KIỂM TRA CẤU HÌNH"   { Load-Module "SystemInfo.ps1" }
Add-Btn $P1 "♻ DỌN RÁC MÁY TÍNH"    { Load-Module "SystemCleaner.ps1" }
Add-Btn $P1 "💾 QUẢN LÝ Ổ ĐĨA"      { Load-Module "DiskManager.ps1" }
Add-Btn $P1 "🔍 QUÉT LỖI WINDOWS"   { Load-Module "SystemScan.ps1" }
Add-Btn $P1 "⚡ TỐI ƯU RAM"          { Load-Module "RamBooster.ps1" }
Add-Btn $P1 "🗝 KÍCH HOẠT BẢN QUYỀN"{ Load-Module "WinActivator.ps1" }
Add-Btn $P1 "🚑 CỨU DỮ LIỆU (HDD)"  { Tai-Va-Chay "Disk.Genius.rar" "DiskGenius.rar" "Portable" }
Add-Btn $P1 "🗑 GỠ APP RÁC"         { Load-Module "Debloater.ps1" }

# --- CỘT 2: BẢO MẬT & MẠNG ---
$P2 = Add-Card "BẢO MẬT & MẠNG" 340 20 315 400
Add-Btn $P2 "🌐 ĐỔI DNS SIÊU TỐC"   { Load-Module "NetworkMaster.ps1" }
Add-Btn $P2 "↻ QUẢN LÝ UPDATE"      { Load-Module "WinUpdatePro.ps1" }
Add-Btn $P2 "🛡 DIỆT VIRUS (ON/OFF)"{ Load-Module "DefenderMgr.ps1" }
Add-Btn $P2 "🔒 KHÓA Ổ CỨNG (BIT)"  { Load-Module "BitLockerMgr.ps1" }
Add-Btn $P2 "⛔ CHẶN WEB ĐỘC"       { Load-Module "BrowserPrivacy.ps1" }
Add-Btn $P2 "🔥 TẮT TƯỜNG LỬA"      { netsh advfirewall set allprofiles state off; [System.Windows.Forms.MessageBox]::Show("Đã Tắt Tường Lửa!", "Thông Báo") }

# --- CỘT 3: CÀI ĐẶT & TIỆN ÍCH ---
$P3 = Add-Card "TRIỂN KHAI & TIỆN ÍCH" 665 20 315 400
Add-Btn $P3 "💿 CÀI WIN TỰ ĐỘNG"    { Load-Module "WinInstall.ps1" }
Add-Btn $P3 "📝 CÀI OFFICE 365"     { Load-Module "OfficeInstaller.ps1" }
Add-Btn $P3 "🔧 TỐI ƯU HÓA WIN"     { Load-Module "WinModder.ps1" }
Add-Btn $P3 "📦 ĐÓNG GÓI ISO"       { Load-Module "WinAIOBuilder.ps1" }
Add-Btn $P3 "🤖 TRỢ LÝ AI (GEMINI)" { Load-Module "GeminiAI.ps1" }
Add-Btn $P3 "👜 CÀI STORE (LTSC)"   { Load-Module "StoreInstaller.ps1" }
Add-Btn $P3 "📥 TẢI ISO GỐC"        { Load-Module "ISODownloader.ps1" }
Add-Btn $P3 "☁ SAO LƯU DỮ LIỆU"     { Load-Module "BackupCenter.ps1" }
Add-Btn $P3 "⚡ TẠO USB BOOT"        { Load-Module "UsbBootMaker.ps1" }
Add-Btn $P3 "🛒 KHO ỨNG DỤNG"       { Load-Module "AppStore.ps1" }

# > TAB 2: KHO PHẦN MỀM (JSON)
try {
    $Ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $Data = Invoke-RestMethod -Uri "$($JsonUrl.Trim())?t=$Ts" -Headers @{"User-Agent"="PS";"Cache-Control"="no-cache"} -ErrorAction Stop
} catch { $Data = @() }

$JsonTabs = $Data | Select -Expand tab -Unique
foreach ($T in $JsonTabs) {
    $TabName = $T.Replace("Softwares","PHẦN MỀM").Replace("Drivers","DRIVER").Replace("Office","VĂN PHÒNG")
    $Page = New-Object System.Windows.Forms.TabPage; $Page.Text = " $TabName "; $Page.AutoScroll = $true; $TabControl.Controls.Add($Page)
    $Flow = New-Object System.Windows.Forms.FlowLayoutPanel; $Flow.Dock="Fill"; $Flow.AutoScroll=$true; $Flow.Padding="20,20,20,20"; $Page.Controls.Add($Flow)
    $Apps = $Data | Where {$_.tab -eq $T}
    foreach ($A in $Apps) {
        $Chk = New-Object System.Windows.Forms.CheckBox; $Chk.Text=$A.name; $Chk.Tag=$A; $Chk.AutoSize=$true; $Chk.Margin="10,10,20,10"; $Chk.Font="Segoe UI, 11"; $Flow.Controls.Add($Chk)
    }
}

# --- FOOTER ---
$PnlFooter = New-Object System.Windows.Forms.Panel; $PnlFooter.Location="0,590"; $PnlFooter.Size="1050,120"; $PnlFooter.BackColor=[System.Drawing.Color]::Transparent; $Form.Controls.Add($PnlFooter)

$BtnAll = New-Object System.Windows.Forms.Button; $BtnAll.Text="CHỌN TẤT CẢ"; $BtnAll.Location="30,10"; $BtnAll.Size="120,40"; $BtnAll.FlatStyle="Flat"
$BtnAll.Add_Click({ foreach($P in $TabControl.TabPages){ foreach($F in $P.Controls){ foreach($C in $F.Controls){ if($C -is [System.Windows.Forms.CheckBox]){$C.Checked=$true} } } } }); $PnlFooter.Controls.Add($BtnAll)

$BtnNone = New-Object System.Windows.Forms.Button; $BtnNone.Text="BỎ CHỌN"; $BtnNone.Location="160,10"; $BtnNone.Size="120,40"; $BtnNone.FlatStyle="Flat"
$BtnNone.Add_Click({ foreach($P in $TabControl.TabPages){ foreach($F in $P.Controls){ foreach($C in $F.Controls){ if($C -is [System.Windows.Forms.CheckBox]){$C.Checked=$false} } } } }); $PnlFooter.Controls.Add($BtnNone)

$BtnInstall = New-Object System.Windows.Forms.Button; $BtnInstall.Text="TIẾN HÀNH CÀI ĐẶT ĐÃ CHỌN"; $BtnInstall.Font="Segoe UI, 13, Bold"; $BtnInstall.Location="360,10"; $BtnInstall.Size="320,60"; $BtnInstall.BackColor="LimeGreen"; $BtnInstall.ForeColor="Black"; $BtnInstall.FlatStyle="Flat"; $BtnInstall.Cursor="Hand"
Add-HoverEffect $BtnInstall
$BtnInstall.Add_Click({
    $BtnInstall.Enabled=$false; $BtnInstall.Text="ĐANG XỬ LÝ..."
    foreach($P in $TabControl.TabPages){ 
        foreach($F in $P.Controls){ 
            foreach($C in $F.Controls){
                if($C -is [System.Windows.Forms.CheckBox] -and $C.Checked){
                    $I = $C.Tag
                    if($I.type -eq "Script"){ iex $I.irm } else { Tai-Va-Chay $I.link $I.filename $I.type; if($I.irm){ iex $I.irm } }
                    $C.Checked=$false
                }
            }
        } 
    }
    [System.Windows.Forms.MessageBox]::Show("Đã hoàn thành!", "Thông Báo"); $BtnInstall.Text="TIẾN HÀNH CÀI ĐẶT ĐÃ CHỌN"; $BtnInstall.Enabled=$true
}); $PnlFooter.Controls.Add($BtnInstall)

# --- NÚT GHI CÔNG & DONATE ---
$BtnPe = New-Object System.Windows.Forms.Button; $BtnPe.Text="⚡ VÀO WINPE"; $BtnPe.Location="750,10"; $BtnPe.Size="120,35"; $BtnPe.BackColor="Orange"; $BtnPe.ForeColor="Black"; $BtnPe.FlatStyle="Flat"
#$BtnPe.Add_Click({ Tai-Va-Chay "WinPE_CuuHo.exe" "WinPE_Setup.exe" "Portable" }); $PnlFooter.Controls.Add($BtnPe)

$BtnDonate = New-Object System.Windows.Forms.Button; $BtnDonate.Text="☕ ỦNG HỘ"; $BtnDonate.Location="880,10"; $BtnDonate.Size="120,35"; $BtnDonate.BackColor="Gold"; $BtnDonate.ForeColor="Black"; $BtnPe.FlatStyle="Flat"
$BtnDonate.Add_Click({ 
    $D=New-Object System.Windows.Forms.Form;$D.Size="400,500";$D.StartPosition="CenterScreen";$P=New-Object System.Windows.Forms.PictureBox;$P.Dock="Fill";$P.SizeMode="Zoom"
    try{$P.Load("https://img.vietqr.io/image/970436-1055835227-print.png?addInfo=Donate%20PhatTanPC&accountName=DANG%20LAM%20TAN%20PHAT")}catch{};$D.Controls.Add($P);$D.ShowDialog() 
}); $PnlFooter.Controls.Add($BtnDonate)

# NÚT CREDITS
$BtnCredit = New-Object System.Windows.Forms.Button; $BtnCredit.Text="ℹ️ TÁC GIẢ"; $BtnCredit.Location="750,55"; $BtnCredit.Size="250,35"; $BtnCredit.BackColor="DarkSlateBlue"; $BtnCredit.ForeColor="White"; $BtnCredit.FlatStyle="Flat"
$BtnCredit.Add_Click({
    [System.Windows.Forms.MessageBox]::Show(
        "PHAT TAN PC TOOLKIT - GHI CÔNG:`n`n" +
        "1. MMT (Ma Minh Toan) - Core Idea`n" +
        "2. Massgrave.dev - MAS (Windows Activation Scripts)`n" +
        "3. DONG599 - Ý tưởng giao diện`n" +
        "4. Cộng đồng Open Source.`n`n" +
        "Phát triển bởi: PHÁT TẤN PC`nLiên hệ Zalo: 0823.883.028", 
        "THÔNG TIN TÁC GIẢ"
    )
}); $PnlFooter.Controls.Add($BtnCredit)

Apply-Theme; $Form.Add_Load({ Start-FadeIn }); $Form.ShowDialog() | Out-Null
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
