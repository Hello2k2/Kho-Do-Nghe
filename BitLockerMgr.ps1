# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "BITLOCKER MANAGER V2.1 - OFFLINE BACKUP"
$Form.Size = New-Object System.Drawing.Size(900, 600)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "QUAN LY KHOA O CUNG (NO EMAIL REQUIRED)"; $LblT.Font = "Impact, 18"; $LblT.ForeColor="Gold"; $LblT.AutoSize=$true; $LblT.Location="20,15"; $Form.Controls.Add($LblT)

# --- DANH SÁCH Ổ ĐĨA ---
$GbList = New-Object System.Windows.Forms.GroupBox; $GbList.Text = "Danh Sach O Dia"; $GbList.Location="20,70"; $GbList.Size="845,200"; $GbList.ForeColor="Cyan"; $Form.Controls.Add($GbList)

$Grid = New-Object System.Windows.Forms.DataGridView; $Grid.Location="15,25"; $Grid.Size="815,160"; $Grid.BackgroundColor="Black"; $Grid.ForeColor="Black"; $Grid.AllowUserToAddRows=$false; $Grid.RowHeadersVisible=$false; $Grid.SelectionMode="FullRowSelect"; $Grid.MultiSelect=$false; $Grid.AutoSizeColumnsMode="Fill"
$Grid.Columns.Add("Mount", "O Dia"); $Grid.Columns.Add("Status", "Trang Thai"); $Grid.Columns.Add("Lock", "Khoa (Lock)"); $Grid.Columns.Add("Encrypt", "Tien Do"); $Grid.Columns.Add("Key", "ID Bao Ve")
$Grid.Columns[0].FillWeight=30; $Grid.Columns[3].FillWeight=40
$GbList.Controls.Add($Grid)

# --- KHU VỰC MỞ KHÓA (UNLOCK) ---
$GbUnlock = New-Object System.Windows.Forms.GroupBox; $GbUnlock.Text = "MO KHOA O CUNG (UNLOCK)"; $GbUnlock.Location="20,290"; $GbUnlock.Size="845,100"; $GbUnlock.ForeColor="Lime"; $Form.Controls.Add($GbUnlock)

$LblKey = New-Object System.Windows.Forms.Label; $LblKey.Text = "Nhap Recovery Key (48 so):"; $LblKey.Location="20,40"; $LblKey.AutoSize=$true; $GbUnlock.Controls.Add($LblKey)
$TxtKey = New-Object System.Windows.Forms.TextBox; $TxtKey.Location="190,37"; $TxtKey.Size="450,30"; $TxtKey.Font="Consolas, 11"; $GbUnlock.Controls.Add($TxtKey)

$BtnUnlock = New-Object System.Windows.Forms.Button; $BtnUnlock.Text="GIAI MA (UNLOCK)"; $BtnUnlock.Location="660,35"; $BtnUnlock.Size="170,35"; $BtnUnlock.BackColor="Green"; $BtnUnlock.ForeColor="White"; $BtnUnlock.Font="Segoe UI, 9, Bold"
$GbUnlock.Controls.Add($BtnUnlock)

# --- KHU VỰC QUẢN LÝ (CONTROL) ---
$GbCtrl = New-Object System.Windows.Forms.GroupBox; $GbCtrl.Text = "QUAN LY & SAO LUU (KHONG CAN EMAIL)"; $GbCtrl.Location="20,410"; $GbCtrl.Size="845,130"; $GbCtrl.ForeColor="Orange"; $Form.Controls.Add($GbCtrl)

function Add-Btn ($P, $T, $X, $Y, $C, $Cmd) { $b=New-Object System.Windows.Forms.Button; $b.Text=$T; $b.Location="$X,$Y"; $b.Size="190,40"; $b.BackColor=$C; $b.ForeColor="White"; $b.FlatStyle="Flat"; $b.Add_Click($Cmd); $P.Controls.Add($b) }

# Hàng 1
Add-Btn $GbCtrl "TAT BITLOCKER (DECRYPT)" 20 30 "Firebrick" { Action-BitLocker "Disable" }
Add-Btn $GbCtrl "TAM DUNG (SUSPEND)" 230 30 "DimGray" { Action-BitLocker "Suspend" }
Add-Btn $GbCtrl "BAT LAI (RESUME)" 440 30 "SeaGreen" { Action-BitLocker "Resume" }
Add-Btn $GbCtrl "REFRESH LIST" 650 30 "Blue" { Load-Drives }

# Hàng 2
Add-Btn $GbCtrl "SAO LUU KEY RA FILE" 20 80 "Teal" { Backup-Key }
Add-Btn $GbCtrl "MO CONTROL PANEL" 650 80 "Gray" { Start-Process "control" -ArgumentList "/name Microsoft.BitLockerDriveEncryption" }

# --- LOGIC ---

