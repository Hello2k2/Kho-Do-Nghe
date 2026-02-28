# ==============================================================================
# Phát Tấn PC - Advanced Printer & Network Tool V4 (HORIZONTAL HYBRID)
# - Layout Ngang (WrapPanel)
# - Thêm: Check SMB 445, Restart Explorer, Toggle Firewall, Get SysInfo, Tắt IPv6
# ==============================================================================

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# 1. KIỂM TRA HỖ TRỢ WPF
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

function Get-SysInfo {
    Write-Log "--- ĐANG LẤY THÔNG TIN HỆ THỐNG ---" "Yellow"
    $pcName = $env:COMPUTERNAME
    $ip = "Không rõ"
    try {
        # Fallback cho WinPE (thường cắt module NetTCPIP)
        $ipObj = (ipconfig | Select-String "IPv4").Line
        if ($ipObj) { $ip = ($ipObj -split ": ")[-1].Trim() }
    } catch {}
    Write-Log "🖥️ Tên máy (Hostname): $pcName" "Cyan"
    Write-Log "🌐 IP LAN (IPv4): $ip" "Cyan"
}

# ==============================================================================
# ACTIONS TÍNH NĂNG CHÍNH
# ==============================================================================

$Action_CleanSpooler = {
    Write-Log "--- Đang dọn dẹp & Restart Spooler ---" "White"
    Run-CmdAndLog "net stop spooler /y"
    Run-CmdAndLog "del /Q /F /S %systemroot%\System32\Spool\Printers\*.*"
    Run-CmdAndLog "net start spooler"
    Write-Log "Hoàn tất Spooler." "LimeGreen"
}

$Action_ShowErrorMenu = {
    $MForm = New-Object System.Windows.Forms.Form
    $MForm.Text = "Chọn Mã Lỗi"
    $MForm.Size = New-Object System.Drawing.Size(280, 240)
    $MForm.StartPosition = "CenterParent"
    $MForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2D2D30")
    $MForm.FormBorderStyle = "FixedToolWindow"

    $pnl = New-Object System.Windows.Forms.FlowLayoutPanel
    $pnl.Dock = "Fill"; $pnl.FlowDirection = "TopDown"; $pnl.Padding = New-Object System.Windows.Forms.Padding(10)

    function Add-MBtn($txt, $colHex, $act) {
        $b = New-Object System.Windows.Forms.Button
        $b.Text = $txt; $b.Size = New-Object System.Drawing.Size(240, 35)
        $b.FlatStyle = "Flat"; $b.ForeColor = [System.Drawing.Color]::White
        $b.BackColor = [System.Drawing.ColorTranslator]::FromHtml($colHex)
        $b.Cursor = [System.Windows.Forms.Cursors]::Hand
        $b.Margin = New-Object System.Windows.Forms.Padding(0,0,0,8)
        $b.Add_Click({ &$act; $MForm.Close() })
        $pnl.Controls.Add($b)
    }

    Add-MBtn "1. Lỗi 11B, 0709, 07c" "#8A2BE2" {
        $PReg = "HKLM:\System\CurrentControlSet\Control\Print"
        Set-RegSafe $PReg "RpcAuthnLevelPrivacyEnabled" 0
        Set-RegSafe $PReg "RpcConnectionUpdates" 0
        & $Action_CleanSpooler
    }
    Add-MBtn "2. Lỗi bc4, 4005" "#B22222" {
        $PnReg = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
        Set-RegSafe $PnReg "RestrictDriverInstallationToAdministrators" 0
        Set-RegSafe $PnReg "InForest" 0
        Set-RegSafe $PnReg "Restricted" 0
        Set-RegSafe $PnReg "TrustedServers" 0
        & $Action_CleanSpooler
    }
    Add-MBtn "3. Lỗi 002, 057" "#D2691E" { & $Action_CleanSpooler }

    $MForm.Controls.Add($pnl); $MForm.ShowDialog() | Out-Null
}

