# --- 1. FORCE ADMIN & PRE-SETUP ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- 2. THEME NEON (Modern Dark) ---
$Theme = @{
    Back      = [System.Drawing.Color]::FromArgb(32, 32, 32)
    Panel     = [System.Drawing.Color]::FromArgb(45, 45, 48)
    Text      = [System.Drawing.Color]::FromArgb(240, 240, 240)
    Accent    = [System.Drawing.Color]::FromArgb(0, 120, 215) # Blue Metro
    Warning   = [System.Drawing.Color]::FromArgb(255, 140, 0)
    Success   = [System.Drawing.Color]::FromArgb(40, 167, 69)
    Border    = [System.Drawing.Color]::FromArgb(60, 60, 60)
}

# --- 3. HELPER FUNCTIONS FOR UI ---
function New-Panel ($Parent, $Dock, $Padding) {
    $P = New-Object System.Windows.Forms.Panel
    $P.Dock = $Dock; $P.BackColor = $Theme.Panel; $P.Padding = $Padding
    if ($Parent) { $Parent.Controls.Add($P) }
    return $P
}

function New-Label ($Parent, $Txt, $FontStyles, $Color) {
    $L = New-Object System.Windows.Forms.Label
    $L.Text = $Txt; $L.AutoSize = $true; $L.ForeColor = $Color
    if ($FontStyles -eq "Title") { $L.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold) }
    elseif ($FontStyles -eq "Header") { $L.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold) }
    else { $L.Font = New-Object System.Drawing.Font("Segoe UI", 10) }
    if ($Parent) { $Parent.Controls.Add($L) }
    return $L
}

function New-Button ($Parent, $Txt, $Color, $W, $H, $Event) {
    $B = New-Object System.Windows.Forms.Button
    $B.Text = $Txt; $B.BackColor = $Color; $B.ForeColor = "White"
    $B.FlatStyle = "Flat"; $B.FlatAppearance.BorderSize = 0
    $B.Size = New-Object System.Drawing.Size($W, $H); $B.Cursor = "Hand"
    $B.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $B.Add_Click($Event)
    if ($Parent) { $Parent.Controls.Add($B) }
    return $B
}

# --- 4. MAIN FORM SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "OFFICE MASTER TOOLKIT - DEVELOPED BY PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(1100, 750)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back; $Form.ForeColor = $Theme.Text

# --- HEADER ---
$HeaderPanel = New-Panel $Form "Top" (New-Object System.Windows.Forms.Padding(10))
$HeaderPanel.Height = 60; $HeaderPanel.BackColor = $Theme.Back
$Title = New-Label $HeaderPanel "MICROSOFT OFFICE DEPLOYMENT & ACTIVATION HUB" "Title" $Theme.Accent
$Title.Location = New-Object System.Drawing.Point(10, 15)

# --- MAIN LAYOUT (TABLE LAYOUT) ---
# Chia giao diện làm 4 phần bằng TableLayoutPanel để không phải set cứng tọa độ
$Table = New-Object System.Windows.Forms.TableLayoutPanel
$Table.Dock = "Fill"; $Table.ColumnCount = 2; $Table.RowCount = 2
$Table.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 50)))
$Table.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 50)))
$Table.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 55))) # Hàng trên lớn hơn chút
$Table.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 45)))
$Table.Padding = New-Object System.Windows.Forms.Padding(10)
$Form.Controls.Add($Table)

# --- SECTION 1: SELECTION (Top Left) ---
$Pnl1 = New-Panel $Table "Fill" (New-Object System.Windows.Forms.Padding(10))
$Table.Controls.Add($Pnl1, 0, 0)
New-Label $Pnl1 "1. PHIÊN BẢN & KIẾN TRÚC" "Header" $Theme.Warning | Out-Null

$GbVer = New-Object System.Windows.Forms.GroupBox; $GbVer.Text = "Chọn Phiên Bản"; $GbVer.ForeColor = "White"; $GbVer.Location = "15, 40"; $GbVer.Size = "220, 180"
$Pnl1.Controls.Add($GbVer)
$OfficeVers = @("Office 2016", "Office 2019", "Office 2021", "Office 2024", "Microsoft 365")
$RadioVers = @(); $vY = 25
foreach ($V in $OfficeVers) {
    $R = New-Object System.Windows.Forms.RadioButton; $R.Text = $V; $R.Location = "15, $vY"; $R.AutoSize = $true; $GbVer.Controls.Add($R)
    if ($V -eq "Office 2021") { $R.Checked = $true }; $RadioVers += $R; $vY += 30
}

