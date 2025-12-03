<#
    TOOL CUU HO MAY TINH - PHAT TAN PC
    Version: 11.0 (Professional UI - Dark/Light Mode)
    Github:  https://github.com/Hello2k2/Kho-Do-Nghe
#>

# --- 1. ADMIN CHECK & INIT ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- 2. CONFIG & DATA ---
$JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/apps.json"
$TempDir = "$env:TEMP\PhatTan_Tool"; if (!(Test-Path $TempDir)) { md $TempDir | Out-Null }
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# --- 3. THEME ENGINE (DARK/LIGHT) ---
$Theme = @{
    Dark = @{
        Bg = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1E")
        Fg = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
        PanelBg = [System.Drawing.ColorTranslator]::FromHtml("#252526")
        BtnBg = [System.Drawing.ColorTranslator]::FromHtml("#333333")
        BtnFg = [System.Drawing.ColorTranslator]::FromHtml("#E0E0E0")
        Accent = [System.Drawing.ColorTranslator]::FromHtml("#007ACC") # Xanh VS Code
        Border = [System.Drawing.ColorTranslator]::FromHtml("#3F3F46")
    }
    Light = @{
        Bg = [System.Drawing.ColorTranslator]::FromHtml("#F3F3F3")
        Fg = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1E")
        PanelBg = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
        BtnBg = [System.Drawing.ColorTranslator]::FromHtml("#E1E1E1")
        BtnFg = [System.Drawing.ColorTranslator]::FromHtml("#000000")
        Accent = [System.Drawing.ColorTranslator]::FromHtml("#0078D7") # Xanh Win 10
        Border = [System.Drawing.ColorTranslator]::FromHtml("#CCCCCC")
    }
}
$CurrentMode = "Dark" # Mac dinh

function Apply-Theme {
    param($Mode)
    $C = $Theme[$Mode]
    $Form.BackColor = $C.Bg; $Form.ForeColor = $C.Fg
    
    # Update TabControl
    foreach ($Page in $TabControl.TabPages) { $Page.BackColor = $C.PanelBg; $Page.ForeColor = $C.Fg }
    
    # Update Buttons (Tru nut Install/Launch mau xanh)
    $AllBtns = $Form.Controls.Find("BtnModule", $true)
    foreach ($Btn in $AllBtns) { $Btn.BackColor = $C.BtnBg; $Btn.ForeColor = $C.BtnFg }
    
    # Update Checkboxes
    $AllChks = $Form.Controls.Find("AppChk", $true)
    foreach ($Chk in $AllChks) { $Chk.ForeColor = $C.Fg }
    
    # Update GroupBox/Labels
    $Lbls = $Form.Controls.Find("HeaderLbl", $true)
    foreach ($L in $Lbls) { $L.ForeColor = $C.Accent }
}

# --- 4. DATA LOADING ---
try {
    $Ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $AppData = Invoke-RestMethod -Uri "$($JsonUrl.Trim())?t=$Ts" -Headers @{"Cache-Control"="no-cache"} -ErrorAction Stop
} catch { [System.Windows.Forms.MessageBox]::Show("Loi tai Data: $($_.Exception.Message)", "Error"); Exit }

# --- 5. GUI CONSTRUCTION ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "PHAT TAN PC - TOOLKIT V11.0 PRO"
$Form.Size = New-Object System.Drawing.Size(1000, 700)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header Area
$PnlHead = New-Object System.Windows.Forms.Panel; $PnlHead.Dock = "Top"; $PnlHead.Height = 60; $Form.Controls.Add($PnlHead)
$LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text = "PHAT TAN TOOLKIT"; $LblTitle.Font = "Segoe UI, 18, Bold"; $LblTitle.ForeColor = $Theme.Dark.Accent; $LblTitle.AutoSize = $true; $LblTitle.Location = "15, 10"; $PnlHead.Controls.Add($LblTitle)
$LblSub = New-Object System.Windows.Forms.Label; $LblSub.Text = "Professional IT Solutions"; $LblSub.Font = "Segoe UI, 10"; $LblSub.ForeColor = "Gray"; $LblSub.AutoSize = $true; $LblSub.Location = "20, 40"; $PnlHead.Controls.Add($LblSub)

# Footer Area (Bottom)
$PnlBot = New-Object System.Windows.Forms.Panel; $PnlBot.Dock = "Bottom"; $PnlBot.Height = 70; $Form.Controls.Add($PnlBot)

# Tab Control
$TabControl = New-Object System.Windows.Forms.TabControl; $TabControl.Dock = "Fill"; $Form.Controls.Add($TabControl)

