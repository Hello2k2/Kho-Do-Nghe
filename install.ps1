<#
    TOOL CUU HO MAY TINH - PHAT TAN PC
    Version: 19.0 Ultimate SaaS (Fileless Execution & Multi-Tier Billing)
    Author:  Phat Tan PC
#>

if ($host.Name -match "ISE") { Exit }
if ($MyInvocation.MyCommand.Path) { Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show("Truy cập trái phép! Vui lòng dùng lệnh tải từ Server.", "BẢO VỆ", 0, 16); Exit }
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://script.phattan.id.vn/tool/install.ps1 | iex`"" -Verb RunAs; Exit }

Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; Add-Type -AssemblyName Microsoft.VisualBasic
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; $ErrorActionPreference = "SilentlyContinue"

[System.Net.ServicePointManager]::Expect100Continue = $true
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13 -bor [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

function Get-HWID {
    $C = (Get-WmiObject Win32_Processor).ProcessorId; $B = (Get-WmiObject Win32_BaseBoard).SerialNumber; if (!$C) { $C = "VM" }; if (!$B) { $B = "VM" }
    $MD = [System.Security.Cryptography.MD5]::Create(); return ([System.BitConverter]::ToString($MD.ComputeHash([System.Text.Encoding]::UTF8.GetBytes("$C-$B"))) -replace "-", "").Substring(0, 16)
}
$Global:MyHWID = Get-HWID; $Global:PCName = $env:COMPUTERNAME
$EncAPI = "php.ipa/api/nv.di.nattahp.ipa//:sptth"; $Global:ApiServer = [string]::join('', ($EncAPI.ToCharArray()[($EncAPI.Length - 1)..0]))
$BaseUrl = "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/"
$EncRaw = "/loot/nv.di.nattahp.tpircs//:sptth"; $RawUrl = [string]::join('', ($EncRaw.ToCharArray()[($EncRaw.Length - 1)..0]))
$JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/apps.json"

$TempDir = "$env:TEMP\PhatTan_Tool"; $LogFile = "$TempDir\PhatTan_Toolkit.log"; if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }
function Write-Log ($Msg, $Type="INFO") { $Time = (Get-Date).ToString("HH:mm:ss dd/MM/yyyy"); "[$Time] [$Type] $Msg" | Out-File -FilePath $LogFile -Append -Encoding UTF8 }

$Global:SessionFile = "$env:LOCALAPPDATA\PhatTan_Titan.dat"
$Global:IsAuthenticated = $false; $Global:LicenseType = "NONE"; $Global:UserEmail = ""; $Global:LocalPass = "root"; $Global:ServerPass = "root"

