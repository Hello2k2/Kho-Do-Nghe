<#
    DISK MANAGER PRO - PHAT TAN PC (V6.0 ULTIMATE LAYOUT)
    Layout: Sidebar Navigation (Left) + Disk Dashboard (Right)
    Style: Professional Dark/Neon
#>

# --- 1. ADMIN CHECK ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    if ($PSCommandPath) { Start-Process powershell "-NoP -File `"$PSCommandPath`"" -Verb RunAs; Exit }
    else { Write-Host "Run as Administrator!" -F Red; Exit }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic
$ErrorActionPreference = "SilentlyContinue"

# --- COLOR PALETTE (DEEP DARK NEON) ---
$C = @{
    FormBack    = [System.Drawing.Color]::FromArgb(18, 18, 22)      # Nền chính (Rất tối)
    Sidebar     = [System.Drawing.Color]::FromArgb(25, 25, 30)      # Nền Sidebar trái
    CardBack    = [System.Drawing.Color]::FromArgb(32, 32, 38)      # Nền Card ổ đĩa
    
    TextMain    = [System.Drawing.Color]::FromArgb(235, 235, 235)   # Trắng sáng
    TextMuted   = [System.Drawing.Color]::FromArgb(150, 150, 160)   # Xám chữ phụ
    
    Accent      = [System.Drawing.Color]::FromArgb(0, 255, 180)     # Cyan/Green Neon (Màu nhấn)
    Danger      = [System.Drawing.Color]::FromArgb(255, 60, 90)     # Đỏ (Xóa/Format)
    Warning     = [System.Drawing.Color]::FromArgb(255, 180, 0)     # Vàng (Active)
    
    PartPri     = [System.Drawing.Color]::FromArgb(0, 110, 200)     # Xanh Primary
    PartLog     = [System.Drawing.Color]::FromArgb(140, 60, 200)    # Tím Logical
    PartFree    = [System.Drawing.Color]::FromArgb(50, 50, 55)      # Xám Unallocated
    
    BtnHover    = [System.Drawing.Color]::FromArgb(45, 45, 50)
}

# --- GLOBAL STATE ---
$Global:SelectedPart = $null

# --- FORM SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "DISK MANAGER V6 - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(1280, 800)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $C.FormBack
$Form.ForeColor = $C.TextMain
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# -- FONTS --
$F_Title = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$F_Head  = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$F_Norm  = New-Object System.Drawing.Font("Segoe UI", 9)
$F_Mono  = New-Object System.Drawing.Font("Consolas", 9)

# ================= LAYOUT STRUCTURE =================

# 1. SIDEBAR (LEFT - 280px)
$PnlSide = New-Object System.Windows.Forms.Panel
$PnlSide.Dock = "Left"; $PnlSide.Width = 280
$PnlSide.BackColor = $C.Sidebar
$PnlSide.Padding = "10,20,10,20" # Padding trong
$Form.Controls.Add($PnlSide)

# 2. MAIN CONTENT (RIGHT - FILL)
$PnlMain = New-Object System.Windows.Forms.Panel
$PnlMain.Dock = "Fill"; $PnlMain.AutoScroll = $true
$PnlMain.Padding = "20,20,20,20"
$Form.Controls.Add($PnlMain)

# ================= SIDEBAR COMPONENTS =================

# Logo Area
$LblLogo = New-Object System.Windows.Forms.Label; $LblLogo.Text = "DISK MASTER"; $LblLogo.Font = $F_Title; $LblLogo.ForeColor = $C.Accent; $LblLogo.AutoSize = $true; $LblLogo.Location = "15, 20"
$PnlSide.Controls.Add($LblLogo)
$LblSub = New-Object System.Windows.Forms.Label; $LblSub.Text = "PRO EDITION"; $LblSub.Font = $F_Norm; $LblSub.ForeColor = $C.TextMuted; $LblSub.AutoSize = $true; $LblSub.Location = "180, 28"
$PnlSide.Controls.Add($LblSub)

# Separator
$Sep1 = New-Object System.Windows.Forms.Panel; $Sep1.Size="260,1"; $Sep1.Location="10,60"; $Sep1.BackColor=[System.Drawing.Color]::FromArgb(60,60,70)
$PnlSide.Controls.Add($Sep1)

