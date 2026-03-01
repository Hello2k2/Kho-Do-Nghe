# ==============================================================================
# Phát Tấn PC - ULTIMATE SYSADMIN & PRINTER TOOL V5.1 PRO (HYBRID EDITION)
# - Chế độ Ưu tiên WPF, tự động Fallback về WinForms
# - Giao diện TabControl tự động render từ Dynamic Array
# ==============================================================================

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { 
    Write-Host "CẢNH BÁO: CHƯA CHẠY QUYỀN ADMIN! Vui lòng chuột phải chọn Run as Administrator." -ForegroundColor Red
    Start-Sleep -Seconds 5
    exit
}

# 1. KIỂM TRA HỖ TRỢ WPF VÀ WINFORMS
$global:HasWPF = $false
try {
    Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
    Add-Type -AssemblyName PresentationCore -ErrorAction Stop
    Add-Type -AssemblyName WindowsBase -ErrorAction Stop
    $global:HasWPF = $true
} catch { $global:HasWPF = $false }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$global:CurrentUIMode = if ($global:HasWPF) { "WPF" } else { "WinForms" }
$global:LogControl = $null

# ==============================================================================
# ENGINE: XỬ LÝ LOGIC (LOG, CMD, REGISTRY)
# ==============================================================================

function Write-Log ($Message, $Color = "LimeGreen") {
    $time = (Get-Date).ToString("HH:mm:ss")
    $FullMsg = "[$time] $Message`n"
    
    if ($global:LogControl -is [System.Windows.Forms.RichTextBox]) {
        $global:LogControl.SelectionStart = $global:LogControl.TextLength
        $global:LogControl.SelectionLength = 0
        $global:LogControl.SelectionColor = [System.Drawing.Color]::$Color
        $global:LogControl.AppendText($FullMsg)
        $global:LogControl.ScrollToCaret()
    } elseif ($global:LogControl -is [System.Windows.Controls.TextBox]) {
        $global:LogControl.AppendText($FullMsg)
        $global:LogControl.ScrollToEnd()
    }
    
    $CColor = "White"
    if ($Color -match "Green") { $CColor = "Green" } elseif ($Color -match "Red") { $CColor = "Red" }
    elseif ($Color -match "Yellow" -or $Color -match "Orange") { $CColor = "Yellow" }
    elseif ($Color -match "Cyan" -or $Color -match "Blue") { $CColor = "Cyan" }
    Write-Host "[$time] $Message" -ForegroundColor $CColor
}

function Run-CmdAndLog ($cmdStr) {
    Write-Log "Đang chạy: $cmdStr" "Cyan"
    $output = Invoke-Expression $cmdStr 2>&1
    foreach ($line in $output) { if (![string]::IsNullOrWhiteSpace($line)) { Write-Log "  $line" "White" } }
}

