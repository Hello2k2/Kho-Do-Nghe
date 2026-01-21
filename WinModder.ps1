<#
    WINDOWS MODDER STUDIO - PHAT TAN PC
    Version: 4.0 (VSS Edition: The Ultimate Live Capture Solution)
    Technique: Volume Shadow Copy Service Snapshot -> Symbolic Link -> DISM
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
$CurrentShadowID = $null

# --- HÀM LOGGING ---
function Log ($Box, $Msg, $Type="INFO") {
    $Time = [DateTime]::Now.ToString('HH:mm:ss')
    $Color = "Lime"
    if ($Type -eq "ERR") { $Color = "Red" }
    if ($Type -eq "VSS") { $Color = "Cyan" }
    
    $Box.AppendText("[$Time] [$Type] $Msg`r`n")
    $Box.ScrollToCaret()
    $StatusLbl.Text = "Status: $Msg"
    [System.Windows.Forms.Application]::DoEvents()
}

# --- HÀM TẠO CONFIG (CHỈ CẦN LOẠI TRỪ RÁC, KHÔNG CẦN LO FILE LOCK NỮA) ---
function Create-DismConfig {
    if (!(Test-Path $ToolsDir)) { New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null }
    $ConfigPath = "$ToolsDir\WimScript.ini"
    
    # VSS đã giải quyết vấn đề Lock file.
    # File này giờ chỉ dùng để loại bỏ file RÁC cho nhẹ bản Win.
    $Content = @"
[ExclusionList]
\$ntfs.log
\hiberfil.sys
\pagefile.sys
\swapfile.sys
\System Volume Information
\RECYCLER
\$Recycle.Bin
\Windows\CSC
\DumpStack.log.tmp
\Config.Msi
\Windows\SoftwareDistribution
\Users\*\AppData\Local\Temp
\Users\*\AppData\Local\Microsoft\Windows\INetCache
\Users\*\AppData\Local\Microsoft\Windows\WebCache
"@
    [System.IO.File]::WriteAllText($ConfigPath, $Content)
    return $ConfigPath
}

# =========================================================================================
# VSS CORE FUNCTIONS (TRÁI TIM CỦA V4.0)
# =========================================================================================

function Create-ShadowCopy {
    param($DriveLetter, $MountPoint, $Box)
    
    Log $Box "Khởi tạo Volume Shadow Copy (VSS) cho $DriveLetter..." "VSS"
    
    try {
        # 1. Gọi WMI để tạo Shadow Copy
        $WmiClass = [WMICLASS]"root\cimv2:Win32_ShadowCopy"
        $Result = $WmiClass.Create($DriveLetter, "ClientAccessible")
        
        if ($Result.ReturnValue -ne 0) {
            Log $Box "Lỗi tạo VSS. Mã lỗi WMI: $($Result.ReturnValue)" "ERR"
            return $false
        }
        
        $Global:CurrentShadowID = $Result.ShadowID
        Log $Box "VSS ID Created: $($Global:CurrentShadowID)" "VSS"
        
        # 2. Lấy đường dẫn thiết bị (Device Path) của Snapshot vừa tạo
        # Định dạng: \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopyX
        $Snapshot = Get-WmiObject Win32_ShadowCopy | Where-Object { $_.ID -eq $Global:CurrentShadowID }
        $DevicePath = $Snapshot.DeviceObject
        
        if ([string]::IsNullOrEmpty($DevicePath)) {
            Log $Box "Không tìm thấy Device Path của Snapshot." "ERR"
            return $false
        }
        
        Log $Box "Snapshot Device Path: $DevicePath" "VSS"
        
        # 3. Tạo Symbolic Link để DISM có thể đọc được
        # DISM không đọc được đường dẫn \\?\, nên ta map nó vào thư mục C:\WinMod_Temp\ShadowMount
        if (Test-Path $MountPoint) { Remove-Item $MountPoint -Force -Recurse -ErrorAction SilentlyContinue }
        
        # Dùng CMD mklink vì PowerShell New-Item đôi khi lỗi với Device Path
        $CmdArgs = "/c mklink /d `"$MountPoint`" `"$DevicePath\`""
        Start-Process "cmd.exe" -ArgumentList $CmdArgs -NoNewWindow -Wait
        
        if (Test-Path "$MountPoint\Windows") {
            Log $Box "VSS Mapped thành công tại: $MountPoint" "VSS"
            return $true
        } else {
            Log $Box "Lỗi Map VSS (Symlink failed)." "ERR"
            return $false
        }
        
    } catch {
        Log $Box "VSS Exception: $($_.Exception.Message)" "ERR"
        return $false
    }
}

