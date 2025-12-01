# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "NETWORK MASTER - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(600, 450)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
$Form.ForeColor = "Cyan"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "NETWORK OPTIMIZER"; $LblT.Font = New-Object System.Drawing.Font("Impact", 18); $LblT.AutoSize=$true; $LblT.Location="20,15"; $Form.Controls.Add($LblT)

# Status Box
$TxtLog = New-Object System.Windows.Forms.TextBox
$TxtLog.Multiline = $true; $TxtLog.Location = "20, 60"; $TxtLog.Size = "545, 150"
$TxtLog.BackColor = "Black"; $TxtLog.ForeColor = "Lime"; $TxtLog.Font = "Consolas, 10"; $TxtLog.ReadOnly = $true
$Form.Controls.Add($TxtLog)

function Log ($M) { $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $M`r`n"); $TxtLog.ScrollToCaret() }

# --- FUNCTIONS ---
function Set-DNS ($Provider) {
    Log "Dang thiet lap DNS: $Provider..."
    $DNS = @("8.8.8.8","8.8.4.4"); if ($Provider -eq "Cloudflare") { $DNS = @("1.1.1.1","1.0.0.1") }
    
    try {
        $Nics = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
        foreach ($N in $Nics) {
            if ($Provider -eq "Auto") { $N.SetDNSServerSearchOrder() | Out-Null; Log " -> $($N.Description): Reset Auto (DHCP)" }
            else { $N.SetDNSServerSearchOrder($DNS) | Out-Null; Log " -> $($N.Description): OK" }
        }
        Log ">>> CAU HINH XONG!"
        [System.Windows.Forms.MessageBox]::Show("Da doi DNS sang $Provider thanh cong!", "Success")
    } catch { Log "Loi: $($_.Exception.Message)" }
}

function Fix-Net {
    Log "Bat dau quy trinh sua loi mang..."
    cmd /c "ipconfig /flushdns"; Log " - Flush DNS: OK"
    cmd /c "ipconfig /release"; Log " - Release IP: OK"
    cmd /c "ipconfig /renew"; Log " - Renew IP: OK"
    cmd /c "netsh int ip reset"; Log " - Reset TCP/IP: OK"
    cmd /c "netsh winsock reset"; Log " - Reset Winsock: OK"
    Log ">>> XONG! Vui long Restart may de ap dung."
    [System.Windows.Forms.MessageBox]::Show("Da reset toan bo mang luoi!`nKhoi dong lai may ngay?", "Xong", "YesNo", "Question")
}

function Ping-Test {
    $TxtLog.Text = "--- PING TEST STARTING ---`r`n"
    foreach ($Target in @("google.com", "vnexpress.net", "facebook.com")) {
        $P = Test-Connection -ComputerName $Target -Count 1 -ErrorAction SilentlyContinue
        if ($P) { Log "Ping $Target : $($P.ResponseTime) ms (OK)" } else { Log "Ping $Target : REQUEST TIMED OUT (Loi)" }
        Start-Sleep -Milliseconds 500
    }
    Log "--- END TEST ---"
}

# --- BUTTONS ---
# Nhóm 1: DNS
$GB1 = New-Object System.Windows.Forms.GroupBox; $GB1.Text = "1. DOI DNS SIEU TOC"; $GB1.Location = "20,220"; $GB1.Size = "545, 80"; $GB1.ForeColor="White"; $Form.Controls.Add($GB1)
$B_Go = New-Object System.Windows.Forms.Button; $B_Go.Text="GOOGLE (8.8.8.8)"; $B_Go.Location="20,30"; $B_Go.Size="150,35"; $B_Go.BackColor="DimGray"; $B_Go.Add_Click({Set-DNS "Google"}); $GB1.Controls.Add($B_Go)
$B_Cf = New-Object System.Windows.Forms.Button; $B_Cf.Text="CLOUDFLARE (1.1.1.1)"; $B_Cf.Location="190,30"; $B_Cf.Size="150,35"; $B_Cf.BackColor="DimGray"; $B_Cf.Add_Click({Set-DNS "Cloudflare"}); $GB1.Controls.Add($B_Cf)
$B_Au = New-Object System.Windows.Forms.Button; $B_Au.Text="AUTO (RESET)"; $B_Au.Location="360,30"; $B_Au.Size="150,35"; $B_Au.BackColor="DimGray"; $B_Au.Add_Click({Set-DNS "Auto"}); $GB1.Controls.Add($B_Au)

# Nhóm 2: FIX & TEST
$GB2 = New-Object System.Windows.Forms.GroupBox; $GB2.Text = "2. SUA LOI & KIEM TRA"; $GB2.Location = "20,310"; $GB2.Size = "545, 80"; $GB2.ForeColor="Yellow"; $Form.Controls.Add($GB2)
$B_Fix = New-Object System.Windows.Forms.Button; $B_Fix.Text="FIX LOI MANG (RESET ALL)"; $B_Fix.Location="20,30"; $B_Fix.Size="250,35"; $B_Fix.BackColor="DarkRed"; $B_Fix.ForeColor="White"; $B_Fix.Add_Click({Fix-Net}); $GB2.Controls.Add($B_Fix)
$B_Ping = New-Object System.Windows.Forms.Button; $B_Ping.Text="TEST PING (3 MANG)"; $B_Ping.Location="290,30"; $B_Ping.Size="220,35"; $B_Ping.BackColor="Green"; $B_Ping.ForeColor="White"; $B_Ping.Add_Click({Ping-Test}); $GB2.Controls.Add($B_Ping)

$Form.ShowDialog() | Out-Null
