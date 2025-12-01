# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "BROWSER PRIVACY CONTROL - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(600, 350)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedToolWindow"

# Header
$LblT = New-Object System.Windows.Forms.Label
$LblT.Text = "QUAN LY RIENG TU TRINH DUYET"
$LblT.Font = New-Object System.Drawing.Font("Impact", 18); $LblT.ForeColor = "Cyan"
$LblT.AutoSize = $true; $LblT.Location = "20, 20"; $Form.Controls.Add($LblT)

$LblSub = New-Object System.Windows.Forms.Label
$LblSub.Text = "Chan luu lich su Web (History) tren Chrome & Edge thong qua Registry (GPO)"
$LblSub.Font = "Segoe UI, 9"; $LblSub.ForeColor = "Gray"; $LblSub.AutoSize=$true; $LblSub.Location = "25, 55"; $Form.Controls.Add($LblSub)

# --- FUNCTIONS ---
function Set-Reg ($Path, $Name, $Val) {
    if (!(Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    if ($Val -eq $null) { Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue }
    else { Set-ItemProperty -Path $Path -Name $Name -Value $Val -Type DWord }
}

function Get-Status ($Path, $Name) {
    if (Test-Path $Path) {
        $V = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        if ($V.$Name -eq 1) { return $true } # Dang chan (Blocked)
    }
    return $false # Binh thuong
}

function Check-UI {
    # Check Chrome
    $C = Get-Status "HKLM:\SOFTWARE\Policies\Google\Chrome" "SavingBrowserHistoryDisabled"
    if ($C) { $LblC.Text = "CHROME: DANG CHAN LICH SU (SECURE)"; $LblC.ForeColor = "Lime"; $BtnC.Text = "MO KHOA (CHO PHEP LUU)"; $BtnC.BackColor = "DimGray" }
    else    { $LblC.Text = "CHROME: DANG LUU LICH SU (DEFAULT)"; $LblC.ForeColor = "Yellow"; $BtnC.Text = "CHAN LUU LICH SU NGAY"; $BtnC.BackColor = "Firebrick" }

    # Check Edge
    $E = Get-Status "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "SavingBrowserHistoryDisabled"
    if ($E) { $LblE.Text = "EDGE: DANG CHAN LICH SU (SECURE)"; $LblE.ForeColor = "Lime"; $BtnE.Text = "MO KHOA (CHO PHEP LUU)"; $BtnE.BackColor = "DimGray" }
    else    { $LblE.Text = "EDGE: DANG LUU LICH SU (DEFAULT)"; $LblE.ForeColor = "Yellow"; $BtnE.Text = "CHAN LUU LICH SU NGAY"; $BtnE.BackColor = "Firebrick" }
}

# --- CHROME CONTROL ---
$GbC = New-Object System.Windows.Forms.GroupBox; $GbC.Text = "Google Chrome"; $GbC.Location = "20, 90"; $GbC.Size = "545, 100"; $GbC.ForeColor = "White"; $Form.Controls.Add($GbC)
$LblC = New-Object System.Windows.Forms.Label; $LblC.Location = "20, 30"; $LblC.AutoSize=$true; $LblC.Font="Segoe UI, 10, Bold"; $GbC.Controls.Add($LblC)
$BtnC = New-Object System.Windows.Forms.Button; $BtnC.Location = "350, 25"; $BtnC.Size = "180, 35"; $BtnC.FlatStyle="Flat"; $GbC.Controls.Add($BtnC)

$BtnC.Add_Click({
    $Path = "HKLM:\SOFTWARE\Policies\Google\Chrome"
    if ($BtnC.Text -match "CHAN") { Set-Reg $Path "SavingBrowserHistoryDisabled" 1; [System.Windows.Forms.MessageBox]::Show("Da CHAN luu lich su Chrome!", "Done") }
    else { Set-Reg $Path "SavingBrowserHistoryDisabled" $null; [System.Windows.Forms.MessageBox]::Show("Da MO KHOA lich su Chrome!", "Done") }
    Check-UI
})

# --- EDGE CONTROL ---
$GbE = New-Object System.Windows.Forms.GroupBox; $GbE.Text = "Microsoft Edge"; $GbE.Location = "20, 200"; $GbE.Size = "545, 100"; $GbE.ForeColor = "White"; $Form.Controls.Add($GbE)
$LblE = New-Object System.Windows.Forms.Label; $LblE.Location = "20, 30"; $LblE.AutoSize=$true; $LblE.Font="Segoe UI, 10, Bold"; $GbE.Controls.Add($LblE)
$BtnE = New-Object System.Windows.Forms.Button; $BtnE.Location = "350, 25"; $BtnE.Size = "180, 35"; $BtnE.FlatStyle="Flat"; $GbE.Controls.Add($BtnE)

$BtnE.Add_Click({
    $Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    if ($BtnE.Text -match "CHAN") { Set-Reg $Path "SavingBrowserHistoryDisabled" 1; [System.Windows.Forms.MessageBox]::Show("Da CHAN luu lich su Edge!", "Done") }
    else { Set-Reg $Path "SavingBrowserHistoryDisabled" $null; [System.Windows.Forms.MessageBox]::Show("Da MO KHOA lich su Edge!", "Done") }
    Check-UI
})

$Form.Add_Shown({ Check-UI })
$Form.ShowDialog() | Out-Null
