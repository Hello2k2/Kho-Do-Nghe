# Yêu cầu chạy bằng quyền Admin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Vui lòng chạy Script bằng quyền Administrator!"
    Exit
}

# Load thư viện UI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CẤU HÌNH LÕI & DỮ LIỆU ---
# [BẢO MẬT] API Key VirusTotal đã được mã hóa Base64 (Giấu key)
$encodedVTKey = "M2Y0NDhmZmE2NmU5ODRhYjVlNzRjOWIzOGYyOTJhYmY2YjFiNzI2YmY4N2U1N2Q2YWY4MzgzNjZlMTc2MThiYg=="
$VT_API_KEY = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedVTKey))

$sigcheckUrl = "https://live.sysinternals.com/sigcheck64.exe"
$sigcheckPath = "$env:TEMP\sigcheck64.exe"
$localDbPath = "$env:TEMP\MalwareHashDB.txt"

$global:scanResults = @()
$global:LocalHashDB = New-Object System.Collections.Generic.HashSet[string]

# Tải DB có sẵn từ ổ cứng vào RAM (nếu đã tải trước đó)
if (Test-Path $localDbPath) {
    (Get-Content $localDbPath) | ForEach-Object { if ($_ -match '^[a-fA-F0-9]{32}$') { $global:LocalHashDB.Add($_.ToLower()) | Out-Null } }
}

$defaultTargetPaths = @(
    @{ Scope = "User";   Path = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup" }
    @{ Scope = "User";   Path = "$env:LOCALAPPDATA\Temp" }
    @{ Scope = "System"; Path = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" }
)

# --- HÀM 1: CẬP NHẬT DATABASE OFFLINE ---
function Update-LocalDatabase {
    param([ScriptBlock]$UpdateStatus)
    &$UpdateStatus "Đang tải Database Virus mới nhất (Xin chờ vài giây)..."
    try {
        # Dùng nguồn Abuse.ch
        $dbUrl = "https://bazaar.abuse.ch/export/txt/md5/recent/"
        $response = Invoke-WebRequest -Uri $dbUrl -UseBasicParsing
        
        $lines = $response.Content -split "`n"
        $global:LocalHashDB.Clear()
        $newHashes = @()

        foreach ($line in $lines) {
            $line = $line.Trim()
            if ($line -match '^[a-fA-F0-9]{32}$') {
                $hash = $line.ToLower()
                $global:LocalHashDB.Add($hash) | Out-Null
                $newHashes += $hash
            }
        }
        $newHashes | Out-File -FilePath $localDbPath -Encoding ASCII
        &$UpdateStatus "Cập nhật thành công $( $global:LocalHashDB.Count ) mẫu Virus vào Database Offline!"
    } catch {
        &$UpdateStatus "Lỗi mạng! Không thể tải Database Offline."
    }
}

# --- HÀM 2: LÕI XỬ LÝ QUÉT ---
function Start-DeepScan {
    param([array]$Targets, [ScriptBlock]$UpdateStatusAction, [ScriptBlock]$AddRowAction, [ScriptBlock]$CompleteAction)
    $global:scanResults = @(); $count = 0; $dangerCount = 0

    if (-not (Test-Path $sigcheckPath)) {
        &$UpdateStatusAction "Đang tải Core Sysinternals..."
        try { Invoke-WebRequest -Uri $sigcheckUrl -OutFile $sigcheckPath -UseBasicParsing } catch { return }
    }

    &$UpdateStatusAction "Đang quét và đối chiếu Database..."

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
                    
                    if ($hashMD5 -ne "N/A" -and $global:LocalHashDB.Contains($hashMD5)) {
                        $status = "💀 NHIỄM ĐỘC (Local DB)!"
                        $dangerCount++
                    } 
                    elseif ($isRun) {
                        if ($row."Verified" -eq "Signed") { $status = "✅ An toàn" } 
                        else { $status = "❌ NGHI NGỜ (Không chữ ký)"; $dangerCount++ }
                    }

                    $resultObj = [pscustomobject]@{
                        Scope = $target.Scope; Status = $status; FileType = $ext; 
                        Hash = $row.MD5; Publisher = $row.Publisher; FileName = Split-Path $row.Path -Leaf; Path = $row.Path
                    }
                    $global:scanResults += $resultObj
                    &$AddRowAction $resultObj
                }
            }
        }
    }
    &$CompleteAction $count $dangerCount
}

# --- HÀM 3: GỌI API VIRUSTOTAL ---
function Check-VirusTotalAPI ($hash) {
    if ([string]::IsNullOrWhiteSpace($VT_API_KEY)) {
        [System.Windows.Forms.MessageBox]::Show("Lỗi giải mã API Key!", "Thiếu API Key", 0, 48) | Out-Null
        return "Lỗi API Key"
    }
    try {
        $headers = @{ "x-apikey" = $VT_API_KEY }
        $url = "https://www.virustotal.com/api/v3/files/$hash"
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get -ErrorAction Stop
        
        $stats = $response.data.attributes.last_analysis_stats
        $malicious = $stats.malicious
        $total = $stats.malicious + $stats.undetected + $stats.harmless
        
        if ($malicious -gt 0) { return "🚨 Phát hiện: $malicious/$total hãng báo độc!" }
        else { return "✅ Sạch: 0/$total hãng báo độc" }
    } catch {
        return "⚠️ Chưa có trên VirusTotal"
    }
}

