<#
    TOOL CAU HINH WINDOWS - PHAT TAN PC
    Version: 42.0 (Full Auto Unattend + Language + App Installer)
    Author: Phat Tan
#>

try { Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing } catch { Exit }

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CAU HINH FILE V42.0 (FULL AUTO & LANGUAGE)"
$Form.Size = "680,750"
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 30); $Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

$FontBold = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$FontNorm = New-Object System.Drawing.Font("Segoe UI", 10)

$Lbl = New-Object System.Windows.Forms.Label; $Lbl.Text = "THIET LAP TU DONG HOA (UNATTEND)"; $Lbl.Location = "20,20"; $Lbl.AutoSize=$true; $Lbl.Font=$FontBold; $Lbl.ForeColor="Cyan"; $Form.Controls.Add($Lbl)

function Add-Input ($T, $Y, $D, $W=400) {
    $L=New-Object System.Windows.Forms.Label; $L.Text=$T; $L.Location="20,$Y"; $L.AutoSize=$true; $L.Font=$FontNorm; $Form.Controls.Add($L)
    $B=New-Object System.Windows.Forms.TextBox; $B.Text=$D; $B.Location="220,$Y"; $B.Size="$W,25"; $B.Font=$FontNorm; $Form.Controls.Add($B); return $B
}

# 1. Tai khoan & May tinh
$TxtUser = Add-Input "Ten User:" 60 "Admin"
$TxtPass = Add-Input "Mat Khau:" 95 ""
$TxtPC   = Add-Input "Ten May:" 130 "PhatTan-PC"

# 2. Ngon ngu & Vung mien (New)
$TxtLang = Add-Input "Ngon ngu UI (vd: en-US):" 165 "en-US" 150
$TxtLocale = Add-Input "Locale (vd: en-US):" 200 "en-US" 150
$TxtKbd = Add-Input "Ban phim (vd: 0409:00000409):" 235 "0409:00000409" 250
$TxtTZ  = Add-Input "Mui gio (Timezone):" 270 "SE Asia Standard Time" 250

# 3. Chon noi luu file
$LblPath = New-Object System.Windows.Forms.Label; $LblPath.Text = "Noi luu file XML:"; $LblPath.Location = "20,310"; $LblPath.AutoSize=$true; $Form.Controls.Add($LblPath)
$TxtPath = New-Object System.Windows.Forms.TextBox; $TxtPath.Text = "D:\autounattend.xml"; $TxtPath.Location = "220,310"; $TxtPath.Size = "320,25"; $Form.Controls.Add($TxtPath)
$BtnBrowse = New-Object System.Windows.Forms.Button; $BtnBrowse.Text = "..."; $BtnBrowse.Location = "550,308"; $BtnBrowse.Size = "70,28"; $BtnBrowse.BackColor = "Gray"
$BtnBrowse.Add_Click({
    $SaveFile = New-Object System.Windows.Forms.SaveFileDialog; $SaveFile.Filter = "XML Files (*.xml)|*.xml"; $SaveFile.FileName = "autounattend.xml"
    if ($SaveFile.ShowDialog() -eq "OK") { $TxtPath.Text = $SaveFile.FileName }
})
$Form.Controls.Add($BtnBrowse)

# 4. Tuy chon Apps (Winget)
$GBApps = New-Object System.Windows.Forms.GroupBox; $GBApps.Text = "TU DONG CAI APPS (SAU KHI LEN WIN)"; $GBApps.Location = "20,360"; $GBApps.Size = "620,100"; $GBApps.ForeColor = "Cyan"; $Form.Controls.Add($GBApps)
$CkChrome = New-Object System.Windows.Forms.CheckBox; $CkChrome.Text = "Google Chrome"; $CkChrome.Location = "20,35"; $CkChrome.AutoSize=$true; $CkChrome.Checked=$true; $GBApps.Controls.Add($CkChrome)
$CkUltra = New-Object System.Windows.Forms.CheckBox; $CkUltra.Text = "UltraViewer"; $CkUltra.Location = "200,35"; $CkUltra.AutoSize=$true; $CkUltra.Checked=$true; $GBApps.Controls.Add($CkUltra)
$CkUnikey = New-Object System.Windows.Forms.CheckBox; $CkUnikey.Text = "Unikey"; $CkUnikey.Location = "380,35"; $CkUnikey.AutoSize=$true; $CkUnikey.Checked=$true; $GBApps.Controls.Add($CkUnikey)

# 5. Settings OOBE
$GBSet = New-Object System.Windows.Forms.GroupBox; $GBSet.Text = "OOBE AUTOMATION"; $GBSet.Location = "20,470"; $GBSet.Size = "620,80"; $GBSet.ForeColor = "Lime"; $Form.Controls.Add($GBSet)
$CkSkipWifi = New-Object System.Windows.Forms.CheckBox; $CkSkipWifi.Text = "Skip Wifi"; $CkSkipWifi.Location = "20,30"; $CkSkipWifi.Checked=$true; $GBSet.Controls.Add($CkSkipWifi)
$CkAutoLogon = New-Object System.Windows.Forms.CheckBox; $CkAutoLogon.Text = "Auto Logon"; $CkAutoLogon.Location = "150,30"; $CkAutoLogon.Checked=$true; $GBSet.Controls.Add($CkAutoLogon)

