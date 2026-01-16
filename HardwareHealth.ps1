<#
    TOOL CUU HO MAY TINH - PHAT TAN PC
    Module: Hardware Health (Bản vạn năng)
    Author: Phat Tan
    Version: 2.0 (Fix lỗi Font & WMI)
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ThemeColor = [System.Drawing.Color]::FromArgb(180, 80, 255)
$BgColor = [System.Drawing.Color]::FromArgb(25, 25, 30)

# --- GUI ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "HARDWARE HEALTH V2 - PHAT TAN PC"
$Form.Size = "850,650"
$Form.BackColor = $BgColor
$Form.StartPosition = "CenterScreen"

$LblTitle = New-Object System.Windows.Forms.Label
$LblTitle.Text = "🩺 CHẨN ĐOÁN SỨC KHỎE PHẦN CỨNG"
# FIX LỖI FONT: Khai báo qua New-Object thay vì dùng chuỗi
$LblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$LblTitle.ForeColor = $ThemeColor
$LblTitle.Location = "20,20"; $LblTitle.AutoSize = $true
$Form.Controls.Add($LblTitle)

$RichBox = New-Object System.Windows.Forms.RichTextBox
$RichBox.Location = "20,80"; $RichBox.Size = "790,450"
$RichBox.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 45)
$RichBox.ForeColor = [System.Drawing.Color]::White
$RichBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$RichBox.ReadOnly = $true
$Form.Controls.Add($RichBox)

# --- CORE FUNCTIONS ---
function Get-HardwareStatus {
    $RichBox.Clear()
    $RichBox.SelectionColor = [System.Drawing.Color]::Cyan
    $RichBox.AppendText("--- [1] KIỂM TRA Ổ CỨNG (S.M.A.R.T) ---`n")
    
    # FIX LỖI S.M.A.R.T: Dùng Try-Catch để không bị văng lỗi đỏ
    try {
        $Disks = Get-CimInstance -Namespace root\wmi -ClassName MSStorageDriver_FailurePredictStatus -ErrorAction Stop
        foreach ($d in $Disks) {
            $Status = if ($d.PredictFailure) { "⚠️ CẢNH BÁO: CÓ DẤU HIỆU HỎNG!" } else { "✅ TỐT (Healthy)" }
            $RichBox.AppendText("Thiết bị: $($d.InstanceName)`nTrạng thái: $Status`n`n")
        }
    } catch {
        $RichBox.AppendText("[-] Không lấy được dữ liệu S.M.A.R.T (Có thể máy không hỗ trợ lớp này).`n`n")
    }

    $RichBox.SelectionColor = [System.Drawing.Color]::Yellow
    $RichBox.AppendText("--- [2] KIỂM TRA PIN (LAPTOP) ---`n")
    $Battery = Get-CimInstance -ClassName Win32_Battery
    if ($Battery) {
        foreach ($b in $Battery) {
            $RichBox.AppendText("Tên: $($b.Name)`nDung lượng: $($b.EstimatedChargeRemaining)%`nTrạng thái: $($b.Status)`n`n")
        }
    } else { $RichBox.AppendText("[-] Không phát hiện Pin (Máy bàn).`n`n") }

    $RichBox.SelectionColor = [System.Drawing.Color]::OrangeRed
    $RichBox.AppendText("--- [3] NHIỆT ĐỘ CPU ---`n")
    # FIX LỖI NHIỆT ĐỘ: Check giá trị khác 0 và dùng Try-Catch
    try {
        $TempData = Get-CimInstance -Namespace root\wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop
        if ($TempData.CurrentTemperature -gt 0) {
            $CurrentTemp = [math]::Round(($TempData.CurrentTemperature / 10) - 273.15, 1)
            $RichBox.AppendText("Nhiệt độ hiện tại: $CurrentTemp °C`n")
            if ($CurrentTemp -gt 85) { $RichBox.AppendText("⚠️ CẢNH BÁO: MÁY QUÁ NÓNG!`n") }
        } else {
            $RichBox.AppendText("[-] Cảm biến trả về giá trị 0 (Không hợp lệ).`n")
        }
    } catch {
        $RichBox.AppendText("[-] Không lấy được nhiệt độ (Thiếu Driver ACPI hoặc quyền Admin).`n")
    }
}

# --- BUTTONS ---
$BtnCheck = New-Object System.Windows.Forms.Button
$BtnCheck.Text = "🔍 QUÉT LẠI"; $BtnCheck.Location = "20,540"; $BtnCheck.Size = "150,45"
$BtnCheck.FlatStyle = "Flat"; $BtnCheck.BackColor = $ThemeColor; $BtnCheck.ForeColor = "White"
$BtnCheck.Add_Click({ Get-HardwareStatus })
$Form.Controls.Add($BtnCheck)

$Form.Add_Load({ Get-HardwareStatus })
$Form.ShowDialog() | Out-Null
