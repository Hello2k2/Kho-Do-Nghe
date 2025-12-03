<#
    TOOL CUU HO MAY TINH - PHAT TAN PC
    Author:  Phat Tan
    Version: 11.0 (Professional UI - Dashboard Style)
    Github:  https://github.com/Hello2k2/Kho-Do-Nghe
#>

# --- KHỞI TẠO ---
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- CẤU HÌNH ---
$BaseUrl = "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/"
$RawUrl  = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/"
$JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/apps.json"
$TempDir = "$env:TEMP\PhatTan_Tool"
if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir | Out-Null }

# Tối ưu mạng
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::DefaultConnectionLimit = 1000

# --- THEME ENGINE (MÀU SẮC) ---
$Theme = @{
    Dark = @{
        BgForm = [System.Drawing.Color]::FromArgb(30, 30, 30)
        BgSide = [System.Drawing.Color]::FromArgb(45, 45, 48)
        BgPanel= [System.Drawing.Color]::FromArgb(40, 40, 40)
        FgText = [System.Drawing.Color]::White
        BtnBg  = [System.Drawing.Color]::FromArgb(60, 60, 60)
        BtnFg  = [System.Drawing.Color]::White
        Accent = [System.Drawing.Color]::DeepSkyBlue
    }
    Light = @{
        BgForm = [System.Drawing.Color]::WhiteSmoke
        BgSide = [System.Drawing.Color]::FromArgb(230, 230, 230)
        BgPanel= [System.Drawing.Color]::White
        FgText = [System.Drawing.Color]::Black
        BtnBg  = [System.Drawing.Color]::FromArgb(220, 220, 220)
        BtnFg  = [System.Drawing.Color]::Black
        Accent = [System.Drawing.Color]::DodgerBlue
    }
}
$CurrentTheme = $Theme.Dark # Mặc định Dark Mode

# --- HÀM LOGIC ---
function Log-Msg ($Msg) { Write-Host " $Msg" -ForegroundColor Cyan }

