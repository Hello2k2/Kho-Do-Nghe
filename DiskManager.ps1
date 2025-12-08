<#
    DISK MANAGER ULTIMATE - PHAT TAN PC (V15.0)
    Engine: Hybrid (Storage Module + WMI Fallback)
    UI: Titanium Dark Pro + Tabbed Interface
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

# --- THEME CONFIG (TITANIUM DARK PRO) ---
$T = @{
    BgForm      = [System.Drawing.Color]::FromArgb(18, 18, 22)
    BgPanel     = [System.Drawing.Color]::FromArgb(30, 30, 35)
    GridBg      = [System.Drawing.Color]::FromArgb(25, 25, 28)
    TextMain    = [System.Drawing.Color]::FromArgb(240, 240, 240)
    TextMuted   = [System.Drawing.Color]::FromArgb(160, 160, 160)
    
    # Accents
    Cyan        = [System.Drawing.Color]::FromArgb(0, 200, 255)
    Red         = [System.Drawing.Color]::FromArgb(255, 60, 80)
    Green       = [System.Drawing.Color]::FromArgb(50, 220, 120)
    Orange      = [System.Drawing.Color]::FromArgb(255, 165, 0)
    
    # Button Gradients
    BtnNorm1    = [System.Drawing.Color]::FromArgb(45, 45, 55)
    BtnNorm2    = [System.Drawing.Color]::FromArgb(65, 65, 75)
    BtnHigh1    = [System.Drawing.Color]::FromArgb(0, 100, 150) # Blue Highlight
    BtnHigh2    = [System.Drawing.Color]::FromArgb(0, 150, 200)
}

$Global:SelectedDisk = $null
$Global:SelectedPart = $null

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "TITANIUM DISK MANAGER V15.0 (ULTIMATE EDITION)"
$Form.Size = New-Object System.Drawing.Size(1280, 850)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $T.BgForm
$Form.ForeColor = $T.TextMain
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# -- FONTS --
$F_Logo = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$F_Head = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$F_Norm = New-Object System.Drawing.Font("Segoe UI", 9)
$F_Btn  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

# ==================== CUSTOM DRAWING ====================

# Panel Gradient Paint
$PaintPanel = {
    param($s, $e)
    $Rect = $s.ClientRectangle
    $Br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($Rect, $T.BgPanel, [System.Drawing.Color]::FromArgb(20,20,22), 90)
    $e.Graphics.FillRectangle($Br, $Rect)
    $Pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(60,60,70), 1)
    $e.Graphics.DrawRectangle($Pen, 0, 0, $s.Width-1, $s.Height-1)
    $Br.Dispose(); $Pen.Dispose()
}

