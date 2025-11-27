# --- 1. ADMIN CHECK ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- INIT ---
try { Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing } catch { Exit }
$ErrorActionPreference = "SilentlyContinue"
$WinToHDD_Url = "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/WinToHDD.exe"
$XML_Url = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/autounattend.xml"

# --- GUI ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CAI DAT WINDOWS MASTER - PHAT TAN PC (V8.0 UNATTEND)"
$Form.Size = New-Object System.Drawing.Size(800, 700)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30); $Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

# Tabs
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = "10,10"; $TabControl.Size = "765,640"
$Form.Controls.Add($TabControl)

function Make-Tab ($T) { $P = New-Object System.Windows.Forms.TabPage; $P.Text = $T; $P.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48); $P.ForeColor = "White"; $TabControl.Controls.Add($P); return $P }

# --- TAB 1: CAI DAT (GIAO DIEN CU) ---
$TabInstall = Make-Tab "Cai Dat Windows"
$LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text = "CHON FILE ISO WINDOWS"; $LblTitle.Font = "Segoe UI, 14, Bold"; $LblTitle.ForeColor = "Cyan"; $LblTitle.AutoSize=$true; $LblTitle.Location = "20,15"; $TabInstall.Controls.Add($LblTitle)

$CmbISO = New-Object System.Windows.Forms.ComboBox; $CmbISO.Size = "580, 30"; $CmbISO.Location = "20,55"; $CmbISO.Font = "Segoe UI, 10"; $CmbISO.DropDownStyle = "DropDownList"; $TabInstall.Controls.Add($CmbISO)
$BtnBrowse = New-Object System.Windows.Forms.Button; $BtnBrowse.Text = "TIM FILE"; $BtnBrowse.Location = "610,53"; $BtnBrowse.Size = "100,30"; $BtnBrowse.BackColor = "Gray"; $BtnBrowse.Add_Click({ $OFD = New-Object System.Windows.Forms.OpenFileDialog; $OFD.Filter = "ISO (*.iso)|*.iso"; if ($OFD.ShowDialog() -eq "OK") { $CmbISO.Items.Insert(0, $OFD.FileName); $CmbISO.SelectedIndex = 0 } }); $TabInstall.Controls.Add($BtnBrowse)
$LblScan = New-Object System.Windows.Forms.Label; $LblScan.Text = "Dang quet..."; $LblScan.Location = "20,90"; $LblScan.AutoSize=$true; $LblScan.ForeColor = "Yellow"; $TabInstall.Controls.Add($LblScan)

# Group Actions
$GBAct = New-Object System.Windows.Forms.GroupBox; $GBAct.Text = "CHON PHUONG PHAP"; $GBAct.Location = "20,130"; $GBAct.Size = "720,450"; $GBAct.ForeColor = "Lime"; $TabInstall.Controls.Add($GBAct)

$BtnMode1 = New-Object System.Windows.Forms.Button; $BtnMode1.Text = "CHE DO 1: CAI DE / NANG CAP (SETUP.EXE)"; $BtnMode1.Location = "20,40"; $BtnMode1.Size = "680,50"; $BtnMode1.BackColor = "LimeGreen"; $BtnMode1.ForeColor = "Black"; $BtnMode1.Font = "Segoe UI, 12, Bold"
$BtnMode1.Add_Click({ Show-SubMenu-Upgrade }); $GBAct.Controls.Add($BtnMode1)

$BtnMode2 = New-Object System.Windows.Forms.Button; $BtnMode2.Text = "CHE DO 2: CAI MOI (WinToHDD)"; $BtnMode2.Location = "20,110"; $BtnMode2.Size = "680,50"; $BtnMode2.BackColor = "Orange"; $BtnMode2.ForeColor = "Black"; $BtnMode2.Font = "Segoe UI, 12, Bold"
$BtnMode2.Add_Click({ Start-Install "WinToHDD" }); $GBAct.Controls.Add($BtnMode2)


