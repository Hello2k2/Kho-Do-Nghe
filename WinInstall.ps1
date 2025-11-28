# --- 1. TU DONG YEU CAU QUYEN ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- NAP THU VIEN ---
try { Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing } catch { Exit }
$ErrorActionPreference = "SilentlyContinue"

# --- CAU HINH ---
$WinToHDD_Url = "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/WinToHDD.exe"
$XML_Url = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/autounattend.xml"
$Global:DriverPath = "D:\Drivers_Backup_Auto"
$Global:CurrentISO = $null
$DebugLog = "C:\PhatTan_Debug.txt" # File Log nằm ở ổ C

# --- HÀM GHI LOG (QUAN TRỌNG) ---
function Write-DebugLog ($Message) {
    $Time = Get-Date -Format "HH:mm:ss"
    $Line = "[$Time] $Message"
    $Line | Out-File -FilePath $DebugLog -Append -Encoding UTF8
    Write-Host $Line -ForegroundColor Cyan
}

# Xóa log cũ khi mở tool
if (Test-Path $DebugLog) { Remove-Item $DebugLog -Force }
Write-DebugLog "=== BAT DAU TOOL V9.3 ==="
Write-DebugLog "User: $env:USERNAME | OS: $env:OS"

# --- HÀM HỖ TRỢ ---
function Dismount-All {
    Write-DebugLog "Dismounting all images..."
    if ($Global:CurrentISO) { Dismount-DiskImage -ImagePath $Global:CurrentISO -ErrorAction SilentlyContinue }
}

function Get-BiosMode {
    $Info = bcdedit /enum | Out-String
    if ($Info -match "winload.efi") { return "UEFI" }
    return "Legacy"
}

function Clean-Boot-Entries {
    Write-DebugLog "Cleaning old boot entries..."
    $BcdList = bcdedit /enum /v | Out-String
    $Lines = $BcdList -split "`r`n"
    for ($i=0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match "description\s+CAI WIN TAM THOI") {
            for ($j=$i; $j -ge 0; $j--) {
                if ($Lines[$j] -match "identifier\s+{(.*)}") {
                    cmd /c "bcdedit /delete {$($Matches[1])} /f"
                    Write-DebugLog "Deleted BCD ID: {$($Matches[1])}"
                    break
                }
            }
        }
    }
    if (Test-Path "$env:SystemDrive\WinInstall_Boot.wim") { Remove-Item "$env:SystemDrive\WinInstall_Boot.wim" -Force; Write-DebugLog "Deleted old WIM." }
    if (Test-Path "$env:SystemDrive\boot.sdi") { Remove-Item "$env:SystemDrive\boot.sdi" -Force }
}

function Create-Boot-Entry ($WimPath) {
    try {
        Clean-Boot-Entries
        $Name = "CAI WIN TAM THOI (Phat Tan PC)"
        $Mode = Get-BiosMode
        $Drive = $env:SystemDrive
        
        Write-DebugLog "Creating BCD Entry (Mode: $Mode)..."
        
        cmd /c "bcdedit /create {ramdiskoptions} /d `"Ramdisk Options`"" 2>$null
        cmd /c "bcdedit /set {ramdiskoptions} ramdisksdidevice partition=$Drive"
        cmd /c "bcdedit /set {ramdiskoptions} ramdisksdipath \boot.sdi"
        
        $Output = cmd /c "bcdedit /create /d `"$Name`" /application osloader"
        if ($Output -match '{([a-f0-9\-]+)}') { $ID = $matches[0] } else { Write-DebugLog "Error: Could not create BCD entry."; return $false }
        
        Write-DebugLog "Created Entry ID: $ID"
        
        cmd /c "bcdedit /set $ID device ramdisk=[$Drive]$WimPath,{ramdiskoptions}"
        cmd /c "bcdedit /set $ID osdevice ramdisk=[$Drive]$WimPath,{ramdiskoptions}"
        cmd /c "bcdedit /set $ID systemroot \windows"
        cmd /c "bcdedit /set $ID detecthal yes"
        cmd /c "bcdedit /set $ID winpe yes"
        
        if ($Mode -eq "UEFI") { cmd /c "bcdedit /set $ID path \windows\system32\boot\winload.efi" }
        else { cmd /c "bcdedit /set $ID path \windows\system32\boot\winload.exe" }

        cmd /c "bcdedit /displayorder $ID /addlast"
        cmd /c "bcdedit /bootsequence $ID"
        return $true
    } catch { Write-DebugLog "Exception BCD: $($_.Exception.Message)"; return $false }
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CAI DAT WINDOWS MASTER - PHAT TAN PC (V9.3 DEBUG)"
$Form.Size = New-Object System.Drawing.Size(800, 680)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30); $Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

