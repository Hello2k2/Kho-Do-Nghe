# --- 1. TU DONG YEU CAU QUYEN ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- CẤU HÌNH ---
# Link tải WinToHDD từ kho của ông
$WinToHDD_Url = "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/WinToHDD.exe"

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CAI DAT WINDOWS TU DONG - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(700, 480)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$LblTitle = New-Object System.Windows.Forms.Label
$LblTitle.Text = "CHON FILE ISO WINDOWS (TU DONG QUET)"
$LblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$LblTitle.ForeColor = "Cyan"
$LblTitle.AutoSize = $true; $LblTitle.Location = "20,15"
$Form.Controls.Add($LblTitle)

# --- COMBOBOX ISO ---
$CmbISO = New-Object System.Windows.Forms.ComboBox
$CmbISO.Size = New-Object System.Drawing.Size(530, 30); $CmbISO.Location = "20,55"; $CmbISO.Font = "Segoe UI, 10"
$CmbISO.DropDownStyle = "DropDownList"
$Form.Controls.Add($CmbISO)

# Nút Browse
$BtnBrowse = New-Object System.Windows.Forms.Button
$BtnBrowse.Text = "TIM THU CONG"
$BtnBrowse.Location = "560,53"; $BtnBrowse.Size = "100,30"; $BtnBrowse.BackColor = "Gray"; $BtnBrowse.ForeColor = "White"
$BtnBrowse.Add_Click({
    $OFD = New-Object System.Windows.Forms.OpenFileDialog
    $OFD.Filter = "ISO Image (*.iso)|*.iso"
    $OFD.Title = "Chon file ISO Windows"
    if ($OFD.ShowDialog() -eq "OK") { 
        $CmbISO.Items.Insert(0, $OFD.FileName)
        $CmbISO.SelectedIndex = 0
    }
})
$Form.Controls.Add($BtnBrowse)

# Status Label
$LblScan = New-Object System.Windows.Forms.Label
$LblScan.Text = "Dang quet file ISO..."
$LblScan.Location = "20,90"; $LblScan.AutoSize = $true; $LblScan.ForeColor = "Yellow"
$Form.Controls.Add($LblScan)

# --- GROUP 1: CAI DE (UPGRADE/REPAIR) ---
$GB1 = New-Object System.Windows.Forms.GroupBox; $GB1.Text = "CHE DO 1: CAI DE (Giu du lieu / Sua loi Win)"; $GB1.Location = "20,120"; $GB1.Size = "640,120"; $GB1.ForeColor = "Lime"
$Form.Controls.Add($GB1)

$Lbl1 = New-Object System.Windows.Forms.Label; $Lbl1.Text = "Mount ISO -> Chay Setup.exe tu dong. Dung de nang cap Win 10 len 11 hoac sua loi Win."; $Lbl1.Location = "20,30"; $Lbl1.AutoSize = $true; $Lbl1.ForeColor = "White"; $GB1.Controls.Add($Lbl1)

