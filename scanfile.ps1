# Yêu cầu quyền Admin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Vui lòng chạy Script bằng quyền Administrator!"
    Exit
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# --- CẤU HÌNH HỆ THỐNG ---
$tempDir = "$env:TEMP\DeepScanner"
if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir | Out-Null }

$sigcheckUrl = "https://live.sysinternals.com/sigcheck64.exe"
$sigcheckPath = "$tempDir\sigcheck64.exe"

# Cấu hình ClamAV
$clamavUrl = "https://www.clamav.net/downloads/production/clamav-1.4.1.win.x64.zip"
$clamavZip = "$tempDir\clamav.zip"
$clamavDir = "$tempDir\ClamAV"
$clamscan = "$clamavDir\clamscan.exe"
$freshclam = "$clamavDir\freshclam.exe"

$defaultTargetPaths = @(
    @{ Scope = "User";   Path = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup" }
    @{ Scope = "User";   Path = "$env:LOCALAPPDATA\Temp" }
    @{ Scope = "System"; Path = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" }
    @{ Scope = "System"; Path = "$env:WINDIR\Temp" }
)

# --- HÀM CLAMAV & VIRUSTOTAL API ---
function Setup-ClamAV {
    param([ScriptBlock]$StatusUpdate)
    
    if (-not (Test-Path $freshclam)) {
        &$StatusUpdate "Đang tải Core ClamAV (Khoảng 20MB)..."
        try { Invoke-WebRequest -Uri $clamavUrl -OutFile $clamavZip -UseBasicParsing } catch { return $false }
        &$StatusUpdate "Đang giải nén ClamAV..."
        Expand-Archive -Path $clamavZip -DestinationPath $clamavDir -Force
        
        # Di chuyển file từ thư mục con ra ngoài
        $subDir = Get-ChildItem $clamavDir -Directory | Select-Object -First 1
        if ($subDir) { Move-Item -Path "$($subDir.FullName)\*" -Destination $clamavDir -Force }
    }
    
    # Tạo file config cho FreshClam
    $confPath = "$clamavDir\freshclam.conf"
    "DatabaseDirectory $clamavDir\database" | Out-File $confPath -Encoding ASCII
    "DatabaseMirror database.clamav.net" | Out-File -Append $confPath -Encoding ASCII
    "UpdateLogFile $clamavDir\freshclam.log" | Out-File -Append $confPath -Encoding ASCII
    
    if (-not (Test-Path "$clamavDir\database")) { New-Item -ItemType Directory -Path "$clamavDir\database" | Out-Null }
    
    &$StatusUpdate "Đang mở Console tải Database ClamAV (Vui lòng đợi Console chạy xong)..."
    # Mở cửa sổ riêng để tải DB (vì tải rất lâu và hiển thị phần trăm)
    Start-Process -FilePath $freshclam -ArgumentList "--config-file=""$confPath""" -Wait
    
    &$StatusUpdate "Sẵn sàng quét!"
    return $true
}

function Get-VTAPI ($hash, $apiKey) {
    if ([string]::IsNullOrWhiteSpace($apiKey)) { return "Thiếu API Key!" }
    $headers = @{ "x-apikey" = $apiKey }
    try {
        $resp = Invoke-RestMethod -Uri "https://www.virustotal.com/api/v3/files/$hash" -Headers $headers -Method Get -ErrorAction Stop
        $res = $resp.data.attributes.last_analysis_results
        $kas = if ($res.Kaspersky.category -eq "malicious") { "Kas: NGUY HIỂM" } else { "Kas: Sạch" }
        $bit = if ($res.BitDefender.category -eq "malicious") { "Bit: NGUY HIỂM" } else { "Bit: Sạch" }
        return "$kas | $bit"
    } catch { return "API Lỗi / Chưa có Data" }
}

# --- HÀM LÕI QUÉT ---
function Start-DeepScan {
    param([array]$Targets, [ScriptBlock]$UpdateStatusAction, [ScriptBlock]$AddRowAction, [ScriptBlock]$CompleteAction)

    $count = 0; $dangerCount = 0

    if (-not (Test-Path $sigcheckPath)) {
        &$UpdateStatusAction "Đang tải Sigcheck Core..."
        Invoke-WebRequest -Uri $sigcheckUrl -OutFile $sigcheckPath -UseBasicParsing
    }

    &$UpdateStatusAction "Đang cày nát ổ đĩa (Sigcheck + ClamAV nếu có)..."
    $hasClamAV = (Test-Path "$clamavDir\database\main.cvd")

    foreach ($target in $Targets) {
        if (Test-Path $target.Path) {
            # Bật cờ -v và -vt để check Hash tự động với VirusTotal (EULA tự động accept)
            $sigOutput = & $sigcheckPath -accepteula -c -h -v -vt -s $target.Path 2>$null
            if ($sigOutput -and $sigOutput.Count -gt 1) {
                $csvData = $sigOutput | ConvertFrom-Csv -Delimiter ","
                foreach ($row in $csvData) {
                    if ([string]::IsNullOrWhiteSpace($row.Path)) { continue }
                    $count++
                    $ext = [System.IO.Path]::GetExtension($row.Path).ToLower()
                    $isRun = ($ext -match "\.(exe|dll|sys|bat|vbs|ps1|js|scr|com)$")
                    $fileType = if ($isRun) { "Thực thi/Script" } else { "Khác" }

                    $status = ""
                    $vtScore = if ($row."VT detection") { $row."VT detection" } else { "0/0" }

                    if ($isRun) {
                        if ($row.Verified -eq "Signed" -and $row.Publisher -match "Microsoft|Google|Intel|NVIDIA|AMD") {
                            $status = "✅ An toàn"
                        } else {
                            $status = "❌ NGUY HIỂM"
                            $dangerCount++
                            
                            # Nếu là file Nguy hiểm + Đã cài ClamAV -> Đem chém qua ClamAV
                            if ($hasClamAV) {
                                $clamOut = & $clamscan -d "$clamavDir\database" $row.Path 2>&1
                                if ($clamOut -match "FOUND") { $status = "💀 CLAMAV PHÁT HIỆN VIRUS!" }
                            }
                        }
                    } else { $status = "🔵 Ít rủi ro" }

                    $hashMD5 = if ($row.MD5) { $row.MD5 } else { "N/A" }
                    &$AddRowAction [pscustomobject]@{
                        Scope = $target.Scope; Status = $status; VTScore = $vtScore
                        FileType = $fileType; Hash = $hashMD5; Path = $row.Path
                    }
                }
            }
        }
    }
    &$CompleteAction $count $dangerCount
}

# --- GIAO DIỆN WPF ---
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="Deep Scanner v7 (CyberSec Edition)" Height="700" Width="1200" Background="#f4f6f9">
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/> <RowDefinition Height="*"/> <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <TextBlock Text="Bộ Quét Chuyên Sâu v7 (Tích hợp Sigcheck + ClamAV + VirusTotal API)" FontWeight="Bold" FontSize="18" Foreground="#2c3e50" Margin="0,0,0,10"/>
        
        <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,0,0,15" Background="#e9ecef" >
            <TextBlock Text="VT API Key:" VerticalAlignment="Center" Margin="5,0,5,0" FontWeight="Bold"/>
            <TextBox Name="txtApiKey" Width="250" Height="28" Margin="0,0,15,0" VerticalContentAlignment="Center"/>
            <Button Name="btnUpdateClam" Content="🔄 Tải &amp; Cập nhật Data ClamAV" Width="200" Height="30" Background="#17a2b8" Foreground="White" FontWeight="Bold" BorderThickness="0"/>
        </StackPanel>

        <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="0,0,0,15">
            <Button Name="btnBrowse" Content="📂 Chọn thư mục..." Width="120" Height="32" Margin="0,0,10,0"/>
            <TextBox Name="txtTarget" Width="280" Height="32" VerticalContentAlignment="Center" Text="[Mặc định] Các vùng trọng điểm" IsReadOnly="True" Margin="0,0,10,0"/>
            <Button Name="btnScan" Content="🚀 Bắt đầu Quét" Width="130" Height="32" Background="#dc3545" Foreground="White" FontWeight="Bold" BorderThickness="0"/>
            <TextBlock Name="txtStatus" Text="Sẵn sàng quét..." Margin="15,7,0,0" FontStyle="Italic" Foreground="#6c757d"/>
        </StackPanel>

        <ListView Name="lstResults" Grid.Row="3" Background="White" BorderBrush="#ced4da" BorderThickness="1">
            <ListView.ContextMenu>
                <ContextMenu>
                    <MenuItem Name="menuAPI" Header="🤖 Check API (Kaspersky/Bitdefender)" FontWeight="Bold" Foreground="Blue"/>
                    <Separator/>
                    <MenuItem Name="menuOpen" Header="📂 Mở thư mục chứa file" />
                    <MenuItem Name="menuKill" Header="🔪 Tiêu diệt (Xóa File)" Foreground="Red" FontWeight="Bold" />
                </ContextMenu>
            </ListView.ContextMenu>
            <ListView.View>
                <GridView>
                    <GridViewColumn Header="Cảnh báo" DisplayMemberBinding="{Binding Status}" Width="180"/>
                    <GridViewColumn Header="VT Điểm" DisplayMemberBinding="{Binding VTScore}" Width="70"/>
                    <GridViewColumn Header="Scope" DisplayMemberBinding="{Binding Scope}" Width="70"/>
                    <GridViewColumn Header="Loại File" DisplayMemberBinding="{Binding FileType}" Width="100"/>
                    <GridViewColumn Header="MD5 Hash" DisplayMemberBinding="{Binding Hash}" Width="230"/>
                    <GridViewColumn Header="Đường dẫn" DisplayMemberBinding="{Binding Path}" Width="350"/>
                </GridView>
            </ListView.View>
        </ListView>
        <TextBlock Name="txtSummary" Grid.Row="4" FontWeight="Bold" FontSize="14" Margin="0,15,0,0"/>
    </Grid>
</Window>
"@
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$btnBrowse = $window.FindName("btnBrowse"); $txtTarget = $window.FindName("txtTarget")
$btnScan = $window.FindName("btnScan"); $txtStatus = $window.FindName("txtStatus")
$lstResults = $window.FindName("lstResults"); $txtSummary = $window.FindName("txtSummary")
$btnUpdateClam = $window.FindName("btnUpdateClam"); $txtApiKey = $window.FindName("txtApiKey")

# Nút cập nhật ClamAV
$btnUpdateClam.Add_Click({
    $btnUpdateClam.IsEnabled = $false
    $dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher
    $actStatus = { param($msg) $dispatcher.Invoke([Action]{ $txtStatus.Text = $msg }) }
    
    # Chạy Setup
    if (Setup-ClamAV -StatusUpdate $actStatus) {
        [System.Windows.Forms.MessageBox]::Show("Cập nhật Database ClamAV hoàn tất! Lần quét tiếp theo sẽ tự động dùng thêm ClamAV.", "Thành công", 0, 64) | Out-Null
    }
    $btnUpdateClam.IsEnabled = $true
})

# Chuột phải -> VT API
$window.FindName("menuAPI").Add_Click({
    if ($lstResults.SelectedItem) {
        $obj = $lstResults.SelectedItem
        $txtStatus.Text = "Đang gọi API VirusTotal cho $($obj.Hash)..."
        $apiResult = Get-VTAPI -hash $obj.Hash -apiKey $txtApiKey.Text
        $obj.Status = "[$apiResult] " + $obj.Status
        $lstResults.Items.Refresh()
        $txtStatus.Text = "Check API hoàn tất!"
    }
})

# Chuột phải -> Open & Kill
$window.FindName("menuOpen").Add_Click({ if ($lstResults.SelectedItem) { explorer.exe /select, "$($lstResults.SelectedItem.Path)" } })
$window.FindName("menuKill").Add_Click({ 
    if ($lstResults.SelectedItem) { 
        $obj = $lstResults.SelectedItem
        if ([System.Windows.Forms.MessageBox]::Show("Xóa file này?", "Cảnh báo", 4, 48) -eq "Yes") {
            try { Remove-Item $obj.Path -Force; $obj.Status = "💀 ĐÃ XÓA"; $lstResults.Items.Refresh() } catch {}
        }
    } 
})

$btnBrowse.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $txtTarget.Text = $dialog.SelectedPath }
})

$btnScan.Add_Click({
    $btnScan.IsEnabled = $false; $lstResults.Items.Clear(); $txtSummary.Text = ""
    $dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher
    $targetsToScan = if ($txtTarget.Text -match "\[Mặc định\]") { $defaultTargetPaths } else { @( @{ Scope="Custom"; Path=$txtTarget.Text } ) }

    $actStatus = { param($msg) $dispatcher.Invoke([Action]{ $txtStatus.Text = $msg }) }
    $actRow = { param($obj) $dispatcher.Invoke([Action]{ $lstResults.Items.Add($obj) | Out-Null }) }
    $actDone = { param($c, $dc)
        $dispatcher.Invoke([Action]{
            $txtStatus.Text = "Hoàn tất quét $c file."
            if ($dc -gt 0) { $txtSummary.Text = "Phát hiện $dc file NGUY HIỂM!"; $txtSummary.Foreground = "Red" } else { $txtSummary.Text = "An toàn."; $txtSummary.Foreground = "Green" }
            $btnScan.IsEnabled = $true
        })
    }
    Start-DeepScan -Targets $targetsToScan -UpdateStatusAction $actStatus -AddRowAction $actRow -CompleteAction $actDone
})

$window.ShowDialog() | Out-Null
