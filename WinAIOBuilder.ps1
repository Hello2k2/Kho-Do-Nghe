<#
    WIN AIO BUILDER - PHAT TAN PC
    Version: 3.5 (Fix HDD Boot Path + Auto Admin CMD)
#>

# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

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
$Form.Text = "WINDOWS AIO BUILDER V3.5 (HDD BOOT FIXED)"
$Form.Size = New-Object System.Drawing.Size(950, 800)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back; $Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

# Header
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "TẠO WINDOWS AIO & FILE ISO BOOT"; $LblT.Font = "Impact, 18"; $LblT.ForeColor = $Theme.Accent; $LblT.AutoSize = $true; $LblT.Location = "20,10"; $Form.Controls.Add($LblT)

# ================= SECTIONS =================

# 1. INPUT ISO
$GbIso = New-Object System.Windows.Forms.GroupBox; $GbIso.Text = "1. Danh Sách ISO Nguồn"; $GbIso.Location = "20,50"; $GbIso.Size = "895,250"; $GbIso.ForeColor = "Yellow"; $Form.Controls.Add($GbIso)

$TxtIsoList = New-Object System.Windows.Forms.TextBox; $TxtIsoList.Location = "15,25"; $TxtIsoList.Size = "580,25"; $TxtIsoList.ReadOnly = $true; $GbIso.Controls.Add($TxtIsoList)
$BtnAdd = New-Object System.Windows.Forms.Button; $BtnAdd.Text = "THÊM ISO..."; $BtnAdd.Location = "610,23"; $BtnAdd.Size = "100,27"; $BtnAdd.BackColor = "DimGray"; $BtnAdd.ForeColor = "White"; $GbIso.Controls.Add($BtnAdd)
$BtnEject = New-Object System.Windows.Forms.Button; $BtnEject.Text = "GỠ TẤT CẢ"; $BtnEject.Location = "720,23"; $BtnEject.Size = "100,27"; $BtnEject.BackColor = "DarkRed"; $BtnEject.ForeColor = "White"; $GbIso.Controls.Add($BtnEject)

$Grid = New-Object System.Windows.Forms.DataGridView; $Grid.Location = "15,60"; $Grid.Size = "865,175"; $Grid.BackgroundColor = "Black"; $Grid.ForeColor = "Black"; $Grid.AllowUserToAddRows = $false; $Grid.RowHeadersVisible = $false; $Grid.SelectionMode = "FullRowSelect"; $Grid.AutoSizeColumnsMode = "Fill"
$ColChk = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn; $ColChk.Name = "Select"; $ColChk.HeaderText = "[X]"; $ColChk.Width = 40; $Grid.Columns.Add($ColChk) | Out-Null
$Grid.Columns.Add("ISO", "File ISO"); $Grid.Columns.Add("Index", "Index"); $Grid.Columns.Add("Name", "Phiên Bản"); $Grid.Columns.Add("Size", "Dung Lượng"); $Grid.Columns.Add("Arch", "Bit")
$Grid.Columns[1].Width = 50; $Grid.Columns[3].Width = 80; $Grid.Columns[4].Width = 60; $GbIso.Controls.Add($Grid)

# 2. BUILD OPTIONS
$GbBuild = New-Object System.Windows.Forms.GroupBox; $GbBuild.Text = "2. Cấu Hình & Build (install.wim + CMD)"; $GbBuild.Location = "20,310"; $GbBuild.Size = "895,120"; $GbBuild.ForeColor = "Lime"; $Form.Controls.Add($GbBuild)

$LblOut = New-Object System.Windows.Forms.Label; $LblOut.Text = "Thư mục làm việc:"; $LblOut.Location = "15,25"; $LblOut.AutoSize = $true; $GbBuild.Controls.Add($LblOut)
$TxtOut = New-Object System.Windows.Forms.TextBox; $TxtOut.Location = "120,22"; $TxtOut.Size = "400,25"; $TxtOut.Text = "D:\AIO_Output"; $GbBuild.Controls.Add($TxtOut)
$BtnBrowseOut = New-Object System.Windows.Forms.Button; $BtnBrowseOut.Text = "..."; $BtnBrowseOut.Location = "530,20"; $BtnBrowseOut.Size = "40,27"; $GbBuild.Controls.Add($BtnBrowseOut)

