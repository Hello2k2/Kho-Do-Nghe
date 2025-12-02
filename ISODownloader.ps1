Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CẤU HÌNH ---
$JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/iso_list.json"
$MaxThreads = 8 # So luong luong tai (Giong IDM)

# Tối ưu kết nối
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::DefaultConnectionLimit = 1000

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "ISO DOWNLOADER TURBO - PHAT TAN PC (8 THREADS)"
$Form.Size = New-Object System.Drawing.Size(700, 500)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

$Global:IsoData = @()

# Header
$Lbl = New-Object System.Windows.Forms.Label; $Lbl.Text = "KHO TAI NGUYEN (ENGINE DA LUONG)"; $Lbl.AutoSize=$true; $Lbl.Location="20,15"; $Lbl.Font="Segoe UI, 12, Bold"; $Lbl.ForeColor="Cyan"; $Form.Controls.Add($Lbl)

# Filter
$GbFilter = New-Object System.Windows.Forms.GroupBox; $GbFilter.Text="Bo Loc"; $GbFilter.Location="20,50"; $GbFilter.Size="640,70"; $GbFilter.ForeColor="Yellow"; $Form.Controls.Add($GbFilter)
$CbType = New-Object System.Windows.Forms.ComboBox; $CbType.Location="20,30"; $CbType.Size="150,30"; $CbType.DropDownStyle="DropDownList"; $GbFilter.Controls.Add($CbType)
$CbBit = New-Object System.Windows.Forms.ComboBox; $CbBit.Location="190,30"; $CbBit.Size="100,30"; $CbBit.DropDownStyle="DropDownList"; $CbBit.Items.AddRange(@("All", "x64", "x86", "arm64")); $CbBit.SelectedIndex=0; $GbFilter.Controls.Add($CbBit)
$BtnLoad = New-Object System.Windows.Forms.Button; $BtnLoad.Text="LAM MOI"; $BtnLoad.Location="500,25"; $BtnLoad.Size="120,35"; $BtnLoad.BackColor="DimGray"; $BtnLoad.ForeColor="White"; $GbFilter.Controls.Add($BtnLoad)

# List
$LblRes = New-Object System.Windows.Forms.Label; $LblRes.Text="Chon File:"; $LblRes.Location="20,130"; $LblRes.AutoSize=$true; $Form.Controls.Add($LblRes)
$CbResult = New-Object System.Windows.Forms.ComboBox; $CbResult.Location="20,155"; $CbResult.Size="640,35"; $CbResult.Font="Segoe UI, 11"; $CbResult.DropDownStyle="DropDownList"; $Form.Controls.Add($CbResult)

# Progress
$Bar = New-Object System.Windows.Forms.ProgressBar; $Bar.Location="20,250"; $Bar.Size="640,30"; $Form.Controls.Add($Bar)
$Status = New-Object System.Windows.Forms.Label; $Status.Text="San sang."; $Status.AutoSize=$true; $Status.Location="20,220"; $Status.ForeColor="Lime"; $Form.Controls.Add($Status)

# Button
$BtnDown = New-Object System.Windows.Forms.Button; $BtnDown.Text="DOWNLOAD TURBO (8 LUONG)"; $BtnDown.Font="Segoe UI, 12, Bold"; $BtnDown.Location="180,310"; $BtnDown.Size="340,50"; $BtnDown.BackColor="LimeGreen"; $BtnDown.ForeColor="Black"; $BtnDown.FlatStyle="Flat"; $BtnDown.Enabled=$false; $Form.Controls.Add($BtnDown)

# --- WORKER SCRIPT BLOCK (Chạy ngầm từng luồng) ---
$ScriptBlock = {
    param($Url, $Start, $End, $Path)
    try {
        $Req = [System.Net.HttpWebRequest]::Create($Url)
        $Req.Method = "GET"
        $Req.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
        $Req.AddRange($Start, $End)
        $Resp = $Req.GetResponse()
        $Stream = $Resp.GetResponseStream()
        
        $Buffer = New-Object byte[] 8192
        $Fs = [System.IO.File]::Create($Path)
        
        while (($Read = $Stream.Read($Buffer, 0, $Buffer.Length)) -gt 0) {
            $Fs.Write($Buffer, 0, $Read)
        }
        $Fs.Close(); $Stream.Close(); $Resp.Close()
    } catch { return $_.Exception.Message }
}

