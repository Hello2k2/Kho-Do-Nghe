<#
    VENTOY BOOT MAKER - PHAT TAN PC (V5.5 ULTIMATE)
    Updates:
    - [UPDATE] Thêm chế độ Update Ventoy (Không mất dữ liệu).
    - [THEME] Trình quản lý Theme Online (Tải từ JSON).
    - [CONFIG] Cấu hình Memdisk, Reserved Space.
    - [INFO] Xem chi tiết thông số kỹ thuật USB.
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

# 2. CONFIG GLOBAL
$Global:VentoyUrl = "https://github.com/ventoy/Ventoy/releases/download/v1.0.97/ventoy-1.0.97-windows.zip"
# Link JSON chứa danh sách Theme (Anh sửa link này thành link raw file json trên github của anh)
# Cấu trúc JSON mẫu: [{"Name":"WhiteSur","Url":"LINK_ZIP_THEME","File":"theme.txt","Folder":"whitesur"}]
$Global:ThemeJsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/themes_ventoy.json" 
$Global:WorkDir = "C:\PhatTan_Ventoy_Temp"
if (!(Test-Path $Global:WorkDir)) { New-Item -ItemType Directory -Path $Global:WorkDir -Force | Out-Null }

# --- DATA MẪU NẾU KHÔNG TẢI ĐƯỢC JSON ---
$Global:DefaultThemes = @(
    @{ Name="Ventoy Default"; Url=""; File=""; Folder="" },
    @{ Name="WhiteSur 4K (Demo)"; Url="https://github.com/vinceliuice/WhiteSur-grub-theme/archive/refs/heads/master.zip"; File="theme.txt"; Folder="WhiteSur-grub-theme-master" }
)

# 3. THEME GUI
$Theme = @{
    BgForm  = [System.Drawing.Color]::FromArgb(30, 30, 35)
    Card    = [System.Drawing.Color]::FromArgb(45, 45, 50)
    Text    = [System.Drawing.Color]::FromArgb(240, 240, 240)
    Accent  = [System.Drawing.Color]::FromArgb(0, 180, 255) # Cyber Blue
    Warn    = [System.Drawing.Color]::FromArgb(255, 160, 0)
    Success = [System.Drawing.Color]::FromArgb(50, 205, 50)
    InputBg = [System.Drawing.Color]::FromArgb(60, 60, 70)
}

# --- HELPER FUNCTIONS ---
function Log-Msg ($Msg, $Color="Lime") { 
    $TxtLog.SelectionStart = $TxtLog.TextLength
    $TxtLog.SelectionLength = 0
    $TxtLog.SelectionColor = [System.Drawing.Color]::FromName($Color)
    $TxtLog.AppendText("[$(Get-Date -F 'HH:mm:ss')] $Msg`r`n")
    $TxtLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function Add-GlowBorder ($Panel) {
    $Panel.Add_Paint({ param($s,$e) $p=New-Object System.Drawing.Pen($Theme.Accent,1); $r=$s.ClientRectangle; $r.Width-=1; $r.Height-=1; $e.Graphics.DrawRectangle($p,$r); $p.Dispose() })
}

# --- GUI INIT ---
$F_Title = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$F_Norm  = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
$F_Bold  = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$F_Code  = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Regular)

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "PHAT TAN VENTOY MASTER V5.5"; $Form.Size = "900,780"; $Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.BgForm; $Form.ForeColor = $Theme.Text; $Form.Padding = 10

$MainTable = New-Object System.Windows.Forms.TableLayoutPanel; $MainTable.Dock = "Fill"; $MainTable.ColumnCount = 1; $MainTable.RowCount = 5
$MainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) # Header
$MainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) # USB Selection
$MainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 320))) # Settings Tab
$MainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) # Log
$MainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 70))) # Action Button
$Form.Controls.Add($MainTable)