$ChkBootLayout = New-Object System.Windows.Forms.CheckBox; $ChkBootLayout.Text = "Sao chép cấu trúc Boot (Quan trọng để tạo ISO)"; $ChkBootLayout.Location = "120,55"; $ChkBootLayout.AutoSize = $true; $ChkBootLayout.Checked = $true; $ChkBootLayout.ForeColor = "Cyan"; $GbBuild.Controls.Add($ChkBootLayout)

$BtnBuild = New-Object System.Windows.Forms.Button; $BtnBuild.Text = "BẮT ĐẦU BUILD AIO"; $BtnBuild.Location = "600,20"; $BtnBuild.Size = "280,80"; $BtnBuild.BackColor = "Green"; $BtnBuild.ForeColor = "White"; $BtnBuild.Font = "Segoe UI, 12, Bold"; $GbBuild.Controls.Add($BtnBuild)

# 3. CREATE ISO
$GbIsoTool = New-Object System.Windows.Forms.GroupBox; $GbIsoTool.Text = "3. Đóng Gói Ra File ISO (Bootable)"; $GbIsoTool.Location = "20,440"; $GbIsoTool.Size = "440,150"; $GbIsoTool.ForeColor = "Orange"; $Form.Controls.Add($GbIsoTool)

$BtnMakeIso = New-Object System.Windows.Forms.Button; $BtnMakeIso.Text = "TẠO FILE ISO NGAY"; $BtnMakeIso.Location = "20,30"; $BtnMakeIso.Size = "400,50"; $BtnMakeIso.BackColor = "DarkOrange"; $BtnMakeIso.ForeColor = "Black"; $BtnMakeIso.Font = "Segoe UI, 11, Bold"; $GbIsoTool.Controls.Add($BtnMakeIso)

$LblIsoNote = New-Object System.Windows.Forms.Label; $LblIsoNote.Text = "* Tool sẽ tự tải oscdimg.exe nếu thiếu.`n* Tự động Fix nếu thiếu thư mục Boot."; $LblIsoNote.Location = "20,90"; $LblIsoNote.AutoSize = $true; $LblIsoNote.ForeColor = "Gray"; $GbIsoTool.Controls.Add($LblIsoNote)

# 4. HDD BOOT
$GbHdd = New-Object System.Windows.Forms.GroupBox; $GbHdd.Text = "4. HDD Boot (Cài ko cần USB)"; $GbHdd.Location = "475,440"; $GbHdd.Size = "440,150"; $GbHdd.ForeColor = "Red"; $Form.Controls.Add($GbHdd)
$BtnHddBoot = New-Object System.Windows.Forms.Button; $BtnHddBoot.Text = "TẠO MENU BOOT HDD"; $BtnHddBoot.Location = "20,30"; $BtnHddBoot.Size = "400,50"; $BtnHddBoot.BackColor = "Firebrick"; $BtnHddBoot.ForeColor = "White"; $BtnHddBoot.Font = "Segoe UI, 11, Bold"; $GbHdd.Controls.Add($BtnHddBoot)
$LblHddStat = New-Object System.Windows.Forms.Label; $LblHddStat.Text = "Trạng thái: Sẵn sàng"; $LblHddStat.Location = "20,90"; $LblHddStat.AutoSize = $true; $GbHdd.Controls.Add($LblHddStat)

# Log Area
$TxtLog = New-Object System.Windows.Forms.TextBox; $TxtLog.Multiline = $true; $TxtLog.Location = "20,600"; $TxtLog.Size = "895,140"; $TxtLog.BackColor = "Black"; $TxtLog.ForeColor = "Lime"; $TxtLog.ReadOnly = $true; $TxtLog.ScrollBars = "Vertical"; $Form.Controls.Add($TxtLog)

