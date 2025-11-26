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
$Lbl.AutoSize = $true; $Lbl.Location = New-Object System.Drawing.Point(20, 20); $Lbl.Font = "Segoe UI, 10"
$Form.Controls.Add($Lbl)

# Textbox
$Txt = New-Object System.Windows.Forms.TextBox
$Txt.Size = New-Object System.Drawing.Size(540, 30); $Txt.Location = New-Object System.Drawing.Point(20, 50); $Txt.Font = "Segoe UI, 12"
$Form.Controls.Add($Txt)

# Button
$Btn = New-Object System.Windows.Forms.Button
$Btn.Text = "TIM & CAI DAT TU DONG"
$Btn.Location = New-Object System.Drawing.Point(150, 100); $Btn.Size = New-Object System.Drawing.Size(280, 50)
$Btn.BackColor = "Cyan"; $Btn.ForeColor = "Black"; $Btn.FlatStyle = "Flat"; $Btn.Font = "Segoe UI, 10, Bold"

$Btn.Add_Click({
    $AppName = $Txt.Text
    if ([string]::IsNullOrWhiteSpace($AppName)) { return }
    $Form.Close()
    
    # --- SCRIPT LOGIC CHÍNH ---
    $ScriptBlock = {
        param($App)
        
        function Log-Msg ($Msg, $Color="Cyan") { Write-Host " $Msg" -ForegroundColor $Color }
        function Log-Err ($Msg) { Write-Host " $Msg" -ForegroundColor Red }
        
        $Host.UI.RawUI.WindowTitle = "PHAT TAN PC - AUTO INSTALLER: $App"
        Clear-Host
        Log-Msg "---------------------------------------------------" "Yellow"
        Log-Msg "   HE THONG CAI DAT THONG MINH (WINGET/CHOCO/SCOOP)" "Yellow"
        Log-Msg "---------------------------------------------------" "Yellow"
        
        # --- 1. KIỂM TRA & CÀI ĐẶT KHO ỨNG DỤNG (NẾU THIẾU) ---
        
        # Check Chocolatey
        if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
            Log-Msg "[*] Phat hien thieu Chocolatey. Dang cai dat..." "Magenta"
            try {
                Set-ExecutionPolicy Bypass -Scope Process -Force
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
                $env:Path += ";$env:ALLUSERSPROFILE\chocolatey\bin" # Refresh Path tạm
                Log-Msg "[+] Da cai xong Chocolatey!" "Green"
            } catch { Log-Err "[!] Loi cai Chocolatey." }
        }

        # Check Scoop
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
        
        # --- 2. TIẾN HÀNH TÌM VÀ CÀI (THEO ƯU TIÊN) ---
        $Installed = $false

        # >>> UU TIEN 1: WINGET (Chinh chu MS)
        if (!$Installed -and (Get-Command winget -ErrorAction SilentlyContinue)) {
            Log-Msg "[1] Dang quet Winget..." "Cyan"
            # Tìm ID của kết quả đầu tiên (Chính xác nhất)
            $WingetSearch = winget search "$App" --source winget -n 1 | Out-String
            
            # Logic "Mò" ID từ kết quả trả về (Hơi thủ công vì Winget trả về Text)
            if ($WingetSearch -match "$App") {
                Log-Msg "    -> Tim thay tren Winget!" "Green"
                Log-Msg "    -> Dang cai dat..." "Yellow"
                # Cài đặt im lặng, chấp nhận mọi thỏa thuận
                winget install "$App" -e --silent --accept-package-agreements --accept-source-agreements
                if ($?) { $Installed = $true }
            } else {
                Log-Msg "    -> Khong tim thay tren Winget." "Gray"
            }
        }

        # >>> UU TIEN 2: CHOCOLATEY (Phổ biến)
        if (!$Installed -and (Get-Command choco -ErrorAction SilentlyContinue)) {
            Log-Msg "[2] Dang quet Chocolatey..." "Cyan"
            $ChocoSearch = choco search "$App" --exact --limit-output
            if ($ChocoSearch) {
                Log-Msg "    -> Tim thay tren Choco!" "Green"
                Log-Msg "    -> Dang cai dat..." "Yellow"
                choco install "$App" -y
                if ($?) { $Installed = $true }
            } else {
                # Thử tìm gần đúng nếu exact không ra
                $ChocoSearchFuzzy = choco search "$App" --order-by-popularity --limit-output | Select-Object -First 1
                if ($ChocoSearchFuzzy) {
                    $PkgName = $ChocoSearchFuzzy.Split("|")[0]
                    Log-Msg "    -> Tim thay goi tuong tu: $PkgName" "Green"
                    choco install "$PkgName" -y
                    if ($?) { $Installed = $true }
                } else {
                     Log-Msg "    -> Khong tim thay tren Choco." "Gray"
                }
            }
        }

        # >>> UU TIEN 3: SCOOP (Portable/Dev)
        if (!$Installed -and (Get-Command scoop -ErrorAction SilentlyContinue)) {
            Log-Msg "[3] Dang quet Scoop..." "Cyan"
            $ScoopSearch = scoop search "$App" | Out-String
            if ($ScoopSearch -match "bucket") { # Scoop trả về bucket nếu tìm thấy
                Log-Msg "    -> Tim thay tren Scoop!" "Green"
                Log-Msg "    -> Dang cai dat..." "Yellow"
                scoop install "$App"
                if ($?) { $Installed = $true }
            } else {
                 Log-Msg "    -> Khong tim thay tren Scoop." "Gray"
            }
        }

        # --- 3. KẾT QUẢ & DỌN DẸP ---
        if ($Installed) {
            Log-Msg "---------------------------------------------------"
            Log-Msg "[SUCCESS] DA CAI DAT THANH CONG: $App" "Green"
            
            Log-Msg "[*] Dang don dep ruc (Clean Up)..." "Magenta"
            # Dọn rác Choco/Temp
            Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
            if (Get-Command choco -ErrorAction SilentlyContinue) { choco clean; Remove-Item "$env:ChocolateyInstall\lib-bad" -Recurse -Force -ErrorAction SilentlyContinue }
            if (Get-Command scoop -ErrorAction SilentlyContinue) { scoop cleanup * }
            
            Log-Msg "[ok] May tinh da sach se!" "Green"
        } else {
            Log-Err "[FAILED] Khong tim thay phan mem nao ten la: $App"
            Log-Err "Vui long kiem tra lai ten (VD: go 'obs-studio' thay vi 'obs')"
        }
        
        Read-Host "Nhan Enter de thoat..."
    }

    Start-Process powershell -ArgumentList "-NoExit", "-Command", $ScriptBlock -ArgumentList $AppName
})

$Form.Controls.Add($Btn)
$Form.ShowDialog() | Out-Null
