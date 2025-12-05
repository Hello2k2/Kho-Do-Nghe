<#
    WIN AIO BUILDER - PHAT TAN PC
    Version: 2.2 (Fix Mount Delay + Eject Button + HDD Boot)
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
$Form.Text = "WINDOWS AIO BUILDER V2.2 (STABLE)"
$Form.Size = New-Object System.Drawing.Size(950, 750)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back; $Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

# Header
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "TẠO BỘ CÀI WINDOWS AIO & HDD BOOT"; $LblT.Font = "Impact, 18"; $LblT.ForeColor = $Theme.Accent; $LblT.AutoSize = $true; $LblT.Location = "20,15"; $Form.Controls.Add($LblT)

# LIST ISO
$GbIso = New-Object System.Windows.Forms.GroupBox; $GbIso.Text = "1. Chọn File ISO Nguồn (Windows 7/10/11)"; $GbIso.Location = "20,60"; $GbIso.Size = "895,80"; $GbIso.ForeColor = "Yellow"; $Form.Controls.Add($GbIso)

$TxtIsoList = New-Object System.Windows.Forms.TextBox; $TxtIsoList.Location = "20,30"; $TxtIsoList.Size = "580,30"; $TxtIsoList.ReadOnly = $true; $GbIso.Controls.Add($TxtIsoList)

$BtnAdd = New-Object System.Windows.Forms.Button; $BtnAdd.Text = "THÊM ISO..."; $BtnAdd.Location = "610,28"; $BtnAdd.Size = "130,30"; $BtnAdd.BackColor = "DimGray"; $BtnAdd.ForeColor = "White"; $GbIso.Controls.Add($BtnAdd)

# NÚT GỠ ISO (NEW FEATURE)
$BtnEject = New-Object System.Windows.Forms.Button; $BtnEject.Text = "GỠ TẤT CẢ Ổ ẢO"; $BtnEject.Location = "750,28"; $BtnEject.Size = "130,30"; $BtnEject.BackColor = "DarkRed"; $BtnEject.ForeColor = "White"; $GbIso.Controls.Add($BtnEject)

# DATA GRID
$Grid = New-Object System.Windows.Forms.DataGridView; $Grid.Location = "20,160"; $Grid.Size = "895,250"; $Grid.BackgroundColor = "Black"; $Grid.ForeColor = "Black"; $Grid.AllowUserToAddRows = $false; $Grid.RowHeadersVisible = $false; $Grid.SelectionMode = "FullRowSelect"; $Grid.AutoSizeColumnsMode = "Fill"
$ColChk = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn; $ColChk.Name = "Select"; $ColChk.HeaderText = "[X]"; $ColChk.Width = 40; $Grid.Columns.Add($ColChk) | Out-Null
$Grid.Columns.Add("ISO", "File ISO Nguồn"); $Grid.Columns.Add("Index", "Index"); $Grid.Columns.Add("Name", "Tên Phiên Bản (Edition)"); $Grid.Columns.Add("Size", "Dung Lượng"); $Grid.Columns.Add("Arch", "Kiến Trúc")
$Grid.Columns[1].Width = 50; $Grid.Columns[3].Width = 80; $Grid.Columns[4].Width = 60
$Form.Controls.Add($Grid)

# OUTPUT
$GbOut = New-Object System.Windows.Forms.GroupBox; $GbOut.Text = "2. Nơi Lưu File AIO (install.wim)"; $GbOut.Location = "20,430"; $GbOut.Size = "550,70"; $GbOut.ForeColor = "Lime"; $Form.Controls.Add($GbOut)
$TxtOut = New-Object System.Windows.Forms.TextBox; $TxtOut.Location = "20,25"; $TxtOut.Size = "400,25"; $TxtOut.Text = "D:\AIO_Output"; $GbOut.Controls.Add($TxtOut)
$BtnBrowseOut = New-Object System.Windows.Forms.Button; $BtnBrowseOut.Text = "CHỌN..."; $BtnBrowseOut.Location = "440,23"; $BtnBrowseOut.Size = "90,27"; $BtnBrowseOut.BackColor = "Gray"; $BtnBrowseOut.ForeColor = "White"; $GbOut.Controls.Add($BtnBrowseOut)

