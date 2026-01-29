<#
    TITANIUM GOD MODE V6.6 - CLOUD CONFIG EDITION
    Tính năng: 
    - Load cấu hình (Region, Keyboard, Timezone) từ GitHub JSON.
    - Sửa lỗi hiển thị System Info (Xuống dòng, Màu Cyan).
    - Tab Hệ thống: Chỉnh giờ, Múi giờ, Vùng, Bàn phím, 12h/24h.
    Kiến trúc: Hamburger Menu + GDI+ + Networking
#>

# --- 0. KHỞI TẠO AN TOÀN ---
$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

# Kiểm tra Admin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- 1. TẢI CẤU HÌNH TỪ GITHUB ---
$Global:JsonData = $null
try {
    # Link RAW file JSON của bạn
    $JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/language.json"
    $Global:JsonData = Invoke-RestMethod -Uri $JsonUrl -Method Get -TimeoutSec 5
} catch {
    # Dữ liệu dự phòng (Offline Fallback)
    $Global:JsonData = @{
        regions = @(
            @{code="vi-VN"; name="Vietnam (Offline)"},
            @{code="en-US"; name="US (Offline)"}
        )
        timezones = @(
            @{id="SE Asia Standard Time"; name="(UTC+07:00) Bangkok, Hanoi, Jakarta"},
            @{id="Pacific Standard Time"; name="(UTC-08:00) Pacific Time (US & Canada)"}
        )
        keyboards = @(
            @{id="0409:00000409"; name="US (Offline)"}
        )
    }
}

# --- 2. CẤU HÌNH GIAO DIỆN ---
$Theme = @{
    BgForm      = [System.Drawing.Color]::FromArgb(10, 10, 15)
    BgSidebar   = [System.Drawing.Color]::FromArgb(20, 20, 28)
    BgContent   = [System.Drawing.Color]::FromArgb(28, 28, 38)
    BgInput     = [System.Drawing.Color]::FromArgb(45, 45, 55)
    Accent      = [System.Drawing.Color]::FromArgb(0, 210, 255)      # Xanh Neon
    Accent2     = [System.Drawing.Color]::FromArgb(180, 0, 255)      # Tím Neon
    AccentRed   = [System.Drawing.Color]::FromArgb(255, 50, 80)      # Đỏ
    AccentGold  = [System.Drawing.Color]::FromArgb(255, 180, 0)      # Vàng
    TextMain    = [System.Drawing.Color]::WhiteSmoke
    TextInfo    = [System.Drawing.Color]::FromArgb(0, 255, 255)      # Cyan (Màu chữ Info mới)
    Border      = [System.Drawing.Color]::FromArgb(60, 60, 80)
    FontLogo    = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    FontHead    = New-Object System.Drawing.Font("Segoe UI Semibold", 11)
    FontNorm    = New-Object System.Drawing.Font("Segoe UI", 9)
    FontMono    = New-Object System.Drawing.Font("Consolas", 10)
}

# --- 3. FORM CHÍNH ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "TITANIUM V6.6"
$Form.Size = New-Object System.Drawing.Size(1250, 800)
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

# --- 4. LAYOUT ---
$Sidebar = New-Object System.Windows.Forms.Panel; $Sidebar.Dock = "Left"; $Sidebar.Width = 230; $Sidebar.BackColor = $Theme.BgSidebar; $Form.Controls.Add($Sidebar)
$ContentContainer = New-Object System.Windows.Forms.Panel; $ContentContainer.Dock = "Fill"; $ContentContainer.BackColor = $Theme.BgForm; $Form.Controls.Add($ContentContainer); $ContentContainer.BringToFront()
$TopBar = New-Object System.Windows.Forms.Panel; $TopBar.Dock = "Top"; $TopBar.Height = 45; $TopBar.BackColor = $Theme.BgForm; $ContentContainer.Controls.Add($TopBar)
$TopBar.Add_MouseDown({ $Global:IsDragging = $true; $Global:DragStart = $_.Location })
$TopBar.Add_MouseMove({ if ($Global:IsDragging) { $Form.Location = [System.Drawing.Point]::Add($Form.Location, [System.Drawing.Size]::Subtract($_.Location, $Global:DragStart)) } })
$TopBar.Add_MouseUp({ $Global:IsDragging = $false })