function Set-RegSafe ($Path, $Name, $Value, $Type = "DWord") {
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
        Write-Log "  -> Reg [$Name] = $Value (OK)" "White"
    } catch {
        $cType = if ($Type -eq "DWord") { "REG_DWORD" } else { "REG_SZ" }
        Run-CmdAndLog "reg add `"$Path`" /v $Name /t $cType /d $Value /f"
    }
}

# ==============================================================================
# CÁC MODULE CHỨC NĂNG CỐT LÕI
# ==============================================================================

$Act_Spooler = {
    Write-Log "Đang Restart Spooler và xóa kẹt lệnh in..." "Yellow"
    Run-CmdAndLog "net stop spooler /y"
    Run-CmdAndLog "del /Q /F /S %systemroot%\System32\Spool\Printers\*.*"
    Run-CmdAndLog "net start spooler"
}

$Act_SearchDriver = {
    Write-Log "Đang tìm kiếm Driver cho máy in Mặc Định..." "Cyan"
    $defPrinter = Get-WmiObject -Query " SELECT * FROM Win32_Printer WHERE Default=$true"
    if ($defPrinter) {
        $query = "Download driver $($defPrinter.Name) Windows"
        $url = "https://www.google.com/search?q=" + [System.Uri]::EscapeDataString($query)
        Start-Process $url
        Write-Log "Đã mở trình duyệt tìm: $($defPrinter.Name)" "LimeGreen"
    } else { Write-Log "Không tìm thấy máy in mặc định nào!" "Red" }
}

$Act_ExportInfo = {
    Write-Log "Đang xuất cấu hình máy ra Desktop..." "Yellow"
    $path = "$env:USERPROFILE\Desktop\IT_Report_$env:COMPUTERNAME.txt"
    "BÁO CÁO CẤU HÌNH PC: $env:COMPUTERNAME" | Out-File $path
    "IP LAN: $((ipconfig | Select-String 'IPv4').Line.Trim())" | Out-File $path -Append
    "Danh sách máy in:" | Out-File $path -Append
    Get-CimInstance Win32_Printer | Select-Object Name, PortName, DriverName | Format-Table | Out-File $path -Append
    Start-Process notepad.exe $path
    Write-Log "Đã lưu file tại Desktop!" "LimeGreen"
}

$Act_PrintGuard = {
    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    $val = try { (Get-ItemProperty $path -ErrorAction Stop).NoAutoUpdate } catch { 0 }
    if ($val -eq 1) {
        Set-RegSafe $path "NoAutoUpdate" 0; Write-Log "Đã MỞ LẠI Windows Update." "Yellow"
    } else {
        Set-RegSafe $path "NoAutoUpdate" 1; Write-Log "Đã CHẶN Windows Update (Print Guard Active)." "LimeGreen"
    }
}

$Act_ResetHost = {
    Write-Log "Khôi phục file Hosts và Flush DNS..." "Yellow"
    $hostPath = "$env:windir\System32\drivers\etc\hosts"
    @"
# Default Hosts File
127.0.0.1 localhost
::1 localhost
"@ | Out-File $hostPath -Encoding ascii
    Run-CmdAndLog "ipconfig /flushdns"; Write-Log "Đã làm sạch File Host!" "LimeGreen"
}

$Act_OpenPrintConfig = {
    Write-Log "Đang mở bảng tùy chỉnh khổ giấy (Preferences)..." "Yellow"
    $defPrinter = Get-WmiObject -Query " SELECT * FROM Win32_Printer WHERE Default=$true"
    if ($defPrinter) { Run-CmdAndLog "rundll32 printui.dll,PrintUIEntry /e /n `"$($defPrinter.Name)`"" }
    else { Run-CmdAndLog "control printers" }
}

# ==============================================================================
# MẢNG DỮ LIỆU ĐỘNG (THÊM/XÓA NÚT Ở ĐÂY SẼ TỰ ĐỘNG CẬP NHẬT GIAO DIỆN)
# ==============================================================================