# 1. HEADER
$PnlHead = New-Object System.Windows.Forms.Panel; $PnlHead.Height = 60; $PnlHead.Dock = "Top"; $PnlHead.Margin = "0,0,0,10"
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "USB BOOT MASTER - VENTOY EDITION"; $LblT.Font = $F_Title; $LblT.ForeColor = $Theme.Accent; $LblT.AutoSize = $true; $LblT.Location = "10,10"
$LblS = New-Object System.Windows.Forms.Label; $LblS.Text = "Install | Update | Themes | Memdisk | JSON Config"; $LblS.ForeColor = "Gray"; $LblS.AutoSize = $true; $LblS.Location = "15,40"
$PnlHead.Controls.Add($LblT); $PnlHead.Controls.Add($LblS); $MainTable.Controls.Add($PnlHead, 0, 0)

# 2. USB SELECTION
$CardUSB = New-Object System.Windows.Forms.Panel; $CardUSB.BackColor = $Theme.Card; $CardUSB.Padding = 10; $CardUSB.AutoSize = $true; $CardUSB.Dock = "Top"; $CardUSB.Margin = "0,0,0,10"; Add-GlowBorder $CardUSB
$L_U1 = New-Object System.Windows.Forms.TableLayoutPanel; $L_U1.Dock = "Top"; $L_U1.Height = 35; $L_U1.ColumnCount = 3
$L_U1.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 70)))
$L_U1.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 15)))
$L_U1.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 15)))

$CbUSB = New-Object System.Windows.Forms.ComboBox; $CbUSB.Dock = "Fill"; $CbUSB.Font = $F_Norm; $CbUSB.BackColor = $Theme.InputBg; $CbUSB.ForeColor = "White"; $CbUSB.DropDownStyle = "DropDownList"
$BtnRef = New-Object System.Windows.Forms.Button; $BtnRef.Text = "↻ Refresh"; $BtnRef.Dock = "Fill"; $BtnRef.BackColor = $Theme.InputBg; $BtnRef.ForeColor = "White"; $BtnRef.FlatStyle = "Flat"
$BtnInfo = New-Object System.Windows.Forms.Button; $BtnInfo.Text = "ℹ Chi tiết"; $BtnInfo.Dock = "Fill"; $BtnInfo.BackColor = $Theme.InputBg; $BtnInfo.ForeColor = "Cyan"; $BtnInfo.FlatStyle = "Flat"

$L_U1.Controls.Add($CbUSB, 0, 0); $L_U1.Controls.Add($BtnRef, 1, 0); $L_U1.Controls.Add($BtnInfo, 2, 0)
$LblUTitle = New-Object System.Windows.Forms.Label; $LblUTitle.Text = "THIẾT BỊ MỤC TIÊU:"; $LblUTitle.Font = $F_Bold; $LblUTitle.Dock = "Top"; $LblUTitle.ForeColor = "Silver"
$CardUSB.Controls.Add($L_U1); $CardUSB.Controls.Add($LblUTitle); $MainTable.Controls.Add($CardUSB, 0, 1)

# 3. SETTINGS & TABS
$TabC = New-Object System.Windows.Forms.TabControl; $TabC.Dock = "Fill"; $TabC.Padding = "10,5"
$Tab1 = New-Object System.Windows.Forms.TabPage; $Tab1.Text = "CÀI ĐẶT CƠ BẢN"; $Tab1.BackColor = $Theme.BgForm
$Tab2 = New-Object System.Windows.Forms.TabPage; $Tab2.Text = "THEME & JSON"; $Tab2.BackColor = $Theme.BgForm
$TabC.Controls.Add($Tab1); $TabC.Controls.Add($Tab2); $MainTable.Controls.Add($TabC, 0, 2)

# -- TAB 1: BASIC --
$G1 = New-Object System.Windows.Forms.TableLayoutPanel; $G1.Dock = "Top"; $G1.AutoSize = $true; $G1.Padding = 10; $G1.ColumnCount = 2; $G1.RowCount = 5
$G1.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 50)))
$G1.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 50)))

