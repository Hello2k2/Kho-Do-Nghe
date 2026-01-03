<#
    TITANIUM GOD MODE V4.0 - THE NEXT LEVEL
    Architecture: Modern UI (Borderless) + Sidebar Nav + Real-time Monitor
    Engine: PowerShell + WinForms + GDI+
    Author: Upgraded by Gemini
#>

# --- 0. SAFETY & INIT ---
$ErrorActionPreference = "SilentlyContinue"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Check Admin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- 1. CORE THEME CONFIG ---
$Theme = @{
    BgForm      = [System.Drawing.Color]::FromArgb(18, 18, 24)       # Deep Dark Blue/Black
    BgSidebar   = [System.Drawing.Color]::FromArgb(25, 25, 35)       # Lighter Sidebar
    BgContent   = [System.Drawing.Color]::FromArgb(30, 30, 40)       # Content Area
    Accent      = [System.Drawing.Color]::FromArgb(0, 255, 180)      # Cyber Green
    AccentRed   = [System.Drawing.Color]::FromArgb(255, 60, 90)      # Cyber Red
    TextMain    = [System.Drawing.Color]::WhiteSmoke
    TextMuted   = [System.Drawing.Color]::Gray
    Border      = [System.Drawing.Color]::FromArgb(50, 50, 65)
    FontLogo    = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    FontHead    = New-Object System.Drawing.Font("Segoe UI Semibold", 11)
    FontNorm    = New-Object System.Drawing.Font("Segoe UI", 9)
    FontMono    = New-Object System.Drawing.Font("Consolas", 9)
}

# --- 2. MAIN FORM SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "TITANIUM GOD MODE V4.0"
$Form.Size = New-Object System.Drawing.Size(1000, 650)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "None" # Borderless Modern Look
$Form.BackColor = $Theme.BgForm
$Form.ForeColor = $Theme.TextMain

# Enable Dragging on Borderless Form
$IsDragging = $false
$DragStart = [System.Drawing.Point]::Empty
$Form.Add_MouseDown({ $Global:IsDragging = $true; $Global:DragStart = $_.Location })
$Form.Add_MouseMove({ if ($Global:IsDragging) { $Form.Location = [System.Drawing.Point]::Add($Form.Location, [System.Drawing.Size]::Subtract($_.Location, $Global:DragStart)) } })
$Form.Add_MouseUp({ $Global:IsDragging = $false })

# --- 3. UI COMPONENTS BUILDER ---

# > Custom Button Builder
function Add-NavBtn ($Parent, $Text, $Icon, $Y, $PanelToOpen) {
    $Btn = New-Object System.Windows.Forms.Label
    $Btn.Text = "  $Icon   $Text"
    $Btn.Size = New-Object System.Drawing.Size(200, 45)
    $Btn.Location = New-Object System.Drawing.Point(0, $Y)
    $Btn.Font = $Theme.FontHead
    $Btn.ForeColor = $Theme.TextMuted
    $Btn.TextAlign = "MiddleLeft"
    $Btn.Cursor = "Hand"
    $Btn.Tag = $PanelToOpen # Link to content panel

    $Btn.Add_MouseEnter({ 
        $this.ForeColor = $Theme.Accent
        $this.BackColor = [System.Drawing.Color]::FromArgb(40,40,50)
    })
    $Btn.Add_MouseLeave({ 
        if ($script:ActivePanel -ne $this.Tag) {
            $this.ForeColor = $Theme.TextMuted
            $this.BackColor = [System.Drawing.Color]::Transparent
        }
    })
    $Btn.Add_Click({ Switch-Panel $this })
    $Parent.Controls.Add($Btn)
    return $Btn
}

