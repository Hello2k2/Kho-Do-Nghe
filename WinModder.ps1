<#
    WINDOWS MODDER STUDIO - PHAT TAN PC
    Version: 2.3 (Final Stable: Auto-Drive Detect + Auto ADK Installer + Anti-Error 267)
#>

# --- 1. FORCE ADMIN & SECURITY ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# Bật TLS 1.2/1.3 để tải file từ GitHub/Microsoft không bị lỗi
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# =========================================================================================
# CẤU HÌNH THÔNG MINH (AUTO DETECT DRIVE)
# =========================================================================================

# 1. Tự động chọn ổ đĩa làm việc (Ưu tiên D: để tránh đầy ổ C)
if (Test-Path "D:\") {
    $WorkDir = "D:\PhatTan_WinModder"
} else {
    $WorkDir = "C:\PhatTan_WinModder"
}

# 2. Định nghĩa các đường dẫn
$Global:MountDir   = "$WorkDir\Mount"
$Global:ExtractDir = "$WorkDir\Extracted"
$Global:CaptureDir = "$WorkDir\Capture"
$ScratchDir        = "$WorkDir\Scratch"
$ToolsDir          = "$env:TEMP\PhatTan_Tools"

# 3. Hàm tạo thư mục an toàn
function Ensure-Dir ($Path) {
    if (!(Test-Path $Path)) { 
        New-Item -ItemType Directory -Path $Path -Force | Out-Null 
    }
}

# Khởi tạo ngay
Ensure-Dir $ToolsDir
Ensure-Dir $WorkDir
Ensure-Dir $ScratchDir

# =========================================================================================
# GUI SETUP
# =========================================================================================
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WINDOWS MODDER STUDIO V2.3 (AUTO ADK INSTALLER)"
$Form.Size = New-Object System.Drawing.Size(920, 680)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 25)
$Form.ForeColor = "WhiteSmoke"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$LblT = New-Object System.Windows.Forms.Label
$LblT.Text = "PHAT TAN PC - SYSTEM BUILDER"
$LblT.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$LblT.ForeColor = "Gold"
$LblT.AutoSize = $true
$LblT.Location = "20,15"
$Form.Controls.Add($LblT)

# Status Strip
$StatusStrip = New-Object System.Windows.Forms.StatusStrip
$StatusLbl = New-Object System.Windows.Forms.ToolStripStatusLabel
$StatusLbl.Text = "WorkDir: $WorkDir"
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

# --- TAB 1 GUI ---
$GbCap = New-Object System.Windows.Forms.GroupBox; $GbCap.Text="QUY TRÌNH ĐÓNG GÓI WINDOWS"; $GbCap.Location="20,20"; $GbCap.Size="820,450"; $GbCap.ForeColor="Cyan"; $TabCap.Controls.Add($GbCap)
$LblC1 = New-Object System.Windows.Forms.Label; $LblC1.Text="Lưu ý: Tắt Defender. Tool chụp toàn bộ ổ C: thành install.wim."; $LblC1.Location="30,40"; $LblC1.AutoSize=$true; $LblC1.ForeColor="LightGray"; $GbCap.Controls.Add($LblC1)
$LblC2 = New-Object System.Windows.Forms.Label; $LblC2.Text="Nơi lưu file ISO thành phẩm:"; $LblC2.Location="30,100"; $LblC2.AutoSize=$true; $GbCap.Controls.Add($LblC2)
$TxtCapOut = New-Object System.Windows.Forms.TextBox; $TxtCapOut.Location="30,125"; $TxtCapOut.Size="550,25"; $TxtCapOut.Text="D:\PhatTan_Backup.iso"; $GbCap.Controls.Add($TxtCapOut)
$BtnCapBrowse = New-Object System.Windows.Forms.Button; $BtnCapBrowse.Text="CHỌN..."; $BtnCapBrowse.Location="600,123"; $BtnCapBrowse.Size="100,27"; $BtnCapBrowse.ForeColor="Black"; $GbCap.Controls.Add($BtnCapBrowse)
$BtnStartCap = New-Object System.Windows.Forms.Button; $BtnStartCap.Text="BẮT ĐẦU CAPTURE & TẠO ISO"; $BtnStartCap.Location="30,180"; $BtnStartCap.Size="670,60"; $BtnStartCap.BackColor="OrangeRed"; $BtnStartCap.ForeColor="White"; $BtnStartCap.Font="Segoe UI, 12, Bold"; $GbCap.Controls.Add($BtnStartCap)
$TxtLogCap = New-Object System.Windows.Forms.TextBox; $TxtLogCap.Multiline=$true; $TxtLogCap.Location="30,260"; $TxtLogCap.Size="670,160"; $TxtLogCap.BackColor="Black"; $TxtLogCap.ForeColor="Lime"; $TxtLogCap.ScrollBars="Vertical"; $TxtLogCap.ReadOnly=$true; $GbCap.Controls.Add($TxtLogCap)

