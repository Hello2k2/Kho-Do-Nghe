<#
    SYSTEM INFO DEEP DIVE - PHAT TAN PC
    Version: 4.0 (Full Details + White Theme)
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- GUI SETUP (WHITE THEME) ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "THONG TIN PHAN CUNG CHI TIET - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(1000, 650)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = "White"
$Form.ForeColor = "Black"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Tab Control
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = New-Object System.Drawing.Point(10, 10)
$TabControl.Size = New-Object System.Drawing.Size(965, 540)
$Form.Controls.Add($TabControl)

# --- HAM TAO GIAO DIEN ---
function Make-Tab ($Title) {
    $Page = New-Object System.Windows.Forms.TabPage; $Page.Text = $Title
    $Page.BackColor = "White"; $Page.ForeColor = "Black"
    $TabControl.Controls.Add($Page); return $Page
}

function Make-ListView ($Parent) {
    $Lv = New-Object System.Windows.Forms.ListView
    $Lv.Size = New-Object System.Drawing.Size(955, 510); $Lv.Location = New-Object System.Drawing.Point(0, 0)
    $Lv.View = "Details"; $Lv.GridLines = $true; $Lv.FullRowSelect = $true
    $Lv.BackColor = "White"; $Lv.ForeColor = "Black"
    $Parent.Controls.Add($Lv); return $Lv
}

function Add-Item ($Lv, $Name, $Value) {
    $Item = New-Object System.Windows.Forms.ListViewItem($Name)
    $Item.SubItems.Add($Value)
    $Lv.Items.Add($Item) | Out-Null
}

# ==========================================
# TAB 1: TỔNG QUAN (SUMMARY)
# ==========================================
$TabSum = Make-Tab "Tong Quan"
$LvSum = Make-ListView $TabSum
$LvSum.Columns.Add("Thanh Phan", 200); $LvSum.Columns.Add("Thong Tin", 700)

function Load-Summary {
    $LvSum.Items.Clear()
    $OS = Get-CimInstance Win32_OperatingSystem
    $CS = Get-CimInstance Win32_ComputerSystem
    $Bios = Get-CimInstance Win32_BIOS
    
    Add-Item $LvSum "Ten May (Hostname)" $CS.Name
    Add-Item $LvSum "He Dieu Hanh" "$($OS.Caption) ($($OS.OSArchitecture))"
    Add-Item $LvSum "Phien Ban (Build)" "$($OS.Version) (Build $($OS.BuildNumber))"
    Add-Item $LvSum "Nguoi Dung" $env:USERNAME
    Add-Item $LvSum "Ngay Cai Win" $OS.InstallDate
    Add-Item $LvSum "Thoi Gian Boot" "$([Math]::Round((Get-Date).Subtract($OS.LastBootUpTime).TotalHours, 1)) gio truoc"
    Add-Item $LvSum "-----------------" "-----------------"
    Add-Item $LvSum "Hang San Xuat" $CS.Manufacturer
    Add-Item $LvSum "Model May" $CS.Model
    Add-Item $LvSum "Serial Number" $Bios.SerialNumber
    Add-Item $LvSum "BIOS Version" "$($Bios.SMBIOSBIOSVersion) (Date: $($Bios.ReleaseDate))"
}

# ==========================================
# TAB 2: CPU & RAM (CHI TIẾT)
# ==========================================
$TabCpu = Make-Tab "CPU & RAM"
$LvCpu = Make-ListView $TabCpu
$LvCpu.Columns.Add("Thong So", 200); $LvCpu.Columns.Add("Gia Tri", 700)

