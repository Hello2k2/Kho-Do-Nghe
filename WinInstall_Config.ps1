<#
    TOOL CAU HINH WINDOWS - PHAT TAN PC
    Version: 41.0 (OOBE + App Installer + Custom Save)
#>

try { Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing } catch { Exit }

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CAU HINH FILE V41.0 (APP & SAVE SELECT)"
$Form.Size = "650,650" # Tang size de chua them app
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30); $Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false
$FontBold = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$FontNorm = New-Object System.Drawing.Font("Segoe UI", 10)

$Lbl = New-Object System.Windows.Forms.Label; $Lbl.Text = "THONG TIN TAI KHOAN & UNATTEND"; $Lbl.Location = "20,20"; $Lbl.AutoSize=$true; $Lbl.Font=$FontBold; $Lbl.ForeColor="Cyan"; $Form.Controls.Add($Lbl)

function Add-Input ($T, $Y, $D) {
    $L=New-Object System.Windows.Forms.Label; $L.Text=$T; $L.Location="20,$Y"; $L.AutoSize=$true; $L.Font=$FontNorm; $Form.Controls.Add($L)
    $B=New-Object System.Windows.Forms.TextBox; $B.Text=$D; $B.Location="200,$Y"; $B.Size="400,25"; $B.Font=$FontNorm; $Form.Controls.Add($B); return $B
}

$TxtUser = Add-Input "Ten User:" 60 "Admin"
$TxtPass = Add-Input "Mat Khau:" 100 ""
$TxtPC   = Add-Input "Ten May:" 140 "PhatTan-PC"

# --- 1. CHON NOI LUU FILE ---
$LblPath = New-Object System.Windows.Forms.Label; $LblPath.Text = "Noi luu file:"; $LblPath.Location = "20,180"; $LblPath.AutoSize=$true; $Form.Controls.Add($LblPath)
$TxtPath = New-Object System.Windows.Forms.TextBox; $TxtPath.Text = "D:\autounattend.xml"; $TxtPath.Location = "200,180"; $TxtPath.Size = "320,25"; $Form.Controls.Add($TxtPath)
$BtnBrowse = New-Object System.Windows.Forms.Button; $BtnBrowse.Text = "..."; $BtnBrowse.Location = "530,178"; $BtnBrowse.Size = "70,28"; $BtnBrowse.BackColor = "Gray"
$BtnBrowse.Add_Click({
    $SaveFile = New-Object System.Windows.Forms.SaveFileDialog
    $SaveFile.Filter = "XML Files (*.xml)|*.xml"
    $SaveFile.FileName = "autounattend.xml"
    if ($SaveFile.ShowDialog() -eq "OK") { $TxtPath.Text = $SaveFile.FileName }
})
$Form.Controls.Add($BtnBrowse)

# --- 2. TUY CHON APPS (WINGET) ---
$GBApps = New-Object System.Windows.Forms.GroupBox; $GBApps.Text = "CAI THEM UNG DUNG (AUTO)"; $GBApps.Location = "20,230"; $GBApps.Size = "580,100"; $GBApps.ForeColor = "Cyan"; $Form.Controls.Add($GBApps)
$CkChrome = New-Object System.Windows.Forms.CheckBox; $CkChrome.Text = "Google Chrome"; $CkChrome.Location = "20,35"; $CkChrome.AutoSize=$true; $CkChrome.Checked=$true; $GBApps.Controls.Add($CkChrome)
$CkUltra = New-Object System.Windows.Forms.CheckBox; $CkUltra.Text = "UltraViewer"; $CkUltra.Location = "200,35"; $CkUltra.AutoSize=$true; $CkUltra.Checked=$true; $GBApps.Controls.Add($CkUltra)
$CkUnikey = New-Object System.Windows.Forms.CheckBox; $CkUnikey.Text = "Unikey (Winget)"; $CkUnikey.Location = "380,35"; $CkUnikey.AutoSize=$true; $GBApps.Controls.Add($CkUnikey)

