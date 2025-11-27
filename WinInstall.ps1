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

# --- HÀM HỖ TRỢ ---
function Dismount-All {
    if ($Global:CurrentISO) { Dismount-DiskImage -ImagePath $Global:CurrentISO -ErrorAction SilentlyContinue }
}

function Get-BiosMode {
    # Cách check BIOS Mode chuẩn nhất qua bcdedit
    $Info = bcdedit /enum | Out-String
    if ($Info -match "winload.efi") { return "UEFI" }
    return "Legacy"
}

# --- HÀM TẠO MENU BOOT (FIXED 0xc000000f) ---
function Create-Boot-Entry ($WimPath) {
    try {
        $Name = "CAI WIN TAM THOI (Phat Tan PC)"
        $Mode = Get-BiosMode
        $Drive = $env:SystemDrive # Lấy ổ cài Win hiện tại (thường là C:)
        
        # 1. Xóa Ramdisk Options cũ nếu có để tránh xung đột
        cmd /c "bcdedit /delete {ramdiskoptions} /f"
        
        # 2. Tạo Ramdisk Options mới chuẩn
        cmd /c "bcdedit /create {ramdiskoptions} /d `"Ramdisk Options`""
        cmd /c "bcdedit /set {ramdiskoptions} ramdisksdidevice partition=$Drive"
        cmd /c "bcdedit /set {ramdiskoptions} ramdisksdipath \boot.sdi"
        
        # 3. Tạo Entry Boot
        $Output = cmd /c "bcdedit /create /d `"$Name`" /application osloader"
        if ($Output -match '{([a-f0-9\-]+)}') { $ID = $matches[0] } else { return $false }
        
        # 4. Cấu hình Entry (Quan trọng: Dùng [$Drive] thay vì [C:])
        cmd /c "bcdedit /set $ID device ramdisk=[$Drive]$WimPath,{ramdiskoptions}"
        cmd /c "bcdedit /set $ID osdevice ramdisk=[$Drive]$WimPath,{ramdiskoptions}"
        cmd /c "bcdedit /set $ID systemroot \windows"
        cmd /c "bcdedit /set $ID detecthal yes"
        cmd /c "bcdedit /set $ID winpe yes"
        
        # 5. Chỉnh Bootloader theo BIOS Mode chuẩn xác
        if ($Mode -eq "UEFI") { 
            cmd /c "bcdedit /set $ID path \windows\system32\boot\winload.efi"
        } else { 
            cmd /c "bcdedit /set $ID path \windows\system32\boot\winload.exe" 
        }

        # 6. Đưa lên đầu và Set Boot 1 lần
        cmd /c "bcdedit /displayorder $ID /addlast"
        cmd /c "bcdedit /bootsequence $ID"
        
        return $true
    } catch { return $false }
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CAI DAT WINDOWS MASTER - PHAT TAN PC (V9.0)"
$Form.Size = New-Object System.Drawing.Size(800, 680)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30); $Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

# Tabs
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = "10,10"; $TabControl.Size = "765,620"
$Form.Controls.Add($TabControl)

function Make-Tab ($T) { $P = New-Object System.Windows.Forms.TabPage; $P.Text = $T; $P.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48); $P.ForeColor = "White"; $TabControl.Controls.Add($P); return $P }

# ==========================================
# TAB 1: CAI DAT (MAIN)
# ==========================================
$TabInstall = Make-Tab "Cai Dat Windows"

$LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text = "CHON ISO & CAU HINH"; $LblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold); $LblTitle.ForeColor = "Cyan"; $LblTitle.AutoSize=$true; $LblTitle.Location = "20,15"; $TabInstall.Controls.Add($LblTitle)

