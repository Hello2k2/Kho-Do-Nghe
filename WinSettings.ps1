<#
    TITANIUM GOD MODE V7.0 - ULTIMATE RGB EDITION
    Tính năng: 
    - Giao diện Card (Thẻ) hiện đại với hiệu ứng Hover RGB.
    - Chế độ Light/Dark Mode chuyển đổi tức thì.
    - Quản lý User (Pass, Admin Group) & Workgroup chuyên sâu.
    - Load Config từ GitHub.
#>

# --- 0. KHỞI TẠO ---
$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

# Check Admin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- 1. TẢI CẤU HÌNH CLOUD ---
$Global:JsonData = $null
try {
    $JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/language.json"
    $Global:JsonData = Invoke-RestMethod -Uri $JsonUrl -Method Get -TimeoutSec 3
} catch {
    $Global:JsonData = @{ regions=@(@{code="vi-VN";name="Vietnam"}); timezones=@(@{id="SE Asia Standard Time";name="(UTC+07:00) Vietnam"}) }
}

# --- 2. ENGINE GIAO DIỆN (THEME & RGB) ---
$Global:DarkMode = $true
$Global:ControlsToUpdate = @()

function Get-Theme {
    if ($Global:DarkMode) {
        return @{
            BgForm="#121215"; BgSidebar="#1A1A20"; BgCard="#252530"; Text="#FFFFFF"; 
            TextMuted="#888899"; Border="#333340"; Accent="#00D0FF"; Accent2="#FF0055"
        }
    } else {
        return @{
            BgForm="#F0F2F5"; BgSidebar="#FFFFFF"; BgCard="#FFFFFF"; Text="#222222"; 
            TextMuted="#666666"; Border="#DDEEFF"; Accent="#007ACC"; Accent2="#FF3366"
        }
    }
}

function Color-FromHex ($Hex) { return [System.Drawing.ColorTranslator]::FromHtml($Hex) }

# --- 3. FORM CHÍNH ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "TITANIUM V7.0"
$Form.Size = New-Object System.Drawing.Size(1280, 800)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "None"
$Form.DoubleBuffered = $true

# Drag Logic
$IsDragging=$false; $DragStart=[System.Drawing.Point]::Empty
$Form.Add_MouseDown({ $Global:IsDragging=$true; $Global:DragStart=$_.Location })
$Form.Add_MouseMove({ if($Global:IsDragging){$Form.Location=[System.Drawing.Point]::Add($Form.Location,[System.Drawing.Size]::Subtract($_.Location,$Global:DragStart))} })
$Form.Add_MouseUp({ $Global:IsDragging=$false })

# --- 4. LAYOUT ---
$T = Get-Theme
$Form.BackColor = Color-FromHex $T.BgForm

$Sidebar = New-Object System.Windows.Forms.Panel; $Sidebar.Dock="Left"; $Sidebar.Width=240
$Content = New-Object System.Windows.Forms.Panel; $Content.Dock="Fill"
$TopBar  = New-Object System.Windows.Forms.Panel; $TopBar.Dock="Top"; $TopBar.Height=50
$Form.Controls.Add($Content); $Form.Controls.Add($Sidebar); $Content.Controls.Add($TopBar)

# Apply Theme Function
function Apply-Theme {
    $T = Get-Theme
    $Form.BackColor = Color-FromHex $T.BgForm
    $Sidebar.BackColor = Color-FromHex $T.BgSidebar
    $Content.BackColor = Color-FromHex $T.BgForm
    $TopBar.BackColor = Color-FromHex $T.BgForm
    
    # Update Status
    $Global:LblStatus.BackColor = Color-FromHex $T.BgSidebar
    $Global:LblStatus.ForeColor = Color-FromHex $T.Accent

    # Update Cards
    foreach ($ctrl in $Global:ControlsToUpdate) {
        if ($ctrl.GetType().Name -eq "Button" -or $ctrl.GetType().Name -eq "Panel") {
            $ctrl.BackColor = Color-FromHex $T.BgCard
            $ctrl.ForeColor = Color-FromHex $T.Text
            if ($ctrl.Tag -eq "SIDEBTN") { $ctrl.ForeColor = Color-FromHex $T.TextMuted; $ctrl.BackColor="Transparent" }
        }
    }
    $Form.Refresh()
}

