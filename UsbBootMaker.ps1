<#
    USB BOOT MAKER - PHAT TAN PC (FINAL FIX UNALLOCATED DATA)
    Fix: Tách quy trình DiskPart làm 2 bước để đảm bảo phân vùng Data được tạo thành công.
    UI: Thêm Scrollbar cho màn hình nhỏ.
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

# 2. CẤU HÌNH
$Global:JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/bootkits.json"
$Global:TempDir = "$env:TEMP\UsbBootMaker"
if (!(Test-Path $Global:TempDir)) { New-Item -ItemType Directory -Path $Global:TempDir -Force | Out-Null }

# 3. GIAO DIỆN (THEME)
$Theme = @{
    BgForm   = [System.Drawing.Color]::FromArgb(20, 20, 25)
    Card     = [System.Drawing.Color]::FromArgb(35, 35, 40)
    Text     = [System.Drawing.Color]::FromArgb(240, 240, 240)
    Cyan     = [System.Drawing.Color]::FromArgb(0, 255, 255)
    InputBg  = [System.Drawing.Color]::FromArgb(50, 50, 55)
    Warn     = [System.Drawing.Color]::FromArgb(255, 50, 80)
}

# --- HÀM HỖ TRỢ ---
function Add-GlowBorder ($Panel) {
    $Panel.Add_Paint({ param($s,$e) 
        $p = New-Object System.Drawing.Pen([System.Drawing.Color]::Cyan, 1)
        $r = $s.ClientRectangle; $r.Width-=1; $r.Height-=1
        $e.Graphics.DrawRectangle($p, $r)
        $p.Dispose() 
    })
}

function Log-Msg ($M) { 
    $TxtLog.Text += "[$(Get-Date -F HH:mm:ss)] $M`r`n"
    $TxtLog.SelectionStart = $TxtLog.Text.Length
    $TxtLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents() 
}

# --- KHỞI TẠO FORM ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "USB BOOT MAKER - PHÁT TẤN PC (FIX DATA)"
$Form.Size = New-Object System.Drawing.Size(900, 720)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.BgForm
$Form.ForeColor = $Theme.Text
$Form.AutoScroll = $true # <--- THÊM THANH TRƯỢT CHO FORM

$F_Title = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$F_Norm  = New-Object System.Drawing.Font("Segoe UI", 10)
$F_Code  = New-Object System.Drawing.Font("Consolas", 9)

# CONTAINER CHÍNH (Để chứa các thành phần cho gọn)
$MainContainer = New-Object System.Windows.Forms.TableLayoutPanel
$MainContainer.Dock = "Top" # Dock Top để thanh trượt hoạt động đúng
$MainContainer.AutoSize = $true
$MainContainer.ColumnCount = 1
$MainContainer.Padding = New-Object System.Windows.Forms.Padding(15)
$Form.Controls.Add($MainContainer)

# 1. HEADER
$PnlTitle = New-Object System.Windows.Forms.Panel; $PnlTitle.Height = 50; $PnlTitle.Dock="Top"; $PnlTitle.Margin="0,0,0,10"
$LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text = "⚡ USB BOOT CREATOR ULTIMATE"; $LblTitle.Font = $F_Title; $LblTitle.ForeColor = $Theme.Cyan; $LblTitle.AutoSize = $true
$PnlTitle.Controls.Add($LblTitle)
$MainContainer.Controls.Add($PnlTitle)

# HÀM TẠO CARD
function New-Card ($Title) { 
    $P = New-Object System.Windows.Forms.Panel
    $P.BackColor = $Theme.Card
    $P.Padding = New-Object System.Windows.Forms.Padding(10)
    $P.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 15)
    $P.Dock = "Top"
    $P.AutoSize = $true
    Add-GlowBorder $P
    $L = New-Object System.Windows.Forms.Label; $L.Text = $Title; $L.Font = $F_Norm; $L.ForeColor = "Gray"; $L.Dock = "Top"; $L.Height = 25
    $P.Controls.Add($L)
    return $P 
}

