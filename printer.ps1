# ==============================================================================
# Phát Tấn PC - Advanced Printer & Network Tool V5 (FINAL HYBRID)
# - Đầy đủ tính năng Thợ: Ép Private, Hiện LAN, Bật Icon, Clear Update/Temp...
# ==============================================================================

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$global:HasWPF = $false
try {
    Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
    Add-Type -AssemblyName PresentationCore -ErrorAction Stop
    Add-Type -AssemblyName WindowsBase -ErrorAction Stop
    $global:HasWPF = $true
} catch { $global:HasWPF = $false }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$global:CurrentUIMode = if ($global:HasWPF) { "WPF" } else { "WinForms" }
$global:LogControl = $null

# ==============================================================================
# ENGINE: XỬ LÝ LOGIC
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

function Get-SysInfo {
    Write-Log "--- ĐANG LẤY THÔNG TIN HỆ THỐNG ---" "Yellow"
    Write-Log "🖥️ Tên máy: $env:COMPUTERNAME" "Cyan"
    try {
        $ipObj = (ipconfig | Select-String "IPv4").Line
        if ($ipObj) { Write-Log "🌐 IP LAN: $(($ipObj -split ": ")[-1].Trim())" "Cyan" }
    } catch {}
}

# ==============================================================================
# DANH SÁCH TÍNH NĂNG (ACTIONS)
# ==============================================================================

$Action_RestartExplorer = {
    Write-Log "--- Restarting Explorer.exe ---" "White"
    if (Get-Process -Name explorer -ErrorAction SilentlyContinue) {
        Stop-Process -Name explorer -Force; Start-Process explorer
    } else { Write-Log "Không tìm thấy tiến trình Explorer." "Yellow" }
}

$Action_CleanSpooler = {
    Write-Log "--- Đang dọn dẹp & Restart Spooler ---" "White"
    Run-CmdAndLog "net stop spooler /y"
    Run-CmdAndLog "del /Q /F /S %systemroot%\System32\Spool\Printers\*.*"
    Run-CmdAndLog "net start spooler"
    Write-Log "Hoàn tất Spooler." "LimeGreen"
}

# --- CÁC TÍNH NĂNG MỚI ĐƯỢC YÊU CẦU & BỔ SUNG ---

$Action_ForcePrivate = {
    Write-Log "--- Ép Card Mạng Chuyển Sang Private ---" "White"
    try {
        Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private -ErrorAction Stop
        Write-Log "✅ Đã ép mạng thành Private bằng PowerShell." "LimeGreen"
    } catch {
        Write-Log "Module lỗi (WinPE/Lite), dùng Registry Fallback..." "Yellow"
        $profPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles"
        if (Test-Path $profPath) {
            Get-ChildItem $profPath | ForEach-Object { Set-ItemProperty -Path $_.PSPath -Name "Category" -Value 1 -ErrorAction SilentlyContinue }
            Write-Log "✅ Đã set Category=1 (Private) trong Registry. Restart máy để nhận diện." "LimeGreen"
        }
    }
}

$Action_FixLANVisibility = {
    Write-Log "--- Sửa Lỗi Không Thấy Máy LAN (Network Discovery) ---" "White"
    $svcs = "fdPHost", "FDResPub", "lmhosts", "upnphost"
    foreach ($s in $svcs) {
        Run-CmdAndLog "sc config $s start= auto"
        Run-CmdAndLog "net start $s"
    }
    Write-Log "✅ Đã bật các dịch vụ cốt lõi. Bấm F5 trong mục Network sẽ thấy máy!" "LimeGreen"
}

$Action_ShowDesktopIcons = {
    Write-Log "--- Lôi Icon (This PC, Net, CPanel) ra Desktop ---" "White"
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
    Set-RegSafe $regPath "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" 0 # This PC
    Set-RegSafe $regPath "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" 0 # Network
    Set-RegSafe $regPath "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" 0 # Control Panel
    Set-RegSafe $regPath "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" 0 # User Folder
    & $Action_RestartExplorer
    Write-Log "✅ Đã lôi Icon ra màn hình chính." "LimeGreen"
}

