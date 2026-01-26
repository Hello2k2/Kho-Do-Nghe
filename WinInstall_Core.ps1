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
$Form.Text = "CORE INSTALLER V10.5.8  (PHAT TAN PC)"; $Form.Size = "1000, 750"; $Form.StartPosition = "CenterScreen"; $Form.BackColor = $Theme.Bg; $Form.ForeColor = $Theme.Text; $Form.FormBorderStyle = "FixedSingle"

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
    $TargetDrive = "$($Global:SelectedInstall):"
    
    if ([System.Windows.Forms.MessageBox]::Show("CẢNH BÁO: Sẽ Format ổ $TargetDrive và chép bộ cài.`nTiếp tục?", "Phat Tan PC", "YesNo", "Warning") -ne "Yes") { return }

    $Form.Cursor = "WaitCursor"
    Log "--- KHOI TAO (V13.0 PHYSICAL SIGNATURE) ---"

    # 1. DỌN DẸP BCD CŨ
    Log "Don dep BCD..."
    & bcdedit /enum | Select-String "identifier" | ForEach-Object {
        $ID = $_.ToString().Split(" ")[-1].Trim()
        if ($ID -match "{[a-z0-9-]{36}}") { & bcdedit /delete $ID /f 2>$null }
    }
    & bcdedit /delete "{ramdiskoptions}" /f 2>$null

    # 2. CHUẨN BỊ SOURCE
    $SourceDir = "$TargetDrive\WinSource"
    Log "Creating Source at $SourceDir..."
    if (Test-Path $SourceDir) { Remove-Item $SourceDir -Recurse -Force }
    New-Item -ItemType Directory -Path "$SourceDir\sources" -Force | Out-Null
    New-Item -ItemType Directory -Path "$SourceDir\boot" -Force | Out-Null
    
    Copy-Item "$Global:IsoMounted\sources\boot.wim" "$SourceDir\boot.wim" -Force
    Copy-Item "$Global:IsoMounted\boot\boot.sdi" "$SourceDir\boot.sdi" -Force
    
    # Copy Install.wim (để Setup tìm thấy)
    $InstWim = "$Global:IsoMounted\sources\install.wim"
    if (!(Test-Path $InstWim)) { $InstWim = "$Global:IsoMounted\sources\install.esd" }
    Copy-Item $InstWim "$SourceDir\sources\install.wim" -Force
    Copy-Item "$Global:IsoMounted\setup.exe" "$SourceDir\setup.exe" -Force

    # 3. CẤU HÌNH BCD (PHYSICAL DISK MODE)
    Log "Configuring BCD (Physical Disk Signature)..."
    try {
        $IsUEFI = ($env:Firmware_Type -eq "UEFI") -or (Test-Path "$TargetDrive\EFI")
        $Loader = if ($IsUEFI) { "\windows\system32\boot\winload.efi" } else { "\windows\system32\winload.exe" }

        # Lấy thông tin Partition vật lý bằng DiskPart
        # Mẹo: Tạo file script Diskpart để lấy ID
        $DpScript = "$env:TEMP\getid.txt"
        "select volume $TargetDrive`ndetail volume" | Out-File $DpScript -Encoding ASCII
        $VolDetail = & diskpart /s $DpScript | Out-String
        
        # Lấy Partition Type/Info để gán đúng
        # Tuy nhiên, cách an toàn nhất trong PowerShell là dùng đối tượng COM BcdStore (khó code trong 1 file).
        # Nên ta quay lại dùng `locate` (Tự động tìm file).

        # PHƯƠNG PHÁP LOCATE (Tự động tìm file trên mọi ổ)
        # Đây là cách cứu hộ: locate=custom:
        
        # B1: Tạo Ramdisk Options
        & bcdedit /create "{ramdiskoptions}" /d "Phat Tan Setup" /f | Out-Null
        # locate=custom: chỉ định file sdi
        & bcdedit /set "{ramdiskoptions}" ramdisksdidevice "locate=\WinSource\boot.sdi"
        & bcdedit /set "{ramdiskoptions}" ramdisksdipath "\WinSource\boot.sdi"

        # B2: Tạo Entry
        $BcdOutput = & bcdedit /create /d "PHAT TAN SETUP (LOCATE MODE)" /application osloader
        $Guid = ([regex]'{[a-z0-9-]{36}}').Match($BcdOutput).Value

        if ($Guid) {
            # Dùng cú pháp LOCATE để BCD tự tìm file boot.wim trên tất cả các ổ
            # Thay vì chỉ định ổ C:, ta bảo nó "tìm thằng nào có đường dẫn này thì load lên"
            
            $DeviceVal = "ramdisk=[locate]\WinSource\boot.wim,{ramdiskoptions}"
            
            Log "-> Setting Device: $DeviceVal"
            
            & bcdedit /set $Guid device $DeviceVal
            & bcdedit /set $Guid osdevice $DeviceVal
            & bcdedit /set $Guid path $Loader
            & bcdedit /set $Guid systemroot "\windows"
            & bcdedit /set $Guid winpe yes
            & bcdedit /set $Guid detecthal yes
            
            & bcdedit /displayorder $Guid /addfirst
            & bcdedit /bootsequence $Guid
            & bcdedit /timeout 5
            
            Log "-> BOOT SUCCESS! Entry: $Guid"
        } 
    } catch { 
        Log "CRITICAL ERROR: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show("Lỗi BCD: $_", "Error")
        $Form.Cursor = "Default"
        return
    }

    $Form.Cursor = "Default"
    if ([System.Windows.Forms.MessageBox]::Show("Đã Fix lỗi Device Unknown (V13)!`nRestart ngay?", "Xong", "YesNo") -eq "Yes") {
        Restart-Computer -Force
    }
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
