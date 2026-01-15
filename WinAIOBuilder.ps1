<#
    WIN AIO BUILDER - PHAT TAN PC
    Version: 7.5.6 (FINAL STABLE)
    - Fix: Lỗi cú pháp do copy paste thừa dòng (orm.Cursor).
    - Fix: Logic tìm kiếm Windows 11 thông minh.
    - Fix: Tải file đa luồng 512KB Buffer.
#>

# --- 1. FORCE ADMIN (QUYỀN QUẢN TRỊ CAO NHẤT) ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- GLOBAL ERROR HANDLING ---
try {

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop" # Đổi thành Stop để bắt lỗi chính xác hơn trong Try/Catch

# --- GLOBAL VARIABLES ---
$Global:IsoCache = @{} 
$Global:TempWimDir = "$env:TEMP\PhatTan_Wims"
$Global:BootKitCacheDir = "$env:TEMP\PhatTan_BootKits"

# [CONFIG] Link JSON Online
$Global:JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/bootkits.json" 
# Link dự phòng
$Global:DefaultBootKits = @(
    @{Name="Boot Kit Windows 10 (Mặc Định)"; Url="https://example.com/w10.zip"; FileName="w10.zip"}
)

if (!(Test-Path $Global:TempWimDir)) { New-Item -ItemType Directory -Path $Global:TempWimDir -Force | Out-Null }
if (!(Test-Path $Global:BootKitCacheDir)) { New-Item -ItemType Directory -Path $Global:BootKitCacheDir -Force | Out-Null }

# --- THEME ENGINE (RED & DARK) ---
$Theme = @{
    Back      = [System.Drawing.Color]::FromArgb(20, 20, 20)
    Card      = [System.Drawing.Color]::FromArgb(35, 35, 35)
    Text      = [System.Drawing.Color]::FromArgb(240, 240, 240)
    BtnBack   = [System.Drawing.Color]::FromArgb(50, 50, 50)
    Accent    = [System.Drawing.Color]::FromArgb(255, 50, 50) # ĐỎ (RED)
    Success   = [System.Drawing.Color]::SeaGreen
    Warning   = [System.Drawing.Color]::Orange
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WIN AIO BUILDER v7.5.6 - PHÁT TÂN PC"
$Form.Size = New-Object System.Drawing.Size(960, 860)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back; $Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "PHAT TAN PC - SYSTEM BUILDER"; $LblT.Font = New-Object System.Drawing.Font("Impact", 24); $LblT.ForeColor = $Theme.Accent; $LblT.AutoSize = $true; $LblT.Location = "20,10"; $Form.Controls.Add($LblT)

# --- TAB CONTROL ---
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = "20,70"; $TabControl.Size = "910,730"
$TabControl.Appearance = "FlatButtons"; $TabControl.ItemSize = New-Object System.Drawing.Size(150, 35)

$TabAIO = New-Object System.Windows.Forms.TabPage; $TabAIO.Text = "  1. GHÉP ISO AIO  "; $TabAIO.BackColor = $Theme.Back
$TabControl.Controls.Add($TabAIO)

$TabW2I = New-Object System.Windows.Forms.TabPage; $TabW2I.Text = "  2. WIM TO ISO  "; $TabW2I.BackColor = $Theme.Back
$TabControl.Controls.Add($TabW2I)

$Form.Controls.Add($TabControl)

# ==================== GUI TAB 1: AIO BUILDER ====================
$GbIso = New-Object System.Windows.Forms.GroupBox; $GbIso.Text = "Danh Sách File ISO Nguồn"; $GbIso.Location = "15,15"; $GbIso.Size = "870,250"; $GbIso.ForeColor = "Yellow"; $TabAIO.Controls.Add($GbIso)
$TxtIsoList = New-Object System.Windows.Forms.TextBox; $TxtIsoList.Location = "15,25"; $TxtIsoList.Size = "550,25"; $TxtIsoList.ReadOnly = $true; $GbIso.Controls.Add($TxtIsoList)
$BtnAdd = New-Object System.Windows.Forms.Button; $BtnAdd.Text = "THÊM ISO"; $BtnAdd.Location = "580,23"; $BtnAdd.Size = "100,27"; $BtnAdd.BackColor = "DimGray"; $BtnAdd.ForeColor = "White"; $GbIso.Controls.Add($BtnAdd)
$BtnEject = New-Object System.Windows.Forms.Button; $BtnEject.Text = "LÀM MỚI"; $BtnEject.Location = "690,23"; $BtnEject.Size = "100,27"; $BtnEject.BackColor = "DarkRed"; $BtnEject.ForeColor = "White"; $GbIso.Controls.Add($BtnEject)

$Grid = New-Object System.Windows.Forms.DataGridView; $Grid.Location = "15,60"; $Grid.Size = "840,175"; $Grid.BackgroundColor = "Black"; $Grid.ForeColor = "Black"; $Grid.AllowUserToAddRows = $false; $Grid.RowHeadersVisible = $false; $Grid.SelectionMode = "FullRowSelect"; $Grid.AutoSizeColumnsMode = "Fill"
$ColChk = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn; $ColChk.Name = "Select"; $ColChk.HeaderText = "[Chọn]"; $ColChk.Width = 50; $Grid.Columns.Add($ColChk) | Out-Null
$Grid.Columns.Add("ISO", "Tên File"); $Grid.Columns.Add("Index", "Idx"); $Grid.Columns.Add("Name", "Phiên Bản Windows"); $Grid.Columns.Add("Size", "Dung Lượng"); $Grid.Columns.Add("Arch", "Bit"); $Grid.Columns.Add("WimPath", "WimPath"); $Grid.Columns.Add("BuildVer", "Kernel"); 
$Grid.Columns[7].Visible = $false; $Grid.Columns[6].Visible = $false; $Grid.Columns[5].Visible = $false;
$Grid.Columns[1].Width = 60; $Grid.Columns[3].Width = 80; $Grid.Columns[4].Width = 60; $GbIso.Controls.Add($Grid)

$GbBuild = New-Object System.Windows.Forms.GroupBox; $GbBuild.Text = "Cấu Hình & Build AIO"; $GbBuild.Location = "15,280"; $GbBuild.Size = "870,110"; $GbBuild.ForeColor = "Lime"; $TabAIO.Controls.Add($GbBuild)
$LblOut = New-Object System.Windows.Forms.Label; $LblOut.Text = "Nơi Lưu:"; $LblOut.Location = "15,30"; $LblOut.AutoSize = $true; $GbBuild.Controls.Add($LblOut)
$TxtOut = New-Object System.Windows.Forms.TextBox; $TxtOut.Location = "80,27"; $TxtOut.Size = "350,25"; $TxtOut.Text = "D:\AIO_Output"; $GbBuild.Controls.Add($TxtOut)
$BtnBrowseOut = New-Object System.Windows.Forms.Button; $BtnBrowseOut.Text = "..."; $BtnBrowseOut.Location = "440,25"; $BtnBrowseOut.Size = "40,27"; $GbBuild.Controls.Add($BtnBrowseOut)
$BtnBuild = New-Object System.Windows.Forms.Button; $BtnBuild.Text = "BẮT ĐẦU BUILD AIO"; $BtnBuild.Location = "510,20"; $BtnBuild.Size = "340,70"; $BtnBuild.BackColor = $Theme.Accent; $BtnBuild.ForeColor = "White"; $BtnBuild.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold); $GbBuild.Controls.Add($BtnBuild)

$MenuBuild = New-Object System.Windows.Forms.ContextMenu
$Item1 = $MenuBuild.MenuItems.Add("1. Build ra thư mục cài đặt (install.wim)")
$Item2 = $MenuBuild.MenuItems.Add("2. Tạo cấu trúc ISO Boot đầy đủ (Khuyên dùng)")

$GbIsoTool = New-Object System.Windows.Forms.GroupBox; $GbIsoTool.Text = "Công Cụ ISO & HDD Boot"; $GbIsoTool.Location = "15,400"; $GbIsoTool.Size = "870,100"; $GbIsoTool.ForeColor = "Orange"; $TabAIO.Controls.Add($GbIsoTool)
$MenuIsoHidden = New-Object System.Windows.Forms.ContextMenu
$MItem_Default = $MenuIsoHidden.MenuItems.Add("1. Tạo ISO từ thư mục hiện tại (Mặc định)")
$MItem_Custom  = $MenuIsoHidden.MenuItems.Add("2. Chọn thư mục nguồn khác để đóng gói ISO...")
$BtnMakeIso = New-Object System.Windows.Forms.Button; $BtnMakeIso.Text = "ĐÓNG GÓI ISO"; $BtnMakeIso.Location = "20,30"; $BtnMakeIso.Size = "400,50"; $BtnMakeIso.BackColor = "DarkOrange"; $BtnMakeIso.ForeColor = "Black"; $GbIsoTool.Controls.Add($BtnMakeIso)
$BtnHddBoot = New-Object System.Windows.Forms.Button; $BtnHddBoot.Text = "TẠO HDD BOOT MENU"; $BtnHddBoot.Location = "440,30"; $BtnHddBoot.Size = "400,50"; $BtnHddBoot.BackColor = "Firebrick"; $BtnHddBoot.ForeColor = "White"; $GbIsoTool.Controls.Add($BtnHddBoot)

$TxtLog = New-Object System.Windows.Forms.TextBox; $TxtLog.Multiline = $true; $TxtLog.Location = "15,510"; $TxtLog.Size = "870,170"; $TxtLog.BackColor = "Black"; $TxtLog.ForeColor = "Lime"; $TxtLog.ReadOnly = $true; $TxtLog.ScrollBars = "Vertical"; $TabAIO.Controls.Add($TxtLog)


# ==================== GUI TAB 2: WIM TO ISO (FIXED) ====================
$GbWimIn = New-Object System.Windows.Forms.GroupBox; $GbWimIn.Text = "1. Chọn File WIM/ESD Nguồn (Cần đóng gói)"; $GbWimIn.Location = "20,20"; $GbWimIn.Size = "860,80"; $GbWimIn.ForeColor = "Cyan"; $TabW2I.Controls.Add($GbWimIn)
$TxtWimIn = New-Object System.Windows.Forms.TextBox; $TxtWimIn.Location = "20,30"; $TxtWimIn.Size = "660,25"; $GbWimIn.Controls.Add($TxtWimIn)
$BtnBrWim = New-Object System.Windows.Forms.Button; $BtnBrWim.Text = "CHỌN FILE..."; $BtnBrWim.Location = "700,28"; $BtnBrWim.Size = "140,27"; $BtnBrWim.BackColor = "DimGray"; $BtnBrWim.ForeColor = "White"; $GbWimIn.Controls.Add($BtnBrWim)

$GbBootBase = New-Object System.Windows.Forms.GroupBox; $GbBootBase.Text = "2. Chọn Nguồn Boot (Bộ vỏ ISO)"; $GbBootBase.Location = "20,110"; $GbBootBase.Size = "860,130"; $GbBootBase.ForeColor = "Yellow"; $TabW2I.Controls.Add($GbBootBase)

# Radio Buttons
$RbUseLocal = New-Object System.Windows.Forms.RadioButton; $RbUseLocal.Text = "Dùng file ISO có sẵn trong máy tính"; $RbUseLocal.Location = "20,25"; $RbUseLocal.AutoSize = $true; $RbUseLocal.Checked = $true; $GbBootBase.Controls.Add($RbUseLocal)
$RbUseCloud = New-Object System.Windows.Forms.RadioButton; $RbUseCloud.Text = "Tải Boot Kit từ Server (JSON Online)"; $RbUseCloud.Location = "20,75"; $RbUseCloud.AutoSize = $true; $GbBootBase.Controls.Add($RbUseCloud)

# Local ISO Controls
$TxtBaseIso = New-Object System.Windows.Forms.TextBox; $TxtBaseIso.Location = "40,50"; $TxtBaseIso.Size = "640,25"; $GbBootBase.Controls.Add($TxtBaseIso)
$BtnBrBase = New-Object System.Windows.Forms.Button; $BtnBrBase.Text = "DUYỆT FILE..."; $BtnBrBase.Location = "700,48"; $BtnBrBase.Size = "140,27"; $BtnBrBase.BackColor = "DimGray"; $BtnBrBase.ForeColor = "White"; $GbBootBase.Controls.Add($BtnBrBase)

# Cloud ISO Controls (ComboBox)
$CbBootKits = New-Object System.Windows.Forms.ComboBox; $CbBootKits.Location = "40,100"; $CbBootKits.Size = "640,25"; $CbBootKits.Enabled = $false; $GbBootBase.Controls.Add($CbBootKits)
$BtnRefresh = New-Object System.Windows.Forms.Button; $BtnRefresh.Text = "LÀM MỚI LIST"; $BtnRefresh.Location = "700,98"; $BtnRefresh.Size = "140,27"; $BtnRefresh.BackColor = "Teal"; $BtnRefresh.ForeColor = "White"; $BtnRefresh.Enabled = $false; $GbBootBase.Controls.Add($BtnRefresh)

$GbOutW2I = New-Object System.Windows.Forms.GroupBox; $GbOutW2I.Text = "3. Xuất File ISO"; $GbOutW2I.Location = "20,250"; $GbOutW2I.Size = "860,100"; $GbOutW2I.ForeColor = "Lime"; $TabW2I.Controls.Add($GbOutW2I)
$BtnStartW2I = New-Object System.Windows.Forms.Button; $BtnStartW2I.Text = "BẮT ĐẦU TẠO ISO"; $BtnStartW2I.Location = "230,30"; $BtnStartW2I.Size = "400,50"; $BtnStartW2I.BackColor = $Theme.Accent; $BtnStartW2I.ForeColor = "White"; $BtnStartW2I.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold); $GbOutW2I.Controls.Add($BtnStartW2I)

