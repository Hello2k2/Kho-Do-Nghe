# --- CORE INSTALLER MODULE ---
Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing
$WinToHDD_Url = "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/WinToHDD.exe"

# --- HAM MOUNT ---
function Mount-ISO ($IsoPath) {
    Dismount-DiskImage -ImagePath $IsoPath -ErrorAction SilentlyContinue
    try { Mount-DiskImage -ImagePath $IsoPath -StorageType ISO -ErrorAction Stop; Start-Sleep -Seconds 2 } catch { return $null }
    
    # Get Drive Letter
    $Drives = Get-PSDrive -PSProvider FileSystem
    foreach ($D in $Drives) {
        $R = $D.Root
        if ($R -in "C:\", "A:\", "B:\") { continue }
        if ((Test-Path "$R\setup.exe") -and (Test-Path "$R\bootmgr")) { return [string]$R.TrimEnd("\") }
    }
    return $null
}

# --- HAM BOOT ---
function Create-BCD ($WimPath) {
    $Drive = $env:SystemDrive
    cmd /c "bcdedit /create {ramdiskoptions} /d `"Ramdisk Options`"" 2>$null
    cmd /c "bcdedit /set {ramdiskoptions} ramdisksdidevice partition=$Drive"
    cmd /c "bcdedit /set {ramdiskoptions} ramdisksdipath \boot.sdi"
    
    $ID = (cmd /c "bcdedit /create /d `"CAI WIN TAM THOI`" /application osloader" | Select-String '{.*}').Matches.Value
    if (!$ID) { return $false }
    
    cmd /c "bcdedit /set $ID device ramdisk=[$Drive]$WimPath,{ramdiskoptions}"
    cmd /c "bcdedit /set $ID osdevice ramdisk=[$Drive]$WimPath,{ramdiskoptions}"
    cmd /c "bcdedit /set $ID winpe yes"
    cmd /c "bcdedit /set $ID detecthal yes"
    
    if ((bcdedit /enum) -match "winload.efi") { cmd /c "bcdedit /set $ID path \windows\system32\boot\winload.efi" } 
    else { cmd /c "bcdedit /set $ID path \windows\system32\boot\winload.exe" }
    
    cmd /c "bcdedit /displayorder $ID /addlast"
    cmd /c "bcdedit /bootsequence $ID"
    return $true
}

# --- GUI ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "TIEN HANH CAI DAT (CORE)"; $Form.Size = "600, 450"; $Form.StartPosition = "CenterScreen"; $Form.BackColor="#1E1E1E"; $Form.ForeColor="White"

$Lbl = New-Object System.Windows.Forms.Label; $Lbl.Text = "CHON FILE ISO:"; $Lbl.Location="20,20"; $Lbl.AutoSize=$true; $Form.Controls.Add($Lbl)
$CmbISO = New-Object System.Windows.Forms.ComboBox; $CmbISO.Location="20,50"; $CmbISO.Size="430,30"; $Form.Controls.Add($CmbISO)
$BtnTim = New-Object System.Windows.Forms.Button; $BtnTim.Text="TIM"; $BtnTim.Location="460,49"; $BtnTim.Size="100,25"; $BtnTim.Add_Click({ $O = New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="ISO|*.iso"; if($O.ShowDialog() -eq "OK"){$CmbISO.Items.Insert(0,$O.FileName);$CmbISO.SelectedIndex=0} }); $Form.Controls.Add($BtnTim)

# Auto Scan
$Paths = @("$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop", "D:", "E:")
foreach ($P in $Paths) { if(Test-Path $P){ Get-ChildItem $P -Filter "*.iso" -Recurse -Depth 1 | Where {$_.Length -gt 500MB} | ForEach {$CmbISO.Items.Add($_.FullName)} } }
if($CmbISO.Items.Count -gt 0){ $CmbISO.SelectedIndex=0 }

# ACTION BUTTONS
$BtnDirect = New-Object System.Windows.Forms.Button; $BtnDirect.Text = "1. CAI DE (Chay Setup.exe)"; $BtnDirect.Location="20,120"; $BtnDirect.Size="540,50"; $BtnDirect.BackColor="LimeGreen"; $BtnDirect.ForeColor="Black"
$BtnDirect.Add_Click({ 
    $ISO=$CmbISO.SelectedItem; if(!$ISO){return}
    $Drv=Mount-ISO $ISO; if($Drv){ Start-Process "$Drv\setup.exe"; $Form.Close() } else { [System.Windows.Forms.MessageBox]::Show("Loi Mount!", "Error") }
}); $Form.Controls.Add($BtnDirect)

$BtnBoot = New-Object System.Windows.Forms.Button; $BtnBoot.Text = "2. TAO BOOT TAM (Restart & Cai)"; $BtnBoot.Location="20,190"; $BtnBoot.Size="540,50"; $BtnBoot.BackColor="Magenta"; $BtnBoot.ForeColor="White"
$BtnBoot.Add_Click({
    $ISO=$CmbISO.SelectedItem; if(!$ISO){return}
    
    $Drv=Mount-ISO $ISO
    if(!$Drv) { [System.Windows.Forms.MessageBox]::Show("Loi Mount ISO!", "Error"); return }
    
    $SysDrive = $env:SystemDrive
    $Form.Text = "DANG COPY FILE (VUI LONG DOI)..."
    
    # --- FIX COPY LỖI (CHECK SIZE) ---
    $SrcWim = "$Drv\sources\boot.wim"; $DstWim = "$SysDrive\WinInstall_Boot.wim"
    $SrcSdi = "$Drv\boot\boot.sdi";    $DstSdi = "$SysDrive\boot.sdi"
    
    # Copy Force
    Copy-Item $SrcWim $DstWim -Force; Copy-Item $SrcSdi $DstSdi -Force
    
    # VERIFY SIZE (CHỐT CHẶN CUỐI CÙNG)
    $WimSize = (Get-Item $DstWim).Length / 1MB
    if ($WimSize -lt 100) {
        [System.Windows.Forms.MessageBox]::Show("LOI NGHIEIM TRONG: File boot.wim copy bi loi (Size: $WimSize MB).`nKhong the tao Boot Tam. Vui long dung WinToHDD!", "Loi Copy")
        return
    }
    
    if (Create-BCD "\WinInstall_Boot.wim") {
        if ([System.Windows.Forms.MessageBox]::Show("Da tao Boot xong! Restart ngay?", "Thanh Cong", "YesNo") -eq "Yes") { Restart-Computer -Force }
    }
}); $Form.Controls.Add($BtnBoot)

$BtnWTH = New-Object System.Windows.Forms.Button; $BtnWTH.Text = "3. DUNG WINTOHDD (Portable)"; $BtnWTH.Location="20,260"; $BtnWTH.Size="540,50"; $BtnWTH.BackColor="Orange"; $BtnWTH.ForeColor="Black"
$BtnWTH.Add_Click({ 
    $P="$env:TEMP\WinToHDD.exe"; if(!(Test-Path $P)){(New-Object Net.WebClient).DownloadFile($WinToHDD_Url, $P)}; Start-Process $P
}); $Form.Controls.Add($BtnWTH)

$Form.ShowDialog() | Out-Null
