# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic
$ErrorActionPreference = "SilentlyContinue"

# --- THEME ENGINE (PHAT TAN STYLE) ---
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
$Form.Text = "DISK MANAGER PRO - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(1100, 700)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back
$Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "QUẢN LÝ Ổ CỨNG CHUYÊN SÂU"; $LblT.Font = "Impact, 22"; $LblT.ForeColor = $Theme.Cyan; $LblT.AutoSize = $true; $LblT.Location = "20,15"; $Form.Controls.Add($LblT)

$LblSub = New-Object System.Windows.Forms.Label; $LblSub.Text = "Phân vùng - Cứu hộ - Chuyển đổi định dạng"; $LblSub.ForeColor = "Gray"; $LblSub.AutoSize = $true; $LblSub.Location = "25,55"; $Form.Controls.Add($LblSub)

# --- GLOBAL VARIABLES ---
$Global:SelectedDiskID = $null
$Global:SelectedPartID = $null
$Global:SelectedLetter = $null

# --- GRIDVIEW (DANH SÁCH) ---
$Grid = New-Object System.Windows.Forms.DataGridView
$Grid.Location = "20, 90"; $Grid.Size = "800, 400"
$Grid.BackgroundColor = $Theme.Panel
$Grid.ForeColor = "Black"
$Grid.AllowUserToAddRows = $false
$Grid.RowHeadersVisible = $false
$Grid.SelectionMode = "FullRowSelect"
$Grid.MultiSelect = $false
$Grid.AutoSizeColumnsMode = "Fill"
$Grid.ReadOnly = $true

# Cột hiển thị
$Grid.Columns.Add("Disk", "Disk #"); $Grid.Columns["Disk"].FillWeight = 10
$Grid.Columns.Add("Letter", "Ký Tự"); $Grid.Columns["Letter"].FillWeight = 10
$Grid.Columns.Add("Label", "Tên Ổ (Label)"); $Grid.Columns["Label"].FillWeight = 20
$Grid.Columns.Add("FS", "Định Dạng"); $Grid.Columns["FS"].FillWeight = 15
$Grid.Columns.Add("Total", "Tổng DL"); $Grid.Columns["Total"].FillWeight = 15
$Grid.Columns.Add("Used", "Đã Dùng"); $Grid.Columns["Used"].FillWeight = 15
$Grid.Columns.Add("Free", "Còn Trống"); $Grid.Columns["Free"].FillWeight = 15
$Grid.Columns.Add("Percent", "% Used"); $Grid.Columns["Percent"].FillWeight = 15
$Grid.Columns.Add("Health", "Sức Khỏe"); $Grid.Columns["Health"].FillWeight = 15

$Form.Controls.Add($Grid)

# --- PANEL CHỨC NĂNG (BÊN PHẢI) ---
$PnlTool = New-Object System.Windows.Forms.FlowLayoutPanel
$PnlTool.Location = "840, 90"; $PnlTool.Size = "230, 550"; $PnlTool.FlowDirection = "TopDown"
$Form.Controls.Add($PnlTool)

function Add-Group ($Title, $Color) {
    $L = New-Object System.Windows.Forms.Label; $L.Text = $Title; $L.ForeColor = $Color; $L.Font = "Segoe UI, 10, Bold"; $L.AutoSize = $true; $L.Margin = "0,10,0,5"
    $PnlTool.Controls.Add($L)
}

function Add-Btn ($Txt, $Tag, $Color) {
    $B = New-Object System.Windows.Forms.Button; $B.Text = $Txt; $B.Tag = $Tag; $B.Size = "220, 35"; $B.FlatStyle = "Flat"
    $B.BackColor = $Theme.Btn; $B.ForeColor = "White"; $B.Cursor = "Hand"
    $B.FlatAppearance.BorderColor = $Color; $B.FlatAppearance.BorderSize = 1
    $B.Margin = "0,2,0,2"
    $B.Add_Click({ Run-Action $this.Tag })
    $PnlTool.Controls.Add($B)
}

