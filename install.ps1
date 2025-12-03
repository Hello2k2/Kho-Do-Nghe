<#
    TOOL CUU HO MAY TINH - PHAT TAN PC
    Author:  Phat Tan
    Version: 10.0 (Professional Edition)
    Github:  https://github.com/Hello2k2/Kho-Do-Nghe
#>

# --- 1. ADMIN CHECK ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- 2. INIT & CONFIG ---
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

$BaseUrl = "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/"
$RawUrl  = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/"
$JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/apps.json"
$TempDir = "$env:TEMP\PhatTan_Tool"
if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null }

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# --- 3. THEME ENGINE (DARK/LIGHT) ---
$Global:DarkMode = $true 

# Bảng màu (Palette)
$Theme = @{
    Dark = @{
        Back = [System.Drawing.Color]::FromArgb(32, 33, 36)
        Panel = [System.Drawing.Color]::FromArgb(45, 45, 48)
        Text = [System.Drawing.Color]::White
        BtnBack = [System.Drawing.Color]::FromArgb(60, 60, 60)
        BtnHover = [System.Drawing.Color]::FromArgb(80, 80, 80)
        Accent = [System.Drawing.Color]::Cyan
        Group = [System.Drawing.Color]::FromArgb(255, 215, 0) # Gold
    }
    Light = @{
        Back = [System.Drawing.Color]::FromArgb(240, 240, 240)
        Panel = [System.Drawing.Color]::White
        Text = [System.Drawing.Color]::Black
        BtnBack = [System.Drawing.Color]::FromArgb(225, 225, 225)
        BtnHover = [System.Drawing.Color]::FromArgb(200, 200, 200)
        Accent = [System.Drawing.Color]::FromArgb(0, 120, 215) # Blue Win10
        Group = [System.Drawing.Color]::FromArgb(0, 100, 0) # Dark Green
    }
}

function Apply-Theme {
    $T = if ($Global:DarkMode) { $Theme.Dark } else { $Theme.Light }
    
    $Form.BackColor = $T.Back
    $Form.ForeColor = $T.Text
    $LblTitle.ForeColor = $T.Accent
    
    # Update Tabs
    foreach ($P in $TabControl.TabPages) {
        $P.BackColor = $T.Panel
        $P.ForeColor = $T.Text
        
        # Update Checkboxes & GroupBox
        foreach ($C in $P.Controls) {
            if ($C -is [System.Windows.Forms.CheckBox]) { $C.ForeColor = $T.Text }
            if ($C -is [System.Windows.Forms.GroupBox]) { 
                $C.ForeColor = $T.Group
                foreach ($GC in $C.Controls) {
                     if ($GC -is [System.Windows.Forms.Button]) {
                        $GC.BackColor = $T.BtnBack
                        $GC.ForeColor = $T.Text
                     }
                }
            }
        }
    }
    
    # Update Footer Buttons (Trừ nút Install màu xanh lá)
    $BtnSelectAll.BackColor = $T.BtnBack; $BtnSelectAll.ForeColor = $T.Text
    $BtnUncheck.BackColor = $T.BtnBack; $BtnUncheck.ForeColor = $T.Text
    $BtnTheme.Text = if ($Global:DarkMode) { "☀ LIGHT MODE" } else { "🌙 DARK MODE" }
    $BtnTheme.BackColor = if ($Global:DarkMode) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::Black }
    $BtnTheme.ForeColor = if ($Global:DarkMode) { [System.Drawing.Color]::Black } else { [System.Drawing.Color]::White }
}

# --- 4. CORE FUNCTIONS ---
function Log-Msg ($Msg) { Write-Host " $Msg" -ForegroundColor Cyan }

