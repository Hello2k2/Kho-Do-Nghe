<#
    WIN AIO BUILDER - PHAT TAN PC
    Version: 7.4 (CLOUD JSON BOOTKITS)
    - Feature: Load danh sách Boot Kit (Win10/11) từ file JSON Online.
    - Feature: Chọn Boot Kit linh hoạt qua Menu thả xuống.
    - Core: Giữ nguyên các fix bảo vệ (Disk Guard, Nuclear Wipe).
#>

# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- GLOBAL ERROR HANDLING ---
try {

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"

# --- GLOBAL VARIABLES ---
$Global:IsoCache = @{} 
$Global:TempWimDir = "$env:TEMP\PhatTan_Wims"
$Global:BootKitCacheDir = "$env:TEMP\PhatTan_BootKits"

# [CONFIG] Link file JSON chứa danh sách Boot Kit (Thay link của ông vào đây)
$Global:JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/bootkits.json" 
# Link dự phòng nếu chưa có file JSON (để test)
$Global:DefaultBootKits = @(
    @{Name="Boot Kit Windows 10 (Default)"; Url="https://example.com/w10.zip"; FileName="w10.zip"}
)

if (!(Test-Path $Global:TempWimDir)) { New-Item -ItemType Directory -Path $Global:TempWimDir -Force | Out-Null }
if (!(Test-Path $Global:BootKitCacheDir)) { New-Item -ItemType Directory -Path $Global:BootKitCacheDir -Force | Out-Null }

# --- THEME ENGINE ---
$Theme = @{
    Back      = [System.Drawing.Color]::FromArgb(30, 30, 30)
    Card      = [System.Drawing.Color]::FromArgb(40, 40, 43)
    Text      = [System.Drawing.Color]::FromArgb(240, 240, 240)
    BtnBack   = [System.Drawing.Color]::FromArgb(60, 60, 60)
    BtnHover  = [System.Drawing.Color]::FromArgb(255, 140, 0)
    Accent    = [System.Drawing.Color]::FromArgb(0, 255, 255)
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WIN AIO BUILDER v7.4 - PHAT TAN PC (CLOUD CONFIG)"
$Form.Size = New-Object System.Drawing.Size(950, 850)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back; $Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "PHAT TAN PC - SYSTEM BUILDER"; $LblT.Font = New-Object System.Drawing.Font("Impact", 20); $LblT.ForeColor = $Theme.Accent; $LblT.AutoSize = $true; $LblT.Location = "20,10"; $Form.Controls.Add($LblT)

# --- TAB CONTROL ---
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = "20,60"; $TabControl.Size = "900,730"
$TabControl.Appearance = "FlatButtons"; $TabControl.ItemSize = New-Object System.Drawing.Size(150, 30)

$TabAIO = New-Object System.Windows.Forms.TabPage; $TabAIO.Text = "  1. GHEP ISO AIO  "; $TabAIO.BackColor = $Theme.Back
$TabControl.Controls.Add($TabAIO)

$TabW2I = New-Object System.Windows.Forms.TabPage; $TabW2I.Text = "  2. WIM TO ISO  "; $TabW2I.BackColor = $Theme.Back
$TabControl.Controls.Add($TabW2I)

$Form.Controls.Add($TabControl)

# ==================== GUI TAB 1: AIO BUILDER (GIỮ NGUYÊN) ====================
$GbIso = New-Object System.Windows.Forms.GroupBox; $GbIso.Text = "Danh Sách ISO Nguồn"; $GbIso.Location = "15,15"; $GbIso.Size = "860,250"; $GbIso.ForeColor = "Yellow"; $TabAIO.Controls.Add($GbIso)
$TxtIsoList = New-Object System.Windows.Forms.TextBox; $TxtIsoList.Location = "15,25"; $TxtIsoList.Size = "550,25"; $TxtIsoList.ReadOnly = $true; $GbIso.Controls.Add($TxtIsoList)
$BtnAdd = New-Object System.Windows.Forms.Button; $BtnAdd.Text = "THEM ISO"; $BtnAdd.Location = "580,23"; $BtnAdd.Size = "90,27"; $BtnAdd.BackColor = "DimGray"; $BtnAdd.ForeColor = "White"; $GbIso.Controls.Add($BtnAdd)
$BtnEject = New-Object System.Windows.Forms.Button; $BtnEject.Text = "RESET"; $BtnEject.Location = "680,23"; $BtnEject.Size = "80,27"; $BtnEject.BackColor = "DarkRed"; $BtnEject.ForeColor = "White"; $GbIso.Controls.Add($BtnEject)
$Grid = New-Object System.Windows.Forms.DataGridView; $Grid.Location = "15,60"; $Grid.Size = "830,175"; $Grid.BackgroundColor = "Black"; $Grid.ForeColor = "Black"; $Grid.AllowUserToAddRows = $false; $Grid.RowHeadersVisible = $false; $Grid.SelectionMode = "FullRowSelect"; $Grid.AutoSizeColumnsMode = "Fill"
$ColChk = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn; $ColChk.Name = "Select"; $ColChk.HeaderText = "[X]"; $ColChk.Width = 40; $Grid.Columns.Add($ColChk) | Out-Null
$Grid.Columns.Add("ISO", "File"); $Grid.Columns.Add("Index", "Idx"); $Grid.Columns.Add("Name", "Version"); $Grid.Columns.Add("Size", "Size"); $Grid.Columns.Add("Arch", "Bit"); $Grid.Columns.Add("WimPath", "WimPath"); $Grid.Columns.Add("BuildVer", "Kernel"); $Grid.Columns[7].Visible = $false; $Grid.Columns[6].Visible = $false; $Grid.Columns[5].Visible = $false;
$Grid.Columns[1].Width = 50; $Grid.Columns[3].Width = 80; $Grid.Columns[4].Width = 60; $GbIso.Controls.Add($Grid)

$GbBuild = New-Object System.Windows.Forms.GroupBox; $GbBuild.Text = "Cấu Hình & Build AIO"; $GbBuild.Location = "15,280"; $GbBuild.Size = "860,100"; $GbBuild.ForeColor = "Lime"; $TabAIO.Controls.Add($GbBuild)
$LblOut = New-Object System.Windows.Forms.Label; $LblOut.Text = "Output:"; $LblOut.Location = "15,25"; $LblOut.AutoSize = $true; $GbBuild.Controls.Add($LblOut)
$TxtOut = New-Object System.Windows.Forms.TextBox; $TxtOut.Location = "70,22"; $TxtOut.Size = "350,25"; $TxtOut.Text = "D:\AIO_Output"; $GbBuild.Controls.Add($TxtOut)
$BtnBrowseOut = New-Object System.Windows.Forms.Button; $BtnBrowseOut.Text = "..."; $BtnBrowseOut.Location = "430,20"; $BtnBrowseOut.Size = "40,27"; $GbBuild.Controls.Add($BtnBrowseOut)
$BtnBuild = New-Object System.Windows.Forms.Button; $BtnBuild.Text = "START BUILD AIO"; $BtnBuild.Location = "500,20"; $BtnBuild.Size = "340,60"; $BtnBuild.BackColor = "Green"; $BtnBuild.ForeColor = "White"; $BtnBuild.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold); $GbBuild.Controls.Add($BtnBuild)

$MenuBuild = New-Object System.Windows.Forms.ContextMenu
$Item1 = $MenuBuild.MenuItems.Add("1. Build ra folder cai dat (install.wim)")
$Item2 = $MenuBuild.MenuItems.Add("2. Tao cau truc ISO Boot (Full)")

$GbIsoTool = New-Object System.Windows.Forms.GroupBox; $GbIsoTool.Text = "ISO & HDD Boot Tools"; $GbIsoTool.Location = "15,390"; $GbIsoTool.Size = "860,100"; $GbIsoTool.ForeColor = "Orange"; $TabAIO.Controls.Add($GbIsoTool)
$MenuIsoHidden = New-Object System.Windows.Forms.ContextMenu
$MItem_Default = $MenuIsoHidden.MenuItems.Add("1. Tao ISO tu thu muc hien tai (Default)")
$MItem_Custom  = $MenuIsoHidden.MenuItems.Add("2. Chon thu muc nguon khac de tao ISO... (Import)")
$BtnMakeIso = New-Object System.Windows.Forms.Button; $BtnMakeIso.Text = "MAKE ISO"; $BtnMakeIso.Location = "20,30"; $BtnMakeIso.Size = "400,50"; $BtnMakeIso.BackColor = "DarkOrange"; $BtnMakeIso.ForeColor = "Black"; $GbIsoTool.Controls.Add($BtnMakeIso)
$BtnHddBoot = New-Object System.Windows.Forms.Button; $BtnHddBoot.Text = "HDD BOOT"; $BtnHddBoot.Location = "440,30"; $BtnHddBoot.Size = "400,50"; $BtnHddBoot.BackColor = "Firebrick"; $BtnHddBoot.ForeColor = "White"; $GbIsoTool.Controls.Add($BtnHddBoot)

$TxtLog = New-Object System.Windows.Forms.TextBox; $TxtLog.Multiline = $true; $TxtLog.Location = "15,500"; $TxtLog.Size = "860,180"; $TxtLog.BackColor = "Black"; $TxtLog.ForeColor = "Lime"; $TxtLog.ReadOnly = $true; $TxtLog.ScrollBars = "Vertical"; $TabAIO.Controls.Add($TxtLog)


# ==================== GUI TAB 2: WIM TO ISO (NÂNG CẤP) ====================
$GbWimIn = New-Object System.Windows.Forms.GroupBox; $GbWimIn.Text = "1. Chon File WIM Nguon"; $GbWimIn.Location = "20,20"; $GbWimIn.Size = "850,80"; $GbWimIn.ForeColor = "Cyan"; $TabW2I.Controls.Add($GbWimIn)
$TxtWimIn = New-Object System.Windows.Forms.TextBox; $TxtWimIn.Location = "20,30"; $TxtWimIn.Size = "650,25"; $GbWimIn.Controls.Add($TxtWimIn)
$BtnBrWim = New-Object System.Windows.Forms.Button; $BtnBrWim.Text = "CHON WIM..."; $BtnBrWim.Location = "690,28"; $BtnBrWim.Size = "140,27"; $BtnBrWim.BackColor = "DimGray"; $BtnBrWim.ForeColor = "White"; $GbWimIn.Controls.Add($BtnBrWim)

$GbBootBase = New-Object System.Windows.Forms.GroupBox; $GbBootBase.Text = "2. Chon Nguon Boot (ISO 'Vo')"; $GbBootBase.Location = "20,110"; $GbBootBase.Size = "850,130"; $GbBootBase.ForeColor = "Yellow"; $TabW2I.Controls.Add($GbBootBase)

# Radio Buttons
$RbUseLocal = New-Object System.Windows.Forms.RadioButton; $RbUseLocal.Text = "Dung ISO co san trong may"; $RbUseLocal.Location = "20,25"; $RbUseLocal.AutoSize = $true; $RbUseLocal.Checked = $true; $GbBootBase.Controls.Add($RbUseLocal)
$RbUseCloud = New-Object System.Windows.Forms.RadioButton; $RbUseCloud.Text = "Tai Boot Kit tu Server (JSON)"; $RbUseCloud.Location = "20,75"; $RbUseCloud.AutoSize = $true; $GbBootBase.Controls.Add($RbUseCloud)

# Local ISO Controls
$TxtBaseIso = New-Object System.Windows.Forms.TextBox; $TxtBaseIso.Location = "40,50"; $TxtBaseIso.Size = "630,25"; $GbBootBase.Controls.Add($TxtBaseIso)
$BtnBrBase = New-Object System.Windows.Forms.Button; $BtnBrBase.Text = "BROWSE..."; $BtnBrBase.Location = "690,48"; $BtnBrBase.Size = "140,27"; $BtnBrBase.BackColor = "DimGray"; $BtnBrBase.ForeColor = "White"; $GbBootBase.Controls.Add($BtnBrBase)

# Cloud ISO Controls (ComboBox)
$CbBootKits = New-Object System.Windows.Forms.ComboBox; $CbBootKits.Location = "40,100"; $CbBootKits.Size = "630,25"; $CbBootKits.Enabled = $false; $GbBootBase.Controls.Add($CbBootKits)
$BtnRefresh = New-Object System.Windows.Forms.Button; $BtnRefresh.Text = "REFRESH LIST"; $BtnRefresh.Location = "690,98"; $BtnRefresh.Size = "140,27"; $BtnRefresh.BackColor = "Teal"; $BtnRefresh.ForeColor = "White"; $BtnRefresh.Enabled = $false; $GbBootBase.Controls.Add($BtnRefresh)

$GbOutW2I = New-Object System.Windows.Forms.GroupBox; $GbOutW2I.Text = "3. Xuat File ISO"; $GbOutW2I.Location = "20,250"; $GbOutW2I.Size = "850,100"; $GbOutW2I.ForeColor = "Lime"; $TabW2I.Controls.Add($GbOutW2I)
$BtnStartW2I = New-Object System.Windows.Forms.Button; $BtnStartW2I.Text = "TAO ISO TU FILE WIM"; $BtnStartW2I.Location = "225,30"; $BtnStartW2I.Size = "400,50"; $BtnStartW2I.BackColor = "Green"; $BtnStartW2I.ForeColor = "White"; $BtnStartW2I.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold); $GbOutW2I.Controls.Add($BtnStartW2I)

