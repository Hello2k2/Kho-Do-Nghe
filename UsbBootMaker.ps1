<#
    USB BOOT MAKER - PHAT TAN PC (V4: INTEGRATED BOOTICE CLI)
    Features: 
    - Auto Flash MBR/PBR using BootICE (Silent Mode) for Legacy Boot
    - Full Customization: Label, Size, Filesystem, MBR/GPT
    - Auto Folder Structure Creation
    - Engine: Dual-Mode (Get-Disk + WMI)
    - UI: Dark Titanium + Scrollbar Settings
#>

# 1. SETUP
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

# 2. CONFIG
$Global:JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/bootkits.json"
# Link tải BootICE (Ông nên thay bằng link trên repo của ông cho chắc ăn)
$Global:BootIceUrl = "https://github.com/Hello2k2/Kho-Do-Nghe/raw/main/BOOTICE.exe" 
$Global:TempDir = "$env:TEMP\UsbBootMaker"
if (!(Test-Path $Global:TempDir)) { New-Item -ItemType Directory -Path $Global:TempDir -Force | Out-Null }

# 3. THEME
$Theme = @{
    BgForm=[System.Drawing.Color]::FromArgb(20,20,25); Card=[System.Drawing.Color]::FromArgb(35,35,40)
    Text=[System.Drawing.Color]::FromArgb(240,240,240); Cyan=[System.Drawing.Color]::FromArgb(0,255,255)
    InputBg=[System.Drawing.Color]::FromArgb(50,50,55)
}

# --- HELPER FUNCTIONS ---
function Log-Msg ($Msg) { 
    $TxtLog.Text += "[$(Get-Date -F 'HH:mm:ss')] $Msg`r`n"
    $TxtLog.SelectionStart = $TxtLog.Text.Length; $TxtLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function Run-DiskPartScript ($ScriptContent) {
    $F = "$Global:TempDir\dp_script.txt"; [IO.File]::WriteAllText($F, $ScriptContent)
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
            (New-Object Net.WebClient).DownloadFile($Global:BootIceUrl, $ToolPath)
        } catch { 
            Log-Msg "LOI: Khong tai duoc BootICE! Bo qua nap MBR."
            return 
        }
    }

    Log-Msg "Dang nap MBR/PBR (Grub4Dos) cho Disk $DiskID..."
    
    # 2. Nap MBR (Master Boot Record) -> Grub4Dos 0.4.6a
    $ArgMBR = "/DEVICE=$DiskID /MBR /install /type=GRUB4DOS /auto /quiet"
    Start-Process -FilePath $ToolPath -ArgumentList $ArgMBR -Wait -WindowStyle Hidden
    
    # 3. Nap PBR (Partition Boot Record) -> Grub4Dos (Vao phan vung Boot - Index 0)
    # PartIndex: 0 la phan vung dau tien (GLIM_BOOT)
    $ArgPBR = "/DEVICE=$DiskID /PBR /partition=$PartIndex /install /type=GRUB4DOS /auto /quiet"
    Start-Process -FilePath $ToolPath -ArgumentList $ArgPBR -Wait -WindowStyle Hidden
    
    Log-Msg "Da nap Bootloader Legacy thanh cong!"
}

function Get-DriveLetterByLabel ($Label) {
    if (Get-Command "Get-Volume" -ErrorAction SilentlyContinue) {
        try { Get-Disk | Update-Disk -ErrorAction SilentlyContinue; $v=Get-Volume|Where{$_.FileSystemLabel -eq $Label}|Select -First 1; if($v.DriveLetter){return "$($v.DriveLetter):"} } catch {}
    }
    try { $w=Get-WmiObject Win32_Volume -Filter "Label='$Label'" -EA 0|Select -First 1; if($w.DriveLetter){return $w.DriveLetter} } catch {}
    try { $d=Get-WmiObject Win32_LogicalDisk; foreach($i in $d){if($i.VolumeName -eq $Label){return $i.DeviceID}} } catch {}
    return $null
}

function Add-GlowBorder ($Panel) {
    $Panel.Add_Paint({ param($s,$e) $p=New-Object System.Drawing.Pen([System.Drawing.Color]::Cyan,1); $r=$s.ClientRectangle; $r.Width-=1; $r.Height-=1; $e.Graphics.DrawRectangle($p,$r); $p.Dispose() })
}

