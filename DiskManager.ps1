# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic
$ErrorActionPreference = "SilentlyContinue"

# --- THEME ENGINE ---
$Theme = @{
    Back      = [System.Drawing.Color]::FromArgb(25, 25, 30)
    Panel     = [System.Drawing.Color]::FromArgb(35, 35, 40)
    Text      = [System.Drawing.Color]::FromArgb(240, 240, 240)
    Cyan      = [System.Drawing.Color]::FromArgb(0, 255, 255)
    Lime      = [System.Drawing.Color]::FromArgb(0, 255, 128)
    Orange    = [System.Drawing.Color]::FromArgb(255, 165, 0)
    Red       = [System.Drawing.Color]::FromArgb(255, 50, 50)
    Btn       = [System.Drawing.Color]::FromArgb(50, 50, 60)
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "DISK MANAGER ULTIMATE - PHAT TAN PC (DUAL ENGINE)"
$Form.Size = New-Object System.Drawing.Size(1200, 750) # Tăng chiều rộng
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back
$Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "QUẢN LÝ Ổ CỨNG ĐA NĂNG"; $LblT.Font = "Impact, 22"; $LblT.ForeColor = $Theme.Cyan; $LblT.AutoSize = $true; $LblT.Location = "20,15"; $Form.Controls.Add($LblT)

$LblSub = New-Object System.Windows.Forms.Label; $LblSub.Text = "Hỗ trợ: Windows 7/8/10/11 | Engine: PowerShell Direct & WMI/DiskPart"; $LblSub.ForeColor = "Gray"; $LblSub.AutoSize = $true; $LblSub.Location = "25,55"; $Form.Controls.Add($LblSub)

# --- GRIDVIEW ---
$Grid = New-Object System.Windows.Forms.DataGridView
$Grid.Location = "20, 90"; $Grid.Size = "850, 450" # Grid rộng hơn
$Grid.BackgroundColor = $Theme.Panel
$Grid.ForeColor = "Black"
$Grid.AllowUserToAddRows = $false
$Grid.RowHeadersVisible = $false
$Grid.SelectionMode = "FullRowSelect"
$Grid.MultiSelect = $false
$Grid.AutoSizeColumnsMode = "Fill"
$Grid.ReadOnly = $true

# Cột hiển thị
$Grid.Columns.Add("Disk", "Disk"); $Grid.Columns["Disk"].FillWeight = 8
$Grid.Columns.Add("Idx", "Part #"); $Grid.Columns["Idx"].FillWeight = 8
$Grid.Columns.Add("Letter", "Ký Tự"); $Grid.Columns["Letter"].FillWeight = 10
$Grid.Columns.Add("Label", "Tên Ổ"); $Grid.Columns["Label"].FillWeight = 20
$Grid.Columns.Add("FS", "FS"); $Grid.Columns["FS"].FillWeight = 10
$Grid.Columns.Add("Size", "Dung Lượng"); $Grid.Columns["Size"].FillWeight = 15
$Grid.Columns.Add("Free", "Trống"); $Grid.Columns["Free"].FillWeight = 15
$Grid.Columns.Add("Status", "Trạng Thái"); $Grid.Columns["Status"].FillWeight = 15

$Form.Controls.Add($Grid)

# --- PANEL PHẢI (CHỨC NĂNG) ---
$PnlTool = New-Object System.Windows.Forms.FlowLayoutPanel
$PnlTool.Location = "890, 90"; $PnlTool.Size = "270, 550" # Panel rộng hơn, lùi sang phải
$PnlTool.FlowDirection = "TopDown"
$PnlTool.AutoScroll = $true # Thêm thanh cuộn nếu tràn
$Form.Controls.Add($PnlTool)

function Add-Group ($Title, $Color) {
    $L = New-Object System.Windows.Forms.Label; $L.Text = $Title; $L.ForeColor = $Color; $L.Font = "Segoe UI, 10, Bold"; $L.AutoSize = $true; $L.Margin = "0,15,0,5"
    $PnlTool.Controls.Add($L)
}

function Add-Btn ($Txt, $Tag, $Color) {
    $B = New-Object System.Windows.Forms.Button; $B.Text = $Txt; $B.Tag = $Tag; $B.Size = "240, 35"; $B.FlatStyle = "Flat"
    $B.BackColor = $Theme.Btn; $B.ForeColor = "White"; $B.Cursor = "Hand"
    $B.FlatAppearance.BorderColor = $Color; $B.FlatAppearance.BorderSize = 1
    $B.Margin = "0,3,0,3"
    $B.TextAlign = "MiddleLeft"; $B.Padding = "10,0,0,0" # Căn lề cho đẹp
    $B.Add_Click({ Run-Action $this.Tag })
    $PnlTool.Controls.Add($B)
}

Add-Group "QUẢN LÝ CƠ BẢN" $Theme.Cyan
Add-Btn "♻️ Làm Mới (Refresh)" "Refresh" $Theme.Cyan
Add-Btn "➕ Tạo Ổ Mới (Từ Unallocated)" "Create" $Theme.Cyan
Add-Btn "🏷️ Đổi Ký Tự / Tên Ổ" "Label" $Theme.Cyan
Add-Btn "🧹 Format (Định Dạng)" "Format" $Theme.Cyan
Add-Btn "❌ Xóa Phân Vùng (Delete)" "Delete" $Theme.Red

Add-Group "PHÂN VÙNG NÂNG CAO" $Theme.Lime
Add-Btn "✂️ Chia Tách Ổ (Split)" "Split" $Theme.Lime
Add-Btn "🔗 Gộp Ổ (Merge)" "Merge" $Theme.Lime
Add-Btn "🔄 Convert MBR <-> GPT" "ConvStyle" $Theme.Lime
Add-Btn "⚙️ Dynamic <-> Basic" "ConvDynamic" $Theme.Lime

Add-Group "CỨU HỘ & KHÁC" $Theme.Orange
Add-Btn "🚑 Fix Lỗi Ổ (CHKDSK)" "FixRaw" $Theme.Orange
Add-Btn "🛠️ Nạp Boot (Fix MBR/BCD)" "FixBoot" $Theme.Orange
Add-Btn "🚀 Tối Ưu (Defrag/Trim)" "Optimize" $Theme.Orange
Add-Btn "💣 Wipe Disk (Hủy Diệt)" "Wipe" $Theme.Red

# Log Area
$TxtLog = New-Object System.Windows.Forms.TextBox
$TxtLog.Location = "20, 560"; $TxtLog.Size = "850, 130"; $TxtLog.Multiline = $true; $TxtLog.ReadOnly = $true
$TxtLog.BackColor = "Black"; $TxtLog.ForeColor = "Lime"; $TxtLog.Font = "Consolas, 9"; $TxtLog.ScrollBars = "Vertical"
$Form.Controls.Add($TxtLog)

function Log ($M) { $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $M`r`n"); $TxtLog.ScrollToCaret() }

# --- CORE ENGINE (DUAL MODE) ---

function Load-Data {
    $Grid.Rows.Clear()
    Log "Đang quét ổ cứng..."
    
    # --- MODE 1: MODERN (GET-DISK / GET-VOLUME) ---
    if (Get-Command Get-Disk -ErrorAction SilentlyContinue) {
        try {
            Log " >> Mode: Modern API (Windows 10/11)"
            $Disks = Get-Disk | Sort-Object Number
            foreach ($D in $Disks) {
                $Parts = Get-Partition -DiskNumber $D.Number | Sort-Object PartitionNumber
                foreach ($P in $Parts) {
                    $Vol = $P | Get-Volume -ErrorAction SilentlyContinue
                    
                    $Let = if ($P.DriveLetter) { "$($P.DriveLetter):" } else { "" }
                    $Lab = if ($Vol) { $Vol.FileSystemLabel } else { $P.Type }
                    $FS  = if ($Vol) { $Vol.FileSystem } else { "RAW" }
                    $Size = [Math]::Round($P.Size / 1GB, 2)
                    $Free = if ($Vol) { [Math]::Round($Vol.SizeRemaining / 1GB, 2) } else { "-" }
                    
                    $Row = $Grid.Rows.Add($D.Number, $P.PartitionNumber, $Let, $Lab, $FS, "$Size GB", "$Free GB", "OK")
                    $Grid.Rows[$Row].Tag = @{ Mode="Modern"; Disk=$D.Number; Part=$P.PartitionNumber; Letter=$Let }
                }
                # Check Unallocated (Demo Logic)
                $Allocated = ($Parts | Measure-Object -Property Size -Sum).Sum
                $Unalloc = $D.Size - $Allocated
                if ($Unalloc -gt 1GB) {
                    $USize = [Math]::Round($Unalloc / 1GB, 2)
                    $R = $Grid.Rows.Add($D.Number, "*", "", "[UNALLOCATED]", "-", "$USize GB", "$USize GB", "Trong")
                    $Grid.Rows[$R].DefaultCellStyle.ForeColor = "Gray"
                    $Grid.Rows[$R].Tag = @{ Mode="Unallocated"; Disk=$D.Number }
                }
            }
            return
        } catch { Log "Modern API lỗi. Chuyển sang Legacy..." }
    }

    # --- MODE 2: LEGACY (WMI / DISKPART) ---
    Log " >> Mode: Legacy WMI (Windows 7/Old)"
    try {
        $Parts = Get-WmiObject Win32_DiskPartition
        foreach ($P in $Parts) {
            $LogDisk = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($P.DeviceID)'} WHERE AssocClass=Win32_LogicalDiskToPartition"
            
            $Let = if ($LogDisk) { $LogDisk.DeviceID } else { "" }
            $Lab = if ($LogDisk) { $LogDisk.VolumeName } else { "Partition" }
            $FS  = if ($LogDisk) { $LogDisk.FileSystem } else { "RAW" }
            $Size = [Math]::Round($P.Size / 1GB, 2)
            $Free = if ($LogDisk) { [Math]::Round($LogDisk.FreeSpace / 1GB, 2) } else { "-" }

            $Row = $Grid.Rows.Add($P.DiskIndex, $P.Index, $Let, $Lab, $FS, "$Size GB", "$Free GB", "OK")
            # Lưu Tag đơn giản để DiskPart dùng
            $Grid.Rows[$Row].Tag = @{ Mode="Legacy"; Disk=$P.DiskIndex; Part=$P.Index; Letter=$Let }
        }
    } catch { Log "Lỗi WMI: $($_.Exception.Message)" }
}

# --- DISKPART HELPER (VŨ KHÍ TỐI THƯỢNG) ---
function Run-DiskPart ($ScriptText) {
    $ScriptFile = "$env:TEMP\dp_script.txt"
    [IO.File]::WriteAllText($ScriptFile, $ScriptText)
    Log "Đang chạy lệnh DiskPart..."
    Start-Process "diskpart.exe" "/s `"$ScriptFile`"" -NoNewWindow -Wait
    Remove-Item $ScriptFile -ErrorAction SilentlyContinue
    Load-Data
}

function Run-Action ($Act) {
    if ($Act -eq "Refresh") { Load-Data; return }
    if ($Grid.SelectedRows.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn dòng nào!", "Lỗi"); return }
    
    $Tag = $Grid.SelectedRows[0].Tag
    $D = $Tag.Disk; $P = $Tag.Part; $L = $Tag.Letter
    $IsUnalloc = ($Tag.Mode -eq "Unallocated")

    switch ($Act) {
        "Create" {
            if (!$IsUnalloc) { [System.Windows.Forms.MessageBox]::Show("Hãy chọn dòng [UNALLOCATED] để tạo mới.", "Lưu ý"); return }
            # Tạo ổ từ vùng trống
            $SizeMB = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập dung lượng (MB). Để trống = Max:", "Create New", "")
            $SizeCmd = if($SizeMB){"size=$SizeMB"}else{""}
            $Script = "select disk $D`ncreate partition primary $SizeCmd`nformat fs=ntfs quick`nassign`n"
            Run-DiskPart $Script
        }

        "Label" {
            if ($IsUnalloc) { return }
            if ($L) {
                $NewL = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập tên mới (Label):", "Rename", "NewData")
                if ($NewL) { 
                    $Cmd = "label $L $NewL"; Start-Process "cmd" "/c $Cmd" -WindowStyle Hidden -Wait; Load-Data 
                }
            } else { Log "Phân vùng này không có ký tự ổ đĩa." }
        }

        "Format" {
            if ($IsUnalloc) { return }
            if ([System.Windows.Forms.MessageBox]::Show("FORMAT Ổ $L ? MẤT HẾT DỮ LIỆU!", "CẢNH BÁO", "YesNo", "Warning") -eq "Yes") {
                $Script = "select disk $D`nselect partition $P`nformat fs=ntfs quick`n"
                Run-DiskPart $Script
            }
        }

        "Delete" {
            if ($IsUnalloc) { return }
            if ([System.Windows.Forms.MessageBox]::Show("XÓA PHÂN VÙNG NÀY? ($L)", "CẢNH BÁO", "YesNo", "Error") -eq "Yes") {
                $Script = "select disk $D`nselect partition $P`ndelete partition override`n"
                Run-DiskPart $Script
            }
        }

        "Split" {
            if ($IsUnalloc -or !$L) { return }
            $Mb = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập số MB muốn TÁCH RA (Shrink):", "Chia ổ", "10240")
            if ($Mb) {
                # Shrink -> Create New
                $Script = "select disk $D`nselect partition $P`nshrink desired=$Mb`ncreate partition primary`nformat fs=ntfs quick`nassign`n"
                Run-DiskPart $Script
                Log "Đã tách ổ thành công."
            }
        }

        "Merge" {
            [System.Windows.Forms.MessageBox]::Show("Để gộp, bạn cần xóa phân vùng bên cạnh trước.`nTool sẽ tự động Extend (mở rộng) ổ hiện tại vào vùng trống ngay sau nó.", "Hướng dẫn")
            if ([System.Windows.Forms.MessageBox]::Show("Bạn có muốn MỞ RỘNG (Extend) ổ $L vào vùng trống phía sau không?", "Gộp ổ", "YesNo") -eq "Yes") {
                $Script = "select disk $D`nselect partition $P`nextend`n"
                Run-DiskPart $Script
            }
        }

        "FixRaw" {
            if (!$L) { return }
            Log "Đang chạy CHKDSK..."
            Start-Process "cmd" "/c start cmd /k chkdsk $L /f /x" 
        }

        "FixBoot" {
            if ([System.Windows.Forms.MessageBox]::Show("Nạp lại Bootloader cho ổ C?", "Fix Boot", "YesNo") -eq "Yes") {
                Start-Process "cmd" "/c bcdboot C:\Windows /s C: /f ALL & pause"
            }
        }
        
        "ConvStyle" {
             if ([System.Windows.Forms.MessageBox]::Show("Chuyển đổi MBR <-> GPT?`n(Lệnh: convert gpt/mbr trong DiskPart).`nCHÚ Ý: DỮ LIỆU CÓ THỂ MẤT NẾU KHÔNG DÙNG TOOL CHUYÊN!", "Cảnh báo", "YesNo", "Warning") -eq "Yes") {
                $Script = "select disk $D`nconvert gpt`n" # Mặc định thử GPT
                Run-DiskPart $Script
             }
        }

        "Wipe" {
             if ([System.Windows.Forms.MessageBox]::Show("XÓA TRẮNG TOÀN BỘ DISK $D?`nKHÔNG THỂ KHÔI PHỤC!", "NGUY HIỂM", "YesNo", "Error") -eq "Yes") {
                if ([System.Windows.Forms.MessageBox]::Show("XÁC NHẬN CUỐI CÙNG: WIPE DISK $D?", "CHẮC CHẮN", "YesNo", "Error") -eq "Yes") {
                    $Script = "select disk $D`nclean`nconvert mbr`n"
                    Run-DiskPart $Script
                }
             }
        }
    }
}

$Form.Add_Shown({ Load-Data })
$Form.ShowDialog() | Out-Null
