<#
    VENTOY BOOT MAKER - PHAT TAN PC (V13.5 MEMTEST ZIP FIX)
    Updates:
    - [FIX] Memtest v8.00: Tải ZIP -> Giải nén -> Lấy file ISO (Fix lỗi boot).
    - [THEME] Giữ nguyên tính năng giải nén theme 2 lớp (đang chạy ngon).
#>

# --- 0. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $Arg = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell.exe -Verb RunAs -ArgumentList $Arg
    Exit
}

# 1. SETUP
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.IO.Compression.FileSystem

# 2. CONFIG
$Global:VentoyRepo = "https://api.github.com/repos/ventoy/Ventoy/releases/latest"
$Global:VentoyDirectLink = "https://github.com/ventoy/Ventoy/releases/download/v1.0.99/ventoy-1.0.99-windows.zip"
$Global:MasUrl = "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version-KL/MAS_AIO.cmd"
$Global:ThemeConfigUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/refs/heads/main/themes.json" 
$Global:7zToolUrl = "https://github.com/develar/7zip-bin/raw/master/win/x64/7za.exe"

# Link Memtest v8.00 (Dạng ZIP)
$Global:MemtestFallback = "https://www.memtest.org/download/v8.00/mt86plus_8.00_x86_64.iso.zip"

$Global:WorkDir = "C:\PhatTan_Ventoy_Temp"
$Global:DebugFile = "$PSScriptRoot\debug_log.txt" 
$Global:VersionFile = "$Global:WorkDir\version_info.txt"
if (!(Test-Path $Global:WorkDir)) { New-Item -ItemType Directory -Path $Global:WorkDir -Force | Out-Null }

"--- START LOG $(Get-Date) ---" | Out-File $Global:DebugFile -Encoding UTF8 -Force

# 3. GUI
$Theme = @{
    BgForm  = [System.Drawing.Color]::FromArgb(30, 30, 35)
    Card    = [System.Drawing.Color]::FromArgb(45, 45, 50)
    Text    = [System.Drawing.Color]::FromArgb(240, 240, 240)
    Accent  = [System.Drawing.Color]::FromArgb(0, 180, 255) 
    Warn    = [System.Drawing.Color]::FromArgb(255, 160, 0)
    Success = [System.Drawing.Color]::FromArgb(50, 205, 50)
    InputBg = [System.Drawing.Color]::FromArgb(60, 60, 70)
}

function Log-Msg ($Msg, $Color="Lime") { 
    try {
        $Form.Invoke([Action]{
            $TxtLog.SelectionStart = $TxtLog.TextLength
            $TxtLog.SelectionLength = 0
            $TxtLog.SelectionColor = [System.Drawing.Color]::FromName($Color)
            $TxtLog.AppendText("[$(Get-Date -F 'HH:mm:ss')] $Msg`r`n")
            $TxtLog.ScrollToCaret()
        })
    } catch {}
    try { "$(Get-Date -F 'HH:mm:ss')|$Msg" | Out-File $Global:DebugFile -Append -Encoding UTF8 } catch {}
}

function Get-Sha256 ($String) {
    $Sha = [System.Security.Cryptography.SHA256]::Create()
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($String)
    $Hash = $Sha.ComputeHash($Bytes)
    return [BitConverter]::ToString($Hash).Replace("-", "").ToLower()
}

function Download-File-Robust ($Url, $Dest) {
    $MaxRetries = 3; $RetryCount = 0; $Success = $false
    while (-not $Success -and $RetryCount -lt $MaxRetries) {
        try {
            $RetryCount++
            Invoke-WebRequest -Uri $Url -OutFile $Dest -UserAgent "Mozilla/5.0" -TimeoutSec 300 -ErrorAction Stop
            if ((Get-Item $Dest).Length -gt 1KB) { $Success = $true } else { throw "File quá nhỏ (<1KB)" }
        } catch {
            Log-Msg "Tải lỗi (Lần $RetryCount): $($_.Exception.Message)" "Yellow"
            Start-Sleep -Seconds 2
        }
    }
    if (-not $Success) { throw "Tải thất bại sau $MaxRetries lần thử!" }
}

function Download-File-Simple ($Url, $Dest) {
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($Url, $Dest)
}