$TxtLog2 = New-Object System.Windows.Forms.TextBox; $TxtLog2.Multiline = $true; $TxtLog2.Location = "20,360"; $TxtLog2.Size = "850,310"; $TxtLog2.BackColor = "Black"; $TxtLog2.ForeColor = "Cyan"; $TxtLog2.ReadOnly = $true; $TxtLog2.ScrollBars = "Vertical"; $TabW2I.Controls.Add($TxtLog2)


# --- COMMON FUNCTIONS ---
function Log ($M) { 
    $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $M`r`n"); $TxtLog.ScrollToCaret()
    $TxtLog2.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $M`r`n"); $TxtLog2.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents() 
}

function Get-7Zip {
    $7z = "$env:TEMP\7zr.exe"; if (Test-Path $7z) { return $7z }
    Log "Dang tai 7-Zip..."; try { (New-Object System.Net.WebClient).DownloadFile("https://www.7-zip.org/a/7zr.exe", $7z); return $7z } catch { Log "Loi tai 7-Zip!"; return $null }
}

function Get-Oscdimg {
    $Tool = "$env:TEMP\oscdimg.exe"; if (Test-Path $Tool) { return $Tool }
    try { (New-Object System.Net.WebClient).DownloadFile("https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/refs/heads/main/oscdimg.exe", $Tool); if ((Get-Item $Tool).Length -gt 100kb) { return $Tool } } catch {}
    
    $AdkPaths = @("$env:ProgramFiles(x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe", "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe")
    foreach ($P in $AdkPaths) { if (Test-Path $P) { return $P } }
    
    if ([System.Windows.Forms.MessageBox]::Show("Khong tim thay oscdimg.exe. Tai ADK tu Microsoft?", "Download", "YesNo") -eq "Yes") {
        try { (New-Object System.Net.WebClient).DownloadFile("https://go.microsoft.com/fwlink/?linkid=2243390", "$env:TEMP\adksetup.exe"); Start-Process "$env:TEMP\adksetup.exe" -Wait; foreach ($P in $AdkPaths) { if (Test-Path $P) { return $P } } } catch {}
    }
    return $null
}