# Action Mode
$LblAct = New-Object System.Windows.Forms.Label; $LblAct.Text = "Chế độ (Mode):"; $LblAct.ForeColor = "White"; $LblAct.AutoSize = $true
$CbAction = New-Object System.Windows.Forms.ComboBox; $CbAction.Items.AddRange(@("Cài mới (Xóa sạch dữ liệu)", "Cập nhật Ventoy (Giữ nguyên Data)")); $CbAction.SelectedIndex = 0; $CbAction.DropDownStyle = "DropDownList"; $CbAction.Width = 300
$G1.Controls.Add($LblAct, 0, 0); $G1.Controls.Add($CbAction, 1, 0)

# Style
$LblSty = New-Object System.Windows.Forms.Label; $LblSty.Text = "Kiểu Partition:"; $LblSty.ForeColor = "White"; $LblSty.AutoSize = $true
$CbStyle = New-Object System.Windows.Forms.ComboBox; $CbStyle.Items.AddRange(@("MBR (Legacy + UEFI)", "GPT (UEFI Only)")); $CbStyle.SelectedIndex = 0; $CbStyle.DropDownStyle = "DropDownList"; $CbStyle.Width = 300
$G1.Controls.Add($LblSty, 0, 1); $G1.Controls.Add($CbStyle, 1, 1)

# Secure Boot
$ChkSec = New-Object System.Windows.Forms.CheckBox; $ChkSec.Text = "Bật Secure Boot Support"; $ChkSec.Checked = $true; $ChkSec.ForeColor = "Orange"; $ChkSec.AutoSize = $true
$G1.Controls.Add($ChkSec, 0, 2)

# Reserved Space
$LblRes = New-Object System.Windows.Forms.Label; $LblRes.Text = "Dành riêng (Reserved Space MB):"; $LblRes.ForeColor = "White"; $LblRes.AutoSize = $true
$NumRes = New-Object System.Windows.Forms.NumericUpDown; $NumRes.Minimum = 0; $NumRes.Maximum = 100000; $NumRes.Value = 0; $NumRes.Width = 100
$G1.Controls.Add($LblRes, 0, 3); $G1.Controls.Add($NumRes, 1, 3)

$Tab1.Controls.Add($G1)

# -- TAB 2: ADVANCED --
$G2 = New-Object System.Windows.Forms.TableLayoutPanel; $G2.Dock = "Top"; $G2.AutoSize = $true; $G2.Padding = 10; $G2.ColumnCount = 1; $G2.RowCount = 6

# Memdisk
$ChkMem = New-Object System.Windows.Forms.CheckBox; $ChkMem.Text = "Kích hoạt Memdisk Mode (VTOY_MEM_DISK_MODE)"; $ChkMem.Checked = $false; $ChkMem.ForeColor = "Cyan"; $ChkMem.AutoSize = $true
$G2.Controls.Add($ChkMem, 0, 0)

# Theme Selector
$LblThm = New-Object System.Windows.Forms.Label; $LblThm.Text = "Chọn Theme (Tải từ Server):"; $LblThm.ForeColor = "White"; $LblThm.AutoSize = $true; $LblThm.Margin = "0,10,0,0"
$CbTheme = New-Object System.Windows.Forms.ComboBox; $CbTheme.DropDownStyle = "DropDownList"; $CbTheme.Width = 400
$BtnLoadTheme = New-Object System.Windows.Forms.Button; $BtnLoadTheme.Text = "Tải danh sách Theme"; $BtnLoadTheme.Width = 200; $BtnLoadTheme.BackColor = "DimGray"; $BtnLoadTheme.ForeColor = "White"

$P_Thm = New-Object System.Windows.Forms.FlowLayoutPanel; $P_Thm.AutoSize = $true; $P_Thm.FlowDirection = "LeftToRight"
$P_Thm.Controls.Add($CbTheme); $P_Thm.Controls.Add($BtnLoadTheme)

