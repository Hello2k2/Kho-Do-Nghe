<#
    TOOL CUU HO MAY TINH - PHAT TAN PC
    Version: 20.6 ENTERPRISE (Full Features, Horizontal Flow, Live Log Console, 100% Async)
#>

if ($host.Name -match "ISE") { Exit }
if ($MyInvocation.MyCommand.Path) { Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show("Truy cập trái phép! Vui lòng dùng lệnh tải từ Server.", "BẢO VỆ", 0, 16); Exit }
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://script.phattan.id.vn/tool/install.ps1 | iex`"" -Verb RunAs; Exit }

Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; $ErrorActionPreference = "SilentlyContinue"
[System.Net.ServicePointManager]::Expect100Continue = $true; [System.Net.ServicePointManager]::SecurityProtocol = 3072 -bor 12288; [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

function Get-HWID {
    $C = (Get-WmiObject Win32_Processor).ProcessorId; $B = (Get-WmiObject Win32_BaseBoard).SerialNumber; if (!$C) { $C = "VM" }; if (!$B) { $B = "VM" }
    $MD = [System.Security.Cryptography.MD5]::Create(); return ([System.BitConverter]::ToString($MD.ComputeHash([System.Text.Encoding]::UTF8.GetBytes("$C-$B"))) -replace "-", "").Substring(0, 16)
}
$Global:MyHWID = Get-HWID; $Global:PCName = $env:COMPUTERNAME

$encApi = "aHR0cHM6Ly9hcGkucGhhdHRhbi5pZC52bi9hcGkucGhw"; $Global:ApiServer = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encApi))
$encBaseUrl = "aHR0cHM6Ly9naXRodWIuY29tL0hlbGxvMmsyL0toby1Eby1OZ2hlL3JlbGVhc2VzL2Rvd25sb2FkL3YxLjAv"; $BaseUrl = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encBaseUrl))
$encRawUrl = "aHR0cHM6Ly9zY3JpcHQucGhhdHRhbi5pZC52bi90b29sLw=="; $RawUrl = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encRawUrl))
$encJsonUrl = "aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL0hlbGxvMmsyL0toby1Eby1OZ2hlL21haW4vYXBwcy5qc29u"; $JsonUrl = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encJsonUrl))

$TempDir = "$env:TEMP\PhatTan_Tool"; $LogFile = "$TempDir\PhatTan_Toolkit.log"; if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }

$Global:SessionFile = "$env:LOCALAPPDATA\PhatTan_Titan.dat"
$Global:AvatarFile = "$env:LOCALAPPDATA\PhatTan_Avatar.png"
$Global:IsAuthenticated = $false; $Global:LicenseType = "NONE"; $Global:UserEmail = ""; $Global:LocalPass = "root"; $Global:ServerPass = "root"
$Global:LogBox = $null

# --- HÀM GHI LOG VÀO GIAO DIỆN (UI) ---
function Write-GuiLog ($Msg) {
    $Time = Get-Date -Format "HH:mm:ss"
    $FullMsg = "[$Time] $Msg`n"
    if ($Global:IsWpfMode -and $Global:LogBox) {
        $Global:LogBox.Dispatcher.Invoke({ $Global:LogBox.AppendText($FullMsg); $Global:LogBox.ScrollToEnd() })
    } elseif (-not $Global:IsWpfMode -and $Global:LogBox) {
        $Global:LogBox.AppendText($FullMsg); $Global:LogBox.ScrollToCaret()
    }
}

