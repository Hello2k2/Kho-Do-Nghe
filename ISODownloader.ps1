# ISODownloader_v2.1_Turbo.ps1
# PHAT TAN PC - ISO DOWNLOADER EXTREME V2.1 (TURBO NATIVE ENGINE)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CẤU HÌNH ---
$JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/iso_list.json"

# --- TỐI ƯU KẾT NỐI (CONNECTION BOOST MAX) ---
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13
[System.Net.ServicePointManager]::DefaultConnectionLimit = 512 # Mở max cổng kết nối
[System.Net.ServicePointManager]::Expect100Continue = $false
[System.Net.ServicePointManager]::UseNagleAlgorithm = $false 
[System.Net.ServicePointManager]::CheckCertificateRevocationList = $false # Bỏ qua check thu hồi chứng chỉ cho nhanh

# --- CHECK ARIA2 ---
function Get-Aria2Path {
    $List = @(".\aria2c.exe", "$PSScriptRoot\aria2c.exe", "aria2c.exe")
    foreach ($Path in $List) {
        if (Get-Command $Path -ErrorAction SilentlyContinue) { return (Get-Command $Path).Source }
    }
    return $null
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "ISO DOWNLOADER EXTREME V2.1 - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(720, 520)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 30) # Màu tối hơn chút cho ngầu
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

$Global:IsoData = @()

# -- FONT SETUP --
$FontTitle = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$FontNormal = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$FontBold = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$FontBigBtn = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)

# Header
$Lbl = New-Object System.Windows.Forms.Label
$Lbl.Text = "KHO TAI NGUYEN (TURBO ENGINE)"
$Lbl.AutoSize = $true
$Lbl.Location = "20,15"
$Lbl.Font = $FontTitle
$Lbl.ForeColor = "Cyan"
$Form.Controls.Add($Lbl)

# Aria2 Status
$LblAria = New-Object System.Windows.Forms.Label
$AriaPath = Get-Aria2Path
if ($AriaPath) { 
    $LblAria.Text = "[ARIA2: ON]" 
    $LblAria.ForeColor = "Lime"
} else { 
    $LblAria.Text = "[NATIVE TURBO: ON]" 
    $LblAria.ForeColor = "Orange"
}
$LblAria.Location = "520,20"; $LblAria.AutoSize=$true; $LblAria.Font=$FontBold
$Form.Controls.Add($LblAria)

# Filter Box
$GbFilter = New-Object System.Windows.Forms.GroupBox
$GbFilter.Text = "Bo Loc & Cau Hinh"
$GbFilter.Location = "20,60"
$GbFilter.Size = "660,80"
$GbFilter.ForeColor = "Yellow"
$GbFilter.Font = $FontBold
$Form.Controls.Add($GbFilter)

# Combos
$CbType = New-Object System.Windows.Forms.ComboBox
$CbType.Location = "20,30"; $CbType.Size = "150,30"; $CbType.DropDownStyle = "DropDownList"; $CbType.Font = $FontNormal
$GbFilter.Controls.Add($CbType)

$CbBit = New-Object System.Windows.Forms.ComboBox
$CbBit.Location = "180,30"; $CbBit.Size = "100,30"; $CbBit.DropDownStyle = "DropDownList"; $CbBit.Font = $FontNormal
$CbBit.Items.AddRange(@("All", "x64", "x86", "arm64")); $CbBit.SelectedIndex = 0
$GbFilter.Controls.Add($CbBit)

# Threads
$LblThread = New-Object System.Windows.Forms.Label; $LblThread.Text = "Luong:"; $LblThread.Location = "300,33"; $LblThread.AutoSize = $true; $LblThread.Font = $FontNormal
$GbFilter.Controls.Add($LblThread)

$CbThread = New-Object System.Windows.Forms.ComboBox; $CbThread.Location = "360,30"; $CbThread.Size = "60,30"; $CbThread.DropDownStyle = "DropDownList"; $CbThread.Font = $FontNormal
$CbThread.Items.AddRange(@("4", "8", "16", "32")); $CbThread.SelectedItem = "16" 
$GbFilter.Controls.Add($CbThread)

