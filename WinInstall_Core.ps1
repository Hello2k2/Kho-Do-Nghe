<#
    WININSTALL CORE V10.0 (ULTIMATE HUNTER)
    Author: Phat Tan PC
    Updates V10.0:
    - Dual Drive Select: Cho phép chọn riêng ổ Đích (Cài Win) và ổ Boot (Nạp BCD).
    - Custom Unattend: Hỗ trợ nhập file XML bên ngoài.
    - Headless Mode 2: Tối ưu Setup Hunter để giết sạch GUI Setup, chỉ hiện CMD.
    - Post-Install Tweaks: Tùy chọn tắt GOS/Game Mode, bỏ qua thông báo Reboot.
    - Registry Backup Center: Tự động sao lưu Registry Hives trước khi cài.
#>

# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- INIT ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$Global:SelectedInstall = $null
$Global:SelectedBoot = $null
$Global:CustomXmlPath = ""
$Global:IsoMounted = $null

# --- THEME ---
$Theme = @{ Bg=[System.Drawing.Color]::FromArgb(20,20,25); Panel=[System.Drawing.Color]::FromArgb(35,35,40); Text="White"; Cyan="DeepSkyBlue"; Red="Crimson" }

# --- GUI ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CORE INSTALLER V10.0 - ULTIMATE HUNTER (PHAT TAN PC)"; $Form.Size = "1000, 750"; $Form.StartPosition = "CenterScreen"; $Form.BackColor = $Theme.Bg; $Form.ForeColor = $Theme.Text; $Form.FormBorderStyle = "FixedSingle"

$LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text = "🚀 WINDOWS ULTIMATE INSTALLER V10.0"; $LblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold); $LblTitle.ForeColor = $Theme.Cyan; $LblTitle.AutoSize = $true; $LblTitle.Location = "20, 15"; $Form.Controls.Add($LblTitle)

# === 1. CẤU HÌNH HỆ THỐNG ===
$GrpConfig = New-Object System.Windows.Forms.GroupBox; $GrpConfig.Text = " 1. THIẾT LẬP BỘ CÀI & DRIVE "; $GrpConfig.Location = "20, 70"; $GrpConfig.Size = "550, 520"; $GrpConfig.ForeColor = "Yellow"; $Form.Controls.Add($GrpConfig)

# ISO & Index
$BtnISO = New-Object System.Windows.Forms.Button; $BtnISO.Text = "📂 CHỌN ISO"; $BtnISO.Location = "20,30"; $BtnISO.Size = "120,30"; $BtnISO.BackColor="DimGray"; $GrpConfig.Controls.Add($BtnISO)
$TxtISO = New-Object System.Windows.Forms.TextBox; $TxtISO.Location = "150,32"; $TxtISO.Size = "260,25"; $TxtISO.ReadOnly=$true; $GrpConfig.Controls.Add($TxtISO)
$BtnMount = New-Object System.Windows.Forms.Button; $BtnMount.Text = "💿 MOUNT"; $BtnMount.Location = "420,30"; $BtnMount.Size = "110,30"; $BtnMount.BackColor="DarkGreen"; $GrpConfig.Controls.Add($BtnMount)

$LblVer = New-Object System.Windows.Forms.Label; $LblVer.Text = "Phiên Bản:"; $LblVer.Location = "20,70"; $LblVer.AutoSize=$true; $GrpConfig.Controls.Add($LblVer)
$CbIndex = New-Object System.Windows.Forms.ComboBox; $CbIndex.Location = "100,68"; $CbIndex.Size = "430,30"; $CbIndex.DropDownStyle="DropDownList"; $GrpConfig.Controls.Add($CbIndex)

