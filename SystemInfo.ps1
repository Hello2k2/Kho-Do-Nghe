<#
    SYSTEM INFO PRO MAX - PHAT TAN PC
    Version: 9.0 (Detailed Disk Partition Tree + Battery + Fixed HTML)
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CHI TIẾT CẤU HÌNH - PHÁT TẤN PC (V9.0)"
$Form.Size = New-Object System.Drawing.Size(1000, 700)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = "White"
$Form.ForeColor = "Black"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# --- TAB CONTROL ---
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = New-Object System.Drawing.Point(10, 10)
$TabControl.Size = New-Object System.Drawing.Size(960, 550)
$Form.Controls.Add($TabControl)

# Helper Functions
function Make-Tab ($Title) {
    $Page = New-Object System.Windows.Forms.TabPage; $Page.Text = $Title
    $Page.BackColor = "White"; $Page.ForeColor = "Black"
    $TabControl.Controls.Add($Page); return $Page
}

function Make-ListView ($Parent) {
    $Lv = New-Object System.Windows.Forms.ListView
    $Lv.Size = New-Object System.Drawing.Size(950, 515); $Lv.Location = New-Object System.Drawing.Point(0, 0)
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
    $G.Size = New-Object System.Drawing.Size(950, 515); $G.Location = New-Object System.Drawing.Point(0, 0)
    $G.BackgroundColor = "White"; $G.ForeColor = "Black"
    $G.AllowUserToAddRows=$false; $G.RowHeadersVisible=$false; $G.AutoSizeColumnsMode="Fill"; $G.SelectionMode="FullRowSelect"; $G.ReadOnly=$true
    $Parent.Controls.Add($G); return $G
}

# ==========================================
# TAB 1: TỔNG QUAN
# ==========================================
$TabSum = Make-Tab "Tổng Quan"
$LvSum = Make-ListView $TabSum
$LvSum.Columns.Add("Thành Phần", 250); $LvSum.Columns.Add("Thông Tin", 650)

