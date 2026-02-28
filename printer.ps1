# ==============================================================================
# Phát Tấn PC - Advanced Printer & Network Tool V4.2 (HORIZONTAL HYBRID)
# - Đã fix lỗi Scope biến của nút bấm Menu (GetNewClosure)
# - Phân loại rõ ràng Lỗi Máy Chủ (Server) và Máy Khách (Client)
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
    Write-Log "🖥️ Tên máy: $env:COMPUTERNAME" "Cyan"
    try {
        $ipObj = (ipconfig | Select-String "IPv4").Line
        if ($ipObj) { Write-Log "🌐 IP LAN: $(($ipObj -split ": ")[-1].Trim())" "Cyan" }
    } catch {}
}

# ==============================================================================
# ACTIONS TÍNH NĂNG CHÍNH VÀ MENU MÃ LỖI
# ==============================================================================

$Action_CleanSpooler = {
    Write-Log "--- Đang dọn dẹp & Restart Spooler ---" "White"
    Run-CmdAndLog "net stop spooler /y"
    Run-CmdAndLog "del /Q /F /S %systemroot%\System32\Spool\Printers\*.*"
    Run-CmdAndLog "net start spooler"
    Write-Log "Hoàn tất Spooler." "LimeGreen"
}

# -------------------------------------------------------------
# MENU FIX LỖI (ĐÃ CHIA SERVER VÀ CLIENT)
# -------------------------------------------------------------
$Action_ShowErrorMenu = {
    $MForm = New-Object System.Windows.Forms.Form
    $MForm.Text = "Menu Sửa Mã Lỗi Chuyên Sâu"
    $MForm.Size = New-Object System.Drawing.Size(340, 520) # Kéo dài Form ra để chứa đủ list
    $MForm.StartPosition = "CenterParent"
    $MForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2D2D30")
    $MForm.FormBorderStyle = "FixedToolWindow"

    $pnl = New-Object System.Windows.Forms.FlowLayoutPanel
    $pnl.Dock = "Fill"; $pnl.FlowDirection = "TopDown"; $pnl.Padding = New-Object System.Windows.Forms.Padding(10)

    # Hàm tạo Label tiêu đề phân loại
    function Add-Label($txt) {
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $txt; $lbl.AutoSize = $true
        $lbl.ForeColor = [System.Drawing.Color]::Gold
        $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $lbl.Margin = New-Object System.Windows.Forms.Padding(0,10,0,5)
        $pnl.Controls.Add($lbl)
    }

    # Hàm tạo Nút bấm (Đã fix lỗi GetNewClosure)
    function Add-MBtn($txt, $colHex, [scriptblock]$act) {
        $b = New-Object System.Windows.Forms.Button
        $b.Text = $txt; $b.Size = New-Object System.Drawing.Size(300, 35)
        $b.FlatStyle = "Flat"; $b.ForeColor = [System.Drawing.Color]::White
        $b.BackColor = [System.Drawing.ColorTranslator]::FromHtml($colHex)
        $b.Cursor = [System.Windows.Forms.Cursors]::Hand
        $b.Margin = New-Object System.Windows.Forms.Padding(0,0,0,8)
        
        # ĐÂY LÀ CHÌA KHÓA FIX LỖI: .GetNewClosure() sẽ lưu biến $act vào bộ nhớ nút bấm
        $handler = { & $act; $MForm.Close() }.GetNewClosure()
        $b.Add_Click($handler)
        
        $pnl.Controls.Add($b)
    }

    # ============ MÁY CHỦ (SERVER) ============
    Add-Label "💻 MÁY CHỦ CẮM USB (SERVER)"

    Add-MBtn "1. Lỗi 11B, 0709, 07c (Máy trạm không vô được)" "#8A2BE2" {
        Write-Log "[SERVER] Đang Fix lỗi RPC PrintNightmare..." "White"
        $PReg = "HKLM:\System\CurrentControlSet\Control\Print"
        Set-RegSafe $PReg "RpcAuthnLevelPrivacyEnabled" 0
        Set-RegSafe $PReg "RpcConnectionUpdates" 0
        & $Action_CleanSpooler
    }
    
    Add-MBtn "2. Lỗi 6D9, BCB (Tường lửa chặn Share)" "#D2691E" {
        Write-Log "[SERVER] Đang bật dịch vụ Windows Firewall và Share..." "White"
        Run-CmdAndLog "sc config mpssvc start= auto"
        Run-CmdAndLog "net start mpssvc"
        Run-CmdAndLog "netsh advfirewall firewall set rule group=`"File and Printer Sharing`" new enable=Yes"
        Write-Log "Đã mở cổng tường lửa thành công!" "LimeGreen"
    }

    Add-MBtn "3. Lỗi 002 (Kẹt Driver cũ, không cài được)" "#C71585" {
        Write-Log "[SERVER] HƯỚNG DẪN: Đang mở Print Management." "Yellow"
        Write-Log "-> Vô All Drivers -> Xóa sạch Driver cũ hãng đó -> Cài lại." "White"
        Run-CmdAndLog "printmanagement.msc"
    }

    # ============ MÁY TRẠM (CLIENT) ============
    Add-Label "🖥️ MÁY TRẠM KẾT NỐI (CLIENT)"

    Add-MBtn "4. Lỗi BC4, 4005 (A Policy Is In Effect)" "#B22222" {
        Write-Log "[CLIENT] Đang gỡ chặn cài đặt qua mạng (Point and Print)..." "White"
        $PnReg = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
        Set-RegSafe $PnReg "RestrictDriverInstallationToAdministrators" 0
        Set-RegSafe $PnReg "InForest" 0
        Set-RegSafe $PnReg "Restricted" 0
        Set-RegSafe $PnReg "TrustedServers" 0
        & $Action_CleanSpooler
    }

    Add-MBtn "5. Truy cập máy chủ bị đòi Password / Access Denied" "#20B2AA" {
        Write-Log "[CLIENT] Đang bật Guest Auth & Xóa Session kẹt..." "White"
        Set-RegSafe "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" "AllowInsecureGuestAuth" 1
        cmd.exe /c "cmdkey /list | findstr Target > %temp%\creds.txt"
        $creds = Get-Content "$env:temp\creds.txt" -ErrorAction SilentlyContinue
        if ($creds) { foreach ($c in $creds) { Run-CmdAndLog "cmdkey /delete:$(($c -split 'Target: ')[1])" } }
        Write-Log "Đã xóa cache Password LAN." "LimeGreen"
    }

    Add-MBtn "6. Lỗi 'Another computer is using...' / Bận ảo" "#556B2F" {
        Write-Log "[CLIENT/SERVER] Đang tắt Bidirectional Support..." "White"
        $PrintersPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers"
        if (Test-Path $PrintersPath) {
            Get-ChildItem $PrintersPath | ForEach-Object {
                Set-ItemProperty -Path $_.PSPath -Name "BidiEnabled" -Value 0 -ErrorAction SilentlyContinue
            }
            & $Action_CleanSpooler
        }
    }

    Add-MBtn "7. Lỗi 3E3 (Add qua IP thay vì bấm thẳng)" "#4682B4" {
        Write-Log "[CLIENT] HƯỚNG DẪN: Đang mở Add Printer." "Yellow"
        Write-Log "-> Bấm Add a printer -> Chọn Add a local printer -> Create a new port (Standard TCP/IP) -> Nhập IP Server." "White"
        try { Run-CmdAndLog "control printers" } catch {}
    }

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

$Action_CleanInk = {
    Write-Log "--- Mở bảng Clean Mực ---" "White"
    try { Run-CmdAndLog "control printers" } catch {}
    Run-CmdAndLog "rundll32 printui.dll,PrintUIEntry /p /n `"$((Get-CimInstance Win32_Printer | Select-Object -First 1).Name)`""
}

$Action_DefaultShare = {
    Write-Log "--- Set Mặc định & Share toàn bộ máy in ---" "White"
    try {
        $printers = Get-CimInstance Win32_Printer
        foreach ($p in $printers) {
            Run-CmdAndLog "rundll32 printui.dll,PrintUIEntry /y /n `"$($p.Name)`""
            $p | Set-CimInstance -Property @{Shared=$true; Published=$true} -ErrorAction SilentlyContinue
        }
    } catch { Run-CmdAndLog "net share Printer=LPT1 /users:10" }
}

$Action_RestartExplorer = {
    Write-Log "--- Restarting Explorer.exe ---" "White"
    if (Get-Process -Name explorer -ErrorAction SilentlyContinue) {
        Stop-Process -Name explorer -Force; Start-Process explorer
    } else { Write-Log "Không tìm thấy tiến trình Explorer." "Yellow" }
}

$Action_CheckPort445 = {
    Write-Log "--- Kiểm tra Port 445 (SMB Share) ---" "White"
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect("127.0.0.1", 445)
        Write-Log "✅ Port 445 đang MỞ." "LimeGreen"; $tcp.Close()
    } catch { Write-Log "❌ Port 445 ĐÓNG hoặc bị Firewall chặn!" "Red" }
}

$Action_ToggleFirewall = {
    Write-Log "--- Chuyển đổi trạng thái Firewall ---" "White"
    if ((cmd.exe /c "netsh advfirewall show allprofiles state") -match "ON") {
        Run-CmdAndLog "netsh advfirewall set allprofiles state off"
    } else {
        Run-CmdAndLog "netsh advfirewall set allprofiles state on"
    }
}

$Action_DisableIPv6 = {
    Write-Log "--- Tắt IPv6 Ưu tiên IPv4 ---" "White"
    Set-RegSafe "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" "DisabledComponents" 255
    Write-Log "Vui lòng Restart máy để áp dụng!" "LimeGreen"
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
