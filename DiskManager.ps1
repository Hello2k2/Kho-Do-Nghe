<#
    DISK MANAGER PRO - PHAT TAN PC
    Version: 3.2 (Empty List Fix + Robust Legacy Scan)
#>

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
    Back      = [System.Drawing.Color]::FromArgb(28, 28, 32)
    Card      = [System.Drawing.Color]::FromArgb(45, 45, 50)
    Text      = [System.Drawing.Color]::FromArgb(240, 240, 240)
    GridHead  = [System.Drawing.Color]::FromArgb(0, 122, 204)
    Accent    = [System.Drawing.Color]::FromArgb(0, 120, 215)
    Red       = [System.Drawing.Color]::FromArgb(231, 76, 60)
    Green     = [System.Drawing.Color]::FromArgb(46, 204, 113)
    Orange    = [System.Drawing.Color]::FromArgb(243, 156, 18)
    Border    = [System.Drawing.Color]::FromArgb(80, 80, 80)
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "DISK MANAGER PRO V3.2 (VM FIXED)"
$Form.Size = New-Object System.Drawing.Size(1100, 750)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back
$Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "DISK MASTER"; $LblT.Font = "Impact, 24"; $LblT.ForeColor = $Theme.Accent; $LblT.AutoSize = $true; $LblT.Location = "20,15"; $Form.Controls.Add($LblT)
$LblS = New-Object System.Windows.Forms.Label; $LblS.Text = "Engine: Hybrid V3.2 (Force Scan)"; $LblS.ForeColor = "Gray"; $LblS.AutoSize = $true; $LblS.Location = "25,55"; $Form.Controls.Add($LblS)

# --- 1. DATA GRID ---
$Grid = New-Object System.Windows.Forms.DataGridView
$Grid.Location = "20, 90"; $Grid.Size = "1045, 350"
$Grid.BackgroundColor = $Theme.Card
$Grid.ForeColor = "Black"
$Grid.GridColor = "Gray"
$Grid.BorderStyle = "None"
$Grid.AllowUserToAddRows = $false
$Grid.RowHeadersVisible = $false
$Grid.SelectionMode = "FullRowSelect"
$Grid.MultiSelect = $false
$Grid.AutoSizeColumnsMode = "Fill"
$Grid.ReadOnly = $true
$Grid.RowTemplate.Height = 35
$Grid.ColumnHeadersHeight = 40
$Grid.EnableHeadersVisualStyles = $false
$Grid.ColumnHeadersDefaultCellStyle.BackColor = $Theme.GridHead
$Grid.ColumnHeadersDefaultCellStyle.ForeColor = "White"
$Grid.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

# Columns
$Grid.Columns.Add("Type", "Loại"); $Grid.Columns["Type"].Width = 50
$Grid.Columns.Add("Disk", "Disk #"); $Grid.Columns["Disk"].FillWeight = 10
$Grid.Columns.Add("Part", "Part #"); $Grid.Columns["Part"].FillWeight = 10
$Grid.Columns.Add("Info", "Thông Tin"); $Grid.Columns["Info"].FillWeight = 30
$Grid.Columns.Add("FS", "FS"); $Grid.Columns["FS"].FillWeight = 15
$Grid.Columns.Add("Size", "Dung Lượng"); $Grid.Columns["Size"].FillWeight = 15
$Grid.Columns.Add("Free", "Còn Trống"); $Grid.Columns["Free"].FillWeight = 15
$Form.Controls.Add($Grid)

# --- 2. CONTROL CENTER ---
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = "20, 460"; $TabControl.Size = "1045, 230"
$TabControl.Font = "Segoe UI, 10"
$Form.Controls.Add($TabControl)

function Add-Tab ($Title) { 
    $P = New-Object System.Windows.Forms.TabPage; $P.Text = "  $Title  "
    $P.BackColor = $Theme.Back; $P.ForeColor = $Theme.Text
    $TabControl.Controls.Add($P); return $P 
}

function Add-CmdBtn ($Parent, $Txt, $Icon, $Col, $X, $Y, $Tag) {
    $B = New-Object System.Windows.Forms.Button; $B.Text = "$Icon  $Txt"; $B.Tag = $Tag
    $B.Size = "220, 50"; $B.Location = "$X, $Y"; $B.FlatStyle = "Flat"
    $B.BackColor = $Theme.Card; $B.ForeColor = $Col; $B.Font = "Segoe UI, 10, Bold"
    $B.FlatAppearance.BorderColor = $Col; $B.FlatAppearance.BorderSize = 1
    $B.Cursor = "Hand"; $B.TextAlign = "MiddleLeft"; $B.Padding = "10,0,0,0"
    $B.Add_Click({ Run-Action $this.Tag })
    $Parent.Controls.Add($B)
}