function Load-Summary {
    $LvSum.Items.Clear()
    $OS = Get-CimInstance Win32_OperatingSystem
    $CS = Get-CimInstance Win32_ComputerSystem
    $Bios = Get-CimInstance Win32_BIOS
    $BB = Get-CimInstance Win32_BaseBoard

    Add-Item $LvSum "[HỆ ĐIỀU HÀNH]" ""
    Add-Item $LvSum "Tên HĐH" "$($OS.Caption)"
    Add-Item $LvSum "Phiên bản" "$($OS.Version) (Build $($OS.BuildNumber))"
    Add-Item $LvSum "Kiến trúc" $OS.OSArchitecture
    Add-Item $LvSum "Người dùng" $env:USERNAME
    
    Add-Item $LvSum "" ""
    Add-Item $LvSum "[HỆ THỐNG]" ""
    Add-Item $LvSum "Tên Máy" $CS.Name
    Add-Item $LvSum "Hãng SX" $CS.Manufacturer
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
$LvCpu.Columns.Add("Thông Số", 250); $LvCpu.Columns.Add("Giá Trị", 650)

function Load-CpuRam {
    $LvCpu.Items.Clear()
    $CPU = Get-CimInstance Win32_Processor
    Add-Item $LvCpu "[CPU]" $CPU.Name
    Add-Item $LvCpu "Socket" $CPU.SocketDesignation
    Add-Item $LvCpu "Nhân/Luồng" "$($CPU.NumberOfCores) Cores / $($CPU.NumberOfLogicalProcessors) Threads"
    
    Add-Item $LvCpu "" ""
    $Rams = Get-CimInstance Win32_PhysicalMemory; $TotalRAM = 0
    Add-Item $LvCpu "[RAM]" "Chi tiết:"
    foreach ($R in $Rams) {
        $SizeGB = [Math]::Round($R.Capacity / 1GB, 1); $TotalRAM += $R.Capacity
        Add-Item $LvCpu "  Slot $($R.DeviceLocator)" "$SizeGB GB - $($R.Speed) MHz - $($R.Manufacturer)"
    }
    Add-Item $LvCpu "--- TỔNG RAM ---" "$([Math]::Round($TotalRAM / 1GB, 1)) GB"
}

# ==========================================
# TAB 3: LƯU TRỮ (DISK TREE) - NÂNG CẤP !!!
# ==========================================
$TabDisk = Make-Tab "Lưu Trữ (Disk)"
$GridDisk = Make-Grid $TabDisk
# Định nghĩa cột mới cho chi tiết phân vùng
$GridDisk.Columns.Add("Name", "Tên / Ổ Đĩa"); $GridDisk.Columns["Name"].FillWeight = 150
$GridDisk.Columns.Add("Label", "Nhãn (Label)"); $GridDisk.Columns["Label"].FillWeight = 100
$GridDisk.Columns.Add("Total", "Tổng Dung Lượng"); $GridDisk.Columns["Total"].FillWeight = 80
$GridDisk.Columns.Add("Free", "Còn Trống"); $GridDisk.Columns["Free"].FillWeight = 80
$GridDisk.Columns.Add("Type", "Định Dạng"); $GridDisk.Columns["Type"].FillWeight = 60
$GridDisk.Columns.Add("Status", "Trạng Thái"); $GridDisk.Columns["Status"].FillWeight = 80

function Load-Storage {
    $GridDisk.Rows.Clear()
    
    # 1. Lấy danh sách ổ cứng vật lý
    $Disks = Get-Disk | Sort-Object Number
    
    foreach ($D in $Disks) {
        # Tạo dòng Header cho ổ cứng vật lý (Màu xám đậm)
        $SizeGB = [Math]::Round($D.Size / 1GB, 0)
        $RowIndex = $GridDisk.Rows.Add("💿 DISK $($D.Number)", $D.FriendlyName, "$SizeGB GB", "-", $D.PartitionStyle, $D.HealthStatus)
        $GridDisk.Rows[$RowIndex].DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
        $GridDisk.Rows[$RowIndex].DefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)

        # 2. Lấy danh sách phân vùng của ổ cứng này
        $Parts = Get-Partition -DiskNumber $D.Number | Sort-Object PartitionNumber
        
        foreach ($P in $Parts) {
            # Lấy thông tin Volume (Dung lượng, Free space)
            $Vol = $P | Get-Volume -ErrorAction SilentlyContinue
            
            $DriveLetter = if ($P.DriveLetter) { "  [$($P.DriveLetter):]" } else { "  (Hidden)" }
            $Label = if ($Vol.FileSystemLabel) { $Vol.FileSystemLabel } else { $P.Type }
            
            # Tính toán dung lượng
            if ($Vol) {
                $Total = [Math]::Round($Vol.Size / 1GB, 1).ToString() + " GB"
                $Free = [Math]::Round($Vol.SizeRemaining / 1GB, 1).ToString() + " GB"
                $FS = $Vol.FileSystem
                
                # Tính % trống để hiện trạng thái
                $PercentFree = [Math]::Round(($Vol.SizeRemaining / $Vol.Size) * 100, 0)
                $StatusText = "$PercentFree% Free"
                if ($PercentFree -lt 10) { $StatusText += " (ĐẦY!)" }
            } else {
                # Các phân vùng hệ thống (Recovery, System Reserved) không có Volume info chi tiết
                $Total = [Math]::Round($P.Size / 1GB, 2).ToString() + " GB"
                $Free = "-"
                $FS = "-"
                $StatusText = "System/Recovery"
            }

            # Thêm dòng phân vùng
            $RowIdx = $GridDisk.Rows.Add($DriveLetter, $Label, $Total, $Free, $FS, $StatusText)
            
            # Tô màu đỏ nếu ổ đầy (<10% free)
            if ($StatusText -match "ĐẦY") { $GridDisk.Rows[$RowIdx].DefaultCellStyle.ForeColor = "Red" }
        }
    }
}

# ==========================================
# TAB 4: MẠNG (NETWORK)
# ==========================================
$TabNet = Make-Tab "Mạng (Network)"
$LvNet = Make-ListView $TabNet
$LvNet.Columns.Add("Thông Số", 200); $LvNet.Columns.Add("Giá Trị", 650)

