<#
    DISK MANAGER PRO - PHAT TAN PC
    Version: 4.0 (Neon Cyberpunk UI + Card Style + Theme Switcher)
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

# --- THEME ENGINE ---
$Global:IsDark = $true
$Themes = @{
    Dark = @{
        Back=[System.Drawing.Color]::FromArgb(20,20,25); Panel=[System.Drawing.Color]::FromArgb(35,35,40)
        Text=[System.Drawing.Color]::Cyan; Text2=[System.Drawing.Color]::WhiteSmoke
        Border=[System.Drawing.Color]::Cyan; Glow=[System.Drawing.Color]::FromArgb(50, 0, 255, 255)
        P_Pri=[System.Drawing.Color]::FromArgb(0, 120, 215); P_Log=[System.Drawing.Color]::FromArgb(46, 204, 113)
        Btn=[System.Drawing.Color]::FromArgb(50,50,60)
    }
    Light = @{
        Back=[System.Drawing.Color]::FromArgb(240,240,245); Panel=[System.Drawing.Color]::White
        Text=[System.Drawing.Color]::DeepPink; Text2=[System.Drawing.Color]::Black
        Border=[System.Drawing.Color]::DeepPink; Glow=[System.Drawing.Color]::FromArgb(50, 255, 20, 147)
        P_Pri=[System.Drawing.Color]::FromArgb(100, 149, 237); P_Log=[System.Drawing.Color]::FromArgb(255, 165, 0)
        Btn=[System.Drawing.Color]::FromArgb(220,220,220)
    }
}
$CurrentTheme = $Themes.Dark

# --- GLOBAL STATE ---
$Global:SelectedPart = $null # Luu thong tin part dang chon {Disk, Part, Letter}
$Global:DiskData = @() # Cache du lieu

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "DISK MANAGER PRO V4.0 (NEON EDITION)"
$Form.Size = New-Object System.Drawing.Size(1250, 780); $Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

# Header Panel
$PnlHead = New-Object System.Windows.Forms.Panel; $PnlHead.Dock="Top"; $PnlHead.Height=70; $Form.Controls.Add($PnlHead)
$LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text="DISK MASTER"; $LblTitle.Font="Impact, 26"; $LblTitle.AutoSize=$true; $LblTitle.Location="20,10"; $PnlHead.Controls.Add($LblTitle)
$BtnTheme = New-Object System.Windows.Forms.Button; $BtnTheme.Text="🎨 SWITCH THEME"; $BtnTheme.Size="150,40"; $BtnTheme.Location="1060,15"; $BtnTheme.FlatStyle="Flat"; $PnlHead.Controls.Add($BtnTheme)

# Main Container
$PnlMain = New-Object System.Windows.Forms.Panel; $PnlMain.Dock="Fill"; $Form.Controls.Add($PnlMain)

# Left: Disk Cards (Flow)
$FlowDisk = New-Object System.Windows.Forms.FlowLayoutPanel
$FlowDisk.Location="20,10"; $FlowDisk.Size="880,640"; $FlowDisk.AutoScroll=$true; $FlowDisk.FlowDirection="TopDown"; $FlowDisk.WrapContents=$false
$PnlMain.Controls.Add($FlowDisk)

# Right: Tools
$PnlTool = New-Object System.Windows.Forms.Panel; $PnlTool.Location="920,10"; $PnlTool.Size="300,640"; $PnlMain.Controls.Add($PnlTool)
$LblInfo = New-Object System.Windows.Forms.Label; $LblInfo.Text="CHƯA CHỌN PHÂN VÙNG"; $LblInfo.AutoSize=$false; $LblInfo.Size="280,60"; $LblInfo.Location="10,10"; $LblInfo.Font="Segoe UI, 11, Bold"; $LblInfo.TextAlign="MiddleCenter"; $LblInfo.BorderStyle="FixedSingle"; $PnlTool.Controls.Add($LblInfo)

# --- HELPER FUNCTIONS ---
function Apply-Theme {
    $T = if ($Global:IsDark) { $Themes.Dark } else { $Themes.Light }
    $Script:CurrentTheme = $T
    
    $Form.BackColor = $T.Back
    $PnlHead.BackColor = $T.Panel
    $LblTitle.ForeColor = $T.Text
    $BtnTheme.ForeColor = $T.Text; $BtnTheme.BackColor = $T.Btn
    $LblInfo.ForeColor = $T.Text2
    
    # Redraw all Cards
    $FlowDisk.Controls.Clear()
    foreach ($Disk in $Global:DiskData) { Draw-DiskCard $Disk }
    
    # Redraw Tools
    foreach ($C in $PnlTool.Controls) { if ($C -is [System.Windows.Forms.Button]) { $C.BackColor=$T.Btn; $C.ForeColor=$T.Text2; $C.FlatAppearance.BorderColor=$T.Border } }
}

