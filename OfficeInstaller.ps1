# --- 1. FORCE ADMIN & PRE-SETUP ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- 2. DATA: PRODUCT MAPPING (Menu Đa Cấp) ---
# Cấu trúc: Tên hiển thị = ID trong XML
$ProdMap = @{
    "Microsoft 365" = @{
        "Professional Plus (Doanh nghiệp lớn)" = "O365ProPlusRetail"
        "Business Standard (Doanh nghiệp vừa)" = "O365BusinessRetail"
        "Home / Personal (Cá nhân/Gia đình)"   = "O365HomePremRetail"
    }
    "Office 2021" = @{
        "Pro Plus 2021 (Volume - Khuyên dùng)" = "ProPlus2021Volume"
        "Pro Plus 2021 (Retail)"               = "ProPlus2021Retail"
        "Standard 2021 (Volume)"               = "Standard2021Volume"
    }
    "Office 2019" = @{
        "Pro Plus 2019 (Volume)" = "ProPlus2019Volume"
        "Standard 2019 (Volume)" = "Standard2019Volume"
    }
    "Office 2016" = @{
        "Pro Plus 2016 (Volume)" = "ProPlusVolume"
        "Standard 2016 (Volume)" = "StandardVolume"
    }
}

# --- 3. THEME NEON ---
$Theme = @{
    Back    = [System.Drawing.Color]::FromArgb(20, 20, 20)      # Đen sâu hơn
    Panel   = [System.Drawing.Color]::FromArgb(35, 35, 35)
    Text    = [System.Drawing.Color]::FromArgb(240, 240, 240)
    Accent  = [System.Drawing.Color]::FromArgb(0, 255, 255)     # Cyan Neon
    Warning = [System.Drawing.Color]::FromArgb(255, 69, 0)      # Cam đỏ
    Success = [System.Drawing.Color]::FromArgb(50, 205, 50)     # Lime Green
}

# --- 4. UI HELPER (NO HARD COORDINATES) ---
function New-StyledButton ($Parent, $Txt, $Color, $Event) {
    $B = New-Object System.Windows.Forms.Button
    $B.Text = $Txt; $B.BackColor = $Color; $B.ForeColor = "Black"
    $B.FlatStyle = "Flat"; $B.FlatAppearance.BorderSize = 0
    $B.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $B.Height = 35; $B.Width = 140; $B.Cursor = "Hand"
    $B.Margin = New-Object System.Windows.Forms.Padding(5)
    $B.Add_Click($Event)
    $Parent.Controls.Add($B)
    return $B
}

function New-StyledCombo ($Parent) {
    $C = New-Object System.Windows.Forms.ComboBox
    $C.DropDownStyle = "DropDownList"
    $C.FlatStyle = "Flat"; $C.BackColor = $Theme.Panel; $C.ForeColor = "White"
    $C.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $C.Width = 250; $C.Margin = New-Object System.Windows.Forms.Padding(5)
    $Parent.Controls.Add($C)
    return $C
}

# --- 5. MAIN FORM ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "OFFICE MASTER V5.0 - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(900, 650)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back; $Form.ForeColor = $Theme.Text

# MAIN LAYOUT: TableLayoutPanel (2 Cột, 2 Hàng)
$Table = New-Object System.Windows.Forms.TableLayoutPanel
$Table.Dock = "Fill"; $Table.ColumnCount = 2; $Table.RowCount = 2
$Table.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 50)))
$Table.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 50)))
$Table.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 60)))
$Table.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 40)))
$Table.Padding = New-Object System.Windows.Forms.Padding(10)
$Form.Controls.Add($Table)

# --- PANEL 1: CẤU HÌNH (Top Left) ---
$Pnl1 = New-Object System.Windows.Forms.FlowLayoutPanel
$Pnl1.Dock = "Fill"; $Pnl1.FlowDirection = "TopDown"; $Pnl1.AutoScroll = $true
$Table.Controls.Add($Pnl1, 0, 0)

# Label Header
$Lbl1 = New-Object System.Windows.Forms.Label; $Lbl1.Text = "1. CHỌN PHIÊN BẢN"; $Lbl1.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold); $Lbl1.ForeColor = $Theme.Accent; $Lbl1.AutoSize = $true
$Pnl1.Controls.Add($Lbl1)

# Combo Main Version
$LblVer = New-Object System.Windows.Forms.Label; $LblVer.Text = "Chọn Loại Office:"; $LblVer.AutoSize = $true; $Pnl1.Controls.Add($LblVer)
$CbMainVer = New-StyledCombo $Pnl1
foreach ($k in $ProdMap.Keys) { $CbMainVer.Items.Add($k) | Out-Null }
$CbMainVer.SelectedIndex = 0

# Combo Sub Version
$LblSub = New-Object System.Windows.Forms.Label; $LblSub.Text = "Chọn Bản Con (Edition):"; $LblSub.AutoSize = $true; $Pnl1.Controls.Add($LblSub)
$CbSubVer = New-StyledCombo $Pnl1

