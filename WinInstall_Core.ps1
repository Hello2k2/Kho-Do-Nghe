# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- INIT ---
try { Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing } catch { Exit }
$ErrorActionPreference = "SilentlyContinue"
$DebugLog = "C:\PhatTan_Debug.txt"
$Global:SelectedDisk = 0
$Global:SelectedPart = 0

# --- DATABASE KEY (INTEGRATED) ---
$KeyDB = @{
    "Windows 10/11" = @{
        "Pro"          = "VK7JG-NPHTM-C97JM-9MPGT-3V66T"
        "Home"         = "YTMG3-N6DKC-DKB77-7M9GH-8HVX7"
        "Enterprise"   = "XGVPP-NMH47-7TTHJ-W3FW7-8HV2C"
        "Education"    = "6TP4R-GNPTD-KYYHQ-7B7DP-J447Y"
    }
    "Windows 8.1" = @{
        "Pro"          = "GCRJD-8NW9H-F2CDX-CCM8D-9D6T9"
        "Core"         = "334NH-RXG76-64THK-C7CKG-D3VPT" # Home
        "Enterprise"   = "MHF9N-XY6XB-WVXMC-BTDCT-MKKG7"
    }
    "Windows 7" = @{
        "Ultimate"     = "D4F6K-QK3RD-TMVMJ-BBMRX-3MBMV"
        "Professional" = "FJ82H-XT6CR-J8D7P-XQJJ2-GPDD4"
        "Home Premium" = "VQB3X-Q3KP8-WJ2H8-R6B6D-7QJB7"
        "Home Basic"   = "22MFQ-HDH7V-RBV79-QMVK9-PTMXQ"
        "Enterprise"   = "33PXH-7Y6KF-2VJC9-XBBR8-HVTHH"
    }
}

# --- LOG FUNCTION (ENHANCED) ---
function Write-DebugLog ($Message, $Type="INFO") {
    $Time = Get-Date -Format "HH:mm:ss"
    $Line = "[$Time] [$Type] $Message"
    $Line | Out-File -FilePath $DebugLog -Append -Encoding UTF8
    Write-Host $Line -ForegroundColor Cyan
}
if (Test-Path $DebugLog) { Remove-Item $DebugLog -Force }
Write-DebugLog "=== CORE MODULE START V14.0 (AUTO KEY) ===" "INIT"

# --- CONFIG ---
$WinToHDD_Url = "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/WinToHDD.exe"
$Global:DriverPath = "D:\Drivers_Backup_Auto"

# --- HELPER FUNCTIONS ---
function Dismount-All { Get-DiskImage -ImagePath * -ErrorAction SilentlyContinue | Dismount-DiskImage -ErrorAction SilentlyContinue | Out-Null }

