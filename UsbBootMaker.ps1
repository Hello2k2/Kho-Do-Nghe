<#
    VENTOY BOOT MAKER - PHAT TAN PC (V15 ULTIMATE)
    Updates:
    - [FULL FEATURE] Khôi phục toàn bộ tính năng: Theme Online, Memtest, Password Boot, Format Type, Mode MBR/GPT.
    - [GUI] Dual Engine: WPF (Tab Control Đẹp) & WinForms (Tab Control Fallback).
    - [STRUCTURE] Tự động tạo cây thư mục chuyên nghiệp.
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

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.IO.Compression.FileSystem

$Global:WpfAvailable = $false
try { Add-Type -AssemblyName PresentationFramework -EA Stop; Add-Type -AssemblyName PresentationCore -EA Stop; $Global:WpfAvailable = $true } catch {}

$Global:UseWpf = $Global:WpfAvailable; $Global:AppRunning = $true

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

# --- 2. HỆ THỐNG LÕI & HELPER ---
function Write-SystemLog ($Msg, $Color="Lime") {
    try { "$(Get-Date -F 'HH:mm:ss') | $Msg" | Out-File $Global:DebugFile -Append -Encoding UTF8 } catch {}
    if ($Global:ActiveLogControl -ne $null) {
        if ($Global:UseWpf) {
            $Global:ActiveLogControl.Dispatcher.Invoke({
                $Global:ActiveLogControl.AppendText("[$(Get-Date -F 'HH:mm:ss')] $Msg`r`n")
                $Global:ActiveLogControl.ScrollToEnd()
            })
        } else {
            try { $Global:ActiveForm.Invoke([Action]{
                $Global:ActiveLogControl.SelectionStart = $Global:ActiveLogControl.TextLength; $Global:ActiveLogControl.SelectionLength = 0
                $Global:ActiveLogControl.SelectionColor = [System.Drawing.Color]::FromName($Color); $Global:ActiveLogControl.AppendText("[$(Get-Date -F 'HH:mm:ss')] $Msg`r`n")
                $Global:ActiveLogControl.ScrollToCaret()
            })} catch {}
        }
    }
}

function Get-Sha256 ($String) {
    $Sha = [System.Security.Cryptography.SHA256]::Create()
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($String)
    $Hash = $Sha.ComputeHash($Bytes)
    return [BitConverter]::ToString($Hash).Replace("-", "").ToLower()
}

