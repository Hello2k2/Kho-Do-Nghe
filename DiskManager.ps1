<#
    DISK MANAGER PRO - PHAT TAN PC (V18.1 - STABLE RGB FIX)
    Status: CRITICAL FIX (DrawString Casting Error)
    Feature: RGB UI, Rescue Tools, Monitor, Anti-Crash
#>

# --- 0. ANTI-CRASH WRAPPER ---
$Global:ErrorLogPath = "$env:USERPROFILE\Desktop\DiskManager_Error.log"
Trap {
    $Err = $_.Exception
    $Msg = "LỖI (CRASH): $($Err.Message)`nLine: $($_.InvocationInfo.ScriptLineNumber)"
    $Log = "[$(Get-Date)] $Msg`n$($Err.StackTrace)"
    $Log | Out-File $Global:ErrorLogPath -Append
    try { [System.Windows.Forms.MessageBox]::Show($Msg, "DEBUG V18.1", "OK", "Error") } catch { Write-Host $Msg -F Red }
    continue 
}

# --- 1. ADMIN CHECK ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- 2. LOAD LIBRARIES ---
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic
$ErrorActionPreference = "SilentlyContinue"

# --- THEME CONFIG (RGB NEON V18.1) ---
$Theme_Dark = @{
    Name        = "Dark Mode (Titanium RGB)"
    BgForm      = [System.Drawing.Color]::FromArgb(15, 15, 20)
    BgPanel     = [System.Drawing.Color]::FromArgb(25, 25, 30)
    GridBg      = [System.Drawing.Color]::FromArgb(20, 20, 22)
    TextMain    = [System.Drawing.Color]::FromArgb(240, 240, 240)
    TextMuted   = [System.Drawing.Color]::FromArgb(160, 160, 160)
    RGB1        = [System.Drawing.Color]::FromArgb(255, 0, 80)   # Neon Red
    RGB2        = [System.Drawing.Color]::FromArgb(0, 200, 255)  # Neon Cyan
    BtnBase     = [System.Drawing.Color]::FromArgb(40, 40, 50)
    BtnHigh     = [System.Drawing.Color]::FromArgb(60, 60, 70)
}

$Theme_Light = @{
    Name        = "Light Mode (Clean RGB)"
    BgForm      = [System.Drawing.Color]::FromArgb(240, 240, 245)
    BgPanel     = [System.Drawing.Color]::FromArgb(255, 255, 255)
    GridBg      = [System.Drawing.Color]::FromArgb(230, 230, 235)
    TextMain    = [System.Drawing.Color]::FromArgb(20, 20, 20)
    TextMuted   = [System.Drawing.Color]::FromArgb(100, 100, 100)
    RGB1        = [System.Drawing.Color]::FromArgb(0, 120, 215)
    RGB2        = [System.Drawing.Color]::FromArgb(0, 180, 100)
    BtnBase     = [System.Drawing.Color]::FromArgb(220, 220, 230)
    BtnHigh     = [System.Drawing.Color]::FromArgb(200, 200, 210)
}

$Global:CurrentTheme = $Theme_Dark
$Global:SelectedDisk = $null
$Global:SelectedPart = $null

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "TITANIUM DISK MANAGER V18.1 (STABLE EDITION)"
$Form.Size = New-Object System.Drawing.Size(1280, 850)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Fonts
$F_Logo = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$F_Head = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$F_Norm = New-Object System.Drawing.Font("Segoe UI", 9)
$F_Btn  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

# ==================== DRAWING LOGIC (FIXED CRASH) ====================

