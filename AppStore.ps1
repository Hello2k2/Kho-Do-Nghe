# --- 1. TU DONG YEU CAU QUYEN ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- CẤU HÌNH LOGGING ---
$LogDir = "$env:TEMP\PhatTan_Log"
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
$EnvLogFile = "$LogDir\Environment_Install.log"

function Write-Log {
    param($Message, $Type="INFO")
    $Time = Get-Date -Format "HH:mm:ss"; $LogLine = "[$Time] [$Type] $Message"
    if ($Type -eq "ERROR") { Write-Host $LogLine -ForegroundColor Red } elseif ($Type -eq "SUCCESS") { Write-Host $LogLine -ForegroundColor Green } else { Write-Host $LogLine -ForegroundColor Cyan }
    $LogLine | Out-File -FilePath $EnvLogFile -Append -Encoding UTF8
}

# --- HÀM CÀI ĐẶT MÔI TRƯỜNG (FIXED) ---
function Install-Environment {
    param($StatusLabel, $Form)
    $StatusLabel.Text = "Dang xu ly... (Xem log)"; $StatusLabel.ForeColor = "Yellow"; $Form.Refresh()
    "=== BAT DAU CAI DAT (V12.0 FIXED) ===" | Out-File -FilePath $EnvLogFile -Encoding UTF8
    [System.Net.ServicePointManager]::SecurityProtocol = 3072

    # 1. WINGET (Fix thieu WindowsAppRuntime)
    if (Get-Command winget -ErrorAction SilentlyContinue) { Write-Log "Winget da co." "OK" } else {
        Write-Log "Bat dau cai Winget (Full Dependencies)..."
        try {
            $WorkDir = "$env:TEMP\Winget_Install"; New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
            $WC = New-Object Net.WebClient
            
            # A. Cài Windows App SDK (Quan trọng để fix lỗi 0x80073CF3)
            Write-Log "Dang tai Windows App SDK..."
            $WC.DownloadFile("https://aka.ms/windowsappsdk/latest/1.6-stable/windowsappruntimeinstall-x64.exe", "$WorkDir\WinAppSDK.exe")
            Write-Log "Dang cai Windows App SDK (Silent)..."
            Start-Process -FilePath "$WorkDir\WinAppSDK.exe" -ArgumentList "--quiet" -Wait
            
            # B. Cài UI.Xaml
            Write-Log "Dang tai UI.Xaml..."
            $WC.DownloadFile("https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx", "$WorkDir\UI.Xaml.appx")
            Add-AppxPackage -Path "$WorkDir\UI.Xaml.appx" -ErrorAction SilentlyContinue

            # C. Cài VCLibs
            Write-Log "Dang tai VCLibs..."
            $WC.DownloadFile("https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx", "$WorkDir\VCLibs.appx")
            Add-AppxPackage -Path "$WorkDir\VCLibs.appx" -ErrorAction SilentlyContinue

            # D. Cài Winget Core
            Write-Log "Dang tai Winget Core..."
            $WC.DownloadFile("https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle", "$WorkDir\Winget.msixbundle")
            Write-Log "Dang Add-AppxPackage Winget..."
            Add-AppxPackage -Path "$WorkDir\Winget.msixbundle" -ForceUpdateFromAnyVersion -ErrorAction Stop
            
            Write-Log "Cai Winget THANH CONG." "SUCCESS"
            Remove-Item $WorkDir -Recurse -Force
        } catch { Write-Log "LOI WINGET: $($_.Exception.Message)" "ERROR" }
    }

    # 2. CHOCOLATEY
    if (Get-Command choco -ErrorAction SilentlyContinue) { Write-Log "Choco da co." "OK" } else {
        # Fix lỗi folder tồn tại nhưng mất path
        if (Test-Path "$env:ProgramData\chocolatey\bin\choco.exe") {
            Write-Log "Fix Path cho Choco..."
            $env:Path += ";$env:ProgramData\chocolatey\bin"
        } else {
            Write-Log "Dang cai Chocolatey..."
            try {
                Set-ExecutionPolicy Bypass -Scope Process -Force
                $Script = (New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')
                Invoke-Expression $Script | Out-File -FilePath $EnvLogFile -Append
                $env:Path += ";$env:ProgramData\chocolatey\bin"
                Write-Log "Cai Choco THANH CONG." "SUCCESS"
            } catch { Write-Log "LOI CHOCO: $($_.Exception.Message)" "ERROR" }
        }
    }

    # 3. SCOOP (Fix Security Error)
    if (Get-Command scoop -ErrorAction SilentlyContinue) { Write-Log "Scoop da co." "OK" } else {
        Write-Log "Dang cai Scoop (Local Script)..."
        try {
            Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            # Tải file script về máy trước (Tránh lỗi Security Error khi chạy online)
            $ScoopInstaller = "$env:TEMP\install_scoop.ps1"
            (New-Object Net.WebClient).DownloadFile('https://get.scoop.sh', $ScoopInstaller)
            
            Write-Log "Dang chay file cai dat Scoop..."
            # Chạy file local
            & $ScoopInstaller | Out-File -FilePath $EnvLogFile -Append
            
            $env:Path += ";$env:USERPROFILE\scoop\shims"
            Write-Log "Cai Scoop THANH CONG." "SUCCESS"
        } catch { Write-Log "LOI SCOOP: $($_.Exception.Message)" "ERROR" }
    }
    
    $StatusLabel.Text = "Hoan tat. Check Log!"; $StatusLabel.ForeColor = "Lime"
    Write-Log "=== KET THUC ===" "END"
}

# --- GUI SETUP (Phần dưới giữ nguyên) ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "APP STORE - PHAT TAN PC (V12.0 FINAL FIX)"
$Form.Size = New-Object System.Drawing.Size(1000, 600)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30); $Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