$Tab1 = Add-Tab "QUẢN LÝ"
Add-CmdBtn $Tab1 "LÀM MỚI (REFRESH)" "♻️" $Theme.Accent 20 20 "Refresh"
Add-CmdBtn $Tab1 "FORMAT" "🧹" $Theme.Orange 260 20 "Format"
Add-CmdBtn $Tab1 "ĐỔI TÊN/KÝ TỰ" "🏷️" $Theme.Accent 500 20 "Label"
Add-CmdBtn $Tab1 "XÓA PHÂN VÙNG" "❌" $Theme.Red 740 20 "Delete"
Add-CmdBtn $Tab1 "SET ACTIVE" "⚡" $Theme.Green 20 90 "Active"

$Tab2 = Add-Tab "CÔNG CỤ"
Add-CmdBtn $Tab2 "FIX LỖI (CHKDSK)" "🚑" $Theme.Green 20 20 "ChkDsk"
Add-CmdBtn $Tab2 "NẠP BOOT (BCD)" "🛠️" $Theme.Orange 260 20 "FixBoot"
Add-CmdBtn $Tab2 "TỐI ƯU (TRIM)" "🚀" $Theme.Accent 500 20 "Trim"
Add-CmdBtn $Tab2 "DISKPART" "💻" "White" 740 20 "DiskPart"

Add-CmdBtn $Tab2 "CONVERT MBR/GPT" "🔄" $Theme.Orange 20 90 "ConvStyle"
Add-CmdBtn $Tab2 "WIPE DISK" "💣" $Theme.Red 260 90 "Wipe"

# Log Area
$TxtLog = New-Object System.Windows.Forms.TextBox
$TxtLog.Location = "20, 600"; $TxtLog.Size = "1045, 100"; $TxtLog.Multiline = $true; $TxtLog.ReadOnly = $true; $TxtLog.Visible = $false
$Form.Controls.Add($TxtLog)
function Log ($M) { $TxtLog.AppendText("$M`r`n") }

# --- CORE LOGIC (V3.2 FIXED) ---
function Load-Data {
    $Grid.Rows.Clear()
    $Form.Cursor = "WaitCursor"
    
    # 1. THU DUNG MODERN API (GET-DISK)
    try {
        $Disks = Get-Disk -ErrorAction Stop | Sort-Object Number
        # FIX: Neu lenh chay OK nhung khong co o nao (tra ve 0) -> Chuyen sang Legacy
        if (!$Disks -or $Disks.Count -eq 0) { throw "Empty Disk List" }

        foreach ($D in $Disks) {
            $SizeGB = [Math]::Round($D.Size / 1GB, 1)
            $H = $Grid.Rows.Add("💿", "Disk $($D.Number)", "", "$($D.FriendlyName) ($($D.PartitionStyle))", "ONLINE", "$SizeGB GB", "-")
            $Grid.Rows[$H].DefaultCellStyle.BackColor = "DimGray"; $Grid.Rows[$H].DefaultCellStyle.ForeColor = "White"
            $Grid.Rows[$H].Tag = @{Type="Disk"; ID=$D.Number}

            $Parts = Get-Partition -DiskNumber $D.Number | Sort-Object PartitionNumber
            foreach ($P in $Parts) {
                $Vol = $P | Get-Volume -ErrorAction SilentlyContinue
                $Label = if($Vol.FileSystemLabel){$Vol.FileSystemLabel}else{"Partition"}
                $Let = if($P.DriveLetter){"[$($P.DriveLetter):]"}else{""}
                $FS = if($Vol){$Vol.FileSystem}else{$P.Type}
                $S = [Math]::Round($P.Size/1GB, 2)
                $F = if($Vol){[Math]::Round($Vol.SizeRemaining/1GB, 2)}else{"-"}
                
                $R = $Grid.Rows.Add("", "", $P.PartitionNumber, "$Let $Label", $FS, "$S GB", "$F GB")
                $Grid.Rows[$R].Tag = @{Type="Part"; D=$D.Number; P=$P.PartitionNumber; L=$P.DriveLetter}
            }
        }
        $Form.Cursor = "Default"; return
    } catch {
        # 2. CHUYEN SANG WMI LEGACY (CHO VM / WIN 7)
    }

    # LEGACY MODE (DIRECT WMI PARTITION SCAN)
    try {
        # Quet truc tiep Partition (Bat ke o dia vat ly nao)
        $Parts = Get-WmiObject Win32_DiskPartition
        
        # Tao header gia cho Disk 0 (Vi WMI Legacy kho nhom Disk)
        if ($Parts) {
            $H = $Grid.Rows.Add("💿", "Legacy Mode", "", "WMI Scan Results", "VM/MBR", "Auto", "-")
            $Grid.Rows[$H].DefaultCellStyle.BackColor = "DarkRed"; $Grid.Rows[$H].DefaultCellStyle.ForeColor = "White"
        }

        foreach ($P in $Parts) {
            $LogDisk = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($P.DeviceID)'} WHERE AssocClass=Win32_LogicalDiskToPartition" | Select-Object -First 1
            
            $Let = if($LogDisk){"[$($LogDisk.DeviceID)]"}else{""}
            $Lab = if($LogDisk){$LogDisk.VolumeName}else{"Partition"}
            $FS = if($LogDisk){$LogDisk.FileSystem}else{"RAW"}
            $S = [Math]::Round($P.Size/1GB, 2)
            $F = if($LogDisk){[Math]::Round($LogDisk.FreeSpace/1GB, 2)}else{"-"}
            
            $R = $Grid.Rows.Add("💾", $P.DiskIndex, $P.Index, "$Let $Lab", $FS, "$S GB", "$F GB")
            # Legacy Index WMI thuong lech 1 so voi DiskPart -> Fix P=$P.Index + 1 neu can thiet, o day ta de nguyen
            $Grid.Rows[$R].Tag = @{Type="Part"; D=$P.DiskIndex; P=$P.Index + 1; L=$LogDisk.DeviceID.Trim(":")}
        }
    } catch { [System.Windows.Forms.MessageBox]::Show("Khong doc duoc thong tin o cung!", "Loi") }
    $Form.Cursor = "Default"
}

