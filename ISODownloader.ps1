Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CẤU HÌNH ---
# Link JSON chuẩn (Đã fix lỗi Hostname)
$JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/iso_list.json"

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "ISO DOWNLOADER V5.0 - BITS ENGINE (MICROSOFT TECHNOLOGY)"
$Form.Size = New-Object System.Drawing.Size(700, 480)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

$Global:IsoData = @()

# Header
$Lbl = New-Object System.Windows.Forms.Label; $Lbl.Text = "KHO TAI NGUYEN (BITS ENGINE)"; $Lbl.AutoSize=$true; $Lbl.Location="20,15"; $Lbl.Font="Segoe UI, 12, Bold"; $Lbl.ForeColor="Cyan"; $Form.Controls.Add($Lbl)

# Filter
$GbFilter = New-Object System.Windows.Forms.GroupBox; $GbFilter.Text="Bo Loc"; $GbFilter.Location="20,50"; $GbFilter.Size="640,70"; $GbFilter.ForeColor="Yellow"; $Form.Controls.Add($GbFilter)
$CbType = New-Object System.Windows.Forms.ComboBox; $CbType.Location="20,30"; $CbType.Size="150,30"; $CbType.DropDownStyle="DropDownList"; $GbFilter.Controls.Add($CbType)
$CbBit = New-Object System.Windows.Forms.ComboBox; $CbBit.Location="190,30"; $CbBit.Size="100,30"; $CbBit.DropDownStyle="DropDownList"; $CbBit.Items.AddRange(@("All", "x64", "x86", "arm64")); $CbBit.SelectedIndex=0; $GbFilter.Controls.Add($CbBit)
$BtnLoad = New-Object System.Windows.Forms.Button; $BtnLoad.Text="LAM MOI"; $BtnLoad.Location="500,25"; $BtnLoad.Size="120,35"; $BtnLoad.BackColor="DimGray"; $BtnLoad.ForeColor="White"; $GbFilter.Controls.Add($BtnLoad)

# List
$LblRes = New-Object System.Windows.Forms.Label; $LblRes.Text="Chon File:"; $LblRes.Location="20,130"; $LblRes.AutoSize=$true; $Form.Controls.Add($LblRes)
$CbResult = New-Object System.Windows.Forms.ComboBox; $CbResult.Location="20,155"; $CbResult.Size="640,35"; $CbResult.Font="Segoe UI, 11"; $CbResult.DropDownStyle="DropDownList"; $Form.Controls.Add($CbResult)

# Progress
$Bar = New-Object System.Windows.Forms.ProgressBar; $Bar.Location="20,250"; $Bar.Size="640,30"; $Form.Controls.Add($Bar)
$Status = New-Object System.Windows.Forms.Label; $Status.Text="San sang."; $Status.AutoSize=$true; $Status.Location="20,220"; $Status.ForeColor="Lime"; $Form.Controls.Add($Status)

# Button
$BtnDown = New-Object System.Windows.Forms.Button; $BtnDown.Text="DOWNLOAD BITS (ON DINH NHAT)"; $BtnDown.Font="Segoe UI, 12, Bold"; $BtnDown.Location="180,310"; $BtnDown.Size="340,50"; $BtnDown.BackColor="LimeGreen"; $BtnDown.ForeColor="Black"; $BtnDown.FlatStyle="Flat"; $BtnDown.Enabled=$false; $Form.Controls.Add($BtnDown)

