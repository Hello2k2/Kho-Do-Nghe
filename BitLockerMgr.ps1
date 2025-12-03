# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "BITLOCKER MANAGER V2.3 - FULL COMPATIBILITY"
$Form.Size = New-Object System.Drawing.Size(900, 600)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "QUAN LY KHOA O CUNG (DUAL ENGINE)"; $LblT.Font = "Impact, 18"; $LblT.ForeColor="Gold"; $LblT.AutoSize=$true; $LblT.Location="20,15"; $Form.Controls.Add($LblT)

# --- DANH SÁCH Ổ ĐĨA ---
$GbList = New-Object System.Windows.Forms.GroupBox; $GbList.Text = "Danh Sach O Dia"; $GbList.Location="20,70"; $GbList.Size="845,200"; $GbList.ForeColor="Cyan"; $Form.Controls.Add($GbList)

$Grid = New-Object System.Windows.Forms.DataGridView; $Grid.Location="15,25"; $Grid.Size="815,160"; $Grid.BackgroundColor="Black"; $Grid.ForeColor="Black"; $Grid.AllowUserToAddRows=$false; $Grid.RowHeadersVisible=$false; $Grid.SelectionMode="FullRowSelect"; $Grid.MultiSelect=$false; $Grid.AutoSizeColumnsMode="Fill"
$Grid.Columns.Add("Mount", "O Dia"); $Grid.Columns.Add("Status", "Trang Thai"); $Grid.Columns.Add("Lock", "Khoa (Lock)"); $Grid.Columns.Add("Encrypt", "Tien Do"); $Grid.Columns.Add("Key", "Che Do (Mode)")
$Grid.Columns[0].FillWeight=30; $Grid.Columns[3].FillWeight=40
$GbList.Controls.Add($Grid)

# --- KHU VỰC MỞ KHÓA (UNLOCK) ---
$GbUnlock = New-Object System.Windows.Forms.GroupBox; $GbUnlock.Text = "MO KHOA O CUNG (UNLOCK)"; $GbUnlock.Location="20,290"; $GbUnlock.Size="845,100"; $GbUnlock.ForeColor="Lime"; $Form.Controls.Add($GbUnlock)

$LblKey = New-Object System.Windows.Forms.Label; $LblKey.Text = "Nhap Recovery Key (48 so):"; $LblKey.Location="20,40"; $LblKey.AutoSize=$true; $GbUnlock.Controls.Add($LblKey)
$TxtKey = New-Object System.Windows.Forms.TextBox; $TxtKey.Location="190,37"; $TxtKey.Size="450,30"; $TxtKey.Font="Consolas, 11"; $GbUnlock.Controls.Add($TxtKey)

$BtnUnlock = New-Object System.Windows.Forms.Button; $BtnUnlock.Text="GIAI MA (UNLOCK)"; $BtnUnlock.Location="660,35"; $BtnUnlock.Size="170,35"; $BtnUnlock.BackColor="Green"; $BtnUnlock.ForeColor="White"; $BtnUnlock.Font="Segoe UI, 9, Bold"
$GbUnlock.Controls.Add($BtnUnlock)

# --- KHU VỰC QUẢN LÝ (CONTROL) ---
$GbCtrl = New-Object System.Windows.Forms.GroupBox; $GbCtrl.Text = "QUAN LY & SAO LUU"; $GbCtrl.Location="20,410"; $GbCtrl.Size="845,130"; $GbCtrl.ForeColor="Orange"; $Form.Controls.Add($GbCtrl)

function Add-Btn ($P, $T, $X, $Y, $C, $Cmd) { $b=New-Object System.Windows.Forms.Button; $b.Text=$T; $b.Location="$X,$Y"; $b.Size="190,40"; $b.BackColor=$C; $b.ForeColor="White"; $b.FlatStyle="Flat"; $b.Add_Click($Cmd); $P.Controls.Add($b) }

Add-Btn $GbCtrl "TAT BITLOCKER (DECRYPT)" 20 30 "Firebrick" { Action-BitLocker "Disable" }
Add-Btn $GbCtrl "TAM DUNG (SUSPEND)" 230 30 "DimGray" { Action-BitLocker "Suspend" }
Add-Btn $GbCtrl "BAT LAI (RESUME)" 440 30 "SeaGreen" { Action-BitLocker "Resume" }
Add-Btn $GbCtrl "REFRESH LIST" 650 30 "Blue" { Load-Drives }

