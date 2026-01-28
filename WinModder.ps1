<#
    WINDOWS MODDER STUDIO - PHAT TAN PC
    Version: 6.0 (Hybrid Engine: Wimlib + DISM Fallback)
    Technique: Native VSS (Wimlib) / Manual VSS (DISM)
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
    if ($Type -eq "WARN") { $Color = "Yellow" }
    
    $Box.AppendText("[$Time] [$Type] $Msg`r`n")
    $Box.ScrollToCaret()
    $StatusLbl.Text = "Status: $Msg"
    [System.Windows.Forms.Application]::DoEvents()
}

# --- HÀM KIỂM TRA & TẢI WIMLIB (CÓ CHECK MẠNG) ---
function Check-Wimlib {
    $WimlibZip = "$ToolsDir\wimlib.zip"
    $WimlibExe = "$ToolsDir\wimlib-imagex.exe"
    $DllFile   = "$ToolsDir\libwim-15.dll"

    # 1. Nếu đã có file offline -> Dùng luôn
    if ((Test-Path $WimlibExe) -and (Test-Path $DllFile)) { return $true }
    
    # 2. Nếu chưa có -> Check mạng để tải
    Log $TxtLogCap "Đang kiểm tra kết nối mạng để tải Wimlib..." "INFO"
    try {
        $test = [System.Net.Dns]::GetHostEntry("google.com")
        Log $TxtLogCap "Có mạng! Đang tải Wimlib Engine..." "INFO"
        
        $Url = "https://wimlib.net/downloads/wimlib-1.14.4-windows-x86_64-bin.zip"
        if (!(Test-Path $ToolsDir)) { New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null }
        (New-Object System.Net.WebClient).DownloadFile($Url, $WimlibZip)
        
        Expand-Archive $WimlibZip -DestinationPath "$ToolsDir\wimlib_temp" -Force
        Get-ChildItem -Path "$ToolsDir\wimlib_temp" -Filter "wimlib-imagex.exe" -Recurse | Copy-Item -Destination $WimlibExe
        Get-ChildItem -Path "$ToolsDir\wimlib_temp" -Filter "libwim-15.dll" -Recurse | Copy-Item -Destination $ToolsDir
        
        return $true
    } catch { 
        Log $TxtLogCap "KHÔNG CÓ MẠNG hoặc Lỗi tải! Sẽ chuyển sang dùng DISM (Offline Mode)." "WARN"
        return $false 
    }
}

# --- HÀM TẠO CONFIG CHO DISM (KHI FALLBACK) ---
function Create-DismConfig {
    if (!(Test-Path $ToolsDir)) { New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null }
    $ConfigPath = "$ToolsDir\WimScript.ini"
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
"@
    [System.IO.File]::WriteAllText($ConfigPath, $Content)
    return $ConfigPath
}

# =========================================================================================
# VSS CORE FUNCTIONS (DÙNG CHO DISM MODE)
# =========================================================================================

function Create-ShadowCopy {
    param($DriveLetter, $MountPoint, $Box)
    $SW = [System.Diagnostics.Stopwatch]::StartNew()
    Log $Box "BẮT ĐẦU: Khởi tạo VSS Snapshot (Manual Mode)..." "VSS"
    try {
        $WmiClass = [WMICLASS]"root\cimv2:Win32_ShadowCopy"
        $Result = $WmiClass.Create($DriveLetter, "ClientAccessible")
        if ($Result.ReturnValue -ne 0) { Log $Box "Lỗi tạo VSS: $($Result.ReturnValue)" "ERR"; return $false }
        
        $Global:CurrentShadowID = $Result.ShadowID
        $Snapshot = Get-CimInstance -ClassName Win32_ShadowCopy -Filter "ID = '$($Global:CurrentShadowID)'"
        $DevicePath = $Snapshot.DeviceObject
        
        if (Test-Path $MountPoint) { Remove-Item $MountPoint -Force -ErrorAction SilentlyContinue }
        $CmdArgs = "/c mklink /d `"$MountPoint`" `"$DevicePath\`""
        Start-Process "cmd.exe" -ArgumentList $CmdArgs -NoNewWindow -Wait
        
        if (Test-Path "$MountPoint\Windows\System32") {
            Log $Box "VSS Ready! Time: $($SW.Elapsed.TotalSeconds)s" "SUCCESS"
            return $true
        }
        return $false
    } catch { Log $Box "VSS Exception: $($_.Exception.Message)" "ERR"; return $false }
}

