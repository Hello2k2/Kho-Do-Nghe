<#
    SYSTEM INFO PRO MAX - PHAT TAN PC
    Version: 4.0 (MSInfo32 Replica)
#>

# --- 1. TU DONG YEU CAU QUYEN ADMIN (De doc thong tin sau) ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "HE THONG CHI TIET - PHAT TAN PC (MSINFO32 STYLE)"
$Form.Size = New-Object System.Drawing.Size(1000, 700)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# --- TAB CONTROL ---
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = "10,10"; $TabControl.Size = "965, 580"
$Form.Controls.Add($TabControl)

function Make-Tab ($Title) {
    $Page = New-Object System.Windows.Forms.TabPage; $Page.Text = $Title
    $Page.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48); $Page.ForeColor = "Black"
    $TabControl.Controls.Add($Page); return $Page
}

function Make-ListView ($Parent) {
    $LV = New-Object System.Windows.Forms.ListView
    $LV.Size = "955, 550"; $LV.Location = "5,5"; $LV.View = "Details"; $LV.GridLines = $true
    $LV.FullRowSelect = $true; $LV.BackColor = "Black"; $LV.ForeColor = "Lime"
    $LV.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $LV.Columns.Add("Ten Thuoc Tinh", 300); $LV.Columns.Add("Gia Tri", 600)
    $Parent.Controls.Add($LV); return $LV
}

function Make-Grid ($Parent) {
    $G = New-Object System.Windows.Forms.DataGridView
    $G.Size = "955, 550"; $G.Location = "5,5"; $G.BackgroundColor = "Black"; $G.ForeColor = "Black"
    $G.AllowUserToAddRows=$false; $G.RowHeadersVisible=$false; $G.AutoSizeColumnsMode="Fill"; $G.SelectionMode="FullRowSelect"; $G.ReadOnly=$true
    $Parent.Controls.Add($G); return $G
}

# --- TAB 1: SUMMARY (GIONG MSINFO32) ---
$TabSum = Make-Tab "Tom Tat He Thong"
$ListSum = Make-ListView $TabSum

# --- TAB 2: COMPONENTS (PHAN CUNG) ---
$TabHw = Make-Tab "Linh Kien (Hardware)"
$ListHw = Make-ListView $TabHw

# --- TAB 3: STORAGE (LUU TRU) ---
$TabDisk = Make-Tab "Luu Tru (Disk)"
$GridDisk = Make-Grid $TabDisk
$GridDisk.Columns.Add("Disk", "Disk #"); $GridDisk.Columns.Add("Model", "Ten O Cung"); $GridDisk.Columns.Add("Size", "Dung Luong"); $GridDisk.Columns.Add("Type", "Partition"); $GridDisk.Columns.Add("Status", "Trang Thai")

# --- TAB 4: DRIVERS ---
$TabDrv = Make-Tab "Drivers"
$GridDrv = Make-Grid $TabDrv
$GridDrv.Columns.Add("Device", "Ten Thiet Bi"); $GridDrv.Columns.Add("Manuf", "Hang SX"); $GridDrv.Columns.Add("Ver", "Phien Ban"); $GridDrv.Columns.Add("Date", "Ngay")

# --- LOGIC LAY THONG TIN (CORE) ---
function Add-Item ($ListView, $Name, $Value) {
    $Item = New-Object System.Windows.Forms.ListViewItem($Name)
    $Item.SubItems.Add($Value)
    $ListView.Items.Add($Item)
}

