# --- 1. TU DONG YEU CAU QUYEN ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- NAP THU VIEN ---
try { Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing } catch { Exit }
$ErrorActionPreference = "SilentlyContinue"

# --- CAU HINH ---
$WinToHDD_Url = "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/WinToHDD.exe"
$Global:CurrentISO = $null # Biến theo dõi ISO đang mount

# --- HÀM HỖ TRỢ: DON DEP O AO ---
function Dismount-All {
    Write-Host "Dang kiem tra va go bo o dia ao cu..." -F Cyan
    # Gỡ ISO đang lưu trong biến
    if ($Global:CurrentISO) { Dismount-DiskImage -ImagePath $Global:CurrentISO -ErrorAction SilentlyContinue }
    
    # Quét tất cả ISO trong danh sách ComboBox để gỡ cho chắc
    if ($CmbISO.Items.Count -gt 0) {
        foreach ($IsoPath in $CmbISO.Items) { Dismount-DiskImage -ImagePath $IsoPath -ErrorAction SilentlyContinue }
    }
}

# --- HÀM TẠO MENU BOOT TAM (BCD) ---
function Create-Boot-Entry ($WimPath) {
    try {
        $Guid = [Guid]::NewGuid().ToString()
        $Name = "CAI WIN TAM THOI (Phat Tan PC)"
        
        # 1. Tao Ramdisk Options
        cmd /c "bcdedit /create {ramdiskoptions} /d `"Ramdisk Options`""
        cmd /c "bcdedit /set {ramdiskoptions} ramdisksdidevice partition=C:"
        cmd /c "bcdedit /set {ramdiskoptions} ramdisksdipath \boot.sdi"
        
        # 2. Tao Entry Boot
        $Output = cmd /c "bcdedit /create /d `"$Name`" /application osloader"
        if ($Output -match '{([a-f0-9\-]+)}') { $ID = $matches[0] } else { return $false }
        
        # 3. Cau hinh Entry
        cmd /c "bcdedit /set $ID device ramdisk=[C:]$WimPath,{ramdiskoptions}"
        cmd /c "bcdedit /set $ID osdevice ramdisk=[C:]$WimPath,{ramdiskoptions}"
        cmd /c "bcdedit /set $ID systemroot \windows"
        cmd /c "bcdedit /set $ID detecthal yes"
        cmd /c "bcdedit /set $ID winpe yes"
        cmd /c "bcdedit /displayorder $ID /addlast"
        
        # 4. Set Boot 1 Lan (One-Time Boot)
        # Nếu cài lỗi, restart sẽ về Win cũ
        cmd /c "bcdedit /bootsequence $ID"
        
        return $true
    } catch { return $false }
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CAI DAT WINDOWS MASTER - PHAT TAN PC (V7.0)"
$Form.Size = New-Object System.Drawing.Size(750, 600)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30); $Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

# Header
$LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text = "CHON ISO & PHUONG PHAP CAI DAT"; $LblTitle.Font = "Segoe UI, 14, Bold"; $LblTitle.ForeColor = "Cyan"; $LblTitle.AutoSize=$true; $LblTitle.Location = "20,15"; $Form.Controls.Add($LblTitle)

# ISO Selection
$CmbISO = New-Object System.Windows.Forms.ComboBox; $CmbISO.Size = "580, 30"; $CmbISO.Location = "20,55"; $CmbISO.Font = "Segoe UI, 10"; $CmbISO.DropDownStyle = "DropDownList"; $Form.Controls.Add($CmbISO)
$BtnBrowse = New-Object System.Windows.Forms.Button; $BtnBrowse.Text = "TIM ISO"; $BtnBrowse.Location = "610,53"; $BtnBrowse.Size = "100,30"; $BtnBrowse.BackColor = "Gray"; $BtnBrowse.Add_Click({ $OFD = New-Object System.Windows.Forms.OpenFileDialog; $OFD.Filter = "ISO (*.iso)|*.iso"; if ($OFD.ShowDialog() -eq "OK") { $CmbISO.Items.Insert(0, $OFD.FileName); $CmbISO.SelectedIndex = 0 } }); $Form.Controls.Add($BtnBrowse)
$LblScan = New-Object System.Windows.Forms.Label; $LblScan.Text = "Dang quet..."; $LblScan.Location = "20,90"; $LblScan.AutoSize=$true; $LblScan.ForeColor = "Yellow"; $Form.Controls.Add($LblScan)

