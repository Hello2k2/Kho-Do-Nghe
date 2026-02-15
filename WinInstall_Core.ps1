<#
  WININSTALL CORE V23.2 (RESPONSIVE UI)
  Author: Phat Tan PC

  FIX V23.2:
  1. AUTO FIT: Tự động chỉnh kích thước cửa sổ dựa trên độ phân giải màn hình (VM/WinPE Safe).
  2. SCROLLABLE: Thêm thanh cuộn (AutoScroll) nếu màn hình quá bé.
  3. COMPACT LAYOUT: Tinh chỉnh lại vị trí để gọn gàng hơn.
#>

# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit 
}

# --- GLOBAL VARS ---
$Global:LogPath     = "$env:SystemDrive\WinInstall_V23.log"
$Global:SelSource   = $null
$Global:SelWinPart  = $null
$Global:SelBootPart = $null
$Global:IsoMounted  = $null
$Global:TargetLabel = "TARGET_$(Get-Random -Minimum 1000 -Maximum 9999)"

# --- HELPER FUNCTIONS ---
function Log-Write { 
    param([string]$Msg) 
    $Time = Get-Date -Format "HH:mm:ss"
    $Line = "[$Time] $Msg"
    try { $Global:TxtLog.AppendText("$Line`r`n"); $Global:TxtLog.SelectionStart = $Global:TxtLog.Text.Length; $Global:TxtLog.ScrollToCaret() } catch {}
    try { Add-Content -Path $Global:LogPath -Value $Line -Force } catch {} 
}

function Exec-Cmd { param([string]$Command); Log-Write "CMD> $Command"; $R = cmd /c $Command 2>&1; return $R }

function Get-Key-From-Json-Tree {
    param([string]$EditionFullname) 
    $JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/winkeys_kms.json"
    Log-Write "Scanning Key..."
    try {
        $KmsData = Invoke-RestMethod -Uri $JsonUrl -TimeoutSec 5
        foreach ($Prop in $KmsData.PSObject.Properties) {
            foreach ($Item in $Prop.Value) {
                if ($EditionFullname.Trim() -match $Item.Name.Trim()) { return $Item.Key }
            }
        }
    } catch { Log-Write "JSON Error." }
    return ""
}