# --- TITAN PAY GATEWAY ---
function Show-QRPay ($Amount, $Prefix, $Email, $TitleMsg) {
    $SafeEmail = $Email -replace "\s", ""; $Content = "$Prefix $SafeEmail"; $UrlContent = [uri]::EscapeDataString($Content)
    $QrUrl = "https://img.vietqr.io/image/970436-1055835227-qr_only.png?accountName=DANG%20LAM%20TAN%20PHAT&addInfo=$UrlContent"
    if ($Amount -gt 0) { $QrUrl += "&amount=$Amount" }

    $Q = New-Object System.Windows.Forms.Form; $Q.Size = "750, 480"; $Q.StartPosition = "CenterScreen"; $Q.Text = "TITAN SECURE PAY - $TitleMsg"; $Q.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 250); $Q.FormBorderStyle = "FixedToolWindow"
    $LblTop = New-Object System.Windows.Forms.Label; $LblTop.Text = "CỔNG THANH TOÁN TỰ ĐỘNG"; $LblTop.Dock = "Top"; $LblTop.TextAlign = "MiddleCenter"; $LblTop.Font = "Segoe UI, 16, Bold"; $LblTop.ForeColor = [System.Drawing.Color]::White; $LblTop.BackColor = [System.Drawing.Color]::FromArgb(0, 102, 204); $LblTop.Height = 60; $Q.Controls.Add($LblTop)

    $PnlQR = New-Object System.Windows.Forms.Panel; $PnlQR.Location = "20, 80"; $PnlQR.Size = "320, 320"; $PnlQR.BackColor = [System.Drawing.Color]::White; $PnlQR.BorderStyle = "FixedSingle"; $Q.Controls.Add($PnlQR)
    $Pic = New-Object System.Windows.Forms.PictureBox; $Pic.Location = "10,10"; $Pic.Size = "300, 300"; $Pic.SizeMode = "Zoom"; try { $Pic.Load($QrUrl) } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi mạng!") }; $PnlQR.Controls.Add($Pic)
    $LblSubQR = New-Object System.Windows.Forms.Label; $LblSubQR.Text = "Sử dụng App Ngân hàng để quét mã"; $LblSubQR.Location = "20, 410"; $LblSubQR.Size="320,20"; $LblSubQR.TextAlign = "MiddleCenter"; $LblSubQR.Font = "Segoe UI, 9, Italic"; $LblSubQR.ForeColor="Gray"; $Q.Controls.Add($LblSubQR)

    $PnlInfo = New-Object System.Windows.Forms.Panel; $PnlInfo.Location = "360, 80"; $PnlInfo.Size = "350, 320"; $PnlInfo.BackColor = [System.Drawing.Color]::White; $PnlInfo.BorderStyle = "FixedSingle"; $Q.Controls.Add($PnlInfo)
    $BankName = New-Object System.Windows.Forms.Label; $BankName.Text = "NGÂN HÀNG VIETCOMBANK"; $BankName.Location = "20,20"; $BankName.AutoSize=$true; $BankName.Font = "Segoe UI, 13, Bold"; $BankName.ForeColor=[System.Drawing.Color]::Green; $PnlInfo.Controls.Add($BankName)
    $L1 = New-Object System.Windows.Forms.Label; $L1.Text = "Chủ tài khoản:"; $L1.Location = "20, 60"; $L1.AutoSize=$true; $L1.Font = "Segoe UI, 10"; $L1.ForeColor="Gray"; $PnlInfo.Controls.Add($L1); $V1 = New-Object System.Windows.Forms.Label; $V1.Text = "DANG LAM TAN PHAT"; $V1.Location = "20, 80"; $V1.AutoSize=$true; $V1.Font = "Segoe UI, 12, Bold"; $PnlInfo.Controls.Add($V1)
    $L2 = New-Object System.Windows.Forms.Label; $L2.Text = "Số tài khoản:"; $L2.Location = "20, 120"; $L2.AutoSize=$true; $L2.Font = "Segoe UI, 10"; $L2.ForeColor="Gray"; $PnlInfo.Controls.Add($L2); $V2 = New-Object System.Windows.Forms.TextBox; $V2.Text = "1055835227"; $V2.Location = "20, 140"; $V2.Size="230,25"; $V2.Font = "Segoe UI, 12, Bold"; $V2.ReadOnly=$true; $V2.BackColor="White"; $V2.BorderStyle="None"; $PnlInfo.Controls.Add($V2)
    $BtnCpy1 = New-Object System.Windows.Forms.Button; $BtnCpy1.Text="Copy"; $BtnCpy1.Location="260,135"; $BtnCpy1.Size="70,30"; $BtnCpy1.BackColor="LightGray"; $BtnCpy1.FlatStyle="Flat"; $BtnCpy1.Add_Click({ [System.Windows.Forms.Clipboard]::SetText("1055835227"); $BtnCpy1.Text="Đã Copy!" }); $PnlInfo.Controls.Add($BtnCpy1)
    $L3 = New-Object System.Windows.Forms.Label; $L3.Text = "Số tiền cần chuyển:"; $L3.Location = "20, 180"; $L3.AutoSize=$true; $L3.Font = "Segoe UI, 10"; $L3.ForeColor="Gray"; $PnlInfo.Controls.Add($L3); $AmtStr = if($Amount -gt 0){"{0:N0} VNĐ" -f $Amount}else{"TÙY TÂM NHẬP SỐ TIỀN"}; $V3 = New-Object System.Windows.Forms.Label; $V3.Text = $AmtStr; $V3.Location = "20, 200"; $V3.AutoSize=$true; $V3.Font = "Segoe UI, 14, Bold"; $V3.ForeColor="Red"; $PnlInfo.Controls.Add($V3)
    $L4 = New-Object System.Windows.Forms.Label; $L4.Text = "Nội dung (BẮT BUỘC ĐÚNG):"; $L4.Location = "20, 245"; $L4.AutoSize=$true; $L4.Font = "Segoe UI, 10"; $L4.ForeColor="Gray"; $PnlInfo.Controls.Add($L4); $V4 = New-Object System.Windows.Forms.TextBox; $V4.Text = $Content; $V4.Location = "20, 265"; $V4.Size="230,25"; $V4.Font = "Segoe UI, 10, Bold"; $V4.ReadOnly=$true; $V4.BackColor="White"; $V4.BorderStyle="None"; $V4.ForeColor="Blue"; $PnlInfo.Controls.Add($V4)
    $BtnCpy2 = New-Object System.Windows.Forms.Button; $BtnCpy2.Text="Copy"; $BtnCpy2.Location="260,260"; $BtnCpy2.Size="70,30"; $BtnCpy2.BackColor="LightGray"; $BtnCpy2.FlatStyle="Flat"; $BtnCpy2.Add_Click({ [System.Windows.Forms.Clipboard]::SetText($Content); $BtnCpy2.Text="Đã Copy!" }); $PnlInfo.Controls.Add($BtnCpy2)
    $Warn = New-Object System.Windows.Forms.Label; $Warn.Text = "⚠️ Vui lòng giữ nguyên nội dung chuyển khoản để Server tự động nâng cấp gói cho tài khoản."; $Warn.Location = "360, 410"; $Warn.Size="350,40"; $Warn.Font = "Segoe UI, 9"; $Warn.ForeColor="OrangeRed"; $Q.Controls.Add($Warn)

    $Q.ShowDialog() | Out-Null
}

