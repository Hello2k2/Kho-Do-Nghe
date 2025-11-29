# --- INIT ---
try { Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing } catch { Exit }
$XML_Url = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/autounattend.xml"

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CAU HINH FILE TU DONG (V5.1 UTF8-NOBOM)"
$Form.Size = New-Object System.Drawing.Size(650, 750)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30); $Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false
$FontBold = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$FontNorm = New-Object System.Drawing.Font("Segoe UI", 10)

$Lbl = New-Object System.Windows.Forms.Label; $Lbl.Text = "THONG TIN TAI KHOAN & HE THONG"; $Lbl.Location = "20,20"; $Lbl.AutoSize=$true; $Lbl.Font=$FontBold; $Lbl.ForeColor="Cyan"; $Form.Controls.Add($Lbl)

function Add-Input ($T, $Y, $D) {
    $L=New-Object System.Windows.Forms.Label; $L.Text=$T; $L.Location="20,$Y"; $L.AutoSize=$true; $L.Font=$FontNorm; $Form.Controls.Add($L)
    $B=New-Object System.Windows.Forms.TextBox; $B.Text=$D; $B.Location="200,$Y"; $B.Size="400,25"; $B.Font=$FontNorm; $Form.Controls.Add($B); return $B
}

$TxtUser = Add-Input "Ten User:" 60 "Admin"
$TxtPass = Add-Input "Mat Khau:" 100 ""
$TxtPC   = Add-Input "Ten May:" 140 "PhatTan-PC"
$TxtKey  = Add-Input "Product Key:" 180 ""
$LblHint = New-Object System.Windows.Forms.Label; $LblHint.Text = "(De trong Key se tu dong xoa de tranh loi)"; $LblHint.Location = "200,210"; $LblHint.AutoSize=$true; $LblHint.ForeColor="Gray"; $Form.Controls.Add($LblHint)

$GBSet = New-Object System.Windows.Forms.GroupBox; $GBSet.Text = "CAI DAT HE THONG"; $GBSet.Location = "20,240"; $GBSet.Size = "580,150"; $GBSet.ForeColor = "Lime"; $Form.Controls.Add($GBSet)
$LblTZ = New-Object System.Windows.Forms.Label; $LblTZ.Text = "Mui Gio:"; $LblTZ.Location = "20,30"; $LblTZ.AutoSize=$true; $LblTZ.ForeColor="White"; $GBSet.Controls.Add($LblTZ)
$CmbTZ = New-Object System.Windows.Forms.ComboBox; $CmbTZ.Location = "100,27"; $CmbTZ.Size = "300,25"; $CmbTZ.DropDownStyle="DropDownList"; $GBSet.Controls.Add($CmbTZ)
$CmbTZ.Items.AddRange(@("SE Asia Standard Time", "Pacific Standard Time", "China Standard Time", "Tokyo Standard Time")); $CmbTZ.SelectedIndex = 0
$CkSkipWifi = New-Object System.Windows.Forms.CheckBox; $CkSkipWifi.Text = "Skip Wifi (OOBE)"; $CkSkipWifi.Location = "20,60"; $CkSkipWifi.AutoSize=$true; $CkSkipWifi.ForeColor="White"; $CkSkipWifi.Checked=$true; $GBSet.Controls.Add($CkSkipWifi)
$CkAutoLogon = New-Object System.Windows.Forms.CheckBox; $CkAutoLogon.Text = "Auto Logon"; $CkAutoLogon.Location = "20,90"; $CkAutoLogon.AutoSize=$true; $CkAutoLogon.ForeColor="White"; $CkAutoLogon.Checked=$true; $GBSet.Controls.Add($CkAutoLogon)
$CkDefender = New-Object System.Windows.Forms.CheckBox; $CkDefender.Text = "Tat Defender"; $CkDefender.Location = "300,60"; $CkDefender.AutoSize=$true; $CkDefender.ForeColor="Orange"; $GBSet.Controls.Add($CkDefender)
$CkUAC = New-Object System.Windows.Forms.CheckBox; $CkUAC.Text = "Tat UAC"; $CkUAC.Location = "300,90"; $CkUAC.AutoSize=$true; $CkUAC.ForeColor="Orange"; $GBSet.Controls.Add($CkUAC)

$GB = New-Object System.Windows.Forms.GroupBox; $GB.Text = "CHIA O CUNG"; $GB.Location = "20,410"; $GB.Size = "580,100"; $GB.ForeColor = "Yellow"; $Form.Controls.Add($GB)
$RadWipe = New-Object System.Windows.Forms.RadioButton; $RadWipe.Text = "XOA SACH (Clean Install)"; $RadWipe.Location = "20,30"; $RadWipe.AutoSize=$true; $RadWipe.ForeColor="White"; $RadWipe.Checked=$true; $GB.Controls.Add($RadWipe)
$RadDual = New-Object System.Windows.Forms.RadioButton; $RadDual.Text = "DUAL BOOT"; $RadDual.Location = "20,60"; $RadDual.AutoSize=$true; $RadDual.ForeColor="White"; $GB.Controls.Add($RadDual)

