# --- 1. TU DONG YEU CAU QUYEN ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# Thiết lập encoding UTF-8 cho Console để không lỗi font khi chạy nền
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- CẤU HÌNH LOGGING ---
$LogDir = "C:\PhatTan_Log"
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
$EnvLogFile = "$LogDir\Environment_Install.log"

function Write-Log {
    param($Message, $Type="INFO")
    $Time = Get-Date -Format "HH:mm:ss"; $LogLine = "[$Time] [$Type] $Message"
    if ($Type -eq "ERROR") { Write-Host $LogLine -ForegroundColor Red } elseif ($Type -eq "SUCCESS") { Write-Host $LogLine -ForegroundColor Green } else { Write-Host $LogLine -ForegroundColor Cyan }
    $LogLine | Out-File -FilePath $EnvLogFile -Append -Encoding UTF8
}

# --- HÀM CÀI ĐẶT MÔI TRƯỜNG (SMART CHECK) ---
function Install-Environment {
    param($StatusLabel, $Form)
    $StatusLabel.Text = "Đang xử lý... (Smart Check)"; $StatusLabel.ForeColor = "Yellow"; $Form.Refresh()
    "=== BẮT ĐẦU CÀI ĐẶT (V15.0 SMART) ===" | Out-File -FilePath $EnvLogFile -Encoding UTF8
    [System.Net.ServicePointManager]::SecurityProtocol = 3072

    # ==========================================
    # 1. CHOCOLATEY (FIX CLEAN)
    # ==========================================
    if (Get-Command choco -ErrorAction SilentlyContinue) { 
        Write-Log "Choco đã có." "OK" 
    } else {
        if (Test-Path "$env:ProgramData\chocolatey\bin\choco.exe") {
            $env:Path += ";$env:ProgramData\chocolatey\bin"; Write-Log "Fix đường dẫn Choco."
        } else {
            # Xóa sạch thư mục cũ nếu lỗi
            if (Test-Path "$env:ProgramData\chocolatey") { Remove-Item "$env:ProgramData\chocolatey" -Recurse -Force; Write-Log "Đã dọn dẹp thư mục Choco cũ." }
            
            Write-Log "Đang cài Chocolatey..."
            try {
                Set-ExecutionPolicy Bypass -Scope Process -Force
                iex ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
                $env:Path += ";$env:ProgramData\chocolatey\bin"
                Write-Log "Cài Choco THÀNH CÔNG." "SUCCESS"
            } catch { Write-Log "LỖI CHOCO: $($_.Exception.Message)" "ERROR" }
        }
    }

    # ==========================================
    # 2. WINGET (SMART DEPENDENCY CHECK)
    # ==========================================
    if (Get-Command winget -ErrorAction SilentlyContinue) { 
        Write-Log "Winget đã có." "OK" 
    } else {
        Write-Log "Kiểm tra Winget Dependencies..."
        try {
            $WorkDir = "C:\Winget_Temp"; New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
            $WC = New-Object Net.WebClient
            
            # A. CHECK WINDOWS APP SDK
            if (Get-AppxPackage *Microsoft.WindowsAppRuntime*) {
                Write-Log "Windows App SDK đã có. Bỏ qua." "SKIP"
            } else {
                Write-Log "Thiếu Windows App SDK. Đang tải..."
                $WC.DownloadFile("https://aka.ms/windowsappsdk/latest/1.6-stable/windowsappruntimeinstall-x64.exe", "$WorkDir\WinAppSDK.exe")
                Start-Process -FilePath "$WorkDir\WinAppSDK.exe" -ArgumentList "--quiet" -Wait
                Write-Log "Cài SDK xong."
            }

            # B. CHECK UI.XAML
            if (Get-AppxPackage *Microsoft.UI.Xaml.2.8*) {
                Write-Log "UI.Xaml 2.8 đã có. Bỏ qua." "SKIP"
            } else {
                Write-Log "Thiếu UI.Xaml. Đang tải..."
                $WC.DownloadFile("https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx", "$WorkDir\UI.Xaml.appx")
                Add-AppxPackage -Path "$WorkDir\UI.Xaml.appx" -ErrorAction SilentlyContinue
            }

            # C. CHECK VCLIBS
            if (Get-AppxPackage *Microsoft.VCLibs.140.00.UWPDesktop*) {
                Write-Log "VCLibs đã có. Bỏ qua." "SKIP"
            } else {
                Write-Log "Thiếu VCLibs. Đang tải..."
                $WC.DownloadFile("https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx", "$WorkDir\VCLibs.appx")
                Add-AppxPackage -Path "$WorkDir\VCLibs.appx" -ErrorAction SilentlyContinue
            }

            # D. CAI WINGET CORE (LUÔN CÀI NẾU CHƯA CÓ LỆNH)
            Write-Log "Đang tải Winget Core..."
            $WC.DownloadFile("https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle", "$WorkDir\Winget.msixbundle")
            Add-AppxPackage -Path "$WorkDir\Winget.msixbundle" -ForceUpdateFromAnyVersion -ErrorAction Stop
            
            Write-Log "Cài Winget THÀNH CÔNG." "SUCCESS"
            Remove-Item $WorkDir -Recurse -Force
        } catch { Write-Log "LỖI WINGET: $($_.Exception.Message)" "ERROR" }
    }

    # ==========================================
    # 3. SCOOP (Smart Check)
    # ==========================================
    if (Get-Command scoop -ErrorAction SilentlyContinue) { 
        Write-Log "Scoop đã có." "OK" 
    } else {
        if (Test-Path "$env:USERPROFILE\scoop\shims\scoop.cmd") {
            $env:Path += ";$env:USERPROFILE\scoop\shims"; Write-Log "Fix đường dẫn Scoop."
        } else {
            Write-Log "Đang cài Scoop..."
            try {
                Set-ExecutionPolicy Bypass -Scope Process -Force
                # One-liner chuẩn, bypass policy
                Invoke-Expression "& {$(irm get.scoop.sh)} -RunAsAdmin" 2>&1 | Out-File -FilePath $EnvLogFile -Append
                $env:Path += ";$env:USERPROFILE\scoop\shims"
                Write-Log "Cài Scoop THÀNH CÔNG." "SUCCESS"
            } catch { Write-Log "LỖI SCOOP: $($_.Exception.Message)" "ERROR" }
        }
    }
    
    $StatusLabel.Text = "Hoàn tất. Kiểm tra log!"
    $StatusLabel.ForeColor = "Lime"
    Write-Log "=== KẾT THÚC ===" "END"
}