$Action_ClearWUCache = {
    Write-Log "--- Gỡ Kẹt Windows Update (Clear Cache) ---" "White"
    Run-CmdAndLog "net stop wuauserv /y"
    Run-CmdAndLog "net stop bits /y"
    Run-CmdAndLog "del /Q /F /S %systemroot%\SoftwareDistribution\*"
    Run-CmdAndLog "net start wuauserv"
    Write-Log "✅ Đã xóa sạch thư mục SoftwareDistribution. Quạt hết rú." "LimeGreen"
}

$Action_ClearTemp = {
    Write-Log "--- Dọn Rác Hệ Thống (Temp, Prefetch) ---" "White"
    Run-CmdAndLog "del /Q /F /S %TEMP%\*"
    Run-CmdAndLog "del /Q /F /S %systemroot%\Temp\*"
    Run-CmdAndLog "del /Q /F /S %systemroot%\Prefetch\*"
    Write-Log "✅ Đã dọn rác giúp máy mượt hơn." "LimeGreen"
}

$Action_DisableSleep = {
    Write-Log "--- Tắt Ngủ Đông (Dành Cho Máy Chủ) ---" "White"
    Run-CmdAndLog "powercfg -h off"
    Run-CmdAndLog "powercfg -change -standby-timeout-ac 0"
    Run-CmdAndLog "powercfg -change -standby-timeout-dc 0"
    Write-Log "✅ Đã cấu hình máy luôn thức (Không tự Sleep)." "LimeGreen"
}

