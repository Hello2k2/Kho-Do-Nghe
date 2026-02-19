<#
    PHAT TAN PC - V39.0 TITAN COMPACT GOD (ULTIMATE RAM MASTER)
    Update: 
    - Viết lại toàn bộ hệ thống đọc khe RAM. Hiện bảng Grid chi tiết cho từng thanh.
    - Soi tận răng: Hãng, Dung lượng, Tốc độ, Part Number, Serial, Loại RAM (DDR3/4/5), Voltage.
    - Sửa lỗi hiện số "3" vô duyên ở bản cũ.
#>

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ĐANG KHỞI ĐỘNG LẠI VỚI QUYỀN ADMINISTRATOR..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; $ErrorActionPreference = "SilentlyContinue"

# --- ENGINE BENCHMARK C# ---
$BenchCode = @"
using System; using System.Diagnostics; using System.Threading.Tasks; using System.IO;
public class TitanBench {
    public static double RunCpuMultiCore() {
        Stopwatch sw = Stopwatch.StartNew();
        Parallel.For(1, 2000, i => { double x = 0; for(int j=1; j<100000; j++){ x += Math.Sqrt(j) * Math.Atan(i); } });
        sw.Stop(); return Math.Round(10000000.0 / sw.ElapsedMilliseconds, 0);
    }
    public static double RunDiskWrite(string path) {
        byte[] data = new byte[1024 * 1024 * 50]; new Random().NextBytes(data); Stopwatch sw = Stopwatch.StartNew();
        using (FileStream fs = new FileStream(path, FileMode.Create, FileAccess.Write, FileShare.None, 8192, FileOptions.WriteThrough)) {
            for(int i=0; i<10; i++) fs.Write(data, 0, data.Length);
        }
        sw.Stop(); return Math.Round(500.0 / sw.Elapsed.TotalSeconds, 1);
    }
}
"@
Add-Type -TypeDefinition $BenchCode -Language CSharp -ErrorAction SilentlyContinue

# --- TẢI LHM ---
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$InstallDir = "$env:LOCALAPPDATA\PhatTanPC"
if (!(Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir | Out-Null }
$dllPath = "$InstallDir\LibreHardwareMonitorLib.dll"

if (-not (Test-Path $dllPath)) {
    try { Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/LibreHardwareMonitorLib" -OutFile "$env:TEMP\lhm.zip" -UseBasicParsing; Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFileExtensions]::ExtractToFile(([System.IO.Compression.ZipFile]::OpenRead("$env:TEMP\lhm.zip").Entries | ? { $_.FullName -match "LibreHardwareMonitorLib.dll$" }), $dllPath, $true); Remove-Item "$env:TEMP\lhm.zip" -Force } catch {}
}
try { Add-Type -Path $dllPath; $PC = New-Object LibreHardwareMonitor.Hardware.Computer; $PC.IsCpuEnabled = $true; $PC.IsStorageEnabled = $true; $PC.IsMotherboardEnabled = $true; $PC.IsMemoryEnabled = $true; $PC.IsGpuEnabled = $true; $PC.Open(); [System.Windows.Forms.Application]::ApplicationExit += { $PC.Close() } } catch {}

# --- THEME CƠ BẢN ---
$C_Bg = [System.Drawing.Color]::FromArgb(10, 10, 15); $C_Panel = [System.Drawing.Color]::FromArgb(20, 20, 28)
$C_Cyan = [System.Drawing.Color]::FromArgb(0, 255, 255); $C_Lime = [System.Drawing.Color]::FromArgb(50, 205, 50)
$C_Pink = [System.Drawing.Color]::FromArgb(255, 20, 147); $C_Text = [System.Drawing.Color]::WhiteSmoke
$FontBold = New-Object System.Drawing.Font("Segoe UI", 10, 1); $FontHead = New-Object System.Drawing.Font("Segoe UI", 12, 1)

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "PHAT TAN PC - TITAN V39.0 (ULTIMATE RAM MASTER)"; $Form.Size = "1280, 850"; $Form.StartPosition = "CenterScreen"; $Form.BackColor = $C_Bg; $Form.ForeColor = $C_Text; $Form.DoubleBuffered = $true 

# HÀM RENDER UI
function Make-Group ($P, $T, $R, $C) { $G = New-Object System.Windows.Forms.GroupBox; $G.Text=$T; $G.Location="$($R[0]),$($R[1])"; $G.Size="$($R[2]),$($R[3])"; $G.ForeColor=[System.Drawing.Color]::FromName($C); $G.Font=$FontBold; $P.Controls.Add($G); return $G }
function Make-Label ($P, $T, $X, $Y, $C, $Cur=$false, $W=260) { $L = New-Object System.Windows.Forms.Label; $L.Text=$T; $L.Location="$X,$Y"; $L.AutoSize=$true; $L.MaximumSize=New-Object System.Drawing.Size($W, 0); $L.ForeColor=[System.Drawing.Color]::FromName($C); if($Cur){$L.Cursor=[System.Windows.Forms.Cursors]::Hand}; $P.Controls.Add($L); return $L }
function Make-Gauge ($Parent, $X, $Y, $ColorPen) {
    $Pic = New-Object System.Windows.Forms.PictureBox; $Pic.Location = "$X, $Y"; $Pic.Size = "150, 150"; $Pic.BackColor = "Transparent"; $Pic.Tag = 0 
    $Pic.Add_Paint({
        param($sender, $e); $g = $e.Graphics; $g.SmoothingMode = 4
        $Rect = New-Object System.Drawing.Rectangle(10, 10, 130, 130); $PenBack = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40,40,40), 15); $g.DrawArc($PenBack, $Rect, 135, 270); $PenBack.Dispose()
        $Val = if ($sender.Tag -ne $null) { [int]$sender.Tag } else { 0 }; if ($Val -gt 100) { $Val = 100 }
        if ($Val -gt 0) { $Angle = [Math]::Round(($Val / 100) * 270); $PenFore = New-Object System.Drawing.Pen($ColorPen, 15); $PenFore.StartCap = 2; $PenFore.EndCap = 2; $g.DrawArc($PenFore, $Rect, 135, $Angle); $PenFore.Dispose() }
        $F = New-Object System.Drawing.Font("Impact", 24); $Brush = New-Object System.Drawing.SolidBrush($ColorPen); $Str = "$Val%"; $Sz = $g.MeasureString($Str, $F); $g.DrawString($Str, $F, $Brush, (75 - $Sz.Width/2), (75 - $Sz.Height/2)); $Brush.Dispose(); $F.Dispose()
    }.GetNewClosure()); $Parent.Controls.Add($Pic); return $Pic
}
function Show-PopUp ($Title, $InfoString) {
    $Pop = New-Object System.Windows.Forms.Form; $Pop.Text = $Title; $Pop.Size = "700, 550"; $Pop.StartPosition = "CenterParent"; $Pop.BackColor = $C_Bg; $Pop.FormBorderStyle = "FixedDialog"
    $Rtb = New-Object System.Windows.Forms.RichTextBox; $Rtb.Location="10,10"; $Rtb.Size="665,440"; $Rtb.BackColor = $C_Panel; $Rtb.ForeColor = $C_Lime; $Rtb.Font = New-Object System.Drawing.Font("Consolas", 10); $Rtb.ReadOnly = $true; $Rtb.Text = $InfoString; $Pop.Controls.Add($Rtb)
    $BtnClose = New-Object System.Windows.Forms.Button; $BtnClose.Text="[ X ] ĐÓNG CỬA SỔ"; $BtnClose.Location="200,460"; $BtnClose.Size="250,40"; $BtnClose.BackColor="Maroon"; $BtnClose.ForeColor="White"; $BtnClose.Add_Click({$Pop.Close()}); $Pop.Controls.Add($BtnClose)
    $Pop.ShowDialog() | Out-Null
}

