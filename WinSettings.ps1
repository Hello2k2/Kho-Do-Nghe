<#
    WINDOWS MASTER SETTINGS V3.1 - TITANIUM LEGENDARY
    Style: V2.6 NEON (Headers + Lines) - No GroupBoxes
    Fix: Force Headers Visible, Fixed Layouts
#>

# --- 0. SAFETY BOOTSTRAP ---
$ErrorActionPreference = "SilentlyContinue"
$Global:ErrorLog = "$env:TEMP\WinSettings_Crash.log"
Trap { Continue }

# --- 1. ADMIN CHECK ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- THEME CONFIG ---
$Theme_Dark = @{
    Name = "Dark Neon"
    BgForm = [System.Drawing.Color]::FromArgb(20, 20, 25)
    BgPanel = [System.Drawing.Color]::FromArgb(35, 35, 40)
    TextMain = [System.Drawing.Color]::White
    TextMuted = [System.Drawing.Color]::Silver
    RGB1 = [System.Drawing.Color]::FromArgb(255, 0, 80)
    RGB2 = [System.Drawing.Color]::FromArgb(0, 255, 255)
    BtnBase = [System.Drawing.Color]::FromArgb(50, 50, 60)
    BtnHigh = [System.Drawing.Color]::FromArgb(70, 70, 90)
    Border  = [System.Drawing.Color]::FromArgb(80, 80, 100)
}

$Theme_Light = @{
    Name = "Light Neon"
    BgForm = [System.Drawing.Color]::FromArgb(240, 240, 245)
    BgPanel = [System.Drawing.Color]::FromArgb(255, 255, 255)
    TextMain = [System.Drawing.Color]::Black
    TextMuted = [System.Drawing.Color]::DimGray
    RGB1 = [System.Drawing.Color]::FromArgb(0, 120, 255)
    RGB2 = [System.Drawing.Color]::FromArgb(0, 200, 100)
    BtnBase = [System.Drawing.Color]::FromArgb(220, 220, 230)
    BtnHigh = [System.Drawing.Color]::FromArgb(240, 240, 255)
    Border  = [System.Drawing.Color]::Silver
}

$Global:CurrentTheme = $Theme_Dark

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "TITANIUM MASTER SETTINGS V3.1 (LEGENDARY UI)"
$Form.Size = New-Object System.Drawing.Size(1150, 800)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Fonts
$F_Logo = New-Object System.Drawing.Font("Segoe UI", 24, [System.Drawing.FontStyle]::Bold)
$F_Head = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$F_Norm = New-Object System.Drawing.Font("Segoe UI", 10)
$F_Btn = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

# --- THEME FUNCTIONS ---
function Apply-Theme {
    $T = $Global:CurrentTheme
    $Form.BackColor = $T.BgForm
    $Form.ForeColor = $T.TextMain
    $LblLogo.ForeColor = $T.RGB2
    $LblSub.ForeColor = $T.TextMuted
    $TabControl.Controls | ForEach-Object { $_.BackColor = $T.BgPanel; $_.ForeColor = $T.TextMain }
    $Form.Refresh()
}