# --- GUI INIT ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text="USB BOOT MAKER ULTIMATE - PHÁT TẤN PC (V4 HYBRID)"; $Form.Size="900,750"; $Form.StartPosition="CenterScreen"; $Form.BackColor=$Theme.BgForm; $Form.ForeColor=$Theme.Text; $Form.Padding=15
$F_Title=New-Object System.Drawing.Font("Segoe UI",14,1); $F_Norm=New-Object System.Drawing.Font("Segoe UI",10); $F_Code=New-Object System.Drawing.Font("Consolas",9)

$MainLayout=New-Object System.Windows.Forms.TableLayoutPanel; $MainLayout.Dock="Fill"; $MainLayout.ColumnCount=1; $MainLayout.RowCount=5
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize)))
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize)))
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize)))
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute,200)))
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent,100)))
$Form.Controls.Add($MainLayout)

# 1. Header
$PnlTitle=New-Object System.Windows.Forms.Panel; $PnlTitle.Height=50; $PnlTitle.Dock="Top"; $PnlTitle.Margin="0,0,0,10"
$LblTitle=New-Object System.Windows.Forms.Label; $LblTitle.Text="⚡ USB BOOT CREATOR ULTIMATE"; $LblTitle.Font=$F_Title; $LblTitle.ForeColor=$Theme.Cyan; $LblTitle.AutoSize=$true; $LblTitle.Location="10,10"
$PnlTitle.Controls.Add($LblTitle); $MainLayout.Controls.Add($PnlTitle,0,0)

# Card Helper
function New-Card ($T) { $P=New-Object System.Windows.Forms.Panel; $P.BackColor=$Theme.Card; $P.Padding=10; $P.Margin="0,0,0,15"; $P.Dock="Top"; $P.AutoSize=$true; Add-GlowBorder $P; $L=New-Object System.Windows.Forms.Label; $L.Text=$T; $L.Font=[System.Drawing.Font]::new($F_Norm,[System.Drawing.FontStyle]::Bold); $L.ForeColor=$Theme.Muted; $L.Dock="Top"; $L.Height=25; $P.Controls.Add($L); return $P }

# 2. USB
$CardUSB=New-Card "1. CHỌN THIẾT BỊ USB"; $L1=New-Object System.Windows.Forms.TableLayoutPanel; $L1.Dock="Top"; $L1.Height=40; $L1.ColumnCount=2; $L1.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,80)))
$CbUSB=New-Object System.Windows.Forms.ComboBox; $CbUSB.Dock="Fill"; $CbUSB.Font=$F_Norm; $CbUSB.BackColor=$Theme.InputBg; $CbUSB.ForeColor="White"; $CbUSB.DropDownStyle="DropDownList"
$BtnRef=New-Object System.Windows.Forms.Button; $BtnRef.Text="LÀM MỚI"; $BtnRef.Dock="Fill"; $BtnRef.BackColor=$Theme.InputBg; $BtnRef.ForeColor="White"; $BtnRef.FlatStyle="Flat"
$L1.Controls.Add($CbUSB,0,0); $L1.Controls.Add($BtnRef,1,0); $CardUSB.Controls.Add($L1); $MainLayout.Controls.Add($CardUSB,0,1)

# 3. Kit
$CardKit=New-Card "2. CHỌN BOOT KIT"; $CbKit=New-Object System.Windows.Forms.ComboBox; $CbKit.Dock="Top"; $CbKit.Font=$F_Norm; $CbKit.BackColor=$Theme.InputBg; $CbKit.ForeColor="White"; $CbKit.DropDownStyle="DropDownList"; $CardKit.Controls.Add($CbKit); $MainLayout.Controls.Add($CardKit,0,2)

# 4. Settings (Scroll)
$CardSet=New-Object System.Windows.Forms.GroupBox; $CardSet.Text="3. TÙY CHỈNH NÂNG CAO"; $CardSet.Dock="Fill"; $CardSet.ForeColor=[System.Drawing.Color]::Gold; $CardSet.Padding="5,20,5,5"
$Scroll=New-Object System.Windows.Forms.Panel; $Scroll.Dock="Fill"; $Scroll.AutoScroll=$true; $CardSet.Controls.Add($Scroll)
$Grid=New-Object System.Windows.Forms.TableLayoutPanel; $Grid.Dock="Top"; $Grid.AutoSize=$true; $Grid.ColumnCount=3; $Grid.RowCount=3
$Grid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,33)))
$Grid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,33)))
$Grid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,33)))
$Scroll.Controls.Add($Grid)

