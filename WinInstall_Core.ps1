<#
    WININSTALL CORE V10.1 (SUPER HUNTER)
    Author: Phat Tan PC
    Fix: 
    - Full Qualified Name cho OpenFileDialog (Fix lỗi TypeNotFound).
    - WMIC Legacy Support: Giữ nguyên cơ chế quét đĩa bằng WMI cho Win cổ.
    - Headless DISM: Tối ưu loop Taskkill để giấu sạch GUI Setup.
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
$Form.Text = "CORE INSTALLER V10.5  (PHAT TAN PC)"; $Form.Size = "1000, 750"; $Form.StartPosition = "CenterScreen"; $Form.BackColor = $Theme.Bg; $Form.ForeColor = $Theme.Text; $Form.FormBorderStyle = "FixedSingle"

$LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text = "🚀 WINDOWS ULTIMATE INSTALLER V10.2"; $LblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold); $LblTitle.ForeColor = $Theme.Cyan; $LblTitle.AutoSize = $true; $LblTitle.Location = "20, 15"; $Form.Controls.Add($LblTitle)

# === 1. CẤU HÌNH HỆ THỐNG ===
$GrpConfig = New-Object System.Windows.Forms.GroupBox; $GrpConfig.Text = " 1. THIẾT LẬP BỘ CÀI & DRIVE "; $GrpConfig.Location = "20, 70"; $GrpConfig.Size = "550, 520"; $GrpConfig.ForeColor = "Yellow"; $Form.Controls.Add($GrpConfig)

# ISO & Index
$BtnISO = New-Object System.Windows.Forms.Button; $BtnISO.Text = "📂 CHỌN ISO"; $BtnISO.Location = "20,30"; $BtnISO.Size = "120,30"; $BtnISO.BackColor="DimGray"; $GrpConfig.Controls.Add($BtnISO)
$TxtISO = New-Object System.Windows.Forms.TextBox; $TxtISO.Location = "150,32"; $TxtISO.Size = "260,25"; $TxtISO.ReadOnly=$true; $GrpConfig.Controls.Add($TxtISO)
$BtnMount = New-Object System.Windows.Forms.Button; $BtnMount.Text = "💿 MOUNT"; $BtnMount.Location = "420,30"; $BtnMount.Size = "110,30"; $BtnMount.BackColor="DarkGreen"; $GrpConfig.Controls.Add($BtnMount)

$LblVer = New-Object System.Windows.Forms.Label; $LblVer.Text = "Phiên Bản:"; $LblVer.Location = "20,70"; $LblVer.AutoSize=$true; $GrpConfig.Controls.Add($LblVer)
$CbIndex = New-Object System.Windows.Forms.ComboBox; $CbIndex.Location = "100,68"; $CbIndex.Size = "430,30"; $CbIndex.DropDownStyle="DropDownList"; $GrpConfig.Controls.Add($CbIndex)

# Partition Selection (WMIC Legacy)
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
New-BigBtn $GrpAction "MODE 1: SETUP.EXE`n(Rollback Standard)" 100 "LightGray" { 
    if (!$Global:IsoMounted) { [MessageBox]::Show("Chưa Mount ISO!"); return }
    Start-Process "$($Global:IsoMounted)\setup.exe"
}

# Log Box
$TxtLog = New-Object System.Windows.Forms.TextBox; $TxtLog.Location = "20, 610"; $TxtLog.Size = "945, 80"; $TxtLog.Multiline=$true; $TxtLog.BackColor="Black"; $TxtLog.ForeColor="Lime"; $TxtLog.ReadOnly=$true; $TxtLog.ScrollBars="Vertical"; $Form.Controls.Add($TxtLog)