# --- 5. COMPONENT BUILDER (CARD STYLE) ---

# Nút Menu Sidebar
function Add-NavBtn ($Text, $Icon, $Y, $PanelTag) {
    $Btn = New-Object System.Windows.Forms.Label
    $Btn.Text = "  $Icon   $Text"; $Btn.Size = New-Object System.Drawing.Size(240, 55); $Btn.Location = New-Object System.Drawing.Point(0, $Y)
    $Btn.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 11)
    $Btn.TextAlign = "MiddleLeft"; $Btn.Cursor = "Hand"; $Btn.Tag = "SIDEBTN"
    
    $Btn.Add_MouseEnter({ 
        $T=Get-Theme; $this.ForeColor=Color-FromHex $T.Accent
        $this.BackColor=Color-FromHex $T.BgCard 
    })
    $Btn.Add_MouseLeave({ 
        $T=Get-Theme; if($script:ActivePanel -ne $this.Tag2){ $this.ForeColor=Color-FromHex $T.TextMuted; $this.BackColor="Transparent" }
    })
    $Btn.Add_Click({ Switch-Panel $this })
    $Btn.Tag2 = $PanelTag # Link to Panel
    
    $Sidebar.Controls.Add($Btn)
    $Global:ControlsToUpdate += $Btn
    return $Btn
}

# CARD BUTTON (THAY THẾ NÚT THƯỜNG)
function Add-CardBtn ($Parent, $Text, $Cmd, $X, $Y, $Wide=$false) {
    $Btn = New-Object System.Windows.Forms.Button
    $Btn.Text = $Text
    $Btn.Tag = $Cmd
    $Btn.Location = New-Object System.Drawing.Point($X, $Y)
    $Btn.Size = if($Wide){New-Object System.Drawing.Size(480, 45)}else{New-Object System.Drawing.Size(230, 45)}
    $Btn.FlatStyle = "Flat"
    $Btn.FlatAppearance.BorderSize = 0
    $Btn.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $Btn.Cursor = "Hand"
    $Btn.TextAlign = "MiddleLeft"
    $Btn.Padding = New-Object System.Windows.Forms.Padding(15,0,0,0)
    
    # Custom Paint cho hiệu ứng Viền RGB/Gradient
    $Btn.Add_Paint({ param($s, $e)
        $T = Get-Theme
        $g = $e.Graphics; $g.SmoothingMode = "AntiAlias"
        
        # Vẽ viền trái màu Accent (Giả lập Card)
        $pen = New-Object System.Drawing.Pen (Color-FromHex $T.Accent), 4
        $g.DrawLine($pen, 0, 0, 0, $s.Height)
        
        # Nếu Hover thì vẽ viền bao quanh
        if ($s.ClientRectangle.Contains($s.PointToClient([System.Windows.Forms.Control]::MousePosition))) {
            $penBorder = New-Object System.Drawing.Pen (Color-FromHex $T.Accent2), 2
            $g.DrawRectangle($penBorder, 1, 1, $s.Width-2, $s.Height-2)
        }
    })

    $Btn.Add_Click({ Run-Command $this.Tag $this.Text })
    $Parent.Controls.Add($Btn)
    $Global:ControlsToUpdate += $Btn
}

function Add-Title ($Parent, $Text, $Y) {
    $L = New-Object System.Windows.Forms.Label
    $L.Text = $Text; $L.Font = New-Object System.Drawing.Font("Segoe UI", 12, "Bold")
    $L.ForeColor = [System.Drawing.Color]::Gray; $L.AutoSize=$true
    $L.Location = New-Object System.Drawing.Point(30, $Y)
    $Parent.Controls.Add($L)
}

