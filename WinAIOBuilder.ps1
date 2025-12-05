<#
    WIN AIO BUILDER - PHAT TAN PC
    Version: 3.1 (Microsoft ADK Official + Mount Fix + HDD Boot)
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
$Form.Text = "WINDOWS AIO BUILDER V3.1 (MS OFFICIAL)"
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
$GbBuild = New-Object System.Windows.Forms.GroupBox; $GbBuild.Text = "2. Cấu Hình & Build (install.wim)"; $GbBuild.Location = "20,310"; $GbBuild.Size = "895,120"; $GbBuild.ForeColor = "Lime"; $Form.Controls.Add($GbBuild)

$LblOut = New-Object System.Windows.Forms.Label; $LblOut.Text = "Thư mục làm việc:"; $LblOut.Location = "15,25"; $LblOut.AutoSize = $true; $GbBuild.Controls.Add($LblOut)
$TxtOut = New-Object System.Windows.Forms.TextBox; $TxtOut.Location = "120,22"; $TxtOut.Size = "400,25"; $TxtOut.Text = "D:\AIO_Output"; $GbBuild.Controls.Add($TxtOut)
$BtnBrowseOut = New-Object System.Windows.Forms.Button; $BtnBrowseOut.Text = "..."; $BtnBrowseOut.Location = "530,20"; $BtnBrowseOut.Size = "40,27"; $GbBuild.Controls.Add($BtnBrowseOut)

$ChkBootLayout = New-Object System.Windows.Forms.CheckBox; $ChkBootLayout.Text = "Sao chép cấu trúc Boot (Để tạo file ISO sau này)"; $ChkBootLayout.Location = "120,55"; $ChkBootLayout.AutoSize = $true; $ChkBootLayout.Checked = $true; $ChkBootLayout.ForeColor = "Cyan"; $GbBuild.Controls.Add($ChkBootLayout)

$BtnBuild = New-Object System.Windows.Forms.Button; $BtnBuild.Text = "BẮT ĐẦU BUILD AIO"; $BtnBuild.Location = "600,20"; $BtnBuild.Size = "280,80"; $BtnBuild.BackColor = "Green"; $BtnBuild.ForeColor = "White"; $BtnBuild.Font = "Segoe UI, 12, Bold"; $GbBuild.Controls.Add($BtnBuild)

# 3. CREATE ISO
$GbIsoTool = New-Object System.Windows.Forms.GroupBox; $GbIsoTool.Text = "3. Đóng Gói Ra File ISO (Bootable)"; $GbIsoTool.Location = "20,440"; $GbIsoTool.Size = "440,150"; $GbIsoTool.ForeColor = "Orange"; $Form.Controls.Add($GbIsoTool)

$BtnMakeIso = New-Object System.Windows.Forms.Button; $BtnMakeIso.Text = "TẠO FILE ISO NGAY"; $BtnMakeIso.Location = "20,30"; $BtnMakeIso.Size = "400,50"; $BtnMakeIso.BackColor = "DarkOrange"; $BtnMakeIso.ForeColor = "Black"; $BtnMakeIso.Font = "Segoe UI, 11, Bold"; $GbIsoTool.Controls.Add($BtnMakeIso)

