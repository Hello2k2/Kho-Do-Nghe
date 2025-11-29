# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- INIT ---
try { Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing } catch { Exit }
$ErrorActionPreference = "SilentlyContinue"
$DebugLog = "C:\PhatTan_Debug.txt"

# --- LOG FUNCTION ---
function Write-DebugLog ($Message) {
    $Time = Get-Date -Format "HH:mm:ss"; $Line = "[$Time] $Message"
    $Line | Out-File -FilePath $DebugLog -Append -Encoding UTF8
    Write-Host $Line -ForegroundColor Cyan
}
if (Test-Path $DebugLog) { Remove-Item $DebugLog -Force }
Write-DebugLog "=== CORE MODULE START V12.0 (FIX XML PRIORITY) ==="

# --- CẤU HÌNH ---
$WinToHDD_Url = "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/WinToHDD.exe"
$Global:DriverPath = "D:\Drivers_Backup_Auto"

# --- HÀM CLEANUP ---
function Nuke-All-Mounts {
    Get-DiskImage -ImagePath * -ErrorAction SilentlyContinue | Dismount-DiskImage -ErrorAction SilentlyContinue | Out-Null
}

# --- HÀM MOUNT (HYBRID - TRẢ VỀ STRING) ---
function Mount-And-GetDrive ($IsoPath) {
    Write-DebugLog "Mounting: $IsoPath"
    Nuke-All-Mounts
    try { Mount-DiskImage -ImagePath $IsoPath -StorageType ISO -ErrorAction Stop | Out-Null; Start-Sleep -Seconds 2 } catch {}

    # 1. Get-DiskImage
    try {
        $Vol = Get-DiskImage -ImagePath $IsoPath | Get-Volume
        if ($Vol) { 
            $L = "$($Vol.DriveLetter):"
            if (Test-Path "$L\setup.exe") { return $L } 
        }
    } catch {}

    # 2. Brute Force
    $Drives = Get-PSDrive -PSProvider FileSystem
    foreach ($D in $Drives) {
        $R = $D.Root
        if ($R -in "C:\", "A:\", "B:\") { continue }
        if ((Test-Path "$R\setup.exe") -and (Test-Path "$R\bootmgr")) { 
            return [string]$R.TrimEnd("\")
        }
    }
    return $null
}

# --- HÀM TẠO BOOT ---
function Get-BiosMode { if (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State") { return "UEFI" } return "Legacy" }

function Create-Boot-Entry ($WimPath) {
    try {
        # Clean Old Entries
        $BcdList = bcdedit /enum /v | Out-String; $Lines = $BcdList -split "`r`n"
        for ($i=0; $i -lt $Lines.Count; $i++) { if ($Lines[$i] -match "description\s+CAI WIN TAM THOI") { for ($j=$i; $j -ge 0; $j--) { if ($Lines[$j] -match "identifier\s+{(.*)}") { cmd /c "bcdedit /delete {$($Matches[1])} /f"; break } } } }
        
        $Name = "CAI WIN TAM THOI (Phat Tan PC)"; $Mode = Get-BiosMode; $Drive = $env:SystemDrive
        cmd /c "bcdedit /create {ramdiskoptions} /d `"Ramdisk Options`"" 2>$null
        cmd /c "bcdedit /set {ramdiskoptions} ramdisksdidevice partition=$Drive"
        cmd /c "bcdedit /set {ramdiskoptions} ramdisksdipath \boot.sdi"
        
        $Output = cmd /c "bcdedit /create /d `"$Name`" /application osloader"
        if ($Output -match '{([a-f0-9\-]+)}') { $ID = $matches[0] } else { return $false }
        cmd /c "bcdedit /set $ID device ramdisk=[$Drive]$WimPath,{ramdiskoptions}"
        cmd /c "bcdedit /set $ID osdevice ramdisk=[$Drive]$WimPath,{ramdiskoptions}"
        cmd /c "bcdedit /set $ID systemroot \windows"
        cmd /c "bcdedit /set $ID detecthal yes"
        cmd /c "bcdedit /set $ID winpe yes"
        if ($Mode -eq "UEFI") { cmd /c "bcdedit /set $ID path \windows\system32\boot\winload.efi" } else { cmd /c "bcdedit /set $ID path \windows\system32\boot\winload.exe" }
        cmd /c "bcdedit /displayorder $ID /addlast"; cmd /c "bcdedit /bootsequence $ID"
        return $true
    } catch { return $false }
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "TIEN HANH CAI DAT (CORE V12.0)"
$Form.Size = New-Object System.Drawing.Size(800, 680)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30); $Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

$TabControl = New-Object System.Windows.Forms.TabControl; $TabControl.Location = "10,10"; $TabControl.Size = "765,620"; $Form.Controls.Add($TabControl)
function Make-Tab ($T) { $P = New-Object System.Windows.Forms.TabPage; $P.Text = $T; $P.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48); $P.ForeColor = "White"; $TabControl.Controls.Add($P); return $P }

# TAB 1: INSTALL
$TabInstall = Make-Tab "Menu Cai Dat"
$LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text = "CHON ISO & CAU HINH"; $LblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold); $LblTitle.ForeColor = "Cyan"; $LblTitle.AutoSize=$true; $LblTitle.Location = "20,15"; $TabInstall.Controls.Add($LblTitle)

$CmbISO = New-Object System.Windows.Forms.ComboBox; $CmbISO.Size = "580, 30"; $CmbISO.Location = "20,55"; $CmbISO.Font = New-Object System.Drawing.Font("Segoe UI", 10); $CmbISO.DropDownStyle = "DropDownList"; $TabInstall.Controls.Add($CmbISO)
$BtnBrowse = New-Object System.Windows.Forms.Button; $BtnBrowse.Text = "TIM ISO"; $BtnBrowse.Location = "610,53"; $BtnBrowse.Size = "100,30"; $BtnBrowse.BackColor = "Gray"; $BtnBrowse.ForeColor="White"; $BtnBrowse.Add_Click({ $OFD = New-Object System.Windows.Forms.OpenFileDialog; $OFD.Filter = "ISO (*.iso)|*.iso"; if ($OFD.ShowDialog() -eq "OK") { $CmbISO.Items.Insert(0, $OFD.FileName); $CmbISO.SelectedIndex = 0 } }); $TabInstall.Controls.Add($BtnBrowse)

$GBOpt = New-Object System.Windows.Forms.GroupBox; $GBOpt.Text = "TUY CHON DRIVER"; $GBOpt.Location = "20,100"; $GBOpt.Size = "690,200"; $GBOpt.ForeColor = "Yellow"; $TabInstall.Controls.Add($GBOpt)
$CkBackup = New-Object System.Windows.Forms.CheckBox; $CkBackup.Text = "Sao luu Driver hien tai"; $CkBackup.Location = "20,30"; $CkBackup.AutoSize=$true; $CkBackup.Checked=$true; $GBOpt.Controls.Add($CkBackup)
$Ck3DP = New-Object System.Windows.Forms.CheckBox; $Ck3DP.Text = "Tai 3DP Net"; $Ck3DP.Location = "20,60"; $Ck3DP.AutoSize=$true; $Ck3DP.Checked=$true; $GBOpt.Controls.Add($Ck3DP)
$CkInject = New-Object System.Windows.Forms.CheckBox; $CkInject.Text = "Tao Script Auto-Install"; $CkInject.Location = "20,90"; $CkInject.AutoSize=$true; $CkInject.Checked=$true; $GBOpt.Controls.Add($CkInject)
$LblPath = New-Object System.Windows.Forms.Label; $LblPath.Text = "Noi luu:"; $LblPath.Location = "40,125"; $LblPath.AutoSize=$true; $GBOpt.Controls.Add($LblPath)
$TxtPath = New-Object System.Windows.Forms.TextBox; $TxtPath.Text = $Global:DriverPath; $TxtPath.Location = "100,122"; $TxtPath.Size = "480,25"; $GBOpt.Controls.Add($TxtPath)
$BtnPath = New-Object System.Windows.Forms.Button; $BtnPath.Text = "..."; $BtnPath.Location = "590,121"; $BtnPath.Size = "40,27"; $BtnPath.BackColor="Gray"; $BtnPath.ForeColor="White"; $BtnPath.Add_Click({ $FBD = New-Object System.Windows.Forms.FolderBrowserDialog; if ($FBD.ShowDialog() -eq "OK") { $TxtPath.Text = $FBD.SelectedPath; $Global:DriverPath = $FBD.SelectedPath } }); $GBOpt.Controls.Add($BtnPath)

$BtnMode1 = New-Object System.Windows.Forms.Button; $BtnMode1.Text = "CHE DO 1: CAI DE / NANG CAP (Setup.exe)"; $BtnMode1.Location = "20,320"; $BtnMode1.Size = "690,50"; $BtnMode1.BackColor = "LimeGreen"; $BtnMode1.ForeColor = "Black"; $BtnMode1.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$BtnMode1.Add_Click({ 
    $ISO = $CmbISO.SelectedItem; if (!$ISO) { return }
    [string]$DriveLetter = Mount-And-GetDrive $ISO
    if ($DriveLetter -match "([A-Z]:)") { $DriveLetter = $matches[1] }
    if ($DriveLetter) { Start-Process "$DriveLetter\setup.exe"; $Form.Close() } else { [System.Windows.Forms.MessageBox]::Show("Loi Mount!", "Loi") }
})
$TabInstall.Controls.Add($BtnMode1)

$BtnMode2 = New-Object System.Windows.Forms.Button; $BtnMode2.Text = "CHE DO 2: TAO BOOT TAM (Cai tu XML)"; $BtnMode2.Location = "20,390"; $BtnMode2.Size = "690,50"; $BtnMode2.BackColor = "Magenta"; $BtnMode2.ForeColor = "White"; $BtnMode2.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$BtnMode2.Add_Click({ 
    $ISO = $CmbISO.SelectedItem; if (!$ISO) { return }
    
    # --- CHECK LOGIC XML PRIORITY ---
    if (!(Test-Path "$env:SystemDrive\autounattend.xml")) { [System.Windows.Forms.MessageBox]::Show("Chua co file XML! Hay dung Tool Config tao truoc.", "Canh Bao"); return }
    
    $FinalPath = $TxtPath.Text
    [string]$DriveLetter = Mount-And-GetDrive $ISO
    if ($DriveLetter -match "([A-Z]:)") { $DriveLetter = $matches[1] }
    if (!$DriveLetter) { [System.Windows.Forms.MessageBox]::Show("Loi: Khong tim thay ISO!", "Loi"); return }

    # --- CHECK ISO INTERNAL XML ---
    if (Test-Path "$DriveLetter\autounattend.xml") {
        $Ans = [System.Windows.Forms.MessageBox]::Show("CANH BAO: File ISO nay da co san 'autounattend.xml'.`nNo se ghi de cau hinh cua ban!`nBan co muon tiep tuc khong?", "Xung Dot Cau Hinh", "YesNo", "Warning")
        if ($Ans -eq "No") { return }
    }

    # BACKUP DRIVER
    if ($CkBackup.Checked) {
        if (!(Test-Path $FinalPath)) { New-Item -ItemType Directory -Path $FinalPath -Force | Out-Null }
        $Form.Text = "DANG SAO LUU DRIVER..."
        Start-Process "pnputil.exe" -ArgumentList "/export-driver * `"$FinalPath`"" -Wait -NoNewWindow
        if ($CkInject.Checked) { Set-Content -Path "$FinalPath\1_CLICK_INSTALL_DRIVER.bat" -Value "@echo off`npnputil /add-driver `"%~dp0*.inf`" /subdirs /install`npause" }
        if ($Ck3DP.Checked) { try { (New-Object Net.WebClient).DownloadFile("https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/3DP.Net.exe", "$FinalPath\3DP_Net.exe") } catch {} }
    }

    # COPY BOOT (SAFE COPY)
    $Form.Text = "DANG TAO BOOT TAM..."
    $SysDrive = $env:SystemDrive
    $Temp = "C:\WinInstall_Temp"; New-Item -ItemType Directory -Path $Temp -Force | Out-Null
    
    Copy-Item "$DriveLetter\sources\boot.wim" "$Temp\boot.wim" -Force
    Copy-Item "$DriveLetter\boot\boot.sdi" "$Temp\boot.sdi" -Force
    
    Move-Item "$Temp\boot.wim" "$SysDrive\WinInstall_Boot.wim" -Force
    Move-Item "$Temp\boot.sdi" "$SysDrive\boot.sdi" -Force
    Remove-Item $Temp -Recurse -Force
    
    # --- RAI THINH XML (NHIEU VI TRI) ---
    Write-DebugLog "Scattering XML config..."
    if (Test-Path "$SysDrive\autounattend.xml") {
        $TargetPanther = "$SysDrive\Windows\Panther"
        if (!(Test-Path $TargetPanther)) { New-Item -ItemType Directory -Path $TargetPanther -Force | Out-Null }
        Copy-Item "$SysDrive\autounattend.xml" "$TargetPanther\unattend.xml" -Force
        Write-DebugLog "Copied to Panther."
    }

    if (Test-Path "$SysDrive\WinInstall_Boot.wim") {
        if (Create-Boot-Entry "\WinInstall_Boot.wim") { if ([System.Windows.Forms.MessageBox]::Show("Da tao Boot Tam! Restart?", "Yes", "YesNo") -eq "Yes") { Restart-Computer -Force } }
    } else { [System.Windows.Forms.MessageBox]::Show("Loi copy boot.wim!", "Loi") }
})
$TabInstall.Controls.Add($BtnMode2)

$BtnMode3 = New-Object System.Windows.Forms.Button; $BtnMode3.Text = "CHE DO 3: CAI MOI (WinToHDD)"; $BtnMode3.Location = "20,460"; $BtnMode3.Size = "690,50"; $BtnMode3.BackColor = "Orange"; $BtnMode3.ForeColor = "Black"; $BtnMode3.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$BtnMode3.Add_Click({ 
    $P = "$env:TEMP\WinToHDD.exe"; if (!(Test-Path $P)) { (New-Object Net.WebClient).DownloadFile($WinToHDD_Url, $P) }
    Start-Process $P; [System.Windows.Forms.MessageBox]::Show("Da xong!", "Info")
})
$TabInstall.Controls.Add($BtnMode3)

# --- AUTO SCAN ---
$Form.Add_Shown({ $ScanPaths = @("$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop", "D:", "E:"); foreach ($P in $ScanPaths) { if (Test-Path $P) { Get-ChildItem $P -Filter "*.iso" -Recurse -Depth 1 | Where {$_.Length -gt 500MB} | ForEach { $CmbISO.Items.Add($_.FullName) } } }; if ($CmbISO.Items.Count -gt 0) { $CmbISO.SelectedIndex = 0 } })

$Form.ShowDialog() | Out-Null
