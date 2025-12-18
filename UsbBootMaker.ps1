<#
    USB BOOT MAKER - PHAT TAN PC (FINAL FIX PARTITION & SCROLLBAR)
    Fix:
    1. Lỗi DiskPart không tạo được phân vùng Data (Unallocated).
    2. Thêm thanh cuộn (Scrollbar) cho vùng Cấu hình.
#>

# 1. THIẾT LẬP ENCODING & THƯ VIỆN
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

# 2. CẤU HÌNH
$Global:JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/bootkits.json"
$Global:TempDir = "$env:TEMP\UsbBootMaker"
if (!(Test-Path $Global:TempDir)) { New-Item -ItemType Directory -Path $Global:TempDir -Force | Out-Null }

# 3. GIAO DIỆN (THEME DARK TITANIUM)
$Theme = @{
    BgForm   = [System.Drawing.Color]::FromArgb(20, 20, 25)
    Card     = [System.Drawing.Color]::FromArgb(35, 35, 40)
    Text     = [System.Drawing.Color]::FromArgb(240, 240, 240)
    Muted    = [System.Drawing.Color]::FromArgb(150, 150, 150)
    Cyan     = [System.Drawing.Color]::FromArgb(0, 255, 255) # Màu Neon
    Red      = [System.Drawing.Color]::FromArgb(255, 50, 80)
    InputBg  = [System.Drawing.Color]::FromArgb(50, 50, 55)
}

