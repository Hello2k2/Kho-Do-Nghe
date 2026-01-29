<#
    TITANIUM GOD MODE V6.4 - SYSTEM CONTROL EDITION
    Tính năng mới: Tab Hệ Thống (Đổi tên PC, UAC, SmartScreen, Ngôn ngữ...)
    Kiến trúc: Hamburger Menu + GDI+ + InputBox
    Ngôn ngữ: Tiếng Việt 100%.
#>

# --- 0. KHỞI TẠO AN TOÀN & FIX FONT ---
$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic # Để dùng InputBox

# Kiểm tra Admin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- 1. CẤU HÌNH GIAO DIỆN ---
$Theme = @{
    BgForm      = [System.Drawing.Color]::FromArgb(10, 10, 15)
    BgSidebar   = [System.Drawing.Color]::FromArgb(20, 20, 28)
    BgContent   = [System.Drawing.Color]::FromArgb(28, 28, 38)
    BgInput     = [System.Drawing.Color]::FromArgb(15, 15, 20)
    Accent      = [System.Drawing.Color]::FromArgb(0, 210, 255)
    Accent2     = [System.Drawing.Color]::FromArgb(180, 0, 255)
    AccentRed   = [System.Drawing.Color]::FromArgb(255, 50, 80)
    AccentGold  = [System.Drawing.Color]::FromArgb(255, 180, 0)
    AccentGreen = [System.Drawing.Color]::FromArgb(0, 255, 120)
    TextMain    = [System.Drawing.Color]::WhiteSmoke
    TextMuted   = [System.Drawing.Color]::FromArgb(120, 120, 140)
    Border      = [System.Drawing.Color]::FromArgb(60, 60, 80)
    FontLogo    = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    FontHead    = New-Object System.Drawing.Font("Segoe UI Semibold", 11)
    FontNorm    = New-Object System.Drawing.Font("Segoe UI", 9)
    FontMono    = New-Object System.Drawing.Font("Consolas", 9)
}

# --- 2. FORM CHÍNH ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "TITANIUM V6.4"
$Form.Size = New-Object System.Drawing.Size(1200, 760)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "None"
$Form.BackColor = $Theme.BgForm
$Form.ForeColor = $Theme.TextMain
$Form.DoubleBuffered = $true 

# Drag Logic
$IsDragging = $false; $DragStart = [System.Drawing.Point]::Empty
$Form.Add_MouseDown({ $Global:IsDragging = $true; $Global:DragStart = $_.Location })
$Form.Add_MouseMove({ if ($Global:IsDragging) { $Form.Location = [System.Drawing.Point]::Add($Form.Location, [System.Drawing.Size]::Subtract($_.Location, $Global:DragStart)) } })
$Form.Add_MouseUp({ $Global:IsDragging = $false })

# --- 3. LAYOUT ---

# Sidebar
$Sidebar = New-Object System.Windows.Forms.Panel; $Sidebar.Dock = "Left"; $Sidebar.Width = 230; $Sidebar.BackColor = $Theme.BgSidebar
$Form.Controls.Add($Sidebar)

# Logo
$PnlLogo = New-Object System.Windows.Forms.Panel; $PnlLogo.Size = New-Object System.Drawing.Size(230, 90); $PnlLogo.Dock="Top"; $PnlLogo.BackColor="Transparent"
$LblLogo = New-Object System.Windows.Forms.Label; $LblLogo.Text = "TITANIUM"; $LblLogo.Font = $Theme.FontLogo; $LblLogo.ForeColor = $Theme.Accent; $LblLogo.AutoSize=$true; $LblLogo.Location=New-Object System.Drawing.Point(20, 20)
$LblVer = New-Object System.Windows.Forms.Label; $LblVer.Text = "SYSTEM CONTROL"; $LblVer.Font = $Theme.FontMono; $LblVer.ForeColor = $Theme.AccentGreen; $LblVer.AutoSize=$true; $LblVer.Location=New-Object System.Drawing.Point(22, 55)
$PnlLogo.Controls.Add($LblLogo); $PnlLogo.Controls.Add($LblVer); $Sidebar.Controls.Add($PnlLogo)