# --- BITS ENGINE CORE ---
function Start-BitsDownload ($Url, $DestPath) {
    Import-Module BitsTransfer
    $Status.Text = "Dang khoi tao BITS Transfer..."
    $Bar.Value = 0
    [System.Windows.Forms.Application]::DoEvents()

    try {
        # Bắt đầu tải BITS (Asynchronous - Không treo máy)
        # Priority Foreground = Ép mạng chạy max tốc độ (mặc định BITS chạy nền sẽ chậm)
        $Job = Start-BitsTransfer -Source $Url -Destination $DestPath -Asynchronous -Priority Foreground -DisplayName "PhatTan_ISO_Download"
        
        # Vòng lặp cập nhật tiến độ
        while ($Job.JobState -eq "Transferring" -or $Job.JobState -eq "Connecting" -or $Job.JobState -eq "Queued") {
            $Job = Get-BitsTransfer -JobId $Job.JobId
            
            if ($Job.TotalBytes -gt 0) {
                $Percent = [Math]::Min(100, [Math]::Round(($Job.BytesTransferred / $Job.TotalBytes) * 100))
                $Bar.Value = [int]$Percent
                
                $MB_Trans = [Math]::Round($Job.BytesTransferred / 1MB, 2)
                $MB_Total = [Math]::Round($Job.TotalBytes / 1MB, 2)
                
                $Status.Text = "BITS Running... $Percent% ($MB_Trans MB / $MB_Total MB)"
            } else {
                $Status.Text = "Dang ket noi Server..."
            }
            
            # Giữ cho giao diện không bị đơ
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 250
        }
        
        # Kiểm tra kết quả
        if ($Job.JobState -eq "Transferred") {
            Complete-BitsTransfer -JobId $Job.JobId
            $Bar.Value = 100
            $Status.Text = "HOAN TAT! File luu tai: $DestPath"
            [System.Windows.Forms.MessageBox]::Show("Tai thanh cong (BITS Engine)!", "Phat Tan PC")
            Invoke-Item (Split-Path $DestPath)
        }
        else {
            # Nếu lỗi
            $Err = $Job | Select-Object -ExpandProperty Error
            $Msg = if ($Err) { $Err.Message } else { $Job.JobState }
            $Status.Text = "Loi: $Msg"
            # Hủy job lỗi để không treo
            Remove-BitsTransfer -JobId $Job.JobId -ErrorAction SilentlyContinue
            [System.Windows.Forms.MessageBox]::Show("Loi BITS: $Msg", "Error")
        }
        
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Loi he thong: $($_.Exception.Message)", "Error")
    }
}

# --- HANDLERS ---
function Load-JsonData {
    $Status.Text = "Dang tai danh sach..."
    $Form.Cursor = "WaitCursor"
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    try {
        $Ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        $Headers = @{ "User-Agent" = "Mozilla/5.0"; "Cache-Control" = "no-cache" }
        
        # Link JSON đã fix lỗi khoảng trắng
        $JsonContent = Invoke-RestMethod -Uri "$($JsonUrl.Trim())?t=$Ts" -Headers $Headers -ErrorAction Stop
        
        if (!$JsonContent) { throw "JSON Empty" }
        $Global:IsoData = $JsonContent
        
        $CbType.Items.Clear(); $CbType.Items.Add("All")
        $Types = $Global:IsoData | Select-Object -ExpandProperty type -Unique | Sort-Object
        foreach ($t in $Types) { $CbType.Items.Add($t) }
        $CbType.SelectedIndex = 0
        Filter-List
        $Status.Text = "San sang. ($($Global:IsoData.Count) muc)"
    } catch {
        $Err = $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show("Loi tai JSON: $Err", "Error")
    }
    $Form.Cursor = "Default"
}

function Filter-List {
    $CbResult.Items.Clear()
    $T = $CbType.SelectedItem; $B = $CbBit.SelectedItem
    $List = $Global:IsoData
    if ($T -ne "All") { $List = $List | Where-Object { $_.type -eq $T } }
    if ($B -ne "All") { $List = $List | Where-Object { $_.bit -eq $B } }
    foreach ($I in $List) { $CbResult.Items.Add($I.name) }
    if ($CbResult.Items.Count -gt 0) { $CbResult.SelectedIndex=0; $BtnDown.Enabled=$true } else { $BtnDown.Enabled=$false }
}

$CbType.Add_SelectedIndexChanged({ Filter-List })
$CbBit.Add_SelectedIndexChanged({ Filter-List })
$BtnLoad.Add_Click({ Load-JsonData })

$BtnDown.Add_Click({
    $Sel = $CbResult.SelectedItem
    $Item = $Global:IsoData | Where-Object { $_.name -eq $Sel } | Select-Object -First 1
    if (!$Item) { return }
    
    $FName = "Download.iso"
    if ($Item.link -match "/([^/]+\.iso)$") { $FName = $Matches[1] }
    elseif ($Item.link -match "/([^/]+\.img)$") { $FName = $Matches[1] }
    elseif ($Item.link -match "/([^/]+\.exe)$") { $FName = $Matches[1] }
    
    $Save = New-Object System.Windows.Forms.SaveFileDialog
    $Save.FileName = $FName; $Save.Filter = "All Files|*.*"
    
    if ($Save.ShowDialog() -eq "OK") {
        $BtnDown.Enabled = $false; $CbResult.Enabled = $false
        Start-BitsDownload $Item.link $Save.FileName
        $BtnDown.Enabled = $true; $CbResult.Enabled = $true
    }
})

$Form.Add_Shown({ Load-JsonData })
$Form.ShowDialog() | Out-Null