# --- TAB 2 GUI ---
$GbStep1 = New-Object System.Windows.Forms.GroupBox; $GbStep1.Text="BƯỚC 1: CHỌN FILE ISO GỐC"; $GbStep1.Location="20,20"; $GbStep1.Size="820,80"; $GbStep1.ForeColor="Yellow"; $TabMod.Controls.Add($GbStep1)
$TxtIsoSrc = New-Object System.Windows.Forms.TextBox; $TxtIsoSrc.Location="20,35"; $TxtIsoSrc.Size="600,25"; $GbStep1.Controls.Add($TxtIsoSrc)
$BtnIsoSrc = New-Object System.Windows.Forms.Button; $BtnIsoSrc.Text="MỞ FILE ISO"; $BtnIsoSrc.Location="640,33"; $BtnIsoSrc.Size="120,27"; $BtnIsoSrc.ForeColor="Black"; $GbStep1.Controls.Add($BtnIsoSrc)

$GbStep2 = New-Object System.Windows.Forms.GroupBox; $GbStep2.Text="BƯỚC 2: CAN THIỆP HỆ THỐNG"; $GbStep2.Location="20,110"; $GbStep2.Size="820,280"; $GbStep2.ForeColor="Lime"; $GbStep2.Enabled=$false; $TabMod.Controls.Add($GbStep2)

function Add-ModBtn ($T, $X, $Y, $Col, $Cmd) { 
    $b=New-Object System.Windows.Forms.Button; $b.Text=$T; $b.Location="$X,$Y"; $b.Size="230,45"; 
    $b.BackColor=$Col; $b.ForeColor="Black"; $b.FlatStyle="Flat"; $b.Add_Click($Cmd); $GbStep2.Controls.Add($b) 
}

Add-ModBtn "1. GIẢI NÉN & MOUNT" 30 40 "Cyan" { Start-Mount }
Add-ModBtn "2. THÊM FOLDER APP/DATA" 30 100 "White" { Add-Folder }
Add-ModBtn "3. THÊM DRIVER (FOLDER)" 290 100 "White" { Add-Driver }
Add-ModBtn "4. COPY FILE RA DESKTOP" 550 100 "White" { Add-DesktopFile }
Add-ModBtn "DỌN DẸP (RESET)" 550 40 "Red" { Force-Cleanup }

$LblMountInfo = New-Object System.Windows.Forms.Label; $LblMountInfo.Text="TRẠNG THÁI: CHƯA MOUNT"; $LblMountInfo.Location="290,55"; $LblMountInfo.AutoSize=$true; $LblMountInfo.Font="Segoe UI, 10, Bold"; $LblMountInfo.ForeColor="Gray"; $GbStep2.Controls.Add($LblMountInfo)
$TxtLogMod = New-Object System.Windows.Forms.TextBox; $TxtLogMod.Multiline=$true; $TxtLogMod.Location="30,160"; $TxtLogMod.Size="750,100"; $TxtLogMod.BackColor="Black"; $TxtLogMod.ForeColor="Cyan"; $TxtLogMod.ScrollBars="Vertical"; $TxtLogMod.ReadOnly=$true; $GbStep2.Controls.Add($TxtLogMod)