# Content
$ContentContainer = New-Object System.Windows.Forms.Panel; $ContentContainer.Dock = "Fill"; $ContentContainer.BackColor = $Theme.BgForm
$Form.Controls.Add($ContentContainer); $ContentContainer.BringToFront()

# Top Bar
$TopBar = New-Object System.Windows.Forms.Panel; $TopBar.Dock = "Top"; $TopBar.Height = 45; $TopBar.BackColor = $Theme.BgForm
$ContentContainer.Controls.Add($TopBar)
$TopBar.Add_MouseDown({ $Global:IsDragging = $true; $Global:DragStart = $_.Location })
$TopBar.Add_MouseMove({ if ($Global:IsDragging) { $Form.Location = [System.Drawing.Point]::Add($Form.Location, [System.Drawing.Size]::Subtract($_.Location, $Global:DragStart)) } })
$TopBar.Add_MouseUp({ $Global:IsDragging = $false })

# Menu Button
$BtnMenu = New-Object System.Windows.Forms.Label
$BtnMenu.Text = "☰"; $BtnMenu.Font = New-Object System.Drawing.Font("Segoe UI Symbol", 16); $BtnMenu.ForeColor = $Theme.Accent; $BtnMenu.AutoSize = $true; $BtnMenu.Location = New-Object System.Drawing.Point(15, 8); $BtnMenu.Cursor = "Hand"
$BtnMenu.Add_Click({ if ($Sidebar.Visible) { $Sidebar.Visible = $false } else { $Sidebar.Visible = $true } })
$TopBar.Controls.Add($BtnMenu)

# Win Controls
$BtnClose = New-Object System.Windows.Forms.Label; $BtnClose.Text="✕"; $BtnClose.Dock="Right"; $BtnClose.Width=50; $BtnClose.TextAlign="MiddleCenter"; $BtnClose.ForeColor=$Theme.AccentRed; $BtnClose.Cursor="Hand"; $BtnClose.Font=$Theme.FontHead; $BtnClose.Add_Click({ $Form.Close() })
$BtnMin = New-Object System.Windows.Forms.Label; $BtnMin.Text="—"; $BtnMin.Dock="Right"; $BtnMin.Width=50; $BtnMin.TextAlign="MiddleCenter"; $BtnMin.ForeColor="White"; $BtnMin.Cursor="Hand"; $BtnMin.Font=$Theme.FontHead; $BtnMin.Add_Click({ $Form.WindowState = "Minimized" })
$TopBar.Controls.Add($BtnClose); $TopBar.Controls.Add($BtnMin)

# Status Bar
$StatusBar = New-Object System.Windows.Forms.Panel; $StatusBar.Dock="Bottom"; $StatusBar.Height=35; $StatusBar.BackColor=$Theme.BgSidebar
$LblStatus = New-Object System.Windows.Forms.Label; $LblStatus.Text="Chào mừng. Chọn một chức năng để bắt đầu."; $LblStatus.ForeColor=$Theme.Accent; $LblStatus.Dock="Fill"; $LblStatus.TextAlign="MiddleLeft"; $LblStatus.Padding=New-Object System.Windows.Forms.Padding(15,0,0,0); $LblStatus.Font=$Theme.FontMono
$StatusBar.Controls.Add($LblStatus); $ContentContainer.Controls.Add($StatusBar)

# --- 4. HÀM HỖ TRỢ ---
$Global:Panels = @()
function Make-Panel ($Name) {
    $P = New-Object System.Windows.Forms.Panel; $P.Dock = "Fill"; $P.BackColor = $Theme.BgForm; $P.Visible = $false; $P.AutoScroll = $true; $P.Padding = New-Object System.Windows.Forms.Padding(20, 0, 0, 50)
    $ContentContainer.Controls.Add($P); $P.BringToFront(); $Global:Panels += $P; return $P
}

