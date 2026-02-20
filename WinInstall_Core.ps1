<#
  WININSTALL CORE V23.7 (TRINITY UUID & AUTOMATION ENGINE)
  Author: Phat Tan PC

  UPDATE V23.7:
  1. Thêm Tùy biến OOBE: Tự tạo Local Admin, bỏ qua đăng nhập Microsoft Account, setup sẵn Keyboard/Region.
  2. Thêm Anti-Win 11: Tự động ghi BypassNRO và LabConfig (TPM 2.0, CPU, SecureBoot) vào Registry Offline.
  3. Nút "Run Setup.exe" cũng được tiêm sẵn thuốc giải Win 11 vào RAM WinPE trước khi chạy.
#>

# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit 
}

# --- GLOBAL VARS ---
$Global:LogPath     = "$env:SystemDrive\WinInstall_V23.log"
$Global:SelSource   = $null
$Global:SelWinUUID  = $null
$Global:SelBootUUID = $null
$Global:AutoTargetUUID = $null
$Global:IsoMounted  = $null
$Global:IsWinPE     = (Test-Path "X:\Windows\System32")

# --- HELPER FUNCTIONS ---
function Log-Write { 
    param([string]$Msg) 
    $Time = Get-Date -Format "HH:mm:ss"
    $Line = "[$Time] $Msg"
    try { $Global:TxtLog.AppendText("$Line`r`n"); $Global:TxtLog.SelectionStart = $Global:TxtLog.Text.Length; $Global:TxtLog.ScrollToCaret() } catch {}
    try { Add-Content -Path $Global:LogPath -Value $Line -Force } catch {} 
}

# --- GUI INIT ---
Add-Type -AssemblyName System.Windows.Forms

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WININSTALL CORE V23.7 (AUTO-BYPASS ENGINE)"
$Form.BackColor = "30, 30, 30"; $Form.ForeColor = "White"
$Form.Size = "1100, 720"; $Form.StartPosition = "CenterScreen"; $Form.AutoScroll = $true

$LblTitle = New-Object System.Windows.Forms.Label
$LblTitle.Text = "🚀 WININSTALL V23.7 (ANTI-WIN11 & OOBE BYPASS)"
$LblTitle.Font = New-Object System.Drawing.Font("Consolas", 18, [System.Drawing.FontStyle]::Bold)
$LblTitle.ForeColor = "Cyan"; $LblTitle.AutoSize = $true; $LblTitle.Location = "20, 10"
$Form.Controls.Add($LblTitle)

# === LAYOUT ===

# 1. SOURCE
$PnlSource = New-Object System.Windows.Forms.Panel; $PnlSource.Location="20,50"; $PnlSource.Size="1040,60"; $PnlSource.BackColor="45, 45, 48"; $PnlSource.BorderStyle="FixedSingle"; $Form.Controls.Add($PnlSource)
$BtnISO = New-Object System.Windows.Forms.Button; $BtnISO.Text="CHỌN ISO"; $BtnISO.Location="10,15"; $BtnISO.Size="100,30"; $BtnISO.FlatStyle="Flat"; $BtnISO.BackColor="DimGray"; $PnlSource.Controls.Add($BtnISO)
$TxtISO = New-Object System.Windows.Forms.TextBox; $TxtISO.Location="120,18"; $TxtISO.Size="500,25"; $TxtISO.BackColor="30, 30, 30"; $TxtISO.ForeColor="White"; $TxtISO.ReadOnly=$true; $PnlSource.Controls.Add($TxtISO)
$BtnMount = New-Object System.Windows.Forms.Button; $BtnMount.Text="MOUNT"; $BtnMount.Location="630,15"; $BtnMount.Size="80,30"; $BtnMount.FlatStyle="Flat"; $BtnMount.BackColor="DarkGreen"; $PnlSource.Controls.Add($BtnMount)
$CbIndex = New-Object System.Windows.Forms.ComboBox; $CbIndex.Location="720,18"; $CbIndex.Size="300,30"; $CbIndex.DropDownStyle="DropDownList"; $CbIndex.BackColor="30, 30, 30"; $CbIndex.ForeColor="White"; $PnlSource.Controls.Add($CbIndex)

