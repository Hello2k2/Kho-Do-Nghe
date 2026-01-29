<#
    TITANIUM GOD MODE V6.2 - VIETNAMESE & SPACIOUS EDITION
    Kiến trúc: Giao diện Modern + GDI+ Vector Gauges + Winget + PowerGrid
    Ngôn ngữ: Tiếng Việt (Full dấu)
    Sửa lỗi: Tăng khoảng cách lề trái để không bị dính Sidebar
#>

# --- 0. KHỞI TẠO AN TOÀN & FIX FONT TIẾNG VIỆT ---
$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Kiểm tra quyền Admin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- 1. CẤU HÌNH GIAO DIỆN (CYBERPUNK) ---
$Theme = @{
    BgForm      = [System.Drawing.Color]::FromArgb(10, 10, 15)       # Đen thẳm
    BgSidebar   = [System.Drawing.Color]::FromArgb(20, 20, 28)       # Xám tối (Sidebar)
    BgContent   = [System.Drawing.Color]::FromArgb(28, 28, 38)       # Nền nội dung
    BgInput     = [System.Drawing.Color]::FromArgb(15, 15, 20)       # Nền ô nhập liệu
    Accent      = [System.Drawing.Color]::FromArgb(0, 210, 255)      # Xanh Neon
    Accent2     = [System.Drawing.Color]::FromArgb(180, 0, 255)      # Tím Neon
    AccentRed   = [System.Drawing.Color]::FromArgb(255, 50, 80)      # Đỏ Cảnh báo
    AccentGold  = [System.Drawing.Color]::FromArgb(255, 180, 0)      # Vàng Kim
    TextMain    = [System.Drawing.Color]::WhiteSmoke                 # Chữ chính
    TextMuted   = [System.Drawing.Color]::FromArgb(120, 120, 140)    # Chữ mờ
    Border      = [System.Drawing.Color]::FromArgb(60, 60, 80)       # Viền
    FontLogo    = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    FontHead    = New-Object System.Drawing.Font("Segoe UI Semibold", 11)
    FontNorm    = New-Object System.Drawing.Font("Segoe UI", 9)
    FontMono    = New-Object System.Drawing.Font("Consolas", 9)
}

# --- 2. THIẾT LẬP FORM CHÍNH ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "TITANIUM V6.2 VIETNAMESE"
$Form.Size = New-Object System.Drawing.Size(1200, 750) # Tăng kích thước chút cho thoáng
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "None"
$Form.BackColor = $Theme.BgForm
$Form.ForeColor = $Theme.TextMain
$Form.DoubleBuffered = $true 

# Kéo thả cửa sổ (Drag Logic)
$IsDragging = $false; $DragStart = [System.Drawing.Point]::Empty
$Form.Add_MouseDown({ $Global:IsDragging = $true; $Global:DragStart = $_.Location })
$Form.Add_MouseMove({ if ($Global:IsDragging) { $Form.Location = [System.Drawing.Point]::Add($Form.Location, [System.Drawing.Size]::Subtract($_.Location, $Global:DragStart)) } })
$Form.Add_MouseUp({ $Global:IsDragging = $false })

# --- 3. BỘ CÔNG CỤ XÂY DỰNG GIAO DIỆN ---

# Nút Sidebar (Menu trái)
function Add-NavBtn ($Parent, $Text, $Icon, $Y, $PanelToOpen) {
    $Btn = New-Object System.Windows.Forms.Label
    $Btn.Text = "  $Icon   $Text"
    $Btn.Size = New-Object System.Drawing.Size(220, 50) # Tăng chiều cao nút
    $Btn.Location = New-Object System.Drawing.Point(0, $Y)
    $Btn.Font = $Theme.FontHead
    $Btn.ForeColor = $Theme.TextMuted
    $Btn.TextAlign = "MiddleLeft"
    $Btn.Cursor = "Hand"
    $Btn.Tag = $PanelToOpen

    $Btn.Add_MouseEnter({ 
        $this.ForeColor = $Theme.Accent
        $this.BackColor = [System.Drawing.Color]::FromArgb(35,35,45)
    })
    $Btn.Add_MouseLeave({ 
        if ($script:ActivePanel -ne $this.Tag) {
            $this.ForeColor = $Theme.TextMuted
            $this.BackColor = [System.Drawing.Color]::Transparent
        }
    })
    $Btn.Add_Click({ Switch-Panel $this })
    $Parent.Controls.Add($Btn)
}

