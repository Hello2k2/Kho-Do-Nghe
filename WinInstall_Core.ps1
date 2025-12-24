<#
    WININSTALL CORE V4.5 (ULTIMATE ENGINE)
    Author: Phat Tan PC
    Hosted on: GitHub (Called by Launcher)
#>

# --- 1. FORCE ADMIN & SETUP ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CONFIG (LINK CHUẨN CỦA ÔNG) ---
$Global:WinToHDD_Url = "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/WinToHDD.exe"
$Global:SelectedDisk = $null
$Global:SelectedPart = $null
$Global:IsoMounted = $null

# --- THEME (Dark Mode đồng bộ với Launcher) ---
$Theme = @{
    Bg = [System.Drawing.Color]::FromArgb(30, 30, 35)
    Panel = [System.Drawing.Color]::FromArgb(45, 45, 50)
    Text = "White"
    Accent = "Cyan"
    Btn = "DimGray"
}

# --- GUI INIT ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "CORE INSTALLER V4.5 - PHAT TAN PC"
$Form.Size = "820, 680"
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Bg
$Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$LblTitle = New-Object System.Windows.Forms.Label
$LblTitle.Text = "⚡ WINDOWS DEPLOYMENT ENGINE V4.5"
$LblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$LblTitle.ForeColor = $Theme.Accent
$LblTitle.AutoSize = $true
$LblTitle.Location = "20, 15"
$Form.Controls.Add($LblTitle)

# Tabs
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = "20, 60"
$TabControl.Size = "765, 450"
$Form.Controls.Add($TabControl)

# === TAB 1: CÀI WIN (SETUP/DISM) ===
$TabInst = New-Object System.Windows.Forms.TabPage; $TabInst.Text = "  CHẾ ĐỘ CÀI ĐẶT (INSTALL)  "; $TabInst.BackColor = $Theme.Panel
$TabControl.Controls.Add($TabInst)

# 1. ISO
$GrpISO = New-Object System.Windows.Forms.GroupBox; $GrpISO.Text = "1. Chọn File ISO Windows"; $GrpISO.Location = "15,15"; $GrpISO.Size = "730, 80"; $GrpISO.ForeColor = "Gold"; $TabInst.Controls.Add($GrpISO)
$CbISO = New-Object System.Windows.Forms.ComboBox; $CbISO.Location = "20,30"; $CbISO.Size = "570,30"; $CbISO.DropDownStyle="DropDownList"; $GrpISO.Controls.Add($CbISO)
$BtnBrowse = New-Object System.Windows.Forms.Button; $BtnBrowse.Text = "📂 TÌM ISO"; $BtnBrowse.Location = "600,29"; $BtnBrowse.Size = "110,25"; $BtnBrowse.BackColor=$Theme.Btn; $GrpISO.Controls.Add($BtnBrowse)

# 2. Index
$GrpVer = New-Object System.Windows.Forms.GroupBox; $GrpVer.Text = "2. Chọn Phiên Bản (Index)"; $GrpVer.Location = "15,105"; $GrpVer.Size = "730, 70"; $GrpVer.ForeColor = "Lime"; $TabInst.Controls.Add($GrpVer)
$CbIndex = New-Object System.Windows.Forms.ComboBox; $CbIndex.Location = "20,30"; $CbIndex.Size = "690,30"; $CbIndex.DropDownStyle="DropDownList"; $GrpVer.Controls.Add($CbIndex)

# 3. Partition
$GrpDisk = New-Object System.Windows.Forms.GroupBox; $GrpDisk.Text = "3. Chọn Phân Vùng Cài (Ổ C)"; $GrpDisk.Location = "15,185"; $GrpDisk.Size = "730, 150"; $GrpDisk.ForeColor = "Cyan"; $TabInst.Controls.Add($GrpDisk)
$GridPart = New-Object System.Windows.Forms.DataGridView; $GridPart.Location = "20,25"; $GridPart.Size = "690,110"; $GridPart.BackgroundColor="Black"; $GridPart.ForeColor="Black"; $GridPart.AllowUserToAddRows=$false; $GridPart.RowHeadersVisible=$false; $GridPart.SelectionMode="FullRowSelect"; $GridPart.MultiSelect=$false; $GridPart.ReadOnly=$true; $GridPart.AutoSizeColumnsMode="Fill"
$GridPart.Columns.Add("Disk","Disk"); $GridPart.Columns.Add("Part","Part"); $GridPart.Columns.Add("Letter","Ký Tự"); $GridPart.Columns.Add("Size","Size"); $GridPart.Columns.Add("Label","Nhãn"); 
$GrpDisk.Controls.Add($GridPart)