$Lbl = New-Object System.Windows.Forms.Label; $Lbl.Text = "TEN PHAN MEM:"; $Lbl.Location = "15,15"; $Lbl.AutoSize=$true; $Form.Controls.Add($Lbl)
$TxtSearch = New-Object System.Windows.Forms.TextBox; $TxtSearch.Size = "350,30"; $TxtSearch.Location = "15,40"; $TxtSearch.Font="Segoe UI, 11"; $Form.Controls.Add($TxtSearch)

$CbSource = New-Object System.Windows.Forms.ComboBox; $CbSource.Location="380,40"; $CbSource.Size="120,30"; $CbSource.DropDownStyle="DropDownList"; $CbSource.Items.AddRange(@("Nguon: All", "Winget", "Chocolatey", "Scoop")); $CbSource.SelectedIndex=0; $Form.Controls.Add($CbSource)
$CbStatus = New-Object System.Windows.Forms.ComboBox; $CbStatus.Location="510,40"; $CbStatus.Size="120,30"; $CbStatus.DropDownStyle="DropDownList"; $CbStatus.Items.AddRange(@("Trang thai: All", "Chua cai", "Da cai")); $CbStatus.SelectedIndex=0; $Form.Controls.Add($CbStatus)

$BtnSearch = New-Object System.Windows.Forms.Button; $BtnSearch.Text="TIM KIEM"; $BtnSearch.Location="640,38"; $BtnSearch.Size="80,32"; $BtnSearch.BackColor="Cyan"; $BtnSearch.ForeColor="Black"; $Form.Controls.Add($BtnSearch)
$BtnFix = New-Object System.Windows.Forms.Button; $BtnFix.Text="FIX MOI TRUONG"; $BtnFix.Location="730,38"; $BtnFix.Size="120,32"; $BtnFix.BackColor="Orange"; $BtnFix.ForeColor="Black"; $Form.Controls.Add($BtnFix)
$BtnLog = New-Object System.Windows.Forms.Button; $BtnLog.Text="LOGS"; $BtnLog.Location="860,38"; $BtnLog.Size="60,32"; $BtnLog.BackColor="Gray"; $BtnLog.ForeColor="White"; $Form.Controls.Add($BtnLog)

