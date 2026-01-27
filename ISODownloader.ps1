# =============================================================================
# ISODownloader_v2.7_FixedUI.ps1
# PHAT TAN PC - ISO DOWNLOADER EXTREME (FIXED UI & PROGRESS)
# =============================================================================

# 1. YÊU CẦU QUYỀN ADMIN
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "powershell.exe"; $processInfo.Arguments = "-File `"$PSCommandPath`""; $processInfo.Verb = "runas"
    [System.Diagnostics.Process]::Start($processInfo); Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

# --- CẤU HÌNH ---
$JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/iso_list.json"
$AriaUrl = "https://github.com/aria2/aria2/releases/download/release-1.36.0/aria2-1.36.0-win-64bit-build1.zip"

# --- TỐI ƯU KẾT NỐI ---
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13
[System.Net.ServicePointManager]::DefaultConnectionLimit = 512
[System.Net.ServicePointManager]::CheckCertificateRevocationList = $false

# =============================================================================
# AUTO SETUP ZONE
# =============================================================================
function Setup-DefenderExclusion {
    $CurrentPath = $PSScriptRoot; if ([string]::IsNullOrEmpty($CurrentPath)) { $CurrentPath = Get-Location }
    Try {
        $Exclusions = Get-MpPreference | Select-Object -ExpandProperty ExclusionPath
        if ($Exclusions -notcontains $CurrentPath) { Add-MpPreference -ExclusionPath $CurrentPath -Force -ErrorAction SilentlyContinue }
    } Catch {}
}

function Setup-Aria2 {
    $AriaPath = "$PSScriptRoot\aria2c.exe"; if ([string]::IsNullOrEmpty($PSScriptRoot)) { $AriaPath = ".\aria2c.exe" }
    if (-not (Test-Path $AriaPath)) {
        $Splash = New-Object System.Windows.Forms.Form
        $Splash.Size = New-Object System.Drawing.Size(400, 150); $Splash.StartPosition = "CenterScreen"; $Splash.FormBorderStyle = "None"; $Splash.BackColor = "Black"
        $SplashLbl = New-Object System.Windows.Forms.Label; $SplashLbl.Text = "DANG CAI DAT ENGINE...`nVui long cho..."; $SplashLbl.ForeColor = "Cyan"; $SplashLbl.AutoSize = $false; $SplashLbl.Size = New-Object System.Drawing.Size(400, 150); $SplashLbl.TextAlign = "MiddleCenter"; $SplashLbl.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $Splash.Controls.Add($SplashLbl); $Splash.Show(); $Splash.Refresh()
        Try {
            $ZipPath = ".\aria2_temp.zip"; Invoke-WebRequest -Uri $AriaUrl -OutFile $ZipPath -UseBasicParsing
            $ExtractPath = ".\aria2_temp"; if (Test-Path $ExtractPath) { Remove-Item $ExtractPath -Recurse -Force }
            [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $ExtractPath)
            $ExeSource = Get-ChildItem -Path $ExtractPath -Filter "aria2c.exe" -Recurse | Select-Object -First 1
            if ($ExeSource) { Move-Item -Path $ExeSource.FullName -Destination $AriaPath -Force }
            Remove-Item $ZipPath -Force; Remove-Item $ExtractPath -Recurse -Force; $Splash.Close()
        } Catch { $Splash.Close() }
    }
}
Setup-DefenderExclusion; Setup-Aria2

# =============================================================================
# GUI & LOGIC
# =============================================================================
function Get-Aria2Path {
    $List = @(".\aria2c.exe", "$PSScriptRoot\aria2c.exe", "aria2c.exe")
    foreach ($Path in $List) { if (Get-Command $Path -ErrorAction SilentlyContinue) { return (Get-Command $Path).Source } }
    return $null
}

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "ISO DOWNLOADER V2.7 (FIX UI) - PHAT TAN PC"; $Form.Size = New-Object System.Drawing.Size(780, 520); $Form.StartPosition = "CenterScreen"; $Form.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 30); $Form.ForeColor = "White"; $Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false
$Global:IsoData = @()

$FontTitle = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold); $FontNormal = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular); $FontBold = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold); $FontBigBtn = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)