# Partition Selection
$LblGrid = New-Object System.Windows.Forms.Label; $LblGrid.Text = "DANH SÁCH PHÂN VÙNG (Chuột phải để chọn Ổ CÀI / Ổ BOOT):"; $LblGrid.Location = "20,110"; $LblGrid.AutoSize=$true; $LblGrid.ForeColor="Silver"; $GrpConfig.Controls.Add($LblGrid)
$GridPart = New-Object System.Windows.Forms.DataGridView; $GridPart.Location = "20,135"; $GridPart.Size = "510,200"; $GridPart.BackgroundColor="Black"; $GridPart.ForeColor="Black"; $GridPart.RowHeadersVisible=$false; $GridPart.SelectionMode="FullRowSelect"; $GridPart.ReadOnly=$true; $GridPart.AutoSizeColumnsMode="Fill"
$GridPart.Columns.Add("Dsk","D"); $GridPart.Columns.Add("Prt","P"); $GridPart.Columns.Add("Ltr","L"); $GridPart.Columns.Add("Size","Size"); $GridPart.Columns.Add("Role","Vai Trò"); $GrpConfig.Controls.Add($GridPart)

# Custom XML
$BtnXml = New-Object System.Windows.Forms.Button; $BtnXml.Text = "📄 Nạp Unattend.xml"; $BtnXml.Location = "20,350"; $BtnXml.Size = "150,30"; $BtnXml.BackColor="SteelBlue"; $GrpConfig.Controls.Add($BtnXml)
$TxtXml = New-Object System.Windows.Forms.TextBox; $TxtXml.Location = "180,352"; $TxtXml.Size = "350,25"; $TxtXml.ReadOnly=$true; $TxtXml.Text = "Mặc định (Auto)"; $GrpConfig.Controls.Add($TxtXml)

# === 2. TÙY CHỌN NÂNG CAO ===
$GrpOption = New-Object System.Windows.Forms.GroupBox; $GrpOption.Text = " 2. OPTIMIZATION "; $GrpOption.Location = "590, 70"; $GrpOption.Size = "370, 280"; $GrpOption.ForeColor = "Lime"; $Form.Controls.Add($GrpOption)

$ChkReg = New-Object System.Windows.Forms.CheckBox; $ChkReg.Text = "Backup Registry Hives (An toàn)"; $ChkReg.Location="20, 30"; $ChkReg.AutoSize=$true; $ChkReg.Checked=$true; $GrpOption.Controls.Add($ChkReg)
$ChkGOS = New-Object System.Windows.Forms.CheckBox; $ChkGOS.Text = "Tắt Game Mode & Optimization (Tăng FPS)"; $ChkGOS.Location="20, 60"; $ChkGOS.AutoSize=$true; $ChkGOS.Checked=$true; $GrpOption.Controls.Add($ChkGOS)
$ChkWarn = New-Object System.Windows.Forms.CheckBox; $ChkWarn.Text = "Tắt thông báo Reboot (Cài xong tự Restart)"; $ChkWarn.Location="20, 90"; $ChkWarn.AutoSize=$true; $ChkWarn.Checked=$false; $GrpOption.Controls.Add($ChkWarn)
$ChkDriver = New-Object System.Windows.Forms.CheckBox; $ChkDriver.Text = "Auto Backup/Restore Driver"; $ChkDriver.Location="20, 120"; $ChkDriver.AutoSize=$true; $ChkDriver.Checked=$true; $GrpOption.Controls.Add($ChkDriver)

# === 3. ACTIONS ===
$GrpAction = New-Object System.Windows.Forms.GroupBox; $GrpAction.Text = " 3. EXECUTE "; $GrpAction.Location = "590, 360"; $GrpAction.Size = "370, 230"; $GrpAction.ForeColor = "Cyan"; $Form.Controls.Add($GrpAction)

function New-BigBtn ($Parent, $Txt, $Y, $Color, $Event) {
    $B = New-Object System.Windows.Forms.Button; $B.Text = $Txt; $B.Location = "20, $Y"; $B.Size = "330, 60"; $B.BackColor = $Color; $B.ForeColor = "Black"; $B.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold); $B.FlatStyle = "Flat"; $B.Add_Click($Event); $Parent.Controls.Add($B)
}

New-BigBtn $GrpAction "MODE 2: HEADLESS DISM`n(Format C -> CMD Only -> No GUI)" 30 "Orange" { Start-Headless-DISM }
New-BigBtn $GrpAction "MODE 1: SETUP.EXE`n(Rollback Standard)" 100 "LightGray" { Start-Standard-Setup }

