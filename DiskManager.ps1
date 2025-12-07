<#
    DISK MANAGER PRO - PHAT TAN PC (V8.6 REAL RGB FIX)
    Fix: RGB Text chạy mượt 100% (Dùng thuật toán Sine Wave nội bộ)
    Fix: Light Mode tương phản cao, viền Neon rõ nét.
#>

# --- 1. ADMIN CHECK ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-NoP -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- THEME DEFINITIONS ---
$Themes = @{
    Dark = @{
        FormBg      = [System.Drawing.Color]::FromArgb(15, 15, 20)
        Text        = [System.Drawing.Color]::White
        GridBg      = [System.Drawing.Color]::FromArgb(25, 25, 30)
        GridText    = [System.Drawing.Color]::White
        GridLine    = [System.Drawing.Color]::FromArgb(50, 50, 60)
        PanelBg     = [System.Drawing.Color]::FromArgb(35, 35, 40)
        NeonColor   = [System.Drawing.Color]::Cyan
        BtnText     = [System.Drawing.Color]::White
    }
    Light = @{
        FormBg      = [System.Drawing.Color]::FromArgb(245, 245, 250)
        Text        = [System.Drawing.Color]::Black
        GridBg      = [System.Drawing.Color]::White
        GridText    = [System.Drawing.Color]::Black
        GridLine    = [System.Drawing.Color]::DarkGray
        PanelBg     = [System.Drawing.Color]::White
        NeonColor   = [System.Drawing.Color]::DeepPink # Hồng đậm cho nổi trên nền trắng
        BtnText     = [System.Drawing.Color]::Black
    }
}

$Global:IsDark = $true
$Global:TickCount = 0

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "DISK MANAGER PRO - RGB EDITION"
$Form.Size = New-Object System.Drawing.Size(1050, 720)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# -- FONTS --
$F_Head = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$F_Norm = New-Object System.Drawing.Font("Segoe UI", 9)

# -- RGB LOGO (LABEL) --
$LblLogo = New-Object System.Windows.Forms.Label
$LblLogo.Text = "DISK MANAGER PRO - PHAT TAN PC"
$LblLogo.Font = New-Object System.Drawing.Font("Impact", 24)
$LblLogo.AutoSize = $true
$LblLogo.Location = "20, 10"
$Form.Controls.Add($LblLogo)

# -- THEME BUTTON --
$BtnTheme = New-Object System.Windows.Forms.Button
$BtnTheme.Text = "☯ SWITCH MODE"
$BtnTheme.Location = "880, 20"; $BtnTheme.Size = "130, 35"; $BtnTheme.FlatStyle = "Flat"
$BtnTheme.Cursor = "Hand"
$Form.Controls.Add($BtnTheme)

# ==================== PAINT NEON BORDER (HÀM VẼ VIỀN) ====================
# Sự kiện vẽ viền Neon cho Panel
$NeonPaint = {
    param($s, $e)
    $T = if ($Global:IsDark) { $Themes.Dark } else { $Themes.Light }
    
    # Vẽ viền Neon (Dày 2px)
    $Pen = New-Object System.Drawing.Pen($T.NeonColor, 2)
    $Rect = $s.ClientRectangle
    $Rect.Width -= 2; $Rect.Height -= 2; $Rect.X += 1; $Rect.Y += 1
    
    $e.Graphics.DrawRectangle($Pen, $Rect)
    $Pen.Dispose()
}

# ==================== MAIN PANELS ====================

# 1. GRID BOX
$PnlGrid = New-Object System.Windows.Forms.Panel
$PnlGrid.Location = "20, 70"; $PnlGrid.Size = "995, 250"
$PnlGrid.Add_Paint($NeonPaint) # Gán sự kiện vẽ
$PnlGrid.Padding = "5,5,5,5"
$Form.Controls.Add($PnlGrid)

