<#
    DISK MANAGER PRO - PHAT TAN PC (V14.1 ULTIMATE STABLE)
    Fix: System.Drawing.Rectangle cast error (Fixed DrawString)
    Style: Gradient Neon + Custom Dialogs
#>

# --- 0. ANTI-CLOSE WRAPPER ---
try {

# --- 1. ADMIN CHECK ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Dang khoi dong lai voi quyen Admin..." -ForegroundColor Cyan
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# --- 2. LOAD LIBRARIES ---
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- THEME CONFIG (CYBERPUNK GRADIENTS) ---
$T = @{
    BgForm      = [System.Drawing.Color]::FromArgb(15, 15, 20)
    BgPanel     = [System.Drawing.Color]::FromArgb(25, 25, 30)
    GridBg      = [System.Drawing.Color]::FromArgb(20, 20, 22)
    TextMain    = [System.Drawing.Color]::White
    TextMuted   = [System.Drawing.Color]::FromArgb(170, 170, 170)
    NeonBlue    = [System.Drawing.Color]::FromArgb(0, 190, 255)
    NeonRed     = [System.Drawing.Color]::FromArgb(255, 50, 80)
    NeonGreen   = [System.Drawing.Color]::FromArgb(50, 255, 150)
    NeonGold    = [System.Drawing.Color]::Gold
    
    # Gradient Buttons
    BtnNorm1    = [System.Drawing.Color]::FromArgb(40, 40, 50)
    BtnNorm2    = [System.Drawing.Color]::FromArgb(60, 60, 70)
    BtnDang1    = [System.Drawing.Color]::FromArgb(150, 0, 0)
    BtnDang2    = [System.Drawing.Color]::FromArgb(255, 80, 80)
}

$Global:SelectedDisk = $null
$Global:SelectedPart = $null

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "DISK MANAGER PRO V14.1 - ULTIMATE STABLE"
$Form.Size = New-Object System.Drawing.Size(1250, 800)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $T.BgForm
$Form.ForeColor = $T.TextMain
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# -- FONTS --
$F_Logo = New-Object System.Drawing.Font("Impact", 22)
$F_Head = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$F_Norm = New-Object System.Drawing.Font("Segoe UI", 9)
$F_Btn  = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)

# ==================== CUSTOM DRAWING ====================

$PaintPanel = {
    param($s, $e)
    $Rect = $s.ClientRectangle
    $Br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($Rect, [System.Drawing.Color]::FromArgb(35,35,40), [System.Drawing.Color]::FromArgb(20,20,25), 90)
    $e.Graphics.FillRectangle($Br, $Rect)
    $Pen = New-Object System.Drawing.Pen($T.NeonBlue, 1)
    $e.Graphics.DrawRectangle($Pen, 0, 0, $s.Width-1, $s.Height-1)
    $Br.Dispose(); $Pen.Dispose()
}

function Add-CyberBtn ($Parent, $Txt, $Icon, $X, $Y, $W, $Tag, $IsDanger=$false) {
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
        $C1 = if($s.Tag.Danger){$T.BtnDang1}else{$T.BtnNorm1}
        $C2 = if($s.Tag.Danger){$T.BtnDang2}else{$T.BtnNorm2}
        if($s.Tag.Hover){ $C1=[System.Windows.Forms.ControlPaint]::Light($C1); $C2=[System.Windows.Forms.ControlPaint]::Light($C2) }
        
        $Br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($R, $C1, $C2, 45)
        $e.Graphics.FillRectangle($Br, $R)
        $Pen = New-Object System.Drawing.Pen($C2, 1)
        $e.Graphics.DrawRectangle($Pen, 0, 0, $s.Width-1, $s.Height-1)
        
        $Sf = New-Object System.Drawing.StringFormat; $Sf.Alignment="Center"; $Sf.LineAlignment="Center"
        
        # --- FIX LỖI CAST ---
        $RectF = [System.Drawing.RectangleF]::new([float]$R.X, [float]$R.Y, [float]$R.Width, [float]$R.Height)
        $e.Graphics.DrawString($s.Text, $s.Font, [System.Drawing.Brushes]::White, $RectF, $Sf)
        
        $Br.Dispose(); $Pen.Dispose()
    })
    $Parent.Controls.Add($Btn)
}

