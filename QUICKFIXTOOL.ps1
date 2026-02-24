# =============================================================================
# PHAT TAN PC - QUICK FIX TOOL V11.0 (ULTIMATE ECOSYSTEM)
# DUAL-UI (WPF/WINFORMS) & 5-TIER LOGIC & HTML REPORT
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
# HỆ THỐNG LÕI & CÁC TÁC VỤ 5-TIER
# =============================================================================

function Get-RemovableDrives {
    try { if (-not ('Win32Native' -as [type])) { Add-Type -TypeDefinition @"
        using System; using System.Runtime.InteropServices; public class Win32Native { [DllImport("kernel32.dll")] public static extern uint GetDriveType(string lpRootPathName); }
"@ -ErrorAction Stop }; return ([System.IO.DriveInfo]::GetDrives() | ? { [Win32Native]::GetDriveType($_.Name) -eq 2 }).Name } catch {}
    try { return (Get-CimInstance Win32_Volume -Filter "DriveType=2" -ErrorAction Stop).DriveLetter } catch {}
    try { return (Get-WmiObject Win32_Volume -Filter "DriveType=2" -ErrorAction Stop).DriveLetter } catch {}
    try { return cmd.exe /c "wmic logicaldisk where drivetype=2 get deviceid" | Select-String -Pattern "[A-Z]:" | ForEach-Object { $_.Matches.Value } } catch { return $null }
}

function Stop-ServiceSafe($SvcName) {
    try { Stop-Service -Name $SvcName -Force -ErrorAction Stop | Out-Null; return $true } catch {}
    try { Invoke-CimMethod -Query "Select * from Win32_Service Where Name='$SvcName'" -MethodName StopService -ErrorAction Stop | Out-Null; return $true } catch {}
    try { cmd.exe /c "net stop $SvcName /y" | Out-Null; return $true } catch { return $false }
}

# 1. MẠNG CHUYÊN Sâu (DEEP RESET)
function Fix-NetworkAndDNS {
    Write-Log "Đang dọn Proxy ẩn, Reset Hosts & Đổi DNS..." "INFO"
    try {
        # Xóa Proxy do Virus gán
        cmd.exe /c 'reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /f' 2>$null
        cmd.exe /c 'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f' 2>$null
        # Set DNS Google
        cmd.exe /c 'netsh interface ipv4 set dns name="Ethernet" static 8.8.8.8 both' 2>$null
        cmd.exe /c 'netsh interface ipv4 set dns name="Wi-Fi" static 8.8.8.8 both' 2>$null
        # Reset IP/Winsock
        cmd.exe /c "netsh winsock reset & netsh int ip reset & ipconfig /flushdns" | Out-Null
        Write-Log "Đã khôi phục mạng chuyên sâu!" "SUCCESS"
    } catch { Write-Log "Lỗi Mạng: $($_.Exception.Message)" "ERROR" }
}

# 2. DỌN RÁC
function Clean-TempAndJunk {
    Write-Log "Đang dọn dẹp hệ thống..." "INFO"
    foreach ($P in @("$env:TEMP\*", "$env:WINDIR\Temp\*", "$env:WINDIR\Prefetch\*")) { try { Remove-Item -Path ($P -replace "\*","") -Recurse -Force -ErrorAction Stop | Out-Null } catch { cmd.exe /c "del /q /f /s `"$($P -replace '\*','')\*`"" 2>$null } }
    Write-Log "Dọn rác hoàn tất!" "SUCCESS"
}

# 3. WINDOWS UPDATE
function Fix-WindowsUpdate {
    Write-Log "Đang sửa kẹt Windows Update..." "INFO"; if ($IsWinPE) { return }
    $Svcs = @("wuauserv", "cryptSvc", "bits", "msiserver"); foreach ($S in $Svcs) { Stop-ServiceSafe $S | Out-Null }
    try { Rename-Item "$env:WINDIR\SoftwareDistribution" "SoftwareDistribution.bak" -Force -ErrorAction Stop | Out-Null } catch { cmd.exe /c 'ren %WINDIR%\SoftwareDistribution SoftwareDistribution.bak' 2>$null }
    foreach ($S in $Svcs) { try { Start-Service $S -ErrorAction SilentlyContinue } catch { cmd.exe /c "net start $S" 2>$null } }
    Write-Log "Sửa lỗi Update hoàn tất!" "SUCCESS"
}

# 4. SFC/DISM
function Repair-SystemFiles {
    Write-Log "Đang chạy SFC & DISM..." "INFO"
    if (-not $IsWinPE) { try { Repair-WindowsImage -Online -RestoreHealth -ErrorAction Stop | Out-Null } catch { cmd.exe /c "DISM /Online /Cleanup-Image /RestoreHealth" | Out-Null } }
    cmd.exe /c "sfc /scannow" | Out-Null; Write-Log "Sửa file hệ thống hoàn tất!" "SUCCESS"
}

# 5. [MỚI] KHÔI PHỤC REGISTRY BỊ KHÓA
function Fix-VirusRegistry {
    Write-Log "Đang mở khóa TaskMgr, Regedit & CMD..." "INFO"
    $Keys = @("HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System", "HKCU\Software\Policies\Microsoft\Windows\System")
    foreach ($K in $Keys) {
        cmd.exe /c "reg delete `"$K`" /v DisableTaskMgr /f" 2>$null
        cmd.exe /c "reg delete `"$K`" /v DisableRegistryTools /f" 2>$null
        cmd.exe /c "reg delete `"$K`" /v DisableCMD /f" 2>$null
    }
    Write-Log "Đã giải cứu Registry thành công!" "SUCCESS"
}

# 6. RESTART EXPLORER
function Restart-Explorer { try { Stop-Process -Name "explorer" -Force -ErrorAction Stop; Start-Sleep 1; Start-Process "explorer.exe"; Write-Log "Restart Explorer!" "SUCCESS" } catch { cmd.exe /c "taskkill /f /im explorer.exe" | Out-Null; Start-Sleep 1; Start-Process "explorer.exe" } }

# 7. FIX MÁY IN PRO
function Fix-PrintSpooler {
    Write-Log "Đang trị lỗi Máy in (0x11b, 0x709)..." "INFO"
    Stop-ServiceSafe "Spooler" | Out-Null
    $P = "$env:WINDIR\System32\spool\PRINTERS\*"; if (Test-Path ($P -replace "\*","")) { Remove-Item -Path $P -Force -Recurse -ErrorAction SilentlyContinue | Out-Null }
    try { Set-ItemProperty "HKLM:\System\CurrentControlSet\Control\Print" "RpcAuthnLevelPrivacyEnabled" 0 -Type DWord -ErrorAction Stop | Out-Null } catch { cmd.exe /c 'reg add "HKLM\System\CurrentControlSet\Control\Print" /v RpcAuthnLevelPrivacyEnabled /t REG_DWORD /d 0 /f' 2>$null }
    try { Start-Service "Spooler" -ErrorAction Stop } catch { cmd.exe /c "net start spooler" 2>$null }
    Write-Log "Đã fix kẹt lệnh in và LAN!" "SUCCESS"
}

# 8. AUDIO
function Fix-AudioServices { Stop-ServiceSafe "Audiosrv" | Out-Null; Stop-ServiceSafe "AudioEndpointBuilder" | Out-Null; Start-Sleep 1; try { Start-Service "AudioEndpointBuilder"; Start-Service "Audiosrv"; Write-Log "Khôi phục âm thanh!" "SUCCESS" } catch { cmd.exe /c "net start AudioEndpointBuilder & net start Audiosrv" 2>$null } }

# 9. WINDOWS STORE
function Fix-WindowsStore { if ($IsWinPE) { return }; try { Get-AppxPackage *windowsstore* | Reset-AppxPackage -ErrorAction Stop | Out-Null; Write-Log "Reset Store!" "SUCCESS" } catch { cmd.exe /c "wsreset.exe" | Out-Null } }

# 10. TỐI ƯU GAME
function Fix-GameErrors { Write-Log "Tối ưu Game..."; try { foreach ($P in @("$env:LOCALAPPDATA\D3DSCache\*", "$env:LOCALAPPDATA\NVIDIA\GLCache\*", "$env:LOCALAPPDATA\AMD\DxCache\*")) { if (Test-Path ($P -replace "\*","")) { Remove-Item -Path $P -Recurse -Force -ErrorAction SilentlyContinue | Out-Null } }; if (-not $IsWinPE) { cmd.exe /c 'icacls "C:\Program Files" /grant Administrators:(OI)(CI)F /T /C /Q' 2>$null }; Write-Log "Tối ưu Game hoàn tất!" "SUCCESS" } catch {} }

# 11. [MỚI] GỠ APP RÁC (DEBLOAT)
function Optimize-Debloat {
    Write-Log "Đang dọn dẹp Bloatware (Candy Crush, TikTok...)..." "INFO"
    if ($IsWinPE) { return }
    $Bloats = @("CandyCrush", "TikTok", "Facebook", "Instagram", "Spotify")
    foreach ($B in $Bloats) { try { Get-AppxPackage "*$B*" | Remove-AppxPackage -ErrorAction SilentlyContinue | Out-Null } catch {} }
    Write-Log "Đã thanh trừng ứng dụng rác!" "SUCCESS"
}

# 12. DIỆT VIRUS USB
function Fix-USBShortcut {
    Write-Log "Bắt đầu chu trình rà quét USB..." "INFO"
    $USBs = Get-RemovableDrives
    if ($USBs) {
        foreach ($L in $USBs) { $L = $L.Replace("\","").Replace(":",""); cmd.exe /c "del /f /q /a:h $L:\*.lnk & attrib -h -r -s /s /d $L:\*.*" 2>$null }
        Write-Log "Hoàn tất khôi phục file ẩn USB!" "SUCCESS"
    } else { Write-Log "Không tìm thấy USB." "WARN" }
}

# [MỚI] XUẤT BÁO CÁO HTML
function Export-HtmlReport {
    Write-Log "Đang tạo báo cáo HTML..." "INFO"
    $HtmlPath = "$PSScriptRoot\PhatTanPC_BaoCao.html"; if ([string]::IsNullOrEmpty($PSScriptRoot)) { $HtmlPath = ".\PhatTanPC_BaoCao.html" }
    $Html = "<html><head><meta charset='utf-8'><title>Báo Cáo Sửa Lỗi - Phát Tấn PC</title><style>body{font-family:Arial; background:#1e1e28; color:#fff; padding:20px;} h1{color:#00e5ff; text-align:center;} .log{background:#000; color:#0f0; padding:15px; border-radius:8px; height:400px; overflow-y:scroll; line-height:1.5;}</style></head><body><h1>⚙️ PHÁT TẤN PC - BÁO CÁO BẢO TRÌ ĐỊNH KỲ ⚙️</h1><div class='log'>"
    try { $Logs = Get-Content $LogFile -ErrorAction Stop; foreach ($L in $Logs) { $Html += "$L<br>" } } catch { $Html += "Không có log." }
    $Html += "</div><h3 style='text-align:center; color:#ffeb3b; margin-top:20px;'>Cảm ơn quý khách đã tin tưởng dịch vụ của Phát Tấn PC!</h3></body></html>"
    $Html | Out-File $HtmlPath -Encoding UTF8; Start-Process $HtmlPath
}

# =============================================================================
# ENGINE 1 UI: WPF (MODERN UI - 12 NÚT)
# =============================================================================
$WPF_Loaded = $true
try {
    Add-Type -AssemblyName PresentationFramework -ErrorAction Stop; Add-Type -AssemblyName PresentationCore -ErrorAction Stop; Add-Type -AssemblyName WindowsBase -ErrorAction Stop
    [xml]$XAML = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="PHÁT TẤN PC - V11.0 ULTIMATE" Height="760" Width="840" Background="#1E1E28" Foreground="White" WindowStartupLocation="CenterScreen" ResizeMode="NoResize">
        <Window.Resources>
            <Style TargetType="Button">
                <Setter Property="Background" Value="#2A2A35"/> <Setter Property="Foreground" Value="White"/> <Setter Property="FontWeight" Value="Bold"/> <Setter Property="FontSize" Value="13"/> <Setter Property="Margin" Value="5"/> <Setter Property="Padding" Value="10"/> <Setter Property="BorderThickness" Value="0"/>
                <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="8"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="#3F3F50"/></Trigger><Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.5"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter>
            </Style>
            <Style TargetType="GroupBox"><Setter Property="Foreground" Value="#00E5FF"/> <Setter Property="FontWeight" Value="Bold"/> <Setter Property="FontSize" Value="14"/> <Setter Property="Margin" Value="10"/> <Setter Property="BorderBrush" Value="#3F3F50"/></Style>
        </Window.Resources>
        <Grid>
            <Grid.RowDefinitions><RowDefinition Height="60"/><RowDefinition Height="370"/><RowDefinition Height="80"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            <TextBlock Text="HỆ SINH THÁI CỨU HỘ MÁY TÍNH CHUYÊN NGHIỆP" Foreground="#00E5FF" FontSize="22" FontWeight="Bold" HorizontalAlignment="Center" VerticalAlignment="Center" />
            <Grid Grid.Row="1"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <GroupBox Header="HỆ THỐNG &amp; BẢO MẬT" Grid.Column="0"><StackPanel Margin="5"><Button x:Name="BtnNet" Content="1. Reset Mạng Chuyên Sâu (Proxy/DNS)"/><Button x:Name="BtnJunk" Content="2. Dọn Rác (Temp, Prefetch)"/><Button x:Name="BtnUpd" Content="3. Sửa Lỗi Kẹt Windows Update"/><Button x:Name="BtnSFC" Content="4. Sửa File Lõi Hệ Thống (SFC/DISM)"/><Button x:Name="BtnReg" Content="5. Khôi Phục Registry (Virus Khóa)"/><Button x:Name="BtnExp" Content="6. Restart Giao diện Explorer"/></StackPanel></GroupBox>
                <GroupBox Header="THIẾT BỊ, APP &amp; GAME" Grid.Column="1"><StackPanel Margin="5"><Button x:Name="BtnPrn" Content="7. Fix Máy In PRO (Mã lỗi &amp; LAN)"/><Button x:Name="BtnAud" Content="8. Sửa Lỗi Mất Âm Thanh"/><Button x:Name="BtnApp" Content="9. Reset App UWP &amp; Win Store"/><Button x:Name="BtnGam" Content="10. Tối Ưu Game (Cache, Quyền)"/><Button x:Name="BtnDeb" Content="11. Gỡ App Rác (Debloat Windows)"/><Button x:Name="BtnUSB" Content="12. Diệt Virus USB &amp; Hiện File Ẩn"/></StackPanel></GroupBox>
            </Grid>
            <Button x:Name="BtnAll" Grid.Row="2" Content="⚡ CHẠY TẤT CẢ &amp; XUẤT BÁO CÁO HTML ⚡" Background="#B71C1C" FontSize="16" Margin="20,10,20,10"/>
            <TextBox x:Name="TxtLog" Grid.Row="3" Background="#000000" Foreground="#00FF00" FontFamily="Consolas" FontSize="12" IsReadOnly="True" VerticalScrollBarVisibility="Auto" Margin="20,0,20,20" Padding="5" BorderThickness="0"/>
        </Grid>
    </Window>
"@
    $Reader = (New-Object System.Xml.XmlNodeReader $XAML); $WpfForm = [Windows.Markup.XamlReader]::Load($Reader); $Global:UIType = "WPF"; $Global:WpfLogBox = $WpfForm.FindName("TxtLog")
    function Lock-WpfUI($state) { foreach($b in @("BtnNet","BtnJunk","BtnUpd","BtnSFC","BtnReg","BtnExp","BtnPrn","BtnAud","BtnApp","BtnGam","BtnDeb","BtnUSB","BtnAll")){ $WpfForm.FindName($b).IsEnabled = $state }; [System.Windows.Forms.Application]::DoEvents() }
    
    $WpfForm.FindName("BtnNet").Add_Click({ Lock-WpfUI $false; Fix-NetworkAndDNS; Lock-WpfUI $true })
    $WpfForm.FindName("BtnJunk").Add_Click({ Lock-WpfUI $false; Clean-TempAndJunk; Lock-WpfUI $true })
    $WpfForm.FindName("BtnUpd").Add_Click({ Lock-WpfUI $false; Fix-WindowsUpdate; Lock-WpfUI $true })
    $WpfForm.FindName("BtnSFC").Add_Click({ Lock-WpfUI $false; Repair-SystemFiles; Lock-WpfUI $true })
    $WpfForm.FindName("BtnReg").Add_Click({ Lock-WpfUI $false; Fix-VirusRegistry; Lock-WpfUI $true })
    $WpfForm.FindName("BtnExp").Add_Click({ Lock-WpfUI $false; Restart-Explorer; Lock-WpfUI $true })
    $WpfForm.FindName("BtnPrn").Add_Click({ Lock-WpfUI $false; Fix-PrintSpooler; Lock-WpfUI $true })
    $WpfForm.FindName("BtnAud").Add_Click({ Lock-WpfUI $false; Fix-AudioServices; Lock-WpfUI $true })
    $WpfForm.FindName("BtnApp").Add_Click({ Lock-WpfUI $false; Fix-WindowsStore; Lock-WpfUI $true })
    $WpfForm.FindName("BtnGam").Add_Click({ Lock-WpfUI $false; Fix-GameErrors; Lock-WpfUI $true })
    $WpfForm.FindName("BtnDeb").Add_Click({ Lock-WpfUI $false; Optimize-Debloat; Lock-WpfUI $true })
    $WpfForm.FindName("BtnUSB").Add_Click({ Lock-WpfUI $false; Fix-USBShortcut; Lock-WpfUI $true })
    
    $WpfForm.FindName("BtnAll").Add_Click({ 
        Lock-WpfUI $false; Write-Log "--- BẮT ĐẦU AUTO FIX (V11 ULTIMATE) ---" "WARN"
        Fix-NetworkAndDNS; Clean-TempAndJunk; Fix-VirusRegistry; Optimize-Debloat; Fix-PrintSpooler; Fix-AudioServices; Fix-WindowsUpdate; Fix-GameErrors; Repair-SystemFiles; Restart-Explorer
        Write-Log "--- HOÀN TẤT ---" "SUCCESS"; Export-HtmlReport; Lock-WpfUI $true 
    })
    Write-Log "Khởi động WPF Engine V11.0 thành công!" "INFO"
    $WpfForm.ShowDialog() | Out-Null
} catch { $WPF_Loaded = $false }

# =============================================================================
# ENGINE 2 UI: WINFORMS (FLOWLAYOUT - 12 NÚT)
# =============================================================================
if (-not $WPF_Loaded) {
    Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; $Global:UIType = "WINFORMS"
    $WfForm = New-Object System.Windows.Forms.Form; $WfForm.Text = "PHÁT TẤN PC - V11.0 (FALLBACK MODE)"; $WfForm.Size = New-Object System.Drawing.Size(760, 740); $WfForm.StartPosition = "CenterScreen"; $WfForm.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 40); $WfForm.ForeColor = "White"; $WfForm.FormBorderStyle = "FixedDialog"; $WfForm.MaximizeBox = $false
    $LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text = "CÔNG CỤ CỨU HỘ (CHẾ ĐỘ TƯƠNG THÍCH)"; $LblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold); $LblTitle.ForeColor = "Cyan"; $LblTitle.AutoSize = $true; $LblTitle.Location = New-Object System.Drawing.Point(120, 15); $WfForm.Controls.Add($LblTitle)
    $Global:WfLogBox = New-Object System.Windows.Forms.TextBox; $Global:WfLogBox.Multiline = $true; $Global:WfLogBox.ScrollBars = "Vertical"; $Global:WfLogBox.ReadOnly = $true; $Global:WfLogBox.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular); $Global:WfLogBox.BackColor = "Black"; $Global:WfLogBox.ForeColor = "Lime"; $Global:WfLogBox.Size = New-Object System.Drawing.Size(700, 150); $Global:WfLogBox.Location = New-Object System.Drawing.Point(20, 530); $WfForm.Controls.Add($Global:WfLogBox)
    
    $FlowLeft = New-Object System.Windows.Forms.FlowLayoutPanel; $FlowLeft.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown; $FlowLeft.Dock = [System.Windows.Forms.DockStyle]::Fill
    $GrpSys = New-Object System.Windows.Forms.GroupBox; $GrpSys.Text = "HỆ THỐNG & BẢO MẬT"; $GrpSys.Size = New-Object System.Drawing.Size(340, 370); $GrpSys.Location = New-Object System.Drawing.Point(20, 60); $GrpSys.ForeColor = "Yellow"; $GrpSys.Controls.Add($FlowLeft); $WfForm.Controls.Add($GrpSys)
    
    $FlowRight = New-Object System.Windows.Forms.FlowLayoutPanel; $FlowRight.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown; $FlowRight.Dock = [System.Windows.Forms.DockStyle]::Fill
    $GrpApp = New-Object System.Windows.Forms.GroupBox; $GrpApp.Text = "THIẾT BỊ, APP & GAME"; $GrpApp.Size = New-Object System.Drawing.Size(340, 370); $GrpApp.Location = New-Object System.Drawing.Point(380, 60); $GrpApp.ForeColor = "Yellow"; $GrpApp.Controls.Add($FlowRight); $WfForm.Controls.Add($GrpApp)

    function Lock-WfUI([bool]$State) { foreach ($C in $WfForm.Controls) { if ($C -is [System.Windows.Forms.Button] -or $C -is [System.Windows.Forms.GroupBox]) { $C.Enabled = $State } }; [System.Windows.Forms.Application]::DoEvents() }
    function Create-Btn($C, $T, $A) { $B = New-Object System.Windows.Forms.Button; $B.Text = $T; $B.Size = New-Object System.Drawing.Size(310, 42); $B.Margin = New-Object System.Windows.Forms.Padding(10, 6, 0, 6); $B.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 60); $B.ForeColor="White"; $B.FlatStyle="Flat"; $B.Add_Click({ Lock-WfUI $false; & $A; Lock-WfUI $true }); $C.Controls.Add($B) }

    Create-Btn $FlowLeft "1. Reset Mạng Chuyên Sâu" { Fix-NetworkAndDNS }; Create-Btn $FlowLeft "2. Dọn Rác (Temp, Prefetch)" { Clean-TempAndJunk }; Create-Btn $FlowLeft "3. Sửa Lỗi Kẹt Windows Update" { Fix-WindowsUpdate }; Create-Btn $FlowLeft "4. Sửa File Lõi Hệ Thống (SFC)" { Repair-SystemFiles }; Create-Btn $FlowLeft "5. Khôi Phục Registry (Virus Khóa)" { Fix-VirusRegistry }; Create-Btn $FlowLeft "6. Restart Giao diện Explorer" { Restart-Explorer }
    Create-Btn $FlowRight "7. Fix Máy In PRO" { Fix-PrintSpooler }; Create-Btn $FlowRight "8. Sửa Lỗi Mất Âm Thanh" { Fix-AudioServices }; Create-Btn $FlowRight "9. Reset App UWP & Win Store" { Fix-WindowsStore }; Create-Btn $FlowRight "10. Tối Ưu Game (Cache, Quyền)" { Fix-GameErrors }; Create-Btn $FlowRight "11. Gỡ App Rác (Debloat Windows)" { Optimize-Debloat }; Create-Btn $FlowRight "12. Diệt Virus Shortcut USB" { Fix-USBShortcut }

    $BtnAll = New-Object System.Windows.Forms.Button; $BtnAll.Text = "⚡ CHẠY TẤT CẢ & XUẤT BÁO CÁO ⚡"; $BtnAll.Size = New-Object System.Drawing.Size(700, 60); $BtnAll.Location = New-Object System.Drawing.Point(20, 450); $BtnAll.BackColor = "DarkRed"; $BtnAll.ForeColor="White"; $BtnAll.FlatStyle="Flat"; $BtnAll.Font=New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $BtnAll.Add_Click({ Lock-WfUI $false; Write-Log "--- BẮT ĐẦU AUTO FIX ---" "WARN"; Fix-NetworkAndDNS; Clean-TempAndJunk; Fix-VirusRegistry; Optimize-Debloat; Fix-PrintSpooler; Fix-AudioServices; Fix-WindowsUpdate; Fix-GameErrors; Repair-SystemFiles; Restart-Explorer; Write-Log "--- HOÀN TẤT ---" "SUCCESS"; Export-HtmlReport; Lock-WfUI $true })
    $WfForm.Controls.Add($BtnAll)

    $WfForm.Add_Shown({ Write-Log "WPF thất bại! Đã lùi về WinForms UI (FlowLayout)." "WARN" })
    $WfForm.ShowDialog() | Out-Null
}
