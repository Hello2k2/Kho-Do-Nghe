# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WINDOWS UPDATE MANAGER - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(500, 350)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.FormBorderStyle = "FixedToolWindow"

# Label Trạng Thái To
$LblStatus = New-Object System.Windows.Forms.Label
$LblStatus.Text = "CHECKING STATUS..."
$LblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$LblStatus.AutoSize = $false; $LblStatus.Size = "460, 50"; $LblStatus.TextAlign = "MiddleCenter"; $LblStatus.Location = "10, 30"
$Form.Controls.Add($LblStatus)

# Label Giải thích
$LblNote = New-Object System.Windows.Forms.Label
$LblNote.Text = "Cong cu quan ly Update vinh vien (Registry + Services)"
$LblNote.ForeColor = "Gray"; $LblNote.AutoSize = $true; $LblNote.Location = "90, 80"
$Form.Controls.Add($LblNote)

# --- FUNCTIONS ---
$RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"

function Check-Status {
    $IsBlocked = $false
    # Check Registry Key
    if (Test-Path $RegPath) {
        $Val = Get-ItemProperty -Path $RegPath -Name "NoAutoUpdate" -ErrorAction SilentlyContinue
        if ($Val.NoAutoUpdate -eq 1) { $IsBlocked = $true }
    }
    
    if ($IsBlocked) {
        $LblStatus.Text = "STATUS: BLOCKED (DA TAT)"
        $LblStatus.ForeColor = "Red"
    } else {
        $LblStatus.Text = "STATUS: RUNNING (DANG BAT)"
        $LblStatus.ForeColor = "LimeGreen"
    }
}

function Block-Update {
    try {
        # 1. Registry (GPO Method - Manh nhat)
        if (!(Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }
        Set-ItemProperty -Path $RegPath -Name "NoAutoUpdate" -Value 1 -Type DWord
        Set-ItemProperty -Path $RegPath -Name "AUOptions" -Value 2 -Type DWord # Notify only

        # 2. Services
        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        Set-Service -Name wuauserv -StartupType Disabled
        Stop-Service -Name dosvc -Force -ErrorAction SilentlyContinue # Delivery Optimization
        Set-Service -Name dosvc -StartupType Disabled

        [System.Windows.Forms.MessageBox]::Show("DA CHAN UPDATE THANH CONG!`n(Registry Modified + Service Disabled)", "Success")
        Check-Status
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi: $($_.Exception.Message)", "Error") }
}

function Restore-Update {
    try {
        # 1. Registry
        if (Test-Path $RegPath) { Remove-ItemProperty -Path $RegPath -Name "NoAutoUpdate" -ErrorAction SilentlyContinue }
        
        # 2. Services
        Set-Service -Name wuauserv -StartupType Manual
        Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        Set-Service -Name dosvc -StartupType Manual
        
        [System.Windows.Forms.MessageBox]::Show("DA MO LAI UPDATE!`n(Ban co the Check Update ngay bay gio)", "Success")
        Check-Status
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi: $($_.Exception.Message)", "Error") }
}

# --- BUTTONS ---
$BtnBlock = New-Object System.Windows.Forms.Button
$BtnBlock.Text = "BLOCK UPDATE`n(Tat Cap Nhat)"
$BtnBlock.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$BtnBlock.Location = "40, 130"; $BtnBlock.Size = "200, 120"
$BtnBlock.BackColor = "Firebrick"; $BtnBlock.ForeColor = "White"; $BtnBlock.FlatStyle = "Flat"
$BtnBlock.Add_Click({ Block-Update })
$Form.Controls.Add($BtnBlock)

$BtnRestore = New-Object System.Windows.Forms.Button
$BtnRestore.Text = "RESTORE UPDATE`n(Mo Lai)"
$BtnRestore.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$BtnRestore.Location = "250, 130"; $BtnRestore.Size = "200, 120"
$BtnRestore.BackColor = "SeaGreen"; $BtnRestore.ForeColor = "White"; $BtnRestore.FlatStyle = "Flat"
$BtnRestore.Add_Click({ Restore-Update })
$Form.Controls.Add($BtnRestore)

# Load
$Form.Add_Shown({ Check-Status })
$Form.ShowDialog() | Out-Null
