<#
    DISK MANAGER PRO - PHAT TAN PC
    Version: 3.1 (VM Compatibility Fix + Robust Legacy Scan)
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
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "DISK MANAGER PRO V3.1 (VM FIXED)"
$Form.Size = New-Object System.Drawing.Size(1100, 750)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back; $Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

# Header
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "DISK MASTER"; $LblT.Font = New-Object System.Drawing.Font("Impact", 24); $LblT.ForeColor = $Theme.Accent; $LblT.AutoSize = $true; $LblT.Location = "20,15"; $Form.Controls.Add($LblT)
$LblS = New-Object System.Windows.Forms.Label; $LblS.Text = "Mode: Auto-Detect (VM Optimized)"; $LblS.ForeColor = "Gray"; $LblS.AutoSize = $true; $LblS.Location = "25,55"; $Form.Controls.Add($LblS)

# --- GRID ---
$Grid = New-Object System.Windows.Forms.DataGridView
$Grid.Location = "20, 90"; $Grid.Size = "1045, 350"
$Grid.BackgroundColor = $Theme.Card
$Grid.ForeColor = "Black"
$Grid.AllowUserToAddRows = $false; $Grid.RowHeadersVisible = $false; $Grid.SelectionMode = "FullRowSelect"; $Grid.MultiSelect = $false; $Grid.AutoSizeColumnsMode = "Fill"; $Grid.ReadOnly = $true
$Grid.RowTemplate.Height = 35; $Grid.ColumnHeadersHeight = 40; $Grid.EnableHeadersVisualStyles = $false
$Grid.ColumnHeadersDefaultCellStyle.BackColor = $Theme.GridHead; $Grid.ColumnHeadersDefaultCellStyle.ForeColor = "White"; $Grid.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

$Grid.Columns.Add("Type", "Loại"); $Grid.Columns["Type"].Width = 50
$Grid.Columns.Add("Disk", "Disk #"); $Grid.Columns["Disk"].FillWeight = 10
$Grid.Columns.Add("Part", "Part #"); $Grid.Columns["Part"].FillWeight = 10
$Grid.Columns.Add("Info", "Thông Tin"); $Grid.Columns["Info"].FillWeight = 30
$Grid.Columns.Add("FS", "FS"); $Grid.Columns["FS"].FillWeight = 15
$Grid.Columns.Add("Size", "Size"); $Grid.Columns["Size"].FillWeight = 15
$Grid.Columns.Add("Free", "Free"); $Grid.Columns["Free"].FillWeight = 15
$Form.Controls.Add($Grid)

# --- CONTROLS ---
$TabControl = New-Object System.Windows.Forms.TabControl; $TabControl.Location = "20, 460"; $TabControl.Size = "1045, 230"; $TabControl.Font = New-Object System.Drawing.Font("Segoe UI", 10); $Form.Controls.Add($TabControl)

