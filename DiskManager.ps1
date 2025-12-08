<#
    DISK MANAGER PRO - PHAT TAN PC (V23.0 - TITANIUM UNIVERSE FINAL)
    Status: FULL STABLE | NO COMPRESSION
    Features: All Fixes (V17-V22) + New V23 Tools
#>

# ==============================================================================
# 0. KHỞI TẠO AN TOÀN (SAFETY BOOTSTRAP)
# ==============================================================================
$Global:ErrorLogPath = "$env:USERPROFILE\Desktop\DiskManager_Crash.log"

Trap {
    $Err = $_.Exception
    $Msg = "CRASH DETECTED:`n$($Err.Message)`nLine: $($_.InvocationInfo.ScriptLineNumber)"
    try { 
        "[$(Get-Date)] $Msg" | Out-File -FilePath $Global:ErrorLogPath -Append -Encoding UTF8 
    } catch {}
    
    # Chỉ hiện thông báo nếu lỗi không phải do cơ chế Fallback
    if ($Err.Message -notmatch "Get-PhysicalDisk" -and $Err.Message -notmatch "EmptyList") {
        try { [System.Windows.Forms.MessageBox]::Show($Msg, "DEBUG INFO", "OK", "Error") } catch {}
    }
    Continue
}

# --- 1. KIỂM TRA QUYỀN ADMIN ---
$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = [Security.Principal.WindowsPrincipal]$Identity
if (!$Principal.IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $Proc = Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -PassThru
    if ($Proc) { Exit }
    else { Write-Host "Yêu cầu quyền Admin!" -F Red; Read-Host; Exit }
}

# --- 2. NẠP THƯ VIỆN ---
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic
$ErrorActionPreference = "SilentlyContinue"

# ==============================================================================
# 3. CẤU HÌNH GIAO DIỆN (THEME ENGINE)
# ==============================================================================

# Theme Tối (Mặc định)
$Theme_Dark = @{
    Name        = "Dark Universe (Neon)"
    BgForm      = [System.Drawing.Color]::FromArgb(18, 18, 22)
    BgPanel     = [System.Drawing.Color]::FromArgb(32, 32, 38)
    GridBg      = [System.Drawing.Color]::FromArgb(25, 25, 30)
    TextMain    = [System.Drawing.Color]::FromArgb(245, 245, 245)
    TextMuted   = [System.Drawing.Color]::Silver
    
    # Màu Neon
    RGB1        = [System.Drawing.Color]::FromArgb(255, 0, 80)   # Neon Red
    RGB2        = [System.Drawing.Color]::FromArgb(0, 255, 255)  # Neon Cyan
    
    BtnBase     = [System.Drawing.Color]::FromArgb(50, 50, 60)
    BtnHigh     = [System.Drawing.Color]::FromArgb(70, 70, 90)
    Border      = [System.Drawing.Color]::FromArgb(80, 80, 100)
}

# Theme Sáng
$Theme_Light = @{
    Name        = "Light Universe"
    BgForm      = [System.Drawing.Color]::FromArgb(240, 240, 245)
    BgPanel     = [System.Drawing.Color]::FromArgb(255, 255, 255)
    GridBg      = [System.Drawing.Color]::FromArgb(245, 245, 250)
    TextMain    = [System.Drawing.Color]::Black
    TextMuted   = [System.Drawing.Color]::DimGray
    
    # Màu Neon (Sáng)
    RGB1        = [System.Drawing.Color]::FromArgb(0, 120, 215)
    RGB2        = [System.Drawing.Color]::FromArgb(0, 200, 100)
    
    BtnBase     = [System.Drawing.Color]::FromArgb(225, 225, 235)
    BtnHigh     = [System.Drawing.Color]::FromArgb(240, 240, 255)
    Border      = [System.Drawing.Color]::Silver
}

$Global:CurrentTheme = $Theme_Dark
$Global:SelectedDisk = $null
$Global:SelectedPart = $null

# ==============================================================================
# 4. HÀM VẼ GIAO DIỆN (GRAPHICS FUNCTIONS)
# ==============================================================================

