# --- 1. FORCE ADMIN & SECURITY PROTOCOL ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# [FIX QUANTRONG] Ép buộc sử dụng TLS 1.2 để tải file từ Github không bị lỗi
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- CONFIG ---
$WorkDir = "D:\PhatTan_WinModder" 
$ToolsDir = "$env:TEMP\PhatTan_Tools"
if (!(Test-Path $ToolsDir)) { New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null }

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WINDOWS MODDER STUDIO V2 - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(920, 680)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 25) # Darker Theme
$Form.ForeColor = "WhiteSmoke"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header Style
$LblT = New-Object System.Windows.Forms.Label
$LblT.Text = "PHAT TAN PC - SYSTEM BUILDER"
$LblT.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$LblT.ForeColor = "Gold"
$LblT.AutoSize = $true
$LblT.Location = "20,15"
$Form.Controls.Add($LblT)

# Status Strip (Thanh trạng thái bên dưới)
$StatusStrip = New-Object System.Windows.Forms.StatusStrip
$StatusLbl = New-Object System.Windows.Forms.ToolStripStatusLabel
$StatusLbl.Text = "Ready."
$StatusLbl.ForeColor = "Black"
$StatusStrip.Items.Add($StatusLbl) | Out-Null
$Form.Controls.Add($StatusStrip)

# TABS
$Tabs = New-Object System.Windows.Forms.TabControl
$Tabs.Location = "20,70"
$Tabs.Size = "865,530"
$Tabs.Appearance = "FlatButtons" 
$Tabs.Padding = New-Object System.Drawing.Point(20, 6)
$Form.Controls.Add($Tabs)

function Make-Tab ($T) { 
    $P = New-Object System.Windows.Forms.TabPage
    $P.Text = "  $T  "
    $P.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $Tabs.Controls.Add($P)
    return $P 
}

$TabCap = Make-Tab "1. CAPTURE OS (SAO LƯU)"
$TabMod = Make-Tab "2. MODDING ISO (CHỈNH SỬA)"

# =========================================================================================
# TAB 1: CAPTURE
# =========================================================================================
$GbCap = New-Object System.Windows.Forms.GroupBox; $GbCap.Text="QUY TRÌNH ĐÓNG GÓI WINDOWS ĐANG CHẠY"; $GbCap.Location="20,20"; $GbCap.Size="820,450"; $GbCap.ForeColor="Cyan"; $TabCap.Controls.Add($GbCap)

$LblC1 = New-Object System.Windows.Forms.Label; $LblC1.Text="Lưu ý: Tắt hết các phần mềm đang chạy trước khi bắt đầu.`nTool sẽ chụp lại toàn bộ ổ C: và nén thành install.wim."; $LblC1.Location="30,40"; $LblC1.AutoSize=$true; $LblC1.ForeColor="LightGray"; $GbCap.Controls.Add($LblC1)

$LblC2 = New-Object System.Windows.Forms.Label; $LblC2.Text="Nơi lưu file ISO thành phẩm:"; $LblC2.Location="30,100"; $LblC2.AutoSize=$true; $GbCap.Controls.Add($LblC2)
$TxtCapOut = New-Object System.Windows.Forms.TextBox; $TxtCapOut.Location="30,125"; $TxtCapOut.Size="550,25"; $TxtCapOut.Text="D:\PhatTan_Backup.iso"; $GbCap.Controls.Add($TxtCapOut)
$BtnCapBrowse = New-Object System.Windows.Forms.Button; $BtnCapBrowse.Text="CHỌN..."; $BtnCapBrowse.Location="600,123"; $BtnCapBrowse.Size="100,27"; $BtnCapBrowse.ForeColor="Black"; $GbCap.Controls.Add($BtnCapBrowse)

$BtnStartCap = New-Object System.Windows.Forms.Button; $BtnStartCap.Text="BẮT ĐẦU CAPTURE & TẠO ISO"; $BtnStartCap.Location="30,180"; $BtnStartCap.Size="670,60"; $BtnStartCap.BackColor="OrangeRed"; $BtnStartCap.ForeColor="White"; $BtnStartCap.Font="Segoe UI, 12, Bold"; $GbCap.Controls.Add($BtnStartCap)

$TxtLogCap = New-Object System.Windows.Forms.TextBox; $TxtLogCap.Multiline=$true; $TxtLogCap.Location="30,260"; $TxtLogCap.Size="670,160"; $TxtLogCap.BackColor="Black"; $TxtLogCap.ForeColor="Lime"; $TxtLogCap.ScrollBars="Vertical"; $TxtLogCap.ReadOnly=$true; $GbCap.Controls.Add($TxtLogCap)

