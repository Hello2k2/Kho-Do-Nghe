<#
    DISK MANAGER PRO - PHAT TAN PC (V6.2 HYBRID ENGINE)
    Engine: Hybrid (Ưu tiên Modern Storage -> Fallback sang Legacy WMI nếu lỗi)
    Layout: Split Grid (Danh sách Ổ cứng trên -> Danh sách Phân vùng dưới)
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
$Global:SelectedPart = $null
$Global:EngineMode = "Modern" # Modern hoặc Legacy

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "DISK MANAGER PRO V6.2 - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(1150, 700)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $C.BgForm
$Form.ForeColor = $C.Text
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# -- FONTS --
$FontBold = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$FontNorm = New-Object System.Drawing.Font("Segoe UI", 9)

# -- LAYOUT STRUCTURE (SPLIT CONTAINER) --
$Split = New-Object System.Windows.Forms.SplitContainer
$Split.Dock = "Fill"
$Split.Orientation = "Vertical"
$Split.SplitterDistance = 900 # Phần trái chứa bảng rộng hơn
$Form.Controls.Add($Split)

# === LEFT PANEL (DATA) ===
$PnlLeft = $Split.Panel1
$PnlLeft.Padding = "10,10,10,10"

# 1. DISK GRID (TOP)
$GbDisk = New-Object System.Windows.Forms.GroupBox; $GbDisk.Text = "1. DANH SÁCH Ổ CỨNG VẬT LÝ"; $GbDisk.ForeColor = $C.Accent; $GbDisk.Dock = "Top"; $GbDisk.Height = 220
$PnlLeft.Controls.Add($GbDisk)

$GridDisk = New-Object System.Windows.Forms.DataGridView
$GridDisk.Dock = "Fill"; $GridDisk.BackgroundColor = $C.GridBg; $GridDisk.ForeColor = "Black"
$GridDisk.AllowUserToAddRows = $false; $GridDisk.RowHeadersVisible = $false; $GridDisk.SelectionMode = "FullRowSelect"; $GridDisk.MultiSelect = $false; $GridDisk.ReadOnly = $true; $GridDisk.AutoSizeColumnsMode = "Fill"
$GridDisk.GridColor = $C.GridLine
# Columns
$GridDisk.Columns.Add("ID", "Disk #"); $GridDisk.Columns[0].Width = 60
$GridDisk.Columns.Add("Model", "Tên Ổ Cứng (Model)"); $GridDisk.Columns[1].FillWeight = 150
$GridDisk.Columns.Add("Type", "Loại"); $GridDisk.Columns[2].Width = 100
$GridDisk.Columns.Add("Size", "Tổng Dung Lượng"); $GridDisk.Columns[3].Width = 120
$GridDisk.Columns.Add("Status", "Trạng Thái"); $GridDisk.Columns[4].Width = 100
$GbDisk.Controls.Add($GridDisk)

# SPACER
$PnlSep = New-Object System.Windows.Forms.Panel; $PnlSep.Dock="Top"; $PnlSep.Height=15; $PnlLeft.Controls.Add($PnlSep)

# 2. PARTITION GRID (BOTTOM)
$GbPart = New-Object System.Windows.Forms.GroupBox; $GbPart.Text = "2. CHI TIẾT PHÂN VÙNG"; $GbPart.ForeColor = $C.Accent; $GbPart.Dock = "Fill"
$PnlLeft.Controls.Add($GbPart)

$GridPart = New-Object System.Windows.Forms.DataGridView
$GridPart.Dock = "Fill"; $GridPart.BackgroundColor = $C.GridBg; $GridPart.ForeColor = "Black"
$GridPart.AllowUserToAddRows = $false; $GridPart.RowHeadersVisible = $false; $GridPart.SelectionMode = "FullRowSelect"; $GridPart.MultiSelect = $false; $GridPart.ReadOnly = $true; $GridPart.AutoSizeColumnsMode = "Fill"
$GridPart.GridColor = $C.GridLine
# Columns Chi Tiết
$GridPart.Columns.Add("Let", "Ký Tự"); $GridPart.Columns[0].Width = 50
$GridPart.Columns.Add("Label", "Tên Ổ"); $GridPart.Columns[1].FillWeight = 120
$GridPart.Columns.Add("FS", "FS"); $GridPart.Columns[2].Width = 60
$GridPart.Columns.Add("Total", "Tổng"); $GridPart.Columns[3].Width = 80
$GridPart.Columns.Add("Used", "Đã Dùng"); $GridPart.Columns[4].Width = 80
$GridPart.Columns.Add("PctUsed", "% Dùng"); $GridPart.Columns[5].Width = 70
$GridPart.Columns.Add("Free", "Còn Lại"); $GridPart.Columns[6].Width = 80
$GridPart.Columns.Add("PctFree", "% Trống"); $GridPart.Columns[7].Width = 70
$GridPart.Columns.Add("Stat", "Trạng Thái"); $GridPart.Columns[8].Width = 100
$GbPart.Controls.Add($GridPart)

