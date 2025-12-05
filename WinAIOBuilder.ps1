<#
    WIN AIO BUILDER - PHAT TAN PC
    Version: 3.7 (Safe Mode + Syntax Fix + Debug Ready)
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
$Form.Text = "WINDOWS AIO BUILDER V3.7 (STABLE)"
$Form.Size = New-Object System.Drawing.Size(950, 800)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back; $Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "TẠO WINDOWS AIO & HDD BOOT"; $LblT.Font = "Impact, 18"; $LblT.ForeColor = $Theme.Accent; $LblT.AutoSize = $true; $LblT.Location = "20,10"; $Form.Controls.Add($LblT)

# ================= SECTIONS =================

# 1. INPUT ISO
$GbIso = New-Object System.Windows.Forms.GroupBox; $GbIso.Text = "1. Danh Sách ISO Nguồn (Hỗ trợ Win 7/8/10/11)"; $GbIso.Location = "20,50"; $GbIso.Size = "895,250"; $GbIso.ForeColor = "Yellow"; $Form.Controls.Add($GbIso)

$TxtIsoList = New-Object System.Windows.Forms.TextBox; $TxtIsoList.Location = "15,25"; $TxtIsoList.Size = "580,25"; $TxtIsoList.ReadOnly = $true; $GbIso.Controls.Add($TxtIsoList)
$BtnAdd = New-Object System.Windows.Forms.Button; $BtnAdd.Text = "THÊM ISO..."; $BtnAdd.Location = "610,23"; $BtnAdd.Size = "100,27"; $BtnAdd.BackColor = "DimGray"; $BtnAdd.ForeColor = "White"; $GbIso.Controls.Add($BtnAdd)
$BtnEject = New-Object System.Windows.Forms.Button; $BtnEject.Text = "RESET LIST"; $BtnEject.Location = "720,23"; $BtnEject.Size = "100,27"; $BtnEject.BackColor = "DarkRed"; $BtnEject.ForeColor = "White"; $GbIso.Controls.Add($BtnEject)

$Grid = New-Object System.Windows.Forms.DataGridView; $Grid.Location = "15,60"; $Grid.Size = "865,175"; $Grid.BackgroundColor = "Black"; $Grid.ForeColor = "Black"; $Grid.AllowUserToAddRows = $false; $Grid.RowHeadersVisible = $false; $Grid.SelectionMode = "FullRowSelect"; $Grid.AutoSizeColumnsMode = "Fill"
$ColChk = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn; $ColChk.Name = "Select"; $ColChk.HeaderText = "[X]"; $ColChk.Width = 40; $Grid.Columns.Add($ColChk) | Out-Null
$Grid.Columns.Add("ISO", "Đường dẫn File"); $Grid.Columns.Add("Index", "Index"); $Grid.Columns.Add("Name", "Phiên Bản"); $Grid.Columns.Add("Size", "Dung Lượng"); $Grid.Columns.Add("Arch", "Bit"); $Grid.Columns.Add("WimPath", "WimPath")
$Grid.Columns[1].Width = 50; $Grid.Columns[3].Width = 80; $Grid.Columns[4].Width = 60; $Grid.Columns[5].Visible = $false; $GbIso.Controls.Add($Grid)

# 2. BUILD OPTIONS
$GbBuild = New-Object System.Windows.Forms.GroupBox; $GbBuild.Text = "2. Cấu Hình & Build (install.wim + CMD)"; $GbBuild.Location = "20,310"; $GbBuild.Size = "895,120"; $GbBuild.ForeColor = "Lime"; $Form.Controls.Add($GbBuild)

$LblOut = New-Object System.Windows.Forms.Label; $LblOut.Text = "Thư mục làm việc:"; $LblOut.Location = "15,25"; $LblOut.AutoSize = $true; $GbBuild.Controls.Add($LblOut)
$TxtOut = New-Object System.Windows.Forms.TextBox; $TxtOut.Location = "120,22"; $TxtOut.Size = "400,25"; $TxtOut.Text = "D:\AIO_Output"; $GbBuild.Controls.Add($TxtOut)
$BtnBrowseOut = New-Object System.Windows.Forms.Button; $BtnBrowseOut.Text = "..."; $BtnBrowseOut.Location = "530,20"; $BtnBrowseOut.Size = "40,27"; $GbBuild.Controls.Add($BtnBrowseOut)