$BtnBuildIso = New-Object System.Windows.Forms.Button; $BtnBuildIso.Text="BƯỚC 3: ĐÓNG GÓI RA FILE ISO MỚI"; $BtnBuildIso.Location="20,410"; $BtnBuildIso.Size="820,60"; $BtnBuildIso.BackColor="Green"; $BtnBuildIso.ForeColor="White"; $BtnBuildIso.Font="Segoe UI, 14, Bold"; $BtnBuildIso.Enabled=$false; $TabMod.Controls.Add($BtnBuildIso)

# =========================================================================================
# LOGIC & FUNCTIONS
# =========================================================================================
function Set-Status ($Msg) { $StatusLbl.Text = $Msg; [System.Windows.Forms.Application]::DoEvents() }
function Log ($Box, $Msg) { 
    $Box.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $Msg`r`n"); $Box.ScrollToCaret(); Set-Status $Msg
}

# --- TOOL MANAGER (AUTO ADK INSTALLER) ---
function Check-Tools {
    $OscTarget = "$ToolsDir\oscdimg.exe"
    
    # 1. Kiểm tra tool có sẵn
    if (Test-Path $OscTarget) { return $true }

    # 2. Thử tải từ Server cá nhân (GitHub)
    Set-Status "Đang kiểm tra tool từ Server..."
    try {
        $Url = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/refs/heads/main/oscdimg.exe"
        (New-Object System.Net.WebClient).DownloadFile($Url, $OscTarget)
        if ((Get-Item $OscTarget).Length -gt 100kb) { return $true } 
    } catch {}

    # 3. Quét trong máy
    $AdkPaths = @(
        "$env:ProgramFiles(x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
        "$env:ProgramFiles\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
        "C:\Windows\System32\oscdimg.exe"
    )
    foreach ($P in $AdkPaths) { 
        if (Test-Path $P) { Copy-Item $P $OscTarget -Force; return $true } 
    }

    # 4. HỎI NGƯỜI DÙNG TỰ ĐỘNG CÀI ADK
    $Msg = "Không tìm thấy file tạo ISO (oscdimg.exe).`n`nBạn có muốn Tool TỰ ĐỘNG TẢI & CÀI ĐẶT Windows ADK không?`n(Tool sẽ tải từ Microsoft và tự cài đặt).`n`nChọn [NO] để trỏ file thủ công."
    $Ask = [System.Windows.Forms.MessageBox]::Show($Msg, "Thiếu Tool", "YesNoCancel", "Question")

    if ($Ask -eq "Yes") {
        try {
            $AdkInstaller = "$env:TEMP\adksetup.exe"
            Set-Status "Đang tải ADK Setup từ Microsoft..."
            (New-Object System.Net.WebClient).DownloadFile("https://go.microsoft.com/fwlink/?linkid=2243390", $AdkInstaller)
            
            Set-Status "Đang cài đặt ADK (Vui lòng đợi 3-5 phút)..."
            $Proc = Start-Process -FilePath $AdkInstaller -ArgumentList "/quiet /norestart /features OptionId.DeploymentTools" -Wait -PassThru
            
            Set-Status "Cài đặt xong. Đang kiểm tra lại..."
            foreach ($P in $AdkPaths) { 
                if (Test-Path $P) { Copy-Item $P $OscTarget -Force; Set-Status "Đã lấy được Tool!"; return $true } 
            }
            [System.Windows.Forms.MessageBox]::Show("Đã cài đặt xong nhưng vẫn không thấy file. Vui lòng khởi động lại Tool.", "Thông báo")
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Lỗi tải/cài ADK: $($_.Exception.Message)", "Lỗi")
        }
    } 
    elseif ($Ask -eq "No") {
        $O = New-Object System.Windows.Forms.OpenFileDialog; $O.Filter = "Oscdimg|oscdimg.exe"
        if ($O.ShowDialog() -eq "OK") { Copy-Item $O.FileName $OscTarget -Force; return $true }
    }

    return $false
}