function Load-Network {
    $LvNet.Items.Clear()
    $Nets = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled -eq $true}
    foreach ($N in $Nets) {
        Add-Item $LvNet "[CARD MẠNG]" $N.Description
        Add-Item $LvNet "MAC Address" $N.MACAddress
        Add-Item $LvNet "IPv4 Address" $N.IPAddress[0]
        if ($N.IPAddress[1]) { Add-Item $LvNet "IPv6 Address" $N.IPAddress[1] }
        Add-Item $LvNet "DHCP Server" $N.DHCPServer
        Add-Item $LvNet "DNS Servers" ($N.DNSServerSearchOrder -join ", ")
        Add-Item $LvNet "---" "---"
    }
}

# ==========================================
# TAB 5: PIN (BATTERY)
# ==========================================
$TabBat = Make-Tab "PIN (Battery)"
$LvBat = Make-ListView $TabBat
$LvBat.Columns.Add("Thông Số", 250); $LvBat.Columns.Add("Giá Trị", 650)

function Load-Battery {
    $LvBat.Items.Clear()
    try {
        $Bat = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
        if ($Bat) {
            Add-Item $LvBat "[TRẠNG THÁI]" ""
            Add-Item $LvBat "Tên Pin" $Bat.Name
            Add-Item $LvBat "Hiện Tại" "$($Bat.EstimatedChargeRemaining)%"
            
            $Status = switch ($Bat.BatteryStatus) { 1 {"Đang xả"} 2 {"Đang sạc"} 3 {"Đầy"} default {"Khác"} }
            Add-Item $LvBat "Tình trạng" $Status

            Add-Item $LvBat "" ""
            Add-Item $LvBat "[SỨC KHỎE (HEALTH)]" "Đang phân tích..."
            
            # Generate Report
            $ReportPath = "$env:TEMP\battery-report.xml"
            powercfg /batteryreport /output "$ReportPath" /xml | Out-Null
            
            if (Test-Path $ReportPath) {
                [xml]$Xml = Get-Content $ReportPath
                $Design = $Xml.BatteryReport.Batteries.Battery.DesignCapacity
                $Full = $Xml.BatteryReport.Batteries.Battery.FullChargeCapacity
                
                if ($Design -and $Full) {
                    $Health = [Math]::Round(($Full / $Design) * 100, 1)
                    $Wear = [Math]::Round(100 - $Health, 1)
                    
                    Add-Item $LvBat "Dung lượng Thiết Kế" "$Design mWh"
                    Add-Item $LvBat "Dung lượng Thực Tế" "$Full mWh"
                    Add-Item $LvBat "Độ Chai Pin (Wear)" "$Wear %"
                    Add-Item $LvBat "Sức Khỏe (Health)" "$Health %"
                    
                    if ($Health -lt 60) { 
                        $Item = New-Object System.Windows.Forms.ListViewItem("CẢNH BÁO"); $Item.SubItems.Add("PIN CHAI > 40% -> NÊN THAY!"); $Item.ForeColor = "Red"; $LvBat.Items.Add($Item)
                    }
                }
                Remove-Item $ReportPath -ErrorAction SilentlyContinue
            }
        } else { Add-Item $LvBat "KẾT QUẢ" "Không tìm thấy Pin (Máy bàn/Desktop)." }
    } catch { Add-Item $LvBat "Lỗi" "Không đọc được thông tin." }
}

# ==========================================
# TAB 6 & 7: GPU & DRIVERS
# ==========================================
$TabGpu = Make-Tab "GPU (Card Hình)"; $LvGpu = Make-ListView $TabGpu; $LvGpu.Columns.Add("Thông Số", 250); $LvGpu.Columns.Add("Giá Trị", 650)
function Load-GPU { $LvGpu.Items.Clear(); $GPUs = Get-CimInstance Win32_VideoController; foreach ($G in $GPUs) { Add-Item $LvGpu "[GPU]" $G.Name; Add-Item $LvGpu "VRAM" "$([Math]::Round($G.AdapterRAM / 1MB, 0)) MB"; Add-Item $LvGpu "Driver" $G.DriverVersion } }

$TabDrivers = Make-Tab "Drivers"; $GridDrv = Make-Grid $TabDrivers; $GridDrv.Columns.Add("N","Thiết Bị"); $GridDrv.Columns.Add("V","Phiên Bản"); $GridDrv.Columns.Add("D","Ngày")
function Load-AllDrivers { 
    $Ds = Get-WmiObject Win32_PnPSignedDriver | Where {$_.DeviceName}; foreach($d in $Ds){ 
        try{$Date=[DateTime]::ParseExact($d.DriverDate.Substring(0,8),"yyyyMMdd",$null).ToString("yyyy-MM-dd")}catch{$Date=""}
        $GridDrv.Rows.Add($d.DeviceName, $d.DriverVersion, $Date) | Out-Null 
    } 
}