$ChkBootLayout = New-Object System.Windows.Forms.CheckBox; $ChkBootLayout.Text = "Sao chép Boot (Để tạo ISO hoặc USB Boot)"; $ChkBootLayout.Location = "120,55"; $ChkBootLayout.AutoSize = $true; $ChkBootLayout.Checked = $true; $ChkBootLayout.ForeColor = "Cyan"; $GbBuild.Controls.Add($ChkBootLayout)

$BtnBuild = New-Object System.Windows.Forms.Button; $BtnBuild.Text = "BẮT ĐẦU BUILD AIO"; $BtnBuild.Location = "600,20"; $BtnBuild.Size = "280,80"; $BtnBuild.BackColor = "Green"; $BtnBuild.ForeColor = "White"; $BtnBuild.Font = "Segoe UI, 12, Bold"; $GbBuild.Controls.Add($BtnBuild)

# 3. CREATE ISO
$GbIsoTool = New-Object System.Windows.Forms.GroupBox; $GbIsoTool.Text = "3. Đóng Gói Ra File ISO"; $GbIsoTool.Location = "20,440"; $GbIsoTool.Size = "440,150"; $GbIsoTool.ForeColor = "Orange"; $Form.Controls.Add($GbIsoTool)
$BtnMakeIso = New-Object System.Windows.Forms.Button; $BtnMakeIso.Text = "TẠO FILE ISO NGAY"; $BtnMakeIso.Location = "20,30"; $BtnMakeIso.Size = "400,50"; $BtnMakeIso.BackColor = "DarkOrange"; $BtnMakeIso.ForeColor = "Black"; $BtnMakeIso.Font = "Segoe UI, 11, Bold"; $GbIsoTool.Controls.Add($BtnMakeIso)
$LblIsoNote = New-Object System.Windows.Forms.Label; $LblIsoNote.Text = "* Tự động tải oscdimg.exe (ADK) nếu thiếu."; $LblIsoNote.Location = "20,90"; $LblIsoNote.AutoSize = $true; $LblIsoNote.ForeColor = "Gray"; $GbIsoTool.Controls.Add($LblIsoNote)

# 4. HDD BOOT
$GbHdd = New-Object System.Windows.Forms.GroupBox; $GbHdd.Text = "4. HDD Boot (Không cần USB)"; $GbHdd.Location = "475,440"; $GbHdd.Size = "440,150"; $GbHdd.ForeColor = "Red"; $Form.Controls.Add($GbHdd)
$BtnHddBoot = New-Object System.Windows.Forms.Button; $BtnHddBoot.Text = "TẠO MENU BOOT HDD"; $BtnHddBoot.Location = "20,30"; $BtnHddBoot.Size = "400,50"; $BtnHddBoot.BackColor = "Firebrick"; $BtnHddBoot.ForeColor = "White"; $BtnHddBoot.Font = "Segoe UI, 11, Bold"; $GbHdd.Controls.Add($BtnHddBoot)
$LblHddStat = New-Object System.Windows.Forms.Label; $LblHddStat.Text = "Tự động tạo BCD và WinPE"; $LblHddStat.Location = "20,90"; $LblHddStat.AutoSize = $true; $GbHdd.Controls.Add($LblHddStat)

# Log Area
$TxtLog = New-Object System.Windows.Forms.TextBox; $TxtLog.Multiline = $true; $TxtLog.Location = "20,600"; $TxtLog.Size = "895,140"; $TxtLog.BackColor = "Black"; $TxtLog.ForeColor = "Lime"; $TxtLog.ReadOnly = $true; $TxtLog.ScrollBars = "Vertical"; $Form.Controls.Add($TxtLog)

# --- FUNCTIONS ---
$Global:TempWimDir = "$env:TEMP\PhatTan_Wims"
if (!(Test-Path $Global:TempWimDir)) { New-Item -ItemType Directory -Path $Global:TempWimDir -Force | Out-Null }