# --- GUI SETUP (GIỮ NGUYÊN) ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "KHO PHẦN MỀM - PHÁT TÂN PC (V15.0 SMART CHECK)"
$Form.Size = New-Object System.Drawing.Size(1000, 600)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30); $Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

$Lbl = New-Object System.Windows.Forms.Label; $Lbl.Text = "TÊN PHẦN MỀM:"; $Lbl.Location = "15,15"; $Lbl.AutoSize=$true; $Form.Controls.Add($Lbl)
$TxtSearch = New-Object System.Windows.Forms.TextBox; $TxtSearch.Size = "350,30"; $TxtSearch.Location = "15,40"; $TxtSearch.Font="Segoe UI, 11"; $Form.Controls.Add($TxtSearch)

$CbSource = New-Object System.Windows.Forms.ComboBox; $CbSource.Location="380,40"; $CbSource.Size="120,30"; $CbSource.DropDownStyle="DropDownList"; $CbSource.Items.AddRange(@("Nguồn: Tất cả", "Winget", "Chocolatey", "Scoop")); $CbSource.SelectedIndex=0; $Form.Controls.Add($CbSource)
$CbStatus = New-Object System.Windows.Forms.ComboBox; $CbStatus.Location="510,40"; $CbStatus.Size="120,30"; $CbStatus.DropDownStyle="DropDownList"; $CbStatus.Items.AddRange(@("Trạng thái: Tất cả", "Chưa cài", "Đã cài")); $CbStatus.SelectedIndex=0; $Form.Controls.Add($CbStatus)