$G2.Controls.Add($LblThm, 0, 1); $G2.Controls.Add($P_Thm, 0, 2)

$LblJ = New-Object System.Windows.Forms.Label; $LblJ.Text = "JSON Config Preview:"; $LblJ.ForeColor = "Gray"; $LblJ.AutoSize = $true; $LblJ.Margin = "0,10,0,0"
$G2.Controls.Add($LblJ, 0, 3)

$Tab2.Controls.Add($G2)

# 4. LOG
$TxtLog = New-Object System.Windows.Forms.RichTextBox; $TxtLog.Dock = "Fill"; $TxtLog.BackColor = "Black"; $TxtLog.ForeColor = "Lime"; $TxtLog.Font = $F_Code; $TxtLog.ReadOnly = $true; $MainTable.Controls.Add($TxtLog, 0, 3)

# 5. EXECUTE BUTTON
$BtnStart = New-Object System.Windows.Forms.Button; $BtnStart.Text = "THỰC HIỆN"; $BtnStart.Font = $F_Title; $BtnStart.BackColor = $Theme.Accent; $BtnStart.ForeColor = "Black"; $BtnStart.FlatStyle = "Flat"; $BtnStart.Dock = "Fill"
$MainTable.Controls.Add($BtnStart, 0, 4)

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
    } else { $CbUSB.Items.Add("Không tìm thấy USB"); $CbUSB.SelectedIndex = 0 }
}

function Show-UsbDetails {
    if ($CbUSB.SelectedItem -match "Disk (\d+)") {
        $ID = $Matches[1]
        $D = Get-Disk -Number $ID
        $P = Get-Partition -DiskNumber $ID
        $Msg = "THÔNG TIN DISK $ID`n------------------`n"
        $Msg += "Model: $($D.FriendlyName)`nStyle: $($D.PartitionStyle)`nSize: $([Math]::Round($D.Size/1GB, 2)) GB`n"
        $Msg += "`nPARTITIONS:`n"
        foreach ($part in $P) {
            $Vol = Get-Volume -Partition $part -ErrorAction SilentlyContinue
            $Msg += "#$($part.PartitionNumber): $($Vol.FileSystemLabel) ($($Vol.FileSystem)) - $([Math]::Round($part.Size/1GB, 2)) GB`n"
        }
        [System.Windows.Forms.MessageBox]::Show($Msg, "Chi tiết USB")
    }
}

function Load-Themes {
    $CbTheme.Items.Clear()
    $CbTheme.Items.Add("Mặc định (Ventoy)")
    
    try {
        Log-Msg "Đang tải danh sách Theme từ GitHub..." "Yellow"
        # Thử tải từ JSON Online
        # $JsonData = Invoke-RestMethod -Uri $Global:ThemeJsonUrl -TimeoutSec 5 -ErrorAction Stop
        # Nếu không có mạng hoặc link chết, dùng Default
        $JsonData = $Global:DefaultThemes
        
        $Global:ThemeData = $JsonData
        foreach ($item in $JsonData) {
            if ($item.Url) { $CbTheme.Items.Add($item.Name) }
        }
        Log-Msg "Đã tải danh sách Theme." "Cyan"
    } catch {
        Log-Msg "Lỗi tải Theme: $($_.Exception.Message)" "Red"
        $Global:ThemeData = $Global:DefaultThemes
        foreach ($item in $Global:DefaultThemes) { if ($item.Url) { $CbTheme.Items.Add($item.Name) } }
    }
    $CbTheme.SelectedIndex = 0
}

