<#
    WINDOWS MODDER STUDIO - PHAT TAN PC
    Version: 7.0 (Async Engine + Anti-Registry Lock + VSS Garbage Collector)
    Technique: Native VSS (Wimlib) / Manual VSS (DISM) with Multi-threading
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

# --- HÀM TẠO CONFIG CHO DISM ---
function Create-DismConfig {
    if (!(Test-Path $ToolsDir)) { New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null }
    $ConfigPath = "$ToolsDir\WimScript.ini"
    $Content = "[ExclusionList]`n\$ntfs.log`n\hiberfil.sys`n\pagefile.sys`n\swapfile.sys`n\System Volume Information`n\RECYCLER`n\$Recycle.Bin`n\Windows\CSC`n\DumpStack.log.tmp`n\Config.Msi`n\Windows\SoftwareDistribution`n\Users\*\AppData\Local\Temp"
    [System.IO.File]::WriteAllText($ConfigPath, $Content)
    return $ConfigPath
}

# --- HÀM DỌN VSS RÁC TOÀN HỆ THỐNG ---
function Clean-OrphanedVSS {
    # Quét các VSS do tool tạo ra mà quên chưa xóa (thường mang cờ ClientAccessible)
    $Orphans = Get-WmiObject Win32_ShadowCopy | Where-Object { $_.ClientAccessible -eq $true }
    foreach ($vss in $Orphans) {
        try { $vss.Delete() | Out-Null } catch {}
    }
}

# =========================================================================================
# GUI SETUP (KHUNG GIAO DIỆN)
# =========================================================================================
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WINDOWS MODDER STUDIO V7.0 (ASYNC & ANTI-LOCK ENGINE)"
$Form.Size = New-Object System.Drawing.Size(950, 750)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 35)
$Form.ForeColor = "WhiteSmoke"
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

# Header
$PanelTop = New-Object System.Windows.Forms.Panel; $PanelTop.Dock="Top"; $PanelTop.Height=80; $PanelTop.BackColor=[System.Drawing.Color]::FromArgb(45,45,50); $Form.Controls.Add($PanelTop)
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "PHAT TAN PC - SYSTEM BUILDER"; $LblT.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold); $LblT.ForeColor = "Gold"; $LblT.AutoSize = $true; $LblT.Location = "20,10"; $PanelTop.Controls.Add($LblT)

# Drive Selector
$LblSel = New-Object System.Windows.Forms.Label; $LblSel.Text = "Chọn ổ Workspace (Nơi chứa file tạm):"; $LblSel.Location = "20, 50"; $LblSel.AutoSize=$true; $PanelTop.Controls.Add($LblSel)
$CboDrives = New-Object System.Windows.Forms.ComboBox; $CboDrives.Location = "300, 48"; $CboDrives.Size = "150, 25"; $CboDrives.DropDownStyle = "DropDownList"; $PanelTop.Controls.Add($CboDrives)
$Drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }; foreach ($D in $Drives) { $CboDrives.Items.Add("$($D.DeviceID) (Free: $([Math]::Round($D.FreeSpace/1GB,1)) GB)") | Out-Null }
$LblWorkDir = New-Object System.Windows.Forms.Label; $LblWorkDir.Text = "..."; $LblWorkDir.Location = "470, 50"; $LblWorkDir.AutoSize=$true; $LblWorkDir.ForeColor="Lime"; $PanelTop.Controls.Add($LblWorkDir)

function Update-Workspace {
    if ($CboDrives.SelectedIndex -ge 0) {
        $SelDrive = $CboDrives.SelectedItem.ToString().Split(" ")[0]
        $Global:WorkDir     = "$SelDrive\WinMod_Temp"
        $Global:MountDir    = "$Global:WorkDir\Mount"
        $Global:ExtractDir  = "$Global:WorkDir\Source"
        $Global:CaptureDir  = "$Global:WorkDir\Capture"
        $Global:ScratchDir  = "$Global:WorkDir\Scratch"
        $Global:ShadowMount = "$Global:WorkDir\ShadowMount" 
        $LblWorkDir.Text = "Workspace: $Global:WorkDir"
    }
}
if ($CboDrives.Items.Count -gt 0) { $CboDrives.SelectedIndex = 0; Update-Workspace }
$CboDrives.Add_SelectedIndexChanged({ Update-Workspace })

# Tabs
$Tabs = New-Object System.Windows.Forms.TabControl; $Tabs.Location = "20,100"; $Tabs.Size = "895,580"; $Tabs.Appearance = "FlatButtons"; $Form.Controls.Add($Tabs)
function Make-Tab ($T) { $P = New-Object System.Windows.Forms.TabPage; $P.Text = "  $T  "; $P.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 35); $Tabs.Controls.Add($P); return $P }
$TabCap = Make-Tab "1. CAPTURE OS (HYBRID)"; $TabMod = Make-Tab "2. MODDING ISO"

