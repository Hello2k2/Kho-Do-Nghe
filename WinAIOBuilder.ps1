<#
    WIN AIO BUILDER - PHAT TAN PC
    Version: 5.8 (Final Stable)
    - Feature: Auto Detect Kernel (Smart Boot Selection)
    - Feature: Robust Copy Logic (7-Zip Fallback)
    - Feature: Full Oscdimg Recovery (GitHub -> Local ADK -> Manual -> MS Download)
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
$Global:MountedISOs = @()
$Global:TempWimDir = "$env:TEMP\PhatTan_Wims"
# QUAN TRỌNG: Map giữa Đường dẫn ISO -> Ký tự ổ đĩa
$Global:IsoMap = @{} 

if (!(Test-Path $Global:TempWimDir)) { New-Item -ItemType Directory -Path $Global:TempWimDir -Force | Out-Null }

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
$Form.Text = "WINDOWS AIO BUILDER V5.8 (FULL STABLE)"
$Form.Size = New-Object System.Drawing.Size(950, 800)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back; $Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "TẠO WINDOWS AIO & HDD BOOT"; $LblT.Font = New-Object System.Drawing.Font("Impact", 18); $LblT.ForeColor = $Theme.Accent; $LblT.AutoSize = $true; $LblT.Location = "20,10"; $Form.Controls.Add($LblT)

# ================= SECTIONS =================

# 1. INPUT ISO
$GbIso = New-Object System.Windows.Forms.GroupBox; $GbIso.Text = "1. Danh Sách ISO Nguồn"; $GbIso.Location = "20,50"; $GbIso.Size = "895,250"; $GbIso.ForeColor = "Yellow"; $Form.Controls.Add($GbIso)

$TxtIsoList = New-Object System.Windows.Forms.TextBox; $TxtIsoList.Location = "15,25"; $TxtIsoList.Size = "580,25"; $TxtIsoList.ReadOnly = $true; $GbIso.Controls.Add($TxtIsoList)
$BtnAdd = New-Object System.Windows.Forms.Button; $BtnAdd.Text = "THÊM ISO..."; $BtnAdd.Location = "610,23"; $BtnAdd.Size = "100,27"; $BtnAdd.BackColor = "DimGray"; $BtnAdd.ForeColor = "White"; $GbIso.Controls.Add($BtnAdd)
$BtnEject = New-Object System.Windows.Forms.Button; $BtnEject.Text = "RESET LIST"; $BtnEject.Location = "720,23"; $BtnEject.Size = "100,27"; $BtnEject.BackColor = "DarkRed"; $BtnEject.ForeColor = "White"; $GbIso.Controls.Add($BtnEject)

$Grid = New-Object System.Windows.Forms.DataGridView; $Grid.Location = "15,60"; $Grid.Size = "865,175"; $Grid.BackgroundColor = "Black"; $Grid.ForeColor = "Black"; $Grid.AllowUserToAddRows = $false; $Grid.RowHeadersVisible = $false; $Grid.SelectionMode = "FullRowSelect"; $Grid.AutoSizeColumnsMode = "Fill"
$ColChk = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn; $ColChk.Name = "Select"; $ColChk.HeaderText = "[X]"; $ColChk.Width = 40; $Grid.Columns.Add($ColChk) | Out-Null
$Grid.Columns.Add("ISO", "Đường dẫn File"); $Grid.Columns.Add("Index", "Index"); $Grid.Columns.Add("Name", "Phiên Bản"); $Grid.Columns.Add("Size", "Dung Lượng"); $Grid.Columns.Add("Arch", "Bit"); 
$Grid.Columns.Add("WimPath", "WimPath"); 
# Cột ẩn lưu Version
$Grid.Columns.Add("BuildVer", "Kernel Version"); $Grid.Columns[7].Visible = $false 

$Grid.Columns[1].Width = 50; $Grid.Columns[3].Width = 80; $Grid.Columns[4].Width = 60; $Grid.Columns[5].Visible = $false; $GbIso.Controls.Add($Grid)

# 2. BUILD OPTIONS
$GbBuild = New-Object System.Windows.Forms.GroupBox; $GbBuild.Text = "2. Cấu Hình & Build"; $GbBuild.Location = "20,310"; $GbBuild.Size = "895,120"; $GbBuild.ForeColor = "Lime"; $Form.Controls.Add($GbBuild)