$LblIsoNote = New-Object System.Windows.Forms.Label; $LblIsoNote.Text = "* Yêu cầu: Đã Build AIO kèm cấu trúc Boot.`n* Tool sẽ kiểm tra oscdimg.exe (ADK) từ Microsoft."; $LblIsoNote.Location = "20,90"; $LblIsoNote.AutoSize = $true; $LblIsoNote.ForeColor = "Gray"; $GbIsoTool.Controls.Add($LblIsoNote)

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
    # 1. Kiểm tra file ngay tại thư mục Tool (Ưu tiên)
    $LocalTool = "$env:TEMP\oscdimg.exe"
    if (Test-Path $LocalTool) { return $LocalTool }
    
    # 2. Quét trong ổ C (Nếu đã cài ADK)
    Log "Dang quet tim oscdimg.exe trong may..."
    $AdkPaths = @(
        "$env:ProgramFiles(x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
        "$env:ProgramFiles\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
    )
    
    foreach ($Path in $AdkPaths) {
        if (Test-Path $Path) {
            Log "Da tim thay oscdimg.exe chinh chu MS!"
            return $Path
        }
    }

    # 3. Nếu không có -> Tải Installer từ Microsoft
    $AdkSetup = "$env:TEMP\adksetup.exe"
    $LinkMS = "https://go.microsoft.com/fwlink/?linkid=2243390" # Link gốc Win 11 ADK
    
    if ([System.Windows.Forms.MessageBox]::Show("Khong tim thay 'oscdimg.exe' (Tool tao ISO).`n`nBan co muon tai bo cai ADK chinh chu tu Microsoft khong?", "Thieu File", "YesNo", "Question") -eq "Yes") {
        Log "Dang tai ADK Setup tu Microsoft..."
        try {
            (New-Object System.Net.WebClient).DownloadFile($LinkMS, $AdkSetup)
            
            [System.Windows.Forms.MessageBox]::Show("DA TAI XONG ADK SETUP!`n`nHuong dan:`n1. Cua so cai dat se hien ra.`n2. Bam Next -> Den phan chon tinh nang.`n3. Chi can tich vao o 'Deployment Tools'.`n4. Bam Install.`n`nSau khi cai xong, hay bam 'TAO ISO' lai.", "Huong dan")
            
            # Chạy file cài đặt
            Start-Process $AdkSetup -Wait
            
            # Sau khi cài xong, thử tìm lại lần nữa
            foreach ($Path in $AdkPaths) {
                if (Test-Path $Path) { return $Path }
            }
        } catch {
            Log "Loi tai ADK: $($_.Exception.Message)"
            [System.Windows.Forms.MessageBox]::Show("Khong tai duoc tu Microsoft. Vui long kiem tra mang.", "Loi")
        }
    }
    return $null
}

function Mount-Scan ($Iso) {
    try {
        $Form.Cursor = "WaitCursor"
        Mount-DiskImage -ImagePath $Iso -StorageType ISO -ErrorAction Stop | Out-Null
        
        # SMART WAIT FIX
        $Vol = $null
        for($i=0;$i -lt 10;$i++){ 
            $Vol = Get-DiskImage -ImagePath $Iso | Get-Volume
            if($Vol -and $Vol.DriveLetter){break}
            Start-Sleep -m 500 
        }
        
        if ($Vol) {
            $Drv = "$($Vol.DriveLetter):"
            $Wim = "$Drv\sources\install.wim"; if(!(Test-Path $Wim)){$Wim="$Drv\sources\install.esd"}
            if(Test-Path $Wim){
                $Global:MountedISOs += $Iso
                $Info = Get-WindowsImage -ImagePath $Wim
                foreach($I in $Info){ $Grid.Rows.Add($true, $Iso, $I.ImageIndex, $I.ImageName, "$([Math]::Round($I.Size/1GB,2)) GB", $I.Architecture) | Out-Null }
            }
        } else {
            Log "Loi Mount: Device not ready (Timeout)"
        }
    } catch { Log "Loi Mount ISO: $_" }
    $Form.Cursor = "Default"
}

# --- EVENTS ---
$BtnAdd.Add_Click({ 
    $O = New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="ISO|*.iso"; $O.Multiselect=$true
    if($O.ShowDialog() -eq "OK"){ foreach($f in $O.FileNames){ if($TxtIsoList.Text -notmatch $f){ $TxtIsoList.Text+="$f; "; Mount-Scan $f } } }
})

$BtnEject.Add_Click({ Get-DiskImage -ImagePath "*.iso" | Dismount-DiskImage -ErrorAction SilentlyContinue; $TxtIsoList.Text=""; $Grid.Rows.Clear(); Log "Da go tat ca o ao." })
$BtnBrowseOut.Add_Click({ $F=New-Object System.Windows.Forms.FolderBrowserDialog; if($F.ShowDialog() -eq "OK"){$TxtOut.Text=$F.SelectedPath} })