# --- CORE FUNCTIONS ---
function Prepare-Ventoy-Core {
    $ZipFile = "$Global:WorkDir\ventoy.zip"
    $ExtractPath = "$Global:WorkDir\Extracted"
    $CurrentVer = if (Test-Path $Global:VersionFile) { Get-Content $Global:VersionFile } else { "v0.0.0" }
    
    Log-Msg "Check Ventoy Core (Current: $CurrentVer)..." "Cyan"
    try {
        $Assets = Invoke-RestMethod -Uri $Global:VentoyRepo -UseBasicParsing -TimeoutSec 5
        $LatestVer = $Assets.tag_name
        $WinZip = $Assets.assets | Where-Object { $_.name -match "windows.zip" } | Select -First 1
        $Url = $WinZip.browser_download_url
        
        if ($LatestVer -eq $CurrentVer -and (Test-Path "$ExtractPath\ventoy\Ventoy2Disk.exe")) {
            Log-Msg "Core đã mới nhất ($LatestVer). Skip tải." "Success"
            $Global:VentoyExe = Get-ChildItem -Path $ExtractPath -Filter "Ventoy2Disk.exe" -Recurse | Select -First 1 | %{$_.FullName}
            return
        }
        Log-Msg "Tải bản mới ($LatestVer)..." "Yellow"
        Download-File-Robust $Url $ZipFile
        if (Test-Path $ExtractPath) { Remove-Item $ExtractPath -Recurse -Force }
        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $ExtractPath)
        $LatestVer | Out-File $Global:VersionFile -Force
    } catch {
        Log-Msg "Offline/API Error. Dùng bản cũ..." "Yellow"
        if (Test-Path "$ExtractPath\ventoy\Ventoy2Disk.exe") {
             $Global:VentoyExe = Get-ChildItem -Path $ExtractPath -Filter "Ventoy2Disk.exe" -Recurse | Select -First 1 | %{$_.FullName}
        } else { Log-Msg "CRITICAL: Không tìm thấy Ventoy Core!" "Red" }
    }
    $Global:VentoyExe = Get-ChildItem -Path $ExtractPath -Filter "Ventoy2Disk.exe" -Recurse | Select -First 1 | %{$_.FullName}
}

function Extract-Recursive ($SourceFile, $DestDir) {
    if (!(Test-Path $SourceFile)) { throw "File nguồn không tồn tại!" }
    if (Test-Path $DestDir) { Remove-Item $DestDir -Recurse -Force }
    New-Item $DestDir -ItemType Directory | Out-Null

    Log-Msg "Bắt đầu giải nén: $([System.IO.Path]::GetFileName($SourceFile))" "Yellow"
    
    # Chuẩn bị 7-Zip
    $7zExe = "$Global:WorkDir\7za.exe"
    if (!(Test-Path $7zExe)) { try { Log-Msg "Tải engine 7-Zip..." "Gray"; Download-File-Robust $Global:7zToolUrl $7zExe } catch { throw "Lỗi tải 7-Zip!" } }

    # LẦN 1: Giải nén file gốc
    $Proc = Start-Process -FilePath $7zExe -ArgumentList "x `"$SourceFile`" -o`"$DestDir`" -y -bso0 -bsp0" -Wait -NoNewWindow -PassThru
    if ($Proc.ExitCode -ne 0) {
        try { [System.IO.Compression.ZipFile]::ExtractToDirectory($SourceFile, $DestDir); Log-Msg "Dùng Native Zip OK." "Success"; return }
        catch { throw "Giải nén thất bại!" }
    }

    # LẦN 2: Check TAR lồng
    $InnerTar = Get-ChildItem -Path $DestDir -Filter "*.tar" | Select -First 1
    if ($InnerTar) {
        Log-Msg "⚠️ Phát hiện file TAR lồng bên trong. Giải nén tiếp..." "Cyan"
        $Proc2 = Start-Process -FilePath $7zExe -ArgumentList "x `"$($InnerTar.FullName)`" -o`"$DestDir`" -y -bso0 -bsp0" -Wait -NoNewWindow -PassThru
        if ($Proc2.ExitCode -eq 0) { Remove-Item $InnerTar.FullName -Force; Log-Msg "Giải nén lớp 2 hoàn tất!" "Success" }
    } else { Log-Msg "Giải nén hoàn tất." "Success" }
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
$Form.Text = "PHAT TAN VENTOY V13.5 (FINAL)"; $Form.Size = "950,920"; $Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.BgForm; $Form.ForeColor = $Theme.Text; $Form.Padding = 10

$MainTable = New-Object System.Windows.Forms.TableLayoutPanel; $MainTable.Dock = "Fill"; $MainTable.ColumnCount = 1; $MainTable.RowCount = 5
$MainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) 
$MainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize))) 
$MainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 500))) 
$MainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) 
$MainTable.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 70))) 
$Form.Controls.Add($MainTable)

