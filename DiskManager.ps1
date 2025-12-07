<#
    DISK MANAGER PRO - PHAT TAN PC (V10.0 CYBER CORE)
    Style: Gradient Neon + Custom Drawn Controls (Giao diện vẽ tay)
    Engine: WMI Stable (Full Actions)
#>

# --- 1. ADMIN CHECK ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-NoP -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- THEME CONFIG (CYBERPUNK GRADIENTS) ---
$T = @{
    BgForm      = [System.Drawing.Color]::FromArgb(15, 15, 20)
    BgPanel     = [System.Drawing.Color]::FromArgb(25, 25, 30)
    TextMain    = [System.Drawing.Color]::White
    TextMuted   = [System.Drawing.Color]::FromArgb(150, 150, 150)
    
    # Gradient Colors (Start -> End)
    GradBtn1    = [System.Drawing.Color]::FromArgb(0, 120, 215) # Blue
    GradBtn2    = [System.Drawing.Color]::FromArgb(0, 200, 255) # Cyan
    
    GradDanger1 = [System.Drawing.Color]::FromArgb(200, 0, 0)   # Red Dark
    GradDanger2 = [System.Drawing.Color]::FromArgb(255, 80, 80) # Red Light
    
    NeonBorder  = [System.Drawing.Color]::FromArgb(0, 255, 200) # Cyan Neon
}

$Global:SelectedDisk = $null
$Global:SelectedPart = $null
$Global:Hue = 0

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "DISK MANAGER PRO V10.0 - CYBER CORE"
$Form.Size = New-Object System.Drawing.Size(1150, 780)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $T.BgForm
$Form.ForeColor = $T.TextMain
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# -- FONTS --
$F_Logo = New-Object System.Drawing.Font("Impact", 22)
$F_Head = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$F_Norm = New-Object System.Drawing.Font("Segoe UI", 9)
$F_Btn  = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)

# ==================== CUSTOM PAINTING (VẼ GIAO DIỆN) ====================

# 1. Hàm vẽ Gradient Background cho Panel
$PaintGradient = {
    param($s, $e)
    $Rect = $s.ClientRectangle
    $Brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($Rect, [System.Drawing.Color]::FromArgb(40,40,45), [System.Drawing.Color]::FromArgb(20,20,25), 90)
    $e.Graphics.FillRectangle($Brush, $Rect)
    
    # Vẽ viền Neon mỏng
    $Pen = New-Object System.Drawing.Pen($T.NeonBorder, 1)
    $e.Graphics.DrawRectangle($Pen, 0, 0, $s.Width-1, $s.Height-1)
    $Brush.Dispose(); $Pen.Dispose()
}

# 2. Custom Button Class (Giả lập nút bấm xịn)
function Add-CyberBtn ($Parent, $Txt, $Icon, $X, $Y, $W, $Tag, $IsDanger=$false) {
    $Btn = New-Object System.Windows.Forms.Label # Dùng Label để vẽ custom dễ hơn Button
    $Btn.Text = "$Icon  $Txt"
    $Btn.Tag = $Tag
    $Btn.Location = "$X, $Y"; $Btn.Size = "$W, 40"
    $Btn.Font = $F_Btn; $Btn.TextAlign = "MiddleCenter"
    $Btn.ForeColor = $T.TextMain
    $Btn.Cursor = "Hand"
    
    # Lưu màu vào Tag để dùng khi vẽ
    $Btn.Tag = @{ Act=$Tag; Hover=$false; Danger=$IsDanger }

    $Btn.Add_MouseEnter({ $this.Tag.Hover=$true; $this.Invalidate() })
    $Btn.Add_MouseLeave({ $this.Tag.Hover=$false; $this.Invalidate() })
    $Btn.Add_Click({ Run-Action $this.Tag.Act })
    
    $Btn.Add_Paint({
        param($s, $e)
        $R = $s.ClientRectangle
        
        # Chọn màu Gradient
        $C1 = if($s.Tag.Danger){$T.GradDanger1}else{$T.GradBtn1}
        $C2 = if($s.Tag.Danger){$T.GradDanger2}else{$T.GradBtn2}
        
        # Nếu Hover thì sáng hơn
        if($s.Tag.Hover){ 
            $C1 = [System.Windows.Forms.ControlPaint]::Light($C1)
            $C2 = [System.Windows.Forms.ControlPaint]::Light($C2)
        } else {
            # Mặc định thì mờ đi chút (Glass effect)
            $C1 = [System.Drawing.Color]::FromArgb(50, $C1)
            $C2 = [System.Drawing.Color]::FromArgb(50, $C2)
        }

        $Br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($R, $C1, $C2, 45)
        $e.Graphics.FillRectangle($Br, $R)
        
        # Viền nút
        $Pen = New-Object System.Drawing.Pen($C2, 1)
        $e.Graphics.DrawRectangle($Pen, 0, 0, $s.Width-1, $s.Height-1)
        
        # Text (Vẽ lại text để căn giữa chuẩn)
        $Sf = New-Object System.Drawing.StringFormat; $Sf.Alignment="Center"; $Sf.LineAlignment="Center"
        $e.Graphics.DrawString($s.Text, $s.Font, [System.Drawing.Brushes]::White, $R, $Sf)
        
        $Br.Dispose(); $Pen.Dispose()
    })
    
    $Parent.Controls.Add($Btn)
}