# --- ACTION AREA ---
$GBAct = New-Object System.Windows.Forms.GroupBox; $GBAct.Text = "MENU CAI DAT"; $GBAct.Location = "20,130"; $GBAct.Size = "690,300"; $GBAct.ForeColor = "Lime"; $Form.Controls.Add($GBAct)

# Nut 1: Cai De (Menu Con)
$BtnMode1 = New-Object System.Windows.Forms.Button; $BtnMode1.Text = "CHE DO 1: CAI DE / NANG CAP (RECOMMENDED)"; $BtnMode1.Location = "20,40"; $BtnMode1.Size = "650,50"; $BtnMode1.BackColor = "LimeGreen"; $BtnMode1.ForeColor = "Black"; $BtnMode1.Font = "Segoe UI, 12, Bold"
$BtnMode1.Add_Click({ Show-SubMenu-Upgrade }); $GBAct.Controls.Add($BtnMode1)

$LblNote1 = New-Object System.Windows.Forms.Label; $LblNote1.Text = "-> Giu nguyen du lieu. Co the chon cai truc tiep hoac tao Boot tam."; $LblNote1.Location = "25,95"; $LblNote1.AutoSize=$true; $LblNote1.ForeColor="LightGray"; $GBAct.Controls.Add($LblNote1)

# Nut 2: WinToHDD
$BtnMode2 = New-Object System.Windows.Forms.Button; $BtnMode2.Text = "CHE DO 2: CAI MOI (WinToHDD - Sạch se)"; $BtnMode2.Location = "20,140"; $BtnMode2.Size = "650,50"; $BtnMode2.BackColor = "Orange"; $BtnMode2.ForeColor = "Black"; $BtnMode2.Font = "Segoe UI, 12, Bold"
$BtnMode2.Add_Click({ Start-Install "WinToHDD" }); $GBAct.Controls.Add($BtnMode2)
$LblNote2 = New-Object System.Windows.Forms.Label; $LblNote2.Text = "-> Format o C, cai lai tu dau. Dung cho may loi nang."; $LblNote2.Location = "25,195"; $LblNote2.AutoSize=$true; $LblNote2.ForeColor="LightGray"; $GBAct.Controls.Add($LblNote2)

# --- HÀM HIỂN THỊ MENU CON (CHOICE DIALOG) ---
function Show-SubMenu-Upgrade {
    $ISO = $CmbISO.SelectedItem
    if (!$ISO) { [System.Windows.Forms.MessageBox]::Show("Chua chon ISO!", "Loi"); return }

    $SubForm = New-Object System.Windows.Forms.Form
    $SubForm.Text = "CHON CACH KHOI CHAY"
    $SubForm.Size = New-Object System.Drawing.Size(500, 250)
    $SubForm.StartPosition = "CenterParent"
    $SubForm.BackColor = "Black"
    $SubForm.ForeColor = "White"
    $SubForm.FormBorderStyle = "FixedToolWindow"

    $LblQ = New-Object System.Windows.Forms.Label; $LblQ.Text = "Ban muon cai dat theo cach nao?"; $LblQ.Location = "20,20"; $LblQ.AutoSize=$true; $LblQ.Font="Segoe UI, 11, Bold"; $SubForm.Controls.Add($LblQ)

    # Nut A: Cai Truc Tiep
    $BtnDirect = New-Object System.Windows.Forms.Button; $BtnDirect.Text = "CAI TRUC TIEP (Tren nen Win)"; $BtnDirect.Location = "20,60"; $BtnDirect.Size = "440,40"; $BtnDirect.BackColor = "Cyan"; $BtnDirect.ForeColor = "Black"
    $BtnDirect.Add_Click({ 
        $SubForm.Close(); Start-Install "Direct" 
    })
    $SubForm.Controls.Add($BtnDirect)

    # Nut B: Tao Boot Tam
    $BtnBoot = New-Object System.Windows.Forms.Button; $BtnBoot.Text = "TAO BOOT TAM (Restart vao moi truong cai dat)"; $BtnBoot.Location = "20,110"; $BtnBoot.Size = "440,40"; $BtnBoot.BackColor = "Magenta"; $BtnBoot.ForeColor = "White"
    $BtnBoot.Add_Click({ 
        $SubForm.Close(); Start-Install "BootTmp" 
    })
    $SubForm.Controls.Add($BtnBoot)
    
    $SubForm.ShowDialog() | Out-Null
}