# Logo
$PnlLogo = New-Object System.Windows.Forms.Panel; $PnlLogo.Size = New-Object System.Drawing.Size(230, 90); $PnlLogo.Dock="Top"; $PnlLogo.BackColor="Transparent"
$LblLogo = New-Object System.Windows.Forms.Label; $LblLogo.Text = "TITANIUM"; $LblLogo.Font = $Theme.FontLogo; $LblLogo.ForeColor = $Theme.Accent; $LblLogo.AutoSize=$true; $LblLogo.Location=New-Object System.Drawing.Point(20, 20)
$LblVer = New-Object System.Windows.Forms.Label; $LblVer.Text = "CLOUD CONFIG"; $LblVer.Font = $Theme.FontMono; $LblVer.ForeColor = $Theme.AccentGold; $LblVer.AutoSize=$true; $LblVer.Location=New-Object System.Drawing.Point(22, 55)
$PnlLogo.Controls.Add($LblLogo); $PnlLogo.Controls.Add($LblVer); $Sidebar.Controls.Add($PnlLogo)

# Controls
$BtnMenu = New-Object System.Windows.Forms.Label; $BtnMenu.Text = "☰"; $BtnMenu.Font = New-Object System.Drawing.Font("Segoe UI Symbol", 16); $BtnMenu.ForeColor = $Theme.Accent; $BtnMenu.AutoSize = $true; $BtnMenu.Location = New-Object System.Drawing.Point(15, 8); $BtnMenu.Cursor = "Hand"; $BtnMenu.Add_Click({ if ($Sidebar.Visible) { $Sidebar.Visible = $false } else { $Sidebar.Visible = $true } }); $TopBar.Controls.Add($BtnMenu)
$BtnClose = New-Object System.Windows.Forms.Label; $BtnClose.Text="✕"; $BtnClose.Dock="Right"; $BtnClose.Width=50; $BtnClose.TextAlign="MiddleCenter"; $BtnClose.ForeColor=$Theme.AccentRed; $BtnClose.Cursor="Hand"; $BtnClose.Font=$Theme.FontHead; $BtnClose.Add_Click({ $Form.Close() }); $TopBar.Controls.Add($BtnClose)
$BtnMin = New-Object System.Windows.Forms.Label; $BtnMin.Text="—"; $BtnMin.Dock="Right"; $BtnMin.Width=50; $BtnMin.TextAlign="MiddleCenter"; $BtnMin.ForeColor="White"; $BtnMin.Cursor="Hand"; $BtnMin.Font=$Theme.FontHead; $BtnMin.Add_Click({ $Form.WindowState = "Minimized" }); $TopBar.Controls.Add($BtnMin)
$StatusBar = New-Object System.Windows.Forms.Panel; $StatusBar.Dock="Bottom"; $StatusBar.Height=35; $StatusBar.BackColor=$Theme.BgSidebar; $LblStatus = New-Object System.Windows.Forms.Label; $LblStatus.Text="Đã tải config từ GitHub."; $LblStatus.ForeColor=$Theme.Accent; $LblStatus.Dock="Fill"; $LblStatus.TextAlign="MiddleLeft"; $LblStatus.Padding=New-Object System.Windows.Forms.Padding(15,0,0,0); $LblStatus.Font=$Theme.FontMono; $StatusBar.Controls.Add($LblStatus); $ContentContainer.Controls.Add($StatusBar)