# Header
$Lbl = New-Object System.Windows.Forms.Label; $Lbl.Text = "KHO TAI NGUYEN (FIXED PROGRESS)"; $Lbl.AutoSize=$true; $Lbl.Location="20,15"; $Lbl.Font=$FontTitle; $Lbl.ForeColor="Cyan"; $Form.Controls.Add($Lbl)

# Aria2 Check Status
$LblAria = New-Object System.Windows.Forms.Label; $LblAria.Location="580,20"; $LblAria.AutoSize=$true; $LblAria.Font=$FontBold; $Form.Controls.Add($LblAria)
if (Get-Aria2Path) { $LblAria.Text="[ARIA2: INSTALLED]"; $LblAria.ForeColor="Lime" } else { $LblAria.Text="[ARIA2: MISSING]"; $LblAria.ForeColor="Red" }

# Filter Group
$GbFilter = New-Object System.Windows.Forms.GroupBox; $GbFilter.Text="Bo Loc & Cau Hinh"; $GbFilter.Location="20,60"; $GbFilter.Size="720,80"; $GbFilter.ForeColor="Yellow"; $GbFilter.Font=$FontBold; $Form.Controls.Add($GbFilter)

$CbType = New-Object System.Windows.Forms.ComboBox; $CbType.Location="20,30"; $CbType.Size="120,30"; $CbType.DropDownStyle="DropDownList"; $CbType.Font=$FontNormal; $GbFilter.Controls.Add($CbType)
$CbBit = New-Object System.Windows.Forms.ComboBox; $CbBit.Location="150,30"; $CbBit.Size="60,30"; $CbBit.DropDownStyle="DropDownList"; $CbBit.Font=$FontNormal; $CbBit.Items.AddRange(@("All", "x64", "x86", "arm64")); $CbBit.SelectedIndex=0; $GbFilter.Controls.Add($CbBit)
$CbLang = New-Object System.Windows.Forms.ComboBox; $CbLang.Location="220,30"; $CbLang.Size="90,30"; $CbLang.DropDownStyle="DropDownList"; $CbLang.Font=$FontNormal; $GbFilter.Controls.Add($CbLang)

$LblThread = New-Object System.Windows.Forms.Label; $LblThread.Text="Luong:"; $LblThread.Location="320,33"; $LblThread.AutoSize=$true; $LblThread.Font=$FontNormal; $GbFilter.Controls.Add($LblThread)
$CbThread = New-Object System.Windows.Forms.ComboBox; $CbThread.Location="370,30"; $CbThread.Size="50,30"; $CbThread.DropDownStyle="DropDownList"; $CbThread.Font=$FontNormal; $CbThread.Items.AddRange(@("4", "8", "16", "32")); $CbThread.SelectedItem="16"; $GbFilter.Controls.Add($CbThread)

$LblEng = New-Object System.Windows.Forms.Label; $LblEng.Text="Engine:"; $LblEng.Location="440,33"; $LblEng.AutoSize=$true; $LblEng.Font=$FontNormal; $GbFilter.Controls.Add($LblEng)
$RadNative = New-Object System.Windows.Forms.RadioButton; $RadNative.Text="Native"; $RadNative.Location="500,30"; $RadNative.AutoSize=$true; $RadNative.Font=$FontNormal; $RadNative.Checked=$true; $GbFilter.Controls.Add($RadNative)
$RadAria = New-Object System.Windows.Forms.RadioButton; $RadAria.Text="Aria2"; $RadAria.Location="565,30"; $RadAria.AutoSize=$true; $RadAria.Font=$FontNormal; $GbFilter.Controls.Add($RadAria)

$BtnLoad = New-Object System.Windows.Forms.Button; $BtnLoad.Text="REFRESH"; $BtnLoad.Location="630,25"; $BtnLoad.Size="80,35"; $BtnLoad.BackColor="DimGray"; $BtnLoad.ForeColor="White"; $BtnLoad.Font=$FontBold; $GbFilter.Controls.Add($BtnLoad)

# List & Status
$LblRes = New-Object System.Windows.Forms.Label; $LblRes.Text="Danh sach File:"; $LblRes.Location="20,150"; $LblRes.AutoSize=$true; $LblRes.Font=$FontNormal; $Form.Controls.Add($LblRes)
$CbResult = New-Object System.Windows.Forms.ComboBox; $CbResult.Location="20,175"; $CbResult.Size="720,35"; $CbResult.Font=New-Object System.Drawing.Font("Consolas", 11); $CbResult.DropDownStyle="DropDownList"; $Form.Controls.Add($CbResult)

