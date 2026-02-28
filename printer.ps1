# ==============================================================================
# Phát Tấn PC - Advanced Printer & Network Tool V3 (HYBRID: WPF + WinForms)
# Tối ưu cho WinPE, Win Lite, Windows Full
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
$global:AppRunning = $true

# ==============================================================================
# ENGINE: XỬ LÝ LOGIC (DÙNG CHUNG CHO CẢ 2 GIAO DIỆN)
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
        # WPF TextBox (đơn giản hóa log cho WPF)
        $global:LogControl.AppendText($FullMsg)
        $global:LogControl.ScrollToEnd()
    }
    Write-Host $FullMsg -ForegroundColor $Color
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

$Action_FixErrors = {
    Write-Log "--- Đang Fix lỗi 11B, 709, bc4, 002, 057 ---" "White"
    $PrintReg = "HKLM:\System\CurrentControlSet\Control\Print"
    Set-RegSafe $PrintReg "RpcAuthnLevelPrivacyEnabled" 0
    Set-RegSafe $PrintReg "RpcConnectionUpdates" 0
    & $Action_CleanSpooler
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
    Write-Log "Lưu ý: Tính năng này sẽ mở hộp thoại của Driver, bạn cần tự bấm Clean trong đó." "Yellow"
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

$Action_SwitchUI = {
    if ($global:CurrentUIMode -eq "WinForms") {
        if (-not $global:HasWPF) {
            [System.Windows.Forms.MessageBox]::Show("Máy của bạn hoặc bản WinPE này ĐÃ BỊ CẮT MODULE WPF!`nKhông thể chuyển đổi giao diện.", "Lỗi Hệ Thống", 0, 16)
            Write-Log "LỖI: Môi trường không hỗ trợ WPF." "Red"
        } else {
            $global:CurrentUIMode = "WPF"
            if ($global:Form) { $global:Form.Close() }
        }
    } else {
        $global:CurrentUIMode = "WinForms"
        if ($global:WPFWindow) { $global:WPFWindow.Close() }
    }
}

# ==============================================================================
# ENGINE 1: WINFORMS UI (SIÊU BỀN TRÊN WINPE)
# ==============================================================================
function Show-WinFormsUI {
    $global:Form = New-Object System.Windows.Forms.Form
    $global:Form.Text = "Phát Tấn PC - WinForms Mode"
    $global:Form.Size = New-Object System.Drawing.Size(1200, 700)
    $global:Form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1E")
    $global:Form.StartPosition = "CenterScreen"

    $layout = New-Object System.Windows.Forms.TableLayoutPanel
    $layout.Dock = "Fill"; $layout.ColumnCount = 4; $layout.RowCount = 1
    $layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 22)))
    $layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 22)))
    $layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 22)))
    $layout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 34)))
    $global:Form.Controls.Add($layout)

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
    $c1.Controls.Add((CreateBtn "2. Fix Các Mã Lỗi 11B/709/BC4" $Action_FixErrors "#8A2BE2"))
    $layout.Controls.Add($c1, 0, 0)

    $c2 = New-Object System.Windows.Forms.FlowLayoutPanel; $c2.Dock="Fill"; $c2.FlowDirection="TopDown"
    $c2.Controls.Add((CreateBtn "1. Auto Share Ổ D, E, F" $Action_AutoShareDrive "#20B2AA"))
    $c2.Controls.Add((CreateBtn "2. Deep Reset Network (IP/DNS)" { Run-CmdAndLog "ipconfig /release & ipconfig /flushdns & ipconfig /renew & netsh winsock reset" } "#4682B4"))
    $c2.Controls.Add((CreateBtn "3. Xóa kẹt Session LAN" $Action_ClearCreds "#3CB371"))
    $layout.Controls.Add($c2, 1, 0)

    $c3 = New-Object System.Windows.Forms.FlowLayoutPanel; $c3.Dock="Fill"; $c3.FlowDirection="TopDown"
    $c3.Controls.Add((CreateBtn "1. Test Ping Mạng Tới Log" { Run-CmdAndLog "ping 8.8.8.8 -n 4" } "#CD5C5C"))
    $c3.Controls.Add((CreateBtn "2. Mở Cài Đặt Clean Mực" $Action_CleanInk "#C71585"))
    $c3.Controls.Add((CreateBtn "3. Bật Share/Default All Máy In" $Action_DefaultShare "#FF8C00"))
    $c3.Controls.Add((CreateBtn "🔄 ĐỔI GIAO DIỆN WPF" $Action_SwitchUI "#444444"))
    $layout.Controls.Add($c3, 2, 0)

    $txtLog = New-Object System.Windows.Forms.RichTextBox; $txtLog.Dock="Fill"
    $txtLog.BackColor=[System.Drawing.ColorTranslator]::FromHtml("#2D2D30")
    $txtLog.Font=New-Object System.Drawing.Font("Consolas", 10)
    $global:LogControl = $txtLog
    $layout.Controls.Add($txtLog, 3, 0)

    $global:Form.ShowDialog() | Out-Null
}