$GbArch = New-Object System.Windows.Forms.GroupBox; $GbArch.Text = "Hệ (Bit)"; $GbArch.ForeColor = "White"; $GbArch.Location = "250, 40"; $GbArch.Size = "200, 80"
$Pnl1.Controls.Add($GbArch)
$R64 = New-Object System.Windows.Forms.RadioButton; $R64.Text = "x64 (Chuẩn)"; $R64.Location = "15, 30"; $R64.AutoSize = $true; $R64.Checked = $true; $GbArch.Controls.Add($R64)
$R86 = New-Object System.Windows.Forms.RadioButton; $R86.Text = "x86 (Máy cũ)"; $R86.Location = "110, 30"; $R86.AutoSize = $true; $GbArch.Controls.Add($R86)

# --- SECTION 2: APPS (Top Right) ---
$Pnl2 = New-Panel $Table "Fill" (New-Object System.Windows.Forms.Padding(10))
$Table.Controls.Add($Pnl2, 1, 0)
New-Label $Pnl2 "2. ỨNG DỤNG CẦN CÀI" "Header" $Theme.Warning | Out-Null

$FlowApp = New-Object System.Windows.Forms.FlowLayoutPanel; $FlowApp.Location = "15, 40"; $FlowApp.Size = "450, 250"; $FlowApp.AutoScroll = $true
$Pnl2.Controls.Add($FlowApp)
$AppsList = @("Word", "Excel", "PowerPoint", "Outlook", "OneNote", "Access", "Publisher", "Teams", "OneDrive", "SkypeForBusiness")
$ChkApps = @()
foreach ($A in $AppsList) {
    $C = New-Object System.Windows.Forms.CheckBox; $C.Text = $A; $C.Width = 130; $C.Checked = ($A -match "Word|Excel|PowerPoint")
    $FlowApp.Controls.Add($C); $ChkApps += $C
}

# --- SECTION 3: CONFIG (Bottom Left) ---
$Pnl3 = New-Panel $Table "Fill" (New-Object System.Windows.Forms.Padding(10))
$Table.Controls.Add($Pnl3, 0, 1)
New-Label $Pnl3 "3. CẤU HÌNH NÂNG CAO" "Header" $Theme.Warning | Out-Null

$GbExt = New-Object System.Windows.Forms.GroupBox; $GbExt.Text = "Sản phẩm & Ngôn ngữ"; $GbExt.ForeColor = "White"; $GbExt.Location = "15, 40"; $GbExt.Size = "450, 100"
$Pnl3.Controls.Add($GbExt)

$ChkVisio = New-Object System.Windows.Forms.CheckBox; $ChkVisio.Text = "Visio Pro"; $ChkVisio.Location = "15, 25"; $ChkVisio.AutoSize = $true; $GbExt.Controls.Add($ChkVisio)
$ChkProj = New-Object System.Windows.Forms.CheckBox; $ChkProj.Text = "Project Pro"; $ChkProj.Location = "150, 25"; $ChkProj.AutoSize = $true; $GbExt.Controls.Add($ChkProj)
$ChkVl = New-Object System.Windows.Forms.CheckBox; $ChkVl.Text = "Volume License (VL)"; $ChkVl.Location = "300, 25"; $ChkVl.AutoSize = $true; $ChkVl.Checked = $true; $ChkVl.ForeColor = "Cyan"; $GbExt.Controls.Add($ChkVl)

$CbLang = New-Object System.Windows.Forms.ComboBox; $CbLang.Location = "15, 60"; $CbLang.Width = 150; $CbLang.Items.AddRange(@("en-us", "vi-vn")); $CbLang.SelectedIndex = 0
$GbExt.Controls.Add($CbLang)

# Action Buttons (Install/Download/Uninstall)
$FlowAct = New-Object System.Windows.Forms.FlowLayoutPanel; $FlowAct.Location = "15, 150"; $FlowAct.AutoSize = $true
$Pnl3.Controls.Add($FlowAct)
New-Button $FlowAct "CÀI ĐẶT (INSTALL)" "OrangeRed" 140 40 { Start-Install "Install" } | Out-Null
New-Button $FlowAct "TẢI VỀ (DOWNLOAD)" "Gold" 140 40 { Start-Install "Download" } | Out-Null
New-Button $FlowAct "GỠ BỎ (UNINSTALL)" "Gray" 140 40 { Start-Uninstall } | Out-Null


# --- SECTION 4: ACTIVATION CENTER (Bottom Right - NEW) ---
$Pnl4 = New-Panel $Table "Fill" (New-Object System.Windows.Forms.Padding(10))
$Table.Controls.Add($Pnl4, 1, 1)
New-Label $Pnl4 "4. QUẢN LÝ LICENSE & KÍCH HOẠT" "Header" "Magenta" | Out-Null

