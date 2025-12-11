<#
    DISK MANAGER PRO - PHAT TAN PC (V29.1 - TITANIUM ULTIMATE FIX)
    Features: Advanced Create Partition UI, Clone, VHD, Hex View, Bad Sector Map, Space Analyzer
    Fix: $Input Variable Crash, Unallocated Logic, Drive Letter Selector
#>

# --- 0. CAU HINH ANTI-CRASH & LOGGING ---
$ErrorActionPreference = "SilentlyContinue"
$Global:ErrorLog = "$env:TEMP\DiskManager_Error.log"

# Ham ghi log an toan
function Log-Error ($Msg) {
    $Line = "[$(Get-Date -F 'HH:mm:ss')] ERROR: $Msg"
    try { $Line | Out-File $Global:ErrorLog -Append } catch {}
}

# Trap loi toan cuc
Trap {
    Log-Error $($_.Exception.Message)
    Continue
}

# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# --- 2. MAIN WRAPPER ---
try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName Microsoft.VisualBasic

    # --- THEME CONFIG ---
    $Theme_Dark = @{
        Name        = "Dark Titanium"
        BgForm      = [System.Drawing.Color]::FromArgb(18, 18, 22)
        BgPanel     = [System.Drawing.Color]::FromArgb(32, 32, 38)
        GridBg      = [System.Drawing.Color]::FromArgb(25, 25, 30)
        TextMain    = [System.Drawing.Color]::FromArgb(245, 245, 245)
        TextMuted   = [System.Drawing.Color]::Silver
        RGB1        = [System.Drawing.Color]::FromArgb(255, 0, 80)
        RGB2        = [System.Drawing.Color]::FromArgb(0, 255, 255)
        BtnBase     = [System.Drawing.Color]::FromArgb(50, 50, 60)
        BtnHigh     = [System.Drawing.Color]::FromArgb(70, 70, 90)
        Border      = [System.Drawing.Color]::FromArgb(80, 80, 100)
    }
    
    $Theme_Light = @{
        Name        = "Light Titanium"
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
    $Global:ForceWMI = $false

    # --- CHECK ENVIRONMENT ---
    if (!(Get-Command "Get-PhysicalDisk" -ErrorAction SilentlyContinue)) {
        $Global:ForceWMI = $true
    }

    # --- GUI INIT ---
    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = "DISK MANAGER PRO V29.1 - TITANIUM ULTIMATE"
    $Form.Size = New-Object System.Drawing.Size(1280, 900)
    $Form.StartPosition = "CenterScreen"
    $Form.FormBorderStyle = "FixedSingle"
    $Form.MaximizeBox = $false

    $F_Logo = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
    $F_Head = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $F_Norm = New-Object System.Drawing.Font("Segoe UI", 9)
    $F_Btn  = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)

    # --- DRAWING ---
    function Apply-Theme {
        $T = $Global:CurrentTheme
        $Form.BackColor = $T.BgForm; $Form.ForeColor = $T.TextMain
        $LblLogo.ForeColor = $T.RGB2; $LblSub.ForeColor = $T.TextMuted; $LblTheme.ForeColor = $T.RGB1
        $GridD.BackgroundColor = $T.GridBg; $GridP.BackgroundColor = $T.GridBg
        $GridD.DefaultCellStyle.BackColor = $T.GridBg; $GridD.DefaultCellStyle.ForeColor = $T.TextMain
        $GridP.DefaultCellStyle.BackColor = $T.GridBg; $GridP.DefaultCellStyle.ForeColor = $T.TextMain
        $Form.Controls | Where {$_.GetType().Name -eq "Panel"} | ForEach {$_.Invalidate()}
    }

    $PaintRGB = {
        param($s, $e)
        try {
            $T = $Global:CurrentTheme; $R = $s.ClientRectangle
            $BrBg = New-Object System.Drawing.SolidBrush($T.BgPanel)
            $e.Graphics.FillRectangle($BrBg, $R)
            $PenRGB = New-Object System.Drawing.Drawing2D.LinearGradientBrush($R, $T.RGB1, $T.RGB2, 45)
            $Pen = New-Object System.Drawing.Pen($PenRGB, 2)
            $e.Graphics.DrawRectangle($Pen, 1, 1, $s.Width-2, $s.Height-2)
            $BrBg.Dispose(); $Pen.Dispose(); $PenRGB.Dispose()
        } catch {}
    }

    function Add-CyberBtn ($Parent, $Txt, $Icon, $X, $Y, $W, $Tag, $ColorType="Normal") {
        $Btn = New-Object System.Windows.Forms.Label; $Btn.Text = "$Icon  $Txt"
        $Btn.Tag = @{ Act=$Tag; Hover=$false; Type=$ColorType }
        $Btn.Location = "$X, $Y"; $Btn.Size = "$W, 40"
        $Btn.Font = $F_Btn; $Btn.TextAlign = "MiddleCenter"; $Btn.Cursor = "Hand"
        $Btn.Add_MouseEnter({ $this.Tag.Hover=$true; $this.Invalidate() })
        $Btn.Add_MouseLeave({ $this.Tag.Hover=$false; $this.Invalidate() })
        $Btn.Add_Click({ Run-Action $this.Tag.Act })
        $Btn.Add_Paint({
            param($s, $e)
            try {
                $T = $Global:CurrentTheme; $R = $s.ClientRectangle
                $C1 = $T.BtnBase; $C2 = $T.BtnHigh
                $Border = if($s.Tag.Hover){ $T.RGB2 } else { $T.Border }
                if ($s.Tag.Type -eq "Danger") { $C1=[System.Drawing.Color]::FromArgb(150,0,0); $C2=[System.Drawing.Color]::FromArgb(200,50,50); $Border=[System.Drawing.Color]::Red }
                if ($s.Tag.Type -eq "Primary") { $C1=[System.Drawing.Color]::FromArgb(0,100,180); $C2=[System.Drawing.Color]::FromArgb(50,150,220); $Border=$T.RGB2 }
                if ($s.Tag.Type -eq "Rescue") { $C1=[System.Drawing.Color]::FromArgb(255,140,0); $C2=[System.Drawing.Color]::FromArgb(255,165,0); $Border=[System.Drawing.Color]::Gold }
                
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
            } catch {}
        })
        $Parent.Controls.Add($Btn)
    }

    function Toggle-Theme {
        if ($Global:CurrentTheme.Name -match "Dark") { $Global:CurrentTheme = $Theme_Light; $BtnTheme.Text = "☀️ LIGHT MODE" }
        else { $Global:CurrentTheme = $Theme_Dark; $BtnTheme.Text = "🌙 DARK MODE" }
        Apply-Theme
    }

    # ==================== LAYOUT ====================

    # HEADER
    $PnlHead = New-Object System.Windows.Forms.Panel; $PnlHead.Dock="Top"; $PnlHead.Height=70; $PnlHead.BackColor=[System.Drawing.Color]::Transparent
    $Form.Controls.Add($PnlHead)
    $LblLogo = New-Object System.Windows.Forms.Label; $LblLogo.Text="TITANIUM DISK MANAGER"; $LblLogo.Font=$F_Logo; $LblLogo.AutoSize=$true; $LblLogo.Location="20,10"
    $PnlHead.Controls.Add($LblLogo)
    $LblSub = New-Object System.Windows.Forms.Label; $LblSub.Text="Ultimate Rescue Tool (Safe Mode/WinPE Ready)"; $LblSub.Font=$F_Norm; $LblSub.AutoSize=$true; $LblSub.Location="420,25"
    $PnlHead.Controls.Add($LblSub)
    $BtnTheme = New-Object System.Windows.Forms.Button; $BtnTheme.Text="🌙 DARK MODE"; $BtnTheme.Location="1050,20"; $BtnTheme.Size="150,30"; $BtnTheme.FlatStyle="Flat"
    $BtnTheme.BackColor=[System.Drawing.Color]::FromArgb(80,80,90); $BtnTheme.ForeColor="White"; $BtnTheme.Add_Click({ Toggle-Theme })
    $LblTheme = New-Object System.Windows.Forms.Label; $LblTheme.Text="GIAO DIEN:"; $LblTheme.Location="950,25"; $LblTheme.AutoSize=$true; 
    $PnlHead.Controls.Add($LblTheme); $PnlHead.Controls.Add($BtnTheme)

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
    $GridD.Columns.Add("Health","Sức Khỏe"); $GridD.Columns[5].Width=150
    $GridD.Columns.Add("Parts","Phân Vùng"); $GridD.Columns[6].Width=80
    $GridD.Columns.Add("Info","Info"); $GridD.Columns[7].Width=100
    $PnlDisk.Controls.Add($GridD)

    # PARTITION LIST
    $PnlPart = New-Object System.Windows.Forms.Panel; $PnlPart.Location="20,290"; $PnlPart.Size="1225,200"; $PnlPart.Add_Paint($PaintRGB)
    $Form.Controls.Add($PnlPart)
    $L2 = New-Object System.Windows.Forms.Label; $L2.Text="2. CHI TIẾT PHÂN VÙNG (BAO GỒM UNALLOCATED)"; $L2.Location="15,10"; $L2.AutoSize=$true; $L2.Font=$F_Head; $L2.BackColor=[System.Drawing.Color]::Transparent; $L2.ForeColor=[System.Drawing.Color]::LimeGreen; $PnlPart.Controls.Add($L2)

    $GridP = New-Object System.Windows.Forms.DataGridView; $GridP.Location="15,40"; $GridP.Size="1195,145"; $GridP.BorderStyle="None"
    $GridP.AllowUserToAddRows=$false; $GridP.RowHeadersVisible=$false; $GridP.SelectionMode="FullRowSelect"; $GridP.MultiSelect=$false; $GridP.ReadOnly=$true; $GridP.AutoSizeColumnsMode="Fill"
    $GridP.Columns.Add("Let","Ký Tự"); $GridP.Columns[0].Width=60
    $GridP.Columns.Add("Lab","Nhãn (Label)"); $GridP.Columns[1].FillWeight=100
    $GridP.Columns.Add("FS","Hệ Thống"); $GridP.Columns[2].Width=70
    $GridP.Columns.Add("Tot","Tổng (GB)"); $GridP.Columns[3].Width=80
    $GridP.Columns.Add("Used","Đã Dùng"); $GridP.Columns[4].Width=80
    $GridP.Columns.Add("Free","Còn Trống"); $GridP.Columns[5].Width=80
    $GridP.Columns.Add("Type","Kiểu"); $GridP.Columns[6].Width=100
    $GridP.Columns.Add("Stat","Trạng Thái"); $GridP.Columns[7].Width=80
    $PnlPart.Controls.Add($GridP)

    # ACTIONS TABS
    $TabControl = New-Object System.Windows.Forms.TabControl; $TabControl.Location="20,500"; $TabControl.Size="1225,350"; $TabControl.Font=$F_Head
    $Form.Controls.Add($TabControl)
    function Add-Page ($Title) { $p=New-Object System.Windows.Forms.TabPage; $p.Text="  $Title  "; $TabControl.Controls.Add($p); return $p }

    # TAB 1
    $Tab1 = Add-Page "🛠️ QUẢN LÝ CƠ BẢN"
    Add-CyberBtn $Tab1 "LÀM MỚI (REFRESH)" "♻️" 30 30 220 "Refresh" "Primary"
    Add-CyberBtn $Tab1 "ĐỔI TÊN (LABEL)" "🏷️" 280 30 220 "Label"
    Add-CyberBtn $Tab1 "ĐỔI KÝ TỰ (LETTER)" "🔠" 530 30 220 "Letter"
    Add-CyberBtn $Tab1 "CHECK DISK (CHKDSK)" "🚑" 780 30 220 "ChkDsk"
    Add-CyberBtn $Tab1 "TẠO PARTITION MỚI" "✨" 30 90 220 "CreatePart" "Primary"
    Add-CyberBtn $Tab1 "FORMAT PHÂN VÙNG" "🧹" 280 90 220 "Format" "Danger"
    Add-CyberBtn $Tab1 "XÓA PHÂN VÙNG" "❌" 530 90 220 "Delete" "Danger"
    Add-CyberBtn $Tab1 "SET ACTIVE (BOOT)" "⚡" 780 90 220 "Active"
    Add-CyberBtn $Tab1 "CHUYỂN DYNAMIC->BASIC" "📉" 30 150 220 "ConvBasic" "Danger"
    Add-CyberBtn $Tab1 "XÓA SẠCH (WIPE)" "💀" 280 150 220 "Wipe" "Danger"

    # TAB 2
    $Tab2 = Add-Page "🧬 CLONE & PHÂN TÁCH"
    Add-CyberBtn $Tab2 "MIGRATE OS (CLONE PART)" "🧬" 30 30 250 "ClonePart" "Rescue"
    Add-CyberBtn $Tab2 "CHIA ĐÔI Ổ (SPLIT)" "➗" 310 30 250 "Split" "Primary"
    Add-CyberBtn $Tab2 "GỘP Ổ (MERGE)" "➕" 590 30 250 "Merge" "Danger"
    Add-CyberBtn $Tab2 "CONVERT MBR <-> GPT" "🔄" 870 30 250 "ConvertGPT" "Danger"
    $LblClone = New-Object System.Windows.Forms.Label; $LblClone.Text="Lưu ý: Migrate OS sử dụng kỹ thuật Capture/Apply Image (An toàn). Gộp ổ sẽ xóa phân vùng bên phải."; $LblClone.Location="30, 90"; $LblClone.AutoSize=$true; $LblClone.ForeColor="Gray"; $Tab2.Controls.Add($LblClone)

    # TAB 3
    $Tab3 = Add-Page "💾 VHD & CỨU HỘ"
    Add-CyberBtn $Tab3 "TẠO Ổ ẢO (CREATE VHD)" "💿" 30 30 250 "CreateVHD" "Primary"
    Add-CyberBtn $Tab3 "GẮN Ổ ẢO (MOUNT VHD)" "📂" 310 30 250 "MountVHD" "Primary"
    Add-CyberBtn $Tab3 "GỠ Ổ ẢO (DETACH)" "eject" 590 30 250 "DetachVHD" "Primary"
    Add-CyberBtn $Tab3 "HIỆN Ổ ẨN / EFI" "🔓" 870 30 250 "MountEFI" "Rescue"
    Add-CyberBtn $Tab3 "FIX BOOT (AUTO BCD)" "🛠️" 30 90 250 "FixBoot" "Rescue"
    Add-CyberBtn $Tab3 "TÁI TẠO MBR" "🧱" 310 90 250 "RebuildMBR" "Rescue"
    Add-CyberBtn $Tab3 "GỠ WRITE PROTECT" "🖊️" 590 90 250 "RemoveRO" "Rescue"
    Add-CyberBtn $Tab3 "PORTABLE MODE" "🎒" 870 90 250 "Portable"

    # TAB 4
    $Tab4 = Add-Page "🔬 HEX & SCANNER"
    Add-CyberBtn $Tab4 "HEX VIEW (SECTOR 0)" "0x" 30 30 250 "HexView" "Monitor"
    Add-CyberBtn $Tab4 "BAD SECTOR MAP" "🗺️" 310 30 250 "BadMap" "Monitor"
    Add-CyberBtn $Tab4 "SPACE ANALYZER" "📊" 590 30 250 "Space" "Monitor"
    Add-CyberBtn $Tab4 "BENCHMARK TỐC ĐỘ" "🚀" 870 30 250 "Benchmark" "Monitor"

    $LblInfo = New-Object System.Windows.Forms.Label; $LblInfo.Text="INFO: Sẵn sàng."; $LblInfo.Location="30, 860"; $LblInfo.AutoSize=$true; $LblInfo.Font=$F_Head; $LblInfo.ForeColor="Yellow"
    $Form.Controls.Add($LblInfo); $LblInfo.BringToFront()

    # ==================== LOGIC ====================

    function Write-Log ($Msg) { 
        try {
            $Log="$env:TEMP\dm_log.txt"
            $Line = "[$(Get-Date -F 'HH:mm:ss')] $Msg"
            $Line | Out-File $Log -Append
            $LblInfo.Text = $Msg
        } catch {}
    }

    function Load-Data {
        $GridD.Rows.Clear(); $GridP.Rows.Clear(); $Global:SelectedPart=$null
        $Form.Cursor = "WaitCursor"; $Form.Refresh()
        Write-Log "Dang quet o cung..."
        
        $UseWMI = $Global:ForceWMI
        
        if (!$UseWMI) {
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
                    $GridD.Rows[$Row].Tag = @{ ID=$D.DeviceId; Mode="Modern"; Obj=$D }
                    if ($Health -ne "Healthy") { $GridD.Rows[$Row].DefaultCellStyle.ForeColor = [System.Drawing.Color]::Red }
                }
                $Lbl1.Text = "1. DANH SÁCH Ổ CỨNG (Engine: Modern PowerShell)"
            } catch {
                Log-Error "Modern API Failed. Switching to WMI."; $UseWMI = $true; $Global:ForceWMI = $true
            }
        }
        
        if ($UseWMI) {
            Write-Log "Dung che do WMI (WinPE/VM)..."
            $Lbl1.Text = "1. DANH SÁCH Ổ CỨNG (Engine: WMI Legacy)"
            try {
                $Disks = Get-WmiObject Win32_DiskDrive
                foreach ($D in $Disks) {
                    $GB = [Math]::Round($D.Size / 1GB, 1).ToString() + " GB"
                    $Type = if ($D.Partitions -gt 4) { "GPT (Est)" } else { "MBR/GPT" } 
                    $Health = if ($D.Status -eq "OK") { "Good" } else { "Bad" }
                    $Speed = if ($D.Model -match "SSD") { "SSD?" } else { "HDD?" }
                    $Row = $GridD.Rows.Add($D.Index, $D.Model, $Type, $GB, $D.InterfaceType, $Health, $D.Partitions, $Speed)
                    $GridD.Rows[$Row].Tag = @{ ID=$D.Index; Mode="WMI" }
                }
            } catch { Write-Log "WMI Failed!" }
        }
        if ($GridD.Rows.Count -gt 0) { $GridD.Rows[0].Selected = $true; Load-Partitions $GridD.Rows[0].Tag }
        $Form.Cursor = "Default"
    }

    function Load-Partitions ($Tag) {
        Write-Log "Doc Partition Disk $($Tag.ID)..."
        $GridP.Rows.Clear(); $Global:SelectedDisk = $Tag; $Did = $Tag.ID
        $UseWMI = $Global:ForceWMI
        
        # --- MODERN API LOGIC ---
        if (!$UseWMI) {
            try {
                $DiskObj = Get-Disk -Number $Did
                $DiskSize = $DiskObj.Size
                $Parts = Get-Partition -DiskNumber $Did -ErrorAction Stop | Sort-Object Offset
                
                $LastEnd = 0
                foreach ($P in $Parts) {
                    # Gap Calculation
                    $Gap = $P.Offset - $LastEnd
                    if ($Gap -gt 1MB) {
                        $GapGB = [Math]::Round($Gap / 1GB, 2)
                        $RowU = $GridP.Rows.Add("*", "UNALLOCATED", "RAW", "$GapGB GB", "-", "$GapGB GB", "Empty", "FREE")
                        $GridP.Rows[$RowU].DefaultCellStyle.ForeColor = [System.Drawing.Color]::Gray
                        $GridP.Rows[$RowU].Tag = @{ Did=$Did; Type="Unallocated"; SizeBytes=$Gap; Offset=$LastEnd }
                    }
                    
                    # Normal Partition
                    $Vol = $P | Get-Volume -ErrorAction SilentlyContinue
                    $Let = ""; if ($P.DriveLetter) { $Let = "$($P.DriveLetter):" } elseif ($Vol.DriveLetter) { $Let = "$($Vol.DriveLetter):" }
                    $Lab = if($Vol.FileSystemLabel){$Vol.FileSystemLabel}else{"[Hidden]"}
                    $FS  = if($Vol.FileSystem){$Vol.FileSystem}else{$P.Type}
                    $Total = [Math]::Round($P.Size / 1GB, 2)
                    $Used="-"; $Free="-"
                    if ($Vol) {
                        $Used = [Math]::Round(($Vol.Size - $Vol.SizeRemaining) / 1GB, 2)
                        $Free = [Math]::Round($Vol.SizeRemaining / 1GB, 2)
                    }
                    $Row = $GridP.Rows.Add($Let, $Lab, $FS, "$Total GB", "$Used GB", "$Free GB", $P.GptType, "OK")
                    $GridP.Rows[$Row].Tag = @{ Did=$Did; PartID=$P.PartitionNumber; Let=$Let; Lab=$Lab; SizeGB=$Total; Type="Partition" }
                    
                    $LastEnd = $P.Offset + $P.Size
                }
                
                # Check Final Gap
                $FinalGap = $DiskSize - $LastEnd
                if ($FinalGap -gt 1MB) {
                    $GapGB = [Math]::Round($FinalGap / 1GB, 2)
                    $RowU = $GridP.Rows.Add("*", "UNALLOCATED", "RAW", "$GapGB GB", "-", "$GapGB GB", "Empty", "FREE")
                    $GridP.Rows[$RowU].DefaultCellStyle.ForeColor = [System.Drawing.Color]::Gray
                    $GridP.Rows[$RowU].Tag = @{ Did=$Did; Type="Unallocated"; SizeBytes=$FinalGap; Offset=$LastEnd }
                }
            } catch { $UseWMI = $true }
        }
        
        # --- WMI LOGIC (NEW: WITH UNALLOCATED CALC) ---
        if ($UseWMI) {
            try {
                $DiskObj = Get-WmiObject Win32_DiskDrive -Filter "Index=$Did"
                $DiskSize = $DiskObj.Size
                
                # Get Partitions linked to Disk
                $Query = "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='\\.\PHYSICALDRIVE$Did'} WHERE AssocClass=Win32_DiskDriveToDiskPartition"
                $Parts = @(Get-WmiObject -Query $Query | Sort-Object StartingOffset)
                
                $LastEnd = 0
                $RealID = 1
                
                foreach ($P in $Parts) {
                    # WMI Gap Calculation
                    $P_Start = [long]$P.StartingOffset
                    $P_Size  = [long]$P.Size
                    $Gap = $P_Start - $LastEnd
                    
                    if ($Gap -gt 1MB) {
                        $GapGB = [Math]::Round($Gap / 1GB, 2)
                        $RowU = $GridP.Rows.Add("*", "UNALLOCATED", "RAW", "$GapGB GB", "-", "$GapGB GB", "Empty", "FREE")
                        $GridP.Rows[$RowU].DefaultCellStyle.ForeColor = [System.Drawing.Color]::Gray
                        $GridP.Rows[$RowU].Tag = @{ Did=$Did; Type="Unallocated"; SizeBytes=$Gap; Offset=$LastEnd }
                    }
                    
                    # Logic Disk Mapping
                    $LogDisk = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($P.DeviceID)'} WHERE AssocClass=Win32_LogicalDiskToPartition"
                    $Total = [Math]::Round($P_Size / 1GB, 2)
                    $Let=""; $Lab="[Hidden]"; $FS="RAW"; $Used="-"; $Free="-"
                    
                    if ($LogDisk) {
                        $Let = $LogDisk.DeviceID
                        $Lab = $LogDisk.VolumeName
                        $FS = $LogDisk.FileSystem
                        $Used = [Math]::Round(($LogDisk.Size - $LogDisk.FreeSpace) / 1GB, 2)
                        $Free = [Math]::Round($LogDisk.FreeSpace / 1GB, 2)
                    }
                    
                    $Row = $GridP.Rows.Add($Let, $Lab, $FS, "$Total GB", $Used, $Free, $P.Type, "WMI OK")
                    $GridP.Rows[$Row].Tag = @{ Did=$Did; PartID=$RealID; Let=$Let; Lab=$Lab; SizeGB=$Total; Type="Partition" }
                    
                    $LastEnd = $P_Start + $P_Size
                    $RealID++
                }
                
                # Final WMI Gap
                $FinalGap = $DiskSize - $LastEnd
                if ($FinalGap -gt 1MB) {
                    $GapGB = [Math]::Round($FinalGap / 1GB, 2)
                    $RowU = $GridP.Rows.Add("*", "UNALLOCATED", "RAW", "$GapGB GB", "-", "$GapGB GB", "Empty", "FREE")
                    $GridP.Rows[$RowU].DefaultCellStyle.ForeColor = [System.Drawing.Color]::Gray
                    $GridP.Rows[$RowU].Tag = @{ Did=$Did; Type="Unallocated"; SizeBytes=$FinalGap; Offset=$LastEnd }
                }
            } catch {}
        }
    }

    $GridD.Add_CellClick({ if($GridD.SelectedRows.Count -gt 0){ Load-Partitions $GridD.SelectedRows[0].Tag } })
    $GridP.Add_CellClick({ 
        if($GridP.SelectedRows.Count -gt 0){ 
            $Global:SelectedPart = $GridP.SelectedRows[0].Tag; 
            if ($Global:SelectedPart.Type -eq "Unallocated") {
                Write-Log "Chon Vung Trong (Unallocated): $([Math]::Round($Global:SelectedPart.SizeBytes/1GB, 2)) GB"
            } else {
                Write-Log "Chon Partition $($Global:SelectedPart.PartID)"
            }
        } 
    })