function Smart-Apply-Image {
    param($ImagePath, $Index, $ApplyDir)
    Log-Write "--- SMART ENGINE ---"
    if (Get-Command Expand-WindowsImage -ErrorAction SilentlyContinue) {
        try { Expand-WindowsImage -ImagePath $ImagePath -Index $Index -ApplyPath $ApplyDir -ErrorAction Stop; Log-Write "[API] Success."; return } catch {}
    }
    $Res = Exec-Cmd "dism /Apply-Image /ImageFile:`"$ImagePath`" /Index:$Index /ApplyDir:$ApplyDir"
    if ($Res -eq 0) { Log-Write "[DISM] Success." } else { Log-Write "[DISM] Fail ($Res)." }
}

function Mount-All-Partitions {
    try { Get-WmiObject Win32_Volume | % { if(!$_.DriveLetter){ $_.Mount() } } } catch {}
}

# --- GUI INIT ---
Add-Type -AssemblyName System.Windows.Forms

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WININSTALL CORE V23.2 (RESPONSIVE)"
$Form.BackColor = "30, 30, 30"
$Form.ForeColor = "White"

# --- RESPONSIVE LOGIC ---
$Screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$FormWidth = 1100
$FormHeight = 720

# Nếu màn hình nhỏ hơn Form, thu nhỏ Form lại và bật Scroll
if ($Screen.Width -lt $FormWidth) { $FormWidth = $Screen.Width - 50 }
if ($Screen.Height -lt $FormHeight) { $FormHeight = $Screen.Height - 50 }

$Form.Size = "$FormWidth, $FormHeight"
$Form.StartPosition = "CenterScreen"
$Form.AutoScroll = $true # [QUAN TRỌNG] Bật thanh cuộn nếu bị che

$LblTitle = New-Object System.Windows.Forms.Label
$LblTitle.Text = "🚀 WININSTALL V23.2"
$LblTitle.Font = New-Object System.Drawing.Font("Consolas", 18, [System.Drawing.FontStyle]::Bold)
$LblTitle.ForeColor = "Cyan"
$LblTitle.AutoSize = $true
$LblTitle.Location = "20, 10"
$Form.Controls.Add($LblTitle)

# === LAYOUT (COMPACT) ===

# 1. SOURCE
$PnlSource = New-Object System.Windows.Forms.Panel; $PnlSource.Location="20,50"; $PnlSource.Size="1040,60"; $PnlSource.BackColor="45, 45, 48"; $PnlSource.BorderStyle="FixedSingle"; $Form.Controls.Add($PnlSource)
$BtnISO = New-Object System.Windows.Forms.Button; $BtnISO.Text="CHỌN ISO"; $BtnISO.Location="10,15"; $BtnISO.Size="100,30"; $BtnISO.FlatStyle="Flat"; $BtnISO.BackColor="DimGray"; $PnlSource.Controls.Add($BtnISO)
$TxtISO = New-Object System.Windows.Forms.TextBox; $TxtISO.Location="120,18"; $TxtISO.Size="500,25"; $TxtISO.BackColor="30, 30, 30"; $TxtISO.ForeColor="White"; $TxtISO.ReadOnly=$true; $PnlSource.Controls.Add($TxtISO)
$BtnMount = New-Object System.Windows.Forms.Button; $BtnMount.Text="MOUNT"; $BtnMount.Location="630,15"; $BtnMount.Size="80,30"; $BtnMount.FlatStyle="Flat"; $BtnMount.BackColor="DarkGreen"; $PnlSource.Controls.Add($BtnMount)
$CbIndex = New-Object System.Windows.Forms.ComboBox; $CbIndex.Location="720,18"; $CbIndex.Size="300,30"; $CbIndex.DropDownStyle="DropDownList"; $CbIndex.BackColor="30, 30, 30"; $CbIndex.ForeColor="White"; $PnlSource.Controls.Add($CbIndex)

# 2. DISK MAP & OPTIONS
$PnlLeft = New-Object System.Windows.Forms.Panel; $PnlLeft.Location="20,120"; $PnlLeft.Size="600,420"; $PnlLeft.BackColor="45, 45, 48"; $PnlLeft.BorderStyle="FixedSingle"; $Form.Controls.Add($PnlLeft)

$GridPart = New-Object System.Windows.Forms.DataGridView; $GridPart.Location="10,10"; $GridPart.Size="580,260"; $GridPart.BackgroundColor="30, 30, 30"; $GridPart.ForeColor="Black"; $GridPart.RowHeadersVisible=$false; $GridPart.SelectionMode="FullRowSelect"; $GridPart.ReadOnly=$true; $GridPart.AutoSizeColumnsMode="Fill"
[void]$GridPart.Columns.Add("Ltr","Let"); [void]$GridPart.Columns.Add("Label","Label"); [void]$GridPart.Columns.Add("Size","Size (GB)"); [void]$GridPart.Columns.Add("FS","FS"); [void]$GridPart.Columns.Add("Role","Vai Trò"); $PnlLeft.Controls.Add($GridPart)

$BtnScan = New-Object System.Windows.Forms.Button; $BtnScan.Text="RE-SCAN DRIVES"; $BtnScan.Location="10,280"; $BtnScan.Size="580,30"; $BtnScan.FlatStyle="Flat"; $BtnScan.BackColor="DodgerBlue"; $PnlLeft.Controls.Add($BtnScan)

# OPTIONS
$GrpOpt = New-Object System.Windows.Forms.GroupBox; $GrpOpt.Text=" OPTIONS "; $GrpOpt.Location="10,320"; $GrpOpt.Size="580,90"; $GrpOpt.ForeColor="Lime"; $PnlLeft.Controls.Add($GrpOpt)
$ChkBackupDrv = New-Object System.Windows.Forms.CheckBox; $ChkBackupDrv.Text="Backup Drivers"; $ChkBackupDrv.Location="20,30"; $ChkBackupDrv.AutoSize=$true; $ChkBackupDrv.Checked=$true; $ChkBackupDrv.ForeColor="White"; $GrpOpt.Controls.Add($ChkBackupDrv)
$ChkBackupReg = New-Object System.Windows.Forms.CheckBox; $ChkBackupReg.Text="Backup Registry"; $ChkBackupReg.Location="20,60"; $ChkBackupReg.AutoSize=$true; $ChkBackupReg.ForeColor="White"; $GrpOpt.Controls.Add($ChkBackupReg)
$ChkGameMode = New-Object System.Windows.Forms.CheckBox; $ChkGameMode.Text="Tắt Game Mode"; $ChkGameMode.Location="200,30"; $ChkGameMode.AutoSize=$true; $ChkGameMode.Checked=$true; $ChkGameMode.ForeColor="White"; $GrpOpt.Controls.Add($ChkGameMode)

# 3. ACTIONS
$PnlAct = New-Object System.Windows.Forms.Panel; $PnlAct.Location="640,120"; $PnlAct.Size="420,420"; $PnlAct.BackColor="45, 45, 48"; $PnlAct.BorderStyle="FixedSingle"; $Form.Controls.Add($PnlAct)

# AUTO MODE
$GrpAuto = New-Object System.Windows.Forms.GroupBox; $GrpAuto.Text=" MODE 1: AUTO (HEADLESS) "; $GrpAuto.Location="10,10"; $GrpAuto.Size="400,110"; $GrpAuto.ForeColor="Orange"; $PnlAct.Controls.Add($GrpAuto)
$BtnAutoRun = New-Object System.Windows.Forms.Button; $BtnAutoRun.Text="🚀 CHẠY AUTO (Full Automatic)"; $BtnAutoRun.Location="10,30"; $BtnAutoRun.Size="380,60"; $BtnAutoRun.FlatStyle="Flat"; $BtnAutoRun.BackColor="Orange"; $BtnAutoRun.ForeColor="Black"; $GrpAuto.Controls.Add($BtnAutoRun)

# MANUAL MODE
$GrpMan = New-Object System.Windows.Forms.GroupBox; $GrpMan.Text=" MODE 2: MANUAL "; $GrpMan.Location="10,130"; $GrpMan.Size="400,180"; $GrpMan.ForeColor="Cyan"; $PnlAct.Controls.Add($GrpMan)
$LblSelWin = New-Object System.Windows.Forms.Label; $LblSelWin.Text="Target: [None]"; $LblSelWin.Location="10,25"; $LblSelWin.AutoSize=$true; $LblSelWin.ForeColor="Yellow"; $GrpMan.Controls.Add($LblSelWin)
$LblSelBoot = New-Object System.Windows.Forms.Label; $LblSelBoot.Text="Boot: [None]"; $LblSelBoot.Location="10,50"; $LblSelBoot.AutoSize=$true; $LblSelBoot.ForeColor="Magenta"; $GrpMan.Controls.Add($LblSelBoot)
$ChkFmt = New-Object System.Windows.Forms.CheckBox; $ChkFmt.Text="Format Target"; $ChkFmt.Location="200,25"; $ChkFmt.AutoSize=$true; $ChkFmt.Checked=$true; $ChkFmt.ForeColor="White"; $GrpMan.Controls.Add($ChkFmt)
$BtnManRun = New-Object System.Windows.Forms.Button; $BtnManRun.Text="🔥 CHẠY MANUAL"; $BtnManRun.Location="10,80"; $BtnManRun.Size="380,60"; $BtnManRun.FlatStyle="Flat"; $BtnManRun.BackColor="DarkRed"; $BtnManRun.ForeColor="White"; $GrpMan.Controls.Add($BtnManRun)

# EXTRAS
$BtnWinToHDD = New-Object System.Windows.Forms.Button; $BtnWinToHDD.Text="Download WinToHDD"; $BtnWinToHDD.Location="10,360"; $BtnWinToHDD.Size="190,40"; $BtnWinToHDD.FlatStyle="Flat"; $BtnWinToHDD.BackColor="DimGray"; $PnlAct.Controls.Add($BtnWinToHDD)
$BtnSetup = New-Object System.Windows.Forms.Button; $BtnSetup.Text="Run Setup.exe"; $BtnSetup.Location="210,360"; $BtnSetup.Size="190,40"; $BtnSetup.FlatStyle="Flat"; $BtnSetup.BackColor="DimGray"; $PnlAct.Controls.Add($BtnSetup)

# LOG
$Global:TxtLog = New-Object System.Windows.Forms.TextBox; $Global:TxtLog.Location="20,550"; $Global:TxtLog.Size="1040,100"; $Global:TxtLog.Multiline=$true; $Global:TxtLog.BackColor="Black"; $Global:TxtLog.ForeColor="Lime"; $Global:TxtLog.ReadOnly=$true; $Global:TxtLog.ScrollBars="Vertical"; $Form.Controls.Add($Global:TxtLog)

# =========================
#   LOGIC
# =========================

function Load-Grid {
    $GridPart.Rows.Clear()
    Mount-All-Partitions
    $Vols = Get-WmiObject Win32_Volume
    foreach ($V in $Vols) {
        if ($V.DriveLetter) {
            $Size = [math]::Round($V.Capacity / 1GB, 1)
            $Ltr = $V.DriveLetter
            $Status = ""
            if ($Ltr -eq $Global:SelWinPart) { $Status = "WIN TARGET" }
            if ($Ltr -eq $Global:SelBootPart) { $Status = "BOOT SYSTEM" }
            if ($Ltr -eq $Global:SelectedInstall) { $Status = "AUTO TARGET" }
            
            $Row = $GridPart.Rows.Add($Ltr, $V.Label, $Size, $V.FileSystem, $Status)
            if ($Status -match "TARGET") { $GridPart.Rows[$Row].DefaultCellStyle.BackColor = "Maroon"; $GridPart.Rows[$Row].DefaultCellStyle.ForeColor = "White" }
            if ($Status -eq "BOOT SYSTEM") { $GridPart.Rows[$Row].DefaultCellStyle.BackColor = "DarkGreen"; $GridPart.Rows[$Row].DefaultCellStyle.ForeColor = "White" }
        }
    }
}

$Cms = New-Object System.Windows.Forms.ContextMenuStrip
$MiAuto = $Cms.Items.Add("🎯 Chọn làm ổ Cài Win cho Mode 1 (AUTO)"); 
$MiWin = $Cms.Items.Add("💾 Chọn làm ổ Cài Win cho Mode 2 (MANUAL)"); 
$MiBoot = $Cms.Items.Add("🚀 Chọn làm ổ BOOT cho Mode 2 (MANUAL)"); 

$MiAuto.Add_Click({ if($GridPart.SelectedRows.Count -gt 0){ $Global:SelectedInstall = $GridPart.SelectedRows[0].Cells[0].Value.Replace(":",""); Load-Grid } })
$MiWin.Add_Click({ if($GridPart.SelectedRows.Count -gt 0){ $Global:SelWinPart = $GridPart.SelectedRows[0].Cells[0].Value; $LblSelWin.Text = "Target: $($Global:SelWinPart)"; Load-Grid } })
$MiBoot.Add_Click({ if($GridPart.SelectedRows.Count -gt 0){ $Global:SelBootPart = $GridPart.SelectedRows[0].Cells[0].Value; $LblSelBoot.Text = "Boot: $($Global:SelBootPart)"; Load-Grid } })
$GridPart.ContextMenuStrip = $Cms

$BtnScan.Add_Click({ Load-Grid })
$BtnISO.Add_Click({ $OFD = New-Object System.Windows.Forms.OpenFileDialog; $OFD.Filter="ISO/WIM|*.iso;*.wim;*.esd"; if($OFD.ShowDialog() -eq "OK") { $TxtISO.Text=$OFD.FileName } })

$BtnMount.Add_Click({
    if(!$TxtISO.Text){return}
    Log-Write "Mounting..."
    if ($TxtISO.Text.EndsWith(".iso")) {
        Mount-DiskImage $TxtISO.Text -ErrorAction SilentlyContinue | Out-Null
        $Vol = (Get-DiskImage $TxtISO.Text | Get-Volume).DriveLetter + ":"
        $Global:IsoMounted = $Vol
        $Wim = "$Vol\sources\install.wim"
        if (!(Test-Path $Wim)) { $Wim = "$Vol\sources\install.esd" }
    } else { $Wim = $TxtISO.Text }
    $Global:SelSource = $Wim
    Log-Write "Source: $Wim"
    $CbIndex.Items.Clear()
    $Raw = cmd /c "dism /Get-WimInfo /WimFile:`"$Wim`""
    $Raw | Select-String "Name :" | % { $CbIndex.Items.Add($_.ToString().Trim()) | Out-Null }
    if($CbIndex.Items.Count -gt 0){$CbIndex.SelectedIndex=0}
})

