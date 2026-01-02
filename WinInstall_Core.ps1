<#
    WININSTALL CORE V9.0 (BOOT REPAIR EDITION)
    Author: Phat Tan PC
    Updates:
    - FIX "No OS Found": Smart BCDboot (Auto-detect System Partition).
    - FIX "Setup.exe runs": XML explicitly kills setup.exe first.
    - Added Bootsect & Bootrec for legacy MBR support.
#>

# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- ENCODING SETUP ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CONFIG ---
$Global:WinToHDD_Url = "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/WinToHDD.exe"
$Global:SevenZip_Url = "https://www.7-zip.org/a/7zr.exe"
$Global:SelectedDisk = $null
$Global:SelectedPart = $null
$Global:SelectedLetter = $null
$Global:IsoMounted = $null
$Global:WimFile = $null

# --- THEME ---
$Theme = @{ Bg=[System.Drawing.Color]::FromArgb(30,30,35); Panel=[System.Drawing.Color]::FromArgb(45,45,50); Text="White"; Cyan="Cyan"; Red="Salmon" }

# --- GUI INIT ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CORE INSTALLER V9.0 - BOOT FIXER"; $Form.Size = "950, 650"; $Form.StartPosition = "CenterScreen"; $Form.BackColor = $Theme.Bg; $Form.ForeColor = $Theme.Text; $Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

$LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text = "⚡ WINDOWS AUTO INSTALLER V9.0"; $LblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold); $LblTitle.ForeColor = $Theme.Cyan; $LblTitle.AutoSize = $true; $LblTitle.Location = "20, 15"; $Form.Controls.Add($LblTitle)

# === LEFT: CONFIG ===
$GrpConfig = New-Object System.Windows.Forms.GroupBox; $GrpConfig.Text = " 1. CẤU HÌNH "; $GrpConfig.Location = "20, 60"; $GrpConfig.Size = "520, 430"; $GrpConfig.ForeColor = "Gold"; $Form.Controls.Add($GrpConfig)

$LblISO = New-Object System.Windows.Forms.Label; $LblISO.Text = "File ISO:"; $LblISO.Location = "20,30"; $LblISO.AutoSize=$true; $LblISO.ForeColor="Silver"; $GrpConfig.Controls.Add($LblISO)
$CbISO = New-Object System.Windows.Forms.ComboBox; $CbISO.Location = "20,50"; $CbISO.Size = "300,30"; $CbISO.DropDownStyle="DropDownList"; $GrpConfig.Controls.Add($CbISO)

$BtnBrowse = New-Object System.Windows.Forms.Button; $BtnBrowse.Text = "📂..."; $BtnBrowse.Location = "330,49"; $BtnBrowse.Size = "50,25"; $BtnBrowse.BackColor="DimGray"; $GrpConfig.Controls.Add($BtnBrowse)
$BtnMount = New-Object System.Windows.Forms.Button; $BtnMount.Text = "💿 MOUNT"; $BtnMount.Location = "390,49"; $BtnMount.Size = "110,25"; $BtnMount.BackColor="DarkGreen"; $BtnMount.ForeColor="White"; $GrpConfig.Controls.Add($BtnMount)

$LblVer = New-Object System.Windows.Forms.Label; $LblVer.Text = "Phiên Bản (Source):"; $LblVer.Location = "20,90"; $LblVer.AutoSize=$true; $LblVer.ForeColor="Silver"; $GrpConfig.Controls.Add($LblVer)
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

New-BigBtn $GrpAction "MODE 2: AUTO DISM (SIÊU TỐC)`n🚀 Format C -> Bung Win -> Nạp Driver`n✅ FIX: No OS Found + Setup Loop" 40 "Orange" { Start-Auto-DISM }

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

# --- HELPER FUNCTIONS ---
function Get-7Zip {
    $7z = "$env:TEMP\7zr.exe"; if (Test-Path $7z) { return $7z }
    Log "Đang tải 7-Zip..."
    try { (New-Object System.Net.WebClient).DownloadFile($Global:SevenZip_Url, $7z); return $7z } 
    catch { Log "Lỗi tải 7-Zip. Kiểm tra mạng!"; return $null }
}

function Check-Iso-Path ($Drv, $IsoPath) {
    if ((Test-Path "$Drv\sources\install.wim") -or (Test-Path "$Drv\sources\install.esd")) { return $true }
    return $false
}

