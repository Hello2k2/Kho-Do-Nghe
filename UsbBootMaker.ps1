<#
    USB BOOT MAKER - PHAT TAN PC (ULTIMATE VN EDITION)
    Tính năng:
    - Tùy chỉnh Full: Label, Size, Filesystem, MBR/GPT
    - Tự tạo thư mục ISO chuẩn GLIM
    - Engine kép: Get-Disk + WMI (Fix Win Lite)
    - Tự tải Config từ GitHub
    - Giao diện Dark Titanium Responsive
#>

# Ép kiểu UTF-8 cho Console để hiện tiếng Việt
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

# --- CẤU HÌNH ---
$Global:JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/bootkits.json"
$Global:TempDir = "$env:TEMP\UsbBootMaker"
if (!(Test-Path $Global:TempDir)) { New-Item -ItemType Directory -Path $Global:TempDir -Force | Out-Null }

# --- THEME CONFIG ---
$Theme = @{
    BgForm   = [System.Drawing.Color]::FromArgb(18, 18, 22)
    BgPanel  = [System.Drawing.Color]::FromArgb(32, 32, 38)
    TextMain = [System.Drawing.Color]::FromArgb(245, 245, 245)
    Accent   = [System.Drawing.Color]::FromArgb(0, 255, 255)
    Warn     = [System.Drawing.Color]::FromArgb(255, 50, 80)
    Border   = [System.Drawing.Color]::FromArgb(80, 80, 100)
}

# --- HELPER FUNCTIONS ---
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
    # 1. Modern
    if (Get-Command "Get-Volume" -ErrorAction SilentlyContinue) {
        try {
            Get-Disk | Update-Disk -ErrorAction SilentlyContinue
            $Vol = Get-Volume | Where-Object { $_.FileSystemLabel -eq $Label } | Select-Object -First 1
            if ($Vol -and $Vol.DriveLetter) { return "$($Vol.DriveLetter):" }
        } catch {}
    }
    # 2. Legacy WMI
    try {
        $WmiVol = Get-WmiObject -Class Win32_Volume -Filter "Label = '$Label'" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($WmiVol -and $WmiVol.DriveLetter) { return $WmiVol.DriveLetter }
    } catch {}
    return $null
}

# --- GUI INIT ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "USB BOOT MAKER ULTIMATE - PHÁT TẤN PC"
$Form.Size = New-Object System.Drawing.Size(900, 750) 
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.BgForm; $Form.ForeColor = $Theme.TextMain; $Form.Padding = 20

$F_Head = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$F_Norm = New-Object System.Drawing.Font("Segoe UI", 10)
$F_Code = New-Object System.Drawing.Font("Consolas", 9)

# 1. BOTTOM
$PnlBottom = New-Object System.Windows.Forms.Panel; $PnlBottom.Height=70; $PnlBottom.Dock="Bottom"; $PnlBottom.Padding="100,15,100,15"
$BtnStart = New-Object System.Windows.Forms.Button; $BtnStart.Text="🚀 KHỞI TẠO & TỰ ĐỘNG TẠO THƯ MỤC"; $BtnStart.Dock="Fill"; $BtnStart.Font=$F_Head; $BtnStart.BackColor=$Theme.Warn; $BtnStart.ForeColor="White"; $BtnStart.FlatStyle="Flat"
$PnlBottom.Controls.Add($BtnStart); $Form.Controls.Add($PnlBottom)

# 2. HEADER
$PnlHead = New-Object System.Windows.Forms.Panel; $PnlHead.Height=60; $PnlHead.Dock="Top"
$LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text="⚡ CÔNG CỤ TẠO USB BOOT ĐA NĂNG"; $LblTitle.Dock="Top"; $LblTitle.Font="Segoe UI, 16, Bold"; $LblTitle.ForeColor=$Theme.Accent; $LblTitle.TextAlign="MiddleCenter"
$PnlHead.Controls.Add($LblTitle); $Form.Controls.Add($PnlHead)

