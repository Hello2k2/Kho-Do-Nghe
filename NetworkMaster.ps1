# --- 1. QUYỀN ADMIN & TIẾNG VIỆT ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- KHỞI TẠO GIAO DIỆN ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "QUẢN LÝ MẠNG V2.4 - PHÁT TẤN PC (PRIVACY)"
$Form.Size = New-Object System.Drawing.Size(720, 650)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 35)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# --- HÀM HỖ TRỢ UI ---
function New-Label ($Parent, $Txt, $X, $Y, $FontSz, $Color) {
    $L = New-Object System.Windows.Forms.Label; $L.Text=$Txt; $L.Location="$X,$Y"; $L.AutoSize=$true
    $L.Font = New-Object System.Drawing.Font("Segoe UI", $FontSz)
    $L.ForeColor = $Color
    $Parent.Controls.Add($L)
    return $L
}

function New-Box ($Parent, $Txt, $X, $Y, $W) {
    $L = New-Object System.Windows.Forms.Label; $L.Text=$Txt; $L.Location="$X,$Y"; $L.AutoSize=$true; $L.ForeColor="LightGray"; $Parent.Controls.Add($L)
    $T = New-Object System.Windows.Forms.TextBox; $T.Location="$X,$($Y+20)"; $T.Width=$W; $T.BackColor="DimGray"; $T.ForeColor="White"; $T.BorderStyle="FixedSingle"; $Parent.Controls.Add($T)
    return $T
}

function Log ($M) { 
    $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $M`r`n")
    $TxtLog.ScrollToCaret() 
}

# --- HEADER ---
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "NETWORK MASTER V2.4"; $LblT.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold); $LblT.AutoSize=$true; $LblT.Location="20,10"; $LblT.ForeColor="Cyan"; $Form.Controls.Add($LblT)

$LblNic = New-Object System.Windows.Forms.Label; $LblNic.Text = "Chọn Card Mạng (Interface):"; $LblNic.Location="20,50"; $LblNic.AutoSize=$true; $Form.Controls.Add($LblNic)
$CbNic = New-Object System.Windows.Forms.ComboBox; $CbNic.Location="20,70"; $CbNic.Width=660; $CbNic.DropDownStyle="DropDownList"; $CbNic.BackColor="Black"; $CbNic.ForeColor="Gold"; $Form.Controls.Add($CbNic)

# --- TAB CONTROL ---
$TabControl = New-Object System.Windows.Forms.TabControl; $TabControl.Location="20,110"; $TabControl.Size="660,350"; $Form.Controls.Add($TabControl)

# === TAB 0: DASHBOARD (TỔNG QUAN) ===
$TabDash = New-Object System.Windows.Forms.TabPage; $TabDash.Text = "  TỔNG QUAN (INFO)  "; $TabDash.BackColor = [System.Drawing.Color]::FromArgb(35,35,40)
$TabControl.Controls.Add($TabDash)

# Dashboard UI Elements
New-Label $TabDash "THÔNG TIN MẠNG HIỆN TẠI" 20 20 12 "Gold"

# Status & Speed
$LblStatusTitle = New-Label $TabDash "Trạng Thái:" 20 60 10 "Silver"
$LblStatusVal = New-Label $TabDash "Đang tải..." 120 60 10 "Lime"
$LblSpeedTitle = New-Label $TabDash "Tốc Độ Link:" 350 60 10 "Silver"
$LblSpeedVal = New-Label $TabDash "..." 450 60 10 "Cyan"

# --- IP LAN (Bên Trái) ---
New-Label $TabDash "IP LAN (NỘI BỘ):" 20 100 10 "Silver"
$LblBigIP = New-Label $TabDash "0.0.0.0" 20 125 24 "Cyan" # Big Font

# --- IP WAN (Bên Phải - CÓ CHE) ---
New-Label $TabDash "IP PUBLIC (WAN):" 350 100 10 "Silver"
$LblPubIP = New-Label $TabDash "***.***.***.***" 350 125 24 "Orange" # Mặc định che

# Nút Hiện/Ẩn IP WAN
$BtnEye = New-Object System.Windows.Forms.Button; $BtnEye.Text="👁️ HIỆN"; $BtnEye.Location="600,128"; $BtnEye.Size="50,30"; $BtnEye.BackColor="DimGray"; $BtnEye.ForeColor="White"; $BtnEye.FlatStyle="Flat"
$TabDash.Controls.Add($BtnEye)