# Nút Chức năng (Content Button)
function Add-ActionBtn ($Parent, $Text, $Cmd, $X, $Y, $IsDanger=$false, $IsWide=$false) {
    # TỰ ĐỘNG CỘNG THÊM 30PX VÀO TỌA ĐỘ X ĐỂ KHÔNG DÍNH SIDEBAR
    $RealX = $X + 30 
    
    $Btn = New-Object System.Windows.Forms.Button
    $Btn.Text = $Text
    $Btn.Tag = $Cmd
    $Btn.Location = New-Object System.Drawing.Point($RealX, $Y)
    $Btn.Size = if($IsWide){New-Object System.Drawing.Size(490, 38)}else{New-Object System.Drawing.Size(235, 38)}
    $Btn.FlatStyle = "Flat"
    $Btn.Font = $Theme.FontNorm
    $Btn.Cursor = "Hand"
    
    if ($IsDanger) {
        $Btn.ForeColor = $Theme.AccentRed
        $Btn.FlatAppearance.BorderColor = $Theme.AccentRed
    } else {
        $Btn.ForeColor = $Theme.TextMain
        $Btn.FlatAppearance.BorderColor = $Theme.Border
    }
    $Btn.FlatAppearance.BorderSize = 1
    $Btn.BackColor = $Theme.BgContent

    $Btn.Add_MouseEnter({ $this.BackColor = if($IsDanger){[System.Drawing.Color]::FromArgb(50,20,20)}else{[System.Drawing.Color]::FromArgb(50,50,60)} })
    $Btn.Add_MouseLeave({ $this.BackColor = $Theme.BgContent })
    $Btn.Add_Click({ Run-Command $this.Tag $this.Text })
    $Parent.Controls.Add($Btn)
}

# Tiêu đề mục (Section Title)
function Add-SectionTitle ($Parent, $Text, $Y) {
    # TỰ ĐỘNG CỘNG THÊM 30PX VÀO TỌA ĐỘ X
    $RealX = 60 # Gốc cũ là 30, giờ đẩy ra 60

    $L = New-Object System.Windows.Forms.Label; $L.Text = $Text
    $L.Font = $Theme.FontHead; $L.ForeColor = $Theme.Accent
    $L.Location = New-Object System.Drawing.Point($RealX, $Y); $L.AutoSize = $true
    $Parent.Controls.Add($L)
    $Line = New-Object System.Windows.Forms.Panel; $Line.Size = New-Object System.Drawing.Size(800, 1)
    $Line.BackColor = $Theme.Border; $Line.Location = New-Object System.Drawing.Point($RealX, $Y+28)
    $Parent.Controls.Add($Line)
}

# --- 4. CẤU TRÚC LAYOUT ---

# Sidebar (Cột trái)
$Sidebar = New-Object System.Windows.Forms.Panel; $Sidebar.Dock = "Left"; $Sidebar.Width = 220; $Sidebar.BackColor = $Theme.BgSidebar
$Form.Controls.Add($Sidebar)

