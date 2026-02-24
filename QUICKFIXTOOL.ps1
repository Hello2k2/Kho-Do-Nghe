# =============================================================================
# PHAT TAN PC - QUICK FIX TOOL V10.1 (DYNAMIC UI & 5-TIER LOGIC TITAN)
# AUTO FALLBACK UI: WPF -> WINFORMS (DÙNG FLOWLAYOUT BỐ CỤC ĐỘNG)
# FAILOVER LOGIC 5 LỚP: WIN32 API (C#) -> CIM -> WMI -> COM/.NET -> CMD
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
# HỆ THỐNG FAILOVER 5 LỚP
# =============================================================================

# HÀM LẤY Ổ USB VỚI 5 LỚP BẢO VỆ
function Get-RemovableDrives {
    # TIER 1: THƯ VIỆN NGOÀI/NATIVE WIN32 API
    try {
        if (-not ('Win32Native' -as [type])) {
            Add-Type -TypeDefinition @"
            using System; using System.Runtime.InteropServices;
            public class Win32Native { [DllImport("kernel32.dll")] public static extern uint GetDriveType(string lpRootPathName); }
"@ -ErrorAction Stop
        }
        $drives = [System.IO.DriveInfo]::GetDrives() | Where-Object { [Win32Native]::GetDriveType($_.Name) -eq 2 }
        Write-Log "[Engine] Dùng giao thức xịn: Win32 API (Kernel32)" "INFO"
        return $drives.Name
    } catch { Write-Log "[Failover] API xịn xịt (thiếu C# Compiler), lùi về CIM..." "WARN" }

    # TIER 2: CIM INSTANCE
    try {
        $drives = Get-CimInstance Win32_Volume -Filter "DriveType=2" -ErrorAction Stop
        Write-Log "[Engine] Dùng giao thức: CIM" "INFO"
        return $drives.DriveLetter
    } catch { Write-Log "[Failover] CIM lỗi, lùi về WMI..." "WARN" }

    # TIER 3: WMI CLASSIC
    try {
        $drives = Get-WmiObject Win32_Volume -Filter "DriveType=2" -ErrorAction Stop
        Write-Log "[Engine] Dùng giao thức: WMI Classic" "INFO"
        return $drives.DriveLetter
    } catch { Write-Log "[Failover] WMI hỏng, lùi về COM Object..." "WARN" }

    # TIER 4: COM / .NET
    try {
        $fso = New-Object -ComObject Scripting.FileSystemObject -ErrorAction Stop
        $res = @(); foreach ($d in $fso.Drives) { if ($d.DriveType -eq 1) { $res += $d.DriveLetter + ":" } }
        Write-Log "[Engine] Dùng giao thức: COM Object (FSO)" "INFO"
        return $res
    } catch { Write-Log "[Failover] COM lỗi, lùi về CMD Parsing..." "WARN" }

    # TIER 5: CMD / CLI (BẤT TỬ)
    try {
        Write-Log "[Engine] Dùng giao thức: WMIC (CMD)" "INFO"
        $out = cmd.exe /c "wmic logicaldisk where drivetype=2 get deviceid"
        return $out | Select-String -Pattern "[A-Z]:" | ForEach-Object { $_.Matches.Value }
    } catch { return $null }
}

# HÀM DỪNG SERVICE 5 LỚP
function Stop-ServiceSafe($SvcName) {
    try { Stop-Service -Name $SvcName -Force -ErrorAction Stop | Out-Null; return $true } catch {} # Tier 1: Core Cmdlet
    try { Invoke-CimMethod -Query "Select * from Win32_Service Where Name='$SvcName'" -MethodName StopService -ErrorAction Stop | Out-Null; return $true } catch {} # Tier 2: CIM
    try { (Get-WmiObject Win32_Service -Filter "Name='$SvcName'").StopService() | Out-Null; return $true } catch {} # Tier 3: WMI
    try { ([System.ServiceProcess.ServiceController]::new($SvcName)).Stop(); return $true } catch {} # Tier 4: .NET
    try { cmd.exe /c "net stop $SvcName /y" | Out-Null; return $true } catch { return $false } # Tier 5: CMD
}

