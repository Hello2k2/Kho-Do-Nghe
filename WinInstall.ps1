# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

# --- INIT ---
try { Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing } catch { Exit }
$ErrorActionPreference = "SilentlyContinue"
$DebugLog = "C:\PhatTan_Debug.txt"

# --- LOG FUNCTION ---
function Write-DebugLog ($Message) {
    $Time = Get-Date -Format "HH:mm:ss"; $Line = "[$Time] $Message"
    $Line | Out-File -FilePath $DebugLog -Append -Encoding UTF8
}
if (Test-Path $DebugLog) { Remove-Item $DebugLog -Force }
Write-DebugLog "=== TOOL START V18.0 (FIX VM DISK & PASSWORD) ==="

# --- CẤU HÌNH ---
$WinToHDD_Url = "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/WinToHDD.exe"
$XML_Url = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/autounattend.xml"
$Global:DriverPath = "D:\Drivers_Backup_Auto"
$Global:SelectedDisk = 0
$Global:SelectedPart = 0
$Global:SelectedLabel = ""

# --- HÀM CLEANUP ---
function Dismount-All {
    Get-DiskImage -ImagePath * -ErrorAction SilentlyContinue | Dismount-DiskImage -ErrorAction SilentlyContinue | Out-Null
}

# --- HÀM MOUNT HYBRID (BẤT TỬ) ---
function Mount-And-GetDrive ($IsoPath) {
    Write-DebugLog "Mounting: $IsoPath"
    Dismount-All
    try { Mount-DiskImage -ImagePath $IsoPath -StorageType ISO -ErrorAction Stop | Out-Null; Start-Sleep -Seconds 2 } catch { return $null }

    # 1. Get-DiskImage
    try {
        $Vol = Get-DiskImage -ImagePath $IsoPath | Get-Volume
        if ($Vol) { 
            $L = "$($Vol.DriveLetter):"
            if (Test-Path "$L\setup.exe") { return $L } 
        }
    } catch {}

    # 2. Brute Force
    $Drives = Get-PSDrive -PSProvider FileSystem
    foreach ($D in $Drives) {
        $R = $D.Root
        if ($R -in "C:\", "A:\", "B:\") { continue }
        if ((Test-Path "$R\setup.exe") -and (Test-Path "$R\bootmgr")) { 
            return [string]$R.TrimEnd("\")
        }
    }
    return $null
}

# --- HÀM TẠO BOOT ---
function Get-BiosMode { if (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State") { return "UEFI" } return "Legacy" }

function Create-Boot-Entry ($WimPath) {
    try {
        $BcdList = bcdedit /enum /v | Out-String; $Lines = $BcdList -split "`r`n"
        for ($i=0; $i -lt $Lines.Count; $i++) { if ($Lines[$i] -match "description\s+CAI WIN TAM THOI") { for ($j=$i; $j -ge 0; $j--) { if ($Lines[$j] -match "identifier\s+{(.*)}") { cmd /c "bcdedit /delete {$($Matches[1])} /f"; break } } } }
        
        $Name = "CAI WIN TAM THOI (Phat Tan PC)"; $Mode = Get-BiosMode; $Drive = $env:SystemDrive
        cmd /c "bcdedit /create {ramdiskoptions} /d `"Ramdisk Options`"" 2>$null
        cmd /c "bcdedit /set {ramdiskoptions} ramdisksdidevice partition=$Drive"
        cmd /c "bcdedit /set {ramdiskoptions} ramdisksdipath \boot.sdi"
        
        $Output = cmd /c "bcdedit /create /d `"$Name`" /application osloader"
        if ($Output -match '{([a-f0-9\-]+)}') { $ID = $matches[0] } else { return $false }
        
        cmd /c "bcdedit /set $ID device ramdisk=[$Drive]$WimPath,{ramdiskoptions}"
        cmd /c "bcdedit /set $ID osdevice ramdisk=[$Drive]$WimPath,{ramdiskoptions}"
        cmd /c "bcdedit /set $ID systemroot \windows"
        cmd /c "bcdedit /set $ID detecthal yes"
        cmd /c "bcdedit /set $ID winpe yes"
        
        if ($Mode -eq "UEFI") { cmd /c "bcdedit /set $ID path \windows\system32\boot\winload.efi" } else { cmd /c "bcdedit /set $ID path \windows\system32\boot\winload.exe" }
        cmd /c "bcdedit /displayorder $ID /addlast"; cmd /c "bcdedit /bootsequence $ID"
        return $true
    } catch { return $false }
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CAI DAT WINDOWS MASTER - PHAT TAN PC (V18.0)"
$Form.Size = New-Object System.Drawing.Size(800, 650)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30); $Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

$LblTitle = New-Object System.Windows.Forms.Label; $LblTitle.Text = "CHON FILE ISO"; $LblTitle.Font = "Segoe UI, 12, Bold"; $LblTitle.ForeColor = "Cyan"; $LblTitle.AutoSize=$true; $LblTitle.Location = "20,15"; $Form.Controls.Add($LblTitle)
$CmbISO = New-Object System.Windows.Forms.ComboBox; $CmbISO.Size = "580, 30"; $CmbISO.Location = "20,45"; $CmbISO.Font = "Segoe UI, 10"; $CmbISO.DropDownStyle = "DropDownList"; $Form.Controls.Add($CmbISO)
$BtnBrowse = New-Object System.Windows.Forms.Button; $BtnBrowse.Text = "TIM ISO"; $BtnBrowse.Location = "610,43"; $BtnBrowse.Size = "100,30"; $BtnBrowse.BackColor = "Gray"; $BtnBrowse.Add_Click({ $OFD = New-Object System.Windows.Forms.OpenFileDialog; $OFD.Filter = "ISO (*.iso)|*.iso"; if ($OFD.ShowDialog() -eq "OK") { $CmbISO.Items.Insert(0, $OFD.FileName); $CmbISO.SelectedIndex = 0 } }); $Form.Controls.Add($BtnBrowse)

# --- GROUP CHỌN CHẾ ĐỘ ---
$GBAct = New-Object System.Windows.Forms.GroupBox; $GBAct.Text = "CHON CHE DO CAI DAT"; $GBAct.Location = "20,100"; $GBAct.Size = "740,450"; $GBAct.ForeColor = "Lime"; $Form.Controls.Add($GBAct)

$BtnSetup = New-Object System.Windows.Forms.Button; $BtnSetup.Text = "1. CAI DE / NANG CAP (Setup.exe)"; $BtnSetup.Location = "30,40"; $BtnSetup.Size = "680,50"; $BtnSetup.BackColor = "LimeGreen"; $BtnSetup.ForeColor = "Black"; $BtnSetup.Font = "Segoe UI, 12, Bold"
$BtnSetup.Add_Click({ 
    $ISO = $CmbISO.SelectedItem; if (!$ISO) { return }
    [string]$Drive = Mount-And-GetDrive $ISO; if ($Drive -match "([A-Z]:)") { $Drive = $matches[1] }
    if ($Drive) { Start-Process "$Drive\setup.exe"; $Form.Close() } else { [System.Windows.Forms.MessageBox]::Show("Loi Mount!", "Loi") }
})
$GBAct.Controls.Add($BtnSetup)

$BtnBoot = New-Object System.Windows.Forms.Button; $BtnBoot.Text = "2. TAO BOOT TAM (Clean Install / Dual Boot)"; $BtnBoot.Location = "30,110"; $BtnBoot.Size = "680,50"; $BtnBoot.BackColor = "Magenta"; $BtnBoot.ForeColor = "White"; $BtnBoot.Font = "Segoe UI, 12, Bold"
$BtnBoot.Add_Click({ Show-Advanced-Config })
$GBAct.Controls.Add($BtnBoot)

$BtnWTH = New-Object System.Windows.Forms.Button; $BtnWTH.Text = "3. DUNG WINTOHDD (Portable)"; $BtnWTH.Location = "30,180"; $BtnWTH.Size = "680,50"; $BtnWTH.BackColor = "Orange"; $BtnWTH.ForeColor = "Black"; $BtnWTH.Font = "Segoe UI, 12, Bold"
$BtnWTH.Add_Click({ 
    $P = "$env:TEMP\WinToHDD.exe"; if (!(Test-Path $P)) { (New-Object Net.WebClient).DownloadFile($WinToHDD_Url, $P) }
    Start-Process $P 
})
$GBAct.Controls.Add($BtnWTH)

# --- FORM CẤU HÌNH NÂNG CAO ---
function Show-Advanced-Config {
    $ISO = $CmbISO.SelectedItem; if (!$ISO) { [System.Windows.Forms.MessageBox]::Show("Chua chon ISO!", "Loi"); return }
    
    $Form.Cursor = "WaitCursor"
    [string]$Drive = Mount-And-GetDrive $ISO
    if ($Drive -match "([A-Z]:)") { $Drive = $matches[1] }
    if (!$Drive) { $Form.Cursor = "Default"; [System.Windows.Forms.MessageBox]::Show("Loi Mount!", "Loi"); return }
    
    $Wim = "$Drive\sources\install.wim"; if (!(Test-Path $Wim)) { $Wim = "$Drive\sources\install.esd" }
    
    $ConfForm = New-Object System.Windows.Forms.Form; $ConfForm.Text = "CAU HINH CAI DAT CHI TIET"; $ConfForm.Size = "800, 750"; $ConfForm.StartPosition = "CenterParent"; $ConfForm.BackColor = "Black"; $ConfForm.ForeColor = "White"
    
    # 1. CHỌN PHIÊN BẢN
    $LblEd = New-Object System.Windows.Forms.Label; $LblEd.Text = "1. CHON PHIEN BAN WINDOWS:"; $LblEd.Location = "20,20"; $LblEd.AutoSize=$true; $LblEd.ForeColor="Cyan"; $ConfForm.Controls.Add($LblEd)
    $CmbEd = New-Object System.Windows.Forms.ComboBox; $CmbEd.Location = "20,50"; $CmbEd.Size = "740,30"; $CmbEd.DropDownStyle="DropDownList"
    $Info = dism /Get-WimInfo /WimFile:$Wim
    $Indexes = $Info | Select-String "Index :"; $Names = $Info | Select-String "Name :"
    for ($i=0; $i -lt $Indexes.Count; $i++) {
        $Idx = $Indexes[$i].ToString().Split(":")[1].Trim(); $Nam = $Names[$i].ToString().Split(":")[1].Trim()
        $CmbEd.Items.Add("$Idx - $Nam")
    }
    $CmbEd.SelectedIndex = 0; $ConfForm.Controls.Add($CmbEd)

    # 2. CHỌN Ổ CỨNG (FIX HIỂN THỊ MÁY ẢO)
    $LblD = New-Object System.Windows.Forms.Label; $LblD.Text = "2. CHON PHAN VUNG CAI DAT (Chon O C neu muon de len):"; $LblD.Location = "20,100"; $LblD.AutoSize=$true; $LblD.ForeColor="Cyan"; $ConfForm.Controls.Add($LblD)
    $GridPart = New-Object System.Windows.Forms.DataGridView; $GridPart.Location = "20,130"; $GridPart.Size = "740,200"; $GridPart.BackgroundColor="Black"; $GridPart.ForeColor="Black"
    $GridPart.AllowUserToAddRows=$false; $GridPart.RowHeadersVisible=$false; $GridPart.SelectionMode="FullRowSelect"; $GridPart.MultiSelect=$false; $GridPart.ReadOnly=$true; $GridPart.AutoSizeColumnsMode="Fill"
    $GridPart.Columns.Add("Disk", "Disk"); $GridPart.Columns.Add("Part", "Part"); $GridPart.Columns.Add("Letter", "Ky Tu"); $GridPart.Columns.Add("Label", "Nhan"); $GridPart.Columns.Add("Size", "Dung Luong")
    
    # Quét phân vùng (Get-Partition không dùng filter để hiện tất cả)
    $Parts = Get-Partition
    $SysDriveLetter = $env:SystemDrive.Replace(":", "")
    foreach ($P in $Parts) {
        $SizeGB = [Math]::Round($P.Size / 1GB, 1)
        $Let = if ($P.DriveLetter) { $P.DriveLetter } else { "N/A" } # Hiện N/A nếu không có ký tự
        $RowId = $GridPart.Rows.Add($P.DiskNumber, $P.PartitionNumber, $Let, $P.GptType, "$SizeGB GB")
        
        if ($P.DriveLetter -eq $SysDriveLetter) { 
            $GridPart.Rows[$RowId].Selected = $true 
            $GridPart.Rows[$RowId].DefaultCellStyle.BackColor = "LightGreen"
            $Global:SelectedDisk = $P.DiskNumber; $Global:SelectedPart = $P.PartitionNumber
        }
    }
    $GridPart.Add_CellClick({ $R = $GridPart.SelectedRows[0]; $Global:SelectedDisk = $R.Cells[0].Value; $Global:SelectedPart = $R.Cells[1].Value; $Global:SelectedLabel = $R.Cells[2].Value })
    $ConfForm.Controls.Add($GridPart)

    # 3. THÔNG TIN USER
    $LblU = New-Object System.Windows.Forms.Label; $LblU.Text = "3. THONG TIN TAI KHOAN:"; $LblU.Location = "20,350"; $LblU.AutoSize=$true; $LblU.ForeColor="Cyan"; $ConfForm.Controls.Add($LblU)
    function Add-In ($L, $X, $Y) { $Lb=New-Object System.Windows.Forms.Label; $Lb.Text=$L; $Lb.Location="$X,$Y"; $Lb.AutoSize=$true; $ConfForm.Controls.Add($Lb); $Tx=New-Object System.Windows.Forms.TextBox; $Tx.Location="$($X+80),$Y"; $Tx.Size="150,25"; $ConfForm.Controls.Add($Tx); return $Tx }
    $TxUser = Add-In "User:" 20 380; $TxUser.Text="Admin"
    $TxPass = Add-In "Pass:" 280 380
    $TxKey  = Add-In "Key:" 540 380

    # NÚT START
    $BtnGo = New-Object System.Windows.Forms.Button; $BtnGo.Text = "TAO BOOT & KHOI DONG LAI"; $BtnGo.Location = "20,450"; $BtnGo.Size = "740,50"; $BtnGo.BackColor = "LimeGreen"; $BtnGo.ForeColor = "Black"; $BtnGo.Font = "Segoe UI, 12, Bold"
    $BtnGo.Add_Click({
        $Idx = $CmbEd.SelectedItem.ToString().Split("-")[0].Trim()
        $Disk = $Global:SelectedDisk
        $Part = $Global:SelectedPart
        
        # XML
        $XMLPath = "$env:SystemDrive\autounattend.xml"
        try {
            (New-Object Net.WebClient).DownloadFile($XML_Url, $XMLPath)
            $Content = Get-Content $XMLPath -Raw
            $Content = $Content -replace "%USERNAME%", $TxUser.Text 
            $Content = $Content -replace "%COMPUTERNAME%", "PhatTan-PC"
            
            # FIX LỖI PASSWORD RỖNG
            if ([string]::IsNullOrWhiteSpace($TxPass.Text)) {
                 # Xóa block Password nếu rỗng để tránh lỗi OOBE
                 $Content = $Content -replace "(?s)<Password>.*?</Password>", ""
                 $Content = $Content -replace "%PASSWORD%", "" 
            } else {
                 $Content = $Content -replace "%PASSWORD%", $TxPass.Text
            }

            # FIX LỖI KEY RỖNG
            if ([string]::IsNullOrWhiteSpace($TxKey.Text)) { 
                $Content = $Content -replace "(?s)<ProductKey>.*?</ProductKey>", "" 
            } else { 
                $Content = $Content -replace "%PRODUCTKEY%", $TxKey.Text 
            }

            # PARTITION
            $Content = $Content -replace "%WIPEDISK%", "false"
            $Content = $Content -replace "%CREATEPARTITIONS%", ""
            $Content = $Content -replace "%INSTALLTO%", "<DiskID>$Disk</DiskID><PartitionID>$Part</PartitionID>"
            
            # INJECT IMAGE INDEX
            $ImgBlock = "<InstallFrom><MetaData wcm:action=`"add`"><Key>/IMAGE/INDEX</Key><Value>$Idx</Value></MetaData></InstallFrom>"
            $Content = $Content -replace "<InstallTo>", "$ImgBlock<InstallTo>"

            $Content | Set-Content $XMLPath
            
            # COPY
            $SysDrive = $env:SystemDrive
            $SrcWim = "$Drive\sources\boot.wim"; $SrcSdi = "$Drive\boot\boot.sdi"
            $TempDir = "C:\WinInstall_Temp"; New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
            Copy-Item $SrcWim "$TempDir\boot.wim" -Force; Copy-Item $SrcSdi "$TempDir\boot.sdi" -Force
            Move-Item "$TempDir\boot.wim" "$SysDrive\WinInstall_Boot.wim" -Force
            Move-Item "$TempDir\boot.sdi" "$SysDrive\boot.sdi" -Force
            Remove-Item $TempDir -Recurse -Force
            
            if (Create-Boot-Entry "\WinInstall_Boot.wim") {
                 if ([System.Windows.Forms.MessageBox]::Show("Da cau hinh xong! Restart ngay?", "Success", "YesNo") -eq "Yes") { Restart-Computer -Force }
            }
        } catch { [System.Windows.Forms.MessageBox]::Show("Loi: $($_.Exception.Message)", "Loi") }
    })
    $ConfForm.Controls.Add($BtnGo)
    $Form.Cursor = "Default"; $ConfForm.ShowDialog()
}

# --- AUTO SCAN ---
$Form.Add_Shown({ $ScanPaths = @("$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop", "D:", "E:"); foreach ($P in $ScanPaths) { if (Test-Path $P) { Get-ChildItem $P -Filter "*.iso" -Recurse -Depth 1 | Where {$_.Length -gt 500MB} | ForEach { $CmbISO.Items.Add($_.FullName) } } }; if ($CmbISO.Items.Count -gt 0) { $CmbISO.SelectedIndex = 0 } })

$Form.ShowDialog() | Out-Null