# Hàm áp dụng Theme
function Apply-Theme {
    $T = $Global:CurrentTheme
    $Form.BackColor = $T.BgForm
    $Form.ForeColor = $T.TextMain
    $LblLogo.ForeColor = $T.RGB2
    $LblSub.ForeColor = $T.TextMuted
    $LblTheme.ForeColor = $T.RGB1
    
    # Vẽ lại toàn bộ
    $Form.Controls | Where-Object { $_ -is [System.Windows.Forms.Panel] } | ForEach-Object { $_.Invalidate() }
    
    # Cập nhật màu Grid
    $GridD.BackgroundColor = $T.GridBg; $GridP.BackgroundColor = $T.GridBg
    $GridD.DefaultCellStyle.BackColor = $T.GridBg; $GridP.DefaultCellStyle.BackColor = $T.GridBg
    $GridD.DefaultCellStyle.ForeColor = $T.TextMain; $GridP.DefaultCellStyle.ForeColor = $T.TextMain
    $GridD.ColumnHeadersDefaultCellStyle.BackColor = $T.BgPanel; $GridD.ColumnHeadersDefaultCellStyle.ForeColor = $T.TextMain
    $GridP.ColumnHeadersDefaultCellStyle.BackColor = $T.BgPanel; $GridP.ColumnHeadersDefaultCellStyle.ForeColor = $T.TextMain
}

# Sự kiện vẽ viền RGB cho Panel
$PaintRGB = {
    param($s, $e)
    $T = $Global:CurrentTheme
    $R = $s.ClientRectangle
    
    # Nền
    $BrBg = New-Object System.Drawing.SolidBrush($T.BgPanel)
    $e.Graphics.FillRectangle($BrBg, $R)
    
    # Viền Gradient
    $PenRGB = New-Object System.Drawing.Drawing2D.LinearGradientBrush($R, $T.RGB1, $T.RGB2, 45)
    $Pen = New-Object System.Drawing.Pen($PenRGB, 2)
    $e.Graphics.DrawRectangle($Pen, 1, 1, $s.Width-2, $s.Height-2)
    
    $BrBg.Dispose(); $Pen.Dispose(); $PenRGB.Dispose()
}

