<#
    SYSTEM INFO PRO MAX - PHAT TAN PC
    Version: 8.0 (Added Battery Health + Fix HTML Report)
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CHI TIET CAU HINH - PHAT TAN PC (V8.0)"
$Form.Size = New-Object System.Drawing.Size(950, 680)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = "White"
$Form.ForeColor = "Black"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# --- TAB CONTROL ---
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = New-Object System.Drawing.Point(10, 10)
$TabControl.Size = New-Object System.Drawing.Size(915, 530)
$Form.Controls.Add($TabControl)

# Helper Functions
function Make-Tab ($Title) {
    $Page = New-Object System.Windows.Forms.TabPage; $Page.Text = $Title
    $Page.BackColor = "White"; $Page.ForeColor = "Black"
    $TabControl.Controls.Add($Page); return $Page
}

function Make-ListView ($Parent) {
    $Lv = New-Object System.Windows.Forms.ListView
    $Lv.Size = New-Object System.Drawing.Size(905, 495); $Lv.Location = New-Object System.Drawing.Point(0, 0)
    $Lv.View = "Details"; $Lv.GridLines = $true; $Lv.FullRowSelect = $true
    $Lv.BackColor = "White"; $Lv.ForeColor = "Black"
    $Parent.Controls.Add($Lv); return $Lv
}

function Add-Item ($Lv, $Name, $Value) {
    $Item = New-Object System.Windows.Forms.ListViewItem($Name)
    $Item.SubItems.Add($Value)
    $Lv.Items.Add($Item) | Out-Null
}

function Make-Grid ($Parent) {
    $G = New-Object System.Windows.Forms.DataGridView
    $G.Size = New-Object System.Drawing.Size(905, 495); $G.Location = New-Object System.Drawing.Point(0, 0)
    $G.BackgroundColor = "White"; $G.ForeColor = "Black"
    $G.AllowUserToAddRows=$false; $G.RowHeadersVisible=$false; $G.AutoSizeColumnsMode="Fill"; $G.SelectionMode="FullRowSelect"; $G.ReadOnly=$true
    $Parent.Controls.Add($G); return $G
}

# ==========================================
# TAB 1: TỔNG QUAN
# ==========================================
$TabSum = Make-Tab "Tong Quan"
$LvSum = Make-ListView $TabSum
$LvSum.Columns.Add("Thanh Phan", 250); $LvSum.Columns.Add("Thong Tin", 600)

