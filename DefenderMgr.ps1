# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "DEFENDER MANAGER PRO - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(900, 650)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 25)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "WINDOWS DEFENDER ULTIMATE CONTROL"; $LblT.Font = "Impact, 20"; $LblT.ForeColor="Cyan"; $LblT.AutoSize=$true; $LblT.Location="20,15"; $Form.Controls.Add($LblT)

# TAB CONTROL
$Tabs = New-Object System.Windows.Forms.TabControl; $Tabs.Location="20,70"; $Tabs.Size="845,460"; $Form.Controls.Add($Tabs)
function Make-Tab ($T) { $P=New-Object System.Windows.Forms.TabPage; $P.Text=$T; $P.BackColor=[System.Drawing.Color]::FromArgb(35,35,35); $Tabs.Controls.Add($P); return $P }

$TabStat = Make-Tab "TRANG THAI & DIEU KHIEN"
$TabExcl = Make-Tab "DANH SACH LOAI TRU (EXCLUSIONS)"
$TabAdv  = Make-Tab "NANG CAO (ADVANCED)"

# =========================================================================================
# TAB 1: DASHBOARD & CONTROL
# =========================================================================================

# --- STATUS PANEL ---
$GbStatus = New-Object System.Windows.Forms.GroupBox; $GbStatus.Text="1. TRANG THAI BAO VE (REAL-TIME STATUS)"; $GbStatus.Location="20,20"; $GbStatus.Size="800,100"; $GbStatus.ForeColor="Yellow"; $TabStat.Controls.Add($GbStatus)

function Add-StatLbl ($P, $T, $X, $Y) {
    $L1 = New-Object System.Windows.Forms.Label; $L1.Text=$T; $L1.Location="$X,$Y"; $L1.AutoSize=$true; $L1.ForeColor="LightGray"; $P.Controls.Add($L1)
    $L2 = New-Object System.Windows.Forms.Label; $L2.Text="Checking..."; $L2.Location="$($X+130),$Y"; $L2.AutoSize=$true; $L2.Font="Segoe UI, 9, Bold"; $P.Controls.Add($L2)
    return $L2
}

$StReal  = Add-StatLbl $GbStatus "Real-time Protection:" 20 30
$StCloud = Add-StatLbl $GbStatus "Cloud Protection:" 20 60
$StIOAV  = Add-StatLbl $GbStatus "Download Scan (IOAV):" 400 30
$StTamp  = Add-StatLbl $GbStatus "Tamper Protection:" 400 60

# --- CONTROL PANEL ---
$GbCtrl = New-Object System.Windows.Forms.GroupBox; $GbCtrl.Text="2. DIEU KHIEN (ON/OFF)"; $GbCtrl.Location="20,140"; $GbCtrl.Size="480,270"; $GbCtrl.ForeColor="Cyan"; $TabStat.Controls.Add($GbCtrl)

function Add-Toggle ($P, $Txt, $Y, $Tag) {
    $c = New-Object System.Windows.Forms.CheckBox; $c.Text=$Txt; $c.Location="20,$Y"; $c.AutoSize=$true; $c.Tag=$Tag; $c.Font="Segoe UI, 10"; $c.ForeColor="White"; $P.Controls.Add($c); return $c
}

$ChkReal  = Add-Toggle $GbCtrl "Real-time Protection (Bao ve thoi gian thuc)" 30 "DisableRealtimeMonitoring"
$ChkCloud = Add-Toggle $GbCtrl "Cloud Protection (Bao ve dam may)" 60 "MAPSReporting" # 0=Off, 2=On
$ChkIOAV  = Add-Toggle $GbCtrl "Download Scanning (Quet file tai ve)" 90 "DisableIOAVProtection"
$L_Note   = New-Object System.Windows.Forms.Label; $L_Note.Text="*Luu y: Tamper Protection phai tat thu cong!"; $L_Note.Location="20,130"; $L_Note.AutoSize=$true; $L_Note.ForeColor="Red"; $GbCtrl.Controls.Add($L_Note)

$BtnApply = New-Object System.Windows.Forms.Button; $BtnApply.Text="AP DUNG THAY DOI (APPLY)"; $BtnApply.Location="20,160"; $BtnApply.Size="440,40"; $BtnApply.BackColor="DimGray"; $BtnApply.ForeColor="White"; $GbCtrl.Controls.Add($BtnApply)