# 3. SETTINGS GROUP
$GbSet = New-Object System.Windows.Forms.GroupBox; $GbSet.Text="TÙY CHỈNH CẤU HÌNH (NÂNG CAO)"; $GbSet.Height=140; $GbSet.Dock="Top"; $GbSet.ForeColor=[System.Drawing.Color]::Gold; $GbSet.Padding="15,25,15,10"
$Form.Controls.Add($GbSet)

$TblSet = New-Object System.Windows.Forms.TableLayoutPanel; $TblSet.Dock="Fill"; $TblSet.ColumnCount=4; $TblSet.RowCount=2
$GbSet.Controls.Add($TblSet)

function Add-Set ($Row, $Col, $Label, $Control) {
    $L = New-Object System.Windows.Forms.Label; $L.Text=$Label; $L.AutoSize=$true; $L.Font=$F_Norm; $L.ForeColor="White"; $L.Anchor="Left"
    $Control.Font=$F_Norm; $Control.Width=160; $Control.BackColor=$Theme.BgPanel; $Control.ForeColor="White"
    $P=New-Object System.Windows.Forms.FlowLayoutPanel; $P.AutoSize=$true; $P.FlowDirection="TopDown"; $P.Controls.Add($L); $P.Controls.Add($Control)
    $TblSet.Controls.Add($P, $Col, $Row)
    return $Control
}

$CbPartStyle = New-Object System.Windows.Forms.ComboBox; $CbPartStyle.Items.AddRange(@("MBR (Tương thích Legacy/UEFI)", "GPT (Chỉ UEFI)")); $CbPartStyle.SelectedIndex=0; $CbPartStyle.DropDownStyle="DropDownList"
Add-Set 0 0 "Kiểu Phân Vùng:" $CbPartStyle | Out-Null

$NumBootSize = New-Object System.Windows.Forms.NumericUpDown; $NumBootSize.Minimum=100; $NumBootSize.Maximum=4096; $NumBootSize.Value=512
Add-Set 0 1 "Dung Lượng Boot (MB):" $NumBootSize | Out-Null

$TxtBootLbl = New-Object System.Windows.Forms.TextBox; $TxtBootLbl.Text="GLIM_BOOT"
Add-Set 0 2 "Tên Ổ Boot:" $TxtBootLbl | Out-Null

$CbFS = New-Object System.Windows.Forms.ComboBox; $CbFS.Items.AddRange(@("NTFS", "exFAT", "FAT32")); $CbFS.SelectedIndex=0; $CbFS.DropDownStyle="DropDownList"
Add-Set 1 0 "Định Dạng Data:" $CbFS | Out-Null

$TxtDataLbl = New-Object System.Windows.Forms.TextBox; $TxtDataLbl.Text="GLIM_DATA"
Add-Set 1 1 "Tên Ổ Data:" $TxtDataLbl | Out-Null

$Spacer1 = New-Object System.Windows.Forms.Panel; $Spacer1.Height=10; $Spacer1.Dock="Top"; $Form.Controls.Add($Spacer1)

# 4. USB SELECT
$GbUSB = New-Object System.Windows.Forms.GroupBox; $GbUSB.Text="CHỌN THIẾT BỊ USB"; $GbUSB.Height=70; $GbUSB.Dock="Top"; $GbUSB.Padding="10,20,10,10"; $GbUSB.ForeColor=$Theme.Warn
$BtnRef = New-Object System.Windows.Forms.Button; $BtnRef.Text="LÀM MỚI"; $BtnRef.Dock="Right"; $BtnRef.Width=100; $BtnRef.BackColor=$Theme.BgPanel; $BtnRef.ForeColor="White"
$CbUSB = New-Object System.Windows.Forms.ComboBox; $CbUSB.Dock="Fill"; $CbUSB.Font=$F_Norm; $CbUSB.BackColor=$Theme.BgPanel; $CbUSB.ForeColor="White"; $CbUSB.DropDownStyle="DropDownList"
$GbUSB.Controls.Add($CbUSB); $GbUSB.Controls.Add($BtnRef); $Form.Controls.Add($GbUSB)

$Spacer2 = New-Object System.Windows.Forms.Panel; $Spacer2.Height=10; $Spacer2.Dock="Top"; $Form.Controls.Add($Spacer2)

