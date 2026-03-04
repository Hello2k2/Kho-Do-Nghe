<#
    TOOL CUU HO MAY TINH - PHAT TAN PC
    Version: 20.13 TITANIUM MAX (Added GiftCode / Redeem Key System)
#>

if ($host.Name -match "ISE") { Exit }
if ($MyInvocation.MyCommand.Path) { Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show("Truy cập trái phép! Vui lòng dùng lệnh tải từ Server.", "BẢO VỆ", 0, 16); Exit }
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://script.phattan.id.vn/tool/install.ps1 | iex`"" -Verb RunAs; Exit }

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[System.Net.ServicePointManager]::Expect100Continue = $true; [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; $ErrorActionPreference = "SilentlyContinue"

# TẠO BIẾN FONT DÙNG CHUNG
$FontTitle = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$FontHeader = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$FontBtn = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$FontBtnSmall = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$FontText = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$FontConsole = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular)

function Get-HWID {
    $C = (Get-WmiObject Win32_Processor).ProcessorId; $B = (Get-WmiObject Win32_BaseBoard).SerialNumber; if (!$C) { $C = "VM" }; if (!$B) { $B = "VM" }
    $MD = [System.Security.Cryptography.MD5]::Create(); return ([System.BitConverter]::ToString($MD.ComputeHash([System.Text.Encoding]::UTF8.GetBytes("$C-$B"))) -replace "-", "").Substring(0, 16)
}
$Global:MyHWID = Get-HWID; $Global:PCName = $env:COMPUTERNAME

$encApi = "aHR0cHM6Ly9hcGkucGhhdHRhbi5pZC52bi9hcGkucGhw"; $Global:ApiServer = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encApi))
$encBaseUrl = "aHR0cHM6Ly9naXRodWIuY29tL0hlbGxvMmsyL0toby1Eby1OZ2hlL3JlbGVhc2VzL2Rvd25sb2FkL3YxLjAv"; $BaseUrl = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encBaseUrl))
$encRawUrl = "aHR0cHM6Ly9zY3JpcHQucGhhdHRhbi5pZC52bi90b29sLw=="; $RawUrl = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encRawUrl))
$encJsonUrl = "aHR0cHM6Ly9zY3JpcHQucGhhdHRhbi5pZC52bi90b29sL2FwcHMuanNvbg=="; $JsonUrl = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encJsonUrl))

$TempDir = "$env:TEMP\PhatTan_Tool"; if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }
$Global:SessionFile = "$env:LOCALAPPDATA\PhatTan_Titan.dat"
$Global:AvatarFile = "$env:LOCALAPPDATA\PhatTan_Avatar.png"
$Global:IsAuthenticated = $false; $Global:LicenseType = "NONE"; $Global:UserEmail = ""; $Global:LocalPass = "root"; $Global:ServerPass = "root"
$Global:LogBox = $null; $Global:JsonData = $null

function Load-JsonData {
    if ($Global:JsonData -eq $null) {
        Write-Host "[TITAN-CORE] Đang tải danh sách Apps từ Server..." -ForegroundColor Yellow
        try { 
            $Ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            $wc = New-Object System.Net.WebClient
            $wc.Encoding = [System.Text.Encoding]::UTF8
            $wc.Headers.Add("User-Agent", "Titan/20")
            $RawJson = $wc.DownloadString("$($JsonUrl)?t=$Ts")
            $Global:JsonData = $RawJson | ConvertFrom-Json
        } catch { Write-Host "[TITAN-CORE] Lỗi tải JSON: $($_.Exception.Message)" -ForegroundColor Red }
    }
}

function Write-GuiLog ($Msg) {
    $Time = Get-Date -Format "HH:mm:ss"; $FullMsg = "[$Time] $Msg`n"; Write-Host "[TITAN-CORE] $Msg" -ForegroundColor Cyan
    if ($Global:IsWpfMode -and $Global:LogBox) { $Global:LogBox.Dispatcher.Invoke({ $Global:LogBox.AppendText($FullMsg); $Global:LogBox.ScrollToEnd() }) } 
    elseif (-not $Global:IsWpfMode -and $Global:LogBox) { $Global:LogBox.AppendText($FullMsg); $Global:LogBox.ScrollToCaret() }
}

function Call-API ($Action, $Payload) { try { $Payload.Add("action", $Action); $JsonString = $Payload | ConvertTo-Json -Depth 10 -Compress; $Utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($JsonString); return Invoke-RestMethod -Uri $Global:ApiServer -Method Post -Body $Utf8Bytes -ContentType "application/json; charset=utf-8" -TimeoutSec 15 } catch { return @{ status="error"; message="Mất kết nối Máy chủ!" } } }

# ==============================================================================
# LƯU SESSION REGISTRY
# ==============================================================================
$Global:RegPath = "HKCU:\Software\TitanPC"
function Save-Session ($E, $T, $H, $LP, $SP) { 
    $R = "$E|PT|$T|PC|$H|LP|$LP|SP|$SP"; $Encoded = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($R))
    if (-not (Test-Path $Global:RegPath)) { New-Item -Path $Global:RegPath -Force | Out-Null }
    Set-ItemProperty -Path $Global:RegPath -Name "SessionData" -Value $Encoded -Force
    try { [System.IO.File]::WriteAllText($Global:SessionFile, $Encoded) } catch {}
}
function Load-Session { 
    $Global:RegPath = "HKCU:\Software\TitanPC"; $Encoded = $null
    if (Test-Path $Global:RegPath) { $RegVal = Get-ItemProperty -Path $Global:RegPath -Name "SessionData" -ErrorAction SilentlyContinue; if ($RegVal) { $Encoded = $RegVal.SessionData } }
    if ([string]::IsNullOrEmpty($Encoded) -and [System.IO.File]::Exists($Global:SessionFile)) { try { $Encoded = [System.IO.File]::ReadAllText($Global:SessionFile).Trim() } catch {} }
    if ($Encoded) {
        try { 
            $Decoded = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Encoded)); $P = $Decoded -split "\|"
            if ($P[4] -eq $Global:MyHWID) { $Global:UserEmail = $P[0]; $Global:LicenseType = $P[2]; $Global:LocalPass = $P[6]; $Global:ServerPass = $P[8]; return $true }
        } catch { }
    }
    if (Test-Path $Global:RegPath) { Remove-ItemProperty -Path $Global:RegPath -Name "SessionData" -ErrorAction SilentlyContinue }
    if (Test-Path $Global:SessionFile) { Remove-Item $Global:SessionFile -Force -ErrorAction SilentlyContinue }
    return $false 
}

# ==============================================================================
# UI FORMS CƠ BẢN
# ==============================================================================
function Show-OtpInput ($Title, $Msg, $Link, $EmailToCheck) {
    $OForm = New-Object System.Windows.Forms.Form; $OForm.Text = $Title; $OForm.Size = "400, 240"; $OForm.StartPosition = "CenterParent"; $OForm.FormBorderStyle = "FixedToolWindow"; $OForm.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 25); $OForm.ForeColor = "White"
    $LblMsg = New-Object System.Windows.Forms.Label; $LblMsg.Text = $Msg; $LblMsg.Location = "20, 15"; $LblMsg.Size = "340, 45"; $LblMsg.Font = $FontText; $OForm.Controls.Add($LblMsg)
    $TxtOtp = New-Object System.Windows.Forms.TextBox; $TxtOtp.Location = "20, 65"; $TxtOtp.Size = "340, 30"; $TxtOtp.Font = $FontHeader; $TxtOtp.TextAlign = "Center"; $OForm.Controls.Add($TxtOtp)
    
    $LnkWeb = New-Object System.Windows.Forms.LinkLabel; $LnkWeb.Text = "⚠️ Bấm vào đây để xem trực tiếp OTP!"; $LnkWeb.Location = "20, 110"; $LnkWeb.Size = "340, 20"; $LnkWeb.Font = $FontText; $LnkWeb.LinkColor = "DeepSkyBlue"; $LnkWeb.ActiveLinkColor = "Red"; $LnkWeb.Cursor = "Hand"
    $LnkWeb.Add_Click({ 
        if ($Link) { 
            $OForm.Cursor="WaitCursor"
            $QA = Call-API "get_security_question" @{ email=$EmailToCheck }
            $OForm.Cursor="Default"

            if ($QA.status -eq "success") {
                $AnsInput = [Microsoft.VisualBasic.Interaction]::InputBox("Trang web yêu cầu xác minh bảo mật trước khi xem OTP.`n`nCâu hỏi của bạn: $($QA.question)", "Bảo mật tài khoản", "")
                if ($AnsInput -eq $QA.answer) { Start-Process $Link } 
                else { [System.Windows.Forms.MessageBox]::Show("Sai câu trả lời bảo mật! Không thể xem OTP.", "CẢNH BÁO", 0, 16) }
            } else { [System.Windows.Forms.MessageBox]::Show("Không thể tải câu hỏi bảo mật. Lỗi máy chủ!", "LỖI", 0, 16) }
        } 
    })
    if ([string]::IsNullOrEmpty($Link)) { $LnkWeb.Visible = $false }; $OForm.Controls.Add($LnkWeb)
    
    $BtnOk = New-Object System.Windows.Forms.Button; $BtnOk.Text = "XÁC NHẬN"; $BtnOk.Location = "20, 145"; $BtnOk.Size = "340, 40"; $BtnOk.BackColor = "ForestGreen"; $BtnOk.ForeColor = "White"; $BtnOk.Font = $FontBtn; $BtnOk.FlatStyle = "Flat"; $BtnOk.DialogResult = "OK"; $OForm.Controls.Add($BtnOk)
    $OForm.AcceptButton = $BtnOk; $OForm.ShowDialog() | Out-Null; $Res = if ($OForm.DialogResult -eq "OK") { $TxtOtp.Text.Trim() } else { $null }; $OForm.Dispose(); return $Res
}

