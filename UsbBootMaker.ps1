<#
    USB BOOT MAKER - PHAT TAN PC (CYBER UI EDITION)
    Features: 
    - UI: Responsive Grid Layout (TableLayoutPanel), Neon Borders, Modern Cards
    - Core: Dual-Engine (Get-Disk/WMI), Auto ISO Folders, Custom Partitioning
#>

# 1. SETUP & ENCODING
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

# 2. CONFIG
$Global:JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/bootkits.json"
$Global:TempDir = "$env:TEMP\UsbBootMaker"
if (!(Test-Path $Global:TempDir)) { New-Item -ItemType Directory -Path $Global:TempDir -Force | Out-Null }

# 3. THEME (CYBER DARK)
$Theme = @{
    BgForm   = [System.Drawing.Color]::FromArgb(20, 20, 25)
    Card     = [System.Drawing.Color]::FromArgb(35, 35, 40)
    Text     = [System.Drawing.Color]::FromArgb(240, 240, 240)
    Muted    = [System.Drawing.Color]::FromArgb(150, 150, 150)
    Cyan     = [System.Drawing.Color]::FromArgb(0, 255, 255) # Neon Glow
    Red      = [System.Drawing.Color]::FromArgb(255, 50, 80)
    InputBg  = [System.Drawing.Color]::FromArgb(50, 50, 55)
}

# --- HELPER GUI ---
function Add-GlowBorder ($Panel) {
    $Panel.Add_Paint({
        param($s, $e)
        $Pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(0, 255, 255), 1) # Cyan Border
        $Rect = $s.ClientRectangle; $Rect.Width-=1; $Rect.Height-=1
        $e.Graphics.DrawRectangle($Pen, $Rect)
        $Pen.Dispose()
    })
}

# --- FORM INIT ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "USB BOOT MAKER - PHÁT TẤN PC (CYBER EDITION)"
$Form.Size = New-Object System.Drawing.Size(900, 700)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.BgForm
$Form.ForeColor = $Theme.Text
$Form.Padding = New-Object System.Windows.Forms.Padding(15)

$F_Title = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$F_Bold  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$F_Norm  = New-Object System.Drawing.Font("Segoe UI", 10)
$F_Code  = New-Object System.Drawing.Font("Consolas", 9)

# --- LAYOUT CHÍNH (VERTICAL STACK) ---
# Dùng TableLayoutPanel để chia dòng, đảm bảo không cái nào đè cái nào
$MainLayout = New-Object System.Windows.Forms.TableLayoutPanel
$MainLayout.Dock = "Fill"
$MainLayout.ColumnCount = 1
$MainLayout.RowCount = 5
# Tỷ lệ chiều cao các dòng: Header(Auto), USB(Auto), Kit(Auto), Settings(Auto), Log(Fill)
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize)))
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize)))
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize)))
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize)))
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) 
$Form.Controls.Add($MainLayout)

# --- 1. HEADER TITLE ---
$PnlTitle = New-Object System.Windows.Forms.Panel; $PnlTitle.Height = 50; $PnlTitle.Dock="Top"; $PnlTitle.Margin="0,0,0,10"
$LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text = "⚡ USB BOOT MAKER ULTIMATE"; $LblTitle.Font = $F_Title; $LblTitle.ForeColor = $Theme.Cyan; $LblTitle.AutoSize = $true; $LblTitle.Location="10,10"
$PnlTitle.Controls.Add($LblTitle)
$MainLayout.Controls.Add($PnlTitle, 0, 0)

# --- FUNCTION TẠO CARD (PANEL) ---
function New-CardPanel ($Title) {
    $P = New-Object System.Windows.Forms.Panel
    $P.BackColor = $Theme.Card
    $P.Padding = New-Object System.Windows.Forms.Padding(10)
    $P.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 15)
    $P.Dock = "Top"
    $P.AutoSize = $true # Quan trọng: Tự giãn theo nội dung bên trong
    Add-GlowBorder $P
    
    $L = New-Object System.Windows.Forms.Label; $L.Text = $Title; $L.Font = $F_Bold; $L.ForeColor = $Theme.Muted; $L.Dock = "Top"; $L.Height = 25
    $P.Controls.Add($L)
    return $P
}

