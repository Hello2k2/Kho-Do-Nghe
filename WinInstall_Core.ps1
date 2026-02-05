<#
  WININSTALL CORE V18.4 (SMART EFI/SYSTEM DETECT - TEMP LETTER ASSIGN BY VOLUME)
  Author: Phat Tan PC

  New:
  - Auto detect firmware: UEFI vs BIOS
  - Auto locate system volume via DISKPART list vol:
      * UEFI -> FAT32 + Info=System (prefer) + small size
      * BIOS -> NTFS + Info=System (prefer) + 50-600MB
  - Only assign TEMP letter when needed for bcdboot/bootsect
  - After rebuild boot, auto cleanup temp letter by VolumeNumber (no guessing S:)
  - WinPE RAMDISK entry uses [locate] to avoid drive-letter swap
#>

# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator"
)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# --- INIT ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$Global:SelectedInstall = $null
$Global:SelectedBoot    = $null
$Global:CustomXmlPath   = ""
$Global:IsoMounted      = $null
$Global:WimFile         = $null

# --- THEME ---
$Theme = @{
    Bg    = [System.Drawing.Color]::FromArgb(20,20,25)
    Panel = [System.Drawing.Color]::FromArgb(35,35,40)
    Text  = "White"
    Cyan  = "DeepSkyBlue"
    Red   = "Crimson"
}

# --- GUI ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CORE INSTALLER V18.4 (AUTO DETECT BOOT + REBUILD BCD)"
$Form.Size = "1000, 750"
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Bg
$Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

$LblTitle = New-Object System.Windows.Forms.Label
$LblTitle.Text = "🚀 WINDOWS ULTIMATE INSTALLER V18.4 (AUTO BOOT DETECT)"
$LblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$LblTitle.ForeColor = $Theme.Cyan
$LblTitle.AutoSize = $true
$LblTitle.Location = "20, 15"
$Form.Controls.Add($LblTitle)

# === 1. CONFIG ===
$GrpConfig = New-Object System.Windows.Forms.GroupBox
$GrpConfig.Text = " 1. THIẾT LẬP BỘ CÀI & DRIVE "
$GrpConfig.Location = "20, 70"
$GrpConfig.Size = "550, 520"
$GrpConfig.ForeColor = "Yellow"
$Form.Controls.Add($GrpConfig)

# ISO & Index
$BtnISO = New-Object System.Windows.Forms.Button
$BtnISO.Text = "📂 CHỌN ISO"
$BtnISO.Location = "20,30"
$BtnISO.Size = "120,30"
$BtnISO.BackColor="DimGray"
$GrpConfig.Controls.Add($BtnISO)

$TxtISO = New-Object System.Windows.Forms.TextBox
$TxtISO.Location = "150,32"
$TxtISO.Size = "260,25"
$TxtISO.ReadOnly=$true
$GrpConfig.Controls.Add($TxtISO)

$BtnMount = New-Object System.Windows.Forms.Button
$BtnMount.Text = "💿 MOUNT"
$BtnMount.Location = "420,30"
$BtnMount.Size = "110,30"
$BtnMount.BackColor="DarkGreen"
$GrpConfig.Controls.Add($BtnMount)

$LblVer = New-Object System.Windows.Forms.Label
$LblVer.Text = "Phiên Bản:"
$LblVer.Location = "20,70"
$LblVer.AutoSize=$true
$GrpConfig.Controls.Add($LblVer)

$CbIndex = New-Object System.Windows.Forms.ComboBox
$CbIndex.Location = "100,68"
$CbIndex.Size = "430,30"
$CbIndex.DropDownStyle="DropDownList"
$GrpConfig.Controls.Add($CbIndex)

# Partition Grid
$LblGrid = New-Object System.Windows.Forms.Label
$LblGrid.Text = "DANH SÁCH PHÂN VÙNG (Chuột phải để chọn Ổ CÀI / Ổ BOOT):"
$LblGrid.Location = "20,110"
$LblGrid.AutoSize=$true
$LblGrid.ForeColor="Silver"
$GrpConfig.Controls.Add($LblGrid)

