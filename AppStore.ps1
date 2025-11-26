# --- 1. TU DONG YEU CAU QUYEN ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- CẤU HÌNH LOGGING ---
$LogDir = "$env:TEMP\PhatTan_Tool\Logs"
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
$LogFile = "$LogDir\AppStore_Install_$((Get-Date).ToString('yyyyMMdd')).txt"

# --- HÀM CÀI ĐẶT MÔI TRƯỜNG ---
function Install-Environment {
    param($StatusLabel, $Form)
    $StatusLabel.Text = "Dang xu ly moi truong..."
    $StatusLabel.ForeColor = "Yellow"; $Form.Refresh()
    
    # WINGET
    if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
        try {
            $Url = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
            $Path = "$env:TEMP\winget.msixbundle"
            (New-Object System.Net.WebClient).DownloadFile($Url, $Path)
            Add-AppxPackage -Path $Path; Remove-Item $Path -Force
        } catch {}
    }
    # CHOCOLATEY
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = 3072
            iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            $env:Path += ";$env:ProgramData\chocolatey\bin"
        } catch {}
    }
    # SCOOP
    if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
        try {
            Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            irm get.scoop.sh | iex; $env:Path += ";$env:USERPROFILE\scoop\shims"
        } catch {}
    }
    $StatusLabel.Text = "Moi truong OK!"; $StatusLabel.ForeColor = "Lime"
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "APP STORE - PHAT TAN PC (V9.0 LOGGING)"
$Form.Size = New-Object System.Drawing.Size(1000, 600)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30); $Form.ForeColor = "White"

# Header Controls
$Lbl = New-Object System.Windows.Forms.Label; $Lbl.Text = "TEN PHAN MEM:"; $Lbl.Location = "15,15"; $Lbl.AutoSize=$true; $Form.Controls.Add($Lbl)
$TxtSearch = New-Object System.Windows.Forms.TextBox; $TxtSearch.Size = "350,30"; $TxtSearch.Location = "15,40"; $TxtSearch.Font="Segoe UI, 11"; $Form.Controls.Add($TxtSearch)

$CbSource = New-Object System.Windows.Forms.ComboBox; $CbSource.Location="380,40"; $CbSource.Size="120,30"; $CbSource.DropDownStyle="DropDownList"; $CbSource.Items.AddRange(@("Nguon: All", "Winget", "Chocolatey", "Scoop")); $CbSource.SelectedIndex=0; $Form.Controls.Add($CbSource)
$CbStatus = New-Object System.Windows.Forms.ComboBox; $CbStatus.Location="510,40"; $CbStatus.Size="120,30"; $CbStatus.DropDownStyle="DropDownList"; $CbStatus.Items.AddRange(@("Trang thai: All", "Chua cai", "Da cai")); $CbStatus.SelectedIndex=0; $Form.Controls.Add($CbStatus)

# Buttons
$BtnSearch = New-Object System.Windows.Forms.Button; $BtnSearch.Text="TIM KIEM"; $BtnSearch.Location="640,38"; $BtnSearch.Size="100,32"; $BtnSearch.BackColor="Cyan"; $BtnSearch.ForeColor="Black"; $Form.Controls.Add($BtnSearch)
$BtnFix = New-Object System.Windows.Forms.Button; $BtnFix.Text="FIX MOI TRUONG"; $BtnFix.Location="750,38"; $BtnFix.Size="120,32"; $BtnFix.BackColor="Orange"; $BtnFix.ForeColor="Black"; $Form.Controls.Add($BtnFix)

# Nút Xem Log (Mới)
$BtnLog = New-Object System.Windows.Forms.Button; $BtnLog.Text="LOGS"; $BtnLog.Location="880,38"; $BtnLog.Size="80,32"; $BtnLog.BackColor="Gray"; $BtnLog.ForeColor="White"; $Form.Controls.Add($BtnLog)

# Grid
$Grid = New-Object System.Windows.Forms.DataGridView; $Grid.Location = "15,90"; $Grid.Size = "950,380"; $Grid.BackgroundColor = [System.Drawing.Color]::FromArgb(40,40,40); $Grid.ForeColor="Black"; $Grid.AllowUserToAddRows=$false; $Grid.RowHeadersVisible=$false; $Grid.SelectionMode="FullRowSelect"; $Grid.MultiSelect=$false; $Grid.ReadOnly=$false; $Grid.AutoSizeColumnsMode="Fill"
$ColChk = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn; $ColChk.Name="Select"; $ColChk.HeaderText="[X]"; $ColChk.Width=30; $ColChk.AutoSizeMode="None"; $Grid.Columns.Add($ColChk) | Out-Null
$Grid.Columns.Add("Source", "NGUON"); $Grid.Columns["Source"].ReadOnly=$true; $Grid.Columns["Source"].FillWeight=15
$Grid.Columns.Add("Name", "TEN PHAN MEM"); $Grid.Columns["Name"].ReadOnly=$true; $Grid.Columns["Name"].FillWeight=35
$Grid.Columns.Add("ID", "ID GOI"); $Grid.Columns["ID"].ReadOnly=$true; $Grid.Columns["ID"].FillWeight=25
$Grid.Columns.Add("Ver", "VERSION"); $Grid.Columns["Ver"].ReadOnly=$true; $Grid.Columns["Ver"].FillWeight=15
$Grid.Columns.Add("Status", "TRANG THAI"); $Grid.Columns["Status"].ReadOnly=$true; $Grid.Columns["Status"].FillWeight=15
$Form.Controls.Add($Grid)

