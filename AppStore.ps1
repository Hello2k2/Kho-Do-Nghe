Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "APP STORE - PHAT TAN PC (AUTO INSTALLER)"
$Form.Size = New-Object System.Drawing.Size(600, 250)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Label
$Lbl = New-Object System.Windows.Forms.Label
$Lbl.Text = "Nhap ten phan mem (VD: discord, obs, python, telegram...):"
$Lbl.AutoSize = $true; $Lbl.Location = New-Object System.Drawing.Point(20, 20); $Lbl.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Form.Controls.Add($Lbl)

# Textbox
$Txt = New-Object System.Windows.Forms.TextBox
$Txt.Size = New-Object System.Drawing.Size(540, 30); $Txt.Location = New-Object System.Drawing.Point(20, 50); $Txt.Font = New-Object System.Drawing.Font("Segoe UI", 12)
$Form.Controls.Add($Txt)

# Button
$Btn = New-Object System.Windows.Forms.Button
$Btn.Text = "TIM & CAI DAT TU DONG"
$Btn.Location = New-Object System.Drawing.Point(150, 100); $Btn.Size = New-Object System.Drawing.Size(280, 50)
$Btn.BackColor = "Cyan"; $Btn.ForeColor = "Black"; $Btn.FlatStyle = "Flat"
$Btn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

$Btn.Add_Click({
    $AppName = $Txt.Text
    if ([string]::IsNullOrWhiteSpace($AppName)) { return }
    $Form.Close()
    
    # --- SCRIPT LOGIC CHÍNH (Chuyển thành chuỗi để truyền vào CMD mới) ---
    $ScriptContent = {
        param($App)
        
        function Log-Msg ($Msg, $Color="Cyan") { Write-Host " $Msg" -ForegroundColor $Color }
        function Log-Err ($Msg) { Write-Host " $Msg" -ForegroundColor Red }
        
        $Host.UI.RawUI.WindowTitle = "PHAT TAN PC - AUTO INSTALLER: $App"
        Clear-Host
        Log-Msg "---------------------------------------------------" "Yellow"
        Log-Msg "   HE THONG CAI DAT THONG MINH (WINGET/CHOCO/SCOOP)" "Yellow"
        Log-Msg "---------------------------------------------------" "Yellow"
        
        # --- 1. KIỂM TRA & CÀI ĐẶT KHO ỨNG DỤNG ---
        if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
            Log-Msg "[*] Phat hien thieu Chocolatey. Dang cai dat..." "Magenta"
            try {
                Set-ExecutionPolicy Bypass -Scope Process -Force
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
                $env:Path += ";$env:ALLUSERSPROFILE\chocolatey\bin"
                Log-Msg "[+] Da cai xong Chocolatey!" "Green"
            } catch { Log-Err "[!] Loi cai Chocolatey." }
        }

        if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
            Log-Msg "[*] Phat hien thieu Scoop. Dang cai dat..." "Magenta"
            try {
                Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
                irm get.scoop.sh | iex
                Log-Msg "[+] Da cai xong Scoop!" "Green"
            } catch { Log-Err "[!] Loi cai Scoop." }
        }
        
        Log-Msg "---------------------------------------------------"
        Log-Msg "[>>>] DANG TIM KIEM: $App" "Cyan"
        
        $Installed = $false

        # >>> WINGET
        if (!$Installed -and (Get-Command winget -ErrorAction SilentlyContinue)) {
            Log-Msg "[1] Dang quet Winget..." "Cyan"
            $WingetSearch = winget search "$App" --source winget -n 1 | Out-String
            if ($WingetSearch -match "$App") {
                Log-Msg "    -> Tim thay tren Winget! Dang cai dat..." "Green"
                winget install "$App" -e --silent --accept-package-agreements --accept-source-agreements
                if ($?) { $Installed = $true }
            } else { Log-Msg "    -> Khong tim thay tren Winget." "Gray" }
        }

        # >>> CHOCO
        if (!$Installed -and (Get-Command choco -ErrorAction SilentlyContinue)) {
            Log-Msg "[2] Dang quet Chocolatey..." "Cyan"
            $ChocoSearch = choco search "$App" --exact --limit-output
            if ($ChocoSearch) {
                Log-Msg "    -> Tim thay tren Choco! Dang cai dat..." "Green"
                choco install "$App" -y
                if ($?) { $Installed = $true }
            } else {
                $ChocoSearchFuzzy = choco search "$App" --order-by-popularity --limit-output | Select-Object -First 1
                if ($ChocoSearchFuzzy) {
                    $PkgName = $ChocoSearchFuzzy.Split("|")[0]
                    Log-Msg "    -> Tim thay goi tuong tu: $PkgName" "Green"
                    choco install "$PkgName" -y
                    if ($?) { $Installed = $true }
                } else { Log-Msg "    -> Khong tim thay tren Choco." "Gray" }
            }
        }

        # >>> SCOOP
        if (!$Installed -and (Get-Command scoop -ErrorAction SilentlyContinue)) {
            Log-Msg "[3] Dang quet Scoop..." "Cyan"
            $ScoopSearch = scoop search "$App" | Out-String
            if ($ScoopSearch -match "bucket") {
                Log-Msg "    -> Tim thay tren Scoop! Dang cai dat..." "Green"
                scoop install "$App"
                if ($?) { $Installed = $true }
            } else { Log-Msg "    -> Khong tim thay tren Scoop." "Gray" }
        }

        # --- KẾT QUẢ ---
        if ($Installed) {
            Log-Msg "---------------------------------------------------"
            Log-Msg "[SUCCESS] DA CAI DAT THANH CONG: $App" "Green"
            Log-Msg "[*] Dang don dep rac..." "Magenta"
            Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
            if (Get-Command choco -ErrorAction SilentlyContinue) { choco clean; Remove-Item "$env:ChocolateyInstall\lib-bad" -Recurse -Force -ErrorAction SilentlyContinue }
            if (Get-Command scoop -ErrorAction SilentlyContinue) { scoop cleanup * }
            Log-Msg "[ok] May tinh da sach se!" "Green"
        } else {
            Log-Err "[FAILED] Khong tim thay phan mem nao ten la: $App"
        }
        
        Read-Host "Nhan Enter de thoat..."
    }

    # Chuyển ScriptBlock thành chuỗi và gọi trong process mới
    # Đây là cách FIX LỖI ArgumentList
    $EncodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($ScriptContent.ToString() + "`n" + "param(`$App)`n" + "`$App = '$AppName'"))
    
    # Chạy trực tiếp lệnh (cách đơn giản nhất để truyền biến)
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "& { $ScriptContent } -App '$AppName'"
})

$Form.Controls.Add($Btn)
$Form.ShowDialog() | Out-Null