function Cleanup-ShadowCopy {
    param($MountPoint, $Box)
    if (Test-Path $MountPoint) { cmd /c rmdir "$MountPoint" }
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
        # Link dự phòng nếu github lỗi
        $Url = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/refs/heads/main/oscdimg.exe"
        (New-Object System.Net.WebClient).DownloadFile($Url, $OscTarget)
        if ((Get-Item $OscTarget).Length -gt 100kb) { return $true }
    } catch {}
    
    # Nếu không tải được oscdimg thì hỏi user
    $Msg = "Thiếu 'oscdimg.exe'. Máy có mạng không?"; 
    if ([System.Windows.Forms.MessageBox]::Show($Msg, "Missing Tool", "YesNo") -eq "Yes") {
       # Logic tải ADK ở đây (giữ nguyên hoặc bỏ qua nếu muốn gọn)
       return $false 
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
    $Global:ShadowMount = "$Global:WorkDir\ShadowMount" 
    $LblWorkDir.Text = "Workspace: $Global:WorkDir"
}

function Prepare-Dirs {
    if (!(Test-Path $Global:WorkDir)) { New-Item -ItemType Directory -Path $Global:WorkDir -Force | Out-Null }
    if (!(Test-Path $Global:ScratchDir)) { New-Item -ItemType Directory -Path $Global:ScratchDir -Force | Out-Null }
    Grant-FullAccess $Global:WorkDir
}

# =========================================================================================
# GUI SETUP
# =========================================================================================
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WINDOWS MODDER STUDIO V7.0 (HYBRID ENGINE)"
$Form.Size = New-Object System.Drawing.Size(950, 750)
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
$Tabs = New-Object System.Windows.Forms.TabControl; $Tabs.Location = "20,100"; $Tabs.Size = "895,580"; $Tabs.Appearance = "FlatButtons"; $Form.Controls.Add($Tabs)
function Make-Tab ($T) { $P = New-Object System.Windows.Forms.TabPage; $P.Text = "  $T  "; $P.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 35); $Tabs.Controls.Add($P); return $P }
$TabCap = Make-Tab "1. CAPTURE OS (HYBRID)"; $TabMod = Make-Tab "2. MODDING ISO"

# --- TAB 1: CAPTURE ---
$GbCap = New-Object System.Windows.Forms.GroupBox; $GbCap.Text="CAPTURE SETTINGS"; $GbCap.Location="20,20"; $GbCap.Size="845,500"; $GbCap.ForeColor="Cyan"; $TabCap.Controls.Add($GbCap)

$LblC1 = New-Object System.Windows.Forms.Label; $LblC1.Text="Lưu file WIM tại:"; $LblC1.Location="30,40"; $LblC1.AutoSize=$true; $GbCap.Controls.Add($LblC1)
$TxtCapOut = New-Object System.Windows.Forms.TextBox; $TxtCapOut.Location="30,65"; $TxtCapOut.Size="650,25"; $TxtCapOut.Text="D:\PhatTan_Backup.wim"; $GbCap.Controls.Add($TxtCapOut)
$BtnCapBrowse = New-Object System.Windows.Forms.Button; $BtnCapBrowse.Text="CHỌN..."; $BtnCapBrowse.Location="700,63"; $BtnCapBrowse.Size="100,27"; $BtnCapBrowse.ForeColor="Black"; $GbCap.Controls.Add($BtnCapBrowse)

# -- DISM OPTIONS --
$LblComp = New-Object System.Windows.Forms.Label; $LblComp.Text="Mức nén (Dành cho DISM Fallback):"; $LblComp.Location="30,110"; $LblComp.AutoSize=$true; $GbCap.Controls.Add($LblComp)
$CboComp = New-Object System.Windows.Forms.ComboBox; $CboComp.Location="280,108"; $CboComp.Size="100,25"; $CboComp.DropDownStyle="DropDownList"
$CboComp.Items.Add("fast"); $CboComp.Items.Add("max"); $CboComp.SelectedIndex=1; $GbCap.Controls.Add($CboComp)
$LblHint = New-Object System.Windows.Forms.Label; $LblHint.Text="(Wimlib luôn dùng nén LZX siêu mạnh)"; $LblHint.Location="400,110"; $LblHint.AutoSize=$true; $LblHint.ForeColor="Gray"; $GbCap.Controls.Add($LblHint)