# --- 1. BUILD AIO PROCESS ---
$BtnBuild.Add_Click({
    $Dir = $TxtOut.Text; if(!$Dir){return}; if(!(Test-Path $Dir)){New-Item -ItemType Directory -Path $Dir -Force | Out-Null}
    $Tasks = @(); foreach($r in $Grid.Rows){if($r.Cells[0].Value){$Tasks+=$r}}
    if($Tasks.Count -eq 0){ [System.Windows.Forms.MessageBox]::Show("Chua chon phien ban!", "Loi"); return }

    $BtnBuild.Enabled=$false
    
    # A. COPY BOOT LAYOUT (Optional)
    if ($ChkBootLayout.Checked) {
        $BaseIso = $Tasks[0].Cells[1].Value
        Log "Dang chuan bi cau truc Boot tu: $BaseIso..."
        $Vol = Get-DiskImage -ImagePath $BaseIso | Get-Volume
        $Drv = "$($Vol.DriveLetter):"
        
        # Robocopy tru install.wim/esd
        Log "Copying files (Robocopy)... Please wait."
        Start-Process "robocopy.exe" -ArgumentList "`"$Drv`" `"$Dir`" /E /XD `"$Drv\System Volume Information`" /XF install.wim install.esd /MT:16 /NFL /NDL" -NoNewWindow -Wait
        Log "Copy Boot Layout Done."
    }

    # B. EXPORT IMAGES
    $DestWim = "$Dir\sources\install.wim"
    if (!(Test-Path "$Dir\sources")) { New-Item -ItemType Directory -Path "$Dir\sources" -Force | Out-Null }
    
    $Count = 1
    foreach ($T in $Tasks) {
        $SrcIso = $T.Cells[1].Value; $Idx = $T.Cells[2].Value; $Name = $T.Cells[3].Value
        
        # Remount check
        $Vol = Get-DiskImage -ImagePath $SrcIso | Get-Volume
        if (!$Vol) { Mount-DiskImage -ImagePath $SrcIso -StorageType ISO -ErrorAction SilentlyContinue | Out-Null; Start-Sleep -s 1; $Vol = Get-DiskImage -ImagePath $SrcIso | Get-Volume }
        $Drv = "$($Vol.DriveLetter):"
        $SrcWim = "$Drv\sources\install.wim"; if(!(Test-Path $SrcWim)){$SrcWim="$Drv\sources\install.esd"}
        
        Log "Exporting ($Count/$($Tasks.Count)): $Name..."
        try {
            Export-WindowsImage -SourceImagePath $SrcWim -SourceIndex $Idx -DestinationImagePath $DestWim -DestinationName "$Name" -CompressionType Maximum -ErrorAction Stop
        } catch { Log "Loi Export: $_" }
        $Count++
    }
    
    Log "BUILD AIO HOAN TAT!"
    [System.Windows.Forms.MessageBox]::Show("Da tao xong install.wim tai: $Dir", "Thanh Cong")
    $BtnBuild.Enabled=$true
})

# --- 2. CREATE ISO PROCESS ---
$BtnMakeIso.Add_Click({
    $Dir = $TxtOut.Text
    if (!(Test-Path "$Dir\sources\install.wim") -or !(Test-Path "$Dir\boot")) { 
        [System.Windows.Forms.MessageBox]::Show("Thu muc '$Dir' thieu file cai dat hoac thieu thu muc boot!`nVui long chay 'BUILD AIO' va tich vao 'Sao chep cau truc Boot' truoc.", "Thieu file"); return 
    }

    $Oscd = Get-Oscdimg; if (!$Oscd) { return }
    
    $IsoName = "Windows_AIO_PhatTanPC.iso"
    $Save = New-Object System.Windows.Forms.SaveFileDialog; $Save.FileName=$IsoName; $Save.Filter="ISO Files|*.iso"
    if ($Save.ShowDialog() -eq "OK") {
        $Target = $Save.FileName
        Log "Dang tao file ISO: $Target..."
        $Form.Cursor = "WaitCursor"
        
        # Command chuan Microsoft tao ISO Boot 2 chuan (BIOS + UEFI)
        $CmdArgs = "-m -o -u2 -udfver102 -bootdata:2#p0,e,b`"$Dir\boot\etfsboot.com`"#pEF,e,b`"$Dir\efi\microsoft\boot\efisys.bin`" `"$Dir`" `"$Target`""
        
        $P = Start-Process $Oscd -ArgumentList $CmdArgs -NoNewWindow -PassThru -Wait
        
        if ($P.ExitCode -eq 0) {
            Log "TAO ISO THANH CONG!"
            [System.Windows.Forms.MessageBox]::Show("File ISO da duoc tao tai:`n$Target", "Thanh Cong")
            Invoke-Item $Target
        } else {
            Log "Loi tao ISO (Code $($P.ExitCode))."
            [System.Windows.Forms.MessageBox]::Show("Co loi khi tao ISO. Kiem tra lai file nguon.", "Loi")
        }
        $Form.Cursor = "Default"
    }
})