$GridPart = New-Object System.Windows.Forms.DataGridView
$GridPart.Location = "20,135"
$GridPart.Size = "510,200"
$GridPart.BackgroundColor="Black"
$GridPart.ForeColor="Black"
$GridPart.RowHeadersVisible=$false
$GridPart.SelectionMode="FullRowSelect"
$GridPart.ReadOnly=$true
$GridPart.AutoSizeColumnsMode="Fill"
[void]$GridPart.Columns.Add("Dsk","D")
[void]$GridPart.Columns.Add("Prt","P")
[void]$GridPart.Columns.Add("Ltr","L")
[void]$GridPart.Columns.Add("Size","Size")
[void]$GridPart.Columns.Add("Role","Vai Trò")
$GrpConfig.Controls.Add($GridPart)

# Custom XML
$BtnXml = New-Object System.Windows.Forms.Button
$BtnXml.Text = "📄 Nạp Unattend.xml"
$BtnXml.Location = "20,350"
$BtnXml.Size = "150,30"
$BtnXml.BackColor="SteelBlue"
$GrpConfig.Controls.Add($BtnXml)

$TxtXml = New-Object System.Windows.Forms.TextBox
$TxtXml.Location = "180,352"
$TxtXml.Size = "350,25"
$TxtXml.ReadOnly=$true
$TxtXml.Text = "Mặc định (Auto)"
$GrpConfig.Controls.Add($TxtXml)

# === 2. OPTIONS ===
$GrpOption = New-Object System.Windows.Forms.GroupBox
$GrpOption.Text = " 2. OPTIMIZATION "
$GrpOption.Location = "590, 70"
$GrpOption.Size = "370, 280"
$GrpOption.ForeColor = "Lime"
$Form.Controls.Add($GrpOption)

$ChkReg = New-Object System.Windows.Forms.CheckBox
$ChkReg.Text = "Backup Registry Hives (An toàn)"
$ChkReg.Location="20, 30"
$ChkReg.AutoSize=$true
$ChkReg.Checked=$true
$GrpOption.Controls.Add($ChkReg)

$ChkGOS = New-Object System.Windows.Forms.CheckBox
$ChkGOS.Text = "Tắt Game Mode & Optimization (Tăng FPS)"
$ChkGOS.Location="20, 60"
$ChkGOS.AutoSize=$true
$ChkGOS.Checked=$true
$GrpOption.Controls.Add($ChkGOS)

$ChkWarn = New-Object System.Windows.Forms.CheckBox
$ChkWarn.Text = "Tắt thông báo Reboot (Cài xong tự Restart)"
$ChkWarn.Location="20, 90"
$ChkWarn.AutoSize=$true
$ChkWarn.Checked=$false
$GrpOption.Controls.Add($ChkWarn)

$ChkDriver = New-Object System.Windows.Forms.CheckBox
$ChkDriver.Text = "Auto Backup/Restore Driver"
$ChkDriver.Location="20, 120"
$ChkDriver.AutoSize=$true
$ChkDriver.Checked=$true
$GrpOption.Controls.Add($ChkDriver)

# === 3. ACTION ===
$GrpAction = New-Object System.Windows.Forms.GroupBox
$GrpAction.Text = " 3. EXECUTE "
$GrpAction.Location = "590, 360"
$GrpAction.Size = "370, 230"
$GrpAction.ForeColor = "Cyan"
$Form.Controls.Add($GrpAction)

function New-BigBtn ($Parent, $Txt, $Y, $Color, $Event) {
    $B = New-Object System.Windows.Forms.Button
    $B.Text = $Txt
    $B.Location = "20, $Y"
    $B.Size = "330, 60"
    $B.BackColor = $Color
    $B.ForeColor = "Black"
    $B.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $B.FlatStyle = "Flat"
    $B.Add_Click($Event)
    $Parent.Controls.Add($B)
}

# Log Box
$TxtLog = New-Object System.Windows.Forms.TextBox
$TxtLog.Location = "20, 610"
$TxtLog.Size = "945, 80"
$TxtLog.Multiline=$true
$TxtLog.BackColor="Black"
$TxtLog.ForeColor="Lime"
$TxtLog.ReadOnly=$true
$TxtLog.ScrollBars="Vertical"
$Form.Controls.Add($TxtLog)