# === TAB 1: INSTALL APPS (AUTO LAYOUT) ===
# Tao cac Tab con dua tren JSON
$TabNames = $AppData | Select-Object -ExpandProperty tab -Unique
foreach ($TName in $TabNames) {
    $Page = New-Object System.Windows.Forms.TabPage; $Page.Text = "  $TName  "
    $TabControl.Controls.Add($Page)
    
    # Dung FlowLayoutPanel de tu dong dan trang
    $Flow = New-Object System.Windows.Forms.FlowLayoutPanel; $Flow.Dock = "Fill"; $Flow.AutoScroll = $true; $Flow.Padding = "20,20,20,20"
    $Page.Controls.Add($Flow)
    
    $Apps = $AppData | Where-Object { $_.tab -eq $TName }
    foreach ($App in $Apps) {
        $Chk = New-Object System.Windows.Forms.CheckBox; $Chk.Text = $App.name; $Chk.Tag = $App; $Chk.Name = "AppChk"
        $Chk.AutoSize = $false; $Chk.Size = "280, 30"; $Chk.Font = "Segoe UI, 11"
        $Flow.Controls.Add($Chk)
    }
}

# === TAB 2: ADVANCED MODULES (3 COLUMNS) ===
$AdvTab = New-Object System.Windows.Forms.TabPage; $AdvTab.Text = "  ADVANCED TOOLS  "; $TabControl.Controls.Add($AdvTab)
$AdvGrid = New-Object System.Windows.Forms.TableLayoutPanel; $AdvGrid.Dock = "Fill"; $AdvGrid.ColumnCount = 3; $AdvGrid.RowCount = 1
$AdvGrid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33.33))) | Out-Null
$AdvGrid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33.33))) | Out-Null
$AdvGrid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33.33))) | Out-Null
$AdvTab.Controls.Add($AdvGrid)

# Ham tao Panel cot
function Make-Col ($Title, $ColIndex) {
    $P = New-Object System.Windows.Forms.FlowLayoutPanel; $P.Dock = "Fill"; $P.FlowDirection = "TopDown"; $P.Padding = "10,10,10,10"; $P.AutoSize = $true
    $H = New-Object System.Windows.Forms.Label; $H.Text = $Title; $H.AutoSize = $true; $H.Font = "Segoe UI, 11, Bold"; $H.Margin = "0,0,0,15"; $H.Name = "HeaderLbl"
    $P.Controls.Add($H)
    $AdvGrid.Controls.Add($P, $ColIndex, 0)
    return $P
}

# Ham tao Nut Module
function Add-Mod ($Panel, $Txt, $CmdName) {
    $B = New-Object System.Windows.Forms.Button; $B.Text = $Txt; $B.Name = "BtnModule"
    $B.Size = "280, 45"; $B.FlatStyle = "Flat"; $B.FlatAppearance.BorderSize = 0; $B.Font = "Segoe UI, 9, Bold"; $B.TextAlign = "MiddleLeft"; $B.Padding = "15,0,0,0"
    $B.Cursor = "Hand"; $B.Margin = "0,0,0,10"
    
    # Logic Load Module
    $B.Add_Click({ 
        $Script = "$TempDir\$CmdName"
        Write-Host "Loading: $CmdName..."
        try { Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/$CmdName" -OutFile $Script; Start-Process powershell "-Ex Bypass -File `"$Script`"" } catch {}
    })
    $Panel.Controls.Add($B)
}

# --- CỘT 1: HỆ THỐNG ---
$Col1 = Make-Col "SYSTEM & MAINTENANCE" 0
Add-Mod $Col1 "CHECK INFO & DRIVER" "SystemInfo.ps1"
Add-Mod $Col1 "SYSTEM SCAN (SFC/DISM)" "SystemScan.ps1"
Add-Mod $Col1 "SYSTEM CLEANER PRO" "SystemCleaner.ps1"
Add-Mod $Col1 "DATA RECOVERY (HDD)" "DiskRecovery.ps1" # (Gia lap)

# --- CỘT 2: BẢO MẬT & MẠNG ---
$Col2 = Make-Col "SECURITY & NETWORK" 1
Add-Mod $Col2 "NETWORK MASTER (DNS)" "NetworkMaster.ps1"
Add-Mod $Col2 "WIN UPDATE CONTROL" "WinUpdatePro.ps1"
Add-Mod $Col2 "DEFENDER CONTROL" "DefenderMgr.ps1"
Add-Mod $Col2 "BITLOCKER MANAGER" "BitLockerMgr.ps1"
Add-Mod $Col2 "BROWSER PRIVACY" "BrowserPrivacy.ps1"