# ==================== LAYOUT ====================
# HEADER
$PnlHead = New-Object System.Windows.Forms.Panel; $PnlHead.Dock="Top"; $PnlHead.Height=60; $PnlHead.BackColor=[System.Drawing.Color]::Transparent
$Form.Controls.Add($PnlHead)
$LblLogo = New-Object System.Windows.Forms.Label; $LblLogo.Text="TITANIUM DISK MANAGER"; $LblLogo.Font=$F_Logo; $LblLogo.AutoSize=$true; $LblLogo.Location="20,10"; $LblLogo.ForeColor=$T.NeonBlue
$PnlHead.Controls.Add($LblLogo)

# 1. DISK LIST PANEL (FULL INFO)
$PnlDisk = New-Object System.Windows.Forms.Panel; $PnlDisk.Location="20,70"; $PnlDisk.Size="1200,220"; $PnlDisk.Add_Paint($PaintPanel)
$Form.Controls.Add($PnlDisk)

$Lbl1 = New-Object System.Windows.Forms.Label; $Lbl1.Text="1. DANH SÁCH Ổ CỨNG VẬT LÝ"; $Lbl1.Location="15,10"; $Lbl1.AutoSize=$true; $Lbl1.ForeColor=$T.TextMuted; $Lbl1.BackColor=[System.Drawing.Color]::Transparent; $PnlDisk.Controls.Add($Lbl1)

$GridD = New-Object System.Windows.Forms.DataGridView; $GridD.Location="15,35"; $GridD.Size="1170,170"; $GridD.BorderStyle="None"
$GridD.BackgroundColor=$T.GridBg; $GridD.ForeColor="Black"
$GridD.AllowUserToAddRows=$false; $GridD.RowHeadersVisible=$false; $GridD.SelectionMode="FullRowSelect"; $GridD.MultiSelect=$false; $GridD.ReadOnly=$true; $GridD.AutoSizeColumnsMode="Fill"
$GridD.Columns.Add("ID","Disk #"); $GridD.Columns[0].Width=60
$GridD.Columns.Add("Mod","Model Name"); $GridD.Columns[1].FillWeight=150
$GridD.Columns.Add("Type","Loại (MBR/GPT)"); $GridD.Columns[2].Width=100
$GridD.Columns.Add("Size","Dung Lượng"); $GridD.Columns[3].Width=100
$GridD.Columns.Add("Bus","Giao Tiếp (Bus)"); $GridD.Columns[4].Width=100
$GridD.Columns.Add("Media","Loại Media"); $GridD.Columns[5].Width=100
$GridD.Columns.Add("Stat","Trạng Thái"); $GridD.Columns[6].Width=100
$PnlDisk.Controls.Add($GridD)

# 2. PARTITION LIST PANEL (FULL INFO)
$PnlPart = New-Object System.Windows.Forms.Panel; $PnlPart.Location="20,305"; $PnlPart.Size="1200,220"; $PnlPart.Add_Paint($PaintPanel)
$Form.Controls.Add($PnlPart)

$Lbl2 = New-Object System.Windows.Forms.Label; $Lbl2.Text="2. CHI TIẾT PHÂN VÙNG (Click chọn để thao tác)"; $Lbl2.Location="15,10"; $Lbl2.AutoSize=$true; $Lbl2.ForeColor=$T.TextMuted; $Lbl2.BackColor=[System.Drawing.Color]::Transparent; $PnlPart.Controls.Add($Lbl2)