# 4. Buttons (Mode 1 & 2)
$BtnMode1 = New-Object System.Windows.Forms.Button; $BtnMode1.Text = "MODE 1: SETUP.EXE (CHUẨN)"; $BtnMode1.Location = "15,350"; $BtnMode1.Size = "360,60"; $BtnMode1.BackColor = "DarkBlue"; $BtnMode1.ForeColor="White"; $BtnMode1.Font=New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold); $TabInst.Controls.Add($BtnMode1)
$BtnMode2 = New-Object System.Windows.Forms.Button; $BtnMode2.Text = "MODE 2: DISM (NHANH - ADVANCED)"; $BtnMode2.Location = "385,350"; $BtnMode2.Size = "360,60"; $BtnMode2.BackColor = "DarkRed"; $BtnMode2.ForeColor="White"; $BtnMode2.Font=New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold); $TabInst.Controls.Add($BtnMode2)

# === TAB 2: WINTOHDD (AUTO DOWNLOAD) ===
$TabWTH = New-Object System.Windows.Forms.TabPage; $TabWTH.Text = "  MODE 3: WINTOHDD (AUTO)  "; $TabWTH.BackColor = $Theme.Panel
$TabControl.Controls.Add($TabWTH)

$LblWTH = New-Object System.Windows.Forms.Label; $LblWTH.Text = "CÀI WIN KHÔNG CẦN USB"; $LblWTH.Font = New-Object System.Drawing.Font("Impact", 24); $LblWTH.ForeColor = "Orange"; $LblWTH.AutoSize = $true; $LblWTH.Location = "200, 100"; $TabWTH.Controls.Add($LblWTH)
$LblWTHSub = New-Object System.Windows.Forms.Label; $LblWTHSub.Text = "Tự động tải & chạy WinToHDD Portable từ Server."; $LblWTHSub.ForeColor = "Silver"; $LblWTHSub.AutoSize = $true; $LblWTHSub.Location = "230, 150"; $TabWTH.Controls.Add($LblWTHSub)

$BtnRunWTH = New-Object System.Windows.Forms.Button; $BtnRunWTH.Text = "🚀 TẢI VÀ CHẠY NGAY"; $BtnRunWTH.Location = "200, 200"; $BtnRunWTH.Size = "350, 70"; $BtnRunWTH.BackColor = "Orange"; $BtnRunWTH.ForeColor="Black"; $BtnRunWTH.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$TabWTH.Controls.Add($BtnRunWTH)

$PbDownload = New-Object System.Windows.Forms.ProgressBar; $PbDownload.Location = "100, 300"; $PbDownload.Size = "550, 25"; $PbDownload.Visible=$false; $TabWTH.Controls.Add($PbDownload)

# --- LOG BOX ---
$TxtLog = New-Object System.Windows.Forms.TextBox; $TxtLog.Location = "20, 520"; $TxtLog.Size = "765, 100"; $TxtLog.Multiline=$true; $TxtLog.BackColor="Black"; $TxtLog.ForeColor="Lime"; $TxtLog.ReadOnly=$true; $TxtLog.ScrollBars="Vertical"
$Form.Controls.Add($TxtLog)