$Bar = New-Object System.Windows.Forms.ProgressBar; $Bar.Location="20,270"; $Bar.Size="720,30"; $Form.Controls.Add($Bar)
$Status = New-Object System.Windows.Forms.Label; $Status.Text="San sang."; $Status.AutoSize=$true; $Status.Location="20,240"; $Status.ForeColor="Lime"; $Status.Font=$FontNormal; $Form.Controls.Add($Status)

$BtnDown = New-Object System.Windows.Forms.Button; $BtnDown.Text="KHOI DONG DOWNLOAD"; $BtnDown.Font=$FontBigBtn; $BtnDown.Location="200,330"; $BtnDown.Size="340,60"; $BtnDown.BackColor="LimeGreen"; $BtnDown.ForeColor="Black"; $BtnDown.FlatStyle="Flat"; $BtnDown.Enabled=$false; $Form.Controls.Add($BtnDown)

# --- WORKER SCRIPT ---
$ScriptBlock = {
    param($Url, $Start, $End, $Path)
    try {
        $Req = [System.Net.HttpWebRequest]::Create($Url); $Req.Method = "GET"; $Req.UserAgent = "Mozilla/5.0"; $Req.Timeout = 60000; $Req.ReadWriteTimeout = 60000
        $Req.AddRange([long]$Start, [long]$End); $Req.UnsafeAuthenticatedConnectionSharing = $true; $Req.KeepAlive = $true
        $Resp = $Req.GetResponse(); $Stream = $Resp.GetResponseStream()
        $Buf = New-Object byte[] 262144
        $Fs = New-Object System.IO.FileStream($Path, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None, 262144)
        $Max = ($End - $Start) + 1; $Tot = 0
        while (($R = $Stream.Read($Buf, 0, $Buf.Length)) -gt 0) {
            if (($Tot + $R) -gt $Max) { $R = $Max - $Tot }; $Fs.Write($Buf, 0, $R); $Tot += $R; if ($Tot -ge $Max) { break }
        }
        $Fs.Close(); $Stream.Close(); $Resp.Close()
    } catch { return $_.Exception.Message }
}