# --- 5. HÀM HỖ TRỢ ---
$Global:Panels = @()
function Make-Panel ($Name) {
    $P = New-Object System.Windows.Forms.Panel; $P.Dock = "Fill"; $P.BackColor = $Theme.BgForm; $P.Visible = $false; $P.AutoScroll = $true; $P.Padding = New-Object System.Windows.Forms.Padding(20, 0, 0, 50)
    $ContentContainer.Controls.Add($P); $P.BringToFront(); $Global:Panels += $P; return $P
}
function Add-NavBtn ($Parent, $Text, $Icon, $Y, $PanelToOpen) {
    $Btn = New-Object System.Windows.Forms.Label; $Btn.Text = "  $Icon   $Text"; $Btn.Size = New-Object System.Drawing.Size(230, 50); $Btn.Location = New-Object System.Drawing.Point(0, $Y); $Btn.Font = $Theme.FontHead; $Btn.ForeColor = $Theme.TextMuted; $Btn.TextAlign = "MiddleLeft"; $Btn.Cursor = "Hand"; $Btn.Tag = $PanelToOpen
    $Btn.Add_MouseEnter({ $this.ForeColor = $Theme.Accent; $this.BackColor = [System.Drawing.Color]::FromArgb(35,35,45) }); $Btn.Add_MouseLeave({ if ($script:ActivePanel -ne $this.Tag) { $this.ForeColor = $Theme.TextMuted; $this.BackColor = [System.Drawing.Color]::Transparent } }); $Btn.Add_Click({ Switch-Panel $this }); $Parent.Controls.Add($Btn)
}
function Add-ActionBtn ($Parent, $Text, $Cmd, $X, $Y, $IsDanger=$false, $IsWide=$false) {
    $Btn = New-Object System.Windows.Forms.Button; $Btn.Text = $Text; $Btn.Tag = $Cmd; $Btn.Location = New-Object System.Drawing.Point($X, $Y)
    $Btn.Size = if($IsWide){New-Object System.Drawing.Size(480, 40)}else{New-Object System.Drawing.Size(230, 40)}
    $Btn.FlatStyle = "Flat"; $Btn.Font = $Theme.FontNorm; $Btn.Cursor = "Hand"
    if ($IsDanger) { $Btn.ForeColor = $Theme.AccentRed; $Btn.FlatAppearance.BorderColor = $Theme.AccentRed } else { $Btn.ForeColor = $Theme.TextMain; $Btn.FlatAppearance.BorderColor = $Theme.Border }
    $Btn.FlatAppearance.BorderSize = 1; $Btn.BackColor = $Theme.BgContent
    $Btn.Add_MouseEnter({ $this.BackColor = if($IsDanger){[System.Drawing.Color]::FromArgb(50,20,20)}else{[System.Drawing.Color]::FromArgb(50,50,60)} }); $Btn.Add_MouseLeave({ $this.BackColor = $Theme.BgContent }); $Btn.Add_Click({ Run-Command $this.Tag $this.Text }); $Parent.Controls.Add($Btn)
}
function Add-SectionTitle ($Parent, $Text, $Y) {
    $L = New-Object System.Windows.Forms.Label; $L.Text = $Text; $L.Font = $Theme.FontHead; $L.ForeColor = $Theme.Accent; $L.Location = New-Object System.Drawing.Point(30, $Y); $L.AutoSize = $true; $Parent.Controls.Add($L)
    $Line = New-Object System.Windows.Forms.Panel; $Line.Size = New-Object System.Drawing.Size(800, 1); $Line.BackColor = $Theme.Border; $Line.Location = New-Object System.Drawing.Point(30, $Y+28); $Parent.Controls.Add($Line)
}
function Show-InputBox ($Title, $Prompt) {
    $f = New-Object System.Windows.Forms.Form; $f.Width = 400; $f.Height = 180; $f.Text = $Title; $f.StartPosition = "CenterScreen"; $f.FormBorderStyle = "FixedDialog"; $f.MaximizeBox = $false
    $l = New-Object System.Windows.Forms.Label; $l.Left = 20; $l.Top = 20; $l.Text = $Prompt; $l.AutoSize = $true
    $t = New-Object System.Windows.Forms.TextBox; $t.Left = 20; $t.Top = 50; $t.Width = 340
    $b = New-Object System.Windows.Forms.Button; $b.Left = 260; $b.Top = 90; $b.Text = "OK"; $b.DialogResult = "OK"
    $f.Controls.Add($l); $f.Controls.Add($t); $f.Controls.Add($b); $f.AcceptButton = $b; if ($f.ShowDialog() -eq "OK") { return $t.Text } else { return $null }
}