# Logo Area
$PnlLogo = New-Object System.Windows.Forms.Panel; $PnlLogo.Size = New-Object System.Drawing.Size(220, 90); $PnlLogo.Dock="Top"; $PnlLogo.BackColor="Transparent"
$LblLogo = New-Object System.Windows.Forms.Label; $LblLogo.Text = "TITANIUM"; $LblLogo.Font = $Theme.FontLogo; $LblLogo.ForeColor = $Theme.Accent; $LblLogo.AutoSize=$true; $LblLogo.Location=New-Object System.Drawing.Point(20, 20)
$LblVer = New-Object System.Windows.Forms.Label; $LblVer.Text = "VN EDITION V6.2"; $LblVer.Font = $Theme.FontMono; $LblVer.ForeColor = $Theme.AccentGold; $LblVer.AutoSize=$true; $LblVer.Location=New-Object System.Drawing.Point(22, 55)
$PnlLogo.Controls.Add($LblLogo); $PnlLogo.Controls.Add($LblVer); $Sidebar.Controls.Add($PnlLogo)

# Content Container (Vùng nội dung)
$ContentContainer = New-Object System.Windows.Forms.Panel; $ContentContainer.Dock = "Fill"; $ContentContainer.BackColor = $Theme.BgForm
$Form.Controls.Add($ContentContainer)

# Top Bar (Thanh trên cùng)
$TopBar = New-Object System.Windows.Forms.Panel; $TopBar.Dock="Top"; $TopBar.Height=35; $TopBar.BackColor="Transparent"
$TopBar.Add_MouseDown({ $Global:IsDragging = $true; $Global:DragStart = $_.Location })
$TopBar.Add_MouseMove({ if ($Global:IsDragging) { $Form.Location = [System.Drawing.Point]::Add($Form.Location, [System.Drawing.Size]::Subtract($_.Location, $Global:DragStart)) } })
$TopBar.Add_MouseUp({ $Global:IsDragging = $false })

$BtnClose = New-Object System.Windows.Forms.Label; $BtnClose.Text="✕"; $BtnClose.Dock="Right"; $BtnClose.Width=45; $BtnClose.TextAlign="MiddleCenter"; $BtnClose.ForeColor=$Theme.AccentRed; $BtnClose.Cursor="Hand"; $BtnClose.Font=$Theme.FontHead
$BtnClose.Add_Click({ $Form.Close() })
$BtnMin = New-Object System.Windows.Forms.Label; $BtnMin.Text="—"; $BtnMin.Dock="Right"; $BtnMin.Width=45; $BtnMin.TextAlign="MiddleCenter"; $BtnMin.ForeColor="White"; $BtnMin.Cursor="Hand"; $BtnMin.Font=$Theme.FontHead
$BtnMin.Add_Click({ $Form.WindowState = "Minimized" })
$TopBar.Controls.Add($BtnClose); $TopBar.Controls.Add($BtnMin)
$ContentContainer.Controls.Add($TopBar)

# Status Bar (Thanh trạng thái dưới cùng)
$StatusBar = New-Object System.Windows.Forms.Panel; $StatusBar.Dock="Bottom"; $StatusBar.Height=35; $StatusBar.BackColor=$Theme.BgSidebar
$LblStatus = New-Object System.Windows.Forms.Label; $LblStatus.Text="Hệ thống đã sẵn sàng. Chờ lệnh..."; $LblStatus.ForeColor=$Theme.Accent; $LblStatus.Dock="Fill"; $LblStatus.TextAlign="MiddleLeft"; $LblStatus.Padding=New-Object System.Windows.Forms.Padding(15,0,0,0); $LblStatus.Font=$Theme.FontMono
$StatusBar.Controls.Add($LblStatus)
$ContentContainer.Controls.Add($StatusBar)

# --- 5. PANELS & NỘI DUNG (ĐÃ BẬT SCROLL & CĂN LỀ) ---
$Global:Panels = @()
function Make-Panel ($Name) {
    $P = New-Object System.Windows.Forms.Panel
    $P.Dock = "Fill"
    $P.BackColor = $Theme.BgForm
    $P.Visible = $false
    
    # BẬT THANH CUỘN VÀ TĂNG PADDING
    $P.AutoScroll = $true 
    $P.Padding = New-Object System.Windows.Forms.Padding(0, 0, 0, 50)
    
    $ContentContainer.Controls.Add($P)
    $P.BringToFront()
    $Global:Panels += $P
    return $P
}