function Log ($M) {
    $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm'))] $M`r`n")
    $TxtLog.ScrollToCaret()
}

# =========================
#   SMART CORE FUNCTIONS
# =========================

function Get-FirmwareMode {
    try {
        $fw = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "PEFirmwareType" -ErrorAction Stop).PEFirmwareType
        if ($fw -eq 2) { return "UEFI" }
        return "BIOS"
    } catch {
        return "BIOS"
    }
}

function Get-FreeDriveLetter {
    param([string]$Prefer = "S")

    $used = (Get-Volume -EA SilentlyContinue | Where-Object DriveLetter | Select-Object -Expand DriveLetter) 2>$null
    if (-not $used) { $used = @() }

    $Prefer = $Prefer.Trim().ToUpper()
    if ($Prefer -match '^[A-Z]$' -and ($used -notcontains $Prefer)) { return $Prefer }

    foreach ($c in @("S","T","R","V","W","U","Q","P","O","N","M","L","K","J","I","H","G","F","E","D","Y","X","Z")) {
        if ($used -notcontains $c) { return $c }
    }
    throw "Không còn drive letter trống để assign tạm!"
}

function Invoke-DiskpartAssignLetterByVolume {
    param(
        [Parameter(Mandatory=$true)][int]$VolumeNumber,
        [Parameter(Mandatory=$true)][string]$Letter
    )
    $tmp = Join-Path $env:TEMP ("dp_assign_{0}.txt" -f ([Guid]::NewGuid().ToString("N")))
@"
select volume $VolumeNumber
assign letter=$Letter
exit
"@ | Set-Content -Path $tmp -Encoding ASCII

    $out = & diskpart /s $tmp 2>&1
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    return $out
}

function Invoke-DiskpartRemoveAllLettersByVolume {
    param(
        [Parameter(Mandatory=$true)][int]$VolumeNumber
    )
    $tmp = Join-Path $env:TEMP ("dp_removeAll_{0}.txt" -f ([Guid]::NewGuid().ToString("N")))
@"
select volume $VolumeNumber
remove all
exit
"@ | Set-Content -Path $tmp -Encoding ASCII

    $out = & diskpart /s $tmp 2>&1
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    return $out
}

function Ensure-VolumeHasLetter {
    param(
        [Parameter(Mandatory=$true)][int]$VolumeNumber,
        [string]$Prefer = "S"
    )

    $dp = & diskpart /s (cmd /c "echo list vol&echo exit") 2>&1
    $lines = $dp -split "`r?`n" | Where-Object { $_ -match "Volume\s+$VolumeNumber\s+" }

    foreach ($ln in $lines) {
        if ($ln -match "Volume\s+$VolumeNumber\s+([A-Z])\s+") {
            $has = $matches[1]
            return @{ Letter = "${has}:"; WasAssigned = $false }
        }
    }

    $free = Get-FreeDriveLetter -Prefer $Prefer
    $assignOut = Invoke-DiskpartAssignLetterByVolume -VolumeNumber $VolumeNumber -Letter $free
    Log ("Assign temp ${free}: -> Volume $VolumeNumber => " + (($assignOut | Out-String).Trim()))

    return @{ Letter = "${free}:"; WasAssigned = $true }
}