# --- TAB 1 LOGIC ---
$BtnCapBrowse.Add_Click({
    $S = New-Object System.Windows.Forms.SaveFileDialog; $S.Filter="ISO File|*.iso"; $S.FileName="PhatTan_Backup.iso"
    if($S.ShowDialog() -eq "OK"){$TxtCapOut.Text=$S.FileName}
})
$BtnStartCap.Add_Click({
    if (!(Check-Tools)) { return }
    Ensure-Dir $ScratchDir; Ensure-Dir "$WorkDir\Capture"
    $WimFile = "$WorkDir\Capture\install.wim"
    
    $BtnStartCap.Enabled=$false; $Form.Cursor = "WaitCursor"
    Log $TxtLogCap ">>> ĐANG CAPTURE Ổ C:..."
    Start-Process "dism" -ArgumentList "/Capture-Image /ImageFile:`"$WimFile`" /CaptureDir:C:\ /Name:`"Phat Tan Windows`" /Compress:max /ScratchDir:`"$ScratchDir`"" -Wait -NoNewWindow
    if (Test-Path $WimFile) {
        Log $TxtLogCap " [OK] Capture xong. File WIM tại: $WimFile"
        [System.Windows.Forms.MessageBox]::Show("Đã tạo xong install.wim! Giờ bạn có thể dùng Tab 2 để tạo ISO.", "Thành công")
    } else { Log $TxtLogCap " [ERR] Capture thất bại." }
    $BtnStartCap.Enabled=$true; $Form.Cursor = "Default"
})

# --- TAB 2 LOGIC ---
$BtnIsoSrc.Add_Click({
    $O = New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="ISO File|*.iso"
    if($O.ShowDialog() -eq "OK"){$TxtIsoSrc.Text=$O.FileName; $GbStep2.Enabled=$true}
})

