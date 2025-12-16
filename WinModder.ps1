<#
    WINDOWS MODDER STUDIO - PHAT TAN PC
    Version: 2.8 (Live Capture Final: Auto Stop Services + Enhanced Exclusions)
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

# --- HÀM LOGGING ---
function Log ($Box, $Msg, $Type="INFO") {
    $Time = [DateTime]::Now.ToString('HH:mm:ss')
    $Box.AppendText("[$Time] [$Type] $Msg`r`n")
    $Box.ScrollToCaret()
    $StatusLbl.Text = "Status: $Msg"
    [System.Windows.Forms.Application]::DoEvents()
}

# --- HÀM TẠO FILE CẤU HÌNH LOẠI TRỪ (CẬP NHẬT MỚI) ---
function Create-DismConfig {
    if (!(Test-Path $ToolsDir)) { New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null }
    $ConfigPath = "$ToolsDir\WimScript.ini"
    
    # Danh sách loại trừ mở rộng để tránh lỗi edb.jtx và các file lock khác
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
\DumpStack.log
\Config.Msi
\Windows\SoftwareDistribution
\ProgramData\Microsoft\Search
\Windows\System32\LogFiles
\Windows\Logs
\PerfLogs
"@
    [System.IO.File]::WriteAllText($ConfigPath, $Content)
    return $ConfigPath
}

# --- HÀM QUẢN LÝ DỊCH VỤ (FIX LỖI 0x80070020) ---
function Toggle-Services ($State) {
    # Danh sách các dịch vụ hay khóa file
    $Services = @("wsearch", "sysmain", "cryptsvc", "wuauserv", "bits")
    
    foreach ($Svc in $Services) {
        if ($State -eq "STOP") {
            if ((Get-Service $Svc).Status -eq "Running") {
                Stop-Service -Name $Svc -Force -ErrorAction SilentlyContinue
            }
        } else {
            # Chỉ bật lại những cái thiết yếu nếu cần (hoặc để Windows tự bật lại sau)
            if ((Get-Service $Svc).Status -eq "Stopped") {
                Start-Service -Name $Svc -ErrorAction SilentlyContinue
            }
        }
    }
}

