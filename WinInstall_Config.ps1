# --- INIT ---
try { Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing } catch { Exit }
$XML_Url = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/refs/heads/main/autounattend.xml"

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CAU HINH FILE (V22.0 DOM FIX)"
$Form.Size = New-Object System.Drawing.Size(650, 550)
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

# --- SETTINGS GROUP ---
$GBSet = New-Object System.Windows.Forms.GroupBox; $GBSet.Text = "CAI DAT HE THONG"; $GBSet.Location = "20,190"; $GBSet.Size = "580,150"; $GBSet.ForeColor = "Lime"; $Form.Controls.Add($GBSet)
$LblTZ = New-Object System.Windows.Forms.Label; $LblTZ.Text = "Mui Gio:"; $LblTZ.Location = "20,30"; $LblTZ.AutoSize=$true; $LblTZ.ForeColor="White"; $GBSet.Controls.Add($LblTZ)
$CmbTZ = New-Object System.Windows.Forms.ComboBox; $CmbTZ.Location = "100,27"; $CmbTZ.Size = "300,25"; $CmbTZ.DropDownStyle="DropDownList"; $GBSet.Controls.Add($CmbTZ)
$CmbTZ.Items.AddRange(@("SE Asia Standard Time", "Pacific Standard Time", "China Standard Time", "Tokyo Standard Time")); $CmbTZ.SelectedIndex = 0
$CkSkipWifi = New-Object System.Windows.Forms.CheckBox; $CkSkipWifi.Text = "Skip Wifi (OOBE)"; $CkSkipWifi.Location = "20,60"; $CkSkipWifi.AutoSize=$true; $CkSkipWifi.ForeColor="White"; $CkSkipWifi.Checked=$true; $GBSet.Controls.Add($CkSkipWifi)
$CkAutoLogon = New-Object System.Windows.Forms.CheckBox; $CkAutoLogon.Text = "Auto Logon"; $CkAutoLogon.Location = "20,90"; $CkAutoLogon.AutoSize=$true; $CkAutoLogon.ForeColor="White"; $CkAutoLogon.Checked=$true; $GBSet.Controls.Add($CkAutoLogon)
$CkDefender = New-Object System.Windows.Forms.CheckBox; $CkDefender.Text = "Tat Defender"; $CkDefender.Location = "300,60"; $CkDefender.AutoSize=$true; $CkDefender.ForeColor="Orange"; $GBSet.Controls.Add($CkDefender)
$CkUAC = New-Object System.Windows.Forms.CheckBox; $CkUAC.Text = "Tat UAC"; $CkUAC.Location = "300,90"; $CkUAC.AutoSize=$true; $CkUAC.ForeColor="Orange"; $GBSet.Controls.Add($CkUAC)

$GB = New-Object System.Windows.Forms.GroupBox; $GB.Text = "CHIA O CUNG"; $GB.Location = "20,360"; $GB.Size = "580,100"; $GB.ForeColor = "Yellow"; $Form.Controls.Add($GB)
$RadWipe = New-Object System.Windows.Forms.RadioButton; $RadWipe.Text = "XOA SACH (Clean Install)"; $RadWipe.Location = "20,30"; $RadWipe.AutoSize=$true; $RadWipe.ForeColor="White"; $RadWipe.Checked=$true; $GB.Controls.Add($RadWipe)
$RadDual = New-Object System.Windows.Forms.RadioButton; $RadDual.Text = "DUAL BOOT (Giu nguyen Partition)"; $RadDual.Location = "20,60"; $RadDual.AutoSize=$true; $RadDual.ForeColor="White"; $GB.Controls.Add($RadDual)

$BtnSave = New-Object System.Windows.Forms.Button; $BtnSave.Text = "TAI XML & LUU CAU HINH"; $BtnSave.Location = "20,480"; $BtnSave.Size = "580,50"; $BtnSave.BackColor = "Cyan"; $BtnSave.ForeColor = "Black"; $BtnSave.Font=$FontBold

