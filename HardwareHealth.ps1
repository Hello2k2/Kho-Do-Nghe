<#
    TOOL CUU HO MAY TINH - PHAT TAN PC
    Module: Hardware Health (Chẩn đoán phần cứng)
    Author: Phat Tan
    Version: 1.0 (Neon UI)
#>

# --- 1. INIT & THEME ---
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ThemeColor = [System.Drawing.Color]::FromArgb(180, 80, 255) # Neon Purple
$BgColor = [System.Drawing.Color]::FromArgb(25, 25, 30)

# --- 2. GUI ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "HARDWARE HEALTH - PHAT TAN PC"
$Form.Size = "850,650"
$Form.BackColor = $BgColor
$Form.StartPosition = "CenterScreen"

$LblTitle = New-Object System.Windows.Forms.Label
$LblTitle.Text = "🩺 CHẨN ĐOÁN SỨC KHỎE PHẦN CỨNG"
$LblTitle.Font = "Segoe UI, 18, Bold"; $LblTitle.ForeColor = $ThemeColor
$LblTitle.Location = "20,20"; $LblTitle.AutoSize = $true
$Form.Controls.Add($LblTitle)

$RichBox = New-Object System.Windows.Forms.RichTextBox
$RichBox.Location = "20,80"; $RichBox.Size = "790,450"
$RichBox.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 45)
$RichBox.ForeColor = [System.Drawing.Color]::White
$RichBox.Font = "Consolas, 10"
$RichBox.ReadOnly = $true
$Form.Controls.Add($RichBox)

# --- 3. CORE FUNCTIONS ---
function Get-HardwareStatus {
    $RichBox.Clear()
    $RichBox.AppendText("--- [1] KIỂM TRA Ổ CỨNG (S.M.A.R.T) ---`n")
    # Kiểm tra trạng thái ổ cứng
    $Disks = Get-CimInstance -Namespace root\wmi -ClassName MSStorageDriver_FailurePredictStatus
    foreach ($d in $Disks) {
        $Status = if ($d.PredictFailure) { "⚠️ CẢNH BÁO: CÓ DẤU HIỆU HỎNG!" } else { "✅ TỐT (Healthy)" }
        $RichBox.AppendText("Instance: $($d.InstanceName)`nTrạng thái: $Status`n`n")
    }

    $RichBox.AppendText("--- [2] KIỂM TRA PIN (LAPTOP) ---`n")
    # Lấy thông số pin
    $Battery = Get-CimInstance -ClassName Win32_Battery
    if ($Battery) {
        foreach ($b in $Battery) {
            $RichBox.AppendText("Tên: $($b.Name)`nDung lượng hiện tại: $($b.EstimatedChargeRemaining)%`nTrạng thái: $($b.Status)`n`n")
        }
    } else { $RichBox.AppendText("Không phát hiện Pin (Máy bàn).`n`n") }

    $RichBox.AppendText("--- [3] NHIỆT ĐỘ CPU ---`n")
    # Lấy nhiệt độ (Yêu cầu quyền Admin cao)
    try {
        $Temp = Get-CimInstance -Namespace root\wmi -ClassName MSAcpi_ThermalZoneTemperature
        $CurrentTemp = [math]::Round(($Temp.CurrentTemperature / 10) - 273.15, 1)
        $RichBox.AppendText("Nhiệt độ hiện tại: $CurrentTemp °C`n")
        if ($CurrentTemp -gt 85) { $RichBox.AppendText("⚠️ CẢNH BÁO: MÁY ĐANG QUÁ NÓNG!`n") }
    } catch { $RichBox.AppendText("Không thể lấy dữ liệu nhiệt độ (Lỗi Driver/Quyền).`n") }
}

function Export-Report {
    $ReportPath = "$env:USERPROFILE\Desktop\Hardware_Report.txt"
    $RichBox.Text | Out-File -FilePath $ReportPath -Encoding UTF8
    [System.Windows.Forms.MessageBox]::Show("Đã xuất báo cáo ra Desktop!", "Thành Công")
}

# --- 4. BUTTONS ---
$BtnCheck = New-Object System.Windows.Forms.Button
$BtnCheck.Text = "🔍 QUÉT NGAY"; $BtnCheck.Location = "20,540"; $BtnCheck.Size = "150,45"
$BtnCheck.FlatStyle = "Flat"; $BtnCheck.BackColor = $ThemeColor; $BtnCheck.ForeColor = "White"
$BtnCheck.Add_Click({ Get-HardwareStatus })
$Form.Controls.Add($BtnCheck)

$BtnExport = New-Object System.Windows.Forms.Button
$BtnExport.Text = "📄 XUẤT BÁO CÁO"; $BtnExport.Location = "180,540"; $BtnExport.Size = "150,45"
$BtnExport.FlatStyle = "Flat"; $BtnExport.BackColor = [System.Drawing.Color]::ForestGreen; $BtnExport.ForeColor = "White"
$BtnExport.Add_Click({ Export-Report })
$Form.Controls.Add($BtnExport)

$Form.Add_Load({ Get-HardwareStatus })
$Form.ShowDialog() | Out-Null
