<#
    OFFICE MASTER - PHAT TAN PC
    Version: 5.3 (Multi-Language Support)
    Update: 
    - Languages are now loaded dynamically from JSON.
    - Added Backup Languages if offline.
#>

# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- 2. CONFIG & DATA LOADER ---
$JsonUrl = "https://raw.githubusercontent.com/Hello2k2/Kho-Do-Nghe/main/office_data.json"
$Global:ProdMap = @{}
$Global:LangMap = @{} # [NEW] Map tên ngôn ngữ sang mã
$Global:Extras = @{ "VisioRetail"="VisioProRetail"; "ProjectRetail"="ProjectProRetail" }

function Load-Config {
    try {
        $Req = [System.Net.WebRequest]::Create($JsonUrl)
        $Req.Timeout = 5000; $Resp = $Req.GetResponse()
        $Stream = New-Object System.IO.StreamReader($Resp.GetResponseStream())
        $JsonContent = $Stream.ReadToEnd(); $Stream.Close(); $Resp.Close()
        
        $Data = $JsonContent | ConvertFrom-Json
        
        # Parse Products
        $Data.Categories.PSObject.Properties | ForEach-Object {
            $CatName = $_.Name; $Items = $_.Value; $SubMap = @{}
            $Items.PSObject.Properties | ForEach-Object { $SubMap[$_.Name] = $_.Value }
            $Global:ProdMap[$CatName] = $SubMap
        }
        
        # Parse Extras
        if ($Data.Extras) {
            $Global:Extras["VisioRetail"] = $Data.Extras.VisioRetail
            $Global:Extras["ProjectRetail"] = $Data.Extras.ProjectRetail
        }

        # [NEW] Parse Languages
        if ($Data.Languages) {
            $Data.Languages.PSObject.Properties | ForEach-Object {
                $Global:LangMap[$_.Name] = $_.Value
            }
        } else { throw "No Langs" }

        return $true
    } catch {
        # [BACKUP DATA]
        $Global:ProdMap = @{
            "Microsoft 365 (Offline Mode)" = @{ "Pro Plus"="O365ProPlusRetail"; "Home"="O365HomePremRetail" }
            "Office 2021 (Offline Mode)" = @{ "Pro Plus Volume"="ProPlus2021Volume" }
        }
        $Global:LangMap = @{ "Tiếng Việt"="vi-vn"; "English (US)"="en-us" }
        return $false
    }
}

# --- 3. THEME NEON ---
$Theme = @{
    Back    = [System.Drawing.Color]::FromArgb(20, 20, 20)
    Panel   = [System.Drawing.Color]::FromArgb(35, 35, 35)
    Text    = [System.Drawing.Color]::FromArgb(240, 240, 240)
    Accent  = [System.Drawing.Color]::FromArgb(0, 255, 255)
    Warning = [System.Drawing.Color]::FromArgb(255, 69, 0)
}

# --- 4. UI CONSTRUCTION ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "OFFICE MASTER V5.3 (MULTI-LANG) - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(950, 680)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back; $Form.ForeColor = $Theme.Text

$IsOnline = Load-Config
$TitleStatus = if ($IsOnline) { "ONLINE" } else { "OFFLINE" }

$Table = New-Object System.Windows.Forms.TableLayoutPanel; $Table.Dock = "Fill"; $Table.ColumnCount = 2; $Table.RowCount = 2
$Table.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 50)))
$Table.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 50)))
$Table.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 65)))
$Table.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 35)))
$Table.Padding = New-Object System.Windows.Forms.Padding(10)
$Form.Controls.Add($Table)

function New-StyledButton ($Parent, $Txt, $Color, $Event) {
    $B = New-Object System.Windows.Forms.Button
    $B.Text = $Txt; $B.BackColor = $Color; $B.ForeColor = "Black"
    $B.FlatStyle = "Flat"; $B.FlatAppearance.BorderSize = 0
    $B.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $B.Height = 35; $B.Width = 140; $B.Cursor = "Hand"; $B.Margin = New-Object System.Windows.Forms.Padding(5)
    $B.Add_Click($Event); $Parent.Controls.Add($B); return $B
}
function New-StyledCombo ($Parent) {
    $C = New-Object System.Windows.Forms.ComboBox; $C.DropDownStyle = "DropDownList"
    $C.FlatStyle = "Flat"; $C.BackColor = $Theme.Panel; $C.ForeColor = "White"
    $C.Font = New-Object System.Drawing.Font("Segoe UI", 10); $C.Width = 280; $C.Margin = New-Object System.Windows.Forms.Padding(5)
    $Parent.Controls.Add($C); return $C
}

