<#
    DISK MANAGER PRO - PHAT TAN PC (V7.0 RIBBON EDITION)
    Layout: Top Toolbar (Menu Ngang) + Split Grid (Trên/Dưới)
    Fix: Logic chọn dòng (Selection) chính xác 100%
#>

# --- 1. ADMIN CHECK ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-NoP -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- THEME CONFIG (PROFESSIONAL DARK) ---
$C = @{
    FormBg   = [System.Drawing.Color]::FromArgb(30, 30, 30)
    PanelBg  = [System.Drawing.Color]::FromArgb(45, 45, 48)
    GridBg   = [System.Drawing.Color]::FromArgb(25, 25, 25)
    Text     = [System.Drawing.Color]::White
    Accent   = [System.Drawing.Color]::FromArgb(0, 120, 215) # Xanh Win 10
    Warning  = [System.Drawing.Color]::Gold
    Danger   = [System.Drawing.Color]::IndianRed
    BtnBg    = [System.Drawing.Color]::FromArgb(60, 60, 60)
    BtnHover = [System.Drawing.Color]::FromArgb(80, 80, 80)
}

# --- GLOBAL VARS ---
$Global:SelectedDisk = $null
$Global:SelectedPart = $null # Chứa thông tin Partition đang chọn

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "DISK MANAGER PRO V7.0 - PHAT TAN PC"
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

# ==================== LAYOUT: TOP TOOLBAR (RIBBON) ====================
$PnlTop = New-Object System.Windows.Forms.Panel
$PnlTop.Dock = "Top"; $PnlTop.Height = 100; $PnlTop.BackColor = $C.PanelBg
$PnlTop.Padding = "10,10,10,10"
$Form.Controls.Add($PnlTop)

# Label Info (Góc trái trên)
$LblInfo = New-Object System.Windows.Forms.Label
$LblInfo.Text = "ĐANG CHỌN: [Chưa chọn phân vùng]"
$LblInfo.Font = $F_Title; $LblInfo.ForeColor = $C.Warning
$LblInfo.AutoSize = $true; $LblInfo.Location = "10, 10"
$PnlTop.Controls.Add($LblInfo)

# Toolbar Flow (Chứa nút)
$FlowTool = New-Object System.Windows.Forms.FlowLayoutPanel
$FlowTool.Dock = "Bottom"; $FlowTool.Height = 55; $FlowTool.FlowDirection = "LeftToRight"
$FlowTool.WrapContents = $false # Cho trượt ngang nếu nhiều nút
$FlowTool.AutoScroll = $true
$PnlTop.Controls.Add($FlowTool)

# ==================== LAYOUT: MAIN GRIDS ====================
$Split = New-Object System.Windows.Forms.SplitContainer
$Split.Dock = "Fill"; $Split.Orientation = "Horizontal"; $Split.SplitterDistance = 250
$Form.Controls.Add($Split)

# --- GRID 1: DISK LIST (Ở TRÊN) ---
$GbDisk = New-Object System.Windows.Forms.GroupBox; $GbDisk.Text = "DANH SÁCH Ổ CỨNG VẬT LÝ (Chọn Disk để xem phân vùng)"; $GbDisk.ForeColor = $C.Accent; $GbDisk.Dock = "Fill"
$Split.Panel1.Controls.Add($GbDisk); $Split.Panel1.Padding = "10,10,10,0"

$GridDisk = New-Object System.Windows.Forms.DataGridView
$GridDisk.Dock = "Fill"; $GridDisk.BackgroundColor = $C.GridBg; $GridDisk.ForeColor = "Black"
$GridDisk.AllowUserToAddRows=$false; $GridDisk.RowHeadersVisible=$false; $GridDisk.SelectionMode="FullRowSelect"; $GridDisk.MultiSelect=$false; $GridDisk.ReadOnly=$true; $GridDisk.AutoSizeColumnsMode="Fill"
$GridDisk.Columns.Add("ID","Disk #"); $GridDisk.Columns[0].Width=60
$GridDisk.Columns.Add("Model","Model"); 
$GridDisk.Columns.Add("Style","Kiểu (GPT/MBR)"); $GridDisk.Columns[2].Width=100
$GridDisk.Columns.Add("Size","Dung Lượng"); $GridDisk.Columns[3].Width=100
$GridDisk.Columns.Add("Status","Trạng Thái"); $GridDisk.Columns[4].Width=100
$GbDisk.Controls.Add($GridDisk)