# 1. HEADER
$PnlHead = New-Object System.Windows.Forms.Panel; $PnlHead.Height = 60; $PnlHead.Dock = "Top"; $PnlHead.Margin = "0,0,0,10"
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "USB BOOT MASTER - VENTOY EDITION"; $LblT.Font = $F_Title; $LblT.ForeColor = $Theme.Accent; $LblT.AutoSize = $true; $LblT.Location = "10,10"
$LblS = New-Object System.Windows.Forms.Label; $LblS.Text = "Recursive Extract | Robust Download | Win11 Bypass"; $LblS.ForeColor = "Gray"; $LblS.AutoSize = $true; $LblS.Location = "15,40"
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
$Tab3 = New-Object System.Windows.Forms.TabPage; $Tab3.Text = "WIN 11 HACKS"; $Tab3.BackColor = $Theme.BgForm
$Tab2 = New-Object System.Windows.Forms.TabPage; $Tab2.Text = "KHO THEME (JSON)"; $Tab2.BackColor = $Theme.BgForm
$TabC.Controls.Add($Tab1); $TabC.Controls.Add($Tab3); $TabC.Controls.Add($Tab2); $MainTable.Controls.Add($TabC, 0, 2)

# -- TAB 1: BASIC --
$G1 = New-Object System.Windows.Forms.TableLayoutPanel; $G1.Dock = "Top"; $G1.AutoSize = $true; $G1.Padding = 10; $G1.ColumnCount = 2; $G1.RowCount = 10
$G1.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 40)))
$G1.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 60)))

$LblAct = New-Object System.Windows.Forms.Label; $LblAct.Text = "Chế độ (Mode):"; $LblAct.ForeColor = "White"; $LblAct.AutoSize = $true
$CbAction = New-Object System.Windows.Forms.ComboBox; $CbAction.Items.AddRange(@("Cài mới (Xóa sạch & Format)", "Cập nhật Ventoy (Giữ Data)")); $CbAction.SelectedIndex = 0; $CbAction.DropDownStyle = "DropDownList"; $CbAction.Width = 300
$G1.Controls.Add($LblAct, 0, 0); $G1.Controls.Add($CbAction, 1, 0)

$LblSty = New-Object System.Windows.Forms.Label; $LblSty.Text = "Kiểu Partition:"; $LblSty.ForeColor = "White"; $LblSty.AutoSize = $true
$CbStyle = New-Object System.Windows.Forms.ComboBox; $CbStyle.Items.AddRange(@("MBR (Legacy + UEFI)", "GPT (UEFI Only)")); $CbStyle.SelectedIndex = 0; $CbStyle.DropDownStyle = "DropDownList"; $CbStyle.Width = 300
$G1.Controls.Add($LblSty, 0, 1); $G1.Controls.Add($CbStyle, 1, 1)

$LblName = New-Object System.Windows.Forms.Label; $LblName.Text = "Tên USB (Label):"; $LblName.ForeColor = "White"; $LblName.AutoSize = $true
$TxtLabel = New-Object System.Windows.Forms.TextBox; $TxtLabel.Text = "PhatTan_Boot"; $TxtLabel.Width = 300; $TxtLabel.BackColor = $Theme.InputBg; $TxtLabel.ForeColor = "Cyan"
$G1.Controls.Add($LblName, 0, 2); $G1.Controls.Add($TxtLabel, 1, 2)

$LblFS = New-Object System.Windows.Forms.Label; $LblFS.Text = "Định dạng (Format):"; $LblFS.ForeColor = "White"; $LblFS.AutoSize = $true
$CbFS = New-Object System.Windows.Forms.ComboBox; $CbFS.Items.AddRange(@("exFAT (Khuyên dùng)", "NTFS (Tương thích Win)", "FAT32 (Max 4GB/file)")); $CbFS.SelectedIndex = 0; $CbFS.DropDownStyle = "DropDownList"; $CbFS.Width = 300
$G1.Controls.Add($LblFS, 0, 3); $G1.Controls.Add($CbFS, 1, 3)