# Button Generator
function Add-CyberBtn ($Parent, $Txt, $Icon, $X, $Y, $W, $Tag, $ColorType="Normal") {
    $Btn = New-Object System.Windows.Forms.Label 
    $Btn.Text = "$Icon  $Txt"
    $Btn.Tag = @{ Act=$Tag; Hover=$false; Type=$ColorType }
    $Btn.Location = "$X, $Y"; $Btn.Size = "$W, 45"
    $Btn.Font = $F_Btn; $Btn.TextAlign = "MiddleCenter"
    $Btn.ForeColor = $T.TextMain; $Btn.Cursor = "Hand"
    
    $Btn.Add_MouseEnter({ $this.Tag.Hover=$true; $this.Invalidate() })
    $Btn.Add_MouseLeave({ $this.Tag.Hover=$false; $this.Invalidate() })
    $Btn.Add_Click({ Run-Action $this.Tag.Act })
    
    $Btn.Add_Paint({
        param($s, $e)
        $R = $s.ClientRectangle
        
        # Color Logic
        switch ($s.Tag.Type) {
            "Danger" { $C1=[System.Drawing.Color]::FromArgb(120,0,0); $C2=[System.Drawing.Color]::FromArgb(180,50,50); $Border=$T.Red }
            "Rescue" { $C1=[System.Drawing.Color]::FromArgb(150,100,0); $C2=[System.Drawing.Color]::FromArgb(200,140,0); $Border=$T.Orange }
            "Monitor"{ $C1=[System.Drawing.Color]::FromArgb(0,80,0); $C2=[System.Drawing.Color]::FromArgb(0,140,50); $Border=$T.Green }
            "Primary"{ $C1=$T.BtnHigh1; $C2=$T.BtnHigh2; $Border=$T.Cyan }
            Default  { $C1=$T.BtnNorm1; $C2=$T.BtnNorm2; $Border=[System.Drawing.Color]::Gray }
        }
        
        if($s.Tag.Hover){ $C1=[System.Windows.Forms.ControlPaint]::Light($C1); $C2=[System.Windows.Forms.ControlPaint]::Light($C2) }
        
        $Br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($R, $C1, $C2, 45)
        $e.Graphics.FillRectangle($Br, $R)
        $Pen = New-Object System.Drawing.Pen($Border, 1)
        $e.Graphics.DrawRectangle($Pen, 0, 0, $s.Width-1, $s.Height-1)
        
        $Sf = New-Object System.Drawing.StringFormat; $Sf.Alignment="Center"; $Sf.LineAlignment="Center"
        $RectF = New-Object System.Drawing.RectangleF(0, 0, $s.Width, $s.Height)
        $e.Graphics.DrawString($s.Text, $s.Font, [System.Drawing.Brushes]::White, $RectF, $Sf)
        
        $Br.Dispose(); $Pen.Dispose()
    })
    $Parent.Controls.Add($Btn)
}

# ==================== LAYOUT ====================

# HEADER
$PnlHead = New-Object System.Windows.Forms.Panel; $PnlHead.Dock="Top"; $PnlHead.Height=70; $PnlHead.BackColor=[System.Drawing.Color]::Transparent
$Form.Controls.Add($PnlHead)
$LblLogo = New-Object System.Windows.Forms.Label; $LblLogo.Text="TITANIUM DISK MANAGER"; $LblLogo.Font=$F_Logo; $LblLogo.AutoSize=$true; $LblLogo.Location="20,15"; $LblLogo.ForeColor=$T.Cyan
$PnlHead.Controls.Add($LblLogo)
$LblSub = New-Object System.Windows.Forms.Label; $LblSub.Text="Ultimate Rescue & Management Tool"; $LblSub.Font=$F_Norm; $LblSub.AutoSize=$true; $LblSub.Location="380,28"; $LblSub.ForeColor=$T.TextMuted
$PnlHead.Controls.Add($LblSub)

# 1. DISK LIST
$PnlDisk = New-Object System.Windows.Forms.Panel; $PnlDisk.Location="20,80"; $PnlDisk.Size="1225,200"; $PnlDisk.Add_Paint($PaintPanel)
$Form.Controls.Add($PnlDisk)
$Lbl1 = New-Object System.Windows.Forms.Label; $Lbl1.Text="1. DANH SÁCH Ổ CỨNG (PHYSICAL DISKS)"; $Lbl1.Location="15,10"; $Lbl1.AutoSize=$true; $Lbl1.ForeColor=$T.Cyan; $Lbl1.Font=$F_Head; $Lbl1.BackColor=[System.Drawing.Color]::Transparent; $PnlDisk.Controls.Add($Lbl1)