$Grid = New-Object System.Windows.Forms.DataGridView
$Grid.Dock = "Fill"; $Grid.BorderStyle = "None"
$Grid.AllowUserToAddRows = $false; $Grid.RowHeadersVisible = $false
$Grid.SelectionMode = "FullRowSelect"; $Grid.MultiSelect = $false; $Grid.ReadOnly = $true
$Grid.AutoSizeColumnsMode = "Fill"
$Grid.Columns.Add("Disk","Disk"); $Grid.Columns[0].Width=50
$Grid.Columns.Add("Let","Ký Tự"); $Grid.Columns[1].Width=60
$Grid.Columns.Add("Label","Tên Ổ"); $Grid.Columns[2].FillWeight=150
$Grid.Columns.Add("FS","Loại"); $Grid.Columns[3].Width=70
$Grid.Columns.Add("Total","Tổng"); $Grid.Columns[4].Width=80
$Grid.Columns.Add("Free","Còn Lại"); $Grid.Columns[5].Width=80
$Grid.Columns.Add("Stat","Trạng Thái"); $Grid.Columns[6].Width=100
$PnlGrid.Controls.Add($Grid)

# 2. INFO BAR
$PnlInfo = New-Object System.Windows.Forms.Panel
$PnlInfo.Location = "20, 340"; $PnlInfo.Size = "995, 80"
$PnlInfo.Add_Paint($NeonPaint)
$Form.Controls.Add($PnlInfo)

$LblDet = New-Object System.Windows.Forms.Label
$LblDet.Text = "Chọn phân vùng để xem chi tiết..."; $LblDet.AutoSize = $true; $LblDet.Location = "15, 15"; $LblDet.Font = $F_Head
$PnlInfo.Controls.Add($LblDet)

$PBar = New-Object System.Windows.Forms.ProgressBar
$PBar.Location = "15, 45"; $PBar.Size = "900, 20"; $PBar.Style = "Continuous"
$PnlInfo.Controls.Add($PBar)

$LblPct = New-Object System.Windows.Forms.Label; $LblPct.Location = "930, 47"; $LblPct.AutoSize = $true
$PnlInfo.Controls.Add($LblPct)

# 3. TOOLS BOX
$PnlTool = New-Object System.Windows.Forms.Panel
$PnlTool.Location = "20, 440"; $PnlTool.Size = "995, 220"
$PnlTool.Add_Paint($NeonPaint)
$Form.Controls.Add($PnlTool)

# --- Button Helper ---
function Add-Btn ($Txt, $X, $Y, $Col, $Tag) {
    $B = New-Object System.Windows.Forms.Button
    $B.Text=$Txt; $B.Tag=$Tag; $B.Location="$X,$Y"; $B.Size="220, 45"
    $B.FlatStyle="Flat"; $B.Font=$F_Norm; $B.Cursor="Hand"
    $B.FlatAppearance.BorderSize = 0
    
    # Màu nền nút (Pha nhẹ)
    $B.BackColor = [System.Drawing.Color]::FromArgb(30, $Col.R, $Col.G, $Col.B) # Nền mờ
    # Viền dưới đậm
    $Pn = New-Object System.Windows.Forms.Panel; $Pn.Height=3; $Pn.Dock="Bottom"; $Pn.BackColor=$Col; $B.Controls.Add($Pn)
    
    $B.Add_Click({ Run-Action $this.Tag })
    $PnlTool.Controls.Add($B)
    return $B
}

$Col1 = [System.Drawing.Color]::DodgerBlue
$Col2 = [System.Drawing.Color]::Orange
$Col3 = [System.Drawing.Color]::Crimson

Add-Btn "Làm Mới (Refresh)" 30 30 $Col1 "Refresh"
Add-Btn "Check Disk (Sửa Lỗi)" 270 30 $Col1 "ChkDsk"
Add-Btn "Convert GPT/MBR" 510 30 $Col1 "Convert"

Add-Btn "Đổi Ký Tự (Letter)" 30 90 $Col2 "Letter"
Add-Btn "Đổi Tên (Label)" 270 90 $Col2 "Label"
Add-Btn "Set Active (Boot)" 510 90 $Col2 "Active"

