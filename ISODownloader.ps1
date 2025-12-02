Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CẤU HÌNH ---
$JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/iso_list.json"

# --- TỐI ƯU KẾT NỐI ---
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::DefaultConnectionLimit = 1000
[System.Net.ServicePointManager]::Expect100Continue = $false

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "ISO DOWNLOADER V6.0 - HYBRID ENGINE (IDM STYLE)"
$Form.Size = New-Object System.Drawing.Size(750, 550)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

$Global:IsoData = @()

# Fonts
$FontBold = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$FontNorm = New-Object System.Drawing.Font("Segoe UI", 10)

# Header
$Lbl = New-Object System.Windows.Forms.Label; $Lbl.Text = "KHO TAI NGUYEN (MULTI-ENGINE)"; $Lbl.AutoSize=$true; $Lbl.Location="20,15"; $Lbl.ForeColor="Cyan"; $Lbl.Font=$FontBold; $Form.Controls.Add($Lbl)

# --- CONFIG GROUP ---
$GbCfg = New-Object System.Windows.Forms.GroupBox; $GbCfg.Text="Cau Hinh Tai Xuong"; $GbCfg.Location="20,50"; $GbCfg.Size="690,80"; $GbCfg.ForeColor="Yellow"; $Form.Controls.Add($GbCfg)

# Engine Selector
$LblEng = New-Object System.Windows.Forms.Label; $LblEng.Text="Chon Engine:"; $LblEng.Location="20,30"; $LblEng.AutoSize=$true; $GbCfg.Controls.Add($LblEng)
$CbEngine = New-Object System.Windows.Forms.ComboBox; $CbEngine.Location="110,27"; $CbEngine.Size="150,30"; $CbEngine.DropDownStyle="DropDownList"
$CbEngine.Items.AddRange(@("TURBO (Nhanh - IDM)", "BITS (On dinh)")); $CbEngine.SelectedIndex=0; $GbCfg.Controls.Add($CbEngine)

# Thread Selector
$LblTh = New-Object System.Windows.Forms.Label; $LblTh.Text="So Luong:"; $LblTh.Location="280,30"; $LblTh.AutoSize=$true; $GbCfg.Controls.Add($LblTh)
$CbThread = New-Object System.Windows.Forms.ComboBox; $CbThread.Location="350,27"; $CbThread.Size="60,30"; $CbThread.DropDownStyle="DropDownList"
$CbThread.Items.AddRange(@("1", "4", "8", "16", "32")); $CbThread.SelectedIndex=2; $GbCfg.Controls.Add($CbThread) # Default 8

# Filter Bit
$LblBit = New-Object System.Windows.Forms.Label; $LblBit.Text="He:"; $LblBit.Location="430,30"; $LblBit.AutoSize=$true; $GbCfg.Controls.Add($LblBit)
$CbBit = New-Object System.Windows.Forms.ComboBox; $CbBit.Location="460,27"; $CbBit.Size="80,30"; $CbBit.DropDownStyle="DropDownList"; $CbBit.Items.AddRange(@("All", "x64", "x86", "arm64")); $CbBit.SelectedIndex=0; $GbCfg.Controls.Add($CbBit)

$BtnRef = New-Object System.Windows.Forms.Button; $BtnRef.Text="REFRESH"; $BtnRef.Location="570,25"; $BtnRef.Size="100,32"; $BtnRef.BackColor="DimGray"; $BtnRef.ForeColor="White"; $GbCfg.Controls.Add($BtnRef)

# List
$LblRes = New-Object System.Windows.Forms.Label; $LblRes.Text="Danh Sach File:"; $LblRes.Location="20,145"; $LblRes.AutoSize=$true; $Form.Controls.Add($LblRes)
$CbResult = New-Object System.Windows.Forms.ComboBox; $CbResult.Location="20,170"; $CbResult.Size="690,35"; $CbResult.Font=$FontNorm; $CbResult.DropDownStyle="DropDownList"; $Form.Controls.Add($CbResult)

# Progress
$Bar = New-Object System.Windows.Forms.ProgressBar; $Bar.Location="20,270"; $Bar.Size="690,30"; $Form.Controls.Add($Bar)
$Status = New-Object System.Windows.Forms.Label; $Status.Text="Trang thai: Cho lenh..."; $Status.AutoSize=$true; $Status.Location="20,240"; $Status.ForeColor="Lime"; $Form.Controls.Add($Status)