$Grid = New-Object System.Windows.Forms.DataGridView; $Grid.Location = "15,90"; $Grid.Size = "950,380"; $Grid.BackgroundColor = [System.Drawing.Color]::FromArgb(40,40,40); $Grid.ForeColor="Black"; $Grid.AllowUserToAddRows=$false; $Grid.RowHeadersVisible=$false; $Grid.SelectionMode="FullRowSelect"; $Grid.MultiSelect=$false; $Grid.ReadOnly=$false; $Grid.AutoSizeColumnsMode="Fill"
$ColChk = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn; $ColChk.Name="Select"; $ColChk.HeaderText="[X]"; $ColChk.Width=30; $ColChk.AutoSizeMode="None"; $Grid.Columns.Add($ColChk) | Out-Null
$Grid.Columns.Add("Source", "NGUON"); $Grid.Columns["Source"].ReadOnly=$true; $Grid.Columns["Source"].FillWeight=15
$Grid.Columns.Add("Name", "TEN PHAN MEM"); $Grid.Columns["Name"].ReadOnly=$true; $Grid.Columns["Name"].FillWeight=35
$Grid.Columns.Add("ID", "ID GOI"); $Grid.Columns["ID"].ReadOnly=$true; $Grid.Columns["ID"].FillWeight=25
$Grid.Columns.Add("Ver", "VERSION"); $Grid.Columns["Ver"].ReadOnly=$true; $Grid.Columns["Ver"].FillWeight=15
$Grid.Columns.Add("Status", "TRANG THAI"); $Grid.Columns["Status"].ReadOnly=$true; $Grid.Columns["Status"].FillWeight=15
$Form.Controls.Add($Grid)

$BtnInstall = New-Object System.Windows.Forms.Button; $BtnInstall.Text="CAI DAT CAC APP DA CHON"; $BtnInstall.Location="300,490"; $BtnInstall.Size="400,50"; $BtnInstall.BackColor="LimeGreen"; $BtnInstall.ForeColor="Black"; $BtnInstall.Font="Segoe UI, 12, Bold"; $BtnInstall.Enabled=$false; $Form.Controls.Add($BtnInstall)
$StatusLbl = New-Object System.Windows.Forms.Label; $StatusLbl.Text="San sang."; $StatusLbl.Location="15,550"; $StatusLbl.AutoSize=$true; $StatusLbl.ForeColor="Yellow"; $Form.Controls.Add($StatusLbl)

$BtnLog.Add_Click({ if (Test-Path $EnvLogFile) { Invoke-Item $EnvLogFile } else { [System.Windows.Forms.MessageBox]::Show("Chua co log.", "Info") } })
$BtnFix.Add_Click({ $BtnFix.Enabled=$false; Install-Environment $StatusLbl $Form; $BtnFix.Enabled=$true; [System.Windows.Forms.MessageBox]::Show("Da chay xong! Bam LOGS de kiem tra.", "Phat Tan PC") })

$BtnSearch.Add_Click({
    $Kw = $TxtSearch.Text; if (!$Kw) { return }
    $Grid.Rows.Clear(); $BtnSearch.Text="..."; $StatusLbl.Text="Dang tim..."; $Form.Refresh()
    $SrcFilter = $CbSource.SelectedItem; $StatFilter = $CbStatus.SelectedItem

    # CHOCO
    if (($SrcFilter -match "All|Choco") -and (Get-Command choco -ErrorAction SilentlyContinue)) {
        $Raw = choco search "$Kw" --limit-output --order-by-popularity
        foreach ($L in $Raw) {
            if ($L -match "^(.*?)\|(.*?)$") { 
                $P = $L -split "\|"; $Stat = "Chua cai"
                if (Test-Path "$env:ChocolateyInstall\lib\$($P[0])") { $Stat = "Da cai" }
                if ($StatFilter -eq "Trang thai: All" -or $StatFilter -match $Stat) { $Grid.Rows.Add($false, "Choco", $P[0], $P[0], $P[1], $Stat) | Out-Null }
            }
        }
    }
    # SCOOP
    if (($SrcFilter -match "All|Scoop") -and (Get-Command scoop -ErrorAction SilentlyContinue)) {
        $RawS = scoop search "$Kw"; $RawList = $RawS -split "`r`n"
        foreach ($Line in $RawList) {
            if ($Line -match "^(\S+)\s+(\S+)\s+(\S+)") {
               $Parts = $Line -split "\s+"; $Stat = "Chua cai"
               if ($Parts -contains "*global*") { $Stat = "Da cai" }
               if ($StatFilter -eq "Trang thai: All" -or $StatFilter -match $Stat) { $Grid.Rows.Add($false, "Scoop", $Parts[0], $Parts[0], $Parts[1], $Stat) | Out-Null }
            }
        }
    }
    $BtnSearch.Text="TIM KIEM"; $StatusLbl.Text="Tim thay $($Grid.Rows.Count) ket qua."; if ($Grid.Rows.Count -gt 0) { $BtnInstall.Enabled=$true }
})