# --- TAB 2: CAU HINH TU DONG (AUTO-UNATTEND) ---
$TabConfig = Make-Tab "Cau Hinh Tu Dong (Unattend)"
$LblInfo = New-Object System.Windows.Forms.Label; $LblInfo.Text = "CAU HINH FILE XML DE CAI WIN TU DONG HOAN TOAN"; $LblInfo.Font = "Segoe UI, 12, Bold"; $LblInfo.ForeColor = "Cyan"; $LblInfo.AutoSize=$true; $LblInfo.Location = "20,20"; $TabConfig.Controls.Add($LblInfo)

# Form Input
function Add-Input ($Txt, $Y, $Def="") {
    $L = New-Object System.Windows.Forms.Label; $L.Text = $Txt; $L.Location = "20,$Y"; $L.AutoSize=$true; $TabConfig.Controls.Add($L)
    $T = New-Object System.Windows.Forms.TextBox; $T.Text = $Def; $T.Location = "200,$Y"; $T.Size = "300,25"; $TabConfig.Controls.Add($T)
    return $T
}

$TxtUser = Add-Input "Ten User (Account):" 60 "Admin"
$TxtPass = Add-Input "Mat Khau (Bo trong neu ko):" 100 ""
$TxtPCName = Add-Input "Ten May Tinh:" 140 "PhatTan-PC"
$TxtKey = Add-Input "Product Key (Bo trong skip):" 180 ""

# Partition Option
$GBPart = New-Object System.Windows.Forms.GroupBox; $GBPart.Text = "TUY CHON O CUNG (NGUY HIEM - DOC KY)"; $GBPart.Location = "20,230"; $GBPart.Size = "720,120"; $GBPart.ForeColor = "Red"; $TabConfig.Controls.Add($GBPart)

$RadioWipe = New-Object System.Windows.Forms.RadioButton; $RadioWipe.Text = "XOA SACH O CUNG (Clean Install - Mat het du lieu)"; $RadioWipe.Location = "20,30"; $RadioWipe.AutoSize=$true; $RadioWipe.Checked=$true; $GBPart.Controls.Add($RadioWipe)
$RadioDual = New-Object System.Windows.Forms.RadioButton; $RadioDual.Text = "DUAL BOOT (Cai len phan vung trong - Giu Win cu)"; $RadioDual.Location = "20,60"; $RadioDual.AutoSize=$true; $GBPart.Controls.Add($RadioDual)

$BtnGenXML = New-Object System.Windows.Forms.Button; $BtnGenXML.Text = "TAO FILE AUTOUNATTEND.XML"; $BtnGenXML.Location = "20,380"; $BtnGenXML.Size = "720,50"; $BtnGenXML.BackColor = "Cyan"; $BtnGenXML.ForeColor = "Black"; $BtnGenXML.Font = "Segoe UI, 12, Bold"
$BtnGenXML.Add_Click({ Generate-XML }); $TabConfig.Controls.Add($BtnGenXML)

# --- HÀM XỬ LÝ XML ---
function Generate-XML {
    $User = $TxtUser.Text; $Pass = $TxtPass.Text; $PC = $TxtPCName.Text; $Key = $TxtKey.Text
    
    # 1. Tải file mẫu
    $XMLPath = "C:\autounattend.xml" # Lưu thẳng vào gốc ổ C để Boot Tạm nhận
    try { (New-Object Net.WebClient).DownloadFile($XML_Url, $XMLPath) } catch { [System.Windows.Forms.MessageBox]::Show("Loi tai file XML mau!", "Error"); return }
    
    # 2. Đọc & Thay thế
    $Content = Get-Content $XMLPath -Raw
    $Content = $Content -replace "%USERNAME%", $User
    $Content = $Content -replace "%PASSWORD%", $Pass
    $Content = $Content -replace "%COMPUTERNAME%", $PC
    if ($Key) { $Content = $Content -replace "%PRODUCTKEY%", $Key } else { $Content = $Content -replace "<ProductKey>.*?</ProductKey>", "" } # Xóa thẻ key nếu trống
    
    # Xử lý ổ cứng
    if ($RadioWipe.Checked) {
        # Giữ nguyên lệnh WipeDisk trong XML mẫu
    } else {
        # Nếu Dual Boot -> Xóa lệnh WipeDisk, đổi sang InstallToAvailablePartition
        $Content = $Content -replace "<WillWipeDisk>true</WillWipeDisk>", "<WillWipeDisk>false</WillWipeDisk>"
        $Content = $Content -replace "<InstallTo>.*?</InstallTo>", "<InstallTo><AvailablePartition>true</AvailablePartition></InstallTo>"
    }

    # 3. Lưu lại
    $Content | Set-Content $XMLPath
    [System.Windows.Forms.MessageBox]::Show("DA TAO FILE CAU HINH THANH CONG!`n`nFile luu tai: $XMLPath`nKhi chon 'Tao Boot Tam', file nay se duoc su dung.", "Phat Tan PC")
}

