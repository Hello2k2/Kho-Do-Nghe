# --- 1. TU DONG YEU CAU QUYEN ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- NAP THU VIEN ---
try { Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing } catch { Exit }
$ErrorActionPreference = "SilentlyContinue"

# --- CAU HINH ---
$WinToHDD_Url = "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/WinToHDD.exe"
$DriverBackupPath = "D:\Drivers_Backup_Auto" # Lưu ổ D để cài lại Win không mất

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CAI DAT WINDOWS & DRIVER MASTER (V5.0)"
$Form.Size = New-Object System.Drawing.Size(750, 600)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30); $Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

# Header
$LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text = "CHON ISO & CAU HINH DRIVER"; $LblTitle.Font = "Segoe UI, 14, Bold"; $LblTitle.ForeColor = "Cyan"; $LblTitle.AutoSize=$true; $LblTitle.Location = "20,15"; $Form.Controls.Add($LblTitle)

# ISO Selection
$CmbISO = New-Object System.Windows.Forms.ComboBox; $CmbISO.Size = "580, 30"; $CmbISO.Location = "20,55"; $CmbISO.Font = "Segoe UI, 10"; $CmbISO.DropDownStyle = "DropDownList"; $Form.Controls.Add($CmbISO)
$BtnBrowse = New-Object System.Windows.Forms.Button; $BtnBrowse.Text = "TIM ISO"; $BtnBrowse.Location = "610,53"; $BtnBrowse.Size = "100,30"; $BtnBrowse.BackColor = "Gray"; $BtnBrowse.Add_Click({ 
    $OFD = New-Object System.Windows.Forms.OpenFileDialog; $OFD.Filter = "ISO (*.iso)|*.iso"; 
    if ($OFD.ShowDialog() -eq "OK") { $CmbISO.Items.Insert(0, $OFD.FileName); $CmbISO.SelectedIndex = 0; Check-Version } 
}); $Form.Controls.Add($BtnBrowse)

# --- GROUP OPTION (DRIVER INTELLIGENCE) ---
$GBOpt = New-Object System.Windows.Forms.GroupBox; $GBOpt.Text = "TUY CHON DRIVER (SMART CHECK)"; $GBOpt.Location = "20,100"; $GBOpt.Size = "690,180"; $GBOpt.ForeColor = "Yellow"; $Form.Controls.Add($GBOpt)

# Info Version
$LblVerInfo = New-Object System.Windows.Forms.Label; $LblVerInfo.Text = "Trang thai: Chua chon ISO..."; $LblVerInfo.Location = "20,30"; $LblVerInfo.AutoSize=$true; $LblVerInfo.ForeColor="LightGray"; $GBOpt.Controls.Add($LblVerInfo)

# Checkbox Backup
$CkBackup = New-Object System.Windows.Forms.CheckBox; $CkBackup.Text = "Sao luu Driver hien tai (Khuyen dung khi cung/nang cap Win)"; $CkBackup.Location = "20,60"; $CkBackup.AutoSize=$true; $CkBackup.Font="Segoe UI, 10, Bold"; $CkBackup.ForeColor="White"; $CkBackup.Checked=$true; $GBOpt.Controls.Add($CkBackup)

# Checkbox 3DP (Alternative)
$Ck3DP = New-Object System.Windows.Forms.CheckBox; $Ck3DP.Text = "Tai san 3DP Net (Cuu mang) phong truong hop thieu Driver"; $Ck3DP.Location = "20,90"; $Ck3DP.AutoSize=$true; $Ck3DP.Font="Segoe UI, 10"; $Ck3DP.ForeColor="White"; $Ck3DP.Checked=$true; $GBOpt.Controls.Add($Ck3DP)

# Checkbox Inject
$CkInject = New-Object System.Windows.Forms.CheckBox; $CkInject.Text = "Tao Script tu dong cai Driver (1-Click) cho Win moi"; $CkInject.Location = "20,120"; $CkInject.AutoSize=$true; $CkInject.Font="Segoe UI, 10"; $CkInject.ForeColor="Lime"; $CkInject.Checked=$true; $GBOpt.Controls.Add($CkInject)