function Apply-Theme {
    $T = $Global:CurrentTheme
    $Form.BackColor = $T.BgForm
    $Form.ForeColor = $T.TextMain
    $LblLogo.ForeColor = $T.RGB2
    
    $Form.Controls | Where-Object { $_ -is [System.Windows.Forms.Panel] } | ForEach-Object { $_.Invalidate() }
    
    $GridD.BackgroundColor = $T.GridBg; $GridP.BackgroundColor = $T.GridBg
    $GridD.DefaultCellStyle.BackColor = $T.GridBg; $GridD.DefaultCellStyle.ForeColor = $T.TextMain
    $GridP.DefaultCellStyle.BackColor = $T.GridBg; $GridP.DefaultCellStyle.ForeColor = $T.TextMain
    $GridD.ColumnHeadersDefaultCellStyle.BackColor = $T.BgPanel; $GridD.ColumnHeadersDefaultCellStyle.ForeColor = $T.TextMain
    $GridP.ColumnHeadersDefaultCellStyle.BackColor = $T.BgPanel; $GridP.ColumnHeadersDefaultCellStyle.ForeColor = $T.TextMain
}

$PaintRGB = {
    param($s, $e)
    $T = $Global:CurrentTheme
    $R = $s.ClientRectangle
    
    $Br = New-Object System.Drawing.SolidBrush($T.BgPanel)
    $e.Graphics.FillRectangle($Br, $R)
    
    $LGB = New-Object System.Drawing.Drawing2D.LinearGradientBrush($R, $T.RGB1, $T.RGB2, 45)
    $Pen = New-Object System.Drawing.Pen($LGB, 2)
    $e.Graphics.DrawRectangle($Pen, 1, 1, $s.Width-2, $s.Height-2)
    
    $Br.Dispose(); $Pen.Dispose(); $LGB.Dispose()
}

# --- CRITICAL FIX: Add-CyberBtn ---
function Add-CyberBtn ($Parent, $Txt, $Icon, $X, $Y, $W, $Tag, $ColorType="Normal") {
    $Btn = New-Object System.Windows.Forms.Label 
    $Btn.Text = "$Icon  $Txt"
    $Btn.Tag = @{ Act=$Tag; Hover=$false; Type=$ColorType }
    $Btn.Location = "$X, $Y"; $Btn.Size = "$W, 45"
    $Btn.Font = $F_Btn; $Btn.TextAlign = "MiddleCenter"
    $Btn.Cursor = "Hand"
    
    $Btn.Add_MouseEnter({ $this.Tag.Hover=$true; $this.Invalidate() })
    $Btn.Add_MouseLeave({ $this.Tag.Hover=$false; $this.Invalidate() })
    $Btn.Add_Click({ Run-Action $this.Tag.Act })
    
    $Btn.Add_Paint({
        param($s, $e)
        $T = $Global:CurrentTheme
        $R = $s.ClientRectangle
        
        # Colors
        $C1 = $T.BtnBase; $C2 = $T.BtnHigh
        $Border = [System.Drawing.Color]::Gray
        
        if ($s.Tag.Type -eq "Danger") { $C1=[System.Drawing.Color]::FromArgb(100,0,0); $C2=[System.Drawing.Color]::FromArgb(150,0,0); $Border=[System.Drawing.Color]::Red }
        if ($s.Tag.Type -eq "Primary") { $C1=[System.Drawing.Color]::FromArgb(0,80,120); $C2=[System.Drawing.Color]::FromArgb(0,120,180); $Border=$T.RGB2 }
        if ($s.Tag.Hover) { $C1=[System.Windows.Forms.ControlPaint]::Light($C1); $C2=[System.Windows.Forms.ControlPaint]::Light($C2); $Border=$T.RGB2 }
        
        # Draw BG
        $Br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($R, $C1, $C2, 90)
        $e.Graphics.FillRectangle($Br, $R)
        
        # Draw Border
        $Pen = New-Object System.Drawing.Pen($Border, 2)
        $e.Graphics.DrawRectangle($Pen, 1, 1, $s.Width-2, $s.Height-2)
        
        # --- FIX STARTS HERE: Explicitly use RectangleF for DrawString ---
        $RectF = New-Object System.Drawing.RectangleF([float]$R.X, [float]$R.Y, [float]$R.Width, [float]$R.Height)
        $BrushTxt = New-Object System.Drawing.SolidBrush($T.TextMain)
        $Sf = New-Object System.Drawing.StringFormat; $Sf.Alignment="Center"; $Sf.LineAlignment="Center"
        
        $e.Graphics.DrawString($s.Text, $s.Font, $BrushTxt, $RectF, $Sf)
        # --- FIX ENDS HERE ---
        
        $Br.Dispose(); $Pen.Dispose(); $BrushTxt.Dispose()
    })
    $Parent.Controls.Add($Btn)
}