function Load-Summary {
    $LvSum.Items.Clear()
    $OS = Get-CimInstance Win32_OperatingSystem
    $CS = Get-CimInstance Win32_ComputerSystem
    $Bios = Get-CimInstance Win32_BIOS
    $BB = Get-CimInstance Win32_BaseBoard

    Add-Item $LvSum "[HE DIEU HANH]" ""
    Add-Item $LvSum "Ten HDH" "$($OS.Caption)"
    Add-Item $LvSum "Phien ban" "$($OS.Version) (Build $($OS.BuildNumber))"
    Add-Item $LvSum "Kien truc" $OS.OSArchitecture
    Add-Item $LvSum "Nguoi dung" $env:USERNAME
    
    Add-Item $LvSum "" ""
    Add-Item $LvSum "[HE THONG]" ""
    Add-Item $LvSum "Ten May" $CS.Name
    Add-Item $LvSum "Hang San Xuat" $CS.Manufacturer
    Add-Item $LvSum "Model" $CS.Model
    
    Add-Item $LvSum "" ""
    Add-Item $LvSum "[MAINBOARD]" ""
    Add-Item $LvSum "Mainboard" "$($BB.Manufacturer) - $($BB.Product)"
    Add-Item $LvSum "BIOS Ver" "$($Bios.SMBIOSBIOSVersion) ($($Bios.ReleaseDate))"
    $BiosMode = "Legacy"; if (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State") { $BiosMode = "UEFI" }
    Add-Item $LvSum "BIOS Mode" $BiosMode
}

# ==========================================
# TAB 2: CPU & RAM
# ==========================================
$TabCpu = Make-Tab "CPU & RAM"
$LvCpu = Make-ListView $TabCpu
$LvCpu.Columns.Add("Thong So", 250); $LvCpu.Columns.Add("Gia Tri", 600)

function Load-CpuRam {
    $LvCpu.Items.Clear()
    $CPU = Get-CimInstance Win32_Processor
    Add-Item $LvCpu "[CPU]" $CPU.Name
    Add-Item $LvCpu "Socket" $CPU.SocketDesignation
    Add-Item $LvCpu "So Nhan/Luong" "$($CPU.NumberOfCores) Cores / $($CPU.NumberOfLogicalProcessors) Threads"
    
    Add-Item $LvCpu "" ""
    $Rams = Get-CimInstance Win32_PhysicalMemory; $TotalRAM = 0
    Add-Item $LvCpu "[RAM]" "Chi tiet:"
    foreach ($R in $Rams) {
        $SizeGB = [Math]::Round($R.Capacity / 1GB, 1); $TotalRAM += $R.Capacity
        Add-Item $LvCpu "  Slot $($R.DeviceLocator)" "$SizeGB GB - $($R.Speed) MHz - $($R.Manufacturer)"
    }
    Add-Item $LvCpu "--- TONG RAM ---" "$([Math]::Round($TotalRAM / 1GB, 1)) GB"
}

# ==========================================
# TAB 3: DISK
# ==========================================
$TabDisk = Make-Tab "Luu Tru (Disk)"
$GridDisk = Make-Grid $TabDisk
$GridDisk.Columns.Add("Id", "Disk #"); $GridDisk.Columns.Add("Model", "Ten O Cung"); $GridDisk.Columns.Add("Size", "Dung Luong"); $GridDisk.Columns.Add("Type", "Loai"); $GridDisk.Columns.Add("Part", "Kieu")

function Load-Storage {
    $Disks = Get-PhysicalDisk | Sort-Object DeviceId
    foreach ($D in $Disks) {
        $Size = [Math]::Round($D.Size / 1GB, 1).ToString() + " GB"
        $GridDisk.Rows.Add($D.DeviceId, $D.Model, $Size, $D.MediaType, $D.PartitionStyle) | Out-Null
    }
}

# ==========================================
# TAB 4: MANG (NETWORK)
# ==========================================
$TabNet = Make-Tab "Mang (Network)"
$LvNet = Make-ListView $TabNet
$LvNet.Columns.Add("Thong So", 200); $LvNet.Columns.Add("Gia Tri", 650)

function Load-Network {
    $LvNet.Items.Clear()
    $Nets = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled -eq $true}
    foreach ($N in $Nets) {
        Add-Item $LvNet "[CARD MANG]" $N.Description
        Add-Item $LvNet "MAC Address" $N.MACAddress
        Add-Item $LvNet "IPv4 Address" $N.IPAddress[0]
        Add-Item $LvNet "DNS Servers" ($N.DNSServerSearchOrder -join ", ")
        Add-Item $LvNet "---" "---"
    }
}

# ==========================================
# TAB 5: PIN (BATTERY HEALTH) - NEW !!!
# ==========================================
$TabBat = Make-Tab "PIN (Battery)"
$LvBat = Make-ListView $TabBat
$LvBat.Columns.Add("Thong So", 250); $LvBat.Columns.Add("Gia Tri", 600)