function Mount-And-GetDrive ($IsoPath) {
    Write-DebugLog "Mounting ISO: $IsoPath" "DISK"
    Dismount-All
    try { Mount-DiskImage -ImagePath $IsoPath -StorageType ISO -ErrorAction Stop | Out-Null; Start-Sleep -Seconds 2 } catch { Write-DebugLog "Mount Failed!" "ERROR"; return $null }

    try { $Vol = Get-DiskImage -ImagePath $IsoPath | Get-Volume; if ($Vol) { $L="$($Vol.DriveLetter):"; if (Test-Path "$L\setup.exe") { return $L } } } catch {}
    $Drives = Get-PSDrive -PSProvider FileSystem
    foreach ($D in $Drives) { $R=$D.Root; if($R -in "C:\","A:\","B:\"){continue}; if((Test-Path "$R\setup.exe") -and (Test-Path "$R\bootmgr")){ return $R.TrimEnd("\") } }
    return $null
}

function Get-BiosMode { if (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State") { return "UEFI" } return "Legacy" }

# --- SMART KEY DETECTOR ---
function Get-SmartKey ($FullIndexName) {
    Write-DebugLog "Analysing OS Name: $FullIndexName" "KEY_LOGIC"
    $Name = $FullIndexName.ToLower()
    $VerGroup = $null
    $Edition = $null

    # 1. Detect Version Group
    if ($Name -match "windows 7") { $VerGroup = "Windows 7" }
    elseif ($Name -match "windows 8.1") { $VerGroup = "Windows 8.1" }
    elseif ($Name -match "windows 10" -or $Name -match "windows 11") { $VerGroup = "Windows 10/11" }
    
    if (!$VerGroup) { Write-DebugLog "-> Unknown Windows Version. Skip Key." "WARN"; return $null }

    # 2. Detect Edition
    if ($Name -match "enterprise") { $Edition = "Enterprise" }
    elseif ($Name -match "education") { $Edition = "Education" }
    elseif ($Name -match "ultimate") { $Edition = "Ultimate" }
    elseif ($Name -match "pro") { $Edition = "Pro" }
    elseif ($Name -match "home" -or $Name -match "core") { 
        if ($VerGroup -eq "Windows 7") {
             if ($Name -match "premium") { $Edition = "Home Premium" } else { $Edition = "Home Basic" }
        } elseif ($VerGroup -eq "Windows 8.1") { $Edition = "Core (Home)" } 
        else { $Edition = "Home" }
    }

    if ($Edition -and $KeyDB[$VerGroup][$Edition]) {
        $K = $KeyDB[$VerGroup][$Edition]
        Write-DebugLog "-> DETECTED: $VerGroup | $Edition" "SUCCESS"
        Write-DebugLog "-> KEY FOUND: $K" "SUCCESS"
        return $K
    }
    Write-DebugLog "-> No matching key in DB for: $Edition" "WARN"
    return $null
}

function Create-Boot-Entry ($WimPath) {
    try {
        $BcdList = bcdedit /enum /v | Out-String; $Lines = $BcdList -split "`r`n"
        for ($i=0; $i -lt $Lines.Count; $i++) { if ($Lines[$i] -match "description\s+CAI WIN TAM THOI") { for ($j=$i; $j -ge 0; $j--) { if ($Lines[$j] -match "identifier\s+{(.*)}") { cmd /c "bcdedit /delete {$($Matches[1])} /f"; break } } } }
        
        $Name="CAI WIN TAM THOI (Phat Tan PC)"; $Mode=Get-BiosMode; $Drive=$env:SystemDrive
        cmd /c "bcdedit /create {ramdiskoptions} /d `"Ramdisk Options`"" 2>$null
        cmd /c "bcdedit /set {ramdiskoptions} ramdisksdidevice partition=$Drive"; cmd /c "bcdedit /set {ramdiskoptions} ramdisksdipath \boot.sdi"
        $Output = cmd /c "bcdedit /create /d `"$Name`" /application osloader"; if ($Output -match '{([a-f0-9\-]+)}') { $ID = $matches[0] } else { return $false }
        cmd /c "bcdedit /set $ID device ramdisk=[$Drive]$WimPath,{ramdiskoptions}"; cmd /c "bcdedit /set $ID osdevice ramdisk=[$Drive]$WimPath,{ramdiskoptions}"
        cmd /c "bcdedit /set $ID systemroot \windows"; cmd /c "bcdedit /set $ID detecthal yes"; cmd /c "bcdedit /set $ID winpe yes"
        if ($Mode -eq "UEFI") { cmd /c "bcdedit /set $ID path \windows\system32\boot\winload.efi" } else { cmd /c "bcdedit /set $ID path \windows\system32\boot\winload.exe" }
        cmd /c "bcdedit /displayorder $ID /addlast"; cmd /c "bcdedit /bootsequence $ID"
        Write-DebugLog "BCD Entry Created: $ID ($Mode)" "BOOT"
        return $true
    } catch { Write-DebugLog "BCD Error: $($_.Exception.Message)" "ERROR"; return $false }
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CAI DAT WINDOWS (CORE V14.0 AUTO KEY)"
$Form.Size = New-Object System.Drawing.Size(850, 780)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30); $Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

# Fonts
$FontBold = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$FontNorm = New-Object System.Drawing.Font("Segoe UI", 10)

# 1. ISO
$GBIso = New-Object System.Windows.Forms.GroupBox; $GBIso.Text = "1. CHON FILE ISO"; $GBIso.Location = "20,10"; $GBIso.Size = "790,80"; $GBIso.ForeColor = "Cyan"; $Form.Controls.Add($GBIso)
$CmbISO = New-Object System.Windows.Forms.ComboBox; $CmbISO.Location = "20,30"; $CmbISO.Size = "630,30"; $CmbISO.Font = $FontNorm; $CmbISO.DropDownStyle = "DropDownList"; $GBIso.Controls.Add($CmbISO)
$BtnBrowse = New-Object System.Windows.Forms.Button; $BtnBrowse.Text = "MO FILE"; $BtnBrowse.Location = "660,28"; $BtnBrowse.Size = "110,30"; $BtnBrowse.BackColor = "Gray"; $BtnBrowse.ForeColor="White"; $BtnBrowse.Add_Click({ $OFD = New-Object System.Windows.Forms.OpenFileDialog; $OFD.Filter = "ISO (*.iso)|*.iso"; if ($OFD.ShowDialog() -eq "OK") { $CmbISO.Items.Insert(0, $OFD.FileName); $CmbISO.SelectedIndex = 0; Load-WimInfo } }); $GBIso.Controls.Add($BtnBrowse)

# 2. VERSION SELECTOR
$GBVer = New-Object System.Windows.Forms.GroupBox; $GBVer.Text = "2. CHON PHIEN BAN WINDOWS (INDEX)"; $GBVer.Location = "20,100"; $GBVer.Size = "790,80"; $GBVer.ForeColor = "Lime"; $Form.Controls.Add($GBVer)
$CmbEd = New-Object System.Windows.Forms.ComboBox; $CmbEd.Location = "20,30"; $CmbEd.Size = "750,30"; $CmbEd.Font = $FontNorm; $CmbEd.DropDownStyle = "DropDownList"; $GBVer.Controls.Add($CmbEd)

# 3. PARTITION SELECTOR
$GBPart = New-Object System.Windows.Forms.GroupBox; $GBPart.Text = "3. CHON PHAN VUNG CAI DAT (AUTO SELECT C:)"; $GBPart.Location = "20,190"; $GBPart.Size = "790,220"; $GBPart.ForeColor = "Yellow"; $Form.Controls.Add($GBPart)
$GridPart = New-Object System.Windows.Forms.DataGridView; $GridPart.Location = "20,30"; $GridPart.Size = "750,170"; $GridPart.BackgroundColor="Black"; $GridPart.ForeColor="Black"; $GridPart.AllowUserToAddRows=$false; $GridPart.RowHeadersVisible=$false; $GridPart.SelectionMode="FullRowSelect"; $GridPart.MultiSelect=$false; $GridPart.ReadOnly=$true; $GridPart.AutoSizeColumnsMode="Fill"
$GridPart.Columns.Add("Disk", "Disk"); $GridPart.Columns.Add("Part", "Part"); $GridPart.Columns.Add("Letter", "Ky Tu"); $GridPart.Columns.Add("Label", "Nhan"); $GridPart.Columns.Add("Size", "Dung Luong"); $GridPart.Columns.Add("Info", "Thong Tin")
$GridPart.Columns[0].FillWeight=10; $GridPart.Columns[1].FillWeight=10; $GridPart.Columns[2].FillWeight=10; $GridPart.Columns[5].FillWeight=40
$GridPart.Add_CellClick({ $R = $GridPart.SelectedRows[0]; $Global:SelectedDisk = $R.Cells[0].Value; $Global:SelectedPart = $R.Cells[1].Value }); $GBPart.Controls.Add($GridPart)

# 4. OPTIONS
$GBOpt = New-Object System.Windows.Forms.GroupBox; $GBOpt.Text = "4. TUY CHON KHAC"; $GBOpt.Location = "20,420"; $GBOpt.Size = "790,100"; $GBOpt.ForeColor = "White"; $Form.Controls.Add($GBOpt)
$CkBackup = New-Object System.Windows.Forms.CheckBox; $CkBackup.Text = "Sao luu Driver hien tai"; $CkBackup.Location = "20,30"; $CkBackup.AutoSize=$true; $CkBackup.Checked=$true; $GBOpt.Controls.Add($CkBackup)
$CkInject = New-Object System.Windows.Forms.CheckBox; $CkInject.Text = "Tao Script Auto-Install"; $CkInject.Location = "20,60"; $CkInject.AutoSize=$true; $CkInject.Checked=$true; $GBOpt.Controls.Add($CkInject)
$TxtPath = New-Object System.Windows.Forms.TextBox; $TxtPath.Text = $Global:DriverPath; $TxtPath.Location = "250,30"; $TxtPath.Size = "400,25"; $GBOpt.Controls.Add($TxtPath)

# 5. EXECUTE
$BtnBoot = New-Object System.Windows.Forms.Button; $BtnBoot.Text = "TAO BOOT TAM (Khoi dong lai va Cai dat)"; $BtnBoot.Location = "20,540"; $BtnBoot.Size = "790,50"; $BtnBoot.BackColor = "Magenta"; $BtnBoot.ForeColor = "White"; $BtnBoot.Font = $FontBold
$BtnBoot.Add_Click({ Start-Boot-Install }); $Form.Controls.Add($BtnBoot)

$BtnWTH = New-Object System.Windows.Forms.Button; $BtnWTH.Text = "DUNG WINTOHDD (Neu cach tren loi)"; $BtnWTH.Location = "20,600"; $BtnWTH.Size = "790,40"; $BtnWTH.BackColor = "Orange"; $BtnWTH.ForeColor = "Black"; $BtnWTH.Font = $FontBold
$BtnWTH.Add_Click({ $P="$env:TEMP\WinToHDD.exe"; if(!(Test-Path $P)){(New-Object Net.WebClient).DownloadFile($WinToHDD_Url, $P)}; Start-Process $P }); $Form.Controls.Add($BtnWTH)


# --- LOGIC LOAD INFO ---
function Load-WimInfo {
    $ISO = $CmbISO.SelectedItem; if (!$ISO) { return }
    $Form.Cursor = "WaitCursor"; $CmbEd.Items.Clear()
    
    [string]$Drive = Mount-And-GetDrive $ISO
    if ($Drive -match "([A-Z]:)") { $Drive = $matches[1] }
    if (!$Drive) { $Form.Cursor = "Default"; Write-DebugLog "Cannot Mount ISO" "ERROR"; return }

    $Wim = "$Drive\sources\install.wim"; if (!(Test-Path $Wim)) { $Wim = "$Drive\sources\install.esd" }
    
    try {
        $Info = dism /Get-WimInfo /WimFile:$Wim
        $Indexes = $Info | Select-String "Index :"; $Names = $Info | Select-String "Name :"
        for ($i=0; $i -lt $Indexes.Count; $i++) {
            $Idx = $Indexes[$i].ToString().Split(":")[1].Trim(); $Nam = $Names[$i].ToString().Split(":")[1].Trim()
            $CmbEd.Items.Add("$Idx - $Nam")
        }
        if ($CmbEd.Items.Count -gt 0) { $CmbEd.SelectedIndex = 0 }
    } catch {}
    $Form.Cursor = "Default"
}
$CmbISO.Add_SelectedIndexChanged({ Load-WimInfo })

function Load-Partitions {
    $GridPart.Rows.Clear()
    $Parts = Get-Partition
    $SysDrive = $env:SystemDrive.Replace(":", "")
    
    foreach ($P in $Parts) {
        $GB = [Math]::Round($P.Size / 1GB, 1)
        $Let = if ($P.DriveLetter) { $P.DriveLetter } else { "" }
        $Info = ""
        
        # Tu dong nhan dien o Boot va o Win
        if ($P.IsSystem) { $Info = "[BOOT/EFI]" }
        if ($P.DriveLetter -eq $SysDrive) { $Info = "[WINDOWS HIEN TAI]" }
        
        $RowId = $GridPart.Rows.Add($P.DiskNumber, $P.PartitionNumber, $Let, $P.GptType, "$GB GB", $Info)
        
        # Highlight
        if ($P.DriveLetter -eq $SysDrive) { 
            $GridPart.Rows[$RowId].Selected = $true 
            $GridPart.Rows[$RowId].DefaultCellStyle.BackColor = "LightGreen"
            $Global:SelectedDisk = $P.DiskNumber; $Global:SelectedPart = $P.PartitionNumber
        }
        if ($P.IsSystem) { $GridPart.Rows[$RowId].DefaultCellStyle.BackColor = "Yellow" }
    }
}

# --- START INSTALL LOGIC ---
function Start-Boot-Install {
    Write-DebugLog "STARTING INSTALL PROCESS..." "MAIN"
    $ISO = $CmbISO.SelectedItem
    if (!$ISO) { [System.Windows.Forms.MessageBox]::Show("Chua chon ISO!", "Loi"); return }
    
    # 1. UPDATE XML (INJECT INFO + SMART KEY)
    $XML = "$env:SystemDrive\autounattend.xml"
    if (!(Test-Path $XML)) { [System.Windows.Forms.MessageBox]::Show("Chua co file XML! Vui long dung Tool Config tao truoc.", "Canh Bao"); return }
    
    # Lấy thông tin từ GUI
    if ($CmbEd.SelectedItem) { 
        $FullString = $CmbEd.SelectedItem.ToString()
        $Idx = $FullString.Split("-")[0].Trim() 
        # TỰ ĐỘNG LẤY KEY TỪ TÊN
        $DetectedKey = Get-SmartKey $FullString
    } else { $Idx = 1; $DetectedKey = $null }
    
    $D_ID = $Global:SelectedDisk
    $P_ID = $Global:SelectedPart
    
    try {
        $Content = [IO.File]::ReadAllText($XML)
        
        # Cập nhật Partition đích (InstallTo)
        $InstallBlock = "<DiskID>$D_ID</DiskID><PartitionID>$P_ID</PartitionID>"
        $Content = $Content -replace "(?s)<InstallTo>.*?</InstallTo>", "<InstallTo>$InstallBlock</InstallTo>"

        # Cập nhật Image Index (InstallFrom)
        $ImgBlock = "<InstallFrom><MetaData wcm:action=`"add`"><Key>/IMAGE/INDEX</Key><Value>$Idx</Value></MetaData></InstallFrom>"
        if ($Content -match "<InstallFrom>") {
            $Content = $Content -replace "(?s)<InstallFrom>.*?</InstallFrom>", $ImgBlock
        } else {
            $Content = $Content -replace "<OSImage>", "<OSImage>$ImgBlock"
        }

        # --- KEY INJECTION LOGIC ---
        # 1. Xoa Key cu neu con sot
        $Content = $Content -replace "(?s)\s*<ProductKey>.*?</ProductKey>", ""
        
        # 2. Neu tim thay Key, nhet vao UserData
        if ($DetectedKey) {
            Write-DebugLog "Injecting Product Key to XML: $DetectedKey" "XML"
            $KeyBlock = "<ProductKey><Key>$DetectedKey</Key><WillShowUI>OnError</WillShowUI></ProductKey>"
            # Tim the <UserData> de nhet Key vao sau do
            if ($Content -match "<UserData>") {
                $Content = $Content -replace "<UserData>", "<UserData>$KeyBlock"
            }
        } else {
             Write-DebugLog "No Key to inject. Clean install without key." "XML"
        }

        [IO.File]::WriteAllText($XML, $Content)
        Write-DebugLog "XML Saved. Disk:$D_ID Part:$P_ID Idx:$Idx" "SUCCESS"
    } catch { 
        [System.Windows.Forms.MessageBox]::Show("Loi update XML: $($_.Exception.Message)", "Error")
        Write-DebugLog "XML Update Failed: $($_.Exception.Message)" "CRITICAL"
        return 
    }

    # 2. BACKUP DRIVER
    if ($CkBackup.Checked) {
        Write-DebugLog "Backing up Drivers..." "DRIVER"
        $Path = $TxtPath.Text
        if (!(Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
        Start-Process "pnputil.exe" -ArgumentList "/export-driver * `"$Path`"" -Wait -NoNewWindow
        if ($CkInject.Checked) { Set-Content -Path "$Path\1_CLICK_INSTALL_DRIVER.bat" -Value "@echo off`npnputil /add-driver `"%~dp0*.inf`" /subdirs /install`npause" }
        Write-DebugLog "Driver Backup Done." "DRIVER"
    }

    # 3. PREPARE BOOT
    $Form.Text = "DANG TAO BOOT TAM..."
    $Drive = Mount-And-GetDrive $ISO
    if ($Drive -match "([A-Z]:)") { $Drive = $matches[1] }
    
    $SysDrive = $env:SystemDrive
    $DestWim = "$SysDrive\WinInstall_Boot.wim"
    
    # SAFE COPY
    Write-DebugLog "Copying Boot WIM..." "COPY"
    $Temp = "C:\WinInstall_Temp"; New-Item -ItemType Directory -Path $Temp -Force | Out-Null
    Copy-Item "$Drive\sources\boot.wim" "$Temp\boot.wim" -Force
    Copy-Item "$Drive\boot\boot.sdi" "$Temp\boot.sdi" -Force
    Move-Item "$Temp\boot.wim" "$SysDrive\WinInstall_Boot.wim" -Force
    Move-Item "$Temp\boot.sdi" "$SysDrive\boot.sdi" -Force
    Remove-Item $Temp -Recurse -Force

    if (Test-Path $DestWim) {
        # Copy XML vào panther để chắc ăn
        $Panther = "$SysDrive\Windows\Panther"
        if (!(Test-Path $Panther)) { New-Item -ItemType Directory -Path $Panther -Force | Out-Null }
        Copy-Item $XML "$Panther\unattend.xml" -Force
        Write-DebugLog "XML Copied to Panther." "COPY"

        if (Create-Boot-Entry "\WinInstall_Boot.wim") {
             Write-DebugLog "ALL DONE. READY TO RESTART." "SUCCESS"
             if ([System.Windows.Forms.MessageBox]::Show("DA XONG! Log file: $DebugLog `nKhoi dong lai ngay?", "Thanh Cong", "YesNo") -eq "Yes") { Restart-Computer -Force }
        }
    } else { 
        [System.Windows.Forms.MessageBox]::Show("Loi copy file Boot!", "Loi") 
        Write-DebugLog "Copy Boot File Failed!" "CRITICAL"
    }
}

# --- AUTO SCAN ---
$Form.Add_Shown({ 
    Load-Partitions
    $ScanPaths = @("$env:USERPROFILE\Downloads", "D:", "E:", "F:")
    foreach ($P in $ScanPaths) { if (Test-Path $P) { Get-ChildItem $P -Filter "*.iso" -Recurse -Depth 1 | Where {$_.Length -gt 500MB} | ForEach { $CmbISO.Items.Add($_.FullName) } } }
    if ($CmbISO.Items.Count -gt 0) { $CmbISO.SelectedIndex = 0; Load-WimInfo }
})

$Form.ShowDialog() | Out-Null