# ==================== HEADER (RGB LOGO) ====================
$PnlHead = New-Object System.Windows.Forms.Panel; $PnlHead.Dock="Top"; $PnlHead.Height=70; $PnlHead.BackColor=[System.Drawing.Color]::Transparent
$Form.Controls.Add($PnlHead)

$LblLogo = New-Object System.Windows.Forms.Label
$LblLogo.Text = "DISK MANAGER V10 - CYBER CORE"
$LblLogo.Font = $F_Logo; $LblLogo.AutoSize = $true; $LblLogo.Location = "20, 15"
$PnlHead.Controls.Add($LblLogo)

# ==================== MAIN GRIDS ====================
# 1. DISK GRID PANEL
$PnlGrid = New-Object System.Windows.Forms.Panel
$PnlGrid.Location = "20, 80"; $PnlGrid.Size = "1095, 220"
$PnlGrid.Add_Paint($PaintGradient) # Áp dụng nền Gradient
$Form.Controls.Add($PnlGrid)

$LblG1 = New-Object System.Windows.Forms.Label; $LblG1.Text="DANH SÁCH Ổ CỨNG VẬT LÝ"; $LblG1.Location="15,10"; $LblG1.AutoSize=$true; $LblG1.ForeColor=$T.TextMuted; $LblG1.BackColor=[System.Drawing.Color]::Transparent
$PnlGrid.Controls.Add($LblG1)

$GridD = New-Object System.Windows.Forms.DataGridView
$GridD.Location="15,35"; $GridD.Size="1065,170"; $GridD.BorderStyle="None"; $GridD.BackgroundColor=[System.Drawing.Color]::FromArgb(30,30,35)
$GridD.AllowUserToAddRows=$false; $GridD.RowHeadersVisible=$false; $GridD.SelectionMode="FullRowSelect"; $GridD.MultiSelect=$false; $GridD.ReadOnly=$true; $GridD.AutoSizeColumnsMode="Fill"
$GridD.EnableHeadersVisualStyles=$false
$GridD.ColumnHeadersDefaultCellStyle.BackColor=[System.Drawing.Color]::FromArgb(50,50,60); $GridD.ColumnHeadersDefaultCellStyle.ForeColor=[System.Drawing.Color]::White
$GridD.DefaultCellStyle.BackColor=[System.Drawing.Color]::FromArgb(35,35,40); $GridD.DefaultCellStyle.ForeColor=[System.Drawing.Color]::White; $GridD.DefaultCellStyle.SelectionBackColor=[System.Drawing.Color]::FromArgb(0,100,180)
$GridD.Columns.Add("ID","Disk #"); $GridD.Columns[0].Width=60
$GridD.Columns.Add("Mod","Model"); $GridD.Columns[1].FillWeight=150
$GridD.Columns.Add("Size","Dung Lượng"); $GridD.Columns[2].Width=120
$GridD.Columns.Add("Type","Loại"); $GridD.Columns[3].Width=80
$GridD.Columns.Add("Stat","Trạng Thái"); $GridD.Columns[4].Width=100
$PnlGrid.Controls.Add($GridD)

# 2. PARTITION GRID PANEL
$PnlPart = New-Object System.Windows.Forms.Panel
$PnlPart.Location = "20, 315"; $PnlPart.Size = "1095, 200"
$PnlPart.Add_Paint($PaintGradient)
$Form.Controls.Add($PnlPart)

$LblG2 = New-Object System.Windows.Forms.Label; $LblG2.Text="CHI TIẾT PHÂN VÙNG"; $LblG2.Location="15,10"; $LblG2.AutoSize=$true; $LblG2.ForeColor=$T.TextMuted; $LblG2.BackColor=[System.Drawing.Color]::Transparent
$PnlPart.Controls.Add($LblG2)

