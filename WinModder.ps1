<#
    WINDOWS MODDER STUDIO - PHAT TAN PC
    Version: 9.0 (WinFsp Fusion Engine + Feature Manager + Async)
    Technique: Native WinFsp Wimlib Mount -> Fallback DISM -> Solid Compress
#>

# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13
Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# =========================================================================================
# GLOBAL VARIABLES
# =========================================================================================
$ToolsDir = "$env:TEMP\PhatTan_Tools"

function Clean-OrphanedVSS {
    Get-WmiObject Win32_ShadowCopy | ? { $_.ClientAccessible -eq $true } | % { try { $_.Delete() | Out-Null } catch {} }
}

# =========================================================================================
# GUI SETUP
# =========================================================================================
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WINDOWS MODDER STUDIO V9.0 (WINFSP FUSION ENGINE)"
$Form.Size = New-Object System.Drawing.Size(950, 750); $Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 35); $Form.ForeColor = "WhiteSmoke"
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

$PanelTop = New-Object System.Windows.Forms.Panel; $PanelTop.Dock="Top"; $PanelTop.Height=80; $PanelTop.BackColor=[System.Drawing.Color]::FromArgb(45,45,50); $Form.Controls.Add($PanelTop)
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "PHAT TAN PC - SYSTEM BUILDER"; $LblT.Font = New-Object System.Drawing.Font("Segoe UI", 16, 1); $LblT.ForeColor = "Gold"; $LblT.AutoSize = $true; $LblT.Location = "20,10"; $PanelTop.Controls.Add($LblT)

$LblSel = New-Object System.Windows.Forms.Label; $LblSel.Text = "Chọn ổ Workspace:"; $LblSel.Location = "20, 50"; $LblSel.AutoSize=$true; $PanelTop.Controls.Add($LblSel)
$CboDrives = New-Object System.Windows.Forms.ComboBox; $CboDrives.Location = "150, 48"; $CboDrives.Size = "150, 25"; $CboDrives.DropDownStyle = "DropDownList"; $PanelTop.Controls.Add($CboDrives)
Get-WmiObject Win32_LogicalDisk | ? DriveType -eq 3 | % { $CboDrives.Items.Add("$($_.DeviceID) (Free: $([Math]::Round($_.FreeSpace/1GB,1)) GB)") | Out-Null }
$LblWorkDir = New-Object System.Windows.Forms.Label; $LblWorkDir.Text = "..."; $LblWorkDir.Location = "320, 50"; $LblWorkDir.AutoSize=$true; $LblWorkDir.ForeColor="Lime"; $PanelTop.Controls.Add($LblWorkDir)

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

$Tabs = New-Object System.Windows.Forms.TabControl; $Tabs.Location = "20,100"; $Tabs.Size = "895,580"; $Tabs.Appearance = "FlatButtons"; $Form.Controls.Add($Tabs)
function Make-Tab ($T) { $P = New-Object System.Windows.Forms.TabPage; $P.Text = "  $T  "; $P.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 35); $Tabs.Controls.Add($P); return $P }
$TabCap = Make-Tab "1. CAPTURE OS (HYBRID)"; $TabMod = Make-Tab "2. MODDING ISO"

# --- TAB 1: CAPTURE ---
$GbCap = New-Object System.Windows.Forms.GroupBox; $GbCap.Text="CAPTURE SETTINGS"; $GbCap.Location="20,20"; $GbCap.Size="845,500"; $GbCap.ForeColor="Cyan"; $TabCap.Controls.Add($GbCap)
$TxtCapOut = New-Object System.Windows.Forms.TextBox; $TxtCapOut.Location="30,65"; $TxtCapOut.Size="650,25"; $TxtCapOut.Text="D:\PhatTan_Backup.wim"; $GbCap.Controls.Add($TxtCapOut)
$BtnCapBrowse = New-Object System.Windows.Forms.Button; $BtnCapBrowse.Text="CHỌN..."; $BtnCapBrowse.Location="700,63"; $BtnCapBrowse.Size="100,27"; $BtnCapBrowse.ForeColor="Black"; $GbCap.Controls.Add($BtnCapBrowse)
$BtnCapBrowse.Add_Click({ $S=New-Object System.Windows.Forms.SaveFileDialog; $S.Filter="WIM File|*.wim"; $S.FileName="install.wim"; if($S.ShowDialog()-eq"OK"){$TxtCapOut.Text=$S.FileName} })
$BtnStartCap = New-Object System.Windows.Forms.Button; $BtnStartCap.Text="BẮT ĐẦU CAPTURE (WIMLIB NATIVE)"; $BtnStartCap.Location="30,120"; $BtnStartCap.Size="770,50"; $BtnStartCap.BackColor="OrangeRed"; $BtnStartCap.ForeColor="White"; $BtnStartCap.Font="Segoe UI, 11, Bold"; $GbCap.Controls.Add($BtnStartCap)
$TxtLogCap = New-Object System.Windows.Forms.TextBox; $TxtLogCap.Multiline=$true; $TxtLogCap.Location="30,190"; $TxtLogCap.Size="770,280"; $TxtLogCap.BackColor="Black"; $TxtLogCap.ForeColor="Lime"; $TxtLogCap.ScrollBars="Vertical"; $TxtLogCap.ReadOnly=$true; $TxtLogCap.Font="Consolas, 9"; $GbCap.Controls.Add($TxtLogCap)

