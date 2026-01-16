<#
    TOOL CUU HO MAY TINH - PHAT TAN PC
    Module: Hardware Health (X-Ray Edition)
    Author: Phat Tan
    Version: 3.0 (Multi-Layer Hardware Scan)
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ThemeColor = [System.Drawing.Color]::FromArgb(0, 255, 127) # Neon Spring Green
$BgColor = [System.Drawing.Color]::FromArgb(25, 25, 30)

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "HARDWARE X-RAY V3 - PHAT TAN PC"
$Form.Size = "900,700"
$Form.BackColor = $BgColor
$Form.StartPosition = "CenterScreen"

$LblTitle = New-Object System.Windows.Forms.Label
$LblTitle.Text = "🔍 SIÊU CHẨN ĐOÁN PHẦN CỨNG"
$LblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$LblTitle.ForeColor = $ThemeColor
$LblTitle.Location = "20,20"; $LblTitle.AutoSize = $true
$Form.Controls.Add($LblTitle)

$RichBox = New-Object System.Windows.Forms.RichTextBox
$RichBox.Location = "20,80"; $RichBox.Size = "840,500"
$RichBox.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 40)
$RichBox.ForeColor = [System.Drawing.Color]::White
$RichBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$RichBox.ReadOnly = $true
$Form.Controls.Add($RichBox)

function Get-HardwareStatus {
    $RichBox.Clear()
    
    # --- [1] KIỂM TRA Ổ CỨNG (SỬ DỤNG STORAGE MODULE HIỆN ĐẠI) ---
    $RichBox.SelectionColor = [System.Drawing.Color]::Cyan
    $RichBox.AppendText("--- [1] KIỂM TRA SỨC KHỎE Ổ CỨNG (PHYSICAL DISKS) ---`n")
    try {
        # Get-PhysicalDisk là lệnh chuẩn từ Win 8/10/11, nhận được cả NVMe
        $Disks = Get-PhysicalDisk -ErrorAction SilentlyContinue
        if ($Disks) {
            foreach ($d in $Disks) {
                $StatusColor = if ($d.HealthStatus -eq "Healthy") { "Lime" } else { "Red" }
                $RichBox.AppendText("Model: $($d.FriendlyName)`n")
                $RichBox.AppendText("Loại: $($d.MediaType) | Sức khỏe: ")
                $RichBox.SelectionColor = [System.Drawing.Color]::FromName($StatusColor)
                $RichBox.AppendText("$($d.HealthStatus)`n")
                $RichBox.SelectionColor = [System.Drawing.Color]::White
                $RichBox.AppendText("Trạng thái vận hành: $($d.OperationalStatus)`n`n")
            }
        } else {
            # Fallback cho Win 7 / Máy cổ
            $LegacyDisks = Get-CimInstance -ClassName Win32_DiskDrive
            foreach ($ld in $LegacyDisks) {
                $RichBox.AppendText("Legacy Model: $($ld.Model)`nTrạng thái: $($ld.Status)`n`n")
            }
        }
    } catch { $RichBox.AppendText("[-] Lỗi truy xuất dữ liệu ổ cứng.`n`n") }

    # --- [2] KIỂM TRA PIN (CHI TIẾT HƠN) ---
    $RichBox.SelectionColor = [System.Drawing.Color]::Yellow
    $RichBox.AppendText("--- [2] THÔNG TIN NĂNG LƯỢNG (BATTERY) ---`n")
    $Battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
    if ($Battery) {
        foreach ($b in $Battery) {
            $RichBox.AppendText("Tên Pin: $($b.Name)`nDung lượng: $($b.EstimatedChargeRemaining)%`n")
            $RichBox.AppendText("Trạng thái sạc: $($b.BatteryStatus)`n`n")
        }
    } else { $RichBox.AppendText("[-] Không phát hiện Pin (Máy bàn hoặc thiếu Driver ACPI).`n`n") }

    # --- [3] NHIỆT ĐỘ CPU (CƠ CHẾ QUÉT ĐA LỚP) ---
    $RichBox.SelectionColor = [System.Drawing.Color]::OrangeRed
    $RichBox.AppendText("--- [3] NHIỆT ĐỘ HỆ THỐNG ---`n")
    $TempSuccess = $false
    
    # Cách 1: MSAcpi (Phổ biến trên Laptop)
    try {
        $AcpiTemp = Get-CimInstance -Namespace root\wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop
        if ($AcpiTemp.CurrentTemperature -gt 0) {
            $T = [math]::Round(($AcpiTemp.CurrentTemperature / 10) - 273.15, 1)
            $RichBox.AppendText("[ACPI] Nhiệt độ CPU: $T °C`n")
            $TempSuccess = $true
        }
    } catch {}

    # Cách 2: Win32_TemperatureProbe (Fallback cho máy bộ/máy chủ)
    if (-not $TempSuccess) {
        try {
            $Probe = Get-CimInstance -ClassName Win32_TemperatureProbe -ErrorAction Stop
            if ($Probe) {
                $RichBox.AppendText("[Probe] Nhiệt độ: $($Probe.CurrentReading) °C`n")
                $TempSuccess = $true
            }
        } catch {}
    }

    if (-not $TempSuccess) {
        $RichBox.AppendText("[-] Cảm biến nhiệt độ bị khóa hoặc không hỗ trợ native.`n")
        $RichBox.AppendText("👉 Lời khuyên: Dùng module 'Stress Test' để chẩn đoán gián tiếp.`n")
    }
}

$BtnCheck = New-Object System.Windows.Forms.Button
$BtnCheck.Text = "🔍 QUÉT HỆ THỐNG"; $BtnCheck.Location = "20,600"; $BtnCheck.Size = "180,45"
$BtnCheck.FlatStyle = "Flat"; $BtnCheck.BackColor = $ThemeColor; $BtnCheck.ForeColor = "Black"
$BtnCheck.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$BtnCheck.Add_Click({ Get-HardwareStatus })
$Form.Controls.Add($BtnCheck)

$Form.Add_Load({ Get-HardwareStatus })
$Form.ShowDialog() | Out-Null