# Details Grid
$GrpDet = New-Object System.Windows.Forms.GroupBox; $GrpDet.Text="Chi Tiết Kỹ Thuật"; $GrpDet.Location="20,190"; $GrpDet.Size="600,110"; $GrpDet.ForeColor="White"; $TabDash.Controls.Add($GrpDet)

New-Label $GrpDet "Subnet Mask:" 20 30 9 "Silver"
$LblMaskVal = New-Label $GrpDet "..." 120 30 9 "White"

New-Label $GrpDet "Gateway:" 20 60 9 "Silver"
$LblGateVal = New-Label $GrpDet "..." 120 60 9 "White"

New-Label $GrpDet "DNS Server:" 300 30 9 "Silver"
$LblDNSVal = New-Label $GrpDet "..." 380 30 9 "Yellow"

New-Label $GrpDet "MAC Address:" 300 60 9 "Silver"
$LblMACVal = New-Label $GrpDet "..." 380 60 9 "White"

$BtnRefreshDash = New-Object System.Windows.Forms.Button; $BtnRefreshDash.Text="LÀM MỚI"; $BtnRefreshDash.Location="520,20"; $BtnRefreshDash.Size="80,30"; $BtnRefreshDash.BackColor="DimGray"; $BtnRefreshDash.ForeColor="White"; $TabDash.Controls.Add($BtnRefreshDash)


# === TAB 1: CẤU HÌNH IP ===
$TabIP = New-Object System.Windows.Forms.TabPage; $TabIP.Text = "  Cấu Hình IP & DNS  "; $TabIP.BackColor = [System.Drawing.Color]::FromArgb(45,45,50)
$TabControl.Controls.Add($TabIP)

$TxtIP = New-Box $TabIP "Địa chỉ IP (IPv4):" 20 20 200
$TxtSub = New-Box $TabIP "Mặt Nạ Mạng (Subnet Mask):" 240 20 200
$TxtGate = New-Box $TabIP "Cổng Mặc Định (Gateway):" 20 80 200
$TxtDNS1 = New-Box $TabIP "DNS Chính (Ưu tiên):" 240 80 150
$TxtDNS2 = New-Box $TabIP "DNS Phụ (Dự phòng):" 410 80 150
$TxtIP.Text="192.168.1.150"; $TxtSub.Text="255.255.255.0"; $TxtGate.Text="192.168.1.1"; $TxtDNS1.Text="8.8.8.8"; $TxtDNS2.Text="8.8.4.4"

$BtnSetStatic = New-Object System.Windows.Forms.Button; $BtnSetStatic.Text="ÁP DỤNG IP TĨNH"; $BtnSetStatic.Location="20,150"; $BtnSetStatic.Size="180,40"; $BtnSetStatic.BackColor="DarkBlue"; $BtnSetStatic.ForeColor="White"; $TabIP.Controls.Add($BtnSetStatic)
$BtnDHCP = New-Object System.Windows.Forms.Button; $BtnDHCP.Text="CHUYỂN VỀ IP ĐỘNG (AUTO)"; $BtnDHCP.Location="220,150"; $BtnDHCP.Size="200,40"; $BtnDHCP.BackColor="ForestGreen"; $BtnDHCP.ForeColor="White"; $TabIP.Controls.Add($BtnDHCP)

# === TAB 2: ĐỔI MAC ===
$TabMAC = New-Object System.Windows.Forms.TabPage; $TabMAC.Text = "  Đổi Địa Chỉ MAC  "; $TabMAC.BackColor = [System.Drawing.Color]::FromArgb(45,45,50)
$TabControl.Controls.Add($TabMAC)

$LblCurMac = New-Object System.Windows.Forms.Label; $LblCurMac.Text="MAC Hiện Tại:"; $LblCurMac.Location="20,30"; $LblCurMac.AutoSize=$true; $TabMAC.Controls.Add($LblCurMac)
$TxtCurMac = New-Object System.Windows.Forms.TextBox; $TxtCurMac.Location="120,27"; $TxtCurMac.ReadOnly=$true; $TabMAC.Controls.Add($TxtCurMac)

$TxtNewMac = New-Box $TabMAC "MAC Mới (VD: 001122334455 - Viết liền không dấu):" 20 70 300
$BtnGenMac = New-Object System.Windows.Forms.Button; $BtnGenMac.Text="Ngẫu Nhiên"; $BtnGenMac.Location="330,88"; $BtnGenMac.Size="100,23"; $BtnGenMac.BackColor="DimGray"; $TabMAC.Controls.Add($BtnGenMac)

