# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- CONFIG ---
$WorkDir = "D:\PhatTan_WinModder" # Thu muc lam viec (Nen de o D/E cho rong)
$ToolsDir = "$env:TEMP\PhatTan_Tools"
if (!(Test-Path $ToolsDir)) { New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null }

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WINDOWS MODDER STUDIO - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(900, 650)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "WINDOWS MODDER & REBUILDER"; $LblT.Font = "Impact, 20"; $LblT.ForeColor="Gold"; $LblT.AutoSize=$true; $LblT.Location="20,15"; $Form.Controls.Add($LblT)

# TABS
$Tabs = New-Object System.Windows.Forms.TabControl; $Tabs.Location="20,70"; $Tabs.Size="845,520"; $Form.Controls.Add($Tabs)
function Make-Tab ($T) { $P=New-Object System.Windows.Forms.TabPage; $P.Text=$T; $P.BackColor=[System.Drawing.Color]::FromArgb(40,40,40); $Tabs.Controls.Add($P); return $P }

$TabCap = Make-Tab "1. TAO ISO TU O CUNG (CAPTURE)"
$TabMod = Make-Tab "2. CHINH SUA FILE ISO (MODDING)"

# =========================================================================================
# TAB 1: CAPTURE (TẠO ISO TỪ MÁY ĐANG CHẠY)
# =========================================================================================
$GbCap = New-Object System.Windows.Forms.GroupBox; $GbCap.Text="SAO CHEP HE DIEU HANH HIEN TAI (C:)"; $GbCap.Location="20,30"; $GbCap.Size="800,400"; $GbCap.ForeColor="Cyan"; $TabCap.Controls.Add($GbCap)

$LblC1 = New-Object System.Windows.Forms.Label; $LblC1.Text="Chuc nang nay se chup anh toan bo o C: (Windows + Phan mem da cai)`nva dong goi thanh file ISO co the cai dat duoc."; $LblC1.Location="30,40"; $LblC1.AutoSize=$true; $LblC1.ForeColor="White"; $GbCap.Controls.Add($LblC1)

$LblC2 = New-Object System.Windows.Forms.Label; $LblC2.Text="Chon o dia luu file ISO (Khong duoc la o C):"; $LblC2.Location="30,100"; $LblC2.AutoSize=$true; $GbCap.Controls.Add($LblC2)
$TxtCapOut = New-Object System.Windows.Forms.TextBox; $TxtCapOut.Location="30,125"; $TxtCapOut.Size="550,25"; $TxtCapOut.Text="D:\MyWindowsBackup.iso"; $GbCap.Controls.Add($TxtCapOut)
$BtnCapBrowse = New-Object System.Windows.Forms.Button; $BtnCapBrowse.Text="CHON..."; $BtnCapBrowse.Location="600,123"; $BtnCapBrowse.Size="100,27"; $BtnCapBrowse.ForeColor="Black"; $GbCap.Controls.Add($BtnCapBrowse)

$BtnStartCap = New-Object System.Windows.Forms.Button; $BtnStartCap.Text="BAT DAU CAPTURE & TAO ISO"; $BtnStartCap.Location="30,180"; $BtnStartCap.Size="670,60"; $BtnStartCap.BackColor="OrangeRed"; $BtnStartCap.ForeColor="White"; $BtnStartCap.Font="Segoe UI, 12, Bold"; $GbCap.Controls.Add($BtnStartCap)

$TxtLogCap = New-Object System.Windows.Forms.TextBox; $TxtLogCap.Multiline=$true; $TxtLogCap.Location="30,260"; $TxtLogCap.Size="670,120"; $TxtLogCap.BackColor="Black"; $TxtLogCap.ForeColor="Lime"; $TxtLogCap.ReadOnly=$true; $GbCap.Controls.Add($TxtLogCap)

# =========================================================================================
# TAB 2: MODDING (CHỈNH SỬA ISO)
# =========================================================================================
# --- STEP 1: LOAD ISO ---
$GbStep1 = New-Object System.Windows.Forms.GroupBox; $GbStep1.Text="B1: CHON FILE ISO GOC"; $GbStep1.Location="20,20"; $GbStep1.Size="800,80"; $GbStep1.ForeColor="Yellow"; $TabMod.Controls.Add($GbStep1)
$TxtIsoSrc = New-Object System.Windows.Forms.TextBox; $TxtIsoSrc.Location="20,30"; $TxtIsoSrc.Size="600,25"; $GbStep1.Controls.Add($TxtIsoSrc)
$BtnIsoSrc = New-Object System.Windows.Forms.Button; $BtnIsoSrc.Text="MO FILE..."; $BtnIsoSrc.Location="640,28"; $BtnIsoSrc.Size="100,27"; $BtnIsoSrc.ForeColor="Black"; $GbStep1.Controls.Add($BtnIsoSrc)

