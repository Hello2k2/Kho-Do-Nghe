# --- INIT ---
try { Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing } catch { Exit }

# Link XML Gốc (Chứa các biến %BIEN% để thay thế)
$XML_Url = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/autounattend.xml"

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CAU HINH FILE TU DONG - PHAT TAN PC (V2.0 SMART)"
$Form.Size = New-Object System.Drawing.Size(650, 750) # Tăng chiều cao
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Fonts
$FontBold = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$FontNorm = New-Object System.Drawing.Font("Segoe UI", 10)

# Header
$Lbl = New-Object System.Windows.Forms.Label; $Lbl.Text = "THONG TIN TAI KHOAN & HE THONG"; $Lbl.Location = "20,20"; $Lbl.AutoSize=$true; $Lbl.Font=$FontBold; $Lbl.ForeColor="Cyan"; $Form.Controls.Add($Lbl)

# Helper Input
function Add-Input ($T, $Y, $D) {
    $L=New-Object System.Windows.Forms.Label; $L.Text=$T; $L.Location="20,$Y"; $L.AutoSize=$true; $L.Font=$FontNorm; $Form.Controls.Add($L)
    $B=New-Object System.Windows.Forms.TextBox; $B.Text=$D; $B.Location="200,$Y"; $B.Size="400,25"; $B.Font=$FontNorm; $Form.Controls.Add($B); return $B
}

$TxtUser = Add-Input "Ten User (Account):" 60 "Admin"
$TxtPass = Add-Input "Mat Khau:" 100 ""
$TxtPC   = Add-Input "Ten May Tinh:" 140 "PhatTan-PC"
$TxtKey  = Add-Input "Product Key:" 180 ""

$LblHint = New-Object System.Windows.Forms.Label; $LblHint.Text = "(De trong Key/Pass se tu dong xoa bo cau hinh tuong ung)"; $LblHint.Location = "200,210"; $LblHint.AutoSize=$true; $LblHint.ForeColor="Gray"; $Form.Controls.Add($LblHint)

# --- SETTINGS GROUP ---
$GBSet = New-Object System.Windows.Forms.GroupBox; $GBSet.Text = "CAI DAT HE THONG"; $GBSet.Location = "20,240"; $GBSet.Size = "580,150"; $GBSet.ForeColor = "Lime"; $Form.Controls.Add($GBSet)

# Timezone
$LblTZ = New-Object System.Windows.Forms.Label; $LblTZ.Text = "Mui Gio:"; $LblTZ.Location = "20,30"; $LblTZ.AutoSize=$true; $LblTZ.ForeColor="White"; $GBSet.Controls.Add($LblTZ)
$CmbTZ = New-Object System.Windows.Forms.ComboBox; $CmbTZ.Location = "100,27"; $CmbTZ.Size = "300,25"; $CmbTZ.DropDownStyle="DropDownList"; $GBSet.Controls.Add($CmbTZ)
$CmbTZ.Items.AddRange(@("SE Asia Standard Time", "Pacific Standard Time", "China Standard Time", "Tokyo Standard Time"))
$CmbTZ.SelectedIndex = 0 # Mặc định VN

# Options
$CkSkipWifi = New-Object System.Windows.Forms.CheckBox; $CkSkipWifi.Text = "Bo qua Wifi (OOBE) - Vao thang Desktop"; $CkSkipWifi.Location = "20,60"; $CkSkipWifi.AutoSize=$true; $CkSkipWifi.ForeColor="White"; $CkSkipWifi.Checked=$true; $GBSet.Controls.Add($CkSkipWifi)
$CkAutoLogon = New-Object System.Windows.Forms.CheckBox; $CkAutoLogon.Text = "Tu dong dang nhap (Auto Logon)"; $CkAutoLogon.Location = "20,90"; $CkAutoLogon.AutoSize=$true; $CkAutoLogon.ForeColor="White"; $CkAutoLogon.Checked=$true; $GBSet.Controls.Add($CkAutoLogon)
$CkDefender = New-Object System.Windows.Forms.CheckBox; $CkDefender.Text = "Tat Windows Defender (Can than)"; $CkDefender.Location = "300,60"; $CkDefender.AutoSize=$true; $CkDefender.ForeColor="Orange"; $GBSet.Controls.Add($CkDefender)
$CkUAC = New-Object System.Windows.Forms.CheckBox; $CkUAC.Text = "Tat UAC (Hoi quyen Admin)"; $CkUAC.Location = "300,90"; $CkUAC.AutoSize=$true; $CkUAC.ForeColor="Orange"; $GBSet.Controls.Add($CkUAC)

# --- PARTITION GROUP ---
$GB = New-Object System.Windows.Forms.GroupBox; $GB.Text = "CHIA O CUNG (DISK PARTITION)"; $GB.Location = "20,410"; $GB.Size = "580,100"; $GB.ForeColor = "Yellow"; $Form.Controls.Add($GB)
$RadWipe = New-Object System.Windows.Forms.RadioButton; $RadWipe.Text = "XOA SACH O CUNG (Clean Install)"; $RadWipe.Location = "20,30"; $RadWipe.AutoSize=$true; $RadWipe.ForeColor="White"; $RadWipe.Checked=$true; $GB.Controls.Add($RadWipe)
$RadDual = New-Object System.Windows.Forms.RadioButton; $RadDual.Text = "DUAL BOOT (Giu Win Cu - Cai vao vung trong)"; $RadDual.Location = "20,60"; $RadDual.AutoSize=$true; $RadDual.ForeColor="White"; $GB.Controls.Add($RadDual)