# =========================================================================================
# TAB 2: MODDING
# =========================================================================================
# --- STEP 1: LOAD ISO ---
$GbStep1 = New-Object System.Windows.Forms.GroupBox; $GbStep1.Text="BƯỚC 1: CHỌN FILE ISO GỐC (Source)"; $GbStep1.Location="20,20"; $GbStep1.Size="820,80"; $GbStep1.ForeColor="Yellow"; $TabMod.Controls.Add($GbStep1)
$TxtIsoSrc = New-Object System.Windows.Forms.TextBox; $TxtIsoSrc.Location="20,35"; $TxtIsoSrc.Size="600,25"; $GbStep1.Controls.Add($TxtIsoSrc)
$BtnIsoSrc = New-Object System.Windows.Forms.Button; $BtnIsoSrc.Text="MỞ FILE ISO"; $BtnIsoSrc.Location="640,33"; $BtnIsoSrc.Size="120,27"; $BtnIsoSrc.ForeColor="Black"; $GbStep1.Controls.Add($BtnIsoSrc)

# --- STEP 2: MODIFY ---
$GbStep2 = New-Object System.Windows.Forms.GroupBox; $GbStep2.Text="BƯỚC 2: CAN THIỆP HỆ THỐNG"; $GbStep2.Location="20,110"; $GbStep2.Size="820,280"; $GbStep2.ForeColor="Lime"; $GbStep2.Enabled=$false; $TabMod.Controls.Add($GbStep2)

function Add-ModBtn ($T, $X, $Y, $Col, $Cmd) { 
    $b=New-Object System.Windows.Forms.Button; $b.Text=$T; $b.Location="$X,$Y"; $b.Size="230,45"; 
    $b.BackColor=$Col; $b.ForeColor="Black"; $b.FlatStyle="Flat"; $b.Add_Click($Cmd); $GbStep2.Controls.Add($b) 
}

Add-ModBtn "1. GIẢI NÉN & MOUNT" 30 40 "Cyan" { Start-Mount }
Add-ModBtn "2. THÊM FOLDER APP/DATA" 30 100 "White" { Add-Folder }
Add-ModBtn "3. THÊM DRIVER (FOLDER)" 290 100 "White" { Add-Driver }
Add-ModBtn "4. COPY FILE RA DESKTOP" 550 100 "White" { Add-DesktopFile }
Add-ModBtn "DỌN DẸP MOUNT LỖI" 550 40 "Red" { Force-Cleanup } # Nut moi

$LblMountInfo = New-Object System.Windows.Forms.Label; $LblMountInfo.Text="TRẠNG THÁI: CHƯA MOUNT"; $LblMountInfo.Location="290,55"; $LblMountInfo.AutoSize=$true; $LblMountInfo.Font="Segoe UI, 10, Bold"; $LblMountInfo.ForeColor="Gray"; $GbStep2.Controls.Add($LblMountInfo)

$TxtLogMod = New-Object System.Windows.Forms.TextBox; $TxtLogMod.Multiline=$true; $TxtLogMod.Location="30,160"; $TxtLogMod.Size="750,100"; $TxtLogMod.BackColor="Black"; $TxtLogMod.ForeColor="Cyan"; $TxtLogMod.ScrollBars="Vertical"; $TxtLogMod.ReadOnly=$true; $GbStep2.Controls.Add($TxtLogMod)

# --- STEP 3: BUILD ---
$BtnBuildIso = New-Object System.Windows.Forms.Button; $BtnBuildIso.Text="BƯỚC 3: ĐÓNG GÓI RA FILE ISO MỚI (REBUILD)"; $BtnBuildIso.Location="20,410"; $BtnBuildIso.Size="820,60"; $BtnBuildIso.BackColor="Green"; $BtnBuildIso.ForeColor="White"; $BtnBuildIso.Font="Segoe UI, 14, Bold"; $BtnBuildIso.Enabled=$false; $TabMod.Controls.Add($BtnBuildIso)

# =========================================================================================
# LOGIC & FUNCTIONS
# =========================================================================================
function Set-Status ($Msg) { $StatusLbl.Text = $Msg; [System.Windows.Forms.Application]::DoEvents() }
function Log ($Box, $Msg) { 
    $Box.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $Msg`r`n"); $Box.ScrollToCaret(); Set-Status $Msg
}