$BtnPermOff = New-Object System.Windows.Forms.Button; $BtnPermOff.Text="TAT HOAN TOAN (REGISTRY - VINH VIEN)"; $BtnPermOff.Location="20,210"; $BtnPermOff.Size="440,40"; $BtnPermOff.BackColor="DarkRed"; $BtnPermOff.ForeColor="White"; $GbCtrl.Controls.Add($BtnPermOff)

# --- SCHEDULE PANEL ---
$GbSche = New-Object System.Windows.Forms.GroupBox; $GbSche.Text="3. HEN GIO BAT LAI (AUTO ENABLE)"; $GbSche.Location="520,140"; $GbSche.Size="300,270"; $GbSche.ForeColor="Lime"; $TabStat.Controls.Add($GbSche)

$L_Days = New-Object System.Windows.Forms.Label; $L_Days.Text="Tat Defender trong (Ngay):"; $L_Days.Location="20,40"; $L_Days.AutoSize=$true; $GbSche.Controls.Add($L_Days)
$NumDays = New-Object System.Windows.Forms.NumericUpDown; $NumDays.Location="20,70"; $NumDays.Size="100,30"; $NumDays.Minimum=1; $NumDays.Value=1; $GbSche.Controls.Add($NumDays)

$BtnPause = New-Object System.Windows.Forms.Button; $BtnPause.Text="TAM DUNG & HEN GIO"; $BtnPause.Location="20,120"; $BtnPause.Size="260,50"; $BtnPause.BackColor="Orange"; $BtnPause.ForeColor="Black"; $GbSche.Controls.Add($BtnPause)
$BtnResume = New-Object System.Windows.Forms.Button; $BtnResume.Text="HUY HEN GIO & BAT LAI"; $BtnResume.Location="20,190"; $BtnResume.Size="260,50"; $BtnResume.BackColor="Green"; $BtnResume.ForeColor="White"; $GbSche.Controls.Add($BtnResume)

# =========================================================================================
# TAB 2: EXCLUSIONS MANAGER
# =========================================================================================
$Grid = New-Object System.Windows.Forms.DataGridView; $Grid.Location="20,20"; $Grid.Size="800,300"; $Grid.BackgroundColor="Black"; $Grid.ForeColor="Black"; $Grid.AllowUserToAddRows=$false; $Grid.RowHeadersVisible=$false; $Grid.SelectionMode="FullRowSelect"; $Grid.AutoSizeColumnsMode="Fill"
$Grid.Columns.Add("Type", "Loai"); $Grid.Columns.Add("Path", "Duong Dan / Gia Tri"); $Grid.Columns[0].Width=100
$TabExcl.Controls.Add($Grid)

$PnlBtns = New-Object System.Windows.Forms.Panel; $PnlBtns.Location="20,330"; $PnlBtns.Size="800,60"; $TabExcl.Controls.Add($PnlBtns)

function Add-ExBtn ($T, $X, $Col, $Cmd) { $b=New-Object System.Windows.Forms.Button; $b.Text=$T; $b.Location="$X,10"; $b.Size="140,40"; $b.BackColor=$Col; $b.ForeColor="White"; $b.Add_Click($Cmd); $PnlBtns.Controls.Add($b) }

Add-ExBtn "+ THEM FILE" 0 "Teal" {
    $OFD = New-Object System.Windows.Forms.OpenFileDialog; $OFD.Title="Chon File can loai tru"
    if($OFD.ShowDialog() -eq "OK") { Add-MpPreference -ExclusionPath $OFD.FileName; Refresh-Exclusions }
}
Add-ExBtn "+ THEM THU MUC" 150 "Teal" {
    $FBD = New-Object System.Windows.Forms.FolderBrowserDialog
    if($FBD.ShowDialog() -eq "OK") { Add-MpPreference -ExclusionPath $FBD.SelectedPath; Refresh-Exclusions }
}
Add-ExBtn "+ THEM DUOI FILE" 300 "Teal" {
    $Ext = [Microsoft.VisualBasic.Interaction]::InputBox("Nhap duoi file (VD: .exe, .iso):", "Extension Exclusion")
    if($Ext) { Add-MpPreference -ExclusionExtension $Ext; Refresh-Exclusions }
}
Add-ExBtn "- XOA MUC CHON" 450 "Firebrick" {
    if($Grid.SelectedRows.Count -gt 0) {
        $Row = $Grid.SelectedRows[0]; $Type = $Row.Cells[0].Value; $Val = $Row.Cells[1].Value
        if($Type -match "File|Folder") { Remove-MpPreference -ExclusionPath $Val }
        if($Type -eq "Extension") { Remove-MpPreference -ExclusionExtension $Val }
        if($Type -eq "Process") { Remove-MpPreference -ExclusionProcess $Val }
        Refresh-Exclusions
    }
}
Add-ExBtn "LAM MOI (REFRESH)" 600 "Gray" { Refresh-Exclusions }

