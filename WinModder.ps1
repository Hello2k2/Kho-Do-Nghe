<#
    WINDOWS MODDER STUDIO - PHAT TAN PC
    Version: 2.5 (Drive Selector + CD-ROM Filter + Fix Error 267)
#>

# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# Fix TLS
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# =========================================================================================
# GLOBAL VARIABLES
# =========================================================================================
$ToolsDir = "$env:TEMP\PhatTan_Tools"
# Các biến khác sẽ được cập nhật khi người dùng chọn ổ đĩa

# --- HÀM LOGGING ---
function Log ($Box, $Msg, $Type="INFO") {
    $Time = [DateTime]::Now.ToString('HH:mm:ss')
    $Color = "Lime"
    if ($Type -eq "ERR") { $Color = "Red" }
    if ($Type -eq "WARN") { $Color = "Yellow" }
    if ($Type -eq "CMD") { $Color = "Cyan" }
    
    $Box.AppendText("[$Time] [$Type] $Msg`r`n")
    $Box.ScrollToCaret()
    $StatusLbl.Text = "Status: $Msg"
    [System.Windows.Forms.Application]::DoEvents()
}

# --- HÀM CẤP QUYỀN (FIX 267) ---
function Grant-FullAccess ($Path) {
    if (Test-Path $Path) {
        Start-Process "icacls" -ArgumentList "`"$Path`" /grant Everyone:F /T /C /Q" -Wait -NoNewWindow
    }
}

# --- HÀM CẬP NHẬT WORKSPACE KHI CHỌN Ổ ĐĨA ---
function Update-Workspace {
    # Lấy ổ đĩa từ ComboBox (VD: "C:")
    $SelDrive = $CboDrives.SelectedItem.ToString().Split(" ")[0]
    
    $Global:WorkDir     = "$SelDrive\WinMod_Temp"
    $Global:MountDir    = "$Global:WorkDir\Mount"
    $Global:ExtractDir  = "$Global:WorkDir\Source"
    $Global:CaptureDir  = "$Global:WorkDir\Capture"
    $Global:ScratchDir  = "$Global:WorkDir\Scratch"
    
    $LblWorkDir.Text = "Thư mục làm việc hiện tại: $Global:WorkDir"
}

# --- HÀM CHUẨN BỊ FOLDER ---
function Prepare-Dirs {
    if (!(Test-Path $Global:WorkDir)) { New-Item -ItemType Directory -Path $Global:WorkDir -Force | Out-Null }
    if (!(Test-Path $Global:ScratchDir)) { New-Item -ItemType Directory -Path $Global:ScratchDir -Force | Out-Null }
    if (!(Test-Path $Global:CaptureDir)) { New-Item -ItemType Directory -Path $Global:CaptureDir -Force | Out-Null }
    Grant-FullAccess $Global:WorkDir
}

# =========================================================================================
# GUI SETUP
# =========================================================================================
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WINDOWS MODDER STUDIO V2.5 (DRIVE SELECTOR)"
$Form.Size = New-Object System.Drawing.Size(950, 720)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 35)
$Form.ForeColor = "WhiteSmoke"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header Panel
$PanelTop = New-Object System.Windows.Forms.Panel; $PanelTop.Dock="Top"; $PanelTop.Height=80; $PanelTop.BackColor=[System.Drawing.Color]::FromArgb(45,45,50); $Form.Controls.Add($PanelTop)

$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "PHAT TAN PC - SYSTEM BUILDER"; $LblT.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold); $LblT.ForeColor = "Gold"; $LblT.AutoSize = $true; $LblT.Location = "20,10"; $PanelTop.Controls.Add($LblT)

# --- DRIVE SELECTOR (QUAN TRỌNG) ---
$LblSel = New-Object System.Windows.Forms.Label; $LblSel.Text = "Chọn ổ đĩa làm bộ nhớ đệm (Workspace):"; $LblSel.Location = "20, 50"; $LblSel.AutoSize=$true; $PanelTop.Controls.Add($LblSel)

$CboDrives = New-Object System.Windows.Forms.ComboBox; $CboDrives.Location = "270, 48"; $CboDrives.Size = "200, 25"; $CboDrives.DropDownStyle = "DropDownList"; $PanelTop.Controls.Add($CboDrives)

# Logic lấy danh sách ổ cứng (LOẠI BỎ Ổ CD)
$Drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } # Type 3 = HDD/SSD Fixed
foreach ($D in $Drives) {
    $FreeSpace = [Math]::Round($D.FreeSpace / 1GB, 1)
    $CboDrives.Items.Add("$($D.DeviceID) (Trống: $FreeSpace GB)") | Out-Null
}
if ($CboDrives.Items.Count -gt 0) { $CboDrives.SelectedIndex = 0 } # Chọn ổ đầu tiên mặc định
$CboDrives.Add_SelectedIndexChanged({ Update-Workspace })

$LblWorkDir = New-Object System.Windows.Forms.Label; $LblWorkDir.Text = "..."; $LblWorkDir.Location = "490, 50"; $LblWorkDir.AutoSize=$true; $LblWorkDir.ForeColor="Lime"; $PanelTop.Controls.Add($LblWorkDir)

# Status Strip
$StatusStrip = New-Object System.Windows.Forms.StatusStrip; $StatusStrip.BackColor="Black"
$StatusLbl = New-Object System.Windows.Forms.ToolStripStatusLabel; $StatusLbl.Text = "Ready."; $StatusLbl.ForeColor="Cyan"; $StatusStrip.Items.Add($StatusLbl) | Out-Null
$Form.Controls.Add($StatusStrip)

# Tabs
$Tabs = New-Object System.Windows.Forms.TabControl; $Tabs.Location = "20,100"; $Tabs.Size = "895,550"; $Tabs.Appearance = "FlatButtons"; $Form.Controls.Add($Tabs)
function Make-Tab ($T) { $P = New-Object System.Windows.Forms.TabPage; $P.Text = "  $T  "; $P.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 35); $Tabs.Controls.Add($P); return $P }

$TabCap = Make-Tab "1. CAPTURE OS"
$TabMod = Make-Tab "2. MODDING ISO"

# --- TAB 1: CAPTURE ---
$GbCap = New-Object System.Windows.Forms.GroupBox; $GbCap.Text="CAPTURE WINDOWS (Tạo install.wim từ ổ C)"; $GbCap.Location="20,20"; $GbCap.Size="845,470"; $GbCap.ForeColor="Cyan"; $TabCap.Controls.Add($GbCap)

$LblC1 = New-Object System.Windows.Forms.Label; $LblC1.Text="Nơi lưu file WIM/ISO thành phẩm:"; $LblC1.Location="30,40"; $LblC1.AutoSize=$true; $GbCap.Controls.Add($LblC1)
$TxtCapOut = New-Object System.Windows.Forms.TextBox; $TxtCapOut.Location="30,65"; $TxtCapOut.Size="650,25"; $TxtCapOut.Text="C:\PhatTan_Backup.wim"; $GbCap.Controls.Add($TxtCapOut)
$BtnCapBrowse = New-Object System.Windows.Forms.Button; $BtnCapBrowse.Text="CHỌN..."; $BtnCapBrowse.Location="700,63"; $BtnCapBrowse.Size="100,27"; $BtnCapBrowse.ForeColor="Black"; $GbCap.Controls.Add($BtnCapBrowse)

$BtnStartCap = New-Object System.Windows.Forms.Button; $BtnStartCap.Text="BẮT ĐẦU CAPTURE (START)"; $BtnStartCap.Location="30,110"; $BtnStartCap.Size="770,50"; $BtnStartCap.BackColor="OrangeRed"; $BtnStartCap.ForeColor="White"; $BtnStartCap.Font="Segoe UI, 11, Bold"; $GbCap.Controls.Add($BtnStartCap)

$TxtLogCap = New-Object System.Windows.Forms.TextBox; $TxtLogCap.Multiline=$true; $TxtLogCap.Location="30,180"; $TxtLogCap.Size="770,260"; $TxtLogCap.BackColor="Black"; $TxtLogCap.ForeColor="Lime"; $TxtLogCap.ScrollBars="Vertical"; $TxtLogCap.ReadOnly=$true; $TxtLogCap.Font="Consolas, 9"; $GbCap.Controls.Add($TxtLogCap)

# --- TAB 2: MODDING ---
$GbSrc = New-Object System.Windows.Forms.GroupBox; $GbSrc.Text="SOURCE ISO"; $GbSrc.Location="20,20"; $GbSrc.Size="845,80"; $GbSrc.ForeColor="Yellow"; $TabMod.Controls.Add($GbSrc)
$TxtIsoSrc = New-Object System.Windows.Forms.TextBox; $TxtIsoSrc.Location="20,35"; $TxtIsoSrc.Size="650,25"; $GbSrc.Controls.Add($TxtIsoSrc)
$BtnIsoSrc = New-Object System.Windows.Forms.Button; $BtnIsoSrc.Text="MỞ ISO"; $BtnIsoSrc.Location="690,33"; $BtnIsoSrc.Size="120,27"; $BtnIsoSrc.ForeColor="Black"; $GbSrc.Controls.Add($BtnIsoSrc)

$GbAct = New-Object System.Windows.Forms.GroupBox; $GbAct.Text="MENU EDIT"; $GbAct.Location="20,110"; $GbAct.Size="845,300"; $GbAct.ForeColor="Lime"; $GbAct.Enabled=$false; $TabMod.Controls.Add($GbAct)

function Add-Btn ($T, $X, $Y, $C, $Fn) { $b=New-Object System.Windows.Forms.Button; $b.Text=$T; $b.Location="$X,$Y"; $b.Size="250,40"; $b.BackColor=$C; $b.ForeColor="Black"; $b.FlatStyle="Flat"; $b.Add_Click($Fn); $GbAct.Controls.Add($b) }

Add-Btn "1. MOUNT ISO" 30 30 "Cyan" { Start-Mount }
Add-Btn "2. ADD FOLDER" 30 80 "White" { Add-Folder }
Add-Btn "3. ADD DRIVERS" 30 130 "White" { Add-Driver }
Add-Btn "4. ADD DESKTOP FILE" 30 180 "White" { Add-DesktopFile }
Add-Btn "DỌN DẸP LỖI" 560 30 "Red" { Force-Cleanup }

$LblInfo = New-Object System.Windows.Forms.Label; $LblInfo.Text="STATUS: UNMOUNTED"; $LblInfo.Location="300,40"; $LblInfo.AutoSize=$true; $LblInfo.Font="Segoe UI, 10, Bold"; $GbAct.Controls.Add($LblInfo)
$TxtLogMod = New-Object System.Windows.Forms.TextBox; $TxtLogMod.Multiline=$true; $TxtLogMod.Location="300,80"; $TxtLogMod.Size="510,200"; $TxtLogMod.BackColor="Black"; $TxtLogMod.ForeColor="Cyan"; $TxtLogMod.ScrollBars="Vertical"; $TxtLogMod.ReadOnly=$true; $TxtLogMod.Font="Consolas, 9"; $GbAct.Controls.Add($TxtLogMod)
$BtnBuild = New-Object System.Windows.Forms.Button; $BtnBuild.Text="3. TẠO ISO MỚI (REBUILD)"; $BtnBuild.Location="20,420"; $BtnBuild.Size="845,60"; $BtnBuild.BackColor="Green"; $BtnBuild.ForeColor="White"; $BtnBuild.Font="Segoe UI, 14, Bold"; $BtnBuild.Enabled=$false; $TabMod.Controls.Add($BtnBuild)

# =========================================================================================
# LOGIC CORE
# =========================================================================================

# --- TOOL CHECKER ---
function Check-Tools {
    $OscTarget = "$ToolsDir\oscdimg.exe"
    if (Test-Path $OscTarget) { return $true }
    
    Log $TxtLogMod "Đang tìm kiếm Tool..."
    try {
        if (!(Test-Path $ToolsDir)) { New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null }
        $Url = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/refs/heads/main/oscdimg.exe"
        (New-Object System.Net.WebClient).DownloadFile($Url, $OscTarget)
        if ((Get-Item $OscTarget).Length -gt 100kb) { return $true }
    } catch {}

    $Msg = "Không tìm thấy 'oscdimg.exe'. Bạn có muốn Tool tự tải ADK không?"
    if ([System.Windows.Forms.MessageBox]::Show($Msg, "Missing Tool", "YesNo") -eq "Yes") {
        try {
            $Installer = "$env:TEMP\adksetup.exe"
            Log $TxtLogMod "Đang tải ADK (chờ xíu)..."
            (New-Object System.Net.WebClient).DownloadFile("https://go.microsoft.com/fwlink/?linkid=2243390", $Installer)
            Log $TxtLogMod "Đang cài đặt ADK..."
            Start-Process $Installer -ArgumentList "/quiet /norestart /features OptionId.DeploymentTools" -Wait
            return $true
        } catch { Log $TxtLogMod "Lỗi tải ADK: $($_.Exception.Message)" "ERR"; return $false }
    }
    return $false
}

# --- CAPTURE LOGIC ---
$BtnCapBrowse.Add_Click({ $S=New-Object System.Windows.Forms.SaveFileDialog; $S.Filter="WIM File|*.wim"; $S.FileName="install.wim"; if($S.ShowDialog()-eq"OK"){$TxtCapOut.Text=$S.FileName} })

$BtnStartCap.Add_Click({
    if (!(Check-Tools)) { return }
    Update-Workspace # Đảm bảo cập nhật theo ổ đĩa đang chọn
    Prepare-Dirs
    
    $WimTarget = $TxtCapOut.Text
    
    $BtnStartCap.Enabled=$false; $Form.Cursor="WaitCursor"
    Log $TxtLogCap "Bắt đầu Capture ổ C..." "INFO"
    Log $TxtLogCap "Temp Workspace: $Global:ScratchDir" "WARN"
    
    # Lệnh Capture
    $Proc = Start-Process "dism" -ArgumentList "/Capture-Image /ImageFile:`"$WimTarget`" /CaptureDir:C:\ /Name:`"MyWindows`" /Compress:max /ScratchDir:`"$Global:ScratchDir`"" -Wait -NoNewWindow -PassThru
    
    if ($Proc.ExitCode -eq 0) { 
        Log $TxtLogCap "Capture THÀNH CÔNG! File tại: $WimTarget" "INFO"
        [System.Windows.Forms.MessageBox]::Show("Capture xong! Bạn có thể dùng file WIM này để tạo ISO ở Tab 2.")
    } else { 
        Log $TxtLogCap "Lỗi Capture (Code $($Proc.ExitCode))." "ERR"
        Log $TxtLogCap "Gợi ý: Tắt Defender, hoặc chọn ổ đĩa khác làm Workspace." "WARN"
    }
    
    $BtnStartCap.Enabled=$true; $Form.Cursor="Default"
})

# --- MODDING LOGIC ---
$BtnIsoSrc.Add_Click({ $O=New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="ISO|*.iso"; if($O.ShowDialog()-eq"OK"){$TxtIsoSrc.Text=$O.FileName; $GbAct.Enabled=$true} })

function Force-Cleanup {
    Log $TxtLogMod "Dọn dẹp file rác..."
    Start-Process "dism" -ArgumentList "/Cleanup-Mountpoints" -Wait -NoNewWindow
    Start-Process "dism" -ArgumentList "/Cleanup-Wim" -Wait -NoNewWindow
    if (Test-Path $Global:MountDir) {
        Start-Process "dism" -ArgumentList "/Unmount-Image /MountDir:`"$Global:MountDir`" /Discard" -Wait -NoNewWindow
        Remove-Item $Global:MountDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    Log $TxtLogMod "Đã dọn dẹp."
}

function Start-Mount {
    $Iso = $TxtIsoSrc.Text
    Update-Workspace
    Prepare-Dirs
    
    $Form.Cursor="WaitCursor"
    Force-Cleanup
    Ensure-Dir $Global:ExtractDir; Ensure-Dir $Global:MountDir
    Grant-FullAccess $Global:MountDir

    Log $TxtLogMod "Mounting ISO..."
    Mount-DiskImage -ImagePath $Iso -StorageType ISO -ErrorAction SilentlyContinue | Out-Null
    $Vol = Get-DiskImage -ImagePath $Iso | Get-Volume
    if (!$Vol) { Log $TxtLogMod "Lỗi đọc file ISO." "ERR"; $Form.Cursor="Default"; return }
    
    Log $TxtLogMod "Extracting files..."
    Copy-Item "$($Vol.DriveLetter):\*" $Global:ExtractDir -Recurse -Force
    
    $Wim = "$Global:ExtractDir\sources\install.wim"
    $Esd = "$Global:ExtractDir\sources\install.esd"

    if (!(Test-Path $Wim)) {
        if (Test-Path $Esd) {
            Log $TxtLogMod "ESD Detected. Converting to WIM..."
            Start-Process "dism" -ArgumentList "/Export-Image /SourceImageFile:`"$Esd`" /SourceIndex:1 /DestinationImageFile:`"$Wim`" /Compress:max /ScratchDir:`"$Global:ScratchDir`"" -Wait -NoNewWindow
            Remove-Item $Esd -Force
        } else { Log $TxtLogMod "Không tìm thấy install.wim!" "ERR"; $Form.Cursor="Default"; return }
    }

    Log $TxtLogMod "Mounting WIM..."
    $Proc = Start-Process "dism" -ArgumentList "/Mount-Image /ImageFile:`"$Wim`" /Index:1 /MountDir:`"$Global:MountDir`" /ScratchDir:`"$Global:ScratchDir`"" -Wait -NoNewWindow -PassThru
    
    if ($Proc.ExitCode -eq 0) {
        $LblInfo.Text="MOUNTED"; $LblInfo.ForeColor="Lime"; $BtnBuild.Enabled=$true
        Log $TxtLogMod "Mount thành công!" "INFO"
    } else {
        Log $TxtLogMod "Mount thất bại (Code $($Proc.ExitCode))." "ERR"
    }
    $Form.Cursor="Default"
}

function Add-Folder {
    $FBD = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($FBD.ShowDialog() -eq "OK") {
        Copy-Item $FBD.SelectedPath $Global:MountDir -Recurse -Force
        Log $TxtLogMod "Đã chép Folder: $($FBD.SelectedPath)"
    }
}
function Add-Driver {
    $FBD = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($FBD.ShowDialog() -eq "OK") {
        Log $TxtLogMod "Đang nạp Driver..."
        Start-Process "dism" -ArgumentList "/Image:`"$Global:MountDir`" /Add-Driver /Driver:`"$($FBD.SelectedPath)`" /Recurse /ScratchDir:`"$Global:ScratchDir`"" -Wait -NoNewWindow
        Log $TxtLogMod "Xong."
    }
}
function Add-DesktopFile {
    $O = New-Object System.Windows.Forms.OpenFileDialog
    if ($O.ShowDialog() -eq "OK") {
        Copy-Item $O.FileName "$Global:MountDir\Users\Public\Desktop" -Force
        Log $TxtLogMod "Đã thêm file ra Desktop."
    }
}

$BtnBuild.Add_Click({
    if (!(Check-Tools)) { return }
    $S = New-Object System.Windows.Forms.SaveFileDialog; $S.Filter="ISO|*.iso"; $S.FileName="NewWin.iso"
    if ($S.ShowDialog() -eq "OK") {
        $Form.Cursor="WaitCursor"
        Log $TxtLogMod "Unmounting..."
        Start-Process "dism" -ArgumentList "/Unmount-Image /MountDir:`"$Global:MountDir`" /Commit /ScratchDir:`"$Global:ScratchDir`"" -Wait -NoNewWindow
        
        Log $TxtLogMod "Building ISO..."
        $Osc = "$ToolsDir\oscdimg.exe"
        $Boot = "2#p0,e,b`"$Global:ExtractDir\boot\etfsboot.com`"#pEF,e,b`"$Global:ExtractDir\efi\microsoft\boot\efisys.bin`""
        Start-Process $Osc -ArgumentList "-bootdata:$Boot -u2 -udfver102 `"$Global:ExtractDir`" `"$S.FileName`"" -Wait -NoNewWindow
        
        Log $TxtLogMod "Hoàn tất! File tại: $($S.FileName)" "INFO"
        [System.Windows.Forms.MessageBox]::Show("Xong!"); Invoke-Item (Split-Path $S.FileName)
        $GbAct.Enabled=$false; $BtnBuild.Enabled=$false; $Form.Cursor="Default"
    }
})

# Khởi tạo Workspace mặc định
if ($CboDrives.Items.Count -gt 0) { Update-Workspace }

$Form.ShowDialog() | Out-Null