function Show-Input ($Title, $Msg) {
    [Microsoft.VisualBasic.Interaction]::InputBox($Msg, $Title)
}

# --- 6. HEADER & CONTROLS ---

# Logo
$LblLogo = New-Object System.Windows.Forms.Label; $LblLogo.Text="TITANIUM"; $LblLogo.Font=New-Object System.Drawing.Font("Segoe UI",18,"Bold"); $LblLogo.ForeColor=[System.Drawing.Color]::Cyan; $LblLogo.AutoSize=$true; $LblLogo.Location=New-Object System.Drawing.Point(20,20); $Sidebar.Controls.Add($LblLogo)
$LblVer = New-Object System.Windows.Forms.Label; $LblVer.Text="V7.0 RGB"; $LblVer.Font=New-Object System.Drawing.Font("Consolas",10); $LblVer.ForeColor=[System.Drawing.Color]::Orange; $LblVer.AutoSize=$true; $LblVer.Location=New-Object System.Drawing.Point(22,55); $Sidebar.Controls.Add($LblVer)

# TopBar Btns
$BtnMenu = New-Object System.Windows.Forms.Label; $BtnMenu.Text="☰"; $BtnMenu.Font=New-Object System.Drawing.Font("Segoe UI",16); $BtnMenu.AutoSize=$true; $BtnMenu.Location=New-Object System.Drawing.Point(15,10); $BtnMenu.Cursor="Hand"; $BtnMenu.ForeColor=[System.Drawing.Color]::Gray
$BtnMenu.Add_Click({ if($Sidebar.Visible){$Sidebar.Visible=$false}else{$Sidebar.Visible=$true} }); $TopBar.Controls.Add($BtnMenu)

$BtnTheme = New-Object System.Windows.Forms.Label; $BtnTheme.Text="◑"; $BtnTheme.Font=New-Object System.Drawing.Font("Segoe UI",16); $BtnTheme.AutoSize=$true; $BtnTheme.Location=New-Object System.Drawing.Point(60,10); $BtnTheme.Cursor="Hand"; $BtnTheme.ForeColor=[System.Drawing.Color]::Gray
$BtnTheme.Add_Click({ 
    $Global:DarkMode = -not $Global:DarkMode
    Apply-Theme 
}); $TopBar.Controls.Add($BtnTheme)

$BtnClose = New-Object System.Windows.Forms.Label; $BtnClose.Text="✕"; $BtnClose.Dock="Right"; $BtnClose.Width=50; $BtnClose.TextAlign="MiddleCenter"; $BtnClose.Font=New-Object System.Drawing.Font("Segoe UI",12); $BtnClose.ForeColor=[System.Drawing.Color]::Red; $BtnClose.Cursor="Hand"
$BtnClose.Add_Click({$Form.Close()}); $TopBar.Controls.Add($BtnClose)

# Status Bar
$Global:LblStatus = New-Object System.Windows.Forms.Label; $Global:LblStatus.Dock="Bottom"; $Global:LblStatus.Height=30; $Global:LblStatus.TextAlign="MiddleLeft"; $Global:LblStatus.Padding=New-Object System.Windows.Forms.Padding(10,0,0,0)
$Content.Controls.Add($Global:LblStatus)

# --- 7. PANELS ---
$Global:Panels = @()
function Make-Panel ($Tag) {
    $P = New-Object System.Windows.Forms.Panel; $P.Dock="Fill"; $P.Visible=$false; $P.AutoScroll=$true; $P.Padding=New-Object System.Windows.Forms.Padding(20,0,0,50)
    $Content.Controls.Add($P); $P.BringToFront(); $Global:Panels+=$P; return $P
}

