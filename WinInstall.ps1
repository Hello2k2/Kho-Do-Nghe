# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- INIT ---
try { Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing } catch { Exit }
$ErrorActionPreference = "SilentlyContinue"
$DebugLog = "C:\PhatTan_Debug.txt"

# --- LOGGING ---
function Write-DebugLog ($Message) {
    $Time = Get-Date -Format "HH:mm:ss"; $Line = "[$Time] $Message"
    $Line | Out-File -FilePath $DebugLog -Append -Encoding UTF8
    Write-Host $Line -ForegroundColor Cyan
}
if (Test-Path $DebugLog) { Remove-Item $DebugLog -Force }
Write-DebugLog "=== TOOL START V20.0 (ULTIMATE) ==="

# --- CẤU HÌNH ---
$WinToHDD_Url = "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/WinToHDD.exe"
$XML_Url = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/autounattend.xml"
$Global:DriverPath = "D:\Drivers_Backup_Auto"
$Global:SelectedDisk = 0
$Global:SelectedPart = 0
$Global:WimIndex = 1

# --- MOUNT ENGINE ---
function Dismount-All { Get-DiskImage -ImagePath * -ErrorAction SilentlyContinue | Dismount-DiskImage -ErrorAction SilentlyContinue }
function Mount-And-GetDrive ($IsoPath) {
    Dismount-All
    try { Mount-DiskImage -ImagePath $IsoPath -StorageType ISO -ErrorAction Stop | Out-Null; Start-Sleep -Seconds 2 } catch {}
    try { 
        $Vol = Get-DiskImage -ImagePath $IsoPath | Get-Volume
        if ($Vol) { $L="$($Vol.DriveLetter):"; if (Test-Path "$L\setup.exe") { return $L } }
    } catch {}
    $Drives = Get-PSDrive -PSProvider FileSystem
    foreach ($D in $Drives) { $R=$D.Root; if($R -in "C:\","A:\","B:\"){continue}; if((Test-Path "$R\setup.exe") -and (Test-Path "$R\bootmgr")){ return $R.TrimEnd("\") } }
    return $null
}

# --- BOOT ENGINE ---
function Get-BiosMode { if (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State") { return "UEFI" } return "Legacy" }
function Create-Boot-Entry ($WimPath) {
    try {
        $BcdList = bcdedit /enum /v | Out-String; $Lines = $BcdList -split "`r`n"
        for ($i=0; $i -lt $Lines.Count; $i++) { if ($Lines[$i] -match "description\s+CAI WIN TAM THOI") { for ($j=$i; $j -ge 0; $j--) { if ($Lines[$j] -match "identifier\s+{(.*)}") { cmd /c "bcdedit /delete {$($Matches[1])} /f"; break } } } }
        if (Test-Path "$env:SystemDrive\WinInstall_Boot.wim") { Remove-Item "$env:SystemDrive\WinInstall_Boot.wim" -Force }

        $Name="CAI WIN TAM THOI (Phat Tan PC)"; $Mode=Get-BiosMode; $Drive=$env:SystemDrive
        cmd /c "bcdedit /create {ramdiskoptions} /d `"Ramdisk Options`"" 2>$null
        cmd /c "bcdedit /set {ramdiskoptions} ramdisksdidevice partition=$Drive"; cmd /c "bcdedit /set {ramdiskoptions} ramdisksdipath \boot.sdi"
        $Output = cmd /c "bcdedit /create /d `"$Name`" /application osloader"; if ($Output -match '{([a-f0-9\-]+)}') { $ID = $matches[0] } else { return $false }
        cmd /c "bcdedit /set $ID device ramdisk=[$Drive]$WimPath,{ramdiskoptions}"; cmd /c "bcdedit /set $ID osdevice ramdisk=[$Drive]$WimPath,{ramdiskoptions}"
        cmd /c "bcdedit /set $ID systemroot \windows"; cmd /c "bcdedit /set $ID detecthal yes"; cmd /c "bcdedit /set $ID winpe yes"
        if ($Mode -eq "UEFI") { cmd /c "bcdedit /set $ID path \windows\system32\boot\winload.efi" } else { cmd /c "bcdedit /set $ID path \windows\system32\boot\winload.exe" }
        cmd /c "bcdedit /displayorder $ID /addlast"; cmd /c "bcdedit /bootsequence $ID"
        return $true
    } catch { return $false }
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CAI DAT WINDOWS MASTER - PHAT TAN PC (V20.0)"
$Form.Size = New-Object System.Drawing.Size(850, 750)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30); $Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

$TabControl = New-Object System.Windows.Forms.TabControl; $TabControl.Location = "10,10"; $TabControl.Size = "815,690"; $Form.Controls.Add($TabControl)
function Make-Tab ($T) { $P = New-Object System.Windows.Forms.TabPage; $P.Text = $T; $P.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48); $P.ForeColor = "White"; $TabControl.Controls.Add($P); return $P }

# === TAB 1: CAI DAT ===
$TabInstall = Make-Tab "Cai Dat Windows"
$LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text = "CHON ISO & CAU HINH"; $LblTitle.Font = "Segoe UI, 14, Bold"; $LblTitle.ForeColor = "Cyan"; $LblTitle.AutoSize=$true; $LblTitle.Location = "20,15"; $TabInstall.Controls.Add($LblTitle)
$CmbISO = New-Object System.Windows.Forms.ComboBox; $CmbISO.Size = "580, 30"; $CmbISO.Location = "20,55"; $CmbISO.Font = "Segoe UI, 10"; $CmbISO.DropDownStyle = "DropDownList"; $TabInstall.Controls.Add($CmbISO)
$BtnBrowse = New-Object System.Windows.Forms.Button; $BtnBrowse.Text = "TIM ISO"; $BtnBrowse.Location = "610,53"; $BtnBrowse.Size = "100,30"; $BtnBrowse.BackColor = "Gray"; $BtnBrowse.ForeColor="White"; $BtnBrowse.Add_Click({ $OFD = New-Object System.Windows.Forms.OpenFileDialog; $OFD.Filter = "ISO (*.iso)|*.iso"; if ($OFD.ShowDialog() -eq "OK") { $CmbISO.Items.Insert(0, $OFD.FileName); $CmbISO.SelectedIndex = 0; Check-Version } }); $TabInstall.Controls.Add($BtnBrowse)

$GBOpt = New-Object System.Windows.Forms.GroupBox; $GBOpt.Text = "TUY CHON DRIVER"; $GBOpt.Location = "20,100"; $GBOpt.Size = "690,200"; $GBOpt.ForeColor = "Yellow"; $TabInstall.Controls.Add($GBOpt)
$LblVerInfo = New-Object System.Windows.Forms.Label; $LblVerInfo.Text = "Trang thai: Chua chon ISO..."; $LblVerInfo.Location = "20,30"; $LblVerInfo.AutoSize=$true; $LblVerInfo.ForeColor="LightGray"; $GBOpt.Controls.Add($LblVerInfo)
$CkBackup = New-Object System.Windows.Forms.CheckBox; $CkBackup.Text = "Sao luu Driver hien tai"; $CkBackup.Location = "20,60"; $CkBackup.AutoSize=$true; $CkBackup.Checked=$true; $GBOpt.Controls.Add($CkBackup)
$Ck3DP = New-Object System.Windows.Forms.CheckBox; $Ck3DP.Text = "Tai 3DP Net"; $Ck3DP.Location = "20,90"; $Ck3DP.AutoSize=$true; $Ck3DP.Checked=$true; $GBOpt.Controls.Add($Ck3DP)
$CkInject = New-Object System.Windows.Forms.CheckBox; $CkInject.Text = "Tao Script Auto-Install"; $CkInject.Location = "20,120"; $CkInject.AutoSize=$true; $CkInject.Checked=$true; $GBOpt.Controls.Add($CkInject)
$LblPath = New-Object System.Windows.Forms.Label; $LblPath.Text = "Noi luu:"; $LblPath.Location = "40,155"; $LblPath.AutoSize=$true; $GBOpt.Controls.Add($LblPath)
$TxtPath = New-Object System.Windows.Forms.TextBox; $TxtPath.Text = $Global:DriverPath; $TxtPath.Location = "100,152"; $TxtPath.Size = "480,25"; $GBOpt.Controls.Add($TxtPath)
$BtnPath = New-Object System.Windows.Forms.Button; $BtnPath.Text = "..."; $BtnPath.Location = "590,151"; $BtnPath.Size = "40,27"; $BtnPath.BackColor="Gray"; $BtnPath.ForeColor="White"; $BtnPath.Add_Click({ $FBD = New-Object System.Windows.Forms.FolderBrowserDialog; if ($FBD.ShowDialog() -eq "OK") { $TxtPath.Text = $FBD.SelectedPath; $Global:DriverPath = $FBD.SelectedPath } }); $GBOpt.Controls.Add($BtnPath)

$BtnMode1 = New-Object System.Windows.Forms.Button; $BtnMode1.Text = "CHE DO 1: CAI DE / NANG CAP (Setup.exe)"; $BtnMode1.Location = "20,320"; $BtnMode1.Size = "690,50"; $BtnMode1.BackColor = "LimeGreen"; $BtnMode1.ForeColor = "Black"; $BtnMode1.Font = "Segoe UI, 12, Bold"; $BtnMode1.Add_Click({ Show-SubMenu-Upgrade }); $TabInstall.Controls.Add($BtnMode1)
$BtnMode2 = New-Object System.Windows.Forms.Button; $BtnMode2.Text = "CHE DO 2: CAI MOI (WinToHDD)"; $BtnMode2.Location = "20,390"; $BtnMode2.Size = "690,50"; $BtnMode2.BackColor = "Orange"; $BtnMode2.ForeColor = "Black"; $BtnMode2.Font = "Segoe UI, 12, Bold"; $BtnMode2.Add_Click({ Start-Install "WinToHDD" }); $TabInstall.Controls.Add($BtnMode2)

# === TAB 2: AUTO UNATTEND (FULL) ===
$TabConfig = Make-Tab "Cau Hinh Tu Dong (Unattend)"
$LblInfo = New-Object System.Windows.Forms.Label; $LblInfo.Text = "CAU HINH XML"; $LblInfo.Font = "Segoe UI, 12, Bold"; $LblInfo.ForeColor = "Cyan"; $LblInfo.AutoSize=$true; $LblInfo.Location = "20,20"; $TabConfig.Controls.Add($LblInfo)
function Add-Input ($Txt, $Y, $Def="") { $L = New-Object System.Windows.Forms.Label; $L.Text = $Txt; $L.Location = "20,$Y"; $L.AutoSize=$true; $TabConfig.Controls.Add($L); $T = New-Object System.Windows.Forms.TextBox; $T.Text = $Def; $T.Location = "220,$Y"; $T.Size = "300,25"; $TabConfig.Controls.Add($T); return $T }
$TxtUser = Add-Input "User:" 60 "Admin"; $TxtPass = Add-Input "Pass:" 100 ""; $TxtPCName = Add-Input "PC Name:" 140 "PhatTan-PC"; $TxtKey = Add-Input "Key:" 180 ""

$LblLoc = New-Object System.Windows.Forms.Label; $LblLoc.Text = "Mui gio:"; $LblLoc.Location = "20,220"; $LblLoc.AutoSize=$true; $TabConfig.Controls.Add($LblLoc)
$CmbTZ = New-Object System.Windows.Forms.ComboBox; $CmbTZ.Location = "220,217"; $CmbTZ.Size = "300,25"; $CmbTZ.DropDownStyle="DropDownList"; $TabConfig.Controls.Add($CmbTZ)
$CmbTZ.Items.AddRange(@("SE Asia Standard Time", "Pacific Standard Time", "China Standard Time", "Tokyo Standard Time")); $CmbTZ.SelectedIndex=0

$CkSkipWifi = New-Object System.Windows.Forms.CheckBox; $CkSkipWifi.Text = "Bo qua buoc ket noi Wifi (OOBE)"; $CkSkipWifi.Location = "220,250"; $CkSkipWifi.AutoSize=$true; $CkSkipWifi.Checked=$true; $TabConfig.Controls.Add($CkSkipWifi)
$CkAutoLogon = New-Object System.Windows.Forms.CheckBox; $CkAutoLogon.Text = "Tu dong dang nhap (Auto Logon)"; $CkAutoLogon.Location = "220,280"; $CkAutoLogon.AutoSize=$true; $CkAutoLogon.Checked=$true; $TabConfig.Controls.Add($CkAutoLogon)

$GBPart = New-Object System.Windows.Forms.GroupBox; $GBPart.Text = "TUY CHON O CUNG"; $GBPart.Location = "20,320"; $GBPart.Size = "700,80"; $GBPart.ForeColor = "Red"; $TabConfig.Controls.Add($GBPart)
$RadioWipe = New-Object System.Windows.Forms.RadioButton; $RadioWipe.Text = "XOA SACH (Clean)"; $RadioWipe.Location = "20,30"; $RadioWipe.AutoSize=$true; $RadioWipe.Checked=$true; $GBPart.Controls.Add($RadioWipe)
$RadioDual = New-Object System.Windows.Forms.RadioButton; $RadioDual.Text = "DUAL BOOT"; $RadioDual.Location = "250,30"; $RadioDual.AutoSize=$true; $GBPart.Controls.Add($RadioDual)

$BtnGenXML = New-Object System.Windows.Forms.Button; $BtnGenXML.Text = "TAO FILE CAU HINH"; $BtnGenXML.Location = "20,420"; $BtnGenXML.Size = "700,50"; $BtnGenXML.BackColor = "Cyan"; $BtnGenXML.ForeColor = "Black"; $BtnGenXML.Font = "Segoe UI, 12, Bold"
$BtnGenXML.Add_Click({ Generate-XML }); $TabConfig.Controls.Add($BtnGenXML)

# --- LOGIC ---
function Generate-XML {
    $User = $TxtUser.Text.Trim(); $Pass = $TxtPass.Text.Trim(); $PC = $TxtPCName.Text.Trim(); $Key = $TxtKey.Text.Trim(); $TZ = $CmbTZ.SelectedItem
    $XMLPath = "$env:SystemDrive\autounattend.xml"
    try { (New-Object Net.WebClient).DownloadFile($XML_Url, $XMLPath); $Content = Get-Content $XMLPath -Raw
        $Content = $Content -replace "%USERNAME%", $User -replace "%PASSWORD%", $Pass -replace "%COMPUTERNAME%", $PC -replace "SE Asia Standard Time", $TZ
        if ([string]::IsNullOrWhiteSpace($Key)) { $Content = $Content -replace "(?s)<ProductKey>.*?</ProductKey>", "" } else { $Content = $Content -replace "%PRODUCTKEY%", $Key }
        if ($CkSkipWifi.Checked) { $Content = $Content -replace "<HideWirelessSetupInOOBE>false</HideWirelessSetupInOOBE>", "<HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>" }
        if ($CkAutoLogon.Checked) { $Content = $Content -replace "<Enabled>false</Enabled>", "<Enabled>true</Enabled>" }

        # LOGIC CHÈN DISK/PARTITION TỪ GLOBAL VARIABLE
        $D_ID = $Global:SelectedDisk; $P_ID = $Global:SelectedPart
        if ($RadioWipe.Checked) { 
             $Content = $Content -replace "%WIPEDISK%", "true" -replace "%INSTALLTO%", "<DiskID>$D_ID</DiskID><PartitionID>1</PartitionID>"
             $Content = $Content -replace "%CREATEPARTITIONS%", "<CreatePartition wcm:action='add'><Order>1</Order><Type>Primary</Type><Extend>true</Extend></CreatePartition><ModifyPartition wcm:action='add'><Order>1</Order><PartitionID>1</PartitionID><Label>Windows</Label><Letter>C</Letter><Format>NTFS</Format></ModifyPartition>"
        } else { 
             $Content = $Content -replace "%WIPEDISK%", "false" -replace "%CREATEPARTITIONS%", ""
             $Content = $Content -replace "%INSTALLTO%", "<DiskID>$D_ID</DiskID><PartitionID>$P_ID</PartitionID>" 
        }
        
        # LOGIC CHÈN WIM INDEX
        $Idx = $Global:WimIndex
        $ImgBlock = "<InstallFrom><MetaData wcm:action=`"add`"><Key>/IMAGE/INDEX</Key><Value>$Idx</Value></MetaData></InstallFrom>"
        $Content = $Content -replace "<InstallTo>", "$ImgBlock<InstallTo>"

        $Content | Set-Content $XMLPath; [System.Windows.Forms.MessageBox]::Show("DA TAO XML THANH CONG!", "Phat Tan PC")
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi tai XML!", "Error") }
}

function Check-Version {
    $ISO = $CmbISO.SelectedItem; if (!$ISO) { return }
    $Form.Cursor = "WaitCursor"; $LblVerInfo.Text = "Dang check..."
    [string]$DriveLetter = Mount-And-GetDrive $ISO; if ($DriveLetter -match "([A-Z]:)") { $DriveLetter = $matches[1] }
    if ($DriveLetter) {
        try {
            $HostVer = [Environment]::OSVersion.Version.Major
            $Wim = "$DriveLetter\sources\install.wim"; if (!(Test-Path $Wim)) { $Wim = "$DriveLetter\sources\install.esd" }
            $DismInfo = dism /Get-WimInfo /WimFile:$Wim /Index:1 | Out-String
            if ($DismInfo -match "Version\s*:\s*(\d+)\.") {
                $ISOVerMajor = [int]$Matches[1]; $Msg = "Host: Win $HostVer | ISO: Win $ISOVerMajor"
                if ($ISOVerMajor -lt $HostVer) { $Msg += " [HA CAP -> KHOA BACKUP]"; $CkBackup.Checked=$false; $CkBackup.Enabled=$false; $LblVerInfo.ForeColor="Red" } 
                else { $Msg += " [OK]"; $CkBackup.Enabled=$true; $CkBackup.Checked=$true; $LblVerInfo.ForeColor="Lime" }
                $LblVerInfo.Text = $Msg
            } else { $LblVerInfo.Text = "Unknown Version."; $CkBackup.Enabled=$true }
        } catch { $LblVerInfo.Text = "Loi WIM." }
    } else { $LblVerInfo.Text = "Mount loi." }
    $Form.Cursor = "Default"
}

# --- ADVANCED CONFIG DIALOG (CHỌN WIN & Ổ) ---
function Show-Advanced-Config {
    $ISO = $CmbISO.SelectedItem; if (!$ISO) { [System.Windows.Forms.MessageBox]::Show("Chua chon ISO!", "Loi"); return }
    $Form.Cursor = "WaitCursor"; [string]$Drive = Mount-And-GetDrive $ISO; if ($Drive -match "([A-Z]:)") { $Drive = $matches[1] }
    if (!$Drive) { $Form.Cursor = "Default"; [System.Windows.Forms.MessageBox]::Show("Loi Mount!", "Loi"); return }
    $Wim = "$Drive\sources\install.wim"; if (!(Test-Path $Wim)) { $Wim = "$Drive\sources\install.esd" }
    
    $ConfForm = New-Object System.Windows.Forms.Form; $ConfForm.Text = "CAU HINH CHI TIET"; $ConfForm.Size = "800, 500"; $ConfForm.StartPosition = "CenterParent"; $ConfForm.BackColor = "Black"; $ConfForm.ForeColor = "White"
    $LblEd = New-Object System.Windows.Forms.Label; $LblEd.Text = "1. CHON PHIEN BAN:"; $LblEd.Location = "20,20"; $LblEd.AutoSize=$true; $LblEd.ForeColor="Cyan"; $ConfForm.Controls.Add($LblEd)
    $CmbEd = New-Object System.Windows.Forms.ComboBox; $CmbEd.Location = "20,50"; $CmbEd.Size = "740,30"; $CmbEd.DropDownStyle="DropDownList"
    
    # Get WIM Info
    $Info = dism /Get-WimInfo /WimFile:$Wim; $Indexes = $Info | Select-String "Index :"; $Names = $Info | Select-String "Name :"
    for ($i=0; $i -lt $Indexes.Count; $i++) { $Idx = $Indexes[$i].ToString().Split(":")[1].Trim(); $Nam = $Names[$i].ToString().Split(":")[1].Trim(); $CmbEd.Items.Add("$Idx - $Nam") }
    $CmbEd.SelectedIndex = 0; $ConfForm.Controls.Add($CmbEd)
    
    $LblD = New-Object System.Windows.Forms.Label; $LblD.Text = "2. CHON PHAN VUNG CAI DAT:"; $LblD.Location = "20,100"; $LblD.AutoSize=$true; $LblD.ForeColor="Cyan"; $ConfForm.Controls.Add($LblD)
    $GridPart = New-Object System.Windows.Forms.DataGridView; $GridPart.Location = "20,130"; $GridPart.Size = "740,200"; $GridPart.BackgroundColor="Black"; $GridPart.ForeColor="Black"; $GridPart.AllowUserToAddRows=$false; $GridPart.RowHeadersVisible=$false; $GridPart.SelectionMode="FullRowSelect"; $GridPart.MultiSelect=$false; $GridPart.ReadOnly=$true; $GridPart.AutoSizeColumnsMode="Fill"
    $GridPart.Columns.Add("Disk", "Disk"); $GridPart.Columns.Add("Part", "Part"); $GridPart.Columns.Add("Letter", "Ky Tu"); $GridPart.Columns.Add("Type", "Type"); $GridPart.Columns.Add("Size", "Size")
    
    $Parts = Get-Partition; $SysD = $env:SystemDrive.Replace(":", "")
    foreach ($P in $Parts) { $GB = [Math]::Round($P.Size / 1GB, 1); $L = if ($P.DriveLetter) { $P.DriveLetter } else { "N/A" }; $RowId = $GridPart.Rows.Add($P.DiskNumber, $P.PartitionNumber, $L, $P.Type, "$GB GB"); if ($P.DriveLetter -eq $SysD) { $GridPart.Rows[$RowId].Selected=$true; $GridPart.Rows[$RowId].DefaultCellStyle.BackColor="LightGreen"; $Global:SelectedDisk=$P.DiskNumber; $Global:SelectedPart=$P.PartitionNumber } }
    $GridPart.Add_CellClick({ $R = $GridPart.SelectedRows[0]; $Global:SelectedDisk = $R.Cells[0].Value; $Global:SelectedPart = $R.Cells[1].Value }); $ConfForm.Controls.Add($GridPart)
    
    $BtnGo = New-Object System.Windows.Forms.Button; $BtnGo.Text = "XAC NHAN & TIEP TUC"; $BtnGo.Location = "20,350"; $BtnGo.Size = "740,50"; $BtnGo.BackColor = "LimeGreen"; $BtnGo.ForeColor = "Black"; $BtnGo.Font = "Segoe UI, 12, Bold"
    $BtnGo.Add_Click({ $Global:WimIndex = $CmbEd.SelectedItem.ToString().Split("-")[0].Trim(); $ConfForm.Close(); Show-SubMenu-Upgrade }); $ConfForm.Controls.Add($BtnGo)
    $Form.Cursor = "Default"; $ConfForm.ShowDialog()
}

function Show-SubMenu-Upgrade {
    $SubForm = New-Object System.Windows.Forms.Form; $SubForm.Text="CHON CACH CHAY"; $SubForm.Size="550, 300"; $SubForm.StartPosition="CenterParent"; $SubForm.BackColor="Black"; $SubForm.ForeColor="White"
    $BtnD = New-Object System.Windows.Forms.Button; $BtnD.Text="1. CAI TRUC TIEP"; $BtnD.Location="20,60"; $BtnD.Size="490,40"; $BtnD.BackColor="Cyan"; $BtnD.ForeColor="Black"; $BtnD.Add_Click({ $SubForm.Close(); Start-Install "Direct" }); $SubForm.Controls.Add($BtnD)
    $BtnB = New-Object System.Windows.Forms.Button; $BtnB.Text="2. TAO BOOT TAM (Dung XML)"; $BtnB.Location="20,110"; $BtnB.Size="490,40"; $BtnB.BackColor="Magenta"; $BtnB.ForeColor="White"; $BtnB.Add_Click({ if (!(Test-Path "$env:SystemDrive\autounattend.xml")) { [System.Windows.Forms.MessageBox]::Show("Chua co XML! Sang Tab Unattend tao ngay.", "Warning"); return }; $SubForm.Close(); Start-Install "BootTmp" }); $SubForm.Controls.Add($BtnB); $SubForm.ShowDialog()
}

# --- MAIN INSTALL (SAFE COPY) ---
function Start-Install ($Mode) {
    $ISO = $CmbISO.SelectedItem; if (!$ISO) { return }
    $FinalPath = $TxtPath.Text; [string]$DriveLetter = Mount-And-GetDrive $ISO; if ($DriveLetter -match "([A-Z]:)") { $DriveLetter = $matches[1] }
    if (!$DriveLetter) { [System.Windows.Forms.MessageBox]::Show("Loi: Khong thay ISO!", "Loi"); return }
    $SrcWim = "$DriveLetter\sources\boot.wim"; $SrcSdi = "$DriveLetter\boot\boot.sdi"

    if ($CkBackup.Checked) {
        if (!(Test-Path $FinalPath)) { New-Item -ItemType Directory -Path $FinalPath -Force | Out-Null }
        $Form.Text = "DANG SAO LUU DRIVER..."; $Form.Refresh()
        Start-Process "pnputil.exe" -ArgumentList "/export-driver * `"$FinalPath`"" -Wait -NoNewWindow
        if ($CkInject.Checked) { Set-Content -Path "$FinalPath\1_CLICK_INSTALL_DRIVER.bat" -Value "@echo off`npnputil /add-driver `"%~dp0*.inf`" /subdirs /install`npause" }
        if ($Ck3DP.Checked) { try { (New-Object Net.WebClient).DownloadFile("https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/3DP.Net.exe", "$FinalPath\3DP_Net.exe") } catch {} }
    }

    if ($Mode -eq "Direct") { Start-Process "$DriveLetter\setup.exe"; $Form.Close() }
    elseif ($Mode -eq "BootTmp") {
        $Form.Text = "DANG TAO BOOT TAM (SAFE COPY)..."; $SysDrive = $env:SystemDrive
        $FreeC = (Get-PSDrive $SysDrive.Substring(0,1)).Free / 1GB; if ($FreeC -lt 2) { [System.Windows.Forms.MessageBox]::Show("O C: day qua!", "Loi"); return }
        
        $Temp = "C:\WinInstall_Temp"; New-Item -ItemType Directory -Path $Temp -Force | Out-Null
        Write-DebugLog "Copying files to temp..."
        Copy-Item $SrcWim "$Temp\boot.wim" -Force; Copy-Item $SrcSdi "$Temp\boot.sdi" -Force
        
        Write-DebugLog "Moving files to Root..."
        Move-Item "$Temp\boot.wim" "$SysDrive\WinInstall_Boot.wim" -Force; Move-Item "$Temp\boot.sdi" "$SysDrive\boot.sdi" -Force
        Remove-Item $Temp -Recurse -Force
        
        if (Test-Path "$SysDrive\WinInstall_Boot.wim") {
            if (Create-Boot-Entry "\WinInstall_Boot.wim") { if ([System.Windows.Forms.MessageBox]::Show("Da tao Boot Tam! Restart?", "Xong", "YesNo") -eq "Yes") { Restart-Computer -Force } }
        } else { [System.Windows.Forms.MessageBox]::Show("Loi copy file! Check log.", "Loi") }
    }
    elseif ($Mode -eq "WinToHDD") {
        $P = "$env:TEMP\WinToHDD.exe"; if (!(Test-Path $P)) { (New-Object Net.WebClient).DownloadFile($WinToHDD_Url, $P) }
        Start-Process $P; [System.Windows.Forms.MessageBox]::Show("Da xong!", "Info")
    }
}

$Form.Add_Shown({ $ScanPaths = @("$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop", "D:", "E:"); foreach ($P in $ScanPaths) { if (Test-Path $P) { Get-ChildItem $P -Filter "*.iso" -Recurse -Depth 1 | Where {$_.Length -gt 500MB} | ForEach { $CmbISO.Items.Add($_.FullName) } } }; if ($CmbISO.Items.Count -gt 0) { $CmbISO.SelectedIndex = 0 } })

$Form.ShowDialog() | Out-Null
