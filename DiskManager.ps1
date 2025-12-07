<#
    DISK MANAGER PRO - PHAT TAN PC
    Version: 3.3 (DiskPart Parser Engine - Fix Missing C Drive)
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
$Form.Text = "DISK MANAGER PRO V3.3 (DISKPART ENGINE)"
$Form.Size = New-Object System.Drawing.Size(1100, 750)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back; $Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

# Header
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "DISK MASTER"; $LblT.Font = "Impact, 24"; $LblT.ForeColor = $Theme.Accent; $LblT.AutoSize = $true; $LblT.Location = "20,15"; $Form.Controls.Add($LblT)
$LblS = New-Object System.Windows.Forms.Label; $LblS.Text = "Engine: DiskPart Parser (100% Compatible)"; $LblS.ForeColor = "Gray"; $LblS.AutoSize = $true; $LblS.Location = "25,55"; $Form.Controls.Add($LblS)

# --- GRID ---
$Grid = New-Object System.Windows.Forms.DataGridView
$Grid.Location = "20, 90"; $Grid.Size = "1045, 350"
$Grid.BackgroundColor = $Theme.Card
$Grid.ForeColor = "Black"
$Grid.AllowUserToAddRows = $false; $Grid.RowHeadersVisible = $false; $Grid.SelectionMode = "FullRowSelect"; $Grid.MultiSelect = $false; $Grid.AutoSizeColumnsMode = "Fill"; $Grid.ReadOnly = $true
$Grid.RowTemplate.Height = 35; $Grid.ColumnHeadersHeight = 40; $Grid.EnableHeadersVisualStyles = $false
$Grid.ColumnHeadersDefaultCellStyle.BackColor = $Theme.GridHead; $Grid.ColumnHeadersDefaultCellStyle.ForeColor = "White"; $Grid.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

$Grid.Columns.Add("Type", "Loại"); $Grid.Columns["Type"].Width = 50
$Grid.Columns.Add("Disk", "Disk"); $Grid.Columns["Disk"].FillWeight = 10
$Grid.Columns.Add("Part", "Part"); $Grid.Columns["Part"].FillWeight = 10
$Grid.Columns.Add("Info", "Volume Info"); $Grid.Columns["Info"].FillWeight = 30
$Grid.Columns.Add("FS", "FS"); $Grid.Columns["FS"].FillWeight = 15
$Grid.Columns.Add("Size", "Size"); $Grid.Columns["Size"].FillWeight = 15
$Grid.Columns.Add("Stat", "Status"); $Grid.Columns["Stat"].FillWeight = 15
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

# Log Area
$TxtLog = New-Object System.Windows.Forms.TextBox
$TxtLog.Location = "20, 600"; $TxtLog.Size = "1045, 100"; $TxtLog.Multiline = $true; $TxtLog.ReadOnly = $true; $TxtLog.Visible = $false
$Form.Controls.Add($TxtLog)
function Log ($M) { $TxtLog.AppendText("$M`r`n") }

# --- CORE ENGINE: DISKPART PARSER (100% WORKS) ---
function Load-Data {
    $Grid.Rows.Clear()
    $Form.Cursor = "WaitCursor"
    
    # 1. LAY DANH SACH DISK
    $DP_Script = "$env:TEMP\dp_list.txt"
    [IO.File]::WriteAllText($DP_Script, "list disk")
    $RawDisks = (cmd /c "diskpart /s `"$DP_Script`"") | Where-Object { $_ -match "Disk \d" }
    
    foreach ($Line in $RawDisks) {
        # Parse Disk Info
        if ($Line -match "Disk (\d+)\s+Online\s+(\d+\s\w+)") {
            $DiskID = $Matches[1]
            $DiskSize = $Matches[2]
            
            $H = $Grid.Rows.Add("💿", "Disk $DiskID", "", "Online ($DiskSize)", "-", "-", "OK")
            $Grid.Rows[$H].DefaultCellStyle.BackColor = "DimGray"; $Grid.Rows[$H].DefaultCellStyle.ForeColor = "White"
            $Grid.Rows[$H].Tag = @{Type="Disk"; D=$DiskID}

            # 2. LAY PARTITION CUA DISK NAY
            [IO.File]::WriteAllText($DP_Script, "select disk $DiskID`ndetail disk`nlist partition")
            $RawParts = cmd /c "diskpart /s `"$DP_Script`""
            
            # Parse Volume Info (Tim Volume lien ket)
            $Volumes = @()
            $VolLines = $RawParts | Where-Object { $_ -match "Volume \d" }
            foreach ($V in $VolLines) {
                # Parse: Volume 1     C   Windows      NTFS   Partition
                $V = $V -replace "\s+", " " # Chuan hoa khoang trang
                $PartsV = $V.Split(" ")
                $VolID = $PartsV[1]
                $Ltr = $PartsV[2]
                $Lab = $PartsV[3]
                $Fs = $PartsV[4]
                # Luu vao Map don gian
                $Volumes += @{Id=$VolID; Ltr=$Ltr; Lab=$Lab; Fs=$Fs}
            }

            # Parse Partition Info
            $PartLines = $RawParts | Where-Object { $_ -match "Partition \d" }
            foreach ($P in $PartLines) {
                if ($P -match "Partition (\d+)") {
                    $PartID = $Matches[1]
                    $P = $P -replace "\s+", " "
                    $Details = $P.Split(" ")
                    $Size = $Details[-2] + " " + $Details[-1] # VD: 100 GB
                    
                    # Tim Volume tuong ung (Co the khong chinh xac 100% neu 1 disk nhieu vol giong nhau, nhung du dung)
                    # O day ta hien thi Partition truoc.
                    
                    # De chinh xac, ta can select part roi detail part. Hoi cham nhung chuan.
                    [IO.File]::WriteAllText($DP_Script, "select disk $DiskID`nselect partition $PartID`ndetail partition")
                    $PartDetail = cmd /c "diskpart /s `"$DP_Script`""
                    
                    $VolInfo = "-"
                    $Let = ""; $Lab = ""; $Fs = ""
                    
                    # Tim Volume Ltr trong detail
                    foreach ($Row in $PartDetail) {
                        if ($Row -match "Volume \d") {
                             $Row = $Row -replace "\s+", " "
                             $VData = $Row.Split(" ")
                             $Let = if($VData[2].Length -eq 1){"[$($VData[2]):]"}else{""}
                             $Lab = $VData[3]
                             $Fs = $VData[4]
                             break
                        }
                    }
                    
                    $R = $Grid.Rows.Add("", "", $PartID, "$Let $Lab", $Fs, $Size, "Healthy")
                    $Grid.Rows[$R].Tag = @{Type="Part"; D=$DiskID; P=$PartID; L=$Let.Trim("[]:")}
                }
            }
        }
    }
    Remove-Item $DP_Script -ErrorAction SilentlyContinue
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
        "Label"  {
            $New=[Microsoft.VisualBasic.Interaction]::InputBox("Nhap ten moi:", "Rename", ""); if($New){cmd /c "label $L`: $New"; Load-Data}
        }
        "ChkDsk" { if($L){Start-Process "cmd" "/c start cmd /k chkdsk $L`: /f /x"} }
        "FixBoot" { Start-Process "cmd" "/c bcdboot C:\Windows /s C: /f ALL & pause" }
    }
}

$Form.Add_Shown({ Load-Data })
$Form.ShowDialog() | Out-Null