# Info Box (Selected Partition)
$GbInfo = New-Object System.Windows.Forms.GroupBox; $GbInfo.Text = "INFO"; $GbInfo.ForeColor = $C.TextMuted; $GbInfo.Location = "10, 70"; $GbInfo.Size = "260, 100"
$LblSelMain = New-Object System.Windows.Forms.Label; $LblSelMain.Text = "CHƯA CHỌN"; $LblSelMain.Font = $F_Head; $LblSelMain.ForeColor = $C.Danger; $LblSelMain.AutoSize = $false; $LblSelMain.Size = "240,30"; $LblSelMain.Location = "10,25"; $LblSelMain.TextAlign = "MiddleCenter"
$LblSelSub = New-Object System.Windows.Forms.Label; $LblSelSub.Text = "--"; $LblSelSub.Font = $F_Norm; $LblSelSub.ForeColor = $C.TextMain; $LblSelSub.AutoSize = $false; $LblSelSub.Size = "240,40"; $LblSelSub.Location = "10,55"; $LblSelSub.TextAlign = "MiddleCenter"
$GbInfo.Controls.Add($LblSelMain); $GbInfo.Controls.Add($LblSelSub)
$PnlSide.Controls.Add($GbInfo)

# Buttons Container
$FlowTools = New-Object System.Windows.Forms.FlowLayoutPanel; $FlowTools.Location = "10, 190"; $FlowTools.Size = "260, 550"; $FlowTools.FlowDirection = "TopDown"
$PnlSide.Controls.Add($FlowTools)

# --- FUNCTION: ADD SIDEBAR BUTTON ---
function Add-SideBtn ($Txt, $Icon, $Tag, $Color) {
    $Btn = New-Object System.Windows.Forms.Button
    $Btn.Text = "  $Icon   $Txt"
    $Btn.Tag = $Tag
    $Btn.Size = New-Object System.Drawing.Size(260, 45)
    $Btn.Margin = "0,0,0,8" # Margin bottom
    $Btn.FlatStyle = "Flat"; $Btn.FlatAppearance.BorderSize = 0
    $Btn.BackColor = [System.Drawing.Color]::Transparent
    $Btn.ForeColor = $C.TextMain
    $Btn.Font = $F_Norm
    $Btn.TextAlign = "MiddleLeft"
    $Btn.Cursor = "Hand"
    
    # Left Border Indicator
    $Ind = New-Object System.Windows.Forms.Panel; $Ind.Width=4; $Ind.Dock="Left"; $Ind.BackColor=$Color; $Ind.Visible=$false
    $Btn.Controls.Add($Ind)

    $Btn.Add_MouseEnter({ $this.BackColor = $C.BtnHover; $Ind.Visible=$true })
    $Btn.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::Transparent; $Ind.Visible=$false })
    $Btn.Add_Click({ Run-Action $this.Tag })
    
    $FlowTools.Controls.Add($Btn)
}

# Add Tools
Add-SideBtn "Làm mới (Refresh)" "♻️" "Refresh" $C.Accent
Add-SideBtn "Đổi tên / Ký tự" "🏷️" "Label" [System.Drawing.Color]::Orange
Add-SideBtn "Set Active (Boot)" "⚡" "Active" $C.Warning
Add-SideBtn "Nạp lại Boot (BCD)" "🛠️" "FixBoot" [System.Drawing.Color]::Violet
Add-SideBtn "Sửa Lỗi (ChkDsk)" "🚑" "ChkDsk" [System.Drawing.Color]::LightGreen
Add-SideBtn "Convert GPT/MBR" "🔄" "Convert" [System.Drawing.Color]::Gray

