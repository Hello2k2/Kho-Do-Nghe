# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "GEMINI AI TERMINAL ASSISTANT"
$Form.Size = New-Object System.Drawing.Size(700, 450)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "GEMINI AI CLI (POWERED BY GOOGLE)"; $LblT.Font = "Impact, 18"; $LblT.ForeColor="Cyan"; $LblT.AutoSize=$true; $LblT.Location="20,15"; $Form.Controls.Add($LblT)

$LblDesc = New-Object System.Windows.Forms.Label; $LblDesc.Text = "Tro ly ao AI tich hop ngay trong Terminal.`nHoi dap ky thuat, viet code, debug loi truc tiep."; $LblDesc.Location="25,50"; $LblDesc.AutoSize=$true; $LblDesc.ForeColor="LightGray"; $Form.Controls.Add($LblDesc)

# --- STATUS AREA ---
$GbStatus = New-Object System.Windows.Forms.GroupBox; $GbStatus.Text = "Trang Thai He Thong"; $GbStatus.Location="20,90"; $GbStatus.Size="640,120"; $GbStatus.ForeColor="Yellow"; $Form.Controls.Add($GbStatus)

$LblNode = New-Object System.Windows.Forms.Label; $LblNode.Text="Node.js (v20+): Dang kiem tra..."; $LblNode.Location="20,30"; $LblNode.AutoSize=$true; $GbStatus.Controls.Add($LblNode)
$LblGemini = New-Object System.Windows.Forms.Label; $LblGemini.Text="Gemini CLI Package: Dang kiem tra..."; $LblGemini.Location="20,60"; $LblGemini.AutoSize=$true; $GbStatus.Controls.Add($LblGemini)

# --- ACTION BUTTONS ---
$BtnInstall = New-Object System.Windows.Forms.Button; $BtnInstall.Text="CAI DAT / CAP NHAT MOI TRUONG"; $BtnInstall.Location="20,230"; $BtnInstall.Size="310,50"; $BtnInstall.BackColor="DimGray"; $BtnInstall.ForeColor="White"; $BtnInstall.Font="Segoe UI, 10, Bold"; $Form.Controls.Add($BtnInstall)

$BtnLaunch = New-Object System.Windows.Forms.Button; $BtnLaunch.Text="MO CHAT GEMINI AI NGAY"; $BtnLaunch.Location="350,230"; $BtnLaunch.Size="310,50"; $BtnLaunch.BackColor="Green"; $BtnLaunch.ForeColor="White"; $BtnLaunch.Font="Segoe UI, 10, Bold"; $BtnLaunch.Enabled=$false; $Form.Controls.Add($BtnLaunch)

$TxtHd = New-Object System.Windows.Forms.TextBox; $TxtHd.Multiline=$true; $TxtHd.ReadOnly=$true; $TxtHd.Location="20,300"; $TxtHd.Size="640,90"; $TxtHd.BackColor="Black"; $TxtHd.ForeColor="Lime"; $Form.Controls.Add($TxtHd)
$TxtHd.Text = "HUONG DAN:`r`n1. Lan dau chay, chon 'Login with Google' tren trinh duyet.`r`n2. Chat truc tiep trong cua so den.`r`n3. Go /help de xem lenh hoac /exit de thoat."

# --- LOGIC ---

function Check-Env {
    $Form.Cursor = "WaitCursor"
    
    # 1. Check Node.js
    try {
        $NodeVer = node -v 2>$null
        if ($NodeVer) {
            $Major = [int]($NodeVer -replace "v","" -split "\.")[0]
            if ($Major -ge 20) { # Yeu cau Node v20+
                $LblNode.Text = "Node.js: OK ($NodeVer)"; $LblNode.ForeColor="Lime"
                $Global:NodeReady = $true
            } else {
                $LblNode.Text = "Node.js: $NodeVer (Can v20+)"; $LblNode.ForeColor="Red"
                $Global:NodeReady = $false
            }
        } else {
            $LblNode.Text = "Node.js: Chua cai dat!"; $LblNode.ForeColor="Red"
            $Global:NodeReady = $false
        }
    } catch { $LblNode.Text = "Node.js: Loi check!"; $Global:NodeReady = $false }

    # 2. Check Gemini CLI
    if ($Global:NodeReady) {
        try {
            $GeminiCheck = npm list -g @google/gemini-cli 2>$null
            if ($GeminiCheck -match "@google/gemini-cli") {
                $LblGemini.Text = "Gemini CLI: DA CAI DAT (Ready)"; $LblGemini.ForeColor="Lime"
                $BtnLaunch.Enabled = $true; $BtnLaunch.BackColor="LimeGreen"
            } else {
                $LblGemini.Text = "Gemini CLI: Chua cai dat."; $LblGemini.ForeColor="Orange"
                $BtnLaunch.Enabled = $false; $BtnLaunch.BackColor="Gray"
            }
        } catch { $LblGemini.Text = "Gemini CLI: Loi check!"; }
    } else {
        $LblGemini.Text = "Gemini CLI: Cho Node.js..."; $LblGemini.ForeColor="Gray"
        $BtnLaunch.Enabled = $false
    }
    $Form.Cursor = "Default"
}

$BtnInstall.Add_Click({
    $Form.Cursor = "WaitCursor"
    
    # 1. Cai Node.js neu thieu (Dung Winget hoac MSI)
    if (!$Global:NodeReady) {
        $Ans = [System.Windows.Forms.MessageBox]::Show("May ban thieu Node.js v20+. Ban co muon tai va cai dat tu dong khong?", "Cai Node.js", "YesNo", "Question")
        if ($Ans -eq "Yes") {
            try {
                # Tai Node v20 LTS
                $Url = "https://nodejs.org/dist/v20.11.0/node-v20.11.0-x64.msi"
                $Dest = "$env:TEMP\node_install.msi"
                (New-Object System.Net.WebClient).DownloadFile($Url, $Dest)
                Start-Process "msiexec.exe" -ArgumentList "/i `"$Dest`" /quiet /norestart" -Wait
                
                # Refresh path environment
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                [System.Windows.Forms.MessageBox]::Show("Da cai Node.js. Vui long KHOI DONG LAI TOOL de nhan dien.", "Canh bao")
                $Form.Close(); return 
            } catch { [System.Windows.Forms.MessageBox]::Show("Loi cai Node: $($_.Exception.Message)", "Error") }
        }
    }

    # 2. Cai Gemini CLI qua NPM
    if ($Global:NodeReady) {
        try {
            Start-Process "npm" -ArgumentList "install -g @google/gemini-cli@latest" -NoNewWindow -Wait
            [System.Windows.Forms.MessageBox]::Show("DA CAI DAT GEMINI CLI THANH CONG!", "Success")
            Check-Env
        } catch { [System.Windows.Forms.MessageBox]::Show("Loi NPM: $($_.Exception.Message)", "Error") }
    }
    $Form.Cursor = "Default"
})

$BtnLaunch.Add_Click({
    # Chay lenh gemini trong cua so rieng
    try {
        Start-Process "gemini" 
        $Form.Close()
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Khong the khoi dong Gemini. Thu chay lenh 'gemini' trong CMD.", "Error")
    }
})

$Form.Add_Shown({ Check-Env })
$Form.ShowDialog() | Out-Null