# --- ACTIONS ---
function Run-DP ($Cmd) {
    $F="$env:TEMP\d.txt"; [IO.File]::WriteAllText($F,$Cmd); Start-Process "diskpart" "/s `"$F`"" -Wait -NoNewWindow; Remove-Item $F; Load-Data
}

function Run-Action ($Act) {
    if ($Act -eq "Refresh") { Load-Data; return }
    if ($Act -eq "DiskPart") { Start-Process "diskpart"; return }
    
    if ($Grid.SelectedRows.Count -eq 0) { return }
    $T = $Grid.SelectedRows[0].Tag
    if ($T.Type -ne "Part" -and $Act -ne "Wipe" -and $Act -ne "ConvStyle") { return }

    $D=$T.D; $P=$T.P; $L=$T.L

    switch ($Act) {
        "Format" { 
            if([System.Windows.Forms.MessageBox]::Show("FORMAT P$P DISK $D? MAT HET DU LIEU!","CANH BAO","YesNo")-eq"Yes"){
                Run-DP "sel disk $D`nsel part $P`nformat fs=ntfs quick"
            }
        }
        "Delete" {
            if([System.Windows.Forms.MessageBox]::Show("XOA BO PARTITION $P?","CANH BAO","YesNo")-eq"Yes"){
                Run-DP "sel disk $D`nsel part $P`ndelete partition override"
            }
        }
        "Active" { Run-DP "sel disk $D`nsel part $P`nactive" }
        "Hide"   { Run-DP "sel disk $D`nsel part $P`nremove" }
        "Label"  {
            $New=[Microsoft.VisualBasic.Interaction]::InputBox("Nhap ten moi:", "Rename", ""); if($New){cmd /c "label $L`: $New"; Load-Data}
        }
        "ChkDsk" { if($L){Start-Process "cmd" "/c start cmd /k chkdsk $L`: /f /x"} }
        "FixBoot" { Start-Process "cmd" "/c bcdboot C:\Windows /s C: /f ALL & pause" }
        "Trim"   { if($L){Start-Process "defrag" "/C /O $L`: /U /V" -NoNewWindow -Wait} }
        "Wipe"   { 
            if([System.Windows.Forms.MessageBox]::Show("XOA TRANG DISK $D (CLEAN ALL)?","NGUY HIEM","YesNo","Error")-eq"Yes"){
                Run-DP "sel disk $D`nclean"
            }
        }
        "ConvStyle" {
             if([System.Windows.Forms.MessageBox]::Show("Convert MBR/GPT? (Mat du lieu neu khong backup)","Hoi","YesNo")-eq"Yes"){
                Run-DP "sel disk $D`nclean`nconvert gpt"
             }
        }
    }
}

$Form.Add_Shown({ Load-Data })
$Form.ShowDialog() | Out-Null