function Show-Level2Pass ($TitleMsg) {
    $OForm = New-Object System.Windows.Forms.Form; $OForm.Text = "BẢO MẬT CỤC BỘ"; $OForm.Size = "400, 200"; $OForm.StartPosition = "CenterScreen"; $OForm.FormBorderStyle = "FixedToolWindow"; $OForm.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 25); $OForm.ForeColor = "White"
    $LblMsg = New-Object System.Windows.Forms.Label; $LblMsg.Text = $TitleMsg; $LblMsg.Location = "20, 20"; $LblMsg.Size = "340, 25"; $LblMsg.Font = $FontText; $OForm.Controls.Add($LblMsg)
    $TxtPass = New-Object System.Windows.Forms.TextBox; $TxtPass.Location = "20, 55"; $TxtPass.Size = "340, 30"; $TxtPass.Font = $FontHeader; $TxtPass.PasswordChar = "*"; $TxtPass.TextAlign = "Center"; $OForm.Controls.Add($TxtPass)
    $BtnOk = New-Object System.Windows.Forms.Button; $BtnOk.Text = "MỞ KHÓA TOOL"; $BtnOk.Location = "20, 100"; $BtnOk.Size = "340, 40"; $BtnOk.BackColor = "OrangeRed"; $BtnOk.ForeColor = "White"; $BtnOk.Font = $FontBtn; $BtnOk.FlatStyle = "Flat"; $BtnOk.DialogResult = "OK"; $OForm.Controls.Add($BtnOk)
    $OForm.AcceptButton = $BtnOk; $OForm.ShowDialog() | Out-Null; $Res = if ($OForm.DialogResult -eq "OK") { $TxtPass.Text.Trim() } else { "CANCEL" }; $OForm.Dispose(); return $Res
}

function Show-QRPay ($Amount, $Prefix, $Email, $TitleMsg) {
    $SafeEmail = $Email -replace "\s", ""; $Content = "$Prefix $SafeEmail"; $UrlContent = [uri]::EscapeDataString($Content)
    $QrUrl = "https://img.vietqr.io/image/970436-1055835227-qr_only.png?accountName=DANG%20LAM%20TAN%20PHAT&addInfo=$UrlContent"; if ($Amount -gt 0) { $QrUrl += "&amount=$Amount" }
    $Q = New-Object System.Windows.Forms.Form; $Q.Size = "750, 480"; $Q.StartPosition = "CenterScreen"; $Q.Text = "TITAN SECURE PAY - $TitleMsg"; $Q.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 250); $Q.FormBorderStyle = "FixedToolWindow"
    $LblTop = New-Object System.Windows.Forms.Label; $LblTop.Text = "CỔNG THANH TOÁN TỰ ĐỘNG"; $LblTop.Dock = "Top"; $LblTop.TextAlign = "MiddleCenter"; $LblTop.Font = $FontTitle; $LblTop.ForeColor = [System.Drawing.Color]::White; $LblTop.BackColor = [System.Drawing.Color]::FromArgb(0, 102, 204); $LblTop.Height = 60; $Q.Controls.Add($LblTop)
    $PnlQR = New-Object System.Windows.Forms.Panel; $PnlQR.Location = "20, 80"; $PnlQR.Size = "320, 320"; $PnlQR.BackColor = [System.Drawing.Color]::White; $PnlQR.BorderStyle = "FixedSingle"; $Q.Controls.Add($PnlQR)
    $Pic = New-Object System.Windows.Forms.PictureBox; $Pic.Location = "10,10"; $Pic.Size = "300, 300"; $Pic.SizeMode = "Zoom"; try { $Pic.Load($QrUrl) } catch { }; $PnlQR.Controls.Add($Pic)
    $PnlInfo = New-Object System.Windows.Forms.Panel; $PnlInfo.Location = "360, 80"; $PnlInfo.Size = "350, 320"; $PnlInfo.BackColor = [System.Drawing.Color]::White; $PnlInfo.BorderStyle = "FixedSingle"; $Q.Controls.Add($PnlInfo)
    $BankName = New-Object System.Windows.Forms.Label; $BankName.Text = "VIETCOMBANK"; $BankName.Location = "20,20"; $BankName.AutoSize=$true; $BankName.Font = $FontHeader; $BankName.ForeColor=[System.Drawing.Color]::Green; $PnlInfo.Controls.Add($BankName)
    $L2 = New-Object System.Windows.Forms.Label; $L2.Text = "Số tài khoản: 1055835227"; $L2.Location = "20, 70"; $L2.AutoSize=$true; $L2.Font = $FontBtn; $PnlInfo.Controls.Add($L2)
    $L3 = New-Object System.Windows.Forms.Label; $L3.Text = "Số tiền: " + (if($Amount -gt 0){"{0:N0} VNĐ" -f $Amount}else{"TÙY TÂM"}); $L3.Location = "20, 110"; $L3.AutoSize=$true; $L3.Font = $FontHeader; $L3.ForeColor="Red"; $PnlInfo.Controls.Add($L3)
    $L4 = New-Object System.Windows.Forms.Label; $L4.Text = "Nội dung: $Content"; $L4.Location = "20, 160"; $L4.AutoSize=$true; $L4.Font = $FontBtn; $L4.ForeColor="Blue"; $PnlInfo.Controls.Add($L4)
    $Warn = New-Object System.Windows.Forms.Label; $Warn.Text = "⚠️ Vui lòng ghi ĐÚNG NỘI DUNG để Server tự duyệt."; $Warn.Location = "20, 250"; $Warn.Size="300,40"; $Warn.Font = $FontText; $Warn.ForeColor="OrangeRed"; $PnlInfo.Controls.Add($Warn)
    $Q.ShowDialog() | Out-Null; $Q.Dispose()
}

function Show-Store {
    $S = New-Object System.Windows.Forms.Form; $S.Size="450, 400"; $S.StartPosition="CenterParent"; $S.Text="NÂNG CẤP GÓI VIP"; $S.BackColor=[System.Drawing.Color]::FromArgb(20,20,25); $S.FormBorderStyle="FixedToolWindow"
    $L = New-Object System.Windows.Forms.Label; $L.Text="🛒 CHỌN GÓI CƯỚC"; $L.Font = $FontHeader; $L.ForeColor="White"; $L.Location="110,15"; $L.AutoSize=$true; $S.Controls.Add($L)
    $BTrial = New-Object System.Windows.Forms.Button; $BTrial.Text="🎁 LẤY / GIA HẠN KEY 7 NGÀY (Cần Donate)"; $BTrial.Location="20,60"; $BTrial.Size="390,40"; $BTrial.BackColor="DarkMagenta"; $BTrial.ForeColor="White"; $BTrial.FlatStyle="Flat"; $BTrial.Font=$FontBtnSmall; $S.Controls.Add($BTrial)
    $BTrial.Add_Click({ $E = Show-Level2Pass "Nhập Email của bạn:"; if ($E -ne "CANCEL" -and $E -ne "") { $S.Cursor="WaitCursor"; $R = Call-API "request_trial" @{ email=$E }; [System.Windows.Forms.MessageBox]::Show($R.message, "Thông báo"); $S.Cursor="Default" } })
    $B1M = New-Object System.Windows.Forms.Button; $B1M.Text="🥉 VIP 1 THÁNG (29.000đ)"; $B1M.Location="20,110"; $B1M.Size="190,50"; $B1M.BackColor="MediumSeaGreen"; $B1M.ForeColor="White"; $B1M.FlatStyle="Flat"; $B1M.Font=$FontBtnSmall; $S.Controls.Add($B1M)
    $B1M.Add_Click({ $E = Show-Level2Pass "Nhập Email nâng cấp VIP 1 THÁNG:"; if ($E -ne "CANCEL" -and $E -ne "") { Show-QRPay 29000 "MUA KEY 1M" $E "VIP 1 THÁNG" } })
    $B6M = New-Object System.Windows.Forms.Button; $B6M.Text="🥈 VIP 6 THÁNG (149.000đ)"; $B6M.Location="220,110"; $B6M.Size="190,50"; $B6M.BackColor="DodgerBlue"; $B6M.ForeColor="White"; $B6M.FlatStyle="Flat"; $B6M.Font=$FontBtnSmall; $S.Controls.Add($B6M)
    $B6M.Add_Click({ $E = Show-Level2Pass "Nhập Email nâng cấp VIP 6 THÁNG:"; if ($E -ne "CANCEL" -and $E -ne "") { Show-QRPay 149000 "MUA KEY 6M" $E "VIP 6 THÁNG" } })
    $BFull = New-Object System.Windows.Forms.Button; $BFull.Text="💎 VIP VĨNH VIỄN (200.000đ)"; $BFull.Location="20,170"; $BFull.Size="190,50"; $BFull.BackColor="Gold"; $BFull.ForeColor="Black"; $BFull.FlatStyle="Flat"; $BFull.Font=$FontBtnSmall; $S.Controls.Add($BFull)
    $BFull.Add_Click({ $E = Show-Level2Pass "Nhập Email nâng cấp VIP VĨNH VIỄN:"; if ($E -ne "CANCEL" -and $E -ne "") { Show-QRPay 200000 "MUA KEY VIP" $E "VIP VĨNH VIỄN" } })
    $BFam = New-Object System.Windows.Forms.Button; $BFam.Text="👑 ĐẠI LÝ (800.000đ - 25 PC)"; $BFam.Location="220,170"; $BFam.Size="190,50"; $BFam.BackColor="DarkOrange"; $BFam.ForeColor="Black"; $BFam.FlatStyle="Flat"; $BFam.Font=$FontBtnSmall; $S.Controls.Add($BFam)
    $BFam.Add_Click({ $E = Show-Level2Pass "Nhập Email nâng cấp GÓI ĐẠI LÝ:"; if ($E -ne "CANCEL" -and $E -ne "") { Show-QRPay 800000 "MUA KEY MULTI" $E "GÓI ĐẠI LÝ" } })
    $S.ShowDialog() | Out-Null; $S.Dispose()
}

