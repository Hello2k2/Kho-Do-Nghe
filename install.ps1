<#
    TOOL CUU HO MAY TINH - PHAT TAN PC
    Author:  Phat Tan
    Version: 9.5 (Ultimate Suite)
    Github:  https://github.com/Hello2k2/Kho-Do-Nghe
#>

# --- KHỞI TẠO ---
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- CẤU HÌNH ---
$BaseUrl = "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/"
$RawUrl  = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/"
# QUAN TRỌNG: LINK FILE JSON CỦA BẠN
$JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/refs/heads/main/apps.json"

$TempDir = "$env:TEMP\PhatTan_Tool"
if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir | Out-Null }

# Tối ưu mạng (Max Speed)
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::DefaultConnectionLimit = 100

# --- HACK GIAO DIỆN (BLUR EFFECT) ---
$ConsoleCode = @'
using System; using System.Runtime.InteropServices;
public class ConsoleEffects {
    [DllImport("user32.dll")] public static extern int SetWindowCompositionAttribute(IntPtr hwnd, ref WindowCompositionAttributeData data);
    [StructLayout(LayoutKind.Sequential)] public struct WindowCompositionAttributeData { public int Attribute; public IntPtr Data; public int SizeOfData; }
    [StructLayout(LayoutKind.Sequential)] public struct AccentPolicy { public int AccentState; public int AccentFlags; public int GradientColor; public int AnimationId; }
    public static void EnableBlur() {
        var hwnd = System.Diagnostics.Process.GetCurrentProcess().MainWindowHandle;
        var accent = new AccentPolicy(); accent.AccentState = 3;
        var accentStructSize = Marshal.SizeOf(accent); var accentPtr = Marshal.AllocHGlobal(accentStructSize);
        Marshal.StructureToPtr(accent, accentPtr, false);
        var data = new WindowCompositionAttributeData(); data.Attribute = 19; data.SizeOfData = accentStructSize; data.Data = accentPtr;
        SetWindowCompositionAttribute(hwnd, ref data); Marshal.FreeHGlobal(accentPtr);
    }
}
'@
try { Add-Type -TypeDefinition $ConsoleCode; [ConsoleEffects]::EnableBlur() } catch {}
$Host.UI.RawUI.WindowTitle = "PHÁT TẤN - LOG WINDOW (Zalo: 0823.883.028)"
[Console]::BackgroundColor = "Black"; [Console]::ForegroundColor = "Cyan"; Clear-Host

# --- LOGO ---
Write-Host " PHAT TAN PC TOOLKIT V9.5 (ULTIMATE)" -ForegroundColor Cyan
Write-Host " ------------------------------------" -ForegroundColor Gray

# --- HÀM LOGIC ---
function Log-Msg ($Msg, $Color="Cyan") { Write-Host " $Msg" -ForegroundColor $Color }