# --- NEW: CUSTOM ALIAS & PASSWORD ---
$LblAlias = New-Object System.Windows.Forms.Label; $LblAlias.Text = "Tên Menu (Alias):"; $LblAlias.ForeColor = "Yellow"; $LblAlias.AutoSize = $true
$TxtAlias = New-Object System.Windows.Forms.TextBox; $TxtAlias.Text = "PHAT TAN RESCUE USB"; $TxtAlias.Width = 300; $TxtAlias.BackColor = $Theme.InputBg; $TxtAlias.ForeColor = "Yellow"
$G1.Controls.Add($LblAlias, 0, 4); $G1.Controls.Add($TxtAlias, 1, 4)

$LblPass = New-Object System.Windows.Forms.Label; $LblPass.Text = "Password Boot (Optional):"; $LblPass.ForeColor = "Orange"; $LblPass.AutoSize = $true
$TxtPass = New-Object System.Windows.Forms.TextBox; $TxtPass.Text = ""; $TxtPass.Width = 300; $TxtPass.BackColor = $Theme.InputBg; $TxtPass.ForeColor = "Orange"; $TxtPass.PasswordChar = "*"
$G1.Controls.Add($LblPass, 0, 5); $G1.Controls.Add($TxtPass, 1, 5)

$ChkMemtest = New-Object System.Windows.Forms.CheckBox; $ChkMemtest.Text = "Tải Memtest86+ mới nhất (GitHub API)"; $ChkMemtest.Checked = $true; $ChkMemtest.ForeColor = "Cyan"; $ChkMemtest.AutoSize = $true
$G1.Controls.Add($ChkMemtest, 0, 6); $G1.SetColumnSpan($ChkMemtest, 2)

$ChkLive = New-Object System.Windows.Forms.CheckBox; $ChkLive.Text = "Tải & Cài LiveCD (NangCap_UsbBoot.iso)"; $ChkLive.Checked = $true; $ChkLive.ForeColor = "Yellow"; $ChkLive.AutoSize = $true
$G1.Controls.Add($ChkLive, 0, 7); $G1.SetColumnSpan($ChkLive, 2)

$ChkDir = New-Object System.Windows.Forms.CheckBox; $ChkDir.Text = "Tạo Full Cấu trúc (DATA, ISO, MAS...)"; $ChkDir.Checked = $true; $ChkDir.ForeColor = "Lime"; $ChkDir.AutoSize = $true
$G1.Controls.Add($ChkDir, 0, 8); $G1.SetColumnSpan($ChkDir, 2)

$ChkSec = New-Object System.Windows.Forms.CheckBox; $ChkSec.Text = "Bật Secure Boot Support"; $ChkSec.Checked = $true; $ChkSec.ForeColor = "Orange"; $ChkSec.AutoSize = $true
$G1.Controls.Add($ChkSec, 0, 9); $G1.SetColumnSpan($ChkSec, 2)

$Tab1.Controls.Add($G1)

# -- TAB 3: WIN 11 HACKS --
$G3 = New-Object System.Windows.Forms.TableLayoutPanel; $G3.Dock = "Top"; $G3.AutoSize = $true; $G3.Padding = 20; $G3.ColumnCount = 1; $G3.RowCount = 4
$LblHacks = New-Object System.Windows.Forms.Label; $LblHacks.Text = "TÙY CHỌN CÀI ĐẶT WINDOWS 11:"; $LblHacks.Font = $F_Bold; $LblHacks.ForeColor = "Cyan"; $LblHacks.AutoSize = $true; $LblHacks.Margin = "0,0,0,10"
$G3.Controls.Add($LblHacks, 0, 0)
$ChkBypassCheck = New-Object System.Windows.Forms.CheckBox; $ChkBypassCheck.Text = "✅ Bypass TPM 2.0, SecureBoot, CPU Check"; $ChkBypassCheck.Checked = $true; $ChkBypassCheck.ForeColor = "White"; $ChkBypassCheck.AutoSize = $true; $ChkBypassCheck.Font = $F_Norm
$G3.Controls.Add($ChkBypassCheck, 0, 1)
$ChkBypassNRO = New-Object System.Windows.Forms.CheckBox; $ChkBypassNRO.Text = "✅ Bypass Online Account (Không cần mạng)"; $ChkBypassNRO.Checked = $true; $ChkBypassNRO.ForeColor = "White"; $ChkBypassNRO.AutoSize = $true; $ChkBypassNRO.Font = $F_Norm
$G3.Controls.Add($ChkBypassNRO, 0, 2)
$Tab3.Controls.Add($G3)