$Action_AutoShareDrive = {
    Write-Log "--- Bật Auto Share các ổ đĩa ---" "White"
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -match "^[DEF]" }
    if ($drives) { foreach ($d in $drives) { Run-CmdAndLog "net share $($d.Name)Drive=$($d.Root) /GRANT:Everyone,FULL" } }
}

$Action_ClearCreds = {
    Write-Log "--- Đang xóa kẹt Session LAN ---" "White"
    cmd.exe /c "cmdkey /list | findstr Target > %temp%\creds.txt"
    $creds = Get-Content "$env:temp\creds.txt" -ErrorAction SilentlyContinue
    if ($creds) { foreach ($c in $creds) { Run-CmdAndLog "cmdkey /delete:$(($c -split 'Target: ')[1])" } }
}

# --- CÁC TÍNH NĂNG MỚI ĐẮP THÊM ---

$Action_RestartExplorer = {
    Write-Log "--- Restarting Explorer.exe ---" "White"
    $exp = Get-Process -Name explorer -ErrorAction SilentlyContinue
    if ($exp) {
        Stop-Process -Name explorer -Force
        Start-Process explorer
        Write-Log "Đã khởi động lại Windows UI." "LimeGreen"
    } else { Write-Log "Không tìm thấy tiến trình Explorer (Đang ở WinPE?)." "Yellow" }
}

$Action_CheckPort445 = {
    Write-Log "--- Kiểm tra Port 445 (SMB Share) ---" "White"
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect("127.0.0.1", 445)
        Write-Log "✅ Port 445 đang MỞ. Máy chủ đã sẵn sàng chia sẻ." "LimeGreen"
        $tcp.Close()
    } catch { Write-Log "❌ Port 445 ĐÓNG hoặc bị chặn bởi Firewall!" "Red" }
}

$Action_ToggleFirewall = {
    Write-Log "--- Chuyển đổi trạng thái Firewall ---" "White"
    $state = cmd.exe /c "netsh advfirewall show allprofiles state"
    if ($state -match "ON") {
        Run-CmdAndLog "netsh advfirewall set allprofiles state off"
        Write-Log "🔥 ĐÃ TẮT FIREWALL (Thích hợp test LAN)" "Yellow"
    } else {
        Run-CmdAndLog "netsh advfirewall set allprofiles state on"
        Write-Log "🛡️ ĐÃ BẬT LẠI FIREWALL" "LimeGreen"
    }
}

$Action_DisableIPv6 = {
    Write-Log "--- Tắt IPv6 Ưu tiên IPv4 ---" "White"
    Set-RegSafe "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" "DisabledComponents" 255
    Write-Log "Đã ép dùng IPv4. Vui lòng Restart máy để áp dụng!" "LimeGreen"
}

# ==============================================================================
# QUẢN LÝ GIAO DIỆN CHÍNH (LAYOUT NGANG CHIA 4 HÀNG)
# ==============================================================================