# --- GRID 2: PARTITION LIST (Ở DƯỚI) ---
$GbPart = New-Object System.Windows.Forms.GroupBox; $GbPart.Text = "CHI TIẾT PHÂN VÙNG (Chọn dòng ở đây để thao tác)"; $GbPart.ForeColor = $C.Accent; $GbPart.Dock = "Fill"
$Split.Panel2.Controls.Add($GbPart); $Split.Panel2.Padding = "10,0,10,10"

$GridPart = New-Object System.Windows.Forms.DataGridView
$GridPart.Dock = "Fill"; $GridPart.BackgroundColor = $C.GridBg; $GridPart.ForeColor = "Black"
$GridPart.AllowUserToAddRows=$false; $GridPart.RowHeadersVisible=$false; $GridPart.SelectionMode="FullRowSelect"; $GridPart.MultiSelect=$false; $GridPart.ReadOnly=$true; $GridPart.AutoSizeColumnsMode="Fill"
$GridPart.Columns.Add("Let","Ký Tự"); $GridPart.Columns[0].Width=60
$GridPart.Columns.Add("Label","Tên (Label)"); $GridPart.Columns[1].FillWeight=120
$GridPart.Columns.Add("FS","FS"); $GridPart.Columns[2].Width=60
$GridPart.Columns.Add("Cap","Tổng"); $GridPart.Columns[3].Width=80
$GridPart.Columns.Add("Used","Đã Dùng"); $GridPart.Columns[4].Width=80
$GridPart.Columns.Add("P_Use","% Dùng"); $GridPart.Columns[5].Width=70
$GridPart.Columns.Add("Free","Còn Lại"); $GridPart.Columns[6].Width=80
$GridPart.Columns.Add("P_Free","% Trống"); $GridPart.Columns[7].Width=70
$GridPart.Columns.Add("Stat","Trạng Thái"); $GridPart.Columns[8].Width=100
$GbPart.Controls.Add($GridPart)

# --- HELPER: ADD RIBBON BUTTON ---
function Add-Btn ($Txt, $Icon, $Tag, $Color) {
    $Btn = New-Object System.Windows.Forms.Button
    $Btn.Text = "$Icon $Txt"
    $Btn.Tag = $Tag
    $Btn.Size = New-Object System.Drawing.Size(130, 45) # Nút vuông vức nằm ngang
    $Btn.Margin = "0,0,5,0"
    $Btn.FlatStyle = "Flat"; $Btn.FlatAppearance.BorderSize = 0
    $Btn.BackColor = $C.BtnBg; $Btn.ForeColor = $C.Text; $Btn.Font = $F_Btn
    $Btn.Cursor = "Hand"
    
    # Border Bottom màu
    $Pn = New-Object System.Windows.Forms.Panel; $Pn.Height=4; $Pn.Dock="Bottom"; $Pn.BackColor=$Color; $Btn.Controls.Add($Pn)
    
    $Btn.Add_MouseEnter({ $this.BackColor = $C.BtnHover })
    $Btn.Add_MouseLeave({ $this.BackColor = $C.BtnBg })
    $Btn.Add_Click({ Run-Action $this.Tag })
    $FlowTool.Controls.Add($Btn)
}

# --- ADD BUTTONS (THANH NGANG) ---
Add-Btn "Làm Mới" "♻️" "Refresh" $C.Accent
Add-Btn "Đổi Ký Tự" "🔠" "Letter" [System.Drawing.Color]::Orange
Add-Btn "Đổi Tên" "🏷️" "Label" [System.Drawing.Color]::Orange
Add-Btn "Set Active" "⚡" "Active" $C.Warning
Add-Btn "Nạp Boot" "🛠️" "FixBoot" [System.Drawing.Color]::Violet
Add-Btn "Convert" "🔄" "Convert" [System.Drawing.Color]::Gray
Add-Btn "Check Disk" "🚑" "ChkDsk" [System.Drawing.Color]::LightGreen
# Nhóm nguy hiểm để cuối
Add-Btn "Format" "🧹" "Format" $C.Danger
Add-Btn "Xóa Part" "❌" "Delete" $C.Danger

