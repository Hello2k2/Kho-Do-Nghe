<#
    DISK MANAGER PRO - PHAT TAN PC (V7.1 STABLE)
    UI: Ribbon Toolbar (Thanh ngang) + Grid Layout (Bảng)
    Engine: Hybrid (Tự động chuyển WMI nếu Get-Disk lỗi/rỗng)
#>

# --- 1. ADMIN CHECK ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-NoP -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- CONFIG ---
$C = @{
    FormBg   = [System.Drawing.Color]::FromArgb(30, 30, 30)
    PanelBg  = [System.Drawing.Color]::FromArgb(45, 45, 48)
    GridBg   = [System.Drawing.Color]::FromArgb(25, 25, 25)
    Text     = [System.Drawing.Color]::White
    Accent   = [System.Drawing.Color]::FromArgb(0, 120, 215)
    Warning  = [System.Drawing.Color]::Gold
    Danger   = [System.Drawing.Color]::IndianRed
    BtnBg    = [System.Drawing.Color]::FromArgb(60, 60, 60)
    BtnHover = [System.Drawing.Color]::FromArgb(80, 80, 80)
}

$Global:SelectedDisk = $null
$Global:SelectedPart = $null
$Global:UseWMI = $false # Cờ kiểm tra chế độ chạy

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "DISK MANAGER PRO V7.1 - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(1100, 750)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $C.FormBg
$Form.ForeColor = $C.Text
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# -- FONTS --
$F_Title = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$F_Btn   = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$F_Norm  = New-Object System.Drawing.Font("Segoe UI", 9)

# === TOP TOOLBAR (RIBBON) ===
$PnlTop = New-Object System.Windows.Forms.Panel; $PnlTop.Dock="Top"; $PnlTop.Height=100; $PnlTop.BackColor=$C.PanelBg; $PnlTop.Padding="10,10,10,10"
$Form.Controls.Add($PnlTop)

$LblInfo = New-Object System.Windows.Forms.Label; $LblInfo.Text="ĐANG TẢI..."; $LblInfo.Font=$F_Title; $LblInfo.ForeColor=$C.Warning; $LblInfo.AutoSize=$true; $LblInfo.Location="10,10"
$PnlTop.Controls.Add($LblInfo)

$FlowTool = New-Object System.Windows.Forms.FlowLayoutPanel; $FlowTool.Dock="Bottom"; $FlowTool.Height=55; $FlowTool.FlowDirection="LeftToRight"; $FlowTool.WrapContents=$false; $FlowTool.AutoScroll=$true
$PnlTop.Controls.Add($FlowTool)

# === MAIN GRIDS ===
$Split = New-Object System.Windows.Forms.SplitContainer; $Split.Dock="Fill"; $Split.Orientation="Horizontal"; $Split.SplitterDistance=250
$Form.Controls.Add($Split)

# GRID 1: DISK
$GbDisk = New-Object System.Windows.Forms.GroupBox; $GbDisk.Text="1. DANH SÁCH Ổ CỨNG VẬT LÝ"; $GbDisk.ForeColor=$C.Accent; $GbDisk.Dock="Fill"
$Split.Panel1.Controls.Add($GbDisk); $Split.Panel1.Padding="10,10,10,0"

$GridDisk = New-Object System.Windows.Forms.DataGridView; $GridDisk.Dock="Fill"; $GridDisk.BackgroundColor=$C.GridBg; $GridDisk.ForeColor="Black"
$GridDisk.AllowUserToAddRows=$false; $GridDisk.RowHeadersVisible=$false; $GridDisk.SelectionMode="FullRowSelect"; $GridDisk.MultiSelect=$false; $GridDisk.ReadOnly=$true; $GridDisk.AutoSizeColumnsMode="Fill"
$GridDisk.Columns.Add("ID","Disk #"); $GridDisk.Columns[0].Width=60
$GridDisk.Columns.Add("Model","Tên Ổ Cứng (Model)"); 
$GridDisk.Columns.Add("Style","Kiểu"); $GridDisk.Columns[2].Width=100
$GridDisk.Columns.Add("Size","Tổng Dung Lượng"); $GridDisk.Columns[3].Width=120
$GridDisk.Columns.Add("Status","Trạng Thái"); $GridDisk.Columns[4].Width=100
$GbDisk.Controls.Add($GridDisk)

