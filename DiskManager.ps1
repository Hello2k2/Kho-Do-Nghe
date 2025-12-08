<#
    DISK MANAGER PRO - PHAT TAN PC (V21.0 - TITANIUM ETERNITY)
    Fix: Winsat missing on Win Lite (Added Internal Benchmark Engine)
    UI: RGB Neon Loop, Optimized Drawing
#>

# --- 0. ANTI-CRASH SYSTEM ---
$Global:ErrorLogPath = "$env:TEMP\DiskManager_Crash.log"
Trap {
    $Err = $_.Exception
    $Msg = "CRASH: $($Err.Message) | Line: $($_.InvocationInfo.ScriptLineNumber)"
    try { $Msg | Out-File $Global:ErrorLogPath -Append } catch {}
    if ($Err.Message -notmatch "Get-PhysicalDisk" -and $Err.Message -notmatch "EmptyList") {
        # Silent continue
    }
    Continue
}

# --- 1. ADMIN & SETUP ---
$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
if (!([Security.Principal.WindowsPrincipal]$Identity).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic
$ErrorActionPreference = "SilentlyContinue"

# --- THEME CONFIG (RGB MATRIX) ---
$Theme_Dark = @{
    Name        = "Dark Eternity (RGB)"
    BgForm      = [System.Drawing.Color]::FromArgb(18, 18, 22)
    BgPanel     = [System.Drawing.Color]::FromArgb(32, 32, 38)
    GridBg      = [System.Drawing.Color]::FromArgb(25, 25, 30)
    TextMain    = [System.Drawing.Color]::FromArgb(245, 245, 245)
    TextMuted   = [System.Drawing.Color]::Silver
    RGB1        = [System.Drawing.Color]::FromArgb(255, 0, 80)   # Neon Red
    RGB2        = [System.Drawing.Color]::FromArgb(0, 255, 255)  # Neon Cyan
    BtnBase     = [System.Drawing.Color]::FromArgb(50, 50, 60)
    BtnHigh     = [System.Drawing.Color]::FromArgb(70, 70, 90)
    Border      = [System.Drawing.Color]::FromArgb(80, 80, 100)
}

$Theme_Light = @{
    Name        = "Light Eternity"
    BgForm      = [System.Drawing.Color]::FromArgb(240, 240, 245)
    BgPanel     = [System.Drawing.Color]::FromArgb(255, 255, 255)
    GridBg      = [System.Drawing.Color]::FromArgb(245, 245, 250)
    TextMain    = [System.Drawing.Color]::Black
    TextMuted   = [System.Drawing.Color]::DimGray
    RGB1        = [System.Drawing.Color]::FromArgb(0, 120, 255)
    RGB2        = [System.Drawing.Color]::FromArgb(0, 200, 100)
    BtnBase     = [System.Drawing.Color]::FromArgb(220, 220, 230)
    BtnHigh     = [System.Drawing.Color]::FromArgb(240, 240, 255)
    Border      = [System.Drawing.Color]::Silver
}

$Global:CurrentTheme = $Theme_Dark
$Global:SelectedDisk = $null
$Global:SelectedPart = $null

# --- GUI INIT ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "TITANIUM DISK MANAGER V21.0 (ETERNITY EDITION)"
$Form.Size = New-Object System.Drawing.Size(1280, 850)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Fonts
$F_Logo = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$F_Head = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$F_Norm = New-Object System.Drawing.Font("Segoe UI", 9)
$F_Btn  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

# ==================== DRAWING ENGINE ====================

function Apply-Theme {
    $T = $Global:CurrentTheme
    $Form.BackColor = $T.BgForm
    $Form.ForeColor = $T.TextMain
    $LblLogo.ForeColor = $T.RGB2
    $LblSub.ForeColor = $T.TextMuted
    $LblTheme.ForeColor = $T.RGB1
    
    $Form.Controls | Where-Object { $_ -is [System.Windows.Forms.Panel] } | ForEach-Object { $_.Invalidate() }
    
    $GridD.BackgroundColor = $T.GridBg; $GridP.BackgroundColor = $T.GridBg
    $GridD.DefaultCellStyle.BackColor = $T.GridBg; $GridP.DefaultCellStyle.BackColor = $T.GridBg
    $GridD.DefaultCellStyle.ForeColor = $T.TextMain; $GridP.DefaultCellStyle.ForeColor = $T.TextMain
    $GridD.ColumnHeadersDefaultCellStyle.BackColor = $T.BgPanel; $GridD.ColumnHeadersDefaultCellStyle.ForeColor = $T.TextMain
    $GridP.ColumnHeadersDefaultCellStyle.BackColor = $T.BgPanel; $GridP.ColumnHeadersDefaultCellStyle.ForeColor = $T.TextMain
}

$PaintRGB = {
    param($s, $e)
    $T = $Global:CurrentTheme
    $R = $s.ClientRectangle
    $BrBg = New-Object System.Drawing.SolidBrush($T.BgPanel)
    $e.Graphics.FillRectangle($BrBg, $R)
    $PenRGB = New-Object System.Drawing.Drawing2D.LinearGradientBrush($R, $T.RGB1, $T.RGB2, 45)
    $Pen = New-Object System.Drawing.Pen($PenRGB, 2)
    $e.Graphics.DrawRectangle($Pen, 1, 1, $s.Width-2, $s.Height-2)
    $BrBg.Dispose(); $Pen.Dispose(); $PenRGB.Dispose()
}

function Add-CyberBtn ($Parent, $Txt, $Icon, $X, $Y, $W, $Tag, $ColorType="Normal") {
    $Btn = New-Object System.Windows.Forms.Label; $Btn.Text = "$Icon  $Txt"
    $Btn.Tag = @{ Act=$Tag; Hover=$false; Type=$ColorType }
    $Btn.Location = "$X, $Y"; $Btn.Size = "$W, 45"
    $Btn.Font = $F_Btn; $Btn.TextAlign = "MiddleCenter"; $Btn.Cursor = "Hand"
    $Btn.Add_MouseEnter({ $this.Tag.Hover=$true; $this.Invalidate() }); $Btn.Add_MouseLeave({ $this.Tag.Hover=$false; $this.Invalidate() })
    $Btn.Add_Click({ Run-Action $this.Tag.Act })
    $Btn.Add_Paint({
        param($s, $e)
        $T = $Global:CurrentTheme; $R = $s.ClientRectangle
        $C1 = $T.BtnBase; $C2 = $T.BtnHigh
        $Border = if($s.Tag.Hover){ $T.RGB2 } else { $T.Border }
        if ($s.Tag.Type -eq "Danger") { $C1=[System.Drawing.Color]::FromArgb(150,0,0); $C2=[System.Drawing.Color]::FromArgb(200,50,50); $Border=[System.Drawing.Color]::Red }
        if ($s.Tag.Type -eq "Primary") { $C1=[System.Drawing.Color]::FromArgb(0,100,180); $C2=[System.Drawing.Color]::FromArgb(50,150,220); $Border=$T.RGB2 }
        if($s.Tag.Hover){ $C1=[System.Windows.Forms.ControlPaint]::Light($C1); $C2=[System.Windows.Forms.ControlPaint]::Light($C2) }
        $Br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($R, $C1, $C2, 90)
        $e.Graphics.FillRectangle($Br, $R)
        $Pen = New-Object System.Drawing.Pen($Border, 2)
        $e.Graphics.DrawRectangle($Pen, 1, 1, $s.Width-2, $s.Height-2)
        $F_Brush = New-Object System.Drawing.SolidBrush($T.TextMain)
        $Sf = New-Object System.Drawing.StringFormat; $Sf.Alignment="Center"; $Sf.LineAlignment="Center"
        $RectF = New-Object System.Drawing.RectangleF([float]0, [float]0, [float]$s.Width, [float]$s.Height)
        $e.Graphics.DrawString($s.Text, $s.Font, $F_Brush, $RectF, $Sf)
        $Br.Dispose(); $Pen.Dispose(); $F_Brush.Dispose()
    })
    $Parent.Controls.Add($Btn)
}

function Toggle-Theme {
    if ($Global:CurrentTheme.Name -match "Dark") { $Global:CurrentTheme = $Theme_Light; $BtnTheme.Text = "☀️ LIGHT MODE" }
    else { $Global:CurrentTheme = $Theme_Dark; $BtnTheme.Text = "🌙 DARK MODE" }
    Apply-Theme
}

# ==================== LAYOUT ====================

# HEAD
$PnlHead = New-Object System.Windows.Forms.Panel; $PnlHead.Dock="Top"; $PnlHead.Height=70; $PnlHead.BackColor=[System.Drawing.Color]::Transparent
$Form.Controls.Add($PnlHead)
$LblLogo = New-Object System.Windows.Forms.Label; $LblLogo.Text="TITANIUM DISK MANAGER V21"; $LblLogo.Font=$F_Logo; $LblLogo.AutoSize=$true; $LblLogo.Location="20,10"
$PnlHead.Controls.Add($LblLogo)
$LblSub = New-Object System.Windows.Forms.Label; $LblSub.Text="Ultimate Rescue Tool (Internal Benchmark Engine)"; $LblSub.Font=$F_Norm; $LblSub.AutoSize=$true; $LblSub.Location="420,25"
$PnlHead.Controls.Add($LblSub)
$LblTheme = New-Object System.Windows.Forms.Label; $LblTheme.Font=$F_Norm; $LblTheme.AutoSize=$true; $LblTheme.Location="950,15"; $LblTheme.Text="GIAO DIỆN:"
$PnlHead.Controls.Add($LblTheme)
$BtnTheme = New-Object System.Windows.Forms.Button; $BtnTheme.Text="🌙 DARK MODE"; $BtnTheme.Location="950,35"; $BtnTheme.Size="200,30"; $BtnTheme.FlatStyle="Flat"
$BtnTheme.BackColor=[System.Drawing.Color]::FromArgb(80,80,90); $BtnTheme.ForeColor="White"; $BtnTheme.Add_Click({ Toggle-Theme })
$PnlHead.Controls.Add($BtnTheme)

# DISK LIST
$PnlDisk = New-Object System.Windows.Forms.Panel; $PnlDisk.Location="20,80"; $PnlDisk.Size="1225,200"; $PnlDisk.Add_Paint($PaintRGB)
$Form.Controls.Add($PnlDisk)
$Lbl1 = New-Object System.Windows.Forms.Label; $Lbl1.Text="1. DANH SÁCH Ổ CỨNG VẬT LÝ"; $Lbl1.Location="15,10"; $Lbl1.AutoSize=$true; $Lbl1.Font=$F_Head; $Lbl1.BackColor=[System.Drawing.Color]::Transparent; $Lbl1.ForeColor=[System.Drawing.Color]::Cyan; $PnlDisk.Controls.Add($Lbl1)

$GridD = New-Object System.Windows.Forms.DataGridView; $GridD.Location="15,40"; $GridD.Size="1195,145"; $GridD.BorderStyle="None"
$GridD.AllowUserToAddRows=$false; $GridD.RowHeadersVisible=$false; $GridD.SelectionMode="FullRowSelect"; $GridD.MultiSelect=$false; $GridD.ReadOnly=$true; $GridD.AutoSizeColumnsMode="Fill"
$GridD.Columns.Add("ID","Disk #"); $GridD.Columns[0].Width=50
$GridD.Columns.Add("Mod","Tên Model"); $GridD.Columns[1].FillWeight=150
$GridD.Columns.Add("Type","Loại"); $GridD.Columns[2].Width=80
$GridD.Columns.Add("Size","Dung Lượng"); $GridD.Columns[3].Width=90
$GridD.Columns.Add("Bus","Giao Tiếp"); $GridD.Columns[4].Width=80
$GridD.Columns.Add("Health","Sức Khỏe (S.M.A.R.T)"); $GridD.Columns[5].Width=150
$GridD.Columns.Add("Parts","Phân Vùng"); $GridD.Columns[6].Width=80
$GridD.Columns.Add("Speed","Tốc Độ (Check)"); $GridD.Columns[7].Width=100
$PnlDisk.Controls.Add($GridD)

# PARTITION LIST
$PnlPart = New-Object System.Windows.Forms.Panel; $PnlPart.Location="20,290"; $PnlPart.Size="1225,200"; $PnlPart.Add_Paint($PaintRGB)
$Form.Controls.Add($PnlPart)
$L2 = New-Object System.Windows.Forms.Label; $L2.Text="2. CHI TIẾT PHÂN VÙNG"; $L2.Location="15,10"; $L2.AutoSize=$true; $L2.Font=$F_Head; $L2.BackColor=[System.Drawing.Color]::Transparent; $L2.ForeColor=[System.Drawing.Color]::LimeGreen; $PnlPart.Controls.Add($L2)

$GridP = New-Object System.Windows.Forms.DataGridView; $GridP.Location="15,40"; $GridP.Size="1195,145"; $GridP.BorderStyle="None"
$GridP.AllowUserToAddRows=$false; $GridP.RowHeadersVisible=$false; $GridP.SelectionMode="FullRowSelect"; $GridP.MultiSelect=$false; $GridP.ReadOnly=$true; $GridP.AutoSizeColumnsMode="Fill"
$GridP.Columns.Add("Let","Ký Tự"); $GridP.Columns[0].Width=60
$GridP.Columns.Add("Lab","Nhãn (Label)"); $GridP.Columns[1].FillWeight=100
$GridP.Columns.Add("FS","Hệ Thống"); $GridP.Columns[2].Width=70
$GridP.Columns.Add("Tot","Tổng (GB)"); $GridP.Columns[3].Width=80
$GridP.Columns.Add("Used","Đã Dùng"); $GridP.Columns[4].Width=80
$GridP.Columns.Add("Free","Còn Trống"); $GridP.Columns[5].Width=80
$GridP.Columns.Add("PUse","%"); $GridP.Columns[6].Width=60
$GridP.Columns.Add("Type","Kiểu"); $GridP.Columns[7].Width=100
$GridP.Columns.Add("Stat","Trạng Thái"); $GridP.Columns[8].Width=80
$PnlPart.Controls.Add($GridP)

# ACTIONS
$TabControl = New-Object System.Windows.Forms.TabControl; $TabControl.Location="20,500"; $TabControl.Size="1225,300"; $TabControl.Font=$F_Head
$Form.Controls.Add($TabControl)
function Add-Page ($Title) { $p=New-Object System.Windows.Forms.TabPage; $p.Text="  $Title  "; $TabControl.Controls.Add($p); return $p }

# TAB 1
$Tab1 = Add-Page "🛠️ CƠ BẢN"
Add-CyberBtn $Tab1 "LÀM MỚI (REFRESH)" "♻️" 30 30 220 "Refresh" "Primary"
Add-CyberBtn $Tab1 "ĐỔI TÊN (LABEL)" "🏷️" 280 30 220 "Label"
Add-CyberBtn $Tab1 "ĐỔI KÝ TỰ (LETTER)" "🔠" 530 30 220 "Letter"
Add-CyberBtn $Tab1 "CHECK DISK (CHKDSK)" "🚑" 780 30 220 "ChkDsk"

Add-CyberBtn $Tab1 "FORMAT PHÂN VÙNG" "🧹" 30 100 220 "Format" "Danger"
Add-CyberBtn $Tab1 "XÓA PHÂN VÙNG" "❌" 280 100 220 "Delete" "Danger"
Add-CyberBtn $Tab1 "WIPE DATA (XÓA SẠCH)" "💀" 530 100 220 "Wipe" "Danger"
Add-CyberBtn $Tab1 "SET ACTIVE" "⚡" 780 100 220 "Active"

# TAB 2
$Tab2 = Add-Page "🚑 CỨU HỘ & CAO CẤP"
Add-CyberBtn $Tab2 "FIX BOOT (AUTO BCD)" "🛠️" 30 30 250 "FixBoot" "Rescue"
Add-CyberBtn $Tab2 "HIỆN Ổ ẨN / EFI (MOUNT)" "🔓" 310 30 250 "MountEFI" "Rescue"
Add-CyberBtn $Tab2 "GỠ WRITE PROTECT" "🖊️" 590 30 250 "RemoveRO" "Rescue"
Add-CyberBtn $Tab2 "CHUYỂN GPT (CLEAN)" "🔄" 870 30 250 "ConvertGPT" "Danger"

Add-CyberBtn $Tab2 "TEST BỀ MẶT (BAD SECTOR)" "🔍" 30 100 250 "Surface" "Monitor"
Add-CyberBtn $Tab2 "TÁI TẠO MBR" "🧱" 310 100 250 "RebuildMBR" "Rescue"

# TAB 3
$Tab3 = Add-Page "📊 GIÁM SÁT"
Add-CyberBtn $Tab3 "CHI TIẾT S.M.A.R.T" "📋" 30 30 250 "SmartDetail" "Monitor"
Add-CyberBtn $Tab3 "BENCHMARK TỐC ĐỘ" "🚀" 310 30 250 "Benchmark" "Monitor"
Add-CyberBtn $Tab3 "TỐI ƯU HÓA (TRIM/DEFRAG)" "✨" 590 30 250 "Optimize" "Monitor"
$LblInfo = New-Object System.Windows.Forms.Label; $LblInfo.Text="INFO: Chọn phân vùng để thực hiện thao tác."; $LblInfo.Location="30, 200"; $LblInfo.AutoSize=$true; $Tab3.Controls.Add($LblInfo)

# ==================== LOGIC CORE ====================

function Write-Log ($Msg) { $Log="$env:TEMP\dm_log.txt"; "[$(Get-Date -F 'HH:mm:ss')] $Msg" | Out-File $Log -Append }

function Load-Data {
    $GridD.Rows.Clear(); $GridP.Rows.Clear(); $Global:SelectedPart=$null
    $Form.Cursor = "WaitCursor"; $Form.Refresh()
    Write-Log "Load-Data Start"
    
    $UseWMI = $false
    
    # 1. TRY MODERN API FIRST
    try {
        $PhyDisks = @(Get-PhysicalDisk -ErrorAction Stop | Sort-Object DeviceId)
        if ($PhyDisks.Count -eq 0) { throw "EmptyList" }
        
        foreach ($D in $PhyDisks) {
            $GB = [Math]::Round($D.Size / 1GB, 1).ToString() + " GB"
            $Type = if ($D.PartitionStyle -eq "Uninitialized") { "RAW" } else { $D.PartitionStyle }
            $PartCount = (Get-Partition -DiskNumber $D.DeviceId -ErrorAction SilentlyContinue).Count
            $Health = $D.HealthStatus.ToString()
            $Speed = if ($D.MediaType -eq "HDD") { "HDD" } elseif ($D.MediaType -eq "SSD") { "SSD" } else { "Unknown" }
            
            $Row = $GridD.Rows.Add($D.DeviceId, $D.FriendlyName, $Type, $GB, $D.BusType, $Health, $PartCount, $Speed)
            $GridD.Rows[$Row].Tag = @{ ID=$D.DeviceId; Mode="Modern" }
            if ($Health -ne "Healthy") { $GridD.Rows[$Row].DefaultCellStyle.ForeColor = [System.Drawing.Color]::Red }
        }
        $Lbl1.Text = "1. DANH SÁCH Ổ CỨNG (Engine: Modern)"
    } catch {
        $UseWMI = $true
    }
    
    # 2. WMI FALLBACK (DEEP FILL)
    if ($UseWMI) {
        Write-Log "Switching to WMI Deep Scan..."
        $Lbl1.Text = "1. DANH SÁCH Ổ CỨNG (Engine: WMI Legacy)"
        try {
            $Disks = Get-WmiObject Win32_DiskDrive
            foreach ($D in $Disks) {
                $GB = [Math]::Round($D.Size / 1GB, 1).ToString() + " GB"
                $Type = if ($D.Partitions -gt 4) { "GPT (Est)" } else { "MBR/GPT" } 
                $Health = if ($D.Status -eq "OK") { "Good (WMI)" } else { "Bad: $($D.Status)" }
                $Speed = if ($D.Model -match "SSD") { "SSD?" } else { "HDD?" }
                
                $Row = $GridD.Rows.Add($D.Index, $D.Model, $Type, $GB, $D.InterfaceType, $Health, $D.Partitions, $Speed)
                $GridD.Rows[$Row].Tag = @{ ID=$D.Index; Mode="WMI" }
            }
        } catch { Write-Log "WMI Failed." }
    }
    
    if ($GridD.Rows.Count -gt 0) { $GridD.Rows[0].Selected = $true; Load-Partitions $GridD.Rows[0].Tag }
    $Form.Cursor = "Default"
}

function Load-Partitions ($Tag) {
    Write-Log "Load-Partitions for Disk $($Tag.ID)"
    $GridP.Rows.Clear(); $Global:SelectedDisk = $Tag; $Did = $Tag.ID
    
    $UseWMI = $false
    # 1. MODERN PARTITION SCAN
    try {
        $Parts = Get-Partition -DiskNumber $Did -ErrorAction Stop | Sort-Object PartitionNumber
        foreach ($P in $Parts) {
            $Vol = $P | Get-Volume -ErrorAction SilentlyContinue
            
            # --- SUPER FIX: DRIVE LETTER ---
            $Let = ""
            if ($P.DriveLetter -ne 0 -and $P.DriveLetter) { $Let = "$($P.DriveLetter):" }
            elseif ($Vol.DriveLetter -ne 0 -and $Vol.DriveLetter) { $Let = "$($Vol.DriveLetter):" }
            
            $Lab = if($Vol.FileSystemLabel){$Vol.FileSystemLabel}else{"[Hidden]"}
            $FS  = if($Vol.FileSystem){$Vol.FileSystem}else{$P.Type}
            $Total = [Math]::Round($P.Size / 1GB, 2)
            
            $Used="-"; $Free="-"; $PUse="-"
            if ($Vol) {
                $UsedVal = $Vol.Size - $Vol.SizeRemaining
                $Used = [Math]::Round($UsedVal / 1GB, 2)
                $Free = [Math]::Round($Vol.SizeRemaining / 1GB, 2)
                if ($Vol.Size -gt 0) { $PUse = ([Math]::Round(($UsedVal / $Vol.Size)*100)).ToString() + "%" }
            }
            
            $Row = $GridP.Rows.Add($Let, $Lab, $FS, "$Total GB", "$Used GB", "$Free GB", $PUse, $P.GptType, "OK")
            $GridP.Rows[$Row].Tag = @{ Did=$Did; PartID=$P.PartitionNumber; Let=$Let; Lab=$Lab }
        }
    } catch { $UseWMI = $true }
    
    # 2. WMI PARTITION FALLBACK (DEEP LETTER SCAN)
    if ($UseWMI) {
        try {
            $Query = "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='\\.\PHYSICALDRIVE$Did'} WHERE AssocClass=Win32_DiskDriveToDiskPartition"
            $Parts = @(Get-WmiObject -Query $Query | Sort-Object StartingOffset)
            $RealID = 1
            foreach ($P in $Parts) {
                $LogDisk = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($P.DeviceID)'} WHERE AssocClass=Win32_LogicalDiskToPartition"
                $Total = [Math]::Round($P.Size / 1GB, 2)
                
                $Let=""; $Lab="[Hidden]"; $FS="RAW"; $Used="-"; $Free="-"
                if ($LogDisk) {
                    $Let = $LogDisk.DeviceID # e.g. "C:"
                    $Lab = $LogDisk.VolumeName
                    $FS  = $LogDisk.FileSystem
                    $Used = [Math]::Round(($LogDisk.Size - $LogDisk.FreeSpace) / 1GB, 2)
                    $Free = [Math]::Round($LogDisk.FreeSpace / 1GB, 2)
                }
                
                $Row = $GridP.Rows.Add($Let, $Lab, $FS, "$Total GB", $Used, $Free, "-", $P.Type, "WMI OK")
                $GridP.Rows[$Row].Tag = @{ Did=$Did; PartID=$RealID; Let=$Let; Lab=$Lab }
                $RealID++
            }
        } catch {}
    }
}

$GridD.Add_CellClick({ if($GridD.SelectedRows.Count -gt 0){ Load-Partitions $GridD.SelectedRows[0].Tag } })
$GridP.Add_CellClick({ if($GridP.SelectedRows.Count -gt 0){ $Global:SelectedPart = $GridP.SelectedRows[0].Tag; $LblInfo.Text = "Đang chọn: Partition $($Global:SelectedPart.PartID) (Disk $($Global:SelectedPart.Did))" } })

# ==================== ACTIONS (INTERNAL BENCHMARK) ====================

function Run-DP ($Cmd) {
    $F = "$env:TEMP\dp_exec.txt"; [IO.File]::WriteAllText($F, $Cmd)
    Start-Process "diskpart" "/s `"$F`"" -Wait -NoNewWindow
}

function Custom-Benchmark ($Let) {
    $Form.Cursor = "WaitCursor"
    try {
        $Drv = $Let.Substring(0,1) + ":"
        $TestFile = "$Drv\speed_test.tmp"
        
        # 1. WRITE TEST (256MB)
        $Buffer = New-Object byte[] (64 * 1024) # 64KB Buffer
        $TotalSize = 256 * 1024 * 1024
        
        $Sw = [System.Diagnostics.Stopwatch]::StartNew()
        $Fs = [System.IO.File]::Create($TestFile, 4096, [System.IO.FileOptions]::WriteThrough)
        $Written = 0
        while ($Written -lt $TotalSize) {
            $Fs.Write($Buffer, 0, $Buffer.Length)
            $Written += $Buffer.Length
        }
        $Fs.Close()
        $Sw.Stop()
        $WriteSpeed = [Math]::Round(($TotalSize / 1MB) / $Sw.Elapsed.TotalSeconds, 2)
        
        # 2. READ TEST
        $Sw.Restart()
        $Fs = [System.IO.File]::OpenRead($TestFile)
        while ($Fs.Read($Buffer, 0, $Buffer.Length) -gt 0) {}
        $Fs.Close()
        $Sw.Stop()
        $ReadSpeed = [Math]::Round(($TotalSize / 1MB) / $Sw.Elapsed.TotalSeconds, 2)
        
        Remove-Item $TestFile -Force -ErrorAction SilentlyContinue
        
        $Form.Cursor = "Default"
        [System.Windows.Forms.MessageBox]::Show("BENCHMARK RESULT ($Drv):`n`nWRITE SPEED: $WriteSpeed MB/s`nREAD SPEED:  $ReadSpeed MB/s`n`n(Internal Engine - Safe for Win Lite)", "Kết quả")
        
    } catch {
        $Form.Cursor = "Default"
        [System.Windows.Forms.MessageBox]::Show("Lỗi Benchmark: $($_.Exception.Message)", "Error")
    }
}