function Toggle-Theme {
    if ($Global:CurrentTheme.Name -match "Dark") { $Global:CurrentTheme = $Theme_Light; $BtnTheme.Text = "☀️ LIGHT MODE" }
    else { $Global:CurrentTheme = $Theme_Dark; $BtnTheme.Text = "🌙 DARK MODE" }
    Apply-Theme
}

# ==================== GUI LAYOUT ====================

# HEADER
$PnlHead = New-Object System.Windows.Forms.Panel; $PnlHead.Dock="Top"; $PnlHead.Height=70; $PnlHead.BackColor=[System.Drawing.Color]::Transparent
$Form.Controls.Add($PnlHead)

$LblLogo = New-Object System.Windows.Forms.Label; $LblLogo.Text="TITANIUM DISK MANAGER V18.1"; $LblLogo.Font=$F_Logo; $LblLogo.AutoSize=$true; $LblLogo.Location="20,10"
$PnlHead.Controls.Add($LblLogo)
$LblSub = New-Object System.Windows.Forms.Label; $LblSub.Text="Ultimate Rescue & Management Tool (Stable Edition)"; $LblSub.Font=$F_Norm; $LblSub.AutoSize=$true; $LblSub.Location="450,25"
$PnlHead.Controls.Add($LblSub)

$BtnTheme = New-Object System.Windows.Forms.Button; $BtnTheme.Text="🌙 DARK MODE"; $BtnTheme.Location="950,30"; $BtnTheme.Size="200,30"; $BtnTheme.FlatStyle="Flat"
$BtnTheme.BackColor=[System.Drawing.Color]::FromArgb(60,60,60); $BtnTheme.ForeColor="White"
$BtnTheme.Add_Click({ Toggle-Theme })
$PnlHead.Controls.Add($BtnTheme)

# 1. DISK PANEL
$PnlDisk = New-Object System.Windows.Forms.Panel; $PnlDisk.Location="20,80"; $PnlDisk.Size="1225,200"; $PnlDisk.Add_Paint($PaintRGB)
$Form.Controls.Add($PnlDisk)
$L1 = New-Object System.Windows.Forms.Label; $L1.Text="1. DANH SÁCH Ổ CỨNG (PHYSICAL DISKS)"; $L1.Location="15,10"; $L1.AutoSize=$true; $L1.Font=$F_Head; $L1.BackColor=[System.Drawing.Color]::Transparent; $PnlDisk.Controls.Add($L1)

$GridD = New-Object System.Windows.Forms.DataGridView; $GridD.Location="15,40"; $GridD.Size="1195,145"; $GridD.BorderStyle="None"
$GridD.AllowUserToAddRows=$false; $GridD.RowHeadersVisible=$false; $GridD.SelectionMode="FullRowSelect"; $GridD.MultiSelect=$false; $GridD.ReadOnly=$true; $GridD.AutoSizeColumnsMode="Fill"
# 5 Cột thêm mới theo yêu cầu
$GridD.Columns.Add("ID","Disk #"); $GridD.Columns[0].Width=50
$GridD.Columns.Add("Mod","Tên Model"); $GridD.Columns[1].FillWeight=150
$GridD.Columns.Add("Type","Loại"); $GridD.Columns[2].Width=80
$GridD.Columns.Add("Size","Dung lượng"); $GridD.Columns[3].Width=90
$GridD.Columns.Add("Bus","Giao tiếp"); $GridD.Columns[4].Width=80
$GridD.Columns.Add("Health","Sức khỏe"); $GridD.Columns[5].Width=100
$GridD.Columns.Add("Parts","Số P.Vùng"); $GridD.Columns[6].Width=70
$GridD.Columns.Add("Status","Trạng thái"); $GridD.Columns[7].Width=90
$PnlDisk.Controls.Add($GridD)