function Start-App {
    if ($global:CurrentUIMode -eq "WPF" -and $global:HasWPF) {
        [xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="Phát Tấn PC - WPF Horizontal Mode" Height="750" Width="1000" Background="#1E1E1E" WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="Width" Value="180"/>
            <Setter Property="Height" Value="40"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
    </Window.Resources>
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <GroupBox Header="🖨️ XỬ LÝ MÁY IN" Grid.Row="0" Foreground="#4DA6FF" BorderBrush="#333333" Margin="0,0,0,10" Padding="5">
            <WrapPanel>
                <Button Name="btnFixSpooler" Content="1. Restart Spooler" Background="#FF3399"/>
                <Button Name="btnFixErrors" Content="2. 📌 Menu Sửa Mã Lỗi" Background="#8A2BE2" FontWeight="Bold"/>
                <Button Name="btnCleanInk" Content="3. Mở Cài Đặt Mực" Background="#C71585"/>
                <Button Name="btnSetDef" Content="4. Share/Set Default" Background="#FF8C00"/>
            </WrapPanel>
        </GroupBox>

        <GroupBox Header="🌐 MẠNG &amp; CHIA SẺ" Grid.Row="1" Foreground="#00FA9A" BorderBrush="#333333" Margin="0,0,0,10" Padding="5">
            <WrapPanel>
                <Button Name="btnShareDrive" Content="1. Auto Share D, E, F" Background="#20B2AA"/>
                <Button Name="btnClearCred" Content="2. Xóa Kẹt Pass LAN" Background="#3CB371"/>
                <Button Name="btnCheck445" Content="3. Check Port SMB (445)" Background="#D2691E"/>
                <Button Name="btnOffIPv6" Content="4. Tắt IPv6 (Ép IPv4)" Background="#556B2F"/>
                <Button Name="btnResetNet" Content="5. Deep Reset IP/DNS" Background="#4682B4"/>
            </WrapPanel>
        </GroupBox>

        <GroupBox Header="🛠️ TIỆN ÍCH HỆ THỐNG" Grid.Row="2" Foreground="#FF69B4" BorderBrush="#333333" Margin="0,0,0,10" Padding="5">
            <WrapPanel>
                <Button Name="btnRestartExp" Content="1. Restart Explorer.exe" Background="#A0522D"/>
                <Button Name="btnToggleFW" Content="2. Bật/Tắt Firewall" Background="#B22222"/>
                <Button Name="btnPing" Content="3. Test Ping Tới Log" Background="#CD5C5C"/>
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

        # Gắn sự kiện
        $global:MainForm.FindName("btnFixSpooler").Add_Click($Action_CleanSpooler)
        $global:MainForm.FindName("btnFixErrors").Add_Click($Action_ShowErrorMenu)
        $global:MainForm.FindName("btnCleanInk").Add_Click($Action_CleanInk)
        $global:MainForm.FindName("btnSetDef").Add_Click($Action_DefaultShare)
        $global:MainForm.FindName("btnShareDrive").Add_Click($Action_AutoShareDrive)
        $global:MainForm.FindName("btnClearCred").Add_Click($Action_ClearCreds)
        $global:MainForm.FindName("btnCheck445").Add_Click($Action_CheckPort445)
        $global:MainForm.FindName("btnOffIPv6").Add_Click($Action_DisableIPv6)
        $global:MainForm.FindName("btnResetNet").Add_Click({ Run-CmdAndLog "ipconfig /release & ipconfig /flushdns & netsh winsock reset" })
        $global:MainForm.FindName("btnRestartExp").Add_Click($Action_RestartExplorer)
        $global:MainForm.FindName("btnToggleFW").Add_Click($Action_ToggleFirewall)
        $global:MainForm.FindName("btnPing").Add_Click({ Run-CmdAndLog "ping 8.8.8.8 -n 4" })
        $global:MainForm.FindName("btnSwitch").Add_Click({ $global:CurrentUIMode = "WinForms"; $global:MainForm.Close(); Start-App })

        $global:MainForm.Add_Loaded({ Get-SysInfo })
        $global:MainForm.ShowDialog() | Out-Null

    } else {
        # ---- GIAO DIỆN WINFORMS NGANG ----
        $global:MainForm = New-Object System.Windows.Forms.Form
        $global:MainForm.Text = "Phát Tấn PC - WinForms Horizontal Mode"
        $global:MainForm.Size = New-Object System.Drawing.Size(1000, 750)
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
            $gb = New-Object System.Windows.Forms.GroupBox
            $gb.Text = $title; $gb.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($colHex)
            $gb.Dock = "Fill"; $gb.AutoSize = $true; $gb.Padding = New-Object System.Windows.Forms.Padding(10)
            $gb.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            
            $wp = New-Object System.Windows.Forms.FlowLayoutPanel
            $wp.Dock = "Fill"; $wp.AutoSize = $true; $wp.WrapContents = $true
            $gb.Controls.Add($wp)
            return $gb, $wp
        }

        function AddBtn($wp, $txt, $act, $bg) {
            $b = New-Object System.Windows.Forms.Button
            $b.Text = $txt; $b.Size = New-Object System.Drawing.Size(180, 40)
            $b.FlatStyle = "Flat"; $b.ForeColor = [System.Drawing.Color]::White
            $b.BackColor = [System.Drawing.ColorTranslator]::FromHtml($bg)
            $b.Cursor = [System.Windows.Forms.Cursors]::Hand
            $b.Margin = New-Object System.Windows.Forms.Padding(5)
            $b.Font = New-Object System.Drawing.Font("Segoe UI", 9)
            $b.Add_Click($act)
            $wp.Controls.Add($b)
        }

        $gb1, $wp1 = CreateWrapGroup "🖨️ XỬ LÝ MÁY IN" "#4DA6FF"
        AddBtn $wp1 "1. Restart Spooler" $Action_CleanSpooler "#FF3399"
        AddBtn $wp1 "2. 📌 Menu Sửa Mã Lỗi" $Action_ShowErrorMenu "#8A2BE2"
        AddBtn $wp1 "3. Mở Cài Đặt Mực" $Action_CleanInk "#C71585"
        AddBtn $wp1 "4. Share/Set Default" $Action_DefaultShare "#FF8C00"
        $layout.Controls.Add($gb1, 0, 0)

        $gb2, $wp2 = CreateWrapGroup "🌐 MẠNG & CHIA SẺ" "#00FA9A"
        AddBtn $wp2 "1. Auto Share D, E, F" $Action_AutoShareDrive "#20B2AA"
        AddBtn $wp2 "2. Xóa Kẹt Pass LAN" $Action_ClearCreds "#3CB371"
        AddBtn $wp2 "3. Check Port SMB (445)" $Action_CheckPort445 "#D2691E"
        AddBtn $wp2 "4. Tắt IPv6 (Ép IPv4)" $Action_DisableIPv6 "#556B2F"
        AddBtn $wp2 "5. Deep Reset IP/DNS" { Run-CmdAndLog "ipconfig /release & ipconfig /flushdns & netsh winsock reset" } "#4682B4"
        $layout.Controls.Add($gb2, 0, 1)

        $gb3, $wp3 = CreateWrapGroup "🛠️ TIỆN ÍCH HỆ THỐNG" "#FF69B4"
        AddBtn $wp3 "1. Restart Explorer.exe" $Action_RestartExplorer "#A0522D"
        AddBtn $wp3 "2. Bật/Tắt Firewall" $Action_ToggleFirewall "#B22222"
        AddBtn $wp3 "3. Test Ping Tới Log" { Run-CmdAndLog "ping 8.8.8.8 -n 4" } "#CD5C5C"
        
        $btnSW = New-Object System.Windows.Forms.Button
        $btnSW.Text = "🔄 Sang WPF Mode"; $btnSW.Size = New-Object System.Drawing.Size(180, 40)
        $btnSW.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#444444")
        $btnSW.ForeColor = [System.Drawing.Color]::White; $btnSW.FlatStyle = "Flat"
        $btnSW.Margin = New-Object System.Windows.Forms.Padding(5)
        $btnSW.Add_Click({
            if (-not $global:HasWPF) { [System.Windows.Forms.MessageBox]::Show("Máy không có WPF!", "Lỗi", 0, 16) }
            else { $global:CurrentUIMode = "WPF"; $global:MainForm.Close(); Start-App }
        })
        $wp3.Controls.Add($btnSW)
        $layout.Controls.Add($gb3, 0, 2)

        $gb4 = New-Object System.Windows.Forms.GroupBox; $gb4.Dock = "Fill"; $gb4.Text = "📋 NHẬT KÝ HỆ THỐNG"; $gb4.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFB900")
        $txtLog = New-Object System.Windows.Forms.RichTextBox; $txtLog.Dock="Fill"
        $txtLog.BackColor=[System.Drawing.ColorTranslator]::FromHtml("#2D2D30")
        $txtLog.Font=New-Object System.Drawing.Font("Consolas", 10)
        $global:LogControl = $txtLog
        $gb4.Controls.Add($txtLog)
        $layout.Controls.Add($gb4, 0, 3)

        $global:MainForm.Add_Shown({ Get-SysInfo })
        $global:MainForm.ShowDialog() | Out-Null
    }
}

if (-not $isAdmin) { Write-Host "CẢNH BÁO: CHƯA CHẠY QUYỀN ADMIN!" -ForegroundColor Red }
Start-App
