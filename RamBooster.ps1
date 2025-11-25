Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CẤU HÌNH GIAO DIỆN ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "PHAT TAN PC - RAM DOWNLOADER V2.0"
$Form.Size = New-Object System.Drawing.Size(600, 350)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20) # Màu đen Hacker
$Form.FormBorderStyle = "FixedDialog"
$Form.MaximizeBox = $false

# Logo
$Title = New-Object System.Windows.Forms.Label
$Title.Text = "CLOUD RAM DOWNLOADER"
$Title.Font = New-Object System.Drawing.Font("Consolas", 20, [System.Drawing.FontStyle]::Bold)
$Title.ForeColor = [System.Drawing.Color]::LimeGreen
$Title.AutoSize = $true
$Title.Location = New-Object System.Drawing.Point(130, 30)
$Form.Controls.Add($Title)

# Thông số hiện tại
$InfoLabel = New-Object System.Windows.Forms.Label
$InfoLabel.Text = "System Analysis: Waiting..."
$InfoLabel.Font = New-Object System.Drawing.Font("Consolas", 10)
$InfoLabel.ForeColor = [System.Drawing.Color]::Cyan
$InfoLabel.AutoSize = $true
$InfoLabel.Location = New-Object System.Drawing.Point(40, 90)
$Form.Controls.Add($InfoLabel)

# Thanh chạy (Progress Bar)
$Bar = New-Object System.Windows.Forms.ProgressBar
$Bar.Size = New-Object System.Drawing.Size(500, 40)
$Bar.Location = New-Object System.Drawing.Point(40, 130)
$Bar.Style = "Continuous"
$Form.Controls.Add($Bar)

# Trạng thái chi tiết (Log)
$LogLabel = New-Object System.Windows.Forms.Label
$LogLabel.Text = "Ready."
$LogLabel.Font = New-Object System.Drawing.Font("Consolas", 9)
$LogLabel.ForeColor = [System.Drawing.Color]::Gray
$LogLabel.AutoSize = $true
$LogLabel.Location = New-Object System.Drawing.Point(40, 180)
$Form.Controls.Add($LogLabel)

# Nút Bấm
$Btn = New-Object System.Windows.Forms.Button
$Btn.Text = "DOWNLOAD MORE RAM"
$Btn.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$Btn.Size = New-Object System.Drawing.Size(250, 60)
$Btn.Location = New-Object System.Drawing.Point(170, 220)
$Btn.BackColor = [System.Drawing.Color]::LimeGreen
$Btn.ForeColor = [System.Drawing.Color]::Black
$Btn.FlatStyle = "Flat"
$Btn.Cursor = [System.Windows.Forms.Cursors]::Hand
$Form.Controls.Add($Btn)