$LblOut = New-Object System.Windows.Forms.Label; $LblOut.Text = "Thư mục làm việc:"; $LblOut.Location = "15,25"; $LblOut.AutoSize = $true; $GbBuild.Controls.Add($LblOut)
$TxtOut = New-Object System.Windows.Forms.TextBox; $TxtOut.Location = "120,22"; $TxtOut.Size = "400,25"; $TxtOut.Text = "D:\AIO_Output"; $GbBuild.Controls.Add($TxtOut)
$BtnBrowseOut = New-Object System.Windows.Forms.Button; $BtnBrowseOut.Text = "..."; $BtnBrowseOut.Location = "530,20"; $BtnBrowseOut.Size = "40,27"; $GbBuild.Controls.Add($BtnBrowseOut)

# Context Menu
$MenuBuild = New-Object System.Windows.Forms.ContextMenu
$Item1 = $MenuBuild.MenuItems.Add("1. Build ra file cài đặt (install.wim + CMD Admin)")
$Item2 = $MenuBuild.MenuItems.Add("2. Chuẩn bị cấu trúc ISO (Để tạo file ISO Boot)")

$BtnBuild = New-Object System.Windows.Forms.Button; $BtnBuild.Text = "BẮT ĐẦU BUILD AIO ▼"; $BtnBuild.Location = "600,20"; $BtnBuild.Size = "280,80"; $BtnBuild.BackColor = "Green"; $BtnBuild.ForeColor = "White"; $BtnBuild.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold); $GbBuild.Controls.Add($BtnBuild)

# 3. CREATE ISO
$GbIsoTool = New-Object System.Windows.Forms.GroupBox; $GbIsoTool.Text = "3. Đóng Gói Ra File ISO"; $GbIsoTool.Location = "20,440"; $GbIsoTool.Size = "440,150"; $GbIsoTool.ForeColor = "Orange"; $Form.Controls.Add($GbIsoTool)
$BtnMakeIso = New-Object System.Windows.Forms.Button; $BtnMakeIso.Text = "TẠO FILE ISO NGAY"; $BtnMakeIso.Location = "20,30"; $BtnMakeIso.Size = "400,50"; $BtnMakeIso.BackColor = "DarkOrange"; $BtnMakeIso.ForeColor = "Black"; $BtnMakeIso.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold); $GbIsoTool.Controls.Add($BtnMakeIso)
$LblIsoNote = New-Object System.Windows.Forms.Label; $LblIsoNote.Text = "* Tự động tìm oscdimg (GitHub -> Local ADK -> Download)."; $LblIsoNote.Location = "20,90"; $LblIsoNote.AutoSize = $true; $LblIsoNote.ForeColor = "Gray"; $GbIsoTool.Controls.Add($LblIsoNote)

# 4. HDD BOOT
$GbHdd = New-Object System.Windows.Forms.GroupBox; $GbHdd.Text = "4. HDD Boot (Không cần USB)"; $GbHdd.Location = "475,440"; $GbHdd.Size = "440,150"; $GbHdd.ForeColor = "Red"; $Form.Controls.Add($GbHdd)
$BtnHddBoot = New-Object System.Windows.Forms.Button; $BtnHddBoot.Text = "TẠO MENU BOOT HDD"; $BtnHddBoot.Location = "20,30"; $BtnHddBoot.Size = "400,50"; $BtnHddBoot.BackColor = "Firebrick"; $BtnHddBoot.ForeColor = "White"; $BtnHddBoot.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold); $GbHdd.Controls.Add($BtnHddBoot)
$LblHddStat = New-Object System.Windows.Forms.Label; $LblHddStat.Text = "Tự động tạo BCD và WinPE"; $LblHddStat.Location = "20,90"; $LblHddStat.AutoSize = $true; $GbHdd.Controls.Add($LblHddStat)

# Log Area
$TxtLog = New-Object System.Windows.Forms.TextBox; $TxtLog.Multiline = $true; $TxtLog.Location = "20,600"; $TxtLog.Size = "895,140"; $TxtLog.BackColor = "Black"; $TxtLog.ForeColor = "Lime"; $TxtLog.ReadOnly = $true; $TxtLog.ScrollBars = "Vertical"; $Form.Controls.Add($TxtLog)