function Kill-Virus ($filePath) {
    if ([System.Windows.Forms.MessageBox]::Show("Xóa VĨNH VIỄN file này?", "Cảnh báo", 4, 48) -eq "Yes") {
        try { Remove-Item -Path $filePath -Force -ErrorAction Stop; return $true } catch { return $false }
    }
    return $false
}

# ==========================================
# --- KHỞI TẠO GIAO DIỆN (WPF / WinForms) ---
# ==========================================
$useWPF = $true
try { Add-Type -AssemblyName PresentationFramework -ErrorAction Stop } catch { $useWPF = $false }

if ($useWPF) {
    [xml]$xaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="Pro Scanner v7.1 (Secure Key)" Height="650" Width="1100" Background="#f4f6f9">
        <Grid Margin="15">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/> <RowDefinition Height="*"/> <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <TextBlock Text="Bộ Quét Tối Thượng v7.1 (Bảo mật API Key)" FontWeight="Bold" FontSize="18" Foreground="#2c3e50" Margin="0,0,0,15"/>
            
            <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,0,0,15">
                <Button Name="btnUpdateDB" Content="🔄 Cập nhật Data" Width="120" Height="32" Background="#17a2b8" Foreground="White" FontWeight="Bold" Margin="0,0,10,0"/>
                <Button Name="btnBrowse" Content="📂 Chọn thư mục..." Width="120" Height="32" Margin="0,0,10,0" Background="#e2e6ea"/>
                <TextBox Name="txtTarget" Width="200" Height="32" VerticalContentAlignment="Center" Text="[Mặc định] Trọng điểm" IsReadOnly="True" Margin="0,0,10,0"/>
                <Button Name="btnScan" Content="🚀 Bắt đầu Quét" Width="120" Height="32" Background="#dc3545" Foreground="White" FontWeight="Bold"/>
                <TextBlock Name="txtStatus" Text="Sẵn sàng..." Margin="15,7,0,0" FontStyle="Italic" Foreground="#6c757d"/>
            </StackPanel>

            <ListView Name="lstResults" Grid.Row="2" Background="White">
                <ListView.ContextMenu>
                    <ContextMenu>
                        <MenuItem Name="menuVTAPI" Header="⚡ Check VirusTotal API (Ngầm)" FontWeight="Bold" Foreground="Blue"/>
                        <Separator/>
                        <MenuItem Name="menuKill" Header="🔪 Tiêu diệt (Xóa File)" Foreground="Red" FontWeight="Bold" />
                    </ContextMenu>
                </ListView.ContextMenu>
                <ListView.View>
                    <GridView>
                        <GridViewColumn Header="Scope" DisplayMemberBinding="{Binding Scope}" Width="70"/>
                        <GridViewColumn Header="Cảnh báo" DisplayMemberBinding="{Binding Status}" Width="200"/>
                        <GridViewColumn Header="MD5 Hash" DisplayMemberBinding="{Binding Hash}" Width="230"/>
                        <GridViewColumn Header="Tên File" DisplayMemberBinding="{Binding FileName}" Width="160"/>
                        <GridViewColumn Header="Đường dẫn" DisplayMemberBinding="{Binding Path}" Width="350"/>
                    </GridView>
                </ListView.View>
            </ListView>
            <TextBlock Name="txtSummary" Grid.Row="3" FontWeight="Bold" FontSize="14" Margin="0,15,0,0"/>
        </Grid>
    </Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader $xaml); $window = [Windows.Markup.XamlReader]::Load($reader)
    $btnUpdateDB = $window.FindName("btnUpdateDB"); $btnScan = $window.FindName("btnScan")
    $txtStatus = $window.FindName("txtStatus"); $lstResults = $window.FindName("lstResults")

    $window.FindName("btnBrowse").Add_Click({
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($dialog.ShowDialog() -eq "OK") { $window.FindName("txtTarget").Text = $dialog.SelectedPath }
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
            $txtStatus.Text = "Đang hỏi VirusTotal API cho mã $($obj.Hash)..."
            [System.Windows.Forms.Application]::DoEvents()
            $obj.Status = Check-VirusTotalAPI $obj.Hash
            $lstResults.Items.Refresh()
            $txtStatus.Text = "Check API hoàn tất!"
        }
    })

    $window.FindName("menuKill").Add_Click({ 
        if ($lstResults.SelectedItem -and (Kill-Virus $lstResults.SelectedItem.Path)) { 
            $lstResults.SelectedItem.Status = "💀 ĐÃ TIÊU DIỆT"; $lstResults.Items.Refresh() 
        } 
    })

    $btnScan.Add_Click({
        $btnScan.IsEnabled = $false; $lstResults.Items.Clear()
        $dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher
        $targets = if ($window.FindName("txtTarget").Text -match "\[Mặc định\]") { $defaultTargetPaths } else { @( @{ Scope="Custom"; Path=$window.FindName("txtTarget").Text } ) }
        $actStatus = { param($msg) $dispatcher.Invoke([Action]{ $txtStatus.Text = $msg }) }
        $actRow = { param($obj) $dispatcher.Invoke([Action]{ $lstResults.Items.Add($obj) | Out-Null }) }
        $actDone = { param($c, $dc) $dispatcher.Invoke([Action]{ $txtStatus.Text = "Xong!"; $btnScan.IsEnabled = $true }) }
        Start-DeepScan -Targets $targets -UpdateStatusAction $actStatus -AddRowAction $actRow -CompleteAction $actDone
    })
    
    if ($global:LocalHashDB.Count -gt 0) { $txtStatus.Text = "Đã nạp $($global:LocalHashDB.Count) mã độc vào RAM." }
    $window.ShowDialog() | Out-Null

} else {
    # ---------------- UI: WinForms ----------------
    $form = New-Object System.Windows.Forms.Form; $form.Text = "Pro Scanner v7.1 (WinForms)"; $form.Size = New-Object System.Drawing.Size(1050, 600); $form.StartPosition = "CenterScreen"
    $btnUpdateDB = New-Object System.Windows.Forms.Button; $btnUpdateDB.Location = New-Object System.Drawing.Point(10, 10); $btnUpdateDB.Size = New-Object System.Drawing.Size(110, 30); $btnUpdateDB.Text = "🔄 Cập nhật Data"; $btnUpdateDB.BackColor = [System.Drawing.Color]::Teal; $btnUpdateDB.ForeColor = [System.Drawing.Color]::White
    $btnBrowse = New-Object System.Windows.Forms.Button; $btnBrowse.Location = New-Object System.Drawing.Point(130, 10); $btnBrowse.Size = New-Object System.Drawing.Size(100, 30); $btnBrowse.Text = "📂 Chọn..."
    $txtTarget = New-Object System.Windows.Forms.TextBox; $txtTarget.Location = New-Object System.Drawing.Point(240, 15); $txtTarget.Size = New-Object System.Drawing.Size(180, 30); $txtTarget.Text = "[Mặc định] Trọng điểm"; $txtTarget.ReadOnly = $true
    $btnScan = New-Object System.Windows.Forms.Button; $btnScan.Location = New-Object System.Drawing.Point(430, 10); $btnScan.Size = New-Object System.Drawing.Size(100, 30); $btnScan.Text = "🚀 Bắt đầu"; $btnScan.BackColor = [System.Drawing.Color]::Crimson; $btnScan.ForeColor = [System.Drawing.Color]::White
    
    $lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Location = New-Object System.Drawing.Point(540, 15); $lblStatus.Size = New-Object System.Drawing.Size(400, 20); $lblStatus.Text = "Sẵn sàng..."
    if ($global:LocalHashDB.Count -gt 0) { $lblStatus.Text = "Đã nạp $($global:LocalHashDB.Count) mã độc vào RAM." }

    $lstView = New-Object System.Windows.Forms.ListView; $lstView.Location = New-Object System.Drawing.Point(10, 50); $lstView.Size = New-Object System.Drawing.Size(1010, 480); $lstView.View = [System.Windows.Forms.View]::Details; $lstView.GridLines = $true; $lstView.FullRowSelect = $true; $lstView.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $lstView.Columns.Add("Scope", 70) | Out-Null; $lstView.Columns.Add("Cảnh báo", 200) | Out-Null; $lstView.Columns.Add("MD5 Hash", 230) | Out-Null; $lstView.Columns.Add("Tên File", 150) | Out-Null; $lstView.Columns.Add("Đường dẫn", 300) | Out-Null

    $ctxMenu = New-Object System.Windows.Forms.ContextMenuStrip
    $ctxAPI = $ctxMenu.Items.Add("⚡ Check VirusTotal API (Ngầm)"); $ctxAPI.ForeColor = [System.Drawing.Color]::Blue
    $ctxMenu.Items.Add("-") | Out-Null
    $ctxKill = $ctxMenu.Items.Add("🔪 Tiêu diệt (Xóa File)"); $ctxKill.ForeColor = [System.Drawing.Color]::Red
    $lstView.ContextMenuStrip = $ctxMenu

    $ctxAPI.Add_Click({
        if ($lstView.SelectedItems.Count) {
            $item = $lstView.SelectedItems[0]
            $lblStatus.Text = "Đang hỏi VirusTotal API..."; [System.Windows.Forms.Application]::DoEvents()
            $item.SubItems[1].Text = Check-VirusTotalAPI $item.SubItems[2].Text
            $lblStatus.Text = "Check API hoàn tất!"
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

    $form.Controls.AddRange(@($btnUpdateDB, $btnBrowse, $txtTarget, $btnScan, $lblStatus, $lstView))
    $form.ShowDialog() | Out-Null
}