function Add-CyberBtn ($Parent, $Txt, $Icon, $X, $Y, $W, $Tag, $ColorType="Normal") {
    $Btn = New-Object System.Windows.Forms.Label
    $Btn.Text = "$Icon  $Txt"
    $Btn.Tag = @{ Act=$Tag; Hover=$false; Type=$ColorType }
    $Btn.Location = New-Object System.Drawing.Point($X, $Y)
    $Btn.Size = New-Object System.Drawing.Size($W, 45)
    $Btn.Font = $F_Btn; $Btn.TextAlign = "MiddleCenter"; $Btn.Cursor = "Hand"
    $Btn.Add_MouseEnter({ $this.Tag.Hover=$true; $this.Invalidate() })
    $Btn.Add_MouseLeave({ $this.Tag.Hover=$false; $this.Invalidate() })
    $Btn.Add_Click({ Run-Action $this.Tag.Act })
    $Btn.Add_Paint({
        param($s, $e)
        $T = $Global:CurrentTheme; $R = $s.ClientRectangle
        $C1 = $T.BtnBase; $C2 = $T.BtnHigh
        $Border = if($s.Tag.Hover){ $T.RGB2 } else { $T.Border }
        if ($s.Tag.Type -eq "Danger") { $C1=[System.Drawing.Color]::FromArgb(150,0,0); $C2=[System.Drawing.Color]::FromArgb(200,50,50); $Border=[System.Drawing.Color]::Red }
        if ($s.Tag.Type -eq "Primary") { $C1=[System.Drawing.Color]::FromArgb(0,100,180); $C2=[System.Drawing.Color]::FromArgb(50,150,220); $Border=$T.RGB2 }
        if($s.Tag.Hover){ $C1=[System.Windows.Forms.ControlPaint]::Light($C1); $C2=[System.Windows.Forms.ControlPaint]::Light($C2) }
        $Br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($R, $C1, $C2, 90)
        $e.Graphics.FillRectangle($Br, $R)
        $Pen = New-Object System.Drawing.Pen($Border, 2)
        $e.Graphics.DrawRectangle($Pen, 1, 1, $s.Width-2, $s.Height-2)
        $F_Brush = New-Object System.Drawing.SolidBrush($T.TextMain)
        $Sf = New-Object System.Drawing.StringFormat; $Sf.Alignment="Center"; $Sf.LineAlignment="Center"
        $RectF = New-Object System.Drawing.RectangleF([float]0,[float]0,[float]$s.Width,[float]$s.Height)
        $e.Graphics.DrawString($s.Text, $s.Font, $F_Brush, $RectF, $Sf)
        $Br.Dispose(); $Pen.Dispose(); $F_Brush.Dispose()
    })
    $Parent.Controls.Add($Btn)
    $Btn.BringToFront() # Đảm bảo nút nổi lên
}

function Add-Header ($Parent, $Title, $X, $Y, $Color) {
    # Label Text (FIX AUTO SIZE BUG)
    $L = New-Object System.Windows.Forms.Label
    $L.Text = $Title
    $L.Location = New-Object System.Drawing.Point($X, $Y)
    $L.AutoSize = $false # Tắt tự động co giãn
    $L.Size = New-Object System.Drawing.Size(450, 30) # Set cứng kích thước
    $L.Font = $F_Head; $L.ForeColor = $Color
    $Parent.Controls.Add($L)
    $L.BringToFront() # Đưa lên trên cùng
    
    # Line
    $Line = New-Object System.Windows.Forms.Label
    $Line.Location = New-Object System.Drawing.Point($X, ($Y+28))
    $Line.Size = New-Object System.Drawing.Size(440, 2)
    $Line.BackColor = $Color
    $Parent.Controls.Add($Line)
    $Line.BringToFront()
}

function Add-Toggle ($Parent, $Txt, $X, $Y, $OnCmd, $OffCmd) {
    $Chk = New-Object System.Windows.Forms.CheckBox; $Chk.Text=$Txt
    $Chk.Location = New-Object System.Drawing.Point($X, $Y)
    $Chk.Size = New-Object System.Drawing.Size(450, 30)
    $Chk.Font=$F_Norm; $Chk.ForeColor=$Global:CurrentTheme.TextMain
    $Chk.Add_CheckedChanged({ if ($Chk.Checked) { & $OnCmd } else { & $OffCmd } })
    $Parent.Controls.Add($Chk)
}

function Toggle-Theme {
    if ($Global:CurrentTheme.Name -match "Dark") { $Global:CurrentTheme = $Theme_Light; $BtnTheme.Text = "☀️ LIGHT MODE" }
    else { $Global:CurrentTheme = $Theme_Dark; $BtnTheme.Text = "🌙 DARK MODE" }
    Apply-Theme
}

