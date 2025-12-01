Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "SYSTEM CLEANER PRO - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(700, 500)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
$Form.ForeColor = "Lime"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Tiêu đề
$LblTitle = New-Object System.Windows.Forms.Label
$LblTitle.Text = "DEEP SYSTEM CLEANING"
$LblTitle.Font = New-Object System.Drawing.Font("Impact", 18)
$LblTitle.ForeColor = "Cyan"
$LblTitle.AutoSize = $true
$LblTitle.Location = "20, 15"
$Form.Controls.Add($LblTitle)

# Khung Log (Quan trọng để khách nhìn cho sướng)
$TxtLog = New-Object System.Windows.Forms.TextBox
$TxtLog.Multiline = $true
$TxtLog.ScrollBars = "Vertical"
$TxtLog.Location = New-Object System.Drawing.Point(20, 60)
$TxtLog.Size = New-Object System.Drawing.Size(645, 300)
$TxtLog.BackColor = [System.Drawing.Color]::Black
$TxtLog.ForeColor = "Lime"
$TxtLog.Font = New-Object System.Drawing.Font("Consolas", 10)
$TxtLog.ReadOnly = $true
$Form.Controls.Add($TxtLog)

# Biến tổng dung lượng dọn được
$Global:TotalCleaned = 0

# Hàm ghi Log
function Log ($Msg) {
    $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $Msg`r`n")
    $TxtLog.SelectionStart = $TxtLog.Text.Length
    $TxtLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents() # Giúp UI không bị treo
}

# Hàm xóa file an toàn
function Remove-Safe ($Path, $Desc) {
    if (Test-Path $Path) {
        Log "Scanning $Desc..."
        $Files = Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
        foreach ($F in $Files) {
            try {
                $Size = $F.Length
                Remove-Item $F.FullName -Force -Recurse -ErrorAction Stop
                $Global:TotalCleaned += $Size
                # Log "Deleted: $($F.Name)" # Bỏ comment nếu muốn hiện từng file (nhưng sẽ chậm)
            } catch {}
        }
        Log ">>> DONE: $Desc"
    } else {
        Log "Skipped: $Desc (Not found)"
    }
}

# NÚT: QUICK CLEAN (Dọn cơ bản)
$BtnQuick = New-Object System.Windows.Forms.Button
$BtnQuick.Text = "QUICK CLEAN (DON NHANH)"
$BtnQuick.Location = "20, 380"
$BtnQuick.Size = "310, 60"
$BtnQuick.BackColor = "Green"
$BtnQuick.ForeColor = "White"
$BtnQuick.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$BtnQuick.FlatStyle = "Flat"

$BtnQuick.Add_Click({
    $BtnQuick.Enabled = $false; $BtnDeep.Enabled = $false
    $Global:TotalCleaned = 0
    $TxtLog.Text = "--- STARTING QUICK CLEAN ---`r`n"
    
    # 1. Dọn Temp User
    Remove-Safe "$env:TEMP" "User Temp Folder"
    
    # 2. Dọn Temp Windows
    Remove-Safe "$env:SystemRoot\Temp" "Windows Temp Folder"
    
    # 3. Dọn Prefetch (Giúp khởi động nhanh hơn chút)
    Remove-Safe "$env:SystemRoot\Prefetch" "Windows Prefetch"
    
    # 4. Dọn Thùng Rác
    Log "Emptying Recycle Bin..."
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    
    $MB = [Math]::Round($Global:TotalCleaned / 1MB, 2)
    Log "----------------------------------"
    Log "COMPLETED! RECOVERED: $MB MB"
    [System.Windows.Forms.MessageBox]::Show("Da don dep xong! Giai phong: $MB MB", "Success")
    $BtnQuick.Enabled = $true; $BtnDeep.Enabled = $true
})
$Form.Controls.Add($BtnQuick)

# NÚT: DEEP CLEAN (Dọn sâu - Update Cache)
$BtnDeep = New-Object System.Windows.Forms.Button
$BtnDeep.Text = "DEEP CLEAN (DON SAU - UPDATE)"
$BtnDeep.Location = "355, 380"
$BtnDeep.Size = "310, 60"
$BtnDeep.BackColor = "OrangeRed"
$BtnDeep.ForeColor = "White"
$BtnDeep.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$BtnDeep.FlatStyle = "Flat"

$BtnDeep.Add_Click({
    if ([System.Windows.Forms.MessageBox]::Show("Che do nay se Reset Windows Update Service.`nBan co muon tiep tuc?", "Warning", "YesNo", "Warning") -eq "Yes") {
        $BtnQuick.Enabled = $false; $BtnDeep.Enabled = $false
        $Global:TotalCleaned = 0
        $TxtLog.Text = "--- STARTING DEEP CLEAN ---`r`n"
        
        # 1. Stop Services
        Log "Stopping Windows Update Service..."
        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        Stop-Service -Name bits -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        
        # 2. Dọn SoftwareDistribution (Nơi chứa file update tải về)
        Remove-Safe "$env:SystemRoot\SoftwareDistribution\Download" "Update Cache (Downloads)"
        
        # 3. Dọn Logs
        Log "Clearing System Event Logs..."
        Get-EventLog -List | ForEach-Object { Clear-EventLog -LogName $_.Log -ErrorAction SilentlyContinue }
        
        # 4. Start Services
        Log "Restarting Services..."
        Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        Start-Service -Name bits -ErrorAction SilentlyContinue
        
        $MB = [Math]::Round($Global:TotalCleaned / 1MB, 2)
        Log "----------------------------------"
        Log "DEEP CLEAN COMPLETED! RECOVERED: $MB MB"
        [System.Windows.Forms.MessageBox]::Show("Da don dep chuyen sau! Giai phong: $MB MB", "Success")
        $BtnQuick.Enabled = $true; $BtnDeep.Enabled = $true
    }
})
$Form.Controls.Add($BtnDeep)

$Form.ShowDialog() | Out-Null