# --- STEP 2: MODIFY ---
$GbStep2 = New-Object System.Windows.Forms.GroupBox; $GbStep2.Text="B2: CHINH SUA (NHET APP/DRIVER/DATA)"; $GbStep2.Location="20,110"; $GbStep2.Size="800,250"; $GbStep2.ForeColor="Lime"; $GbStep2.Enabled=$false; $TabMod.Controls.Add($GbStep2)

function Add-ModBtn ($T, $X, $Y, $Col, $Cmd) { $b=New-Object System.Windows.Forms.Button; $b.Text=$T; $b.Location="$X,$Y"; $b.Size="230,45"; $b.BackColor=$Col; $b.ForeColor="Black"; $b.FlatStyle="Flat"; $b.Add_Click($Cmd); $GbStep2.Controls.Add($b) }

Add-ModBtn "1. GIAI NEN & MOUNT" 20 30 "Cyan" { Start-Mount }
Add-ModBtn "2. THEM FOLDER APP/DATA" 20 90 "White" { Add-Folder }
Add-ModBtn "3. THEM DRIVER (FOLDER)" 280 90 "White" { Add-Driver }
Add-ModBtn "4. COPY FILE VAO DESKTOP" 540 90 "White" { Add-DesktopFile }

$LblMountInfo = New-Object System.Windows.Forms.Label; $LblMountInfo.Text="Trang thai: Chua Mount."; $LblMountInfo.Location="280,45"; $LblMountInfo.AutoSize=$true; $LblMountInfo.ForeColor="Gray"; $GbStep2.Controls.Add($LblMountInfo)

$TxtLogMod = New-Object System.Windows.Forms.TextBox; $TxtLogMod.Multiline=$true; $TxtLogMod.Location="20,150"; $TxtLogMod.Size="750,80"; $TxtLogMod.BackColor="Black"; $TxtLogMod.ForeColor="Cyan"; $TxtLogMod.ReadOnly=$true; $GbStep2.Controls.Add($TxtLogMod)

# --- STEP 3: BUILD ---
$BtnBuildIso = New-Object System.Windows.Forms.Button; $BtnBuildIso.Text="B3: DONG GOI LAI THANH ISO (REBUILD)"; $BtnBuildIso.Location="20,380"; $BtnBuildIso.Size="800,60"; $BtnBuildIso.BackColor="Green"; $BtnBuildIso.ForeColor="White"; $BtnBuildIso.Font="Segoe UI, 14, Bold"; $BtnBuildIso.Enabled=$false; $TabMod.Controls.Add($BtnBuildIso)

# =========================================================================================
# LOGIC & FUNCTIONS
# =========================================================================================
function Log ($Box, $Msg) { 
    $Box.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $Msg`r`n"); $Box.ScrollToCaret(); [System.Windows.Forms.Application]::DoEvents() 
}

# --- TOOL DOWNLOADER (OSCDIMG) ---
function Check-Tools {
    $Osc = "$ToolsDir\oscdimg.exe"
    if (!(Test-Path $Osc)) {
        if ([System.Windows.Forms.MessageBox]::Show("Thieu file ho tro tao ISO (oscdimg.exe).`nBan co muon tai ve ngay khong?", "Thieu Tool", "YesNo") -eq "Yes") {
            try {
                # Link du phong tu Github (File nho ~500KB)
                $Url = "https://github.com/momo5502/oscdimg/raw/master/oscdimg.exe"
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
                (New-Object System.Net.WebClient).DownloadFile($Url, $Osc)
                [System.Windows.Forms.MessageBox]::Show("Da tai xong Tool!", "Success")
            } catch { [System.Windows.Forms.MessageBox]::Show("Loi tai Tool: $($_.Exception.Message)", "Error"); return $false }
        } else { return $false }
    }
    return $true
}

# --- TAB 1 LOGIC: CAPTURE ---
$BtnCapBrowse.Add_Click({
    $S = New-Object System.Windows.Forms.SaveFileDialog; $S.Filter="ISO File|*.iso"; $S.FileName="MyBackup.iso"
    if($S.ShowDialog() -eq "OK"){$TxtCapOut.Text=$S.FileName}
})