# --- 2. CARD: CHỌN USB ---
$CardUSB = New-CardPanel "1. CHỌN THIẾT BỊ USB (SẼ FORMAT)"
$LayoutUSB = New-Object System.Windows.Forms.TableLayoutPanel; $LayoutUSB.Dock="Top"; $LayoutUSB.Height=40; $LayoutUSB.ColumnCount=2
$LayoutUSB.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 80)))
$LayoutUSB.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 20)))

$CbUSB = New-Object System.Windows.Forms.ComboBox; $CbUSB.Dock="Fill"; $CbUSB.Font=$F_Norm; $CbUSB.BackColor=$Theme.InputBg; $CbUSB.ForeColor="White"; $CbUSB.DropDownStyle="DropDownList"
$BtnRef = New-Object System.Windows.Forms.Button; $BtnRef.Text="🔄 LÀM MỚI"; $BtnRef.Dock="Fill"; $BtnRef.BackColor=$Theme.InputBg; $BtnRef.ForeColor="White"; $BtnRef.FlatStyle="Flat"

$LayoutUSB.Controls.Add($CbUSB, 0, 0); $LayoutUSB.Controls.Add($BtnRef, 1, 0)
$CardUSB.Controls.Add($LayoutUSB)
$MainLayout.Controls.Add($CardUSB, 0, 1)

# --- 3. CARD: CHỌN BOOT KIT ---
$CardKit = New-CardPanel "2. CHỌN PHIÊN BẢN BOOT (TỪ GITHUB)"
$CbKit = New-Object System.Windows.Forms.ComboBox; $CbKit.Dock="Top"; $CbKit.Font=$F_Norm; $CbKit.BackColor=$Theme.InputBg; $CbKit.ForeColor="White"; $CbKit.DropDownStyle="DropDownList"
$CardKit.Controls.Add($CbKit)
$MainLayout.Controls.Add($CardKit, 0, 2)

# --- 4. CARD: CẤU HÌNH (GRID LAYOUT - KHÔNG BAO GIỜ LỖI) ---
$CardSet = New-Object System.Windows.Forms.Panel; $CardSet.BackColor=$Theme.Card; $CardSet.Padding="10,10,10,10"; $CardSet.Dock="Top"; $CardSet.Height=160; Add-GlowBorder $CardSet
$LblSet = New-Object System.Windows.Forms.Label; $LblSet.Text="3. TÙY CHỈNH NÂNG CAO"; $LblSet.Font=$F_Bold; $LblSet.ForeColor=$Theme.Muted; $LblSet.Dock="Top"; $LblSet.Height=25
$CardSet.Controls.Add($LblSet)

# Grid 2 dòng 3 cột cho Setting
$GridSet = New-Object System.Windows.Forms.TableLayoutPanel; $GridSet.Dock="Fill"; $GridSet.ColumnCount=3; $GridSet.RowCount=2
$GridSet.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33)))
$GridSet.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33)))
$GridSet.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33)))

function Add-Input ($Label, $Control, $Row, $Col) {
    $P = New-Object System.Windows.Forms.Panel; $P.Dock="Fill"; $P.Padding="5,5,5,5"
    $L = New-Object System.Windows.Forms.Label; $L.Text=$Label; $L.Dock="Top"; $L.Height=20; $L.ForeColor="Silver"
    $Control.Dock="Top"; $Control.Font=$F_Norm; $Control.BackColor=$Theme.InputBg; $Control.ForeColor="White"
    $P.Controls.Add($Control); $P.Controls.Add($L)
    $GridSet.Controls.Add($P, $Col, $Row)
}

# Row 1
$CbStyle = New-Object System.Windows.Forms.ComboBox; $CbStyle.Items.AddRange(@("MBR (Legacy+UEFI)", "GPT (UEFI Only)")); $CbStyle.SelectedIndex=0; $CbStyle.DropDownStyle="DropDownList"
Add-Input "Kiểu Partition:" $CbStyle 0 0

$NumSize = New-Object System.Windows.Forms.NumericUpDown; $NumSize.Minimum=100; $NumSize.Maximum=8192; $NumSize.Value=512
Add-Input "Dung lượng Boot (MB):" $NumSize 0 1

$TxtBoot = New-Object System.Windows.Forms.TextBox; $TxtBoot.Text="GLIM_BOOT"
Add-Input "Nhãn Boot:" $TxtBoot 0 2