$BtnInstall.Add_Click({
    $Tasks = @(); foreach ($Row in $Grid.Rows) { if ($Row.Cells[0].Value -eq $true) { $Tasks += @{ Src=$Row.Cells[1].Value; ID=$Row.Cells[3].Value; Name=$Row.Cells[2].Value } } }
    if ($Tasks.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Chon it nhat 1 app!", "Luu y"); return }
    $LogFile = "$LogDir\Apps_Install.log"
    $ScriptBody = "param(`$ListApps)`n`$Host.UI.RawUI.WindowTitle = 'PHAT TAN PC - INSTALLER'`nfunction Log(`$m) { Write-Host `"`$m`" -F Cyan; `$l='['+(Get-Date -Format 'HH:mm:ss')+'] ' + `$m; `$l | Out-File '$LogFile' -Append }`n"
    foreach ($Task in $Tasks) {
        $Cmd = ""; if ($Task.Src -eq "Choco") { $Cmd = "choco install $($Task.ID) -y" } elseif ($Task.Src -eq "Scoop") { $Cmd = "scoop install $($Task.ID)" }
        $ScriptBody += "Log '>>> Dang cai: $($Task.Name)'; $Cmd | Out-File '$LogFile' -Append; Log '--- XONG ---'; Start-Sleep -s 2;`n"
    }
    $ScriptBody += "Write-Host 'DA CAI XONG!' -F Green; Read-Host 'Enter de thoat...'"
    $Bytes = [System.Text.Encoding]::Unicode.GetBytes($ScriptBody); $Encoded = [Convert]::ToBase64String($Bytes)
    Start-Process powershell -ArgumentList "-NoExit", "-EncodedCommand", "$Encoded"
})

$CtxMenu = New-Object System.Windows.Forms.ContextMenuStrip
$Grid.ContextMenuStrip = $CtxMenu; $Grid.Add_CellMouseDown({ param($s, $e) if ($e.Button -eq 'Right' -and $e.RowIndex -ge 0) { $Grid.ClearSelection(); $Grid.Rows[$e.RowIndex].Selected = $true } })
$CtxMenu.Items.Add("Copy ID").Add_Click({ if ($Grid.SelectedRows.Count -gt 0) { [System.Windows.Forms.Clipboard]::SetText($Grid.SelectedRows[0].Cells[3].Value) } })
$CtxMenu.Items.Add("Go cai dat").Add_Click({ if ($Grid.SelectedRows.Count -eq 0) { return }; $Row = $Grid.SelectedRows[0]; $ID = $Row.Cells[3].Value; $Src = $Row.Cells[1].Value; $Cmd = ""; if ($Src -eq "Choco") { $Cmd = "choco uninstall $ID -y" } elseif ($Src -eq "Scoop") { $Cmd = "scoop uninstall $ID" }; if ($Cmd) { Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'DANG GO: $ID' -F Red; $Cmd; Read-Host 'Xong...'" } })

Add-Type -AssemblyName Microsoft.VisualBasic
$Form.ShowDialog() | Out-Null