# Tabs
$TabControl = New-Object System.Windows.Forms.TabControl; $TabControl.Location = "10,10"; $TabControl.Size = "765,620"; $Form.Controls.Add($TabControl)
function Make-Tab ($T) { $P = New-Object System.Windows.Forms.TabPage; $P.Text = $T; $P.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48); $P.ForeColor = "White"; $TabControl.Controls.Add($P); return $P }

# TAB 1: CAI DAT
$TabInstall = Make-Tab "Cai Dat Windows"
$LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text = "CHON ISO & CAU HINH"; $LblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold); $LblTitle.ForeColor = "Cyan"; $LblTitle.AutoSize=$true; $LblTitle.Location = "20,15"; $TabInstall.Controls.Add($LblTitle)

$CmbISO = New-Object System.Windows.Forms.ComboBox; $CmbISO.Size = "580, 30"; $CmbISO.Location = "20,55"; $CmbISO.Font = New-Object System.Drawing.Font("Segoe UI", 10); $CmbISO.DropDownStyle = "DropDownList"; $TabInstall.Controls.Add($CmbISO)
$BtnBrowse = New-Object System.Windows.Forms.Button; $BtnBrowse.Text = "TIM ISO"; $BtnBrowse.Location = "610,53"; $BtnBrowse.Size = "100,30"; $BtnBrowse.BackColor = "Gray"; $BtnBrowse.ForeColor="White"; $BtnBrowse.Add_Click({ $OFD = New-Object System.Windows.Forms.OpenFileDialog; $OFD.Filter = "ISO (*.iso)|*.iso"; if ($OFD.ShowDialog() -eq "OK") { $CmbISO.Items.Insert(0, $OFD.FileName); $CmbISO.SelectedIndex = 0; Check-Version } }); $TabInstall.Controls.Add($BtnBrowse)

$GBOpt = New-Object System.Windows.Forms.GroupBox; $GBOpt.Text = "TUY CHON DRIVER"; $GBOpt.Location = "20,100"; $GBOpt.Size = "690,200"; $GBOpt.ForeColor = "Yellow"; $TabInstall.Controls.Add($GBOpt)
$LblVerInfo = New-Object System.Windows.Forms.Label; $LblVerInfo.Text = "Trang thai: Chua chon ISO..."; $LblVerInfo.Location = "20,30"; $LblVerInfo.AutoSize=$true; $LblVerInfo.ForeColor="LightGray"; $GBOpt.Controls.Add($LblVerInfo)
$CkBackup = New-Object System.Windows.Forms.CheckBox; $CkBackup.Text = "Sao luu Driver hien tai"; $CkBackup.Location = "20,60"; $CkBackup.AutoSize=$true; $CkBackup.Checked=$true; $GBOpt.Controls.Add($CkBackup)
$Ck3DP = New-Object System.Windows.Forms.CheckBox; $Ck3DP.Text = "Tai 3DP Net"; $Ck3DP.Location = "20,90"; $Ck3DP.AutoSize=$true; $Ck3DP.Checked=$true; $GBOpt.Controls.Add($Ck3DP)
$CkInject = New-Object System.Windows.Forms.CheckBox; $CkInject.Text = "Tao Script Auto-Install"; $CkInject.Location = "20,120"; $CkInject.AutoSize=$true; $CkInject.Checked=$true; $GBOpt.Controls.Add($CkInject)
$LblPath = New-Object System.Windows.Forms.Label; $LblPath.Text = "Noi luu:"; $LblPath.Location = "40,155"; $LblPath.AutoSize=$true; $GBOpt.Controls.Add($LblPath)
$TxtPath = New-Object System.Windows.Forms.TextBox; $TxtPath.Text = $Global:DriverPath; $TxtPath.Location = "100,152"; $TxtPath.Size = "480,25"; $GBOpt.Controls.Add($TxtPath)
$BtnPath = New-Object System.Windows.Forms.Button; $BtnPath.Text = "..."; $BtnPath.Location = "590,151"; $BtnPath.Size = "40,27"; $BtnPath.BackColor="Gray"; $BtnPath.ForeColor="White"; $BtnPath.Add_Click({ $FBD = New-Object System.Windows.Forms.FolderBrowserDialog; if ($FBD.ShowDialog() -eq "OK") { $TxtPath.Text = $FBD.SelectedPath; $Global:DriverPath = $FBD.SelectedPath } }); $GBOpt.Controls.Add($BtnPath)

