# --- 1. FORCE ADMIN & CONFIG ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"

# --- THEME: CYBERPUNK ---
$Theme = @{
    Back      = [System.Drawing.Color]::FromArgb(20, 20, 25)
    Panel     = [System.Drawing.Color]::FromArgb(35, 35, 40)
    Text      = [System.Drawing.Color]::FromArgb(220, 220, 220)
    Accent    = [System.Drawing.Color]::FromArgb(0, 190, 255) # Deep Cyan
    Hacker    = [System.Drawing.Color]::FromArgb(0, 255, 65)  # Matrix Green
    Warn      = [System.Drawing.Color]::FromArgb(255, 140, 0)
    Err       = [System.Drawing.Color]::FromArgb(255, 50, 50)
}

# --- GUI INIT ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "PHAT TAN RESCUE CENTER - V5.0 PRO MAX"
$Form.Size = New-Object System.Drawing.Size(1000, 750)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back; $Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

# HEADER
$PnlHead = New-Object System.Windows.Forms.Panel; $PnlHead.Size="1000, 70"; $PnlHead.Dock="Top"; $PnlHead.BackColor=$Theme.Panel; $Form.Controls.Add($PnlHead)
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "SYSTEM RECOVERY PROTOCOL"; $LblT.Font = "Impact, 26"; $LblT.ForeColor = $Theme.Accent; $LblT.AutoSize = $true; $LblT.Location = "20,15"; $PnlHead.Controls.Add($LblT)
$LblSub = New-Object System.Windows.Forms.Label; $LblSub.Text = "Build V5.0 | High Performance | Auto-Threading"; $LblSub.ForeColor = "Gray"; $LblSub.Location = "450, 28"; $LblSub.AutoSize = $true; $PnlHead.Controls.Add($LblSub)

# TAB CONTROL
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = "20, 90"; $TabControl.Size = "945, 420"
$Form.Controls.Add($TabControl)

function Add-Page ($Title) { $p=New-Object System.Windows.Forms.TabPage; $p.Text=$Title; $p.BackColor=$Theme.Back; $p.ForeColor=$Theme.Text; $TabControl.Controls.Add($p); return $p }
function Add-Grp ($P, $T, $X, $Y, $W, $H, $C) { $g=New-Object System.Windows.Forms.GroupBox; $g.Text=$T; $g.Location="$X,$Y"; $g.Size="$W,$H"; $g.ForeColor=$C; $P.Controls.Add($g); return $g }
function Add-Chk ($P, $T, $X, $Y, $Tag) { $c=New-Object System.Windows.Forms.CheckBox; $c.Text=$T; $c.Location="$X,$Y"; $c.AutoSize=$true; $c.Tag=$Tag; $c.Font="Segoe UI, 10"; $c.ForeColor="White"; $P.Controls.Add($c); return $c }

# ==========================================
# TAB 1: BACKUP ZONE
# ==========================================
$TabB = Add-Page "  /// EXECUTE BACKUP  "

