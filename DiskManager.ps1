<#
    DISK MANAGER PRO - PHAT TAN PC
    Version: 2.0 (Hybrid Scan Engine + Modern GUI)
#>

# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"

# --- THEME ENGINE ---
$Theme = @{
    Back      = [System.Drawing.Color]::FromArgb(30, 30, 35)
    Card      = [System.Drawing.Color]::FromArgb(40, 40, 45)
    Text      = [System.Drawing.Color]::FromArgb(240, 240, 240)
    GridBack  = [System.Drawing.Color]::FromArgb(50, 50, 55)
    Accent    = [System.Drawing.Color]::FromArgb(0, 120, 215) # Blue Metro
    Green     = [System.Drawing.Color]::FromArgb(0, 200, 80)
    Red       = [System.Drawing.Color]::FromArgb(220, 50, 50)
    Orange    = [System.Drawing.Color]::FromArgb(255, 140, 0)
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "PHAT TAN PARTITION MANAGER PRO V2.0"
$Form.Size = New-Object System.Drawing.Size(1250, 750)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back; $Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

# Header
$PnlHead = New-Object System.Windows.Forms.Panel; $PnlHead.Dock="Top"; $PnlHead.Height=60; $PnlHead.BackColor=$Theme.Card; $Form.Controls.Add($PnlHead)
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "DISK & PARTITION MASTER"; $LblT.Font = "Segoe UI, 18, Bold"; $LblT.ForeColor = $Theme.Accent; $LblT.AutoSize = $true; $LblT.Location = "20,10"; $PnlHead.Controls.Add($LblT)
$LblS = New-Object System.Windows.Forms.Label; $LblS.Text = "Hybrid Engine: Auto Switch (Modern API <-> WMI Legacy)"; $LblS.ForeColor = "Gray"; $LblS.AutoSize = $true; $LblS.Location = "25,40"; $PnlHead.Controls.Add($LblS)

# --- MAIN LAYOUT ---
$Split = New-Object System.Windows.Forms.SplitContainer; $Split.Dock="Fill"; $Split.SplitterDistance=900; $Split.BackColor=$Theme.Back; $Form.Controls.Add($Split)

# --- LEFT: DISK LIST ---
$Grid = New-Object System.Windows.Forms.DataGridView
$Grid.Dock = "Fill"
$Grid.BackgroundColor = $Theme.Back
$Grid.ForeColor = "Black" # Text trong cell mau den cho de doc
$Grid.GridColor = "Gray"
$Grid.AllowUserToAddRows = $false
$Grid.RowHeadersVisible = $false
$Grid.SelectionMode = "FullRowSelect"
$Grid.MultiSelect = $false
$Grid.AutoSizeColumnsMode = "Fill"
$Grid.ReadOnly = $true
$Grid.RowTemplate.Height = 30
$Grid.ColumnHeadersHeight = 35
$Grid.ColumnHeadersDefaultCellStyle.BackColor = $Theme.Card
$Grid.ColumnHeadersDefaultCellStyle.ForeColor = "Black"
$Grid.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

# Columns
$Grid.Columns.Add("Icon", ""); $Grid.Columns["Icon"].Width = 30
$Grid.Columns.Add("Disk", "Disk #"); $Grid.Columns["Disk"].FillWeight = 10
$Grid.Columns.Add("Part", "Part #"); $Grid.Columns["Part"].FillWeight = 10
$Grid.Columns.Add("Vol", "Volume / Label"); $Grid.Columns["Vol"].FillWeight = 25
$Grid.Columns.Add("FS", "File Sys"); $Grid.Columns["FS"].FillWeight = 10
$Grid.Columns.Add("Size", "Size"); $Grid.Columns["Size"].FillWeight = 12
$Grid.Columns.Add("Free", "Free"); $Grid.Columns["Free"].FillWeight = 12
$Grid.Columns.Add("Stat", "Status"); $Grid.Columns["Stat"].FillWeight = 15
$Split.Panel1.Controls.Add($Grid)

# --- RIGHT: TOOLBOX ---
$Flow = New-Object System.Windows.Forms.FlowLayoutPanel; $Flow.Dock="Fill"; $Flow.FlowDirection="TopDown"; $Flow.AutoScroll=$true; $Flow.Padding="10,10,0,0"; $Split.Panel2.Controls.Add($Flow)

function Add-Title ($T, $C) { $L=New-Object System.Windows.Forms.Label; $L.Text=$T; $L.ForeColor=$C; $L.Font="Segoe UI, 11, Bold"; $L.AutoSize=$true; $L.Margin="0,15,0,5"; $Flow.Controls.Add($L) }
function Add-Btn ($T, $Tag, $C) { 
    $B=New-Object System.Windows.Forms.Button; $B.Text=$T; $B.Tag=$Tag; $B.Size="280,45"; $B.FlatStyle="Flat"; $B.BackColor=$Theme.Card; $B.ForeColor="White"; $B.Font="Segoe UI, 10"; $B.TextAlign="MiddleLeft"; $B.Padding="15,0,0,0"; $B.Cursor="Hand"
    $B.FlatAppearance.BorderColor=$C; $B.FlatAppearance.BorderSize=1
    $B.Add_Click({ Run-Action $this.Tag }); $Flow.Controls.Add($B)
}

Add-Title "BASIC OPERATIONS" $Theme.Accent
Add-Btn "♻️ Reload Disk Info" "Refresh" $Theme.Accent
Add-Btn "🧹 Format Partition" "Format" $Theme.Accent
Add-Btn "❌ Delete Partition" "Delete" $Theme.Red
Add-Btn "🏷️ Change Label / Letter" "Label" $Theme.Accent
Add-Btn "➕ Create New Partition" "Create" $Theme.Green

Add-Title "ADVANCED TOOLS" $Theme.Orange
Add-Btn "🚑 Check File System (Fix RAW)" "ChkDsk" $Theme.Orange
Add-Btn "🛠️ Rebuild Boot (MBR/BCD)" "FixBoot" $Theme.Orange
Add-Btn "🚀 Optimize / Trim SSD" "Trim" $Theme.Orange
Add-Btn "⚙️ DiskPart Console" "DiskPart" "Gray"

# --- CORE ENGINE: HYBRID SCAN ---
function Load-Data {
    $Grid.Rows.Clear()
    
    # 1. THU DUNG MODERN API (GET-DISK)
    try {
        $Disks = Get-Disk -ErrorAction Stop | Sort-Object Number
        foreach ($D in $Disks) {
            # Add Disk Header
            $SizeGB = [Math]::Round($D.Size / 1GB, 1)
            $Header = $Grid.Rows.Add("💿", "Disk $($D.Number)", "", "$($D.FriendlyName)", "$($D.PartitionStyle)", "$SizeGB GB", "-", "Online")
            $Grid.Rows[$Header].DefaultCellStyle.BackColor = "LightGray"
            $Grid.Rows[$Header].DefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            
            $Parts = Get-Partition -DiskNumber $D.Number | Sort-Object PartitionNumber
            foreach ($P in $Parts) {
                $Vol = $P | Get-Volume -ErrorAction SilentlyContinue
                $Label = if($Vol.FileSystemLabel){$Vol.FileSystemLabel}else{"Local Disk"}
                $Let = if($P.DriveLetter){"[$($P.DriveLetter):]"}else{""}
                $FS = if($Vol){$Vol.FileSystem}else{$P.Type}
                $S = [Math]::Round($P.Size/1GB, 2)
                $F = if($Vol){[Math]::Round($Vol.SizeRemaining/1GB, 2)}else{"-"}
                
                $R = $Grid.Rows.Add("", $D.Number, $P.PartitionNumber, "$Let $Label", $FS, "$S GB", "$F GB", "Healthy")
                $Grid.Rows[$R].Tag = @{Type="Modern"; D=$D.Number; P=$P.PartitionNumber; L=$P.DriveLetter}
            }
        }
        return # Neu thanh cong thi thoat, khong chay Legacy
    } catch {
        # 2. NEU LOI -> CHUYEN SANG WMI LEGACY (CHO WIN 7 / VM)
        Load-Legacy
    }
}

function Load-Legacy {
    try {
        $Parts = Get-WmiObject Win32_DiskPartition
        foreach ($P in $Parts) {
            $LogDisk = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($P.DeviceID)'} WHERE AssocClass=Win32_LogicalDiskToPartition" | Select-Object -First 1
            
            $Let = if($LogDisk){"[$($LogDisk.DeviceID)]"}else{""}
            $Lab = if($LogDisk){$LogDisk.VolumeName}else{"Partition"}
            $FS = if($LogDisk){$LogDisk.FileSystem}else{"RAW"}
            $S = [Math]::Round($P.Size/1GB, 2)
            $F = if($LogDisk){[Math]::Round($LogDisk.FreeSpace/1GB, 2)}else{"-"}
            
            $R = $Grid.Rows.Add("💾", $P.DiskIndex, $P.Index, "$Let $Lab", $FS, "$S GB", "$F GB", "Legacy")
            $Grid.Rows[$R].Tag = @{Type="Legacy"; D=$P.DiskIndex; P=$P.Index; L=$LogDisk.DeviceID.Trim(":")}
        }
    } catch { [System.Windows.Forms.MessageBox]::Show("Khong the doc thong tin o cung!", "Loi") }
}

# --- ACTIONS ---
function Run-DiskPart ($Cmds) {
    $F = "$env:TEMP\dp.txt"; [IO.File]::WriteAllText($F, $Cmds)
    Start-Process "diskpart" "/s `"$F`"" -Wait -NoNewWindow
    Remove-Item $F; Load-Data
}

function Run-Action ($Act) {
    if ($Act -eq "Refresh") { Load-Data; return }
    if ($Act -eq "DiskPart") { Start-Process "diskpart"; return }
    
    if ($Grid.SelectedRows.Count -eq 0) { return }
    $T = $Grid.SelectedRows[0].Tag
    if (!$T) { return } # Header Row
    $D=$T.D; $P=$T.P; $L=$T.L

    switch ($Act) {
        "Format" {
            if ([System.Windows.Forms.MessageBox]::Show("XOA SACH DU LIEU TREN PARTITION NAY?", "CANH BAO", "YesNo") -eq "Yes") {
                Run-DiskPart "select disk $D`nselect part $P`nformat fs=ntfs quick label=NewVolume"
            }
        }
        "Delete" {
            if ([System.Windows.Forms.MessageBox]::Show("XOA BO PHAN VUNG?", "CANH BAO", "YesNo") -eq "Yes") {
                Run-DiskPart "select disk $D`nselect part $P`ndelete partition override"
            }
        }
        "Label" {
            if (!$L) { [System.Windows.Forms.MessageBox]::Show("Chua co ky tu o dia (Assign Letter truoc)", "Loi"); return }
            $New = [Microsoft.VisualBasic.Interaction]::InputBox("Nhap ten moi:", "Rename", "Data")
            if ($New) { cmd /c "label $L`: $New"; Load-Data }
        }
        "ChkDsk" {
            if (!$L) { return }
            Start-Process "cmd" "/c start cmd /k chkdsk $L`: /f /x"
        }
        "FixBoot" {
             Start-Process "cmd" "/c bcdboot C:\Windows /s C: /f ALL & pause"
        }
        "Create" {
             [System.Windows.Forms.MessageBox]::Show("Chuc nang nay can chon vung Unallocated (Hien chua ho tro hien thi Unallocated).`nVui long dung DiskPart Console.", "Info")
        }
    }
}

$Form.Add_Shown({ Load-Data })
$Form.ShowDialog() | Out-Null