# --- CORE TẢI ĐA LUỒNG ---
function Start-TurboDownload ($Url, $DestPath) {
    $Status.Text = "Dang khoi tao ket noi..."
    [System.Windows.Forms.Application]::DoEvents()

    # 1. Lay kich thuoc file
    try {
        $ReqHead = [System.Net.HttpWebRequest]::Create($Url)
        $ReqHead.Method = "HEAD"
        $ReqHead.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
        $RespHead = $ReqHead.GetResponse()
        $TotalSize = $RespHead.ContentLength
        $RespHead.Close()
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi ket noi Server: $($_.Exception.Message)", "Error"); return }

    if ($TotalSize -lt 10MB) { $Threads = 1 } else { $Threads = $MaxThreads } # File nho thi 1 luong
    $PartSize = [Math]::Floor($TotalSize / $Threads)
    
    $Runspaces = @(); $PowerShells = @(); $Handles = @()
    $Pool = [runspacefactory]::CreateRunspacePool(1, $Threads)
    $Pool.Open()

    $Status.Text = "Dang chia nho file thanh $Threads phan..."
    
    # 2. Khoi tao cac luong (Threads)
    for ($i = 0; $i -lt $Threads; $i++) {
        $Start = $i * $PartSize
        $End = ($i + 1) * $PartSize - 1
        if ($i -eq $Threads - 1) { $End = $TotalSize - 1 } # Phan cuoi cung lay het
        
        $PartPath = "$DestPath.part$i"
        
        $Ps = [powershell]::Create()
        $Ps.RunspacePool = $Pool
        $Ps.AddScript($ScriptBlock).AddArgument($Url).AddArgument($Start).AddArgument($End).AddArgument($PartPath) | Out-Null
        
        $PowerShells += $Ps
        $Handles += $Ps.BeginInvoke()
    }

    # 3. Vong lap theo doi tien do
    $IsDone = $false
    while (-not $IsDone) {
        $Downloaded = 0
        $Completed = 0
        
        for ($i = 0; $i -lt $Threads; $i++) {
            $P = "$DestPath.part$i"
            if (Test-Path $P) { 
                $Info = Get-Item $P
                $Downloaded += $Info.Length 
            }
            if ($Handles[$i].IsCompleted) { $Completed++ }
        }

        # Update GUI
        if ($TotalSize -gt 0) {
            $Percent = [Math]::Min(100, [Math]::Round(($Downloaded / $TotalSize) * 100))
            $Bar.Value = $Percent
            $MB = [Math]::Round($Downloaded / 1MB, 2)
            $TotalMB = [Math]::Round($TotalSize / 1MB, 2)
            $Status.Text = "Downloading ($Threads Threads)... $Percent% ($MB MB / $TotalMB MB)"
        }
        
        if ($Completed -eq $Threads) { $IsDone = $true }
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 200
    }

    # 4. Ghep file (Merge)
    $Status.Text = "Dang ghep noi cac phan (Merging)..."
    [System.Windows.Forms.Application]::DoEvents()
    
    $OutStream = [System.IO.File]::Create($DestPath)
    for ($i = 0; $i -lt $Threads; $i++) {
        $PartPath = "$DestPath.part$i"
        if (Test-Path $PartPath) {
            $InBytes = [System.IO.File]::ReadAllBytes($PartPath)
            $OutStream.Write($InBytes, 0, $InBytes.Length)
            Remove-Item $PartPath -Force
        }
    }
    $OutStream.Close()
    
    $Pool.Close()
    $Status.Text = "HOAN TAT! File luu tai: $DestPath"
    $Bar.Value = 100
    [System.Windows.Forms.MessageBox]::Show("Tai thanh cong (Turbo Mode)!", "Phat Tan PC")
    Invoke-Item (Split-Path $DestPath)
}

# --- EVENT HANDLERS ---
function Load-JsonData {
    $Status.Text = "Dang tai danh sach tu Github..."
    $Form.Cursor = "WaitCursor"
    try {
        $Ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        $Headers = @{ "User-Agent" = "Mozilla/5.0"; "Cache-Control" = "no-cache" }
        $JsonContent = Invoke-RestMethod -Uri "$($JsonUrl.Trim())?t=$Ts" -Headers $Headers -ErrorAction Stop
        $Global:IsoData = $JsonContent
        
        $CbType.Items.Clear(); $CbType.Items.Add("All")
        $Types = $Global:IsoData | Select-Object -ExpandProperty type -Unique | Sort-Object
        foreach ($t in $Types) { $CbType.Items.Add($t) }
        $CbType.SelectedIndex = 0
        Filter-List
        $Status.Text = "San sang. ($($Global:IsoData.Count) muc)"
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Loi tai JSON: $($_.Exception.Message)", "Error")
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
    if ($Item.link -match "/([^/]+\.iso)$") { $FName = $Matches[1] }
    
    $Save = New-Object System.Windows.Forms.SaveFileDialog
    $Save.FileName = $FName; $Save.Filter = "ISO Files|*.iso|All|*.*"
    
    if ($Save.ShowDialog() -eq "OK") {
        $BtnDown.Enabled = $false; $CbResult.Enabled = $false
        Start-TurboDownload $Item.link $Save.FileName
        $BtnDown.Enabled = $true; $CbResult.Enabled = $true
    }
})

$Form.Add_Shown({ Load-JsonData })
$Form.ShowDialog() | Out-Null