function Run-Action ($Act) {
    if ($Act -eq "Refresh") { Load-Data; return }
    
    $D = $Global:SelectedDisk
    $P = $Global:SelectedPart
    
    # --- DISK LEVEL ---
    if ($Act -eq "ConvertGPT") {
        if (!$D) { return }
        if ([System.Windows.Forms.MessageBox]::Show("CONVERT DISK $($D.ID) SANG GPT?`nSẼ XÓA SẠCH DỮ LIỆU!", "WARNING", "YesNo", "Error") -eq "Yes") {
            Run-DP "sel disk $($D.ID)`nclean`nconvert gpt"; Load-Data
        }
        return
    }
    
    if ($Act -eq "RemoveRO") {
        if (!$D) { return }
        Run-DP "sel disk $($D.ID)`nattributes disk clear readonly`nonline disk"
        [System.Windows.Forms.MessageBox]::Show("Đã gỡ Read-Only cho Disk $($D.ID)", "Success")
        return
    }

    if ($Act -eq "SmartDetail") {
        if (!$D) { return }
        try {
            $Info = Get-PhysicalDisk -DeviceId $D.ID | Select *
            $Info | Out-GridView -Title "S.M.A.R.T Details - Disk $($D.ID)"
        } catch { [System.Windows.Forms.MessageBox]::Show("Không đọc được SMART.", "Info") }
        return
    }

    # --- PARTITION LEVEL ---
    if (!$P) { [System.Windows.Forms.MessageBox]::Show("Chọn phân vùng trước!", "Lỗi"); return }
    $Did = $P.Did; $TargetPartID = $P.PartID; $Let = $P.Let

    switch ($Act) {
        "Format" {
            $Lab = [Microsoft.VisualBasic.Interaction]::InputBox("Nhãn mới:", "Format", "NewVol")
            if ($Lab) { Run-DP "sel disk $Did`nsel part $TargetPartID`nformat fs=ntfs label=`"$Lab`" quick" }
        }
        "Wipe" {
            if ([System.Windows.Forms.MessageBox]::Show("WIPE DATA (XÓA TRẮNG)?", "DANGER", "YesNo", "Error") -eq "Yes") {
                if ($Let) { 
                    $Form.Cursor="WaitCursor"; Format-Volume -DriveLetter $Let.Trim(":") -FileSystem NTFS -Full -Force | Out-Null; $Form.Cursor="Default"
                    [System.Windows.Forms.MessageBox]::Show("Done!", "Info")
                } else { [System.Windows.Forms.MessageBox]::Show("Cần ký tự ổ đĩa (Letter).", "Info") }
            }
        }
        "Delete" {
            if ([System.Windows.Forms.MessageBox]::Show("Xóa phân vùng $PartID?", "Confirm", "YesNo", "Warning") -eq "Yes") {
                Run-DP "sel disk $Did`nsel part $TargetPartID`ndelete partition override"; Load-Data
            }
        }
        "Label" {
            $N=[Microsoft.VisualBasic.Interaction]::InputBox("Tên mới:", "Rename", $P.Lab)
            if ($N) { if($Let){ Set-Volume -DriveLetter $Let.Trim(":") -NewFileSystemLabel $N; Load-Data } }
        }
        "Letter" {
            $L=[Microsoft.VisualBasic.Interaction]::InputBox("Ký tự mới (A-Z):", "Change Letter", "")
            if ($L) { Run-DP "sel disk $Did`nsel part $TargetPartID`nassign letter=$L"; Load-Data }
        }
        "Active" { Run-DP "sel disk $Did`nsel part $TargetPartID`nactive" }
        "ChkDsk" { if($Let){ Start-Process "cmd" "/k chkdsk $Let /f /x" } }
        "Surface" { if($Let){ Start-Process "cmd" "/k chkdsk $Let /r" } else { [System.Windows.Forms.MessageBox]::Show("Cần ký tự ổ đĩa!", "Info") } }
        "FixBoot" { if($Let){ Start-Process "cmd" "/k bcdboot $Let\Windows /s $Let /f ALL" } else { [System.Windows.Forms.MessageBox]::Show("Chọn phân vùng Windows!", "Info") } }
        "MountEFI" {
            $Efi = Get-Partition -DiskNumber $Did | Where {$_.GptType -eq "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" -or $_.Type -eq "System"}
            if ($Efi) { Set-Partition -DiskNumber $Did -PartitionNumber $Efi.PartitionNumber -NewDriveLetter "Z"; Load-Data }
        }
        "Benchmark" { 
            if ($Let) {
                # --- AUTO SWITCH WINSAT OR INTERNAL ---
                if (Get-Command "winsat" -ErrorAction SilentlyContinue) {
                    Start-Process "cmd.exe" -ArgumentList "/k title DISK BENCHMARK ($Let) & winsat disk -drive $($Let.Substring(0,1)) -ran -read -count 1"
                } else {
                    Custom-Benchmark $Let
                }
            } else { [System.Windows.Forms.MessageBox]::Show("Cần ký tự ổ đĩa (VD: C:)!", "Lỗi") } 
        }
        "Optimize" { if($Let){ Optimize-Volume -DriveLetter $Let.Trim(":") -ReTrim -Verbose; [System.Windows.Forms.MessageBox]::Show("Done!") } else { [System.Windows.Forms.MessageBox]::Show("Cần ký tự ổ đĩa!", "Info") } }
    }
}

# --- INIT ---
Apply-Theme
$Timer = New-Object System.Windows.Forms.Timer; $Timer.Interval=500; $Timer.Add_Tick({$Timer.Stop(); Load-Data}); $Timer.Start()
[System.Windows.Forms.Application]::Run($Form)