function Add-Tab ($Title) { $P = New-Object System.Windows.Forms.TabPage; $P.Text = "  $Title  "; $P.BackColor = $Theme.Back; $P.ForeColor = $Theme.Text; $TabControl.Controls.Add($P); return $P }
function Add-CmdBtn ($Parent, $Txt, $Icon, $Col, $X, $Y, $Tag) {
    $B = New-Object System.Windows.Forms.Button; $B.Text = "$Icon  $Txt"; $B.Tag = $Tag; $B.Size = "220, 50"; $B.Location = "$X, $Y"; $B.FlatStyle = "Flat"
    $B.BackColor = $Theme.Card; $B.ForeColor = $Col; $B.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $B.FlatAppearance.BorderColor = $Col; $B.FlatAppearance.BorderSize = 1; $B.Cursor = "Hand"; $B.TextAlign = "MiddleLeft"; $B.Padding = "10,0,0,0"
    $B.Add_Click({ Run-Action $this.Tag }); $Parent.Controls.Add($B)
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
Add-CmdBtn $Tab2 "DISKPART" "💻" "White" 500 20 "DiskPart"

# --- CORE ENGINE (VM FIXED) ---
function Load-Data {
    $Grid.Rows.Clear()
    $Form.Cursor = "WaitCursor"
    
    # --- UU TIEN 1: MODERN API (Win 8/10/11) ---
    try {
        $Disks = Get-Disk -ErrorAction Stop | Sort-Object Number
        foreach ($D in $Disks) {
            $SizeGB = [Math]::Round($D.Size / 1GB, 1)
            $H = $Grid.Rows.Add("💿", "Disk $($D.Number)", "", "$($D.FriendlyName) ($($D.PartitionStyle))", "ONLINE", "$SizeGB GB", "-")
            $Grid.Rows[$H].DefaultCellStyle.BackColor = "DimGray"; $Grid.Rows[$H].DefaultCellStyle.ForeColor = "White"; $Grid.Rows[$H].Tag = @{Type="Disk"; ID=$D.Number}

            $Parts = Get-Partition -DiskNumber $D.Number | Sort-Object PartitionNumber
            foreach ($P in $Parts) {
                $Vol = $P | Get-Volume -ErrorAction SilentlyContinue
                $Let = if($P.DriveLetter){"[$($P.DriveLetter):]"}else{""}
                $Lab = if($Vol.FileSystemLabel){$Vol.FileSystemLabel}else{"Partition"}
                $FS = if($Vol){$Vol.FileSystem}else{$P.Type}
                $S = [Math]::Round($P.Size/1GB, 2); $F = if($Vol){[Math]::Round($Vol.SizeRemaining/1GB, 2)}else{"-"}
                
                $R = $Grid.Rows.Add("", "", $P.PartitionNumber, "$Let $Lab", $FS, "$S GB", "$F GB")
                $Grid.Rows[$R].Tag = @{Type="Part"; D=$D.Number; P=$P.PartitionNumber; L=$P.DriveLetter}
            }
        }
        $Form.Cursor = "Default"; return
    } catch {
        # --- UU TIEN 2: LEGACY WMI (Win 7 / VM) ---
        Load-Legacy
    }
}

function Load-Legacy {
    try {
        # Quet O cung vat ly truoc
        $Disks = Get-WmiObject Win32_DiskDrive
        foreach ($D in $Disks) {
            $SizeGB = [Math]::Round($D.Size / 1GB, 1)
            $H = $Grid.Rows.Add("💿", "Disk $($D.Index)", "", "$($D.Model)", "MBR", "$SizeGB GB", "-")
            $Grid.Rows[$H].DefaultCellStyle.BackColor = "DimGray"; $Grid.Rows[$H].DefaultCellStyle.ForeColor = "White"

            # Quet Partition cua Disk nay
            $Query = "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($D.DeviceID)'} WHERE AssocClass=Win32_DiskDriveToDiskPartition"
            $Parts = Get-WmiObject -Query $Query
            
            foreach ($P in $Parts) {
                # Lay Thong tin Logical Disk (O C:, D:...)
                $LogQuery = "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($P.DeviceID)'} WHERE AssocClass=Win32_LogicalDiskToPartition"
                $LogDisk = Get-WmiObject -Query $LogQuery | Select-Object -First 1
                
                $Let = if($LogDisk){"[$($LogDisk.DeviceID)]"}else{""}
                $Lab = if($LogDisk){$LogDisk.VolumeName}else{"Partition"}
                $FS = if($LogDisk){$LogDisk.FileSystem}else{"RAW"}
                $S = [Math]::Round($P.Size/1GB, 2)
                $F = if($LogDisk){[Math]::Round($LogDisk.FreeSpace/1GB, 2)}else{"-"}
                
                $R = $Grid.Rows.Add("", "", $P.Index, "$Let $Lab", $FS, "$S GB", "$F GB")
                # Fix: Legacy Index cua WMI khac DiskPart 1 ti, can mapping chuan
                $Grid.Rows[$R].Tag = @{Type="Part"; D=$D.Index; P=$P.Index + 1; L=$LogDisk.DeviceID.Trim(":")} 
            }
        }
    } catch { [System.Windows.Forms.MessageBox]::Show("Khong doc duoc thong tin o cung (Legacy Mode Fail)!", "Loi") }
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
    if ($T.Type -ne "Part") { return }

    $D=$T.D; $P=$T.P; $L=$T.L

    switch ($Act) {
        "Format" { 
            if([System.Windows.Forms.MessageBox]::Show("FORMAT P$P DISK $D? MAT HET DU LIEU!","CANH BAO","YesNo")-eq"Yes"){ Run-DP "sel disk $D`nsel part $P`nformat fs=ntfs quick" }
        }
        "Delete" {
            if([System.Windows.Forms.MessageBox]::Show("XOA BO PARTITION $P?","CANH BAO","YesNo")-eq"Yes"){ Run-DP "sel disk $D`nsel part $P`ndelete partition override" }
        }
        "Active" { Run-DP "sel disk $D`nsel part $P`nactive" }
        "Label"  {
            $New=[Microsoft.VisualBasic.Interaction]::InputBox("Nhap ten moi:", "Rename", ""); if($New){cmd /c "label $L`: $New"; Load-Data}
        }
        "ChkDsk" { if($L){Start-Process "cmd" "/c start cmd /k chkdsk $L`: /f /x"} }
        "FixBoot" { Start-Process "cmd" "/c bcdboot C:\Windows /s C: /f ALL & pause" }
    }
}

$Form.Add_Shown({ Load-Data })
$Form.ShowDialog() | Out-Null