$BtnBuild = New-Object System.Windows.Forms.Button; $BtnBuild.Text = "TIẾN HÀNH BUILD AIO"; $BtnBuild.Location = "590,440"; $BtnBuild.Size = "325,60"; $BtnBuild.BackColor = "Green"; $BtnBuild.ForeColor = "White"; $BtnBuild.Font = "Segoe UI, 14, Bold"
$Form.Controls.Add($BtnBuild)

# --- 3. HDD BOOT (NO USB) ---
$GbHdd = New-Object System.Windows.Forms.GroupBox; $GbHdd.Text = "3. CHẾ ĐỘ CÀI ĐẶT KHÔNG CẦN USB (HDD BOOT)"; $GbHdd.Location = "20,520"; $GbHdd.Size = "895,130"; $GbHdd.ForeColor = "OrangeRed"; $Form.Controls.Add($GbHdd)

$LblHdd = New-Object System.Windows.Forms.Label; $LblHdd.Text = "Tính năng này sẽ tạo menu Boot vào WinPE và tự động chạy file AIO_Installer.cmd`n(Dùng trong trường hợp không có USB, muốn cài lại Win sạch từ ổ cứng)"; $LblHdd.Location = "20,30"; $LblHdd.AutoSize = $true; $LblHdd.ForeColor = "LightGray"; $GbHdd.Controls.Add($LblHdd)

$BtnHddBoot = New-Object System.Windows.Forms.Button; $BtnHddBoot.Text = "TẠO MENU BOOT CÀI TRỰC TIẾP"; $BtnHddBoot.Location = "20,80"; $BtnHddBoot.Size = "300,35"; $BtnHddBoot.BackColor = "Firebrick"; $BtnHddBoot.ForeColor = "White"; $BtnHddBoot.Font = "Segoe UI, 10, Bold"; $GbHdd.Controls.Add($BtnHddBoot)

$LblStat = New-Object System.Windows.Forms.Label; $LblStat.Text = "Sẵn sàng."; $LblStat.Location = "340,90"; $LblStat.AutoSize = $true; $LblStat.ForeColor = "Cyan"; $GbHdd.Controls.Add($LblStat)

# --- LOGIC ---
$Global:MountedISOs = @()

# Hàm Mount với cơ chế đợi thông minh (Fix lỗi device not ready)
function Mount-And-Scan ($IsoPath) {
    try {
        $Form.Cursor = "WaitCursor"
        
        # 1. Mount ISO
        Mount-DiskImage -ImagePath $IsoPath -StorageType ISO -ErrorAction Stop | Out-Null
        
        # 2. FIX LỖI: Chờ ổ đĩa xuất hiện (Smart Wait Loop)
        $DriveLetter = $null
        for ($i = 0; $i -lt 10; $i++) { # Thử lại 10 lần (5 giây)
            $Vol = Get-DiskImage -ImagePath $IsoPath | Get-Volume
            if ($Vol -and $Vol.DriveLetter) {
                $DriveLetter = $Vol.DriveLetter
                break
            }
            Start-Sleep -Milliseconds 500
        }
        
        if (!$DriveLetter) { throw "Không thể Mount ISO hoặc không nhận diện được ổ đĩa!" }
        
        # 3. Kiểm tra file WIM
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
            [System.Windows.Forms.MessageBox]::Show("Không tìm thấy file install.wim/esd trong ISO!", "Cảnh báo")
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Lỗi đọc ISO: $IsoPath`n`nChi tiết: $($_.Exception.Message)", "Lỗi")
    }
    $Form.Cursor = "Default"
}

$BtnAdd.Add_Click({
    $OFD = New-Object System.Windows.Forms.OpenFileDialog; $OFD.Filter = "ISO Files (*.iso)|*.iso"; $OFD.Multiselect = $true
    if ($OFD.ShowDialog() -eq "OK") {
        foreach ($File in $OFD.FileNames) {
            if ($TxtIsoList.Text -notmatch $File) {
                $TxtIsoList.Text += "$File; "
                Mount-And-Scan $File
            }
        }
    }
})

