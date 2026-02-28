# ==============================================================================
# Phát Tấn PC - Advanced Printer & Network Tool V2 (PowerShell WinForms)
# Tối ưu cho WinPE, Win Lite, Windows Full
# ==============================================================================

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- SETUP GIAO DIỆN CHÍNH ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Phát Tấn PC - Fix Printer & Network Tool V2"
$form.Size = New-Object System.Drawing.Size(1200, 700)
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1E")
$form.ForeColor = [System.Drawing.Color]::White
$form.StartPosition = "CenterScreen"
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

$layout = New-Object System.Windows.Forms.TableLayoutPanel
$layout.Dock = "Fill"
$layout.ColumnCount = 4
$layout.RowCount = 1
$layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 22)))
$layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 22)))
$layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 22)))
$layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 34)))
$form.Controls.Add($layout)

function New-ColumnPanel ($Title, $ColorHex) {
    $panel = New-Object System.Windows.Forms.FlowLayoutPanel
    $panel.Dock = "Fill"
    $panel.FlowDirection = "TopDown"
    $panel.WrapContents = $false
    $panel.AutoScroll = $true
    $panel.Padding = New-Object System.Windows.Forms.Padding(10)

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $Title
    $lbl.AutoSize = $true
    $lbl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($ColorHex)
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $lbl.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 15)
    $panel.Controls.Add($lbl)

    return $panel
}

function New-StyledButton ($Text, $OnClick, $BgColor = "#333337") {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $Text
    $btn.Size = New-Object System.Drawing.Size(220, 35)
    $btn.FlatStyle = "Flat"
    $btn.BackColor = [System.Drawing.ColorTranslator]::FromHtml($BgColor)
    $btn.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#555555")
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btn.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 8)
    $btn.Add_Click($OnClick)
    return $btn
}

# --- CỘT 4: KHUNG LOG ---
$logPanel = New-Object System.Windows.Forms.Panel
$logPanel.Dock = "Fill"
$logPanel.Padding = New-Object System.Windows.Forms.Padding(10)

$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Text = "📋 NHẬT KÝ HỆ THỐNG"
$lblLog.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFB900")
$lblLog.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$lblLog.Dock = "Top"

$txtLog = New-Object System.Windows.Forms.RichTextBox
$txtLog.Dock = "Fill"
$txtLog.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2D2D30")
$txtLog.ForeColor = [System.Drawing.Color]::LimeGreen
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 10)
$txtLog.ReadOnly = $true

$btnClearLog = New-Object System.Windows.Forms.Button
$btnClearLog.Text = "Clear Log"
$btnClearLog.Dock = "Bottom"
$btnClearLog.Height = 30
$btnClearLog.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#FF4D4D")
$btnClearLog.FlatStyle = "Flat"
$btnClearLog.FlatAppearance.BorderSize = 0
$btnClearLog.Add_Click({ $txtLog.Clear(); Write-Log "Đã dọn dẹp nhật ký." })

$logPanel.Controls.Add($txtLog)
$logPanel.Controls.Add($lblLog)
$logPanel.Controls.Add($btnClearLog)
$layout.Controls.Add($logPanel, 3, 0)

function Write-Log ($Message, $Color = "LimeGreen") {
    $time = (Get-Date).ToString("HH:mm:ss")
    $txtLog.SelectionStart = $txtLog.TextLength
    $txtLog.SelectionLength = 0
    $txtLog.SelectionColor = [System.Drawing.Color]::$Color
    $txtLog.AppendText("[$time] $Message`n")
    $txtLog.ScrollToCaret()
    Write-Host "[$time] $Message"
}

# ==============================================================================
# LOGIC XỬ LÝ FIX LỖI SÂU (REGISTRY & DỊCH VỤ)
# ==============================================================================

