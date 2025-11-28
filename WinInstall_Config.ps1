# --- INIT ---
try { Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing } catch { Exit }
$XML_Url = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/autounattend.xml"

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CAU HINH FILE TU DONG - PHAT TAN PC (V3.0 XML DOM)"
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

$LblHint = New-Object System.Windows.Forms.Label; $LblHint.Text = "(Bo trong Key se tu dong xoa the Key de tranh loi)"; $LblHint.Location = "200,210"; $LblHint.AutoSize=$true; $LblHint.ForeColor="Gray"; $Form.Controls.Add($LblHint)

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
        
        # Đọc nội dung thô để replace biến đơn giản trước
        $Content = Get-Content $XMLPath -Raw
        $Content = $Content -replace "%USERNAME%", $TxtUser.Text
        $Content = $Content -replace "%PASSWORD%", $TxtPass.Text
        $Content = $Content -replace "%COMPUTERNAME%", $TxtPC.Text
        $Content = $Content -replace "SE Asia Standard Time", $CmbTZ.SelectedItem
        
        # Xử lý Partition (Vẫn dùng String Replace vì đoạn này là block lớn)
        if ($RadWipe.Checked) {
            $PartLayout = "<CreatePartition wcm:action='add'><Order>1</Order><Type>Primary</Type><Extend>true</Extend></CreatePartition><ModifyPartition wcm:action='add'><Order>1</Order><PartitionID>1</PartitionID><Label>Windows</Label><Letter>C</Letter><Format>NTFS</Format></ModifyPartition>"
            $Content = $Content -replace "%WIPEDISK%", "true" -replace "%CREATEPARTITIONS%", $PartLayout -replace "%INSTALLTO%", "<DiskID>0</DiskID><PartitionID>1</PartitionID>"
        } else {
            $Content = $Content -replace "%WIPEDISK%", "false" -replace "%CREATEPARTITIONS%", "" -replace "%INSTALLTO%", "<DiskID>0</DiskID><PartitionID>3</PartitionID>"
        }
        
        # Lưu tạm để load vào XML Object
        $Content | Set-Content $XMLPath -Encoding UTF8
        
        # --- XỬ LÝ NÂNG CAO BẰNG XML DOM (FIX LỖI KEY/PASS) ---
        $XmlDoc = New-Object System.Xml.XmlDocument
        $XmlDoc.Load($XMLPath)
        $NS = New-Object System.Xml.XmlNamespaceManager($XmlDoc.NameTable)
        $NS.AddNamespace("u", "urn:schemas-microsoft-com:unattend")
        $NS.AddNamespace("wcm", "http://schemas.microsoft.com/WMIConfig/2002/State")

        # 1. XỬ LÝ KEY (QUAN TRỌNG)
        if ([string]::IsNullOrWhiteSpace($TxtKey.Text)) {
            # Tìm node UserData
            $UserData = $XmlDoc.SelectSingleNode("//u:UserData", $NS)
            if ($UserData) {
                # Tìm node ProductKey bên trong UserData
                $PKeyNode = $UserData.SelectSingleNode("u:ProductKey", $NS)
                if ($PKeyNode) { 
                    # Xóa sạch node ProductKey
                    $UserData.RemoveChild($PKeyNode) | Out-Null 
                }
            }
        } else {
            # Nếu có key, điền vào
            $KeyNode = $XmlDoc.SelectSingleNode("//u:ProductKey/u:Key", $NS)
            if ($KeyNode) { $KeyNode.InnerText = $TxtKey.Text }
        }

        # 2. XỬ LÝ PASSWORD RỖNG (Để tránh lỗi OOBE)
        if ([string]::IsNullOrWhiteSpace($TxtPass.Text)) {
            # Tìm tất cả thẻ Password
            $PassNodes = $XmlDoc.SelectNodes("//u:Password", $NS)
            foreach ($Node in $PassNodes) {
                $Parent = $Node.ParentNode
                $Parent.RemoveChild($Node) | Out-Null
            }
        }

        # 3. LƯU LẠI FILE XML CHUẨN
        $XmlDoc.Save($XMLPath)
        
        [System.Windows.Forms.MessageBox]::Show("DA TAO XML CHUAN! (Da fix loi Key/Pass)", "Phat Tan PC")
        $Form.Close()

    } catch { [System.Windows.Forms.MessageBox]::Show("Loi: $($_.Exception.Message)", "Error") }
})
$Form.Controls.Add($BtnSave)

$Form.ShowDialog() | Out-Null