# --- 6. NỘI DUNG ---

# P1: Dashboard
$P_Dash = Make-Panel "Dashboard"
Add-SectionTitle $P_Dash "GIÁM SÁT HỆ THỐNG" 30
$GaugeBox = New-Object System.Windows.Forms.PictureBox; $GaugeBox.Location = New-Object System.Drawing.Point(30, 70); $GaugeBox.Size = New-Object System.Drawing.Size(820, 160); $GaugeBox.BackColor = "Transparent"; $P_Dash.Controls.Add($GaugeBox)
# SỬA LỖI TEXTBOX: Màu sắc & Xuống dòng
$TxtInfo = New-Object System.Windows.Forms.TextBox
$TxtInfo.Multiline = $true
$TxtInfo.Location = New-Object System.Drawing.Point(30, 250)
$TxtInfo.Size = New-Object System.Drawing.Size(820, 350)
$TxtInfo.BackColor = $Theme.BgInput
$TxtInfo.ForeColor = $Theme.TextInfo # Cyan cho dễ đọc
$TxtInfo.BorderStyle = "None"
$TxtInfo.Font = $Theme.FontMono
$TxtInfo.ReadOnly = $true
$TxtInfo.ScrollBars = "Vertical" # Thêm thanh cuộn
$P_Dash.Controls.Add($TxtInfo)

# P2: System (Advanced)
$P_Sys = Make-Panel "System"
Add-SectionTitle $P_Sys "CÀI ĐẶT CƠ BẢN" 30
Add-ActionBtn $P_Sys "Đổi Tên Máy Tính" "RenPC" 30 70

# -- Ngày & Giờ --
$LblTime = New-Object System.Windows.Forms.Label; $LblTime.Text = "Ngày & Giờ:"; $LblTime.ForeColor="White"; $LblTime.Location = New-Object System.Drawing.Point(30, 120); $LblTime.AutoSize=$true; $P_Sys.Controls.Add($LblTime)
$DtPicker = New-Object System.Windows.Forms.DateTimePicker; $DtPicker.Format="Custom"; $DtPicker.CustomFormat="dd/MM/yyyy HH:mm:ss"; $DtPicker.Location=New-Object System.Drawing.Point(120, 117); $DtPicker.Size=New-Object System.Drawing.Size(200, 25); $P_Sys.Controls.Add($DtPicker)
$BtnSetTime = New-Object System.Windows.Forms.Button; $BtnSetTime.Text="Lưu"; $BtnSetTime.Location=New-Object System.Drawing.Point(330, 115); $BtnSetTime.Size=New-Object System.Drawing.Size(60, 28); $BtnSetTime.FlatStyle="Flat"; $BtnSetTime.ForeColor="White"; $BtnSetTime.BackColor=$Theme.BgInput; $BtnSetTime.Add_Click({ Set-Date -Date $DtPicker.Value; Log "Đã cập nhật ngày giờ!" }); $P_Sys.Controls.Add($BtnSetTime)