$GbLic = New-Object System.Windows.Forms.GroupBox; $GbLic.Text = "Công Cụ Kích Hoạt"; $GbLic.ForeColor = "White"; $GbLic.Location = "15, 40"; $GbLic.Size = "450, 160"
$Pnl4.Controls.Add($GbLic)

# Manual Key
New-Label $GbLic "Nhập Key thủ công:" "Normal" "Silver" | % {$_.Location = "15, 25"}
$TxtKey = New-Object System.Windows.Forms.TextBox; $TxtKey.Location = "15, 45"; $TxtKey.Size = "300, 25"
$GbLic.Controls.Add($TxtKey)
New-Button $GbLic "Nạp Key" $Theme.Accent 100 27 { Install-Key } | % {$_.Location = "325, 43"}

# Clean & MAS
New-Button $GbLic "XÓA LICENSE (CLEAN SKUs)" "Crimson" 200 40 { Clean-Licenses } | % {$_.Location = "15, 90"}
New-Button $GbLic "CHẠY MAS (OHOOK / KMS)" "SeaGreen" 200 40 { Run-MAS } | % {$_.Location = "225, 90"}

# --- BOTTOM LOG ---
$TxtLog = New-Object System.Windows.Forms.TextBox; $TxtLog.Dock = "Bottom"; $TxtLog.Height = 100
$TxtLog.Multiline = $true; $TxtLog.BackColor = "Black"; $TxtLog.ForeColor = "Lime"; $TxtLog.ReadOnly = $true; $TxtLog.ScrollBars = "Vertical"
$Form.Controls.Add($TxtLog)

# ================= LOGIC & FUNCTIONS =================

function Log ($M) { 
    $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $M`r`n") 
    $TxtLog.ScrollToCaret()
}

function Get-Odt {
    $OdtPath = "$env:TEMP\setup.exe"
    if (!(Test-Path $OdtPath)) {
        Log "Đang tải Office Deployment Tool..."
        try { (New-Object System.Net.WebClient).DownloadFile("https://otp.landian.vip/en-us/setup.exe", $OdtPath) } 
        catch { Log "Lỗi tải ODT! Kiểm tra mạng." }
    }
    return $OdtPath
}

# --- LOGIC ACTIVATION ---

function Install-Key {
    $K = $TxtKey.Text.Trim()
    if ($K.Length -lt 5) { Log "Vui lòng nhập Key hợp lệ."; return }
    Log "Đang nạp key: $K..."
    $proc = Start-Process "cscript" -ArgumentList "//nologo $env:SystemRoot\System32\slmgr.vbs /ipk $K" -NoNewWindow -PassThru -Wait
    if ($proc.ExitCode -eq 0) { Log "Nạp Key thành công! Đang thử kích hoạt online..." 
        Start-Process "cscript" -ArgumentList "//nologo $env:SystemRoot\System32\slmgr.vbs /ato" -NoNewWindow -Wait
        Log "Lệnh kích hoạt đã gửi."
    } else { Log "Lỗi nạp Key." }
}

function Clean-Licenses {
    Log "Đang tìm kiếm Skus Office (OSPP.VBS)..."
    $OsppPath = "$env:ProgramFiles\Microsoft Office\Office16\OSPP.VBS"
    if (!(Test-Path $OsppPath)) { $OsppPath = "${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS" }
    
    if (Test-Path $OsppPath) {
        if ([System.Windows.Forms.MessageBox]::Show("Hành động này sẽ xóa toàn bộ Key Office hiện tại.`nBạn có chắc chắn?", "Cảnh báo", "YesNo", "Warning") -eq "Yes") {
            Log "Đang quét key..."
            $Output = & cscript //nologo $OsppPath /dstatus
            $Keys = $Output | Select-String "Last 5 characters of installed product key: (.+)" | % { $_.Matches.Groups[1].Value }
            
            if ($Keys) {
                foreach ($K in $Keys) {
                    Log "Đang gỡ key đuôi: $K"
                    & cscript //nologo $OsppPath /unpkey:$K | Out-Null
                }
                Log "Đã dọn sạch license cũ! Sẵn sàng nạp key mới hoặc Ohook."
                [System.Windows.Forms.MessageBox]::Show("Đã xóa sạch license!", "Thành công")
            } else { Log "Không tìm thấy key nào để xóa." }
        }
    } else { Log "Không tìm thấy file OSPP.VBS. Có thể Office chưa cài đặt?" }
}

