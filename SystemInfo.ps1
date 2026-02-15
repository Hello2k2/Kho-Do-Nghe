<#
    PHAT TAN PC - V22.0 TITAN COMPACT GOD (LAYOUT FIXED)
    Update:
    - LAYOUT: Thiết kế lại dạng Grid 2x2. Disk và Net nằm ngang nhau để giảm chiều cao Form.
    - SYSTEM GOD: Hiển thị sâu: BIOS Date, Serial, OS Build, Mainboard Ver.
    - POWER GOD: Hiển thị VCore, Clock Speed, Power Plan chi tiết.
    - CORE: Vẫn giữ RAM Failover, Diskpart Hybrid, Graphics Fix.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"

# --- THEME ---
$C_Bg     = [System.Drawing.Color]::FromArgb(10, 10, 15)
$C_Panel  = [System.Drawing.Color]::FromArgb(20, 20, 28)
$C_Cyan   = [System.Drawing.Color]::FromArgb(0, 255, 255)
$C_Pink   = [System.Drawing.Color]::FromArgb(255, 20, 147)
$C_Lime   = [System.Drawing.Color]::FromArgb(50, 205, 50)
$C_Yellow = [System.Drawing.Color]::FromArgb(255, 215, 0)
$C_Text   = [System.Drawing.Color]::WhiteSmoke
$FontBold = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$FontHead = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$FontMono = New-Object System.Drawing.Font("Consolas", 10)

# --- FORM (COMPACT SIZE) ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "PHAT TAN PC - TITAN V22.0 (COMPACT GOD)"
$Form.Size = New-Object System.Drawing.Size(1280, 850) # Thấp hơn bản cũ
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $C_Bg
$Form.ForeColor = $C_Text
$Form.MaximizeBox = $false
$Form.DoubleBuffered = $true 

# --- TABS ---
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = "10, 10"; $TabControl.Size = "1245, 790"
$TabControl.Font = $FontHead
$Form.Controls.Add($TabControl)

function Make-Tab ($Title) { 
    $P = New-Object System.Windows.Forms.TabPage; $P.Text = $Title
    $P.BackColor = $C_Bg; $P.ForeColor = $C_Text
    $TabControl.Controls.Add($P); return $P 
}
function Make-Group ($Parent, $Title, $Rect, $Color="Cyan") {
    $G = New-Object System.Windows.Forms.GroupBox; $G.Text = $Title
    $G.Location = "$($Rect[0]), $($Rect[1])"; $G.Size = "$($Rect[2]), $($Rect[3])"
    $G.ForeColor = [System.Drawing.Color]::FromName($Color); $G.Font = $FontBold
    $Parent.Controls.Add($G); return $G
}
function Make-Label ($Parent, $Text, $X, $Y, $C="White") {
    $L = New-Object System.Windows.Forms.Label; $L.Text=$Text; $L.AutoSize=$true; $L.Location="$X,$Y"
    $L.ForeColor=[System.Drawing.Color]::FromName($C); $Parent.Controls.Add($L); return $L
}

# ==============================================================================
# ENGINE GAUGE (V19.2 CORE)
# ==============================================================================
function Make-Gauge ($Parent, $X, $Y, $ColorPen) {
    $Pic = New-Object System.Windows.Forms.PictureBox
    $Pic.Location = "$X, $Y"; $Pic.Size = "150, 150"; $Pic.BackColor = "Transparent"; $Pic.Tag = 0 
    $Pic.Add_Paint({
        param($sender, $e)
        try {
            $g = $e.Graphics; $g.SmoothingMode = 4
            $Rect = New-Object System.Drawing.Rectangle(10, 10, 130, 130)
            $PenBack = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40,40,40), 15)
            $g.DrawArc($PenBack, $Rect, 135, 270); $PenBack.Dispose()
            $Val = 0; if ($sender.Tag -ne $null) { $Val = [int]$sender.Tag }
            if ($Val -gt 100) { $Val = 100 }
            if ($Val -gt 0) {
                $Angle = [Math]::Round(($Val / 100) * 270)
                $PenFore = New-Object System.Drawing.Pen($ColorPen, 15)
                $PenFore.StartCap = 2; $PenFore.EndCap = 2
                $g.DrawArc($PenFore, $Rect, 135, $Angle); $PenFore.Dispose()
            }
            $F = New-Object System.Drawing.Font("Impact", 24)
            $Brush = New-Object System.Drawing.SolidBrush($ColorPen)
            $Str = "$Val%"; $Sz = $g.MeasureString($Str, $F)
            $g.DrawString($Str, $F, $Brush, (75 - $Sz.Width/2), (75 - $Sz.Height/2))
            $Brush.Dispose(); $F.Dispose()
        } catch {}
    }.GetNewClosure()); $Parent.Controls.Add($Pic); return $Pic
}