# -- Múi Giờ (JSON Load) --
$LblTZ = New-Object System.Windows.Forms.Label; $LblTZ.Text = "Múi Giờ:"; $LblTZ.ForeColor="White"; $LblTZ.Location = New-Object System.Drawing.Point(430, 120); $LblTZ.AutoSize=$true; $P_Sys.Controls.Add($LblTZ)
$CbTZ = New-Object System.Windows.Forms.ComboBox; $CbTZ.Location=New-Object System.Drawing.Point(500, 117); $CbTZ.Size=New-Object System.Drawing.Size(320, 25); $CbTZ.DropDownStyle="DropDownList"; $CbTZ.BackColor="White"; $P_Sys.Controls.Add($CbTZ)
# Ưu tiên load từ JSON
if ($Global:JsonData.timezones) {
    foreach ($tz in $Global:JsonData.timezones) { $CbTZ.Items.Add("$($tz.name) [$($tz.id)]") | Out-Null }
} else {
    # Fallback System List
    $Zones = Get-TimeZone -ListAvailable | Sort-Object BaseUtcOffset
    foreach ($z in $Zones) { $off=if($z.BaseUtcOffset -ge [TimeSpan]::Zero){"+{0:hh\:mm}" -f $z.BaseUtcOffset}else{"{0:hh\:mm}" -f $z.BaseUtcOffset}; $CbTZ.Items.Add("(UTC$off) $($z.Id) [$($z.Id)]") | Out-Null }
}
$BtnSetTZ = New-Object System.Windows.Forms.Button; $BtnSetTZ.Text="Lưu"; $BtnSetTZ.Location=New-Object System.Drawing.Point(830, 115); $BtnSetTZ.Size=New-Object System.Drawing.Size(60, 28); $BtnSetTZ.FlatStyle="Flat"; $BtnSetTZ.ForeColor="White"; $BtnSetTZ.BackColor=$Theme.BgInput
$BtnSetTZ.Add_Click({ if($CbTZ.SelectedItem){ $id=$CbTZ.SelectedItem.ToString().Split("[")[-1].Trim("]"); try{Set-TimeZone -Id $id;Log "Đã đổi múi giờ: $id"}catch{Log "Lỗi: Không tìm thấy ID múi giờ."} } }); $P_Sys.Controls.Add($BtnSetTZ)

# -- 12h/24h --
$LblFmt = New-Object System.Windows.Forms.Label; $LblFmt.Text = "Định dạng:"; $LblFmt.ForeColor="White"; $LblFmt.Location = New-Object System.Drawing.Point(30, 170); $LblFmt.AutoSize=$true; $P_Sys.Controls.Add($LblFmt)
$Rb24 = New-Object System.Windows.Forms.RadioButton; $Rb24.Text="24 Giờ"; $Rb24.ForeColor="White"; $Rb24.Location=New-Object System.Drawing.Point(120, 168); $Rb24.Width=80; $P_Sys.Controls.Add($Rb24)
$Rb12 = New-Object System.Windows.Forms.RadioButton; $Rb12.Text="12 Giờ"; $Rb12.ForeColor="White"; $Rb12.Location=New-Object System.Drawing.Point(200, 168); $Rb12.Width=80; $P_Sys.Controls.Add($Rb12)
$BtnSetFmt = New-Object System.Windows.Forms.Button; $BtnSetFmt.Text="Lưu"; $BtnSetFmt.Location=New-Object System.Drawing.Point(290, 165); $BtnSetFmt.Size=New-Object System.Drawing.Size(60, 28); $BtnSetFmt.FlatStyle="Flat"; $BtnSetFmt.ForeColor="White"; $BtnSetFmt.BackColor=$Theme.BgInput
$BtnSetFmt.Add_Click({ if($Rb24.Checked){ Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name "sShortTime" -Value "HH:mm"; Log "Mode 24H (Logout để apply)" }; if($Rb12.Checked){ Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name "sShortTime" -Value "h:mm tt"; Log "Mode 12H (Logout để apply)" } }); $P_Sys.Controls.Add($BtnSetFmt)

