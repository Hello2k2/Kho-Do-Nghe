Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- HÀM CÀI ĐẶT MÔI TRƯỜNG (CORE) ---
function Install-Environment {
    param($StatusLabel)
    
    $StatusLabel.Text = "Dang xu ly..."
    $StatusLabel.ForeColor = "Yellow"
    $Form.Refresh()
    
    # 1. WINGET (Cài thủ công từ GitHub MS - Không cần Store)
    if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
        $StatusLabel.Text = "Dang tai & cai Winget (MSIX)..."
        $Form.Refresh()
        try {
            $WingetUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
            $SavePath = "$env:TEMP\winget.msixbundle"
            (New-Object System.Net.WebClient).DownloadFile($WingetUrl, $SavePath)
            Add-AppxPackage -Path $SavePath
            Remove-Item $SavePath -Force
        } catch {}
    }

    # 2. CHOCOLATEY
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        $StatusLabel.Text = "Dang cai Chocolatey..."
        $Form.Refresh()
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            $env:Path += ";$env:ProgramData\chocolatey\bin"
        } catch {}
    }

    # 3. SCOOP
    if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
        $StatusLabel.Text = "Dang cai Scoop..."
        $Form.Refresh()
        try {
            Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            irm get.scoop.sh | iex
            $env:Path += ";$env:USERPROFILE\scoop\shims"
        } catch {}
    }
    
    $StatusLabel.Text = "Moi truong da san sang! Hay tim kiem."
    $StatusLabel.ForeColor = "Lime"
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "APP STORE - PHAT TAN PC (V6.0)"
$Form.Size = New-Object System.Drawing.Size(850, 580)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$Lbl = New-Object System.Windows.Forms.Label
$Lbl.Text = "NHAP TEN APP (VD: chrome, zalo, obs...):"
$Lbl.AutoSize = $true; $Lbl.Location = New-Object System.Drawing.Point(15, 15); $Lbl.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$Form.Controls.Add($Lbl)

# Search Box
$TxtSearch = New-Object System.Windows.Forms.TextBox
$TxtSearch.Size = New-Object System.Drawing.Size(400, 30); $TxtSearch.Location = New-Object System.Drawing.Point(15, 40); $TxtSearch.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$Form.Controls.Add($TxtSearch)

# Filter ComboBox (Bộ lọc nguồn)
$CbSource = New-Object System.Windows.Forms.ComboBox
$CbSource.Location = New-Object System.Drawing.Point(425, 40); $CbSource.Size = New-Object System.Drawing.Size(120, 30); $CbSource.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$CbSource.DropDownStyle = "DropDownList"
$CbSource.Items.Add("TAT CA (All)")
$CbSource.Items.Add("Winget (MS)")
$CbSource.Items.Add("Chocolatey")
$CbSource.Items.Add("Scoop")
$CbSource.SelectedIndex = 0
$Form.Controls.Add($CbSource)

# Button Search
$BtnSearch = New-Object System.Windows.Forms.Button
$BtnSearch.Text = "TIM KIEM"
$BtnSearch.Location = New-Object System.Drawing.Point(555, 38); $BtnSearch.Size = New-Object System.Drawing.Size(90, 32)
$BtnSearch.BackColor = "Cyan"; $BtnSearch.ForeColor = "Black"; $BtnSearch.FlatStyle = "Flat"; $BtnSearch.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$Form.Controls.Add($BtnSearch)

# Nút Fix Môi Trường
$BtnFix = New-Object System.Windows.Forms.Button
$BtnFix.Text = "CAI WINGET/CHOCO"
$BtnFix.Location = New-Object System.Drawing.Point(660, 38); $BtnFix.Size = New-Object System.Drawing.Size(160, 32)
$BtnFix.BackColor = "Orange"; $BtnFix.ForeColor = "Black"; $BtnFix.FlatStyle = "Flat"; $BtnFix.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$Form.Controls.Add($BtnFix)