# > Action Button Builder
function Add-ActionBtn ($Parent, $Text, $Cmd, $X, $Y, $IsDanger=$false) {
    $Btn = New-Object System.Windows.Forms.Button
    $Btn.Text = $Text
    $Btn.Tag = $Cmd
    $Btn.Location = New-Object System.Drawing.Point($X, $Y)
    $Btn.Size = New-Object System.Drawing.Size(220, 35)
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

# > Header Label Builder
function Add-SectionTitle ($Parent, $Text, $Y) {
    $L = New-Object System.Windows.Forms.Label
    $L.Text = $Text
    $L.Font = $Theme.FontHead
    $L.ForeColor = $Theme.Accent
    $L.Location = New-Object System.Drawing.Point(20, $Y)
    $L.AutoSize = $true
    $Parent.Controls.Add($L)
    
    $Line = New-Object System.Windows.Forms.Panel
    $Line.Size = New-Object System.Drawing.Size(700, 1)
    $Line.BackColor = $Theme.Border
    $Line.Location = New-Object System.Drawing.Point(20, $Y+25)
    $Parent.Controls.Add($Line)
}

# --- 4. LAYOUT STRUCTURE ---

# [SIDEBAR]
$Sidebar = New-Object System.Windows.Forms.Panel
$Sidebar.Dock = "Left"
$Sidebar.Width = 200
$Sidebar.BackColor = $Theme.BgSidebar
$Form.Controls.Add($Sidebar)

# Logo Area
$PnlLogo = New-Object System.Windows.Forms.Panel; $PnlLogo.Size = New-Object System.Drawing.Size(200, 60); $PnlLogo.Dock="Top"; $PnlLogo.BackColor="Transparent"
$LblLogo = New-Object System.Windows.Forms.Label; $LblLogo.Text = "TITANIUM"; $LblLogo.Font = $Theme.FontLogo; $LblLogo.ForeColor = $Theme.Accent; $LblLogo.AutoSize=$true; $LblLogo.Location=New-Object System.Drawing.Point(20, 15)
$PnlLogo.Controls.Add($LblLogo); $Sidebar.Controls.Add($PnlLogo)

# [CONTENT CONTAINER]
$ContentContainer = New-Object System.Windows.Forms.Panel
$ContentContainer.Dock = "Fill"
$ContentContainer.BackColor = $Theme.BgForm
$Form.Controls.Add($ContentContainer)

# [TOP BAR (Close/Min)]
$TopBar = New-Object System.Windows.Forms.Panel; $TopBar.Dock="Top"; $TopBar.Height=30; $TopBar.BackColor="Transparent"
# Drag Logic for TopBar
$TopBar.Add_MouseDown({ $Global:IsDragging = $true; $Global:DragStart = $_.Location })
$TopBar.Add_MouseMove({ if ($Global:IsDragging) { $Form.Location = [System.Drawing.Point]::Add($Form.Location, [System.Drawing.Size]::Subtract($_.Location, $Global:DragStart)) } })
$TopBar.Add_MouseUp({ $Global:IsDragging = $false })

$BtnClose = New-Object System.Windows.Forms.Label; $BtnClose.Text="✕"; $BtnClose.Dock="Right"; $BtnClose.Width=40; $BtnClose.TextAlign="MiddleCenter"; $BtnClose.ForeColor=$Theme.AccentRed; $BtnClose.Cursor="Hand"
$BtnClose.Add_Click({ $Form.Close() })
$BtnMin = New-Object System.Windows.Forms.Label; $BtnMin.Text="—"; $BtnMin.Dock="Right"; $BtnMin.Width=40; $BtnMin.TextAlign="MiddleCenter"; $BtnMin.ForeColor="White"; $BtnMin.Cursor="Hand"
$BtnMin.Add_Click({ $Form.WindowState = "Minimized" })
$TopBar.Controls.Add($BtnClose); $TopBar.Controls.Add($BtnMin)
$ContentContainer.Controls.Add($TopBar)

# [STATUS BAR / LOG]
$StatusBar = New-Object System.Windows.Forms.Panel; $StatusBar.Dock="Bottom"; $StatusBar.Height=30; $StatusBar.BackColor=$Theme.BgSidebar
$LblStatus = New-Object System.Windows.Forms.Label; $LblStatus.Text="Ready."; $LblStatus.ForeColor=$Theme.Accent; $LblStatus.Dock="Fill"; $LblStatus.TextAlign="MiddleLeft"; $LblStatus.Padding=New-Object System.Windows.Forms.Padding(10,0,0,0)
$StatusBar.Controls.Add($LblStatus)
$ContentContainer.Controls.Add($StatusBar)

# --- 5. PANELS & CONTENT ---
$Panels = @()

function Make-Panel ($Name) {
    $P = New-Object System.Windows.Forms.Panel
    $P.Dock = "Fill"
    $P.BackColor = $Theme.BgForm
    $P.Visible = $false
    $ContentContainer.Controls.Add($P)
    $P.BringToFront()
    $Global:Panels += $P
    return $P
}

# --- P1: DASHBOARD ---
$P_Dash = Make-Panel "Dashboard"
Add-SectionTitle $P_Dash "SYSTEM MONITOR" 20
# RAM/CPU Circles (Simulated with Progress Bars for simplicity in GDI)
$LblCPU = New-Object System.Windows.Forms.Label; $LblCPU.Location=New-Object System.Drawing.Point(30, 60); $LblCPU.AutoSize=$true; $LblCPU.ForeColor="White"; $P_Dash.Controls.Add($LblCPU)
$LblRAM = New-Object System.Windows.Forms.Label; $LblRAM.Location=New-Object System.Drawing.Point(200, 60); $LblRAM.AutoSize=$true; $LblRAM.ForeColor="White"; $P_Dash.Controls.Add($LblRAM)

$TxtInfo = New-Object System.Windows.Forms.TextBox; $TxtInfo.Multiline=$true; $TxtInfo.Location=New-Object System.Drawing.Point(30, 100); $TxtInfo.Size=New-Object System.Drawing.Size(700, 300); $TxtInfo.BackColor=$Theme.BgSidebar; $TxtInfo.ForeColor=$Theme.TextMain; $TxtInfo.BorderStyle="None"; $TxtInfo.Font=$Theme.FontMono; $TxtInfo.ReadOnly=$true
$P_Dash.Controls.Add($TxtInfo)
Add-ActionBtn $P_Dash "Tạo Restore Point (An Toàn)" "CreateRestore" 30 420 $false

# --- P2: OPTIMIZE ---
$P_Opt = Make-Panel "Optimize"
Add-SectionTitle $P_Opt "DỌN DẸP & TỐI ƯU" 20
Add-ActionBtn $P_Opt "Dọn Rác Hệ Thống (Temp)" "CleanTemp" 30 60
Add-ActionBtn $P_Opt "Xóa Cache Windows Update" "CleanUpd" 270 60
Add-ActionBtn $P_Opt "Bật Ultimate Performance" "UltPerf" 30 110
Add-ActionBtn $P_Opt "Tắt Apps Chạy Ngầm" "OffBgApps" 270 110
Add-ActionBtn $P_Opt "Tắt Telemetry (Theo dõi)" "OffTele" 30 160
Add-ActionBtn $P_Opt "Flush DNS Cache" "FlushDns" 270 160

Add-SectionTitle $P_Opt "BLOATWARE KILLER" 220
Add-ActionBtn $P_Opt "Gỡ Cortana" "DelCortana" 30 260 $true
Add-ActionBtn $P_Opt "Gỡ Xbox Apps" "DelXbox" 270 260 $true
Add-ActionBtn $P_Opt "Gỡ OneDrive" "DelOneDrive" 30 310 $true

# --- P3: INTERFACE ---
$P_UI = Make-Panel "Interface"
Add-SectionTitle $P_UI "CUSTOMIZE WINDOWS" 20
Add-ActionBtn $P_UI "Bật Dark Mode" "DarkMode" 30 60
Add-ActionBtn $P_UI "Bật Light Mode" "LightMode" 270 60
Add-ActionBtn $P_UI "Menu Chuột Phải Win 10" "OldMenu" 30 110
Add-ActionBtn $P_UI "Hiện File Ẩn" "ShowHidden" 270 110
Add-ActionBtn $P_UI "Restart Explorer" "RestartExp" 30 160 $true

# --- P4: NETWORK ---
$P_Net = Make-Panel "Network"
Add-SectionTitle $P_Net "DNS & MẠNG" 20
Add-ActionBtn $P_Net "DNS Google (8.8.8.8)" "DnsGo" 30 60
Add-ActionBtn $P_Net "DNS Cloudflare (1.1.1.1)" "DnsCf" 270 60
Add-ActionBtn $P_Net "DNS Tự Động (DHCP)" "DnsAuto" 30 110
Add-ActionBtn $P_Net "Reset Mạng (Fix lỗi)" "NetReset" 270 110 $true

# --- P5: TOOLS ---
$P_Tool = Make-Panel "Tools"
Add-SectionTitle $P_Tool "SHORTCUTS" 20
Add-ActionBtn $P_Tool "Control Panel" "OpenControl" 30 60
Add-ActionBtn $P_Tool "Registry Editor" "OpenReg" 270 60
Add-ActionBtn $P_Tool "Services" "OpenSvc" 30 110
Add-ActionBtn $P_Tool "Network Connections" "OpenNcpa" 270 110
Add-ActionBtn $P_Tool "God Mode Folder" "GodMode" 30 160

# --- NAV BUTTONS ---
Add-NavBtn $Sidebar "Dashboard" "📊" 80 $P_Dash
Add-NavBtn $Sidebar "Tối Ưu Hóa" "🚀" 130 $P_Opt
Add-NavBtn $Sidebar "Giao Diện" "🎨" 180 $P_UI
Add-NavBtn $Sidebar "Internet" "🌐" 230 $P_Net
Add-NavBtn $Sidebar "Công Cụ" "🛠️" 280 $P_Tool

# --- 6. LOGIC ENGINE ---
$script:ActivePanel = $null

function Switch-Panel ($Btn) {
    # Reset all buttons
    $Sidebar.Controls | Where-Object { $_.GetType().Name -eq "Label" -and $_.Tag -ne $null } | ForEach-Object {
        $_.ForeColor = $Theme.TextMuted
        $_.BackColor = "Transparent"
    }
    # Hide all panels
    $Global:Panels | ForEach-Object { $_.Visible = $false }
    
    # Activate
    $Btn.ForeColor = $Theme.Accent
    $Btn.BackColor = [System.Drawing.Color]::FromArgb(40,40,50)
    $Btn.Tag.Visible = $true
    $script:ActivePanel = $Btn.Tag
}

function Log ($Msg) {
    $LblStatus.Text = "$(Get-Date -Format 'HH:mm:ss') > $Msg"
    $Form.Refresh()
}

function Set-Reg ($Path, $Name, $Val) {
    if(!(Test-Path $Path)){New-Item $Path -Force | Out-Null}
    New-ItemProperty -Path $Path -Name $Name -Value $Val -PropertyType DWord -Force | Out-Null
}

function Run-Command ($Cmd, $Desc) {
    Log "Đang thực hiện: $Desc..."
    $Form.Cursor = "WaitCursor"
    
    switch ($Cmd) {
        "CreateRestore" { Checkpoint-Computer -Description "TitaniumV4_Backup" -RestorePointType "MODIFY_SETTINGS"; Log "Đã tạo Restore Point!" }
        "CleanTemp" { Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue; Log "Đã dọn dẹp Temp!" }
        "CleanUpd"  { Stop-Service wuauserv; Remove-Item "$env:windir\SoftwareDistribution\Download\*" -Recurse -Force; Start-Service wuauserv; Log "Đã xóa Cache Update!" }
        "UltPerf" { powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61; Log "Đã thêm Ultimate Performance!" }
        "OffBgApps" { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1; Log "Đã tắt Apps chạy ngầm!" }
        "OffTele" { Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0; Log "Đã tắt Telemetry!" }
        "FlushDns" { ipconfig /flushdns; Log "DNS Cache đã xóa!" }
        "DelCortana" { Get-AppxPackage -allusers *Cortana* | Remove-AppxPackage; Log "Đã gỡ Cortana!" }
        "DelXbox" { Get-AppxPackage *xbox* | Remove-AppxPackage; Log "Đã gỡ Xbox Apps!" }
        "DelOneDrive" { Stop-Process -Name "OneDrive" -Force; Start-Process "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" "/uninstall" -Wait; Log "Đã gỡ OneDrive!" }
        "DarkMode" { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 0; Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 0; Log "Dark Mode ON" }
        "LightMode" { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 1; Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 1; Log "Light Mode ON" }
        "OldMenu" { Set-Reg "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" "" ""; Log "Đã bật Menu cũ (Cần Restart Explorer)" }
        "ShowHidden" { Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" 1; Log "Đã hiện file ẩn" }
        "RestartExp" { Stop-Process -Name explorer -Force; Log "Đã khởi động lại Explorer" }
        "DnsGo" { Get-NetAdapter | Where Status -eq Up | Set-DnsClientServerAddress -ServerAddresses ("8.8.8.8","8.8.4.4"); Log "Đã set DNS Google" }
        "DnsCf" { Get-NetAdapter | Where Status -eq Up | Set-DnsClientServerAddress -ServerAddresses ("1.1.1.1","1.0.0.1"); Log "Đã set DNS Cloudflare" }
        "DnsAuto" { Get-NetAdapter | Where Status -eq Up | Set-DnsClientServerAddress -ResetServerAddresses; Log "Đã set Auto DNS" }
        "NetReset" { netsh int ip reset; netsh winsock reset; Log "Đã reset mạng (Cần Reboot)" }
        "GodMode" { New-Item "$env:USERPROFILE\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}" -ItemType Directory -Force; Log "Đã tạo GodMode trên Desktop" }
        # Shortcuts
        "OpenControl" { Start-Process "control" }
        "OpenReg" { Start-Process "regedit" }
        "OpenSvc" { Start-Process "services.msc" }
        "OpenNcpa" { Start-Process "ncpa.cpl" }
    }
    $Form.Cursor = "Default"
}

# --- 7. REAL-TIME MONITOR ---
$Timer = New-Object System.Windows.Forms.Timer
$Timer.Interval = 2000 # 2 seconds
$Timer.Add_Tick({
    $OS = Get-CimInstance Win32_OperatingSystem
    $TotalRAM = [Math]::Round(($OS.TotalVisibleMemorySize / 1MB), 1)
    $FreeRAM = [Math]::Round(($OS.FreePhysicalMemory / 1MB), 1)
    $UsedRAM = [Math]::Round($TotalRAM - $FreeRAM, 1)
    
    $LblCPU.Text = "CPU: $(Get-WmiObject Win32_Processor | Select -ExpandProperty LoadPercentage)%"
    $LblRAM.Text = "RAM: $UsedRAM GB / $TotalRAM GB"
    
    # Update Info Box once
    if ($TxtInfo.Text -eq "") {
         $TxtInfo.Text = "OS: $($OS.Caption)`r`nBuild: $($OS.BuildNumber)`r`nUser: $env:USERNAME`r`nArch: $($OS.OSArchitecture)"
    }
})
$Timer.Start()

# --- INIT START ---
Switch-Panel ($Sidebar.Controls | Where Text -match "Dashboard" | Select -First 1)
$Form.ShowDialog() | Out-Null