function Set-RegSafe ($Path, $Name, $Value, $Type = "DWord") {
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
        Write-Log "  -> Set [$Name] = $Value thành công." "White"
    } catch {
        Write-Log "  -> LỖI khi set [$Name]. Đang thử qua cmd/reg.exe..." "Yellow"
        $cmdType = if ($Type -eq "DWord") { "REG_DWORD" } else { "REG_SZ" }
        cmd.exe /c "reg add `"$Path`" /v $Name /t $cmdType /d $Value /f" | Out-Null
        Write-Log "  -> Đã chạy Fallback cmd reg.exe." "Cyan"
    }
}

$Action_CleanSpooler = {
    Write-Log "Đang khởi động lại Print Spooler..." "White"
    try {
        cmd.exe /c "net stop spooler /y" | Out-Null
        cmd.exe /c "del /Q /F /S %systemroot%\System32\Spool\Printers\*.*" | Out-Null
        cmd.exe /c "net start spooler" | Out-Null
        Write-Log "Hoàn tất Dọn dẹp & Restart Spooler." "LimeGreen"
    } catch { Write-Log "Lỗi Restart Spooler." "Red" }
}

$Action_Fix11B_709 = {
    Write-Log "Đang Fix lỗi 0x0000011B / 0x00000709 / 0x0000007c..." "White"
    $PrintReg = "HKLM:\System\CurrentControlSet\Control\Print"
    Set-RegSafe $PrintReg "RpcAuthnLevelPrivacyEnabled" 0
    Set-RegSafe $PrintReg "RpcConnectionUpdates" 0
    & $Action_CleanSpooler
}

$Action_FixPolicy = {
    Write-Log "Đang Fix lỗi 'A Policy Is In Effect' (Point and Print)..." "White"
    $PnPReg = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
    Set-RegSafe $PnPReg "RestrictDriverInstallationToAdministrators" 0
    Set-RegSafe $PnPReg "InForest" 0
    Set-RegSafe $PnPReg "Restricted" 0
    Set-RegSafe $PnPReg "TrustedServers" 0
    & $Action_CleanSpooler
}

$Action_FixPassLAN = {
    Write-Log "Đang Fix lỗi đòi Password khi vào LAN..." "White"
    $LanManReg = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
    Set-RegSafe $LanManReg "AllowInsecureGuestAuth" 1
    cmd.exe /c "netsh advfirewall firewall set rule group=`"File and Printer Sharing`" new enable=Yes" | Out-Null
    Write-Log "Đã cho phép Guest Auth và bật Share Firewall." "LimeGreen"
}

$Action_EnableSMB1 = {
    Write-Log "Đang bật SMBv1 cho máy in/scan cổ..." "White"
    try {
        Enable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -All -NoRestart -ErrorAction Stop
        Write-Log "Bật SMBv1 bằng PS thành công." "LimeGreen"
    } catch {
        Write-Log "Thiếu module, dùng Fallback DISM/Registry..." "Yellow"
        cmd.exe /c "dism /online /enable-feature /featurename:SMB1Protocol /all /norestart" | Out-Null
        Set-RegSafe "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" "SMB1" 1
        Write-Log "Đã ép bật SMB1 bằng DISM/Reg. Yêu cầu khởi động lại máy!" "Cyan"
    }
}

$Action_ClearCreds = {
    Write-Log "Đang xóa Cache Mật khẩu LAN (Xóa kẹt Session)..." "White"
    cmd.exe /c "cmdkey /list | findstr Target > %temp%\creds.txt" | Out-Null
    $creds = Get-Content "$env:temp\creds.txt" -ErrorAction SilentlyContinue
    if ($creds) {
        foreach ($cred in $creds) {
            $target = ($cred -split "Target: ")[1]
            cmd.exe /c "cmdkey /delete:$target" | Out-Null
            Write-Log "Đã xóa: $target" "Cyan"
        }
    } else {
        Write-Log "Không tìm thấy session nào bị kẹt." "LimeGreen"
    }
}

# --- RÁP CÁC CỘT LẠI VỚI NHAU (ĐÃ FIX LỖI DẤU PHẨY ARRAY) ---