$Action_FixPrintToPDF = {
    Write-Log "--- Khôi Phục Tính Năng Print to PDF ---" "White"
    try {
        Enable-WindowsOptionalFeature -Online -FeatureName "Printing-PrintToPDFServices-Features" -All -NoRestart -ErrorAction Stop
    } catch {
        Run-CmdAndLog "dism /Online /Enable-Feature /FeatureName:`"Printing-PrintToPDFServices-Features`" /NoRestart"
    }
    Write-Log "✅ Cài lại Print to PDF thành công." "LimeGreen"
}

# --- CÁC TÍNH NĂNG CŨ ĐƯỢC GIỮ NGUYÊN ---
$Action_ShowErrorMenu = {
    $MForm = New-Object System.Windows.Forms.Form; $MForm.Text = "Menu Sửa Mã Lỗi Chuyên Sâu"
    $MForm.Size = New-Object System.Drawing.Size(340, 520); $MForm.StartPosition = "CenterParent"
    $MForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2D2D30"); $MForm.FormBorderStyle = "FixedToolWindow"
    $pnl = New-Object System.Windows.Forms.FlowLayoutPanel; $pnl.Dock = "Fill"; $pnl.FlowDirection = "TopDown"; $pnl.Padding = New-Object System.Windows.Forms.Padding(10)

    function Add-Label($txt) {
        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $txt; $lbl.AutoSize = $true
        $lbl.ForeColor = [System.Drawing.Color]::Gold; $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $lbl.Margin = New-Object System.Windows.Forms.Padding(0,10,0,5); $pnl.Controls.Add($lbl)
    }

    function Add-MBtn($txt, $colHex, [scriptblock]$act) {
        $b = New-Object System.Windows.Forms.Button; $b.Text = $txt; $b.Size = New-Object System.Drawing.Size(300, 35)
        $b.FlatStyle = "Flat"; $b.ForeColor = [System.Drawing.Color]::White; $b.BackColor = [System.Drawing.ColorTranslator]::FromHtml($colHex)
        $b.Cursor = [System.Windows.Forms.Cursors]::Hand; $b.Margin = New-Object System.Windows.Forms.Padding(0,0,0,8)
        $handler = { & $act; $MForm.Close() }.GetNewClosure(); $b.Add_Click($handler); $pnl.Controls.Add($b)
    }

    Add-Label "💻 MÁY CHỦ CẮM USB (SERVER)"
    Add-MBtn "1. Lỗi 11B, 0709, 07c (Máy trạm không vô được)" "#8A2BE2" {
        $PReg = "HKLM:\System\CurrentControlSet\Control\Print"
        Set-RegSafe $PReg "RpcAuthnLevelPrivacyEnabled" 0
        Set-RegSafe $PReg "RpcConnectionUpdates" 0
        & $Action_CleanSpooler
    }
    Add-MBtn "2. Lỗi 6D9, BCB (Tường lửa chặn Share)" "#D2691E" {
        Run-CmdAndLog "sc config mpssvc start= auto"; Run-CmdAndLog "net start mpssvc"
        Run-CmdAndLog "netsh advfirewall firewall set rule group=`"File and Printer Sharing`" new enable=Yes"
    }
    Add-MBtn "3. Lỗi 002 (Kẹt Driver cũ, không cài được)" "#C71585" { Run-CmdAndLog "printmanagement.msc" }

    Add-Label "🖥️ MÁY TRẠM KẾT NỐI (CLIENT)"
    Add-MBtn "4. Lỗi BC4, 4005 (A Policy Is In Effect)" "#B22222" {
        $PnReg = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
        Set-RegSafe $PnReg "RestrictDriverInstallationToAdministrators" 0; Set-RegSafe $PnReg "InForest" 0
        Set-RegSafe $PnReg "Restricted" 0; Set-RegSafe $PnReg "TrustedServers" 0; & $Action_CleanSpooler
    }
    Add-MBtn "5. Truy cập máy chủ bị đòi Password / Access Denied" "#20B2AA" {
        Set-RegSafe "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" "AllowInsecureGuestAuth" 1
        cmd.exe /c "cmdkey /list | findstr Target > %temp%\creds.txt"
        $creds = Get-Content "$env:temp\creds.txt" -ErrorAction SilentlyContinue
        if ($creds) { foreach ($c in $creds) { Run-CmdAndLog "cmdkey /delete:$(($c -split 'Target: ')[1])" } }
    }
    Add-MBtn "6. Lỗi 'Another computer is using...' / Bận ảo" "#556B2F" {
        $PrintersPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers"
        if (Test-Path $PrintersPath) {
            Get-ChildItem $PrintersPath | ForEach-Object { Set-ItemProperty -Path $_.PSPath -Name "BidiEnabled" -Value 0 -ErrorAction SilentlyContinue }
            & $Action_CleanSpooler
        }
    }
    Add-MBtn "7. Lỗi 3E3 (Add qua IP thay vì bấm thẳng)" "#4682B4" { try { Run-CmdAndLog "control printers" } catch {} }

    $MForm.Controls.Add($pnl); $MForm.ShowDialog() | Out-Null
}

$Action_AutoShareDrive = {
    Write-Log "--- Bật Auto Share các ổ đĩa ---" "White"
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -match "^[DEF]" }
    if ($drives) { foreach ($d in $drives) { Run-CmdAndLog "net share $($d.Name)Drive=$($d.Root) /GRANT:Everyone,FULL" } }
}
$Action_CleanInk = { try { Run-CmdAndLog "control printers" } catch {}; Run-CmdAndLog "rundll32 printui.dll,PrintUIEntry /p /n `"$((Get-CimInstance Win32_Printer | Select-Object -First 1).Name)`"" }
$Action_DefaultShare = {
    try {
        $printers = Get-CimInstance Win32_Printer
        foreach ($p in $printers) { Run-CmdAndLog "rundll32 printui.dll,PrintUIEntry /y /n `"$($p.Name)`""; $p | Set-CimInstance -Property @{Shared=$true; Published=$true} -ErrorAction SilentlyContinue }
    } catch { Run-CmdAndLog "net share Printer=LPT1 /users:10" }
}
$Action_CheckPort445 = {
    try { $tcp = New-Object System.Net.Sockets.TcpClient; $tcp.Connect("127.0.0.1", 445); Write-Log "✅ Port 445 đang MỞ." "LimeGreen"; $tcp.Close()
    } catch { Write-Log "❌ Port 445 ĐÓNG hoặc bị Firewall chặn!" "Red" }
}