# --- FUNCTIONS ---
$Global:MountedISOs = @()
function Log ($M) { $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $M`r`n"); $TxtLog.ScrollToCaret(); [System.Windows.Forms.Application]::DoEvents() }

function Get-Oscdimg {
    $LocalTool = "$env:TEMP\oscdimg.exe"; if (Test-Path $LocalTool) { return $LocalTool }
    $AdkPaths = @("$env:ProgramFiles(x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe", "$env:ProgramFiles\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe")
    foreach ($P in $AdkPaths) { if (Test-Path $P) { Log "Da tim thay oscdimg.exe chinh chu MS!"; return $P } }

    $AdkSetup = "$env:TEMP\adksetup.exe"; $LinkMS = "https://go.microsoft.com/fwlink/?linkid=2243390"
    if ([System.Windows.Forms.MessageBox]::Show("Khong tim thay 'oscdimg.exe' (Tool tao ISO).`n`nBan co muon tai ADK chinh chu tu Microsoft khong?", "Thieu File", "YesNo", "Question") -eq "Yes") {
        Log "Dang tai ADK Setup..."
        try { (New-Object System.Net.WebClient).DownloadFile($LinkMS, $AdkSetup)
            [System.Windows.Forms.MessageBox]::Show("HUONG DAN CAI DAT:`n1. Cua so cai dat hien ra -> Next.`n2. Chi can tich vao 'Deployment Tools'.`n3. Install.", "Guide")
            Start-Process $AdkSetup -Wait
            foreach ($P in $AdkPaths) { if (Test-Path $P) { return $P } }
        } catch { Log "Loi tai ADK: $($_.Exception.Message)" }
    }
    return $null
}

function Mount-Scan ($Iso) {
    try {
        $Form.Cursor = "WaitCursor"
        Mount-DiskImage -ImagePath $Iso -StorageType ISO -ErrorAction Stop | Out-Null
        $Vol = $null; for($i=0;$i -lt 10;$i++){ $Vol = Get-DiskImage -ImagePath $Iso | Get-Volume; if($Vol -and $Vol.DriveLetter){break}; Start-Sleep -m 500 }
        if ($Vol) {
            $Drv = "$($Vol.DriveLetter):"; $Wim = "$Drv\sources\install.wim"; if(!(Test-Path $Wim)){$Wim="$Drv\sources\install.esd"}
            if(Test-Path $Wim){
                $Global:MountedISOs += $Iso
                $Info = Get-WindowsImage -ImagePath $Wim
                foreach($I in $Info){ $Grid.Rows.Add($true, $Iso, $I.ImageIndex, $I.ImageName, "$([Math]::Round($I.Size/1GB,2)) GB", $I.Architecture) | Out-Null }
            }
        }
    } catch { Log "Loi Mount: $_" }
    $Form.Cursor = "Default"
}

# --- EVENTS ---
$BtnAdd.Add_Click({ 
    $O = New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="ISO|*.iso"; $O.Multiselect=$true; 
    if($O.ShowDialog() -eq "OK"){ 
        foreach($f in $O.FileNames){ 
            if (!($TxtIsoList.Text.Contains($f))) { 
                $TxtIsoList.Text += "$f; "
                Mount-Scan $f 
            } 
        } 
    } 
})

$BtnEject.Add_Click({ Get-DiskImage -ImagePath "*.iso" | Dismount-DiskImage -ErrorAction SilentlyContinue; $TxtIsoList.Text=""; $Grid.Rows.Clear(); Log "Da go tat ca o ao." })
$BtnBrowseOut.Add_Click({ $F=New-Object System.Windows.Forms.FolderBrowserDialog; if($F.ShowDialog() -eq "OK"){$TxtOut.Text=$F.SelectedPath} })

# --- 1. BUILD AIO PROCESS (XUẤT INSTALL.WIM + CMD ADMIN) ---
$BtnBuild.Add_Click({
    $Dir = $TxtOut.Text; if(!$Dir){return}; if(!(Test-Path $Dir)){New-Item -ItemType Directory -Path $Dir -Force | Out-Null}
    $Tasks = @(); foreach($r in $Grid.Rows){if($r.Cells[0].Value){$Tasks+=$r}}
    if($Tasks.Count -eq 0){ [System.Windows.Forms.MessageBox]::Show("Chua chon phien ban!", "Loi"); return }

    $BtnBuild.Enabled=$false
    if ($ChkBootLayout.Checked) {
        $BaseIso = $Tasks[0].Cells[1].Value
        Log "Sao chep Boot tu: $BaseIso..."
        $Vol = Get-DiskImage -ImagePath $BaseIso | Get-Volume
        $Drv = "$($Vol.DriveLetter):"
        Start-Process "robocopy.exe" -ArgumentList "`"$Drv`" `"$Dir`" /E /XD `"$Drv\System Volume Information`" /XF install.wim install.esd /MT:16 /NFL /NDL" -NoNewWindow -Wait
    }
    $DestWim = "$Dir\sources\install.wim"; if (!(Test-Path "$Dir\sources")) { New-Item -ItemType Directory -Path "$Dir\sources" -Force | Out-Null }
    
    $Count = 1
    foreach ($T in $Tasks) {
        $SrcIso = $T.Cells[1].Value; $Idx = $T.Cells[2].Value; $Name = $T.Cells[3].Value
        $Vol = Get-DiskImage -ImagePath $SrcIso | Get-Volume; if (!$Vol) { Mount-DiskImage -ImagePath $SrcIso -StorageType ISO -ErrorAction SilentlyContinue | Out-Null; Start-Sleep -s 1; $Vol = Get-DiskImage -ImagePath $SrcIso | Get-Volume }
        $Drv = "$($Vol.DriveLetter):"; $SrcWim = "$Drv\sources\install.wim"; if(!(Test-Path $SrcWim)){$SrcWim="$Drv\sources\install.esd"}
        Log "Exporting ($Count/$($Tasks.Count)): $Name..."; Export-WindowsImage -SourceImagePath $SrcWim -SourceIndex $Idx -DestinationImagePath $DestWim -DestinationName "$Name" -CompressionType Maximum -ErrorAction SilentlyContinue
        $Count++
    }

    # === TẠO FILE CMD TỰ ĐỘNG CHẠY ADMIN ===
    $CmdContent = @"
@echo off
:: --- AUTO ADMIN REQUEST ---
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting Admin rights...
    goto UACPrompt
) else ( goto gotAdmin )
:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B
:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"
:: --------------------------

title PHAT TAN PC - AIO INSTALLER
color 1f
cls
set WIMPATH=
for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%d:%~p0install.wim" set WIMPATH=%%d:%~p0install.wim
    if exist "%%d:\AIO_Output\install.wim" set WIMPATH=%%d:\AIO_Output\install.wim
)

if "%WIMPATH%"=="" (
    echo [ERROR] Khong tim thay file install.wim!
    echo Vui long kiem tra lai duong dan.
    pause
    exit
)

echo ==========================================================
echo         TIM THAY FILE NGUON: %WIMPATH%
echo ==========================================================
dism /Get-ImageInfo /ImageFile:"%WIMPATH%"
echo.
echo ==========================================================
set /p idx=">>> NHAP SO THU TU (INDEX) BAN MUON CAI: "
echo.
echo [!] CANH BAO: TOAN BO O C: SE BI FORMAT DE CAI MOI.
echo [!] DU LIEU TREN C: SE MAT HET.
echo.
pause
echo Dang format C:...
format C: /q /y /fs:ntfs
echo Dang bung file anh...
dism /Apply-Image /ImageFile:"%WIMPATH%" /Index:%idx% /ApplyDir:C:\
echo.
echo [!] DANG NAP BOOT (UEFI/LEGACY)...
bcdboot C:\Windows /s C:
echo.
echo [OK] DA CAI XONG. KHOI DONG LAI!
pause
wpeutil reboot
"@
    [IO.File]::WriteAllText("$Dir\AIO_Installer.cmd", $CmdContent)

    Log "BUILD XONG!"; [System.Windows.Forms.MessageBox]::Show("Đã Build xong!`nFile install.wim và AIO_Installer.cmd nằm tại: $Dir", "Thành Công"); Invoke-Item $Dir; $BtnBuild.Enabled=$true
})