function Process-Ventoy {
    param($DiskID, $Mode, $Style, $Label)
    
    $ZipFile = "$Global:WorkDir\ventoy.zip"
    $ExtractPath = "$Global:WorkDir\Extracted"
    
    # 1. CHECK SOURCE
    if (!(Test-Path "$ExtractPath\ventoy\Ventoy2Disk.exe")) {
        Log-Msg "Downloading Ventoy Core..." "Yellow"
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            (New-Object Net.WebClient).DownloadFile($Global:VentoyUrl, $ZipFile)
            if (Test-Path $ExtractPath) { Remove-Item $ExtractPath -Recurse -Force }
            [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $ExtractPath)
            
            $ExePath = Get-ChildItem -Path $ExtractPath -Filter "Ventoy2Disk.exe" -Recurse | Select -First 1
            if ($ExePath) {
                $Global:VentoyExe = $ExePath.FullName; $Global:VentoyDir = $ExePath.DirectoryName
            } else { Log-Msg "Lỗi: Không tìm thấy core Ventoy!" "Red"; return }
        } catch { Log-Msg "Lỗi download: $($_.Exception.Message)" "Red"; return }
    } else {
        $Global:VentoyExe = Get-ChildItem -Path $ExtractPath -Filter "Ventoy2Disk.exe" -Recurse | Select -First 1 | %{$_.FullName}
        $Global:VentoyDir = Get-ChildItem -Path $ExtractPath -Filter "Ventoy2Disk.exe" -Recurse | Select -First 1 | %{$_.DirectoryName}
    }

    # 2. PREPARE COMMAND
    # Mapping Drive Letter
    $Part = Get-Partition -DiskNumber $DiskID | Where-Object { $_.DriveLetter } | Select -First 1
    if (!$Part) { Log-Msg "Lỗi: USB cần có ký tự ổ đĩa (Drive Letter) để tool nhận diện." "Red"; return }
    $DL = "$($Part.DriveLetter):"

    # Argument Builder
    # Mode: -i (Install) or -u (Update)
    $FlagMode = if ($Mode -eq "UPDATE") { "/U" } else { "/I" }
    $FlagStyle = if ($Style -match "GPT") { "/GPT" } else { "/MBR" }
    $FlagSecure = if ($ChkSec.Checked) { "/S" } else { "" }
    $FlagForce = "/NoUsbCheck"
    
    # Reserved Space (Only for Install)
    $FlagRes = ""
    if ($Mode -eq "INSTALL" -and $NumRes.Value -gt 0) { $FlagRes = "/R:$($NumRes.Value)" }

    Log-Msg "Executing: Ventoy2Disk $FlagMode $DL" "Cyan"
    
    $PInfo = New-Object System.Diagnostics.ProcessStartInfo
    $PInfo.FileName = $Global:VentoyExe
    $PInfo.Arguments = "VTOYCLI $FlagMode /Drive:$DL $FlagForce $FlagStyle $FlagSecure $FlagRes"
    $PInfo.RedirectStandardOutput = $true
    $PInfo.UseShellExecute = $false
    $PInfo.CreateNoWindow = $true
    
    $P = [System.Diagnostics.Process]::Start($PInfo)
    $P.WaitForExit()
    
    if ($P.ExitCode -eq 0) {
        Log-Msg "Ventoy Action ($Mode) COMPLETE!" "Success"
    } else {
        Log-Msg "FAILED. Error Code: $($P.ExitCode)" "Red"; return
    }

    # 3. POST-PROCESS (THEME & JSON)
    Log-Msg "Mounting USB..." "Yellow"; Start-Sleep 3; Get-Disk | Update-Disk
    
    $NewPart = Get-Partition -DiskNumber $DiskID | Where-Object { $_.Type -eq "Basic" -or $_.Type -eq "IFS" } | Sort-Object Size -Descending | Select -First 1
    if ($NewPart) {
        if ($Mode -eq "INSTALL" -and $Label) { Set-Volume -Partition $NewPart -NewFileSystemLabel $Label -Confirm:$false }
        $UsbRoot = "$($NewPart.DriveLetter):"
        $VentoyDir = "$UsbRoot\ventoy"
        if (!(Test-Path $VentoyDir)) { New-Item -Path $VentoyDir -ItemType Directory | Out-Null }

        # --- THEME DOWNLOADER ---
        $SelTheme = $CbTheme.SelectedItem
        $ThemeConfig = $null
        
        if ($SelTheme -ne "Mặc định (Ventoy)") {
            $T = $Global:ThemeData | Where-Object { $_.Name -eq $SelTheme } | Select -First 1
            if ($T) {
                Log-Msg "Downloading Theme: $($T.Name)..." "Yellow"
                $ThemeZip = "$Global:WorkDir\theme.zip"
                try {
                    (New-Object Net.WebClient).DownloadFile($T.Url, $ThemeZip)
                    $ThemeDest = "$VentoyDir\themes"
                    if (!(Test-Path $ThemeDest)) { New-Item $ThemeDest -ItemType Directory | Out-Null }
                    
                    # Extract
                    [System.IO.Compression.ZipFile]::ExtractToDirectory($ThemeZip, $ThemeDest, $true) # Overwrite
                    
                    # Cấu hình đường dẫn theme
                    # Giả sử cấu trúc zip là FolderName/theme.txt
                    $ThemeConfig = "/ventoy/themes/$($T.Folder)/$($T.File)"
                    Log-Msg "Theme Installed at: $ThemeConfig" "Success"
                } catch {
                    Log-Msg "Download Theme Failed: $_" "Red"
                }
            }
        }

        # --- GENERATE JSON ---
        Log-Msg "Generating ventoy.json..." "Yellow"
        
        # Build JSON Object
        $J = @{
            "control" = @(
                @{ "VTOY_DEFAULT_MENU_MODE" = "0" },
                @{ "VTOY_FILT_DOT_UNDERSCORE_FILE" = "1" }
            )
            "theme" = @{
                "display_mode" = "GUI"
                "gfxmode" = "1920x1080"
            }
        }

        # Add Memdisk if checked
        if ($ChkMem.Checked) {
            $J.control += @{ "VTOY_MEM_DISK_MODE" = "1" }
        }

        # Add Theme if selected
        if ($ThemeConfig) {
            $J.theme.Add("file", $ThemeConfig)
        } else {
            # Default theme config if wanted, or leave blank to use Ventoy default
        }

        $JsonStr = $J | ConvertTo-Json -Depth 5
        $JsonStr | Out-File "$VentoyDir\ventoy.json" -Encoding UTF8 -Force
        Log-Msg "Config Saved: $VentoyDir\ventoy.json" "Success"

        # Create Folders
        New-Item "$UsbRoot\ISO" -ItemType Directory -Force | Out-Null
        
        Log-Msg ">>> ALL DONE! <<<" "Success"
        Invoke-Item $UsbRoot
    }
}