$BtnStartCap.Add_Click({
    if (!(Check-Tools)) { return }
    $IsoPath = $TxtCapOut.Text
    $WimFile = "$WorkDir\Capture\install.wim"
    $IsoDir  = "$WorkDir\Capture\ISO_Root"
    
    if (Test-Path $WorkDir) { Remove-Item $WorkDir -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $IsoDir -Force | Out-Null
    
    $BtnStartCap.Enabled=$false; Log $TxtLogCap ">>> DANG BAT DAU CAPTURE O C: ..."
    
    # 1. Capture C: (Dung DISM)
    # Luu y: Capture Live OS co the bi loi file dang mo, nhung van dung duoc.
    try {
        Start-Process "dism" -ArgumentList "/Capture-Image /ImageFile:`"$WimFile`" /CaptureDir:C:\ /Name:`"My Windows Backup`" /Compress:max" -Wait -NoNewWindow
        Log $TxtLogCap " [OK] Da Capture xong C: -> install.wim"
    } catch { Log $TxtLogCap " [ERR] Loi Capture: $($_.Exception.Message)"; $BtnStartCap.Enabled=$true; return }
    
    # 2. Tao cau truc ISO (Can bo Boot)
    # De don gian, ta se lay bo boot tu 1 file ISO co san hoac tai bo Boot mau.
    # O day ta gia dinh nguoi dung se MOD tu 1 ISO co san o Tab 2 se tot hon.
    # Nhung de tool doc lap, ta se Copy file Boot tu chinh C:\Windows\Boot (Hoi phuc tap).
    # CACH TOT NHAT: Canh bao nguoi dung.
    Log $TxtLogCap " [!] Luu y: De tao ISO Boot duoc, ban can co bo file Boot (efisys.bin, etfsboot.com)."
    Log $TxtLogCap " [!] Tool nay se tao file WIM truoc. Ban nen dung Tab 2 de nhet WIM nay vao 1 ISO goc."
    
    [System.Windows.Forms.MessageBox]::Show("Da Capture xong file install.wim tai: $WimFile`n`nDe tao ISO Boot, hay sang Tab 2, chon 1 file ISO Windows goc bat ky, roi thay the file install.wim cua no bang file nay!", "Huong dan", "OK", "Information")
    Invoke-Item (Split-Path $WimFile)
    $BtnStartCap.Enabled=$true
})

# --- TAB 2 LOGIC: MODDING ---
$Global:MountDir = "$WorkDir\Mount"
$Global:ExtractDir = "$WorkDir\Extracted"

$BtnIsoSrc.Add_Click({
    $O = New-Object System.Windows.Forms.OpenFileDialog; $O.Filter="ISO File|*.iso"
    if($O.ShowDialog() -eq "OK"){$TxtIsoSrc.Text=$O.FileName; $GbStep2.Enabled=$true}
})

function Start-Mount {
    $Iso = $TxtIsoSrc.Text
    if (!(Test-Path $Iso)) { return }
    
    if (Test-Path $WorkDir) { Remove-Item $WorkDir -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $Global:ExtractDir -Force | Out-Null
    New-Item -ItemType Directory -Path $Global:MountDir -Force | Out-Null
    
    Log $TxtLogMod ">>> Dang Mount ISO..."
    Mount-DiskImage -ImagePath $Iso -StorageType ISO -ErrorAction SilentlyContinue | Out-Null
    $Vol = Get-DiskImage -ImagePath $Iso | Get-Volume
    $Drv = "$($Vol.DriveLetter):"
    
    Log $TxtLogMod ">>> Dang copy file ISO ra thu muc tam..."
    Copy-Item "$Drv\*" $Global:ExtractDir -Recurse -Force
    
    Log $TxtLogMod ">>> Dang Mount install.wim (Index 1)..."
    $Wim = "$Global:ExtractDir\sources\install.wim"
    if (!(Test-Path $Wim)) { 
        $Esd = "$Global:ExtractDir\sources\install.esd"
        if (Test-Path $Esd) { 
            Log $TxtLogMod " [!] Phat hien ESD. Dang chuyen doi sang WIM..."
            Start-Process "dism" -ArgumentList "/Export-Image /SourceImageFile:`"$Esd`" /SourceIndex:1 /DestinationImageFile:`"$Wim`" /Compress:max /CheckIntegrity" -Wait -NoNewWindow
            Remove-Item $Esd -Force
        } else {
             [System.Windows.Forms.MessageBox]::Show("Khong tim thay install.wim hoac install.esd!", "Loi"); return
        }
    }
    
    Start-Process "dism" -ArgumentList "/Mount-Image /ImageFile:`"$Wim`" /Index:1 /MountDir:`"$Global:MountDir`"" -Wait -NoNewWindow
    
    $LblMountInfo.Text = "MOUNTED: $Global:MountDir"
    $LblMountInfo.ForeColor = "Lime"
    $BtnBuildIso.Enabled = $true
    Log $TxtLogMod " [OK] Da Mount xong. Hay them File/Driver roi bam Rebuild."
}

function Add-Folder {
    $FBD = New-Object System.Windows.Forms.FolderBrowserDialog; $FBD.Description="Chon thu muc App/Data muon them vao o C cua ISO"
    if ($FBD.ShowDialog() -eq "OK") {
        $Src = $FBD.SelectedPath
        $Name = Split-Path $Src -Leaf
        $Dst = "$Global:MountDir\$Name" # Copy thang vao goc o C
        Copy-Item $Src $Dst -Recurse -Force
        Log $TxtLogMod " [OK] Da them folder: $Name vao goc o C."
    }
}

function Add-Driver {
    $FBD = New-Object System.Windows.Forms.FolderBrowserDialog; $FBD.Description="Chon thu muc chua Driver (.inf)"
    if ($FBD.ShowDialog() -eq "OK") {
        Log $TxtLogMod ">>> Dang Inject Driver..."
        Start-Process "dism" -ArgumentList "/Image:`"$Global:MountDir`" /Add-Driver /Driver:`"$($FBD.SelectedPath)`" /Recurse" -Wait -NoNewWindow
        Log $TxtLogMod " [OK] Inject Driver hoan tat."
    }
}

function Add-DesktopFile {
    $O = New-Object System.Windows.Forms.OpenFileDialog; $O.Title="Chon file muon de ngoai Desktop"
    if ($O.ShowDialog() -eq "OK") {
        $Dst = "$Global:MountDir\Users\Public\Desktop"
        Copy-Item $O.FileName $Dst -Force
        Log $TxtLogMod " [OK] Da them file vao Public Desktop."
    }
}

$BtnBuildIso.Add_Click({
    if (!(Check-Tools)) { return }
    $Save = New-Object System.Windows.Forms.SaveFileDialog; $Save.Filter="ISO File|*.iso"; $Save.FileName="Windows_Modded.iso"
    if ($Save.ShowDialog() -eq "OK") {
        $IsoOut = $Save.FileName
        $Osc = "$ToolsDir\oscdimg.exe"
        
        Log $TxtLogMod ">>> Dang Unmount va Commit WIM..."
        Start-Process "dism" -ArgumentList "/Unmount-Image /MountDir:`"$Global:MountDir`" /Commit" -Wait -NoNewWindow
        
        Log $TxtLogMod ">>> Dang dong goi ISO (OSCDIMG)..."
        # Lenh tao ISO UEFI/Legacy (Dual Boot)
        $BootData = "2#p0,e,b`"$Global:ExtractDir\boot\etfsboot.com`"#pEF,e,b`"$Global:ExtractDir\efi\microsoft\boot\efisys.bin`""
        
        $Proc = Start-Process $Osc -ArgumentList "-bootdata:$BootData -u2 -udfver102 `"$Global:ExtractDir`" `"$IsoOut`"" -Wait -NoNewWindow -PassThru
        
        if ($Proc.ExitCode -eq 0) {
            Log $TxtLogMod " [SUCCESS] ISO da duoc tao!"
            [System.Windows.Forms.MessageBox]::Show("THANH CONG!`nFile ISO: $IsoOut", "Phat Tan PC")
            Invoke-Item (Split-Path $IsoOut)
        } else {
            Log $TxtLogMod " [ERR] Loi tao ISO. Ma loi: $($Proc.ExitCode)"
            [System.Windows.Forms.MessageBox]::Show("Loi khi build ISO. Kiem tra lai file boot.", "Error")
        }
        
        # Cleanup
        Dismount-DiskImage -ImagePath $TxtIsoSrc.Text -ErrorAction SilentlyContinue | Out-Null
        $GbStep2.Enabled=$false; $BtnBuildIso.Enabled=$false
        $LblMountInfo.Text="Trang thai: Da xong."
    }
})

$Form.FormClosing.Add_Method({ 
    Dismount-DiskImage -ImagePath $TxtIsoSrc.Text -ErrorAction SilentlyContinue | Out-Null
    Start-Process "dism" -ArgumentList "/Unmount-Image /MountDir:`"$Global:MountDir`" /Discard" -Wait -NoNewWindow -ErrorAction SilentlyContinue
})

$Form.ShowDialog() | Out-Null
