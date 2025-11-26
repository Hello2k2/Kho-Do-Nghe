Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- GUI SETUP ---
$SForm = New-Object System.Windows.Forms.Form
$SForm.Text = "SYSTEM HEALTH SCAN - PHAT TAN PC"
$SForm.Size = New-Object System.Drawing.Size(700, 500)
$SForm.StartPosition = "CenterScreen"
$SForm.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
$SForm.ForeColor = "Lime"
$SForm.FormBorderStyle = "FixedSingle"
$SForm.MaximizeBox = $false

# Khung Log
$TxtLog = New-Object System.Windows.Forms.TextBox
$TxtLog.Multiline = $true
$TxtLog.ScrollBars = "Vertical"
$TxtLog.Location = New-Object System.Drawing.Point(15, 15)
$TxtLog.Size = New-Object System.Drawing.Size(650, 350)
$TxtLog.BackColor = [System.Drawing.Color]::Black
$TxtLog.ForeColor = "Lime"
$TxtLog.Font = New-Object System.Drawing.Font("Consolas", 10)
$TxtLog.ReadOnly = $true
$SForm.Controls.Add($TxtLog)

# --- HÀM LOGIC (QUAN TRỌNG) ---
function Add-Log ($Msg) {
    $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $Msg`r`n")
    $TxtLog.SelectionStart = $TxtLog.Text.Length
    $TxtLog.ScrollToCaret()
}

# Hàm chạy lệnh CMD và Stream kết quả ngay lập tức
function Run-RealTimeCmd ($Command) {
    $B1.Enabled = $false; $B2.Enabled = $false; $B3.Enabled = $false
    
    Add-Log ">>> DANG KHOI CHAY LENH: $Command"
    Add-Log ">>> Vui long doi, khong tat cua so..."
    
    # Cấu hình Process để bắt Output
    $PInfo = New-Object System.Diagnostics.ProcessStartInfo
    $PInfo.FileName = "cmd.exe"
    $PInfo.Arguments = "/c $Command"
    $PInfo.RedirectStandardOutput = $true
    $PInfo.RedirectStandardError = $true
    $PInfo.UseShellExecute = $false
    $PInfo.CreateNoWindow = $true
    $PInfo.StandardOutputEncoding = [System.Text.Encoding]::GetEncoding(850) # Fix lỗi font CMD

    $Process = New-Object System.Diagnostics.Process
    $Process.StartInfo = $PInfo
    $Process.Start() | Out-Null

    # Vòng lặp đọc từng dòng khi đang chạy
    while (-not $Process.StandardOutput.EndOfStream) {
        $Line = $Process.StandardOutput.ReadLine()
        if ($Line -ne "") {
            Add-Log $Line
            # Lệnh này giúp UI không bị treo (QUAN TRỌNG)
            [System.Windows.Forms.Application]::DoEvents()
        }
    }
    
    $Process.WaitForExit()
    Add-Log ">>> HOAN TAT."
    Add-Log "-----------------------------------------------------"
    
    $B1.Enabled = $true; $B2.Enabled = $true; $B3.Enabled = $true
}

# --- BUTTONS ---
$B1 = New-Object System.Windows.Forms.Button
$B1.Text = "1. SFC SCAN (QUET FILE LOI)"
$B1.Location = New-Object System.Drawing.Point(15, 390)
$B1.Size = New-Object System.Drawing.Size(210, 50)
$B1.BackColor = "DimGray"; $B1.ForeColor = "White"; $B1.FlatStyle = "Flat"
$B1.Add_Click({ Run-RealTimeCmd "sfc /scannow" })
$SForm.Controls.Add($B1)

$B2 = New-Object System.Windows.Forms.Button
$B2.Text = "2. CHECK HEALTH (KIEM TRA)"
$B2.Location = New-Object System.Drawing.Point(235, 390)
$B2.Size = New-Object System.Drawing.Size(210, 50)
$B2.BackColor = "DimGray"; $B2.ForeColor = "White"; $B2.FlatStyle = "Flat"
$B2.Add_Click({ Run-RealTimeCmd "dism /online /cleanup-image /scanhealth" })
$SForm.Controls.Add($B2)

$B3 = New-Object System.Windows.Forms.Button
$B3.Text = "3. RESTORE HEALTH (SUA LOI)"
$B3.Location = New-Object System.Drawing.Point(455, 390)
$B3.Size = New-Object System.Drawing.Size(210, 50)
$B3.BackColor = "DarkOrange"; $B3.ForeColor = "Black"; $B3.FlatStyle = "Flat"; $B3.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$B3.Add_Click({ Run-RealTimeCmd "dism /online /cleanup-image /restorehealth" })
$SForm.Controls.Add($B3)

$SForm.ShowDialog() | Out-Null