# --- AUTO MODE ---
$BtnAutoRun.Add_Click({
    if (!$Global:SelectedInstall) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn ổ đích (Auto Mode)!"); return }
    if (!$Global:IsoMounted) { [System.Windows.Forms.MessageBox]::Show("Chưa Mount ISO!"); return }
    
    $Form.Cursor = "WaitCursor"
    Log-Write "STARTING AUTO HEADLESS..."
    $InstallDrive = "$($Global:SelectedInstall):"
    
    try { cmd /c "label $InstallDrive $($Global:TargetLabel)" } catch {}
    
    $SrcDrive = $InstallDrive 
    Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" | % { if($_.DeviceID -ne $InstallDrive -and $_.FreeSpace -gt 8GB){ $SrcDrive = $_.DeviceID } }
    $WinSource = "$SrcDrive\WinSource_PhatTan"
    if (Test-Path $WinSource) { Remove-Item $WinSource -Recurse -Force -EA 0 }
    New-Item -ItemType Directory -Path "$WinSource\sources" -Force | Out-Null
    New-Item -ItemType Directory -Path "$WinSource\boot" -Force | Out-Null
    
    if ($ChkBackupDrv.Checked) {
        $DrvPath = "$WinSource\Backups\Drivers"
        New-Item -ItemType Directory -Path $DrvPath -Force | Out-Null
        Log-Write "Backing up Drivers..."
        try { dism /online /export-driver /destination:"$DrvPath" | Out-Null } catch { Log-Write "Driver backup warning." }
    }
    if ($ChkBackupReg.Checked) {
        $RegPath = "$WinSource\Backups\Registry"
        New-Item -ItemType Directory -Path $RegPath -Force | Out-Null
        Log-Write "Backing up Registry..."
        cmd /c "reg save HKLM\SYSTEM `"$RegPath\SYSTEM`" /y"
        cmd /c "reg save HKLM\SOFTWARE `"$RegPath\SOFTWARE`" /y"
    }

    Copy-Item "$Global:IsoMounted\sources\boot.wim" "$WinSource\sources\boot.wim" -Force
    Copy-Item "$Global:IsoMounted\boot\boot.sdi" "$WinSource\boot\boot.sdi" -Force
    
    $BootCommand = 'cmd /c "wpeinit & for /L %n in (1,0,30) do ( for %i in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist %i:\WinSource_PhatTan\Launcher.cmd ( start /MIN %i:\WinSource_PhatTan\Launcher.cmd & exit ) & timeout /t 1 )"'
    $XmlBoot = "<?xml version='1.0'?><unattend xmlns='urn:schemas-microsoft-com:unattend'><settings pass='windowsPE'><component name='Microsoft-Windows-Setup' processorArchitecture='amd64' publicKeyToken='31bf3856ad364e35' language='neutral' versionScope='nonSxS'><RunSynchronous><RunSynchronousCommand xmlns:wcm='http://schemas.microsoft.com/WMIConfig/2002/State' wcm:action='add'><Order>1</Order><Path>$BootCommand</Path></RunSynchronousCommand></RunSynchronous></component></settings></unattend>"
    [IO.File]::WriteAllText("$SrcDrive\autounattend.xml", $XmlBoot, [System.Text.Encoding]::UTF8)
    
    $Launcher = "@echo off`r`ntaskkill /F /IM setup.exe >nul 2>&1`r`nwpeinit`r`n:LOOP`r`ntaskkill /F /IM setup.exe >nul 2>&1`r`nfor %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist %%d:\WinSource_PhatTan\AutoInstall.cmd ( call %%d:\WinSource_PhatTan\AutoInstall.cmd & exit )`r`ntimeout /t 1 >nul & goto LOOP"
    [IO.File]::WriteAllText("$WinSource\Launcher.cmd", $Launcher, [System.Text.Encoding]::ASCII)
    
    $Key = Get-Key-From-Json-Tree -EditionFullname $CbIndex.SelectedItem.ToString()
    $SetupComplete = if($Key){ "@echo off`r`ncscript //b %windir%\system32\slmgr.vbs /ipk $Key" } else { "@echo No Key" }
    [IO.File]::WriteAllText("$WinSource\SetupComplete.cmd", $SetupComplete, [System.Text.Encoding]::ASCII)
    
    $XmlOobe = "<?xml version='1.0'?><unattend xmlns='urn:schemas-microsoft-com:unattend'><settings pass='oobeSystem'><component name='Microsoft-Windows-Shell-Setup' processorArchitecture='amd64' publicKeyToken='31bf3856ad364e35' language='neutral' versionScope='nonSxS'><OOBE><HideEULAPage>true</HideEULAPage><HideLocalAccountScreen>true</HideLocalAccountScreen><HideOnlineAccountScreens>true</HideOnlineAccountScreens><ProtectYourPC>3</ProtectYourPC></OOBE><UserAccounts><LocalAccounts><LocalAccount wcm:action='add'><Password><Value></Value><PlainText>true</PlainText></Password><DisplayName>Admin</DisplayName><Group>Administrators</Group><Name>Admin</Name></LocalAccount></LocalAccounts></UserAccounts></component></settings></unattend>"
    [IO.File]::WriteAllText("$WinSource\oobe_config.xml", $XmlOobe, [System.Text.Encoding]::UTF8)
    
    $Idx = $CbIndex.SelectedIndex + 1
    
    $RestoreCmd = ""
    if ($ChkBackupDrv.Checked) { $RestoreCmd += "`r`necho Restoring Drivers... & dism /Image:%TARGET% /Add-Driver /Driver:`"%~dp0Backups\Drivers`" /Recurse /ForceUnsigned" }
    $TweakCmd = ""
    if ($ChkGameMode.Checked) { 
        $TweakCmd += "`r`necho Optimizing Game Mode...`r`nreg load HKLM\OFFLINE %TARGET%\Windows\System32\config\SOFTWARE"
        $TweakCmd += "`r`nreg add `"HKLM\OFFLINE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR`" /v value /t REG_DWORD /d 0 /f"
        $TweakCmd += "`r`nreg unload HKLM\OFFLINE"
    }

    $AutoCmd = "@echo off`r`ntaskkill /F /IM setup.exe >nul 2>&1`r`nfor %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do ( vol %%d: | find `"$($Global:TargetLabel)`" >nul && set TARGET=%%d: )`r`nif `"%TARGET%`"==`"`" exit`r`nformat %TARGET% /fs:ntfs /q /y /v:Windows`r`ndism /Apply-Image /ImageFile:`"$($Global:SelSource)`" /Index:$Idx /ApplyDir:%TARGET%`r`nmkdir %TARGET%\Windows\Panther`r`ncopy /y `"%~dp0oobe_config.xml`" `"%TARGET%\Windows\Panther\unattend.xml`"`r`nmkdir %TARGET%\Windows\Setup\Scripts`r`ncopy /y `"%~dp0SetupComplete.cmd`" `"%TARGET%\Windows\Setup\Scripts\SetupComplete.cmd`"$RestoreCmd $TweakCmd`r`nbcdboot %TARGET%\Windows /f ALL`r`nwpeutil reboot"
    [IO.File]::WriteAllText("$WinSource\AutoInstall.cmd", $AutoCmd, [System.Text.Encoding]::ASCII)
    
    $FW = if ((Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control -Name PEFirmwareType -EA 0).PEFirmwareType -eq 2) { "UEFI" } else { "BIOS" }
    $WL = if ($FW -eq "UEFI") { "\windows\system32\boot\winload.efi" } else { "\windows\system32\winload.exe" }
    
    cmd /c "bcdedit /create {ramdiskoptions} /d `"PHAT TAN RAMDISK`"" >$null 2>&1
    cmd /c "bcdedit /set {ramdiskoptions} ramdisksdidevice partition=$SrcDrive"
    cmd /c "bcdedit /set {ramdiskoptions} ramdisksdipath \WinSource_PhatTan\boot\boot.sdi"
    
    $Out = cmd /c "bcdedit /create /d `"PHAT TAN AUTO INSTALLER`" /application osloader"
    $GUID = ([regex]'{[a-z0-9-]{36}}').Match([string]$Out).Value
    cmd /c "bcdedit /set $GUID device `"ramdisk=[$SrcDrive]\WinSource_PhatTan\sources\boot.wim,{ramdiskoptions}`""
    cmd /c "bcdedit /set $GUID osdevice `"ramdisk=[$SrcDrive]\WinSource_PhatTan\sources\boot.wim,{ramdiskoptions}`""
    cmd /c "bcdedit /set $GUID path $WL"
    cmd /c "bcdedit /set $GUID systemroot \windows"
    cmd /c "bcdedit /set $GUID winpe yes"
    cmd /c "bcdedit /set $GUID detecthal yes"
    cmd /c "bcdedit /displayorder $GUID /addfirst"
    
    $Form.Cursor = "Default"
    [System.Windows.Forms.MessageBox]::Show("Auto Installer Ready! Reboot now.", "Success")
})