$GridD = New-Object System.Windows.Forms.DataGridView; $GridD.Location="15,40"; $GridD.Size="1195,145"; $GridD.BorderStyle="None"
$GridD.BackgroundColor=$T.GridBg; $GridD.ForeColor="Black"
$GridD.AllowUserToAddRows=$false; $GridD.RowHeadersVisible=$false; $GridD.SelectionMode="FullRowSelect"; $GridD.MultiSelect=$false; $GridD.ReadOnly=$true; $GridD.AutoSizeColumnsMode="Fill"
$GridD.Columns.Add("ID","Disk #"); $GridD.Columns[0].Width=60
$GridD.Columns.Add("Mod","Model Name"); $GridD.Columns[1].FillWeight=150
$GridD.Columns.Add("Type","Type"); $GridD.Columns[2].Width=80
$GridD.Columns.Add("Size","Size"); $GridD.Columns[3].Width=80
$GridD.Columns.Add("Bus","Interface"); $GridD.Columns[4].Width=80
$GridD.Columns.Add("Health","Status / S.M.A.R.T"); $GridD.Columns[5].Width=150
$PnlDisk.Controls.Add($GridD)

# 2. PARTITION LIST
$PnlPart = New-Object System.Windows.Forms.Panel; $PnlPart.Location="20,290"; $PnlPart.Size="1225,200"; $PnlPart.Add_Paint($PaintPanel)
$Form.Controls.Add($PnlPart)
$Lbl2 = New-Object System.Windows.Forms.Label; $Lbl2.Text="2. PHÂN VÙNG (PARTITIONS)"; $Lbl2.Location="15,10"; $Lbl2.AutoSize=$true; $Lbl2.ForeColor=$T.Green; $Lbl2.Font=$F_Head; $Lbl2.BackColor=[System.Drawing.Color]::Transparent; $PnlPart.Controls.Add($Lbl2)

$GridP = New-Object System.Windows.Forms.DataGridView; $GridP.Location="15,40"; $GridP.Size="1195,145"; $GridP.BorderStyle="None"
$GridP.BackgroundColor=$T.GridBg; $GridP.ForeColor="Black"
$GridP.AllowUserToAddRows=$false; $GridP.RowHeadersVisible=$false; $GridP.SelectionMode="FullRowSelect"; $GridP.MultiSelect=$false; $GridP.ReadOnly=$true; $GridP.AutoSizeColumnsMode="Fill"
$GridP.Columns.Add("Let","Ltr"); $GridP.Columns[0].Width=50
$GridP.Columns.Add("Lab","Label"); $GridP.Columns[1].FillWeight=120
$GridP.Columns.Add("FS","FS"); $GridP.Columns[2].Width=60
$GridP.Columns.Add("Tot","Total"); $GridP.Columns[3].Width=80
$GridP.Columns.Add("Used","Used"); $GridP.Columns[4].Width=80
$GridP.Columns.Add("PUse","%"); $GridP.Columns[5].Width=60
$GridP.Columns.Add("Type","Type"); $GridP.Columns[6].Width=100
$GridP.Columns.Add("Stat","Status"); $GridP.Columns[7].Width=100
$PnlPart.Controls.Add($GridP)

# 3. ACTION TABS
$TabControl = New-Object System.Windows.Forms.TabControl; $TabControl.Location="20,500"; $TabControl.Size="1225,300"; $TabControl.Font=$F_Head
$Form.Controls.Add($TabControl)

# Helper function for Tabs
function Add-Page ($Title, $BG) { $p=New-Object System.Windows.Forms.TabPage; $p.Text="  $Title  "; $p.BackColor=$BG; $p.ForeColor=$T.TextMain; $TabControl.Controls.Add($p); return $p }

# --- TAB 1: BASIC & MANAGEMENT ---
$TabBasic = Add-Page "🛠️ QUẢN LÝ CƠ BẢN" $T.BgPanel
Add-CyberBtn $TabBasic "LÀM MỚI (REFRESH)" "♻️" 30 30 200 "Refresh" "Primary"
Add-CyberBtn $TabBasic "CHECK DISK (CHKDSK)" "🚑" 250 30 200 "ChkDsk"
Add-CyberBtn $TabBasic "ĐỔI TÊN (LABEL)" "🏷️" 470 30 200 "Label"
Add-CyberBtn $TabBasic "ĐỔI KÝ TỰ (LETTER)" "🔠" 690 30 200 "Letter"

