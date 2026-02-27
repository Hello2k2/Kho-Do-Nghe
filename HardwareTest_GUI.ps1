<#
.SYNOPSIS
    Công cụ Kiểm tra Phần Cứng Toàn Diện (GUI Version - RGB Edition)
.DESCRIPTION
    Hỗ trợ mọi môi trường: WinPE, Windows Lite, Windows Full.
    GUI Failover: WPF -> WinForms.
    Logic Failover: Win32 API -> CIM -> WMI -> WMIC.
#>

param (
    [string]$LogPath = "$env:TEMP\HWTest_Log.txt"
)

# -------------------------------------------------------------------
# 1. CORE LOGIC: API & WMI FALLBACK
# -------------------------------------------------------------------
$global:apiAvailable = $false
$csharpCode = @"
using System;
using System.Runtime.InteropServices;
public class Win32API {
    [DllImport("user32.dll", CharSet = CharSet.Auto, ExactSpelling = true)]
    public static extern int GetSystemMetrics(int nIndex);
    
    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool MessageBeep(uint uType);
}
"@
try {
    Add-Type -TypeDefinition $csharpCode -ErrorAction Stop
    $global:apiAvailable = $true
} catch { }

Function Get-HardwareData ($ClassName) {
    if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue) {
        try { return Get-CimInstance -ClassName $ClassName -ErrorAction Stop } catch { }
    }
    if (Get-Command Get-WmiObject -ErrorAction SilentlyContinue) {
        try { return Get-WmiObject -Class $ClassName -ErrorAction Stop } catch { }
    }
    try {
        $wmicOutput = wmic path $ClassName get Description, Status /format:csv 2>$null | Select-String -Pattern ","
        if ($wmicOutput) {
            return $wmicOutput | ForEach-Object {
                $parts = $_.ToString().Split(',')
                if ($parts.Count -ge 3) { @{ Description = $parts[1]; Status = $parts[2] } }
            }
        }
    } catch { }
    return $null
}

# -------------------------------------------------------------------
# 2. CHỌN FRAMEWORK GUI (WPF HAY WINFORMS)
# -------------------------------------------------------------------
$useWPF = $false
try {
    Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
    Add-Type -AssemblyName PresentationCore -ErrorAction Stop
    $useWPF = $true
} catch {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
}

# Biến toàn cục cho Theme & RGB
$global:isDarkMode = $true
$global:rgbIndex = 0
$global:rgbColorsWPF = "Cyan","Magenta","Yellow","Lime","Orange","DeepSkyBlue","HotPink"
$global:rgbColorsWF = "Cyan","Magenta","Yellow","Lime","Orange","DeepSkyBlue","HotPink"