$BtnMode1 = New-Object System.Windows.Forms.Button; $BtnMode1.Text = "CHE DO 1: CAI DE (Setup.exe)"; $BtnMode1.Location = "20,320"; $BtnMode1.Size = "690,50"; $BtnMode1.BackColor = "LimeGreen"; $BtnMode1.ForeColor = "Black"; $BtnMode1.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$BtnMode1.Add_Click({ Show-SubMenu-Upgrade }); $TabInstall.Controls.Add($BtnMode1)
$BtnMode2 = New-Object System.Windows.Forms.Button; $BtnMode2.Text = "CHE DO 2: CAI MOI (WinToHDD)"; $BtnMode2.Location = "20,390"; $BtnMode2.Size = "690,50"; $BtnMode2.BackColor = "Orange"; $BtnMode2.ForeColor = "Black"; $BtnMode2.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$BtnMode2.Add_Click({ Start-Install "WinToHDD" }); $TabInstall.Controls.Add($BtnMode2)

# TAB 2: CONFIG
$TabConfig = Make-Tab "Cau Hinh Tu Dong"
$LblInfo = New-Object System.Windows.Forms.Label; $LblInfo.Text = "CAU HINH XML"; $LblInfo.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold); $LblInfo.ForeColor = "Cyan"; $LblInfo.AutoSize=$true; $LblInfo.Location = "20,20"; $TabConfig.Controls.Add($LblInfo)
function Add-Input ($Txt, $Y, $Def="") { $L = New-Object System.Windows.Forms.Label; $L.Text = $Txt; $L.Location = "20,$Y"; $L.AutoSize=$true; $TabConfig.Controls.Add($L); $T = New-Object System.Windows.Forms.TextBox; $T.Text = $Def; $T.Location = "220,$Y"; $T.Size = "300,25"; $TabConfig.Controls.Add($T); return $T }
$TxtUser = Add-Input "User:" 60 "Admin"; $TxtPass = Add-Input "Pass:" 100 ""; $TxtPCName = Add-Input "PC Name:" 140 "PhatTan-PC"; $TxtKey = Add-Input "Key:" 180 ""
$GBPart = New-Object System.Windows.Forms.GroupBox; $GBPart.Text = "TUY CHON O CUNG"; $GBPart.Location = "20,230"; $GBPart.Size = "700,120"; $GBPart.ForeColor = "Red"; $TabConfig.Controls.Add($GBPart)
$RadioWipe = New-Object System.Windows.Forms.RadioButton; $RadioWipe.Text = "XOA SACH (Clean)"; $RadioWipe.Location = "20,30"; $RadioWipe.AutoSize=$true; $RadioWipe.Checked=$true; $GBPart.Controls.Add($RadioWipe)
$RadioDual = New-Object System.Windows.Forms.RadioButton; $RadioDual.Text = "DUAL BOOT"; $RadioDual.Location = "20,60"; $RadioDual.AutoSize=$true; $GBPart.Controls.Add($RadioDual)
$BtnGenXML = New-Object System.Windows.Forms.Button; $BtnGenXML.Text = "TAO FILE XML"; $BtnGenXML.Location = "20,380"; $BtnGenXML.Size = "700,50"; $BtnGenXML.BackColor = "Cyan"; $BtnGenXML.ForeColor = "Black"; $BtnGenXML.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$BtnGenXML.Add_Click({ Generate-XML }); $TabConfig.Controls.Add($BtnGenXML)

