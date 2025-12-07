<#
    DISK MANAGER PRO - PHAT TAN PC (V8.0 CLASSIC EDITION)
    Style: Windows Standard (White/Clean) - Giống hình mẫu image_acc617.jpg
    Layout: Grid trên -> Info Bar giữa -> Tools dưới
#>

# --- 1. ADMIN CHECK ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-NoP -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- THEME CONFIG (CLASSIC WHITE) ---
$C = @{
    FormBg   = [System.Drawing.Color]::White
    Text     = [System.Drawing.Color]::Black
    GridBg   = [System.Drawing.Color]::White
    GridLine = [System.Drawing.Color]::Silver
    Accent   = [System.Drawing.Color]::FromArgb(0, 120, 215) # Xanh Windows
    Green    = [System.Drawing.Color]::FromArgb(34, 177, 76)  # Xanh lá cây (Thanh dung lượng)
    Red      = [System.Drawing.Color]::FromArgb(232, 17, 35)   # Đỏ (Xóa)
}

# --- GLOBAL VARS ---
$Global:SelectedPart = $null

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "QUẢN LÝ PHÂN VÙNG Ổ ĐĨA - PHAT TAN PC (V8.0)"
$Form.Size = New-Object System.Drawing.Size(1000, 650)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $C.FormBg
$Form.ForeColor = $C.Text
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# -- FONTS --
$F_Bold  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$F_Norm  = New-Object System.Drawing.Font("Segoe UI", 9)
$F_Small = New-Object System.Drawing.Font("Segoe UI", 8)

# ==================== PHẦN 1: DANH SÁCH (GRID) ====================
$GbList = New-Object System.Windows.Forms.GroupBox
$GbList.Text = "1. Danh sách phân vùng (Disk List)"
$GbList.Location = "10, 10"; $GbList.Size = "965, 250"
$GbList.Font = $F_Bold
$Form.Controls.Add($GbList)

$Grid = New-Object System.Windows.Forms.DataGridView
$Grid.Dock = "Fill"; $Grid.BackgroundColor = $C.GridBg; $Grid.ForeColor = "Black"
$Grid.AllowUserToAddRows = $false; $Grid.RowHeadersVisible = $false; $Grid.SelectionMode = "FullRowSelect"
$Grid.MultiSelect = $false; $Grid.ReadOnly = $true; $Grid.AutoSizeColumnsMode = "Fill"
$Grid.GridColor = $C.GridLine
$Grid.Font = $F_Norm

# Columns (Đúng yêu cầu: Ký tự, Tên, FS, Tổng, Đã dùng, %, Còn lại, Sức khỏe)
$Grid.Columns.Add("Disk", "Disk"); $Grid.Columns[0].Width = 50
$Grid.Columns.Add("Let", "Ký Tự"); $Grid.Columns[1].Width = 50
$Grid.Columns.Add("Label", "Tên Ổ (Label)"); $Grid.Columns[2].FillWeight = 120
$Grid.Columns.Add("FS", "Loại"); $Grid.Columns[3].Width = 60
$Grid.Columns.Add("Total", "Tổng"); $Grid.Columns[4].Width = 80
$Grid.Columns.Add("Used", "Đã dùng"); $Grid.Columns[5].Width = 80
$Grid.Columns.Add("PUse", "% Dùng"); $Grid.Columns[6].Width = 70
$Grid.Columns.Add("Free", "Còn lại"); $Grid.Columns[7].Width = 80
$Grid.Columns.Add("Health", "Sức khỏe"); $Grid.Columns[8].Width = 80

$GbList.Controls.Add($Grid)

# ==================== PHẦN 2: THÔNG TIN CHI TIẾT (INFO BAR) ====================
$GbInfo = New-Object System.Windows.Forms.GroupBox
$GbInfo.Text = "2. Thông tin chi tiết ổ đĩa đang chọn"
$GbInfo.Location = "10, 270"; $GbInfo.Size = "965, 100"
$GbInfo.Font = $F_Bold
$Form.Controls.Add($GbInfo)

# Labels
$LblDet1 = New-Object System.Windows.Forms.Label; $LblDet1.Location = "20, 25"; $LblDet1.AutoSize = $true; $LblDet1.Font = $F_Norm
$LblDet1.Text = "Vui lòng chọn một phân vùng ở bảng trên..."
$GbInfo.Controls.Add($LblDet1)