$BtnSave = New-Object System.Windows.Forms.Button; $BtnSave.Text = "XUAT FILE AUTO UNATTEND XML (V42.0)"; $BtnSave.Location = "20,580"; $BtnSave.Size = "620,70"; $BtnSave.BackColor = "Cyan"; $BtnSave.ForeColor = "Black"; $BtnSave.Font=$FontBold

$BtnSave.Add_Click({
    $DestPath = $TxtPath.Text; $User = $TxtUser.Text; $Pass = $TxtPass.Text; $PCName = $TxtPC.Text
    $Lang = $TxtLang.Text; $Locale = $TxtLocale.Text; $Kbd = $TxtKbd.Text; $TZ = $TxtTZ.Text
    
    $PassBlock = ""; if (![string]::IsNullOrEmpty($Pass)) { $PassBlock = "<Password><Value>$Pass</Value><PlainText>true</PlainText></Password>" }
    $AutoLogon = ""; if ($CkAutoLogon.Checked) { $AutoLogon = "<AutoLogon><Username>$User</Username>$PassBlock<Enabled>true</Enabled><LogonCount>1</LogonCount></AutoLogon>" }
    $SkipWifi = if ($CkSkipWifi.Checked) { "true" } else { "false" }

    # Command cai App
    $AppCmds = ""; $Idx = 1
    if ($CkChrome.Checked) { $AppCmds += "<SynchronousCommand wcm:action=`"add`"><CommandLine>powershell -Command `"winget install Google.Chrome --silent --accept-package-agreements`"</CommandLine><Description>Chrome</Description><Order>$Idx</Order></SynchronousCommand>"; $Idx++ }
    if ($CkUltra.Checked) { $AppCmds += "<SynchronousCommand wcm:action=`"add`"><CommandLine>powershell -Command `"winget install UltraViewer.UltraViewer --silent --accept-package-agreements`"</CommandLine><Description>UltraViewer</Description><Order>$Idx</Order></SynchronousCommand>"; $Idx++ }
    if ($CkUnikey.Checked) { $AppCmds += "<SynchronousCommand wcm:action=`"add`"><CommandLine>powershell -Command `"winget install PhamKimLong.UniKey --silent --accept-package-agreements`"</CommandLine><Description>Unikey</Description><Order>$Idx</Order></SynchronousCommand>"; $Idx++ }

    $FirstLogon = ""; if (![string]::IsNullOrEmpty($AppCmds)) { $FirstLogon = "<FirstLogonCommands>$AppCmds</FirstLogonCommands>" }

    # Component OOBE Core
    function Gen-OOBE ($Arch) {
        return @"
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="$Arch" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <ComputerName>$PCName</ComputerName>
            <TimeZone>$TZ</TimeZone>
            <UserAccounts><LocalAccounts><LocalAccount wcm:action="add"><Name>$User</Name><DisplayName>$User</DisplayName><Group>Administrators</Group>$PassBlock</LocalAccount></LocalAccounts></UserAccounts>
            $AutoLogon
            <OOBE><ProtectYourPC>3</ProtectYourPC><HideEULAPage>true</HideEULAPage><HideWirelessSetupInOOBE>$SkipWifi</HideWirelessSetupInOOBE><HideOnlineAccountScreens>true</HideOnlineAccountScreens><HideLocalUserAccountScreen>true</HideLocalUserAccountScreen></OOBE>
            $FirstLogon
        </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="$Arch" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <InputLocale>$Kbd</InputLocale><SystemLocale>$Locale</SystemLocale><UILanguage>$Lang</UILanguage><UserLocale>$Locale</UserLocale>
        </component>
"@
    }

    $FinalXML = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <SetupUILanguage><UILanguage>$Lang</UILanguage></SetupUILanguage>
            <InputLocale>$Kbd</InputLocale><SystemLocale>$Locale</SystemLocale><UILanguage>$Lang</UILanguage><UserLocale>$Locale</UserLocale>
        </component>
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <UserData><AcceptEula>true</AcceptEula></UserData>
        </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"><ComputerName>$PCName</ComputerName></component>
    </settings>
    <settings pass="oobeSystem">
        $(Gen-OOBE "amd64")
    </settings>
</unattend>
"@
    try {
        [IO.File]::WriteAllText($DestPath, $FinalXML, [System.Text.Encoding]::UTF8)
        [System.Windows.Forms.MessageBox]::Show("DA TAO FILE THANH CONG!`nLuu tai: $DestPath", "Phat Tan PC")
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi: $($_.Exception.Message)") }
})

$Form.Controls.Add($BtnSave)
$Form.ShowDialog() | Out-Null