function Get-SystemVolumeInfo {
    $mode = Get-FirmwareMode
    Log "Detect Firmware: $mode"

    $dp = & diskpart /s (cmd /c "echo list vol&echo exit") 2>&1
    $lines = $dp -split "`r?`n" | Where-Object { $_ -match '^\s*Volume\s+\d+' }

    if ($mode -eq "UEFI") {
        $candidates = @()
        foreach ($ln in $lines) {
            # UEFI EFI: FAT32 + small (50-600MB), prefer Info=System
            if ($ln -match 'Volume\s+(\d+)\s+([A-Z]?)\s+.*\s+FAT32\s+.*\s+(\d+)\s+MB\s+.*') {
                $num = [int]$matches[1]
                $ltr = $matches[2]
                $mb  = [int]$matches[3]
                if ($mb -ge 50 -and $mb -le 600) {
                    $isSystem = ($ln -match '\sSystem(\s|$)')
                    $candidates += [pscustomobject]@{ Num=$num; Ltr=$ltr; MB=$mb; IsSystem=$isSystem; Line=$ln }
                }
            }
        }

        $pick = $candidates | Sort-Object @{Expression="IsSystem"; Descending=$true}, @{Expression="MB"; Ascending=$true} | Select-Object -First 1
        if (-not $pick) { throw "Không tìm thấy EFI (FAT32)!" }

        $assign = Ensure-VolumeHasLetter -VolumeNumber $pick.Num -Prefer "S"
        return @{ Mode="UEFI"; VolumeNumber=$pick.Num; Letter=$assign.Letter; WasAssigned=$assign.WasAssigned }
    }
    else {
        $candidates = @()
        foreach ($ln in $lines) {
            # BIOS System Reserved: NTFS + small (50-600MB), prefer Info=System
            if ($ln -match 'Volume\s+(\d+)\s+([A-Z]?)\s+.*\s+NTFS\s+Partition\s+(\d+)\s+MB\s+.*') {
                $num = [int]$matches[1]
                $ltr = $matches[2]
                $mb  = [int]$matches[3]
                if ($mb -ge 50 -and $mb -le 600) {
                    $isSystem = ($ln -match '\sSystem(\s|$)')
                    $candidates += [pscustomobject]@{ Num=$num; Ltr=$ltr; MB=$mb; IsSystem=$isSystem; Line=$ln }
                }
            }
        }

        $pick = $candidates | Sort-Object @{Expression="IsSystem"; Descending=$true}, @{Expression="MB"; Ascending=$true} | Select-Object -First 1
        if (-not $pick) { throw "Không tìm thấy System Reserved (NTFS System)!" }

        $assign = Ensure-VolumeHasLetter -VolumeNumber $pick.Num -Prefer "S"
        return @{ Mode="BIOS"; VolumeNumber=$pick.Num; Letter=$assign.Letter; WasAssigned=$assign.WasAssigned }
    }
}

function Ensure-EntryInDisplayOrder {
    param([Parameter(Mandatory=$true)][string]$Guid)
    try { & bcdedit /displayorder $Guid /addfirst | Out-Null } catch {}
    try { & bcdedit /timeout 10 | Out-Null } catch {}
}

function Rebuild-SystemBoot {
    param([Parameter(Mandatory=$true)][string]$WindowsDrive)

    $sys = Get-SystemVolumeInfo
    Log "System Partition: Vol=$($sys.VolumeNumber) Letter=$($sys.Letter) Mode=$($sys.Mode) TempAssigned=$($sys.WasAssigned)"

    try {
        if ($sys.Mode -eq "UEFI") {
            $out = & bcdboot "$WindowsDrive\Windows" /s $sys.Letter /f UEFI 2>&1
            Log ("bcdboot UEFI => " + (($out | Out-String).Trim()))
        } else {
            try {
                $out1 = & bootsect /nt60 $sys.Letter /mbr 2>&1
                Log ("bootsect => " + (($out1 | Out-String).Trim()))
            } catch {
                Log "WARN: bootsect không chạy - vẫn tiếp tục bcdboot."
            }
            $out2 = & bcdboot "$WindowsDrive\Windows" /s $sys.Letter /f BIOS 2>&1
            Log ("bcdboot BIOS => " + (($out2 | Out-String).Trim()))
        }

        try { & bcdedit /timeout 10 | Out-Null } catch {}
    }
    finally {
        # Cleanup only if WE assigned temp letter
        if ($sys.WasAssigned -eq $true -and $sys.VolumeNumber -ne $null) {
            Log "Cleanup: remove temp mount from Volume $($sys.VolumeNumber)"
            $rm = Invoke-DiskpartRemoveAllLettersByVolume -VolumeNumber $sys.VolumeNumber
            Log ("Cleanup remove => " + (($rm | Out-String).Trim()))
        }
    }

    return $sys
}

# =========================
#   CORE LOGIC
# =========================

