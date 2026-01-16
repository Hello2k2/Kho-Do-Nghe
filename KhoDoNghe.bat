@echo off
setlocal
title PHAT TAN PC - LAUNCHER V12.6 (SYNCED)

:: --- 1. TU DONG KICH HOAT QUYEN ADMIN ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [*] Dang yeu cau quyen Quan tri vien...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: --- 2. CAU HINH DONG BO ---
set "TEMP_DIR=%TEMP%\PhatTan_Tool"
set "CHECK_FILE=%TEMP%\ps_check.txt"
set "PS_PATH=%~dp0install.ps1"

if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"
cd /d "%~dp0"

echo ================================================
echo    PHAT TAN PC - KHO DO NGHE V12.6
echo ================================================

:: --- 3. KIEM TRA POWERSHELL ---
echo [*] Kiem tra he thong...
powershell -NoProfile -ExecutionPolicy Bypass -Command "'Healthy' | Out-File -FilePath '%CHECK_FILE%'" 2>nul

if exist "%CHECK_FILE%" (
    del "%CHECK_FILE%"
    echo [+] He thong san sang!
    :: Chay file PS1 voi tham so -WindowStyle Hidden de giam bot cua so den neu muon
    powershell -NoProfile -ExecutionPolicy Bypass -File "install.ps1"
) else (
    echo [!] LOI: PowerShell bi hu hoac bi chan!
    echo [*] Dang tai bo thu vien "moi" de tu va loi...
    curl -L "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/pwsh_mini.zip" -o "%TEMP_DIR%\pwsh_mini.zip"
    echo [!] Vui long giai nen vao %TEMP_DIR% hoac lien he Phat Tan: 0823.883.028
    pause
)
exit