# ==============================================================================
# TAB 1: DASHBOARD (COMPACT LAYOUT)
# ==============================================================================
$TabDash = Make-Tab "🚀 DASHBOARD"

# --- ROW 1: CPU | RAM | SYSTEM & POWER (3 Cột) ---

# 1. CPU
$GrpCpu = Make-Group $TabDash " CPU " @(10, 10, 300, 250) "Cyan"
$GaugeCpu = Make-Gauge $GrpCpu 75 30 $C_Cyan
$LblCpuName = Make-Label $GrpCpu "CPU..." 20 190 "White"
$LblUpTime  = Make-Label $GrpCpu "Uptime..." 20 215 "Orange"

# 2. RAM
$GrpRam = Make-Group $TabDash " RAM " @(320, 10, 300, 250) "Magenta"
$GaugeRam = Make-Gauge $GrpRam 75 30 $C_Pink
$LblRamTotal = Make-Label $GrpRam "Total..." 20 190 "White"
# Mini List RAM
$ListRam = New-Object System.Windows.Forms.ListBox; $ListRam.Location="20,215"; $ListRam.Size="260,30"; $ListRam.BackColor=$C_Panel; $ListRam.ForeColor="Lime"; $ListRam.BorderStyle="None"; $GrpRam.Controls.Add($ListRam)

# 3. SYSTEM & POWER GOD (GỘP CHUNG CHO GỌN)
$GrpSys = Make-Group $TabDash " HỆ THỐNG & NGUỒN (SYSTEM GOD) " @(630, 10, 600, 250) "Yellow"
$TxtSys = New-Object System.Windows.Forms.RichTextBox; $TxtSys.Location="15,30"; $TxtSys.Size="570,200"; $TxtSys.BackColor=$C_Panel; $TxtSys.ForeColor="White"; $TxtSys.Font=$FontMono; $TxtSys.ReadOnly=$true; $TxtSys.BorderStyle="None"
$GrpSys.Controls.Add($TxtSys)

# --- ROW 2: DISK | NETWORK (2 Cột Ngang) ---

# 4. DISK (LEFT SIDE - 60%)
$GrpDisk = Make-Group $TabDash " Ổ CỨNG (DISK MASTER) " @(10, 270, 750, 250) "White"
$GridPhy = New-Object System.Windows.Forms.DataGridView; $GridPhy.Location="15,30"; $GridPhy.Size="720,100"; $GridPhy.BackgroundColor=$C_Panel; $GridPhy.ForeColor="Black"; $GridPhy.RowHeadersVisible=$false; $GridPhy.AutoSizeColumnsMode="Fill"; $GridPhy.ReadOnly=$true
$GridPhy.Columns.Add("D","Ổ"); $GridPhy.Columns.Add("M","Model"); $GridPhy.Columns.Add("T","Loại"); $GridPhy.Columns.Add("S","Size"); $GridPhy.Columns.Add("C","Part"); $GridPhy.Columns.Add("L","Ký Tự")|Out-Null
$GrpDisk.Controls.Add($GridPhy)
$GridPart = New-Object System.Windows.Forms.DataGridView; $GridPart.Location="15,140"; $GridPart.Size="720,100"; $GridPart.BackgroundColor=$C_Panel; $GridPart.ForeColor="Black"; $GridPart.RowHeadersVisible=$false; $GridPart.AutoSizeColumnsMode="Fill"; $GridPart.ReadOnly=$true
$GridPart.Columns.Add("L","Ký Tự"); $GridPart.Columns.Add("Lb","Nhãn"); $GridPart.Columns.Add("F","Format"); $GridPart.Columns.Add("T","Tổng"); $GridPart.Columns.Add("Fr","Trống"); $GridPart.Columns.Add("U","% Used")|Out-Null
$GrpDisk.Controls.Add($GridPart)

