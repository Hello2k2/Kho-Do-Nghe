Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CẤU HÌNH ONLINE ---
# Link file JSON (Đã sửa lại link chuẩn main)
$JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/iso_list.json"

# --- TỐI ƯU TỐC ĐỘ MẠNG ---
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::DefaultConnectionLimit = 100
[System.Net.ServicePointManager]::Expect100Continue = $false

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CLOUD ISO DOWNLOADER - PHAT TAN PC (TRIM FIXED)"
$Form.Size = New-Object System.Drawing.Size(700, 450)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Biến toàn cục chứa data
$Global:IsoData = @()

# Tiêu đề
$Lbl = New-Object System.Windows.Forms.Label
$Lbl.Text = "KHO TAI NGUYEN WINDOWS / OFFICE / DRIVER"
$Lbl.AutoSize = $true; $Lbl.Location = New-Object System.Drawing.Point(20, 15)
$Lbl.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$Lbl.ForeColor = "Cyan"
$Form.Controls.Add($Lbl)

# --- KHU VỰC LỌC (FILTER) ---
$GbFilter = New-Object System.Windows.Forms.GroupBox
$GbFilter.Text = "Bo Loc Tim Kiem"
$GbFilter.Location = "20, 50"; $GbFilter.Size = "640, 70"; $GbFilter.ForeColor = "Yellow"
$Form.Controls.Add($GbFilter)

# Combo Type
$CbType = New-Object System.Windows.Forms.ComboBox; $CbType.Location = "20, 30"; $CbType.Size = "150, 30"; $CbType.DropDownStyle = "DropDownList"
$GbFilter.Controls.Add($CbType)

# Combo Bit
$CbBit = New-Object System.Windows.Forms.ComboBox; $CbBit.Location = "190, 30"; $CbBit.Size = "100, 30"; $CbBit.DropDownStyle = "DropDownList"
$CbBit.Items.AddRange(@("All", "x64", "x86", "arm64"))
$CbBit.SelectedIndex = 0
$GbFilter.Controls.Add($CbBit)

# Nút Lọc
$BtnLoad = New-Object System.Windows.Forms.Button; $BtnLoad.Text = "LAM MOI DS"; $BtnLoad.Location = "500, 25"; $BtnLoad.Size = "120, 35"
$BtnLoad.BackColor = "DimGray"; $BtnLoad.ForeColor = "White"
$GbFilter.Controls.Add($BtnLoad)

# --- DANH SÁCH KẾT QUẢ ---
$LblRes = New-Object System.Windows.Forms.Label; $LblRes.Text = "Chon File Can Tai:"; $LblRes.Location = "20, 130"; $LblRes.AutoSize=$true
$Form.Controls.Add($LblRes)

$CbResult = New-Object System.Windows.Forms.ComboBox
$CbResult.Location = "20, 155"; $CbResult.Size = "640, 35"
$CbResult.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$CbResult.DropDownStyle = "DropDownList"
$Form.Controls.Add($CbResult)

# --- THANH TIẾN TRÌNH ---
$Bar = New-Object System.Windows.Forms.ProgressBar
$Bar.Location = New-Object System.Drawing.Point(20, 250); $Bar.Size = New-Object System.Drawing.Size(640, 30)
$Form.Controls.Add($Bar)

$Status = New-Object System.Windows.Forms.Label
$Status.Text = "Trang thai: Dang cho du lieu..."
$Status.AutoSize = $true; $Status.Location = New-Object System.Drawing.Point(20, 220); $Status.Font = "Segoe UI, 10"; $Status.ForeColor = "Lime"
$Form.Controls.Add($Status)

$BtnDown = New-Object System.Windows.Forms.Button
$BtnDown.Text = "DOWNLOAD NGAY (MAX SPEED)"
$BtnDown.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$BtnDown.Location = New-Object System.Drawing.Point(180, 310); $BtnDown.Size = New-Object System.Drawing.Size(340, 50)
$BtnDown.BackColor = "LimeGreen"; $BtnDown.ForeColor = "Black"; $BtnDown.FlatStyle = "Flat"
$BtnDown.Enabled = $false

# --- HÀM XỬ LÝ (FIXED TRIM) ---