$GridP = New-Object System.Windows.Forms.DataGridView; $GridP.Location="15,35"; $GridP.Size="1170,170"; $GridP.BorderStyle="None"
$GridP.BackgroundColor=$T.GridBg; $GridP.ForeColor="Black"
$GridP.AllowUserToAddRows=$false; $GridP.RowHeadersVisible=$false; $GridP.SelectionMode="FullRowSelect"; $GridP.MultiSelect=$false; $GridP.ReadOnly=$true; $GridP.AutoSizeColumnsMode="Fill"
# Full Columns Requested
$GridP.Columns.Add("Let","Ký Tự"); $GridP.Columns[0].Width=50
$GridP.Columns.Add("Lab","Label"); $GridP.Columns[1].FillWeight=120
$GridP.Columns.Add("FS","FS"); $GridP.Columns[2].Width=60
$GridP.Columns.Add("Tot","Tổng"); $GridP.Columns[3].Width=80
$GridP.Columns.Add("Used","Đã Dùng"); $GridP.Columns[4].Width=80
$GridP.Columns.Add("PUse","% Dùng"); $GridP.Columns[5].Width=70
$GridP.Columns.Add("Free","Còn Lại"); $GridP.Columns[6].Width=80
$GridP.Columns.Add("Type","Loại Partition"); $GridP.Columns[7].Width=100
$GridP.Columns.Add("Boot","Boot?"); $GridP.Columns[8].Width=60
$GridP.Columns.Add("Stat","Trạng Thái"); $GridP.Columns[9].Width=80
$PnlPart.Controls.Add($GridP)

# 3. TOOLS PANEL
$PnlTool = New-Object System.Windows.Forms.Panel; $PnlTool.Location="20,540"; $PnlTool.Size="1200,200"; $PnlTool.Add_Paint($PaintPanel)
$Form.Controls.Add($PnlTool)

$LblInfo = New-Object System.Windows.Forms.Label; $LblInfo.Text="ĐANG CHỌN: [Chưa chọn]"; $LblInfo.Font=$F_Head; $LblInfo.ForeColor=$T.NeonGreen; $LblInfo.AutoSize=$true; $LblInfo.Location="15,15"; $LblInfo.BackColor=[System.Drawing.Color]::Transparent; $PnlTool.Controls.Add($LblInfo)

# Buttons
Add-CyberBtn $PnlTool "LÀM MỚI" "♻️" 30 50 180 "Refresh"
Add-CyberBtn $PnlTool "CHECK DISK" "🚑" 230 50 180 "ChkDsk"
Add-CyberBtn $PnlTool "CONVERT GPT" "🔄" 430 50 180 "Convert"
Add-CyberBtn $PnlTool "NẠP BOOT" "🛠️" 630 50 180 "FixBoot"

Add-CyberBtn $PnlTool "ĐỔI KÝ TỰ" "🔠" 30 110 180 "Letter"
Add-CyberBtn $PnlTool "ĐỔI TÊN" "🏷️" 230 110 180 "Label"
Add-CyberBtn $PnlTool "SET ACTIVE" "⚡" 430 110 180 "Active"

Add-CyberBtn $PnlTool "FORMAT" "🧹" 850 50 300 "Format" $true
Add-CyberBtn $PnlTool "XÓA PARTITION" "❌" 850 110 300 "Delete" $true

# ==================== CORE ENGINE (WMI EXTENDED) ====================
function Load-Data {
    $GridD.Rows.Clear(); $GridP.Rows.Clear(); $Global:SelectedPart = $null
    $LblInfo.Text = "ĐANG TẢI DỮ LIỆU... VUI LÒNG ĐỢI"; $LblInfo.ForeColor = $T.NeonGold
    $Form.Cursor = "WaitCursor"; $Form.Refresh()
    
    try {
        $Disks = @(Get-WmiObject Win32_DiskDrive)
        foreach ($D in $Disks) {
            # Tính toán thông tin Disk
            $GB = [Math]::Round($D.Size / 1GB, 1).ToString() + " GB"
            # WMI không trả về MBR/GPT trực tiếp dễ dàng, ta check Partition Table
            $PCount = $D.Partitions
            $Type = if ($PCount -gt 4) { "GPT (Auto Detect)" } else { "MBR/GPT" } # Logic phỏng đoán an toàn
            
            $Row = $GridD.Rows.Add($D.Index, $D.Model, $Type, $GB, $D.InterfaceType, $D.MediaType, $D.Status)
            $GridD.Rows[$Row].Tag = $D
        }
    } catch {}
    
    if ($GridD.Rows.Count -gt 0) {
        $GridD.Rows[0].Selected = $true
        Load-Partitions $GridD.Rows[0].Tag
    }
    $Form.Cursor = "Default"
    $LblInfo.Text = "SẴN SÀNG"
    $LblInfo.ForeColor = $T.NeonBlue
}

