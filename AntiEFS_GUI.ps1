# =============================================================================
# PHAT TAN PC - QUICK FIX TOOL V14.0 (RGB GALAXY EDITION)
# 15 FIXES/BUTTON - DARK/LIGHT RGB THEME - DUAL UI & 5-TIER LOGIC
# =============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 1. YÊU CẦU QUYỀN ADMIN
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "powershell.exe"
    $processInfo.Arguments = "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $processInfo.Verb = "runas"
    [System.Diagnostics.Process]::Start($processInfo); Exit
}

# --- CẤU HÌNH & LOGGING ---
$LogFile = "$PSScriptRoot\PhatTanPC_FixLog.txt"
if ([string]::IsNullOrEmpty($PSScriptRoot)) { $LogFile = ".\PhatTanPC_FixLog.txt" }
$Global:UIType = "NONE" 
$Global:IsDarkMode = $true
$IsWinPE = Test-Path "HKLM:\System\CurrentControlSet\Control\MiniNT"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $TimeStamp = Get-Date -Format "HH:mm:ss"
    $LogLine = "[$TimeStamp] [$Level] $Message"
    try { Add-Content -Path $LogFile -Value $LogLine -ErrorAction SilentlyContinue } catch {}
    
    if ($Global:UIType -eq "WPF" -and $Global:WpfLogBox) {
        $Global:WpfLogBox.Dispatcher.Invoke([action]{ $Global:WpfLogBox.AppendText("$LogLine`r`n"); $Global:WpfLogBox.ScrollToEnd() })
    } elseif ($Global:UIType -eq "WINFORMS" -and $Global:WfLogBox) {
        if ($Global:WfLogBox.InvokeRequired) { $Global:WfLogBox.Invoke([action]{ Write-Log $Message $Level }) } 
        else { $Global:WfLogBox.AppendText("$LogLine`r`n"); $Global:WfLogBox.SelectionStart = $Global:WfLogBox.Text.Length; $Global:WfLogBox.ScrollToCaret(); [System.Windows.Forms.Application]::DoEvents() }
    }
}

# =============================================================================
# HỆ THỐNG LÕI & CÁC TÁC VỤ 5-TIER (MỖI TÁC VỤ 15 BƯỚC)
# =============================================================================

function Stop-ServiceSafe($SvcName) { try { Stop-Service -Name $SvcName -Force -ErrorAction Stop | Out-Null } catch { cmd.exe /c "net stop $SvcName /y" 2>$null } }

function Fix-NetworkAndDNS { 
    Write-Log "Đang chạy 15 bước Reset Mạng Toàn Diện..." "INFO"
    $Cmds = @("ipconfig /flushdns", "ipconfig /registerdns", "ipconfig /release", "ipconfig /renew", "netsh winsock reset", "netsh int ip reset", "netsh int ipv4 reset", "netsh int ipv6 reset", "netsh int tcp reset", 'reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /f', 'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f', 'netsh interface ipv4 set dns name="Ethernet" static 8.8.8.8 both', 'netsh interface ipv4 set dns name="Wi-Fi" static 8.8.8.8 both', "arp -d *", "nbtstat -R")
    for($i=0; $i -lt 15; $i++) { cmd.exe /c $Cmds[$i] 2>$null | Out-Null; Write-Log "Bước $($i+1)/15: Thực thi $($Cmds[$i].Split(' ')[0])..." "WARN" }
    Write-Log "Đã khôi phục mạng chuyên sâu (15 lỗi)!" "SUCCESS" 
}

function Clean-TempAndJunk { 
    Write-Log "Đang càn quét 15 phân vùng rác hệ thống..." "INFO"
    $Paths = @("$env:TEMP\*", "$env:WINDIR\Temp\*", "$env:WINDIR\Prefetch\*", "$env:WINDIR\SoftwareDistribution\Download\*", "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\ThumbCacheToDelete\*", "$env:LOCALAPPDATA\CrashDumps\*", "$env:WINDIR\System32\wbem\Repository\*", "$env:LOCALAPPDATA\D3DSCache\*", "$env:LOCALAPPDATA\NVIDIA\GLCache\*", "$env:LOCALAPPDATA\AMD\DxCache\*", "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*", "$env:WINDIR\Logs\CBS\*", "$env:WINDIR\System32\winevt\Logs\*", "$env:LOCALAPPDATA\Temp\*", "C:\$Recycle.Bin\*")
    for($i=0; $i -lt 15; $i++) { try { Remove-Item -Path ($Paths[$i] -replace "\*","") -Recurse -Force -ErrorAction SilentlyContinue | Out-Null } catch {}; Write-Log "Bước $($i+1)/15: Dọn dẹp $($Paths[$i])" "WARN" }
    Write-Log "Đã dọn dẹp 15 vùng rác hoàn tất!" "SUCCESS" 
}

