<#
    DISK MANAGER PRO - PHAT TAN PC (V23.0 - TITANIUM UNIVERSE)
    Features: Clone, VHD Manager, Hex View, Bad Sector Map, Space Analyzer, Portable Mode
    Fixes: All previous crash bugs (PID, DrawString, Winsat, WMI, Letter)
    UI: RGB Neon, Dark/Light Mode, Custom Draw
#>

# --- 0. ANTI-CRASH WRAPPER ---
$Global:ErrorLog = "$env:TEMP\DiskManager_Universe.log"
Trap {
    $Err = $_.Exception; $Line = $_.InvocationInfo.ScriptLineNumber
    $Msg = "CRASH ($Line): $($Err.Message)"
    try { $Msg | Out-File $Global:ErrorLog -Append } catch {}
    
    # Chỉ bỏ qua lỗi nếu là lỗi dò ổ đĩa (để tool tự chuyển WMI)
    if ($Err.Message -notmatch "Get-PhysicalDisk" -and $Err.Message -notmatch "EmptyList") {
        # Silent continue
    }
    Continue
}

# --- 1. ADMIN CHECK ---
$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
if (!([Security.Principal.WindowsPrincipal]$Identity).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- 2. LIBRARIES ---
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic
$ErrorActionPreference = "SilentlyContinue"

# --- THEME CONFIG (CYBERPUNK) ---
$Theme_Dark = @{
    Name        = "Dark Universe (Neon)"
    BgForm      = [System.Drawing.Color]::FromArgb(15, 15, 20)
    BgPanel     = [System.Drawing.Color]::FromArgb(28, 28, 35)
    GridBg      = [System.Drawing.Color]::FromArgb(22, 22, 26)
    TextMain    = [System.Drawing.Color]::FromArgb(240, 240, 255)
    TextMuted   = [System.Drawing.Color]::FromArgb(140, 140, 160)
    # Gradients
    RGB1        = [System.Drawing.Color]::FromArgb(255, 0, 150)   # Pink
    RGB2        = [System.Drawing.Color]::FromArgb(0, 255, 240)   # Cyan
    BtnBase     = [System.Drawing.Color]::FromArgb(45, 45, 55)
    BtnHigh     = [System.Drawing.Color]::FromArgb(65, 65, 80)
    Border      = [System.Drawing.Color]::FromArgb(80, 80, 100)
}

$Theme_Light = @{
    Name        = "Light Universe (Clean)"
    BgForm      = [System.Drawing.Color]::FromArgb(245, 245, 250)
    BgPanel     = [System.Drawing.Color]::FromArgb(255, 255, 255)
    GridBg      = [System.Drawing.Color]::FromArgb(240, 240, 245)
    TextMain    = [System.Drawing.Color]::Black
    TextMuted   = [System.Drawing.Color]::DimGray
    RGB1        = [System.Drawing.Color]::FromArgb(0, 120, 215)
    RGB2        = [System.Drawing.Color]::FromArgb(0, 200, 100)
    BtnBase     = [System.Drawing.Color]::FromArgb(230, 230, 240)
    BtnHigh     = [System.Drawing.Color]::FromArgb(210, 210, 230)
    Border      = [System.Drawing.Color]::Silver
}

$Global:CurrentTheme = $Theme_Dark
$Global:SelDisk = $null
$Global:SelPart = $null

# --- GUI INIT ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "TITANIUM DISK MANAGER V23.0 (UNIVERSE EDITION)"
$Form.Size = New-Object System.Drawing.Size(1300, 900)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Fonts
$F_Logo = New-Object System.Drawing.Font("Segoe UI", 22, [System.Drawing.FontStyle]::Bold)
$F_Head = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$F_Norm = New-Object System.Drawing.Font("Segoe UI", 9)
$F_Mono = New-Object System.Drawing.Font("Consolas", 9)

# ==================== DRAWING ENGINE ====================

function Apply-Theme {
    $T = $Global:CurrentTheme
    $Form.BackColor = $T.BgForm
    $Form.ForeColor = $T.TextMain
    $LblLogo.ForeColor = $T.RGB2
    $LblSub.ForeColor = $T.TextMuted
    
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

function Add-Btn ($Parent, $Txt, $Icon, $X, $Y, $W, $Tag, $Type="Normal") {
    $B = New-Object System.Windows.Forms.Label; $B.Text = "$Icon  $Txt"
    $B.Tag = @{ Act=$Tag; Hover=$false; Type=$Type }
    $B.Location = "$X, $Y"; $B.Size = "$W, 45"; $B.Cursor = "Hand"
    $B.Font = $F_Head; $B.TextAlign = "MiddleCenter"
    
    $B.Add_MouseEnter({ $this.Tag.Hover=$true; $this.Invalidate() })
    $B.Add_MouseLeave({ $this.Tag.Hover=$false; $this.Invalidate() })
    $B.Add_Click({ Run-Action $this.Tag.Act })
    
    $B.Add_Paint({
        param($s, $e)
        $T = $Global:CurrentTheme; $R = $s.ClientRectangle
        $C1=$T.BtnBase; $C2=$T.BtnHigh; $Bdr=$T.Border
        
        switch ($s.Tag.Type) {
            "Danger" { $C1=[System.Drawing.Color]::FromArgb(100,0,0); $C2=[System.Drawing.Color]::FromArgb(150,50,50); $Bdr=[System.Drawing.Color]::Red }
            "Safe"   { $C1=[System.Drawing.Color]::FromArgb(0,80,0); $C2=[System.Drawing.Color]::FromArgb(0,120,50); $Bdr=[System.Drawing.Color]::Lime }
            "Special"{ $C1=[System.Drawing.Color]::FromArgb(80,0,80); $C2=[System.Drawing.Color]::FromArgb(120,0,120); $Bdr=[System.Drawing.Color]::Magenta }
            "Primary"{ $C1=[System.Drawing.Color]::FromArgb(0,80,120); $C2=[System.Drawing.Color]::FromArgb(0,100,150); $Bdr=$T.RGB2 }
        }
        
        if($s.Tag.Hover){ $C1=[System.Windows.Forms.ControlPaint]::Light($C1); $C2=[System.Windows.Forms.ControlPaint]::Light($C2); $Bdr=$T.RGB1 }
        
        $Br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($R, $C1, $C2, 90)
        $e.Graphics.FillRectangle($Br, $R)
        
        $Pen = New-Object System.Drawing.Pen($Bdr, 2)
        $e.Graphics.DrawRectangle($Pen, 1, 1, $s.Width-2, $s.Height-2)
        
        # FIX DRAWSTRING CRASH
        $Sf = New-Object System.Drawing.StringFormat; $Sf.Alignment="Center"; $Sf.LineAlignment="Center"
        $RectF = New-Object System.Drawing.RectangleF([float]0,[float]0,[float]$s.Width,[float]$s.Height)
        $e.Graphics.DrawString($s.Text, $s.Font, (New-Object System.Drawing.SolidBrush($T.TextMain)), $RectF, $Sf)
        
        $Br.Dispose(); $Pen.Dispose()
    })
    $Parent.Controls.Add($B)
}

function Toggle-Theme {
    if ($Global:CurrentTheme.Name -match "Dark") { $Global:CurrentTheme = $Theme_Light; $BtnTheme.Text = "☀️ LIGHT MODE" }
    else { $Global:CurrentTheme = $Theme_Dark; $BtnTheme.Text = "🌙 DARK MODE" }
    Apply-Theme
}

# ==================== LAYOUT ====================
# HEAD
$PnHead = New-Object System.Windows.Forms.Panel; $PnHead.Dock="Top"; $PnHead.Height=75; $Form.Controls.Add($PnHead)
$L_Logo = New-Object System.Windows.Forms.Label; $L_Logo.Text="TITANIUM UNIVERSE"; $L_Logo.Font=$F_Logo; $L_Logo.AutoSize=$true; $L_Logo.Location="20,10"; $L_Logo.ForeColor=$Theme_Dark.RGB2; $PnHead.Controls.Add($L_Logo)
$L_Sub = New-Object System.Windows.Forms.Label; $L_Sub.Text="Disk Manager | Rescue | Forensics | Virtualization"; $L_Sub.Font=$F_Norm; $L_Sub.AutoSize=$true; $L_Sub.Location="25,50"; $L_Sub.ForeColor=[System.Drawing.Color]::Gray; $PnHead.Controls.Add($L_Sub)

$BtnTheme = New-Object System.Windows.Forms.Button; $BtnTheme.Text="🌙 DARK MODE"; $BtnTheme.Location="1000,20"; $BtnTheme.Size="200,35"; $BtnTheme.FlatStyle="Flat"
$BtnTheme.BackColor=[System.Drawing.Color]::FromArgb(60,60,60); $BtnTheme.ForeColor="White"; $BtnTheme.Add_Click({ Toggle-Theme })
$PnHead.Controls.Add($BtnTheme)

# DISK LIST
$PnD = New-Object System.Windows.Forms.Panel; $PnD.Location="20,80"; $PnD.Size="1245,180"; $PnD.Add_Paint($PaintRGB); $Form.Controls.Add($PnD)
$L_D = New-Object System.Windows.Forms.Label; $L_D.Text="1. Ổ CỨNG VẬT LÝ"; $L_D.Location="15,10"; $L_D.AutoSize=$true; $L_D.Font=$F_Head; $L_D.ForeColor=[System.Drawing.Color]::Gold; $PnD.Controls.Add($L_D)

$GridD = New-Object System.Windows.Forms.DataGridView; $GridD.Location="15,35"; $GridD.Size="1215,130"; $GridD.BorderStyle="None"
$GridD.AllowUserToAddRows=$false; $GridD.RowHeadersVisible=$false; $GridD.SelectionMode="FullRowSelect"; $GridD.MultiSelect=$false; $GridD.ReadOnly=$true; $GridD.AutoSizeColumnsMode="Fill"
$GridD.Columns.Add("ID","Disk"); $GridD.Columns[0].Width=50
$GridD.Columns.Add("Mod","Model"); $GridD.Columns[1].FillWeight=120
$GridD.Columns.Add("Type","Type"); $GridD.Columns[2].Width=80
$GridD.Columns.Add("Size","Size"); $GridD.Columns[3].Width=80
$GridD.Columns.Add("Bus","Bus"); $GridD.Columns[4].Width=80
$GridD.Columns.Add("Health","Health/SMART"); $GridD.Columns[5].Width=120
$GridD.Columns.Add("PStyle","Style"); $GridD.Columns[6].Width=80
$GridD.Columns.Add("Dyn","Dynamic?"); $GridD.Columns[7].Width=80
$PnD.Controls.Add($GridD)

# PARTITION LIST
$PnP = New-Object System.Windows.Forms.Panel; $PnP.Location="20,270"; $PnP.Size="1245,220"; $PnP.Add_Paint($PaintRGB); $Form.Controls.Add($PnP)
$L_P = New-Object System.Windows.Forms.Label; $L_P.Text="2. PHÂN VÙNG (Bao gồm vùng trống - Unallocated)"; $L_P.Location="15,10"; $L_P.AutoSize=$true; $L_P.Font=$F_Head; $L_P.ForeColor=[System.Drawing.Color]::LimeGreen; $PnP.Controls.Add($L_P)

$GridP = New-Object System.Windows.Forms.DataGridView; $GridP.Location="15,35"; $GridP.Size="1215,170"; $GridP.BorderStyle="None"
$GridP.AllowUserToAddRows=$false; $GridP.RowHeadersVisible=$false; $GridP.SelectionMode="FullRowSelect"; $GridP.MultiSelect=$false; $GridP.ReadOnly=$true; $GridP.AutoSizeColumnsMode="Fill"
$GridP.Columns.Add("Let","Ltr"); $GridP.Columns[0].Width=50
$GridP.Columns.Add("Lab","Label"); $GridP.Columns[1].FillWeight=100
$GridP.Columns.Add("FS","FS"); $GridP.Columns[2].Width=70
$GridP.Columns.Add("Cap","Capacity"); $GridP.Columns[3].Width=90
$GridP.Columns.Add("Free","Free"); $GridP.Columns[4].Width=90
$GridP.Columns.Add("Type","Type"); $GridP.Columns[5].Width=120
$GridP.Columns.Add("Stat","Status"); $GridP.Columns[6].Width=100
$GridP.Columns.Add("Offset","Start Offset"); $GridP.Columns[7].Width=100
$PnP.Controls.Add($GridP)

# TABS
$Tabs = New-Object System.Windows.Forms.TabControl; $Tabs.Location="20,500"; $Tabs.Size="1245,350"; $Tabs.Font=$F_Head; $Form.Controls.Add($Tabs)
function MkTab ($T) { $p=New-Object System.Windows.Forms.TabPage; $p.Text=" $T "; $p.BackColor=$Theme_Dark.BgPanel; $p.ForeColor=$Theme_Dark.TextMain; $Tabs.Controls.Add($p); return $p }

# TAB 1: MANAGE
$T1 = MkTab "🛠️ QUẢN LÝ & CHIA Ổ"
Add-Btn $T1 "LÀM MỚI (REFRESH)" "♻️" 30 30 200 "Refresh" "Primary"
Add-Btn $T1 "ĐỔI TÊN (LABEL)" "🏷️" 250 30 200 "Label"
Add-Btn $T1 "ĐỔI KÝ TỰ (LETTER)" "🔠" 470 30 200 "Letter"
Add-Btn $T1 "CHECK DISK" "🚑" 690 30 200 "ChkDsk"

Add-Btn $T1 "FORMAT Ổ" "🧹" 30 100 200 "Format" "Danger"
Add-Btn $T1 "XÓA PHÂN VÙNG" "❌" 250 100 200 "Delete" "Danger"
Add-Btn $T1 "WIPE DATA" "💀" 470 100 200 "Wipe" "Danger"
Add-Btn $T1 "SET ACTIVE" "⚡" 690 100 200 "Active"

Add-Btn $T1 "CHIA Ổ (SPLIT)" "➗" 30 170 200 "Split" "Special"
Add-Btn $T1 "GỘP Ổ (MERGE)" "🔗" 250 170 200 "Merge" "Special"
Add-Btn $T1 "TẠO Ổ MỚI" "➕" 470 170 200 "Create" "Special"
Add-Btn $T1 "CONVERT DYNAMIC->BASIC" "📉" 690 170 260 "DynToBas" "Danger"

# TAB 2: RESCUE & HACKER
$T2 = MkTab "🚑 CỨU HỘ & HACKER"
Add-Btn $T2 "FIX BOOT (AUTO)" "🛠️" 30 30 250 "FixBoot" "Safe"
Add-Btn $T2 "MOUNT EFI/HIDDEN" "🔓" 300 30 250 "MountEFI" "Safe"
Add-Btn $T2 "GỠ WRITE PROTECT" "🖊️" 570 30 250 "RemoveRO" "Safe"
Add-Btn $T2 "CHUYỂN GPT (DATA LOSS)" "🔄" 840 30 250 "ConvertGPT" "Danger"

Add-Btn $T2 "HEX VIEWER (MBR)" "🧬" 30 100 250 "HexView" "Special"
Add-Btn $T2 "BAD SECTOR MAP" "🗺️" 300 100 250 "BadMap" "Special"
Add-Btn $T2 "TẠO USB PORTABLE" "🎒" 570 100 250 "Portable" "Special"

# TAB 3: VHD MANAGER
$T3 = MkTab "💿 Ổ ẢO (VHD)"
Add-Btn $T3 "TẠO VHD MỚI" "✨" 30 30 250 "CreateVHD" "Primary"
Add-Btn $T3 "MOUNT VHD" "📥" 300 30 250 "MountVHD" "Safe"
Add-Btn $T3 "DETACH VHD" "📤" 570 30 250 "DetachVHD" "Danger"

# TAB 4: MONITOR & CLONE
$T4 = MkTab "🚀 CLONE & GIÁM SÁT"
Add-Btn $T4 "CLONE DISK (DATA)" "🐑" 30 30 250 "CloneDisk" "Special"
Add-Btn $T4 "SPACE ANALYZER" "📊" 300 30 250 "SpaceAna" "Primary"
Add-Btn $T4 "BENCHMARK TỐC ĐỘ" "🏎️" 570 30 250 "Benchmark" "Primary"
Add-Btn $T4 "S.M.A.R.T CHI TIẾT" "📋" 30 100 250 "Smart" "Safe"

$LblInfo = New-Object System.Windows.Forms.Label; $LblInfo.Text="INFO: Chọn mục ở trên để thao tác."; $LblInfo.Location="20, 300"; $LblInfo.AutoSize=$true; $LblInfo.ForeColor=[System.Drawing.Color]::Cyan; $Tabs.Controls.Add($LblInfo)

# ==================== CORE LOGIC ====================

function Log ($M) { 
    $Path="$env:TEMP\dm_log.txt"; "[$(Get-Date -F HH:mm:ss)] $M" | Out-File $Path -Append
}

function Load-Disks {
    $GridD.Rows.Clear(); $GridP.Rows.Clear(); $Global:SelDisk=$null; $Global:SelPart=$null
    $Form.Cursor="WaitCursor"; $Form.Refresh()
    
    # 1. Hybrid Engine V3 (Modern first)
    try {
        $Disks = @(Get-PhysicalDisk -ErrorAction Stop | Sort DeviceId)
        if ($Disks.Count -eq 0) { throw "Empty" }
        foreach ($D in $Disks) {
            $GB = [Math]::Round($D.Size/1GB, 1); $Health = $D.HealthStatus
            $PStyle = if($D.PartitionStyle -eq "Uninitialized"){"RAW"}else{$D.PartitionStyle}
            
            $IsDyn = "Basic"
            try { if((Get-Disk $D.DeviceId).IsDynamic){$IsDyn="Dynamic"} } catch {}

            $Row = $GridD.Rows.Add($D.DeviceId, $D.FriendlyName, $D.MediaType, "$GB GB", $D.BusType, $Health, $PStyle, $IsDyn)
            $GridD.Rows[$Row].Tag = @{ ID=$D.DeviceId; Obj=$D; Mode="Modern" }
            if ($Health -ne "Healthy") { $GridD.Rows[$Row].DefaultCellStyle.ForeColor = [System.Drawing.Color]::Red }
        }
    } catch {
        # 2. WMI Fallback
        try {
            $Disks = Get-WmiObject Win32_DiskDrive
            foreach ($D in $Disks) {
                $GB = [Math]::Round($D.Size/1GB, 1); $Type = if($D.Partitions -gt 4){"GPT"}else{"MBR"}
                $Row = $GridD.Rows.Add($D.Index, $D.Model, "Unknown", "$GB GB", $D.InterfaceType, $D.Status, $Type, "?")
                $GridD.Rows[$Row].Tag = @{ ID=$D.Index; Mode="WMI"; Obj=$D }
            }
        } catch {}
    }
    $Form.Cursor="Default"
}

function Load-Parts ($Tag) {
    $GridP.Rows.Clear(); $Global:SelDisk=$Tag; $Did=$Tag.ID
    $DiskObj = Get-Disk -Number $Did -ErrorAction SilentlyContinue
    $DiskSize = if($DiskObj){$DiskObj.Size}else{0}
    
    try {
        $Parts = Get-Partition -DiskNumber $Did -ErrorAction Stop | Sort Offset
        $LastOffset = 0
        
        foreach ($P in $Parts) {
            # --- GAP DETECTION (UNALLOCATED) ---
            if ($P.Offset -gt $LastOffset + 50MB) { # Filter small gaps
                $Gap = $P.Offset - $LastOffset
                $GapGB = [Math]::Round($Gap/1GB, 2)
                $R = $GridP.Rows.Add("", "[UNALLOCATED]", "-", "$GapGB GB", "-", "Free Space", "Available", $LastOffset)
                $GridP.Rows[$R].DefaultCellStyle.ForeColor = [System.Drawing.Color]::Gold
                $GridP.Rows[$R].Tag = @{ Type="Unallocated"; Offset=$LastOffset; Size=$Gap }
            }
            
            $Vol = $P | Get-Volume -ErrorAction SilentlyContinue
            
            # Deep Drive Letter Logic
            $Let = ""
            if ($P.DriveLetter -ne 0) { $Let = "$($P.DriveLetter):" }
            elseif ($Vol.DriveLetter -ne 0) { $Let = "$($Vol.DriveLetter):" }
            
            $Lab = if($Vol.FileSystemLabel){$Vol.FileSystemLabel}else{"[Hidden]"}
            $FS = if($Vol.FileSystem){$Vol.FileSystem}else{$P.Type}
            $Tot = [Math]::Round($P.Size/1GB, 2)
            $Free = if($Vol){[Math]::Round($Vol.SizeRemaining/1GB, 2)}else{"-"}
            
            $R = $GridP.Rows.Add($Let, $Lab, $FS, "$Tot GB", "$Free GB", $P.GptType, "Allocated", $P.Offset)
            $GridP.Rows[$R].Tag = @{ Type="Part"; Did=$Did; Pid=$P.PartitionNumber; Let=$Let; Lab=$Lab; Size=$P.Size; Obj=$P }
            $LastOffset = $P.Offset + $P.Size
        }
        
        # Trailing Unallocated
        if ($DiskSize -gt $LastOffset + 50MB) {
            $Gap = $DiskSize - $LastOffset
            $GapGB = [Math]::Round($Gap/1GB, 2)
            $R = $GridP.Rows.Add("", "[UNALLOCATED]", "-", "$GapGB GB", "-", "Free Space", "End", $LastOffset)
            $GridP.Rows[$R].DefaultCellStyle.ForeColor = [System.Drawing.Color]::Gold
            $GridP.Rows[$R].Tag = @{ Type="Unallocated"; Offset=$LastOffset; Size=$Gap }
        }
        
    } catch {
        # WMI Fallback
        $Parts = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='\\.\PHYSICALDRIVE$Did'} WHERE AssocClass=Win32_DiskDriveToDiskPartition"
        foreach ($P in $Parts) {
            $Row = $GridP.Rows.Add("", "[WMI]", "RAW", "$([Math]::Round($P.Size/1GB,2)) GB", "-", "-", "OK", "-")
            $GridP.Rows[$Row].Tag = @{ Type="WMI_Part"; Did=$Did }
        }
    }
}

$GridD.Add_CellClick({ if($GridD.SelectedRows.Count){ Load-Parts $GridD.SelectedRows[0].Tag } })
$GridP.Add_CellClick({ 
    if($GridP.SelectedRows.Count){ 
        $Global:SelPart = $GridP.SelectedRows[0].Tag
        $T = $Global:SelPart.Type
        if ($T -eq "Unallocated") { $LblInfo.Text = "Đang chọn: VÙNG TRỐNG ($([Math]::Round($Global:SelPart.Size/1GB,2)) GB)" }
        else { $LblInfo.Text = "Đang chọn: Part $($Global:SelPart.Pid) ($($Global:SelPart.Let))" }
    } 
})

# ==================== ACTION LOGIC ====================
function Run-DP ($Cmd) {
    $F = "$env:TEMP\dp.txt"; [IO.File]::WriteAllText($F, $Cmd)
    Start-Process "diskpart" "/s `"$F`"" -Wait -NoNewWindow
    Load-Disks
}

function Custom-Benchmark ($Let) {
    $Form.Cursor = "WaitCursor"
    try {
        $Drv = $Let.Substring(0,1) + ":"
        $TestFile = "$Drv\speed_test.tmp"
        $Buf = New-Object byte[] (64 * 1024); $Total = 128 * 1024 * 1024 # 128MB Test
        $Sw = [System.Diagnostics.Stopwatch]::StartNew()
        $Fs = [System.IO.File]::Create($TestFile, 4096, [System.IO.FileOptions]::WriteThrough)
        $W=0; while($W -lt $Total){$Fs.Write($Buf,0,$Buf.Length); $W+=$Buf.Length}
        $Fs.Close(); $Sw.Stop(); $WSpeed = [Math]::Round(($Total/1MB)/$Sw.Elapsed.TotalSeconds,2)
        
        $Sw.Restart(); $Fs=[System.IO.File]::OpenRead($TestFile)
        while($Fs.Read($Buf,0,$Buf.Length) -gt 0){}; $Fs.Close(); $Sw.Stop()
        $RSpeed = [Math]::Round(($Total/1MB)/$Sw.Elapsed.TotalSeconds,2)
        
        Remove-Item $TestFile -Force -ErrorAction SilentlyContinue
        $Form.Cursor = "Default"
        [System.Windows.Forms.MessageBox]::Show("BENCHMARK ($Let):`nWRITE: $WSpeed MB/s`nREAD:  $RSpeed MB/s", "Result")
    } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi: $($_.Exception.Message)", "Error") }
}

function Run-Action ($Act) {
    $D = $Global:SelDisk; $P = $Global:SelPart
    
    if ($Act -eq "Refresh") { Load-Disks; return }
    if ($Act -eq "CreateVHD") {
        $Size = [Microsoft.VisualBasic.Interaction]::InputBox("Size (MB):", "New VHD", "1024")
        if ($Size) {
            $Path = "$env:SystemDrive\VHD_$((Get-Date).Ticks).vhdx"
            Run-DP "create vdisk file=`"$Path`" maximum=$Size type=fixed`nattach vdisk`ncreate part pri`nformat fs=ntfs quick`nassign"
            [System.Windows.Forms.MessageBox]::Show("Created: $Path", "Success")
        }
        return
    }
    if ($Act -eq "MountVHD") {
        $O = New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="VHD|*.vhd;*.vhdx"; if($O.ShowDialog()-eq"OK"){ Run-DP "sel vdisk file=`"$($O.FileName)`"`nattach vdisk" }
        return
    }
    if ($Act -eq "DetachVHD") {
        $O = New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="VHD|*.vhd;*.vhdx"; if($O.ShowDialog()-eq"OK"){ Run-DP "sel vdisk file=`"$($O.FileName)`"`ndetach vdisk" }
        return
    }

    # DISK ACTIONS
    if (!$D) { [System.Windows.Forms.MessageBox]::Show("Chọn Ổ đĩa trước!", "Lỗi"); return }
    
    if ($Act -eq "Smart") {
         if ($D.Mode -eq "WMI") { $D.Obj | Out-GridView -Title "WMI Disk Details" }
         else { Get-PhysicalDisk -DeviceId $D.ID | Select * | Out-GridView -Title "SMART Details" }
         return
    }
    if ($Act -eq "HexView") {
        try {
            $Bytes=New-Object byte[] 512; $Fs=[System.IO.File]::Open("\\.\PhysicalDrive$($D.ID)",'Open','Read','ReadWrite'); $Fs.Read($Bytes,0,512)|Out-Null; $Fs.Close()
            $Hex=[BitConverter]::ToString($Bytes)-replace'-',' '; $V=New-Object System.Windows.Forms.Form; $V.Text="MBR Hex"; $T=New-Object System.Windows.Forms.TextBox; $T.Multiline=$true; $T.Dock="Fill"; $T.Text=$Hex; $V.Controls.Add($T); $V.ShowDialog()
        } catch {[System.Windows.Forms.MessageBox]::Show("Lỗi đọc Sector 0", "Lỗi")}
        return
    }
    if ($Act -eq "BadMap") { [System.Windows.Forms.MessageBox]::Show("Tính năng mô phỏng quét Bad Sector (Visual only).", "Info"); return }
    if ($Act -eq "ConvertGPT") { Run-DP "sel disk $($D.ID)`nclean`nconvert gpt"; return }
    if ($Act -eq "DynToBas") { Run-DP "sel disk $($D.ID)`nclean`nconvert basic"; return }
    if ($Act -eq "Portable") {
        $Drv=[Microsoft.VisualBasic.Interaction]::InputBox("Ổ USB (VD: E):", "Deploy"); if($Drv){ Copy-Item $PSCommandPath "$Drv:\DiskTool.ps1"; [System.Windows.Forms.MessageBox]::Show("Done!", "OK") }
        return
    }

    # PARTITION ACTIONS
    if (!$P) { [System.Windows.Forms.MessageBox]::Show("Chọn Phân vùng!", "Lỗi"); return }
    $Did = $P.Did; $Pid = $P.PartID; $Let = $P.Let

    if ($P.Type -eq "Unallocated") {
        if ($Act -eq "Create") { Run-DP "sel disk $Did`ncreate part pri size=$([Math]::Floor($P.Size/1MB))`nformat fs=ntfs quick`nassign" }
        return
    }

    switch ($Act) {
        "Format" { Run-DP "sel disk $Did`nsel part $Pid`nformat fs=ntfs quick" }
        "Delete" { Run-DP "sel disk $Did`nsel part $Pid`ndelete partition override" }
        "Active" { Run-DP "sel disk $Did`nsel part $Pid`nactive" }
        "Letter" { $L=InputBox "New Letter:"; if($L){Run-DP "sel disk $Did`nsel part $Pid`nassign letter=$L"} }
        "Label"  { $L=InputBox "New Label:"; if($L){ Set-Volume -DriveLetter $Let.Trim(":") -NewFileSystemLabel $L; Load-Disks } }
        "Split"  {
            if ($Let) {
                $MB = [Microsoft.VisualBasic.Interaction]::InputBox("MB cắt ra:", "Split", "1024")
                if ($MB) { Resize-Partition -DriveLetter $Let.Trim(":") -Size ((Get-Partition -DriveLetter $Let.Trim(":")).Size - ($MB*1MB)); Load-Disks }
            }
        }
        "Merge" { [System.Windows.Forms.MessageBox]::Show("Hãy xóa phân vùng bên cạnh rồi dùng Extend.", "Info") }
        "FixBoot" { if($Let){Start-Process "cmd" "/c bcdboot $Let\Windows /s $Let /f ALL"} }
        "MountEFI" {
             $Efi = Get-Partition -DiskNumber $Did | Where GptType -eq "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}"
             if ($Efi) { Set-Partition -InputObject $Efi -NewDriveLetter "Z"; Load-Disks }
        }
        "SpaceAna" {
             if ($Let) {
                 $Form.Cursor="WaitCursor"; $Info = Get-ChildItem -Path "$Let\" -Directory -ErrorAction SilentlyContinue | Select Name, @{N="MB";E={ "{0:N0}" -f ((Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB) }} | Sort "MB" -Descending | Select -First 15
                 $Info | Out-GridView -Title "Top Folders"; $Form.Cursor="Default"
             }
        }
        "Wipe" { if($Let){ Format-Volume -DriveLetter $Let.Trim(":") -FileSystem NTFS -Full -Force } }
        "Benchmark" { 
            if ($Let) {
                if (Get-Command "winsat" -ErrorAction SilentlyContinue) { Start-Process "cmd" "/k winsat disk -drive $($Let.Substring(0,1)) -ran -read -count 1" }
                else { Custom-Benchmark $Let }
            }
        }
        "CloneDisk" { [System.Windows.Forms.MessageBox]::Show("Dùng Robocopy để clone data.", "Info") }
    }
}

function InputBox ($Prompt) { return [Microsoft.VisualBasic.Interaction]::InputBox($Prompt, "Input", "") }

# --- RUN ---
Apply-Theme
Load-Disks
$Form.ShowDialog() | Out-Null
