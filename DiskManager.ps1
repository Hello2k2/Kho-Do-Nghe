<#
    DISK MANAGER PRO - PHAT TAN PC (V6.1 WMI EDITION)
    Engine: WMI/CIM (Native Windows Management) - Chính xác & Chi tiết
    Layout: Master-Detail Grid (Disk List -> Partition List)
#>

# --- 1. ADMIN CHECK ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    if ($PSCommandPath) { Start-Process powershell "-NoP -File `"$PSCommandPath`"" -Verb RunAs; Exit }
    else { Write-Host "Run as Administrator!" -F Red; Exit }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- THEME CONFIG (DARK MODE) ---
$C = @{
    BgForm   = [System.Drawing.Color]::FromArgb(30, 30, 30)
    BgPanel  = [System.Drawing.Color]::FromArgb(40, 40, 45)
    Text     = [System.Drawing.Color]::White
    TextDim  = [System.Drawing.Color]::Silver
    Accent   = [System.Drawing.Color]::Cyan
    GridBg   = [System.Drawing.Color]::FromArgb(20, 20, 20)
    GridLine = [System.Drawing.Color]::FromArgb(60, 60, 60)
    Btn      = [System.Drawing.Color]::FromArgb(60, 60, 70)
}

# --- GLOBAL VARS ---
$Global:SelectedDisk = $null
$Global:SelectedPart = $null # Object Partition

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "DISK MANAGER PRO V6.1 - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(1100, 700)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $C.BgForm
$Form.ForeColor = $C.Text
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# -- FONTS --
$FontBold = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$FontNorm = New-Object System.Drawing.Font("Segoe UI", 9)

# -- LAYOUT --
$Split = New-Object System.Windows.Forms.SplitContainer
$Split.Dock = "Fill"; $Split.Orientation = "Vertical"; $Split.SplitterDistance = 850
$Form.Controls.Add($Split)

# LEFT PANEL (DATA GRIDS)
$PnlLeft = $Split.Panel1
$PnlLeft.Padding = "10,10,10,10"

# -- SECTION 1: PHYSICAL DISKS --
$GbDisk = New-Object System.Windows.Forms.GroupBox; $GbDisk.Text = "1. DANH SÁCH Ổ CỨNG VẬT LÝ (PHYSICAL DISKS)"; $GbDisk.ForeColor = $C.Accent; $GbDisk.Dock = "Top"; $GbDisk.Height = 200
$PnlLeft.Controls.Add($GbDisk)

$GridDisk = New-Object System.Windows.Forms.DataGridView
$GridDisk.Dock = "Fill"; $GridDisk.BackgroundColor = $C.GridBg; $GridDisk.ForeColor = "Black" # Text đen cho dễ đọc trên nền trắng mặc định của cell
$GridDisk.AllowUserToAddRows = $false; $GridDisk.RowHeadersVisible = $false; $GridDisk.SelectionMode = "FullRowSelect"; $GridDisk.MultiSelect = $false; $GridDisk.ReadOnly = $true; $GridDisk.AutoSizeColumnsMode = "Fill"
$GridDisk.GridColor = $C.GridLine
# Columns
$GridDisk.Columns.Add("ID", "Disk #"); $GridDisk.Columns[0].Width = 60
$GridDisk.Columns.Add("Model", "Tên Ổ Cứng (Model)"); $GridDisk.Columns[1].FillWeight = 150
$GridDisk.Columns.Add("Type", "Loại (MBR/GPT)"); $GridDisk.Columns[2].Width = 100
$GridDisk.Columns.Add("Size", "Tổng Dung Lượng"); $GridDisk.Columns[3].Width = 120
$GridDisk.Columns.Add("Health", "Sức Khỏe"); $GridDisk.Columns[4].Width = 100
$GridDisk.Columns.Add("Status", "Trạng Thái"); $GridDisk.Columns[5].Width = 100
$GbDisk.Controls.Add($GridDisk)