function Add-Set ($L,$C,$R,$Cl) { $P=New-Object System.Windows.Forms.Panel; $P.Dock="Top"; $P.Height=60; $P.Padding=5; $Lb=New-Object System.Windows.Forms.Label; $Lb.Text=$L; $Lb.Dock="Top"; $Lb.Height=20; $Lb.ForeColor="Silver"; $C.Dock="Top"; $C.Font=$F_Norm; $C.BackColor=$Theme.InputBg; $C.ForeColor="White"; $P.Controls.Add($C); $P.Controls.Add($Lb); $Grid.Controls.Add($P,$Cl,$R) }

$CbStyle=New-Object System.Windows.Forms.ComboBox; $CbStyle.Items.AddRange(@("MBR (Legacy+UEFI)", "GPT (UEFI Only)")); $CbStyle.SelectedIndex=0; $CbStyle.DropDownStyle="DropDownList"; Add-Set "Kiểu Partition:" $CbStyle 0 0
$NumSize=New-Object System.Windows.Forms.NumericUpDown; $NumSize.Minimum=100; $NumSize.Maximum=8192; $NumSize.Value=512; Add-Set "Size Boot (MB):" $NumSize 0 1
$TxtBoot=New-Object System.Windows.Forms.TextBox; $TxtBoot.Text="GLIM_BOOT"; Add-Set "Nhãn Boot:" $TxtBoot 0 2
$CbFS=New-Object System.Windows.Forms.ComboBox; $CbFS.Items.AddRange(@("NTFS","exFAT","FAT32")); $CbFS.SelectedIndex=0; $CbFS.DropDownStyle="DropDownList"; Add-Set "Định dạng Data:" $CbFS 1 0
$TxtData=New-Object System.Windows.Forms.TextBox; $TxtData.Text="GLIM_DATA"; Add-Set "Nhãn Data:" $TxtData 1 1

$MainLayout.Controls.Add($CardSet,0,3)

# 5. Log
$PnlLog=New-Object System.Windows.Forms.Panel; $PnlLog.Dock="Fill"; $PnlLog.Padding="0,10,0,0"
$TxtLog=New-Object System.Windows.Forms.TextBox; $TxtLog.Multiline=$true; $TxtLog.Dock="Fill"; $TxtLog.BackColor="Black"; $TxtLog.ForeColor="Lime"; $TxtLog.Font=$F_Code; $TxtLog.ReadOnly=$true; $TxtLog.ScrollBars="Vertical"
$PnlLog.Controls.Add($TxtLog); $MainLayout.Controls.Add($PnlLog,0,4)

# 6. Start
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
    try { [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $j=Invoke-RestMethod -Uri "$($Global:JsonUrl)?t=$(Get-Date -UFormat %s)" -Headers @{"Cache-Control"="no-cache"} -EA Stop; if($j){foreach($i in $j){if($i.Name){$CbKit.Items.Add($i.Name);$Global:KitData=$j}}}; if($CbKit.Items.Count -gt 0){$CbKit.SelectedIndex=0; Log-Msg "Sẵn sàng."} } catch { $CbKit.Items.Add("Chế độ Demo");$CbKit.SelectedIndex=0; Log-Msg "Lỗi mạng." }
}

function Download-File ($Url, $Dest) {
    Log-Msg "Đang tải xuống..."; try { (New-Object Net.WebClient).DownloadFile($Url, $Dest); return $true } catch { Log-Msg "Lỗi tải file!"; return $false }
}

