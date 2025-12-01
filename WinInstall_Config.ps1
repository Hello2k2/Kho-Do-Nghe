# --- INIT ---
try { Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing } catch { Exit }

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CAU HINH FILE (V40.0 OOBE DISM)"
$Form.Size = New-Object System.Drawing.Size(650, 500)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30); $Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false
$FontBold = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$FontNorm = New-Object System.Drawing.Font("Segoe UI", 10)

$Lbl = New-Object System.Windows.Forms.Label; $Lbl.Text = "THONG TIN TAI KHOAN (DISM MODE)"; $Lbl.Location = "20,20"; $Lbl.AutoSize=$true; $Lbl.Font=$FontBold; $Lbl.ForeColor="Cyan"; $Form.Controls.Add($Lbl)

function Add-Input ($T, $Y, $D) {
    $L=New-Object System.Windows.Forms.Label; $L.Text=$T; $L.Location="20,$Y"; $L.AutoSize=$true; $L.Font=$FontNorm; $Form.Controls.Add($L)
    $B=New-Object System.Windows.Forms.TextBox; $B.Text=$D; $B.Location="200,$Y"; $B.Size="400,25"; $B.Font=$FontNorm; $Form.Controls.Add($B); return $B
}

$TxtUser = Add-Input "Ten User:" 60 "Admin"
$TxtPass = Add-Input "Mat Khau:" 100 ""
$TxtPC   = Add-Input "Ten May:" 140 "PhatTan-PC"

# --- SETTINGS GROUP ---
$GBSet = New-Object System.Windows.Forms.GroupBox; $GBSet.Text = "TUY CHON"; $GBSet.Location = "20,190"; $GBSet.Size = "580,100"; $GBSet.ForeColor = "Lime"; $Form.Controls.Add($GBSet)
$CkSkipWifi = New-Object System.Windows.Forms.CheckBox; $CkSkipWifi.Text = "Skip Wifi (OOBE)"; $CkSkipWifi.Location = "20,30"; $CkSkipWifi.AutoSize=$true; $CkSkipWifi.ForeColor="White"; $CkSkipWifi.Checked=$true; $GBSet.Controls.Add($CkSkipWifi)
$CkAutoLogon = New-Object System.Windows.Forms.CheckBox; $CkAutoLogon.Text = "Auto Logon"; $CkAutoLogon.Location = "20,60"; $CkAutoLogon.AutoSize=$true; $CkAutoLogon.ForeColor="White"; $CkAutoLogon.Checked=$true; $GBSet.Controls.Add($CkAutoLogon)

$LblNote = New-Object System.Windows.Forms.Label; $LblNote.Text = "Luu y: File XML nay chi dung cho giai doan sau khi cai Win (OOBE).`nViec chia dia va copy file se do DISM Script trong Core dam nhiem."; $LblNote.Location = "20,310"; $LblNote.AutoSize=$true; $LblNote.ForeColor="Yellow"; $Form.Controls.Add($LblNote)

$BtnSave = New-Object System.Windows.Forms.Button; $BtnSave.Text = "TAO XML & LUU VAO TEMP"; $BtnSave.Location = "20,380"; $BtnSave.Size = "580,50"; $BtnSave.BackColor = "Cyan"; $BtnSave.ForeColor = "Black"; $BtnSave.Font=$FontBold

$BtnSave.Add_Click({
    $XMLPath = "$env:TEMP\unattend.xml" # Luu tam o Temp de Core copy sau

    $User = $TxtUser.Text; $Pass = $TxtPass.Text; $PCName = $TxtPC.Text
    $PassBlock = ""; if (![string]::IsNullOrEmpty($Pass)) { $PassBlock = "<Password><Value>$Pass</Value><PlainText>true</PlainText></Password>" }
    $AutoLogon = ""; if ($CkAutoLogon.Checked) { $AutoLogon = "<AutoLogon><Username>$User</Username>$PassBlock<Enabled>true</Enabled><LogonCount>1</LogonCount></AutoLogon>" }
    $SkipWifi = if ($CkSkipWifi.Checked) { "true" } else { "false" }
    
    # Function tao Component OOBE (Dung chung cho x86/amd64)
    function Gen-OOBE ($Arch) {
        return @"
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="$Arch" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <ComputerName>$PCName</ComputerName>
            <UserAccounts><LocalAccounts><LocalAccount wcm:action="add"><Name>$User</Name><DisplayName>$User</DisplayName><Group>Administrators</Group>$PassBlock</LocalAccount></LocalAccounts></UserAccounts>
            $AutoLogon
            <OOBE><ProtectYourPC>3</ProtectYourPC><HideEULAPage>true</HideEULAPage><HideWirelessSetupInOOBE>$SkipWifi</HideWirelessSetupInOOBE><HideOnlineAccountScreens>true</HideOnlineAccountScreens></OOBE>
        </component>
"@
    }

    $FinalXML = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"><ComputerName>$PCName</ComputerName></component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"><ComputerName>$PCName</ComputerName></component>
    </settings>
    <settings pass="oobeSystem">
        $(Gen-OOBE "amd64")
        $(Gen-OOBE "x86")
    </settings>
</unattend>
"@
    try {
        $Utf8Bom = New-Object System.Text.UTF8Encoding $true
        [IO.File]::WriteAllText($XMLPath, $FinalXML, $Utf8Bom)
        [System.Windows.Forms.MessageBox]::Show("DA TAO OOBE XML!`nHay chay file Core de bat dau tien trinh DISM.", "Success")
        $Form.Close()
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi: $($_.Exception.Message)", "Loi") }
})

$Form.Controls.Add($BtnSave)
$Form.ShowDialog() | Out-Null