# --- MANUAL MODE ---
$BtnManRun.Add_Click({
    if (!$Global:SelSource -or !$Global:SelWinPart -or !$Global:SelBootPart) { [System.Windows.Forms.MessageBox]::Show("Thiếu thông tin!", "Error"); return }
    if ([System.Windows.Forms.MessageBox]::Show("Dữ liệu trên $($Global:SelWinPart) sẽ mất!", "Confirm", "YesNo") -eq "Yes") {
        $Form.Cursor = "WaitCursor"
        $Idx = $CbIndex.SelectedIndex + 1
        if ($ChkFmt.Checked) { Log-Write "Formatting..."; cmd /c "format $($Global:SelWinPart) /fs:ntfs /q /y /v:Windows" }
        Smart-Apply-Image -ImagePath $Global:SelSource -Index $Idx -ApplyDir $Global:SelWinPart
        if ($ChkReboot.Checked) { Log-Write "Booting..."; Exec-Cmd "bcdboot $($Global:SelWinPart)\Windows /s $($Global:SelBootPart) /f ALL" }
        $Form.Cursor = "Default"
        [System.Windows.Forms.MessageBox]::Show("Done Manual!", "Success")
    }
})

$BtnWinToHDD.Add_Click({ try { (New-Object System.Net.WebClient).DownloadFile("https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/WinToHDD.exe", "$env:TEMP\WinToHDD.exe"); Start-Process "$env:TEMP\WinToHDD.exe" } catch { Log-Write "Download Fail" } })
$BtnSetup.Add_Click({ if($Global:IsoMounted){Start-Process "$($Global:IsoMounted)\setup.exe"} })

Load-Grid
$Form.ShowDialog() | Out-Null