# 5. NET (RIGHT SIDE - 40%)
$GrpNet = Make-Group $TabDash " MẠNG (NET) " @(770, 270, 460, 250) "Cyan"
$GridNet = New-Object System.Windows.Forms.DataGridView; $GridNet.Location="15,30"; $GridNet.Size="430,200"; $GridNet.BackgroundColor=$C_Panel; $GridNet.ForeColor="Black"; $GridNet.RowHeadersVisible=$false; $GridNet.AutoSizeColumnsMode="AllCells"; $GridNet.ReadOnly=$true
$GridNet.Columns.Add("N","Card"); $GridNet.Columns.Add("S","Speed"); $GridNet.Columns.Add("IP","IP/Gateway")|Out-Null
$GrpNet.Controls.Add($GridNet)

# --- ROW 3: TOOLS (FOOTER) ---
$GrpAct = Make-Group $TabDash " ĐIỀU KHIỂN " @(10, 530, 1220, 100) "White"
$BtnExport=New-Object System.Windows.Forms.Button; $BtnExport.Text="💾 LƯU BÁO CÁO"; $BtnExport.Location="30,30"; $BtnExport.Size="200,50"; $BtnExport.BackColor="MidnightBlue"; $BtnExport.ForeColor="White"; $GrpAct.Controls.Add($BtnExport)
$CtxExp=New-Object System.Windows.Forms.ContextMenuStrip; foreach($i in @("HTML","Excel","TXT")){$CtxExp.Items.Add($i).Name=$i}; $BtnExport.ContextMenuStrip=$CtxExp; $BtnExport.Add_Click({$BtnExport.ContextMenuStrip.Show($BtnExport,0,$BtnExport.Height)})
$BtnBuild=New-Object System.Windows.Forms.Button; $BtnBuild.Text="🛠 ĐÓNG GÓI"; $BtnBuild.Location="250,30"; $BtnBuild.Size="200,50"; $BtnBuild.BackColor="DarkGreen"; $BtnBuild.ForeColor="White"; $CtxBuild=New-Object System.Windows.Forms.ContextMenuStrip; $CtxBuild.Items.Add("EXE").Name="EXE"; $CtxBuild.Items.Add("VBS").Name="VBS"; $BtnBuild.ContextMenuStrip=$CtxBuild; $BtnBuild.Add_Click({$BtnBuild.ContextMenuStrip.Show($BtnBuild,0,$BtnBuild.Height)}); $GrpAct.Controls.Add($BtnBuild)
$BtnGod=New-Object System.Windows.Forms.Button; $BtnGod.Text="👑 GOD MODE"; $BtnGod.Location="470,30"; $BtnGod.Size="200,50"; $BtnGod.BackColor="Purple"; $BtnGod.ForeColor="White"; $BtnGod.Add_Click({New-Item -Path "$env:USERPROFILE\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}" -ItemType Directory -Force|Out-Null;[MessageBox]::Show("Done")}); $GrpAct.Controls.Add($BtnGod)
$BtnReload=New-Object System.Windows.Forms.Button; $BtnReload.Text="🔄 LÀM MỚI"; $BtnReload.Location="950,30"; $BtnReload.Size="200,50"; $BtnReload.BackColor="DarkOrange"; $BtnReload.ForeColor="Black"; $GrpAct.Controls.Add($BtnReload)