# --- FUNCTIONS ---
function Log ($M) { $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $M`r`n"); $TxtLog.ScrollToCaret(); [System.Windows.Forms.Application]::DoEvents() }

function Get-7Zip {
    $7z = "$env:TEMP\7zr.exe"; if (Test-Path $7z) { return $7z }
    Log "Dang tai 7-Zip..."; try { (New-Object System.Net.WebClient).DownloadFile("https://www.7-zip.org/a/7zr.exe", $7z); return $7z } catch { Log "Loi tai 7-Zip!"; return $null }
}

# [FIX] ĐÃ TRẢ LẠI LOGIC TÌM KIẾM ĐẦY ĐỦ
function Get-Oscdimg {
    $Tool = "$env:TEMP\oscdimg.exe"
    
    # 1. Check Temp (Có sẵn thì dùng)
    if (Test-Path $Tool) { return $Tool }
    
    # 2. Check GitHub (Ưu tiên tải về)
    Log "Check 1: Dang tai oscdimg.exe tu GitHub..."
    try {
        $Url = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/refs/heads/main/oscdimg.exe"
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        (New-Object System.Net.WebClient).DownloadFile($Url, $Tool)
        if ((Get-Item $Tool).Length -gt 100kb) { Log "Tai tu GitHub thanh cong!"; return $Tool }
    } catch { Log "GitHub Link loi hoac khong co mang." }

    # 3. Check Local ADK (Nếu GitHub lỗi thì quét trong máy)
    Log "Check 2: Quet ADK trong may..."
    $AdkPaths = @(
        "$env:ProgramFiles(x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
        "$env:ProgramFiles\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
        "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
    )
    foreach ($P in $AdkPaths) { if (Test-Path $P) { Log "Tim thay ADK tai: $P"; return $P } }

    # 4. Check Manual (Hỏi người dùng trỏ file)
    if ([System.Windows.Forms.MessageBox]::Show("Khong tim thay oscdimg.exe (GitHub loi & May chua cai ADK).`n`nBan co muon CHON FILE THU CONG (Browse) khong?", "Tim File", "YesNo", "Question") -eq "Yes") {
        $OFD = New-Object System.Windows.Forms.OpenFileDialog
        $OFD.Filter = "Oscdimg Tool (oscdimg.exe)|oscdimg.exe"
        if ($OFD.ShowDialog() -eq "OK") { return $OFD.FileName }
    }

    # 5. Check Download Microsoft (Đường cùng)
    if ([System.Windows.Forms.MessageBox]::Show("Ban co muon tai ADK Setup tu Microsoft ngay bay gio?", "Download ADK", "YesNo") -eq "Yes") {
        try {
            Log "Dang tai ADK Setup..."
            (New-Object System.Net.WebClient).DownloadFile("https://go.microsoft.com/fwlink/?linkid=2243390", "$env:TEMP\adksetup.exe")
            Start-Process "$env:TEMP\adksetup.exe" -Wait
            # Check lại lần nữa sau khi cài
            foreach ($P in $AdkPaths) { if (Test-Path $P) { return $P } }
        } catch { Log "Loi tai ADK Setup tu Microsoft." }
    }
    
    return $null
}

function Get-IsoDrive ($IsoPath) {
    try {
        $Img = Get-DiskImage -ImagePath $IsoPath -ErrorAction SilentlyContinue
        if ($Img -and $Img.Attached) { $Vol = $Img | Get-Volume; if ($Vol) { return "$($Vol.DriveLetter):" } }
    } catch {}
    try {
        $Disks = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 5 }
        foreach ($D in $Disks) {
            if ($Global:MountedISOs.Values -contains $D.DeviceID) { continue }
            if ((Test-Path "$($D.DeviceID)\sources\install.wim") -or (Test-Path "$($D.DeviceID)\sources\install.esd")) { return $D.DeviceID }
        }
    } catch {}
    return $null
}

function Scan-Wim ($WimPath, $SourceName) {
    try {
        Log "Da tim thay WIM. Dang doc metadata..."
        $Info = Get-WindowsImage -ImagePath $WimPath
        foreach ($I in $Info) {
            $RealVer = $I.Version; if (!$RealVer) { $RealVer = "0.0.0.0" }
            $Grid.Rows.Add($true, $SourceName, $I.ImageIndex, $I.ImageName, "$([Math]::Round($I.Size/1GB,2)) GB", $I.Architecture, $WimPath, $RealVer) | Out-Null
        }
        Log "Da them thanh cong: $SourceName"
    } catch { Log "Loi doc WIM: $($_.Exception.Message)" }
}