function Load-CpuRam {
    $LvCpu.Items.Clear()
    # CPU
    $CPU = Get-CimInstance Win32_Processor
    Add-Item $LvCpu "[VI XU LY - CPU]" $CPU.Name
    Add-Item $LvCpu "Socket" $CPU.SocketDesignation
    Add-Item $LvCpu "So Nhan (Cores)" $CPU.NumberOfCores
    Add-Item $LvCpu "So Luong (Threads)" $CPU.NumberOfLogicalProcessors
    Add-Item $LvCpu "Toc Do Co Ban" "$($CPU.MaxClockSpeed) MHz"
    Add-Item $LvCpu "Ao Hoa (Virtualization)" $(if($CPU.VirtualizationFirmwareEnabled){"Da Bat"}else{"Dang Tat"})
    
    Add-Item $LvCpu "" ""
    
    # RAM DETAILS
    $Rams = Get-CimInstance Win32_PhysicalMemory
    $TotalRAM = 0
    Add-Item $LvCpu "[BO NHO TRONG - RAM]" "Chi tiet tung thanh:"
    
    foreach ($R in $Rams) {
        $SizeGB = [Math]::Round($R.Capacity / 1GB, 1)
        $TotalRAM += $R.Capacity
        $Speed = $R.Speed
        $Maker = $R.Manufacturer
        $Part = $R.PartNumber
        $Loc = $R.DeviceLocator
        Add-Item $LvCpu "  + Slot $Loc" "$SizeGB GB - $Speed MHz - $Maker ($Part)"
    }
    Add-Item $LvCpu "=== TONG CONG ===" "$([Math]::Round($TotalRAM / 1GB, 1)) GB"
}

# ==========================================
# TAB 3: O CUNG (STORAGE)
# ==========================================
$TabDisk = Make-Tab "Luu Tru (HDD/SSD)"
$LvDisk = Make-ListView $TabDisk
$LvDisk.Columns.Add("O Cung", 100); $LvDisk.Columns.Add("Loai", 80); $LvDisk.Columns.Add("Dung Luong", 100); $LvDisk.Columns.Add("Ten Model", 300); $LvDisk.Columns.Add("Suc Khoe", 100); $LvDisk.Columns.Add("Serial", 200)

function Load-Storage {
    $LvDisk.Items.Clear()
    $Disks = Get-PhysicalDisk | Sort-Object DeviceId
    foreach ($D in $Disks) {
        $Size = [Math]::Round($D.Size / 1GB, 1).ToString() + " GB"
        $Item = New-Object System.Windows.Forms.ListViewItem("Disk $($D.DeviceId)")
        $Item.SubItems.Add($D.MediaType) # SSD hay HDD
        $Item.SubItems.Add($Size)
        $Item.SubItems.Add($D.Model)
        $Item.SubItems.Add($D.HealthStatus)
        $Item.SubItems.Add($D.SerialNumber)
        $LvDisk.Items.Add($Item)
    }
}

# ==========================================
# TAB 4: DO HOA (GPU)
# ==========================================
$TabGpu = Make-Tab "Card Man Hinh (GPU)"
$LvGpu = Make-ListView $TabGpu
$LvGpu.Columns.Add("Thong So", 200); $LvGpu.Columns.Add("Gia Tri", 700)

function Load-GPU {
    $LvGpu.Items.Clear()
    $GPUs = Get-CimInstance Win32_VideoController
    foreach ($G in $GPUs) {
        Add-Item $LvGpu "[CARD DO HOA]" $G.Name
        
        # Tính VRAM (Hơi khó chính xác tuyệt đối nhưng tương đối)
        $VRAM = [Math]::Round($G.AdapterRAM / 1MB, 0)
        if ($VRAM -gt 0) { Add-Item $LvGpu "VRAM (Video Memory)" "$VRAM MB" }
        
        Add-Item $LvGpu "Driver Version" $G.DriverVersion
        try { 
            $Date = [DateTime]::ParseExact($G.DriverDate.Substring(0,8), "yyyyMMdd", $null).ToString("yyyy-MM-dd")
            Add-Item $LvGpu "Driver Date" $Date
        } catch {}
        
        Add-Item $LvGpu "Do Phan Giai" "$($G.CurrentHorizontalResolution) x $($G.CurrentVerticalResolution) @ $($G.CurrentRefreshRate)Hz"
        Add-Item $LvGpu "---" "---"
    }
}

