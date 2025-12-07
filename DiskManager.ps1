<#
    DISK MANAGER PRO - PHAT TAN PC (REMASTERED UI)
    Version: 5.0 (True Neon Cyberpunk - Modern Flat UI)
#>

# --- 1. ADMIN CHECK ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    if ($PSCommandPath) { Start-Process powershell "-NoP -File `"$PSCommandPath`"" -Verb RunAs; Exit }
    else { Write-Host "Vui long chay duoi quyen Admin!" -F Red; Exit }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic
$ErrorActionPreference = "SilentlyContinue"

# --- THEME CONFIGURATION (CYBERPUNK PALETTE) ---
$Colors = @{
    BgForm      = [System.Drawing.Color]::FromArgb(18, 18, 24)       # Đen sâu
    BgPanel     = [System.Drawing.Color]::FromArgb(30, 30, 38)       # Xám đen
    BgPartBar   = [System.Drawing.Color]::FromArgb(45, 45, 55)       # Nền thanh Disk
    TextMain    = [System.Drawing.Color]::FromArgb(240, 240, 240)    # Trắng
    TextDim     = [System.Drawing.Color]::FromArgb(160, 160, 160)    # Xám nhạt
    Accent      = [System.Drawing.Color]::FromArgb(0, 255, 200)      # Cyan Neon (Màu chủ đạo)
    PartPri     = [System.Drawing.Color]::FromArgb(0, 120, 215)      # Xanh Primary Partition
    PartLog     = [System.Drawing.Color]::FromArgb(138, 43, 226)     # Tím Logical Partition
    BtnNormal   = [System.Drawing.Color]::FromArgb(50, 50, 60)
    BtnHover    = [System.Drawing.Color]::FromArgb(70, 70, 80)
    BtnActive   = [System.Drawing.Color]::FromArgb(0, 150, 136)
    Danger      = [System.Drawing.Color]::FromArgb(255, 50, 80)      # Đỏ báo động
}

# --- GLOBAL STATE ---
$Global:SelectedPart = $null 
$Global:DiskData = @()

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "DISK MANAGER PRO V5.0 - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(1280, 800)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Colors.BgForm
$Form.ForeColor = $Colors.TextMain
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# -- FONTS --
$FontTitle = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$FontBold  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$FontNorm  = New-Object System.Drawing.Font("Segoe UI", 9)
$FontSmall = New-Object System.Drawing.Font("Consolas", 8)

# -- HEADER --
$PnlHead = New-Object System.Windows.Forms.Panel; $PnlHead.Dock="Top"; $PnlHead.Height=60; $PnlHead.BackColor=[System.Drawing.Color]::FromArgb(25, 25, 30)
$Form.Controls.Add($PnlHead)

# Logo Text với hiệu ứng vạch màu
$LblLogo = New-Object System.Windows.Forms.Label; $LblLogo.Text="DISK MANAGER"; $LblLogo.Font=$FontTitle; $LblLogo.ForeColor=$Colors.Accent; $LblLogo.AutoSize=$true; $LblLogo.Location="20,15"
$PnlHead.Controls.Add($LblLogo)
$LblSub = New-Object System.Windows.Forms.Label; $LblSub.Text="PRO EDITION"; $LblSub.Font=$FontNorm; $LblSub.ForeColor=$Colors.TextDim; $LblSub.AutoSize=$true; $LblSub.Location="180,22"
$PnlHead.Controls.Add($LblSub)

# -- MAIN LAYOUT --
$PnlBody = New-Object System.Windows.Forms.Panel; $PnlBody.Dock="Fill"; $PnlBody.Padding="20,20,20,20"
$Form.Controls.Add($PnlBody)

# 1. Left Panel (Disk List) - Chiếm 75%
$FlowDisk = New-Object System.Windows.Forms.FlowLayoutPanel
$FlowDisk.Dock = "Left"; $FlowDisk.Width = 900; $FlowDisk.AutoScroll = $true; $FlowDisk.FlowDirection = "TopDown"; $FlowDisk.WrapContents = $false
$PnlBody.Controls.Add($FlowDisk)

