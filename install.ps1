<#
    TOOL CUU HO MAY TINH - PHAT TAN PC
    Author:  Phat Tan
    Version: 8.0 (Modular Launcher)
    Github:  https://github.com/Hello2k2/Kho-Do-Nghe
#>

# --- KHỞI TẠO ---
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- CẤU HÌNH ---
$BaseUrl = "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/"
$RawUrl  = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/"
$TempDir = "$env:TEMP\PhatTan_Tool"
if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir | Out-Null }

# --- HACK GIAO DIỆN CONSOLE (BLUR) ---
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
$Host.UI.RawUI.WindowTitle = "PHAT TAN PC - LOG WINDOW (Zalo: 0823.883.028)"
[Console]::BackgroundColor = "Black"; [Console]::ForegroundColor = "Cyan"; Clear-Host

# --- LOGO STARTUP ---
Write-Host "
  _____  _           _   _______   _      
 |  __ \| |         | | |__   __| (_)     
 | |__) | |__   __ _| |_   | | __ _ _ __  
 |  ___/| '_ \ / _` | __|  | |/ _` | '_ \ 
 | |    | | | | (_| | |_   | | (_| | | | |
 |_|    |_| |_|\__,_|\__|  |_|\__,_|_| |_|
                                          
    " -ForegroundColor Cyan
Write-Host "    ---  CUU HO MAY TINH ONLINE ---" -ForegroundColor Yellow
Write-Host "--------------------------------------------------------" -ForegroundColor Gray
Write-Host " [*] Author:      Phat Tan (Zalo: 0823.883.028)" -ForegroundColor White
Write-Host " [*] Credits:     Vu Kim Dong, MMT, MAS" -ForegroundColor DarkGray
Write-Host "--------------------------------------------------------" -ForegroundColor Gray
Write-Host ""

# --- HÀM LOGIC ---
function Log-Msg ($Msg, $Color="Cyan") { Write-Host " $Msg" -ForegroundColor $Color }

function Tai-Va-Chay {
    param ([string]$TenFileTrenMang, [string]$TenFileLuu, [string]$Loai, [string]$NguonRieng = "")
    if ($NguonRieng -ne "") { $LinkTai = $NguonRieng } else { $LinkTai = "$BaseUrl$TenFileTrenMang" }
    $DuongDanLuu = "$TempDir\$TenFileLuu"
    Write-Host " [>] Dang tai: $TenFileLuu ..." -NoNewline -ForegroundColor Yellow
    try {
        (New-Object System.Net.WebClient).DownloadFile($LinkTai, $DuongDanLuu)
        Write-Host " [OK]" -ForegroundColor Green
        if (Test-Path $DuongDanLuu) {
            Log-Msg " [+] Dang khoi chay..." "Green"
            if ($Loai -eq "Msi") { Start-Process "msiexec.exe" -ArgumentList "/i `"$DuongDanLuu`" /quiet /norestart" -Wait }
            elseif ($Loai -eq "Portable") { Start-Process -FilePath $DuongDanLuu -Wait }
            else { Start-Process -FilePath $DuongDanLuu -Wait }
            Log-Msg " [ok] Hoan tat." "Green"
        } else { Log-Msg " [!] Loi: File khong ton tai." "Red" }
    } catch { Log-Msg " [!] LOI TAI FILE: $($_.Exception.Message)" "Red" }
}

# --- HÀM TẢI MODULE ---
function Load-Module ($ScriptName) {
    $LocalPath = "$TempDir\$ScriptName"
    Write-Host " [*] Dang tai Module: $ScriptName ..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri "$RawUrl$ScriptName" -OutFile $LocalPath
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$LocalPath`""
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi tai Module $ScriptName!", "Error") }
}

# --- HÀM DONATE ---
function Hien-Donate {
    $DonForm = New-Object System.Windows.Forms.Form; $DonForm.Text = "DONATE - PHAT TAN PC"; $DonForm.Size = New-Object System.Drawing.Size(400, 550); $DonForm.StartPosition = "CenterScreen"; $DonForm.BackColor="White"; $DonForm.FormBorderStyle = "FixedToolWindow"
    $PB = New-Object System.Windows.Forms.PictureBox; $PB.Size = New-Object System.Drawing.Size(350, 400); $PB.Location = New-Object System.Drawing.Point(15, 10); $PB.SizeMode = "Zoom"
    try { $PB.Load("https://img.vietqr.io/image/970436-1055835227-print.png?addInfo=Donate%20PhatTanPC&accountName=DANG%20LAM%20TAN%20PHAT") } catch {}; $DonForm.Controls.Add($PB)
    $LblSTK = New-Object System.Windows.Forms.Label; $LblSTK.Text = "STK: 1055835227 (VCB)"; $LblSTK.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold); $LblSTK.ForeColor = "Red"; $LblSTK.AutoSize = $true; $LblSTK.Location = New-Object System.Drawing.Point(90, 420); $DonForm.Controls.Add($LblSTK)
    $DonForm.ShowDialog() | Out-Null
}

# --- GUI CHÍNH ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "PHAT TAN PC - TOOLKIT V8.0"
$Form.Size = New-Object System.Drawing.Size(750, 680)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = [System.Drawing.Color]::White
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header & Donate
$LabelTitle = New-Object System.Windows.Forms.Label; $LabelTitle.Text = "PHAT TAN PC TOOLKIT"; $LabelTitle.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold); $LabelTitle.ForeColor = "Cyan"; $LabelTitle.AutoSize = $true; $LabelTitle.Location = New-Object System.Drawing.Point(20, 10); $Form.Controls.Add($LabelTitle)
$LabelSub = New-Object System.Windows.Forms.Label; $LabelSub.Text = "Zalo: 0823.883.028 | Credits: MMT - DONG599 - MAS"; $LabelSub.Font = "Segoe UI, 10"; $LabelSub.ForeColor = "LightGray"; $LabelSub.AutoSize = $true; $LabelSub.Location = New-Object System.Drawing.Point(25, 45); $Form.Controls.Add($LabelSub)
$BtnDonate = New-Object System.Windows.Forms.Button; $BtnDonate.Text = "☕ DONATE"; $BtnDonate.Location = New-Object System.Drawing.Point(600, 15); $BtnDonate.BackColor = "Gold"; $BtnDonate.ForeColor = "Black"; $BtnDonate.FlatStyle = "Flat"; $BtnDonate.Add_Click({ Hien-Donate }); $Form.Controls.Add($BtnDonate)

# Tab Control
$TabControl = New-Object System.Windows.Forms.TabControl; $TabControl.Location = New-Object System.Drawing.Point(20, 80); $TabControl.Size = New-Object System.Drawing.Size(690, 380); $Form.Controls.Add($TabControl)
function Make-Tab ($Name) { $P = New-Object System.Windows.Forms.TabPage; $P.Text = $Name; $P.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48); $TabControl.Controls.Add($P); return $P }
function Add-Check ($Page, $Text, $Tag, $X, $Y) { $c = New-Object System.Windows.Forms.CheckBox; $c.Text = $Text; $c.Tag = $Tag; $c.Location = New-Object System.Drawing.Point($X, $Y); $c.AutoSize = $true; $c.Font = "Segoe UI, 11"; $Page.Controls.Add($c); return $c }

# Tab 1: Hệ Thống
$T1 = Make-Tab "He Thong & Driver"; Add-Check $T1 "JUKI Tool (Auto Soft + Optimize)" "JUKI" 30 30; Add-Check $T1 "Driver Mang (3DP Net)" "3DPNet" 30 70; Add-Check $T1 "Driver Tong Hop (3DP Chip)" "3DPChip" 30 110; Add-Check $T1 "Fix Loi Game (DirectX + Visual C++)" "FixGame" 30 150; Add-Check $T1 "Hien thi file an (Registry Mod)" "ShowFile" 30 190
# Tab 2: Internet
$T2 = Make-Tab "Internet & Office"; Add-Check $T2 "Google Chrome Enterprise" "Chrome" 30 30; Add-Check $T2 "IDM Full Toolkit (Sieu toc)" "IDM" 30 70; Add-Check $T2 "AnyDesk (Dieu khien tu xa)" "AnyDesk" 30 110; Add-Check $T2 "Unikey / EVKey (Go Tieng Viet)" "EVKey" 30 150; Add-Check $T2 "Foxit PDF Reader" "PDF" 30 190; Add-Check $T2 "Notepad++ (Editor)" "NPP" 30 230
# Tab 3: Tien Ich
$T3 = Make-Tab "Tien Ich"; Add-Check $T3 "WinRAR Full (Giai nen)" "WinRAR" 30 30; Add-Check $T3 "HiBit Uninstaller (Go sach)" "HiBit" 30 70; Add-Check $T3 "FastStone Capture" "FSC" 30 110; Add-Check $T3 "TeraCopy (Copy nhanh)" "Tera" 30 150; Add-Check $T3 "Unlocker (Xoa file cung dau)" "Unlocker" 30 190
# Tab 4: Advanced (Modules)
$T4 = Make-Tab "Advanced Tools"; 
$B1 = New-Object System.Windows.Forms.Button; $B1.Text="SYSTEM SCAN (SFC/DISM)"; $B1.Location=New-Object System.Drawing.Point(30,30); $B1.Size=New-Object System.Drawing.Size(200,40); $B1.BackColor="Orange"; $B1.ForeColor="Black"; $B1.Add_Click({ Load-Module "SystemScan.ps1" }); $T4.Controls.Add($B1)
$B2 = New-Object System.Windows.Forms.Button; $B2.Text="BACKUP & RESTORE"; $B2.Location=New-Object System.Drawing.Point(30,80); $B2.Size=New-Object System.Drawing.Size(200,40); $B2.BackColor="Cyan"; $B2.ForeColor="Black"; $B2.Add_Click({ Load-Module "BackupCenter.ps1" }); $T4.Controls.Add($B2)
$B3 = New-Object System.Windows.Forms.Button; $B3.Text="APP STORE (WINGET)"; $B3.Location=New-Object System.Drawing.Point(250,30); $B3.Size=New-Object System.Drawing.Size(200,40); $B3.BackColor="LightGreen"; $B3.ForeColor="Black"; $B3.Add_Click({ Load-Module "AppStore.ps1" }); $T4.Controls.Add($B3)
$B4 = New-Object System.Windows.Forms.Button; $B4.Text="ISO DOWNLOADER"; $B4.Location=New-Object System.Drawing.Point(250,80); $B4.Size=New-Object System.Drawing.Size(200,40); $B4.BackColor="Yellow"; $B4.ForeColor="Black"; $B4.Add_Click({ Load-Module "ISODownloader.ps1" }); $T4.Controls.Add($B4)
$B5 = New-Object System.Windows.Forms.Button; $B5.Text="DATA RECOVERY (TOOL)"; $B5.Location=New-Object System.Drawing.Point(30,130); $B5.Size=New-Object System.Drawing.Size(200,40); $B5.BackColor="Red"; $B5.ForeColor="White"; $B5.Add_Click({ Tai-Va-Chay "Disk.Genius.rar" "DiskGenius.rar" "Portable" }); $T4.Controls.Add($B5)
$B6 = New-Object System.Windows.Forms.Button
$B6.Text = "CHECK THONG TIN MAY & DRIVER"
$B6.Location = New-Object System.Drawing.Point(250, 130)
$B6.Size = New-Object System.Drawing.Size(200, 40)
$B6.BackColor = "Purple"
$B6.ForeColor = "White"
$B6.Add_Click({ Load-Module "SystemInfo.ps1" })
$T4.Controls.Add($B6)
# Thêm vào Tab 4 hoặc nơi ông thích
$B_InstallWin = New-Object System.Windows.Forms.Button
$B_InstallWin.Text = "CÀI WIN TỰ ĐỘNGĐỘNG (ISO)"
$B_InstallWin.Location = New-Object System.Drawing.Point(470, 80) # Chỉnh tọa độ cho đẹp
$B_InstallWin.Size = New-Object System.Drawing.Size(180, 40)
$B_InstallWin.BackColor = "Pink"
$B_InstallWin.ForeColor = "Black"
$B_InstallWin.Add_Click({ Load-Module "WinInstall.ps1" })
$T4.Controls.Add($B_InstallWin)
# Buttons Bottom
$BtnSelectAll = New-Object System.Windows.Forms.Button; $BtnSelectAll.Text = "Chon All"; $BtnSelectAll.Location = New-Object System.Drawing.Point(20, 470); $BtnSelectAll.Size = New-Object System.Drawing.Size(80, 30); $BtnSelectAll.BackColor = "Gray"; $BtnSelectAll.Add_Click({ foreach ($P in $TabControl.TabPages) { foreach ($C in $P.Controls) { if ($C -is [System.Windows.Forms.CheckBox]) { $C.Checked = $true } } } }); $Form.Controls.Add($BtnSelectAll)
$BtnUncheck = New-Object System.Windows.Forms.Button; $BtnUncheck.Text = "Bo Chon"; $BtnUncheck.Location = New-Object System.Drawing.Point(110, 470); $BtnUncheck.Size = New-Object System.Drawing.Size(80, 30); $BtnUncheck.BackColor = "Gray"; $BtnUncheck.Add_Click({ foreach ($P in $TabControl.TabPages) { foreach ($C in $P.Controls) { if ($C -is [System.Windows.Forms.CheckBox]) { $C.Checked = $false } } } }); $Form.Controls.Add($BtnUncheck)

$BtnInstall = New-Object System.Windows.Forms.Button; $BtnInstall.Text = "CAI DAT DA CHON"; $BtnInstall.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold); $BtnInstall.Size = New-Object System.Drawing.Size(200, 60); $BtnInstall.Location = New-Object System.Drawing.Point(490, 470); $BtnInstall.BackColor = "LimeGreen"; $BtnInstall.ForeColor = "Black"; $BtnInstall.FlatStyle = "Flat"
$BtnInstall.Add_Click({
    $BtnInstall.Enabled = $false; $BtnInstall.Text = "DANG CAI..."
    foreach ($P in $TabControl.TabPages) {
        foreach ($C in $P.Controls) {
            if ($C -is [System.Windows.Forms.CheckBox] -and $C.Checked) {
                $Tag = $C.Tag
                switch ($Tag) {
                    "JUKI" { Tai-Va-Chay "JUKI.exe" "JUKI.exe" "Portable" }
                    "3DPNet" { Tai-Va-Chay "3DP.Net.exe" "3DPNet.exe" "Portable" }
                    "3DPChip" { Tai-Va-Chay "3DP.Chip.exe" "3DPChip.exe" "Portable" }
                    "FixGame" { Tai-Va-Chay "DirectX.repack.exe" "DX.exe" "Portable"; Tai-Va-Chay "vcredist.all.in.one.by.MMT.Windows.Tech.exe" "VC.exe" "Portable" }
                    "ShowFile" { Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" 1; Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 0; Stop-Process -Name explorer -Force }
                    "Chrome" { $C = "$TempDir\Chrome.msi"; Invoke-WebRequest "https://dl.google.com/chrome/install/googlechromestandaloneenterprise64.msi" -OutFile $C; Start-Process "msiexec.exe" -ArgumentList "/i `"$C`" /quiet /norestart" -Wait }
                    "IDM" { Tai-Va-Chay "IDM.MMT.WINDOWS.TECH.exe" "IDM.exe" "Portable" }
                    "AnyDesk" { Tai-Va-Chay "Anydesk.6.2.1.exe" "AnyDesk.exe" "Portable" }
                    "EVKey" { Tai-Va-Chay "EVKey.Setup.exe" "EVKey.exe" "Portable" }
                    "PDF" { Tai-Va-Chay "FoxitPDFReader.exe" "Foxit.exe" "Exe" }
                    "NPP" { Tai-Va-Chay "Notepad++.exe" "NPP.exe" "Exe" }
                    "WinRAR" { Tai-Va-Chay "WinRAR.7.13.exe" "WinRAR.exe" "Exe" }
                    "HiBit" { Tai-Va-Chay "HiBitUninstaller.exe" "HiBit.exe" "Portable" }
                    "FSC" { Tai-Va-Chay "FastStone.Capture.exe" "FSC.exe" "Portable" }
                    "Tera" { Tai-Va-Chay "TeraCopy.Pro.v3.17.0.0.exe" "Tera.exe" "Portable" }
                    "Unlocker" { Tai-Va-Chay "Unlocker1.9.2.exe" "Unlock.exe" "Portable" }
                }
                $C.Checked = $false
            }
        }
    }
    [System.Windows.Forms.MessageBox]::Show("Da hoan tat!", "Phat Tan PC"); $BtnInstall.Text = "CAI DAT DA CHON"; $BtnInstall.Enabled = $true
})
$Form.Controls.Add($BtnInstall)

# --- MINI BUTTONS ---
function Add-MiniBtn ($Txt, $Col, $X, $Y, $Act) { $b = New-Object System.Windows.Forms.Button; $b.Text = $Txt; $b.Location = New-Object System.Drawing.Point($X, $Y); $b.Size = New-Object System.Drawing.Size(115, 35); $b.BackColor = $Col; $b.ForeColor = "Black"; $b.FlatStyle = "Flat"; $b.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold); $b.Add_Click($Act); $Form.Controls.Add($b) }

Add-MiniBtn "RAM BOOSTER" "Orange" 20 540 { Load-Module "RamBooster.ps1" }
Add-MiniBtn "WALLPAPER" "Cyan" 145 540 { try { $Code = @'
using System; using System.Runtime.InteropServices; public class W { [DllImport("user32.dll")] public static extern int SystemParametersInfo(int u, int v, string s, int f); }
'@
Add-Type -TypeDefinition $Code -ErrorAction SilentlyContinue; $J = Invoke-RestMethod "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US"; $Img = "$env:TEMP\bing.jpg"; Invoke-WebRequest ("https://www.bing.com" + $J.images[0].urlbase + "_1920x1080.jpg") -OutFile $Img; [W]::SystemParametersInfo(20, 0, $Img, 3); [System.Windows.Forms.MessageBox]::Show("Da doi hinh nen!", "Phat Tan PC") } catch {} }
Add-MiniBtn "WINPE CUU HO" "Yellow" 270 540 { Tai-Va-Chay "WinPE_CuuHo.exe" "WinPE_Setup.exe" "Portable" }
Add-MiniBtn "ACTIVE WIN" "Magenta" 395 540 { $Form.WindowState = "Minimized"; irm https://get.activated.win | iex; $Form.WindowState = "Normal" }

$Form.ShowDialog() | Out-Null
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