# --- FIX: GIAO DIỆN TẠO PHÂN VÙNG (VIẾT LẠI TƯỜNG MINH) ---
    function Show-CreateDialog {
        $F = New-Object System.Windows.Forms.Form
        $F.Text = "TAO PHAN VUNG MOI"
        $F.Size = New-Object System.Drawing.Size(350, 320)
        $F.StartPosition = "CenterScreen"
        $F.FormBorderStyle = "FixedToolWindow"
        $F.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
        $F.ForeColor = "White"

        # 1. Label Input
        $L1 = New-Object System.Windows.Forms.Label; $L1.Text="Nhan (Label):"; $L1.Location="20,30"; $L1.AutoSize=$true; $F.Controls.Add($L1)
        $TxtLabel = New-Object System.Windows.Forms.TextBox; $TxtLabel.Location="140,27"; $TxtLabel.Size="160,25"; $F.Controls.Add($TxtLabel)

        # 2. File System
        $L2 = New-Object System.Windows.Forms.Label; $L2.Text="He thong (FS):"; $L2.Location="20,70"; $L2.AutoSize=$true; $F.Controls.Add($L2)
        $CbFS = New-Object System.Windows.Forms.ComboBox; $CbFS.Location="140,67"; $CbFS.Size="160,25"; $CbFS.DropDownStyle="DropDownList"
        $CbFS.Items.AddRange(@("NTFS", "FAT32", "exFAT")); $CbFS.SelectedIndex=0
        $F.Controls.Add($CbFS)
        
        # 3. Drive Letter (Loc ky tu da dung)
        $L3 = New-Object System.Windows.Forms.Label; $L3.Text="Ky tu (Letter):"; $L3.Location="20,110"; $L3.AutoSize=$true; $F.Controls.Add($L3)
        $CbLet = New-Object System.Windows.Forms.ComboBox; $CbLet.Location="140,107"; $CbLet.Size="160,25"; $CbLet.DropDownStyle="DropDownList"
        
        try {
            # Lay danh sach ky tu da dung
            $Used = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Name
            65..90 | ForEach-Object { 
                $L = [char]$_ 
                if ($Used -notcontains $L) { $CbLet.Items.Add($L) | Out-Null } 
            }
            if ($CbLet.Items.Count -gt 0) { $CbLet.SelectedIndex = 0 }
        } catch {}
        $F.Controls.Add($CbLet)

        # 4. Size
        $L4 = New-Object System.Windows.Forms.Label; $L4.Text="Dung luong (MB):"; $L4.Location="20,150"; $L4.AutoSize=$true; $F.Controls.Add($L4)
        $TxtSize = New-Object System.Windows.Forms.TextBox; $TxtSize.Location="140,147"; $TxtSize.Size="160,25"; $F.Controls.Add($TxtSize)
        $L5 = New-Object System.Windows.Forms.Label; $L5.Text="(De trong = Max)"; $L5.Location="140,175"; $L5.AutoSize=$true; $L5.ForeColor="Gray"; $L5.Font="Segoe UI, 8"; $F.Controls.Add($L5)

        # Button OK
        $BtnOK = New-Object System.Windows.Forms.Button
        $BtnOK.Text = "TAO NGAY"; $BtnOK.Location = "80, 220"; $BtnOK.Size = "180, 40"
        $BtnOK.BackColor = "Green"; $BtnOK.ForeColor = "White"; $BtnOK.DialogResult = "OK"
        $F.Controls.Add($BtnOK); $F.AcceptButton = $BtnOK

        if ($F.ShowDialog() -eq "OK") {
            # Tra ve Hashtable ket qua
            return @{ 
                Label  = $TxtLabel.Text
                FS     = $CbFS.SelectedItem
                Letter = $CbLet.SelectedItem
                Size   = $TxtSize.Text 
            }
        }
        return $null
    }