$BtnSearch = New-Object System.Windows.Forms.Button; $BtnSearch.Text="TÌM KIẾM"; $BtnSearch.Location="640,38"; $BtnSearch.Size="80,32"; $BtnSearch.BackColor="Cyan"; $BtnSearch.ForeColor="Black"; $Form.Controls.Add($BtnSearch)
$BtnFix = New-Object System.Windows.Forms.Button; $BtnFix.Text="SỬA MÔI TRƯỜNG"; $BtnFix.Location="730,38"; $BtnFix.Size="120,32"; $BtnFix.BackColor="Orange"; $BtnFix.ForeColor="Black"; $Form.Controls.Add($BtnFix)
$BtnLog = New-Object System.Windows.Forms.Button; $BtnLog.Text="LOGS"; $BtnLog.Location="860,38"; $BtnLog.Size="60,32"; $BtnLog.BackColor="Gray"; $BtnLog.ForeColor="White"; $Form.Controls.Add($BtnLog)

$Grid = New-Object System.Windows.Forms.DataGridView; $Grid.Location = "15,90"; $Grid.Size = "950,380"; $Grid.BackgroundColor = [System.Drawing.Color]::FromArgb(40,40,40); $Grid.ForeColor="Black"; $Grid.AllowUserToAddRows=$false; $Grid.RowHeadersVisible=$false; $Grid.SelectionMode="FullRowSelect"; $Grid.MultiSelect=$false; $Grid.ReadOnly=$false; $Grid.AutoSizeColumnsMode="Fill"
$ColChk = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn; $ColChk.Name="Select"; $ColChk.HeaderText="[X]"; $ColChk.Width=30; $ColChk.AutoSizeMode="None"; $Grid.Columns.Add($ColChk) | Out-Null
$Grid.Columns.Add("Source", "NGUỒN"); $Grid.Columns["Source"].ReadOnly=$true; $Grid.Columns["Source"].FillWeight=15
$Grid.Columns.Add("Name", "TÊN PHẦN MỀM"); $Grid.Columns["Name"].ReadOnly=$true; $Grid.Columns["Name"].FillWeight=35
$Grid.Columns.Add("ID", "ID GÓI"); $Grid.Columns["ID"].ReadOnly=$true; $Grid.Columns["ID"].FillWeight=25
$Grid.Columns.Add("Ver", "PHIÊN BẢN"); $Grid.Columns["Ver"].ReadOnly=$true; $Grid.Columns["Ver"].FillWeight=15
$Grid.Columns.Add("Status", "TRẠNG THÁI"); $Grid.Columns["Status"].ReadOnly=$true; $Grid.Columns["Status"].FillWeight=15
$Form.Controls.Add($Grid)

$BtnInstall = New-Object System.Windows.Forms.Button; $BtnInstall.Text="CÀI ĐẶT CÁC APP ĐÃ CHỌN"; $BtnInstall.Location="300,490"; $BtnInstall.Size="400,50"; $BtnInstall.BackColor="LimeGreen"; $BtnInstall.ForeColor="Black"; $BtnInstall.Font="Segoe UI, 12, Bold"; $BtnInstall.Enabled=$false; $Form.Controls.Add($BtnInstall)
$StatusLbl = New-Object System.Windows.Forms.Label; $StatusLbl.Text="Sẵn sàng."; $StatusLbl.Location="15,550"; $StatusLbl.AutoSize=$true; $StatusLbl.ForeColor="Yellow"; $Form.Controls.Add($StatusLbl)

# --- EVENT HANDLERS ---

$BtnLog.Add_Click({ if (Test-Path $EnvLogFile) { Invoke-Item $EnvLogFile } else { [System.Windows.Forms.MessageBox]::Show("Chưa có log.", "Thông báo") } })
$BtnFix.Add_Click({ $BtnFix.Enabled=$false; Install-Environment $StatusLbl $Form; $BtnFix.Enabled=$true; [System.Windows.Forms.MessageBox]::Show("Đã chạy xong! Bấm LOGS để kiểm tra.", "Phát Tân PC") })