# ==========================================
# TAB 5: DRIVERS (FULL LIST)
# ==========================================
$TabDrivers = Make-Tab "Tat Ca Driver"
$GridDrv = New-Object System.Windows.Forms.DataGridView
$GridDrv.Size = New-Object System.Drawing.Size(955, 510); $GridDrv.Location = New-Object System.Drawing.Point(0, 0)
$GridDrv.BackgroundColor = "White"; $GridDrv.ForeColor = "Black"
$GridDrv.AllowUserToAddRows = $false; $GridDrv.RowHeadersVisible = $false
$GridDrv.AutoSizeColumnsMode = "Fill"; $GridDrv.SelectionMode = "FullRowSelect"; $GridDrv.ReadOnly = $true
$TabDrivers.Controls.Add($GridDrv)

function Load-AllDrivers {
    $Drivers = Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -ne $null } | Select-Object DeviceName, Manufacturer, DriverVersion, DriverDate
    
    $DT = New-Object System.Data.DataTable
    $DT.Columns.Add("Thiet Bi"); $DT.Columns.Add("Nha SX"); $DT.Columns.Add("Version"); $DT.Columns.Add("Ngay")
    
    foreach ($D in $Drivers) {
        try { $Date = [DateTime]::ParseExact($D.DriverDate.Substring(0,8), "yyyyMMdd", $null).ToString("yyyy-MM-dd") } catch { $Date = "" }
        $DT.Rows.Add($D.DeviceName, $D.Manufacturer, $D.DriverVersion, $Date) | Out-Null
    }
    $GridDrv.DataSource = $DT
}

# ==========================================
# BUTTONS
# ==========================================
$BtnReload = New-Object System.Windows.Forms.Button
$BtnReload.Text = "LAM MOI"; $BtnReload.Location = "10,560"; $BtnReload.Size = "150,40"; $BtnReload.BackColor = "LightBlue"
$BtnReload.Add_Click({ Run-All-Checks })
$Form.Controls.Add($BtnReload)

$BtnHTML = New-Object System.Windows.Forms.Button
$BtnHTML.Text = "XUAT BAO CAO (HTML)"; $BtnHTML.Location = "170,560"; $BtnHTML.Size = "200,40"; $BtnHTML.BackColor = "Orange"
$BtnHTML.Add_Click({
    $Path = "$env:USERPROFILE\Desktop\PC_Report.html"
    $CSS = "<style>body{font-family:Arial} table{border-collapse:collapse;width:100%} th,td{border:1px solid #ddd;padding:8px} th{background:#4CAF50;color:white} h2{color:#333}</style>"
    $H = "<html><head>$CSS</head><body><h1>BAO CAO PHAN CUNG - PHAT TAN PC</h1>"
    
    # Function convert ListView to HTML Table
    function LvToHtml ($Title, $Lv) {
        $Res = "<h2>$Title</h2><table><tr><th>Thong So</th><th>Gia Tri</th></tr>"
        foreach ($Item in $Lv.Items) { $Res += "<tr><td>$($Item.Text)</td><td>$($Item.SubItems[1].Text)</td></tr>" }
        return $Res + "</table>"
    }
    
    $H += LvToHtml "TONG QUAN" $LvSum
    $H += LvToHtml "CPU & RAM" $LvCpu
    $H += LvToHtml "GPU" $LvGpu
    
    # Disk table
    $H += "<h2>LUU TRU (DISK)</h2><table><tr><th>Disk</th><th>Loai</th><th>Size</th><th>Model</th><th>Health</th></tr>"
    foreach ($Item in $LvDisk.Items) { 
        $H += "<tr><td>$($Item.Text)</td><td>$($Item.SubItems[1].Text)</td><td>$($Item.SubItems[2].Text)</td><td>$($Item.SubItems[3].Text)</td><td>$($Item.SubItems[4].Text)</td></tr>" 
    }
    $H += "</table></body></html>"
    
    $H | Out-File $Path -Encoding UTF8
    Invoke-Item $Path
})
$Form.Controls.Add($BtnHTML)

# --- MASTER RUN ---
function Run-All-Checks {
    Load-Summary
    Load-CpuRam
    Load-Storage
    Load-GPU
    Load-AllDrivers
}

# Chạy lần đầu
$Form.Add_Shown({ Run-All-Checks })
$Form.ShowDialog() | Out-Null
