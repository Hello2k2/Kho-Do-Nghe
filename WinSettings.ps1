<#
    TITANIUM GOD MODE V6.0 - OMNIPOTENCE EDITION
    Architecture: Modern UI + GDI+ Vector Gauges + Winget + PowerGrid + NetOps
    Engine: PowerShell 5.1/7 + WinForms
    Upgraded by: Gemini
#>

# --- 0. SAFETY & INIT ---
$ErrorActionPreference = "SilentlyContinue"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Check Admin & Elevate
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- 1. CORE THEME CONFIG (CYBERPUNK PALETTE) ---
$Theme = @{
    BgForm      = [System.Drawing.Color]::FromArgb(10, 10, 15)       # Void Black
    BgSidebar   = [System.Drawing.Color]::FromArgb(20, 20, 28)       # Deep Grey
    BgContent   = [System.Drawing.Color]::FromArgb(28, 28, 38)       # Panel Bg
    BgInput     = [System.Drawing.Color]::FromArgb(15, 15, 20)       # Inputs
    Accent      = [System.Drawing.Color]::FromArgb(0, 210, 255)      # Neon Cyan
    Accent2     = [System.Drawing.Color]::FromArgb(180, 0, 255)      # Neon Purple
    AccentRed   = [System.Drawing.Color]::FromArgb(255, 50, 80)      # Danger Red
    AccentGold  = [System.Drawing.Color]::FromArgb(255, 180, 0)      # Gold (New)
    TextMain    = [System.Drawing.Color]::WhiteSmoke
    TextMuted   = [System.Drawing.Color]::FromArgb(120, 120, 140)
    Border      = [System.Drawing.Color]::FromArgb(60, 60, 80)
    FontLogo    = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    FontHead    = New-Object System.Drawing.Font("Segoe UI Semibold", 11)
    FontNorm    = New-Object System.Drawing.Font("Segoe UI", 9)
    FontMono    = New-Object System.Drawing.Font("Consolas", 9)
}

# --- 2. MAIN FORM SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "TITANIUM V6.0 OMNIPOTENCE"
$Form.Size = New-Object System.Drawing.Size(1150, 720)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "None"
$Form.BackColor = $Theme.BgForm
$Form.ForeColor = $Theme.TextMain
$Form.DoubleBuffered = $true 

# Drag Logic
$IsDragging = $false; $DragStart = [System.Drawing.Point]::Empty
$Form.Add_MouseDown({ $Global:IsDragging = $true; $Global:DragStart = $_.Location })
$Form.Add_MouseMove({ if ($Global:IsDragging) { $Form.Location = [System.Drawing.Point]::Add($Form.Location, [System.Drawing.Size]::Subtract($_.Location, $Global:DragStart)) } })
$Form.Add_MouseUp({ $Global:IsDragging = $false })

# --- 3. UI COMPONENTS BUILDER ---

function Add-NavBtn ($Parent, $Text, $Icon, $Y, $PanelToOpen) {
    $Btn = New-Object System.Windows.Forms.Label
    $Btn.Text = "  $Icon   $Text"
    $Btn.Size = New-Object System.Drawing.Size(220, 45)
    $Btn.Location = New-Object System.Drawing.Point(0, $Y)
    $Btn.Font = $Theme.FontHead
    $Btn.ForeColor = $Theme.TextMuted
    $Btn.TextAlign = "MiddleLeft"
    $Btn.Cursor = "Hand"
    $Btn.Tag = $PanelToOpen

    $Btn.Add_MouseEnter({ 
        $this.ForeColor = $Theme.Accent
        $this.BackColor = [System.Drawing.Color]::FromArgb(35,35,45)
    })
    $Btn.Add_MouseLeave({ 
        if ($script:ActivePanel -ne $this.Tag) {
            $this.ForeColor = $Theme.TextMuted
            $this.BackColor = [System.Drawing.Color]::Transparent
        }
    })
    $Btn.Add_Click({ Switch-Panel $this })
    $Parent.Controls.Add($Btn)
}