function Cleanup-ShadowCopy {
    param($MountPoint, $Box)
    
    Log $Box "Dọn dẹp VSS..." "VSS"
    
    # 1. Xóa Symlink
    if (Test-Path $MountPoint) {
        cmd /c rmdir "$MountPoint" # RMDIR an toàn hơn cho Symlink
    }
    
    # 2. Xóa Shadow Copy trên hệ thống
    if ($Global:CurrentShadowID) {
        try {
            $Shadow = Get-WmiObject Win32_ShadowCopy | Where-Object { $_.ID -eq $Global:CurrentShadowID }
            if ($Shadow) { $Shadow.Delete() }
            Log $Box "Đã xóa Snapshot rác." "VSS"
        } catch {}
        $Global:CurrentShadowID = $null
    }
}

# =========================================================================================
# STANDARD FUNCTIONS
# =========================================================================================

function Check-Tools {
    $OscTarget = "$ToolsDir\oscdimg.exe"
    if (Test-Path $OscTarget) { return $true }
    Log $TxtLogMod "Checking Tools..."
    try {
        if (!(Test-Path $ToolsDir)) { New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null }
        $Url = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/refs/heads/main/oscdimg.exe"
        (New-Object System.Net.WebClient).DownloadFile($Url, $OscTarget)
        if ((Get-Item $OscTarget).Length -gt 100kb) { return $true }
    } catch {}
    $Msg = "Thiếu 'oscdimg.exe'. Tự động tải ADK?"; if ([System.Windows.Forms.MessageBox]::Show($Msg, "Missing Tool", "YesNo") -eq "Yes") {
        try {
            $Installer = "$env:TEMP\adksetup.exe"; (New-Object System.Net.WebClient).DownloadFile("https://go.microsoft.com/fwlink/?linkid=2243390", $Installer)
            Start-Process $Installer -ArgumentList "/quiet /norestart /features OptionId.DeploymentTools" -Wait; return $true
        } catch { return $false }
    }
    return $false
}