# -------------------------------------------------------------------
# 3. KỊCH BẢN KIỂM TRA PHẦN CỨNG
# -------------------------------------------------------------------
Function Run-HardwareTest ($LogAction) {
    &$LogAction "=== BẮT ĐẦU KIỂM TRA PHẦN CỨNG ==="
    
    # 1. CPU & RAM
    &$LogAction "`n[CPU] Đang lấy thông tin..."
    $cpus = Get-HardwareData "Win32_Processor"
    if ($cpus) { foreach($c in $cpus) { &$LogAction " -> $($c.Name)" } }
    
    $rams = Get-HardwareData "Win32_PhysicalMemory"
    if ($rams) { 
        $totalRam = 0; foreach($r in $rams) { $totalRam += [math]::Round($r.Capacity / 1GB, 2) }
        &$LogAction " -> Tổng RAM: $totalRam GB" 
    }

    # 2. DISK
    &$LogAction "`n[DISK] Đang kiểm tra Ổ cứng..."
    $disks = Get-HardwareData "Win32_DiskDrive"
    if ($disks) { foreach($d in $disks) { &$LogAction " -> $($d.Model) - $([math]::Round($d.Size / 1GB, 2)) GB - Trạng thái: $($d.Status)" } }

    # 3. CHUỘT
    &$LogAction "`n[MOUSE] Đang kiểm tra Chuột..."
    $mouseDetected = $false
    if ($global:apiAvailable) {
        $buttons = [Win32API]::GetSystemMetrics(43)
        if ($buttons -gt 0) { &$LogAction " -> [API] Phát hiện chuột có $buttons nút."; $mouseDetected = $true }
    }
    $mice = Get-HardwareData "Win32_PointingDevice"
    if ($mice) { foreach($m in $mice) { &$LogAction " -> $($m.Description) - Trạng thái: $($m.Status)" } }
    elseif (-not $mouseDetected) { &$LogAction " -> [!] Không nhận diện được chuột." }

    # 4. PHÍM
    &$LogAction "`n[KEYBOARD] Đang kiểm tra Bàn phím..."
    $keyboards = Get-HardwareData "Win32_Keyboard"
    if ($keyboards) { foreach($k in $keyboards) { &$LogAction " -> $($k.Description) - Trạng thái: $($k.Status)" } }

    # 5. AUDIO
    &$LogAction "`n[AUDIO] Đang kiểm tra Loa (Kích hoạt Beep)..."
    $audio = Get-HardwareData "Win32_SoundDevice"
    if ($audio) { foreach($a in $audio) { &$LogAction " -> $($a.Description) - Trạng thái: $($a.Status)" } }
    if ($global:apiAvailable) { [Win32API]::MessageBeep(0) | Out-Null } else { try { [System.Console]::Beep(800, 300) } catch {} }

    # 6. MÀN HÌNH
    &$LogAction "`n[DISPLAY] Đang kiểm tra Card/Màn hình..."
    $mons = Get-HardwareData "Win32_VideoController"
    if ($mons) { foreach($mon in $mons) { &$LogAction " -> $($mon.Description)" } }

    # 7. MẠNG
    &$LogAction "`n[NETWORK] Đang kiểm tra Card mạng..."
    $nets = Get-HardwareData "Win32_NetworkAdapter"
    if ($nets) { foreach($n in $nets) { 
        if ($n.NetConnectionStatus -eq 2) { &$LogAction " -> $($n.Name) [ĐÃ KẾT NỐI]" }
        elseif ($n.NetConnectionStatus -ne $null) { &$LogAction " -> $($n.Name) [Ngắt kết nối]" }
    }}

    &$LogAction "`n=== HOÀN TẤT ==="
}