# =========================================================================================
# TAB 3: ADVANCED TOOLS (XỊN XỊN)
# =========================================================================================
$GbAdvTools = New-Object System.Windows.Forms.GroupBox; $GbAdvTools.Text="CONG CU BO TRO"; $GbAdvTools.Location="20,20"; $GbAdvTools.Size="800,150"; $GbAdvTools.ForeColor="Cyan"; $TabAdv.Controls.Add($GbAdvTools)

function Add-AdvBtn ($T, $X, $Cmd) { $b=New-Object System.Windows.Forms.Button; $b.Text=$T; $b.Location="$X,40"; $b.Size="230,50"; $b.BackColor="DimGray"; $b.ForeColor="White"; $b.Add_Click($Cmd); $GbAdvTools.Controls.Add($b) }

Add-AdvBtn "XOA LICH SU QUET (PURGE LOGS)" 20 {
    $LogPath = "C:\ProgramData\Microsoft\Windows Defender\Scans\History\Service"
    if(Test-Path $LogPath) { Remove-Item "$LogPath\*" -Recurse -Force; [System.Windows.Forms.MessageBox]::Show("Da xoa sach nhat ky quet virus!", "Done") }
}
Add-AdvBtn "GIOI HAN CPU KHI QUET (20%)" 270 { Set-MpPreference -ScanAvgCPULoadFactor 20; [System.Windows.Forms.MessageBox]::Show("Da gioi han CPU Defender xuong 20%!", "Done") }
Add-AdvBtn "UNBLOCK FILE TAI VE" 520 {
    $OFD = New-Object System.Windows.Forms.OpenFileDialog; $OFD.Title="Chon file bi Block boi SmartScreen"
    if($OFD.ShowDialog() -eq "OK") { Unblock-File -Path $OFD.FileName; [System.Windows.Forms.MessageBox]::Show("Da Unblock file an toan!", "Done") }
}

# --- FOOTER BUTTONS ---
$BtnSec = New-Object System.Windows.Forms.Button; $BtnSec.Text="MO WINDOWS SECURITY"; $BtnSec.Location="20,550"; $BtnSec.Size="400,50"; $BtnSec.BackColor="Blue"; $BtnSec.ForeColor="White"; $Form.Controls.Add($BtnSec)
$BtnSec.Add_Click({ Start-Process "windowsdefender:" })

$BtnSet = New-Object System.Windows.Forms.Button; $BtnSet.Text="MO VIRUS & THREAT SETTINGS"; $BtnSet.Location="465,550"; $BtnSet.Size="400,50"; $BtnSet.BackColor="Blue"; $BtnSet.ForeColor="White"; $Form.Controls.Add($BtnSet)
$BtnSet.Add_Click({ Start-Process "windowsdefender://threat/" })

# --- LOGIC FUNCTIONS ---

function Refresh-Status {
    $S = Get-MpComputerStatus
    
    # Realtime
    if($S.RealTimeProtectionEnabled){ $StReal.Text="ON"; $StReal.ForeColor="Lime"; $ChkReal.Checked=$false } 
    else { $StReal.Text="OFF"; $StReal.ForeColor="Red"; $ChkReal.Checked=$true }
    
    # Cloud
    # Get-MpPreference MAPSReporting (2=Adv, 0=Off)
    $Pref = Get-MpPreference
    if($Pref.MAPSReporting -eq 2){ $StCloud.Text="ON"; $StCloud.ForeColor="Lime"; $ChkCloud.Checked=$false } 
    else { $StCloud.Text="OFF"; $StCloud.ForeColor="Red"; $ChkCloud.Checked=$true }
    
    # IOAV
    if($S.IoavProtectionEnabled){ $StIOAV.Text="ON"; $StIOAV.ForeColor="Lime"; $ChkIOAV.Checked=$false } 
    else { $StIOAV.Text="OFF"; $StIOAV.ForeColor="Red"; $ChkIOAV.Checked=$true }
    
    # Tamper
    if($S.IsTamperProtectionEnabled){ $StTamp.Text="ON (LOCKED)"; $StTamp.ForeColor="Red" } 
    else { $StTamp.Text="OFF (UNLOCKED)"; $StTamp.ForeColor="Gray" }
}

