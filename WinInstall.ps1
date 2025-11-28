# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- CONFIG ---
$RawUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/"
$TempDir = "$env:TEMP\PhatTan_Tool"
if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir | Out-Null }

# --- GUI INIT ---
try { Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing } catch { Exit }

# Cấu hình Form chính
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "PHAT TAN PC - WINDOWS DEPLOYMENT SUITE"
$Form.Size = New-Object System.Drawing.Size(600, 450)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30) # Màu xám đen chuyên nghiệp
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# --- FONTS ---
$FontTitle = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$FontSub   = New-Object System.Windows.Forms.Label
$FontBtn   = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$FontSmall = New-Object System.Drawing.Font("Consolas", 9)

# --- HÀM TẢI MODULE ---
function Load-Mod ($Name) {
    $Form.Cursor = "WaitCursor" # Hiện chuột xoay xoay
    $P = "$TempDir\$Name"
    try { 
        [System.Net.ServicePointManager]::SecurityProtocol = 3072
        (New-Object Net.WebClient).DownloadFile("$RawUrl$Name", $P)
        Start-Process powershell "-Ex Bypass -File `"$P`"" 
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi tai Module: $Name `nKiem tra lai mang!", "Error") }
    $Form.Cursor = "Default"
}

# --- HEADER (Tiêu đề) ---
$LblHeader = New-Object System.Windows.Forms.Label
$LblHeader.Text = "PHAT TAN PC TOOLKIT"
$LblHeader.Font = $FontTitle
$LblHeader.ForeColor = [System.Drawing.Color]::Cyan
$LblHeader.AutoSize = $true
$LblHeader.Location = New-Object System.Drawing.Point(140, 20)
$Form.Controls.Add($LblHeader)

$LblSub = New-Object System.Windows.Forms.Label
$LblSub.Text = "CHUYEN GIA CAI DAT WINDOWS & CUU HO"
$LblSub.Font = $FontSmall
$LblSub.ForeColor = [System.Drawing.Color]::LightGray
$LblSub.AutoSize = $true
$LblSub.Location = New-Object System.Drawing.Point(150, 60)
$Form.Controls.Add($LblSub)

# --- PANEL CHỨA NÚT (Để căn giữa đẹp hơn) ---
$Panel = New-Object System.Windows.Forms.Panel
$Panel.Size = New-Object System.Drawing.Size(500, 250)
$Panel.Location = New-Object System.Drawing.Point(40, 100)
$Panel.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$Form.Controls.Add($Panel)

# --- NÚT 1: CẤU HÌNH ---
$BtnCfg = New-Object System.Windows.Forms.Button
$BtnCfg.Text = "1. CAU HINH FILE TU DONG`n(Tao file XML: User, Key, Disk...)"
$BtnCfg.Font = $FontBtn
$BtnCfg.Location = New-Object System.Drawing.Point(20, 20)
$BtnCfg.Size = New-Object System.Drawing.Size(460, 80)
$BtnCfg.FlatStyle = "Flat"
$BtnCfg.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204) # Xanh VS Code
$BtnCfg.ForeColor = "White"
$BtnCfg.Cursor = "Hand"
# Hiệu ứng Hover
$BtnCfg.Add_MouseEnter({ $BtnCfg.BackColor = [System.Drawing.Color]::FromArgb(28, 151, 234) })
$BtnCfg.Add_MouseLeave({ $BtnCfg.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204) })
$BtnCfg.Add_Click({ Load-Mod "WinInstall_Config.ps1" })
$Panel.Controls.Add($BtnCfg)

# --- NÚT 2: CÀI ĐẶT ---
$BtnRun = New-Object System.Windows.Forms.Button
$BtnRun.Text = "2. TIEN HANH CAI DAT`n(Mount ISO, Backup Driver, Cai Win)"
$BtnRun.Font = $FontBtn
$BtnRun.Location = New-Object System.Drawing.Point(20, 120)
$BtnRun.Size = New-Object System.Drawing.Size(460, 80)
$BtnRun.FlatStyle = "Flat"
$BtnRun.BackColor = [System.Drawing.Color]::FromArgb(40, 167, 69) # Xanh lá Matrix
$BtnRun.ForeColor = "White"
$BtnRun.Cursor = "Hand"
# Hiệu ứng Hover
$BtnRun.Add_MouseEnter({ $BtnRun.BackColor = [System.Drawing.Color]::FromArgb(50, 200, 80) })
$BtnRun.Add_MouseLeave({ $BtnRun.BackColor = [System.Drawing.Color]::FromArgb(40, 167, 69) })
$BtnRun.Add_Click({ Load-Mod "WinInstall_Core.ps1" })
$Panel.Controls.Add($BtnRun)

# --- FOOTER (Thông tin liên hệ) ---
$LblFooter = New-Object System.Windows.Forms.Label
$LblFooter.Text = "Zalo Ho Tro: 0823.883.028  |  Github: Hello2k2"
$LblFooter.Font = $FontSmall
$LblFooter.ForeColor = [System.Drawing.Color]::Gray
$LblFooter.AutoSize = $true
$LblFooter.Location = New-Object System.Drawing.Point(150, 380)
$Form.Controls.Add($LblFooter)

# --- HIỂN THỊ ---
$Form.ShowDialog() | Out-Null
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
