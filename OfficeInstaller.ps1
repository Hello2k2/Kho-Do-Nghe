# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- THEME NEON ---
$Theme = @{
    Back      = [System.Drawing.Color]::FromArgb(30, 30, 30)
    Card      = [System.Drawing.Color]::FromArgb(40, 40, 45)
    Text      = [System.Drawing.Color]::FromArgb(240, 240, 240)
    BtnBack   = [System.Drawing.Color]::FromArgb(60, 60, 60)
    BtnHover  = [System.Drawing.Color]::FromArgb(255, 140, 0)
    Accent    = [System.Drawing.Color]::FromArgb(255, 69, 0)
    Border    = [System.Drawing.Color]::FromArgb(255, 69, 0)
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "MICROSOFT OFFICE INSTALLER - ODT GUI"
$Form.Size = New-Object System.Drawing.Size(1000, 700)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back; $Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"; $Form.MaximizeBox = $false

$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "OFFICE DEPLOYMENT TOOL (ODT)"; $LblT.Font = "Impact, 22"; $LblT.ForeColor = $Theme.Accent; $LblT.AutoSize = $true; $LblT.Location = "20,15"; $Form.Controls.Add($LblT)

# --- PAINT HANDLER ---
$PaintHandler = {
    param($sender, $e)
    $Pen = New-Object System.Drawing.Pen($Theme.Border, 2)
    $Rect = $sender.ClientRectangle; $Rect.Width-=2; $Rect.Height-=2; $Rect.X+=1; $Rect.Y+=1
    $e.Graphics.DrawRectangle($Pen, $Rect); $Pen.Dispose()
}

# --- CONFIG DATA ---
$OfficeVers = @("Office 2016", "Office 2019", "Office 2021", "Office 2024", "Microsoft 365")
$Archs = @("x64 (64-bit)", "x86 (32-bit)")
$Langs = @("en-us", "vi-vn", "ko-kr", "ja-jp", "zh-cn", "fr-fr", "ru-ru", "de-de", "es-es")
$AppsList = @("Word", "Excel", "PowerPoint", "Outlook", "OneNote", "Access", "Publisher", "Teams", "OneDrive", "SkypeForBusiness")

# ================= UI SECTIONS =================

# 1. VERSION
$PnlVer = New-Object System.Windows.Forms.Panel; $PnlVer.Location="20,80"; $PnlVer.Size="300,320"; $PnlVer.BackColor=$Theme.Card; $PnlVer.Add_Paint($PaintHandler); $Form.Controls.Add($PnlVer)
$L1 = New-Object System.Windows.Forms.Label; $L1.Text="1. PHIEN BAN & KIEN TRUC"; $L1.Location="10,10"; $L1.AutoSize=$true; $L1.Font="Segoe UI, 10, Bold"; $PnlVer.Controls.Add($L1)

$GbVer = New-Object System.Windows.Forms.GroupBox; $GbVer.Text="Chon Phien Ban"; $GbVer.Location="15,40"; $GbVer.Size="270,180"; $GbVer.ForeColor="White"; $PnlVer.Controls.Add($GbVer)
$RadioVers = @()
$Y = 25
foreach ($V in $OfficeVers) {
    $R = New-Object System.Windows.Forms.RadioButton; $R.Text=$V; $R.Location="20,$Y"; $R.AutoSize=$true; $R.Font="Segoe UI, 10"
    if ($V -eq "Office 2021") { $R.Checked=$true }
    $GbVer.Controls.Add($R); $RadioVers += $R; $Y += 30
}

$GbArch = New-Object System.Windows.Forms.GroupBox; $GbArch.Text="Kien Truc (Bit)"; $GbArch.Location="15,230"; $GbArch.Size="270,70"; $GbArch.ForeColor="White"; $PnlVer.Controls.Add($GbArch)
$RadioArchs = @()
$R64 = New-Object System.Windows.Forms.RadioButton; $R64.Text="x64 (Chuan)"; $R64.Location="20,30"; $R64.AutoSize=$true; $R64.Checked=$true; $GbArch.Controls.Add($R64)
$R86 = New-Object System.Windows.Forms.RadioButton; $R86.Text="x86 (May yeu)"; $R86.Location="140,30"; $R86.AutoSize=$true; $GbArch.Controls.Add($R86)

# 2. APPS
$PnlApp = New-Object System.Windows.Forms.Panel; $PnlApp.Location="340,80"; $PnlApp.Size="300,320"; $PnlApp.BackColor=$Theme.Card; $PnlApp.Add_Paint($PaintHandler); $Form.Controls.Add($PnlApp)
$L2 = New-Object System.Windows.Forms.Label; $L2.Text="2. UNG DUNG CAN CAI"; $L2.Location="10,10"; $L2.AutoSize=$true; $L2.Font="Segoe UI, 10, Bold"; $PnlApp.Controls.Add($L2)

$FlowApp = New-Object System.Windows.Forms.FlowLayoutPanel; $FlowApp.Location="15,40"; $FlowApp.Size="270,260"; $FlowApp.FlowDirection="TopDown"; $PnlApp.Controls.Add($FlowApp)
$ChkApps = @()
foreach ($A in $AppsList) {
    $C = New-Object System.Windows.Forms.CheckBox; $C.Text=$A; $C.AutoSize=$true; $C.Font="Segoe UI, 10"; $C.Margin="3,3,20,5"
    if ($A -match "Word|Excel|PowerPoint") { $C.Checked=$true }
    $FlowApp.Controls.Add($C); $ChkApps += $C
}

$BtnSelAll = New-Object System.Windows.Forms.Button; $BtnSelAll.Text="All"; $BtnSelAll.Location="220,5"; $BtnSelAll.Size="35,25"; $BtnSelAll.FlatStyle="Flat"; $PnlApp.Controls.Add($BtnSelAll)
$BtnSelAll.Add_Click({ foreach($c in $ChkApps){$c.Checked=$true} })
$BtnSelNone = New-Object System.Windows.Forms.Button; $BtnSelNone.Text="X"; $BtnSelNone.Location="260,5"; $BtnSelNone.Size="25,25"; $BtnSelNone.FlatStyle="Flat"; $PnlApp.Controls.Add($BtnSelNone)
$BtnSelNone.Add_Click({ foreach($c in $ChkApps){$c.Checked=$false} })

# 3. EXTRA
$PnlExt = New-Object System.Windows.Forms.Panel; $PnlExt.Location="660,80"; $PnlExt.Size="300,320"; $PnlExt.BackColor=$Theme.Card; $PnlExt.Add_Paint($PaintHandler); $Form.Controls.Add($PnlExt)
$L3 = New-Object System.Windows.Forms.Label; $L3.Text="3. CAU HINH BO SUNG"; $L3.Location="10,10"; $L3.AutoSize=$true; $L3.Font="Segoe UI, 10, Bold"; $PnlExt.Controls.Add($L3)

$GbPro = New-Object System.Windows.Forms.GroupBox; $GbPro.Text="San Pham Rieng Le"; $GbPro.Location="15,40"; $GbPro.Size="270,80"; $GbPro.ForeColor="Gold"; $PnlExt.Controls.Add($GbPro)
$ChkVisio = New-Object System.Windows.Forms.CheckBox; $ChkVisio.Text="Visio Pro"; $ChkVisio.Location="20,25"; $ChkVisio.AutoSize=$true; $GbPro.Controls.Add($ChkVisio)
$ChkProj = New-Object System.Windows.Forms.CheckBox; $ChkProj.Text="Project Pro"; $ChkProj.Location="140,25"; $ChkProj.AutoSize=$true; $GbPro.Controls.Add($ChkProj)
$ChkVl = New-Object System.Windows.Forms.CheckBox; $ChkVl.Text="Dung Ban Volume License (VL)"; $ChkVl.Location="20,50"; $ChkVl.AutoSize=$true; $ChkVl.ForeColor="Cyan"; $ChkVl.Checked=$true; $GbPro.Controls.Add($ChkVl)

$LblLang = New-Object System.Windows.Forms.Label; $LblLang.Text="Ngon Ngu:"; $LblLang.Location="15,140"; $LblLang.AutoSize=$true; $PnlExt.Controls.Add($LblLang)
$CbLang = New-Object System.Windows.Forms.ComboBox; $CbLang.Location="100,135"; $CbLang.Size="180,25"; $CbLang.DropDownStyle="DropDownList"
foreach ($L in $Langs) { $CbLang.Items.Add($L) | Out-Null }; $CbLang.SelectedIndex=0; $PnlExt.Controls.Add($CbLang)

$LblPath = New-Object System.Windows.Forms.Label; $LblPath.Text="Noi cai dat (Bo trong = Mac dinh):"; $LblPath.Location="15,180"; $LblPath.AutoSize=$true; $PnlExt.Controls.Add($LblPath)
$TxtPath = New-Object System.Windows.Forms.TextBox; $TxtPath.Location="15,205"; $TxtPath.Size="220,25"; $PnlExt.Controls.Add($TxtPath)
$BtnPath = New-Object System.Windows.Forms.Button; $BtnPath.Text="..."; $BtnPath.Location="240,203"; $BtnPath.Size="40,27"; $BtnPath.FlatStyle="Flat"; $PnlExt.Controls.Add($BtnPath)
$BtnPath.Add_Click({ $FBD = New-Object System.Windows.Forms.FolderBrowserDialog; if($FBD.ShowDialog() -eq "OK"){$TxtPath.Text=$FBD.SelectedPath} })

# --- ACTIONS ---
$PnlAct = New-Object System.Windows.Forms.Panel; $PnlAct.Location="20,420"; $PnlAct.Size="940,120"; $PnlAct.BackColor=$Theme.Card; $PnlAct.Add_Paint($PaintHandler); $Form.Controls.Add($PnlAct)

function Add-BigBtn ($Txt, $X, $Col, $Cmd) {
    $B = New-Object System.Windows.Forms.Button; $B.Text=$Txt; $B.Location="$X,35"; $B.Size="280,50"; $B.Font="Segoe UI, 12, Bold"
    $B.BackColor=$Col; $B.ForeColor="Black"; $B.FlatStyle="Flat"; $B.Cursor="Hand"; $B.Add_Click($Cmd)
    $PnlAct.Controls.Add($B)
}

Add-BigBtn "CAI DAT OFFICE NGAY" 20 "OrangeRed" { Start-Install "Install" }
Add-BigBtn "TAI VE (TAO BO CAI OFF)" 330 "Gold" { Start-Install "Download" }
Add-BigBtn "GO OFFICE CU (UNINSTALL)" 640 "Gray" { Start-Uninstall }

$TxtLog = New-Object System.Windows.Forms.TextBox; $TxtLog.Multiline=$true; $TxtLog.Location="20,560"; $TxtLog.Size="940,80"; $TxtLog.BackColor="Black"; $TxtLog.ForeColor="Lime"; $TxtLog.ReadOnly=$true; $Form.Controls.Add($TxtLog)

# ================= LOGIC =================

function Log ($M) { $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $M`r`n") }

function Get-Odt {
    $OdtPath = "$env:TEMP\setup.exe"
    if (!(Test-Path $OdtPath)) {
        Log "Dang tai Office Deployment Tool..."
        try {
            (New-Object System.Net.WebClient).DownloadFile("https://otp.landian.vip/en-us/setup.exe", $OdtPath) 
        } catch { Log "Loi tai ODT! Kiem tra mang." }
    }
    return $OdtPath
}

function Start-Install ($Mode) {
    # 1. PARAMS
    $VerStr = ($RadioVers | Where {$_.Checked}).Text
    $Arch = if ($R64.Checked) { "64" } else { "32" }
    $Lang = $CbLang.SelectedItem
    $IsVol = $ChkVl.Checked
    
    # 2. MAP PRODUCT ID
    $ProdID = switch -Regex ($VerStr) {
        "2016" { if($IsVol){"ProPlusVolume"}else{"ProPlusRetail"} }
        "2019" { if($IsVol){"ProPlus2019Volume"}else{"ProPlus2019Retail"} }
        "2021" { if($IsVol){"ProPlus2021Volume"}else{"ProPlus2021Retail"} }
        "2024" { if($IsVol){"ProPlus2024Volume"}else{"ProPlus2024Retail"} }
        "365"  { "O365ProPlusRetail" }
    }
    
    # 3. CREATE XML (FIXED SYNTAX)
    $XmlPath = "$env:TEMP\config_office.xml"
    $Writer = New-Object System.IO.StreamWriter($XmlPath)
    $Writer.WriteLine('<Configuration>') # Dung nhay don bao ngoai
    
    $SrcAttr = if ($Mode -eq "Download" -or $TxtPath.Text) { 
        $P = if($TxtPath.Text){$TxtPath.Text}else{"$env:USERPROFILE\Desktop\Office_Install_Files"}
        'SourcePath="' + $P + '"' 
    } else { "" }
    
    # FIX: Dùng chuỗi ghép (Concatenation) để tránh lỗi Parser
    $Writer.WriteLine('  <Add OfficeClientEdition="' + $Arch + '" Channel="PerpetualVL2021" ' + $SrcAttr + '>')
    
    $Writer.WriteLine('    <Product ID="' + $ProdID + '">')
    $Writer.WriteLine('      <Language ID="' + $Lang + '" />')
    
    foreach ($C in $ChkApps) {
        if (!$C.Checked) {
            $AppID = switch ($C.Text) {
                "Word" {"Word"} "Excel" {"Excel"} "PowerPoint" {"PowerPoint"} "Outlook" {"Outlook"} 
                "OneNote" {"OneNote"} "Access" {"Access"} "Publisher" {"Publisher"} "Teams" {"Teams"} "OneDrive" {"Groove"} "SkypeForBusiness" {"Lync"}
            }
            $Writer.WriteLine('      <ExcludeApp ID="' + $AppID + '" />')
        }
    }
    $Writer.WriteLine('    </Product>')
    
    if ($ChkVisio.Checked) {
        $Vid = if($IsVol){"VisioPro2021Volume"}else{"VisioProRetail"}
        $Writer.WriteLine('    <Product ID="' + $Vid + '"><Language ID="' + $Lang + '" /></Product>')
    }
    if ($ChkProj.Checked) {
        $Pid = if($IsVol){"ProjectPro2021Volume"}else{"ProjectProRetail"}
        $Writer.WriteLine('    <Product ID="' + $Pid + '"><Language ID="' + $Lang + '" /></Product>')
    }
    
    $Writer.WriteLine('  </Add>')
    
    if ($Mode -eq "Install") {
        $Writer.WriteLine('  <Display Level="Full" AcceptEULA="TRUE" />')
        $Writer.WriteLine('  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />')
    }
    $Writer.WriteLine('</Configuration>')
    $Writer.Close()
    
    # 4. RUN
    $Setup = Get-Odt
    Log "Da tao file Config.xml. Dang chay setup.exe..."
    
    try {
        if ($Mode -eq "Install") {
            Start-Process $Setup -ArgumentList "/configure `"$XmlPath`"" 
            Log "Da khoi chay trinh cai dat Office!"
        } else {
            Log "Dang tai file cai dat ve... (Se mat thoi gian)"
            $Proc = Start-Process $Setup -ArgumentList "/download `"$XmlPath`"" -PassThru
            while (!$Proc.HasExited) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -m 500 }
            Log "Da tai xong! Kiem tra thu muc chon."
            [System.Windows.Forms.MessageBox]::Show("Tai xong Office Offline!", "Thanh cong")
        }
    } catch { Log "Loi chay Setup: $($_.Exception.Message)" }
}

function Start-Uninstall {
    if ([System.Windows.Forms.MessageBox]::Show("Ban co chac muon GO BO toan bo Office?", "Canh bao", "YesNo", "Warning") -eq "Yes") {
        $XmlPath = "$env:TEMP\remove_office.xml"
        [IO.File]::WriteAllText($XmlPath, '<Configuration><Remove All="TRUE" /></Configuration>')
        $Setup = Get-Odt
        Start-Process $Setup -ArgumentList "/configure `"$XmlPath`""
        Log "Da gui lenh go bo Office."
    }
}

$Form.ShowDialog() | Out-Null
