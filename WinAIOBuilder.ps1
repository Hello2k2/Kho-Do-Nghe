# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WINDOWS AIO BUILDER - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(900, 600)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "TAO BO CAI WINDOWS AIO (ALL-IN-ONE)"; $LblT.Font = "Impact, 18"; $LblT.ForeColor="Cyan"; $LblT.AutoSize=$true; $LblT.Location="20,15"; $Form.Controls.Add($LblT)

# LIST ISO
$GbIso = New-Object System.Windows.Forms.GroupBox; $GbIso.Text = "1. Them File ISO Nguon"; $GbIso.Location="20,60"; $GbIso.Size="845,80"; $GbIso.ForeColor="Yellow"; $Form.Controls.Add($GbIso)
$TxtIsoList = New-Object System.Windows.Forms.TextBox; $TxtIsoList.Location="20,30"; $TxtIsoList.Size="650,30"; $TxtIsoList.ReadOnly=$true; $GbIso.Controls.Add($TxtIsoList)
$BtnAdd = New-Object System.Windows.Forms.Button; $BtnAdd.Text="THEM ISO..."; $BtnAdd.Location="690,28"; $BtnAdd.Size="130,30"; $BtnAdd.BackColor="DimGray"; $BtnAdd.ForeColor="White"
$GbIso.Controls.Add($BtnAdd)

# DATA GRID
$Grid = New-Object System.Windows.Forms.DataGridView; $Grid.Location="20,160"; $Grid.Size="845,300"; $Grid.BackgroundColor="Black"; $Grid.ForeColor="Black"; $Grid.AllowUserToAddRows=$false; $Grid.RowHeadersVisible=$false; $Grid.SelectionMode="FullRowSelect"; $Grid.AutoSizeColumnsMode="Fill"
$ColChk = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn; $ColChk.Name="Select"; $ColChk.HeaderText="[X]"; $ColChk.Width=40; $Grid.Columns.Add($ColChk) | Out-Null
$Grid.Columns.Add("ISO", "File ISO Nguon"); $Grid.Columns.Add("Index", "Index"); $Grid.Columns.Add("Name", "Ten Phien Ban (Edition)"); $Grid.Columns.Add("Size", "Dung Luong"); $Grid.Columns.Add("Arch", "Kien Truc")
$Grid.Columns[1].Width=50; $Grid.Columns[3].Width=80; $Grid.Columns[4].Width=60
$Form.Controls.Add($Grid)

# OUTPUT
$GbOut = New-Object System.Windows.Forms.GroupBox; $GbOut.Text = "2. Noi Luu File AIO (install.wim)"; $GbOut.Location="20,480"; $GbOut.Size="550,70"; $GbOut.ForeColor="Lime"; $Form.Controls.Add($GbOut)
$TxtOut = New-Object System.Windows.Forms.TextBox; $TxtOut.Location="20,25"; $TxtOut.Size="400,25"; $TxtOut.Text="D:\AIO_Output"; $GbOut.Controls.Add($TxtOut)
$BtnBrowseOut = New-Object System.Windows.Forms.Button; $BtnBrowseOut.Text="CHON..."; $BtnBrowseOut.Location="440,23"; $BtnBrowseOut.Size="90,27"; $BtnBrowseOut.BackColor="Gray"; $BtnBrowseOut.ForeColor="White"; $GbOut.Controls.Add($BtnBrowseOut)

# ACTION BUTTONS
$BtnBuild = New-Object System.Windows.Forms.Button; $BtnBuild.Text="BUILD AIO NOW"; $BtnBuild.Location="590,490"; $BtnBuild.Size="275,60"; $BtnBuild.BackColor="Green"; $BtnBuild.ForeColor="White"; $BtnBuild.Font="Segoe UI, 14, Bold"
$Form.Controls.Add($BtnBuild)

# --- LOGIC ---
$Global:MountedISOs = @()