# GRID 2: PARTITION
$GbPart = New-Object System.Windows.Forms.GroupBox; $GbPart.Text="2. CHI TIẾT PHÂN VÙNG"; $GbPart.ForeColor=$C.Accent; $GbPart.Dock="Fill"
$Split.Panel2.Controls.Add($GbPart); $Split.Panel2.Padding="10,0,10,10"

$GridPart = New-Object System.Windows.Forms.DataGridView; $GridPart.Dock="Fill"; $GridPart.BackgroundColor=$C.GridBg; $GridPart.ForeColor="Black"
$GridPart.AllowUserToAddRows=$false; $GridPart.RowHeadersVisible=$false; $GridPart.SelectionMode="FullRowSelect"; $GridPart.MultiSelect=$false; $GridPart.ReadOnly=$true; $GridPart.AutoSizeColumnsMode="Fill"
$GridPart.Columns.Add("Let","Ký Tự"); $GridPart.Columns[0].Width=60
$GridPart.Columns.Add("Label","Tên Ổ (Label)"); $GridPart.Columns[1].FillWeight=120
$GridPart.Columns.Add("FS","FS"); $GridPart.Columns[2].Width=60
$GridPart.Columns.Add("Total","Tổng"); $GridPart.Columns[3].Width=80
$GridPart.Columns.Add("Used","Đã Dùng"); $GridPart.Columns[4].Width=80
$GridPart.Columns.Add("Free","Còn Lại"); $GridPart.Columns[5].Width=80
$GridPart.Columns.Add("Stat","Trạng Thái"); $GridPart.Columns[6].Width=100
$GbPart.Controls.Add($GridPart)

# --- BUTTON HELPER ---
function Add-Btn ($Txt, $Icon, $Tag, $Color) {
    $Btn = New-Object System.Windows.Forms.Button; $Btn.Text="$Icon $Txt"; $Btn.Tag=$Tag
    $Btn.Size="130, 45"; $Btn.Margin="0,0,5,0"; $Btn.FlatStyle="Flat"; $Btn.FlatAppearance.BorderSize=0
    $Btn.BackColor=$C.BtnBg; $Btn.ForeColor=$C.Text; $Btn.Font=$F_Btn; $Btn.Cursor="Hand"
    $Pn=New-Object System.Windows.Forms.Panel; $Pn.Height=4; $Pn.Dock="Bottom"; $Pn.BackColor=$Color; $Btn.Controls.Add($Pn)
    $Btn.Add_MouseEnter({$this.BackColor=$C.BtnHover}); $Btn.Add_MouseLeave({$this.BackColor=$C.BtnBg})
    $Btn.Add_Click({Run-Action $this.Tag}); $FlowTool.Controls.Add($Btn)
}

Add-Btn "Làm Mới" "♻️" "Refresh" $C.Accent
Add-Btn "Đổi Ký Tự" "🔠" "Letter" [System.Drawing.Color]::Orange
Add-Btn "Đổi Tên" "🏷️" "Label" [System.Drawing.Color]::Orange
Add-Btn "Set Active" "⚡" "Active" $C.Warning
Add-Btn "Check Disk" "🚑" "ChkDsk" [System.Drawing.Color]::LightGreen
Add-Btn "Convert" "🔄" "Convert" [System.Drawing.Color]::Gray
Add-Btn "Format" "🧹" "Format" $C.Danger
Add-Btn "Xóa Part" "❌" "Delete" $C.Danger

# --- CORE ENGINE (HYBRID) ---

