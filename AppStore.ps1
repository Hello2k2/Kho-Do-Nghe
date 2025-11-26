Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- HÀM TỰ SỬA LỖI CHOCO/WINGET ---
function Fix-Environment {
    $ChocoPath = "$env:ProgramData\chocolatey\bin"
    if (Test-Path $ChocoPath) {
        if ($env:Path -notlike "*$ChocoPath*") {
            $env:Path += ";$ChocoPath"
            [Environment]::SetEnvironmentVariable("Path", $env:Path, "Machine")
        }
    }
    # Nếu Choco lỗi nặng, xóa cài lại (Chỉ dùng khi cần thiết)
    # Remove-Item "$env:ProgramData\chocolatey" -Recurse -Force
}
Fix-Environment

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "APP STORE - PHAT TAN PC (GUI VERSION)"
$Form.Size = New-Object System.Drawing.Size(800, 500)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$Lbl = New-Object System.Windows.Forms.Label
$Lbl.Text = "NHAP TEN PHAN MEM CAN TIM (VD: chrome, zoom, ultraview...):"
$Lbl.AutoSize = $true; $Lbl.Location = New-Object System.Drawing.Point(15, 15); $Lbl.Font = "Segoe UI, 10, Bold"
$Form.Controls.Add($Lbl)

# Search Box
$TxtSearch = New-Object System.Windows.Forms.TextBox
$TxtSearch.Size = New-Object System.Drawing.Size(600, 30); $TxtSearch.Location = New-Object System.Drawing.Point(15, 40); $TxtSearch.Font = "Segoe UI, 11"
$Form.Controls.Add($TxtSearch)

# Button Search
$BtnSearch = New-Object System.Windows.Forms.Button
$BtnSearch.Text = "TIM KIEM"
$BtnSearch.Location = New-Object System.Drawing.Point(630, 38); $BtnSearch.Size = New-Object System.Drawing.Size(140, 32)
$BtnSearch.BackColor = "Cyan"; $BtnSearch.ForeColor = "Black"; $BtnSearch.FlatStyle = "Flat"; $BtnSearch.Font = "Segoe UI, 9, Bold"
$Form.Controls.Add($BtnSearch)

# Data Grid View (Bảng kết quả)
$Grid = New-Object System.Windows.Forms.DataGridView
$Grid.Location = New-Object System.Drawing.Point(15, 90); $Grid.Size = New-Object System.Drawing.Size(755, 300)
$Grid.BackgroundColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
$Grid.ForeColor = "Black"
$Grid.AllowUserToAddRows = $false
$Grid.RowHeadersVisible = $false
$Grid.SelectionMode = "FullRowSelect"
$Grid.MultiSelect = $false
$Grid.ReadOnly = $true
$Grid.AutoSizeColumnsMode = "Fill"

$Grid.Columns.Add("Source", "NGUON") | Out-Null
$Grid.Columns.Add("Name", "TEN PHAN MEM") | Out-Null
$Grid.Columns.Add("ID", "ID GOI (PACKAGE)") | Out-Null
$Grid.Columns.Add("Ver", "VERSION") | Out-Null

$Grid.Columns[0].FillWeight = 15
$Grid.Columns[1].FillWeight = 40
$Grid.Columns[2].FillWeight = 30
$Grid.Columns[3].FillWeight = 15
$Form.Controls.Add($Grid)

# Status Bar
$StatusLbl = New-Object System.Windows.Forms.Label
$StatusLbl.Text = "Trang thai: San sang."
$StatusLbl.AutoSize = $true; $Status.Location = New-Object System.Drawing.Point(15, 400); $StatusLbl.ForeColor = "Yellow"
$Form.Controls.Add($StatusLbl)

# Button Install
$BtnInstall = New-Object System.Windows.Forms.Button
$BtnInstall.Text = "CAI DAT APP DA CHON"
$BtnInstall.Location = New-Object System.Drawing.Point(250, 410); $BtnInstall.Size = New-Object System.Drawing.Size(300, 45)
$BtnInstall.BackColor = "LimeGreen"; $BtnInstall.ForeColor = "Black"; $BtnInstall.FlatStyle = "Flat"; $BtnInstall.Font = "Segoe UI, 11, Bold"
$BtnInstall.Enabled = $false
$Form.Controls.Add($BtnInstall)

# --- LOGIC TIM KIEM ---
$BtnSearch.Add_Click({
    $Kw = $TxtSearch.Text
    if ([string]::IsNullOrWhiteSpace($Kw)) { return }
    
    $Grid.Rows.Clear()
    $BtnSearch.Enabled = $false
    $BtnSearch.Text = "DANG TIM..."
    $StatusLbl.Text = "Dang quet Chocolatey & Winget... Vui long doi..."
    $Form.Refresh()

    # 1. Tìm bằng Chocolatey (Nhanh & Chuẩn nhất cho GUI)
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        # Dùng tham số --limit-output để lấy dạng thô: Name|Version|...
        $RawChoco = choco search "$Kw" --limit-output --order-by-popularity
        foreach ($Line in $RawChoco) {
            if ($Line -match "^(.*?)\|(.*?)$") {
                $Parts = $Line -split "\|"
                $Grid.Rows.Add("Choco", $Parts[0], $Parts[0], $Parts[1]) | Out-Null
            }
        }
    } else {
        # Nếu chưa có Choco thì cài
        $StatusLbl.Text = "Phat hien thieu Choco. Dang cai dat nen..."
        $Form.Refresh()
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        } catch {}
    }

    # 2. Tìm bằng Winget (Lọc kết quả đầu)
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        # Winget output dạng text khó parse hơn, lấy đơn giản
        # Chạy job ngầm để không treo UI (Simplified)
        # (Phần Winget này parse text hơi phức tạp, tạm thời ưu tiên Choco cho mượt)
    }

    $StatusLbl.Text = "Tim thay $($Grid.Rows.Count) ket qua."
    $BtnSearch.Text = "TIM KIEM"
    $BtnSearch.Enabled = $true
    
    if ($Grid.Rows.Count -gt 0) { $BtnInstall.Enabled = $true }
})

# --- LOGIC CAI DAT ---
$BtnInstall.Add_Click({
    if ($Grid.SelectedRows.Count -eq 0) { return }
    
    $Row = $Grid.SelectedRows[0]
    $Source = $Row.Cells[0].Value
    $ID = $Row.Cells[2].Value
    
    $BtnInstall.Enabled = $false
    $BtnInstall.Text = "DANG CAI DAT..."
    $StatusLbl.Text = "Dang cai dat: $ID tu nguon $Source..."
    $Form.Refresh()
    
    # Tạo cửa sổ cài đặt riêng để khách nhìn thấy tiến trình
    if ($Source -eq "Choco") {
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "choco install $ID -y; Write-Host '--- CAI DAT XONG! ---' -F Green; Read-Host 'Nhan Enter de dong...'"
    }
    
    $StatusLbl.Text = "Da gui lenh cai dat."
    $BtnInstall.Text = "CAI DAT APP DA CHON"
    $BtnInstall.Enabled = $true
})

$Form.ShowDialog() | Out-Null