# --- HÀM CHECK VERSION ---
function Check-Version {
    $ISO = $CmbISO.SelectedItem
    if (!$ISO) { return }
    
    $Form.Cursor = "WaitCursor"
    $LblVerInfo.Text = "Dang kiem tra phien ban ISO..."
    $Form.Refresh()

    try {
        # 1. Lấy Version Máy Thật
        $HostVer = [Environment]::OSVersion.Version.Major # 10 = Win10/11, 6 = Win7/8
        $HostBuild = [Environment]::OSVersion.Version.Build
        
        # 2. Lấy Version ISO (Mount ngầm)
        Mount-DiskImage -ImagePath $ISO -StorageType ISO -ErrorAction SilentlyContinue
        $Vol = Get-Volume | Where-Object { Test-Path "$($_.DriveLetter):\setup.exe" } | Select -First 1
        if (!$Vol) { $LblVerInfo.Text = "Loi: Khong doc duoc ISO!"; $Form.Cursor = "Default"; return }
        
        $Drive = "$($Vol.DriveLetter):"
        $Wim = "$Drive\sources\install.wim"; if (!(Test-Path $Wim)) { $Wim = "$Drive\sources\install.esd" }
        
        # Dùng DISM đọc thông tin
        $DismInfo = dism /Get-WimInfo /WimFile:$Wim /Index:1
        $ISOVerStr = ($DismInfo | Select-String "Version :").ToString().Split(":")[1].Trim()
        $ISOVerMajor = [int]$ISOVerStr.Split(".")[0] # 10, 6...

        # 3. So Sánh Logic
        $Msg = "May hien tai: Win $HostVer (Build $HostBuild) | ISO: Win $ISOVerMajor ($ISOVerStr)"
        
        if ($ISOVerMajor -lt $HostVer) {
            $Msg += "`n[!] CANH BAO: Ban dang HA CAP Windows. Driver cu se gay man hinh xanh!"
            $CkBackup.Checked = $false
            $CkBackup.Enabled = $false # Khóa luôn
            $CkBackup.Text = "Sao luu Driver (DA KHOA: Do ha cap Windows)"
            $LblVerInfo.ForeColor = "Red"
        }
        else {
            $Msg += "`n[OK] Phien ban hop le. Cho phep Backup Driver."
            $CkBackup.Enabled = $true
            $CkBackup.Checked = $true
            $CkBackup.Text = "Sao luu Driver hien tai (Khuyen dung)"
            $LblVerInfo.ForeColor = "Lime"
        }
        $LblVerInfo.Text = $Msg
        
    } catch { $LblVerInfo.Text = "Khong xac dinh duoc phien ban ISO." }
    $Form.Cursor = "Default"
}
$CmbISO.Add_SelectedIndexChanged({ Check-Version })

# --- ACTION BUTTONS ---
$GBAct = New-Object System.Windows.Forms.GroupBox; $GBAct.Text = "CHON CHE DO CAI DAT"; $GBAct.Location = "20,290"; $GBAct.Size = "690,200"; $GBAct.ForeColor = "Cyan"; $Form.Controls.Add($GBAct)

# Mode 1: Upgrade
$BtnMode1 = New-Object System.Windows.Forms.Button; $BtnMode1.Text = "CHE DO 1: CAI DE (Giu App/Data)"; $BtnMode1.Location = "20,30"; $BtnMode1.Size = "650,45"; $BtnMode1.BackColor = "LimeGreen"; $BtnMode1.ForeColor = "Black"; $BtnMode1.Font = "Segoe UI, 11, Bold"
$BtnMode1.Add_Click({ Start-Install "Upgrade" }); $GBAct.Controls.Add($BtnMode1)

# Mode 2: Clean
$BtnMode2 = New-Object System.Windows.Forms.Button; $BtnMode2.Text = "CHE DO 2: CAI MOI (WinToHDD - Sạch se)"; $BtnMode2.Location = "20,85"; $BtnMode2.Size = "650,45"; $BtnMode2.BackColor = "Orange"; $BtnMode2.ForeColor = "Black"; $BtnMode2.Font = "Segoe UI, 11, Bold"
$BtnMode2.Add_Click({ Start-Install "Clean" }); $GBAct.Controls.Add($BtnMode2)