function Log ($M) { $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm'))] $M`r`n"); $TxtLog.ScrollToCaret() }

# --- CORE LOGIC (FIXED) ---

function Load-Partitions {
    $GridPart.Rows.Clear()
    # Dùng WMIC Legacy để tương thích Win Lite
    try {
        $Drives = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
        foreach ($D in $Drives) {
            $Letter = $D.DeviceID.Replace(":","")
            $Row = $GridPart.Rows.Add("?", "?", $Letter, "$([math]::Round($D.Size/1GB,1)) GB", "Chưa chọn")
            if ($Letter -eq $env:SystemDrive.Replace(":","")) { 
                $Global:SelectedInstall = $Letter; $Global:SelectedBoot = $Letter
                $GridPart.Rows[$Row].Cells[4].Value = "CÀI + BOOT"
            }
        }
    } catch { Log "Lỗi quét phân vùng bằng WMI!" }
}

# Context Menu for Grid
$Cms = New-Object System.Windows.Forms.ContextMenuStrip
$miInstall = $Cms.Items.Add("Chọn làm Ổ CÀI WIN (Đích)")
$miBoot = $Cms.Items.Add("Chọn làm Ổ BOOT (Nạp BCD)")
$miInstall.Add_Click({ 
    if ($GridPart.SelectedRows.Count -gt 0) {
        $L = $GridPart.SelectedRows[0].Cells[2].Value
        $Global:SelectedInstall = $L; Log "Đã chọn ổ CÀI: $L"
        foreach($R in $GridPart.Rows){ if($R.Cells[4].Value -match "CÀI"){ $R.Cells[4].Value = $R.Cells[4].Value.Replace("CÀI","").Trim("- ") } }
        $GridPart.SelectedRows[0].Cells[4].Value = ($GridPart.SelectedRows[0].Cells[4].Value + " - CÀI").Trim("- ")
    }
})
$miBoot.Add_Click({ 
    if ($GridPart.SelectedRows.Count -gt 0) {
        $L = $GridPart.SelectedRows[0].Cells[2].Value
        $Global:SelectedBoot = $L; Log "Đã chọn ổ BOOT: $L"
        foreach($R in $GridPart.Rows){ if($R.Cells[4].Value -match "BOOT"){ $R.Cells[4].Value = $R.Cells[4].Value.Replace("BOOT","").Trim("- ") } }
        $GridPart.SelectedRows[0].Cells[4].Value = ($GridPart.SelectedRows[0].Cells[4].Value + " - BOOT").Trim("- ")
    }
})
$GridPart.ContextMenuStrip = $Cms

function Start-Headless-DISM {
    if (!$Global:IsoMounted) { [System.Windows.Forms.MessageBox]::Show("Chưa Mount ISO!"); return }
    $IndexName = $CbIndex.SelectedItem; $Idx = if ($IndexName) { $IndexName.ToString().Split("-")[0].Trim() } else { 1 }

    if ([System.Windows.Forms.MessageBox]::Show("XÁC NHẬN CÀI WIN?`nỔ $($Global:SelectedInstall) sẽ bị xóa dữ liệu!", "Phat Tan PC", "YesNo") -ne "Yes") { return }

    $Form.Cursor = "WaitCursor"
    Log "Đang khởi tạo môi trường..."

    # 1. Tìm ổ đĩa an toàn để lưu bộ cài
    $SafeDrive = $null
    $Drives = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($D in $Drives) { if ($D.DeviceID -ne "$($Global:SelectedInstall):" -and $D.FreeSpace -gt 5GB) { $SafeDrive = $D.DeviceID; break } }
    if (!$SafeDrive) { [System.Windows.Forms.MessageBox]::Show("Cần ổ đĩa khác ổ Cài trống > 5GB!"); $Form.Cursor = "Default"; return }

    $WorkDir = "$SafeDrive\WinSource_PhatTan"; New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null

    # 2. Xử lý phần mở rộng (WIM hay ESD)
    $Ext = [System.IO.Path]::GetExtension($Global:WimFile)
    Log "Phát hiện định dạng bộ cài: $Ext"

    # 3. Copy files & Backup (Giữ nguyên logic của bác)
    Log "Copying core files... (Vui lòng đợi)"
    Copy-Item $Global:WimFile "$WorkDir\install$Ext" -Force # Lưu đúng đuôi file
    Copy-Item "$Global:IsoMounted\sources\boot.wim" "$($Global:SelectedInstall):\WinInstall.wim" -Force
    Copy-Item "$Global:IsoMounted\boot\boot.sdi" "$($Global:SelectedInstall):\boot.sdi" -Force

    # 4. Tạo AutoInstall.cmd (Headless Mode)
    $ScriptCmd = "@echo off`r`ntitle HEADLESS INSTALLER - PHAT TAN PC`r`ncolor 0b`r`ncls`r`n" +
                 "start /min cmd /c `"for /l %%i in (1,1,100) do (taskkill /F /IM setup.exe >nul 2>&1 & timeout /t 1 >nul)`"`r`n" +
                 "set TARGET=`r`nfor %%x in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (vol %%x: 2>nul | find `"WIN_TARGET`" >nul && set TARGET=%%x)`r`n" +
                 "echo [2/7] SOFT FORMAT %TARGET%:...`r`n" +
                 "for /d %%p in (%TARGET%:\*) do rd /s /q `"%%p`"`r`ndel /f /q /a %TARGET%:\*.*`r`n" +
                 "echo [3/7] BUNG WIN (INDEX $Idx)...`r`ndism /Apply-Image /ImageFile:`"%~dp0install$Ext`" /Index:$Idx /ApplyDir:%TARGET%:\`r`n" +
                 "echo [4/7] FIX BOOT...`r`nbcdboot %TARGET%:\Windows /s $($Global:SelectedBoot): /f ALL`r`n" +
                 "wpeutil reboot"

    [IO.File]::WriteAllText("$WorkDir\AutoInstall.cmd", $ScriptCmd, [System.Text.Encoding]::ASCII)
    
    # 5. Cấu hình BCD (Fix treo - Bắt GUID tự động)
    # 5. Cấu hình BCD (Tự động nhận diện BIOS/UEFI để tránh treo VirtualBox)
    # 5. Cấu hình BCD (Bản V10.5 - Chống Dump xanh Unmountable Boot Volume)
    Log "Cấu hình Boot Manager (Refined Mode)..."
    try {
        # 5.1. Kiểm tra sự tồn tại của tệp tin trước khi nạp (Tránh nạp đường dẫn ma)
        $WimPath = "$($Global:SelectedInstall):\WinInstall.wim"
        $SdiPath = "$($Global:SelectedInstall):\boot.sdi"
        if (!(Test-Path $WimPath) -or !(Test-Path $SdiPath)) { throw "Thiếu file hệ thống tại $WimPath hoặc $SdiPath!" }

        # 5.2. Nhận diện môi trường BIOS/UEFI chuẩn xác
        $BootInfo = & bcdedit /enum "{current}"
        $IsUEFI = ($BootInfo -match "winload.efi") -or ($env:Firmware_Type -eq "UEFI")
        # Legacy thường nằm ở system32, UEFI bắt buộc ở system32\boot
        $LoaderPath = if ($IsUEFI) { "\windows\system32\boot\winload.efi" } else { "\windows\system32\winload.exe" }
        Log "-> Moi truong: $(if($IsUEFI){"UEFI"}else{"Legacy"}) | Loader: $LoaderPath"

        # 5.3. Xử lý ramdiskoptions (Gốc rễ của lỗi Unmountable)
        & bcdedit /delete "{ramdiskoptions}" /f 2>$null
        & bcdedit /create "{ramdiskoptions}" /d "PhatTan Ramdisk" /f | Out-Null
        & bcdedit /set "{ramdiskoptions}" ramdisksdidevice "partition=$($Global:SelectedInstall):"
        & bcdedit /set "{ramdiskoptions}" ramdisksdipath "\boot.sdi" # SDI phai o root cua device

        # 5.4. Tạo và cấu hình Boot Entry (Dùng Regex bắt GUID chuẩn)
        $BcdOutput = & bcdedit /create /d "AUTO INSTALLER (Phat Tan PC)" /application osloader
        $RealGuid = ([regex]'{[a-z0-9-]{36}}').Match($BcdOutput).Value

        if ($RealGuid) {
            # Thiết lập thiết bị chứa Ramdisk (Đảm bảo định dạng [C:]\Path)
            $DeviceStr = "ramdisk=[$($Global:SelectedInstall):]\WinInstall.wim,{ramdiskoptions}"
            & bcdedit /set $RealGuid device $DeviceStr
            & bcdedit /set $RealGuid osdevice $DeviceStr
            & bcdedit /set $RealGuid path $LoaderPath
            & bcdedit /set $RealGuid systemroot "\windows"
            & bcdedit /set $RealGuid winpe yes
            & bcdedit /set $RealGuid detecthal yes
            # Tắt kiểm tra chữ ký (Quan trọng cho Win Lite/Custom WIM)
            & bcdedit /set $RealGuid nointegritychecks yes
            & bcdedit /set $RealGuid testsigning yes
            
            # Đẩy lên đầu danh sách boot cho lần sau
            & bcdedit /bootsequence $RealGuid
            Log "-> Nap BCD thanh cong! GUID: $RealGuid"
        } else { throw "Khong the tao GUID cho Boot Entry!" }
    } catch { 
        Log "LOI NGHIEP TRONG: $($_.Exception.Message)" 
        [System.Windows.Forms.MessageBox]::Show("Lỗi cấu hình BCD! Chi tiết: $($_.Exception.Message)", "Phat Tan PC")
    }
    $Form.Cursor = "Default"
    if ([System.Windows.Forms.MessageBox]::Show("Đã thiết lập thành công! Khởi động lại ngay?", "Hoàn Tất", "YesNo") -eq "Yes") { Restart-Computer -Force }
}