function Grant-FullAccess ($Path) { if (Test-Path $Path) { Start-Process "icacls" -ArgumentList "`"$Path`" /grant Everyone:F /T /C /Q" -Wait -NoNewWindow } }

function Update-Workspace {
    $SelDrive = $CboDrives.SelectedItem.ToString().Split(" ")[0]
    $Global:WorkDir     = "$SelDrive\WinMod_Temp"
    $Global:MountDir    = "$Global:WorkDir\Mount"
    $Global:ExtractDir  = "$Global:WorkDir\Source"
    $Global:CaptureDir  = "$Global:WorkDir\Capture"
    $Global:ScratchDir  = "$Global:WorkDir\Scratch"
    $Global:ShadowMount = "$Global:WorkDir\ShadowMount" # Thư mục mount VSS
    $LblWorkDir.Text = "Workspace: $Global:WorkDir"
}

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
$Form.Text = "WINDOWS MODDER STUDIO V4.0 (VSS SNAPSHOT EDITION)"
$Form.Size = New-Object System.Drawing.Size(950, 720)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 35)
$Form.ForeColor = "WhiteSmoke"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$PanelTop = New-Object System.Windows.Forms.Panel; $PanelTop.Dock="Top"; $PanelTop.Height=80; $PanelTop.BackColor=[System.Drawing.Color]::FromArgb(45,45,50); $Form.Controls.Add($PanelTop)
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "PHAT TAN PC - SYSTEM BUILDER"; $LblT.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold); $LblT.ForeColor = "Gold"; $LblT.AutoSize = $true; $LblT.Location = "20,10"; $PanelTop.Controls.Add($LblT)

# Drive Selector
$LblSel = New-Object System.Windows.Forms.Label; $LblSel.Text = "Chọn ổ Workspace (Nơi chứa file tạm):"; $LblSel.Location = "20, 50"; $LblSel.AutoSize=$true; $PanelTop.Controls.Add($LblSel)
$CboDrives = New-Object System.Windows.Forms.ComboBox; $CboDrives.Location = "300, 48"; $CboDrives.Size = "150, 25"; $CboDrives.DropDownStyle = "DropDownList"; $PanelTop.Controls.Add($CboDrives)
$Drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }; foreach ($D in $Drives) { $CboDrives.Items.Add("$($D.DeviceID) (Free: $([Math]::Round($D.FreeSpace/1GB,1)) GB)") | Out-Null }
if ($CboDrives.Items.Count -gt 0) { $CboDrives.SelectedIndex = 0 }; $CboDrives.Add_SelectedIndexChanged({ Update-Workspace })
$LblWorkDir = New-Object System.Windows.Forms.Label; $LblWorkDir.Text = "..."; $LblWorkDir.Location = "470, 50"; $LblWorkDir.AutoSize=$true; $LblWorkDir.ForeColor="Lime"; $PanelTop.Controls.Add($LblWorkDir)

# Status
$StatusStrip = New-Object System.Windows.Forms.StatusStrip; $StatusStrip.BackColor="Black"
$StatusLbl = New-Object System.Windows.Forms.ToolStripStatusLabel; $StatusLbl.Text = "Ready."; $StatusLbl.ForeColor="Cyan"; $StatusStrip.Items.Add($StatusLbl) | Out-Null; $Form.Controls.Add($StatusStrip)

# Tabs
$Tabs = New-Object System.Windows.Forms.TabControl; $Tabs.Location = "20,100"; $Tabs.Size = "895,550"; $Tabs.Appearance = "FlatButtons"; $Form.Controls.Add($Tabs)
function Make-Tab ($T) { $P = New-Object System.Windows.Forms.TabPage; $P.Text = "  $T  "; $P.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 35); $Tabs.Controls.Add($P); return $P }
$TabCap = Make-Tab "1. CAPTURE OS (VSS)"; $TabMod = Make-Tab "2. MODDING ISO"

# --- TAB 1: CAPTURE ---
$GbCap = New-Object System.Windows.Forms.GroupBox; $GbCap.Text="CAPTURE WINDOWS (LIVE OS VIA VSS)"; $GbCap.Location="20,20"; $GbCap.Size="845,470"; $GbCap.ForeColor="Cyan"; $TabCap.Controls.Add($GbCap)
$LblC1 = New-Object System.Windows.Forms.Label; $LblC1.Text="Lưu file WIM tại:"; $LblC1.Location="30,40"; $LblC1.AutoSize=$true; $GbCap.Controls.Add($LblC1)
$TxtCapOut = New-Object System.Windows.Forms.TextBox; $TxtCapOut.Location="30,65"; $TxtCapOut.Size="650,25"; $TxtCapOut.Text="D:\PhatTan_Backup.wim"; $GbCap.Controls.Add($TxtCapOut)
$BtnCapBrowse = New-Object System.Windows.Forms.Button; $BtnCapBrowse.Text="CHỌN..."; $BtnCapBrowse.Location="700,63"; $BtnCapBrowse.Size="100,27"; $BtnCapBrowse.ForeColor="Black"; $GbCap.Controls.Add($BtnCapBrowse)
$BtnStartCap = New-Object System.Windows.Forms.Button; $BtnStartCap.Text="BẮT ĐẦU CAPTURE (Công nghệ VSS Snapshot)"; $BtnStartCap.Location="30,110"; $BtnStartCap.Size="770,50"; $BtnStartCap.BackColor="OrangeRed"; $BtnStartCap.ForeColor="White"; $BtnStartCap.Font="Segoe UI, 11, Bold"; $GbCap.Controls.Add($BtnStartCap)
$TxtLogCap = New-Object System.Windows.Forms.TextBox; $TxtLogCap.Multiline=$true; $TxtLogCap.Location="30,180"; $TxtLogCap.Size="770,260"; $TxtLogCap.BackColor="Black"; $TxtLogCap.ForeColor="Lime"; $TxtLogCap.ScrollBars="Vertical"; $TxtLogCap.ReadOnly=$true; $TxtLogCap.Font="Consolas, 9"; $GbCap.Controls.Add($TxtLogCap)

# --- TAB 2: MODDING ---
$GbSrc = New-Object System.Windows.Forms.GroupBox; $GbSrc.Text="SOURCE ISO"; $GbSrc.Location="20,20"; $GbSrc.Size="845,80"; $GbSrc.ForeColor="Yellow"; $TabMod.Controls.Add($GbSrc)
$TxtIsoSrc = New-Object System.Windows.Forms.TextBox; $TxtIsoSrc.Location="20,35"; $TxtIsoSrc.Size="650,25"; $GbSrc.Controls.Add($TxtIsoSrc)
$BtnIsoSrc = New-Object System.Windows.Forms.Button; $BtnIsoSrc.Text="MỞ ISO"; $BtnIsoSrc.Location="690,33"; $BtnIsoSrc.Size="120,27"; $BtnIsoSrc.ForeColor="Black"; $GbSrc.Controls.Add($BtnIsoSrc)
$GbAct = New-Object System.Windows.Forms.GroupBox; $GbAct.Text="MENU EDIT"; $GbAct.Location="20,110"; $GbAct.Size="845,300"; $GbAct.ForeColor="Lime"; $GbAct.Enabled=$false; $TabMod.Controls.Add($GbAct)
function Add-Btn ($T, $X, $Y, $C, $Fn) { $b=New-Object System.Windows.Forms.Button; $b.Text=$T; $b.Location="$X,$Y"; $b.Size="250,40"; $b.BackColor=$C; $b.ForeColor="Black"; $b.FlatStyle="Flat"; $b.Add_Click($Fn); $GbAct.Controls.Add($b) }
Add-Btn "1. MOUNT ISO" 30 30 "Cyan" { Start-Mount }; Add-Btn "2. ADD FOLDER" 30 80 "White" { Add-Folder }
Add-Btn "3. ADD DRIVERS" 30 130 "White" { Add-Driver }; Add-Btn "4. ADD DESKTOP FILE" 30 180 "White" { Add-DesktopFile }
Add-Btn "DỌN DẸP LỖI" 560 30 "Red" { Force-Cleanup }
$LblInfo = New-Object System.Windows.Forms.Label; $LblInfo.Text="STATUS: UNMOUNTED"; $LblInfo.Location="300,40"; $LblInfo.AutoSize=$true; $LblInfo.Font="Segoe UI, 10, Bold"; $GbAct.Controls.Add($LblInfo)
$TxtLogMod = New-Object System.Windows.Forms.TextBox; $TxtLogMod.Multiline=$true; $TxtLogMod.Location="300,80"; $TxtLogMod.Size="510,200"; $TxtLogMod.BackColor="Black"; $TxtLogMod.ForeColor="Cyan"; $TxtLogMod.ScrollBars="Vertical"; $TxtLogMod.ReadOnly=$true; $TxtLogMod.Font="Consolas, 9"; $GbAct.Controls.Add($TxtLogMod)
$BtnBuild = New-Object System.Windows.Forms.Button; $BtnBuild.Text="3. TẠO ISO MỚI (REBUILD)"; $BtnBuild.Location="20,420"; $BtnBuild.Size="845,60"; $BtnBuild.BackColor="Green"; $BtnBuild.ForeColor="White"; $BtnBuild.Font="Segoe UI, 14, Bold"; $BtnBuild.Enabled=$false; $TabMod.Controls.Add($BtnBuild)

# =========================================================================================
# LOGIC CORE
# =========================================================================================

$BtnCapBrowse.Add_Click({ $S=New-Object System.Windows.Forms.SaveFileDialog; $S.Filter="WIM File|*.wim"; $S.FileName="install.wim"; if($S.ShowDialog()-eq"OK"){$TxtCapOut.Text=$S.FileName} })

# --- CAPTURE LOGIC (VSS INTEGRATED) ---
$BtnStartCap.Add_Click({
    if (!(Check-Tools)) { return }
    Update-Workspace; Prepare-Dirs
    $ConfigFile = Create-DismConfig
    $WimTarget = $TxtCapOut.Text
    
    $BtnStartCap.Enabled=$false; $Form.Cursor="WaitCursor"
    
    # BƯỚC 1: TẠO SHADOW COPY CỦA Ổ C:
    # -----------------------------------------------------
    $VssOk = Create-ShadowCopy "C:\" $Global:ShadowMount $TxtLogCap
    
    if ($VssOk) {
        # BƯỚC 2: CAPTURE TỪ SHADOW COPY (KHÔNG PHẢI Ổ C)
        # -----------------------------------------------------
        Log $TxtLogCap "Đang Capture từ Snapshot (Zero Lock Files)..." "INFO"
        
        $Proc = Start-Process "dism" -ArgumentList "/Capture-Image /ImageFile:`"$WimTarget`" /CaptureDir:`"$Global:ShadowMount`" /Name:`"MyWin_VSS`" /Compress:max /ScratchDir:`"$Global:ScratchDir`" /ConfigFile:`"$ConfigFile`"" -Wait -NoNewWindow -PassThru
        
        if ($Proc.ExitCode -eq 0) {
            Log $TxtLogCap "THÀNH CÔNG! Đã tạo WIM sạch từ VSS." "INFO"
            [System.Windows.Forms.MessageBox]::Show("Capture VSS Thành Công!")
        } else {
            Log $TxtLogCap "Lỗi Capture (Code $($Proc.ExitCode))." "ERR"
        }
        
        # BƯỚC 3: DỌN DẸP VSS
        # -----------------------------------------------------
        Cleanup-ShadowCopy $Global:ShadowMount $TxtLogCap
    }
    
    $BtnStartCap.Enabled=$true; $Form.Cursor="Default"
})

