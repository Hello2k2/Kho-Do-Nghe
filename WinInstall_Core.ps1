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
$XML_Url = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/refs/heads/main/autounattend.xml"

# --- KEY DATABASE ---
$KeyDB = @{
    "Windows 10/11" = @{ "Pro" = "VK7JG-NPHTM-C97JM-9MPGT-3V66T"; "Home" = "YTMG3-N6DKC-DKB77-7M9GH-8HVX7"; "Home Single Language" = "BT79Q-G7N6G-PGBYW-4YWX6-6F4BT"; "Enterprise" = "XGVPP-NMH47-7TTHJ-W3FW7-8HV2C"; "Education" = "6TP4R-GNPTD-KYYHQ-7B7DP-J447Y" }
    "Windows 8.1" = @{ "Pro" = "GCRJD-8NW9H-F2CDX-CCM8D-9D6T9"; "Core" = "334NH-RXG76-64THK-C7CKG-D3VPT"; "Enterprise" = "MHF9N-XY6XB-WVXMC-BTDCT-MKKG7" }
    "Windows 7" = @{ "Ultimate" = "D4F6K-QK3RD-TMVMJ-BBMRX-3MBMV"; "Professional" = "FJ82H-XT6CR-J8D7P-XQJJ2-GPDD4"; "Home Premium" = "VQB3X-Q3KP8-WJ2H8-R6B6D-7QJB7"; "Enterprise" = "33PXH-7Y6KF-2VJC9-XBBR8-HVTHH" }
}

function Write-DebugLog ($Message, $Type="INFO") {
    $Line = "[$(Get-Date -Format 'HH:mm:ss')] [$Type] $Message"; $Line | Out-File -FilePath $DebugLog -Append -Encoding UTF8; Write-Host $Line -ForegroundColor Cyan
}
if (Test-Path $DebugLog) { Remove-Item $DebugLog -Force }
Write-DebugLog "=== CORE MODULE V23.0 (PLACEHOLDER FIX) ===" "INIT"

