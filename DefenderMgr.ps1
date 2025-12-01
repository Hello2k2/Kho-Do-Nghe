# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "DEFENDER CONTROL - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(500, 350)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 25)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedToolWindow"

# Header
$LblT = New-Object System.Windows.Forms.Label
$LblT.Text = "WINDOWS DEFENDER MANAGER"; $LblT.Font = New-Object System.Drawing.Font("Impact", 18)
$LblT.AutoSize=$true; $LblT.ForeColor="Cyan"; $LblT.Location="20,15"; $Form.Controls.Add($LblT)

# Status Panel
$PnlStatus = New-Object System.Windows.Forms.Panel
$PnlStatus.Location="20, 60"; $PnlStatus.Size="445, 100"; $PnlStatus.BorderStyle="FixedSingle"
$Form.Controls.Add($PnlStatus)

$LblStatText = New-Object System.Windows.Forms.Label
$LblStatText.Text = "REAL-TIME PROTECTION:"; $LblStatText.Location="10,10"; $LblStatText.AutoSize=$true; $LblStatText.Font="Segoe UI, 10"; $PnlStatus.Controls.Add($LblStatText)

$LblStatus = New-Object System.Windows.Forms.Label
$LblStatus.Text = "CHECKING..."; $LblStatus.Location="10,35"; $LblStatus.AutoSize=$true; $LblStatus.Font="Segoe UI, 20, Bold"; $PnlStatus.Controls.Add($LblStatus)

$LblTamper = New-Object System.Windows.Forms.Label
$LblTamper.Text = "Tamper Protection Check..."; $LblTamper.Location="10,75"; $LblTamper.AutoSize=$true; $LblTamper.ForeColor="Gray"; $PnlStatus.Controls.Add($LblTamper)

# --- LOGIC ---
function Update-UI {
    $MpStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
    $IsRealTimeOn = $MpStatus.RealTimeProtectionEnabled
    $IsTamperOn = $MpStatus.IsTamperProtectionEnabled

    # Update Realtime Status
    if ($IsRealTimeOn) {
        $LblStatus.Text = "ON (DANG BAT)"
        $LblStatus.ForeColor = "LimeGreen"
        $BtnToggle.Text = "TAT DEFENDER NGAY"
        $BtnToggle.BackColor = "Firebrick"
    } else {
        $LblStatus.Text = "OFF (DA TAT)"
        $LblStatus.ForeColor = "Red"
        $BtnToggle.Text = "BAT LAI DEFENDER"
        $BtnToggle.BackColor = "SeaGreen"
    }

    # Update Tamper Status (QUAN TRỌNG)
    if ($IsTamperOn) {
        $LblTamper.Text = "LUU Y: Tamper Protection dang BAT. Ban phai tat no bang tay truoc!"
        $LblTamper.ForeColor = "Yellow"
        $BtnOpenSec.Visible = $true
    } else {
        $LblTamper.Text = "Tamper Protection: OFF (OK de dung Tool)"
        $LblTamper.ForeColor = "Gray"
        $BtnOpenSec.Visible = $false
    }
}

function Toggle-Def {
    $MpStatus = Get-MpComputerStatus
    try {
        if ($MpStatus.RealTimeProtectionEnabled) {
            # Tắt
            Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop
            [System.Windows.Forms.MessageBox]::Show("Da gui lenh TAT Defender!", "Info")
        } else {
            # Bật
            Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop
            [System.Windows.Forms.MessageBox]::Show("Da gui lenh BAT Defender!", "Info")
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("KHONG THE THAY DOI!`n`nLy do: 'Tamper Protection' dang bat.`nVui long bam nut 'MO WINDOWS SECURITY' va tat Tamper Protection truoc.", "Block", "OK", "Error")
    }
    Update-UI
}

# --- BUTTONS ---
$BtnToggle = New-Object System.Windows.Forms.Button
$BtnToggle.Text = "..."
$BtnToggle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$BtnToggle.Location = "20, 180"; $BtnToggle.Size = "445, 60"
$BtnToggle.ForeColor = "White"; $BtnToggle.FlatStyle = "Flat"
$BtnToggle.Add_Click({ Toggle-Def })
$Form.Controls.Add($BtnToggle)

$BtnOpenSec = New-Object System.Windows.Forms.Button
$BtnOpenSec.Text = "MO WINDOWS SECURITY (DE TAT TAMPER)"
$BtnOpenSec.Location = "20, 250"; $BtnOpenSec.Size = "445, 40"
$BtnOpenSec.BackColor = "DimGray"; $BtnOpenSec.ForeColor = "White"; $BtnOpenSec.FlatStyle = "Flat"
$BtnOpenSec.Visible = $false
$BtnOpenSec.Add_Click({ Start-Process "windowsdefender:" })
$Form.Controls.Add($BtnOpenSec)

# Load Initial State
$Form.Add_Shown({ Update-UI })
$Form.ShowDialog() | Out-Null
