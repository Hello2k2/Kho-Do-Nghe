<#
    VENTOY BOOT MAKER - PHAT TAN PC (V5.0: VENTOY CORE)
    Updates:
    - [CORE] Chuyển sang nhân Ventoy (Copy ISO là chạy).
    - [AUTO] Tự động tải và cài đặt Ventoy mới nhất.
    - [THEME] Tự động cấu hình file JSON giao diện.
    - [MODE] Hỗ trợ Secure Boot & Partition Style.
#>

# --- 0. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $Arg = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell.exe -Verb RunAs -ArgumentList $Arg
    Exit
}

# 1. SETUP
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

# 2. CONFIG
$Global:VentoyUrl = "https://github.com/ventoy/Ventoy/releases/download/v1.0.97/ventoy-1.0.97-windows.zip" # Link cứng bản ổn định hoặc dùng API để get mới nhất
$Global:WorkDir = "C:\PhatTan_Ventoy_Temp"
if (!(Test-Path $Global:WorkDir)) { New-Item -ItemType Directory -Path $Global:WorkDir -Force | Out-Null }

# 3. THEME
$Theme = @{
    BgForm  = [System.Drawing.Color]::FromArgb(25, 25, 35)
    Card    = [System.Drawing.Color]::FromArgb(40, 40, 50)
    Text    = [System.Drawing.Color]::FromArgb(240, 240, 240)
    Accent  = [System.Drawing.Color]::FromArgb(0, 200, 83) # Ventoy Green
    InputBg = [System.Drawing.Color]::FromArgb(60, 60, 70)
    Muted   = [System.Drawing.Color]::Gray
}

# --- HELPER FUNCTIONS ---
function Log-Msg ($Msg) { 
    $TxtLog.AppendText("[$(Get-Date -F 'HH:mm:ss')] $Msg`r`n")
    $TxtLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function Add-GlowBorder ($Panel) {
    $Panel.Add_Paint({ param($s,$e) $p=New-Object System.Drawing.Pen($Theme.Accent,1); $r=$s.ClientRectangle; $r.Width-=1; $r.Height-=1; $e.Graphics.DrawRectangle($p,$r); $p.Dispose() })
}

# --- GUI ---
$F_Title = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$F_Norm  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$F_Bold  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$F_Code  = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Regular)

$Form = New-Object System.Windows.Forms.Form
$Form.Text="PHAT TAN BOOT MAKER (V5.0)"; $Form.Size="900,700"; $Form.StartPosition="CenterScreen"; $Form.BackColor=$Theme.BgForm; $Form.ForeColor=$Theme.Text; $Form.Padding=15

$MainLayout=New-Object System.Windows.Forms.TableLayoutPanel; $MainLayout.Dock="Fill"; $MainLayout.ColumnCount=1; $MainLayout.RowCount=5
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) # Title
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) # USB
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 220))) # Settings
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent,100))) # Log
$MainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 70))) # Button
$Form.Controls.Add($MainLayout)

# HEADER
$PnlTitle=New-Object System.Windows.Forms.Panel; $PnlTitle.Height=60; $PnlTitle.Dock="Top"; $PnlTitle.Margin="0,0,0,10"
$LblTitle=New-Object System.Windows.Forms.Label; $LblTitle.Text="🛠️ TẠO USB BOOT VENTOY ĐA NĂNG"; $LblTitle.Font=$F_Title; $LblTitle.ForeColor=$Theme.Accent; $LblTitle.AutoSize=$true; $LblTitle.Location="10,10"
$LblSub=New-Object System.Windows.Forms.Label; $LblSub.Text="Copy ISO/WIM/IMG là chạy - Không cần format lại"; $LblSub.ForeColor="Gray"; $LblSub.AutoSize=$true; $LblSub.Location="15,40"; $LblSub.Font=$F_Code
$PnlTitle.Controls.Add($LblTitle); $PnlTitle.Controls.Add($LblSub); $MainLayout.Controls.Add($PnlTitle,0,0)