$LblDest = New-Object System.Windows.Forms.Label; $LblDest.Text = "DESTINATION PATH:"; $LblDest.Location = "20,20"; $LblDest.AutoSize = $true; $TabB.Controls.Add($LblDest)
$TxtDest = New-Object System.Windows.Forms.TextBox; $TxtDest.Location = "20,45"; $TxtDest.Size = "800,25"; $TxtDest.BackColor=$Theme.Panel; $TxtDest.ForeColor="White"; $TxtDest.BorderStyle="FixedSingle"; $TabB.Controls.Add($TxtDest)
if(Test-Path "D:\"){$TxtDest.Text="D:\PhatTan_Backup"}else{$TxtDest.Text="C:\PhatTan_Backup"}
$BtnBrw = New-Object System.Windows.Forms.Button; $BtnBrw.Text="..."; $BtnBrw.Location="830,45"; $BtnBrw.Size="40,25"; $BtnBrw.FlatStyle="Flat"; $TabB.Controls.Add($BtnBrw)
$BtnBrw.Add_Click({ $F=New-Object System.Windows.Forms.FolderBrowserDialog; if($F.ShowDialog() -eq "OK"){$TxtDest.Text=$F.SelectedPath+"\PhatTan_Backup"} })

# -- COLUMN 1: CORE SYSTEM --
$Gb1 = Add-Grp $TabB " [ SYSTEM CORE ] " 20 90 280 230 $Theme.Accent
$cB_Wifi  = Add-Chk $Gb1 "Wifi Profiles (XML)" 20 30 "Wifi"
$cB_Drv   = Add-Chk $Gb1 "Drivers (DISM Export)" 20 60 "Driver"
$cB_Net   = Add-Chk $Gb1 "IP Config (Static IP)" 20 90 "Net"  # NEW
$cB_Print = Add-Chk $Gb1 "Printers (Config File)" 20 120 "Print" # NEW
$cB_Hosts = Add-Chk $Gb1 "Hosts File" 20 150 "Hosts"
$cB_Start = Add-Chk $Gb1 "Start Menu Layout" 20 180 "Start"

# -- COLUMN 2: APPS & UTILS --
$Gb2 = Add-Grp $TabB " [ APPLICATIONS ] " 320 90 280 230 $Theme.Hacker
$cB_IDM    = Add-Chk $Gb2 "IDM (Full Key + Data)" 20 30 "IDM"
$cB_Zalo   = Add-Chk $Gb2 "Zalo PC (Chat Data)" 20 60 "Zalo"
$cB_Chrome = Add-Chk $Gb2 "Chrome (User Profile)" 20 90 "Chrome"
$cB_Edge   = Add-Chk $Gb2 "Edge (User Profile)" 20 120 "Edge"
$cB_Font   = Add-Chk $Gb2 "Fonts (External)" 20 150 "Fonts"
$cB_HTML   = Add-Chk $Gb2 "Export App List (HTML)" 20 180 "HTML"

# -- COLUMN 3: USER FILES --
$Gb3 = Add-Grp $TabB " [ USER DATA ] " 620 90 280 230 $Theme.Warn
$cB_Desk = Add-Chk $Gb3 "Desktop" 20 30 "Desktop"
$cB_Doc  = Add-Chk $Gb3 "Documents" 20 60 "Doc"
$cB_Pic  = Add-Chk $Gb3 "Pictures" 20 90 "Pic"
$cB_Down = Add-Chk $Gb3 "Downloads" 20 120 "Down"
$cB_Mus  = Add-Chk $Gb3 "Music & Video" 20 150 "Media"

# Defaults
$cB_Wifi.Checked=$true; $cB_Drv.Checked=$true; $cB_Net.Checked=$true; $cB_IDM.Checked=$true; $cB_Zalo.Checked=$true; $cB_Desk.Checked=$true

$BtnBack = New-Object System.Windows.Forms.Button; $BtnBack.Text="INITIALIZE BACKUP SEQUENCE"; $BtnBack.Location="20,340"; $BtnBack.Size="880,45"; $BtnBack.BackColor=$Theme.Accent; $BtnBack.ForeColor="Black"; $BtnBack.FlatStyle="Flat"; $BtnBack.Font="Segoe UI, 12, Bold"
$TabB.Controls.Add($BtnBack)

# ==========================================
# TAB 2: RESTORE ZONE
# ==========================================
$TabR = Add-Page "  /// RESTORE DATA  "

$LblSrc = New-Object System.Windows.Forms.Label; $LblSrc.Text = "SOURCE PATH:"; $LblSrc.Location = "20,20"; $LblSrc.AutoSize = $true; $TabR.Controls.Add($LblSrc)
$TxtSrc = New-Object System.Windows.Forms.TextBox; $TxtSrc.Location = "20,45"; $TxtSrc.Size = "800,25"; $TxtSrc.BackColor=$Theme.Panel; $TxtSrc.ForeColor="White"; $TxtSrc.BorderStyle="FixedSingle"; $TabR.Controls.Add($TxtSrc)
$BtnBrwR = New-Object System.Windows.Forms.Button; $BtnBrwR.Text="SRC"; $BtnBrwR.Location="830,45"; $BtnBrwR.Size="40,25"; $BtnBrwR.FlatStyle="Flat"; $TabR.Controls.Add($BtnBrwR)
$BtnBrwR.Add_Click({ $F=New-Object System.Windows.Forms.FolderBrowserDialog; if($F.ShowDialog() -eq "OK"){$TxtSrc.Text=$F.SelectedPath} })

$GbR = Add-Grp $TabR " [ RESTORE MODULES ] " 20 90 880 230 "White"
$cR_Wifi = Add-Chk $GbR "Wifi" 30 30 "R_Wifi"; $cR_Drv = Add-Chk $GbR "Drivers" 30 60 "R_Drv"; $cR_Net = Add-Chk $GbR "IP Config" 30 90 "R_Net"
$cR_Print= Add-Chk $GbR "Printers (Info Only)" 30 120 "R_Print"; $cR_Hosts= Add-Chk $GbR "Hosts" 30 150 "R_Hosts"

$cR_IDM = Add-Chk $GbR "IDM (Full)" 200 30 "R_IDM"; $cR_Zalo= Add-Chk $GbR "Zalo PC" 200 60 "R_Zalo"
$cR_Chrome= Add-Chk $GbR "Chrome" 200 90 "R_Chrome"; $cR_Edge= Add-Chk $GbR "Edge" 200 120 "R_Edge"
$cR_Start= Add-Chk $GbR "Start Menu" 200 150 "R_Start"; $cR_Font= Add-Chk $GbR "Fonts" 200 180 "R_Font"

$cR_Data = Add-Chk $GbR "OVERWRITE USER DATA" 450 30 "R_Data"; $cR_Data.ForeColor=$Theme.Warn
$LblW = New-Object System.Windows.Forms.Label; $LblW.Text="WARNING: Browsers & Zalo will be terminated forcefully during restore!"; $LblW.ForeColor=$Theme.Err; $LblW.Location="450, 60"; $LblW.AutoSize=$true; $GbR.Controls.Add($LblW)

$BtnRes = New-Object System.Windows.Forms.Button; $BtnRes.Text="ENGAGE RESTORE PROCESS"; $BtnRes.Location="20,340"; $BtnRes.Size="880,45"; $BtnRes.BackColor=$Theme.Err; $BtnRes.ForeColor="White"; $BtnRes.FlatStyle="Flat"; $BtnRes.Font="Segoe UI, 12, Bold"
$TabR.Controls.Add($BtnRes)

# --- STATUS & LOG ---
$PBar = New-Object System.Windows.Forms.ProgressBar; $PBar.Location="20, 520"; $PBar.Size="945, 20"; $PBar.Style="Continuous"; $Form.Controls.Add($PBar)
$TxtLog = New-Object System.Windows.Forms.TextBox; $TxtLog.Multiline=$true; $TxtLog.Location="20,550"; $TxtLog.Size="945,140"; $TxtLog.BackColor="Black"; $TxtLog.ForeColor=$Theme.Hacker; $TxtLog.ReadOnly=$true; $TxtLog.ScrollBars="Vertical"; $TxtLog.Font="Consolas, 9"; $Form.Controls.Add($TxtLog)

function Log ($M, $Val=0) { 
    $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $M`r`n"); $TxtLog.ScrollToCaret()
    if($Val -gt 0){ $PBar.Value = $Val }
    [System.Windows.Forms.Application]::DoEvents() 
}

# ==========================================
# ADVANCED LOGIC V5.0
# ==========================================

function Export-NetConfig ($Path) {
    Log "Scanning Network Adapters..." 10
    $Net = Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -and $_.InterfaceAlias -notlike "*Loopback*" } | Select InterfaceAlias, IPAddress, PrefixLength
    $DNS = Get-DnsClientServerAddress | Where-Object { $_.ServerAddresses } | Select InterfaceAlias, ServerAddresses
    $Report = "NETWORK CONFIG REPORT`n---------------------`n"
    foreach ($N in $Net) {
        $Report += "Interface: $($N.InterfaceAlias)`nIP: $($N.IPAddress) / $($N.PrefixLength)`n"
        $D = $DNS | Where {$_.InterfaceAlias -eq $N.InterfaceAlias}
        if($D){ $Report += "DNS: $($D.ServerAddresses -join ', ')" }
        $Report += "`n---------------------`n"
    }
    $Report | Out-File "$Path\NetworkConfig.txt"; Log "Network Config Saved." 15
}

