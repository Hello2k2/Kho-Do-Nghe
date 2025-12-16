<#
    WINDOWS MODDER STUDIO - PHAT TAN PC
    Version: 2.4 (Ultimate Debug: Auto ACL Fix + Deep Logging + Disk Check)
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
# CẤU HÌNH HỆ THỐNG & LOGIC AN TOÀN
# =========================================================================================

# Chọn ổ đĩa: Ưu tiên D: (Data), nếu không có dùng C: (System)
# Sử dụng đường dẫn NGẮN GỌN, KHÔNG DẤU để tránh lỗi 267
if (Test-Path "D:\") { $RootDrive = "D:" } else { $RootDrive = "C:" }

$WorkDir       = "$RootDrive\WinMod_Temp"  # Đường dẫn ngắn nhất có thể
$Global:MountDir   = "$WorkDir\Mount"
$Global:ExtractDir = "$WorkDir\Source"
$ScratchDir        = "$WorkDir\Scratch"     # Thư mục tạm quan trọng
$ToolsDir          = "$env:TEMP\PhatTan_Tools"

# --- HÀM LOGGING CAO CẤP ---
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

# --- HÀM CẤP QUYỀN (FIX LỖI 267 QUAN TRỌNG NHẤT) ---
function Grant-FullAccess ($Path) {
    if (Test-Path $Path) {
        # Dùng ICACLS để ép quyền Everyone Full Control
        Start-Process "icacls" -ArgumentList "`"$Path`" /grant Everyone:F /T /C /Q" -Wait -NoNewWindow
    }
}

# --- HÀM CHUẨN BỊ THƯ MỤC ---
function Prepare-Workspace {
    param($Box)
    
    # 1. Kiểm tra dung lượng trống (Cần > 15GB)
    $Disk = Get-Volume -DriveLetter $RootDrive.Substring(0,1)
    if ($Disk.SizeRemaining -lt 15GB) {
        Log $Box "CẢNH BÁO: Ổ $RootDrive chỉ còn $([Math]::Round($Disk.SizeRemaining/1GB, 2)) GB. Dễ gây lỗi 267/112!" "WARN"
        if ([System.Windows.Forms.MessageBox]::Show("Ổ đĩa sắp đầy (<15GB). Tiếp tục dễ bị lỗi. Bạn có muốn liều không?", "Cảnh báo Disk", "YesNo", "Warning") -eq "No") { return $false }
    }

    # 2. Tạo thư mục
    if (!(Test-Path $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null }
    if (!(Test-Path $ScratchDir)) { New-Item -ItemType Directory -Path $ScratchDir -Force | Out-Null }
    
    # 3. Fix quyền ngay lập tức
    Grant-FullAccess $WorkDir
    
    Log $Box "Workspace: $WorkDir (Free: $([Math]::Round($Disk.SizeRemaining/1GB, 2)) GB)" "INFO"
    return $true
}

Prepare-Workspace $null # Chạy ngầm lần đầu

# =========================================================================================
# GUI SETUP (GIAO DIỆN XỊN HƠN)
# =========================================================================================
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WINDOWS MODDER STUDIO V2.4 (ULTIMATE DEBUG)"
$Form.Size = New-Object System.Drawing.Size(950, 700)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 35)
$Form.ForeColor = "WhiteSmoke"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$PanelTop = New-Object System.Windows.Forms.Panel; $PanelTop.Dock="Top"; $PanelTop.Height=60; $PanelTop.BackColor=[System.Drawing.Color]::FromArgb(45,45,50); $Form.Controls.Add($PanelTop)
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "PHAT TAN PC - SYSTEM BUILDER"; $LblT.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold); $LblT.ForeColor = "Gold"; $LblT.AutoSize = $true; $LblT.Location = "20,15"; $PanelTop.Controls.Add($LblT)
$LblVer = New-Object System.Windows.Forms.Label; $LblVer.Text = "v2.4 Stable"; $LblVer.ForeColor="Gray"; $LblVer.Location="350,22"; $PanelTop.Controls.Add($LblVer)

# Status Strip
$StatusStrip = New-Object System.Windows.Forms.StatusStrip; $StatusStrip.BackColor="Black"
$StatusLbl = New-Object System.Windows.Forms.ToolStripStatusLabel; $StatusLbl.Text = "Ready."; $StatusLbl.ForeColor="Lime"; $StatusStrip.Items.Add($StatusLbl) | Out-Null
$Form.Controls.Add($StatusStrip)

# Tabs
$Tabs = New-Object System.Windows.Forms.TabControl; $Tabs.Location = "20,80"; $Tabs.Size = "895,550"; $Tabs.Appearance = "FlatButtons"; $Form.Controls.Add($Tabs)
function Make-Tab ($T) { $P = New-Object System.Windows.Forms.TabPage; $P.Text = "  $T  "; $P.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 35); $Tabs.Controls.Add($P); return $P }

$TabCap = Make-Tab "1. CAPTURE OS"
$TabMod = Make-Tab "2. MODDING ISO"

# --- TAB 1: CAPTURE ---
$GbCap = New-Object System.Windows.Forms.GroupBox; $GbCap.Text="CAPTURE WINDOWS"; $GbCap.Location="20,20"; $GbCap.Size="845,470"; $GbCap.ForeColor="Cyan"; $TabCap.Controls.Add($GbCap)

$LblC1 = New-Object System.Windows.Forms.Label; $LblC1.Text="Output ISO Path:"; $LblC1.Location="30,40"; $LblC1.AutoSize=$true; $GbCap.Controls.Add($LblC1)
$TxtCapOut = New-Object System.Windows.Forms.TextBox; $TxtCapOut.Location="30,65"; $TxtCapOut.Size="650,25"; $TxtCapOut.Text="D:\MyWindows.iso"; $GbCap.Controls.Add($TxtCapOut)
$BtnCapBrowse = New-Object System.Windows.Forms.Button; $BtnCapBrowse.Text="BROWSE"; $BtnCapBrowse.Location="700,63"; $BtnCapBrowse.Size="100,27"; $BtnCapBrowse.ForeColor="Black"; $GbCap.Controls.Add($BtnCapBrowse)

$BtnStartCap = New-Object System.Windows.Forms.Button; $BtnStartCap.Text="START CAPTURE (C: -> WIM -> ISO)"; $BtnStartCap.Location="30,110"; $BtnStartCap.Size="770,50"; $BtnStartCap.BackColor="OrangeRed"; $BtnStartCap.ForeColor="White"; $BtnStartCap.Font="Segoe UI, 11, Bold"; $GbCap.Controls.Add($BtnStartCap)

$TxtLogCap = New-Object System.Windows.Forms.TextBox; $TxtLogCap.Multiline=$true; $TxtLogCap.Location="30,180"; $TxtLogCap.Size="770,260"; $TxtLogCap.BackColor="Black"; $TxtLogCap.ForeColor="Lime"; $TxtLogCap.ScrollBars="Vertical"; $TxtLogCap.ReadOnly=$true; $TxtLogCap.Font="Consolas, 9"; $GbCap.Controls.Add($TxtLogCap)

# --- TAB 2: MODDING ---
$GbSrc = New-Object System.Windows.Forms.GroupBox; $GbSrc.Text="SOURCE ISO"; $GbSrc.Location="20,20"; $GbSrc.Size="845,80"; $GbSrc.ForeColor="Yellow"; $TabMod.Controls.Add($GbSrc)
$TxtIsoSrc = New-Object System.Windows.Forms.TextBox; $TxtIsoSrc.Location="20,35"; $TxtIsoSrc.Size="650,25"; $GbSrc.Controls.Add($TxtIsoSrc)
$BtnIsoSrc = New-Object System.Windows.Forms.Button; $BtnIsoSrc.Text="OPEN ISO"; $BtnIsoSrc.Location="690,33"; $BtnIsoSrc.Size="120,27"; $BtnIsoSrc.ForeColor="Black"; $GbSrc.Controls.Add($BtnIsoSrc)

$GbAct = New-Object System.Windows.Forms.GroupBox; $GbAct.Text="ACTIONS"; $GbAct.Location="20,110"; $GbAct.Size="845,300"; $GbAct.ForeColor="Lime"; $GbAct.Enabled=$false; $TabMod.Controls.Add($GbAct)

function Add-Btn ($T, $X, $Y, $C, $Fn) { $b=New-Object System.Windows.Forms.Button; $b.Text=$T; $b.Location="$X,$Y"; $b.Size="250,40"; $b.BackColor=$C; $b.ForeColor="Black"; $b.FlatStyle="Flat"; $b.Add_Click($Fn); $GbAct.Controls.Add($b) }

Add-Btn "1. MOUNT ISO (AUTO FIX)" 30 30 "Cyan" { Start-Mount }
Add-Btn "2. ADD FOLDER (Data/App)" 30 80 "White" { Add-Folder }
Add-Btn "3. ADD DRIVERS (Inf)" 30 130 "White" { Add-Driver }
Add-Btn "4. ADD DESKTOP FILE" 30 180 "White" { Add-DesktopFile }

Add-Btn "CLEANUP / RESET" 560 30 "Red" { Force-Cleanup }
$LblInfo = New-Object System.Windows.Forms.Label; $LblInfo.Text="STATUS: UNMOUNTED"; $LblInfo.Location="300,40"; $LblInfo.AutoSize=$true; $LblInfo.Font="Segoe UI, 10, Bold"; $GbAct.Controls.Add($LblInfo)

$TxtLogMod = New-Object System.Windows.Forms.TextBox; $TxtLogMod.Multiline=$true; $TxtLogMod.Location="300,80"; $TxtLogMod.Size="510,200"; $TxtLogMod.BackColor="Black"; $TxtLogMod.ForeColor="Cyan"; $TxtLogMod.ScrollBars="Vertical"; $TxtLogMod.ReadOnly=$true; $TxtLogMod.Font="Consolas, 9"; $GbAct.Controls.Add($TxtLogMod)

$BtnBuild = New-Object System.Windows.Forms.Button; $BtnBuild.Text="3. REBUILD & CREATE ISO"; $BtnBuild.Location="20,420"; $BtnBuild.Size="845,60"; $BtnBuild.BackColor="Green"; $BtnBuild.ForeColor="White"; $BtnBuild.Font="Segoe UI, 14, Bold"; $BtnBuild.Enabled=$false; $TabMod.Controls.Add($BtnBuild)

# =========================================================================================
# LOGIC CORE
# =========================================================================================

# --- TOOL CHECKER ---
function Check-Tools {
    $OscTarget = "$ToolsDir\oscdimg.exe"
    if (Test-Path $OscTarget) { return $true }
    
    Log $TxtLogMod "Checking tools..."
    try {
        $Url = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/refs/heads/main/oscdimg.exe"
        (New-Object System.Net.WebClient).DownloadFile($Url, $OscTarget)
        if ((Get-Item $OscTarget).Length -gt 100kb) { return $true }
    } catch {}

    $Msg = "Thiếu Tool tạo ISO (oscdimg.exe).`nBạn có muốn tool tự tải và cài đặt ADK từ Microsoft không?"
    if ([System.Windows.Forms.MessageBox]::Show($Msg, "Missing Tool", "YesNo") -eq "Yes") {
        try {
            $Installer = "$env:TEMP\adksetup.exe"
            Log $TxtLogMod "Downloading ADK Installer..."
            (New-Object System.Net.WebClient).DownloadFile("https://go.microsoft.com/fwlink/?linkid=2243390", $Installer)
            Log $TxtLogMod "Installing ADK (Deployment Tools)..."
            Start-Process $Installer -ArgumentList "/quiet /norestart /features OptionId.DeploymentTools" -Wait
            return $true
        } catch { Log $TxtLogMod "Error installing ADK: $($_.Exception.Message)" "ERR"; return $false }
    }
    return $false
}

# --- CAPTURE ---
$BtnCapBrowse.Add_Click({ $S=New-Object System.Windows.Forms.SaveFileDialog; $S.Filter="ISO|*.iso"; if($S.ShowDialog()-eq"OK"){$TxtCapOut.Text=$S.FileName} })
$BtnStartCap.Add_Click({
    if(!(Prepare-Workspace $TxtLogCap)){return}
    if(!(Check-Tools)){return}
    
    $WimFile = "$WorkDir\Capture\install.wim"
    Ensure-Dir "$WorkDir\Capture"; Ensure-Dir $ScratchDir
    Grant-FullAccess $ScratchDir # FIX 267
    
    $BtnStartCap.Enabled=$false; $Form.Cursor="WaitCursor"
    Log $TxtLogCap "Starting Capture C:..." "INFO"
    Log $TxtLogCap "Command: dism /Capture-Image /ImageFile:$WimFile /CaptureDir:C:\ /ScratchDir:$ScratchDir" "CMD"
    
    $Proc = Start-Process "dism" -ArgumentList "/Capture-Image /ImageFile:`"$WimFile`" /CaptureDir:C:\ /Name:`"MyWin`" /Compress:max /ScratchDir:`"$ScratchDir`"" -Wait -NoNewWindow -PassThru
    
    if ($Proc.ExitCode -eq 0) { Log $TxtLogCap "Capture SUCCESS!" "INFO"; [System.Windows.Forms.MessageBox]::Show("Success!") }
    else { Log $TxtLogCap "Capture FAILED. Code: $($Proc.ExitCode)" "ERR" }
    
    $BtnStartCap.Enabled=$true; $Form.Cursor="Default"
})

# --- MODDING ---
$BtnIsoSrc.Add_Click({ $O=New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="ISO|*.iso"; if($O.ShowDialog()-eq"OK"){$TxtIsoSrc.Text=$O.FileName; $GbAct.Enabled=$true} })

function Force-Cleanup {
    Log $TxtLogMod "Cleaning up..."
    Start-Process "dism" -ArgumentList "/Cleanup-Mountpoints" -Wait -NoNewWindow
    Start-Process "dism" -ArgumentList "/Cleanup-Wim" -Wait -NoNewWindow
    if (Test-Path $Global:MountDir) {
        Start-Process "dism" -ArgumentList "/Unmount-Image /MountDir:`"$Global:MountDir`" /Discard" -Wait -NoNewWindow
        Remove-Item $Global:MountDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    Log $TxtLogMod "Cleaned."
}

function Start-Mount {
    $Iso = $TxtIsoSrc.Text
    if (!(Prepare-Workspace $TxtLogMod)) { return }
    
    $Form.Cursor="WaitCursor"
    Force-Cleanup
    Ensure-Dir $Global:ExtractDir; Ensure-Dir $Global:MountDir; Ensure-Dir $ScratchDir
    Grant-FullAccess $ScratchDir # FIX 267
    Grant-FullAccess $Global:MountDir # FIX 267

    Log $TxtLogMod "Mounting ISO Disk..."
    Mount-DiskImage -ImagePath $Iso -StorageType ISO -ErrorAction SilentlyContinue | Out-Null
    $Vol = Get-DiskImage -ImagePath $Iso | Get-Volume
    if (!$Vol) { Log $TxtLogMod "Cannot mount ISO file." "ERR"; $Form.Cursor="Default"; return }
    
    Log $TxtLogMod "Copying files (This may take time)..."
    Copy-Item "$($Vol.DriveLetter):\*" $Global:ExtractDir -Recurse -Force
    
    $Wim = "$Global:ExtractDir\sources\install.wim"
    $Esd = "$Global:ExtractDir\sources\install.esd"

    if (!(Test-Path $Wim)) {
        if (Test-Path $Esd) {
            Log $TxtLogMod "ESD Detected. Exporting to WIM..."
            Start-Process "dism" -ArgumentList "/Export-Image /SourceImageFile:`"$Esd`" /SourceIndex:1 /DestinationImageFile:`"$Wim`" /Compress:max /ScratchDir:`"$ScratchDir`"" -Wait -NoNewWindow
            Remove-Item $Esd -Force
        } else { Log $TxtLogMod "No install.wim/esd found!" "ERR"; $Form.Cursor="Default"; return }
    }

    Log $TxtLogMod "Mounting WIM to Directory..."
    Log $TxtLogMod "CMD: dism /Mount-Image /ImageFile:$Wim /Index:1 /MountDir:$Global:MountDir /ScratchDir:$ScratchDir" "CMD"
    
    $Proc = Start-Process "dism" -ArgumentList "/Mount-Image /ImageFile:`"$Wim`" /Index:1 /MountDir:`"$Global:MountDir`" /ScratchDir:`"$ScratchDir`"" -Wait -NoNewWindow -PassThru
    
    if ($Proc.ExitCode -eq 0) {
        $LblInfo.Text="STATUS: MOUNTED"; $LblInfo.ForeColor="Lime"; $BtnBuild.Enabled=$true
        Log $TxtLogMod "Mount SUCCESS!" "INFO"
    } else {
        Log $TxtLogMod "Mount FAILED. ExitCode: $($Proc.ExitCode). Check permissions or disk space." "ERR"
    }
    $Form.Cursor="Default"
}

function Add-Folder {
    $FBD = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($FBD.ShowDialog() -eq "OK") {
        Copy-Item $FBD.SelectedPath $Global:MountDir -Recurse -Force
        Log $TxtLogMod "Added Folder: $($FBD.SelectedPath)"
    }
}
function Add-Driver {
    $FBD = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($FBD.ShowDialog() -eq "OK") {
        Log $TxtLogMod "Adding Drivers..."
        Start-Process "dism" -ArgumentList "/Image:`"$Global:MountDir`" /Add-Driver /Driver:`"$($FBD.SelectedPath)`" /Recurse /ScratchDir:`"$ScratchDir`"" -Wait -NoNewWindow
        Log $TxtLogMod "Drivers Added."
    }
}
function Add-DesktopFile {
    $O = New-Object System.Windows.Forms.OpenFileDialog
    if ($O.ShowDialog() -eq "OK") {
        Copy-Item $O.FileName "$Global:MountDir\Users\Public\Desktop" -Force
        Log $TxtLogMod "File added to Desktop."
    }
}

$BtnBuild.Add_Click({
    if (!(Check-Tools)) { return }
    $S = New-Object System.Windows.Forms.SaveFileDialog; $S.Filter="ISO|*.iso"; $S.FileName="WinModded.iso"
    if ($S.ShowDialog() -eq "OK") {
        $Form.Cursor="WaitCursor"
        Log $TxtLogMod "Unmounting & Committing..."
        Start-Process "dism" -ArgumentList "/Unmount-Image /MountDir:`"$Global:MountDir`" /Commit /ScratchDir:`"$ScratchDir`"" -Wait -NoNewWindow
        
        Log $TxtLogMod "Creating ISO..."
        $Osc = "$ToolsDir\oscdimg.exe"
        $Boot = "2#p0,e,b`"$Global:ExtractDir\boot\etfsboot.com`"#pEF,e,b`"$Global:ExtractDir\efi\microsoft\boot\efisys.bin`""
        Start-Process $Osc -ArgumentList "-bootdata:$Boot -u2 -udfver102 `"$Global:ExtractDir`" `"$S.FileName`"" -Wait -NoNewWindow
        
        Log $TxtLogMod "DONE! ISO at: $($S.FileName)" "INFO"
        [System.Windows.Forms.MessageBox]::Show("Done!"); Invoke-Item (Split-Path $S.FileName)
        $GbAct.Enabled=$false; $BtnBuild.Enabled=$false; $Form.Cursor="Default"
    }
})

$Form.ShowDialog() | Out-Null