$BtnStartCap = New-Object System.Windows.Forms.Button; $BtnStartCap.Text="BẮT ĐẦU CAPTURE (AUTO WIMLIB / DISM)"; $BtnStartCap.Location="30,150"; $BtnStartCap.Size="770,50"; $BtnStartCap.BackColor="OrangeRed"; $BtnStartCap.ForeColor="White"; $BtnStartCap.Font="Segoe UI, 11, Bold"; $GbCap.Controls.Add($BtnStartCap)
$TxtLogCap = New-Object System.Windows.Forms.TextBox; $TxtLogCap.Multiline=$true; $TxtLogCap.Location="30,220"; $TxtLogCap.Size="770,250"; $TxtLogCap.BackColor="Black"; $TxtLogCap.ForeColor="Lime"; $TxtLogCap.ScrollBars="Vertical"; $TxtLogCap.ReadOnly=$true; $TxtLogCap.Font="Consolas, 9"; $GbCap.Controls.Add($TxtLogCap)

# --- TAB 2: MODDING (REBUILD ISO) ---
$GbSrc = New-Object System.Windows.Forms.GroupBox; $GbSrc.Text="SOURCE ISO"; $GbSrc.Location="20,20"; $GbSrc.Size="845,80"; $GbSrc.ForeColor="Yellow"; $TabMod.Controls.Add($GbSrc)
$TxtIsoSrc = New-Object System.Windows.Forms.TextBox; $TxtIsoSrc.Location="20,35"; $TxtIsoSrc.Size="650,25"; $GbSrc.Controls.Add($TxtIsoSrc)
$BtnIsoSrc = New-Object System.Windows.Forms.Button; $BtnIsoSrc.Text="MỞ ISO"; $BtnIsoSrc.Location="690,33"; $BtnIsoSrc.Size="120,27"; $BtnIsoSrc.ForeColor="Black"; $GbSrc.Controls.Add($BtnIsoSrc)

$GbAct = New-Object System.Windows.Forms.GroupBox; $GbAct.Text="MENU EDIT"; $GbAct.Location="20,110"; $GbAct.Size="845,300"; $GbAct.ForeColor="Lime"; $GbAct.Enabled=$false; $TabMod.Controls.Add($GbAct)
function Add-Btn ($T, $X, $Y, $C, $Fn) { $b=New-Object System.Windows.Forms.Button; $b.Text=$T; $b.Location="$X,$Y"; $b.Size="250,40"; $b.BackColor=$C; $b.ForeColor="Black"; $b.FlatStyle="Flat"; $b.Add_Click($Fn); $GbAct.Controls.Add($b) }
Add-Btn "1. MOUNT ISO" 30 30 "Cyan" { Start-Mount }; Add-Btn "2. ADD FOLDER" 30 80 "White" { Add-Folder }
Add-Btn "3. ADD DRIVERS" 30 130 "White" { Add-Driver }; Add-Btn "4. ADD DESKTOP FILE" 30 180 "White" { Add-DesktopFile }
Add-Btn "4.DỌN DẸP LỖI" 560 30 "Red" { Force-Cleanup }
Add-Btn "5. TẮT TÍNH NĂNG RÁC (DEBLOAT)" 30 230 "OrangeRed" { Optimize-Image }

$LblInfo = New-Object System.Windows.Forms.Label; $LblInfo.Text="STATUS: UNMOUNTED"; $LblInfo.Location="300,40"; $LblInfo.AutoSize=$true; $LblInfo.Font="Segoe UI, 10, Bold"; $GbAct.Controls.Add($LblInfo)
$TxtLogMod = New-Object System.Windows.Forms.TextBox; $TxtLogMod.Multiline=$true; $TxtLogMod.Location="300,80"; $TxtLogMod.Size="510,200"; $TxtLogMod.BackColor="Black"; $TxtLogMod.ForeColor="Cyan"; $TxtLogMod.ScrollBars="Vertical"; $TxtLogMod.ReadOnly=$true; $TxtLogMod.Font="Consolas, 9"; $GbAct.Controls.Add($TxtLogMod)