# ==============================================================================
# GIAO DIỆN CHÍNH (TỰ ĐỘNG CÂN BẰNG NÚT BẤM)
# ==============================================================================

function Start-App {
    if ($global:CurrentUIMode -eq "WPF" -and $global:HasWPF) {
        [xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="Phát Tấn PC - Tool Setup &amp; Fix Network V5" Height="850" Width="1050" Background="#1E1E1E" WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="Width" Value="220"/>
            <Setter Property="Height" Value="40"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
    </Window.Resources>
    <Grid Margin="10">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>

        <GroupBox Header="🖨️ XỬ LÝ MÁY IN &amp; LỖI" Grid.Row="0" Foreground="#4DA6FF" BorderBrush="#333333" Margin="0,0,0,10" Padding="5">
            <WrapPanel>
                <Button Name="btnFixSpooler" Content="1. Restart Spooler" Background="#FF3399"/>
                <Button Name="btnFixErrors" Content="2. 📌 Menu Sửa Mã Lỗi" Background="#8A2BE2" FontWeight="Bold"/>
                <Button Name="btnCleanInk" Content="3. Mở Cài Đặt Mực" Background="#C71585"/>
                <Button Name="btnSetDef" Content="4. Share/Set Default" Background="#FF8C00"/>
                <Button Name="btnFixPDF" Content="5. Khôi Phục Print To PDF" Background="#A0522D"/>
            </WrapPanel>
        </GroupBox>

        <GroupBox Header="🌐 MẠNG &amp; CHIA SẺ (SÁT THỦ)" Grid.Row="1" Foreground="#00FA9A" BorderBrush="#333333" Margin="0,0,0,10" Padding="5">
            <WrapPanel>
                <Button Name="btnForcePrivate" Content="1. Ép Mạng Sang Private" Background="#2E8B57" FontWeight="Bold"/>
                <Button Name="btnFixLAN" Content="2. Bật Hiện Máy Tính LAN" Background="#008B8B" FontWeight="Bold"/>
                <Button Name="btnShareDrive" Content="3. Auto Share D, E, F" Background="#20B2AA"/>
                <Button Name="btnCheck445" Content="4. Check Port SMB (445)" Background="#D2691E"/>
                <Button Name="btnResetNet" Content="5. Deep Reset IP/DNS" Background="#4682B4"/>
            </WrapPanel>
        </GroupBox>

        <GroupBox Header="🛠️ TIỆN ÍCH HỆ THỐNG &amp; THỢ" Grid.Row="2" Foreground="#FF69B4" BorderBrush="#333333" Margin="0,0,0,10" Padding="5">
            <WrapPanel>
                <Button Name="btnShowDesktop" Content="1. Hiện Icon Desktop" Background="#BA55D3"/>
                <Button Name="btnClearWU" Content="2. Gỡ Kẹt Win Update" Background="#CD5C5C"/>
                <Button Name="btnClearTemp" Content="3. Dọn Rác (Temp, Prefetch)" Background="#8B0000"/>
                <Button Name="btnNoSleep" Content="4. Tắt Ngủ Đông (Host)" Background="#DAA520"/>
                <Button Name="btnRestartExp" Content="5. Restart Explorer.exe" Background="#696969"/>
                <Button Name="btnSwitch" Content="🔄 Về WinForms Mode" Background="#444444"/>
            </WrapPanel>
        </GroupBox>

        <GroupBox Header="📋 NHẬT KÝ HỆ THỐNG" Grid.Row="3" Foreground="#FFB900" BorderBrush="#333333" Padding="5">
            <TextBox Name="txtLog" Background="#2D2D30" Foreground="#00FF00" FontFamily="Consolas" FontSize="13" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"/>
        </GroupBox>
    </Grid>
</Window>
"@
        $reader = (New-Object System.Xml.XmlNodeReader $xaml)
        $global:MainForm = [System.Windows.Markup.XamlReader]::Load($reader)
        $global:LogControl = $global:MainForm.FindName("txtLog")

        $global:MainForm.FindName("btnFixSpooler").Add_Click($Action_CleanSpooler)
        $global:MainForm.FindName("btnFixErrors").Add_Click($Action_ShowErrorMenu)
        $global:MainForm.FindName("btnCleanInk").Add_Click($Action_CleanInk)
        $global:MainForm.FindName("btnSetDef").Add_Click($Action_DefaultShare)
        $global:MainForm.FindName("btnFixPDF").Add_Click($Action_FixPrintToPDF)
        
        $global:MainForm.FindName("btnForcePrivate").Add_Click($Action_ForcePrivate)
        $global:MainForm.FindName("btnFixLAN").Add_Click($Action_FixLANVisibility)
        $global:MainForm.FindName("btnShareDrive").Add_Click($Action_AutoShareDrive)
        $global:MainForm.FindName("btnCheck445").Add_Click($Action_CheckPort445)
        $global:MainForm.FindName("btnResetNet").Add_Click({ Run-CmdAndLog "ipconfig /release & ipconfig /flushdns & netsh winsock reset" })

        $global:MainForm.FindName("btnShowDesktop").Add_Click($Action_ShowDesktopIcons)
        $global:MainForm.FindName("btnClearWU").Add_Click($Action_ClearWUCache)
        $global:MainForm.FindName("btnClearTemp").Add_Click($Action_ClearTemp)
        $global:MainForm.FindName("btnNoSleep").Add_Click($Action_DisableSleep)
        $global:MainForm.FindName("btnRestartExp").Add_Click($Action_RestartExplorer)
        $global:MainForm.FindName("btnSwitch").Add_Click({ $global:CurrentUIMode = "WinForms"; $global:MainForm.Close(); Start-App })

        $global:MainForm.Add_Loaded({ Get-SysInfo })
        $global:MainForm.ShowDialog() | Out-Null

    } else {
        $global:MainForm = New-Object System.Windows.Forms.Form
        $global:MainForm.Text = "Phát Tấn PC - WinForms V5"
        $global:MainForm.Size = New-Object System.Drawing.Size(1050, 850)
        $global:MainForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1E")
        $global:MainForm.StartPosition = "CenterScreen"

        $layout = New-Object System.Windows.Forms.TableLayoutPanel
        $layout.Dock = "Fill"; $layout.ColumnCount = 1; $layout.RowCount = 4
        $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize)))
        $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize)))
        $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize)))
        $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100)))
        $global:MainForm.Controls.Add($layout)

        function CreateWrapGroup($title, $colHex) {
            $gb = New-Object System.Windows.Forms.GroupBox; $gb.Text = $title; $gb.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($colHex)
            $gb.Dock = "Fill"; $gb.AutoSize = $true; $gb.Padding = New-Object System.Windows.Forms.Padding(10)
            $gb.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $wp = New-Object System.Windows.Forms.FlowLayoutPanel; $wp.Dock = "Fill"; $wp.AutoSize = $true; $wp.WrapContents = $true; $gb.Controls.Add($wp)
            return $gb, $wp
        }

        function AddBtn($wp, $txt, $act, $bg) {
            $b = New-Object System.Windows.Forms.Button; $b.Text = $txt; $b.Size = New-Object System.Drawing.Size(220, 40)
            $b.FlatStyle = "Flat"; $b.ForeColor = [System.Drawing.Color]::White; $b.BackColor = [System.Drawing.ColorTranslator]::FromHtml($bg)
            $b.Cursor = [System.Windows.Forms.Cursors]::Hand; $b.Margin = New-Object System.Windows.Forms.Padding(5)
            $b.Font = New-Object System.Drawing.Font("Segoe UI", 9); $b.Add_Click($act); $wp.Controls.Add($b)
        }

        $gb1, $wp1 = CreateWrapGroup "🖨️ XỬ LÝ MÁY IN & LỖI" "#4DA6FF"
        AddBtn $wp1 "1. Restart Spooler" $Action_CleanSpooler "#FF3399"
        AddBtn $wp1 "2. 📌 Menu Sửa Mã Lỗi" $Action_ShowErrorMenu "#8A2BE2"
        AddBtn $wp1 "3. Mở Cài Đặt Mực" $Action_CleanInk "#C71585"
        AddBtn $wp1 "4. Share/Set Default" $Action_DefaultShare "#FF8C00"
        AddBtn $wp1 "5. Khôi Phục Print To PDF" $Action_FixPrintToPDF "#A0522D"
        $layout.Controls.Add($gb1, 0, 0)

        $gb2, $wp2 = CreateWrapGroup "🌐 MẠNG & CHIA SẺ (SÁT THỦ)" "#00FA9A"
        AddBtn $wp2 "1. Ép Mạng Sang Private" $Action_ForcePrivate "#2E8B57"
        AddBtn $wp2 "2. Bật Hiện Máy Tính LAN" $Action_FixLANVisibility "#008B8B"
        AddBtn $wp2 "3. Auto Share D, E, F" $Action_AutoShareDrive "#20B2AA"
        AddBtn $wp2 "4. Check Port SMB (445)" $Action_CheckPort445 "#D2691E"
        AddBtn $wp2 "5. Deep Reset IP/DNS" { Run-CmdAndLog "ipconfig /release & ipconfig /flushdns & netsh winsock reset" } "#4682B4"
        $layout.Controls.Add($gb2, 0, 1)

        $gb3, $wp3 = CreateWrapGroup "🛠️ TIỆN ÍCH HỆ THỐNG & THỢ" "#FF69B4"
        AddBtn $wp3 "1. Hiện Icon Desktop" $Action_ShowDesktopIcons "#BA55D3"
        AddBtn $wp3 "2. Gỡ Kẹt Win Update" $Action_ClearWUCache "#CD5C5C"
        AddBtn $wp3 "3. Dọn Rác (Temp, Prefetch)" $Action_ClearTemp "#8B0000"
        AddBtn $wp3 "4. Tắt Ngủ Đông (Host)" $Action_DisableSleep "#DAA520"
        AddBtn $wp3 "5. Restart Explorer.exe" $Action_RestartExplorer "#696969"
        
        $btnSW = New-Object System.Windows.Forms.Button; $btnSW.Text = "🔄 Sang WPF Mode"; $btnSW.Size = New-Object System.Drawing.Size(220, 40)
        $btnSW.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#444444"); $btnSW.ForeColor = [System.Drawing.Color]::White; $btnSW.FlatStyle = "Flat"; $btnSW.Margin = New-Object System.Windows.Forms.Padding(5)
        $btnSW.Add_Click({
            if (-not $global:HasWPF) { [System.Windows.Forms.MessageBox]::Show("Máy không có WPF!", "Lỗi", 0, 16) }
            else { $global:CurrentUIMode = "WPF"; $global:MainForm.Close(); Start-App }
        }); $wp3.Controls.Add($btnSW)
        $layout.Controls.Add($gb3, 0, 2)

        $gb4 = New-Object System.Windows.Forms.GroupBox; $gb4.Dock = "Fill"; $gb4.Text = "📋 NHẬT KÝ HỆ THỐNG"; $gb4.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFB900")
        $txtLog = New-Object System.Windows.Forms.RichTextBox; $txtLog.Dock="Fill"; $txtLog.BackColor=[System.Drawing.ColorTranslator]::FromHtml("#2D2D30"); $txtLog.Font=New-Object System.Drawing.Font("Consolas", 10)
        $global:LogControl = $txtLog; $gb4.Controls.Add($txtLog)
        $layout.Controls.Add($gb4, 0, 3)

        $global:MainForm.Add_Shown({ Get-SysInfo })
        $global:MainForm.ShowDialog() | Out-Null
    }
}

if (-not $isAdmin) { Write-Host "CẢNH BÁO: CHƯA CHẠY QUYỀN ADMIN!" -ForegroundColor Red }
Start-App
