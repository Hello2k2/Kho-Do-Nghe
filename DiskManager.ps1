<#
    DISK MANAGER PRO - PHAT TAN PC (V8.5 NEON THEME SWITCHER)
    Style: Dual Theme (Dark Neon / Light Neon)
    Layout: Grid trên -> Info Bar giữa -> Tools dưới
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
        FormBg      = [System.Drawing.Color]::FromArgb(20, 20, 25)
        GroupBoxFg  = [System.Drawing.Color]::FromArgb(0, 255, 255) # Cyan Neon
        Text        = [System.Drawing.Color]::FromArgb(240, 240, 240)
        GridBg      = [System.Drawing.Color]::FromArgb(30, 30, 35)
        GridText    = [System.Drawing.Color]::White
        GridLine    = [System.Drawing.Color]::FromArgb(0, 255, 255)
        PanelBg     = [System.Drawing.Color]::FromArgb(40, 40, 45)
        InfoLabel   = [System.Drawing.Color]::FromArgb(255, 0, 255) # Magenta Neon
        BtnText     = [System.Drawing.Color]::White
        BtnBorder   = 0
    }
    Light = @{
        FormBg      = [System.Drawing.Color]::White
        GroupBoxFg  = [System.Drawing.Color]::FromArgb(0, 100, 200) # Deep Blue
        Text        = [System.Drawing.Color]::Black
        GridBg      = [System.Drawing.Color]::WhiteSmoke
        GridText    = [System.Drawing.Color]::Black
        GridLine    = [System.Drawing.Color]::Silver
        PanelBg     = [System.Drawing.Color]::FromArgb(240, 240, 240)
        InfoLabel   = [System.Drawing.Color]::FromArgb(255, 20, 147) # Deep Pink
        BtnText     = [System.Drawing.Color]::White
        BtnBorder   = 1
    }
}

$Global:IsDark = $true # Mặc định Dark Mode
$Global:SelectedPart = $null

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "QUẢN LÝ PHÂN VÙNG Ổ ĐĨA - PHAT TAN PC (V8.5)"
$Form.Size = New-Object System.Drawing.Size(1000, 700)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# -- FONTS --
$F_Title = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$F_Norm  = New-Object System.Drawing.Font("Segoe UI", 9)

# -- THEME SWITCHER BUTTON --
$BtnTheme = New-Object System.Windows.Forms.Button
$BtnTheme.Text = "☯ ĐỔI GIAO DIỆN"
$BtnTheme.Size = New-Object System.Drawing.Size(120, 30)
$BtnTheme.Location = New-Object System.Drawing.Point(850, 5) # Góc phải trên
$BtnTheme.FlatStyle = "Flat"
$BtnTheme.Cursor = "Hand"
$Form.Controls.Add($BtnTheme)

# ==================== PHẦN 1: DANH SÁCH (GRID) ====================
$GbList = New-Object System.Windows.Forms.GroupBox
$GbList.Text = "1. DANH SÁCH PHÂN VÙNG (DISK LIST)"
$GbList.Location = "10, 30"; $GbList.Size = "965, 250"
$GbList.Font = $F_Title
$Form.Controls.Add($GbList)

$Grid = New-Object System.Windows.Forms.DataGridView
$Grid.Dock = "Fill"; 
$Grid.AllowUserToAddRows = $false; $Grid.RowHeadersVisible = $false
$Grid.SelectionMode = "FullRowSelect"; $Grid.MultiSelect = $false; $Grid.ReadOnly = $true
$Grid.AutoSizeColumnsMode = "Fill"; $Grid.Font = $F_Norm
$Grid.EnableHeadersVisualStyles = $false # Để tô màu header

# Columns
$Grid.Columns.Add("Disk", "Disk"); $Grid.Columns[0].Width = 50
$Grid.Columns.Add("Let", "Ký Tự"); $Grid.Columns[1].Width = 60
$Grid.Columns.Add("Label", "Tên Ổ (Label)"); $Grid.Columns[2].FillWeight = 120
$Grid.Columns.Add("FS", "Loại"); $Grid.Columns[3].Width = 70
$Grid.Columns.Add("Total", "Tổng"); $Grid.Columns[4].Width = 80
$Grid.Columns.Add("Used", "Đã dùng"); $Grid.Columns[5].Width = 80
$Grid.Columns.Add("PUse", "% Dùng"); $Grid.Columns[6].Width = 70
$Grid.Columns.Add("Free", "Còn lại"); $Grid.Columns[7].Width = 80
$Grid.Columns.Add("Health", "Sức khỏe"); $Grid.Columns[8].Width = 90

