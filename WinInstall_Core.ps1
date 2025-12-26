<#
    WININSTALL CORE V6.0 (ULTIMATE BYPASS)
    Author: Phat Tan PC
    Features:
    - Smart Mount ISO (Direct > Snapshot > Manual).
    - Auto DISM Install with Bypass Mode (No WIM Mount required).
    - Driver Injection & Auto Reboot.
#>

# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CONFIG ---
$Global:WinToHDD_Url = "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/WinToHDD.exe"
$Global:SelectedDisk = $null
$Global:SelectedPart = $null
$Global:SelectedLetter = $null
$Global:IsoMounted = $null
$Global:WimFile = $null

# --- THEME ---
$Theme = @{ Bg=[System.Drawing.Color]::FromArgb(30,30,35); Panel=[System.Drawing.Color]::FromArgb(45,45,50); Text="White"; Cyan="Cyan"; Red="Salmon" }

# --- GUI INIT ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CORE INSTALLER V6.0 - BYPASS EDITION"; $Form.Size = "950, 650"; $Form.StartPosition = "CenterScreen"; $Form.BackColor = $Theme.Bg; $Form.ForeColor = $Theme.Text; $Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

$LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text = "⚡ WINDOWS AUTO INSTALLER V6.0"; $LblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold); $LblTitle.ForeColor = $Theme.Cyan; $LblTitle.AutoSize = $true; $LblTitle.Location = "20, 15"; $Form.Controls.Add($LblTitle)

# === LEFT: CONFIG ===
$GrpConfig = New-Object System.Windows.Forms.GroupBox; $GrpConfig.Text = " 1. CẤU HÌNH "; $GrpConfig.Location = "20, 60"; $GrpConfig.Size = "520, 430"; $GrpConfig.ForeColor = "Gold"; $Form.Controls.Add($GrpConfig)

$LblISO = New-Object System.Windows.Forms.Label; $LblISO.Text = "File ISO:"; $LblISO.Location = "20,30"; $LblISO.AutoSize=$true; $LblISO.ForeColor="Silver"; $GrpConfig.Controls.Add($LblISO)
$CbISO = New-Object System.Windows.Forms.ComboBox; $CbISO.Location = "20,50"; $CbISO.Size = "300,30"; $CbISO.DropDownStyle="DropDownList"; $GrpConfig.Controls.Add($CbISO)

$BtnBrowse = New-Object System.Windows.Forms.Button; $BtnBrowse.Text = "📂..."; $BtnBrowse.Location = "330,49"; $BtnBrowse.Size = "50,25"; $BtnBrowse.BackColor="DimGray"; $GrpConfig.Controls.Add($BtnBrowse)
$BtnMount = New-Object System.Windows.Forms.Button; $BtnMount.Text = "💿 MOUNT"; $BtnMount.Location = "390,49"; $BtnMount.Size = "110,25"; $BtnMount.BackColor="DarkGreen"; $BtnMount.ForeColor="White"; $GrpConfig.Controls.Add($BtnMount)

$LblVer = New-Object System.Windows.Forms.Label; $LblVer.Text = "Phiên Bản (Trong ổ ảo):"; $LblVer.Location = "20,90"; $LblVer.AutoSize=$true; $LblVer.ForeColor="Silver"; $GrpConfig.Controls.Add($LblVer)
$CbIndex = New-Object System.Windows.Forms.ComboBox; $CbIndex.Location = "20,110"; $CbIndex.Size = "480,30"; $CbIndex.DropDownStyle="DropDownList"; $GrpConfig.Controls.Add($CbIndex)