# --- HÀM CẤP QUYỀN ---
function Grant-FullAccess ($Path) {
    if (Test-Path $Path) {
        Start-Process "icacls" -ArgumentList "`"$Path`" /grant Everyone:F /T /C /Q" -Wait -NoNewWindow
    }
}

# --- HÀM THOÁT KHỎI THƯ MỤC ---
function Release-Locks {
    Set-Location "$env:TEMP"
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}

# --- HÀM CẬP NHẬT WORKSPACE ---
function Update-Workspace {
    $SelDrive = $CboDrives.SelectedItem.ToString().Split(" ")[0]
    $Global:WorkDir     = "$SelDrive\WinMod_Temp"
    $Global:MountDir    = "$Global:WorkDir\Mount"
    $Global:ExtractDir  = "$Global:WorkDir\Source"
    $Global:CaptureDir  = "$Global:WorkDir\Capture"
    $Global:ScratchDir  = "$Global:WorkDir\Scratch"
    $LblWorkDir.Text = "Workspace: $Global:WorkDir"
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
$Form.Text = "WINDOWS MODDER STUDIO V2.8 (LIVE CAPTURE FINAL)"
$Form.Size = New-Object System.Drawing.Size(950, 720)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 35)
$Form.ForeColor = "WhiteSmoke"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header Panel
$PanelTop = New-Object System.Windows.Forms.Panel; $PanelTop.Dock="Top"; $PanelTop.Height=80; $PanelTop.BackColor=[System.Drawing.Color]::FromArgb(45,45,50); $Form.Controls.Add($PanelTop)

$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "PHAT TAN PC - SYSTEM BUILDER"; $LblT.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold); $LblT.ForeColor = "Gold"; $LblT.AutoSize = $true; $LblT.Location = "20,10"; $PanelTop.Controls.Add($LblT)

# --- DRIVE SELECTOR ---
$LblSel = New-Object System.Windows.Forms.Label; $LblSel.Text = "Chọn ổ đĩa Workspace (Nơi chứa file tạm):"; $LblSel.Location = "20, 50"; $LblSel.AutoSize=$true; $PanelTop.Controls.Add($LblSel)

$CboDrives = New-Object System.Windows.Forms.ComboBox; $CboDrives.Location = "350, 48"; $CboDrives.Size = "150, 25"; $CboDrives.DropDownStyle = "DropDownList"; $PanelTop.Controls.Add($CboDrives)

# Lấy danh sách ổ cứng (LOẠI BỎ Ổ CD)
$Drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } 
foreach ($D in $Drives) {
    $FreeSpace = [Math]::Round($D.FreeSpace / 1GB, 1)
    $CboDrives.Items.Add("$($D.DeviceID) (Free: $FreeSpace GB)") | Out-Null
}
if ($CboDrives.Items.Count -gt 0) { $CboDrives.SelectedIndex = 0 } 
$CboDrives.Add_SelectedIndexChanged({ Update-Workspace })

$LblWorkDir = New-Object System.Windows.Forms.Label; $LblWorkDir.Text = "..."; $LblWorkDir.Location = "520, 50"; $LblWorkDir.AutoSize=$true; $LblWorkDir.ForeColor="Lime"; $PanelTop.Controls.Add($LblWorkDir)

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
$GbCap = New-Object System.Windows.Forms.GroupBox; $GbCap.Text="CAPTURE WINDOWS"; $GbCap.Location="20,20"; $GbCap.Size="845,470"; $GbCap.ForeColor="Cyan"; $TabCap.Controls.Add($GbCap)

$LblC1 = New-Object System.Windows.Forms.Label; $LblC1.Text="Lưu file WIM tại:"; $LblC1.Location="30,40"; $LblC1.AutoSize=$true; $GbCap.Controls.Add($LblC1)
$TxtCapOut = New-Object System.Windows.Forms.TextBox; $TxtCapOut.Location="30,65"; $TxtCapOut.Size="650,25"; $TxtCapOut.Text="D:\PhatTan_Backup.wim"; $GbCap.Controls.Add($TxtCapOut)
$BtnCapBrowse = New-Object System.Windows.Forms.Button; $BtnCapBrowse.Text="CHỌN..."; $BtnCapBrowse.Location="700,63"; $BtnCapBrowse.Size="100,27"; $BtnCapBrowse.ForeColor="Black"; $GbCap.Controls.Add($BtnCapBrowse)

$BtnStartCap = New-Object System.Windows.Forms.Button; $BtnStartCap.Text="BẮT ĐẦU CAPTURE (An toàn & Tự động)"; $BtnStartCap.Location="30,110"; $BtnStartCap.Size="770,50"; $BtnStartCap.BackColor="OrangeRed"; $BtnStartCap.ForeColor="White"; $BtnStartCap.Font="Segoe UI, 11, Bold"; $GbCap.Controls.Add($BtnStartCap)

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
# LOGIC CORE (V2.8)
# =========================================================================================

# --- TOOL CHECKER ---
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

    $Msg = "Không tìm thấy 'oscdimg.exe'. Tự động tải ADK?"
    if ([System.Windows.Forms.MessageBox]::Show($Msg, "Missing Tool", "YesNo") -eq "Yes") {
        try {
            $Installer = "$env:TEMP\adksetup.exe"
            Log $TxtLogMod "Downloading ADK..."
            (New-Object System.Net.WebClient).DownloadFile("https://go.microsoft.com/fwlink/?linkid=2243390", $Installer)
            Log $TxtLogMod "Installing ADK..."
            Start-Process $Installer -ArgumentList "/quiet /norestart /features OptionId.DeploymentTools" -Wait
            return $true
        } catch { Log $TxtLogMod "Lỗi tải ADK: $($_.Exception.Message)" "ERR"; return $false }
    }
    return $false
}

# --- SMART UNMOUNT ---
function Smart-Unmount ($Commit) {
    Release-Locks
    $Attempt = 1; $MaxRetry = 3; $Success = $false
    
    do {
        Log $TxtLogMod "Unmounting... ($Attempt)" "CMD"
        $ArgsList = "/Unmount-Image /MountDir:`"$Global:MountDir`" /ScratchDir:`"$Global:ScratchDir`""
        if ($Commit) { $ArgsList += " /Commit" } else { $ArgsList += " /Discard" }
        $Proc = Start-Process "dism" -ArgumentList $ArgsList -Wait -NoNewWindow -PassThru
        
        if ($Proc.ExitCode -eq 0) { $Success = $true; Log $TxtLogMod "Unmount OK!" "INFO" } 
        else {
            Log $TxtLogMod "Lỗi Unmount. Thử lại sau 3s..." "WARN"
            Start-Sleep -Seconds 3
            Start-Process "dism" -ArgumentList "/Cleanup-Wim" -Wait -NoNewWindow
        }
        $Attempt++
    } while (($Attempt -le $MaxRetry) -and ($Success -eq $false))
    return $Success
}