# --- EVENTS (FIXED TypeNotFound) ---
$BtnISO.Add_Click({ 
    $OFD = New-Object System.Windows.Forms.OpenFileDialog
    $OFD.Filter = "ISO Files|*.iso"
    if($OFD.ShowDialog() -eq "OK") { $TxtISO.Text = $OFD.FileName } 
})

$BtnXml.Add_Click({ 
    $OFD = New-Object System.Windows.Forms.OpenFileDialog
    $OFD.Filter = "XML Files|*.xml"
    if($OFD.ShowDialog() -eq "OK") { $Global:CustomXmlPath = $OFD.FileName; $TxtXml.Text = $OFD.FileName } 
})

$BtnMount.Add_Click({ 
    if ([string]::IsNullOrEmpty($TxtISO.Text)) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn file ISO!"); return }
    Log "Đang tiến hành Mount ISO..."
    
    try {
        # 1. Thực hiện Mount (Bỏ qua nếu đã Mount)
        $Img = Get-DiskImage -ImagePath $TxtISO.Text
        if ($Img.Attached -eq $false) {
            Mount-DiskImage -ImagePath $TxtISO.Text -StorageType ISO -ErrorAction Stop | Out-Null
            Start-Sleep -Seconds 3 # Đợi hệ thống nhận diện
        }

        # 2. Tìm Drive Letter - CHIẾN THUẬT ĐA TẦNG
        $D = $null
        
        # Cách 1: Thử bằng lệnh Get-Volume hiện đại
        Log "-> Thử quét bằng Storage Module..."
        $D = (Get-DiskImage -ImagePath $TxtISO.Text | Get-Volume -ErrorAction SilentlyContinue).DriveLetter
        
        # Cách 2: Fallback sang quét WMI (Dành cho Win Lite/Máy cổ)
        if (-not $D) {
            Log "-> Không tìm thấy ổ đĩa! Chuyển sang quét WMI..."
            # Tìm ổ đĩa loại "CD-ROM" ảo có chứa bộ cài Windows
            $Drives = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3 OR DriveType=5"
            foreach ($Drv in $Drives) {
                $TestPath = "$($Drv.DeviceID)\sources\install.wim"
                $TestPath2 = "$($Drv.DeviceID)\sources\install.esd"
                if (Test-Path $TestPath) { $D = $Drv.DeviceID.Replace(":",""); break }
                if (Test-Path $TestPath2) { $D = $Drv.DeviceID.Replace(":",""); break }
            }
        }

        if (-not $D) { throw "Không thể xác định ký tự ổ đĩa sau khi Mount!" }

        $Global:IsoMounted = "$D`:"
        Log "Mount thành công ổ $($Global:IsoMounted)"

        # 3. Load Index (Dùng DISM cho nhẹ máy)
        $Wim = "$($Global:IsoMounted)\sources\install.wim"
        if(!(Test-Path $Wim)){ $Wim = "$($Global:IsoMounted)\sources\install.esd" }
        
        if (Test-Path $Wim) {
            $Global:WimFile = $Wim
            $CbIndex.Items.Clear()
            & dism /Get-WimInfo /WimFile:$Wim | Select-String "Name :" | ForEach { 
                $CbIndex.Items.Add($_.ToString().Split(":")[1].Trim()) 
            }
            if ($CbIndex.Items.Count -gt 0) { $CbIndex.SelectedIndex = 0 }
        } else {
            Log "Lỗi: Không tìm thấy Install file trong ổ $D"
        }
    } catch { 
        Log "Lỗi: $($_.Exception.Message)" 
        [System.Windows.Forms.MessageBox]::Show("Lỗi Mount ISO! Hãy thử Mount thủ công hoặc kiểm tra file ISO.`n`nChi tiết: $($_.Exception.Message)", "Error")
    }
})
Load-Partitions
$Form.ShowDialog() | Out-Null