# --- CORE FUNCTIONS (API, AUTH, SESSION) ---
function Show-OtpInput ($Title, $Msg, $Link) {
    $OForm = New-Object System.Windows.Forms.Form; $OForm.Text = $Title; $OForm.Size = "400, 240"; $OForm.StartPosition = "CenterParent"; $OForm.FormBorderStyle = "FixedToolWindow"; $OForm.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 25); $OForm.ForeColor = "White"
    $LblMsg = New-Object System.Windows.Forms.Label; $LblMsg.Text = $Msg; $LblMsg.Location = "20, 15"; $LblMsg.Size = "340, 45"; $LblMsg.Font = "Segoe UI, 10"; $OForm.Controls.Add($LblMsg)
    $TxtOtp = New-Object System.Windows.Forms.TextBox; $TxtOtp.Location = "20, 65"; $TxtOtp.Size = "340, 30"; $TxtOtp.Font = "Segoe UI, 14, Bold"; $TxtOtp.TextAlign = "Center"; $OForm.Controls.Add($TxtOtp)
    $LnkWeb = New-Object System.Windows.Forms.LinkLabel; $LnkWeb.Text = "⚠️ Không nhận được mã? Bấm vào đây để lấy trực tiếp!"; $LnkWeb.Location = "20, 110"; $LnkWeb.Size = "340, 20"; $LnkWeb.Font = "Segoe UI, 9, Italic"; $LnkWeb.LinkColor = "DeepSkyBlue"; $LnkWeb.ActiveLinkColor = "Red"; $LnkWeb.Cursor = "Hand"; $LnkWeb.Add_Click({ if($Link){ Start-Process $Link } }); if ([string]::IsNullOrEmpty($Link)) { $LnkWeb.Visible = $false }; $OForm.Controls.Add($LnkWeb)
    $BtnOk = New-Object System.Windows.Forms.Button; $BtnOk.Text = "XÁC NHẬN"; $BtnOk.Location = "20, 145"; $BtnOk.Size = "340, 40"; $BtnOk.BackColor = "ForestGreen"; $BtnOk.ForeColor = "White"; $BtnOk.Font = "Segoe UI, 11, Bold"; $BtnOk.FlatStyle = "Flat"; $BtnOk.DialogResult = "OK"; $OForm.Controls.Add($BtnOk)
    $OForm.AcceptButton = $BtnOk; $OForm.ShowDialog() | Out-Null; $Res = if ($OForm.DialogResult -eq "OK") { $TxtOtp.Text.Trim() } else { $null }; $OForm.Dispose(); return $Res
}
function Show-Level2Pass ($TitleMsg) {
    $OForm = New-Object System.Windows.Forms.Form; $OForm.Text = "BẢO MẬT CỤC BỘ"; $OForm.Size = "400, 200"; $OForm.StartPosition = "CenterScreen"; $OForm.FormBorderStyle = "FixedToolWindow"; $OForm.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 25); $OForm.ForeColor = "White"
    $LblMsg = New-Object System.Windows.Forms.Label; $LblMsg.Text = $TitleMsg; $LblMsg.Location = "20, 20"; $LblMsg.Size = "340, 25"; $LblMsg.Font = "Segoe UI, 10"; $OForm.Controls.Add($LblMsg)
    $TxtPass = New-Object System.Windows.Forms.TextBox; $TxtPass.Location = "20, 55"; $TxtPass.Size = "340, 30"; $TxtPass.Font = "Segoe UI, 14, Bold"; $TxtPass.PasswordChar = "*"; $TxtPass.TextAlign = "Center"; $OForm.Controls.Add($TxtPass)
    $BtnOk = New-Object System.Windows.Forms.Button; $BtnOk.Text = "MỞ KHÓA TOOL"; $BtnOk.Location = "20, 100"; $BtnOk.Size = "340, 40"; $BtnOk.BackColor = "OrangeRed"; $BtnOk.ForeColor = "White"; $BtnOk.Font = "Segoe UI, 11, Bold"; $BtnOk.FlatStyle = "Flat"; $BtnOk.DialogResult = "OK"; $OForm.Controls.Add($BtnOk)
    $OForm.AcceptButton = $BtnOk; $OForm.ShowDialog() | Out-Null; $Res = if ($OForm.DialogResult -eq "OK") { $TxtPass.Text.Trim() } else { "" }; $OForm.Dispose(); return $Res
}
function Show-QRPay ($Amount, $Prefix, $Email, $TitleMsg) {
    $SafeEmail = $Email -replace "\s", ""; $Content = "$Prefix $SafeEmail"; $UrlContent = [uri]::EscapeDataString($Content)
    $QrUrl = "https://img.vietqr.io/image/970436-1055835227-qr_only.png?accountName=DANG%20LAM%20TAN%20PHAT&addInfo=$UrlContent"; if ($Amount -gt 0) { $QrUrl += "&amount=$Amount" }
    $Q = New-Object System.Windows.Forms.Form; $Q.Size = "750, 480"; $Q.StartPosition = "CenterScreen"; $Q.Text = "TITAN SECURE PAY - $TitleMsg"; $Q.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 250); $Q.FormBorderStyle = "FixedToolWindow"
    $LblTop = New-Object System.Windows.Forms.Label; $LblTop.Text = "CỔNG THANH TOÁN TỰ ĐỘNG"; $LblTop.Dock = "Top"; $LblTop.TextAlign = "MiddleCenter"; $LblTop.Font = "Segoe UI, 16, Bold"; $LblTop.ForeColor = [System.Drawing.Color]::White; $LblTop.BackColor = [System.Drawing.Color]::FromArgb(0, 102, 204); $LblTop.Height = 60; $Q.Controls.Add($LblTop)
    $PnlQR = New-Object System.Windows.Forms.Panel; $PnlQR.Location = "20, 80"; $PnlQR.Size = "320, 320"; $PnlQR.BackColor = [System.Drawing.Color]::White; $PnlQR.BorderStyle = "FixedSingle"; $Q.Controls.Add($PnlQR)
    $Pic = New-Object System.Windows.Forms.PictureBox; $Pic.Location = "10,10"; $Pic.Size = "300, 300"; $Pic.SizeMode = "Zoom"; try { $Pic.Load($QrUrl) } catch { }; $PnlQR.Controls.Add($Pic)
    $PnlInfo = New-Object System.Windows.Forms.Panel; $PnlInfo.Location = "360, 80"; $PnlInfo.Size = "350, 320"; $PnlInfo.BackColor = [System.Drawing.Color]::White; $PnlInfo.BorderStyle = "FixedSingle"; $Q.Controls.Add($PnlInfo)
    $BankName = New-Object System.Windows.Forms.Label; $BankName.Text = "VIETCOMBANK"; $BankName.Location = "20,20"; $BankName.AutoSize=$true; $BankName.Font = "Segoe UI, 15, Bold"; $BankName.ForeColor=[System.Drawing.Color]::Green; $PnlInfo.Controls.Add($BankName)
    $L2 = New-Object System.Windows.Forms.Label; $L2.Text = "Số tài khoản: 1055835227"; $L2.Location = "20, 70"; $L2.AutoSize=$true; $L2.Font = "Segoe UI, 12, Bold"; $PnlInfo.Controls.Add($L2)
    $L3 = New-Object System.Windows.Forms.Label; $L3.Text = "Số tiền: " + (if($Amount -gt 0){"{0:N0} VNĐ" -f $Amount}else{"TÙY TÂM"}); $L3.Location = "20, 110"; $L3.AutoSize=$true; $L3.Font = "Segoe UI, 14, Bold"; $L3.ForeColor="Red"; $PnlInfo.Controls.Add($L3)
    $L4 = New-Object System.Windows.Forms.Label; $L4.Text = "Nội dung: $Content"; $L4.Location = "20, 160"; $L4.AutoSize=$true; $L4.Font = "Segoe UI, 11, Bold"; $L4.ForeColor="Blue"; $PnlInfo.Controls.Add($L4)
    $Warn = New-Object System.Windows.Forms.Label; $Warn.Text = "⚠️ Vui lòng ghi ĐÚNG NỘI DUNG để Server tự duyệt."; $Warn.Location = "20, 250"; $Warn.Size="300,40"; $Warn.Font = "Segoe UI, 10"; $Warn.ForeColor="OrangeRed"; $PnlInfo.Controls.Add($Warn)
    $Q.ShowDialog() | Out-Null
}
function Show-Store {
    $S = New-Object System.Windows.Forms.Form; $S.Size="450, 400"; $S.StartPosition="CenterParent"; $S.Text="NÂNG CẤP GÓI VIP"; $S.BackColor=[System.Drawing.Color]::FromArgb(20,20,25); $S.FormBorderStyle="FixedToolWindow"
    $L = New-Object System.Windows.Forms.Label; $L.Text="🛒 CHỌN GÓI CƯỚC"; $L.Font="Segoe UI, 16, Bold"; $L.ForeColor="White"; $L.Location="110,15"; $L.AutoSize=$true; $S.Controls.Add($L)
    $BTrial = New-Object System.Windows.Forms.Button; $BTrial.Text="🎁 LẤY / GIA HẠN KEY 7 NGÀY (Cần Donate)"; $BTrial.Location="20,60"; $BTrial.Size="390,40"; $BTrial.BackColor="DarkMagenta"; $BTrial.ForeColor="White"; $BTrial.FlatStyle="Flat"; $S.Controls.Add($BTrial)
    $BTrial.Add_Click({ $E = Show-Level2Pass "Nhập Email của bạn:"; if ($E) { $S.Cursor="WaitCursor"; $R = Call-API "request_trial" @{ email=$E }; [System.Windows.Forms.MessageBox]::Show($R.message, "Thông báo"); $S.Cursor="Default" } })
    $B1M = New-Object System.Windows.Forms.Button; $B1M.Text="🥉 VIP 1 THÁNG (29.000đ)"; $B1M.Location="20,110"; $B1M.Size="190,50"; $B1M.BackColor="MediumSeaGreen"; $B1M.ForeColor="White"; $B1M.FlatStyle="Flat"; $S.Controls.Add($B1M)
    $B1M.Add_Click({ $E = Show-Level2Pass "Nhập Email nâng cấp VIP 1 THÁNG:"; if ($E) { Show-QRPay 29000 "MUA KEY 1M" $E "VIP 1 THÁNG" } })
    $B6M = New-Object System.Windows.Forms.Button; $B6M.Text="🥈 VIP 6 THÁNG (149.000đ)"; $B6M.Location="220,110"; $B6M.Size="190,50"; $B6M.BackColor="DodgerBlue"; $B6M.ForeColor="White"; $B6M.FlatStyle="Flat"; $S.Controls.Add($B6M)
    $B6M.Add_Click({ $E = Show-Level2Pass "Nhập Email nâng cấp VIP 6 THÁNG:"; if ($E) { Show-QRPay 149000 "MUA KEY 6M" $E "VIP 6 THÁNG" } })
    $BFull = New-Object System.Windows.Forms.Button; $BFull.Text="💎 VIP VĨNH VIỄN (200.000đ)"; $BFull.Location="20,170"; $BFull.Size="190,50"; $BFull.BackColor="Gold"; $BFull.ForeColor="Black"; $BFull.FlatStyle="Flat"; $S.Controls.Add($BFull)
    $BFull.Add_Click({ $E = Show-Level2Pass "Nhập Email nâng cấp VIP VĨNH VIỄN:"; if ($E) { Show-QRPay 200000 "MUA KEY VIP" $E "VIP VĨNH VIỄN" } })
    $BFam = New-Object System.Windows.Forms.Button; $BFam.Text="👑 ĐẠI LÝ (800.000đ - 25 PC)"; $BFam.Location="220,170"; $BFam.Size="190,50"; $BFam.BackColor="DarkOrange"; $BFam.ForeColor="Black"; $BFam.FlatStyle="Flat"; $S.Controls.Add($BFam)
    $BFam.Add_Click({ $E = Show-Level2Pass "Nhập Email nâng cấp GÓI ĐẠI LÝ:"; if ($E) { Show-QRPay 800000 "MUA KEY MULTI" $E "GÓI ĐẠI LÝ" } })
    $S.ShowDialog() | Out-Null
}
function Call-API ($Action, $Payload) { try { $Payload.Add("action", $Action); $JsonString = $Payload | ConvertTo-Json -Compress; $Utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($JsonString); return Invoke-RestMethod -Uri $Global:ApiServer -Method Post -Body $Utf8Bytes -ContentType "application/json; charset=utf-8" -TimeoutSec 15 } catch { return @{ status="error"; message="Mất kết nối Máy chủ!" } } }
function Save-Session ($E, $T, $H, $LP, $SP) { $R = "$E|PT|$T|PC|$H|LP|$LP|SP|$SP"; $B = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($R)); $Reversed = [string]::join('', ($B.ToCharArray()[($B.Length - 1)..0])); [System.IO.File]::WriteAllText($Global:SessionFile, $Reversed) }
function Load-Session { if ([System.IO.File]::Exists($Global:SessionFile)) { try { $O = [System.IO.File]::ReadAllText($Global:SessionFile).Trim(); $Reversed = [string]::join('', ($O.ToCharArray()[($O.Length - 1)..0])); $R = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Reversed)); $P = $R -split "\|"; if ($P[4] -eq $Global:MyHWID) { $Global:UserEmail = $P[0]; $Global:LicenseType = $P[2]; $Global:LocalPass = $P[6]; $Global:ServerPass = $P[8]; return $true } else { Remove-Item $Global:SessionFile -Force; return $false } } catch { Remove-Item $Global:SessionFile -Force; return $false } } return $false }