# SECTION 1: USB
$CardUSB=New-Object System.Windows.Forms.Panel; $CardUSB.BackColor=$Theme.Card; $CardUSB.Padding=10; $CardUSB.Margin="0,0,0,15"; $CardUSB.Dock="Top"; $CardUSB.AutoSize=$true; Add-GlowBorder $CardUSB
$LblU=New-Object System.Windows.Forms.Label; $LblU.Text="CHỌN THIẾT BỊ USB (Sẽ bị xóa sạch dữ liệu!)"; $LblU.Font=$F_Bold; $LblU.Dock="Top"; $CardUSB.Controls.Add($LblU)
$L1=New-Object System.Windows.Forms.TableLayoutPanel; $L1.Dock="Top"; $L1.Height=40; $L1.ColumnCount=2; $L1.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,80)))
$CbUSB=New-Object System.Windows.Forms.ComboBox; $CbUSB.Dock="Fill"; $CbUSB.Font=$F_Norm; $CbUSB.BackColor=$Theme.InputBg; $CbUSB.ForeColor="White"; $CbUSB.DropDownStyle="DropDownList"
$BtnRef=New-Object System.Windows.Forms.Button; $BtnRef.Text="LÀM MỚI"; $BtnRef.Dock="Fill"; $BtnRef.BackColor=$Theme.InputBg; $BtnRef.ForeColor="White"; $BtnRef.FlatStyle="Flat"
$L1.Controls.Add($CbUSB,0,0); $L1.Controls.Add($BtnRef,1,0); $CardUSB.Controls.Add($L1); $MainLayout.Controls.Add($CardUSB,0,1)

# SECTION 2: SETTINGS
$CardSet=New-Object System.Windows.Forms.GroupBox; $CardSet.Text="CẤU HÌNH VENTOY"; $CardSet.Dock="Fill"; $CardSet.ForeColor=$Theme.Accent; $CardSet.Font=$F_Bold; $CardSet.Padding="10,25,10,10"
$Grid=New-Object System.Windows.Forms.TableLayoutPanel; $Grid.Dock="Fill"; $Grid.ColumnCount=2; $Grid.RowCount=3
$Grid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,50)))
$Grid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,50)))

function Add-Option ($L, $C, $Col, $Row) {
    $P=New-Object System.Windows.Forms.Panel; $P.Dock="Fill"; $P.Padding=5
    $Lb=New-Object System.Windows.Forms.Label; $Lb.Text=$L; $Lb.Dock="Top"; $Lb.Height=25; $Lb.ForeColor="White"; $Lb.Font=$Global:F_Norm
    $C.Dock="Top"; $C.BackColor=$Global:Theme.InputBg; $C.ForeColor="White"; $C.Font=$Global:F_Norm
    $P.Controls.Add($C); $P.Controls.Add($Lb); $Grid.Controls.Add($P, $Col, $Row)
}

# Opt 1: Label
$TxtLabel=New-Object System.Windows.Forms.TextBox; $TxtLabel.Text="Ventoy_Boot"; Add-Option "Tên ổ đĩa (Label):" $TxtLabel 0 0
# Opt 2: Partition Style
$CbStyle=New-Object System.Windows.Forms.ComboBox; $CbStyle.Items.AddRange(@("MBR (Tương thích cao - PC cũ & mới)", "GPT (Chuẩn UEFI mới - Trên 2TB)")); $CbStyle.SelectedIndex=0; $CbStyle.DropDownStyle="DropDownList"; Add-Option "Kiểu phân vùng (Partition Style):" $CbStyle 1 0
# Opt 3: Secure Boot
$ChkSecure=New-Object System.Windows.Forms.CheckBox; $ChkSecure.Text="Bật hỗ trợ Secure Boot"; $ChkSecure.Checked=$true; $ChkSecure.AutoSize=$true; $ChkSecure.ForeColor="Orange"
$P_Sec=New-Object System.Windows.Forms.Panel; $P_Sec.Padding=5; $P_Sec.Controls.Add($ChkSecure); $Grid.Controls.Add($P_Sec, 0, 1)
# Opt 4: Theme
$ChkTheme=New-Object System.Windows.Forms.CheckBox; $ChkTheme.Text="Cài sẵn Theme & Icon đẹp"; $ChkTheme.Checked=$true; $ChkTheme.AutoSize=$true; $ChkTheme.ForeColor="Cyan"
$P_Thm=New-Object System.Windows.Forms.Panel; $P_Thm.Padding=5; $P_Thm.Controls.Add($ChkTheme); $Grid.Controls.Add($P_Thm, 1, 1)

$CardSet.Controls.Add($Grid); $MainLayout.Controls.Add($CardSet,0,2)

# SECTION 3: LOG
$TxtLog=New-Object System.Windows.Forms.TextBox; $TxtLog.Multiline=$true; $TxtLog.Dock="Fill"; $TxtLog.BackColor="Black"; $TxtLog.ForeColor="Lime"; $TxtLog.Font=$F_Code; $TxtLog.ReadOnly=$true; $TxtLog.ScrollBars="Vertical"
$MainLayout.Controls.Add($TxtLog,0,3)