function Create-Ventoy-Structure ($UsbRoot) {
    Write-SystemLog "Đang tạo cấu trúc thư mục Phát Tấn PC..." "Cyan"
    $Dirs = @( "ventoy\script", "ventoy\themes\theme-vfc", "ISO_Windows\Win7", "ISO_Windows\Win10", "ISO_Windows\Win11", "ISO_Windows\LTSC10", "ISO_Windows\LTSC11", "ISO_Windows\Server", "ISO_Windows\LTSC", "ISO_Linux\Ubuntu", "ISO_Linux\Kali", "ISO_Linux\Mint", "ISO_Linux\CentOS", "ISO_Rescue", "Tools_Drivers", "ISO_Android", "DATA\Documents", "DATA\Music", "DATA\Picture", "DATA\Video", "DATA\App", "DATA\Shortcut", "BanQuyen\Windows7", "BanQuyen\Windows10", "BanQuyen\Windows11", "BanQuyen\Office", "BanQuyen\Keys" )
    foreach ($d in $Dirs) { $Path = Join-Path $UsbRoot $d; if (!(Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null } }
    "USB BOOT MASTER - PHAT TAN PC`nCreated: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')`nTool version: 15.0" | Out-File (Join-Path $UsbRoot "ReadMe.txt") -Encoding UTF8 -Force
}

function Force-Disk-Refresh { Write-SystemLog "Rescan Disk..." "Yellow"; try { "rescan" | Out-File "$env:TEMP\dp_rescan.txt" -Encoding ASCII -Force; Start-Process diskpart -ArgumentList "/s `"$env:TEMP\dp_rescan.txt`"" -Wait -WindowStyle Hidden; Start-Sleep -Seconds 2 } catch {} }

function Get-DriveLetter-DiskPart ($DiskIndex) { try { $DpScript = "$env:TEMP\dp_vol_check.txt"; "select disk $DiskIndex`ndetail disk" | Out-File $DpScript -Encoding ASCII -Force; $Output = & diskpart /s $DpScript; foreach ($Line in $Output) { if ($Line -match "Volume \d+\s+([A-Z])\s+") { return "$($Matches[1]):" } } } catch {}; return $null }

function Download-File-Robust ($Url, $Dest) {
    $Max = 3; $Count = 0; $Success = $false
    while (-not $Success -and $Count -lt $Max) {
        try { $Count++; Invoke-WebRequest -Uri $Url -OutFile $Dest -UseBasicParsing -TimeoutSec 300 -EA Stop; if ((Get-Item $Dest).Length -gt 1KB) { $Success = $true } } catch { Start-Sleep 2 }
    }
    if (-not $Success) { throw "Tải lỗi!" }
}

function Extract-Recursive ($SourceFile, $DestDir) {
    if (Test-Path $DestDir) { Remove-Item $DestDir -Recurse -Force }; New-Item $DestDir -ItemType Directory | Out-Null
    Write-SystemLog "Giải nén: $([System.IO.Path]::GetFileName($SourceFile))" "Yellow"
    $7zExe = "$Global:WorkDir\7za.exe"; if (!(Test-Path $7zExe)) { Download-File-Robust $Global:7zToolUrl $7zExe }
    $Proc = Start-Process -FilePath $7zExe -ArgumentList "x `"$SourceFile`" -o`"$DestDir`" -y -bso0 -bsp0" -Wait -NoNewWindow -PassThru
    if ($Proc.ExitCode -ne 0) { try { [System.IO.Compression.ZipFile]::ExtractToDirectory($SourceFile, $DestDir) } catch { throw "Lỗi giải nén" } }
    $InnerTar = Get-ChildItem -Path $DestDir -Filter "*.tar" | Select -First 1
    if ($InnerTar) { Start-Process -FilePath $7zExe -ArgumentList "x `"$($InnerTar.FullName)`" -o`"$DestDir`" -y -bso0 -bsp0" -Wait -NoNewWindow | Out-Null; Remove-Item $InnerTar.FullName -Force }
}

function Prepare-Ventoy-Core {
    $ZipFile = "$Global:WorkDir\ventoy.zip"; $ExtractPath = "$Global:WorkDir\Extracted"
    $CurrentVer = if (Test-Path $Global:VersionFile) { Get-Content $Global:VersionFile } else { "v0.0.0" }
    try {
        $Assets = Invoke-RestMethod -Uri $Global:VentoyRepo -UseBasicParsing -TimeoutSec 5; $LatestVer = $Assets.tag_name
        if ($LatestVer -ne $CurrentVer -or !(Test-Path "$ExtractPath\ventoy\Ventoy2Disk.exe")) {
            Write-SystemLog "Tải Ventoy Core ($LatestVer)..." "Cyan"
            $Url = ($Assets.assets | Where-Object { $_.name -match "windows.zip" }).browser_download_url
            Download-File-Robust $Url $ZipFile
            if (Test-Path $ExtractPath) { Remove-Item $ExtractPath -Recurse -Force }
            [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $ExtractPath)
            $LatestVer | Out-File $Global:VersionFile -Force
        }
    } catch { Write-SystemLog "Dùng bản Offline do lỗi mạng." "Yellow" }
    $Global:VentoyExe = Get-ChildItem -Path $ExtractPath -Filter "Ventoy2Disk.exe" -Recurse | Select -First 1 | %{$_.FullName}
}

function Load-Themes-Online {
    Write-SystemLog "Tải danh sách Theme..." "Cyan"; $List = @("Mặc định (Ventoy)")
    try { $Global:ThemeData = Invoke-RestMethod -Uri $Global:ThemeConfigUrl -TimeoutSec 3 -EA Stop; foreach ($item in $Global:ThemeData) { if ($item.type -eq "GRUB" -and $item.link) { $List += $item.name } }; Write-SystemLog "Tải danh sách Theme xong!" "Success" } catch { Write-SystemLog "Lỗi tải Theme Online." "Red" }
    return $List
}

function Execute-VentoyProcess ($Config) {
    Prepare-Ventoy-Core; if (!$Global:VentoyExe) { Write-SystemLog "Lỗi: Không có Ventoy Core!" "Red"; return }
    Force-Disk-Refresh; $DL = Get-DriveLetter-DiskPart $Config.DiskID
    if (!$DL) { Write-SystemLog "Lỗi: Không tìm Drive Letter!" "Red"; return }

    $FlagMode = if ($Config.Mode -eq "Cập nhật Ventoy") { "/U" } else { "/I" }
    $FlagStyle = if ($Config.Style -match "GPT") { "/GPT" } else { "/MBR" }
    $FlagSecure = if ($Config.Secure) { "/S" } else { "" }
    $FlagFS = if ($Config.Mode -match "Cài mới") { if ($Config.FSType -match "NTFS") { "/FS:NTFS" } elseif ($Config.FSType -match "FAT32") { "/FS:FAT32" } else { "/FS:exFAT" } } else { "" }

    Write-SystemLog "Chạy cài đặt Ventoy..." "Cyan"
    $P = Start-Process -FilePath $Global:VentoyExe -ArgumentList "VTOYCLI $FlagMode /Drive:$DL /NoUsbCheck $FlagStyle $FlagSecure $FlagFS" -PassThru -Wait
    
    if ($P.ExitCode -eq 0) {
        Write-SystemLog "Cài Core OK! Đang config..." "Yellow"; $UsbRoot = $null
        for ($i = 0; $i -lt 20; $i++) { Force-Disk-Refresh; $TempDL = Get-DriveLetter-DiskPart $Config.DiskID; if ($TempDL -and (Test-Path $TempDL)) { $UsbRoot = $TempDL; break }; Start-Sleep 1 }
        if (!$UsbRoot) { $UsbRoot = $DL }
        
        if (Test-Path $UsbRoot) {
            if ($Config.Mode -match "Cài mới") { try { cmd /c "label $UsbRoot $($Config.LabelName)" } catch {} }
            $VentoyDir = "$UsbRoot\ventoy"; New-Item -Path $VentoyDir -ItemType Directory -Force | Out-Null
            if ($Config.MkDir) { Create-Ventoy-Structure $UsbRoot }
            
            # --- Memtest & MAS ---
            if ($Config.GetMemtest) {
                try {
                    Write-SystemLog "Tải Memtest86+..." "Cyan"
                    $MemZip = "$Global:WorkDir\memtest.zip"; $MemExtract = "$Global:WorkDir\MemtestExtract"
                    Download-File-Robust $Global:MemtestFallback $MemZip; Extract-Recursive $MemZip $MemExtract
                    $RealIso = Get-ChildItem -Path $MemExtract -Filter "*.iso" -Recurse | Select -First 1
                    if ($RealIso) {
                        $IsoRescueDir = "$UsbRoot\ISO_Rescue"; if (!(Test-Path $IsoRescueDir)) { New-Item -Path $IsoRescueDir -ItemType Directory -Force | Out-Null }
                        Copy-Item $RealIso.FullName "$IsoRescueDir\memtest86+.iso" -Force; Write-SystemLog "Memtest OK!" "Success"
                    }
                } catch { Write-SystemLog "Lỗi tải Memtest" "Red" }
            }
            if ($Config.GetMas) { try { Invoke-WebRequest $Global:MasUrl -OutFile "$UsbRoot\MAS_AIO.cmd" -UseBasicParsing | Out-Null; Write-SystemLog "MAS OK" "Success" } catch {} }

            # --- Theme ---
            $ThemeConfig = $null
            if ($Config.ThemeName -ne "Mặc định (Ventoy)" -and $Global:ThemeData) {
                $T = $Global:ThemeData | Where-Object { $_.Name -eq $Config.ThemeName } | Select -First 1
                if ($T) {
                    try {
                        Write-SystemLog "Tải Theme $($T.Name)..." "Cyan"
                        $ThemeFile = "$Global:WorkDir\theme_temp.zip"; Download-File-Robust $T.Link $ThemeFile
                        $ThemeDest = "$VentoyDir\themes"; Extract-Recursive $ThemeFile $ThemeDest
                        $ThemeTxt = Get-ChildItem -Path $ThemeDest -Filter "theme.txt" -Recurse | Select -First 1
                        if ($ThemeTxt) { $RelPath = $ThemeTxt.FullName.Substring($VentoyDir.Length).Replace("\", "/"); $ThemeConfig = "/ventoy$RelPath"; Write-SystemLog "Theme OK!" "Success" }
                    } catch { Write-SystemLog "Lỗi Theme" "Red" }
                }
            }

            # --- JSON ---
            $JControl = @(@{ "VTOY_DEFAULT_MENU_MODE" = "0" }, @{ "VTOY_FILT_DOT_UNDERSCORE_FILE" = "1" })
            if ($Config.BypassCheck) { $JControl += @{ "VTOY_WIN11_BYPASS_CHECK" = "1" } }
            if ($Config.BypassNro) { $JControl += @{ "VTOY_WIN11_BYPASS_NRO" = "1" } }
            
            $J = @{ "control" = $JControl; "theme" = @{ "display_mode" = "GUI"; "gfxmode" = "1920x1080" }; "menu_alias" = @( @{ "image" = "/ventoy/ventoy.png"; "alias" = $Config.Alias } ) }
            if ($Config.Password -ne "") { $J.Add("password", @{ "menupwd" = (Get-Sha256 $Config.Password) }); Write-SystemLog "Set Pass OK" "Cyan" }
            if ($ThemeConfig) { $J.theme.Add("file", $ThemeConfig) }
            
            $J | ConvertTo-Json -Depth 10 | Out-File "$VentoyDir\ventoy.json" -Encoding UTF8 -Force
            Write-SystemLog "DONE!" "Success"; [System.Windows.Forms.MessageBox]::Show("Tạo BOOT thành công!", "Phat Tan PC"); Invoke-Item $UsbRoot
        }
    } else { Write-SystemLog "Lỗi Ventoy ExitCode!" "Red" }
}

function Get-Usb-List-String {
    $L = @(); Force-Disk-Refresh
    try { $Disks = Get-Disk | Where-Object { $_.BusType -eq "USB" -or $_.MediaType -eq "Removable" }; foreach ($d in $Disks) { $L += "Disk $($d.Number): $($d.FriendlyName) - $([Math]::Round($d.Size/1GB,1))GB" } } catch {}
    if ($L.Count -eq 0) { try { $Wmi = Get-WmiObject Win32_DiskDrive | Where-Object { $_.InterfaceType -eq "USB" -or $_.MediaType -match "Removable" }; foreach ($d in $Wmi) { $L += "Disk $($d.Index): $($d.Model) - $([Math]::Round($d.Size/1GB,1))GB" } } catch {} }
    if ($L.Count -eq 0) { $L += "Không tìm thấy USB" }; return $L
}

# --- 3. WPF GUI (FULL TABS) ---
function Show-WpfGUI {
    $XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="PHAT TAN VENTOY V15 (WPF ENGINE)" Height="750" Width="900" Background="#1E1E23" WindowStartupLocation="CenterScreen">
    <Grid Margin="10">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        
        <Grid Grid.Row="0" Margin="0,0,0,10">
            <StackPanel>
                <TextBlock Text="USB BOOT MASTER - VENTOY EDITION" FontSize="20" FontWeight="Bold" Foreground="#00B4FF"/>
                <TextBlock Text="Đầy đủ chức năng V13.5 | Cấu trúc chuẩn | Dual GUI Engine" Foreground="Gray"/>
            </StackPanel>
            <Button Name="BtnSwitch" Content="Sang WinForms" HorizontalAlignment="Right" VerticalAlignment="Center" Background="Orange" FontWeight="Bold" Padding="10,5"/>
        </Grid>

        <Border Grid.Row="1" Background="#2D2D32" CornerRadius="5" Padding="10" Margin="0,0,0,10">
            <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="120"/></Grid.ColumnDefinitions>
                <ComboBox Name="CbUsb" Grid.Column="0" Height="30" FontSize="14" Margin="0,0,10,0"/>
                <Button Name="BtnRef" Grid.Column="1" Content="↻ Refresh" Background="#3C3C46" Foreground="White"/>
            </Grid>
        </Border>

        <TabControl Grid.Row="2" Background="#1E1E23" BorderBrush="#00B4FF" Margin="0,0,0,10">
            <TabItem Header="CÀI ĐẶT CƠ BẢN" Foreground="Black">
                <Grid Margin="10">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="150"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Grid.RowDefinitions><RowDefinition Height="35"/><RowDefinition Height="35"/><RowDefinition Height="35"/><RowDefinition Height="35"/><RowDefinition Height="35"/><RowDefinition Height="35"/><RowDefinition Height="*"/></Grid.RowDefinitions>
                    
                    <TextBlock Text="Chế độ:" Foreground="White" Grid.Row="0" VerticalAlignment="Center"/>
                    <ComboBox Name="CbMode" Grid.Row="0" Grid.Column="1" Height="25"/>
                    
                    <TextBlock Text="Kiểu Phân Vùng:" Foreground="White" Grid.Row="1" VerticalAlignment="Center"/>
                    <ComboBox Name="CbStyle" Grid.Row="1" Grid.Column="1" Height="25"/>
                    
                    <TextBlock Text="Tên USB (Label):" Foreground="White" Grid.Row="2" VerticalAlignment="Center"/>
                    <TextBox Name="TxtLbl" Text="PHATTAN_BOOT" Grid.Row="2" Grid.Column="1" Height="25" Foreground="Cyan" Background="#3C3C46"/>
                    
                    <TextBlock Text="Định dạng (FS):" Foreground="White" Grid.Row="3" VerticalAlignment="Center"/>
                    <ComboBox Name="CbFS" Grid.Row="3" Grid.Column="1" Height="25"/>
                    
                    <TextBlock Text="Tên Menu (Alias):" Foreground="Yellow" Grid.Row="4" VerticalAlignment="Center"/>
                    <TextBox Name="TxtAlias" Text="PHAT TAN RESCUE" Grid.Row="4" Grid.Column="1" Height="25" Foreground="Yellow" Background="#3C3C46"/>
                    
                    <TextBlock Text="Password Boot:" Foreground="Orange" Grid.Row="5" VerticalAlignment="Center"/>
                    <TextBox Name="TxtPass" Grid.Row="5" Grid.Column="1" Height="25" Foreground="Orange" Background="#3C3C46"/>
                    
                    <StackPanel Grid.Row="6" Grid.ColumnSpan="2" Margin="0,10,0,0">
                        <CheckBox Name="ChkMemtest" Content="Tải Memtest86+ mới nhất (ZIP fix)" IsChecked="True" Foreground="Cyan" Margin="0,5"/>
                        <CheckBox Name="ChkDir" Content="Tạo Full Cấu trúc Thư mục (DATA, ISO, BanQuyen...)" IsChecked="True" Foreground="Lime" Margin="0,5"/>
                        <CheckBox Name="ChkSec" Content="Bật Secure Boot Support" IsChecked="True" Foreground="Orange" Margin="0,5"/>
                        <CheckBox Name="ChkLive" Content="Tải tool MAS Activate Windows" IsChecked="True" Foreground="Yellow" Margin="0,5"/>
                    </StackPanel>
                </Grid>
            </TabItem>
            <TabItem Header="WIN 11 HACKS" Foreground="Black">
                <StackPanel Margin="15">
                    <CheckBox Name="ChkBypassCheck" Content="Bypass TPM 2.0 &amp; CPU Check (Cài Win11 máy cũ)" IsChecked="True" Foreground="White" FontSize="14" Margin="0,10"/>
                    <CheckBox Name="ChkBypassNRO" Content="Bypass Online Account (Skip mạng Win 11)" IsChecked="True" Foreground="White" FontSize="14" Margin="0,10"/>
                </StackPanel>
            </TabItem>
            <TabItem Header="KHO THEME &amp; LOG" Foreground="Black">
                <Grid Margin="10">
                    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
                    <TextBlock Text="Chọn Theme (Từ Server Kho-Do-Nghe):" Foreground="White" Margin="0,0,0,5"/>
                    <Grid Grid.Row="1" Margin="0,0,0,10">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="150"/></Grid.ColumnDefinitions>
                        <ComboBox Name="CbTheme" Height="25" Margin="0,0,10,0"/>
                        <Button Name="BtnLoadTheme" Content="Tải lại danh sách" Grid.Column="1" Height="25"/>
                    </Grid>
                    <TextBox Name="TxtLog" Grid.Row="2" Background="Black" Foreground="Lime" FontFamily="Consolas" IsReadOnly="True" VerticalScrollBarVisibility="Auto"/>
                </Grid>
            </TabItem>
        </TabControl>

        <Button Name="BtnStart" Grid.Row="3" Content="THỰC HIỆN TẠO BOOT" Height="45" FontSize="16" FontWeight="Bold" Background="#00B4FF" Foreground="Black"/>
    </Grid>
</Window>
"@
    $Reader = New-Object System.Xml.XmlNodeReader([xml]$XAML)
    $W = [Windows.Markup.XamlReader]::Load($Reader)
    
    # Map controls
    $CbUsb = $W.FindName("CbUsb"); $BtnRef = $W.FindName("BtnRef"); $BtnSwitch = $W.FindName("BtnSwitch")
    $CbMode = $W.FindName("CbMode"); $CbStyle = $W.FindName("CbStyle"); $CbFS = $W.FindName("CbFS")
    $TxtLbl = $W.FindName("TxtLbl"); $TxtAlias = $W.FindName("TxtAlias"); $TxtPass = $W.FindName("TxtPass")
    $ChkMemtest = $W.FindName("ChkMemtest"); $ChkDir = $W.FindName("ChkDir"); $ChkSec = $W.FindName("ChkSec"); $ChkLive = $W.FindName("ChkLive")
    $ChkBypassCheck = $W.FindName("ChkBypassCheck"); $ChkBypassNRO = $W.FindName("ChkBypassNRO")
    $CbTheme = $W.FindName("CbTheme"); $BtnLoadTheme = $W.FindName("BtnLoadTheme"); $TxtLog = $W.FindName("TxtLog")
    $BtnStart = $W.FindName("BtnStart")
    
    $Global:ActiveLogControl = $TxtLog; $Global:ActiveForm = $null

    # Init
    "Cài mới (Xóa sạch & Format)", "Cập nhật Ventoy (Giữ Data)" | ForEach-Object { $CbMode.Items.Add($_) }; $CbMode.SelectedIndex = 0
    "MBR (Legacy + UEFI)", "GPT (UEFI Only)" | ForEach-Object { $CbStyle.Items.Add($_) }; $CbStyle.SelectedIndex = 0
    "exFAT (Khuyên dùng)", "NTFS (Tương thích Win)", "FAT32 (Max 4GB/file)" | ForEach-Object { $CbFS.Items.Add($_) }; $CbFS.SelectedIndex = 0

    $LoadU = { $CbUsb.Items.Clear(); foreach ($u in (Get-Usb-List-String)) { $CbUsb.Items.Add($u) }; if ($CbUsb.Items.Count -gt 0) { $CbUsb.SelectedIndex = 0 } }; &$LoadU
    $BtnRef.Add_Click($LoadU)
    
    $LoadT = { $CbTheme.Items.Clear(); foreach ($t in (Load-Themes-Online)) { $CbTheme.Items.Add($t) }; $CbTheme.SelectedIndex = 0 }; &$LoadT
    $BtnLoadTheme.Add_Click($LoadT)

    $BtnSwitch.Add_Click({ $Global:UseWpf = $false; $W.Close() })

    $BtnStart.Add_Click({
        $Sel = $CbUsb.SelectedItem
        if ($Sel -match "Disk (\d+)") {
            if ([System.Windows.Forms.MessageBox]::Show("Toàn bộ dữ liệu trên USB sẽ bị xóa nếu chọn Cài Mới. Tiếp tục?", "Cảnh báo", "YesNo") -eq "Yes") {
                $BtnStart.IsEnabled = $false
                $Config = @{
                    DiskID=$Matches[1]; Mode=$CbMode.SelectedItem; Style=$CbStyle.SelectedItem; LabelName=$TxtLbl.Text
                    FSType=$CbFS.SelectedItem; Alias=$TxtAlias.Text; Password=$TxtPass.Text; ThemeName=$CbTheme.SelectedItem
                    MkDir=[bool]$ChkDir.IsChecked; Secure=[bool]$ChkSec.IsChecked; GetMemtest=[bool]$ChkMemtest.IsChecked; GetMas=[bool]$ChkLive.IsChecked
                    BypassCheck=[bool]$ChkBypassCheck.IsChecked; BypassNro=[bool]$ChkBypassNRO.IsChecked
                }
                $RunSpace = [runspacefactory]::CreateRunspace(); $RunSpace.Open()
                $Pipe = $RunSpace.CreatePipeline(); $Pipe.Commands.AddScript({ param($c) Execute-VentoyProcess $c }) | Out-Null
                $Pipe.Commands[0].Parameters.Add("c", $Config); $Pipe.InvokeAsync()
            }
        }
    })

    $W.ShowDialog() | Out-Null
}

# --- 4. WINFORMS GUI (FULL TABS - MÁY WINPE YẾU) ---
function Show-WinFormsGUI {
    $F = New-Object System.Windows.Forms.Form
    $F.Text = "PHAT TAN VENTOY V15 (WINFORMS)"; $F.Size = "950,850"; $F.StartPosition = "CenterScreen"; $F.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 35); $F.ForeColor = [System.Drawing.Color]::White

    $FTit = New-Object System.Drawing.Font("Segoe UI", 14, 1); $FNor = New-Object System.Drawing.Font("Segoe UI", 9, 0)
    $Pnl = New-Object System.Windows.Forms.Panel; $Pnl.Dock = "Top"; $Pnl.Height = 120; $F.Controls.Add($Pnl)
    
    $L1 = New-Object System.Windows.Forms.Label; $L1.Text = "USB BOOT MASTER - VENTOY V15"; $L1.Font = $FTit; $L1.ForeColor = [System.Drawing.Color]::Cyan; $L1.AutoSize = $true; $L1.Location = "10,10"
    $BtnSw = New-Object System.Windows.Forms.Button; $BtnSw.Text = "Sang WPF"; $BtnSw.Bounds = "750,10,150,30"; $BtnSw.BackColor = [System.Drawing.Color]::Orange; $BtnSw.ForeColor = [System.Drawing.Color]::Black
    $CbU = New-Object System.Windows.Forms.ComboBox; $CbU.Bounds = "10,50,600,25"; $CbU.DropDownStyle = 2
    $BtnR = New-Object System.Windows.Forms.Button; $BtnR.Text = "↻ Refresh"; $BtnR.Bounds = "620,50,100,25"; $BtnR.BackColor = [System.Drawing.Color]::Gray
    $Pnl.Controls.AddRange(@($L1, $BtnSw, $CbU, $BtnR))

    $TabC = New-Object System.Windows.Forms.TabControl; $TabC.Dock = "Top"; $TabC.Height = 350; $F.Controls.Add($TabC)
    
    # Tab 1: Basic
    $T1 = New-Object System.Windows.Forms.TabPage; $T1.Text = "CƠ BẢN"; $T1.BackColor = [System.Drawing.Color]::FromArgb(30,30,35); $TabC.Controls.Add($T1)
    $y = 10
    $l_M = New-Object System.Windows.Forms.Label; $l_M.Text="Chế độ:"; $l_M.Bounds="10,$y,100,20"; $cb_M = New-Object System.Windows.Forms.ComboBox; $cb_M.Bounds="120,$y,250,20"; $cb_M.Items.AddRange(@("Cài mới","Cập nhật")); $cb_M.SelectedIndex=0; $T1.Controls.AddRange(@($l_M,$cb_M)); $y+=35
    $l_S = New-Object System.Windows.Forms.Label; $l_S.Text="Style:"; $l_S.Bounds="10,$y,100,20"; $cb_S = New-Object System.Windows.Forms.ComboBox; $cb_S.Bounds="120,$y,250,20"; $cb_S.Items.AddRange(@("MBR","GPT")); $cb_S.SelectedIndex=0; $T1.Controls.AddRange(@($l_S,$cb_S)); $y+=35
    $l_L = New-Object System.Windows.Forms.Label; $l_L.Text="Label:"; $l_L.Bounds="10,$y,100,20"; $txt_L = New-Object System.Windows.Forms.TextBox; $txt_L.Bounds="120,$y,250,20"; $txt_L.Text="PHATTAN"; $T1.Controls.AddRange(@($l_L,$txt_L)); $y+=35
    $l_F = New-Object System.Windows.Forms.Label; $l_F.Text="Format:"; $l_F.Bounds="10,$y,100,20"; $cb_F = New-Object System.Windows.Forms.ComboBox; $cb_F.Bounds="120,$y,250,20"; $cb_F.Items.AddRange(@("exFAT","NTFS","FAT32")); $cb_F.SelectedIndex=0; $T1.Controls.AddRange(@($l_F,$cb_F)); $y+=35
    $l_A = New-Object System.Windows.Forms.Label; $l_A.Text="Alias:"; $l_A.Bounds="10,$y,100,20"; $txt_A = New-Object System.Windows.Forms.TextBox; $txt_A.Bounds="120,$y,250,20"; $txt_A.Text="PHAT TAN USB"; $T1.Controls.AddRange(@($l_A,$txt_A)); $y+=35
    $l_P = New-Object System.Windows.Forms.Label; $l_P.Text="Pass (Opt):"; $l_P.Bounds="10,$y,100,20"; $txt_P = New-Object System.Windows.Forms.TextBox; $txt_P.Bounds="120,$y,250,20"; $T1.Controls.AddRange(@($l_P,$txt_P))
    
    $chk_Dir = New-Object System.Windows.Forms.CheckBox; $chk_Dir.Text="Tạo Full Thư Mục"; $chk_Dir.Bounds="400,10,300,20"; $chk_Dir.Checked=$true; $T1.Controls.Add($chk_Dir)
    $chk_Mem = New-Object System.Windows.Forms.CheckBox; $chk_Mem.Text="Tải Memtest86+"; $chk_Mem.Bounds="400,45,300,20"; $chk_Mem.Checked=$true; $T1.Controls.Add($chk_Mem)
    $chk_Sec = New-Object System.Windows.Forms.CheckBox; $chk_Sec.Text="Secure Boot"; $chk_Sec.Bounds="400,80,300,20"; $chk_Sec.Checked=$true; $T1.Controls.Add($chk_Sec)
    $chk_Mas = New-Object System.Windows.Forms.CheckBox; $chk_Mas.Text="Tải tool MAS"; $chk_Mas.Bounds="400,115,300,20"; $chk_Mas.Checked=$true; $T1.Controls.Add($chk_Mas)

    # Tab 2: Hacks
    $T2 = New-Object System.Windows.Forms.TabPage; $T2.Text = "HACKS"; $T2.BackColor = [System.Drawing.Color]::FromArgb(30,30,35); $TabC.Controls.Add($T2)
    $chk_B1 = New-Object System.Windows.Forms.CheckBox; $chk_B1.Text="Bypass TPM 2.0 / CPU Win 11"; $chk_B1.Bounds="20,20,400,30"; $chk_B1.Checked=$true; $T2.Controls.Add($chk_B1)
    $chk_B2 = New-Object System.Windows.Forms.CheckBox; $chk_B2.Text="Bypass NRO (Online Account)"; $chk_B2.Bounds="20,60,400,30"; $chk_B2.Checked=$true; $T2.Controls.Add($chk_B2)

    # Tab 3: Themes
    $T3 = New-Object System.Windows.Forms.TabPage; $T3.Text = "THEMES"; $T3.BackColor = [System.Drawing.Color]::FromArgb(30,30,35); $TabC.Controls.Add($T3)
    $l_Th = New-Object System.Windows.Forms.Label; $l_Th.Text="Chọn Theme Server:"; $l_Th.Bounds="20,20,200,20"; $T3.Controls.Add($l_Th)
    $cb_Th = New-Object System.Windows.Forms.ComboBox; $cb_Th.Bounds="20,50,400,25"; $cb_Th.DropDownStyle = 2; $T3.Controls.Add($cb_Th)
    $btn_Th = New-Object System.Windows.Forms.Button; $btn_Th.Text="Tải Lại Theme"; $btn_Th.Bounds="440,50,150,25"; $btn_Th.BackColor = [System.Drawing.Color]::Gray; $T3.Controls.Add($btn_Th)

    # Log & Start
    $TxtL = New-Object System.Windows.Forms.RichTextBox; $TxtL.Dock = "Top"; $TxtL.Height=230; $TxtL.BackColor="Black"; $TxtL.ForeColor="Lime"; $TxtL.ReadOnly=$true; $F.Controls.Add($TxtL)
    $BtnS = New-Object System.Windows.Forms.Button; $BtnS.Text = "THỰC HIỆN"; $BtnS.Dock = "Bottom"; $BtnS.Height=50; $BtnS.BackColor=[System.Drawing.Color]::Cyan; $BtnS.ForeColor="Black"; $BtnS.Font=$FTit; $F.Controls.Add($BtnS)

    $Global:ActiveLogControl = $TxtL; $Global:ActiveForm = $F

    $LdU = { $CbU.Items.Clear(); foreach ($u in (Get-Usb-List-String)) { [void]$CbU.Items.Add($u) }; if ($CbU.Items.Count -gt 0) { $CbU.SelectedIndex = 0 } }; &$LdU
    $BtnR.Add_Click($LdU)
    
    $LdT = { $cb_Th.Items.Clear(); foreach ($t in (Load-Themes-Online)) { [void]$cb_Th.Items.Add($t) }; $cb_Th.SelectedIndex = 0 }; &$LdT
    $btn_Th.Add_Click($LdT)

    $BtnSw.Add_Click({ if ($Global:WpfAvailable) { $Global:UseWpf = $true; $F.Close() } else { [System.Windows.Forms.MessageBox]::Show("Máy không có WPF!") } })

    $BtnS.Add_Click({
        if ($CbU.SelectedItem -match "Disk (\d+)") {
            if ([System.Windows.Forms.MessageBox]::Show("Tiếp tục cài đặt lên USB?", "Xác nhận", "YesNo") -eq "Yes") {
                $BtnS.Enabled = $false
                Execute-VentoyProcess @{
                    DiskID=$Matches[1]; Mode=$cb_M.SelectedItem; Style=$cb_S.SelectedItem; LabelName=$txt_L.Text
                    FSType=$cb_F.SelectedItem; Alias=$txt_A.Text; Password=$txt_P.Text; ThemeName=$cb_Th.SelectedItem
                    MkDir=$chk_Dir.Checked; Secure=$chk_Sec.Checked; GetMemtest=$chk_Mem.Checked; GetMas=$chk_Mas.Checked
                    BypassCheck=$chk_B1.Checked; BypassNro=$chk_B2.Checked
                }
                $BtnS.Enabled = $true
            }
        }
    })

    $F.ShowDialog() | Out-Null
}

# --- 5. MAIN LOOP ---
while ($Global:AppRunning) {
    if ($Global:UseWpf -and $Global:WpfAvailable) { Show-WpfGUI; if ($Global:UseWpf) { $Global:AppRunning = $false } } 
    else { Show-WinFormsGUI; if (-not $Global:UseWpf) { $Global:AppRunning = $false } }
}