# ================= LẤY DATA CƠ BẢN =================
$WmiOS = Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber, OSArchitecture, TotalVisibleMemorySize, InstallDate, BootDevice
$WmiCPU = Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, SocketDesignation, L2CacheSize, L3CacheSize, MaxClockSpeed
$TotalRAM_MB = [Math]::Round($WmiOS.TotalVisibleMemorySize / 1024, 0)
$WmiGPU = try { (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name } catch { "Generic VGA" }
$WmiCS = Get-CimInstance Win32_ComputerSystem
$WmiBIOS = Get-CimInstance Win32_BIOS
$SysType = if ((Get-CimInstance Win32_SystemEnclosure).ChassisTypes -contains 10) { "Laptop" } else { "Desktop/VM" }
$TpmSupport = "Tắt / Không Hỗ Trợ"; try { $Tpm = Get-WmiObject -Namespace "Root\CIMV2\Security\MicrosoftTpm" -Class Win32_Tpm -ErrorAction Stop; if ($Tpm.SpecVersion -match "2.0") { $TpmSupport = "Có (Sẵn sàng Win 11)" } elseif ($Tpm) { $TpmSupport = "Bản cũ ($($Tpm.SpecVersion))" } } catch {}
$WinKey = try { (Get-CimInstance -Query "select OA3xOriginalProductKey from SoftwareLicensingService").OA3xOriginalProductKey } catch {}; if(!$WinKey){$WinKey="Digital License / N/A"}

$OfficeInfo = "Không tìm thấy (Hoặc dùng bản Web/Portable)"
try { $OffReg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | ? { $_.DisplayName -match "Microsoft Office" -and $_.DisplayName -notmatch "Update" } | Select -First 1; if ($OffReg) { $OfficeInfo = "$($OffReg.DisplayName) (Version: $($OffReg.DisplayVersion))" } } catch {}

# ================= LAYOUT CHÍNH =================

# --- CPU ---
$GrpCpu = Make-Group $Form " CPU " @(10, 10, 300, 240) "Cyan"; $GaugeCpu = Make-Gauge $GrpCpu 75 30 $C_Cyan
Make-Label $GrpCpu "$($WmiCPU.Name)" 10 180 "White" $false 280 | Out-Null
$LblCpuBtn = Make-Label $GrpCpu "[ i ] Bấm xem Chi tiết & RAM App" 10 210 "Silver" $true 280
$LblCpuBtn.Add_Click({ 
    $I = "========== CHI TIẾT BỘ VI XỬ LÝ ==========`nTên CPU      : $($WmiCPU.Name)`nSố nhân      : $($WmiCPU.NumberOfCores) Cores / $($WmiCPU.NumberOfLogicalProcessors) Threads`nSocket       : $(if($WmiCPU.SocketDesignation){$WmiCPU.SocketDesignation}else{'VM/N/A'})`nL2 Cache     : $(if($WmiCPU.L2CacheSize){$WmiCPU.L2CacheSize}else{0}) KB`nL3 Cache     : $(if($WmiCPU.L3CacheSize){$WmiCPU.L3CacheSize}else{0}) KB`nBase Clock   : $($WmiCPU.MaxClockSpeed) MHz`n`n--- BẢO MẬT PHẦN CỨNG ---`nTPM 2.0 State: $TpmSupport`n" 
    $I += "`n--- TOP 5 TIẾN TRÌNH ĐANG NGỐN RAM ---`n"
    Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 5 | % { $I += "• $($_.Name.PadRight(20)) : $([Math]::Round($_.WorkingSet/1MB, 1)) MB`n" }
    Show-PopUp "CPU & PROCESS MASTER" $I
})

# --- RAM TỐI THƯỢNG (NEW) ---
$GrpRam = Make-Group $Form " RAM " @(320, 10, 300, 240) "Magenta"; $GaugeRam = Make-Gauge $GrpRam 75 30 $C_Pink
$LblRamTotal = Make-Label $GrpRam "[ i ] Bấm xem Bảng Chi tiết khe RAM" 10 180 "White" $true 280
$LblRamAvail = Make-Label $GrpRam "Trống: Đang tính..." 10 210 "Lime" 280

$LblRamTotal.Add_Click({
    $PRam = New-Object System.Windows.Forms.Form; $PRam.Text = "RAM HARDWARE MASTER"; $PRam.Size = "900, 500"; $PRam.StartPosition = "CenterParent"; $PRam.BackColor = $C_Bg
    
    Make-Label $PRam ">> TỔNG DUNG LƯỢNG VẬT LÝ: $([Math]::Round($TotalRAM_MB/1024, 2)) GB" 10 15 "Lime" $false 800 | Out-Null
    Make-Label $PRam ">> DUNG LƯỢNG HOÁN ĐỔI (VIRTUAL): $([Math]::Round($WmiOS.TotalVirtualMemorySize/1024/1024, 2)) GB" 10 40 "Silver" $false 800 | Out-Null
    
    $GridRam = New-Object System.Windows.Forms.DataGridView; $GridRam.Location="10,80"; $GridRam.Size="860,350"; $GridRam.BackgroundColor=$C_Panel; $GridRam.ForeColor="Black"; $GridRam.AutoSizeColumnsMode="Fill"; $GridRam.ReadOnly=$true; $GridRam.SelectionMode="FullRowSelect"; $GridRam.AllowUserToAddRows=$false
    $GridRam.Columns.Add("Slot","Khe cắm"); $GridRam.Columns.Add("Manu","Hãng SX"); $GridRam.Columns.Add("Cap","Dung lượng"); $GridRam.Columns.Add("Spd","Tốc độ"); $GridRam.Columns.Add("Type","Loại"); $GridRam.Columns.Add("Part","Part Number"); $GridRam.Columns.Add("Volt","Điện áp") | Out-Null
    $PRam.Controls.Add($GridRam)
    
    $RAMs = Get-CimInstance Win32_PhysicalMemory
    if ($RAMs) {
        foreach ($R in $RAMs) {
            # Giải mã chuẩn RAM (SMBIOS MemoryType)
            $memType = "Khác"
            if ($R.SMBIOSMemoryType -eq 24) { $memType = "DDR3" }
            elseif ($R.SMBIOSMemoryType -eq 26) { $memType = "DDR4" }
            elseif ($R.SMBIOSMemoryType -eq 34) { $memType = "DDR5" }
            elseif ($R.MemoryType -eq 24) { $memType = "DDR3" }
            elseif ($R.MemoryType -eq 0) { $memType = "DDR4/DDR5" } # Win 10 cũ không nhận diện đc DDR4/5 qua WMI
            
            $cap = "$([Math]::Round($R.Capacity/1GB, 1)) GB"
            $spd = if ($R.Speed) { "$($R.Speed) MHz" } else { "N/A" }
            $part = if ($R.PartNumber) { $R.PartNumber.Trim() } else { "N/A" }
            $volt = if ($R.ConfiguredVoltage -gt 0) { "$([Math]::Round($R.ConfiguredVoltage/1000, 2)) V" } else { "N/A" }
            $manu = if ($R.Manufacturer) { $R.Manufacturer.Trim() } else { "Unknown" }
            
            $GridRam.Rows.Add($R.DeviceLocator, $manu, $cap, $spd, $memType, $part, $volt) | Out-Null
        }
    } else {
        $GridRam.Rows.Add("VM/Ảo hóa", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A") | Out-Null
    }
    
    $PRam.ShowDialog() | Out-Null
})

# --- HỆ THỐNG ---
$GrpSys = Make-Group $Form " THÔNG TIN HỆ THỐNG " @(630, 10, 620, 240) "Yellow"
Make-Label $GrpSys "Máy: $($env:COMPUTERNAME) | User: $($env:USERNAME)" 20 30 "White" $false 580 | Out-Null
Make-Label $GrpSys "GPU: $WmiGPU" 20 55 "Cyan" $false 580 | Out-Null
$LblUptime = Make-Label $GrpSys "Uptime: Đang lấy..." 20 90 "Pink" $false 580

$BtnOS = Make-Label $GrpSys "[ i ] Xem HĐH, BIOS, Key & Office" 20 130 "White" $true 580
$BtnGPU = Make-Label $GrpSys "[ 🖥️ ] Xem chi tiết GPU & Màn Hình" 20 160 "Cyan" $true 580
$BtnSensors = Make-Label $GrpSys "[ ⚡ ] Xem Cảm biến Nhiệt & Quạt (Live)" 20 190 "Yellow" $true 580
$BtnBattery = Make-Label $GrpSys "[ i ] Xem Trạng thái Pin & Nguồn" 20 220 "Lime" $true 580

$BtnOS.Add_Click({ 
    $I = "========== PHẦN MỀM & BẢN QUYỀN ==========`nTên OS        : $($WmiOS.Caption)`nPhiên bản     : $($WmiOS.Version) (Build $($WmiOS.BuildNumber))`nKiến trúc     : $($WmiOS.OSArchitecture)`nNgày cài đặt  : $($WmiOS.InstallDate.ToString('dd/MM/yyyy HH:mm:ss'))`nThư mục Boot  : $($WmiOS.BootDevice)`n`n"
    $I += "--- THÔNG TIN BIOS/UEFI ---`nNhà SX BIOS : $($WmiBIOS.Manufacturer)`nTên BIOS    : $($WmiBIOS.Name)`nPhiên bản   : $($WmiBIOS.SMBIOSBIOSVersion)`nSerial No.  : $($WmiBIOS.SerialNumber)`n`n"
    $I += "--- BẢN QUYỀN WINDOWS ---`nWin Product Key: $WinKey`nUUID Máy tính    : $($WmiCS.UUID)`n`n--- MICROSOFT OFFICE ---`nBản cài đặt   : $OfficeInfo`n"
    Show-PopUp "SYSTEM OS & BIOS MASTER" $I 
})

$BtnGPU.Add_Click({
    $Vid = Get-CimInstance Win32_VideoController | Select -First 1; $Mon = try { Get-CimInstance Win32_DesktopMonitor -ErrorAction Stop | Select -First 1 } catch { $null }
    $I = "========== ĐỒ HỌA (VGA / GPU) ==========`nTên GPU      : $($Vid.Name)`nVRAM (RAM)   : $([Math]::Round($Vid.AdapterRAM/1GB, 2)) GB`nDriver Name  : $($Vid.InstalledDisplayDrivers)`nDriver Ver   : $($Vid.DriverVersion)`n`n========== MÀN HÌNH (DISPLAY) ==========`nTên Màn Hình : $(if($Mon.Name -and $Mon.Name -notmatch 'Default'){ $Mon.Name } else { 'Generic PnP Monitor' })`nĐộ phân giải : $($Vid.CurrentHorizontalResolution) x $($Vid.CurrentVerticalResolution) Pixels`nTần số quét  : $($Vid.CurrentRefreshRate) Hz`nĐộ sâu màu   : $($Vid.CurrentBitsPerPixel) Bit Color`n"
    Show-PopUp "GPU & DISPLAY MASTER" $I
})
$BtnSensors.Add_Click({
    $UpdateScript = {
        $Str = "========== SENSORS CHUYÊN SÂU (LIVE) ==========`n"
        $hasData = $false
        foreach ($hw in $PC.Hardware) { $hw.Update(); $fans = $hw.Sensors | ? SensorType -eq 'Fan'; $powers = $hw.Sensors | ? SensorType -eq 'Power'; $temps = $hw.Sensors | ? SensorType -eq 'Temperature'
            if ($fans -or $powers -or $temps) { $hasData = $true; $Str += "`n--- [$($hw.HardwareType)] $($hw.Name) ---`n"
                if ($temps) { foreach ($t in $temps) { $Str += " Nhiệt độ : $($t.Name.PadRight(15)): $([Math]::Round($t.Value, 1)) °C`n" } }
                if ($fans) { foreach ($f in $fans) { $Str += " Tốc độ Quạt: $($f.Name.PadRight(15)): $([Math]::Round($f.Value, 0)) RPM`n" } }
                if ($powers) { foreach ($p in $powers) { $Str += " Điện tiêu thụ: $($p.Name.PadRight(15)): $([Math]::Round($p.Value, 2)) W`n" } }
            }
        }
        if (-not $hasData) { $Str += "`nKhông phát hiện cảm biến thật. (Đang chạy VM hoặc Mainboard khóa cổng đọc)" }; return $Str
    }; Show-PopUp "HARDWARE SENSORS LIVE" (&$UpdateScript) $true $UpdateScript
})
$BtnBattery.Add_Click({
    $Bat = Get-CimInstance Win32_Battery
    if ($Bat) { Show-PopUp "PIN & NGUỒN" "Tình trạng: $($Bat.EstimatedChargeRemaining)%`nStatus: $($Bat.BatteryStatus) (2=Cắm sạc, 1=Đang xả)" } else { Show-PopUp "POWER STATUS" "========== TRẠM NĂNG LƯỢNG ==========`nNguồn cấp   : Điện lưới AC trực tiếp (Bú điện EVN)`nPower Plan  : $(try{(Get-CimInstance -Ns root\cimv2\power -Cl Win32_PowerPlan -Filter 'IsActive=TRUE').ElementName}catch{'N/A'})`nTrạng thái  : Đang cắm nguồn trực tiếp 24/7. Không giới hạn hiệu năng." }
})

# --- DISK & PARTITION ---
$GrpDisk = Make-Group $Form " LƯU TRỮ (Bấm vào dòng để xem chi tiết) " @(10, 260, 600, 240) "White"
Make-Label $GrpDisk ">> Ổ CỨNG VẬT LÝ (Physical Disks):" 10 20 "Silver" | Out-Null
$GridPhy = New-Object System.Windows.Forms.DataGridView; $GridPhy.Location="10,40"; $GridPhy.Size="580,80"; $GridPhy.BackgroundColor=$C_Panel; $GridPhy.ForeColor="Black"; $GridPhy.AutoSizeColumnsMode="Fill"; $GridPhy.ReadOnly=$true; $GridPhy.SelectionMode="FullRowSelect"; $GridPhy.Columns.Add("D","Tên Ổ Vật Lý"); $GridPhy.Columns.Add("S","Size")|Out-Null; $GrpDisk.Controls.Add($GridPhy)
try { Get-CimInstance Win32_DiskDrive | % { $GridPhy.Rows.Add($_.Model, "$([Math]::Round($_.Size/1GB,0)) GB")|Out-Null } } catch {}

Make-Label $GrpDisk ">> PHÂN VÙNG (Logical Partitions):" 10 125 "Silver" | Out-Null
$GridPart = New-Object System.Windows.Forms.DataGridView; $GridPart.Location="10,145"; $GridPart.Size="580,85"; $GridPart.BackgroundColor=$C_Panel; $GridPart.ForeColor="Black"; $GridPart.AutoSizeColumnsMode="Fill"; $GridPart.ReadOnly=$true; $GridPart.SelectionMode="FullRowSelect"; $GridPart.Columns.Add("L","Ký tự"); $GridPart.Columns.Add("N","Nhãn"); $GridPart.Columns.Add("F","Trống/Tổng")|Out-Null; $GrpDisk.Controls.Add($GridPart)
try { Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | % { $Tot = [Math]::Round($_.Size/1GB,1); $Fre = [Math]::Round($_.FreeSpace/1GB,1); $GridPart.Rows.Add($_.DeviceID, $_.VolumeName, "$Fre / $Tot GB")|Out-Null } } catch {}

$GridPhy.Add_CellClick({
    $RowIdx = $this.CurrentCell.RowIndex; if ($RowIdx -lt 0) { return }; $DiskName = $this.Rows[$RowIdx].Cells[0].Value; $Info = "========== CHI TIẾT Ổ CỨNG VẬT LÝ ==========`nModel: $DiskName`n"
    try { 
        $WmiDisk = Get-WmiObject Win32_DiskDrive | ? Model -match [regex]::Escape($DiskName) | Select -First 1; $pStyle = "N/A"
        try { $pStyle = (Get-Disk -Number $WmiDisk.Index -ErrorAction Stop).PartitionStyle } catch {}
        if ($WmiDisk) { $Info += "Giao tiếp : $($WmiDisk.InterfaceType)`nBoot Format : $pStyle (GPT/MBR)`nPhân vùng : $($WmiDisk.Partitions)`nTình trạng: $($WmiDisk.Status)`n`n" } 
    } catch {}
    $Info += "--- DỮ LIỆU S.M.A.R.T (Sức khỏe thực) ---`n"
    try { $LHMDisk = $PC.Hardware | ? { $_.HardwareType -eq 'Storage' -and $_.Name -match [regex]::Escape($DiskName -replace " NVMe","") } | Select -First 1
        if ($LHMDisk) { $LHMDisk.Update(); foreach ($s in $LHMDisk.Sensors) { if ($s.SensorType -eq 'Temperature') { $Info += "Nhiệt độ ổ: $([Math]::Round($s.Value, 1)) °C`n" }; if ($s.SensorType -eq 'Load') { $Info += "Tuổi thọ còn lại: $([Math]::Round($s.Value, 1)) %`n" }; if ($s.SensorType -eq 'Data') { $Info += "$($s.Name.PadRight(18)): $([Math]::Round($s.Value, 1)) GB`n" } }
        } else { $Info += "Không hỗ trợ SMART / Máy ảo.`n" } } catch { $Info += "Lỗi tải SMART data.`n" }
    Show-PopUp "PHYSICAL DISK MASTER" $Info
})

$GridPart.Add_CellClick({
    $RowIdx = $this.CurrentCell.RowIndex; if ($RowIdx -lt 0) { return }; $DriveLtr = $this.Rows[$RowIdx].Cells[0].Value; $VolName = $this.Rows[$RowIdx].Cells[1].Value
    $WmiVol = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$DriveLtr'" | Select -First 1; $Tot = [Math]::Round($WmiVol.Size/1GB, 2); $Fre = [Math]::Round($WmiVol.FreeSpace/1GB, 2); $Usd = $Tot - $Fre; $Pct = if($Tot -gt 0){ [Math]::Round(($Usd/$Tot)*100, 1) }else{0}
    $Info = "========== PHÂN VÙNG $DriveLtr ($VolName) ==========`nĐịnh dạng (FS): $($WmiVol.FileSystem)`nDung lượng    : Đã dùng $Usd GB / Tổng $Tot GB ($Pct%)`nCòn trống     : $Fre GB`n`n--- BẢO MẬT & MÃ HÓA (BitLocker) ---`n"
    try { $BL = Get-BitLockerVolume -MountPoint $DriveLtr -ErrorAction Stop; $Info += "Trạng thái: $($BL.VolumeStatus) ($($BL.EncryptionPercentage)% Mã hóa)`n"; $Keys = $BL.KeyProtector | ? KeyProtectorType -Match 'RecoveryPassword'; if ($Keys) { $Info += "Recovery Key (48 số): $($Keys.RecoveryPassword -join ' | ')`n" } else { $Info += "Recovery Key: Chưa có Password số.`n" }
    } catch { $Info += "BitLocker: Phân vùng chưa mã hóa (FullyDecrypted) hoặc Windows Home không hỗ trợ.`n" }
    Show-PopUp "LOGICAL PARTITION DETAILS" $Info
})

# --- NETWORK ---
$GrpNet = Make-Group $Form " MẠNG (Nhấp đúp IP để Copy) " @(620, 260, 630, 240) "Cyan"
$LblNetInfo = Make-Label $GrpNet "IP Nội bộ: Đang tải..." 20 40 "White" $true 590
$LblPubIP = Make-Label $GrpNet "IP Public: (Bấm để tải)" 20 70 "Yellow" $true 590
$BtnNetView = New-Object System.Windows.Forms.Button; $BtnNetView.Text="🌐 QUẢN LÝ MẠNG SÂU"; $BtnNetView.Location="20,110"; $BtnNetView.Size="590,45"; $BtnNetView.BackColor="DarkRed"; $BtnNetView.ForeColor="White"; $GrpNet.Controls.Add($BtnNetView)
$BtnWifi = New-Object System.Windows.Forms.Button; $BtnWifi.Text="🔑 XEM MẬT KHẨU WI-FI"; $BtnWifi.Location="20,170"; $BtnWifi.Size="590,45"; $BtnWifi.BackColor="DarkBlue"; $BtnWifi.ForeColor="White"; $GrpNet.Controls.Add($BtnWifi)

$LblNetInfo.Add_DoubleClick({ Set-Clipboard ($LblNetInfo.Text -replace "IP Nội bộ: ",""); [MessageBox]::Show("Đã Copy IP Nội bộ!") })
$LblPubIP.Add_DoubleClick({ Set-Clipboard ($LblPubIP.Text -replace "IP Public: ",""); [MessageBox]::Show("Đã Copy IP Public!") })
$LblPubIP.Add_Click({ try { $LblPubIP.Text = "IP Public: " + (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing -TimeoutSec 3).Content } catch { $LblPubIP.Text = "IP Public: Lỗi" } })

$BtnNetView.Add_Click({ $Adp = Get-WmiObject Win32_NetworkAdapterConfiguration | ? IPEnabled | Select -First 1; Show-PopUp "NETWORK GOD" "Card Mạng: $($Adp.Description)`nMAC: $($Adp.MACAddress)`nDHCP: $($Adp.DHCPEnabled)`nIPv4: $($Adp.IPAddress[0])`nSubnet: $($Adp.IPSubnet[0])`nGateway: $($Adp.DefaultIPGateway[0])`nDNS: $($Adp.DNSServerSearchOrder -join ', ')" })
$BtnWifi.Add_Click({
    $Out = "========== DANH SÁCH MẬT KHẨU WI-FI ==========`n`n"
    $Profiles = (netsh wlan show profiles) | Select-String "All User Profile\s+:\s+(.+)$" | %{ $_.Matches.Groups[1].Value.Trim() }
    if ($Profiles) { foreach ($P in $Profiles) { $Key = (netsh wlan show profile name="$P" key=clear) | Select-String "Key Content\s+:\s+(.+)$" | %{ $_.Matches.Groups[1].Value.Trim() }; if (-not $Key) { $Key = "<Trống>" }; $Out += "SSID: $($P.PadRight(20)) | Pass: $Key`n" } } else { $Out += "Không có cấu hình Wi-Fi." }
    Show-PopUp "WI-FI REVEALER" $Out
})

# --- ROW 3: QUICK TOOLS & BENCHMARK & EXPORT ---
$GrpTools = Make-Group $Form " 🛠️ CÔNG CỤ " @(10, 510, 300, 280) "Pink"
$BtnReg = New-Object System.Windows.Forms.Button; $BtnReg.Text="Task Manager"; $BtnReg.Location="20,25"; $BtnReg.Size="125,35"; $BtnReg.BackColor=$C_Panel; $BtnReg.ForeColor="White"; $BtnReg.Add_Click({Start-Process "taskmgr.exe"}); $GrpTools.Controls.Add($BtnReg)
$BtnDev = New-Object System.Windows.Forms.Button; $BtnDev.Text="Device Manager"; $BtnDev.Location="155,25"; $BtnDev.Size="125,35"; $BtnDev.BackColor=$C_Panel; $BtnDev.ForeColor="White"; $BtnDev.Add_Click({Start-Process "devmgmt.msc"}); $GrpTools.Controls.Add($BtnDev)
$BtnDisk = New-Object System.Windows.Forms.Button; $BtnDisk.Text="Disk Manager"; $BtnDisk.Location="20,70"; $BtnDisk.Size="125,35"; $BtnDisk.BackColor=$C_Panel; $BtnDisk.ForeColor="White"; $BtnDisk.Add_Click({Start-Process "diskmgmt.msc"}); $GrpTools.Controls.Add($BtnDisk)

$BtnClean = New-Object System.Windows.Forms.Button; $BtnClean.Text="🧹 DỌN RÁC"; $BtnClean.Location="155,70"; $BtnClean.Size="125,35"; $BtnClean.BackColor="DarkGreen"; $BtnClean.ForeColor="White"
$BtnClean.Add_Click({ Remove-Item "$env:TEMP\*" -Recurse -Force -EA SilentlyContinue; ipconfig /flushdns | Out-Null; [MessageBox]::Show("Dọn xong Temp và Flush DNS!") })
$GrpTools.Controls.Add($BtnClean)

$BtnBench = New-Object System.Windows.Forms.Button; $BtnBench.Text="🔥 BENCHMARK"; $BtnBench.Location="20,115"; $BtnBench.Size="125,45"; $BtnBench.BackColor="Maroon"; $BtnBench.ForeColor="White"; $BtnBench.Font=$FontBold; $GrpTools.Controls.Add($BtnBench)
$BtnKill = New-Object System.Windows.Forms.Button; $BtnKill.Text="💀 DIỆT APP TREO"; $BtnKill.Location="155,115"; $BtnKill.Size="125,45"; $BtnKill.BackColor="Crimson"; $BtnKill.ForeColor="White"; $BtnKill.Font=$FontBold
$BtnKill.Add_Click({ $bad = Get-Process | ? { $_.Responding -eq $false -and $_.MainWindowHandle -ne 0 }; if ($bad) { $bad | Stop-Process -Force; [MessageBox]::Show("Đã diệt $($bad.Count) App cứng đầu!") } else { [MessageBox]::Show("Hệ thống mượt mà, không có App nào bị treo.") } })
$GrpTools.Controls.Add($BtnKill)

$BtnExport = New-Object System.Windows.Forms.Button; $BtnExport.Text="💾 XUẤT BÁO CÁO"; $BtnExport.Location="20,170"; $BtnExport.Size="260,50"; $BtnExport.BackColor="DarkOrange"; $BtnExport.ForeColor="Black"; $BtnExport.Font=$FontBold
$CtxExport = New-Object System.Windows.Forms.ContextMenuStrip; $BtnExport.ContextMenuStrip = $CtxExport; $BtnExport.Add_Click({ $BtnExport.ContextMenuStrip.Show($BtnExport, 0, $BtnExport.Height) })
$GrpTools.Controls.Add($BtnExport)

function Get-FullReportText {
    $Adp = Get-WmiObject Win32_NetworkAdapterConfiguration | ? IPEnabled | Select -First 1
    $R = "========================================================`n    PHAT TAN PC - BÁO CÁO HỆ THỐNG (FULL REPORT)`n    Ngày xuất: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')`n========================================================`n`n[HỆ ĐIỀU HÀNH & BẢN QUYỀN]`n- PC Name    : $($env:COMPUTERNAME)`n- OS         : $($WmiOS.Caption) (Build $($WmiOS.BuildNumber))`n- Product Key: $WinKey`n- Install    : $($WmiOS.InstallDate)`n`n[CẤU HÌNH PHẦN CỨNG]`n- CPU        : $($WmiCPU.Name) ($($WmiCPU.NumberOfCores) Core)`n- RAM Tổng   : $([Math]::Round($TotalRAM_MB/1024, 2)) GB`n- GPU        : $WmiGPU`n`n[MẠNG & IP]`n- Card Mạng  : $($Adp.Description)`n- IP Nội bộ  : $($Adp.IPAddress[0])`n- MAC Address: $($Adp.MACAddress)`n`n[Ổ CỨNG VẬT LÝ]`n"
    Get-WmiObject Win32_DiskDrive | % { $R += "- Ổ: $($_.Model) ($([Math]::Round($_.Size/1GB,0)) GB)`n" }
    $R += "`n[PHÂN VÙNG LOGIC]`n"
    Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" | % { $Tot = [Math]::Round($_.Size/1GB,2); $Fre = [Math]::Round($_.FreeSpace/1GB,2); $Usd = $Tot-$Fre; $R += "- Ổ [$($_.DeviceID)] $($_.VolumeName) | Dùng: $Usd GB / $Tot GB | FS: $($_.FileSystem)`n" }
    return $R
}

$Desktop = "$env:USERPROFILE\Desktop"
$CtxExport.Items.Add("1. File Text (.TXT)").Add_Click({ $P = "$Desktop\PhatTan_Report_$($env:COMPUTERNAME).txt"; Get-FullReportText | Out-File $P -Encoding UTF8; [MessageBox]::Show("Đã lưu TXT!"); Invoke-Item $P })
$CtxExport.Items.Add("2. Hình ảnh (.PNG)").Add_Click({ $P = "$Desktop\PhatTan_Screen_$($env:COMPUTERNAME).png"; $bmp = New-Object System.Drawing.Bitmap $Form.Width, $Form.Height; $Form.DrawToBitmap($bmp, (New-Object System.Drawing.Rectangle(0, 0, $Form.Width, $Form.Height))); $bmp.Save($P, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose(); [MessageBox]::Show("Đã lưu PNG!"); Invoke-Item $P })
$CtxExport.Items.Add("3. Excel (.CSV)").Add_Click({ $P = "$Desktop\PhatTan_Data_$($env:COMPUTERNAME).csv"; [PSCustomObject]@{ PC_Name=$env:COMPUTERNAME; OS=$WmiOS.Caption; Key=$WinKey; CPU=$WmiCPU.Name; RAM_GB=[Math]::Round($TotalRAM_MB/1024, 2); GPU=$WmiGPU } | Export-Csv -Path $P -NoTypeInformation -Encoding UTF8; [MessageBox]::Show("Đã lưu CSV!"); Invoke-Item $P })
$CtxExport.Items.Add("4. JSON Dữ liệu").Add_Click({ $P = "$Desktop\PhatTan_Data_$($env:COMPUTERNAME).json"; [PSCustomObject]@{ PC_Name=$env:COMPUTERNAME; OS=$WmiOS.Caption; Key=$WinKey; CPU=$WmiCPU.Name; RAM_GB=[Math]::Round($TotalRAM_MB/1024, 2); GPU=$WmiGPU } | ConvertTo-Json | Out-File $P -Encoding UTF8; [MessageBox]::Show("Đã lưu JSON!"); Invoke-Item $P })
$CtxExport.Items.Add("5. Web HTML").Add_Click({ $P = "$Desktop\PhatTan_Report_$($env:COMPUTERNAME).html"; $Text = (Get-FullReportText) -replace "`n", "<br>"; "<html><body style='font-family:Consolas; background:#111; color:#0f0; padding:20px'><h2>PC REPORT</h2><div>$Text</div></body></html>" | Out-File $P -Encoding UTF8; [MessageBox]::Show("Đã lưu HTML!"); Invoke-Item $P })
$CtxExport.Items.Add("6. PDF (Edge)").Add_Click({
    $HtmlPath = "$env:TEMP\temp_report.html"; $PdfPath = "$Desktop\PhatTan_Report_$($env:COMPUTERNAME).pdf"
    "<html><body style='font-family:Arial; padding:30px'><h2>PC SYSTEM REPORT</h2><div style='font-size:14px; line-height:1.6'>$((Get-FullReportText) -replace "`n", "<br>")</div></body></html>" | Out-File $HtmlPath -Encoding UTF8
    [MessageBox]::Show("Đang dùng Edge ngầm xuất PDF (Chờ 3 giây)...")
    Start-Process -FilePath "msedge.exe" -ArgumentList "--headless", "--disable-gpu", "--print-to-pdf=`"$PdfPath`"", "`"$HtmlPath`"" -Wait -WindowStyle Hidden
    if(Test-Path $PdfPath){ [MessageBox]::Show("Đã lưu PDF!"); Invoke-Item $PdfPath } else { [MessageBox]::Show("Lỗi Edge.") }
})

# BENCHMARK CLICK EVENT
$BtnBench.Add_Click({
    $PBench = New-Object System.Windows.Forms.Form; $PBench.Text="TITAN BENCHMARK MASTER"; $PBench.Size="650,450"; $PBench.StartPosition="CenterParent"; $PBench.BackColor=$C_Bg
    $RtbBench = New-Object System.Windows.Forms.RichTextBox; $RtbBench.Location="10,10"; $RtbBench.Size="610,300"; $RtbBench.BackColor="Black"; $RtbBench.ForeColor="Lime"; $RtbBench.Font=New-Object System.Drawing.Font("Consolas", 11); $RtbBench.ReadOnly=$true; $PBench.Controls.Add($RtbBench)
    
    $BtnWinSat = New-Object System.Windows.Forms.Button; $BtnWinSat.Text="1. Đọc điểm WinSAT (Windows)"; $BtnWinSat.Location="10,330"; $BtnWinSat.Size="280,60"; $BtnWinSat.BackColor="Teal"; $BtnWinSat.ForeColor="White"; $PBench.Controls.Add($BtnWinSat)
    $BtnCustom = New-Object System.Windows.Forms.Button; $BtnCustom.Text="2. Chạy C# Native Engine (Sâu)"; $BtnCustom.Location="340,330"; $BtnCustom.Size="280,60"; $BtnCustom.BackColor="Purple"; $BtnCustom.ForeColor="White"; $PBench.Controls.Add($BtnCustom)
    
    $BtnWinSat.Add_Click({
        $RtbBench.Text = "Đang truy xuất Win32_WinSAT...\n"
        try { $ws = Get-CimInstance Win32_WinSAT -ErrorAction Stop; $RtbBench.Text += "========== KẾT QUẢ WINSAT ==========\nĐiểm Tổng Hợp : $($ws.WinSPRLevel) / 9.9\nĐiểm CPU      : $($ws.CPUScore) / 9.9\nĐiểm RAM      : $($ws.MemoryScore) / 9.9\nĐiểm Đồ Họa 2D: $($ws.GraphicsScore) / 9.9\nĐiểm Đồ Họa 3D: $($ws.D3DScore) / 9.9\nĐiểm Ổ Cứng   : $($ws.DiskScore) / 9.9\n"
        } catch { $RtbBench.Text += "Không thể đọc điểm WinSAT. Máy có thể chưa được chạy đánh giá lần nào." }
    })
    
    $BtnCustom.Add_Click({
        $BtnCustom.Enabled = $false; $BtnWinSat.Enabled = $false
        $RtbBench.Text = "Đang nạp Titan C# Engine vào RAM...\n>> Test CPU (Thuật toán lượng giác đa luồng)...\n"; [System.Windows.Forms.Application]::DoEvents()
        try {
            $cpuScore = [TitanBench]::RunCpuMultiCore(); $cpuScale = [Math]::Round(($cpuScore / 3700), 1); if($cpuScale -gt 9.9) { $cpuScale = 9.9 } elseif($cpuScale -lt 1.0) { $cpuScale = 1.0 }
            $RtbBench.Text += "=> Tốc độ RAW: $cpuScore pts\n=> Điểm chuẩn C# CPU: $cpuScale / 9.9\n\n>> Test Ổ Cứng C: (Ghi luồng FileStream 500MB)...\n"; [System.Windows.Forms.Application]::DoEvents()
            
            $diskSpeed = [TitanBench]::RunDiskWrite("$env:TEMP\titan_bench.tmp"); $diskScale = [Math]::Round(3.0 + ($diskSpeed / 250), 1); if($diskScale -gt 9.9) { $diskScale = 9.9 } elseif($diskScale -lt 1.0) { $diskScale = 1.0 }
            $RtbBench.Text += "=> Tốc độ Ghi thực tế (Seq): $diskSpeed MB/s\n=> Điểm chuẩn C# Disk: $diskScale / 9.9\n\n"
            Remove-Item "$env:TEMP\titan_bench.tmp" -ErrorAction SilentlyContinue
            
            $avgScore = [Math]::Round((($cpuScale + $diskScale) / 2), 1)
            $isCapped = $false; $penaltyMsg = ""
            
            if ($TotalRAM_MB -lt 4000) { $penaltyMsg += "! CẢNH BÁO: RAM dưới 4GB (Nghẽn cổ chai).\n"; $isCapped = $true }
            if ($WmiGPU -match "Generic|HD Graphics|UHD|Intel|Basic") { $penaltyMsg += "! CẢNH BÁO: Đồ họa Onboard/Basic.\n"; $isCapped = $true }
            if ($isCapped -and $avgScore -gt 3.9) { $avgScore = 3.9; $penaltyMsg += "=> Bị hạ điểm xuống $avgScore do phần cứng không đạt chuẩn Gaming.\n" }

            $RtbBench.Text += ">> ĐÁNH GIÁ TỔNG QUAN ($avgScore / 9.9):`n"
            if ($penaltyMsg) { $RtbBench.Text += $penaltyMsg + "`n" }

            if ($avgScore -ge 7.0) { $RtbBench.Text += "- Hạng S (Quái vật): Cân mượt Game AAA, Render 4K, Đồ họa nặng." }
            elseif ($avgScore -ge 5.0) { $RtbBench.Text += "- Hạng A (Mạnh mẽ): Chơi tốt Genshin, LoL, Edit video mượt mà." }
            elseif ($avgScore -ge 4.0) { $RtbBench.Text += "- Hạng B (Tiêu chuẩn): Làm văn phòng, xem phim FHD, chơi LoL nhẹ nhàng." }
            else { $RtbBench.Text += "- Hạng C (Máy cỏ/Văn phòng): Lướt web, gõ Word, xem YouTube. Chơi game sẽ giật lag." }

        } catch { $RtbBench.Text += "Lỗi thực thi C# Engine. Không thể chạy Benchmark." }
        $BtnCustom.Enabled = $true; $BtnWinSat.Enabled = $true
    })
    $PBench.ShowDialog() | Out-Null
})

# --- LIVE PING ---
$GrpPing = Make-Group $Form " LIVE PING VÀ TRAFFIC (Siêu Mượt) " @(320, 510, 930, 280) "Lime"
$TxtPingLog = New-Object System.Windows.Forms.RichTextBox; $TxtPingLog.Location="20,30"; $TxtPingLog.Size="890,230"; $TxtPingLog.BackColor="Black"; $TxtPingLog.ForeColor="Cyan"; $TxtPingLog.Font=New-Object System.Drawing.Font("Consolas", 11); $TxtPingLog.ReadOnly=$true; $GrpPing.Controls.Add($TxtPingLog)

$Global:PingBuffer = @(">> Đang khởi tạo kết nối mạng...")
$Runspace = [runspacefactory]::CreateRunspace(); $Runspace.Open(); $Pipeline = $Runspace.CreatePipeline()
$Pipeline.Commands.AddScript({
    $pingSender = New-Object System.Net.NetworkInformation.Ping; $sent=0; $lost=0; $totalMs=0
    while ($true) {
        $sent++; $reply = try { $pingSender.Send("8.8.8.8", 1000) } catch { $null }; $time = (Get-Date).ToString("HH:mm:ss")
        if ($reply -and $reply.Status -eq 'Success') {
            $ms = $reply.RoundtripTime; $totalMs += $ms; $avg = [Math]::Round($totalMs/($sent-$lost), 0)
            [void]$host.Runspace.Events.GenerateEvent("NewPingData", $null, $null, "[$time] Reply từ 8.8.8.8: time=$ms ms | Sent: $sent | Lost: $lost | Avg: $avg ms")
        } else { $lost++; [void]$host.Runspace.Events.GenerateEvent("NewPingData", $null, $null, "[$time] REQUEST TIMEOUT! | Packet Lost!") }
        Start-Sleep -Milliseconds 800
    }
}) | Out-Null
$Pipeline.InvokeAsync()

Register-EngineEvent -SourceIdentifier "NewPingData" -Action {
    $Global:PingBuffer += $Event.MessageData
    if ($Global:PingBuffer.Count -gt 11) { $Global:PingBuffer = $Global:PingBuffer[-11..-1] }
} | Out-Null

# --- BỘ TIMER THẦN THÁNH BẰNG .NET NGUYÊN BẢN (KHÔNG DÙNG PS CMDLETS) ---
try { 
    $Global:CpuC = New-Object System.Diagnostics.PerformanceCounter("Processor Information", "% Processor Utility", "_Total")
    $Global:RamAvailC = New-Object System.Diagnostics.PerformanceCounter("Memory", "Available MBytes")
    $Global:UpTimeC = New-Object System.Diagnostics.PerformanceCounter("System", "System Up Time")
} catch {}

$Timer = New-Object System.Windows.Forms.Timer; $Timer.Interval = 1000
$Timer.Add_Tick({
    try {
        if ($Global:CpuC) { $cpuLd = [Math]::Round($Global:CpuC.NextValue(), 0); if ($cpuLd -gt 100) { $cpuLd = 100 }; $GaugeCpu.Tag = $cpuLd; $GaugeCpu.Invalidate() }
        if ($Global:RamAvailC) { $avMB = $Global:RamAvailC.NextValue(); $ramPct = [Math]::Round((($TotalRAM_MB - $avMB) / $TotalRAM_MB) * 100, 0); $GaugeRam.Tag = $ramPct; $GaugeRam.Invalidate(); $LblRamAvail.Text = "Trống: $([Math]::Round($avMB/1024, 2)) GB" }
        if ($Global:UpTimeC) { $ts = [TimeSpan]::FromSeconds($Global:UpTimeC.NextValue()); $LblUptime.Text = "Uptime: {0:D2}h {1:D2}m {2:D2}s" -f $ts.Hours, $ts.Minutes, $ts.Seconds }
    } catch {}

    if ($LblNetInfo.Text -match "Đang tải") {
        try { $Net = [Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | ? { $_.OperationalStatus -eq 'Up' -and $_.NetworkInterfaceType -ne 'Loopback' }; $Ip = ($Net.GetIPProperties().UnicastAddresses | ? { $_.Address.AddressFamily -eq 'InterNetwork' }).Address.IPAddressToString | Select -First 1; if ($Ip) { $LblNetInfo.Text = "IP Nội bộ: $Ip" } } catch { $LblNetInfo.Text = "IP Nội bộ: Offline" }
    }
    if ($TxtPingLog.IsHandleCreated) { $TxtPingLog.Text = ($Global:PingBuffer -join "`n") }
})
$Timer.Start()

$Form.Add_FormClosing({ $Pipeline.Stop(); $Runspace.Close(); $Runspace.Dispose() })
$Form.ShowDialog() | Out-Null