# --- TOOL DOWNLOADER (OSCDIMG) FIX ---
# --- TOOL MANAGER (OSCDIMG) - QUY TRÌNH 5 BƯỚC ---
function Check-Tools {
    $OscTarget = "$ToolsDir\oscdimg.exe"

    # BƯỚC 1: Kiểm tra xem đã có sẵn trong thư mục Tool của App chưa
    if (Test-Path $OscTarget) { return $true }

    # BƯỚC 2: Tự động tải từ Github (Kho-Do-Nghe)
    # Check file > 100KB để tránh file lỗi 0kb hoặc file html 404
    Set-Status "Đang tải oscdimg.exe từ Server Phat Tan..."
    try {
        $Url = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/refs/heads/main/oscdimg.exe"
        (New-Object System.Net.WebClient).DownloadFile($Url, $OscTarget)
        
        if ((Get-Item $OscTarget).Length -gt 100kb) {
            Set-Status "Tải xong Tool."
            return $true
        } else {
            # Nếu file tải về quá nhẹ (file lỗi), xóa đi để chạy bước tiếp theo
            Remove-Item $OscTarget -Force 
        }
    } catch { 
        Set-Status "Lỗi tải Server, chuyển sang bước tìm kiếm..."
    }

    # BƯỚC 3: Quét xem máy có cài sẵn Windows ADK không
    $AdkPaths = @(
        "$env:ProgramFiles(x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
        "$env:ProgramFiles(x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\x86\Oscdimg\oscdimg.exe",
        "C:\Windows\System32\oscdimg.exe"
    )
    foreach ($P in $AdkPaths) {
        if (Test-Path $P) {
            Copy-Item $P $OscTarget -Force
            return $true
        }
    }

    # BƯỚC 4 & 5: Hỏi người dùng (Browse hoặc Tải ADK)
    $Ask = [System.Windows.Forms.MessageBox]::Show("Không tìm thấy file tạo ISO (oscdimg.exe).`n`n- Bấm [YES] để trỏ đường dẫn file (nếu bạn có sẵn).`n- Bấm [NO] để tải bộ cài ADK từ Microsoft (Sẽ rất lâu).`n- Bấm [CANCEL] để hủy.", "Thiếu Tool", "YesNoCancel", "Warning")

    if ($Ask -eq "Yes") {
        # --- BƯỚC 4: BROWSE FILE ---
        $O = New-Object System.Windows.Forms.OpenFileDialog
        $O.Title = "Chọn file oscdimg.exe trên máy của bạn"
        $O.Filter = "Oscdimg Tool|oscdimg.exe"
        if ($O.ShowDialog() -eq "OK") {
            try {
                Copy-Item $O.FileName $OscTarget -Force
                return $true
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Lỗi copy file: $($_.Exception.Message)", "Error")
            }
        }
    }
    elseif ($Ask -eq "No") {
        # --- BƯỚC 5: TẢI ADK SETUP (LAST RESORT) ---
        try {
            Set-Status "Đang tải bộ cài ADK (adksetup.exe)..."
            $AdkSetup = "$env:TEMP\adksetup.exe"
            (New-Object System.Net.WebClient).DownloadFile("https://go.microsoft.com/fwlink/?linkid=2243390", $AdkSetup)
            
            if ([System.Windows.Forms.MessageBox]::Show("Đã tải xong ADK Setup. Bạn hãy cài đặt nó, sau đó chạy lại Tool này.`n`nBấm OK để mở bộ cài.", "Hướng dẫn") -eq "OK") {
                Start-Process $AdkSetup -Wait
                # Hy vọng sau khi cài xong nó nằm ở đường dẫn mặc định, check lại lần nữa
                foreach ($P in $AdkPaths) {
                    if (Test-Path $P) { Copy-Item $P $OscTarget -Force; return $true }
                }
            }
        } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi tải ADK. Vui lòng kiểm tra mạng.", "Error") }
    }

    Set-Status "Thiếu Tool, không thể tạo ISO."
    return $false
}
# --- TAB 1 LOGIC: CAPTURE ---
$BtnCapBrowse.Add_Click({
    $S = New-Object System.Windows.Forms.SaveFileDialog; $S.Filter="ISO File|*.iso"; $S.FileName="PhatTan_Backup.iso"
    if($S.ShowDialog() -eq "OK"){$TxtCapOut.Text=$S.FileName}
})