# 1. Hàm tải JSON
function Load-JsonData {
    $Status.Text = "Dang tai danh sach tu Github..."
    $Form.Cursor = "WaitCursor"
    
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

    try {
        $Ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        
        $Headers = @{
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) PowerShell/ISODownloader"
            "Cache-Control" = "no-cache"
        }

        # === FIX LỖI HOSTNAME: THÊM .Trim() VÀO ĐÂY ===
        $CleanUrl = "$($JsonUrl.Trim())?t=$Ts"
        
        # Tải dữ liệu
        $JsonContent = Invoke-RestMethod -Uri $CleanUrl -Headers $Headers -ErrorAction Stop
        
        if (!$JsonContent) { throw "File JSON rong hoac sai dinh dang." }

        $Global:IsoData = $JsonContent
        
        # Nạp dữ liệu vào bộ lọc Type
        $CbType.Items.Clear()
        $CbType.Items.Add("All")
        $Types = $Global:IsoData | Select-Object -ExpandProperty type -Unique | Sort-Object
        foreach ($t in $Types) { $CbType.Items.Add($t) }
        $CbType.SelectedIndex = 0
        
        Filter-List
        $Status.Text = "Da tai xong danh sach! (" + $Global:IsoData.Count + " muc)"
    } catch {
        $Err = $_.Exception.Message
        $Status.Text = "Loi: $Err"
        # Hiện link CleanUrl để debug xem đã sạch chưa
        [System.Windows.Forms.MessageBox]::Show("LOI TAI DANH SACH ISO!`n`nLoi: $Err`n`nLink Debug: [$CleanUrl]", "Loi Mang", "OK", "Error")
    }
    $Form.Cursor = "Default"
}

# 2. Hàm lọc danh sách
function Filter-List {
    $CbResult.Items.Clear()
    $SelType = $CbType.SelectedItem
    $SelBit = $CbBit.SelectedItem
    
    $Filtered = $Global:IsoData
    if ($SelType -ne "All") { $Filtered = $Filtered | Where-Object { $_.type -eq $SelType } }
    if ($SelBit -ne "All") { $Filtered = $Filtered | Where-Object { $_.bit -eq $SelBit } }
    
    foreach ($Item in $Filtered) {
        $CbResult.Items.Add($Item.name)
    }
    
    if ($CbResult.Items.Count -gt 0) { 
        $CbResult.SelectedIndex = 0; $BtnDown.Enabled = $true 
    } else { 
        $CbResult.Text = ""; $BtnDown.Enabled = $false 
    }
}

# Sự kiện thay đổi bộ lọc
$CbType.Add_SelectedIndexChanged({ Filter-List })
$CbBit.Add_SelectedIndexChanged({ Filter-List })
$BtnLoad.Add_Click({ Load-JsonData })

# 3. Hàm tải file
$BtnDown.Add_Click({
    $SelectedName = $CbResult.SelectedItem
    $TargetItem = $Global:IsoData | Where-Object { $_.name -eq $SelectedName } | Select-Object -First 1
    
    if (!$TargetItem) { return }
    $Url = $TargetItem.link
    
    # Tạo tên file gợi ý
    $FileName = "Download.iso"
    if ($Url -match "/([^/]+\.iso)$") { $FileName = $Matches[1] }
    elseif ($Url -match "/([^/]+\.img)$") { $FileName = $Matches[1] }
    else { $FileName = "$($TargetItem.type)_$($TargetItem.bit).iso" }

    $SaveDlg = New-Object System.Windows.Forms.SaveFileDialog
    $SaveDlg.FileName = $FileName
    $SaveDlg.Filter = "Disk Image (*.iso;*.img)|*.iso;*.img|All Files (*.*)|*.*"
    
    if ($SaveDlg.ShowDialog() -eq "OK") {
        $LocalPath = $SaveDlg.FileName
        $BtnDown.Enabled = $false; $CbResult.Enabled = $false
        
        try {
            $WebClient = New-Object System.Net.WebClient
            $WebClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
            
            $WebClient.Add_DownloadProgressChanged({
                $Percent = $_.ProgressPercentage
                $Bar.Value = $Percent
                $DaTai = [Math]::Round($_.BytesReceived / 1MB, 2)
                $Tong  = [Math]::Round($_.TotalBytesToReceive / 1MB, 2)
                $Status.Text = "Dang tai... $Percent% ($DaTai MB / $Tong MB)"
            })
            
            $WebClient.Add_DownloadFileCompleted({
                $Bar.Value = 100
                $Status.Text = "HOAN TAT! Luu tai: $LocalPath"
                $BtnDown.Enabled = $true; $CbResult.Enabled = $true
                [System.Windows.Forms.MessageBox]::Show("Tai thanh cong!`nFile: $LocalPath", "Phat Tan PC")
                Invoke-Item (Split-Path $LocalPath)
            })
            
            $Status.Text = "Dang ket noi Server (High Speed)..."
            $WebClient.DownloadFileAsync($Url, $LocalPath)
            
        } catch {
            $Status.Text = "Loi: $($_.Exception.Message)"
            $BtnDown.Enabled = $true; $CbResult.Enabled = $true
            [System.Windows.Forms.MessageBox]::Show("Loi Download: $($_.Exception.Message)", "Error")
        }
    }
})

$Form.Controls.Add($BtnDown)

# Tự động tải JSON khi mở Form
$Form.Add_Shown({ Load-JsonData })
$Form.ShowDialog() | Out-Null