# --- P1: DASHBOARD (TRUNG TÂM) ---
$P_Dash = Make-Panel "Dashboard"
Add-SectionTitle $P_Dash "GIÁM SÁT HỆ THỐNG" 20
# Dịch chuyển GaugeBox sang phải (X=60)
$GaugeBox = New-Object System.Windows.Forms.PictureBox; $GaugeBox.Location = New-Object System.Drawing.Point(60, 60); $GaugeBox.Size = New-Object System.Drawing.Size(820, 160); $GaugeBox.BackColor = "Transparent"; $P_Dash.Controls.Add($GaugeBox)
# Dịch chuyển TextBox thông tin sang phải (X=60)
$TxtInfo = New-Object System.Windows.Forms.TextBox; $TxtInfo.Multiline=$true; $TxtInfo.Location=New-Object System.Drawing.Point(60, 240); $TxtInfo.Size=New-Object System.Drawing.Size(820, 300); $TxtInfo.BackColor=$Theme.BgInput; $TxtInfo.ForeColor=$Theme.TextMain; $TxtInfo.BorderStyle="None"; $TxtInfo.Font=$Theme.FontMono; $TxtInfo.ReadOnly=$true; $P_Dash.Controls.Add($TxtInfo)

# --- P2: OPTIMIZE (TỐI ƯU) ---
$P_Opt = Make-Panel "Optimize"
Add-SectionTitle $P_Opt "DỌN DẸP & TĂNG TỐC" 20
# Lưu ý: Hàm Add-ActionBtn đã tự động cộng thêm 30px vào X. Nên nhập gốc là 30 -> thực tế là 60.
Add-ActionBtn $P_Opt "Dọn Rác Sâu (Temp & Log)" "CleanDeep" 30 60 $false $true
Add-ActionBtn $P_Opt "Xóa Cache Windows Update" "CleanUpd" 30 110
Add-ActionBtn $P_Opt "Tắt Theo Dõi (Telemetry)" "OffTele" 285 110
Add-ActionBtn $P_Opt "Chế Độ Hiệu Suất Cao" "UltPerf" 30 160
Add-ActionBtn $P_Opt "Tắt Ngủ Đông (Tiết kiệm ổ cứng)" "OffHiber" 285 160

Add-SectionTitle $P_Opt "GỠ BỎ APP RÁC (BLOATWARE)" 220
Add-ActionBtn $P_Opt "Gỡ Cortana" "DelCortana" 30 260 $true
Add-ActionBtn $P_Opt "Gỡ Xbox Apps" "DelXbox" 285 260 $true
Add-ActionBtn $P_Opt "Gỡ OneDrive" "DelOneDrive" 30 310 $true
Add-ActionBtn $P_Opt "Gỡ Edge (Nguy hiểm)" "DelEdge" 285 310 $true

# --- P3: REPAIR (SỬA LỖI) ---
$P_Repair = Make-Panel "Repair"
Add-SectionTitle $P_Repair "SỬA LỖI WINDOWS" 20
Add-ActionBtn $P_Repair "Quét SFC (Sửa file hệ thống)" "RunSFC" 30 60
Add-ActionBtn $P_Repair "Chạy DISM (Sửa ảnh Win)" "RunDISM" 285 60
Add-ActionBtn $P_Repair "Check Disk (Ổ C:)" "RunChkDsk" 30 110
Add-ActionBtn $P_Repair "Khởi động lại Explorer" "RestartExp" 285 110

Add-SectionTitle $P_Repair "SỬA LỖI KHÁC" 170
Add-ActionBtn $P_Repair "Sửa lỗi máy in (Spooler)" "FixPrint" 30 210
Add-ActionBtn $P_Repair "Cài lại Microsoft Store" "FixStore" 285 210

