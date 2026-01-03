# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"

# --- THEME NEON ---
$Theme = @{
    Back      = [System.Drawing.Color]::FromArgb(30, 30, 35)
    Card      = [System.Drawing.Color]::FromArgb(45, 45, 50)
    Text      = [System.Drawing.Color]::FromArgb(240, 240, 240)
    Accent    = [System.Drawing.Color]::FromArgb(0, 255, 127) # SpringGreen
    Warn      = [System.Drawing.Color]::FromArgb(255, 165, 0)
    Err       = [System.Drawing.Color]::FromArgb(255, 69, 0)
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "DATA & SYSTEM RESCUE (V3.0 ULTIMATE)"
$Form.Size = New-Object System.Drawing.Size(900, 650)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back; $Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "PHAT TAN RESCUE CENTER"; $LblT.Font = "Impact, 22"; $LblT.ForeColor = $Theme.Accent; $LblT.AutoSize = $true; $LblT.Location = "20,10"
$Form.Controls.Add($LblT)

# --- TAB CONTROL ---
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = "20, 60"; $TabControl.Size = "845, 380"
$Form.Controls.Add($TabControl)

function Add-Page ($Title) { $p=New-Object System.Windows.Forms.TabPage; $p.Text=$Title; $p.BackColor=$Theme.Card; $p.ForeColor=$Theme.Text; $TabControl.Controls.Add($p); return $p }
function Add-Chk ($P, $T, $X, $Y, $Tag) { $c=New-Object System.Windows.Forms.CheckBox; $c.Text=$T; $c.Location="$X,$Y"; $c.AutoSize=$true; $c.Tag=$Tag; $c.Font="Segoe UI, 10"; $c.ForeColor="White"; $P.Controls.Add($c); return $c }

# ==========================================
# TAB 1: BACKUP (SAO LƯU)
# ==========================================
$TabBackup = Add-Page "  1. BACKUP SYSTEM  "

$LblB1 = New-Object System.Windows.Forms.Label; $LblB1.Text = "Nơi lưu trữ (Destination):"; $LblB1.Location = "20,20"; $LblB1.AutoSize = $true; $TabBackup.Controls.Add($LblB1)
$TxtDest = New-Object System.Windows.Forms.TextBox; $TxtDest.Location = "20,45"; $TxtDest.Size = "650,25"; $TabBackup.Controls.Add($TxtDest)
if(Test-Path "D:\"){$TxtDest.Text="D:\PhatTan_Backup"}else{$TxtDest.Text="C:\PhatTan_Backup"}

$BtnBrowseB = New-Object System.Windows.Forms.Button; $BtnBrowseB.Text="..."; $BtnBrowseB.Location="680,43"; $BtnBrowseB.Size="40,27"; $BtnBrowseB.FlatStyle="Flat"; $TabBackup.Controls.Add($BtnBrowseB)
$BtnBrowseB.Add_Click({ $F=New-Object System.Windows.Forms.FolderBrowserDialog; if($F.ShowDialog() -eq "OK"){$TxtDest.Text=$F.SelectedPath+"\PhatTan_Backup"} })

# GROUP 1: BASIC DATA
$GbBasic = New-Object System.Windows.Forms.GroupBox; $GbBasic.Text="Dữ liệu cơ bản"; $GbBasic.Location="20,80"; $GbBasic.Size="390,120"; $GbBasic.ForeColor="Cyan"; $TabBackup.Controls.Add($GbBasic)
$cB_Wifi = Add-Chk $GbBasic "Wifi Passwords (All)" 20 30 "Wifi"
$cB_Drv  = Add-Chk $GbBasic "Drivers (Export DISM)" 20 60 "Driver"
$cB_Data = Add-Chk $GbBasic "User Data (Desktop/Doc...)" 200 30 "UserData"
$cB_Font = Add-Chk $GbBasic "Installed Fonts" 200 60 "Fonts"

# GROUP 2: APPS & SYSTEM (NEW!)
$GbAdv = New-Object System.Windows.Forms.GroupBox; $GbAdv.Text="Apps & System (Nâng cao)"; $GbAdv.Location="430,80"; $GbAdv.Size="390,120"; $GbAdv.ForeColor="SpringGreen"; $TabBackup.Controls.Add($GbAdv)
$cB_IDM   = Add-Chk $GbAdv "IDM (Key + Data + Settings)" 20 30 "IDM"
$cB_Start = Add-Chk $GbAdv "Start Menu & Taskbar Layout" 20 60 "StartLayout"
$cB_Hosts = Add-Chk $GbAdv "File Hosts (Chặn QC)" 20 90 "Hosts"
$cB_HTML  = Add-Chk $GbAdv "Xuất List phần mềm (HTML)" 220 30 "HTML"
$cB_Zalo  = Add-Chk $GbAdv "Zalo PC Data" 220 60 "Zalo"

$BtnRunBackup = New-Object System.Windows.Forms.Button; $BtnRunBackup.Text="CHẠY BACKUP (FULL OPTIONS)"; $BtnRunBackup.Location="20,290"; $BtnRunBackup.Size="805,50"; $BtnRunBackup.BackColor=$Theme.Accent; $BtnRunBackup.ForeColor="Black"; $BtnRunBackup.FlatStyle="Flat"; $BtnRunBackup.Font="Segoe UI, 13, Bold"
$TabBackup.Controls.Add($BtnRunBackup)

# ==========================================
# TAB 2: RESTORE (KHÔI PHỤC)
# ==========================================
$TabRestore = Add-Page "  2. RESTORE SYSTEM  "

$LblR1 = New-Object System.Windows.Forms.Label; $LblR1.Text = "Chọn thư mục Backup:"; $LblR1.Location = "20,20"; $LblR1.AutoSize = $true; $TabRestore.Controls.Add($LblR1)
$TxtSource = New-Object System.Windows.Forms.TextBox; $TxtSource.Location = "20,45"; $TxtSource.Size = "650,25"; $TabRestore.Controls.Add($TxtSource)
$BtnBrowseR = New-Object System.Windows.Forms.Button; $BtnBrowseR.Text="CHỌN..."; $BtnBrowseR.Location="680,43"; $BtnBrowseR.Size="80,27"; $BtnBrowseR.FlatStyle="Flat"; $TabRestore.Controls.Add($BtnBrowseR)
$BtnBrowseR.Add_Click({ $F=New-Object System.Windows.Forms.FolderBrowserDialog; if($F.ShowDialog() -eq "OK"){$TxtSource.Text=$F.SelectedPath} })

$GbRes = New-Object System.Windows.Forms.GroupBox; $GbRes.Text="Chọn mục cần Khôi phục"; $GbRes.Location="20,80"; $GbRes.Size="805,180"; $GbRes.ForeColor="Orange"; $TabRestore.Controls.Add($GbRes)

# Restore Columns
$cR_Wifi = Add-Chk $GbRes "Wifi Passwords" 30 30 "Wifi"
$cR_Drv  = Add-Chk $GbRes "Drivers (Auto Install)" 30 60 "Driver"
$cR_Data = Add-Chk $GbRes "User Data (Ghi đè)" 30 90 "UserData"

$cR_IDM   = Add-Chk $GbRes "IDM (Reg + Settings)" 250 30 "IDM"
$cR_Start = Add-Chk $GbRes "Start Menu Layout" 250 60 "StartLayout"
$cR_Hosts = Add-Chk $GbRes "File Hosts" 250 90 "Hosts"

$cR_Zalo = Add-Chk $GbRes "Zalo PC Data" 500 30 "Zalo"
$cR_Font = Add-Chk $GbRes "Install Fonts" 500 60 "Fonts"

$BtnRunRestore = New-Object System.Windows.Forms.Button; $BtnRunRestore.Text="TIẾN HÀNH KHÔI PHỤC (DANGEROUS)"; $BtnRunRestore.Location="20,290"; $BtnRunRestore.Size="805,50"; $BtnRunRestore.BackColor="Firebrick"; $BtnRunRestore.ForeColor="White"; $BtnRunRestore.FlatStyle="Flat"; $BtnRunRestore.Font="Segoe UI, 13, Bold"
$TabRestore.Controls.Add($BtnRunRestore)

# --- LOG AREA ---
$TxtLog = New-Object System.Windows.Forms.TextBox; $TxtLog.Multiline=$true; $TxtLog.Location="20,460"; $TxtLog.Size="845,130"; $TxtLog.BackColor="Black"; $TxtLog.ForeColor="Lime"; $TxtLog.ReadOnly=$true; $TxtLog.ScrollBars="Vertical"; $TxtLog.Font="Consolas, 10"
$Form.Controls.Add($TxtLog)

function Log ($M) { $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $M`r`n"); $TxtLog.ScrollToCaret(); [System.Windows.Forms.Application]::DoEvents() }
function Copy-Item-R ($S, $D) { if(Test-Path $S){ Copy-Item $S $D -Force; Log "Copied: $S" } else { Log "Miss: $S" } }

# ==========================================
# LOGIC GENERATE HTML LIST
# ==========================================
function Export-HTML-List ($Path) {
    Log "Generating HTML Software List..."
    $RegPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $Apps = Get-ItemProperty $RegPath | Where-Object {$_.DisplayName -ne $null} | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Sort-Object DisplayName
    
    $HTML = @"
<html><head><title>DANH SÁCH PHẦN MỀM</title>
<style>
body { font-family: 'Segoe UI', sans-serif; background: #222; color: #fff; padding: 20px; }
h1 { color: #00FF7F; border-bottom: 2px solid #555; padding-bottom: 10px; }
input { width: 100%; padding: 10px; margin-bottom: 20px; font-size: 16px; background: #333; color: white; border: 1px solid #555; }
table { width: 100%; border-collapse: collapse; }
th, td { padding: 12px; text-align: left; border-bottom: 1px solid #444; }
th { background-color: #333; color: #00FF7F; }
tr:hover { background-color: #444; }
</style>
<script>
function filterTable() {
  var input, filter, table, tr, td, i, txtValue;
  input = document.getElementById("myInput");
  filter = input.value.toUpperCase();
  table = document.getElementById("myTable");
  tr = table.getElementsByTagName("tr");
  for (i = 0; i < tr.length; i++) {
    td = tr[i].getElementsByTagName("td")[0];
    if (td) {
      txtValue = td.textContent || td.innerText;
      if (txtValue.toUpperCase().indexOf(filter) > -1) { tr[i].style.display = ""; } else { tr[i].style.display = "none"; }
    }       
  }
}
</script>
</head><body>
<h1>DANH SÁCH PHẦN MỀM ĐÃ CÀI - $(Get-Date -F 'dd/MM/yyyy')</h1>
<input type="text" id="myInput" onkeyup="filterTable()" placeholder="Tìm kiếm tên phần mềm...">
<table id="myTable">
<tr><th>Tên phần mềm</th><th>Phiên bản</th><th>Nhà phát hành</th></tr>
"@
    foreach ($a in $Apps) {
        $HTML += "<tr><td>$($a.DisplayName)</td><td>$($a.DisplayVersion)</td><td>$($a.Publisher)</td></tr>`n"
    }
    $HTML += "</table></body></html>"
    $HTML | Out-File "$Path\Software_List.html" -Encoding UTF8
    Log "Export HTML Done: $Path\Software_List.html"
    Invoke-Item "$Path\Software_List.html"
}

# ==========================================
# LOGIC BACKUP
# ==========================================
$BtnRunBackup.Add_Click({
    $Dst = "$($TxtDest.Text)\Backup_$(Get-Date -F 'ddMM_HHmm')"
    New-Item -ItemType Directory -Path "$Dst\System" -Force | Out-Null
    New-Item -ItemType Directory -Path "$Dst\AppData" -Force | Out-Null
    
    # 1. IDM (Registry + AppData)
    if ($cB_IDM.Checked) {
        Log "Backing up IDM (Registry & Data)..."
        # Export Registry Settings & License info
        Start-Process "reg.exe" "export `"HKCU\Software\DownloadManager`" `"$Dst\System\IDM_Reg.reg`" /y" -Wait
        # Backup AppData (Lists, DwnlData)
        if (Test-Path "$env:APPDATA\IDM") { Copy-Item "$env:APPDATA\IDM" "$Dst\AppData\IDM" -Recurse -Force }
        if (Test-Path "$env:APPDATA\DwnlData") { Copy-Item "$env:APPDATA\DwnlData" "$Dst\AppData\DwnlData" -Recurse -Force }
    }

    # 2. START MENU & TASKBAR & HOSTS
    if ($cB_Start.Checked) {
        Log "Backing up Start Menu & Taskbar..."
        # Start Menu Registry (Quan trọng cho Win 10/11)
        Start-Process "reg.exe" "export `"HKCU\Software\Microsoft\Windows\CurrentVersion\CloudStore`" `"$Dst\System\StartMenu_CloudStore.reg`" /y" -Wait
        # Taskbar Shortcuts
        if (Test-Path "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar") {
            New-Item "$Dst\System\TaskbarIcons" -ItemType Directory -Force | Out-Null
            Copy-Item "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*" "$Dst\System\TaskbarIcons" -Force
        }
    }
    
    # 3. HOSTS FILE
    if ($cB_Hosts.Checked) {
        Log "Backing up Hosts file..."
        Copy-Item "C:\Windows\System32\drivers\etc\hosts" "$Dst\System\hosts_backup" -Force
    }

    # 4. WIFI & DRIVERS
    if ($cB_Wifi.Checked) { 
        New-Item "$Dst\System\Wifi" -ItemType Directory -Force | Out-Null
        netsh wlan export profile key=clear folder="$Dst\System\Wifi" | Out-Null; Log "Wifi Exported." 
    }
    if ($cB_Drv.Checked) {
        Log "Exporting Drivers (Wait ~5 mins)..."
        New-Item "$Dst\Drivers" -ItemType Directory -Force | Out-Null
        Start-Process "dism.exe" "/online /export-driver /destination:`"$Dst\Drivers`"" -NoNewWindow -Wait
    }

    # 5. USER DATA & ZALO & FONTS
    if ($cB_Data.Checked) {
        foreach ($F in @("Desktop", "Documents", "Pictures", "Downloads")) {
            Log "Robocopy: $F"
            Start-Process "robocopy.exe" "`"$env:USERPROFILE\$F`" `"$Dst\UserData\$F`" /E /MT:16 /R:0 /W:0 /NFL /NDL" -NoNewWindow -Wait
        }
    }
    if ($cB_Zalo.Checked) {
        Log "Backing up ZaloPC..."
        Start-Process "robocopy.exe" "`"$env:APPDATA\ZaloPC`" `"$Dst\AppData\ZaloPC`" /E /MT:16 /R:0 /W:0 /NFL /NDL" -NoNewWindow -Wait
    }
    if ($cB_HTML.Checked) { Export-HTML-List $Dst }

    Log "--- BACKUP COMPLETED ---"
    [System.Windows.Forms.MessageBox]::Show("Backup thành công!", "Phat Tan PC")
    Invoke-Item $Dst
})

# ==========================================
# LOGIC RESTORE
# ==========================================
$BtnRunRestore.Add_Click({
    $Src = $TxtSource.Text
    if (!(Test-Path $Src)) { [System.Windows.Forms.MessageBox]::Show("Folder không tồn tại!", "Lỗi"); return }
    if ([System.Windows.Forms.MessageBox]::Show("Dữ liệu cũ sẽ bị ghi đè. Tiếp tục?", "Cảnh báo", "YesNo", "Warning") -eq "No") { return }

    # 1. RESTORE IDM
    if ($cR_IDM.Checked) {
        Log "Restoring IDM..."
        Stop-Process -Name "IDMan" -ErrorAction SilentlyContinue
        # Import Registry
        if (Test-Path "$Src\System\IDM_Reg.reg") { Start-Process "reg.exe" "import `"$Src\System\IDM_Reg.reg`"" -Wait }
        # Restore AppData
        if (Test-Path "$Src\AppData\IDM") { Copy-Item "$Src\AppData\IDM" "$env:APPDATA" -Recurse -Force }
        if (Test-Path "$Src\AppData\DwnlData") { Copy-Item "$Src\AppData\DwnlData" "$env:APPDATA" -Recurse -Force }
    }

    # 2. RESTORE HOSTS
    if ($cR_Hosts.Checked) {
        Log "Restoring Hosts..."
        Copy-Item "$Src\System\hosts_backup" "C:\Windows\System32\drivers\etc\hosts" -Force
    }

    # 3. RESTORE START MENU
    if ($cR_Start.Checked) {
        Log "Restoring Start Menu (Registry)..."
        # Kill Explorer to refresh
        Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
        if (Test-Path "$Src\System\StartMenu_CloudStore.reg") { Start-Process "reg.exe" "import `"$Src\System\StartMenu_CloudStore.reg`"" -Wait }
        if (Test-Path "$Src\System\TaskbarIcons") { Copy-Item "$Src\System\TaskbarIcons\*" "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar" -Force }
        Start-Sleep -s 2
        Start-Process "explorer.exe"
    }

    # 4. BASIC RESTORE
    if ($cR_Wifi.Checked) { Get-ChildItem "$Src\System\Wifi\*.xml" | ForEach { netsh wlan add profile filename="$($_.FullName)" } }
    if ($cR_Drv.Checked) { Start-Process "pnputil.exe" "/add-driver `"$Src\Drivers\*.inf`" /subdirs /install" -Wait }
    if ($cR_Zalo.Checked) { 
        Stop-Process -Name "Zalo" -ErrorAction SilentlyContinue
        Copy-Item "$Src\AppData\ZaloPC" "$env:APPDATA" -Recurse -Force 
    }
    if ($cR_Data.Checked) {
        foreach ($F in @("Desktop", "Documents", "Pictures", "Downloads")) {
            if (Test-Path "$Src\UserData\$F") { Copy-Item "$Src\UserData\$F\*" "$env:USERPROFILE\$F" -Recurse -Force }
        }
    }

    Log "--- RESTORE FINISHED ---"
    [System.Windows.Forms.MessageBox]::Show("Đã khôi phục xong! Vui lòng khởi động lại máy.", "Thông báo")
})

$Form.ShowDialog() | Out-Null