# --- P1: DASHBOARD ---
$P_Dash = Make-Panel "Dash"
Add-Title $P_Dash "THÔNG SỐ THỜI GIAN THỰC" 30
$Gauge = New-Object System.Windows.Forms.PictureBox; $Gauge.Size=New-Object System.Drawing.Size(800,160); $Gauge.Location=New-Object System.Drawing.Point(30,70); $P_Dash.Controls.Add($Gauge)
$TxtInfo = New-Object System.Windows.Forms.TextBox; $TxtInfo.Multiline=$true; $TxtInfo.Size=New-Object System.Drawing.Size(800,300); $TxtInfo.Location=New-Object System.Drawing.Point(30,250); $TxtInfo.BorderStyle="None"; $TxtInfo.Font=New-Object System.Drawing.Font("Consolas",10)
$Global:ControlsToUpdate += $TxtInfo; $P_Dash.Controls.Add($TxtInfo)

# --- P2: HỆ THỐNG (Workgroup, Name, Time) ---
$P_Sys = Make-Panel "System"
Add-Title $P_Sys "ĐỊNH DANH & MẠNG (WORKGROUP)" 30
Add-CardBtn $P_Sys "Đổi Tên Máy Tính (Rename PC)" "RenPC" 30 70
Add-CardBtn $P_Sys "Gia Nhập Workgroup" "JoinWG" 280 70
Add-CardBtn $P_Sys "Đổi Tên Workgroup" "RenWG" 530 70 $true

Add-Title $P_Sys "NGÀY GIỜ & VÙNG" 130
# Time controls manual placement due to complexity
$CbTZ = New-Object System.Windows.Forms.ComboBox; $CbTZ.Location=New-Object System.Drawing.Point(30,170); $CbTZ.Size=New-Object System.Drawing.Size(300,25); $CbTZ.DropDownStyle="DropDownList"
if($Global:JsonData.timezones){foreach($t in $Global:JsonData.timezones){$CbTZ.Items.Add("$($t.name) [$($t.id)]")}}
$P_Sys.Controls.Add($CbTZ)
Add-CardBtn $P_Sys "Lưu Múi Giờ" "SetTZ" 340 160

Add-Title $P_Sys "BẢO MẬT HỆ THỐNG" 220
Add-CardBtn $P_Sys "Tắt UAC (Im lặng)" "OffUAC" 30 260
Add-CardBtn $P_Sys "Bật UAC (Mặc định)" "OnUAC" 280 260
Add-CardBtn $P_Sys "Tắt SmartScreen" "OffSmart" 530 260

# --- P3: NGƯỜI DÙNG (User Management) ---
$P_User = Make-Panel "User"
Add-Title $P_User "QUẢN LÝ TÀI KHOẢN (LOCAL)" 30
$CbUsers = New-Object System.Windows.Forms.ComboBox; $CbUsers.Location=New-Object System.Drawing.Point(30,70); $CbUsers.Size=New-Object System.Drawing.Size(230,25); $CbUsers.DropDownStyle="DropDownList"
$P_User.Controls.Add($CbUsers)
# Load Users
Get-LocalUser | Where Enabled -eq $true | ForEach { $CbUsers.Items.Add($_.Name) }
if($CbUsers.Items.Count -gt 0){ $CbUsers.SelectedIndex=0 }

Add-CardBtn $P_User "Đặt Mật Khẩu Mới" "SetPass" 280 60
Add-CardBtn $P_User "Xóa Mật Khẩu (Trống)" "ClearPass" 530 60

Add-Title $P_User "PHÂN QUYỀN NHÓM (GROUP)" 120
Add-CardBtn $P_User "Thêm vào nhóm Admin" "AddAdmin" 30 160
Add-CardBtn $P_User "Xóa khỏi nhóm Admin" "DelAdmin" 280 160
Add-CardBtn $P_User "Thêm vào Remote Desktop" "AddRDP" 530 160

