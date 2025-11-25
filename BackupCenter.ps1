Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing
$Form = New-Object System.Windows.Forms.Form; $Form.Text = "BACKUP CENTER - PHAT TAN PC"; $Form.Size = New-Object System.Drawing.Size(500, 400); $Form.StartPosition = "CenterScreen"
$GB = New-Object System.Windows.Forms.GroupBox; $GB.Text = "Luu tai: D:\PhatTan_Backup"; $GB.Location = New-Object System.Drawing.Point(20, 20); $GB.Size = New-Object System.Drawing.Size(440, 250); $Form.Controls.Add($GB)
$cW = New-Object System.Windows.Forms.CheckBox; $cW.Text="Wifi Passwords"; $cW.Location="20,30"; $cW.AutoSize=$true; $GB.Controls.Add($cW)
$cD = New-Object System.Windows.Forms.CheckBox; $cD.Text="Drivers (Export)"; $cD.Location="20,60"; $cD.AutoSize=$true; $GB.Controls.Add($cD)
$cF = New-Object System.Windows.Forms.CheckBox; $cF.Text="Data (Desktop/Doc/Down)"; $cF.Location="20,90"; $cF.AutoSize=$true; $GB.Controls.Add($cF)
$cZ = New-Object System.Windows.Forms.CheckBox; $cZ.Text="Zalo PC Data"; $cZ.Location="20,120"; $cZ.AutoSize=$true; $GB.Controls.Add($cZ)
$cL = New-Object System.Windows.Forms.CheckBox; $cL.Text="License (Tokens.dat)"; $cL.Location="20,150"; $cL.AutoSize=$true; $GB.Controls.Add($cL)
$cC = New-Object System.Windows.Forms.CheckBox; $cC.Text="Chrome Profile"; $cC.Location="20,180"; $cC.AutoSize=$true; $GB.Controls.Add($cC)
$Btn = New-Object System.Windows.Forms.Button; $Btn.Text="START BACKUP"; $Btn.Size="200,50"; $Btn.Location="140,300"; $Btn.BackColor="LimeGreen"; $Btn.Add_Click({
    $Dir = "D:\PhatTan_Backup_$((Get-Date).ToString('ddMMyy_HHmm'))"; New-Item -ItemType Directory -Path $Dir -Force | Out-Null
    if ($cW.Checked) { netsh wlan export profile key=clear folder="$Dir" }
    if ($cD.Checked) { dism /online /export-driver /destination:"$Dir\Drivers" }
    if ($cF.Checked) { foreach($i in "Desktop","Documents","Downloads") { Robocopy "$env:USERPROFILE\$i" "$Dir\$i" /E /R:0 /W:0 } }
    if ($cZ.Checked) { Robocopy "$env:APPDATA\ZaloPC" "$Dir\ZaloPC" /E /R:0 /W:0 }
    if ($cL.Checked) { Robocopy "C:\Windows\System32\spp\store" "$Dir\License" /E /R:0 /W:0 }
    if ($cC.Checked) { Robocopy "$env:LOCALAPPDATA\Google\Chrome\User Data" "$Dir\Chrome" /E /R:0 /W:0 }
    [System.Windows.Forms.MessageBox]::Show("Xong! Luu tai: $Dir", "Phat Tan PC")
}); $Form.Controls.Add($Btn); $Form.ShowDialog()