# --- TAB 2: MODDING ---
$GbSrc = New-Object System.Windows.Forms.GroupBox; $GbSrc.Text="SOURCE ISO"; $GbSrc.Location="20,20"; $GbSrc.Size="845,70"; $GbSrc.ForeColor="Yellow"; $TabMod.Controls.Add($GbSrc)
$TxtIsoSrc = New-Object System.Windows.Forms.TextBox; $TxtIsoSrc.Location="20,30"; $TxtIsoSrc.Size="650,25"; $GbSrc.Controls.Add($TxtIsoSrc)
$BtnIsoSrc = New-Object System.Windows.Forms.Button; $BtnIsoSrc.Text="MỞ ISO"; $BtnIsoSrc.Location="690,28"; $BtnIsoSrc.Size="120,27"; $BtnIsoSrc.ForeColor="Black"; $GbSrc.Controls.Add($BtnIsoSrc)
$BtnIsoSrc.Add_Click({ $O=New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="ISO|*.iso"; if($O.ShowDialog()-eq"OK"){$TxtIsoSrc.Text=$O.FileName; $GbAct.Enabled=$true} })

$GbAct = New-Object System.Windows.Forms.GroupBox; $GbAct.Text="MENU EDIT (V9.0 WINFSP ENGINE)"; $GbAct.Location="20,100"; $GbAct.Size="845,300"; $GbAct.ForeColor="Lime"; $GbAct.Enabled=$false; $TabMod.Controls.Add($GbAct)
function Add-Btn ($T, $X, $Y, $C, $Fn) { $b=New-Object System.Windows.Forms.Button; $b.Text=$T; $b.Location="$X,$Y"; $b.Size="250,40"; $b.BackColor=$C; $b.ForeColor="Black"; $b.FlatStyle="Flat"; $b.Font="Segoe UI, 9, Bold"; $b.Add_Click($Fn); $GbAct.Controls.Add($b); return $b }

$BtnMnt  = Add-Btn "1. MOUNT ISO" 30 30 "Cyan" { Async-Mount }
$BtnAddF = Add-Btn "2. ADD FOLDER" 30 80 "White" { $FBD=New-Object System.Windows.Forms.FolderBrowserDialog; if($FBD.ShowDialog()-eq"OK"){Copy-Item $FBD.SelectedPath $Global:MountDir -Recurse -Force; [System.Windows.Forms.MessageBox]::Show("Đã Copy Folder vào WIM!")} }
$BtnAddD = Add-Btn "3. ADD DRIVERS" 30 130 "White" { Async-AddDriver }
$BtnDbl  = Add-Btn "4. TỐI ƯU (DEBLOAT REG)" 30 180 "Orange" { Async-Optimize }
$BtnFeat = Add-Btn "5. QUẢN LÝ TÍNH NĂNG (FEATURES)" 30 230 "Plum" { Async-ManageFeatures }

$BtnCln  = Add-Btn "6. FORCE CLEANUP (CỨU LỖI)" 560 30 "Red" { Async-Cleanup }

$LblInfo = New-Object System.Windows.Forms.Label; $LblInfo.Text="STATUS: UNMOUNTED"; $LblInfo.Location="300,40"; $LblInfo.AutoSize=$true; $LblInfo.Font="Segoe UI, 10, Bold"; $GbAct.Controls.Add($LblInfo)
$TxtLogMod = New-Object System.Windows.Forms.TextBox; $TxtLogMod.Multiline=$true; $TxtLogMod.Location="300,80"; $TxtLogMod.Size="510,190"; $TxtLogMod.BackColor="Black"; $TxtLogMod.ForeColor="Cyan"; $TxtLogMod.ScrollBars="Vertical"; $TxtLogMod.ReadOnly=$true; $TxtLogMod.Font="Consolas, 9"; $GbAct.Controls.Add($TxtLogMod)

$BtnBuild = New-Object System.Windows.Forms.Button; $BtnBuild.Text="TẠO ISO MỚI (REBUILD BẰNG WIMLIB)"; $BtnBuild.Location="20,410"; $BtnBuild.Size="845,60"; $BtnBuild.BackColor="Green"; $BtnBuild.ForeColor="White"; $BtnBuild.Font="Segoe UI, 14, Bold"; $BtnBuild.Enabled=$false; $TabMod.Controls.Add($BtnBuild)
$BtnBuild.Add_Click({ Async-Rebuild })

# =========================================================================================
# THREAD-SAFE SYNC HASH
# =========================================================================================
$Global:SyncHash = [hashtable]::Synchronized(@{
    TxtCap=$TxtLogCap; TxtMod=$TxtLogMod; LblInfo=$LblInfo; Form=$Form
    BtnCap=$BtnStartCap; BtnMnt=$BtnMnt; BtnBld=$BtnBuild; BtnDbl=$BtnDbl; BtnFeat=$BtnFeat; BtnCln=$BtnCln
    MountMethod="NONE"
})

# =========================================================================================
# LUỒNG CHẠY NGẦM (RUNSPACES)
# =========================================================================================