# 5. KIT SELECT
$GbKit = New-Object System.Windows.Forms.GroupBox; $GbKit.Text="CHỌN PHIÊN BẢN BOOT (TẢI TỪ GITHUB)"; $GbKit.Height=70; $GbKit.Dock="Top"; $GbKit.Padding="10,20,10,10"; $GbKit.ForeColor=$Theme.Accent
$CbKit = New-Object System.Windows.Forms.ComboBox; $CbKit.Dock="Fill"; $CbKit.Font=$F_Norm; $CbKit.BackColor=$Theme.BgPanel; $CbKit.ForeColor="White"; $CbKit.DropDownStyle="DropDownList"
$GbKit.Controls.Add($CbKit); $Form.Controls.Add($GbKit)

$Spacer3 = New-Object System.Windows.Forms.Panel; $Spacer3.Height=10; $Spacer3.Dock="Top"; $Form.Controls.Add($Spacer3)

# 6. LOG
$TxtLog = New-Object System.Windows.Forms.TextBox; $TxtLog.Multiline=$true; $TxtLog.ScrollBars="Vertical"; $TxtLog.Dock="Fill"; $TxtLog.BackColor="Black"; $TxtLog.ForeColor="Lime"; $TxtLog.Font=$F_Code; $TxtLog.ReadOnly=$true; $Form.Controls.Add($TxtLog)

$PnlBottom.BringToFront(); $PnlHead.BringToFront(); $GbSet.BringToFront(); $Spacer1.BringToFront(); $GbUSB.BringToFront(); $Spacer2.BringToFront(); $GbKit.BringToFront(); $Spacer3.BringToFront(); $TxtLog.BringToFront()

# --- LOGIC ---

function Load-UsbList {
    $CbUSB.Items.Clear()
    $UseWMI = $false
    if (Get-Command "Get-Disk" -ErrorAction SilentlyContinue) {
        try {
            $Disks = @(Get-Disk -ErrorAction Stop | Where-Object { $_.BusType -eq "USB" -or $_.MediaType -eq "Removable" })
            if ($Disks.Count -eq 0) { throw }
            foreach ($D in $Disks) { $CbUSB.Items.Add("Disk $($D.Number): $($D.FriendlyName) ($([Math]::Round($D.Size/1GB,1)) GB)") }
        } catch { $UseWMI=$true }
    } else { $UseWMI=$true }
    if ($UseWMI) {
        try {
            $Disks = @(Get-WmiObject Win32_DiskDrive | Where { $_.InterfaceType -eq "USB" -or $_.MediaType -match "Removable" })
            foreach ($D in $Disks) { $CbUSB.Items.Add("Disk $($D.Index): $($D.Model) ($([Math]::Round($D.Size/1GB,1)) GB)") }
        } catch {}
    }
    if ($CbUSB.Items.Count -gt 0) { $CbUSB.SelectedIndex=0 } else { $CbUSB.Items.Add("Không tìm thấy USB"); $CbUSB.SelectedIndex=0 }
}

function Load-Kits {
    $CbKit.Items.Clear(); Log-Msg "Đang tải danh sách..."
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $Json = Invoke-RestMethod -Uri "$($Global:JsonUrl)?t=$(Get-Date -UFormat %s)" -Headers @{"Cache-Control"="no-cache"} -ErrorAction Stop
        if ($Json) { foreach ($I in $Json) { if($I.Name){$CbKit.Items.Add($I.Name); $Global:KitData=$Json} } }
        if ($CbKit.Items.Count -gt 0) { $CbKit.SelectedIndex=0 }
    } catch { $CbKit.Items.Add("Chế độ Demo (Mất mạng)"); $CbKit.SelectedIndex=0; Log-Msg "Lỗi kết nối mạng." }
}

function Download-File ($Url, $Dest) {
    Log-Msg "Đang tải xuống..."; try { (New-Object Net.WebClient).DownloadFile($Url, $Dest); return $true } catch { Log-Msg "Lỗi tải file!"; return $false }
}