# ==============================================================================
# TAB 2: BENCHMARK
# ==============================================================================
$TabBench = Make-Tab "🔥 BENCHMARK"
$BtnRun = New-Object System.Windows.Forms.Button; $BtnRun.Text="💀 CHẠY TEST (1GB DISK + 300K CPU)"; $BtnRun.Location="350,30"; $BtnRun.Size="500,70"
$BtnRun.BackColor="Maroon"; $BtnRun.ForeColor="White"; $BtnRun.Font=$FontHead; $TabBench.Controls.Add($BtnRun)
$GrpRes = Make-Group $TabBench " KẾT QUẢ " @(50, 120, 1100, 550) "Gray"
$LblScore = Make-Label $GrpRes "Rank: ?" 50 50 "White" $true; $LblScore.Font=New-Object System.Drawing.Font("Impact",40)
$TxtLog = New-Object System.Windows.Forms.RichTextBox; $TxtLog.Location="50,150"; $TxtLog.Size="1000,380"; $TxtLog.BackColor="Black"; $TxtLog.ForeColor="Lime"; $GrpRes.Controls.Add($TxtLog)

# ==============================================================================
# LOGIC
# ==============================================================================
$Global:ExportData = @{CPU="";RAM="";Info=""}
try { $CpuC = New-Object System.Diagnostics.PerformanceCounter("Processor", "% Processor Time", "_Total"); $RamC = New-Object System.Diagnostics.PerformanceCounter("Memory", "% Committed Bytes In Use") } catch { $CpuC=$null }

$Timer = New-Object System.Windows.Forms.Timer; $Timer.Interval = 1000
$Timer.Add_Tick({
    try {
        $Up = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        $LblUpTime.Text = "Up: {0:D2}:{1:D2}:{2:D2}" -f $Up.Hours, $Up.Minutes, $Up.Seconds
        $ValCPU = if ($CpuC) { [Math]::Round($CpuC.NextValue()) } else { 0 }
        $GaugeCpu.Tag = $ValCPU; $GaugeCpu.Invalidate()
        $ValRAM = if ($RamC) { [Math]::Round($RamC.NextValue()) } else { 0 }
        $GaugeRam.Tag = $ValRAM; $GaugeRam.Invalidate()
    } catch {}
})

