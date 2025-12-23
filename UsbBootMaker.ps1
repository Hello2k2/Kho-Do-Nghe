<#
    USB BOOT MAKER - PHAT TAN PC (V4.2: FINAL FIX)
    Updates:
    - Fixed Function Name mismatch error
    - Optimized DiskPart steps for VirtualBox
    - Auto-detect BootICE or download from GitHub
#>

# 1. SETUP
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

# 2. CONFIG
$Global:JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/bootkits.json"
# [LUU Y] File tren Github phai ten la BOOTICE.exe
$Global:BootIceUrl = "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/BOOTICE.exe" 
$Global:TempDir = "$env:TEMP\UsbBootMaker"
if (!(Test-Path $Global:TempDir)) { New-Item -ItemType Directory -Path $Global:TempDir -Force | Out-Null }

# 3. THEME
$Theme = @{
    BgForm  = [System.Drawing.Color]::FromArgb(20,20,25)
    Card    = [System.Drawing.Color]::FromArgb(35,35,40)
    Text    = [System.Drawing.Color]::FromArgb(240,240,240)
    Cyan    = [System.Drawing.Color]::FromArgb(0,255,255)
    InputBg = [System.Drawing.Color]::FromArgb(50,50,55)
    Muted   = [System.Drawing.Color]::Gray
}