Add-Btn $GbCtrl "SAO LUU KEY RA FILE" 20 80 "Teal" { Backup-Key }
Add-Btn $GbCtrl "MO CONTROL PANEL" 650 80 "Gray" { Start-Process "control" -ArgumentList "/name Microsoft.BitLockerDriveEncryption" }

# --- LOGIC (DUAL SCAN ENGINE) ---

function Load-Drives {
    $Grid.Rows.Clear()
    $TxtKey.Text = ""
    
    # --- CÁCH 1: POWERSHELL CMDLET (MODERN) ---
    try {
        $Vols = Get-BitLockerVolume -ErrorAction Stop
        if ($Vols.Count -gt 0) {
            foreach ($V in $Vols) {
                $LockStat = $V.VolumeStatus
                $IsLocked = if($V.ProtectionStatus -eq "On") { "LOCKED (Khoa)" } else { "UNLOCKED (Mo)" }
                if ($V.VolumeStatus -eq "FullyDecrypted") { $IsLocked = "OFF (Khong dung)" }
                $Percent = "$($V.EncryptionPercentage)%"
                $Mode = "PowerShell Mode"
                $Grid.Rows.Add($V.MountPoint, $V.VolumeStatus, $IsLocked, $Percent, $Mode) | Out-Null
            }
            return
        }
    } catch {}

    # --- CÁCH 2: WMI (LEGACY / FAILOVER) ---
    if ($Grid.Rows.Count -eq 0) {
        try {
            $WmiVols = Get-WmiObject -Namespace "root\CIMV2\Security\MicrosoftVolumeEncryption" -Class Win32_EncryptableVolume
            foreach ($W in $WmiVols) {
                $DrvLetter = $W.DriveLetter
                $StatMap = @{0="FullyDecrypted"; 1="FullyEncrypted"; 2="Encrypting"; 3="Decrypting"; 4="Paused"}
                $VolStat = if ($StatMap[$W.ConversionStatus]) { $StatMap[$W.ConversionStatus] } else { "Unknown" }
                
                $IsLocked = if ($W.ProtectionStatus -eq 1) { "LOCKED (Khoa)" } else { 
                    if ($W.ConversionStatus -eq 0) { "OFF (Khong dung)" } else { "UNLOCKED (Mo)" }
                }
                
                $Percent = if ($W.ConversionStatus -eq 1) { "100%" } else { "0%" }
                $Grid.Rows.Add($DrvLetter, $VolStat, $IsLocked, $Percent, "WMI Mode") | Out-Null
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("KHONG TIM THAY O DIA NAO!`nCa 2 phuong phap (Cmdlet & WMI) deu that bai.", "Error")
        }
    }
}

$BtnUnlock.Add_Click({
    $Key = $TxtKey.Text.Trim()
    if ($Grid.SelectedRows.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Chon 1 o dia truoc!", "Loi"); return }
    $Drv = $Grid.SelectedRows[0].Cells[0].Value
    if (!$Key) { [System.Windows.Forms.MessageBox]::Show("Chua nhap Key!", "Loi"); return }
    
    try {
        $Form.Cursor = "WaitCursor"
        # Thu 1: Cmdlet
        Unlock-BitLocker -MountPoint $Drv -RecoveryPassword $Key -ErrorAction Stop
        [System.Windows.Forms.MessageBox]::Show("DA MO KHOA THANH CONG! ($Drv)", "Success")
        Load-Drives
    } catch {
        # Thu 2: CMD
        $Proc = Start-Process "manage-bde" -ArgumentList "-unlock $Drv -rp $Key" -NoNewWindow -PassThru -Wait
        if ($Proc.ExitCode -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("DA MO KHOA (CMD MODE)! ($Drv)", "Success"); Load-Drives
        } else {
            [System.Windows.Forms.MessageBox]::Show("MO KHOA THAT BAI!`nKiem tra lai Key.", "Error")
        }
    }
    $Form.Cursor = "Default"
})

function Action-BitLocker ($Action) {
    if ($Grid.SelectedRows.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Chon 1 o dia truoc!", "Loi"); return }
    $Drv = $Grid.SelectedRows[0].Cells[0].Value
    
    # Fallback CMD cho chac an
    if ($Action -eq "Disable") { 
        if ([System.Windows.Forms.MessageBox]::Show("Ban co chac muon GIAI MA (Decrypt) o $Drv?", "Warning", "YesNo") -eq "Yes") {
            Start-Process "manage-bde" "-off $Drv" -NoNewWindow -Wait
            [System.Windows.Forms.MessageBox]::Show("Da gui lenh Giai Ma (CMD).", "Info")
        }
    }
    if ($Action -eq "Suspend") { Start-Process "manage-bde" "-protectors -disable $Drv" -NoNewWindow -Wait; [System.Windows.Forms.MessageBox]::Show("Da Suspend.", "Info") }
    if ($Action -eq "Resume") { Start-Process "manage-bde" "-protectors -enable $Drv" -NoNewWindow -Wait; [System.Windows.Forms.MessageBox]::Show("Da Resume.", "Info") }
    Load-Drives
}

# --- FIX LỖI BACKUP KEY (HỖ TRỢ CẢ WMI) ---
function Backup-Key {
    if ($Grid.SelectedRows.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Chon 1 o dia truoc!", "Loi"); return }
    $Row = $Grid.SelectedRows[0]; $Drv = $Row.Cells[0].Value
    
    $Pass = ""
    $ID = "Unknown"
    
    # --- THỬ LẤY KEY BẰNG POWERSHELL ---
    try {
        $Vol = Get-BitLockerVolume -MountPoint $Drv -ErrorAction Stop
        $KeyObj = $Vol.KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }
        if ($KeyObj) { $Pass = $KeyObj.RecoveryPassword; $ID = $KeyObj.KeyProtectorId }
    } catch {
        # --- NẾU LỖI -> THỬ LẤY KEY BẰNG WMI (FIX CHO MÁY ẢO) ---
        try {
            $WmiVol = Get-WmiObject -Namespace "root\CIMV2\Security\MicrosoftVolumeEncryption" -Class Win32_EncryptableVolume -Filter "DriveLetter='$Drv'"
            # Type 3 = Numerical Password (48 so)
            $Res = $WmiVol.GetKeyProtectors(3) 
            if ($Res.ReturnValue -eq 0 -and $Res.VolumeKeyProtectorID.Count -gt 0) {
                $ID = $Res.VolumeKeyProtectorID[0]
                $KeyRes = $WmiVol.GetKeyProtectorNumericalPassword($ID)
                if ($KeyRes.ReturnValue -eq 0) { $Pass = $KeyRes.NumericalPassword }
            } else {
                # Neu chua co Key -> Tao moi bang WMI
                if ([System.Windows.Forms.MessageBox]::Show("O dia nay chua co Recovery Key (48 so). Tao moi?", "Tao Key", "YesNo") -eq "Yes") {
                    $WmiVol.ProtectKeyWithNumericalPassword() | Out-Null
                    # Lay lai sau khi tao
                    $Res2 = $WmiVol.GetKeyProtectors(3)
                    if ($Res2.VolumeKeyProtectorID.Count -gt 0) {
                        $ID = $Res2.VolumeKeyProtectorID[0]
                        $KeyRes2 = $WmiVol.GetKeyProtectorNumericalPassword($ID)
                        $Pass = $KeyRes2.NumericalPassword
                    }
                }
            }
        } catch {}
    }
    
    # LUU FILE
    if ($Pass) {
        $Save = New-Object System.Windows.Forms.SaveFileDialog; $Save.FileName = "BitLocker_Key_$($Drv.Replace(':','')).txt"
        if ($Save.ShowDialog() -eq "OK") {
            [IO.File]::WriteAllText($Save.FileName, "--- BITLOCKER KEY ---`r`nDRIVE: $Drv`r`nID: $ID`r`nKEY: $Pass`r`nDATE: $(Get-Date)")
            [System.Windows.Forms.MessageBox]::Show("Da luu!", "Success"); Invoke-Item $Save.FileName
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Khong lay duoc Key! (Co the o dia chua duoc Ma Hoa hoac chua co Key 48 so)", "Error")
    }
}

# Init
$Form.Add_Shown({ Load-Drives })
$Form.ShowDialog() | Out-Null