function Load-Battery {
    $LvBat.Items.Clear()
    try {
        # Cach 1: Dung WMI Battery (Co ban)
        $Bat = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
        
        if ($Bat) {
            Add-Item $LvBat "[TRANG THAI PIN]" ""
            Add-Item $LvBat "Ten Pin" $Bat.Name
            
            # Tinh toan % Pin
            Add-Item $LvBat "Dung Luong Hien Tai" "$($Bat.EstimatedChargeRemaining)%"
            
            # Status code
            $Status = switch ($Bat.BatteryStatus) {
                1 {"Dang xa (Discharging)"} 2 {"Dang Sac (Charging)"} 
                3 {"Day Pin (Fully Charged)"} 4 {"Thap (Low)"} 5 {"Rat Thap (Critical)"} 
                default {"Khong xac dinh"}
            }
            Add-Item $LvBat "Trang Thai" $Status
            Add-Item $LvBat "Volatage" "$($Bat.DesignVoltage) mV"

            Add-Item $LvBat "" ""
            Add-Item $LvBat "[DO CHAI PIN (HEALTH)]" "Dang quet bao cao..."
            
            # Cach 2: Generate Battery Report de lay thong tin Design Capacity (Chinh xac hon)
            # Tao report vao Temp
            $ReportPath = "$env:TEMP\battery-report.xml"
            powercfg /batteryreport /output "$ReportPath" /xml | Out-Null
            
            if (Test-Path $ReportPath) {
                [xml]$Xml = Get-Content $ReportPath
                $Design = $Xml.BatteryReport.Batteries.Battery.DesignCapacity
                $Full = $Xml.BatteryReport.Batteries.Battery.FullChargeCapacity
                
                if ($Design -and $Full) {
                    $Health = [Math]::Round(($Full / $Design) * 100, 1)
                    $Wear = [Math]::Round(100 - $Health, 1)
                    
                    Add-Item $LvBat "Dung luong Thiet Ke" "$Design mWh"
                    Add-Item $LvBat "Dung luong Thuc Te (Full)" "$Full mWh"
                    Add-Item $LvBat "Suc Khoe Pin (Health)" "$Health %"
                    Add-Item $LvBat "Do Chai Pin (Wear Level)" "$Wear %"
                    
                    if ($Health -lt 60) { 
                        $Item = New-Object System.Windows.Forms.ListViewItem("KHUYEN CAO")
                        $Item.SubItems.Add("PIN DA CHAI NHIEU -> NEN THAY THE!")
                        $Item.ForeColor = "Red"
                        $LvBat.Items.Add($Item)
                    }
                } else {
                    Add-Item $LvBat "Info" "Khong doc duoc chi so mWh tu XML."
                }
                Remove-Item $ReportPath -ErrorAction SilentlyContinue
            }
        } else {
            Add-Item $LvBat "KET QUA" "May tinh nay la DESKTOP hoac khong co Pin."
        }
    } catch {
        Add-Item $LvBat "Loi" "Khong the doc thong tin Pin."
    }
}

# ==========================================
# TAB 6: GPU & TAB 7: DRIVERS (Giu nguyen)
# ==========================================
$TabGpu = Make-Tab "Card Man Hinh (GPU)"; $LvGpu = Make-ListView $TabGpu; $LvGpu.Columns.Add("Thong So", 250); $LvGpu.Columns.Add("Gia Tri", 600)
function Load-GPU { $LvGpu.Items.Clear(); $GPUs = Get-CimInstance Win32_VideoController; foreach ($G in $GPUs) { Add-Item $LvGpu "[GPU]" $G.Name; Add-Item $LvGpu "VRAM" "$([Math]::Round($G.AdapterRAM / 1MB, 0)) MB"; Add-Item $LvGpu "Driver" $G.DriverVersion } }

$TabDrivers = Make-Tab "Drivers"; $GridDrv = Make-Grid $TabDrivers; $GridDrv.Columns.Add("N","Thiet Bi"); $GridDrv.Columns.Add("V","Ver"); $GridDrv.Columns.Add("D","Date")
function Load-AllDrivers { 
    $Ds = Get-WmiObject Win32_PnPSignedDriver | Where {$_.DeviceName}; foreach($d in $Ds){ $GridDrv.Rows.Add($d.DeviceName, $d.DriverVersion, $d.DriverDate) | Out-Null } 
}

# ==========================================
# BUTTONS & HTML EXPORT ENGINE (FIXED)
# ==========================================
$BtnReload = New-Object System.Windows.Forms.Button; $BtnReload.Text = "LAM MOI"; $BtnReload.Location = "10,560"; $BtnReload.Size = "150,40"; $BtnReload.BackColor = "LightBlue"
$BtnReload.Add_Click({ Run-All-Checks })
$Form.Controls.Add($BtnReload)