$BtnSave = New-Object System.Windows.Forms.Button; $BtnSave.Text = "TAO FILE XML"; $BtnSave.Location = "20,530"; $BtnSave.Size = "580,50"; $BtnSave.BackColor = "Cyan"; $BtnSave.ForeColor = "Black"; $BtnSave.Font=$FontBold

$BtnSave.Add_Click({
    $XMLPath = "$env:SystemDrive\autounattend.xml"
    try {
        (New-Object Net.WebClient).DownloadFile($XML_Url, $XMLPath)
        
        # Đọc file (Lưu ý: Đọc dưới dạng String để xử lý Regex)
        $Content = [IO.File]::ReadAllText($XMLPath)
        
        # 1. Replace Info
        $Content = $Content.Replace("%USERNAME%", $TxtUser.Text)
        $Content = $Content.Replace("%COMPUTERNAME%", $TxtPC.Text)
        $Content = $Content.Replace("SE Asia Standard Time", $CmbTZ.SelectedItem)
        
        # 2. Replace Password
        if ([string]::IsNullOrWhiteSpace($TxtPass.Text)) {
            # Xóa thẻ Password và Value rỗng
            $Content = $Content -replace "(?s)<Password>.*?</Password>", ""
            $Content = $Content.Replace("%PASSWORD%", "")
        } else {
            $Content = $Content.Replace("%PASSWORD%", $TxtPass.Text)
        }

        # 3. FIX KEY (QUAN TRỌNG NHẤT)
        if ([string]::IsNullOrWhiteSpace($TxtKey.Text)) {
            # Xóa sạch khối ProductKey
            # (?s) = Singleline mode (match newlines)
            # \s* = Match whitespace before/after
            $Content = $Content -replace "(?s)\s*<ProductKey>.*?</ProductKey>", ""
            
            # Xóa luôn thẻ Key lẻ nếu còn sót
            $Content = $Content.Replace("<Key>%PRODUCTKEY%</Key>", "")
            $Content = $Content.Replace("<Key></Key>", "")
        } else {
            $Content = $Content.Replace("%PRODUCTKEY%", $TxtKey.Text)
        }

        # 4. Partition
        if ($RadWipe.Checked) {
            $Content = $Content.Replace("%WIPEDISK%", "true")
            $PartLayout = "<CreatePartition wcm:action='add'><Order>1</Order><Type>Primary</Type><Extend>true</Extend></CreatePartition><ModifyPartition wcm:action='add'><Order>1</Order><PartitionID>1</PartitionID><Label>Windows</Label><Letter>C</Letter><Format>NTFS</Format></ModifyPartition>"
            $Content = $Content.Replace("%CREATEPARTITIONS%", $PartLayout)
            $Content = $Content.Replace("%INSTALLTO%", "<DiskID>0</DiskID><PartitionID>1</PartitionID>")
        } else {
            $Content = $Content.Replace("%WIPEDISK%", "false")
            $Content = $Content.Replace("%CREATEPARTITIONS%", "")
            $Content = $Content.Replace("%INSTALLTO%", "<DiskID>0</DiskID><PartitionID>3</PartitionID>")
        }
        
        # 5. Settings
        if ($CkSkipWifi.Checked) { 
            $Content = $Content.Replace("<HideWirelessSetupInOOBE>false</HideWirelessSetupInOOBE>", "<HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>") 
        }
        if ($CkAutoLogon.Checked) { 
            $Content = $Content.Replace("<Enabled>false</Enabled>", "<Enabled>true</Enabled>") 
        } else {
            $Content = $Content -replace "(?s)\s*<AutoLogon>.*?</AutoLogon>", ""
        }

        # 6. LƯU FILE CHUẨN UTF-8 NO BOM (QUAN TRỌNG ĐỂ WINDOWS ĐỌC ĐƯỢC)
        $Utf8NoBom = New-Object System.Text.UTF8Encoding($false) # $false = No BOM
        [IO.File]::WriteAllText($XMLPath, $Content, $Utf8NoBom)
        
        [System.Windows.Forms.MessageBox]::Show("DA TAO XML (UTF8-NO-BOM)!`nKiem tra file tai: $XMLPath", "Phat Tan PC")
        $Form.Close()

    } catch { [System.Windows.Forms.MessageBox]::Show("Loi tao XML: $($_.Exception.Message)", "Error") }
})

$Form.Controls.Add($BtnSave)
$Form.ShowDialog() | Out-Null