# Add Buttons
Add-Group "QUẢN LÝ PHÂN VÙNG" $Theme.Cyan
Add-Btn "♻️ Làm Mới (Refresh)" "Refresh" $Theme.Cyan
Add-Btn "➕ Tạo Ổ Mới (New Volume)" "Create" $Theme.Cyan
Add-Btn "✂️ Chia Ổ (Split/Shrink)" "Split" $Theme.Cyan
Add-Btn "🔗 Gộp Ổ (Merge)" "Merge" $Theme.Cyan
Add-Btn "🏷️ Đổi Tên / Ký Tự" "Label" $Theme.Cyan
Add-Btn "🧹 Format Phân Vùng" "Format" $Theme.Cyan
Add-Btn "❌ Xóa Phân Vùng" "Delete" $Theme.Red

Add-Group "CỨU HỘ & SỬA CHỮA" $Theme.Orange
Add-Btn "🚑 Cứu Ổ RAW (CHKDSK)" "FixRAW" $Theme.Orange
Add-Btn "🛠️ Rebuild MBR/Boot" "FixBoot" $Theme.Orange
Add-Btn "🚀 Tối Ưu (Trim/Defrag)" "Optimize" $Theme.Orange
Add-Btn "🔍 Check Health (SMART)" "Smart" $Theme.Orange

Add-Group "ĐĨA CỨNG (DISK OPS)" $Theme.Lime
Add-Btn "🔄 Convert MBR <-> GPT" "ConvertStyle" $Theme.Lime
Add-Btn "💣 Wipe Disk (Xóa Sạch)" "WipeDisk" $Theme.Lime
# Add-Btn "⚙️ Dynamic <-> Basic" "ConvertDynamic" $Theme.Lime # Nguy hiểm, tạm ẩn

# Info Box dưới cùng
$TxtLog = New-Object System.Windows.Forms.TextBox
$TxtLog.Location = "20, 500"; $TxtLog.Size = "800, 140"; $TxtLog.Multiline = $true; $TxtLog.ReadOnly = $true
$TxtLog.BackColor = "Black"; $TxtLog.ForeColor = "Lime"; $TxtLog.Font = "Consolas, 9"
$Form.Controls.Add($TxtLog)