function Set-Reg ($Path, $Name, $Val, $Type="DWord") {
    if(!(Test-Path $Path)){New-Item $Path -Force | Out-Null}
    if([string]::IsNullOrEmpty($Name)){ Set-Item -Path $Path -Value $Val }
    else{ New-ItemProperty -Path $Path -Name $Name -Value $Val -PropertyType $Type -Force | Out-Null }
}

# ==================== LAYOUT ====================
# HEAD
$PnlHead = New-Object System.Windows.Forms.Panel; $PnlHead.Dock="Top"; $PnlHead.Height=80; $PnlHead.BackColor=[System.Drawing.Color]::Transparent
$Form.Controls.Add($PnlHead)

$LblLogo = New-Object System.Windows.Forms.Label; $LblLogo.Text="TITANIUM MASTER SETTINGS"; $LblLogo.Font=$F_Logo; $LblLogo.AutoSize=$true; $LblLogo.Location=New-Object System.Drawing.Point(20, 10)
$PnlHead.Controls.Add($LblLogo)
$LblSub = New-Object System.Windows.Forms.Label; $LblSub.Text="Ultimate Windows Control Center V3.1 (Legendary)"; $LblSub.Font=$F_Norm; $LblSub.AutoSize=$true; $LblSub.Location=New-Object System.Drawing.Point(480, 30)
$PnlHead.Controls.Add($LblSub)

$BtnTheme = New-Object System.Windows.Forms.Button; $BtnTheme.Text="🌙 DARK MODE"; $BtnTheme.Location=New-Object System.Drawing.Point(900, 25); $BtnTheme.Size=New-Object System.Drawing.Size(200, 35); $BtnTheme.FlatStyle="Flat"
$BtnTheme.BackColor=[System.Drawing.Color]::FromArgb(60,60,60); $BtnTheme.ForeColor="White"
$BtnTheme.Add_Click({ Toggle-Theme })
$PnlHead.Controls.Add($BtnTheme)

# TABS
$TabControl = New-Object System.Windows.Forms.TabControl; $TabControl.Location=New-Object System.Drawing.Point(20, 100); $TabControl.Size=New-Object System.Drawing.Size(1100, 630); $TabControl.Font=$F_Head
$Form.Controls.Add($TabControl)

function MkTab ($Title) { 
    $P=New-Object System.Windows.Forms.TabPage; $P.Text="  $Title  "
    $P.BackColor=$Global:CurrentTheme.BgPanel; $P.ForeColor=$Global:CurrentTheme.TextMain
    $TabControl.Controls.Add($P); return $P 
}

# --- TAB 1: GIAO DIỆN ---
$T1 = MkTab "🖥️ GIAO DIỆN"
Add-Header $T1 "MÀU SẮC & THEME" 30 30 $Global:CurrentTheme.RGB2
Add-CyberBtn $T1 "BẬT DARK MODE" "🌑" 30 70 440 "DarkMode" "Primary"
Add-CyberBtn $T1 "BẬT LIGHT MODE" "☀️" 30 125 440 "LightMode"
Add-CyberBtn $T1 "TRANSPARENCY" "✨" 30 180 440 "TransEffects"

Add-Header $T1 "EXPLORER & TASKBAR" 550 30 $Global:CurrentTheme.RGB1
Add-CyberBtn $T1 "MENU CHUỘT PHẢI WIN 10" "🖱️" 550 70 440 "OldMenu"
Add-CyberBtn $T1 "HIỆN FILE ẨN" "👁️" 550 125 440 "ShowHidden"
Add-CyberBtn $T1 "RESTART EXPLORER" "🔄" 550 180 440 "RestartExp" "Danger"