# Logic Cài Đặt Chung
function Start-Install ($Mode) {
    $ISO = $CmbISO.SelectedItem
    if (!$ISO) { [System.Windows.Forms.MessageBox]::Show("Chua chon ISO!", "Loi"); return }
    
    # 1. BACKUP DRIVER (Nếu được chọn)
    if ($CkBackup.Checked) {
        $Form.Text = "DANG SAO LUU DRIVER..."
        if (!(Test-Path $DriverBackupPath)) { New-Item -ItemType Directory -Path $DriverBackupPath -Force | Out-Null }
        
        # Export Driver
        dism /online /export-driver /destination:"$DriverBackupPath"
        
        # 2. TAO SCRIPT AUTO INSTALL (Cực Xịn)
        if ($CkInject.Checked) {
            $BatContent = @"
@echo off
Title TUC DONG CAI DAT DRIVER - PHAT TAN PC
color 0a
echo ====================================================
echo      DANG TU DONG NAP LAI TOAN BO DRIVER...
echo      Vui long doi trong giay lat...
echo ====================================================
pnputil /add-driver "%~dp0*.inf" /subdirs /install
echo.
echo DA XONG! BAM PHIM BAT KY DE THOAT.
pause
"@
            $BatFile = "$DriverBackupPath\1_CLICK_INSTALL_DRIVER.bat"
            Set-Content -Path $BatFile -Value $BatContent
        }
    }
    
    # 3. TAI 3DP NET (Nếu chọn)
    if ($Ck3DP.Checked) {
        $Form.Text = "DANG TAI 3DP NET..."
        (New-Object Net.WebClient).DownloadFile("https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/3DP.Net.exe", "$DriverBackupPath\3DP_Net.exe")
    }
    
    # 4. THUC THI CAI WIN
    if ($Mode -eq "Upgrade") {
        # Mount và chạy Setup (Có tham số Driver nếu Win hỗ trợ)
        Mount-DiskImage -ImagePath $ISO -StorageType ISO
        $Vol = Get-Volume | Where-Object { Test-Path "$($_.DriveLetter):\setup.exe" } | Select -First 1
        $Setup = "$($Vol.DriveLetter):\setup.exe"
        
        if ($CkBackup.Checked) {
            # Setup.exe hỗ trợ tham số /InstallDrivers (Chỉ Win 10/11)
            Start-Process $Setup -ArgumentList "/Auto Upgrade /InstallDrivers `"$DriverBackupPath`""
        } else {
            Start-Process $Setup
        }
        $Form.Close()
    }
    else {
        # WinToHDD Mode
        $WTHPath = "$env:TEMP\WinToHDD.exe"
        if (!(Test-Path $WTHPath)) { (New-Object Net.WebClient).DownloadFile($WinToHDD_Url, $WTHPath) }
        Start-Process $WTHPath
        [System.Windows.Forms.MessageBox]::Show("Da chuan bi Driver tai: $DriverBackupPath`n`nSau khi cai Win xong, hay vao thu muc do va chay file '1_CLICK_INSTALL_DRIVER.bat' de nap lai Driver nhe!", "PHAT TAN PC")
    }
}

# --- AUTO SCAN ---
$Form.Add_Shown({
    $Form.Refresh(); $LblScan.Text = "Dang quet ISO..."
    $Paths = @("$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop", "D:", "E:")
    foreach ($P in $Paths) { if (Test-Path $P) { Get-ChildItem $P -Filter "*.iso" -Recurse -Depth 1 | Where {$_.Length -gt 500MB} | ForEach { $CmbISO.Items.Add($_.FullName) } } }
    if ($CmbISO.Items.Count -gt 0) { $CmbISO.SelectedIndex = 0; Check-Version; $LblScan.Text = "Tim thay ISO." } else { $LblScan.Text = "Khong thay ISO." }
})

$Form.ShowDialog() | Out-Null
