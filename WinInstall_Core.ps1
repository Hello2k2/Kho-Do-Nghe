# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- INIT ---
try { Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing } catch { Exit }
$ErrorActionPreference = "SilentlyContinue"
$DebugLog = "C:\PhatTan_Debug.txt"
$Global:SourceDrive = ""

function Write-DebugLog ($Message, $Type="INFO") {
    $Line = "[$(Get-Date -Format 'HH:mm:ss')] [$Type] $Message"; $Line | Out-File -FilePath $DebugLog -Append -Encoding UTF8; Write-Host $Line -ForegroundColor Cyan
}
if (Test-Path $DebugLog) { Remove-Item $DebugLog -Force }
Write-DebugLog "=== CORE MODULE V40.1 (DISM PERMISSION FIX) ===" "INIT"

# --- HELPER FUNCTIONS ---
function Mount-And-GetDrive ($IsoPath) {
    Write-DebugLog "Mounting ISO: $IsoPath" "DISK"
    Get-DiskImage -ImagePath * | Dismount-DiskImage | Out-Null
    try { Mount-DiskImage -ImagePath $IsoPath -StorageType ISO -ErrorAction Stop | Out-Null; Start-Sleep -Seconds 2 } catch { Write-DebugLog "Mount Failed!" "ERROR"; return $null }
    try { $Vol = Get-DiskImage -ImagePath $IsoPath | Get-Volume; if ($Vol) { $L="$($Vol.DriveLetter):"; if (Test-Path "$L\setup.exe") { return $L } } } catch {}
    $Drives = Get-PSDrive -PSProvider FileSystem; foreach ($D in $Drives) { $R=$D.Root; if($R -in "C:\","A:\","B:\"){continue}; if((Test-Path "$R\setup.exe") -and (Test-Path "$R\bootmgr")){ return $R.TrimEnd("\") } }
    return $null
}

function Create-Boot-Entry ($WimPath) {
    try {
        $BcdList = bcdedit /enum /v | Out-String; $Lines = $BcdList -split "`r`n"
        for ($i=0; $i -lt $Lines.Count; $i++) { if ($Lines[$i] -match "description\s+CAI WIN TU DONG") { for ($j=$i; $j -ge 0; $j--) { if ($Lines[$j] -match "identifier\s+{(.*)}") { cmd /c "bcdedit /delete {$($Matches[1])} /f"; break } } } }
        $Name="CAI WIN TU DONG (DISM MODE)"; $Drive=$env:SystemDrive
        cmd /c "bcdedit /create {ramdiskoptions} /d `"Ramdisk Options`"" 2>$null
        cmd /c "bcdedit /set {ramdiskoptions} ramdisksdidevice partition=$Drive"; cmd /c "bcdedit /set {ramdiskoptions} ramdisksdipath \boot.sdi"
        $Output = cmd /c "bcdedit /create /d `"$Name`" /application osloader"; if ($Output -match '{([a-f0-9\-]+)}') { $ID = $matches[0] } else { return $false }
        cmd /c "bcdedit /set $ID device ramdisk=[$Drive]$WimPath,{ramdiskoptions}"; cmd /c "bcdedit /set $ID osdevice ramdisk=[$Drive]$WimPath,{ramdiskoptions}"; cmd /c "bcdedit /set $ID systemroot \windows"; cmd /c "bcdedit /set $ID detecthal yes"; cmd /c "bcdedit /set $ID winpe yes"
        if (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State") { cmd /c "bcdedit /set $ID path \windows\system32\boot\winload.efi" } else { cmd /c "bcdedit /set $ID path \windows\system32\boot\winload.exe" }
        cmd /c "bcdedit /displayorder $ID /addlast"; cmd /c "bcdedit /bootsequence $ID"
        return $true
    } catch { return $false }
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form; $Form.Text = "CAI DAT WINDOWS (V40.1 DISM FIX)"; $Form.Size = "850, 550"; $Form.StartPosition = "CenterScreen"; $Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30); $Form.ForeColor = "White"; $Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false
$FontBold = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold); $FontNorm = New-Object System.Drawing.Font("Segoe UI", 10)

$GBIso = New-Object System.Windows.Forms.GroupBox; $GBIso.Text = "1. CHON FILE ISO"; $GBIso.Location = "20,10"; $GBIso.Size = "790,80"; $GBIso.ForeColor = "Cyan"; $Form.Controls.Add($GBIso)
$CmbISO = New-Object System.Windows.Forms.ComboBox; $CmbISO.Location = "20,30"; $CmbISO.Size = "630,30"; $CmbISO.Font = $FontNorm; $CmbISO.DropDownStyle = "DropDownList"; $GBIso.Controls.Add($CmbISO)
$BtnBrowse = New-Object System.Windows.Forms.Button; $BtnBrowse.Text = "MO FILE"; $BtnBrowse.Location = "660,28"; $BtnBrowse.Size = "110,30"; $BtnBrowse.BackColor = "Gray"; $BtnBrowse.ForeColor="White"; $BtnBrowse.Add_Click({ $OFD = New-Object System.Windows.Forms.OpenFileDialog; $OFD.Filter = "ISO (*.iso)|*.iso"; if ($OFD.ShowDialog() -eq "OK") { $CmbISO.Items.Insert(0, $OFD.FileName); $CmbISO.SelectedIndex = 0; Load-WimInfo } }); $GBIso.Controls.Add($BtnBrowse)

$GBVer = New-Object System.Windows.Forms.GroupBox; $GBVer.Text = "2. CHON PHIEN BAN WINDOWS"; $GBVer.Location = "20,100"; $GBVer.Size = "790,80"; $GBVer.ForeColor = "Lime"; $Form.Controls.Add($GBVer)
$CmbEd = New-Object System.Windows.Forms.ComboBox; $CmbEd.Location = "20,30"; $CmbEd.Size = "750,30"; $CmbEd.Font = $FontNorm; $CmbEd.DropDownStyle = "DropDownList"; $GBVer.Controls.Add($CmbEd)

$PbCopy = New-Object System.Windows.Forms.ProgressBar; $PbCopy.Location = "20,220"; $PbCopy.Size = "790,30"; $PbCopy.Visible=$false; $Form.Controls.Add($PbCopy)
$LblStatus = New-Object System.Windows.Forms.Label; $LblStatus.Text = "San sang..."; $LblStatus.Location = "20,260"; $LblStatus.AutoSize=$true; $LblStatus.ForeColor="Yellow"; $Form.Controls.Add($LblStatus)

$BtnStart = New-Object System.Windows.Forms.Button; $BtnStart.Text = "BAT DAU CAI DAT (AUTO DISM)"; $BtnStart.Location = "20,300"; $BtnStart.Size = "790,60"; $BtnStart.BackColor = "Red"; $BtnStart.ForeColor = "White"; $BtnStart.Font = $FontBold
$BtnStart.Add_Click({ Start-Dism-Inject }); $Form.Controls.Add($BtnStart)

# --- LOGIC DETECT SOURCE DRIVE ---
function Load-WimInfo {
    $ISO = $CmbISO.SelectedItem; if (!$ISO) { return }
    $Form.Cursor = "WaitCursor"; $CmbEd.Items.Clear()
    [string]$Drive = Mount-And-GetDrive $ISO
    if ($Drive -match "([A-Z]:)") { $Drive = $matches[1] }
    if (!$Drive) { $Form.Cursor = "Default"; return }
    $Wim = "$Drive\sources\install.wim"; if (!(Test-Path $Wim)) { $Wim = "$Drive\sources\install.esd" }
    try { $Info = dism /Get-WimInfo /WimFile:$Wim; $Indexes = $Info | Select-String "Index :"; $Names = $Info | Select-String "Name :"; for ($i=0; $i -lt $Indexes.Count; $i++) { $Idx = $Indexes[$i].ToString().Split(":")[1].Trim(); $Nam = $Names[$i].ToString().Split(":")[1].Trim(); $CmbEd.Items.Add("$Idx - $Nam") }; if ($CmbEd.Items.Count -gt 0) { $CmbEd.SelectedIndex = 0 } } catch {}
    
    $Parts = Get-PSDrive -PSProvider FileSystem
    foreach ($P in $Parts) { if ($P.Name -ne "C" -and $P.Free -gt 6GB) { $Global:SourceDrive = $P.Name + ":"; break } }
    $Form.Cursor = "Default"
}
$CmbISO.Add_SelectedIndexChanged({ Load-WimInfo })

function Copy-FileWithProgress ($Source, $Dest) {
    $SrcFile = [IO.File]::OpenRead($Source); $DestFile = [IO.File]::Create($Dest)
    $Buffer = New-Object byte[] (1024 * 1024); $Total = $SrcFile.Length; $SoFar = 0
    $PbCopy.Visible = $true; $PbCopy.Value = 0
    do {
        $Read = $SrcFile.Read($Buffer, 0, $Buffer.Length); $DestFile.Write($Buffer, 0, $Read); $SoFar += $Read
        if ($Total -gt 0) {
            $PbCopy.Value = [Math]::Min(100, [Math]::Round(($SoFar / $Total) * 100))
            $LblStatus.Text = "Copying Source... $([Math]::Round($SoFar/1GB,2)) GB"
            [System.Windows.Forms.Application]::DoEvents()
        }
    } while ($Read -gt 0)
    $SrcFile.Close(); $DestFile.Close(); $SrcFile.Dispose(); $DestFile.Dispose(); $PbCopy.Visible = $false
}

function Start-Dism-Inject {
    $ISO = $CmbISO.SelectedItem; if (!$ISO) { [System.Windows.Forms.MessageBox]::Show("Chua chon ISO!"); return }
    if ($CmbEd.SelectedItem) { $Idx = $CmbEd.SelectedItem.ToString().Split("-")[0].Trim() } else { $Idx = 1 }

    $Drive = Mount-And-GetDrive $ISO; if ($Drive -match "([A-Z]:)") { $Drive = $matches[1] }
    
    # 1. PREPARE DIRS
    $WorkDir = "C:\WinInstall_Work"; New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
    $MountDir = "$WorkDir\Mount"; New-Item -ItemType Directory -Path $MountDir -Force | Out-Null
    $SourceDir = if ($Global:SourceDrive) { "$($Global:SourceDrive)\WinSource" } else { "$env:SystemDrive\`$WINDOWS.~BT\Sources" }
    New-Item -ItemType Directory -Path $SourceDir -Force | Out-Null

    # 2. COPY INSTALL.WIM
    $WimSrc = "$Drive\sources\install.wim"; if (!(Test-Path $WimSrc)) { $WimSrc = "$Drive\sources\install.esd" }
    $LblStatus.Text = "Dang copy file cai dat vao $SourceDir..."; Copy-FileWithProgress $WimSrc "$SourceDir\install.wim"
    
    # 3. COPY OOBE XML
    $XML = "$env:TEMP\unattend.xml"
    if (Test-Path $XML) { Copy-Item $XML "$SourceDir\unattend.xml" -Force }

    # 4. PREPARE BOOT.WIM & FIX PERMISSIONS
    $LblStatus.Text = "Dang xu ly file Boot (Mounting)..."
    
    # Fix Cleanup truoc khi lam gi
    Start-Process "dism" -ArgumentList "/Cleanup-Wim" -Wait -NoNewWindow

    Copy-Item "$Drive\sources\boot.wim" "$WorkDir\boot.wim" -Force
    
    # --- QUAN TRONG: GO BO READ-ONLY ATTRIBUTE ---
    Set-ItemProperty -Path "$WorkDir\boot.wim" -Name IsReadOnly -Value $false
    
    Copy-Item "$Drive\boot\boot.sdi" "$env:SystemDrive\boot.sdi" -Force
    
    # Mount Boot.wim
    $Proc = Start-Process "dism" -ArgumentList "/Mount-Image /ImageFile:`"$WorkDir\boot.wim`" /Index:2 /MountDir:`"$MountDir`"" -Wait -NoNewWindow -PassThru
    
    if ($Proc.ExitCode -ne 0) {
        [System.Windows.Forms.MessageBox]::Show("LOI DISM MOUNT! Ma loi: $($Proc.ExitCode)`n(Da tu dong thu fix loi Read-Only).", "Error")
        return
    }
    
    # 5. INJECT AUTO SCRIPT
    $ScriptContent = @"
@echo off
title PHAT TAN PC - AUTO INSTALLER
color 1f
echo.
echo  ===================================================
echo    DANG TIM KIEM BO CAI DAT... VUI LONG DOI...
echo  ===================================================
echo.
:: 1. FIND SOURCE
set INSTALL_WIM=
for %%d in (C D E F G H I J K L M N O P Q R S T U V W Y Z) do (
    if exist "%%d:\WinSource\install.wim" ( set "INSTALL_WIM=%%d:\WinSource\install.wim" & set "SRC_DRV=%%d:" & goto FoundSource )
    if exist "%%d:\`$WINDOWS.~BT\Sources\install.wim" ( set "INSTALL_WIM=%%d:\`$WINDOWS.~BT\Sources\install.wim" & set "SRC_DRV=%%d:" & goto FoundSource )
)
echo [ERROR] KHONG TIM THAY FILE INSTALL.WIM!
pause
exit

:FoundSource
echo [OK] DA THAY SOURCE TAI: %INSTALL_WIM%

:: 2. FIND TARGET (C:)
set TARGET=
for %%d in (C D E F G H) do (
    if exist "%%d:\Users" (
        if /i "%%d:" NEQ "%SRC_DRV%" ( set "TARGET=%%d:" & goto FoundTarget )
    )
)
set TARGET=%SRC_DRV%

:FoundTarget
echo [OK] O DIA MUC TIEU: %TARGET%

:: 3. WIPE / CLEANUP
if /i "%TARGET%" NEQ "%SRC_DRV%" (
    echo [INFO] DANG FORMAT O %TARGET%...
    format %TARGET% /q /y /fs:ntfs
) else (
    echo [INFO] CHE DO 1 O CUNG -> GHI DE (KHONG FORMAT)
    rd /s /q %TARGET%\Windows
    rd /s /q "%TARGET%\Program Files"
    rd /s /q "%TARGET%\Program Files (x86)"
    rd /s /q "%TARGET%\ProgramData"
)

:: 4. APPLY IMAGE
echo.
echo  ===================================================
echo    DANG BUNG FILE WIN (DISM)... KHONG TAT MAY!
echo  ===================================================
echo.
dism /Apply-Image /ImageFile:"%INSTALL_WIM%" /Index:$Idx /ApplyDir:%TARGET%\

:: 5. BOOT & XML
echo Dang cai Bootloader...
bcdboot %TARGET%\Windows /s %TARGET%
if exist "%SRC_DRV%\WinSource\unattend.xml" (
    echo Dang copy file cau hinh...
    mkdir %TARGET%\Windows\Panther
    copy "%SRC_DRV%\WinSource\unattend.xml" "%TARGET%\Windows\Panther\unattend.xml" /y
)

echo.
echo  ===================================================
echo    XONG! MAY SE KHOI DONG LAI TRONG 5 GIAY...
echo  ===================================================
timeout /t 5
wpeutil reboot
"@
    [IO.File]::WriteAllText("$MountDir\Windows\System32\AutoSetup.cmd", $ScriptContent)
    $IniContent = "[LaunchApps]`r`n%SystemDrive%\Windows\System32\AutoSetup.cmd"
    [IO.File]::WriteAllText("$MountDir\Windows\System32\winpeshl.ini", $IniContent)

    # 6. UNMOUNT & COMMIT
    $LblStatus.Text = "Dang luu file Boot (Unmounting)..."
    Start-Process "dism" -ArgumentList "/Unmount-Image /MountDir:`"$MountDir`" /Commit" -Wait -NoNewWindow
    
    # 7. MOVE TO C:
    Move-Item "$WorkDir\boot.wim" "$env:SystemDrive\WinInstall_Boot.wim" -Force
    Remove-Item $WorkDir -Recurse -Force
    
    # 8. BCD ENTRY
    if (Create-Boot-Entry "\WinInstall_Boot.wim") {
         if ([System.Windows.Forms.MessageBox]::Show("DA XONG! KHOI DONG LAI NGAY?", "Success", "YesNo") -eq "Yes") { Restart-Computer -Force }
    }
}

$Form.Add_Shown({ 
    Load-Partitions
    $ScanPaths = @("$env:USERPROFILE\Downloads", "D:", "E:", "F:")
    foreach ($P in $ScanPaths) { if (Test-Path $P) { Get-ChildItem $P -Filter "*.iso" -Recurse -Depth 1 | Where {$_.Length -gt 500MB} | ForEach { $CmbISO.Items.Add($_.FullName) } } }
    if ($CmbISO.Items.Count -gt 0) { $CmbISO.SelectedIndex = 0; Load-WimInfo }
})
$Form.ShowDialog() | Out-Null