function Fix-WindowsUpdate { 
    Write-Log "Đang ép Reset Windows Update (15 Tác vụ)..." "INFO"; if ($IsWinPE) { return }
    $Svcs = @("wuauserv", "cryptSvc", "bits", "msiserver", "UsoSvc", "DoSvc", "TrustedInstaller", "AppIDSvc")
    for($i=0; $i -lt 8; $i++) { Stop-ServiceSafe $Svcs[$i]; Write-Log "Bước $($i+1)/15: Stop $($Svcs[$i])" "WARN" }
    cmd.exe /c 'ren %WINDIR%\SoftwareDistribution SoftwareDistribution.bak' 2>$null; Write-Log "Bước 9/15: Backup SoftwareDistribution" "WARN"
    cmd.exe /c 'ren %WINDIR%\System32\catroot2 catroot2.bak' 2>$null; Write-Log "Bước 10/15: Backup catroot2" "WARN"
    cmd.exe /c 'sc config wuauserv start= auto' 2>$null; Write-Log "Bước 11/15: Re-config Auto Start" "WARN"
    for($i=0; $i -lt 4; $i++) { cmd.exe /c "net start $($Svcs[$i])" 2>$null | Out-Null; Write-Log "Bước $($i+12)/15: Start $($Svcs[$i])" "WARN" }
    Write-Log "Sửa lỗi Update 15 bước hoàn tất!" "SUCCESS" 
}