# 2. DISK MAP & OPTIONS
$PnlLeft = New-Object System.Windows.Forms.Panel; $PnlLeft.Location="20,120"; $PnlLeft.Size="600,420"; $PnlLeft.BackColor="45, 45, 48"; $PnlLeft.BorderStyle="FixedSingle"; $Form.Controls.Add($PnlLeft)
$GridPart = New-Object System.Windows.Forms.DataGridView; $GridPart.Location="10,10"; $GridPart.Size="580,250"; $GridPart.BackgroundColor="30, 30, 30"; $GridPart.ForeColor="Black"; $GridPart.RowHeadersVisible=$false; $GridPart.SelectionMode="FullRowSelect"; $GridPart.ReadOnly=$true; $GridPart.AutoSizeColumnsMode="Fill"
[void]$GridPart.Columns.Add("Disk","Disk"); [void]$GridPart.Columns.Add("Ltr","Let"); [void]$GridPart.Columns.Add("Label","Label"); [void]$GridPart.Columns.Add("Size","Size (GB)"); [void]$GridPart.Columns.Add("FS","FS"); [void]$GridPart.Columns.Add("Role","Vai Trò")
[void]$GridPart.Columns.Add("UUID","UUID"); $GridPart.Columns["UUID"].Visible = $false
$PnlLeft.Controls.Add($GridPart)

$BtnScan = New-Object System.Windows.Forms.Button; $BtnScan.Text="RE-SCAN DRIVES (TRINITY MODE)"; $BtnScan.Location="10,270"; $BtnScan.Size="580,30"; $BtnScan.FlatStyle="Flat"; $BtnScan.BackColor="DodgerBlue"; $PnlLeft.Controls.Add($BtnScan)

# BẢNG TÙY CHỌN (NÂNG CẤP V23.7)
$GrpOpt = New-Object System.Windows.Forms.GroupBox; $GrpOpt.Text=" VIP OPTIONS (TỰ ĐỘNG HÓA) "; $GrpOpt.Location="10,310"; $GrpOpt.Size="580,100"; $GrpOpt.ForeColor="Lime"; $PnlLeft.Controls.Add($GrpOpt)
$ChkGameMode = New-Object System.Windows.Forms.CheckBox; $ChkGameMode.Text="Tắt Game DVR (Chống Drop FPS)"; $ChkGameMode.Location="20,25"; $ChkGameMode.AutoSize=$true; $ChkGameMode.Checked=$true; $ChkGameMode.ForeColor="White"; $GrpOpt.Controls.Add($ChkGameMode)
$ChkOobe = New-Object System.Windows.Forms.CheckBox; $ChkOobe.Text="Bypass OOBE (Tự tạo Local Admin, Bỏ qua Setup Bàn phím/Ngôn ngữ)"; $ChkOobe.Location="20,48"; $ChkOobe.AutoSize=$true; $ChkOobe.Checked=$true; $ChkOobe.ForeColor="Yellow"; $GrpOpt.Controls.Add($ChkOobe)
$ChkWin11 = New-Object System.Windows.Forms.CheckBox; $ChkWin11.Text="Anti-Win 11 (Bypass TPM 2.0, SecureBoot, RAM, Bỏ qua Bắt buộc Wifi)"; $ChkWin11.Location="20,71"; $ChkWin11.AutoSize=$true; $ChkWin11.Checked=$true; $ChkWin11.ForeColor="Cyan"; $GrpOpt.Controls.Add($ChkWin11)