function Show-AuthGateway {
    $Auth = New-Object System.Windows.Forms.Form; $Auth.Text = "TITAN ENGINE V20.6 | HWID: $($Global:MyHWID)"; $Auth.Size = "500, 500"; $Auth.StartPosition = "CenterScreen"; $Auth.FormBorderStyle = "FixedToolWindow"; $Auth.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 18); $Auth.ForeColor = "White"
    $LTitle = New-Object System.Windows.Forms.Label; $LTitle.Text = "TITAN TOOLKIT LOGIN"; $LTitle.Font = "Segoe UI, 18, Bold"; $LTitle.ForeColor = "DeepSkyBlue"; $LTitle.AutoSize = $true; $LTitle.Location = "105, 15"; $Auth.Controls.Add($LTitle)
    $PnlLogin = New-Object System.Windows.Forms.Panel; $PnlLogin.Size = "460, 400"; $PnlLogin.Location = "10, 60"; $Auth.Controls.Add($PnlLogin)
    $L1=New-Object System.Windows.Forms.Label;$L1.Text="Email đăng nhập:";$L1.Location="20,10";$L1.AutoSize=$true;$PnlLogin.Controls.Add($L1); $TUser=New-Object System.Windows.Forms.TextBox;$TUser.Location="20,30";$TUser.Size="420,30";$TUser.Font="Segoe UI, 12";$PnlLogin.Controls.Add($TUser)
    $L2=New-Object System.Windows.Forms.Label;$L2.Text="Mật khẩu:";$L2.Location="20,70";$L2.AutoSize=$true;$PnlLogin.Controls.Add($L2); $TPass=New-Object System.Windows.Forms.TextBox;$TPass.Location="20,90";$TPass.Size="420,30";$TPass.Font="Segoe UI, 12";$TPass.PasswordChar="*";$PnlLogin.Controls.Add($TPass)
    $BLog = New-Object System.Windows.Forms.Button; $BLog.Text="ĐĂNG NHẬP SERVER"; $BLog.Location="20,135"; $BLog.Size="420,45"; $BLog.BackColor="DodgerBlue"; $BLog.ForeColor="White"; $BLog.Font="Segoe UI, 11, Bold"; $BLog.FlatStyle="Flat"; $PnlLogin.Controls.Add($BLog)
    $BLog.Add_Click({
        if ($TUser.Text -and $TPass.Text) {
            $Auth.Cursor = "WaitCursor"; $BLog.Text = "ĐANG CHECK DATABASE..."; 
            $R = Call-API "login" @{ email=$TUser.Text; password=$TPass.Text; hwid=$Global:MyHWID; machine_name=$Global:PCName }
            if ($R.status -eq "error" -or $R.status -eq "banned" -or $R.status -eq "fail") { [System.Windows.Forms.MessageBox]::Show($R.message, "Lỗi", 0, 16) }
            else {
                $WaitOTP = $false; $OTPType = ""
                if ($R.status -eq "require_device_otp") { $WaitOTP = $true; $OTPType = "device" } elseif ($R.status -eq "require_2fa") { $WaitOTP = $true; $OTPType = "2fa" }
                if ($WaitOTP) {
                    $OTP = Show-OtpInput "XÁC MINH BẢO MẬT" "Mã xác minh (Device/2FA) đã được gửi đến Email:" $R.otp_link
                    if ($OTP) { 
                        $R2 = Call-API "verify_otp" @{ email=$TUser.Text; otp=$OTP; hwid=$Global:MyHWID; machine_name=$Global:PCName; type=$OTPType }
                        if ($R2.status -eq "require_2fa") { $OTP2 = Show-OtpInput "XÁC MINH BẢO MẬT 2 LỚP" $R2.message $R2.otp_link; $R2 = Call-API "verify_otp" @{ email=$TUser.Text; otp=$OTP2; hwid=$Global:MyHWID; type="2fa" } }
                        if ($R2.status -eq "success") { $R = $R2 } else { [System.Windows.Forms.MessageBox]::Show($R2.message, "LỖI", 0, 16); $R = $null }
                    } else { $R = $null }
                }
                if ($R -and $R.status -eq "success") { $Global:IsAuthenticated=$true; $Global:LicenseType=$R.package; $Global:UserEmail=$TUser.Text; $Global:LocalPass="root"; $Global:ServerPass=$R.aes_key; Save-Session $Global:UserEmail $Global:LicenseType $Global:MyHWID $Global:LocalPass $Global:ServerPass; $Auth.Close() }
            }
            $Auth.Cursor = "Default"; $BLog.Text = "ĐĂNG NHẬP SERVER"
        }
    })
    $BFree = New-Object System.Windows.Forms.Button; $BFree.Text="⏱️ Mở Tool Trải Nghiệm (Free 30 Phút)"; $BFree.Location="20,195"; $BFree.Size="420,35"; $BFree.BackColor="Teal"; $BFree.ForeColor="White"; $BFree.FlatStyle="Flat"; $PnlLogin.Controls.Add($BFree)
    $BFree.Add_Click({ [System.Windows.Forms.MessageBox]::Show("Chế độ Free bị KHÓA CÁC TÍNH NĂNG VIP."); $Global:IsAuthenticated=$true; $Global:LicenseType="FREE_30M"; $Auth.Close() })
    $BStore = New-Object System.Windows.Forms.Button; $BStore.Text="Cửa Hàng VIP"; $BStore.Location="300,245"; $BStore.Size="140,30"; $BStore.BackColor="Gold"; $BStore.ForeColor="Black"; $BStore.FlatStyle="Flat"; $PnlLogin.Controls.Add($BStore); $BStore.Add_Click({ Show-Store })
    $Auth.ShowDialog() | Out-Null; $Auth.Dispose()
}