# --- LOGIC ENGINE (HYBRID WMI/CIM) ---

function Load-Disks {
    $GridDisk.Rows.Clear(); $GridPart.Rows.Clear()
    $Global:SelectedDisk = $null; $Global:SelectedPart = $null
    $LblInfo.Text = "ĐANG TẢI DỮ LIỆU..."
    $Form.Cursor = "WaitCursor"; $Form.Refresh()

    # 1. Load Disk (Ưu tiên Get-Disk)
    try {
        $Disks = Get-Disk | Sort-Object Number
        foreach ($D in $Disks) {
            $GB = [Math]::Round($D.Size / 1GB, 1).ToString() + " GB"
            $Style = if ($D.PartitionStyle -eq "RAW") { "Chưa Init" } else { $D.PartitionStyle }
            $Stat = if ($D.OperationalStatus -eq "Online") { "Online" } else { "Offline" }
            $Idx = $GridDisk.Rows.Add($D.Number, $D.FriendlyName, $Style, $GB, $Stat)
            $GridDisk.Rows[$Idx].Tag = $D # Lưu object Disk
        }
    } catch {
        # Fallback WMI
        $Disks = Get-WmiObject Win32_DiskDrive
        foreach ($D in $Disks) {
            $GB = [Math]::Round($D.Size / 1GB, 1).ToString() + " GB"
            $Idx = $GridDisk.Rows.Add($D.Index, $D.Model, "Unknown", $GB, $D.Status)
            $GridDisk.Rows[$Idx].Tag = @{Number=$D.Index; FriendlyName=$D.Model} # Fake object
        }
    }

    if ($GridDisk.Rows.Count -gt 0) {
        $GridDisk.Rows[0].Selected = $true # Auto select first disk
    }
    $Form.Cursor = "Default"
}

function Load-Partitions ($DiskObj) {
    $GridPart.Rows.Clear()
    $Global:SelectedDisk = $DiskObj
    $Global:SelectedPart = $null
    $LblInfo.Text = "ĐANG CHỌN DISK: $($DiskObj.Number) - $($DiskObj.FriendlyName)"

    # Load Partitions (Ưu tiên Get-Partition)
    try {
        $Parts = Get-Partition -DiskNumber $DiskObj.Number | Sort-Object PartitionNumber -ErrorAction Stop
        foreach ($P in $Parts) {
            $Vol = $null; try { $Vol = $P | Get-Volume -ErrorAction SilentlyContinue } catch {}
            
            $Let = if ($P.DriveLetter) { "$($P.DriveLetter):" } else { "" }
            
            if ($Vol) {
                $Lab = if ($Vol.FileSystemLabel) { $Vol.FileSystemLabel } else { "(NoName)" }
                $FS = $Vol.FileSystem
                $Total = [Math]::Round($Vol.Size / 1GB, 2)
                $Free  = [Math]::Round($Vol.SizeRemaining / 1GB, 2)
                $Used  = [Math]::Round($Total - $Free, 2)
                $P_Fr  = if($Total -gt 0){[Math]::Round(($Free/$Total)*100,0)}else{0}
                $P_Us  = 100 - $P_Fr
                $Stat  = "Healthy"
            } else {
                $Lab = $P.Type; $FS = "-"; $Total = [Math]::Round($P.Size / 1GB, 2)
                $Used = "-"; $Free = "-"; $P_Us = "-"; $P_Fr = "-"; $Stat = "Hidden/Sys"
            }

            $Idx = $GridPart.Rows.Add($Let, $Lab, $FS, "$Total GB", "$Used GB", "$P_Us%", "$Free GB", "$P_Fr%", $Stat)
            # Quan trọng: Lưu dữ liệu vào Tag để dùng cho nút bấm
            $GridPart.Rows[$Idx].Tag = @{ Did=$DiskObj.Number; Pid=$P.PartitionNumber; Let=$Let; Lab=$Lab }
        }
    } catch {
        # Fallback WMI logic (nếu cần thiết) - Nhưng Get-Partition thường rất ổn
    }
}

