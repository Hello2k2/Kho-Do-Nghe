# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WINDOWS AIO BUILDER V2.1 (FIX MOUNT ERROR)"
$Form.Size = New-Object System.Drawing.Size(900, 720) 
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "TAO BO CAI WINDOWS AIO & HDD BOOT"; $LblT.Font = "Impact, 18"; $LblT.ForeColor="Cyan"; $LblT.AutoSize=$true; $LblT.Location="20,15"; $Form.Controls.Add($LblT)

# LIST ISO
$GbIso = New-Object System.Windows.Forms.GroupBox; $GbIso.Text = "1. Them File ISO Nguon"; $GbIso.Location="20,60"; $GbIso.Size="845,80"; $GbIso.ForeColor="Yellow"; $Form.Controls.Add($GbIso)
$TxtIsoList = New-Object System.Windows.Forms.TextBox; $TxtIsoList.Location="20,30"; $TxtIsoList.Size="650,30"; $TxtIsoList.ReadOnly=$true; $GbIso.Controls.Add($TxtIsoList)
$BtnAdd = New-Object System.Windows.Forms.Button; $BtnAdd.Text="THEM ISO..."; $BtnAdd.Location="690,28"; $BtnAdd.Size="130,30"; $BtnAdd.BackColor="DimGray"; $BtnAdd.ForeColor="White"
$GbIso.Controls.Add($BtnAdd)

# DATA GRID
$Grid = New-Object System.Windows.Forms.DataGridView; $Grid.Location="20,160"; $Grid.Size="845,250"; $Grid.BackgroundColor="Black"; $Grid.ForeColor="Black"; $Grid.AllowUserToAddRows=$false; $Grid.RowHeadersVisible=$false; $Grid.SelectionMode="FullRowSelect"; $Grid.AutoSizeColumnsMode="Fill"
$ColChk = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn; $ColChk.Name="Select"; $ColChk.HeaderText="[X]"; $ColChk.Width=40; $Grid.Columns.Add($ColChk) | Out-Null
$Grid.Columns.Add("ISO", "File ISO Nguon"); $Grid.Columns.Add("Index", "Index"); $Grid.Columns.Add("Name", "Ten Phien Ban (Edition)"); $Grid.Columns.Add("Size", "Dung Luong"); $Grid.Columns.Add("Arch", "Kien Truc")
$Grid.Columns[1].Width=50; $Grid.Columns[3].Width=80; $Grid.Columns[4].Width=60
$Form.Controls.Add($Grid)

# OUTPUT
$GbOut = New-Object System.Windows.Forms.GroupBox; $GbOut.Text = "2. Noi Luu File AIO (install.wim)"; $GbOut.Location="20,430"; $GbOut.Size="550,70"; $GbOut.ForeColor="Lime"; $Form.Controls.Add($GbOut)
$TxtOut = New-Object System.Windows.Forms.TextBox; $TxtOut.Location="20,25"; $TxtOut.Size="400,25"; $TxtOut.Text="D:\AIO_Output"; $GbOut.Controls.Add($TxtOut)
$BtnBrowseOut = New-Object System.Windows.Forms.Button; $BtnBrowseOut.Text="CHON..."; $BtnBrowseOut.Location="440,23"; $BtnBrowseOut.Size="90,27"; $BtnBrowseOut.BackColor="Gray"; $BtnBrowseOut.ForeColor="White"; $GbOut.Controls.Add($BtnBrowseOut)

$BtnBuild = New-Object System.Windows.Forms.Button; $BtnBuild.Text="BUILD AIO NOW"; $BtnBuild.Location="590,440"; $BtnBuild.Size="275,60"; $BtnBuild.BackColor="Green"; $BtnBuild.ForeColor="White"; $BtnBuild.Font="Segoe UI, 14, Bold"
$Form.Controls.Add($BtnBuild)

# --- 3. HDD BOOT (NO USB) ---
$GbHdd = New-Object System.Windows.Forms.GroupBox; $GbHdd.Text = "3. CHE DO CAI DAT KHONG CAN USB (HDD BOOT)"; $GbHdd.Location="20,520"; $GbHdd.Size="845,130"; $GbHdd.ForeColor="OrangeRed"; $Form.Controls.Add($GbHdd)

$LblHdd = New-Object System.Windows.Forms.Label; $LblHdd.Text = "Tinh nang nay se tao menu Boot vao WinPE va tu dong chay file AIO_Installer.cmd`n(Dung trong truong hop khong co USB, muon cai lai Win sach tu o cung)"; $LblHdd.Location="20,30"; $LblHdd.AutoSize=$true; $LblHdd.ForeColor="LightGray"; $GbHdd.Controls.Add($LblHdd)

$BtnHddBoot = New-Object System.Windows.Forms.Button; $BtnHddBoot.Text="TAO MENU BOOT CAI TRUC TIEP"; $BtnHddBoot.Location="20,80"; $BtnHddBoot.Size="300,35"; $BtnHddBoot.BackColor="Firebrick"; $BtnHddBoot.ForeColor="White"; $BtnHddBoot.Font="Segoe UI, 10, Bold"; $GbHdd.Controls.Add($BtnHddBoot)