function Load-Partitions {
    $GridPart.Rows.Clear()
    try {
        $Drives = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
        foreach ($D in $Drives) {
            $Letter = $D.DeviceID.Replace(":","")
            $Row = $GridPart.Rows.Add("?", "?", $Letter, "$([math]::Round($D.Size/1GB,1)) GB", "Chưa chọn")

            if ($Letter -eq $env:SystemDrive.Replace(":","")) {
                $Global:SelectedInstall = $Letter
                $Global:SelectedBoot    = $Letter
                $GridPart.Rows[$Row].Cells[4].Value = "CÀI + BOOT (Mặc định)"
            }
        }
    } catch {
        Log "Lỗi quét phân vùng bằng WMI!"
    }
}

# Context Menu
$Cms = New-Object System.Windows.Forms.ContextMenuStrip
$miInstall = $Cms.Items.Add("Chọn làm Ổ CÀI WIN (Đích)")
$miBoot    = $Cms.Items.Add("Chọn làm Ổ BOOT (Nạp BCD)")

$miInstall.Add_Click({
    if ($GridPart.SelectedRows.Count -gt 0) {
        $L = $GridPart.SelectedRows[0].Cells[2].Value
        $Global:SelectedInstall = $L
        Log "Đã chọn ổ CÀI: $L"
        foreach($R in $GridPart.Rows){
            if($R.Cells[4].Value -match "CÀI"){
                $R.Cells[4].Value = $R.Cells[4].Value.Replace("CÀI","").Trim("- ")
            }
        }
        $GridPart.SelectedRows[0].Cells[4].Value = ($GridPart.SelectedRows[0].Cells[4].Value + " - CÀI").Trim("- ")
    }
})

$miBoot.Add_Click({
    if ($GridPart.SelectedRows.Count -gt 0) {
        $L = $GridPart.SelectedRows[0].Cells[2].Value
        $Global:SelectedBoot = $L
        Log "Đã chọn ổ BOOT: $L"
        foreach($R in $GridPart.Rows){
            if($R.Cells[4].Value -match "BOOT"){
                $R.Cells[4].Value = $R.Cells[4].Value.Replace("BOOT","").Trim("- ")
            }
        }
        $GridPart.SelectedRows[0].Cells[4].Value = ($GridPart.SelectedRows[0].Cells[4].Value + " - BOOT").Trim("- ")
    }
})
$GridPart.ContextMenuStrip = $Cms

function Start-Headless-DISM {
    if (!$Global:IsoMounted) { [System.Windows.Forms.MessageBox]::Show("Chưa Mount ISO!"); return }

    $InstallDrive = "$($Global:SelectedInstall):"
    if ([string]::IsNullOrWhiteSpace($Global:SelectedInstall)) {
        [System.Windows.Forms.MessageBox]::Show("Chưa chọn ổ CÀI!", "Lỗi"); return
    }

    # Pick source drive (not target) > 8GB free
    $SourceDrive = $null
    $Drives = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($D in $Drives) {
        if ($D.DeviceID -ne $InstallDrive -and $D.FreeSpace -gt 8GB) { $SourceDrive = $D.DeviceID; break }
    }
    if (!$SourceDrive) { [System.Windows.Forms.MessageBox]::Show("Cần 1 ổ phụ > 8GB (khác ổ cài)!", "Lỗi"); return }

    $Index = 1
    if ($CbIndex.Items.Count -gt 0 -and $CbIndex.SelectedIndex -ge 0) { $Index = $CbIndex.SelectedIndex + 1 }

    $Msg = "AUTO DETECT BOOT + REBUILD`nSource: $SourceDrive -> Target: $InstallDrive`nIndex: $Index`n`nTiếp tục?"
    if ([System.Windows.Forms.MessageBox]::Show($Msg, "Phat Tan PC", "YesNo", "Warning") -ne "Yes") { return }

    $Form.Cursor = "WaitCursor"
    Log "--- V18.4 START ---"

    # (A) Rebuild boot FIRST
    try {
        Log "Rebuilding System Boot (smart detect UEFI/BIOS + temp letter by volume)..."
        $sysInfo = Rebuild-SystemBoot -WindowsDrive $InstallDrive
        Log "Boot rebuild done."
    } catch {
        Log "WARN: Rebuild boot fail: $_"
    }

    # (B) Prepare WinSource folder
    $WinSource = "$SourceDrive\WinSource_PhatTan"
    Log "Prepare folder: $WinSource"
    try {
        if (Test-Path $WinSource) { Remove-Item $WinSource -Recurse -Force }
        New-Item -ItemType Directory -Path "$WinSource\sources" -Force | Out-Null
        New-Item -ItemType Directory -Path "$WinSource\boot" -Force | Out-Null
    } catch {
        Log "ERR: Không tạo được thư mục WinSource!"; $Form.Cursor="Default"; return
    }

    # Copy needed files
    Log "Copying boot.wim/boot.sdi/setup/install..."
    try {
        Copy-Item "$Global:IsoMounted\sources\boot.wim" "$WinSource\sources\boot.wim" -Force
        Copy-Item "$Global:IsoMounted\boot\boot.sdi" "$WinSource\boot\boot.sdi" -Force
        Copy-Item "$Global:IsoMounted\setup.exe" "$WinSource\setup.exe" -Force

        $InstWim = "$Global:IsoMounted\sources\install.wim"
        $IsESD = $false
        if (!(Test-Path $InstWim)) { $InstWim = "$Global:IsoMounted\sources\install.esd"; $IsESD = $true }

        if ($IsESD) {
            Copy-Item $InstWim "$WinSource\sources\install.esd" -Force
            $InstallImagePath = "%~dp0sources\install.esd"
        } else {
            Copy-Item $InstWim "$WinSource\sources\install.wim" -Force
            $InstallImagePath = "%~dp0sources\install.wim"
        }
    } catch {
        Log "ERR: Copy fail: $_"; $Form.Cursor="Default"; return
    }

    # Label target for WinPE detection
    try { cmd /c "label $InstallDrive WIN_TARGET" | Out-Null } catch {}

    # Write AutoInstall.cmd
    Log "Writing AutoInstall.cmd..."
    $CmdContent = @"
@echo off
title PHAT TAN V18.4 AUTO INSTALL
setlocal enabledelayedexpansion

for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
  vol %%d: 2>nul | find "WIN_TARGET" >nul && set TARGET=%%d:
)