# 2. CHỌN USB
$CardUSB = New-Card "1. CHỌN THIẾT BỊ USB"
$LayUSB = New-Object System.Windows.Forms.TableLayoutPanel; $LayUSB.Dock="Top"; $LayUSB.Height=40; $LayUSB.ColumnCount=2
$LayUSB.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 80)))
$CbUSB = New-Object System.Windows.Forms.ComboBox; $CbUSB.Dock="Fill"; $CbUSB.Font=$F_Norm; $CbUSB.BackColor=$Theme.InputBg; $CbUSB.ForeColor="White"; $CbUSB.DropDownStyle="DropDownList"
$BtnRef = New-Object System.Windows.Forms.Button; $BtnRef.Text="REFRESH"; $BtnRef.Dock="Fill"; $BtnRef.BackColor=$Theme.InputBg; $BtnRef.ForeColor="White"; $BtnRef.FlatStyle="Flat"
$LayUSB.Controls.Add($CbUSB,0,0); $LayUSB.Controls.Add($BtnRef,1,0)
$CardUSB.Controls.Add($LayUSB)
$MainContainer.Controls.Add($CardUSB)

# 3. CHỌN KIT
$CardKit = New-Card "2. CHỌN BOOT KIT"
$CbKit = New-Object System.Windows.Forms.ComboBox; $CbKit.Dock="Top"; $CbKit.Font=$F_Norm; $CbKit.BackColor=$Theme.InputBg; $CbKit.ForeColor="White"; $CbKit.DropDownStyle="DropDownList"
$CardKit.Controls.Add($CbKit)
$MainContainer.Controls.Add($CardKit)

# 4. CẤU HÌNH
$CardSet = New-Card "3. CẤU HÌNH PHÂN VÙNG (QUAN TRỌNG)"
$GridSet = New-Object System.Windows.Forms.TableLayoutPanel; $GridSet.Dock="Top"; $GridSet.Height=140; $GridSet.ColumnCount=3; $GridSet.RowCount=2
$GridSet.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33)))
$GridSet.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33)))
$GridSet.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33)))

function Add-Input ($Label, $Ctrl, $R, $C) { 
    $P = New-Object System.Windows.Forms.Panel; $P.Dock="Fill"; $P.Padding=New-Object System.Windows.Forms.Padding(5)
    $L = New-Object System.Windows.Forms.Label; $L.Text=$Label; $L.Dock="Top"; $L.Height=20; $L.ForeColor="Silver"
    $Ctrl.Dock="Top"; $Ctrl.Font=$F_Norm; $Ctrl.BackColor=$Theme.InputBg; $Ctrl.ForeColor="White"
    $P.Controls.Add($Ctrl); $P.Controls.Add($L)
    $GridSet.Controls.Add($P, $C, $R) 
}

$CbStyle = New-Object System.Windows.Forms.ComboBox; $CbStyle.Items.AddRange(@("MBR", "GPT")); $CbStyle.SelectedIndex=0; $CbStyle.DropDownStyle="DropDownList"
Add-Input "Kiểu Partition:" $CbStyle 0 0

$NumSize = New-Object System.Windows.Forms.NumericUpDown; $NumSize.Minimum=100; $NumSize.Maximum=8192; $NumSize.Value=512
Add-Input "Size Boot (MB):" $NumSize 0 1

$TxtBoot = New-Object System.Windows.Forms.TextBox; $TxtBoot.Text="GLIM_BOOT"
Add-Input "Nhãn Boot:" $TxtBoot 0 2

$CbFS = New-Object System.Windows.Forms.ComboBox; $CbFS.Items.AddRange(@("NTFS", "exFAT", "FAT32")); $CbFS.SelectedIndex=0; $CbFS.DropDownStyle="DropDownList"
Add-Input "Định dạng Data:" $CbFS 1 0

$TxtData = New-Object System.Windows.Forms.TextBox; $TxtData.Text="GLIM_DATA"
Add-Input "Nhãn Data:" $TxtData 1 1

$CardSet.Controls.Add($GridSet)
$MainContainer.Controls.Add($CardSet)

# 5. LOG (LOG nằm dưới cùng container)
$PnlLog = New-Object System.Windows.Forms.Panel; $PnlLog.Height=200; $PnlLog.Dock="Top"; $PnlLog.Margin="0,10,0,0"
$TxtLog = New-Object System.Windows.Forms.TextBox; $TxtLog.Multiline=$true; $TxtLog.Dock="Fill"; $TxtLog.BackColor="Black"; $TxtLog.ForeColor="Lime"; $TxtLog.Font=$F_Code; $TxtLog.ReadOnly=$true; $TxtLog.ScrollBars="Vertical"
$PnlLog.Controls.Add($TxtLog)
$MainContainer.Controls.Add($PnlLog)