# --- P4: NET OPS (MẠNG) ---
$P_Net = Make-Panel "NetOps"
Add-SectionTitle $P_Net "CÔNG CỤ MẠNG" 20
Add-ActionBtn $P_Net "Xem IP Công Khai (Public IP)" "GetPubIP" 30 60
Add-ActionBtn $P_Net "Ping Google (Kiểm tra mạng)" "PingTest" 285 60
Add-ActionBtn $P_Net "Xóa Cache DNS (Flush)" "FlushDns" 30 110
Add-ActionBtn $P_Net "Reset Mạng (TCP/IP)" "NetReset" 285 110 $true

Add-SectionTitle $P_Net "TIỆN ÍCH NÂNG CAO" 170
Add-ActionBtn $P_Net "Xuất Mật Khẩu Wi-Fi ra Desktop" "DumpWifi" 30 210 $false $true
Add-ActionBtn $P_Net "Sửa file Hosts" "EditHosts" 30 260
Add-ActionBtn $P_Net "Quản lý Adapter Mạng" "OpenNcpa" 285 260

# --- P5: POWER GRID (NGUỒN) ---
$P_Power = Make-Panel "PowerGrid"
Add-SectionTitle $P_Power "ĐIỀU KHIỂN PHIÊN" 20
Add-ActionBtn $P_Power "Khóa Màn Hình (Lock)" "PowerLock" 30 60
Add-ActionBtn $P_Power "Đăng Xuất (Sign Out)" "PowerLogoff" 285 60
Add-ActionBtn $P_Power "Ngủ (Sleep)" "PowerSleep" 30 110
Add-ActionBtn $P_Power "Ngủ Đông (Hibernate)" "PowerHiber" 285 110

Add-SectionTitle $P_Power "HẸN GIỜ TẮT MÁY" 170
Add-ActionBtn $P_Power "Tắt sau 30 Phút" "Shut30" 30 210
Add-ActionBtn $P_Power "Tắt sau 1 Giờ" "Shut60" 285 210
Add-ActionBtn $P_Power "Tắt sau 2 Giờ" "Shut120" 30 260
Add-ActionBtn $P_Power "HỦY LỆNH TẮT MÁY" "ShutAbort" 285 260 $true

# --- P6: SOFTWARE HUB (PHẦN MỀM) ---
$P_Soft = Make-Panel "Software"
Add-SectionTitle $P_Soft "TRÌNH DUYỆT WEB" 20
Add-ActionBtn $P_Soft "Cài Chrome" "InstChrome" 30 60
Add-ActionBtn $P_Soft "Cài Firefox" "InstFirefox" 285 60
Add-ActionBtn $P_Soft "Cài Brave" "InstBrave" 540 60

Add-SectionTitle $P_Soft "LẬP TRÌNH & CHAT" 110
Add-ActionBtn $P_Soft "Cài VS Code" "InstVSCode" 30 150
Add-ActionBtn $P_Soft "Cài Discord" "InstDiscord" 285 150
Add-ActionBtn $P_Soft "Cài Zalo" "InstZalo" 540 150

Add-SectionTitle $P_Soft "VĂN PHÒNG & TIỆN ÍCH" 200
Add-ActionBtn $P_Soft "Cài Unikey" "InstUnikey" 30 240
Add-ActionBtn $P_Soft "Cài 7-Zip" "Inst7Zip" 285 240
Add-ActionBtn $P_Soft "Cài OBS Studio" "InstOBS" 540 240

# --- NAV LINKING (MENU TRÁI) ---
Add-NavBtn $Sidebar "Trung Tâm" "📊" 100 $P_Dash
Add-NavBtn $Sidebar "Tối Ưu Hóa" "🚀" 150 $P_Opt
Add-NavBtn $Sidebar "Mạng & Net" "🌐" 200 $P_Net
Add-NavBtn $Sidebar "Nguồn Điện" "⚡" 250 $P_Power
Add-NavBtn $Sidebar "Sửa Chữa" "🛠️" 300 $P_Repair
Add-NavBtn $Sidebar "Kho Phần Mềm" "💾" 350 $P_Soft