$UIData = @(
    @{
        TabName = "🖨️ Máy In LAN"; Color = "#8A2BE2"
        Buttons = @(
            @{ T="1. Fix Spooler & Kẹt In"; A=$Act_Spooler }
            @{ T="2. Lỗi 11B (PrintNightmare)"; A={ Set-RegSafe "HKLM:\System\CurrentControlSet\Control\Print" "RpcAuthnLevelPrivacyEnabled" 0; &$Act_Spooler } }
            @{ T="3. Lỗi 0709 / 07C"; A={ Set-RegSafe "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC" "RpcUseNamedPipeProtocol" 1 } }
            @{ T="4. Lỗi BC4 / 4005 (Policy)"; A={ Set-RegSafe "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint" "RestrictDriverInstallationToAdministrators" 0 } }
            @{ T="5. Lỗi Bận Ảo / Communication"; A={ Write-Log "Tắt BidiSupport trên máy con..."; Run-CmdAndLog "control printers" } }
            @{ T="6. Lỗi BCB / Tường lửa"; A={ Run-CmdAndLog "netsh advfirewall firewall set rule group=`"File and Printer Sharing`" new enable=Yes" } }
            @{ T="7. Add Local Port (Lỗi 3E3)"; A={ Run-CmdAndLog "control printers" } }
            @{ T="8. Fix Triệt Để Registry Spool"; A={ Run-CmdAndLog "reg delete HKLM\SYSTEM\CurrentControlSet\Control\Print\Environments\Windowsx64\PrintProcessors /f" } }
        )
    },
    @{
        TabName = "🌐 Mạng & Share"; Color = "#20B2AA"
        Buttons = @(
            @{ T="1. Share D, E, F (Full)"; A={ Get-PSDrive -PSProvider FileSystem | ?{$_.Name -match "^[DEF]"} | %{Run-CmdAndLog "net share $($_.Name)Drive=$($_.Root) /GRANT:Everyone,FULL"} } }
            @{ T="2. Bật SMBv1 (Máy cũ)"; A={ Run-CmdAndLog "dism /online /Enable-Feature /FeatureName:SMB1Protocol /All /NoRestart" } }
            @{ T="3. Fix Đòi Password LAN"; A={ Set-RegSafe "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" "AllowInsecureGuestAuth" 1 } }
            @{ T="4. Xóa Kẹt Session Mạng"; A={ Run-CmdAndLog "cmdkey /list | findstr Target > %temp%\creds.txt"; Get-Content "$env:temp\creds.txt" | %{Run-CmdAndLog "cmdkey /delete:$(($_ -split 'Target: ')[1])"} } }
            @{ T="5. Deep Reset Network"; A={ Run-CmdAndLog "ipconfig /release & ipconfig /flushdns & netsh winsock reset & netsh int ip reset" } }
            @{ T="6. Khôi phục Dịch vụ Mạng"; A={ Run-CmdAndLog "net start fdphost & net start fdrespub & net start upnphost" } }
            @{ T="7. Fix Block Guest"; A={ Set-RegSafe "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation" "AllowInsecureGuestAuth" 1 } }
            @{ T="8. Tắt Tường Lửa"; A={ Run-CmdAndLog "netsh advfirewall set allprofiles state off" } }
        )
    },
    @{
        TabName = "🛠️ Tiện Ích IN"; Color = "#FF8C00"
        Buttons = @(
            @{ T="1. Clean Mực / Head Cleaning"; A={ Run-CmdAndLog "rundll32 printui.dll,PrintUIEntry /p /n `"$((Get-CimInstance Win32_Printer | Select-Object -First 1).Name)`"" } }
            @{ T="2. Set Mặc Định Toàn Bộ"; A={ Get-CimInstance Win32_Printer | %{Run-CmdAndLog "rundll32 printui.dll,PrintUIEntry /y /n `"$($_.Name)`""} } }
            @{ T="3. Thêm Print to PDF"; A={ Run-CmdAndLog "dism /Online /Enable-Feature /FeatureName:`"Printing-PrintToPDFServices-Features`" /NoRestart" } }
            @{ T="4. Kiểm Tra Ping"; A={ Run-CmdAndLog "ping 8.8.8.8 -n 4" } }
            @{ T="5. Quản Lý Print Management"; A={ Run-CmdAndLog "printmanagement.msc" } }
            @{ T="6. 🤖 AUTO SEARCH DRIVER"; A=$Act_SearchDriver; Bg="#FF1493" }
            @{ T="7. Khôi Phục Print Spooler"; A={ Run-CmdAndLog "sc config spooler start= auto"; &$Act_Spooler } }
        )
    },
    @{
        TabName = "📠 Scan VIP"; Color = "#3CB371"
        Buttons = @(
            @{ T="1. Tạo Folder Scan Desktop"; A={ $p="$env:USERPROFILE\Desktop\SCAN_DATA"; md $p -Force; Run-CmdAndLog "net share Scan_Data=`"$p`" /GRANT:Everyone,FULL" } }
            @{ T="2. Mở App WFS"; A={ Run-CmdAndLog "wfs.exe" } }
            @{ T="3. Fix WIA & TWAIN"; A={ Run-CmdAndLog "net stop stisvc /y & net start stisvc" } }
            @{ T="4. Chuyển Mạng Private"; A={ Run-CmdAndLog "Set-NetConnectionProfile -NetworkCategory Private" } }
            @{ T="5. Fix Scan NTLMv2 (Win10)"; A={ Set-RegSafe "HKLM:\System\CurrentControlSet\Control\Lsa" "LmCompatibilityLevel" 1 } }
            @{ T="6. Allow WIA Firewall"; A={ Run-CmdAndLog "netsh advfirewall firewall set rule group=`"Windows Image Acquisition`" new enable=Yes" } }
        )
    },
    @{
        TabName = "📦 In Đơn Shopee"; Color = "#FF69B4"
        Buttons = @(
            @{ T="1. Chỉnh Khổ Shopee (A6)"; A=$Act_OpenPrintConfig }
            @{ T="2. Chỉnh Khổ TikTok (A6)"; A=$Act_OpenPrintConfig }
            @{ T="3. Chỉnh Khổ GHTK/VNPost"; A=$Act_OpenPrintConfig }
            @{ T="4. Chỉnh Bill Siêu Thị (K80)"; A=$Act_OpenPrintConfig }
            @{ T="5. Chỉnh Bill Mini (K57)"; A=$Act_OpenPrintConfig }
            @{ T="6. Tạo Khổ Giấy Mới"; A={ Run-CmdAndLog "rundll32 printui.dll,PrintUIEntry /s" } }
        )
    },
    @{
        TabName = "🌟 AI PRO Features"; Color = "#DC143C"
        Buttons = @(
            @{ T="1. Bật/Tắt Print Guard"; A=$Act_PrintGuard }
            @{ T="2. Sửa Không Nhận USB"; A={ Write-Log "Mở Device Manager, vui lòng xóa USB Root Hub..."; Run-CmdAndLog "devmgmt.msc" } }
            @{ T="3. Xuất Báo Cáo IT"; A=$Act_ExportInfo }
            @{ T="4. Khôi Phục Host/DNS"; A=$Act_ResetHost }
            @{ T="5. Restart Explorer"; A={ Stop-Process -Name explorer -Force } }
            @{ T="6. 🔄 Test Sang WinForms"; A={ $global:CurrentUIMode = "WinForms"; $global:MainForm.Close(); Start-App }; Bg="#444444" }
        )
    }
)

# ==============================================================================
# HÀM RENDER UI (WPF + WINFORMS HYBRID)
# ==============================================================================

function Start-App {
    if ($global:CurrentUIMode -eq "WPF" -and $global:HasWPF) {
        # ---- W P F   M O D E ----
        [xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="PHÁT TẤN PC - ULTIMATE SYSADMIN TOOL V5.1 (WPF)" Height="750" Width="1000" Background="#1E1E1E" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI">
    <Window.Resources>
        <Style TargetType="TabItem">
            <Setter Property="Background" Value="#2D2D30"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Padding" Value="12,8"/>
            <Setter Property="Margin" Value="0,0,2,0"/>
        </Style>
    </Window.Resources>
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="6*"/>
            <RowDefinition Height="4*"/>
        </Grid.RowDefinitions>
        
        <TabControl Name="MainTabControl" Background="#2D2D30" BorderThickness="0" Grid.Row="0" Margin="10,10,10,5"/>
        
        <GroupBox Header="📋 TRẠNG THÁI HỆ THỐNG" Foreground="Gold" FontWeight="Bold" Grid.Row="1" Margin="10,5,10,10" BorderBrush="#333333">
            <TextBox Name="txtLog" Background="#121212" Foreground="#00FF00" FontFamily="Consolas" FontSize="13" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" BorderThickness="0"/>
        </GroupBox>
    </Grid>
</Window>
"@
        $reader = (New-Object System.Xml.XmlNodeReader $xaml)
        $global:MainForm = [System.Windows.Markup.XamlReader]::Load($reader)
        $global:LogControl = $global:MainForm.FindName("txtLog")
        $TabCtrl = $global:MainForm.FindName("MainTabControl")
        
        $brushConv = New-Object System.Windows.Media.BrushConverter

        foreach ($TabDef in $UIData) {
            $TabItem = New-Object System.Windows.Controls.TabItem
            $TabItem.Header = $TabDef.TabName
            
            $Scroll = New-Object System.Windows.Controls.ScrollViewer
            $Scroll.VerticalScrollBarVisibility = "Auto"
            
            $Wrap = New-Object System.Windows.Controls.WrapPanel
            $Wrap.Margin = "10"
            
            foreach ($BtnDef in $TabDef.Buttons) {
                $btn = New-Object System.Windows.Controls.Button
                $btn.Content = $BtnDef.T
                $btn.Width = 270; $btn.Height = 45; $btn.Margin = "8"
                $btn.Cursor = [System.Windows.Input.Cursors]::Hand
                $btn.FontSize = 13; $btn.FontWeight = [System.Windows.FontWeights]::Normal
                $btn.BorderThickness = "0"
                
                $bgColor = if ($BtnDef.Bg) { $BtnDef.Bg } else { $TabDef.Color }
                $btn.Background = $brushConv.ConvertFromString($bgColor)
                $btn.Foreground = [System.Windows.Media.Brushes]::White
                
                $handler = { & $BtnDef.A }.GetNewClosure()
                $btn.Add_Click($handler)
                
                $Wrap.Children.Add($btn)
            }
            $Scroll.Content = $Wrap
            $TabItem.Content = $Scroll
            $TabCtrl.Items.Add($TabItem)
        }

        $global:MainForm.Add_Loaded({ Write-Log "=== Khởi động Phát Tấn PC V5.1 (WPF ENGINE) ===" "Gold"; Write-Log "Máy: $env:COMPUTERNAME" "Cyan" })
        $global:MainForm.ShowDialog() | Out-Null

    } else {
        # ---- W I N F O R M S   M O D E   (F A L L B A C K) ----
        $global:MainForm = New-Object System.Windows.Forms.Form
        $global:MainForm.Text = "PHÁT TẤN PC - ULTIMATE SYSADMIN TOOL V5.1 (WINFORMS)"
        $global:MainForm.Size = New-Object System.Drawing.Size(1000, 750)
        $global:MainForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1E")
        $global:MainForm.StartPosition = "CenterScreen"

        $MainLayout = New-Object System.Windows.Forms.TableLayoutPanel
        $MainLayout.Dock = "Fill"; $MainLayout.RowCount = 2; $MainLayout.ColumnCount = 1
        $MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 400)))
        $MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100)))

        $TabCtrl = New-Object System.Windows.Forms.TabControl
        $TabCtrl.Dock = "Fill"; $TabCtrl.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

        foreach ($TabDef in $UIData) {
            $TabPage = New-Object System.Windows.Forms.TabPage
            $TabPage.Text = $TabDef.TabName
            $TabPage.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2D2D30")
            
            $Flow = New-Object System.Windows.Forms.FlowLayoutPanel
            $Flow.Dock = "Fill"; $Flow.Padding = New-Object System.Windows.Forms.Padding(15); $Flow.AutoScroll = $true

            foreach ($BtnDef in $TabDef.Buttons) {
                $btn = New-Object System.Windows.Forms.Button
                $btn.Text = $BtnDef.T; $btn.Size = New-Object System.Drawing.Size(260, 45)
                $btn.FlatStyle = "Flat"; $btn.ForeColor = [System.Drawing.Color]::White
                
                $bgColor = if ($BtnDef.Bg) { $BtnDef.Bg } else { $TabDef.Color }
                $btn.BackColor = [System.Drawing.ColorTranslator]::FromHtml($bgColor)
                $btn.Font = New-Object System.Drawing.Font("Segoe UI", 10)
                $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
                $btn.Margin = New-Object System.Windows.Forms.Padding(6)
                
                $handler = { & $BtnDef.A }.GetNewClosure()
                $btn.Add_Click($handler)
                
                $Flow.Controls.Add($btn)
            }
            $TabPage.Controls.Add($Flow)
            $TabCtrl.TabPages.Add($TabPage)
        }
        $MainLayout.Controls.Add($TabCtrl, 0, 0)

        $gbLog = New-Object System.Windows.Forms.GroupBox
        $gbLog.Dock = "Fill"; $gbLog.Text = "📋 TRẠNG THÁI HỆ THỐNG"; $gbLog.ForeColor = [System.Drawing.Color]::Gold
        $gbLog.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)

        $txtLog = New-Object System.Windows.Forms.RichTextBox
        $txtLog.Dock = "Fill"; $txtLog.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#121212")
        $txtLog.Font = New-Object System.Drawing.Font("Consolas", 11)
        $global:LogControl = $txtLog

        $gbLog.Controls.Add($txtLog)
        $MainLayout.Controls.Add($gbLog, 0, 1)
        $global:MainForm.Controls.Add($MainLayout)

        $global:MainForm.Add_Shown({ Write-Log "=== Khởi động Phát Tấn PC V5.1 (WINFORMS ENGINE) ===" "Gold"; Write-Log "Máy: $env:COMPUTERNAME" "Cyan" })
        $global:MainForm.ShowDialog() | Out-Null
    }
}

Start-App