function Call-API ($Action, $Payload) { try { $Payload.Add("action", $Action); return Invoke-RestMethod -Uri $Global:ApiServer -Method Post -Body ($Payload | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 15 } catch { Write-Log "API Error: $_" "ERROR"; return @{ status="error"; message="Mất kết nối Máy chủ!" } } }
function Save-Session ($E, $T, $H, $LP, $SP) { $R = "$E|PT|$T|PC|$H|LP|$LP|SP|$SP"; $B = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($R)); [string]::join('', ($B.ToCharArray()[($B.Length - 1)..0])) | Out-File $Global:SessionFile -Force }
function Load-Session {
    if (Test-Path $Global:SessionFile) {
        try { $O = Get-Content $Global:SessionFile -Raw; $R = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String([string]::join('', ($O.ToCharArray()[($O.Length - 1)..0])))); $P = $R -split "\|"; if ($P[4] -eq $Global:MyHWID) { $Global:UserEmail = $P[0]; $Global:LicenseType = $P[2]; $Global:LocalPass = $P[6]; $Global:ServerPass = $P[8]; return $true } else { Remove-Item $Global:SessionFile -Force; return $false } } catch { return $false }
    } return $false
}

function Show-AuthGateway {
    $Auth = New-Object System.Windows.Forms.Form; $Auth.Text = "TITAN ENGINE V19.0 | HWID: $($Global:MyHWID)"; $Auth.Size = "500, 680"; $Auth.StartPosition = "CenterScreen"; $Auth.FormBorderStyle = "FixedToolWindow"; $Auth.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 18); $Auth.ForeColor = "White"
    $LTitle = New-Object System.Windows.Forms.Label; $LTitle.Text = "TITAN TOOLKIT LOGIN"; $LTitle.Font = "Segoe UI, 18, Bold"; $LTitle.ForeColor = "DeepSkyBlue"; $LTitle.AutoSize = $true; $LTitle.Location = "105, 15"; $Auth.Controls.Add($LTitle)

    # LOGIN PANEL
    $PnlLogin = New-Object System.Windows.Forms.Panel; $PnlLogin.Size = "460, 600"; $PnlLogin.Location = "10, 60"; $Auth.Controls.Add($PnlLogin)
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
        } else { [System.Windows.Forms.MessageBox]::Show("Nhập đủ thông tin!") }
    })

    $BForgot = New-Object System.Windows.Forms.Button; $BForgot.Text="Quên mật khẩu?"; $BForgot.Location="20,185"; $BForgot.Size="200,30"; $BForgot.BackColor="Transparent"; $BForgot.ForeColor="LightSkyBlue"; $BForgot.FlatStyle="Flat"; $BForgot.FlatAppearance.BorderSize=0; $PnlLogin.Controls.Add($BForgot)
    $BShowReg = New-Object System.Windows.Forms.Button; $BShowReg.Text="Tạo tài khoản mới"; $BShowReg.Location="240,185"; $BShowReg.Size="200,30"; $BShowReg.BackColor="DimGray"; $BShowReg.FlatStyle="Flat"; $PnlLogin.Controls.Add($BShowReg)

    # BẢNG GIÁ SAAS CHUYÊN NGHIỆP
    $GFree = New-Object System.Windows.Forms.GroupBox; $GFree.Text=" CỬA HÀNG & BẢNG GIÁ "; $GFree.Location="20,230"; $GFree.Size="420,330"; $GFree.ForeColor="Lime"; $PnlLogin.Controls.Add($GFree)
    
    $BTrial = New-Object System.Windows.Forms.Button; $BTrial.Text="🎁 LẤY / GIA HẠN KEY 7 NGÀY (Cần Donate)"; $BTrial.Location="15,25"; $BTrial.Size="390,35"; $BTrial.BackColor="DarkMagenta"; $BTrial.ForeColor="White"; $BTrial.FlatStyle="Flat"; $GFree.Controls.Add($BTrial)
    $BTrial.Add_Click({ $E = [Microsoft.VisualBasic.Interaction]::InputBox("Hệ thống tự động Check lượng Donate để cấp Key.`nNhập Email của bạn:", "Nhận Key"); if ($E) { $Auth.Cursor = "WaitCursor"; $R = Call-API "request_trial" @{ email=$E }; [System.Windows.Forms.MessageBox]::Show($R.message, "Thông báo"); $Auth.Cursor = "Default" } })
    
    # Hàng 1: 1 Tháng & 6 Tháng
    $B1M = New-Object System.Windows.Forms.Button; $B1M.Text="🥉 VIP 1 THÁNG`n(29.000đ)"; $B1M.Location="15,70"; $B1M.Size="190,50"; $B1M.BackColor="MediumSeaGreen"; $B1M.ForeColor="White"; $B1M.Font="Segoe UI, 9, Bold"; $B1M.FlatStyle="Flat"; $GFree.Controls.Add($B1M)
    $B1M.Add_Click({ $E = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập Email cần nạp VIP 1 THÁNG:", "Mua Key"); if ($E) { Show-QRPay 29000 "MUA KEY 1M" $E "VIP 1 THÁNG" } })

    $B6M = New-Object System.Windows.Forms.Button; $B6M.Text="🥈 VIP 6 THÁNG`n(149.000đ)"; $B6M.Location="215,70"; $B6M.Size="190,50"; $B6M.BackColor="DodgerBlue"; $B6M.ForeColor="White"; $B6M.Font="Segoe UI, 9, Bold"; $B6M.FlatStyle="Flat"; $GFree.Controls.Add($B6M)
    $B6M.Add_Click({ $E = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập Email cần nạp VIP 6 THÁNG:", "Mua Key"); if ($E) { Show-QRPay 149000 "MUA KEY 6M" $E "VIP 6 THÁNG" } })

    # Hàng 2: Vĩnh viễn & Family
    $BFull = New-Object System.Windows.Forms.Button; $BFull.Text="💎 VIP VĨNH VIỄN`n(200.000đ - 5 PC)"; $BFull.Location="15,130"; $BFull.Size="190,50"; $BFull.BackColor="Gold"; $BFull.ForeColor="Black"; $BFull.Font="Segoe UI, 9, Bold"; $BFull.FlatStyle="Flat"; $GFree.Controls.Add($BFull)
    $BFull.Add_Click({ $E = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập Email cần nạp VIP VĨNH VIỄN:", "Mua Key"); if ($E) { Show-QRPay 200000 "MUA KEY VIP" $E "VIP VĨNH VIỄN" } })

    $BFam = New-Object System.Windows.Forms.Button; $BFam.Text="👑 ĐẠI LÝ / FAMILY`n(800.000đ - 25 PC)"; $BFam.Location="215,130"; $BFam.Size="190,50"; $BFam.BackColor="DarkOrange"; $BFam.ForeColor="Black"; $BFam.Font="Segoe UI, 9, Bold"; $BFam.FlatStyle="Flat"; $GFree.Controls.Add($BFam)
    $BFam.Add_Click({ $E = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập Email cần nâng cấp GÓI ĐẠI LÝ:", "Mua Key"); if ($E) { Show-QRPay 800000 "MUA KEY MULTI" $E "GÓI ĐẠI LÝ" } })

    $BDraw = New-Object System.Windows.Forms.Label; $BDraw.Text="----------------------------------------------------------"; $BDraw.Location="15,190"; $BDraw.Size="390,20"; $BDraw.ForeColor="Gray"; $GFree.Controls.Add($BDraw)

    $BFree = New-Object System.Windows.Forms.Button; $BFree.Text="⏱️ Mở Tool Trải Nghiệm (Free 30 Phút)"; $BFree.Location="15,215"; $BFree.Size="390,35"; $BFree.BackColor="Teal"; $BFree.ForeColor="White"; $BFree.FlatStyle="Flat"; $GFree.Controls.Add($BFree)
    $BFree.Add_Click({ [System.Windows.Forms.MessageBox]::Show("Chế độ Free bị KHÓA CÁC TÍNH NĂNG VIP."); $Global:IsAuthenticated=$true; $Global:LicenseType="FREE_30M"; $env:TITAN_AUTH_TOKEN = [System.Guid]::NewGuid().ToString(); $Auth.Close() })

    # ĐĂNG KÝ
    $PnlReg = New-Object System.Windows.Forms.Panel; $PnlReg.Size = "420, 480"; $PnlReg.Location = "10, 60"; $PnlReg.Visible = $false; $Auth.Controls.Add($PnlReg)
    $R1=New-Object System.Windows.Forms.Label;$R1.Text="Họ tên:";$R1.Location="20,0";$R1.AutoSize=$true;$PnlReg.Controls.Add($R1); $TRName=New-Object System.Windows.Forms.TextBox;$TRName.Location="20,20";$TRName.Size="380,25";$PnlReg.Controls.Add($TRName)
    $R2=New-Object System.Windows.Forms.Label;$R2.Text="Email (Bắt buộc đúng để nhận OTP):";$R2.Location="20,50";$R2.AutoSize=$true;$PnlReg.Controls.Add($R2); $TREmail=New-Object System.Windows.Forms.TextBox;$TREmail.Location="20,70";$TREmail.Size="380,25";$PnlReg.Controls.Add($TREmail)
    $R3=New-Object System.Windows.Forms.Label;$R3.Text="Mật khẩu:";$R3.Location="20,100";$R3.AutoSize=$true;$PnlReg.Controls.Add($R3); $TRPass=New-Object System.Windows.Forms.TextBox;$TRPass.Location="20,120";$TRPass.Size="380,25";$TRPass.PasswordChar="*";$PnlReg.Controls.Add($TRPass)
    $R4=New-Object System.Windows.Forms.Label;$R4.Text="Câu hỏi bảo mật:";$R4.Location="20,150";$R4.AutoSize=$true;$PnlReg.Controls.Add($R4); $CSec=New-Object System.Windows.Forms.ComboBox;$CSec.Location="20,170";$CSec.Size="380,25";$CSec.DropDownStyle="DropDownList"; $CSec.Items.AddRange(@("Con vật yêu thích?","Tên trường cấp 1?","Người yêu cũ?"));$CSec.SelectedIndex=0;$PnlReg.Controls.Add($CSec)
    $R5=New-Object System.Windows.Forms.Label;$R5.Text="Trả lời:";$R5.Location="20,200";$R5.AutoSize=$true;$PnlReg.Controls.Add($R5); $TRAns=New-Object System.Windows.Forms.TextBox;$TRAns.Location="20,220";$TRAns.Size="380,25";$PnlReg.Controls.Add($TRAns)

    $BReg = New-Object System.Windows.Forms.Button; $BReg.Text="ĐĂNG KÝ TÀI KHOẢN"; $BReg.Location="20,265"; $BReg.Size="380,40"; $BReg.BackColor="Green"; $BReg.ForeColor="White"; $BReg.FlatStyle="Flat"; $PnlReg.Controls.Add($BReg)
    $BReg.Add_Click({
        $Auth.Cursor = "WaitCursor"; $R = Call-API "register" @{ name=$TRName.Text; email=$TREmail.Text; password=$TRPass.Text; question=$CSec.Text; answer=$TRAns.Text }
        if ($R.status -eq "success") { [System.Windows.Forms.MessageBox]::Show("Tạo thành công!"); $PnlReg.Visible=$false; $PnlLogin.Visible=$true } else { [System.Windows.Forms.MessageBox]::Show($R.message) }
        $Auth.Cursor = "Default"
    })
    $BBack = New-Object System.Windows.Forms.Button; $BBack.Text="Quay lại"; $BBack.Location="20,315"; $BBack.Size="380,35"; $BBack.BackColor="DimGray"; $BBack.FlatStyle="Flat"; $PnlReg.Controls.Add($BBack)
    $BShowReg.Add_Click({ $PnlLogin.Visible = $false; $PnlReg.Visible = $true }); $BBack.Add_Click({ $PnlReg.Visible = $false; $PnlLogin.Visible = $true })
    
    $Auth.ShowDialog() | Out-Null
}

if (Load-Session) {
    $InputAES = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập Mật mã Tool Cấp 2 (Hoặc Master Pass từ Server):", "BẢO MẬT CỤC BỘ")
    if ($InputAES -eq $Global:LocalPass -or $InputAES -eq $Global:ServerPass) { $env:TITAN_AUTH_TOKEN = [System.Guid]::NewGuid().ToString() } 
    else { [System.Windows.Forms.MessageBox]::Show("Sai Mật mã Cấp 2! Tool sẽ thoát.", "LỖI", 0, 16); Exit }
} else { Show-AuthGateway }

if (-not $Global:IsAuthenticated) { Exit }

# --- 7. DOOM TIMER ---
$Global:TimeLeft = 1800 
if ($Global:LicenseType -eq "FREE_30M") {
    $Script:DoomTimer = New-Object System.Windows.Forms.Timer; $Script:DoomTimer.Interval = 1000
    $Script:DoomTimer.Add_Tick({
        $Global:TimeLeft--; if ($Global:TimeLeft -le 0) { $Script:DoomTimer.Stop(); [System.Windows.Forms.MessageBox]::Show("HẾT THỜI GIAN DÙNG THỬ! Vui lòng mua Key.", "HẾT HẠN", 0, 16); Remove-Item $Global:SessionFile -Force; [Environment]::Exit(0) }
        $m = [math]::Floor($Global:TimeLeft / 60); $s = $Global:TimeLeft % 60; $Form.Text = "PHAT TAN PC TOOLKIT V19.0 | TRẢI NGHIỆM FREE - HẾT HẠN SAU: $m phút $s giây"
    }); $Script:DoomTimer.Start()
}

function Invoke-SmartDownload ($Url, $OutFile) {
    if (Get-Command "curl.exe" -ErrorAction SilentlyContinue) { $p = Start-Process "curl" "-L -o `"$OutFile`" `"$Url`" -s --retry 3 -k" -Wait -PassThru -WindowStyle Hidden; if ($p.ExitCode -eq 0 -and (Test-Path $OutFile)) { return $true } }
    try { Add-Type -AssemblyName System.Net.Http; $c = New-Object System.Net.Http.HttpClient; $r = $c.GetAsync($Url).GetAwaiter().GetResult(); if ($r.IsSuccessStatusCode) { $s = $r.Content.ReadAsStreamAsync().GetAwaiter().GetResult(); $fs = [System.IO.File]::Create($OutFile); $s.CopyTo($fs); $fs.Close(); $s.Close(); $c.Dispose(); return $true } } catch {}
    try { $w = New-Object System.Net.WebClient; $w.DownloadFile($Url, $OutFile); return $true } catch { return $false }
}
function Tai-Va-Chay { param ($L, $N, $T); if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }; if ($L -notmatch "^http") { $L = "$BaseUrl$L" }; $D = "$TempDir\$N"; if (Invoke-SmartDownload $L $D) { if ($T -eq "Msi") { Start-Process "msiexec.exe" "/i `"$D`" /quiet /norestart" -Wait } else { Start-Process $D -Wait } } }

# ==============================================================================
# BỘ CÔNG CỤ TẢI XUỐNG VÀ CHẠY ẢO TRÊN RAM (FILELESS EXECUTION)
# ==============================================================================
function Load-Module ($N) { 
    try { 
        $W = New-Object System.Net.WebClient; $W.Headers.Add("User-Agent", "Titan/19"); $W.Encoding = [System.Text.Encoding]::UTF8
        # Tải Code dạng Text thuần từ máy chủ
        $RawCode = $W.DownloadString("$RawUrl$N`?t=$(Get-Date -UFormat %s)")
        
        # Ép kiểu và tự động Nén Base64 ngay trên RAM
        $Bytes = [System.Text.Encoding]::Unicode.GetBytes($RawCode)
        $EncodedCode = [Convert]::ToBase64String($Bytes)
        
        # Bắn lệnh vào một Process PowerShell chạy ẩn, tuyệt đối không lưu ra ổ cứng
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $EncodedCode" 
    } catch { [System.Windows.Forms.MessageBox]::Show("Tải module $N thất bại!", "Lỗi") } 
}

$Global:IsDarkMode = $true 
$Theme = @{ Dark=@{ Back=[System.Drawing.Color]::FromArgb(25,25,30); Card=[System.Drawing.Color]::FromArgb(40,40,45); Text=[System.Drawing.Color]::WhiteSmoke; System=[System.Drawing.Color]::FromArgb(0,190,255); Security=[System.Drawing.Color]::FromArgb(180,80,255); Install=[System.Drawing.Color]::FromArgb(50,230,130) }; Light=@{ Back=[System.Drawing.Color]::FromArgb(245,245,250); Card=[System.Drawing.Color]::White; Text=[System.Drawing.Color]::Black; System=[System.Drawing.Color]::FromArgb(0,120,215); Security=[System.Drawing.Color]::FromArgb(138,43,226); Install=[System.Drawing.Color]::FromArgb(34,139,34) } }
$Paint_Glow = { param($s, $e); $C = $s.Tag; if(!$C){$C=[System.Drawing.Color]::Gray}; $P = New-Object System.Drawing.Pen($C, 5); $R = $s.ClientRectangle; $R.X+=2; $R.Y+=2; $R.Width-=4; $R.Height-=4; $e.Graphics.DrawRectangle($P, $R); $P.Dispose() }
function Apply-Theme { $T=if($Global:IsDarkMode){$Theme.Dark}else{$Theme.Light}; $Form.BackColor=$T.Back; $Form.ForeColor=$T.Text; $PnlHeader.BackColor=if($Global:IsDarkMode){[System.Drawing.Color]::FromArgb(35,35,40)}else{[System.Drawing.Color]::FromArgb(230,230,230)}; $BtnTheme.Text=if($Global:IsDarkMode){"☀ LIGHT"}else{"🌙 DARK"}; $BtnTheme.BackColor=if($Global:IsDarkMode){[System.Drawing.Color]::White}else{[System.Drawing.Color]::Black}; $BtnTheme.ForeColor=if($Global:IsDarkMode){[System.Drawing.Color]::Black}else{[System.Drawing.Color]::White}; foreach($P in $TabControl.TabPages){$P.BackColor=$T.Back; $P.ForeColor=$T.Text; foreach($C in $P.Controls){if($C -is [System.Windows.Forms.Panel] -and $C.Name -like "Card*"){$C.BackColor=$T.Card; $G=$T.System; if($C.Name -match "SECURITY"){$G=$T.Security}; if($C.Name -match "INSTALL"){$G=$T.Install}; $C.Tag=$G; $C.Invalidate(); foreach($Child in $C.Controls){if($Child -is [System.Windows.Forms.Label]){$Child.ForeColor=$G}; if($Child -is [System.Windows.Forms.FlowLayoutPanel]){foreach($Btn in $Child.Controls){$Btn.BackColor=$G; $Btn.ForeColor="White"; $Btn.Tag=$G}}}}}}}
function Add-HoverEffect ($Btn) { $Btn.Add_MouseEnter({ if($this.Enabled){$this.BackColor=[System.Windows.Forms.ControlPaint]::Light($this.Tag, 0.6)} }); $Btn.Add_MouseLeave({ if($this.Enabled){$this.BackColor=$this.Tag} }) }

$Form = New-Object System.Windows.Forms.Form; 
$Form.Text = "PHAT TAN PC V19.0 | GÓI: $($Global:LicenseType) | User: $($Global:UserEmail)" 
$Form.Size = New-Object System.Drawing.Size(1080, 780); $Form.StartPosition = "CenterScreen"; $Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

$PnlHeader = New-Object System.Windows.Forms.Panel; $PnlHeader.Size="1080, 80"; $PnlHeader.Location="0,0"; $Form.Controls.Add($PnlHeader)
$LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text="PHAT TAN PC TOOLKIT"; $LblTitle.Font="Segoe UI, 24, Bold"; $LblTitle.AutoSize=$true; $LblTitle.Location="20,15"; $LblTitle.ForeColor=[System.Drawing.Color]::DeepSkyBlue; $PnlHeader.Controls.Add($LblTitle)
$LblSub = New-Object System.Windows.Forms.Label; $LblSub.Text="Enterprise Cloud Architecture - Current Plan: $($Global:LicenseType)"; $LblSub.ForeColor="Lime"; $LblSub.AutoSize=$true; $LblSub.Font="Segoe UI, 10, Italic"; $LblSub.Location="25,60"; $PnlHeader.Controls.Add($LblSub)

$BtnChangePass = New-Object System.Windows.Forms.Button; $BtnChangePass.Location="740, 25"; $BtnChangePass.Size="150, 35"; $BtnChangePass.FlatStyle="Flat"; $BtnChangePass.Font="Segoe UI, 9, Bold"; $BtnChangePass.Cursor="Hand"; $BtnChangePass.Text="🔑 ĐỔI PASS CẤP 2"; $BtnChangePass.BackColor="DimGray"; $BtnChangePass.ForeColor="White"
$BtnChangePass.Add_Click({
    $Old = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập Pass Cấp 2 hiện tại của máy (Hoặc Master Pass):", "Xác thực")
    if ($Old -eq $Global:LocalPass -or $Old -eq $Global:ServerPass) {
        $New = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập Mật mã Cấp 2 MỚI cho máy này:", "Đổi Mật Mã")
        if ($New) { $Global:LocalPass = $New; Save-Session $Global:UserEmail $Global:LicenseType $Global:MyHWID $Global:LocalPass $Global:ServerPass; [System.Windows.Forms.MessageBox]::Show("Đã đổi Mật mã Local thành công!", "Thành Công") }
    } elseif ($Old) { [System.Windows.Forms.MessageBox]::Show("Sai Mật mã hiện tại!", "Lỗi") }
})
$PnlHeader.Controls.Add($BtnChangePass)

$BtnTheme = New-Object System.Windows.Forms.Button; $BtnTheme.Location="900, 25"; $BtnTheme.Size="140, 35"; $BtnTheme.FlatStyle="Flat"; $BtnTheme.Font="Segoe UI, 9, Bold"; $BtnTheme.Cursor="Hand"; $BtnTheme.Add_Click({ $Global:IsDarkMode = -not $Global:IsDarkMode; Apply-Theme }); $PnlHeader.Controls.Add($BtnTheme)

$TabControl = New-Object System.Windows.Forms.TabControl; $TabControl.Location="20,90"; $TabControl.Size="1020,520"; $TabControl.Font="Segoe UI, 10, Bold"; $TabControl.Multiline=$true; $TabControl.SizeMode="FillToRight"; $TabControl.Padding=New-Object System.Drawing.Point(20,5); $TabControl.ItemSize=New-Object System.Drawing.Size(0,40); $Form.Controls.Add($TabControl)

$AdvTab = New-Object System.Windows.Forms.TabPage; $AdvTab.Text=" DASHBOARD "; $AdvTab.AutoScroll=$true; $TabControl.Controls.Add($AdvTab)
function Add-Card ($T, $N, $X, $Y, $W, $H) { $P=New-Object System.Windows.Forms.Panel; $P.Name="Card_$N"; $P.Location="$X,$Y"; $P.Size="$W,$H"; $P.Padding="7,7,7,7"; $P.Add_Paint($Paint_Glow); $L=New-Object System.Windows.Forms.Label; $L.Text=$T; $L.Location="15,15"; $L.AutoSize=$true; $L.Font="Segoe UI, 13, Bold"; $P.Controls.Add($L); $F=New-Object System.Windows.Forms.FlowLayoutPanel; $F.Location="5,50"; $F.Size="$($W-10),$($H-60)"; $F.FlowDirection="TopDown"; $F.WrapContents=$true; $F.Padding="5,0,0,0"; $P.Controls.Add($F); $AdvTab.Controls.Add($P); return $F }
function Add-Btn ($P, $T, $C) { $B=New-Object System.Windows.Forms.Button; $B.Text=$T; $B.Size="140,45"; $B.FlatStyle="Flat"; $B.Font="Segoe UI, 9, Bold"; $B.Margin="5,5,5,5"; $B.Cursor="Hand"; $B.FlatAppearance.BorderSize=0; $B.Add_Click($C); Add-HoverEffect $B; $P.Controls.Add($B); return $B }

$P1 = Add-Card "HỆ THỐNG" "SYSTEM" 15 20 320 400
Add-Btn $P1 "ℹ KIỂM TRA CẤU HÌNH"      { Load-Module "SystemInfo.ps1" } | Out-Null
Add-Btn $P1 "♻ DỌN RÁC MÁY TÍNH"       { Load-Module "SystemCleaner.ps1" } | Out-Null
Add-Btn $P1 "💾 QUẢN LÝ Ổ ĐĨA"    { Load-Module "DiskManager.ps1" } | Out-Null
Add-Btn $P1 "🔍 QUÉT LỖI WINDOWS"     { Load-Module "SystemScan.ps1" } | Out-Null
Add-Btn $P1 "⚡ TỐI ƯU RAM"       { Load-Module "RamBooster.ps1" } | Out-Null
Add-Btn $P1 "🗝 KÍCH HOẠT BẢN QUYỀN"    { Load-Module "WinActivator.ps1" } | Out-Null
$Btn_CuuDuLieu = Add-Btn $P1 "🚑 CỨU DỮ LIỆU(HDD)" { Tai-Va-Chay "Disk.Genius.rar" "DiskGenius.rar" "Portable" }
Add-Btn $P1 "🗑 GỠ APP RÁC"       { Load-Module "Debloater.ps1" } | Out-Null
Add-Btn $P1 "🛠️ Tùy chỉnh Windows" { Load-Module "WinSettings.ps1" } | Out-Null

$P2 = Add-Card "BẢO MẬT" "SECURITY" 350 20 320 400
Add-Btn $P2 "🌐 ĐỔI DNS SIÊU TỐC"    { Load-Module "NetworkMaster.ps1" } | Out-Null
Add-Btn $P2 "↻ QUẢN LÝ UPDATE"    { Load-Module "WinUpdatePro.ps1" } | Out-Null
Add-Btn $P2 "🛡 DEFENDER ON/OFF"  { Load-Module "DefenderMgr.ps1" } | Out-Null
$Btn_AntiEFS = Add-Btn $P2 "🛡 VÔ HIỆU HÓA EFSs"  { Load-Module "AntiEFS_GUI.ps1" }
$Btn_Bitlock = Add-Btn $P2 "🔒 KHÓA BITLOCKER"  { Load-Module "BitLockerMgr.ps1" }
Add-Btn $P2 "⛔ CHẶN WEB ĐỘC"     { Load-Module "BrowserPrivacy.ps1" } | Out-Null
Add-Btn $P2 "🔥 TẮT TƯỜNG LỬA"    { netsh advfirewall set allprofiles state off; [System.Windows.Forms.MessageBox]::Show("Đã Tắt Firewall!") } | Out-Null

$P3 = Add-Card "CÀI ĐẶT" "INSTALL" 685 20 320 400
$Btn_CaiWin = Add-Btn $P3 "💿 CÀI WIN TỰ ĐỘNG"     { Load-Module "WinInstall.ps1" }
$Btn_Office = Add-Btn $P3 "📝 CÀI OFFICE 365"   { Load-Module "OfficeInstaller.ps1" }
Add-Btn $P3 "🔧 TỐI ƯU HÓA WIN"       { Load-Module "WinModder.ps1" } | Out-Null
$Btn_DongGoi = Add-Btn $P3 "📦 ĐÓNG GÓI ISO"     { Load-Module "WinAIOBuilder.ps1" }
Add-Btn $P3 "🤖 TRỢ LÝ AI"        { Load-Module "GeminiAI.ps1" } | Out-Null
Add-Btn $P3 "👜 CÀI STORE"        { Load-Module "AppStore.ps1" } | Out-Null

# --- HỆ THỐNG NERF CHỈ BÓP FREE / FREE_30M ---
if ($Global:LicenseType -eq "FREE" -or $Global:LicenseType -eq "FREE_30M") {
    $BtnsToNerf = @($Btn_CaiWin, $Btn_Office, $Btn_DongGoi, $Btn_AntiEFS, $Btn_Bitlock, $Btn_CuuDuLieu)
    foreach ($b in $BtnsToNerf) { $b.Enabled = $false; $b.Text = "⛔ YÊU CẦU KEY VIP"; $b.BackColor = [System.Drawing.Color]::DimGray; $b.Cursor = "No" }
}

$PnlFooter = New-Object System.Windows.Forms.Panel; $PnlFooter.Location="0,620"; $PnlFooter.Size="1080,120"; $PnlFooter.BackColor=[System.Drawing.Color]::FromArgb(25,25,30); $Form.Controls.Add($PnlFooter)

# TÁCH ĐỘC LẬP 2 NÚT DONATE VÀ MUA BẢN QUYỀN
$BtnDonate = New-Object System.Windows.Forms.Button; $BtnDonate.Text="☕ DONATE TÙY TÂM"; $BtnDonate.Location="600,20"; $BtnDonate.Size="200,45"; $BtnDonate.BackColor="LimeGreen"; $BtnDonate.ForeColor="White"; $BtnDonate.FlatStyle="Flat"; $BtnDonate.Font="Segoe UI, 10, Bold"
$BtnDonate.Add_Click({ $E = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập Email của bạn (để Admin ghi nhận vào hệ thống):", "Donate"); if ($E) { Show-QRPay 0 "DONATE" $E "QUÉT MÃ ĐỂ ỦNG HỘ" } })
$PnlFooter.Controls.Add($BtnDonate)

$BtnBuyKey = New-Object System.Windows.Forms.Button; $BtnBuyKey.Text="💎 MUA BẢN QUYỀN"; $BtnBuyKey.Location="820,20"; $BtnBuyKey.Size="200,45"; $BtnBuyKey.BackColor="Gold"; $BtnBuyKey.ForeColor="Black"; $BtnBuyKey.FlatStyle="Flat"; $BtnBuyKey.Font="Segoe UI, 10, Bold"
$BtnBuyKey.Add_Click({ 
    [System.Windows.Forms.MessageBox]::Show("Để mua các gói:`n- VIP 1 Tháng: 29.000đ`n- VIP 6 Tháng: 149.000đ`n- VIP Vĩnh viễn: 200.000đ`n- Đại lý: 800.000đ`n`nVui lòng Đăng xuất -> Bấm vào Bảng Giá ở màn hình Đăng Nhập để chọn gói và thanh toán!", "HƯỚNG DẪN MUA KEY", 0, 64) 
})
$PnlFooter.Controls.Add($BtnBuyKey)

Apply-Theme; $Form.Add_Load({ Start-FadeIn }); $Form.ShowDialog() | Out-Null