# Log Box
$TxtLog = New-Object System.Windows.Forms.TextBox; $TxtLog.Location = "20, 610"; $TxtLog.Size = "945, 80"; $TxtLog.Multiline=$true; $TxtLog.BackColor="Black"; $TxtLog.ForeColor="Lime"; $TxtLog.ReadOnly=$true; $TxtLog.ScrollBars="Vertical"; $Form.Controls.Add($TxtLog)

function Log ($M) { $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm'))] $M`r`n"); $TxtLog.ScrollToCaret() }

# --- CORE LOGIC ---

function Load-Partitions {
    $GridPart.Rows.Clear()
    $Drives = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($D in $Drives) {
        $Letter = $D.DeviceID.Replace(":","")
        $Row = $GridPart.Rows.Add("?", "?", $Letter, "$([math]::Round($D.Size/1GB,1)) GB", "Chưa chọn")
        if ($Letter -eq $env:SystemDrive.Replace(":","")) { 
            $Global:SelectedInstall = $Letter; $Global:SelectedBoot = $Letter
            $GridPart.Rows[$Row].Cells[4].Value = "CÀI + BOOT"
        }
    }
}

# Context Menu for Grid
$Cms = New-Object System.Windows.Forms.ContextMenuStrip
$miInstall = $Cms.Items.Add("Chọn làm Ổ CÀI WIN (Đích)")
$miBoot = $Cms.Items.Add("Chọn làm Ổ BOOT (Nạp BCD)")
$miInstall.Add_Click({ 
    $L = $GridPart.SelectedRows[0].Cells[2].Value
    $Global:SelectedInstall = $L; Log "Đã chọn ổ CÀI: $L"
    foreach($R in $GridPart.Rows){ if($R.Cells[4].Value -match "CÀI"){ $R.Cells[4].Value = $R.Cells[4].Value.Replace("CÀI","").Trim("- ") } }
    $GridPart.SelectedRows[0].Cells[4].Value = ($GridPart.SelectedRows[0].Cells[4].Value + " - CÀI").Trim("- ")
})
$miBoot.Add_Click({ 
    $L = $GridPart.SelectedRows[0].Cells[2].Value
    $Global:SelectedBoot = $L; Log "Đã chọn ổ BOOT: $L"
    foreach($R in $GridPart.Rows){ if($R.Cells[4].Value -match "BOOT"){ $R.Cells[4].Value = $R.Cells[4].Value.Replace("BOOT","").Trim("- ") } }
    $GridPart.SelectedRows[0].Cells[4].Value = ($GridPart.SelectedRows[0].Cells[4].Value + " - BOOT").Trim("- ")
})
$GridPart.ContextMenuStrip = $Cms

function Start-Headless-DISM {
    if (!$Global:IsoMounted) { [MessageBox]::Show("Chưa Mount ISO!"); return }
    $IndexName = $CbIndex.SelectedItem; $Idx = if ($IndexName) { $IndexName.ToString().Split("-")[0].Trim() } else { 1 }

    if ([MessageBox]::Show("XÁC NHẬN CÀI WIN CHẾ ĐỘ HEADLESS?`nToàn bộ dữ liệu ổ $($Global:SelectedInstall) sẽ bị xóa!", "Phat Tan PC", "YesNo") -ne "Yes") { return }

    $Form.Cursor = "WaitCursor"
    $SafeDrive = $null
    $Drives = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($D in $Drives) { if ($D.DeviceID -ne "$($Global:SelectedInstall):" -and $D.FreeSpace -gt 5GB) { $SafeDrive = $D.DeviceID; break } }
    
    if (!$SafeDrive) { [MessageBox]::Show("Cần 1 ổ khác ổ Cài trống > 5GB để lưu tạm!"); $Form.Cursor = "Default"; return }

    $WorkDir = "$SafeDrive\WinSource_PhatTan"; New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null

    # 1. Backup Registry
    if ($ChkReg.Checked) {
        Log "Backup Registry Hives..."
        $RegDir = "$WorkDir\Reg_Backup"; New-Item $RegDir -Type Directory -Force | Out-Null
        reg save HKLM\SYSTEM "$RegDir\SYSTEM.hiv" /y | Out-Null
        reg save HKLM\SOFTWARE "$RegDir\SOFTWARE.hiv" /y | Out-Null
    }

    # 2. Driver Backup
    $DrvCmd = ""
    if ($ChkDriver.Checked) {
        Log "Backup Driver..."
        $DrvPath = "$WorkDir\Drivers_Backup"; New-Item $DrvPath -Type Directory -Force | Out-Null
        & dism /online /export-driver /destination:"$DrvPath" | Out-Null
        $DrvCmd = "echo [6/7] NAP DRIVER...`r`ndism /Image:%TARGET%:\ /Add-Driver /Driver:`"%~d0\WinSource_PhatTan\Drivers_Backup`" /Recurse`r`n"
    }

    # 3. Label Drive Đích
    Log "Đánh dấu ổ cài..."
    $TargetVol = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$($Global:SelectedInstall):'"
    $TargetVol.VolumeName = "WIN_TARGET"; $TargetVol.Put()

    # 4. Copy Files
    Log "Copying core files..."
    Copy-Item $Global:WimFile "$WorkDir\install.wim" -Force
    Copy-Item "$Global:IsoMounted\sources\boot.wim" "$($Global:SelectedInstall):\WinInstall.wim" -Force
    Copy-Item "$Global:IsoMounted\boot\boot.sdi" "$($Global:SelectedInstall):\boot.sdi" -Force

    # 5. Create Headless AutoInstall.cmd
    $RebootTime = if ($ChkWarn.Checked) { "1" } else { "10" }
    $GOS_Tweak = if ($ChkGOS.Checked) { "reg add `"HKLM\Software\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR`" /v value /t REG_DWORD /d 0 /f" } else { "echo Skip Tweaks" }

    $ScriptCmd = "@echo off`r`ntitle HEADLESS INSTALLER - PHAT TAN PC`r`ncolor 0b`r`ncls`r`n" +
                 "echo ====================================================`r`n" +
                 "echo    PHAT TAN PC - DANG CAI WIN HEADLESS (SIEU TOC)`r`n" +
                 "echo ====================================================`r`n" +
                 "start /min cmd /c `"for /l %%i in (1,1,60) do (taskkill /F /IM setup.exe >nul 2>&1 & timeout /t 1 >nul)`"`r`n" +
                 "set TARGET=`r`nfor %%x in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (vol %%x: 2>nul | find `"WIN_TARGET`" >nul && set TARGET=%%x)`r`n" +
                 "echo [2/7] SOFT FORMAT %TARGET%:...`r`n" +
                 "for /d %%p in (%TARGET%:\*) do rd /s /q `"%%p`"`r`ndel /f /q /a %TARGET%:\*.*`r`n" +
                 "echo [3/7] BUNG WIN (INDEX $Idx)...`r`ndism /Apply-Image /ImageFile:`"%~dp0install.wim`" /Index:$Idx /ApplyDir:%TARGET%:\`r`n" +
                 "echo [4/7] FIX BOOT...`r`nbcdboot %TARGET%:\Windows /s $($Global:SelectedBoot): /f ALL`r`n" +
                 $DrvCmd +
                 "echo [7/7] OPTIMIZING...`r`n" + $GOS_Tweak + "`r`n" +
                 "echo HOAN TAT! REBOOT TRONG $RebootTime GIAY...`r`ntimeout /t $RebootTime`r`nwpeutil reboot"

    [IO.File]::WriteAllText("$WorkDir\AutoInstall.cmd", $ScriptCmd, [System.Text.Encoding]::ASCII)
    
    # 6. XML Trigger (Bypass Setup hoàn toàn)
    $XmlContent = "<?xml version=`"1.0`" encoding=`"utf-8`"?><unattend xmlns=`"urn:schemas-microsoft-com:unattend`"><settings pass=`"windowsPE`"><component name=`"Microsoft-Windows-Setup`" processorArchitecture=`"amd64`" publicKeyToken=`"31bf3856ad364e35`" language=`"neutral`" versionScope=`"nonSxS`"><RunSynchronous><RunSynchronousCommand wcm:action=`"add`"><Order>1</Order><Path>cmd /c for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (if exist %%d:\WinSource_PhatTan\AutoInstall.cmd call %%d:\WinSource_PhatTan\AutoInstall.cmd)</Path></RunSynchronousCommand></RunSynchronous></component></settings></unattend>"
    
    # Nếu có file XML custom thì ưu tiên copy file đó
    if ($Global:CustomXmlPath -and (Test-Path $Global:CustomXmlPath)) {
        Log "Sử dụng Custom XML..."
        Copy-Item $Global:CustomXmlPath "$($Global:SelectedInstall):\autounattend.xml" -Force
    } else {
        [IO.File]::WriteAllText("$($Global:SelectedInstall):\autounattend.xml", $XmlContent, [System.Text.Encoding]::UTF8)
    }

    # 7. Nạp Boot Entry
    Log "Cấu hình Boot Manager..."
    & bcdedit /create "{ramdiskoptions}" /d "PhatTan Ramdisk" /f
    & bcdedit /set "{ramdiskoptions}" ramdisksdidevice "partition=$($Global:SelectedInstall):"
    & bcdedit /set "{ramdiskoptions}" ramdisksdipath "\boot.sdi"
    $Guid = "{$( [Guid]::NewGuid().ToString() )}"
    & bcdedit /create $Guid /d "AUTO INSTALLER (Phat Tan PC)" /application osloader
    & bcdedit /set $Guid device "ramdisk=[$($Global:SelectedInstall):]\WinInstall.wim,{ramdiskoptions}"
    & bcdedit /set $Guid osdevice "ramdisk=[$($Global:SelectedInstall):]\WinInstall.wim,{ramdiskoptions}"
    & bcdedit /set $Guid path "\windows\system32\boot\winload.efi"
    & bcdedit /set $Guid systemroot "\windows"
    & bcdedit /set $Guid winpe yes
    & bcdedit /set $Guid detecthal yes
    & bcdedit /bootsequence $Guid
    
    $Form.Cursor = "Default"
    if ([MessageBox]::Show("Đã thiết lập thành công! Khởi động lại ngay?", "Hoàn Tất", "YesNo") -eq "Yes") { Restart-Computer -Force }
}

# --- EVENTS ---
$BtnISO.Add_Click({ $OFD = New-Object OpenFileDialog; $OFD.Filter = "ISO|*.iso"; if($OFD.ShowDialog() -eq "OK") { $TxtISO.Text = $OFD.FileName } })
$BtnXml.Add_Click({ $OFD = New-Object OpenFileDialog; $OFD.Filter = "XML|*.xml"; if($OFD.ShowDialog() -eq "OK") { $Global:CustomXmlPath = $OFD.FileName; $TxtXml.Text = $OFD.FileName } })
$BtnMount.Add_Click({ 
    Log "Mounting ISO..."
    Mount-DiskImage -ImagePath $TxtISO.Text -StorageType ISO | Out-Null
    Start-Sleep 2
    $D = (Get-DiskImage -ImagePath $TxtISO.Text | Get-Volume).DriveLetter + ":"
    $Global:IsoMounted = $D
    $Wim = "$D\sources\install.wim"; if(!(Test-Path $Wim)){ $Wim = "$D\sources\install.esd" }
    $Global:WimFile = $Wim
    $CbIndex.Items.Clear()
    & dism /Get-WimInfo /WimFile:$Wim | Select-String "Name :" | ForEach { $CbIndex.Items.Add($_.ToString().Split(":")[1].Trim()) }
    $CbIndex.SelectedIndex = 0
    Log "Mount thành công ổ $D"
})

Load-Partitions
$Form.ShowDialog() | Out-Null