# --- MODDING LOGIC (GIỮ NGUYÊN) ---
$BtnIsoSrc.Add_Click({ $O=New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="ISO|*.iso"; if($O.ShowDialog()-eq"OK"){$TxtIsoSrc.Text=$O.FileName; $GbAct.Enabled=$true} })
function Force-Cleanup {
    Start-Process "dism" -ArgumentList "/Cleanup-Wim" -Wait -NoNewWindow
    Start-Process "dism" -ArgumentList "/Unmount-Image /MountDir:`"$Global:MountDir`" /Discard" -Wait -NoNewWindow
    Remove-Item $Global:MountDir -Recurse -Force -ErrorAction SilentlyContinue
    Log $TxtLogMod "Cleaned."
}
function Start-Mount {
    $Iso = $TxtIsoSrc.Text
    if (!(Test-Path $Iso)) { Log $TxtLogMod "Không tìm thấy file ISO!" "ERR"; return }

    # 1. Chuẩn bị môi trường
    Update-Workspace; Prepare-Dirs; $Form.Cursor="WaitCursor"; Force-Cleanup
    Ensure-Dir $Global:ExtractDir; Ensure-Dir $Global:MountDir
    
    # 2. MOUNT ISO & QUÉT DRIVE LETTER (HYBRID MODE)
    Log $TxtLogMod "Mounting ISO..."
    Mount-DiskImage -ImagePath $Iso -StorageType ISO -ErrorAction SilentlyContinue | Out-Null
    
    $IsoDrive = $null
    
    # -- Vòng lặp quét 5 lần (mỗi lần 1s) --
    for ($i=1; $i -le 5; $i++) {
        # CÁCH 1: Thử Get-Volume (Win Full)
        try {
            $Vol = Get-DiskImage -ImagePath $Iso | Get-Volume -ErrorAction Stop
            if ($Vol.DriveLetter) { $IsoDrive = "$($Vol.DriveLetter):"; break }
        } catch {}

        # CÁCH 2: Fallback sang WMI (Win Lite / Win Cổ)
        if (!$IsoDrive) {
            # Quét tất cả ổ CD-ROM (DriveType=5) xem ổ nào chứa bộ cài
            $Cds = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=5"
            foreach ($Cd in $Cds) {
                if ((Test-Path "$($Cd.DeviceID)\sources\install.wim") -or (Test-Path "$($Cd.DeviceID)\sources\install.esd")) {
                    $IsoDrive = $Cd.DeviceID
                    break
                }
            }
        }
        
        if ($IsoDrive) { break }
        Start-Sleep -Seconds 1
    }

    if (!$IsoDrive) { 
        Log $TxtLogMod "Lỗi: Không tìm thấy ổ đĩa ảo! (Win Lite bị lỗi Mount?)" "ERR"
        $Form.Cursor="Default"; return 
    }
    
    Log $TxtLogMod "Phát hiện bộ cài tại ổ: $IsoDrive" "INFO"

    # 3. COPY DỮ LIỆU
    Log $TxtLogMod "Copying data from $IsoDrive..."
    Copy-Item "$IsoDrive\*" $Global:ExtractDir -Recurse -Force
    
    # 4. XỬ LÝ ESD (ESD CONVERTER)
    $SourceWim = "$Global:ExtractDir\sources\install.wim"
    $SourceEsd = "$Global:ExtractDir\sources\install.esd"
    $TargetImage = $SourceWim 

    if (Test-Path $SourceEsd) {
        Log $TxtLogMod "Phát hiện ESD (Read-Only). Đang Convert sang WIM..."
        # Export ESD -> WIM để có quyền Ghi (Read-Write)
        $Proc = Start-Process "dism" -ArgumentList "/Export-Image /SourceImageFile:`"$SourceEsd`" /SourceIndex:1 /DestinationImageFile:`"$SourceWim`" /Compress:max" -Wait -NoNewWindow -PassThru
        
        if ($Proc.ExitCode -eq 0) {
            Log $TxtLogMod "Convert ESD -> WIM thành công." "INFO"
            Remove-Item $SourceEsd -Force # Xóa file ESD gốc cho nhẹ
            $TargetImage = $SourceWim
        } else {
            Log $TxtLogMod "Lỗi Convert ESD! (Code $($Proc.ExitCode))" "ERR"
            $Form.Cursor="Default"; return
        }
    } elseif (!(Test-Path $SourceWim)) {
        Log $TxtLogMod "Lỗi: ISO không chứa install.wim hoặc install.esd" "ERR"
        $Form.Cursor="Default"; return
    }

    # 5. MOUNT WIM (RW MODE)
    Log $TxtLogMod "Mounting WIM để Modding..."
    $ProcMount = Start-Process "dism" -ArgumentList "/Mount-Image /ImageFile:`"$TargetImage`" /Index:1 /MountDir:`"$Global:MountDir`" /ScratchDir:`"$Global:ScratchDir`"" -Wait -NoNewWindow -PassThru
    
    if ($ProcMount.ExitCode -eq 0) {
        $LblInfo.Text="MOUNTED (RW)"; $LblInfo.ForeColor="Lime"
        $BtnBuild.Enabled=$true
        Log $TxtLogMod "Mount OK! Sẵn sàng thêm Soft/Driver." "INFO"
    } else {
        Log $TxtLogMod "Lỗi Mount DISM (Code $($ProcMount.ExitCode))." "ERR"
    }
    
    $Form.Cursor="Default"
}