function Show-DeviceManager {
    $DM = New-Object System.Windows.Forms.Form
    $DM.Text = "QUẢN LÝ THIẾT BỊ ĐĂNG NHẬP | $($Global:UserEmail)"
    $DM.Size = "750, 450"; $DM.StartPosition = "CenterParent"; $DM.BackColor = [System.Drawing.Color]::FromArgb(25,25,30); $DM.ForeColor = "White"; $DM.FormBorderStyle="FixedToolWindow"

    $LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text = "💻 DANH SÁCH MÁY TÍNH ĐANG SỬ DỤNG KEY"; $LblTitle.Font = $FontHeader; $LblTitle.ForeColor = "DeepSkyBlue"; $LblTitle.Location = "20, 15"; $LblTitle.AutoSize = $true; $DM.Controls.Add($LblTitle)

    $Grid = New-Object System.Windows.Forms.DataGridView
    $Grid.Location = "20, 50"; $Grid.Size = "690, 280"; $Grid.BackgroundColor = [System.Drawing.Color]::FromArgb(40,40,45); $Grid.Font = $FontText
    $Grid.ForeColor = "Black"; $Grid.AllowUserToAddRows = $false; $Grid.RowHeadersVisible = $false; $Grid.SelectionMode = "FullRowSelect"; $Grid.AutoSizeColumnsMode = "Fill"
    
    $ChkCol = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn; $ChkCol.HeaderText = "Chọn"; $ChkCol.Width = 50; $Grid.Columns.Add($ChkCol) | Out-Null
    $Grid.Columns.Add("PCName", "Tên Máy") | Out-Null
    $Grid.Columns.Add("HWID", "Mã Phần Cứng") | Out-Null
    $Grid.Columns.Add("LastLogin", "Lần Cuối Truy Cập") | Out-Null
    $Grid.Columns.Add("Location", "Vị Trí (IP)") | Out-Null
    $DM.Controls.Add($Grid)

    $DM.Cursor = "WaitCursor"
    $Res = Call-API "get_devices" @{ email=$Global:UserEmail }
    if ($Res.status -eq "success") {
        $DeviceList = @()
        if ($Res.devices -is [array]) { $DeviceList = $Res.devices }
        elseif ($Res.devices -ne $null) { $DeviceList += $Res.devices }
        
        foreach ($dev in $DeviceList) {
            $RowIdx = $Grid.Rows.Add()
            $Grid.Rows[$RowIdx].Cells[1].Value = $dev.machine_name
            $Grid.Rows[$RowIdx].Cells[2].Value = $dev.hwid
            $Grid.Rows[$RowIdx].Cells[3].Value = $dev.last_login
            $Grid.Rows[$RowIdx].Cells[4].Value = $dev.location
            if ($dev.hwid -eq $Global:MyHWID) { 
                $Grid.Rows[$RowIdx].DefaultCellStyle.BackColor = [System.Drawing.Color]::LightGreen 
                $Grid.Rows[$RowIdx].Cells[1].Value += " (Máy này)"
                $Grid.Rows[$RowIdx].Cells[0].ReadOnly = $true 
            }
        }
    } else { [System.Windows.Forms.MessageBox]::Show("Không thể tải danh sách thiết bị!", "Lỗi", 0, 16) }
    $DM.Cursor = "Default"

    $BtnRemove = New-Object System.Windows.Forms.Button; $BtnRemove.Text="🗑 GỠ MÁY ĐÃ CHỌN"; $BtnRemove.Location="20, 350"; $BtnRemove.Size="200, 40"; $BtnRemove.BackColor="OrangeRed"; $BtnRemove.FlatStyle="Flat"; $BtnRemove.Font=$FontBtn
    $BtnRemove.Add_Click({
        $SelectedHWIDs = @()
        foreach ($row in $Grid.Rows) { if ($row.Cells[0].Value -eq $true) { $SelectedHWIDs += $row.Cells[2].Value } }
        if ($SelectedHWIDs.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn máy nào!"); return }
        
        $confirm = [System.Windows.Forms.MessageBox]::Show("Gỡ $($SelectedHWIDs.Count) thiết bị đã chọn?", "Xác nhận", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($confirm -eq "Yes") {
            $DM.Cursor="WaitCursor"; $R = Call-API "remove_device" @{ email=$Global:UserEmail; hwids=$SelectedHWIDs }
            if ($R.status -eq "success") { [System.Windows.Forms.MessageBox]::Show($R.message); $DM.Close() } else { [System.Windows.Forms.MessageBox]::Show($R.message) }
            $DM.Cursor="Default"
        }
    })
    $DM.Controls.Add($BtnRemove)

    $BtnLogoutAll = New-Object System.Windows.Forms.Button; $BtnLogoutAll.Text="💥 ĐĂNG XUẤT TOÀN BỘ (Trừ máy này)"; $BtnLogoutAll.Location="240, 350"; $BtnLogoutAll.Size="300, 40"; $BtnLogoutAll.BackColor="DarkRed"; $BtnLogoutAll.FlatStyle="Flat"; $BtnLogoutAll.Font=$FontBtn
    $BtnLogoutAll.Add_Click({
        $confirm = [System.Windows.Forms.MessageBox]::Show("Hành động này sẽ kích toàn bộ người dùng khác đang xài chung tài khoản. Tiếp tục?", "Cảnh báo", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Error)
        if ($confirm -eq "Yes") {
            $DM.Cursor="WaitCursor"; $R = Call-API "logout_all" @{ email=$Global:UserEmail; current_hwid=$Global:MyHWID }
            if ($R.status -eq "success") { [System.Windows.Forms.MessageBox]::Show($R.message); $DM.Close() }
            $DM.Cursor="Default"
        }
    })
    $DM.Controls.Add($BtnLogoutAll)

    $DM.ShowDialog() | Out-Null; $DM.Dispose()
}

function Show-ProfileForm {
    $ProfForm = New-Object System.Windows.Forms.Form
    $ProfForm.Text = "Hồ Sơ Của Tôi"; $ProfForm.Size = "400, 420"; $ProfForm.StartPosition = "CenterParent"; $ProfForm.BackColor = [System.Drawing.Color]::FromArgb(25,25,30); $ProfForm.ForeColor = "White"; $ProfForm.FormBorderStyle="FixedToolWindow"
    
    $Pic = New-Object System.Windows.Forms.PictureBox; $Pic.Size = "120,120"; $Pic.Location = "20,20"; $Pic.SizeMode = "StretchImage"; $Pic.BackColor = "Gray"
    $Path = New-Object System.Drawing.Drawing2D.GraphicsPath; $Path.AddEllipse(0, 0, 120, 120); $Pic.Region = New-Object System.Drawing.Region($Path)
    if (Test-Path $Global:AvatarFile) { try { $Pic.Image = [System.Drawing.Image]::FromFile($Global:AvatarFile) } catch {} }
    $ProfForm.Controls.Add($Pic)

    $BtnUpload = New-Object System.Windows.Forms.Button; $BtnUpload.Text="Đổi Avatar"; $BtnUpload.Location="30, 150"; $BtnUpload.Size="100, 30"; $BtnUpload.BackColor="SteelBlue"; $BtnUpload.FlatStyle="Flat"; $BtnUpload.Font=$FontBtnSmall
    $BtnUpload.Add_Click({
        $FD = New-Object System.Windows.Forms.OpenFileDialog; $FD.Filter = "Image Files|*.jpg;*.jpeg;*.png"
        if ($FD.ShowDialog() -eq 'OK') {
            try {
                $Img = [System.Drawing.Image]::FromFile($FD.FileName); $Ratio = $Img.Width / $Img.Height; $NewW = 512; $NewH = 512
                if ($Ratio -gt 1) { $NewH = [math]::Floor(512 / $Ratio) } else { $NewW = [math]::Floor(512 * $Ratio) }
                $Bmp = New-Object System.Drawing.Bitmap($NewW, $NewH); $G = [System.Drawing.Graphics]::FromImage($Bmp); $G.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic; $G.DrawImage($Img, 0, 0, $NewW, $NewH); $G.Dispose(); $Img.Dispose()
                if (Test-Path $Global:AvatarFile) { Remove-Item $Global:AvatarFile -Force }
                $Bmp.Save($Global:AvatarFile, [System.Drawing.Imaging.ImageFormat]::Png); $Pic.Image = $Bmp
            } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi xử lý ảnh!") }
        }
    })
    $ProfForm.Controls.Add($BtnUpload)

    $L_Email = New-Object System.Windows.Forms.Label; $L_Email.Text = "📧 Email: $($Global:UserEmail)"; $L_Email.Location="160, 30"; $L_Email.AutoSize=$true; $L_Email.Font = $FontBtnSmall; $ProfForm.Controls.Add($L_Email)
    $L_Plan = New-Object System.Windows.Forms.Label; $L_Plan.Text = "💎 Gói: $($Global:LicenseType)"; $L_Plan.Location="160, 65"; $L_Plan.AutoSize=$true; $L_Plan.Font = $FontBtnSmall; $L_Plan.ForeColor="Lime"; $ProfForm.Controls.Add($L_Plan)
    
    $BtnChangeLocal = New-Object System.Windows.Forms.Button; $BtnChangeLocal.Text="🔑 Đổi Pass Tool (Cấp 2)"; $BtnChangeLocal.Location="160, 105"; $BtnChangeLocal.Size="200, 35"; $BtnChangeLocal.BackColor="OrangeRed"; $BtnChangeLocal.FlatStyle="Flat"; $BtnChangeLocal.Font=$FontBtnSmall
    $BtnChangeLocal.Add_Click({
        $Old = Show-Level2Pass "Nhập Pass Cấp 2 hiện tại (Hoặc Master Pass):"
        if ($Old -eq "CANCEL" -or $Old -eq "") { return }
        if ($Old -eq $Global:LocalPass -or $Old -eq $Global:ServerPass) {
            $New = Show-Level2Pass "Nhập Mật mã Cấp 2 MỚI cho máy này:"
            if ($New -ne "CANCEL" -and $New -ne "") { $Global:LocalPass = $New; Save-Session $Global:UserEmail $Global:LicenseType $Global:MyHWID $Global:LocalPass $Global:ServerPass; [System.Windows.Forms.MessageBox]::Show("Đổi Mật mã thành công!") }
        } else { [System.Windows.Forms.MessageBox]::Show("Sai Mật mã!", "Lỗi") }
    })
    $ProfForm.Controls.Add($BtnChangeLocal)

    $BtnDeviceMgr = New-Object System.Windows.Forms.Button; $BtnDeviceMgr.Text="💻 QUẢN LÝ THIẾT BỊ (Đăng xuất)"; $BtnDeviceMgr.Location="160, 150"; $BtnDeviceMgr.Size="200, 35"; $BtnDeviceMgr.BackColor="Teal"; $BtnDeviceMgr.FlatStyle="Flat"; $BtnDeviceMgr.Font=$FontBtnSmall
    $BtnDeviceMgr.Add_Click({ Show-DeviceManager })
    $ProfForm.Controls.Add($BtnDeviceMgr)

    # --- KHU VỰC NHẬP KEY (GIFT CODE) ---
    $LblKey = New-Object System.Windows.Forms.Label; $LblKey.Text = "🎁 Kích hoạt mã Key VIP:"; $LblKey.Location="160, 200"; $LblKey.AutoSize=$true; $LblKey.Font = $FontBtnSmall; $ProfForm.Controls.Add($LblKey)
    $TxtKey = New-Object System.Windows.Forms.TextBox; $TxtKey.Location="160, 225"; $TxtKey.Size="130, 25"; $TxtKey.Font = $FontText; $ProfForm.Controls.Add($TxtKey)
    $BtnKey = New-Object System.Windows.Forms.Button; $BtnKey.Text="NHẬP"; $BtnKey.Location="300, 224"; $BtnKey.Size="60, 27"; $BtnKey.BackColor="MediumSeaGreen"; $BtnKey.ForeColor="White"; $BtnKey.FlatStyle="Flat"; $BtnKey.Font=$FontBtnSmall
    $BtnKey.Add_Click({
        $K = $TxtKey.Text.Trim()
        if (!$K) { [System.Windows.Forms.MessageBox]::Show("Vui lòng nhập mã Key!", "Lỗi"); return }
        $ProfForm.Cursor = "WaitCursor"
        $R = Call-API "redeem_key" @{ email=$Global:UserEmail; key_code=$K }
        $ProfForm.Cursor = "Default"
        if ($R.status -eq "success") {
            [System.Windows.Forms.MessageBox]::Show($R.message, "Thành công")
            $Global:LicenseType = $R.new_package
            $L_Plan.Text = "💎 Gói: $($Global:LicenseType)"
            Save-Session $Global:UserEmail $Global:LicenseType $Global:MyHWID $Global:LocalPass $Global:ServerPass
            $TxtKey.Text = ""
        } else {
            [System.Windows.Forms.MessageBox]::Show($R.message, "Lỗi", 0, 16)
        }
    })
    $ProfForm.Controls.Add($BtnKey)

    $ProfForm.ShowDialog() | Out-Null; $ProfForm.Dispose()
}

# ==============================================================================
# GIAO DIỆN ĐĂNG NHẬP GATEWAY
# ==============================================================================
function Show-AuthGateway {
    $Auth = New-Object System.Windows.Forms.Form; $Auth.Text = "TITAN ENGINE V20.13 | HWID: $($Global:MyHWID)"; $Auth.Size = "500, 530"; $Auth.StartPosition = "CenterScreen"; $Auth.FormBorderStyle = "FixedToolWindow"; $Auth.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 18); $Auth.ForeColor = "White"
    $LTitle = New-Object System.Windows.Forms.Label; $LTitle.Text = "TITAN TOOLKIT LOGIN"; $LTitle.Font = $FontTitle; $LTitle.ForeColor = "DeepSkyBlue"; $LTitle.AutoSize = $true; $LTitle.Location = "105, 15"; $Auth.Controls.Add($LTitle)
    
    $PnlLogin = New-Object System.Windows.Forms.Panel; $PnlLogin.Size = "460, 400"; $PnlLogin.Location = "10, 60"; $Auth.Controls.Add($PnlLogin)
    $L1=New-Object System.Windows.Forms.Label;$L1.Text="Email đăng nhập:";$L1.Location="20,10";$L1.AutoSize=$true;$L1.Font=$FontText;$PnlLogin.Controls.Add($L1); $TUser=New-Object System.Windows.Forms.TextBox;$TUser.Location="20,30";$TUser.Size="420,30";$TUser.Font=$FontText;$PnlLogin.Controls.Add($TUser)
    $L2=New-Object System.Windows.Forms.Label;$L2.Text="Mật khẩu:";$L2.Location="20,70";$L2.AutoSize=$true;$L2.Font=$FontText;$PnlLogin.Controls.Add($L2); $TPass=New-Object System.Windows.Forms.TextBox;$TPass.Location="20,90";$TPass.Size="420,30";$TPass.Font=$FontText;$TPass.PasswordChar="*";$PnlLogin.Controls.Add($TPass)
    $BLog = New-Object System.Windows.Forms.Button; $BLog.Text="ĐĂNG NHẬP SERVER"; $BLog.Location="20,135"; $BLog.Size="420,45"; $BLog.BackColor="DodgerBlue"; $BLog.ForeColor="White"; $BLog.Font=$FontBtn; $BLog.FlatStyle="Flat"; $PnlLogin.Controls.Add($BLog)
    $BLog.Add_Click({
        if ($TUser.Text -and $TPass.Text) {
            $Auth.Cursor = "WaitCursor"; $BLog.Text = "ĐANG CHECK DATABASE..."; 
            $R = Call-API "login" @{ email=$TUser.Text; password=$TPass.Text; hwid=$Global:MyHWID; machine_name=$Global:PCName }
            if ($R.status -eq "error" -or $R.status -eq "banned" -or $R.status -eq "fail") { [System.Windows.Forms.MessageBox]::Show($R.message, "Lỗi", 0, 16) }
            else {
                $WaitOTP = $false; $OTPType = ""
                if ($R.status -eq "require_device_otp") { $WaitOTP = $true; $OTPType = "device" } elseif ($R.status -eq "require_2fa") { $WaitOTP = $true; $OTPType = "2fa" }
                if ($WaitOTP) {
                    $OTP = Show-OtpInput "XÁC MINH BẢO MẬT" "Mã xác minh (Device/2FA) đã được gửi đến Email:" $R.otp_link $TUser.Text
                    if ($OTP) { 
                        $R2 = Call-API "verify_otp" @{ email=$TUser.Text; otp=$OTP; hwid=$Global:MyHWID; machine_name=$Global:PCName; type=$OTPType }
                        if ($R2.status -eq "require_2fa") { $OTP2 = Show-OtpInput "XÁC MINH BẢO MẬT 2 LỚP" $R2.message $R2.otp_link $TUser.Text; $R2 = Call-API "verify_otp" @{ email=$TUser.Text; otp=$OTP2; hwid=$Global:MyHWID; type="2fa" } }
                        if ($R2.status -eq "success") { $R = $R2 } else { [System.Windows.Forms.MessageBox]::Show($R2.message, "LỖI", 0, 16); $R = $null }
                    } else { $R = $null }
                }
                if ($R -and $R.status -eq "success") { $Global:IsAuthenticated=$true; $Global:LicenseType=$R.package; $Global:UserEmail=$TUser.Text; $Global:LocalPass="root"; $Global:ServerPass=$R.aes_key; Save-Session $Global:UserEmail $Global:LicenseType $Global:MyHWID $Global:LocalPass $Global:ServerPass; $Auth.Close() }
            }
            $Auth.Cursor = "Default"; $BLog.Text = "ĐĂNG NHẬP SERVER"
        }
    })
    $BFree = New-Object System.Windows.Forms.Button; $BFree.Text="⏱️ Mở Tool Trải Nghiệm (Free 30 Phút)"; $BFree.Location="20,195"; $BFree.Size="420,35"; $BFree.BackColor="Teal"; $BFree.ForeColor="White"; $BFree.FlatStyle="Flat"; $BFree.Font=$FontText; $PnlLogin.Controls.Add($BFree)
    $BFree.Add_Click({ [System.Windows.Forms.MessageBox]::Show("Chế độ Free bị KHÓA CÁC TÍNH NĂNG VIP."); $Global:IsAuthenticated=$true; $Global:LicenseType="FREE_30M"; $Auth.Close() })
    $BForgot = New-Object System.Windows.Forms.Button; $BForgot.Text="Quên mật khẩu?"; $BForgot.Location="20,245"; $BForgot.Size="130,30"; $BForgot.BackColor="Transparent"; $BForgot.ForeColor="LightSkyBlue"; $BForgot.FlatStyle="Flat"; $BForgot.FlatAppearance.BorderSize=0; $BForgot.Font=$FontText; $PnlLogin.Controls.Add($BForgot)
    $BShowReg = New-Object System.Windows.Forms.Button; $BShowReg.Text="Tạo tài khoản"; $BShowReg.Location="160,245"; $BShowReg.Size="130,30"; $BShowReg.BackColor="DimGray"; $BShowReg.FlatStyle="Flat"; $BShowReg.Font=$FontText; $PnlLogin.Controls.Add($BShowReg)
    $BStore = New-Object System.Windows.Forms.Button; $BStore.Text="Cửa Hàng VIP"; $BStore.Location="300,245"; $BStore.Size="140,30"; $BStore.BackColor="Gold"; $BStore.ForeColor="Black"; $BStore.FlatStyle="Flat"; $BStore.Font=$FontBtnSmall; $PnlLogin.Controls.Add($BStore); $BStore.Add_Click({ Show-Store })
    
    $PnlReg = New-Object System.Windows.Forms.Panel; $PnlReg.Size = "460, 430"; $PnlReg.Location = "10, 60"; $PnlReg.Visible = $false; $Auth.Controls.Add($PnlReg)
    $R1=New-Object System.Windows.Forms.Label;$R1.Text="Họ tên:";$R1.Location="20,0";$R1.AutoSize=$true;$R1.Font=$FontText;$PnlReg.Controls.Add($R1); $TRName=New-Object System.Windows.Forms.TextBox;$TRName.Location="20,20";$TRName.Size="420,25";$PnlReg.Controls.Add($TRName)
    $R2=New-Object System.Windows.Forms.Label;$R2.Text="Email:";$R2.Location="20,50";$R2.AutoSize=$true;$R2.Font=$FontText;$PnlReg.Controls.Add($R2); $TREmail=New-Object System.Windows.Forms.TextBox;$TREmail.Location="20,70";$TREmail.Size="420,25";$PnlReg.Controls.Add($TREmail)
    $R3=New-Object System.Windows.Forms.Label;$R3.Text="Mật khẩu:";$R3.Location="20,100";$R3.AutoSize=$true;$R3.Font=$FontText;$PnlReg.Controls.Add($R3); $TRPass=New-Object System.Windows.Forms.TextBox;$TRPass.Location="20,120";$TRPass.Size="420,25";$TRPass.PasswordChar="*";$PnlReg.Controls.Add($TRPass)
    $R4=New-Object System.Windows.Forms.Label;$R4.Text="Câu hỏi bảo mật:";$R4.Location="20,150";$R4.AutoSize=$true;$R4.Font=$FontText;$PnlReg.Controls.Add($R4); $CSec=New-Object System.Windows.Forms.ComboBox;$CSec.Location="20,170";$CSec.Size="420,25";$CSec.DropDownStyle="DropDownList"; $CSec.Items.AddRange(@("Con vật yêu thích?","Tên trường cấp 1?","Người yêu cũ?"));$CSec.SelectedIndex=0;$PnlReg.Controls.Add($CSec)
    $R5=New-Object System.Windows.Forms.Label;$R5.Text="Trả lời:";$R5.Location="20,200";$R5.AutoSize=$true;$R5.Font=$FontText;$PnlReg.Controls.Add($R5); $TRAns=New-Object System.Windows.Forms.TextBox;$TRAns.Location="20,220";$TRAns.Size="420,25";$PnlReg.Controls.Add($TRAns)
    
    $Num1 = Get-Random -Minimum 1 -Maximum 10; $Num2 = Get-Random -Minimum 1 -Maximum 10; $Sum = $Num1 + $Num2
    $R6=New-Object System.Windows.Forms.Label;$R6.Text="Xác minh Robot: $Num1 + $Num2 = ?";$R6.Location="20,250";$R6.AutoSize=$true;$R6.Font=$FontBtn;$R6.ForeColor="Yellow";$PnlReg.Controls.Add($R6); $TRCaptcha=New-Object System.Windows.Forms.TextBox;$TRCaptcha.Location="20,270";$TRCaptcha.Size="420,25";$PnlReg.Controls.Add($TRCaptcha)

    $BReg = New-Object System.Windows.Forms.Button; $BReg.Text="XÁC NHẬN ĐĂNG KÝ"; $BReg.Location="20,310"; $BReg.Size="420,40"; $BReg.BackColor="Green"; $BReg.ForeColor="White"; $BReg.FlatStyle="Flat"; $BReg.Font=$FontBtn; $PnlReg.Controls.Add($BReg)
    $BReg.Add_Click({ 
        if ($TRCaptcha.Text -ne $Sum.ToString()) { [System.Windows.Forms.MessageBox]::Show("Mã xác minh toán học sai!", "Lỗi"); return }
        $Auth.Cursor="WaitCursor"; $R=Call-API "register" @{ name=$TRName.Text; email=$TREmail.Text; password=$TRPass.Text; question=$CSec.Text; answer=$TRAns.Text }; if($R.status -eq "success"){[System.Windows.Forms.MessageBox]::Show("Tạo thành công!");$PnlReg.Visible=$false;$PnlLogin.Visible=$true}else{[System.Windows.Forms.MessageBox]::Show($R.message)}; $Auth.Cursor="Default" 
    })
    $BBack = New-Object System.Windows.Forms.Button; $BBack.Text="Quay lại Đăng nhập"; $BBack.Location="20,360"; $BBack.Size="420,35"; $BBack.BackColor="DimGray"; $BBack.FlatStyle="Flat"; $BBack.Font=$FontText; $PnlReg.Controls.Add($BBack)
    
    $BShowReg.Add_Click({ $PnlLogin.Visible = $false; $PnlReg.Visible = $true })
    $BBack.Add_Click({ $PnlReg.Visible = $false; $PnlLogin.Visible = $true })

    Add-Type -AssemblyName Microsoft.VisualBasic
    $Auth.ShowDialog() | Out-Null; $Auth.Dispose()
}

Write-Host "[TITAN-CORE] Dang kiem tra Session..." -ForegroundColor Yellow
if (Load-Session) { 
    $RetryPass = $true
    while ($RetryPass) {
        $InputAES = Show-Level2Pass "Nhập Mật mã Cấp 2 (Hoặc Master Pass từ Server):"
        if ($InputAES -eq "CANCEL") { Write-Host "[TITAN-CORE] Huy dang nhap." -ForegroundColor Red; Exit }
        if ($InputAES -eq $Global:LocalPass -or $InputAES -eq $Global:ServerPass) { 
            $Global:IsAuthenticated = $true; $RetryPass = $false
        } else { [System.Windows.Forms.MessageBox]::Show("Sai Mật mã Cấp 2! Vui lòng thử lại.", "BẢO MẬT", 0, 16) }
    }
} else { Show-AuthGateway }
if (-not $Global:IsAuthenticated) { Exit }

Write-Host "[TITAN-CORE] Xac thuc thanh cong! Nap Giao dien..." -ForegroundColor Green
Load-JsonData

# ==============================================================================
# HÀM RUN-MODULE BẰNG .NET PROCESS
# ==============================================================================
function Invoke-SmartDownload ($Url, $OutFile) {
    if ($Url -match "drive\.google\.com") { $id = ""; if ($Url -match "id=([a-zA-Z0-9_-]+)") { $id = $matches[1] } elseif ($Url -match "/d/([a-zA-Z0-9_-]+)") { $id = $matches[1] }; if ($id) { $Session = New-Object Microsoft.PowerShell.Commands.WebRequestSession; $BaseDriveUrl = "https://drive.google.com/uc?id=$id&export=download"; try { $Resp1 = Invoke-WebRequest -Uri $BaseDriveUrl -WebSession $Session -UseBasicParsing -ErrorAction Stop; [System.IO.File]::WriteAllBytes($OutFile, $Resp1.Content); return $true } catch { $Html = $_.Exception.Response.GetResponseStream(); $Reader = New-Object System.IO.StreamReader($Html); $Content = $Reader.ReadToEnd(); $Reader.Close(); if ($Content -match "confirm=([a-zA-Z0-9_-]+)") { try { Invoke-WebRequest -Uri "$BaseDriveUrl&confirm=$($matches[1])" -OutFile $OutFile -WebSession $Session -UseBasicParsing; return $true } catch { return $false } } } } }
    if (Get-Command "curl.exe" -ErrorAction SilentlyContinue) { $p = Start-Process "curl" "-L -o `"$OutFile`" `"$Url`" -s --retry 3 -k" -Wait -PassThru -WindowStyle Hidden; if ($p.ExitCode -eq 0 -and (Test-Path $OutFile)) { return $true } }
    try { $w = New-Object System.Net.WebClient; $w.DownloadFile($Url, $OutFile); return $true } catch { return $false }
}
function Tai-Va-Chay { param ($L, $N, $T); if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }; if ($L -notmatch "^http") { $L = "$BaseUrl$L" }; $D = "$TempDir\$N"; if (Invoke-SmartDownload $L $D) { if ($T -eq "Msi") { Start-Process "msiexec.exe" "/i `"$D`" /quiet /norestart" -Wait } else { Start-Process $D -Wait } } }

function Run-ModuleAsync ($Btn, $ModulePath, $IsWpfBtn = $false) {
    $OriginalText = if ($IsWpfBtn) { $Btn.Content } else { $Btn.Text }
    if ($OriginalText -match "ĐANG MỞ") { return }

    Write-GuiLog "Dang nap tien trinh: $ModulePath"
    if ($IsWpfBtn) {
        $Btn.Content = "⏳ ĐANG MỞ..."; $Btn.Background = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("DimGray"); $Btn.IsEnabled = $false
    } else {
        $Btn.Text = "⏳ ĐANG MỞ..."; $Btn.BackColor = [System.Drawing.Color]::DimGray; $Btn.Enabled = $false
    }
    
    $TargetUrl = "$($RawUrl)$($ModulePath)?t=$(Get-Date -UFormat %s)"
    $StubCmd = "[System.Net.ServicePointManager]::SecurityProtocol = 3072 -bor 12288; `$c = `$null; try { `$w = New-Object System.Net.WebClient; `$w.Headers.Add('User-Agent', 'Titan/20'); `$w.Encoding = [System.Text.Encoding]::UTF8; `$c = `$w.DownloadString('$TargetUrl'); `$w.Dispose() } catch {}; if (`$c) { [scriptblock]::Create(`$c).Invoke() }; [System.GC]::Collect(); [Environment]::Exit(0)"
    $Encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($StubCmd))
    
    $ProcInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcInfo.FileName = "powershell.exe"
    if ($ModulePath -match "WinModder.ps1|AppStore.ps1") {
        $ProcInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Normal -EncodedCommand $Encoded"
    } else {
        $ProcInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $Encoded"
    }
    $ProcInfo.UseShellExecute = $false
    $Proc = [System.Diagnostics.Process]::Start($ProcInfo)
    Write-GuiLog "Tien trinh doc lap [PID: $($Proc.Id)] da tao..."

    $TimerState = New-Object PSObject -Property @{ Button = $Btn; OrigText = $OriginalText; OrigColor = $Btn.Tag; IsWpf = $IsWpfBtn; Timer = $null; Pid = $Proc.Id }
    $CheckTimer = New-Object System.Windows.Forms.Timer; $CheckTimer.Interval = 1000; $CheckTimer.Tag = $TimerState 
    $Global:Counter = 0
    $CheckTimer.Add_Tick({
        $State = $this.Tag; $Global:Counter++
        if ($Global:Counter -ge 3) {
            if ($State.IsWpf) { $State.Button.Content = $State.OrigText; $State.Button.Background = (New-Object System.Windows.Media.BrushConverter).ConvertFromString($State.OrigColor); $State.Button.IsEnabled = $true } 
            else { $State.Button.Text = $State.OrigText; $State.Button.BackColor = $State.OrigColor; $State.Button.Enabled = $true }
        }
        $ProcStatus = Get-Process -Id $State.Pid -ErrorAction SilentlyContinue
        if ($null -eq $ProcStatus) {
            Write-GuiLog "=> [PID: $($State.Pid)] Da dong va don rac!"
            $State.Timer.Stop(); $State.Timer.Dispose()
        }
    })
    $TimerState.Timer = $CheckTimer; $CheckTimer.Start()
}

# ==============================================================================
# GIAO DIỆN WPF
# ==============================================================================
$Global:IsWpfMode = $true 

function Load-WPF {
    try {
        Add-Type -AssemblyName PresentationFramework -ErrorAction Stop; Add-Type -AssemblyName PresentationCore; Add-Type -AssemblyName WindowsBase
        
        $JsonTabsXaml = ""
        if ($Global:JsonData) {
            $JsonTabs = $Global:JsonData | Select-Object -ExpandProperty tab -Unique
            foreach ($T in $JsonTabs) {
                $SafeHeader = [Security.SecurityElement]::Escape($T.ToUpper())
                $PanelName = "wpTab_" + ($T -replace '[^a-zA-Z0-9]', '')
                $JsonTabsXaml += @"
                    <TabItem Header=" $SafeHeader ">
                        <ScrollViewer VerticalScrollBarVisibility="Auto">
                            <WrapPanel Name="$PanelName" Margin="20"/>
                        </ScrollViewer>
                    </TabItem>
"@
            }
        }

        [xml]$WpfXaml = @"
<?xml version="1.0" encoding="utf-8"?>
        <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
                Title="PHAT TAN PC V20.13 TITANIUM | USER: $($Global:UserEmail)" 
                Height="850" Width="1100" WindowStartupLocation="CenterScreen" Background="#19191E" FontFamily="Segoe UI">
            <Window.Resources>
                <Style TargetType="Button">
                    <Setter Property="Width" Value="165"/>
                    <Setter Property="Height" Value="45"/>
                    <Setter Property="Margin" Value="5"/>
                    <Setter Property="BorderThickness" Value="0"/>
                    <Setter Property="Cursor" Value="Hand"/>
                    <Setter Property="FontWeight" Value="Bold"/>
                    <Setter Property="Foreground" Value="White"/>
                </Style>
                <Style TargetType="TabItem">
                    <Setter Property="Background" Value="#232328"/>
                    <Setter Property="Foreground" Value="White"/>
                    <Setter Property="FontSize" Value="14"/>
                    <Setter Property="FontWeight" Value="Bold"/>
                    <Setter Property="Padding" Value="10,5"/>
                </Style>
            </Window.Resources>
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="90"/> <RowDefinition Height="*"/> <RowDefinition Height="120"/> <RowDefinition Height="80"/> </Grid.RowDefinitions>
                
                <Grid Grid.Row="0" Background="#232328">
                    <TextBlock Text="PHAT TAN PC TOOLKIT" Foreground="DeepSkyBlue" FontSize="26" FontWeight="Bold" Margin="20,15,0,0"/>
                    <TextBlock Text="Enterprise Cloud Architecture - Async Multi-Thread Mode" Foreground="Lime" FontSize="13" FontStyle="Italic" Margin="25,55,0,0"/>
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,20,0">
                        <Button Name="BtnToggleUI" Content="🌐 DÙNG WINFORMS" Width="160" Height="35" Background="#8A2BE2" Foreground="White" FontWeight="Bold" BorderThickness="0" Cursor="Hand" Margin="0,0,15,0"/>
                        <Button Name="BtnProfileWpf" Content="👤 TRANG CÁ NHÂN" Width="150" Height="35" Background="DimGray" Foreground="White" FontWeight="Bold" BorderThickness="0" Cursor="Hand"/>
                    </StackPanel>
                </Grid>
                
                <TabControl Grid.Row="1" Background="#1E1E23" BorderThickness="0">
                    <TabItem Header=" DASHBOARD ">
                        <ScrollViewer VerticalScrollBarVisibility="Auto">
                            <StackPanel Margin="15">
                                <Border Background="#28282D" CornerRadius="8" Padding="15" Margin="0,0,0,15">
                                    <StackPanel>
                                        <TextBlock Text="⚙ HỆ THỐNG (SYSTEM)" Foreground="#00BEFF" FontSize="18" FontWeight="Bold" Margin="0,0,0,10"/>
                                        <WrapPanel Name="wpSystem"/>
                                    </StackPanel>
                                </Border>
                                <Border Background="#28282D" CornerRadius="8" Padding="15" Margin="0,0,0,15">
                                    <StackPanel>
                                        <TextBlock Text="🛡 BẢO MẬT (SECURITY)" Foreground="#8A2BE2" FontSize="18" FontWeight="Bold" Margin="0,0,0,10"/>
                                        <WrapPanel Name="wpSecurity"/>
                                    </StackPanel>
                                </Border>
                                <Border Background="#28282D" CornerRadius="8" Padding="15">
                                    <StackPanel>
                                        <TextBlock Text="💿 CÀI ĐẶT (INSTALL)" Foreground="#32E682" FontSize="18" FontWeight="Bold" Margin="0,0,0,10"/>
                                        <WrapPanel Name="wpInstall"/>
                                    </StackPanel>
                                </Border>
                            </StackPanel>
                        </ScrollViewer>
                    </TabItem>
                    
                    $JsonTabsXaml
                    
                </TabControl>
                
                <Border Grid.Row="2" Background="#0A0A0C" BorderBrush="#333" BorderThickness="0,1,0,0">
                    <TextBox Name="txtLog" Background="Transparent" Foreground="Lime" FontFamily="Consolas" FontSize="12" BorderThickness="0" IsReadOnly="True" VerticalScrollBarVisibility="Auto" Text="[+] TITAN ENGINE KERNEL INITIALIZED...&#x0a;"/>
                </Border>
                
                <Grid Grid.Row="3" Background="#232328">
                    <Button Name="BtnInstallAppsWpf" Content="📦 CÀI ĐẶT ỨNG DỤNG ĐÃ CHỌN" Width="300" Height="45" HorizontalAlignment="Left" Margin="20,0,0,0" Background="ForestGreen" Foreground="White" FontWeight="Bold" BorderThickness="0" Cursor="Hand"/>
                    <Button Name="BtnBuyKeyWpf" Content="💎 CỬA HÀNG VIP" Width="200" Height="45" HorizontalAlignment="Right" Margin="0,0,20,0" Background="Gold" Foreground="Black" FontWeight="Bold" BorderThickness="0" Cursor="Hand"/>
                </Grid>
            </Grid>
        </Window>
"@
        $Reader = (New-Object System.Xml.XmlNodeReader $WpfXaml); $WpfForm = [System.Windows.Markup.XamlReader]::Load($Reader)
        $Global:LogBox = $WpfForm.FindName("txtLog")
        
        function Add-WpfBtn ($PanelName, $Text, $Cmd, $ColorHex, $IsVip = $false) {
            $Btn = New-Object System.Windows.Controls.Button; $Btn.Content = $Text; $Btn.Width = 165; $Btn.Height = 45; $Btn.Margin = "5"; $Btn.BorderThickness = 0; $Btn.Cursor = [System.Windows.Input.Cursors]::Hand
            $Btn.FontWeight = [System.Windows.FontWeights]::Bold; $Btn.Foreground = [System.Windows.Media.Brushes]::White
            if ($IsVip -and $Global:LicenseType -in @("NONE", "FREE", "FREE_30M")) {
                $Btn.Background = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#505050"); $Btn.Foreground = [System.Windows.Media.Brushes]::Silver
                $Btn.Add_Click({ [System.Windows.Forms.MessageBox]::Show("Tính năng này yêu cầu VIP!", "KHÓA", 0, 16) })
            } else {
                $Btn.Background = (New-Object System.Windows.Media.BrushConverter).ConvertFromString($ColorHex); $Btn.Tag = $ColorHex
                if ($Cmd -eq "DISK_GENIUS") { $Btn.Add_Click({ Write-GuiLog "Tai Cuu du lieu..."; Tai-Va-Chay "Disk.Genius.rar" "DiskGenius.rar" "Portable" }) }
                else { $action = [scriptblock]::Create("Run-ModuleAsync `$this `"$Cmd`" `$true"); $Btn.Add_Click($action) }
            }
            $WpfForm.FindName($PanelName).Children.Add($Btn)
        }

        Add-WpfBtn "wpSystem" "ℹ CẤU HÌNH" "SystemInfo.ps1" "#00BEFF"
        Add-WpfBtn "wpSystem" "♻ DỌN RÁC" "SystemCleaner.ps1" "#00BEFF"
        Add-WpfBtn "wpSystem" "💾 QUẢN LÝ ĐĨA" "DiskManager.ps1" "#00BEFF"
        Add-WpfBtn "wpSystem" "🔍 QUÉT WINDOWS" "SystemScan.ps1" "#00BEFF"
        Add-WpfBtn "wpSystem" "⚡ TỐI ƯU RAM" "RamBooster.ps1" "#00BEFF"
        Add-WpfBtn "wpSystem" "🗝 KÍCH HOẠT" "WinActivator.ps1" "#00BEFF"
        Add-WpfBtn "wpSystem" "🚑 CỨU DỮ LIỆU" "DISK_GENIUS" "#00BEFF" $true
        Add-WpfBtn "wpSystem" "🔧 SỬA LỖI HT" "SystemRepair.ps1" "#00BEFF"
        Add-WpfBtn "wpSystem" "🔎 QUÉT TẬP TIN" "scanfile.ps1" "#00BEFF"
        Add-WpfBtn "wpSystem" "🖱 MENU CHUỘT PHẢI" "ContextMenuManager.ps1" "#00BEFF"
        Add-WpfBtn "wpSystem" "🖨 FIX MÁY IN" "fixprinter_errors.ps1" "#00BEFF"
        
        Add-WpfBtn "wpSecurity" "🌐 ĐỔI DNS" "NetworkMaster.ps1" "#8A2BE2"
        Add-WpfBtn "wpSecurity" "↻ QUẢN UPDATE" "WinUpdatePro.ps1" "#8A2BE2"
        Add-WpfBtn "wpSecurity" "🛡 DEFENDER ON/OFF" "DefenderMgr.ps1" "#8A2BE2"
        Add-WpfBtn "wpSecurity" "🛡 VÔ HIỆU EFSs" "AntiEFS_GUI.ps1" "#8A2BE2" $true
        Add-WpfBtn "wpSecurity" "🔒 KHÓA BITLOCKER" "BitLockerMgr.ps1" "#8A2BE2" $true
        Add-WpfBtn "wpSecurity" "⛔ CHẶN LỊCH SỬ WEB" "BrowserPrivacy.ps1" "#8A2BE2"
        
        Add-WpfBtn "wpInstall" "💿 CÀI WIN AUTO" "WinInstall.ps1" "#32E682" $true
        Add-WpfBtn "wpInstall" "📝 CÀI OFFICE 365" "OfficeInstaller.ps1" "#32E682" $true
        Add-WpfBtn "wpInstall" "🔧 TỐI ƯU WIN" "WinModder.ps1" "#32E682"
        Add-WpfBtn "wpInstall" "📦 ĐÓNG GÓI ISO" "WinAIOBuilder.ps1" "#32E682" $true
        Add-WpfBtn "wpInstall" "🤖 TRỢ LÝ AI" "GeminiAI.ps1" "#32E682"
        Add-WpfBtn "wpInstall" "👜 CÀI STORE" "AppStore.ps1" "#32E682"
        Add-WpfBtn "wpInstall" "📥 TẢI ISO GỐC" "ISODownloader.ps1" "#32E682"
        Add-WpfBtn "wpInstall" "⚡ TẠO USB BOOT" "UsbBootMaker.ps1" "#32E682"
        Add-WpfBtn "wpInstall" "🍏 JAILBREAK iOS" "iOS_Jailbreak.ps1" "#32E682" $true
        Add-WpfBtn "wpInstall" "🖧 CÀI DRIVER" "AutoDriver.ps1" "#32E682"

        $Global:WpfAppCheckBoxes = @()
        if ($Global:JsonData) {
            foreach ($App in $Global:JsonData) {
                $PanelName = "wpTab_" + ($App.tab -replace '[^a-zA-Z0-9]', '')
                $WrapPanel = $WpfForm.FindName($PanelName)
                if ($WrapPanel) {
                    $Chk = New-Object System.Windows.Controls.CheckBox
                    $Chk.Content = $App.name
                    $Chk.Tag = $App
                    $Chk.Margin = "10"
                    $Chk.FontSize = 14
                    $Chk.Foreground = [System.Windows.Media.Brushes]::White
                    $WrapPanel.Children.Add($Chk)
                    $Global:WpfAppCheckBoxes += $Chk
                }
            }
        }

        $WpfForm.FindName("BtnInstallAppsWpf").Add_Click({
            $ListToInstall = @()
            foreach ($Chk in $Global:WpfAppCheckBoxes) { if ($Chk.IsChecked) { $ListToInstall += $Chk.Tag; $Chk.IsChecked = $false } }
            if ($ListToInstall.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Vui lòng chọn ít nhất 1 phần mềm để cài!"); return }
            
            Write-GuiLog "Bắt đầu tải và cài đặt $($ListToInstall.Count) ứng dụng ngầm..."
            $SyncHash_Wpf = [hashtable]::Synchronized(@{ Queue=$ListToInstall; BaseUrl=$BaseUrl; TempDir=$TempDir; Log=$Global:LogBox })
            $Runspace_Wpf = [runspacefactory]::CreateRunspace(); $Runspace_Wpf.Open(); $Runspace_Wpf.SessionStateProxy.SetVariable("sync", $SyncHash_Wpf)
            $Pipe_Wpf = $Runspace_Wpf.CreatePipeline()
            $Pipe_Wpf.Commands.AddScript({
                foreach ($A in $sync.Queue) {
                    $Line = "[$([DateTime]::Now.ToString('HH:mm:ss'))] [INSTALL] Dang tai: $($A.name)`r`n"
                    $sync.Log.Dispatcher.Invoke({ $sync.Log.AppendText($Line); $sync.Log.ScrollToEnd() })
                    $OutFile = "$($sync.TempDir)\$($A.name).exe"
                    $Url = if ($A.link -match "^http") { $A.link } else { "$($sync.BaseUrl)$($A.link)" }
                    try { (New-Object System.Net.WebClient).DownloadFile($Url, $OutFile) } catch {}
                    if (Test-Path $OutFile) { Start-Process $OutFile -Wait }
                }
                $sync.Log.Dispatcher.Invoke({ $sync.Log.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] [INSTALL] HOAN TAT CAI DAT TAT CA APP!`r`n"); $sync.Log.ScrollToEnd() })
            }) | Out-Null; $Pipe_Wpf.InvokeAsync()
        })

        $WpfForm.FindName("BtnBuyKeyWpf").Add_Click({ Show-Store })
        $WpfForm.FindName("BtnToggleUI").Add_Click({ $Global:IsWpfMode = $false; $WpfForm.Close() })
        $WpfForm.FindName("BtnProfileWpf").Add_Click({ Show-ProfileForm })

        $WpfForm.ShowDialog() | Out-Null; return $true
    } catch { Write-Host "DEBUG: Loi WPF: $($_.Exception.Message)" -ForegroundColor Red; return $false }
}

# ==============================================================================
# GIAO DIỆN WINFORMS
# ==============================================================================
function Load-WinForms {
    $Form = New-Object System.Windows.Forms.Form; $Form.Text = "PHAT TAN PC V20.13 TITANIUM | WINFORMS MODE"; $Form.Size = "1100, 850"; $Form.StartPosition = "CenterScreen"; $Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 35); $Form.ForeColor = "White"
    $PnlHeader = New-Object System.Windows.Forms.Panel; $PnlHeader.Size="1100, 80"; $PnlHeader.Location="0,0"; $PnlHeader.BackColor = [System.Drawing.Color]::FromArgb(35,35,40); $Form.Controls.Add($PnlHeader)
    $LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text="PHAT TAN PC TOOLKIT"; $LblTitle.Font=$FontTitle; $LblTitle.AutoSize=$true; $LblTitle.Location="20,15"; $LblTitle.ForeColor=[System.Drawing.Color]::DeepSkyBlue; $PnlHeader.Controls.Add($LblTitle)
    
    $BtnProfile = New-Object System.Windows.Forms.Button; $BtnProfile.Location="750, 25"; $BtnProfile.Size="140, 35"; $BtnProfile.FlatStyle="Flat"; $BtnProfile.Font=$FontBtnSmall; $BtnProfile.Cursor="Hand"; $BtnProfile.Text="👤 TRANG CÁ NHÂN"; $BtnProfile.BackColor="DimGray"; $BtnProfile.ForeColor="White"
    $BtnProfile.Add_Click({ Show-ProfileForm })
    $PnlHeader.Controls.Add($BtnProfile)

    $BtnToggleUI = New-Object System.Windows.Forms.Button; $BtnToggleUI.Location="570, 25"; $BtnToggleUI.Size="160, 35"; $BtnToggleUI.FlatStyle="Flat"; $BtnToggleUI.Font=$FontBtnSmall; $BtnToggleUI.Cursor="Hand"; $BtnToggleUI.Text="✨ DÙNG GIAO DIỆN WPF"; $BtnToggleUI.BackColor=[System.Drawing.Color]::BlueViolet; $BtnToggleUI.ForeColor="White"
    $BtnToggleUI.Add_Click({ $Global:IsWpfMode = $true; $Form.Close() })
    $PnlHeader.Controls.Add($BtnToggleUI)

    $TabControl = New-Object System.Windows.Forms.TabControl; $TabControl.Location="10,90"; $TabControl.Size="1060,450"; $TabControl.Font=$FontText; $Form.Controls.Add($TabControl)
    
    $AdvTab = New-Object System.Windows.Forms.TabPage; $AdvTab.Text=" DASHBOARD "; $AdvTab.BackColor=[System.Drawing.Color]::FromArgb(30, 30, 35); $TabControl.Controls.Add($AdvTab)
    $MainFlow = New-Object System.Windows.Forms.FlowLayoutPanel; $MainFlow.Dock="Fill"; $MainFlow.AutoScroll=$true; $AdvTab.Controls.Add($MainFlow)

    function Add-HozWinGroup ($Title, $Color) {
        $Pnl = New-Object System.Windows.Forms.Panel; $Pnl.Size="1020, 160"; $Pnl.Margin="0,0,0,15"; $Pnl.BackColor=[System.Drawing.Color]::FromArgb(40,40,45)
        $Lbl = New-Object System.Windows.Forms.Label; $Lbl.Text=$Title; $Lbl.ForeColor=$Color; $Lbl.Font=$FontHeader; $Lbl.Location="15,10"; $Lbl.AutoSize=$true; $Pnl.Controls.Add($Lbl)
        $Wrap = New-Object System.Windows.Forms.FlowLayoutPanel; $Wrap.Location="15, 45"; $Wrap.Size="990, 105"; $Pnl.Controls.Add($Wrap)
        $MainFlow.Controls.Add($Pnl); return $Wrap
    }
    
    function Add-WinBtn ($Wrap, $Text, $Cmd, $Color, $IsVip=$false) { 
        $B = New-Object System.Windows.Forms.Button; $B.Text=$Text; $B.Size="150,45"; $B.FlatStyle="Flat"; $B.Font=$FontBtnSmall; $B.Margin="5"; $B.Tag = $Color
        if ($IsVip -and $Global:LicenseType -in @("NONE", "FREE", "FREE_30M")) {
            $B.ForeColor="Silver"; $B.BackColor=[System.Drawing.Color]::FromArgb(80,80,80); $B.Add_Click({ [System.Windows.Forms.MessageBox]::Show("Cần VIP!") })
        } else {
            $B.BackColor=$Color; $B.ForeColor="White"
            if ($Cmd -eq "DISK_GENIUS") { $B.Add_Click({ Write-GuiLog "Tải Cứu dữ liệu..."; Tai-Va-Chay "Disk.Genius.rar" "DiskGenius.rar" "Portable" }) }
            else { 
                $Action = [scriptblock]::Create("Run-ModuleAsync `$this `"$Cmd`" `$false")
                $B.Add_Click($Action)
            }
        }
        $Wrap.Controls.Add($B)
    }

    $GrpSys = Add-HozWinGroup "⚙ HỆ THỐNG" [System.Drawing.Color]::DeepSkyBlue
    @("ℹ CẤU HÌNH|SystemInfo.ps1", "♻ DỌN RÁC|SystemCleaner.ps1", "💾 QUẢN LÝ ĐĨA|DiskManager.ps1", "🔍 QUÉT WIN|SystemScan.ps1", "⚡ TỐI ƯU RAM|RamBooster.ps1", "🗝 KÍCH HOẠT|WinActivator.ps1", "🔧 SỬA LỖI HT|SystemRepair.ps1", "🔎 QUÉT TẬP TIN|scanfile.ps1", "🖱 MENU CHUỘT PHẢI|ContextMenuManager.ps1", "🖨 FIX MÁY IN|fixprinter_errors.ps1") | % {
        $d=$_ -split '\|'; Add-WinBtn $GrpSys $d[0] $d[1] [System.Drawing.Color]::DeepSkyBlue
    }
    Add-WinBtn $GrpSys "🚑 CỨU DỮ LIỆU" "DISK_GENIUS" [System.Drawing.Color]::DeepSkyBlue $true

    $GrpSec = Add-HozWinGroup "🛡 BẢO MẬT" [System.Drawing.Color]::BlueViolet
    @("🌐 ĐỔI DNS|NetworkMaster.ps1", "↻ QUẢN UPDATE|WinUpdatePro.ps1", "🛡 DEFENDER|DefenderMgr.ps1", "⛔ CHẶN LỊCH SỬ WEB|BrowserPrivacy.ps1") | % {
        $d=$_ -split '\|'; Add-WinBtn $GrpSec $d[0] $d[1] [System.Drawing.Color]::BlueViolet
    }
    Add-WinBtn $GrpSec "🛡 VÔ HIỆU EFSs" "AntiEFS_GUI.ps1" [System.Drawing.Color]::BlueViolet $true
    Add-WinBtn $GrpSec "🔒 KHÓA BITLOCKER" "BitLockerMgr.ps1" [System.Drawing.Color]::BlueViolet $true

    $GrpIns = Add-HozWinGroup "💿 CÀI ĐẶT" [System.Drawing.Color]::MediumSeaGreen
    @("🔧 TỐI ƯU WIN|WinModder.ps1", "🤖 TRỢ LÝ AI|GeminiAI.ps1", "👜 CÀI STORE|AppStore.ps1", "📥 TẢI ISO|ISODownloader.ps1", "⚡ TẠO USB|UsbBootMaker.ps1", "🖧 CÀI DRIVER|AutoDriver.ps1") | % {
        $d=$_ -split '\|'; Add-WinBtn $GrpIns $d[0] $d[1] [System.Drawing.Color]::MediumSeaGreen
    }
    Add-WinBtn $GrpIns "💿 CÀI WIN AUTO" "WinInstall.ps1" [System.Drawing.Color]::MediumSeaGreen $true
    Add-WinBtn $GrpIns "📝 CÀI OFFICE 365" "OfficeInstaller.ps1" [System.Drawing.Color]::MediumSeaGreen $true
    Add-WinBtn $GrpIns "📦 ĐÓNG GÓI ISO" "WinAIOBuilder.ps1" [System.Drawing.Color]::MediumSeaGreen $true
    Add-WinBtn $GrpIns "🍏 JAILBREAK iOS" "iOS_Jailbreak.ps1" [System.Drawing.Color]::MediumSeaGreen $true

    if ($Global:JsonData) {
        $JsonTabs = $Global:JsonData | Select-Object -ExpandProperty tab -Unique
        foreach ($T in $JsonTabs) {
            $Page = New-Object System.Windows.Forms.TabPage; $Page.Text=" " + $T.ToUpper() + " "; $Page.BackColor=[System.Drawing.Color]::FromArgb(30, 30, 35); $TabControl.Controls.Add($Page)
            $Flow = New-Object System.Windows.Forms.FlowLayoutPanel; $Flow.Dock="Fill"; $Flow.AutoScroll=$true; $Flow.Padding="20,20,20,20"; $Page.Controls.Add($Flow)
            $Apps = $Global:JsonData | Where-Object {$_.tab -eq $T}
            foreach ($A in $Apps) { $Chk = New-Object System.Windows.Forms.CheckBox; $Chk.Text=$A.name; $Chk.Tag=$A; $Chk.AutoSize=$true; $Chk.Margin="10,10,20,10"; $Chk.Font=$FontText; $Chk.ForeColor="White"; $Flow.Controls.Add($Chk) }
        }
    }

    $Global:LogBox = New-Object System.Windows.Forms.TextBox
    $Global:LogBox.Location="10, 560"; $Global:LogBox.Size="1060, 150"; $Global:LogBox.Multiline=$true; $Global:LogBox.ReadOnly=$true; $Global:LogBox.BackColor=[System.Drawing.Color]::Black; $Global:LogBox.ForeColor=[System.Drawing.Color]::Lime; $Global:LogBox.Font=$FontConsole; $Form.Controls.Add($Global:LogBox)

    $BtnInstallApps = New-Object System.Windows.Forms.Button; $BtnInstallApps.Text="📦 CÀI ĐẶT ỨNG DỤNG ĐÃ CHỌN"; $BtnInstallApps.Location="10, 730"; $BtnInstallApps.Size="300,45"; $BtnInstallApps.BackColor="ForestGreen"; $BtnInstallApps.ForeColor="White"; $BtnInstallApps.FlatStyle="Flat"; $BtnInstallApps.Font=$FontBtn; 
    $BtnInstallApps.Add_Click({
        $ListToInstall = @()
        foreach ($Page in $TabControl.TabPages) { if ($Page.Text -notmatch "DASHBOARD") { foreach ($Flow in $Page.Controls) { foreach ($Chk in $Flow.Controls) { if ($Chk -is [System.Windows.Forms.CheckBox] -and $Chk.Checked) { $ListToInstall += $Chk.Tag; $Chk.Checked = $false } } } } }
        if ($ListToInstall.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Vui lòng chọn ít nhất 1 phần mềm!"); return }
        
        Write-GuiLog "Bắt đầu tải và cài đặt $($ListToInstall.Count) ứng dụng ngầm..."
        $SyncHash_Win = [hashtable]::Synchronized(@{ Queue=$ListToInstall; BaseUrl=$BaseUrl; TempDir=$TempDir; Log=$Global:LogBox })
        $Runspace_Win = [runspacefactory]::CreateRunspace(); $Runspace_Win.Open(); $Runspace_Win.SessionStateProxy.SetVariable("sync", $SyncHash_Win)
        $Pipe_Win = $Runspace_Win.CreatePipeline()
        $Pipe_Win.Commands.AddScript({
            foreach ($A in $sync.Queue) {
                $Line = "[$([DateTime]::Now.ToString('HH:mm:ss'))] [INSTALL] Dang tai: $($A.name)`r`n"
                $sync.Log.Invoke([action]{ $sync.Log.AppendText($Line); $sync.Log.ScrollToCaret() })
                $OutFile = "$($sync.TempDir)\$($A.name).exe"
                $Url = if ($A.link -match "^http") { $A.link } else { "$($sync.BaseUrl)$($A.link)" }
                try { (New-Object System.Net.WebClient).DownloadFile($Url, $OutFile) } catch {}
                if (Test-Path $OutFile) { Start-Process $OutFile -Wait }
            }
            $sync.Log.Invoke([action]{ $sync.Log.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] [INSTALL] HOAN TAT CAI DAT TAT CA APP!`r`n"); $sync.Log.ScrollToCaret() })
        }) | Out-Null; $Pipe_Win.InvokeAsync()
    })
    $Form.Controls.Add($BtnInstallApps)

    $BtnBuyKey = New-Object System.Windows.Forms.Button; $BtnBuyKey.Text="💎 CỬA HÀNG VIP"; $BtnBuyKey.Location="870, 730"; $BtnBuyKey.Size="200,45"; $BtnBuyKey.BackColor="Gold"; $BtnBuyKey.ForeColor="Black"; $BtnBuyKey.FlatStyle="Flat"; $BtnBuyKey.Font=$FontBtn; $BtnBuyKey.Add_Click({ Show-Store }); $Form.Controls.Add($BtnBuyKey)

    $Form.ShowDialog() | Out-Null; $Form.Dispose()
}

Write-Host "[TITAN-CORE] Bắt đầu nạp giao diện chính..." -ForegroundColor Yellow
while ($true) {
    if ($Global:IsWpfMode) { 
        if (-not (Load-WPF)) { Write-Host "[TITAN-CORE] Fallback sang WinForms" -ForegroundColor Cyan; $Global:IsWpfMode = $false } 
    } else { Load-WinForms }
    if ([System.Windows.Forms.Application]::OpenForms.Count -eq 0) { break }
}

Write-Host "[TITAN-CORE] Đã đóng Form, dọn dẹp hệ thống..." -ForegroundColor Green
[System.GC]::Collect()
Stop-Process -Id $PID -Force