# Refresh
$BtnLoad = New-Object System.Windows.Forms.Button; $BtnLoad.Text = "REFRESH"; $BtnLoad.Location = "520,25"; $BtnLoad.Size = "120,35"; $BtnLoad.BackColor = "DimGray"; $BtnLoad.ForeColor = "White"; $BtnLoad.Font = $FontBold
$GbFilter.Controls.Add($BtnLoad)

# Result
$LblRes = New-Object System.Windows.Forms.Label; $LblRes.Text = "Danh sach File:"; $LblRes.Location = "20,150"; $LblRes.AutoSize = $true; $LblRes.Font = $FontNormal; $Form.Controls.Add($LblRes)
$CbResult = New-Object System.Windows.Forms.ComboBox; $CbResult.Location = "20,175"; $CbResult.Size = "660,35"; $CbResult.Font = New-Object System.Drawing.Font("Consolas", 11); $CbResult.DropDownStyle = "DropDownList"; $Form.Controls.Add($CbResult)

# Progress
$Bar = New-Object System.Windows.Forms.ProgressBar; $Bar.Location = "20,270"; $Bar.Size = "660,30"; $Form.Controls.Add($Bar)
$Status = New-Object System.Windows.Forms.Label; $Status.Text = "San sang."; $Status.AutoSize = $true; $Status.Location = "20,240"; $Status.ForeColor = "Lime"; $Status.Font = $FontNormal; $Form.Controls.Add($Status)

# Download Button
$BtnDown = New-Object System.Windows.Forms.Button
$BtnDown.Text = "KHOI DONG TURBO DOWNLOAD"
$BtnDown.Font = $FontBigBtn
$BtnDown.Location = "180,330"
$BtnDown.Size = "340,60"
$BtnDown.BackColor = "LimeGreen"
$BtnDown.ForeColor = "Black"
$BtnDown.FlatStyle = "Flat"
$BtnDown.Enabled = $false
$Form.Controls.Add($BtnDown)

# --- WORKER SCRIPT BLOCK (UPGRADED NATIVE ENGINE) ---
$ScriptBlock = {
    param($Url, $Start, $End, $Path)
    try {
        $Req = [System.Net.HttpWebRequest]::Create($Url)
        $Req.Method = "GET"
        $Req.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        $Req.AddRange([long]$Start, [long]$End) 
        $Req.Timeout = 60000 
        $Req.ReadWriteTimeout = 60000
        $Req.ServicePoint.ConnectionLimit = 100
        # GIỮ KẾT NỐI ĐỂ TĂNG TỐC (Tránh Handshake lại)
        $Req.UnsafeAuthenticatedConnectionSharing = $true 
        $Req.KeepAlive = $true

        $Resp = $Req.GetResponse()
        
        if ($Resp.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $Start -gt 0) {
             $Resp.Close(); return "LOI: Server khong ho tro Resume (Tra ve 200 OK)."
        }

        $Stream = $Resp.GetResponseStream()
        
        # --- NÂNG BUFFER LÊN 256KB (Tối ưu cho mạng nhanh) ---
        $BufferSize = 262144 # 256 KB
        $Buffer = New-Object byte[] $BufferSize
        
        # Dùng FileStream với WriteThrough để ghi thẳng xuống đĩa
        $Fs = New-Object System.IO.FileStream($Path, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None, $BufferSize)
        
        $MaxBytes = ($End - $Start) + 1
        $TotalWritten = 0

        while (($Read = $Stream.Read($Buffer, 0, $Buffer.Length)) -gt 0) {
            if (($TotalWritten + $Read) -gt $MaxBytes) { $Read = $MaxBytes - $TotalWritten }
            $Fs.Write($Buffer, 0, $Read)
            $TotalWritten += $Read
            if ($TotalWritten -ge $MaxBytes) { break }
        }
        $Fs.Close(); $Stream.Close(); $Resp.Close()
    } catch { return $_.Exception.Message }
}