# --- NATIVE DOWNLOAD (FIXED UI) ---
function Start-NativeDownload ($Url, $DestPath, $ThreadCount, $SilentMode) {
    if (!$SilentMode) { $Status.Text = "KHOI DONG NATIVE ENGINE..." }
    [System.Windows.Forms.Application]::DoEvents()
    try {
        $ReqHead = [System.Net.HttpWebRequest]::Create($Url); $ReqHead.Method = "HEAD"; $ReqHead.UserAgent="Mozilla/5.0"
        $RespHead = $ReqHead.GetResponse(); $TotalSize = $RespHead.ContentLength; $RespHead.Close()
    } catch { if(!$SilentMode){[System.Windows.Forms.MessageBox]::Show("Loi Link: $($_.Exception.Message)","Error")}; return $false }

    if ($TotalSize -lt 50MB) { $Threads = 1 } else { $Threads = [int]$ThreadCount }
    $PartSize = [Math]::Floor($TotalSize / $Threads)
    $Pool = [runspacefactory]::CreateRunspacePool(1, $Threads); $Pool.Open(); $PowerShells = @(); $Handles = @()
    
    for ($i = 0; $i -lt $Threads; $i++) {
        $Start = $i * $PartSize; $End = ($i + 1) * $PartSize - 1; if ($i -eq $Threads - 1) { $End = $TotalSize - 1 }
        $PartPath = "$DestPath.part$i"
        $Ps = [powershell]::Create(); $Ps.RunspacePool = $Pool
        $Ps.AddScript($ScriptBlock).AddArgument($Url).AddArgument($Start).AddArgument($End).AddArgument($PartPath) | Out-Null
        $PowerShells += $Ps; $Handles += $Ps.BeginInvoke()
    }

    $IsDone = $false
    while (-not $IsDone) {
        $Downloaded = 0; $Completed = 0
        for ($i = 0; $i -lt $Threads; $i++) {
            $P = "$DestPath.part$i"; if (Test-Path $P) { try { $Info = Get-Item $P; $Downloaded += $Info.Length } catch {} }
            if ($Handles[$i].IsCompleted) { $Completed++ }
        }
        if ($TotalSize -gt 0) {
            $Percent = [Math]::Min(100, [Math]::Round(($Downloaded / $TotalSize) * 100))
            # --- FIX HIỂN THỊ SỐ ẢO Ở ĐÂY ---
            if (!$SilentMode) { 
                $CurrentMB = [Math]::Round($Downloaded / 1MB, 2)
                $TotalMB = [Math]::Round($TotalSize / 1MB, 2)
                $Bar.Value = [int]$Percent
                $Status.Text = "Dang tai... $Percent% ($CurrentMB MB / $TotalMB MB)" 
            }
            # --------------------------------
        }
        if ($Completed -eq $Threads) { $IsDone = $true }
        [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 200
    }
    foreach ($Ps in $PowerShells) { $Ps.Dispose() }; $Pool.Close(); $Pool.Dispose(); [GC]::Collect()

    if (!$SilentMode) { $Status.Text = "Dang ghep file (Merging)..." }
    try {
        $OutStream = New-Object System.IO.FileStream($DestPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None, 1048576)
        $MergeBuf = New-Object byte[] 1048576
        for ($i = 0; $i -lt $Threads; $i++) {
            $PartPath = "$DestPath.part$i"
            if (Test-Path $PartPath) {
                $InStream = [System.IO.File]::OpenRead($PartPath)
                while (($R = $InStream.Read($MergeBuf, 0, $MergeBuf.Length)) -gt 0) { $OutStream.Write($MergeBuf, 0, $R) }
                $InStream.Close(); $InStream.Dispose(); Remove-Item $PartPath -Force
            }
        }
        $OutStream.Close(); $OutStream.Dispose()
        if (!$SilentMode) { $Status.Text = "HOAN TAT!"; $Bar.Value = 100; [System.Windows.Forms.MessageBox]::Show("Tai thanh cong!", "Phat Tan PC"); Invoke-Item (Split-Path $DestPath) }
        return $true
    } catch { return $false }
}

# --- ARIA2 DOWNLOAD ---
function Start-AriaDownload ($Url, $DestPath, $ThreadCount, $ExePath, $SilentMode) {
    $Dir = Split-Path $DestPath; $FileName = Split-Path $DestPath -Leaf
    $ArgsList = "-x$ThreadCount -s$ThreadCount -k1M --file-allocation=none -d `"$Dir`" -o `"$FileName`" `"$Url`""
    if (!$SilentMode) { $Status.Text = "ARIA2 DANG CHAY (Vui long xem cua so CMD)..." }
    Start-Process -FilePath $ExePath -ArgumentList $ArgsList -Wait -NoNewWindow
    if (Test-Path $DestPath) {
        if (!$SilentMode) { $Status.Text = "HOAN TAT!"; [System.Windows.Forms.MessageBox]::Show("Tai thanh cong!", "Success"); Invoke-Item $Dir }
        return $true
    }
    return $false
}

# --- HANDLERS ---
function Load-JsonData {
    $Status.Text = "Dang tai du lieu..."; $Form.Cursor = "WaitCursor"
    try {
        $Ts = [DateTimeOffset]::Now.ToUnixTimeSeconds(); $Json = Invoke-RestMethod -Uri "$($JsonUrl.Trim())?t=$Ts"
        $Global:IsoData = $Json
        $CbType.Items.Clear(); $CbType.Items.Add("All"); ($Json.type | Select -Unique | Sort) | % { $CbType.Items.Add($_) }; $CbType.SelectedIndex=0
        $CbLang.Items.Clear(); $CbLang.Items.Add("All"); ($Json.language | Select -Unique | Sort) | % { $CbLang.Items.Add($_) }; $CbLang.SelectedIndex=0
        Filter-List; $Status.Text = "San sang."
    } catch { [System.Windows.Forms.MessageBox]::Show("Khong tai duoc danh sach ISO!","Loi Mang") }
    $Form.Cursor = "Default"
}

function Filter-List {
    $CbResult.Items.Clear(); $T = $CbType.SelectedItem; $B = $CbBit.SelectedItem; $L = $CbLang.SelectedItem; $List = $Global:IsoData
    if ($T -ne "All") { $List = $List | ? { $_.type -eq $T } }
    if ($B -ne "All") { $List = $List | ? { $_.bit -eq $B } }
    if ($L -ne "All") { $List = $List | ? { $_.language -eq $L } }
    foreach ($I in $List) { $CbResult.Items.Add($I.name) }
    if ($CbResult.Items.Count -gt 0) { $CbResult.SelectedIndex=0; $BtnDown.Enabled=$true } else { $BtnDown.Enabled=$false }
}

$CbType.Add_SelectedIndexChanged({ Filter-List }); $CbBit.Add_SelectedIndexChanged({ Filter-List }); $CbLang.Add_SelectedIndexChanged({ Filter-List }); $BtnLoad.Add_Click({ Load-JsonData })

# --- BTN DOWN LOGIC ---
$BtnDown.Add_Click({
    $Sel = $CbResult.SelectedItem
    $Item = $Global:IsoData | ? { $_.name -eq $Sel } | Select -First 1
    if (!$Item) { return }

    $SafeName = $Item.name -replace '[\\/:*?"<>|]', '' -replace '\s+', '_'
    if (-not $SafeName.EndsWith(".iso")) { $SafeName += ".iso" }

    $Save = New-Object System.Windows.Forms.SaveFileDialog; $Save.FileName = $SafeName; $Save.Filter = "ISO Files|*.iso|All Files|*.*"

    if ($Save.ShowDialog() -eq "OK") {
        $Threads = $CbThread.SelectedItem; $BtnDown.Enabled = $false; $CbResult.Enabled = $false
        $TargetFile = $Save.FileName; $Links = $Item.link -split "\|"
        
        $UseAria = $RadAria.Checked; $AriaExe = Get-Aria2Path
        if ($UseAria -and -not $AriaExe) { [System.Windows.Forms.MessageBox]::Show("Khong tim thay Aria2! Chuyen ve Native.", "Thong Bao"); $UseAria = $false }

        if ($Links.Count -gt 1) {
            $PartFiles = @(); $Count = 1; $Success = $true
            foreach ($L in $Links) {
                $PartName = "$TargetFile.part$Count.tmp"; $PartFiles += $PartName
                $Status.Text = "Dang tai PHAN $Count / $($Links.Count) ..."; $Bar.Value = [Math]::Round(($Count / $Links.Count) * 100); [System.Windows.Forms.Application]::DoEvents()
                
                if ($UseAria) { $Res = Start-AriaDownload $L $PartName $Threads $AriaExe $true } 
                else { $Res = Start-NativeDownload $L $PartName $Threads $true }

                if (-not $Res) { $Success = $false; break }; $Count++
            }
            if ($Success) {
                $Status.Text = "Dang noi file (Joining)..."; [System.Windows.Forms.Application]::DoEvents()
                try {
                    $CmdArgs = "/c copy /b "; foreach ($P in $PartFiles) { $CmdArgs += "`"$P`" + " }; $CmdArgs = $CmdArgs.Substring(0, $CmdArgs.Length - 3) + " `"$TargetFile`""
                    Start-Process -FilePath "cmd.exe" -ArgumentList $CmdArgs -Wait -WindowStyle Hidden
                    foreach ($P in $PartFiles) { Remove-Item $P -Force -ErrorAction SilentlyContinue }
                    $Status.Text = "HOAN TAT!"; $Bar.Value = 100; [System.Windows.Forms.MessageBox]::Show("Tai va noi file thanh cong!", "Phat Tan PC"); Invoke-Item (Split-Path $TargetFile)
                } catch { [System.Windows.Forms.MessageBox]::Show("Loi Join File!", "Error") }
            } else { [System.Windows.Forms.MessageBox]::Show("Loi khi tai cac phan!", "Error") }
        } else {
            $Status.Text = "Dang chuan bi..."; 
            if ($UseAria) { Start-AriaDownload $Links[0] $TargetFile $Threads $AriaExe $false } 
            else { Start-NativeDownload $Links[0] $TargetFile $Threads $false }
        }
        $BtnDown.Enabled = $true; $CbResult.Enabled = $true
    }
})

$Form.Add_Shown({ Load-JsonData })
$Form.ShowDialog() | Out-Null