Add-Btn "Format (Định Dạng)" 30 150 $Col3 "Format"
Add-Btn "Xóa Phân Vùng" 270 150 $Col3 "Delete"
Add-Btn "Nạp Boot (BCD)" 510 150 $Col3 "FixBoot"

# ==================== RGB ENGINE (FIXED) ====================
# Dùng thuật toán Sine Wave trực tiếp trong Timer để không bị lỗi Scope
$RgbTimer = New-Object System.Windows.Forms.Timer
$RgbTimer.Interval = 50 # Tốc độ đổi màu (ms)

$RgbTimer.Add_Tick({
    $Script:TickCount++
    
    # Thuật toán sóng Sine tạo màu RGB mượt mà
    $f = 0.1
    $r = [Math]::Floor([Math]::Sin($f * $Script:TickCount + 0) * 127 + 128)
    $g = [Math]::Floor([Math]::Sin($f * $Script:TickCount + 2) * 127 + 128)
    $b = [Math]::Floor([Math]::Sin($f * $Script:TickCount + 4) * 127 + 128)
    
    # Áp dụng màu cho Logo
    $LblLogo.ForeColor = [System.Drawing.Color]::FromArgb(255, $r, $g, $b)
})
$RgbTimer.Start()

# ==================== THEME APPLY ====================
function Apply-Theme {
    $T = if ($Global:IsDark) { $Themes.Dark } else { $Themes.Light }
    
    $Form.BackColor = $T.FormBg
    $Form.ForeColor = $T.Text
    $BtnTheme.BackColor = $T.PanelBg
    $BtnTheme.ForeColor = $T.Text
    $BtnTheme.Text = if ($Global:IsDark) { "☀ LIGHT MODE" } else { "🌙 DARK MODE" }

    # Grid Colors
    $Grid.BackgroundColor = $T.GridBg
    $Grid.GridColor = $T.GridLine
    $Grid.DefaultCellStyle.BackColor = $T.GridBg
    $Grid.DefaultCellStyle.ForeColor = $T.GridText
    $Grid.ColumnHeadersDefaultCellStyle.BackColor = $T.PanelBg
    $Grid.ColumnHeadersDefaultCellStyle.ForeColor = $T.GridText
    $Grid.EnableHeadersVisualStyles = $false
    
    # Panels BackColor
    $PnlGrid.BackColor = $T.PanelBg
    $PnlInfo.BackColor = $T.PanelBg
    $PnlTool.BackColor = $T.PanelBg
    
    # Label Colors
    $LblDet.ForeColor = $T.NeonColor
    $LblPct.ForeColor = $T.Text
    
    # Button Colors
    foreach ($C in $PnlTool.Controls) {
        if ($C -is [System.Windows.Forms.Button]) {
            $C.ForeColor = $T.BtnText
            # Light Mode thì làm nền nút sáng lên xíu
            if (!$Global:IsDark) { $C.BackColor = [System.Drawing.Color]::FromArgb(20, 0, 0, 0) } 
            else { $C.BackColor = [System.Drawing.Color]::FromArgb(30, 255, 255, 255) }
        }
    }
    
    # Vẽ lại viền Neon ngay lập tức
    $Form.Refresh()
}

$BtnTheme.Add_Click({ $Global:IsDark = -not $Global:IsDark; Apply-Theme })