# --- LOGIC CAPTURE (V2.8 FIXED) ---
$BtnCapBrowse.Add_Click({ $S=New-Object System.Windows.Forms.SaveFileDialog; $S.Filter="WIM File|*.wim"; $S.FileName="install.wim"; if($S.ShowDialog()-eq"OK"){$TxtCapOut.Text=$S.FileName} })

$BtnStartCap.Add_Click({
    if (!(Check-Tools)) { return }
    Update-Workspace; Prepare-Dirs
    
    # 1. TẠO FILE CẤU HÌNH LOẠI TRỪ (MẠNH HƠN)
    $ConfigFile = Create-DismConfig
    Log $TxtLogCap "Đã tạo file cấu hình: $ConfigFile" "INFO"

    $WimTarget = $TxtCapOut.Text
    $BtnStartCap.Enabled=$false; $Form.Cursor="WaitCursor"
    
    # 2. TẮT SERVICES GÂY LOCK (QUAN TRỌNG)
    Log $TxtLogCap "Đang tắt Windows Search & SysMain..." "WARN"
    Toggle-Services "STOP"
    
    Log $TxtLogCap "Đang Capture ổ C (Live OS)..." "INFO"
    Release-Locks 

    # 3. CHẠY LỆNH DISM
    $Proc = Start-Process "dism" -ArgumentList "/Capture-Image /ImageFile:`"$WimTarget`" /CaptureDir:C:\ /Name:`"MyWin`" /Compress:max /ScratchDir:`"$Global:ScratchDir`" /ConfigFile:`"$ConfigFile`"" -Wait -NoNewWindow -PassThru
    
    # 4. BẬT LẠI SERVICES
    Log $TxtLogCap "Khôi phục Services..." "INFO"
    Toggle-Services "START"

    if ($Proc.ExitCode -eq 0) { 
        Log $TxtLogCap "Capture THÀNH CÔNG!" "INFO"
        [System.Windows.Forms.MessageBox]::Show("Capture xong!")
    } else { 
        Log $TxtLogCap "Lỗi Capture (Code $($Proc.ExitCode)). Xem log chi tiết." "ERR" 
    }
    
    $BtnStartCap.Enabled=$true; $Form.Cursor="Default"
})

# --- MODDING LOGIC ---
$BtnIsoSrc.Add_Click({ $O=New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="ISO|*.iso"; if($O.ShowDialog()-eq"OK"){$TxtIsoSrc.Text=$O.FileName; $GbAct.Enabled=$true} })

function Force-Cleanup {
    Release-Locks
    Log $TxtLogMod "Cleanup..."
    Start-Process "dism" -ArgumentList "/Cleanup-Mountpoints" -Wait -NoNewWindow
    Start-Process "dism" -ArgumentList "/Cleanup-Wim" -Wait -NoNewWindow
    if (Test-Path $Global:MountDir) {
        Smart-Unmount $false 
        Remove-Item $Global:MountDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    Log $TxtLogMod "Done."
}

function Start-Mount {
    $Iso = $TxtIsoSrc.Text
    Update-Workspace; Prepare-Dirs
    $Form.Cursor="WaitCursor"
    Force-Cleanup
    Ensure-Dir $Global:ExtractDir; Ensure-Dir $Global:MountDir
    Grant-FullAccess $Global:MountDir

    Log $TxtLogMod "Mounting ISO..."
    Mount-DiskImage -ImagePath $Iso -StorageType ISO -ErrorAction SilentlyContinue | Out-Null
    $Vol = Get-DiskImage -ImagePath $Iso | Get-Volume
    if (!$Vol) { Log $TxtLogMod "Lỗi ISO." "ERR"; $Form.Cursor="Default"; return }
    
    Log $TxtLogMod "Copying..."
    Copy-Item "$($Vol.DriveLetter):\*" $Global:ExtractDir -Recurse -Force
    
    $Wim = "$Global:ExtractDir\sources\install.wim"
    if (!(Test-Path $Wim)) { $Wim = "$Global:ExtractDir\sources\install.esd" }

    if (!(Test-Path $Wim)) { Log $TxtLogMod "No WIM/ESD found!" "ERR"; $Form.Cursor="Default"; return }

    if ($Wim -match ".esd") {
        Log $TxtLogMod "Convert ESD -> WIM..."
        $NewWim = "$Global:ExtractDir\sources\install.wim"
        Start-Process "dism" -ArgumentList "/Export-Image /SourceImageFile:`"$Wim`" /SourceIndex:1 /DestinationImageFile:`"$NewWim`" /Compress:max /ScratchDir:`"$Global:ScratchDir`"" -Wait -NoNewWindow
        Remove-Item $Wim -Force; $Wim = $NewWim
    }

    Log $TxtLogMod "Mounting WIM..."
    Release-Locks
    $Proc = Start-Process "dism" -ArgumentList "/Mount-Image /ImageFile:`"$Wim`" /Index:1 /MountDir:`"$Global:MountDir`" /ScratchDir:`"$Global:ScratchDir`"" -Wait -NoNewWindow -PassThru
    
    if ($Proc.ExitCode -eq 0) {
        $LblInfo.Text="MOUNTED"; $LblInfo.ForeColor="Lime"; $BtnBuild.Enabled=$true
        Log $TxtLogMod "Mount OK!" "INFO"
    } else { Log $TxtLogMod "Mount Fail ($($Proc.ExitCode))." "ERR" }
    $Form.Cursor="Default"
}

function Add-Folder {
    $FBD = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($FBD.ShowDialog() -eq "OK") {
        Copy-Item $FBD.SelectedPath $Global:MountDir -Recurse -Force
        Log $TxtLogMod "Copied Folder."
        Release-Locks 
    }
}
function Add-Driver {
    $FBD = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($FBD.ShowDialog() -eq "OK") {
        Release-Locks
        Log $TxtLogMod "Adding Drivers..."
        Start-Process "dism" -ArgumentList "/Image:`"$Global:MountDir`" /Add-Driver /Driver:`"$($FBD.SelectedPath)`" /Recurse /ScratchDir:`"$Global:ScratchDir`"" -Wait -NoNewWindow
        Log $TxtLogMod "Done."
    }
}
function Add-DesktopFile {
    $O = New-Object System.Windows.Forms.OpenFileDialog
    if ($O.ShowDialog() -eq "OK") {
        Copy-Item $O.FileName "$Global:MountDir\Users\Public\Desktop" -Force
        Log $TxtLogMod "File Added."
        Release-Locks
    }
}

$BtnBuild.Add_Click({
    if (!(Check-Tools)) { return }
    $S = New-Object System.Windows.Forms.SaveFileDialog; $S.Filter="ISO|*.iso"; $S.FileName="NewWin.iso"
    if ($S.ShowDialog() -eq "OK") {
        $Form.Cursor="WaitCursor"
        Log $TxtLogMod "Unmounting..."
        
        if (Smart-Unmount $true) {
            Log $TxtLogMod "Building ISO..."
            $Osc = "$ToolsDir\oscdimg.exe"
            $Boot = "2#p0,e,b`"$Global:ExtractDir\boot\etfsboot.com`"#pEF,e,b`"$Global:ExtractDir\efi\microsoft\boot\efisys.bin`""
            Start-Process $Osc -ArgumentList "-bootdata:$Boot -u2 -udfver102 `"$Global:ExtractDir`" `"$S.FileName`"" -Wait -NoNewWindow
            
            Log $TxtLogMod "SUCCESS! File: $($S.FileName)" "INFO"
            [System.Windows.Forms.MessageBox]::Show("Xong!"); Invoke-Item (Split-Path $S.FileName)
            $GbAct.Enabled=$false; $BtnBuild.Enabled=$false
        } else {
            [System.Windows.Forms.MessageBox]::Show("Unmount Failed.", "Error")
        }
        $Form.Cursor="Default"
    }
})

if ($CboDrives.Items.Count -gt 0) { Update-Workspace }
$Form.ShowDialog() | Out-Null
