<#
.SYNOPSIS
    Hardware Tester Tương Tác (GUI RGB - Full Diagnostic)
.DESCRIPTION
    Hỗ trợ Test Điểm chết màn hình, Loa Trái/Phải, Camera, Info, Phím.
    Failover GUI: WPF -> WinForms.
#>

param ( [string]$LogPath = "$env:TEMP\HWTest_Log.txt" )

# -------------------------------------------------------------------
# 1. CORE LOGIC & HELPER FUNCTIONS
# -------------------------------------------------------------------
$global:apiAvailable = $false
try {
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    public class Win32API {
        [DllImport("user32.dll", CharSet = CharSet.Auto, ExactSpelling = true)]
        public static extern int GetSystemMetrics(int nIndex);
    }
"@ -ErrorAction Stop
    $global:apiAvailable = $true
} catch { }

Function Get-HardwareData ($ClassName) {
    if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue) { try { return Get-CimInstance -ClassName $ClassName -ErrorAction Stop } catch {} }
    if (Get-Command Get-WmiObject -ErrorAction SilentlyContinue) { try { return Get-WmiObject -Class $ClassName -ErrorAction Stop } catch {} }
    try {
        $wmicOutput = wmic path $ClassName get Description, Status /format:csv 2>$null | Select-String -Pattern ","
        if ($wmicOutput) {
            return $wmicOutput | ForEach-Object { $parts = $_.ToString().Split(','); if ($parts.Count -ge 3) { @{ Description = $parts[1]; Status = $parts[2] } } }
        }
    } catch { }
    return $null
}

# --- CÁC HÀM TEST TƯƠNG TÁC ---
Function Run-InfoTest ($LogAction) {
    &$LogAction "=== ĐỌC THÔNG SỐ TỔNG QUAN ==="
    $cpus = Get-HardwareData "Win32_Processor"; if ($cpus) { foreach($c in $cpus) { &$LogAction "[CPU] $($c.Name)" } }
    $rams = Get-HardwareData "Win32_PhysicalMemory"; if ($rams) { $tr=0; foreach($r in $rams){ $tr+=[math]::Round($r.Capacity/1GB,2) }; &$LogAction "[RAM] Tổng: $tr GB" }
    $disks = Get-HardwareData "Win32_DiskDrive"; if ($disks) { foreach($d in $disks) { &$LogAction "[DISK] $($d.Model) - $($d.Status)" } }
}

Function Run-MonitorTest {
    Add-Type -AssemblyName System.Windows.Forms
    $f = New-Object System.Windows.Forms.Form
    $f.FormBorderStyle = 'None'; $f.WindowState = 'Maximized'; $f.TopMost = $true
    $colors = @('Red','Green','Blue','White','Black')
    $script:cIdx = 0
    $f.BackColor = [System.Drawing.Color]::FromName($colors[$script:cIdx])
    
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "Click chuột để test màu tiếp theo. Hết màu sẽ tự đóng."
    $lbl.ForeColor = 'Gray'; $lbl.AutoSize = $true; $lbl.Font = New-Object System.Drawing.Font("Arial", 16)
    $f.Controls.Add($lbl)

    $f.Add_Click({
        $script:cIdx++
        if ($script:cIdx -ge $colors.Length) { $f.Close() }
        else { $f.BackColor = [System.Drawing.Color]::FromName($colors[$script:cIdx]); $lbl.Visible = $false }
    })
    $f.ShowDialog() | Out-Null
}

Function Run-AudioTest ($Side, $LogAction) {
    try {
        $wmp = New-Object -ComObject WMPlayer.OCX
        $wmp.settings.volume = 100
        $soundFile = "$env:windir\Media\tada.wav" # File âm thanh mặc định của Windows
        if (-not (Test-Path $soundFile)) { $soundFile = "$env:windir\Media\ding.wav" }
        
        if ($Side -eq 'Left') { $wmp.settings.balance = -100; &$LogAction "Đang phát tiếng bên LOA TRÁI..." }
        else { $wmp.settings.balance = 100; &$LogAction "Đang phát tiếng bên LOA PHẢI..." }
        
        $wmp.URL = $soundFile
        $wmp.controls.play()
    } catch {
        &$LogAction "[!] Không có Media COM (WinPE/Lite). Phát tiếng Beep mainboard..."
        [System.Console]::Beep(1000, 500)
    }
}