$GridP = New-Object System.Windows.Forms.DataGridView
$GridP.Location="15,35"; $GridP.Size="1065,150"; $GridP.BorderStyle="None"; $GridP.BackgroundColor=[System.Drawing.Color]::FromArgb(30,30,35)
$GridP.AllowUserToAddRows=$false; $GridP.RowHeadersVisible=$false; $GridP.SelectionMode="FullRowSelect"; $GridP.MultiSelect=$false; $GridP.ReadOnly=$true; $GridP.AutoSizeColumnsMode="Fill"
$GridP.EnableHeadersVisualStyles=$false
$GridP.ColumnHeadersDefaultCellStyle.BackColor=[System.Drawing.Color]::FromArgb(50,50,60); $GridP.ColumnHeadersDefaultCellStyle.ForeColor=[System.Drawing.Color]::White
$GridP.DefaultCellStyle.BackColor=[System.Drawing.Color]::FromArgb(35,35,40); $GridP.DefaultCellStyle.ForeColor=[System.Drawing.Color]::White; $GridP.DefaultCellStyle.SelectionBackColor=[System.Drawing.Color]::FromArgb(0,100,180)
$GridP.Columns.Add("Let","Ký Tự"); $GridP.Columns[0].Width=60
$GridP.Columns.Add("Lab","Label"); $GridP.Columns[1].FillWeight=150
$GridP.Columns.Add("FS","FS"); $GridP.Columns[2].Width=80
$GridP.Columns.Add("Tot","Tổng"); $GridP.Columns[3].Width=100
$GridP.Columns.Add("Fre","Còn Lại"); $GridP.Columns[4].Width=100
$GridP.Columns.Add("Sta","Trạng Thái"); $GridP.Columns[5].Width=100
$PnlPart.Controls.Add($GridP)

# ==================== INFO & TOOLS PANEL ====================
$PnlTool = New-Object System.Windows.Forms.Panel
$PnlTool.Location = "20, 530"; $PnlTool.Size = "1095, 200"
$PnlTool.Add_Paint($PaintGradient)
$Form.Controls.Add($PnlTool)

# Info Label
$LblInfo = New-Object System.Windows.Forms.Label
$LblInfo.Text = "Đang chọn: [Chưa chọn]"; $LblInfo.Font = $F_Head; $LblInfo.ForeColor = $T.NeonBorder
$LblInfo.AutoSize = $true; $LblInfo.Location = "15, 15"; $LblInfo.BackColor=[System.Drawing.Color]::Transparent
$PnlTool.Controls.Add($LblInfo)

# Buttons Row 1
Add-CyberBtn $PnlTool "LÀM MỚI" "♻️" 15 50 160 "Refresh"
Add-CyberBtn $PnlTool "CHECK DISK" "🚑" 190 50 160 "ChkDsk"
Add-CyberBtn $PnlTool "CONVERT GPT" "🔄" 365 50 160 "Convert"
Add-CyberBtn $PnlTool "NẠP BOOT" "🛠️" 540 50 160 "FixBoot"

# Buttons Row 2
Add-CyberBtn $PnlTool "ĐỔI KÝ TỰ" "🔠" 15 105 160 "Letter"
Add-CyberBtn $PnlTool "ĐỔI TÊN" "🏷️" 190 105 160 "Label"
Add-CyberBtn $PnlTool "SET ACTIVE" "⚡" 365 105 160 "Active"

# Danger Zone
Add-CyberBtn $PnlTool "FORMAT" "🧹" 750 50 160 "Format" $true
Add-CyberBtn $PnlTool "DELETE" "❌" 920 50 160 "Delete" $true

# ==================== RGB LOGIC ====================
$Tmr = New-Object System.Windows.Forms.Timer; $Tmr.Interval=30
$Tmr.Add_Tick({
    $Global:Hue += 2; if($Global:Hue -gt 255){$Global:Hue=0}
    $H=$Global:Hue; $R=0;$G=0;$B=0
    if($H -lt 85){$R=$H*3;$G=255-$H*3} elseif($H -lt 170){$H-=85;$R=255-$H*3;$B=$H*3} else{$H-=170;$G=$H*3;$B=255-$H*3}
    $LblLogo.ForeColor = [System.Drawing.Color]::FromArgb(255, $R, $G, $B)
})
$Tmr.Start()