# --- 3. SETTINGS KHAC ---
$GBSet = New-Object System.Windows.Forms.GroupBox; $GBSet.Text = "SETTINGS OOBE"; $GBSet.Location = "20,340"; $GBSet.Size = "580,80"; $GBSet.ForeColor = "Lime"; $Form.Controls.Add($GBSet)
$CkSkipWifi = New-Object System.Windows.Forms.CheckBox; $CkSkipWifi.Text = "Skip Wifi"; $CkSkipWifi.Location = "20,30"; $CkSkipWifi.Checked=$true; $GBSet.Controls.Add($CkSkipWifi)
$CkAutoLogon = New-Object System.Windows.Forms.CheckBox; $CkAutoLogon.Text = "Auto Logon"; $CkAutoLogon.Location = "150,30"; $CkAutoLogon.Checked=$true; $GBSet.Controls.Add($CkAutoLogon)

$BtnSave = New-Object System.Windows.Forms.Button; $BtnSave.Text = "XUAT FILE AUTO UNATTEND XML"; $BtnSave.Location = "20,450"; $BtnSave.Size = "580,60"; $BtnSave.BackColor = "Cyan"; $BtnSave.ForeColor = "Black"; $BtnSave.Font=$FontBold

$BtnSave.Add_Click({
    $DestPath = $TxtPath.Text
    $User = $TxtUser.Text; $Pass = $TxtPass.Text; $PCName = $TxtPC.Text
    $PassBlock = ""; if (![string]::IsNullOrEmpty($Pass)) { $PassBlock = "<Password><Value>$Pass</Value><PlainText>true</PlainText></Password>" }
    $AutoLogon = ""; if ($CkAutoLogon.Checked) { $AutoLogon = "<AutoLogon><Username>$User</Username>$PassBlock<Enabled>true</Enabled><LogonCount>1</LogonCount></AutoLogon>" }
    $SkipWifi = if ($CkSkipWifi.Checked) { "true" } else { "false" }

    # Xy ly phan lenh cai App
    $AppCommands = ""
    $CmdIndex = 1
    if ($CkChrome.Checked) { $AppCommands += "<SynchronousCommand wcm:action=`"add`"><CommandLine>powershell -Command `"winget install Google.Chrome --silent --accept-package-agreements`"</CommandLine><Description>Install Chrome</Description><Order>$CmdIndex</Order></SynchronousCommand>"; $CmdIndex++ }
    if ($CkUltra.Checked) { $AppCommands += "<SynchronousCommand wcm:action=`"add`"><CommandLine>powershell -Command `"winget install UltraViewer.UltraViewer --silent --accept-package-agreements`"</CommandLine><Description>Install UltraViewer</Description><Order>$CmdIndex</Order></SynchronousCommand>"; $CmdIndex++ }
    if ($CkUnikey.Checked) { $AppCommands += "<SynchronousCommand wcm:action=`"add`"><CommandLine>powershell -Command `"winget install PhamKimLong.UniKey --silent --accept-package-agreements`"</CommandLine><Description>Install Unikey</Description><Order>$CmdIndex</Order></SynchronousCommand>"; $CmdIndex++ }

    $FirstLogon = ""
    if (![string]::IsNullOrEmpty($AppCommands)) { $FirstLogon = "<FirstLogonCommands>$AppCommands</FirstLogonCommands>" }

    function Gen-OOBE ($Arch) {
        return @"
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="$Arch" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <ComputerName>$PCName</ComputerName>
            <UserAccounts><LocalAccounts><LocalAccount wcm:action="add"><Name>$User</Name><DisplayName>$User</DisplayName><Group>Administrators</Group>$PassBlock</LocalAccount></LocalAccounts></UserAccounts>
            $AutoLogon
            <OOBE><ProtectYourPC>3</ProtectYourPC><HideEULAPage>true</HideEULAPage><HideWirelessSetupInOOBE>$SkipWifi</HideWirelessSetupInOOBE><HideOnlineAccountScreens>true</HideOnlineAccountScreens></OOBE>
            $FirstLogon
        </component>
"@
    }

    $FinalXML = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"><ComputerName>$PCName</ComputerName></component>
    </settings>
    <settings pass="oobeSystem">
        $(Gen-OOBE "amd64")
        $(Gen-OOBE "x86")
    </settings>
</unattend>
"@
    try {
        $Utf8Bom = New-Object System.Text.UTF8Encoding $true
        [IO.File]::WriteAllText($DestPath, $FinalXML, $Utf8Bom)
        [System.Windows.Forms.MessageBox]::Show("DA TAO FILE TAI: $DestPath`nHay dung DISM de copy file nay vao Windows/Panther.", "Success")
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi: $($_.Exception.Message)", "Loi") }
})

$Form.Controls.Add($BtnSave)
$Form.ShowDialog() | Out-Null