function Add-ActionBtn ($Parent, $Text, $Cmd, $X, $Y, $IsDanger=$false, $IsWide=$false) {
    $Btn = New-Object System.Windows.Forms.Button
    $Btn.Text = $Text
    $Btn.Tag = $Cmd
    $Btn.Location = New-Object System.Drawing.Point($X, $Y)
    $Btn.Size = if($IsWide){New-Object System.Drawing.Size(460, 35)}else{New-Object System.Drawing.Size(220, 35)}
    $Btn.FlatStyle = "Flat"
    $Btn.Font = $Theme.FontNorm
    $Btn.Cursor = "Hand"
    
    if ($IsDanger) {
        $Btn.ForeColor = $Theme.AccentRed
        $Btn.FlatAppearance.BorderColor = $Theme.AccentRed
    } else {
        $Btn.ForeColor = $Theme.TextMain
        $Btn.FlatAppearance.BorderColor = $Theme.Border
    }
    $Btn.FlatAppearance.BorderSize = 1
    $Btn.BackColor = $Theme.BgContent

    $Btn.Add_MouseEnter({ $this.BackColor = if($IsDanger){[System.Drawing.Color]::FromArgb(50,20,20)}else{[System.Drawing.Color]::FromArgb(50,50,60)} })
    $Btn.Add_MouseLeave({ $this.BackColor = $Theme.BgContent })
    $Btn.Add_Click({ Run-Command $this.Tag $this.Text })
    $Parent.Controls.Add($Btn)
}

function Add-SectionTitle ($Parent, $Text, $Y) {
    $L = New-Object System.Windows.Forms.Label; $L.Text = $Text
    $L.Font = $Theme.FontHead; $L.ForeColor = $Theme.Accent
    $L.Location = New-Object System.Drawing.Point(30, $Y); $L.AutoSize = $true
    $Parent.Controls.Add($L)
    $Line = New-Object System.Windows.Forms.Panel; $Line.Size = New-Object System.Drawing.Size(800, 1)
    $Line.BackColor = $Theme.Border; $Line.Location = New-Object System.Drawing.Point(30, $Y+28)
    $Parent.Controls.Add($Line)
}

# --- 4. LAYOUT STRUCTURE ---

# Sidebar
$Sidebar = New-Object System.Windows.Forms.Panel; $Sidebar.Dock = "Left"; $Sidebar.Width = 220; $Sidebar.BackColor = $Theme.BgSidebar
$Form.Controls.Add($Sidebar)

# Logo
$PnlLogo = New-Object System.Windows.Forms.Panel; $PnlLogo.Size = New-Object System.Drawing.Size(220, 80); $PnlLogo.Dock="Top"; $PnlLogo.BackColor="Transparent"
$LblLogo = New-Object System.Windows.Forms.Label; $LblLogo.Text = "TITANIUM"; $LblLogo.Font = $Theme.FontLogo; $LblLogo.ForeColor = $Theme.Accent; $LblLogo.AutoSize=$true; $LblLogo.Location=New-Object System.Drawing.Point(20, 20)
$LblVer = New-Object System.Windows.Forms.Label; $LblVer.Text = "V6.0 OMNIPOTENCE"; $LblVer.Font = $Theme.FontMono; $LblVer.ForeColor = $Theme.AccentGold; $LblVer.AutoSize=$true; $LblVer.Location=New-Object System.Drawing.Point(22, 55)
$PnlLogo.Controls.Add($LblLogo); $PnlLogo.Controls.Add($LblVer); $Sidebar.Controls.Add($PnlLogo)

# Content Area
$ContentContainer = New-Object System.Windows.Forms.Panel; $ContentContainer.Dock = "Fill"; $ContentContainer.BackColor = $Theme.BgForm
$Form.Controls.Add($ContentContainer)

# Top Bar
$TopBar = New-Object System.Windows.Forms.Panel; $TopBar.Dock="Top"; $TopBar.Height=35; $TopBar.BackColor="Transparent"
$TopBar.Add_MouseDown({ $Global:IsDragging = $true; $Global:DragStart = $_.Location })
$TopBar.Add_MouseMove({ if ($Global:IsDragging) { $Form.Location = [System.Drawing.Point]::Add($Form.Location, [System.Drawing.Size]::Subtract($_.Location, $Global:DragStart)) } })
$TopBar.Add_MouseUp({ $Global:IsDragging = $false })