# 3. ACTIONS
$PnlAct = New-Object System.Windows.Forms.Panel; $PnlAct.Location="640,120"; $PnlAct.Size="420,420"; $PnlAct.BackColor="45, 45, 48"; $PnlAct.BorderStyle="FixedSingle"; $Form.Controls.Add($PnlAct)
$GrpAuto = New-Object System.Windows.Forms.GroupBox; $GrpAuto.Text=" MODE 1: SMART DEPLOY (CÀI THẲNG) "; $GrpAuto.Location="10,10"; $GrpAuto.Size="400,110"; $GrpAuto.ForeColor="Orange"; $PnlAct.Controls.Add($GrpAuto)
$BtnAutoRun = New-Object System.Windows.Forms.Button; $BtnAutoRun.Text="🚀 CÀI ĐẶT TRỰC TIẾP (LIVE GUI)"; $BtnAutoRun.Location="10,30"; $BtnAutoRun.Size="380,60"; $BtnAutoRun.FlatStyle="Flat"; $BtnAutoRun.BackColor="Orange"; $BtnAutoRun.ForeColor="Black"; $BtnAutoRun.Font = New-Object System.Drawing.Font("Segoe UI", 11, 1); $GrpAuto.Controls.Add($BtnAutoRun)

$GrpMan = New-Object System.Windows.Forms.GroupBox; $GrpMan.Text=" MODE 2: MANUAL "; $GrpMan.Location="10,130"; $GrpMan.Size="400,180"; $GrpMan.ForeColor="Cyan"; $PnlAct.Controls.Add($GrpMan)
$LblSelWin = New-Object System.Windows.Forms.Label; $LblSelWin.Text="Target: [None]"; $LblSelWin.Location="10,25"; $LblSelWin.AutoSize=$true; $LblSelWin.ForeColor="Yellow"; $GrpMan.Controls.Add($LblSelWin)
$LblSelBoot = New-Object System.Windows.Forms.Label; $LblSelBoot.Text="Boot: [None]"; $LblSelBoot.Location="10,50"; $LblSelBoot.AutoSize=$true; $LblSelBoot.ForeColor="Magenta"; $GrpMan.Controls.Add($LblSelBoot)
$ChkFmt = New-Object System.Windows.Forms.CheckBox; $ChkFmt.Text="Format Target"; $ChkFmt.Location="200,25"; $ChkFmt.AutoSize=$true; $ChkFmt.Checked=$true; $ChkFmt.ForeColor="White"; $GrpMan.Controls.Add($ChkFmt)
$BtnManRun = New-Object System.Windows.Forms.Button; $BtnManRun.Text="🔥 CHẠY MANUAL"; $BtnManRun.Location="10,80"; $BtnManRun.Size="380,60"; $BtnManRun.FlatStyle="Flat"; $BtnManRun.BackColor="DarkRed"; $BtnManRun.ForeColor="White"; $GrpMan.Controls.Add($BtnManRun)

$BtnWinToHDD = New-Object System.Windows.Forms.Button; $BtnWinToHDD.Text="Download WinToHDD"; $BtnWinToHDD.Location="10,360"; $BtnWinToHDD.Size="190,40"; $BtnWinToHDD.FlatStyle="Flat"; $BtnWinToHDD.BackColor="DimGray"; $PnlAct.Controls.Add($BtnWinToHDD)
$BtnSetup = New-Object System.Windows.Forms.Button; $BtnSetup.Text="Run Setup.exe (Patched)"; $BtnSetup.Location="210,360"; $BtnSetup.Size="190,40"; $BtnSetup.FlatStyle="Flat"; $BtnSetup.BackColor="DimGray"; $BtnSetup.ForeColor="Cyan"; $PnlAct.Controls.Add($BtnSetup)

$Global:TxtLog = New-Object System.Windows.Forms.TextBox; $Global:TxtLog.Location="20,550"; $Global:TxtLog.Size="1040,100"; $Global:TxtLog.Multiline=$true; $Global:TxtLog.BackColor="Black"; $Global:TxtLog.ForeColor="Lime"; $Global:TxtLog.ReadOnly=$true; $Global:TxtLog.ScrollBars="Vertical"; $Global:TxtLog.Font = New-Object System.Drawing.Font("Consolas", 9); $Form.Controls.Add($Global:TxtLog)

$Global:DeploySeconds = 0
$Global:TimerDeploy = New-Object System.Windows.Forms.Timer; $Global:TimerDeploy.Interval = 1000
$Global:TimerDeploy.Add_Tick({ 
    $Global:DeploySeconds++
    $m = [math]::Floor($Global:DeploySeconds / 60); $s = $Global:DeploySeconds % 60
    $BtnAutoRun.Text = "ĐANG XẢ NÉN LIVE... ($m phút $s giây)" 
})

