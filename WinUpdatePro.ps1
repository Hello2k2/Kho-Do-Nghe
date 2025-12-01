# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WINDOWS UPDATE PRO MANAGER - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(950, 650)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# REGISTRY PATHS
$RegAU = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
$RegWU = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$RegUX = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"

# --- HELPER FUNCTIONS ---
function Set-Reg ($Path, $Name, $Val, $Type="DWord") {
    if (!(Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    if ($Val -eq $null) { Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue }
    else { Set-ItemProperty -Path $Path -Name $Name -Value $Val -Type $Type }
}

function Get-Reg ($Path, $Name) {
    if (Test-Path $Path) {
        $V = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        return $V.$Name
    }
    return $null
}

# --- HEADER ---
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "WINDOWS UPDATE CONTROL CENTER"; $LblT.Font = "Impact, 20"; $LblT.ForeColor="Cyan"; $LblT.AutoSize=$true; $LblT.Location="20,15"; $Form.Controls.Add($LblT)

# ==========================================
# KHU VỰC 1: CÀI ĐẶT CẬP NHẬT (SETTINGS)
# ==========================================
$GbSet = New-Object System.Windows.Forms.GroupBox; $GbSet.Text = "1. CAI DAT CAP NHAT (CHINH SACH GPO)"; $GbSet.Location="20,60"; $GbSet.Size="440,220"; $GbSet.ForeColor="Yellow"; $Form.Controls.Add($GbSet)

function Add-Chk ($P, $T, $Y, $Tag) {
    $c = New-Object System.Windows.Forms.CheckBox; $c.Text=$T; $c.Location="20,$Y"; $c.AutoSize=$true; $c.Tag=$Tag; $c.Font="Segoe UI, 10"; $c.ForeColor="White"; $P.Controls.Add($c); return $c
}

$ChkService = Add-Chk $GbSet "Vo hieu hoa Windows Update Service (Tat han)" 30 "Service"
$ChkDriver  = Add-Chk $GbSet "Chan cap nhat Driver (Exclude Drivers)" 60 "Driver"
$ChkFeature = Add-Chk $GbSet "Chan len phien ban Windows moi (Target Version)" 90 "Version"
$ChkNotify  = Add-Chk $GbSet "Che do 'Metered' (Chi thong bao, khong tu tai)" 120 "Metered"
$ChkSecOnly = Add-Chk $GbSet "Chi nhan ban va Bao mat (Block Quality Update)" 150 "SecOnly" 
# Note: Block Quality thực ra là hoãn, nhưng ở đây ta dùng logic hoãn dài hạn.

# ==========================================
# KHU VỰC 2: CẤU HÌNH NÂNG CAO (ADVANCED)
# ==========================================
$GbAdv = New-Object System.Windows.Forms.GroupBox; $GbAdv.Text = "2. CAU HINH NANG CAO & GIO HOAT DONG"; $GbAdv.Location="480,60"; $GbAdv.Size="440,220"; $GbAdv.ForeColor="Lime"; $Form.Controls.Add($GbAdv)

$LblDeferF = New-Object System.Windows.Forms.Label; $LblDeferF.Text="Hoan Feature Update (Ngay):"; $LblDeferF.Location="20,30"; $LblDeferF.AutoSize=$true; $GbAdv.Controls.Add($LblDeferF)
$NumF = New-Object System.Windows.Forms.NumericUpDown; $NumF.Location="250,28"; $NumF.Size="100,25"; $NumF.Maximum=365; $GbAdv.Controls.Add($NumF)

$LblDeferQ = New-Object System.Windows.Forms.Label; $LblDeferQ.Text="Hoan Quality/Security (Ngay):"; $LblDeferQ.Location="20,65"; $LblDeferQ.AutoSize=$true; $GbAdv.Controls.Add($LblDeferQ)
$NumQ = New-Object System.Windows.Forms.NumericUpDown; $NumQ.Location="250,63"; $NumQ.Size="100,25"; $NumQ.Maximum=30; $GbAdv.Controls.Add($NumQ)

$LblActive = New-Object System.Windows.Forms.Label; $LblActive.Text="Gio Cam Restart (Active Hours):"; $LblActive.Location="20,100"; $LblActive.AutoSize=$true; $LblActive.ForeColor="Cyan"; $GbAdv.Controls.Add($LblActive)
$CmbStart = New-Object System.Windows.Forms.ComboBox; $CmbStart.Size="60,25"; $CmbStart.Location="20,130"; $CmbStart.Items.AddRange(0..23); $GbAdv.Controls.Add($CmbStart)
$LblTo = New-Object System.Windows.Forms.Label; $LblTo.Text="DEN"; $LblTo.Location="90,133"; $LblTo.AutoSize=$true; $GbAdv.Controls.Add($LblTo)
$CmbEnd = New-Object System.Windows.Forms.ComboBox; $CmbEnd.Size="60,25"; $CmbEnd.Location="130,130"; $CmbEnd.Items.AddRange(0..23); $GbAdv.Controls.Add($CmbEnd)

# ==========================================
# KHU VỰC 3: TRẠNG THÁI (STATUS)
# ==========================================
$GbStat = New-Object System.Windows.Forms.GroupBox; $GbStat.Text = "3. TRANG THAI HE THONG"; $GbStat.Location="20,290"; $GbStat.Size="440,180"; $GbStat.ForeColor="Cyan"; $Form.Controls.Add($GbStat)

$TxtStatus = New-Object System.Windows.Forms.TextBox; $TxtStatus.Multiline=$true; $TxtStatus.Location="15,25"; $TxtStatus.Size="410,140"; $TxtStatus.BackColor="Black"; $TxtStatus.ForeColor="White"; $TxtStatus.ReadOnly=$true; $GbStat.Controls.Add($TxtStatus)

function Refresh-Status {
    $S = "=== CAP NHAT LUC: $(Get-Date -Format 'HH:mm:ss') ===`r`n"
    
    # 1. Service
    $Svc = Get-Service wuauserv
    $S += " - Windows Update Service: $($Svc.Status) ($($Svc.StartType))`r`n"
    
    # 2. Driver
    $Drv = Get-Reg $RegWU "ExcludeWUDriversInQualityUpdate"
    $S += " - Driver Update Policy: $(if($Drv -eq 1){'BLOCKED'}else{'ALLOWED'})`r`n"
    
    # 3. Target Version
    $Ver = Get-Reg $RegWU "TargetReleaseVersion"
    $VerInfo = Get-Reg $RegWU "TargetReleaseVersionInfo"
    $S += " - Target Version Lock: $(if($Ver -eq 1){"LOCKED ($VerInfo)"}else{'OFF'})`r`n"

    # 4. Deferrals
    $DF = Get-Reg $RegWU "DeferFeatureUpdatesPeriodInDays"
    $DQ = Get-Reg $RegWU "DeferQualityUpdatesPeriodInDays"
    $S += " - Deferrals: Feature($($DF)d) | Quality($($DQ)d)`r`n"
    
    $TxtStatus.Text = $S
}

# ==========================================
# KHU VỰC 4: CÔNG CỤ (TOOLS)
# ==========================================
$GbTool = New-Object System.Windows.Forms.GroupBox; $GbTool.Text = "4. CONG CU XU LY SU CO"; $GbTool.Location="480,290"; $GbTool.Size="440,180"; $GbTool.ForeColor="Orange"; $Form.Controls.Add($GbTool)

function Add-Tool ($P, $T, $X, $Y, $Cmd) { $b=New-Object System.Windows.Forms.Button; $b.Text=$T; $b.Location="$X,$Y"; $b.Size="130,35"; $b.BackColor="DimGray"; $b.ForeColor="White"; $b.Add_Click($Cmd); $P.Controls.Add($b) }

Add-Tool $GbTool "Check Update" 20 30 { Start-Process "ms-settings:windowsupdate-action" }
Add-Tool $GbTool "Xoa Cache Update" 155 30 { 
    Stop-Service wuauserv -Force; Stop-Service bits -Force
    Remove-Item "$env:SystemRoot\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service wuauserv; Start-Service bits
    [System.Windows.Forms.MessageBox]::Show("Da xoa Cache (SoftwareDistribution)!", "Done") 
}
Add-Tool $GbTool "Xem Lich Su Up" 290 30 { 
    # Hien thi Gridview lich su
    try {
        $Session = New-Object -ComObject Microsoft.Update.Session
        $Searcher = $Session.CreateUpdateSearcher()
        $HistoryCount = $Searcher.GetTotalHistoryCount()
        $History = $Searcher.QueryHistory(0, $HistoryCount) | Select-Object Date, Title, Description
        $History | Out-GridView -Title "Windows Update History"
    } catch { [System.Windows.Forms.MessageBox]::Show("Loi load lich su!", "Error") }
}

Add-Tool $GbTool "Pause 7 Ngay" 20 75 { 
    # Set Registry Pause
    $D = (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:ssZ")
    Set-Reg $RegUX "PauseFeatureUpdatesStartTime" $D "String"
    Set-Reg $RegUX "PauseQualityUpdatesStartTime" $D "String"
    Set-Reg $RegUX "PauseUpdatesExpiryTime" $D "String"
    [System.Windows.Forms.MessageBox]::Show("Da tam dung update den: $D", "Done")
    Refresh-Status
}
Add-Tool $GbTool "Tiep tuc (Resume)" 155 75 {
    Set-Reg $RegUX "PauseFeatureUpdatesStartTime" $null
    Set-Reg $RegUX "PauseQualityUpdatesStartTime" $null
    Set-Reg $RegUX "PauseUpdatesExpiryTime" $null
    Start-Process "ms-settings:windowsupdate-action"
    Refresh-Status
}
Add-Tool $GbTool "Reset Service DLL" 290 75 {
    # Fix sau
    cmd /c "net stop wuauserv & regsvr32 /s wuaueng.dll & net start wuauserv"
    [System.Windows.Forms.MessageBox]::Show("Da Reset DLLs & Service!", "Done")
    Refresh-Status
}

# ==========================================
# ACTION BUTTONS (BOTTOM)
# ==========================================
$BtnApply = New-Object System.Windows.Forms.Button; $BtnApply.Text="AP DUNG TAT CA CAI DAT"; $BtnApply.Location="20,490"; $BtnApply.Size="300,50"; $BtnApply.BackColor="Green"; $BtnApply.ForeColor="White"; $BtnApply.Font="Segoe UI, 12, Bold"; $Form.Controls.Add($BtnApply)

$BtnReset = New-Object System.Windows.Forms.Button; $BtnReset.Text="RESET MAC DINH"; $BtnReset.Location="340,490"; $BtnReset.Size="200,50"; $BtnReset.BackColor="DarkRed"; $BtnReset.ForeColor="White"; $Form.Controls.Add($BtnReset)

$BtnRef = New-Object System.Windows.Forms.Button; $BtnRef.Text="REFRESH STATUS"; $BtnRef.Location="560,490"; $BtnRef.Size="150,50"; $BtnRef.BackColor="Blue"; $BtnRef.ForeColor="White"; $Form.Controls.Add($BtnRef)

$BtnExit = New-Object System.Windows.Forms.Button; $BtnExit.Text="THOAT"; $BtnExit.Location="730,490"; $BtnExit.Size="190,50"; $BtnExit.BackColor="Gray"; $BtnExit.ForeColor="White"; $BtnExit.Add_Click({$Form.Close()}); $Form.Controls.Add($BtnExit)

# --- LOGIC ÁP DỤNG ---
$BtnApply.Add_Click({
    # 1. Service
    if ($ChkService.Checked) { Stop-Service wuauserv -Force; Set-Service wuauserv -StartupType Disabled }
    else { Set-Service wuauserv -StartupType Manual; Start-Service wuauserv }

    # 2. Driver Policy
    if ($ChkDriver.Checked) { Set-Reg $RegWU "ExcludeWUDriversInQualityUpdate" 1 } 
    else { Set-Reg $RegWU "ExcludeWUDriversInQualityUpdate" $null }

    # 3. Target Version (Stay on Current)
    if ($ChkFeature.Checked) { 
        $CurVer = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion
        Set-Reg $RegWU "TargetReleaseVersion" 1
        Set-Reg $RegWU "TargetReleaseVersionInfo" $CurVer "String"
        Set-Reg $RegWU "ProductVersion" "Windows 10" "String" # Hack chung cho Win 10/11
    } else {
        Set-Reg $RegWU "TargetReleaseVersion" $null
        Set-Reg $RegWU "TargetReleaseVersionInfo" $null
    }

    # 4. Metered / Notify
    if ($ChkNotify.Checked) { Set-Reg $RegAU "NoAutoUpdate" 2; Set-Reg $RegAU "AUOptions" 2 }
    else { Set-Reg $RegAU "NoAutoUpdate" $null; Set-Reg $RegAU "AUOptions" $null }

    # 5. Advanced: Deferrals
    if ($NumF.Value -gt 0) { Set-Reg $RegWU "DeferFeatureUpdates" 1; Set-Reg $RegWU "DeferFeatureUpdatesPeriodInDays" $NumF.Value }
    else { Set-Reg $RegWU "DeferFeatureUpdates" $null; Set-Reg $RegWU "DeferFeatureUpdatesPeriodInDays" $null }

    if ($NumQ.Value -gt 0) { Set-Reg $RegWU "DeferQualityUpdates" 1; Set-Reg $RegWU "DeferQualityUpdatesPeriodInDays" $NumQ.Value }
    else { Set-Reg $RegWU "DeferQualityUpdates" $null; Set-Reg $RegWU "DeferQualityUpdatesPeriodInDays" $null }

    # 6. Active Hours
    $Start = $CmbStart.SelectedItem; $End = $CmbEnd.SelectedItem
    if ($Start -ne $null -and $End -ne $null) {
        Set-Reg $RegUX "ActiveHoursStart" $Start
        Set-Reg $RegUX "ActiveHoursEnd" $End
    }

    [System.Windows.Forms.MessageBox]::Show("Da ap dung tat ca cau hinh!", "Success")
    Refresh-Status
})

$BtnReset.Add_Click({
    if ([System.Windows.Forms.MessageBox]::Show("Ban co chac muon Reset toan bo cau hinh Update ve mac dinh?", "Confirm", "YesNo") -eq "Yes") {
        Set-Service wuauserv -StartupType Manual; Start-Service wuauserv
        Remove-ItemProperty -Path $RegWU -Name "ExcludeWUDriversInQualityUpdate" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $RegWU -Name "TargetReleaseVersion" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $RegWU -Name "DeferFeatureUpdates" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $RegAU -Name "NoAutoUpdate" -ErrorAction SilentlyContinue
        
        $ChkService.Checked=$false; $ChkDriver.Checked=$false; $ChkFeature.Checked=$false
        $NumF.Value=0; $NumQ.Value=0
        
        [System.Windows.Forms.MessageBox]::Show("Da Reset ve Mac Dinh!", "Done")
        Refresh-Status
    }
})

$BtnRef.Add_Click({ Refresh-Status })

# Load Init
$Form.Add_Shown({ 
    Refresh-Status 
    # Load Active Hours hien tai neu co
    $AhS = Get-Reg $RegUX "ActiveHoursStart"; if ($AhS) { $CmbStart.SelectedItem = $AhS } else { $CmbStart.SelectedItem = 8 }
    $AhE = Get-Reg $RegUX "ActiveHoursEnd"; if ($AhE) { $CmbEnd.SelectedItem = $AhE } else { $CmbEnd.SelectedItem = 17 }
})
$Form.ShowDialog() | Out-Null