function Force-Cleanup {
    Log $TxtLogMod ">>> Dọn dẹp Mount cũ..."
    Start-Process "dism" -ArgumentList "/Cleanup-Mountpoints" -Wait -NoNewWindow
    Start-Process "dism" -ArgumentList "/Cleanup-Wim" -Wait -NoNewWindow
    if (Test-Path $Global:MountDir) { 
        Start-Process "dism" -ArgumentList "/Unmount-Image /MountDir:`"$Global:MountDir`" /Discard" -Wait -NoNewWindow -ErrorAction SilentlyContinue 
        Remove-Item $Global:MountDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    Log $TxtLogMod " [OK] Đã dọn dẹp."
}

function Start-Mount {
    $Iso = $TxtIsoSrc.Text
    if (!(Test-Path $Iso)) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn ISO!"); return }

    $Form.Cursor = "WaitCursor"
    Force-Cleanup
    Ensure-Dir $Global:ExtractDir; Ensure-Dir $Global:MountDir; Ensure-Dir $ScratchDir
    
    if (!(Test-Path $Global:MountDir)) {
        $Form.Cursor = "Default"; [System.Windows.Forms.MessageBox]::Show("Lỗi 267: Không tạo được thư mục Mount tại $Global:MountDir", "Fatal"); return
    }

    Log $TxtLogMod ">>> Extract ISO..."
    Mount-DiskImage -ImagePath $Iso -StorageType ISO -ErrorAction SilentlyContinue | Out-Null
    $Vol = Get-DiskImage -ImagePath $Iso | Get-Volume
    if (!$Vol) { Log $TxtLogMod " [ERR] Lỗi Mount ISO ảo."; $Form.Cursor="Default"; return }
    Copy-Item "$($Vol.DriveLetter):\*" $Global:ExtractDir -Recurse -Force

    $Wim = "$Global:ExtractDir\sources\install.wim"
    $Esd = "$Global:ExtractDir\sources\install.esd"
    
    if (!(Test-Path $Wim)) { 
        if (Test-Path $Esd) { 
            Log $TxtLogMod "Phát hiện ESD. Convert sang WIM..."
            Start-Process "dism" -ArgumentList "/Export-Image /SourceImageFile:`"$Esd`" /SourceIndex:1 /DestinationImageFile:`"$Wim`" /Compress:max /ScratchDir:`"$ScratchDir`"" -Wait -NoNewWindow
            Remove-Item $Esd -Force
        } else { $Form.Cursor="Default"; Log $TxtLogMod " [ERR] Không tìm thấy file install.wim/esd"; return }
    }

    Log $TxtLogMod ">>> Mounting WIM..."
    $Proc = Start-Process "dism" -ArgumentList "/Mount-Image /ImageFile:`"$Wim`" /Index:1 /MountDir:`"$Global:MountDir`" /ScratchDir:`"$ScratchDir`"" -Wait -NoNewWindow -PassThru
    
    if ($Proc.ExitCode -eq 0) {
        $LblMountInfo.Text="ĐÃ MOUNT"; $LblMountInfo.ForeColor="Lime"; $BtnBuildIso.Enabled=$true
        Log $TxtLogMod " [OK] Mount thành công!"
    } else {
        Log $TxtLogMod " [FAIL] Mount thất bại. Code: $($Proc.ExitCode)"
    }
    $Form.Cursor = "Default"
}

function Add-Folder {
    $FBD = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($FBD.ShowDialog() -eq "OK") {
        Copy-Item $FBD.SelectedPath "$Global:MountDir" -Recurse -Force
        Log $TxtLogMod "Copied Folder: $($FBD.SelectedPath)"
    }
}

function Add-Driver {
    $FBD = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($FBD.ShowDialog() -eq "OK") {
        $Form.Cursor="WaitCursor"; Log $TxtLogMod "Injecting Drivers..."
        Start-Process "dism" -ArgumentList "/Image:`"$Global:MountDir`" /Add-Driver /Driver:`"$($FBD.SelectedPath)`" /Recurse /ScratchDir:`"$ScratchDir`"" -Wait -NoNewWindow
        Log $TxtLogMod "Drivers Injected."; $Form.Cursor="Default"
    }
}

function Add-DesktopFile {
    $O = New-Object System.Windows.Forms.OpenFileDialog
    if ($O.ShowDialog() -eq "OK") {
        Copy-Item $O.FileName "$Global:MountDir\Users\Public\Desktop" -Force
        Log $TxtLogMod "File copied to Desktop."
    }
}

$BtnBuildIso.Add_Click({
    if (!(Check-Tools)) { return }
    $S = New-Object System.Windows.Forms.SaveFileDialog; $S.Filter="ISO File|*.iso"; $S.FileName="New_Windows.iso"
    if ($S.ShowDialog() -eq "OK") {
        $IsoOut = $S.FileName; $Osc = "$ToolsDir\oscdimg.exe"
        $Form.Cursor="WaitCursor"
        
        Log $TxtLogMod ">>> Unmounting & Saving..."
        Start-Process "dism" -ArgumentList "/Unmount-Image /MountDir:`"$Global:MountDir`" /Commit /ScratchDir:`"$ScratchDir`"" -Wait -NoNewWindow
        
        Log $TxtLogMod ">>> Building ISO with Oscdimg..."
        $BootData = "2#p0,e,b`"$Global:ExtractDir\boot\etfsboot.com`"#pEF,e,b`"$Global:ExtractDir\efi\microsoft\boot\efisys.bin`""
        Start-Process $Osc -ArgumentList "-bootdata:$BootData -u2 -udfver102 `"$Global:ExtractDir`" `"$IsoOut`"" -Wait -NoNewWindow
        
        Dismount-DiskImage -ImagePath $TxtIsoSrc.Text -ErrorAction SilentlyContinue | Out-Null
        $GbStep2.Enabled=$false; $BtnBuildIso.Enabled=$false
        $LblMountInfo.Text="HOÀN TẤT"; $Form.Cursor="Default"
        [System.Windows.Forms.MessageBox]::Show("Tạo ISO thành công!`nFile: $IsoOut")
        Invoke-Item (Split-Path $IsoOut)
    }
})

$Form.FormClosing.Add_Method({ 
    Dismount-DiskImage -ImagePath $TxtIsoSrc.Text -ErrorAction SilentlyContinue | Out-Null
    Start-Process "dism" -ArgumentList "/Unmount-Image /MountDir:`"$Global:MountDir`" /Discard" -Wait -NoNewWindow -ErrorAction SilentlyContinue
})

$Form.ShowDialog() | Out-Null