# =============================================================================
# CÁC TÁC VỤ SỬA LỖI ĐÃ TÍCH HỢP 5 LỚP
# =============================================================================

function Fix-NetworkAndDNS {
    Write-Log "Đang làm mới mạng..." "INFO"
    try { Clear-DnsClientCache -ErrorAction Stop | Out-Null; Write-Log "Đã dùng Cmdlet tối ưu DNS!" "SUCCESS" } 
    catch { cmd.exe /c "netsh winsock reset & netsh int ip reset & ipconfig /release & ipconfig /renew & ipconfig /flushdns" | Out-Null; Write-Log "Đã khôi phục mạng bằng CMD!" "SUCCESS" }
}

function Clean-TempAndJunk {
    Write-Log "Đang dọn dẹp hệ thống..." "INFO"
    $Paths = @("$env:TEMP\*", "$env:WINDIR\Temp\*", "$env:WINDIR\Prefetch\*", "$env:WINDIR\SoftwareDistribution\Download\*")
    foreach ($P in $Paths) { try { Remove-Item -Path ($P -replace "\*","") -Recurse -Force -ErrorAction Stop | Out-Null } catch { cmd.exe /c "del /q /f /s `"$($P -replace '\*','')\*`"" | Out-Null } }
    Write-Log "Dọn rác hoàn tất!" "SUCCESS"
}

function Fix-WindowsUpdate {
    Write-Log "Đang sửa lỗi Windows Update..." "INFO"; if ($IsWinPE) { Write-Log "Bỏ qua trên WinPE." "WARN"; return }
    $Svcs = @("wuauserv", "cryptSvc", "bits", "msiserver")
    foreach ($S in $Svcs) { Stop-ServiceSafe $S | Out-Null }
    try { Rename-Item -Path "$env:WINDIR\SoftwareDistribution" -NewName "SoftwareDistribution.bak" -Force -ErrorAction Stop | Out-Null } catch { cmd.exe /c 'ren %WINDIR%\SoftwareDistribution SoftwareDistribution.bak & ren %WINDIR%\System32\catroot2 catroot2.bak' | Out-Null }
    foreach ($S in $Svcs) { try { Start-Service $S -ErrorAction SilentlyContinue } catch { cmd.exe /c "net start $S" } }
    Write-Log "Sửa lỗi Update hoàn tất!" "SUCCESS"
}

function Repair-SystemFiles {
    Write-Log "Đang chạy SFC & DISM..." "INFO"
    if (-not $IsWinPE) { try { Repair-WindowsImage -Online -RestoreHealth -ErrorAction Stop | Out-Null } catch { cmd.exe /c "DISM /Online /Cleanup-Image /RestoreHealth" | Out-Null } }
    cmd.exe /c "sfc /scannow" | Out-Null; Write-Log "Sửa file hệ thống hoàn tất!" "SUCCESS"
}

function Restart-Explorer { try { Stop-Process -Name "explorer" -Force -ErrorAction Stop; Start-Sleep 1; Start-Process "explorer.exe"; Write-Log "Restart Explorer (API)!" "SUCCESS" } catch { cmd.exe /c "taskkill /f /im explorer.exe" | Out-Null; Start-Sleep 1; Start-Process "explorer.exe"; Write-Log "Restart Explorer (CMD)!" "SUCCESS" } }

function Fix-PrintSpooler {
    Write-Log "Đang trị lỗi Máy in (0x11b, 0x709)..." "INFO"
    Stop-ServiceSafe "Spooler" | Out-Null
    $P = "$env:WINDIR\System32\spool\PRINTERS\*"; if (Test-Path ($P -replace "\*","")) { Remove-Item -Path $P -Force -Recurse -ErrorAction SilentlyContinue | Out-Null }
    try { Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Print" -Name "RpcAuthnLevelPrivacyEnabled" -Value 0 -Type DWord -ErrorAction Stop | Out-Null } catch { cmd.exe /c 'reg add "HKLM\System\CurrentControlSet\Control\Print" /v RpcAuthnLevelPrivacyEnabled /t REG_DWORD /d 0 /f' | Out-Null }
    try { Start-Service "Spooler" -ErrorAction Stop } catch { cmd.exe /c "net start spooler" }
    Write-Log "Đã fix kẹt lệnh in và sửa lỗi chia sẻ mạng!" "SUCCESS"
}

function Fix-AudioServices { Stop-ServiceSafe "Audiosrv" | Out-Null; Stop-ServiceSafe "AudioEndpointBuilder" | Out-Null; Start-Sleep 1; try { Start-Service "AudioEndpointBuilder"; Start-Service "Audiosrv"; Write-Log "Khôi phục âm thanh!" "SUCCESS" } catch { cmd.exe /c "net start AudioEndpointBuilder & net start Audiosrv"; Write-Log "Khôi phục âm thanh!" "SUCCESS" } }
function Fix-WindowsStore { if ($IsWinPE) { return }; try { Get-AppxPackage *windowsstore* | Reset-AppxPackage -ErrorAction Stop | Out-Null; Write-Log "Reset Store qua API!" "SUCCESS" } catch { cmd.exe /c "wsreset.exe" | Out-Null; Write-Log "Reset Store qua Wsreset!" "SUCCESS" } }
function Fix-GameErrors { Write-Log "Tối ưu Game..."; try { foreach ($P in @("$env:LOCALAPPDATA\D3DSCache\*", "$env:LOCALAPPDATA\NVIDIA\GLCache\*", "$env:LOCALAPPDATA\AMD\DxCache\*")) { if (Test-Path ($P -replace "\*","")) { Remove-Item -Path $P -Recurse -Force -ErrorAction SilentlyContinue | Out-Null } }; if (-not $IsWinPE) { cmd.exe /c 'icacls "C:\Program Files" /grant Administrators:(OI)(CI)F /T /C /Q' | Out-Null }; cmd.exe /c "ipconfig /flushdns" | Out-Null; Write-Log "Xong!" "SUCCESS" } catch {} }

function Fix-USBShortcut {
    Write-Log "Bắt đầu chu trình rà quét USB..." "INFO"
    $USBs = Get-RemovableDrives
    if ($USBs) {
        foreach ($L in $USBs) {
            $L = $L.Replace("\","").Replace(":","")
            Write-Log "Phát hiện USB tại ổ [$L:]. Đang diệt..." "WARN"
            cmd.exe /c "del /f /q /a:h $L:\*.lnk & attrib -h -r -s /s /d $L:\*.*" | Out-Null
        }
        Write-Log "Hoàn tất khôi phục file ẩn USB!" "SUCCESS"
    } else { Write-Log "Không tìm thấy USB nào cắm vào máy." "WARN" }
}

# =============================================================================
# ENGINE 1 UI: WPF (GIAO DIỆN XỊN - MODERN UI)
# =============================================================================
$WPF_Loaded = $true
try {
    Add-Type -AssemblyName PresentationFramework -ErrorAction Stop; Add-Type -AssemblyName PresentationCore -ErrorAction Stop; Add-Type -AssemblyName WindowsBase -ErrorAction Stop
    [xml]$XAML = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="PHÁT TẤN PC - V10.1 (DYNAMIC UI)" Height="720" Width="800" Background="#1E1E28" Foreground="White" WindowStartupLocation="CenterScreen" ResizeMode="NoResize">
        <Window.Resources>
            <Style TargetType="Button">
                <Setter Property="Background" Value="#2A2A35"/> <Setter Property="Foreground" Value="White"/> <Setter Property="FontWeight" Value="Bold"/> <Setter Property="FontSize" Value="13"/> <Setter Property="Margin" Value="5"/> <Setter Property="Padding" Value="10"/> <Setter Property="BorderThickness" Value="0"/>
                <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="8"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="#3F3F50"/></Trigger><Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.5"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter>
            </Style>
            <Style TargetType="GroupBox"><Setter Property="Foreground" Value="#00E5FF"/> <Setter Property="FontWeight" Value="Bold"/> <Setter Property="FontSize" Value="14"/> <Setter Property="Margin" Value="10"/> <Setter Property="BorderBrush" Value="#3F3F50"/></Style>
        </Window.Resources>
        <Grid>
            <Grid.RowDefinitions><RowDefinition Height="60"/><RowDefinition Height="320"/><RowDefinition Height="80"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            <TextBlock Text="CÔNG CỤ CỨU HỘ LOGIC 5 LỚP ĐA NĂNG" Foreground="#00E5FF" FontSize="22" FontWeight="Bold" HorizontalAlignment="Center" VerticalAlignment="Center" />
            <Grid Grid.Row="1"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <GroupBox Header="HỆ THỐNG &amp; MẠNG" Grid.Column="0"><StackPanel Margin="5"><Button x:Name="BtnNet" Content="1. Reset Mạng &amp; Tối ưu DNS"/><Button x:Name="BtnJunk" Content="2. Dọn Rác (Temp, Prefetch)"/><Button x:Name="BtnUpd" Content="3. Sửa Lỗi Kẹt Windows Update"/><Button x:Name="BtnSFC" Content="4. Sửa File Lõi Hệ Thống (SFC)"/><Button x:Name="BtnExp" Content="5. Restart Giao diện Explorer"/></StackPanel></GroupBox>
                <GroupBox Header="THIẾT BỊ, APP &amp; GAME" Grid.Column="1"><StackPanel Margin="5"><Button x:Name="BtnPrn" Content="6. Fix Máy In PRO (Mã lỗi &amp; LAN)"/><Button x:Name="BtnAud" Content="7. Sửa Lỗi Mất Âm Thanh"/><Button x:Name="BtnApp" Content="8. Reset App UWP &amp; Win Store"/><Button x:Name="BtnGam" Content="9. Sửa lỗi Game (Quyền, Defender)"/><Button x:Name="BtnUSB" Content="10. Diệt Virus Shortcut USB"/></StackPanel></GroupBox>
            </Grid>
            <Button x:Name="BtnAll" Grid.Row="2" Content="⚡ CHẠY TẤT CẢ (AUTO FIX 5 TIER) ⚡" Background="#B71C1C" FontSize="16" Margin="20,10,20,10"/>
            <TextBox x:Name="TxtLog" Grid.Row="3" Background="#000000" Foreground="#00FF00" FontFamily="Consolas" FontSize="12" IsReadOnly="True" VerticalScrollBarVisibility="Auto" Margin="20,0,20,20" Padding="5" BorderThickness="0"/>
        </Grid>
    </Window>
"@
    $Reader = (New-Object System.Xml.XmlNodeReader $XAML); $WpfForm = [Windows.Markup.XamlReader]::Load($Reader); $Global:UIType = "WPF"; $Global:WpfLogBox = $WpfForm.FindName("TxtLog")
    function Lock-WpfUI($state) { foreach($b in @("BtnNet","BtnPrn","BtnJunk","BtnAud","BtnUpd","BtnApp","BtnSFC","BtnGam","BtnExp","BtnUSB","BtnAll")){ $WpfForm.FindName($b).IsEnabled = $state }; [System.Windows.Forms.Application]::DoEvents() }
    $WpfForm.FindName("BtnNet").Add_Click({ Lock-WpfUI $false; Fix-NetworkAndDNS; Lock-WpfUI $true }); $WpfForm.FindName("BtnJunk").Add_Click({ Lock-WpfUI $false; Clean-TempAndJunk; Lock-WpfUI $true }); $WpfForm.FindName("BtnUpd").Add_Click({ Lock-WpfUI $false; Fix-WindowsUpdate; Lock-WpfUI $true }); $WpfForm.FindName("BtnSFC").Add_Click({ Lock-WpfUI $false; Repair-SystemFiles; Lock-WpfUI $true }); $WpfForm.FindName("BtnExp").Add_Click({ Lock-WpfUI $false; Restart-Explorer; Lock-WpfUI $true })
    $WpfForm.FindName("BtnPrn").Add_Click({ Lock-WpfUI $false; Fix-PrintSpooler; Lock-WpfUI $true }); $WpfForm.FindName("BtnAud").Add_Click({ Lock-WpfUI $false; Fix-AudioServices; Lock-WpfUI $true }); $WpfForm.FindName("BtnApp").Add_Click({ Lock-WpfUI $false; Fix-WindowsStore; Lock-WpfUI $true }); $WpfForm.FindName("BtnGam").Add_Click({ Lock-WpfUI $false; Fix-GameErrors; Lock-WpfUI $true }); $WpfForm.FindName("BtnUSB").Add_Click({ Lock-WpfUI $false; Fix-USBShortcut; Lock-WpfUI $true })
    $WpfForm.FindName("BtnAll").Add_Click({ Lock-WpfUI $false; Write-Log "--- BẮT ĐẦU AUTO FIX (5-TIER) ---" "WARN"; Fix-NetworkAndDNS; Clean-TempAndJunk; Fix-PrintSpooler; Fix-AudioServices; Fix-WindowsUpdate; Fix-GameErrors; Repair-SystemFiles; Restart-Explorer; Write-Log "--- HOÀN TẤT ---" "SUCCESS"; [System.Windows.MessageBox]::Show("Đã hoàn tất bảo trì máy tính của Phát Tấn PC!", "Thành công"); Lock-WpfUI $true })
    Write-Log "Khởi động WPF Engine & Logic 5-Tier thành công!" "INFO"
    $WpfForm.ShowDialog() | Out-Null
} catch { $WPF_Loaded = $false }

# =============================================================================
# ENGINE 2 UI: WINFORMS (FLOWLAYOUT BỐ CỤC ĐỘNG)
# =============================================================================
if (-not $WPF_Loaded) {
    Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; $Global:UIType = "WINFORMS"
    
    $WfForm = New-Object System.Windows.Forms.Form
    $WfForm.Text = "PHÁT TẤN PC - V10.1 (FALLBACK MODE)"
    $WfForm.Size = New-Object System.Drawing.Size(760, 680)
    $WfForm.StartPosition = "CenterScreen"
    $WfForm.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 40)
    $WfForm.ForeColor = "White"
    $WfForm.FormBorderStyle = "FixedDialog"
    $WfForm.MaximizeBox = $false

    $LblTitle = New-Object System.Windows.Forms.Label
    $LblTitle.Text = "CÔNG CỤ CỨU HỘ (CHẾ ĐỘ TƯƠNG THÍCH CAO)"
    $LblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $LblTitle.ForeColor = "Cyan"
    $LblTitle.AutoSize = $true
    $LblTitle.Location = New-Object System.Drawing.Point(120, 15)
    $WfForm.Controls.Add($LblTitle)

    $Global:WfLogBox = New-Object System.Windows.Forms.TextBox
    $Global:WfLogBox.Multiline = $true
    $Global:WfLogBox.ScrollBars = "Vertical"
    $Global:WfLogBox.ReadOnly = $true
    $Global:WfLogBox.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular)
    $Global:WfLogBox.BackColor = "Black"
    $Global:WfLogBox.ForeColor = "Lime"
    $Global:WfLogBox.Size = New-Object System.Drawing.Size(700, 150)
    $Global:WfLogBox.Location = New-Object System.Drawing.Point(20, 470)
    $WfForm.Controls.Add($Global:WfLogBox)

    # DÙNG FLOWLAYOUT BÊN TRÁI
    $FlowLeft = New-Object System.Windows.Forms.FlowLayoutPanel
    $FlowLeft.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
    $FlowLeft.Dock = [System.Windows.Forms.DockStyle]::Fill
    
    $GrpSys = New-Object System.Windows.Forms.GroupBox
    $GrpSys.Text = "KHỐI HỆ THỐNG"
    $GrpSys.Size = New-Object System.Drawing.Size(340, 310)
    $GrpSys.Location = New-Object System.Drawing.Point(20, 60)
    $GrpSys.ForeColor = "Yellow"
    $GrpSys.Controls.Add($FlowLeft)
    $WfForm.Controls.Add($GrpSys)

    # DÙNG FLOWLAYOUT BÊN PHẢI
    $FlowRight = New-Object System.Windows.Forms.FlowLayoutPanel
    $FlowRight.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
    $FlowRight.Dock = [System.Windows.Forms.DockStyle]::Fill
    
    $GrpApp = New-Object System.Windows.Forms.GroupBox
    $GrpApp.Text = "KHỐI THIẾT BỊ & GAME"
    $GrpApp.Size = New-Object System.Drawing.Size(340, 310)
    $GrpApp.Location = New-Object System.Drawing.Point(380, 60)
    $GrpApp.ForeColor = "Yellow"
    $GrpApp.Controls.Add($FlowRight)
    $WfForm.Controls.Add($GrpApp)

    function Lock-WfUI([bool]$State) { 
        foreach ($C in $WfForm.Controls) { if ($C -is [System.Windows.Forms.Button] -or $C -is [System.Windows.Forms.GroupBox]) { $C.Enabled = $State } }
        [System.Windows.Forms.Application]::DoEvents() 
    }
    
    # HÀM TẠO NÚT KHÔNG CẦN TỌA ĐỘ Y NỮA
    function Create-Btn($ContainerFlow, $T, $A) { 
        $B = New-Object System.Windows.Forms.Button
        $B.Text = $T
        $B.Size = New-Object System.Drawing.Size(310, 45)
        $B.Margin = New-Object System.Windows.Forms.Padding(10, 8, 0, 8) # Đẩy lề tự động
        $B.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 60)
        $B.ForeColor = "White"
        $B.FlatStyle = "Flat"
        $B.Add_Click({ Lock-WfUI $false; & $A; Lock-WfUI $true })
        $ContainerFlow.Controls.Add($B) # Tự động ném vào luồng
    }

    # THÊM NÚT CỰC KỲ GỌN GÀNG VÀ CHUYÊN NGHIỆP
    Create-Btn $FlowLeft "1. Reset Mạng" { Fix-NetworkAndDNS }
    Create-Btn $FlowLeft "2. Dọn Rác" { Clean-TempAndJunk }
    Create-Btn $FlowLeft "3. Fix Win Update" { Fix-WindowsUpdate }
    Create-Btn $FlowLeft "4. SFC/DISM" { Repair-SystemFiles }
    Create-Btn $FlowLeft "5. Restart Explorer" { Restart-Explorer }

    Create-Btn $FlowRight "6. Fix Máy In PRO" { Fix-PrintSpooler }
    Create-Btn $FlowRight "7. Fix Âm Thanh" { Fix-AudioServices }
    Create-Btn $FlowRight "8. Reset Win Store" { Fix-WindowsStore }
    Create-Btn $FlowRight "9. Tối ưu Game" { Fix-GameErrors }
    Create-Btn $FlowRight "10. Diệt Virus USB" { Fix-USBShortcut }

    $BtnAll = New-Object System.Windows.Forms.Button
    $BtnAll.Text = "⚡ CHẠY TẤT CẢ ⚡"
    $BtnAll.Size = New-Object System.Drawing.Size(700, 60)
    $BtnAll.Location = New-Object System.Drawing.Point(20, 390)
    $BtnAll.BackColor = "DarkRed"
    $BtnAll.ForeColor = "White"
    $BtnAll.FlatStyle = "Flat"
    $BtnAll.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $BtnAll.Add_Click({ 
        Lock-WfUI $false; Write-Log "--- BẮT ĐẦU AUTO FIX ---" "WARN"
        Fix-NetworkAndDNS; Clean-TempAndJunk; Fix-PrintSpooler; Fix-AudioServices; Fix-WindowsUpdate; Fix-GameErrors; Repair-SystemFiles; Restart-Explorer
        Write-Log "--- HOÀN TẤT ---" "SUCCESS"; [System.Windows.Forms.MessageBox]::Show("Đã xong!")
        Lock-WfUI $true 
    })
    $WfForm.Controls.Add($BtnAll)

    $WfForm.Add_Shown({ Write-Log "WPF thất bại! Đã lùi về WinForms UI (FlowLayout). Logic 5-Tier vẫn chạy ngầm!" "WARN" })
    $WfForm.ShowDialog() | Out-Null
}
