# --- INIT ---
try { Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing } catch { Exit }

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CAU HINH FILE (V36.0 AUTO DISCOVERY)"
$Form.Size = New-Object System.Drawing.Size(650, 550)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30); $Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false
$FontBold = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$FontNorm = New-Object System.Drawing.Font("Segoe UI", 10)

$Lbl = New-Object System.Windows.Forms.Label; $Lbl.Text = "THONG TIN TAI KHOAN"; $Lbl.Location = "20,20"; $Lbl.AutoSize=$true; $Lbl.Font=$FontBold; $Lbl.ForeColor="Cyan"; $Form.Controls.Add($Lbl)

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
$RadWipe = New-Object System.Windows.Forms.RadioButton; $RadWipe.Text = "FORMAT SACH O C: (Can co o phu)"; $RadWipe.Location = "20,30"; $RadWipe.AutoSize=$true; $RadWipe.ForeColor="Red"; $GB.Controls.Add($RadWipe)
$RadDual = New-Object System.Windows.Forms.RadioButton; $RadDual.Text = "GHI DE (Windows.old)"; $RadDual.Location = "20,60"; $RadDual.AutoSize=$true; $RadDual.ForeColor="White"; $RadDual.Checked=$true; $GB.Controls.Add($RadDual)

$BtnSave = New-Object System.Windows.Forms.Button; $BtnSave.Text = "TAO XML CAU HINH"; $BtnSave.Location = "20,480"; $BtnSave.Size = "580,50"; $BtnSave.BackColor = "Cyan"; $BtnSave.ForeColor = "Black"; $BtnSave.Font=$FontBold

$BtnSave.Add_Click({
    $XMLPath = "$env:SystemDrive\autounattend.xml"

    $User = $TxtUser.Text; $Pass = $TxtPass.Text; $PCName = $TxtPC.Text; $TZ = $CmbTZ.SelectedItem
    $PassBlock = ""; if (![string]::IsNullOrEmpty($Pass)) { $PassBlock = "<Password><Value>$Pass</Value><PlainText>true</PlainText></Password>" }
    $AutoLogon = ""; if ($CkAutoLogon.Checked) { $AutoLogon = "<AutoLogon><Username>$User</Username>$PassBlock<Enabled>true</Enabled><LogonCount>1</LogonCount></AutoLogon>" }
    $SkipWifi = if ($CkSkipWifi.Checked) { "true" } else { "false" }
    
    if ($RadWipe.Checked) {
        $Wipe = "true"
        $CreatePart = "<CreatePartitions><CreatePartition wcm:action='add'><Order>1</Order><Type>Primary</Type><Extend>true</Extend></CreatePartition></CreatePartitions><ModifyPartitions><ModifyPartition wcm:action='add'><Order>1</Order><PartitionID>1</PartitionID><Label>Windows</Label><Letter>C</Letter><Format>NTFS</Format></ModifyPartition></ModifyPartitions>"
    } else {
        $Wipe = "false"
        $CreatePart = "" 
    }

    $Regs = ""
    $i=1
    $Regs += "<RunSynchronousCommand wcm:action='add'><Order>$i</Order><Path>reg.exe add `"HKLM\SYSTEM\Setup\LabConfig`" /v BypassTPMCheck /t REG_DWORD /d 1 /f</Path></RunSynchronousCommand>"; $i++
    $Regs += "<RunSynchronousCommand wcm:action='add'><Order>$i</Order><Path>reg.exe add `"HKLM\SYSTEM\Setup\LabConfig`" /v BypassSecureBootCheck /t REG_DWORD /d 1 /f</Path></RunSynchronousCommand>"; $i++
    $Regs += "<RunSynchronousCommand wcm:action='add'><Order>$i</Order><Path>reg.exe add `"HKLM\SYSTEM\Setup\LabConfig`" /v BypassRAMCheck /t REG_DWORD /d 1 /f</Path></RunSynchronousCommand>"; $i++
    $Regs += "<RunSynchronousCommand wcm:action='add'><Order>$i</Order><Path>reg.exe add `"HKLM\SYSTEM\Setup\LabConfig`" /v BypassDiskSpaceCheck /t REG_DWORD /d 1 /f</Path></RunSynchronousCommand>"; $i++
    
    if ($CkDefender.Checked) { $Regs += "<RunSynchronousCommand wcm:action='add'><Order>$i</Order><Path>reg.exe add `"HKLM\SOFTWARE\Policies\Microsoft\Windows Defender`" /v DisableAntiSpyware /t REG_DWORD /d 1 /f</Path></RunSynchronousCommand>"; $i++ }
    if ($CkUAC.Checked) { $Regs += "<RunSynchronousCommand wcm:action='add'><Order>$i</Order><Path>reg.exe add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" /v EnableLUA /t REG_DWORD /d 0 /f</Path></RunSynchronousCommand>"; $i++ }

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
            <DiskConfiguration>
                <WillShowUI>OnError</WillShowUI>
                <Disk wcm:action="add">
                    <DiskID>__DISKID__</DiskID>
                    <WillWipeDisk>$Wipe</WillWipeDisk>
                    $CreatePart
                </Disk>
            </DiskConfiguration>
            <ImageInstall>
                <OSImage>
                    <InstallFrom><MetaData wcm:action="add"><Key>/IMAGE/INDEX</Key><Value>__INDEX__</Value></MetaData></InstallFrom>
                    <InstallTo><DiskID>__DISKID__</DiskID><PartitionID>__PARTID__</PartitionID></InstallTo>
                </OSImage>
            </ImageInstall>
            <RunSynchronous>$Regs</RunSynchronous>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="$Arch" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <ComputerName>$PCName</ComputerName><TimeZone>$TZ</TimeZone>
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
        [System.Windows.Forms.MessageBox]::Show("DA TAO XML (V36 AUTO DISCOVERY)!", "Success")
        $Form.Close()
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi ghi file: $($_.Exception.Message)", "Loi") }
})

$Form.Controls.Add($BtnSave)
$Form.ShowDialog() | Out-Null