# 2. PARTITION PANEL
$PnlPart = New-Object System.Windows.Forms.Panel; $PnlPart.Location="20,290"; $PnlPart.Size="1225,200"; $PnlPart.Add_Paint($PaintRGB)
$Form.Controls.Add($PnlPart)
$L2 = New-Object System.Windows.Forms.Label; $L2.Text="2. CHI TIẾT PHÂN VÙNG"; $L2.Location="15,10"; $L2.AutoSize=$true; $L2.Font=$F_Head; $L2.BackColor=[System.Drawing.Color]::Transparent; $PnlPart.Controls.Add($L2)

$GridP = New-Object System.Windows.Forms.DataGridView; $GridP.Location="15,40"; $GridP.Size="1195,145"; $GridP.BorderStyle="None"
$GridP.AllowUserToAddRows=$false; $GridP.RowHeadersVisible=$false; $GridP.SelectionMode="FullRowSelect"; $GridP.MultiSelect=$false; $GridP.ReadOnly=$true; $GridP.AutoSizeColumnsMode="Fill"
# 5 Cột thêm mới cho phân vùng
$GridP.Columns.Add("Let","Ký tự"); $GridP.Columns[0].Width=50
$GridP.Columns.Add("Lab","Nhãn"); $GridP.Columns[1].FillWeight=100
$GridP.Columns.Add("FS","Định dạng"); $GridP.Columns[2].Width=70
$GridP.Columns.Add("Tot","Tổng (GB)"); $GridP.Columns[3].Width=80
$GridP.Columns.Add("Used","Đã dùng"); $GridP.Columns[4].Width=80
$GridP.Columns.Add("Free","Trống"); $GridP.Columns[5].Width=80
$GridP.Columns.Add("PUse","%"); $GridP.Columns[6].Width=60
$GridP.Columns.Add("Type","Kiểu"); $GridP.Columns[7].Width=100
$GridP.Columns.Add("Stat","Active"); $GridP.Columns[8].Width=80
$PnlPart.Controls.Add($GridP)

# 3. ACTION TABS
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
$Tab2 = Add-Page "🚑 CỨU HỘ"
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

$LblInfo = New-Object System.Windows.Forms.Label; $LblInfo.Text="INFO: Vui lòng chọn Ổ đĩa ở bảng trên và Phân vùng ở bảng dưới."; $LblInfo.Location="30, 200"; $LblInfo.AutoSize=$true; $Tab3.Controls.Add($LblInfo)

# ==================== LOGIC CORE (HYBRID V18.1) ====================

function Load-Data {
    $GridD.Rows.Clear(); $GridP.Rows.Clear(); $Global:SelectedPart=$null
    $Form.Cursor = "WaitCursor"; $Form.Refresh()
    
    # 1. MODERN API
    try {
        $PhyDisks = Get-PhysicalDisk -ErrorAction Stop | Sort-Object DeviceId
        foreach ($D in $PhyDisks) {
            $GB = [Math]::Round($D.Size / 1GB, 1).ToString() + " GB"
            $Type = if ($D.PartitionStyle -eq "Uninitialized") { "RAW" } else { $D.PartitionStyle }
            $PartCount = (Get-Partition -DiskNumber $D.DeviceId -ErrorAction SilentlyContinue).Count
            $Health = $D.HealthStatus.ToString()
            $OpStat = $D.OperationalStatus.ToString()
            
            $Row = $GridD.Rows.Add($D.DeviceId, $D.FriendlyName, $Type, $GB, $D.BusType, $Health, $PartCount, $OpStat)
            $GridD.Rows[$Row].Tag = @{ ID=$D.DeviceId; Mode="Modern" }
            if ($Health -ne "Healthy") { $GridD.Rows[$Row].DefaultCellStyle.ForeColor = [System.Drawing.Color]::Red }
        }
    } catch {
        # 2. WMI FALLBACK
        try {
            $Disks = Get-WmiObject Win32_DiskDrive
            foreach ($D in $Disks) {
                $GB = [Math]::Round($D.Size / 1GB, 1).ToString() + " GB"
                $Row = $GridD.Rows.Add($D.Index, $D.Model, "Unknown", $GB, $D.InterfaceType, "Unknown (WMI)", $D.Partitions, $D.Status)
                $GridD.Rows[$Row].Tag = @{ ID=$D.Index; Mode="WMI" }
            }
        } catch { }
    }
    
    if ($GridD.Rows.Count -gt 0) { $GridD.Rows[0].Selected = $true; Load-Partitions $GridD.Rows[0].Tag }
    $Form.Cursor = "Default"
}

