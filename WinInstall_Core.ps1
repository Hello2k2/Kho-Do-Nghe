<#
  WININSTALL CORE V23.5 (ULTIMATE UUID & SMART DEPLOY ENGINE)
  Author: Phat Tan PC

  UPDATE V23.5:
  1. Loại bỏ quản lý bằng ký tự ổ đĩa (Drive Letter). Sử dụng 100% Volume GUID.
  2. Giải quyết triệt để lỗi nhảy ký tự ổ đĩa trong WinPE/WinRE.
  3. Smart Boot Hunter V2: Tìm EFI/System dựa trên Disk Number (tránh USB) và GPT/MBR Flag (hỗ trợ cả EFI NTFS).
  4. Dynamic Mount: Tự động gán ký tự ảo (W:, S:) lúc xả Win để API không bị lỗi.
#>

# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit 
}

# --- GLOBAL VARS ---
$Global:LogPath     = "$env:SystemDrive\WinInstall_V23.log"
$Global:SelSource   = $null
$Global:SelWinUUID  = $null  # Thay vì Drive Letter, giờ dùng UUID
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

# Gán một ký tự ổ đĩa trống ngẫu nhiên cho một UUID để thao tác
function Mount-UUID-To-TempLetter {
    param([string]$UUID)
    if (!$UUID) { return $null }
    $Vol = Get-Volume -UniqueId $UUID -ErrorAction SilentlyContinue
    if ($Vol.DriveLetter) { return "$($Vol.DriveLetter):" }
    
    # Tìm ký tự trống
    $Used = (Get-Volume).DriveLetter | Where-Object { $_ }
    $All = 67..90 | ForEach-Object { [char]$_ } # C đến Z
    $Free = $All | Where-Object { $Used -notcontains $_ } | Select-Object -First 1
    
    if ($Free) {
        Get-Partition -Volume $Vol | Set-Partition -NewDriveLetter $Free -ErrorAction SilentlyContinue | Out-Null
        Log-Write "=> Ánh xạ UUID ẩn ra ký tự ảo: $($Free):"
        return "$($Free):"
    }
    return $null
}

# Thuật toán Săn Boot xịn xò (Theo Disk Number & Partition Flag)
function Săn-Boot-Partition-Bằng-UUID {
    param([string]$TargetUUID)
    if (!$TargetUUID) { return $null }
    
    try {
        $TargetVol = Get-Volume -UniqueId $TargetUUID
        $TargetPart = Get-Partition -Volume $TargetVol
        $DiskNum = $TargetPart.DiskNumber
        
        Log-Write "-> Đang quét Ổ cứng vật lý (Disk $DiskNum) để tìm Boot..."
        
        # 1. Tìm phân vùng EFI trên cùng ổ cứng (Dựa vào GPT Type GUID của EFI, đéo quan tâm NTFS hay FAT32)
        $EfiPart = Get-Partition -DiskNumber $DiskNum | Where-Object { $_.GptType -eq "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" } | Select-Object -First 1
        
        if ($EfiPart) {
            $BootVol = Get-Volume -Partition $EfiPart
            Log-Write "-> Đã tìm thấy EFI Partition (UUID: $($BootVol.UniqueId))"
            return $BootVol.UniqueId
        }

        # 2. Nếu là chuẩn cũ MBR, tìm phân vùng được đánh dấu Active
        $ActivePart = Get-Partition -DiskNumber $DiskNum | Where-Object { $_.IsActive -eq $true -and $_.Size -lt 2GB } | Select-Object -First 1
        if ($ActivePart) {
            $BootVol = Get-Volume -Partition $ActivePart
            Log-Write "-> Đã tìm thấy Active/System Partition (UUID: $($BootVol.UniqueId))"
            return $BootVol.UniqueId
        }
    } catch { Log-Write "-> Lỗi thuật toán săn Boot: $_" }
    
    return $null
}

# --- GUI INIT ---
Add-Type -AssemblyName System.Windows.Forms

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WININSTALL CORE V23.5 (UUID & BOOT HUNTER ENGINE)"
$Form.BackColor = "30, 30, 30"; $Form.ForeColor = "White"
$Form.Size = "1100, 720"; $Form.StartPosition = "CenterScreen"; $Form.AutoScroll = $true