$BtnEject.Add_Click({
    try {
        Get-DiskImage -ImagePath "*.iso" | Dismount-DiskImage -ErrorAction SilentlyContinue
        $TxtIsoList.Text = ""
        $Grid.Rows.Clear()
        [System.Windows.Forms.MessageBox]::Show("Đã gỡ sạch các ổ đĩa ảo!", "Thành công")
    } catch {}
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
    if ($Tasks.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn phiên bản nào!", "Lỗi"); return }

    $BtnBuild.Enabled = $false; $BtnBuild.Text = "ĐANG XỬ LÝ..."
    
    try {
        $Count = 1
        foreach ($Task in $Tasks) {
            $Iso = $Task.Cells[1].Value
            $Idx = $Task.Cells[2].Value
            $Name = $Task.Cells[3].Value
            
            # Mount lại để chắc chắn ổ đĩa còn đó
            Mount-DiskImage -ImagePath $Iso -StorageType ISO -ErrorAction SilentlyContinue | Out-Null
            $Vol = Get-DiskImage -ImagePath $Iso | Get-Volume
            if (!$Vol) { Start-Sleep -s 2; $Vol = Get-DiskImage -ImagePath $Iso | Get-Volume } 
            
            $Drv = "$($Vol.DriveLetter):"
            $SrcWim = "$Drv\sources\install.wim"; if (!(Test-Path $SrcWim)) { $SrcWim = "$Drv\sources\install.esd" }
            
            $BtnBuild.Text = "Đang xuất ($Count/$($Tasks.Count)): $Name..."
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

        [System.Windows.Forms.MessageBox]::Show("BUILD THÀNH CÔNG!`nFile lưu tại: $OutDir", "Thành công")
        Invoke-Item $OutDir
    } catch {
        [System.Windows.Forms.MessageBox]::Show("LỖI: $($_.Exception.Message)", "Lỗi")
    }
    
    $BtnBuild.Text = "TIẾN HÀNH BUILD AIO"; $BtnBuild.Enabled = $true
})

# --- HDD BOOT LOGIC ---
$BtnHddBoot.Add_Click({
    $OutDir = $TxtOut.Text
    if (!(Test-Path "$OutDir\AIO_Installer.cmd")) { [System.Windows.Forms.MessageBox]::Show("Chưa thấy file AIO_Installer.cmd!`nVui lòng BUILD AIO trước.", "Lỗi"); return }
    
    if ($Grid.Rows.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Cần ít nhất 1 file ISO trong danh sách để lấy boot.wim!", "Lỗi"); return }
    $FirstIso = $Grid.Rows[0].Cells[1].Value
    
    $LblStat.Text = "Đang trích xuất boot.wim..."
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
        
        $LblStat.Text = "Đang cấu hình WinPE (Inject)..."
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
        
        $LblStat.Text = "Đang lưu file Boot..."
        [System.Windows.Forms.Application]::DoEvents()
        Start-Process "dism" -ArgumentList "/Unmount-Image /MountDir:`"$MountDir`" /Commit" -Wait -NoNewWindow
        Remove-Item $MountDir -Recurse -Force
        
        $LblStat.Text = "Đang thêm Menu Boot..."
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
        
        $LblStat.Text = "HOÀN TẤT!"
        if ([System.Windows.Forms.MessageBox]::Show("ĐÃ TẠO MENU BOOT THÀNH CÔNG!`n`nBạn có muốn KHỞI ĐỘNG LẠI MÁY ngay lập tức để vào chế độ cài đặt không?", "Xong", "YesNo", "Question") -eq "Yes") {
            Restart-Computer -Force
        }
        
    } catch {
        $LblStat.Text = "Lỗi!"
        [System.Windows.Forms.MessageBox]::Show("Lỗi HDD Boot: $($_.Exception.Message)", "Lỗi")
    }
    
    $BtnHddBoot.Enabled = $true
})

$Form.FormClosing.Add_Method({ foreach ($Iso in $Global:MountedISOs) { Dismount-DiskImage -ImagePath $Iso -ErrorAction SilentlyContinue | Out-Null } })
$Form.ShowDialog() | Out-Null