# --- 3. HDD BOOT PROCESS ---
$BtnHddBoot.Add_Click({
    $OutDir = $TxtOut.Text
    if (!(Test-Path "$OutDir\sources\install.wim")) { [System.Windows.Forms.MessageBox]::Show("Chua co file install.wim!", "Loi"); return }
    
    # 1. LAY BOOT.WIM TU ISO DAU TIEN
    if ($Grid.Rows.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Can it nhat 1 file ISO trong danh sach de lay boot.wim!", "Loi"); return }
    $FirstIso = $Grid.Rows[0].Cells[1].Value
    
    $LblHddStat.Text = "Dang trich xuat boot.wim..."
    $BtnHddBoot.Enabled = $false; [System.Windows.Forms.Application]::DoEvents()
    
    try {
        Mount-DiskImage -ImagePath $FirstIso -StorageType ISO -ErrorAction SilentlyContinue | Out-Null
        $Vol = Get-DiskImage -ImagePath $FirstIso | Get-Volume; if(!$Vol){Start-Sleep 1; $Vol=Get-DiskImage -ImagePath $FirstIso | Get-Volume}
        $Drv = "$($Vol.DriveLetter):"
        
        $BootWim = "$OutDir\boot.wim"
        Copy-Item "$Drv\sources\boot.wim" $BootWim -Force
        if (!(Test-Path "$OutDir\boot.sdi")) { Copy-Item "$Drv\boot\boot.sdi" "$OutDir\boot.sdi" -Force }
        
        # 2. INJECT
        $MountDir = "$env:TEMP\WimMount"
        if (Test-Path $MountDir) { Remove-Item $MountDir -Recurse -Force -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Path $MountDir -Force | Out-Null
        
        $LblHddStat.Text = "Dang cau hinh WinPE..."
        [System.Windows.Forms.Application]::DoEvents()
        
        Start-Process "dism" -ArgumentList "/Mount-Image /ImageFile:`"$BootWim`" /Index:2 /MountDir:`"$MountDir`"" -Wait -NoNewWindow
        
        # CMD INSTALLER
        $CmdContent = "@echo off`r`ntitle HDD INSTALLER`r`nfor %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (if exist `"%%d:%~p0install.wim`" set WIM=%%d:%~p0install.wim)`r`nif exist `"%%d:\AIO_Output\install.wim`" set WIM=%%d:\AIO_Output\install.wim`r`ndism /Apply-Image /ImageFile:`"%WIM%`" /Index:1 /ApplyDir:C:\`r`nbcdboot C:\Windows /s C:`r`npause`r`nwpeutil reboot"
        [IO.File]::WriteAllText("$OutDir\AIO_Installer.cmd", $CmdContent)
        
        # INJECT AUTO RUN
        [IO.File]::WriteAllText("$MountDir\Windows\System32\winpeshl.ini", "[LaunchApps]`r`n%SystemRoot%\System32\AutoRunAIO.cmd")
        $AutoCmd = "@echo off`r`nfor %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (`r`n if exist `"%%d:\AIO_Output\AIO_Installer.cmd`" (%%d: & cd \AIO_Output & call AIO_Installer.cmd & exit)`r`n)`r`ncmd.exe"
        [IO.File]::WriteAllText("$MountDir\Windows\System32\AutoRunAIO.cmd", $AutoCmd)
        
        $LblHddStat.Text = "Dang luu file Boot..."
        [System.Windows.Forms.Application]::DoEvents()
        Start-Process "dism" -ArgumentList "/Unmount-Image /MountDir:`"$MountDir`" /Commit" -Wait -NoNewWindow
        Remove-Item $MountDir -Recurse -Force
        
        # 3. BCD ENTRY
        $Desc = "PHAT TAN PC - CAI DAT AIO (HDD)"
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
        
        $LblHddStat.Text = "HOAN TAT!"
        [System.Windows.Forms.MessageBox]::Show("DA TAO MENU BOOT THANH CONG!", "Xong")
        
    } catch {
        $LblHddStat.Text = "Loi!"
        [System.Windows.Forms.MessageBox]::Show("Loi HDD Boot: $($_.Exception.Message)", "Error")
    }
    
    $BtnHddBoot.Enabled = $true
})

$Form.FormClosing.Add_Method({ foreach ($Iso in $Global:MountedISOs) { Dismount-DiskImage -ImagePath $Iso -ErrorAction SilentlyContinue | Out-Null } })
$Form.ShowDialog() | Out-Null