$TxtLog2 = New-Object System.Windows.Forms.TextBox; $TxtLog2.Multiline = $true; $TxtLog2.Location = "20,360"; $TxtLog2.Size = "860,310"; $TxtLog2.BackColor = "Black"; $TxtLog2.ForeColor = "Cyan"; $TxtLog2.ReadOnly = $true; $TxtLog2.ScrollBars = "Vertical"; $TabW2I.Controls.Add($TxtLog2)


# --- COMMON FUNCTIONS ---
function Log ($M) { 
    $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $M`r`n"); $TxtLog.ScrollToCaret()
    $TxtLog2.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $M`r`n"); $TxtLog2.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents() 
}

function Get-7Zip {
    $7z = "$env:TEMP\7zr.exe"; if (Test-Path $7z) { return $7z }
    Log "Đang tải 7-Zip..."; try { (New-Object System.Net.WebClient).DownloadFile("https://www.7-zip.org/a/7zr.exe", $7z); return $7z } catch { Log "Lỗi tải 7-Zip!"; return $null }
}

function Download-Fast ($Url, $DestFile) {
    try {
        $HttpClient = New-Object System.Net.Http.HttpClient
        $HttpClient.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
        
        Log "Kết nối Server..."
        $Response = $HttpClient.GetAsync($Url).Result
        if (!$Response.IsSuccessStatusCode) { throw "HTTP Error: $($Response.StatusCode)" }

        $TotalBytes = $Response.Content.Headers.ContentLength
        $RemoteStream = $Response.Content.ReadAsStreamAsync().Result
        $FileStream = [System.IO.File]::Create($DestFile)
        
        $BufferSize = 512 * 1024 
        $Buffer = New-Object byte[] $BufferSize
        $TotalRead = 0
        $LastPercent = 0

        Log "Bắt đầu tải (Mode: Stream, Buffer: 512KB)..."
        
        do {
            $Count = $RemoteStream.Read($Buffer, 0, $BufferSize)
            if ($Count -gt 0) {
                $FileStream.Write($Buffer, 0, $Count)
                $TotalRead += $Count
                
                if ($TotalBytes -gt 0) {
                    $Percent = [Math]::Floor(($TotalRead / $TotalBytes) * 100)
                    if ($Percent -ge $LastPercent + 10) { 
                        Log "Đang tải... $Percent% ($([Math]::Round($TotalRead/1MB, 2)) MB)"
                        $LastPercent = $Percent
                    }
                }
            }
        } while ($Count -gt 0)

        $FileStream.Close()
        $RemoteStream.Close()
        $HttpClient.Dispose()
        Log "Tải hoàn tất 100%."
        return $true
    } catch {
        Log "Lỗi tải file: $($_.Exception.Message)"
        if ($FileStream) { $FileStream.Close() }
        return $false
    }
}

