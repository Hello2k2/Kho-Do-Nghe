<#
    WININSTALL CORE V5.0 (AUTOMATION EDITION)
    Author: Phat Tan PC
    Features: 
    - Mode 2: Auto Format + Install + Restore Drivers (Native DISM).
    - Mode 1: Setup.exe (Fallback).
    - Mode 3: WinToHDD (Optional).
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

# --- THEME (Dark) ---
$Theme = @{ Bg=[System.Drawing.Color]::FromArgb(30,30,35); Panel=[System.Drawing.Color]::FromArgb(45,45,50); Text="White"; Cyan="Cyan"; Red="Salmon" }

# --- GUI INIT ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CORE INSTALLER V5.0 - AUTOMATION EDITION"; $Form.Size = "950, 650"; $Form.StartPosition = "CenterScreen"; $Form.BackColor = $Theme.Bg; $Form.ForeColor = $Theme.Text; $Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

$LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text = "⚡ WINDOWS AUTO INSTALLER V5.0"; $LblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold); $LblTitle.ForeColor = $Theme.Cyan; $LblTitle.AutoSize = $true; $LblTitle.Location = "20, 15"; $Form.Controls.Add($LblTitle)

# === LEFT: CONFIG ===
$GrpConfig = New-Object System.Windows.Forms.GroupBox; $GrpConfig.Text = " 1. CẤU HÌNH "; $GrpConfig.Location = "20, 60"; $GrpConfig.Size = "520, 430"; $GrpConfig.ForeColor = "Gold"; $Form.Controls.Add($GrpConfig)

$LblISO = New-Object System.Windows.Forms.Label; $LblISO.Text = "File ISO:"; $LblISO.Location = "20,30"; $LblISO.AutoSize=$true; $LblISO.ForeColor="Silver"; $GrpConfig.Controls.Add($LblISO)
$CbISO = New-Object System.Windows.Forms.ComboBox; $CbISO.Location = "20,50"; $CbISO.Size = "380,30"; $CbISO.DropDownStyle="DropDownList"; $GrpConfig.Controls.Add($CbISO)
$BtnBrowse = New-Object System.Windows.Forms.Button; $BtnBrowse.Text = "📂..."; $BtnBrowse.Location = "410,49"; $BtnBrowse.Size = "90,25"; $BtnBrowse.BackColor="DimGray"; $GrpConfig.Controls.Add($BtnBrowse)

$LblVer = New-Object System.Windows.Forms.Label; $LblVer.Text = "Phiên Bản:"; $LblVer.Location = "20,90"; $LblVer.AutoSize=$true; $LblVer.ForeColor="Silver"; $GrpConfig.Controls.Add($LblVer)
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

# Mode 2 (Main Star)
New-BigBtn $GrpAction "MODE 2: AUTO DISM (SIÊU TỐC)`n🚀 Format C -> Bung Win -> Nạp Driver`n✅ Nhanh hơn Setup.exe 3 lần" 40 "Orange" { Start-Auto-DISM }

# Mode 1
New-BigBtn $GrpAction "MODE 1: SETUP.EXE (AN TOÀN)`n✅ Dùng Rollback của Microsoft`n✅ Chậm nhưng chắc" 120 "LightGray" {
    if (!$Global:IsoMounted) { Log "Chưa Mount ISO!"; return }
    $Setup = "$($Global:IsoMounted)\setup.exe"
    if (Test-Path $Setup) { Start-Process $Setup; $Form.Close() } else { Log "Lỗi: Không thấy Setup.exe" }
}

# Mode 3
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

$LblWarn = New-Object System.Windows.Forms.Label; $LblWarn.Text = "LƯU Ý KHI DÙNG MODE 2:`n- Máy sẽ TỰ ĐỘNG KHỞI ĐỘNG LẠI.`n- Mất kết nối Remote (TeamViewer) tạm thời.`n- Sẽ tự vào lại Win mới sau 10-15p."; $LblWarn.Location = "20, 300"; $LblWarn.Size = "310, 100"; $LblWarn.ForeColor="Salmon"; $GrpAction.Controls.Add($LblWarn)

# --- LOG BOX ---
$TxtLog = New-Object System.Windows.Forms.TextBox; $TxtLog.Location = "20, 510"; $TxtLog.Size = "890, 80"; $TxtLog.Multiline=$true; $TxtLog.BackColor="Black"; $TxtLog.ForeColor="Lime"; $TxtLog.ReadOnly=$true; $TxtLog.ScrollBars="Vertical"; $Form.Controls.Add($TxtLog)

