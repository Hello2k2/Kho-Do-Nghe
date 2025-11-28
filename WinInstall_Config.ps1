try { Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing } catch { Exit }
$XML_Url = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/autounattend.xml"

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CAU HINH FILE TU DONG (XML GENERATOR)"
$Form.Size = New-Object System.Drawing.Size(600, 550); $Form.StartPosition = "CenterScreen"; $Form.BackColor = "#2D2D30"; $Form.ForeColor = "White"

$FontBold = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)

$Lbl = New-Object System.Windows.Forms.Label; $Lbl.Text = "NHAP THONG TIN CHO WINDOWS MOI:"; $Lbl.Location = "20,20"; $Lbl.AutoSize=$true; $Lbl.Font=$FontBold; $Form.Controls.Add($Lbl)

function Add-Input ($T, $Y, $D) {
    $L=New-Object System.Windows.Forms.Label; $L.Text=$T; $L.Location="20,$Y"; $L.AutoSize=$true; $Form.Controls.Add($L)
    $B=New-Object System.Windows.Forms.TextBox; $B.Text=$D; $B.Location="200,$Y"; $B.Size="350,25"; $Form.Controls.Add($B); return $B
}

$TxtUser = Add-Input "User Account:" 60 "Admin"
$TxtPass = Add-Input "Password:" 100 ""
$TxtPC   = Add-Input "Computer Name:" 140 "PhatTan-PC"
$TxtKey  = Add-Input "Product Key:" 180 ""

$GB = New-Object System.Windows.Forms.GroupBox; $GB.Text = "CHIA O CUNG"; $GB.Location = "20,230"; $GB.Size = "530,100"; $GB.ForeColor = "Yellow"; $Form.Controls.Add($GB)
$RadWipe = New-Object System.Windows.Forms.RadioButton; $RadWipe.Text = "XOA SACH (Clean Install)"; $RadWipe.Location = "20,30"; $RadWipe.AutoSize=$true; $RadWipe.Checked=$true; $GB.Controls.Add($RadWipe)
$RadDual = New-Object System.Windows.Forms.RadioButton; $RadDual.Text = "DUAL BOOT (Giu Win Cu)"; $RadDual.Location = "20,60"; $RadDual.AutoSize=$true; $GB.Controls.Add($RadDual)

$BtnSave = New-Object System.Windows.Forms.Button; $BtnSave.Text = "LUU CAU HINH"; $BtnSave.Location = "20,400"; $BtnSave.Size = "530,50"; $BtnSave.BackColor = "Cyan"; $BtnSave.ForeColor = "Black"; $BtnSave.Font=$FontBold
$BtnSave.Add_Click({
    $XMLPath = "$env:SystemDrive\autounattend.xml"
    try {
        (New-Object Net.WebClient).DownloadFile($XML_Url, $XMLPath)
        $Content = Get-Content $XMLPath -Raw
        $Content = $Content -replace "%USERNAME%", $TxtUser.Text -replace "%PASSWORD%", $TxtPass.Text -replace "%COMPUTERNAME%", $TxtPC
        
        if ([string]::IsNullOrWhiteSpace($TxtKey.Text)) { $Content = $Content -replace "(?s)<ProductKey>.*?</ProductKey>", "" } 
        else { $Content = $Content -replace "%PRODUCTKEY%", $TxtKey.Text }

        if ($RadWipe.Checked) {
            $PartLayout = "<CreatePartition wcm:action='add'><Order>1</Order><Type>Primary</Type><Extend>true</Extend></CreatePartition><ModifyPartition wcm:action='add'><Order>1</Order><PartitionID>1</PartitionID><Label>Windows</Label><Letter>C</Letter><Format>NTFS</Format></ModifyPartition>"
            $Content = $Content -replace "%WIPEDISK%", "true" -replace "%CREATEPARTITIONS%", $PartLayout -replace "%INSTALLTO%", "<DiskID>0</DiskID><PartitionID>1</PartitionID>"
        } else {
            $Content = $Content -replace "%WIPEDISK%", "false" -replace "%CREATEPARTITIONS%", "" -replace "%INSTALLTO%", "<DiskID>0</DiskID><PartitionID>3</PartitionID>"
        }
        $Content | Set-Content $XMLPath
        [System.Windows.Forms.MessageBox]::Show("Da tao file XML thanh cong tai o C:\`nBjo co the dung chuc nang Boot Tam.", "OK")
        $Form.Close()
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi tai XML mau!", "Error") }
})
$Form.Controls.Add($BtnSave); $Form.ShowDialog() | Out-Null