# =========================
#   LOGIC GIAO DIỆN (TRINITY)
# =========================

function Load-Grid {
    $GridPart.Rows.Clear()
    $HasStorage = [bool](Get-Command Get-Volume -ErrorAction SilentlyContinue)
    
    if ($HasStorage) {
        $Vols = Get-Volume | Where-Object DriveType -eq 'Fixed'
        foreach ($V in $Vols) {
            $Size = [math]::Round($V.Size / 1GB, 1); if ($Size -lt 0.1) { continue }
            $Ltr = if ($V.DriveLetter) { "$($V.DriveLetter):" } else { "Ẩn" }
            $UUID = $V.UniqueId
            $DiskNum = try { (Get-Partition -Volume $V -ErrorAction SilentlyContinue).DiskNumber } catch { "-" }
            
            $Status = ""
            if ($UUID -eq $Global:SelWinUUID) { $Status = "WIN TARGET" }
            if ($UUID -eq $Global:SelBootUUID) { $Status = "BOOT SYSTEM" }
            if ($UUID -eq $Global:AutoTargetUUID) { $Status = "AUTO TARGET" }
            
            $Row = $GridPart.Rows.Add($DiskNum, $Ltr, $V.FileSystemLabel, $Size, $V.FileSystem, $Status, $UUID)
            if ($Status -match "TARGET") { $GridPart.Rows[$Row].DefaultCellStyle.BackColor = "Maroon"; $GridPart.Rows[$Row].DefaultCellStyle.ForeColor = "White" }
            if ($Status -eq "BOOT SYSTEM") { $GridPart.Rows[$Row].DefaultCellStyle.BackColor = "DarkGreen"; $GridPart.Rows[$Row].DefaultCellStyle.ForeColor = "White" }
        }
    } else {
        $Vols = Get-WmiObject Win32_Volume | Where-Object DriveType -eq 3
        foreach ($V in $Vols) {
            $Size = [math]::Round($V.Capacity / 1GB, 1); if ($Size -lt 0.1) { continue }
            $Ltr = if ($V.DriveLetter) { $V.DriveLetter } else { "Ẩn" }
            $UUID = $V.DeviceID 
            $DiskNum = "WMI"
            
            $Status = ""
            if ($UUID -eq $Global:SelWinUUID) { $Status = "WIN TARGET" }
            if ($UUID -eq $Global:SelBootUUID) { $Status = "BOOT SYSTEM" }
            if ($UUID -eq $Global:AutoTargetUUID) { $Status = "AUTO TARGET" }
            
            $Row = $GridPart.Rows.Add($DiskNum, $Ltr, $V.Label, $Size, $V.FileSystem, $Status, $UUID)
            if ($Status -match "TARGET") { $GridPart.Rows[$Row].DefaultCellStyle.BackColor = "Maroon"; $GridPart.Rows[$Row].DefaultCellStyle.ForeColor = "White" }
            if ($Status -eq "BOOT SYSTEM") { $GridPart.Rows[$Row].DefaultCellStyle.BackColor = "DarkGreen"; $GridPart.Rows[$Row].DefaultCellStyle.ForeColor = "White" }
        }
    }
}

$Cms = New-Object System.Windows.Forms.ContextMenuStrip
$MiAuto = $Cms.Items.Add("🎯 Chọn làm ổ Cài Win (MODE 1 AUTO)"); 
$MiWin = $Cms.Items.Add("💾 Chọn làm ổ Cài Win (MODE 2 MANUAL)"); 
$MiBoot = $Cms.Items.Add("🚀 Chọn làm ổ BOOT (MODE 2 MANUAL)"); 

$MiAuto.Add_Click({ if($GridPart.SelectedRows.Count -gt 0){ $Global:AutoTargetUUID = $GridPart.SelectedRows[0].Cells["UUID"].Value; Load-Grid } })
$MiWin.Add_Click({ if($GridPart.SelectedRows.Count -gt 0){ $Global:SelWinUUID = $GridPart.SelectedRows[0].Cells["UUID"].Value; $LblSelWin.Text = "Target: Đã chốt UUID"; Load-Grid } })
$MiBoot.Add_Click({ if($GridPart.SelectedRows.Count -gt 0){ $Global:SelBootUUID = $GridPart.SelectedRows[0].Cells["UUID"].Value; $LblSelBoot.Text = "Boot: Đã chốt UUID"; Load-Grid } })
$GridPart.ContextMenuStrip = $Cms