function Get-IsoDrive ($IsoPath) {
    if ($Global:IsoCache.ContainsKey($IsoPath)) {
        $CachedDrv = $Global:IsoCache[$IsoPath]
        if ((Test-Path "$CachedDrv\sources") -or (Test-Path "$CachedDrv\bootmgr")) { return $CachedDrv } else { $Global:IsoCache.Remove($IsoPath) }
    }
    try {
        $Img = Get-DiskImage -ImagePath $IsoPath -ErrorAction SilentlyContinue
        if ($Img -and $Img.Attached) { $Vol = $Img | Get-Volume; if ($Vol) { return "$($Vol.DriveLetter):" } }
    } catch {}
    return $null
}

# --- AIO LOGIC ---
function Scan-Wim ($WimPath, $SourceName) {
    try {
        $Info = Get-WindowsImage -ImagePath $WimPath
        foreach ($I in $Info) {
            $RealVer = $I.Version; if (!$RealVer) { $RealVer = "0.0.0.0" }
            $Grid.Rows.Add($true, $SourceName, $I.ImageIndex, $I.ImageName, "$([Math]::Round($I.Size/1GB,2)) GB", $I.Architecture, $WimPath, $RealVer) | Out-Null
        }
        Log "Loaded: $SourceName"
    } catch { Log "Loi WIM: $WimPath" }
}