$BtnTheme.Add_Click({ 
    $Global:IsDark = -not $Global:IsDark
    Apply-Theme
})

# --- DRAWING ENGINE (CARD SYSTEM) ---
function Draw-DiskCard ($Disk) {
    $T = $Script:CurrentTheme
    
    # 1. Main Card Panel
    $Card = New-Object System.Windows.Forms.Panel
    $Card.Size = New-Object System.Drawing.Size(850, 130); $Card.Margin = "0,0,0,20"; $Card.BackColor = $T.Panel
    # Glow Border Paint
    $Card.Add_Paint({ 
        param($s, $e) 
        $p = New-Object System.Drawing.Pen($T.Border, 2)
        $e.Graphics.DrawRectangle($p, 1, 1, $s.Width-2, $s.Height-2)
    })
    
    # 2. Header Info
    $LblD = New-Object System.Windows.Forms.Label; $LblD.Text="💿 DISK $($Disk.ID) - $($Disk.Status) - $($Disk.Size)"; $LblD.Font="Segoe UI, 10, Bold"; $LblD.ForeColor=$T.Text2; $LblD.AutoSize=$true; $LblD.Location="15,10"
    $Card.Controls.Add($LblD)

    # 3. Partition Visual Bar (Container)
    $BarContainer = New-Object System.Windows.Forms.Panel; $BarContainer.Location="15,40"; $BarContainer.Size="820,70"; $BarContainer.BackColor=[System.Drawing.Color]::Gray
    $Card.Controls.Add($BarContainer)
    
    # 4. Draw Partitions
    $TotalSizeMB = $Disk.SizeMB; if ($TotalSizeMB -eq 0) { $TotalSizeMB = 1 }
    $CurrentX = 0
    
    foreach ($Part in $Disk.Partitions) {
        $Width = [Math]::Max(5, [int](($Part.SizeMB / $TotalSizeMB) * 820))
        if ($CurrentX + $Width -gt 820) { $Width = 820 - $CurrentX } # Trim overflow

        $PBox = New-Object System.Windows.Forms.Button # Dung Button cho de click
        $PBox.FlatStyle = "Flat"; $PBox.FlatAppearance.BorderSize = 0
        $PBox.BackColor = if ($Part.Type -eq "Primary") { $T.P_Pri } else { $T.P_Log }
        $PBox.Location = "$CurrentX, 0"; $PBox.Size = "$Width, 70"
        $PBox.Text = "$($Part.Letter)`n$($Part.Label)`n$($Part.FS)`n$($Part.SizeGB)"
        $PBox.ForeColor = "White"; $PBox.Font = "Segoe UI, 8"
        $PBox.Cursor = "Hand"
        
        # Save Data to Tag
        $PBox.Tag = @{Disk=$Disk.ID; Part=$Part.ID; Let=$Part.Letter; Lab=$Part.Label}
        
        # Click Event
        $PBox.Add_Click({ 
            $Global:SelectedPart = $this.Tag
            $LblInfo.Text = "ĐANG CHỌN:`nDISK $($this.Tag.Disk) | PART $($this.Tag.Part) | $($this.Tag.Let)"
            $LblInfo.ForeColor = $Script:CurrentTheme.Text
        })
        
        $BarContainer.Controls.Add($PBox)
        $CurrentX += $Width
    }
    
    # 5. Add to Flow
    $FlowDisk.Controls.Add($Card)
}