$BtnClose = New-Object System.Windows.Forms.Label; $BtnClose.Text="✕"; $BtnClose.Dock="Right"; $BtnClose.Width=45; $BtnClose.TextAlign="MiddleCenter"; $BtnClose.ForeColor=$Theme.AccentRed; $BtnClose.Cursor="Hand"; $BtnClose.Font=$Theme.FontHead
$BtnClose.Add_Click({ $Form.Close() })
$BtnMin = New-Object System.Windows.Forms.Label; $BtnMin.Text="—"; $BtnMin.Dock="Right"; $BtnMin.Width=45; $BtnMin.TextAlign="MiddleCenter"; $BtnMin.ForeColor="White"; $BtnMin.Cursor="Hand"; $BtnMin.Font=$Theme.FontHead
$BtnMin.Add_Click({ $Form.WindowState = "Minimized" })
$TopBar.Controls.Add($BtnClose); $TopBar.Controls.Add($BtnMin)
$ContentContainer.Controls.Add($TopBar)

# Status Log
$StatusBar = New-Object System.Windows.Forms.Panel; $StatusBar.Dock="Bottom"; $StatusBar.Height=35; $StatusBar.BackColor=$Theme.BgSidebar
$LblStatus = New-Object System.Windows.Forms.Label; $LblStatus.Text="System initialized. Waiting for command..."; $LblStatus.ForeColor=$Theme.Accent; $LblStatus.Dock="Fill"; $LblStatus.TextAlign="MiddleLeft"; $LblStatus.Padding=New-Object System.Windows.Forms.Padding(15,0,0,0); $LblStatus.Font=$Theme.FontMono
$StatusBar.Controls.Add($LblStatus)
$ContentContainer.Controls.Add($StatusBar)

# --- 5. PANELS & CONTENT ---
$Global:Panels = @()
function Make-Panel ($Name) {
    $P = New-Object System.Windows.Forms.Panel; $P.Dock = "Fill"; $P.BackColor = $Theme.BgForm; $P.Visible = $false
    $ContentContainer.Controls.Add($P); $P.BringToFront(); $Global:Panels += $P; return $P
}

# --- P1: DASHBOARD ---
$P_Dash = Make-Panel "Dashboard"
Add-SectionTitle $P_Dash "SYSTEM MONITOR" 20
$GaugeBox = New-Object System.Windows.Forms.PictureBox; $GaugeBox.Location = New-Object System.Drawing.Point(30, 60); $GaugeBox.Size = New-Object System.Drawing.Size(820, 160); $GaugeBox.BackColor = "Transparent"; $P_Dash.Controls.Add($GaugeBox)
$TxtInfo = New-Object System.Windows.Forms.TextBox; $TxtInfo.Multiline=$true; $TxtInfo.Location=New-Object System.Drawing.Point(30, 240); $TxtInfo.Size=New-Object System.Drawing.Size(820, 300); $TxtInfo.BackColor=$Theme.BgInput; $TxtInfo.ForeColor=$Theme.TextMain; $TxtInfo.BorderStyle="None"; $TxtInfo.Font=$Theme.FontMono; $TxtInfo.ReadOnly=$true; $P_Dash.Controls.Add($TxtInfo)

# --- P2: OPTIMIZE ---
$P_Opt = Make-Panel "Optimize"
Add-SectionTitle $P_Opt "QUICK CLEANUP" 20
Add-ActionBtn $P_Opt "Deep Clean (Temp & Logs)" "CleanDeep" 30 60 $false $true
Add-ActionBtn $P_Opt "Reset Windows Update" "CleanUpd" 30 110
Add-ActionBtn $P_Opt "Disable Telemetry" "OffTele" 270 110
Add-ActionBtn $P_Opt "Enable Ultimate Power" "UltPerf" 30 160
Add-ActionBtn $P_Opt "Disable Hibernation (Save GB)" "OffHiber" 270 160

Add-SectionTitle $P_Opt "DEBLOATER" 220
Add-ActionBtn $P_Opt "Remove Cortana" "DelCortana" 30 260 $true
Add-ActionBtn $P_Opt "Remove Xbox Bloat" "DelXbox" 270 260 $true
Add-ActionBtn $P_Opt "Remove OneDrive" "DelOneDrive" 30 310 $true
Add-ActionBtn $P_Opt "Remove Edge (Risky)" "DelEdge" 270 310 $true

# --- P3: REPAIR ---
$P_Repair = Make-Panel "Repair"
Add-SectionTitle $P_Repair "SYSTEM INTEGRITY" 20
Add-ActionBtn $P_Repair "SFC Scan (Fix Files)" "RunSFC" 30 60
Add-ActionBtn $P_Repair "DISM Restore Health" "RunDISM" 270 60
Add-ActionBtn $P_Repair "Check Disk (C:)" "RunChkDsk" 30 110
Add-ActionBtn $P_Repair "Restart Explorer.exe" "RestartExp" 270 110
Add-SectionTitle $P_Repair "ADVANCED FIXES" 170
Add-ActionBtn $P_Repair "Fix Printer Spooler" "FixPrint" 30 210
Add-ActionBtn $P_Repair "Re-Register Store Apps" "FixStore" 270 210