function Log ($M) { $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $M`r`n"); $TxtLog.ScrollToCaret() }

# --- LOGIC FUNCTION ---

function Load-Data {
    $Grid.Rows.Clear()
    $Disks = Get-Disk | Sort-Object Number
    
    foreach ($D in $Disks) {
        # Hiển thị Unallocated Space nếu cần (Logic phức tạp, ở đây hiển thị Partitions chính)
        $Parts = Get-Partition -DiskNumber $D.Number | Sort-Object PartitionNumber
        
        foreach ($P in $Parts) {
            $Vol = $P | Get-Volume -ErrorAction SilentlyContinue
            
            $Let = if ($P.DriveLetter) { "$($P.DriveLetter):" } else { "" }
            
            if ($Vol) {
                $Lab = $Vol.FileSystemLabel
                $FS = $Vol.FileSystem
                $Tot = [Math]::Round($Vol.Size / 1GB, 2)
                $Fre = [Math]::Round($Vol.SizeRemaining / 1GB, 2)
                $Usd = [Math]::Round($Tot - $Fre, 2)
                
                $Per = if($Tot -gt 0) { [Math]::Round(($Usd / $Tot) * 100, 1) } else { 0 }
                $PerStr = "$Per%"
                $Health = $D.HealthStatus
            } else {
                # Partition hệ thống hoặc Recovery
                $Lab = $P.Type
                $FS = "RAW/System"
                $Tot = [Math]::Round($P.Size / 1GB, 2)
                $Fre = "-"; $Usd = "-"; $PerStr = "-"; $Health = $D.HealthStatus
            }
            
            $Idx = $Grid.Rows.Add($D.Number, $Let, $Lab, $FS, "$Tot GB", "$Usd GB", "$Fre GB", $PerStr, $Health)
            $Grid.Rows[$Idx].Tag = @{ Disk=$D; Part=$P; Vol=$Vol }
            
            # Tô màu Unallocated hoặc Full
            if ($Per -ge 90) { $Grid.Rows[$Idx].DefaultCellStyle.ForeColor = "Red" }
        }
    }
    Log "Đã tải danh sách phân vùng."
}

# Lấy Item đang chọn
function Get-Sel {
    if ($Grid.SelectedRows.Count -eq 0) { return $null }
    return $Grid.SelectedRows[0].Tag
}

function Run-Action ($Act) {
    $Item = Get-Sel
    
    # Các lệnh không cần chọn phân vùng cụ thể (Refresh)
    if ($Act -eq "Refresh") { Load-Data; return }
    
    if (!$Item) { [System.Windows.Forms.MessageBox]::Show("Vui lòng chọn 1 phân vùng trên danh sách!", "Lỗi"); return }
    $D = $Item.Disk; $P = $Item.Part; $V = $Item.Vol
    
    switch ($Act) {
        "Create" {
            # Logic tạo phân vùng từ Unallocated (Cần tìm khoảng trống lớn nhất)
            # Ở đây dùng logic đơn giản: Tạo trên ổ đĩa hiện tại nếu còn chỗ
            $MaxSize = Get-PartitionSupportedSize -DiskNumber $D.Number -PartitionNumber $P.PartitionNumber
            Log "Chức năng này hỗ trợ tạo trên vùng Unallocated. Hãy dùng Disk Management nếu phức tạp."
            Start-Process "diskmgmt.msc"
        }
        
        "Split" {
            if (!$V) { Log "Không thể chia phân vùng hệ thống."; return }
            $Input = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập dung lượng muốn TÁCH RA (GB) từ ổ $($P.DriveLetter):", "Chia Ổ", "10")
            if ($Input -as [double]) {
                try {
                    $Size = [double]$Input * 1GB
                    Log "Đang thu nhỏ (Shrink) ổ cũ..."
                    Resize-Partition -DiskNumber $D.Number -PartitionNumber $P.PartitionNumber -Size ($P.Size - $Size) -ErrorAction Stop
                    Log "Đang tạo phân vùng mới..."
                    $NewP = New-Partition -DiskNumber $D.Number -UseMaximumSize -AssignDriveLetter
                    Format-Volume -Partition $NewP -FileSystem NTFS -NewFileSystemLabel "NewVolume" -Confirm:$false
                    Log "Thành công! Đã tạo ổ mới."
                    Load-Data
                } catch { Log "Lỗi: $($_.Exception.Message)" }
            }
        }
        
        "Merge" {
             [System.Windows.Forms.MessageBox]::Show("Gộp ổ yêu cầu XÓA phân vùng liền kề. Hãy dùng Disk Genius (có trong Tool) để an toàn dữ liệu hơn.", "Khuyên dùng")
             # Logic PS: Remove-Partition Next -> Resize-Partition Current
        }
        
        "Label" {
            if (!$V) { return }
            $NewName = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập tên mới:", "Rename", $V.FileSystemLabel)
            if ($NewName) { Set-Volume -DriveLetter $P.DriveLetter -NewFileSystemLabel $NewName; Log "Đã đổi tên."; Load-Data }
        }
        
        "Format" {
            if ([System.Windows.Forms.MessageBox]::Show("BẠN CÓ CHẮC MUỐN FORMAT Ổ $($P.DriveLetter)?`nDữ liệu sẽ mất hết!", "CẢNH BÁO", "YesNo", "Warning") -eq "Yes") {
                Log "Đang Format..."
                Format-Volume -DriveLetter $P.DriveLetter -FileSystem NTFS -Confirm:$false
                Log "Format xong."; Load-Data
            }
        }
        
        "Delete" {
            if ([System.Windows.Forms.MessageBox]::Show("XÓA PHÂN VÙNG $($P.DriveLetter)?`nDữ liệu sẽ mất!", "CẢNH BÁO", "YesNo", "Error") -eq "Yes") {
                Remove-Partition -DiskNumber $D.Number -PartitionNumber $P.PartitionNumber -Confirm:$false
                Log "Đã xóa phân vùng."; Load-Data
            }
        }
        
        "FixRAW" {
            if (!$P.DriveLetter) { Log "Ổ này không có ký tự để sửa."; return }
            Log "Đang chạy CHKDSK sửa lỗi RAW/File System..."
            Start-Process "cmd.exe" -ArgumentList "/c chkdsk $($P.DriveLetter): /f /x & pause" -Wait
            Log "Hoàn tất."
        }
        
        "FixBoot" {
            if ([System.Windows.Forms.MessageBox]::Show("Chức năng này sẽ nạp lại Boot cho ổ C.`nChỉ chạy khi máy không Boot được.", "Xác nhận", "YesNo") -eq "Yes") {
                Log "Đang nạp Boot (bcdboot)..."
                Start-Process "cmd.exe" -ArgumentList "/c bcdboot C:\Windows /s C: /f ALL & pause" -Wait
                Log "Đã nạp xong."
            }
        }
        
        "Optimize" {
            if (!$P.DriveLetter) { return }
            Log "Đang tối ưu (Trim/Defrag) ổ $($P.DriveLetter)..."
            Optimize-Volume -DriveLetter $P.DriveLetter -Verbose
            Log "Tối ưu xong."
        }
        
        "Smart" {
             $Storage = Get-PhysicalDisk | Where {$_.DeviceId -eq $D.Number}
             $Msg = "Model: $($Storage.FriendlyName)`nBus: $($Storage.BusType)`nMedia: $($Storage.MediaType)`nHealth: $($Storage.HealthStatus)`nOperational: $($Storage.OperationalStatus)"
             [System.Windows.Forms.MessageBox]::Show($Msg, "S.M.A.R.T Info")
        }
        
        "ConvertStyle" {
            $Style = $D.PartitionStyle
            if ($Style -eq "MBR") {
                if ([System.Windows.Forms.MessageBox]::Show("Chuyển Disk $($D.Number) sang GPT?`nLưu ý: Nếu là ổ chứa Win, cần Main hỗ trợ UEFI.`nDữ liệu có thể bị ảnh hưởng nếu không dùng Tool chuyên dụng.", "Convert GPT", "YesNo") -eq "Yes") {
                    # Dùng MBR2GPT nếu là ổ System, hoặc Set-Disk nếu là ổ Data
                    Log "Đang thử chuyển đổi..."
                    # Đây là demo, thực tế cần check kỹ
                    Log "Vui lòng dùng MiniTool Partition Wizard (có trong bộ cứu hộ) để chuyển đổi không mất dữ liệu."
                }
            } else {
                Log "Disk đang là GPT."
            }
        }
        
        "WipeDisk" {
             if ([System.Windows.Forms.MessageBox]::Show("HỦY DIỆT TOÀN BỘ DISK $($D.Number)?`nTất cả phân vùng sẽ bay màu!", "CỰC KỲ NGUY HIỂM", "YesNo", "Error") -eq "Yes") {
                if ([System.Windows.Forms.MessageBox]::Show("XÁC NHẬN LẦN 2: XÓA SẠCH?", "CHẮC CHẮN", "YesNo", "Error") -eq "Yes") {
                    Clear-Disk -Number $D.Number -RemoveData -Confirm:$false
                    Initialize-Disk -Number $D.Number
                    Log "Đã Wipe ổ cứng và khởi tạo lại."
                    Load-Data
                }
             }
        }
    }
}

# --- INIT ---
$Form.Add_Shown({ Load-Data })
$Form.ShowDialog() | Out-Null
}
