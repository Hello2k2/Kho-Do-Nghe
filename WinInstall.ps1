# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- ENCODING FIX (CONSOLE) ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- CONFIG ---
$RawUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/"
$TempDir = "$env:TEMP\PhatTan_Tool"
if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }

# --- GUI INIT ---
try { Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing } catch { Exit }

# Cấu hình Form
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "PHAT TAN PC - WINDOWS DEPLOYMENT SUITE"
$Form.Size = New-Object System.Drawing.Size(600, 450)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# --- FONTS ---
$FontTitle = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$FontSub   = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Italic) 
$FontBtn   = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$FontSmall = New-Object System.Drawing.Font("Consolas", 9)

# --- HÀM TẢI MODULE (CÔNG NGHỆ FIX BOM) ---
function Load-Mod ($Name) {
    $Form.Cursor = "WaitCursor" 
    $P = "$TempDir\$Name"
    try { 
        [System.Net.ServicePointManager]::SecurityProtocol = 3072
        $WC = New-Object Net.WebClient
        $WC.Encoding = [System.Text.Encoding]::UTF8
        
        # BƯỚC 1: Tải nội dung về RAM (String) thay vì tải thẳng ra file
        # Điều này giúp ta nắm trọn nội dung UTF-8 chuẩn từ GitHub
        $Content = $WC.DownloadString("$RawUrl$Name")
        
        # BƯỚC 2: Tự tay lưu xuống ổ cứng với chuẩn UTF-8 WITH BOM
        # [System.Text.Encoding]::UTF8 trong .NET Framework mặc định có BOM -> Fix được lỗi PowerShell 5.1
        [System.IO.File]::WriteAllText($P, $Content, [System.Text.Encoding]::UTF8)

        # BƯỚC 3: Mở khóa file (Unblock)
        Unblock-File -Path $P -ErrorAction SilentlyContinue

        # BƯỚC 4: Chạy file (Giờ nó đã có BOM, PowerShell sẽ đọc đúng Emoji/Tiếng Việt)
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$P`"" -Verb RunAs
    } catch { 
        [System.Windows.Forms.MessageBox]::Show("Lỗi tải Module: $Name `nChi tiết: $_", "Error") 
    }
    $Form.Cursor = "Default"
}

# --- HEADER ---
$LblHeader = New-Object System.Windows.Forms.Label
$LblHeader.Text = "PHAT TAN PC TOOLKIT"
$LblHeader.Font = $FontTitle
$LblHeader.ForeColor = [System.Drawing.Color]::Cyan
$LblHeader.AutoSize = $true
$LblHeader.Location = New-Object System.Drawing.Point(140, 20)
$Form.Controls.Add($LblHeader)

$LblSub = New-Object System.Windows.Forms.Label
$LblSub.Text = "CHUYÊN GIA CÀI ĐẶT WINDOWS & CỨU HỘ"
$LblSub.Font = $FontSmall
$LblSub.ForeColor = [System.Drawing.Color]::LightGray
$LblSub.AutoSize = $true
$LblSub.Location = New-Object System.Drawing.Point(150, 60)
$Form.Controls.Add($LblSub)

# --- PANEL ---
$Panel = New-Object System.Windows.Forms.Panel
$Panel.Size = New-Object System.Drawing.Size(500, 250)
$Panel.Location = New-Object System.Drawing.Point(40, 100)
$Panel.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$Form.Controls.Add($Panel)

# --- NÚT 1: CẤU HÌNH ---
$BtnCfg = New-Object System.Windows.Forms.Button
$BtnCfg.Text = "1. CẤU HÌNH FILE TỰ ĐỘNG`n(Tạo file XML: User, Key, Disk...)"
$BtnCfg.Font = $FontBtn
$BtnCfg.Location = New-Object System.Drawing.Point(20, 20)
$BtnCfg.Size = New-Object System.Drawing.Size(460, 80)
$BtnCfg.FlatStyle = "Flat"
$BtnCfg.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204) 
$BtnCfg.ForeColor = "White"
$BtnCfg.Cursor = "Hand"
$BtnCfg.Add_MouseEnter({ $BtnCfg.BackColor = [System.Drawing.Color]::FromArgb(28, 151, 234) })
$BtnCfg.Add_MouseLeave({ $BtnCfg.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204) })
$BtnCfg.Add_Click({ Load-Mod "WinInstall_Config.ps1" })
$Panel.Controls.Add($BtnCfg)

# --- NÚT 2: CÀI ĐẶT ---
$BtnRun = New-Object System.Windows.Forms.Button
$BtnRun.Text = "2. TIẾN HÀNH CÀI ĐẶT`n(Mount ISO, Backup Driver, Cài Win)"
$BtnRun.Font = $FontBtn
$BtnRun.Location = New-Object System.Drawing.Point(20, 120)
$BtnRun.Size = New-Object System.Drawing.Size(460, 80)
$BtnRun.FlatStyle = "Flat"
$BtnRun.BackColor = [System.Drawing.Color]::FromArgb(40, 167, 69) 
$BtnRun.ForeColor = "White"
$BtnRun.Cursor = "Hand"
$BtnRun.Add_MouseEnter({ $BtnRun.BackColor = [System.Drawing.Color]::FromArgb(50, 200, 80) })
$BtnRun.Add_MouseLeave({ $BtnRun.BackColor = [System.Drawing.Color]::FromArgb(40, 167, 69) })
$BtnRun.Add_Click({ Load-Mod "WinInstall_Core.ps1" })
$Panel.Controls.Add($BtnRun)

# --- FOOTER ---
$LblFooter = New-Object System.Windows.Forms.Label
$LblFooter.Text = "Zalo Hỗ Trợ: 0823.883.028  |  Github: Hello2k2"
$LblFooter.Font = $FontSmall
$LblFooter.ForeColor = [System.Drawing.Color]::Gray
$LblFooter.AutoSize = $true
$LblFooter.Location = New-Object System.Drawing.Point(150, 380)
$Form.Controls.Add($LblFooter)

# --- HIỂN THỊ ---
$Form.ShowDialog() | Out-Null
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