# --- TAB 1: CAPTURE ---
$GbCap = New-Object System.Windows.Forms.GroupBox; $GbCap.Text="CAPTURE SETTINGS"; $GbCap.Location="20,20"; $GbCap.Size="845,500"; $GbCap.ForeColor="Cyan"; $TabCap.Controls.Add($GbCap)
$LblC1 = New-Object System.Windows.Forms.Label; $LblC1.Text="Lưu file WIM tại:"; $LblC1.Location="30,40"; $LblC1.AutoSize=$true; $GbCap.Controls.Add($LblC1)
$TxtCapOut = New-Object System.Windows.Forms.TextBox; $TxtCapOut.Location="30,65"; $TxtCapOut.Size="650,25"; $TxtCapOut.Text="D:\PhatTan_Backup.wim"; $GbCap.Controls.Add($TxtCapOut)
$BtnCapBrowse = New-Object System.Windows.Forms.Button; $BtnCapBrowse.Text="CHỌN..."; $BtnCapBrowse.Location="700,63"; $BtnCapBrowse.Size="100,27"; $BtnCapBrowse.ForeColor="Black"; $GbCap.Controls.Add($BtnCapBrowse)
$BtnCapBrowse.Add_Click({ $S=New-Object System.Windows.Forms.SaveFileDialog; $S.Filter="WIM File|*.wim"; $S.FileName="install.wim"; if($S.ShowDialog()-eq"OK"){$TxtCapOut.Text=$S.FileName} })

$LblComp = New-Object System.Windows.Forms.Label; $LblComp.Text="Mức nén (Dành cho DISM Fallback):"; $LblComp.Location="30,110"; $LblComp.AutoSize=$true; $GbCap.Controls.Add($LblComp)
$CboComp = New-Object System.Windows.Forms.ComboBox; $CboComp.Location="280,108"; $CboComp.Size="100,25"; $CboComp.DropDownStyle="DropDownList"; $CboComp.Items.Add("fast"); $CboComp.Items.Add("max"); $CboComp.SelectedIndex=1; $GbCap.Controls.Add($CboComp)

$BtnStartCap = New-Object System.Windows.Forms.Button; $BtnStartCap.Text="BẮT ĐẦU CAPTURE (AUTO WIMLIB / DISM)"; $BtnStartCap.Location="30,150"; $BtnStartCap.Size="770,50"; $BtnStartCap.BackColor="OrangeRed"; $BtnStartCap.ForeColor="White"; $BtnStartCap.Font="Segoe UI, 11, Bold"; $GbCap.Controls.Add($BtnStartCap)
$TxtLogCap = New-Object System.Windows.Forms.TextBox; $TxtLogCap.Multiline=$true; $TxtLogCap.Location="30,220"; $TxtLogCap.Size="770,250"; $TxtLogCap.BackColor="Black"; $TxtLogCap.ForeColor="Lime"; $TxtLogCap.ScrollBars="Vertical"; $TxtLogCap.ReadOnly=$true; $TxtLogCap.Font="Consolas, 9"; $GbCap.Controls.Add($TxtLogCap)

# --- TAB 2: MODDING ---
$GbSrc = New-Object System.Windows.Forms.GroupBox; $GbSrc.Text="SOURCE ISO"; $GbSrc.Location="20,20"; $GbSrc.Size="845,80"; $GbSrc.ForeColor="Yellow"; $TabMod.Controls.Add($GbSrc)
$TxtIsoSrc = New-Object System.Windows.Forms.TextBox; $TxtIsoSrc.Location="20,35"; $TxtIsoSrc.Size="650,25"; $GbSrc.Controls.Add($TxtIsoSrc)
$BtnIsoSrc = New-Object System.Windows.Forms.Button; $BtnIsoSrc.Text="MỞ ISO"; $BtnIsoSrc.Location="690,33"; $BtnIsoSrc.Size="120,27"; $BtnIsoSrc.ForeColor="Black"; $GbSrc.Controls.Add($BtnIsoSrc)
$BtnIsoSrc.Add_Click({ $O=New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="ISO|*.iso"; if($O.ShowDialog()-eq"OK"){$TxtIsoSrc.Text=$O.FileName; $GbAct.Enabled=$true} })

$GbAct = New-Object System.Windows.Forms.GroupBox; $GbAct.Text="MENU EDIT"; $GbAct.Location="20,110"; $GbAct.Size="845,300"; $GbAct.ForeColor="Lime"; $GbAct.Enabled=$false; $TabMod.Controls.Add($GbAct)
function Add-Btn ($T, $X, $Y, $C, $Fn) { $b=New-Object System.Windows.Forms.Button; $b.Text=$T; $b.Location="$X,$Y"; $b.Size="250,40"; $b.BackColor=$C; $b.ForeColor="Black"; $b.FlatStyle="Flat"; $b.Add_Click($Fn); $GbAct.Controls.Add($b); return $b }