$BtnStart.Add_Click({
    if($CbUSB.SelectedItem -match "Disk (\d+)"){ $ID=$Matches[1] } else { return }
    $K=$Global:KitData | Where{$_.Name -eq $CbKit.SelectedItem} | Select -First 1; if(!$K){return}
    if([System.Windows.Forms.MessageBox]::Show("XÓA SẠCH DỮ LIỆU DISK $ID?","CẢNH BÁO","YesNo","Warning") -ne "Yes"){return}
    $BtnStart.Enabled=$false; $Form.Cursor="WaitCursor"

    # 1. DL ZIP
    $Zip="$Global:TempDir\$($K.FileName)"
    if(!(Test-Path $Zip)){ Log-Msg "Tải Kit: $($K.FileName)..."; if(!(Download-File $K.Url $Zip)){$BtnStart.Enabled=$true;$Form.Cursor="Default";return} }

    # 2. DISKPART
    $St=if($CbStyle.SelectedIndex -eq 0){"mbr"}else{"gpt"}; $Sz=$NumSize.Value; $BL=$TxtBoot.Text; $DL=$TxtData.Text; $FS=$CbFS.SelectedItem
    Log-Msg "Format: $St | Boot: $Sz MB..."
    
    $Cmd="select disk $ID`nclean`nconvert $St`nrescan"
    if($St -eq "mbr"){ $Cmd+="`ncreate part pri size=$Sz`nformat fs=fat32 quick label=`"$BL`"`nactive`nassign"; $Cmd+="`ncreate part pri`nformat fs=$FS quick label=`"$DL`"`nassign`nexit" }
    else { $Cmd+="`ncreate part pri size=$Sz`nformat fs=fat32 quick label=`"$BL`"`nassign"; $Cmd+="`ncreate part pri`nformat fs=$FS quick label=`"$DL`"`nassign`nexit" }
    
    Run-DiskPartScript $Cmd
    Log-Msg "Đợi Windows (10s)..."; Start-Sleep 10

    # 3. BOOTICE (AUTO FLASH MBR NEU LA MBR)
    if ($St -eq "mbr") {
        Log-Msg "Đang nạp Bootloader Legacy (BootICE)..."
        # Download BootICE neu can
        $BTool = "$Global:TempDir\BOOTICE.exe"
        if (!(Test-Path $BTool)) {
             try { (New-Object Net.WebClient).DownloadFile($Global:BootIceUrl, $BTool) } catch { Log-Msg "Không tải được BootICE. Bỏ qua nạp MBR." }
        }
        if (Test-Path $BTool) {
             # Nạp MBR Grub4Dos
             Start-Process $BTool -Arg "/DEVICE=$ID /MBR /install /type=GRUB4DOS /auto /quiet" -Wait -WindowStyle Hidden
             # Nạp PBR Grub4Dos cho phân vùng 0 (Boot)
             Start-Process $BTool -Arg "/DEVICE=$ID /PBR /partition=0 /install /type=GRUB4DOS /auto /quiet" -Wait -WindowStyle Hidden
             Log-Msg "Đã nạp MBR/PBR xong."
        }
    }

    # 4. DETECT
    for($i=1;$i -le 3;$i++){ $B=Get-DriveLetterByLabel $BL; $D=Get-DriveLetterByLabel $DL; if($B -and $D){break}; Start-Sleep 3 }
    if(!$B){ Log-Msg "Lỗi tìm ổ Boot!"; $BtnStart.Enabled=$true; $Form.Cursor="Default"; return }
    Log-Msg "Boot: $B | Data: $D"

    # 5. EXTRACT & GRLDR CHECK
    Log-Msg "Giải nén..."
    try{Expand-Archive -Path $Zip -DestinationPath "$B\" -Force}catch{}
    
    # Tao file menu.lst cho GRUB4DOS neu chua co (De chuyen huong sang GRUB2)
    if ($St -eq "mbr" -and !(Test-Path "$B\menu.lst")) {
        Log-Msg "Tạo menu.lst (Bridge)..."
        # Lenh nay giup Grub4Dos tu dong tim va boot vao Grub2
        "timeout 0`ndefault 0`ntitle Go to GRUB2`nfind --set-root /boot/grub/i386-pc/core.img`nkernel /boot/grub/i386-pc/core.img`nboot" | Out-File "$B\menu.lst" -Encoding ASCII
        
        # Can thiet: File grldr. Neu trong ZIP khong co, ta khong the tu tao duoc. 
        # (Nhung thuong Grub4Dos installer cua BootICE da co san co che boot co ban)
        # Tot nhat la trong Kit ZIP cua ong nen co san file 'grldr'.
    }

    # 6. FOLDERS
    if($D){
        Log-Msg "Tạo thư mục ISO..."
        @("iso\windows","iso\linux","iso\android","iso\utilities","iso\dos") | ForEach { New-Item -ItemType Directory -Path "$D\$_" -Force | Out-Null }
        Set-Content "$D\README.txt" "Chép ISO vào đây!"
    }

    Log-Msg "XONG!"; [System.Windows.Forms.MessageBox]::Show("Thành công!"); $BtnStart.Enabled=$true; $Form.Cursor="Default"
    if($D){Invoke-Item "$D\iso"}
})

$BtnRef.Add_Click({Load-U;Load-K}); $Form.Add_Load({Load-U;Load-K}); [System.Windows.Forms.Application]::Run($Form)