# 6. START BUTTON (Dock Bottom của Form chính, không nằm trong Container cuộn)
$PnlFooter = New-Object System.Windows.Forms.Panel; $PnlFooter.Dock="Bottom"; $PnlFooter.Height=60; $PnlFooter.Padding=New-Object System.Windows.Forms.Padding(100, 10, 100, 10)
$BtnStart = New-Object System.Windows.Forms.Button; $BtnStart.Text="🚀 BẮT ĐẦU TẠO USB"; $BtnStart.Font=$F_Title; $BtnStart.BackColor=$Theme.Cyan; $BtnStart.ForeColor="Black"; $BtnStart.FlatStyle="Flat"; $BtnStart.Dock="Fill"
$PnlFooter.Controls.Add($BtnStart)
$Form.Controls.Add($PnlFooter) # Add vào Form để luôn hiện

# --- LOGIC XỬ LÝ (FIXED PARTITION) ---

function Get-DL ($Label) {
    # Ưu tiên: WMI Volume (Chính xác nhất sau khi DiskPart)
    try { 
        $w = Get-WmiObject Win32_Volume -Filter "Label='$Label'" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($w.DriveLetter) { return $w.DriveLetter } 
    } catch {}

    # Dự phòng: LogicalDisk
    try { 
        $d = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.VolumeName -eq $Label } | Select-Object -First 1
        if ($d.DeviceID) { return $d.DeviceID }
    } catch {}
    
    return $null
}