$Sep2 = New-Object System.Windows.Forms.Label; $Sep2.Text="DANGER ZONE"; $Sep2.ForeColor=$C.Danger; $Sep2.AutoSize=$true; $Sep2.Margin="5,15,0,5"; $Sep2.Font=[System.Drawing.Font]::new("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$FlowTools.Controls.Add($Sep2)

Add-SideBtn "Format (Định dạng)" "🧹" "Format" $C.Danger
Add-SideBtn "Xóa Phân Vùng" "❌" "Delete" $C.Danger

# ================= MAIN CONTENT FUNCTIONS =================

# Hàm vẽ Card Ổ Đĩa (Gọn hơn, đẹp hơn)
function Draw-DiskRow ($Disk) {
    # 1. Container Card
    $Card = New-Object System.Windows.Forms.Panel
    $Card.Size = New-Object System.Drawing.Size(950, 110) # Chiều cao nhỏ gọn hơn
    $Card.Margin = "0,0,0,20"
    $Card.BackColor = $C.CardBack
    # Viền trái màu Accent để nhấn
    $Bord = New-Object System.Windows.Forms.Panel; $Bord.Width=3; $Bord.Dock="Left"; $Bord.BackColor=$C.Accent
    $Card.Controls.Add($Bord)

    # 2. Header: Disk Info (Nằm ngang)
    $LblD = New-Object System.Windows.Forms.Label; $LblD.Text = "DISK $($Disk.ID)"; $LblD.Font = $F_Head; $LblD.ForeColor = $C.TextMain; $LblD.AutoSize = $true; $LblD.Location = "15, 10"
    $Card.Controls.Add($LblD)
    
    $LblS = New-Object System.Windows.Forms.Label; $LblS.Text = "•  $($Disk.Status)  •  $($Disk.Size)"; $LblS.Font = $F_Norm; $LblS.ForeColor = $C.TextMuted; $LblS.AutoSize = $true; $LblS.Location = "100, 12"
    $Card.Controls.Add($LblS)

    # 3. Visual Bar Container
    $BarW = 920; $BarH = 40 # Thanh mỏng hơn
    $PnlBar = New-Object System.Windows.Forms.Panel; $PnlBar.Location = "15, 40"; $PnlBar.Size = "$BarW, $BarH"; $PnlBar.BackColor = $C.PartFree
    $Card.Controls.Add($PnlBar)

    # 4. Partition Buttons Loop
    $TotalSizeMB = $Disk.SizeMB; if ($TotalSizeMB -eq 0) { $TotalSizeMB = 1 }
    $CurX = 0
    
    foreach ($Part in $Disk.Partitions) {
        $Pct = $Part.SizeMB / $TotalSizeMB
        $W = [Math]::Max(2, [int]($Pct * $BarW))
        if ($CurX + $W -gt $BarW) { $W = $BarW - $CurX }

        $BtnP = New-Object System.Windows.Forms.Button
        $BtnP.FlatStyle = "Flat"; $BtnP.FlatAppearance.BorderSize = 0
        $BtnP.BackColor = if ($Part.Type -eq "Primary") { $C.PartPri } else { $C.PartLog }
        $BtnP.Location = "$CurX, 0"; $BtnP.Size = "$W, $BarH"
        
        # Chỉ hiện text nếu nút đủ rộng
        if ($W -gt 50) {
            $BtnP.Text = if ($Part.Letter) { $Part.Letter } else { $Part.ID }
            $BtnP.ForeColor = "White"; $BtnP.Font = $F_Head
        }
        $BtnP.Cursor = "Hand"
        $BtnP.Tag = $Part # Lưu info vào Tag
        
        # Click Event
        $BtnP.Add_Click({ 
            $Global:SelectedPart = $this.Tag
            $LblSelMain.Text = if($this.Tag.Letter){"Ổ $($this.Tag.Letter)"}else{"PARTITION $($this.Tag.ID)"}
            $LblSelMain.ForeColor = $C.Accent
            $LblSelSub.Text = "$($this.Tag.Label)`n$($this.Tag.FS) - $($this.Tag.SizeGB)"
        })
        
        # Separator (White line)
        $Sep = New-Object System.Windows.Forms.Panel; $Sep.Width=1; $Sep.Dock="Right"; $Sep.BackColor=$C.CardBack; $BtnP.Controls.Add($Sep)

        $PnlBar.Controls.Add($BtnP)
        $CurX += $W
    }

    # 5. Mini Detail Row (Thông tin chữ bên dưới thanh bar)
    $LblDet = New-Object System.Windows.Forms.Label
    $InfoStr = ""
    foreach ($P in $Disk.Partitions) {
        $L = if($P.Letter){$P.Letter}else{"#"+$P.ID}
        $InfoStr += "[$L : $($P.Label) ($($P.SizeGB))]    "
    }
    $LblDet.Text = $InfoStr; $LblDet.Font = $F_Mono; $LblDet.ForeColor = $C.TextMuted; $LblDet.AutoSize = $false; $LblDet.Size = "$BarW, 20"; $LblDet.Location = "15, 85"; $LblDet.AutoEllipsis = $true
    $Card.Controls.Add($LblDet)

    $PnlMain.Controls.Add($Card)
}

# ================= CORE LOGIC (DISKPART) =================
function Load-Data {
    $PnlMain.Controls.Clear(); $Global:SelectedPart = $null
    $LblSelMain.Text="ĐANG QUÉT..."; $LblSelMain.ForeColor=$C.TextMuted; $LblSelSub.Text="..."
    $Form.Cursor = "WaitCursor"; $Form.Refresh()

    $Script = "$env:TEMP\dp_scan.txt"; [IO.File]::WriteAllText($Script, "list disk")
    $RawDisks = (cmd /c "diskpart /s `"$Script`"") | Where { $_ -match "Disk \d" }
    
    foreach ($Line in $RawDisks) {
        if ($Line -match "Disk (\d+)\s+\w+\s+(\d+)\s+(GB|MB)") {
            $Did = $Matches[1]; $DSize = $Matches[2]; $Unit = $Matches[3]
            $SizeMB = if($Unit -eq "GB") { [int]$DSize * 1024 } else { [int]$DSize }
            
            $DiskObj = @{ID=$Did; Size="$DSize $Unit"; SizeMB=$SizeMB; Status="Online"; Partitions=@()}
            
            # Deep Scan
            [IO.File]::WriteAllText($Script, "sel disk $Did`ndetail disk`nlist part")
            $RawParts = cmd /c "diskpart /s `"$Script`""
            foreach ($P in $RawParts) {
                if ($P -match "Partition (\d+)\s+(\w+)\s+(\d+)\s+(GB|MB)") {
                    $Pid = $Matches[1]; $Type = $Matches[2]; $PSize = $Matches[3]; $PUnit = $Matches[4]
                    $PSizeMB = if($PUnit -eq "GB") { [int]$PSize * 1024 } else { [int]$PSize }
                    
                    # Fetch Label/FS/Letter
                    [IO.File]::WriteAllText($Script, "sel disk $Did`nsel part $Pid`ndetail part")
                    $Det = cmd /c "diskpart /s `"$Script`""
                    $Ltr=""; $Lab="NoName"; $Fs="RAW"
                    foreach ($R in $Det) {
                        if ($R -match "Ltr\s+:\s*([A-Z])") { $Ltr = "$($Matches[1]):" }
                        if ($R -match "Fs\s+:\s*(\w+)") { $Fs = $Matches[1] }
                        if ($R -match "Label\s+:\s*(.+)") { $Lab = $Matches[1] }
                    }
                    $DiskObj.Partitions += @{ID=$Pid; Type=$Type; SizeGB="$PSize $PUnit"; SizeMB=$PSizeMB; Letter=$Ltr; Label=$Lab; FS=$Fs; Disk=$Did}
                }
            }
            Draw-DiskRow $DiskObj
            [System.Windows.Forms.Application]::DoEvents()
        }
    }
    Remove-Item $Script -ErrorAction SilentlyContinue
    $LblSelMain.Text="SẴN SÀNG"; $LblSelMain.ForeColor=$C.TextMain; $LblSelSub.Text="Đã tải xong."
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
    if (!$S) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn phân vùng!", "Lỗi"); return }
    $D=$S.Disk; $P=$S.ID; $L=$S.Letter

    switch ($Act) {
        "Format" { if([System.Windows.Forms.MessageBox]::Show("FORMAT Ổ $L (Disk $D Part $P)?`nDỮ LIỆU SẼ BỊ XÓA VĨNH VIỄN!","CẢNH BÁO","YesNo","Warning")-eq"Yes"){ Run-DP "sel disk $D`nsel part $P`nformat fs=ntfs quick" } }
        "Delete" { if([System.Windows.Forms.MessageBox]::Show("XÓA PHÂN VÙNG $P TRÊN DISK $D?","CẢNH BÁO","YesNo","Error")-eq"Yes"){ Run-DP "sel disk $D`nsel part $P`ndelete partition override" } }
        "Active" { Run-DP "sel disk $D`nsel part $P`nactive" }
        "Label"  { $New=[Microsoft.VisualBasic.Interaction]::InputBox("Nhập ký tự ổ mới (VD: K):", "Đổi Ký Tự", ""); if($New){ Run-DP "sel disk $D`nsel part $P`nassign letter=$New" } }
        "ChkDsk" { if($L){Start-Process "cmd" "/c start cmd /k chkdsk $L /f /x"} else {[System.Windows.Forms.MessageBox]::Show("Phân vùng này chưa có ký tự ổ!", "Lỗi")} }
        "Convert"{ if([System.Windows.Forms.MessageBox]::Show("Convert Disk $D sang GPT/MBR? (Yêu cầu Clean Disk)","Hỏi","YesNo")-eq"Yes"){ Run-DP "sel disk $D`nclean`nconvert gpt" } }
    }
}

# --- INIT ---
$Form.Add_Shown({ Load-Data })
$Form.ShowDialog() | Out-Null