$LblTitle = New-Object System.Windows.Forms.Label
$LblTitle.Text = "🚀 WININSTALL V23.5 (TRACKING BẰNG UUID)"
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

# 2. DISK MAP (Nâng cấp)
$PnlLeft = New-Object System.Windows.Forms.Panel; $PnlLeft.Location="20,120"; $PnlLeft.Size="600,420"; $PnlLeft.BackColor="45, 45, 48"; $PnlLeft.BorderStyle="FixedSingle"; $Form.Controls.Add($PnlLeft)
$GridPart = New-Object System.Windows.Forms.DataGridView; $GridPart.Location="10,10"; $GridPart.Size="580,260"; $GridPart.BackgroundColor="30, 30, 30"; $GridPart.ForeColor="Black"; $GridPart.RowHeadersVisible=$false; $GridPart.SelectionMode="FullRowSelect"; $GridPart.ReadOnly=$true; $GridPart.AutoSizeColumnsMode="Fill"
[void]$GridPart.Columns.Add("Disk","Disk"); [void]$GridPart.Columns.Add("Ltr","Let"); [void]$GridPart.Columns.Add("Label","Label"); [void]$GridPart.Columns.Add("Size","Size (GB)"); [void]$GridPart.Columns.Add("FS","FS"); [void]$GridPart.Columns.Add("Role","Vai Trò")
[void]$GridPart.Columns.Add("UUID","UUID"); $GridPart.Columns["UUID"].Visible = $false # Cột ẩn chứa UUID
$PnlLeft.Controls.Add($GridPart)

$BtnScan = New-Object System.Windows.Forms.Button; $BtnScan.Text="RE-SCAN DRIVES (UUID MODE)"; $BtnScan.Location="10,280"; $BtnScan.Size="580,30"; $BtnScan.FlatStyle="Flat"; $BtnScan.BackColor="DodgerBlue"; $PnlLeft.Controls.Add($BtnScan)

$GrpOpt = New-Object System.Windows.Forms.GroupBox; $GrpOpt.Text=" OPTIONS "; $GrpOpt.Location="10,320"; $GrpOpt.Size="580,90"; $GrpOpt.ForeColor="Lime"; $PnlLeft.Controls.Add($GrpOpt)
$ChkGameMode = New-Object System.Windows.Forms.CheckBox; $ChkGameMode.Text="Tắt Game Mode & Xbox DVR"; $ChkGameMode.Location="20,30"; $ChkGameMode.AutoSize=$true; $ChkGameMode.Checked=$true; $ChkGameMode.ForeColor="White"; $GrpOpt.Controls.Add($ChkGameMode)

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
$BtnSetup = New-Object System.Windows.Forms.Button; $BtnSetup.Text="Run Setup.exe"; $BtnSetup.Location="210,360"; $BtnSetup.Size="190,40"; $BtnSetup.FlatStyle="Flat"; $BtnSetup.BackColor="DimGray"; $PnlAct.Controls.Add($BtnSetup)

$Global:TxtLog = New-Object System.Windows.Forms.TextBox; $Global:TxtLog.Location="20,550"; $Global:TxtLog.Size="1040,100"; $Global:TxtLog.Multiline=$true; $Global:TxtLog.BackColor="Black"; $Global:TxtLog.ForeColor="Lime"; $Global:TxtLog.ReadOnly=$true; $Global:TxtLog.ScrollBars="Vertical"; $Global:TxtLog.Font = New-Object System.Drawing.Font("Consolas", 9); $Form.Controls.Add($Global:TxtLog)

$Global:DeploySeconds = 0
$Global:TimerDeploy = New-Object System.Windows.Forms.Timer; $Global:TimerDeploy.Interval = 1000
$Global:TimerDeploy.Add_Tick({ 
    $Global:DeploySeconds++
    $m = [math]::Floor($Global:DeploySeconds / 60); $s = $Global:DeploySeconds % 60
    $BtnAutoRun.Text = "ĐANG XẢ NÉN LIVE... ($m phút $s giây)" 
})

# =========================
#   LOGIC GIAO DIỆN
# =========================