$BtnHTML = New-Object System.Windows.Forms.Button; $BtnHTML.Text = "XUAT HTML (FIXED)"; $BtnHTML.Location = "170,560"; $BtnHTML.Size = "150,40"; $BtnHTML.BackColor = "Orange"

# --- HTML GENERATOR ENGINE ---
$BtnHTML.Add_Click({
    $Path = "$env:USERPROFILE\Desktop\PC_Report_$($env:COMPUTERNAME).html"
    
    # CSS Styles
    $CSS = "<style>
        body { font-family: Segoe UI, sans-serif; padding: 20px; background: #f0f0f0; }
        .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 0 10px rgba(0,0,0,0.1); max-width: 1000px; margin: auto; }
        h1 { color: #0078d4; border-bottom: 2px solid #0078d4; padding-bottom: 10px; }
        h2 { background: #333; color: white; padding: 10px; margin-top: 30px; border-radius: 4px; font-size: 16px; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
        th { background-color: #f2f2f2; font-weight: bold; width: 30%; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>"

    # Builder
    $Html = New-Object System.Text.StringBuilder
    $Html.Append("<html><head><title>System Report</title><meta charset='utf-8'>$CSS</head><body><div class='container'>")
    $Html.Append("<h1>BAO CAO HE THONG - PHAT TAN PC</h1>")
    $Html.Append("<p><b>May tinh:</b> $($env:COMPUTERNAME) | <b>User:</b> $($env:USERNAME) | <b>Ngay:</b> $(Get-Date)</p>")

    # Helper convert ListView to Table
    function LvToHtml ($Lv, $Title) {
        $Html.Append("<h2>$Title</h2><table><tr><th>Thong So</th><th>Gia Tri</th></tr>")
        foreach ($Item in $Lv.Items) {
            $Col1 = $Item.Text; $Col2 = $Item.SubItems[1].Text
            if ($Col1 -like "[*") { $Html.Append("<tr><td colspan='2' style='background:#e1f5fe;font-weight:bold'>$Col1 $Col2</td></tr>") }
            else { $Html.Append("<tr><td>$Col1</td><td>$Col2</td></tr>") }
        }
        $Html.Append("</table>")
    }

    # Helper convert Grid to Table
    function GridToHtml ($Grid, $Title) {
        $Html.Append("<h2>$Title</h2><table><tr>")
        foreach ($Col in $Grid.Columns) { $Html.Append("<th>$($Col.HeaderText)</th>") }
        $Html.Append("</tr>")
        foreach ($Row in $Grid.Rows) {
            $Html.Append("<tr>")
            foreach ($Cell in $Row.Cells) { $Html.Append("<td>$($Cell.Value)</td>") }
            $Html.Append("</tr>")
        }
        $Html.Append("</table>")
    }

    # Generate Content
    LvToHtml $LvSum "1. TONG QUAN"
    LvToHtml $LvCpu "2. CPU & RAM"
    GridToHtml $GridDisk "3. LUU TRU (DISK)"
    LvToHtml $LvNet "4. MANG"
    LvToHtml $LvBat "5. PIN (BATTERY HEALTH)"
    LvToHtml $LvGpu "6. GPU"
    
    $Html.Append("</div></body></html>")
    
    # Save & Open
    $Html.ToString() | Out-File $Path -Encoding UTF8
    Invoke-Item $Path
    [System.Windows.Forms.MessageBox]::Show("Da xuat bao cao ra Desktop!", "Thanh Cong")
})
$Form.Controls.Add($BtnHTML)

# --- RUN ALL ---
function Run-All-Checks {
    Load-Summary; Load-CpuRam; Load-Storage; Load-Network; Load-Battery; Load-GPU; Load-AllDrivers
}
$Form.Add_Shown({ Run-All-Checks })
$Form.ShowDialog() | Out-Null