# --- P4: NET OPS (NEW) ---
$P_Net = Make-Panel "NetOps"
Add-SectionTitle $P_Net "NETWORK OPERATIONS" 20
Add-ActionBtn $P_Net "Check Public IP" "GetPubIP" 30 60
Add-ActionBtn $P_Net "Ping Google (Test)" "PingTest" 270 60
Add-ActionBtn $P_Net "Flush DNS Cache" "FlushDns" 30 110
Add-ActionBtn $P_Net "Reset TCP/IP Stack" "NetReset" 270 110 $true

Add-SectionTitle $P_Net "HACKER TOOLS" 170
Add-ActionBtn $P_Net "Export Wi-Fi Passwords" "DumpWifi" 30 210 $false $true
Add-ActionBtn $P_Net "Edit Hosts File" "EditHosts" 30 260
Add-ActionBtn $P_Net "View Network Adapters" "OpenNcpa" 270 260

# --- P5: POWER GRID (NEW) ---
$P_Power = Make-Panel "PowerGrid"
Add-SectionTitle $P_Power "SESSION CONTROL" 20
Add-ActionBtn $P_Power "Lock Station" "PowerLock" 30 60
Add-ActionBtn $P_Power "Sign Out" "PowerLogoff" 270 60
Add-ActionBtn $P_Power "Sleep Now" "PowerSleep" 30 110
Add-ActionBtn $P_Power "Hibernate Now" "PowerHiber" 270 110

Add-SectionTitle $P_Power "SCHEDULED SHUTDOWN" 170
Add-ActionBtn $P_Power "Shutdown in 30 Mins" "Shut30" 30 210
Add-ActionBtn $P_Power "Shutdown in 1 Hour" "Shut60" 270 210
Add-ActionBtn $P_Power "Shutdown in 2 Hours" "Shut120" 30 260
Add-ActionBtn $P_Power "ABORT SHUTDOWN" "ShutAbort" 270 260 $true

# --- P6: SOFTWARE HUB ---
$P_Soft = Make-Panel "Software"
Add-SectionTitle $P_Soft "BROWSERS" 20
Add-ActionBtn $P_Soft "Chrome" "InstChrome" 30 60
Add-ActionBtn $P_Soft "Firefox" "InstFirefox" 270 60
Add-ActionBtn $P_Soft "Brave" "InstBrave" 510 60

Add-SectionTitle $P_Soft "DEV & CHAT" 110
Add-ActionBtn $P_Soft "VS Code" "InstVSCode" 30 150
Add-ActionBtn $P_Soft "Discord" "InstDiscord" 270 150
Add-ActionBtn $P_Soft "Zoom" "InstZoom" 510 150

Add-SectionTitle $P_Soft "OFFICE & TOOLS" 200
Add-ActionBtn $P_Soft "LibreOffice" "InstLibre" 30 240
Add-ActionBtn $P_Soft "7-Zip" "Inst7Zip" 270 240
Add-ActionBtn $P_Soft "OBS Studio" "InstOBS" 510 240

# --- NAV LINKING ---
Add-NavBtn $Sidebar "Dashboard" "📊" 90 $P_Dash
Add-NavBtn $Sidebar "Optimize" "🚀" 135 $P_Opt
Add-NavBtn $Sidebar "Net Ops" "🌐" 180 $P_Net
Add-NavBtn $Sidebar "Power Grid" "⚡" 225 $P_Power
Add-NavBtn $Sidebar "Sys Repair" "❤️" 270 $P_Repair
Add-NavBtn $Sidebar "Software" "💾" 315 $P_Soft

# --- 6. LOGIC ENGINE ---
$script:ActivePanel = $null
$Global:CpuLoad = 0; $Global:RamLoad = 0

function Switch-Panel ($Btn) {
    $Sidebar.Controls | Where-Object { $_.GetType().Name -eq "Label" -and $_.Tag -ne $null } | ForEach-Object {
        $_.ForeColor = $Theme.TextMuted; $_.BackColor = "Transparent"
    }
    $Global:Panels | ForEach-Object { $_.Visible = $false }
    $Btn.ForeColor = $Theme.Accent; $Btn.BackColor = [System.Drawing.Color]::FromArgb(35,35,45)
    $Btn.Tag.Visible = $true; $script:ActivePanel = $Btn.Tag
}