if "%TARGET%"=="" (
  echo [ERR] Khong tim thay WIN_TARGET
  timeout /t 5 >nul
  exit /b 1
)

echo [OK] Target = %TARGET%
format %TARGET% /fs:ntfs /q /y /v:Windows

dism /Apply-Image /ImageFile:"$InstallImagePath" /Index:$Index /ApplyDir:%TARGET%

bcdboot %TARGET%\Windows /f ALL
wpeutil reboot
"@
    [IO.File]::WriteAllText("$WinSource\AutoInstall.cmd", $CmdContent, [System.Text.Encoding]::ASCII)

    # Write autounattend.xml
    Log "Writing autounattend.xml..."
    $XmlSmart = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
  <settings pass="windowsPE">
    <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <RunSynchronous>
        <RunSynchronousCommand wcm:action="add">
          <Order>1</Order>
          <Path>cmd /c for %%%%i in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist %%%%i:\WinSource_PhatTan\AutoInstall.cmd call %%%%i:\WinSource_PhatTan\AutoInstall.cmd</Path>
        </RunSynchronousCommand>
      </RunSynchronous>
    </component>
  </settings>
</unattend>
"@
    [IO.File]::WriteAllText("$WinSource\autounattend.xml", $XmlSmart, [System.Text.Encoding]::UTF8)

    # (C) Create WinPE RAMDISK BCD entry using [locate]
    Log "Configuring WinPE BCD (LOCATE)..."
    try {
        & bcdedit /create "{ramdiskoptions}" /d "Phat Tan Ramdisk" /f | Out-Null
        & bcdedit /set "{ramdiskoptions}" ramdisksdidevice locate | Out-Null
        & bcdedit /set "{ramdiskoptions}" ramdisksdipath "\WinSource_PhatTan\boot\boot.sdi" | Out-Null

        $BcdOutput = & bcdedit /create /d "PHAT TAN INSTALLER (V18.4 - LOCATE)" /application osloader
        $Guid = ([regex]'{[a-z0-9-]{36}}').Match($BcdOutput).Value
        if (!$Guid) { throw "Không lấy được GUID" }

        $DeviceStr = "ramdisk=[locate]\WinSource_PhatTan\sources\boot.wim,{ramdiskoptions}"
        & bcdedit /set $Guid device $DeviceStr | Out-Null
        & bcdedit /set $Guid osdevice $DeviceStr | Out-Null
        & bcdedit /set $Guid path \windows\system32\boot\winload.exe | Out-Null
        & bcdedit /set $Guid systemroot \windows | Out-Null
        & bcdedit /set $Guid winpe yes | Out-Null
        & bcdedit /set $Guid detecthal yes | Out-Null

        Ensure-EntryInDisplayOrder -Guid $Guid

        Log "-> ENTRY OK: $Guid"
        Log "-> DEVICE: $DeviceStr"
    } catch {
        Log "BCD ERROR: $_"
        [System.Windows.Forms.MessageBox]::Show("Lỗi BCD: $_", "Error")
        $Form.Cursor="Default"
        return
    }

    $Form.Cursor = "Default"
    if ([System.Windows.Forms.MessageBox]::Show("Đã tạo Boot Entry + Rebuild Boot! Restart ngay?", "Success", "YesNo") -eq "Yes") {
        Restart-Computer -Force
    }
}