function Log ($M) { $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $M`r`n"); $TxtLog.ScrollToCaret(); [System.Windows.Forms.Application]::DoEvents() }

function Get-7Zip {
    $7z = "$env:TEMP\7zr.exe"
    if (Test-Path $7z) { return $7z }
    Log "Dang tai 7-Zip Engine (de xu ly Win 7)..."
    try { (New-Object System.Net.WebClient).DownloadFile("https://www.7-zip.org/a/7zr.exe", $7z); return $7z } 
    catch { Log "Loi tai 7-Zip!"; return $null }
}

function Get-Oscdimg {
    $Tool = "$env:TEMP\oscdimg.exe"; if (Test-Path $Tool) { return $Tool }
    $AdkPaths = @("$env:ProgramFiles(x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe")
    foreach ($P in $AdkPaths) { if (Test-Path $P) { return $P } }
    if ([System.Windows.Forms.MessageBox]::Show("Thieu 'oscdimg.exe'. Ban co muon tai ADK Setup?", "Hoi", "YesNo") -eq "Yes") {
        (New-Object System.Net.WebClient).DownloadFile("https://go.microsoft.com/fwlink/?linkid=2243390", "$env:TEMP\adksetup.exe")
        Start-Process "$env:TEMP\adksetup.exe" -Wait
    }
    return $null
}

function Scan-Wim ($WimPath, $SourceName) {
    try {
        $Info = Get-WindowsImage -ImagePath $WimPath
        foreach ($I in $Info) {
            $Grid.Rows.Add($true, $SourceName, $I.ImageIndex, $I.ImageName, "$([Math]::Round($I.Size/1GB,2)) GB", $I.Architecture, $WimPath) | Out-Null
        }
        Log "Da them: $SourceName"
    } catch { Log "Loi doc WIM: $WimPath" }
}

function Process-Iso ($IsoPath) {
    $Form.Cursor = "WaitCursor"
    Log "Dang xu ly ISO: $IsoPath..."
    
    # 1. Thu Mount bang Windows
    try {
        Mount-DiskImage -ImagePath $IsoPath -StorageType ISO -ErrorAction Stop | Out-Null
        $Vol = $null; for($i=0;$i -lt 6;$i++){ $Vol=Get-DiskImage -ImagePath $IsoPath|Get-Volume; if($Vol){break}; Start-Sleep -m 500 }
        
        if ($Vol) {
            $Drv = "$($Vol.DriveLetter):"; $Wim = "$Drv\sources\install.wim"; if(!(Test-Path $Wim)){$Wim="$Drv\sources\install.esd"}
            if (Test-Path $Wim) { Scan-Wim $Wim $IsoPath; $Form.Cursor="Default"; return }
        }
    } catch { Log "Windows Mount that bai. Chuyen sang 7-Zip..." }

    # 2. Neu Mount that bai (Win 7) -> Dung 7-Zip
    $7z = Get-7Zip
    if ($7z) {
        $Hash = (Get-Item $IsoPath).Name.GetHashCode()
        $ExtractDir = "$Global:TempWimDir\$Hash"
        New-Item -ItemType Directory -Path $ExtractDir -Force | Out-Null
        
        Log "Dang trich xuat install.wim bang 7-Zip (Mat vai phut)..."
        $P = Start-Process $7z -ArgumentList "e `"$IsoPath`" sources/install.wim sources/install.esd -o`"$ExtractDir`" -y" -NoNewWindow -PassThru -Wait
        
        $ExtWim = "$ExtractDir\install.wim"; if(!(Test-Path $ExtWim)){$ExtWim="$ExtractDir\install.esd"}
        
        if (Test-Path $ExtWim) { Scan-Wim $ExtWim $IsoPath } else { Log "Khong tim thay install.wim trong ISO nay!" }
    }
    $Form.Cursor = "Default"
}

# --- EVENTS ---
$BtnAdd.Add_Click({ 
    $O = New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="ISO/WIM|*.iso;*.wim;*.esd"; $O.Multiselect=$true
    if($O.ShowDialog() -eq "OK"){ foreach($f in $O.FileNames){ if(!($TxtIsoList.Text.Contains($f))){ $TxtIsoList.Text+="$f; "; Process-Iso $f } } } 
})

$BtnEject.Add_Click({ 
    Get-DiskImage -ImagePath "*.iso" | Dismount-DiskImage -ErrorAction SilentlyContinue
    Remove-Item $Global:TempWimDir -Recurse -Force -ErrorAction SilentlyContinue
    $TxtIsoList.Text=""; $Grid.Rows.Clear(); Log "Da reset danh sach." 
})
$BtnBrowseOut.Add_Click({ $F=New-Object System.Windows.Forms.FolderBrowserDialog; if($F.ShowDialog() -eq "OK"){$TxtOut.Text=$F.SelectedPath} })

# --- 1. BUILD AIO ---
$BtnBuild.Add_Click({
    $Dir = $TxtOut.Text; if(!$Dir){return}; if(!(Test-Path $Dir)){New-Item -ItemType Directory -Path $Dir -Force | Out-Null}
    $Tasks = @(); foreach($r in $Grid.Rows){if($r.Cells[0].Value){$Tasks+=$r}}
    if($Tasks.Count -eq 0){ [System.Windows.Forms.MessageBox]::Show("Chua chon phien ban!", "Loi"); return }

    $BtnBuild.Enabled=$false
    
    if ($ChkBootLayout.Checked) {
        $FirstSource = $Tasks[0].Cells[1].Value
        $FirstWim = $Tasks[0].Cells[5].Value 
        
        Log "Dang tao Boot Layout..."
        if ($FirstWim -match "PhatTan_Wims") {
            $7z = Get-7Zip; Log "Trich xuat Boot tu ISO bang 7-Zip..."
            Start-Process $7z -ArgumentList "x `"$FirstSource`" boot efi setup.exe autorun.inf bootmgr bootmgr.efi -o`"$Dir`" -y" -NoNewWindow -Wait
        } else {
            $Vol = Get-DiskImage -ImagePath $FirstSource | Get-Volume
            if ($Vol) {
                $Drv = "$($Vol.DriveLetter):"
                Start-Process "robocopy.exe" -ArgumentList "`"$Drv`" `"$Dir`" /E /XD `"$Drv\sources`" `"$Drv\System Volume Information`" /MT:16 /NFL /NDL" -NoNewWindow -Wait
                New-Item "$Dir\sources" -ItemType Directory -Force | Out-Null
            }
        }
    }

    $DestWim = "$Dir\sources\install.wim"; if (!(Test-Path "$Dir\sources")) { New-Item -ItemType Directory -Path "$Dir\sources" -Force | Out-Null }
    
    $Count = 1
    foreach ($T in $Tasks) {
        $SrcWim = $T.Cells[5].Value; $Idx = $T.Cells[2].Value; $Name = $T.Cells[3].Value
        Log "Exporting ($Count/$($Tasks.Count)): $Name..."
        Export-WindowsImage -SourceImagePath $SrcWim -SourceIndex $Idx -DestinationImagePath $DestWim -DestinationName "$Name" -CompressionType Maximum -ErrorAction SilentlyContinue
        $Count++
    }

    $Cmd = @"
@echo off
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' ( echo Request Admin... & goto UAC ) else ( goto Admin )
:UAC
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs" & exit /B
:Admin
pushd "%~dp0"
title PHAT TAN PC - INSTALLER
set WIM=
for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do ( if exist "%%d:%~p0install.wim" set WIM=%%d:%~p0install.wim )
if "%WIM%"=="" set WIM=%~dp0install.wim
dism /Get-ImageInfo /ImageFile:"%WIM%"
set /p idx="NHAP INDEX: "
format C: /q /y /fs:ntfs
dism /Apply-Image /ImageFile:"%WIM%" /Index:%idx% /ApplyDir:C:\
bcdboot C:\Windows /s C:
echo DONE! REBOOTING...
timeout 5 & wpeutil reboot
"@
    [IO.File]::WriteAllText("$Dir\AIO_Installer.cmd", $Cmd)
    Log "BUILD THANH CONG!"; [System.Windows.Forms.MessageBox]::Show("Xong! File tai: $Dir", "OK"); Invoke-Item $Dir; $BtnBuild.Enabled=$true
})

# --- 2. MAKE ISO ---
$BtnMakeIso.Add_Click({
    $Dir = $TxtOut.Text
    $Oscd = Get-Oscdimg; if (!$Oscd) { return }
    $Save = New-Object System.Windows.Forms.SaveFileDialog; $Save.FileName="WinAIO.iso"; $Save.Filter="ISO|*.iso"
    if ($Save.ShowDialog() -eq "OK") {
        $Target = $Save.FileName; Log "Creating ISO..."; $Form.Cursor="WaitCursor"
        $Args = "-m -o -u2 -udfver102 -bootdata:2#p0,e,b`"$Dir\boot\etfsboot.com`"#pEF,e,b`"$Dir\efi\microsoft\boot\efisys.bin`" `"$Dir`" `"$Target`""
        Start-Process $Oscd -ArgumentList $Args -NoNewWindow -Wait
        Log "Done!"; [System.Windows.Forms.MessageBox]::Show("ISO Created!", "OK"); $Form.Cursor="Default"
    }
})

# --- 3. HDD BOOT ---
$BtnHddBoot.Add_Click({
    $OutDir = $TxtOut.Text
    if (!($Grid.Rows.Count)) { [System.Windows.Forms.MessageBox]::Show("Can it nhat 1 ISO!", "Loi"); return }
    
    # Lay boot.wim (Tu 7z hoac Mount)
    $FirstIso = $Grid.Rows[0].Cells[1].Value
    $7z = Get-7Zip; Log "Trich xuat boot.wim..."
    Start-Process $7z -ArgumentList "e `"$FirstIso`" sources/boot.wim -o`"$OutDir`" -y" -NoNewWindow -Wait
    
    # Inject
    $Mnt = "$env:TEMP\Mnt"; New-Item $Mnt -ItemType Directory -Force | Out-Null
    Start-Process "dism" "/Mount-Image /ImageFile:`"$OutDir\boot.wim`" /Index:2 /MountDir:`"$Mnt`"" -Wait -NoNewWindow
    [IO.File]::WriteAllText("$Mnt\Windows\System32\winpeshl.ini", "[LaunchApps]`r`n%SystemRoot%\System32\AutoRunAIO.cmd")
    [IO.File]::WriteAllText("$Mnt\Windows\System32\AutoRunAIO.cmd", "@echo off`r`nfor %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (if exist `"%%d:\AIO_Output\AIO_Installer.cmd`" (%%d: & cd \AIO_Output & call AIO_Installer.cmd & exit))`r`ncmd.exe")
    Start-Process "dism" "/Unmount-Image /MountDir:`"$Mnt`" /Commit" -Wait -NoNewWindow
    
    # BCD
    $Drive = $OutDir.Substring(0,2); $Wim = "\AIO_Output\boot.wim"
    cmd /c "bcdedit /create {ramdiskoptions} /d `"Ramdisk`"" 2>$null
    cmd /c "bcdedit /set {ramdiskoptions} ramdisksdidevice partition=$Drive"
    cmd /c "bcdedit /set {ramdiskoptions} ramdisksdipath \AIO_Output\boot.sdi" # Can file sdi
    $ID_L = cmd /c "bcdedit /create /d `"PHAT TAN PC - HDD BOOT`" /application osloader"
    if ($ID_L -match '{([a-f0-9\-]+)}') { 
        $ID = $Matches[0]
        cmd /c "bcdedit /set $ID device ramdisk=[$Drive]$Wim,{ramdiskoptions}"
        cmd /c "bcdedit /set $ID osdevice ramdisk=[$Drive]$Wim,{ramdiskoptions}"
        cmd /c "bcdedit /set $ID winpe yes"
        cmd /c "bcdedit /displayorder $ID /addlast"
    }
    [System.Windows.Forms.MessageBox]::Show("HDD Boot Menu Created!", "Success")
})

# FIX EVENT: Use FormClosing
$Form.Add_FormClosing({ 
    try {
        foreach ($Iso in $Global:MountedISOs) { Dismount-DiskImage -ImagePath $Iso -ErrorAction SilentlyContinue | Out-Null }
        Remove-Item $Global:TempWimDir -Recurse -Force -ErrorAction SilentlyContinue 
    } catch {}
})

$Form.ShowDialog() | Out-Null

} catch {
    # Hien thi loi neu script chet
    [System.Windows.Forms.MessageBox]::Show("Loi Script: $($_.Exception.Message)", "Critical Error")
}
