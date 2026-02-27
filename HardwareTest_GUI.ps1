<#
.SYNOPSIS
    Hardware Tester Ultra Tương Tác (GUI RGB - Full Auto/Manual Diagnostic)
.DESCRIPTION
    Tích hợp Test Phím Trực quan (Chấm điểm), Chuột, Màn hình (Auto/Manual đa màu).
    Failover: WPF -> WinForms | Win32 API -> CIM -> WMI -> WMIC.
#>

param ( [string]$LogPath = "$env:TEMP\HWTest_Log.txt" )

# ===================================================================
# 1. CORE LOGIC & HELPER FUNCTIONS
# ===================================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$global:apiAvailable = $false
try {
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    public class Win32API {
        [DllImport("user32.dll", CharSet = CharSet.Auto, ExactSpelling = true)]
        public static extern int GetSystemMetrics(int nIndex);
        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool MessageBeep(uint uType);
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

# ===================================================================
# 2. CÁC MODULE TEST CHUYÊN SÂU (POPUP WINFORMS ĐỂ TỐI ƯU WINPE)
# ===================================================================

# --- A. TEST MÀN HÌNH (AUTO / MANUAL) ---
Function Run-MonitorTest ($LogAction) {
    # Form Cấu hình Test Màn hình
    $cfg = New-Object System.Windows.Forms.Form
    $cfg.Text = "Cấu hình Test Màn Hình"; $cfg.Size = New-Object System.Drawing.Size(350, 250); $cfg.StartPosition = "CenterScreen"
    $cfg.BackColor = [System.Drawing.Color]::FromArgb(30,30,30); $cfg.ForeColor = [System.Drawing.Color]::White

    $radManual = New-Object System.Windows.Forms.RadioButton; $radManual.Text = "Manual (Click để đổi màu)"; $radManual.Location = New-Object System.Drawing.Point(20, 20); $radManual.AutoSize = $true; $radManual.Checked = $true
    $radAuto = New-Object System.Windows.Forms.RadioButton; $radAuto.Text = "Auto (Tự động đổi màu)"; $radAuto.Location = New-Object System.Drawing.Point(20, 50); $radAuto.AutoSize = $true
    
    $lblSpd = New-Object System.Windows.Forms.Label; $lblSpd.Text = "Tốc độ (ms):"; $lblSpd.Location = New-Object System.Drawing.Point(40, 80); $lblSpd.AutoSize = $true
    $txtSpd = New-Object System.Windows.Forms.TextBox; $txtSpd.Text = "1000"; $txtSpd.Location = New-Object System.Drawing.Point(120, 77); $txtSpd.Width = 60
    
    $lblLoop = New-Object System.Windows.Forms.Label; $lblLoop.Text = "Số vòng lặp:"; $lblLoop.Location = New-Object System.Drawing.Point(40, 110); $lblLoop.AutoSize = $true
    $txtLoop = New-Object System.Windows.Forms.TextBox; $txtLoop.Text = "2"; $txtLoop.Location = New-Object System.Drawing.Point(120, 107); $txtLoop.Width = 60

    $btnRun = New-Object System.Windows.Forms.Button; $btnRun.Text = "BẮT ĐẦU TEST"; $btnRun.Location = New-Object System.Drawing.Point(80, 150); $btnRun.Size = New-Object System.Drawing.Size(150, 40); $btnRun.BackColor = [System.Drawing.Color]::Cyan; $btnRun.ForeColor = [System.Drawing.Color]::Black; $btnRun.FlatStyle = "Flat"
    
    $cfg.Controls.AddRange(@($radManual, $radAuto, $lblSpd, $txtSpd, $lblLoop, $txtLoop, $btnRun))

    $btnRun.Add_Click({
        $cfg.Hide()
        $isAuto = $radAuto.Checked
        $spd = [int]$txtSpd.Text; if ($spd -lt 1) { $spd = 1 }
        $loops = [int]$txtLoop.Text; if ($loops -lt 1) { $loops = 1 }
        
        # Mở màn hình Test
        $f = New-Object System.Windows.Forms.Form
        $f.FormBorderStyle = 'None'; $f.WindowState = 'Maximized'; $f.TopMost = $true
        # Thêm nhiều màu hơn
        $colors = @('Red','Lime','Blue','White','Black','Yellow','Cyan','Magenta','Gray')
        $script:cIdx = 0; $script:curLoop = 1
        $f.BackColor = [System.Drawing.Color]::FromName($colors[$script:cIdx])
        
        $lblMsg = New-Object System.Windows.Forms.Label; $lblMsg.ForeColor = 'Gray'; $lblMsg.AutoSize = $true; $lblMsg.Font = New-Object System.Drawing.Font("Arial", 16)
        if ($isAuto) { $lblMsg.Text = "Đang chạy Auto... Bấm phím ESC để thoát sớm." } else { $lblMsg.Text = "Click chuột để đổi màu." }
        $f.Controls.Add($lblMsg)

        if ($isAuto) {
            $tmr = New-Object System.Windows.Forms.Timer; $tmr.Interval = $spd
            $tmr.Add_Tick({
                $script:cIdx++
                if ($script:cIdx -ge $colors.Length) { 
                    $script:cIdx = 0; $script:curLoop++
                    if ($script:curLoop -gt $loops) { $tmr.Stop(); $f.Close(); return }
                }
                $f.BackColor = [System.Drawing.Color]::FromName($colors[$script:cIdx]); $lblMsg.Visible = $false
            })
            $tmr.Start()
            $f.Add_KeyDown({ if ($_.KeyCode -eq 'Escape') { $tmr.Stop(); $f.Close() } })
        } else {
            $f.Add_Click({
                $script:cIdx++
                if ($script:cIdx -ge $colors.Length) { $f.Close() }
                else { $f.BackColor = [System.Drawing.Color]::FromName($colors[$script:cIdx]); $lblMsg.Visible = $false }
            })
        }
        $f.ShowDialog() | Out-Null
        $cfg.Close()
    })
    $cfg.ShowDialog() | Out-Null
    &$LogAction "Đã hoàn thành bài test Màn hình."
}

# --- B. TEST CHUỘT ---
Function Run-MouseTest ($LogAction) {
    &$LogAction "Mở bài test Chuột..."
    $mf = New-Object System.Windows.Forms.Form
    $mf.Text = "Mouse Diagnostic"; $mf.Size = New-Object System.Drawing.Size(400, 300); $mf.StartPosition = "CenterScreen"; $mf.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
    
    $pLeft = New-Object System.Windows.Forms.Label; $pLeft.Text = "Chuột Trái"; $pLeft.BackColor = [System.Drawing.Color]::Gray; $pLeft.Size = New-Object System.Drawing.Size(100, 150); $pLeft.Location = New-Object System.Drawing.Point(30, 50); $pLeft.TextAlign = "MiddleCenter"
    $pMid = New-Object System.Windows.Forms.Label; $pMid.Text = "Con Lăn"; $pMid.BackColor = [System.Drawing.Color]::Gray; $pMid.Size = New-Object System.Drawing.Size(60, 80); $pMid.Location = New-Object System.Drawing.Point(160, 50); $pMid.TextAlign = "MiddleCenter"
    $pRight = New-Object System.Windows.Forms.Label; $pRight.Text = "Chuột Phải"; $pRight.BackColor = [System.Drawing.Color]::Gray; $pRight.Size = New-Object System.Drawing.Size(100, 150); $pRight.Location = New-Object System.Drawing.Point(250, 50); $pRight.TextAlign = "MiddleCenter"
    $lblInfo = New-Object System.Windows.Forms.Label; $lblInfo.Text = "Click thử vào các vùng. Lăn chuột. Đóng cửa sổ khi xong."; $lblInfo.ForeColor = [System.Drawing.Color]::Cyan; $lblInfo.AutoSize = $true; $lblInfo.Location = New-Object System.Drawing.Point(30, 220)

    $mf.Controls.AddRange(@($pLeft, $pMid, $pRight, $lblInfo))

    $mf.Add_MouseDown({
        if ($_.Button -eq 'Left') { $pLeft.BackColor = [System.Drawing.Color]::Lime }
        if ($_.Button -eq 'Right') { $pRight.BackColor = [System.Drawing.Color]::Lime }
        if ($_.Button -eq 'Middle') { $pMid.BackColor = [System.Drawing.Color]::Lime }
    })
    $mf.Add_MouseWheel({ $pMid.BackColor = [System.Drawing.Color]::Magenta }) # Đổi màu hồng khi lăn chuột

    $mf.ShowDialog() | Out-Null
    &$LogAction "Đã đóng bài test Chuột."
}

# --- C. TEST BÀN PHÍM TRỰC QUAN (TÍNH ĐIỂM) ---
Function Run-KeyboardTest ($LogAction) {
    &$LogAction "Mở bài test Bàn phím trực quan..."
    $kf = New-Object System.Windows.Forms.Form
    $kf.Text = "Keyboard Diagnostic Pro"; $kf.Size = New-Object System.Drawing.Size(850, 350); $kf.StartPosition = "CenterScreen"; $kf.BackColor = [System.Drawing.Color]::FromArgb(25,25,25)
    $kf.KeyPreview = $true # Bắt mọi phím bấm vào form

    $keyMap = @{}
    $flow = New-Object System.Windows.Forms.FlowLayoutPanel; $flow.Dock = "Top"; $flow.Height = 220; $flow.Padding = New-Object System.Windows.Forms.Padding(10)
    
    # Tạo các nút mô phỏng (QWERTY + Số cơ bản)
    $keysToTest = "Q,W,E,R,T,Y,U,I,O,P,A,S,D,F,G,H,J,K,L,Z,X,C,V,B,N,M,Space,Enter,Up,Down,Left,Right".Split(',')
    foreach ($k in $keysToTest) {
        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $k; $btn.Size = New-Object System.Drawing.Size(50, 50); $btn.BackColor = [System.Drawing.Color]::FromArgb(50,50,50); $btn.ForeColor = [System.Drawing.Color]::White; $btn.FlatStyle = "Flat"
        if ($k -eq "Space") { $btn.Width = 300 }
        if ($k -eq "Enter") { $btn.Width = 100 }
        $flow.Controls.Add($btn)
        $keyMap[$k.ToUpper()] = $btn
    }

    $btnConfirm = New-Object System.Windows.Forms.Button; $btnConfirm.Text = "XÁC NHẬN & TÍNH ĐIỂM"; $btnConfirm.Dock = "Bottom"; $btnConfirm.Height = 50; $btnConfirm.BackColor = [System.Drawing.Color]::Teal; $btnConfirm.ForeColor = [System.Drawing.Color]::White; $btnConfirm.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)

    $kf.Controls.Add($flow); $kf.Controls.Add($btnConfirm)

    $kf.Add_KeyDown({
        $code = $_.KeyCode.ToString().ToUpper()
        if ($code -eq 'SPACE') { $code = 'SPACE' } # Chuẩn hóa tên
        if ($keyMap.ContainsKey($code)) {
            $keyMap[$code].BackColor = [System.Drawing.Color]::Lime
            $keyMap[$code].ForeColor = [System.Drawing.Color]::Black
        }
    })

    $btnConfirm.Add_Click({
        $total = $keyMap.Count; $passed = 0
        foreach ($btn in $keyMap.Values) { if ($btn.BackColor.Name -eq "Lime") { $passed++ } }
        $score = [math]::Round(($passed / $total) * 100, 2)
        
        if ($passed -eq $total) {
            [System.Windows.Forms.MessageBox]::Show("Tuyệt vời! Bàn phím hoàn hảo (100%).", "Kết quả", 0, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
            &$LogAction "[KEYBOARD] Điểm: 100% - OK (Xanh hết)"
        } else {
            [System.Windows.Forms.MessageBox]::Show("Bàn phím bị lỗi hoặc chưa test hết! Điểm: $score% ($passed/$total nút)", "Kết quả", 0, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            &$LogAction "[KEYBOARD] LỖI/CHƯA ĐẠT - Điểm: $score% ($passed/$total nút hoạt động)"
        }
        $kf.Close()
    })

    $kf.ShowDialog() | Out-Null
}

Function Run-OtherTests ($LogAction) {
    &$LogAction "=== TEST TỔNG HỢP KHÁC ==="
    $bios = Get-HardwareData "Win32_BIOS"
    if ($bios) { &$LogAction "[BIOS] $($bios[0].Description) - Ver: $(Get-WmiObject Win32_BIOS | Select -ExpandProperty SMBIOSBIOSVersion -ErrorAction SilentlyContinue)" }
    $batt = Get-HardwareData "Win32_Battery"
    if ($batt) { &$LogAction "[BATTERY] Phát hiện có Pin. Status: $($batt[0].Status)" } else { &$LogAction "[BATTERY] Không có Pin (PC / Lỗi kết nối)" }
}

# (Giữ nguyên Audio & Camera & Info từ bản trước)
Function Run-AudioTest ($Side, $LogAction) {
    try {
        $wmp = New-Object -ComObject WMPlayer.OCX; $wmp.settings.volume = 100
        $soundFile = "$env:windir\Media\tada.wav"; if (-not (Test-Path $soundFile)) { $soundFile = "$env:windir\Media\ding.wav" }
        if ($Side -eq 'Left') { $wmp.settings.balance = -100; &$LogAction "Đang phát tiếng bên LOA TRÁI..." } else { $wmp.settings.balance = 100; &$LogAction "Đang phát tiếng bên LOA PHẢI..." }
        $wmp.URL = $soundFile; $wmp.controls.play()
    } catch { &$LogAction "[!] Không có Media COM. Mainboard Beep..."; if($global:apiAvailable){ [Win32API]::MessageBeep(0) | Out-Null } }
}
Function Run-CameraTest ($LogAction) {
    &$LogAction "=== TEST CAMERA ==="; try { Start-Process "microsoft.windows.camera:" -ErrorAction Stop; &$LogAction "Đã gọi App Windows Camera." } catch {
        &$LogAction "Không gọi được App, quét phần cứng..."; $cams = Get-HardwareData "Win32_PnPEntity" | Where-Object { $_.PNPClass -match 'Image|Camera' }
        if ($cams) { foreach($c in $cams) { &$LogAction " -> Có cắm: $($c.Description)" } } else { &$LogAction " -> Không tìm thấy Camera." }
    }
}
Function Run-InfoTest ($LogAction) {
    &$LogAction "=== ĐỌC THÔNG SỐ TỔNG QUAN ==="
    $cpus = Get-HardwareData "Win32_Processor"; if ($cpus) { foreach($c in $cpus) { &$LogAction "[CPU] $($c.Name)" } }
    $rams = Get-HardwareData "Win32_PhysicalMemory"; if ($rams) { $tr=0; foreach($r in $rams){ $tr+=[math]::Round($r.Capacity/1GB,2) }; &$LogAction "[RAM] Tổng: $tr GB" }
    $disks = Get-HardwareData "Win32_DiskDrive"; if ($disks) { foreach($d in $disks) { &$LogAction "[DISK] $($d.Model) - $($d.Status)" } }
}

# ===================================================================
# 3. KHỞI TẠO GUI CHÍNH (WPF VỚI WINFORMS FALLBACK)
# ===================================================================
$useWPF = $false; try { Add-Type -AssemblyName PresentationFramework -ErrorAction Stop; $useWPF = $true } catch { }
$global:isDark = $true; $global:rgbIdx = 0; $global:rgbColors = "Cyan","Magenta","Yellow","Lime","Orange","DeepSkyBlue","HotPink"

if ($useWPF) {
    # ---------------- WPF ENGINE ----------------
    [xml]$xaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="Hardware Diagnostic Ultra" Height="680" Width="950" WindowStartupLocation="CenterScreen" Background="#121212">
        <Border Name="RgbBorder" BorderBrush="Cyan" BorderThickness="3" CornerRadius="5" Margin="5">
            <Grid Margin="10">
                <Grid.ColumnDefinitions><ColumnDefinition Width="280"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0" Margin="0,0,10,0">
                    <TextBlock Name="TitleText" Text="DIAGNOSTIC ULTRA" FontSize="26" FontWeight="Heavy" Foreground="Cyan" TextAlignment="Center" Margin="0,5,0,20"/>
                    <Button Name="BtnInfo" Content="🔍 Đọc Thông Số &amp; Pin" Height="40" Margin="0,0,0,10" Background="#252526" Foreground="White"/>
                    <Button Name="BtnMonitor" Content="📺 Test Màn (Auto/Manual)" Height="40" Margin="0,0,0,10" Background="#252526" Foreground="White"/>
                    <Button Name="BtnKeyboard" Content="⌨️ Test Phím (Trực quan)" Height="40" Margin="0,0,0,10" Background="#252526" Foreground="Lime" FontWeight="Bold"/>
                    <Button Name="BtnMouse" Content="🖱️ Test Chuột" Height="40" Margin="0,0,0,10" Background="#252526" Foreground="White"/>
                    <Button Name="BtnCamera" Content="📷 Test Camera" Height="40" Margin="0,0,0,10" Background="#252526" Foreground="White"/>
                    <Button Name="BtnAudioToggle" Content="🔊 Test Loa (Mở rộng)" Height="40" Margin="0,0,0,5" Background="#252526" Foreground="White"/>
                    <StackPanel Name="PanelAudio" Visibility="Collapsed" Orientation="Horizontal" Margin="0,0,0,10">
                        <Button Name="BtnAudioL" Content="🎧 Trái" Width="130" Height="35" Margin="0,0,10,0" Background="#1E3E59" Foreground="White"/>
                        <Button Name="BtnAudioR" Content="Phải 🎧" Width="130" Height="35" Background="#591E1E" Foreground="White"/>
                    </StackPanel>
                    <Button Name="BtnTheme" Content="🌗 Đổi Theme" Height="40" Margin="0,15,0,0" Background="#333333" Foreground="White"/>
                </StackPanel>
                <TextBox Name="LogBox" Grid.Column="1" Background="#1E1E1E" Foreground="#00FF00" FontFamily="Consolas" FontSize="14" IsReadOnly="True" VerticalScrollBarVisibility="Auto" AcceptsReturn="True" TextWrapping="Wrap"/>
            </Grid>
        </Border>
    </Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader $xaml); $Window = [Windows.Markup.XamlReader]::Load($reader)
    $UI = @{ RgbBorder=$Window.FindName("RgbBorder"); TitleText=$Window.FindName("TitleText"); LogBox=$Window.FindName("LogBox")
             BtnInfo=$Window.FindName("BtnInfo"); BtnMonitor=$Window.FindName("BtnMonitor"); BtnKeyboard=$Window.FindName("BtnKeyboard"); BtnMouse=$Window.FindName("BtnMouse")
             BtnCamera=$Window.FindName("BtnCamera"); BtnAudioToggle=$Window.FindName("BtnAudioToggle"); PanelAudio=$Window.FindName("PanelAudio")
             BtnAudioL=$Window.FindName("BtnAudioL"); BtnAudioR=$Window.FindName("BtnAudioR"); BtnTheme=$Window.FindName("BtnTheme") }
    
    $LogAction = { param($m) $Window.Dispatcher.Invoke({ $UI.LogBox.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $m`n"); $UI.LogBox.ScrollToEnd() }); Add-Content -Path $LogPath -Value $m }

    $UI.BtnInfo.Add_Click({ Run-InfoTest $LogAction; Run-OtherTests $LogAction })
    $UI.BtnMonitor.Add_Click({ Run-MonitorTest $LogAction })
    $UI.BtnKeyboard.Add_Click({ Run-KeyboardTest $LogAction })
    $UI.BtnMouse.Add_Click({ Run-MouseTest $LogAction })
    $UI.BtnCamera.Add_Click({ Run-CameraTest $LogAction })
    $UI.BtnAudioToggle.Add_Click({ if ($UI.PanelAudio.Visibility -eq 'Collapsed') { $UI.PanelAudio.Visibility = 'Visible' } else { $UI.PanelAudio.Visibility = 'Collapsed' } })
    $UI.BtnAudioL.Add_Click({ Run-AudioTest 'Left' $LogAction }); $UI.BtnAudioR.Add_Click({ Run-AudioTest 'Right' $LogAction })

    $UI.BtnTheme.Add_Click({
        $global:isDark = -not $global:isDark
        if ($global:isDark) { $Window.Background="#121212"; $UI.LogBox.Background="#1E1E1E"; $UI.LogBox.Foreground="#00FF00" } 
        else { $Window.Background="#F0F0F0"; $UI.LogBox.Background="#FFFFFF"; $UI.LogBox.Foreground="#000000" }
    })

    $Tmr = New-Object System.Windows.Threading.DispatcherTimer; $Tmr.Interval = [TimeSpan]::FromMilliseconds(300)
    $Tmr.Add_Tick({ $b = (New-Object System.Windows.Media.BrushConverter).ConvertFromString($global:rgbColors[$global:rgbIdx]); $UI.RgbBorder.BorderBrush = $b; $UI.TitleText.Foreground = $b; $global:rgbIdx = ($global:rgbIdx + 1) % $global:rgbColors.Length })
    $Tmr.Start()

    $Window.ShowDialog() | Out-Null
} else {
    # ---------------- WINFORMS ENGINE (FALLBACK) ----------------
    $Form = New-Object System.Windows.Forms.Form; $Form.Text = "Hardware Diagnostic Ultra - WinForms"; $Form.Size = New-Object System.Drawing.Size(950, 680); $Form.StartPosition = "CenterScreen"; $Form.BackColor = [System.Drawing.Color]::FromArgb(18, 18, 18)
    $FlowMenu = New-Object System.Windows.Forms.FlowLayoutPanel; $FlowMenu.Dock = "Left"; $FlowMenu.Width = 280; $FlowMenu.Padding = New-Object System.Windows.Forms.Padding(10)
    
    $TitleText = New-Object System.Windows.Forms.Label; $TitleText.Text = "DIAGNOSTIC"; $TitleText.Font = New-Object System.Drawing.Font("Arial", 22, [System.Drawing.FontStyle]::Bold); $TitleText.Size = New-Object System.Drawing.Size(260, 50); $TitleText.TextAlign = "MiddleCenter"
    Function Create-Btn($txt, $color, $fg="White") { $b = New-Object System.Windows.Forms.Button; $b.Text = $txt; $b.Size = New-Object System.Drawing.Size(250, 40); $b.BackColor = [System.Drawing.Color]::FromName($color); $b.ForeColor = [System.Drawing.Color]::FromName($fg); $b.FlatStyle = "Flat"; $b.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 10); return $b }

    $BtnInfo = Create-Btn "🔍 Đọc Thông Số & Pin" "ControlDarkDark"
    $BtnMonitor = Create-Btn "📺 Test Màn (Auto/Manual)" "ControlDarkDark"
    $BtnKeyboard = Create-Btn "⌨️ Test Phím (Trực quan)" "ControlDarkDark" "Lime"
    $BtnMouse = Create-Btn "🖱️ Test Chuột" "ControlDarkDark"
    $BtnCamera = Create-Btn "📷 Test Camera" "ControlDarkDark"
    $BtnAudioToggle = Create-Btn "🔊 Test Loa (Mở rộng)" "ControlDarkDark"
    
    $PanelAudio = New-Object System.Windows.Forms.Panel; $PanelAudio.Size = New-Object System.Drawing.Size(250, 40); $PanelAudio.Visible = $false
    $BtnAudioL = Create-Btn "🎧 Trái" "Teal"; $BtnAudioL.Size = New-Object System.Drawing.Size(120, 35); $BtnAudioL.Dock = "Left"
    $BtnAudioR = Create-Btn "Phải 🎧" "Maroon"; $BtnAudioR.Size = New-Object System.Drawing.Size(120, 35); $BtnAudioR.Dock = "Right"
    $PanelAudio.Controls.Add($BtnAudioL); $PanelAudio.Controls.Add($BtnAudioR)
    $BtnTheme = Create-Btn "🌗 Đổi Theme" "SaddleBrown"

    $LogBox = New-Object System.Windows.Forms.RichTextBox; $LogBox.Dock = "Fill"; $LogBox.BackColor = [System.Drawing.Color]::FromArgb(30,30,30); $LogBox.ForeColor = [System.Drawing.Color]::Lime; $LogBox.Font = New-Object System.Drawing.Font("Consolas", 12); $LogBox.ReadOnly = $true
    $FlowMenu.Controls.AddRange(@($TitleText, $BtnInfo, $BtnMonitor, $BtnKeyboard, $BtnMouse, $BtnCamera, $BtnAudioToggle, $PanelAudio, $BtnTheme))
    $Form.Controls.Add($LogBox); $Form.Controls.Add($FlowMenu)

    $LogAction = { param($m) $LogBox.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $m`n"); $LogBox.ScrollToCaret(); [System.Windows.Forms.Application]::DoEvents(); Add-Content -Path $LogPath -Value $m }

    $BtnInfo.Add_Click({ Run-InfoTest $LogAction; Run-OtherTests $LogAction })
    $BtnMonitor.Add_Click({ Run-MonitorTest $LogAction })
    $BtnKeyboard.Add_Click({ Run-KeyboardTest $LogAction })
    $BtnMouse.Add_Click({ Run-MouseTest $LogAction })
    $BtnCamera.Add_Click({ Run-CameraTest $LogAction })
    $BtnAudioToggle.Add_Click({ $PanelAudio.Visible = -not $PanelAudio.Visible })
    $BtnAudioL.Add_Click({ Run-AudioTest 'Left' $LogAction }); $BtnAudioR.Add_Click({ Run-AudioTest 'Right' $LogAction })
    $BtnTheme.Add_Click({
        $global:isDark = -not $global:isDark
        if ($global:isDark) { $Form.BackColor = [System.Drawing.Color]::FromArgb(18,18,18); $LogBox.BackColor = [System.Drawing.Color]::FromArgb(30,30,30); $LogBox.ForeColor = [System.Drawing.Color]::Lime } 
        else { $Form.BackColor = [System.Drawing.Color]::White; $LogBox.BackColor = [System.Drawing.Color]::FromArgb(240,240,240); $LogBox.ForeColor = [System.Drawing.Color]::Black }
    })

    $Tmr = New-Object System.Windows.Forms.Timer; $Tmr.Interval = 300; $Tmr.Add_Tick({ $TitleText.ForeColor = [System.Drawing.Color]::FromName($global:rgbColors[$global:rgbIdx]); $global:rgbIdx = ($global:rgbIdx + 1) % $global:rgbColors.Length }); $Tmr.Start()
    $Form.ShowDialog() | Out-Null
}