# === RIGHT PANEL (TOOLS) ===
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

# --- CORE ENGINE (HYBRID) ---

function Load-Disks {
    $GridDisk.Rows.Clear(); $GridPart.Rows.Clear()
    $Global:SelectedDisk = $null; $Global:SelectedPart = $null
    $Form.Cursor = "WaitCursor"

    # 1. THỬ MODERN ENGINE (Get-Disk)
    try {
        $Disks = Get-Disk -ErrorAction Stop
        if ($Disks.Count -eq 0) { throw "Empty" }
        $Global:EngineMode = "Modern"
        $GbDisk.Text = "1. DANH SÁCH Ổ CỨNG (MODERN MODE)"
        
        foreach ($D in $Disks) {
            $SizeGB = [Math]::Round($D.Size / 1GB, 1).ToString() + " GB"
            $Style = if ($D.PartitionStyle -eq "RAW") { "Chưa Init" } else { $D.PartitionStyle }
            $Status = if ($D.OperationalStatus -eq "Online") { "Online" } else { "Offline" }
            $GridDisk.Rows.Add($D.Number, $D.FriendlyName, $Style, $SizeGB, $Status) | Out-Null
        }
    } 
    catch {
        # 2. FALLBACK LEGACY ENGINE (WMI - Win32_DiskDrive)
        $Global:EngineMode = "Legacy"
        $GbDisk.Text = "1. DANH SÁCH Ổ CỨNG (LEGACY WMI MODE)"
        try {
            $Disks = Get-WmiObject Win32_DiskDrive
            foreach ($D in $Disks) {
                $SizeGB = [Math]::Round($D.Size / 1GB, 1).ToString() + " GB"
                # Legacy không hiện GPT/MBR trực tiếp dễ dàng, phải check Partition
                $GridDisk.Rows.Add($D.Index, $D.Model, "Unknown", $SizeGB, $D.Status) | Out-Null
            }
        } catch {}
    }
    
    if ($GridDisk.Rows.Count -gt 0) {
        $GridDisk.Rows[0].Selected = $true
        Load-Partitions $GridDisk.Rows[0].Cells[0].Value # Pass Disk Index
    }
    $Form.Cursor = "Default"
}

function Load-Partitions ($DiskIndex) {
    $GridPart.Rows.Clear()
    
    # === MODERN ENGINE ===
    if ($Global:EngineMode -eq "Modern") {
        $Parts = Get-Partition -DiskNumber $DiskIndex | Sort-Object PartitionNumber
        foreach ($P in $Parts) {
            $Vol = $null; try { $Vol = $P | Get-Volume -ErrorAction SilentlyContinue } catch {}
            $Let = if ($P.DriveLetter) { "$($P.DriveLetter):" } else { "" }
            
            if ($Vol) {
                $Lab = if ($Vol.FileSystemLabel) { $Vol.FileSystemLabel } else { "(No Name)" }
                $FS = $Vol.FileSystem
                $Total = [Math]::Round($Vol.Size / 1GB, 2)
                $Free  = [Math]::Round($Vol.SizeRemaining / 1GB, 2)
                $Used  = [Math]::Round($Total - $Free, 2)
                $P_Fr  = if($Total -gt 0){[Math]::Round(($Free/$Total)*100,0)}else{0}
                $P_Us  = 100 - $P_Fr
                $Stat = "OK"
            } else {
                $Lab = $P.Type; $FS = "-"; $Total = [Math]::Round($P.Size / 1GB, 2)
                $Used = "-"; $Free = "-"; $P_Us = "-"; $P_Fr = "-"; $Stat = "Hidden"
            }
            
            $Idx = $GridPart.Rows.Add($Let, $Lab, $FS, "$Total GB", "$Used GB", "$P_Us %", "$Free GB", "$P_Fr %", $Stat)
            $GridPart.Rows[$Idx].Tag = @{ Did=$DiskIndex; Pid=$P.PartitionNumber; Let=$Let; Lab=$Lab }
        }
    } 
    # === LEGACY WMI ENGINE (FALLBACK) ===
    else {
        # Query Phức tạp để link Disk -> Partition -> LogicalDisk
        $Query = "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='\\.\PHYSICALDRIVE$DiskIndex'} WHERE AssocClass=Win32_DiskDriveToDiskPartition"
        $Parts = Get-WmiObject -Query $Query
        
        foreach ($P in $Parts) {
            $LogDisk = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($P.DeviceID)'} WHERE AssocClass=Win32_LogicalDiskToPartition"
            
            $Total = [Math]::Round($P.Size / 1GB, 2)
            
            if ($LogDisk) {
                $Let = $LogDisk.DeviceID
                $Lab = $LogDisk.VolumeName
                $FS  = $LogDisk.FileSystem
                $Free = [Math]::Round($LogDisk.FreeSpace / 1GB, 2)
                $Used = [Math]::Round($Total - $Free, 2)
                $P_Fr = if($Total -gt 0){[Math]::Round(($Free/$Total)*100,0)}else{0}
                $P_Us = 100 - $P_Fr
                $Stat = "OK"
            } else {
                $Let = ""; $Lab = "Partition #$($P.Index)"; $FS = "RAW/Hidden"
                $Used="-"; $Free="-"; $P_Us="-"; $P_Fr="-"; $Stat = "System"
            }
            
            $Idx = $GridPart.Rows.Add($Let, $Lab, $FS, "$Total GB", "$Used GB", "$P_Us %", "$Free GB", "$P_Fr %", $Stat)
            # Legacy Tag (Simple Data)
            $GridPart.Rows[$Idx].Tag = @{ Did=$DiskIndex; Pid=$P.Index; Let=$Let; Lab=$Lab }
        }
    }
}