Add-Title $P_User "TẠO & XÓA USER" 220
Add-CardBtn $P_User "Tạo User Mới" "NewUser" 30 260
Add-CardBtn $P_User "Xóa User Đang Chọn" "DelUser" 280 260

# --- P4: TỐI ƯU ---
$P_Opt = Make-Panel "Opt"
Add-Title $P_Opt "TĂNG TỐC & DỌN DẸP" 30
Add-CardBtn $P_Opt "Dọn Rác Sâu (Deep Clean)" "CleanDeep" 30 70
Add-CardBtn $P_Opt "Xóa Cache Update" "CleanUpd" 280 70
Add-CardBtn $P_Opt "Bật Ultimate Performance" "UltPerf" 530 70
Add-Title $P_Opt "GỠ BỎ (BLOATWARE)" 130
Add-CardBtn $P_Opt "Gỡ Cortana" "DelCortana" 30 170
Add-CardBtn $P_Opt "Gỡ Xbox Apps" "DelXbox" 280 170

# --- P5: MẠNG ---
$P_Net = Make-Panel "Net"
Add-Title $P_Net "CÔNG CỤ MẠNG" 30
Add-CardBtn $P_Net "Ping Google Check" "PingTest" 30 70
Add-CardBtn $P_Net "Reset Mạng (TCP/IP)" "NetReset" 280 70
Add-CardBtn $P_Net "Xuất Pass Wifi ra Desktop" "DumpWifi" 530 70

# --- NAVIGATION ---
Add-NavBtn "Tổng Quan" "📊" 100 $P_Dash
Add-NavBtn "Hệ Thống" "⚙️" 160 $P_Sys
Add-NavBtn "Người Dùng" "👤" 220 $P_User
Add-NavBtn "Tối Ưu Hóa" "🚀" 280 $P_Opt
Add-NavBtn "Mạng & Net" "🌐" 340 $P_Net

# --- LOGIC & COMMANDS ---
$script:ActivePanel = $null
function Switch-Panel ($Btn) {
    $Global:Panels | ForEach { $_.Visible = $false }
    $Btn.Tag2.Visible = $true
    $script:ActivePanel = $Btn.Tag2
    Apply-Theme # Refresh colors logic
    $Btn.ForeColor = Color-FromHex (Get-Theme).Accent # Highlight active
}