# --- SAVE BUTTON ---
$BtnSave = New-Object System.Windows.Forms.Button; $BtnSave.Text = "TAO FILE AUTOUNATTEND.XML"; $BtnSave.Location = "20,530"; $BtnSave.Size = "580,50"; $BtnSave.BackColor = "Cyan"; $BtnSave.ForeColor = "Black"; $BtnSave.Font=$FontBold
$BtnSave.Add_Click({
    $XMLPath = "$env:SystemDrive\autounattend.xml"
    
    try {
        # 1. Tải file mẫu
        (New-Object Net.WebClient).DownloadFile($XML_Url, $XMLPath)
        $Content = Get-Content $XMLPath -Raw

        # 2. Thay thế thông tin cơ bản
        $Content = $Content -replace "%USERNAME%", $TxtUser.Text
        $Content = $Content -replace "%COMPUTERNAME%", $TxtPC.Text
        $Content = $Content -replace "SE Asia Standard Time", $CmbTZ.SelectedItem

        # 3. XỬ LÝ KEY (QUAN TRỌNG: Xóa Tag nếu trống)
        if ([string]::IsNullOrWhiteSpace($TxtKey.Text)) {
            # Dùng Regex xóa cả khối <ProductKey>...</ProductKey>
            $Content = $Content -replace "(?s)<ProductKey>.*?</ProductKey>", ""
            # Dự phòng: Xóa thẻ Key lẻ nếu template khác
            $Content = $Content -replace "<Key>.*?</Key>", "" 
        } else {
            $Content = $Content -replace "%PRODUCTKEY%", $TxtKey.Text
        }

        # 4. XỬ LÝ PASSWORD (QUAN TRỌNG: Xóa Tag nếu trống)
        if ([string]::IsNullOrWhiteSpace($TxtPass.Text)) {
            # Xóa thẻ Password trong UserAccounts
            $Content = $Content -replace "<Password>.*?<Value>%PASSWORD%</Value>.*?</Password>", ""
            $Content = $Content -replace "<Password>.*?<Value></Value>.*?</Password>", ""
            # Nếu AutoLogon cũng cần pass, ta xóa password trong AutoLogon
            $Content = $Content -replace "<Password>.*?<Value>%PASSWORD%</Value>.*?</Password>", ""
            
            # Replace %PASSWORD% còn sót lại thành rỗng
            $Content = $Content -replace "%PASSWORD%", ""
        } else {
            $Content = $Content -replace "%PASSWORD%", $TxtPass.Text
        }

        # 5. Cấu hình Settings
        if ($CkSkipWifi.Checked) { 
            $Content = $Content -replace "<HideWirelessSetupInOOBE>false</HideWirelessSetupInOOBE>", "<HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>" 
        }
        
        if ($CkAutoLogon.Checked) { 
            $Content = $Content -replace "<Enabled>false</Enabled>", "<Enabled>true</Enabled>" 
        } else {
            # Nếu tắt AutoLogon -> Xóa cả khối AutoLogon
            $Content = $Content -replace "(?s)<AutoLogon>.*?</AutoLogon>", ""
        }

        # 6. Xử lý Tweaks (Defender/UAC) - Chèn vào RunSynchronous
        $Tweaks = ""
        if ($CkDefender.Checked) { $Tweaks += "<RunSynchronousCommand wcm:action='add'><Order>10</Order><Path>reg.exe add `"HKLM\SOFTWARE\Policies\Microsoft\Windows Defender`" /v DisableAntiSpyware /t REG_DWORD /d 1 /f</Path></RunSynchronousCommand>" }
        if ($CkUAC.Checked) { $Tweaks += "<RunSynchronousCommand wcm:action='add'><Order>11</Order><Path>reg.exe add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" /v EnableLUA /t REG_DWORD /d 0 /f</Path></RunSynchronousCommand>" }
        
        if ($Tweaks -ne "") {
            # Chèn vào cuối khối RunSynchronous
            $Content = $Content -replace "</RunSynchronous>", "$Tweaks</RunSynchronous>"
        }

        # 7. Xử lý Partition
        if ($RadWipe.Checked) {
            $Content = $Content -replace "%WIPEDISK%", "true"
            $PartLayout = "<CreatePartition wcm:action='add'><Order>1</Order><Type>Primary</Type><Extend>true</Extend></CreatePartition><ModifyPartition wcm:action='add'><Order>1</Order><PartitionID>1</PartitionID><Label>Windows</Label><Letter>C</Letter><Format>NTFS</Format></ModifyPartition>"
            $Content = $Content -replace "%CREATEPARTITIONS%", $PartLayout
            $Content = $Content -replace "%INSTALLTO%", "<DiskID>0</DiskID><PartitionID>1</PartitionID>"
        } else {
            $Content = $Content -replace "%WIPEDISK%", "false"
            $Content = $Content -replace "%CREATEPARTITIONS%", ""
            # Partition 3 thường là vùng trống sau các phân vùng hệ thống
            $Content = $Content -replace "%INSTALLTO%", "<DiskID>0</DiskID><PartitionID>3</PartitionID>"
        }

        # 8. LƯU FILE
        $Content | Set-Content $XMLPath -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("DA TAO FILE XML THANH CONG!`n`nLuu tai: $XMLPath`n(Cac truong trong da duoc xoa bo de tranh loi)", "Phat Tan PC")
        $Form.Close()

    } catch { 
        [System.Windows.Forms.MessageBox]::Show("Loi tao XML: $($_.Exception.Message)", "Error") 
    }
})
$Form.Controls.Add($BtnSave)

$Form.ShowDialog() | Out-Null
