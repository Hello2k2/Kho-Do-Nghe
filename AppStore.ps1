Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- HÀM CÀI ĐẶT MÔI TRƯỜNG (CORE) ---
function Install-Environment {
    param($StatusLabel)
    
    $StatusLabel.Text = "Dang kiem tra moi truong..."
    $StatusLabel.ForeColor = "Yellow"
    $Form.Refresh()
    
    # 1. XU LY CHOCOLATEY
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        $StatusLabel.Text = "Dang cai Chocolatey..."
        $Form.Refresh()
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            $ChocoScript = (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')
            Invoke-Expression $ChocoScript
            $env:Path += ";$env:ProgramData\chocolatey\bin"
        } catch {}
    }

    # 2. XU LY SCOOP
    if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
        $StatusLabel.Text = "Dang cai Scoop..."
        $Form.Refresh()
        try {
            Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
            $env:Path += ";$env:USERPROFILE\scoop\shims"
        } catch {}
    }

    # 3. XU LY WINGET (Fix cho LTSC/Lite - Cài full dependencies)
    if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
        $StatusLabel.Text = "Dang tai & cai Winget (LTSC Mode)..."
        $Form.Refresh()
        try {
            $WebClient = New-Object System.Net.WebClient
            
            # Tạo thư mục tạm
            $WGDir = "$env:TEMP\Winget_Install"
            if (!(Test-Path $WGDir)) { New-Item -ItemType Directory -Path $WGDir | Out-Null }

            # Link tải các gói cần thiết (Lấy từ GitHub Microsoft)
            # 1. UI.Xaml (Dependency)
            $UrlXaml = "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx"
            $WebClient.DownloadFile($UrlXaml, "$WGDir\UI.Xaml.appx")
            Add-AppxPackage -Path "$WGDir\UI.Xaml.appx"

            # 2. VCLibs (Dependency)
            $UrlVCLibs = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
            $WebClient.DownloadFile($UrlVCLibs, "$WGDir\VCLibs.appx")
            Add-AppxPackage -Path "$WGDir\VCLibs.appx"

            # 3. Desktop App Installer (Winget Core)
            $UrlWinget = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
            $WebClient.DownloadFile($UrlWinget, "$WGDir\Winget.msixbundle")
            Add-AppxPackage -Path "$WGDir\Winget.msixbundle"

            # Dọn dẹp
            Remove-Item $WGDir -Recurse -Force
            
        } catch {
             # Nếu lỗi thì bỏ qua, dùng Choco thay thế
        }
    }
    
    $StatusLabel.Text = "Moi truong da san sang! Hay tim kiem."
    $StatusLabel.ForeColor = "Lime"
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "APP STORE - PHAT TAN PC (LTSC SUPPORT)"
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

# Filter ComboBox
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
    [System.Windows.Forms.MessageBox]::Show("Da cai dat xong moi truong! Hay thu tim kiem.", "Phat Tan PC")
})

$BtnSearch.Add_Click({
    $Kw = $TxtSearch.Text
    $SourceFilter = $CbSource.SelectedItem
    if ([string]::IsNullOrWhiteSpace($Kw)) { return }
    
    $Grid.Rows.Clear()
    $BtnSearch.Enabled = $false; $BtnSearch.Text = "..."
    $LblStatus.Text = "Dang tim kiem tren: $SourceFilter ..."
    $Form.Refresh()

    # 1. CHOCOLATEY (Luôn ưu tiên vì dễ dùng nhất trên LTSC)
    if (($SourceFilter -like "*Tat ca*" -or $SourceFilter -like "*Chocolatey*") -and (Get-Command choco -ErrorAction SilentlyContinue)) {
        $Raw = choco search "$Kw" --limit-output --order-by-popularity
        foreach ($L in $Raw) {
            if ($L -match "^(.*?)\|(.*?)$") { $P = $L -split "\|"; $Grid.Rows.Add("Choco", $P[0], $P[0], $P[1]) }
        }
    }
    
    # 2. WINGET
    if (($SourceFilter -like "*Tat ca*" -or $SourceFilter -like "*Winget*") -and (Get-Command winget -ErrorAction SilentlyContinue)) {
        # Logic Winget đơn giản hóa để tránh lỗi trên PS cũ
    }

    # 3. SCOOP
    if (($SourceFilter -like "*Tat ca*" -or $SourceFilter -like "*Scoop*") -and (Get-Command scoop -ErrorAction SilentlyContinue)) {
        $RawS = scoop search "$Kw"
        if ($RawS -match "bucket") { $Grid.Rows.Add("Scoop", "$Kw (Scoop)", "$Kw", "Latest") }
    }

    $LblStatus.Text = "Tim thay $($Grid.Rows.Count) ket qua."
    $BtnSearch.Enabled = $true; $BtnSearch.Text = "TIM KIEM"
    if ($Grid.Rows.Count -gt 0) { $BtnInstall.Enabled = $true }
})

$BtnInstall.Add_Click({
    if ($Grid.SelectedRows.Count -eq 0) { return }
    $Row = $Grid.SelectedRows[0]
    $Src = $Row.Cells[0].Value; $ID = $Row.Cells[2].Value
    $AppName = $Row.Cells[1].Value # Lấy tên App để truyền vào
    
    $BtnInstall.Enabled = $false; $BtnInstall.Text = "DANG CAI..."
    
    # Chuẩn bị lệnh chạy
    $Cmd = ""
    if ($Src -eq "Choco") { $Cmd = "choco install $ID -y" }
    elseif ($Src -eq "Scoop") { $Cmd = "scoop install $ID" }
    elseif ($Src -eq "Winget") { $Cmd = "winget install $ID -e --accept-package-agreements --accept-source-agreements" }
    
    if ($Cmd -ne "") {
        # SCRIPT BLOCK ĐỂ CHẠY TIẾN TRÌNH MỚI (Fix lỗi ArgumentList)
        $ScriptContent = {
            param($TargetCmd, $TargetName)
            $Host.UI.RawUI.WindowTitle = "PHAT TAN PC - INSTALLER: $TargetName"
            Write-Host "Dang cai dat: $TargetName" -ForegroundColor Cyan
            Invoke-Expression $TargetCmd
            Write-Host "--- XONG! Nhan Enter de dong... ---" -ForegroundColor Green
            Read-Host
        }
        
        # Mã hóa Script Block
        $Encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($ScriptContent.ToString() + "`n" + "& `$ScriptBlock -TargetCmd '$Cmd' -TargetName '$AppName'"))
        
        # Chạy
        Start-Process powershell -ArgumentList "-NoExit", "-EncodedCommand", "$Encoded"
    }
    
    $BtnInstall.Enabled = $true; $BtnInstall.Text = "CAI DAT APP DA CHON"
})

$Form.ShowDialog() | Out-Null
