<#
    SYSTEM INFO PRO - PHAT TAN PC
    Version: 3.0 (GUI Tabs & Grids)
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "MAY SOI CAU HINH - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(900, 600)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# --- TAB CONTROL ---
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = New-Object System.Drawing.Point(10, 10)
$TabControl.Size = New-Object System.Drawing.Size(865, 480)
$Form.Controls.Add($TabControl)

# Hàm hỗ trợ tạo Tab và Grid
function Make-Tab ($Title) {
    $Page = New-Object System.Windows.Forms.TabPage
    $Page.Text = $Title
    $Page.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
    $Page.ForeColor = "Black" 
    $TabControl.Controls.Add($Page)
    return $Page
}

function Make-Grid ($ParentTab) {
    $G = New-Object System.Windows.Forms.DataGridView
    $G.Size = New-Object System.Drawing.Size(855, 450); $G.Location = New-Object System.Drawing.Point(0, 0)
    $G.BackgroundColor = "Black"; $G.ForeColor = "Black"
    $G.AllowUserToAddRows = $false; $G.RowHeadersVisible = $false
    $G.AutoSizeColumnsMode = "Fill"; $G.SelectionMode = "FullRowSelect"; $G.ReadOnly = $true
    $ParentTab.Controls.Add($G)
    return $G
}

function Make-Label ($Parent, $Text, $X, $Y, $FontData="10") {
    $L = New-Object System.Windows.Forms.Label
    $L.Text = $Text; $L.Location = New-Object System.Drawing.Point($X, $Y); $L.AutoSize = $true
    $L.Font = New-Object System.Drawing.Font("Segoe UI", $FontData); $L.ForeColor = "Lime"
    $Parent.Controls.Add($L)
    return $L
}

# ==========================================
# TAB 1: TỔNG QUAN (DASHBOARD)
# ==========================================
$Tab1 = Make-Tab "Tong Quan"
$Tab1.BackColor = "Black" # Tab này dùng Label nên để nền đen

$OS = Get-CimInstance Win32_OperatingSystem
$CS = Get-CimInstance Win32_ComputerSystem
$Bios = Get-CimInstance Win32_BIOS
$CPU = Get-CimInstance Win32_Processor

Make-Label $Tab1 "HE THONG:" 20 20 "12"
Make-Label $Tab1 "  + HDH:       $($OS.Caption) ($($OS.OSArchitecture))" 20 50
Make-Label $Tab1 "  + Phien ban: $($OS.Version) (Build $($OS.BuildNumber))" 20 80
Make-Label $Tab1 "  + May tinh:  $($CS.Name) (User: $($env:USERNAME))" 20 110
Make-Label $Tab1 "  + Ngay cai:  $($OS.InstallDate)" 20 140

Make-Label $Tab1 "PHAN CUNG:" 20 190 "12"
Make-Label $Tab1 "  + Mainboard: $($CS.Manufacturer) - $($CS.Model)" 20 220
Make-Label $Tab1 "  + BIOS:      $($Bios.SMBIOSBIOSVersion) ($($Bios.ReleaseDate))" 20 250
Make-Label $Tab1 "  + CPU:       $($CPU.Name)" 20 280
# Fix lỗi RAM hiển thị
$RamGB = [Math]::Round($CS.TotalPhysicalMemory / 1GB, 2)
Make-Label $Tab1 "  + RAM:       $RamGB GB" 20 310

# ==========================================
# TAB 2: O CUNG (DISK) - DẠNG BẢNG
# ==========================================
$Tab2 = Make-Tab "O Cung (Disk)"
$GridDisk = Make-Grid $Tab2
$GridDisk.Columns.Add("Disk", "Disk #"); $GridDisk.Columns.Add("Model", "Ten O Cung")
$GridDisk.Columns.Add("Size", "Dung Luong (GB)"); $GridDisk.Columns.Add("Type", "Chuan (GPT/MBR)")
$GridDisk.Columns.Add("Status", "Trang Thai")