# --- 6. LOGIC XỬ LÝ ---
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
    Log "Đang thực hiện: $Desc..."
    $Form.Cursor = "WaitCursor"
    
    switch ($Cmd) {
        # Optimize
        "CleanDeep" { Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item "$env:windir\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue; Log "Đã dọn dẹp sạch sẽ!" }
        "CleanUpd"  { Stop-Service wuauserv; Remove-Item "$env:windir\SoftwareDistribution\Download\*" -Recurse -Force; Start-Service wuauserv; Log "Đã xóa Cache Update!" }
        "UltPerf"   { powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61; Log "Đã bật chế độ Hiệu suất đỉnh cao!" }
        "OffTele"   { Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0; Log "Đã tắt Telemetry!" }
        "OffHiber"  { powercfg -h off; Log "Đã tắt Ngủ đông (Giải phóng ổ cứng)." }
        "DelCortana"{ Get-AppxPackage -allusers *Cortana* | Remove-AppxPackage; Log "Đã gỡ Cortana." }
        "DelXbox"   { Get-AppxPackage *xbox* | Remove-AppxPackage; Log "Đã gỡ Xbox Apps." }
        "DelOneDrive"{ Stop-Process -Name "OneDrive" -Force; Start-Process "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" "/uninstall" -Wait; Log "Đã gỡ OneDrive." }
        
        # Repair
        "RunSFC"    { Start-Process "sfc" "/scannow" -Verb RunAs; Log "Đang chạy SFC..." }
        "RunDISM"   { Start-Process "dism" "/online /cleanup-image /restorehealth" -Verb RunAs; Log "Đang chạy DISM..." }
        "RunChkDsk" { Start-Process "cmd" "/k chkdsk C:" -Verb RunAs; Log "Đang chạy Check Disk..." }
        "RestartExp"{ Stop-Process -Name explorer -Force; Log "Đã khởi động lại Explorer." }
        "FixPrint"  { Restart-Service spooler; Log "Đã reset Spooler máy in." }
        
        # NetOps
        "GetPubIP"  { try { $ip = Invoke-RestMethod http://ipinfo.io/ip; Log "IP Công khai của bạn: $ip" } catch { Log "Không lấy được IP." } }
        "PingTest"  { Start-Process "cmd" "/k ping 8.8.8.8"; Log "Đang Ping Google..." }
        "FlushDns"  { ipconfig /flushdns; Log "Đã xóa Cache DNS." }
        "NetReset"  { netsh int ip reset; netsh winsock reset; Log "Đã reset mạng. Cần khởi động lại máy!" }
        "DumpWifi"  { 
            $out = "$env:USERPROFILE\Desktop\MatKhauWifi.txt"; "--- DANH SÁCH MẬT KHẨU WI-FI ---" | Out-File $out -Encoding UTF8
            (netsh wlan show profiles) | Select-String "\:(.+)$" | %{
                $name=$_.Matches.Groups[1].Value.Trim(); $pass=(netsh wlan show profile name="$name" key=clear); 
                "$name : $pass" | Out-File $out -Append -Encoding UTF8
            }; Log "Đã xuất file mật khẩu ra Desktop!" 
        }
        "EditHosts" { Start-Process "notepad" "C:\Windows\System32\drivers\etc\hosts" -Verb RunAs }
        "OpenNcpa"  { Start-Process "ncpa.cpl" }

        # PowerGrid
        "PowerLock"   { rundll32.exe user32.dll,LockWorkStation }
        "PowerLogoff" { shutdown -l }
        "PowerSleep"  { [System.Windows.Forms.Application]::SetSuspendState([System.Windows.Forms.PowerState]::Suspend, $false, $false) }
        "PowerHiber"  { [System.Windows.Forms.Application]::SetSuspendState([System.Windows.Forms.PowerState]::Hibernate, $false, $false) }
        "Shut30"      { shutdown -s -t 1800; Log "Máy sẽ tắt sau 30 phút." }
        "Shut60"      { shutdown -s -t 3600; Log "Máy sẽ tắt sau 1 giờ." }
        "Shut120"     { shutdown -s -t 7200; Log "Máy sẽ tắt sau 2 giờ." }
        "ShutAbort"   { shutdown -a; Log "Đã hủy lệnh tắt máy!" }

        # Software
        "InstChrome"  { Start-Process "winget" "install Google.Chrome -e --silent"; Log "Đang cài Chrome..." }
        "InstFirefox" { Start-Process "winget" "install Mozilla.Firefox -e --silent"; Log "Đang cài Firefox..." }
        "InstBrave"   { Start-Process "winget" "install Brave.Brave -e --silent"; Log "Đang cài Brave..." }
        "InstVSCode"  { Start-Process "winget" "install Microsoft.VisualStudioCode -e --silent"; Log "Đang cài VS Code..." }
        "InstDiscord" { Start-Process "winget" "install Discord.Discord -e --silent"; Log "Đang cài Discord..." }
        "InstZalo"    { Start-Process "winget" "install VNG.Zalo -e --silent"; Log "Đang cài Zalo..." }
        "InstUnikey"  { Start-Process "winget" "install Unikey.Unikey -e --silent"; Log "Đang cài Unikey..." }
        "Inst7Zip"    { Start-Process "winget" "install 7zip.7zip -e --silent"; Log "Đang cài 7-Zip..." }
        "InstOBS"     { Start-Process "winget" "install OBSProject.OBSStudio -e --silent"; Log "Đang cài OBS..." }
    }
    $Form.Cursor = "Default"
}

# --- 7. VẼ ĐỒ HỌA (GAUGES) ---
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
    # Đã dịch chuyển vị trí vẽ để cân đối hơn
    & $DrawArc 70 $Global:CpuLoad $Theme.Accent "CPU LOAD"
    & $DrawArc 350 $Global:RamLoad $Theme.Accent2 "RAM USAGE"
})