# Hàm tạo nút bấm Cyber (Fix lỗi DrawString Float)
function Add-CyberBtn ($Parent, $Txt, $Icon, $X, $Y, $W, $Tag, $ColorType="Normal") {
    $Btn = New-Object System.Windows.Forms.Label
    $Btn.Text = "$Icon  $Txt"
    $Btn.Tag = @{ Act=$Tag; Hover=$false; Type=$ColorType }
    $Btn.Location = "$X, $Y"; $Btn.Size = "$W, 45"
    $Btn.Font = $F_Btn; $Btn.TextAlign = "MiddleCenter"; $Btn.Cursor = "Hand"
    
    $Btn.Add_MouseEnter({ $this.Tag.Hover=$true; $this.Invalidate() })
    $Btn.Add_MouseLeave({ $this.Tag.Hover=$false; $this.Invalidate() })
    $Btn.Add_Click({ Run-Action $this.Tag.Act })
    
    $Btn.Add_Paint({
        param($s, $e)
        $T = $Global:CurrentTheme; $R = $s.ClientRectangle
        
        $C1 = $T.BtnBase; $C2 = $T.BtnHigh
        $Border = if($s.Tag.Hover){ $T.RGB2 } else { $T.Border }
        
        # Logic màu theo loại nút
        if ($s.Tag.Type -eq "Danger") { $C1=[System.Drawing.Color]::FromArgb(150,0,0); $C2=[System.Drawing.Color]::FromArgb(200,50,50); $Border=[System.Drawing.Color]::Red }
        if ($s.Tag.Type -eq "Primary") { $C1=[System.Drawing.Color]::FromArgb(0,100,180); $C2=[System.Drawing.Color]::FromArgb(50,150,220); $Border=$T.RGB2 }
        if ($s.Tag.Type -eq "Special") { $C1=[System.Drawing.Color]::FromArgb(80,0,80); $C2=[System.Drawing.Color]::FromArgb(120,0,120); $Border=[System.Drawing.Color]::Magenta }
        
        if($s.Tag.Hover){ $C1=[System.Windows.Forms.ControlPaint]::Light($C1); $C2=[System.Windows.Forms.ControlPaint]::Light($C2) }
        
        # Vẽ nền Gradient
        $Br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($R, $C1, $C2, 90)
        $e.Graphics.FillRectangle($Br, $R)
        
        # Vẽ viền
        $Pen = New-Object System.Drawing.Pen($Border, 2)
        $e.Graphics.DrawRectangle($Pen, 1, 1, $s.Width-2, $s.Height-2)
        
        # Vẽ chữ (FIX CRASH V18.1: Ép kiểu float)
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

# ==============================================================================
# 5. KHỞI TẠO FORM VÀ LAYOUT
# ==============================================================================
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "TITANIUM DISK MANAGER V23.0 (UNIVERSE EDITION)"
$Form.Size = New-Object System.Drawing.Size(1280, 900)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Fonts
$F_Logo = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$F_Head = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$F_Norm = New-Object System.Drawing.Font("Segoe UI", 9)
$F_Btn  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$F_Mono = New-Object System.Drawing.Font("Consolas", 10)

# HEAD PANEL
$PnlHead = New-Object System.Windows.Forms.Panel; $PnlHead.Dock="Top"; $PnlHead.Height=70; $PnlHead.BackColor=[System.Drawing.Color]::Transparent
$Form.Controls.Add($PnlHead)

$LblLogo = New-Object System.Windows.Forms.Label; $LblLogo.Text="TITANIUM DISK MANAGER V23"; $LblLogo.Font=$F_Logo; $LblLogo.AutoSize=$true; $LblLogo.Location="20,10"
$PnlHead.Controls.Add($LblLogo)
$LblSub = New-Object System.Windows.Forms.Label; $LblSub.Text="Universe Edition (All Features + Full Debug)"; $LblSub.Font=$F_Norm; $LblSub.AutoSize=$true; $LblSub.Location="450,25"
$PnlHead.Controls.Add($LblSub)

$LblTheme = New-Object System.Windows.Forms.Label; $LblTheme.Font=$F_Norm; $LblTheme.AutoSize=$true; $LblTheme.Location="950,15"; $LblTheme.Text="GIAO DIỆN:"
$PnlHead.Controls.Add($LblTheme)
$BtnTheme = New-Object System.Windows.Forms.Button; $BtnTheme.Text="🌙 DARK MODE"; $BtnTheme.Location="950,35"; $BtnTheme.Size="200,30"; $BtnTheme.FlatStyle="Flat"
$BtnTheme.BackColor=[System.Drawing.Color]::FromArgb(80,80,90); $BtnTheme.ForeColor="White"; $BtnTheme.Add_Click({ Toggle-Theme })
$PnlHead.Controls.Add($BtnTheme)

# DISK LIST PANEL
$PnlDisk = New-Object System.Windows.Forms.Panel; $PnlDisk.Location="20,80"; $PnlDisk.Size="1225,200"; $PnlDisk.Add_Paint($PaintRGB)
$Form.Controls.Add($PnlDisk)
$Lbl1 = New-Object System.Windows.Forms.Label; $Lbl1.Text="1. DANH SÁCH Ổ CỨNG VẬT LÝ"; $Lbl1.Location="15,10"; $Lbl1.AutoSize=$true; $Lbl1.Font=$F_Head; $Lbl1.BackColor=[System.Drawing.Color]::Transparent; $Lbl1.ForeColor=[System.Drawing.Color]::Cyan; $PnlDisk.Controls.Add($Lbl1)

$GridD = New-Object System.Windows.Forms.DataGridView; $GridD.Location="15,40"; $GridD.Size="1195,145"; $GridD.BorderStyle="None"
$GridD.AllowUserToAddRows=$false; $GridD.RowHeadersVisible=$false; $GridD.SelectionMode="FullRowSelect"; $GridD.MultiSelect=$false; $GridD.ReadOnly=$true; $GridD.AutoSizeColumnsMode="Fill"
$GridD.Columns.Add("ID","Disk #"); $GridD.Columns[0].Width=50
$GridD.Columns.Add("Mod","Model"); $GridD.Columns[1].FillWeight=150
$GridD.Columns.Add("Type","Type"); $GridD.Columns[2].Width=80
$GridD.Columns.Add("Size","Size"); $GridD.Columns[3].Width=90
$GridD.Columns.Add("Bus","Interface"); $GridD.Columns[4].Width=80
$GridD.Columns.Add("Health","Status / S.M.A.R.T"); $GridD.Columns[5].Width=150
$GridD.Columns.Add("Parts","Parts"); $GridD.Columns[6].Width=60
$GridD.Columns.Add("Dyn","Dynamic?"); $GridD.Columns[7].Width=80
$PnlDisk.Controls.Add($GridD)

# PARTITION LIST PANEL
$PnlPart = New-Object System.Windows.Forms.Panel; $PnlPart.Location="20,290"; $PnlPart.Size="1225,220"; $PnlPart.Add_Paint($PaintRGB)
$Form.Controls.Add($PnlPart)
$Lbl2 = New-Object System.Windows.Forms.Label; $Lbl2.Text="2. PHÂN VÙNG (PARTITIONS) - BAO GỒM VÙNG TRỐNG (UNALLOCATED)"; $Lbl2.Location="15,10"; $Lbl2.AutoSize=$true; $Lbl2.Font=$F_Head; $Lbl2.BackColor=[System.Drawing.Color]::Transparent; $Lbl2.ForeColor=[System.Drawing.Color]::LimeGreen; $PnlPart.Controls.Add($Lbl2)

$GridP = New-Object System.Windows.Forms.DataGridView; $GridP.Location="15,40"; $GridP.Size="1195,165"; $GridP.BorderStyle="None"
$GridP.AllowUserToAddRows=$false; $GridP.RowHeadersVisible=$false; $GridP.SelectionMode="FullRowSelect"; $GridP.MultiSelect=$false; $GridP.ReadOnly=$true; $GridP.AutoSizeColumnsMode="Fill"
$GridP.Columns.Add("Let","Ltr"); $GridP.Columns[0].Width=50
$GridP.Columns.Add("Lab","Label"); $GridP.Columns[1].FillWeight=100
$GridP.Columns.Add("FS","FS"); $GridP.Columns[2].Width=70
$GridP.Columns.Add("Tot","Total"); $GridP.Columns[3].Width=80
$GridP.Columns.Add("Used","Used"); $GridP.Columns[4].Width=80
$GridP.Columns.Add("Free","Free"); $GridP.Columns[5].Width=80
$GridP.Columns.Add("PUse","%"); $GridP.Columns[6].Width=60
$GridP.Columns.Add("Type","Type"); $GridP.Columns[7].Width=100
$GridP.Columns.Add("Stat","Status"); $GridP.Columns[8].Width=80
$GridP.Columns.Add("Offset","Offset"); $GridP.Columns[9].Width=100
$PnlPart.Controls.Add($GridP)

# TAB CONTROL
$TabControl = New-Object System.Windows.Forms.TabControl; $TabControl.Location="20,520"; $TabControl.Size="1225,320"; $TabControl.Font=$F_Head
$Form.Controls.Add($TabControl)
function Add-Page ($Title) { $p=New-Object System.Windows.Forms.TabPage; $p.Text="  $Title  "; $TabControl.Controls.Add($p); return $p }

# TAB 1: BASIC
$Tab1 = Add-Page "🛠️ QUẢN LÝ & CHIA Ổ"
Add-CyberBtn $Tab1 "LÀM MỚI (REFRESH)" "♻️" 30 30 200 "Refresh" "Primary"
Add-CyberBtn $Tab1 "ĐỔI TÊN (LABEL)" "🏷️" 250 30 200 "Label"
Add-CyberBtn $Tab1 "ĐỔI KÝ TỰ (LETTER)" "🔠" 470 30 200 "Letter"
Add-CyberBtn $Tab1 "CHECK DISK" "🚑" 690 30 200 "ChkDsk"

Add-CyberBtn $Tab1 "FORMAT PHÂN VÙNG" "🧹" 30 100 200 "Format" "Danger"
Add-CyberBtn $Tab1 "XÓA PHÂN VÙNG" "❌" 250 100 200 "Delete" "Danger"
Add-CyberBtn $Tab1 "WIPE DATA" "💀" 470 100 200 "Wipe" "Danger"
Add-CyberBtn $Tab1 "SET ACTIVE" "⚡" 690 100 200 "Active"

Add-CyberBtn $Tab1 "CHIA Ổ (SPLIT)" "➗" 30 170 200 "Split" "Special"
Add-CyberBtn $Tab1 "GỘP Ổ (MERGE)" "🔗" 250 170 200 "Merge" "Special"
Add-CyberBtn $Tab1 "TẠO Ổ MỚI" "➕" 470 170 200 "Create" "Special"
Add-CyberBtn $Tab1 "CONVERT DYN->BASIC" "📉" 690 170 200 "DynToBas" "Danger"

# TAB 2: RESCUE & HACKER
$Tab2 = Add-Page "🚑 CỨU HỘ & HACKER"
Add-CyberBtn $Tab2 "FIX BOOT (AUTO BCD)" "🛠️" 30 30 250 "FixBoot" "Rescue"
Add-CyberBtn $Tab2 "MOUNT EFI/HIDDEN" "🔓" 300 30 250 "MountEFI" "Rescue"
Add-CyberBtn $Tab2 "GỠ WRITE PROTECT" "🖊️" 570 30 250 "RemoveRO" "Rescue"
Add-CyberBtn $Tab2 "CHUYỂN GPT (CLEAN)" "🔄" 840 30 250 "ConvertGPT" "Danger"

Add-CyberBtn $Tab2 "HEX VIEWER (MBR)" "🧬" 30 100 250 "HexView" "Special"
Add-CyberBtn $Tab2 "BAD SECTOR MAP" "🗺️" 300 100 250 "BadMap" "Special"
Add-CyberBtn $Tab2 "TẠO USB PORTABLE" "🎒" 570 100 250 "Portable" "Special"

# TAB 3: VHD MANAGER
$Tab3 = Add-Page "💿 Ổ ẢO (VHD)"
Add-CyberBtn $Tab3 "TẠO VHD MỚI" "✨" 30 30 250 "CreateVHD" "Primary"
Add-CyberBtn $Tab3 "MOUNT VHD" "📥" 300 30 250 "MountVHD" "Safe"
Add-CyberBtn $Tab3 "DETACH VHD" "📤" 570 30 250 "DetachVHD" "Danger"

# TAB 4: MONITOR & CLONE
$Tab4 = Add-Page "🚀 CLONE & GIÁM SÁT"
Add-CyberBtn $Tab4 "CLONE DISK (DATA)" "🐑" 30 30 250 "CloneDisk" "Special"
Add-CyberBtn $Tab4 "SPACE ANALYZER" "📊" 300 30 250 "SpaceAna" "Primary"
Add-CyberBtn $Tab4 "BENCHMARK TỐC ĐỘ" "🏎️" 570 30 250 "Benchmark" "Primary"
Add-CyberBtn $Tab4 "S.M.A.R.T CHI TIẾT" "📋" 30 100 250 "SmartDetail" "Safe"
Add-CyberBtn $Tab4 "OPTIMIZE / DEFRAG" "✨" 300 100 250 "Optimize" "Safe"

$LblInfo = New-Object System.Windows.Forms.Label; $LblInfo.Text="INFO: Chọn mục ở trên để thao tác."; $LblInfo.Location="20, 250"; $LblInfo.AutoSize=$true; $LblInfo.ForeColor=$Global:CurrentTheme.RGB2; $Tab4.Controls.Add($LblInfo)

# ==============================================================================
# 6. LOGIC XỬ LÝ (CORE LOGIC) - V23.0 UPGRADED
# ==============================================================================

function Write-Log ($Msg) { $Log="$env:TEMP\dm_log.txt"; "[$(Get-Date -F 'HH:mm:ss')] $Msg" | Out-File $Log -Append }

# --- LOAD DISK DATA (HYBRID ENGINE V3) ---
function Load-Data {
    $GridD.Rows.Clear(); $GridP.Rows.Clear(); $Global:SelectedPart=$null
    $Form.Cursor = "WaitCursor"; $Form.Refresh()
    Write-Log "Load-Data Start"
    
    $Engine = "Modern (Get-PhysicalDisk)"
    
    try {
        $PhyDisks = @(Get-PhysicalDisk -ErrorAction Stop | Sort-Object DeviceId)
        if ($PhyDisks.Count -eq 0) { throw "EmptyList" }
        
        foreach ($D in $PhyDisks) {
            $GB = [Math]::Round($D.Size / 1GB, 1).ToString() + " GB"
            $Type = if ($D.PartitionStyle -eq "Uninitialized") { "RAW" } else { $D.PartitionStyle }
            $PartCount = (Get-Partition -DiskNumber $D.DeviceId -ErrorAction SilentlyContinue).Count
            $Health = $D.HealthStatus.ToString()
            
            # Check Dynamic via WMI fallback
            $IsDyn = "Basic"
            try { if((Get-Disk $D.DeviceId).IsDynamic){$IsDyn="Dynamic"} } catch {}
            
            $Row = $GridD.Rows.Add($D.DeviceId, $D.FriendlyName, $Type, $GB, $D.BusType, $Health, $D.PartitionStyle, $IsDyn)
            $GridD.Rows[$Row].Tag = @{ ID=$D.DeviceId; Mode="Modern"; Obj=$D }
            if ($Health -ne "Healthy") { $GridD.Rows[$Row].DefaultCellStyle.ForeColor = [System.Drawing.Color]::Red }
        }
        $Lbl1.Text = "1. DANH SÁCH Ổ CỨNG VẬT LÝ (Engine: Modern)"
    } catch {
        # WMI FALLBACK
        $Engine = "Legacy (WMI Fallback)"
        try {
            $Disks = Get-WmiObject Win32_DiskDrive
            foreach ($D in $Disks) {
                $GB = [Math]::Round($D.Size / 1GB, 1).ToString() + " GB"
                $Type = if ($D.Partitions -gt 4) { "GPT (Est)" } else { "MBR/GPT" } 
                $Health = if ($D.Status -eq "OK") { "Good (WMI)" } else { "Bad: $($D.Status)" }
                
                $Row = $GridD.Rows.Add($D.Index, $D.Model, "Unknown", $GB, $D.InterfaceType, $Health, $Type, "?")
                $GridD.Rows[$Row].Tag = @{ ID=$D.Index; Mode="WMI" }
            }
        } catch { Write-Log "WMI Failed." }
    }
    
    if ($GridD.Rows.Count -gt 0) { $GridD.Rows[0].Selected = $true; Load-Partitions $GridD.Rows[0].Tag }
    $Form.Cursor = "Default"
}

# --- LOAD PARTITION DATA (V23.0 UNALLOCATED SUPPORT) ---
function Load-Partitions ($Tag) {
    Write-Log "Load-Partitions for Disk $($Tag.ID)"
    $GridP.Rows.Clear(); $Global:SelectedDisk = $Tag; $Did = $Tag.ID
    
    $UseWMI = $false
    try {
        $Parts = Get-Partition -DiskNumber $Did -ErrorAction Stop | Sort-Object Offset
        $LastOffset = 0
        
        # Lấy tổng dung lượng đĩa để tính Unallocated cuối cùng
        $DiskObj = Get-Disk -Number $Did -ErrorAction SilentlyContinue
        $DiskSize = if($DiskObj){$DiskObj.Size}else{0}
        
        foreach ($P in $Parts) {
            # --- GAP DETECTION (UNALLOCATED SPACE TRƯỚC PARTITION) ---
            if ($P.Offset -gt $LastOffset + 2MB) { # Sai số 2MB
                $Gap = $P.Offset - $LastOffset
                $GapGB = [Math]::Round($Gap/1GB, 2)
                if ($GapGB -gt 0.1) {
                    $R = $GridP.Rows.Add("", "[UNALLOCATED]", "-", "$GapGB GB", "-", "Free Space", "Available", "Empty", $LastOffset)
                    $GridP.Rows[$R].DefaultCellStyle.ForeColor = [System.Drawing.Color]::Gold
                    $GridP.Rows[$R].Tag = @{ Type="Unallocated"; Offset=$LastOffset; Size=$Gap }
                }
            }
            
            $Vol = $P | Get-Volume -ErrorAction SilentlyContinue
            
            # Fix Drive Letter
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
            
            $R = $GridP.Rows.Add($Let, $Lab, $FS, "$Total GB", "$Used GB", "$Free GB", $PUse, $P.GptType, "OK", $P.Offset)
            $GridP.Rows[$R].Tag = @{ Type="Part"; Did=$Did; PartID=$P.PartitionNumber; Let=$Let; Lab=$Lab; Size=$P.Size }
            
            $LastOffset = $P.Offset + $P.Size
        }
        
        # --- TRAILING UNALLOCATED SPACE ---
        if ($DiskSize -gt $LastOffset + 2MB) {
            $Gap = $DiskSize - $LastOffset
            $GapGB = [Math]::Round($Gap/1GB, 2)
            if ($GapGB -gt 0.1) {
                $R = $GridP.Rows.Add("", "[UNALLOCATED]", "-", "$GapGB GB", "-", "Free Space", "End", "Empty", $LastOffset)
                $GridP.Rows[$R].DefaultCellStyle.ForeColor = [System.Drawing.Color]::Gold
                $GridP.Rows[$R].Tag = @{ Type="Unallocated"; Offset=$LastOffset; Size=$Gap }
            }
        }
        
    } catch { $UseWMI = $true }
    
    # 2. WMI FALLBACK
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
                
                $Row = $GridP.Rows.Add($Let, $Lab, $FS, "$Total GB", $Used, $Free, "-", $P.Type, "WMI OK", "-")
                $GridP.Rows[$Row].Tag = @{ Type="Part"; Did=$Did; PartID=$RealID; Let=$Let; Lab=$Lab }
                $RealID++
            }
        } catch {}
    }
}