# -- Region (JSON Load) --
$LblLang = New-Object System.Windows.Forms.Label; $LblLang.Text = "Vùng:"; $LblLang.ForeColor="White"; $LblLang.Location = New-Object System.Drawing.Point(400, 170); $LblLang.AutoSize=$true; $P_Sys.Controls.Add($LblLang)
$CbLang = New-Object System.Windows.Forms.ComboBox; $CbLang.Location=New-Object System.Drawing.Point(460, 167); $CbLang.Size=New-Object System.Drawing.Size(200, 25); $CbLang.DropDownStyle="DropDownList"; $CbLang.BackColor="White"; $P_Sys.Controls.Add($CbLang)
if ($Global:JsonData.regions) { foreach ($r in $Global:JsonData.regions) { $CbLang.Items.Add("$($r.name) [$($r.code)]") | Out-Null } }
$BtnSetLang = New-Object System.Windows.Forms.Button; $BtnSetLang.Text="Lưu"; $BtnSetLang.Location=New-Object System.Drawing.Point(670, 165); $BtnSetLang.Size=New-Object System.Drawing.Size(60, 28); $BtnSetLang.FlatStyle="Flat"; $BtnSetLang.ForeColor="White"; $BtnSetLang.BackColor=$Theme.BgInput
$BtnSetLang.Add_Click({ if($CbLang.SelectedItem){ $code=$CbLang.SelectedItem.ToString().Split("[")[1].Trim("]"); Set-Culture $code; Set-WinSystemLocale $code; Log "Đã set vùng: $code" } }); $P_Sys.Controls.Add($BtnSetLang)

# -- Keyboard (JSON Load) --
$LblKb = New-Object System.Windows.Forms.Label; $LblKb.Text = "Bàn phím:"; $LblKb.ForeColor="White"; $LblKb.Location = New-Object System.Drawing.Point(750, 170); $LblKb.AutoSize=$true; $P_Sys.Controls.Add($LblKb)
$CbKb = New-Object System.Windows.Forms.ComboBox; $CbKb.Location=New-Object System.Drawing.Point(820, 167); $CbKb.Size=New-Object System.Drawing.Size(200, 25); $CbKb.DropDownStyle="DropDownList"; $CbKb.BackColor="White"; $P_Sys.Controls.Add($CbKb)
if ($Global:JsonData.keyboards) { foreach ($k in $Global:JsonData.keyboards) { $CbKb.Items.Add("$($k.name) [$($k.id)]") | Out-Null } }
$BtnSetKb = New-Object System.Windows.Forms.Button; $BtnSetKb.Text="Thêm"; $BtnSetKb.Location=New-Object System.Drawing.Point(1030, 165); $BtnSetKb.Size=New-Object System.Drawing.Size(60, 28); $BtnSetKb.FlatStyle="Flat"; $BtnSetKb.ForeColor="White"; $BtnSetKb.BackColor=$Theme.BgInput
$BtnSetKb.Add_Click({ if($CbKb.SelectedItem){ $id=$CbKb.SelectedItem.ToString().Split("[")[-1].Trim("]"); Log "Tính năng thêm KB ($id) bị hạn chế trong PS. Hãy dùng Settings." } }); $P_Sys.Controls.Add($BtnSetKb)

Add-SectionTitle $P_Sys "BẢO MẬT (ADMIN)" 230
Add-ActionBtn $P_Sys "Tắt Thông Báo" "OffNotify" 30 270
Add-ActionBtn $P_Sys "Bật Thông Báo" "OnNotify" 280 270
Add-ActionBtn $P_Sys "Tắt UAC (Im lặng)" "OffUAC" 30 320 $true
Add-ActionBtn $P_Sys "Bật UAC (An toàn)" "OnUAC" 280 320