function Load-Partitions ($Tag) {
    $GridP.Rows.Clear(); $Global:SelectedDisk = $Tag; $Did = $Tag.ID
    
    try {
        $Parts = Get-Partition -DiskNumber $Did -ErrorAction Stop | Sort-Object PartitionNumber
        foreach ($P in $Parts) {
            $Vol = $P | Get-Volume -ErrorAction SilentlyContinue
            $Let = if($P.DriveLetter){$P.DriveLetter + ":"}else{""}
            $Lab = if($Vol){$Vol.FileSystemLabel}else{"[Hidden]"}
            $FS  = if($Vol){$Vol.FileSystem}else{$P.Type}
            $Total = [Math]::Round($P.Size / 1GB, 2)
            
            $Used="-"; $Free="-"; $PUse="-"
            if ($Vol) {
                $UsedVal = $Vol.Size - $Vol.SizeRemaining
                $Used = [Math]::Round($UsedVal / 1GB, 2)
                $Free = [Math]::Round($Vol.SizeRemaining / 1GB, 2)
                if ($Vol.Size -gt 0) { $PUse = ([Math]::Round(($UsedVal / $Vol.Size)*100)).ToString() + "%" }
            }
            
            $Row = $GridP.Rows.Add($Let, $Lab, $FS, "$Total GB", "$Used GB", "$Free GB", $PUse, $P.GptType, "OK")
            $GridP.Rows[$Row].Tag = @{ Did=$Did; PartID=$P.PartitionNumber; Let=$Let.Replace(":",""); Lab=$Lab }
        }
    } catch {
        # WMI Fallback
        try {
            $Query = "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='\\.\PHYSICALDRIVE$Did'} WHERE AssocClass=Win32_DiskDriveToDiskPartition"
            $Parts = @(Get-WmiObject -Query $Query | Sort-Object StartingOffset)
            $RealID = 1
            foreach ($P in $Parts) {
                $Total = [Math]::Round($P.Size / 1GB, 2)
                $Row = $GridP.Rows.Add("", "[WMI Part]", "RAW", "$Total GB", "-", "-", "-", $P.Type, "OK")
                $GridP.Rows[$Row].Tag = @{ Did=$Did; PartID=$RealID; Let=$null; Lab="[WMI Part]" }
                $RealID++
            }
        } catch {}
    }
}

$GridD.Add_CellClick({ if($GridD.SelectedRows.Count -gt 0){ Load-Partitions $GridD.SelectedRows[0].Tag } })
$GridP.Add_CellClick({ if($GridP.SelectedRows.Count -gt 0){ $Global:SelectedPart = $GridP.SelectedRows[0].Tag; $LblInfo.Text = "Đang chọn: Partition $($Global:SelectedPart.PartID) trên Disk $($Global:SelectedPart.Did)" } })

# ==================== ACTIONS ====================