# --- FUNCTION: NATIVE DOWNLOAD (TURBO MODE) ---
function Start-NativeDownload ($Url, $DestPath, $ThreadCount) {
    $Status.Text = "KHOI DONG TURBO ENGINE ($ThreadCount Luong)..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        $ReqHead = [System.Net.HttpWebRequest]::Create($Url)
        $ReqHead.Method = "HEAD"; $ReqHead.UserAgent = "Mozilla/5.0"
        $RespHead = $ReqHead.GetResponse()
        $TotalSize = $RespHead.ContentLength
        $RespHead.Close()
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi Server: $($_.Exception.Message)", "Error"); return }

    # Tự động điều chỉnh luồng nếu file nhỏ
    if ($TotalSize -lt 50MB) { $Threads = 1 } else { $Threads = [int]$ThreadCount }
    
    $PartSize = [Math]::Floor($TotalSize / $Threads)
    $Pool = [runspacefactory]::CreateRunspacePool(1, $Threads)
    $Pool.Open()
    $PowerShells = @(); $Handles = @()

    $Status.Text = "Dang tai xuong (Turbo Mode ON)..."
    
    for ($i = 0; $i -lt $Threads; $i++) {
        $Start = $i * $PartSize
        $End = ($i + 1) * $PartSize - 1
        if ($i -eq $Threads - 1) { $End = $TotalSize - 1 }
        
        $PartPath = "$DestPath.part$i"
        $Ps = [powershell]::Create(); $Ps.RunspacePool = $Pool
        $Ps.AddScript($ScriptBlock).AddArgument($Url).AddArgument($Start).AddArgument($End).AddArgument($PartPath) | Out-Null
        $PowerShells += $Ps; $Handles += $Ps.BeginInvoke()
    }

    # Monitor Loop
    $IsDone = $false
    while (-not $IsDone) {
        $Downloaded = 0; $Completed = 0
        $ErrorMsg = $null

        for ($i = 0; $i -lt $Threads; $i++) {
            $P = "$DestPath.part$i"
            if (Test-Path $P) { try { $Info = Get-Item $P; $Downloaded += $Info.Length } catch {} }
            
            if ($Handles[$i].IsCompleted) { 
                $Completed++ 
                try { 
                    $Res = $PowerShells[$i].EndInvoke($Handles[$i])
                    if ($Res -match "LOI") { $ErrorMsg = $Res }
                } catch {}
            }
        }

        if ($ErrorMsg) {
             $Status.Text = "LOI: $ErrorMsg"
             foreach ($Ps in $PowerShells) { $Ps.Dispose() }; $Pool.Close(); $Pool.Dispose()
             [System.Windows.Forms.MessageBox]::Show($ErrorMsg, "Loi Download", "OK", "Error")
             return
        }

        if ($TotalSize -gt 0) {
            $Percent = [Math]::Min(100, [Math]::Round(($Downloaded / $TotalSize) * 100))
            $Bar.Value = $Percent
            $MB = [Math]::Round($Downloaded / 1MB, 2); $TotalMB = [Math]::Round($TotalSize / 1MB, 2)
            $Status.Text = "Downloading... $Percent% ($MB MB / $TotalMB MB)"
        }
        
        if ($Completed -eq $Threads) { $IsDone = $true }
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 200 # Giảm delay để update mượt hơn
    }

    # CLEANUP
    $Status.Text = "Don dep Threads..."
    foreach ($Ps in $PowerShells) { $Ps.Dispose() }; $Pool.Close(); $Pool.Dispose(); [GC]::Collect()

    # MERGE FILE (TỐI ƯU HÓA TỐC ĐỘ GHI)
    $Status.Text = "Dang ghep file (Merge)..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        # Dùng Buffer 1MB cho việc gộp file để max tốc độ HDD/SSD
        $MergeBuffer = New-Object byte[] 1048576 # 1MB
        $OutStream = New-Object System.IO.FileStream($DestPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None, 1048576)

        for ($i = 0; $i -lt $Threads; $i++) {
            $PartPath = "$DestPath.part$i"
            if (Test-Path $PartPath) {
                $InStream = [System.IO.File]::OpenRead($PartPath)
                
                # Copy thủ công với Buffer lớn
                while (($Read = $InStream.Read($MergeBuffer, 0, $MergeBuffer.Length)) -gt 0) {
                    $OutStream.Write($MergeBuffer, 0, $Read)
                }
                
                $InStream.Close(); $InStream.Dispose()
                Remove-Item $PartPath -Force -ErrorAction SilentlyContinue
                
                $MergePercent = [Math]::Round((($i + 1) / $Threads) * 100)
                $Status.Text = "Dang ghep file... $MergePercent%"
                [System.Windows.Forms.Application]::DoEvents()
            }
        }
        $OutStream.Close(); $OutStream.Dispose()
        
        $Status.Text = "HOAN TAT! (TURBO DOWNLOAD COMPLETED)"; $Bar.Value = 100
        [System.Windows.Forms.MessageBox]::Show("Tai thanh cong!", "Phat Tan PC")
        Invoke-Item (Split-Path $DestPath)
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi ghep file: $($_.Exception.Message)", "Error") }
}