# CỘT 1: FIX MÁY IN
$col1 = New-ColumnPanel "🖨️ FIX MÁY IN MẠNG LAN" "#4DA6FF"
$col1.Controls.Add((New-StyledButton "1. Fix Spooler Services" $Action_CleanSpooler "#FF3399"))
$col1.Controls.Add((New-StyledButton "2. Fix 0x0000011B & 0709" $Action_Fix11B_709 "#8A2BE2"))
$col1.Controls.Add((New-StyledButton "3. Fix A Policy Is In Effects" $Action_FixPolicy "#2E8B57"))
$col1.Controls.Add((New-StyledButton "4. Fix 0x00000bc4 & 4005" $Action_Fix11B_709 "#B22222"))
$col1.Controls.Add((New-StyledButton "5. Xóa hàng đợi in Hardcore" { Write-Log "Đang xóa thư mục PRINTERS..." "White"; cmd.exe /c "del /Q /F /S %systemroot%\System32\Spool\Printers\*.*"; Write-Log "Xong." } "#008080"))
$layout.Controls.Add($col1, 0, 0)

# CỘT 2: FIX MẠNG & CHIA SẺ
$col2 = New-ColumnPanel "🌐 FIX CHIA SẺ DỮ LIỆU" "#00FA9A"
$col2.Controls.Add((New-StyledButton "1. Auto Share D, E, F..." { Write-Log "Chức năng Share đang dev" "Yellow" } "#20B2AA"))
$col2.Controls.Add((New-StyledButton "2. Bật SMBv1 (Máy/Scan cũ)" $Action_EnableSMB1 "#9370DB"))
$col2.Controls.Add((New-StyledButton "3. Fix Lỗi Đòi Pass LAN" $Action_FixPassLAN "#D2691E"))
$col2.Controls.Add((New-StyledButton "4. Xóa kẹt Session Mạng" $Action_ClearCreds "#3CB371"))
$col2.Controls.Add((New-StyledButton "5. Deep Reset Network" { Write-Log "Đang reset IP/DNS/Winsock..."; cmd.exe /c "ipconfig /release & ipconfig /flushdns & ipconfig /renew & netsh winsock reset"; Write-Log "Reset mạng thành công. Vui lòng Restart máy." } "#4682B4"))
$layout.Controls.Add($col2, 1, 0)

# CỘT 3: TIỆN ÍCH HỆ THỐNG
$col3 = New-ColumnPanel "🛠️ TIỆN ÍCH MỞ RỘNG" "#FF69B4"
$col3.Controls.Add((New-StyledButton "1. Kiểm tra IP/Ping Mạng" { Write-Log "Đang Ping Google..."; cmd.exe /c "ping 8.8.8.8 -n 4" | Out-Host; Write-Log "Check cmd để xem kết quả" } "#CD5C5C"))
$col3.Controls.Add((New-StyledButton "2. Clean Mực (Máy in màu)" { Write-Log "Tính năng này phụ thuộc driver từng hãng, đang dev..." "Yellow" } "#C71585"))
$col3.Controls.Add((New-StyledButton "3. Kiểm tra mã máy in (WMI)" { $print = Get-CimInstance Win32_Printer -ErrorAction SilentlyContinue; Write-Log ($print.Name | Out-String) } "#4B0082"))
$col3.Controls.Add((New-StyledButton "4. Bật Share_Set Mặc Định" { Write-Log "Chức năng đang dev" "Yellow" } "#FF8C00"))
$layout.Controls.Add($col3, 2, 0)

# Khởi chạy ban đầu
$form.Add_Shown({
    if (-not $isAdmin) {
        Write-Log "CẢNH BÁO: Script chưa được chạy bằng quyền Administrator! Việc can thiệp Registry sẽ bị Access Denied." "Red"
    } else {
        Write-Log "Khởi động thành công. Quyền Administrator: HỢP LỆ." "LimeGreen"
    }
})

$form.ShowDialog() | Out-Null