function Tai-Va-Chay {
    param ([string]$TenFileTrenMang, [string]$TenFileLuu, [string]$Loai, [string]$NguonRieng = "")
    
    # Xử lý link: Nếu có http thì dùng luôn, không thì nối BaseUrl
    if ($NguonRieng -match "^http") { $LinkTai = $NguonRieng } 
    elseif ($TenFileTrenMang -match "^http") { $LinkTai = $TenFileTrenMang }
    else { $LinkTai = "$BaseUrl$TenFileTrenMang" }

    $DuongDanLuu = "$TempDir\$TenFileLuu"
    Write-Host " [>] Downloading: $TenFileLuu ..." -NoNewline -ForegroundColor Yellow
    
    try {
        (New-Object System.Net.WebClient).DownloadFile($LinkTai, $DuongDanLuu)
        Write-Host " [OK]" -ForegroundColor Green
        
        if (Test-Path $DuongDanLuu) {
            Log-Msg " [+] Installing..." "Green"
            if ($Loai -eq "Msi") { Start-Process "msiexec.exe" -ArgumentList "/i `"$DuongDanLuu`" /quiet /norestart" -Wait }
            else { Start-Process -FilePath $DuongDanLuu -Wait }
            Log-Msg " [ok] Done." "Green"
        } 
    } catch { Log-Msg " [!] ERROR: $($_.Exception.Message)" "Red" }
}

function Load-Module ($ScriptName) {
    $LocalPath = "$TempDir\$ScriptName"
    Write-Host " [*] Module: $ScriptName" -ForegroundColor Cyan
    try { Invoke-WebRequest -Uri "$RawUrl$ScriptName" -OutFile $LocalPath; Start-Process powershell -ArgumentList "-Ex Bypass -File `"$LocalPath`"" } catch {}
}

# --- TẢI JSON DATA ---
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

try {
    # 1. Tạo timestamp để tránh cache (Dùng UnixTimeSeconds chuẩn hơn %s)
    $Ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    
    # 2. Thêm User-Agent giả lập trình duyệt để GitHub không chặn
    $Headers = @{
        "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) PowerShell/9.5"
        "Cache-Control" = "no-cache"
    }

    # 3. Tải dữ liệu
    $AppData = Invoke-RestMethod -Uri "$JsonUrl?t=$Ts" -Headers $Headers -ErrorAction Stop
    
    # 4. Kiểm tra dữ liệu
    if (!$AppData -or $AppData.Count -eq 0) { throw "File JSON rong hoac khong dung dinh dang." }
    
    Log-Msg " [OK] Da tai danh sach: $($AppData.Count) ung dung." "Green"

} catch {
    # 5. Hiện nguyên văn lỗi để debug (Quan trọng)
    $RealError = $_.Exception.Message
    [System.Windows.Forms.MessageBox]::Show("KHONG TAI DUOC FILE APPS.JSON!`n`nNguyen nhan chi tiet:`n$RealError`n`nLink: $JsonUrl", "Loi Debug", "OK", "Error")
    Exit
}

# --- GUI CHÍNH ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "PHÁT TẤN PC - TOOLKIT V9.5 (ULTIMATE SUITE)"
$Form.Size = New-Object System.Drawing.Size(900, 720) # Form to hơn chút
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

# Header
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "PHAT TAN PC TOOLKIT"; $LblT.Font = "Segoe UI, 18, Bold"; $LblT.ForeColor = "Cyan"; $LblT.AutoSize = $true; $LblT.Location = "20, 10"; $Form.Controls.Add($LblT)
$LblS = New-Object System.Windows.Forms.Label; $LblS.Text = "Professional IT Rescue Suite - Updated: $(Get-Date -Format 'dd/MM/yyyy')"; $LblS.ForeColor = "Gray"; $LblS.AutoSize = $true; $LblS.Location = "25, 45"; $Form.Controls.Add($LblS)

# Tab Control
$TabControl = New-Object System.Windows.Forms.TabControl; $TabControl.Location = "20, 80"; $TabControl.Size = "840, 440"; $Form.Controls.Add($TabControl)

# --- ENGINE TẠO TAB TỰ ĐỘNG TỪ JSON ---
$TabNames = $AppData | Select-Object -ExpandProperty tab -Unique
$TabObjects = @{}

foreach ($TName in $TabNames) {
    $Page = New-Object System.Windows.Forms.TabPage; $Page.Text = $TName; $Page.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48); $Page.AutoScroll = $true
    $TabControl.Controls.Add($Page)
    $TabObjects[$TName] = $Page
    
    # Lấy danh sách app thuộc Tab này
    $AppsInTab = $AppData | Where-Object { $_.tab -eq $TName }
    $CurrentY = 30
    
    foreach ($App in $AppsInTab) {
        $Chk = New-Object System.Windows.Forms.CheckBox
        $Chk.Text = $App.name
        $Chk.Tag = $App # Lưu toàn bộ object JSON vào Tag để dùng sau
        $Chk.Location = New-Object System.Drawing.Point(30, $CurrentY)
        $Chk.AutoSize = $true; $Chk.Font = "Segoe UI, 11"; $Chk.ForeColor = "White"
        $Page.Controls.Add($Chk)
        $CurrentY += 40
    }
}

# --- TAB ADVANCED TOOLS (MODULES - FULL OPTION) ---
$AdvTab = New-Object System.Windows.Forms.TabPage; $AdvTab.Text = "Advanced Tools (Modules)"; $AdvTab.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 35); $TabControl.Controls.Add($AdvTab)

function Add-AdvBtn ($P, $Txt, $X, $Y, $Col, $Cmd) {
    $B = New-Object System.Windows.Forms.Button; $B.Text=$Txt; $B.Location="$X,$Y"; $B.Size="250,45" # Nút to hơn chút cho dễ bấm
    $B.BackColor=$Col; $B.ForeColor="White"; if($Col -match "Yellow|Lime|Orange"){$B.ForeColor="Black"}
    $B.FlatStyle="Flat"; $B.Font="Segoe UI, 9, Bold"; $B.Add_Click($Cmd); $P.Controls.Add($B)
}

# Tiêu đề cột (Label)
function Add-Header ($P, $T, $X) { $L=New-Object System.Windows.Forms.Label; $L.Text=$T; $L.Location="$X,20"; $L.AutoSize=$true; $L.ForeColor="Gray"; $L.Font="Segoe UI, 10, Bold, Underline"; $P.Controls.Add($L) }

# === CỘT 1: SYSTEM & MAINTENANCE (X=20) ===
Add-Header $AdvTab "1. SYSTEM & MAINTENANCE" 20
Add-AdvBtn $AdvTab "CHECK INFO & DRIVER" 20 50 "Purple" { Load-Module "SystemInfo.ps1" }
Add-AdvBtn $AdvTab "SYSTEM SCAN (SFC/DISM)" 20 105 "Orange" { Load-Module "SystemScan.ps1" }
Add-AdvBtn $AdvTab "SYSTEM CLEANER PRO" 20 160 "Green" { Load-Module "SystemCleaner.ps1" }
Add-AdvBtn $AdvTab "DATA RECOVERY (HDD)" 20 215 "Red" { Tai-Va-Chay "Disk.Genius.rar" "DiskGenius.rar" "Portable" }

# === CỘT 2: SECURITY & NETWORK (X=290) ===
Add-Header $AdvTab "2. SECURITY & NETWORK" 290
Add-AdvBtn $AdvTab "NETWORK MASTER (DNS/FIX)" 290 50 "Teal" { Load-Module "NetworkMaster.ps1" }
Add-AdvBtn $AdvTab "WIN UPDATE PRO (QUAN LY)" 290 105 "Firebrick" { Load-Module "WinUpdatePro.ps1" } # Module Xịn
Add-AdvBtn $AdvTab "DEFENDER CONTROL" 290 160 "DarkSlateBlue" { Load-Module "DefenderMgr.ps1" }
Add-AdvBtn $AdvTab "BROWSER PRIVACY (BLOCK)" 290 215 "DarkRed" { Load-Module "BrowserPrivacy.ps1" }

# === CỘT 3: DEPLOYMENT & TOOLS (X=560) ===
Add-Header $AdvTab "3. DEPLOYMENT & UTILITIES" 560
Add-AdvBtn $AdvTab "CÀI WIN TỰ ĐỘNG (ISO)" 560 50 "Pink" { Load-Module "WinInstall.ps1" }
Add-AdvBtn $AdvTab "WIN AIO BUILDER (TAO ISO)" 560 105 "OrangeRed" { Load-Module "WinAIOBuilder.ps1" } 

# THÊM NÚT NÀY VÀO ĐÂY (Vị trí hợp lý nhất)
Add-AdvBtn $AdvTab "LTSC STORE INSTALLER" 560 160 "DeepSkyBlue" { Load-Module "StoreInstaller.ps1" }

# Đẩy các nút cũ xuống
Add-AdvBtn $AdvTab "ISO DOWNLOADER (CLOUD)" 560 215 "Yellow" { Load-Module "ISODownloader.ps1" }
Add-AdvBtn $AdvTab "BACKUP & RESTORE PRO" 560 270 "Cyan" { Load-Module "BackupCenter.ps1" }
Add-AdvBtn $AdvTab "APP STORE (WINGET)" 560 325 "LightGreen" { Load-Module "AppStore.ps1" }

# --- FOOTER BUTTONS ---
$BtnSelectAll = New-Object System.Windows.Forms.Button; $BtnSelectAll.Text = "Chon All"; $BtnSelectAll.Location = "30, 540"; $BtnSelectAll.Size = "100, 35"; $BtnSelectAll.BackColor = "Gray"; $Form.Controls.Add($BtnSelectAll)
$BtnSelectAll.Add_Click({ foreach ($P in $TabControl.TabPages) { foreach ($C in $P.Controls) { if ($C -is [System.Windows.Forms.CheckBox]) { $C.Checked = $true } } } })

$BtnUncheck = New-Object System.Windows.Forms.Button; $BtnUncheck.Text = "Bo Chon"; $BtnUncheck.Location = "140, 540"; $BtnUncheck.Size = "100, 35"; $BtnUncheck.BackColor = "Gray"; $Form.Controls.Add($BtnUncheck)
$BtnUncheck.Add_Click({ foreach ($P in $TabControl.TabPages) { foreach ($C in $P.Controls) { if ($C -is [System.Windows.Forms.CheckBox]) { $C.Checked = $false } } } })

# --- NÚT CÀI ĐẶT (PROCESS BUTTON) ---
$BtnInstall = New-Object System.Windows.Forms.Button
$BtnInstall.Text = "TIEN HANH CAI DAT DA CHON"; $BtnInstall.Font = "Segoe UI, 14, Bold"
$BtnInstall.Size = "300, 60"; $BtnInstall.Location = "560, 540"; $BtnInstall.BackColor = "LimeGreen"; $BtnInstall.ForeColor = "Black"; $BtnInstall.FlatStyle = "Flat"

$BtnInstall.Add_Click({
    $BtnInstall.Enabled = $false; $BtnInstall.Text = "DANG XU LY..."
    
    foreach ($P in $TabControl.TabPages) {
        foreach ($C in $P.Controls) {
            if ($C -is [System.Windows.Forms.CheckBox] -and $C.Checked) {
                $Item = $C.Tag # Lấy data JSON từ Tag
                
                # 1. Nếu là Script thuần (Registry, Tweak)
                if ($Item.type -eq "Script") {
                    Log-Msg " [~] Running Script: $($Item.name)" "Yellow"
                    Invoke-Expression $Item.irm
                }
                # 2. Nếu là File cần tải
                else {
                    Tai-Va-Chay $Item.link $Item.filename $Item.type
                    
                    # 3. Nếu có lệnh IRM chạy kèm (VD: Fix IDM)
                    if ($Item.irm -ne $null -and $Item.irm -ne "") {
                        Log-Msg " [!] Running Post-Install Command..." "Yellow"
                        Invoke-Expression $Item.irm
                    }
                }
                $C.Checked = $false
            }
        }
    }
    
    [System.Windows.Forms.MessageBox]::Show("Da hoan tat tat ca tac vu!", "Phat Tan PC")
    $BtnInstall.Text = "TIEN HANH CAI DAT DA CHON"; $BtnInstall.Enabled = $true
})
$Form.Controls.Add($BtnInstall)

# --- MINI TOOLBAR (BOTTOM) ---
function Add-Mini ($T, $C, $X, $Y, $Cmd) { $b=New-Object System.Windows.Forms.Button; $b.Text=$T; $b.BackColor=$C; $b.Location="$X,$Y"; $b.Size="120,35"; $b.FlatStyle="Flat"; $b.Add_Click($Cmd); $Form.Controls.Add($b) }

Add-Mini "RAM BOOSTER" "Orange" 30 620 { Load-Module "RamBooster.ps1" }
Add-Mini "WINPE RESCUE" "Yellow" 160 620 { Tai-Va-Chay "WinPE_CuuHo.exe" "WinPE_Setup.exe" "Portable" }
Add-Mini "ACTIVE WIN" "Magenta" 290 620 { irm https://get.activated.win | iex }
Add-Mini "DONATE" "Gold" 420 620 { 
    $DonForm = New-Object System.Windows.Forms.Form; $DonForm.Text = "DONATE"; $DonForm.Size="400,550"; $DonForm.StartPosition="CenterScreen"
    $PB=New-Object System.Windows.Forms.PictureBox; $PB.Size="350,400"; $PB.Location="15,10"; $PB.SizeMode="Zoom"
    try{$PB.Load("https://img.vietqr.io/image/970436-1055835227-print.png?addInfo=Donate%20PhatTanPC&accountName=DANG%20LAM%20TAN%20PHAT")}catch{}
    $DonForm.Controls.Add($PB); $DonForm.ShowDialog() 
}

$Form.ShowDialog() | Out-Null
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