Add-CyberBtn $TabBasic "FORMAT PARTITION" "🧹" 30 100 200 "Format" "Danger"
Add-CyberBtn $TabBasic "XÓA PHÂN VÙNG" "❌" 250 100 200 "Delete" "Danger"
Add-CyberBtn $TabBasic "WIPE DATA (XÓA SẠCH)" "💀" 470 100 200 "Wipe" "Danger"
Add-CyberBtn $TabBasic "SET ACTIVE" "⚡" 690 100 200 "Active"

# --- TAB 2: RESCUE & ADVANCED ---
$TabRescue = Add-Page "🚑 CỨU HỘ & NÂNG CAO" $T.BgPanel
Add-CyberBtn $TabRescue "FIX BOOT (AUTO BCD)" "🛠️" 30 30 250 "FixBoot" "Rescue"
Add-CyberBtn $TabRescue "HIỆN Ổ ẨN / EFI (MOUNT)" "🔓" 300 30 250 "MountEFI" "Rescue"
Add-CyberBtn $TabRescue "GỠ WRITE PROTECT (USB)" "🖊️" 570 30 250 "RemoveRO" "Rescue"
Add-CyberBtn $TabRescue "CONVERT GPT (NO DATA)" "🔄" 840 30 250 "ConvertGPT" "Danger"

Add-CyberBtn $TabRescue "SURFACE TEST (BAD SECTOR)" "🔍" 30 100 250 "Surface" "Monitor"
Add-CyberBtn $TabRescue "REBUILD MBR" "🧱" 300 100 250 "RebuildMBR" "Rescue"

# --- TAB 3: MONITORING & BENCHMARK ---
$TabMon = Add-Page "📊 SỨC KHỎE & TỐC ĐỘ" $T.BgPanel
Add-CyberBtn $TabMon "XEM CHI TIẾT S.M.A.R.T" "📋" 30 30 250 "SmartDetail" "Monitor"
Add-CyberBtn $TabMon "BENCHMARK TỐC ĐỘ (WINSAT)" "🚀" 300 30 250 "Benchmark" "Monitor"

$LblInfo = New-Object System.Windows.Forms.Label; $LblInfo.Text="INFO: Chọn Phân vùng để thao tác."; $LblInfo.Location="30, 200"; $LblInfo.AutoSize=$true; $LblInfo.ForeColor=$T.Cyan; $TabMon.Controls.Add($LblInfo)

# ==================== LOGIC CORE (HYBRID ENGINE) ====================