function Tai-Va-Chay {
    param ($Link, $Name, $Type, $RawLink="")
    if ($RawLink -match "^http") { $Url = $RawLink } elseif ($Link -match "^http") { $Url = $Link } else { $Url = "$BaseUrl$Link" }
    $Dest = "$TempDir\$Name"
    try {
        (New-Object System.Net.WebClient).DownloadFile($Url, $Dest)
        if (Test-Path $Dest) {
            if ($Type -eq "Msi") { Start-Process "msiexec.exe" "/i `"$Dest`" /quiet /norestart" -Wait }
            else { Start-Process $Dest -Wait }
        }
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi tai: $Name", "Error") }
}

function Load-Module ($Name) {
    $Path = "$TempDir\$Name"
    try { Invoke-WebRequest "$RawUrl$Name" -OutFile $Path; Start-Process powershell "-Ex Bypass -File `"$Path`"" } catch {}
}

# --- TẢI JSON ---
try {
    $Ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $AppData = Invoke-RestMethod -Uri "$($JsonUrl.Trim())?t=$Ts" -Headers @{"Cache-Control"="no-cache"} -ErrorAction Stop
} catch { $AppData = @() }

# --- GUI MAIN ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "PHAT TAN PC - TOOLKIT V11.0 PRO"
$Form.Size = New-Object System.Drawing.Size(1100, 700)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

# 1. SIDEBAR (THANH BÊN TRÁI)
$SidePanel = New-Object System.Windows.Forms.Panel
$SidePanel.Dock = "Left"; $SidePanel.Width = 220
$Form.Controls.Add($SidePanel)

# Logo
$LblLogo = New-Object System.Windows.Forms.Label
$LblLogo.Text = "PHAT TAN`nTOOLKIT"; $LblLogo.Font = "Segoe UI, 16, Bold"
$LblLogo.AutoSize = $false; $LblLogo.Size = "220, 80"; $LblLogo.TextAlign = "MiddleCenter"
$SidePanel.Controls.Add($LblLogo)

# Menu Buttons Container
$MenuFlow = New-Object System.Windows.Forms.FlowLayoutPanel
$MenuFlow.Location = "0, 90"; $MenuFlow.Size = "220, 500"; $MenuFlow.FlowDirection = "TopDown"
$SidePanel.Controls.Add($MenuFlow)

# Dark Mode Toggle
$BtnTheme = New-Object System.Windows.Forms.Button
$BtnTheme.Text = "🌙 Dark Mode"; $BtnTheme.Size = "180, 40"; $BtnTheme.Location = "20, 600"; $BtnTheme.FlatStyle = "Flat"
$SidePanel.Controls.Add($BtnTheme)

# 2. MAIN CONTENT (BÊN PHẢI)
$MainPanel = New-Object System.Windows.Forms.Panel
$MainPanel.Dock = "Fill"
$Form.Controls.Add($MainPanel)

# Header Title in Main
$LblHeader = New-Object System.Windows.Forms.Label
$LblHeader.Text = "Dashboard"; $LblHeader.Font = "Segoe UI, 14, Bold"; $LblHeader.Location = "20, 20"; $LblHeader.AutoSize = $true
$MainPanel.Controls.Add($LblHeader)

# Content Container (Sẽ thay đổi nội dung)
$ContentBox = New-Object System.Windows.Forms.Panel
$ContentBox.Location = "20, 60"; $ContentBox.Size = "830, 580"; $ContentBox.AutoScroll = $true
$MainPanel.Controls.Add($ContentBox)

# --- HELPER UI FUNCTIONS ---

# Tạo nút Menu bên trái
function Add-MenuBtn ($Txt, $Tag) {
    $B = New-Object System.Windows.Forms.Button
    $B.Text = "  $Txt"; $B.Size = "220, 50"; $B.FlatStyle = "Flat"; $B.TextAlign = "MiddleLeft"; $B.Tag = $Tag; $B.FlatAppearance.BorderSize = 0
    $B.Font = "Segoe UI, 11"; $B.Cursor = "Hand"
    $B.Add_Click({ Switch-View $this.Tag $this })
    $MenuFlow.Controls.Add($B)
    return $B
}

# Tạo GroupBox chứa nút trong phần Advanced
function Add-Group ($Title) {
    $G = New-Object System.Windows.Forms.GroupBox
    $G.Text = $Title; $G.Size = "800, 10"; $G.AutoSize = $true; $G.Margin = "0,0,0,20"
    $G.Font = "Segoe UI, 11, Bold"
    
    $Flow = New-Object System.Windows.Forms.FlowLayoutPanel
    $Flow.Dock = "Fill"; $Flow.AutoSize = $true; $Flow.Padding = "10"; $Flow.MaximumSize = "790, 0"
    $G.Controls.Add($Flow)
    $ContentBox.Controls.Add($G)
    return $Flow
}

# Tạo nút chức năng trong Advanced
function Add-ToolBtn ($Panel, $Txt, $Color, $Cmd) {
    $B = New-Object System.Windows.Forms.Button
    $B.Text = $Txt; $B.Size = "180, 45"; $B.Margin = "5"; $B.FlatStyle = "Flat"
    $B.BackColor = $Color; $B.ForeColor = "White"; if($Color -eq "Yellow" -or $Color -eq "Orange"){$B.ForeColor="Black"}
    $B.Font = "Segoe UI, 9"; $B.Add_Click($Cmd)
    $Panel.Controls.Add($B)
}

# --- VIEW CONTROLLER ---
function Switch-View ($ViewName, $BtnSender) {
    $ContentBox.Controls.Clear()
    $LblHeader.Text = $ViewName
    
    # Highlight Active Button
    foreach($c in $MenuFlow.Controls){ $c.BackColor = $CurrentTheme.BgSide }
    if($BtnSender){ $BtnSender.BackColor = $CurrentTheme.Accent }

    # === VIEW 1: SOFTWARE INSTALLER ===
    if ($ViewName -eq "SOFTWARE INSTALLER") {
        # Tạo Tabs con cho App
        $TabSoft = New-Object System.Windows.Forms.TabControl; $TabSoft.Dock="Fill"
        $TabNames = $AppData | Select -Expand tab -Unique
        foreach($T in $TabNames) {
            $P = New-Object System.Windows.Forms.TabPage; $P.Text = $T; $P.AutoScroll=$true
            $P.BackColor = $CurrentTheme.BgPanel; $P.ForeColor = $CurrentTheme.FgText
            $Apps = $AppData | ? {$_.tab -eq $T}
            $Y=20
            foreach($A in $Apps) {
                $C = New-Object System.Windows.Forms.CheckBox; $C.Text=$A.name; $C.Tag=$A; $C.Location="30,$Y"; $C.AutoSize=$true; $C.Font="Segoe UI, 11"
                $P.Controls.Add($C); $Y+=35
            }
            $TabSoft.Controls.Add($P)
        }
        $ContentBox.Controls.Add($TabSoft)
        
        # Nút Install
        $PnlBot = New-Object System.Windows.Forms.Panel; $PnlBot.Dock="Bottom"; $PnlBot.Height=60
        $BtnRun = New-Object System.Windows.Forms.Button; $BtnRun.Text="CAI DAT DA CHON"; $BtnRun.Dock="Right"; $BtnRun.Width=200
        $BtnRun.BackColor="Green"; $BtnRun.ForeColor="White"; $BtnRun.Font="Segoe UI, 10, Bold"
        $BtnRun.Add_Click({ 
            foreach($tp in $TabSoft.TabPages){ foreach($c in $tp.Controls){ if($c.Checked){ 
                $i=$c.Tag; if($i.type -eq "Script"){iex $i.irm}else{Tai-Va-Chay $i.link $i.filename $i.type; if($i.irm){iex $i.irm}}
                $c.Checked=$false 
            }}}
            [System.Windows.Forms.MessageBox]::Show("Xong!", "Info")
        })
        $PnlBot.Controls.Add($BtnRun); $ContentBox.Controls.Add($PnlBot)
    }

    # === VIEW 2: ADVANCED TOOLS (DASHBOARD) ===
    if ($ViewName -eq "ADVANCED TOOLS") {
        # Dùng FlowLayout để tự sắp xếp nút (Không cần tọa độ)
        $ContentBox.AutoScroll = $true

        # Group 1: System
        $G1 = Add-Group "1. SYSTEM & MAINTENANCE"
        Add-ToolBtn $G1 "INFO & DRIVER" "Purple" { Load-Module "SystemInfo.ps1" }
        Add-ToolBtn $G1 "SCAN SYSTEM (SFC)" "Orange" { Load-Module "SystemScan.ps1" }
        Add-ToolBtn $G1 "CLEANER PRO" "Green" { Load-Module "SystemCleaner.ps1" }
        Add-ToolBtn $G1 "RAM BOOSTER" "DarkGoldenrod" { Load-Module "RamBooster.ps1" }
        Add-ToolBtn $G1 "DATA RECOVERY" "Red" { Tai-Va-Chay "Disk.Genius.rar" "DiskGenius.rar" "Portable" }

        # Group 2: Security
        $G2 = Add-Group "2. SECURITY & NETWORK"
        Add-ToolBtn $G2 "NETWORK MASTER" "Teal" { Load-Module "NetworkMaster.ps1" }
        Add-ToolBtn $G2 "WIN UPDATE MGR" "Firebrick" { Load-Module "WinUpdatePro.ps1" }
        Add-ToolBtn $G2 "DEFENDER CONTROL" "DarkSlateBlue" { Load-Module "DefenderMgr.ps1" }
        Add-ToolBtn $G2 "BITLOCKER MGR" "Gold" { Load-Module "BitLockerMgr.ps1" }
        Add-ToolBtn $G2 "BROWSER PRIVACY" "DarkRed" { Load-Module "BrowserPrivacy.ps1" }

        # Group 3: Deployment
        $G3 = Add-Group "3. DEPLOYMENT & UTILITIES"
        Add-ToolBtn $G3 "AUTO INSTALL WIN" "Pink" { Load-Module "WinInstall.ps1" }
        Add-ToolBtn $G3 "WIN AIO BUILDER" "OrangeRed" { Load-Module "WinAIOBuilder.ps1" }
        Add-ToolBtn $G3 "WIN MODDER STUDIO" "OrangeRed" { Load-Module "WinModder.ps1" }
        Add-ToolBtn $G3 "ISO DOWNLOADER" "Yellow" { Load-Module "ISODownloader.ps1" }
        Add-ToolBtn $G3 "LTSC STORE" "DeepSkyBlue" { Load-Module "StoreInstaller.ps1" }
        Add-ToolBtn $G3 "BACKUP CENTER" "Cyan" { Load-Module "BackupCenter.ps1" }
        Add-ToolBtn $G3 "APP STORE (WINGET)" "LightGreen" { Load-Module "AppStore.ps1" }
        Add-ToolBtn $G3 "GEMINI AI" "DeepPink" { Load-Module "GeminiAI.ps1" }
    }

    # === VIEW 3: UTILITIES ===
    if ($ViewName -eq "QUICK UTILITIES") {
         $G4 = Add-Group "QUICK ACTIONS"
         Add-ToolBtn $G4 "ACTIVE WINDOWS" "Magenta" { irm https://get.activated.win | iex }
         Add-ToolBtn $G4 "WINPE RESCUE" "Yellow" { Tai-Va-Chay "WinPE_CuuHo.exe" "WinPE_Setup.exe" "Portable" }
         Add-ToolBtn $G4 "DONATE INFO" "Gold" { 
            $F=New-Object System.Windows.Forms.Form; $F.Size="400,500"; $F.StartPosition="CenterScreen"
            $P=New-Object System.Windows.Forms.PictureBox; $P.Dock="Fill"; $P.SizeMode="Zoom"
            try{$P.Load("https://img.vietqr.io/image/970436-1055835227-print.png?addInfo=Donate%20PhatTanPC&accountName=DANG%20LAM%20TAN%20PHAT")}catch{}
            $F.Controls.Add($P); $F.ShowDialog()
         }
    }
    
    Apply-Theme # Apply màu cho các control vừa tạo
}

# --- THEME FUNCTION ---
function Apply-Theme {
    $Form.BackColor = $CurrentTheme.BgForm
    $SidePanel.BackColor = $CurrentTheme.BgSide
    $MainPanel.BackColor = $CurrentTheme.BgForm
    $ContentBox.BackColor = $CurrentTheme.BgForm
    
    $LblLogo.ForeColor = $CurrentTheme.Accent
    $LblHeader.ForeColor = $CurrentTheme.FgText
    
    # Update Menu Buttons
    foreach ($c in $MenuFlow.Controls) { $c.ForeColor = $CurrentTheme.FgText }
    
    # Update GroupBoxes
    foreach ($c in $ContentBox.Controls) {
        if ($c -is [System.Windows.Forms.GroupBox]) {
            $c.ForeColor = $CurrentTheme.Accent
            foreach ($sub in $c.Controls) { # FlowPanel
               # Buttons inside flow panel already have colors set, don't overwrite bg
            }
        }
    }
}

$BtnTheme.Add_Click({
    if ($BtnTheme.Text -match "Dark") {
        $Global:CurrentTheme = $Theme.Light
        $BtnTheme.Text = "☀️ Light Mode"
    } else {
        $Global:CurrentTheme = $Theme.Dark
        $BtnTheme.Text = "🌙 Dark Mode"
    }
    Apply-Theme
    # Refresh current view coloring
    foreach($c in $MenuFlow.Controls){ if($c.Text -match $LblHeader.Text){ $c.BackColor = $CurrentTheme.Accent } else { $c.BackColor = $CurrentTheme.BgSide } }
})

# --- INIT ---
$Btn1 = Add-MenuBtn "SOFTWARE INSTALLER" "SOFTWARE INSTALLER"
$Btn2 = Add-MenuBtn "ADVANCED TOOLS" "ADVANCED TOOLS"
$Btn3 = Add-MenuBtn "QUICK UTILITIES" "QUICK UTILITIES"

# Default View
Switch-View "SOFTWARE INSTALLER" $Btn1
Apply-Theme

$Form.ShowDialog() | Out-Null
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