$LblStat = New-Object System.Windows.Forms.Label; $LblStat.Text = "San sang."; $LblStat.Location="340,90"; $LblStat.AutoSize=$true; $LblStat.ForeColor="Cyan"; $GbHdd.Controls.Add($LblStat)

# --- LOGIC (FIXED MOUNT) ---
$Global:MountedISOs = @()

function Mount-And-Scan ($IsoPath) {
    try {
        $Form.Cursor = "WaitCursor"
        
        # 1. Mount ISO
        Mount-DiskImage -ImagePath $IsoPath -StorageType ISO -ErrorAction Stop | Out-Null
        
        # 2. FIX LOI: Cho o dia xuat hien (Smart Wait Loop)
        $DriveLetter = $null
        for ($i = 0; $i -lt 10; $i++) { # Thu lai 10 lan (5 giay)
            $Vol = Get-DiskImage -ImagePath $IsoPath | Get-Volume
            if ($Vol -and $Vol.DriveLetter) {
                $DriveLetter = $Vol.DriveLetter
                break
            }
            Start-Sleep -Milliseconds 500
        }
        
        if (!$DriveLetter) { throw "Khong the Mount ISO hoac khong nhan dien duoc o dia!" }
        
        # 3. Kiem tra file WIM
        $Drv = "$($DriveLetter):"
        $Wim = "$Drv\sources\install.wim"
        if (!(Test-Path $Wim)) { $Wim = "$Drv\sources\install.esd" }
        
        if (Test-Path $Wim) {
            $Global:MountedISOs += $IsoPath
            $Info = Get-WindowsImage -ImagePath $Wim
            foreach ($I in $Info) {
                $SizeGB = [Math]::Round($I.Size / 1GB, 2)
                $Grid.Rows.Add($true, $IsoPath, $I.ImageIndex, $I.ImageName, "$SizeGB GB", $I.Architecture) | Out-Null
            }
        } else {
            [System.Windows.Forms.MessageBox]::Show("Khong tim thay file install.wim/esd trong ISO!", "Warning")
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Loi doc ISO: $IsoPath`n`nChi tiet: $($_.Exception.Message)", "Error")
    }
    $Form.Cursor = "Default"
}

$BtnAdd.Add_Click({
    $OFD = New-Object System.Windows.Forms.OpenFileDialog; $OFD.Filter="ISO Files (*.iso)|*.iso"; $OFD.Multiselect=$true
    if ($OFD.ShowDialog() -eq "OK") {
        foreach ($File in $OFD.FileNames) {
            if ($TxtIsoList.Text -notmatch $File) {
                $TxtIsoList.Text += "$File; "
                Mount-And-Scan $File
            }
        }
    }
})

$BtnBrowseOut.Add_Click({
    $FBD = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($FBD.ShowDialog() -eq "OK") { $TxtOut.Text = $FBD.SelectedPath }
})

# --- BUILD AIO ---
$BtnBuild.Add_Click({
    $OutDir = $TxtOut.Text; if (!$OutDir) { return }
    if (!(Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }
    $OutWim = "$OutDir\install.wim"
    
    $Tasks = @(); foreach ($Row in $Grid.Rows) { if ($Row.Cells[0].Value -eq $true) { $Tasks += $Row } }
    if ($Tasks.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Chua chon phien ban nao!", "Loi"); return }

    $BtnBuild.Enabled=$false; $BtnBuild.Text="DANG XU LY..."
    
    try {
        $Count = 1
        foreach ($Task in $Tasks) {
            $Iso = $Task.Cells[1].Value
            $Idx = $Task.Cells[2].Value
            $Name = $Task.Cells[3].Value
            
            # Mount lai de chac chan o dia con do
            Mount-DiskImage -ImagePath $Iso -StorageType ISO -ErrorAction SilentlyContinue | Out-Null
            $Vol = Get-DiskImage -ImagePath $Iso | Get-Volume
            if (!$Vol) { Start-Sleep -s 2; $Vol = Get-DiskImage -ImagePath $Iso | Get-Volume } # Wait again
            
            $Drv = "$($Vol.DriveLetter):"
            $SrcWim = "$Drv\sources\install.wim"; if (!(Test-Path $SrcWim)) { $SrcWim = "$Drv\sources\install.esd" }
            
            $BtnBuild.Text = "Exporting ($Count/$($Tasks.Count)): $Name..."
            [System.Windows.Forms.Application]::DoEvents()
            
            Export-WindowsImage -SourceImagePath $SrcWim -SourceIndex $Idx -DestinationImagePath $OutWim -DestinationName "$Name (AIO)" -CompressionType Maximum -ErrorAction Stop
            $Count++
        }
        
        # TAO CMD INSTALLER
        $CmdContent = @"
@echo off
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
        [IO.File]::WriteAllText("$OutDir\AIO_Installer.cmd", $CmdContent)

        [System.Windows.Forms.MessageBox]::Show("BUILD THANH CONG!`nFile luu tai: $OutDir", "Success")
        Invoke-Item $OutDir
    } catch {
        [System.Windows.Forms.MessageBox]::Show("LOI: $($_.Exception.Message)", "Error")
    }
    
    $BtnBuild.Text = "BUILD AIO NOW"; $BtnBuild.Enabled=$true
})

# --- HDD BOOT LOGIC ---
$BtnHddBoot.Add_Click({
    $OutDir = $TxtOut.Text
    if (!(Test-Path "$OutDir\AIO_Installer.cmd")) { [System.Windows.Forms.MessageBox]::Show("Chua thay file AIO_Installer.cmd!`nVui long BUILD AIO truoc.", "Loi"); return }
    
    if ($Grid.Rows.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Can it nhat 1 file ISO trong danh sach de lay boot.wim!", "Loi"); return }
    $FirstIso = $Grid.Rows[0].Cells[1].Value
    
    $LblStat.Text = "Dang trich xuat boot.wim..."
    $BtnHddBoot.Enabled = $false; [System.Windows.Forms.Application]::DoEvents()
    
    try {
        Mount-DiskImage -ImagePath $FirstIso -StorageType ISO -ErrorAction SilentlyContinue | Out-Null
        $Vol = Get-DiskImage -ImagePath $FirstIso | Get-Volume
        $Drv = "$($Vol.DriveLetter):"
        
        $BootWim = "$OutDir\boot.wim"
        Copy-Item "$Drv\sources\boot.wim" $BootWim -Force
        
        $MountDir = "$env:TEMP\WimMount"
        if (Test-Path $MountDir) { Remove-Item $MountDir -Recurse -Force -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Path $MountDir -Force | Out-Null
        
        $LblStat.Text = "Dang cau hinh WinPE (Inject)..."
        [System.Windows.Forms.Application]::DoEvents()
        
        Start-Process "dism" -ArgumentList "/Mount-Image /ImageFile:`"$BootWim`" /Index:2 /MountDir:`"$MountDir`"" -Wait -NoNewWindow
        
        $IniContent = "[LaunchApps]`r`n%SystemRoot%\System32\AutoRunAIO.cmd"
        [IO.File]::WriteAllText("$MountDir\Windows\System32\winpeshl.ini", $IniContent)
        
        $AutoCmd = @"
@echo off
for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%d:\AIO_Output\AIO_Installer.cmd" (
        %%d:
        cd \AIO_Output
        call AIO_Installer.cmd
        exit
    )
    if exist "%%d:AIO_Installer.cmd" (
        %%d:
        call AIO_Installer.cmd
        exit
    )
)
echo KHONG TIM THAY FILE CAI DAT!
cmd.exe
"@
        [IO.File]::WriteAllText("$MountDir\Windows\System32\AutoRunAIO.cmd", $AutoCmd)
        
        $LblStat.Text = "Dang luu file Boot..."
        [System.Windows.Forms.Application]::DoEvents()
        Start-Process "dism" -ArgumentList "/Unmount-Image /MountDir:`"$MountDir`" /Commit" -Wait -NoNewWindow
        Remove-Item $MountDir -Recurse -Force
        
        $LblStat.Text = "Dang them Menu Boot..."
        $Desc = "PHAT TAN PC - CAI DAT AIO (HDD)"
        
        if (!(Test-Path "$OutDir\boot.sdi")) { Copy-Item "$Drv\boot\boot.sdi" "$OutDir\boot.sdi" -Force }
        
        $Drive = $OutDir.Substring(0,2) 
        $WimPath = $BootWim.Substring(2)
        
        cmd /c "bcdedit /create {ramdiskoptions} /d `"Ramdisk Options`"" 2>$null
        cmd /c "bcdedit /set {ramdiskoptions} ramdisksdidevice partition=$Drive"
        cmd /c "bcdedit /set {ramdiskoptions} ramdisksdipath \AIO_Output\boot.sdi"
        
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
        
        $LblStat.Text = "HOAN TAT!"
        if ([System.Windows.Forms.MessageBox]::Show("DA TAO MENU BOOT THANH CONG!`n`nBan co muon KHOI DONG LAI MAY ngay lap tuc de vao che do cai dat khong?", "Xong", "YesNo", "Question") -eq "Yes") {
            Restart-Computer -Force
        }
        
    } catch {
        $LblStat.Text = "Loi!"
        [System.Windows.Forms.MessageBox]::Show("Loi HDD Boot: $($_.Exception.Message)", "Error")
    }
    
    $BtnHddBoot.Enabled = $true
})

$Form.FormClosing.Add_Method({ foreach ($Iso in $Global:MountedISOs) { Dismount-DiskImage -ImagePath $Iso -ErrorAction SilentlyContinue | Out-Null } })
$Form.ShowDialog() | Out-Null