function Load-Partitions ($DiskObj) {
    $GridP.Rows.Clear(); $Global:SelectedDisk = $DiskObj
    $Global:SelectedPart = $null # Reset Selection mỗi khi load lại Disk
    
    try {
        # Sắp xếp theo Offset để đảm bảo thứ tự vật lý
        $Query = "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($DiskObj.DeviceID)'} WHERE AssocClass=Win32_DiskDriveToDiskPartition"
        $Parts = @(Get-WmiObject -Query $Query | Sort-Object StartingOffset)
        
        $RealID = 1 # ID Diskpart bắt đầu từ 1
        foreach ($P in $Parts) {
            $LogQuery = "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($P.DeviceID)'} WHERE AssocClass=Win32_LogicalDiskToPartition"
            $LogDisk = Get-WmiObject -Query $LogQuery
            
            $Total = [Math]::Round($P.Size / 1GB, 2)
            $Boot = if ($P.Bootable) { "Yes" } else { "No" }
            $PType = $P.Type
            
            if ($LogDisk) {
                $Let=$LogDisk.DeviceID; $Lab=$LogDisk.VolumeName; $FS=$LogDisk.FileSystem
                $Free=[Math]::Round($LogDisk.FreeSpace / 1GB, 2)
                $Used=[Math]::Round($Total - $Free, 2)
                $PUse=if($Total -gt 0){[Math]::Round(($Used/$Total)*100, 1)}else{0}
                
                $Row = $GridP.Rows.Add($Let, $Lab, $FS, "$Total GB", "$Used GB", "$PUse%", "$Free GB", $PType, $Boot, "OK")
            } else {
                $Let=$null; $Lab="[Hidden]"; $FS="RAW"
                $Row = $GridP.Rows.Add("", "[Hidden]", "RAW", "$Total GB", "-", "-", "-", $PType, $Boot, "Sys")
            }
            
            # Lưu Tag cho Action
            $GridP.Rows[$Row].Tag = @{ Did=$DiskObj.Index; Pid=$RealID; Let=$Let; Lab=$Lab }
            $RealID++ 
        }
    } catch {}
}

# --- EVENTS ---
$GridD.Add_CellClick({ if($GridD.SelectedRows.Count -gt 0){ Load-Partitions $GridD.SelectedRows[0].Tag } })

# FIX LỖI CHỌN: Dùng CellClick cho chắc ăn
$GridP.Add_CellClick({ 
    if($GridP.SelectedRows.Count -gt 0){ 
        $Global:SelectedPart = $GridP.SelectedRows[0].Tag 
        $P = $Global:SelectedPart
        $Name = if($P.Let){"Ổ $($P.Let)"}else{"PARTITION $($P.Pid)"}
        $LblInfo.Text = "ĐANG CHỌN: $Name (Disk $($P.Did)) - Label: $($P.Lab)"
        $LblInfo.ForeColor = $T.NeonGreen
    }
})

# ==================== ACTIONS HANDLER ====================
function Run-DP ($Cmd) {
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
            $L2 = New-Object System.Windows.Forms.Label; $L2.Text="Hệ thống tệp:"; $L2.Location="20,80"; $L2.AutoSize=$true; $F.Controls.Add($L2)
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
        "ChkDsk" { if($Let){ Start-Process "cmd" "/k chkdsk $Let /f /x" } }
        "Convert" {
            if ([System.Windows.Forms.MessageBox]::Show("Convert Disk sang GPT? (Cần Clean)", "Hỏi", "YesNo") -eq "Yes") {
                Run-DP "sel disk $Did`nclean`nconvert gpt"
            }
        }
    }
}

# --- INIT ---
$Timer = New-Object System.Windows.Forms.Timer; $Timer.Interval=500; $Timer.Add_Tick({$Timer.Stop(); Load-Data}); $Timer.Start()
$Form.ShowDialog() | Out-Null

} catch {
    # --- ERROR TRAP ---
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
}