# P3: Optimize
$P_Opt = Make-Panel "Optimize"
Add-SectionTitle $P_Opt "TỐI ƯU HÓA" 30
Add-ActionBtn $P_Opt "Dọn Rác Sâu" "CleanDeep" 30 70 $false $true
Add-ActionBtn $P_Opt "Xóa Cache Update" "CleanUpd" 30 120
Add-ActionBtn $P_Opt "Tắt Telemetry" "OffTele" 280 120
Add-ActionBtn $P_Opt "Hiệu Suất Cao" "UltPerf" 30 170
Add-ActionBtn $P_Opt "Tắt Ngủ Đông" "OffHiber" 280 170
Add-SectionTitle $P_Opt "BLOATWARE" 230
Add-ActionBtn $P_Opt "Gỡ Cortana" "DelCortana" 30 270 $true
Add-ActionBtn $P_Opt "Gỡ Xbox" "DelXbox" 280 270 $true

# P4: Repair
$P_Repair = Make-Panel "Repair"
Add-SectionTitle $P_Repair "SỬA LỖI" 30
Add-ActionBtn $P_Repair "SFC Scan" "RunSFC" 30 70
Add-ActionBtn $P_Repair "DISM Restore" "RunDISM" 280 70
Add-ActionBtn $P_Repair "Check Disk C:" "RunChkDsk" 30 120
Add-ActionBtn $P_Repair "Reset Explorer" "RestartExp" 280 120

# P5: NetOps
$P_Net = Make-Panel "NetOps"
Add-SectionTitle $P_Net "MẠNG" 30
Add-ActionBtn $P_Net "Xem IP Public" "GetPubIP" 30 70
Add-ActionBtn $P_Net "Ping Google" "PingTest" 280 70
Add-ActionBtn $P_Net "Xóa DNS" "FlushDns" 30 120
Add-ActionBtn $P_Net "Reset Mạng" "NetReset" 280 120 $true
Add-ActionBtn $P_Net "Xuất Pass Wifi" "DumpWifi" 30 220 $false $true

# P6: Software
$P_Soft = Make-Panel "Software"
Add-SectionTitle $P_Soft "CÀI NHANH" 30
Add-ActionBtn $P_Soft "Chrome" "InstChrome" 30 70
Add-ActionBtn $P_Soft "Unikey" "InstUnikey" 280 70
Add-ActionBtn $P_Soft "VS Code" "InstVSCode" 30 120
Add-ActionBtn $P_Soft "7-Zip" "Inst7Zip" 280 120

# --- NAV ---
Add-NavBtn $Sidebar "Tổng Quan" "📊" 100 $P_Dash
Add-NavBtn $Sidebar "Hệ Thống" "⚙️" 150 $P_Sys
Add-NavBtn $Sidebar "Tối Ưu Hóa" "🚀" 200 $P_Opt
Add-NavBtn $Sidebar "Mạng" "🌐" 250 $P_Net
Add-NavBtn $Sidebar "Sửa Chữa" "🛠️" 300 $P_Repair
Add-NavBtn $Sidebar "Phần Mềm" "💾" 350 $P_Soft

# --- LOGIC ---
$script:ActivePanel = $null; $Global:CpuLoad = 0; $Global:RamLoad = 0
function Switch-Panel ($Btn) { $Sidebar.Controls | ?{$_.GetType().Name-eq"Label"-and$_.Tag}|%{$_.ForeColor=$Theme.TextMuted;$_.BackColor="Transparent"}; $Global:Panels | %{$_.Visible=$false}; $Btn.ForeColor=$Theme.Accent;$Btn.BackColor=[System.Drawing.Color]::FromArgb(35,35,45); $Btn.Tag.Visible=$true; $script:ActivePanel=$Btn.Tag }
function Log ($Msg) { $LblStatus.Text = "$(Get-Date -Format 'HH:mm:ss') > $Msg"; $Form.Refresh() }
function Set-Reg ($P, $N, $V) { if(!(Test-Path $P)){New-Item $P -Force|Out-Null}; New-ItemProperty -Path $P -Name $N -Value $V -PropertyType DWord -Force|Out-Null }

