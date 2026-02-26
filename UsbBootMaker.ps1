<#
    VENTOY BOOT MAKER - PHAT TAN PC (V14 DUAL GUI & PRO FOLDER TREE)
    Updates:
    - [GUI] Hỗ trợ cả WPF (Đẹp) và WinForms (WinPE Fallback). Nút chuyển đổi tự do.
    - [STRUCTURE] Tự động tạo cây thư mục chuyên nghiệp (ISO, DATA, BanQuyen...).
    - [CORE] Fix Memtest, Robust Extract, Bypass Win11.
#>

# --- 0. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $Arg = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell.exe -Verb RunAs -ArgumentList $Arg
    Exit
}

# --- 1. MÔI TRƯỜNG & BIẾN GLOBAL ---
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Load cơ bản
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Kiểm tra WPF
$Global:WpfAvailable = $false
try {
    Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
    Add-Type -AssemblyName PresentationCore -ErrorAction Stop
    $Global:WpfAvailable = $true
} catch {
    Write-Host "WPF không khả dụng trên môi trường này (Có thể là WinPE). Dùng WinForms Fallback." -ForegroundColor Yellow
}

$Global:UseWpf = $Global:WpfAvailable
$Global:AppRunning = $true

# Configs
$Global:VentoyRepo = "https://api.github.com/repos/ventoy/Ventoy/releases/latest"
$Global:MasUrl = "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version-KL/MAS_AIO.cmd"
$Global:ThemeConfigUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/refs/heads/main/themes.json" 
$Global:7zToolUrl = "https://github.com/develar/7zip-bin/raw/master/win/x64/7za.exe"
$Global:MemtestFallback = "https://www.memtest.org/download/v8.00/mt86plus_8.00_x86_64.iso.zip"
$Global:WorkDir = "C:\PhatTan_Ventoy_Temp"
$Global:DebugFile = "$PSScriptRoot\debug_log.txt" 
$Global:VersionFile = "$Global:WorkDir\version_info.txt"

if (!(Test-Path $Global:WorkDir)) { New-Item -ItemType Directory -Path $Global:WorkDir -Force | Out-Null }
"--- START LOG $(Get-Date) ---" | Out-File $Global:DebugFile -Encoding UTF8 -Force

# --- 2. HỆ THỐNG LÕI (CORE FUNCTIONS) ---

function Write-SystemLog ($Msg, $Color="Lime") {
    try { "$(Get-Date -F 'HH:mm:ss') | $Msg" | Out-File $Global:DebugFile -Append -Encoding UTF8 } catch {}
    
    # Bắn log ra màn hình đang active
    if ($Global:ActiveLogControl -ne $null) {
        if ($Global:UseWpf) {
            $Global:ActiveLogControl.Dispatcher.Invoke({
                $Global:ActiveLogControl.AppendText("[$(Get-Date -F 'HH:mm:ss')] $Msg`r`n")
                $Global:ActiveLogControl.ScrollToEnd()
            })
        } else {
            try {
                $Global:ActiveForm.Invoke([Action]{
                    $Global:ActiveLogControl.SelectionStart = $Global:ActiveLogControl.TextLength
                    $Global:ActiveLogControl.SelectionLength = 0
                    $Global:ActiveLogControl.SelectionColor = [System.Drawing.Color]::FromName($Color)
                    $Global:ActiveLogControl.AppendText("[$(Get-Date -F 'HH:mm:ss')] $Msg`r`n")
                    $Global:ActiveLogControl.ScrollToCaret()
                })
            } catch {}
        }
    }
}