$BtnBuild = New-Object System.Windows.Forms.Button; $BtnBuild.Text="3. TẠO ISO MỚI (REBUILD)"; $BtnBuild.Location="20,420"; $BtnBuild.Size="845,60"; $BtnBuild.BackColor="Green"; $BtnBuild.ForeColor="White"; $BtnBuild.Font="Segoe UI, 14, Bold"; $BtnBuild.Enabled=$false; $TabMod.Controls.Add($BtnBuild)

# =========================================================================================
# LOGIC CORE
# =========================================================================================

$BtnCapBrowse.Add_Click({ $S=New-Object System.Windows.Forms.SaveFileDialog; $S.Filter="WIM File|*.wim"; $S.FileName="install.wim"; if($S.ShowDialog()-eq"OK"){$TxtCapOut.Text=$S.FileName} })

# --- MAIN CAPTURE LOGIC (HYBRID ENGINE) ---
$BtnStartCap.Add_Click({
    Update-Workspace; Prepare-Dirs
    $WimTarget = $TxtCapOut.Text
    $BtnStartCap.Enabled=$false; $Form.Cursor="WaitCursor"
    
    # --- PHASE 1: CHECK WIMLIB ---
    $UseWimlib = Check-Wimlib
    
    if ($UseWimlib) {
        # ==================== MODE 1: WIMLIB (NATIVE VSS) ====================
        Log $TxtLogCap ">>> CHẾ ĐỘ WIMLIB (ONLINE/CACHED) <<<" "INFO"
        
        $WimlibExe = "$ToolsDir\wimlib-imagex.exe"
        $WimConfigFile = "$ToolsDir\WimExcludes.ini"
        
        # Tạo Config
        $ConfigContent = @'
[ExclusionList]
\hiberfil.sys
\pagefile.sys
\swapfile.sys
\System Volume Information
\$Recycle.Bin
\Users\*\AppData\Local\Temp
\Config.Msi
'@
        [System.IO.File]::WriteAllText($WimConfigFile, $ConfigContent)

        # Build Args
        $WimArgs = @("capture", "C:", "$WimTarget", "PhatTan_OS", "Build_by_PhatTanPC", "--compress=LZX", "--check", "--threads=0", "--snapshot", "--config=$WimConfigFile")
        
        Log $TxtLogCap "Running: wimlib-imagex $($WimArgs -join ' ')" "DEBUG"
        
        try {
            $Proc = Start-Process -FilePath $WimlibExe -ArgumentList $WimArgs -Wait -NoNewWindow -PassThru
            if ($Proc.ExitCode -eq 0) {
                Log $TxtLogCap "Wimlib Capture SUCCESS!" "SUCCESS"
                [System.Windows.Forms.MessageBox]::Show("Capture Thành Công (Wimlib)!")
            } else {
                Log $TxtLogCap "Wimlib Failed (Code $($Proc.ExitCode))." "ERR"
            }
        } catch { Log $TxtLogCap "Exec Error: $($_.Exception.Message)" "ERR" }

    } else {
        # ==================== MODE 2: DISM (FALLBACK / OFFLINE) ====================
        Log $TxtLogCap ">>> CHẾ ĐỘ DISM (OFFLINE FALLBACK) <<<" "WARN"
        
        $CompMode = $CboComp.SelectedItem.ToString()
        Log $TxtLogCap "Mức nén đã chọn: $CompMode" "INFO"
        
        $ConfigFile = Create-DismConfig
        
        # 1. Tạo VSS thủ công
        $VssOk = Create-ShadowCopy "C:\" $Global:ShadowMount $TxtLogCap
        
        if ($VssOk) {
            # 2. DISM Capture
            Log $TxtLogCap "DISM đang chạy (Sẽ chậm hơn Wimlib)..." "INFO"
            
            # Ép ScratchDir để tránh tràn ổ C
            $DismArgs = "/Capture-Image /ImageFile:`"$WimTarget`" /CaptureDir:`"$Global:ShadowMount`" /Name:`"PhatTan_OS_DISM`" /Compress:$CompMode /ScratchDir:`"$Global:ScratchDir`" /ConfigFile:`"$ConfigFile`""
            
            $Proc = Start-Process "dism" -ArgumentList $DismArgs -Wait -NoNewWindow -PassThru
            
            if ($Proc.ExitCode -eq 0) {
                Log $TxtLogCap "DISM Capture SUCCESS!" "SUCCESS"
                [System.Windows.Forms.MessageBox]::Show("Capture Thành Công (DISM)!")
            } else {
                Log $TxtLogCap "DISM Failed (Code $($Proc.ExitCode))." "ERR"
            }
            
            Cleanup-ShadowCopy $Global:ShadowMount $TxtLogCap
        }
    }
    
    $BtnStartCap.Enabled=$true; $Form.Cursor="Default"
})