function Mount-And-Scan ($IsoPath) {
    try {
        $Form.Cursor = "WaitCursor"
        Mount-DiskImage -ImagePath $IsoPath -StorageType ISO -ErrorAction Stop | Out-Null
        $Vol = Get-DiskImage -ImagePath $IsoPath | Get-Volume
        if ($Vol) {
            $Drv = "$($Vol.DriveLetter):"
            $Wim = "$Drv\sources\install.wim"; if (!(Test-Path $Wim)) { $Wim = "$Drv\sources\install.esd" }
            
            if (Test-Path $Wim) {
                $Global:MountedISOs += $IsoPath
                $Info = Get-WindowsImage -ImagePath $Wim
                foreach ($I in $Info) {
                    $SizeGB = [Math]::Round($I.Size / 1GB, 2)
                    $Grid.Rows.Add($true, $IsoPath, $I.ImageIndex, $I.ImageName, "$SizeGB GB", $I.Architecture) | Out-Null
                }
            }
        }
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi Mount ISO: $IsoPath", "Error") }
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

$BtnBuild.Add_Click({
    $OutDir = $TxtOut.Text; if (!$OutDir) { return }
    if (!(Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }
    $OutWim = "$OutDir\install.wim"
    
    # Kiem tra chon
    $Tasks = @(); foreach ($Row in $Grid.Rows) { if ($Row.Cells[0].Value -eq $true) { $Tasks += $Row } }
    if ($Tasks.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Chua chon phien ban nao!", "Loi"); return }

    $BtnBuild.Enabled=$false; $BtnBuild.Text="DANG XU LY..."
    
    # 1. BAT DAU EXPORT
    try {
        $Count = 1
        foreach ($Task in $Tasks) {
            $Iso = $Task.Cells[1].Value
            $Idx = $Task.Cells[2].Value
            $Name = $Task.Cells[3].Value
            
            $Vol = Get-DiskImage -ImagePath $Iso | Get-Volume
            $Drv = "$($Vol.DriveLetter):"
            $SrcWim = "$Drv\sources\install.wim"; if (!(Test-Path $SrcWim)) { $SrcWim = "$Drv\sources\install.esd" }
            
            $BtnBuild.Text = "Exporting ($Count/$($Tasks.Count)): $Name..."
            [System.Windows.Forms.Application]::DoEvents()
            
            # Lenh Export (Gop vao file WIM dich)
            Export-WindowsImage -SourceImagePath $SrcWim -SourceIndex $Idx -DestinationImagePath $OutWim -DestinationName "$Name (AIO)" -CompressionType Maximum -ErrorAction Stop
            
            $Count++
        }
        
        # 2. TAO SCRIPT CMD CAI DAT
        $CmdContent = @"
@echo off
title PHAT TAN PC - WINDOWS AIO INSTALLER
color 1f
cls
echo ==========================================================
echo        DANH SACH CAC PHIEN BAN WINDOWS TRONG BO CAI
echo ==========================================================
dism /Get-ImageInfo /ImageFile:"%~dp0install.wim"
echo.
echo ==========================================================
set /p idx=">>> NHAP SO THU TU (INDEX) BAN MUON CAI: "
echo.
echo [!] CANH BAO: O C: SE BI FORMAT.
echo [!] DANG TIEN HANH CAI DAT INDEX %idx% ...
echo.
format C: /q /y /fs:ntfs
dism /Apply-Image /ImageFile:"%~dp0install.wim" /Index:%idx% /ApplyDir:C:\
echo.
echo [!] DANG NAP BOOT (UEFI/LEGACY)...
bcdboot C:\Windows /s C:
echo.
echo [OK] DA CAI XONG. RUT USB VA KHOI DONG LAI!
pause
wpeutil reboot
"@
        [IO.File]::WriteAllText("$OutDir\AIO_Installer.cmd", $CmdContent)

        [System.Windows.Forms.MessageBox]::Show("DA TAO THANH CONG!`nFile luu tai: $OutDir`n`nCopy toan bo thu muc nay vao USB cuu ho roi chay file .cmd de cai.", "Success")
        Invoke-Item $OutDir
        
    } catch {
        [System.Windows.Forms.MessageBox]::Show("LOI: $($_.Exception.Message)", "Error")
    }
    
    # Clean up
    foreach ($Iso in $Global:MountedISOs) { Dismount-DiskImage -ImagePath $Iso -ErrorAction SilentlyContinue | Out-Null }
    $BtnBuild.Text = "BUILD AIO NOW"; $BtnBuild.Enabled=$true
})

$Form.FormClosing.Add_Method({ foreach ($Iso in $Global:MountedISOs) { Dismount-DiskImage -ImagePath $Iso -ErrorAction SilentlyContinue | Out-Null } })
$Form.ShowDialog() | Out-Null
