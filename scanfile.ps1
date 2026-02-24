# Yêu cầu chạy bằng quyền Admin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Vui lòng chạy Script bằng quyền Administrator!"
    Exit
}

# Load thư viện UI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CẤU HÌNH LÕI & DỮ LIỆU ---
$sigcheckUrl = "https://live.sysinternals.com/sigcheck64.exe"
$sigcheckPath = "$env:TEMP\sigcheck64.exe"

$defaultTargetPaths = @(
    @{ Scope = "User";   Path = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup" }
    @{ Scope = "User";   Path = "$env:LOCALAPPDATA\Temp" }
    @{ Scope = "System"; Path = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" }
    @{ Scope = "System"; Path = "$env:WINDIR\Temp" }
)

# --- HÀM LÕI XỬ LÝ QUÉT ---
function Start-DeepScan {
    param(
        [array]$Targets,
        [ScriptBlock]$UpdateStatusAction,
        [ScriptBlock]$AddRowAction,
        [ScriptBlock]$CompleteAction
    )

    $count = 0
    $dangerCount = 0

    if (-not (Test-Path $sigcheckPath)) {
        &$UpdateStatusAction "Đang tải Core Sysinternals..."
        try { Invoke-WebRequest -Uri $sigcheckUrl -OutFile $sigcheckPath -UseBasicParsing } 
        catch { &$UpdateStatusAction "Lỗi mạng! Không thể tải Core."; &$CompleteAction 0 0; return }
    }

    &$UpdateStatusAction "Đang quét và băm Hash..."

    foreach ($target in $Targets) {
        $path = $target.Path
        $scope = $target.Scope

        if (Test-Path $path) {
            $sigOutput = & $sigcheckPath -accepteula -c -h -s $path 2>$null
            if ($sigOutput -and $sigOutput.Count -gt 1) {
                $csvData = $sigOutput | ConvertFrom-Csv -Delimiter ","
                foreach ($row in $csvData) {
                    # [FIX LỖI SPLIT-PATH]: Bỏ qua nếu dòng này không có Path
                    if ([string]::IsNullOrWhiteSpace($row.Path)) { continue }

                    $count++
                    $ext = [System.IO.Path]::GetExtension($row.Path).ToLower()
                    $fileType = "Khác"
                    $isRun = $false

                    if ($ext -match "\.(exe|dll|sys|ocx|bin|scr|com|cpl|msc)$") { $fileType = "Thực thi (PE)"; $isRun = $true } 
                    elseif ($ext -match "\.(bat|cmd|vbs|ps1|js|wsf|hta|py|sh|psm1)$") { $fileType = "Script/Code"; $isRun = $true } 
                    elseif ($ext -match "\.(zip|rar|7z|tar|iso|cab|gz)$") { $fileType = "File Nén" } 
                    elseif ($ext -match "\.(doc|docx|xls|xlsx|pdf|ppt|pptx|rtf)$") { $fileType = "Tài liệu (Office/PDF)" } 
                    elseif ($ext -match "\.(txt|log|ini|cfg|xml|json|yaml|md)$") { $fileType = "Văn bản/Cấu hình" } 
                    elseif ($ext -match "\.(jpg|png|gif|mp4|mp3|wav|avi|mkv)$") { $fileType = "Đa phương tiện" }
                    elseif ($ext -match "\.(db|sqlite|sql|mdb)$") { $fileType = "Database" }

                    $publisher = $row.Publisher
                    $status = ""

                    if ($isRun) {
                        if ($row."Verified" -eq "Signed" -and $publisher -match "Microsoft|Google|Intel|NVIDIA|AMD|VMware|Apple") {
                            $status = "✅ An toàn (Trust)"
                        } elseif ($row."Verified" -eq "Signed") {
                            $status = "⚠️ An toàn (Khác)"
                        } else {
                            $status = "❌ NGUY HIỂM!"
                            $dangerCount++
                        }
                    } else {
                        $status = "🔵 Ít rủi ro"
                    }

                    $hashMD5 = if ($row.MD5) { $row.MD5 } else { "N/A" }
                    $pub = if([string]::IsNullOrWhiteSpace($publisher)) { "---" } else { $publisher }
                    $fileName = Split-Path $row.Path -Leaf

                    &$AddRowAction $scope $status $fileType $hashMD5 $pub $fileName $row.Path
                }
            }
        }
    }
    &$CompleteAction $count $dangerCount
}

# ==========================================
# --- KIỂM TRA & KHỞI TẠO GIAO DIỆN (UI) ---
# ==========================================
$useWPF = $true
try { Add-Type -AssemblyName PresentationFramework -ErrorAction Stop } 
catch { $useWPF = $false }

if ($useWPF) {
    # ---------------- UI: WPF ----------------
    [xml]$xaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="Deep Scanner v5 (Custom Folder)" Height="600" Width="1050" Background="#f8f9fa">
        <Grid Margin="10">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/> <RowDefinition Height="*"/> <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <TextBlock Text="Bộ Quét Chuyên Sâu v5 (Hỗ trợ chọn thư mục tuỳ ý)" FontWeight="Bold" FontSize="16" Margin="0,0,0,10"/>
            <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,0,0,10">
                <Button Name="btnBrowse" Content="Chọn thư mục..." Width="100" Height="30" Margin="0,0,10,0"/>
                <TextBox Name="txtTarget" Width="250" Height="30" VerticalContentAlignment="Center" Text="[Mặc định] Các vùng trọng điểm" IsReadOnly="True" Margin="0,0,10,0" Background="#eee"/>
                <Button Name="btnScan" Content="Bắt đầu Quét" Width="120" Height="30" Background="#DC3545" Foreground="White" FontWeight="Bold"/>
                <TextBlock Name="txtStatus" Text="Sẵn sàng..." Margin="15,5,0,0" FontStyle="Italic" Foreground="#555"/>
            </StackPanel>
            <ListView Name="lstResults" Grid.Row="2" Background="White">
                <ListView.View>
                    <GridView>
                        <GridViewColumn Header="Scope" DisplayMemberBinding="{Binding Scope}" Width="80"/>
                        <GridViewColumn Header="Cảnh báo" DisplayMemberBinding="{Binding Status}" Width="140"/>
                        <GridViewColumn Header="Loại File" DisplayMemberBinding="{Binding FileType}" Width="120"/>
                        <GridViewColumn Header="MD5 Hash" DisplayMemberBinding="{Binding Hash}" Width="230"/>
                        <GridViewColumn Header="Nhà phát hành" DisplayMemberBinding="{Binding Publisher}" Width="120"/>
                        <GridViewColumn Header="Tên File" DisplayMemberBinding="{Binding FileName}" Width="150"/>
                        <GridViewColumn Header="Đường dẫn" DisplayMemberBinding="{Binding Path}" Width="200"/>
                    </GridView>
                </ListView.View>
            </ListView>
            <TextBlock Name="txtSummary" Grid.Row="3" FontWeight="Bold" Margin="0,10,0,0"/>
        </Grid>
    </Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $btnBrowse = $window.FindName("btnBrowse"); $txtTarget = $window.FindName("txtTarget")
    $btnScan = $window.FindName("btnScan"); $txtStatus = $window.FindName("txtStatus")
    $lstResults = $window.FindName("lstResults"); $txtSummary = $window.FindName("txtSummary")

    # Sự kiện chọn thư mục
    $btnBrowse.Add_Click({
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "Chọn thư mục bạn muốn quét mã độc"
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtTarget.Text = $dialog.SelectedPath
        }
    })

    $btnScan.Add_Click({
        $btnScan.IsEnabled = $false; $btnBrowse.IsEnabled = $false
        $lstResults.Items.Clear(); $txtSummary.Text = ""
        $dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher

        $targetsToScan = @()
        if ($txtTarget.Text -match "\[Mặc định\]") { $targetsToScan = $defaultTargetPaths } 
        else { $targetsToScan = @( @{ Scope = "Custom"; Path = $txtTarget.Text } ) }

        $actStatus = { param($msg) $dispatcher.Invoke([Action]{ $txtStatus.Text = $msg }) }
        $actRow = { param($sc, $st, $ft, $hs, $pb, $fn, $pt) 
            $dispatcher.Invoke([Action]{
                $lstResults.Items.Add([pscustomobject]@{Scope=$sc; Status=$st; FileType=$ft; Hash=$hs; Publisher=$pb; FileName=$fn; Path=$pt}) | Out-Null
            })
        }
        $actDone = { param($c, $dc)
            $dispatcher.Invoke([Action]{
                $txtStatus.Text = "Hoàn tất quét $c file."
                if ($dc -gt 0) { $txtSummary.Text = "Phát hiện $dc file NGUY HIỂM!"; $txtSummary.Foreground = "Red" } 
                else { $txtSummary.Text = "Hệ thống an toàn."; $txtSummary.Foreground = "Green" }
                $btnScan.IsEnabled = $true; $btnBrowse.IsEnabled = $true
            })
        }
        
        Start-DeepScan -Targets $targetsToScan -UpdateStatusAction $actStatus -AddRowAction $actRow -CompleteAction $actDone
    })
    $window.ShowDialog() | Out-Null

} else {
    # ---------------- UI: WinForms (Dự phòng) ----------------
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Deep Scanner v5 (WinForms - Fallback)"
    $form.Size = New-Object System.Drawing.Size(1050, 600)
    $form.StartPosition = "CenterScreen"

    $btnBrowse = New-Object System.Windows.Forms.Button
    $btnBrowse.Location = New-Object System.Drawing.Point(10, 10)
    $btnBrowse.Size = New-Object System.Drawing.Size(100, 30)
    $btnBrowse.Text = "Chọn thư mục..."

    $txtTarget = New-Object System.Windows.Forms.TextBox
    $txtTarget.Location = New-Object System.Drawing.Point(120, 15)
    $txtTarget.Size = New-Object System.Drawing.Size(250, 30)
    $txtTarget.Text = "[Mặc định] Các vùng trọng điểm"
    $txtTarget.ReadOnly = $true

    $btnScan = New-Object System.Windows.Forms.Button
    $btnScan.Location = New-Object System.Drawing.Point(380, 10)
    $btnScan.Size = New-Object System.Drawing.Size(100, 30)
    $btnScan.Text = "Bắt đầu Quét"
    $btnScan.BackColor = [System.Drawing.Color]::Crimson
    $btnScan.ForeColor = [System.Drawing.Color]::White

    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Location = New-Object System.Drawing.Point(490, 15)
    $lblStatus.Size = New-Object System.Drawing.Size(400, 20)
    $lblStatus.Text = "Sẵn sàng (Đang chạy chế độ WinForms)..."

    $lstView = New-Object System.Windows.Forms.ListView
    $lstView.Location = New-Object System.Drawing.Point(10, 50)
    $lstView.Size = New-Object System.Drawing.Size(1010, 480)
    $lstView.View = [System.Windows.Forms.View]::Details
    $lstView.GridLines = $true; $lstView.FullRowSelect = $true
    $lstView.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

    $lstView.Columns.Add("Scope", 70) | Out-Null; $lstView.Columns.Add("Cảnh báo", 120) | Out-Null
    $lstView.Columns.Add("Loại File", 120) | Out-Null; $lstView.Columns.Add("MD5 Hash", 230) | Out-Null
    $lstView.Columns.Add("Nhà phát hành", 120) | Out-Null; $lstView.Columns.Add("Tên File", 150) | Out-Null; $lstView.Columns.Add("Đường dẫn", 200) | Out-Null

    $form.Controls.AddRange(@($btnBrowse, $txtTarget, $btnScan, $lblStatus, $lstView))

    $btnBrowse.Add_Click({
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $txtTarget.Text = $dialog.SelectedPath }
    })

    $btnScan.Add_Click({
        $btnScan.Enabled = $false; $btnBrowse.Enabled = $false; $lstView.Items.Clear()

        $targetsToScan = @()
        if ($txtTarget.Text -match "\[Mặc định\]") { $targetsToScan = $defaultTargetPaths } 
        else { $targetsToScan = @( @{ Scope = "Custom"; Path = $txtTarget.Text } ) }

        $actStatus = { param($msg) $lblStatus.Text = $msg; [System.Windows.Forms.Application]::DoEvents() }
        $actRow = { param($sc, $st, $ft, $hs, $pb, $fn, $pt) 
            $item = New-Object System.Windows.Forms.ListViewItem($sc)
            $item.SubItems.Add($st) | Out-Null; $item.SubItems.Add($ft) | Out-Null
            $item.SubItems.Add($hs) | Out-Null; $item.SubItems.Add($pb) | Out-Null
            $item.SubItems.Add($fn) | Out-Null; $item.SubItems.Add($pt) | Out-Null
            if ($st -match "NGUY HIỂM") { $item.BackColor = [System.Drawing.Color]::MistyRose }
            $lstView.Items.Add($item) | Out-Null
            if ($lstView.Items.Count % 10 -eq 0) { [System.Windows.Forms.Application]::DoEvents() }
        }
        $actDone = { param($c, $dc)
            if ($dc -gt 0) { $lblStatus.Text = "Hoàn tất $c file. Phát hiện $dc file NGUY HIỂM!" } else { $lblStatus.Text = "Hoàn tất. Hệ thống an toàn." }
            $btnScan.Enabled = $true; $btnBrowse.Enabled = $true
        }

        Start-DeepScan -Targets $targetsToScan -UpdateStatusAction $actStatus -AddRowAction $actRow -CompleteAction $actDone
    })

    $form.ShowDialog() | Out-Null
}