# -- TAB 2: ONLINE THEME --
$G2 = New-Object System.Windows.Forms.TableLayoutPanel; $G2.Dock = "Top"; $G2.AutoSize = $true; $G2.Padding = 10; $G2.ColumnCount = 1; $G2.RowCount = 6
$ChkMem = New-Object System.Windows.Forms.CheckBox; $ChkMem.Text = "Kích hoạt Memdisk Mode"; $ChkMem.Checked = $false; $ChkMem.ForeColor = "Cyan"; $ChkMem.AutoSize = $true
$G2.Controls.Add($ChkMem, 0, 0)
$LblThm = New-Object System.Windows.Forms.Label; $LblThm.Text = "Chọn Theme (Đồng bộ từ Server):"; $LblThm.ForeColor = "White"; $LblThm.AutoSize = $true; $LblThm.Margin = "0,10,0,0"
$CbTheme = New-Object System.Windows.Forms.ComboBox; $CbTheme.DropDownStyle = "DropDownList"; $CbTheme.Width = 400
$BtnLoadTheme = New-Object System.Windows.Forms.Button; $BtnLoadTheme.Text = "🔄 Tải danh sách Theme"; $BtnLoadTheme.Width = 200; $BtnLoadTheme.BackColor = "DimGray"; $BtnLoadTheme.ForeColor = "White"
$P_Thm = New-Object System.Windows.Forms.FlowLayoutPanel; $P_Thm.AutoSize = $true; $P_Thm.FlowDirection = "LeftToRight"
$P_Thm.Controls.Add($CbTheme); $P_Thm.Controls.Add($BtnLoadTheme)
$G2.Controls.Add($LblThm, 0, 2); $G2.Controls.Add($P_Thm, 0, 3)
$LblJ = New-Object System.Windows.Forms.Label; $LblJ.Text = "JSON Config Preview:"; $LblJ.ForeColor = "Gray"; $LblJ.AutoSize = $true; $LblJ.Margin = "0,10,0,0"
$G2.Controls.Add($LblJ, 0, 4)
$Tab2.Controls.Add($G2)

# 4. LOG
$TxtLog = New-Object System.Windows.Forms.RichTextBox; $TxtLog.Dock = "Fill"; $TxtLog.BackColor = "Black"; $TxtLog.ForeColor = "Lime"; $TxtLog.Font = $F_Code; $TxtLog.ReadOnly = $true; $MainTable.Controls.Add($TxtLog, 0, 3)

# 5. EXECUTE BUTTON
$BtnStart = New-Object System.Windows.Forms.Button; $BtnStart.Text = "THỰC HIỆN"; $BtnStart.Font = $F_Title; $BtnStart.BackColor = $Theme.Accent; $BtnStart.ForeColor = "Black"; $BtnStart.FlatStyle = "Flat"; $BtnStart.Dock = "Fill"
$MainTable.Controls.Add($BtnStart, 0, 4)

# ==========================================
# 🛡️ HELPER LOGIC
# ==========================================

function Check-MathBot {
    if (!$ChkAntiBot.Checked) { return $true }
    $A = Get-Random -Min 1 -Max 20; $B = Get-Random -Min 1 -Max 10; $Result = $A + $B
    $UserAns = [Microsoft.VisualBasic.Interaction]::InputBox("Xác thực bảo mật:`n`nHãy tính: $A + $B = ?", "Anti-Bot Verification", "")
    if ($UserAns -eq "$Result") { return $true } else { [System.Windows.Forms.MessageBox]::Show("Sai rồi!", "Cảnh báo", "OK", "Error"); return $false }
}