# --- HÀM TẢI CÔNG CỤ (TÍCH HỢP TẢI WINFSP) ---
$ScriptDownloadTools = {
    function Init-Tools ($TDir, $SyncObj) {
        if (!(Test-Path $TDir)) { New-Item -ItemType Directory -Path $TDir -Force | Out-Null }
        
        # 1. Tải Wimlib & Oscdimg
        $WimExe = "$TDir\wimlib-imagex.exe"
        if (!(Test-Path $WimExe)) {
            try {
                $SyncObj.TxtMod.Invoke([action]{ $SyncObj.TxtMod.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] [SYS] Đang tải Wimlib Engine...`r`n") })
                (New-Object System.Net.WebClient).DownloadFile("https://wimlib.net/downloads/wimlib-1.14.4-windows-x86_64-bin.zip", "$TDir\wim.zip")
                Expand-Archive "$TDir\wim.zip" -DestinationPath "$TDir\wim_tmp" -Force
                Copy-Item "$TDir\wim_tmp\*\wimlib-imagex.exe" $WimExe -Force
                Copy-Item "$TDir\wim_tmp\*\libwim-15.dll" $TDir -Force
            } catch {}
        }
        $Osc = "$TDir\oscdimg.exe"
        if (!(Test-Path $Osc)) {
            try { (New-Object System.Net.WebClient).DownloadFile("https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/refs/heads/main/oscdimg.exe", $Osc) } catch {}
        }

        # 2. Kiểm tra & Tải WinFsp
        $WinFspInstalled = (Test-Path "${env:ProgramFiles(x86)}\WinFsp") -or (Test-Path "$env:ProgramFiles\WinFsp")
        if (-not $WinFspInstalled) {
            try {
                $SyncObj.TxtMod.Invoke([action]{ $SyncObj.TxtMod.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] [SYS] Phát hiện thiếu WinFsp. Đang tải và cài đặt ngầm (Bắt buộc cho Wimlib Mount)...`r`n") })
                $MsiPath = "$TDir\winfsp.msi"
                (New-Object System.Net.WebClient).DownloadFile("https://github.com/winfsp/winfsp/releases/download/v2.1/winfsp-2.1.25156.msi", $MsiPath)
                $P_Msi = Start-Process "msiexec.exe" -ArgumentList "/i `"$MsiPath`" /qn /norestart" -Wait -PassThru
                if ($P_Msi.ExitCode -eq 0) {
                    $SyncObj.TxtMod.Invoke([action]{ $SyncObj.TxtMod.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] [SYS] Cài đặt WinFsp Thành Công!`r`n") })
                }
            } catch {
                $SyncObj.TxtMod.Invoke([action]{ $SyncObj.TxtMod.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] [SYS] Lỗi cài WinFsp, sẽ chuyển sang DISM!`r`n") })
            }
        }
    }
}

# --- CAPTURE ---
$BtnStartCap.Add_Click({
    Update-Workspace; Clean-OrphanedVSS
    if (!(Test-Path $Global:WorkDir)) { New-Item -ItemType Directory -Path $Global:WorkDir -Force | Out-Null }
    $BtnStartCap.Enabled = $false; $BtnStartCap.Text = "ĐANG CAPTURE... VUI LÒNG ĐỢI!"
    $Global:SyncHash.Target = $TxtCapOut.Text; $Global:SyncHash.ToolsDir = $ToolsDir
    
    $Runspace = [runspacefactory]::CreateRunspace(); $Runspace.Open(); $Runspace.SessionStateProxy.SetVariable("Sync", $Global:SyncHash)
    $Pipeline = $Runspace.CreatePipeline()
    $Pipeline.Commands.AddScript($ScriptDownloadTools)
    $Pipeline.Commands.AddScript({
        function LogBg ($Msg, $Type="INFO") { $Line="[$([DateTime]::Now.ToString('HH:mm:ss'))] [$Type] $Msg`r`n"; $Sync.TxtCap.Invoke([action]{ $Sync.TxtCap.AppendText($Line); $Sync.TxtCap.ScrollToCaret() }) }
        Init-Tools $Sync.ToolsDir $Sync
        
        $WimExe = "$($Sync.ToolsDir)\wimlib-imagex.exe"
        if (Test-Path $WimExe) {
            LogBg ">>> CHẠY CHẾ ĐỘ WIMLIB (NATIVE VSS) <<<" "SUCCESS"
            $WimConf = "$($Sync.ToolsDir)\WimExcludes.ini"
            "[ExclusionList]`n\hiberfil.sys`n\pagefile.sys`n\swapfile.sys`n\System Volume Information`n\$Recycle.Bin" | Out-File $WimConf
            $Args = @("capture", "C:", $Sync.Target, "PhatTan_OS", "--compress=LZX", "--check", "--threads=0", "--snapshot", "--config=$WimConf")
            $Proc = Start-Process $WimExe -ArgumentList $Args -Wait -NoNewWindow -PassThru
            if ($Proc.ExitCode -eq 0) { LogBg "Capture XONG!" "SUCCESS" } else { LogBg "Lỗi Wimlib: $($Proc.ExitCode)" "ERR" }
        } else { LogBg "LỖI MẠNG: Không thể tải Wimlib." "ERR" }
        
        $Sync.BtnCap.Invoke([action]{ $Sync.BtnCap.Enabled=$true; $Sync.BtnCap.Text="BẮT ĐẦU CAPTURE (WIMLIB NATIVE)" })
    }) | Out-Null; $Pipeline.InvokeAsync()
})

# --- MOUNT FUSION (WINFSP -> DISM) ---
function Async-Mount {
    $Iso = $TxtIsoSrc.Text; if (!(Test-Path $Iso)) { Log $TxtLogMod "Missing ISO!" "ERR"; return }
    $BtnMnt.Enabled=$false; $BtnBuild.Enabled=$false; $BtnDbl.Enabled=$false; $BtnFeat.Enabled=$false
    Update-Workspace; Ensure-Dir $Global:WorkDir
    $Global:SyncHash.Iso = $Iso; $Global:SyncHash.MountDir = $Global:MountDir; $Global:SyncHash.ExtractDir = $Global:ExtractDir; $Global:SyncHash.ScratchDir = $Global:ScratchDir
    $Global:SyncHash.ToolsDir = $ToolsDir

    $Runspace = [runspacefactory]::CreateRunspace(); $Runspace.Open(); $Runspace.SessionStateProxy.SetVariable("Sync", $Global:SyncHash)
    $Pipeline = $Runspace.CreatePipeline()
    $Pipeline.Commands.AddScript($ScriptDownloadTools)
    $Pipeline.Commands.AddScript({
        function LogBg ($Msg, $Type="INFO") { $Line="[$([DateTime]::Now.ToString('HH:mm:ss'))] [$Type] $Msg`r`n"; $Sync.TxtMod.Invoke([action]{ $Sync.TxtMod.AppendText($Line); $Sync.TxtMod.ScrollToCaret() }) }
        
        Init-Tools $Sync.ToolsDir $Sync

        LogBg "Đang dọn dẹp thư mục cũ..."
        $WimExe = "$($Sync.ToolsDir)\wimlib-imagex.exe"
        if (Test-Path $WimExe) { cmd /c "`"$WimExe`" unmount `"$($Sync.MountDir)`" --force >nul 2>&1" }
        cmd /c "dism /Unmount-Image /MountDir:`"$($Sync.MountDir)`" /Discard >nul 2>&1"
        Remove-Item $Sync.ExtractDir -Recurse -Force -ErrorAction SilentlyContinue; New-Item $Sync.ExtractDir -ItemType Directory -Force | Out-Null
        Remove-Item $Sync.MountDir -Recurse -Force -ErrorAction SilentlyContinue; New-Item $Sync.MountDir -ItemType Directory -Force | Out-Null

        LogBg "Đang Mount ISO ảo..."
        Mount-DiskImage -ImagePath $Sync.Iso -StorageType ISO -ErrorAction SilentlyContinue | Out-Null
        $IsoDrive=$null; for($i=1;$i -le 5;$i++){try{$Vol=Get-DiskImage -ImagePath $Sync.Iso|Get-Volume -ErrorAction Stop;if($Vol.DriveLetter){$IsoDrive="$($Vol.DriveLetter):";break}}catch{};Start-Sleep 1}
        
        if ($IsoDrive) {
            LogBg "Đang copy mã nguồn sang Workspace..."
            cmd /c "xcopy /E /H /Y /I `"$IsoDrive\*`" `"$($Sync.ExtractDir)\`" >nul 2>&1"
            Dismount-DiskImage -ImagePath $Sync.Iso | Out-Null

            $SrcW="$($Sync.ExtractDir)\sources\install.wim"; $SrcE="$($Sync.ExtractDir)\sources\install.esd"
            if(Test-Path $SrcE){
                LogBg "Chuyển ESD sang WIM..."
                cmd /c "dism /Export-Image /SourceImageFile:`"$SrcE`" /SourceIndex:1 /DestinationImageFile:`"$SrcW`" /Compress:max"
                Remove-Item $SrcE -Force
            }

            # WINFSP FUSION MOUNT
            $Sync.MountMethod = "NONE"
            if (Test-Path $WimExe) {
                LogBg "Đang thử bung ruột WIM bằng WinFsp + Wimlib (Siêu Tốc)..."
                $P1 = Start-Process $WimExe -ArgumentList "mountrw", "`"$SrcW`"", "1", "`"$($Sync.MountDir)`"" -Wait -NoNewWindow -PassThru
                if ($P1.ExitCode -eq 0) {
                    $Sync.MountMethod = "WIMLIB"
                    LogBg "WINFSP MOUNT THÀNH CÔNG!" "SUCCESS"
                } else {
                    LogBg "WinFsp không phản hồi. Chuyển sang DISM WOF..." "WARN"
                }
            }
            
            # DISM FALLBACK
            if ($Sync.MountMethod -eq "NONE") {
                LogBg "Đang bung ruột WIM bằng DISM..."
                $P2 = Start-Process "dism" -ArgumentList "/Mount-Image /ImageFile:`"$SrcW`" /Index:1 /MountDir:`"$($Sync.MountDir)`" /ScratchDir:`"$($Sync.ScratchDir)`"" -Wait -NoNewWindow -PassThru
                if ($P2.ExitCode -eq 0) {
                    $Sync.MountMethod = "DISM"
                    LogBg "DISM MOUNT THÀNH CÔNG!" "SUCCESS"
                } else { LogBg "Lỗi bung WIM (Cả 2 engine đều xịt)!" "ERR" }
            }

            if ($Sync.MountMethod -ne "NONE") {
                $Sync.LblInfo.Invoke([action]{ $Sync.LblInfo.Text="STATUS: MOUNTED ($($Sync.MountMethod) RW)"; $Sync.LblInfo.ForeColor="Lime" })
                $Sync.BtnBld.Invoke([action]{ $Sync.BtnBld.Enabled=$true }); $Sync.BtnDbl.Invoke([action]{ $Sync.BtnDbl.Enabled=$true }); $Sync.BtnFeat.Invoke([action]{ $Sync.BtnFeat.Enabled=$true })
            }
        }
        $Sync.BtnMnt.Invoke([action]{ $Sync.BtnMnt.Enabled=$true })
    }) | Out-Null; $Pipeline.InvokeAsync()
}
function Ensure-Dir($p) { if(!(Test-Path $p)){New-Item -ItemType Directory -Path $p -Force|Out-Null} }