function Load-Summary {
    $ListSum.Items.Clear()
    
    # 1. OS INFO
    $OS = Get-CimInstance Win32_OperatingSystem
    Add-Item $ListSum "Ten He Dieu Hanh" $OS.Caption
    Add-Item $ListSum "Phien Ban" "$($OS.Version) (Build $($OS.BuildNumber))"
    Add-Item $ListSum "Nha San Xuat OS" $OS.Manufacturer
    Add-Item $ListSum "Ten May (System Name)" $OS.CSName
    
    # 2. SYSTEM INFO
    $CS = Get-CimInstance Win32_ComputerSystem
    $Bios = Get-CimInstance Win32_BIOS
    Add-Item $ListSum "Hang San Xuat May (System Manufacturer)" $CS.Manufacturer
    Add-Item $ListSum "Model May (System Model)" $CS.Model
    Add-Item $ListSum "Loai He Thong (System Type)" $CS.SystemType
    Add-Item $ListSum "Vi Xu Ly (Processor)" ((Get-CimInstance Win32_Processor).Name)
    
    # 3. BIOS/UEFI
    Add-Item $ListSum "Phien Ban BIOS" "$($Bios.SMBIOSBIOSVersion) ($($Bios.ReleaseDate))"
    
    # Check BIOS Mode (Legacy/UEFI)
    $BiosMode = "Legacy"
    try { 
        $SecureBootPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State"
        if (Test-Path $SecureBootPath) { $BiosMode = "UEFI" }
    } catch {}
    Add-Item $ListSum "Che Do BIOS (BIOS Mode)" $BiosMode
    
    # Check Secure Boot
    $SecureBoot = "Khong ho tro"
    if ($BiosMode -eq "UEFI") {
        try { 
            if ((Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State").UEFISecureBootEnabled -eq 1) { $SecureBoot = "Bat (On)" } else { $SecureBoot = "Tat (Off)" }
        } catch { $SecureBoot = "Chua ro" }
    }
    Add-Item $ListSum "Trang Thai Secure Boot" $SecureBoot
    
    # 4. MAINBOARD
    $Base = Get-WmiObject Win32_BaseBoard
    Add-Item $ListSum "Nha San Xuat Mainboard" $Base.Manufacturer
    Add-Item $ListSum "San Pham Mainboard (Product)" $Base.Product
    Add-Item $ListSum "Phien Ban Mainboard" $Base.Version

    # 5. MEMORY (RAM)
    $RamTotal = [Math]::Round($CS.TotalPhysicalMemory / 1GB, 2)
    $RamFree = [Math]::Round($OS.FreePhysicalMemory / 1024 / 1024, 2)
    Add-Item $ListSum "RAM Vat Ly (Installed RAM)" "$RamTotal GB"
    Add-Item $ListSum "RAM Kha Dung (Available RAM)" "$RamFree GB"
    
    # Virtual Memory
    $VirtualTotal = [Math]::Round($OS.TotalVirtualMemorySize / 1024 / 1024, 2)
    $VirtualFree = [Math]::Round($OS.FreeVirtualMemory / 1024 / 1024, 2)
    Add-Item $ListSum "Tong Bo Nho Ao (Total Virtual Memory)" "$VirtualTotal GB"
    Add-Item $ListSum "Bo Nho Ao Kha Dung" "$VirtualFree GB"
    Add-Item $ListSum "Page File Space" "$([Math]::Round(($OS.TotalVirtualMemorySize - $OS.TotalVisibleMemorySize) / 1024, 0)) MB"
    
    # 6. TIME ZONE & USER
    Add-Item $ListSum "Mui Gio (Time Zone)" (Get-TimeZone).StandardName
    Add-Item $ListSum "Nguoi Dung (User Name)" "$($env:USERDOMAIN)\$($env:USERNAME)"
    Add-Item $ListSum "Thu Muc Windows" $OS.WindowsDirectory
}

function Load-Hardware {
    $ListHw.Items.Clear()
    
    # GPU
    $GPUs = Get-CimInstance Win32_VideoController
    foreach ($G in $GPUs) {
        Add-Item $ListHw "[Hien Thi] Ten Card" $G.Name
        Add-Item $ListHw "[Hien Thi] Phien Ban Driver" $G.DriverVersion
        Add-Item $ListHw "[Hien Thi] Do Phan Giai" "$($G.CurrentHorizontalResolution) x $($G.CurrentVerticalResolution) @ $($G.CurrentRefreshRate)Hz"
        Add-Item $ListHw "---" "---"
    }
    
    # AUDIO
    $Audios = Get-CimInstance Win32_SoundDevice
    foreach ($A in $Audios) {
        Add-Item $ListHw "[Am Thanh] Thiet Bi" $A.Name
        Add-Item $ListHw "[Am Thanh] Trang Thai" $A.Status
    }
    Add-Item $ListHw "---" "---"
    
    # NETWORK
    $Nets = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled -eq $true}
    foreach ($N in $Nets) {
        Add-Item $ListHw "[Mang] Ten Card" $N.Description
        Add-Item $ListHw "[Mang] IP Address" $N.IPAddress[0]
        Add-Item $ListHw "[Mang] MAC Address" $N.MACAddress
        Add-Item $ListHw "---" "---"
    }
    
    # TPM
    try {
        $Tpm = Get-WmiObject -Namespace "Root\CIMv2\Security\MicrosoftTpm" -Class Win32_Tpm
        $TpmVer = if ($Tpm.SpecVersion) { $Tpm.SpecVersion } else { "Khong co / Bi tat" }
        Add-Item $ListHw "[Bao Mat] TPM Version" $TpmVer
    } catch { Add-Item $ListHw "[Bao Mat] TPM" "Khong tim thay" }
}

function Load-DiskAndDriver {
    $GridDisk.Rows.Clear(); $GridDrv.Rows.Clear()
    
    # DISK
    $Disks = Get-Disk
    foreach ($D in $Disks) {
        $Size = [Math]::Round($D.Size / 1GB, 1)
        $GridDisk.Rows.Add($D.Number, $D.Model, "$Size GB", $D.PartitionStyle, $D.HealthStatus) | Out-Null
    }

    # DRIVER
    $Drivers = Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -ne $null } | Select-Object DeviceName, Manufacturer, DriverVersion, DriverDate
    foreach ($D in $Drivers) {
        try { $Date = [DateTime]::ParseExact($D.DriverDate.Substring(0,8), "yyyyMMdd", $null).ToString("yyyy-MM-dd") } catch { $Date = "" }
        $GridDrv.Rows.Add($D.DeviceName, $D.Manufacturer, $D.DriverVersion, $Date) | Out-Null
    }
}

