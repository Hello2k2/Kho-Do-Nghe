# ==============================================================================
# Phát Tấn PC - Advanced Printer & Network Tool V3.1 (HYBRID: WPF + WinForms)
# - Đã Fix lỗi Write-Host Color
# - Thêm Popup Menu chọn mã lỗi cho khách
# ==============================================================================

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# 1. KIỂM TRA HỖ TRỢ WPF
$global:HasWPF = $false
try {
    Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
    Add-Type -AssemblyName PresentationCore -ErrorAction Stop
    Add-Type -AssemblyName WindowsBase -ErrorAction Stop
    $global:HasWPF = $true
} catch {
    $global:HasWPF = $false
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$global:CurrentUIMode = if ($global:HasWPF) { "WPF" } else { "WinForms" }
$global:LogControl = $null

# ==============================================================================
# ENGINE: XỬ LÝ LOGIC (DÙNG CHUNG CẢ 2 GIAO DIỆN)
# ==============================================================================

function Write-Log ($Message, $Color = "LimeGreen") {
    $time = (Get-Date).ToString("HH:mm:ss")
    $FullMsg = "[$time] $Message`n"
    
    # In ra UI
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
    
    # Fix lỗi Console Color (Map màu UI sang Console)
    $ConsoleColor = "White"
    if ($Color -match "Green") { $ConsoleColor = "Green" }
    elseif ($Color -match "Red") { $ConsoleColor = "Red" }
    elseif ($Color -match "Yellow" -or $Color -match "Orange") { $ConsoleColor = "Yellow" }
    elseif ($Color -match "Cyan" -or $Color -match "Blue") { $ConsoleColor = "Cyan" }
    Write-Host "[$time] $Message" -ForegroundColor $ConsoleColor
}

function Run-CmdAndLog ($cmdStr) {
    Write-Log "Đang chạy: $cmdStr" "Cyan"
    $output = Invoke-Expression $cmdStr 2>&1
    foreach ($line in $output) {
        if (![string]::IsNullOrWhiteSpace($line)) { Write-Log "  $line" "White" }
    }
}

function Set-RegSafe ($Path, $Name, $Value, $Type = "DWord") {
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
        Write-Log "  -> Reg [$Name] = $Value (OK)" "White"
    } catch {
        $cmdType = if ($Type -eq "DWord") { "REG_DWORD" } else { "REG_SZ" }
        Run-CmdAndLog "reg add `"$Path`" /v $Name /t $cmdType /d $Value /f"
    }
}

# --- CÁC HÀM CHỨC NĂNG CHÍNH ---
$Action_CleanSpooler = {
    Write-Log "--- Đang dọn dẹp & Restart Spooler ---" "White"
    Run-CmdAndLog "net stop spooler /y"
    Run-CmdAndLog "del /Q /F /S %systemroot%\System32\Spool\Printers\*.*"
    Run-CmdAndLog "net start spooler"
    Write-Log "Hoàn tất Spooler." "LimeGreen"
}

# HÀM HIỆN POPUP MENU ĐỂ KHÁCH CHỌN LỖI
$Action_ShowErrorMenu = {
    $MenuForm = New-Object System.Windows.Forms.Form
    $MenuForm.Text = "Chọn Mã Lỗi Cần Sửa"
    $MenuForm.Size = New-Object System.Drawing.Size(280, 240)
    $MenuForm.StartPosition = "CenterParent"
    $MenuForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2D2D30")
    $MenuForm.FormBorderStyle = "FixedToolWindow"

    $pnl = New-Object System.Windows.Forms.FlowLayoutPanel
    $pnl.Dock = "Fill"; $pnl.FlowDirection = "TopDown"
    $pnl.Padding = New-Object System.Windows.Forms.Padding(10)

    function Add-MenuBtn($txt, $colHex, $act) {
        $b = New-Object System.Windows.Forms.Button
        $b.Text = $txt; $b.Size = New-Object System.Drawing.Size(240, 35)
        $b.FlatStyle = "Flat"; $b.ForeColor = [System.Drawing.Color]::White
        $b.BackColor = [System.Drawing.ColorTranslator]::FromHtml($colHex)
        $b.Cursor = [System.Windows.Forms.Cursors]::Hand
        $b.Margin = New-Object System.Windows.Forms.Padding(0,0,0,8)
        $b.Add_Click({ &$act; $MenuForm.Close() })
        $pnl.Controls.Add($b)
    }

    Add-MenuBtn "1. Lỗi 0x0000011B, 0709, 07c" "#8A2BE2" {
        Write-Log "Đang Fix 11B/709/07c (Lỗi RPC PrintNightmare)..." "White"
        $PrintReg = "HKLM:\System\CurrentControlSet\Control\Print"
        Set-RegSafe $PrintReg "RpcAuthnLevelPrivacyEnabled" 0
        Set-RegSafe $PrintReg "RpcConnectionUpdates" 0
        & $Action_CleanSpooler
    }

    Add-MenuBtn "2. Lỗi 0x00000bc4, 4005" "#B22222" {
        Write-Log "Đang Fix BC4/4005 (A Policy Is In Effect)..." "White"
        $PnPReg = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
        Set-RegSafe $PnPReg "RestrictDriverInstallationToAdministrators" 0
        Set-RegSafe $PnPReg "InForest" 0
        Set-RegSafe $PnPReg "Restricted" 0
        Set-RegSafe $PnPReg "TrustedServers" 0
        & $Action_CleanSpooler
    }

    Add-MenuBtn "3. Lỗi 0x00000002, 057" "#D2691E" {
        Write-Log "Đang Fix 002/057 (Lỗi Spooler / Driver)..." "White"
        & $Action_CleanSpooler
    }

    $MenuForm.Controls.Add($pnl)
    $MenuForm.ShowDialog() | Out-Null
}

$Action_AutoShareDrive = {
    Write-Log "--- Bật Auto Share các ổ đĩa D, E, F... ---" "White"
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -match "^[DEF]" }
    if ($drives) {
        foreach ($d in $drives) {
            Run-CmdAndLog "net share $($d.Name)Drive=$($d.Root) /GRANT:Everyone,FULL"
        }
        Write-Log "Đã share thành công!" "LimeGreen"
    } else { Write-Log "Không tìm thấy ổ D, E, F nào." "Yellow" }
}

$Action_CleanInk = {
    Write-Log "--- Mở bảng Clean Mực (Tùy hãng) ---" "White"
    Write-Log "Lưu ý: Bạn cần tự bấm Clean trong cửa sổ cài đặt của hãng." "Yellow"
    try { Run-CmdAndLog "control printers" } catch {}
    Run-CmdAndLog "rundll32 printui.dll,PrintUIEntry /p /n `"$((Get-CimInstance Win32_Printer | Select-Object -First 1).Name)`""
}

$Action_DefaultShare = {
    Write-Log "--- Set Mặc định & Share toàn bộ máy in ---" "White"
    try {
        $printers = Get-CimInstance Win32_Printer
        foreach ($p in $printers) {
            Run-CmdAndLog "rundll32 printui.dll,PrintUIEntry /y /n `"$($p.Name)`"" # Set Default
            $p | Set-CimInstance -Property @{Shared=$true; Published=$true} -ErrorAction SilentlyContinue
            Write-Log "Đã xử lý: $($p.Name)" "Cyan"
        }
    } catch { Run-CmdAndLog "net share Printer=LPT1 /users:10" } # Fallback
}

$Action_ClearCreds = {
    Write-Log "--- Đang xóa kẹt Session LAN ---" "White"
    cmd.exe /c "cmdkey /list | findstr Target > %temp%\creds.txt"
    $creds = Get-Content "$env:temp\creds.txt" -ErrorAction SilentlyContinue
    if ($creds) {
        foreach ($cred in $creds) {
            $target = ($cred -split "Target: ")[1]
            Run-CmdAndLog "cmdkey /delete:$target"
        }
    } else { Write-Log "Không có Session mạng nào bị kẹt." "LimeGreen" }
}

# ==============================================================================
# QUẢN LÝ KHỞI CHẠY GIAO DIỆN
# ==============================================================================

function Start-App {
    if ($global:CurrentUIMode -eq "WPF" -and $global:HasWPF) {
        # ---- GIAO DIỆN WPF ----
        [xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="Phát Tấn PC - WPF Modern Mode" Height="700" Width="1200" Background="#1E1E1E" WindowStartupLocation="CenterScreen">
    <Grid Margin="10">
        <Grid.ColumnDefinitions><ColumnDefinition Width="1*"/><ColumnDefinition Width="1*"/><ColumnDefinition Width="1*"/><ColumnDefinition Width="1.5*"/></Grid.ColumnDefinitions>
        <StackPanel Grid.Column="0" Margin="5">
            <Button Name="btnFixSpooler" Content="1. Fix Spooler Services" Background="#FF3399" Foreground="White" Padding="10" Margin="0,0,0,10"/>
            <Button Name="btnFixErrors" Content="2. 📌 Mở Menu Sửa Các Mã Lỗi" Background="#8A2BE2" Foreground="White" Padding="10" Margin="0,0,0,10" FontWeight="Bold"/>
        </StackPanel>
        <StackPanel Grid.Column="1" Margin="5">
            <Button Name="btnShareDrive" Content="1. Auto Share Ổ D, E, F" Background="#20B2AA" Foreground="White" Padding="10" Margin="0,0,0,10"/>
            <Button Name="btnResetNet" Content="2. Deep Reset IP/DNS" Background="#4682B4" Foreground="White" Padding="10" Margin="0,0,0,10"/>
            <Button Name="btnClearCred" Content="3. Xóa Kẹt Mật Khẩu LAN" Background="#3CB371" Foreground="White" Padding="10" Margin="0,0,0,10"/>
        </StackPanel>
        <StackPanel Grid.Column="2" Margin="5">
            <Button Name="btnPing" Content="1. Test Ping Mạng Tới Log" Background="#CD5C5C" Foreground="White" Padding="10" Margin="0,0,0,10"/>
            <Button Name="btnCleanInk" Content="2. Mở Cài Đặt Clean Mực" Background="#C71585" Foreground="White" Padding="10" Margin="0,0,0,10"/>
            <Button Name="btnSetDef" Content="3. Share/Default Máy In" Background="#FF8C00" Foreground="White" Padding="10" Margin="0,0,0,10"/>
            <Button Name="btnSwitch" Content="🔄 ĐỔI GIAO DIỆN (Đang: WPF)" Background="#444444" Foreground="White" Padding="10" Margin="0,0,0,10"/>
        </StackPanel>
        <TextBox Name="txtLog" Grid.Column="3" Background="#2D2D30" Foreground="#00FF00" FontFamily="Consolas" FontSize="14" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" Margin="5"/>
    </Grid>
</Window>
"@
        $reader = (New-Object System.Xml.XmlNodeReader $xaml)
        $global:MainForm = [System.Windows.Markup.XamlReader]::Load($reader)
        $global:LogControl = $global:MainForm.FindName("txtLog")

        $global:MainForm.FindName("btnFixSpooler").Add_Click($Action_CleanSpooler)
        $global:MainForm.FindName("btnFixErrors").Add_Click($Action_ShowErrorMenu) # Gắn Menu Popup vào đây
        $global:MainForm.FindName("btnShareDrive").Add_Click($Action_AutoShareDrive)
        $global:MainForm.FindName("btnResetNet").Add_Click({ Run-CmdAndLog "ipconfig /release & ipconfig /flushdns & netsh winsock reset" })
        $global:MainForm.FindName("btnClearCred").Add_Click($Action_ClearCreds)
        $global:MainForm.FindName("btnPing").Add_Click({ Run-CmdAndLog "ping 8.8.8.8 -n 4" })
        $global:MainForm.FindName("btnCleanInk").Add_Click($Action_CleanInk)
        $global:MainForm.FindName("btnSetDef").Add_Click($Action_DefaultShare)
        $global:MainForm.FindName("btnSwitch").Add_Click({ $global:CurrentUIMode = "WinForms"; $global:MainForm.Close(); Start-App })

        $global:MainForm.ShowDialog() | Out-Null

    } else {
        # ---- GIAO DIỆN WINFORMS ----
        $global:MainForm = New-Object System.Windows.Forms.Form
        $global:MainForm.Text = "Phát Tấn PC - WinForms Mode"
        $global:MainForm.Size = New-Object System.Drawing.Size(1200, 700)
        $global:MainForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1E")
        $global:MainForm.StartPosition = "CenterScreen"

        $layout = New-Object System.Windows.Forms.TableLayoutPanel
        $layout.Dock = "Fill"; $layout.ColumnCount = 4; $layout.RowCount = 1
        $layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 22)))
        $layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 22)))
        $layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 22)))
        $layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 34)))
        $global:MainForm.Controls.Add($layout)

        function CreateBtn ($txt, $act, $col) {
            $b = New-Object System.Windows.Forms.Button
            $b.Text = $txt; $b.Size = New-Object System.Drawing.Size(220, 35)
            $b.FlatStyle = "Flat"; $b.ForeColor = [System.Drawing.Color]::White
            $b.BackColor = [System.Drawing.ColorTranslator]::FromHtml($col)
            $b.Add_Click($act); $b.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 8)
            return $b
        }

        $c1 = New-Object System.Windows.Forms.FlowLayoutPanel; $c1.Dock="Fill"; $c1.FlowDirection="TopDown"
        $c1.Controls.Add((CreateBtn "1. Fix Spooler Services" $Action_CleanSpooler "#FF3399"))
        $c1.Controls.Add((CreateBtn "2. 📌 Mở Menu Sửa Các Mã Lỗi" $Action_ShowErrorMenu "#8A2BE2")) # Gắn Menu Popup
        $layout.Controls.Add($c1, 0, 0)

        $c2 = New-Object System.Windows.Forms.FlowLayoutPanel; $c2.Dock="Fill"; $c2.FlowDirection="TopDown"
        $c2.Controls.Add((CreateBtn "1. Auto Share Ổ D, E, F" $Action_AutoShareDrive "#20B2AA"))
        $c2.Controls.Add((CreateBtn "2. Deep Reset Network" { Run-CmdAndLog "ipconfig /release & ipconfig /flushdns & netsh winsock reset" } "#4682B4"))
        $c2.Controls.Add((CreateBtn "3. Xóa kẹt Session LAN" $Action_ClearCreds "#3CB371"))
        $layout.Controls.Add($c2, 1, 0)

        $c3 = New-Object System.Windows.Forms.FlowLayoutPanel; $c3.Dock="Fill"; $c3.FlowDirection="TopDown"
        $c3.Controls.Add((CreateBtn "1. Test Ping Mạng Tới Log" { Run-CmdAndLog "ping 8.8.8.8 -n 4" } "#CD5C5C"))
        $c3.Controls.Add((CreateBtn "2. Mở Cài Đặt Clean Mực" $Action_CleanInk "#C71585"))
        $c3.Controls.Add((CreateBtn "3. Bật Share/Default All" $Action_DefaultShare "#FF8C00"))
        
        $btnSwitch = CreateBtn "🔄 ĐỔI GIAO DIỆN (Đang: WinForm)" {} "#444444"
        $btnSwitch.Add_Click({
            if (-not $global:HasWPF) {
                [System.Windows.Forms.MessageBox]::Show("Môi trường WinPE/Win Lite này KHÔNG HỖ TRỢ WPF!", "Cảnh báo", 0, 16)
                Write-Log "LỖI: Máy không có module WPF (PresentationFramework)." "Red"
            } else {
                $global:CurrentUIMode = "WPF"; $global:MainForm.Close(); Start-App
            }
        })
        $c3.Controls.Add($btnSwitch)
        $layout.Controls.Add($c3, 2, 0)

        $txtLog = New-Object System.Windows.Forms.RichTextBox; $txtLog.Dock="Fill"
        $txtLog.BackColor=[System.Drawing.ColorTranslator]::FromHtml("#2D2D30")
        $txtLog.Font=New-Object System.Drawing.Font("Consolas", 10)
        $global:LogControl = $txtLog
        $layout.Controls.Add($txtLog, 3, 0)

        $global:MainForm.ShowDialog() | Out-Null
    }
}

if (-not $isAdmin) { Write-Host "CẢNH BÁO: CHƯA CHẠY QUYỀN ADMIN!" -ForegroundColor Red }
Start-App