function Get-DriveList-Robust {
    $List = @()
    try {
        $Drives = Get-WmiObject Win32_LogicalDisk
        foreach ($D in $Drives) { $List += $D.DeviceID }
    } catch {
        67..90 | ForEach-Object { $L = [char]$_ + ":"; if (Test-Path $L) { $List += $L } }
    }
    return $List
}

# --- ROBUST PARTITION LOADER ---
function Load-Partitions {
    $GridPart.Rows.Clear(); $SysDrive = $env:SystemDrive.Replace(":","")
    $Loaded = $false

    try {
        if (Get-Command Get-Volume -ErrorAction SilentlyContinue) {
            $Parts = Get-Volume | Where-Object {$_.DriveType -eq 'Fixed'} | Sort-Object DriveLetter -ErrorAction Stop
            if ($Parts.Count -gt 0) {
                foreach ($P in $Parts) {
                    try { $Dsk = (Get-Partition -DriveLetter $P.DriveLetter).DiskNumber; $Prt = (Get-Partition -DriveLetter $P.DriveLetter).PartitionNumber } catch { $Dsk = "?"; $Prt = "?" }
                    $Info = if ($P.DriveLetter -eq $SysDrive) { " (WIN CŨ)" } else { "" }
                    $Row = $GridPart.Rows.Add($Dsk, $Prt, $P.DriveLetter, "$([math]::Round($P.Size/1GB,1)) GB", "$($P.FileSystemLabel)$Info")
                    if ($P.DriveLetter -eq $SysDrive) { $GridPart.Rows[$Row].Selected = $true; $Global:SelectedLetter = $P.DriveLetter }
                }
                if ($GridPart.Rows.Count -gt 0) { $Loaded = $true }
            }
        }
    } catch { Log "Lỗi Cmdlet hiện đại. Chuyển WMI..." }

    if (!$Loaded) {
        Log "-> Đang dùng WMI để quét ổ (WinLite Mode)..."
        try {
            $Disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
            foreach ($D in $Disks) {
                $Letter = $D.DeviceID.Replace(":",""); $SizeGB = [math]::Round($D.Size / 1GB, 1)
                $VolName = if ($D.VolumeName) { $D.VolumeName } else { "Local Disk" }
                $Info = if ($Letter -eq $SysDrive) { " (WIN CŨ)" } else { "" }
                $Row = $GridPart.Rows.Add("?", "?", $Letter, "$SizeGB GB", "$VolName$Info")
                if ($Letter -eq $SysDrive) { $GridPart.Rows[$Row].Selected = $true; $Global:SelectedLetter = $Letter }
            }
        } catch { Log "Lỗi WMI! Không thể đọc danh sách ổ đĩa." }
    }
}

# --- AGGRESSIVE UNMOUNT ---
function Unmount-All ($Silent = $true) {
    if (!$Silent) { Log "--- DỌN DẸP Ổ ẢO ---" }
    $Form.Cursor = "WaitCursor"
    if (Test-Path "$env:TEMP\WinInstall_Ext") { Remove-Item "$env:TEMP\WinInstall_Ext" -Recurse -Force -ErrorAction SilentlyContinue }
    if (Get-Command Dismount-DiskImage -ErrorAction SilentlyContinue) {
        try { Get-DiskImage -ImagePath "*" -ErrorAction SilentlyContinue | Dismount-DiskImage -ErrorAction SilentlyContinue | Out-Null } catch {}
    }
    try {
        $CDs = Get-WmiObject Win32_CDROMDrive
        foreach ($CD in $CDs) {
            $Letter = $CD.Drive
            if ($Letter -and ((Test-Path "$Letter\sources\install.wim") -or (Test-Path "$Letter\sources\install.esd"))) {
                Start-Process "mountvol" -ArgumentList "$Letter /D" -NoNewWindow -Wait
            }
        }
    } catch {}
    $Global:IsoMounted = $null; $CbIndex.Items.Clear(); $Form.Cursor = "Default"
}