# --- FUNCTION: ARIA2 DOWNLOAD ---
function Start-AriaDownload ($Url, $DestPath, $ThreadCount, $ExePath) {
    $Dir = Split-Path $DestPath
    $FileName = Split-Path $DestPath -Leaf
    $ArgsList = "-x$ThreadCount -s$ThreadCount -k1M --file-allocation=none -d `"$Dir`" -o `"$FileName`" `"$Url`""
    
    $Status.Text = "ARIA2 DANG CHAY..."
    $Bar.Value = 100
    Start-Process -FilePath $ExePath -ArgumentList $ArgsList -Wait
    
    if (Test-Path $DestPath) {
        $Status.Text = "HOAN TAT (ARIA2)!"
        [System.Windows.Forms.MessageBox]::Show("Aria2 da tai xong!", "Success")
        Invoke-Item $Dir
    } else {
        $Status.Text = "ARIA2 THAT BAI HOAC BI HUY."
    }
}

# --- HANDLERS ---
function Load-JsonData {
    $Status.Text = "Dang lay du lieu..."
    $Form.Cursor = "WaitCursor"
    try {
        $Ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        $CleanUrl = "$($JsonUrl.Trim())?t=$Ts"
        $JsonContent = Invoke-RestMethod -Uri $CleanUrl -ErrorAction Stop
        $Global:IsoData = $JsonContent
        
        $CbType.Items.Clear(); $CbType.Items.Add("All")
        $Types = $Global:IsoData | Select-Object -ExpandProperty type -Unique | Sort-Object
        foreach ($t in $Types) { $CbType.Items.Add($t) }
        $CbType.SelectedIndex = 0
        Filter-List
        $Status.Text = "Da tai xong danh sach ($($Global:IsoData.Count) file)."
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Loi JSON: $($_.Exception.Message)", "Error")
    }
    $Form.Cursor = "Default"
}

function Filter-List {
    $CbResult.Items.Clear()
    $T = $CbType.SelectedItem; $B = $CbBit.SelectedItem
    $List = $Global:IsoData
    if ($T -ne "All") { $List = $List | Where-Object { $_.type -eq $T } }
    if ($B -ne "All") { $List = $List | Where-Object { $_.bit -eq $B } }
    foreach ($I in $List) { $CbResult.Items.Add($I.name) }
    if ($CbResult.Items.Count -gt 0) { $CbResult.SelectedIndex=0; $BtnDown.Enabled=$true } else { $BtnDown.Enabled=$false }
}

$CbType.Add_SelectedIndexChanged({ Filter-List })
$CbBit.Add_SelectedIndexChanged({ Filter-List })
$BtnLoad.Add_Click({ Load-JsonData })

$BtnDown.Add_Click({
    $Sel = $CbResult.SelectedItem
    $Item = $Global:IsoData | Where-Object { $_.name -eq $Sel } | Select-Object -First 1
    if (!$Item) { return }
    
    $FName = "Download.iso"
    if ($Item.link -match "/([^/]+\.(iso|img|exe|zip|rar))$") { $FName = $Matches[1] }
    
    $Save = New-Object System.Windows.Forms.SaveFileDialog
    $Save.FileName = $FName; $Save.Filter = "All Files|*.*"
    
    if ($Save.ShowDialog() -eq "OK") {
        $Threads = $CbThread.SelectedItem
        $BtnDown.Enabled = $false; $CbResult.Enabled = $false
        
        $AriaExe = Get-Aria2Path
        if ($AriaExe) {
            Start-AriaDownload $Item.link $Save.FileName $Threads $AriaExe
        } else {
            Start-NativeDownload $Item.link $Save.FileName $Threads
        }
        
        $BtnDown.Enabled = $true; $CbResult.Enabled = $true
    }
})

$Form.Add_Shown({ Load-JsonData })
$Form.ShowDialog() | Out-Null