# --- PANEL 1 ---
$Pnl1 = New-Object System.Windows.Forms.FlowLayoutPanel; $Pnl1.Dock = "Fill"; $Pnl1.FlowDirection = "TopDown"; $Table.Controls.Add($Pnl1, 0, 0)
$Lbl1 = New-Object System.Windows.Forms.Label; $Lbl1.Text = "1. CHỌN PHIÊN BẢN ($TitleStatus)"; $Lbl1.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold); $Lbl1.ForeColor = $Theme.Accent; $Lbl1.AutoSize = $true; $Pnl1.Controls.Add($Lbl1)

$Pnl1.Controls.Add((New-Object System.Windows.Forms.Label -Prop @{Text="Nhóm Office:"; AutoSize=$true}))
$CbMainVer = New-StyledCombo $Pnl1
foreach ($k in $Global:ProdMap.Keys) { $CbMainVer.Items.Add($k) | Out-Null }

$Pnl1.Controls.Add((New-Object System.Windows.Forms.Label -Prop @{Text="Chi tiết (Edition):"; AutoSize=$true}))
$CbSubVer = New-StyledCombo $Pnl1

$CbMainVer.Add_SelectedIndexChanged({
    $CbSubVer.Items.Clear()
    $Sel = $CbMainVer.SelectedItem
    if ($Sel) { foreach ($sub in $Global:ProdMap[$Sel].Keys) { $CbSubVer.Items.Add($sub) | Out-Null } }
    if ($CbSubVer.Items.Count -gt 0) { $CbSubVer.SelectedIndex = 0 }
})
if ($CbMainVer.Items.Count -gt 0) { $CbMainVer.SelectedIndex = 0 }

# [UPDATED UI] NGÔN NGỮ TỪ JSON
$Pnl1.Controls.Add((New-Object System.Windows.Forms.Label -Prop @{Text="Ngôn ngữ:"; AutoSize=$true}))
$CbLang = New-StyledCombo $Pnl1
foreach ($L in $Global:LangMap.Keys) { $CbLang.Items.Add($L) | Out-Null }
if ($CbLang.Items.Count -gt 0) { $CbLang.SelectedIndex = 0 }

$Pnl1.Controls.Add((New-Object System.Windows.Forms.Label -Prop @{Text="Kiến trúc:"; AutoSize=$true}))
$PnlBit = New-Object System.Windows.Forms.FlowLayoutPanel; $PnlBit.AutoSize = $true
$R64 = New-Object System.Windows.Forms.RadioButton; $R64.Text = "64-bit"; $R64.Checked = $true; $R64.AutoSize = $true
$R86 = New-Object System.Windows.Forms.RadioButton; $R86.Text = "32-bit"; $R86.AutoSize = $true
$PnlBit.Controls.AddRange(@($R64, $R86)); $Pnl1.Controls.Add($PnlBit)

# --- PANEL 2 ---
$Pnl2 = New-Object System.Windows.Forms.FlowLayoutPanel; $Pnl2.Dock = "Fill"; $Pnl2.FlowDirection = "TopDown"; $Pnl2.BorderStyle = "FixedSingle"; $Table.Controls.Add($Pnl2, 1, 0)
$Lbl2 = New-Object System.Windows.Forms.Label; $Lbl2.Text = "2. TÙY CHỌN APP"; $Lbl2.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold); $Lbl2.ForeColor = $Theme.Warning; $Lbl2.AutoSize = $true; $Pnl2.Controls.Add($Lbl2)

$Apps = @("Word", "Excel", "PowerPoint", "Outlook", "OneNote", "Access", "Publisher", "Teams", "OneDrive")
$ChkApps = @()
foreach ($A in $Apps) {
    $C = New-Object System.Windows.Forms.CheckBox; $C.Text = $A; $C.AutoSize = $true; $C.ForeColor = "White"
    if ($A -match "Word|Excel|PowerPoint") { $C.Checked = $true }
    $Pnl2.Controls.Add($C); $ChkApps += $C
}
$PnlVP = New-Object System.Windows.Forms.FlowLayoutPanel; $PnlVP.AutoSize = $true
$ChkVisio = New-Object System.Windows.Forms.CheckBox; $ChkVisio.Text = "+ Visio"; $ChkVisio.AutoSize = $true; $PnlVP.Controls.Add($ChkVisio)
$ChkProj = New-Object System.Windows.Forms.CheckBox; $ChkProj.Text = "+ Project"; $ChkProj.AutoSize = $true; $PnlVP.Controls.Add($ChkProj)
$Pnl2.Controls.Add($PnlVP)

# --- PANEL 3 & 4 ---
$Pnl3 = New-Object System.Windows.Forms.FlowLayoutPanel; $Pnl3.Dock="Fill"; $Pnl3.Padding="10,10,10,10"; $Table.Controls.Add($Pnl3, 0, 1)
New-StyledButton $Pnl3 "CÀI ĐẶT" "OrangeRed" { Run-ODT "Install" }
New-StyledButton $Pnl3 "TẢI ISO" "Gold" { Run-ODT "Download" }
New-StyledButton $Pnl3 "GỠ OFFICE" "Gray" { Start-Uninstall }