function Tai-Va-Chay {
    param ($Link, $Name, $Type)
    if ($Link -notmatch "^http") { $Link = "$BaseUrl$Link" }
    $Dest = "$TempDir\$Name"
    try {
        (New-Object System.Net.WebClient).DownloadFile($Link, $Dest)
        if (Test-Path $Dest) {
            if ($Type -eq "Msi") { Start-Process "msiexec.exe" "/i `"$Dest`" /quiet /norestart" -Wait }
            else { Start-Process $Dest -Wait }
        }
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi download: $Name", "Error") }
}

function Load-Module ($Name) {
    $Dest = "$TempDir\$Name"
    try { Invoke-WebRequest "$RawUrl$Name" -OutFile $Dest; Start-Process powershell "-Ex Bypass -File `"$Dest`"" } catch {}
}

# --- 5. DATA LOADING ---
try {
    $Ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $Data = Invoke-RestMethod -Uri "$($JsonUrl.Trim())?t=$Ts" -Headers @{"User-Agent"="PS";"Cache-Control"="no-cache"} -ErrorAction Stop
} catch { $Data = @() }

# --- 6. GUI CONSTRUCTION ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "PHAT TAN PC TOOLKIT V10.0 (PROFESSIONAL)"
$Form.Size = New-Object System.Drawing.Size(1000, 750) # Form rộng hơn
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header Area
$LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text="PHAT TAN PC TOOLKIT"; $LblTitle.Font="Segoe UI, 20, Bold"; $LblTitle.AutoSize=$true; $LblTitle.Location="20,10"; $Form.Controls.Add($LblTitle)
$LblSub = New-Object System.Windows.Forms.Label; $LblSub.Text="Professional IT Rescue Suite"; $LblSub.ForeColor="Gray"; $LblSub.AutoSize=$true; $LblSub.Location="25,50"; $Form.Controls.Add($LblSub)

# Theme Toggle Button
$BtnTheme = New-Object System.Windows.Forms.Button; $BtnTheme.Location="830,20"; $BtnTheme.Size="120,35"; $BtnTheme.FlatStyle="Flat"
$BtnTheme.Add_Click({ $Global:DarkMode = -not $Global:DarkMode; Apply-Theme })
$Form.Controls.Add($BtnTheme)

# MAIN TAB CONTROL
$TabControl = New-Object System.Windows.Forms.TabControl; $TabControl.Location="20,90"; $TabControl.Size="940,480"; $TabControl.Font="Segoe UI, 10"
$Form.Controls.Add($TabControl)

# > GENERATE JSON TABS
$Tabs = $Data | Select -Expand tab -Unique
foreach ($T in $Tabs) {
    $Page = New-Object System.Windows.Forms.TabPage; $Page.Text = "  $T  "; $Page.AutoScroll = $true
    $TabControl.Controls.Add($Page)
    
    $Apps = $Data | Where {$_.tab -eq $T}
    $Flow = New-Object System.Windows.Forms.FlowLayoutPanel; $Flow.Dock="Fill"; $Flow.AutoScroll=$true; $Flow.Padding="20,20,20,20"
    $Page.Controls.Add($Flow)
    
    foreach ($A in $Apps) {
        $Chk = New-Object System.Windows.Forms.CheckBox; $Chk.Text=$A.name; $Chk.Tag=$A; $Chk.AutoSize=$true; $Chk.Margin="10,10,20,10"; $Chk.Font="Segoe UI, 11"
        $Flow.Controls.Add($Chk)
    }
}

# > ADVANCED TOOLS TAB (NEW LAYOUT)
$AdvTab = New-Object System.Windows.Forms.TabPage; $AdvTab.Text = "  ADVANCED MODULES  "; $AdvTab.AutoScroll = $true
$TabControl.Controls.Add($AdvTab)

# Helper tạo GroupBox và Button
function Add-Group ($Title, $X, $Y, $H) {
    $G = New-Object System.Windows.Forms.GroupBox; $G.Text=$Title; $G.Location="$X,$Y"; $G.Size="290,$H"; $G.Font="Segoe UI, 10, Bold"
    $AdvTab.Controls.Add($G); return $G
}
function Add-ModBtn ($Parent, $Txt, $Y, $Cmd) {
    $B = New-Object System.Windows.Forms.Button; $B.Text=$Txt; $B.Location="15,$Y"; $B.Size="260,40"; $B.FlatStyle="Flat"; $B.Font="Segoe UI, 9"
    $B.Add_Click($Cmd); $Parent.Controls.Add($B)
}

# CỘT 1: SYSTEM (X=15)
$G1 = Add-Group "SYSTEM & MAINTENANCE" 15 20 420
Add-ModBtn $G1 "CHECK INFO & DRIVER" 30 { Load-Module "SystemInfo.ps1" }
Add-ModBtn $G1 "SYSTEM SCAN (SFC/DISM)" 80 { Load-Module "SystemScan.ps1" }
Add-ModBtn $G1 "SYSTEM CLEANER PRO" 130 { Load-Module "SystemCleaner.ps1" }
Add-ModBtn $G1 "RAM BOOSTER (OPTIMIZE)" 180 { Load-Module "RamBooster.ps1" }
Add-ModBtn $G1 "ACTIVE WINDOWS/OFFICE" 230 { irm https://get.activated.win | iex }
Add-ModBtn $G1 "DATA RECOVERY (HDD)" 280 { Tai-Va-Chay "Disk.Genius.rar" "DiskGenius.rar" "Portable" }

# CỘT 2: SECURITY (X=325)
$G2 = Add-Group "SECURITY & NETWORK" 325 20 420
Add-ModBtn $G2 "NETWORK MASTER (DNS)" 30 { Load-Module "NetworkMaster.ps1" }
Add-ModBtn $G2 "WIN UPDATE MANAGER" 80 { Load-Module "WinUpdatePro.ps1" }
Add-ModBtn $G2 "DEFENDER CONTROL" 130 { Load-Module "DefenderMgr.ps1" }
Add-ModBtn $G2 "BITLOCKER MANAGER" 180 { Load-Module "BitLockerMgr.ps1" }
Add-ModBtn $G2 "BROWSER PRIVACY" 230 { Load-Module "BrowserPrivacy.ps1" }

# CỘT 3: DEPLOYMENT & AI (X=635)
$G3 = Add-Group "DEPLOYMENT & AI TOOLS" 635 20 420
Add-ModBtn $G3 "AUTO INSTALL WINDOWS" 30 { Load-Module "WinInstall.ps1" }
Add-ModBtn $G3 "WIN MODDER STUDIO (EDIT ISO)" 80 { Load-Module "WinModder.ps1" }
Add-ModBtn $G3 "WIN AIO BUILDER (MERGE)" 130 { Load-Module "WinAIOBuilder.ps1" }
Add-ModBtn $G3 "LTSC STORE INSTALLER" 180 { Load-Module "StoreInstaller.ps1" }
Add-ModBtn $G3 "ISO DOWNLOADER (IDM)" 230 { Load-Module "ISODownloader.ps1" }
Add-ModBtn $G3 "BACKUP & RESTORE PRO" 280 { Load-Module "BackupCenter.ps1" }
Add-ModBtn $G3 "GEMINI AI ASSISTANT (CLI)" 330 { Load-Module "GeminiAI.ps1" }

# --- FOOTER AREA ---
$PnlFooter = New-Object System.Windows.Forms.Panel; $PnlFooter.Location="0,590"; $PnlFooter.Size="1000,120"; $PnlFooter.BackColor=[System.Drawing.Color]::Transparent
$Form.Controls.Add($PnlFooter)

# Select Buttons
$BtnAll = New-Object System.Windows.Forms.Button; $BtnAll.Text="CHON TAT CA"; $BtnAll.Location="30,10"; $BtnAll.Size="120,40"; $BtnAll.FlatStyle="Flat"
$BtnAll.Add_Click({ foreach($P in $TabControl.TabPages){ foreach($C in $P.Controls){ foreach($Ct in $C.Controls){ if($Ct -is [System.Windows.Forms.CheckBox]){$Ct.Checked=$true} } } } })
$PnlFooter.Controls.Add($BtnAll)

$BtnNone = New-Object System.Windows.Forms.Button; $BtnNone.Text="BO CHON"; $BtnNone.Location="160,10"; $BtnNone.Size="120,40"; $BtnNone.FlatStyle="Flat"
$BtnNone.Add_Click({ foreach($P in $TabControl.TabPages){ foreach($C in $P.Controls){ foreach($Ct in $C.Controls){ if($Ct -is [System.Windows.Forms.CheckBox]){$Ct.Checked=$false} } } } })
$PnlFooter.Controls.Add($BtnNone)

# BIG INSTALL BUTTON
$BtnInstall = New-Object System.Windows.Forms.Button; $BtnInstall.Text="TIEN HANH CAI DAT DA CHON"; $BtnInstall.Font="Segoe UI, 14, Bold"
$BtnInstall.Location="350,10"; $BtnInstall.Size="400,60"; $BtnInstall.BackColor="LimeGreen"; $BtnInstall.ForeColor="Black"; $BtnInstall.FlatStyle="Flat"
$BtnInstall.Add_Click({
    $BtnInstall.Enabled=$false; $BtnInstall.Text="DANG XU LY..."
    foreach($P in $TabControl.TabPages){ 
        foreach($F in $P.Controls){ # Check flow panel
            foreach($C in $F.Controls){
                if($C -is [System.Windows.Forms.CheckBox] -and $C.Checked){
                    $I = $C.Tag
                    if($I.type -eq "Script"){ iex $I.irm } else { Tai-Va-Chay $I.link $I.filename $I.type; if($I.irm){ iex $I.irm } }
                    $C.Checked=$false
                }
            }
        } 
    }
    [System.Windows.Forms.MessageBox]::Show("Da Xong!", "Info"); $BtnInstall.Text="TIEN HANH CAI DAT DA CHON"; $BtnInstall.Enabled=$true
})
$PnlFooter.Controls.Add($BtnInstall)

# Mini Links
$BtnPe = New-Object System.Windows.Forms.Button; $BtnPe.Text="WINPE RESCUE"; $BtnPe.Location="780,10"; $BtnPe.Size="120,35"; $BtnPe.BackColor="Orange"; $BtnPe.ForeColor="Black"; $BtnPe.FlatStyle="Flat"
$BtnPe.Add_Click({ Tai-Va-Chay "WinPE_CuuHo.exe" "WinPE_Setup.exe" "Portable" }); $PnlFooter.Controls.Add($BtnPe)

$BtnDonate = New-Object System.Windows.Forms.Button; $BtnDonate.Text="DONATE"; $BtnDonate.Location="780,50"; $BtnDonate.Size="120,35"; $BtnDonate.BackColor="Gold"; $BtnDonate.ForeColor="Black"; $BtnPe.FlatStyle="Flat"
$BtnDonate.Add_Click({ 
    $D=New-Object System.Windows.Forms.Form;$D.Size="400,500";$D.StartPosition="CenterScreen";$P=New-Object System.Windows.Forms.PictureBox;$P.Dock="Fill";$P.SizeMode="Zoom"
    try{$P.Load("https://img.vietqr.io/image/970436-1055835227-print.png?addInfo=Donate%20PhatTanPC&accountName=DANG%20LAM%20TAN%20PHAT")}catch{};$D.Controls.Add($P);$D.ShowDialog() 
}); $PnlFooter.Controls.Add($BtnDonate)

# --- INIT ---
Apply-Theme
$Form.Add_Shown({ Apply-Theme })
$Form.ShowDialog() | Out-Null
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
