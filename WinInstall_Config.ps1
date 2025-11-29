# --- INIT ---
try { Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing } catch { Exit }
$XML_Url = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/autounattend.xml"

# --- DATABASE KEY (GENERIC INSTALLATION KEYS) ---
$KeyDB = @{
    "Windows 10/11" = @{
        "Pro"          = "VK7JG-NPHTM-C97JM-9MPGT-3V66T"
        "Home"         = "YTMG3-N6DKC-DKB77-7M9GH-8HVX7"
        "Enterprise"   = "XGVPP-NMH47-7TTHJ-W3FW7-8HV2C"
        "Education"    = "6TP4R-GNPTD-KYYHQ-7B7DP-J447Y"
    }
    "Windows 8.1" = @{
        "Pro"          = "GCRJD-8NW9H-F2CDX-CCM8D-9D6T9"
        "Core (Home)"  = "334NH-RXG76-64THK-C7CKG-D3VPT"
        "Enterprise"   = "MHF9N-XY6XB-WVXMC-BTDCT-MKKG7"
    }
    "Windows 7" = @{
        "Ultimate"     = "D4F6K-QK3RD-TMVMJ-BBMRX-3MBMV"
        "Professional" = "FJ82H-XT6CR-J8D7P-XQJJ2-GPDD4"
        "Home Premium" = "VQB3X-Q3KP8-WJ2H8-R6B6D-7QJB7"
        "Home Basic"   = "22MFQ-HDH7V-RBV79-QMVK9-PTMXQ"
        "Enterprise"   = "33PXH-7Y6KF-2VJC9-XBBR8-HVTHH"
    }
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CAU HINH FILE TU DONG - PHAT TAN PC (V7.0 SMART KEY)"
$Form.Size = New-Object System.Drawing.Size(650, 780)
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

# --- SELECT WINDOWS VERSION (NEW) ---
$LblVer = New-Object System.Windows.Forms.Label; $LblVer.Text = "Chon Phien Ban:"; $LblVer.Location = "20,180"; $LblVer.AutoSize=$true; $LblVer.Font=$FontNorm; $Form.Controls.Add($LblVer)
$CmbVer = New-Object System.Windows.Forms.ComboBox; $CmbVer.Location = "200,177"; $CmbVer.Size = "190,25"; $CmbVer.DropDownStyle="DropDownList"; $Form.Controls.Add($CmbVer)

$LblEd = New-Object System.Windows.Forms.Label; $LblEd.Text = "Edition:"; $LblEd.Location = "400,180"; $LblEd.AutoSize=$true; $LblEd.Font=$FontNorm; $Form.Controls.Add($LblEd)
$CmbEd = New-Object System.Windows.Forms.ComboBox; $CmbEd.Location = "460,177"; $CmbEd.Size = "140,25"; $CmbEd.DropDownStyle="DropDownList"; $Form.Controls.Add($CmbEd)

# --- PRODUCT KEY INPUT ---
$TxtKey = Add-Input "Product Key (Auto):" 220 ""
$LblHint = New-Object System.Windows.Forms.Label; $LblHint.Text = "(Key se tu dong dien khi ban chon Phien ban)"; $LblHint.Location = "200,250"; $LblHint.AutoSize=$true; $LblHint.ForeColor="Lime"; $Form.Controls.Add($LblHint)

# --- LOGIC AUTO KEY ---
# 1. Load Versions
foreach ($Ver in $KeyDB.Keys) { $CmbVer.Items.Add($Ver) }

# 2. Event Change Version -> Load Editions
$CmbVer.Add_SelectedIndexChanged({
    $SelVer = $CmbVer.SelectedItem
    $CmbEd.Items.Clear()
    if ($SelVer) {
        foreach ($Ed in $KeyDB[$SelVer].Keys) { $CmbEd.Items.Add($Ed) }
        $CmbEd.SelectedIndex = 0 # Auto select first
    }
})

# 3. Event Change Edition -> Fill Key
$CmbEd.Add_SelectedIndexChanged({
    $SelVer = $CmbVer.SelectedItem
    $SelEd = $CmbEd.SelectedItem
    if ($SelVer -and $SelEd) {
        $TxtKey.Text = $KeyDB[$SelVer][$SelEd]
    }
})

# Set Default
$CmbVer.SelectedItem = "Windows 10/11" 

# --- SETTINGS GROUP ---
$GBSet = New-Object System.Windows.Forms.GroupBox; $GBSet.Text = "CAI DAT HE THONG"; $GBSet.Location = "20,280"; $GBSet.Size = "580,150"; $GBSet.ForeColor = "Lime"; $Form.Controls.Add($GBSet)
$LblTZ = New-Object System.Windows.Forms.Label; $LblTZ.Text = "Mui Gio:"; $LblTZ.Location = "20,30"; $LblTZ.AutoSize=$true; $LblTZ.ForeColor="White"; $GBSet.Controls.Add($LblTZ)
$CmbTZ = New-Object System.Windows.Forms.ComboBox; $CmbTZ.Location = "100,27"; $CmbTZ.Size = "300,25"; $CmbTZ.DropDownStyle="DropDownList"; $GBSet.Controls.Add($CmbTZ)
$CmbTZ.Items.AddRange(@("SE Asia Standard Time", "Pacific Standard Time", "China Standard Time", "Tokyo Standard Time")); $CmbTZ.SelectedIndex = 0
$CkSkipWifi = New-Object System.Windows.Forms.CheckBox; $CkSkipWifi.Text = "Skip Wifi (OOBE)"; $CkSkipWifi.Location = "20,60"; $CkSkipWifi.AutoSize=$true; $CkSkipWifi.ForeColor="White"; $CkSkipWifi.Checked=$true; $GBSet.Controls.Add($CkSkipWifi)
$CkAutoLogon = New-Object System.Windows.Forms.CheckBox; $CkAutoLogon.Text = "Auto Logon"; $CkAutoLogon.Location = "20,90"; $CkAutoLogon.AutoSize=$true; $CkAutoLogon.ForeColor="White"; $CkAutoLogon.Checked=$true; $GBSet.Controls.Add($CkAutoLogon)
$CkDefender = New-Object System.Windows.Forms.CheckBox; $CkDefender.Text = "Tat Defender"; $CkDefender.Location = "300,60"; $CkDefender.AutoSize=$true; $CkDefender.ForeColor="Orange"; $GBSet.Controls.Add($CkDefender)
$CkUAC = New-Object System.Windows.Forms.CheckBox; $CkUAC.Text = "Tat UAC"; $CkUAC.Location = "300,90"; $CkUAC.AutoSize=$true; $CkUAC.ForeColor="Orange"; $GBSet.Controls.Add($CkUAC)

$GB = New-Object System.Windows.Forms.GroupBox; $GB.Text = "CHIA O CUNG"; $GB.Location = "20,450"; $GB.Size = "580,100"; $GB.ForeColor = "Yellow"; $Form.Controls.Add($GB)
$RadWipe = New-Object System.Windows.Forms.RadioButton; $RadWipe.Text = "XOA SACH (Clean Install)"; $RadWipe.Location = "20,30"; $RadWipe.AutoSize=$true; $RadWipe.ForeColor="White"; $RadWipe.Checked=$true; $GB.Controls.Add($RadWipe)
$RadDual = New-Object System.Windows.Forms.RadioButton; $RadDual.Text = "DUAL BOOT"; $RadDual.Location = "20,60"; $RadDual.AutoSize=$true; $RadDual.ForeColor="White"; $GB.Controls.Add($RadDual)

$BtnSave = New-Object System.Windows.Forms.Button; $BtnSave.Text = "TAO FILE XML"; $BtnSave.Location = "20,560"; $BtnSave.Size = "580,50"; $BtnSave.BackColor = "Cyan"; $BtnSave.ForeColor = "Black"; $BtnSave.Font=$FontBold

$BtnSave.Add_Click({
    $XMLPath = "$env:SystemDrive\autounattend.xml"
    try {
        (New-Object Net.WebClient).DownloadFile($XML_Url, $XMLPath)
        $Content = [IO.File]::ReadAllText($XMLPath)
        
        $Content = $Content.Replace("%USERNAME%", $TxtUser.Text)
        $Content = $Content.Replace("%COMPUTERNAME%", $TxtPC.Text)
        $Content = $Content.Replace("SE Asia Standard Time", $CmbTZ.SelectedItem)
        
        if ([string]::IsNullOrWhiteSpace($TxtPass.Text)) {
            $Content = $Content -replace "(?s)<Password>.*?<Value>%PASSWORD%</Value>.*?</Password>", ""
            $Content = $Content.Replace("%PASSWORD%", "")
        } else { $Content = $Content.Replace("%PASSWORD%", $TxtPass.Text) }

        # LOGIC KEY (Luôn điền Key nếu có, nếu trống xóa sạch)
        if ([string]::IsNullOrWhiteSpace($TxtKey.Text)) {
            $Content = $Content -replace "(?s)\s*<ProductKey>.*?</ProductKey>", ""
            $Content = $Content -replace "\s*<Key>%PRODUCTKEY%</Key>", ""
        } else {
            $Content = $Content.Replace("%PRODUCTKEY%", $TxtKey.Text)
        }

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
        
        if ($CkSkipWifi.Checked) { $Content = $Content.Replace("<HideWirelessSetupInOOBE>false</HideWirelessSetupInOOBE>", "<HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>") }
        if ($CkAutoLogon.Checked) { $Content = $Content.Replace("<Enabled>false</Enabled>", "<Enabled>true</Enabled>") } 
        else { $Content = $Content -replace "(?s)\s*<AutoLogon>.*?</AutoLogon>", "" }

        [IO.File]::WriteAllText($XMLPath, $Content)
        [System.Windows.Forms.MessageBox]::Show("DA TAO XML (V7.0 SMART KEY)!`nLuu tai: $XMLPath", "Phat Tan PC")
        $Form.Close()

    } catch { [System.Windows.Forms.MessageBox]::Show("Loi tao XML: $($_.Exception.Message)", "Error") }
})

$Form.Controls.Add($BtnSave)
$Form.ShowDialog() | Out-Null