$BtnApplyMac = New-Object System.Windows.Forms.Button; $BtnApplyMac.Text="ĐỔI MAC NGAY"; $BtnApplyMac.Location="20,150"; $BtnApplyMac.Size="180,40"; $BtnApplyMac.BackColor="Maroon"; $BtnApplyMac.ForeColor="White"; $TabMAC.Controls.Add($BtnApplyMac)
$BtnResetMac = New-Object System.Windows.Forms.Button; $BtnResetMac.Text="KHÔI PHỤC GỐC"; $BtnResetMac.Location="220,150"; $BtnResetMac.Size="180,40"; $BtnResetMac.BackColor="DimGray"; $BtnResetMac.ForeColor="White"; $TabMAC.Controls.Add($BtnResetMac)
$LblWarn = New-Object System.Windows.Forms.Label; $LblWarn.Text="*Lưu ý: Mạng sẽ bị ngắt 3-5 giây để nhận diện MAC mới."; $LblWarn.Location="20,220"; $LblWarn.AutoSize=$true; $LblWarn.ForeColor="Orange"; $TabMAC.Controls.Add($LblWarn)

# === TAB 3: TIỆN ÍCH ===
$TabUtil = New-Object System.Windows.Forms.TabPage; $TabUtil.Text = "  Tiện Ích Mở Rộng  "; $TabUtil.BackColor = [System.Drawing.Color]::FromArgb(45,45,50)
$TabControl.Controls.Add($TabUtil)

$BtnResetNet = New-Object System.Windows.Forms.Button; $BtnResetNet.Text="RESET TOÀN BỘ MẠNG (FIX LỖI)"; $BtnResetNet.Location="20,30"; $BtnResetNet.Size="250,40"; $BtnResetNet.BackColor="Firebrick"; $BtnResetNet.ForeColor="White"; $TabUtil.Controls.Add($BtnResetNet)
$BtnPing = New-Object System.Windows.Forms.Button; $BtnPing.Text="KIỂM TRA PING (GOOGLE/VNPT)"; $BtnPing.Location="290,30"; $BtnPing.Size="250,40"; $BtnPing.BackColor="Teal"; $BtnPing.ForeColor="White"; $TabUtil.Controls.Add($BtnPing)
$BtnFlush = New-Object System.Windows.Forms.Button; $BtnFlush.Text="XÓA BỘ NHỚ ĐỆM DNS (FLUSH)"; $BtnFlush.Location="20,90"; $BtnFlush.Size="250,40"; $BtnFlush.BackColor="OliveDrab"; $BtnFlush.ForeColor="White"; $TabUtil.Controls.Add($BtnFlush)

# --- KHUNG NHẬT KÝ (LOG) ---
$LblLog = New-Object System.Windows.Forms.Label; $LblLog.Text="Nhật Ký Hoạt Động:"; $LblLog.Location="20,465"; $LblLog.AutoSize=$true; $LblLog.ForeColor="Silver"; $Form.Controls.Add($LblLog)
$TxtLog = New-Object System.Windows.Forms.TextBox; $TxtLog.Multiline = $true; $TxtLog.Location = "20, 490"; $TxtLog.Size = "660, 100"
$TxtLog.BackColor = "Black"; $TxtLog.ForeColor = "Lime"; $TxtLog.Font = "Consolas, 9"; $TxtLog.ReadOnly = $true; $TxtLog.ScrollBars="Vertical"
$Form.Controls.Add($TxtLog)

# --- LOGIC ---

function Load-Adapters {
    $CbNic.Items.Clear()
    $Adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -or $_.Status -eq "Disconnected" }
    foreach ($A in $Adapters) {
        $Status = if ($A.Status -eq "Up") { "Online" } else { "Offline" }
        $CbNic.Items.Add("$($A.InterfaceAlias) | $Status | $($A.InterfaceDescription)") | Out-Null
    }
    if ($CbNic.Items.Count -gt 0) { $CbNic.SelectedIndex = 0 }
}

function Get-SelectedAlias {
    if ($CbNic.SelectedItem) { return $CbNic.SelectedItem.Split('|')[0].Trim() }
    return $null
}