# --- MAIN INSTALL LOGIC ---
function Start-Install ($Mode) {
    $ISO = $CmbISO.SelectedItem
    
    # 1. Dọn dẹp ổ ảo cũ trước khi làm gì đó
    Dismount-All
    
    # 2. Mount ISO Mới
    $Form.Text = "DANG MOUNT ISO..."
    $Global:CurrentISO = $ISO # Lưu lại để tí gỡ
    Mount-DiskImage -ImagePath $ISO -StorageType ISO -ErrorAction SilentlyContinue
    $Vol = Get-Volume | Where-Object { Test-Path "$($_.DriveLetter):\setup.exe" } | Select -First 1
    
    if (!$Vol) { [System.Windows.Forms.MessageBox]::Show("Loi Mount ISO!", "Loi"); return }
    $Drive = "$($Vol.DriveLetter):"

    # --- XU LY THEO MODE ---
    
    if ($Mode -eq "Direct") {
        # Chạy Setup.exe thẳng
        Start-Process "$Drive\setup.exe"
        $Form.Close()
    }
    elseif ($Mode -eq "BootTmp") {
        # Copy boot.wim ra ổ C và tạo Menu Boot
        $Form.Text = "DANG TAO BOOT TAM..."
        $BootWim = "$Drive\sources\boot.wim"
        $LocalWim = "\WinInstall_Boot.wim" # Lưu ở gốc ổ C
        
        if (Test-Path $BootWim) {
            Copy-Item $BootWim "C:$LocalWim" -Force
            # Copy file boot.sdi (cần thiết)
            if (!(Test-Path "C:\boot.sdi")) { Copy-Item "$Drive\boot\boot.sdi" "C:\boot.sdi" -Force }
            
            if (Create-Boot-Entry $LocalWim) {
                 $Res = [System.Windows.Forms.MessageBox]::Show("Da tao Boot Tam thanh cong!`nMay se khoi dong lai vao moi truong cai dat.`n`nNeu cai loi, lan sau khoi dong se tu ve Win cu.`n`nRestart ngay?", "Thanh Cong", "YesNo", "Information")
                 if ($Res -eq "Yes") { Restart-Computer -Force }
            } else {
                 [System.Windows.Forms.MessageBox]::Show("Loi tao Menu Boot (BCD).", "Loi")
            }
        } else {
            [System.Windows.Forms.MessageBox]::Show("Khong tim thay boot.wim trong ISO!", "Loi")
        }
    }
    elseif ($Mode -eq "WinToHDD") {
        $WTHPath = "$env:TEMP\WinToHDD.exe"
        if (!(Test-Path $WTHPath)) { (New-Object Net.WebClient).DownloadFile($WinToHDD_Url, $WTHPath) }
        Start-Process $WTHPath
    }
}

# --- AUTO SCAN ---
$Form.Add_Shown({
    $Form.Refresh(); $LblScan.Text = "Dang quet ISO..."
    $Paths = @("$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop", "D:", "E:")
    foreach ($P in $Paths) { if (Test-Path $P) { Get-ChildItem $P -Filter "*.iso" -Recurse -Depth 1 | Where {$_.Length -gt 500MB} | ForEach { $CmbISO.Items.Add($_.FullName) } } }
    if ($CmbISO.Items.Count -gt 0) { $CmbISO.SelectedIndex = 0; $LblScan.Text = "Tim thay ISO." } else { $LblScan.Text = "Khong thay ISO." }
})

$Form.ShowDialog() | Out-Null
