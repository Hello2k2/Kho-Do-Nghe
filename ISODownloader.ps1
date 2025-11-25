Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing
$Form = New-Object System.Windows.Forms.Form; $Form.Text = "ISO DOWNLOADER"; $Form.Size = New-Object System.Drawing.Size(400, 300); $Form.StartPosition = "CenterScreen"
function Add-Btn($T, $U, $Y) { $b=New-Object System.Windows.Forms.Button; $b.Text=$T; $b.Location="50,$Y"; $b.Size="300,35"; $b.Add_Click({Start-Process $U}); $Form.Controls.Add($b) }
Add-Btn "Win 10 LTSC 2021 (Archive.org)" "https://archive.org/download/windows-10-enterprise-ltsc-2021_202111/Windows%2010%20Enterprise%20LTSC%202021.iso" 20
Add-Btn "Win 11 Goc (Microsoft)" "https://www.microsoft.com/software-download/windows11" 70
Add-Btn "Win 10 Goc (Microsoft)" "https://www.microsoft.com/software-download/windows10" 120
Add-Btn "Massgrave (All Version)" "https://massgrave.dev/genuine-installation-media" 170
$Form.ShowDialog()