Function Run-CameraTest ($LogAction) {
    &$LogAction "=== TEST CAMERA ==="
    try {
        # Thử gọi app Camera tích hợp của Windows
        Start-Process "microsoft.windows.camera:" -ErrorAction Stop
        &$LogAction "Đã ra lệnh mở ứng dụng Windows Camera."
    } catch {
        &$LogAction "Không gọi được App Camera (Có thể là WinPE/Lite). Quét phần cứng gốc:"
        $cams = Get-HardwareData "Win32_PnPEntity" | Where-Object { $_.PNPClass -eq 'Image' -or $_.PNPClass -eq 'Camera' }
        if ($cams) { foreach($c in $cams) { &$LogAction " -> Đã cắm: $($c.Description)" } }
        else { &$LogAction " -> Không tìm thấy Camera nào được kết nối." }
    }
}

# -------------------------------------------------------------------
# 2. KHỞI TẠO GUI FRAMEWORK
# -------------------------------------------------------------------
$useWPF = $false
try { Add-Type -AssemblyName PresentationFramework -ErrorAction Stop; $useWPF = $true } 
catch { Add-Type -AssemblyName System.Windows.Forms }

$global:isDark = $true
$global:rgbIdx = 0
$global:rgbColors = "Cyan","Magenta","Yellow","Lime","Orange","DeepSkyBlue","HotPink"