# BUTTON
$BtnStart=New-Object System.Windows.Forms.Button; $BtnStart.Text="🚀 CÀI ĐẶT VENTOY"; $BtnStart.Font=$F_Title; $BtnStart.BackColor=$Theme.Accent; $BtnStart.ForeColor="Black"; $BtnStart.FlatStyle="Flat"; $BtnStart.Dock="Fill"
$MainLayout.Controls.Add($BtnStart,0,4)

# --- LOGIC ---

function Load-USB {
    $CbUSB.Items.Clear()
    $Disks = Get-Disk | Where-Object { $_.BusType -eq "USB" -or $_.MediaType -eq "Removable" }
    if ($Disks) {
        foreach ($d in $Disks) {
            $SizeGB = [Math]::Round($d.Size / 1GB, 1)
            $CbUSB.Items.Add("Disk $($d.Number): $($d.FriendlyName) - $SizeGB GB")
        }
        $CbUSB.SelectedIndex = 0
    } else {
        $CbUSB.Items.Add("Không tìm thấy USB nào")
        $CbUSB.SelectedIndex = 0
    }
}

function Install-Ventoy {
    param($DiskID, $Style, $Label)
    
    $ZipFile = "$Global:WorkDir\ventoy.zip"
    $ExtractPath = "$Global:WorkDir\Extracted"
    
    # 1. DOWNLOAD VENTOY
    if (!(Test-Path "$ExtractPath\ventoy\Ventoy2Disk.exe")) {
        Log-Msg "Đang tải Ventoy từ Server..."
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            (New-Object Net.WebClient).DownloadFile($Global:VentoyUrl, $ZipFile)
            Log-Msg "Tải xong. Đang giải nén..."
            
            if (Test-Path $ExtractPath) { Remove-Item $ExtractPath -Recurse -Force }
            [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $ExtractPath)
            
            # Tìm thư mục con nếu zip có cấu trúc lồng nhau
            $ExePath = Get-ChildItem -Path $ExtractPath -Filter "Ventoy2Disk.exe" -Recurse | Select -First 1
            if ($ExePath) {
                $Global:VentoyExe = $ExePath.FullName
                $Global:VentoyDir = $ExePath.DirectoryName
            } else {
                Log-Msg "Lỗi: Không tìm thấy Ventoy2Disk.exe trong file tải về!"; return
            }
        } catch {
            Log-Msg "LỖI TẢI FILE: $($_.Exception.Message)"; return
        }
    } else {
        $Global:VentoyExe = Get-ChildItem -Path $ExtractPath -Filter "Ventoy2Disk.exe" -Recurse | Select -First 1 | %{$_.FullName}
        Log-Msg "Đã có sẵn source Ventoy."
    }

    # 2. RUN INSTALLATION
    Log-Msg "Đang chạy Ventoy2Disk cho Disk $DiskID..."
    
    # Chuyển đổi tham số
    $ArgStyle = if ($Style -match "GPT") { "/GPT" } else { "/MBR" }
    $ArgSecure = if ($ChkSecure.Checked) { "/S" } else { "" }
    
    # Lấy Drive Letter tạm của USB để Ventoy nhận diện (Ventoy CLI cần Drive Letter hoặc Disk Index)
    # Dùng CLI mode: Ventoy2Disk.exe VTOYCLI /I /Drive:X:
    # Nhưng an toàn nhất là dùng giao diện dòng lệnh VTOYCLI dựa trên Physical Drive
    
    # Mapping Disk Number to Drive Letter
    $Part = Get-Partition -DiskNumber $DiskID | Where-Object { $_.DriveLetter } | Select -First 1
    if (!$Part) { Log-Msg "Lỗi: USB cần có ít nhất 1 phân vùng có ký tự ổ đĩa để cài đặt."; return }
    $DriveLetter = "$($Part.DriveLetter):"
    
    Log-Msg "Mục tiêu: $DriveLetter (Disk $DiskID) | Mode: $ArgStyle | SecureBoot: $ArgSecure"
    
    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.FileName = $Global:VentoyExe
    # Cú pháp: Ventoy2Disk.exe VTOYCLI /I /Drive:D: /NoUsbCheck /GPT
    $Args = "VTOYCLI /I /Drive:$DriveLetter /NoUsbCheck $ArgStyle $ArgSecure"
    $ProcessInfo.Arguments = $Args
    $ProcessInfo.RedirectStandardOutput = $true
    $ProcessInfo.UseShellExecute = $false
    $ProcessInfo.CreateNoWindow = $true
    
    $P = [System.Diagnostics.Process]::Start($ProcessInfo)
    $P.WaitForExit()
    
    if ($P.ExitCode -eq 0) {
        Log-Msg "Cài đặt Ventoy THÀNH CÔNG!"
    } else {
        Log-Msg "Cài đặt thất bại. Mã lỗi: $($P.ExitCode). Vui lòng thử lại hoặc format USB thủ công."
        return
    }

    # 3. POST-INSTALL (Đổi tên & Theme)
    Log-Msg "Đợi USB mount lại..."
    Start-Sleep -Seconds 5
    Get-Disk | Update-Disk
    
    # Tìm ổ Ventoy mới (thường là partition lớn nhất trên disk đó)
    $NewPart = Get-Partition -DiskNumber $DiskID | Where-Object { $_.Type -eq "Basic" -or $_.Type -eq "IFS" } | Sort-Object Size -Descending | Select -First 1
    if ($NewPart) {
        # Đổi tên Label
        Set-Volume -Partition $NewPart -NewFileSystemLabel $Label -Confirm:$false
        Log-Msg "Đã đổi tên ổ thành: $Label"
        
        $UsbRoot = "$($NewPart.DriveLetter):"
        
        # Tạo cấu hình Theme (ventoy.json)
        if ($ChkTheme.Checked) {
            Log-Msg "Đang cấu hình giao diện..."
            $VentoyConfigDir = "$UsbRoot\ventoy"
            if (!(Test-Path $VentoyConfigDir)) { New-Item -Path $VentoyConfigDir -ItemType Directory | Out-Null }
            
            # JSON cấu hình đơn giản nhưng đẹp (Dark Mode)
            $JsonContent = @{
                "control" = @{
                    "theme" = @{
                        "display_mode" = "GUI"
                        "gfxmode" = "1920x1080"
                    }
                }
                "theme" = @{
                    "file" = "/ventoy/theme/phattan/theme.txt"
                }
            } | ConvertTo-Json -Depth 5
            
            # Ở đây ta tạo một file json cơ bản để Ventoy nhận diện
            $JsonConfig = @"
{
    "control": [
        { "VTOY_DEFAULT_MENU_MODE": "0" },
        { "VTOY_FILT_DOT_UNDERSCORE_FILE": "1" }
    ],
    "theme": {
        "file": "/ventoy/theme/theme.txt",
        "gfxmode": "1920x1080"
    },
    "menu_alias": [
        {
            "image": "/ventoy/ventoy.png",
            "alias": "PHAT TAN RESCUE USB"
        }
    ]
}
"@
            $JsonConfig | Out-File "$VentoyConfigDir\ventoy.json" -Encoding UTF8
            Log-Msg "Đã tạo file cấu hình ventoy.json"
        }
        
        # Tạo thư mục ISO mẫu
        New-Item -Path "$UsbRoot\ISO_Windows" -ItemType Directory -Force | Out-Null
        New-Item -Path "$UsbRoot\ISO_Linux" -ItemType Directory -Force | Out-Null
        New-Item -Path "$UsbRoot\ISO_CuuHo" -ItemType Directory -Force | Out-Null
        
        Log-Msg ">>> HOÀN TẤT TOÀN BỘ! <<<"
        Log-Msg "Copy file ISO vào ổ $UsbRoot và boot nhé!"
        Invoke-Item $UsbRoot
    }
}

$BtnRef.Add_Click({ Load-USB })

$BtnStart.Add_Click({
    if ($CbUSB.SelectedItem -match "Disk (\d+)") {
        $DiskID = $Matches[1]
        if ([System.Windows.Forms.MessageBox]::Show("Toàn bộ dữ liệu trên DISK $DiskID sẽ bị xóa sạch!`nBạn có chắc chắn không?", "CẢNH BÁO", "YesNo", "Warning") -eq "Yes") {
            $BtnStart.Enabled = $false; $Form.Cursor = "WaitCursor"
            Install-Ventoy $DiskID $CbStyle.SelectedItem $TxtLabel.Text
            $BtnStart.Enabled = $true; $Form.Cursor = "Default"
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Vui lòng chọn USB!")
    }
})

$Form.Add_Load({ Load-USB })
[System.Windows.Forms.Application]::Run($Form)