function Process-Iso ($IsoPath) {
    $Form.Cursor = "WaitCursor"; Log "Reading: $IsoPath..."
    $Drv = Get-IsoDrive $IsoPath 
    if (!$Drv) { try { Mount-DiskImage -ImagePath $IsoPath -StorageType ISO -ErrorAction Stop | Out-Null; for($i=0;$i -lt 15;$i++){ $Drv = Get-IsoDrive $IsoPath; if($Drv){ break }; Start-Sleep -Milliseconds 500 } } catch {} } 
    if ($Drv) {
        $Global:IsoCache[$IsoPath] = $Drv
        $WimFiles = Get-ChildItem -Path $Drv -Include "install.wim","install.esd" -Recurse -ErrorAction SilentlyContinue
        if ($WimFiles) { Scan-Wim $WimFiles[0].FullName $IsoPath; $Form.Cursor="Default"; return }
    }
    Log "Mount failed. 7-Zip scan..."
    Dismount-DiskImage -ImagePath $IsoPath -ErrorAction SilentlyContinue | Out-Null
    $7z = Get-7Zip; if ($7z) {
        $Hash = (Get-Item $IsoPath).Name.GetHashCode(); $ExtractDir = "$Global:TempWimDir\$Hash"; New-Item -ItemType Directory -Path $ExtractDir -Force | Out-Null
        Start-Process $7z -ArgumentList "e `"$IsoPath`" sources/install.wim sources/install.esd -o`"$ExtractDir`" -y" -NoNewWindow -Wait
        $ExtWim = Get-ChildItem -Path $ExtractDir -Include "install.wim","install.esd" -Recurse -ErrorAction SilentlyContinue
        if ($ExtWim) { Scan-Wim $ExtWim[0].FullName $IsoPath }
    }
    $Form.Cursor = "Default"
}