# ISO Select
$CmbISO = New-Object System.Windows.Forms.ComboBox; $CmbISO.Size = "580, 30"; $CmbISO.Location = "20,55"; $CmbISO.Font = New-Object System.Drawing.Font("Segoe UI", 10); $CmbISO.DropDownStyle = "DropDownList"; $TabInstall.Controls.Add($CmbISO)
$BtnBrowse = New-Object System.Windows.Forms.Button; $BtnBrowse.Text = "TIM ISO"; $BtnBrowse.Location = "610,53"; $BtnBrowse.Size = "100,30"; $BtnBrowse.BackColor = "Gray"; $BtnBrowse.ForeColor="White"; $BtnBrowse.Add_Click({ $OFD = New-Object System.Windows.Forms.OpenFileDialog; $OFD.Filter = "ISO (*.iso)|*.iso"; if ($OFD.ShowDialog() -eq "OK") { $CmbISO.Items.Insert(0, $OFD.FileName); $CmbISO.SelectedIndex = 0; Check-Version } }); $TabInstall.Controls.Add($BtnBrowse)

# Driver Options
$GBOpt = New-Object System.Windows.Forms.GroupBox; $GBOpt.Text = "TUY CHON DRIVER"; $GBOpt.Location = "20,100"; $GBOpt.Size = "690,200"; $GBOpt.ForeColor = "Yellow"; $TabInstall.Controls.Add($GBOpt)
$LblVerInfo = New-Object System.Windows.Forms.Label; $LblVerInfo.Text = "Trang thai: Chua chon ISO..."; $LblVerInfo.Location = "20,30"; $LblVerInfo.AutoSize=$true; $LblVerInfo.ForeColor="LightGray"; $GBOpt.Controls.Add($LblVerInfo)
$CkBackup = New-Object System.Windows.Forms.CheckBox; $CkBackup.Text = "Sao luu Driver hien tai (Pnputil)"; $CkBackup.Location = "20,60"; $CkBackup.AutoSize=$true; $CkBackup.Checked=$true; $GBOpt.Controls.Add($CkBackup)
$Ck3DP = New-Object System.Windows.Forms.CheckBox; $Ck3DP.Text = "Tai 3DP Net (Cuu mang)"; $Ck3DP.Location = "20,90"; $Ck3DP.AutoSize=$true; $Ck3DP.Checked=$true; $GBOpt.Controls.Add($Ck3DP)
$CkInject = New-Object System.Windows.Forms.CheckBox; $CkInject.Text = "Tao Script Auto-Install Driver (1-Click)"; $CkInject.Location = "20,120"; $CkInject.AutoSize=$true; $CkInject.Checked=$true; $GBOpt.Controls.Add($CkInject)
$LblPath = New-Object System.Windows.Forms.Label; $LblPath.Text = "Noi luu:"; $LblPath.Location = "40,155"; $LblPath.AutoSize=$true; $GBOpt.Controls.Add($LblPath)
$TxtPath = New-Object System.Windows.Forms.TextBox; $TxtPath.Text = $Global:DriverPath; $TxtPath.Location = "100,152"; $TxtPath.Size = "480,25"; $GBOpt.Controls.Add($TxtPath)
$BtnPath = New-Object System.Windows.Forms.Button; $BtnPath.Text = "..."; $BtnPath.Location = "590,151"; $BtnPath.Size = "40,27"; $BtnPath.BackColor="Gray"; $BtnPath.ForeColor="White"; $BtnPath.Add_Click({ $FBD = New-Object System.Windows.Forms.FolderBrowserDialog; if ($FBD.ShowDialog() -eq "OK") { $TxtPath.Text = $FBD.SelectedPath; $Global:DriverPath = $FBD.SelectedPath } }); $GBOpt.Controls.Add($BtnPath)

# Action Buttons
$BtnMode1 = New-Object System.Windows.Forms.Button; $BtnMode1.Text = "CHE DO 1: CAI DE / NANG CAP (Setup.exe)"; $BtnMode1.Location = "20,320"; $BtnMode1.Size = "690,50"; $BtnMode1.BackColor = "LimeGreen"; $BtnMode1.ForeColor = "Black"; $BtnMode1.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$BtnMode1.Add_Click({ Show-SubMenu-Upgrade }); $TabInstall.Controls.Add($BtnMode1)