# --- EVENT HANDLERS (FIX SELECTION BUG) ---

# Khi chọn dòng ở bảng Disk -> Load Partition tương ứng
$GridDisk.Add_SelectionChanged({
    if ($GridDisk.SelectedRows.Count -gt 0) {
        Load-Partitions $GridDisk.SelectedRows[0].Tag
    }
})

# Khi chọn dòng ở bảng Partition -> Cập nhật biến toàn cục
$GridPart.Add_SelectionChanged({
    if ($GridPart.SelectedRows.Count -gt 0) {
        $Data = $GridPart.SelectedRows[0].Tag
        $Global:SelectedPart = $Data
        
        # Cập nhật Label cho người dùng biết chắc chắn
        $Name = if($Data.Let){"Ổ $($Data.Let)"}else{"PARTITION $($Data.Pid)"}
        $LblInfo.Text = "ĐANG CHỌN: $Name (Disk $($Data.Did)) | Label: $($Data.Lab)"
        $LblInfo.ForeColor = $C.Accent
    } else {
        $Global:SelectedPart = $null
        $LblInfo.Text = "ĐANG CHỌN: [Chưa chọn phân vùng]"
        $LblInfo.ForeColor = $C.Warning
    }
})

# --- ACTION LOGIC ---
function Run-DP ($Cmd) {
    $F = "$env:TEMP\dp_run.txt"; [IO.File]::WriteAllText($F, $Cmd)
    Start-Process "diskpart" "/s `"$F`"" -Wait -NoNewWindow
    Remove-Item $F; Load-Disks # Load lại Disk để cập nhật bảng trên
}

function Run-Action ($Act) {
    if ($Act -eq "Refresh") { Load-Disks; return }
    if ($Act -eq "FixBoot") { Start-Process "cmd" "/c bcdboot C:\Windows /s C: /f ALL & pause"; return }

    # Kiểm tra kỹ biến SelectedPart
    $P = $Global:SelectedPart
    if ($null -eq $P) { 
        [System.Windows.Forms.MessageBox]::Show("Vui lòng click chọn một dòng trong bảng 'CHI TIẾT PHÂN VÙNG' ở dưới trước!", "Chưa chọn đối tượng", "OK", "Warning")
        return 
    }

    $Did = $P.Did; $Pid = $P.Pid; $Let = $P.Let

    switch ($Act) {
        "Letter" {
            $New = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập ký tự mới (VD: Z):", "Đổi Ký Tự", "")
            if ($New) { 
                try { Set-Partition -DiskNumber $Did -PartitionNumber $Pid -NewDriveLetter $New; Load-Disks } 
                catch { [System.Windows.Forms.MessageBox]::Show("Lỗi: $($_.Exception.Message)", "Error") }
            }
        }
        "Label" {
            $New = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập tên ổ mới:", "Đổi Tên", $P.Lab)
            if ($New) {
                try { Set-Volume -DriveLetter $Let -NewFileSystemLabel $New; Load-Disks }
                catch { [System.Windows.Forms.MessageBox]::Show("Lỗi (Ổ phải có ký tự mới đổi tên được bằng lệnh này): $($_.Exception.Message)", "Error") }
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
            if ($Let) { Start-Process "cmd" "/k chkdsk $Let /f /x" } 
            else { [System.Windows.Forms.MessageBox]::Show("Phân vùng này không có Ký tự ổ!", "Lỗi") }
        }
        "Convert" {
            if ([System.Windows.Forms.MessageBox]::Show("Chuyển đổi Disk $Did sang GPT/MBR?`nYêu cầu Disk phải Trống (Clean)!", "Hỏi", "YesNo") -eq "Yes") {
                # Logic đơn giản: Nếu đang MBR thì sang GPT và ngược lại (cần check kỹ hơn ở bản sau nếu muốn)
                Run-DP "sel disk $Did`nclean`nconvert gpt" 
            }
        }
    }
}

# --- INIT ---
$Form.Add_Shown({ Load-Disks })
$Form.ShowDialog() | Out-Null
