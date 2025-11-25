Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing
$Form = New-Object System.Windows.Forms.Form; $Form.Text = "APP STORE - PHAT TAN PC"; $Form.Size = New-Object System.Drawing.Size(600, 200); $Form.StartPosition = "CenterScreen"
$Lbl = New-Object System.Windows.Forms.Label; $Lbl.Text = "Nhap ten app (VD: discord, telegram, obs...):"; $Lbl.AutoSize=$true; $Lbl.Location="20,20"; $Form.Controls.Add($Lbl)
$Txt = New-Object System.Windows.Forms.TextBox; $Txt.Size="540,30"; $Txt.Location="20,50"; $Form.Controls.Add($Txt)
$Btn = New-Object System.Windows.Forms.Button; $Btn.Text="TIM & CAI DAT"; $Btn.Location="200,90"; $Btn.Size="180,40"; $Btn.BackColor="Cyan"; $Btn.Add_Click({
    $App = $Txt.Text; if (!$App) { return }
    $Form.Close()
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Start-Process powershell "-NoExit", "-Command", "winget search $App; Write-Host 'Go: winget install <ID>'; Read-Host"
    } else {
        Write-Host "Cai Chocolatey..." -F Yellow; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Start-Process powershell "-NoExit", "-Command", "choco search $App; Write-Host 'Go: choco install <Name> -y'; Read-Host"
    }
}); $Form.Controls.Add($Btn); $Form.ShowDialog()