function Load-Disks {
    $GridDisk.Rows.Clear(); $GridPart.Rows.Clear()
    $Global:SelectedDisk = $null; $Global:SelectedPart = $null
    $LblInfo.Text = "ĐANG QUÉT HỆ THỐNG..."
    $Form.Cursor = "WaitCursor"; $Form.Refresh()

    $Global:UseWMI = $false
    
    # 1. Thu dung Modern Cmdlets
    try {
        $Disks = Get-Disk -ErrorAction Stop
        if (!$Disks -or $Disks.Count -eq 0) { throw "Empty" }
        
        foreach ($D in $Disks) {
            $GB = [Math]::Round($D.Size / 1GB, 1).ToString() + " GB"
            $Style = if ($D.PartitionStyle -eq "RAW") { "Unknown" } else { $D.PartitionStyle }
            $Stat = if ($D.OperationalStatus -eq "Online") { "Online" } else { "Offline" }
            $Idx = $GridDisk.Rows.Add($D.Number, $D.FriendlyName, $Style, $GB, $Stat)
            $GridDisk.Rows[$Idx].Tag = $D.Number # Luu ID
        }
    } catch {
        # 2. Fallback WMI (Neu loi hoac rong)
        $Global:UseWMI = $true
        $LblInfo.Text = "CHẾ ĐỘ WMI (LEGACY)"
        try {
            $Disks = Get-WmiObject Win32_DiskDrive
            foreach ($D in $Disks) {
                $GB = [Math]::Round($D.Size / 1GB, 1).ToString() + " GB"
                $Idx = $GridDisk.Rows.Add($D.Index, $D.Model, "Basic", $GB, $D.Status)
                $GridDisk.Rows[$Idx].Tag = $D.Index
            }
        } catch { $LblInfo.Text = "LỖI KHÔNG TÌM THẤY Ổ CỨNG!" }
    }

    if ($GridDisk.Rows.Count -gt 0) { $GridDisk.Rows[0].Selected = $true }
    $Form.Cursor = "Default"
}

function Load-Partitions ($DiskIndex) {
    $GridPart.Rows.Clear()
    $Global:SelectedDisk = $DiskIndex
    $LblInfo.Text = "ĐANG XEM DISK $DiskIndex"

    # --- MODE 1: WMI (Chay cai nay neu co lenh WMI duoc bat) ---
    if ($Global:UseWMI) {
        $Query = "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='\\.\PHYSICALDRIVE$DiskIndex'} WHERE AssocClass=Win32_DiskDriveToDiskPartition"
        try {
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
                    $Stat = "OK"
                } else {
                    $Let=""; $Lab="System/Hidden"; $FS="RAW"; $Used="-"; $Free="-"; $Stat="System"
                }
                
                $Idx = $GridPart.Rows.Add($Let, $Lab, $FS, "$Total GB", $Used, $Free, $Stat)
                $GridPart.Rows[$Idx].Tag = @{Did=$DiskIndex; Pid=$P.Index; Let=$Let} # Luu Index WMI
            }
        } catch {}
    } 
    # --- MODE 2: MODERN (Get-Partition) ---
    else {
        try {
            $Parts = Get-Partition -DiskNumber $DiskIndex | Sort-Object PartitionNumber
            foreach ($P in $Parts) {
                $Vol = $null; try { $Vol = $P | Get-Volume -ErrorAction SilentlyContinue } catch {}
                $Let = if ($P.DriveLetter) { "$($P.DriveLetter):" } else { "" }
                
                if ($Vol) {
                    $Lab = if ($Vol.FileSystemLabel) { $Vol.FileSystemLabel } else { "(NoName)" }
                    $FS = $Vol.FileSystem
                    $Total = [Math]::Round($Vol.Size / 1GB, 2)
                    $Free = [Math]::Round($Vol.SizeRemaining / 1GB, 2)
                    $Used = [Math]::Round($Total - $Free, 2)
                    $Stat = "Healthy"
                } else {
                    $Lab = $P.Type; $FS = "-"; $Total = [Math]::Round($P.Size / 1GB, 2)
                    $Used="-"; $Free="-"; $Stat="Hidden"
                }
                $Idx = $GridPart.Rows.Add($Let, $Lab, $FS, "$Total GB", $Used, $Free, $Stat)
                $GridPart.Rows[$Idx].Tag = @{Did=$DiskIndex; Pid=$P.PartitionNumber; Let=$Let}
            }
        } catch {}
    }
}