$TxtLog = New-Object System.Windows.Forms.TextBox; $TxtLog.Dock="Fill"; $TxtLog.Multiline=$true; $TxtLog.BackColor="Black"; $TxtLog.ForeColor="Lime"; $TxtLog.ReadOnly=$true; $Table.Controls.Add($TxtLog, 1, 1)

function Log ($M) { $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm'))] $M`r`n"); $TxtLog.ScrollToCaret() }

function Get-SetupExe {
    $WorkDir = "$env:TEMP\OfficeSetup"; if (!(Test-Path $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir | Out-Null }
    $SetupPath = "$WorkDir\setup.exe"
    if (!(Test-Path $SetupPath)) {
        Log "Tải ODT từ Microsoft..."
        try { (New-Object System.Net.WebClient).DownloadFile("https://go.microsoft.com/fwlink/?LinkID=626065", "$WorkDir\odt.exe")
            Start-Process "$WorkDir\odt.exe" "/quiet /extract:`"$WorkDir`"" -Wait
        } catch { Log "Lỗi mạng!" }
    }
    return $SetupPath
}

function Run-ODT ($Mode) {
    $Main=$CbMainVer.SelectedItem; $Sub=$CbSubVer.SelectedItem
    $ID = $Global:ProdMap[$Main][$Sub]
    
    # [UPDATED LOGIC] Lấy Mã Ngôn Ngữ từ Map
    $SelLangName = $CbLang.SelectedItem
    $LangID = $Global:LangMap[$SelLangName]
    $Bit=if($R64.Checked){"64"}else{"32"}

    if (!$ID) { Log "Chưa chọn phiên bản!"; return }
    Log "Cấu hình: $ID ($Bit) - $LangID"

    $Xml = "$env:TEMP\config.xml"; $W = New-Object System.IO.StreamWriter($Xml); $W.WriteLine('<Configuration>')
    
    $Ch = "Current"; if ($ID -match "Volume") { $Ch = "PerpetualVL2021" }
    $Src = ""; if ($Mode -eq "Download") { $D="$env:USERPROFILE\Desktop\Office_$ID"; md $D -Force | Out-Null; $Src="SourcePath=`"$D`"" }
    
    $W.WriteLine(" <Add OfficeClientEdition=`"$Bit`" Channel=`"$Ch`" $Src><Product ID=`"$ID`"><Language ID=`"$LangID`"/>")
    foreach ($C in $ChkApps) { if (!$C.Checked) { 
        $ExID = switch($C.Text){"Word"{"Word"}"Excel"{"Excel"}"PowerPoint"{"PowerPoint"}"Outlook"{"Outlook"}"OneNote"{"OneNote"}"Access"{"Access"}"Publisher"{"Publisher"}"Teams"{"Teams"}"OneDrive"{"Groove"}}
        if($ExID){$W.WriteLine("  <ExcludeApp ID=`"$ExID`"/>")} 
    }}
    $W.WriteLine(" </Product>")

    $IsVol = $ID -match "Volume"
    if($ChkVisio.Checked){ $V=if($IsVol){"VisioPro2021Volume"}else{$Global:Extras["VisioRetail"]}; $W.WriteLine(" <Product ID=`"$V`"><Language ID=`"$LangID`"/></Product>") }
    if($ChkProj.Checked){ $P=if($IsVol){"ProjectPro2021Volume"}else{$Global:Extras["ProjectRetail"]}; $W.WriteLine(" <Product ID=`"$P`"><Language ID=`"$LangID`"/></Product>") }
    
    $W.WriteLine(" </Add>"); if($Mode -eq "Install"){$W.WriteLine('<Display Level="Full" AcceptEULA="TRUE"/><Property Name="FORCEAPPSHUTDOWN" Value="TRUE"/>')}
    if($ID -eq "O365ProPlusRetail"){$W.WriteLine('<Property Name="SharedComputerLicensing" Value="0"/>')}
    $W.WriteLine('</Configuration>'); $W.Close()

    $Exe = Get-SetupExe
    if(Test-Path $Exe){ 
        if($Mode -eq "Install"){Start-Process $Exe "/configure `"$Xml`""}else{Start-Process $Exe "/download `"$Xml`""}
    }
}

function Start-Uninstall {
    if([System.Windows.Forms.MessageBox]::Show("Gỡ Office?", "Xác nhận", "YesNo") -eq "Yes"){
        $X="$env:TEMP\rm.xml"; [IO.File]::WriteAllText($X, '<Configuration><Remove All="TRUE"/></Configuration>')
        $S=Get-SetupExe; if(Test-Path $S){Start-Process $S "/configure `"$X`""}
    }
}

$Form.ShowDialog() | Out-Null
