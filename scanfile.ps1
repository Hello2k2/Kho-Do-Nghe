# Yêu cầu chạy bằng quyền Admin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Vui lòng chạy Script bằng quyền Administrator!"
    Exit
}

# --- CẤU HÌNH LÕI & DỮ LIỆU ---
$sigcheckUrl = "https://live.sysinternals.com/sigcheck64.exe"
$sigcheckPath = "$env:TEMP\sigcheck64.exe"

# Phân tách rõ ràng User (Người dùng hiện tại) và System (Toàn hệ thống)
$targetPaths = @(
    @{ Scope = "User";   Path = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup" }
    @{ Scope = "User";   Path = "$env:LOCALAPPDATA\Temp" }
    @{ Scope = "System"; Path = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" }
    @{ Scope = "System"; Path = "$env:WINDIR\Temp" } # Thêm thư mục Temp của System
)

# --- HÀM LÕI XỬ LÝ QUÉT (Chạy độc lập với UI) ---
function Start-DeepScan {
    param(
        [ScriptBlock]$UpdateStatusAction,
        [ScriptBlock]$AddRowAction,
        [ScriptBlock]$CompleteAction
    )

    $count = 0
    $dangerCount = 0

    # 1. Tải Core
    if (-not (Test-Path $sigcheckPath)) {
        &$UpdateStatusAction "Đang tải Core Sysinternals..."
        try { Invoke-WebRequest -Uri $sigcheckUrl -OutFile $sigcheckPath -UseBasicParsing } 
        catch { &$UpdateStatusAction "Lỗi mạng! Không thể tải Core."; &$CompleteAction 0 0; return }
    }

    &$UpdateStatusAction "Đang quét và băm Hash toàn bộ file..."

    # 2. Quét từng vùng theo Scope
    foreach ($target in $targetPaths) {
        $path = $target.Path
        $scope = $target.Scope

        if (Test-Path $path) {
            $sigOutput = & $sigcheckPath -accepteula -c -h -s $path 2>$null
            if ($sigOutput -and $sigOutput.Count -gt 1) {
                $csvData = $sigOutput | ConvertFrom-Csv -Delimiter ","
                foreach ($row in $csvData) {
                    $count++
                    
                    # --- PHÂN LOẠI FILE ĐA DẠNG ---
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

                    # --- ĐÁNH GIÁ AN TOÀN ---
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

                    # Gửi data lên UI
                    &$AddRowAction $scope $status $fileType $hashMD5 $pub $fileName $row.Path
                }
            }
        }
    }
    
    # Báo hoàn thành
    &$CompleteAction $count $dangerCount
}

# ==========================================
# --- KIỂM TRA & KHỞI TẠO GIAO DIỆN (UI) ---
# ==========================================
$useWPF = $true
try { Add-Type -AssemblyName PresentationFramework -ErrorAction Stop } 
catch { $useWPF = $false }

if ($useWPF) {
    # ---------------- UI: WPF (Ưu tiên) ----------------
    [xml]$xaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="Deep Scanner v4 (WPF - Modern)" Height="600" Width="1050" Background="#f8f9fa">
        <Grid Margin="10">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/> <RowDefinition Height="*"/> <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <TextBlock Text="Bộ Quét Chuyên Sâu v4 (Hỗ trợ chia Scope &amp; Đa định dạng)" FontWeight="Bold" FontSize="16" Margin="0,0,0,10"/>
            <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,0,0,10">
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
    $btnScan = $window.FindName("btnScan"); $txtStatus = $window.FindName("txtStatus")
    $lstResults = $window.FindName("lstResults"); $txtSummary = $window.FindName("txtSummary")

    $btnScan.Add_Click({
        $btnScan.IsEnabled = $false; $lstResults.Items.Clear(); $txtSummary.Text = ""
        $dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher

        # Định nghĩa các Action để truyền vào hàm Lõi
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
                $btnScan.IsEnabled = $true
            })
        }
        
        Start-DeepScan -UpdateStatusAction $actStatus -AddRowAction $actRow -CompleteAction $actDone
    })
    $window.ShowDialog() | Out-Null

} else {
    # ---------------- UI: WinForms (Dự phòng) ----------------
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Deep Scanner v4 (WinForms - Fallback)"
    $form.Size = New-Object System.Drawing.Size(1050, 600)
    $form.StartPosition = "CenterScreen"

    $btnScan = New-Object System.Windows.Forms.Button
    $btnScan.Location = New-Object System.Drawing.Point(10, 10)
    $btnScan.Size = New-Object System.Drawing.Size(120, 30)
    $btnScan.Text = "Bắt đầu Quét"
    $btnScan.BackColor = [System.Drawing.Color]::Crimson
    $btnScan.ForeColor = [System.Drawing.Color]::White

    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Location = New-Object System.Drawing.Point(140, 18)
    $lblStatus.Size = New-Object System.Drawing.Size(400, 20)
    $lblStatus.Text = "Sẵn sàng (Đang chạy chế độ WinForms)..."

    $lstView = New-Object System.Windows.Forms.ListView
    $lstView.Location = New-Object System.Drawing.Point(10, 50)
    $lstView.Size = New-Object System.Drawing.Size(1010, 480)
    $lstView.View = [System.Windows.Forms.View]::Details
    $lstView.GridLines = $true
    $lstView.FullRowSelect = $true
    $lstView.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

    # Add Columns
    $lstView.Columns.Add("Scope", 70) | Out-Null
    $lstView.Columns.Add("Cảnh báo", 120) | Out-Null
    $lstView.Columns.Add("Loại File", 120) | Out-Null
    $lstView.Columns.Add("MD5 Hash", 230) | Out-Null
    $lstView.Columns.Add("Nhà phát hành", 120) | Out-Null
    $lstView.Columns.Add("Tên File", 150) | Out-Null
    $lstView.Columns.Add("Đường dẫn", 200) | Out-Null

    $form.Controls.Add($btnScan)
    $form.Controls.Add($lblStatus)
    $form.Controls.Add($lstView)

    $btnScan.Add_Click({
        $btnScan.Enabled = $false
        $lstView.Items.Clear()

        $actStatus = { param($msg) $lblStatus.Text = $msg; [System.Windows.Forms.Application]::DoEvents() }
        $actRow = { param($sc, $st, $ft, $hs, $pb, $fn, $pt) 
            $item = New-Object System.Windows.Forms.ListViewItem($sc)
            $item.SubItems.Add($st) | Out-Null; $item.SubItems.Add($ft) | Out-Null
            $item.SubItems.Add($hs) | Out-Null; $item.SubItems.Add($pb) | Out-Null
            $item.SubItems.Add($fn) | Out-Null; $item.SubItems.Add($pt) | Out-Null
            if ($st -match "NGUY HIỂM") { $item.BackColor = [System.Drawing.Color]::MistyRose }
            $lstView.Items.Add($item) | Out-Null
            # Update UI mượt mà
            if ($lstView.Items.Count % 10 -eq 0) { [System.Windows.Forms.Application]::DoEvents() }
        }
        $actDone = { param($c, $dc)
            if ($dc -gt 0) { $lblStatus.Text = "Hoàn tất $c file. Phát hiện $dc file NGUY HIỂM!" } 
            else { $lblStatus.Text = "Hoàn tất. Hệ thống an toàn." }
            $btnScan.Enabled = $true
        }

        Start-DeepScan -UpdateStatusAction $actStatus -AddRowAction $actRow -CompleteAction $actDone
    })

    $form.ShowDialog() | Out-Null
}