function Run-Command ($Cmd, $Desc) {
    $Global:LblStatus.Text = "Đang chạy: $Desc..."
    $Form.Refresh()
    
    switch ($Cmd) {
        # SYSTEM
        "RenPC" { $n=Show-Input "Đổi Tên" "Nhập tên máy mới:"; if($n){Rename-Computer $n -ErrorAction SilentlyContinue; $Global:LblStatus.Text="Đã đổi tên. Cần Restart."} }
        "JoinWG" { $w=Show-Input "Workgroup" "Nhập tên Workgroup:"; if($w){Add-Computer -WorkgroupName $w -ErrorAction SilentlyContinue; $Global:LblStatus.Text="Đã gia nhập WG. Cần Restart."} }
        "RenWG" { $w=Show-Input "Workgroup" "Tên Workgroup mới:"; if($w){Add-Computer -WorkgroupName $w -ErrorAction SilentlyContinue; $Global:LblStatus.Text="Đã đổi WG. Cần Restart."} }
        "SetTZ" { if($CbTZ.SelectedItem){ $id=$CbTZ.SelectedItem.ToString().Split("[")[-1].Trim("]"); Set-TimeZone -Id $id; $Global:LblStatus.Text="Đã lưu múi giờ." } }
        "OffUAC" { Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0; $Global:LblStatus.Text="UAC Tắt (Restart)." }
        "OnUAC"  { Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1; $Global:LblStatus.Text="UAC Bật." }

        # USER
        "SetPass" { 
            $u=$CbUsers.SelectedItem; $p=Show-Input "Mật khẩu" "Nhập mật khẩu mới cho $u:"
            if($u -and $p){ Set-LocalUser -Name $u -Password ($p | ConvertTo-SecureString -AsPlainText -Force); $Global:LblStatus.Text="Đã đổi pass cho $u." }
        }
        "ClearPass" { $u=$CbUsers.SelectedItem; if($u){ Set-LocalUser -Name $u -Password ([string]::Empty | ConvertTo-SecureString -AsPlainText -Force); $Global:LblStatus.Text="Đã xóa pass $u." } }
        "AddAdmin" { $u=$CbUsers.SelectedItem; if($u){ Add-LocalGroupMember -Group "Administrators" -Member $u; $Global:LblStatus.Text="$u đã là Admin." } }
        "DelAdmin" { $u=$CbUsers.SelectedItem; if($u){ Remove-LocalGroupMember -Group "Administrators" -Member $u; $Global:LblStatus.Text="$u không còn là Admin." } }
        "NewUser"  { 
            $n=Show-Input "Tạo User" "Tên User mới:"; $p=Show-Input "Mật khẩu" "Mật khẩu:"
            if($n){ New-LocalUser -Name $n -Password ($p | ConvertTo-SecureString -AsPlainText -Force) -FullName $n; $Global:LblStatus.Text="Đã tạo user $n." }
        }
        "DelUser" { $u=$CbUsers.SelectedItem; if($u){ Remove-LocalUser -Name $u; $Global:LblStatus.Text="Đã xóa user $u." } }

        # OPTIMIZE
        "CleanDeep" { Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue; $Global:LblStatus.Text="Đã dọn dẹp." }
        "UltPerf" { powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61; $Global:LblStatus.Text="Đã kích hoạt Ultimate Perf." }
        
        # NET
        "PingTest" { Start-Process "cmd" "/k ping 8.8.8.8" }
        "DumpWifi" { $f="$env:USERPROFILE\Desktop\Wifi.txt"; "--- WIFI ---"|Out-File $f; (netsh wlan show profiles)|Select-String "\:(.+)$"|%{$n=$_.Matches.Groups[1].Value.Trim();$p=(netsh wlan show profile name="$n" key=clear);"$n : $p"|Out-File $f -Append}; $Global:LblStatus.Text="Đã xuất file Wifi." }
    }
}

# --- REAL-TIME MONITOR & INITIALIZE ---
$Timer = New-Object System.Windows.Forms.Timer; $Timer.Interval = 1000
$Timer.Add_Tick({
    $Gauge.Invalidate() # Repaint Gauge
    # Only update text once to save CPU, or update values if needed
    if ($TxtInfo.Text.Length -lt 10) {
       $OS = Get-CimInstance Win32_OperatingSystem
       $TxtInfo.Text = "HỆ THỐNG: $($OS.Caption)`r`nUSER: $env:USERNAME`r`nCPU: $((Get-CimInstance Win32_Processor).Name)"
    }
})
$Gauge.Add_Paint({ param($s, $e)
    $g=$e.Graphics; $g.SmoothingMode="AntiAlias"; $T=Get-Theme
    $cpu = (Get-CimInstance Win32_Processor).LoadPercentage
    
    # Draw simple bars for RGB effect
    $b1 = New-Object System.Drawing.SolidBrush (Color-FromHex $T.Accent)
    $b2 = New-Object System.Drawing.SolidBrush (Color-FromHex $T.Accent2)
    $g.FillRectangle($b1, 50, 50, [int]($cpu*2), 30)
    $g.DrawString("CPU: $cpu%", (New-Object System.Drawing.Font("Segoe UI",12)), $b1, 50, 20)
})
$Timer.Start()

# Apply Default Theme & Start
Apply-Theme
Switch-Panel ($Sidebar.Controls | Where Tag2 -eq $P_Dash | Select -First 1)
$Form.ShowDialog() | Out-Null