function Get-Oscdimg {
    $Tool = "$env:TEMP\oscdimg.exe"

    if (Test-Path $Tool) { return $Tool }
    $AdkPaths = @(
        "$env:ProgramFiles(x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
        "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
        "$env:ProgramFiles(x86)\Windows Kits\8.1\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
    )
    foreach ($P in $AdkPaths) { if (Test-Path $P) { return $P } }

    Log "Đang thử tải oscdimg.exe từ Server..."
    try { 
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        (New-Object System.Net.WebClient).DownloadFile("https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/refs/heads/main/oscdimg.exe", $Tool)
        if ((Get-Item $Tool).Length -gt 100kb) { return $Tool } 
    } catch { Log "Không tải được từ Server." }
    
    if ([System.Windows.Forms.MessageBox]::Show("Không tìm thấy 'oscdimg.exe'.`nBạn có muốn CHỌN FILE thủ công không?", "Thiếu Tool", "YesNo", "Question") -eq "Yes") {
        $O = New-Object System.Windows.Forms.OpenFileDialog
        $O.Title = "Chọn file oscdimg.exe"
        $O.Filter = "Oscdimg Tool|oscdimg.exe|All Files|*.*"
        if ($O.ShowDialog() -eq "OK") { return $O.FileName }
    }

    if ([System.Windows.Forms.MessageBox]::Show("Vẫn không có tool!`nBạn có muốn tải bộ cài Windows ADK từ Microsoft để cài đặt không?", "Tải ADK", "YesNo", "Warning") -eq "Yes") {
        Log "Đang tải ADK Setup (adksetup.exe)..."
        $AdkSetup = "$env:TEMP\adksetup.exe"
        try {
            (New-Object System.Net.WebClient).DownloadFile("https://go.microsoft.com/fwlink/?linkid=2196127", $AdkSetup)
            
            Log "Đang khởi chạy cài đặt ADK..."
            [System.Windows.Forms.MessageBox]::Show("Tool sẽ mở trình cài đặt ADK.`nVui lòng chọn cài 'Deployment Tools' rồi quay lại đây nhé!", "Hướng dẫn")
            
            Start-Process $AdkSetup -Wait
            foreach ($P in $AdkPaths) { if (Test-Path $P) { return $P } }
        } catch {
            Log "Lỗi khi tải hoặc chạy ADK Setup!"
            [System.Windows.Forms.MessageBox]::Show("Lỗi mạng! Không tải được ADK.", "Lỗi")
        }
    }

    return $null
}