# -- SECTION 2: PARTITIONS --
$GbPart = New-Object System.Windows.Forms.GroupBox; $GbPart.Text = "2. CHI TIẾT PHÂN VÙNG (PARTITIONS & VOLUMES)"; $GbPart.ForeColor = $C.Accent; $GbPart.Dock = "Fill"
$GbPart.Padding = "3,10,3,3" # Top padding để cách title ra
$PnlLeft.Controls.Add($GbPart)
# Spacer Panel để tạo khoảng cách giữa 2 groupbox
$PnlSpacer = New-Object System.Windows.Forms.Panel; $PnlSpacer.Dock="Top"; $PnlSpacer.Height=10; $PnlLeft.Controls.Add($PnlSpacer)

$GridPart = New-Object System.Windows.Forms.DataGridView
$GridPart.Dock = "Fill"; $GridPart.BackgroundColor = $C.GridBg; $GridPart.ForeColor = "Black"
$GridPart.AllowUserToAddRows = $false; $GridPart.RowHeadersVisible = $false; $GridPart.SelectionMode = "FullRowSelect"; $GridPart.MultiSelect = $false; $GridPart.ReadOnly = $true; $GridPart.AutoSizeColumnsMode = "Fill"
$GridPart.GridColor = $C.GridLine
# Columns Chi Tiết
$GridPart.Columns.Add("Let", "Ký Tự"); $GridPart.Columns[0].Width = 50
$GridPart.Columns.Add("Label", "Tên Ổ (Label)"); $GridPart.Columns[1].FillWeight = 120
$GridPart.Columns.Add("FS", "Định Dạng"); $GridPart.Columns[2].Width = 80
$GridPart.Columns.Add("Total", "Tổng (GB)"); $GridPart.Columns[3].Width = 80
$GridPart.Columns.Add("Used", "Đã Dùng (GB)"); $GridPart.Columns[4].Width = 90
$GridPart.Columns.Add("Free", "Còn Lại (GB)"); $GridPart.Columns[5].Width = 90
$GridPart.Columns.Add("PctUsed", "% Dùng"); $GridPart.Columns[6].Width = 70
$GridPart.Columns.Add("PctFree", "% Trống"); $GridPart.Columns[7].Width = 70
$GridPart.Columns.Add("Stat", "Trạng Thái"); $GridPart.Columns[8].Width = 100
$GbPart.Controls.Add($GridPart)


# RIGHT PANEL (TOOLS)
$PnlRight = $Split.Panel2
$PnlRight.BackColor = $C.BgPanel
$PnlRight.Padding = "10,20,10,10"

$LblTools = New-Object System.Windows.Forms.Label; $LblTools.Text = "CÔNG CỤ"; $LblTools.Font = $FontBold; $LblTools.ForeColor = $C.Accent; $LblTools.AutoSize = $true; $LblTools.Location = "10,10"
$PnlRight.Controls.Add($LblTools)

$FlowTools = New-Object System.Windows.Forms.FlowLayoutPanel
$FlowTools.Location = "10, 40"; $FlowTools.Size = "220, 600"; $FlowTools.FlowDirection = "TopDown"
$PnlRight.Controls.Add($FlowTools)

# --- FUNCTIONS ---

# Hàm thêm nút Tool
function Add-BtnTool ($Txt, $Tag, $Color) {
    $Btn = New-Object System.Windows.Forms.Button
    $Btn.Text = $Txt
    $Btn.Tag = $Tag
    $Btn.Size = New-Object System.Drawing.Size(210, 40)
    $Btn.Margin = "0,0,0,10"
    $Btn.FlatStyle = "Flat"; $Btn.FlatAppearance.BorderSize = 0
    $Btn.BackColor = $C.Btn
    $Btn.ForeColor = "White"
    $Btn.Font = $FontNorm
    $Btn.Cursor = "Hand"
    
    # Border trái
    $Pn = New-Object System.Windows.Forms.Panel; $Pn.Width=4; $Pn.Dock="Left"; $Pn.BackColor=$Color; $Btn.Controls.Add($Pn)
    
    $Btn.Add_Click({ Run-Action $this.Tag })
    $FlowTools.Controls.Add($Btn)
}