# --- MODDING & REBUILD LOGIC (GIỮ NGUYÊN NHƯ V5) ---
$BtnIsoSrc.Add_Click({ $O=New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="ISO|*.iso"; if($O.ShowDialog()-eq"OK"){$TxtIsoSrc.Text=$O.FileName; $GbAct.Enabled=$true} })
function Force-Cleanup {
    Start-Process "dism" -ArgumentList "/Cleanup-Wim" -Wait -NoNewWindow
    Start-Process "dism" -ArgumentList "/Unmount-Image /MountDir:`"$Global:MountDir`" /Discard" -Wait -NoNewWindow
    Remove-Item $Global:MountDir -Recurse -Force -ErrorAction SilentlyContinue
    Log $TxtLogMod "Cleaned."
}
function Start-Mount {
    $Iso = $TxtIsoSrc.Text; if (!(Test-Path $Iso)) { Log $TxtLogMod "Missing ISO!" "ERR"; return }
    Update-Workspace; Prepare-Dirs; $Form.Cursor="WaitCursor"; Force-Cleanup
    Ensure-Dir $Global:ExtractDir; Ensure-Dir $Global:MountDir
    Log $TxtLogMod "Mounting ISO..."
    Mount-DiskImage -ImagePath $Iso -StorageType ISO -ErrorAction SilentlyContinue | Out-Null
    $IsoDrive=$null; for($i=1;$i -le 5;$i++){try{$Vol=Get-DiskImage -ImagePath $Iso|Get-Volume -ErrorAction Stop;if($Vol.DriveLetter){$IsoDrive="$($Vol.DriveLetter):";break}}catch{};Start-Sleep 1}
    if(!$IsoDrive){$Cds=Get-WmiObject Win32_LogicalDisk -Filter "DriveType=5";foreach($c in $Cds){if(Test-Path "$($c.DeviceID)\sources\install.wim"){$IsoDrive=$c.DeviceID;break}}}
    if(!$IsoDrive){Log $TxtLogMod "Mount Failed!" "ERR";$Form.Cursor="Default";return}
    Log $TxtLogMod "Source found at $IsoDrive. Copying..."
    Copy-Item "$IsoDrive\*" $Global:ExtractDir -Recurse -Force
    Grant-FullAccess $Global:ExtractDir
    
    # ESD Logic
    $SrcW="$Global:ExtractDir\sources\install.wim"; $SrcE="$Global:ExtractDir\sources\install.esd"; $Tgt=$SrcW
    if(Test-Path $SrcE){Log $TxtLogMod "Converting ESD..."; Start-Process "dism" -ArgumentList "/Export-Image /SourceImageFile:`"$SrcE`" /SourceIndex:1 /DestinationImageFile:`"$SrcW`" /Compress:max" -Wait -NoNewWindow; Remove-Item $SrcE -Force}
    
    Log $TxtLogMod "Mounting WIM..."
    Grant-FullAccess $Tgt
    $P=Start-Process "dism" -ArgumentList "/Mount-Image /ImageFile:`"$Tgt`" /Index:1 /MountDir:`"$Global:MountDir`" /ScratchDir:`"$Global:ScratchDir`"" -Wait -NoNewWindow -PassThru
    if($P.ExitCode-eq 0){$LblInfo.Text="MOUNTED (RW)";$LblInfo.ForeColor="Lime";$BtnBuild.Enabled=$true;Log $TxtLogMod "Ready to Mod." "SUCCESS"}else{Log $TxtLogMod "Mount Error" "ERR"}
    $Form.Cursor="Default"
}
function Ensure-Dir($path) { if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null } }
function Add-Folder { $FBD=New-Object System.Windows.Forms.FolderBrowserDialog; if($FBD.ShowDialog()-eq"OK"){Copy-Item $FBD.SelectedPath $Global:MountDir -Recurse -Force; Log $TxtLogMod "Added Folder"} }
function Add-Driver { $FBD=New-Object System.Windows.Forms.FolderBrowserDialog; if($FBD.ShowDialog()-eq"OK"){Log $TxtLogMod "Injecting Drivers..."; Start-Process "dism" -ArgumentList "/Image:`"$Global:MountDir`" /Add-Driver /Driver:`"$($FBD.SelectedPath)`" /Recurse /ScratchDir:`"$Global:ScratchDir`"" -Wait -NoNewWindow; Log $TxtLogMod "Done"} }
function Add-DesktopFile { $O=New-Object System.Windows.Forms.OpenFileDialog; if($O.ShowDialog()-eq"OK"){Copy-Item $O.FileName "$Global:MountDir\Users\Public\Desktop" -Force; Log $TxtLogMod "Added File"} }
# --- HÀM HIỆN MENU CHỌN (CHECKLIST) ---
function Show-TweakMenu {
    $TweakForm = New-Object System.Windows.Forms.Form
    $TweakForm.Text = "MENU TỐI ƯU HÓA (DEBLOAT)"
    $TweakForm.Size = New-Object System.Drawing.Size(450, 500)
    $TweakForm.StartPosition = "CenterScreen"
    $TweakForm.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 45)
    $TweakForm.ForeColor = "White"

    $Lbl = New-Object System.Windows.Forms.Label
    $Lbl.Text = "Chọn các thành phần muốn TẮT hoặc XÓA:"
    $Lbl.Location = "10, 10"; $Lbl.AutoSize = $true
    $TweakForm.Controls.Add($Lbl)

    # CheckedListBox để chọn nhiều món
    $CLB = New-Object System.Windows.Forms.CheckedListBox
    $CLB.Location = "10, 40"; $CLB.Size = "410, 350"
    $CLB.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 65)
    $CLB.ForeColor = "Cyan"
    $CLB.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    
    # --- DANH SÁCH MÓN ĂN CHƠI ---
    $CLB.Items.Add("1. Xóa Apps Rác (Bing, Zune, Maps, Solitaire...)") 
    $CLB.Items.Add("2. Tắt Telemetry (Theo dõi người dùng)")
    $CLB.Items.Add("3. Tắt Cortana & Web Search (Tiết kiệm RAM)")
    $CLB.Items.Add("4. Tắt Windows Defender (Cơ bản - RegEdit)")
    $CLB.Items.Add("5. Tắt Windows Update (Chặn cập nhật tự động)")
    $CLB.Items.Add("6. Tắt OneDrive (Không cho khởi động cùng Win)")
    $CLB.Items.Add("7. Tắt Action Center (Thông báo bên phải)")
    $CLB.Items.Add("8. Bật Windows Photo Viewer cũ (Xem ảnh nhanh)")

    # Check sẵn mấy cái cơ bản an toàn
    $CLB.SetItemChecked(0, $true) # Apps
    $CLB.SetItemChecked(1, $true) # Telemetry
    $CLB.SetItemChecked(2, $true) # Cortana

    $TweakForm.Controls.Add($CLB)

    $BtnOK = New-Object System.Windows.Forms.Button
    $BtnOK.Text = "THỰC HIỆN"; $BtnOK.DialogResult = "OK"
    $BtnOK.Location = "10, 410"; $BtnOK.Size = "200, 40"
    $BtnOK.BackColor = "Green"; $BtnOK.ForeColor = "White"
    $TweakForm.Controls.Add($BtnOK)

    $BtnCancel = New-Object System.Windows.Forms.Button
    $BtnCancel.Text = "HỦY BỎ"; $BtnCancel.DialogResult = "Cancel"
    $BtnCancel.Location = "220, 410"; $BtnCancel.Size = "190, 40"
    $BtnCancel.BackColor = "Red"; $BtnCancel.ForeColor = "White"
    $TweakForm.Controls.Add($BtnCancel)

    if ($TweakForm.ShowDialog() -eq "OK") {
        return $CLB.CheckedItems
    }
    return $null
}