function Add-NavBtn ($Parent, $Text, $Icon, $Y, $PanelToOpen) {
    $Btn = New-Object System.Windows.Forms.Label; $Btn.Text = "  $Icon   $Text"; $Btn.Size = New-Object System.Drawing.Size(230, 50); $Btn.Location = New-Object System.Drawing.Point(0, $Y); $Btn.Font = $Theme.FontHead; $Btn.ForeColor = $Theme.TextMuted; $Btn.TextAlign = "MiddleLeft"; $Btn.Cursor = "Hand"; $Btn.Tag = $PanelToOpen
    $Btn.Add_MouseEnter({ $this.ForeColor = $Theme.Accent; $this.BackColor = [System.Drawing.Color]::FromArgb(35,35,45) })
    $Btn.Add_MouseLeave({ if ($script:ActivePanel -ne $this.Tag) { $this.ForeColor = $Theme.TextMuted; $this.BackColor = [System.Drawing.Color]::Transparent } })
    $Btn.Add_Click({ Switch-Panel $this }); $Parent.Controls.Add($Btn)
}

function Add-ActionBtn ($Parent, $Text, $Cmd, $X, $Y, $IsDanger=$false, $IsWide=$false) {
    $Btn = New-Object System.Windows.Forms.Button; $Btn.Text = $Text; $Btn.Tag = $Cmd; $Btn.Location = New-Object System.Drawing.Point($X, $Y)
    $Btn.Size = if($IsWide){New-Object System.Drawing.Size(480, 40)}else{New-Object System.Drawing.Size(230, 40)}
    $Btn.FlatStyle = "Flat"; $Btn.Font = $Theme.FontNorm; $Btn.Cursor = "Hand"
    if ($IsDanger) { $Btn.ForeColor = $Theme.AccentRed; $Btn.FlatAppearance.BorderColor = $Theme.AccentRed } else { $Btn.ForeColor = $Theme.TextMain; $Btn.FlatAppearance.BorderColor = $Theme.Border }
    $Btn.FlatAppearance.BorderSize = 1; $Btn.BackColor = $Theme.BgContent
    $Btn.Add_MouseEnter({ $this.BackColor = if($IsDanger){[System.Drawing.Color]::FromArgb(50,20,20)}else{[System.Drawing.Color]::FromArgb(50,50,60)} })
    $Btn.Add_MouseLeave({ $this.BackColor = $Theme.BgContent }); $Btn.Add_Click({ Run-Command $this.Tag $this.Text }); $Parent.Controls.Add($Btn)
}

function Add-SectionTitle ($Parent, $Text, $Y) {
    $L = New-Object System.Windows.Forms.Label; $L.Text = $Text; $L.Font = $Theme.FontHead; $L.ForeColor = $Theme.Accent; $L.Location = New-Object System.Drawing.Point(30, $Y); $L.AutoSize = $true; $Parent.Controls.Add($L)
    $Line = New-Object System.Windows.Forms.Panel; $Line.Size = New-Object System.Drawing.Size(800, 1); $Line.BackColor = $Theme.Border; $Line.Location = New-Object System.Drawing.Point(30, $Y+28); $Parent.Controls.Add($Line)
}

function Show-InputBox ($Title, $Prompt) {
    # Tự tạo InputBox đơn giản bằng WinForms
    $f = New-Object System.Windows.Forms.Form
    $f.Width = 400; $f.Height = 180; $f.Text = $Title; $f.StartPosition = "CenterScreen"; $f.FormBorderStyle = "FixedDialog"; $f.MaximizeBox = $false
    $l = New-Object System.Windows.Forms.Label; $l.Left = 20; $l.Top = 20; $l.Text = $Prompt; $l.AutoSize = $true
    $t = New-Object System.Windows.Forms.TextBox; $t.Left = 20; $t.Top = 50; $t.Width = 340
    $b = New-Object System.Windows.Forms.Button; $b.Left = 260; $b.Top = 90; $b.Text = "OK"; $b.DialogResult = "OK"
    $f.Controls.Add($l); $f.Controls.Add($t); $f.Controls.Add($b); $f.AcceptButton = $b
    if ($f.ShowDialog() -eq "OK") { return $t.Text } else { return $null }
}

