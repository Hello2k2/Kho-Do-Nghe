Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "APP STORE - PHAT TAN PC (GUI VERSION)"
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

# --- NÚT CHECK & FIX ENVIRONMENT (MỚI) ---
$BtnCheckEnv = New-Object System.Windows.Forms.Button
$BtnCheckEnv.Text = "KIEM TRA & CAI TOOL HO TRO"
$BtnCheckEnv.Location = New-Object System.Drawing.Point(640, 38); $BtnCheckEnv.Size = New-Object System.Drawing.Size(180, 32)
$BtnCheckEnv.BackColor = "Orange"; $BtnCheckEnv.ForeColor = "Black"; $BtnCheckEnv.FlatStyle = "Flat"; $BtnCheckEnv.Font = "Segoe UI, 8, Bold"
$Form.Controls.Add($BtnCheckEnv)

# Label hiển thị trạng thái tool
$LblEnvStatus = New-Object System.Windows.Forms.Label
$LblEnvStatus.Text = "Trang thai: Chua kiem tra..."
$LblEnvStatus.AutoSize = $true; $LblEnvStatus.Location = New-Object System.Drawing.Point(15, 75); $LblEnvStatus.ForeColor = "LightGray"
$Form.Controls.Add($LblEnvStatus)

# Data Grid View
$Grid = New-Object System.Windows.Forms.DataGridView
$Grid.Location = New-Object System.Drawing.Point(15, 100); $Grid.Size = New-Object System.Drawing.Size(805, 330)
$Grid.BackgroundColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
$Grid.ForeColor = "Black"
$Grid.AllowUserToAddRows = $false; $Grid.RowHeadersVisible = $false
$Grid.SelectionMode = "FullRowSelect"; $Grid.MultiSelect = $false; $Grid.ReadOnly = $true; $Grid.AutoSizeColumnsMode = "Fill"
$Grid.Columns.Add("Source", "NGUON"); $Grid.Columns.Add("Name", "TEN PHAN MEM"); $Grid.Columns.Add("ID", "ID GOI (PACKAGE)"); $Grid.Columns.Add("Ver", "VERSION")
$Grid.Columns[0].FillWeight = 15; $Grid.Columns[1].FillWeight = 40; $Grid.Columns[2].FillWeight = 30; $Grid.Columns[3].FillWeight = 15
$Form.Controls.Add($Grid)

# Status Bar
$StatusLbl = New-Object System.Windows.Forms.Label
$StatusLbl.Text = "San sang."
$StatusLbl.AutoSize = $true; $StatusLbl.Location = New-Object System.Drawing.Point(15, 440); $StatusLbl.ForeColor = "Yellow"
$Form.Controls.Add($StatusLbl)

# Button Install
$BtnInstall = New-Object System.Windows.Forms.Button
$BtnInstall.Text = "CAI DAT APP DA CHON"
$BtnInstall.Location = New-Object System.Drawing.Point(250, 460); $BtnInstall.Size = New-Object System.Drawing.Size(300, 45)
$BtnInstall.BackColor = "LimeGreen"; $BtnInstall.ForeColor = "Black"; $BtnInstall.FlatStyle = "Flat"; $BtnInstall.Font = "Segoe UI, 11, Bold"
$BtnInstall.Enabled = $false
$Form.Controls.Add($BtnInstall)

# --- LOGIC CHECK & FIX ---
$BtnCheckEnv.Add_Click({
    $BtnCheckEnv.Enabled = $false
    $BtnCheckEnv.Text = "DANG QUET..."
    $StatusLbl.Text = "Dang kiem tra Winget, Chocolatey, Scoop..."
    $Form.Refresh()

    $Log = ""
    
    # 1. Check Winget
    if (Get-Command winget -ErrorAction SilentlyContinue) { $Log += "[Winget: OK]  " } 
    else { $Log += "[Winget: MISSING]  " }

    # 2. Check & Install Chocolatey
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        $StatusLbl.Text = "Dang cai dat Chocolatey (Mat 1-2 phut)..."
        $Form.Refresh()
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            
            # Refresh Env Var ngay lập tức để dùng luôn
            $env:Path += ";$env:ProgramData\chocolatey\bin"
            $Log += "[Choco: CAI MOI]  "
        } catch { $Log += "[Choco: LOI]  " }
    } else { $Log += "[Choco: OK]  " }

    # 3. Check & Install Scoop (Tùy chọn, nếu ông thích)
    if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
        $StatusLbl.Text = "Dang cai dat Scoop..."
        $Form.Refresh()
        try {
            Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            irm get.scoop.sh | iex
            $env:Path += ";$env:USERPROFILE\scoop\shims"
            $Log += "[Scoop: CAI MOI]"
        } catch { $Log += "[Scoop: LOI]" }
    } else { $Log += "[Scoop: OK]" }

    $LblEnvStatus.Text = $Log
    $LblEnvStatus.ForeColor = "Lime"
    $StatusLbl.Text = "Da kiem tra va cai dat xong moi truong!"
    $BtnCheckEnv.Text = "KIEM TRA LAI"
    $BtnCheckEnv.Enabled = $true
    [System.Windows.Forms.MessageBox]::Show("Da cai dat du bo cong cu ho tro!", "Phat Tan PC")
})

# --- LOGIC TIM KIEM ---
$BtnSearch.Add_Click({
    $Kw = $TxtSearch.Text
    if ([string]::IsNullOrWhiteSpace($Kw)) { return }
    
    $Grid.Rows.Clear()
    $BtnSearch.Enabled = $false; $BtnSearch.Text = "..."
    $StatusLbl.Text = "Dang tim kiem..."
    $Form.Refresh()

    # Tìm Choco (Ưu tiên vì có limit-output dễ parse)
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        $Raw = choco search "$Kw" --limit-output --order-by-popularity
        foreach ($L in $Raw) {
            if ($L -match "^(.*?)\|(.*?)$") { $P = $L -split "\|"; $Grid.Rows.Add("Choco", $P[0], $P[0], $P[1]) }
        }
    }
    
    # Tìm Scoop (Nếu có)
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        # Scoop search hơi chậm và output text, xử lý đơn giản
        # (Có thể bỏ qua nếu thấy chậm)
    }

    $StatusLbl.Text = "Tim thay $($Grid.Rows.Count) ket qua."
    $BtnSearch.Enabled = $true; $BtnSearch.Text = "TIM KIEM"
    if ($Grid.Rows.Count -gt 0) { $BtnInstall.Enabled = $true }
})

# --- LOGIC CAI DAT ---
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