# Buttons create (needs Start-Headless-DISM defined above)
New-BigBtn $GrpAction "MODE 2: HEADLESS DISM (AUTO DETECT + REBUILD BOOT)`n(Boot Source -> Cài Target)" 30 "Orange" { Start-Headless-DISM }
New-BigBtn $GrpAction "MODE 1: SETUP.EXE`n(Truyền thống)" 100 "LightGray" {
    if (!$Global:IsoMounted) { [System.Windows.Forms.MessageBox]::Show("Chưa Mount ISO!"); return }
    Start-Process "$($Global:IsoMounted)\setup.exe"
}

# --- EVENTS ---
$BtnISO.Add_Click({
    $OFD = New-Object System.Windows.Forms.OpenFileDialog
    $OFD.Filter = "ISO Files|*.iso"
    if($OFD.ShowDialog() -eq "OK") { $TxtISO.Text = $OFD.FileName }
})

$BtnXml.Add_Click({
    $OFD = New-Object System.Windows.Forms.OpenFileDialog
    $OFD.Filter = "XML Files|*.xml"
    if($OFD.ShowDialog() -eq "OK") {
        $Global:CustomXmlPath = $OFD.FileName
        $TxtXml.Text = $OFD.FileName
    }
})

$BtnMount.Add_Click({
    if ([string]::IsNullOrEmpty($TxtISO.Text)) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn file ISO!"); return }
    Log "Mounting ISO..."
    try {
        $Img = Get-DiskImage -ImagePath $TxtISO.Text
        if ($Img.Attached -eq $false) { Mount-DiskImage -ImagePath $TxtISO.Text -StorageType ISO -ErrorAction Stop | Out-Null; Start-Sleep 2 }

        $D = (Get-DiskImage -ImagePath $TxtISO.Text | Get-Volume -EA 0).DriveLetter

        if (!$D) {
            $Drives = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=5"
            foreach ($Drv in $Drives) {
                if ((Test-Path "$($Drv.DeviceID)\sources\install.wim") -or (Test-Path "$($Drv.DeviceID)\sources\install.esd")) {
                    $D = $Drv.DeviceID.Replace(":","")
                    break
                }
            }
        }
        if (!$D) { throw "Mount Fail / Cannot detect ISO drive letter" }

        $Global:IsoMounted = "$D`:"
        Log "Mounted at $Global:IsoMounted"

        $Wim = "$($Global:IsoMounted)\sources\install.wim"
        if(!(Test-Path $Wim)) { $Wim = "$($Global:IsoMounted)\sources\install.esd" }
        $Global:WimFile = $Wim

        $CbIndex.Items.Clear()
        & dism /Get-WimInfo /WimFile:$Wim | Select-String "Name :" | ForEach-Object {
            $CbIndex.Items.Add($_.ToString().Split(":")[1].Trim()) | Out-Null
        }
        if ($CbIndex.Items.Count -gt 0) { $CbIndex.SelectedIndex = 0 }

    } catch {
        Log "Err: $_"
    }
})

Load-Partitions
$Form.ShowDialog() | Out-Null