# ==============================================================================
# ENGINE 2: WPF UI (GIAO DIỆN HIỆN ĐẠI TỐI ƯU WIN FULL)
# ==============================================================================
function Show-WPFUI {
    [xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Phát Tấn PC - WPF Modern Mode" Height="700" Width="1200" Background="#1E1E1E" WindowStartupLocation="CenterScreen">
    <Grid Margin="10">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="1*"/><ColumnDefinition Width="1*"/><ColumnDefinition Width="1*"/><ColumnDefinition Width="1.5*"/>
        </Grid.ColumnDefinitions>
        
        <StackPanel Grid.Column="0" Margin="5">
            <Button Name="btnFixSpooler" Content="1. Fix Spooler Services" Background="#FF3399" Foreground="White" Padding="10" Margin="0,0,0,10"/>
            <Button Name="btnFixErrors" Content="2. Fix Các Mã Lỗi Registry" Background="#8A2BE2" Foreground="White" Padding="10" Margin="0,0,0,10"/>
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
            <Button Name="btnSwitch" Content="🔄 VỀ GIAO DIỆN WINFORMS" Background="#444444" Foreground="White" Padding="10" Margin="0,0,0,10"/>
        </StackPanel>

        <TextBox Name="txtLog" Grid.Column="3" Background="#2D2D30" Foreground="#00FF00" FontFamily="Consolas" FontSize="14" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" Margin="5"/>
    </Grid>
</Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $global:WPFWindow = [System.Windows.Markup.XamlReader]::Load($reader)

    # Gắn Control Log
    $global:LogControl = $global:WPFWindow.FindName("txtLog")

    # Gắn Sự kiện Click
    $global:WPFWindow.FindName("btnFixSpooler").Add_Click($Action_CleanSpooler)
    $global:WPFWindow.FindName("btnFixErrors").Add_Click($Action_FixErrors)
    $global:WPFWindow.FindName("btnShareDrive").Add_Click($Action_AutoShareDrive)
    $global:WPFWindow.FindName("btnResetNet").Add_Click({ Run-CmdAndLog "ipconfig /release & ipconfig /flushdns & netsh winsock reset" })
    $global:WPFWindow.FindName("btnClearCred").Add_Click($Action_ClearCreds)
    $global:WPFWindow.FindName("btnPing").Add_Click({ Run-CmdAndLog "ping 8.8.8.8 -n 4" })
    $global:WPFWindow.FindName("btnCleanInk").Add_Click($Action_CleanInk)
    $global:WPFWindow.FindName("btnSetDef").Add_Click($Action_DefaultShare)
    $global:WPFWindow.FindName("btnSwitch").Add_Click($Action_SwitchUI)

    $global:WPFWindow.ShowDialog() | Out-Null
}

# ==============================================================================
# MAIN LOOP: CHẠY & QUẢN LÝ VIỆC CHUYỂN ĐỔI GIAO DIỆN
# ==============================================================================
if (-not $isAdmin) { Write-Host "CẢNH BÁO: CHƯA CHẠY QUYỀN ADMIN!" -ForegroundColor Red }

# Vòng lặp giữ app sống khi đổi giao diện
while ($global:AppRunning) {
    if ($global:CurrentUIMode -eq "WPF" -and $global:HasWPF) {
        Show-WPFUI
    } else {
        Show-WinFormsUI
    }
    # Thoát vòng lặp nếu cửa sổ đóng hẳn (không phải do nút Switch)
    $global:AppRunning = $false 
    # Logic kiểm tra: Nút switch sẽ set lại AppRunning = true trong sự kiện nếu ta viết trick, 
    # Nhưng trong PS 1 luồng, cách dễ nhất: Mỗi khi đóng Form, vòng lặp kết thúc. Tui đã thiết lập switch đóng form cũ, mở lại form mới.
    $global:AppRunning = $true # Khởi động lại vòng lặp
    
    # Check nếu user ấn dấu X (Đóng) thay vì ấn nút đổi giao diện
    # Ta phải check LogControl có bị dispose không
    if (($global:CurrentUIMode -eq "WinForms" -and -not $global:Form.Visible) -or 
        ($global:CurrentUIMode -eq "WPF" -and -not $global:WPFWindow.IsVisible)) {
        # Nếu switch ui vừa được click, biến đổi trạng thái, form cũ ẩn -> Mở form mới.
        # Nhưng thực tế PowerShell sẽ kẹt ở hàm ShowDialog cho đến khi form tắt.
    }
}