function Load-Disks {
    $Disks = Get-Disk
    foreach ($D in $Disks) {
        $Size = [Math]::Round($D.Size / 1GB, 1)
        $GridDisk.Rows.Add($D.Number, $D.Model, $Size, $D.PartitionStyle, $D.HealthStatus) | Out-Null
    }
}

# ==========================================
# TAB 3: MANG (NETWORK) - DẠNG BẢNG
# ==========================================
$Tab3 = Make-Tab "Mang (Network)"
$GridNet = Make-Grid $Tab3
$GridNet.Columns.Add("Name", "Ten Card"); $GridNet.Columns.Add("IP", "IP Address")
$GridNet.Columns.Add("MAC", "MAC Address"); $GridNet.Columns.Add("DHCP", "DHCP")

function Load-Network {
    $Nets = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled -eq $true}
    foreach ($N in $Nets) {
        $GridNet.Rows.Add($N.Description, $N.IPAddress[0], $N.MACAddress, $N.DHCPEnabled) | Out-Null
    }
}

# ==========================================
# TAB 4: DRIVERS (DẠNG BẢNG CHI TIẾT)
# ==========================================
$Tab4 = Make-Tab "Drivers"
$GridDrv = Make-Grid $Tab4
$GridDrv.Columns.Add("Name", "Thiet Bi"); $GridDrv.Columns.Add("Provider", "Nha Cung Cap")
$GridDrv.Columns.Add("Version", "Phien Ban"); $GridDrv.Columns.Add("Date", "Ngay")

function Load-Drivers {
    $Drivers = Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -ne $null } | Select-Object DeviceName, Manufacturer, DriverVersion, DriverDate
    foreach ($D in $Drivers) {
        try { $Date = [DateTime]::ParseExact($D.DriverDate.Substring(0,8), "yyyyMMdd", $null).ToString("yyyy-MM-dd") } catch { $Date = "" }
        $GridDrv.Rows.Add($D.DeviceName, $D.Manufacturer, $D.DriverVersion, $Date) | Out-Null
    }
}

# ==========================================
# BUTTONS & LOAD
# ==========================================
$BtnRefresh = New-Object System.Windows.Forms.Button
$BtnRefresh.Text = "LAM MOI DU LIEU"; $BtnRefresh.Location = "20,500"; $BtnRefresh.Size = "150,40"
$BtnRefresh.BackColor = "Cyan"; $BtnRefresh.ForeColor = "Black"; $BtnRefresh.FlatStyle = "Flat"
$BtnRefresh.Add_Click({
    $GridDisk.Rows.Clear(); Load-Disks
    $GridNet.Rows.Clear(); Load-Network
    $GridDrv.Rows.Clear(); Load-Drivers
    [System.Windows.Forms.MessageBox]::Show("Da cap nhat thong tin!", "Phat Tan PC")
})
$Form.Controls.Add($BtnRefresh)

$BtnExport = New-Object System.Windows.Forms.Button
$BtnExport.Text = "XUAT FILE HTML"; $BtnExport.Location = "200,500"; $BtnExport.Size = "150,40"
$BtnExport.BackColor = "Orange"; $BtnExport.ForeColor = "Black"; $BtnExport.FlatStyle = "Flat"
$BtnExport.Add_Click({
    $Path = "$env:USERPROFILE\Desktop\System_Report.html"
    $H = "<h1>BAO CAO HE THONG - PHAT TAN PC</h1><hr>"
    $H += "<h3>TONG QUAN</h3><p>OS: $($OS.Caption)</p><p>CPU: $($CPU.Name)</p><p>RAM: $RamGB GB</p>"
    $H += "<h3>DRIVER</h3>" + ($GridDrv.DataSource | ConvertTo-Html -Fragment) # Demo đơn giản
    $H | Out-File $Path
    Invoke-Item $Path
})
$Form.Controls.Add($BtnExport)

# --- RUN ---
Load-Disks
Load-Network
# Load Drivers chạy ngầm để không đơ lúc mở
$Form.Add_Shown({ 
    $Form.Refresh()
    Load-Drivers 
})

$Form.ShowDialog() | Out-Null
