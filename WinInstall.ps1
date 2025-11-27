# --- 1. TỰ ĐỘNG YÊU CẦU QUYỀN ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# --- CẤU HÌNH ---
$WinToHDD_Url = "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/WinToHDD.exe"

# --- NẠP THƯ VIỆN GUI (Kiểm tra kỹ phần này) ---
try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
}
catch {
    Write-Host "LỖI NẠP THƯ VIỆN GUI: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Nhấn Enter để thoát..."
    Exit
}

$ErrorActionPreference = "Continue" # Để hiện lỗi đỏ thay vì im lặng

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CÀI ĐẶT WINDOWS TỰ ĐỘNG - PHÁT TẤN PC (V3.2 DEBUG)"
$Form.Size = New-Object System.Drawing.Size(700, 520)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$LblTitle = New-Object System.Windows.Forms.Label
$LblTitle.Text = "CHỌN FILE ISO WINDOWS (TỰ ĐỘNG QUÉT)"
$LblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$LblTitle.ForeColor = "Cyan"
$LblTitle.AutoSize = $true; $LblTitle.Location = "20,15"
$Form.Controls.Add($LblTitle)

# File Selection
$CmbISO = New-Object System.Windows.Forms.ComboBox
$CmbISO.Size = New-Object System.Drawing.Size(530, 30); $CmbISO.Location = "20,55"; $CmbISO.Font = "Segoe UI, 10"
$CmbISO.DropDownStyle = "DropDownList"
$Form.Controls.Add($CmbISO)

$BtnBrowse = New-Object System.Windows.Forms.Button
$BtnBrowse.Text = "TÌM THỦ CÔNG"
$BtnBrowse.Location = "560,53"; $BtnBrowse.Size = "100,30"; $BtnBrowse.BackColor = "Gray"; $BtnBrowse.ForeColor = "White"
$BtnBrowse.Add_Click({
    $OFD = New-Object System.Windows.Forms.OpenFileDialog
    $OFD.Filter = "ISO Image (*.iso)|*.iso"
    $OFD.Title = "Chọn file ISO Windows"
    if ($OFD.ShowDialog() -eq "OK") { $CmbISO.Items.Insert(0, $OFD.FileName); $CmbISO.SelectedIndex = 0 }
})
$Form.Controls.Add($BtnBrowse)

$LblScan = New-Object System.Windows.Forms.Label
$LblScan.Text = "Đang quét file ISO..."
$LblScan.Location = "20,90"; $LblScan.AutoSize = $true; $LblScan.ForeColor = "Yellow"
$Form.Controls.Add($LblScan)

# --- GROUP 1: CÀI ĐÈ (UPGRADE) ---
$GB1 = New-Object System.Windows.Forms.GroupBox; $GB1.Text = "CHẾ ĐỘ 1: CÀI ĐÈ (Sửa lỗi / Nâng cấp Win)"; $GB1.Location = "20,120"; $GB1.Size = "640,120"; $GB1.ForeColor = "Lime"
$Form.Controls.Add($GB1)

$Lbl1 = New-Object System.Windows.Forms.Label; $Lbl1.Text = "Mount ISO -> Chạy Setup.exe tự động.`nDùng để nâng cấp Win 10 lên 11 hoặc sửa lỗi Win (GIỮ DỮ LIỆU)."; $Lbl1.Location = "20,30"; $Lbl1.AutoSize = $true; $Lbl1.ForeColor = "White"; $GB1.Controls.Add($Lbl1)

$BtnMount = New-Object System.Windows.Forms.Button; $BtnMount.Text = "MỞ FILE ISO VÀ CHẠY SETUP.EXE"; $BtnMount.Location = "20,65"; $BtnMount.Size = "600,35"; $BtnMount.BackColor = "LimeGreen"; $BtnMount.ForeColor = "Black"; $BtnMount.Font = "Segoe UI, 10, Bold"
$BtnMount.Add_Click({
    $ISO = $CmbISO.SelectedItem
    if ($ISO -eq $null -or $ISO -eq "") { [System.Windows.Forms.MessageBox]::Show("Chưa chọn file ISO!", "Lỗi"); return }
    
    try {
        Write-Host "Đang Mount ISO: $ISO" -F Yellow
        $Mount = Mount-DiskImage -ImagePath $ISO -PassThru
        $Vol = $Mount | Get-Volume
        
        if ($Vol) {
            $DriveLetter = $Vol.DriveLetter + ":"
            $SetupPath = "$DriveLetter\setup.exe"
            Invoke-Item $DriveLetter
            
            if (Test-Path $SetupPath) {
                Start-Process $SetupPath
                [System.Windows.Forms.MessageBox]::Show("Đã mở bộ cài Windows ($DriveLetter).`nBấm Next để cài đặt!", "Phát Tấn PC")
                $Form.Close()
            } else {
                [System.Windows.Forms.MessageBox]::Show("Đã Mount ra ổ $DriveLetter, nhưng không thấy file Setup.exe!`n(Có thể đây là ISO WinXP hoặc ISO bị lỗi)", "Cảnh Báo")
            }
        } else { [System.Windows.Forms.MessageBox]::Show("Lỗi: Không lấy được ký tự ổ đĩa ảo.", "Lỗi") }
    } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi Mount ISO: $($_.Exception.Message)", "Lỗi") }
})
$GB1.Controls.Add($BtnMount)