# -------------------------------------------------------------------
# 3. TRIỂN KHAI GIAO DIỆN
# -------------------------------------------------------------------
if ($useWPF) {
    # ================== WPF ENGINE ==================
    [xml]$xaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="Hardware Diagnostic Pro" Height="650" Width="900" WindowStartupLocation="CenterScreen" Background="#121212">
        <Border Name="RgbBorder" BorderBrush="Cyan" BorderThickness="3" CornerRadius="5" Margin="5">
            <Grid Margin="10">
                <Grid.ColumnDefinitions><ColumnDefinition Width="260"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                
                <StackPanel Grid.Column="0" Margin="0,0,10,0">
                    <TextBlock Name="TitleText" Text="DIAGNOSTIC" FontSize="28" FontWeight="Heavy" Foreground="Cyan" TextAlignment="Center" Margin="0,5,0,20"/>
                    
                    <Button Name="BtnInfo" Content="🔍 Đọc Thông Số" Height="45" Margin="0,0,0,10" Background="#252526" Foreground="White"/>
                    <Button Name="BtnMonitor" Content="📺 Test Màn (Điểm Chết)" Height="45" Margin="0,0,0,10" Background="#252526" Foreground="White"/>
                    <Button Name="BtnCamera" Content="📷 Test Camera" Height="45" Margin="0,0,0,10" Background="#252526" Foreground="White"/>
                    
                    <Button Name="BtnAudioToggle" Content="🔊 Test Loa (Mở rộng)" Height="45" Margin="0,0,0,5" Background="#252526" Foreground="White"/>
                    <StackPanel Name="PanelAudio" Visibility="Collapsed" Orientation="Horizontal" Margin="0,0,0,10">
                        <Button Name="BtnAudioL" Content="🎧 Loa Trái" Width="120" Height="35" Margin="0,0,10,0" Background="#1E3E59" Foreground="White"/>
                        <Button Name="BtnAudioR" Content="Loa Phải 🎧" Width="120" Height="35" Background="#591E1E" Foreground="White"/>
                    </StackPanel>

                    <Button Name="BtnTheme" Content="🌗 Đổi Theme" Height="45" Margin="0,15,0,15" Background="#333333" Foreground="White"/>
                    
                    <TextBlock Text="Test Bàn Phím ở đây:" Foreground="Gray" Margin="0,10,0,5"/>
                    <TextBox Name="KeyBox" Height="60" TextWrapping="Wrap" Background="#1E1E1E" Foreground="Lime" FontSize="14" BorderBrush="Gray"/>
                </StackPanel>
                
                <TextBox Name="LogBox" Grid.Column="1" Background="#1E1E1E" Foreground="#00FF00" FontFamily="Consolas" FontSize="14" IsReadOnly="True" VerticalScrollBarVisibility="Auto" AcceptsReturn="True" TextWrapping="Wrap"/>
            </Grid>
        </Border>
    </Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $Window = [Windows.Markup.XamlReader]::Load($reader)

    $UI = @{
        RgbBorder = $Window.FindName("RgbBorder"); TitleText = $Window.FindName("TitleText")
        LogBox = $Window.FindName("LogBox"); KeyBox = $Window.FindName("KeyBox")
        BtnInfo = $Window.FindName("BtnInfo"); BtnMonitor = $Window.FindName("BtnMonitor")
        BtnCamera = $Window.FindName("BtnCamera"); BtnTheme = $Window.FindName("BtnTheme")
        BtnAudioToggle = $Window.FindName("BtnAudioToggle"); PanelAudio = $Window.FindName("PanelAudio")
        BtnAudioL = $Window.FindName("BtnAudioL"); BtnAudioR = $Window.FindName("BtnAudioR")
    }
    
    $LogAction = { param($m)
        $Window.Dispatcher.Invoke({ $UI.LogBox.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $m`n"); $UI.LogBox.ScrollToEnd() })
    }

    $UI.BtnInfo.Add_Click({ Run-InfoTest $LogAction })
    $UI.BtnMonitor.Add_Click({ &$LogAction "Đang mở cửa sổ Test Màn hình..."; Run-MonitorTest; &$LogAction "Đóng test màn hình." })
    $UI.BtnCamera.Add_Click({ Run-CameraTest $LogAction })
    
    $UI.BtnAudioToggle.Add_Click({
        if ($UI.PanelAudio.Visibility -eq 'Collapsed') { $UI.PanelAudio.Visibility = 'Visible' } else { $UI.PanelAudio.Visibility = 'Collapsed' }
    })
    $UI.BtnAudioL.Add_Click({ Run-AudioTest 'Left' $LogAction })
    $UI.BtnAudioR.Add_Click({ Run-AudioTest 'Right' $LogAction })

    $UI.BtnTheme.Add_Click({
        $global:isDark = -not $global:isDark
        if ($global:isDark) {
            $Window.Background = "#121212"; $UI.LogBox.Background = "#1E1E1E"; $UI.LogBox.Foreground = "#00FF00"; $UI.KeyBox.Background = "#1E1E1E"
        } else {
            $Window.Background = "#F0F0F0"; $UI.LogBox.Background = "#FFFFFF"; $UI.LogBox.Foreground = "#000000"; $UI.KeyBox.Background = "#FFFFFF"
        }
    })

    $Tmr = New-Object System.Windows.Threading.DispatcherTimer
    $Tmr.Interval = [TimeSpan]::FromMilliseconds(300)
    $Tmr.Add_Tick({
        $b = (New-Object System.Windows.Media.BrushConverter).ConvertFromString($global:rgbColors[$global:rgbIdx])
        $UI.RgbBorder.BorderBrush = $b; $UI.TitleText.Foreground = $b
        $global:rgbIdx = ($global:rgbIdx + 1) % $global:rgbColors.Length
    })
    $Tmr.Start()

    $Window.ShowDialog() | Out-Null

} else {
    # ================== WINFORMS ENGINE (FALLBACK) ==================
    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = "Hardware Diagnostic Pro - WinForms"
    $Form.Size = New-Object System.Drawing.Size(900, 650)
    $Form.StartPosition = "CenterScreen"
    $Form.BackColor = [System.Drawing.Color]::FromArgb(18, 18, 18)

    $FlowMenu = New-Object System.Windows.Forms.FlowLayoutPanel
    $FlowMenu.Dock = "Left"; $FlowMenu.Width = 260; $FlowMenu.Padding = New-Object System.Windows.Forms.Padding(10)
    
    $TitleText = New-Object System.Windows.Forms.Label
    $TitleText.Text = "DIAGNOSTIC"; $TitleText.Font = New-Object System.Drawing.Font("Arial", 22, [System.Drawing.FontStyle]::Bold)
    $TitleText.Size = New-Object System.Drawing.Size(240, 50); $TitleText.TextAlign = "MiddleCenter"
    
    # Helper tạo nút WinForms
    Function Create-Button($txt, $color) {
        $b = New-Object System.Windows.Forms.Button
        $b.Text = $txt; $b.Size = New-Object System.Drawing.Size(235, 45)
        $b.BackColor = [System.Drawing.Color]::FromName($color); $b.ForeColor = [System.Drawing.Color]::White; $b.FlatStyle = "Flat"
        $b.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 10)
        return $b
    }

    $BtnInfo = Create-Button "🔍 Đọc Thông Số" "ControlDarkDark"
    $BtnMonitor = Create-Button "📺 Test Màn (Điểm Chết)" "ControlDarkDark"
    $BtnCamera = Create-Button "📷 Test Camera" "ControlDarkDark"
    $BtnAudioToggle = Create-Button "🔊 Test Loa (Mở rộng)" "ControlDarkDark"
    
    $PanelAudio = New-Object System.Windows.Forms.Panel
    $PanelAudio.Size = New-Object System.Drawing.Size(235, 45); $PanelAudio.Visible = $false
    $BtnAudioL = Create-Button "🎧 Trái" "Teal"; $BtnAudioL.Size = New-Object System.Drawing.Size(110, 40); $BtnAudioL.Dock = "Left"
    $BtnAudioR = Create-Button "Phải 🎧" "Maroon"; $BtnAudioR.Size = New-Object System.Drawing.Size(110, 40); $BtnAudioR.Dock = "Right"
    $PanelAudio.Controls.Add($BtnAudioL); $PanelAudio.Controls.Add($BtnAudioR)

    $BtnTheme = Create-Button "🌗 Đổi Theme" "SaddleBrown"

    $LblKey = New-Object System.Windows.Forms.Label
    $LblKey.Text = "Test Bàn Phím ở đây:"; $LblKey.ForeColor = [System.Drawing.Color]::Gray; $LblKey.Size = New-Object System.Drawing.Size(235, 20)
    
    $KeyBox = New-Object System.Windows.Forms.TextBox
    $KeyBox.Multiline = $true; $KeyBox.Size = New-Object System.Drawing.Size(235, 80)
    $KeyBox.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30); $KeyBox.ForeColor = [System.Drawing.Color]::Lime

    $LogBox = New-Object System.Windows.Forms.RichTextBox
    $LogBox.Dock = "Fill"; $LogBox.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30); $LogBox.ForeColor = [System.Drawing.Color]::Lime
    $LogBox.Font = New-Object System.Drawing.Font("Consolas", 12); $LogBox.ReadOnly = $true

    $FlowMenu.Controls.AddRange(@($TitleText, $BtnInfo, $BtnMonitor, $BtnCamera, $BtnAudioToggle, $PanelAudio, $BtnTheme, $LblKey, $KeyBox))
    $Form.Controls.Add($LogBox); $Form.Controls.Add($FlowMenu)

    $LogAction = { param($m)
        $LogBox.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $m`n"); $LogBox.ScrollToCaret(); [System.Windows.Forms.Application]::DoEvents()
    }

    $BtnInfo.Add_Click({ Run-InfoTest $LogAction })
    $BtnMonitor.Add_Click({ &$LogAction "Mở cửa sổ Test Màn hình..."; Run-MonitorTest })
    $BtnCamera.Add_Click({ Run-CameraTest $LogAction })
    
    $BtnAudioToggle.Add_Click({ $PanelAudio.Visible = -not $PanelAudio.Visible })
    $BtnAudioL.Add_Click({ Run-AudioTest 'Left' $LogAction })
    $BtnAudioR.Add_Click({ Run-AudioTest 'Right' $LogAction })

    $BtnTheme.Add_Click({
        $global:isDark = -not $global:isDark
        if ($global:isDark) { $Form.BackColor = [System.Drawing.Color]::FromArgb(18,18,18); $LogBox.BackColor = [System.Drawing.Color]::FromArgb(30,30,30); $LogBox.ForeColor = [System.Drawing.Color]::Lime } 
        else { $Form.BackColor = [System.Drawing.Color]::White; $LogBox.BackColor = [System.Drawing.Color]::FromArgb(240,240,240); $LogBox.ForeColor = [System.Drawing.Color]::Black }
    })

    $Tmr = New-Object System.Windows.Forms.Timer; $Tmr.Interval = 300
    $Tmr.Add_Tick({ $TitleText.ForeColor = [System.Drawing.Color]::FromName($global:rgbColors[$global:rgbIdx]); $global:rgbIdx = ($global:rgbIdx + 1) % $global:rgbColors.Length })
    $Tmr.Start()

    $Form.ShowDialog() | Out-Null
}