function Refresh-Exclusions {
    $Grid.Rows.Clear()
    $P = Get-MpPreference
    if ($P.ExclusionPath) { foreach($p in $P.ExclusionPath) { 
        $Type = if($p -match "\.\w+$"){"File"}else{"Folder"}
        $Grid.Rows.Add($Type, $p) 
    }}
    if ($P.ExclusionExtension) { foreach($e in $P.ExclusionExtension) { $Grid.Rows.Add("Extension", $e) } }
    if ($P.ExclusionProcess) { foreach($pr in $P.ExclusionProcess) { $Grid.Rows.Add("Process", $pr) } }
}

$BtnApply.Add_Click({
    try {
        # Realtime: Logic Checkbox la "Tat" -> Checked = Tat
        $Real = !$ChkReal.Checked
        Set-MpPreference -DisableRealtimeMonitoring (!$Real) -ErrorAction Stop
        
        # Cloud
        if ($ChkCloud.Checked) { Set-MpPreference -MAPSReporting 0 } else { Set-MpPreference -MAPSReporting 2 }
        
        # IOAV
        if ($ChkIOAV.Checked) { Set-MpPreference -DisableIOAVProtection $true } else { Set-MpPreference -DisableIOAVProtection $false }
        
        [System.Windows.Forms.MessageBox]::Show("Da ap dung cau hinh!", "Success")
        Refresh-Status
    } catch {
        [System.Windows.Forms.MessageBox]::Show("KHONG THE THAY DOI!`nCo the do Tamper Protection dang bat.`nVui long tat Tamper Protection truoc!", "Blocked", "OK", "Error")
    }
})

$BtnPermOff.Add_Click({
    if([System.Windows.Forms.MessageBox]::Show("Ban muon tat vinh vien Defender bang Registry?`n(Yeu cau Tamper Protection phai OFF truoc)", "Confirm", "YesNo") -eq "Yes") {
        New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -PropertyType DWORD -Force
        Set-MpPreference -DisableRealtimeMonitoring $true
        [System.Windows.Forms.MessageBox]::Show("Da ghi Registry tat Defender. Restart may de ap dung.", "Done")
    }
})

$BtnPause.Add_Click({
    $Days = $NumDays.Value
    # Tat ngay lap tuc
    Set-MpPreference -DisableRealtimeMonitoring $true
    
    # Tao Scheduled Task de bat lai sau X ngay
    $Date = (Get-Date).AddDays($Days).ToString("HH:mm")
    $DateStr = (Get-Date).AddDays($Days).ToString("dd/MM/yyyy")
    
    $Cmd = "powershell -WindowStyle Hidden -Command `"Set-MpPreference -DisableRealtimeMonitoring `$false`""
    Schtasks /Create /SC ONCE /TN "PhatTan_EnableDefender" /TR $Cmd /ST $Date /SD $DateStr /RL HIGHEST /F | Out-Null
    
    [System.Windows.Forms.MessageBox]::Show("Da tat Defender!`nHe thong se tu dong bat lai vao luc: $Date ngay $DateStr", "Scheduled")
    Refresh-Status
})

$BtnResume.Add_Click({
    Set-MpPreference -DisableRealtimeMonitoring $false
    Schtasks /Delete /TN "PhatTan_EnableDefender" /F | Out-Null
    [System.Windows.Forms.MessageBox]::Show("Da bat lai Defender va huy lich hen gio.", "Done")
    Refresh-Status
})

# INIT
Add-Type -AssemblyName Microsoft.VisualBasic
$Form.Add_Shown({ Refresh-Status; Refresh-Exclusions })
$Form.ShowDialog() | Out-Null
