<#
    TOOL CUU HO MAY TINH - PHAT TAN PC
    Version: 20.1 MASTERPIECE (Fixed Hover, Doom Timer, SaaS Store inside App)
#>

if ($host.Name -match "ISE") { Exit }
if ($MyInvocation.MyCommand.Path) { Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show("Truy cập trái phép! Vui lòng dùng lệnh tải từ Server.", "BẢO VỆ", 0, 16); Exit }
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://script.phattan.id.vn/tool/install.ps1 | iex`"" -Verb RunAs; Exit }

Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; Add-Type -AssemblyName Microsoft.VisualBasic
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
function Write-Log ($Msg, $Type="INFO") { $Time = (Get-Date).ToString("HH:mm:ss dd/MM/yyyy"); "[$Time] [$Type] $Msg" | Out-File -FilePath $LogFile -Append -Encoding UTF8 }

$Global:SessionFile = "$env:LOCALAPPDATA\PhatTan_Titan.dat"
$Global:AvatarFile = "$env:LOCALAPPDATA\PhatTan_Avatar.png"
$Global:IsAuthenticated = $false; $Global:LicenseType = "NONE"; $Global:UserEmail = ""; $Global:LocalPass = "root"; $Global:ServerPass = "root"

# --- TITAN PAY GATEWAY ---
function Show-QRPay ($Amount, $Prefix, $Email, $TitleMsg) {
    $SafeEmail = $Email -replace "\s", ""; $Content = "$Prefix $SafeEmail"; $UrlContent = [uri]::EscapeDataString($Content)
    $QrUrl = "https://img.vietqr.io/image/970436-1055835227-qr_only.png?accountName=DANG%20LAM%20TAN%20PHAT&addInfo=$UrlContent"
    if ($Amount -gt 0) { $QrUrl += "&amount=$Amount" }
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

# --- CỬA HÀNG BẢNG GIÁ ĐỘC LẬP ---
function Show-Store {
    $S = New-Object System.Windows.Forms.Form; $S.Size="450, 400"; $S.StartPosition="CenterParent"; $S.Text="NÂNG CẤP GÓI VIP"; $S.BackColor=[System.Drawing.Color]::FromArgb(20,20,25); $S.FormBorderStyle="FixedToolWindow"
    $L = New-Object System.Windows.Forms.Label; $L.Text="🛒 CHỌN GÓI CƯỚC"; $L.Font="Segoe UI, 16, Bold"; $L.ForeColor="White"; $L.Location="110,15"; $L.AutoSize=$true; $S.Controls.Add($L)
    
    $BTrial = New-Object System.Windows.Forms.Button; $BTrial.Text="🎁 LẤY / GIA HẠN KEY 7 NGÀY (Cần Donate)"; $BTrial.Location="20,60"; $BTrial.Size="390,40"; $BTrial.BackColor="DarkMagenta"; $BTrial.ForeColor="White"; $BTrial.FlatStyle="Flat"; $S.Controls.Add($BTrial)
    $BTrial.Add_Click({ $E = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập Email của bạn:", "Nhận Key"); if ($E) { $S.Cursor="WaitCursor"; $R = Call-API "request_trial" @{ email=$E }; [System.Windows.Forms.MessageBox]::Show($R.message, "Thông báo"); $S.Cursor="Default" } })
    
    $B1M = New-Object System.Windows.Forms.Button; $B1M.Text="🥉 VIP 1 THÁNG (29.000đ)"; $B1M.Location="20,110"; $B1M.Size="190,50"; $B1M.BackColor="MediumSeaGreen"; $B1M.ForeColor="White"; $B1M.FlatStyle="Flat"; $S.Controls.Add($B1M)
    $B1M.Add_Click({ $E = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập Email nâng cấp VIP 1 THÁNG:", "Mua Key"); if ($E) { Show-QRPay 29000 "MUA KEY 1M" $E "VIP 1 THÁNG" } })

    $B6M = New-Object System.Windows.Forms.Button; $B6M.Text="🥈 VIP 6 THÁNG (149.000đ)"; $B6M.Location="220,110"; $B6M.Size="190,50"; $B6M.BackColor="DodgerBlue"; $B6M.ForeColor="White"; $B6M.FlatStyle="Flat"; $S.Controls.Add($B6M)
    $B6M.Add_Click({ $E = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập Email nâng cấp VIP 6 THÁNG:", "Mua Key"); if ($E) { Show-QRPay 149000 "MUA KEY 6M" $E "VIP 6 THÁNG" } })

    $BFull = New-Object System.Windows.Forms.Button; $BFull.Text="💎 VIP VĨNH VIỄN (200.000đ)"; $BFull.Location="20,170"; $BFull.Size="190,50"; $BFull.BackColor="Gold"; $BFull.ForeColor="Black"; $BFull.FlatStyle="Flat"; $S.Controls.Add($BFull)
    $BFull.Add_Click({ $E = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập Email nâng cấp VIP VĨNH VIỄN:", "Mua Key"); if ($E) { Show-QRPay 200000 "MUA KEY VIP" $E "VIP VĨNH VIỄN" } })

    $BFam = New-Object System.Windows.Forms.Button; $BFam.Text="👑 ĐẠI LÝ (800.000đ - 25 PC)"; $BFam.Location="220,170"; $BFam.Size="190,50"; $BFam.BackColor="DarkOrange"; $BFam.ForeColor="Black"; $BFam.FlatStyle="Flat"; $S.Controls.Add($BFam)
    $BFam.Add_Click({ $E = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập Email nâng cấp GÓI ĐẠI LÝ:", "Mua Key"); if ($E) { Show-QRPay 800000 "MUA KEY MULTI" $E "GÓI ĐẠI LÝ" } })
    
    $S.ShowDialog() | Out-Null
}

function Call-API ($Action, $Payload) { 
    try { 
        $Payload.Add("action", $Action)
        $JsonString = $Payload | ConvertTo-Json -Compress
        $Utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($JsonString)
        return Invoke-RestMethod -Uri $Global:ApiServer -Method Post -Body $Utf8Bytes -ContentType "application/json; charset=utf-8" -TimeoutSec 15 
    } catch { 
        return @{ status="error"; message="Mất kết nối Máy chủ!" } 
    } 
}
function Save-Session ($E, $T, $H, $LP, $SP) { $R = "$E|PT|$T|PC|$H|LP|$LP|SP|$SP"; $B = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($R)); [string]::join('', ($B.ToCharArray()[($B.Length - 1)..0])) | Out-File $Global:SessionFile -Force }
function Load-Session {
    if (Test-Path $Global:SessionFile) {
        try { $O = Get-Content $Global:SessionFile -Raw; $R = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String([string]::join('', ($O.ToCharArray()[($O.Length - 1)..0])))); $P = $R -split "\|"; if ($P[4] -eq $Global:MyHWID) { $Global:UserEmail = $P[0]; $Global:LicenseType = $P[2]; $Global:LocalPass = $P[6]; $Global:ServerPass = $P[8]; return $true } else { Remove-Item $Global:SessionFile -Force; return $false } } catch { return $false }
    } return $false
}

function Show-AuthGateway {
    $Auth = New-Object System.Windows.Forms.Form; $Auth.Text = "TITAN ENGINE V20.1 | HWID: $($Global:MyHWID)"; $Auth.Size = "500, 500"; $Auth.StartPosition = "CenterScreen"; $Auth.FormBorderStyle = "FixedToolWindow"; $Auth.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 18); $Auth.ForeColor = "White"
    $LTitle = New-Object System.Windows.Forms.Label; $LTitle.Text = "TITAN TOOLKIT LOGIN"; $LTitle.Font = "Segoe UI, 18, Bold"; $LTitle.ForeColor = "DeepSkyBlue"; $LTitle.AutoSize = $true; $LTitle.Location = "105, 15"; $Auth.Controls.Add($LTitle)
    
    # LOGIN PANEL
    $PnlLogin = New-Object System.Windows.Forms.Panel; $PnlLogin.Size = "460, 400"; $PnlLogin.Location = "10, 60"; $Auth.Controls.Add($PnlLogin)
    $L1=New-Object System.Windows.Forms.Label;$L1.Text="Email đăng nhập:";$L1.Location="20,10";$L1.AutoSize=$true;$PnlLogin.Controls.Add($L1); $TUser=New-Object System.Windows.Forms.TextBox;$TUser.Location="20,30";$TUser.Size="420,30";$TUser.Font="Segoe UI, 12";$PnlLogin.Controls.Add($TUser)
    $L2=New-Object System.Windows.Forms.Label;$L2.Text="Mật khẩu:";$L2.Location="20,70";$L2.AutoSize=$true;$PnlLogin.Controls.Add($L2); $TPass=New-Object System.Windows.Forms.TextBox;$TPass.Location="20,90";$TPass.Size="420,30";$TPass.Font="Segoe UI, 12";$TPass.PasswordChar="*";$PnlLogin.Controls.Add($TPass)
    $BLog = New-Object System.Windows.Forms.Button; $BLog.Text="ĐĂNG NHẬP SERVER"; $BLog.Location="20,135"; $BLog.Size="420,45"; $BLog.BackColor="DodgerBlue"; $BLog.ForeColor="White"; $BLog.Font="Segoe UI, 11, Bold"; $BLog.FlatStyle="Flat"; $PnlLogin.Controls.Add($BLog)
    $BLog.Add_Click({
        if ($TUser.Text -and $TPass.Text) {
            $Auth.Cursor = "WaitCursor"; $BLog.Text = "ĐANG CHECK DATABASE..."; $R = Call-API "login" @{ email=$TUser.Text; password=$TPass.Text; hwid=$Global:MyHWID; machine_name=$Global:PCName }
            if ($R.status -eq "error" -or $R.status -eq "banned" -or $R.status -eq "fail") { [System.Windows.Forms.MessageBox]::Show($R.message, "Lỗi") }
            else {
                $WaitOTP = $false; $OTPType = ""
                if ($R.status -eq "require_device_otp") { $WaitOTP = $true; $OTPType = "device" } elseif ($R.status -eq "require_2fa") { $WaitOTP = $true; $OTPType = "2fa" }
                if ($WaitOTP) {
                    $OTP = [Microsoft.VisualBasic.Interaction]::InputBox("Mã xác minh (Device/2FA) đã gửi về Email:", "XÁC MINH")
                    if ($OTP) { 
                        $R2 = Call-API "verify_otp" @{ email=$TUser.Text; otp=$OTP; hwid=$Global:MyHWID; machine_name=$Global:PCName; type=$OTPType }
                        if ($R2.status -eq "require_2fa") { $OTP2 = [Microsoft.VisualBasic.Interaction]::InputBox($R2.message, "XÁC MINH 2FA"); $R2 = Call-API "verify_otp" @{ email=$TUser.Text; otp=$OTP2; hwid=$Global:MyHWID; type="2fa" } }
                        if ($R2.status -eq "success") { $R = $R2 } else { [System.Windows.Forms.MessageBox]::Show($R2.message); $R = $null }
                    } else { $R = $null }
                }
                if ($R -and $R.status -eq "success") {
                    $Global:IsAuthenticated=$true; $Global:LicenseType=$R.package; $Global:UserEmail=$TUser.Text; $Global:LocalPass="root"; $Global:ServerPass=$R.aes_key; $env:TITAN_AUTH_TOKEN=[System.Guid]::NewGuid().ToString()
                    Save-Session $Global:UserEmail $Global:LicenseType $Global:MyHWID $Global:LocalPass $Global:ServerPass; $Auth.Close()
                }
            }
            $Auth.Cursor = "Default"; $BLog.Text = "ĐĂNG NHẬP SERVER"
        }
    })
    
    $BFree = New-Object System.Windows.Forms.Button; $BFree.Text="⏱️ Mở Tool Trải Nghiệm (Free 30 Phút)"; $BFree.Location="20,195"; $BFree.Size="420,35"; $BFree.BackColor="Teal"; $BFree.ForeColor="White"; $BFree.FlatStyle="Flat"; $PnlLogin.Controls.Add($BFree)
    $BFree.Add_Click({ [System.Windows.Forms.MessageBox]::Show("Chế độ Free bị KHÓA CÁC TÍNH NĂNG VIP."); $Global:IsAuthenticated=$true; $Global:LicenseType="FREE_30M"; $env:TITAN_AUTH_TOKEN = [System.Guid]::NewGuid().ToString(); $Auth.Close() })
    
    $BForgot = New-Object System.Windows.Forms.Button; $BForgot.Text="Quên mật khẩu?"; $BForgot.Location="20,245"; $BForgot.Size="130,30"; $BForgot.BackColor="Transparent"; $BForgot.ForeColor="LightSkyBlue"; $BForgot.FlatStyle="Flat"; $BForgot.FlatAppearance.BorderSize=0; $PnlLogin.Controls.Add($BForgot)
    $BShowReg = New-Object System.Windows.Forms.Button; $BShowReg.Text="Tạo tài khoản"; $BShowReg.Location="160,245"; $BShowReg.Size="130,30"; $BShowReg.BackColor="DimGray"; $BShowReg.FlatStyle="Flat"; $PnlLogin.Controls.Add($BShowReg)
    $BStore = New-Object System.Windows.Forms.Button; $BStore.Text="Cửa Hàng VIP"; $BStore.Location="300,245"; $BStore.Size="140,30"; $BStore.BackColor="Gold"; $BStore.ForeColor="Black"; $BStore.FlatStyle="Flat"; $PnlLogin.Controls.Add($BStore)
    $BStore.Add_Click({ Show-Store })

    # ĐĂNG KÝ MỚI
    $PnlReg = New-Object System.Windows.Forms.Panel; $PnlReg.Size = "460, 400"; $PnlReg.Location = "10, 60"; $PnlReg.Visible = $false; $Auth.Controls.Add($PnlReg)
    $R1=New-Object System.Windows.Forms.Label;$R1.Text="Họ tên:";$R1.Location="20,0";$R1.AutoSize=$true;$PnlReg.Controls.Add($R1); $TRName=New-Object System.Windows.Forms.TextBox;$TRName.Location="20,20";$TRName.Size="420,25";$PnlReg.Controls.Add($TRName)
    $R2=New-Object System.Windows.Forms.Label;$R2.Text="Email (Bắt buộc đúng để nhận OTP):";$R2.Location="20,50";$R2.AutoSize=$true;$PnlReg.Controls.Add($R2); $TREmail=New-Object System.Windows.Forms.TextBox;$TREmail.Location="20,70";$TREmail.Size="420,25";$PnlReg.Controls.Add($TREmail)
    $R3=New-Object System.Windows.Forms.Label;$R3.Text="Mật khẩu:";$R3.Location="20,100";$R3.AutoSize=$true;$PnlReg.Controls.Add($R3); $TRPass=New-Object System.Windows.Forms.TextBox;$TRPass.Location="20,120";$TRPass.Size="420,25";$TRPass.PasswordChar="*";$PnlReg.Controls.Add($TRPass)
    $R4=New-Object System.Windows.Forms.Label;$R4.Text="Câu hỏi bảo mật:";$R4.Location="20,150";$R4.AutoSize=$true;$PnlReg.Controls.Add($R4); $CSec=New-Object System.Windows.Forms.ComboBox;$CSec.Location="20,170";$CSec.Size="420,25";$CSec.DropDownStyle="DropDownList"; $CSec.Items.AddRange(@("Con vật yêu thích?","Tên trường cấp 1?","Người yêu cũ?"));$CSec.SelectedIndex=0;$PnlReg.Controls.Add($CSec)
    $R5=New-Object System.Windows.Forms.Label;$R5.Text="Trả lời:";$R5.Location="20,200";$R5.AutoSize=$true;$PnlReg.Controls.Add($R5); $TRAns=New-Object System.Windows.Forms.TextBox;$TRAns.Location="20,220";$TRAns.Size="420,25";$PnlReg.Controls.Add($TRAns)

    $BReg = New-Object System.Windows.Forms.Button; $BReg.Text="XÁC NHẬN ĐĂNG KÝ"; $BReg.Location="20,260"; $BReg.Size="420,40"; $BReg.BackColor="Green"; $BReg.ForeColor="White"; $BReg.FlatStyle="Flat"; $PnlReg.Controls.Add($BReg)
    $BReg.Add_Click({
        $Auth.Cursor = "WaitCursor"; $R = Call-API "register" @{ name=$TRName.Text; email=$TREmail.Text; password=$TRPass.Text; question=$CSec.Text; answer=$TRAns.Text }
        if ($R.status -eq "success") { [System.Windows.Forms.MessageBox]::Show("Tạo thành công!"); $PnlReg.Visible=$false; $PnlLogin.Visible=$true } else { [System.Windows.Forms.MessageBox]::Show($R.message) }
        $Auth.Cursor = "Default"
    })
    $BBack = New-Object System.Windows.Forms.Button; $BBack.Text="Quay lại Đăng nhập"; $BBack.Location="20,310"; $BBack.Size="420,35"; $BBack.BackColor="DimGray"; $BBack.FlatStyle="Flat"; $PnlReg.Controls.Add($BBack)
    $BShowReg.Add_Click({ $PnlLogin.Visible = $false; $PnlReg.Visible = $true }); $BBack.Add_Click({ $PnlReg.Visible = $false; $PnlLogin.Visible = $true })

    $Auth.ShowDialog() | Out-Null
}

if (Load-Session) {
    $InputAES = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập Mật mã Tool Cấp 2 (Hoặc Master Pass từ Server):", "BẢO MẬT CỤC BỘ")
    if ($InputAES -eq $Global:LocalPass -or $InputAES -eq $Global:ServerPass) { $env:TITAN_AUTH_TOKEN = [System.Guid]::NewGuid().ToString() } 
    else { [System.Windows.Forms.MessageBox]::Show("Sai Mật mã Cấp 2! Tool sẽ thoát.", "LỖI", 0, 16); Exit }
} else { Show-AuthGateway }

if (-not $Global:IsAuthenticated) { Exit }

# ==============================================================================
# HÀM FILELESS ẢO HÓA HOÀN TOÀN
# ==============================================================================
function Invoke-SmartDownload ($Url, $OutFile) {
    if (Get-Command "curl.exe" -ErrorAction SilentlyContinue) { $p = Start-Process "curl" "-L -o `"$OutFile`" `"$Url`" -s --retry 3 -k" -Wait -PassThru -WindowStyle Hidden; if ($p.ExitCode -eq 0 -and (Test-Path $OutFile)) { return $true } }
    try { $w = New-Object System.Net.WebClient; $w.DownloadFile($Url, $OutFile); return $true } catch { return $false }
}
function Tai-Va-Chay { param ($L, $N, $T); if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }; if ($L -notmatch "^http") { $L = "$BaseUrl$L" }; $D = "$TempDir\$N"; if (Invoke-SmartDownload $L $D) { if ($T -eq "Msi") { Start-Process "msiexec.exe" "/i `"$D`" /quiet /norestart" -Wait } else { Start-Process $D -Wait } } }

function Load-Module ($N) { 
    if ($this -ne $null) { $this.Enabled = $false }
    try { 
        $TargetUrl = "$RawUrl$N`?t=$(Get-Date -UFormat %s)"
        $StubCmd = "
            [System.Net.ServicePointManager]::Expect100Continue = `$true;
            [System.Net.ServicePointManager]::SecurityProtocol = 3072 -bor 12288;
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { `$true };
            `$code = `$null;
            try { Add-Type -AssemblyName System.Net.Http; `$h = New-Object System.Net.Http.HttpClientHandler; `$h.ServerCertificateCustomValidationCallback = { `$true }; `$c = New-Object System.Net.Http.HttpClient(`$h); `$c.DefaultRequestHeaders.Add('User-Agent', 'Titan/20'); `$code = `$c.GetStringAsync('$TargetUrl').GetAwaiter().GetResult(); `$c.Dispose() } catch {}
            if ([string]::IsNullOrWhiteSpace(`$code)) { try { `$w = New-Object System.Net.WebClient; `$w.Headers.Add('User-Agent', 'Titan/20'); `$w.Encoding = [System.Text.Encoding]::UTF8; `$code = `$w.DownloadString('$TargetUrl'); `$w.Dispose() } catch {} }
            if ([string]::IsNullOrWhiteSpace(`$code)) { try { `$com = New-Object -ComObject WinHttp.WinHttpRequest.5.1; `$com.Open('GET', '$TargetUrl', `$false); `$com.SetRequestHeader('User-Agent', 'Titan/20'); `$com.Option(4) = 13056; `$com.Send(); `$code = `$com.ResponseText } catch {} }
            if (![string]::IsNullOrWhiteSpace(`$code) -and `$code -notmatch '404 Not Found') { [scriptblock]::Create(`$code).Invoke() } else { Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show(`"Tải file $($N) thất bại!`", `"LỖI`", 0, 16) }
        "
        $EncodedStub = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($StubCmd))
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $EncodedStub" 
    } catch { }
    if ($this -ne $null) { Start-Sleep -Milliseconds 500; $this.Enabled = $true }
}

# --- GUI SETUP ---
$Global:IsDarkMode = $true 
$Theme = @{ Dark=@{ Back=[System.Drawing.Color]::FromArgb(25,25,30); Card=[System.Drawing.Color]::FromArgb(40,40,45); Text=[System.Drawing.Color]::WhiteSmoke; System=[System.Drawing.Color]::FromArgb(0,190,255); Security=[System.Drawing.Color]::FromArgb(180,80,255); Install=[System.Drawing.Color]::FromArgb(50,230,130) }; Light=@{ Back=[System.Drawing.Color]::FromArgb(245,245,250); Card=[System.Drawing.Color]::White; Text=[System.Drawing.Color]::Black; System=[System.Drawing.Color]::FromArgb(0,120,215); Security=[System.Drawing.Color]::FromArgb(138,43,226); Install=[System.Drawing.Color]::FromArgb(34,139,34) } }
$Paint_Glow = { param($s, $e); $C = $s.Tag; if(!$C){$C=[System.Drawing.Color]::Gray}; $P = New-Object System.Drawing.Pen($C, 5); $R = $s.ClientRectangle; $R.X+=2; $R.Y+=2; $R.Width-=4; $R.Height-=4; $e.Graphics.DrawRectangle($P, $R); $P.Dispose() }
function Apply-Theme { $T=if($Global:IsDarkMode){$Theme.Dark}else{$Theme.Light}; $Form.BackColor=$T.Back; $Form.ForeColor=$T.Text; $PnlHeader.BackColor=if($Global:IsDarkMode){[System.Drawing.Color]::FromArgb(35,35,40)}else{[System.Drawing.Color]::FromArgb(230,230,230)}; $BtnTheme.Text=if($Global:IsDarkMode){"☀ LIGHT"}else{"🌙 DARK"}; $BtnTheme.BackColor=if($Global:IsDarkMode){[System.Drawing.Color]::White}else{[System.Drawing.Color]::Black}; $BtnTheme.ForeColor=if($Global:IsDarkMode){[System.Drawing.Color]::Black}else{[System.Drawing.Color]::White}; foreach($P in $TabControl.TabPages){$P.BackColor=$T.Back; $P.ForeColor=$T.Text; foreach($C in $P.Controls){if($C -is [System.Windows.Forms.Panel] -and $C.Name -like "Card*"){$C.BackColor=$T.Card; $G=$T.System; if($C.Name -match "SECURITY"){$G=$T.Security}; if($C.Name -match "INSTALL"){$G=$T.Install}; $C.Tag=$G; $C.Invalidate(); foreach($Child in $C.Controls){if($Child -is [System.Windows.Forms.Label]){$Child.ForeColor=$G}; if($Child -is [System.Windows.Forms.FlowLayoutPanel]){foreach($Btn in $Child.Controls){if($Btn.Text -notmatch "CẦN KEY"){$Btn.BackColor=$G; $Btn.ForeColor="White"; $Btn.Tag=$G}}}}}}}}

# --- HÀM TẠO NÚT CÓ TÍNH NĂNG HOVER NERF (ĐÃ SỬA LỖI CHỮ THẬT) ---
function Add-Btn ($P, $T, $Cmd, $IsVipOnly = $false) { 
    $B = New-Object System.Windows.Forms.Button; $B.Text=$T; $B.Size="140,45"; $B.FlatStyle="Flat"; $B.Font="Segoe UI, 9, Bold"; $B.Margin="5,5,5,5"; $B.Cursor="Hand"; $B.FlatAppearance.BorderSize=0
    # Lưu lại chữ gốc để lúc rút chuột ra nó hoàn lại
    $B.Tag = $T
    if ($IsVipOnly -and $Global:LicenseType -in @("FREE", "FREE_30M")) {
        $B.ForeColor = "Silver"
        $B.Add_MouseEnter({ $this.Text = "⛔ CẦN KEY VIP"; $this.BackColor = "Crimson"; $this.ForeColor = "White" })
        $B.Add_MouseLeave({ $this.Text = $this.Tag; $this.BackColor = [System.Drawing.Color]::FromArgb(80,80,80); $this.ForeColor = "Silver" })
        $B.Add_Click({ [System.Windows.Forms.MessageBox]::Show("Tính năng này yêu cầu Gói VIP. Vui lòng bấm 'CỬA HÀNG VIP' góc dưới phải để nâng cấp!", "BỊ KHÓA", 0, 16) })
        $B.BackColor = [System.Drawing.Color]::FromArgb(80,80,80) # Màu xám tro báo hiệu chưa mở khóa
    } else {
        $B.Add_Click($Cmd)
        $B.Add_MouseEnter({ if($this.Enabled){$this.BackColor=[System.Windows.Forms.ControlPaint]::Light($this.BackColor, 0.6)} })
        $B.Add_MouseLeave({ if($this.Enabled){ Apply-Theme } })
    }
    $P.Controls.Add($B); return $B 
}

$Form = New-Object System.Windows.Forms.Form; 
$Form.Text = "PHAT TAN PC V20.1 | GÓI: $($Global:LicenseType) | User: $($Global:UserEmail)" 
$Form.Size = New-Object System.Drawing.Size(1080, 780); $Form.StartPosition = "CenterScreen"; $Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

# --- BẬT ĐỒNG HỒ ĐẾM NGƯỢC NẾU LÀ FREE_30M ---
$Global:TimeLeft = 1800 
if ($Global:LicenseType -eq "FREE_30M") {
    $Script:DoomTimer = New-Object System.Windows.Forms.Timer; $Script:DoomTimer.Interval = 1000
    $Script:DoomTimer.Add_Tick({
        $Global:TimeLeft--; if ($Global:TimeLeft -le 0) { $Script:DoomTimer.Stop(); [System.Windows.Forms.MessageBox]::Show("HẾT THỜI GIAN DÙNG THỬ! Vui lòng mua Key.", "HẾT HẠN", 0, 16); Remove-Item $Global:SessionFile -Force; [Environment]::Exit(0) }
        $m = [math]::Floor($Global:TimeLeft / 60); $s = $Global:TimeLeft % 60; $Form.Text = "PHAT TAN PC V20.1 | TRẢI NGHIỆM FREE - HẾT HẠN SAU: $m phút $s giây"
    }); $Script:DoomTimer.Start()
}

$PnlHeader = New-Object System.Windows.Forms.Panel; $PnlHeader.Size="1080, 80"; $PnlHeader.Location="0,0"; $Form.Controls.Add($PnlHeader)
$LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text="PHAT TAN PC TOOLKIT"; $LblTitle.Font="Segoe UI, 24, Bold"; $LblTitle.AutoSize=$true; $LblTitle.Location="20,15"; $LblTitle.ForeColor=[System.Drawing.Color]::DeepSkyBlue; $PnlHeader.Controls.Add($LblTitle)
$LblSub = New-Object System.Windows.Forms.Label; $LblSub.Text="Enterprise Cloud Architecture - Current Plan: $($Global:LicenseType)"; $LblSub.ForeColor="Lime"; $LblSub.AutoSize=$true; $LblSub.Font="Segoe UI, 10, Italic"; $LblSub.Location="25,60"; $PnlHeader.Controls.Add($LblSub)

# --- NÚT TRANG CÁ NHÂN (PROFILE) CÓ AVATAR TỰ ĐỘNG CẮT TRÒN ---
$BtnProfile = New-Object System.Windows.Forms.Button; $BtnProfile.Location="730, 25"; $BtnProfile.Size="160, 35"; $BtnProfile.FlatStyle="Flat"; $BtnProfile.Font="Segoe UI, 9, Bold"; $BtnProfile.Cursor="Hand"; $BtnProfile.Text="👤 TRANG CÁ NHÂN"; $BtnProfile.BackColor="DimGray"; $BtnProfile.ForeColor="White"
$BtnProfile.Add_Click({
    $ProfForm = New-Object System.Windows.Forms.Form
    $ProfForm.Text = "Hồ Sơ Của Tôi"; $ProfForm.Size = "400, 300"; $ProfForm.StartPosition = "CenterParent"; $ProfForm.BackColor = [System.Drawing.Color]::FromArgb(25,25,30); $ProfForm.ForeColor = "White"; $ProfForm.FormBorderStyle="FixedToolWindow"
    
    $Pic = New-Object System.Windows.Forms.PictureBox; $Pic.Size = "120,120"; $Pic.Location = "20,20"; $Pic.SizeMode = "StretchImage"; $Pic.BackColor = "Gray"
    $Path = New-Object System.Drawing.Drawing2D.GraphicsPath; $Path.AddEllipse(0, 0, 120, 120); $Pic.Region = New-Object System.Drawing.Region($Path)
    if (Test-Path $Global:AvatarFile) { try { $Pic.Image = [System.Drawing.Image]::FromFile($Global:AvatarFile) } catch {} }
    $ProfForm.Controls.Add($Pic)

    $BtnUpload = New-Object System.Windows.Forms.Button; $BtnUpload.Text="Đổi Avatar"; $BtnUpload.Location="30, 150"; $BtnUpload.Size="100, 30"; $BtnUpload.BackColor="SteelBlue"; $BtnUpload.FlatStyle="Flat"
    $BtnUpload.Add_Click({
        $FD = New-Object System.Windows.Forms.OpenFileDialog; $FD.Filter = "Image Files|*.jpg;*.jpeg;*.png"
        if ($FD.ShowDialog() -eq 'OK') {
            try {
                $Img = [System.Drawing.Image]::FromFile($FD.FileName)
                $Ratio = $Img.Width / $Img.Height; $NewW = 512; $NewH = 512
                if ($Ratio -gt 1) { $NewH = [math]::Floor(512 / $Ratio) } else { $NewW = [math]::Floor(512 * $Ratio) }
                $Bmp = New-Object System.Drawing.Bitmap($NewW, $NewH)
                $G = [System.Drawing.Graphics]::FromImage($Bmp); $G.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic; $G.DrawImage($Img, 0, 0, $NewW, $NewH); $G.Dispose(); $Img.Dispose()
                if (Test-Path $Global:AvatarFile) { Remove-Item $Global:AvatarFile -Force }
                $Bmp.Save($Global:AvatarFile, [System.Drawing.Imaging.ImageFormat]::Png)
                $Pic.Image = $Bmp
            } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi xử lý ảnh!") }
        }
    })
    $ProfForm.Controls.Add($BtnUpload)

    $L_Email = New-Object System.Windows.Forms.Label; $L_Email.Text = "📧 Email: $($Global:UserEmail)"; $L_Email.Location="160, 30"; $L_Email.AutoSize=$true; $L_Email.Font="Segoe UI, 10, Bold"; $ProfForm.Controls.Add($L_Email)
    $L_Plan = New-Object System.Windows.Forms.Label; $L_Plan.Text = "💎 Gói: $($Global:LicenseType)"; $L_Plan.Location="160, 65"; $L_Plan.AutoSize=$true; $L_Plan.Font="Segoe UI, 10, Bold"; $L_Plan.ForeColor="Lime"; $ProfForm.Controls.Add($L_Plan)
    
    $BtnChangeLocal = New-Object System.Windows.Forms.Button; $BtnChangeLocal.Text="🔑 Đổi Pass Tool (Cấp 2)"; $BtnChangeLocal.Location="160, 105"; $BtnChangeLocal.Size="200, 35"; $BtnChangeLocal.BackColor="OrangeRed"; $BtnChangeLocal.FlatStyle="Flat"
    $BtnChangeLocal.Add_Click({
        $Old = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập Pass Cấp 2 hiện tại (Hoặc Master Pass):", "Xác thực")
        if ($Old -eq $Global:LocalPass -or $Old -eq $Global:ServerPass) {
            $New = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập Mật mã Cấp 2 MỚI cho máy này:", "Đổi Mật Mã")
            if ($New) { $Global:LocalPass = $New; Save-Session $Global:UserEmail $Global:LicenseType $Global:MyHWID $Global:LocalPass $Global:ServerPass; [System.Windows.Forms.MessageBox]::Show("Đổi Mật mã thành công!") }
        } elseif ($Old) { [System.Windows.Forms.MessageBox]::Show("Sai Mật mã!", "Lỗi") }
    })
    $ProfForm.Controls.Add($BtnChangeLocal)

    $ProfForm.ShowDialog() | Out-Null
})
$PnlHeader.Controls.Add($BtnProfile)

$BtnTheme = New-Object System.Windows.Forms.Button; $BtnTheme.Location="900, 25"; $BtnTheme.Size="140, 35"; $BtnTheme.FlatStyle="Flat"; $BtnTheme.Font="Segoe UI, 9, Bold"; $BtnTheme.Cursor="Hand"; $BtnTheme.Add_Click({ $Global:IsDarkMode = -not $Global:IsDarkMode; Apply-Theme }); $PnlHeader.Controls.Add($BtnTheme)

$TabControl = New-Object System.Windows.Forms.TabControl; $TabControl.Location="20,90"; $TabControl.Size="1020,480"; $TabControl.Font="Segoe UI, 10, Bold"; $TabControl.Multiline=$true; $TabControl.SizeMode="FillToRight"; $TabControl.Padding=New-Object System.Drawing.Point(20,5); $TabControl.ItemSize=New-Object System.Drawing.Size(0,40); $Form.Controls.Add($TabControl)

$AdvTab = New-Object System.Windows.Forms.TabPage; $AdvTab.Text=" DASHBOARD "; $AdvTab.AutoScroll=$true; $TabControl.Controls.Add($AdvTab)
function Add-Card ($T, $N, $X, $Y, $W, $H) { $P=New-Object System.Windows.Forms.Panel; $P.Name="Card_$N"; $P.Location="$X,$Y"; $P.Size="$W,$H"; $P.Padding="7,7,7,7"; $P.Add_Paint($Paint_Glow); $L=New-Object System.Windows.Forms.Label; $L.Text=$T; $L.Location="15,15"; $L.AutoSize=$true; $L.Font="Segoe UI, 13, Bold"; $P.Controls.Add($L); $F=New-Object System.Windows.Forms.FlowLayoutPanel; $F.Location="5,50"; $F.Size="$($W-10),$($H-60)"; $F.FlowDirection="TopDown"; $F.WrapContents=$true; $F.Padding="5,0,0,0"; $P.Controls.Add($F); $AdvTab.Controls.Add($P); return $F }

$P1 = Add-Card "HỆ THỐNG" "SYSTEM" 15 20 320 400
Add-Btn $P1 "ℹ KIỂM TRA CẤU HÌNH"      { Load-Module "SystemInfo.ps1" } | Out-Null
Add-Btn $P1 "♻ DỌN RÁC MÁY TÍNH"       { Load-Module "SystemCleaner.ps1" } | Out-Null
Add-Btn $P1 "💾 QUẢN LÝ Ổ ĐĨA"    { Load-Module "DiskManager.ps1" } | Out-Null
Add-Btn $P1 "🔍 QUÉT LỖI WINDOWS"     { Load-Module "SystemScan.ps1" } | Out-Null
Add-Btn $P1 "⚡ TỐI ƯU RAM"       { Load-Module "RamBooster.ps1" } | Out-Null
Add-Btn $P1 "🗝 KÍCH HOẠT BẢN QUYỀN"    { Load-Module "WinActivator.ps1" } | Out-Null
Add-Btn $P1 "🚑 CỨU DỮ LIỆU(HDD)" { Tai-Va-Chay "Disk.Genius.rar" "DiskGenius.rar" "Portable" } $true | Out-Null # Cờ $true = Cần VIP
Add-Btn $P1 "🗑 GỠ APP RÁC"       { Load-Module "Debloater.ps1" } | Out-Null
Add-Btn $P1 "🛠️ Tùy chỉnh Windows" { Load-Module "WinSettings.ps1" } | Out-Null
Add-Btn $P1 "🔧 SỬA LỖI HỆ THỐNG" { Load-Module "SystemRepair.ps1" } | Out-Null
Add-Btn $P1 "🔎 QUÉT TẬP TIN"     { Load-Module "FileScanner.ps1" } | Out-Null

$P2 = Add-Card "BẢO MẬT" "SECURITY" 350 20 320 400
Add-Btn $P2 "🌐 ĐỔI DNS SIÊU TỐC"    { Load-Module "NetworkMaster.ps1" } | Out-Null
Add-Btn $P2 "↻ QUẢN LÝ UPDATE"    { Load-Module "WinUpdatePro.ps1" } | Out-Null
Add-Btn $P2 "🛡 DEFENDER ON/OFF"  { Load-Module "DefenderMgr.ps1" } | Out-Null
Add-Btn $P2 "🛡 VÔ HIỆU HÓA EFSs"  { Load-Module "AntiEFS_GUI.ps1" } $true | Out-Null # Cần VIP
Add-Btn $P2 "🔒 KHÓA BITLOCKER"  { Load-Module "BitLockerMgr.ps1" } $true | Out-Null # Cần VIP
Add-Btn $P2 "⛔ CHẶN WEB ĐỘC"     { Load-Module "BrowserPrivacy.ps1" } | Out-Null
Add-Btn $P2 "🔥 TẮT TƯỜNG LỬA"    { netsh advfirewall set allprofiles state off; [System.Windows.Forms.MessageBox]::Show("Đã Tắt Firewall!") } | Out-Null

$P3 = Add-Card "CÀI ĐẶT" "INSTALL" 685 20 320 400
Add-Btn $P3 "💿 CÀI WIN TỰ ĐỘNG"     { Load-Module "WinInstall.ps1" } $true | Out-Null # Cần VIP
Add-Btn $P3 "📝 CÀI OFFICE 365"   { Load-Module "OfficeInstaller.ps1" } $true | Out-Null # Cần VIP
Add-Btn $P3 "🔧 TỐI ƯU HÓA WIN"       { Load-Module "WinModder.ps1" } | Out-Null
Add-Btn $P3 "📦 ĐÓNG GÓI ISO"     { Load-Module "WinAIOBuilder.ps1" } $true | Out-Null # Cần VIP
Add-Btn $P3 "🤖 TRỢ LÝ AI"        { Load-Module "GeminiAI.ps1" } | Out-Null
Add-Btn $P3 "👜 CÀI STORE"        { Load-Module "AppStore.ps1" } | Out-Null
Add-Btn $P3 "📥 TẢI ISO GỐC"      { Load-Module "ISODownloader.ps1" } | Out-Null
Add-Btn $P3 "⚡ TẠO USB BOOT"      { Load-Module "UsbBootMaker.ps1" } | Out-Null
Add-Btn $P3 "🍏 JAILBREAK iOS"       { Load-Module "iOS_Jailbreak.ps1" } $true | Out-Null # Cần VIP

# --- KHÔI PHỤC TÍNH NĂNG ĐỌC JSON TẠO TABS ---
try { 
    $Ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $Data = Invoke-RestMethod -Uri "$($JsonUrl)?t=$Ts" -Headers @{"User-Agent"="Titan/20"} -ErrorAction Stop 
    $JsonTabs = $Data | Select -ExpandProperty tab -Unique
    foreach ($T in $JsonTabs) {
        $Page = New-Object System.Windows.Forms.TabPage; $Page.Text=" " + $T.ToUpper() + " "; $Page.AutoScroll=$true; $TabControl.Controls.Add($Page)
        $Flow = New-Object System.Windows.Forms.FlowLayoutPanel; $Flow.Dock="Fill"; $Flow.AutoScroll=$true; $Flow.Padding="20,20,20,20"; $Page.Controls.Add($Flow)
        $Apps = $Data | Where-Object {$_.tab -eq $T}
        foreach ($A in $Apps) { $Chk = New-Object System.Windows.Forms.CheckBox; $Chk.Text=$A.name; $Chk.Tag=$A; $Chk.AutoSize=$true; $Chk.Margin="10,10,20,10"; $Chk.Font="Segoe UI, 11"; $Flow.Controls.Add($Chk) }
    }
} catch { Write-Log "Không thể tải cấu trúc JSON: $($_.Exception.Message)" "ERROR" }

# --- FOOTER (TÍCH HỢP ĐỦ: JSON INSTALLER, DONATE, BUY KEY) ---
$PnlFooter = New-Object System.Windows.Forms.Panel; $PnlFooter.Location="0,580"; $PnlFooter.Size="1080,160"; $PnlFooter.BackColor=[System.Drawing.Color]::FromArgb(25,25,30); $Form.Controls.Add($PnlFooter)
function Add-NeonFooterBtn ($P, $T, $X, $Y, $W, $H, $C, $Cmd) { $Pnl=New-Object System.Windows.Forms.Panel; $Pnl.Location="$X,$Y"; $Pnl.Size="$W,$H"; $Pnl.Tag=$C; $Pnl.Add_Paint($Paint_Glow); $Pnl.Padding="7,7,7,7"; $B=New-Object System.Windows.Forms.Button; $B.Text=$T; $B.Dock="Fill"; $B.FlatStyle="Flat"; $B.FlatAppearance.BorderSize=0; $B.BackColor=$C; $B.ForeColor="White"; $B.Font="Segoe UI, 10, Bold"; $B.Cursor="Hand"; $B.Tag=$C; $B.Add_Click($Cmd); Add-HoverEffect $B; $Pnl.Controls.Add($B); $P.Controls.Add($Pnl); return $B }

# Nút Checkbox
Add-NeonFooterBtn $PnlFooter "CHỌN HẾT" 20 20 120 45 "DeepSkyBlue" { foreach($P in $TabControl.TabPages){ foreach($F in $P.Controls){ foreach($C in $F.Controls){ if($C -is [System.Windows.Forms.CheckBox]){$C.Checked=$true} } } } } | Out-Null
Add-NeonFooterBtn $PnlFooter "BỎ CHỌN" 150 20 120 45 "Crimson" { foreach($P in $TabControl.TabPages){ foreach($F in $P.Controls){ foreach($C in $F.Controls){ if($C -is [System.Windows.Forms.CheckBox]){$C.Checked=$false} } } } } | Out-Null

# Khối xử lý cài đặt ngầm JSON
$ProgressBar = New-Object System.Windows.Forms.ProgressBar; $ProgressBar.Location="290,50"; $ProgressBar.Size="280,15"; $ProgressBar.Style="Continuous"; $PnlFooter.Controls.Add($ProgressBar)
$LblStatus = New-Object System.Windows.Forms.Label; $LblStatus.Location="285,75"; $LblStatus.AutoSize=$true; $LblStatus.Text="Trạng thái: Đang chờ lệnh..."; $LblStatus.Font="Segoe UI, 8, Italic"; $LblStatus.ForeColor="Silver"; $PnlFooter.Controls.Add($LblStatus)

$Global:SyncHash = [hashtable]::Synchronized(@{ Queue=@(); Total=0; Current=0; Progress=0; Status=""; IsDone=$false; BaseUrl=$BaseUrl; TempDir=$TempDir; LogFile=$LogFile; RawUrl=$RawUrl })
$TimerUpdate = New-Object System.Windows.Forms.Timer; $TimerUpdate.Interval = 200
$TimerUpdate.Add_Tick({ $ProgressBar.Value = $Global:SyncHash.Progress; $LblStatus.Text = $Global:SyncHash.Status; if ($Global:SyncHash.IsDone) { $TimerUpdate.Stop(); $BtnInstall.Text="CÀI ĐẶT ỨNG DỤNG"; $BtnInstall.Enabled=$true; $Global:SyncHash.IsDone=$false; [System.Windows.Forms.MessageBox]::Show("Hoàn tất cài đặt!", "Xong") } })

$BtnInstall = Add-NeonFooterBtn $PnlFooter "CÀI ĐẶT ỨNG DỤNG" 290 10 280 35 "ForestGreen" {
    $L = @(); foreach($P in $TabControl.TabPages){ foreach($F in $P.Controls){ foreach($C in $F.Controls){ if($C -is [System.Windows.Forms.CheckBox] -and $C.Checked){ $L += $C.Tag; $C.Checked=$false } } } }
    if ($L.Count -eq 0) { return }
    $BtnInstall.Enabled=$false; $BtnInstall.Text="ĐANG CHẠY NGẦM..."; $Global:SyncHash.Queue=$L; $Global:SyncHash.Total=$L.Count; $Global:SyncHash.Current=0; $Global:SyncHash.Progress=0; $Global:SyncHash.IsDone=$false; $TimerUpdate.Start()
    $Runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace(); $Runspace.Open(); $Runspace.SessionStateProxy.SetVariable("sync", $Global:SyncHash)
    $Pipeline = $Runspace.CreatePipeline(); $Pipeline.Commands.AddScript({
        $FDown = { param ($U, $O); if(Get-Command "curl.exe" -ErrorAction SilentlyContinue){$p=Start-Process "curl" "-L -o `"$O`" `"$U`" -s -k" -Wait -PassThru -WindowStyle Hidden; if($p.ExitCode -eq 0 -and (Test-Path $O)){return $true}}; try{Add-Type -AssemblyName System.Net.Http;$c=New-Object System.Net.Http.HttpClient;$r=$c.GetAsync($U).GetAwaiter().GetResult();if($r.IsSuccessStatusCode){$s=$r.Content.ReadAsStreamAsync().GetAwaiter().GetResult();$fs=[System.IO.File]::Create($O);$s.CopyTo($fs);$fs.Close();$s.Close();$c.Dispose();return $true}}catch{}; try{$w=New-Object System.Net.WebClient;$w.DownloadFile($U, $O);return $true}catch{return $false} }
        foreach ($A in $sync.Queue) {
            $sync.Current++; $sync.Status = "[$($sync.Current)/$($sync.Total)] $($A.name)..."; $sync.Progress = [math]::Round((($sync.Current - 1) / $sync.Total) * 100)
            if ($A.type -eq "Script") { try { Invoke-Expression $A.irm } catch {} } 
            else { $L = if ($A.link -notmatch "^http") { "$($sync.BaseUrl)$($A.link)" } else { $A.link }; $D = "$($sync.TempDir)\$($A.filename)"; if (&$FDown $L $D) { try { if ($A.type -eq "Msi") { Start-Process "msiexec.exe" "/i `"$D`" /quiet /norestart" -Wait -WindowStyle Hidden } else { Start-Process $D -Wait -WindowStyle Hidden }; if ($A.irm) { Invoke-Expression $A.irm } } catch {} } }
            $sync.Progress = [math]::Round(($sync.Current / $sync.Total) * 100)
        } $sync.Status = "Xong!"; $sync.IsDone = $true
    }) | Out-Null; $Pipeline.InvokeAsync()
}

$BtnDonate = New-Object System.Windows.Forms.Button; $BtnDonate.Text="☕ DONATE TÙY TÂM"; $BtnDonate.Location="600,20"; $BtnDonate.Size="200,45"; $BtnDonate.BackColor="LimeGreen"; $BtnDonate.ForeColor="White"; $BtnDonate.FlatStyle="Flat"; $BtnDonate.Font="Segoe UI, 10, Bold"
$BtnDonate.Add_Click({ $E = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập Email của bạn (để Admin ghi nhận vào hệ thống):", "Donate"); if ($E) { Show-QRPay 0 "DONATE" $E "QUÉT MÃ ĐỂ ỦNG HỘ" } })
$PnlFooter.Controls.Add($BtnDonate)

$BtnBuyKey = New-Object System.Windows.Forms.Button; $BtnBuyKey.Text="💎 CỬA HÀNG VIP"; $BtnBuyKey.Location="820,20"; $BtnBuyKey.Size="200,45"; $BtnBuyKey.BackColor="Gold"; $BtnBuyKey.ForeColor="Black"; $BtnBuyKey.FlatStyle="Flat"; $BtnBuyKey.Font="Segoe UI, 10, Bold"
$BtnBuyKey.Add_Click({ Show-Store })
$PnlFooter.Controls.Add($BtnBuyKey)

Apply-Theme; $Form.Add_Load({ Start-FadeIn }); $Form.ShowDialog() | Out-Null
