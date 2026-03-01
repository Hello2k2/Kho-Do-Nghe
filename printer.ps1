# ==============================================================================
# Phát Tấn PC - ULTIMATE SYSADMIN & PRINTER TOOL V5.5 PRO (NEON RGB EDITION)
# - Thuật toán màu sắc siêu sặc sỡ (Vibrant RGB)
# - Chữ trắng nổi bật, giao diện mượt mà (WPF + WinForms)
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
$global:SysRand = New-Object System.Random # Biến Random toàn cục giúp trộn màu mượt hơn

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
# MẢNG DỮ LIỆU ĐỘNG 
# ==============================================================================

$UIData = @(
    @{
        TabName = "🖨️ Máy In LAN";
        Buttons = @(
            @{ T="1. Fix Spooler & Kẹt In"; A=$Act_Spooler }
            @{ T="2. Lỗi 11B (PrintNightmare)"; A={ Set-RegSafe "HKLM:\System\CurrentControlSet\Control\Print" "RpcAuthnLevelPrivacyEnabled" 0; &$Act_Spooler } }
            @{ T="3. Lỗi 0709 (RPC Error)"; A={ Set-RegSafe "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC" "RpcUseNamedPipeProtocol" 1; &$Act_Spooler } }
            @{ T="4. Lỗi 007C (RPC Binding)"; A={ Set-RegSafe "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC" "RpcProtocols" 7; &$Act_Spooler } }
            @{ T="5. Lỗi BC4 (A Policy is in effect)"; A={ Set-RegSafe "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint" "RestrictDriverInstallationToAdministrators" 0; &$Act_Spooler } }
            @{ T="6. Lỗi 4005 (Spooler Policy)"; A={ Set-RegSafe "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint" "InForest" 0; &$Act_Spooler } }
            @{ T="7. Lỗi BCB (Firewall Block)"; A={ Run-CmdAndLog "netsh advfirewall firewall set rule group=`"File and Printer Sharing`" new enable=Yes" } }
            @{ T="8. Lỗi 5B3 (Driver Install Fail)"; A={ Set-RegSafe "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint" "Restricted" 0; &$Act_Spooler } }
            @{ T="9. Lỗi 3E3 (Cannot Connect)"; A={ Write-Log "Lỗi này cần Add Local Port (Nhập IP). Đang mở Control Panel..."; Run-CmdAndLog "control printers" } }
            @{ T="10. Lỗi 0002 (Kẹt Local Port)"; A={ Run-CmdAndLog "net stop spooler /y"; Write-Log "Vào Print Management xóa port/driver kẹt"; Run-CmdAndLog "printmanagement.msc" } }
            @{ T="11. Lỗi 0012 (Driver Mismatch)"; A={ Write-Log "Kiểm tra lại bản Win 32bit hay 64bit. Đang mở Print Management..."; Run-CmdAndLog "printmanagement.msc" } }
            @{ T="12. Lỗi 0057 / 139F (Cấp quyền)"; A={ Write-Log "Lỗi Driver/Registry kẹt cứng. Đang reset môi trường Print..."; Run-CmdAndLog "reg delete HKLM\SYSTEM\CurrentControlSet\Control\Print\Environments\Windowsx64\PrintProcessors /f"; &$Act_Spooler } }
            @{ T="13. Lỗi Bận Ảo / Offline"; A={ Write-Log "Vào Port -> Bỏ tick Enable bidirectional support"; Run-CmdAndLog "control printers" } }
        )
    },
    @{
        TabName = "🌐 Mạng & Share";
        Buttons = @(
            @{ T="1. Share D, E, F (Full Mạng)"; A={ Get-PSDrive -PSProvider FileSystem | ?{$_.Name -match "^[DEF]"} | %{Run-CmdAndLog "net share $($_.Name)Drive=$($_.Root) /GRANT:Everyone,FULL"} } }
            @{ T="2. Bật SMBv1 (Fix 0x80004005)"; A={ Run-CmdAndLog "dism /online /Enable-Feature /FeatureName:SMB1Protocol /All /NoRestart" } }
            @{ T="3. Fix Lỗi Đòi Password LAN"; A={ Set-RegSafe "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" "AllowInsecureGuestAuth" 1 } }
            @{ T="4. Xóa Kẹt Pass (Clear Creds)"; A={ Run-CmdAndLog "cmdkey /list | findstr Target > %temp%\creds.txt"; Get-Content "$env:temp\creds.txt" | %{Run-CmdAndLog "cmdkey /delete:$(($_ -split 'Target: ')[1])"} } }
            @{ T="5. Fix Lỗi 0x80070035 (Net Path)"; A={ Run-CmdAndLog "net stop lmhosts /y & net start lmhosts & ipconfig /flushdns" } }
            @{ T="6. Fix Lỗi 0x800704CF (No Reach)"; A={ Run-CmdAndLog "ipconfig /release & ipconfig /renew & netsh winsock reset & netsh int ip reset" } }
            @{ T="7. Fix Lỗi 0x80070043 (Net Name)"; A={ Run-CmdAndLog "net start fdphost & net start fdrespub & net start upnphost" } }
            @{ T="8. Fix Lỗi 0x8007003B (SMB Time)"; A={ Set-RegSafe "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters" "DirectoryCacheLifetime" 0 } }
            @{ T="9. Fix Block Guest (Win 11)"; A={ Set-RegSafe "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation" "AllowInsecureGuestAuth" 1 } }
            @{ T="10. Tắt Tường Lửa Tận Gốc"; A={ Run-CmdAndLog "netsh advfirewall set allprofiles state off" } }
        )
    },
    @{
        TabName = "🛠️ Tiện Ích IN";
        Buttons = @(
            @{ T="1. Clean Mực / Head Cleaning"; A={ Run-CmdAndLog "rundll32 printui.dll,PrintUIEntry /p /n `"$((Get-CimInstance Win32_Printer | Select-Object -First 1).Name)`"" } }
            @{ T="2. Set Mặc Định Toàn Bộ Máy In"; A={ Get-CimInstance Win32_Printer | %{Run-CmdAndLog "rundll32 printui.dll,PrintUIEntry /y /n `"$($_.Name)`""} } }
            @{ T="3. Cài Máy In Ảo (Print to PDF)"; A={ Run-CmdAndLog "dism /Online /Enable-Feature /FeatureName:`"Printing-PrintToPDFServices-Features`" /NoRestart" } }
            @{ T="4. Test Ping GG & LAN"; A={ Run-CmdAndLog "ping 8.8.8.8 -n 4"; Write-Log "IP LAN Của Máy:"; Run-CmdAndLog "ipconfig | findstr IPv4" } }
            @{ T="5. Mở Print Management"; A={ Run-CmdAndLog "printmanagement.msc" } }
            @{ T="6. 🤖 TÌM DRIVER TỰ ĐỘNG"; A=$Act_SearchDriver; Bg="#FF003C" } # Ép Đỏ Neon cho nút tìm kiếm
            @{ T="7. Auto Start Spooler Service"; A={ Run-CmdAndLog "sc config spooler start= auto"; &$Act_Spooler } }
        )
    },
    @{
        TabName = "📠 Scan VIP";
        Buttons = @(
            @{ T="1. Tạo Folder Scan Desktop"; A={ $p="$env:USERPROFILE\Desktop\SCAN_DATA"; md $p -Force; Run-CmdAndLog "net share Scan_Data=`"$p`" /GRANT:Everyone,FULL" } }
            @{ T="2. Mở App WFS (Win Fax Scan)"; A={ Run-CmdAndLog "wfs.exe" } }
            @{ T="3. Fix WIA & Lỗi Kẹt TWAIN"; A={ Run-CmdAndLog "net stop stisvc /y & net start stisvc" } }
            @{ T="4. Chuyển Mạng Private (Lỗi Quét)"; A={ Run-CmdAndLog "Set-NetConnectionProfile -NetworkCategory Private" } }
            @{ T="5. Fix Lỗi Scan SMB NTLMv2"; A={ Set-RegSafe "HKLM:\System\CurrentControlSet\Control\Lsa" "LmCompatibilityLevel" 1 } }
            @{ T="6. Allow WIA Qua Firewall"; A={ Run-CmdAndLog "netsh advfirewall firewall set rule group=`"Windows Image Acquisition`" new enable=Yes" } }
            @{ T="7. Fix Lỗi 0x15 (Scanner Kẹt)"; A={ Run-CmdAndLog "net stop wiaservc /y & net start wiaservc" } }
        )
    },
    @{
        TabName = "📦 In Đơn TMĐT & Bill";
        Buttons = @(
            @{ T="1. Chỉnh Khổ Shopee (A6)"; A=$Act_OpenPrintConfig }
            @{ T="2. Chỉnh Khổ TikTok (A6)"; A=$Act_OpenPrintConfig }
            @{ T="3. Chỉnh Khổ GHTK/VNPost"; A=$Act_OpenPrintConfig }
            @{ T="4. Chỉnh Bill Siêu Thị (K80)"; A=$Act_OpenPrintConfig }
            @{ T="5. Chỉnh Bill Mini (K57)"; A=$Act_OpenPrintConfig }
            @{ T="6. Tạo Khổ Giấy Mới (Server Prop)"; A={ Run-CmdAndLog "rundll32 printui.dll,PrintUIEntry /s" } }
        )
    },
    @{
        TabName = "🌟 AI PRO Features";
        Buttons = @(
            @{ T="1. 🛡️ Bật/Tắt Print Guard (Update)"; A=$Act_PrintGuard }
            @{ T="2. 🔌 Sửa Lỗi Cắm USB Không Nhận"; A={ Write-Log "Mở Device Manager, vui lòng gỡ USB Root Hub rồi quét lại..."; Run-CmdAndLog "devmgmt.msc" } }
            @{ T="3. 📄 Xuất Báo Cáo Cấu Hình IT"; A=$Act_ExportInfo }
            @{ T="4. 🧹 Khôi Phục Host/DNS Gốc"; A=$Act_ResetHost }
            @{ T="5. 🔄 Restart Explorer (Sửa Đơ Máy)"; A={ Stop-Process -Name explorer -Force } }
            @{ T="6. 🧪 Test Giao Diện Sang WinForms"; A={ $global:CurrentUIMode = "WinForms"; $global:MainForm.Close(); Start-App }; Bg="#444444" }
        )
    }
)

# ==============================================================================
# THUẬT TOÁN SINH MÀU SẮC SẶC SỠ (NEON/CYBERPUNK)
# ==============================================================================
function Get-VibrantColor {
    # Ép 1 kênh max (tươi nhất) và 1 kênh min (để không bị pha xám/trắng nhạt)
    $high = $global:SysRand.Next(200, 255)
    $low = $global:SysRand.Next(0, 50)
    $mid = $global:SysRand.Next(0, 255)
    
    # Random vị trí các kênh R, G, B để ra đủ các dải màu (Đỏ, Cam, Lục, Lam, Tím, Hồng)
    $mix = $global:SysRand.Next(1, 7)
    switch ($mix) {
        1 { $r = $high; $g = $mid;  $b = $low }
        2 { $r = $high; $g = $low;  $b = $mid }
        3 { $r = $mid;  $g = $high; $b = $low }
        4 { $r = $low;  $g = $high; $b = $mid }
        5 { $r = $low;  $g = $mid;  $b = $high }
        6 { $r = $mid;  $g = $low;  $b = $high }
    }
    
    # Để chữ trắng nổi trên nền sặc sỡ, ta giảm độ sáng chung xuống khoảng 15%
    $r = [int]($r * 0.85)
    $g = [int]($g * 0.85)
    $b = [int]($b * 0.85)
    
    return "#{0:X2}{1:X2}{2:X2}" -f $r, $g, $b
}

# ==============================================================================
# HÀM RENDER UI (WPF + WINFORMS HYBRID)
# ==============================================================================

function Start-App {
    if ($global:CurrentUIMode -eq "WPF" -and $global:HasWPF) {
        # ---- W P F   M O D E ----
        [xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PHÁT TẤN PC - ULTIMATE SYSADMIN TOOL V5.5 (NEON RGB)" Height="780" Width="1050" Background="#1E1E1E" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI">
    <Window.Resources>
        <Style TargetType="TabItem">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabItem">
                        <Border Name="Border" Padding="15,10" Margin="0,0,2,0" Background="#2D2D30" CornerRadius="4,4,0,0">
                            <ContentPresenter Name="ContentSite" VerticalAlignment="Center" HorizontalAlignment="Center" ContentSource="Header"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="Border" Property="Background" Value="#007ACC"/> 
                                <Setter Property="Foreground" Value="White"/>
                                <Setter Property="FontWeight" Value="Bold"/>
                            </Trigger>
                            <Trigger Property="IsSelected" Value="False">
                                <Setter Property="Foreground" Value="#AAAAAA"/> 
                                <Setter Property="FontWeight" Value="Bold"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Border" Property="Background" Value="#3E3E42"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="ScrollViewer">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollViewer">
                        <Grid>
                            <ScrollContentPresenter />
                            <ScrollBar Name="PART_VerticalScrollBar" Value="{TemplateBinding VerticalOffset}" Maximum="{TemplateBinding ScrollableHeight}" ViewportSize="{TemplateBinding ViewportHeight}" Visibility="{TemplateBinding ComputedVerticalScrollBarVisibility}" HorizontalAlignment="Right" Width="10" Background="#1E1E1E"/>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="65*"/>
            <RowDefinition Height="35*"/>
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
            $Scroll.HorizontalScrollBarVisibility = "Disabled"
            
            $Wrap = New-Object System.Windows.Controls.WrapPanel
            $Wrap.Margin = "10"
            
            foreach ($BtnDef in $TabDef.Buttons) {
                $btn = New-Object System.Windows.Controls.Button
                $btn.Content = $BtnDef.T
                $btn.Width = 290; $btn.Height = 45; $btn.Margin = "8"
                $btn.Cursor = [System.Windows.Input.Cursors]::Hand
                $btn.FontSize = 13; $btn.FontWeight = [System.Windows.FontWeights]::Bold # In đậm chữ cho nổi
                $btn.BorderThickness = "0"
                
                # Nút nào được set Bg tĩnh thì lấy, không thì Random RGB Sặc Sỡ
                $bgColor = if ($BtnDef.Bg) { $BtnDef.Bg } else { Get-VibrantColor }
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

        $global:MainForm.Add_Loaded({ Write-Log "=== Khởi động Phát Tấn PC V5.5 NEON RGB (WPF) ===" "Gold"; Write-Log "Máy: $env:COMPUTERNAME" "Cyan" })
        $global:MainForm.ShowDialog() | Out-Null

    } else {
        # ---- W I N F O R M S   M O D E   (F A L L B A C K) ----
        $global:MainForm = New-Object System.Windows.Forms.Form
        $global:MainForm.Text = "PHÁT TẤN PC - ULTIMATE SYSADMIN TOOL V5.5 NEON RGB (WINFORMS)"
        $global:MainForm.Size = New-Object System.Drawing.Size(1050, 780)
        $global:MainForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1E")
        $global:MainForm.StartPosition = "CenterScreen"

        $MainLayout = New-Object System.Windows.Forms.TableLayoutPanel
        $MainLayout.Dock = "Fill"; $MainLayout.RowCount = 2; $MainLayout.ColumnCount = 1
        $MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 65)))
        $MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 35)))

        $TabCtrl = New-Object System.Windows.Forms.TabControl
        $TabCtrl.Dock = "Fill"; $TabCtrl.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        
        $TabCtrl.DrawMode = [System.Windows.Forms.TabDrawMode]::OwnerDrawFixed
        $TabCtrl.Add_DrawItem({
            param($sender, $e)
            $g = $e.Graphics
            $tabText = $sender.TabPages[$e.Index].Text
            $font = $sender.Font
            $brushBg = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#2D2D30"))
            $brushFg = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#AAAAAA"))

            if ($e.State -match "Selected") {
                $brushBg.Color = [System.Drawing.ColorTranslator]::FromHtml("#007ACC")
                $brushFg.Color = [System.Drawing.Color]::White
            }
            $g.FillRectangle($brushBg, $e.Bounds)
            
            $stringFormat = New-Object System.Drawing.StringFormat
            $stringFormat.Alignment = [System.Drawing.StringAlignment]::Center
            $stringFormat.LineAlignment = [System.Drawing.StringAlignment]::Center
            $g.DrawString($tabText, $font, $brushFg, $e.Bounds, $stringFormat)
        })

        foreach ($TabDef in $UIData) {
            $TabPage = New-Object System.Windows.Forms.TabPage
            $TabPage.Text = $TabDef.TabName
            $TabPage.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2D2D30")
            
            $Flow = New-Object System.Windows.Forms.FlowLayoutPanel
            $Flow.Dock = "Fill"; $Flow.Padding = New-Object System.Windows.Forms.Padding(15); $Flow.AutoScroll = $true

            foreach ($BtnDef in $TabDef.Buttons) {
                $btn = New-Object System.Windows.Forms.Button
                $btn.Text = $BtnDef.T; $btn.Size = New-Object System.Drawing.Size(290, 45)
                $btn.FlatStyle = "Flat"; $btn.ForeColor = [System.Drawing.Color]::White
                
                $bgColor = if ($BtnDef.Bg) { $BtnDef.Bg } else { Get-VibrantColor }
                $btn.BackColor = [System.Drawing.ColorTranslator]::FromHtml($bgColor)
                $btn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold) # Chữ đậm
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

        $global:MainForm.Add_Shown({ Write-Log "=== Khởi động Phát Tấn PC V5.5 NEON RGB (WINFORMS) ===" "Gold"; Write-Log "Máy: $env:COMPUTERNAME" "Cyan" })
        $global:MainForm.ShowDialog() | Out-Null
    }
}

Start-App