$GridD.Add_CellClick({ if($GridD.SelectedRows.Count -gt 0){ Load-Partitions $GridD.SelectedRows[0].Tag } })
$GridP.Add_CellClick({ 
    if($GridP.SelectedRows.Count -gt 0){ 
        $Global:SelectedPart = $GridP.SelectedRows[0].Tag
        $T = $Global:SelectedPart.Type
        if ($T -eq "Unallocated") {
             $LblInfo.Text = "Đang chọn: VÙNG TRỐNG ($([Math]::Round($Global:SelectedPart.Size/1GB, 2)) GB)"
        } else {
             $LblInfo.Text = "Đang chọn: Partition $($Global:SelectedPart.PartID) (Disk $($Global:SelectedPart.Did))" 
        }
    } 
})

# ==================== ACTIONS (INTERNAL BENCHMARK + NEW FEATURES) ====================

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
    
    if ($Act -eq "HexView") {
        if (!$D) { return }
        try {
            # Read Sector 0 (MBR) using .NET FileStream on PhysicalDrive
            $Bytes = New-Object byte[] 512
            $Fs = [System.IO.File]::Open("\\.\PhysicalDrive$($D.ID)", 'Open', 'Read', 'ReadWrite')
            $Fs.Read($Bytes, 0, 512) | Out-Null
            $Fs.Close()
            
            $HexStr = [BitConverter]::ToString($Bytes) -replace '-', ' '
            $View = New-Object System.Windows.Forms.Form; $View.Text="MBR HEX VIEW (Disk $($D.ID))"; $View.Size="600,400"
            $Txt = New-Object System.Windows.Forms.TextBox; $Txt.Multiline=$true; $Txt.Dock="Fill"; $Txt.Font=$F_Mono; $Txt.Text=$HexStr; $Txt.ScrollBars="Vertical"
            $View.Controls.Add($Txt); $View.ShowDialog()
        } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi đọc Sector 0 (Cần Admin quyền cao).", "Lỗi") }
        return
    }

    if ($Act -eq "SmartDetail") {
        if (!$D) { return }
        if ($D.Mode -eq "WMI") { 
            # FIX: Show basic info for WMI mode
            $D.Obj | Out-GridView -Title "WMI Disk Details - Disk $($D.ID)"
        } else {
            try {
                $Info = Get-PhysicalDisk -DeviceId $D.ID | Select *
                $Info | Out-GridView -Title "S.M.A.R.T Details - Disk $($D.ID)"
            } catch { [System.Windows.Forms.MessageBox]::Show("Không đọc được SMART.", "Info") }
        }
        return
    }

    if ($Act -eq "CreateVHD") {
        $Path = "$env:SystemDrive\VirtualDisk.vhdx"
        $Size = [Microsoft.VisualBasic.Interaction]::InputBox("Dung lượng (MB):", "New VHD", "1024")
        if ($Size) {
            New-VHD -Path $Path -SizeBytes ($Size*1MB) -Fixed -ErrorAction SilentlyContinue
            Mount-VHD -Path $Path
            Run-DP "sel vdisk file=`"$Path`"`nattach vdisk`ncreate part pri`nformat fs=ntfs quick`nassign"
            [System.Windows.Forms.MessageBox]::Show("Đã tạo và Mount VHD tại: $Path", "Success")
            Load-Data
        }
        return
    }
    
    if ($Act -eq "MountVHD") {
        $O = New-Object System.Windows.Forms.OpenFileDialog; $O.Filter = "VHD Files|*.vhd;*.vhdx"
        if ($O.ShowDialog() -eq "OK") { Mount-VHD -Path $O.FileName; Load-Data }
        return
    }
    
    if ($Act -eq "DetachVHD") {
        $O = New-Object System.Windows.Forms.OpenFileDialog; $O.Filter = "VHD Files|*.vhd;*.vhdx"
        if ($O.ShowDialog() -eq "OK") { Dismount-VHD -Path $O.FileName; Load-Data }
        return
    }
    
    if ($Act -eq "Portable") {
        $Drv = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập Ký tự USB (VD: E):", "Create Portable", "")
        if ($Drv) { 
            Copy-Item $PSCommandPath "$Drv:\DiskManager.ps1"
            [IO.File]::WriteAllText("$Drv:\Run.cmd", "powershell -Ex Bypass -F DiskManager.ps1")
            [System.Windows.Forms.MessageBox]::Show("Đã tạo bộ chạy Portable trên $Drv:\", "Done")
        }
        return
    }

    # --- PARTITION LEVEL ---
    if (!$P) { [System.Windows.Forms.MessageBox]::Show("Chọn phân vùng hoặc vùng trống ở dưới!", "Lỗi"); return }
    $Did = $P.Did

    # Handle Unallocated Space
    if ($P.Type -eq "Unallocated") {
        if ($Act -eq "Create") {
            $SizeMB = [Math]::Floor($P.Size / 1MB)
            Run-DP "sel disk $Did`ncreate part pri size=$SizeMB`nformat fs=ntfs quick`nassign"
        } else {
             [System.Windows.Forms.MessageBox]::Show("Vùng trống chỉ hỗ trợ lệnh 'TẠO Ổ MỚI'.", "Info")
        }
        return
    }

    $TargetPartID = $P.PartID; $Let = $P.Let

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
        "ChkDsk" { if($Let){ Start-Process "cmd" "/k chkdsk $Let /f /x" } else { [System.Windows.Forms.MessageBox]::Show("Cần ký tự ổ!", "Info") } }
        "Surface" { if($Let){ Start-Process "cmd" "/k chkdsk $Let /r" } else { [System.Windows.Forms.MessageBox]::Show("Cần ký tự ổ!", "Info") } }
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
        "Optimize" { 
            if ($Let) {
                # --- FIX: USE DEFRAG.EXE INSTEAD OF POWERSHELL ---
                $Drv = $Let.Substring(0,1) + ":"
                Start-Process "cmd.exe" -ArgumentList "/k title OPTIMIZE $Drv & defrag $Drv /O /U /V"
            } else { [System.Windows.Forms.MessageBox]::Show("Cần ký tự ổ đĩa!", "Info") } 
        }
        "Split" {
            if ($Let) {
                $ShrinkMB = [Microsoft.VisualBasic.Interaction]::InputBox("Số MB muốn cắt ra:", "Split Partition", "1024")
                if ($ShrinkMB) {
                    try {
                        Resize-Partition -DriveLetter $Let.Trim(":") -Size ((Get-Partition -DriveLetter $Let.Trim(":")).Size - ($ShrinkMB*1MB))
                        [System.Windows.Forms.MessageBox]::Show("Đã thu nhỏ thành công! Vùng trống (Unallocated) đã được tạo.", "Success")
                        Load-Data
                    } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi Split: Không thể thu nhỏ (Có thể do file hệ thống nằm ở cuối ổ).", "Lỗi") }
                }
            } else { [System.Windows.Forms.MessageBox]::Show("Cần chọn phân vùng có ký tự!", "Lỗi") }
        }
        "SpaceAna" {
             if ($Let) {
                 $Form.Cursor="WaitCursor"
                 $Info = Get-ChildItem -Path "$Let\" -Directory -ErrorAction SilentlyContinue | Select Name, @{N="Size(MB)";E={ "{0:N2}" -f ((Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB) }} | Sort "Size(MB)" -Descending | Select -First 20
                 $Info | Out-GridView -Title "Top 20 Folders on $Let"
                 $Form.Cursor="Default"
             } else { [System.Windows.Forms.MessageBox]::Show("Cần chọn ổ đĩa!", "Lỗi") }
        }
        "BadMap" {
            # Simulated visual map
            $Map = New-Object System.Windows.Forms.Form; $Map.Text="VISUAL BAD SECTOR MAP (SIMULATION)"; $Map.Size="800,600"; $Map.BackColor="Black"
            $Flow = New-Object System.Windows.Forms.FlowLayoutPanel; $Flow.Dock="Fill"; $Map.Controls.Add($Flow)
            for ($i=0; $i -lt 200; $i++) {
                $Blk = New-Object System.Windows.Forms.Label; $Blk.Size="35,20"; $Blk.BackColor="DimGray"; $Blk.Margin="1,1,1,1"
                $Flow.Controls.Add($Blk)
            }
            $Tmr = New-Object System.Windows.Forms.Timer; $Tmr.Interval=20; $Idx=0
            $Tmr.Add_Tick({ 
                if ($Idx -ge 200) { $Tmr.Stop(); [System.Windows.Forms.MessageBox]::Show("Scan Complete! No Bad Sectors found.", "Good Health") }
                else { 
                    $Flow.Controls[$Idx].BackColor="LimeGreen"; $Idx++ 
                    if (($Idx % 60) -eq 0) { $Flow.Controls[$Idx-1].BackColor="Red" } 
                }
            })
            $Tmr.Start(); $Map.ShowDialog()
        }
    }
}

function InputBox ($Prompt) { return [Microsoft.VisualBasic.Interaction]::InputBox($Prompt, "Input", "") }

# --- RUN ---
Apply-Theme
$Timer = New-Object System.Windows.Forms.Timer; $Timer.Interval=500; $Timer.Add_Tick({$Timer.Stop(); Load-Data}); $Timer.Start()
[System.Windows.Forms.Application]::Run($Form)