function Get-IsoDrive ($IsoPath) {
    if ($Global:IsoCache.ContainsKey($IsoPath)) {
        $CachedDrv = $Global:IsoCache[$IsoPath]
        if ((Test-Path "$CachedDrv\sources") -or (Test-Path "$CachedDrv\bootmgr")) { return $CachedDrv } else { $Global:IsoCache.Remove($IsoPath) }
    }
    try {
        $Img = Get-DiskImage -ImagePath $IsoPath -ErrorAction SilentlyContinue
        if ($Img -and $Img.Attached) { $Vol = $Img | Get-Volume; if ($Vol) { return "$($Vol.DriveLetter):" } }
    } catch {}
    return $null
}

# --- AIO LOGIC ---
function Scan-Wim ($WimPath, $SourceName) {
    try {
        $Info = Get-WindowsImage -ImagePath $WimPath
        foreach ($I in $Info) {
            $RealVer = $I.Version; if (!$RealVer) { $RealVer = "0.0.0.0" }
            $Grid.Rows.Add($true, $SourceName, $I.ImageIndex, $I.ImageName, "$([Math]::Round($I.Size/1GB,2)) GB", $I.Architecture, $WimPath, $RealVer) | Out-Null
        }
        Log "Đã nạp: $SourceName"
    } catch { Log "Lỗi đọc WIM: $WimPath" }
}

function Process-Iso ($IsoPath) {
    $Form.Cursor = "WaitCursor"; Log "Đang đọc: $IsoPath..."
    $Drv = Get-IsoDrive $IsoPath 
    if (!$Drv) { try { Mount-DiskImage -ImagePath $IsoPath -StorageType ISO -ErrorAction Stop | Out-Null; for($i=0;$i -lt 15;$i++){ $Drv = Get-IsoDrive $IsoPath; if($Drv){ break }; Start-Sleep -Milliseconds 500 } } catch {} } 
    if ($Drv) {
        $Global:IsoCache[$IsoPath] = $Drv
        $WimFiles = Get-ChildItem -Path $Drv -Include "install.wim","install.esd" -Recurse -ErrorAction SilentlyContinue
        if ($WimFiles) { Scan-Wim $WimFiles[0].FullName $IsoPath; $Form.Cursor="Default"; return }
    }
    Log "Mount thất bại. Đang quét bằng 7-Zip..."
    Dismount-DiskImage -ImagePath $IsoPath -ErrorAction SilentlyContinue | Out-Null
    $7z = Get-7Zip; if ($7z) {
        $Hash = (Get-Item $IsoPath).Name.GetHashCode(); $ExtractDir = "$Global:TempWimDir\$Hash"; New-Item -ItemType Directory -Path $ExtractDir -Force | Out-Null
        Start-Process $7z -ArgumentList "e `"$IsoPath`" sources/install.wim sources/install.esd -o`"$ExtractDir`" -y" -NoNewWindow -Wait
        $ExtWim = Get-ChildItem -Path $ExtractDir -Include "install.wim","install.esd" -Recurse -ErrorAction SilentlyContinue
        if ($ExtWim) { Scan-Wim $ExtWim[0].FullName $IsoPath }
    }
    $Form.Cursor = "Default"
}