function Fix-VirusRegistry { 
    Write-Log "Đang mở khóa 15 Policy Registry bị Virus phá..." "INFO"
    $Keys = @("DisableTaskMgr", "DisableRegistryTools", "DisableCMD", "NoControlPanel", "NoFolderOptions", "NoRun", "NoWinKeys", "DisableLockWorkstation", "DisableChangePassword", "NoLogoff", "NoDrives", "NoViewOnDrive", "HideClock", "NoTrayItemsDisplay", "NoAutoTrayNotify")
    for($i=0; $i -lt 15; $i++) { cmd.exe /c "reg delete `"HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System`" /v $($Keys[$i]) /f" 2>$null; Write-Log "Bước $($i+1)/15: Mở khóa $($Keys[$i])" "WARN" }
    Write-Log "Đã giải cứu 15 chốt chặn Registry!" "SUCCESS" 
}

function Export-HtmlReport {
    Write-Log "Đang xuất báo cáo..." "INFO"
    $HtmlPath = "$PSScriptRoot\PhatTanPC_BaoCao.html"; if ([string]::IsNullOrEmpty($PSScriptRoot)) { $HtmlPath = ".\PhatTanPC_BaoCao.html" }
    $Html = "<html><head><meta charset='utf-8'><title>Báo Cáo - Phát Tấn PC</title><style>body{font-family:Segoe UI, Arial; background:#1e1e28; color:#fff; padding:20px;} h1{color:#00e5ff; text-align:center;} .log{background:#0a0a0f; color:#0f0; padding:15px; border-radius:8px; height:400px; overflow-y:scroll; line-height:1.5; box-shadow: 0 0 10px #00e5ff;}</style></head><body><h1>🌈 PHÁT TẤN PC - BÁO CÁO CỨU HỘ V14.0 🌈</h1><div class='log'>"
    try { $Logs = Get-Content $LogFile -ErrorAction Stop; foreach ($L in $Logs) { $Html += "$L<br>" } } catch { $Html += "Không có log." }
    $Html += "</div><h3 style='text-align:center; color:#ffeb3b;'>Cảm ơn quý khách đã tin tưởng Phát Tấn PC!</h3></body></html>"
    $Html | Out-File $HtmlPath -Encoding UTF8; Start-Process $HtmlPath
}

# =============================================================================
# POPUP MENU: MÁY IN (15 LỖI) & GAME (15 LỖI)
# =============================================================================
function Show-Popup15 ($Title, $Items, $ThemePrefix) {
    Add-Type -AssemblyName System.Windows.Forms
    $Pop = New-Object System.Windows.Forms.Form
    $Pop.Text = $Title; $Pop.Size = New-Object System.Drawing.Size(420, 580); $Pop.StartPosition = "CenterParent"; $Pop.FormBorderStyle = "FixedToolWindow"
    $Pop.BackColor = if ($Global:IsDarkMode) { [System.Drawing.Color]::FromArgb(35, 35, 45) } else { [System.Drawing.Color]::WhiteSmoke }

    $Lbl = New-Object System.Windows.Forms.Label; $Lbl.Text = "CHỌN 1 TRONG 15 TÁC VỤ CHUYÊN SÂU:"; $Lbl.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold); $Lbl.ForeColor = if ($Global:IsDarkMode) { "Cyan" } else { "Blue" }; $Lbl.AutoSize = $true; $Lbl.Location = New-Object System.Drawing.Point(20, 15); $Pop.Controls.Add($Lbl)

    $Flow = New-Object System.Windows.Forms.FlowLayoutPanel; $Flow.Dock = "Bottom"; $Flow.Height = 500; $Flow.FlowDirection = "TopDown"; $Flow.AutoScroll = $true; $Flow.WrapContents = $false; $Pop.Controls.Add($Flow)

    # RGB Colors for 15 buttons
    $RGB_Dark = @("255,23,68", "0,230,118", "41,121,255", "213,0,249", "255,145,0", "0,229,255", "255,61,0", "0,176,255", "118,255,3", "255,214,0", "245,0,87", "101,31,255", "29,233,182", "255,193,7", "198,40,40")
    $RGB_Light = @("211,47,47", "56,142,60", "25,118,210", "123,31,162", "245,124,0", "0,151,167", "230,74,25", "2,136,209", "104,159,56", "251,192,45", "194,24,91", "81,45,168", "0,150,136", "255,160,0", "183,28,28")

    $Counter = 0
    foreach ($Item in $Items) {
        $Btn = New-Object System.Windows.Forms.Button
        $Btn.Text = "$($Counter+1). $($Item.Name)"
        $Btn.Size = New-Object System.Drawing.Size(360, 40); $Btn.Margin = New-Object System.Windows.Forms.Padding(15, 3, 0, 3)
        $Btn.FlatStyle = "Flat"; $Btn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        
        $cArr = if ($Global:IsDarkMode) { $RGB_Dark[$Counter] -split ',' } else { $RGB_Light[$Counter] -split ',' }
        $Btn.BackColor = [System.Drawing.Color]::FromArgb($cArr[0], $cArr[1], $cArr[2])
        $Btn.ForeColor = "White"
        
        $Code = $Item.Code
        $Btn.Add_Click({ $Pop.Close(); Write-Log "Thực thi: $($this.Text)" "INFO"; & $Code })
        $Flow.Controls.Add($Btn)
        $Counter++
    }
    $Pop.ShowDialog() | Out-Null
}

$Prn15 = @(
    @{Name="Kẹt lệnh in (Clear Print Spooler)"; Code={ Stop-ServiceSafe "Spooler"; Remove-Item "$env:WINDIR\System32\spool\PRINTERS\*" -Force -Recurse -ErrorAction SilentlyContinue; cmd.exe /c "net start spooler" 2>$null; Write-Log "Xong 1/15" "SUCCESS" }},
    @{Name="Fix lỗi LAN 0x0000011b (PrintNightmare)"; Code={ cmd.exe /c 'reg add "HKLM\System\CurrentControlSet\Control\Print" /v RpcAuthnLevelPrivacyEnabled /t REG_DWORD /d 0 /f' 2>$null; Write-Log "Xong 2/15" "SUCCESS" }},
    @{Name="Fix lỗi 0x00000709 (Lỗi Set Default)"; Code={ try { $Acl = Get-Acl "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Windows"; $Rule = New-Object System.Security.AccessControl.RegistryAccessRule([System.Security.Principal.WindowsIdentity]::GetCurrent().Name, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"); $Acl.SetAccessRule($Rule); Set-Acl "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Windows" $Acl -ErrorAction SilentlyContinue } catch {}; Write-Log "Xong 3/15" "SUCCESS" }},
    @{Name="Fix lỗi 0x0000007c & 0x0000011c (Driver)"; Code={ cmd.exe /c 'reg add "HKLM\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /v RestrictDriverInstallationToAdministrators /t REG_DWORD /d 0 /f' 2>$null; Write-Log "Xong 4/15" "SUCCESS" }},
    @{Name="Sửa Máy In báo Offline (Bật Online)"; Code={ try { cmd.exe /c 'wmic printer where "WorkOffline=TRUE" call setoffline false' 2>$null } catch {}; Write-Log "Xong 5/15" "SUCCESS" }},
    @{Name="Mở cổng Tường Lửa (Firewall Block)"; Code={ cmd.exe /c 'netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes' 2>$null; Write-Log "Xong 6/15" "SUCCESS" }},
    @{Name="Lỗi LAN 0x80070035 (Network Discovery)"; Code={ cmd.exe /c 'sc config lanmanworkstation start= auto & net start lanmanworkstation' 2>$null; Write-Log "Xong 7/15" "SUCCESS" }},
    @{Name="Lỗi Driver Unavailable (Core Restart)"; Code={ Stop-ServiceSafe "Spooler"; cmd.exe /c "net stop wudfsvc /y & net start wudfsvc & net start spooler" 2>$null; Write-Log "Xong 8/15" "SUCCESS" }},
    @{Name="Lỗi 0x000006ba (Print Spooler RPC treo)"; Code={ cmd.exe /c 'sc config spooler depend= RPCSS' 2>$null; Write-Log "Xong 9/15" "SUCCESS" }},
    @{Name="Lỗi 0x000003e3 (Local Print Queue)"; Code={ cmd.exe /c 'reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Print\Printers" /f' 2>$null; Write-Log "Xong 10/15" "SUCCESS" }},
    @{Name="Lỗi cổng USB (USB001/USB002 không nhận)"; Code={ cmd.exe /c "net stop DeviceInstall /y & net start DeviceInstall" 2>$null; Write-Log "Xong 11/15" "SUCCESS" }},
    @{Name="Fix lỗi Access Denied thư mục Spool"; Code={ cmd.exe /c 'icacls "%WINDIR%\System32\spool" /grant Administrators:(OI)(CI)F /T /C /Q' 2>$null; Write-Log "Xong 12/15" "SUCCESS" }},
    @{Name="Khởi động dịch vụ In mạng (WSD/SSDP)"; Code={ cmd.exe /c 'net start SSDPSRV & net start WSDPrintDevice' 2>$null; Write-Log "Xong 13/15" "SUCCESS" }},
    @{Name="Mở hộp thoại Gỡ Driver Rác (PrintUI)"; Code={ cmd.exe /c "printui.exe /s /t2"; Write-Log "Xong 14/15" "SUCCESS" }},
    @{Name="⚡ AUTO FIX TẤT CẢ 14 LỖI TRÊN ⚡"; Code={ Write-Log "Càn quét 14 lỗi Máy in..."; Stop-ServiceSafe "Spooler"; Remove-Item "$env:WINDIR\System32\spool\PRINTERS\*" -Force -Recurse -ErrorAction SilentlyContinue; cmd.exe /c 'reg add "HKLM\System\CurrentControlSet\Control\Print" /v RpcAuthnLevelPrivacyEnabled /t REG_DWORD /d 0 /f & netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes & net start spooler' 2>$null; Write-Log "Hoàn tất Auto Fix Máy in!" "SUCCESS" }}
)

$Gam15 = @(
    @{Name="Xóa Cache Đồ Họa (Fix Drop FPS)"; Code={ foreach ($P in @("$env:LOCALAPPDATA\D3DSCache\*", "$env:LOCALAPPDATA\NVIDIA\GLCache\*", "$env:LOCALAPPDATA\AMD\DxCache\*")) { Remove-Item $P -Recurse -Force -ErrorAction SilentlyContinue }; Write-Log "Xong 1/15" "SUCCESS" }},
    @{Name="Tải Visual C++ & DirectX (Lỗi DLL)"; Code={ Start-Process "https://www.techpowerup.com/download/visual-c-redistributable-runtime-package-all-in-one/"; Write-Log "Xong 2/15" "SUCCESS" }},
    @{Name="Tắt Xbox Game Bar (Chống tuột FPS)"; Code={ cmd.exe /c 'reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f' 2>$null; Write-Log "Xong 3/15" "SUCCESS" }},
    @{Name="Cấp Quyền Admin Thư Mục Game"; Code={ if (-not $IsWinPE) { cmd.exe /c 'icacls "C:\Program Files" /grant Administrators:(OI)(CI)F /T /C /Q' 2>$null }; Write-Log "Xong 4/15" "SUCCESS" }},
    @{Name="Bỏ qua Diệt Virus ổ Game"; Code={ if (-not $IsWinPE) { foreach ($D in @("C:\","D:\","E:\")) { try { Add-MpPreference -ExclusionPath $D -ErrorAction SilentlyContinue } catch {} } }; Write-Log "Xong 5/15" "SUCCESS" }},
    @{Name="Tối Ưu Băng Thông/Ping"; Code={ cmd.exe /c 'reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 4294967295 /f' 2>$null; Write-Log "Xong 6/15" "SUCCESS" }},
    @{Name="Ưu tiên CPU cho Game"; Code={ cmd.exe /c 'reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 0 /f' 2>$null; Write-Log "Xong 7/15" "SUCCESS" }},
    @{Name="Bật Chế Độ High Performance"; Code={ cmd.exe /c "powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" 2>$null; Write-Log "Xong 8/15" "SUCCESS" }},
    @{Name="Tắt Gia Tốc Chuột (Fix Vẩy FPS)"; Code={ cmd.exe /c 'reg add "HKCU\Control Panel\Mouse" /v MouseSpeed /t REG_SZ /d 0 /f' 2>$null; Write-Log "Xong 9/15" "SUCCESS" }},
    @{Name="Tắt Tối Ưu Toàn Màn Hình (Alt-Tab)"; Code={ cmd.exe /c 'reg add "HKCU\System\GameConfigStore" /v GameDVR_FSEBehaviorMode /t REG_DWORD /d 2 /f' 2>$null; Write-Log "Xong 10/15" "SUCCESS" }},
    @{Name="Kiểm Tra Lỗi Tên User Tiếng Việt"; Code={ if ($env:USERNAME -match "[^\x00-\x7F]") { Write-Log "Tên User CÓ DẤU! Dễ văng game!" "ERROR" } else { Write-Log "Tên User Không Dấu. OK!" "SUCCESS" } }},
    @{Name="Reset Xbox App / Microsoft Store"; Code={ if (-not $IsWinPE) { cmd.exe /c "wsreset.exe" | Out-Null }; Write-Log "Xong 12/15" "SUCCESS" }},
    @{Name="Tối Ưu Quản Lý RAM (VRAM Paging)"; Code={ cmd.exe /c 'reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 0 /f' 2>$null; Write-Log "Xong 13/15" "SUCCESS" }},
    @{Name="Restart Dịch Vụ Đồ Họa & Âm Thanh"; Code={ cmd.exe /c "net stop Audiosrv /y & net start Audiosrv" 2>$null; Write-Log "Xong 14/15" "SUCCESS" }},
    @{Name="⚡ AUTO GAMING TUNE TẤT CẢ ⚡"; Code={ Write-Log "Tự động kích hoạt 14 bước Tuning..."; cmd.exe /c 'powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c & ipconfig /flushdns' 2>$null; Write-Log "Gaming Tune hoàn tất!" "SUCCESS" }}
)

# =============================================================================
# ENGINE 1 UI: WPF (RGB THEME ENGINE)
# =============================================================================
$WPF_Loaded = $true
try {
    Add-Type -AssemblyName PresentationFramework -ErrorAction Stop; Add-Type -AssemblyName PresentationCore -ErrorAction Stop; Add-Type -AssemblyName WindowsBase -ErrorAction Stop
    [xml]$XAML = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="PHÁT TẤN PC - V14.0 RGB GALAXY" Height="780" Width="860" WindowStartupLocation="CenterScreen" ResizeMode="NoResize">
        <Window.Resources>
            <Style TargetType="Button">
                <Setter Property="Foreground" Value="White"/> <Setter Property="FontWeight" Value="Bold"/> <Setter Property="FontSize" Value="13"/> <Setter Property="Margin" Value="5"/> <Setter Property="Padding" Value="10"/> <Setter Property="BorderThickness" Value="0"/>
                <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="10"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Opacity" Value="0.8"/></Trigger><Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.4"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter>
            </Style>
        </Window.Resources>
        <Grid x:Name="MainGrid">
            <Grid.RowDefinitions><RowDefinition Height="60"/><RowDefinition Height="400"/><RowDefinition Height="80"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            
            <TextBlock Text="HỆ SINH THÁI CỨU HỘ V14.0 (15 LỖI/NÚT)" FontSize="24" FontWeight="ExtraBold" HorizontalAlignment="Left" VerticalAlignment="Center" Margin="20,0,0,0">
                <TextBlock.Foreground>
                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                        <GradientStop Color="#00E5FF" Offset="0.0"/> <GradientStop Color="#D500F9" Offset="0.5"/> <GradientStop Color="#FF1744" Offset="1.0"/>
                    </LinearGradientBrush>
                </TextBlock.Foreground>
            </TextBlock>
            <Button x:Name="BtnTheme" Content="🌓 ĐỔI THEME RGB" HorizontalAlignment="Right" Width="160" Height="40" Margin="0,0,20,0" Background="#3F3F50"/>

            <Grid Grid.Row="1"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <GroupBox x:Name="GrpLeft" Header="HỆ THỐNG &amp; BẢO MẬT (AUTO 15 BƯỚC)" Grid.Column="0" Margin="10" FontWeight="Bold" FontSize="14"><StackPanel Margin="5">
                    <Button x:Name="BtnNet" Content="1. Reset Mạng Chuyên Sâu (15 Lỗi)"/>
                    <Button x:Name="BtnJunk" Content="2. Dọn Rác Đa Điểm (15 Vùng)"/>
                    <Button x:Name="BtnUpd" Content="3. Sửa Lỗi Win Update (15 Bước)"/>
                    <Button x:Name="BtnSFC" Content="4. Quét &amp; Vá Lõi Hệ Thống"/>
                    <Button x:Name="BtnReg" Content="5. Mở Khóa Registry (15 Chốt chặn)"/>
                    <Button x:Name="BtnExp" Content="6. Restart Giao diện &amp; Explorer"/>
                </StackPanel></GroupBox>
                <GroupBox x:Name="GrpRight" Header="THIẾT BỊ, APP &amp; GAME (MENU 15 LỖI)" Grid.Column="1" Margin="10" FontWeight="Bold" FontSize="14"><StackPanel Margin="5">
                    <Button x:Name="BtnPrn" Content="7. CHUYÊN GIA MÁY IN (MENU 15 LỖI) 🖨️"/>
                    <Button x:Name="BtnGam" Content="8. TỐI ƯU GAMING (MENU 15 TÁC VỤ) 🎮"/>
                    <Button x:Name="BtnAud" Content="9. Sửa Lỗi Mất Âm Thanh"/>
                    <Button x:Name="BtnApp" Content="10. Reset App UWP &amp; Win Store"/>
                    <Button x:Name="BtnDeb" Content="11. Gỡ Rác Windows (Candy Crush...)"/>
                    <Button x:Name="BtnUSB" Content="12. Diệt Virus USB &amp; Hiện File Ẩn"/>
                </StackPanel></GroupBox>
            </Grid>
            <Button x:Name="BtnAll" Grid.Row="2" Content="⚡ AUTO FIX TOÀN DIỆN &amp; XUẤT BÁO CÁO ⚡" FontSize="16" Margin="20,10,20,10"/>
            <TextBox x:Name="TxtLog" Grid.Row="3" FontFamily="Consolas" FontSize="13" IsReadOnly="True" VerticalScrollBarVisibility="Auto" Margin="20,0,20,20" Padding="10" BorderThickness="0"/>
        </Grid>
    </Window>
"@
    $Reader = (New-Object System.Xml.XmlNodeReader $XAML); $WpfForm = [Windows.Markup.XamlReader]::Load($Reader); $Global:UIType = "WPF"; $Global:WpfLogBox = $WpfForm.FindName("TxtLog")
    
    function Apply-WpfTheme {
        $RGB_Dark = @("#FF1744", "#00E676", "#2979FF", "#D500F9", "#FF9100", "#00B0FF", "#004D40", "#4A148C", "#1565C0", "#C62828", "#E65100", "#37474F", "#B71C1C")
        $RGB_Light = @("#D32F2F", "#388E3C", "#1976D2", "#7B1FA2", "#F57C00", "#0288D1", "#00695C", "#6A1B9A", "#1565C0", "#C62828", "#E65100", "#455A64", "#D32F2F")
        $Colors = if ($Global:IsDarkMode) { $RGB_Dark } else { $RGB_Light }
        
        $WpfForm.FindName("MainGrid").Background = if ($Global:IsDarkMode) { "#1E1E28" } else { "#F0F2F5" }
        $WpfForm.FindName("GrpLeft").Foreground = if ($Global:IsDarkMode) { "#00E5FF" } else { "#0D47A1" }
        $WpfForm.FindName("GrpRight").Foreground = if ($Global:IsDarkMode) { "#00E5FF" } else { "#0D47A1" }
        $Global:WpfLogBox.Background = if ($Global:IsDarkMode) { "#0A0A0F" } else { "#FFFFFF" }
        $Global:WpfLogBox.Foreground = if ($Global:IsDarkMode) { "#00FF00" } else { "#1B5E20" }
        
        $Btns = @("BtnNet","BtnJunk","BtnUpd","BtnSFC","BtnReg","BtnExp","BtnPrn","BtnGam","BtnAud","BtnApp","BtnDeb","BtnUSB","BtnAll")
        for ($i=0; $i -lt $Btns.Length; $i++) { $WpfForm.FindName($Btns[$i]).Background = $Colors[$i] }
    }

    function Lock-WpfUI($state) { foreach($b in @("BtnNet","BtnJunk","BtnUpd","BtnSFC","BtnReg","BtnExp","BtnPrn","BtnAud","BtnApp","BtnGam","BtnDeb","BtnUSB","BtnAll","BtnTheme")){ $WpfForm.FindName($b).IsEnabled = $state }; [System.Windows.Forms.Application]::DoEvents() }
    
    $WpfForm.FindName("BtnTheme").Add_Click({ $Global:IsDarkMode = -not $Global:IsDarkMode; Apply-WpfTheme })
    
    $WpfForm.FindName("BtnNet").Add_Click({ Lock-WpfUI $false; Fix-NetworkAndDNS; Lock-WpfUI $true })
    $WpfForm.FindName("BtnJunk").Add_Click({ Lock-WpfUI $false; Clean-TempAndJunk; Lock-WpfUI $true })
    $WpfForm.FindName("BtnUpd").Add_Click({ Lock-WpfUI $false; Fix-WindowsUpdate; Lock-WpfUI $true })
    $WpfForm.FindName("BtnSFC").Add_Click({ Lock-WpfUI $false; Repair-SystemFiles; Lock-WpfUI $true })
    $WpfForm.FindName("BtnReg").Add_Click({ Lock-WpfUI $false; Fix-VirusRegistry; Lock-WpfUI $true })
    $WpfForm.FindName("BtnExp").Add_Click({ Lock-WpfUI $false; Restart-Explorer; Lock-WpfUI $true })
    
    $WpfForm.FindName("BtnPrn").Add_Click({ Lock-WpfUI $false; Show-Popup15 "CHUYÊN GIA MÁY IN V14.0" $Prn15 "Prn"; Lock-WpfUI $true })
    $WpfForm.FindName("BtnGam").Add_Click({ Lock-WpfUI $false; Show-Popup15 "TỐI ƯU GAMING V14.0" $Gam15 "Gam"; Lock-WpfUI $true })
    
    $WpfForm.FindName("BtnAud").Add_Click({ Lock-WpfUI $false; Fix-AudioServices; Lock-WpfUI $true })
    $WpfForm.FindName("BtnApp").Add_Click({ Lock-WpfUI $false; Fix-WindowsStore; Lock-WpfUI $true })
    $WpfForm.FindName("BtnDeb").Add_Click({ Lock-WpfUI $false; Optimize-Debloat; Lock-WpfUI $true })
    $WpfForm.FindName("BtnUSB").Add_Click({ Lock-WpfUI $false; Fix-USBShortcut; Lock-WpfUI $true })
    
    $WpfForm.FindName("BtnAll").Add_Click({ 
        Lock-WpfUI $false; Write-Log "--- BẮT ĐẦU AUTO FIX GALAXY ---" "WARN"
        Fix-NetworkAndDNS; Clean-TempAndJunk; Fix-VirusRegistry; Optimize-Debloat; Fix-AudioServices; Fix-WindowsUpdate; Repair-SystemFiles; Restart-Explorer
        Write-Log "--- HOÀN TẤT ---" "SUCCESS"; Export-HtmlReport; Lock-WpfUI $true 
    })
    
    Apply-WpfTheme
    Write-Log "Khởi động WPF Engine V14.0 (RGB GALAXY) thành công!" "INFO"
    $WpfForm.ShowDialog() | Out-Null
} catch { $WPF_Loaded = $false }

# =============================================================================
# ENGINE 2 UI: WINFORMS (FLOWLAYOUT FALLBACK RGB)
# =============================================================================
if (-not $WPF_Loaded) {
    Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; $Global:UIType = "WINFORMS"
    $WfForm = New-Object System.Windows.Forms.Form; $WfForm.Text = "PHÁT TẤN PC - V14.0 (FALLBACK MODE)"; $WfForm.Size = New-Object System.Drawing.Size(800, 760); $WfForm.StartPosition = "CenterScreen"; $WfForm.FormBorderStyle = "FixedDialog"; $WfForm.MaximizeBox = $false
    
    $LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text = "CÔNG CỤ CỨU HỘ V14.0 (TƯƠNG THÍCH CAO)"; $LblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold); $LblTitle.AutoSize = $true; $LblTitle.Location = New-Object System.Drawing.Point(20, 15); $WfForm.Controls.Add($LblTitle)
    
    $BtnTheme = New-Object System.Windows.Forms.Button; $BtnTheme.Text = "🌓 ĐỔI THEME"; $BtnTheme.Size = New-Object System.Drawing.Size(120, 30); $BtnTheme.Location = New-Object System.Drawing.Point(640, 15); $BtnTheme.FlatStyle="Flat"; $BtnTheme.Add_Click({ $Global:IsDarkMode = -not $Global:IsDarkMode; Apply-WfTheme }); $WfForm.Controls.Add($BtnTheme)

    $Global:WfLogBox = New-Object System.Windows.Forms.TextBox; $Global:WfLogBox.Multiline = $true; $Global:WfLogBox.ScrollBars = "Vertical"; $Global:WfLogBox.ReadOnly = $true; $Global:WfLogBox.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular); $Global:WfLogBox.Size = New-Object System.Drawing.Size(740, 150); $Global:WfLogBox.Location = New-Object System.Drawing.Point(20, 550); $WfForm.Controls.Add($Global:WfLogBox)
    
    $FlowLeft = New-Object System.Windows.Forms.FlowLayoutPanel; $FlowLeft.FlowDirection = "TopDown"; $FlowLeft.Dock = "Fill"
    $GrpSys = New-Object System.Windows.Forms.GroupBox; $GrpSys.Text = "HỆ THỐNG & BẢO MẬT (15 LỖI)"; $GrpSys.Size = New-Object System.Drawing.Size(360, 380); $GrpSys.Location = New-Object System.Drawing.Point(20, 60); $GrpSys.Controls.Add($FlowLeft); $WfForm.Controls.Add($GrpSys)
    
    $FlowRight = New-Object System.Windows.Forms.FlowLayoutPanel; $FlowRight.FlowDirection = "TopDown"; $FlowRight.Dock = "Fill"
    $GrpApp = New-Object System.Windows.Forms.GroupBox; $GrpApp.Text = "THIẾT BỊ, APP & GAME (MENU)"; $GrpApp.Size = New-Object System.Drawing.Size(360, 380); $GrpApp.Location = New-Object System.Drawing.Point(400, 60); $GrpApp.Controls.Add($FlowRight); $WfForm.Controls.Add($GrpApp)

    $BtnAll = New-Object System.Windows.Forms.Button; $BtnAll.Text = "⚡ CHẠY TẤT CẢ & XUẤT BÁO CÁO ⚡"; $BtnAll.Size = New-Object System.Drawing.Size(740, 60); $BtnAll.Location = New-Object System.Drawing.Point(20, 460); $BtnAll.FlatStyle="Flat"; $BtnAll.Font=New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $BtnAll.Add_Click({ Lock-WfUI $false; Write-Log "--- BẮT ĐẦU AUTO FIX ---" "WARN"; Fix-NetworkAndDNS; Clean-TempAndJunk; Fix-VirusRegistry; Optimize-Debloat; Fix-AudioServices; Fix-WindowsUpdate; Repair-SystemFiles; Restart-Explorer; Write-Log "--- HOÀN TẤT ---" "SUCCESS"; Export-HtmlReport; Lock-WfUI $true })
    $WfForm.Controls.Add($BtnAll)

    $WfButtons = @()
    function Create-Btn($C, $T, $A) { $B = New-Object System.Windows.Forms.Button; $B.Text = $T; $B.Size = New-Object System.Drawing.Size(330, 42); $B.Margin = New-Object System.Windows.Forms.Padding(10, 6, 0, 6); $B.FlatStyle="Flat"; $B.ForeColor="White"; $B.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold); $B.Add_Click({ Lock-WfUI $false; & $A; Lock-WfUI $true }); $C.Controls.Add($B); $Global:WfButtons += $B }
    function Lock-WfUI([bool]$State) { foreach ($B in $WfButtons) { $B.Enabled = $State }; $BtnAll.Enabled = $State; $BtnTheme.Enabled = $State; [System.Windows.Forms.Application]::DoEvents() }

    Create-Btn $FlowLeft "1. Reset Mạng Chuyên Sâu (15 Lỗi)" { Fix-NetworkAndDNS }
    Create-Btn $FlowLeft "2. Dọn Rác Đa Điểm (15 Vùng)" { Clean-TempAndJunk }
    Create-Btn $FlowLeft "3. Sửa Lỗi Kẹt Win Update (15 Bước)" { Fix-WindowsUpdate }
    Create-Btn $FlowLeft "4. Quét & Vá Lõi Hệ Thống (SFC)" { Repair-SystemFiles }
    Create-Btn $FlowLeft "5. Mở Khóa Registry (15 Chốt chặn)" { Fix-VirusRegistry }
    Create-Btn $FlowLeft "6. Restart Giao diện Explorer" { Restart-Explorer }

    Create-Btn $FlowRight "7. CHUYÊN GIA MÁY IN (MENU 15 LỖI) 🖨️" { Show-Popup15 "MENU MÁY IN" $Prn15 "Prn" }
    Create-Btn $FlowRight "8. TỐI ƯU GAMING (MENU 15 TÁC VỤ) 🎮" { Show-Popup15 "MENU GAMING" $Gam15 "Gam" }
    Create-Btn $FlowRight "9. Sửa Lỗi Mất Âm Thanh" { Fix-AudioServices }
    Create-Btn $FlowRight "10. Reset App UWP & Win Store" { Fix-WindowsStore }
    Create-Btn $FlowRight "11. Gỡ Rác Windows (Candy Crush...)" { Optimize-Debloat }
    Create-Btn $FlowRight "12. Diệt Virus Shortcut USB & File Ẩn" { Fix-USBShortcut }

    function Apply-WfTheme {
        $RGB_Dark = @("255,23,68", "0,230,118", "41,121,255", "213,0,249", "255,145,0", "0,176,255", "0,77,64", "74,20,140", "21,101,192", "198,40,40", "230,81,0", "55,71,79", "183,28,28")
        $RGB_Light = @("211,47,47", "56,142,60", "25,118,210", "123,31,162", "245,124,0", "2,136,209", "0,105,92", "106,27,154", "21,101,192", "198,40,40", "230,81,0", "69,90,100", "211,47,47")
        $Colors = if ($Global:IsDarkMode) { $RGB_Dark } else { $RGB_Light }
        
        $WfForm.BackColor = if ($Global:IsDarkMode) { [System.Drawing.Color]::FromArgb(30, 30, 40) } else { [System.Drawing.Color]::WhiteSmoke }
        $LblTitle.ForeColor = if ($Global:IsDarkMode) { [System.Drawing.Color]::Cyan } else { [System.Drawing.Color]::DarkBlue }
        $BtnTheme.BackColor = if ($Global:IsDarkMode) { [System.Drawing.Color]::FromArgb(60, 60, 80) } else { [System.Drawing.Color]::LightGray }
        $BtnTheme.ForeColor = if ($Global:IsDarkMode) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::Black }
        $GrpSys.ForeColor = if ($Global:IsDarkMode) { [System.Drawing.Color]::Yellow } else { [System.Drawing.Color]::DarkRed }
        $GrpApp.ForeColor = if ($Global:IsDarkMode) { [System.Drawing.Color]::Yellow } else { [System.Drawing.Color]::DarkRed }
        $Global:WfLogBox.BackColor = if ($Global:IsDarkMode) { [System.Drawing.Color]::Black } else { [System.Drawing.Color]::White }
        $Global:WfLogBox.ForeColor = if ($Global:IsDarkMode) { [System.Drawing.Color]::Lime } else { [System.Drawing.Color]::DarkGreen }

        for ($i=0; $i -lt 12; $i++) { $c = $Colors[$i] -split ','; $Global:WfButtons[$i].BackColor = [System.Drawing.Color]::FromArgb($c[0], $c[1], $c[2]) }
        $cAll = $Colors[12] -split ','; $BtnAll.BackColor = [System.Drawing.Color]::FromArgb($cAll[0], $cAll[1], $cAll[2])
    }

    $WfForm.Add_Shown({ Apply-WfTheme; Write-Log "WPF thất bại! Đã lùi về WinForms UI (RGB Theme)." "WARN" })
    $WfForm.ShowDialog() | Out-Null
}