function Run-Command ($Cmd, $Desc) {
    Log "Đang chạy: $Desc..."
    $Form.Cursor = "WaitCursor"
    switch ($Cmd) {
        "RenPC" { $n=Show-InputBox "Đổi Tên" "Tên máy mới:"; if($n){try{Rename-Computer $n -ErrorAction Stop;Log "Đã đổi thành $n. Restart máy!"}catch{Log "Lỗi Admin/Tên sai."}} }
        "CleanDeep" { Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue; Log "Đã dọn dẹp." }
        "RunSFC" { Start-Process "sfc" "/scannow" -Verb RunAs; Log "Đang chạy SFC..." }
        "DumpWifi" { $f="$env:USERPROFILE\Desktop\Wifi.txt"; "--- WIFI ---"|Out-File $f -Encoding UTF8; (netsh wlan show profiles)|Select-String "\:(.+)$"|%{$n=$_.Matches.Groups[1].Value.Trim();$p=(netsh wlan show profile name="$n" key=clear);"$n : $p"|Out-File $f -Append -Encoding UTF8}; Log "Đã xuất ra Desktop." }
        "InstChrome" { Start-Process "winget" "install Google.Chrome -e --silent"; Log "Cài Chrome..." }
        "InstUnikey" { Start-Process "winget" "install Unikey.Unikey -e --silent"; Log "Cài Unikey..." }
    }
    $Form.Cursor = "Default"
}

# --- GAUGE ---
$GaugeBox.Add_Paint({ param($s, $e)
    $g=$e.Graphics; $g.SmoothingMode="AntiAlias"
    $Draw={param($x,$v,$c,$l) $r=New-Object System.Drawing.Rectangle $x,10,140,140; $g.DrawArc((New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(40,40,50)),15),$r,-90,360); if($v-gt0){$g.DrawArc((New-Object System.Drawing.Pen $c,15),$r,-90,([Math]::Min(360,[Math]::Max(0,($v/100)*360))))}; $g.DrawString("$([int]$v)%",(New-Object System.Drawing.Font("Segoe UI",20,"Bold")),[System.Drawing.Brushes]::White,($x+70-($g.MeasureString("$([int]$v)%",(New-Object System.Drawing.Font("Segoe UI",20,"Bold"))).Width/2)),60); $g.DrawString($l,(New-Object System.Drawing.Font("Segoe UI",10)),[System.Drawing.Brushes]::Gray,($x+70-($g.MeasureString($l,(New-Object System.Drawing.Font("Segoe UI",10))).Width/2)),95) }
    & $Draw 70 $Global:CpuLoad $Theme.Accent "CPU LOAD"; & $Draw 350 $Global:RamLoad $Theme.Accent2 "RAM USAGE"
})

# --- MONITOR (FIX LINE BREAKS & COLOR) ---
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
        # SỬA LỖI XUỐNG DÒNG VÀ HIỂN THỊ
        $Info = "THÔNG TIN HỆ THỐNG`r`n------------------`r`n"
        $Info += "Hệ Điều Hành : $($OS.Caption)`r`n"
        $Info += "Người Dùng   : $env:USERNAME`r`n"
        $Info += "CPU          : $((Get-CimInstance Win32_Processor).Name)`r`n"
        $Info += "GPU          : $GPU`r`n"
        $Info += "RAM          : $([Math]::Round($OS.TotalVisibleMemorySize/1MB/1024, 1)) GB`r`n"
        $Info += "Pin          : $BatStatus`r`n"
        $Info += "Thời Gian    : $((Get-Date) - $OS.LastBootUpTime | Select -ExpandProperty TotalHours | ForEach {[Math]::Round($_, 1)}) Giờ"
        $TxtInfo.Text = $Info
    }
})
$Timer.Start()

Switch-Panel ($Sidebar.Controls | Where Tag -eq $P_Dash | Select -First 1)
$Form.ShowDialog() | Out-Null