if (Load-Session) { $InputAES = Show-Level2Pass "Nhập Mật mã Tool Cấp 2 (Hoặc Master Pass từ Server):"; if ($InputAES -ne $Global:LocalPass -and $InputAES -ne $Global:ServerPass) { [System.Windows.Forms.MessageBox]::Show("Sai Mật mã Cấp 2! Tool sẽ thoát.", "LỖI", 0, 16); Exit } } else { Show-AuthGateway }
if (-not $Global:IsAuthenticated) { Exit }

# ==============================================================================
# HÀM FILELESS ĐA LUỒNG (100% ASYNC - KHÔNG TREO TOOL)
# ==============================================================================
function Invoke-SmartDownload ($Url, $OutFile) {
    if ($Url -match "drive\.google\.com") { $id = ""; if ($Url -match "id=([a-zA-Z0-9_-]+)") { $id = $matches[1] } elseif ($Url -match "/d/([a-zA-Z0-9_-]+)") { $id = $matches[1] }; if ($id) { $Session = New-Object Microsoft.PowerShell.Commands.WebRequestSession; $BaseDriveUrl = "https://drive.google.com/uc?id=$id&export=download"; try { $Resp1 = Invoke-WebRequest -Uri $BaseDriveUrl -WebSession $Session -UseBasicParsing -ErrorAction Stop; [System.IO.File]::WriteAllBytes($OutFile, $Resp1.Content); return $true } catch { $Html = $_.Exception.Response.GetResponseStream(); $Reader = New-Object System.IO.StreamReader($Html); $Content = $Reader.ReadToEnd(); $Reader.Close(); if ($Content -match "confirm=([a-zA-Z0-9_-]+)") { try { Invoke-WebRequest -Uri "$BaseDriveUrl&confirm=$($matches[1])" -OutFile $OutFile -WebSession $Session -UseBasicParsing; return $true } catch { return $false } } } } }
    if (Get-Command "curl.exe" -ErrorAction SilentlyContinue) { $p = Start-Process "curl" "-L -o `"$OutFile`" `"$Url`" -s --retry 3 -k" -Wait -PassThru -WindowStyle Hidden; if ($p.ExitCode -eq 0 -and (Test-Path $OutFile)) { return $true } }
    try { $w = New-Object System.Net.WebClient; $w.DownloadFile($Url, $OutFile); return $true } catch { return $false }
}

function Tai-Va-Chay { param ($L, $N, $T); if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }; if ($L -notmatch "^http") { $L = "$BaseUrl$L" }; $D = "$TempDir\$N"; if (Invoke-SmartDownload $L $D) { if ($T -eq "Msi") { Start-Process "msiexec.exe" "/i `"$D`" /quiet /norestart" -Wait } else { Start-Process $D -Wait } } }

# HÀM LOAD MODULE NGẦM (GHI LOG)
function Run-ModuleAsync ($Btn, $ModulePath, $IsWpfBtn = $false) {
    $OriginalText = if ($IsWpfBtn) { $Btn.Content } else { $Btn.Text }
    if ($OriginalText -match "ĐANG MỞ") { return }

    Write-GuiLog "Nạp Module: $ModulePath ..."
    
    if ($IsWpfBtn) {
        $Btn.Content = "⏳ ĐANG MỞ..."; $Btn.Background = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("DimGray"); $Btn.IsEnabled = $false
    } else {
        $Btn.Text = "⏳ ĐANG MỞ..."; $Btn.BackColor = [System.Drawing.Color]::DimGray; $Btn.Enabled = $false
    }
    
    $SyncHash = [hashtable]::Synchronized(@{ IsDone=$false; RawUrl=$RawUrl; Module=$ModulePath; LogMsg="" })
    $Runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace(); $Runspace.Open(); $Runspace.SessionStateProxy.SetVariable("sync", $SyncHash)
    $Pipeline = $Runspace.CreatePipeline()
    $Pipeline.Commands.AddScript({
        $TargetUrl = "$($sync.RawUrl)$($sync.Module)?t=$(Get-Date -UFormat %s)"
        $StubCmd = "[System.Net.ServicePointManager]::SecurityProtocol = 3072 -bor 12288; `$code = `$null; try { `$w = New-Object System.Net.WebClient; `$w.Headers.Add('User-Agent', 'Titan/20'); `$w.Encoding = [System.Text.Encoding]::UTF8; `$code = `$w.DownloadString('$TargetUrl'); `$w.Dispose() } catch {}; if (`$code) { [scriptblock]::Create(`$code).Invoke() }"
        $Encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($StubCmd))
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $Encoded" -Wait
        $sync.IsDone = $true
    }) | Out-Null
    $Pipeline.InvokeAsync()

    $CheckTimer = New-Object System.Windows.Forms.Timer; $CheckTimer.Interval = 200
    $CheckTimer.Add_Tick({
        if ($SyncHash.IsDone) {
            $CheckTimer.Stop(); $CheckTimer.Dispose()
            if ($IsWpfBtn) {
                $Btn.Content = $OriginalText; $Btn.Background = (New-Object System.Windows.Media.BrushConverter).ConvertFromString($Btn.Tag); $Btn.IsEnabled = $true
            } else {
                $Btn.Text = $OriginalText; $Btn.BackColor = $Btn.Tag; $Btn.Enabled = $true
            }
            Write-GuiLog "Hoàn tất module: $ModulePath !"
            $Runspace.Close(); $Runspace.Dispose()
        }
    })
    $CheckTimer.Start()
}

# ==============================================================================
# GIAO DIỆN WPF - FULL FEATURES
# ==============================================================================
$Global:IsWpfMode = $true 

function Load-WPF {
    try {
        Add-Type -AssemblyName PresentationFramework -ErrorAction Stop; Add-Type -AssemblyName PresentationCore; Add-Type -AssemblyName WindowsBase
        [xml]$WpfXaml = @"
        <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                Title="PHAT TAN PC V20.6 | USER: $($Global:UserEmail)" 
                Height="850" Width="1100" WindowStartupLocation="CenterScreen" Background="#19191E" FontFamily="Segoe UI">
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
                
                <ScrollViewer Grid.Row="1" Background="#1E1E23" VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="15">
                        <Border Background="#28282D" CornerRadius="8" Padding="15" Margin="0,0,0,15">
                            <StackPanel><TextBlock Text="⚙ HỆ THỐNG (SYSTEM)" Foreground="#00BEFF" FontSize="18" FontWeight="Bold" Margin="0,0,0,10"/><WrapPanel Name="wpSystem"/></StackPanel>
                        </Border>
                        <Border Background="#28282D" CornerRadius="8" Padding="15" Margin="0,0,0,15">
                            <StackPanel><TextBlock Text="🛡 BẢO MẬT (SECURITY)" Foreground="#8A2BE2" FontSize="18" FontWeight="Bold" Margin="0,0,0,10"/><WrapPanel Name="wpSecurity"/></StackPanel>
                        </Border>
                        <Border Background="#28282D" CornerRadius="8" Padding="15">
                            <StackPanel><TextBlock Text="💿 CÀI ĐẶT (INSTALL)" Foreground="#32E682" FontSize="18" FontWeight="Bold" Margin="0,0,0,10"/><WrapPanel Name="wpInstall"/></StackPanel>
                        </Border>
                    </StackPanel>
                </ScrollViewer>
                
                <Border Grid.Row="2" Background="#0A0A0C" BorderBrush="#333" BorderThickness="0,1,0,0">
                    <TextBox Name="txtLog" Background="Transparent" Foreground="Lime" FontFamily="Consolas" FontSize="12" BorderThickness="0" IsReadOnly="True" VerticalScrollBarVisibility="Auto" Text="[+] TITAN ENGINE KERNEL INITIALIZED...&#x0a;"/>
                </Border>
                
                <Grid Grid.Row="3" Background="#232328">
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
                $Btn.Add_Click({ Run-ModuleAsync $Btn $Cmd $true })
            }
            $WpfForm.FindName($PanelName).Children.Add($Btn)
        }

        # --- ĐẮP FULL NÚT WPF ---
        Add-WpfBtn "wpSystem" "ℹ CẤU HÌNH" "SystemInfo.ps1" "#00BEFF"
        Add-WpfBtn "wpSystem" "♻ DỌN RÁC" "SystemCleaner.ps1" "#00BEFF"
        Add-WpfBtn "wpSystem" "💾 QUẢN LÝ ĐĨA" "DiskManager.ps1" "#00BEFF"
        Add-WpfBtn "wpSystem" "🔍 QUÉT WINDOWS" "SystemScan.ps1" "#00BEFF"
        Add-WpfBtn "wpSystem" "⚡ TỐI ƯU RAM" "RamBooster.ps1" "#00BEFF"
        Add-WpfBtn "wpSystem" "🗝 KÍCH HOẠT" "WinActivator.ps1" "#00BEFF"
        Add-WpfBtn "wpSystem" "🚑 CỨU DỮ LIỆU" "DiskGenius.ps1" "#00BEFF" $true
        Add-WpfBtn "wpSystem" "🔧 SỬA LỖI HT" "SystemRepair.ps1" "#00BEFF"
        Add-WpfBtn "wpSystem" "🔎 QUÉT TẬP TIN" "scanfile.ps1" "#00BEFF"
        Add-WpfBtn "wpSystem" "🖱 MENU CHUỘT PHẢI" "ContextMenuManager.ps1" "#00BEFF" # <--- NÚT MỚI THÊM
        
        Add-WpfBtn "wpSecurity" "🌐 ĐỔI DNS" "NetworkMaster.ps1" "#8A2BE2"
        Add-WpfBtn "wpSecurity" "↻ QUẢN UPDATE" "WinUpdatePro.ps1" "#8A2BE2"
        Add-WpfBtn "wpSecurity" "🛡 DEFENDER ON/OFF" "DefenderMgr.ps1" "#8A2BE2"
        Add-WpfBtn "wpSecurity" "🛡 VÔ HIỆU EFSs" "AntiEFS_GUI.ps1" "#8A2BE2" $true
        Add-WpfBtn "wpSecurity" "🔒 KHÓA BITLOCKER" "BitLockerMgr.ps1" "#8A2BE2" $true
        Add-WpfBtn "wpSecurity" "⛔ CHẶN WEB ĐỘC" "BrowserPrivacy.ps1" "#8A2BE2"

        Add-WpfBtn "wpInstall" "💿 CÀI WIN AUTO" "WinInstall.ps1" "#32E682" $true
        Add-WpfBtn "wpInstall" "📝 CÀI OFFICE 365" "OfficeInstaller.ps1" "#32E682" $true
        Add-WpfBtn "wpInstall" "🔧 TỐI ƯU WIN" "WinModder.ps1" "#32E682"
        Add-WpfBtn "wpInstall" "📦 ĐÓNG GÓI ISO" "WinAIOBuilder.ps1" "#32E682" $true
        Add-WpfBtn "wpInstall" "🤖 TRỢ LÝ AI" "GeminiAI.ps1" "#32E682"
        Add-WpfBtn "wpInstall" "👜 CÀI STORE" "AppStore.ps1" "#32E682"
        Add-WpfBtn "wpInstall" "📥 TẢI ISO GỐC" "ISODownloader.ps1" "#32E682"
        Add-WpfBtn "wpInstall" "⚡ TẠO USB BOOT" "UsbBootMaker.ps1" "#32E682"
        Add-WpfBtn "wpInstall" "🍏 JAILBREAK iOS" "iOS_Jailbreak.ps1" "#32E682" $true
        Add-WpfBtn "wpInstall" "🖧 CÀI DRIVER" "AutoDriver.ps1" "#32E682" # <--- NÚT MỚI THÊM

        $WpfForm.FindName("BtnBuyKeyWpf").Add_Click({ Show-Store })
        $WpfForm.FindName("BtnToggleUI").Add_Click({ $Global:IsWpfMode = $false; $WpfForm.Close() })
        $WpfForm.ShowDialog() | Out-Null; return $true
    } catch { return $false }
}

# ==============================================================================
# GIAO DIỆN WINFORMS - FULL FEATURES
# ==============================================================================
function Load-WinForms {
    $Form = New-Object System.Windows.Forms.Form; $Form.Text = "PHAT TAN PC V20.6 | WINFORMS MODE"; $Form.Size = "1100, 850"; $Form.StartPosition = "CenterScreen"; $Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 35); $Form.ForeColor = "White"
    $PnlHeader = New-Object System.Windows.Forms.Panel; $PnlHeader.Size="1100, 80"; $PnlHeader.Location="0,0"; $PnlHeader.BackColor = [System.Drawing.Color]::FromArgb(35,35,40); $Form.Controls.Add($PnlHeader)
    $LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text="PHAT TAN PC TOOLKIT"; $LblTitle.Font="Segoe UI, 24, Bold"; $LblTitle.AutoSize=$true; $LblTitle.Location="20,15"; $LblTitle.ForeColor=[System.Drawing.Color]::DeepSkyBlue; $PnlHeader.Controls.Add($LblTitle)
    $BtnToggleUI = New-Object System.Windows.Forms.Button; $BtnToggleUI.Location="750, 25"; $BtnToggleUI.Size="140, 35"; $BtnToggleUI.FlatStyle="Flat"; $BtnToggleUI.Font="Segoe UI, 9, Bold"; $BtnToggleUI.Text="✨ DÙNG WPF"; $BtnToggleUI.BackColor=[System.Drawing.Color]::BlueViolet; $BtnToggleUI.Add_Click({ $Global:IsWpfMode = $true; $Form.Close() }); $PnlHeader.Controls.Add($BtnToggleUI)

    $MainFlow = New-Object System.Windows.Forms.FlowLayoutPanel; $MainFlow.Location="10,90"; $MainFlow.Size="1060,450"; $MainFlow.AutoScroll=$true; $Form.Controls.Add($MainFlow)

    function Add-HozWinGroup ($Title, $Color) {
        $Pnl = New-Object System.Windows.Forms.Panel; $Pnl.Size="1020, 160"; $Pnl.Margin="0,0,0,15"; $Pnl.BackColor=[System.Drawing.Color]::FromArgb(40,40,45)
        $Lbl = New-Object System.Windows.Forms.Label; $Lbl.Text=$Title; $Lbl.ForeColor=$Color; $Lbl.Font="Segoe UI, 14, Bold"; $Lbl.Location="15,10"; $Lbl.AutoSize=$true; $Pnl.Controls.Add($Lbl)
        $Wrap = New-Object System.Windows.Forms.FlowLayoutPanel; $Wrap.Location="15, 45"; $Wrap.Size="990, 105"; $Pnl.Controls.Add($Wrap)
        $MainFlow.Controls.Add($Pnl); return $Wrap
    }
    function Add-WinBtn ($Wrap, $Text, $Cmd, $Color, $IsVip=$false) { 
        $B = New-Object System.Windows.Forms.Button; $B.Text=$Text; $B.Size="150,45"; $B.FlatStyle="Flat"; $B.Font="Segoe UI, 9, Bold"; $B.Margin="5"; $B.Tag = $Color
        if ($IsVip -and $Global:LicenseType -in @("NONE", "FREE", "FREE_30M")) {
            $B.ForeColor="Silver"; $B.BackColor=[System.Drawing.Color]::FromArgb(80,80,80); $B.Add_Click({ [System.Windows.Forms.MessageBox]::Show("Cần VIP!") })
        } else {
            $B.BackColor=$Color; $B.ForeColor="White"; $B.Add_Click({ Run-ModuleAsync $this $Cmd $false })
        }
        $Wrap.Controls.Add($B)
    }

    $GrpSys = Add-HozWinGroup "⚙ HỆ THỐNG" [System.Drawing.Color]::DeepSkyBlue
    @("ℹ CẤU HÌNH|SystemInfo.ps1", "♻ DỌN RÁC|SystemCleaner.ps1", "💾 QUẢN LÝ ĐĨA|DiskManager.ps1", "🔍 QUÉT WIN|SystemScan.ps1", "⚡ TỐI ƯU RAM|RamBooster.ps1", "🗝 KÍCH HOẠT|WinActivator.ps1", "🔧 SỬA LỖI HT|SystemRepair.ps1", "🔎 QUÉT TẬP TIN|scanfile.ps1", "🖱 MENU CHUỘT PHẢI|ContextMenuManager.ps1") | % {
        $d=$_ -split '\|'; Add-WinBtn $GrpSys $d[0] $d[1] [System.Drawing.Color]::DeepSkyBlue
    }

    $GrpSec = Add-HozWinGroup "🛡 BẢO MẬT" [System.Drawing.Color]::BlueViolet
    @("🌐 ĐỔI DNS|NetworkMaster.ps1", "↻ QUẢN UPDATE|WinUpdatePro.ps1", "🛡 DEFENDER|DefenderMgr.ps1", "⛔ CHẶN WEB|BrowserPrivacy.ps1") | % {
        $d=$_ -split '\|'; Add-WinBtn $GrpSec $d[0] $d[1] [System.Drawing.Color]::BlueViolet
    }

    $GrpIns = Add-HozWinGroup "💿 CÀI ĐẶT" [System.Drawing.Color]::MediumSeaGreen
    @("🔧 TỐI ƯU WIN|WinModder.ps1", "🤖 TRỢ LÝ AI|GeminiAI.ps1", "👜 CÀI STORE|AppStore.ps1", "📥 TẢI ISO|ISODownloader.ps1", "⚡ TẠO USB|UsbBootMaker.ps1", "🖧 CÀI DRIVER|AutoDriver.ps1") | % {
        $d=$_ -split '\|'; Add-WinBtn $GrpIns $d[0] $d[1] [System.Drawing.Color]::MediumSeaGreen
    }

    $Global:LogBox = New-Object System.Windows.Forms.TextBox
    $Global:LogBox.Location="10, 560"; $Global:LogBox.Size="1060, 150"; $Global:LogBox.Multiline=$true; $Global:LogBox.ReadOnly=$true; $Global:LogBox.BackColor=[System.Drawing.Color]::Black; $Global:LogBox.ForeColor=[System.Drawing.Color]::Lime; $Global:LogBox.Font="Consolas, 10"; $Form.Controls.Add($Global:LogBox)

    $BtnBuyKey = New-Object System.Windows.Forms.Button; $BtnBuyKey.Text="💎 CỬA HÀNG VIP"; $BtnBuyKey.Location="870, 730"; $BtnBuyKey.Size="200,45"; $BtnBuyKey.BackColor="Gold"; $BtnBuyKey.ForeColor="Black"; $BtnBuyKey.FlatStyle="Flat"; $BtnBuyKey.Font="Segoe UI, 10, Bold"; $BtnBuyKey.Add_Click({ Show-Store }); $Form.Controls.Add($BtnBuyKey)

    $Form.ShowDialog() | Out-Null; $Form.Dispose()
}

while ($true) {
    if ($Global:IsWpfMode) { if (-not (Load-WPF)) { $Global:IsWpfMode = $false } } else { Load-WinForms }
    if ([System.Windows.Forms.Application]::OpenForms.Count -eq 0) { break }
}
[System.GC]::Collect()