# Event: Khi chọn Main -> Update Sub
$CbMainVer.Add_SelectedIndexChanged({
    $CbSubVer.Items.Clear()
    $SelectedMain = $CbMainVer.SelectedItem
    foreach ($sub in $ProdMap[$SelectedMain].Keys) { $CbSubVer.Items.Add($sub) | Out-Null }
    if ($CbSubVer.Items.Count -gt 0) { $CbSubVer.SelectedIndex = 0 }
})
# Trigger lần đầu
$CbMainVer.SelectedIndex = 1 # Default 2021

# Combo Language
$LblLang = New-Object System.Windows.Forms.Label; $LblLang.Text = "Ngôn ngữ:"; $LblLang.AutoSize = $true; $Pnl1.Controls.Add($LblLang)
$CbLang = New-StyledCombo $Pnl1
$CbLang.Items.AddRange(@("vi-vn", "en-us"))
$CbLang.SelectedIndex = 0

# Bit Architecture
$PnlBit = New-Object System.Windows.Forms.FlowLayoutPanel; $PnlBit.AutoSize = $true
$R64 = New-Object System.Windows.Forms.RadioButton; $R64.Text = "64-bit (Chuẩn)"; $R64.Checked = $true; $R64.AutoSize = $true
$R86 = New-Object System.Windows.Forms.RadioButton; $R86.Text = "32-bit (Máy cổ)"; $R86.AutoSize = $true
$PnlBit.Controls.AddRange(@($R64, $R86))
$Pnl1.Controls.Add($PnlBit)

# --- PANEL 2: ỨNG DỤNG (Top Right) ---
$Pnl2 = New-Object System.Windows.Forms.FlowLayoutPanel
$Pnl2.Dock = "Fill"; $Pnl2.FlowDirection = "TopDown"; $Pnl2.BorderStyle = "FixedSingle"
$Table.Controls.Add($Pnl2, 1, 0)

$Lbl2 = New-Object System.Windows.Forms.Label; $Lbl2.Text = "2. TÙY CHỌN APP"; $Lbl2.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold); $Lbl2.ForeColor = $Theme.Warning; $Lbl2.AutoSize = $true
$Pnl2.Controls.Add($Lbl2)

$Apps = @("Word", "Excel", "PowerPoint", "Outlook", "OneNote", "Access", "Publisher", "Teams", "OneDrive")
$ChkApps = @()
foreach ($A in $Apps) {
    $C = New-Object System.Windows.Forms.CheckBox; $C.Text = $A; $C.AutoSize = $true; $C.ForeColor = "White"
    if ($A -match "Word|Excel|PowerPoint") { $C.Checked = $true }
    $Pnl2.Controls.Add($C); $ChkApps += $C
}
# Visio & Project riêng
$PnlVP = New-Object System.Windows.Forms.FlowLayoutPanel; $PnlVP.AutoSize = $true
$ChkVisio = New-Object System.Windows.Forms.CheckBox; $ChkVisio.Text = "+ Visio Pro"; $ChkVisio.AutoSize = $true; $PnlVP.Controls.Add($ChkVisio)
$ChkProj = New-Object System.Windows.Forms.CheckBox; $ChkProj.Text = "+ Project Pro"; $ChkProj.AutoSize = $true; $PnlVP.Controls.Add($ChkProj)
$Pnl2.Controls.Add($PnlVP)

# --- PANEL 3: ACTIONS (Bottom Left) ---
$Pnl3 = New-Object System.Windows.Forms.FlowLayoutPanel
$Pnl3.Dock = "Fill"; $Pnl3.Padding = New-Object System.Windows.Forms.Padding(10)
$Table.Controls.Add($Pnl3, 0, 1)

New-StyledButton $Pnl3 "CÀI ĐẶT NGAY" "OrangeRed" { Start-Process-ODT "Install" } | Out-Null
New-StyledButton $Pnl3 "TẢI BỘ CÀI (ISO)" "Gold" { Start-Process-ODT "Download" } | Out-Null
New-StyledButton $Pnl3 "GỠ BỎ OFFICE" "Gray" { Start-Uninstall } | Out-Null

# --- PANEL 4: LOG & STATUS (Bottom Right) ---
$TxtLog = New-Object System.Windows.Forms.TextBox
$TxtLog.Dock = "Fill"; $TxtLog.Multiline = $true; $TxtLog.BackColor = "Black"; $TxtLog.ForeColor = "Lime"
$TxtLog.ReadOnly = $true; $TxtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
$Table.Controls.Add($TxtLog, 1, 1)

# ================= LOGIC FUNCTION =================

function Log ($M) { 
    $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $M`r`n")
    $TxtLog.ScrollToCaret()
}