# -------------------------------------------------------------------
# 4. TRIỂN KHAI GIAO DIỆN (WPF VÀ WINFORMS)
# -------------------------------------------------------------------
if ($useWPF) {
    # ============== GIAO DIỆN WPF ==============
    [xml]$xaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="Hardware Tester - WPF RGB" Height="600" Width="850" WindowStartupLocation="CenterScreen" Background="#121212">
        <Border Name="RgbBorder" BorderBrush="Cyan" BorderThickness="4" CornerRadius="5" Margin="5">
            <Grid Margin="10">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="250"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                
                <StackPanel Grid.Column="0" Margin="0,0,10,0">
                    <TextBlock Name="TitleText" Text="PHẦN CỨNG" FontSize="30" FontWeight="Heavy" Foreground="Cyan" TextAlignment="Center" Margin="0,10,0,30"/>
                    <Button Name="BtnTest" Content="🚀 Chạy Test" Height="50" Margin="0,0,0,15" Background="#252526" Foreground="White" FontSize="16" FontWeight="Bold"/>
                    <Button Name="BtnTheme" Content="🌗 Đổi Nền (Dark/Light)" Height="50" Margin="0,0,0,15" Background="#252526" Foreground="White" FontSize="14"/>
                    <TextBlock Name="StatusText" Text="Trạng thái: Sẵn sàng" Foreground="Gray" Margin="0,20,0,0" TextWrapping="Wrap"/>
                </StackPanel>
                
                <TextBox Name="LogBox" Grid.Column="1" Background="#1E1E1E" Foreground="#00FF00" FontFamily="Consolas" FontSize="14" IsReadOnly="True" VerticalScrollBarVisibility="Auto" AcceptsReturn="True" TextWrapping="Wrap"/>
            </Grid>
        </Border>
    </Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $Window = [Windows.Markup.XamlReader]::Load($reader)

    $RgbBorder = $Window.FindName("RgbBorder")
    $TitleText = $Window.FindName("TitleText")
    $LogBox = $Window.FindName("LogBox")
    $BtnTest = $Window.FindName("BtnTest")
    $BtnTheme = $Window.FindName("BtnTheme")
    
    # Log Action cho WPF
    $LogAction = {
        param($msg)
        $timestamp = Get-Date -Format "HH:mm:ss"
        $Window.Dispatcher.Invoke({
            $LogBox.AppendText("[$timestamp] $msg`n")
            $LogBox.ScrollToEnd()
        })
        Add-Content -Path $LogPath -Value "[$timestamp] $msg"
    }

    # Sự kiện chạy Test
    $BtnTest.Add_Click({
        $LogBox.Clear()
        $BtnTest.IsEnabled = $false
        Run-HardwareTest $LogAction
        $BtnTest.IsEnabled = $true
    })

    # Sự kiện đổi Theme
    $BtnTheme.Add_Click({
        $global:isDarkMode = -not $global:isDarkMode
        if ($global:isDarkMode) {
            $Window.Background = "#121212"; $LogBox.Background = "#1E1E1E"; $LogBox.Foreground = "#00FF00"
            $BtnTest.Background = "#252526"; $BtnTest.Foreground = "White"
            $BtnTheme.Background = "#252526"; $BtnTheme.Foreground = "White"
        } else {
            $Window.Background = "#F0F0F0"; $LogBox.Background = "#FFFFFF"; $LogBox.Foreground = "#000000"
            $BtnTest.Background = "#E0E0E0"; $BtnTest.Foreground = "Black"
            $BtnTheme.Background = "#E0E0E0"; $BtnTheme.Foreground = "Black"
        }
    })

    # RGB Timer
    $Timer = New-Object System.Windows.Threading.DispatcherTimer
    $Timer.Interval = [TimeSpan]::FromMilliseconds(300)
    $Timer.Add_Tick({
        $color = $global:rgbColorsWPF[$global:rgbIndex]
        $brush = (New-Object System.Windows.Media.BrushConverter).ConvertFromString($color)
        $RgbBorder.BorderBrush = $brush
        $TitleText.Foreground = $brush
        $global:rgbIndex = ($global:rgbIndex + 1) % $global:rgbColorsWPF.Length
    })
    $Timer.Start()

    $Window.ShowDialog() | Out-Null

} else {
    # ============== GIAO DIỆN WINFORMS (FALLBACK CHO WINPE/LITE) ==============
    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = "Hardware Tester - WinForms RGB"
    $Form.Size = New-Object System.Drawing.Size(850, 600)
    $Form.StartPosition = "CenterScreen"
    $Form.BackColor = [System.Drawing.Color]::FromArgb(18, 18, 18)
    $Form.FormBorderStyle = "Fixed3D"

    $PanelLeft = New-Object System.Windows.Forms.Panel
    $PanelLeft.Size = New-Object System.Drawing.Size(220, 560)
    $PanelLeft.Dock = "Left"

    $TitleText = New-Object System.Windows.Forms.Label
    $TitleText.Text = "PHẦN CỨNG"
    $TitleText.Font = New-Object System.Drawing.Font("Arial", 20, [System.Drawing.FontStyle]::Bold)
    $TitleText.ForeColor = [System.Drawing.Color]::Cyan
    $TitleText.Location = New-Object System.Drawing.Point(10, 20)
    $TitleText.Size = New-Object System.Drawing.Size(200, 40)
    $TitleText.TextAlign = "MiddleCenter"

    $BtnTest = New-Object System.Windows.Forms.Button
    $BtnTest.Text = "🚀 Chạy Test"
    $BtnTest.Location = New-Object System.Drawing.Point(10, 80)
    $BtnTest.Size = New-Object System.Drawing.Size(200, 50)
    $BtnTest.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $BtnTest.ForeColor = [System.Drawing.Color]::White
    $BtnTest.FlatStyle = "Flat"

    $BtnTheme = New-Object System.Windows.Forms.Button
    $BtnTheme.Text = "🌗 Đổi Nền (Dark/Light)"
    $BtnTheme.Location = New-Object System.Drawing.Point(10, 140)
    $BtnTheme.Size = New-Object System.Drawing.Size(200, 50)
    $BtnTheme.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
    $BtnTheme.ForeColor = [System.Drawing.Color]::White
    $BtnTheme.FlatStyle = "Flat"

    $LogBox = New-Object System.Windows.Forms.RichTextBox
    $LogBox.Dock = "Fill"
    $LogBox.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $LogBox.ForeColor = [System.Drawing.Color]::Lime
    $LogBox.Font = New-Object System.Drawing.Font("Consolas", 11)
    $LogBox.ReadOnly = $true

    $PanelLeft.Controls.Add($TitleText)
    $PanelLeft.Controls.Add($BtnTest)
    $PanelLeft.Controls.Add($BtnTheme)
    $Form.Controls.Add($LogBox)
    $Form.Controls.Add($PanelLeft)

    # Log Action cho WinForms
    $LogAction = {
        param($msg)
        $timestamp = Get-Date -Format "HH:mm:ss"
        $LogBox.AppendText("[$timestamp] $msg`n")
        $LogBox.SelectionStart = $LogBox.Text.Length
        $LogBox.ScrollToCaret()
        [System.Windows.Forms.Application]::DoEvents()
        Add-Content -Path $LogPath -Value "[$timestamp] $msg"
    }

    # Sự kiện chạy Test
    $BtnTest.Add_Click({
        $LogBox.Clear()
        $BtnTest.Enabled = $false
        Run-HardwareTest $LogAction
        $BtnTest.Enabled = $true
    })

    # Sự kiện đổi Theme
    $BtnTheme.Add_Click({
        $global:isDarkMode = -not $global:isDarkMode
        if ($global:isDarkMode) {
            $Form.BackColor = [System.Drawing.Color]::FromArgb(18, 18, 18)
            $LogBox.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30); $LogBox.ForeColor = [System.Drawing.Color]::Lime
            $BtnTest.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38); $BtnTest.ForeColor = [System.Drawing.Color]::White
            $BtnTheme.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38); $BtnTheme.ForeColor = [System.Drawing.Color]::White
        } else {
            $Form.BackColor = [System.Drawing.Color]::White
            $LogBox.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240); $LogBox.ForeColor = [System.Drawing.Color]::Black
            $BtnTest.BackColor = [System.Drawing.Color]::LightGray; $BtnTest.ForeColor = [System.Drawing.Color]::Black
            $BtnTheme.BackColor = [System.Drawing.Color]::LightGray; $BtnTheme.ForeColor = [System.Drawing.Color]::Black
        }
    })

    # RGB Timer
    $Timer = New-Object System.Windows.Forms.Timer
    $Timer.Interval = 300
    $Timer.Add_Tick({
        $colorName = $global:rgbColorsWF[$global:rgbIndex]
        $TitleText.ForeColor = [System.Drawing.Color]::FromName($colorName)
        $global:rgbIndex = ($global:rgbIndex + 1) % $global:rgbColorsWF.Length
    })
    $Timer.Start()

    $Form.ShowDialog() | Out-Null
}