# --- DATA LOADER (DISKPART PARSER) ---
function Load-Data {
    $FlowDisk.Controls.Clear(); $Global:DiskData = @(); $Global:SelectedPart = $null; $LblInfo.Text="HÃY CHỌN PHÂN VÙNG"
    $Form.Cursor = "WaitCursor"

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
                    
                    # Deep Scan for Letter/Label/FS
                    [IO.File]::WriteAllText($Script, "sel disk $Did`nsel part $Pid`ndetail part")
                    $Det = cmd /c "diskpart /s `"$Script`""
                    $Ltr=""; $Lab="NoName"; $Fs="RAW"
                    foreach ($R in $Det) {
                        if ($R -match "Ltr\s+:\s*([A-Z])") { $Ltr = "$($Matches[1]):" }
                        if ($R -match "Fs\s+:\s*(\w+)") { $Fs = $Matches[1] }
                        if ($R -match "Label\s+:\s*(.+)") { $Lab = $Matches[1] }
                    }
                    
                    $DiskObj.Partitions += @{ID=$Pid; Type=$Type; SizeGB="$PSize $PUnit"; SizeMB=$PSizeMB; Letter=$Ltr; Label=$Lab; FS=$Fs}
                }
            }
            $Global:DiskData += $DiskObj
        }
    }
    Remove-Item $Script -ErrorAction SilentlyContinue
    Apply-Theme # Render GUI
    $Form.Cursor = "Default"
}

# --- TOOL BUTTONS ---
function Add-BtnTool ($Txt, $Tag, $Y) {
    $B = New-Object System.Windows.Forms.Button; $B.Text=$Txt; $B.Tag=$Tag
    $B.Size="280,45"; $B.Location="10,$Y"; $B.FlatStyle="Flat"; $B.Font="Segoe UI, 10, Bold"
    $B.Add_Click({ Run-Action $this.Tag }); $PnlTool.Controls.Add($B)
}

Add-BtnTool "♻️ REFRESH (LÀM MỚI)" "Refresh" 80
Add-BtnTool "🏷️ ĐỔI TÊN / KÝ TỰ" "Label" 135
Add-BtnTool "🧹 FORMAT (ĐỊNH DẠNG)" "Format" 190
Add-BtnTool "⚡ SET ACTIVE" "Active" 245
Add-BtnTool "❌ XÓA PHÂN VÙNG" "Delete" 300
Add-BtnTool "🚑 FIX LỖI Ổ (CHKDSK)" "ChkDsk" 380
Add-BtnTool "🛠️ NẠP LẠI BOOT" "FixBoot" 435
Add-BtnTool "🔄 CONVERT MBR/GPT" "Convert" 490

function Run-DP ($Cmd) { $F="$env:TEMP\d.txt"; [IO.File]::WriteAllText($F,$Cmd); Start-Process "diskpart" "/s `"$F`"" -Wait -NoNewWindow; Remove-Item $F; Load-Data }

function Run-Action ($Act) {
    if ($Act -eq "Refresh") { Load-Data; return }
    if ($Act -eq "FixBoot") { Start-Process "cmd" "/c bcdboot C:\Windows /s C: /f ALL & pause"; return }
    
    $S = $Global:SelectedPart
    if (!$S) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn phân vùng nào trên biểu đồ!", "Lỗi"); return }
    $D=$S.Disk; $P=$S.Part; $L=$S.Let

    switch ($Act) {
        "Format" { if([System.Windows.Forms.MessageBox]::Show("FORMAT Ổ $L (Disk $D Part $P)? MẤT HẾT DỮ LIỆU!","CẢNH BÁO","YesNo")-eq"Yes"){ Run-DP "sel disk $D`nsel part $P`nformat fs=ntfs quick" } }
        "Delete" { if([System.Windows.Forms.MessageBox]::Show("XÓA PHÂN VÙNG $P?","CẢNH BÁO","YesNo")-eq"Yes"){ Run-DP "sel disk $D`nsel part $P`ndelete partition override" } }
        "Active" { Run-DP "sel disk $D`nsel part $P`nactive" }
        "Label"  { $New=[Microsoft.VisualBasic.Interaction]::InputBox("Nhập ký tự ổ mới (VD: K):", "Đổi Ký Tự", ""); if($New){ Run-DP "sel disk $D`nsel part $P`nassign letter=$New" } }
        "ChkDsk" { if($L){Start-Process "cmd" "/c start cmd /k chkdsk $L /f /x"} else {[System.Windows.Forms.MessageBox]::Show("Phân vùng này chưa có ký tự ổ!", "Lỗi")} }
        "Convert"{ if([System.Windows.Forms.MessageBox]::Show("Convert Disk $D sang GPT/MBR? (Cần Clean Disk)","Hỏi","YesNo")-eq"Yes"){ Run-DP "sel disk $D`nclean`nconvert gpt" } }
    }
}

$Form.Add_Shown({ Load-Data })
$Form.ShowDialog() | Out-Null