$BtnMode2 = New-Object System.Windows.Forms.Button; $BtnMode2.Text = "CHE DO 2: CAI MOI (WinToHDD)"; $BtnMode2.Location = "20,390"; $BtnMode2.Size = "690,50"; $BtnMode2.BackColor = "Orange"; $BtnMode2.ForeColor = "Black"; $BtnMode2.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$BtnMode2.Add_Click({ Start-Install "WinToHDD" }); $TabInstall.Controls.Add($BtnMode2)

# ==========================================
# TAB 2: CAU HINH UNATTEND (AUTO XML)
# ==========================================
$TabConfig = Make-Tab "Cau Hinh Tu Dong (Unattend)"
$LblInfo = New-Object System.Windows.Forms.Label; $LblInfo.Text = "CAU HINH TAI KHOAN & O CUNG (XML)"; $LblInfo.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold); $LblInfo.ForeColor = "Cyan"; $LblInfo.AutoSize=$true; $LblInfo.Location = "20,20"; $TabConfig.Controls.Add($LblInfo)

function Add-Input ($Txt, $Y, $Def="") {
    $L = New-Object System.Windows.Forms.Label; $L.Text = $Txt; $L.Location = "20,$Y"; $L.AutoSize=$true; $TabConfig.Controls.Add($L)
    $T = New-Object System.Windows.Forms.TextBox; $T.Text = $Def; $T.Location = "220,$Y"; $T.Size = "300,25"; $TabConfig.Controls.Add($T)
    return $T
}

$TxtUser = Add-Input "Ten User (Account):" 60 "Admin"
$TxtPass = Add-Input "Mat Khau (Bo trong neu ko):" 100 ""
$TxtPCName = Add-Input "Ten May Tinh:" 140 "PhatTan-PC"
$TxtKey = Add-Input "Product Key (Bo trong skip):" 180 ""

$GBPart = New-Object System.Windows.Forms.GroupBox; $GBPart.Text = "TUY CHON O CUNG (Cho XML)"; $GBPart.Location = "20,230"; $GBPart.Size = "700,120"; $GBPart.ForeColor = "Red"; $TabConfig.Controls.Add($GBPart)
$RadioWipe = New-Object System.Windows.Forms.RadioButton; $RadioWipe.Text = "XOA SACH O CUNG (Clean Install)"; $RadioWipe.Location = "20,30"; $RadioWipe.AutoSize=$true; $RadioWipe.Checked=$true; $GBPart.Controls.Add($RadioWipe)
$RadioDual = New-Object System.Windows.Forms.RadioButton; $RadioDual.Text = "DUAL BOOT (Cai vao vung trong)"; $RadioDual.Location = "20,60"; $RadioDual.AutoSize=$true; $GBPart.Controls.Add($RadioDual)

$BtnGenXML = New-Object System.Windows.Forms.Button; $BtnGenXML.Text = "TAO FILE CAU HINH (AUTOUNATTEND.XML)"; $BtnGenXML.Location = "20,380"; $BtnGenXML.Size = "700,50"; $BtnGenXML.BackColor = "Cyan"; $BtnGenXML.ForeColor = "Black"; $BtnGenXML.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$BtnGenXML.Add_Click({ Generate-XML }); $TabConfig.Controls.Add($BtnGenXML)