function Get-SetupExe {
    $WorkDir = "$env:TEMP\OfficeSetup"
    if (!(Test-Path $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir | Out-Null }
    $SetupPath = "$WorkDir\setup.exe"

    if (!(Test-Path $SetupPath)) {
        Log "Đang tải ODT chính chủ từ Microsoft..."
        $OdtUrl = "https://go.microsoft.com/fwlink/?LinkID=626065" # Link gốc ODT
        $OdtExe = "$WorkDir\odt.exe"
        
        try {
            # Tải file ODT gốc (là file tự giải nén)
            (New-Object System.Net.WebClient).DownloadFile($OdtUrl, $OdtExe)
            Log "Tải xong. Đang giải nén lấy setup.exe..."
            
            # Chạy lệnh giải nén silent
            $Proc = Start-Process -FilePath $OdtExe -ArgumentList "/quiet /extract:`"$WorkDir`"" -Wait -PassThru
            
            if (Test-Path $SetupPath) {
                Log "Đã có file Setup.exe chuẩn!"
            } else {
                Log "Lỗi giải nén ODT. Vui lòng kiểm tra lại."
            }
        } catch {
            Log "Lỗi tải mạng: $_"
        }
    }
    return $SetupPath
}

function Start-Process-ODT ($Mode) {
    # 1. Lấy thông tin từ UI
    $MainVer = $CbMainVer.SelectedItem
    $SubVerName = $CbSubVer.SelectedItem
    # Map tên hiển thị sang ProductID thực tế
    $ProductID = $ProdMap[$MainVer][$SubVerName]
    
    $LangID = $CbLang.SelectedItem # Lấy trực tiếp vi-vn hoặc en-us
    $Bit = if ($R64.Checked) { "64" } else { "32" }
    
    Log "Cấu hình: $ProductID ($Bit) - Ngôn ngữ: $LangID"

    # 2. Tạo XML Config
    $XmlPath = "$env:TEMP\config.xml"
    $W = New-Object System.IO.StreamWriter($XmlPath)
    $W.WriteLine('<Configuration>')
    
    # Kênh cập nhật (Channel)
    $Channel = "Current"
    if ($ProductID -match "2019|2021|Volume") { $Channel = "PerpetualVL2021" } # Channel ổn định cho bản VL
    
    # SourcePath: Nếu mode Install thì để trống (tải online), Mode Download thì lưu ra Desktop
    $SrcAttr = ""
    if ($Mode -eq "Download") { 
        $SaveDir = "$env:USERPROFILE\Desktop\Office_$ProductID"
        New-Item -ItemType Directory -Force -Path $SaveDir | Out-Null
        $SrcAttr = 'SourcePath="' + $SaveDir + '"'
    }

    $W.WriteLine("  <Add OfficeClientEdition=""$Bit"" Channel=""$Channel"" $SrcAttr>")
    $W.WriteLine("    <Product ID=""$ProductID"">")
    $W.WriteLine("      <Language ID=""$LangID"" />")
    
    # Exclude Apps
    foreach ($C in $ChkApps) {
        if (!$C.Checked) {
            $ExID = switch ($C.Text) {
                "Word" {"Word"} "Excel" {"Excel"} "PowerPoint" {"PowerPoint"} "Outlook" {"Outlook"} 
                "OneNote" {"OneNote"} "Access" {"Access"} "Publisher" {"Publisher"} "Teams" {"Teams"} "OneDrive" {"Groove"}
            }
            if ($ExID) { $W.WriteLine("      <ExcludeApp ID=""$ExID"" />") }
        }
    }
    $W.WriteLine("    </Product>")
    
    # Visio / Project (Tự động map theo bản Volume hay Retail của bộ chính)
    $IsVol = $ProductID -match "Volume"
    if ($ChkVisio.Checked) {
        $VId = if ($IsVol) { "VisioPro2021Volume" } else { "VisioProRetail" }
        $W.WriteLine("    <Product ID=""$VId""><Language ID=""$LangID"" /></Product>")
    }
    if ($ChkProj.Checked) {
        $PId = if ($IsVol) { "ProjectPro2021Volume" } else { "ProjectProRetail" }
        $W.WriteLine("    <Product ID=""$PId""><Language ID=""$LangID"" /></Product>")
    }

    $W.WriteLine("  </Add>")
    
    if ($Mode -eq "Install") {
        $W.WriteLine('  <Display Level="Full" AcceptEULA="TRUE" />')
        $W.WriteLine('  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />')
    }
    $W.WriteLine('</Configuration>')
    $W.Close()

    # 3. Thực thi
    $SetupExe = Get-SetupExe
    if (Test-Path $SetupExe) {
        if ($Mode -eq "Install") {
            Log "Đang cài đặt... Cửa sổ Office sẽ hiện lên ngay."
            Start-Process $SetupExe -ArgumentList "/configure `"$XmlPath`""
        } else {
            Log "Đang tải về Desktop... Treo máy chờ nhé."
            Start-Process $SetupExe -ArgumentList "/download `"$XmlPath`""
        }
    } else {
        Log "Không tìm thấy file Setup.exe. Kiểm tra lại mạng để tải tool."
    }
}

function Start-Uninstall {
    if ([System.Windows.Forms.MessageBox]::Show("Xác nhận gỡ Office?", "Confirm", "YesNo") -eq "Yes") {
        $X = "$env:TEMP\rem.xml"; [IO.File]::WriteAllText($X, '<Configuration><Remove All="TRUE"/></Configuration>')
        $S = Get-SetupExe
        if(Test-Path $S) { Start-Process $S -ArgumentList "/configure `"$X`"" }
    }
}

$Form.ShowDialog() | Out-Null