# ==========================================
# EXPORT HTML ENGINE
# ==========================================
$BtnReload = New-Object System.Windows.Forms.Button; $BtnReload.Text = "LÀM MỚI"; $BtnReload.Location = "10,580"; $BtnReload.Size = "150,40"; $BtnReload.BackColor = "LightBlue"
$BtnReload.Add_Click({ Run-All-Checks })
$Form.Controls.Add($BtnReload)

$BtnHTML = New-Object System.Windows.Forms.Button; $BtnHTML.Text = "XUẤT BÁO CÁO HTML"; $BtnHTML.Location = "170,580"; $BtnHTML.Size = "180,40"; $BtnHTML.BackColor = "Orange"

$BtnHTML.Add_Click({
    $Path = "$env:USERPROFILE\Desktop\PC_Report_$($env:COMPUTERNAME).html"
    $CSS = "<style>body{font-family:Segoe UI;padding:20px;background:#f4f4f4}.box{background:white;padding:20px;border-radius:8px;box-shadow:0 2px 5px rgba(0,0,0,0.1);margin-bottom:20px}h2{color:#0078d4;border-bottom:2px solid #ddd;padding-bottom:10px}table{width:100%;border-collapse:collapse}th,td{border:1px solid #ddd;padding:8px;text-align:left}th{background:#f0f0f0}tr:nth-child(even){background:#fafafa}.red{color:red;font-weight:bold}.gray{background:#e0e0e0;font-weight:bold}</style>"
    
    $Html = New-Object System.Text.StringBuilder
    $Html.Append("<html><head><meta charset='utf-8'>$CSS</head><body><h1>BÁO CÁO HỆ THỐNG - PHÁT TẤN PC</h1><p>Máy: $($env:COMPUTERNAME) | User: $($env:USERNAME) | Ngày: $(Get-Date)</p>")

    function Tbl ($Title, $Headers, $Rows) {
        $Html.Append("<div class='box'><h2>$Title</h2><table><tr>")
        foreach($h in $Headers){$Html.Append("<th>$h</th>")}
        $Html.Append("</tr>")
        foreach($r in $Rows){
            $Class = if($r[0] -match "DISK"){"class='gray'"}else{""}
            $Html.Append("<tr $Class>"); foreach($c in $r){$Html.Append("<td>$c</td>")}; $Html.Append("</tr>")
        }
        $Html.Append("</table></div>")
    }

    # Data Extractors
    $R_Sum = @(); foreach($i in $LvSum.Items){$R_Sum+=@($i.Text, $i.SubItems[1].Text)}
    Tbl "1. TỔNG QUAN" @("Thông Số","Giá Trị") $R_Sum

    $R_Disk = @(); foreach($r in $GridDisk.Rows){$R_Disk+=@($r.Cells[0].Value,$r.Cells[1].Value,$r.Cells[2].Value,$r.Cells[3].Value,$r.Cells[4].Value,$r.Cells[5].Value)}
    Tbl "2. LƯU TRỮ (DISK DETAIL)" @("Tên/Ổ","Nhãn","Tổng","Trống","Kiểu","Trạng Thái") $R_Disk

    $R_Bat = @(); foreach($i in $LvBat.Items){$R_Bat+=@($i.Text, $i.SubItems[1].Text)}
    Tbl "3. PIN (BATTERY)" @("Thông Số","Giá Trị") $R_Bat

    $Html.Append("</body></html>")
    $Html.ToString() | Out-File $Path -Encoding UTF8
    Invoke-Item $Path
    [System.Windows.Forms.MessageBox]::Show("Đã xuất file HTML ra Desktop!", "Thành công")
})
$Form.Controls.Add($BtnHTML)

function Run-All-Checks {
    Load-Summary; Load-CpuRam; Load-Storage; Load-Network; Load-Battery; Load-GPU; Load-AllDrivers
}
$Form.Add_Shown({ Run-All-Checks })
$Form.ShowDialog() | Out-Null
