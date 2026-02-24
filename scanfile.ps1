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
$global:scanResults = @() # Biến toàn cục lưu kết quả để dễ xuất CSV

$defaultTargetPaths = @(
    @{ Scope = "User";   Path = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup" }
    @{ Scope = "User";   Path = "$env:LOCALAPPDATA\Temp" }
    @{ Scope = "System"; Path = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" }
    @{ Scope = "System"; Path = "$env:WINDIR\Temp" }
)

# --- HÀM LÕI XỬ LÝ QUÉT ---
function Start-DeepScan {
    param([array]$Targets, [ScriptBlock]$UpdateStatusAction, [ScriptBlock]$AddRowAction, [ScriptBlock]$CompleteAction)

    $global:scanResults = @() # Reset data
    $count = 0; $dangerCount = 0

    if (-not (Test-Path $sigcheckPath)) {
        &$UpdateStatusAction "Đang tải Core Sysinternals..."
        try { Invoke-WebRequest -Uri $sigcheckUrl -OutFile $sigcheckPath -UseBasicParsing } 
        catch { &$UpdateStatusAction "Lỗi mạng! Không tải được Core."; &$CompleteAction 0 0; return }
    }

    &$UpdateStatusAction "Đang quét và băm Hash..."

    foreach ($target in $Targets) {
        $path = $target.Path; $scope = $target.Scope

        if (Test-Path $path) {
            $sigOutput = & $sigcheckPath -accepteula -c -h -s $path 2>$null
            if ($sigOutput -and $sigOutput.Count -gt 1) {
                $csvData = $sigOutput | ConvertFrom-Csv -Delimiter ","
                foreach ($row in $csvData) {
                    if ([string]::IsNullOrWhiteSpace($row.Path)) { continue }

                    $count++
                    $ext = [System.IO.Path]::GetExtension($row.Path).ToLower()
                    $fileType = "Khác"; $isRun = $false

                    if ($ext -match "\.(exe|dll|sys|ocx|bin|scr|com|cpl|msc)$") { $fileType = "Thực thi (PE)"; $isRun = $true } 
                    elseif ($ext -match "\.(bat|cmd|vbs|ps1|js|wsf|hta|py|sh|psm1)$") { $fileType = "Script/Code"; $isRun = $true } 
                    elseif ($ext -match "\.(zip|rar|7z|tar|iso|cab|gz)$") { $fileType = "File Nén" } 
                    elseif ($ext -match "\.(doc|docx|xls|xlsx|pdf|ppt|pptx|rtf)$") { $fileType = "Tài liệu (Office)" } 
                    elseif ($ext -match "\.(txt|log|ini|cfg|xml|json|yaml|md)$") { $fileType = "Văn bản/Config" } 
                    elseif ($ext -match "\.(jpg|png|gif|mp4|mp3|wav)$") { $fileType = "Media" }

                    $publisher = $row.Publisher; $status = ""
                    if ($isRun) {
                        if ($row."Verified" -eq "Signed" -and $publisher -match "Microsoft|Google|Intel|NVIDIA|AMD|VMware|Apple") {
                            $status = "✅ An toàn (Trust)"
                        } elseif ($row."Verified" -eq "Signed") {
                            $status = "⚠️ An toàn (Khác)"
                        } else {
                            $status = "❌ NGUY HIỂM!"
                            $dangerCount++
                        }
                    } else { $status = "🔵 Ít rủi ro" }

                    $hashMD5 = if ($row.MD5) { $row.MD5 } else { "N/A" }
                    $pub = if([string]::IsNullOrWhiteSpace($publisher)) { "---" } else { $publisher }
                    $fileName = Split-Path $row.Path -Leaf

                    $resultObj = [pscustomobject]@{
                        Scope = $scope; Status = $status; FileType = $fileType; 
                        Hash = $hashMD5; Publisher = $pub; FileName = $fileName; Path = $row.Path
                    }
                    $global:scanResults += $resultObj
                    &$AddRowAction $resultObj
                }
            }
        }
    }
    &$CompleteAction $count $dangerCount
}

# --- CÁC HÀM XỬ LÝ CHUỘT PHẢI (Dùng chung cho cả 2 UI) ---
function Open-FileLocation ($filePath) {
    if (Test-Path $filePath) { explorer.exe /select, "$filePath" }
}
function Search-VirusTotal ($hash) {
    if ($hash -ne "N/A") { Start-Process "https://www.virustotal.com/gui/search/$hash" }
}
function Kill-Virus ($filePath) {
    $msgBox = [System.Windows.Forms.MessageBox]::Show("Bạn có chắc chắn muốn XÓA VĨNH VIỄN file này không?`n`n$filePath", "Tiêu diệt Virus", 4, 48)
    if ($msgBox -eq "Yes") {
        try {
            Remove-Item -Path $filePath -Force -ErrorAction Stop
            [System.Windows.Forms.MessageBox]::Show("Đã tiêu diệt thành công!", "Thành công", 0, 64) | Out-Null
            return $true
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Không thể xóa file! Có thể file đang chạy. Hãy thử End Task nó trước.", "Lỗi", 0, 16) | Out-Null
        }
    }
    return $false
}
function Export-Report {
    if ($global:scanResults.Count -eq 0) { return }
    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "CSV File (*.csv)|*.csv|All Files (*.*)|*.*"
    $saveDialog.FileName = "ScanReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $global:scanResults | Export-Csv -Path $saveDialog.FileName -NoTypeInformation -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("Đã lưu báo cáo tại:`n" + $saveDialog.FileName, "Thành công", 0, 64) | Out-Null
    }
}

# ==========================================
# --- KHỞI TẠO GIAO DIỆN ---
# ==========================================
$useWPF = $true
try { Add-Type -AssemblyName PresentationFramework -ErrorAction Stop } catch { $useWPF = $false }

if ($useWPF) {
    # ---------------- UI: WPF ----------------
    [xml]$xaml = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="Deep Scanner v6 (Ultimate GUI)" Height="650" Width="1100" Background="#f4f6f9">
        <Grid Margin="15">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/> <RowDefinition Height="*"/> <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <TextBlock Text="Bộ Quét Chuyên Sâu v6 (Context Menu + Báo Cáo)" FontWeight="Bold" FontSize="18" Foreground="#2c3e50" Margin="0,0,0,15"/>
            
            <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,0,0,15">
                <Button Name="btnBrowse" Content="📂 Chọn thư mục..." Width="120" Height="32" Margin="0,0,10,0" Background="#e2e6ea"/>
                <TextBox Name="txtTarget" Width="280" Height="32" VerticalContentAlignment="Center" Text="[Mặc định] Các vùng trọng điểm" IsReadOnly="True" Margin="0,0,10,0" Background="#e9ecef"/>
                <Button Name="btnScan" Content="🚀 Bắt đầu Quét" Width="130" Height="32" Background="#dc3545" Foreground="White" FontWeight="Bold" BorderThickness="0"/>
                <Button Name="btnExport" Content="📊 Xuất CSV" Width="100" Height="32" Margin="10,0,0,0" Background="#28a745" Foreground="White" FontWeight="Bold" BorderThickness="0" IsEnabled="False"/>
                <TextBlock Name="txtStatus" Text="Sẵn sàng quét..." Margin="15,7,0,0" FontStyle="Italic" Foreground="#6c757d"/>
            </StackPanel>

            <ListView Name="lstResults" Grid.Row="2" Background="White" BorderBrush="#ced4da" BorderThickness="1">
                <ListView.ContextMenu>
                    <ContextMenu>
                        <MenuItem Name="menuOpen" Header="📂 Mở thư mục chứa file" />
                        <MenuItem Name="menuVT" Header="🌐 Tra cứu VirusTotal" />
                        <Separator/>
                        <MenuItem Name="menuCopyHash" Header="📋 Copy mã Hash" />
                        <MenuItem Name="menuCopyPath" Header="📋 Copy đường dẫn" />
                        <Separator/>
                        <MenuItem Name="menuKill" Header="🔪 Tiêu diệt (Xóa File)" Foreground="Red" FontWeight="Bold" />
                    </ContextMenu>
                </ListView.ContextMenu>
                <ListView.View>
                    <GridView>
                        <GridViewColumn Header="Scope" DisplayMemberBinding="{Binding Scope}" Width="70"/>
                        <GridViewColumn Header="Cảnh báo" DisplayMemberBinding="{Binding Status}" Width="140"/>
                        <GridViewColumn Header="Loại File" DisplayMemberBinding="{Binding FileType}" Width="110"/>
                        <GridViewColumn Header="MD5 Hash" DisplayMemberBinding="{Binding Hash}" Width="230"/>
                        <GridViewColumn Header="Nhà phát hành" DisplayMemberBinding="{Binding Publisher}" Width="120"/>
                        <GridViewColumn Header="Tên File" DisplayMemberBinding="{Binding FileName}" Width="160"/>
                        <GridViewColumn Header="Đường dẫn" DisplayMemberBinding="{Binding Path}" Width="220"/>
                    </GridView>
                </ListView.View>
            </ListView>
            <TextBlock Name="txtSummary" Grid.Row="3" FontWeight="Bold" FontSize="14" Margin="0,15,0,0"/>
        </Grid>
    </Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $btnBrowse = $window.FindName("btnBrowse"); $txtTarget = $window.FindName("txtTarget")
    $btnScan = $window.FindName("btnScan"); $btnExport = $window.FindName("btnExport"); $txtStatus = $window.FindName("txtStatus")
    $lstResults = $window.FindName("lstResults"); $txtSummary = $window.FindName("txtSummary")

    # Bắt sự kiện Context Menu
    $window.FindName("menuOpen").Add_Click({ if ($lstResults.SelectedItem) { Open-FileLocation $lstResults.SelectedItem.Path } })
    $window.FindName("menuVT").Add_Click({ if ($lstResults.SelectedItem) { Search-VirusTotal $lstResults.SelectedItem.Hash } })
    $window.FindName("menuCopyHash").Add_Click({ if ($lstResults.SelectedItem) { Set-Clipboard -Value $lstResults.SelectedItem.Hash } })
    $window.FindName("menuCopyPath").Add_Click({ if ($lstResults.SelectedItem) { Set-Clipboard -Value $lstResults.SelectedItem.Path } })
    $window.FindName("menuKill").Add_Click({ 
        if ($lstResults.SelectedItem) { 
            $obj = $lstResults.SelectedItem
            if (Kill-Virus $obj.Path) { 
                # Đổi tên trên UI thay vì xóa dòng để giữ lịch sử log
                $obj.Status = "💀 ĐÃ TIÊU DIỆT"
                $lstResults.Items.Refresh() 
            }
        } 
    })

    $btnBrowse.Add_Click({
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $txtTarget.Text = $dialog.SelectedPath }
    })
    $btnExport.Add_Click({ Export-Report })

    $btnScan.Add_Click({
        $btnScan.IsEnabled = $false; $btnBrowse.IsEnabled = $false; $btnExport.IsEnabled = $false
        $lstResults.Items.Clear(); $txtSummary.Text = ""
        $dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher

        $targetsToScan = if ($txtTarget.Text -match "\[Mặc định\]") { $defaultTargetPaths } else { @( @{ Scope="Custom"; Path=$txtTarget.Text } ) }

        $actStatus = { param($msg) $dispatcher.Invoke([Action]{ $txtStatus.Text = $msg }) }
        $actRow = { param($obj) $dispatcher.Invoke([Action]{ $lstResults.Items.Add($obj) | Out-Null }) }
        $actDone = { param($c, $dc)
            $dispatcher.Invoke([Action]{
                $txtStatus.Text = "Hoàn tất quét $c file."
                if ($dc -gt 0) { $txtSummary.Text = "Phát hiện $dc file NGUY HIỂM!"; $txtSummary.Foreground = "Red" } 
                else { $txtSummary.Text = "Hệ thống an toàn."; $txtSummary.Foreground = "Green" }
                $btnScan.IsEnabled = $true; $btnBrowse.IsEnabled = $true; $btnExport.IsEnabled = ($c -gt 0)
            })
        }
        Start-DeepScan -Targets $targetsToScan -UpdateStatusAction $actStatus -AddRowAction $actRow -CompleteAction $actDone
    })
    $window.ShowDialog() | Out-Null

} else {
    # ---------------- UI: WinForms ----------------
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Deep Scanner v6 (WinForms)"
    $form.Size = New-Object System.Drawing.Size(1050, 600)
    $form.StartPosition = "CenterScreen"

    $btnBrowse = New-Object System.Windows.Forms.Button
    $btnBrowse.Location = New-Object System.Drawing.Point(10, 10); $btnBrowse.Size = New-Object System.Drawing.Size(100, 30); $btnBrowse.Text = "📂 Chọn..."
    
    $txtTarget = New-Object System.Windows.Forms.TextBox
    $txtTarget.Location = New-Object System.Drawing.Point(120, 15); $txtTarget.Size = New-Object System.Drawing.Size(250, 30); $txtTarget.Text = "[Mặc định] Các vùng trọng điểm"; $txtTarget.ReadOnly = $true

    $btnScan = New-Object System.Windows.Forms.Button
    $btnScan.Location = New-Object System.Drawing.Point(380, 10); $btnScan.Size = New-Object System.Drawing.Size(100, 30); $btnScan.Text = "🚀 Bắt đầu"; $btnScan.BackColor = [System.Drawing.Color]::Crimson; $btnScan.ForeColor = [System.Drawing.Color]::White

    $btnExport = New-Object System.Windows.Forms.Button
    $btnExport.Location = New-Object System.Drawing.Point(490, 10); $btnExport.Size = New-Object System.Drawing.Size(90, 30); $btnExport.Text = "📊 Xuất CSV"; $btnExport.BackColor = [System.Drawing.Color]::MediumSeaGreen; $btnExport.ForeColor = [System.Drawing.Color]::White; $btnExport.Enabled = $false

    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Location = New-Object System.Drawing.Point(590, 15); $lblStatus.Size = New-Object System.Drawing.Size(400, 20); $lblStatus.Text = "Sẵn sàng..."

    $lstView = New-Object System.Windows.Forms.ListView
    $lstView.Location = New-Object System.Drawing.Point(10, 50); $lstView.Size = New-Object System.Drawing.Size(1010, 480)
    $lstView.View = [System.Windows.Forms.View]::Details; $lstView.GridLines = $true; $lstView.FullRowSelect = $true
    $lstView.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

    $lstView.Columns.Add("Scope", 70) | Out-Null; $lstView.Columns.Add("Cảnh báo", 120) | Out-Null; $lstView.Columns.Add("Loại File", 110) | Out-Null
    $lstView.Columns.Add("MD5 Hash", 230) | Out-Null; $lstView.Columns.Add("Nhà phát hành", 120) | Out-Null; $lstView.Columns.Add("Tên File", 150) | Out-Null; $lstView.Columns.Add("Đường dẫn", 220) | Out-Null

    # Context Menu cho WinForms
    $ctxMenu = New-Object System.Windows.Forms.ContextMenuStrip
    $ctxOpen = $ctxMenu.Items.Add("📂 Mở thư mục chứa file"); $ctxVT = $ctxMenu.Items.Add("🌐 Tra cứu VirusTotal"); $ctxMenu.Items.Add("-") | Out-Null
    $ctxCopyH = $ctxMenu.Items.Add("📋 Copy mã Hash"); $ctxCopyP = $ctxMenu.Items.Add("📋 Copy đường dẫn"); $ctxMenu.Items.Add("-") | Out-Null
    $ctxKill = $ctxMenu.Items.Add("🔪 Tiêu diệt (Xóa File)"); $ctxKill.ForeColor = [System.Drawing.Color]::Red; $ctxKill.Font = New-Object System.Drawing.Font($ctxKill.Font, [System.Drawing.FontStyle]::Bold)
    $lstView.ContextMenuStrip = $ctxMenu

    # Sự kiện Context Menu
    $ctxOpen.Add_Click({ if ($lstView.SelectedItems.Count) { Open-FileLocation $lstView.SelectedItems[0].SubItems[6].Text } })
    $ctxVT.Add_Click({ if ($lstView.SelectedItems.Count) { Search-VirusTotal $lstView.SelectedItems[0].SubItems[3].Text } })
    $ctxCopyH.Add_Click({ if ($lstView.SelectedItems.Count) { Set-Clipboard -Value $lstView.SelectedItems[0].SubItems[3].Text } })
    $ctxCopyP.Add_Click({ if ($lstView.SelectedItems.Count) { Set-Clipboard -Value $lstView.SelectedItems[0].SubItems[6].Text } })
    $ctxKill.Add_Click({ 
        if ($lstView.SelectedItems.Count) { 
            $item = $lstView.SelectedItems[0]
            if (Kill-Virus $item.SubItems[6].Text) { $item.SubItems[1].Text = "💀 ĐÃ TIÊU DIỆT"; $item.BackColor = [System.Drawing.Color]::LightGray }
        } 
    })

    $form.Controls.AddRange(@($btnBrowse, $txtTarget, $btnScan, $btnExport, $lblStatus, $lstView))

    $btnBrowse.Add_Click({ $d = New-Object System.Windows.Forms.FolderBrowserDialog; if ($d.ShowDialog() -eq "OK") { $txtTarget.Text = $d.SelectedPath } })
    $btnExport.Add_Click({ Export-Report })

    $btnScan.Add_Click({
        $btnScan.Enabled = $false; $btnBrowse.Enabled = $false; $btnExport.Enabled = $false; $lstView.Items.Clear()
        $targetsToScan = if ($txtTarget.Text -match "\[Mặc định\]") { $defaultTargetPaths } else { @( @{ Scope="Custom"; Path=$txtTarget.Text } ) }

        $actStatus = { param($msg) $lblStatus.Text = $msg; [System.Windows.Forms.Application]::DoEvents() }
        $actRow = { param($obj) 
            $item = New-Object System.Windows.Forms.ListViewItem($obj.Scope)
            $item.SubItems.Add($obj.Status) | Out-Null; $item.SubItems.Add($obj.FileType) | Out-Null; $item.SubItems.Add($obj.Hash) | Out-Null
            $item.SubItems.Add($obj.Publisher) | Out-Null; $item.SubItems.Add($obj.FileName) | Out-Null; $item.SubItems.Add($obj.Path) | Out-Null
            if ($obj.Status -match "NGUY HIỂM") { $item.BackColor = [System.Drawing.Color]::MistyRose }
            $lstView.Items.Add($item) | Out-Null
            if ($lstView.Items.Count % 10 -eq 0) { [System.Windows.Forms.Application]::DoEvents() }
        }
        $actDone = { param($c, $dc)
            if ($dc -gt 0) { $lblStatus.Text = "Xong $c file. Có $dc file NGUY HIỂM!" } else { $lblStatus.Text = "Xong. Hệ thống an toàn." }
            $btnScan.Enabled = $true; $btnBrowse.Enabled = $true; $btnExport.Enabled = ($c -gt 0)
        }
        Start-DeepScan -Targets $targetsToScan -UpdateStatusAction $actStatus -AddRowAction $actRow -CompleteAction $actDone
    })
    $form.ShowDialog() | Out-Null
}