function Process-Iso ($IsoPath) {
    $Form.Cursor = "WaitCursor"; Log "Dang xu ly ISO: $IsoPath..."
    
    $Drv = Get-IsoDrive $IsoPath 
    if (!$Drv) {
        try {
            Log "Dang Mount ISO..."
            Mount-DiskImage -ImagePath $IsoPath -StorageType ISO -ErrorAction Stop | Out-Null
            for($i=0;$i -lt 15;$i++){ $Drv = Get-IsoDrive $IsoPath; if($Drv){ break }; Start-Sleep -Milliseconds 500 }
            if ($Drv) { $Global:MountedISOs += @{$IsoPath = $Drv} }
        } catch { Log "Mount that bai (Se dung 7-Zip sau)" }
    } else {
        $Global:MountedISOs += @{$IsoPath = $Drv}
    }
    
    if ($Drv) {
        $WimFiles = Get-ChildItem -Path $Drv -Include "install.wim","install.esd" -Recurse -ErrorAction SilentlyContinue
        if ($WimFiles) { Scan-Wim $WimFiles[0].FullName $IsoPath; $Form.Cursor="Default"; return }
    }

    $7z = Get-7Zip
    if ($7z) {
        $Hash = (Get-Item $IsoPath).Name.GetHashCode(); $ExtractDir = "$Global:TempWimDir\$Hash"; New-Item -ItemType Directory -Path $ExtractDir -Force | Out-Null
        Log "Trich xuat bang 7-Zip (Lay mau WIM)..."
        $P = Start-Process $7z -ArgumentList "e `"$IsoPath`" sources/install.wim sources/install.esd -o`"$ExtractDir`" -y" -NoNewWindow -PassThru -Wait
        $ExtWim = Get-ChildItem -Path $ExtractDir -Include "install.wim","install.esd" -Recurse -ErrorAction SilentlyContinue
        if ($ExtWim) { Scan-Wim $ExtWim[0].FullName $IsoPath } else { Log "KHONG TIM THAY FILE WIM!" }
    }
    $Form.Cursor = "Default"
}