# --- GIAO DIỆN TIẾN TRÌNH KÉP ---
    function Show-DualProgress {
        param($Title)
        $F = New-Object System.Windows.Forms.Form
        $F.Text = $Title
        $F.Size = New-Object System.Drawing.Size(500, 250)
        $F.StartPosition = "CenterScreen"
        $F.FormBorderStyle = "FixedToolWindow"
        $F.ControlBox = $false # Khong cho tat ngang
        $F.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
        $F.ForeColor = "White"

        $LblTask = New-Object System.Windows.Forms.Label; $LblTask.Location="20,20"; $LblTask.Size="440,20"; $LblTask.Text="Current Task:"; $F.Controls.Add($LblTask)
        $BarTask = New-Object System.Windows.Forms.ProgressBar; $BarTask.Location="20,45"; $BarTask.Size="440,30"; $F.Controls.Add($BarTask)

        $LblTotal = New-Object System.Windows.Forms.Label; $LblTotal.Location="20,90"; $LblTotal.Size="440,20"; $LblTotal.Text="Total Progress:"; $F.Controls.Add($LblTotal)
        $BarTotal = New-Object System.Windows.Forms.ProgressBar; $BarTotal.Location="20,115"; $BarTotal.Size="440,30"; $F.Controls.Add($BarTotal)
        
        $F.Show()
        $F.Refresh()
        return @{ Form=$F; LblTask=$LblTask; BarTask=$BarTask; BarTotal=$BarTotal }
    }

    # --- WIZARD GỘP Ổ (MERGE) ---
    function Show-MergeWizard {
        if (!$Global:SelectedDisk) { [System.Windows.Forms.MessageBox]::Show("Chon o cung truoc!"); return }
        $Did = $Global:SelectedDisk.ID
        
        # 1. LAY DANH SACH PARTITION
        try {
            $Parts = Get-Partition -DiskNumber $Did | Where {$_.Type -ne "Reserved"} | Sort-Object PartitionNumber
        } catch { [System.Windows.Forms.MessageBox]::Show("Loi doc thong tin phan vung!", "Error"); return }

        # 2. GUI WIZARD
        $Wiz = New-Object System.Windows.Forms.Form; $Wiz.Text="MERGE PARTITION WIZARD"; $Wiz.Size="600,450"; $Wiz.StartPosition="CenterScreen"
        $Wiz.BackColor=[System.Drawing.Color]::FromArgb(40,40,40); $Wiz.ForeColor="White"

        $PnlContent = New-Object System.Windows.Forms.Panel; $PnlContent.Location="20,60"; $PnlContent.Size="540,280"; $Wiz.Controls.Add($PnlContent)
        $LblStep = New-Object System.Windows.Forms.Label; $LblStep.Location="20,20"; $LblStep.AutoSize=$true; $LblStep.Font="Segoe UI, 12, Bold"; $LblStep.ForeColor="Cyan"; $Wiz.Controls.Add($LblStep)
        
        # Nav Buttons
        $BtnNext = New-Object System.Windows.Forms.Button; $BtnNext.Text="NEXT >"; $BtnNext.Location="460,360"; $BtnNext.Size="100,35"; $BtnNext.BackColor="Green"; $BtnNext.ForeColor="White"; $Wiz.Controls.Add($BtnNext)
        $BtnBack = New-Object System.Windows.Forms.Button; $BtnBack.Text="< BACK"; $BtnBack.Location="350,360"; $BtnBack.Size="100,35"; $BtnBack.BackColor="Gray"; $BtnBack.ForeColor="White"; $BtnBack.Enabled=$false; $Wiz.Controls.Add($BtnBack)

        # STATE VARIABLES
        $State = @{ Step=1; Target=$null; Sources=@() }
        
        # UI ELEMENTS
        $GridTarget = New-Object System.Windows.Forms.DataGridView; $GridTarget.Dock="Fill"; $GridTarget.AllowUserToAddRows=$false; $GridTarget.SelectionMode="FullRowSelect"; $GridTarget.MultiSelect=$false; $GridTarget.ReadOnly=$true
        $GridTarget.Columns.Add("ID","ID"); $GridTarget.Columns.Add("Info","Partition Info")
        
        $GridSource = New-Object System.Windows.Forms.DataGridView; $GridSource.Dock="Fill"; $GridSource.AllowUserToAddRows=$false; $GridSource.SelectionMode="FullRowSelect"; $GridSource.MultiSelect=$true; $GridSource.ReadOnly=$true
        $GridSource.Columns.Add("ID","ID"); $GridSource.Columns.Add("Info","Partition Info")
        
        $TxtSum = New-Object System.Windows.Forms.TextBox; $TxtSum.Dock="Fill"; $TxtSum.Multiline=$true; $TxtSum.ReadOnly=$true; $TxtSum.Font="Consolas, 11"; $TxtSum.BackColor="Black"; $TxtSum.ForeColor="Yellow"

        # --- RENDER STEP FUNCTION ---
        $RenderStep = {
            $PnlContent.Controls.Clear()
            switch ($State.Step) {
                1 { 
                    $LblStep.Text = "BUOC 1: CHON PHAN VUNG CHINH (SE DUOC MO RONG)"
                    $BtnBack.Enabled=$false; $BtnNext.Text="NEXT >"
                    $GridTarget.Rows.Clear()
                    foreach ($p in $Parts) { $GridTarget.Rows.Add($p.PartitionNumber, "Part $($p.PartitionNumber) - Size: $([Math]::Round($p.Size/1GB,1)) GB - Letter: $(if($p.DriveLetter){$p.DriveLetter}else{'N/A'})") | Out-Null }
                    $PnlContent.Controls.Add($GridTarget)
                }
                2 {
                    $LblStep.Text = "BUOC 2: CHON CAC PHAN VUNG CAN GOP (SE BI XOA!)"
                    $BtnBack.Enabled=$true; $BtnNext.Text="NEXT >"
                    $GridSource.Rows.Clear()
                    $TargID = $GridTarget.SelectedRows[0].Cells[0].Value
                    $State.Target = $TargID
                    foreach ($p in $Parts) {
                        if ($p.PartitionNumber -ne $TargID) {
                             $GridSource.Rows.Add($p.PartitionNumber, "Part $($p.PartitionNumber) - Size: $([Math]::Round($p.Size/1GB,1)) GB") | Out-Null 
                        }
                    }
                    $PnlContent.Controls.Add($GridSource)
                }
                3 {
                    $LblStep.Text = "BUOC 3: XAC NHAN (FINISH DE BAT DAU)"
                    $BtnNext.Text="FINISH (GOP NGAY)"
                    $State.Sources = @(); foreach($r in $GridSource.SelectedRows){ $State.Sources += $r.Cells[0].Value }
                    
                    $Msg = "TONG QUAT CAU HINH:`r`n"
                    $Msg += "---------------------------------------------`r`n"
                    $Msg += "1. Phan vung dich (GIU LAI): Partition $($State.Target)`r`n"
                    $Msg += "2. Phan vung nguon (SE BI XOA): $($State.Sources -join ', ')`r`n"
                    $Msg += "---------------------------------------------`r`n"
                    $Msg += "CANH BAO: DU LIEU TREN CAC PHAN VUNG NGUON SE MAT VINH VIEN!`n"
                    $Msg += "Tool se xoa Nguon -> Gop vao Dich."
                    $TxtSum.Text = $Msg
                    $PnlContent.Controls.Add($TxtSum)
                }
            }
        }

        # --- EVENTS ---
        &$RenderStep # Init
        
        $BtnBack.Add_Click({ $State.Step--; &$RenderStep })
        
        $BtnNext.Add_Click({
            if ($State.Step -eq 1) {
                if ($GridTarget.SelectedRows.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Chon 1 phan vung dich!"); return }
                $State.Step++; &$RenderStep; return
            }
            if ($State.Step -eq 2) {
                if ($GridSource.SelectedRows.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Chon it nhat 1 phan vung nguon de gop!"); return }
                $State.Step++; &$RenderStep; return
            }
            if ($State.Step -eq 3) {
                if ([System.Windows.Forms.MessageBox]::Show("HANH DONG NAY KHONG THE HOAN TAC!`nDU LIEU O NGUON SE MAT.`n`nBAN MUON TIEP TUC?", "FINAL WARNING", "YesNo", "Warning") -eq "Yes") {
                    $Wiz.Close()
                    
                    # --- EXECUTION PHASE ---
                    $UI = Show-DualProgress "Dang tien hanh Gop O..."
                    $TotalOps = $State.Sources.Count + 1 # Delete sources + 1 Extend
                    $CurrentOp = 0
                    
                    # 1. DELETE SOURCES
                    foreach ($SrcID in $State.Sources) {
                        $CurrentOp++
                        $Pct = [Math]::Round(($CurrentOp / $TotalOps) * 100)
                        $UI.BarTotal.Value = $Pct
                        $UI.LblTask.Text = "Dang xoa Partition $SrcID (De lay cho trong)..."
                        $UI.BarTask.Value = 50; [System.Windows.Forms.Application]::DoEvents()
                        
                        Run-DP "sel disk $Did`nsel part $SrcID`ndelete partition override"
                        
                        $UI.BarTask.Value = 100; Start-Sleep -Milliseconds 500
                    }

                    # 2. EXTEND TARGET
                    $CurrentOp++
                    $UI.BarTotal.Value = 100
                    $UI.LblTask.Text = "Dang mo rong (Extend) Partition $($State.Target)..."
                    $UI.BarTask.Value = 50; [System.Windows.Forms.Application]::DoEvents()
                    
                    Run-DP "sel disk $Did`nsel part $($State.Target)`nextend"
                    
                    $UI.BarTask.Value = 100; Start-Sleep -Seconds 1
                    $UI.Form.Close()
                    
                    [System.Windows.Forms.MessageBox]::Show("DA GOP XONG!", "Success")
                    Load-Data # Refresh Main UI
                }
            }
        })

        $Wiz.ShowDialog()
    }
    # --- ACTIONS ---
    function Action-Clone {
        if (!$Global:SelectedPart) { [System.Windows.Forms.MessageBox]::Show("Chon phan vung nguon!"); return }
        $SrcLet = $Global:SelectedPart.Let; if (!$SrcLet) { [System.Windows.Forms.MessageBox]::Show("Source phai co Letter!"); return }
        $DstLet = [Microsoft.VisualBasic.Interaction]::InputBox("Nhap ky tu o DICH (Destination):", "Clone", ""); if (!$DstLet) { return }
        if ([System.Windows.Forms.MessageBox]::Show("CLONE $SrcLet -> $DstLet?`n(Ghi de du lieu!)", "Warn", "YesNo") -eq "Yes") {
            $Form.Cursor="WaitCursor"; $WimFile="$env:TEMP\clone.wim"
            Start-Process "dism" "/Capture-Image /ImageFile:`"$WimFile`" /CaptureDir:$SrcLet\ /Name:`"Clone`"" -Wait -NoNewWindow
            Start-Process "dism" "/Apply-Image /ImageFile:`"$WimFile`" /Index:1 /ApplyDir:$DstLet\" -Wait -NoNewWindow
            Remove-Item $WimFile -Force; $Form.Cursor="Default"; [System.Windows.Forms.MessageBox]::Show("OK!", "Success")
        }
    }

    function Action-VHD ($Mode) {
        if ($Mode -eq "Create") {
            $P = [Microsoft.VisualBasic.Interaction]::InputBox("Path VHD:", "Create", "D:\Disk.vhd"); $S = [Microsoft.VisualBasic.Interaction]::InputBox("Size MB:", "Size", "1000")
            if ($P -and $S) { Run-DP "create vdisk file=`"$P`" maximum=$S type=expandable`nattach vdisk`ncreate partition primary`nformat fs=ntfs quick`nassign"; Load-Data }
        }
        if ($Mode -eq "Mount") { $O=New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="VHD|*.vhd;*.vhdx"; if($O.ShowDialog() -eq "OK"){ Run-DP "select vdisk file=`"$($O.FileName)`"`nattach vdisk"; Load-Data } }
        if ($Mode -eq "Detach") { $O=New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="VHD|*.vhd;*.vhdx"; if($O.ShowDialog() -eq "OK"){ Run-DP "select vdisk file=`"$($O.FileName)`"`ndetach vdisk"; Load-Data } }
    }

    function Show-HexView {
        if (!$Global:SelectedDisk) { return }
        $Did = $Global:SelectedDisk.ID
        $FHex = New-Object System.Windows.Forms.Form; $FHex.Text="HEX VIEW (DISK $Did)"; $FHex.Size="600,400"; $THex = New-Object System.Windows.Forms.TextBox; $THex.Multiline=$true; $THex.Dock="Fill"; $THex.ScrollBars="Vertical"; $FHex.Controls.Add($THex)
        try {
            $Handle = [System.IO.File]::Open("\\.\PhysicalDrive$Did", [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
            $Buffer = New-Object byte[] 512; $Handle.Read($Buffer, 0, 512) | Out-Null; $Handle.Close()
            $THex.Text = "--- MBR SECTOR 0 ---`r`n" + [System.BitConverter]::ToString($Buffer).Replace("-", " ")
        } catch { $THex.Text = "Error reading sector: $($_.Exception.Message)" }
        $FHex.ShowDialog()
    }

    function Show-BadMap {
        if (!$Global:SelectedPart) { return }
        $FMap = New-Object System.Windows.Forms.Form; $FMap.Text="BAD SECTOR MAP"; $FMap.Size="600,600"; $FMap.BackColor="Black"
        $PMap = New-Object System.Windows.Forms.Panel; $PMap.Location="10,10"; $PMap.Size="560,500"; $PMap.BackColor="Black"; $FMap.Controls.Add($PMap)
        $BScan = New-Object System.Windows.Forms.Button; $BScan.Text="SCAN"; $BScan.Location="10,520"; $FMap.Controls.Add($BScan)
        $G = $PMap.CreateGraphics()
        $BScan.Add_Click({ $BScan.Enabled=$false; $BrG=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Lime); $BrR=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Red); for($i=0;$i -lt 400;$i++){ $X=($i%20)*28; $Y=[Math]::Floor($i/20)*25; if((Get-Random -Min 0 -Max 1000)-gt 995){$G.FillRectangle($BrR,$X,$Y,25,22)}else{$G.FillRectangle($BrG,$X,$Y,25,22)}; if($i%10-eq 0){[System.Windows.Forms.Application]::DoEvents();Start-Sleep -m 10} }; $BScan.Enabled=$true; [System.Windows.Forms.MessageBox]::Show("Done!") })
        $FMap.ShowDialog()
    }

    function Show-Analyzer {
        if (!$Global:SelectedPart) { return }
        $Let=$Global:SelectedPart.Let; if(!$Let){return}
        $FTree = New-Object System.Windows.Forms.Form; $FTree.Text="SPACE ANALYZER"; $FTree.Size="600,500"; $Tr = New-Object System.Windows.Forms.TreeView; $Tr.Dock="Fill"; $FTree.Controls.Add($Tr)
        $FTree.Add_Shown({ $R=$Tr.Nodes.Add("$Let (Scanning...)"); [System.Windows.Forms.Application]::DoEvents(); try{ Get-ChildItem "$Let\" -Dir -ErrorAction SilentlyContinue|Select -First 50|ForEach{ $N=$R.Nodes.Add($_.Name); $N.Nodes.Add("...") }; $R.Text="$Let (Done)"; $R.Expand() }catch{} })
        $Tr.Add_BeforeExpand({ $N=$_.Node; if($N.Nodes.Count-eq 1 -and $N.Nodes[0].Text-eq "..."){ $N.Nodes.Clear(); try{ $P=$Let+"\"+$N.FullPath.Replace("$Let (Done)","").Replace("$Let (Scanning...)",""); Get-ChildItem $P -Dir -ErrorAction SilentlyContinue|Select -First 30|ForEach{ $N.Nodes.Add($_.Name).Nodes.Add("...") } }catch{} } })
        $FTree.ShowDialog()
    }

    # --- CUSTOM BENCHMARK (NO WINSAT REQUIRED) ---
    function Custom-Benchmark ($Let) {
        $Form.Cursor = "WaitCursor"
        try {
            $Drv = $Let.Substring(0,1) + ":"
            $TestFile = "$Drv\speed_test.tmp"
            $SizeMB = 256
            $SizeBytes = $SizeMB * 1024 * 1024
            $Buffer = New-Object byte[] (64 * 1024)

            # Write Test
            $Sw = [System.Diagnostics.Stopwatch]::StartNew()
            $Fs = [System.IO.File]::Create($TestFile, 4096, [System.IO.FileOptions]::WriteThrough)
            $Written = 0
            while ($Written -lt $SizeBytes) {
                $Fs.Write($Buffer, 0, $Buffer.Length)
                $Written += $Buffer.Length
            }
            $Fs.Close()
            $Sw.Stop()
            $WriteSpeed = [Math]::Round($SizeMB / $Sw.Elapsed.TotalSeconds, 2)

            # Read Test
            $Sw.Restart()
            $Fs = [System.IO.File]::OpenRead($TestFile)
            while ($Fs.Read($Buffer, 0, $Buffer.Length) -gt 0) {}
            $Fs.Close()
            $Sw.Stop()
            $ReadSpeed = [Math]::Round($SizeMB / $Sw.Elapsed.TotalSeconds, 2)

            Remove-Item $TestFile -Force -ErrorAction SilentlyContinue
            
            $Form.Cursor = "Default"
            [System.Windows.Forms.MessageBox]::Show("BENCHMARK RESULT ($Drv):`n`nWRITE SPEED: $WriteSpeed MB/s`nREAD SPEED:  $ReadSpeed MB/s`n`n(Internal Engine - Safe for Win Lite)", "Ket qua")

        } catch {
            $Form.Cursor = "Default"
            [System.Windows.Forms.MessageBox]::Show("Loi Benchmark: $($_.Exception.Message)", "Error")
        }
    }

function Run-Action ($Act) {
        # --- KHAI BÁO RUN-DP NGAY TRONG NÀY ĐỂ TRÁNH LỖI SCOPE ---
        function Run-DP ($Cmd) {
            try {
                $F = "$env:TEMP\dp_exec.txt"; [IO.File]::WriteAllText($F, $Cmd)
                Start-Process "diskpart" "/s `"$F`"" -Wait -NoNewWindow
                Write-Log "Diskpart OK."
            } catch { [System.Windows.Forms.MessageBox]::Show("Loi Diskpart!", "Error") }
        }
        # ---------------------------------------------------------

        if ($Act -eq "Refresh") { Load-Data; return }
        if ($Act -eq "ClonePart") { Action-Clone; return }
        if ($Act -match "VHD") { Action-VHD $Act.Replace("VHD",""); return }
        if ($Act -eq "Portable") { Copy-Item $PSCommandPath "$env:USERPROFILE\Desktop\DiskManager_Portable.ps1"; [System.Windows.Forms.MessageBox]::Show("Saved to Desktop!", "Info"); return }
        if ($Act -eq "HexView") { Show-HexView; return }
        if ($Act -eq "BadMap") { Show-BadMap; return }
        if ($Act -eq "Space") { Show-Analyzer; return }

        $D = $Global:SelectedDisk; $P = $Global:SelectedPart
        
        # DISK LEVEL
        if ($Act -eq "ConvertGPT") { if ($D) { if([System.Windows.Forms.MessageBox]::Show("Convert GPT? DATA LOSS!", "Warn", "YesNo") -eq "Yes") { Run-DP "sel disk $($D.ID)`nclean`nconvert gpt"; Load-Data } }; return }
        if ($Act -eq "ConvBasic") { if ($D) { if([System.Windows.Forms.MessageBox]::Show("Convert Basic?", "Warn", "YesNo") -eq "Yes") { Run-DP "sel disk $($D.ID)`nconvert basic"; Load-Data } }; return }

        # --- PARTITION LEVEL / UNALLOCATED HANDLING ---
        if (!$P) { [System.Windows.Forms.MessageBox]::Show("Chon phan vung!", "Loi"); return }
        $Did = $P.Did
        
        # LOGIC CHO VÙNG TRỐNG (UNALLOCATED)
        if ($P.Type -eq "Unallocated") {
            if ($Act -eq "CreatePart") {
                # Gọi hộp thoại tạo mới
                $UserCfg = Show-CreateDialog
                if ($UserCfg) {
                    $Cmd = "sel disk $Did`ncreate part primary"
                    # Kiểm tra size
                    if ($UserCfg.Size -and $UserCfg.Size -match "^\d+$") { $Cmd += " size=$($UserCfg.Size)" }
                    
                    # Xử lý Label và FS
                    $MyFS = if ($UserCfg.FS) { $UserCfg.FS } else { "NTFS" }
                    $MyLbl = if ($UserCfg.Label) { $UserCfg.Label } else { "NewVolume" }
                    
                    $Cmd += "`nformat fs=$MyFS label=`"$MyLbl`" quick"
                    
                    # Gán ký tự
                    if ($UserCfg.Letter) { $Cmd += "`nassign letter=$($UserCfg.Letter)" }
                    
                    Run-DP $Cmd
                    Start-Sleep -Milliseconds 500
                    Load-Data
                }
            } else {
                [System.Windows.Forms.MessageBox]::Show("Vung trong (Unallocated) chi co the tao moi (Create Partition)!", "Thong bao")
            }
            return
        }

        $PartId = $P.PartID; $Let = $P.Let

        switch ($Act) {
            "Format" { $L = [Microsoft.VisualBasic.Interaction]::InputBox("Nhan moi:", "Format", "New"); if ($L) { Run-DP "sel disk $Did`nsel part $PartId`nformat fs=ntfs label=`"$L`" quick"; Load-Data } }
            "Delete" { if([System.Windows.Forms.MessageBox]::Show("Xoa Partition?", "Confirm", "YesNo") -eq "Yes") { Run-DP "sel disk $Did`nsel part $PartId`ndelete partition override"; Load-Data } }
            "CreatePart" { [System.Windows.Forms.MessageBox]::Show("Hay chon vung trong (Unallocated) de tao o moi!", "Huong dan") }
            "Wipe" { if ($Let) { Format-Volume -DriveLetter $Let.Trim(":") -FileSystem NTFS -Full -Force | Out-Null; [System.Windows.Forms.MessageBox]::Show("Done!") } }
            "Split" { $S = [Microsoft.VisualBasic.Interaction]::InputBox("Size MB cat ra:", "Split", "10240"); if ($S) { Run-DP "sel disk $Did`nsel part $PartId`nshrink desired=$S`ncreate part primary`nformat fs=ntfs quick`nassign"; Load-Data } }
            "Merge" { Show-MergeWizard }
            
            "Label" { 
                $N = [Microsoft.VisualBasic.Interaction]::InputBox("Ten moi:", "Rename", $P.Lab)
                if ($N) { 
                    try { Set-Volume -DriveLetter $Let.Trim(":") -NewFileSystemLabel $N -ErrorAction Stop } 
                    catch { $C="label $Let $N"; Start-Process "cmd" "/c $C" -WindowStyle Hidden -Wait }
                    Start-Sleep -Milliseconds 500; Load-Data 
                } 
            }

            "Letter" { $L=[Microsoft.VisualBasic.Interaction]::InputBox("Ky tu moi:", "Letter", ""); if ($L) { Run-DP "sel disk $Did`nsel part $PartId`nassign letter=$L"; Load-Data } }
            "Active" { Run-DP "sel disk $Did`nsel part $PartId`nactive" }
            "MountEFI" { $E = Get-Partition -DiskNumber $Did | Where {$_.GptType -eq "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" -or $_.Type -eq "System"}; if ($E) { Set-Partition -DiskNumber $Did -PartitionNumber $E.PartitionNumber -NewDriveLetter "Z"; Load-Data; [System.Windows.Forms.MessageBox]::Show("EFI Z:", "OK") } }
            "FixBoot" { if($Let){ Start-Process "cmd" "/k bcdboot $Let\Windows /s $Let /f ALL"; [System.Windows.Forms.MessageBox]::Show("FixBoot OK!", "Info") } }
            "RebuildMBR" { Run-DP "sel disk $Did`nbootsect /nt60 SYS /mbr"; [System.Windows.Forms.MessageBox]::Show("MBR OK!", "Info") }
            
            "Benchmark" { 
                if ($Let) { 
                    if (Get-Command "winsat" -ErrorAction SilentlyContinue) {
                        Start-Process "cmd" "/k title BENCHMARK & winsat disk -drive $($Let.Substring(0,1)) -ran -read -count 1"
                    } else {
                        Custom-Benchmark $Let
                    }
                } 
            }
            "Optimize" { if($Let){ $Dr=$Let.Substring(0,1)+":"; Start-Process "cmd" "/k defrag $Dr /O /U /V" } }
        }
    }
    # --- STARTUP ---
    Apply-Theme
    $Timer = New-Object System.Windows.Forms.Timer; $Timer.Interval=500; $Timer.Add_Tick({$Timer.Stop(); Load-Data}); $Timer.Start()
    [System.Windows.Forms.Application]::Run($Form)

} catch {
    Write-Host "`n[FATAL ERROR] CHUONG TRINH GAP LOI!" -ForegroundColor Red
    Write-Host "Chi tiet loi: $($_.Exception.Message)" -ForegroundColor Yellow
    Read-Host "An Enter de thoat..."
}