function Run-MAS {
    if ([System.Windows.Forms.MessageBox]::Show("Chạy Microsoft Activation Scripts (MAS)?`nĐây là script bên thứ 3 (Massgrave), dùng để kích hoạt Ohook hoặc Online KMS.", "Xác nhận", "YesNo", "Question") -eq "Yes") {
        Log "Đang gọi MAS..."
        # Lệnh chuẩn để gọi MAS
        Start-Process powershell.exe -ArgumentList "irm https://massgrave.dev/get | iex"
        Log "Cửa sổ MAS đã mở. Vui lòng chọn số [1] (Kích hoạt HWID/Ohook) trên cửa sổ đen mới hiện ra."
    }
}

# --- LOGIC ODT INSTALL ---
function Start-Install ($Mode) {
    $VerStr = ($RadioVers | Where {$_.Checked}).Text
    $Arch = if ($R64.Checked) { "64" } else { "32" }
    $Lang = $CbLang.SelectedItem
    $IsVol = $ChkVl.Checked
    
    # Map Product ID
    $ProdID = switch -Regex ($VerStr) {
        "2016" { if($IsVol){"ProPlusVolume"}else{"ProPlusRetail"} }
        "2019" { if($IsVol){"ProPlus2019Volume"}else{"ProPlus2019Retail"} }
        "2021" { if($IsVol){"ProPlus2021Volume"}else{"ProPlus2021Retail"} }
        "2024" { if($IsVol){"ProPlus2024Volume"}else{"ProPlus2024Retail"} }
        "365"  { "O365ProPlusRetail" }
    }
    
    # XML Generation
    $XmlPath = "$env:TEMP\config_office.xml"
    $W = New-Object System.IO.StreamWriter($XmlPath)
    $W.WriteLine('<Configuration>')
    
    $Channel = if($VerStr -match "2019|2021|2024"){"PerpetualVL2019"}else{"Current"}
    if($VerStr -match "2021"){$Channel="PerpetualVL2021"}
    
    $SrcStr = if ($Mode -eq "Download") { 'SourcePath="' + "$env:USERPROFILE\Desktop\Office_Install" + '"' } else { "" }

    $W.WriteLine('  <Add OfficeClientEdition="' + $Arch + '" Channel="' + $Channel + '" ' + $SrcStr + '>')
    $W.WriteLine('    <Product ID="' + $ProdID + '">')
    $W.WriteLine('      <Language ID="' + $Lang + '" />')
    
    foreach ($C in $ChkApps) {
        if (!$C.Checked) {
            $AppID = switch ($C.Text) {
                "Word" {"Word"} "Excel" {"Excel"} "PowerPoint" {"PowerPoint"} "Outlook" {"Outlook"} 
                "OneNote" {"OneNote"} "Access" {"Access"} "Publisher" {"Publisher"} "Teams" {"Teams"} "OneDrive" {"Groove"} "SkypeForBusiness" {"Lync"}
            }
            $W.WriteLine('      <ExcludeApp ID="' + $AppID + '" />')
        }
    }
    $W.WriteLine('    </Product>')
    
    # Extra Products (Visio/Project)
    if ($ChkVisio.Checked) { $Vid=if($IsVol){"VisioPro2021Volume"}else{"VisioProRetail"}; $W.WriteLine('    <Product ID="'+$Vid+'"><Language ID="'+$Lang+'" /></Product>') }
    if ($ChkProj.Checked) { $Pid=if($IsVol){"ProjectPro2021Volume"}else{"ProjectProRetail"}; $W.WriteLine('    <Product ID="'+$Pid+'"><Language ID="'+$Lang+'" /></Product>') }
    
    $W.WriteLine('  </Add>')
    if ($Mode -eq "Install") {
        $W.WriteLine('  <Display Level="Full" AcceptEULA="TRUE" />')
        $W.WriteLine('  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />')
    }
    $W.WriteLine('</Configuration>')
    $W.Close()
    
    # Execute
    $Setup = Get-Odt
    try {
        if ($Mode -eq "Install") {
            Log "Đang cài đặt $ProdID..."
            Start-Process $Setup -ArgumentList "/configure `"$XmlPath`"" 
        } else {
            Log "Đang tải về..."
            Start-Process $Setup -ArgumentList "/download `"$XmlPath`""
        }
    } catch { Log "Lỗi thực thi: $_" }
}

function Start-Uninstall {
    if ([System.Windows.Forms.MessageBox]::Show("Gỡ bỏ toàn bộ Office?", "Warning", "YesNo") -eq "Yes") {
        $X = "$env:TEMP\rem.xml"; [IO.File]::WriteAllText($X, '<Configuration><Remove All="TRUE"/></Configuration>')
        Start-Process (Get-Odt) -ArgumentList "/configure `"$X`""
        Log "Đã gửi lệnh gỡ bỏ."
    }
}

$Form.ShowDialog() | Out-Null