# --- ENABLE AUTOMOUNT & START SERVICES ---
function Prepare-System-For-Mount {
    Log "🔧 Chuẩn bị hệ thống (Fix Automount)..."
    try {
        $Script = "$env:TEMP\dp_automount.txt"
        "automount enable`nautomount scrub" | Out-File $Script -Encoding ASCII
        Start-Process "diskpart" -ArgumentList "/s `"$Script`"" -NoNewWindow -Wait
        Remove-Item $Script -Force -ErrorAction SilentlyContinue
    } catch { Log "Lỗi Diskpart Automount." }

    try {
        $S = Get-Service "ShellHWDetection" -ErrorAction SilentlyContinue
        if ($S -and $S.Status -ne 'Running') {
            Set-Service "ShellHWDetection" -StartupType Automatic; Start-Service "ShellHWDetection"
            Log "-> ShellHWDetection: Started"
        }
        $V = Get-Service "vds" -ErrorAction SilentlyContinue
        if ($V -and $V.Status -ne 'Running') {
            Set-Service "vds" -StartupType Manual; Start-Service "vds"
            Log "-> Virtual Disk: Started"
        }
    } catch {}
    Start-Sleep 1
}

# --- SMART LETTER ASSIGN ---
function Smart-Assign-Letter {
    Log "⚠️ Đang tìm ổ bị ẩn..."
    try {
        $Vols = Get-WmiObject Win32_Volume | Where-Object { $_.DriveType -eq 5 -and $_.DriveLetter -eq $null }
        foreach ($V in $Vols) {
            $Available = 69..90 | ForEach-Object { [char]$_ + ":" } | Where-Object { !(Test-Path $_) } | Select-Object -First 1
            if ($Available) {
                Log "-> Gán ký tự $Available..."
                $V.DriveLetter = $Available; $V.Put(); Start-Sleep 1
                if (Test-Path $Available) { return $Available }
            }
        }
    } catch { Log "Lỗi gán ký tự tự động." }
    return $null
}

# --- 7-ZIP EXTRACT FALLBACK ---
function Extract-ISO-With-7Zip ($IsoPath) {
    Log "Unmount sạch sẽ trước khi xả nén..."
    Unmount-All -Silent $true
    Start-Sleep 2 

    $7z = Get-7Zip
    if (!$7z) { [System.Windows.Forms.MessageBox]::Show("Không thể tải 7-Zip!", "Lỗi"); return }
    $ExtDir = "$env:TEMP\WinInstall_Ext"
    if (!(Test-Path $ExtDir)) { New-Item -ItemType Directory -Path $ExtDir -Force | Out-Null }
    
    Get-ChildItem $ExtDir -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Log "⚠️ MODE CỨU HỘ: Đang giải nén file Install..."
    
    $Files = "sources/install.wim sources/install.esd sources/boot.wim boot/boot.sdi setup.exe"
    $Proc = Start-Process $7z -ArgumentList "x `"$IsoPath`" $Files -o`"$ExtDir`" -y" -NoNewWindow -Wait -PassThru
    
    if ($Proc.ExitCode -eq 0 -and (Check-Iso-Path $ExtDir $null)) {
        $Global:IsoMounted = $ExtDir
        Log "-> Giải nén OK: $ExtDir"; Get-WimInfo
    } else {
        Log "Lỗi 7-Zip: Code $($Proc.ExitCode)"
        [System.Windows.Forms.MessageBox]::Show("Giải nén thất bại. File ISO có thể bị hỏng hoặc bị khóa.", "Lỗi")
    }
}

# --- MAIN MOUNT LOGIC ---
function Mount-ISO {
    $ISO = $CbISO.SelectedItem; if (!$ISO) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn file ISO!"); return }
    $Form.Cursor = "WaitCursor"
    
    Unmount-All -Silent $true; Start-Sleep 1 
    Prepare-System-For-Mount 
    
    Log "--- MOUNT ($ISO) ---"
    $DrivesBefore = Get-DriveList-Robust
    $CmdletExists = [bool](Get-Command Mount-DiskImage -ErrorAction SilentlyContinue)

    if ($CmdletExists) {
        try {
            Mount-DiskImage -ImagePath $ISO -StorageType ISO -ErrorAction Stop | Out-Null
            
            Log "Đang quét ổ đĩa..."
            for ($i=0; $i -lt 8; $i++) {
                $AllDrives = Get-DriveList-Robust
                foreach ($D in $AllDrives) {
                    if ($DrivesBefore -notcontains $D) {
                        if (Check-Iso-Path $D $ISO) {
                            $Global:IsoMounted = $D; Log "-> Đã Mount tại: $D (OK)"; Get-WimInfo; $Form.Cursor = "Default"; return
                        }
                    }
                }
                Start-Sleep -Milliseconds 800
            }
            
            $NewLetter = Smart-Assign-Letter
            if ($NewLetter) {
                $Global:IsoMounted = $NewLetter; Log "-> Fix OK: $NewLetter"; Get-WimInfo; $Form.Cursor = "Default"; return
            }

        } catch { Log "Native Mount lỗi." }
    } else { Log "WinLite: Không có lệnh Mount-DiskImage." }

    Log "Chuyển sang chế độ giải nén (7-Zip)..."
    Extract-ISO-With-7Zip $ISO
    $Form.Cursor = "Default"
}

function Get-WimInfo {
    $Drive = $Global:IsoMounted; if (!$Drive) { return }
    $Wim = "$Drive\sources\install.wim"; if (!(Test-Path $Wim)) { $Wim = "$Drive\sources\install.esd" }
    $Global:WimFile = $Wim
    $CbIndex.Items.Clear()
    
    $DismPath = "$env:SystemRoot\System32\dism.exe"
    if (Test-Path $DismPath) {
        try {
            $Info = & $DismPath /Get-WimInfo /WimFile:$Wim; if ($Info) {
                $Indexes = $Info | Select-String "Index :"; $Names = $Info | Select-String "Name :"
                for ($i=0; $i -lt $Indexes.Count; $i++) { $CbIndex.Items.Add($Indexes[$i].ToString().Split(":")[1].Trim() + " - " + $Names[$i].ToString().Split(":")[1].Trim()) }
            }
        } catch {}
    } else { Log "Cảnh báo: Máy không có DISM.exe" }

    if ($CbIndex.Items.Count -eq 0) { $CbIndex.Items.Add("1 - Auto (Default)"); }
    $CbIndex.SelectedIndex = 0
}

# --- AUTO DISM (FIXED: KILL SETUP + SMART BCDBOOT) ---
function Start-Auto-DISM {
    if (!$Global:IsoMounted) { [System.Windows.Forms.MessageBox]::Show("Chưa Mount ISO!"); return }
    $IndexName = $CbIndex.SelectedItem; $Idx = if ($IndexName) { $IndexName.ToString().Split("-")[0].Trim() } else { 1 }
    
    if (!(Test-Path "$env:SystemRoot\System32\dism.exe")) { [System.Windows.Forms.MessageBox]::Show("Lỗi: WinLite này đã bị lược bỏ DISM.exe!", "Error"); return }
    if (!(Test-Path "$env:SystemRoot\System32\bcdboot.exe")) { [System.Windows.Forms.MessageBox]::Show("Lỗi: WinLite này đã bị lược bỏ BCDBOOT.exe!", "Error"); return }

    if ([System.Windows.Forms.MessageBox]::Show("XÁC NHẬN CÀI WIN (MODE 2)?", "Cảnh Báo", "YesNo", "Warning") -ne "Yes") { return }

    $Form.Cursor = "WaitCursor"; $Form.Text = "ĐANG XỬ LÝ..."
    $WorkDir = "$env:SystemDrive\WinInstall_Temp"; New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
    
    # Chọn ổ đĩa an toàn
    $SafeDrive = $null
    $Drives = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($D in $Drives) {
        if ($D.DeviceID -ne "$env:SystemDrive" -and $D.FreeSpace -gt 5368709120) { $SafeDrive = $D.DeviceID; break }
    }
    
    if (!$SafeDrive) {
        [System.Windows.Forms.MessageBox]::Show("Không tìm thấy ổ đĩa an toàn (Khác C:, trống > 5GB).", "Lỗi")
        $Form.Cursor = "Default"; return 
    }
    
    $SourceDir = "$SafeDrive\WinSource"; New-Item -ItemType Directory -Path $SourceDir -Force | Out-Null
    Log "Lưu bộ cài tại: $SourceDir"

    Log "Copying Install File..."
    Copy-Item $Global:WimFile "$SourceDir\install.wim" -Force
    Copy-Item "$Global:IsoMounted\sources\boot.wim" "$WorkDir\boot.wim" -Force
    Copy-Item "$Global:IsoMounted\boot\boot.sdi" "$WorkDir\boot.sdi" -Force

    $DrvCmd = ""
    if ($ChkDriver.Checked) {
        $DrvPath = "$SafeDrive\Drivers_Backup"; New-Item -ItemType Directory -Path $DrvPath -Force | Out-Null
        Log "Backup Driver..."
        & "$env:SystemRoot\System32\dism.exe" /online /export-driver /destination:"$DrvPath" | Out-Null
        $DrvCmd = "dism /Image:C:\ /Add-Driver /Driver:`"$DrvPath`" /Recurse`n"
    }

    # 1. TẠO SCRIPT CÀI ĐẶT (FIXED NO OS FOUND)
    # LƯU Ý: Bỏ tham số /s C: trong bcdboot để nó tự tìm phân vùng EFI/System
    $ScriptCmd = "@echo off`r`ntitle AUTO INSTALLER - PHAT TAN PC`r`ncolor 1f`r`ncls`r`n" +
                 "echo [1/6] DANG DIET SETUP.EXE (NEU CO)...`r`ntaskkill /F /IM setup.exe >nul 2>&1`r`n" +
                 "echo [2/6] DANG FORMAT O C...`r`nformat c: /q /y /fs:ntfs`r`n" +
                 "echo [3/6] DANG BUNG FILE IMAGE...`r`ndism /Apply-Image /ImageFile:`"$SourceDir\install.wim`" /Index:$Idx /ApplyDir:C:\`r`n" +
                 "echo [4/6] FIX BOOT (LEGACY)...`r`nbootsect /nt60 C: /force /mbr`r`n" +
                 "echo [5/6] DANG CAI BOOTLOADER (SMART)...`r`nbcdboot C:\Windows /f ALL`r`n" + $DrvCmd + 
                 "echo [6/6] HOAN TAT! TU DONG KHOI DONG LAI SAU 5 GIAY...`r`ntimeout /t 5`r`nwpeutil reboot"
    [IO.File]::WriteAllText("$SourceDir\AutoInstall.cmd", $ScriptCmd, [System.Text.Encoding]::ASCII)

    # 2. TẠO FILE RUN.CMD
    $RunCmd = "@echo off`r`nif exist `"$SourceDir\AutoInstall.cmd`" call `"$SourceDir\AutoInstall.cmd`""
    [IO.File]::WriteAllText("$SafeDrive\Run.cmd", $RunCmd, [System.Text.Encoding]::ASCII)

    # 3. TẠO XML (KILL SETUP FIRST)
    # Thêm lệnh giết Setup.exe vào đầu tiên trong XML
    $KillSetup = "taskkill /F /IM setup.exe"
    
    $CommandsBlock = ""
    $Order = 1
    
    # Lệnh 1: Giết setup.exe
    $CommandsBlock += "<RunSynchronousCommand wcm:action=`"add`"><Order>$Order</Order><Path>cmd /c $KillSetup</Path></RunSynchronousCommand>"
    $Order++

    # Các lệnh tiếp theo: Tìm và chạy Run.cmd
    for ($i=67; $i -le 90; $i++) {
        $L = [char]$i
        $Cmd = "cmd /c if exist ${L}:\Run.cmd ${L}:\Run.cmd"
        $CommandsBlock += "<RunSynchronousCommand wcm:action=`"add`"><Order>$Order</Order><Path>$Cmd</Path></RunSynchronousCommand>"
        $Order++
    }

    $XmlContent = "<?xml version=`"1.0`" encoding=`"utf-8`"?><unattend xmlns=`"urn:schemas-microsoft-com:unattend`"><settings pass=`"windowsPE`"><component name=`"Microsoft-Windows-Setup`" processorArchitecture=`"amd64`" publicKeyToken=`"31bf3856ad364e35`" language=`"neutral`" versionScope=`"nonSxS`"><RunSynchronous>$CommandsBlock</RunSynchronous></component></settings></unattend>"

    Log "Injecting Boot Triggers..."
    $AllDrives = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($D in $AllDrives) { 
        try { [IO.File]::WriteAllText("$($D.DeviceID)\autounattend.xml", $XmlContent, [System.Text.Encoding]::UTF8) } catch {}
    }

    Log "Moving Boot Files..."
    Move-Item "$WorkDir\boot.wim" "$env:SystemDrive\WinInstall.wim" -Force
    Move-Item "$WorkDir\boot.sdi" "$env:SystemDrive\boot.sdi" -Force
    Remove-Item $WorkDir -Recurse -Force

    # --- [BOOT MANAGER FIX V6] ---
    Log "Cấu hình Boot Manager..."
    
    $BootInfo = & "$env:SystemRoot\System32\bcdedit.exe" /enum "{current}"
    $IsUEFI = ($BootInfo | Select-String "winload.efi") -ne $null
    $LoaderPath = if ($IsUEFI) { "\windows\system32\boot\winload.efi" } else { "\windows\system32\boot\winload.exe" }
    
    & "$env:SystemRoot\System32\bcdedit.exe" /delete "{ramdiskoptions}" /f 2>$null 
    & "$env:SystemRoot\System32\bcdedit.exe" /create "{ramdiskoptions}" /d "WinInstall Ramdisk" 2>$null
    & "$env:SystemRoot\System32\bcdedit.exe" /set "{ramdiskoptions}" ramdisksdidevice "partition=$env:SystemDrive"
    & "$env:SystemRoot\System32\bcdedit.exe" /set "{ramdiskoptions}" ramdisksdipath "\boot.sdi"

    $Guid = [Guid]::NewGuid().ToString("B")
    & "$env:SystemRoot\System32\bcdedit.exe" /create $Guid /d "AUTO INSTALLER (Phat Tan PC)" /application osloader
    & "$env:SystemRoot\System32\bcdedit.exe" /set $Guid device "ramdisk=[$env:SystemDrive]\WinInstall.wim,{ramdiskoptions}"
    & "$env:SystemRoot\System32\bcdedit.exe" /set $Guid osdevice "ramdisk=[$env:SystemDrive]\WinInstall.wim,{ramdiskoptions}"
    & "$env:SystemRoot\System32\bcdedit.exe" /set $Guid path $LoaderPath
    & "$env:SystemRoot\System32\bcdedit.exe" /set $Guid systemroot "\windows"
    & "$env:SystemRoot\System32\bcdedit.exe" /set $Guid winpe yes
    & "$env:SystemRoot\System32\bcdedit.exe" /set $Guid detecthal yes
    & "$env:SystemRoot\System32\bcdedit.exe" /set $Guid nointegritychecks yes 
    & "$env:SystemRoot\System32\bcdedit.exe" /set $Guid testsigning yes

    & "$env:SystemRoot\System32\bcdedit.exe" /displayorder $Guid /addlast
    & "$env:SystemRoot\System32\bcdedit.exe" /bootsequence $Guid

    $Form.Cursor = "Default"
    if ([System.Windows.Forms.MessageBox]::Show("Đã thiết lập Boot thành công!`n`nLƯU Ý: Máy sẽ khởi động lại vào màn hình đen/xanh trong vài giây.`nNó sẽ TỰ ĐỘNG FORMAT C và CÀI WIN.`nĐừng tắt máy!", "Hoàn Tất", "YesNo", "Information") -eq "Yes") { Restart-Computer -Force }
}

# --- EVENTS ---
$BtnBrowse.Add_Click({ $OFD = New-Object System.Windows.Forms.OpenFileDialog; $OFD.Filter = "ISO|*.iso"; if ($OFD.ShowDialog() -eq "OK") { $CbISO.Items.Insert(0, $OFD.FileName); $CbISO.SelectedIndex = 0 } })
$BtnMount.Add_Click({ Mount-ISO })
$GridPart.Add_CellClick({ if ($_.RowIndex -ge 0) { $R = $GridPart.Rows[$_.RowIndex]; $Global:SelectedDisk = $R.Cells[0].Value; $Global:SelectedPart = $R.Cells[1].Value; $Global:SelectedLetter = $R.Cells[2].Value } })

Load-Partitions
$Scan = @("$env:USERPROFILE\Downloads", "D:", "E:", "F:"); foreach ($P in $Scan) { if(Test-Path $P){ Get-ChildItem $P -Filter "*.iso" -Recurse -Depth 1 | Where {$_.Length -gt 1GB} | ForEach { $CbISO.Items.Add($_.FullName) } } }
if ($CbISO.Items.Count -gt 0) { $CbISO.SelectedIndex = 0 }

$Form.ShowDialog() | Out-Null