# --- EVENTS ---
$GridDisk.Add_SelectionChanged({
    if ($GridDisk.SelectedRows.Count -gt 0) {
        Load-Partitions $GridDisk.SelectedRows[0].Tag
    }
})

$GridPart.Add_SelectionChanged({
    if ($GridPart.SelectedRows.Count -gt 0) {
        $Global:SelectedPart = $GridPart.SelectedRows[0].Tag
        $Info = $Global:SelectedPart
        $Name = if($Info.Let){$Info.Let}else{"Partition #"+$Info.Pid}
        $LblInfo.Text = "ĐANG CHỌN: $Name (Disk $($Info.Did))"
        $LblInfo.ForeColor = $C.Accent
    }
})

# --- ACTIONS ---
function Run-DP ($Cmd) {
    $F = "$env:TEMP\dp.txt"; [IO.File]::WriteAllText($F, $Cmd)
    Start-Process "diskpart" "/s `"$F`"" -Wait -NoNewWindow
    Remove-Item $F; Load-Disks
}

function Run-Action ($Act) {
    if ($Act -eq "Refresh") { Load-Disks; return }
    
    $P = $Global:SelectedPart
    if (!$P) { [System.Windows.Forms.MessageBox]::Show("Chọn phân vùng bảng dưới trước!", "Lỗi"); return }
    $Did = $P.Did; $Pid = $P.Pid; $Let = $P.Let

    # Fix Index WMI vs Diskpart (WMI index = 0 base, Diskpart = 1 base, but sometimes varies)
    # Safe way: Select Disk -> Select Partition Index -> Detail
    # Logic: Nếu mode WMI -> PartID thường là Index. Nếu Mode Modern -> PartID là PartitionNumber.
    # Diskpart select partition <id> hoac <index>.
    # De an toan, ta dung Select Partition <ID> neu co, hoac Index + 1.
    
    # Simple fix cho WMI: Thuong thi Index WMI = Partition Number - 1.
    # Thu Select Partition $Pid (Modern) hoac $Pid + 1 (Legacy)
    $TargetID = if($Global:UseWMI){ $Pid + 1 } else { $Pid }

    switch ($Act) {
        "Format" { if([System.Windows.Forms.MessageBox]::Show("FORMAT $Let?","Canh bao","YesNo")-eq"Yes"){ Run-DP "sel disk $Did`nsel part $TargetID`nformat fs=ntfs quick" } }
        "Delete" { if([System.Windows.Forms.MessageBox]::Show("XOA PARTITION?","Canh bao","YesNo")-eq"Yes"){ Run-DP "sel disk $Did`nsel part $TargetID`ndelete partition override" } }
        "Active" { Run-DP "sel disk $Did`nsel part $TargetID`nactive" }
        "Letter" { $N=[Microsoft.VisualBasic.Interaction]::InputBox("Ky tu (VD: Z):","Assign",""); if($N){ Run-DP "sel disk $Did`nsel part $TargetID`nassign letter=$N" } }
        "Label"  { $N=[Microsoft.VisualBasic.Interaction]::InputBox("Ten moi:","Label",""); if($N){ cmd /c "label $Let $N"; Load-Disks } }
        "Convert"{ if([System.Windows.Forms.MessageBox]::Show("Convert Disk $Did? (Clean)","Hoi","YesNo")-eq"Yes"){ Run-DP "sel disk $Did`nclean`nconvert gpt" } }
        "ChkDsk" { if($Let){Start-Process "cmd" "/k chkdsk $Let /f /x"} }
    }
}

$Form.Add_Shown({ Load-Disks })
$Form.ShowDialog() | Out-Null
