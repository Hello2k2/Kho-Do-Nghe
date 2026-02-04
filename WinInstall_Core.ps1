<#
    WININSTALL CORE V18.3.1 (SAFE SOURCE BOOT - LOCATE FIX)
    Author: Phat Tan PC

    Logic:
    - Separate Source & Target: chép bộ cài vào ổ phụ (Source), boot WinPE từ Source, format/cài vào Target.
    - Target detection: label "WIN_TARGET" -> trong WinPE tự dò đúng ổ theo LABEL, không phụ thuộc drive letter.
    - BCD FIX: dùng [locate] để tránh lỗi đổi ký tự ổ khi boot (unmount/locate).
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
$Form.Text = "CORE INSTALLER V18.3.1 (SAFE SOURCE BOOT - LOCATE FIX)"
$Form.Size = "1000, 750"
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Bg
$Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

$LblTitle = New-Object System.Windows.Forms.Label
$LblTitle.Text = "🚀 WINDOWS ULTIMATE INSTALLER V18.3.2"
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

New-BigBtn $GrpAction "MODE 2: HEADLESS DISM (LOCATE FIX)`n(Boot ổ Source -> Cài ổ Target)" 30 "Orange" { Start-Headless-DISM }
New-BigBtn $GrpAction "MODE 1: SETUP.EXE`n(Truyền thống)" 100 "LightGray" {
    if (!$Global:IsoMounted) { [System.Windows.Forms.MessageBox]::Show("Chưa Mount ISO!"); return }
    Start-Process "$($Global:IsoMounted)\setup.exe"
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

# --- CORE LOGIC ---

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
    # 0) ADMIN
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole] "Administrator"
    )) {
        [System.Windows.Forms.MessageBox]::Show("Vui lòng chạy Tool bằng quyền Administrator!", "Lỗi Quyền")
        return
    }

    if (!$Global:IsoMounted) { [System.Windows.Forms.MessageBox]::Show("Chưa Mount ISO!"); return }

    # 1) DRIVE PICK
    $InstallDrive = "$($Global:SelectedInstall):"
    if ([string]::IsNullOrWhiteSpace($Global:SelectedInstall)) {
        [System.Windows.Forms.MessageBox]::Show("Chưa chọn ổ CÀI!", "Lỗi")
        return
    }

    # Source drive: auto pick ổ khác Target và free > 8GB
    $SourceDrive = $null
    $Drives = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($D in $Drives) {
        if ($D.DeviceID -ne $InstallDrive -and $D.FreeSpace -gt 8GB) {
            $SourceDrive = $D.DeviceID
            break
        }
    }
    if (!$SourceDrive) {
        [System.Windows.Forms.MessageBox]::Show("Cần 1 ổ phụ > 8GB (khác ổ cài)!", "Lỗi")
        return
    }

    # Index theo ComboBox (DISM index bắt đầu từ 1)
    $Index = 1
    if ($CbIndex.Items.Count -gt 0 -and $CbIndex.SelectedIndex -ge 0) {
        $Index = $CbIndex.SelectedIndex + 1
    }

    # RAM & Mode (display only)
    $RamMB = (Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1MB
    $BootMode = if ($RamMB -gt 4096) { "RAMDISK" } else { "LOCATE" }

    $Msg = "CHẾ ĐỘ: $BootMode (Hiển thị)`n" +
           "Source: $SourceDrive -> Target: $InstallDrive`n" +
           "Index: $Index`n`nTiếp tục?"
    if ([System.Windows.Forms.MessageBox]::Show($Msg, "Phat Tan PC", "YesNo", "Warning") -ne "Yes") { return }

    $Form.Cursor = "WaitCursor"
    Log "--- KHOI TAO (V18.3.1 LOCATE FIX) ---"

    # 2) PREP FOLDER + MARKER
    $WinSource = "$SourceDrive\WinSource_PhatTan"
    $RandomID = Get-Random -Min 100000 -Max 999999
    $MarkerFile = "PhatTan_Marker_$RandomID.txt"
    $MarkerPath = "$WinSource\boot\$MarkerFile"

    Log "Creating Directories..."
    try {
        if (Test-Path $WinSource) { Remove-Item $WinSource -Recurse -Force }
        New-Item -ItemType Directory -Path "$WinSource\sources" -Force | Out-Null
        New-Item -ItemType Directory -Path "$WinSource\boot" -Force | Out-Null
        Log " -> Folder OK: $WinSource"
    } catch {
        Log "ERR: Không tạo được thư mục! (Check Antivirus/Permissions)"
        $Form.Cursor = "Default"
        return
    }

    Log "Creating Marker File..."
    try {
        [IO.File]::WriteAllText($MarkerPath, "MARKER ID: $RandomID", [System.Text.Encoding]::ASCII)
        if (Test-Path $MarkerPath) { Log " -> Marker OK: $MarkerFile" } else { throw "File not created" }
    } catch {
        Log "ERR: Không tạo được file Marker!"
        $Form.Cursor = "Default"
        return
    }

    # 3) COPY FILES
    Log "Copying Source Files..."
    try {
        Copy-Item "$Global:IsoMounted\sources\boot.wim" "$WinSource\sources\boot.wim" -Force
        Copy-Item "$Global:IsoMounted\boot\boot.sdi" "$WinSource\boot\boot.sdi" -Force
        Copy-Item "$Global:IsoMounted\setup.exe" "$WinSource\setup.exe" -Force

        $InstWim = "$Global:IsoMounted\sources\install.wim"
        $IsESD = $false
        if (!(Test-Path $InstWim)) {
            $InstWim = "$Global:IsoMounted\sources\install.esd"
            $IsESD = $true
        }

        if ($IsESD) {
            Copy-Item $InstWim "$WinSource\sources\install.esd" -Force
            $InstallImagePath = "%~dp0sources\install.esd"
        } else {
            Copy-Item $InstWim "$WinSource\sources\install.wim" -Force
            $InstallImagePath = "%~dp0sources\install.wim"
        }
    } catch {
        Log "ERR: Copy file fail: $_"
        $Form.Cursor = "Default"
        return
    }

    # Label target để WinPE dò
    try {
        cmd /c "label $InstallDrive WIN_TARGET" | Out-Null
        Log "Label Target: WIN_TARGET -> $InstallDrive"
    } catch {
        Log "WARN: Không label được Target (vẫn có thể chạy nếu bạn tự set đúng trong cmd)."
    }

    # 4) BUILD AutoInstall.cmd + autounattend.xml
    Log "Writing AutoInstall.cmd..."
    $CmdContent = @"
@echo off
title PHAT TAN V18.3.1 AUTO INSTALL
setlocal enabledelayedexpansion

for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
  vol %%d: 2>nul | find "WIN_TARGET" >nul && set TARGET=%%d:
)