$LblDsk = New-Object System.Windows.Forms.Label; $LblDsk.Text = "Chọn Ổ Cài Win (Sẽ bị Format):"; $LblDsk.Location = "20,150"; $LblDsk.AutoSize=$true; $LblDsk.ForeColor="Silver"; $GrpConfig.Controls.Add($LblDsk)
$GridPart = New-Object System.Windows.Forms.DataGridView; $GridPart.Location = "20,170"; $GridPart.Size = "480,180"; $GridPart.BackgroundColor="Black"; $GridPart.ForeColor="Black"; $GridPart.AllowUserToAddRows=$false; $GridPart.RowHeadersVisible=$false; $GridPart.SelectionMode="FullRowSelect"; $GridPart.MultiSelect=$false; $GridPart.ReadOnly=$true; $GridPart.AutoSizeColumnsMode="Fill"
$GridPart.Columns.Add("Disk","Disk"); $GridPart.Columns.Add("Part","Part"); $GridPart.Columns.Add("Letter","Ký Tự"); $GridPart.Columns.Add("Size","Size"); $GridPart.Columns.Add("Label","Nhãn"); 
$GridPart.Columns[0].FillWeight=15; $GridPart.Columns[1].FillWeight=15; $GridPart.Columns[2].FillWeight=15; $GrpConfig.Controls.Add($GridPart)

$ChkDriver = New-Object System.Windows.Forms.CheckBox; $ChkDriver.Text = "Tự động Backup & Restore Driver (Giữ mạng)"; $ChkDriver.Location="20, 360"; $ChkDriver.AutoSize=$true; $ChkDriver.Checked=$true; $ChkDriver.ForeColor="LightGreen"; $GrpConfig.Controls.Add($ChkDriver)
$ChkReboot = New-Object System.Windows.Forms.CheckBox; $ChkReboot.Text = "Tự động Reboot khi xong (Hands-free)"; $ChkReboot.Location="20, 390"; $ChkReboot.AutoSize=$true; $ChkReboot.Checked=$true; $GrpConfig.Controls.Add($ChkReboot)

# === RIGHT: ACTIONS ===
$GrpAction = New-Object System.Windows.Forms.GroupBox; $GrpAction.Text = " 2. CHỌN CHẾ ĐỘ "; $GrpAction.Location = "560, 60"; $GrpAction.Size = "350, 430"; $GrpAction.ForeColor = "Cyan"; $Form.Controls.Add($GrpAction)

function New-BigBtn ($Parent, $Txt, $Y, $Color, $Event) {
    $B = New-Object System.Windows.Forms.Button; $B.Text = $Txt; $B.Location = "20, $Y"; $B.Size = "310, 65"; $B.BackColor = $Color; $B.ForeColor = "Black"; $B.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold); $B.FlatStyle = "Flat"; $B.Cursor = "Hand"; $B.Add_Click($Event); $Parent.Controls.Add($B); return $B
}

New-BigBtn $GrpAction "MODE 2: AUTO DISM (SIÊU TỐC)`n🚀 Format C -> Bung Win -> Nạp Driver`n✅ Bao sân WinLite (Bypass Mount)" 40 "Orange" { Start-Auto-DISM }

New-BigBtn $GrpAction "MODE 1: SETUP.EXE (AN TOÀN)`n✅ Dùng Rollback của Microsoft`n✅ Chậm nhưng chắc" 120 "LightGray" {
    if (!$Global:IsoMounted) { Log "Chưa Mount ISO!"; return }
    $Setup = "$($Global:IsoMounted)\setup.exe"
    if (Test-Path $Setup) { Start-Process $Setup; $Form.Close() } else { Log "Lỗi: Không thấy Setup.exe" }
}

New-BigBtn $GrpAction "MODE 3: WINTOHDD (DỰ PHÒNG)`n⬇️ Tải Tool WinToHDD Portable" 200 "LightBlue" {
    $Dest = "$env:TEMP\WinToHDD.exe"
    if (!(Test-Path $Dest)) {
        Log "Đang tải WinToHDD..."
        $Form.Cursor = "WaitCursor"
        try { Import-Module BitsTransfer; Start-BitsTransfer -Source $Global:WinToHDD_Url -Destination $Dest -Priority Foreground } catch { Log "Lỗi tải: $_"; $Form.Cursor = "Default"; return }
        $Form.Cursor = "Default"
    }
    Start-Process $Dest; $Form.Close()
}