# --- CỘT 3: CÔNG CỤ & AI ---
$Col3 = Make-Col "DEPLOYMENT & AI" 2
Add-Mod $Col3 "WIN INSTALLER (AUTO)" "WinInstall.ps1"
Add-Mod $Col3 "WIN AIO BUILDER" "WinAIOBuilder.ps1"
Add-Mod $Col3 "WIN MODDER STUDIO" "WinModder.ps1"
Add-Mod $Col3 "ISO DOWNLOADER (TURBO)" "ISODownloader.ps1"
Add-Mod $Col3 "BACKUP & RESTORE" "BackupCenter.ps1"
Add-Mod $Col3 "APP STORE (WINGET)" "AppStore.ps1"
Add-Mod $Col3 "GEMINI AI ASSISTANT" "GeminiAI.ps1"

# === FOOTER CONTROLS ===

# 1. Dark/Light Mode Switch
$BtnTheme = New-Object System.Windows.Forms.CheckBox; $BtnTheme.Appearance = "Button"; $BtnTheme.Text = "🌙 DARK MODE"; $BtnTheme.Location = "20, 20"; $BtnTheme.Size = "120, 35"
$BtnTheme.TextAlign = "MiddleCenter"; $BtnTheme.Checked = $true; $BtnTheme.FlatStyle = "Flat"; $BtnTheme.BackColor = "Black"; $BtnTheme.ForeColor = "Gold"
$BtnTheme.Add_CheckedChanged({
    if ($BtnTheme.Checked) { $Global:CurrentMode = "Dark"; $BtnTheme.Text = "🌙 DARK MODE"; $BtnTheme.BackColor = "Black"; $BtnTheme.ForeColor = "Gold" }
    else { $Global:CurrentMode = "Light"; $BtnTheme.Text = "☀ LIGHT MODE"; $BtnTheme.BackColor = "White"; $BtnTheme.ForeColor = "Orange" }
    Apply-Theme $Global:CurrentMode
})
$PnlBot.Controls.Add($BtnTheme)

# 2. Mini Tools (Active Win, v.v)
$BtnActive = New-Object System.Windows.Forms.Button; $BtnActive.Text = "ACTIVE WIN"; $BtnActive.Location = "160, 20"; $BtnActive.Size = "110, 35"; $BtnActive.FlatStyle="Flat"; $BtnActive.BackColor="Purple"; $BtnActive.ForeColor="White"
$BtnActive.Add_Click({ irm https://get.activated.win | iex }); $PnlBot.Controls.Add($BtnActive)

# 3. Action Buttons (Right Side)
$BtnInstall = New-Object System.Windows.Forms.Button; $BtnInstall.Text = "START INSTALL"; $BtnInstall.Font = "Segoe UI, 11, Bold"
$BtnInstall.Size = "200, 45"; $BtnInstall.Location = "760, 15"; $BtnInstall.BackColor = $Theme.Dark.Accent; $BtnInstall.ForeColor = "White"; $BtnInstall.FlatStyle = "Flat"
$PnlBot.Controls.Add($BtnInstall)

$BtnSelect = New-Object System.Windows.Forms.Button; $BtnSelect.Text = "Select All"; $BtnSelect.Location = "650, 20"; $BtnSelect.Size = "100, 35"; $BtnSelect.FlatStyle="Flat"; $BtnSelect.Name="BtnModule"
$PnlBot.Controls.Add($BtnSelect)

# Logic Install
$BtnInstall.Add_Click({
    $BtnInstall.Enabled=$false; $BtnInstall.Text="Processing..."
    foreach ($P in $TabControl.TabPages) {
        $Chks = $P.Controls[0].Controls | Where {$_.GetType().Name -eq "CheckBox"}
        foreach ($C in $Chks) {
            if ($C.Checked) {
                $Item = $C.Tag
                if ($Item.type -eq "Script") { Invoke-Expression $Item.irm }
                else { 
                    # Ham tai file co ban
                    $Dest = "$TempDir\$($Item.filename)"; (New-Object System.Net.WebClient).DownloadFile($Item.link, $Dest); Start-Process $Dest -Wait
                }
                $C.Checked = $false
            }
        }
    }
    $BtnInstall.Text="DONE!"; Start-Sleep 1; $BtnInstall.Text="START INSTALL"; $BtnInstall.Enabled=$true
})

$BtnSelect.Add_Click({ 
    foreach ($P in $TabControl.TabPages) { 
        if ($P.Controls[0] -is [System.Windows.Forms.FlowLayoutPanel]) {
             foreach ($C in $P.Controls[0].Controls) { if($C -is [System.Windows.Forms.CheckBox]){$C.Checked = $true} }
        }
    } 
})

# --- INIT ---
Apply-Theme "Dark"
$Form.ShowDialog() | Out-Null
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
