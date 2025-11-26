<#
    SYSTEM INFO PRO MAX - PHAT TAN PC
    Version: 7.0 (Added Network Detail)
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CHI TIET CAU HINH - PHAT TAN PC (V7.0)"
$Form.Size = New-Object System.Drawing.Size(950, 650)
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

# Hàm tạo Tab & Grid/ListView
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
    $TZ = Get-CimInstance Win32_TimeZone

    Add-Item $LvSum "[HE DIEU HANH]" ""
    Add-Item $LvSum "Ten HDH" "$($OS.Caption)"
    Add-Item $LvSum "Phien ban" "$($OS.Version) (Build $($OS.BuildNumber))"
    Add-Item $LvSum "Kien truc" $OS.OSArchitecture
    Add-Item $LvSum "Ngay cai dat" $OS.InstallDate
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
    Add-Item $LvCpu "Toc Do" "$($CPU.MaxClockSpeed) MHz"
    
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
# TAB 4: MANG (NETWORK) - NEW!!!
# ==========================================
$TabNet = Make-Tab "Mang (Network)"
$LvNet = Make-ListView $TabNet
$LvNet.Columns.Add("Thong So", 200); $LvNet.Columns.Add("Gia Tri", 650)

function Load-Network {
    $LvNet.Items.Clear()
    # Chỉ lấy card đang có IP (Đang kết nối)
    $Nets = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled -eq $true}
    
    foreach ($N in $Nets) {
        Add-Item $LvNet "[CARD MANG]" $N.Description
        Add-Item $LvNet "MAC Address" $N.MACAddress
        Add-Item $LvNet "IPv4 Address" $N.IPAddress[0]
        if ($N.IPAddress.Count -gt 1) { Add-Item $LvNet "IPv6 Address" $N.IPAddress[1] }
        Add-Item $LvNet "Subnet Mask" $N.IPSubnet[0]
        Add-Item $LvNet "Default Gateway" $N.DefaultIPGateway[0]
        Add-Item $LvNet "DHCP Enabled" $(if($N.DHCPEnabled){"Yes (Server: $($N.DHCPServer))"}else{"No (Static IP)"})
        Add-Item $LvNet "DNS Servers" ($N.DNSServerSearchOrder -join ", ")
        Add-Item $LvNet "---" "---"
    }
}

# ==========================================
# TAB 5: GPU
# ==========================================
$TabGpu = Make-Tab "Card Man Hinh (GPU)"
$LvGpu = Make-ListView $TabGpu
$LvGpu.Columns.Add("Thong So", 250); $LvGpu.Columns.Add("Gia Tri", 600)

function Load-GPU {
    $LvGpu.Items.Clear()
    $GPUs = Get-CimInstance Win32_VideoController
    foreach ($G in $GPUs) {
        Add-Item $LvGpu "[GPU]" $G.Name
        $VRAM = [Math]::Round($G.AdapterRAM / 1MB, 0); if ($VRAM -gt 0) { Add-Item $LvGpu "VRAM" "$VRAM MB" }
        Add-Item $LvGpu "Driver Version" $G.DriverVersion
        Add-Item $LvGpu "Do Phan Giai" "$($G.CurrentHorizontalResolution) x $($G.CurrentVerticalResolution) @ $($G.CurrentRefreshRate)Hz"
        Add-Item $LvGpu "---" "---"
    }
}

# ==========================================
# TAB 6: NGOAI VI (PERIPHERALS)
# ==========================================
$TabPeri = Make-Tab "Ngoai Vi"
$LvPeri = Make-ListView $TabPeri
$LvPeri.Columns.Add("Loai", 200); $LvPeri.Columns.Add("Ten Thiet Bi", 650)

function Load-Peripherals {
    $LvPeri.Items.Clear()
    $Kbds = Get-CimInstance Win32_Keyboard; foreach ($K in $Kbds) { Add-Item $LvPeri "Ban Phim" $K.Description }
    $Mice = Get-CimInstance Win32_PointingDevice; foreach ($M in $Mice) { Add-Item $LvPeri "Chuot" "$($M.Description) - $($M.Manufacturer)" }
    $Printers = Get-CimInstance Win32_Printer; foreach ($P in $Printers) { Add-Item $LvPeri "May In" "$($P.Name)" }
    $Sounds = Get-CimInstance Win32_SoundDevice | Where-Object { $_.Status -eq "OK" }; foreach ($S in $Sounds) { Add-Item $LvPeri "Am Thanh" $S.Name }
}

# ==========================================
# TAB 7: DRIVERS
# ==========================================
$TabDrivers = Make-Tab "Tat Ca Driver"
$GridDrv = Make-Grid $TabDrivers
$GridDrv.Columns.Add("Name", "Thiet Bi"); $GridDrv.Columns.Add("Version", "Phien Ban"); $GridDrv.Columns.Add("Date", "Ngay")

function Load-AllDrivers {
    $Drivers = Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -ne $null } | Select DeviceName, DriverVersion, DriverDate
    foreach ($D in $Drivers) {
        try { $DDate = [DateTime]::ParseExact($D.DriverDate.Substring(0,8), "yyyyMMdd", $null).ToString("yyyy-MM-dd") } catch { $DDate = "" }
        $GridDrv.Rows.Add($D.DeviceName, $D.DriverVersion, $DDate) | Out-Null
    }
}

# ==========================================
# BUTTONS
# ==========================================
$BtnReload = New-Object System.Windows.Forms.Button; $BtnReload.Text = "LAM MOI"; $BtnReload.Location = "10,560"; $BtnReload.Size = "150,40"; $BtnReload.BackColor = "LightBlue"
$BtnReload.Add_Click({ Run-All-Checks })
$Form.Controls.Add($BtnReload)

$BtnHTML = New-Object System.Windows.Forms.Button; $BtnHTML.Text = "XUAT HTML"; $BtnHTML.Location = "170,560"; $BtnHTML.Size = "150,40"; $BtnHTML.BackColor = "Orange"
$BtnHTML.Add_Click({
    $Path = "$env:USERPROFILE\Desktop\PC_Info.html"
    $H = "<h1>BAO CAO - PHAT TAN PC</h1><hr><h2>HE THONG</h2>$($env:COMPUTERNAME)<br>$($env:USERNAME)"
    $H | Out-File $Path; Invoke-Item $Path
})
$Form.Controls.Add($BtnHTML)

# --- RUN ALL ---
function Run-All-Checks {
    Load-Summary; Load-CpuRam; Load-Storage; Load-Network; Load-GPU; Load-Peripherals; Load-AllDrivers
}
$Form.Add_Shown({ Run-All-Checks })
$Form.ShowDialog() | Out-Null