# --- BUTTONS ---
$BtnExport = New-Object System.Windows.Forms.Button; $BtnExport.Text="XUAT RA FILE TEXT (DESKTOP)"; $BtnExport.Location="20,600"; $BtnExport.Size="250,40"; $BtnExport.BackColor="Cyan"; $BtnExport.ForeColor="Black"
$BtnExport.Add_Click({
    $Path = "$env:USERPROFILE\Desktop\MayTinh_Report.txt"
    $Content = "--- BAO CAO HE THONG PHAT TAN PC ---`r`n`r`n"
    foreach ($Item in $ListSum.Items) { $Content += "$($Item.Text): $($Item.SubItems[1].Text)`r`n" }
    $Content += "`r`n--- PHAN CUNG ---`r`n"
    foreach ($Item in $ListHw.Items) { $Content += "$($Item.Text): $($Item.SubItems[1].Text)`r`n" }
    $Content | Out-File $Path
    [System.Windows.Forms.MessageBox]::Show("Da xuat file: $Path", "Thanh Cong")
    Invoke-Item $Path
})
$Form.Controls.Add($BtnExport)

$BtnRef = New-Object System.Windows.Forms.Button; $BtnRef.Text="LAM MOI"; $BtnRef.Location="280,600"; $BtnRef.Size="150,40"; $BtnRef.BackColor="Orange"; $BtnRef.ForeColor="Black"
$BtnRef.Add_Click({ Load-Summary; Load-Hardware; Load-DiskAndDriver })
$Form.Controls.Add($BtnRef)

# --- RUN ---
$Form.Add_Shown({ 
    $Form.Refresh()
    Load-Summary
    Load-Hardware
    Load-DiskAndDriver 
})
$Form.ShowDialog() | Out-Null