function Run-DP ($Cmd) {
    $F = "$env:TEMP\dp_cmd.txt"; [IO.File]::WriteAllText($F, $Cmd)
    Start-Process "diskpart" "/s `"$F`"" -Wait -NoNewWindow
}

function Run-Action ($Act) {
    if ($Act -eq "Refresh") { Load-Data; return }
    
    $D = $Global:SelectedDisk
    $P = $Global:SelectedPart
    
    # Disk Actions
    if ($Act -eq "ConvertGPT") {
        if (!$D) { return }
        if ([System.Windows.Forms.MessageBox]::Show("CONVERT DISK $($D.ID) SANG GPT?`nDỮ LIỆU SẼ MẤT HẾT!", "WARNING", "YesNo", "Error") -eq "Yes") {
            Run-DP "sel disk $($D.ID)`nclean`nconvert gpt"; Load-Data
        }
        return
    }
    if ($Act -eq "SmartDetail") {
        if (!$D) { return }
        try { $Info = Get-PhysicalDisk -DeviceId $D.ID | Select *; $Info | Out-GridView -Title "S.M.A.R.T - Disk $($D.ID)" } catch {}
        return
    }

    # Partition Actions
    if (!$P) { [System.Windows.Forms.MessageBox]::Show("Chon phan vung truoc!", "Loi"); return }
    $Did = $P.Did; $PartID = $P.PartID; $Let = $P.Let

    switch ($Act) {
        "Format" {
            $Lab = [Microsoft.VisualBasic.Interaction]::InputBox("Nhan moi:", "Format", "NewVol")
            if ($Lab) { Run-DP "sel disk $Did`nsel part $PartID`nformat fs=ntfs label=`"$Lab`" quick" }
        }
        "Wipe" {
            if ([System.Windows.Forms.MessageBox]::Show("WIPE DATA (XOA TRANG)? KHONG THE KHOI PHUC!", "DANGER", "YesNo", "Error") -eq "Yes") {
                if ($Let) { 
                    $Form.Cursor="WaitCursor"; Format-Volume -DriveLetter $Let -FileSystem NTFS -Full -Force | Out-Null; $Form.Cursor="Default"
                    [System.Windows.Forms.MessageBox]::Show("Done!", "Info")
                } else { [System.Windows.Forms.MessageBox]::Show("Can ky tu o dia de Wipe.", "Info") }
            }
        }
        "Delete" {
            if ([System.Windows.Forms.MessageBox]::Show("Xoa phan vung $PartID?", "Confirm", "YesNo", "Warning") -eq "Yes") {
                Run-DP "sel disk $Did`nsel part $PartID`ndelete partition override"; Load-Data
            }
        }
        "Label" {
            $N=[Microsoft.VisualBasic.Interaction]::InputBox("Ten moi:", "Rename", $P.Lab)
            if ($N) { if($Let){ Set-Volume -DriveLetter $Let -NewFileSystemLabel $N; Load-Data } }
        }
        "Letter" {
            $L=[Microsoft.VisualBasic.Interaction]::InputBox("Ky tu moi (A-Z):", "Change Letter", "")
            if ($L) { Run-DP "sel disk $Did`nsel part $PartID`nassign letter=$L"; Load-Data }
        }
        "Active" { Run-DP "sel disk $Did`nsel part $PartID`nactive" }
        "ChkDsk" { if($Let){ Start-Process "cmd" "/k chkdsk $Let : /f /x" } }
        "Surface" { if($Let){ Start-Process "cmd" "/k chkdsk $Let : /r" } }
        "FixBoot" { if($Let){ Start-Process "cmd" "/k bcdboot $Let :\Windows /s $Let : /f ALL" } }
        "MountEFI" {
            $Efi = Get-Partition -DiskNumber $Did | Where {$_.GptType -eq "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" -or $_.Type -eq "System"}
            if ($Efi) { Set-Partition -DiskNumber $Did -PartitionNumber $Efi.PartitionNumber -NewDriveLetter "Z"; Load-Data }
        }
        "Benchmark" { if($Let){ Start-Process "winsat" "disk -drive $Let -ran -read -count 1" } }
        "Optimize" { if($Let){ Optimize-Volume -DriveLetter $Let -ReTrim -Verbose; [System.Windows.Forms.MessageBox]::Show("Done!") } }
    }
}

# --- INIT ---
Apply-Theme
$Timer = New-Object System.Windows.Forms.Timer; $Timer.Interval=500; $Timer.Add_Tick({$Timer.Stop(); Load-Data}); $Timer.Start()
[System.Windows.Forms.Application]::Run($Form)