$BtnStartCap.Add_Click({
    if (!(Check-Tools)) { return }
    $IsoPath = $TxtCapOut.Text
    $WimFile = "$WorkDir\Capture\install.wim"
    $IsoDir  = "$WorkDir\Capture\ISO_Root"
    
    # Canh bao
    if ($IsoPath -like "C:*") { [System.Windows.Forms.MessageBox]::Show("Không được lưu file ISO vào ổ C:", "Cảnh báo"); return }

    if (Test-Path $WorkDir) { Remove-Item $WorkDir -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $IsoDir -Force | Out-Null
    
    $BtnStartCap.Enabled=$false; $Form.Cursor = "WaitCursor"
    Log $TxtLogCap ">>> ĐANG BẮT ĐẦU CAPTURE Ổ C: (Quá trình này rất lâu)..."
    
    try {
        # Loai bo cac thu muc rac khi capture
        Start-Process "dism" -ArgumentList "/Capture-Image /ImageFile:`"$WimFile`" /CaptureDir:C:\ /Name:`"Phat Tan Windows`" /Compress:max /ScratchDir:`"$env:TEMP`"" -Wait -NoNewWindow
        Log $TxtLogCap " [OK] Đã Capture xong C: -> install.wim"
        
        Log $TxtLogCap " [INFO] File WIM đã nằm tại: $WimFile"
        Log $TxtLogCap " [INFO] Để tạo ISO Boot, hãy qua Tab 2, chọn 1 file ISO gốc và thay thế install.wim!"
        
        [System.Windows.Forms.MessageBox]::Show("Đã tạo xong file install.wim!`nHãy sang Tab 2 để đóng gói nó vào ISO.", "Thành công")
        Invoke-Item (Split-Path $WimFile)
    } catch { Log $TxtLogCap " [ERR] Lỗi Capture: $($_.Exception.Message)" }
    
    $BtnStartCap.Enabled=$true; $Form.Cursor = "Default"
})

# --- TAB 2 LOGIC: MODDING ---
$Global:MountDir = "$WorkDir\Mount"
$Global:ExtractDir = "$WorkDir\Extracted"

$BtnIsoSrc.Add_Click({
    $O = New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="ISO File|*.iso"
    if($O.ShowDialog() -eq "OK"){$TxtIsoSrc.Text=$O.FileName; $GbStep2.Enabled=$true}
})

function Force-Cleanup {
    Log $TxtLogMod ">>> Đang dọn dẹp các bản Mount cũ..."
    Start-Process "dism" -ArgumentList "/Cleanup-Wim" -Wait -NoNewWindow
    Start-Process "dism" -ArgumentList "/Unmount-Image /MountDir:`"$Global:MountDir`" /Discard" -Wait -NoNewWindow -ErrorAction SilentlyContinue
    Log $TxtLogMod " [OK] Đã dọn dẹp (Cleanup)."
}

function Start-Mount {
    $Iso = $TxtIsoSrc.Text
    if (!(Test-Path $Iso)) { return }
    
    if (Test-Path $WorkDir) { Remove-Item $WorkDir -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $Global:ExtractDir -Force | Out-Null
    New-Item -ItemType Directory -Path $Global:MountDir -Force | Out-Null
    
    $Form.Cursor = "WaitCursor"
    Log $TxtLogMod ">>> Đang Mount ISO ra ổ ảo..."
    Mount-DiskImage -ImagePath $Iso -StorageType ISO -ErrorAction SilentlyContinue | Out-Null
    $Vol = Get-DiskImage -ImagePath $Iso | Get-Volume
    $Drv = "$($Vol.DriveLetter):"
    
    Log $TxtLogMod ">>> Đang copy dữ liệu ISO..."
    Copy-Item "$Drv\*" $Global:ExtractDir -Recurse -Force
    
    # Auto Check ESD vs WIM
    $Wim = "$Global:ExtractDir\sources\install.wim"
    $Esd = "$Global:ExtractDir\sources\install.esd"
    
    if (!(Test-Path $Wim)) { 
        if (Test-Path $Esd) { 
            Log $TxtLogMod " [DETECT] Phát hiện file ESD. Đang Convert sang WIM (Rất lâu)..."
            Start-Process "dism" -ArgumentList "/Export-Image /SourceImageFile:`"$Esd`" /SourceIndex:1 /DestinationImageFile:`"$Wim`" /Compress:max /CheckIntegrity" -Wait -NoNewWindow
            Remove-Item $Esd -Force
        } else {
            $Form.Cursor = "Default"
            [System.Windows.Forms.MessageBox]::Show("Không tìm thấy install.wim hoặc install.esd trong ISO này!", "Lỗi"); return
        }
    }
    
    Log $TxtLogMod ">>> Đang Mount install.wim vào thư mục Mount..."
    Start-Process "dism" -ArgumentList "/Mount-Image /ImageFile:`"$Wim`" /Index:1 /MountDir:`"$Global:MountDir`"" -Wait -NoNewWindow
    
    $LblMountInfo.Text = "TRẠNG THÁI: ĐÃ MOUNT THÀNH CÔNG"
    $LblMountInfo.ForeColor = "Lime"
    $BtnBuildIso.Enabled = $true
    $Form.Cursor = "Default"
    Log $TxtLogMod " [OK] Sẵn sàng Modding."
}