# --- HÀM XỬ LÝ CHÍNH (THAY THẾ HÀM CŨ) ---
function Optimize-Image {
    if (!(Test-Path "$Global:MountDir\Windows")) { 
        Log $TxtLogMod "Chưa Mount WIM! Hãy chạy bước 1 trước." "ERR"; return 
    }

    # 1. Gọi Menu lên cho người dùng chọn
    $SelectedTweaks = Show-TweakMenu
    if ($SelectedTweaks -eq $null) { return } # Nếu bấm Hủy thì thôi

    $Form.Cursor="WaitCursor"
    Log $TxtLogMod "--- BẮT ĐẦU TỐI ƯU HÓA THEO YÊU CẦU ---" "INFO"

    # 2. XỬ LÝ CÁC MỤC LIÊN QUAN ĐẾN APP (KHÔNG CẦN REGISTRY LOAD)
    if ($SelectedTweaks -contains "1. Xóa Apps Rác (Bing, Zune, Maps, Solitaire...)") {
        Log $TxtLogMod "Đang xóa Apps rác..." "INFO"
        $BloatApps = @("BingWeather", "BingNews", "GetHelp", "Getstarted", "Messaging", "Microsoft3DViewer", "MicrosoftOfficeHub", "MicrosoftSolitaireCollection", "OneConnect", "People", "SkypeApp", "WindowsFeedbackHub", "WindowsMaps", "YourPhone", "ZuneMusic", "ZuneVideo")
        foreach ($App in $BloatApps) {
            Get-AppxProvisionedPackage -Path $Global:MountDir | Where-Object { $_.DisplayName -like "*$App*" } | ForEach-Object {
                Remove-AppxProvisionedPackage -Path $Global:MountDir -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null
            }
        }
        Log $TxtLogMod "-> Đã xóa Apps xong." "DEBUG"
    }

    # 3. XỬ LÝ CÁC MỤC LIÊN QUAN ĐẾN REGISTRY
    # Chỉ load Registry nếu có chọn các mục tweak
    $NeedReg = $false
    foreach ($item in $SelectedTweaks) { if ($item -ne "1. Xóa Apps Rác (Bing, Zune, Maps, Solitaire...)") { $NeedReg = $true } }

    if ($NeedReg) {
        Log $TxtLogMod "Đang load Registry (SOFTWARE Hive)..." "INFO"
        reg load HKLM\WIM_SOFT "$Global:MountDir\Windows\System32\config\SOFTWARE" | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            
            # --- Tweak 2: Telemetry ---
            if ($SelectedTweaks -contains "2. Tắt Telemetry (Theo dõi người dùng)") {
                Log $TxtLogMod "-> Tắt Telemetry..."
                reg add "HKLM\WIM_SOFT\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f | Out-Null
            }

            # --- Tweak 3: Cortana ---
            if ($SelectedTweaks -contains "3. Tắt Cortana & Web Search (Tiết kiệm RAM)") {
                Log $TxtLogMod "-> Tắt Cortana..."
                reg add "HKLM\WIM_SOFT\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f | Out-Null
                reg add "HKLM\WIM_SOFT\Policies\Microsoft\Windows\Windows Search" /v DisableWebSearch /t REG_DWORD /d 1 /f | Out-Null
            }

            # --- Tweak 4: Defender (Soft Disable) ---
            if ($SelectedTweaks -contains "4. Tắt Windows Defender (Cơ bản - RegEdit)") {
                Log $TxtLogMod "-> Tắt Windows Defender (Reg)..."
                reg add "HKLM\WIM_SOFT\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f | Out-Null
            }

            # --- Tweak 5: Windows Update ---
            if ($SelectedTweaks -contains "5. Tắt Windows Update (Chặn cập nhật tự động)") {
                Log $TxtLogMod "-> Tắt Auto Update..."
                reg add "HKLM\WIM_SOFT\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f | Out-Null
            }

            # --- Tweak 6: OneDrive ---
            if ($SelectedTweaks -contains "6. Tắt OneDrive (Không cho khởi động cùng Win)") {
                Log $TxtLogMod "-> Chặn OneDrive Setup..."
                reg add "HKLM\WIM_SOFT\Policies\Microsoft\Windows\OneDrive" /v DisableFileSyncNGSC /t REG_DWORD /d 1 /f | Out-Null
            }
            
            # --- Tweak 8: Photo Viewer ---
            if ($SelectedTweaks -contains "8. Bật Windows Photo Viewer cũ (Xem ảnh nhanh)") {
                Log $TxtLogMod "-> Kích hoạt Classic Photo Viewer..."
                # (Phần này code hơi dài nên tôi dùng lệnh kích hoạt cơ bản của File Association)
                reg add "HKLM\WIM_SOFT\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".jpg" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f | Out-Null
                reg add "HKLM\WIM_SOFT\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".png" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f | Out-Null
            }

            # Unload Registry
            reg unload HKLM\WIM_SOFT | Out-Null
            Log $TxtLogMod "Đã lưu cấu hình Registry." "SUCCESS"
        } else {
            Log $TxtLogMod "Lỗi Load Registry! Không thể Tweak." "ERR"
        }
    }
    
    Log $TxtLogMod "--- HOÀN TẤT TỐI ƯU ---" "SUCCESS"
    [System.Windows.Forms.MessageBox]::Show("Xử lý xong các yêu cầu!")
    $Form.Cursor="Default"
}
# --- REBUILD ISO (TAB 2) ---
$BtnBuild.Add_Click({
    if (!(Check-Tools)) { return }
    $Osc = "$ToolsDir\oscdimg.exe"
    if (!(Test-Path "$Global:ExtractDir\boot\etfsboot.com")) { [System.Windows.Forms.MessageBox]::Show("Chưa có Source! Mount ISO trước."); return }
    $S = New-Object System.Windows.Forms.SaveFileDialog; $S.Filter = "ISO Image|*.iso"; $S.FileName = "PhatTan_WinLite.iso"; if ($S.ShowDialog() -ne "OK") { return }
    
    $BtnBuild.Enabled=$false; $Form.Cursor="WaitCursor"
    Log $TxtLogMod "Đang chuẩn bị đóng gói..." "INFO"

    # Replace WIM
    $MyWim = $TxtCapOut.Text
    if (Test-Path $MyWim) { Log $TxtLogMod "Tích hợp file WIM của ông ($MyWim)..." "INFO"; Copy-Item $MyWim "$Global:ExtractDir\sources\install.wim" -Force }
    else { Log $TxtLogMod "Không thấy file Capture. Dùng file gốc." "WARN" }

    # Create ISO
    $BootCmd = "2#p0,e,b`"$Global:ExtractDir\boot\etfsboot.com`"#pEF,e,b`"$Global:ExtractDir\efi\microsoft\boot\efisys.bin`""
    $IsoArgs = @("-bootdata:$BootCmd", "-u2", "-udfver102", "-lPhatTan_Win", "`"$Global:ExtractDir`"", "`"$($S.FileName)`"")
    
    Log $TxtLogMod "Đang chạy oscdimg..." "DEBUG"
    $P = Start-Process $Osc -ArgumentList $IsoArgs -Wait -NoNewWindow -PassThru
    
    if ($P.ExitCode -eq 0) {
        Log $TxtLogMod "ISO Created: $($S.FileName)" "SUCCESS"
        [System.Windows.Forms.MessageBox]::Show("Tạo ISO Thành Công!")
        Invoke-Item (Split-Path $S.FileName)
    } else { Log $TxtLogMod "Lỗi oscdimg: $($P.ExitCode)" "ERR" }
    
    $BtnBuild.Enabled=$true; $Form.Cursor="Default"
})

if ($CboDrives.Items.Count -gt 0) { Update-Workspace }; $Form.ShowDialog() | Out-Null
