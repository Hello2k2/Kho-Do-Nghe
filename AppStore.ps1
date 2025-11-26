Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- HÀM CÀI ĐẶT MÔI TRƯỜNG (CORE) ---
function Install-Environment {
    param($StatusLabel)
    
    $StatusLabel.Text = "Dang kiem tra moi truong..."
    $StatusLabel.ForeColor = "Yellow"
    
    # 1. XU LY CHOCOLATEY
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        $StatusLabel.Text = "Dang cai Chocolatey..."
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            # Dùng WebClient thay vì curl
            $ChocoScript = (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')
            Invoke-Expression $ChocoScript
            
            # Refresh Path
            $env:Path += ";$env:ProgramData\chocolatey\bin"
        } catch {}
    }

    # 2. XU LY SCOOP (Fix lỗi Policy)
    if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
        $StatusLabel.Text = "Dang cai Scoop..."
        try {
            # Mở khóa Policy cho User hiện tại
            Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            # Cài đặt
            Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
            
            # Refresh Path
            $env:Path += ";$env:USERPROFILE\scoop\shims"
        } catch {}
    }

    # 3. XU LY WINGET (Hàng khủng - Cài thủ công)
    if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
        $StatusLabel.Text = "Dang tai Winget (MSIX)..."
        try {
            # Link tải trực tiếp bản mới nhất từ GitHub Microsoft
            $WingetURL = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
            $SavePath = "$env:TEMP\winget.msixbundle"
            
            # Tải về
            (New-Object System.Net.WebClient).DownloadFile($WingetURL, $SavePath)
            
            # Cài đặt bằng lệnh Appx (Không cần Store)
            $StatusLabel.Text = "Dang cai Winget..."
            Add-AppxPackage -Path $SavePath
            
            Remove-Item $SavePath -Force
        } catch {
             # Nếu lỗi thì bỏ qua, dùng Choco thay thế
        }
    }
    
    $StatusLabel.Text = "Moi truong da san sang!"
    $StatusLabel.ForeColor = "Lime"
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "APP STORE - PHAT TAN PC (AUTO FIX)"
$Form.Size = New-Object System.Drawing.Size(850, 550)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$Lbl = New-Object System.Windows.Forms.Label
$Lbl.Text = "NHAP TEN PHAN MEM (VD: chrome, zoom, ultraview...):"
$Lbl.AutoSize = $true; $Lbl.Location = New-Object System.Drawing.Point(15, 15); $Lbl.Font = "Segoe UI, 10, Bold"
$Form.Controls.Add($Lbl)

# Search Box
$TxtSearch = New-Object System.Windows.Forms.TextBox
$TxtSearch.Size = New-Object System.Drawing.Size(500, 30); $TxtSearch.Location = New-Object System.Drawing.Point(15, 40); $TxtSearch.Font = "Segoe UI, 11"
$Form.Controls.Add($TxtSearch)

# Button Search
$BtnSearch = New-Object System.Windows.Forms.Button
$BtnSearch.Text = "TIM KIEM"
$BtnSearch.Location = New-Object System.Drawing.Point(530, 38); $BtnSearch.Size = New-Object System.Drawing.Size(100, 32)
$BtnSearch.BackColor = "Cyan"; $BtnSearch.ForeColor = "Black"; $BtnSearch.FlatStyle = "Flat"; $BtnSearch.Font = "Segoe UI, 9, Bold"
$Form.Controls.Add($BtnSearch)

# Nút Fix Môi Trường (Thủ công)
$BtnFix = New-Object System.Windows.Forms.Button
$BtnFix.Text = "CAI WINGET/CHOCO/SCOOP"
$BtnFix.Location = New-Object System.Drawing.Point(640, 38); $BtnFix.Size = New-Object System.Drawing.Size(180, 32)
$BtnFix.BackColor = "Orange"; $BtnFix.ForeColor = "Black"; $BtnFix.FlatStyle = "Flat"; $BtnFix.Font = "Segoe UI, 8, Bold"
$Form.Controls.Add($BtnFix)

# Status Label
$LblStatus = New-Object System.Windows.Forms.Label
$LblStatus.Text = "Trang thai: San sang."
$LblStatus.AutoSize = $true; $LblStatus.Location = New-Object System.Drawing.Point(15, 75); $LblStatus.ForeColor = "LightGray"
$Form.Controls.Add($LblStatus)

