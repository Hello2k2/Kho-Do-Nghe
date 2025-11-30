# --- INIT ---
try { Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing } catch { Exit }

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CAU HINH FILE (V28.0 SILENT)"
$Form.Size = New-Object System.Drawing.Size(650, 500)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30); $Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false
$FontBold = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$FontNorm = New-Object System.Drawing.Font("Segoe UI", 10)

$Lbl = New-Object System.Windows.Forms.Label; $Lbl.Text = "THONG TIN TAI KHOAN (AUTO)"; $Lbl.Location = "20,20"; $Lbl.AutoSize=$true; $Lbl.Font=$FontBold; $Lbl.ForeColor="Cyan"; $Form.Controls.Add($Lbl)

function Add-Input ($T, $Y, $D) {
    $L=New-Object System.Windows.Forms.Label; $L.Text=$T; $L.Location="20,$Y"; $L.AutoSize=$true; $L.Font=$FontNorm; $Form.Controls.Add($L)
    $B=New-Object System.Windows.Forms.TextBox; $B.Text=$D; $B.Location="200,$Y"; $B.Size="400,25"; $B.Font=$FontNorm; $Form.Controls.Add($B); return $B
}

$TxtUser = Add-Input "Ten User:" 60 "Admin"
$TxtPass = Add-Input "Mat Khau:" 100 ""
$TxtPC   = Add-Input "Ten May:" 140 "PhatTan-PC"

# --- SETTINGS ---
$GBSet = New-Object System.Windows.Forms.GroupBox; $GBSet.Text = "TUY CHON"; $GBSet.Location = "20,190"; $GBSet.Size = "580,100"; $GBSet.ForeColor = "Lime"; $Form.Controls.Add($GBSet)
$CkSkipWifi = New-Object System.Windows.Forms.CheckBox; $CkSkipWifi.Text = "Skip Wifi (OOBE)"; $CkSkipWifi.Location = "20,30"; $CkSkipWifi.AutoSize=$true; $CkSkipWifi.ForeColor="White"; $CkSkipWifi.Checked=$true; $GBSet.Controls.Add($CkSkipWifi)
$CkAutoLogon = New-Object System.Windows.Forms.CheckBox; $CkAutoLogon.Text = "Auto Logon"; $CkAutoLogon.Location = "20,60"; $CkAutoLogon.AutoSize=$true; $CkAutoLogon.ForeColor="White"; $CkAutoLogon.Checked=$true; $GBSet.Controls.Add($CkAutoLogon)

# LUU Y: CHE DO NAY MAC DINH LA OVERWRITE (KHONG FORMAT SACH) DE TRANH MAT SOURCE
$LblWarn = New-Object System.Windows.Forms.Label; $LblWarn.Text = "Luu y: De tu dong 100%, Tool se cai de len Windows cu (Windows.old).`nKhong Format sach o cung de tranh mat file cai dat."; $LblWarn.Location = "20,300"; $LblWarn.AutoSize=$true; $LblWarn.ForeColor="Yellow"; $Form.Controls.Add($LblWarn)

$BtnSave = New-Object System.Windows.Forms.Button; $BtnSave.Text = "TAO XML (AUTO PILOT)"; $BtnSave.Location = "20,380"; $BtnSave.Size = "580,50"; $BtnSave.BackColor = "Cyan"; $BtnSave.ForeColor = "Black"; $BtnSave.Font=$FontBold

$BtnSave.Add_Click({
    $XMLPath = "$env:SystemDrive\autounattend.xml"

    $User = $TxtUser.Text; $Pass = $TxtPass.Text; $PCName = $TxtPC.Text
    $PassBlock = ""; if (![string]::IsNullOrEmpty($Pass)) { $PassBlock = "<Password><Value>$Pass</Value><PlainText>true</PlainText></Password>" }
    $AutoLogon = ""; if ($CkAutoLogon.Checked) { $AutoLogon = "<AutoLogon><Username>$User</Username>$PassBlock<Enabled>true</Enabled><LogonCount>1</LogonCount></AutoLogon>" }
    $SkipWifi = if ($CkSkipWifi.Checked) { "true" } else { "false" }
    
    # --- XML GENERATOR (NO DISK CONFIG BLOCK -> FIX ERROR) ---
    function Gen-Comp ($Arch) {
        return @"
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="$Arch" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <SetupUILanguage><UILanguage>en-US</UILanguage></SetupUILanguage><InputLocale>0409:00000409</InputLocale><SystemLocale>en-US</SystemLocale><UILanguage>en-US</UILanguage><UserLocale>en-US</UserLocale>
        </component>
        <component name="Microsoft-Windows-Setup" processorArchitecture="$Arch" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <UserData>
                %PRODUCTKEY_PLACEHOLDER%
                <AcceptEula>true</AcceptEula>
            </UserData>
            <ImageInstall>
                <OSImage>
                    %SOURCEPATH_PLACEHOLDER%
                    <InstallTo><DiskID>__DISKID__</DiskID><PartitionID>__PARTID__</PartitionID></InstallTo>
                </OSImage>
            </ImageInstall>
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add"><Order>1</Order><Path>reg.exe add "HKLM\SYSTEM\Setup\LabConfig" /v BypassTPMCheck /t REG_DWORD /d 1 /f</Path></RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add"><Order>2</Order><Path>reg.exe add "HKLM\SYSTEM\Setup\LabConfig" /v BypassSecureBootCheck /t REG_DWORD /d 1 /f</Path></RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add"><Order>3</Order><Path>reg.exe add "HKLM\SYSTEM\Setup\LabConfig" /v BypassRAMCheck /t REG_DWORD /d 1 /f</Path></RunSynchronousCommand>
            </RunSynchronous>
        </component>
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
    <settings pass="windowsPE">
        $(Gen-Comp "amd64")
        $(Gen-Comp "x86")
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"><ComputerName>$PCName</ComputerName></component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"><ComputerName>$PCName</ComputerName></component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">$AutoLogon</component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">$AutoLogon</component>
    </settings>
</unattend>
"@

    try {
        $Utf8Bom = New-Object System.Text.UTF8Encoding $true
        [IO.File]::WriteAllText($XMLPath, $FinalXML, $Utf8Bom)
        [System.Windows.Forms.MessageBox]::Show("DA TAO XML (V28.0) CHUAN SILENT!", "Success")
        $Form.Close()
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi ghi file: $($_.Exception.Message)", "Loi") }
})

$Form.Controls.Add($BtnSave)
$Form.ShowDialog() | Out-Null