$BtnScan.Add_Click({ Load-Grid })
$BtnISO.Add_Click({ $OFD = New-Object System.Windows.Forms.OpenFileDialog; $OFD.Filter="ISO/WIM|*.iso;*.wim;*.esd"; if($OFD.ShowDialog() -eq "OK") { $TxtISO.Text=$OFD.FileName } })

$BtnMount.Add_Click({
    if(!$TxtISO.Text){return}
    Log-Write "Mounting ISO/WIM..."
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

# ==========================================
#   MODE 1: SMART DEPLOY ENGINE (UUID TRINITY + OOBE BYPASS)
# ==========================================
$BtnAutoRun.Add_Click({
    if (!$Global:AutoTargetUUID) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn Ổ Cài Win!", "Lỗi"); return }
    if (!$Global:IsoMounted -and !$Global:SelSource) { [System.Windows.Forms.MessageBox]::Show("Chưa Mount ISO!", "Lỗi"); return }
    
    $SourcePath = $Global:SelSource
    $ImageIdx = $CbIndex.SelectedIndex + 1

    $OsUUID = (Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$($env:SystemDrive)'").VolumeSerialNumber
    $TargetSerial = (Get-WmiObject Win32_Volume -Filter "DeviceID='$($Global:AutoTargetUUID -replace '\\','\\')'").SerialNumber
    if (-not $Global:IsWinPE -and $OsUUID -and ($OsUUID -eq $TargetSerial)) {
        [System.Windows.Forms.MessageBox]::Show("LỖI CHÍ MẠNG: Đang chạy tool trên Windows sống. Không được Format tự sát!", "BẢO VỆ TỰ SÁT", 0, 16); return
    }

    if ([System.Windows.Forms.MessageBox]::Show("Dữ liệu trên phân vùng đích sẽ bị FORMAT SẠCH SẼ! Khởi chạy tiến trình?", "XÁC NHẬN FORMAT", 4, 48) -ne "Yes") { return }

    $BtnAutoRun.Enabled = $false; $BtnManRun.Enabled = $false
    $Global:DeploySeconds = 0; $Global:TimerDeploy.Start()
    
    $Global:SyncUI = [hashtable]::Synchronized(@{ LogBox = $Global:TxtLog; Btn = $BtnAutoRun; Timer = $Global:TimerDeploy; TargetUUID = $Global:AutoTargetUUID })

    $Runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $Runspace.Open()
    $Runspace.SessionStateProxy.SetVariable("Source", $SourcePath)
    $Runspace.SessionStateProxy.SetVariable("Idx", $ImageIdx)
    $Runspace.SessionStateProxy.SetVariable("ChkGameMode", $ChkGameMode.Checked)
    $Runspace.SessionStateProxy.SetVariable("ChkOobe", $ChkOobe.Checked)
    $Runspace.SessionStateProxy.SetVariable("ChkWin11", $ChkWin11.Checked)
    $Runspace.SessionStateProxy.SetVariable("Sync", $Global:SyncUI)
    
    $Pipeline = $Runspace.CreatePipeline()
    $Pipeline.Commands.AddScript({
        function Write-GuiLog ($Msg) {
            $Time = (Get-Date).ToString("HH:mm:ss")
            $Sync.LogBox.Invoke([action]{ 
                $Sync.LogBox.AppendText("[$Time] [AUTO] $Msg`r`n")
                $Sync.LogBox.SelectionStart = $Sync.LogBox.Text.Length; $Sync.LogBox.ScrollToCaret()
            })
        }

        function Mount-UUID-Native ($UUID) {
            $Used = (Get-WmiObject Win32_LogicalDisk).DeviceID.Replace(":","")
            $All = 67..90 | % { [char]$_ }
            $Free = $All | ? { $Used -notcontains $_ } | Select -First 1
            if ($Free) {
                $FreeLtr = "$($Free):"
                cmd /c "mountvol $FreeLtr `"$UUID`"" | Out-Null
                return $FreeLtr
            }
            return $null
        }

        function Smart-Boot-Hunter ($TargetUUID) {
            Write-GuiLog "-> Kích hoạt cảm biến săn Boot (Boot Hunter V3)..."
            $HasStorage = [bool](Get-Command Get-Partition -ErrorAction SilentlyContinue)
            if ($HasStorage) {
                try {
                    $Vol = Get-Volume -UniqueId $TargetUUID
                    $DiskNum = (Get-Partition -Volume $Vol).DiskNumber
                    $Efi = Get-Partition -DiskNumber $DiskNum | ? { $_.GptType -eq "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" } | Select -First 1
                    if ($Efi) { Write-GuiLog "-> Thấy EFI Partition."; return (Get-Volume -Partition $Efi).UniqueId }
                    $Act = Get-Partition -DiskNumber $DiskNum | ? { $_.IsActive -and $_.Size -lt 2GB } | Select -First 1
                    if ($Act) { Write-GuiLog "-> Thấy Active Partition."; return (Get-Volume -Partition $Act).UniqueId }
                } catch { Write-GuiLog "-> [Lớp 1] Fail, chuyển Lớp 2..." }
            }
            Write-GuiLog "-> [Lớp 2] Quét bằng WMI Engine..."
            $Vols = Get-WmiObject Win32_Volume
            $BootVol = $Vols | ? { ($_.FileSystem -eq "FAT32" -and $_.Capacity -lt 1000000000) -or ($_.Label -match "System|EFI" -and $_.Capacity -lt 2000000000) } | Select -First 1
            if ($BootVol) { return $BootVol.DeviceID }
            return $null
        }

        # 1. MOUNT TARGET & FORMAT
        Write-GuiLog "=> [1/6] Khởi tạo Mount-Point cho Target..."
        $TargetDrive = Mount-UUID-Native $Sync.TargetUUID
        if (!$TargetDrive) { Write-GuiLog "LỖI: Không thể ánh xạ đĩa!"; return }
        cmd /c "echo Y | format $TargetDrive /fs:ntfs /q /v:Windows >nul 2>&1"

        # 2. XẢ NÉN
        Write-GuiLog "=> [2/6] Bắn Image (Index $Idx) thẳng vào Target..."
        $WimSuccess = $false
        if (Get-Command Expand-WindowsImage -ErrorAction SilentlyContinue) {
            try { Expand-WindowsImage -ImagePath $Source -Index $Idx -ApplyPath "$TargetDrive\" -ErrorAction Stop | Out-Null; $WimSuccess = $true } catch {}
        }
        if (-not $WimSuccess) { cmd /c "dism /Apply-Image /ImageFile:`"$Source`" /Index:$Idx /ApplyDir:$TargetDrive\ 2>&1" | Out-Null }

        # 3. TWEAK (GameMode & Anti-Win 11)
        Write-GuiLog "=> [3/6] Nhúng kịch bản Tùy biến (Registry Tweak)..."
        if ($ChkGameMode -or $ChkWin11) {
            cmd /c "reg load HKLM\OFFLINESOFT $TargetDrive\Windows\System32\config\SOFTWARE >nul 2>&1"
            cmd /c "reg load HKLM\OFFLINESYS $TargetDrive\Windows\System32\config\SYSTEM >nul 2>&1"
            
            if ($ChkGameMode) {
                Write-GuiLog "-> Tắt Xbox Game DVR..."
                cmd /c "reg add `"HKLM\OFFLINESOFT\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR`" /v value /t REG_DWORD /d 0 /f >nul 2>&1"
            }
            if ($ChkWin11) {
                Write-GuiLog "-> Cấy Bypass Win 11 (BypassNRO - Bỏ qua Wifi/MS Account)..."
                cmd /c "reg add `"HKLM\OFFLINESOFT\Microsoft\Windows\CurrentVersion\OOBE`" /v BypassNRO /t REG_DWORD /d 1 /f >nul 2>&1"
                
                Write-GuiLog "-> Cấy LabConfig Bypass TPM/SecureBoot vào Hệ điều hành..."
                cmd /c "reg add `"HKLM\OFFLINESYS\Setup\LabConfig`" /v BypassTPMCheck /t REG_DWORD /d 1 /f >nul 2>&1"
                cmd /c "reg add `"HKLM\OFFLINESYS\Setup\LabConfig`" /v BypassSecureBootCheck /t REG_DWORD /d 1 /f >nul 2>&1"
                cmd /c "reg add `"HKLM\OFFLINESYS\Setup\LabConfig`" /v BypassRAMCheck /t REG_DWORD /d 1 /f >nul 2>&1"
                cmd /c "reg add `"HKLM\OFFLINESYS\Setup\LabConfig`" /v BypassCPUCheck /t REG_DWORD /d 1 /f >nul 2>&1"
                cmd /c "reg add `"HKLM\OFFLINESYS\Setup\LabConfig`" /v BypassStorageCheck /t REG_DWORD /d 1 /f >nul 2>&1"
            }
            cmd /c "reg unload HKLM\OFFLINESOFT >nul 2>&1"
            cmd /c "reg unload HKLM\OFFLINESYS >nul 2>&1"
        }

        # 4. UNATTEND OOBE (Tự động Setup phím/vùng/Admin)
        if ($ChkOobe) {
            Write-GuiLog "=> [4/6] Tạo Unattend bỏ qua cài đặt Bàn phím/Ngôn ngữ và tạo Admin..."
            $Panther = "$TargetDrive\Windows\Panther"; if (!(Test-Path $Panther)) { New-Item -ItemType Directory -Path $Panther -Force | Out-Null }
            $XmlOobe = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <InputLocale>0409:00000409</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UserLocale>en-US</UserLocale>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <ProtectYourPC>3</ProtectYourPC>
            </OOBE>
            <UserAccounts>
                <LocalAccounts>
                    <LocalAccount wcm:action="add">
                        <Name>Admin</Name>
                        <DisplayName>Admin</DisplayName>
                        <Group>Administrators</Group>
                        <Password><Value></Value><PlainText>true</PlainText></Password>
                    </LocalAccount>
                </LocalAccounts>
            </UserAccounts>
        </component>
    </settings>
</unattend>
"@
            [IO.File]::WriteAllText("$Panther\unattend.xml", $XmlOobe, [System.Text.Encoding]::UTF8)
        } else { Write-GuiLog "=> [4/6] Bỏ qua Unattend (Cài Win mặc định)." }

        # 5. BOOT HUNTER
        Write-GuiLog "=> [5/6] Săn Boot và ghi BCD..."
        $BootUUID = Smart-Boot-Hunter $Sync.TargetUUID
        if ($BootUUID) {
            $BootDrive = Mount-UUID-Native $BootUUID
            Write-GuiLog "-> Ánh xạ Boot Partition ra ổ ảo: $BootDrive"
            $BcdOut = cmd /c "bcdboot $TargetDrive\Windows /s $BootDrive /f ALL 2>&1"
            Write-GuiLog "-> $BcdOut"
        } else {
            Write-GuiLog "-> CẢNH BÁO: Phân vùng Boot không tồn tại! Ghi BCD tạm lên Target."
            $BcdOut = cmd /c "bcdboot $TargetDrive\Windows /f ALL 2>&1"
            Write-GuiLog "-> $BcdOut"
        }

        Write-GuiLog "======================================================"
        Write-GuiLog "🎉 HOÀN TẤT TRỌN VẸN! KHỞI ĐỘNG LẠI MÁY ĐỂ HÚP!"
        
        $Sync.Timer.Invoke([action]{ $Sync.Timer.Stop() })
        $Sync.Btn.Invoke([action]{ 
            $Sync.Btn.Enabled = $true
            $Sync.Btn.Text = "🚀 CÀI ĐẶT TRỰC TIẾP (LIVE GUI)"
            [System.Windows.Forms.MessageBox]::Show("Quá trình cài Windows đã hoàn tất thành công 100%!", "PHÁT TẤN PC VIP")
        })
    }) | Out-Null
    $Pipeline.InvokeAsync()
})

# --- MANUAL MODE ---
$BtnManRun.Add_Click({
    if (!$Global:SelSource -or !$Global:SelWinUUID -or !$Global:SelBootUUID) { [System.Windows.Forms.MessageBox]::Show("Phải chọn đủ File ISO, Ổ Cài Win và Ổ Boot!", "Error"); return }
    if ([System.Windows.Forms.MessageBox]::Show("Chắc chắn ghi đè Manual?", "Confirm", "YesNo") -eq "Yes") {
        $Form.Cursor = "WaitCursor"
        $Idx = $CbIndex.SelectedIndex + 1
        
        $Used = (Get-WmiObject Win32_LogicalDisk).DeviceID.Replace(":",""); $All = 67..90 | % { [char]$_ }
        $FreeWin = $All | ? { $Used -notcontains $_ } | Select -First 1; $T_Drv = "$($FreeWin):"; cmd /c "mountvol $T_Drv `"$($Global:SelWinUUID)`"" | Out-Null
        $Used += $FreeWin; $FreeBoot = $All | ? { $Used -notcontains $_ } | Select -First 1; $B_Drv = "$($FreeBoot):"; cmd /c "mountvol $B_Drv `"$($Global:SelBootUUID)`"" | Out-Null
        
        if ($ChkFmt.Checked) { cmd /c "echo Y | format $T_Drv /fs:ntfs /q /v:Windows >nul 2>&1" }
        
        $WimSuccess = $false
        if (Get-Command Expand-WindowsImage -ErrorAction SilentlyContinue) {
            try { Expand-WindowsImage -ImagePath $Global:SelSource -Index $Idx -ApplyPath "$T_Drv\" -ErrorAction Stop | Out-Null; $WimSuccess = $true } catch {}
        }
        if (-not $WimSuccess) { Exec-Cmd "dism /Apply-Image /ImageFile:`"$($Global:SelSource)`" /Index:$Idx /ApplyDir:$T_Drv\" }
        
        Exec-Cmd "bcdboot $T_Drv\Windows /s $B_Drv /f ALL"
        $Form.Cursor = "Default"
        [System.Windows.Forms.MessageBox]::Show("Manual Deploy Xong!", "Success")
    }
})

$BtnWinToHDD.Add_Click({ try { (New-Object System.Net.WebClient).DownloadFile("https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/WinToHDD.exe", "$env:TEMP\WinToHDD.exe"); Start-Process "$env:TEMP\WinToHDD.exe" } catch { Log-Write "Download Fail" } })

# ==============================================================
# NÚT SETUP.EXE ĐƯỢC "TIÊM THUỐC" ANTI WIN 11 NGAY TRONG RAM WinPE
# ==============================================================
$BtnSetup.Add_Click({ 
    if($Global:IsoMounted){
        Log-Write "Tiêm thuốc giải LabConfig (Anti-Win11) vào WinPE Registry..."
        cmd /c 'reg add "HKLM\SYSTEM\Setup\LabConfig" /v BypassTPMCheck /t REG_DWORD /d 1 /f >nul 2>&1'
        cmd /c 'reg add "HKLM\SYSTEM\Setup\LabConfig" /v BypassSecureBootCheck /t REG_DWORD /d 1 /f >nul 2>&1'
        cmd /c 'reg add "HKLM\SYSTEM\Setup\LabConfig" /v BypassRAMCheck /t REG_DWORD /d 1 /f >nul 2>&1'
        cmd /c 'reg add "HKLM\SYSTEM\Setup\LabConfig" /v BypassCPUCheck /t REG_DWORD /d 1 /f >nul 2>&1'
        cmd /c 'reg add "HKLM\SYSTEM\Setup\LabConfig" /v BypassStorageCheck /t REG_DWORD /d 1 /f >nul 2>&1'
        Log-Write "Chạy Setup.exe bản quyền Microsoft (Đã vá lỗi phần cứng)..."
        Start-Process "$($Global:IsoMounted)\setup.exe"
    } 
})

Load-Grid
$Form.ShowDialog() | Out-Null