function Force-Disk-Refresh {
    Log-Msg "Auto F5: Rescan Disk..." "Yellow"
    try {
        "rescan" | Out-File "$env:TEMP\dp_rescan.txt" -Encoding ASCII -Force
        Start-Process diskpart -ArgumentList "/s `"$env:TEMP\dp_rescan.txt`"" -Wait -WindowStyle Hidden
        Start-Sleep -Seconds 2
    } catch {}
}

function Get-DriveLetter-DiskPart ($DiskIndex) {
    try {
        $DpScript = "$env:TEMP\dp_vol_check.txt"
        "select disk $DiskIndex`ndetail disk" | Out-File $DpScript -Encoding ASCII -Force
        $Output = & diskpart /s $DpScript
        foreach ($Line in $Output) { if ($Line -match "Volume \d+\s+([A-Z])\s+") { return "$($Matches[1]):" } }
    } catch {}
    return $null
}

function Get-Partition-Style-Robust ($DiskIndex) {
    try { if (Get-Command Get-Disk -EA 0) { return (Get-Disk -Number $DiskIndex -ErrorAction Stop).PartitionStyle } } catch {}
    try {
        $DpScript = "$env:TEMP\dp_style.txt"; "list disk" | Out-File $DpScript -Encoding ASCII -Force
        $Output = & diskpart /s $DpScript
        foreach ($Line in $Output) { if ($Line -match "Disk $DiskIndex\s+.*") { if ($Line -match "\*\s*$") { return "GPT" } else { return "MBR" } } }
    } catch {}
    return "Unknown"
}

function Load-USB {
    $CbUSB.Items.Clear(); $Found = $false; Force-Disk-Refresh
    if (Get-Command Get-Disk -EA 0) { try { $Disks = Get-Disk | Where-Object { $_.BusType -eq "USB" -or $_.MediaType -eq "Removable" }; if ($Disks) { foreach ($d in $Disks) { $SizeGB = [Math]::Round($d.Size / 1GB, 1); $CbUSB.Items.Add("Disk $($d.Number): $($d.FriendlyName) - $SizeGB GB") }; $Found = $true } } catch {} }
    if (-not $Found) { try { $WmiDisks = Get-WmiObject Win32_DiskDrive | Where-Object { $_.InterfaceType -eq "USB" -or $_.MediaType -match "Removable" }; if ($WmiDisks) { foreach ($d in $WmiDisks) { $Size = $d.Size; if (!$Size) { $Size = 0 }; $SizeGB = [Math]::Round($Size / 1GB, 1); $CbUSB.Items.Add("Disk $($d.Index): $($d.Model) - $SizeGB GB") }; $Found = $true } } catch {} }
    if (-not $Found) { $CbUSB.Items.Add("Không tìm thấy USB"); $CbUSB.SelectedIndex = 0 } else { $CbUSB.SelectedIndex = 0 }
}

function Show-UsbDetails-Pro {
    if ($CbUSB.SelectedItem -match "Disk (\d+)") {
        $ID = $Matches[1]; $DL = Get-DriveLetter-DiskPart $ID; $Style = Get-Partition-Style-Robust $ID; $Report = "=== USB REPORT ===`r`nDevice ID: Disk $ID`r`nDrive: $DL`r`nStyle: $Style"; [System.Windows.Forms.MessageBox]::Show($Report, "Info")
    }
}

# --- LOGIC JSON ONLINE ---
function Load-Themes-Online {
    $CbTheme.Items.Clear(); $CbTheme.Items.Add("Mặc định (Ventoy)")
    Log-Msg "Đang tải danh sách Theme..." "Cyan"
    try {
        $Global:ThemeData = Invoke-RestMethod -Uri $Global:ThemeConfigUrl -TimeoutSec 3 -ErrorAction Stop
        Log-Msg "Tải Config Online thành công!" "Success"
        foreach ($item in $Global:ThemeData) { if ($item.type -eq "GRUB" -and $item.link) { $CbTheme.Items.Add($item.name) } }
    } catch { 
        Log-Msg "Lỗi tải Config Online! Kiểm tra mạng." "Red" 
    }
    $CbTheme.SelectedIndex = 0
}