function Load-Drives {
    $Grid.Rows.Clear()
    $TxtKey.Text = ""
    try {
        $Vols = Get-BitLockerVolume
        foreach ($V in $Vols) {
            $LockStat = $V.VolumeStatus 
            $IsLocked = if($V.ProtectionStatus -eq "On") { "LOCKED (Dang Khoa)" } else { "UNLOCKED (Mo)" }
            if ($V.VolumeStatus -eq "FullyDecrypted") { $IsLocked = "OFF (Khong dung)" }
            
            $Percent = "$($V.EncryptionPercentage)%"
            $Ids = ($V.KeyProtector | Where {$_.KeyProtectorType -eq "RecoveryPassword"}).KeyProtectorId
            
            $Grid.Rows.Add($V.MountPoint, $V.VolumeStatus, $IsLocked, $Percent, "$Ids") | Out-Null
        }
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi doc thong tin BitLocker!`nCan quyen Admin hoac may khong ho tro.", "Error") }
}

$BtnUnlock.Add_Click({
    $Key = $TxtKey.Text.Trim()
    if ($Grid.SelectedRows.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Chon 1 o dia truoc!", "Loi"); return }
    $Drv = $Grid.SelectedRows[0].Cells[0].Value
    
    if (!$Key) { [System.Windows.Forms.MessageBox]::Show("Chua nhap Key!", "Loi"); return }
    
    try {
        $Form.Cursor = "WaitCursor"
        Unlock-BitLocker -MountPoint $Drv -RecoveryPassword $Key -ErrorAction Stop
        [System.Windows.Forms.MessageBox]::Show("DA MO KHOA THANH CONG! ($Drv)", "Success")
        Load-Drives
    } catch {
        [System.Windows.Forms.MessageBox]::Show("MO KHOA THAT BAI!`nKiem tra lai Key hoac o dia.", "Error")
    }
    $Form.Cursor = "Default"
})

function Action-BitLocker ($Action) {
    if ($Grid.SelectedRows.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Chon 1 o dia truoc!", "Loi"); return }
    $Drv = $Grid.SelectedRows[0].Cells[0].Value
    
    try {
        if ($Action -eq "Disable") {
            if ([System.Windows.Forms.MessageBox]::Show("Ban co chac muon GIAI MA (Decrypt) toan bo o $Drv?`nQua trinh nay co the mat nhieu thoi gian.", "Canh bao", "YesNo", "Warning") -eq "Yes") {
                Disable-BitLocker -MountPoint $Drv -ErrorAction Stop
                [System.Windows.Forms.MessageBox]::Show("Da gui lenh Giai Ma! O dia dang duoc Decrypt ngam.", "Info")
            }
        }
        elseif ($Action -eq "Suspend") { Suspend-BitLocker -MountPoint $Drv -ErrorAction Stop; [System.Windows.Forms.MessageBox]::Show("Da Tam Dung bao ve (Suspend).", "Info") }
        elseif ($Action -eq "Resume") { Resume-BitLocker -MountPoint $Drv -ErrorAction Stop; [System.Windows.Forms.MessageBox]::Show("Da Bat Lai bao ve (Resume).", "Info") }
        
        Load-Drives
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi: $($_.Exception.Message)", "Error") }
}

function Backup-Key {
    if ($Grid.SelectedRows.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Chon 1 o dia truoc!", "Loi"); return }
    $Row = $Grid.SelectedRows[0]
    $Drv = $Row.Cells[0].Value
    $Status = $Row.Cells[2].Value
    
    # Check nếu đang khóa thì không lấy key được
    if ($Status -match "LOCKED") {
        [System.Windows.Forms.MessageBox]::Show("O dia dang bi KHOA (LOCKED)!`nBan phai mo khoa truoc thi moi lay duoc Key.", "Canh bao", "OK", "Warning")
        return
    }
    
    try {
        $Vol = Get-BitLockerVolume -MountPoint $Drv
        $KeyObj = $Vol.KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }
        
        # Nếu chưa có Key 48 số (VD: Chỉ dùng TPM), hỏi tạo mới
        if (!$KeyObj) {
            if ([System.Windows.Forms.MessageBox]::Show("O dia nay chua co Recovery Key (48 so).`nBan co muon TAO MOI mot ma Key ngay bay gio de sao luu khong?", "Tao Key Moi", "YesNo", "Question") -eq "Yes") {
                Add-BitLockerKeyProtector -MountPoint $Drv -RecoveryPassword -ErrorAction Stop
                $Vol = Get-BitLockerVolume -MountPoint $Drv # Reload
                $KeyObj = $Vol.KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }
            } else { return }
        }
        
        # Xuất Key
        if ($KeyObj) {
            $Pass = $KeyObj.RecoveryPassword
            $ID = $KeyObj.KeyProtectorId
            
            $Save = New-Object System.Windows.Forms.SaveFileDialog
            $Save.FileName = "BitLocker_Key_$($Drv.Replace(':','')).txt"
            $Save.Filter = "Text File|*.txt"
            
            if ($Save.ShowDialog() -eq "OK") {
                $Content = "--- BITLOCKER RECOVERY KEY (OFFLINE BACKUP) ---`r`nDrive: $Drv`r`nID: $ID`r`nKEY: $Pass`r`nDate: $(Get-Date)`r`nNote: Luu file nay vao USB hoac Dien thoai."
                [IO.File]::WriteAllText($Save.FileName, $Content)
                [System.Windows.Forms.MessageBox]::Show("DA LUU KEY THANH CONG!`nFile: $($Save.FileName)", "Phat Tan PC")
                Invoke-Item $Save.FileName
            }
        }
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi lay Key: $($_.Exception.Message)", "Error") }
}

# Init
$Form.Add_Shown({ Load-Drives })
$Form.ShowDialog() | Out-Null