# --- 2. CREATE ISO PROCESS ---
$BtnMakeIso.Add_Click({
    $Dir = $TxtOut.Text
    if (!(Test-Path "$Dir\boot") -or !(Test-Path "$Dir\efi")) {
        if ([System.Windows.Forms.MessageBox]::Show("THIEU THU MUC BOOT!`n`nNguyen nhan: Ban chua tich vao 'Sao chep cau truc Boot' khi Build.`nBan co muon chon 1 file ISO de lay file Boot ngay bay gio khong?", "Thieu File", "YesNo", "Warning") -eq "Yes") {
            $OFD = New-Object System.Windows.Forms.OpenFileDialog; $OFD.Filter="ISO Files|*.iso"; $OFD.Title="Chon ISO bat ky (Win 10/11) de lay Boot"
            if ($OFD.ShowDialog() -eq "OK") {
                $FixIso = $OFD.FileName; Log "Dang trich xuat Boot tu: $FixIso ..."
                Mount-DiskImage -ImagePath $FixIso -StorageType ISO -ErrorAction SilentlyContinue | Out-Null; Start-Sleep -s 2; $Vol = Get-DiskImage -ImagePath $FixIso | Get-Volume; $Drv = "$($Vol.DriveLetter):"
                Copy-Item "$Drv\boot" "$Dir\boot" -Recurse -Force
                Copy-Item "$Drv\efi" "$Dir\efi" -Recurse -Force
                Copy-Item "$Drv\setup.exe" "$Dir\setup.exe" -Force
                Copy-Item "$Drv\autorun.inf" "$Dir\autorun.inf" -Force
                Copy-Item "$Drv\support" "$Dir\support" -Recurse -Force -ErrorAction SilentlyContinue
                Dismount-DiskImage -ImagePath $FixIso -ErrorAction SilentlyContinue | Out-Null
            } else { return }
        } else { return }
    }

    $Oscd = Get-Oscdimg; if (!$Oscd) { return }
    $Save = New-Object System.Windows.Forms.SaveFileDialog; $Save.FileName="Windows_AIO.iso"; $Save.Filter="ISO|*.iso"
    if ($Save.ShowDialog() -eq "OK") {
        $Target = $Save.FileName; Log "Dang tao ISO..."; $Form.Cursor = "WaitCursor"
        $CmdArgs = "-m -o -u2 -udfver102 -bootdata:2#p0,e,b`"$Dir\boot\etfsboot.com`"#pEF,e,b`"$Dir\efi\microsoft\boot\efisys.bin`" `"$Dir`" `"$Target`""
        $P = Start-Process $Oscd -ArgumentList $CmdArgs -NoNewWindow -PassThru -Wait
        if ($P.ExitCode -eq 0) { Log "TAO ISO THANH CONG!"; [System.Windows.Forms.MessageBox]::Show("Xong! File tai: $Target", "OK"); Invoke-Item $Target } 
        else { Log "Loi tao ISO code $($P.ExitCode)"; [System.Windows.Forms.MessageBox]::Show("Loi tao ISO!", "Error") }
        $Form.Cursor = "Default"
    }
})

# --- 3. HDD BOOT PROCESS (FIXED PATH) ---
$BtnHddBoot.Add_Click({
    $OutDir = $TxtOut.Text; if (!(Test-Path "$OutDir\sources\install.wim")) { [System.Windows.Forms.MessageBox]::Show("Chua co file install.wim!", "Loi"); return }
    if ($Grid.Rows.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Can it nhat 1 ISO trong danh sach de lay boot.wim!", "Loi"); return }
    $FirstIso = $Grid.Rows[0].Cells[1].Value
    $BtnHddBoot.Enabled = $false; try {
        Mount-DiskImage -ImagePath $FirstIso -StorageType ISO -ErrorAction SilentlyContinue | Out-Null
        $Vol = Get-DiskImage -ImagePath $FirstIso | Get-Volume; $Drv = "$($Vol.DriveLetter):"
        Copy-Item "$Drv\sources\boot.wim" "$OutDir\boot.wim" -Force
        if (!(Test-Path "$OutDir\boot.sdi")) { Copy-Item "$Drv\boot\boot.sdi" "$OutDir\boot.sdi" -Force }
        
        $MountDir = "$env:TEMP\WimMount"; if (Test-Path $MountDir) { Remove-Item $MountDir -Recurse -Force -ErrorAction SilentlyContinue }; New-Item -ItemType Directory -Path $MountDir -Force | Out-Null
        Start-Process "dism" -ArgumentList "/Mount-Image /ImageFile:`"$OutDir\boot.wim`" /Index:2 /MountDir:`"$MountDir`"" -Wait -NoNewWindow
        
        # Inject AutoRunAIO.cmd (Cũng thêm auto-admin cho chắc)
        [IO.File]::WriteAllText("$MountDir\Windows\System32\winpeshl.ini", "[LaunchApps]`r`n%SystemRoot%\System32\AutoRunAIO.cmd")
        $AutoCmd = "@echo off`r`nfor %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (`r`n if exist `"%%d:\AIO_Output\AIO_Installer.cmd`" (%%d: & cd \AIO_Output & call AIO_Installer.cmd & exit)`r`n)`r`ncmd.exe"
        [IO.File]::WriteAllText("$MountDir\Windows\System32\AutoRunAIO.cmd", $AutoCmd)
        
        Start-Process "dism" -ArgumentList "/Unmount-Image /MountDir:`"$MountDir`" /Commit" -Wait -NoNewWindow
        Remove-Item $MountDir -Recurse -Force
        
        # BCD Entry
        $Desc = "PHAT TAN PC - CAI DAT AIO (HDD)"
        $Drive = $OutDir.Substring(0,2) # VD: D:
        
        # FIX DUONG DAN DONG (DYNAMIC PATH)
        $PathNoDrive = $OutDir.Substring(2) # VD: \AIO_Output
        $WimPath = "$PathNoDrive\boot.wim"
        $SdiPath = "$PathNoDrive\boot.sdi"
        
        cmd /c "bcdedit /create {ramdiskoptions} /d `"Ramdisk Options`"" 2>$null
        cmd /c "bcdedit /set {ramdiskoptions} ramdisksdidevice partition=$Drive"
        # Fix path sdi
        cmd /c "bcdedit /set {ramdiskoptions} ramdisksdipath $SdiPath"
        
        $ID_Line = cmd /c "bcdedit /create /d `"$Desc`" /application osloader"
        if ($ID_Line -match '{([a-f0-9\-]+)}') { 
            $ID = $Matches[0] 
            cmd /c "bcdedit /set $ID device ramdisk=[$Drive]$WimPath,{ramdiskoptions}"
            cmd /c "bcdedit /set $ID osdevice ramdisk=[$Drive]$WimPath,{ramdiskoptions}"
            cmd /c "bcdedit /set $ID systemroot \windows"
            cmd /c "bcdedit /set $ID detecthal yes"
            cmd /c "bcdedit /set $ID winpe yes"
            cmd /c "bcdedit /displayorder $ID /addlast"
            cmd /c "bcdedit /timeout 10"
        }
        [System.Windows.Forms.MessageBox]::Show("DA TAO MENU BOOT THANH CONG!", "Xong")
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi: $($_.Exception.Message)", "Error") }
    $BtnHddBoot.Enabled = $true
})

# FIX EVENT: Add_FormClosing
$Form.Add_FormClosing({ foreach ($Iso in $Global:MountedISOs) { Dismount-DiskImage -ImagePath $Iso -ErrorAction SilentlyContinue | Out-Null } })
$Form.ShowDialog() | Out-Null