function Load-Static {
    # 1. CPU
    $C = Get-CimInstance Win32_Processor; $LblCpuName.Text = $C.Name
    $Global:ExportData.CPU = $C.Name
    
    # 2. SYSTEM GOD (CHI TIẾT HÓA)
    $OS = Get-CimInstance Win32_OperatingSystem
    $BIOS = Get-CimInstance Win32_BIOS
    $CS = Get-CimInstance Win32_ComputerSystem
    $InfoText = "=== HỆ ĐIỀU HÀNH & BIOS ===`n"
    $InfoText += "OS: $($OS.Caption) (Build: $($OS.Version))`n"
    $InfoText += "Install: $($OS.InstallDate.ToString('dd/MM/yyyy HH:mm:ss')) (Tuổi thọ: $((New-TimeSpan -Start $OS.InstallDate -End (Get-Date)).Days) ngày)`n"
    $InfoText += "BIOS: $($BIOS.Manufacturer) v$($BIOS.SMBIOSBIOSVersion) (Date: $($BIOS.ReleaseDate.ToString('dd/MM/yyyy')))`n"
    $InfoText += "Serial: $($BIOS.SerialNumber) | UUID: $($CS.UUID)`n"
    $InfoText += "Mainboard: $($CS.Manufacturer) - $($CS.Model)`n"
    $InfoText += "Boot Mode: $(if($env:firmware_type){$env:firmware_type}else{'Legacy'}) | Quyền: $(if(([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrator')){'ADMIN (Full)'}else{'USER'})`n`n"
    
    $InfoText += "=== NGUỒN ĐIỆN & CPU (POWER) ===`n"
    $Bat = Get-CimInstance Win32_Battery
    if ($Bat) {
        $InfoText += "NGUỒN: PIN LAPTOP ($($Bat.EstimatedChargeRemaining)%)$(if($Bat.BatteryStatus -eq 2){' [ĐANG SẠC]'}else{' [ĐANG XẢ]'})`n"
        $InfoText += "Voltage: $($Bat.DesignVoltage) mV | Time: $([Math]::Round($Bat.EstimatedRunTime/60,0)) min`n"
    } else {
        $InfoText += "NGUỒN: AC POWER (PC/Máy bàn)`n"
        try{ $P = Get-CimInstance -Ns root\cimv2\power -Cl Win32_PowerPlan -Filter "IsActive=TRUE"; $InfoText += "Plan: $($P.ElementName)`n" } catch {}
    }
    if ($C.CurrentVoltage -gt 0) { $InfoText += "CPU VCore: $([Math]::Round($C.CurrentVoltage/10, 2)) V | " }
    $InfoText += "Clock: $($C.MaxClockSpeed) MHz"
    
    $TxtSys.Text = $InfoText; $Global:ExportData.Info = $InfoText

    # 3. RAM (FAILOVER)
    $ListRam.Items.Clear(); $RAMs=@(); try{$RAMs=Get-CimInstance Win32_PhysicalMemory -EA Stop}catch{$RAMs=$null}
    if (-not $RAMs) { try{$RAMs=Get-WmiObject Win32_PhysicalMemory -EA Stop}catch{$RAMs=$null} }
    if ($RAMs) {
        $Tot=0; foreach($R in $RAMs){ $Cap=[Math]::Round($R.Capacity/1GB,0); $Tot+=$Cap; $ListRam.Items.Add("$($R.DeviceLocator): ${Cap}GB $($R.Speed)MHz")|Out-Null }
        $LblRamTotal.Text = "Tổng: $Tot GB"
    } else { $LblRamTotal.Text="Sys: $([Math]::Round($CS.TotalPhysicalMemory/1GB,1)) GB"; $ListRam.Items.Add("No Physical RAM info")|Out-Null }

    # 4. DISK & NET
    $GridPhy.Rows.Clear(); $GridPart.Rows.Clear(); $GridNet.Rows.Clear()
    try {
        $Disks = Get-Disk | Sort Number
        if($Disks){
            foreach($d in $Disks){
                $Ltrs = (Get-Partition -DiskNumber $d.Number | ? DriveLetter | Select -Exp DriveLetter) -join ", "; if(!$Ltrs){$Ltrs="-"}
                $GridPhy.Rows.Add("DISK $($d.Number)", $d.FriendlyName, $d.BusType, "$([Math]::Round($d.Size/1GB,0)) GB", (Get-Partition -DiskNumber $d.Number).Count, $Ltrs)|Out-Null
                Get-Partition -DiskNumber $d.Number | ? DriveLetter | % { $V=Get-Volume -DriveLetter $_.DriveLetter; $GridPart.Rows.Add("[$($_.DriveLetter):]", $V.FileSystemLabel, $V.FileSystem, "$([Math]::Round($V.Size/1GB,1)) GB", "$([Math]::Round($V.SizeRemaining/1GB,1)) GB", "$([Math]::Round(($V.Size-$V.SizeRemaining)/$V.Size*100))%")|Out-Null }
            }
        } else { throw "WMI" }
    } catch {
        Get-WmiObject Win32_DiskDrive | % { $GridPhy.Rows.Add("DISK $($_.Index)", $_.Model, $_.InterfaceType, "$([Math]::Round($_.Size/1GB,0)) GB", $_.Partitions, "WMI")|Out-Null }
        Get-WmiObject Win32_LogicalDisk | ? DriveType -eq 3 | % { $GridPart.Rows.Add("[$($_.DeviceID)]", $_.VolumeName, $_.FileSystem, "$([Math]::Round($_.Size/1GB,1)) GB", "$([Math]::Round($_.FreeSpace/1GB,1)) GB", "-")|Out-Null }
    }

    Get-WmiObject Win32_NetworkAdapterConfiguration | ? IPEnabled | % {
        $Adp = Get-WmiObject Win32_NetworkAdapter | ? InterfaceIndex -eq $_.InterfaceIndex | Select -First 1
        $Sp="N/A"; if($Adp.Speed){$Sp="$([Math]::Round($Adp.Speed/1000000)) Mbps"}
        $GridNet.Rows.Add($_.Description, $Sp, "$($_.IPAddress[0]) / $($_.DefaultIPGateway[0])")|Out-Null
    }
}