$BtnSearch.Add_Click({
    $Kw = $TxtSearch.Text; if (!$Kw) { return }
    
    # Tự động cài môi trường nếu thiếu
    if (!(Get-Command choco -ErrorAction SilentlyContinue) -or !(Get-Command scoop -ErrorAction SilentlyContinue)) { 
        Install-Environment $StatusLbl $Form 
    }

    $Grid.Rows.Clear(); $BtnSearch.Text="..."; $StatusLbl.Text="Đang tìm..."; $Form.Refresh()
    
    $SrcFilter = $CbSource.SelectedItem
    $StatFilter = $CbStatus.SelectedItem

    # ==========================================
    # 1. XỬ LÝ CHOCO (Sửa lỗi logic "All" -> "Tất cả")
    # ==========================================
    # Logic cũ: "All|Choco" -> Sai vì menu là "Nguồn: Tất cả"
    # Logic mới: "Tất cả|Chocolatey" -> Đúng với menu
    if (($SrcFilter -match "Tất cả|Chocolatey") -and (Get-Command choco -ErrorAction SilentlyContinue)) {
        # Thêm --limit-output để output ra dạng: tên|phiên_bản (dễ xử lý hơn)
        $Raw = choco search "$Kw" --limit-output --order-by-popularity
        foreach ($L in $Raw) {
            if ($L -match "^(.*?)\|(.*?)$") { 
                $P = $L -split "\|"
                $Name = $P[0]
                $Ver = $P[1]
                
                $Stat = "Chưa cài"
                if (Test-Path "$env:ChocolateyInstall\lib\$Name") { $Stat = "Đã cài" }
                
                if ($StatFilter -eq "Trạng thái: Tất cả" -or $StatFilter -match $Stat) { 
                    $Grid.Rows.Add($false, "Choco", $Name, $Name, $Ver, $Stat) | Out-Null 
                }
            }
        }
    }

    # ==========================================
    # 2. XỬ LÝ SCOOP (Sửa lỗi logic "All" -> "Tất cả")
    # ==========================================
    if (($SrcFilter -match "Tất cả|Scoop") -and (Get-Command scoop -ErrorAction SilentlyContinue)) {
        $RawS = scoop search "$Kw"
        if ($RawS) {
            $RawList = $RawS -split "`r`n"
            foreach ($Line in $RawList) {
                # Scoop output dạng: Name Version Source Binaries...
                # Regex bắt tên và version
                if ($Line -match "^(\S+)\s+(\S+)") {
                    $Parts = $Line -split "\s+"
                    $Name = $Parts[0]
                    $Ver = $Parts[1]
                    
                    $Stat = "Chưa cài"
                    # Scoop đánh dấu app đã cài bằng *global* hoặc * trong output, nhưng check path chuẩn hơn
                    if (Test-Path "$env:USERPROFILE\scoop\apps\$Name") { $Stat = "Đã cài" }
                    
                    if ($StatFilter -eq "Trạng thái: Tất cả" -or $StatFilter -match $Stat) { 
                        $Grid.Rows.Add($false, "Scoop", $Name, $Name, $Ver, $Stat) | Out-Null 
                    }
                }
            }
        }
    }

    # ==========================================
    # 3. XỬ LÝ WINGET (Bổ sung thêm vì menu có mà code thiếu)
    # ==========================================
    if (($SrcFilter -match "Tất cả|Winget") -and (Get-Command winget -ErrorAction SilentlyContinue)) {
        # Dùng mã UTF8 để đọc tiếng Việt/ký tự đặc biệt từ Winget
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        # Tìm kiếm winget
        $RawW = winget search "$Kw" --accept-source-agreements
        if ($RawW) {
            $Lines = $RawW -split "`r`n"
            # Bỏ qua 2 dòng đầu (header)
            for ($i = 2; $i -lt $Lines.Count; $i++) {
                $Line = $Lines[$i].Trim()
                if ($Line.Length -gt 0 -and $Line -notmatch "^-") {
                    # Cắt chuỗi theo khoảng trắng lớn (2 space trở lên) để tách cột
                    $Cols = $Line -split "\s{2,}"
                    if ($Cols.Count -ge 2) {
                        $Name = $Cols[0]
                        $ID = $Cols[1]
                        $Ver = if ($Cols.Count -ge 3) { $Cols[2] } else { "?" }
                        
                        # Check đơn giản nếu winget list có ID đó
                        $Stat = "Chưa cài"
                        # (Phần check đã cài cho Winget hơi chậm nên tạm bỏ qua hoặc xử lý sau)
                        
                        if ($StatFilter -eq "Trạng thái: Tất cả" -or $StatFilter -match $Stat) { 
                            $Grid.Rows.Add($false, "Winget", $Name, $ID, $Ver, $Stat) | Out-Null 
                        }
                    }
                }
            }
        }
    }

    $BtnSearch.Text="TÌM KIẾM"; 
    $StatusLbl.Text="Tìm thấy $($Grid.Rows.Count) kết quả."
    if ($Grid.Rows.Count -gt 0) { $BtnInstall.Enabled=$true }
})