# --- TAB 2: HỆ THỐNG ---
$T2 = MkTab "⚙️ HỆ THỐNG"
Add-Header $T2 "CÀI ĐẶT CHUNG" 30 30 [System.Drawing.Color]::Gold
Add-CyberBtn $T2 "MỞ TIME & LANGUAGE" "🕒" 30 70 440 "OpenTimeLang"
Add-CyberBtn $T2 "MỞ REGION (VÙNG)" "🌍" 30 125 440 "OpenRegion"
Add-CyberBtn $T2 "TẠO GOD MODE" "🛠️" 30 180 440 "GodMode" "Special"

Add-Header $T2 "NGUỒN & HIỆU NĂNG" 550 30 [System.Drawing.Color]::LimeGreen
Add-CyberBtn $T2 "ULTIMATE PERFORMANCE" "🔥" 550 70 440 "UltPerf" "Primary"
Add-CyberBtn $T2 "TẮT HIBERNATE" "💤" 550 125 440 "OffHib"
Add-CyberBtn $T2 "TẮT FAST STARTUP" "⚡" 550 180 440 "OffFastBoot"

# --- TAB 3: TÀI KHOẢN ---
$T3 = MkTab "👤 TÀI KHOẢN"
Add-Header $T3 "QUẢN LÝ USER" 30 30 [System.Drawing.Color]::Cyan
Add-CyberBtn $T3 "BẬT ADMIN ẨN" "👤" 30 70 440 "OnAdmin" "Primary"
Add-CyberBtn $T3 "TẮT ADMIN ẨN" "🚫" 30 125 440 "OffAdmin"

Add-Header $T3 "BẢO MẬT UAC" 550 30 [System.Drawing.Color]::Magenta
Add-CyberBtn $T3 "TẮT HẲN UAC" "🔕" 550 70 440 "OffUAC" "Danger"
Add-CyberBtn $T3 "BẬT LẠI UAC" "🔔" 550 125 440 "OnUAC" "Safe"

# --- TAB 4: MẠNG ---
$T4 = MkTab "🌐 MẠNG"
Add-Header $T4 "DNS SERVER" 30 30 [System.Drawing.Color]::Cyan
Add-CyberBtn $T4 "GOOGLE DNS (8.8.8.8)" "G" 30 70 440 "DnsGo"
Add-CyberBtn $T4 "CLOUDFLARE (1.1.1.1)" "C" 30 125 440 "DnsCf"
Add-CyberBtn $T4 "AUTO DNS (DHCP)" "A" 30 180 440 "DnsAuto"

Add-Header $T4 "SỬA LỖI MẠNG" 550 30 [System.Drawing.Color]::Red
Add-CyberBtn $T4 "RESET MẠNG (FIX LỖI)" "🔧" 550 70 440 "NetReset" "Danger"
Add-CyberBtn $T4 "FLUSH DNS CACHE" "🚿" 550 125 440 "FlushDns"

# --- TAB 5: TỐI ƯU ---
$T5 = MkTab "🚀 TỐI ƯU"
Add-Header $T5 "DỌN DẸP HỆ THỐNG" 30 30 [System.Drawing.Color]::Orange
Add-CyberBtn $T5 "DỌN RÁC (Temp/Prefetch)" "🧹" 30 70 440 "CleanTemp" "Primary"
Add-CyberBtn $T5 "XÓA CACHE UPDATE" "📦" 30 125 440 "CleanUpd"
Add-CyberBtn $T5 "TẮT TELEMETRY" "👁️" 30 180 440 "OffTele"

Add-Header $T5 "TỐI ƯU ỨNG DỤNG" 550 30 [System.Drawing.Color]::Orange
Add-CyberBtn $T5 "TẮT APPS CHẠY NGẦM" "🛑" 550 70 440 "OffBgApps"

# --- TAB 6: CÔNG CỤ ---
$T6 = MkTab "🛠️ CÔNG CỤ"
Add-Header $T6 "SHORTCUTS HỆ THỐNG" 30 30 [System.Drawing.Color]::White
Add-CyberBtn $T6 "CONTROL PANEL (CŨ)" "⚙️" 30 70 440 "OpenControl"
Add-CyberBtn $T6 "REGISTRY EDITOR" "📝" 30 125 440 "OpenReg"
Add-CyberBtn $T6 "SERVICES.MSC" "⚙️" 30 180 440 "OpenSvc"