$BtnMount = New-Object System.Windows.Forms.Button; $BtnMount.Text = "MO FILE ISO VA CHAY SETUP.EXE"; $BtnMount.Location = "20,65"; $BtnMount.Size = "600,35"; $BtnMount.BackColor = "LimeGreen"; $BtnMount.ForeColor = "Black"; $BtnMount.Font = "Segoe UI, 10, Bold"
$BtnMount.Add_Click({
    $ISO = $CmbISO.SelectedItem
    if ($ISO -eq $null -or $ISO -eq "") { [System.Windows.Forms.MessageBox]::Show("Chua chon file ISO!", "Loi"); return }
    
    try {
        Write-Host "Dang Mount ISO: $ISO" -F Yellow
        $MountResult = Mount-DiskImage -ImagePath $ISO -PassThru
        $DriveLetter = ($MountResult | Get-Volume).DriveLetter
        
        if ($DriveLetter) {
            $SetupPath = "$($DriveLetter):\setup.exe"
            if (Test-Path $SetupPath) {
                Start-Process $SetupPath
                [System.Windows.Forms.MessageBox]::Show("Da mo bo cai Windows (O $DriveLetter).`nBam Next de cai dat!", "Phat Tan PC")
                $Form.Close()
            } else { [System.Windows.Forms.MessageBox]::Show("Khong tim thay file Setup.exe trong ISO!", "Loi") }
        }
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi Mount ISO: $($_.Exception.Message)", "Loi") }
})
$GB1.Controls.Add($BtnMount)

# --- GROUP 2: CAI MOI (CLEAN INSTALL - WINTOHDD PORTABLE) ---
$GB2 = New-Object System.Windows.Forms.GroupBox; $GB2.Text = "CHE DO 2: CAI MOI (Format C - WinToHDD Technician)"; $GB2.Location = "20,260"; $GB2.Size = "640,120"; $GB2.ForeColor = "Orange"
$Form.Controls.Add($GB2)

$Lbl2 = New-Object System.Windows.Forms.Label; $Lbl2.Text = "Su dung WinToHDD Technician (Portable) tu kho Phat Tan PC.`nHo tro cai lai Win trang tinh, Clone Win ma KHONG CAN USB."; $Lbl2.Location = "20,30"; $Lbl2.AutoSize = $true; $Lbl2.ForeColor = "White"; $GB2.Controls.Add($Lbl2)

$BtnWTH = New-Object System.Windows.Forms.Button; $BtnWTH.Text = "TAI VA MO WINTOHDD (PORTABLE)"; $BtnWTH.Location = "20,65"; $BtnWTH.Size = "600,35"; $BtnWTH.BackColor = "Orange"; $BtnWTH.ForeColor = "Black"; $BtnWTH.Font = "Segoe UI, 10, Bold"
$BtnWTH.Add_Click({
    $WTHPath = "$env:TEMP\WinToHDD.exe"
    
    # Kiểm tra nếu đã tải rồi thì chạy luôn
    if (Test-Path $WTHPath) {
        Start-Process $WTHPath
    } else {
        try {
            $Form.Text = "DANG TAI WINTOHDD TECHNICIAN..."
            # Tải từ GitHub của ông
            (New-Object Net.WebClient).DownloadFile($WinToHDD_Url, $WTHPath)
            
            # Chạy luôn (Vì là Portable nên không cần cài đặt silent)
            if (Test-Path $WTHPath) {
                Start-Process $WTHPath
                $Form.Text = "CAI DAT WINDOWS TU DONG - PHAT TAN PC"
            } else {
                 [System.Windows.Forms.MessageBox]::Show("Tai that bai. Kiem tra lai mang!", "Loi")
            }
        } catch { [System.Windows.Forms.MessageBox]::Show("Loi: $($_.Exception.Message)", "Loi") }
    }
})
$GB2.Controls.Add($BtnWTH)

# --- LOGIC AUTO SCAN ---
$Form.Add_Shown({
    $Form.Refresh()
    $LblScan.Text = "Dang quet ISO trong: Downloads, Desktop, Documents..."
    
    $ScanPaths = @( "$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop", "$env:USERPROFILE\Documents", $PWD.Path, "D:", "E:" )
    
    $FoundCount = 0
    foreach ($Path in $ScanPaths) {
        if (Test-Path $Path) {
            $ISOs = Get-ChildItem -Path $Path -Filter "*.iso" -File -ErrorAction SilentlyContinue -Recurse -Depth 1
            foreach ($File in $ISOs) {
                if ($File.Length -gt 1GB) { # Chỉ lấy file > 1GB để tránh file rác
                    $CmbISO.Items.Add($File.FullName)
                    $FoundCount++
                }
            }
        }
    }
    
    if ($FoundCount -gt 0) {
        $CmbISO.SelectedIndex = 0
        $LblScan.Text = "Tim thay $FoundCount file ISO."
        $LblScan.ForeColor = "Lime"
    } else {
        $LblScan.Text = "Khong tim thay file ISO nao. Hay tai ve hoac chon thu cong."
        $LblScan.ForeColor = "Red"
    }
})

$Form.ShowDialog() | Out-Null