# === LOGIC DASHBOARD (IP WAN & FIX) ===
function Update-Dashboard {
    $Alias = Get-SelectedAlias
    if (!$Alias) { return }
    
    $Adp = Get-NetAdapter -Name $Alias
    # Status
    if ($Adp.Status -eq "Up") { 
        $LblStatusVal.Text = "Đang Kết Nối (Connected)"; $LblStatusVal.ForeColor = "Lime"
    } else { 
        $LblStatusVal.Text = "Ngắt Kết Nối (Disconnected)"; $LblStatusVal.ForeColor = "Red"
    }
    
    # Link Speed Safe Check
    if ($Adp.LinkSpeed) { $LblSpeedVal.Text = $Adp.LinkSpeed } else { $LblSpeedVal.Text = "..." }
    
    $LblMACVal.Text = $Adp.MacAddress

    # IP LAN Info
    try {
        $NetConf = Get-NetIPConfiguration -InterfaceAlias $Alias -ErrorAction SilentlyContinue
        if ($NetConf) {
            $IPv4 = $NetConf.IPv4Address.IPAddress
            $LblBigIP.Text = if ($IPv4) { $IPv4 } else { "0.0.0.0" }
            
            $Prfx = (Get-NetIPAddress -InterfaceAlias $Alias -AddressFamily IPv4).PrefixLength
            $LblMaskVal.Text = "Prefix Length: /$Prfx"

            $Gate = $NetConf.IPv4DefaultGateway.NextHop
            $LblGateVal.Text = if ($Gate) { $Gate } else { "Chưa có" }

            $DNS = $NetConf.DNSServer.ServerAddresses
            $LblDNSVal.Text = if ($DNS) { $DNS -join ", " } else { "Tự động" }
        } else {
            $LblBigIP.Text = "Chưa nhận IP"
            $LblMaskVal.Text = "---"; $LblGateVal.Text = "---"; $LblDNSVal.Text = "---"
        }
    } catch { $LblBigIP.Text = "Lỗi đọc IP" }
}

# --- LOGIC HIỆN/ẨN IP WAN ---
$BtnEye.Add_Click({
    if ($LblPubIP.Text -match "\*") {
        $LblPubIP.Text = "Đang lấy..."
        $BtnEye.Enabled = $false
        # Dùng Job hoặc WebRequest có timeout để không treo Tool
        try {
            # Lấy IP từ api.ipify.org (nhanh, chỉ trả text)
            $Req = [System.Net.WebRequest]::Create("https://api.ipify.org")
            $Req.Timeout = 3000 # Timeout 3s
            $Resp = $Req.GetResponse()
            $Stream = New-Object System.IO.StreamReader($Resp.GetResponseStream())
            $IPWan = $Stream.ReadToEnd()
            
            $LblPubIP.Text = $IPWan
            $BtnEye.Text = "❌ ẨN"
            Log "Đã lấy IP Public: $IPWan"
        } catch {
            $LblPubIP.Text = "Lỗi Mạng"
            Log "Không lấy được IP Public (Kiểm tra internet)"
        }
        $BtnEye.Enabled = $true
    } else {
        $LblPubIP.Text = "***.***.***.***"
        $BtnEye.Text = "👁️ HIỆN"
    }
})

$BtnRefreshDash.Add_Click({ Update-Dashboard })

$CbNic.Add_SelectedIndexChanged({
    $Alias = Get-SelectedAlias
    if ($Alias) {
        Update-Dashboard
        $Mac = (Get-NetAdapter -Name $Alias).MacAddress
        $TxtCurMac.Text = $Mac
    }
})

# --- LOGIC CÁC TAB KHÁC ---
# 2. Xử Lý IP
$BtnSetStatic.Add_Click({
    $Alias = Get-SelectedAlias
    if (!$Alias) { Log "Vui lòng chọn Card mạng trước!"; return }
    $IP=$TxtIP.Text; $Sub=$TxtSub.Text; $GW=$TxtGate.Text; $D1=$TxtDNS1.Text; $D2=$TxtDNS2.Text

    try {
        Log "Đang thiết lập IP Tĩnh cho: $Alias..."
        New-NetIPAddress -InterfaceAlias $Alias -IPAddress $IP -PrefixLength 24 -DefaultGateway $GW -ErrorAction SilentlyContinue
        Set-NetIPAddress -InterfaceAlias $Alias -IPAddress $IP -PrefixLength 24 -DefaultGateway $GW -Confirm:$false
        Set-DnsClientServerAddress -InterfaceAlias $Alias -ServerAddresses @($D1, $D2) -Confirm:$false
        Log ">>> THÀNH CÔNG: IP $IP / Gateway $GW"
        [System.Windows.Forms.MessageBox]::Show("Đã thiết lập IP Tĩnh thành công!", "Thông Báo")
        Update-Dashboard
    } catch { Log "LỖI: $($_.Exception.Message)" }
})