function Export-Printers ($Path) {
    Log "Exporting Printer Configs..." 20
    # Save list to text for human reading
    Get-Printer | Select Name, DriverName, PortName | Out-File "$Path\PrinterList.txt"
    # Try using PrintUI to save config to binary (experimental)
    # Start-Process "rundll32" "printui.dll,PrintUIEntry /Ss /n `"PrinterName`" /a `"$Path\Printer.dat`"" -Wait # Complex to loop all
    Log "Printer List Exported." 25
}

function Robo ($S, $D, $N, $P) {
    if(Test-Path $S) { Log "Processing: $N..." $P; Start-Process "robocopy.exe" "`"$S`" `"$D`" /E /MT:32 /R:0 /W:0 /NFL /NDL" -WindowStyle Hidden -Wait }
}

# --- BACKUP EVENT ---
$BtnBack.Add_Click({
    $Dst = "$($TxtDest.Text)\Backup_$(Get-Date -F 'ddMM_HHmm')"
    New-Item -Path $Dst -Type Directory -Force | Out-Null
    $PBar.Value = 0
    
    # 1. SYSTEM
    if($cB_Wifi.Checked){ New-Item "$Dst\System\Wifi" -Force -Type Directory; netsh wlan export profile key=clear folder="$Dst\System\Wifi" | Out-Null; Log "Wifi Exported." 5 }
    if($cB_Net.Checked){ Export-NetConfig "$Dst\System" }
    if($cB_Print.Checked){ Export-Printers "$Dst\System" }
    if($cB_Hosts.Checked){ Copy-Item "C:\Windows\System32\drivers\etc\hosts" "$Dst\System\hosts_backup" -Force; Log "Hosts Saved." 30 }
    
    if($cB_Start.Checked){ 
        New-Item "$Dst\System\Start" -Force -Type Directory
        reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\CloudStore" "$Dst\System\Start\StartLayout.reg" /y | Out-Null
        Copy-Item "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*" "$Dst\System\Start" -Recurse -Force
        Log "Start Layout Saved." 35 
    }
    
    if($cB_Drv.Checked){ Log "Exporting Drivers (Deep Scan)..." 40; New-Item "$Dst\Drivers" -Type Directory; Start-Process "dism" "/online /export-driver /destination:`"$Dst\Drivers`"" -WindowStyle Hidden -Wait }
    
    # 2. APPS
    if($cB_IDM.Checked){ 
        Log "Backing up IDM..." 50; New-Item "$Dst\AppData\IDM" -Type Directory -Force
        reg export "HKCU\Software\DownloadManager" "$Dst\AppData\IDM\IDM_Reg.reg" /y | Out-Null
        if(Test-Path "$env:APPDATA\IDM"){ Copy-Item "$env:APPDATA\IDM" "$Dst\AppData\IDM\Roaming_IDM" -Recurse -Force }
        if(Test-Path "$env:APPDATA\DwnlData"){ Copy-Item "$env:APPDATA\DwnlData" "$Dst\AppData\IDM\Roaming_DwnlData" -Recurse -Force }
    }
    
    if($cB_Zalo.Checked){ Robo "$env:APPDATA\ZaloPC" "$Dst\AppData\ZaloPC" "Zalo" 60 }
    if($cB_Chrome.Checked){ Robo "$env:LOCALAPPDATA\Google\Chrome\User Data" "$Dst\AppData\Chrome" "Chrome" 65 }
    if($cB_Edge.Checked){ Robo "$env:LOCALAPPDATA\Microsoft\Edge\User Data" "$Dst\AppData\Edge" "Edge" 70 }
    
    if($cB_Font.Checked){ 
        Log "Cloning Fonts..." 75; New-Item "$Dst\System\Fonts" -Type Directory
        Get-ChildItem "C:\Windows\Fonts" -Include *.ttf,*.otf -Recurse | Copy-Item -Destination "$Dst\System\Fonts" 
    }
    
    if($cB_HTML.Checked){
        Log "Generating HTML Report..." 80
        $Reg = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        $Apps = Get-ItemProperty $Reg | Where {$_.DisplayName} | Select DisplayName, DisplayVersion | Sort DisplayName
        $H = "<html><body style='background:#111;color:#0f0;font-family:Consolas'><h2>APP LIST</h2><table border='1' style='border-color:#333;width:100%'>"
        foreach($a in $Apps){ $H += "<tr><td>$($a.DisplayName)</td><td>$($a.DisplayVersion)</td></tr>" }
        $H += "</table></body></html>"; $H | Out-File "$Dst\Apps.html" -Encoding UTF8
    }

    # 3. DATA
    if($cB_Desk.Checked){ Robo "$env:USERPROFILE\Desktop" "$Dst\UserData\Desktop" "Desktop" 85 }
    if($cB_Doc.Checked){ Robo "$env:USERPROFILE\Documents" "$Dst\UserData\Documents" "Documents" 90 }
    if($cB_Pic.Checked){ Robo "$env:USERPROFILE\Pictures" "$Dst\UserData\Pictures" "Pictures" 92 }
    if($cB_Down.Checked){ Robo "$env:USERPROFILE\Downloads" "$Dst\UserData\Downloads" "Downloads" 95 }
    if($cB_Mus.Checked){ Robo "$env:USERPROFILE\Music" "$Dst\UserData\Music" "Music" 98 }

    $PBar.Value = 100; Log "=== MISSION ACCOMPLISHED ===" 100
    Invoke-Item $Dst
})

# --- RESTORE EVENT ---
$BtnRes.Add_Click({
    $Src = $TxtSrc.Text
    if(!(Test-Path $Src)){ [System.Windows.Forms.MessageBox]::Show("INVALID SOURCE PATH!"); return }
    if([System.Windows.Forms.MessageBox]::Show("DANGER: FILES WILL BE OVERWRITTEN!`nCONTINUE?", "CONFIRM", "YesNo", "Warning") -eq "No"){ return }
    $PBar.Value = 0

    if($cR_Wifi.Checked){ Get-ChildItem "$Src\System\Wifi\*.xml" | % { netsh wlan add profile filename="$($_.FullName)" }; Log "Wifi Imported." 10 }
    if($cR_Hosts.Checked){ Copy-Item "$Src\System\hosts_backup" "C:\Windows\System32\drivers\etc\hosts" -Force; Log "Hosts Restored." 20 }
    
    if($cR_Net.Checked -and (Test-Path "$Src\System\NetworkConfig.txt")){ Invoke-Item "$Src\System\NetworkConfig.txt"; Log "Opened IP Config for manual review." 25 }
    
    if($cR_Drv.Checked){ Log "Injecting Drivers..." 30; Start-Process "pnputil" "/add-driver `"$Src\Drivers\*.inf`" /subdirs /install" -WindowStyle Hidden -Wait }
    
    if($cR_Font.Checked -and (Test-Path "$Src\System\Fonts")){
        Log "Installing Fonts..." 40; $Shell = New-Object -ComObject Shell.Application; $F = $Shell.Namespace(0x14)
        Get-ChildItem "$Src\System\Fonts" | Where { $_.Extension -match "\.ttf|\.otf" } | ForEach { $F.CopyHere($_.FullName) }
    }

    if($cR_Start.Checked){
        Log "Resetting Shell..." 50; Stop-Process -Name explorer -Force
        reg import "$Src\System\Start\StartLayout.reg"
        Copy-Item "$Src\System\Start\*" "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar" -Recurse -Force
        Start-Sleep 2; Start-Process explorer
    }

    if($cR_IDM.Checked){
        Stop-Process -Name IDMan -Force; Log "Restoring IDM..." 60
        reg import "$Src\AppData\IDM\IDM_Reg.reg"
        Copy-Item "$Src\AppData\IDM\Roaming_IDM" "$env:APPDATA\IDM" -Recurse -Force
        Copy-Item "$Src\AppData\IDM\Roaming_DwnlData" "$env:APPDATA\DwnlData" -Recurse -Force
    }

    if($cR_Zalo.Checked){ Stop-Process -Name Zalo -Force; Robo "$Src\AppData\ZaloPC" "$env:APPDATA\ZaloPC" "Zalo" 70 }
    if($cR_Chrome.Checked){ Stop-Process -Name chrome -Force; Robo "$Src\AppData\Chrome" "$env:LOCALAPPDATA\Google\Chrome\User Data" "Chrome" 80 }
    if($cR_Edge.Checked){ Stop-Process -Name msedge -Force; Robo "$Src\AppData\Edge" "$env:LOCALAPPDATA\Microsoft\Edge\User Data" "Edge" 90 }

    if($cR_Data.Checked){
        Robo "$Src\UserData\Desktop" "$env:USERPROFILE\Desktop" "Desktop" 95
        Robo "$Src\UserData\Documents" "$env:USERPROFILE\Documents" "Documents" 98
    }

    $PBar.Value = 100; Log "=== RESTORE COMPLETE! REBOOT REQUIRED ===" 100
    [System.Windows.Forms.MessageBox]::Show("Operation Finished!")
})

$Form.ShowDialog() | Out-Null
