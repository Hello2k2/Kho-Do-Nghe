<#
    DISK MANAGER PRO - PHAT TAN PC
    Version: 3.5 (IEX Compatible + Visual Dashboard + DiskPart Engine)
#>

# --- 1. ADMIN CHECK (IEX FRIENDLY - FIX LỖI IM RU) ---
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (!$IsAdmin) {
    # Neu chay file local (co duong dan) thi thu tu dong mo lai
    if ($PSCommandPath) {
        Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
    } else {
        # Neu chay online (IEX) ma khong co Admin thi bao loi chu KHONG DUOC TAT NGUM
        Write-Host "`n [!] LOI: BAN DANG CHAY TOOL QUA MANG (IEX) MA KHONG CO QUYEN ADMIN!" -ForegroundColor Red
        Write-Host " [i] Vui long tat PowerShell nay di." -ForegroundColor Yellow
        Write-Host " [i] Chuot phai vao Start -> Chon 'Windows PowerShell (Admin)' roi chay lai lenh." -ForegroundColor Yellow
        Read-Host " Bam Enter de thoat..."
        Exit
    }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic
$ErrorActionPreference = "SilentlyContinue"

# --- THEME ENGINE ---
$Theme = @{
    Back      = [System.Drawing.Color]::FromArgb(30, 30, 35)
    Panel     = [System.Drawing.Color]::FromArgb(40, 40, 45)
    GridHead  = [System.Drawing.Color]::FromArgb(0, 122, 204)
    Text      = [System.Drawing.Color]::WhiteSmoke
    TextDim   = [System.Drawing.Color]::Silver
    Accent    = [System.Drawing.Color]::FromArgb(0, 150, 255)
    BarBack   = [System.Drawing.Color]::FromArgb(60, 60, 60)
    BarFill   = [System.Drawing.Color]::FromArgb(0, 200, 80)
    BarFull   = [System.Drawing.Color]::FromArgb(220, 50, 50)
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "DISK MANAGER PRO V3.5 (VISUAL DASHBOARD)"
$Form.Size = New-Object System.Drawing.Size(1200, 750)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back
$Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$PnlHead = New-Object System.Windows.Forms.Panel; $PnlHead.Dock="Top"; $PnlHead.Height=70; $PnlHead.BackColor=$Theme.Panel; $Form.Controls.Add($PnlHead)
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "DISK MASTER PRO"; $LblT.Font = "Impact, 26"; $LblT.ForeColor = $Theme.Accent; $LblT.AutoSize = $true; $LblT.Location = "20,10"; $PnlHead.Controls.Add($LblT)
$LblS = New-Object System.Windows.Forms.Label; $LblS.Text = "Hệ thống quản lý ổ đĩa trực quan (DiskPart Engine - VM Compatible)"; $LblS.ForeColor = "Gray"; $LblS.AutoSize = $true; $LblS.Location = "25,52"; $PnlHead.Controls.Add($LblS)

# --- SPLIT CONTAINER ---
$Split = New-Object System.Windows.Forms.SplitContainer; $Split.Dock="Fill"; $Split.SplitterDistance=850; $Split.BackColor=$Theme.Back; $Form.Controls.Add($Split)

# --- LEFT: DATA GRID (VISUAL) ---
$Grid = New-Object System.Windows.Forms.DataGridView
$Grid.Dock = "Fill"
$Grid.BackgroundColor = $Theme.Back
$Grid.ForeColor = "Black"
$Grid.GridColor = "Gray"
$Grid.BorderStyle = "None"
$Grid.AllowUserToAddRows = $false; $Grid.RowHeadersVisible = $false
$Grid.SelectionMode = "FullRowSelect"; $Grid.MultiSelect = $false
$Grid.AutoSizeColumnsMode = "Fill"; $Grid.ReadOnly = $true
$Grid.RowTemplate.Height = 40
$Grid.ColumnHeadersHeight = 45
$Grid.EnableHeadersVisualStyles = $false
$Grid.ColumnHeadersDefaultCellStyle.BackColor = $Theme.GridHead
$Grid.ColumnHeadersDefaultCellStyle.ForeColor = "White"
$Grid.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)

# Columns
$Grid.Columns.Add("Icon", ""); $Grid.Columns["Icon"].Width = 40
$Grid.Columns.Add("Disk", "Disk"); $Grid.Columns["Disk"].Width = 60
$Grid.Columns.Add("Info", "Thông Tin Phân Vùng"); $Grid.Columns["Info"].FillWeight = 30
$Grid.Columns.Add("FS", "Định Dạng"); $Grid.Columns["FS"].Width = 80
$Grid.Columns.Add("Usage", "Dung Lượng Sử Dụng (Trực Quan)"); $Grid.Columns["Usage"].FillWeight = 40
$Grid.Columns.Add("Detail", "Chi Tiết"); $Grid.Columns["Detail"].Width = 150
$Split.Panel1.Controls.Add($Grid)

# --- RIGHT: COMMAND CENTER ---
$PnlCmd = New-Object System.Windows.Forms.FlowLayoutPanel; $PnlCmd.Dock="Fill"; $PnlCmd.FlowDirection="TopDown"; $PnlCmd.Padding="10,20,10,0"; $PnlCmd.AutoScroll=$true; $Split.Panel2.Controls.Add($PnlCmd)

function Add-Group ($Title) {
    $L = New-Object System.Windows.Forms.Label; $L.Text=$Title; $L.Font="Segoe UI, 12, Bold"; $L.ForeColor=$Theme.Accent; $L.AutoSize=$true; $L.Margin="0,10,0,5"
    $PnlCmd.Controls.Add($L)
}
function Add-Btn ($Txt, $Tag, $Color) {
    $B = New-Object System.Windows.Forms.Button; $B.Text=$Txt; $B.Tag=$Tag; $B.Size="300,50"; $B.FlatStyle="Flat"
    $B.BackColor=$Theme.Panel; $B.ForeColor=$Color; $B.Font="Segoe UI, 10, Bold"; $B.TextAlign="MiddleLeft"; $B.Padding="15,0,0,0"; $B.Cursor="Hand"
    $B.FlatAppearance.BorderColor=$Color; $B.FlatAppearance.BorderSize=1
    $B.Add_Click({ Run-Action $this.Tag }); $PnlCmd.Controls.Add($B)
}

Add-Group "QUẢN LÝ PHÂN VÙNG"
Add-Btn "♻️  LÀM MỚI (REFRESH)" "Refresh" "Cyan"
Add-Btn "🏷️  ĐỔI TÊN / KÝ TỰ" "Label" "Cyan"
Add-Btn "🧹  FORMAT (ĐỊNH DẠNG)" "Format" "Orange"
Add-Btn "⚡  SET ACTIVE (BOOT)" "Active" "Lime"
Add-Btn "❌  XÓA PHÂN VÙNG" "Delete" "Red"

Add-Group "CÔNG CỤ CỨU HỘ"
Add-Btn "🚑  FIX LỖI Ổ (CHKDSK)" "ChkDsk" "Gold"
Add-Btn "🛠️  NẠP LẠI BOOT (BCD)" "FixBoot" "Gold"
Add-Btn "💻  MỞ DISKPART CMD" "DiskPart" "White"
Add-Btn "🔄  CONVERT MBR <-> GPT" "Convert" "Silver"

# --- CUSTOM PAINTING (VE THANH DUNG LUONG) ---
$Grid.Add_CellPainting({
    param($s, $e)
    if ($e.ColumnIndex -eq 4 -and $e.RowIndex -ge 0) {
        $e.PaintBackground($e.CellBounds, $true)
        
        $Tag = $Grid.Rows[$e.RowIndex].Tag
        if ($Tag.Type -eq "Part" -and $Tag.TotalGB -gt 0) {
            $Pct = 0; if ($Tag.UsedGB -gt 0) { $Pct = ($Tag.UsedGB / $Tag.TotalGB) }; if ($Pct -gt 1) { $Pct = 1 }
            $Rect = $e.CellBounds; $Rect.X += 5; $Rect.Y += 8; $Rect.Width -= 10; $Rect.Height -= 16
            
            # Background Bar
            $BrushBack = New-Object System.Drawing.SolidBrush($Theme.BarBack)
            $e.Graphics.FillRectangle($BrushBack, $Rect)
            
            # Fill Bar
            $FillWidth = [int]($Rect.Width * $Pct)
            $Color = if ($Pct -gt 0.9) { $Theme.BarFull } else { $Theme.BarFill }
            $BrushFill = New-Object System.Drawing.SolidBrush($Color)
            $FillRect = $Rect; $FillRect.Width = $FillWidth
            if ($FillWidth -gt 0) { $e.Graphics.FillRectangle($BrushFill, $FillRect) }

            # Text
            $Txt = "$([Math]::Round($Pct*100, 0))% Used"
            $Fnt = New-Object System.Drawing.Font("Segoe UI", 8)
            $TextPt = New-Object System.Drawing.PointF($Rect.X + $Rect.Width/2 - 20, $Rect.Y + 2)
            $e.Graphics.DrawString($Txt, $Fnt, [System.Drawing.Brushes]::White, $TextPt)
        }
        $e.Handled = $true
    }
})

# --- CORE LOGIC (DISKPART - ENGINE CHUẨN NHẤT CHO VM) ---
function Load-Data {
    $Grid.Rows.Clear(); $Form.Cursor = "WaitCursor"
    
    # Lay thong tin WMI Logical Disk de map size chinh xac
    $LogDisks = Get-WmiObject Win32_LogicalDisk
    $DiskStats = @{}
    foreach ($LD in $LogDisks) {
        $DiskStats[$LD.DeviceID] = @{
            Size = [Math]::Round($LD.Size / 1GB, 2)
            Free = [Math]::Round($LD.FreeSpace / 1GB, 2)
            Used = [Math]::Round(($LD.Size - $LD.FreeSpace) / 1GB, 2)
            Vol  = $LD.VolumeName
            FS   = $LD.FileSystem
        }
    }

    # Dung DiskPart de lay cau truc vat ly
    $DP_Script = "$env:TEMP\dp_list.txt"; [IO.File]::WriteAllText($DP_Script, "list disk")
    $RawDisks = (cmd /c "diskpart /s `"$DP_Script`"") | Where {$_.Trim() -match "^Disk \d"}

    foreach ($Line in $RawDisks) {
        if ($Line -match "Disk (\d+)") {
            $Did = $Matches[1]
            $H = $Grid.Rows.Add("💿", "$Did", "$Line", "-", "-", "-")
            $Grid.Rows[$H].DefaultCellStyle.BackColor = "DimGray"; $Grid.Rows[$H].DefaultCellStyle.ForeColor = "White"
            $Grid.Rows[$H].Tag = @{Type="Disk"; ID=$Did}

            [IO.File]::WriteAllText($DP_Script, "sel disk $Did`ndetail disk`nlist part")
            $RawParts = cmd /c "diskpart /s `"$DP_Script`""
            
            foreach ($PL in $RawParts) {
                if ($PL -match "Partition (\d+)") {
                    $Pid = $Matches[1]; $PInfo = $PL -replace "\s+", " "
                    
                    # De lay Drive Letter, phai detail partition
                    [IO.File]::WriteAllText($DP_Script, "sel disk $Did`nsel part $Pid`ndetail part")
                    $PartDet = cmd /c "diskpart /s `"$DP_Script`""
                    
                    $Ltr = ""; $VolLab = ""; $Fs = ""; $Total = 0; $Used = 0
                    foreach ($R in $PartDet) {
                        if ($R -match "Ltr\s+:\s*([A-Z])") { $Ltr = "$($Matches[1]):" }
                        if ($R -match "Fs\s+:\s*(\w+)") { $Fs = $Matches[1] }
                    }
                    
                    if ($Ltr -and $DiskStats.ContainsKey($Ltr)) {
                        $Info = $DiskStats[$Ltr]
                        $Total = $Info.Size; $Used = $Info.Used; $VolLab = $Info.Vol; if (!$Fs) { $Fs = $Info.FS }
                        $TxtSize = "$Total GB"; $TxtFree = "$($Info.Free) GB Free"
                    } else {
                        $Arr = $PInfo.Split(" "); $SizeStr = $Arr[-2] + " " + $Arr[-1]
                        $TxtSize = $SizeStr; $TxtFree = "Hidden/System"
                    }
                    
                    $LabelShow = if($Ltr){"[$Ltr] $VolLab"}else{"(System/Recovery)"}
                    
                    $Row = $Grid.Rows.Add("📄", "$Did", "$Pid: $LabelShow", $Fs, "", "$TxtSize | $TxtFree")
                    $Grid.Rows[$Row].Tag = @{
                        Type="Part"; D=$Did; P=$Pid; L=$Ltr; 
                        TotalGB=$Total; UsedGB=$Used
                    }
                }
            }
        }
    }
    Remove-Item $DP_Script -ErrorAction SilentlyContinue; $Form.Cursor = "Default"
}

# --- ACTIONS ---
function Run-DP ($Cmd) { $F="$env:TEMP\d.txt"; [IO.File]::WriteAllText($F,$Cmd); Start-Process "diskpart" "/s `"$F`"" -Wait -NoNewWindow; Remove-Item $F; Load-Data }

function Run-Action ($Act) {
    if ($Act -eq "Refresh") { Load-Data; return }
    if ($Act -eq "DiskPart") { Start-Process "diskpart"; return }
    
    if ($Grid.SelectedRows.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn phân vùng!", "Lỗi"); return }
    $T = $Grid.SelectedRows[0].Tag
    if ($T.Type -ne "Part" -and $Act -ne "Convert" -and $Act -ne "Wipe") { return }
    $D=$T.D; $P=$T.P; $L=$T.L

    switch ($Act) {
        "Format" { if([System.Windows.Forms.MessageBox]::Show("FORMAT Ổ $L? MẤT HẾT DỮ LIỆU!","CẢNH BÁO","YesNo")-eq"Yes"){ Run-DP "sel disk $D`nsel part $P`nformat fs=ntfs quick" } }
        "Delete" { if([System.Windows.Forms.MessageBox]::Show("XÓA PHÂN VÙNG $P?","CẢNH BÁO","YesNo")-eq"Yes"){ Run-DP "sel disk $D`nsel part $P`ndelete partition override" } }
        "Active" { Run-DP "sel disk $D`nsel part $P`nactive" }
        "Label"  { $New=[Microsoft.VisualBasic.Interaction]::InputBox("Nhập ký tự ổ mới (VD: K):", "Đổi Ký Tự", ""); if($New){ Run-DP "sel disk $D`nsel part $P`nassign letter=$New" } }
        "ChkDsk" { if($L){Start-Process "cmd" "/c start cmd /k chkdsk $L /f /x"} }
        "FixBoot"{ Start-Process "cmd" "/c bcdboot C:\Windows /s C: /f ALL & pause" }
        "Convert"{ if([System.Windows.Forms.MessageBox]::Show("Convert MBR <-> GPT? (Mất dữ liệu)","Hỏi","YesNo")-eq"Yes"){ Run-DP "sel disk $D`nclean`nconvert gpt" } }
    }
}

$Form.Add_Shown({ Load-Data })
$Form.ShowDialog() | Out-Null