function Log ($Msg) { $LblStatus.Text = "$(Get-Date -Format 'HH:mm:ss') > $Msg"; $Form.Refresh() }
function Set-Reg ($Path, $Name, $Val) { if(!(Test-Path $Path)){New-Item $Path -Force|Out-Null}; New-ItemProperty -Path $Path -Name $Name -Value $Val -PropertyType DWord -Force|Out-Null }

function Run-Command ($Cmd, $Desc) {
    Log "Executing: $Desc..."
    $Form.Cursor = "WaitCursor"
    
    switch ($Cmd) {
        # Optimize
        "CleanDeep" { Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item "$env:windir\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue; Log "Deep Clean Complete." }
        "CleanUpd"  { Stop-Service wuauserv; Remove-Item "$env:windir\SoftwareDistribution\Download\*" -Recurse -Force; Start-Service wuauserv; Log "Update Cache Cleared." }
        "UltPerf"   { powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61; Log "Ultimate Performance Plan Added." }
        "OffTele"   { Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0; Log "Telemetry Disabled." }
        "OffHiber"  { powercfg -h off; Log "Hibernation Disabled (Space Saved)." }
        "DelCortana"{ Get-AppxPackage -allusers *Cortana* | Remove-AppxPackage; Log "Cortana Removed." }
        "DelXbox"   { Get-AppxPackage *xbox* | Remove-AppxPackage; Log "Xbox Apps Removed." }
        "DelOneDrive"{ Stop-Process -Name "OneDrive" -Force; Start-Process "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" "/uninstall" -Wait; Log "OneDrive Removed." }
        
        # Repair
        "RunSFC"    { Start-Process "sfc" "/scannow" -Verb RunAs; Log "SFC Launched." }
        "RunDISM"   { Start-Process "dism" "/online /cleanup-image /restorehealth" -Verb RunAs; Log "DISM Launched." }
        "RunChkDsk" { Start-Process "cmd" "/k chkdsk C:" -Verb RunAs; Log "ChkDsk Launched." }
        "RestartExp"{ Stop-Process -Name explorer -Force; Log "Explorer Restarted." }
        "FixPrint"  { Restart-Service spooler; Log "Printer Spooler Restarted." }
        
        # NetOps
        "GetPubIP"  { try { $ip = Invoke-RestMethod http://ipinfo.io/ip; Log "Public IP: $ip" } catch { Log "Failed to get IP." } }
        "PingTest"  { Start-Process "cmd" "/k ping 8.8.8.8"; Log "Pinging Google..." }
        "FlushDns"  { ipconfig /flushdns; Log "DNS Flushed." }
        "NetReset"  { netsh int ip reset; netsh winsock reset; Log "Network Reset. Reboot required." }
        "DumpWifi"  { 
            $out = "$env:USERPROFILE\Desktop\WifiKeys.txt"; "--- WI-FI KEYS ---" | Out-File $out
            (netsh wlan show profiles) | Select-String "\:(.+)$" | %{
                $name=$_.Matches.Groups[1].Value.Trim(); $pass=(netsh wlan show profile name="$name" key=clear); 
                "$name : $pass" | Out-File $out -Append
            }; Log "Saved to Desktop\WifiKeys.txt" 
        }
        "EditHosts" { Start-Process "notepad" "C:\Windows\System32\drivers\etc\hosts" -Verb RunAs }
        "OpenNcpa"  { Start-Process "ncpa.cpl" }

        # PowerGrid
        "PowerLock"   { rundll32.exe user32.dll,LockWorkStation }
        "PowerLogoff" { shutdown -l }
        "PowerSleep"  { [System.Windows.Forms.Application]::SetSuspendState([System.Windows.Forms.PowerState]::Suspend, $false, $false) }
        "PowerHiber"  { [System.Windows.Forms.Application]::SetSuspendState([System.Windows.Forms.PowerState]::Hibernate, $false, $false) }
        "Shut30"      { shutdown -s -t 1800; Log "Shutdown in 30 mins." }
        "Shut60"      { shutdown -s -t 3600; Log "Shutdown in 1 hour." }
        "Shut120"     { shutdown -s -t 7200; Log "Shutdown in 2 hours." }
        "ShutAbort"   { shutdown -a; Log "Shutdown Aborted!" }

        # Software
        "InstChrome"  { Start-Process "winget" "install Google.Chrome -e --silent"; Log "Installing Chrome..." }
        "InstFirefox" { Start-Process "winget" "install Mozilla.Firefox -e --silent"; Log "Installing Firefox..." }
        "InstBrave"   { Start-Process "winget" "install Brave.Brave -e --silent"; Log "Installing Brave..." }
        "InstVSCode"  { Start-Process "winget" "install Microsoft.VisualStudioCode -e --silent"; Log "Installing VS Code..." }
        "InstDiscord" { Start-Process "winget" "install Discord.Discord -e --silent"; Log "Installing Discord..." }
        "InstZoom"    { Start-Process "winget" "install Zoom.Zoom -e --silent"; Log "Installing Zoom..." }
        "InstLibre"   { Start-Process "winget" "install LibreOffice.LibreOffice -e --silent"; Log "Installing LibreOffice..." }
        "Inst7Zip"    { Start-Process "winget" "install 7zip.7zip -e --silent"; Log "Installing 7-Zip..." }
        "InstOBS"     { Start-Process "winget" "install OBSProject.OBSStudio -e --silent"; Log "Installing OBS..." }
    }
    $Form.Cursor = "Default"
}

# --- 7. GDI+ RENDERING ---
$GaugeBox.Add_Paint({
    param($sender, $e)
    $g = $e.Graphics; $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $DrawArc = { param($x, $val, $color, $label) 
        $rect = New-Object System.Drawing.Rectangle $x, 10, 140, 140
        $penBg = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(40,40,50)), 15
        $penVal = New-Object System.Drawing.Pen $color, 15; $penVal.StartCap="Round"; $penVal.EndCap="Round"
        $angle = [Math]::Min(360, [Math]::Max(0, ($val / 100) * 360))
        $g.DrawArc($penBg, $rect, -90, 360); if($val -gt 0) { $g.DrawArc($penVal, $rect, -90, $angle) }
        $fontBig = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
        $txtSize = $g.MeasureString("$([int]$val)%", $fontBig)
        $g.DrawString("$([int]$val)%", $fontBig, [System.Drawing.Brushes]::White, ($x + 70 - $txtSize.Width/2), 60)
        $fontSm = New-Object System.Drawing.Font("Segoe UI", 10)
        $lblSize = $g.MeasureString($label, $fontSm)
        $g.DrawString($label, $fontSm, [System.Drawing.Brushes]::Gray, ($x + 70 - $lblSize.Width/2), 95)
    }
    & $DrawArc 50 $Global:CpuLoad $Theme.Accent "CPU LOAD"
    & $DrawArc 250 $Global:RamLoad $Theme.Accent2 "RAM USAGE"
})

# --- 8. REAL-TIME MONITOR ENGINE ---
$Timer = New-Object System.Windows.Forms.Timer; $Timer.Interval = 1500
$Timer.Add_Tick({
    $OS = Get-CimInstance Win32_OperatingSystem
    $Global:CpuLoad = (Get-CimInstance Win32_Processor).LoadPercentage
    $Global:RamLoad = (($OS.TotalVisibleMemorySize - $OS.FreePhysicalMemory) / $OS.TotalVisibleMemorySize) * 100
    $GaugeBox.Invalidate()
    if ($TxtInfo.Text -eq "") {
        $GPU = (Get-CimInstance Win32_VideoController).Name
        $Bat = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
        $BatStatus = if($Bat){ "$($Bat.EstimatedChargeRemaining)% (Plugged: $($Bat.BatteryStatus -eq 2))" } else { "N/A (Desktop)" }
        $TxtInfo.Text = @"
SYSTEM DIAGNOSTICS [OMNIPOTENCE]
--------------------------------
OS         : $($OS.Caption) ($($OS.OSArchitecture))
User       : $env:USERNAME
CPU        : $((Get-CimInstance Win32_Processor).Name)
GPU        : $GPU
RAM        : $([Math]::Round($OS.TotalVisibleMemorySize/1MB/1024, 1)) GB
Battery    : $BatStatus
Uptime     : $((Get-Date) - $OS.LastBootUpTime | Select -ExpandProperty TotalHours | ForEach {[Math]::Round($_, 1)}) Hours
"@
    }
})
$Timer.Start()

# --- INIT ---
Switch-Panel ($Sidebar.Controls | Where Tag -eq $P_Dash | Select -First 1)
$Form.ShowDialog() | Out-Null