# --- HELPER FUNCTIONS ---
function Log-Msg ($Msg) { 
    $TxtLog.Text += "[$(Get-Date -F 'HH:mm:ss')] $Msg`r`n"
    $TxtLog.SelectionStart = $TxtLog.Text.Length; $TxtLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

# [FIXED] Doi ten ham ve giong luc goi de het loi
function Run-DiskPartScript ($Commands) {
    $F = "$Global:TempDir\dp_step.txt"; [IO.File]::WriteAllText($F, $Commands)
    $P = Start-Process "diskpart" "/s `"$F`"" -Wait -NoNewWindow -PassThru
    return $P.ExitCode
}

# --- HAM NAP MBR/PBR BANG BOOTICE (CLI) ---
function Run-BootICE ($DiskID, $PartIndex) {
    $ToolPath = "$Global:TempDir\BOOTICE.exe"
    
    # 1. Tai BootICE neu chua co
    if (!(Test-Path $ToolPath)) {
        Log-Msg "Dang tai BOOTICE..."
        try { 
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $Web = New-Object Net.WebClient
            $Web.Headers.Add("User-Agent", "Mozilla/5.0")
            $Web.DownloadFile($Global:BootIceUrl, $ToolPath)
        } catch { 
            Log-Msg "LOI: Khong tai duoc BootICE! Kiem tra lai Github."
            return 
        }
    }

    if (Test-Path $ToolPath) {
        Log-Msg "Dang nap MBR/PBR (Grub4Dos)..."
        # Nap MBR
        $ArgMBR = "/DEVICE=$DiskID /MBR /install /type=GRUB4DOS /auto /quiet"
        Start-Process -FilePath $ToolPath -ArgumentList $ArgMBR -Wait -WindowStyle Hidden
        # Nap PBR
        $ArgPBR = "/DEVICE=$DiskID /PBR /partition=$PartIndex /install /type=GRUB4DOS /auto /quiet"
        Start-Process -FilePath $ToolPath -ArgumentList $ArgPBR -Wait -WindowStyle Hidden
        Log-Msg "Nap Bootloader xong."
    }
}

function Get-DriveLetterByLabel ($Label) {
    Get-Disk | Update-Disk -ErrorAction SilentlyContinue; Start-Sleep 1
    if (Get-Command "Get-Volume" -ErrorAction SilentlyContinue) {
        try { $v=Get-Volume|Where{$_.FileSystemLabel -eq $Label}|Select -First 1; if($v.DriveLetter){return "$($v.DriveLetter):"} } catch {}
    }
    try { $w=Get-WmiObject Win32_Volume -Filter "Label='$Label'" -EA 0|Select -First 1; if($w.DriveLetter){return $w.DriveLetter} } catch {}
    return $null
}

function Add-GlowBorder ($Panel) {
    $Panel.Add_Paint({ param($s,$e) $p=New-Object System.Drawing.Pen([System.Drawing.Color]::Cyan,1); $r=$s.ClientRectangle; $r.Width-=1; $r.Height-=1; $e.Graphics.DrawRectangle($p,$r); $p.Dispose() })
}

# --- GUI INIT ---
# [FIXED] Sua khai bao Font de het loi "Ambiguous"
$F_Title = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$F_Norm  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$F_Bold  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$F_Code  = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Regular)

$Form = New-Object System.Windows.Forms.Form
$Form.Text="USB BOOT MAKER V4.2 (FINAL FIX)"; $Form.Size="900,750"; $Form.StartPosition="CenterScreen"; $Form.BackColor=$Theme.BgForm; $Form.ForeColor=$Theme.Text; $Form.Padding=15

$MainLayout=New-Object System.Windows.Forms.TableLayoutPanel; $MainLayout.Dock="Fill"; $MainLayout.ColumnCount=1; $MainLayout.RowCount=5
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize)))
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize)))
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize)))
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute,200)))
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent,100)))
$Form.Controls.Add($MainLayout)

# Header
$PnlTitle=New-Object System.Windows.Forms.Panel; $PnlTitle.Height=50; $PnlTitle.Dock="Top"; $PnlTitle.Margin="0,0,0,10"
$LblTitle=New-Object System.Windows.Forms.Label; $LblTitle.Text="⚡ USB BOOT CREATOR ULTIMATE"; $LblTitle.Font=$F_Title; $LblTitle.ForeColor=$Theme.Cyan; $LblTitle.AutoSize=$true; $LblTitle.Location="10,10"
$PnlTitle.Controls.Add($LblTitle); $MainLayout.Controls.Add($PnlTitle,0,0)

# Helper
function New-Card ($T) { 
    $P=New-Object System.Windows.Forms.Panel; $P.BackColor=$Theme.Card; $P.Padding=10; $P.Margin="0,0,0,15"; $P.Dock="Top"; $P.AutoSize=$true; Add-GlowBorder $P; 
    $L=New-Object System.Windows.Forms.Label; $L.Text=$T; $L.Font=$Global:F_Bold; $L.ForeColor=$Theme.Muted; $L.Dock="Top"; $L.Height=25; 
    $P.Controls.Add($L); return $P 
}

# UI Components
$CardUSB=New-Card "1. CHỌN THIẾT BỊ USB"; $L1=New-Object System.Windows.Forms.TableLayoutPanel; $L1.Dock="Top"; $L1.Height=40; $L1.ColumnCount=2; $L1.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,80)))
$CbUSB=New-Object System.Windows.Forms.ComboBox; $CbUSB.Dock="Fill"; $CbUSB.Font=$F_Norm; $CbUSB.BackColor=$Theme.InputBg; $CbUSB.ForeColor="White"; $CbUSB.DropDownStyle="DropDownList"
$BtnRef=New-Object System.Windows.Forms.Button; $BtnRef.Text="LÀM MỚI"; $BtnRef.Dock="Fill"; $BtnRef.BackColor=$Theme.InputBg; $BtnRef.ForeColor="White"; $BtnRef.FlatStyle="Flat"
$L1.Controls.Add($CbUSB,0,0); $L1.Controls.Add($BtnRef,1,0); $CardUSB.Controls.Add($L1); $MainLayout.Controls.Add($CardUSB,0,1)

$CardKit=New-Card "2. CHỌN BOOT KIT"; $CbKit=New-Object System.Windows.Forms.ComboBox; $CbKit.Dock="Top"; $CbKit.Font=$F_Norm; $CbKit.BackColor=$Theme.InputBg; $CbKit.ForeColor="White"; $CbKit.DropDownStyle="DropDownList"; $CardKit.Controls.Add($CbKit); $MainLayout.Controls.Add($CardKit,0,2)

$CardSet=New-Object System.Windows.Forms.GroupBox; $CardSet.Text="3. TÙY CHỈNH NÂNG CAO"; $CardSet.Dock="Fill"; $CardSet.ForeColor=[System.Drawing.Color]::Gold; $CardSet.Padding="5,20,5,5"
$Scroll=New-Object System.Windows.Forms.Panel; $Scroll.Dock="Fill"; $Scroll.AutoScroll=$true; $CardSet.Controls.Add($Scroll)
$Grid=New-Object System.Windows.Forms.TableLayoutPanel; $Grid.Dock="Top"; $Grid.AutoSize=$true; $Grid.ColumnCount=3; $Grid.RowCount=3
$Grid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,33)))
$Grid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,33)))
$Grid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,33)))
$Scroll.Controls.Add($Grid)

function Add-Set ($L,$C,$R,$Cl) { $P=New-Object System.Windows.Forms.Panel; $P.Dock="Top"; $P.Height=60; $P.Padding=5; $Lb=New-Object System.Windows.Forms.Label; $Lb.Text=$L; $Lb.Dock="Top"; $Lb.Height=20; $Lb.ForeColor="Silver"; $C.Dock="Top"; $C.Font=$Global:F_Norm; $C.BackColor=$Theme.InputBg; $C.ForeColor="White"; $P.Controls.Add($C); $P.Controls.Add($Lb); $Grid.Controls.Add($P,$Cl,$R) }

$CbStyle=New-Object System.Windows.Forms.ComboBox; $CbStyle.Items.AddRange(@("MBR (Legacy+UEFI)", "GPT (UEFI Only)")); $CbStyle.SelectedIndex=0; $CbStyle.DropDownStyle="DropDownList"; Add-Set "Kiểu Partition:" $CbStyle 0 0
$NumSize=New-Object System.Windows.Forms.NumericUpDown; $NumSize.Minimum=100; $NumSize.Maximum=8192; $NumSize.Value=512; Add-Set "Size Boot (MB):" $NumSize 0 1
$TxtBoot=New-Object System.Windows.Forms.TextBox; $TxtBoot.Text="GLIM_BOOT"; Add-Set "Nhãn Boot:" $TxtBoot 0 2
$CbFS=New-Object System.Windows.Forms.ComboBox; $CbFS.Items.AddRange(@("NTFS","exFAT","FAT32")); $CbFS.SelectedIndex=0; $CbFS.DropDownStyle="DropDownList"; Add-Set "Định dạng Data:" $CbFS 1 0
$TxtData=New-Object System.Windows.Forms.TextBox; $TxtData.Text="GLIM_DATA"; Add-Set "Nhãn Data:" $TxtData 1 1

$MainLayout.Controls.Add($CardSet,0,3)

$PnlLog=New-Object System.Windows.Forms.Panel; $PnlLog.Dock="Fill"; $PnlLog.Padding="0,10,0,0"
$TxtLog=New-Object System.Windows.Forms.TextBox; $TxtLog.Multiline=$true; $TxtLog.Dock="Fill"; $TxtLog.BackColor="Black"; $TxtLog.ForeColor="Lime"; $TxtLog.Font=$F_Code; $TxtLog.ReadOnly=$true; $TxtLog.ScrollBars="Vertical"
$PnlLog.Controls.Add($TxtLog); $MainLayout.Controls.Add($PnlLog,0,4)

$BtnStart=New-Object System.Windows.Forms.Button; $BtnStart.Text="🚀 BẮT ĐẦU"; $BtnStart.Font=$F_Title; $BtnStart.BackColor=$Theme.Cyan; $BtnStart.ForeColor="Black"; $BtnStart.FlatStyle="Flat"; $BtnStart.Dock="Bottom"; $BtnStart.Height=60; $Form.Controls.Add($BtnStart)

# --- LOGIC ---
function Load-U {
    $CbUSB.Items.Clear(); $w=$false
    if (Get-Command "Get-Disk" -EA 0) { try { $ds=@(Get-Disk -EA Stop|Where{$_.BusType -eq "USB" -or $_.MediaType -eq "Removable"}); if($ds.Count -eq 0){throw}; foreach($d in $ds){ $CbUSB.Items.Add("Disk $($d.Number): $($d.FriendlyName) ($([Math]::Round($d.Size/1GB,1)) GB)") } } catch {$w=$true} } else {$w=$true}
    if ($w) { try { $ds=@(Get-WmiObject Win32_DiskDrive|Where{$_.InterfaceType -eq "USB"}); foreach($d in $ds){ $CbUSB.Items.Add("Disk $($d.Index): $($d.Model)") } } catch {} }
    if($CbUSB.Items.Count -gt 0){$CbUSB.SelectedIndex=0}else{$CbUSB.Items.Add("Không tìm thấy USB");$CbUSB.SelectedIndex=0}
}

function Load-K {
    $CbKit.Items.Clear(); Log-Msg "Đang tải danh sách..."
    try { 
        [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
        $Web = New-Object Net.WebClient
        $Web.Headers.Add("User-Agent", "Mozilla/5.0")
        $j = $Web.DownloadString("$($Global:JsonUrl)?t=$(Get-Date -UFormat %s)") | ConvertFrom-Json
        if($j){foreach($i in $j){if($i.Name){$CbKit.Items.Add($i.Name);$Global:KitData=$j}}}; if($CbKit.Items.Count -gt 0){$CbKit.SelectedIndex=0; Log-Msg "Sẵn sàng."} 
    } catch { $CbKit.Items.Add("Chế độ Demo");$CbKit.SelectedIndex=0; Log-Msg "Lỗi mạng hoặc JSON lỗi." }
}

function Download-File ($Url, $Dest) {
    Log-Msg "Đang tải xuống..."; try { $Web=New-Object Net.WebClient; $Web.Headers.Add("User-Agent","Mozilla/5.0"); $Web.DownloadFile($Url, $Dest); return $true } catch { Log-Msg "Lỗi tải file!"; return $false }
}

$BtnStart.Add_Click({
    if($CbUSB.SelectedItem -match "Disk (\d+)"){ $ID=$Matches[1] } else { return }
    $K=$Global:KitData | Where{$_.Name -eq $CbKit.SelectedItem} | Select -First 1; if(!$K){return}
    if([System.Windows.Forms.MessageBox]::Show("XÓA SẠCH DỮ LIỆU DISK $ID?","CẢNH BÁO","YesNo","Warning") -ne "Yes"){return}
    $BtnStart.Enabled=$false; $Form.Cursor="WaitCursor"

    $Zip="$Global:TempDir\$($K.FileName)"
    if(!(Test-Path $Zip)){ Log-Msg "Tải Kit: $($K.FileName)..."; if(!(Download-File $K.Url $Zip)){$BtnStart.Enabled=$true;$Form.Cursor="Default";return} }

    # CHIA DOI DISKPART DE FIX VIRTUALBOX
    $St=if($CbStyle.SelectedIndex -eq 0){"mbr"}else{"gpt"}; $Sz=$NumSize.Value; $BL=$TxtBoot.Text; $DL=$TxtData.Text; $FS=$CbFS.SelectedItem
    
    # 1. CLEAN
    Log-Msg "B1: Format USB (Clean)..."
    Run-DiskPartScript "select disk $ID`nclean`nconvert $St`nrescan"
    Log-Msg "Doi 5s cho VirtualBox nhan lai USB..."; Start-Sleep 5

    # 2. CREATE PARTITIONS
    Log-Msg "B2: Tao phan vung..."
    $Cmd="select disk $ID"
    if($St -eq "mbr"){ 
        $Cmd+="`ncreate part pri size=$Sz`nformat fs=fat32 quick label=`"$BL`"`nactive`nassign"
        $Cmd+="`ncreate part pri`nformat fs=$FS quick label=`"$DL`"`nassign`nexit" 
    } else { 
        $Cmd+="`ncreate part pri size=$Sz`nformat fs=fat32 quick label=`"$BL`"`nassign"
        $Cmd+="`ncreate part pri`nformat fs=$FS quick label=`"$DL`"`nassign`nexit" 
    }
    Run-DiskPartScript $Cmd
    Log-Msg "Doi 5s gan o dia..."; Start-Sleep 5

    # 3. BOOTICE
    if ($St -eq "mbr") { Run-BootICE $ID 0 }

    # 4. EXTRACT
    for($i=1;$i -le 5;$i++){ $B=Get-DriveLetterByLabel $BL; $D=Get-DriveLetterByLabel $DL; if($B -and $D){break}; Start-Sleep 2 }
    if(!$B){ Log-Msg "Lỗi tìm ổ Boot! (Rút USB cắm lại rồi thử lại)"; $BtnStart.Enabled=$true; $Form.Cursor="Default"; return }
    Log-Msg "Boot: $B | Data: $D"

    Log-Msg "Giải nén..."
    try{Expand-Archive -Path $Zip -DestinationPath "$B\" -Force}catch{}
    if ($St -eq "mbr" -and !(Test-Path "$B\menu.lst")) { "timeout 0`ndefault 0`ntitle Boot`nfind --set-root /boot/grub/i386-pc/core.img`nkernel /boot/grub/i386-pc/core.img`nboot" | Out-File "$B\menu.lst" -Encoding ASCII }

    if($D){
        Log-Msg "Tạo thư mục ISO..."
        @("iso\windows","iso\linux","iso\android","iso\utilities") | ForEach { New-Item -ItemType Directory -Path "$D\$_" -Force | Out-Null }
    }

    Log-Msg "HOÀN TẤT!"; [System.Windows.Forms.MessageBox]::Show("Thành công!"); $BtnStart.Enabled=$true; $Form.Cursor="Default"
    if($D){Invoke-Item "$D\iso"}
})

$BtnRef.Add_Click({Load-U;Load-K}); $Form.Add_Load({Load-U;Load-K}); [System.Windows.Forms.Application]::Run($Form)