function Load-Data {
    $GridD.Rows.Clear(); $GridP.Rows.Clear(); $Global:SelectedPart = $null; $Global:SelectedDisk = $null
    $Form.Cursor = "WaitCursor"; $Form.Refresh()
    
    $Engine = "Modern (Get-PhysicalDisk)"
    
    # 1. TRY MODERN STORAGE API (Lấy được S.M.A.R.T)
    try {
        $PhyDisks = Get-PhysicalDisk -ErrorAction Stop | Sort-Object DeviceId
        if (!$PhyDisks) { throw "Empty" }
        
        foreach ($D in $PhyDisks) {
            $GB = [Math]::Round($D.Size / 1GB, 1).ToString() + " GB"
            $Type = if ($D.PartitionStyle -eq "Uninitialized") { "RAW" } else { $D.PartitionStyle }
            
            # SMART Status Logic
            $Health = $D.HealthStatus.ToString()
            if ($Health -eq "Healthy") { $HealthStr = "Good (Healthy)" } else { $HealthStr = "WARNING: $Health" }
            
            $Row = $GridD.Rows.Add($D.DeviceId, $D.FriendlyName, $Type, $GB, $D.BusType, $HealthStr)
            $GridD.Rows[$Row].Tag = @{ ID=$D.DeviceId; Mode="Modern"; Obj=$D }
            
            if ($Health -ne "Healthy") { $GridD.Rows[$Row].DefaultCellStyle.ForeColor = "Red" }
        }
    } catch {
        # 2. FALLBACK TO WMI (Nếu lỗi hoặc máy cũ)
        $Engine = "Legacy (WMI Fallback)"
        try {
            $WmiDisks = Get-WmiObject Win32_DiskDrive
            foreach ($D in $WmiDisks) {
                $GB = [Math]::Round($D.Size / 1GB, 1).ToString() + " GB"
                $PCount = $D.Partitions; $Type = if ($PCount -gt 4) { "GPT (Auto)" } else { "MBR/GPT" }
                
                $Row = $GridD.Rows.Add($D.Index, $D.Model, $Type, $GB, $D.InterfaceType, "Unknown (WMI)")
                $GridD.Rows[$Row].Tag = @{ ID=$D.Index; Mode="WMI"; Obj=$D }
            }
        } catch { [System.Windows.Forms.MessageBox]::Show("CRITICAL ERROR: Không tìm thấy ổ cứng nào!", "Lỗi") }
    }
    
    $PnlDisk.Controls[0].Text = "1. DANH SÁCH Ổ CỨNG (Engine: $Engine)"
    if ($GridD.Rows.Count -gt 0) { $GridD.Rows[0].Selected = $true; Load-Partitions $GridD.Rows[0].Tag }
    $Form.Cursor = "Default"
}

function Load-Partitions ($Tag) {
    $GridP.Rows.Clear(); $Global:SelectedDisk = $Tag
    $Global:SelectedPart = $null
    $Did = $Tag.ID
    
    # Logic nạp Partition cũng phải Hybrid để tương thích
    try {
        # Ưu tiên Get-Partition vì nó dễ dùng hơn
        $Parts = Get-Partition -DiskNumber $Did -ErrorAction Stop | Sort-Object PartitionNumber
        foreach ($P in $Parts) {
            $Vol = $P | Get-Volume -ErrorAction SilentlyContinue
            
            $Let = if($P.DriveLetter){$P.DriveLetter}else{""}
            $Lab = if($Vol){$Vol.FileSystemLabel}else{"[Hidden/System]"}
            $FS  = if($Vol){$Vol.FileSystem}else{$P.Type}
            $Total = [Math]::Round($P.Size / 1GB, 2)
            
            $Used="-"; $PUse="-"; $Stat="OK"
            if ($Vol) {
                $UsedVal = $Vol.Size - $Vol.SizeRemaining
                $Used = [Math]::Round($UsedVal / 1GB, 2).ToString() + " GB"
                if ($Vol.Size -gt 0) { $PUse = ([Math]::Round(($UsedVal / $Vol.Size)*100)).ToString() + "%" }
            }
            
            $Row = $GridP.Rows.Add($Let, $Lab, $FS, "$Total GB", $Used, $PUse, $P.GptType, $Stat)
            $GridP.Rows[$Row].Tag = @{ Did=$Did; PartID=$P.PartitionNumber; Let=$Let; Lab=$Lab; Obj=$P }
        }
    } catch {
        # Fallback WMI Partition
        try {
            $Query = "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='\\.\PHYSICALDRIVE$Did'} WHERE AssocClass=Win32_DiskDriveToDiskPartition"
            $Parts = @(Get-WmiObject -Query $Query | Sort-Object StartingOffset)
            $RealID = 1
            foreach ($P in $Parts) {
                $LogDisk = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($P.DeviceID)'} WHERE AssocClass=Win32_LogicalDiskToPartition"
                $Total = [Math]::Round($P.Size / 1GB, 2)
                
                if ($LogDisk) {
                    $Let=$LogDisk.DeviceID; $Lab=$LogDisk.VolumeName; $FS=$LogDisk.FileSystem
                    $Row = $GridP.Rows.Add($Let, $Lab, $FS, "$Total GB", "-", "-", $P.Type, "OK")
                } else {
                    $Row = $GridP.Rows.Add("", "[Hidden]", "RAW", "$Total GB", "-", "-", $P.Type, "Sys")
                }
                $GridP.Rows[$Row].Tag = @{ Did=$Did; PartID=$RealID; Let=$Let; Lab=$Lab }
                $RealID++
            }
        } catch {}
    }
}