$BtnMnt = Add-Btn "1. MOUNT ISO" 30 30 "Cyan" { Async-Mount }
$BtnAddF = Add-Btn "2. ADD FOLDER" 30 80 "White" { $FBD=New-Object System.Windows.Forms.FolderBrowserDialog; if($FBD.ShowDialog()-eq"OK"){Copy-Item $FBD.SelectedPath $Global:MountDir -Recurse -Force; [System.Windows.Forms.MessageBox]::Show("Added Folder!")} }
$BtnAddD = Add-Btn "3. ADD DRIVERS" 30 130 "White" { Async-AddDriver }
$BtnAddX = Add-Btn "4. ADD DESKTOP FILE" 30 180 "White" { $O=New-Object System.Windows.Forms.OpenFileDialog; if($O.ShowDialog()-eq"OK"){Copy-Item $O.FileName "$Global:MountDir\Users\Public\Desktop" -Force; [System.Windows.Forms.MessageBox]::Show("Added File!")} }
$BtnDbl = Add-Btn "5. TỐI ƯU (DEBLOAT)" 30 230 "OrangeRed" { Async-Optimize }
$BtnCln = Add-Btn "6. DỌN RÁC & CỨU LỖI" 560 30 "Red" { Async-Cleanup }

$LblInfo = New-Object System.Windows.Forms.Label; $LblInfo.Text="STATUS: UNMOUNTED"; $LblInfo.Location="300,40"; $LblInfo.AutoSize=$true; $LblInfo.Font="Segoe UI, 10, Bold"; $GbAct.Controls.Add($LblInfo)
$TxtLogMod = New-Object System.Windows.Forms.TextBox; $TxtLogMod.Multiline=$true; $TxtLogMod.Location="300,80"; $TxtLogMod.Size="510,200"; $TxtLogMod.BackColor="Black"; $TxtLogMod.ForeColor="Cyan"; $TxtLogMod.ScrollBars="Vertical"; $TxtLogMod.ReadOnly=$true; $TxtLogMod.Font="Consolas, 9"; $GbAct.Controls.Add($TxtLogMod)

$BtnBuild = New-Object System.Windows.Forms.Button; $BtnBuild.Text="TẠO ISO MỚI (REBUILD)"; $BtnBuild.Location="20,420"; $BtnBuild.Size="845,60"; $BtnBuild.BackColor="Green"; $BtnBuild.ForeColor="White"; $BtnBuild.Font="Segoe UI, 14, Bold"; $BtnBuild.Enabled=$false; $TabMod.Controls.Add($BtnBuild)
$BtnBuild.Add_Click({ Async-Rebuild })

# =========================================================================================
# THREAD-SAFE SYNC HASH
# =========================================================================================
$Global:SyncHash = [hashtable]::Synchronized(@{
    TxtCap = $TxtLogCap; TxtMod = $TxtLogMod; LblInfo = $LblInfo
    BtnCap = $BtnStartCap; BtnMnt = $BtnMnt; BtnBld = $BtnBuild
    BtnDbl = $BtnDbl; BtnCln = $BtnCln; Form = $Form
})

# =========================================================================================
# LUỒNG CHẠY NGẦM (RUNSPACES) - CHỐNG ĐƠ GUI
# =========================================================================================