# Progress Bar (Thanh dung lượng xanh lá)
$PBar = New-Object System.Windows.Forms.ProgressBar
$PBar.Location = "20, 55"; $PBar.Size = "850, 25"
$PBar.Style = "Continuous" # Style liền mạch
$GbInfo.Controls.Add($PBar)

$LblPct = New-Object System.Windows.Forms.Label; $LblPct.Location = "880, 58"; $LblPct.AutoSize = $true; $LblPct.Font = $F_Norm
$LblPct.Text = "0%"
$GbInfo.Controls.Add($LblPct)

# ==================== PHẦN 3: CÔNG CỤ (TOOLS) ====================
$GbTool = New-Object System.Windows.Forms.GroupBox
$GbTool.Text = "3. Thao tác / Công cụ (Actions)"
$GbTool.Location = "10, 380"; $GbTool.Size = "965, 200"
$GbTool.Font = $F_Bold
$Form.Controls.Add($GbTool)

# --- Tool Group 1: Basic ---
$PnlT1 = New-Object System.Windows.Forms.Panel; $PnlT1.Location="20, 30"; $PnlT1.Size="300, 150"; $PnlT1.BorderStyle="FixedSingle"
$GbTool.Controls.Add($PnlT1)
$L_T1 = New-Object System.Windows.Forms.Label; $L_T1.Text="CƠ BẢN"; $L_T1.Dock="Top"; $L_T1.BackColor="LightGray"; $L_T1.TextAlign="MiddleCenter"
$PnlT1.Controls.Add($L_T1)

function Add-Btn ($Panel, $Txt, $Y, $Col, $Tag) {
    $B = New-Object System.Windows.Forms.Button; $B.Text=$Txt; $B.Tag=$Tag
    $B.Location="10,$Y"; $B.Size="278,35"; $B.FlatStyle="Flat"; $B.Font=$F_Norm
    $B.BackColor=$Col; $B.ForeColor="White"; $B.Cursor="Hand"
    $B.Add_Click({ Run-Action $this.Tag })
    $Panel.Controls.Add($B)
}

Add-Btn $PnlT1 "Làm mới danh sách (Refresh)" 30 $C.Accent "Refresh"
Add-Btn $PnlT1 "Đổi tên ổ đĩa (Label)" 70 [System.Drawing.Color]::DimGray "Label"
Add-Btn $PnlT1 "Đổi ký tự ổ (Change Letter)" 110 [System.Drawing.Color]::DimGray "Letter"

# --- Tool Group 2: System ---
$PnlT2 = New-Object System.Windows.Forms.Panel; $PnlT2.Location="330, 30"; $PnlT2.Size="300, 150"; $PnlT2.BorderStyle="FixedSingle"
$GbTool.Controls.Add($PnlT2)
$L_T2 = New-Object System.Windows.Forms.Label; $L_T2.Text="HỆ THỐNG & BOOT"; $L_T2.Dock="Top"; $L_T2.BackColor="LightGray"; $L_T2.TextAlign="MiddleCenter"
$PnlT2.Controls.Add($L_T2)

Add-Btn $PnlT2 "Set Active (Kích hoạt Boot)" 30 [System.Drawing.Color]::Orange "Active"
Add-Btn $PnlT2 "Nạp lại Boot (Fix BCD)" 70 [System.Drawing.Color]::Orange "FixBoot"
Add-Btn $PnlT2 "Sửa lỗi ổ cứng (CheckDisk)" 110 [System.Drawing.Color]::Green "ChkDsk"

# --- Tool Group 3: Danger ---
$PnlT3 = New-Object System.Windows.Forms.Panel; $PnlT3.Location="640, 30"; $PnlT3.Size="300, 150"; $PnlT3.BorderStyle="FixedSingle"
$GbTool.Controls.Add($PnlT3)
$L_T3 = New-Object System.Windows.Forms.Label; $L_T3.Text="VÙNG NGUY HIỂM"; $L_T3.Dock="Top"; $L_T3.BackColor="MistyRose"; $L_T3.TextAlign="MiddleCenter"; $L_T3.ForeColor="Red"
$PnlT3.Controls.Add($L_T3)

Add-Btn $PnlT3 "Format (Định dạng)" 30 $C.Red "Format"
Add-Btn $PnlT3 "Xóa phân vùng (Delete)" 70 $C.Red "Delete"
Add-Btn $PnlT3 "Convert GPT <-> MBR" 110 [System.Drawing.Color]::Gray "Convert"