# 2. Right Panel (Tools) - Chiếm phần còn lại
$PnlTools = New-Object System.Windows.Forms.Panel
$PnlTools.Dock = "Fill"; $PnlTools.Padding = "20,0,0,0" # Cách trái 20px
$PnlBody.Controls.Add($PnlTools)

# Info Box (Hiển thị phân vùng đang chọn)
$GbInfo = New-Object System.Windows.Forms.GroupBox; $GbInfo.Text = "THÔNG TIN ĐANG CHỌN"; $GbInfo.ForeColor=$Colors.TextDim; $GbInfo.Location="20,0"; $GbInfo.Size="320,100"
$PnlTools.Controls.Add($GbInfo)

$LblInfoMain = New-Object System.Windows.Forms.Label; $LblInfoMain.Text="CHƯA CHỌN"; $LblInfoMain.Font=$FontTitle; $LblInfoMain.ForeColor=$Colors.Danger; $LblInfoMain.AutoSize=$false; $LblInfoMain.Dock="Top"; $LblInfoMain.Height=40; $LblInfoMain.TextAlign="MiddleCenter"
$GbInfo.Controls.Add($LblInfoMain)
$LblInfoSub = New-Object System.Windows.Forms.Label; $LblInfoSub.Text="Click vào phân vùng để thao tác"; $LblInfoSub.Font=$FontNorm; $LblInfoSub.ForeColor=$Colors.TextDim; $LblInfoSub.AutoSize=$false; $LblInfoSub.Dock="Top"; $LblInfoSub.Height=30; $LblInfoSub.TextAlign="MiddleCenter"
$GbInfo.Controls.Add($LblInfoSub)

# Action Buttons Container
$FlowAct = New-Object System.Windows.Forms.FlowLayoutPanel; $FlowAct.Location="20,120"; $FlowAct.Size="320,600"; $FlowAct.FlowDirection="TopDown"
$PnlTools.Controls.Add($FlowAct)

# --- CUSTOM UI FUNCTIONS ---

# Hàm tạo nút bấm đẹp (Flat Style)
function Add-NeonButton ($Parent, $Text, $Tag, $Color, $Icon) {
    $Btn = New-Object System.Windows.Forms.Button
    $Btn.Text = "  $Icon  $Text"
    $Btn.Tag = $Tag
    $Btn.Size = New-Object System.Drawing.Size(300, 45)
    $Btn.Margin = "0,0,0,10"
    $Btn.FlatStyle = "Flat"
    $Btn.FlatAppearance.BorderSize = 0
    $Btn.BackColor = $Colors.BtnNormal
    $Btn.ForeColor = $Colors.TextMain
    $Btn.Font = $FontBold
    $Btn.TextAlign = "MiddleLeft"
    $Btn.Cursor = "Hand"

    # Border trái màu (Accent)
    $PnlAccent = New-Object System.Windows.Forms.Panel; $PnlAccent.Width=4; $PnlAccent.Dock="Left"; $PnlAccent.BackColor=$Color
    $Btn.Controls.Add($PnlAccent)

    # Hover Effect
    $Btn.Add_MouseEnter({ $this.BackColor = $Colors.BtnHover })
    $Btn.Add_MouseLeave({ $this.BackColor = $Colors.BtnNormal })
    $Btn.Add_Click({ Run-Action $this.Tag })

    $Parent.Controls.Add($Btn)
}