function Add-Folder {
    $FBD = New-Object System.Windows.Forms.FolderBrowserDialog; $FBD.Description="Chọn thư mục muốn ném vào ổ C"
    if ($FBD.ShowDialog() -eq "OK") {
        $Src = $FBD.SelectedPath; $Name = Split-Path $Src -Leaf; $Dst = "$Global:MountDir\$Name"
        Copy-Item $Src $Dst -Recurse -Force
        Log $TxtLogMod " [OK] Đã thêm Folder: $Name"
    }
}

function Add-Driver {
    $FBD = New-Object System.Windows.Forms.FolderBrowserDialog; $FBD.Description="Chọn thư mục chứa Driver (.inf)"
    if ($FBD.ShowDialog() -eq "OK") {
        $Form.Cursor = "WaitCursor"
        Log $TxtLogMod ">>> Đang Inject Driver..."
        Start-Process "dism" -ArgumentList "/Image:`"$Global:MountDir`" /Add-Driver /Driver:`"$($FBD.SelectedPath)`" /Recurse" -Wait -NoNewWindow
        Log $TxtLogMod " [OK] Đã nạp Driver."
        $Form.Cursor = "Default"
    }
}

function Add-DesktopFile {
    $O = New-Object System.Windows.Forms.OpenFileDialog
    if ($O.ShowDialog() -eq "OK") {
        $Dst = "$Global:MountDir\Users\Public\Desktop"
        Copy-Item $O.FileName $Dst -Force
        Log $TxtLogMod " [OK] Đã thêm file vào Desktop."
    }
}

$BtnBuildIso.Add_Click({
    if (!(Check-Tools)) { return }
    $Save = New-Object System.Windows.Forms.SaveFileDialog; $Save.Filter="ISO File|*.iso"; $Save.FileName="Windows_Modded_PhatTan.iso"
    if ($Save.ShowDialog() -eq "OK") {
        $IsoOut = $Save.FileName
        $Osc = "$ToolsDir\oscdimg.exe"
        
        $Form.Cursor = "WaitCursor"
        Log $TxtLogMod ">>> Đang Unmount và Lưu thay đổi..."
        Start-Process "dism" -ArgumentList "/Unmount-Image /MountDir:`"$Global:MountDir`" /Commit" -Wait -NoNewWindow
        
        Log $TxtLogMod ">>> Đang đóng gói ISO (OSCDIMG)..."
        # Dual Boot Command (UEFI + Legacy)
        $BootData = "2#p0,e,b`"$Global:ExtractDir\boot\etfsboot.com`"#pEF,e,b`"$Global:ExtractDir\efi\microsoft\boot\efisys.bin`""
        
        $Proc = Start-Process $Osc -ArgumentList "-bootdata:$BootData -u2 -udfver102 `"$Global:ExtractDir`" `"$IsoOut`"" -Wait -NoNewWindow -PassThru
        
        if ($Proc.ExitCode -eq 0) {
            Log $TxtLogMod " [SUCCESS] ISO đã ra lò!"
            [System.Windows.Forms.MessageBox]::Show("THÀNH CÔNG RỰC RỠ!`nFile ISO: $IsoOut", "Phat Tan PC")
            Invoke-Item (Split-Path $IsoOut)
        } else {
            Log $TxtLogMod " [ERR] Lỗi đóng gói ISO. Mã lỗi: $($Proc.ExitCode)"
             [System.Windows.Forms.MessageBox]::Show("Lỗi build ISO. Có thể thiếu file boot trong ISO gốc.", "Error")
        }
        
        # Cleanup ISO Goc
        Dismount-DiskImage -ImagePath $TxtIsoSrc.Text -ErrorAction SilentlyContinue | Out-Null
        $GbStep2.Enabled=$false; $BtnBuildIso.Enabled=$false
        $LblMountInfo.Text="TRẠNG THÁI: HOÀN TẤT."
        $Form.Cursor = "Default"
    }
})

$Form.FormClosing.Add_Method({ 
    Dismount-DiskImage -ImagePath $TxtIsoSrc.Text -ErrorAction SilentlyContinue | Out-Null
    Start-Process "dism" -ArgumentList "/Unmount-Image /MountDir:`"$Global:MountDir`" /Discard" -Wait -NoNewWindow -ErrorAction SilentlyContinue
})

$Form.ShowDialog() | Out-Null