# --- BUILD CORE ---
function Build-Core ($CopyBoot) {
    $RawDir = $TxtOut.Text; if (!$RawDir) { return }
    $Dir = $RawDir -replace '/', '\' 
    
    $RootDrive = [System.IO.Path]::GetPathRoot($Dir)
    $DriveInfo = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $RootDrive.Trim('\') }
    if ($DriveInfo.DriveType -eq 5) { [System.Windows.Forms.MessageBox]::Show("Khong the luu vao o dia CD/DVD ($RootDrive)!", "Loi Duong Dan"); return }

    if (!(Test-Path $Dir)) { New-Item -ItemType Directory -Path $Dir -Force | Out-Null }
    $SourceDir = "$Dir\sources"; if (!(Test-Path $SourceDir)) { New-Item -ItemType Directory -Path $SourceDir -Force | Out-Null }

    $Tasks = @(); foreach($r in $Grid.Rows){if($r.Cells[0].Value){$Tasks+=$r}}
    if($Tasks.Count -eq 0){ [System.Windows.Forms.MessageBox]::Show("Chua chon phien ban!", "Loi"); return }

    $BtnBuild.Enabled=$false
    
    # [LOGIC] 4. COPY BOOT - SMART KERNEL DETECT
    if ($CopyBoot) {
        Log "Dang so sanh Version de tim Boot Loader xin nhat..."
        $BestIsoRow = $Tasks[0]
        $MaxVer = [Version]"0.0.0.0"

        foreach ($Row in $Tasks) {
            try {
                $VerStr = $Row.Cells[7].Value 
                $CurrentVer = [Version]$VerStr
                if ($CurrentVer -gt $MaxVer) { $MaxVer = $CurrentVer; $BestIsoRow = $Row }
            } catch { continue }
        }
        
        Log "-> CHON BOOT BASE: $($BestIsoRow.Cells[3].Value) (Kernel: $MaxVer)"

        $FirstSource = $BestIsoRow.Cells[1].Value
        $FirstWim = $BestIsoRow.Cells[6].Value 
        $Drv = Get-IsoDrive $FirstSource

        if ($FirstWim -match "PhatTan_Wims" -or !$Drv) {
            $7z = Get-7Zip; Log "Dung 7-Zip trich xuat Boot (Mount failed)..."
            Start-Process $7z -ArgumentList "x `"$FirstSource`" boot efi setup.exe autorun.inf bootmgr bootmgr.efi sources/boot.wim sources/setup.exe -o`"$Dir`" -y" -NoNewWindow -Wait
        } else {
            Log "Copy Boot tu o dia ao: $Drv..."
            Start-Process "robocopy.exe" -ArgumentList "`"$Drv`" `"$Dir`" /E /XD `"$Drv\sources`" `"$Drv\System Volume Information`" /MT:16 /NFL /NDL" -NoNewWindow -Wait
            Start-Process "robocopy.exe" -ArgumentList "`"$Drv\sources`" `"$SourceDir`" boot.wim setup.exe /MT:16 /NFL /NDL" -NoNewWindow -Wait
        }
    }

    # 5. EXPORT WIM
    $DestWim = "$SourceDir\install.wim"
    $Count = 1
    foreach ($T in $Tasks) {
        $SrcWim = $T.Cells[6].Value 
        $Idx = $T.Cells[2].Value; $Name = $T.Cells[3].Value
        Log "Exporting ($Count/$($Tasks.Count)): $Name..."
        try {
            Export-WindowsImage -SourceImagePath $SrcWim -SourceIndex $Idx -DestinationImagePath $DestWim -DestinationName "$Name" -CompressionType Maximum -ErrorAction Stop
        } catch {
            Log "Loi Export: $($_.Exception.Message)"; [System.Windows.Forms.MessageBox]::Show("Loi khi xuat file WIM!", "Loi"); $BtnBuild.Enabled=$true; return
        }
        $Count++
    }

    # 6. CMD ADMIN
    if (!$CopyBoot) {
        $Cmd = @"
@echo off
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' ( goto UAC ) else ( goto Admin )
:UAC
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs" & exit /B
:Admin
pushd "%~dp0"
title PHAT TAN PC - INSTALLER
set WIM=%~dp0sources\install.wim
if not exist "%WIM%" set WIM=%~dp0install.wim
if not exist "%WIM%" ( echo KHONG THAY INSTALL.WIM & pause & exit )
dism /Get-ImageInfo /ImageFile:"%WIM%"
set /p idx="NHAP INDEX: "
format C: /q /y /fs:ntfs
dism /Apply-Image /ImageFile:"%WIM%" /Index:%idx% /ApplyDir:C:\
bcdboot C:\Windows /s C:
echo DONE!
timeout 10
wpeutil reboot
"@
        [IO.File]::WriteAllText("$Dir\AIO_Installer.cmd", $Cmd)
    }

    Log "HOAN TAT QUY TRINH!"
    [System.Windows.Forms.MessageBox]::Show("Da xong! File tai: $Dir", "Thanh Cong")
    Invoke-Item $Dir
    $BtnBuild.Enabled=$true
}

# --- EVENTS ---
$BtnAdd.Add_Click({ 
    $O = New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="ISO/WIM|*.iso;*.wim;*.esd"; $O.Multiselect=$true
    if($O.ShowDialog() -eq "OK"){ 
        foreach($f in $O.FileNames){ 
            if(!($TxtIsoList.Text.Contains($f))){ $TxtIsoList.Text+="$f; "; Process-Iso $f } 
        } 
    } 
})

$BtnEject.Add_Click({ 
    Get-DiskImage -ImagePath "*.iso" | Dismount-DiskImage -ErrorAction SilentlyContinue
    Remove-Item $Global:TempWimDir -Recurse -Force -ErrorAction SilentlyContinue
    $TxtIsoList.Text=""; $Grid.Rows.Clear(); $Global:MountedISOs=@(); $Global:IsoMap=@{}; Log "Reset." 
})

$BtnBrowseOut.Add_Click({ $F=New-Object System.Windows.Forms.FolderBrowserDialog; if($F.ShowDialog() -eq "OK"){$TxtOut.Text=$F.SelectedPath} })

$BtnBuild.Add_Click({ $Pt = New-Object System.Drawing.Point(0, $BtnBuild.Height); $MenuBuild.Show($BtnBuild, $Pt) })
$Item1.Add_Click({ Build-Core $false }); $Item2.Add_Click({ Build-Core $true })

$BtnMakeIso.Add_Click({
    $Dir = $TxtOut.Text; $Oscd = Get-Oscdimg; if (!$Oscd) { return }
    $Save = New-Object System.Windows.Forms.SaveFileDialog; $Save.FileName="WinAIO.iso"; $Save.Filter="ISO|*.iso"
    if ($Save.ShowDialog() -eq "OK") {
        $Target = $Save.FileName; Log "Creating ISO..."; $Form.Cursor="WaitCursor"
        $Args = "-m -o -u2 -udfver102 -bootdata:2#p0,e,b`"$Dir\boot\etfsboot.com`"#pEF,e,b`"$Dir\efi\microsoft\boot\efisys.bin`" `"$Dir`" `"$Target`""
        Start-Process $Oscd -ArgumentList $Args -NoNewWindow -Wait; Log "Done!"; [System.Windows.Forms.MessageBox]::Show("ISO Created!", "OK"); $Form.Cursor="Default"
    }
})

$BtnHddBoot.Add_Click({
    $OutDir = $TxtOut.Text; if (!($Grid.Rows.Count)) { return }
    
    $MaxVer = [Version]"0.0.0.0"; $BestRow = $Grid.Rows[0]
    foreach ($Row in $Grid.Rows) {
        try { if ([Version]$Row.Cells[7].Value -gt $MaxVer) { $MaxVer = [Version]$Row.Cells[7].Value; $BestRow = $Row } } catch {}
    }
    
    $FirstIso = $BestRow.Cells[1].Value
    $FirstWim = $BestRow.Cells[6].Value 
    Log "HDD BOOT: Su dung Boot Core cua $($BestRow.Cells[3].Value)..."

    $Drv = Get-IsoDrive $FirstIso
    if ($FirstWim -match "PhatTan_Wims" -or !$Drv) {
         $7z = Get-7Zip; Log "Trich xuat boot.wim (7-Zip)..."
         Start-Process $7z -ArgumentList "e `"$FirstIso`" sources/boot.wim -o`"$OutDir`" -y" -NoNewWindow -Wait 
    } else { 
         Log "Copy boot.wim tu $Drv..."; Copy-Item "$Drv\sources\boot.wim" "$OutDir\boot.wim" -Force
         if (!(Test-Path "$OutDir\boot.sdi")) { Copy-Item "$Drv\boot\boot.sdi" "$OutDir\boot.sdi" -Force } 
    }
    
    $Mnt = "$env:TEMP\Mnt"; New-Item $Mnt -ItemType Directory -Force | Out-Null
    Start-Process "dism" "/Mount-Image /ImageFile:`"$OutDir\boot.wim`" /Index:2 /MountDir:`"$Mnt`"" -Wait -NoNewWindow
    [IO.File]::WriteAllText("$Mnt\Windows\System32\winpeshl.ini", "[LaunchApps]`r`n%SystemRoot%\System32\AutoRunAIO.cmd")
    [IO.File]::WriteAllText("$Mnt\Windows\System32\AutoRunAIO.cmd", "@echo off`r`nfor %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (if exist `"%%d:\AIO_Output\AIO_Installer.cmd`" (%%d: & cd \AIO_Output & call AIO_Installer.cmd & exit))`r`ncmd.exe")
    Start-Process "dism" "/Unmount-Image /MountDir:`"$Mnt`" /Commit" -Wait -NoNewWindow; Remove-Item $Mnt -Recurse -Force
    
    $Drive = $OutDir.Substring(0,2); $Wim = "\AIO_Output\boot.wim"
    cmd /c "bcdedit /create {ramdiskoptions} /d `"Ramdisk`"" 2>$null
    cmd /c "bcdedit /set {ramdiskoptions} ramdisksdidevice partition=$Drive"; cmd /c "bcdedit /set {ramdiskoptions} ramdisksdipath \AIO_Output\boot.sdi"
    $ID_L = cmd /c "bcdedit /create /d `"PHAT TAN PC - HDD BOOT`" /application osloader"; if ($ID_L -match '{([a-f0-9\-]+)}') { $ID = $Matches[0]; cmd /c "bcdedit /set $ID device ramdisk=[$Drive]$Wim,{ramdiskoptions}"; cmd /c "bcdedit /set $ID osdevice ramdisk=[$Drive]$Wim,{ramdiskoptions}"; cmd /c "bcdedit /set $ID winpe yes"; cmd /c "bcdedit /displayorder $ID /addlast" }
    [System.Windows.Forms.MessageBox]::Show("HDD Boot Menu Created!", "Success")
})

$Form.Add_FormClosing({ try { foreach ($Iso in $Global:MountedISOs.Keys) { Dismount-DiskImage -ImagePath $Iso -ErrorAction SilentlyContinue | Out-Null }; Remove-Item $Global:TempWimDir -Recurse -Force -ErrorAction SilentlyContinue } catch {} })
$Form.ShowDialog() | Out-Null

} catch { [System.Windows.Forms.MessageBox]::Show("Loi Script: $($_.Exception.Message)", "Critical Error") }