# ==================== ENGINE (WMI) ====================
function Load-Data {
    $GridD.Rows.Clear(); $GridP.Rows.Clear(); $Global:SelectedPart = $null
    $LblInfo.Text = "ĐANG TẢI DỮ LIỆU..."; $Form.Cursor="WaitCursor"; $Form.Refresh()
    
    try {
        $Disks = @(Get-WmiObject Win32_DiskDrive)
        foreach ($D in $Disks) {
            $Parts = @(Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($D.DeviceID)'} WHERE AssocClass=Win32_DiskDriveToDiskPartition" | Sort-Object Index)
            foreach ($P in $Parts) {
                $LogDisk = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($P.DeviceID)'} WHERE AssocClass=Win32_LogicalDiskToPartition"
                $Total = [Math]::Round($P.Size / 1GB, 2)
                $DiskInfo = "Disk $($D.Index)"
                
                if ($LogDisk) {
                    $Let=$LogDisk.DeviceID; $Lab=$LogDisk.VolumeName; $FS=$LogDisk.FileSystem
                    $Free=[Math]::Round($LogDisk.FreeSpace/1GB, 2)
                    $Row = $GridP.Rows.Add($Let, $Lab, $FS, "$Total GB", "$Free GB", "OK")
                    $GridP.Rows[$Row].Tag = @{Did=$D.Index; Pid=($P.Index+1); Let=$Let; Lab=$Lab}
                } else {
                    $Row = $GridP.Rows.Add("", "[Hidden]", $P.Type, "$Total GB", "-", "System")
                    $GridP.Rows[$Row].Tag = @{Did=$D.Index; Pid=($P.Index+1); Let=$null}
                }
            }
            $RowD = $GridD.Rows.Add($D.Index, $D.Model, "$([Math]::Round($D.Size/1GB)) GB", "MBR/GPT", $D.Status)
            $GridD.Rows[$RowD].Tag = $D
        }
    } catch {}
    $LblInfo.Text = "SẴN SÀNG"; $Form.Cursor="Default"
}

# Events
$GridD.Add_CellClick({
    if($GridD.SelectedRows.Count -gt 0){
        # Logic lọc phân vùng theo ổ đĩa nếu muốn (Hiện tại show all cho dễ)
    }
})
$GridP.Add_CellClick({
    if($GridP.SelectedRows.Count -gt 0){
        $D = $GridP.SelectedRows[0].Tag; $Global:SelectedPart = $D
        $Name = if($D.Let){"Ổ $($D.Let)"}else{"PARTITION $($D.Pid)"}
        $LblInfo.Text = "ĐANG CHỌN: $Name (Trên Disk $($D.Did))"
    }
})

# Actions
function Run-DP($C){ $F="$env:TEMP\d.txt";[IO.File]::WriteAllText($F,$C);Start-Process "diskpart" "/s `"$F`"" -Wait -NoNewWindow;Remove-Item $F;Load-Data }
function Run-Action($A){
    if($A -eq "Refresh"){Load-Data;return}
    $P=$Global:SelectedPart; if(!$P){ [System.Windows.Forms.MessageBox]::Show("Chưa chọn phân vùng!","Lỗi");return }
    $Did=$P.Did; $Pid=$P.Pid; $Let=$P.Let
    
    switch($A){
        "Format"{if([System.Windows.Forms.MessageBox]::Show("Format $Let?","Cảnh báo","YesNo")-eq"Yes"){Run-DP "sel disk $Did`nsel part $Pid`nformat fs=ntfs quick"}}
        "Delete"{if([System.Windows.Forms.MessageBox]::Show("Xóa Part?","Cảnh báo","YesNo")-eq"Yes"){Run-DP "sel disk $Did`nsel part $Pid`ndelete partition override"}}
        "Active"{Run-DP "sel disk $Did`nsel part $Pid`nactive"}
        "Letter"{$N=[Microsoft.VisualBasic.Interaction]::InputBox("Ký tự mới:","Assign","");if($N){Run-DP "sel disk $Did`nsel part $Pid`nassign letter=$N"}}
        "Label"{$N=[Microsoft.VisualBasic.Interaction]::InputBox("Tên mới:","Rename",$P.Lab);if($N){if($Let){cmd /c "label $Let $N";Load-Data}}}
        "ChkDsk"{if($Let){Start-Process "cmd" "/k chkdsk $Let /f /x"}}
        "Convert"{if([System.Windows.Forms.MessageBox]::Show("Convert Disk?","Hỏi","YesNo")-eq"Yes"){Run-DP "sel disk $Did`nclean`nconvert gpt"}}
        "FixBoot"{Start-Process "cmd" "/c bcdboot C:\Windows /s C: /f ALL & pause"}
    }
}

# Init
$Timer = New-Object System.Windows.Forms.Timer; $Timer.Interval=300; $Timer.Add_Tick({$Timer.Stop(); Load-Data}); $Timer.Start()
$Form.ShowDialog() | Out-Null