$BtnStart.Add_Click({
    if ($CbUSB.SelectedItem -match "Disk (\d+)") { $DiskID = $Matches[1] } else { return }
    $KitObj = $Global:KitData | Where {$_.Name -eq $CbKit.SelectedItem} | Select -First 1
    if (!$KitObj) { return }
    if ([System.Windows.Forms.MessageBox]::Show("CẢNH BÁO: MỌI DỮ LIỆU TRÊN DISK $DiskID SẼ BỊ XÓA SẠCH!`n`nBạn có chắc chắn muốn tiếp tục?","CẢNH BÁO","YesNo","Warning") -ne "Yes") { return }

    $BtnStart.Enabled=$false; $Form.Cursor="WaitCursor"

    # 1. Prepare Zip
    $ZipPath = "$Global:TempDir\$($KitObj.FileName)"
    if (!(Test-Path $ZipPath)) { if (!(Download-File $KitObj.Url $ZipPath)) { $BtnStart.Enabled=$true; $Form.Cursor="Default"; return } }

    # 2. DiskPart Logic
    $Style = if ($CbPartStyle.SelectedIndex -eq 0) { "mbr" } else { "gpt" }
    $Size = $NumBootSize.Value
    $BootL = $TxtBootLbl.Text
    $DataL = $TxtDataLbl.Text
    $FS = $CbFS.SelectedItem

    Log-Msg "Cấu hình: $Style | Boot: $Size MB | Data: $FS"
    
    $Cmd = "select disk $DiskID`nclean`nconvert $Style"
    $Cmd += "`ncreate partition primary size=$Size`nformat fs=fat32 quick label=`"$BootL`"`nactive`nassign"
    $Cmd += "`ncreate partition primary`nformat fs=$FS quick label=`"$DataL`"`nassign`nexit"
    
    Run-DiskPartScript $Cmd
    Log-Msg "Đang đợi Windows nhận diện ổ đĩa (10s)..."; Start-Sleep -Seconds 10

    # 3. Detect Letters
    for ($i=1; $i -le 3; $i++) {
        $BootDrv = Get-DriveLetterByLabel $BootL
        $DataDrv = Get-DriveLetterByLabel $DataL
        if ($BootDrv) { break }
        Log-Msg "Đang dò tìm lại (Lần $i)..."; Start-Sleep -Seconds 3
    }
    if (!$BootDrv) { Log-Msg "Lỗi: Không tìm thấy ổ Boot! Hãy rút USB ra cắm lại."; $BtnStart.Enabled=$true; $Form.Cursor="Default"; return }

    # 4. Extract Kit
    Log-Msg "Đang giải nén Boot Kit vào $BootDrv..."
    try { Expand-Archive -Path $ZipPath -DestinationPath "$BootDrv\" -Force } catch {}

    # 5. AUTO CREATE ISO FOLDERS
    if ($DataDrv) {
        Log-Msg "Đang tạo cấu trúc thư mục ISO trên $DataDrv..."
        $Folders = @("iso\windows", "iso\linux", "iso\android", "iso\utilities", "iso\antivirus", "iso\dos")
        foreach ($F in $Folders) {
            $P = "$DataDrv\$F"
            if (!(Test-Path $P)) { New-Item -ItemType Directory -Path $P -Force | Out-Null }
        }
        Set-Content "$DataDrv\HUONG_DAN_SUDUNG.txt" "CHÉP FILE ISO VÀO CÁC THƯ MỤC TƯƠNG ỨNG TRONG 'iso' ĐỂ BOOT NGAY!`nVí dụ: Windows 10.iso -> iso\windows\"
    }

    Log-Msg "HOÀN TẤT!"; [System.Windows.Forms.MessageBox]::Show("Tạo USB Boot Thành Công!`nHãy chép file ISO vào ổ $DataDrv\iso nhé!")
    $BtnStart.Enabled=$true; $Form.Cursor="Default"
    if ($DataDrv) { Invoke-Item "$DataDrv\iso" }
})

$BtnRef.Add_Click({ Load-UsbList; Load-Kits })
$Form.Add_Load({ Load-UsbList; Load-Kits; Log-Msg "Sẵn sàng." })
[System.Windows.Forms.Application]::Run($Form)