# Hàm vẽ Card ổ đĩa
function Draw-DiskCard ($Disk) {
    # Main Card
    $Card = New-Object System.Windows.Forms.Panel
    $Card.Size = New-Object System.Drawing.Size(860, 140)
    $Card.Margin = "0,0,0,15"
    $Card.BackColor = $Colors.BgPanel
    # Vẽ viền mỏng
    $Card.Add_Paint({ 
        param($s, $e) 
        $p = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(50,50,50), 1)
        $e.Graphics.DrawRectangle($p, 0, 0, $s.Width-1, $s.Height-1)
    })

    # Header: Icon + Tên Disk
    $ImgDisk = New-Object System.Windows.Forms.Label; $ImgDisk.Text="💾"; $ImgDisk.Font=$FontTitle; $ImgDisk.AutoSize=$true; $ImgDisk.Location="15,10"; $ImgDisk.ForeColor=$Colors.Accent
    $Card.Controls.Add($ImgDisk)
    
    $LblName = New-Object System.Windows.Forms.Label; $LblName.Text="DISK $($Disk.ID)"; $LblName.Font=$FontBold; $LblName.ForeColor=$Colors.TextMain; $LblName.AutoSize=$true; $LblName.Location="50,12"
    $Card.Controls.Add($LblName)
    
    $LblDetail = New-Object System.Windows.Forms.Label; $LblDetail.Text="$($Disk.Status) • $($Disk.Size)"; $LblDetail.Font=$FontNorm; $LblDetail.ForeColor=$Colors.TextDim; $LblDetail.AutoSize=$true; $LblDetail.Location="50,32"
    $Card.Controls.Add($LblDetail)

    # Partition Bar Container (Thanh ngang chứa các phân vùng)
    $BarPanel = New-Object System.Windows.Forms.Panel
    $BarPanel.Location="15, 60"; $BarPanel.Size="830, 60"
    $BarPanel.BackColor = $Colors.BgPartBar
    $Card.Controls.Add($BarPanel)

    # Render Partitions
    $TotalSizeMB = $Disk.SizeMB; if ($TotalSizeMB -eq 0) { $TotalSizeMB = 1 }
    $CurrentX = 0
    $MaxW = 830

    foreach ($Part in $Disk.Partitions) {
        # Tính toán độ rộng theo %
        $Percent = $Part.SizeMB / $TotalSizeMB
        $Width = [Math]::Max(2, [int]($Percent * $MaxW))
        
        # Tránh tràn khung
        if ($CurrentX + $Width -gt $MaxW) { $Width = $MaxW - $CurrentX }

        # Tạo nút đại diện phân vùng
        $PBtn = New-Object System.Windows.Forms.Button
        $PBtn.FlatStyle = "Flat"; $PBtn.FlatAppearance.BorderSize = 0
        
        # Màu sắc dựa trên loại Partition
        if ($Part.Type -eq "Primary") { $PBtn.BackColor = $Colors.PartPri }
        else { $PBtn.BackColor = $Colors.PartLog }
        
        $PBtn.Location = "$CurrentX, 0"; $PBtn.Size = "$Width, 60"
        
        # Text hiển thị (Chỉ hiện nếu đủ rộng)
        if ($Width -gt 40) {
            $Txt = ""
            if ($Part.Letter) { $Txt += "$($Part.Letter)`n" }
            $Txt += "$($Part.Label)`n$($Part.SizeGB)"
            $PBtn.Text = $Txt
        }
        $PBtn.ForeColor = "White"; $PBtn.Font = $FontSmall
        $PBtn.Cursor = "Hand"
        
        # Tag dữ liệu để xử lý khi click
        $PBtn.Tag = @{Disk=$Disk.ID; Part=$Part.ID; Let=$Part.Letter; Lab=$Part.Label; FS=$Part.FS}
        
        # Sự kiện Click
        $PBtn.Add_Click({ 
            $Global:SelectedPart = $this.Tag
            Update-InfoPanel $this.Tag
        })
        
        # Vẽ viền trắng nhỏ ngăn cách
        $Sep = New-Object System.Windows.Forms.Panel; $Sep.Width=1; $Sep.Dock="Right"; $Sep.BackColor=$Colors.BgPanel
        $PBtn.Controls.Add($Sep)

        $BarPanel.Controls.Add($PBtn)
        $CurrentX += $Width
    }

    # Phần dung lượng trống (Unallocated - Màu xám)
    if ($CurrentX -lt $MaxW) {
        $UnallocW = $MaxW - $CurrentX
        $UnBtn = New-Object System.Windows.Forms.Panel
        $UnBtn.Location = "$CurrentX, 0"; $UnBtn.Size = "$UnallocW, 60"
        $UnBtn.BackColor = [System.Drawing.Color]::FromArgb(40,40,40)
        # Hatch Style (Gạch chéo cho vùng trống) - Advanced drawing
        $UnBtn.Add_Paint({
            param($s, $e)
            $hatchBrush = New-Object System.Drawing.Drawing2D.HatchBrush([System.Drawing.Drawing2D.HatchStyle]::BackwardDiagonal, [System.Drawing.Color]::Gray, [System.Drawing.Color]::Transparent)
            $e.Graphics.FillRectangle($hatchBrush, $s.ClientRectangle)
        })
        $BarPanel.Controls.Add($UnBtn)
    }

    $FlowDisk.Controls.Add($Card)
}