Add-Header $T6 "THÔNG TIN KHÁC" 550 30 [System.Drawing.Color]::White
Add-CyberBtn $T6 "NETWORK CONN." "🌐" 550 70 440 "OpenNcpa"
Add-CyberBtn $T6 "SYSTEM PROPERTIES" "ℹ️" 550 125 440 "OpenSys"

# --- TAB 7: BẢO MẬT ---
$T7 = MkTab "🔒 BẢO MẬT"
Add-Header $T7 "QUYỀN RIÊNG TƯ" 30 30 [System.Drawing.Color]::DeepPink
Add-Toggle $T7 "Chặn Camera (Toàn bộ)" 30 70 { Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Camera" "AllowCamera" 0 } { Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Camera" "AllowCamera" 1 }
Add-Toggle $T7 "Chặn Microphone" 30 110 { Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\SoundRecorder" "AllowAudioInput" 0 } { Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\SoundRecorder" "AllowAudioInput" 1 }
Add-Toggle $T7 "Tắt Định Vị (Location)" 30 150 { Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "DisableLocation" 1 } { Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "DisableLocation" 0 }

Add-Header $T7 "WINDOWS DEFENDER" 550 30 [System.Drawing.Color]::Red
Add-CyberBtn $T7 "TẮT DEFENDER (REGISTRY)" "🛡️" 550 70 440 "OffDef" "Danger"
Add-CyberBtn $T7 "BẬT LẠI DEFENDER" "✅" 550 125 440 "OnDef" "Safe"

# --- TAB 8: GAMING ---
$T8 = MkTab "🎮 GAMING"
Add-Header $T8 "TỐI ƯU GAME" 30 30 [System.Drawing.Color]::Lime
Add-CyberBtn $T8 "TẮT MOUSE ACCELERATION" "🖱️" 30 70 440 "OffMouseAcc"
Add-CyberBtn $T8 "TẮT XBOX GAME BAR" "🎮" 30 125 440 "OffGameBar"
Add-CyberBtn $T8 "RESET GRAPHIC DRIVER" "📺" 30 180 440 "ResetGPU"

# --- TAB 9: APPS ---
$T9 = MkTab "📦 ỨNG DỤNG"
Add-Header $T9 "GỠ BLOATWARE" 30 30 [System.Drawing.Color]::Orange
Add-CyberBtn $T9 "GỠ CORTANA" "🗑️" 30 70 440 "DelCortana"
Add-CyberBtn $T9 "GỠ XBOX APPS" "🎮" 30 125 440 "DelXbox"
Add-CyberBtn $T9 "GỠ ONEDRIVE" "☁️" 30 180 440 "DelOneDrive"

# --- TAB 10: INFO ---
$T10 = MkTab "📝 THÔNG TIN"
$TxtInfo = New-Object System.Windows.Forms.TextBox; $TxtInfo.Multiline=$true; $TxtInfo.Location=New-Object System.Drawing.Point(20, 20); $TxtInfo.Size=New-Object System.Drawing.Size(900, 400); $TxtInfo.BackColor="Black"; $TxtInfo.ForeColor="Lime"; $TxtInfo.Font=New-Object System.Drawing.Font("Consolas", 11); $T10.Controls.Add($TxtInfo)