# --- HÀM GENERATE XML ---
function Generate-XML {
    $User = $TxtUser.Text; $Pass = $TxtPass.Text; $PC = $TxtPCName.Text; $Key = $TxtKey.Text
    $XMLPath = "$env:SystemDrive\autounattend.xml"
    
    try { 
        (New-Object Net.WebClient).DownloadFile($XML_Url, $XMLPath) 
        $Content = Get-Content $XMLPath -Raw
        
        $Content = $Content -replace "%USERNAME%", $User
        $Content = $Content -replace "%PASSWORD%", $Pass
        $Content = $Content -replace "%COMPUTERNAME%", $PC
        if ($Key) { $Content = $Content -replace "%PRODUCTKEY%", $Key } else { $Content = $Content -replace "<Key>.*?</Key>", "<Key></Key>" }
        
        if ($RadioWipe.Checked) {
            $Content = $Content -replace "%WIPEDISK%", "true"
            $PartLayout = "<CreatePartition wcm:action='add'><Order>1</Order><Type>Primary</Type><Extend>true</Extend></CreatePartition><ModifyPartition wcm:action='add'><Order>1</Order><PartitionID>1</PartitionID><Label>Windows</Label><Letter>C</Letter><Format>NTFS</Format></ModifyPartition>"
            $Content = $Content -replace "%CREATEPARTITIONS%", $PartLayout
            $Content = $Content -replace "%INSTALLTO%", "<DiskID>0</DiskID><PartitionID>1</PartitionID>"
        } else {
            $Content = $Content -replace "%WIPEDISK%", "false"
            $Content = $Content -replace "%CREATEPARTITIONS%", ""
            $Content = $Content -replace "%INSTALLTO%", "<DiskID>0</DiskID><PartitionID>3</PartitionID>"
        }

        $Content | Set-Content $XMLPath
        [System.Windows.Forms.MessageBox]::Show("DA TAO XML THANH CONG!`nLuu tai: $XMLPath`n`nBay gio ban co the chon 'Tao Boot Tam' o Tab Cai Dat.", "Phat Tan PC")
    } 
    catch { [System.Windows.Forms.MessageBox]::Show("Loi tai file XML mau!", "Error") }
}

# --- HÀM CHECK VERSION ---
function Check-Version {
    $ISO = $CmbISO.SelectedItem; if (!$ISO) { return }
    $Form.Cursor = "WaitCursor"; $LblVerInfo.Text = "Dang kiem tra phien ban..."
    try {
        $HostVer = [Environment]::OSVersion.Version.Major
        Dismount-All
        Mount-DiskImage -ImagePath $ISO -StorageType ISO -ErrorAction SilentlyContinue
        $Vol = Get-Volume | Where-Object { Test-Path "$($_.DriveLetter):\setup.exe" } | Select -First 1
        if ($Vol) {
            $Global:CurrentISO = $ISO
            $Drive = "$($Vol.DriveLetter):"
            $Wim = "$Drive\sources\install.wim"; if (!(Test-Path $Wim)) { $Wim = "$Drive\sources\install.esd" }
            $DismInfo = dism /Get-WimInfo /WimFile:$Wim /Index:1
            $ISOVerStr = ($DismInfo | Select-String "Version :").ToString().Split(":")[1].Trim(); $ISOVerMajor = [int]$ISOVerStr.Split(".")[0]
            
            $Msg = "Host: Win $HostVer | ISO: Win $ISOVerMajor"
            if ($ISOVerMajor -lt $HostVer) {
                $Msg += " [!] HA CAP -> KHOA BACKUP DRIVER"; $CkBackup.Checked=$false; $CkBackup.Enabled=$false; $LblVerInfo.ForeColor="Red"
            } else {
                $Msg += " [OK] Hop le."; $CkBackup.Enabled=$true; $CkBackup.Checked=$true; $LblVerInfo.ForeColor="Lime"
            }
            $LblVerInfo.Text = $Msg
        }
    } catch {}
    $Form.Cursor = "Default"
}
$CmbISO.Add_SelectedIndexChanged({ Check-Version })

