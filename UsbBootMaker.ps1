<#
    USB BOOT MAKER - PHAT TAN PC (HANDMADE PRO EDITION)
    Features: 
    - Auto Dual-Partition (UEFI/Legacy Hybrid)
    - Support GLIM/Grub2/WinPE Boot Kits
    - Safe DiskPart Wrapper
    - NO Hardcoded Drive Letters (Auto Detect)
    - NO Hardcoded GUI Coordinates (Responsive Dock Layout)
    - Dark Titanium UI
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

# --- CẤU HÌNH ---
$Global:LocalJson = "https://github.com/Hello2k2/Kho-Do-Nghe/blob/main/bootkits.json"
$Global:TempDir = "$env:TEMP\UsbBootMaker"
if (!(Test-Path $Global:TempDir)) { New-Item -ItemType Directory -Path $Global:TempDir -Force | Out-Null }

# --- THEME CONFIG (DARK TITANIUM) ---
$Theme = @{
    BgForm   = [System.Drawing.Color]::FromArgb(18, 18, 22)
    BgPanel  = [System.Drawing.Color]::FromArgb(32, 32, 38)
    TextMain = [System.Drawing.Color]::FromArgb(245, 245, 245)
    Accent   = [System.Drawing.Color]::FromArgb(0, 255, 255) # Cyan
    Warn     = [System.Drawing.Color]::FromArgb(255, 50, 80)  # Red
    Success  = [System.Drawing.Color]::FromArgb(50, 205, 50) # Green
    Border   = [System.Drawing.Color]::FromArgb(80, 80, 100)
}

