# Yêu cầu chạy bằng quyền Admin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Vui lòng chạy Script bằng quyền Administrator!"
    Exit
}

# Load thư viện UI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CẤU HÌNH LÕI & DỮ LIỆU ---
$encodedVTKey = "M2Y0NDhmZmE2NmU5ODRhYjVlNzRjOWIzOGYyOTJhYmY2YjFiNzI2YmY4N2U1N2Q2YWY4MzgzNjZlMTc2MThiYg=="
$VT_API_KEY = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedVTKey))
$sigcheckUrl = "https://live.sysinternals.com/sigcheck64.exe"
$sigcheckPath = "$env:TEMP\sigcheck64.exe"
$localDbPath = "$env:TEMP\MalwareHashDB.txt"

$global:scanResults = @()
$global:LocalHashDB = New-Object System.Collections.Generic.HashSet[string]

if (Test-Path $localDbPath) {
    (Get-Content $localDbPath) | ForEach-Object { if ($_ -match '^[a-fA-F0-9]{32}$') { $global:LocalHashDB.Add($_.ToLower()) | Out-Null } }
}

$defaultTargetPaths = @(
    @{ Scope = "User";   Path = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup" }
    @{ Scope = "User";   Path = "$env:LOCALAPPDATA\Temp" }
    @{ Scope = "System"; Path = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" }
)

# --- CÁC HÀM LÕI (Giữ nguyên logic cực xịn từ v7) ---
function Update-LocalDatabase {
    param([ScriptBlock]$UpdateStatus)
    &$UpdateStatus "Đang tải Database mới (Abuse.ch)..."
    try {
        $dbUrl = "https://bazaar.abuse.ch/export/txt/md5/recent/"
        $response = Invoke-WebRequest -Uri $dbUrl -UseBasicParsing
        $lines = $response.Content -split "`n"
        $global:LocalHashDB.Clear(); $newHashes = @()
        foreach ($line in $lines) {
            $line = $line.Trim()
            if ($line -match '^[a-fA-F0-9]{32}$') {
                $hash = $line.ToLower(); $global:LocalHashDB.Add($hash) | Out-Null; $newHashes += $hash
            }
        }
        $newHashes | Out-File -FilePath $localDbPath -Encoding ASCII
        &$UpdateStatus "Đã nạp $( $global:LocalHashDB.Count ) mẫu Virus offline!"
    } catch { &$UpdateStatus "Lỗi mạng! Không tải được DB." }
}

function Start-DeepScan {
    param([array]$Targets, [ScriptBlock]$UpdateStatusAction, [ScriptBlock]$AddRowAction, [ScriptBlock]$CompleteAction)
    $global:scanResults = @(); $count = 0; $dangerCount = 0
    if (-not (Test-Path $sigcheckPath)) {
        &$UpdateStatusAction "Đang tải Core Sysinternals..."
        try { Invoke-WebRequest -Uri $sigcheckUrl -OutFile $sigcheckPath -UseBasicParsing } catch { return }
    }
    &$UpdateStatusAction "Đang quét siêu tốc..."
    foreach ($target in $Targets) {
        if (Test-Path $target.Path) {
            $sigOutput = & $sigcheckPath -accepteula -c -h -s $target.Path 2>$null
            if ($sigOutput -and $sigOutput.Count -gt 1) {
                $csvData = $sigOutput | ConvertFrom-Csv -Delimiter ","
                foreach ($row in $csvData) {
                    if ([string]::IsNullOrWhiteSpace($row.Path)) { continue }
                    $count++
                    $ext = [System.IO.Path]::GetExtension($row.Path).ToLower()
                    $isRun = ($ext -match "\.(exe|dll|sys|ocx|bin|scr|bat|cmd|vbs|ps1)$")
                    $hashMD5 = if ($row.MD5) { $row.MD5.ToLower() } else { "N/A" }
                    $status = "🔵 Ít rủi ro"
                    
                    if ($hashMD5 -ne "N/A" -and $global:LocalHashDB.Contains($hashMD5)) { $status = "💀 NHIỄM ĐỘC!"; $dangerCount++ } 
                    elseif ($isRun) {
                        if ($row."Verified" -eq "Signed") { $status = "✅ An toàn" } else { $status = "❌ NGHI NGỜ"; $dangerCount++ }
                    }
                    $resultObj = [pscustomobject]@{ Scope = $target.Scope; Status = $status; FileType = $ext; Hash = $row.MD5; Publisher = $row.Publisher; FileName = Split-Path $row.Path -Leaf; Path = $row.Path }
                    $global:scanResults += $resultObj
                    &$AddRowAction $resultObj
                }
            }
        }
    }
    &$CompleteAction $count $dangerCount
}

function Check-VirusTotalAPI ($hash) {
    if ([string]::IsNullOrWhiteSpace($VT_API_KEY)) { return "Lỗi API Key" }
    try {
        $headers = @{ "x-apikey" = $VT_API_KEY }; $url = "https://www.virustotal.com/api/v3/files/$hash"
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get -ErrorAction Stop
        $stats = $response.data.attributes.last_analysis_stats
        $malicious = $stats.malicious; $total = $stats.malicious + $stats.undetected + $stats.harmless
        if ($malicious -gt 0) { return "🚨 Phát hiện: $malicious/$total hãng báo độc!" } else { return "✅ Sạch: 0/$total hãng báo độc" }
    } catch { return "⚠️ Chưa có dữ liệu trên VT" }
}

function Kill-Virus ($filePath) {
    if ([System.Windows.Forms.MessageBox]::Show("Xóa VĨNH VIỄN file này?", "Cảnh báo", 4, 48) -eq "Yes") {
        try { Remove-Item -Path $filePath -Force -ErrorAction Stop; return $true } catch { return $false }
    }
    return $false
}

# ==========================================
# --- KHỞI TẠO GIAO DIỆN CHÍNH (WPF/WinForms) ---
# ==========================================
$useWPF = $true
try { Add-Type -AssemblyName PresentationFramework -ErrorAction Stop } catch { $useWPF = $false }

if ($useWPF) {
    [xml]$xaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="Pro Scanner v8 (Modern UI)" Height="700" Width="1150" Background="{DynamicResource WinBg}">
        
        <Window.Resources>
            <SolidColorBrush x:Key="WinBg" Color="#F0F2F5"/>
            <SolidColorBrush x:Key="CardBg" Color="#FFFFFF"/>
            <SolidColorBrush x:Key="TextMain" Color="#2C3E50"/>
            <SolidColorBrush x:Key="TextSub" Color="#6C757D"/>
            <SolidColorBrush x:Key="BorderCol" Color="#E1E5EA"/>
        </Window.Resources>

        <Grid Margin="15">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/> <RowDefinition Height="*"/>    </Grid.RowDefinitions>

            <Grid Grid.Row="0" Margin="0,0,0,15">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBlock Text="🛡️ THỢ SĂN MÃ ĐỘC TỐI THƯỢNG v8" FontWeight="Bold" FontSize="22" Foreground="{DynamicResource TextMain}" VerticalAlignment="Center"/>
                <Button Name="btnTheme" Grid.Column="1" Content="🌙 Dark Mode" Width="100" Height="30" Background="#34495e" Foreground="White" FontWeight="Bold" BorderThickness="0" Cursor="Hand">
                    <Button.Resources>
                        <Style TargetType="Border"> <Setter Property="CornerRadius" Value="15"/> </Style>
                    </Button.Resources>
                </Button>
            </Grid>

            <Border Grid.Row="1" Background="{DynamicResource CardBg}" BorderBrush="{DynamicResource BorderCol}" BorderThickness="1" CornerRadius="10" Margin="0,0,0,15" Padding="15">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    
                    <StackPanel Grid.Column="0" Orientation="Horizontal">
                        <Button Name="btnUpdateDB" Content="🔄 Nạp Database" Width="130" Height="35" Background="#17A2B8" Foreground="White" FontWeight="Bold" Margin="0,0,10,0" BorderThickness="0"/>
                        <Button Name="btnBrowse" Content="📂 Chọn thư mục" Width="120" Height="35" Background="#6C757D" Foreground="White" FontWeight="Bold" Margin="0,0,10,0" BorderThickness="0"/>
                    </StackPanel>
                    
                    <TextBox Name="txtTarget" Grid.Column="1" Height="35" VerticalContentAlignment="Center" Text="[Mặc định] Các thư mục trọng điểm hệ thống" IsReadOnly="True" Margin="0,0,15,0" Padding="10,0,0,0" Background="{DynamicResource WinBg}" Foreground="{DynamicResource TextMain}" BorderBrush="{DynamicResource BorderCol}"/>
                    
                    <StackPanel Grid.Column="2" Orientation="Horizontal">
                        <TextBlock Name="txtStatus" Text="Sẵn sàng quét..." VerticalAlignment="Center" Margin="0,0,15,0" FontStyle="Italic" Foreground="{DynamicResource TextSub}" FontWeight="Bold"/>
                        <Button Name="btnScan" Content="🚀 BẮT ĐẦU QUÉT" Width="140" Height="35" Background="#DC3545" Foreground="White" FontSize="14" FontWeight="Bold" BorderThickness="0"/>
                    </StackPanel>
                </Grid>
            </Border>

            <Border Grid.Row="2" Background="{DynamicResource CardBg}" BorderBrush="{DynamicResource BorderCol}" BorderThickness="1" CornerRadius="10" Padding="10">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    
                    <ListView Name="lstResults" Grid.Row="0" Background="Transparent" Foreground="{DynamicResource TextMain}" BorderThickness="0">
                        <ListView.ContextMenu>
                            <ContextMenu>
                                <MenuItem Name="menuVTAPI" Header="⚡ Check VirusTotal API" FontWeight="Bold" Foreground="#0078D7"/>
                                <Separator/>
                                <MenuItem Name="menuKill" Header="🔪 Tiêu diệt Virus (Xóa vĩnh viễn)" Foreground="Red" FontWeight="Bold" />
                            </ContextMenu>
                        </ListView.ContextMenu>
                        <ListView.View>
                            <GridView>
                                <GridViewColumn Header="Phân vùng" DisplayMemberBinding="{Binding Scope}" Width="80"/>
                                <GridViewColumn Header="Mức độ rủi ro" DisplayMemberBinding="{Binding Status}" Width="190"/>
                                <GridViewColumn Header="Mã Hash (MD5)" DisplayMemberBinding="{Binding Hash}" Width="240"/>
                                <GridViewColumn Header="Tên File" DisplayMemberBinding="{Binding FileName}" Width="180"/>
                                <GridViewColumn Header="Đường dẫn chi tiết" DisplayMemberBinding="{Binding Path}" Width="350"/>
                            </GridView>
                        </ListView.View>
                    </ListView>

                    <TextBlock Name="txtSummary" Grid.Row="1" Text="Thống kê: Chưa quét" FontWeight="Bold" FontSize="14" Foreground="{DynamicResource TextMain}" Margin="5,10,0,0"/>
                </Grid>
            </Border>
        </Grid>
    </Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader $xaml); $window = [Windows.Markup.XamlReader]::Load($reader)
    
    # Ánh xạ Controls
    $btnUpdateDB = $window.FindName("btnUpdateDB"); $btnBrowse = $window.FindName("btnBrowse")
    $txtTarget = $window.FindName("txtTarget"); $btnScan = $window.FindName("btnScan")
    $txtStatus = $window.FindName("txtStatus"); $lstResults = $window.FindName("lstResults")
    $txtSummary = $window.FindName("txtSummary"); $btnTheme = $window.FindName("btnTheme")

    # --- LOGIC DARK MODE ---
    $global:isDarkMode = $false
    $btnTheme.Add_Click({
        $global:isDarkMode = -not $global:isDarkMode
        if ($global:isDarkMode) {
            $window.Resources["WinBg"] = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(24, 26, 27)))
            $window.Resources["CardBg"] = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(36, 39, 42)))
            $window.Resources["TextMain"] = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(232, 230, 227)))
            $window.Resources["TextSub"] = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(160, 165, 170)))
            $window.Resources["BorderCol"] = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(50, 55, 60)))
            $btnTheme.Content = "☀️ Light Mode"
            $btnTheme.Background = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(243, 156, 18)))
        } else {
            $window.Resources["WinBg"] = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(240, 242, 245)))
            $window.Resources["CardBg"] = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(255, 255, 255)))
            $window.Resources["TextMain"] = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(44, 62, 80)))
            $window.Resources["TextSub"] = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(108, 117, 125)))
            $window.Resources["BorderCol"] = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(225, 229, 234)))
            $btnTheme.Content = "🌙 Dark Mode"
            $btnTheme.Background = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(52, 73, 94)))
        }
    })

    # --- SỰ KIỆN CHÍNH ---
    $btnBrowse.Add_Click({
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($dialog.ShowDialog() -eq "OK") { $txtTarget.Text = $dialog.SelectedPath }
    })

    $btnUpdateDB.Add_Click({
        $btnUpdateDB.IsEnabled = $false; $btnScan.IsEnabled = $false
        $dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher
        $act = { param($msg) $dispatcher.Invoke([Action]{ $txtStatus.Text = $msg }) }
        $dispatcher.Invoke([Action]{ Update-LocalDatabase -UpdateStatus $act })
        $btnUpdateDB.IsEnabled = $true; $btnScan.IsEnabled = $true
    })

    $window.FindName("menuVTAPI").Add_Click({
        if ($lstResults.SelectedItem) {
            $obj = $lstResults.SelectedItem
            $txtStatus.Text = "Đang hỏi VirusTotal API..."
            [System.Windows.Forms.Application]::DoEvents()
            $obj.Status = Check-VirusTotalAPI $obj.Hash
            $lstResults.Items.Refresh()
            $txtStatus.Text = "Xong API!"
        }
    })

    $window.FindName("menuKill").Add_Click({ 
        if ($lstResults.SelectedItem -and (Kill-Virus $lstResults.SelectedItem.Path)) { 
            $lstResults.SelectedItem.Status = "💀 ĐÃ TIÊU DIỆT"
            $lstResults.Items.Refresh() 
        } 
    })

    $btnScan.Add_Click({
        $btnScan.IsEnabled = $false; $lstResults.Items.Clear()
        $dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher
        $targets = if ($txtTarget.Text -match "\[Mặc định\]") { $defaultTargetPaths } else { @( @{ Scope="Custom"; Path=$txtTarget.Text } ) }
        
        $actStatus = { param($msg) $dispatcher.Invoke([Action]{ $txtStatus.Text = $msg }) }
        $actRow = { param($obj) $dispatcher.Invoke([Action]{ $lstResults.Items.Add($obj) | Out-Null }) }
        $actDone = { param($c, $dc) 
            $dispatcher.Invoke([Action]{ 
                $txtStatus.Text = "Hoàn tất quét!"
                if ($dc -gt 0) { $txtSummary.Text = "CẢNH BÁO: Phát hiện $dc nguy cơ tiềm ẩn trong $c file!"; $txtSummary.Foreground = "Red" }
                else { $txtSummary.Text = "Tuyệt vời! Không phát hiện nguy hiểm trong $c file quét."; $txtSummary.Foreground = "MediumSeaGreen" }
                $btnScan.IsEnabled = $true 
            }) 
        }
        Start-DeepScan -Targets $targets -UpdateStatusAction $actStatus -AddRowAction $actRow -CompleteAction $actDone
    })
    
    if ($global:LocalHashDB.Count -gt 0) { $txtStatus.Text = "$($global:LocalHashDB.Count) mẫu độc đã nạp." }
    $window.ShowDialog() | Out-Null

} else {
    # ---------------- UI: WinForms (Fallback) ----------------
    $form = New-Object System.Windows.Forms.Form; $form.Text = "Pro Scanner v8 (WinForms Fallback)"; $form.Size = New-Object System.Drawing.Size(1050, 650); $form.StartPosition = "CenterScreen"; $form.BackColor = [System.Drawing.Color]::WhiteSmoke

    # GroupBox 1: Điều khiển
    $gbControl = New-Object System.Windows.Forms.GroupBox; $gbControl.Text = "Bảng Điều Khiển"; $gbControl.Location = New-Object System.Drawing.Point(10, 10); $gbControl.Size = New-Object System.Drawing.Size(1010, 65); $gbControl.Anchor = "Top, Left, Right"
    $btnUpdateDB = New-Object System.Windows.Forms.Button; $btnUpdateDB.Location = New-Object System.Drawing.Point(10, 20); $btnUpdateDB.Size = New-Object System.Drawing.Size(120, 30); $btnUpdateDB.Text = "🔄 Nạp Data"; $btnUpdateDB.BackColor = [System.Drawing.Color]::Teal; $btnUpdateDB.ForeColor = [System.Drawing.Color]::White
    $btnBrowse = New-Object System.Windows.Forms.Button; $btnBrowse.Location = New-Object System.Drawing.Point(140, 20); $btnBrowse.Size = New-Object System.Drawing.Size(100, 30); $btnBrowse.Text = "📂 Chọn..."
    $txtTarget = New-Object System.Windows.Forms.TextBox; $txtTarget.Location = New-Object System.Drawing.Point(250, 25); $txtTarget.Size = New-Object System.Drawing.Size(250, 30); $txtTarget.Text = "[Mặc định] Trọng điểm"; $txtTarget.ReadOnly = $true
    $btnScan = New-Object System.Windows.Forms.Button; $btnScan.Location = New-Object System.Drawing.Point(510, 20); $btnScan.Size = New-Object System.Drawing.Size(120, 30); $btnScan.Text = "🚀 Bắt đầu Quét"; $btnScan.BackColor = [System.Drawing.Color]::Crimson; $btnScan.ForeColor = [System.Drawing.Color]::White
    $lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Location = New-Object System.Drawing.Point(640, 25); $lblStatus.Size = New-Object System.Drawing.Size(350, 20); $lblStatus.Text = "Sẵn sàng..."
    $gbControl.Controls.AddRange(@($btnUpdateDB, $btnBrowse, $txtTarget, $btnScan, $lblStatus))

    # GroupBox 2: Kết quả
    $gbResult = New-Object System.Windows.Forms.GroupBox; $gbResult.Text = "Kết Quả Quét"; $gbResult.Location = New-Object System.Drawing.Point(10, 85); $gbResult.Size = New-Object System.Drawing.Size(1010, 515); $gbResult.Anchor = "Top, Bottom, Left, Right"
    $lstView = New-Object System.Windows.Forms.ListView; $lstView.Location = New-Object System.Drawing.Point(10, 20); $lstView.Size = New-Object System.Drawing.Size(990, 485); $lstView.View = [System.Windows.Forms.View]::Details; $lstView.GridLines = $true; $lstView.FullRowSelect = $true; $lstView.Anchor = "Top, Bottom, Left, Right"
    $lstView.Columns.Add("Phân vùng", 70) | Out-Null; $lstView.Columns.Add("Cảnh báo", 200) | Out-Null; $lstView.Columns.Add("MD5 Hash", 230) | Out-Null; $lstView.Columns.Add("Tên File", 150) | Out-Null; $lstView.Columns.Add("Đường dẫn", 300) | Out-Null
    $gbResult.Controls.Add($lstView)

    $ctxMenu = New-Object System.Windows.Forms.ContextMenuStrip
    $ctxAPI = $ctxMenu.Items.Add("⚡ Check VirusTotal API (Ngầm)"); $ctxAPI.ForeColor = [System.Drawing.Color]::Blue
    $ctxKill = $ctxMenu.Items.Add("🔪 Tiêu diệt (Xóa File)"); $ctxKill.ForeColor = [System.Drawing.Color]::Red
    $lstView.ContextMenuStrip = $ctxMenu

    $ctxAPI.Add_Click({
        if ($lstView.SelectedItems.Count) {
            $item = $lstView.SelectedItems[0]; $lblStatus.Text = "Đang hỏi VirusTotal API..."; [System.Windows.Forms.Application]::DoEvents()
            $item.SubItems[1].Text = Check-VirusTotalAPI $item.SubItems[2].Text; $lblStatus.Text = "Xong API!"
        }
    })
    $ctxKill.Add_Click({ if ($lstView.SelectedItems.Count -and (Kill-Virus $lstView.SelectedItems[0].SubItems[4].Text)) { $lstView.SelectedItems[0].SubItems[1].Text = "💀 ĐÃ TIÊU DIỆT" } })

    $btnUpdateDB.Add_Click({
        $btnUpdateDB.Enabled = $false; $btnScan.Enabled = $false
        Update-LocalDatabase -UpdateStatus { param($msg) $lblStatus.Text = $msg; [System.Windows.Forms.Application]::DoEvents() }
        $btnUpdateDB.Enabled = $true; $btnScan.Enabled = $true
    })

    $btnBrowse.Add_Click({ $d = New-Object System.Windows.Forms.FolderBrowserDialog; if ($d.ShowDialog() -eq "OK") { $txtTarget.Text = $d.SelectedPath } })
    
    $btnScan.Add_Click({
        $btnScan.Enabled = $false; $lstView.Items.Clear()
        $targets = if ($txtTarget.Text -match "\[Mặc định\]") { $defaultTargetPaths } else { @( @{ Scope="Custom"; Path=$txtTarget.Text } ) }
        $actStatus = { param($msg) $lblStatus.Text = $msg; [System.Windows.Forms.Application]::DoEvents() }
        $actRow = { param($obj) 
            $item = New-Object System.Windows.Forms.ListViewItem($obj.Scope)
            $item.SubItems.Add($obj.Status) | Out-Null; $item.SubItems.Add($obj.Hash) | Out-Null; $item.SubItems.Add($obj.FileName) | Out-Null; $item.SubItems.Add($obj.Path) | Out-Null
            if ($obj.Status -match "NHIỄM ĐỘC") { $item.BackColor = [System.Drawing.Color]::LightCoral } elseif ($obj.Status -match "NGHI NGỜ") { $item.BackColor = [System.Drawing.Color]::MistyRose }
            $lstView.Items.Add($item) | Out-Null
            if ($lstView.Items.Count % 5 -eq 0) { [System.Windows.Forms.Application]::DoEvents() }
        }
        $actDone = { param($c, $dc) $lblStatus.Text = "Xong!"; $btnScan.Enabled = $true }
        Start-DeepScan -Targets $targets -UpdateStatusAction $actStatus -AddRowAction $actRow -CompleteAction $actDone
    })

    $form.Controls.AddRange(@($gbControl, $gbResult))
    if ($global:LocalHashDB.Count -gt 0) { $lblStatus.Text = "Đã nạp $($global:LocalHashDB.Count) mã độc vào RAM." }
    $form.ShowDialog() | Out-Null
}