# Đảm bảo hàm này có tồn tại (vì bác dùng trong Start-Mount)
function Ensure-Dir($path) { if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null } }
function Add-Folder { $FBD = New-Object System.Windows.Forms.FolderBrowserDialog; if ($FBD.ShowDialog() -eq "OK") { Copy-Item $FBD.SelectedPath $Global:MountDir -Recurse -Force; Log $TxtLogMod "Copied" } }
function Add-Driver { $FBD = New-Object System.Windows.Forms.FolderBrowserDialog; if ($FBD.ShowDialog() -eq "OK") { Log $TxtLogMod "Adding Drivers..."; Start-Process "dism" -ArgumentList "/Image:`"$Global:MountDir`" /Add-Driver /Driver:`"$($FBD.SelectedPath)`" /Recurse /ScratchDir:`"$Global:ScratchDir`"" -Wait -NoNewWindow; Log $TxtLogMod "Done" } }
function Add-DesktopFile { $O = New-Object System.Windows.Forms.OpenFileDialog; if ($O.ShowDialog() -eq "OK") { Copy-Item $O.FileName "$Global:MountDir\Users\Public\Desktop" -Force; Log $TxtLogMod "Added" } }
$BtnBuild.Add_Click({
    if (!(Check-Tools)) { return }; $S = New-Object System.Windows.Forms.SaveFileDialog; $S.Filter="ISO|*.iso"; $S.FileName="NewWin.iso"
    if ($S.ShowDialog() -eq "OK") {
        $Form.Cursor="WaitCursor"; Log $TxtLogMod "Building..."
        Start-Process "dism" -ArgumentList "/Unmount-Image /MountDir:`"$Global:MountDir`" /Commit /ScratchDir:`"$Global:ScratchDir`"" -Wait -NoNewWindow
        $Osc = "$ToolsDir\oscdimg.exe"; $Boot = "2#p0,e,b`"$Global:ExtractDir\boot\etfsboot.com`"#pEF,e,b`"$Global:ExtractDir\efi\microsoft\boot\efisys.bin`""
        Start-Process $Osc -ArgumentList "-bootdata:$Boot -u2 -udfver102 `"$Global:ExtractDir`" `"$S.FileName`"" -Wait -NoNewWindow
        [System.Windows.Forms.MessageBox]::Show("Done!"); Invoke-Item (Split-Path $S.FileName); $GbAct.Enabled=$false; $BtnBuild.Enabled=$false; $Form.Cursor="Default"
    }
})
if ($CboDrives.Items.Count -gt 0) { Update-Workspace }; $Form.ShowDialog() | Out-Null