# Install Button & Status
$BtnInstall = New-Object System.Windows.Forms.Button; $BtnInstall.Text="CAI DAT CAC APP DA CHON"; $BtnInstall.Location="300,490"; $BtnInstall.Size="400,50"; $BtnInstall.BackColor="LimeGreen"; $BtnInstall.ForeColor="Black"; $BtnInstall.Font="Segoe UI, 12, Bold"; $BtnInstall.Enabled=$false; $Form.Controls.Add($BtnInstall)
$StatusLbl = New-Object System.Windows.Forms.Label; $StatusLbl.Text="San sang."; $StatusLbl.Location="15,550"; $StatusLbl.AutoSize=$true; $StatusLbl.ForeColor="Yellow"; $Form.Controls.Add($StatusLbl)

# --- EVENTS ---
$BtnFix.Add_Click({ $BtnFix.Enabled=$false; Install-Environment $StatusLbl $Form; $BtnFix.Enabled=$true; [System.Windows.Forms.MessageBox]::Show("Da Fix Moi Truong!", "Phat Tan PC") })

$BtnLog.Add_Click({ 
    if (Test-Path $LogFile) { Invoke-Item $LogFile } else { [System.Windows.Forms.MessageBox]::Show("Chua co log nao!", "Thong bao") } 
})

$BtnSearch.Add_Click({
    $Kw = $TxtSearch.Text; if (!$Kw) { return }
    $Grid.Rows.Clear(); $BtnSearch.Text="..."; $StatusLbl.Text="Dang tim..."; $Form.Refresh()
    $SrcFilter = $CbSource.SelectedItem; $StatFilter = $CbStatus.SelectedItem

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

    # SCRIPT LOGIC: Thêm chức năng ghi File Log
    $ScriptBody = "param(`$ListApps, `$LogPath)`n`$Host.UI.RawUI.WindowTitle = 'PHAT TAN PC - INSTALLER'`n"
    $ScriptBody += "function Log(`$m) { Write-Host `"`$m`" -F Cyan; Add-Content -Path `$LogPath -Value `"`$([DateTime]::Now): `$m`" }`n"
    $ScriptBody += "Log '=== BAT DAU CAI DAT ==='`n"
    
    foreach ($Task in $Tasks) {
        $Cmd = ""; if ($Task.Src -eq "Choco") { $Cmd = "choco install $($Task.ID) -y" } elseif ($Task.Src -eq "Scoop") { $Cmd = "scoop install $($Task.ID)" }
        $ScriptBody += "Log '>>> Dang cai dat: $($Task.Name)'; $Cmd | Out-String | ForEach-Object { Log `$_ }; Log '--- XONG ---'; Start-Sleep -s 2;`n"
    }
    $ScriptBody += "Log '=== DA CAI XONG TAT CA! ==='; Write-Host 'DA XONG!' -F Green; Read-Host 'An Enter de thoat...'"

    $Bytes = [System.Text.Encoding]::Unicode.GetBytes($ScriptBody); $Encoded = [Convert]::ToBase64String($Bytes)
    
    # Truyền đường dẫn file log vào script con
    Start-Process powershell -ArgumentList "-NoExit", "-EncodedCommand", "$Encoded", "-ArgumentList", "`"$LogFile`""
})

# Context Menu
$CtxMenu = New-Object System.Windows.Forms.ContextMenuStrip
$Grid.ContextMenuStrip = $CtxMenu; $Grid.Add_CellMouseDown({ param($s, $e) if ($e.Button -eq 'Right' -and $e.RowIndex -ge 0) { $Grid.ClearSelection(); $Grid.Rows[$e.RowIndex].Selected = $true } })
$CtxMenu.Items.Add("Copy ID").Add_Click({ if ($Grid.SelectedRows.Count -gt 0) { [System.Windows.Forms.Clipboard]::SetText($Grid.SelectedRows[0].Cells[3].Value) } })
$CtxMenu.Items.Add("Cai dat phien ban...").Add_Click({ if ($Grid.SelectedRows.Count -eq 0) { return }; $Row = $Grid.SelectedRows[0]; $ID = $Row.Cells[3].Value; $Src = $Row.Cells[1].Value; $Ver = [Microsoft.VisualBasic.Interaction]::InputBox("Nhap phien ban:", "Version", ""); if ($Ver) { $Cmd = ""; if ($Src -eq "Choco") { $Cmd = "choco install $ID --version $Ver -y" }; if ($Cmd) { Start-Process powershell -ArgumentList "-NoExit", "-Command", "$Cmd; Read-Host" } } })
$MenuUninstall = $CtxMenu.Items.Add("Go cai dat (Uninstall)"); $MenuUninstall.Add_Click({ if ($Grid.SelectedRows.Count -eq 0) { return }; $Row = $Grid.SelectedRows[0]; $ID = $Row.Cells[3].Value; $Src = $Row.Cells[1].Value; $Cmd = ""; if ($Src -eq "Choco") { $Cmd = "choco uninstall $ID -y" } elseif ($Src -eq "Scoop") { $Cmd = "scoop uninstall $ID" }; if ($Cmd) { Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'DANG GO: $ID' -F Red; $Cmd; Read-Host 'Xong...'" } })

Add-Type -AssemblyName Microsoft.VisualBasic
$Form.ShowDialog() | Out-Null