function Update-InfoPanel ($Tag) {
    $LblInfoMain.Text = if ($Tag.Let) { "Ổ $($Tag.Let)" } else { "PARTITION $($Tag.Part)" }
    $LblInfoMain.ForeColor = $Colors.Accent
    $LblInfoSub.Text = "Disk $($Tag.Disk) | FS: $($Tag.FS) | Label: $($Tag.Lab)"
}

# --- LOGIC (GIỮ NGUYÊN CORE CŨ NHƯNG TỐI ƯU) ---
function Load-Data {
    $FlowDisk.Controls.Clear(); $Global:DiskData = @(); $Global:SelectedPart = $null
    $LblInfoMain.Text="ĐANG QUÉT..."; $LblInfoMain.ForeColor=$Colors.TextDim; $LblInfoSub.Text="..."
    $Form.Cursor = "WaitCursor"; $Form.Refresh()

    $Script = "$env:TEMP\dp_scan.txt"; [IO.File]::WriteAllText($Script, "list disk")
    $RawDisks = (cmd /c "diskpart /s `"$Script`"") | Where { $_ -match "Disk \d" }
    
    foreach ($Line in $RawDisks) {
        if ($Line -match "Disk (\d+)\s+\w+\s+(\d+)\s+(GB|MB)") {
            $Did = $Matches[1]; $DSize = $Matches[2]; $Unit = $Matches[3]
            $SizeMB = if($Unit -eq "GB") { [int]$DSize * 1024 } else { [int]$DSize }
            
            $DiskObj = @{ID=$Did; Size="$DSize $Unit"; SizeMB=$SizeMB; Status="Online"; Partitions=@()}

            # Scan Partitions
            [IO.File]::WriteAllText($Script, "sel disk $Did`ndetail disk`nlist part")
            $RawParts = cmd /c "diskpart /s `"$Script`""
            
            foreach ($P in $RawParts) {
                if ($P -match "Partition (\d+)\s+(\w+)\s+(\d+)\s+(GB|MB)") {
                    $Pid = $Matches[1]; $Type = $Matches[2]; $PSize = $Matches[3]; $PUnit = $Matches[4]
                    $PSizeMB = if($PUnit -eq "GB") { [int]$PSize * 1024 } else { [int]$PSize }
                    
                    # Deep Scan
                    [IO.File]::WriteAllText($Script, "sel disk $Did`nsel part $Pid`ndetail part")
                    $Det = cmd /c "diskpart /s `"$Script`""
                    $Ltr=""; $Lab="No Label"; $Fs="RAW"
                    foreach ($R in $Det) {
                        if ($R -match "Ltr\s+:\s*([A-Z])") { $Ltr = "$($Matches[1]):" }
                        if ($R -match "Fs\s+:\s*(\w+)") { $Fs = $Matches[1] }
                        if ($R -match "Label\s+:\s*(.+)") { $Lab = $Matches[1] }
                    }
                    $DiskObj.Partitions += @{ID=$Pid; Type=$Type; SizeGB="$PSize $PUnit"; SizeMB=$PSizeMB; Letter=$Ltr; Label=$Lab; FS=$Fs}
                }
            }
            $Global:DiskData += $DiskObj
            Draw-DiskCard $DiskObj # Vẽ luôn từng cái cho mượt
            [System.Windows.Forms.Application]::DoEvents()
        }
    }
    Remove-Item $Script -ErrorAction SilentlyContinue
    
    $LblInfoMain.Text="SẴN SÀNG"; $LblInfoMain.ForeColor=$Colors.TextMain
    $LblInfoSub.Text="Đã tải xong dữ liệu ổ đĩa."
    $Form.Cursor = "Default"
}

function Run-DP ($Cmd) { 
    $F="$env:TEMP\d.txt"; [IO.File]::WriteAllText($F,$Cmd)
    Start-Process "diskpart" "/s `"$F`"" -Wait -NoNewWindow
    Remove-Item $F; Load-Data 
}

function Run-Action ($Act) {
    if ($Act -eq "Refresh") { Load-Data; return }
    if ($Act -eq "FixBoot") { Start-Process "cmd" "/c bcdboot C:\Windows /s C: /f ALL & pause"; return }
    
    $S = $Global:SelectedPart
    if (!$S) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn phân vùng nào!", "Lỗi"); return }
    $D=$S.Disk; $P=$S.Part; $L=$S.Let

    switch ($Act) {
        "Format" { if([System.Windows.Forms.MessageBox]::Show("FORMAT Ổ $L (Disk $D Part $P)?`nDỮ LIỆU SẼ BỊ XÓA VĨNH VIỄN!","CẢNH BÁO","YesNo","Warning")-eq"Yes"){ Run-DP "sel disk $D`nsel part $P`nformat fs=ntfs quick" } }
        "Delete" { if([System.Windows.Forms.MessageBox]::Show("XÓA PHÂN VÙNG $P TRÊN DISK $D?","CẢNH BÁO","YesNo","Error")-eq"Yes"){ Run-DP "sel disk $D`nsel part $P`ndelete partition override" } }
        "Active" { Run-DP "sel disk $D`nsel part $P`nactive" }
        "Label"  { $New=[Microsoft.VisualBasic.Interaction]::InputBox("Nhập ký tự ổ mới (VD: K):", "Đổi Ký Tự", ""); if($New){ Run-DP "sel disk $D`nsel part $P`nassign letter=$New" } }
        "ChkDsk" { if($L){Start-Process "cmd" "/c start cmd /k chkdsk $L /f /x"} else {[System.Windows.Forms.MessageBox]::Show("Phân vùng này chưa có ký tự ổ!", "Lỗi")} }
        "Convert"{ if([System.Windows.Forms.MessageBox]::Show("Convert Disk $D sang GPT/MBR? (Yêu cầu Clean Disk)","Hỏi","YesNo")-eq"Yes"){ Run-DP "sel disk $D`nclean`nconvert gpt" } }
    }
}

# --- ADD TOOL BUTTONS ---
Add-NeonButton $FlowAct "Làm mới (Refresh)" "Refresh" $Colors.Accent "♻️"
Add-NeonButton $FlowAct "Đổi tên / Ký tự" "Label" [System.Drawing.Color]::Orange "🏷️"
Add-NeonButton $FlowAct "Format (Định dạng)" "Format" $Colors.Danger "🧹"
Add-NeonButton $FlowAct "Set Active (Boot)" "Active" [System.Drawing.Color]::Gold "⚡"
Add-NeonButton $FlowAct "Xóa Phân Vùng" "Delete" $Colors.Danger "❌"
Add-NeonButton $FlowAct "Sửa Lỗi (ChkDsk)" "ChkDsk" [System.Drawing.Color]::LightGreen "🚑"
Add-NeonButton $FlowAct "Nạp lại Boot (BCD)" "FixBoot" [System.Drawing.Color]::Violet "🛠️"
Add-NeonButton $FlowAct "Convert GPT/MBR" "Convert" [System.Drawing.Color]::Gray "🔄"

# --- INIT ---
$Form.Add_Shown({ Load-Data })
$Form.ShowDialog() | Out-Null