function Get-Info {
    try {
        $OS = Get-CimInstance Win32_OperatingSystem
        $CPU = Get-CimInstance Win32_Processor
        $RAM = [Math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB, 1)
        $Uptime = (Get-Date) - $OS.LastBootUpTime
        $Txt = "=== SYSTEM INFO ===`r`nOS: $($OS.Caption)`r`nCPU: $($CPU.Name)`r`nRAM: $RAM GB`r`nUser: $env:USERNAME`r`nUptime: $($Uptime.Days)d $($Uptime.Hours)h"
        $TxtInfo.Text = $Txt
    } catch { $TxtInfo.Text = "Loi lay thong tin." }
}
Add-CyberBtn $T10 "LÀM MỚI" "♻️" 20 440 200 "RefreshInfo"
Get-Info

# ==================== ACTIONS ====================
function Run-Action ($Act) {
    switch ($Act) {
        "DarkMode" { 
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 0
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 0
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 1
        }
        "LightMode" {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 1
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 1
        }
        "TransEffects" { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 1 }
        "ShowHidden" { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" 1 }
        "RestartExp" { Stop-Process -Name explorer -Force }
        "OldMenu" { Set-Reg "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" "" "" "String" }
        "OpenTimeLang" { Start-Process "ms-settings:dateandtime" }
        "OpenRegion"   { Start-Process "ms-settings:regionformatting" }
        "GodMode" { New-Item "$env:USERPROFILE\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}" -ItemType Directory -Force; [System.Windows.Forms.MessageBox]::Show("OK") }
        "UltPerf" { powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61; [System.Windows.Forms.MessageBox]::Show("OK") }
        "OffHib" { powercfg -h off }
        "OffFastBoot" { Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled" 0 }
        "OnAdmin" { net user administrator /active:yes }
        "OffAdmin" { net user administrator /active:no }
        "OffUAC" { Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" 0; [System.Windows.Forms.MessageBox]::Show("Restart!") }
        "OnUAC" { Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" 1 }
        "DnsGo" { Get-NetAdapter | Where Status -eq Up | Set-DnsClientServerAddress -ServerAddresses ("8.8.8.8","8.8.4.4") }
        "DnsCf" { Get-NetAdapter | Where Status -eq Up | Set-DnsClientServerAddress -ServerAddresses ("1.1.1.1","1.0.0.1") }
        "DnsAuto" { Get-NetAdapter | Where Status -eq Up | Set-DnsClientServerAddress -ResetServerAddresses }
        "NetReset" { netsh int ip reset; netsh winsock reset }
        "FlushDns" { ipconfig /flushdns }
        "CleanTemp" { Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue }
        "OffBgApps" { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1 }
        "CleanUpd"  { Stop-Service wuauserv; Remove-Item "$env:windir\SoftwareDistribution\Download\*" -Recurse -Force; Start-Service wuauserv }
        "OffTele" { Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0 }
        "OpenControl" { Start-Process "control" }
        "OpenReg" { Start-Process "regedit" }
        "OpenSvc" { Start-Process "services.msc" }
        "OpenNcpa" { Start-Process "ncpa.cpl" }
        "OpenSys" { Start-Process "sysdm.cpl" }
        "BlockCam" { Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Camera" "AllowCamera" 0 }
        "BlockMic" { Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\SoundRecorder" "AllowAudioInput" 0 }
        "BlockLoc" { Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "DisableLocation" 1 }
        "OffDef" { Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableAntiSpyware" 1 }
        "OnDef" { Remove-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableAntiSpyware" -ErrorAction SilentlyContinue }
        "OffMouseAcc" { [System.Windows.Forms.MessageBox]::Show("Updating...") }
        "OffGameBar" { Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0 }
        "ResetGPU" { [System.Windows.Forms.MessageBox]::Show("Ctrl+Shift+Win+B") }
        "DelCortana" { Get-AppxPackage -allusers *Cortana* | Remove-AppxPackage }
        "DelXbox" { Get-AppxPackage *xbox* | Remove-AppxPackage }
        "DelOneDrive" { Stop-Process -Name "OneDrive" -Force; Start-Process "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" "/uninstall" -Wait }
        "RefreshInfo" { Get-Info }
    }
}

# --- INIT ---
Apply-Theme
$Form.ShowDialog() | Out-Null