$GbList.Controls.Add($Grid)

# ==================== PHẦN 2: INFO BAR ====================
$GbInfo = New-Object System.Windows.Forms.GroupBox
$GbInfo.Text = "2. THÔNG TIN CHI TIẾT"
$GbInfo.Location = "10, 290"; $GbInfo.Size = "965, 90"
$GbInfo.Font = $F_Title
$Form.Controls.Add($GbInfo)

$LblDet1 = New-Object System.Windows.Forms.Label; $LblDet1.Location = "20, 25"; $LblDet1.AutoSize = $true; $LblDet1.Font = $F_Norm
$LblDet1.Text = "Vui lòng chọn một phân vùng..."
$GbInfo.Controls.Add($LblDet1)

$PBar = New-Object System.Windows.Forms.ProgressBar
$PBar.Location = "20, 50"; $PBar.Size = "850, 25"; $PBar.Style = "Continuous"
$GbInfo.Controls.Add($PBar)

$LblPct = New-Object System.Windows.Forms.Label; $LblPct.Location = "880, 53"; $LblPct.AutoSize = $true; $LblPct.Font = $F_Norm
$LblPct.Text = "0%"
$GbInfo.Controls.Add($LblPct)

# ==================== PHẦN 3: TOOLS ====================
$GbTool = New-Object System.Windows.Forms.GroupBox
$GbTool.Text = "3. CÔNG CỤ (ACTIONS)"
$GbTool.Location = "10, 390"; $GbTool.Size = "965, 250"
$GbTool.Font = $F_Title
$Form.Controls.Add($GbTool)

# --- Tool Containers ---
$PnlT1 = New-Object System.Windows.Forms.Panel; $PnlT1.Location="20, 30"; $PnlT1.Size="300, 200"; $PnlT1.BorderStyle="FixedSingle"
$GbTool.Controls.Add($PnlT1)
$L_T1 = New-Object System.Windows.Forms.Label; $L_T1.Text="CƠ BẢN"; $L_T1.Dock="Top"; $L_T1.TextAlign="MiddleCenter"; $L_T1.Height=25
$PnlT1.Controls.Add($L_T1)

$PnlT2 = New-Object System.Windows.Forms.Panel; $PnlT2.Location="330, 30"; $PnlT2.Size="300, 200"; $PnlT2.BorderStyle="FixedSingle"
$GbTool.Controls.Add($PnlT2)
$L_T2 = New-Object System.Windows.Forms.Label; $L_T2.Text="HỆ THỐNG"; $L_T2.Dock="Top"; $L_T2.TextAlign="MiddleCenter"; $L_T2.Height=25
$PnlT2.Controls.Add($L_T2)

$PnlT3 = New-Object System.Windows.Forms.Panel; $PnlT3.Location="640, 30"; $PnlT3.Size="300, 200"; $PnlT3.BorderStyle="FixedSingle"
$GbTool.Controls.Add($PnlT3)
$L_T3 = New-Object System.Windows.Forms.Label; $L_T3.Text="NGUY HIỂM"; $L_T3.Dock="Top"; $L_T3.TextAlign="MiddleCenter"; $L_T3.ForeColor=[System.Drawing.Color]::Red; $L_T3.Height=25
$PnlT3.Controls.Add($L_T3)

# --- Button Helper ---
function Add-Btn ($Panel, $Txt, $Y, $Col, $Tag) {
    $B = New-Object System.Windows.Forms.Button; $B.Text=$Txt; $B.Tag=$Tag
    $B.Location="10,$Y"; $B.Size="278,35"; $B.FlatStyle="Flat"; $B.Font=$F_Norm
    $B.BackColor=$Col; $B.ForeColor=[System.Drawing.Color]::White; $B.Cursor="Hand"
    $B.Add_Click({ Run-Action $this.Tag })
    $Panel.Controls.Add($B)
}

# Group 1
Add-Btn $PnlT1 "Làm mới (Refresh)" 35 [System.Drawing.Color]::FromArgb(0, 120, 215) "Refresh"
Add-Btn $PnlT1 "Đổi tên ổ (Label)" 75 [System.Drawing.Color]::DimGray "Label"
Add-Btn $PnlT1 "Đổi ký tự (Letter)" 115 [System.Drawing.Color]::DimGray "Letter"