# --- BUILD CORE (AIO TAB) ---
function Build-Core ($CopyBoot) {
    $RawDir = $TxtOut.Text; if (!$RawDir) { return }
    $Dir = $RawDir -replace '/', '\' 
    
    $RootDrive = [System.IO.Path]::GetPathRoot($Dir)
    $DriveInfo = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $RootDrive.Trim('\') }
    if ($DriveInfo.DriveType -eq 5) { [System.Windows.Forms.MessageBox]::Show("Không thể lưu vào ổ đĩa CD/DVD!", "Lỗi"); return }

    if (!(Test-Path $Dir)) { New-Item -ItemType Directory -Path $Dir -Force | Out-Null }
    $SourceDir = "$Dir\sources"; if (!(Test-Path $SourceDir)) { New-Item -ItemType Directory -Path $SourceDir -Force | Out-Null }

    $Tasks = @(); foreach($r in $Grid.Rows){if($r.Cells[0].Value){$Tasks+=$r}}
    if($Tasks.Count -eq 0){ [System.Windows.Forms.MessageBox]::Show("Chưa chọn phiên bản Windows nào!", "Lỗi"); return }

    $BtnBuild.Enabled=$false
    
    if ($CopyBoot) {
        Log "Đang phân tích để chọn Boot Base xịn nhất..."
        $BestIsoRow = $Tasks[0]; $HighestScore = -1
        foreach ($Row in $Tasks) {
            $Score = 0; $Name = $Row.Cells[3].Value.ToString().ToLower(); $VerStr = $Row.Cells[7].Value.ToString()
            if ($Name -match "windows 11") { $Score += 10000 } elseif ($Name -match "windows 10") { $Score += 5000 } elseif ($Name -match "windows 8") { $Score += 1000 }
            try { $VerObj = [Version]$VerStr; $Score += $VerObj.Major * 100 + $VerObj.Minor } catch {}
            if ($Score -gt $HighestScore) { $HighestScore = $Score; $BestIsoRow = $Row }
        }
        
        Log "=> CHỐT ĐƠN: $($BestIsoRow.Cells[3].Value) (Điểm: $HighestScore) làm Boot Base."
        $FirstSource = $BestIsoRow.Cells[1].Value; $Drv = Get-IsoDrive $FirstSource

        if (!$Drv) {
            Log "Chế độ Dismount & 7-Zip..."
            Dismount-DiskImage -ImagePath $FirstSource -ErrorAction SilentlyContinue | Out-Null
            $7z = Get-7Zip; $ZArgs = @("x", "$FirstSource", "-o$Dir", "-x!sources\install.wim", "-x!sources\install.esd", "-y")
            Start-Process $7z -ArgumentList $ZArgs -NoNewWindow -Wait
        } else {
            Log "Tìm thấy ổ đĩa: $Drv (Robocopy Mirror Mode)..."
            $RoboArgs = @($Drv.TrimEnd('\'), $Dir.TrimEnd('\'), "/E", "/XF", "install.wim", "install.esd", "/MT:16", "/NFL", "/NDL")
            Start-Process "robocopy.exe" -ArgumentList $RoboArgs -NoNewWindow -Wait
        }

        Log "Dọn dẹp tàn dư (Nuclear Wipe)..."; Start-Process "attrib" -ArgumentList "-r `"$Dir\*.*`" /s /d" -NoNewWindow -Wait
        if (Test-Path "$SourceDir\install.wim") { Remove-Item "$SourceDir\install.wim" -Force -ErrorAction SilentlyContinue }
        if (Test-Path "$SourceDir\install.esd") { Remove-Item "$SourceDir\install.esd" -Force -ErrorAction SilentlyContinue }
    }

    $DestWim = "$SourceDir\install.wim"
    $Count = 1
    foreach ($T in $Tasks) {
        $SrcWim = $T.Cells[6].Value; $Idx = $T.Cells[2].Value; $Name = $T.Cells[3].Value
        Log "Đang xuất ($Count/$($Tasks.Count)): $Name..."
        try { Export-WindowsImage -SourceImagePath $SrcWim -SourceIndex $Idx -DestinationImagePath $DestWim -DestinationName "$Name" -CompressionType Maximum -ErrorAction Stop } catch { Log "Lỗi Export: $($_.Exception.Message)"; [System.Windows.Forms.MessageBox]::Show("Lỗi khi xuất file WIM!", "Lỗi"); $BtnBuild.Enabled=$true; return }
        $Count++
    }

    if (!$CopyBoot) { [IO.File]::WriteAllText("$Dir\AIO_Installer.cmd", "@echo off`r`npushd `"%~dp0`"`r`ntitle PHAT TAN PC`r`nset WIM=%~dp0sources\install.wim`r`nif not exist `"%WIM%`" set WIM=%~dp0install.wim`r`ndism /Apply-Image /ImageFile:`"%WIM%`" /Index:1 /ApplyDir:C:\`r`nbcdboot C:\Windows /s C:`r`nwpeutil reboot") }
    Log "HOÀN TẤT!"; [System.Windows.Forms.MessageBox]::Show("Đã xong!", "OK"); Invoke-Item $Dir; $BtnBuild.Enabled=$true
}

# --- LOAD BOOT KITS (FIXED SYNTAX & LOGIC) ---
function Load-Cloud-BootKits {
    $Form.Cursor = "WaitCursor"; Log "Đang tải danh sách Boot Kit..."
    $CbBootKits.Items.Clear()
    $CbBootKits.DisplayMember = "Name"

    try {
        # [QUAN TRỌNG NHẤT] Ép buộc Windows dùng TLS 1.2 (GitHub bắt buộc cái này)
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

        # Dùng WebClient (Cổ điển nhưng an toàn, máy nào cũng có)
        $WebClient = New-Object System.Net.WebClient
        
        # Fake User-Agent để GitHub không chặn (Giả làm trình duyệt Chrome)
        $WebClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
        
        # Tải JSON về (Dạng text)
        $JsonContent = $WebClient.DownloadString($Global:JsonUrl)
        $WebClient.Dispose()

        # Xử lý dữ liệu JSON
        $RawItems = $JsonContent | ConvertFrom-Json
        if ($RawItems -isnot [Array]) { $RawItems = @($RawItems) }

        $BestIndex = 0 
        for ($i = 0; $i -lt $RawItems.Count; $i++) {
            $CbBootKits.Items.Add($RawItems[$i])
            
            # Logic tự chọn Windows 11 / Gen 12
            $Name = $RawItems[$i].Name.ToString()
            if ($Name -match "Windows 11" -or $Name -match "Gen 12" -or $Name -match "Moi nhat") {
                $BestIndex = $i 
            }
        }

        if ($CbBootKits.Items.Count -gt 0) {
            $CbBootKits.SelectedIndex = $BestIndex
            Log "Auto-Select: $($CbBootKits.Text)"
        }
        Log "Đã tải xong list ($($CbBootKits.Items.Count) bản)."

    } catch {
        # In lỗi chi tiết nếu vẫn tạch
        Log "Lỗi tải JSON: $($_.Exception.Message)"
        if ($_.Exception.InnerException) {
            Log "Chi tiết: $($_.Exception.InnerException.Message)"
        }
        
        Log "-> Đang dùng list dự phòng."
        $Global:DefaultBootKits | ForEach-Object { $CbBootKits.Items.Add([PSCustomObject]$_) }
        $CbBootKits.SelectedIndex = 0
    }
    $Form.Cursor = "Default"
}
# --- WIM TO ISO (FIXED) ---
function Wim-To-Iso {
    $Wim = $TxtWimIn.Text
    if (!$Wim -or !(Test-Path $Wim)) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn file WIM hoặc ESD!", "Lỗi"); return }
    
    $WorkDir = "$env:TEMP\Wim2Iso_Work"
    if (Test-Path $WorkDir) { Remove-Item $WorkDir -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item $WorkDir -ItemType Directory -Force | Out-Null

    $Oscd = Get-Oscdimg
    if (!$Oscd) { [System.Windows.Forms.MessageBox]::Show("Không tìm thấy oscdimg.exe, hủy bỏ!", "Hủy"); return }

    if ($RbUseLocal.Checked) {
        $BaseIso = $TxtBaseIso.Text
        if (!$BaseIso -or !(Test-Path $BaseIso)) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn file ISO gốc!", "Lỗi"); return }
        Log "Mode: Local ISO. Đang trích xuất..."
        $Drv = Get-IsoDrive $BaseIso
        if (!$Drv) {
             Mount-DiskImage -ImagePath $BaseIso -StorageType ISO -ErrorAction SilentlyContinue | Out-Null
             for($i=0;$i -lt 10;$i++){ $Drv = Get-IsoDrive $BaseIso; if($Drv){ break }; Start-Sleep -Milliseconds 500 }
        }
        if ($Drv) {
             Start-Process "robocopy.exe" -ArgumentList "`"$($Drv.TrimEnd('\'))`" `"$WorkDir`" /E /XF install.wim install.esd /MT:16 /NFL /NDL" -NoNewWindow -Wait
        } else {
             $7z = Get-7Zip; Start-Process $7z -ArgumentList "x `"$BaseIso`" -o`"$WorkDir`" -x!sources\install.wim -x!sources\install.esd -y" -NoNewWindow -Wait
        }
    } else {
        if ($CbBootKits.SelectedItem -eq $null) { Load-Cloud-BootKits }
        if ($CbBootKits.SelectedItem -eq $null) { return }
        
        $Kit = $CbBootKits.SelectedItem; $KitName = $Kit.Name; $KitUrl = $Kit.Url
        $KitFile = "$Global:BootKitCacheDir\$($Kit.FileName)"
        
        Log "Mode: Cloud Boot Kit ($KitName)"
        
        if (!(Test-Path $KitFile) -or (Get-Item $KitFile).Length -lt 1MB) {
            $Success = Download-Fast $KitUrl $KitFile
            if (!$Success) { [System.Windows.Forms.MessageBox]::Show("Tải thất bại! Kiểm tra mạng.", "Lỗi"); return }
        } else { Log "Dùng Boot Kit từ Cache." }
        
        Log "Đang giải nén Boot Kit (Dùng Windows Native)..."
        try {
            Expand-Archive -LiteralPath "$KitFile" -DestinationPath "$WorkDir" -Force -ErrorAction Stop
        } catch {
            Log "Windows không giải nén được. Đang thử lại bằng 7-Zip..."
            $7z = Get-7Zip
            Start-Process $7z -ArgumentList "x `"$KitFile`" -o`"$WorkDir`" -y" -NoNewWindow -Wait
        }
    }

    if (!(Test-Path "$WorkDir\boot\etfsboot.com")) {
        Log "Vẫn thiếu file Boot! Có thể file ZIP tải về bị lỗi cấu trúc."
        $Result = [System.Windows.Forms.MessageBox]::Show("Tool không tự giải nén được file ZIP này.`nTôi sẽ mở thư mục chứa file ZIP và thư mục đích lên.`nBạn hãy GIẢI NÉN TAY toàn bộ file trong ZIP vào thư mục đích nhé!`n`nLàm xong thì bấm OK để đóng gói.", "Cần Sức Cơm", "OKCancel", "Warning")
        
        if ($Result -eq "OK") {
            Invoke-Item "$Global:BootKitCacheDir" 
            Invoke-Item "$WorkDir"                
            [System.Windows.Forms.MessageBox]::Show("1. Mở file ZIP (BootKit...).`n2. Copy toàn bộ file bên trong.`n3. Paste vào thư mục 'Wim2Iso_Work' đang mở.`n4. Bấm OK ở đây khi đã làm xong.", "Hướng dẫn")
            if (!(Test-Path "$WorkDir\boot\etfsboot.com")) {
                 [System.Windows.Forms.MessageBox]::Show("Vẫn chưa thấy file! Hủy bỏ.", "Thua"); return
            }
        } else {
            return
        }
    }

    $Save = New-Object System.Windows.Forms.SaveFileDialog; $Save.FileName = "MyCustomWin.iso"; $Save.Filter = "ISO|*.iso"
    if ($Save.ShowDialog() -eq "OK") {
        $TargetIso = $Save.FileName
        
        $DestDrive = [System.IO.Path]::GetPathRoot($TargetIso).Trim('\')
        try { if ((Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $DestDrive }).FreeSpace -lt ((Get-Item $Wim).Length + 1GB)) { [System.Windows.Forms.MessageBox]::Show("Ổ đĩa đích đã đầy!", "Full"); return } } catch {}

        Log "Đang bơm file WIM/ESD vào..."
        $DestWimDir = "$WorkDir\sources"; if(!(Test-Path $DestWimDir)){ New-Item -ItemType Directory -Path $DestWimDir | Out-Null }
        
        $Ext = [System.IO.Path]::GetExtension($Wim).ToLower()
        $TargetName = "install.wim"
        if ($Ext -eq ".esd") { $TargetName = "install.esd" }
        Copy-Item $Wim "$DestWimDir\$TargetName" -Force
        
        Log "Đóng gói file ISO..."
        $IsoArgs = "-m -o -u2 -udfver102 -bootdata:2#p0,e,b`"$WorkDir\boot\etfsboot.com`"#pEF,e,b`"$WorkDir\efi\microsoft\boot\efisys.bin`" `"$WorkDir`" `"$TargetIso`""
        
        $Proc = Start-Process $Oscd -ArgumentList $IsoArgs -NoNewWindow -PassThru -Wait
        
        if ($Proc.ExitCode -eq 0 -and (Test-Path $TargetIso)) {
            Log "XONG! File ISO tại: $TargetIso"
            [System.Windows.Forms.MessageBox]::Show("Thành công! ISO đã ra lò.", "Success")
            Remove-Item $WorkDir -Recurse -Force -ErrorAction SilentlyContinue
        } else {
            Log "LỖI: Oscdimg thất bại ($($Proc.ExitCode))."
            [System.Windows.Forms.MessageBox]::Show("Lỗi đóng gói ISO!", "Lỗi")
        }
    }
}

# --- MAKE ISO FROM FOLDER ---
function Make-Iso-Action ($SourceFolder) {
    if (!$SourceFolder -or !(Test-Path $SourceFolder)) { return }
    $Oscd = Get-Oscdimg; if (!$Oscd) { return }
    $Save = New-Object System.Windows.Forms.SaveFileDialog; $Save.FileName="WinAIO.iso"; $Save.Filter="ISO|*.iso"
    if ($Save.ShowDialog() -eq "OK") {
        $Target = $Save.FileName
        $Src = $SourceFolder.TrimEnd('\'); if ($Src.Length -le 3) { if ([System.Windows.Forms.MessageBox]::Show("Nguồn là Root Drive (Ổ gốc). Bạn có chắc muốn tiếp tục?", "Cảnh báo", "YesNo") -eq "No") { return } }
        $IsoArgs = "-m -o -u2 -udfver102 -bootdata:2#p0,e,b`"$Src\boot\etfsboot.com`"#pEF,e,b`"$Src\efi\microsoft\boot\efisys.bin`" `"$Src`" `"$Target`""
        Start-Process $Oscd -ArgumentList $IsoArgs -NoNewWindow -Wait; [System.Windows.Forms.MessageBox]::Show("Đã tạo xong ISO!", "OK")
    }
}

# --- EVENTS ---
$BtnAdd.Add_Click({ $O = New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="ISO/WIM|*.iso;*.wim;*.esd"; $O.Multiselect=$true; if($O.ShowDialog() -eq "OK"){ foreach($f in $O.FileNames){ if(!($TxtIsoList.Text.Contains($f))){ $TxtIsoList.Text+="$f; "; Process-Iso $f } } } })
$BtnEject.Add_Click({ Get-DiskImage -ImagePath "*.iso" | Dismount-DiskImage -ErrorAction SilentlyContinue; Remove-Item $Global:TempWimDir -Recurse -Force; $TxtIsoList.Text=""; $Grid.Rows.Clear(); $Global:IsoCache=@{}; Log "Đã làm mới lại từ đầu." })
$BtnBrowseOut.Add_Click({ $F=New-Object System.Windows.Forms.FolderBrowserDialog; if($F.ShowDialog() -eq "OK"){$TxtOut.Text=$F.SelectedPath} })
$BtnBuild.Add_Click({ $Pt = New-Object System.Drawing.Point(0, $BtnBuild.Height); $MenuBuild.Show($BtnBuild, $Pt) })
$Item1.Add_Click({ Build-Core $false }); $Item2.Add_Click({ Build-Core $true })
$BtnMakeIso.Add_MouseDown({ if ($_.Button -eq 'Right') { $MenuIsoHidden.Show($BtnMakeIso, $_.Location) } else { Make-Iso-Action $TxtOut.Text } })
$MItem_Default.Add_Click({ Make-Iso-Action $TxtOut.Text }); $MItem_Custom.Add_Click({ $F = New-Object System.Windows.Forms.FolderBrowserDialog; if ($F.ShowDialog() -eq "OK") { Make-Iso-Action $F.SelectedPath } })
$BtnHddBoot.Add_Click({
    $OutDir = $TxtOut.Text; if (!($Grid.Rows.Count)) { return }
    $MaxVer = [Version]"0.0.0.0"; $BestRow = $Grid.Rows[0]
    foreach ($Row in $Grid.Rows) { try { if ([Version]$Row.Cells[7].Value -gt $MaxVer) { $MaxVer = [Version]$Row.Cells[7].Value; $BestRow = $Row } } catch {} }
    $FirstIso = $BestRow.Cells[1].Value; $Drv = Get-IsoDrive $FirstIso
    if (!$Drv) { Dismount-DiskImage -ImagePath $FirstIso -ErrorAction SilentlyContinue | Out-Null; $7z = Get-7Zip; Start-Process $7z -ArgumentList "e `"$FirstIso`" sources/boot.wim -o`"$OutDir`" -y" -NoNewWindow -Wait } else { Copy-Item "$Drv\sources\boot.wim" "$OutDir\boot.wim" -Force; if (!(Test-Path "$OutDir\boot.sdi")) { Copy-Item "$Drv\boot\boot.sdi" "$OutDir\boot.sdi" -Force } }
    $Mnt = "$env:TEMP\Mnt"; New-Item $Mnt -ItemType Directory -Force | Out-Null; Start-Process "dism" "/Mount-Image /ImageFile:`"$OutDir\boot.wim`" /Index:2 /MountDir:`"$Mnt`"" -Wait -NoNewWindow
    [IO.File]::WriteAllText("$Mnt\Windows\System32\winpeshl.ini", "[LaunchApps]`r`n%SystemRoot%\System32\AutoRunAIO.cmd"); [IO.File]::WriteAllText("$Mnt\Windows\System32\AutoRunAIO.cmd", "@echo off`r`nfor %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (if exist `"%%d:\AIO_Output\AIO_Installer.cmd`" (%%d: & cd \AIO_Output & call AIO_Installer.cmd & exit))`r`ncmd.exe")
    Start-Process "dism" "/Unmount-Image /MountDir:`"$Mnt`" /Commit" -Wait -NoNewWindow; Remove-Item $Mnt -Recurse -Force
    [System.Windows.Forms.MessageBox]::Show("Đã tạo xong HDD Boot Menu!", "Thành công")
})

# Tab 2 UI Logic
$BtnBrWim.Add_Click({ $O = New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="Windows Image|*.wim;*.esd"; if($O.ShowDialog() -eq "OK"){$TxtWimIn.Text=$O.FileName} })
$BtnBrBase.Add_Click({ $O = New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="ISO Image|*.iso"; if($O.ShowDialog() -eq "OK"){$TxtBaseIso.Text=$O.FileName} })
$RbUseLocal.Add_CheckedChanged({ $TxtBaseIso.Enabled=$RbUseLocal.Checked; $BtnBrBase.Enabled=$RbUseLocal.Checked; $CbBootKits.Enabled=$RbUseCloud.Checked; $BtnRefresh.Enabled=$RbUseCloud.Checked })
$BtnRefresh.Add_Click({ Load-Cloud-BootKits })
$BtnStartW2I.Add_Click({ Wim-To-Iso })

$Form.Add_FormClosing({ try { foreach ($Iso in $Global:IsoCache.Values) { Dismount-DiskImage -ImagePath $Iso -ErrorAction SilentlyContinue | Out-Null }; Remove-Item $Global:TempWimDir -Recurse -Force } catch {} })
$Form.ShowDialog() | Out-Null

} catch { [System.Windows.Forms.MessageBox]::Show("Lỗi Nghiêm Trọng: $($_.Exception.Message)", "Critical") }