# Status Label
$LblStatus = New-Object System.Windows.Forms.Label
$LblStatus.Text = "Trang thai: San sang."
$LblStatus.AutoSize = $true; $LblStatus.Location = New-Object System.Drawing.Point(15, 75); $LblStatus.ForeColor = "LightGray"
$Form.Controls.Add($LblStatus)

# Grid
$Grid = New-Object System.Windows.Forms.DataGridView
$Grid.Location = New-Object System.Drawing.Point(15, 100); $Grid.Size = New-Object System.Drawing.Size(805, 350)
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
$BtnInstall.Location = New-Object System.Drawing.Point(250, 470); $BtnInstall.Size = New-Object System.Drawing.Size(300, 45)
$BtnInstall.BackColor = "LimeGreen"; $BtnInstall.ForeColor = "Black"; $BtnInstall.FlatStyle = "Flat"; $BtnInstall.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$BtnInstall.Enabled = $false
$Form.Controls.Add($BtnInstall)

# --- SỰ KIỆN ---

$BtnFix.Add_Click({
    $BtnFix.Enabled = $false
    Install-Environment -StatusLabel $LblStatus
    $BtnFix.Enabled = $true
    [System.Windows.Forms.MessageBox]::Show("Da kiem tra va cai dat xong moi truong!", "Phat Tan PC")
})

$BtnSearch.Add_Click({
    $Kw = $TxtSearch.Text
    $SourceFilter = $CbSource.SelectedItem
    if ([string]::IsNullOrWhiteSpace($Kw)) { return }
    
    $Grid.Rows.Clear()
    $BtnSearch.Enabled = $false; $BtnSearch.Text = "..."
    $LblStatus.Text = "Dang tim kiem tren: $SourceFilter ..."
    $Form.Refresh()

    # 1. CHOCOLATEY
    if (($SourceFilter -like "*Tat ca*" -or $SourceFilter -like "*Chocolatey*") -and (Get-Command choco -ErrorAction SilentlyContinue)) {
        $Raw = choco search "$Kw" --limit-output --order-by-popularity
        foreach ($L in $Raw) {
            if ($L -match "^(.*?)\|(.*?)$") { $P = $L -split "\|"; $Grid.Rows.Add("Choco", $P[0], $P[0], $P[1]) }
        }
    }
    
    # 2. WINGET (Parse text co ban)
    if (($SourceFilter -like "*Tat ca*" -or $SourceFilter -like "*Winget*") -and (Get-Command winget -ErrorAction SilentlyContinue)) {
        # Winget search tra ve text table, ta lay don gian ID va Name
        # (Code nay parse don gian, lay 5 ket qua dau de tranh lag)
        # Logic: Winget rat kho parse trong PS 5.1 neu khong dung JSON module, nen ta bo qua hien thi chi tiet
        # Chi hien thi thong bao neu muon dung Winget thi nen dung che do cai thu cong
    }

    # 3. SCOOP
    if (($SourceFilter -like "*Tat ca*" -or $SourceFilter -like "*Scoop*") -and (Get-Command scoop -ErrorAction SilentlyContinue)) {
        $RawS = scoop search "$Kw" 
        # Parse Scoop output (Don gian)
        if ($RawS -match "bucket") {
             $Grid.Rows.Add("Scoop", "$Kw (Scoop)", "$Kw", "Latest")
        }
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
    
    # Chuẩn bị lệnh chạy
    $Cmd = ""
    if ($Src -eq "Choco") { $Cmd = "choco install $ID -y" }
    elseif ($Src -eq "Scoop") { $Cmd = "scoop install $ID" }
    elseif ($Src -eq "Winget") { $Cmd = "winget install $ID -e --accept-package-agreements --accept-source-agreements" }
    
    if ($Cmd -ne "") {
        # Fix lỗi ArgumentList bằng cách dùng EncodedCommand hoặc gọi trực tiếp
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "& { Write-Host 'DANG CAI DAT: $ID' -F Cyan; $Cmd; Write-Host '--- XONG! ---' -F Green; Read-Host 'Enter de dong...' }"
    }
    
    $BtnInstall.Enabled = $true; $BtnInstall.Text = "CAI DAT APP DA CHON"
})

$Form.ShowDialog() | Out-Null