# Row 2
$CbFS = New-Object System.Windows.Forms.ComboBox; $CbFS.Items.AddRange(@("NTFS", "exFAT", "FAT32")); $CbFS.SelectedIndex=0; $CbFS.DropDownStyle="DropDownList"
Add-Input "Định dạng Data:" $CbFS 1 0

$TxtData = New-Object System.Windows.Forms.TextBox; $TxtData.Text="GLIM_DATA"
Add-Input "Nhãn Data:" $TxtData 1 1

# Empty Slot Row 2 Col 2 (Optional)

$CardSet.Controls.Add($GridSet)
$MainLayout.Controls.Add($CardSet, 0, 3)

# --- 5. LOG AREA & START BUTTON ---
$PnlLog = New-Object System.Windows.Forms.Panel; $PnlLog.Dock="Fill"; $PnlLog.Padding="0,15,0,0"
$TxtLog = New-Object System.Windows.Forms.TextBox; $TxtLog.Multiline=$true; $TxtLog.Dock="Fill"; $TxtLog.BackColor="Black"; $TxtLog.ForeColor="Lime"; $TxtLog.Font=$F_Code; $TxtLog.ReadOnly=$true; $TxtLog.ScrollBars="Vertical"
$PnlLog.Controls.Add($TxtLog)
$MainLayout.Controls.Add($PnlLog, 0, 4)

# Footer Button (Dock Bottom của Form chính)
$BtnStart = New-Object System.Windows.Forms.Button
$BtnStart.Text = "🚀 BẮT ĐẦU TẠO USB"
$BtnStart.Font = $F_Title
$BtnStart.BackColor = $Theme.Cyan
$BtnStart.ForeColor = "Black" # Chữ đen trên nền Cyan cho nổi
$BtnStart.FlatStyle = "Flat"
$BtnStart.Dock = "Bottom"
$BtnStart.Height = 60
$BtnStart.Cursor = "Hand"
$Form.Controls.Add($BtnStart)

# --- LOGIC CODE (GIỮ NGUYÊN CORE CŨ) ---

function Log-Msg ($Msg) { $TxtLog.Text += "[$(Get-Date -F 'HH:mm:ss')] $Msg`r`n"; $TxtLog.SelectionStart = $TxtLog.Text.Length; $TxtLog.ScrollToCaret(); [System.Windows.Forms.Application]::DoEvents() }

function Get-DriveLetterByLabel ($Label) {
    if (Get-Command "Get-Volume" -ErrorAction SilentlyContinue) {
        try { Get-Disk | Update-Disk -ErrorAction SilentlyContinue; $Vol = Get-Volume | Where { $_.FileSystemLabel -eq $Label } | Select -First 1; if ($Vol.DriveLetter) { return "$($Vol.DriveLetter):" } } catch {}
    }
    try { $W = Get-WmiObject Win32_Volume -Filter "Label = '$Label'" -EA 0 | Select -First 1; if($W.DriveLetter){return $W.DriveLetter} } catch {}
    try { $D = Get-WmiObject Win32_LogicalDisk; foreach($i in $D){if($i.VolumeName -eq $Label){return $i.DeviceID}} } catch {}
    return $null
}