function Process-Ventoy {
    param($DiskID, $Mode, $Style, $LabelName, $FSType, $IsLiveCD, $IsDir)
    if (-not (Check-MathBot)) { return }
    
    # 1. PREPARE VENTOY (Smart Check)
    Prepare-Ventoy-Core
    if (!$Global:VentoyExe) { return }
    
    # 2. GET DRIVE
    Force-Disk-Refresh; $DL = Get-DriveLetter-DiskPart $DiskID
    if (!$DL) { Log-Msg "Lỗi: Không tìm thấy ổ đĩa!" "Red"; return }

    # 3. RUN VENTOY
    $FlagMode = if ($Mode -eq "UPDATE") { "/U" } else { "/I" }
    $FlagStyle = if ($Style -match "GPT") { "/GPT" } else { "/MBR" }
    $FlagSecure = if ($ChkSec.Checked) { "/S" } else { "" }
    $FlagFS = if ($Mode -eq "INSTALL") { if ($FSType -match "NTFS") { "/FS:NTFS" } elseif ($FSType -match "FAT32") { "/FS:FAT32" } else { "/FS:exFAT" } } else { "" }

    Log-Msg "Running Ventoy2Disk $FlagFS..." "Cyan"
    $P = Start-Process -FilePath $Global:VentoyExe -ArgumentList "VTOYCLI $FlagMode /Drive:$DL /NoUsbCheck $FlagStyle $FlagSecure $FlagFS" -PassThru -Wait
    
    if ($P.ExitCode -eq 0) {
        try {
            Log-Msg "VENTOY OK! Rescanning..." "Yellow"
            $UsbRoot = $null; for ($i = 0; $i -lt 30; $i++) { Force-Disk-Refresh; $TempDL = Get-DriveLetter-DiskPart $DiskID; if ($TempDL -and (Test-Path $TempDL)) { $UsbRoot = $TempDL; break }; Start-Sleep 1 }
            if (!$UsbRoot) { $UsbRoot = $DL }
            
            if (Test-Path $UsbRoot) {
                if ($Mode -eq "INSTALL") { try { cmd /c "label $UsbRoot $LabelName" } catch {} }
                $VentoyDir = "$UsbRoot\ventoy"; New-Item -Path $VentoyDir -ItemType Directory -Force | Out-Null
                
                # --- MEMTEST86+ (AUTO API + ZIP FIX) ---
                if ($ChkMemtest.Checked) {
                    try {
                        Log-Msg "Check Memtest86+ Latest..." "Cyan"
                        $MemUrl = $null
                        try {
                            $M_Assets = Invoke-RestMethod -Uri $Global:MemtestRepo -TimeoutSec 5
                            $M_Iso = $M_Assets.assets | Where-Object { $_.name -match "\.iso$" } | Select -First 1
                            $MemUrl = $M_Iso.browser_download_url
                            Log-Msg "Found: $($M_Assets.tag_name)" "Cyan"
                        } catch { }

                        if ([string]::IsNullOrEmpty($MemUrl)) {
                            Log-Msg "API Fail. Dùng Link Fallback (v8.00)." "Yellow"
                            $MemUrl = $Global:MemtestFallback
                        }
                        
                        # Tải Memtest ZIP -> Extract -> Get ISO
                        $MemZip = "$Global:WorkDir\memtest.zip"
                        $MemExtract = "$Global:WorkDir\MemtestExtract"
                        Download-File-Robust $MemUrl $MemZip
                        
                        if (Test-Path $MemExtract) { Remove-Item $MemExtract -Recurse -Force }
                        Extract-Recursive $MemZip $MemExtract
                        
                        $RealIso = Get-ChildItem -Path $MemExtract -Filter "*.iso" -Recurse | Select -First 1
                        if ($RealIso) {
                            $IsoRescueDir = "$UsbRoot\ISO_Rescue"
                            if (!(Test-Path $IsoRescueDir)) { New-Item -Path $IsoRescueDir -ItemType Directory -Force | Out-Null }
                            Copy-Item $RealIso.FullName "$IsoRescueDir\memtest86+.iso" -Force
                            Log-Msg "Memtest86+ OK!" "Success"
                        } else { Log-Msg "Không tìm thấy file ISO trong Memtest Zip!" "Red" }

                    } catch { Log-Msg "Lỗi tải Memtest: $($_.Exception.Message)" "Red" }
                }

                # MAS & LIVECD
                if ($IsDir) { try { Download-File-Simple $Global:MasUrl "$UsbRoot\MAS_AIO.cmd"; Log-Msg "MAS OK" "Success" } catch {} }

                # 4. THEME ONLINE (RECURSIVE)
                $SelTheme = $CbTheme.SelectedItem; $ThemeConfig = $null
                if ($SelTheme -ne "Mặc định (Ventoy)") {
                    $T = $Global:ThemeData | Where-Object { $_.Name -eq $SelTheme } | Select -First 1
                    if ($T) {
                        try {
                            Log-Msg "Đang tải Theme: $($T.Name)..." "Cyan"
                            $FileName = [System.IO.Path]::GetFileName($T.Link); if ($FileName -notmatch "\.") { $FileName = "theme_temp.zip" } 
                            $ThemeFile = "$Global:WorkDir\$FileName"
                            Download-File-Robust $T.Link $ThemeFile
                            
                            $ThemeDest = "$VentoyDir\themes"; if (Test-Path $ThemeDest) { Remove-Item $ThemeDest -Recurse -Force }; New-Item $ThemeDest -ItemType Directory | Out-Null
                            
                            Extract-Recursive $ThemeFile $ThemeDest
                            
                            # Tìm file theme.txt
                            $ThemeTxt = Get-ChildItem -Path $ThemeDest -Filter "theme.txt" -Recurse | Select -First 1
                            if ($ThemeTxt) {
                                $RelPath = $ThemeTxt.FullName.Substring($VentoyDir.Length).Replace("\", "/")
                                $ThemeConfig = "/ventoy$RelPath"
                                Log-Msg "Cài Theme OK: $RelPath" "Success"
                            } else { Log-Msg "Không tìm thấy file theme.txt!" "Red" }
                        } catch { Log-Msg "LỖI THEME: $($_.Exception.Message)" "Red" }
                    }
                }

                # JSON CONFIG
                $JControl = @(@{ "VTOY_DEFAULT_MENU_MODE" = "0" }, @{ "VTOY_FILT_DOT_UNDERSCORE_FILE" = "1" })
                if ($ChkBypassCheck.Checked) { $JControl += @{ "VTOY_WIN11_BYPASS_CHECK" = "1" } }
                if ($ChkBypassNRO.Checked) { $JControl += @{ "VTOY_WIN11_BYPASS_NRO" = "1" } }

                $J = @{ 
                    "control" = $JControl; 
                    "theme" = @{ "display_mode" = "GUI"; "gfxmode" = "1920x1080" }
                    "menu_alias" = @( @{ "image" = "/ventoy/ventoy.png"; "alias" = $TxtAlias.Text } )
                }
                
                if ($TxtPass.Text -ne "") {
                    $HashedPass = Get-Sha256 $TxtPass.Text
                    $J.Add("password", @{ "menupwd" = $HashedPass })
                    Log-Msg "Đã đặt Password Menu (SHA256)." "Cyan"
                }

                if ($ThemeConfig) { $J.theme.Add("file", $ThemeConfig) }
                
                $J | ConvertTo-Json -Depth 10 | Out-File "$VentoyDir\ventoy.json" -Encoding UTF8 -Force
                Log-Msg "DONE! Enjoy." "Success"; [System.Windows.Forms.MessageBox]::Show("HOÀN TẤT!", "Phat Tan PC"); Invoke-Item $UsbRoot
            }
        } catch { Log-Msg "ERR: $($_.Exception.Message)" "Red" }
    } else { Log-Msg "Lỗi Ventoy ExitCode: $ExitCode" "Red" }
    $BtnStart.Enabled = $true; $Form.Cursor = "Default"
}

$BtnRef.Add_Click({ Load-USB })
$BtnInfo.Add_Click({ Show-UsbDetails-Pro })
$BtnLoadTheme.Add_Click({ Load-Themes-Online })
$BtnStart.Add_Click({
    if ($CbUSB.SelectedItem -match "Disk (\d+)") {
        $ID = $Matches[1]; $Mode = if ($CbAction.SelectedIndex -eq 0) { "INSTALL" } else { "UPDATE" }
        if ([System.Windows.Forms.MessageBox]::Show("Xử lý Disk $ID?", "Xác nhận", "YesNo") -eq "Yes") {
            $BtnStart.Enabled = $false; $Form.Cursor = "WaitCursor"
            Process-Ventoy $ID $Mode $CbStyle.SelectedItem $TxtLabel.Text $CbFS.SelectedItem $ChkLive.Checked $ChkDir.Checked
        }
    } else { [System.Windows.Forms.MessageBox]::Show("Chưa chọn USB!") }
})

$Form.Add_Load({ Load-USB; Load-Themes-Online })
[System.Windows.Forms.Application]::Run($Form)