# Grid
$Grid = New-Object System.Windows.Forms.DataGridView
$Grid.Location = New-Object System.Drawing.Point(15, 100); $Grid.Size = New-Object System.Drawing.Size(805, 330)
$Grid.BackgroundColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
$Grid.ForeColor = "Black"
$Grid.AllowUserToAddRows = $false; $Grid.RowHeadersVisible = $false
$Grid.SelectionMode = "FullRowSelect"; $Grid.MultiSelect = $false; $Grid.ReadOnly = $true; $Grid.AutoSizeColumnsMode = "Fill"
$Grid.Columns.Add("Source", "NGUON"); $Grid.Columns.Add("Name", "TEN PHAN MEM"); $Grid.Columns.Add("ID", "ID GOI (PACKAGE)"); $Grid.Columns.Add("Ver", "VERSION")
$Grid.Columns[0].FillWeight = 15; $Grid.Columns[1].FillWeight = 40; $Grid.Columns[2].FillWeight = 30; $Grid.Columns[3].FillWeight = 15
$Form.Controls.Add($Grid)

# Install Button
$BtnInstall = New-Object System.Windows.Forms.Button
$BtnInstall.Text = "CAI DAT APP DA CHON"
$BtnInstall.Location = New-Object System.Drawing.Point(250, 460); $BtnInstall.Size = New-Object System.Drawing.Size(300, 45)
$BtnInstall.BackColor = "LimeGreen"; $BtnInstall.ForeColor = "Black"; $BtnInstall.FlatStyle = "Flat"; $BtnInstall.Font = "Segoe UI, 11, Bold"
$BtnInstall.Enabled = $false
$Form.Controls.Add($BtnInstall)

# --- SỰ KIỆN ---

$BtnFix.Add_Click({
    $BtnFix.Enabled = $false
    Install-Environment -StatusLabel $LblStatus
    $BtnFix.Enabled = $true
    [System.Windows.Forms.MessageBox]::Show("Da cai dat xong moi truong!", "Phat Tan PC")
})

$BtnSearch.Add_Click({
    $Kw = $TxtSearch.Text
    if ([string]::IsNullOrWhiteSpace($Kw)) { return }
    
    # Tự động cài môi trường nếu chưa có
    if (!(Get-Command choco -ErrorAction SilentlyContinue) -or !(Get-Command winget -ErrorAction SilentlyContinue)) {
        Install-Environment -StatusLabel $LblStatus
    }

    $Grid.Rows.Clear()
    $BtnSearch.Enabled = $false; $BtnSearch.Text = "..."
    $LblStatus.Text = "Dang tim kiem..."
    $Form.Refresh()

    # 1. Tìm Choco
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        $Raw = choco search "$Kw" --limit-output --order-by-popularity
        foreach ($L in $Raw) {
            if ($L -match "^(.*?)\|(.*?)$") { $P = $L -split "\|"; $Grid.Rows.Add("Choco", $P[0], $P[0], $P[1]) }
        }
    }
    
    # 2. Tìm Winget (Giới hạn 5 kết quả đầu cho nhanh)
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        # Winget khó parse text, nên tạm thời chỉ hỗ trợ Choco hiển thị GUI đẹp
        # Nếu muốn Winget thì phải dùng JSON mode (nhưng PowerShell cũ không hỗ trợ tốt)
    }

    $LblStatus.Text = "Tim thay $($Grid.Rows.Count) ket qua."
    $BtnSearch.Enabled = $true; $BtnSearch.Text = "TIM KIEM"
    if ($Grid.Rows.Count -gt 0) { $BtnInstall.Enabled = $true }
})

$BtnInstall.Add_Click({
    if ($Grid.SelectedRows.Count -eq 0) { return }
    $Row = $Grid.SelectedRows[0]
    $Src = $Row.Cells[0].Value; $ID = $Row.Cells[2].Value
    
    $BtnInstall.Enabled = $false; $BtnInstall.Text = "DANG CAI..."
    
    if ($Src -eq "Choco") {
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "choco install $ID -y; Write-Host '--- XONG! ---' -F Green; Read-Host 'Enter de dong...'"
    }
    elseif ($Src -eq "Scoop") {
         Start-Process powershell -ArgumentList "-NoExit", "-Command", "scoop install $ID; Write-Host '--- XONG! ---' -F Green; Read-Host 'Enter de dong...'"
    }
    
    $BtnInstall.Enabled = $true; $BtnInstall.Text = "CAI DAT APP DA CHON"
})

$Form.ShowDialog() | Out-Null