# --- 5. NỘI DUNG CÁC TRANG ---

# P1: Dashboard
$P_Dash = Make-Panel "Dashboard"
Add-SectionTitle $P_Dash "GIÁM SÁT HỆ THỐNG" 30
$GaugeBox = New-Object System.Windows.Forms.PictureBox; $GaugeBox.Location = New-Object System.Drawing.Point(30, 70); $GaugeBox.Size = New-Object System.Drawing.Size(820, 160); $GaugeBox.BackColor = "Transparent"; $P_Dash.Controls.Add($GaugeBox)
$TxtInfo = New-Object System.Windows.Forms.TextBox; $TxtInfo.Multiline=$true; $TxtInfo.Location=New-Object System.Drawing.Point(30, 250); $TxtInfo.Size=New-Object System.Drawing.Size(820, 300); $TxtInfo.BackColor=$Theme.BgInput; $TxtInfo.ForeColor=$Theme.TextMain; $TxtInfo.BorderStyle="None"; $TxtInfo.Font=$Theme.FontMono; $TxtInfo.ReadOnly=$true; $P_Dash.Controls.Add($TxtInfo)

# P2: System & Security (NEW)
$P_Sys = Make-Panel "System"
Add-SectionTitle $P_Sys "CẤU HÌNH WINDOWS" 30
Add-ActionBtn $P_Sys "Đổi Tên Máy Tính" "RenPC" 30 70
Add-ActionBtn $P_Sys "Cài Đặt Ngôn Ngữ" "SetLang" 280 70
Add-ActionBtn $P_Sys "Cài Đặt Múi Giờ" "SetTime" 530 70

Add-SectionTitle $P_Sys "BẢO MẬT & THÔNG BÁO (ADMIN)" 130
Add-ActionBtn $P_Sys "Tắt Thông Báo Win" "OffNotify" 30 170
Add-ActionBtn $P_Sys "Bật Lại Thông Báo" "OnNotify" 280 170
Add-ActionBtn $P_Sys "Tắt UAC (Đỡ phiền)" "OffUAC" 30 220 $true
Add-ActionBtn $P_Sys "Bật Lại UAC" "OnUAC" 280 220
Add-ActionBtn $P_Sys "Tắt SmartScreen" "OffSmart" 30 270 $true
Add-ActionBtn $P_Sys "Bật SmartScreen" "OnSmart" 280 270

# P3: Optimize
$P_Opt = Make-Panel "Optimize"
Add-SectionTitle $P_Opt "TỐI ƯU HÓA" 30
Add-ActionBtn $P_Opt "Dọn Rác Sâu (Temp)" "CleanDeep" 30 70 $false $true
Add-ActionBtn $P_Opt "Xóa Cache Update" "CleanUpd" 30 120
Add-ActionBtn $P_Opt "Tắt Telemetry" "OffTele" 280 120
Add-ActionBtn $P_Opt "Hiệu Suất Cao" "UltPerf" 30 170
Add-ActionBtn $P_Opt "Tắt Ngủ Đông" "OffHiber" 280 170
Add-SectionTitle $P_Opt "GỠ BỎ APP RÁC" 230
Add-ActionBtn $P_Opt "Gỡ Cortana" "DelCortana" 30 270 $true
Add-ActionBtn $P_Opt "Gỡ Xbox Apps" "DelXbox" 280 270 $true
Add-ActionBtn $P_Opt "Gỡ OneDrive" "DelOneDrive" 30 320 $true
Add-ActionBtn $P_Opt "Gỡ Edge" "DelEdge" 280 320 $true