# --- HELPER FUNCTIONS ---
function Mount-And-GetDrive ($IsoPath) {
    Write-DebugLog "Mounting ISO: $IsoPath" "DISK"
    Get-DiskImage -ImagePath * | Dismount-DiskImage | Out-Null
    try { Mount-DiskImage -ImagePath $IsoPath -StorageType ISO -ErrorAction Stop | Out-Null; Start-Sleep -Seconds 2 } catch { Write-DebugLog "Mount Failed!" "ERROR"; return $null }
    try { $Vol = Get-DiskImage -ImagePath $IsoPath | Get-Volume; if ($Vol) { $L="$($Vol.DriveLetter):"; if (Test-Path "$L\setup.exe") { return $L } } } catch {}
    $Drives = Get-PSDrive -PSProvider FileSystem; foreach ($D in $Drives) { $R=$D.Root; if($R -in "C:\","A:\","B:\"){continue}; if((Test-Path "$R\setup.exe") -and (Test-Path "$R\bootmgr")){ return $R.TrimEnd("\") } }
    return $null
}

function Get-BiosMode { if (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State") { return "UEFI" } return "Legacy" }

function Get-SmartKey ($FullIndexName) {
    $Name = $FullIndexName.ToLower(); $VerGroup = $null; $Edition = $null
    if ($Name -match "windows 7") { $VerGroup = "Windows 7" } elseif ($Name -match "windows 8.1") { $VerGroup = "Windows 8.1" } elseif ($Name -match "windows 10" -or $Name -match "windows 11") { $VerGroup = "Windows 10/11" }
    if (!$VerGroup) { return $null }
    if ($Name -match "enterprise") { $Edition = "Enterprise" } elseif ($Name -match "education") { $Edition = "Education" } elseif ($Name -match "ultimate") { $Edition = "Ultimate" } elseif ($Name -match "pro") { $Edition = "Pro" } elseif ($Name -match "home" -or $Name -match "core") { if ($VerGroup -eq "Windows 7") { if ($Name -match "premium") { $Edition = "Home Premium" } else { $Edition = "Home Basic" } } elseif ($VerGroup -eq "Windows 8.1") { $Edition = "Core" } else { if ($Name -match "single language") { $Edition = "Home Single Language" } else { $Edition = "Home" } } }
    if ($Edition -and $KeyDB[$VerGroup][$Edition]) { $K = $KeyDB[$VerGroup][$Edition]; Write-DebugLog "KEY DETECTED: $K" "SUCCESS"; return $K }
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
        cmd /c "bcdedit /set $ID device ramdisk=[$Drive]$WimPath,{ramdiskoptions}"; cmd /c "bcdedit /set $ID osdevice ramdisk=[$Drive]$WimPath,{ramdiskoptions}"; cmd /c "bcdedit /set $ID systemroot \windows"; cmd /c "bcdedit /set $ID detecthal yes"; cmd /c "bcdedit /set $ID winpe yes"
        if ($Mode -eq "UEFI") { cmd /c "bcdedit /set $ID path \windows\system32\boot\winload.efi" } else { cmd /c "bcdedit /set $ID path \windows\system32\boot\winload.exe" }
        cmd /c "bcdedit /displayorder $ID /addlast"; cmd /c "bcdedit /bootsequence $ID"
        return $true
    } catch { return $false }
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form; $Form.Text = "CAI DAT WINDOWS (CORE V23.0)"; $Form.Size = "850, 780"; $Form.StartPosition = "CenterScreen"; $Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30); $Form.ForeColor = "White"; $Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false
$FontBold = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold); $FontNorm = New-Object System.Drawing.Font("Segoe UI", 10)

$GBIso = New-Object System.Windows.Forms.GroupBox; $GBIso.Text = "1. CHON FILE ISO"; $GBIso.Location = "20,10"; $GBIso.Size = "790,80"; $GBIso.ForeColor = "Cyan"; $Form.Controls.Add($GBIso)
$CmbISO = New-Object System.Windows.Forms.ComboBox; $CmbISO.Location = "20,30"; $CmbISO.Size = "630,30"; $CmbISO.Font = $FontNorm; $CmbISO.DropDownStyle = "DropDownList"; $GBIso.Controls.Add($CmbISO)
$BtnBrowse = New-Object System.Windows.Forms.Button; $BtnBrowse.Text = "MO FILE"; $BtnBrowse.Location = "660,28"; $BtnBrowse.Size = "110,30"; $BtnBrowse.BackColor = "Gray"; $BtnBrowse.ForeColor="White"; $BtnBrowse.Add_Click({ $OFD = New-Object System.Windows.Forms.OpenFileDialog; $OFD.Filter = "ISO (*.iso)|*.iso"; if ($OFD.ShowDialog() -eq "OK") { $CmbISO.Items.Insert(0, $OFD.FileName); $CmbISO.SelectedIndex = 0; Load-WimInfo } }); $GBIso.Controls.Add($BtnBrowse)

$GBVer = New-Object System.Windows.Forms.GroupBox; $GBVer.Text = "2. CHON PHIEN BAN WINDOWS"; $GBVer.Location = "20,100"; $GBVer.Size = "790,80"; $GBVer.ForeColor = "Lime"; $Form.Controls.Add($GBVer)
$CmbEd = New-Object System.Windows.Forms.ComboBox; $CmbEd.Location = "20,30"; $CmbEd.Size = "750,30"; $CmbEd.Font = $FontNorm; $CmbEd.DropDownStyle = "DropDownList"; $GBVer.Controls.Add($CmbEd)

$GBPart = New-Object System.Windows.Forms.GroupBox; $GBPart.Text = "3. CHON O CUNG (CLICK CHON 1 DONG)"; $GBPart.Location = "20,190"; $GBPart.Size = "790,220"; $GBPart.ForeColor = "Yellow"; $Form.Controls.Add($GBPart)
$GridPart = New-Object System.Windows.Forms.DataGridView; $GridPart.Location = "20,30"; $GridPart.Size = "750,170"; $GridPart.BackgroundColor="Black"; $GridPart.ForeColor="Black"; $GridPart.AllowUserToAddRows=$false; $GridPart.RowHeadersVisible=$false; $GridPart.SelectionMode="FullRowSelect"; $GridPart.MultiSelect=$false; $GridPart.ReadOnly=$true; $GridPart.AutoSizeColumnsMode="Fill"
$GridPart.Columns.Add("Disk", "Disk"); $GridPart.Columns.Add("Part", "Part"); $GridPart.Columns.Add("Letter", "Ky Tu"); $GridPart.Columns.Add("Label", "Nhan"); $GridPart.Columns.Add("Size", "Dung Luong"); $GridPart.Columns.Add("Info", "Thong Tin")
$GridPart.Columns[0].FillWeight=10; $GridPart.Columns[1].FillWeight=10; $GridPart.Columns[2].FillWeight=10; $GridPart.Columns[5].FillWeight=40
$GridPart.Add_CellClick({ $R = $GridPart.SelectedRows[0]; $Global:SelectedDisk = $R.Cells[0].Value; $Global:SelectedPart = $R.Cells[1].Value }); $GBPart.Controls.Add($GridPart)

$GBOpt = New-Object System.Windows.Forms.GroupBox; $GBOpt.Text = "4. TUY CHON KHAC"; $GBOpt.Location = "20,420"; $GBOpt.Size = "790,100"; $GBOpt.ForeColor = "White"; $Form.Controls.Add($GBOpt)
$CkBackup = New-Object System.Windows.Forms.CheckBox; $CkBackup.Text = "Sao luu Driver hien tai"; $CkBackup.Location = "20,30"; $CkBackup.AutoSize=$true; $CkBackup.Checked=$true; $GBOpt.Controls.Add($CkBackup)
$CkSkipKey = New-Object System.Windows.Forms.CheckBox; $CkSkipKey.Text = "BO QUA KEY (Tich vao neu bi loi Key XML)"; $CkSkipKey.Location = "20,60"; $CkSkipKey.AutoSize=$true; $CkSkipKey.Checked=$false; $CkSkipKey.ForeColor="Red"; $GBOpt.Controls.Add($CkSkipKey)
$TxtPath = New-Object System.Windows.Forms.TextBox; $TxtPath.Text = "$env:SystemDrive\Drivers_Backup_Auto"; $TxtPath.Location = "300,30"; $TxtPath.Size = "350,25"; $GBOpt.Controls.Add($TxtPath)

$BtnBoot = New-Object System.Windows.Forms.Button; $BtnBoot.Text = "TAO BOOT TAM (Khoi dong lai va Cai dat)"; $BtnBoot.Location = "20,540"; $BtnBoot.Size = "790,50"; $BtnBoot.BackColor = "Magenta"; $BtnBoot.ForeColor = "White"; $BtnBoot.Font = $FontBold
$BtnBoot.Add_Click({ Start-Boot-Install }); $Form.Controls.Add($BtnBoot)

$BtnWTH = New-Object System.Windows.Forms.Button; $BtnWTH.Text = "DUNG WINTOHDD (Neu cach tren loi)"; $BtnWTH.Location = "20,600"; $BtnWTH.Size = "790,40"; $BtnWTH.BackColor = "Orange"; $BtnWTH.ForeColor = "Black"; $BtnWTH.Font = $FontBold
$BtnWTH.Add_Click({ $P="$env:TEMP\WinToHDD.exe"; if(!(Test-Path $P)){(New-Object Net.WebClient).DownloadFile("https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/WinToHDD.exe", $P)}; Start-Process $P }); $Form.Controls.Add($BtnWTH)

function Load-WimInfo {
    $ISO = $CmbISO.SelectedItem; if (!$ISO) { return }
    $Form.Cursor = "WaitCursor"; $CmbEd.Items.Clear()
    [string]$Drive = Mount-And-GetDrive $ISO
    if ($Drive -match "([A-Z]:)") { $Drive = $matches[1] }
    if (!$Drive) { $Form.Cursor = "Default"; Write-DebugLog "Cannot Mount ISO" "ERROR"; return }
    $Wim = "$Drive\sources\install.wim"; if (!(Test-Path $Wim)) { $Wim = "$Drive\sources\install.esd" }
    try { $Info = dism /Get-WimInfo /WimFile:$Wim; $Indexes = $Info | Select-String "Index :"; $Names = $Info | Select-String "Name :"; for ($i=0; $i -lt $Indexes.Count; $i++) { $Idx = $Indexes[$i].ToString().Split(":")[1].Trim(); $Nam = $Names[$i].ToString().Split(":")[1].Trim(); $CmbEd.Items.Add("$Idx - $Nam") }; if ($CmbEd.Items.Count -gt 0) { $CmbEd.SelectedIndex = 0 } } catch {}
    $Form.Cursor = "Default"
}
$CmbISO.Add_SelectedIndexChanged({ Load-WimInfo })

function Load-Partitions {
    $GridPart.Rows.Clear(); $SysDrive = $env:SystemDrive.Replace(":", "")
    $AutoSelected = $false
    Write-DebugLog "Scanning Partitions (Hybrid)..." "DISK"
    $Parts = Get-Partition -ErrorAction SilentlyContinue
    if ($Parts -and $Parts.Count -gt 0) {
        foreach ($P in $Parts) {
            $GB = [Math]::Round($P.Size / 1GB, 1); $Let = if ($P.DriveLetter) { $P.DriveLetter } else { "" }
            $Info = ""; if ($P.IsSystem) { $Info = "[BOOT/EFI]" }; if ($P.DriveLetter -eq $SysDrive) { $Info = "[WINDOWS HIEN TAI]" }
            $RowId = $GridPart.Rows.Add($P.DiskNumber, $P.PartitionNumber, $Let, $P.GptType, "$GB GB", $Info)
            if ($P.DriveLetter -eq $SysDrive) { $GridPart.Rows[$RowId].Selected = $true; $Global:SelectedDisk = $P.DiskNumber; $Global:SelectedPart = $P.PartitionNumber; $AutoSelected = $true }
        }
    } else {
        try {
            $Partitions = Get-WmiObject Win32_DiskPartition
            foreach ($P in $Partitions) {
                $DiskIdx = $P.DiskIndex; $PartIdx = $P.Index + 1; $SizeGB = [Math]::Round($P.Size / 1GB, 1); $Letter = ""
                try { $LogDisk = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($P.DeviceID)'} WHERE AssocClass=Win32_LogicalDiskToPartition"; if ($LogDisk) { $Letter = $LogDisk.DeviceID.Replace(":","") } } catch {}
                $Info = ""; if ($Letter -eq $SysDrive) { $Info = "[WINDOWS HIEN TAI]" }
                $RowId = $GridPart.Rows.Add($DiskIdx, $PartIdx, $Letter, $P.Type, "$SizeGB GB", $Info)
                if ($Letter -eq $SysDrive) { $GridPart.Rows[$RowId].Selected = $true; $Global:SelectedDisk = $DiskIdx; $Global:SelectedPart = $PartIdx; $AutoSelected = $true }
            }
        } catch {}
    }
}

function Start-Boot-Install {
    $ISO = $CmbISO.SelectedItem
    if (!$ISO) { [System.Windows.Forms.MessageBox]::Show("Chua chon ISO!", "Loi"); return }
    if ($Global:SelectedPart -eq 0) { [System.Windows.Forms.MessageBox]::Show("LOI: BAN CHUA CHON O CUNG!", "Loi"); return }
    
    $XML = "$env:SystemDrive\autounattend.xml"
    if (!(Test-Path $XML)) { 
        try { 
            [System.Net.ServicePointManager]::SecurityProtocol = 3072
            (New-Object Net.WebClient).DownloadFile($XML_Url, $XML) 
        } catch { [System.Windows.Forms.MessageBox]::Show("Loi tai XML goc! Chay Tool Config truoc.", "Error"); return }
    } else { Write-DebugLog "Using existing XML." "CONFIG" }

    if ($CmbEd.SelectedItem) { $FullString = $CmbEd.SelectedItem.ToString(); $Idx = $FullString.Split("-")[0].Trim(); $DetectedKey = Get-SmartKey $FullString } else { $Idx = 1; $DetectedKey = $null }
    $D_ID = $Global:SelectedDisk; $P_ID = $Global:SelectedPart
    
    # --- PRE-PROCESS: FIX PLACEHOLDERS (TEXT MODE) ---
    try {
        $RawContent = [IO.File]::ReadAllText($XML)
        if ($RawContent.Contains("%INSTALLTO%")) {
             Write-DebugLog "Replacing Placeholders..." "FIX"
             # Thay the tam placeholder thanh the chuan de DOM khong bi loi
             $RawContent = $RawContent.Replace("%INSTALLTO%", "<DiskID>0</DiskID><PartitionID>0</PartitionID>")
             $RawContent = $RawContent.Replace("%PRODUCTKEY%", "")
             [IO.File]::WriteAllText($XML, $RawContent)
        }
    } catch { Write-DebugLog "Pre-process failed: $($_.Exception.Message)" "WARN" }

    # --- DOM MANIPULATION ---
    try {
        $xml = [xml](Get-Content $XML)
        
        # 1. Update Disk/Partition (Duyet qua moi component Setup - x86/amd64)
        $InstallTos = $xml.GetElementsByTagName("InstallTo")
        foreach ($IT in $InstallTos) {
            # Tim hoac Tao DiskID
            $DNode = $IT.SelectSingleNode("*[local-name()='DiskID']")
            if (!$DNode) { $DNode = $xml.CreateElement("DiskID", "urn:schemas-microsoft-com:unattend"); [void]$IT.AppendChild($DNode) }
            $DNode.InnerText = $D_ID.ToString()

            # Tim hoac Tao PartitionID
            $PNode = $IT.SelectSingleNode("*[local-name()='PartitionID']")
            if (!$PNode) { $PNode = $xml.CreateElement("PartitionID", "urn:schemas-microsoft-com:unattend"); [void]$IT.AppendChild($PNode) }
            $PNode.InnerText = $P_ID.ToString()
        }

        # 2. Update Index
        $Keys = $xml.GetElementsByTagName("Key")
        foreach ($K in $Keys) { 
            if ($K.InnerText -eq "/IMAGE/INDEX") { 
                # Dung ParentNode de tim Value an toan hon
                $Val = $K.ParentNode.SelectSingleNode("*[local-name()='Value']")
                if ($Val) { $Val.InnerText = $Idx.ToString() }
            } 
        }

        # 3. Inject Key
        if ($CkSkipKey.Checked) {
            Write-DebugLog "USER SKIP KEY." "USER_OPT"
        } elseif ($DetectedKey) {
            Write-DebugLog "Injecting Key: $DetectedKey" "XML"
            $UserDatas = $xml.GetElementsByTagName("UserData")
            foreach ($UD in $UserDatas) {
                $OldKey = $UD.SelectSingleNode("*[local-name()='ProductKey']")
                if ($OldKey) { [void]$UD.RemoveChild($OldKey) }
                
                $pkNode = $xml.CreateElement("ProductKey", "urn:schemas-microsoft-com:unattend")
                $kNode = $xml.CreateElement("Key", "urn:schemas-microsoft-com:unattend"); $kNode.InnerText = $DetectedKey; [void]$pkNode.AppendChild($kNode)
                $uiNode = $xml.CreateElement("WillShowUI", "urn:schemas-microsoft-com:unattend"); $uiNode.InnerText = "OnError"; [void]$pkNode.AppendChild($uiNode)
                [void]$UD.PrependChild($pkNode)
            }
        }

        $xml.Save($XML)
        Write-DebugLog "XML Updated via DOM." "SUCCESS"
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi XML DOM: $($_.Exception.Message)", "Error"); return }

    if ($CkBackup.Checked) {
        $Path = $TxtPath.Text; if (!(Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
        Start-Process "pnputil.exe" -ArgumentList "/export-driver * `"$Path`"" -Wait -NoNewWindow
    }

    $Form.Text = "DANG TAO BOOT TAM..."
    $Drive = Mount-And-GetDrive $ISO; if ($Drive -match "([A-Z]:)") { $Drive = $matches[1] }
    $Temp = "C:\WinInstall_Temp"; New-Item -ItemType Directory -Path $Temp -Force | Out-Null
    Copy-Item "$Drive\sources\boot.wim" "$Temp\boot.wim" -Force; Copy-Item "$Drive\boot\boot.sdi" "$Temp\boot.sdi" -Force
    Move-Item "$Temp\boot.wim" "$env:SystemDrive\WinInstall_Boot.wim" -Force; Move-Item "$Temp\boot.sdi" "$env:SystemDrive\boot.sdi" -Force
    Remove-Item $Temp -Recurse -Force
    if (Test-Path "$env:SystemDrive\WinInstall_Boot.wim") {
        $Panther = "$env:SystemDrive\Windows\Panther"; if (!(Test-Path $Panther)) { New-Item -ItemType Directory -Path $Panther -Force | Out-Null }
        Copy-Item $XML "$Panther\unattend.xml" -Force
        if (Create-Boot-Entry "\WinInstall_Boot.wim") { if ([System.Windows.Forms.MessageBox]::Show("DA XONG! Restart ngay?", "Success", "YesNo") -eq "Yes") { Restart-Computer -Force } }
    } else { [System.Windows.Forms.MessageBox]::Show("Loi copy boot!", "Loi") }
}

$Form.Add_Shown({ 
    Load-Partitions
    $ScanPaths = @("$env:USERPROFILE\Downloads", "D:", "E:", "F:")
    foreach ($P in $ScanPaths) { if (Test-Path $P) { Get-ChildItem $P -Filter "*.iso" -Recurse -Depth 1 | Where {$_.Length -gt 500MB} | ForEach { $CmbISO.Items.Add($_.FullName) } } }
    if ($CmbISO.Items.Count -gt 0) { $CmbISO.SelectedIndex = 0; Load-WimInfo }
})
$Form.ShowDialog() | Out-Null