function Load-Grid {
    $GridPart.Rows.Clear()
    $Vols = Get-Volume | Where-Object DriveType -eq 'Fixed'
    foreach ($V in $Vols) {
        $Size = [math]::Round($V.Size / 1GB, 1)
        if ($Size -lt 0.1) { continue } # Bỏ qua mấy phân vùng dưới 100MB vớ vẩn rác
        
        $Ltr = if ($V.DriveLetter) { "$($V.DriveLetter):" } else { "Ẩn" }
        $UUID = $V.UniqueId
        
        # Lấy thông tin Disk
        $DiskNum = "-"
        try { $DiskNum = (Get-Partition -Volume $V -ErrorAction SilentlyContinue).DiskNumber } catch {}

        $Status = ""
        if ($UUID -eq $Global:SelWinUUID) { $Status = "WIN TARGET" }
        if ($UUID -eq $Global:SelBootUUID) { $Status = "BOOT SYSTEM" }
        if ($UUID -eq $Global:AutoTargetUUID) { $Status = "AUTO TARGET" }
        
        $Row = $GridPart.Rows.Add($DiskNum, $Ltr, $V.FileSystemLabel, $Size, $V.FileSystem, $Status, $UUID)
        
        if ($Status -match "TARGET") { $GridPart.Rows[$Row].DefaultCellStyle.BackColor = "Maroon"; $GridPart.Rows[$Row].DefaultCellStyle.ForeColor = "White" }
        if ($Status -eq "BOOT SYSTEM") { $GridPart.Rows[$Row].DefaultCellStyle.BackColor = "DarkGreen"; $GridPart.Rows[$Row].DefaultCellStyle.ForeColor = "White" }
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
#   MODE 1: SMART DEPLOY ENGINE (UUID)
# ==========================================
$BtnAutoRun.Add_Click({
    if (!$Global:AutoTargetUUID) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn Ổ Cài Win!", "Lỗi"); return }
    if (!$Global:IsoMounted -and !$Global:SelSource) { [System.Windows.Forms.MessageBox]::Show("Chưa Mount ISO!", "Lỗi"); return }
    
    $SourcePath = $Global:SelSource
    $ImageIdx = $CbIndex.SelectedIndex + 1
    $EdName = $CbIndex.SelectedItem.ToString()

    # CƠ CHẾ CẤM TỰ SÁT (Bằng UUID thay vì ổ C)
    $OsUUID = (Get-Volume -DriveLetter $env:SystemDrive.Replace(":","")).UniqueId
    if (-not $Global:IsWinPE -and $Global:AutoTargetUUID -eq $OsUUID) {
        [System.Windows.Forms.MessageBox]::Show("LỖI CHÍ MẠNG: Đang chạy tool trên Windows sống (Ổ gốc). Đéo được Format ổ đang chạy tool!`n`nVui lòng dùng USB Boot WinPE, hoặc chọn cài sang phân vùng khác.", "BẢO VỆ TỰ SÁT", 0, 16)
        return
    }

    if ([System.Windows.Forms.MessageBox]::Show("Toàn bộ dữ liệu trên phân vùng đích sẽ bị FORMAT! Cảnh báo lần cuối, tiếp tục?", "XÁC NHẬN FORMAT", 4, 48) -ne "Yes") { return }

    $BtnAutoRun.Enabled = $false; $BtnManRun.Enabled = $false
    $Global:DeploySeconds = 0; $Global:TimerDeploy.Start()
    
    $Global:SyncUI = [hashtable]::Synchronized(@{ LogBox = $Global:TxtLog; Btn = $BtnAutoRun; Timer = $Global:TimerDeploy; TargetUUID = $Global:AutoTargetUUID })

    $Runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $Runspace.Open()
    $Runspace.SessionStateProxy.SetVariable("Source", $SourcePath)
    $Runspace.SessionStateProxy.SetVariable("Idx", $ImageIdx)
    $Runspace.SessionStateProxy.SetVariable("ChkGameMode", $ChkGameMode.Checked)
    $Runspace.SessionStateProxy.SetVariable("Sync", $Global:SyncUI)
    
    # Push Functions to Runspace
    $Runspace.SessionStateProxy.SetVariable("FuncMountTemp", $function:Mount-UUID-To-TempLetter)
    $Runspace.SessionStateProxy.SetVariable("FuncBootHunt", $function:Săn-Boot-Partition-Bằng-UUID)

    $Pipeline = $Runspace.CreatePipeline()
    $Pipeline.Commands.AddScript({
        function Write-GuiLog ($Msg) {
            $Time = (Get-Date).ToString("HH:mm:ss")
            $Sync.LogBox.Invoke([action]{ 
                $Sync.LogBox.AppendText("[$Time] [AUTO] $Msg`r`n")
                $Sync.LogBox.SelectionStart = $Sync.LogBox.Text.Length; $Sync.LogBox.ScrollToCaret()
            })
        }

        # 1. MOUNT Ổ ĐĨA & FORMAT
        Write-GuiLog "=> [1/5] Khởi tạo Mount-Point cho UUID Target..."
        $TargetDrive = &$FuncMountTemp $Sync.TargetUUID
        if (!$TargetDrive) { Write-GuiLog "LỖI: Không thể ánh xạ ký tự đĩa!"; return }
        
        Write-GuiLog "-> Đang Format phân vùng (NTFS)..."
        Format-Volume -UniqueId $Sync.TargetUUID -FileSystem NTFS -NewFileSystemLabel "Windows" -Confirm:$false | Out-Null
        Write-GuiLog "-> Đã dọn dẹp sạch sẽ ổ cài Win ($TargetDrive)."

        # 2. XẢ NÉN
        Write-GuiLog "=> [2/5] Bắn Image (Index $Idx) thẳng vào UUID..."
        $WimSuccess = $false
        if (Get-Command Expand-WindowsImage -ErrorAction SilentlyContinue) {
            Write-GuiLog "-> Đang dùng API Expand-WindowsImage siêu tốc..."
            try { 
                Expand-WindowsImage -ImagePath $Source -Index $Idx -ApplyPath "$TargetDrive\" -ErrorAction Stop | Out-Null
                $WimSuccess = $true 
            } catch { Write-GuiLog "-> API Lỗi: $_. Chuyển sang DISM Native..." }
        }
        
        if (-not $WimSuccess) {
            Write-GuiLog "-> Đang xả nén bằng DISM..."
            $DismOut = cmd /c "dism /Apply-Image /ImageFile:`"$Source`" /Index:$Idx /ApplyDir:$TargetDrive\ 2>&1"
        }

        # 3. TỐI ƯU HÓA
        Write-GuiLog "=> [3/5] Tối ưu hóa (Registry Tweak)..."
        if ($ChkGameMode) {
            cmd /c "reg load HKLM\OFFLINE $TargetDrive\Windows\System32\config\SOFTWARE >nul 2>&1"
            cmd /c "reg add `"HKLM\OFFLINE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR`" /v value /t REG_DWORD /d 0 /f >nul 2>&1"
            cmd /c "reg unload HKLM\OFFLINE >nul 2>&1"
        }

        # 4. TẠO UNATTEND OOBE
        Write-GuiLog "=> [4/5] Ghi Unattend bỏ qua thiết lập User..."
        $Panther = "$TargetDrive\Windows\Panther"; if (!(Test-Path $Panther)) { New-Item -ItemType Directory -Path $Panther -Force | Out-Null }
        $XmlOobe = "<?xml version='1.0'?><unattend xmlns='urn:schemas-microsoft-com:unattend'><settings pass='oobeSystem'><component name='Microsoft-Windows-Shell-Setup' processorArchitecture='amd64' publicKeyToken='31bf3856ad364e35' language='neutral' versionScope='nonSxS'><OOBE><HideEULAPage>true</HideEULAPage><HideLocalAccountScreen>true</HideLocalAccountScreen><HideOnlineAccountScreens>true</HideOnlineAccountScreens><ProtectYourPC>3</ProtectYourPC></OOBE><UserAccounts><LocalAccounts><LocalAccount wcm:action='add'><Password><Value></Value><PlainText>true</PlainText></Password><DisplayName>Admin</DisplayName><Group>Administrators</Group><Name>Admin</Name></LocalAccount></LocalAccounts></UserAccounts></component></settings></unattend>"
        [IO.File]::WriteAllText("$Panther\unattend.xml", $XmlOobe, [System.Text.Encoding]::UTF8)

        # 5. BOOT HUNTER V2 (Săn Boot bằng UUID)
        Write-GuiLog "=> [5/5] Kích hoạt Boot Hunter V2 (Quét Disk Number)..."
        $BootUUID = &$FuncBootHunt $Sync.TargetUUID
        
        if ($BootUUID) {
            $BootDrive = &$FuncMountTemp $BootUUID
            Write-GuiLog "-> Ánh xạ Boot Partition ra ổ ảo: $BootDrive"
            Write-GuiLog "-> Đang ghi File Boot BCD (Chuẩn xịn)..."
            $BcdOut = cmd /c "bcdboot $TargetDrive\Windows /s $BootDrive /f ALL 2>&1"
            Write-GuiLog "-> $BcdOut"
        } else {
            Write-GuiLog "-> CẢNH BÁO: Phân vùng Boot không tồn tại trên ổ cứng này! Sẽ nạp Boot tạm vào chung với ổ Cài Win."
            $BcdOut = cmd /c "bcdboot $TargetDrive\Windows /f ALL 2>&1"
            Write-GuiLog "-> $BcdOut"
        }

        Write-GuiLog "======================================================"
        Write-GuiLog "🎉 HOÀN TẤT TRỌN VẸN! Khởi động lại máy để tận hưởng."
        
        $Sync.Timer.Invoke([action]{ $Sync.Timer.Stop() })
        $Sync.Btn.Invoke([action]{ 
            $Sync.Btn.Enabled = $true
            $Sync.Btn.Text = "🚀 CÀI ĐẶT TRỰC TIẾP (LIVE GUI)"
            [System.Windows.Forms.MessageBox]::Show("Quá trình Direct Deploy bằng UUID đã hoàn tất thành công 100%!", "PHÁT TẤN PC VIP")
        })
    }) | Out-Null
    $Pipeline.InvokeAsync()
})

# --- MANUAL MODE (Cũng nâng cấp UUID) ---
$BtnManRun.Add_Click({
    if (!$Global:SelSource -or !$Global:SelWinUUID -or !$Global:SelBootUUID) { [System.Windows.Forms.MessageBox]::Show("Phải chọn đủ File ISO, Ổ Cài Win và Ổ Boot!", "Error"); return }
    if ([System.Windows.Forms.MessageBox]::Show("Chắc chắn ghi đè Manual?", "Confirm", "YesNo") -eq "Yes") {
        $Form.Cursor = "WaitCursor"
        $Idx = $CbIndex.SelectedIndex + 1
        
        Log-Write "Mounting UUID Target & Boot..."
        $T_Drv = Mount-UUID-To-TempLetter $Global:SelWinUUID
        $B_Drv = Mount-UUID-To-TempLetter $Global:SelBootUUID
        
        if ($ChkFmt.Checked) { 
            Log-Write "Formatting Target..."
            Format-Volume -UniqueId $Global:SelWinUUID -FileSystem NTFS -Confirm:$false | Out-Null
        }
        
        Log-Write "Applying Image..."
        $WimSuccess = $false
        if (Get-Command Expand-WindowsImage -ErrorAction SilentlyContinue) {
            try { Expand-WindowsImage -ImagePath $Global:SelSource -Index $Idx -ApplyPath "$T_Drv\" -ErrorAction Stop | Out-Null; $WimSuccess = $true } catch {}
        }
        if (-not $WimSuccess) { Exec-Cmd "dism /Apply-Image /ImageFile:`"$($Global:SelSource)`" /Index:$Idx /ApplyDir:$T_Drv\" }
        
        Log-Write "Booting to $B_Drv..."
        Exec-Cmd "bcdboot $T_Drv\Windows /s $B_Drv /f ALL"
        
        $Form.Cursor = "Default"
        [System.Windows.Forms.MessageBox]::Show("Manual Deploy Xong!", "Success")
    }
})

$BtnWinToHDD.Add_Click({ try { (New-Object System.Net.WebClient).DownloadFile("https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/WinToHDD.exe", "$env:TEMP\WinToHDD.exe"); Start-Process "$env:TEMP\WinToHDD.exe" } catch { Log-Write "Download Fail" } })
$BtnSetup.Add_Click({ if($Global:IsoMounted){Start-Process "$($Global:IsoMounted)\setup.exe"} })

Load-Grid
$Form.ShowDialog() | Out-Null