$BtnDHCP.Add_Click({
    $Alias = Get-SelectedAlias
    if (!$Alias) { return }
    try {
        Log "Đang chuyển về chế độ IP Động (DHCP)..."
        Set-NetIPInterface -InterfaceAlias $Alias -Dhcp Enabled
        Set-DnsClientServerAddress -InterfaceAlias $Alias -ResetServerAddresses
        Log ">>> Đã Reset về Tự Động."
        [System.Windows.Forms.MessageBox]::Show("Đã chuyển về chế độ DHCP!", "Thông Báo")
        Update-Dashboard
    } catch { Log "Lỗi: $($_.Exception.Message)" }
})

# 3. Xử Lý MAC
function Get-RegKey ($InterfaceDesc) {
    $Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
    $Keys = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue
    foreach ($K in $Keys) {
        $Desc = (Get-ItemProperty -Path $K.PSPath -Name "DriverDesc" -ErrorAction SilentlyContinue).DriverDesc
        if ($Desc -eq $InterfaceDesc) { return $K.PSPath }
    }
    return $null
}

$BtnGenMac.Add_Click({ $R = "02" + -join ((1..5) | ForEach-Object { "{0:X2}" -f (Get-Random -Max 256) }); $TxtNewMac.Text = $R })

$BtnApplyMac.Add_Click({
    $Alias = Get-SelectedAlias
    if (!$Alias) { return }
    $NewMac = $TxtNewMac.Text.Trim().Replace(":","").Replace("-","")
    if ($NewMac.Length -ne 12) { Log "Lỗi: MAC phải đủ 12 ký tự"; return }
    $Desc = (Get-NetAdapter -Name $Alias).InterfaceDescription
    $RegPath = Get-RegKey $Desc
    if ($RegPath) {
        try {
            Log "Ghi đè Registry..."; Set-ItemProperty -Path $RegPath -Name "NetworkAddress" -Value $NewMac
            Log "Khởi động lại Card mạng..."; Disable-NetAdapter -Name $Alias -Confirm:$false; Start-Sleep 2; Enable-NetAdapter -Name $Alias -Confirm:$false
            Log ">>> ĐỔI MAC THÀNH CÔNG: $NewMac"
            $TxtCurMac.Text = (Get-NetAdapter -Name $Alias).MacAddress
            [System.Windows.Forms.MessageBox]::Show("Đổi MAC thành công!", "Thành Công")
            Update-Dashboard
        } catch { Log "Lỗi: $_" }
    }
})

$BtnResetMac.Add_Click({
    $Alias = Get-SelectedAlias; if (!$Alias) { return }
    $Desc = (Get-NetAdapter -Name $Alias).InterfaceDescription
    $RegPath = Get-RegKey $Desc
    if ($RegPath) {
        Log "Xóa MAC ảo..."; Remove-ItemProperty -Path $RegPath -Name "NetworkAddress" -ErrorAction SilentlyContinue
        Log "Khởi động lại Card..."; Disable-NetAdapter -Name $Alias -Confirm:$false; Start-Sleep 2; Enable-NetAdapter -Name $Alias -Confirm:$false
        Log ">>> Đã về MAC Gốc."; $TxtCurMac.Text = (Get-NetAdapter -Name $Alias).MacAddress
        Update-Dashboard
    }
})

# 4. Tiện Ích
$BtnResetNet.Add_Click({
    Log "Reset Winsock & TCP/IP..."; Start-Process cmd -ArgumentList "/c netsh winsock reset && netsh int ip reset" -Verb RunAs -Wait
    [System.Windows.Forms.MessageBox]::Show("Đã Reset mạng gốc. Hãy Reboot máy!", "Thông Báo")
})
$BtnFlush.Add_Click({ Start-Process cmd -ArgumentList "/c ipconfig /flushdns" -WindowStyle Hidden; Log "Đã xóa cache DNS." })
$BtnPing.Add_Click({
    Log "Đang Ping Google..."; $P1 = Test-Connection "8.8.8.8" -Count 1 -ErrorAction SilentlyContinue
    if ($P1) { Log "Google (8.8.8.8): $($P1.ResponseTime) ms (Ổn)" } else { Log "Google: Mất kết nối" }
})

# Chạy
Load-Adapters
$Form.Add_Load({ Load-Adapters; Update-Dashboard }) 
$Form.ShowDialog() | Out-Null