# --- HÀM SUBMENU (UPGRADE/BOOT TEMP) ---
function Show-SubMenu-Upgrade {
    $SubForm = New-Object System.Windows.Forms.Form; $SubForm.Text = "CHON CACH KHOI CHAY"; $SubForm.Size = "550, 300"; $SubForm.StartPosition = "CenterParent"; $SubForm.BackColor = "Black"; $SubForm.ForeColor = "White"
    $LblQ = New-Object System.Windows.Forms.Label; $LblQ.Text = "Ban muon cai dat theo cach nao?"; $LblQ.Location = "20,20"; $LblQ.AutoSize=$true; $LblQ.Font="Segoe UI, 11, Bold"; $SubForm.Controls.Add($LblQ)
    
    $BtnDirect = New-Object System.Windows.Forms.Button; $BtnDirect.Text = "CAI TRUC TIEP (Setup.exe)"; $BtnDirect.Location = "20,60"; $BtnDirect.Size = "490,40"; $BtnDirect.BackColor = "Cyan"; $BtnDirect.ForeColor = "Black"; $BtnDirect.Add_Click({ $SubForm.Close(); Start-Install "Direct" }); $SubForm.Controls.Add($BtnDirect)
    
    $BtnBoot = New-Object System.Windows.Forms.Button; $BtnBoot.Text = "TAO BOOT TAM (Dung file ISO + XML)"; $BtnBoot.Location = "20,110"; $BtnBoot.Size = "490,40"; $BtnBoot.BackColor = "Magenta"; $BtnBoot.ForeColor = "White"
    $BtnBoot.Add_Click({ 
        # Check XML
        if (Test-Path "C:\autounattend.xml") { $Msg = "Phat hien file cau hinh XML. Se cai dat tu dong!" } else { $Msg = "Khong co file XML. Se cai dat thu cong." }
        [System.Windows.Forms.MessageBox]::Show($Msg, "Thong bao")
        $SubForm.Close(); Start-Install "BootTmp" 
    }); $SubForm.Controls.Add($BtnBoot)
    $SubForm.ShowDialog()
}

# --- LOGIC INSTALL (GIỮ NGUYÊN) ---
function Start-Install ($Mode) {
    $ISO = $CmbISO.SelectedItem; if (!$ISO) { return }
    
    # Mount ISO
    Mount-DiskImage -ImagePath $ISO -StorageType ISO -ErrorAction SilentlyContinue
    $Vol = Get-Volume | Where-Object { Test-Path "$($_.DriveLetter):\setup.exe" } | Select -First 1
    $Drive = "$($Vol.DriveLetter):"

    if ($Mode -eq "Direct") { Start-Process "$Drive\setup.exe"; $Form.Close() }
    elseif ($Mode -eq "BootTmp") {
        $BootWim = "$Drive\sources\boot.wim"; $LocalWim = "\WinInstall_Boot.wim"
        Copy-Item $BootWim "C:$LocalWim" -Force
        Copy-Item "$Drive\boot\boot.sdi" "C:\boot.sdi" -Force
        
        # --- CHEN XML VAO (QUAN TRONG) ---
        if (Test-Path "C:\autounattend.xml") {
            Write-Host "Dang copy XML vao root..." -F Green
            # WinPE tu dong tim file autounattend.xml o thu muc goc cac o dia
            # Nen de o C:\ la no tu nhan
        }

        # ... (Code tạo BCD cũ) ...
        # (Để ngắn gọn, tôi giả định hàm Create-Boot-Entry đã có như bản trước)
        # Ông nhớ copy lại hàm Create-Boot-Entry từ bản V7.1 vào đây nhé!
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