# Button
$BtnDown = New-Object System.Windows.Forms.Button; $BtnDown.Text="BAT DAU TAI (START DOWNLOAD)"; $BtnDown.Location="180,330"; $BtnDown.Size="380,60"; $BtnDown.BackColor="LimeGreen"; $BtnDown.ForeColor="Black"; $BtnDown.FlatStyle="Flat"; $BtnDown.Enabled=$false; $BtnDown.Font=$FontBold; $Form.Controls.Add($BtnDown)

# ==========================================
# ENGINE 1: TURBO (HttpWebRequest + Runspaces)
# ==========================================
$ScriptBlock_Turbo = {
    param($Url, $Start, $End, $Path)
    try {
        $Req = [System.Net.HttpWebRequest]::Create($Url)
        $Req.Method = "GET"
        # Fake User-Agent nhu Chrome de khong bi chan
        $Req.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        $Req.AddRange($Start, $End)
        $Req.Timeout = 60000
        $Req.ReadWriteTimeout = 60000
        $Resp = $Req.GetResponse()
        $Stream = $Resp.GetResponseStream()
        
        $Buffer = New-Object byte[] 65536 # 64KB Buffer
        $Fs = [System.IO.File]::Create($Path)
        
        while (($Read = $Stream.Read($Buffer, 0, $Buffer.Length)) -gt 0) {
            $Fs.Write($Buffer, 0, $Read)
        }
        $Fs.Close(); $Stream.Close(); $Resp.Close()
    } catch { return $_.Exception.Message }
}

