<#
    DISK MANAGER PRO - PHAT TAN PC (V13.0 TITANIUM EDITION)
    Feature: Full Functional Actions + Custom Gradient UI
    Fix: Console Stay Open (Chống thoát) + WMI Smart Indexing
#>

# --- 0. KEEP CONSOLE OPEN WRAPPER ---
try {

# --- 1. LOGGING SETUP ---
function Log ($Type, $Msg) { 
    $Color = switch($Type){"INFO"{"Cyan"}"WARN"{"Yellow"}"ERR"{"Red"}Default{"White"}}
    Write-Host "[$([DateTime]::Now.ToString('HH:mm:ss'))] [$Type] $Msg" -ForegroundColor $Color
}
Clear-Host
Log "INFO" "Dang khoi dong Titanium Engine..."

# --- 2. ADMIN CHECK ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Log "WARN" "Chua chay quyen Admin. Dang khoi dong lai..."
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# --- 3. LOAD LIBRARIES ---
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- THEME ENGINE (GRADIENT CYBERPUNK) ---
$T = @{
    BgForm      = [System.Drawing.Color]::FromArgb(15, 15, 20)
    BgPanel     = [System.Drawing.Color]::FromArgb(25, 25, 30)
    TextMain    = [System.Drawing.Color]::White
    TextMuted   = [System.Drawing.Color]::FromArgb(160, 160, 160)
    NeonBlue    = [System.Drawing.Color]::FromArgb(0, 190, 255)
    NeonRed     = [System.Drawing.Color]::FromArgb(255, 50, 80)
    NeonGreen   = [System.Drawing.Color]::FromArgb(50, 255, 150)
    
    # Gradient Buttons
    BtnNormal1  = [System.Drawing.Color]::FromArgb(40, 40, 50)
    BtnNormal2  = [System.Drawing.Color]::FromArgb(60, 60, 70)
    BtnDanger1  = [System.Drawing.Color]::FromArgb(150, 0, 0)
    BtnDanger2  = [System.Drawing.Color]::FromArgb(255, 80, 80)
}

$Global:SelectedDisk = $null
$Global:SelectedPart = $null

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "DISK MANAGER PRO V13.0 - TITANIUM"
$Form.Size = New-Object System.Drawing.Size(1200, 800)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $T.BgForm
$Form.ForeColor = $T.TextMain
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# -- FONTS --
$F_Logo = New-Object System.Drawing.Font("Impact", 24)
$F_Btn  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$F_Norm = New-Object System.Drawing.Font("Segoe UI", 9)

# ==================== CUSTOM DRAWING (VẼ GIAO DIỆN) ====================

# 1. Gradient Panel Paint
$PaintPanel = {
    param($s, $e)
    $Rect = $s.ClientRectangle
    $Br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($Rect, [System.Drawing.Color]::FromArgb(35,35,40), [System.Drawing.Color]::FromArgb(20,20,25), 90)
    $e.Graphics.FillRectangle($Br, $Rect)
    $Pen = New-Object System.Drawing.Pen($T.NeonBlue, 1)
    $e.Graphics.DrawRectangle($Pen, 0, 0, $s.Width-1, $s.Height-1)
    $Br.Dispose(); $Pen.Dispose()
}

# 2. Custom Button Function
function Add-TitanBtn ($Parent, $Txt, $Icon, $X, $Y, $W, $Tag, $IsDanger=$false) {
    $Btn = New-Object System.Windows.Forms.Label 
    $Btn.Text = "$Icon  $Txt"
    $Btn.Tag = @{ Act=$Tag; Hover=$false; Danger=$IsDanger }
    $Btn.Location = "$X, $Y"; $Btn.Size = "$W, 45"
    $Btn.Font = $F_Btn; $Btn.TextAlign = "MiddleCenter"
    $Btn.ForeColor = $T.TextMain; $Btn.Cursor = "Hand"
    
    $Btn.Add_MouseEnter({ $this.Tag.Hover=$true; $this.Invalidate() })
    $Btn.Add_MouseLeave({ $this.Tag.Hover=$false; $this.Invalidate() })
    $Btn.Add_Click({ Run-Action $this.Tag.Act })
    
    $Btn.Add_Paint({
        param($s, $e)
        $R = $s.ClientRectangle
        $C1 = if($s.Tag.Danger){$T.BtnDanger1}else{$T.BtnNormal1}
        $C2 = if($s.Tag.Danger){$T.BtnDanger2}else{$T.BtnNormal2}
        
        if($s.Tag.Hover){ $C1=[System.Windows.Forms.ControlPaint]::Light($C1); $C2=[System.Windows.Forms.ControlPaint]::Light($C2) }
        
        $Br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($R, $C1, $C2, 45)
        $e.Graphics.FillRectangle($Br, $R)
        $Pen = New-Object System.Drawing.Pen($C2, 1)
        $e.Graphics.DrawRectangle($Pen, 0, 0, $s.Width-1, $s.Height-1)
        
        $Format = New-Object System.Drawing.StringFormat; $Format.Alignment="Center"; $Format.LineAlignment="Center"
        $e.Graphics.DrawString($s.Text, $s.Font, [System.Drawing.Brushes]::White, $R, $Format)
        $Br.Dispose(); $Pen.Dispose()
    })
    $Parent.Controls.Add($Btn)
}

# ==================== MAIN LAYOUT ====================
# HEADER
$LblLogo = New-Object System.Windows.Forms.Label; $LblLogo.Text="TITANIUM DISK MANAGER"; $LblLogo.Font=$F_Logo; $LblLogo.AutoSize=$true; $LblLogo.Location="20,10"; $LblLogo.ForeColor=$T.NeonBlue
$Form.Controls.Add($LblLogo)

# 1. DISK LIST PANEL
$PnlDisk = New-Object System.Windows.Forms.Panel; $PnlDisk.Location="20,70"; $PnlDisk.Size="1145,220"; $PnlDisk.Add_Paint($PaintPanel)
$Form.Controls.Add($PnlDisk)

$Lbl1 = New-Object System.Windows.Forms.Label; $Lbl1.Text="DANH SÁCH Ổ CỨNG VẬT LÝ"; $Lbl1.Location="15,10"; $Lbl1.AutoSize=$true; $Lbl1.ForeColor=$T.TextMuted; $Lbl1.BackColor=[System.Drawing.Color]::Transparent; $PnlDisk.Controls.Add($Lbl1)

$GridD = New-Object System.Windows.Forms.DataGridView; $GridD.Location="15,35"; $GridD.Size="1115,170"; $GridD.BorderStyle="None"
$GridD.BackgroundColor=[System.Drawing.Color]::FromArgb(30,30,35); $GridD.ForeColor="Black" # Fix text color
$GridD.AllowUserToAddRows=$false; $GridD.RowHeadersVisible=$false; $GridD.SelectionMode="FullRowSelect"; $GridD.MultiSelect=$false; $GridD.ReadOnly=$true; $GridD.AutoSizeColumnsMode="Fill"
$GridD.Columns.Add("ID","Disk #"); $GridD.Columns[0].Width=60
$GridD.Columns.Add("Mod","Model"); $GridD.Columns[1].FillWeight=150
$GridD.Columns.Add("Size","Dung Lượng"); $GridD.Columns[2].Width=120
$GridD.Columns.Add("Type","Loại (MBR/GPT)"); $GridD.Columns[3].Width=120
$GridD.Columns.Add("Stat","Trạng Thái"); $GridD.Columns[4].Width=100
$PnlDisk.Controls.Add($GridD)

# 2. PARTITION LIST PANEL
$PnlPart = New-Object System.Windows.Forms.Panel; $PnlPart.Location="20,305"; $PnlPart.Size="1145,220"; $PnlPart.Add_Paint($PaintPanel)
$Form.Controls.Add($PnlPart)

$Lbl2 = New-Object System.Windows.Forms.Label; $Lbl2.Text="CHI TIẾT PHÂN VÙNG"; $Lbl2.Location="15,10"; $Lbl2.AutoSize=$true; $Lbl2.ForeColor=$T.TextMuted; $Lbl2.BackColor=[System.Drawing.Color]::Transparent; $PnlPart.Controls.Add($Lbl2)

$GridP = New-Object System.Windows.Forms.DataGridView; $GridP.Location="15,35"; $GridP.Size="1115,170"; $GridP.BorderStyle="None"
$GridP.BackgroundColor=[System.Drawing.Color]::FromArgb(30,30,35); $GridP.ForeColor="Black"
$GridP.AllowUserToAddRows=$false; $GridP.RowHeadersVisible=$false; $GridP.SelectionMode="FullRowSelect"; $GridP.MultiSelect=$false; $GridP.ReadOnly=$true; $GridP.AutoSizeColumnsMode="Fill"
$GridP.Columns.Add("Let","Ký Tự"); $GridP.Columns[0].Width=60
$GridP.Columns.Add("Lab","Label"); $GridP.Columns[1].FillWeight=150
$GridP.Columns.Add("FS","FS"); $GridP.Columns[2].Width=80
$GridP.Columns.Add("Tot","Tổng"); $GridP.Columns[3].Width=100
$GridP.Columns.Add("Fre","Còn Lại"); $GridP.Columns[4].Width=100
$GridP.Columns.Add("Sta","Trạng Thái"); $GridP.Columns[5].Width=100
$PnlPart.Controls.Add($GridP)

# 3. TOOLS PANEL
$PnlTool = New-Object System.Windows.Forms.Panel; $PnlTool.Location="20,540"; $PnlTool.Size="1145,200"; $PnlTool.Add_Paint($PaintPanel)
$Form.Controls.Add($PnlTool)

$LblInfo = New-Object System.Windows.Forms.Label; $LblInfo.Text="ĐANG CHỌN: [Chưa chọn]"; $LblInfo.Font=$F_Head; $LblInfo.ForeColor=$T.NeonGreen; $LblInfo.AutoSize=$true; $LblInfo.Location="15,15"; $LblInfo.BackColor=[System.Drawing.Color]::Transparent; $PnlTool.Controls.Add($LblInfo)

# Buttons
Add-TitanBtn $PnlTool "LÀM MỚI" "♻️" 30 50 180 "Refresh"
Add-TitanBtn $PnlTool "CHECK DISK" "🚑" 230 50 180 "ChkDsk"
Add-TitanBtn $PnlTool "CONVERT GPT" "🔄" 430 50 180 "Convert"
Add-TitanBtn $PnlTool "NẠP BOOT" "🛠️" 630 50 180 "FixBoot"

Add-TitanBtn $PnlTool "ĐỔI KÝ TỰ" "🔠" 30 110 180 "Letter"
Add-TitanBtn $PnlTool "ĐỔI TÊN" "🏷️" 230 110 180 "Label"
Add-TitanBtn $PnlTool "SET ACTIVE" "⚡" 430 110 180 "Active"

Add-TitanBtn $PnlTool "FORMAT" "🧹" 850 50 250 "Format" $true
Add-TitanBtn $PnlTool "XÓA PARTITION" "❌" 850 110 250 "Delete" $true

# ==================== ENGINE (WMI STABLE) ====================
function Load-Data {
    Log "INFO" "Reloading data..."
    $GridD.Rows.Clear(); $GridP.Rows.Clear(); $Global:SelectedPart = $null
    $LblInfo.Text = "ĐANG TẢI DỮ LIỆU..."
    $Form.Cursor = "WaitCursor"; $Form.Refresh()
    
    try {
        $Disks = @(Get-WmiObject Win32_DiskDrive)
        foreach ($D in $Disks) {
            # Tính Size
            $GB = [Math]::Round($D.Size / 1GB, 1).ToString() + " GB"
            # Thêm vào Grid Disk
            $Row = $GridD.Rows.Add($D.Index, $D.Model, $GB, "MBR/GPT", $D.Status)
            $GridD.Rows[$Row].Tag = $D
        }
    } catch { Log "ERR" "Loi Load Disk: $($_.Exception.Message)" }
    
    if ($GridD.Rows.Count -gt 0) {
        $GridD.Rows[0].Selected = $true
        Load-Partitions $GridD.Rows[0].Tag
    }
    $Form.Cursor = "Default"
    $LblInfo.Text = "SẴN SÀNG"
}

function Load-Partitions ($DiskObj) {
    $GridP.Rows.Clear(); $Global:SelectedDisk = $DiskObj
    Log "INFO" "Loading partitions for Disk $($DiskObj.Index)"
    
    try {
        # --- THUẬT TOÁN SORTING (QUAN TRỌNG ĐỂ KHỚP DISKPART) ---
        $Query = "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($DiskObj.DeviceID)'} WHERE AssocClass=Win32_DiskDriveToDiskPartition"
        $Parts = @(Get-WmiObject -Query $Query | Sort-Object StartingOffset)
        
        $RealID = 1 # Diskpart ID luôn bắt đầu từ 1
        foreach ($P in $Parts) {
            $LogQuery = "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($P.DeviceID)'} WHERE AssocClass=Win32_LogicalDiskToPartition"
            $LogDisk = Get-WmiObject -Query $LogQuery
            $Total = [Math]::Round($P.Size / 1GB, 2)
            
            if ($LogDisk) {
                $Let=$LogDisk.DeviceID; $Lab=$LogDisk.VolumeName; $FS=$LogDisk.FileSystem
                $Free=[Math]::Round($LogDisk.FreeSpace / 1GB, 2)
                $Row = $GridP.Rows.Add($Let, $Lab, $FS, "$Total GB", "$Free GB", "OK")
            } else {
                $Let=$null; $Lab="[Hidden]"; $FS="RAW"
                $Row = $GridP.Rows.Add("", "[Hidden/System]", "RAW", "$Total GB", "-", $P.Type)
            }
            
            # Lưu RealID để dùng cho lệnh Diskpart
            $GridP.Rows[$Row].Tag = @{ Did=$DiskObj.Index; Pid=$RealID; Let=$Let; Lab=$Lab }
            $RealID++ 
        }
    } catch { Log "ERR" "Loi Partition: $($_.Exception.Message)" }
}

$GridD.Add_SelectionChanged({ if($GridD.SelectedRows.Count -gt 0){ Load-Partitions $GridD.SelectedRows[0].Tag } })
$GridP.Add_SelectionChanged({ 
    if($GridP.SelectedRows.Count -gt 0){ 
        $Global:SelectedPart = $GridP.SelectedRows[0].Tag 
        $P = $Global:SelectedPart
        $Name = if($P.Let){"Ổ $($P.Let)"}else{"PARTITION $($P.Pid)"}
        $LblInfo.Text = "ĐANG CHỌN: $Name (Disk $($P.Did))"
    }
})

# ==================== ACTIONS HANDLER ====================
function Run-DP ($Cmd) {
    Log "INFO" "Exec Diskpart: $Cmd"
    $F = "$env:TEMP\dp.txt"; [IO.File]::WriteAllText($F, $Cmd)
    Start-Process "diskpart" "/s `"$F`"" -Wait -NoNewWindow
    Remove-Item $F; Load-Data
}

function Create-SubForm ($Title, $H) {
    $F = New-Object System.Windows.Forms.Form
    $F.Text=$Title; $F.Size="400, $H"; $F.StartPosition="CenterParent"; $F.FormBorderStyle="FixedToolWindow"
    $F.BackColor=[System.Drawing.Color]::FromArgb(40,40,45); $F.ForeColor="White"
    return $F
}

function Run-Action ($Act) {
    if ($Act -eq "Refresh") { Load-Data; return }
    if ($Act -eq "FixBoot") { Start-Process "cmd" "/c bcdboot C:\Windows /s C: /f ALL & pause"; return }
    
    $P = $Global:SelectedPart
    if (!$P) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn phân vùng!", "Lỗi"); return }
    $Did = $P.Did; $Pid = $P.Pid; $Let = $P.Let; $Lab = $P.Lab

    switch ($Act) {
        "Format" {
            $F = Create-SubForm "FORMAT PARTITION $Pid" 250
            $L1 = New-Object System.Windows.Forms.Label; $L1.Text="Nhập tên ổ (Label):"; $L1.Location="20,20"; $L1.AutoSize=$true; $F.Controls.Add($L1)
            $T1 = New-Object System.Windows.Forms.TextBox; $T1.Text=$Lab; $T1.Location="20,45"; $T1.Size="340,25"; $F.Controls.Add($T1)
            $L2 = New-Object System.Windows.Forms.Label; $L2.Text="Hệ thống tệp (File System):"; $L2.Location="20,80"; $L2.AutoSize=$true; $F.Controls.Add($L2)
            $C1 = New-Object System.Windows.Forms.ComboBox; $C1.Items.AddRange(@("NTFS","FAT32")); $C1.SelectedIndex=0; $C1.Location="20,105"; $C1.Size="340,25"; $F.Controls.Add($C1)
            $B1 = New-Object System.Windows.Forms.Button; $B1.Text="FORMAT NGAY"; $B1.Location="20,150"; $B1.Size="340,40"; $B1.BackColor="Red"; $B1.ForeColor="White"; $B1.DialogResult="OK"; $F.Controls.Add($B1)
            
            if($F.ShowDialog() -eq "OK"){ Run-DP "sel disk $Did`nsel part $Pid`nformat fs=$($C1.SelectedItem) label=`"$($T1.Text)`" quick" }
        }
        "Letter" {
            $F = Create-SubForm "ĐỔI KÝ TỰ" 180
            $L1 = New-Object System.Windows.Forms.Label; $L1.Text="Chọn ký tự mới:"; $L1.Location="20,20"; $L1.AutoSize=$true; $F.Controls.Add($L1)
            $C1 = New-Object System.Windows.Forms.ComboBox; $C1.Location="20,50"; $C1.Size="340,25"; $F.Controls.Add($C1)
            $Used = [IO.DriveInfo]::GetDrives().Name | ForEach { $_.Substring(0,1) }; 65..90 | ForEach { $Char=[char]$_; if ($Used -notcontains $Char) { $C1.Items.Add($Char)|Out-Null } }; if($C1.Items.Count){$C1.SelectedIndex=0}
            $B1 = New-Object System.Windows.Forms.Button; $B1.Text="THAY ĐỔI"; $B1.Location="20,90"; $B1.Size="340,40"; $B1.BackColor="Green"; $B1.ForeColor="White"; $B1.DialogResult="OK"; $F.Controls.Add($B1)
            
            if($F.ShowDialog() -eq "OK"){ Run-DP "sel disk $Did`nsel part $Pid`nassign letter=$($C1.SelectedItem)" }
        }
        "Label" {
            $N=[Microsoft.VisualBasic.Interaction]::InputBox("Nhập tên mới:", "Rename", $Lab)
            if ($N) { if($Let){ cmd /c "label $Let $N"; Load-Data } else { [System.Windows.Forms.MessageBox]::Show("Ổ cần có ký tự để đổi tên!","Lỗi") } }
        }
        "Delete" {
            if ([System.Windows.Forms.MessageBox]::Show("XÓA PHÂN VÙNG $Pid?`nDỮ LIỆU SẼ MẤT!", "CẢNH BÁO", "YesNo", "Error") -eq "Yes") {
                Run-DP "sel disk $Did`nsel part $Pid`ndelete partition override"
            }
        }
        "Active" { Run-DP "sel disk $Did`nsel part $Pid`nactive" }
        "Convert" {
            if ([System.Windows.Forms.MessageBox]::Show("Convert Disk sang GPT? (Cần Clean)", "Hỏi", "YesNo") -eq "Yes") {
                Run-DP "sel disk $Did`nclean`nconvert gpt"
            }
        }
        "ChkDsk" { if($Let){ Start-Process "cmd" "/k chkdsk $Let /f /x" } }
    }
}

# --- INIT ---
$Timer = New-Object System.Windows.Forms.Timer; $Timer.Interval=500; $Timer.Add_Tick({$Timer.Stop(); Load-Data}); $Timer.Start()
$Form.ShowDialog() | Out-Null

} catch {
    # --- ERROR TRAP & PAUSE ---
    Write-Host "`n[CRITICAL ERROR] Da xay ra loi nghiem trong!" -ForegroundColor Red
    Write-Host "Chi tiet: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Script se dung lai tai day de ban doc loi." -ForegroundColor Gray
} finally {
    Write-Host "`n=== DA KET THUC ===" -ForegroundColor Green
    Read-Host "Bam phim Enter de thoat..."
}