# ==================== LOGIC (WMI) ====================
function Load-Data {
    $Grid.Rows.Clear(); $Global:SelectedPart = $null; $LblDet.Text = "Đang tải..."; $Form.Cursor = "WaitCursor"; $Form.Refresh()
    try {
        $Disks = @(Get-WmiObject Win32_DiskDrive)
        foreach ($D in $Disks) {
            $Parts = @(Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($D.DeviceID)'} WHERE AssocClass=Win32_DiskDriveToDiskPartition" | Sort-Object Index)
            foreach ($P in $Parts) {
                $LogDisk = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($P.DeviceID)'} WHERE AssocClass=Win32_LogicalDiskToPartition"
                $Total = [Math]::Round($P.Size / 1GB, 2)
                $DiskInfo = "Disk $($D.Index)"
                
                if ($LogDisk) {
                    $Free = [Math]::Round($LogDisk.FreeSpace / 1GB, 2)
                    $Used = [Math]::Round($Total - $Free, 2)
                    $Row = $Grid.Rows.Add($DiskInfo, $LogDisk.DeviceID, $LogDisk.VolumeName, $LogDisk.FileSystem, "$Total GB", "$Free GB", "OK")
                    $Grid.Rows[$Row].Tag = @{ Did=$D.Index; Pid=($P.Index+1); Let=$LogDisk.DeviceID; Lab=$LogDisk.VolumeName; PUsed=[Math]::Round((($Total-$Free)/$Total)*100) }
                } else {
                    $Row = $Grid.Rows.Add($DiskInfo, "", "[Hidden]", $P.Type, "$Total GB", "-", "System")
                    $Grid.Rows[$Row].Tag = @{ Did=$D.Index; Pid=($P.Index+1); Let=$null; PUsed=0 }
                }
            }
        }
    } catch {}
    $LblDet.Text = "Sẵn sàng."; $Form.Cursor = "Default"
}

$Grid.Add_SelectionChanged({
    if ($Grid.SelectedRows.Count -gt 0) {
        $D = $Grid.SelectedRows[0].Tag
        $Global:SelectedPart = $D
        $Name = if($D.Let){"Ổ $($D.Let)"}else{"PARTITION"}
        $LblDet.Text = "Đang chọn: $Name (Disk $($D.Did)) - Label: $($D.Lab)"
        $PBar.Value = [int]$D.PUsed
        $LblPct.Text = "$($D.PUsed)%"
    }
})

function Run-Action ($Act) {
    $P = $Global:SelectedPart; if (!$P) { return }
    $Did = $P.Did; $Pid = $P.Pid; $Let = $P.Let
    
    if ($Act -eq "Refresh") { Load-Data; return }
    
    # Logic Diskpart
    $Script = "$env:TEMP\dp.txt"
    $Cmd = "sel disk $Did`nsel part $Pid`n"
    
    switch ($Act) {
        "ChkDsk" { if($Let){Start-Process "cmd" "/k chkdsk $Let /f /x"; return} }
        "Convert"{ $Cmd+="clean`nconvert gpt"; $Msg="Convert Disk $Did -> GPT (Xóa dữ liệu)?" }
        "Format" { $Cmd+="format fs=ntfs quick"; $Msg="Format $Let?" }
        "Delete" { $Cmd+="delete partition override"; $Msg="Xóa Part $Pid?" }
        "Active" { $Cmd+="active"; $Msg="Set Active?" }
        "Letter" { $N=[Microsoft.VisualBasic.Interaction]::InputBox("Ký tự mới:",""); if($N){$Cmd+="assign letter=$N"; $Msg="Đổi sang $N?"}else{return} }
        "Label"  { $N=[Microsoft.VisualBasic.Interaction]::InputBox("Tên mới:",""); if($N){ cmd /c "label $Let $N"; Load-Data; return } else{return} }
        "FixBoot"{ Start-Process "cmd" "/c bcdboot C:\Windows /s C: /f ALL & pause"; return }
    }
    
    if([System.Windows.Forms.MessageBox]::Show($Msg, "Xác nhận", "YesNo") -eq "Yes") {
        [IO.File]::WriteAllText($Script, $Cmd)
        Start-Process "diskpart" "/s `"$Script`"" -Wait -NoNewWindow
        Load-Data
    }
}

# --- INIT ---
Apply-Theme
$T = New-Object System.Windows.Forms.Timer; $T.Interval=500; $T.Add_Tick({$T.Stop(); Load-Data}); $T.Start()
$Form.ShowDialog() | Out-Null