# --- 1. CAPTURE OS (ASYNC) ---
$BtnStartCap.Add_Click({
    Update-Workspace; Clean-OrphanedVSS
    if (!(Test-Path $Global:WorkDir)) { New-Item -ItemType Directory -Path $Global:WorkDir -Force | Out-Null }
    if (!(Test-Path $Global:ScratchDir)) { New-Item -ItemType Directory -Path $Global:ScratchDir -Force | Out-Null }
    
    $WimTarget = $TxtCapOut.Text; $CompMode = $CboComp.SelectedItem.ToString()
    $BtnStartCap.Enabled = $false; $BtnStartCap.Text = "ĐANG CAPTURE... VUI LÒNG ĐỢI!"
    
    $Global:SyncHash.Target = $WimTarget; $Global:SyncHash.Comp = $CompMode
    $Global:SyncHash.ToolsDir = $ToolsDir; $Global:SyncHash.ShadowMount = $Global:ShadowMount
    $Global:SyncHash.ScratchDir = $Global:ScratchDir

    $Runspace = [runspacefactory]::CreateRunspace(); $Runspace.Open(); $Runspace.SessionStateProxy.SetVariable("Sync", $Global:SyncHash)
    $Pipeline = $Runspace.CreatePipeline()
    $Pipeline.Commands.AddScript({
        function LogBg ($Msg, $Type="INFO") {
            $Line = "[$([DateTime]::Now.ToString('HH:mm:ss'))] [$Type] $Msg`r`n"
            $Sync.TxtCap.Invoke([action]{ $Sync.TxtCap.AppendText($Line); $Sync.TxtCap.ScrollToCaret() })
        }

        # Check Wimlib
        $WimExe = "$($Sync.ToolsDir)\wimlib-imagex.exe"; $UseWimlib = $false
        if ((Test-Path $WimExe) -and (Test-Path "$($Sync.ToolsDir)\libwim-15.dll")) { $UseWimlib = $true }
        else {
            LogBg "Đang tải thư viện Wimlib..." "INFO"
            try {
                $Url = "https://wimlib.net/downloads/wimlib-1.14.4-windows-x86_64-bin.zip"
                (New-Object System.Net.WebClient).DownloadFile($Url, "$($Sync.ToolsDir)\wimlib.zip")
                Expand-Archive "$($Sync.ToolsDir)\wimlib.zip" -DestinationPath "$($Sync.ToolsDir)\wimlib_temp" -Force
                Copy-Item "$($Sync.ToolsDir)\wimlib_temp\*\wimlib-imagex.exe" $WimExe -Force
                Copy-Item "$($Sync.ToolsDir)\wimlib_temp\*\libwim-15.dll" $Sync.ToolsDir -Force
                $UseWimlib = $true
            } catch { LogBg "Lỗi tải Wimlib, chuyển sang DISM!" "WARN" }
        }

        if ($UseWimlib) {
            LogBg ">>> CHẠY CHẾ ĐỘ WIMLIB (SIÊU NHANH) <<<" "SUCCESS"
            $WimConf = "$($Sync.ToolsDir)\WimExcludes.ini"
            "[ExclusionList]`n\hiberfil.sys`n\pagefile.sys`n\swapfile.sys`n\System Volume Information`n\$Recycle.Bin" | Out-File $WimConf
            $Args = @("capture", "C:", $Sync.Target, "PhatTan_OS", "--compress=LZX", "--check", "--threads=0", "--snapshot", "--config=$WimConf")
            $Proc = Start-Process $WimExe -ArgumentList $Args -Wait -NoNewWindow -PassThru
            if ($Proc.ExitCode -eq 0) { LogBg "Wimlib Capture XONG!" "SUCCESS" } else { LogBg "Lỗi Wimlib: $($Proc.ExitCode)" "ERR" }
        } else {
            LogBg ">>> CHẠY CHẾ ĐỘ DISM (CÓ TẠO VSS) <<<" "WARN"
            $DismConf = "$($Sync.ToolsDir)\WimScript.ini"
            "[ExclusionList]`n\hiberfil.sys`n\pagefile.sys`n\swapfile.sys`n\System Volume Information`n\$Recycle.Bin" | Out-File $DismConf
            
            # Khởi tạo VSS
            LogBg "Đang tạo VSS Snapshot cho ổ C..." "VSS"
            $ShadowID = $null
            try {
                $WmiClass = [WMICLASS]"root\cimv2:Win32_ShadowCopy"
                $Res = $WmiClass.Create("C:\", "ClientAccessible")
                if ($Res.ReturnValue -eq 0) {
                    $ShadowID = $Res.ShadowID
                    $DevPath = (Get-CimInstance Win32_ShadowCopy -Filter "ID = '$ShadowID'").DeviceObject
                    if (Test-Path $Sync.ShadowMount) { cmd /c rmdir "`"$($Sync.ShadowMount)`"" }
                    cmd /c mklink /d "`"$($Sync.ShadowMount)`"" "`"$DevPath\`"" | Out-Null
                    LogBg "VSS Tạo thành công!" "SUCCESS"
                    
                    # Capture DISM
                    LogBg "Đang nén dữ liệu bằng DISM (Sẽ khá lâu)..." "INFO"
                    $Proc = Start-Process "dism" -ArgumentList "/Capture-Image /ImageFile:`"$($Sync.Target)`" /CaptureDir:`"$($Sync.ShadowMount)`" /Name:`"PhatTan_OS`" /Compress:$($Sync.Comp) /ScratchDir:`"$($Sync.ScratchDir)`" /ConfigFile:`"$DismConf`"" -Wait -NoNewWindow -PassThru
                    if ($Proc.ExitCode -eq 0) { LogBg "DISM Capture XONG!" "SUCCESS" } else { LogBg "Lỗi DISM: $($Proc.ExitCode)" "ERR" }
                } else { LogBg "Tạo VSS Thất bại ($($Res.ReturnValue))" "ERR" }
            } finally {
                # [QUAN TRỌNG] LUÔN DỌN VSS DÙ LỖI HAY KHÔNG
                if (Test-Path $Sync.ShadowMount) { cmd /c rmdir "`"$($Sync.ShadowMount)`"" }
                if ($ShadowID) { try { (Get-WmiObject Win32_ShadowCopy -Filter "ID='$ShadowID'").Delete() | Out-Null; LogBg "Đã xóa VSS rác an toàn." "VSS" } catch {} }
            }
        }
        
        $Sync.BtnCap.Invoke([action]{ $Sync.BtnCap.Enabled=$true; $Sync.BtnCap.Text="BẮT ĐẦU CAPTURE (AUTO WIMLIB / DISM)"; [System.Windows.Forms.MessageBox]::Show("Tiến trình Capture đã hoàn tất!") })
    }) | Out-Null; $Pipeline.InvokeAsync()
})

# --- 2. MOUNT ISO (ASYNC) ---
function Async-Mount {
    $Iso = $TxtIsoSrc.Text; if (!(Test-Path $Iso)) { Log $TxtLogMod "Missing ISO!" "ERR"; return }
    $BtnMnt.Enabled=$false; $BtnBuild.Enabled=$false; $BtnDbl.Enabled=$false
    Update-Workspace; if (!(Test-Path $Global:WorkDir)) { New-Item -ItemType Directory -Path $Global:WorkDir -Force | Out-Null }
    
    $Global:SyncHash.Iso = $Iso; $Global:SyncHash.MountDir = $Global:MountDir
    $Global:SyncHash.ExtractDir = $Global:ExtractDir; $Global:SyncHash.ScratchDir = $Global:ScratchDir

    $Runspace = [runspacefactory]::CreateRunspace(); $Runspace.Open(); $Runspace.SessionStateProxy.SetVariable("Sync", $Global:SyncHash)
    $Pipeline = $Runspace.CreatePipeline()
    $Pipeline.Commands.AddScript({
        function LogBg ($Msg, $Type="INFO") { $Line="[$([DateTime]::Now.ToString('HH:mm:ss'))] [$Type] $Msg`r`n"; $Sync.TxtMod.Invoke([action]{ $Sync.TxtMod.AppendText($Line); $Sync.TxtMod.ScrollToCaret() }) }
        
        LogBg "Đang dọn dẹp thư mục cũ (Cleanup)..."
        cmd /c "dism /Cleanup-Wim >nul 2>&1"
        cmd /c "dism /Unmount-Image /MountDir:`"$($Sync.MountDir)`" /Discard >nul 2>&1"
        Remove-Item $Sync.ExtractDir -Recurse -Force -ErrorAction SilentlyContinue; New-Item $Sync.ExtractDir -ItemType Directory -Force | Out-Null
        Remove-Item $Sync.MountDir -Recurse -Force -ErrorAction SilentlyContinue; New-Item $Sync.MountDir -ItemType Directory -Force | Out-Null

        LogBg "Đang Mount ISO ảo..."
        Mount-DiskImage -ImagePath $Sync.Iso -StorageType ISO -ErrorAction SilentlyContinue | Out-Null
        $IsoDrive=$null; for($i=1;$i -le 5;$i++){try{$Vol=Get-DiskImage -ImagePath $Sync.Iso|Get-Volume -ErrorAction Stop;if($Vol.DriveLetter){$IsoDrive="$($Vol.DriveLetter):";break}}catch{};Start-Sleep 1}
        
        if ($IsoDrive) {
            LogBg "Đang copy mã nguồn từ $IsoDrive sang Workspace..."
            cmd /c "xcopy /E /H /Y /I `"$IsoDrive\*`" `"$($Sync.ExtractDir)\`" >nul 2>&1"
            Dismount-DiskImage -ImagePath $Sync.Iso | Out-Null

            $SrcW="$($Sync.ExtractDir)\sources\install.wim"; $SrcE="$($Sync.ExtractDir)\sources\install.esd"
            if(Test-Path $SrcE){
                LogBg "Phát hiện file ESD. Đang giải nén sang WIM..."
                cmd /c "dism /Export-Image /SourceImageFile:`"$SrcE`" /SourceIndex:1 /DestinationImageFile:`"$SrcW`" /Compress:max"
                Remove-Item $SrcE -Force
            }
            LogBg "Đang bung ruột WIM ra MountDir..."
            $P = Start-Process "dism" -ArgumentList "/Mount-Image /ImageFile:`"$SrcW`" /Index:1 /MountDir:`"$($Sync.MountDir)`" /ScratchDir:`"$($Sync.ScratchDir)`"" -Wait -NoNewWindow -PassThru
            if ($P.ExitCode -eq 0) {
                LogBg "MOUNT HOÀN TẤT! Đã sẵn sàng Modding." "SUCCESS"
                $Sync.LblInfo.Invoke([action]{ $Sync.LblInfo.Text="STATUS: MOUNTED (RW)"; $Sync.LblInfo.ForeColor="Lime" })
                $Sync.BtnBld.Invoke([action]{ $Sync.BtnBld.Enabled=$true }); $Sync.BtnDbl.Invoke([action]{ $Sync.BtnDbl.Enabled=$true })
            } else { LogBg "Lỗi bung WIM!" "ERR" }
        } else { LogBg "Không thể Mount ISO ảo." "ERR" }
        
        $Sync.BtnMnt.Invoke([action]{ $Sync.BtnMnt.Enabled=$true })
    }) | Out-Null; $Pipeline.InvokeAsync()
}

# --- 3. FORCE CLEANUP & ANTI-REGISTRY LOCK (ASYNC) ---
function Async-Cleanup {
    $BtnCln.Enabled=$false
    Log $TxtLogMod "Đang thực thi lệnh Cứu hộ (Ép dọn dẹp Registry & MountDir)..." "WARN"
    
    $Global:SyncHash.MountDir = $Global:MountDir
    $Runspace = [runspacefactory]::CreateRunspace(); $Runspace.Open(); $Runspace.SessionStateProxy.SetVariable("Sync", $Global:SyncHash)
    $Pipeline = $Runspace.CreatePipeline()
    $Pipeline.Commands.AddScript({
        function LogBg ($Msg) { $Line="[$([DateTime]::Now.ToString('HH:mm:ss'))] [CLEAN] $Msg`r`n"; $Sync.TxtMod.Invoke([action]{ $Sync.TxtMod.AppendText($Line); $Sync.TxtMod.ScrollToCaret() }) }
        
        LogBg "1. Ép mở khóa Registry (Garbage Collector)..."
        [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers()
        cmd /c "reg unload HKLM\WIM_SOFT >nul 2>&1"
        cmd /c "reg unload HKLM\WIM_SYS >nul 2>&1"
        
        LogBg "2. Ép Unmount DISM..."
        cmd /c "dism /Unmount-Image /MountDir:`"$($Sync.MountDir)`" /Discard >nul 2>&1"
        cmd /c "dism /Cleanup-Wim >nul 2>&1"
        
        LogBg "3. Dọn rác VSS toàn hệ thống..."
        Get-WmiObject Win32_ShadowCopy | Where-Object { $_.ClientAccessible -eq $true } | ForEach-Object { try { $_.Delete() | Out-Null } catch {} }
        
        LogBg "HOÀN TẤT DỌN DẸP AN TOÀN."
        $Sync.LblInfo.Invoke([action]{ $Sync.LblInfo.Text="STATUS: UNMOUNTED/CLEANED"; $Sync.LblInfo.ForeColor="Silver" })
        $Sync.BtnCln.Invoke([action]{ $Sync.BtnCln.Enabled=$true })
    }) | Out-Null; $Pipeline.InvokeAsync()
}

# --- 4. TỐI ƯU HÓA DEBLOAT (ASYNC + ANTI-LOCK) ---
function Async-Optimize {
    if (!(Test-Path "$Global:MountDir\Windows")) { Log $TxtLogMod "Chưa Mount WIM!" "ERR"; return }
    
    # Hiện Menu Chọn Tweak trên luồng chính
    $TweakForm = New-Object System.Windows.Forms.Form; $TweakForm.Text="MENU DEBLOAT"; $TweakForm.Size="450, 480"; $TweakForm.StartPosition="CenterScreen"; $TweakForm.BackColor="40,40,45"; $TweakForm.ForeColor="White"
    $CLB = New-Object System.Windows.Forms.CheckedListBox; $CLB.Location="10,10"; $CLB.Size="410,360"; $CLB.BackColor="60,60,65"; $CLB.ForeColor="Cyan"; $CLB.Font="Segoe UI, 10"
    $CLB.Items.Add("1. Xóa Apps Rác (Bing, Zune, Maps...)"); $CLB.Items.Add("2. Tắt Telemetry (Theo dõi)"); $CLB.Items.Add("3. Tắt Cortana & Web Search")
    $CLB.Items.Add("4. Tắt Windows Defender"); $CLB.Items.Add("5. Tắt Windows Update"); $CLB.Items.Add("6. Tắt OneDrive"); $CLB.Items.Add("7. Bật Photo Viewer Cũ")
    $CLB.SetItemChecked(0,$true); $CLB.SetItemChecked(1,$true); $CLB.SetItemChecked(2,$true); $TweakForm.Controls.Add($CLB)
    $BtnOK=New-Object System.Windows.Forms.Button; $BtnOK.Text="THỰC HIỆN"; $BtnOK.DialogResult="OK"; $BtnOK.Location="10,390"; $BtnOK.Size="200,40"; $BtnOK.BackColor="Green"; $TweakForm.Controls.Add($BtnOK)
    $BtnCancel=New-Object System.Windows.Forms.Button; $BtnCancel.Text="HỦY BỎ"; $BtnCancel.DialogResult="Cancel"; $BtnCancel.Location="220,390"; $BtnCancel.Size="190,40"; $BtnCancel.BackColor="Red"; $TweakForm.Controls.Add($BtnCancel)
    if ($TweakForm.ShowDialog() -ne "OK") { return }
    $Tweaks = $CLB.CheckedItems

    $BtnDbl.Enabled=$false
    $Global:SyncHash.Tweaks = $Tweaks; $Global:SyncHash.MountDir = $Global:MountDir
    $Runspace = [runspacefactory]::CreateRunspace(); $Runspace.Open(); $Runspace.SessionStateProxy.SetVariable("Sync", $Global:SyncHash)
    $Pipeline = $Runspace.CreatePipeline()
    $Pipeline.Commands.AddScript({
        function LogBg ($Msg) { $Line="[$([DateTime]::Now.ToString('HH:mm:ss'))] [TWEAK] $Msg`r`n"; $Sync.TxtMod.Invoke([action]{ $Sync.TxtMod.AppendText($Line); $Sync.TxtMod.ScrollToCaret() }) }
        
        if ($Sync.Tweaks -contains "1. Xóa Apps Rác (Bing, Zune, Maps...)") {
            LogBg "Đang gỡ bỏ App rác..."
            $Bloat = @("Bing","Zune","SkypeApp","WindowsMaps","MicrosoftSolitaire","Microsoft3DViewer","FeedbackHub","YourPhone")
            foreach ($App in $Bloat) {
                Get-AppxProvisionedPackage -Path $Sync.MountDir | ? { $_.DisplayName -match $App } | % { Remove-AppxProvisionedPackage -Path $Sync.MountDir -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null }
            }
            LogBg "Xong phần Appx."
        }

        # [QUAN TRỌNG] TRY/FINALLY CHO REGISTRY
        $NeedReg = ($Sync.Tweaks.Count -gt 0)
        if ($NeedReg) {
            LogBg "Đang Load Registry Hive..."
            cmd /c "reg load HKLM\WIM_SOFT `"$($Sync.MountDir)\Windows\System32\config\SOFTWARE`" >nul 2>&1"
            
            try {
                if ($Sync.Tweaks -contains "2. Tắt Telemetry (Theo dõi)") {
                    cmd /c "reg add `"HKLM\WIM_SOFT\Policies\Microsoft\Windows\DataCollection`" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1"
                    LogBg "Đã tắt Telemetry."
                }
                if ($Sync.Tweaks -contains "3. Tắt Cortana & Web Search") {
                    cmd /c "reg add `"HKLM\WIM_SOFT\Policies\Microsoft\Windows\Windows Search`" /v AllowCortana /t REG_DWORD /d 0 /f >nul 2>&1"
                    cmd /c "reg add `"HKLM\WIM_SOFT\Policies\Microsoft\Windows\Windows Search`" /v DisableWebSearch /t REG_DWORD /d 1 /f >nul 2>&1"
                    LogBg "Đã tắt Cortana."
                }
                if ($Sync.Tweaks -contains "4. Tắt Windows Defender") {
                    cmd /c "reg add `"HKLM\WIM_SOFT\Policies\Microsoft\Windows Defender`" /v DisableAntiSpyware /t REG_DWORD /d 1 /f >nul 2>&1"
                    LogBg "Đã tắt Defender."
                }
                if ($Sync.Tweaks -contains "5. Tắt Windows Update") {
                    cmd /c "reg add `"HKLM\WIM_SOFT\Policies\Microsoft\Windows\WindowsUpdate\AU`" /v NoAutoUpdate /t REG_DWORD /d 1 /f >nul 2>&1"
                    LogBg "Đã tắt Auto Update."
                }
                if ($Sync.Tweaks -contains "6. Tắt OneDrive") {
                    cmd /c "reg add `"HKLM\WIM_SOFT\Policies\Microsoft\Windows\OneDrive`" /v DisableFileSyncNGSC /t REG_DWORD /d 1 /f >nul 2>&1"
                    LogBg "Đã tắt OneDrive."
                }
                if ($Sync.Tweaks -contains "7. Bật Photo Viewer Cũ") {
                    cmd /c "reg add `"HKLM\WIM_SOFT\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations`" /v `".jpg`" /t REG_SZ /d `"PhotoViewer.FileAssoc.Tiff`" /f >nul 2>&1"
                    cmd /c "reg add `"HKLM\WIM_SOFT\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations`" /v `".png`" /t REG_SZ /d `"PhotoViewer.FileAssoc.Tiff`" /f >nul 2>&1"
                    LogBg "Đã bật Photo Viewer."
                }
            } finally {
                LogBg "Đang lưu và đóng khóa Registry an toàn (Anti-Lock)..."
                # Ép Garbage Collector chạy để nhả tay cầm File
                [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers()
                Start-Sleep -Seconds 1
                cmd /c "reg unload HKLM\WIM_SOFT >nul 2>&1"
            }
        }
        
        LogBg "HOÀN TẤT TỐI ƯU HÓA!"
        $Sync.BtnDbl.Invoke([action]{ $Sync.BtnDbl.Enabled=$true; [System.Windows.Forms.MessageBox]::Show("Tối ưu xong!") })
    }) | Out-Null; $Pipeline.InvokeAsync()
}

function Async-AddDriver {
    $FBD=New-Object System.Windows.Forms.FolderBrowserDialog; if($FBD.ShowDialog() -ne "OK"){ return }
    $DrvPath = $FBD.SelectedPath
    $BtnDbl.Enabled=$false; Log $TxtLogMod "Đang nạp Drivers chạy ngầm..." "INFO"
    
    $Global:SyncHash.DrvPath = $DrvPath; $Global:SyncHash.MountDir = $Global:MountDir; $Global:SyncHash.ScratchDir = $Global:ScratchDir
    $Runspace = [runspacefactory]::CreateRunspace(); $Runspace.Open(); $Runspace.SessionStateProxy.SetVariable("Sync", $Global:SyncHash)
    $Pipeline = $Runspace.CreatePipeline()
    $Pipeline.Commands.AddScript({
        cmd /c "dism /Image:`"$($Sync.MountDir)`" /Add-Driver /Driver:`"$($Sync.DrvPath)`" /Recurse /ScratchDir:`"$($Sync.ScratchDir)`" >nul 2>&1"
        $Sync.TxtMod.Invoke([action]{ $Sync.TxtMod.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] [INFO] Đã thêm Drivers xong!`r`n") })
        $Sync.BtnDbl.Invoke([action]{ $Sync.BtnDbl.Enabled=$true })
    }) | Out-Null; $Pipeline.InvokeAsync()
}

# --- 5. REBUILD ISO (ASYNC) ---
function Async-Rebuild {
    $OscTarget = "$ToolsDir\oscdimg.exe"
    if (!(Test-Path $OscTarget)) {
        Log $TxtLogMod "Tải oscdimg.exe..." "WARN"
        try { (New-Object System.Net.WebClient).DownloadFile("https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/refs/heads/main/oscdimg.exe", $OscTarget) } catch { Log $TxtLogMod "Lỗi mạng tải oscdimg!" "ERR"; return }
    }
    if (!(Test-Path "$Global:ExtractDir\boot\etfsboot.com")) { [System.Windows.Forms.MessageBox]::Show("Không thấy Source. Mount ISO lại!"); return }
    
    $S = New-Object System.Windows.Forms.SaveFileDialog; $S.Filter = "ISO Image|*.iso"; $S.FileName = "PhatTan_WinLite.iso"; if ($S.ShowDialog() -ne "OK") { return }
    $BtnBuild.Enabled=$false; $BtnBuild.Text="ĐANG ĐÓNG GÓI ISO..."
    
    $Global:SyncHash.OutIso = $S.FileName; $Global:SyncHash.MyWim = $TxtCapOut.Text
    $Global:SyncHash.ExtractDir = $Global:ExtractDir; $Global:SyncHash.MountDir = $Global:MountDir
    $Global:SyncHash.OscTarget = $OscTarget
    
    $Runspace = [runspacefactory]::CreateRunspace(); $Runspace.Open(); $Runspace.SessionStateProxy.SetVariable("Sync", $Global:SyncHash)
    $Pipeline = $Runspace.CreatePipeline()
    $Pipeline.Commands.AddScript({
        function LogBg ($Msg) { $Line="[$([DateTime]::Now.ToString('HH:mm:ss'))] [BUILD] $Msg`r`n"; $Sync.TxtMod.Invoke([action]{ $Sync.TxtMod.AppendText($Line); $Sync.TxtMod.ScrollToCaret() }) }
        
        # Unmount & Save trước khi build
        LogBg "Đang Unmount và lưu Image (Commit)..."
        cmd /c "dism /Unmount-Image /MountDir:`"$($Sync.MountDir)`" /Commit >nul 2>&1"
        
        if (Test-Path $Sync.MyWim) { 
            LogBg "Đang nhét file WIM vừa Capture vào ISO..."
            Copy-Item $Sync.MyWim "$($Sync.ExtractDir)\sources\install.wim" -Force 
        }
        
        LogBg "Khởi chạy quy trình Build ISO bằng Oscdimg..."
        $BootCmd = "2#p0,e,b`"$($Sync.ExtractDir)\boot\etfsboot.com`"#pEF,e,b`"$($Sync.ExtractDir)\efi\microsoft\boot\efisys.bin`""
        $IsoArgs = @("-bootdata:$BootCmd", "-u2", "-udfver102", "-lPhatTan_Win", "`"$($Sync.ExtractDir)`"", "`"$($Sync.OutIso)`"")
        $P = Start-Process $Sync.OscTarget -ArgumentList $IsoArgs -Wait -NoNewWindow -PassThru
        
        if ($P.ExitCode -eq 0) {
            LogBg "ĐÓNG GÓI THÀNH CÔNG: $($Sync.OutIso)"
            $Sync.BtnBld.Invoke([action]{ [System.Windows.Forms.MessageBox]::Show("Tạo ISO Thành Công!") })
        } else { LogBg "Lỗi tạo ISO: $($P.ExitCode)" }
        
        $Sync.LblInfo.Invoke([action]{ $Sync.LblInfo.Text="STATUS: UNMOUNTED"; $Sync.LblInfo.ForeColor="Silver" })
        $Sync.BtnBld.Invoke([action]{ $Sync.BtnBld.Enabled=$true; $Sync.BtnBld.Text="TẠO ISO MỚI (REBUILD)" })
    }) | Out-Null; $Pipeline.InvokeAsync()
}

Clean-OrphanedVSS
$Form.ShowDialog() | Out-Null
