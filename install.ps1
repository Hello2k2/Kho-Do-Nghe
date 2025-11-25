<#
    TOOL CUU HO MAY TINH - PHAT TAN PC
    Author: Phat Tan
    Version: 2.1 (Final)
    Github: https://github.com/Hello2k2/Kho-Do-Nghe
#>

# --- CẤU HÌNH ---
$BaseUrl = "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/"
$RawUrl  = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/" # Dùng cho file script .ps1
$TempDir = "$env:TEMP\PhatTan_Tool"

# Tạo thư mục tạm nếu chưa có
if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir | Out-Null }

# --- HÀM HIỂN THỊ LOGO ---
function Hien-Logo {
    Clear-Host
    Write-Host "
  _____  _           _   _______   _      
 |  __ \| |         | | |__   __| (_)     
 | |__) | |__   __ _| |_   | | __ _ _ __  
 |  ___/| '_ \ / _` | __|  | |/ _` | '_ \ 
 | |    | | | | (_| | |_   | | (_| | | | |
 |_|    |_| |_|\__,_|\__|  |_|\__,_|_| |_|
                                          
    " -ForegroundColor Cyan
    Write-Host "    --- CHUYEN CUU HO MAY TINH ONLINE ---" -ForegroundColor Yellow
    Write-Host "--------------------------------------------------------" -ForegroundColor Gray
    Write-Host " [*] Author:      Phat Tan (Zalo: 0823.883.028)" -ForegroundColor White
    Write-Host " [*] Credits:     Vu Kim Dong (DONG599), Ma Minh Toan (MMT)" -ForegroundColor DarkGray
    Write-Host "                  Massgrave (MAS) & Open Source Community" -ForegroundColor DarkGray
    Write-Host "--------------------------------------------------------" -ForegroundColor Gray
    Write-Host ""
}

# --- HÀM TẢI VÀ CHẠY FILE ---
function Tai-Va-Chay {
    param (
        [string]$TenFileTrenMang,
        [string]$TenFileLuu,
        [string]$Loai # "Exe", "Msi"
    )

    $LinkTai = "$BaseUrl$TenFileTrenMang"
    $DuongDanLuu = "$TempDir\$TenFileLuu"

    Write-Host " [*] Dang tai: $TenFileLuu ..." -ForegroundColor Cyan
    
    try {
        # Dùng WebClient để tải cho ổn định
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile($LinkTai, $DuongDanLuu)

        if (Test-Path $DuongDanLuu) {
            Write-Host " [+] Tai xong! Dang khoi chay..." -ForegroundColor Green
            
            if ($Loai -eq "Msi") {
                Start-Process "msiexec.exe" -ArgumentList "/i `"$DuongDanLuu`" /quiet /norestart" -Wait
            }
            else {
                Start-Process -FilePath $DuongDanLuu -Wait
            }
            Write-Host " [+] Hoan tat!" -ForegroundColor Green
        }
        else { Write-Host " [-] Loi: File khong ton tai sau khi tai." -ForegroundColor Red }
    }
    catch {
        Write-Host " [-] LOI TAI FILE: $($_.Exception.Message)" -ForegroundColor Red
    }
    Start-Sleep -Seconds 1
}

# --- MENU CHÍNH ---
do {
    Hien-Logo
    
    Write-Host "=== HE THONG & DRIVER ===" -ForegroundColor Magenta
    Write-Host " [1]  JUKI Tool (Auto Soft + Optimize)"
    Write-Host " [2]  Driver Mang (3DP Net - Cuu mat mang)"
    Write-Host " [3]  Driver Tong Hop (3DP Chip)"
    
    Write-Host "`n=== INTERNET & REMOTE ===" -ForegroundColor Magenta
    Write-Host " [4]  AnyDesk (Dieu khien tu xa)"
    Write-Host " [5]  IDM Full Toolkit (Download sieu toc)"
    Write-Host " [6]  Chrome Enterprise (Cai tu dong)"
    
    Write-Host "`n=== VAN PHONG & TIEN ICH ===" -ForegroundColor Magenta
    Write-Host " [7]  Unikey / EVKey (Go Tieng Viet)"
    Write-Host " [8]  WinRAR (Giai nen)"
    Write-Host " [9]  Foxit PDF Reader (Doc PDF)"
    Write-Host " [10] Notepad++ (Sua code/van ban)"
    
    Write-Host "`n=== SYSTEM TOOLS & FIX ===" -ForegroundColor Magenta
    Write-Host " [11] HiBit Uninstaller (Go phan mem sach)"
    Write-Host " [12] FastStone Capture (Quay man hinh)"
    Write-Host " [13] Fix Loi Game (DirectX + Visual C++)"
    Write-Host " [14] RAM Downloader (Tang toc may tinh - Troll)" -ForegroundColor Yellow
    
    Write-Host "`n=== BAN QUYEN ===" -ForegroundColor Magenta
    Write-Host " [A]  Kich hoat Windows/Office (MAS Script)" -ForegroundColor Yellow
    
    Write-Host "--------------------------------------------------------"
    $Choice = Read-Host " [?] Nhap so de cai (0 de thoat)"

    switch ($Choice) {
        '1' { Tai-Va-Chay "JUKI.exe" "JUKI_Tool.exe" "Exe" }
        '2' { Tai-Va-Chay "3DP.Net.exe" "3DP_Net.exe" "Exe" }
        '3' { Tai-Va-Chay "3DP.Chip.exe" "3DP_Chip.exe" "Exe" }
        
        '4' { Tai-Va-Chay "Anydesk.6.2.1.exe" "AnyDesk.exe" "Exe" }
        '5' { Tai-Va-Chay "IDM.MMT.WINDOWS.TECH.exe" "IDM_Toolkit.exe" "Exe" }
        '6' { 
            Write-Host " [*] Dang tai Chrome MSI..." -ForegroundColor Cyan
            $CPath = "$TempDir\Chrome.msi"
            try {
                Invoke-WebRequest "https://dl.google.com/chrome/install/googlechromestandaloneenterprise64.msi" -OutFile $CPath
                Start-Process "msiexec.exe" -ArgumentList "/i `"$CPath`" /quiet /norestart" -Wait
                Write-Host " [+] Xong!" -ForegroundColor Green
            } catch { Write-Host " [-] Loi tai Chrome." -ForegroundColor Red }
            Pause
        }
        
        '7' { Tai-Va-Chay "EVKey.Setup.exe" "EVKey.exe" "Exe" }
        '8' { Tai-Va-Chay "WinRAR.7.13.exe" "WinRAR.exe" "Exe" }
        '9' { Tai-Va-Chay "FoxitPDFReader.exe" "FoxitReader.exe" "Exe" }
        '10' { Tai-Va-Chay "Notepad++.exe" "NotepadPP.exe" "Exe" }
        
        '11' { Tai-Va-Chay "HiBitUninstaller.exe" "HiBit.exe" "Exe" }
        '12' { Tai-Va-Chay "FastStone.Capture.exe" "FSCapture.exe" "Exe" }
        '13' { 
            Write-Host " [*] Dang cai DirectX..." -ForegroundColor Cyan
            Tai-Va-Chay "DirectX.repack.exe" "DirectX.exe" "Exe"
            Write-Host " [*] Dang cai Visual C++ AIO..." -ForegroundColor Cyan
            Tai-Va-Chay "vcredist.all.in.one.by.MMT.Windows.Tech.exe" "VCRedist.exe" "Exe"
        }
        
        '14' {
            Write-Host " [*] Dang khoi dong trinh tai RAM..." -ForegroundColor Cyan
            # Tải file script RamBooster.ps1 từ nhánh main (Code)
            $RamScriptURL = "$RawUrl" + "RamBooster.ps1"
            $RamScriptPath = "$TempDir\RamBooster.ps1"
            
            try {
                Invoke-WebRequest -Uri $RamScriptURL -OutFile $RamScriptPath
                Start-Process powershell.exe "-ExecutionPolicy Bypass -File `"$RamScriptPath`"" -Wait
                Remove-Item $RamScriptPath -Force -ErrorAction SilentlyContinue
            } catch {
                Write-Host " [-] Loi: Khong tim thay file RamBooster.ps1 tren GitHub cua ong!" -ForegroundColor Red
                Write-Host "     Nho up file nay len muc CODE nhe!" -ForegroundColor Yellow
            }
            Pause
        }
        
        'A' { 
            Write-Host " [*] Dang goi MAS..." -ForegroundColor Magenta
            irm https://massgrave.dev/get | iex 
        }
        'a' { irm https://massgrave.dev/get | iex }
        
        '0' { 
            Write-Host "Tam biet!" -ForegroundColor Gray
            Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
            break 
        }
        default { Write-Host "Nhap sai roi!" -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
} while ($true)