function Start-Turbo ($Url, $DestPath, $ThreadCount) {
    $Status.Text = "Dang ket noi Server (Turbo Mode)..."
    [System.Windows.Forms.Application]::DoEvents()

    # 1. Get File Size
    try {
        $ReqHead = [System.Net.HttpWebRequest]::Create($Url)
        $ReqHead.Method = "HEAD"
        $ReqHead.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        $RespHead = $ReqHead.GetResponse()
        $TotalSize = $RespHead.ContentLength
        $RespHead.Close()
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi ket noi: $($_.Exception.Message)", "Error"); return }

    if ($TotalSize -lt 10MB) { $Threads = 1 } else { $Threads = [int]$ThreadCount }
    $PartSize = [Math]::Floor($TotalSize / $Threads)
    
    $Pool = [runspacefactory]::CreateRunspacePool(1, $Threads); $Pool.Open()
    $PowerShells = @(); $Handles = @()

    $Status.Text = "Khoi tao $Threads luong tai xuong..."
    
    # 2. Start Threads
    for ($i = 0; $i -lt $Threads; $i++) {
        $Start = $i * $PartSize
        $End = ($i + 1) * $PartSize - 1
        if ($i -eq $Threads - 1) { $End = $TotalSize - 1 }
        
        $PartPath = "$DestPath.part$i"
        $Ps = [powershell]::Create(); $Ps.RunspacePool = $Pool
        $Ps.AddScript($ScriptBlock_Turbo).AddArgument($Url).AddArgument($Start).AddArgument($End).AddArgument($PartPath) | Out-Null
        $PowerShells += $Ps
        $Handles += $Ps.BeginInvoke()
    }

    # 3. Monitor
    $IsDone = $false
    while (-not $IsDone) {
        $Downloaded = 0; $Completed = 0
        for ($i = 0; $i -lt $Threads; $i++) {
            $P = "$DestPath.part$i"
            if (Test-Path $P) { try{$Downloaded += (Get-Item $P).Length}catch{} }
            if ($Handles[$i].IsCompleted) { $Completed++ }
        }

        if ($TotalSize -gt 0) {
            $Pct = [Math]::Min(100, [Math]::Round(($Downloaded / $TotalSize) * 100))
            $Bar.Value = [int]$Pct
            $MB_Cur = [Math]::Round($Downloaded/1MB, 2); $MB_Tot = [Math]::Round($TotalSize/1MB, 2)
            $Status.Text = "TURBO Downloading ($Threads Threads)... $Pct% ($MB_Cur MB / $MB_Tot MB)"
        }
        if ($Completed -eq $Threads) { $IsDone = $true }
        [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 500
    }

    # 4. Merge
    $Status.Text = "Dang ghep noi file... (Dung tat may)"
    [System.Windows.Forms.Application]::DoEvents()
    $Out = [System.IO.File]::Create($DestPath)
    for ($i = 0; $i -lt $Threads; $i++) {
        $P = "$DestPath.part$i"
        if (Test-Path $P) {
            $Bytes = [System.IO.File]::ReadAllBytes($P); $Out.Write($Bytes, 0, $Bytes.Length); Remove-Item $P -Force
        }
    }
    $Out.Close(); $Pool.Close()
    $Status.Text = "HOAN TAT!"; $Bar.Value = 100
    [System.Windows.Forms.MessageBox]::Show("Tai xong (Turbo)!", "Success"); Invoke-Item (Split-Path $DestPath)
}

# ==========================================
# ENGINE 2: BITS (Microsoft)
# ==========================================
function Start-Bits ($Url, $DestPath) {
    Import-Module BitsTransfer
    $Status.Text = "Khoi tao BITS..."
    try {
        $Job = Start-BitsTransfer -Source $Url -Destination $DestPath -Asynchronous -Priority Foreground
        
        do {
            $Job = Get-BitsTransfer -JobId $Job.JobId
            if ($Job.JobState -eq "Transferring" -or $Job.JobState -eq "Transferred") {
                if ($Job.TotalBytes -gt 0) {
                    $Pct = [Math]::Min(100, [Math]::Round(($Job.BytesTransferred / $Job.TotalBytes) * 100))
                    $Bar.Value = [int]$Pct
                    $MB_Cur = [Math]::Round($Job.BytesTransferred/1MB, 2); $MB_Tot = [Math]::Round($Job.TotalBytes/1MB, 2)
                    $Status.Text = "BITS Downloading... $Pct% ($MB_Cur MB / $MB_Tot MB)"
                } else { $Status.Text = "Dang ket noi & cap phat dung luong..." }
            }
            [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 500
        } while ($Job.JobState -ne "Transferred" -and $Job.JobState -ne "Error" -and $Job.JobState -ne "TransientError")
        
        if ($Job.JobState -eq "Transferred") {
            Complete-BitsTransfer -JobId $Job.JobId
            $Status.Text = "HOAN TAT!"; $Bar.Value = 100
            [System.Windows.Forms.MessageBox]::Show("Tai xong (BITS)!", "Success"); Invoke-Item (Split-Path $DestPath)
        } else {
            Remove-BitsTransfer -JobId $Job.JobId
            [System.Windows.Forms.MessageBox]::Show("Loi BITS: $($Job.ErrorDescription)", "Error")
        }
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi: $($_.Exception.Message)", "Error") }
}

# --- HANDLERS ---
function Load-Json {
    $Status.Text = "Dang lay danh sach..."; $Form.Cursor = "WaitCursor"
    try {
        $Ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        $H = @{ "User-Agent"="Mozilla/5.0"; "Cache-Control"="no-cache" }
        $J = Invoke-RestMethod -Uri "$($JsonUrl.Trim())?t=$Ts" -Headers $H -ErrorAction Stop
        $Global:IsoData = $J
        Filter-List; $Status.Text = "San sang."
    } catch { $Status.Text="Loi JSON!"; [System.Windows.Forms.MessageBox]::Show($_.Exception.Message) }
    $Form.Cursor = "Default"
}

function Filter-List {
    $CbResult.Items.Clear(); $B = $CbBit.SelectedItem
    $L = $Global:IsoData | Where-Object { if ($B -ne "All") { $_.bit -eq $B } else { $true } }
    foreach ($I in $L) { $CbResult.Items.Add($I.name) }
    if ($CbResult.Items.Count -gt 0) { $CbResult.SelectedIndex=0; $BtnDown.Enabled=$true } else { $BtnDown.Enabled=$false }
}

$BtnRef.Add_Click({ Load-Json })
$CbBit.Add_SelectedIndexChanged({ Filter-List })

$BtnDown.Add_Click({
    $Item = $Global:IsoData | Where-Object { $_.name -eq $CbResult.SelectedItem } | Select-Object -First 1
    if (!$Item) { return }
    $Name = "Download.iso"
    if ($Item.link -match "/([^/]+\.iso)$") { $Name = $Matches[1] }
    
    $Save = New-Object System.Windows.Forms.SaveFileDialog; $Save.FileName=$Name; $Save.Filter="ISO Files|*.iso|All|*.*"
    if ($Save.ShowDialog() -eq "OK") {
        $BtnDown.Enabled=$false; $CbResult.Enabled=$false
        if ($CbEngine.SelectedItem -match "TURBO") { Start-Turbo $Item.link $Save.FileName $CbThread.SelectedItem }
        else { Start-Bits $Item.link $Save.FileName }
        $BtnDown.Enabled=$true; $CbResult.Enabled=$true
    }
})

$Form.Add_Shown({ Load-Json })
$Form.ShowDialog() | Out-Null