# --- HELPER FUNCTIONS ---
function Log-Msg ($Msg) { 
    $TxtLog.Text += "[$(Get-Date -F 'HH:mm:ss')] $Msg`r`n"
    $TxtLog.SelectionStart = $TxtLog.Text.Length; $TxtLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function Run-DiskPartScript ($ScriptContent) {
    $F = "$Global:TempDir\dp_script.txt"
    [IO.File]::WriteAllText($F, $ScriptContent)
    $P = Start-Process "diskpart" "/s `"$F`"" -Wait -NoNewWindow -PassThru
    return $P.ExitCode
}

function Get-DriveLetterByLabel ($Label) {
    try {
        Get-Disk | Update-Disk -ErrorAction SilentlyContinue
        $Vol = Get-Volume | Where-Object { $_.FileSystemLabel -eq $Label } | Select-Object -First 1
        if ($Vol -and $Vol.DriveLetter) { return "$($Vol.DriveLetter):" }
    } catch {}
    return $null
}

# --- GUI INIT (RESPONSIVE LAYOUT) ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "USB BOOT MAKER PRO - GLIM EDITION"
$Form.Size = New-Object System.Drawing.Size(800, 650)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.BgForm
$Form.ForeColor = $Theme.TextMain
$Form.Padding = New-Object System.Windows.Forms.Padding(20) # Canh le toan bo form

# Fonts
$F_Head = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$F_Norm = New-Object System.Drawing.Font("Segoe UI", 10)
$F_Code = New-Object System.Drawing.Font("Consolas", 9)

# --- 1. BOTTOM PANEL (START BUTTON) ---
# Xep duoi cung (Dock Bottom)
$PnlBottom = New-Object System.Windows.Forms.Panel
$PnlBottom.Height = 80
$PnlBottom.Dock = "Bottom"
$PnlBottom.Padding = New-Object System.Windows.Forms.Padding(100, 20, 100, 10) # Canh giua nut
$Form.Controls.Add($PnlBottom)

$BtnStart = New-Object System.Windows.Forms.Button
$BtnStart.Text = "🚀 KHOI TAO USB BOOT NGAY"
$BtnStart.Dock = "Fill"
$BtnStart.Font = $F_Head
$BtnStart.BackColor = $Theme.Warn
$BtnStart.ForeColor = "White"
$BtnStart.FlatStyle = "Flat"
$PnlBottom.Controls.Add($BtnStart)

# --- 2. HEADER PANEL ---
# Xep tren cung (Dock Top)
$PnlHead = New-Object System.Windows.Forms.Panel
$PnlHead.Height = 70
$PnlHead.Dock = "Top"
$Form.Controls.Add($PnlHead)

$LblSub = New-Object System.Windows.Forms.Label
$LblSub.Text = "Auto Dual-Partition (UEFI/Legacy Hybrid) - Auto Detect Letter"
$LblSub.Dock = "Top"
$LblSub.Height = 25
$LblSub.Font = $F_Norm
$LblSub.ForeColor = "Gray"
$PnlHead.Controls.Add($LblSub)

$LblTitle = New-Object System.Windows.Forms.Label
$LblTitle.Text = "⚡ USB BOOT CREATOR (GLIM MULTIBOOT)"
$LblTitle.Dock = "Top"
$LblTitle.Height = 35
$LblTitle.Font = $F_Head
$LblTitle.ForeColor = $Theme.Accent
$PnlHead.Controls.Add($LblTitle)

# --- 3. USB GROUP ---
# Xep tiep theo sau Header
$GbUSB = New-Object System.Windows.Forms.GroupBox
$GbUSB.Text = "1. CHON THIET BI USB (CANH BAO: SE XOA SACH DU LIEU!)"
$GbUSB.Height = 80
$GbUSB.Dock = "Top"
$GbUSB.ForeColor = $Theme.Warn
# Padding (L, T, R, B) de tranh de len chu GroupBox
$GbUSB.Padding = New-Object System.Windows.Forms.Padding(10, 30, 10, 15)
$Form.Controls.Add($GbUSB)

$BtnRefresh = New-Object System.Windows.Forms.Button
$BtnRefresh.Text = "🔄 LAM MOI"
$BtnRefresh.Width = 120
$BtnRefresh.Dock = "Right"
$BtnRefresh.BackColor = $Theme.BgPanel
$BtnRefresh.ForeColor = "White"
$GbUSB.Controls.Add($BtnRefresh)

# Panel dem de tach nut va combo
$PnlSep1 = New-Object System.Windows.Forms.Panel; $PnlSep1.Width=10; $PnlSep1.Dock="Right"; $GbUSB.Controls.Add($PnlSep1)

$CbUSB = New-Object System.Windows.Forms.ComboBox
$CbUSB.Dock = "Fill"
$CbUSB.Font = $F_Norm
$CbUSB.BackColor = $Theme.BgPanel
$CbUSB.ForeColor = "White"
$CbUSB.DropDownStyle = "DropDownList"
$GbUSB.Controls.Add($CbUSB)
$CbUSB.BringToFront() # Dam bao no hien len tren

# --- Spacer ---
$Spacer1 = New-Object System.Windows.Forms.Panel; $Spacer1.Height=20; $Spacer1.Dock="Top"; $Form.Controls.Add($Spacer1)

# --- 4. KIT GROUP ---
$GbKit = New-Object System.Windows.Forms.GroupBox
$GbKit.Text = "2. CHON PHIEN BAN BOOT (TU GITHUB RELEASE)"
$GbKit.Height = 80
$GbKit.Dock = "Top"
$GbKit.ForeColor = $Theme.Accent
$GbKit.Padding = New-Object System.Windows.Forms.Padding(10, 30, 10, 15)
$Form.Controls.Add($GbKit)

$CbKit = New-Object System.Windows.Forms.ComboBox
$CbKit.Dock = "Fill"
$CbKit.Font = $F_Norm
$CbKit.BackColor = $Theme.BgPanel
$CbKit.ForeColor = "White"
$CbKit.DropDownStyle = "DropDownList"
$GbKit.Controls.Add($CbKit)

# --- Spacer ---
$Spacer2 = New-Object System.Windows.Forms.Panel; $Spacer2.Height=20; $Spacer2.Dock="Top"; $Form.Controls.Add($Spacer2)

# --- 5. LOG (FILL REMAINING) ---
$TxtLog = New-Object System.Windows.Forms.TextBox
$TxtLog.Multiline = $true
$TxtLog.ScrollBars = "Vertical"
$TxtLog.Dock = "Fill"
$TxtLog.BackColor = "Black"
$TxtLog.ForeColor = "Lime"
$TxtLog.Font = $F_Code
$TxtLog.ReadOnly = $true
$Form.Controls.Add($TxtLog)

# --- THU TU Z-ORDER (QUAN TRONG DE DOCK DUNG) ---
# Trong WinForms, cai nao Add sau cung se duoc uu tien Dock truoc (tu ngoai vao trong) hoac Fill.
# De sap xep dung: Bottom -> Header -> USB -> Kit -> Log (Fill)
# Cach don gian nhat la BringToFront theo thu tu nguoc lai
$PnlBottom.BringToFront()
$PnlHead.BringToFront()
$GbUSB.BringToFront()
$Spacer1.BringToFront()
$GbKit.BringToFront()
$Spacer2.BringToFront()
$TxtLog.BringToFront()

# --- LOGIC ---
# (Giu nguyen logic xu ly nhu cu)

function Load-UsbList {
    $CbUSB.Items.Clear()
    try {
        $Disks = Get-Disk | Where-Object { $_.BusType -eq "USB" -or $_.MediaType -eq "Removable" }
        if ($Disks) {
            foreach ($D in $Disks) {
                $SizeGB = [Math]::Round($D.Size / 1GB, 1)
                $Name = if ($D.FriendlyName) { $D.FriendlyName } else { "Unknown Device" }
                $CbUSB.Items.Add("Disk $($D.Number): $Name ($SizeGB GB)")
            }
        } else {
            $CbUSB.Items.Add("Khong tim thay USB nao!")
        }
        if ($CbUSB.Items.Count -gt 0) { $CbUSB.SelectedIndex = 0 }
    } catch { Log-Msg "Loi lay danh sach USB: $($_.Exception.Message)" }
}

function Load-Kits {
    $CbKit.Items.Clear()
    if (Test-Path $Global:LocalJson) {
        try {
            $Json = Get-Content $Global:LocalJson -Raw | ConvertFrom-Json
            $Global:KitData = $Json
            foreach ($Item in $Json) { $CbKit.Items.Add($Item.Name) }
            if ($CbKit.Items.Count -gt 0) { $CbKit.SelectedIndex = 0 }
            Log-Msg "Da tai danh sach Boot Kit tu file JSON."
        } catch { Log-Msg "Loi doc file JSON: $($_.Exception.Message)" }
    } else {
        Log-Msg "Khong tim thay bootkits.json!"; $CbKit.Items.Add("Demo Mode")
    }
}

function Download-File ($Url, $Dest) {
    Log-Msg "Dang tai xuong tu: $Url"; Log-Msg "Vui long cho..."
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        $Wc = New-Object System.Net.WebClient
        $Wc.DownloadFile($Url, $Dest)
        return $true
    } catch { Log-Msg "LOI TAI FILE: $($_.Exception.Message)"; return $false }
}

$BtnStart.Add_Click({
    if ($CbUSB.SelectedItem -match "Disk (\d+)") { $DiskID = $Matches[1] } 
    else { [System.Windows.Forms.MessageBox]::Show("Chon USB truoc!", "Loi"); return }

    $SelKitName = $CbKit.SelectedItem
    $KitObj = $Global:KitData | Where-Object { $_.Name -eq $SelKitName } | Select-Object -First 1
    if (!$KitObj) { [System.Windows.Forms.MessageBox]::Show("Chon Boot Kit!", "Loi"); return }

    if ([System.Windows.Forms.MessageBox]::Show("CANH BAO: XOA SACH DISK $DiskID?`n`nTiep tuc?", "Warning", "YesNo", "Warning") -ne "Yes") { return }

    $BtnStart.Enabled = $false; $Form.Cursor = "WaitCursor"
    
    # 1. Download
    $ZipPath = "$Global:TempDir\$($KitObj.FileName)"
    if (!(Test-Path $ZipPath)) {
        if (!(Download-File $KitObj.Url $ZipPath)) { $BtnStart.Enabled=$true; $Form.Cursor="Default"; return }
    }

    # 2. DiskPart (Auto Letter)
    Log-Msg "Dang phan vung (DiskPart)..."
    $Cmd = "select disk $DiskID`nclean`ncreate partition primary size=4096`nformat fs=fat32 quick label=`"GLIM_BOOT`"`nactive`nassign`ncreate partition primary`nformat fs=ntfs quick label=`"GLIM_DATA`"`nassign`nexit"
    Run-DiskPartScript $Cmd
    
    Log-Msg "Doi Windows nhan o dia (5s)..."; Start-Sleep -Seconds 5
    
    $BootDrv = Get-DriveLetterByLabel "GLIM_BOOT"
    $DataDrv = Get-DriveLetterByLabel "GLIM_DATA"
    if (!$BootDrv) { Log-Msg "LOI: Khong tim thay phan vung BOOT!"; $BtnStart.Enabled=$true; $Form.Cursor="Default"; return }
    Log-Msg "Boot: $BootDrv | Data: $DataDrv"

    # 3. Extract
    Log-Msg "Dang giai nen vao $BootDrv..."
    try {
        Get-ChildItem "$BootDrv\" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Expand-Archive -Path $ZipPath -DestinationPath "$BootDrv\" -Force
        Log-Msg "Giai nen hoan tat."
    } catch { Log-Msg "LOI GIAI NEN: $($_.Exception.Message)"; $BtnStart.Enabled=$true; $Form.Cursor="Default"; return }

    Log-Msg "=== XONG! ==="; Log-Msg "GLIM_DATA ($DataDrv): Chep ISO vao day."
    [System.Windows.Forms.MessageBox]::Show("Thanh Cong!", "Success")
    $BtnStart.Enabled=$true; $Form.Cursor="Default"
    if ($DataDrv) { Invoke-Item "$DataDrv\" }
})

$BtnRefresh.Add_Click({ Load-UsbList; Load-Kits })

$Form.Add_Load({ Load-UsbList; Load-Kits; Log-Msg "Ready. Responsive Mode." })
[System.Windows.Forms.Application]::Run($Form)