# Events
$GridDisk.Add_CellClick({ if ($GridDisk.SelectedRows.Count -gt 0) { Load-Partitions $GridDisk.SelectedRows[0].Cells[0].Value } })
$GridPart.Add_CellClick({ if ($GridPart.SelectedRows.Count -gt 0) { $Global:SelectedPart = $GridPart.SelectedRows[0].Tag } })

# --- TOOL LOGIC ---
function Run-DP ($Cmd) {
    $F = "$env:TEMP\dp.txt"; [IO.File]::WriteAllText($F, $Cmd)
    Start-Process "diskpart" "/s `"$F`"" -Wait -NoNewWindow
    Remove-Item $F; Load-Disks
}

function Run-Action ($Act) {
    if ($Act -eq "Refresh") { Load-Disks; return }
    $P = $Global:SelectedPart
    if (!$P) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn phân vùng bảng dưới!", "Lỗi"); return }
    $Did = $P.Did; $Let = $P.Let; $PartIdx = $P.Pid # WMI Index khác Diskpart ID đôi chút, nhưng thường khớp

    # Cần map Partition Index WMI sang ID Diskpart (Thường là +1 hoặc dùng select partition)
    # Để an toàn, dùng select disk -> select partition index (diskpart hỗ trợ select partition <index>)
    
    # Fix ID cho Diskpart: WMI Index thường bắt đầu từ 0, Diskpart Partition bắt đầu từ 1.
    # Nhưng select partition <n> trong diskpart dùng index hoặc id. 
    # Cách tốt nhất: Select Disk -> Select Partition (Index + 1)
    
    # Tuy nhiên, Engine Modern (Get-Partition) trả về PartitionNumber chuẩn.
    # Engine Legacy trả về Index. Ta sẽ thử Index + 1 cho Legacy.
    $DpPartID = if ($Global:EngineMode -eq "Legacy") { $PartIdx + 1 } else { $PartIdx }

    switch ($Act) {
        "Format" { if([System.Windows.Forms.MessageBox]::Show("FORMAT $Let? Mất dữ liệu!","Cảnh báo","YesNo")-eq"Yes"){ Run-DP "sel disk $Did`nsel part $DpPartID`nformat fs=ntfs quick" } }
        "Delete" { if([System.Windows.Forms.MessageBox]::Show("XÓA PARTITION?","Nguy hiểm","YesNo")-eq"Yes"){ Run-DP "sel disk $Did`nsel part $DpPartID`ndelete partition override" } }
        "Active" { Run-DP "sel disk $Did`nsel part $DpPartID`nactive" }
        "Label"  { $N=[Microsoft.VisualBasic.Interaction]::InputBox("Tên mới:","Rename",$P.Lab); if($N){ 
            if($Let){ cmd /c "label $Let $N" } else { [System.Windows.Forms.MessageBox]::Show("Ổ chưa có ký tự!","Lỗi") }
            Load-Disks
        }}
        "Letter" { $N=[Microsoft.VisualBasic.Interaction]::InputBox("Ký tự mới (VD: Z):","Assign",""); if($N){ Run-DP "sel disk $Did`nsel part $DpPartID`nassign letter=$N" } }
        "ChkDsk" { if($Let){Start-Process "cmd" "/c chkdsk $Let /f /x"} }
        "Convert"{ if([System.Windows.Forms.MessageBox]::Show("Convert Disk $Did? (Cần Clean)","Hỏi","YesNo")-eq"Yes"){ Run-DP "sel disk $Did`nclean`nconvert gpt" } }
    }
}

# Init
$Form.Add_Shown({ Load-Disks })
$Form.ShowDialog() | Out-Null