# --- GROUP 2: CÀI MỚI (WINTOHDD) ---
$GB2 = New-Object System.Windows.Forms.GroupBox; $GB2.Text = "CHẾ ĐỘ 2: CÀI MỚI (WinToHDD Technician - Format ổ C)"; $GB2.Location = "20,260"; $GB2.Size = "640,120"; $GB2.ForeColor = "Orange"
$Form.Controls.Add($GB2)

$Lbl2 = New-Object System.Windows.Forms.Label; $Lbl2.Text = "Sử dụng WinToHDD Technician (Portable) từ kho Phát Tấn PC.`nHỗ trợ cài lại Win trắng tinh, Clone Win mà KHÔNG CẦN USB."; $Lbl2.Location = "20,30"; $Lbl2.AutoSize = $true; $Lbl2.ForeColor = "White"; $GB2.Controls.Add($Lbl2)

$BtnWTH = New-Object System.Windows.Forms.Button; $BtnWTH.Text = "TẢI VÀ MỞ WINTOHDD (PORTABLE)"; $BtnWTH.Location = "20,65"; $BtnWTH.Size = "600,35"; $BtnWTH.BackColor = "Orange"; $BtnWTH.ForeColor = "Black"; $BtnWTH.Font = "Segoe UI, 10, Bold"
$BtnWTH.Add_Click({
    $WTHPath = "$env:TEMP\WinToHDD.exe"
    if (Test-Path $WTHPath) { Start-Process $WTHPath } else {
        try {
            $Form.Text = "ĐANG TẢI WINTOHDD TECHNICIAN..."
            (New-Object Net.WebClient).DownloadFile($WinToHDD_Url, $WTHPath)
            if (Test-Path $WTHPath) { Start-Process $WTHPath; $Form.Text = "CÀI ĐẶT WINDOWS TỰ ĐỘNG - PHÁT TẤN PC" } 
            else { [System.Windows.Forms.MessageBox]::Show("Tải thất bại. Kiểm tra lại mạng!", "Lỗi") }
        } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi: $($_.Exception.Message)", "Lỗi") }
    }
})
$GB2.Controls.Add($BtnWTH)

# --- LOGIC AUTO SCAN (FIXED) ---
$Form.Add_Shown({
    $Form.Refresh()
    $LblScan.Text = "Đang quét ISO trong: Downloads, Desktop, Documents, Pictures..."
    
    $ScanPaths = @( 
        "$env:USERPROFILE\Downloads", 
        "$env:USERPROFILE\Desktop", 
        "$env:USERPROFILE\Documents", 
        "$env:USERPROFILE\Pictures",
        $PWD.Path, "D:", "E:" 
    )
    
    $FoundCount = 0
    foreach ($Path in $ScanPaths) {
        if (Test-Path $Path) {
            $ISOs = Get-ChildItem -Path $Path -Filter "*.iso" -File -ErrorAction SilentlyContinue -Recurse -Depth 1
            foreach ($File in $ISOs) {
                if ($File.Length -gt 500MB) { 
                    $CmbISO.Items.Add($File.FullName)
                    $FoundCount++
                }
            }
        }
    }
    
    if ($FoundCount -gt 0) { $CmbISO.SelectedIndex = 0; $LblScan.Text = "Tìm thấy $FoundCount file ISO."; $LblScan.ForeColor = "Lime" } 
    else { $LblScan.Text = "Không tìm thấy file ISO nào > 500MB."; $LblScan.ForeColor = "Red" }
})

# --- CHẠY GUI ---
Write-Host "Đang khởi động giao diện..." -ForegroundColor Cyan
$Result = $Form.ShowDialog()

# --- LỆNH PAUSE ĐỂ XEM LỖI (QUAN TRỌNG) ---
Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "TOOL ĐÃ ĐÓNG. NẾU CÓ LỖI ĐỎ, HÃY ĐỌC Ở TRÊN!" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Read-Host "Nhấn Enter để thoát..."