function Run-DP ($Script) { 
    $f = "$Global:TempDir\dp.txt"
    [IO.File]::WriteAllText($f, $Script)
    $p = Start-Process "diskpart" "/s `"$f`"" -Wait -NoNewWindow -PassThru
    return $p.ExitCode
}

# LOGIC LOAD USB (DUAL MODE)
function Load-U {
    $CbUSB.Items.Clear(); $useWMI = $false
    # Cách 1: Get-Disk (Nhanh)
    if (Get-Command "Get-Disk" -ErrorAction SilentlyContinue) {
        try {
            $ds = @(Get-Disk -ErrorAction Stop | Where-Object { $_.BusType -eq "USB" -or $_.MediaType -eq "Removable" })
            if ($ds.Count -eq 0) { throw }
            foreach ($d in $ds) { 
                $size = [Math]::Round($d.Size / 1GB, 1)
                $CbUSB.Items.Add("Disk $($d.Number): $($d.FriendlyName) ($size GB)") 
            }
        } catch { $useWMI = $true }
    } else { $useWMI = $true }

    # Cách 2: WMI (Dành cho Win Lite)
    if ($useWMI) {
        try {
            $ds = @(Get-WmiObject Win32_DiskDrive | Where-Object { $_.InterfaceType -eq "USB" -or $_.MediaType -match "Removable" })
            foreach ($d in $ds) { 
                $size = [Math]::Round($d.Size / 1GB, 1)
                $CbUSB.Items.Add("Disk $($d.Index): $($d.Model) ($size GB)") 
            }
        } catch {}
    }
    if ($CbUSB.Items.Count -gt 0) { $CbUSB.SelectedIndex=0 } else { $CbUSB.Items.Add("Không tìm thấy USB"); $CbUSB.SelectedIndex=0 }
}

function Load-K {
    $CbKit.Items.Clear(); Log-Msg "Đang tải danh sách Boot Kit..."
    try { 
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $j = Invoke-RestMethod -Uri "$($Global:JsonUrl)?t=$(Get-Date -UFormat %s)" -Headers @{"Cache-Control"="no-cache"} -ErrorAction Stop
        if ($j) { foreach ($i in $j) { if($i.Name) { $CbKit.Items.Add($i.Name); $Global:KitData=$j } } }
        if ($CbKit.Items.Count -gt 0) { $CbKit.SelectedIndex=0; Log-Msg "Đã tải xong." }
    } catch { 
        $CbKit.Items.Add("Chế độ Demo (Offline)"); $CbKit.SelectedIndex=0; Log-Msg "Lỗi tải Config." 
    }
}

$BtnStart.Add_Click({
    if ($CbUSB.SelectedItem -match "Disk (\d+)") { $ID = $Matches[1] } else { return }
    $K = $Global:KitData | Where-Object { $_.Name -eq $CbKit.SelectedItem } | Select-Object -First 1
    if (!$K) { return }
    if ([System.Windows.Forms.MessageBox]::Show("XÓA SẠCH DỮ LIỆU TRÊN DISK $ID?`n`nToàn bộ dữ liệu sẽ mất vĩnh viễn!","CẢNH BÁO","YesNo","Warning") -ne "Yes") { return }

    $BtnStart.Enabled=$false; $Form.Cursor="WaitCursor"

    # 1. TẢI FILE ZIP
    $Zip = "$Global:TempDir\$($K.FileName)"
    if (!(Test-Path $Zip)) { 
        Log-Msg "Đang tải Boot Kit..."
        try { (New-Object Net.WebClient).DownloadFile($K.Url, $Zip) } 
        catch { Log-Msg "Lỗi tải file!"; $BtnStart.Enabled=$true; $Form.Cursor="Default"; return } 
    }

    # 2. DISKPART (FIX LỖI UNALLOCATED)
    $St = if ($CbStyle.SelectedIndex -eq 0) { "mbr" } else { "gpt" }
    $Sz = $NumSize.Value
    $BL = $TxtBoot.Text
    $DL = $TxtData.Text
    $FS = $CbFS.SelectedItem

    Log-Msg "Đang xử lý phân vùng... (Bước 1: Boot)"
    
    # Bước 1: Clean và tạo Boot trước
    $Cmd1 = "select disk $ID`nclean`nconvert $St`nrescan"
    $Cmd1 += "`ncreate partition primary size=$Sz`nformat fs=fat32 quick label=`"$BL`"`nactive`nassign"
    Run-DP $Cmd1
    
    Start-Sleep -Seconds 3 # Nghỉ để Windows nhận Boot Partition
    Log-Msg "Đang xử lý phân vùng... (Bước 2: Data)"

    # Bước 2: Tạo Data với phần còn lại (Fix lỗi Unallocated)
    $Cmd2 = "select disk $ID`nrescan`ncreate partition primary`nformat fs=$FS quick label=`"$DL`"`nassign`nexit"
    Run-DP $Cmd2
    
    Log-Msg "Đợi Windows nhận diện ổ đĩa (10s)..."
    Start-Sleep -Seconds 10

    # 3. TÌM Ổ ĐĨA
    for ($i=1; $i -le 5; $i++) { 
        $B = Get-DL $BL
        $D = Get-DL $DL
        if ($B -and $D) { break }
        Log-Msg "Đang dò tìm... (Lần $i)"; Start-Sleep -Seconds 3 
    }

    if (!$B) { Log-Msg "Lỗi: Không tìm thấy ổ Boot ($BL)!"; $BtnStart.Enabled=$true; $Form.Cursor="Default"; return }
    Log-Msg "Đã tìm thấy: Boot ($B) | Data ($D)"

    # 4. GIẢI NÉN
    Log-Msg "Đang giải nén Boot Kit vào $B..."
    try { Expand-Archive -Path $Zip -DestinationPath "$B\" -Force } catch { Log-Msg "Lỗi giải nén: $($_.Exception.Message)" }

    # 5. TẠO FOLDER ISO
    if ($D) {
        Log-Msg "Đang tạo thư mục ISO trên $D..."
        $Folders = @("iso\windows", "iso\linux", "iso\android", "iso\utilities", "iso\dos")
        foreach ($f in $Folders) { New-Item -ItemType Directory -Path "$D\$f" -Force | Out-Null }
        Set-Content "$D\HUONG_DAN.txt" "Chép file ISO vào các thư mục trong 'iso' để boot nhé!"
    } else {
        Log-Msg "Cảnh báo: Không tìm thấy ổ Data ($DL) để tạo thư mục ISO."
    }

    Log-Msg "HOÀN TẤT!"; [System.Windows.Forms.MessageBox]::Show("Thành công!"); $BtnStart.Enabled=$true; $Form.Cursor="Default"
    if ($D) { Invoke-Item "$D\iso" }
})

$BtnRef.Add_Click({ Load-U; Load-K })
$Form.Add_Load({ Load-U; Load-K; Log-Msg "Sẵn sàng." })
[System.Windows.Forms.Application]::Run($Form)