# P4: Repair
$P_Repair = Make-Panel "Repair"
Add-SectionTitle $P_Repair "SỬA LỖI HỆ THỐNG" 30
Add-ActionBtn $P_Repair "SFC Scan (File)" "RunSFC" 30 70
Add-ActionBtn $P_Repair "DISM Restore" "RunDISM" 280 70
Add-ActionBtn $P_Repair "Check Disk (C:)" "RunChkDsk" 30 120
Add-ActionBtn $P_Repair "Reset Explorer" "RestartExp" 280 120

# P5: NetOps
$P_Net = Make-Panel "NetOps"
Add-SectionTitle $P_Net "MẠNG & INTERNET" 30
Add-ActionBtn $P_Net "Xem IP Công Khai" "GetPubIP" 30 70
Add-ActionBtn $P_Net "Ping Google" "PingTest" 280 70
Add-ActionBtn $P_Net "Xóa DNS Cache" "FlushDns" 30 120
Add-ActionBtn $P_Net "Reset Mạng" "NetReset" 280 120 $true
Add-SectionTitle $P_Net "TIỆN ÍCH WIFI" 180
Add-ActionBtn $P_Net "Xuất Pass Wifi" "DumpWifi" 30 220 $false $true
Add-ActionBtn $P_Net "Sửa File Hosts" "EditHosts" 30 270

# P6: Software
$P_Soft = Make-Panel "Software"
Add-SectionTitle $P_Soft "TRÌNH DUYỆT & TOOLS" 30
Add-ActionBtn $P_Soft "Chrome" "InstChrome" 30 70
Add-ActionBtn $P_Soft "Firefox" "InstFirefox" 280 70
Add-ActionBtn $P_Soft "Unikey" "InstUnikey" 530 70
Add-ActionBtn $P_Soft "VS Code" "InstVSCode" 30 120
Add-ActionBtn $P_Soft "Discord" "InstDiscord" 280 120
Add-ActionBtn $P_Soft "7-Zip" "Inst7Zip" 530 120

# --- LIÊN KẾT MENU ---
Add-NavBtn $Sidebar "Tổng Quan" "📊" 100 $P_Dash
Add-NavBtn $Sidebar "Hệ Thống" "⚙️" 150 $P_Sys
Add-NavBtn $Sidebar "Tối Ưu Hóa" "🚀" 200 $P_Opt
Add-NavBtn $Sidebar "Mạng & Net" "🌐" 250 $P_Net
Add-NavBtn $Sidebar "Sửa Chữa" "🛠️" 300 $P_Repair
Add-NavBtn $Sidebar "Phần Mềm" "💾" 350 $P_Soft

# --- 6. XỬ LÝ LOGIC ---
$script:ActivePanel = $null
$Global:CpuLoad = 0; $Global:RamLoad = 0

function Switch-Panel ($Btn) {
    $Sidebar.Controls | Where-Object { $_.GetType().Name -eq "Label" -and $_.Tag -ne $null } | ForEach-Object {
        $_.ForeColor = $Theme.TextMuted; $_.BackColor = "Transparent"
    }
    $Global:Panels | ForEach-Object { $_.Visible = $false }
    $Btn.ForeColor = $Theme.Accent; $Btn.BackColor = [System.Drawing.Color]::FromArgb(35,35,45)
    $Btn.Tag.Visible = $true; $script:ActivePanel = $Btn.Tag
}

function Log ($Msg) { $LblStatus.Text = "$(Get-Date -Format 'HH:mm:ss') > $Msg"; $Form.Refresh() }
function Set-Reg ($Path, $Name, $Val) { if(!(Test-Path $Path)){New-Item $Path -Force|Out-Null}; New-ItemProperty -Path $Path -Name $Name -Value $Val -PropertyType DWord -Force|Out-Null }

