# --- 1. FORCE ADMIN (QUAN TRỌNG ĐỂ BACKUP DRIVER/LICENSE) ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "BACKUP CENTER PRO - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(700, 550)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Tiêu đề
$LblTitle = New-Object System.Windows.Forms.Label
$LblTitle.Text = "DATA BACKUP SOLUTION"
$LblTitle.Font = New-Object System.Drawing.Font("Impact", 18)
$LblTitle.ForeColor = "Cyan"
$LblTitle.AutoSize = $true; $LblTitle.Location = "20, 15"
$Form.Controls.Add($LblTitle)

# --- 1. CHỌN NƠI LƯU ---
$GbDest = New-Object System.Windows.Forms.GroupBox
$GbDest.Text = "1. Chon Noi Luu Tru (Destination)"
$GbDest.Location = "20, 60"; $GbDest.Size = "645, 80"; $GbDest.ForeColor = "Yellow"
$Form.Controls.Add($GbDest)

$TxtDest = New-Object System.Windows.Forms.TextBox
$TxtDest.Location = "20, 30"; $TxtDest.Size = "480, 30"; $TxtDest.Font = "Segoe UI, 10"
# Tự động tìm ổ D hoặc E, nếu không có thì lấy ổ C
if (Test-Path "D:\") { $TxtDest.Text = "D:\PhatTan_Backup" } elseif (Test-Path "E:\") { $TxtDest.Text = "E:\PhatTan_Backup" } else { $TxtDest.Text = "C:\PhatTan_Backup" }
$GbDest.Controls.Add($TxtDest)

$BtnBrowse = New-Object System.Windows.Forms.Button
$BtnBrowse.Text = "CHON THU MUC..."
$BtnBrowse.Location = "510, 28"; $BtnBrowse.Size = "115, 30"; $BtnBrowse.BackColor = "DimGray"; $BtnBrowse.ForeColor = "White"
$BtnBrowse.Add_Click({
    $FBD = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($FBD.ShowDialog() -eq "OK") { $TxtDest.Text = $FBD.SelectedPath + "\PhatTan_Backup" }
})
$GbDest.Controls.Add($BtnBrowse)

# --- 2. CHỌN DỮ LIỆU ---
$GbSource = New-Object System.Windows.Forms.GroupBox
$GbSource.Text = "2. Chon Du Lieu Can Sao Luu"
$GbSource.Location = "20, 150"; $GbSource.Size = "645, 120"; $GbSource.ForeColor = "Lime"
$Form.Controls.Add($GbSource)

# Hàm tạo Checkbox cho gọn code
function Add-Chk ($P, $T, $X, $Y, $Def=$true) { 
    $c = New-Object System.Windows.Forms.CheckBox; $c.Text=$T; $c.Location="$X,$Y"; $c.AutoSize=$true; $c.Checked=$Def; $c.Font="Segoe UI, 9"; $c.ForeColor="White"; $P.Controls.Add($c); return $c 
}

$cWifi = Add-Chk $GbSource "Wifi Passwords (XML)" 20 30
$cDrv  = Add-Chk $GbSource "Drivers (Export All)" 20 60
$cLic  = Add-Chk $GbSource "Windows License (Tokens)" 20 90

$cData = Add-Chk $GbSource "User Data (Desktop, Doc, Down...)" 250 30
$cZalo = Add-Chk $GbSource "Zalo PC Data (Mess, File)" 250 60
$cChrome = Add-Chk $GbSource "Chrome Profile" 480 30
$cEdge = Add-Chk $GbSource "Edge Profile" 480 60 # Mới thêm

# --- LOG & PROGRESS ---
$TxtLog = New-Object System.Windows.Forms.TextBox
$TxtLog.Multiline = $true; $TxtLog.ScrollBars = "Vertical"
$TxtLog.Location = "20, 280"; $TxtLog.Size = "645, 150"; $TxtLog.BackColor = "Black"; $TxtLog.ForeColor = "Cyan"; $TxtLog.ReadOnly = $true; $TxtLog.Font = "Consolas, 9"
$Form.Controls.Add($TxtLog)

$ProgressBar = New-Object System.Windows.Forms.ProgressBar
$ProgressBar.Location = "20, 440"; $ProgressBar.Size = "645, 10"
$Form.Controls.Add($ProgressBar)

# Hàm Log
function Log ($Msg) {
    $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $Msg`r`n")
    $TxtLog.SelectionStart = $TxtLog.Text.Length; $TxtLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

# Hàm Robocopy Wrapper (Cơ chế xịn)
function Smart-Copy ($Src, $Dst, $Desc) {
    if (Test-Path $Src) {
        Log ">>> Backing up: $Desc..."
        # /MT:16 = Multi-Thread 16 luồng (Copy siêu nhanh)
        # /E = Copy cả subfolder
        # /NFL /NDL = Không hiện tên file/folder trong log gốc (để log của mình sạch sẽ)
        # /R:0 /W:0 = Không retry nếu lỗi (bỏ qua luôn cho nhanh)
        $Proc = Start-Process "robocopy.exe" -ArgumentList "`"$Src`" `"$Dst`" /E /MT:16 /R:0 /W:0 /NFL /NDL" -NoNewWindow -PassThru -Wait
        Log " [OK] Done ($Desc)"
    } else {
        Log " [SKIP] Khong tim thay nguon: $Desc"
    }
}

# --- NÚT START ---
$BtnStart = New-Object System.Windows.Forms.Button
$BtnStart.Text = "TIEN HANH BACKUP (START)"
$BtnStart.Location = "20, 460"; $BtnStart.Size = "645, 40"
$BtnStart.BackColor = "Green"; $BtnStart.ForeColor = "White"; $BtnStart.Font = "Segoe UI, 12, Bold"; $BtnStart.FlatStyle = "Flat"

$BtnStart.Add_Click({
    $BaseDir = $TxtDest.Text
    if (!$BaseDir) { [System.Windows.Forms.MessageBox]::Show("Chua chon noi luu!", "Loi"); return }
    
    # Tạo folder theo ngày giờ (Tránh ghi đè)
    $TimeStamp = Get-Date -Format "dd-MM-yyyy_HH-mm"
    $FinalDir = "$BaseDir\_Backup_$TimeStamp"
    
    $BtnStart.Enabled = $false
    $ProgressBar.Style = "Marquee" # Chạy liên tục
    $TxtLog.Text = "--- STARTING BACKUP PROCESS ---`r`nLu tai: $FinalDir`r`n"
    
    try {
        New-Item -ItemType Directory -Path $FinalDir -Force | Out-Null
        
        # 1. WIFI
        if ($cWifi.Checked) {
            Log "Exporting Wifi Profiles..."
            New-Item -ItemType Directory -Path "$FinalDir\Wifi" -Force | Out-Null
            netsh wlan export profile key=clear folder="$FinalDir\Wifi" | Out-Null
            Log " [OK] Wifi Done."
        }
        
        # 2. DRIVERS (DISM)
        if ($cDrv.Checked) {
            Log "Exporting Drivers (DISM)... Please wait!"
            New-Item -ItemType Directory -Path "$FinalDir\Drivers" -Force | Out-Null
            Start-Process "dism.exe" -ArgumentList "/online /export-driver /destination:`"$FinalDir\Drivers`"" -NoNewWindow -Wait
            Log " [OK] Drivers Exported."
        }
        
        # 3. USER DATA (Robocopy)
        if ($cData.Checked) {
            $UserFolders = @("Desktop", "Documents", "Downloads", "Pictures", "Videos", "Music")
            foreach ($Folder in $UserFolders) {
                Smart-Copy "$env:USERPROFILE\$Folder" "$FinalDir\UserData\$Folder" $Folder
            }
        }
        
        # 4. ZALO PC
        if ($cZalo.Checked) {
            Smart-Copy "$env:APPDATA\ZaloPC" "$FinalDir\Apps\ZaloPC" "Zalo PC Data"
        }
        
        # 5. LICENSE
        if ($cLic.Checked) {
            Log "Backing up License (Tokens.dat)..."
            $LicDest = "$FinalDir\License"; New-Item -ItemType Directory -Path $LicDest -Force | Out-Null
            try { Copy-Item "C:\Windows\System32\spp\store" $LicDest -Recurse -Force -ErrorAction SilentlyContinue; Log " [OK] License Done." } catch { Log " [ERR] License Fail." }
        }
        
        # 6. BROWSERS
        if ($cChrome.Checked) {
            Smart-Copy "$env:LOCALAPPDATA\Google\Chrome\User Data" "$FinalDir\Apps\Chrome" "Chrome Profile"
        }
        if ($cEdge.Checked) {
            Smart-Copy "$env:LOCALAPPDATA\Microsoft\Edge\User Data" "$FinalDir\Apps\Edge" "Edge Profile"
        }

        $ProgressBar.Style = "Blocks"; $ProgressBar.Value = 100
        Log "--------------------------------"
        Log "BACKUP COMPLETED SUCCESSFULLY!"
        [System.Windows.Forms.MessageBox]::Show("Da Backup Xong!`nThu muc: $FinalDir", "Phat Tan PC")
        Invoke-Item $FinalDir
        
    } catch {
        Log "CRITICAL ERROR: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show("Loi Backup: $($_.Exception.Message)", "Error")
    }
    
    $BtnStart.Enabled = $true
})

$Form.Controls.Add($BtnStart)
$Form.ShowDialog() | Out-Null