$BtnSave.Add_Click({
    $XMLPath = "$env:SystemDrive\autounattend.xml"
    try {
        # 1. TAI FILE TU GITHUB
        [System.Net.ServicePointManager]::SecurityProtocol = 3072
        (New-Object Net.WebClient).DownloadFile($XML_Url, $XMLPath)
        
        # 2. LOAD XML DOM (QUAN TRONG)
        $xml = [xml](Get-Content $XMLPath)
        $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
        $ns.AddNamespace("u", "urn:schemas-microsoft-com:unattend")
        $ns.AddNamespace("wcm", "http://schemas.microsoft.com/WMIConfig/2002/State")

        # 3. FILL THONG TIN (Tim & Thay the tren toan bo file)
        # Thay the thong tin user (Dung Replace string don gian cho cac placeholder)
        # Nhung xu ly cac node cau truc bang DOM
        $xml.OuterXml.Replace("%USERNAME%", $TxtUser.Text).Replace("%COMPUTERNAME%", $TxtPC.Text).Replace("SE Asia Standard Time", $CmbTZ.SelectedItem) | Set-Content $XMLPath
        
        # Reload lai XML sau khi replace string co ban
        $xml = [xml](Get-Content $XMLPath)

        # 4. LOGIC DISK (DOM SAFE)
        # Tim tat ca cac node <Disk> trong file (co the co nhieu do x86/amd64)
        $Disks = $xml.GetElementsByTagName("Disk")
        
        foreach ($Disk in $Disks) {
            # Tim node WillWipeDisk
            $WipeNode = $Disk.SelectSingleNode("*[local-name()='WillWipeDisk']")
            if ($WipeNode) { 
                if ($RadWipe.Checked) { $WipeNode.InnerText = "true" } else { $WipeNode.InnerText = "false" }
            }

            # Xu ly CreatePartitions
            $CPNode = $Disk.SelectSingleNode("*[local-name()='CreatePartitions']")
            if ($CPNode) {
                if ($RadWipe.Checked) {
                    # Tao moi noi dung CreatePartition
                    $CPNode.InnerXml = "<CreatePartition wcm:action='add'><Order>1</Order><Type>Primary</Type><Extend>true</Extend></CreatePartition>"
                } else {
                    # XOA HAN NODE CreatePartitions (Tranh loi tag rong)
                    [void]$Disk.RemoveChild($CPNode)
                }
            }
        }

        # 5. XOA KEY MAC DINH (DOM)
        $Keys = $xml.GetElementsByTagName("ProductKey")
        foreach ($K in $Keys) { [void]$K.ParentNode.RemoveChild($K) }

        # 6. LOGIC PASSWORD
        if ([string]::IsNullOrWhiteSpace($TxtPass.Text)) {
            $Pwds = $xml.GetElementsByTagName("Password")
            foreach ($P in $Pwds) { [void]$P.ParentNode.RemoveChild($P) }
        } else {
            # Da co san trong file mau voi %PASSWORD%, replace o buoc string roi
            $xml.OuterXml.Replace("%PASSWORD%", $TxtPass.Text) | Set-Content $XMLPath
            $xml = [xml](Get-Content $XMLPath) # Reload
        }

        # 7. SKIP WIFI & AUTO LOGON
        if ($CkSkipWifi.Checked) {
            $HideWifi = $xml.GetElementsByTagName("HideWirelessSetupInOOBE")
            foreach ($H in $HideWifi) { $H.InnerText = "true" }
        }
        if ($CkAutoLogon.Checked) {
            $Enables = $xml.GetElementsByTagName("Enabled")
            # Can than chon dung Enabled cua AutoLogon
            foreach ($E in $Enables) { if ($E.ParentNode.Name -eq "AutoLogon") { $E.InnerText = "true" } }
        } else {
            $ALs = $xml.GetElementsByTagName("AutoLogon")
            foreach ($A in $ALs) { [void]$A.ParentNode.RemoveChild($A) }
        }

        # 8. SAVE (UTF8 BOM)
        $xml.Save($XMLPath)
        
        [System.Windows.Forms.MessageBox]::Show("DA CAU HINH XML BANG DOM (SAFE)!`nFile luu tai: $XMLPath", "Success")
        $Form.Close()

    } catch { [System.Windows.Forms.MessageBox]::Show("Loi Config: $($_.Exception.Message)", "Error") }
})

$Form.Controls.Add($BtnSave)
$Form.ShowDialog() | Out-Null