# --- FUNCTIONS ---
function Log ($M) { $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm'))] $M`r`n"); $TxtLog.ScrollToCaret() }

function Load-Partitions {
    $GridPart.Rows.Clear(); $SysDrive = $env:SystemDrive.Replace(":","")
    try {
        $Parts = Get-Volume | Where-Object {$_.DriveType -eq 'Fixed'} | Sort-Object DriveLetter
        foreach ($P in $Parts) {
            $Dsk = (Get-Partition -DriveLetter $P.DriveLetter).DiskNumber
            $Prt = (Get-Partition -DriveLetter $P.DriveLetter).PartitionNumber
            $Info = if ($P.DriveLetter -eq $SysDrive) { " (Windows)" } else { "" }
            $GridPart.Rows.Add($Dsk, $Prt, $P.DriveLetter, "$([math]::Round($P.Size/1GB,1)) GB", "$($P.FileSystemLabel)$Info")
        }
    } catch { Log "Lỗi đọc phân vùng: $_" }
}

function Mount-ISO {
    $ISO = $CbISO.SelectedItem; if (!$ISO) { return }
    Log "Mounting: $ISO..."
    try {
        Dismount-DiskImage -ImagePath $ISO -ErrorAction SilentlyContinue | Out-Null
        $M = Mount-DiskImage -ImagePath $ISO -PassThru
        $Vol = $M | Get-Volume
        if ($Vol) {
            $Global:IsoMounted = "$($Vol.DriveLetter):"
            Log "-> Mounted: $($Global:IsoMounted)"
            Get-WimInfo
        } else { Log "Lỗi Mount: Không có ký tự ổ đĩa." }
    } catch { Log "Lỗi Mount: $_" }
}

function Get-WimInfo {
    $Drive = $Global:IsoMounted; if (!$Drive) { return }
    $Wim = "$Drive\sources\install.wim"; if (!(Test-Path $Wim)) { $Wim = "$Drive\sources\install.esd" }
    $CbIndex.Items.Clear()
    if (Test-Path $Wim) {
        $Info = dism /Get-WimInfo /WimFile:$Wim
        $Indexes = $Info | Select-String "Index :"; $Names = $Info | Select-String "Name :"
        for ($i=0; $i -lt $Indexes.Count; $i++) { 
            $Idx = $Indexes[$i].ToString().Split(":")[1].Trim()
            $Nam = $Names[$i].ToString().Split(":")[1].Trim()
            $CbIndex.Items.Add("$Idx - $Nam") 
        }
        if ($CbIndex.Items.Count -gt 0) { $CbIndex.SelectedIndex = 0 }
    }
}

# --- EVENT HANDLERS ---
$BtnBrowse.Add_Click({
    $OFD = New-Object System.Windows.Forms.OpenFileDialog; $OFD.Filter = "ISO|*.iso"
    if ($OFD.ShowDialog() -eq "OK") { $CbISO.Items.Insert(0, $OFD.FileName); $CbISO.SelectedIndex = 0; Mount-ISO }
})

$BtnMode1.Add_Click({
    if (!$Global:IsoMounted) { Log "Chưa Mount ISO!"; return }
    $Setup = "$($Global:IsoMounted)\setup.exe"
    if (Test-Path $Setup) { Start-Process $Setup; $Form.Close() } else { Log "Lỗi: Không thấy Setup.exe" }
})

$BtnMode2.Add_Click({
    [System.Windows.Forms.MessageBox]::Show("Mode 2 (DISM) yêu cầu kiến thức cao.`nKhuyên dùng Mode 3 (WinToHDD)!", "Khuyến Cáo")
})

# --- MODE 3: WINTOHDD ENGINE ---
$BtnRunWTH.Add_Click({
    $Dest = "$env:TEMP\WinToHDD.exe"
    if (!(Test-Path $Dest)) {
        Log "Đang tải WinToHDD từ GitHub..."
        $PbDownload.Visible = $true; $PbDownload.Style = "Marquee"
        $Form.Cursor = "WaitCursor"
        try {
            # Tải từ link Release chuẩn của ông
            Import-Module BitsTransfer
            Start-BitsTransfer -Source $Global:WinToHDD_Url -Destination $Dest -Priority Foreground
            Log "-> Tải xong."
        } catch {
            Log "Lỗi tải: $_"
            $Form.Cursor = "Default"; $PbDownload.Visible = $false; return
        }
        $Form.Cursor = "Default"; $PbDownload.Visible = $false
    }
    Log "Đang chạy WinToHDD..."; Start-Process $Dest; $Form.Close()
})

# --- STARTUP ---
Load-Partitions
$Scan = @("$env:USERPROFILE\Downloads", "D:", "E:"); foreach ($P in $Scan) { if(Test-Path $P){ Get-ChildItem $P -Filter "*.iso" -Recurse -Depth 1 | Where {$_.Length -gt 1GB} | ForEach { $CbISO.Items.Add($_.FullName) } } }
if ($CbISO.Items.Count -gt 0) { $CbISO.SelectedIndex = 0; Mount-ISO }

$Form.ShowDialog() | Out-Null