# --- 8. ĐỘNG CƠ GIÁM SÁT ---
$Timer = New-Object System.Windows.Forms.Timer; $Timer.Interval = 1500
$Timer.Add_Tick({
    $OS = Get-CimInstance Win32_OperatingSystem
    $Global:CpuLoad = (Get-CimInstance Win32_Processor).LoadPercentage
    $Global:RamLoad = (($OS.TotalVisibleMemorySize - $OS.FreePhysicalMemory) / $OS.TotalVisibleMemorySize) * 100
    $GaugeBox.Invalidate()
    if ($TxtInfo.Text -eq "") {
        $GPU = (Get-CimInstance Win32_VideoController).Name
        $Bat = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
        $BatStatus = if($Bat){ "$($Bat.EstimatedChargeRemaining)% (Đang sạc: $($Bat.BatteryStatus -eq 2))" } else { "N/A (Máy bàn)" }
        $TxtInfo.Text = @"
THÔNG TIN HỆ THỐNG [V6.2]
--------------------------------
Hệ Điều Hành: $($OS.Caption) ($($OS.OSArchitecture))
Người dùng  : $env:USERNAME
CPU         : $((Get-CimInstance Win32_Processor).Name)
GPU         : $GPU
RAM         : $([Math]::Round($OS.TotalVisibleMemorySize/1MB/1024, 1)) GB
Pin         : $BatStatus
Thời gian chạy: $((Get-Date) - $OS.LastBootUpTime | Select -ExpandProperty TotalHours | ForEach {[Math]::Round($_, 1)}) Giờ
"@
    }
})
$Timer.Start()

# --- KHỞI CHẠY ---
Switch-Panel ($Sidebar.Controls | Where Tag -eq $P_Dash | Select -First 1)
$Form.ShowDialog() | Out-Null