if "%TARGET%"=="" (
  echo [ERR] Không tìm thấy WIN_TARGET. Thoat.
  timeout /t 5 >nul
  exit /b 1
)

echo [OK] Target = %TARGET%

format %TARGET% /fs:ntfs /q /y /v:Windows

dism /Apply-Image /ImageFile:"$InstallImagePath" /Index:$Index /ApplyDir:%TARGET%

:: bcdboot an toàn hơn: bỏ /s để tránh chỉ nhầm EFI partition khi UEFI
bcdboot %TARGET%\Windows /f ALL

wpeutil reboot
"@
    [IO.File]::WriteAllText("$WinSource\AutoInstall.cmd", $CmdContent, [System.Text.Encoding]::ASCII)

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

    # 5) BCD CONFIG (LOCATE FIX)  ✅ CHỖ FIX CHÍNH
    Log "Configuring BCD (LOCATE FIX)..."
    try {
        # Không bắt buộc xóa {ramdiskoptions}, nhưng set lại để ăn chắc theo tool
        & bcdedit /create "{ramdiskoptions}" /d "Phat Tan Ramdisk" /f | Out-Null
        & bcdedit /set "{ramdiskoptions}" ramdisksdidevice locate
        & bcdedit /set "{ramdiskoptions}" ramdisksdipath "\WinSource_PhatTan\boot\boot.sdi"

        $BcdOutput = & bcdedit /create /d "PHAT TAN INSTALLER (V18.3.1 - LOCATE)" /application osloader
        $Guid = ([regex]'{[a-z0-9-]{36}}').Match($BcdOutput).Value
        if (!$Guid) { throw "Không lấy được GUID mới từ bcdedit output!" }

        # KEY: device/osdevice dùng [locate] để khỏi dính đổi drive letter khi boot
        $DeviceStr = "ramdisk=[locate]\WinSource_PhatTan\sources\boot.wim,{ramdiskoptions}"

        & bcdedit /set $Guid device $DeviceStr | Out-Null
        & bcdedit /set $Guid osdevice $DeviceStr | Out-Null
        & bcdedit /set $Guid path \windows\system32\boot\winload.exe | Out-Null
        & bcdedit /set $Guid systemroot \windows | Out-Null
        & bcdedit /set $Guid winpe yes | Out-Null
        & bcdedit /set $Guid detecthal yes | Out-Null

        & bcdedit /displayorder $Guid /addfirst | Out-Null
        & bcdedit /timeout 10 | Out-Null

        Log "-> BOOT OK! Entry: $Guid"
        Log "-> Device: $DeviceStr"
    } catch {
        Log "BCD ERROR: $_"
        [System.Windows.Forms.MessageBox]::Show("Lỗi BCD: $_", "Error")
        $Form.Cursor = "Default"
        return
    }

    $Form.Cursor = "Default"
    if ([System.Windows.Forms.MessageBox]::Show("Đã tạo Boot Entry (LOCATE FIX)! Restart ngay?", "Success", "YesNo") -eq "Yes") {
        Restart-Computer -Force
    }
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
    if ([string]::IsNullOrEmpty($TxtISO.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Chưa chọn file ISO!")
        return
    }
    Log "Mounting ISO..."
    try {
        $Img = Get-DiskImage -ImagePath $TxtISO.Text
        if ($Img.Attached -eq $false) {
            Mount-DiskImage -ImagePath $TxtISO.Text -StorageType ISO -ErrorAction Stop | Out-Null
            Start-Sleep 2
        }

        $D = (Get-DiskImage -ImagePath $TxtISO.Text | Get-Volume -EA 0).DriveLetter

        if (!$D) {
            # fallback scan CDROM drives
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

        # Load Index list
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

# BOOT
Load-Partitions
$Form.ShowDialog() | Out-Null