function Compile-Exe { param($P); $S=@"
using System.Diagnostics;class P{static void Main(){Process.Start(new ProcessStartInfo("powershell.exe","-WindowStyle Hidden -Exec Bypass -File \"$([IO.Path]::GetFileName($P))\""){WindowStyle=ProcessWindowStyle.Hidden});}}
"@; $Pr=New-Object Microsoft.CSharp.CSharpCodeProvider; $Pa=New-Object System.CodeDom.Compiler.CompilerParameters; $Pa.GenerateExecutable=$true; $Pa.OutputAssembly="$env:USERPROFILE\Desktop\LAUNCH.exe"; $Pa.CompilerOptions="/target:winexe"; $Pr.CompileAssemblyFromSource($Pa,$S); [MessageBox]::Show("Done!")}
$CtxBuild.Items["EXE"].Add_Click({Compile-Exe $MyInvocation.MyCommand.Path}); $CtxBuild.Items["VBS"].Add_Click({$F="$env:USERPROFILE\Desktop\LAUNCH.vbs";'CreateObject("WScript.Shell").Run "powershell -WindowStyle Hidden -Exec Bypass -File """ & WScript.Arguments(0) & """",0'|Out-File $F; [MessageBox]::Show("Done!")})

# --- BENCHMARK ---
$BtnRun.Add_Click({
    $BtnRun.Enabled=$false; $TxtLog.Clear(); $TxtLog.AppendText(">> BENCHMARK...`n"); [System.Windows.Forms.Application]::DoEvents()
    $Sw=[System.Diagnostics.Stopwatch]::StartNew(); $c=0; for($i=2;$i -le 300000;$i++){$p=$true;for($j=2;$j -le [Math]::Sqrt($i);$j++){if($i%$j -eq 0){$p=$false;break}};if($p){$c++}}; $Sw.Stop(); $Raw=[Math]::Round(30000000/$Sw.Elapsed.TotalMilliseconds,0); $TxtLog.AppendText("CPU: $Raw pts`n")
    $P="$env:TEMP\t.d"; $B=New-Object byte[] (1024*1MB); (new-object Random).NextBytes($B); $Sw.Restart(); [IO.File]::WriteAllBytes($P,$B); $Sw.Stop(); $W=[Math]::Round(1024/$Sw.Elapsed.TotalSeconds,1); $TxtLog.AppendText("Disk Write: $W MB/s`n"); Remove-Item $P -ErrorAction SilentlyContinue
    $Scale=[Math]::Round($Raw/2000,1); if($Scale -gt 10){$Scale=10}; $LblScore.Text="RANK $(if($Scale -ge 9){'S'}elseif($Scale -ge 7){'A'}elseif($Scale -ge 5){'B'}else{'C'})"; $BtnRun.Enabled=$true
})
$CtxExp.Items["HTML"].Add_Click({$P="$env:USERPROFILE\Desktop\R.html"; "<h1>PC REPORT</h1><pre>$($Global:ExportData.Info)</pre>"|Out-File $P; Invoke-Item $P})

$BtnReload.Add_Click({Load-Static}); Load-Static; $Timer.Start(); $Form.ShowDialog() | Out-Null