function Create-Ventoy-Structure ($UsbRoot) {
    Write-SystemLog "Đang tạo cấu trúc thư mục Phát Tấn PC..." "Cyan"
    $Dirs = @(
        "ventoy\script", "ventoy\themes\theme-vfc",
        "ISO_Windows\Win7", "ISO_Windows\Win10", "ISO_Windows\Win11", "ISO_Windows\LTSC10", "ISO_Windows\LTSC11", "ISO_Windows\Server", "ISO_Windows\LTSC",
        "ISO_Linux\Ubuntu", "ISO_Linux\Kali", "ISO_Linux\Mint", "ISO_Linux\CentOS",
        "ISO_Rescue", "Tools_Drivers", "ISO_Android",
        "DATA\Documents", "DATA\Music", "DATA\Picture", "DATA\Video", "DATA\App", "DATA\Shortcut",
        "BanQuyen\Windows7", "BanQuyen\Windows10", "BanQuyen\Windows11", "BanQuyen\Office", "BanQuyen\Keys"
    )

    foreach ($d in $Dirs) {
        $Path = Join-Path $UsbRoot $d
        if (!(Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
    }

    # Tạo file ReadMe
    $ReadMeContent = "USB BOOT MASTER - PHAT TAN PC`nCreated: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')`nTool version: 14.0`nOwner: Dang Lam Tan Phat"
    $ReadMeContent | Out-File (Join-Path $UsbRoot "ReadMe.txt") -Encoding UTF8 -Force

    # Dummy files (Để sẵn cho khách copy đè)
    $IsoPath = Join-Path $UsbRoot "NangCap_UsbBoot.iso"
    if (!(Test-Path $IsoPath)) { Set-Content -Path $IsoPath -Value "Vui long thay the bang file ISO that." -Force }

    $WimPath = Join-Path $UsbRoot "install.wim"
    if (!(Test-Path $WimPath)) { Set-Content -Path $WimPath -Value "Vui long thay the bang file WIM that." -Force }

    Write-SystemLog "Tạo cấu trúc thư mục hoàn tất!" "Success"
}

function Force-Disk-Refresh {
    Write-SystemLog "Rescan Disk..." "Yellow"
    try {
        "rescan" | Out-File "$env:TEMP\dp_rescan.txt" -Encoding ASCII -Force
        Start-Process diskpart -ArgumentList "/s `"$env:TEMP\dp_rescan.txt`"" -Wait -WindowStyle Hidden
        Start-Sleep -Seconds 2
    } catch {}
}

function Get-DriveLetter-DiskPart ($DiskIndex) {
    try {
        $DpScript = "$env:TEMP\dp_vol_check.txt"
        "select disk $DiskIndex`ndetail disk" | Out-File $DpScript -Encoding ASCII -Force
        $Output = & diskpart /s $DpScript
        foreach ($Line in $Output) { if ($Line -match "Volume \d+\s+([A-Z])\s+") { return "$($Matches[1]):" } }
    } catch {}
    return $null
}

function Get-Usb-List {
    $List = @()
    Force-Disk-Refresh
    if (Get-Command Get-Disk -EA 0) { 
        try { 
            $Disks = Get-Disk | Where-Object { $_.BusType -eq "USB" -or $_.MediaType -eq "Removable" }
            if ($Disks) { foreach ($d in $Disks) { $List += "Disk $($d.Number): $($d.FriendlyName) - $([Math]::Round($d.Size / 1GB, 1)) GB" } } 
        } catch {} 
    }
    if ($List.Count -eq 0) { 
        try { 
            $WmiDisks = Get-WmiObject Win32_DiskDrive | Where-Object { $_.InterfaceType -eq "USB" -or $_.MediaType -match "Removable" }
            if ($WmiDisks) { foreach ($d in $WmiDisks) { $Size = if ($d.Size) { $d.Size } else { 0 }; $List += "Disk $($d.Index): $($d.Model) - $([Math]::Round($Size / 1GB, 1)) GB" } } 
        } catch {} 
    }
    if ($List.Count -eq 0) { $List += "Không tìm thấy USB" }
    return $List
}

function Download-File-Robust ($Url, $Dest) {
    $Max = 3; $Count = 0; $Success = $false
    while (-not $Success -and $Count -lt $Max) {
        try {
            $Count++; Invoke-WebRequest -Uri $Url -OutFile $Dest -UseBasicParsing -TimeoutSec 300 -ErrorAction Stop
            if ((Get-Item $Dest).Length -gt 1KB) { $Success = $true }
        } catch { Start-Sleep -Seconds 2 }
    }
    if (-not $Success) { throw "Tải lỗi!" }
}

function Prepare-Ventoy-Core {
    $ZipFile = "$Global:WorkDir\ventoy.zip"; $ExtractPath = "$Global:WorkDir\Extracted"
    $CurrentVer = if (Test-Path $Global:VersionFile) { Get-Content $Global:VersionFile } else { "v0.0.0" }
    
    try {
        $Assets = Invoke-RestMethod -Uri $Global:VentoyRepo -UseBasicParsing -TimeoutSec 5
        $LatestVer = $Assets.tag_name
        $Url = ($Assets.assets | Where-Object { $_.name -match "windows.zip" }).browser_download_url
        
        if ($LatestVer -ne $CurrentVer -or !(Test-Path "$ExtractPath\ventoy\Ventoy2Disk.exe")) {
            Write-SystemLog "Tải Ventoy Core ($LatestVer)..." "Cyan"
            Download-File-Robust $Url $ZipFile
            if (Test-Path $ExtractPath) { Remove-Item $ExtractPath -Recurse -Force }
            [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $ExtractPath)
            $LatestVer | Out-File $Global:VersionFile -Force
        }
    } catch { Write-SystemLog "Dùng bản Offline do lỗi mạng." "Yellow" }
    
    $Global:VentoyExe = Get-ChildItem -Path $ExtractPath -Filter "Ventoy2Disk.exe" -Recurse | Select -First 1 | %{$_.FullName}
}

function Execute-VentoyProcess ($Config) {
    # Giải nén config
    $DiskID = $Config.DiskID; $Mode = $Config.Mode; $Style = $Config.Style; $LabelName = $Config.LabelName
    $FSType = $Config.FSType; $Alias = $Config.Alias; $MkDir = $Config.MkDir; $Secure = $Config.Secure
    $BypassCheck = $Config.BypassCheck; $BypassNro = $Config.BypassNro
    
    Prepare-Ventoy-Core
    if (!$Global:VentoyExe) { Write-SystemLog "Lỗi: Không có Ventoy Core!" "Red"; return }
    
    Force-Disk-Refresh; $DL = Get-DriveLetter-DiskPart $DiskID
    if (!$DL) { Write-SystemLog "Lỗi: Không tìm thấy Drive Letter!" "Red"; return }

    $FlagMode = if ($Mode -eq "UPDATE") { "/U" } else { "/I" }
    $FlagStyle = if ($Style -match "GPT") { "/GPT" } else { "/MBR" }
    $FlagSecure = if ($Secure) { "/S" } else { "" }
    $FlagFS = if ($Mode -eq "INSTALL") { if ($FSType -match "NTFS") { "/FS:NTFS" } elseif ($FSType -match "FAT32") { "/FS:FAT32" } else { "/FS:exFAT" } } else { "" }

    Write-SystemLog "Chạy cài đặt Ventoy trên Disk $DiskID..." "Cyan"
    $P = Start-Process -FilePath $Global:VentoyExe -ArgumentList "VTOYCLI $FlagMode /Drive:$DL /NoUsbCheck $FlagStyle $FlagSecure $FlagFS" -PassThru -Wait
    
    if ($P.ExitCode -eq 0) {
        Write-SystemLog "Hoàn tất lõi Ventoy! Đang config..." "Yellow"
        $UsbRoot = $null
        for ($i = 0; $i -lt 15; $i++) { Force-Disk-Refresh; $TempDL = Get-DriveLetter-DiskPart $DiskID; if ($TempDL -and (Test-Path $TempDL)) { $UsbRoot = $TempDL; break }; Start-Sleep 1 }
        if (!$UsbRoot) { $UsbRoot = $DL }
        
        if (Test-Path $UsbRoot) {
            if ($Mode -eq "INSTALL") { try { cmd /c "label $UsbRoot $LabelName" } catch {} }
            $VentoyDir = "$UsbRoot\ventoy"; New-Item -Path $VentoyDir -ItemType Directory -Force | Out-Null
            
            # Cấu trúc thư mục
            if ($MkDir) { Create-Ventoy-Structure $UsbRoot }
            
            # Tải MAS
            try { Write-SystemLog "Tải MAS..."; Invoke-WebRequest $Global:MasUrl -OutFile "$UsbRoot\MAS_AIO.cmd" -UseBasicParsing | Out-Null } catch {}

            # Tạo JSON Win 11 Hacks
            $JControl = @(@{ "VTOY_DEFAULT_MENU_MODE" = "0" })
            if ($BypassCheck) { $JControl += @{ "VTOY_WIN11_BYPASS_CHECK" = "1" } }
            if ($BypassNro) { $JControl += @{ "VTOY_WIN11_BYPASS_NRO" = "1" } }

            $J = @{ "control" = $JControl; "menu_alias" = @( @{ "image" = "/ventoy/ventoy.png"; "alias" = $Alias } ) }
            $J | ConvertTo-Json -Depth 10 | Out-File "$VentoyDir\ventoy.json" -Encoding UTF8 -Force
            
            Write-SystemLog "MỌI THỨ ĐÃ HOÀN TẤT!" "Success"
            [System.Windows.Forms.MessageBox]::Show("Tạo USB BOOT thành công!", "Phat Tan PC")
        }
    } else { Write-SystemLog "Ventoy ExitCode = $($P.ExitCode). Thất bại!" "Red" }
}

# --- 3. GIAO DIỆN WPF (DÀNH CHO MÁY FULL) ---
function Show-WpfGUI {
    $XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="PHAT TAN VENTOY V14 (WPF ENGINE)" Height="650" Width="800" Background="#1E1E23" WindowStartupLocation="CenterScreen">
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <StackPanel Grid.Row="0" Margin="0,0,0,15">
            <TextBlock Text="USB BOOT MASTER - VENTOY EDITION" FontSize="22" FontWeight="Bold" Foreground="#00B4FF"/>
            <TextBlock Text="Giao diện WPF mượt mà | Cấu trúc chuẩn | Win11 Bypass" Foreground="Gray" FontSize="12"/>
        </StackPanel>
        
        <Border Grid.Row="1" Background="#2D2D32" CornerRadius="8" Padding="15" Margin="0,0,0,15">
            <StackPanel>
                <TextBlock Text="CHỌN USB MỤC TIÊU:" Foreground="Silver" FontWeight="Bold" Margin="0,0,0,10"/>
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="100"/>
                        <ColumnDefinition Width="150"/>
                    </Grid.ColumnDefinitions>
                    <ComboBox Name="CbUsb" Grid.Column="0" Height="30" FontSize="14" Margin="0,0,10,0"/>
                    <Button Name="BtnRefresh" Grid.Column="1" Content="↻ Làm Mới" Height="30" Margin="0,0,10,0" Background="#3C3C46" Foreground="White"/>
                    <Button Name="BtnSwitchUI" Grid.Column="2" Content="Chuyển WinForms" Height="30" Background="#FFA500" Foreground="Black" FontWeight="Bold"/>
                </Grid>
                
                <WrapPanel Margin="0,15,0,0">
                    <CheckBox Name="ChkDir" Content="Tự tạo cây thư mục chuẩn (ISO, DATA, BanQuyen...)" IsChecked="True" Foreground="#32CD32" Margin="0,0,20,5"/>
                    <CheckBox Name="ChkBypass" Content="Bypass TPM 2.0 &amp; CPU Win 11" IsChecked="True" Foreground="White" Margin="0,0,20,5"/>
                    <CheckBox Name="ChkNro" Content="Bypass Account Online" IsChecked="True" Foreground="White"/>
                </WrapPanel>
            </StackPanel>
        </Border>

        <Border Grid.Row="2" Background="Black" CornerRadius="5" Padding="5" Margin="0,0,0,15">
            <TextBox Name="TxtLog" Background="Transparent" Foreground="#00FF00" FontFamily="Consolas" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" IsReadOnly="True" BorderThickness="0"/>
        </Border>

        <Button Name="BtnStart" Grid.Row="3" Content="🚀 BẮT ĐẦU TẠO BOOT" Height="45" FontSize="16" FontWeight="Bold" Background="#00B4FF" Foreground="Black"/>
    </Grid>
</Window>
"@
    $Reader = New-Object System.Xml.XmlNodeReader([xml]$XAML)
    $WpfWindow = [Windows.Markup.XamlReader]::Load($Reader)
    
    $CbUsb = $WpfWindow.FindName("CbUsb")
    $BtnRefresh = $WpfWindow.FindName("BtnRefresh")
    $BtnSwitchUI = $WpfWindow.FindName("BtnSwitchUI")
    $ChkDir = $WpfWindow.FindName("ChkDir")
    $ChkBypass = $WpfWindow.FindName("ChkBypass")
    $ChkNro = $WpfWindow.FindName("ChkNro")
    $TxtLog = $WpfWindow.FindName("TxtLog")
    $BtnStart = $WpfWindow.FindName("BtnStart")
    
    $Global:ActiveLogControl = $TxtLog
    $Global:ActiveForm = $null

    # Load USB initial
    foreach ($u in (Get-Usb-List)) { $CbUsb.Items.Add($u) }
    if ($CbUsb.Items.Count -gt 0) { $CbUsb.SelectedIndex = 0 }

    $BtnRefresh.Add_Click({
        $CbUsb.Items.Clear()
        foreach ($u in (Get-Usb-List)) { $CbUsb.Items.Add($u) }
        if ($CbUsb.Items.Count -gt 0) { $CbUsb.SelectedIndex = 0 }
    })

    $BtnSwitchUI.Add_Click({
        $Global:UseWpf = $false
        $WpfWindow.Close()
    })

    $BtnStart.Add_Click({
        $Sel = $CbUsb.SelectedItem
        if ($Sel -match "Disk (\d+)") {
            if ([System.Windows.Forms.MessageBox]::Show("Toàn bộ dữ liệu trên USB sẽ bị xóa. Tiếp tục?", "Cảnh báo", "YesNo", "Warning") -eq "Yes") {
                $BtnStart.IsEnabled = $false
                $Config = @{
                    DiskID = $Matches[1]; Mode = "INSTALL"; Style = "MBR"; LabelName = "PHATTAN_BOOT"
                    FSType = "exFAT"; Alias = "PHAT TAN RESCUE"; MkDir = [bool]$ChkDir.IsChecked
                    Secure = $true; BypassCheck = [bool]$ChkBypass.IsChecked; BypassNro = [bool]$ChkNro.IsChecked
                }
                # Chạy nền để không đơ UI
                $RunSpace = [runspacefactory]::CreateRunspace()
                $RunSpace.Open()
                $Pipe = $RunSpace.CreatePipeline()
                $Pipe.Commands.AddScript({ param($c) Execute-VentoyProcess $c }) | Out-Null
                $Pipe.Commands[0].Parameters.Add("c", $Config)
                $Pipe.InvokeAsync()
            }
        }
    })

    $WpfWindow.ShowDialog() | Out-Null
}

# --- 4. GIAO DIỆN WINFORMS (FALLBACK CHO WINPE) ---
function Show-WinFormsGUI {
    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = "PHAT TAN VENTOY V14 (WINFORMS ENGINE)"; $Form.Size = "800,650"; $Form.StartPosition = "CenterScreen"
    $Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 35); $Form.ForeColor = [System.Drawing.Color]::White

    $FTitle = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $FNorm = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)

    $LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "USB BOOT MASTER - VENTOY EDITION"; $LblT.Font = $FTitle; $LblT.ForeColor = [System.Drawing.Color]::DeepSkyBlue; $LblT.AutoSize = $true; $LblT.Location = "15,15"
    $Form.Controls.Add($LblT)

    $BtnSwitchUI = New-Object System.Windows.Forms.Button; $BtnSwitchUI.Text = "Chuyển sang WPF"; $BtnSwitchUI.Bounds = "620,15,150,30"; $BtnSwitchUI.BackColor = [System.Drawing.Color]::Orange; $BtnSwitchUI.ForeColor = [System.Drawing.Color]::Black; $BtnSwitchUI.Font = $FNorm; $BtnSwitchUI.FlatStyle = "Flat"
    $Form.Controls.Add($BtnSwitchUI)

    $CbUsb = New-Object System.Windows.Forms.ComboBox; $CbUsb.Bounds = "15,60,500,30"; $CbUsb.Font = $FNorm; $CbUsb.DropDownStyle = "DropDownList"
    $BtnRefresh = New-Object System.Windows.Forms.Button; $BtnRefresh.Text = "↻ Refresh"; $BtnRefresh.Bounds = "525,59,100,30"; $BtnRefresh.BackColor = [System.Drawing.Color]::DimGray
    $Form.Controls.Add($CbUsb); $Form.Controls.Add($BtnRefresh)

    $ChkDir = New-Object System.Windows.Forms.CheckBox; $ChkDir.Text = "Tạo cấu trúc thư mục (ISO, DATA, BanQuyen...)"; $ChkDir.Bounds = "15,100,400,20"; $ChkDir.Checked = $true; $ChkDir.ForeColor = [System.Drawing.Color]::LimeGreen
    $ChkBypass = New-Object System.Windows.Forms.CheckBox; $ChkBypass.Text = "Bypass TPM/CPU Win 11"; $ChkBypass.Bounds = "15,125,250,20"; $ChkBypass.Checked = $true
    $ChkNro = New-Object System.Windows.Forms.CheckBox; $ChkNro.Text = "Bypass NRO (Online Account)"; $ChkNro.Bounds = "270,125,250,20"; $ChkNro.Checked = $true
    $Form.Controls.Add($ChkDir); $Form.Controls.Add($ChkBypass); $Form.Controls.Add($ChkNro)

    $TxtLog = New-Object System.Windows.Forms.RichTextBox; $TxtLog.Bounds = "15,160,750,380"; $TxtLog.BackColor = [System.Drawing.Color]::Black; $TxtLog.ForeColor = [System.Drawing.Color]::Lime; $TxtLog.Font = New-Object System.Drawing.Font("Consolas", 10); $TxtLog.ReadOnly = $true
    $Form.Controls.Add($TxtLog)

    $BtnStart = New-Object System.Windows.Forms.Button; $BtnStart.Text = "🚀 BẮT ĐẦU TẠO BOOT"; $BtnStart.Bounds = "15,550,750,45"; $BtnStart.Font = $FTitle; $BtnStart.BackColor = [System.Drawing.Color]::DeepSkyBlue; $BtnStart.ForeColor = [System.Drawing.Color]::Black; $BtnStart.FlatStyle = "Flat"
    $Form.Controls.Add($BtnStart)

    $Global:ActiveLogControl = $TxtLog
    $Global:ActiveForm = $Form

    # Func load
    $LoadUsb = { $CbUsb.Items.Clear(); foreach ($u in (Get-Usb-List)) { [void]$CbUsb.Items.Add($u) }; if ($CbUsb.Items.Count -gt 0) { $CbUsb.SelectedIndex = 0 } }
    & $LoadUsb

    $BtnRefresh.Add_Click($LoadUsb)
    
    $BtnSwitchUI.Add_Click({
        if ($Global:WpfAvailable) { $Global:UseWpf = $true; $Form.Close() } 
        else { [System.Windows.Forms.MessageBox]::Show("WinPE/Windows Lite của bạn không có thư viện WPF!") }
    })

    $BtnStart.Add_Click({
        $Sel = $CbUsb.SelectedItem
        if ($Sel -match "Disk (\d+)") {
            if ([System.Windows.Forms.MessageBox]::Show("Dữ liệu sẽ bị xóa! Tiếp tục?", "Warning", "YesNo") -eq "Yes") {
                $BtnStart.Enabled = $false
                $Config = @{
                    DiskID = $Matches[1]; Mode = "INSTALL"; Style = "MBR"; LabelName = "PHATTAN_BOOT"
                    FSType = "exFAT"; Alias = "PHAT TAN RESCUE"; MkDir = $ChkDir.Checked
                    Secure = $true; BypassCheck = $ChkBypass.Checked; BypassNro = $ChkNro.Checked
                }
                Execute-VentoyProcess $Config
                $BtnStart.Enabled = $true
            }
        }
    })

    $Form.ShowDialog() | Out-Null
}

# --- 5. MAIN LOOP CONTROLLER ---
while ($Global:AppRunning) {
    if ($Global:UseWpf -and $Global:WpfAvailable) {
        Show-WpfGUI
        # Nếu form bị đóng mà không phải do nhấn SwitchUI -> Thoát script
        if ($Global:UseWpf) { $Global:AppRunning = $false } 
    } else {
        Show-WinFormsGUI
        # Nếu form bị đóng mà không phải do nhấn SwitchUI -> Thoát script
        if (-not $Global:UseWpf) { $Global:AppRunning = $false }
    }
}