# --- HÀM SUBMENU ---
function Show-SubMenu-Upgrade {
    $SubForm = New-Object System.Windows.Forms.Form; $SubForm.Text="CHON CACH CHAY"; $SubForm.Size="550, 300"; $SubForm.StartPosition="CenterParent"; $SubForm.BackColor="Black"; $SubForm.ForeColor="White"
    $LblQ = New-Object System.Windows.Forms.Label; $LblQ.Text = "Ban muon cai dat theo cach nao?"; $LblQ.Location = "20,20"; $LblQ.AutoSize=$true; $LblQ.Font=New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold); $SubForm.Controls.Add($LblQ)
    
    $BtnD = New-Object System.Windows.Forms.Button; $BtnD.Text = "1. CAI TRUC TIEP (Setup.exe)"; $BtnD.Location = "20,60"; $BtnD.Size = "490,40"; $BtnD.BackColor = "Cyan"; $BtnD.ForeColor = "Black"; $BtnD.Add_Click({ $SubForm.Close(); Start-Install "Direct" }); $SubForm.Controls.Add($BtnD)
    
    $BtnB = New-Object System.Windows.Forms.Button; $BtnB.Text = "2. TAO BOOT TAM (Dung XML)"; $BtnB.Location = "20,110"; $BtnB.Size = "490,40"; $BtnB.BackColor = "Magenta"; $BtnB.ForeColor = "White"
    $BtnB.Add_Click({ 
        if (!(Test-Path "$env:SystemDrive\autounattend.xml")) { 
            $Ask = [System.Windows.Forms.MessageBox]::Show("Chua co file XML! Ban muon tao file cau hinh tu dong khong?`nBam 'Yes' de sang Tab cau hinh.", "Canh Bao", "YesNo", "Warning")
            if ($Ask -eq "Yes") { $SubForm.Close(); $TabControl.SelectedTab = $TabConfig; return }
        }
        $SubForm.Close(); Start-Install "BootTmp" 
    }); $SubForm.Controls.Add($BtnB)
    $SubForm.ShowDialog()
}

# --- MAIN INSTALL ---
function Start-Install ($Mode) {
    $ISO = $CmbISO.SelectedItem; if (!$ISO) { return }
    $FinalPath = $TxtPath.Text
    
    # BACKUP DRIVER
    if ($CkBackup.Checked) {
        if (!(Test-Path $FinalPath)) { New-Item -ItemType Directory -Path $FinalPath -Force | Out-Null }
        $Form.Text = "DANG SAO LUU DRIVER (Vui long doi)..."
        Start-Process "pnputil.exe" -ArgumentList "/export-driver * `"$FinalPath`"" -Wait -NoNewWindow
        
        if ($CkInject.Checked) {
            $BatContent = "@echo off`nTitle AUTO DRIVER INSTALLER`ncolor 0a`necho DANG NAP LAI DRIVER...`npnputil /add-driver `"%~dp0*.inf`" /subdirs /install`necho DA XONG!`npause"
            Set-Content -Path "$FinalPath\1_CLICK_INSTALL_DRIVER.bat" -Value $BatContent
        }
        if ($Ck3DP.Checked) { try { (New-Object Net.WebClient).DownloadFile("https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/3DP.Net.exe", "$FinalPath\3DP_Net.exe") } catch {} }
    }

    # Mount & Install
    $Vol = Get-Volume | Where-Object { Test-Path "$($_.DriveLetter):\setup.exe" } | Select -First 1
    if (!$Vol) { Mount-DiskImage -ImagePath $ISO -StorageType ISO; $Vol = Get-Volume | Where-Object { Test-Path "$($_.DriveLetter):\setup.exe" } | Select -First 1 }
    $Drive = "$($Vol.DriveLetter):"

    if ($Mode -eq "Direct") { Start-Process "$Drive\setup.exe"; $Form.Close() }
    elseif ($Mode -eq "BootTmp") {
        $Form.Text = "DANG TAO BOOT TAM..."
        $SysDrive = $env:SystemDrive
        
        Copy-Item "$Drive\sources\boot.wim" "$SysDrive\WinInstall_Boot.wim" -Force
        Copy-Item "$Drive\boot\boot.sdi" "$SysDrive\boot.sdi" -Force
        if (Create-Boot-Entry "\WinInstall_Boot.wim") {
            if ([System.Windows.Forms.MessageBox]::Show("Da tao Boot Tam! Restart ngay?", "Xong", "YesNo") -eq "Yes") { Restart-Computer -Force }
        }
    }
    elseif ($Mode -eq "WinToHDD") {
        $P = "$env:TEMP\WinToHDD.exe"; if (!(Test-Path $P)) { (New-Object Net.WebClient).DownloadFile($WinToHDD_Url, $P) }
        Start-Process $P; [System.Windows.Forms.MessageBox]::Show("Da xong! Check driver tai: $FinalPath", "Info")
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