# --- QUẢN LÝ TÍNH NĂNG (V8.0 FEATURE MANAGER) ---
function Async-ManageFeatures {
    $BtnFeat.Enabled=$false; $BtnFeat.Text="ĐANG QUÉT TÍNH NĂNG..."
    $Global:SyncHash.MountDir = $Global:MountDir
    
    $Runspace = [runspacefactory]::CreateRunspace(); $Runspace.Open(); $Runspace.SessionStateProxy.SetVariable("Sync", $Global:SyncHash)
    $Pipeline = $Runspace.CreatePipeline()
    $Pipeline.Commands.AddScript({
        function LogBg ($Msg) { $Line="[$([DateTime]::Now.ToString('HH:mm:ss'))] [FEATURE] $Msg`r`n"; $Sync.TxtMod.Invoke([action]{ $Sync.TxtMod.AppendText($Line); $Sync.TxtMod.ScrollToCaret() }) }
        
        LogBg "Đang quét danh sách các Tính năng khả dụng trong WIM..."
        $Out = cmd /c "dism /image:`"$($Sync.MountDir)`" /Get-Features /English"
        
        $FeatList = @(); $CurName = ""
        foreach ($Line in $Out) {
            if ($Line -match "Feature Name : (.*)") { $CurName = $Matches[1].Trim() }
            if ($Line -match "State : (.*)") { 
                $State = $Matches[1].Trim()
                $IsChecked = ($State -eq "Enabled" -or $State -eq "EnablePending")
                $FeatList += [PSCustomObject]@{ Name=$CurName; Checked=$IsChecked; Original=$IsChecked }
            }
        }
        
        $Sync.Form.Invoke([action]{
            $FForm = New-Object System.Windows.Forms.Form; $FForm.Text="TRÌNH QUẢN LÝ TÍNH NĂNG (FEATURES)"; $FForm.Size="500,600"; $FForm.StartPosition="CenterParent"; $FForm.BackColor="40,40,45"; $FForm.ForeColor="White"
            $Grid = New-Object System.Windows.Forms.DataGridView; $Grid.Location="10,10"; $Grid.Size="460,480"; $Grid.BackgroundColor="30,30,30"; $Grid.ForeColor="Black"; $Grid.AllowUserToAddRows=$false; $Grid.RowHeadersVisible=$false; $Grid.AutoSizeColumnsMode="Fill"
            $ColChk = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn; $ColChk.HeaderText="Bật/Tắt"; $ColChk.Name="Chk"; $ColChk.Width=60; $Grid.Columns.Add($ColChk) | Out-Null
            $Grid.Columns.Add("Name","Tên Tính năng (Feature Name)") | Out-Null
            $Grid.Columns[1].ReadOnly = $true
            
            foreach ($f in $FeatList) { $Grid.Rows.Add($f.Checked, $f.Name) | Out-Null }
            $FForm.Controls.Add($Grid)
            
            $BtnOK = New-Object System.Windows.Forms.Button; $BtnOK.Text="ÁP DỤNG"; $BtnOK.Location="10,510"; $BtnOK.Size="220,40"; $BtnOK.BackColor="Green"; $BtnOK.ForeColor="White"; $BtnOK.DialogResult="OK"; $FForm.Controls.Add($BtnOK)
            $BtnCancel = New-Object System.Windows.Forms.Button; $BtnCancel.Text="HỦY"; $BtnCancel.Location="250,510"; $BtnCancel.Size="220,40"; $BtnCancel.BackColor="Red"; $BtnCancel.ForeColor="White"; $BtnCancel.DialogResult="Cancel"; $FForm.Controls.Add($BtnCancel)
            
            if ($FForm.ShowDialog() -eq "OK") {
                $ToEnable = @(); $ToDisable = @()
                for ($i=0; $i -lt $Grid.Rows.Count; $i++) {
                    $CheckedNow = $Grid.Rows[$i].Cells[0].Value
                    $Name = $Grid.Rows[$i].Cells[1].Value
                    $Original = $FeatList | ? Name -eq $Name | Select -ExpandProperty Original
                    if ($CheckedNow -and !$Original) { $ToEnable += $Name }
                    if (!$CheckedNow -and $Original) { $ToDisable += $Name }
                }
                
                $Sync.TxtMod.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] [FEATURE] Đang áp dụng thay đổi (Sẽ tốn thời gian)...`r`n")
                
                $RunApp = [runspacefactory]::CreateRunspace(); $RunApp.Open()
                $RunApp.SessionStateProxy.SetVariable("Sync", $Sync)
                $RunApp.SessionStateProxy.SetVariable("ToEnable", $ToEnable)
                $RunApp.SessionStateProxy.SetVariable("ToDisable", $ToDisable)
                $PipeApp = $RunApp.CreatePipeline()
                $PipeApp.Commands.AddScript({
                    foreach ($e in $ToEnable) {
                        $Sync.TxtMod.Invoke([action]{ $Sync.TxtMod.AppendText("-> Đang BẬT: $e ...`r`n") })
                        cmd /c "dism /image:`"$($Sync.MountDir)`" /Enable-Feature /FeatureName:$e /All >nul 2>&1"
                    }
                    foreach ($d in $ToDisable) {
                        $Sync.TxtMod.Invoke([action]{ $Sync.TxtMod.AppendText("-> Đang TẮT: $d ...`r`n") })
                        cmd /c "dism /image:`"$($Sync.MountDir)`" /Disable-Feature /FeatureName:$d >nul 2>&1"
                    }
                    $Sync.TxtMod.Invoke([action]{ $Sync.TxtMod.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] [FEATURE] Xong phần Features!`r`n") })
                }) | Out-Null; $PipeApp.InvokeAsync()
            }
        })
        $Sync.BtnFeat.Invoke([action]{ $Sync.BtnFeat.Enabled=$true; $Sync.BtnFeat.Text="5. QUẢN LÝ TÍNH NĂNG (FEATURES)" })
    }) | Out-Null; $Pipeline.InvokeAsync()
}

function Async-AddDriver {
    $FBD=New-Object System.Windows.Forms.FolderBrowserDialog; if($FBD.ShowDialog() -ne "OK"){ return }
    $Global:SyncHash.DrvPath = $FBD.SelectedPath; $Global:SyncHash.MountDir = $Global:MountDir; $Global:SyncHash.ScratchDir = $Global:ScratchDir
    $BtnDbl.Enabled=$false; Log $TxtLogMod "Đang nạp Drivers chạy ngầm..." "INFO"
    $Runspace = [runspacefactory]::CreateRunspace(); $Runspace.Open(); $Runspace.SessionStateProxy.SetVariable("Sync", $Global:SyncHash)
    $Pipeline = $Runspace.CreatePipeline(); $Pipeline.Commands.AddScript({
        cmd /c "dism /Image:`"$($Sync.MountDir)`" /Add-Driver /Driver:`"$($Sync.DrvPath)`" /Recurse /ScratchDir:`"$($Sync.ScratchDir)`" >nul 2>&1"
        $Sync.TxtMod.Invoke([action]{ $Sync.TxtMod.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] [INFO] Đã thêm Drivers xong!`r`n") })
        $Sync.BtnDbl.Invoke([action]{ $Sync.BtnDbl.Enabled=$true })
    }) | Out-Null; $Pipeline.InvokeAsync()
}

function Async-Optimize {
    if (!(Test-Path "$Global:MountDir\Windows")) { Log $TxtLogMod "Chưa Mount WIM!" "ERR"; return }
    $TweakForm = New-Object System.Windows.Forms.Form; $TweakForm.Text="MENU DEBLOAT"; $TweakForm.Size="450, 480"; $TweakForm.StartPosition="CenterScreen"; $TweakForm.BackColor="40,40,45"; $TweakForm.ForeColor="White"
    $CLB = New-Object System.Windows.Forms.CheckedListBox; $CLB.Location="10,10"; $CLB.Size="410,360"; $CLB.BackColor="60,60,65"; $CLB.ForeColor="Cyan"; $CLB.Font="Segoe UI, 10"
    $CLB.Items.Add("1. Xóa Apps Rác (Bing, Zune, Maps...)"); $CLB.Items.Add("2. Tắt Telemetry (Theo dõi)"); $CLB.Items.Add("3. Tắt Cortana & Web Search")
    $CLB.Items.Add("4. Tắt Windows Defender"); $CLB.Items.Add("5. Tắt Windows Update"); $CLB.Items.Add("6. Tắt OneDrive"); $CLB.Items.Add("7. Bật Photo Viewer Cũ")
    $CLB.SetItemChecked(0,$true); $CLB.SetItemChecked(1,$true); $CLB.SetItemChecked(2,$true); $TweakForm.Controls.Add($CLB)
    $BtnOK=New-Object System.Windows.Forms.Button; $BtnOK.Text="THỰC HIỆN"; $BtnOK.DialogResult="OK"; $BtnOK.Location="10,390"; $BtnOK.Size="200,40"; $BtnOK.BackColor="Green"; $TweakForm.Controls.Add($BtnOK)
    $BtnCancel=New-Object System.Windows.Forms.Button; $BtnCancel.Text="HỦY BỎ"; $BtnCancel.DialogResult="Cancel"; $BtnCancel.Location="220,390"; $BtnCancel.Size="190,40"; $BtnCancel.BackColor="Red"; $TweakForm.Controls.Add($BtnCancel)
    if ($TweakForm.ShowDialog() -ne "OK") { return }
    
    $BtnDbl.Enabled=$false
    $Global:SyncHash.Tweaks = $CLB.CheckedItems; $Global:SyncHash.MountDir = $Global:MountDir
    $Runspace = [runspacefactory]::CreateRunspace(); $Runspace.Open(); $Runspace.SessionStateProxy.SetVariable("Sync", $Global:SyncHash)
    $Pipeline = $Runspace.CreatePipeline(); $Pipeline.Commands.AddScript({
        function LogBg ($Msg) { $Line="[$([DateTime]::Now.ToString('HH:mm:ss'))] [TWEAK] $Msg`r`n"; $Sync.TxtMod.Invoke([action]{ $Sync.TxtMod.AppendText($Line); $Sync.TxtMod.ScrollToCaret() }) }
        if ($Sync.Tweaks -contains "1. Xóa Apps Rác (Bing, Zune, Maps...)") {
            LogBg "Đang gỡ bỏ App rác..."; $Bloat = @("Bing","Zune","SkypeApp","WindowsMaps","MicrosoftSolitaire","Microsoft3DViewer","FeedbackHub","YourPhone")
            foreach ($App in $Bloat) { Get-AppxProvisionedPackage -Path $Sync.MountDir | ? { $_.DisplayName -match $App } | % { Remove-AppxProvisionedPackage -Path $Sync.MountDir -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null } }
        }
        if ($Sync.Tweaks.Count -gt 0) {
            LogBg "Load Registry Hive..."; cmd /c "reg load HKLM\WIM_SOFT `"$($Sync.MountDir)\Windows\System32\config\SOFTWARE`" >nul 2>&1"
            try {
                if ($Sync.Tweaks -contains "2. Tắt Telemetry (Theo dõi)") { cmd /c "reg add `"HKLM\WIM_SOFT\Policies\Microsoft\Windows\DataCollection`" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1" }
                if ($Sync.Tweaks -contains "3. Tắt Cortana & Web Search") { cmd /c "reg add `"HKLM\WIM_SOFT\Policies\Microsoft\Windows\Windows Search`" /v AllowCortana /t REG_DWORD /d 0 /f >nul 2>&1"; cmd /c "reg add `"HKLM\WIM_SOFT\Policies\Microsoft\Windows\Windows Search`" /v DisableWebSearch /t REG_DWORD /d 1 /f >nul 2>&1" }
                if ($Sync.Tweaks -contains "4. Tắt Windows Defender") { cmd /c "reg add `"HKLM\WIM_SOFT\Policies\Microsoft\Windows Defender`" /v DisableAntiSpyware /t REG_DWORD /d 1 /f >nul 2>&1" }
                if ($Sync.Tweaks -contains "5. Tắt Windows Update") { cmd /c "reg add `"HKLM\WIM_SOFT\Policies\Microsoft\Windows\WindowsUpdate\AU`" /v NoAutoUpdate /t REG_DWORD /d 1 /f >nul 2>&1" }
                if ($Sync.Tweaks -contains "6. Tắt OneDrive") { cmd /c "reg add `"HKLM\WIM_SOFT\Policies\Microsoft\Windows\OneDrive`" /v DisableFileSyncNGSC /t REG_DWORD /d 1 /f >nul 2>&1" }
                if ($Sync.Tweaks -contains "7. Bật Photo Viewer Cũ") { cmd /c "reg add `"HKLM\WIM_SOFT\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations`" /v `".jpg`" /t REG_SZ /d `"PhotoViewer.FileAssoc.Tiff`" /f >nul 2>&1"; cmd /c "reg add `"HKLM\WIM_SOFT\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations`" /v `".png`" /t REG_SZ /d `"PhotoViewer.FileAssoc.Tiff`" /f >nul 2>&1" }
            } finally {
                LogBg "Nhả Registry khóa..."; [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers(); Start-Sleep -Seconds 1; cmd /c "reg unload HKLM\WIM_SOFT >nul 2>&1"
            }
        }
        $Sync.BtnDbl.Invoke([action]{ $Sync.BtnDbl.Enabled=$true; [System.Windows.Forms.MessageBox]::Show("Tối ưu xong!") })
    }) | Out-Null; $Pipeline.InvokeAsync()
}

# --- UNMOUNT FUSION ---
function Async-Cleanup {
    $BtnCln.Enabled=$false; Log $TxtLogMod "Đang ép dọn dẹp Registry & MountDir..." "WARN"
    $Global:SyncHash.MountDir = $Global:MountDir; $Global:SyncHash.ToolsDir = $ToolsDir
    $Runspace = [runspacefactory]::CreateRunspace(); $Runspace.Open(); $Runspace.SessionStateProxy.SetVariable("Sync", $Global:SyncHash)
    $Pipeline = $Runspace.CreatePipeline(); $Pipeline.Commands.AddScript({
        [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers()
        cmd /c "reg unload HKLM\WIM_SOFT >nul 2>&1"; cmd /c "reg unload HKLM\WIM_SYS >nul 2>&1"
        
        $WimExe = "$($Sync.ToolsDir)\wimlib-imagex.exe"
        if (Test-Path $WimExe) { cmd /c "`"$WimExe`" unmount `"$($Sync.MountDir)`" --force >nul 2>&1" }
        cmd /c "dism /Unmount-Image /MountDir:`"$($Sync.MountDir)`" /Discard >nul 2>&1"; cmd /c "dism /Cleanup-Wim >nul 2>&1"
        
        Get-WmiObject Win32_ShadowCopy | ? { $_.ClientAccessible -eq $true } | % { try { $_.Delete() | Out-Null } catch {} }
        
        $Sync.LblInfo.Invoke([action]{ $Sync.LblInfo.Text="STATUS: UNMOUNTED/CLEANED"; $Sync.LblInfo.ForeColor="Silver" })
        $Sync.BtnCln.Invoke([action]{ $Sync.BtnCln.Enabled=$true; $Sync.TxtMod.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] [CLEAN] Xong!`r`n") })
    }) | Out-Null; $Pipeline.InvokeAsync()
}

# --- 5. REBUILD BẰNG WIMLIB (SIÊU NÉN) ---
function Async-Rebuild {
    $S = New-Object System.Windows.Forms.SaveFileDialog; $S.Filter = "ISO Image|*.iso"; $S.FileName = "PhatTan_WinLite.iso"; if ($S.ShowDialog() -ne "OK") { return }
    $BtnBuild.Enabled=$false; $BtnBuild.Text="ĐANG ĐÓNG GÓI BẰNG WIMLIB..."
    
    $Global:SyncHash.OutIso = $S.FileName; $Global:SyncHash.ExtractDir = $Global:ExtractDir; $Global:SyncHash.MountDir = $Global:MountDir; $Global:SyncHash.ToolsDir = $ToolsDir
    
    $Runspace = [runspacefactory]::CreateRunspace(); $Runspace.Open(); $Runspace.SessionStateProxy.SetVariable("Sync", $Global:SyncHash)
    $Pipeline = $Runspace.CreatePipeline()
    $Pipeline.Commands.AddScript($ScriptDownloadTools)
    $Pipeline.Commands.AddScript({
        function LogBg ($Msg) { $Line="[$([DateTime]::Now.ToString('HH:mm:ss'))] [BUILD] $Msg`r`n"; $Sync.TxtMod.Invoke([action]{ $Sync.TxtMod.AppendText($Line); $Sync.TxtMod.ScrollToCaret() }) }
        Init-Tools $Sync.ToolsDir $Sync
        $WimExe = "$($Sync.ToolsDir)\wimlib-imagex.exe"
        
        # SMART UNMOUNT COMMIT
        if ($Sync.MountMethod -eq "WIMLIB") {
            LogBg "1. Đang Unmount và lưu thay đổi bằng WIMLIB..."
            cmd /c "`"$WimExe`" unmount `"$($Sync.MountDir)`" --commit >nul 2>&1"
        } else {
            LogBg "1. Đang Unmount và lưu thay đổi bằng DISM..."
            cmd /c "dism /Unmount-Image /MountDir:`"$($Sync.MountDir)`" /Commit >nul 2>&1"
        }
        
        if (Test-Path $WimExe) {
            LogBg "2. Ép xung WIM bằng WIMLIB (Nén LZX Solid)..."
            $WimFile = "$($Sync.ExtractDir)\sources\install.wim"
            $Proc = Start-Process $WimExe -ArgumentList "optimize", "`"$WimFile`"", "--solid" -Wait -NoNewWindow -PassThru
            if ($Proc.ExitCode -eq 0) { LogBg "-> Siêu nén Wimlib Thành công!" } else { LogBg "-> Lỗi nén Wimlib, giữ nguyên WIM gốc." }
        } else { LogBg "2. Bỏ qua nén Wimlib do thiếu Tool." }
        
        LogBg "3. Khởi chạy Oscdimg tạo ISO..."
        $Osc = "$($Sync.ToolsDir)\oscdimg.exe"
        $BootCmd = "2#p0,e,b`"$($Sync.ExtractDir)\boot\etfsboot.com`"#pEF,e,b`"$($Sync.ExtractDir)\efi\microsoft\boot\efisys.bin`""
        $IsoArgs = @("-bootdata:$BootCmd", "-u2", "-udfver102", "-lPhatTan_Win", "`"$($Sync.ExtractDir)`"", "`"$($Sync.OutIso)`"")
        $P = Start-Process $Osc -ArgumentList $IsoArgs -Wait -NoNewWindow -PassThru
        
        if ($P.ExitCode -eq 0) {
            LogBg "ĐÓNG GÓI THÀNH CÔNG: $($Sync.OutIso)"
            $Sync.BtnBld.Invoke([action]{ [System.Windows.Forms.MessageBox]::Show("Tạo ISO Thành Công!") })
        } else { LogBg "Lỗi tạo ISO: $($P.ExitCode)" }
        
        $Sync.LblInfo.Invoke([action]{ $Sync.LblInfo.Text="STATUS: UNMOUNTED"; $Sync.LblInfo.ForeColor="Silver" })
        $Sync.BtnBld.Invoke([action]{ $Sync.BtnBld.Enabled=$true; $Sync.BtnBld.Text="TẠO ISO MỚI (REBUILD BẰNG WIMLIB)" })
    }) | Out-Null; $Pipeline.InvokeAsync()
}

$Form.ShowDialog() | Out-Null