# ==================== LOGIC ENGINE (WMI HYBRID) ====================

function Load-Data {
    $Grid.Rows.Clear()
    $Global:SelectedPart = $null
    $LblDet1.Text = "Đang tải dữ liệu..."
    $Form.Cursor = "WaitCursor"; $Form.Refresh()

    # Query WMI lấy Disk và Partition
    try {
        $Disks = @(Get-WmiObject Win32_DiskDrive)
        foreach ($D in $Disks) {
            # Map Partition của Disk này
            $Query = "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($D.DeviceID)'} WHERE AssocClass=Win32_DiskDriveToDiskPartition"
            $Parts = @(Get-WmiObject -Query $Query | Sort-Object Index)

            foreach ($P in $Parts) {
                # Map Logical Disk (Để lấy Letter, Label, Size thực)
                $LogQuery = "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($P.DeviceID)'} WHERE AssocClass=Win32_LogicalDiskToPartition"
                $LogDisk = Get-WmiObject -Query $LogQuery

                $TotalGB = [Math]::Round($P.Size / 1GB, 2)
                $DiskInfo = "Disk $($D.Index)"
                $Status = $D.Status

                if ($LogDisk) {
                    $Let = $LogDisk.DeviceID
                    $Lab = $LogDisk.VolumeName
                    $FS  = $LogDisk.FileSystem
                    $FreeGB = [Math]::Round($LogDisk.FreeSpace / 1GB, 2)
                    $UsedGB = [Math]::Round($TotalGB - $FreeGB, 2)
                    
                    $PctFree = if($TotalGB -gt 0){[Math]::Round(($FreeGB/$TotalGB)*100,0)}else{0}
                    $PctUsed = 100 - $PctFree
                    
                    $RowIdx = $Grid.Rows.Add($DiskInfo, $Let, $Lab, $FS, "$TotalGB GB", "$UsedGB GB", "$PctUsed%", "$FreeGB GB", $Status)
                    
                    # Lưu Data vào Tag
                    $Grid.Rows[$RowIdx].Tag = @{
                        Did=$D.Index; Pid=($P.Index+1); Let=$Let; Lab=$Lab; 
                        Total=$TotalGB; Free=$FreeGB; Used=$UsedGB; PUsed=$PctUsed
                    }
                } else {
                    # Phân vùng ẩn
                    $Type = $P.Type; if($P.Bootable){$Type+=" (Boot)"}
                    $RowIdx = $Grid.Rows.Add($DiskInfo, "", "[Hidden/System]", $Type, "$TotalGB GB", "-", "-", "-", $Status)
                    $Grid.Rows[$RowIdx].Tag = @{ Did=$D.Index; Pid=($P.Index+1); Let=$null; Lab="Hidden"; Total=$TotalGB; PUsed=0 }
                }
            }
        }
    } catch {}

    $LblDet1.Text = "Đã tải xong. Vui lòng chọn phân vùng."
    $Form.Cursor = "Default"
}

# --- SỰ KIỆN CLICK VÀO BẢNG ---
$Grid.Add_SelectionChanged({
    if ($Grid.SelectedRows.Count -gt 0) {
        $Data = $Grid.SelectedRows[0].Tag
        $Global:SelectedPart = $Data
        
        # Cập nhật Info Bar
        $Name = if($Data.Let){"Ổ $($Data.Let)"}else{"Phân vùng hệ thống"}
        $LblDet1.Text = "Đang chọn: $Name (Disk $($Data.Did))  |  Tổng: $($Data.Total) GB  |  Còn trống: $($Data.Free) GB"
        $LblDet1.ForeColor = $C.Accent
        
        # Cập nhật Progress Bar
        $PBar.Value = [int]$Data.PUsed
        $LblPct.Text = "$($Data.PUsed)%"
        
        # Đổi màu thanh bar tùy mức độ đầy
        if ($Data.PUsed -gt 90) { $PBar.ForeColor = [System.Drawing.Color]::Red } # Đầy > 90% màu đỏ (tùy chỉnh WinForms PB hơi khó, nhưng để logic)
    }
})

# --- ACTION HANDLERS ---
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

# --- LOAD ---
$Timer = New-Object System.Windows.Forms.Timer; $Timer.Interval = 300
$Timer.Add_Tick({ $Timer.Stop(); Load-Data }); $Timer.Start()

$Form.ShowDialog() | Out-Null