function Run-DP ($Script) { $F="$Global:TempDir\dp.txt"; [IO.File]::WriteAllText($F, $Script); Start-Process "diskpart" "/s `"$F`"" -Wait -NoNewWindow }

function Load-UsbList {
    $CbUSB.Items.Clear(); $UseWMI=$false
    if (Get-Command "Get-Disk" -EA 0) {
        try {
            $Ds = @(Get-Disk -EA Stop | Where { $_.BusType -eq "USB" -or $_.MediaType -eq "Removable" })
            if($Ds.Count -eq 0){throw}; foreach($D in $Ds){ $CbUSB.Items.Add("Disk $($D.Number): $($D.FriendlyName) ($([Math]::Round($D.Size/1GB,1)) GB)") }
        } catch { $UseWMI=$true }
    } else { $UseWMI=$true }
    if($UseWMI){ try{$Ds=@(Get-WmiObject Win32_DiskDrive | Where{$_.InterfaceType -eq "USB"}); foreach($D in $Ds){ $CbUSB.Items.Add("Disk $($D.Index): $($D.Model)") }}catch{} }
    if($CbUSB.Items.Count -gt 0){$CbUSB.SelectedIndex=0}else{$CbUSB.Items.Add("No USB Found"); $CbUSB.SelectedIndex=0}
}

function Load-Kits {
    $CbKit.Items.Clear(); Log-Msg "Đang tải danh sách Boot Kit..."
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $Json = Invoke-RestMethod -Uri "$($Global:JsonUrl)?t=$(Get-Date -UFormat %s)" -Headers @{"Cache-Control"="no-cache"} -ErrorAction Stop
        if ($Json) { foreach ($I in $Json) { if($I.Name){$CbKit.Items.Add($I.Name); $Global:KitData=$Json} } }
        if ($CbKit.Items.Count -gt 0) { $CbKit.SelectedIndex=0; Log-Msg "Đã tải xong." }
    } catch { $CbKit.Items.Add("Chế độ Demo (Mất mạng)"); $CbKit.SelectedIndex=0; Log-Msg "Lỗi tải JSON." }
}

$BtnStart.Add_Click({
    if ($CbUSB.SelectedItem -match "Disk (\d+)") { $DiskID = $Matches[1] } else { return }
    $Kit = $Global:KitData | Where {$_.Name -eq $CbKit.SelectedItem} | Select -First 1
    if (!$Kit) { return }
    if ([System.Windows.Forms.MessageBox]::Show("XÓA SẠCH DỮ LIỆU DISK $DiskID?","CẢNH BÁO","YesNo","Warning") -ne "Yes") { return }

    $BtnStart.Enabled=$false; $Form.Cursor="WaitCursor"
    
    # 1. Download
    $ZipPath = "$Global:TempDir\$($Kit.FileName)"
    if (!(Test-Path $ZipPath)) {
        Log-Msg "Đang tải: $($Kit.FileName)..."
        try { (New-Object Net.WebClient).DownloadFile($Kit.Url, $ZipPath) } catch { Log-Msg "Lỗi tải file!"; $BtnStart.Enabled=$true; $Form.Cursor="Default"; return }
    }

    # 2. DiskPart
    $Style = if($CbStyle.SelectedIndex -eq 0){"mbr"}else{"gpt"}; $Size=$NumSize.Value; $BL=$TxtBoot.Text; $DL=$TxtData.Text; $FS=$CbFS.SelectedItem
    Log-Msg "Đang Format: $Style | Boot: $Size MB..."
    $Cmd="sel disk $DiskID`nclean`nconvert $Style`ncreate part pri size=$Size`nformat fs=fat32 quick label=`"$BL`"`nactive`nassign`ncreate part pri`nformat fs=$FS quick label=`"$DL`"`nassign`nexit"
    Run-DP $Cmd
    Log-Msg "Đang đợi Windows (10s)..."; Start-Sleep 10

    # 3. Detect
    for($i=1;$i -le 3;$i++){ $BDrv=Get-DriveLetterByLabel $BL; $DDrv=Get-DriveLetterByLabel $DL; if($BDrv){break}; Start-Sleep 3 }
    if(!$BDrv){ Log-Msg "Lỗi tìm ổ Boot!"; $BtnStart.Enabled=$true; $Form.Cursor="Default"; return }

    # 4. Extract
    Log-Msg "Đang giải nén vào $BDrv..."
    try { Expand-Archive -Path $ZipPath -DestinationPath "$BDrv\" -Force } catch {}

    # 5. Folders
    if($DDrv){
        Log-Msg "Tạo thư mục ISO trên $DDrv..."
        @("iso\windows","iso\linux","iso\android","iso\utilities","iso\dos") | ForEach { New-Item -ItemType Directory -Path "$DDrv\$_" -Force | Out-Null }
    }

    Log-Msg "HOÀN TẤT!"; [System.Windows.Forms.MessageBox]::Show("Xong!"); $BtnStart.Enabled=$true; $Form.Cursor="Default"
    if($DDrv){ Invoke-Item "$DDrv\iso" }
})

$BtnRef.Add_Click({ Load-UsbList; Load-Kits })
$Form.Add_Load({ Load-UsbList; Load-Kits; Log-Msg "Sẵn sàng." })
[System.Windows.Forms.Application]::Run($Form)