function Run-Command ($Cmd, $Desc) {
    Log "Đang chạy: $Desc..."
    $Form.Cursor = "WaitCursor"
    switch ($Cmd) {
        # --- SYSTEM (MỚI) ---
        "RenPC" { 
            $new = Show-InputBox "Đổi Tên Máy" "Nhập tên mới cho máy tính (Không dấu, không khoảng cách):"
            if ($new) { 
                try { Rename-Computer -NewName $new -ErrorAction Stop; Log "Đã đổi tên thành '$new'. Hãy khởi động lại máy!" }
                catch { Log "Lỗi: Tên không hợp lệ hoặc cần quyền Admin." }
            } else { Log "Đã hủy đổi tên." }
        }
        "SetLang"   { Start-Process "ms-settings:regionlanguage"; Log "Đã mở cài đặt Ngôn ngữ." }
        "SetTime"   { Start-Process "ms-settings:dateandtime"; Log "Đã mở cài đặt Giờ & Múi giờ." }
        "OffNotify" { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" "ToastEnabled" 0; Log "Đã tắt toàn bộ thông báo Windows." }
        "OnNotify"  { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" "ToastEnabled" 1; Log "Đã bật lại thông báo." }
        "OffUAC"    { Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" 0; Log "Đã tắt UAC (Cần khởi động lại)." }
        "OnUAC"     { Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" 1; Log "Đã bật UAC (An toàn)." }
        "OffSmart"  { Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "SmartScreenEnabled" "Off"; Log "Đã tắt SmartScreen (Cần khởi động lại)." }
        "OnSmart"   { Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "SmartScreenEnabled" "Warn"; Log "Đã bật SmartScreen." }

        # --- OPTIMIZE ---
        "CleanDeep" { Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue; Log "Đã dọn dẹp xong." }
        "CleanUpd"  { Stop-Service wuauserv; Remove-Item "$env:windir\SoftwareDistribution\Download\*" -Recurse -Force; Start-Service wuauserv; Log "Đã xóa Cache Update." }
        "UltPerf"   { powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61; Log "Đã thêm Ultimate Performance." }
        "OffTele"   { Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0; Log "Đã tắt Telemetry." }
        "OffHiber"  { powercfg -h off; Log "Đã tắt Ngủ đông." }
        "DelCortana"{ Get-AppxPackage -allusers *Cortana* | Remove-AppxPackage; Log "Đã xóa Cortana." }
        "DelXbox"   { Get-AppxPackage *xbox* | Remove-AppxPackage; Log "Đã xóa Xbox." }
        "DelOneDrive"{ Stop-Process -Name "OneDrive" -Force; Start-Process "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" "/uninstall" -Wait; Log "Đã xóa OneDrive." }
        
        # --- REPAIR ---
        "RunSFC"    { Start-Process "sfc" "/scannow" -Verb RunAs; Log "Đang chạy SFC..." }
        "RunDISM"   { Start-Process "dism" "/online /cleanup-image /restorehealth" -Verb RunAs; Log "Đang chạy DISM..." }
        "RunChkDsk" { Start-Process "cmd" "/k chkdsk C:" -Verb RunAs; Log "Đang chạy ChkDsk..." }
        "RestartExp"{ Stop-Process -Name explorer -Force; Log "Explorer đã khởi động lại." }
        
        # --- NET ---
        "GetPubIP"  { try { $ip = Invoke-RestMethod http://ipinfo.io/ip; Log "IP: $ip" } catch { Log "Lỗi lấy IP." } }
        "PingTest"  { Start-Process "cmd" "/k ping 8.8.8.8"; Log "Pinging..." }
        "FlushDns"  { ipconfig /flushdns; Log "DNS Flushed." }
        "NetReset"  { netsh int ip reset; netsh winsock reset; Log "Reset mạng xong. Cần Restart." }
        "DumpWifi"  { 
            $out = "$env:USERPROFILE\Desktop\PassWifi.txt"; "--- WIFI PASSWORD ---" | Out-File $out -Encoding UTF8
            (netsh wlan show profiles) | Select-String "\:(.+)$" | %{
                $name=$_.Matches.Groups[1].Value.Trim(); $pass=(netsh wlan show profile name="$name" key=clear); 
                "$name : $pass" | Out-File $out -Append -Encoding UTF8
            }; Log "Đã xuất pass ra Desktop." 
        }
        "EditHosts" { Start-Process "notepad" "C:\Windows\System32\drivers\etc\hosts" -Verb RunAs }

        # --- SOFT ---
        "InstChrome"  { Start-Process "winget" "install Google.Chrome -e --silent"; Log "Cài Chrome..." }
        "InstFirefox" { Start-Process "winget" "install Mozilla.Firefox -e --silent"; Log "Cài Firefox..." }
        "InstVSCode"  { Start-Process "winget" "install Microsoft.VisualStudioCode -e --silent"; Log "Cài VS Code..." }
        "InstDiscord" { Start-Process "winget" "install Discord.Discord -e --silent"; Log "Cài Discord..." }
        "InstUnikey"  { Start-Process "winget" "install Unikey.Unikey -e --silent"; Log "Cài Unikey..." }
        "Inst7Zip"    { Start-Process "winget" "install 7zip.7zip -e --silent"; Log "Cài 7-Zip..." }
    }
    $Form.Cursor = "Default"
}

# --- 7. VẼ GAUGE ---
$GaugeBox.Add_Paint({
    param($sender, $e)
    $g = $e.Graphics; $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $DrawArc = { param($x, $val, $color, $label) 
        $rect = New-Object System.Drawing.Rectangle $x, 10, 140, 140
        $penBg = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(40,40,50)), 15
        $penVal = New-Object System.Drawing.Pen $color, 15; $penVal.StartCap="Round"; $penVal.EndCap="Round"
        $angle = [Math]::Min(360, [Math]::Max(0, ($val / 100) * 360))
        $g.DrawArc($penBg, $rect, -90, 360); if($val -gt 0) { $g.DrawArc($penVal, $rect, -90, $angle) }
        $fontBig = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
        $txtSize = $g.MeasureString("$([int]$val)%", $fontBig)
        $g.DrawString("$([int]$val)%", $fontBig, [System.Drawing.Brushes]::White, ($x + 70 - $txtSize.Width/2), 60)
        $fontSm = New-Object System.Drawing.Font("Segoe UI", 10)
        $lblSize = $g.MeasureString($label, $fontSm)
        $g.DrawString($label, $fontSm, [System.Drawing.Brushes]::Gray, ($x + 70 - $lblSize.Width/2), 95)
    }
    & $DrawArc 70 $Global:CpuLoad $Theme.Accent "CPU LOAD"
    & $DrawArc 350 $Global:RamLoad $Theme.Accent2 "RAM USAGE"
})

# --- 8. TIMER MONITOR ---
$Timer = New-Object System.Windows.Forms.Timer; $Timer.Interval = 1500
$Timer.Add_Tick({
    $OS = Get-CimInstance Win32_OperatingSystem
    $Global:CpuLoad = (Get-CimInstance Win32_Processor).LoadPercentage
    $Global:RamLoad = (($OS.TotalVisibleMemorySize - $OS.FreePhysicalMemory) / $OS.TotalVisibleMemorySize) * 100
    $GaugeBox.Invalidate()
    if ($TxtInfo.Text -eq "") {
        $GPU = (Get-CimInstance Win32_VideoController).Name
        $Bat = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
        $BatStatus = if($Bat){ "$($Bat.EstimatedChargeRemaining)% (Sạc: $($Bat.BatteryStatus -eq 2))" } else { "PC (Không Pin)" }
        $TxtInfo.Text = @"
THÔNG TIN HỆ THỐNG
------------------
OS     : $($OS.Caption)
User   : $env:USERNAME
CPU    : $((Get-CimInstance Win32_Processor).Name)
GPU    : $GPU
RAM    : $([Math]::Round($OS.TotalVisibleMemorySize/1MB/1024, 1)) GB
Pin    : $BatStatus
Uptime : $((Get-Date) - $OS.LastBootUpTime | Select -ExpandProperty TotalHours | ForEach {[Math]::Round($_, 1)}) Giờ
"@
    }
})
$Timer.Start()

Switch-Panel ($Sidebar.Controls | Where Tag -eq $P_Dash | Select -First 1)
$Form.ShowDialog() | Out-Null