# EVENTS
$GridD.Add_CellClick({ if($GridD.SelectedRows.Count -gt 0){ Load-Partitions $GridD.SelectedRows[0].Tag } })
$GridP.Add_CellClick({ if($GridP.SelectedRows.Count -gt 0){ $Global:SelectedPart = $GridP.SelectedRows[0].Tag; $LblInfo.Text="SELECTED: Partition $($Global:SelectedPart.PartID) - $($Global:SelectedPart.Lab)" } })

# ==================== ACTION LOGIC (THE POWER) ====================

function Run-DP ($Cmd) {
    $F = "$env:TEMP\dp_script.txt"; [IO.File]::WriteAllText($F, $Cmd)
    Start-Process "diskpart" "/s `"$F`"" -Wait -NoNewWindow
    Remove-Item $F -ErrorAction SilentlyContinue; Load-Data
}

function Run-Action ($Act) {
    if ($Act -eq "Refresh") { Load-Data; return }
    
    # Global Checks
    $D = $Global:SelectedDisk
    $P = $Global:SelectedPart
    
    # --- DISK LEVEL ACTIONS ---
    if ($Act -eq "ConvertGPT") {
        if (!$D) { return }
        if ([System.Windows.Forms.MessageBox]::Show("Convert Disk $($D.ID) sang GPT?`nDU LIỆU SẼ MẤT HẾT (CLEAN)!", "Cảnh báo", "YesNo", "Error") -eq "Yes") {
            Run-DP "sel disk $($D.ID)`nclean`nconvert gpt"
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
        if ($D.Mode -eq "WMI") { [System.Windows.Forms.MessageBox]::Show("Chế độ WMI không hỗ trợ xem chi tiết S.M.A.R.T.", "Thông báo"); return }
        try {
            $Info = Get-PhysicalDisk -DeviceId $D.ID | Select *
            $Info | Out-GridView -Title "S.M.A.R.T Details for Disk $($D.ID)"
        } catch { [System.Windows.Forms.MessageBox]::Show("Không đọc được chi tiết.", "Lỗi") }
        return
    }

    # --- PARTITION LEVEL ACTIONS ---
    if (!$P) { [System.Windows.Forms.MessageBox]::Show("Vui lòng chọn 1 phân vùng ở danh sách dưới!", "Chưa chọn"); return }
    $Did = $P.Did; $Pid = $P.PartID; $Let = $P.Let

    switch ($Act) {
        "Format" {
            $Lab = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập tên ổ mới (Label):", "Format", "NewVolume")
            if ($Lab) { 
                if([System.Windows.Forms.MessageBox]::Show("Format Partition $Pid? Dữ liệu sẽ mất!", "Confirm", "YesNo", "Warning") -eq "Yes") {
                    Run-DP "sel disk $Did`nsel part $Pid`nformat fs=ntfs label=`"$Lab`" quick" 
                }
            }
        }
        "Wipe" {
            if([System.Windows.Forms.MessageBox]::Show("WIPE DATA (XÓA SẠCH)?`nHành động này sẽ ghi đè số 0 (Zero-fill) lên toàn bộ phân vùng.`nKHÔNG THỂ KHÔI PHỤC DỮ LIỆU SAU KHI CHẠY!", "DANGER", "YesNo", "Error") -eq "Yes") {
                $Form.Cursor = "WaitCursor"
                if ($Let) { Format-Volume -DriveLetter $Let -FileSystem NTFS -Full -Force | Out-Null }
                else { [System.Windows.Forms.MessageBox]::Show("Partition cần có ký tự (Letter) để Wipe.", "Info") }
                $Form.Cursor = "Default"
                [System.Windows.Forms.MessageBox]::Show("Wipe Complete!", "Done")
            }
        }
        "Delete" {
            if([System.Windows.Forms.MessageBox]::Show("Xóa phân vùng $Pid?", "Confirm", "YesNo", "Error") -eq "Yes") {
                Run-DP "sel disk $Did`nsel part $Pid`ndelete partition override"
            }
        }
        "Label" {
            $N=[Microsoft.VisualBasic.Interaction]::InputBox("Nhập tên mới:", "Rename", $P.Lab)
            if ($N) { if($Let){ Set-Volume -DriveLetter $Let -NewFileSystemLabel $N; Load-Data } }
        }
        "Letter" {
            $NewL=[Microsoft.VisualBasic.Interaction]::InputBox("Nhập ký tự mới (VD: Z):", "Change Letter", "")
            if ($NewL -match "^[A-Z]$") { Run-DP "sel disk $Did`nsel part $Pid`nassign letter=$NewL" }
        }
        "Active" { Run-DP "sel disk $Did`nsel part $Pid`nactive" }
        "ChkDsk" { if($Let){ Start-Process "cmd" "/k chkdsk $Let /f /x" } else { [System.Windows.Forms.MessageBox]::Show("Cần có ký tự ổ đĩa!", "Lỗi") } }
        "Surface" { 
            if($Let){ Start-Process "cmd" "/k title SURFACE TEST & echo DANG QUET BAD SECTOR O $Let ... & chkdsk $Let /r" } 
            else { [System.Windows.Forms.MessageBox]::Show("Cần ký tự ổ đĩa!", "Lỗi") }
        }
        "FixBoot" {
            if($Let) {
                Start-Process "cmd" "/k bcdboot $Let\Windows /s $Let /f ALL & echo DA NAP BOOT XONG! & pause"
            } else { [System.Windows.Forms.MessageBox]::Show("Chọn ổ cài Windows (C:) để nạp boot!", "Hướng dẫn") }
        }
        "MountEFI" {
            # Auto find ESP/System partition on selected disk
            $EfiPart = Get-Partition -DiskNumber $Did | Where-Object { $_.GptType -eq "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" -or $_.Type -eq "System" }
            if ($EfiPart) {
                Set-Partition -DiskNumber $Did -PartitionNumber $EfiPart.PartitionNumber -NewDriveLetter "Z" -ErrorAction SilentlyContinue
                [System.Windows.Forms.MessageBox]::Show("Đã hiện phân vùng EFI thành ổ Z:", "Success")
                Load-Data
            } else { [System.Windows.Forms.MessageBox]::Show("Không tìm thấy phân vùng EFI trên Disk $Did", "Lỗi") }
        }
        "Benchmark" {
            if ($Let) {
                $Form.Cursor = "WaitCursor"
                Start-Process "winsat" -ArgumentList "disk -drive $Let -ran -read -count 1" -Wait
                $Form.Cursor = "Default"
                [System.Windows.Forms.MessageBox]::Show("Đã test xong! Xem kết quả trong cửa sổ CMD vừa tắt (Hoặc mở Event Viewer).`n(Tính năng này chỉ gọi Winsat cơ bản)", "Info")
            } else { [System.Windows.Forms.MessageBox]::Show("Chọn phân vùng có ký tự!", "Lỗi") }
        }
    }
}

# --- INIT ---
$Timer = New-Object System.Windows.Forms.Timer; $Timer.Interval=500; $Timer.Add_Tick({$Timer.Stop(); Load-Data}); $Timer.Start()
$Form.ShowDialog() | Out-Null

} catch {
    Write-Host "Fatal Error: $($_.Exception.Message)" -ForegroundColor Red; Read-Host
}