$BtnInstall.Add_Click({
    $Tasks = @(); foreach ($Row in $Grid.Rows) { if ($Row.Cells[0].Value -eq $true) { $Tasks += @{ Src=$Row.Cells[1].Value; ID=$Row.Cells[3].Value; Name=$Row.Cells[2].Value } } }
    if ($Tasks.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Chọn ít nhất 1 app!", "Lưu ý"); return }
    $LogDir = "C:\PhatTan_Log"; if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null } # Đảm bảo biến $LogDir tồn tại
    $LogFile = "$LogDir\Apps_Install.log"
    
    # Script chạy nền
    $ScriptBody = "param(`$ListApps)`n[Console]::OutputEncoding = [System.Text.Encoding]::UTF8`n`$Host.UI.RawUI.WindowTitle = 'PHAT TAN PC - INSTALLER'`nfunction Log(`$m) { Write-Host `"`$m`" -F Cyan; `$l='['+(Get-Date -Format 'HH:mm:ss')+'] ' + `$m; `$l | Out-File '$LogFile' -Append -Encoding UTF8 }`n"
    foreach ($Task in $Tasks) {
        $Cmd = ""
        # --- FIX: THÊM --ignore-checksums ĐỂ SỬA LỖI CHROME ---
        if ($Task.Src -eq "Choco") { 
            $Cmd = "choco install $($Task.ID) -y --ignore-checksums" 
        } elseif ($Task.Src -eq "Scoop") { 
            $Cmd = "scoop install $($Task.ID)" 
        }
        $ScriptBody += "Log '>>> Đang cài: $($Task.Name)'; $Cmd | Out-File '$LogFile' -Append -Encoding UTF8; Log '--- XONG ---'; Start-Sleep -s 2;`n"
    }
    $ScriptBody += "Write-Host 'ĐÃ CÀI XONG!' -F Green; Read-Host 'Enter để thoát...'"
    
    $Bytes = [System.Text.Encoding]::Unicode.GetBytes($ScriptBody); $Encoded = [Convert]::ToBase64String($Bytes)
    Start-Process powershell -ArgumentList "-NoExit", "-EncodedCommand", "$Encoded"
})

$CtxMenu = New-Object System.Windows.Forms.ContextMenuStrip
$Grid.ContextMenuStrip = $CtxMenu; $Grid.Add_CellMouseDown({ param($s, $e) if ($e.Button -eq 'Right' -and $e.RowIndex -ge 0) { $Grid.ClearSelection(); $Grid.Rows[$e.RowIndex].Selected = $true } })
$CtxMenu.Items.Add("Copy ID").Add_Click({ if ($Grid.SelectedRows.Count -gt 0) { [System.Windows.Forms.Clipboard]::SetText($Grid.SelectedRows[0].Cells[3].Value) } })
$CtxMenu.Items.Add("Cài đặt phiên bản...").Add_Click({ if ($Grid.SelectedRows.Count -eq 0) { return }; $Row = $Grid.SelectedRows[0]; $ID = $Row.Cells[3].Value; $Src = $Row.Cells[1].Value; $Ver = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập phiên bản (VD: 1.0.0):", "Version", ""); if ($Ver) { $Cmd = ""; if ($Src -eq "Choco") { $Cmd = "choco install $ID --version $Ver -y" }; if ($Cmd) { Start-Process powershell -ArgumentList "-NoExit", "-Command", "$Cmd; Read-Host" } } })
$CtxMenu.Items.Add("Gỡ cài đặt").Add_Click({ if ($Grid.SelectedRows.Count -eq 0) { return }; $Row = $Grid.SelectedRows[0]; $ID = $Row.Cells[3].Value; $Src = $Row.Cells[1].Value; $Cmd = ""; if ($Src -eq "Choco") { $Cmd = "choco uninstall $ID -y" } elseif ($Src -eq "Scoop") { $Cmd = "scoop uninstall $ID" }; if ($Cmd) { Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'ĐANG GỠ: $ID' -F Red; $Cmd; Read-Host 'Xong...'" } })

Add-Type -AssemblyName Microsoft.VisualBasic
$Form.ShowDialog() | Out-Null