# --- LOGIC FUNCTIONS ---
function Log ($M) { $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm'))] $M`r`n"); $TxtLog.ScrollToCaret() }

function Load-Partitions {
    $GridPart.Rows.Clear(); $SysDrive = $env:SystemDrive.Replace(":","")
    try {
        $Parts = Get-Volume | Where-Object {$_.DriveType -eq 'Fixed'} | Sort-Object DriveLetter
        foreach ($P in $Parts) {
            $Dsk = (Get-Partition -DriveLetter $P.DriveLetter).DiskNumber
            $Prt = (Get-Partition -DriveLetter $P.DriveLetter).PartitionNumber
            $Info = if ($P.DriveLetter -eq $SysDrive) { " (WIN CŨ)" } else { "" }
            $Row = $GridPart.Rows.Add($Dsk, $Prt, $P.DriveLetter, "$([math]::Round($P.Size/1GB,1)) GB", "$($P.FileSystemLabel)$Info")
            if ($P.DriveLetter -eq $SysDrive) { $GridPart.Rows[$Row].Selected = $true; $Global:SelectedLetter = $P.DriveLetter }
        }
    } catch { Log "Lỗi đọc phân vùng." }
}

function Mount-ISO {
    $ISO = $CbISO.SelectedItem; if (!$ISO) { return }
    Log "Mounting: $ISO..."
    try {
        Dismount-DiskImage -ImagePath $ISO -ErrorAction SilentlyContinue | Out-Null
        $M = Mount-DiskImage -ImagePath $ISO -PassThru; $Vol = $M | Get-Volume
        if ($Vol) { $Global:IsoMounted = "$($Vol.DriveLetter):"; Log "-> Mounted: $($Global:IsoMounted)"; Get-WimInfo }
    } catch { Log "Lỗi Mount: $_" }
}

function Get-WimInfo {
    $Drive = $Global:IsoMounted; if (!$Drive) { return }
    $Wim = "$Drive\sources\install.wim"; if (!(Test-Path $Wim)) { $Wim = "$Drive\sources\install.esd" }
    $CbIndex.Items.Clear()
    if (Test-Path $Wim) {
        $Info = dism /Get-WimInfo /WimFile:$Wim; $Indexes = $Info | Select-String "Index :"; $Names = $Info | Select-String "Name :"
        for ($i=0; $i -lt $Indexes.Count; $i++) { $Idx = $Indexes[$i].ToString().Split(":")[1].Trim(); $Nam = $Names[$i].ToString().Split(":")[1].Trim(); $CbIndex.Items.Add("$Idx - $Nam") }
        if ($CbIndex.Items.Count -gt 0) { $CbIndex.SelectedIndex = 0 }
    }
}

# === CORE: START AUTO DISM ===
function Start-Auto-DISM {
    # 1. Validation
    if (!$Global:IsoMounted) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn file ISO!"); return }
    $IndexName = $CbIndex.SelectedItem; $Idx = if ($IndexName) { $IndexName.ToString().Split("-")[0].Trim() } else { 1 }
    
    # 2. Confirm
    if ([System.Windows.Forms.MessageBox]::Show("XÁC NHẬN CÀI WIN TỰ ĐỘNG (MODE 2)?`n`n- Ổ C sẽ bị FORMAT sạch.`n- Máy sẽ tự khởi động lại.`n- Driver sẽ được tự động nạp lại.`n`nBẠN CHẮC CHẮN CHỨ?", "CẢNH BÁO CUỐI", "YesNo", "Warning") -ne "Yes") { return }

    # 3. Prepare Environment
    $Form.Cursor = "WaitCursor"; $Form.Text = "ĐANG CHUẨN BỊ (KHÔNG TẮT)..."
    $WorkDir = "$env:SystemDrive\WinInstall_Temp"; New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
    $MountDir = "$WorkDir\Mount"; New-Item -ItemType Directory -Path $MountDir -Force | Out-Null
    
    # 4. Find Safe Place for Source (Not C:)
    $SafeDrives = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter -ne $env:SystemDrive.Replace(":","") -and $_.DriveLetter -ne $null }
    if ($SafeDrives) { $SafeDrive = "$($SafeDrives[0].DriveLetter):" } else { 
        [System.Windows.Forms.MessageBox]::Show("LỖI: Cần ít nhất 2 ổ đĩa (C và D/E) để chứa bộ cài.`nMáy này chỉ có 1 ổ C.", "Error"); $Form.Cursor = "Default"; return 
    }
    
    $SourceDir = "$SafeDrive\WinSource"; New-Item -ItemType Directory -Path $SourceDir -Force | Out-Null
    Log "Lưu bộ cài tại: $SourceDir"

    # 5. Copy Files
    $WimSrc = "$Global:IsoMounted\sources\install.wim"; if (!(Test-Path $WimSrc)) { $WimSrc = "$Global:IsoMounted\sources\install.esd" }
    Log "Copying Install Image (Có thể lâu)..."
    Copy-Item $WimSrc "$SourceDir\install.wim" -Force
    Copy-Item "$Global:IsoMounted\sources\boot.wim" "$WorkDir\boot.wim" -Force
    Copy-Item "$Global:IsoMounted\boot\boot.sdi" "$WorkDir\boot.sdi" -Force

    # 6. Backup Drivers (Crucial Step)
    if ($ChkDriver.Checked) {
        Log "Đang Backup Driver (Để giữ mạng)..."
        $DrvPath = "$SafeDrive\Drivers_Backup"; New-Item -ItemType Directory -Path $DrvPath -Force | Out-Null
        dism /online /export-driver /destination:"$DrvPath" | Out-Null
    }

    # 7. Inject Auto-Script into boot.wim
    Log "Mount Boot.wim..."
    Start-Process "dism" -ArgumentList "/Mount-Image /ImageFile:`"$WorkDir\boot.wim`" /Index:2 /MountDir:`"$MountDir`"" -Wait
    
    # Create the Magic Script (startnet.cmd)
    $Cmd = "@echo off`n" +
           "title PHAT TAN PC - AUTO INSTALLER`n" +
           "color 1f`ncls`n" +
           "echo =========================================`n" +
           "echo      DANG CAI WIN - VUI LONG DOI...`n" +
           "echo =========================================`n" +
           "echo 1. Format O C...`n" +
           "format c: /q /y /fs:ntfs`n" +
           "echo 2. Bung File Win (Index $Idx)...`n" +
           "dism /Apply-Image /ImageFile:`"$SourceDir\install.wim`" /Index:$Idx /ApplyDir:C:\`n" +
           "echo 3. Tao Boot Loader...`n" +
           "bcdboot C:\Windows /s C: /f ALL`n"
    
    if ($ChkDriver.Checked) {
        $Cmd += "echo 4. Nap lai Drivers (Network/Audio)...`n" +
                "dism /Image:C:\ /Add-Driver /Driver:`"$DrvPath`" /Recurse`n"
    }
    
    if ($ChkReboot.Checked) {
        $Cmd += "echo 5. XONG! Khoi dong lai sau 5s...`n" +
                "timeout /t 5`nwpeutil reboot`n"
    } else { $Cmd += "echo DA XONG. Hay tu khoi dong lai.`npause`n" }

    [IO.File]::WriteAllText("$MountDir\Windows\System32\startnet.cmd", $Cmd)

    Log "Unmount & Save Boot..."
    Start-Process "dism" -ArgumentList "/Unmount-Image /MountDir:`"$MountDir`" /Commit" -Wait

    # 8. Create Ramdisk Boot Entry
    Log "Tạo Menu Boot..."
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
    if ([System.Windows.Forms.MessageBox]::Show("Đã xong! Bấm YES để Restart và Cài ngay.", "Thành Công", "YesNo") -eq "Yes") {
        Restart-Computer -Force
    }
}

# --- EVENTS ---
$BtnBrowse.Add_Click({ $OFD = New-Object System.Windows.Forms.OpenFileDialog; $OFD.Filter = "ISO|*.iso"; if ($OFD.ShowDialog() -eq "OK") { $CbISO.Items.Insert(0, $OFD.FileName); $CbISO.SelectedIndex = 0; Mount-ISO } })
$GridPart.Add_CellClick({ $R = $GridPart.SelectedRows[0]; $Global:SelectedDisk = $R.Cells[0].Value; $Global:SelectedPart = $R.Cells[1].Value; $Global:SelectedLetter = $R.Cells[2].Value })

# --- STARTUP ---
Load-Partitions
$Scan = @("$env:USERPROFILE\Downloads", "D:", "E:", "F:"); foreach ($P in $Scan) { if(Test-Path $P){ Get-ChildItem $P -Filter "*.iso" -Recurse -Depth 1 | Where {$_.Length -gt 1GB} | ForEach { $CbISO.Items.Add($_.FullName) } } }
if ($CbISO.Items.Count -gt 0) { $CbISO.SelectedIndex = 0; Mount-ISO }

$Form.ShowDialog() | Out-Null