# --- BUILD CORE (AIO TAB) - V7.3 SMART PRIORITY ---
function Build-Core ($CopyBoot) {
    $RawDir = $TxtOut.Text; if (!$RawDir) { return }
    $Dir = $RawDir -replace '/', '\' 
    
    $RootDrive = [System.IO.Path]::GetPathRoot($Dir)
    $DriveInfo = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $RootDrive.Trim('\') }
    if ($DriveInfo.DriveType -eq 5) { [System.Windows.Forms.MessageBox]::Show("Khong the luu vao o dia CD/DVD!", "Loi"); return }

    if (!(Test-Path $Dir)) { New-Item -ItemType Directory -Path $Dir -Force | Out-Null }
    $SourceDir = "$Dir\sources"; if (!(Test-Path $SourceDir)) { New-Item -ItemType Directory -Path $SourceDir -Force | Out-Null }

    $Tasks = @(); foreach($r in $Grid.Rows){if($r.Cells[0].Value){$Tasks+=$r}}
    if($Tasks.Count -eq 0){ [System.Windows.Forms.MessageBox]::Show("Chua chon phien ban!", "Loi"); return }

    $BtnBuild.Enabled=$false
    
    if ($CopyBoot) {
        Log "Dang phan tich de chon Boot Base xin nhat..."
        $BestIsoRow = $Tasks[0]; $HighestScore = -1
        foreach ($Row in $Tasks) {
            $Score = 0; $Name = $Row.Cells[3].Value.ToString().ToLower(); $VerStr = $Row.Cells[7].Value.ToString()
            if ($Name -match "windows 11") { $Score += 10000 } elseif ($Name -match "windows 10") { $Score += 5000 } elseif ($Name -match "windows 8") { $Score += 1000 }
            try { $VerObj = [Version]$VerStr; $Score += $VerObj.Major * 100 + $VerObj.Minor } catch {}
            if ($Score -gt $HighestScore) { $HighestScore = $Score; $BestIsoRow = $Row }
        }
        
        Log "=> CHOT DON: $($BestIsoRow.Cells[3].Value) (Score: $HighestScore) lam Boot Base."
        $FirstSource = $BestIsoRow.Cells[1].Value; $Drv = Get-IsoDrive $FirstSource

        if (!$Drv) {
            Log "Dismount & 7-Zip Mode..."
            Dismount-DiskImage -ImagePath $FirstSource -ErrorAction SilentlyContinue | Out-Null
            $7z = Get-7Zip; $ZArgs = @("x", "$FirstSource", "-o$Dir", "-x!sources\install.wim", "-x!sources\install.esd", "-y")
            Start-Process $7z -ArgumentList $ZArgs -NoNewWindow -Wait
        } else {
            Log "Tim thay o dia: $Drv (Robocopy Mirror Mode)..."
            $RoboArgs = @($Drv.TrimEnd('\'), $Dir.TrimEnd('\'), "/E", "/XF", "install.wim", "install.esd", "/MT:16", "/NFL", "/NDL")
            Start-Process "robocopy.exe" -ArgumentList $RoboArgs -NoNewWindow -Wait
        }

        Log "Nuclear Wipe..."; Start-Process "attrib" -ArgumentList "-r `"$Dir\*.*`" /s /d" -NoNewWindow -Wait
        if (Test-Path "$SourceDir\install.wim") { Remove-Item "$SourceDir\install.wim" -Force -ErrorAction SilentlyContinue }
        if (Test-Path "$SourceDir\install.esd") { Remove-Item "$SourceDir\install.esd" -Force -ErrorAction SilentlyContinue }
    }

    $DestWim = "$SourceDir\install.wim"
    $Count = 1
    foreach ($T in $Tasks) {
        $SrcWim = $T.Cells[6].Value; $Idx = $T.Cells[2].Value; $Name = $T.Cells[3].Value
        Log "Exporting ($Count/$($Tasks.Count)): $Name..."
        try { Export-WindowsImage -SourceImagePath $SrcWim -SourceIndex $Idx -DestinationImagePath $DestWim -DestinationName "$Name" -CompressionType Maximum -ErrorAction Stop } catch { Log "Loi Export: $($_.Exception.Message)"; [System.Windows.Forms.MessageBox]::Show("Loi khi xuat file WIM!", "Loi"); $BtnBuild.Enabled=$true; return }
        $Count++
    }

    if (!$CopyBoot) { [IO.File]::WriteAllText("$Dir\AIO_Installer.cmd", "@echo off`r`npushd `"%~dp0`"`r`ntitle PHAT TAN PC`r`nset WIM=%~dp0sources\install.wim`r`nif not exist `"%WIM%`" set WIM=%~dp0install.wim`r`ndism /Apply-Image /ImageFile:`"%WIM%`" /Index:1 /ApplyDir:C:\`r`nbcdboot C:\Windows /s C:`r`nwpeutil reboot") }
    Log "HOAN TAT!"; [System.Windows.Forms.MessageBox]::Show("Da xong!", "OK"); Invoke-Item $Dir; $BtnBuild.Enabled=$true
}

# --- NEW: LOAD BOOT KITS FROM JSON ---
function Load-Cloud-BootKits {
    $Form.Cursor = "WaitCursor"; Log "Dang tai danh sach Boot Kit tu Server..."
    $CbBootKits.Items.Clear()
    try {
        # Tải JSON từ Server
        $JsonContent = (New-Object System.Net.WebClient).DownloadString($Global:JsonUrl)
        # Parse JSON (Dùng Regex đơn giản hoặc JavaScriptSerializer để không phụ thuộc lib ngoài)
        # Cách đơn giản nhất cho PowerShell mọi phiên bản:
        $RawItems = $JsonContent | ConvertFrom-Json
        
        foreach ($Item in $RawItems) {
            $CbBootKits.Items.Add($Item)
        }
        if ($CbBootKits.Items.Count -gt 0) { $CbBootKits.SelectedIndex = 0 }
        Log "Tai thanh cong $($CbBootKits.Items.Count) Boot Kit."
    } catch {
        Log "Loi tai JSON! Dang dung danh sach du phong."
        # Nếu lỗi mạng thì dùng list mẫu
        $Global:DefaultBootKits | ForEach-Object { $CbBootKits.Items.Add([PSCustomObject]$_) }
        $CbBootKits.SelectedIndex = 0
    }
    $Form.Cursor = "Default"
}

# --- WIM TO ISO LOGIC (Tab 2) [UPDATED V7.4] ---
function Wim-To-Iso {
    $Wim = $TxtWimIn.Text
    if (!$Wim -or !(Test-Path $Wim)) { [System.Windows.Forms.MessageBox]::Show("Chua chon file WIM!", "Loi"); return }
    
    $WorkDir = "$env:TEMP\Wim2Iso_Work"; New-Item $WorkDir -ItemType Directory -Force | Out-Null
    $Oscd = Get-Oscdimg; if (!$Oscd) { return }

    # === LOGIC CHỌN NGUỒN BOOT ===
    if ($RbUseLocal.Checked) {
        $BaseIso = $TxtBaseIso.Text
        if (!$BaseIso -or !(Test-Path $BaseIso)) { [System.Windows.Forms.MessageBox]::Show("Chua chon ISO Local!", "Loi"); return }
        
        Log "Mode: Local ISO. Trich xuat..."
        $Drv = Get-IsoDrive $BaseIso
        if (!$Drv) {
             Mount-DiskImage -ImagePath $BaseIso -StorageType ISO -ErrorAction SilentlyContinue | Out-Null
             for($i=0;$i -lt 10;$i++){ $Drv = Get-IsoDrive $BaseIso; if($Drv){ break }; Start-Sleep -Milliseconds 500 }
        }
        if ($Drv) {
             Start-Process "robocopy.exe" -ArgumentList "`"$($Drv.TrimEnd('\'))`" `"$WorkDir`" /E /XF install.wim install.esd /MT:16 /NFL /NDL" -NoNewWindow -Wait
        } else {
             $7z = Get-7Zip; Start-Process $7z -ArgumentList "x `"$BaseIso`" -o`"$WorkDir`" -x!sources\install.wim -x!sources\install.esd -y" -NoNewWindow -Wait
        }
    } else {
        # === CLOUD JSON MODE ===
        if ($CbBootKits.SelectedItem -eq $null) { Load-Cloud-BootKits }
        if ($CbBootKits.SelectedItem -eq $null) { return }
        
        $Kit = $CbBootKits.SelectedItem
        $KitName = $Kit.Name
        $KitUrl = $Kit.Url
        $KitFile = "$Global:BootKitCacheDir\$($Kit.FileName)"
        
        Log "Mode: Cloud Boot Kit ($KitName)"
        
        # Check Cache
        if (!(Test-Path $KitFile) -or (Get-Item $KitFile).Length -lt 1MB) {
            Log "Dang tai: $KitName..."
            try {
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
                (New-Object System.Net.WebClient).DownloadFile($KitUrl, $KitFile)
            } catch { [System.Windows.Forms.MessageBox]::Show("Tai Boot Kit That Bai! Kiem tra mang.", "Loi"); return }
        } else {
            Log "Dung Boot Kit da luu trong Cache."
        }
        
        Log "Giai nen Boot Kit..."
        $7z = Get-7Zip
        Start-Process $7z -ArgumentList "x `"$KitFile`" -o`"$WorkDir`" -y" -NoNewWindow -Wait
    }

    # Inject & Build (Phần chung)
    $Save = New-Object System.Windows.Forms.SaveFileDialog; $Save.FileName = "MyCustomWin.iso"; $Save.Filter = "ISO|*.iso"
    if ($Save.ShowDialog() -eq "OK") {
        $TargetIso = $Save.FileName
        
        # Disk Check Logic
        $DestDrive = [System.IO.Path]::GetPathRoot($TargetIso).Trim('\')
        try { if ((Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $DestDrive }).FreeSpace -lt ((Get-Item $Wim).Length + 1GB)) { [System.Windows.Forms.MessageBox]::Show("O dia day!", "Full"); return } } catch {}

        Log "Dang bom file WIM cua ban vao..."
        $DestWimDir = "$WorkDir\sources"; if(!(Test-Path $DestWimDir)){ New-Item -ItemType Directory -Path $DestWimDir | Out-Null }
        Copy-Item $Wim "$DestWimDir\install.wim" -Force
        
        Log "Dong goi ISO..."
        $Args = "-m -o -u2 -udfver102 -bootdata:2#p0,e,b`"$WorkDir\boot\etfsboot.com`"#pEF,e,b`"$WorkDir\efi\microsoft\boot\efisys.bin`" `"$WorkDir`" `"$TargetIso`""
        Start-Process $Oscd -ArgumentList $Args -NoNewWindow -Wait
        
        Remove-Item $WorkDir -Recurse -Force -ErrorAction SilentlyContinue
        Log "DONE! ISO tai: $TargetIso"; [System.Windows.Forms.MessageBox]::Show("Thanh Cong!", "Success")
    }
}

# --- MAKE ISO FROM FOLDER ---
function Make-Iso-Action ($SourceFolder) {
    if (!$SourceFolder -or !(Test-Path $SourceFolder)) { return }
    $Oscd = Get-Oscdimg; if (!$Oscd) { return }
    $Save = New-Object System.Windows.Forms.SaveFileDialog; $Save.FileName="WinAIO.iso"; $Save.Filter="ISO|*.iso"
    if ($Save.ShowDialog() -eq "OK") {
        $Target = $Save.FileName
        $Src = $SourceFolder.TrimEnd('\'); if ($Src.Length -le 3) { if ([System.Windows.Forms.MessageBox]::Show("Nguon la Root Drive. Tiep tuc?", "Warn", "YesNo") -eq "No") { return } }
        $Args = "-m -o -u2 -udfver102 -bootdata:2#p0,e,b`"$Src\boot\etfsboot.com`"#pEF,e,b`"$Src\efi\microsoft\boot\efisys.bin`" `"$Src`" `"$Target`""
        Start-Process $Oscd -ArgumentList $Args -NoNewWindow -Wait; [System.Windows.Forms.MessageBox]::Show("ISO Created!", "OK")
    }
}

# --- EVENTS ---
$BtnAdd.Add_Click({ $O = New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="ISO/WIM|*.iso;*.wim;*.esd"; $O.Multiselect=$true; if($O.ShowDialog() -eq "OK"){ foreach($f in $O.FileNames){ if(!($TxtIsoList.Text.Contains($f))){ $TxtIsoList.Text+="$f; "; Process-Iso $f } } } })
$BtnEject.Add_Click({ Get-DiskImage -ImagePath "*.iso" | Dismount-DiskImage -ErrorAction SilentlyContinue; Remove-Item $Global:TempWimDir -Recurse -Force; $TxtIsoList.Text=""; $Grid.Rows.Clear(); $Global:IsoCache=@{}; Log "Reset." })
$BtnBrowseOut.Add_Click({ $F=New-Object System.Windows.Forms.FolderBrowserDialog; if($F.ShowDialog() -eq "OK"){$TxtOut.Text=$F.SelectedPath} })
$BtnBuild.Add_Click({ $Pt = New-Object System.Drawing.Point(0, $BtnBuild.Height); $MenuBuild.Show($BtnBuild, $Pt) })
$Item1.Add_Click({ Build-Core $false }); $Item2.Add_Click({ Build-Core $true })
$BtnMakeIso.Add_MouseDown({ if ($_.Button -eq 'Right') { $MenuIsoHidden.Show($BtnMakeIso, $_.Location) } else { Make-Iso-Action $TxtOut.Text } })
$MItem_Default.Add_Click({ Make-Iso-Action $TxtOut.Text }); $MItem_Custom.Add_Click({ $F = New-Object System.Windows.Forms.FolderBrowserDialog; if ($F.ShowDialog() -eq "OK") { Make-Iso-Action $F.SelectedPath } })
$BtnHddBoot.Add_Click({
    $OutDir = $TxtOut.Text; if (!($Grid.Rows.Count)) { return }
    $MaxVer = [Version]"0.0.0.0"; $BestRow = $Grid.Rows[0]
    foreach ($Row in $Grid.Rows) { try { if ([Version]$Row.Cells[7].Value -gt $MaxVer) { $MaxVer = [Version]$Row.Cells[7].Value; $BestRow = $Row } } catch {} }
    $FirstIso = $BestRow.Cells[1].Value; $Drv = Get-IsoDrive $FirstIso
    if (!$Drv) { Dismount-DiskImage -ImagePath $FirstIso -ErrorAction SilentlyContinue | Out-Null; $7z = Get-7Zip; Start-Process $7z -ArgumentList "e `"$FirstIso`" sources/boot.wim -o`"$OutDir`" -y" -NoNewWindow -Wait } else { Copy-Item "$Drv\sources\boot.wim" "$OutDir\boot.wim" -Force; if (!(Test-Path "$OutDir\boot.sdi")) { Copy-Item "$Drv\boot\boot.sdi" "$OutDir\boot.sdi" -Force } }
    $Mnt = "$env:TEMP\Mnt"; New-Item $Mnt -ItemType Directory -Force | Out-Null; Start-Process "dism" "/Mount-Image /ImageFile:`"$OutDir\boot.wim`" /Index:2 /MountDir:`"$Mnt`"" -Wait -NoNewWindow
    [IO.File]::WriteAllText("$Mnt\Windows\System32\winpeshl.ini", "[LaunchApps]`r`n%SystemRoot%\System32\AutoRunAIO.cmd"); [IO.File]::WriteAllText("$Mnt\Windows\System32\AutoRunAIO.cmd", "@echo off`r`nfor %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (if exist `"%%d:\AIO_Output\AIO_Installer.cmd`" (%%d: & cd \AIO_Output & call AIO_Installer.cmd & exit))`r`ncmd.exe")
    Start-Process "dism" "/Unmount-Image /MountDir:`"$Mnt`" /Commit" -Wait -NoNewWindow; Remove-Item $Mnt -Recurse -Force
    [System.Windows.Forms.MessageBox]::Show("HDD Boot Menu Created!", "Success")
})

# Tab 2 UI Logic
$BtnBrWim.Add_Click({ $O = New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="Windows Image|*.wim;*.esd"; if($O.ShowDialog() -eq "OK"){$TxtWimIn.Text=$O.FileName} })
$BtnBrBase.Add_Click({ $O = New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="ISO Image|*.iso"; if($O.ShowDialog() -eq "OK"){$TxtBaseIso.Text=$O.FileName} })
$RbUseLocal.Add_CheckedChanged({ $TxtBaseIso.Enabled=$RbUseLocal.Checked; $BtnBrBase.Enabled=$RbUseLocal.Checked; $CbBootKits.Enabled=$RbUseCloud.Checked; $BtnRefresh.Enabled=$RbUseCloud.Checked })
$BtnRefresh.Add_Click({ Load-Cloud-BootKits })
$BtnStartW2I.Add_Click({ Wim-To-Iso })

$Form.Add_FormClosing({ try { foreach ($Iso in $Global:IsoCache.Values) { Dismount-DiskImage -ImagePath $Iso -ErrorAction SilentlyContinue | Out-Null }; Remove-Item $Global:TempWimDir -Recurse -Force } catch {} })
$Form.ShowDialog() | Out-Null

} catch { [System.Windows.Forms.MessageBox]::Show("Error: $($_.Exception.Message)", "Critical") }