function Generate-XML {
    $User = $TxtUser.Text; $Pass = $TxtPass.Text; $PC = $TxtPCName.Text; $Key = $TxtKey.Text; $XMLPath = "$env:SystemDrive\autounattend.xml"
    try { (New-Object Net.WebClient).DownloadFile($XML_Url, $XMLPath); $Content = Get-Content $XMLPath -Raw
        $Content = $Content -replace "%USERNAME%", $User -replace "%PASSWORD%", $Pass -replace "%COMPUTERNAME%", $PC
        if ($Key) { $Content = $Content -replace "%PRODUCTKEY%", $Key } else { $Content = $Content -replace "<Key>.*?</Key>", "<Key></Key>" }
        if ($RadioWipe.Checked) { $Content = $Content -replace "%WIPEDISK%", "true" -replace "%CREATEPARTITIONS%", "<CreatePartition wcm:action='add'><Order>1</Order><Type>Primary</Type><Extend>true</Extend></CreatePartition><ModifyPartition wcm:action='add'><Order>1</Order><PartitionID>1</PartitionID><Label>Windows</Label><Letter>C</Letter><Format>NTFS</Format></ModifyPartition>" -replace "%INSTALLTO%", "<DiskID>0</DiskID><PartitionID>1</PartitionID>" } 
        else { $Content = $Content -replace "%WIPEDISK%", "false" -replace "%CREATEPARTITIONS%", "" -replace "%INSTALLTO%", "<DiskID>0</DiskID><PartitionID>3</PartitionID>" }
        $Content | Set-Content $XMLPath; [System.Windows.Forms.MessageBox]::Show("Tao XML xong!", "Phat Tan PC")
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi tai XML!", "Error") }
}

function Check-Version {
    $ISO = $CmbISO.SelectedItem; if (!$ISO) { return }
    $Form.Cursor = "WaitCursor"; $LblVerInfo.Text = "Dang kiem tra..."
    try {
        $HostVer = [Environment]::OSVersion.Version.Major
        Dismount-All
        Mount-DiskImage -ImagePath $ISO -StorageType ISO -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1 # Doi Mount
        $Vol = Get-Volume | Where-Object { Test-Path "$($_.DriveLetter):\setup.exe" } | Select -First 1
        if ($Vol) {
            $Global:CurrentISO = $ISO; $Drive = "$($Vol.DriveLetter):"
            $Wim = "$Drive\sources\install.wim"; if (!(Test-Path $Wim)) { $Wim = "$Drive\sources\install.esd" }
            $DismInfo = dism /Get-WimInfo /WimFile:$Wim /Index:1
            $ISOVerStr = ($DismInfo | Select-String "Version :").ToString().Split(":")[1].Trim(); $ISOVerMajor = [int]$ISOVerStr.Split(".")[0]
            $Msg = "Host: Win $HostVer | ISO: Win $ISOVerMajor"
            if ($ISOVerMajor -lt $HostVer) { $Msg += " [!] HA CAP -> KHOA BACKUP"; $CkBackup.Checked=$false; $CkBackup.Enabled=$false; $LblVerInfo.ForeColor="Red" } 
            else { $Msg += " [OK] Hop le."; $CkBackup.Enabled=$true; $CkBackup.Checked=$true; $LblVerInfo.ForeColor="Lime" }
            $LblVerInfo.Text = $Msg
        } else { $LblVerInfo.Text = "Khong thay o dia ao." }
    } catch { $LblVerInfo.Text = "Loi check version: $($_.Exception.Message)" }
    $Form.Cursor = "Default"
}
$CmbISO.Add_SelectedIndexChanged({ Check-Version })

function Show-SubMenu-Upgrade {
    $SubForm = New-Object System.Windows.Forms.Form; $SubForm.Text="CHON CACH CHAY"; $SubForm.Size="550, 300"; $SubForm.StartPosition="CenterParent"; $SubForm.BackColor="Black"; $SubForm.ForeColor="White"
    $BtnD = New-Object System.Windows.Forms.Button; $BtnD.Text="1. CAI TRUC TIEP"; $BtnD.Location="20,60"; $BtnD.Size="490,40"; $BtnD.BackColor="Cyan"; $BtnD.ForeColor="Black"; $BtnD.Add_Click({ $SubForm.Close(); Start-Install "Direct" }); $SubForm.Controls.Add($BtnD)
    $BtnB = New-Object System.Windows.Forms.Button; $BtnB.Text="2. TAO BOOT TAM (Dung XML)"; $BtnB.Location="20,110"; $BtnB.Size="490,40"; $BtnB.BackColor="Magenta"; $BtnB.ForeColor="White"; $BtnB.Add_Click({ if (!(Test-Path "$env:SystemDrive\autounattend.xml")) { [System.Windows.Forms.MessageBox]::Show("Chua co XML!", "Canh Bao"); return }; $SubForm.Close(); Start-Install "BootTmp" }); $SubForm.Controls.Add($BtnB)
    $SubForm.ShowDialog()
}

# --- MAIN INSTALL (LOGGING) ---
function Start-Install ($Mode) {
    $ISO = $CmbISO.SelectedItem; if (!$ISO) { return }
    $FinalPath = $TxtPath.Text
    Write-DebugLog "Start Install: Mode=$Mode, ISO=$ISO"

    # 1. BACKUP DRIVER
    if ($CkBackup.Checked) {
        Write-DebugLog "Starting Backup Driver..."
        if (!(Test-Path $FinalPath)) { New-Item -ItemType Directory -Path $FinalPath -Force | Out-Null }
        $Form.Text = "DANG SAO LUU DRIVER..."
        $P = Start-Process "pnputil.exe" -ArgumentList "/export-driver * `"$FinalPath`"" -Wait -NoNewWindow -PassThru
        Write-DebugLog "Backup Driver Exit Code: $($P.ExitCode)"
        
        if ($CkInject.Checked) { Set-Content -Path "$FinalPath\1_CLICK_INSTALL_DRIVER.bat" -Value "@echo off`npnputil /add-driver `"%~dp0*.inf`" /subdirs /install`npause" }
        if ($Ck3DP.Checked) { try { (New-Object Net.WebClient).DownloadFile("https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/3DP.Net.exe", "$FinalPath\3DP_Net.exe") } catch {} }
    }

    # 2. MOUNT
    $Vol = Get-Volume | Where-Object { Test-Path "$($_.DriveLetter):\setup.exe" } | Select -First 1
    if (!$Vol) { 
        Write-DebugLog "Mounting ISO..."
        Mount-DiskImage -ImagePath $ISO -StorageType ISO -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        $Vol = Get-Volume | Where-Object { Test-Path "$($_.DriveLetter):\setup.exe" } | Select -First 1
    }
    
    if (!$Vol) { Write-DebugLog "ERROR: Mount Failed."; [System.Windows.Forms.MessageBox]::Show("Loi: Mount ISO that bai hoac khong co setup.exe!", "Loi"); return }
    $Drive = "$($Vol.DriveLetter):"
    Write-DebugLog "ISO Mounted at: $Drive"

    # 3. EXECUTE
    if ($Mode -eq "Direct") { 
        Start-Process "$Drive\setup.exe"
        $Form.Close() 
    }
    elseif ($Mode -eq "BootTmp") {
        $Form.Text = "DANG TAO BOOT TAM..."
        $SysDrive = $env:SystemDrive
        $FreeC = (Get-PSDrive $SysDrive.Substring(0,1)).Free / 1GB
        if ($FreeC -lt 2) { Write-DebugLog "Err: Low Disk Space"; [System.Windows.Forms.MessageBox]::Show("O C: day qua!", "Loi"); return }

        Write-DebugLog "Copying boot.wim..."
        try {
            Copy-Item "$Drive\sources\boot.wim" "$SysDrive\WinInstall_Boot.wim" -Force -ErrorAction Stop
            Copy-Item "$Drive\boot\boot.sdi" "$SysDrive\boot.sdi" -Force -ErrorAction Stop
            
            if (Test-Path "$SysDrive\WinInstall_Boot.wim") {
                Write-DebugLog "Copy OK. Creating BCD..."
                if (Create-Boot-Entry "\WinInstall_Boot.wim") {
                    if ([System.Windows.Forms.MessageBox]::Show("Da tao Boot Tam! Restart ngay?", "Xong", "YesNo") -eq "Yes") { Restart-Computer -Force }
                }
            } else { Write-DebugLog "Err: File copy failed." }
        } catch {
            Write-DebugLog "Copy Exception: $($_.Exception.Message)"
            [System.Windows.Forms.MessageBox]::Show("Loi copy file Boot: $($_.Exception.Message)`nHay xem file Log C:\PhatTan_Debug.txt", "Loi")
        }
    }
    elseif ($Mode -eq "WinToHDD") {
        $P = "$env:TEMP\WinToHDD.exe"; if (!(Test-Path $P)) { (New-Object Net.WebClient).DownloadFile($WinToHDD_Url, $P) }
        Start-Process $P; [System.Windows.Forms.MessageBox]::Show("Da xong!", "Info")
    }
}

# --- AUTO SCAN ---
$Form.Add_Shown({
    $Form.Refresh(); $LblScan.Text = "Dang quet ISO..."
    $Paths = @("$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop", "D:", "E:")
    foreach ($P in $Paths) { if (Test-Path $P) { Get-ChildItem $P -Filter "*.iso" -Recurse -Depth 1 | Where {$_.Length -gt 500MB} | ForEach { $CmbISO.Items.Add($_.FullName) } } }
    if ($CmbISO.Items.Count -gt 0) { $CmbISO.SelectedIndex = 0; Check-Version } else { $LblScan.Text = "Khong thay ISO." }
})

$Form.ShowDialog() | Out-Null