# Group 2
Add-Btn $PnlT2 "Set Active (Boot)" 35 [System.Drawing.Color]::DarkOrange "Active"
Add-Btn $PnlT2 "Fix Boot (BCD)" 75 [System.Drawing.Color]::DarkOrange "FixBoot"
Add-Btn $PnlT2 "Check Disk (Sửa lỗi)" 115 [System.Drawing.Color]::SeaGreen "ChkDsk"

# Group 3
Add-Btn $PnlT3 "Format (Định dạng)" 35 [System.Drawing.Color]::Crimson "Format"
Add-Btn $PnlT3 "Xóa phân vùng (Delete)" 75 [System.Drawing.Color]::Crimson "Delete"
Add-Btn $PnlT3 "Convert GPT <-> MBR" 115 [System.Drawing.Color]::SlateGray "Convert"

# ==================== THEME APPLY FUNCTION ====================
function Apply-Theme {
    $T = if ($Global:IsDark) { $Themes.Dark } else { $Themes.Light }
    
    # 1. Main Form
    $Form.BackColor = $T.FormBg
    $Form.ForeColor = $T.Text
    
    # 2. Theme Button
    $BtnTheme.BackColor = $T.PanelBg
    $BtnTheme.ForeColor = $T.Text
    $BtnTheme.Text = if ($Global:IsDark) { "☀ LIGHT MODE" } else { "🌙 DARK MODE" }

    # 3. GroupBoxes
    foreach ($G in @($GbList, $GbInfo, $GbTool)) {
        $G.ForeColor = $T.GroupBoxFg
    }

    # 4. Grid
    $Grid.BackgroundColor = $T.GridBg
    $Grid.GridColor = $T.GridLine
    $Grid.DefaultCellStyle.BackColor = $T.GridBg
    $Grid.DefaultCellStyle.ForeColor = $T.GridText
    $Grid.ColumnHeadersDefaultCellStyle.BackColor = $T.PanelBg
    $Grid.ColumnHeadersDefaultCellStyle.ForeColor = $T.GridText
    $Grid.RowHeadersDefaultCellStyle.BackColor = $T.PanelBg

    # 5. Labels & Panels
    $LblDet1.ForeColor = $T.InfoLabel
    $LblPct.ForeColor = $T.Text
    
    foreach ($P in @($PnlT1, $PnlT2, $PnlT3)) {
        $P.BackColor = $T.PanelBg
        $P.ForeColor = $T.Text
    }
    # Fix Label Headers trong Panels
    $L_T1.BackColor = if($Global:IsDark){[System.Drawing.Color]::FromArgb(60,60,60)}else{[System.Drawing.Color]::LightGray}
    $L_T2.BackColor = if($Global:IsDark){[System.Drawing.Color]::FromArgb(60,60,60)}else{[System.Drawing.Color]::LightGray}
    $L_T3.BackColor = if($Global:IsDark){[System.Drawing.Color]::FromArgb(50,20,20)}else{[System.Drawing.Color]::MistyRose}
}

$BtnTheme.Add_Click({
    $Global:IsDark = -not $Global:IsDark
    Apply-Theme
})

# ==================== LOGIC ENGINE ====================
function Load-Data {
    $Grid.Rows.Clear()
    $Global:SelectedPart = $null
    $LblDet1.Text = "Đang tải dữ liệu..."
    $Form.Cursor = "WaitCursor"; $Form.Refresh()

    try {
        $Disks = @(Get-WmiObject Win32_DiskDrive)
        foreach ($D in $Disks) {
            $Query = "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($D.DeviceID)'} WHERE AssocClass=Win32_DiskDriveToDiskPartition"
            $Parts = @(Get-WmiObject -Query $Query | Sort-Object Index)

            foreach ($P in $Parts) {
                $LogQuery = "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($P.DeviceID)'} WHERE AssocClass=Win32_LogicalDiskToPartition"
                $LogDisk = Get-WmiObject -Query $LogQuery

                $TotalGB = [Math]::Round($P.Size / 1GB, 2)
                $DiskInfo = "Disk $($D.Index)"

                if ($LogDisk) {
                    $Let = $LogDisk.DeviceID
                    $Lab = $LogDisk.VolumeName
                    $FS  = $LogDisk.FileSystem
                    $FreeGB = [Math]::Round($LogDisk.FreeSpace / 1GB, 2)
                    $UsedGB = [Math]::Round($TotalGB - $FreeGB, 2)
                    $PctFree = if($TotalGB -gt 0){[Math]::Round(($FreeGB/$TotalGB)*100,0)}else{0}
                    $PctUsed = 100 - $PctFree
                    
                    $RowIdx = $Grid.Rows.Add($DiskInfo, $Let, $Lab, $FS, "$TotalGB GB", "$UsedGB GB", "$PctUsed%", "$FreeGB GB", "OK")
                    
                    $Grid.Rows[$RowIdx].Tag = @{
                        Did=$D.Index; Pid=($P.Index+1); Let=$Let; Lab=$Lab; 
                        Total=$TotalGB; Free=$FreeGB; PUsed=$PctUsed
                    }
                } else {
                    $Type = $P.Type; if($P.Bootable){$Type+=" (Boot)"}
                    $RowIdx = $Grid.Rows.Add($DiskInfo, "", "[Hidden/System]", $Type, "$TotalGB GB", "-", "-", "-", "System")
                    $Grid.Rows[$RowIdx].Tag = @{ Did=$D.Index; Pid=($P.Index+1); Let=$null; Lab="Hidden"; PUsed=0 }
                }
            }
        }
    } catch {}

    $LblDet1.Text = "Đã tải xong. Vui lòng chọn phân vùng."
    $Form.Cursor = "Default"
}

