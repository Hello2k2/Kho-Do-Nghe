<#
    DISK MANAGER PRO - PHAT TAN PC (V17.0 - TITANIUM GLASS)
    Fix: $PID Variable Conflict (System Variable Protected)
    New: Optimize Drive, Glass UI, Enhanced Error Handling
    Custom: Vietnamese, Extended Grid, Dark/Light Mode with Neon/Glow
#>

# --- 0. ANTI-CLOSE WRAPPER ---
try {

# --- 1. ADMIN CHECK ---
$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = [Security.Principal.WindowsPrincipal]$Identity
if (!$Principal.IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# --- 2. LOAD LIBRARIES ---
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic
$ErrorActionPreference = "SilentlyContinue"

# --- THEME CONFIGS ---
$Theme_Dark = @{
    Name = "Dark Mode (Titanium Neon)"
    BgForm      = [System.Drawing.Color]::FromArgb(18, 18, 22)
    BgPanel     = [System.Drawing.Color]::FromArgb(30, 30, 36)
    GridBg      = [System.Drawing.Color]::FromArgb(24, 24, 28)
    TextMain    = [System.Drawing.Color]::FromArgb(245, 245, 245)
    TextMuted   = [System.Drawing.Color]::FromArgb(160, 160, 160)
    GridText    = [System.Drawing.Color]::Black
    # Neon Accents
    Cyan        = [System.Drawing.Color]::FromArgb(0, 220, 255)
    Red         = [System.Drawing.Color]::FromArgb(255, 60, 80)
    Green       = [System.Drawing.Color]::FromArgb(50, 230, 150)
    Orange      = [System.Drawing.Color]::FromArgb(255, 180, 0)
    BtnBase     = [System.Drawing.Color]::FromArgb(50, 50, 60)
    BtnHigh     = [System.Drawing.Color]::FromArgb(70, 70, 80)
    BorderColor = [System.Drawing.Color]::FromArgb(60,60,70)
}

$Theme_Light = @{
    Name = "Light Mode (White Glow)"
    BgForm      = [System.Drawing.Color]::FromArgb(240, 240, 240)
    BgPanel     = [System.Drawing.Color]::FromArgb(250, 250, 255)
    GridBg      = [System.Drawing.Color]::FromArgb(220, 220, 220)
    TextMain    = [System.Drawing.Color]::FromArgb(10, 10, 10)
    TextMuted   = [System.Drawing.Color]::FromArgb(90, 90, 90)
    GridText    = [System.Drawing.Color]::Black
    # Glow Accents
    Cyan        = [System.Drawing.Color]::FromArgb(0, 150, 200)
    Red         = [System.Drawing.Color]::FromArgb(200, 40, 60)
    Green       = [System.Drawing.Color]::FromArgb(0, 150, 50)
    Orange      = [System.Drawing.Color]::FromArgb(200, 120, 0)
    BtnBase     = [System.Drawing.Color]::FromArgb(190, 190, 200)
    BtnHigh     = [System.Drawing.Color]::FromArgb(210, 210, 220)
    BorderColor = [System.Drawing.Color]::FromArgb(150, 150, 150)
}

$Global:CurrentTheme = $Theme_Dark # Default to Dark Mode
$Global:SelectedDisk = $null
$Global:SelectedPart = $null

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "TITANIUM DISK MANAGER V17.0 (FIXED & ENHANCED)"
$Form.Size = New-Object System.Drawing.Size(1280, 850)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# -- FONTS --
$F_Logo = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$F_Head = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$F_Norm = New-Object System.Drawing.Font("Segoe UI", 9)
$F_Btn  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

# ==================== THEME APPLY & CUSTOM DRAWING ====================

function Apply-Theme {
    $T = $Global:CurrentTheme
    $Form.BackColor = $T.BgForm
    $Form.ForeColor = $T.TextMain
    $LblLogo.ForeColor = $T.Cyan
    $LblSub.ForeColor = $T.TextMuted
    $Lbl1.ForeColor = $T.Cyan
    $Lbl2.ForeColor = $T.Green
    $LblInfo.ForeColor = $T.Cyan
    $LblTheme.Text = "CHẾ ĐỘ: $($T.Name)"
    
    # Data Grids
    $GridD.BackgroundColor = $T.GridBg; $GridP.BackgroundColor = $T.GridBg
    $GridD.DefaultCellStyle.BackColor = $T.GridBg
    $GridP.DefaultCellStyle.BackColor = $T.GridBg
    $GridD.DefaultCellStyle.ForeColor = $T.TextMain # Use main text color for data
    $GridP.DefaultCellStyle.ForeColor = $T.TextMain
    $GridD.ColumnHeadersDefaultCellStyle.BackColor = $T.BgPanel
    $GridP.ColumnHeadersDefaultCellStyle.BackColor = $T.BgPanel
    $GridD.ColumnHeadersDefaultCellStyle.ForeColor = $T.TextMain
    $GridP.ColumnHeadersDefaultCellStyle.ForeColor = $T.TextMain
    
    # Tabs
    $TabControl.Controls | ForEach-Object { $_.BackColor = $T.BgPanel }
    $TabControl.Invalidate(); $Form.Refresh()
}

# Panel Gradient Paint
$PaintPanel = {
    param($s, $e)
    $T = $Global:CurrentTheme
    $Rect = $s.ClientRectangle
    $Br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($Rect, $T.BgPanel, [System.Drawing.Color]::FromArgb(20,20,22), 90)
    $e.Graphics.FillRectangle($Br, $Rect)
    $Pen = New-Object System.Drawing.Pen($T.BorderColor, 1)
    $e.Graphics.DrawRectangle($Pen, 0, 0, $s.Width-1, $s.Height-1)
    $Br.Dispose(); $Pen.Dispose()
}

# Button Generator (Glass/Glow Effect)
function Add-CyberBtn ($Parent, $Txt, $Icon, $X, $Y, $W, $Tag, $ColorType="Normal") {
    $Btn = New-Object System.Windows.Forms.Label 
    $Btn.Text = "$Icon  $Txt"
    $Btn.Tag = @{ Act=$Tag; Hover=$false; Type=$ColorType }
    $Btn.Location = "$X, $Y"; $Btn.Size = "$W, 45"
    $Btn.Font = $F_Btn; $Btn.TextAlign = "MiddleCenter"
    $Btn.ForeColor = [System.Drawing.Color]::White; $Btn.Cursor = "Hand"
    
    $Btn.Add_MouseEnter({ $this.Tag.Hover=$true; $this.Invalidate() })
    $Btn.Add_MouseLeave({ $this.Tag.Hover=$false; $this.Invalidate() })
    $Btn.Add_Click({ Run-Action $this.Tag.Act })
    
    $Btn.Add_Paint({
        param($s, $e)
        $R = $s.ClientRectangle
        $T = $Global:CurrentTheme
        
        # Color Logic
        switch ($s.Tag.Type) {
            "Danger" { $C1=$T.Red; $C2=[System.Windows.Forms.ControlPaint]::Light($T.Red); $Border=$T.Red }
            "Rescue" { $C1=$T.Orange; $C2=[System.Windows.Forms.ControlPaint]::Light($T.Orange); $Border=$T.Orange }
            "Monitor"{ $C1=$T.Green; $C2=[System.Windows.Forms.ControlPaint]::Light($T.Green); $Border=$T.Green }
            "Primary"{ $C1=$T.Cyan; $C2=[System.Windows.Forms.ControlPaint]::Light($T.Cyan); $Border=$T.Cyan }
            Default  { $C1=$T.BtnBase; $C2=$T.BtnHigh; $Border=$T.TextMuted }
        }
        
        # Adjust C1, C2 for Gradient Base (Always a subtle color difference)
        $BtnC1 = $T.BtnBase; $BtnC2 = $T.BtnHigh
        if($s.Tag.Hover){ $BtnC1=[System.Windows.Forms.ControlPaint]::Light($T.BtnBase); $BtnC2=[System.Windows.Forms.ControlPaint]::Light($T.BtnHigh) }
        
        $Br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($R, $BtnC1, $BtnC2, 45)
        $e.Graphics.FillRectangle($Br, $R)
        
        # Neon/Glow Border (Based on ColorType)
        $Pen = New-Object System.Drawing.Pen($Border, 2)
        $e.Graphics.DrawRectangle($Pen, 0, 0, $s.Width-1, $s.Height-1)
        
        # Glass Shine Effect (White/TextMain depending on mode)
        $RTop = $R; $RTop.Height = $R.Height / 2
        $ShineColor = if($T.Name -match "Dark"){ [System.Drawing.Color]::FromArgb(20, 255, 255, 255) } else { [System.Drawing.Color]::FromArgb(10, 0, 0, 0) }
        $BrGlass = New-Object System.Drawing.SolidBrush($ShineColor)
        $e.Graphics.FillRectangle($BrGlass, $RTop)
        
        # Text
        $TextColor = if($s.Tag.Hover){ $Border } else { $T.TextMain }
        $Sf = New-Object System.Drawing.StringFormat; $Sf.Alignment="Center"; $Sf.LineAlignment="Center"
        $RectF = New-Object System.Drawing.RectangleF(0, 0, $s.Width, $s.Height)
        $e.Graphics.DrawString($s.Text, $s.Font, (New-Object System.Drawing.SolidBrush($TextColor)), $RectF, $Sf)
        
        $Br.Dispose(); $Pen.Dispose(); $BrGlass.Dispose()
    })
    $Parent.Controls.Add($Btn)
}

# --- THEME SWITCH LOGIC ---
function Toggle-Theme {
    if ($Global:CurrentTheme.Name -match "Dark") {
        $Global:CurrentTheme = $Theme_Light
        $BtnThemeSwitch.Text = "🌙 CHUYỂN DARK MODE"
    } else {
        $Global:CurrentTheme = $Theme_Dark
        $BtnThemeSwitch.Text = "☀️ CHUYỂN LIGHT MODE"
    }
    Apply-Theme
    $Form.Controls | ForEach-Object { $_.Invalidate() }
}

# ==================== LAYOUT ====================

# HEADER
$PnlHead = New-Object System.Windows.Forms.Panel; $PnlHead.Dock="Top"; $PnlHead.Height=70; $PnlHead.BackColor=[System.Drawing.Color]::Transparent
$Form.Controls.Add($PnlHead)

$LblLogo = New-Object System.Windows.Forms.Label; $LblLogo.Text="TITANIUM DISK MANAGER V17"; $LblLogo.Font=$F_Logo; $LblLogo.AutoSize=$true; $LblLogo.Location="20,15"
$PnlHead.Controls.Add($LblLogo)
$LblSub = New-Object System.Windows.Forms.Label; $LblSub.Text="Công cụ Phân vùng & Cứu hộ Chuyên nghiệp"; $LblSub.Font=$F_Norm; $LblSub.AutoSize=$true; $LblSub.Location="420,28"
$PnlHead.Controls.Add($LblSub)

# Theme Info Label
$LblTheme = New-Object System.Windows.Forms.Label; $LblTheme.Font=$F_Norm; $LblTheme.AutoSize=$true; $LblTheme.Location="960,18"
$PnlHead.Controls.Add($LblTheme)

# Theme Switch Button
$BtnThemeSwitch = New-Object System.Windows.Forms.Button; $BtnThemeSwitch.Text="☀️ CHUYỂN LIGHT MODE"
$BtnThemeSwitch.Size="250,30"; $BtnThemeSwitch.Location="960,40"; $BtnThemeSwitch.FlatStyle="Flat"
$BtnThemeSwitch.BackColor=[System.Drawing.Color]::DarkGray; $BtnThemeSwitch.ForeColor=[System.Drawing.Color]::White; $BtnThemeSwitch.Font=$F_Btn
$BtnThemeSwitch.Add_Click({ Toggle-Theme })
$PnlHead.Controls.Add($BtnThemeSwitch)

# 1. DISK LIST
$PnlDisk = New-Object System.Windows.Forms.Panel; $PnlDisk.Location="20,80"; $PnlDisk.Size="1225,200"; $PnlDisk.Add_Paint($PaintPanel)
$Form.Controls.Add($PnlDisk)
$Lbl1 = New-Object System.Windows.Forms.Label; $Lbl1.Text="1. DANH SÁCH Ổ CỨNG VẬT LÝ (PHYSICAL DISKS)"; $Lbl1.Location="15,10"; $Lbl1.AutoSize=$true; $Lbl1.Font=$F_Head; $Lbl1.BackColor=[System.Drawing.Color]::Transparent; $PnlDisk.Controls.Add($Lbl1)

$GridD = New-Object System.Windows.Forms.DataGridView; $GridD.Location="15,40"; $GridD.Size="1195,145"; $GridD.BorderStyle="None"
$GridD.AllowUserToAddRows=$false; $GridD.RowHeadersVisible=$false; $GridD.SelectionMode="FullRowSelect"; $GridD.MultiSelect=$false; $GridD.ReadOnly=$true; $GridD.AutoSizeColumnsMode="Fill"
# EXTENDED DISK COLUMNS
$GridD.Columns.Add("ID","Disk #"); $GridD.Columns[0].Width=40
$GridD.Columns.Add("Mod","Tên Model"); $GridD.Columns[1].FillWeight=150
$GridD.Columns.Add("PartStyle","Chuẩn"); $GridD.Columns[2].Width=60
$GridD.Columns.Add("Bus","Giao tiếp"); $GridD.Columns[3].Width=70
$GridD.Columns.Add("Size","Dung lượng"); $GridD.Columns[4].Width=90
$GridD.Columns.Add("PCount","Phân vùng"); $GridD.Columns[5].Width=70
$GridD.Columns.Add("Health","Sức khỏe"); $GridD.Columns[6].Width=70
$GridD.Columns.Add("Speed","Tốc độ (IOPS)"); $GridD.Columns[7].Width=90
$GridD.Columns.Add("Temp","Nhiệt độ (C)"); $GridD.Columns[8].Width=80
$PnlDisk.Controls.Add($GridD)

# 2. PARTITION LIST
$PnlPart = New-Object System.Windows.Forms.Panel; $PnlPart.Location="20,290"; $PnlPart.Size="1225,200"; $PnlPart.Add_Paint($PaintPanel)
$Form.Controls.Add($PnlPart)
$Lbl2 = New-Object System.Windows.Forms.Label; $Lbl2.Text="2. PHÂN VÙNG (PARTITIONS)"; $Lbl2.Location="15,10"; $Lbl2.AutoSize=$true; $Lbl2.Font=$F_Head; $Lbl2.BackColor=[System.Drawing.Color]::Transparent; $PnlPart.Controls.Add($Lbl2)

$GridP = New-Object System.Windows.Forms.DataGridView; $GridP.Location="15,40"; $GridP.Size="1195,145"; $GridP.BorderStyle="None"
$GridP.AllowUserToAddRows=$false; $GridP.RowHeadersVisible=$false; $GridP.SelectionMode="FullRowSelect"; $GridP.MultiSelect=$false; $GridP.ReadOnly=$true; $GridP.AutoSizeColumnsMode="Fill"
# EXTENDED PARTITION COLUMNS
$GridP.Columns.Add("Let","Ký tự"); $GridP.Columns[0].Width=50
$GridP.Columns.Add("Lab","Tên/Nhãn (Label)"); $GridP.Columns[1].FillWeight=100
$GridP.Columns.Add("FS","Hệ thống File"); $GridP.Columns[2].Width=70
$GridP.Columns.Add("Tot","Tổng (GB)"); $GridP.Columns[3].Width=70
$GridP.Columns.Add("Used","Đã dùng (GB)"); $GridP.Columns[4].Width=90
$GridP.Columns.Add("Free","Còn trống (GB)"); $GridP.Columns[5].Width=90
$GridP.Columns.Add("PUse","% Dùng"); $GridP.Columns[6].Width=60
$GridP.Columns.Add("Type","Kiểu GPT"); $GridP.Columns[7].Width=90
$GridP.Columns.Add("PIndex","P.ID"); $GridP.Columns[8].Width=50
$GridP.Columns.Add("Stat","Trạng thái"); $GridP.Columns[9].Width=70
$PnlPart.Controls.Add($GridP)

# 3. ACTION TABS
$TabControl = New-Object System.Windows.Forms.TabControl; $TabControl.Location="20,500"; $TabControl.Size="1225,300"; $TabControl.Font=$F_Head
$Form.Controls.Add($TabControl)

function Add-Page ($Title, $BG) { $p=New-Object System.Windows.Forms.TabPage; $p.Text="  $Title  "; $p.BackColor=$BG; $p.ForeColor=$Global:CurrentTheme.TextMain; $TabControl.Controls.Add($p); return $p }

# --- TAB 1: BASIC ---
$TabBasic = Add-Page "🛠️ QUẢN LÝ CƠ BẢN" $Global:CurrentTheme.BgPanel
Add-CyberBtn $TabBasic "LÀM MỚI (REFRESH)" "♻️" 30 30 200 "Refresh" "Primary"
Add-CyberBtn $TabBasic "KIỂM TRA Ổ ĐĨA (CHKDSK)" "🚑" 250 30 200 "ChkDsk"
Add-CyberBtn $TabBasic "ĐỔI TÊN/NHÃN (LABEL)" "🏷️" 470 30 200 "Label"
Add-CyberBtn $TabBasic "ĐỔI KÝ TỰ (LETTER)" "🔠" 690 30 200 "Letter"

Add-CyberBtn $TabBasic "FORMAT PHÂN VÙNG" "🧹" 30 100 200 "Format" "Danger"
Add-CyberBtn $TabBasic "XÓA PHÂN VÙNG" "❌" 250 100 200 "Delete" "Danger"
Add-CyberBtn $TabBasic "WIPE DATA (GHI ĐÈ ZERO)" "💀" 470 100 200 "Wipe" "Danger"
Add-CyberBtn $TabBasic "THIẾT LẬP ACTIVE (MBR)" "⚡" 690 100 200 "Active"

# --- TAB 2: RESCUE ---
$TabRescue = Add-Page "🚑 CỨU HỘ & NÂNG CAO" $Global:CurrentTheme.BgPanel
Add-CyberBtn $TabRescue "FIX BOOT (TỰ ĐỘNG BCD)" "🛠️" 30 30 250 "FixBoot" "Rescue"
Add-CyberBtn $TabRescue "HIỆN Ổ ẨN / EFI (MOUNT)" "🔓" 300 30 250 "MountEFI" "Rescue"
Add-CyberBtn $TabRescue "GỠ WRITE PROTECT (USB/ĐĨA)" "🖊️" 570 30 250 "RemoveRO" "Rescue"
Add-CyberBtn $TabRescue "CHUYỂN GPT (MẤT DỮ LIỆU)" "🔄" 840 30 250 "ConvertGPT" "Danger"

Add-CyberBtn $TabRescue "TEST BỀ MẶT (BAD SECTOR)" "🔍" 30 100 250 "Surface" "Monitor"
Add-CyberBtn $TabRescue "REBUILD MBR" "🧱" 300 100 250 "RebuildMBR" "Rescue"
Add-CyberBtn $TabRescue "TẠO PHÂN VÙNG MỚI" "➕" 570 100 250 "CreatePart" "Primary"

# --- TAB 3: MONITORING ---
$TabMon = Add-Page "📊 SỨC KHỎE & TỐC ĐỘ" $Global:CurrentTheme.BgPanel
Add-CyberBtn $TabMon "XEM CHI TIẾT S.M.A.R.T" "📋" 30 30 250 "SmartDetail" "Monitor"
Add-CyberBtn $TabMon "KIỂM TRA TỐC ĐỘ (BENCHMARK)" "🚀" 300 30 250 "Benchmark" "Monitor"
Add-CyberBtn $TabMon "OPTIMIZE / DEFRAG" "✨" 570 30 250 "Optimize" "Monitor"

$LblInfo = New-Object System.Windows.Forms.Label; $LblInfo.Text="THÔNG TIN: Chọn Phân vùng để thao tác. "; $LblInfo.Location="30, 200"; $LblInfo.AutoSize=$true; $TabMon.Controls.Add($LblInfo)

# ==================== LOGIC CORE ====================

function Load-Data {
    $GridD.Rows.Clear(); $GridP.Rows.Clear(); $Global:SelectedPart = $null; $Global:SelectedDisk = $null
    $Form.Cursor = "WaitCursor"; $Form.Refresh()
    
    $Engine = "Modern (Get-PhysicalDisk)"
    
    try {
        $PhyDisks = Get-PhysicalDisk -ErrorAction Stop | Sort-Object DeviceId
        if (!$PhyDisks) { throw "Empty" }
        
        foreach ($D in $PhyDisks) {
            $GB = [Math]::Round($D.Size / 1GB, 1).ToString() + " GB"
            $Type = if ($D.PartitionStyle -eq "Uninitialized") { "RAW" } else { $D.PartitionStyle }
            $PartCount = (Get-Partition -DiskNumber $D.DeviceId -ErrorAction SilentlyContinue).Count
            $Health = $D.HealthStatus.ToString()
            $Speed = if ($D.MediaType -eq "HDD") { "Slow" } else { "Fast" }
            $Temp = "N/A" # Cannot get temp reliably from PowerShell cmdlets
            
            $Row = $GridD.Rows.Add($D.DeviceId, $D.FriendlyName, $Type, $D.BusType, $GB, $PartCount, $Health, $Speed, $Temp)
            $GridD.Rows[$Row].Tag = @{ ID=$D.DeviceId; Mode="Modern"; Obj=$D }
            
            if ($Health -ne "Healthy") { $GridD.Rows[$Row].DefaultCellStyle.ForeColor = $Global:CurrentTheme.Red }
            else { $GridD.Rows[$Row].DefaultCellStyle.ForeColor = $Global:CurrentTheme.TextMain }
        }
    } catch {
        $Engine = "Legacy (WMI Fallback)"
        try {
            $WmiDisks = Get-WmiObject Win32_DiskDrive
            foreach ($D in $WmiDisks) {
                $GB = [Math]::Round($D.Size / 1GB, 1).ToString() + " GB"
                $PCount = $D.Partitions; $Type = if ($PCount -gt 4) { "GPT (Auto)" } else { "MBR/GPT" }
                
                $Row = $GridD.Rows.Add($D.Index, $D.Model, $Type, $D.InterfaceType, $GB, $PCount, "Unknown", "Unknown", "N/A")
                $GridD.Rows[$Row].Tag = @{ ID=$D.Index; Mode="WMI"; Obj=$D }
                $GridD.Rows[$Row].DefaultCellStyle.ForeColor = $Global:CurrentTheme.TextMain
            }
        } catch { [System.Windows.Forms.MessageBox]::Show("CRITICAL ERROR: Không tìm thấy ổ cứng nào!", "Lỗi") }
    }
    
    $Lbl1.Text = "1. DANH SÁCH Ổ CỨNG VẬT LÝ (Engine: $Engine)"
    if ($GridD.Rows.Count -gt 0) { $GridD.Rows[0].Selected = $true; Load-Partitions $GridD.Rows[0].Tag }
    $Form.Cursor = "Default"
}

function Load-Partitions ($Tag) {
    $GridP.Rows.Clear(); $Global:SelectedDisk = $Tag
    $Global:SelectedPart = $null
    $Did = $Tag.ID
    
    try {
        $Parts = Get-Partition -DiskNumber $Did -ErrorAction Stop | Sort-Object PartitionNumber
        foreach ($P in $Parts) {
            $Vol = $P | Get-Volume -ErrorAction SilentlyContinue
            
            $Let = if($P.DriveLetter){$P.DriveLetter + ":"}else{""}
            $Lab = if($Vol){$Vol.FileSystemLabel}else{"[Hidden/System]"}
            $FS  = if($Vol){$Vol.FileSystem}else{$P.Type}
            $Total = [Math]::Round($P.Size / 1GB, 2)
            
            $Used="-"; $PUse="-"; $Free="-"; $Stat="OK"
            if ($Vol) {
                $UsedVal = $Vol.Size - $Vol.SizeRemaining
                $Used = [Math]::Round($UsedVal / 1GB, 2)
                $Free = [Math]::Round($Vol.SizeRemaining / 1GB, 2)
                if ($Vol.Size -gt 0) { $PUse = ([Math]::Round(($UsedVal / $Vol.Size)*100)).ToString() + "%" }
            } else {
                if ($P.Type -eq "Basic") { $Stat = "Sys" }
                if ($P.Type -eq "Unknown") { $Stat = "RAW" }
            }
            
            $Row = $GridP.Rows.Add($Let, $Lab, $FS, "$Total GB", "$Used GB", "$Free GB", $PUse, $P.GptType, $P.PartitionNumber, $Stat)
            $GridP.Rows[$Row].Tag = @{ Did=$Did; PartID=$P.PartitionNumber; Let=$P.DriveLetter; Lab=$Lab; Obj=$P }
            $GridP.Rows[$Row].DefaultCellStyle.ForeColor = $Global:CurrentTheme.TextMain
        }
    } catch {
        # Legacy/WMI fallback partitions logic...
        try {
            $Query = "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='\\.\PHYSICALDRIVE$Did'} WHERE AssocClass=Win32_DiskDriveToDiskPartition"
            $Parts = @(Get-WmiObject -Query $Query | Sort-Object StartingOffset)
            $RealID = 1
            foreach ($P in $Parts) {
                $LogDisk = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($P.DeviceID)'} WHERE AssocClass=Win32_LogicalDiskToPartition"
                $Total = [Math]::Round($P.Size / 1GB, 2)
                $Let=""; $Lab="[Hidden]"; $FS="RAW"; $Used="-"; $Free="-"
                if ($LogDisk) {
                    $Let=$LogDisk.DeviceID; $Lab=$LogDisk.VolumeName; $FS=$LogDisk.FileSystem
                    $Used = [Math]::Round(($LogDisk.Size - $LogDisk.Freespace) / 1GB, 2).ToString() + " GB"
                    $Free = [Math]::Round($LogDisk.Freespace / 1GB, 2).ToString() + " GB"
                }
                $Row = $GridP.Rows.Add($Let, $Lab, $FS, "$Total GB", $Used, $Free, "-", $P.Type, $RealID, "OK (WMI)")
                $GridP.Rows[$Row].Tag = @{ Did=$Did; PartID=$RealID; Let=$Let.Replace(":",""); Lab=$Lab }
                $GridP.Rows[$Row].DefaultCellStyle.ForeColor = $Global:CurrentTheme.TextMain
                $RealID++
            }
        } catch {}
    }
}

# EVENTS
$GridD.Add_CellClick({ if($GridD.SelectedRows.Count -gt 0){ Load-Partitions $GridD.SelectedRows[0].Tag } })
$GridP.Add_CellClick({ if($GridP.SelectedRows.Count -gt 0){ $Global:SelectedPart = $GridP.SelectedRows[0].Tag; $LblInfo.Text="ĐÃ CHỌN: Phân vùng $($Global:SelectedPart.PartID) trên Ổ $($Global:SelectedPart.Did) - $($Global:SelectedPart.Lab)" } })

# ==================== ACTION LOGIC (VIỆT HÓA THÔNG BÁO) ====================

function Run-DP ($Cmd) {
    $F = "$env:TEMP\dp_script.txt"; [IO.File]::WriteAllText($F, $Cmd)
    Start-Process "diskpart" "/s `"$F`"" -Wait -NoNewWindow
    Remove-Item $F -ErrorAction SilentlyContinue; Load-Data
}

function Run-Action ($Act) {
    if ($Act -eq "Refresh") { Load-Data; return }
    
    $D = $Global:SelectedDisk
    $P = $Global:SelectedPart
    
    # DISK LEVEL
    if ($Act -eq "ConvertGPT") {
        if (!$D) { [System.Windows.Forms.MessageBox]::Show("Vui lòng chọn Ổ đĩa vật lý!", "Cảnh báo", "OK", "Warning"); return }
        if ([System.Windows.Forms.MessageBox]::Show("CHUYỂN Ổ $($D.ID) sang GPT? LỆNH CLEAN SẼ XÓA HẾT DỮ LIỆU!", "NGUY HIỂM", "YesNo", "Error") -eq "Yes") {
            Run-DP "sel disk $($D.ID)`nclean`nconvert gpt"
            [System.Windows.Forms.MessageBox]::Show("Đã chuyển Ổ $($D.ID) sang GPT và làm sạch.", "Thành công")
        }
        return
    }
    
    if ($Act -eq "RemoveRO") {
        if (!$D) { [System.Windows.Forms.MessageBox]::Show("Vui lòng chọn Ổ đĩa vật lý!", "Cảnh báo", "OK", "Warning"); return }
        Run-DP "sel disk $($D.ID)`nattributes disk clear readonly`nonline disk"
        [System.Windows.Forms.MessageBox]::Show("Đã gỡ chế độ chỉ đọc (Read-Only) khỏi Ổ $($D.ID)", "Thành công")
        return
    }

    if ($Act -eq "SmartDetail") {
        if (!$D) { [System.Windows.Forms.MessageBox]::Show("Vui lòng chọn Ổ đĩa vật lý!", "Cảnh báo", "OK", "Warning"); return }
        if ($D.Mode -eq "WMI") { [System.Windows.Forms.MessageBox]::Show("Chế độ WMI Legacy không hỗ trợ chi tiết SMART đầy đủ.", "Thông tin"); return }
        try {
            $Info = Get-PhysicalDisk -DeviceId $D.ID | Select *
            $Info | Out-GridView -Title "Chi tiết S.M.A.R.T cho Ổ $($D.ID)"
        } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi khi đọc SMART.", "Lỗi") }
        return
    }

    # PARTITION LEVEL
    if (!$P) { [System.Windows.Forms.MessageBox]::Show("Vui lòng chọn một Phân vùng ở bảng bên dưới!", "Cảnh báo", "OK", "Warning"); return }
    
    $Did = $P.Did; $TargetPartID = $P.PartID; $Let = $P.Let

    switch ($Act) {
        "Format" {
            $Lab = [Microsoft.VisualBasic.Interaction]::InputBox("Nhãn mới:", "Định dạng (Format) Phân vùng", "NewVolume")
            if ($Lab) { 
                if([System.Windows.Forms.MessageBox]::Show("Định dạng (Format) Phân vùng $TargetPartID? Dữ liệu sẽ MẤT!", "Xác nhận", "YesNo", "Warning") -eq "Yes") {
                    Run-DP "sel disk $Did`nsel part $TargetPartID`nformat fs=ntfs label=`"$Lab`" quick" 
                }
            }
        }
        "Wipe" {
            if([System.Windows.Forms.MessageBox]::Show("XÓA SẠCH DỮ LIỆU (ZERO-FILL)?`nKHÔNG THỂ PHỤC HỒI!", "NGUY HIỂM", "YesNo", "Error") -eq "Yes") {
                $Form.Cursor = "WaitCursor"
                if ($Let) { Format-Volume -DriveLetter $Let -FileSystem NTFS -Full -Force | Out-Null }
                else { [System.Windows.Forms.MessageBox]::Show("Phân vùng cần có Ký tự Ổ đĩa để thực hiện Wipe.", "Thông tin") }
                $Form.Cursor = "Default"
                [System.Windows.Forms.MessageBox]::Show("Wipe hoàn tất!", "Hoàn thành")
            }
        }
        "Delete" {
            if([System.Windows.Forms.MessageBox]::Show("Xóa Phân vùng $TargetPartID?", "Xác nhận", "YesNo", "Error") -eq "Yes") {
                Run-DP "sel disk $Did`nsel part $TargetPartID`ndelete partition override"
                [System.Windows.Forms.MessageBox]::Show("Đã xóa Phân vùng $TargetPartID.", "Thành công")
            }
        }
        "Label" {
            if(!$Let) { [System.Windows.Forms.MessageBox]::Show("Phân vùng này không có Ký tự Ổ đĩa để đổi Nhãn.", "Thông tin"); return }
            $N=[Microsoft.VisualBasic.Interaction]::InputBox("Tên mới (Label):", "Đổi Tên/Nhãn", $P.Lab)
            if ($N) { Set-Volume -DriveLetter $Let -NewFileSystemLabel $N; Load-Data; [System.Windows.Forms.MessageBox]::Show("Đã đổi Nhãn.", "Thành công") }
        }
        "Letter" {
            $NewL=[Microsoft.VisualBasic.Interaction]::InputBox("Ký tự mới (ví dụ: Z):", "Đổi Ký tự Ổ đĩa", "")
            if ($NewL -match "^[A-Z]$") { 
                Run-DP "sel disk $Did`nsel part $TargetPartID`nassign letter=$NewL" 
                [System.Windows.Forms.MessageBox]::Show("Đã đổi Ký tự Ổ đĩa thành $NewL:", "Thành công")
            } else { [System.Windows.Forms.MessageBox]::Show("Ký tự không hợp lệ. Vui lòng nhập một chữ cái (A-Z).", "Lỗi") }
        }
        "Active" { Run-DP "sel disk $Did`nsel part $TargetPartID`nactive"; [System.Windows.Forms.MessageBox]::Show("Đã thiết lập Phân vùng $TargetPartID là Active.", "Thành công") }
        "ChkDsk" { if($Let){ Start-Process "cmd" "/k chkdsk $Let /f /x" } else { [System.Windows.Forms.MessageBox]::Show("Cần có Ký tự Ổ đĩa để chạy CHKDSK!", "Lỗi") } }
        "Surface" { 
            if($Let){ Start-Process "cmd" "/k title SURFACE TEST & echo DANG QUET BAD SECTORS TRÊN $Let ... & chkdsk $Let /r" } 
            else { [System.Windows.Forms.MessageBox]::Show("Cần có Ký tự Ổ đĩa để chạy Surface Test!", "Lỗi") }
        }
        "FixBoot" {
            if($Let) {
                Start-Process "cmd" "/k bcdboot $Let\Windows /s $Let /f ALL & echo BOOT ĐÃ ĐƯỢC SỬA! & pause"
            } else { [System.Windows.Forms.MessageBox]::Show("Chọn Phân vùng chứa Windows (thường là C:) để sửa lỗi Boot!", "Thông tin") }
        }
        "MountEFI" {
            $EfiPart = Get-Partition -DiskNumber $Did | Where-Object { $_.GptType -eq "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" -or $_.Type -eq "System" }
            if ($EfiPart) {
                Set-Partition -DiskNumber $Did -PartitionNumber $EfiPart.PartitionNumber -NewDriveLetter "Z" -ErrorAction SilentlyContinue
                [System.Windows.Forms.MessageBox]::Show("Phân vùng EFI đã được Mount thành Z:", "Thành công")
                Load-Data
            } else { [System.Windows.Forms.MessageBox]::Show("Không tìm thấy Phân vùng EFI trên Ổ $Did", "Lỗi") }
        }
        "Benchmark" {
            if ($Let) {
                $Form.Cursor = "WaitCursor"
                Start-Process "winsat" -ArgumentList "disk -drive $Let -ran -read -count 1" -Wait
                $Form.Cursor = "Default"
                [System.Windows.Forms.MessageBox]::Show("Đo tốc độ hoàn tất! Kiểm tra kết quả trong cửa sổ CMD.", "Thông tin")
            } else { [System.Windows.Forms.MessageBox]::Show("Chọn Phân vùng có Ký tự Ổ đĩa để đo tốc độ!", "Lỗi") }
        }
        "Optimize" {
            if ($Let) {
                $Form.Cursor = "WaitCursor"
                Optimize-Volume -DriveLetter $Let -ReTrim -Verbose
                $Form.Cursor = "Default"
                [System.Windows.Forms.MessageBox]::Show("Tối ưu hóa / TRIM đã hoàn tất!", "Thành công")
            } else { [System.Windows.Forms.MessageBox]::Show("Chọn Phân vùng có Ký tự Ổ đĩa để Tối ưu hóa!", "Lỗi") }
        }
        "CreatePart" {
            # This requires selecting a block of Unallocated Space, which is complex for this GUI
            [System.Windows.Forms.MessageBox]::Show("Chức năng này cần chọn Vùng Trống (Unallocated Space). Vui lòng dùng Diskpart thủ công hoặc công cụ chuyên dụng hơn.", "Thông tin")
        }
        "RebuildMBR" {
            if ([System.Windows.Forms.MessageBox]::Show("Xây dựng lại MBR cho Ổ $($D.ID)? Chỉ dùng cho chuẩn MBR!", "Cảnh báo", "YesNo", "Warning") -eq "Yes") {
                Run-DP "sel disk $($D.ID)`ncreate partition primary`nformat fs=ntfs quick`nactive`nexit"
                [System.Windows.Forms.MessageBox]::Show("Đã cố gắng xây dựng lại MBR (Tạo Phân vùng Primary).", "Thành công")
            }
        }
    }
}

# --- INIT ---
Apply-Theme # Apply default Dark Theme
$Timer = New-Object System.Windows.Forms.Timer; $Timer.Interval=500; $Timer.Add_Tick({$Timer.Stop(); Load-Data}); $Timer.Start()
$Form.ShowDialog() | Out-Null

} catch {
    Write-Host "Lỗi Nghiêm Trọng: $($_.Exception.Message)" -ForegroundColor Red; Read-Host
}