# --- LOGIC CHẠY ---
$Btn.Add_Click({
    $Btn.Enabled = $false
    $Btn.Text = "PROCESSING..."
    
    # --- BƯỚC 1: CHECK PHẦN CỨNG (0-20%) ---
    $LogLabel.Text = "Scanning Memory Modules..."
    $Form.Refresh()
    Start-Sleep -Milliseconds 500
    
    $RamInfo = Get-CimInstance Win32_ComputerSystem
    $TotalRamGB = [Math]::Round($RamInfo.TotalPhysicalMemory / 1GB)
    $TargetSwapMB = [Math]::Round($TotalRamGB * 1024 * 1.5) # Công thức 1.5x
    
    $InfoLabel.Text = "Physical RAM: $TotalRamGB GB detected. Target Virtual RAM: $TargetSwapMB MB"
    $Bar.Value = 20
    $Form.Refresh()
    Start-Sleep -Milliseconds 800

    # --- BƯỚC 2: CHECK Ổ CỨNG (20-30%) ---
    $LogLabel.Text = "Analyzing Storage I/O Speed..."
    $Form.Refresh()
    
    # Lọc ổ đĩa: Chỉ lấy ổ NTFS/FAT, bỏ ổ mạng/USB
    $Drives = Get-PSDrive -PSProvider FileSystem | Where-Object {$_.Used -gt 0 -and $_.Free -gt ($TargetSwapMB * 1024 * 1024)} | Sort-Object Free -Descending
    
    if ($Drives.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("O cung day qua, khong du cho de tai RAM!", "Loi", "OK", "Error")
        $Btn.Enabled = $true; $Btn.Text = "RETRY"; return
    }
    
    $Bar.Value = 30
    $Form.Refresh()
    Start-Sleep -Milliseconds 500

    # --- BƯỚC 3: GIẢ LẬP DOWNLOAD (30-80%) - QUAN TRỌNG NHẤT ---
    # Khúc này làm màu để khách sướng
    for ($i = 30; $i -le 80; $i += 2) {
        $Bar.Value = $i
        
        # Random text cho nguy hiểm
        $Kbs = Get-Random -Minimum 1024 -Maximum 5120
        $LogLabel.Text = "Downloading RAM Segments... Speed: $Kbs MB/s | Chunk: $i%"
        
        $Form.Refresh()
        
        # Random tốc độ delay để nhìn cho thật
        $Delay = Get-Random -Minimum 50 -Maximum 150
        Start-Sleep -Milliseconds $Delay
    }

    # --- BƯỚC 4: THỰC THI SETTING (80-100%) ---
    $LogLabel.Text = "Writing to Pagefile.sys..."
    $Bar.Value = 90
    $Form.Refresh()

    try {
        # Tắt Auto Manage
        $Sys = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges
        $Sys.AutomaticManagedPagefile = $false
        $Sys.Put() | Out-Null

        # Logic chia ổ (70/30)
        if ($Drives.Count -ge 2) {
            $D1 = $Drives[0]; $S1 = [Math]::Round($TargetSwapMB * 0.7)
            $D2 = $Drives[1]; $S2 = [Math]::Round($TargetSwapMB * 0.3)
            
            # Set ổ 1
            $Pf1 = Get-WmiObject Win32_PageFileSetting -Filter "Name='$($D1.Name[0]):\\pagefile.sys'"
            if (!$Pf1) { Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{Name="$($D1.Name[0]):\pagefile.sys"; InitialSize=$S1; MaximumSize=$S1} | Out-Null }
            else { $Pf1.InitialSize = $S1; $Pf1.MaximumSize = $S1; $Pf1.Put() | Out-Null }
            
            # Set ổ 2
            $Pf2 = Get-WmiObject Win32_PageFileSetting -Filter "Name='$($D2.Name[0]):\\pagefile.sys'"
            if (!$Pf2) { Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{Name="$($D2.Name[0]):\pagefile.sys"; InitialSize=$S2; MaximumSize=$S2} | Out-Null }
            else { $Pf2.InitialSize = $S2; $Pf2.MaximumSize = $S2; $Pf2.Put() | Out-Null }
            
            $LogLabel.Text = "Injecting: 70% to Drive $($D1.Name) | 30% to Drive $($D2.Name)"
        }
        else {
            # 1 ổ
            $D1 = $Drives[0]
            $Pf = Get-WmiObject Win32_PageFileSetting -Filter "Name='$($D1.Name[0]):\\pagefile.sys'"
            if (!$Pf) { Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{Name="$($D1.Name[0]):\pagefile.sys"; InitialSize=$TargetSwapMB; MaximumSize=$TargetSwapMB} | Out-Null }
            else { $Pf.InitialSize = $TargetSwapMB; $Pf.MaximumSize = $TargetSwapMB; $Pf.Put() | Out-Null }
            
             $LogLabel.Text = "Injecting 100% to Drive $($D1.Name)"
        }
    }
    catch {
        $LogLabel.Text = "Error optimizing pagefile."
    }

    $Bar.Value = 100
    $Form.Refresh()
    Start-Sleep -Seconds 1
    
    [System.Windows.Forms.MessageBox]::Show("SUCCESS!`nDa tai them $TargetSwapMB MB RAM Ao thanh cong.`nKhoi dong lai may de trai nghiem toc do!", "PHAT TAN PC", "OK", "Information")
    $Form.Close()
})

$Form.ShowDialog() | Out-Null