# --- HÀM HỖ TRỢ ---
function Log-Msg ($Msg) { 
    $TxtLog.Text += "[$(Get-Date -F 'HH:mm:ss')] $Msg`r`n"
    $TxtLog.SelectionStart = $TxtLog.Text.Length; $TxtLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function Run-DiskPartScript ($ScriptContent) {
    $F = "$Global:TempDir\dp_script.txt"; [IO.File]::WriteAllText($F, $ScriptContent)
    $P = Start-Process "diskpart" "/s `"$F`"" -Wait -NoNewWindow -PassThru
    return $P.ExitCode
}

function Get-DriveLetterByLabel ($Label) {
    # Cách 1: Get-Volume (Win 10/11)
    if (Get-Command "Get-Volume" -ErrorAction SilentlyContinue) {
        try {
            Get-Disk | Update-Disk -ErrorAction SilentlyContinue
            $Vol = Get-Volume | Where-Object { $_.FileSystemLabel -eq $Label } | Select-Object -First 1
            if ($Vol -and $Vol.DriveLetter) { return "$($Vol.DriveLetter):" }
        } catch {}
    }
    # Cách 2: WMI (Win 7/Lite/PE)
    try {
        $WmiVol = Get-WmiObject -Class Win32_Volume -Filter "Label = '$Label'" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($WmiVol -and $WmiVol.DriveLetter) { return $WmiVol.DriveLetter }
    } catch {}
    # Cách 3: LogicalDisk (Cổ điển nhất)
    try {
        $Disks = Get-WmiObject Win32_LogicalDisk
        foreach ($D in $Disks) { if ($D.VolumeName -eq $Label) { return $D.DeviceID } }
    } catch {}
    return $null
}

function Add-GlowBorder ($Panel) {
    $Panel.Add_Paint({
        param($s, $e)
        $Pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(0, 255, 255), 1)
        $Rect = $s.ClientRectangle; $Rect.Width-=1; $Rect.Height-=1
        $e.Graphics.DrawRectangle($Pen, $Rect)
        $Pen.Dispose()
    })
}

# --- KHỞI TẠO FORM ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "USB BOOT MAKER ULTIMATE - PHÁT TẤN PC"
$Form.Size = New-Object System.Drawing.Size(900, 750)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.BgForm
$Form.ForeColor = $Theme.Text
$Form.Padding = New-Object System.Windows.Forms.Padding(15)

$F_Title = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$F_Bold  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$F_Norm  = New-Object System.Drawing.Font("Segoe UI", 10)
$F_Code  = New-Object System.Drawing.Font("Consolas", 9)

# --- LAYOUT CHÍNH (GRID) ---
$MainLayout = New-Object System.Windows.Forms.TableLayoutPanel
$MainLayout.Dock = "Fill"
$MainLayout.ColumnCount = 1
$MainLayout.RowCount = 5
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) # Header
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) # USB
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) # Kit
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) # Settings
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) # Log
$Form.Controls.Add($MainLayout)

# 1. HEADER
$PnlTitle = New-Object System.Windows.Forms.Panel; $PnlTitle.Height = 50; $PnlTitle.Dock="Top"; $PnlTitle.Margin="0,0,0,10"
$LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text = "⚡ USB BOOT CREATOR ULTIMATE"; $LblTitle.Font = $F_Title; $LblTitle.ForeColor = $Theme.Cyan; $LblTitle.AutoSize = $true; $LblTitle.Location="10,10"
$PnlTitle.Controls.Add($LblTitle)
$MainLayout.Controls.Add($PnlTitle, 0, 0)

# Function tạo Card Panel
function New-CardPanel ($Title) {
    $P = New-Object System.Windows.Forms.Panel; $P.BackColor = $Theme.Card; $P.Padding = 10; $P.Margin = "0,0,0,15"; $P.Dock = "Top"; $P.AutoSize = $true; Add-GlowBorder $P
    $L = New-Object System.Windows.Forms.Label; $L.Text = $Title; $L.Font = $F_Bold; $L.ForeColor = $Theme.Muted; $L.Dock = "Top"; $L.Height = 25; $P.Controls.Add($L)
    return $P
}

# 2. CHỌN USB
$CardUSB = New-CardPanel "1. CHỌN THIẾT BỊ USB (DỮ LIỆU SẼ BỊ XÓA)"
$LayoutUSB = New-Object System.Windows.Forms.TableLayoutPanel; $LayoutUSB.Dock="Top"; $LayoutUSB.Height=40; $LayoutUSB.ColumnCount=2
$LayoutUSB.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 80)))
$LayoutUSB.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 20)))
$CbUSB = New-Object System.Windows.Forms.ComboBox; $CbUSB.Dock="Fill"; $CbUSB.Font=$F_Norm; $CbUSB.BackColor=$Theme.InputBg; $CbUSB.ForeColor="White"; $CbUSB.DropDownStyle="DropDownList"
$BtnRef = New-Object System.Windows.Forms.Button; $BtnRef.Text="LÀM MỚI"; $BtnRef.Dock="Fill"; $BtnRef.BackColor=$Theme.InputBg; $BtnRef.ForeColor="White"; $BtnRef.FlatStyle="Flat"
$LayoutUSB.Controls.Add($CbUSB, 0, 0); $LayoutUSB.Controls.Add($BtnRef, 1, 0); $CardUSB.Controls.Add($LayoutUSB); $MainLayout.Controls.Add($CardUSB, 0, 1)

# 3. CHỌN KIT
$CardKit = New-CardPanel "2. CHỌN PHIÊN BẢN BOOT"
$CbKit = New-Object System.Windows.Forms.ComboBox; $CbKit.Dock="Top"; $CbKit.Font=$F_Norm; $CbKit.BackColor=$Theme.InputBg; $CbKit.ForeColor="White"; $CbKit.DropDownStyle="DropDownList"
$CardKit.Controls.Add($CbKit); $MainLayout.Controls.Add($CardKit, 0, 2)

# 4. CẤU HÌNH (CÓ THANH CUỘN)
$CardSet = New-Object System.Windows.Forms.GroupBox; $CardSet.Text="3. TÙY CHỈNH NÂNG CAO"; $CardSet.Height=160; $CardSet.Dock="Top"; $CardSet.ForeColor=[System.Drawing.Color]::Gold; $CardSet.Padding="5,20,5,5"
# Tạo Panel cuộn bên trong GroupBox
$PnlScrollSet = New-Object System.Windows.Forms.Panel; $PnlScrollSet.Dock="Fill"; $PnlScrollSet.AutoScroll=$true
$CardSet.Controls.Add($PnlScrollSet)

# Grid bên trong Panel cuộn
$GridSet = New-Object System.Windows.Forms.TableLayoutPanel; $GridSet.Dock="Top"; $GridSet.AutoSize=$true; $GridSet.ColumnCount=3; $GridSet.RowCount=2
$GridSet.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33)))
$GridSet.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33)))
$GridSet.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33)))
$PnlScrollSet.Controls.Add($GridSet)

function Add-Setting ($L, $C, $R, $Cl) {
    $P = New-Object System.Windows.Forms.Panel; $P.Dock="Top"; $P.Height=60; $P.Padding=5
    $Lb = New-Object System.Windows.Forms.Label; $Lb.Text=$L; $Lb.Dock="Top"; $Lb.Height=20; $Lb.ForeColor="Silver"
    $C.Dock="Top"; $C.Font=$F_Norm; $C.BackColor=$Theme.InputBg; $C.ForeColor="White"
    $P.Controls.Add($C); $P.Controls.Add($Lb); $GridSet.Controls.Add($P, $Cl, $R)
}

$CbStyle = New-Object System.Windows.Forms.ComboBox; $CbStyle.Items.AddRange(@("MBR (Legacy+UEFI)", "GPT (UEFI Only)")); $CbStyle.SelectedIndex=0; $CbStyle.DropDownStyle="DropDownList"
Add-Setting "Kiểu Partition:" $CbStyle 0 0

$NumSize = New-Object System.Windows.Forms.NumericUpDown; $NumSize.Minimum=100; $NumSize.Maximum=8192; $NumSize.Value=512
Add-Setting "Dung lượng Boot (MB):" $NumSize 0 1

$TxtBoot = New-Object System.Windows.Forms.TextBox; $TxtBoot.Text="GLIM_BOOT"
Add-Setting "Nhãn Boot:" $TxtBoot 0 2

$CbFS = New-Object System.Windows.Forms.ComboBox; $CbFS.Items.AddRange(@("NTFS", "exFAT", "FAT32")); $CbFS.SelectedIndex=0; $CbFS.DropDownStyle="DropDownList"
Add-Setting "Định dạng Data:" $CbFS 1 0

$TxtData = New-Object System.Windows.Forms.TextBox; $TxtData.Text="GLIM_DATA"
Add-Setting "Nhãn Data:" $TxtData 1 1

$MainLayout.Controls.Add($CardSet, 0, 3)

# 5. LOG
$PnlLog = New-Object System.Windows.Forms.Panel; $PnlLog.Dock="Fill"; $PnlLog.Padding="0,10,0,0"
$TxtLog = New-Object System.Windows.Forms.TextBox; $TxtLog.Multiline=$true; $TxtLog.Dock="Fill"; $TxtLog.BackColor="Black"; $TxtLog.ForeColor="Lime"; $TxtLog.Font=$F_Code; $TxtLog.ReadOnly=$true; $TxtLog.ScrollBars="Vertical"
$PnlLog.Controls.Add($TxtLog); $MainLayout.Controls.Add($PnlLog, 0, 4)

# 6. BUTTON START
$BtnStart = New-Object System.Windows.Forms.Button; $BtnStart.Text = "🚀 BẮT ĐẦU TẠO USB"; $BtnStart.Font = $F_Title; $BtnStart.BackColor = $Theme.Cyan; $BtnStart.ForeColor = "Black"; $BtnStart.FlatStyle = "Flat"; $BtnStart.Dock = "Bottom"; $BtnStart.Height = 60
$Form.Controls.Add($BtnStart)

# --- LOGIC XỬ LÝ ---

function Load-UsbList {
    $CbUSB.Items.Clear(); $UseWMI=$false
    if (Get-Command "Get-Disk" -ErrorAction SilentlyContinue) {
        try {
            $Ds = @(Get-Disk -ErrorAction Stop | Where { $_.BusType -eq "USB" -or $_.MediaType -eq "Removable" })
            if ($Ds.Count -eq 0) { throw }
            foreach ($D in $Ds) { $CbUSB.Items.Add("Disk $($D.Number): $($D.FriendlyName) ($([Math]::Round($D.Size/1GB,1)) GB)") }
        } catch { $UseWMI=$true }
    } else { $UseWMI=$true }
    if ($UseWMI) {
        try { $Ds=@(Get-WmiObject Win32_DiskDrive | Where{$_.InterfaceType -eq "USB"}); foreach($D in $Ds){ $CbUSB.Items.Add("Disk $($D.Index): $($D.Model)") } } catch {}
    }
    if ($CbUSB.Items.Count -gt 0) { $CbUSB.SelectedIndex=0 } else { $CbUSB.Items.Add("Không tìm thấy USB"); $CbUSB.SelectedIndex=0 }
}

function Load-Kits {
    $CbKit.Items.Clear(); Log-Msg "Đang tải danh sách từ GitHub..."
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $Json = Invoke-RestMethod -Uri "$($Global:JsonUrl)?t=$(Get-Date -UFormat %s)" -Headers @{"Cache-Control"="no-cache"} -ErrorAction Stop
        if ($Json) { foreach ($I in $Json) { if($I.Name){$CbKit.Items.Add($I.Name); $Global:KitData=$Json} } }
        if ($CbKit.Items.Count -gt 0) { $CbKit.SelectedIndex=0; Log-Msg "Đã tải xong." }
    } catch { $CbKit.Items.Add("Chế độ Demo (Mất mạng)"); $CbKit.SelectedIndex=0; Log-Msg "Lỗi tải JSON." }
}

function Download-File ($Url, $Dest) {
    Log-Msg "Đang tải xuống..."; try { (New-Object Net.WebClient).DownloadFile($Url, $Dest); return $true } catch { Log-Msg "Lỗi tải file!"; return $false }
}

$BtnStart.Add_Click({
    if ($CbUSB.SelectedItem -match "Disk (\d+)") { $DiskID = $Matches[1] } else { return }
    $Kit = $Global:KitData | Where {$_.Name -eq $CbKit.SelectedItem} | Select -First 1
    if (!$Kit) { return }
    if ([System.Windows.Forms.MessageBox]::Show("XÓA SẠCH DỮ LIỆU DISK $DiskID?","CẢNH BÁO","YesNo","Warning") -ne "Yes") { return }

    $BtnStart.Enabled=$false; $Form.Cursor="WaitCursor"
    
    # 1. DOWNLOAD
    $ZipPath = "$Global:TempDir\$($Kit.FileName)"
    if (!(Test-Path $ZipPath)) {
        Log-Msg "Đang tải: $($Kit.FileName)..."
        if (!(Download-File $Kit.Url $ZipPath)) { $BtnStart.Enabled=$true; $Form.Cursor="Default"; return }
    }

    # 2. DISKPART (FIXED LOGIC)
    $Style = if($CbStyle.SelectedIndex -eq 0){"mbr"}else{"gpt"}; $Size=$NumSize.Value; $BL=$TxtBoot.Text; $DL=$TxtData.Text; $FS=$CbFS.SelectedItem
    Log-Msg "Đang Format: $Style | Boot: $Size MB | Data: $FS"
    
    # Kịch bản DiskPart CHUẨN:
    # 1. Clean & Convert
    # 2. Tạo Boot -> Format -> Active -> Assign
    # 3. Tạo Data (KHÔNG set size -> Lấy hết phần còn lại) -> Format -> Assign
    $Cmd = @"
select disk $DiskID
clean
convert $Style
create partition primary size=$Size
format fs=fat32 quick label="$BL"
active
assign
create partition primary
format fs=$FS quick label="$DL"
assign
exit
"@
    Run-DiskPartScript $Cmd
    Log-Msg "Đang đợi Windows nhận ổ đĩa (10s)..."; Start-Sleep 10

    # 3. DETECT
    for($i=1; $i -le 3; $i++) {
        $BDrv = Get-DriveLetterByLabel $BL
        $DDrv = Get-DriveLetterByLabel $DL
        if ($BDrv -and $DDrv) { break }
        Log-Msg "Đang thử lại ($i)..."; Start-Sleep 3
    }
    if (!$BDrv) { Log-Msg "Lỗi tìm ổ Boot!"; $BtnStart.Enabled=$true; $Form.Cursor="Default"; return }
    Log-Msg "Boot: $BDrv | Data: $DDrv"

    # 4. EXTRACT
    Log-Msg "Đang giải nén vào $BDrv..."
    try { Expand-Archive -Path $ZipPath -DestinationPath "$BDrv\" -Force } catch {}

    # 5. CREATE FOLDERS
    if ($DDrv) {
        Log-Msg "Tạo thư mục ISO trên $DDrv..."
        @("iso\windows", "iso\linux", "iso\android", "iso\utilities", "iso\dos") | ForEach { New-Item -ItemType Directory -Path "$DDrv\$_" -Force | Out-Null }
        Set-Content "$DDrv\HUONG_DAN.txt" "CHÉP FILE ISO VÀO ĐÚNG THƯ MỤC TRONG 'iso' ĐỂ BOOT NGAY!"
    }

    Log-Msg "HOÀN TẤT!"; [System.Windows.Forms.MessageBox]::Show("Xong! Chép ISO vào $DDrv\iso nhé!")
    $BtnStart.Enabled=$true; $Form.Cursor="Default"
    if ($DDrv) { Invoke-Item "$DDrv\iso" }
})

$BtnRef.Add_Click({ Load-UsbList; Load-Kits })
$Form.Add_Load({ Load-UsbList; Load-Kits; Log-Msg "Sẵn sàng." })
[System.Windows.Forms.Application]::Run($Form)