Add-BtnTool "Làm Mới (Refresh)" "Refresh" [System.Drawing.Color]::Cyan
Add-BtnTool "Đổi Ký Tự Ổ" "Letter" [System.Drawing.Color]::Orange
Add-BtnTool "Đổi Tên (Label)" "Label" [System.Drawing.Color]::Orange
Add-BtnTool "Format (Định Dạng)" "Format" [System.Drawing.Color]::Red
Add-BtnTool "Set Active" "Active" [System.Drawing.Color]::Gold
Add-BtnTool "Xóa Phân Vùng" "Delete" [System.Drawing.Color]::Red
Add-BtnTool "Check Disk (Fix Lỗi)" "ChkDsk" [System.Drawing.Color]::LightGreen
Add-BtnTool "Convert MBR <-> GPT" "Convert" [System.Drawing.Color]::Gray

# --- CORE LOGIC (WMI ENGINE) ---

function Load-Disks {
    $GridDisk.Rows.Clear(); $GridPart.Rows.Clear()
    $Global:SelectedDisk = $null; $Global:SelectedPart = $null
    $Form.Cursor = "WaitCursor"

    # Lấy danh sách Disk vật lý
    $Disks = Get-Disk | Sort-Object Number
    
    foreach ($D in $Disks) {
        $SizeGB = [Math]::Round($D.Size / 1GB, 1).ToString() + " GB"
        $Style = if ($D.PartitionStyle -eq "RAW") { "Chưa Init" } else { $D.PartitionStyle }
        $Health = if ($D.HealthStatus -eq "Healthy") { "Tốt (Healthy)" } else { "Cảnh báo ($($D.HealthStatus))" }
        $Status = if ($D.OperationalStatus -eq "Online") { "Online" } else { "Offline" }
        
        $Idx = $GridDisk.Rows.Add($D.Number, $D.FriendlyName, $Style, $SizeGB, $Health, $Status)
        $GridDisk.Rows[$Idx].Tag = $D # Lưu object Disk vào Row
    }
    
    if ($GridDisk.Rows.Count -gt 0) {
        $GridDisk.Rows[0].Selected = $true
        Load-Partitions $GridDisk.Rows[0].Tag
    }
    $Form.Cursor = "Default"
}

function Load-Partitions ($DiskObj) {
    $GridPart.Rows.Clear()
    $Global:SelectedDisk = $DiskObj
    $GbPart.Text = "2. CHI TIẾT PHÂN VÙNG CỦA DISK $($DiskObj.Number) - $($DiskObj.FriendlyName)"
    
    # Lấy Partitions của Disk này
    $Parts = Get-Partition -DiskNumber $DiskObj.Number | Sort-Object PartitionNumber
    
    foreach ($P in $Parts) {
        # Lấy Volume Info (Label, Size, Free...)
        $Vol = $null
        try { $Vol = $P | Get-Volume -ErrorAction SilentlyContinue } catch {}
        
        $Let = if ($P.DriveLetter) { "$($P.DriveLetter):" } else { "" }
        $Type = $P.Type
        
        if ($Vol) {
            $Lab = if ($Vol.FileSystemLabel) { $Vol.FileSystemLabel } else { "(No Name)" }
            $FS = $Vol.FileSystem
            
            $Total = [Math]::Round($Vol.Size / 1GB, 2)
            $Free  = [Math]::Round($Vol.SizeRemaining / 1GB, 2)
            $Used  = [Math]::Round($Total - $Free, 2)
            
            if ($Total -gt 0) {
                $PctFree = [Math]::Round(($Free / $Total) * 100, 1)
                $PctUsed = [Math]::Round(100 - $PctFree, 1)
            } else { $PctFree=0; $PctUsed=0 }
            
            $Stat = "OK"
        } else {
            # Phân vùng hệ thống / Recovery / Hidden
            $Lab = $Type
            $FS = "-"
            $Total = [Math]::Round($P.Size / 1GB, 2)
            $Used = "-"; $Free = "-"; $PctUsed = "-"; $PctFree = "-"
            $Stat = "System/Hidden"
        }
        
        # Add to Grid
        $Idx = $GridPart.Rows.Add($Let, $Lab, $FS, $Total, $Used, $Free, "$PctUsed%", "$PctFree%", $Stat)
        
        # Tạo Object tùy chỉnh để lưu vào Tag phục vụ cho các nút Tool
        $PartInfo = @{
            DiskId = $DiskObj.Number
            PartId = $P.PartitionNumber
            Letter = if($P.DriveLetter){"$($P.DriveLetter)"}else{$null}
            Label  = $Lab
            Obj    = $P # Lưu object gốc để thao tác
        }
        $GridPart.Rows[$Idx].Tag = $PartInfo
    }
}