$Grid.Add_SelectionChanged({
    if ($Grid.SelectedRows.Count -gt 0) {
        $Data = $Grid.SelectedRows[0].Tag
        $Global:SelectedPart = $Data
        
        $Name = if($Data.Let){"Ổ $($Data.Let)"}else{"Phân vùng hệ thống"}
        $LblDet1.Text = "Đang chọn: $Name (Disk $($Data.Did))  |  Tổng: $($Data.Total) GB  |  Label: $($Data.Lab)"
        
        $PBar.Value = [int]$Data.PUsed
        $LblPct.Text = "$($Data.PUsed)%"
    }
})

function Run-DP ($Cmd) {
    $F = "$env:TEMP\dp_run.txt"; [IO.File]::WriteAllText($F, $Cmd)
    Start-Process "diskpart" "/s `"$F`"" -Wait -NoNewWindow
    Remove-Item $F; Load-Data
}

function Run-Action ($Act) {
    if ($Act -eq "Refresh") { Load-Data; return }
    if ($Act -eq "FixBoot") { Start-Process "cmd" "/c bcdboot C:\Windows /s C: /f ALL & pause"; return }

    $P = $Global:SelectedPart
    if (!$P) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn dòng nào ở danh sách trên!", "Thông báo"); return }
    
    $Did = $P.Did; $Pid = $P.Pid; $Let = $P.Let

    switch ($Act) {
        "Letter" { 
            $N=[Microsoft.VisualBasic.Interaction]::InputBox("Ký tự mới (VD: Z):","Đổi Ký Tự","")
            if($N){ Run-DP "sel disk $Did`nsel part $Pid`nassign letter=$N" } 
        }
        "Label"  { 
            $N=[Microsoft.VisualBasic.Interaction]::InputBox("Tên ổ mới:","Đổi Tên",$P.Lab)
            if($N){ if($Let){ cmd /c "label $Let $N"; Load-Data } else {[System.Windows.Forms.MessageBox]::Show("Ổ này chưa có ký tự!","Lỗi")} }
        }
        "Format" { 
            if([System.Windows.Forms.MessageBox]::Show("FORMAT $Let? Dữ liệu sẽ mất sạch!","CẢNH BÁO","YesNo","Warning")-eq"Yes"){ 
                Run-DP "sel disk $Did`nsel part $Pid`nformat fs=ntfs quick" 
            } 
        }
        "Delete" { 
            if([System.Windows.Forms.MessageBox]::Show("XÓA PHÂN VÙNG $Pid?","NGUY HIỂM","YesNo","Error")-eq"Yes"){ 
                Run-DP "sel disk $Did`nsel part $Pid`ndelete partition override" 
            } 
        }
        "Active" { Run-DP "sel disk $Did`nsel part $Pid`nactive" }
        "ChkDsk" { if($Let){Start-Process "cmd" "/k chkdsk $Let /f /x"} }
        "Convert"{ 
            if([System.Windows.Forms.MessageBox]::Show("Convert Disk $Did? (Cần Clean Disk)","Hỏi","YesNo")-eq"Yes"){ 
                Run-DP "sel disk $Did`nclean`nconvert gpt" 
            } 
        }
    }
}

# --- INIT ---
Apply-Theme # Áp dụng màu lần đầu
$Timer = New-Object System.Windows.Forms.Timer; $Timer.Interval = 300
$Timer.Add_Tick({ $Timer.Stop(); Load-Data }); $Timer.Start()

$Form.ShowDialog() | Out-Null