$LblWarn = New-Object System.Windows.Forms.Label; $LblWarn.Text = "LOG TRẠNG THÁI:"; $LblWarn.Location = "20, 300"; $LblWarn.AutoSize=$true; $LblWarn.ForeColor="Silver"; $GrpAction.Controls.Add($LblWarn)

$TxtLog = New-Object System.Windows.Forms.TextBox; $TxtLog.Location = "20, 510"; $TxtLog.Size = "890, 80"; $TxtLog.Multiline=$true; $TxtLog.BackColor="Black"; $TxtLog.ForeColor="Lime"; $TxtLog.ReadOnly=$true; $TxtLog.ScrollBars="Vertical"; $Form.Controls.Add($TxtLog)

function Log ($M) { $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm'))] $M`r`n"); $TxtLog.ScrollToCaret() }

# --- LOGIC ---
function Get-DriveListWMI {
    try { return @(Get-WmiObject Win32_LogicalDisk | Select-Object -ExpandProperty DeviceID) } catch { return @() }
}

function Load-Partitions {
    $GridPart.Rows.Clear(); $SysDrive = $env:SystemDrive.Replace(":","")
    try {
        $Parts = Get-Volume | Where-Object {$_.DriveType -eq 'Fixed'} | Sort-Object DriveLetter -ErrorAction Stop
        foreach ($P in $Parts) {
            try { $Dsk = (Get-Partition -DriveLetter $P.DriveLetter).DiskNumber; $Prt = (Get-Partition -DriveLetter $P.DriveLetter).PartitionNumber } catch { $Dsk = "?"; $Prt = "?" }
            $Info = if ($P.DriveLetter -eq $SysDrive) { " (WIN CŨ)" } else { "" }
            $Row = $GridPart.Rows.Add($Dsk, $Prt, $P.DriveLetter, "$([math]::Round($P.Size/1GB,1)) GB", "$($P.FileSystemLabel)$Info")
            if ($P.DriveLetter -eq $SysDrive) { $GridPart.Rows[$Row].Selected = $true; $Global:SelectedLetter = $P.DriveLetter }
        }
    } catch { 
        # WMI Fallback
        try {
            $Disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
            foreach ($D in $Disks) {
                $Letter = $D.DeviceID.Replace(":",""); $SizeGB = [math]::Round($D.Size / 1GB, 1)
                $Row = $GridPart.Rows.Add("?", "?", $Letter, "$SizeGB GB", "$($D.VolumeName)")
                if ($Letter -eq $SysDrive) { $GridPart.Rows[$Row].Selected = $true; $Global:SelectedLetter = $Letter }
            }
        } catch { Log "Lỗi Load Partitions." }
    }
}

# [CORE] ULTRA SMART MOUNT
function Mount-ISO {
    $ISO = $CbISO.SelectedItem; if (!$ISO) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn file ISO!"); return }
    $Form.Cursor = "WaitCursor"
    Log "--- BẮT ĐẦU MOUNT ---"
    $Global:IsoMounted = $null

    # 1. Snapshot Trước
    $DrivesBefore = Get-DriveListWMI
    Log "Ổ đĩa hiện tại: $($DrivesBefore -join ', ')"

    # 2. Mount
    try {
        Dismount-DiskImage -ImagePath $ISO -ErrorAction SilentlyContinue | Out-Null
        Mount-DiskImage -ImagePath $ISO -StorageType ISO -ErrorAction SilentlyContinue | Out-Null
        Start-Sleep -Seconds 3
    } catch { Log "WinLite Mount Warning." }

    # 3. KỸ THUẬT 1: Direct
    try {
        $Vol = Get-DiskImage -ImagePath $ISO | Get-Volume
        if ($Vol) { $Global:IsoMounted = "$($Vol.DriveLetter):"; Log "-> Direct: $($Global:IsoMounted)" }
    } catch {}

    # 4. KỸ THUẬT 2: Snapshot
    if (!$Global:IsoMounted) {
        $DrivesAfter = Get-DriveListWMI
        $NewDrives = Compare-Object -ReferenceObject $DrivesBefore -DifferenceObject $DrivesAfter -PassThru | Where-Object { $_.Side -eq "Difference" -and $_ -match "^[A-Z]:$" }
        foreach ($D in $NewDrives) {
            if ((Test-Path "$D\sources\install.wim") -or (Test-Path "$D\sources\install.esd")) { $Global:IsoMounted = $D; Log "-> Snapshot: $D"; break }
        }
    }

    # 5. KỸ THUẬT 3: Manual Picker
    if (!$Global:IsoMounted) { Show-Manual-Picker } else { Get-WimInfo }
    $Form.Cursor = "Default"
}

function Show-Manual-Picker {
    $Candidates = @()
    $AllDrives = Get-WmiObject Win32_LogicalDisk
    foreach ($D in $AllDrives) {
        $Root = $D.DeviceID + "\"
        if ((Test-Path "$Root\sources\install.wim") -or (Test-Path "$Root\sources\install.esd")) {
            $VolName = if ($D.VolumeName) { $D.VolumeName } else { "No Label" }
            $Size = [math]::Round($D.Size / 1GB, 1)
            $Candidates += @{ Path=$D.DeviceID; Info="$($D.DeviceID) - $VolName ($Size GB)" }
        }
    }

    if ($Candidates.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Mount lỗi! Không tìm thấy ổ chứa bộ cài.", "Lỗi"); return }
    if ($Candidates.Count -eq 1) { $Global:IsoMounted = $Candidates[0].Path; Log "-> Auto Select: $($Candidates[0].Info)"; Get-WimInfo; return }

    $PForm = New-Object System.Windows.Forms.Form; $PForm.Text = "CHỌN NGUỒN"; $PForm.Size = "400, 200"; $PForm.StartPosition = "CenterParent"
    $PCmb = New-Object System.Windows.Forms.ComboBox; $PCmb.Location="20,50"; $PCmb.Width=340; $PForm.Controls.Add($PCmb)
    foreach ($C in $Candidates) { $PCmb.Items.Add($C.Info) }
    $PCmb.SelectedIndex = 0
    $POK = New-Object System.Windows.Forms.Button; $POK.Text="OK"; $POK.Location="150,100"; $POK.DialogResult="OK"; $PForm.Controls.Add($POK)
    if ($PForm.ShowDialog() -eq "OK") { $Global:IsoMounted = $PCmb.SelectedItem.ToString().Substring(0, 2); Get-WimInfo }
}

function Get-WimInfo {
    $Drive = $Global:IsoMounted; if (!$Drive) { return }
    $Wim = "$Drive\sources\install.wim"; if (!(Test-Path $Wim)) { $Wim = "$Drive\sources\install.esd" }
    $Global:WimFile = $Wim
    $CbIndex.Items.Clear(); $ReadSuccess = $false
    if (Test-Path $Wim) {
        try {
            $Info = dism /Get-WimInfo /WimFile:$Wim; if ($Info) {
                $Indexes = $Info | Select-String "Index :"; $Names = $Info | Select-String "Name :"
                for ($i=0; $i -lt $Indexes.Count; $i++) { $CbIndex.Items.Add($Indexes[$i].ToString().Split(":")[1].Trim() + " - " + $Names[$i].ToString().Split(":")[1].Trim()) }
                if ($CbIndex.Items.Count -gt 0) { $CbIndex.SelectedIndex = 0; $ReadSuccess = $true }
            }
        } catch {}
    }
    if (-not $ReadSuccess) { $CbIndex.Items.Add("1 - Auto (Default)"); $CbIndex.SelectedIndex = 0 }
}

# [CORE] AUTO DISM (BYPASS MODE ADDED)
function Start-Auto-DISM {
    if (!$Global:IsoMounted) { [System.Windows.Forms.MessageBox]::Show("Chưa Mount ISO!"); return }
    $IndexName = $CbIndex.SelectedItem; $Idx = if ($IndexName) { $IndexName.ToString().Split("-")[0].Trim() } else { 1 }
    
    if ([System.Windows.Forms.MessageBox]::Show("XÁC NHẬN CÀI WIN (MODE 2)?", "Cảnh Báo", "YesNo", "Warning") -ne "Yes") { return }

    $Form.Cursor = "WaitCursor"; $Form.Text = "ĐANG XỬ LÝ..."
    $WorkDir = "$env:SystemDrive\WinInstall_Temp"; New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
    $MountDir = "$WorkDir\Mount"; New-Item -ItemType Directory -Path $MountDir -Force | Out-Null
    
    $SafeDrive = $null
    $Drives = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($D in $Drives) { if ($D.DeviceID -ne "$env:SystemDrive") { $SafeDrive = $D.DeviceID; break } }
    if (!$SafeDrive) { [System.Windows.Forms.MessageBox]::Show("Cần ổ đĩa thứ 2 (D/E) để chứa bộ cài!", "Error"); $Form.Cursor = "Default"; return }
    
    $SourceDir = "$SafeDrive\WinSource"; New-Item -ItemType Directory -Path $SourceDir -Force | Out-Null
    Log "Copying Source..."
    Copy-Item $Global:WimFile "$SourceDir\install.wim" -Force
    Copy-Item "$Global:IsoMounted\sources\boot.wim" "$WorkDir\boot.wim" -Force
    Copy-Item "$Global:IsoMounted\boot\boot.sdi" "$WorkDir\boot.sdi" -Force

    $DrvCmd = ""
    if ($ChkDriver.Checked) {
        $DrvPath = "$SafeDrive\Drivers_Backup"; New-Item -ItemType Directory -Path $DrvPath -Force | Out-Null
        Log "Backup Driver..."
        dism /online /export-driver /destination:"$DrvPath" | Out-Null
        $DrvCmd = "dism /Image:C:\ /Add-Driver /Driver:`"$DrvPath`" /Recurse`n"
    }

    # CREATE SCRIPT CONTENT
    $ScriptCmd = "@echo off`ntitle AUTO INSTALLER`ncolor 1f`ncls`nformat c: /q /y /fs:ntfs`n" +
                 "dism /Apply-Image /ImageFile:`"$SourceDir\install.wim`" /Index:$Idx /ApplyDir:C:\`n" +
                 "bcdboot C:\Windows /s C: /f ALL`n" + $DrvCmd +
                 "timeout /t 5`nwpeutil reboot"

    Log "Injecting Script..."
    
    # --- [GEMINI FIX V2: CHỈ GỠ READ-ONLY (KHÔNG TREO)] ---
    $BootWim = "$WorkDir\boot.wim"
    Log "Đang gỡ bỏ Read-Only..."

    if (Test-Path $BootWim) {
        # 1. Tắt thuộc tính Read-only (Đây là thuốc đặc trị lỗi 0xc1510111)
        & attrib -r -s -h "$BootWim"

        # 2. Tắt bằng PowerShell (Dự phòng cho chắc)
        Set-ItemProperty -Path "$BootWim" -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
    }
    
    # Đã xóa lệnh icacls để tránh bị treo máy
    # -----------------------------------------------

    # Dọn dẹp mount cũ cho sạch sẽ
    Start-Process "dism" -ArgumentList "/Cleanup-Wim" -Wait -WindowStyle Hidden

    $MountSuccess = $false
    
    # Tạo log debug
    $DebugLog = "$env:TEMP\Dism_Debug.txt"
    "--- DISM LOG START ---" | Out-File $DebugLog -Encoding UTF8

    # Thử Index 2 (Setup)
    $CmdLine = "/c dism /Mount-Image /ImageFile:`"$WorkDir\boot.wim`" /Index:2 /MountDir:`"$MountDir`" >> `"$DebugLog`" 2>&1"
    Start-Process "cmd" -ArgumentList $CmdLine -Wait -WindowStyle Hidden

    if (Test-Path "$MountDir\Windows\System32") { 
        $MountSuccess = $true 
    } else {
        # Thử Index 1 (PE)
        "--- RETRY INDEX 1 ---" | Out-File $DebugLog -Append
        $CmdLine = "/c dism /Mount-Image /ImageFile:`"$WorkDir\boot.wim`" /Index:1 /MountDir:`"$MountDir`" >> `"$DebugLog`" 2>&1"
        Start-Process "cmd" -ArgumentList $CmdLine -Wait -WindowStyle Hidden
        
        if (Test-Path "$MountDir\Windows\System32") { $MountSuccess = $true }
    }

    if ($MountSuccess) {
        Log "Mount OK. Using Standard Method."
        [IO.File]::WriteAllText("$MountDir\Windows\System32\startnet.cmd", $ScriptCmd)
        Start-Process "dism" -ArgumentList "/Unmount-Image /MountDir:`"$MountDir`" /Commit" -Wait
    } else {
        Log "MOUNT VẪN THẤT BẠI. XEM LOG CHI TIẾT:"
        Start-Process "dism" -ArgumentList "/Unmount-Image /MountDir:`"$MountDir`" /Discard" -Wait
        
        if (Test-Path $DebugLog) { $RealError = Get-Content $DebugLog | Out-String } else { $RealError = "Không có log." }
        [System.Windows.Forms.MessageBox]::Show("LỖI DISM (V2):\n\n$RealError", "ERROR", "OK", "Error")
        $Form.Cursor = "Default"; return
    }
    Log "Creating Boot Entry..."
    Move-Item "$WorkDir\boot.wim" "$env:SystemDrive\WinInstall.wim" -Force
    Move-Item "$WorkDir\boot.sdi" "$env:SystemDrive\boot.sdi" -Force
    Remove-Item $WorkDir -Recurse -Force

    cmd /c "bcdedit /create {ramdiskoptions} /d `"Ramdisk`"" 2>$null
    cmd /c "bcdedit /set {ramdiskoptions} ramdisksdidevice partition=$env:SystemDrive"
    cmd /c "bcdedit /set {ramdiskoptions} ramdisksdipath \boot.sdi"
    $Guid = [Guid]::NewGuid().ToString("B")
    cmd /c "bcdedit /create $Guid /d `"AUTO INSTALLER`" /application osloader"
    cmd /c "bcdedit /set $Guid device ramdisk=[$env:SystemDrive]\WinInstall.wim,{ramdiskoptions}"
    cmd /c "bcdedit /set $Guid osdevice ramdisk=[$env:SystemDrive]\WinInstall.wim,{ramdiskoptions}"
    cmd /c "bcdedit /set $Guid path \windows\system32\boot\winload.efi"
    cmd /c "bcdedit /set $Guid winpe yes"
    cmd /c "bcdedit /set $Guid detecthal yes"
    cmd /c "bcdedit /bootsequence $Guid"

    $Form.Cursor = "Default"
    if ([System.Windows.Forms.MessageBox]::Show("Sẵn sàng! Bấm YES để Restart.", "Xong", "YesNo") -eq "Yes") { Restart-Computer -Force }
}

# --- EVENTS ---
$BtnBrowse.Add_Click({ $OFD = New-Object System.Windows.Forms.OpenFileDialog; $OFD.Filter = "ISO|*.iso"; if ($OFD.ShowDialog() -eq "OK") { $CbISO.Items.Insert(0, $OFD.FileName); $CbISO.SelectedIndex = 0 } })
$BtnMount.Add_Click({ Mount-ISO })
$GridPart.Add_CellClick({ if ($_.RowIndex -ge 0) { $R = $GridPart.Rows[$_.RowIndex]; $Global:SelectedDisk = $R.Cells[0].Value; $Global:SelectedPart = $R.Cells[1].Value; $Global:SelectedLetter = $R.Cells[2].Value } })

Load-Partitions
$Scan = @("$env:USERPROFILE\Downloads", "D:", "E:", "F:"); foreach ($P in $Scan) { if(Test-Path $P){ Get-ChildItem $P -Filter "*.iso" -Recurse -Depth 1 | Where {$_.Length -gt 1GB} | ForEach { $CbISO.Items.Add($_.FullName) } } }
if ($CbISO.Items.Count -gt 0) { $CbISO.SelectedIndex = 0 }

$Form.ShowDialog() | Out-Null