# Sự kiện Click chọn Disk -> Load Partition
$GridDisk.Add_CellClick({
    if ($GridDisk.SelectedRows.Count -gt 0) {
        Load-Partitions $GridDisk.SelectedRows[0].Tag
    }
})

# Sự kiện Click chọn Partition
$GridPart.Add_CellClick({
    if ($GridPart.SelectedRows.Count -gt 0) {
        $Global:SelectedPart = $GridPart.SelectedRows[0].Tag
    }
})

# --- ACTION HANDLERS ---
function Run-DP ($Cmd) {
    $F = "$env:TEMP\dp.txt"; [IO.File]::WriteAllText($F, $Cmd)
    Start-Process "diskpart" "/s `"$F`"" -Wait -NoNewWindow
    Remove-Item $F; Load-Disks
}

function Run-Action ($Act) {
    if ($Act -eq "Refresh") { Load-Disks; return }
    
    $P = $Global:SelectedPart
    if (!$P) { [System.Windows.Forms.MessageBox]::Show("Vui lòng chọn 1 Phân Vùng ở bảng dưới!", "Chưa chọn"); return }
    
    $Did = $P.DiskId; $Pid = $P.PartId; $Let = $P.Letter

    switch ($Act) {
        "Letter" {
            $New = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập ký tự mới (VD: Z):", "Đổi Ký Tự", "")
            if ($New) { 
                # Dùng Native PowerShell thay vì Diskpart cho nhanh
                try { Set-Partition -DiskNumber $Did -PartitionNumber $Pid -NewDriveLetter $New; Load-Disks } 
                catch { [System.Windows.Forms.MessageBox]::Show("Lỗi: $($_.Exception.Message)", "Error") }
            }
        }
        "Label" {
            $New = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập tên ổ mới:", "Đổi Tên", $P.Label)
            if ($New) {
                try { Set-Volume -DriveLetter $Let -NewFileSystemLabel $New; Load-Disks }
                catch { [System.Windows.Forms.MessageBox]::Show("Lỗi (Có thể ổ chưa có ký tự?): $($_.Exception.Message)", "Error") }
            }
        }
        "Format" {
            if ([System.Windows.Forms.MessageBox]::Show("FORMAT Ổ $Let (Disk $Did Part $Pid)?`nDữ liệu sẽ mất hết!", "CẢNH BÁO", "YesNo", "Warning") -eq "Yes") {
                Run-DP "sel disk $Did`nsel part $Pid`nformat fs=ntfs quick"
            }
        }
        "Delete" {
            if ([System.Windows.Forms.MessageBox]::Show("XÓA PHÂN VÙNG $Pid?`n(Disk $Did)", "NGUY HIỂM", "YesNo", "Error") -eq "Yes") {
                Run-DP "sel disk $Did`nsel part $Pid`ndelete partition override"
            }
        }
        "Active" { Run-DP "sel disk $Did`nsel part $Pid`nactive" }
        "ChkDsk" {
            if ($Let) { Start-Process "cmd" "/k chkdsk $Let`: /f /x" } 
            else { [System.Windows.Forms.MessageBox]::Show("Phân vùng này không có Ký tự ổ!", "Lỗi") }
        }
        "Convert" {
            if ([System.Windows.Forms.MessageBox]::Show("Chuyển đổi Disk $Did sang GPT/MBR?`nYêu cầu Disk phải Trống (Clean)!", "Hỏi", "YesNo") -eq "Yes") {
                if ($Global:SelectedDisk.PartitionStyle -eq "MBR") { Run-DP "sel disk $Did`nclean`nconvert gpt" }
                else { Run-DP "sel disk $Did`nclean`nconvert mbr" }
            }
        }
    }
}

# Init
$Form.Add_Shown({ Load-Disks })
$Form.ShowDialog() | Out-Null