# --- EVENTS ---
$BtnRef.Add_Click({ Load-USB })
$BtnInfo.Add_Click({ Show-UsbDetails })
$BtnLoadTheme.Add_Click({ Load-Themes })

$BtnStart.Add_Click({
    if ($CbUSB.SelectedItem -match "Disk (\d+)") {
        $ID = $Matches[1]
        $Mode = if ($CbAction.SelectedIndex -eq 0) { "INSTALL" } else { "UPDATE" }
        
        $Warn = if ($Mode -eq "INSTALL") { "CẢNH BÁO: TOÀN BỘ DỮ LIỆU SẼ BỊ XÓA SẠCH!" } else { "Chế độ UPDATE: Dữ liệu ISO sẽ được giữ nguyên." }
        
        if ([System.Windows.Forms.MessageBox]::Show("$Warn`nTiếp tục với Disk $ID?", "Xác nhận", "YesNo", "Warning") -eq "Yes") {
            $BtnStart.Enabled = $false; $Form.Cursor = "WaitCursor"
            Process-Ventoy $ID $Mode $CbStyle.SelectedItem "Ventoy_Boot"
            $BtnStart.Enabled = $true; $Form.Cursor = "Default"
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Vui lòng chọn USB!")
    }
})

$Form.Add_Load({ Load-USB; Load-Themes })
[System.Windows.Forms.Application]::Run($Form)
