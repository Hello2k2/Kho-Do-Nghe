# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- THEME ENGINE (NEON GLOW) ---
$Theme = @{
    Back      = [System.Drawing.Color]::FromArgb(20, 20, 25)
    Card      = [System.Drawing.Color]::FromArgb(30, 30, 35)
    Text      = [System.Drawing.Color]::FromArgb(240, 240, 240)
    BtnBack   = [System.Drawing.Color]::FromArgb(45, 45, 50)
    BtnHover  = [System.Drawing.Color]::FromArgb(0, 180, 180) 
    Accent    = [System.Drawing.Color]::FromArgb(0, 255, 255)     # Cyan Neon
    Valid     = [System.Drawing.Color]::FromArgb(0, 255, 0)       # Green Neon
    Error     = [System.Drawing.Color]::FromArgb(255, 0, 80)      # Red Neon
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "ACTIVATION CENTER & ESU MASTER (SMART EDITION)"
$Form.Size = New-Object System.Drawing.Size(950, 680)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back
$Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "WINDOWS ACTIVATION & ESU MASTER"; $LblT.Font = "Segoe UI, 18, Bold"; $LblT.ForeColor = $Theme.Accent; $LblT.AutoSize = $true; $LblT.Location = "20,15"; $Form.Controls.Add($LblT)
$LblS = New-Object System.Windows.Forms.Label; $LblS.Text = "Powered by MAS 3.9 | Smart Key Engine v1.0"; $LblS.ForeColor = "Gray"; $LblS.AutoSize = $true; $LblS.Location = "25,50"; $Form.Controls.Add($LblS)

# --- ADVANCED GLOW PAINTER ---
$GlowPaint = {
    param($sender, $e)
    $GlowColor = $Theme.Accent
    for ($i = 1; $i -le 4; $i++) {
        $Alpha = 50 - ($i * 10); if ($Alpha -lt 0) { $Alpha = 0 }
        $Pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb($Alpha, $GlowColor), $i * 2)
        $Rect = $sender.ClientRectangle
        $Rect.X += $i; $Rect.Y += $i; $Rect.Width -= ($i * 2); $Rect.Height -= ($i * 2)
        $e.Graphics.DrawRectangle($Pen, $Rect); $Pen.Dispose()
    }
    $MainPen = New-Object System.Windows.Forms.Pen($GlowColor, 1)
    $RMain = $sender.ClientRectangle; $RMain.Width-=1; $RMain.Height-=1
    $e.Graphics.DrawRectangle($MainPen, $RMain); $MainPen.Dispose()
}

# --- HELPER FUNCTIONS ---
function Add-Card ($X, $Y, $W, $H, $Title) {
    $P = New-Object System.Windows.Forms.Panel
    $P.Location="$X,$Y"; $P.Size="$W,$H"; $P.BackColor=$Theme.Card
    $P.Padding = "2,2,2,2"; $P.Add_Paint($GlowPaint)
    $L = New-Object System.Windows.Forms.Label; $L.Text=$Title; $L.Font="Segoe UI, 11, Bold"; $L.ForeColor=$Theme.Accent; $L.Location="15,15"; $L.AutoSize=$true
    $P.Controls.Add($L); $Form.Controls.Add($P); return $P
}

function Add-Btn ($Parent, $Txt, $X, $Y, $W, $Cmd) {
    $B = New-Object System.Windows.Forms.Button; $B.Text=$Txt; $B.Location="$X,$Y"; $B.Size="$W,40"
    $B.FlatStyle="Flat"; $B.Font="Segoe UI, 9, Bold"; $B.BackColor=$Theme.BtnBack; $B.ForeColor=$Theme.Text; $B.Cursor="Hand"
    $B.FlatAppearance.BorderSize = 0; $B.Add_Click($Cmd)
    $B.Add_MouseEnter({ if($this.Enabled){$this.BackColor=$Theme.BtnHover; $this.ForeColor="Black"} })
    $B.Add_MouseLeave({ if($this.Enabled){$this.BackColor=$Theme.BtnBack; $this.ForeColor=$Theme.Text} })
    $Parent.Controls.Add($B); return $B
}

# =========================================================================================
# SECTION 1: SMART KEY INPUT (THE ROBOT PART)
# =========================================================================================
$CardKey = Add-Card 20 80 895 150 "1. NHAP KEY THU CONG (SMART ENGINE)"

# Input Box Style Robot
$TxtKey = New-Object System.Windows.Forms.TextBox
$TxtKey.Location="25,50"; $TxtKey.Size="550,35"; $TxtKey.Font="Consolas, 16, Bold"
$TxtKey.BackColor="Black"; $TxtKey.ForeColor="Gray"; $TxtKey.BorderStyle="FixedSingle"
$TxtKey.MaxLength = 29 # 25 chars + 4 hyphens
$CardKey.Controls.Add($TxtKey)

# Status Bar (Robot Voice)
$LblStatus = New-Object System.Windows.Forms.Label
$LblStatus.Text = "[SYSTEM]: WAITING FOR INPUT..."
$LblStatus.Font = "Consolas, 9"; $LblStatus.ForeColor = "Gray"
$LblStatus.Location = "25, 95"; $LblStatus.AutoSize = $true
$CardKey.Controls.Add($LblStatus)

# Paste Button (Icon Style)
$BtnPaste = New-Object System.Windows.Forms.Button
$BtnPaste.Text = "📋 PASTE"
$BtnPaste.Location = "585, 50"; $BtnPaste.Size = "80, 32"; $BtnPaste.FlatStyle="Flat"; $BtnPaste.BackColor="DimGray"; $BtnPaste.ForeColor="White"
$CardKey.Controls.Add($BtnPaste)

# Action Buttons
$BtnInstallKey = Add-Btn $CardKey "NẠP KEY (INSTALL)" 680 48 180 {
    $K = $TxtKey.Text
    Start-Process "slmgr.vbs" -ArgumentList "/ipk $K" -Wait
    Start-Process "slmgr.vbs" -ArgumentList "/ato" -Wait
    [System.Windows.Forms.MessageBox]::Show("Da gui lenh kich hoat!`nKey: $K", "Success")
}
$BtnInstallKey.Enabled = $false # Mac dinh khoa
$BtnInstallKey.BackColor = [System.Drawing.Color]::FromArgb(30,30,30); $BtnInstallKey.ForeColor="Gray"

# --- LOGIC THÔNG MINH (SMART LOGIC) ---
$BtnPaste.Add_Click({
    if ([System.Windows.Forms.Clipboard]::ContainsText()) {
        $Clip = [System.Windows.Forms.Clipboard]::GetText()
        # Loc bo moi ky tu rac, chi lay chu va so
        $Clean = $Clip -replace "[^a-zA-Z0-9]", ""
        if ($Clean.Length -gt 25) { $Clean = $Clean.Substring(0, 25) }
        $TxtKey.Text = $Clean # Trigger TextChanged
    }
})

# Bien co de tranh loop khi format
$Global:IsFormatting = $false

$TxtKey.Add_TextChanged({
    if ($Global:IsFormatting) { return }
    $Global:IsFormatting = $true
    
    # 1. Lay vi tri con tro
    $CursorPos = $TxtKey.SelectionStart
    
    # 2. Clean Text (Chi lay chu so, Upper case)
    $Raw = $TxtKey.Text -replace "[^a-zA-Z0-9]", ""
    $Raw = $Raw.ToUpper()
    
    # 3. Auto Add Hyphens (Them dau gach ngang)
    $Formatted = ""
    for ($i = 0; $i -lt $Raw.Length; $i++) {
        if ($i -gt 0 -and $i % 5 -eq 0) { $Formatted += "-" }
        $Formatted += $Raw[$i]
    }
    
    # 4. Limit Length
    if ($Formatted.Length -gt 29) { $Formatted = $Formatted.Substring(0, 29) }
    
    $TxtKey.Text = $Formatted
    
    # 5. Restore Cursor (Hack nhe de con tro khong bi nhay ve cuoi)
    try { $TxtKey.SelectionStart = $Formatted.Length } catch {}
    
    # 6. Validate & Visual Feedback
    if ($Raw.Length -eq 25) {
        $TxtKey.ForeColor = $Theme.Valid # Xanh Neon
        $LblStatus.Text = "[SYSTEM]: KEY FORMAT VALIDIFIED. READY TO INSTALL."
        $LblStatus.ForeColor = $Theme.Valid
        $BtnInstallKey.Enabled = $true
        $BtnInstallKey.BackColor = $Theme.BtnBack; $BtnInstallKey.ForeColor = $Theme.Text
    } else {
        $TxtKey.ForeColor = $Theme.Error # Do Neon
        $Count = 25 - $Raw.Length
        $LblStatus.Text = "[SYSTEM]: ANALYZING... MISSING $Count CHARACTERS"
        $LblStatus.ForeColor = $Theme.Error
        $BtnInstallKey.Enabled = $false
        $BtnInstallKey.BackColor = [System.Drawing.Color]::FromArgb(30,30,30); $BtnInstallKey.ForeColor="Gray"
    }
    
    if ($Raw.Length -eq 0) {
        $TxtKey.ForeColor = "Gray"
        $LblStatus.Text = "[SYSTEM]: WAITING FOR INPUT..."
        $LblStatus.ForeColor = "Gray"
    }
    
    $Global:IsFormatting = $false
})

# =========================================================================================
# SECTION 2: CONVERT EDITION
# =========================================================================================
$CardConv = Add-Card 20 250 435 300 "2. CHUYEN DOI PHIEN BAN WIN (CONVERT)"

$LblConv = New-Object System.Windows.Forms.Label; $LblConv.Text="Chon phien ban muon chuyen doi sang:"; $LblConv.Location="20,50"; $LblConv.AutoSize=$true; $LblConv.ForeColor="White"; $CardConv.Controls.Add($LblConv)

$CbEditions = New-Object System.Windows.Forms.ComboBox; $CbEditions.Location="20,80"; $CbEditions.Size="390,30"; $CbEditions.Font="Segoe UI, 11"; $CbEditions.DropDownStyle="DropDownList"
$Editions = @("IoT Enterprise LTSC (Recommended for ESU)", "Enterprise LTSC 2021", "Professional", "Professional Workstation", "Enterprise", "Education", "Home")
foreach ($E in $Editions) { $CbEditions.Items.Add($E) | Out-Null }; $CbEditions.SelectedIndex = 0
$CardConv.Controls.Add($CbEditions)

Add-Btn $CardConv "TIEN HANH CONVERT (AUTO)" 20 130 390 {
    $Msg = "Tool se mo Menu MAS. Ban hay bam: [6] Extras -> [1] Change Edition -> Chon phien ban tuong ung."
    if ([System.Windows.Forms.MessageBox]::Show($Msg, "Huong dan", "YesNo", "Information") -eq "Yes") {
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "irm https://get.activated.win | iex"
    }
}
$LblEsu = New-Object System.Windows.Forms.Label; $LblEsu.Text="MEO: De co ESU 2032 (Win 10), hay chuyen sang ban 'IoT Enterprise LTSC'."; $LblEsu.ForeColor="Gold"; $LblEsu.Location="20,200"; $LblEsu.Size="390,50"; $CardConv.Controls.Add($LblEsu)

# =========================================================================================
# SECTION 3: MAS 3.9 ACTIVATION
# =========================================================================================
$CardMas = Add-Card 480 250 435 300 "3. MAS 3.9 - AUTO ACTIVATION & ESU"

Add-Btn $CardMas "1. KICH HOAT WINDOWS (HWID)" 20 50 390 {
    if ([System.Windows.Forms.MessageBox]::Show("Kich hoat Ban quyen so vinh vien (HWID)?", "Confirm", "YesNo") -eq "Yes") {
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "irm https://get.activated.win | iex"
        [System.Windows.Forms.MessageBox]::Show("Cua so MAS da mo. Bam phim [1] de kich hoat HWID.", "Huong dan")
    }
}

Add-Btn $CardMas "2. KICH HOAT OFFICE (OHOOK)" 20 100 390 {
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "irm https://get.activated.win | iex"
    [System.Windows.Forms.MessageBox]::Show("Cua so MAS da mo. Bam phim [2] de kich hoat Office.", "Huong dan")
}

Add-Btn $CardMas "3. KICH HOAT ESU / WIN / OFFICE (TSforge)" 20 150 390 {
    $M = "*** QUAN TRONG: De co ESU (Update 2032): ***`n1. Convert sang 'IoT Enterprise LTSC' (Ben trai).`n2. Chon nut nay -> Cua so hien len -> Chon so [3] (TSforge).`n3. Chon tiep de kich hoat ESU."
    if ([System.Windows.Forms.MessageBox]::Show($M, "Huong dan ESU", "YesNo", "Warning") -eq "Yes") {
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "irm https://get.activated.win | iex"
    }
}

Add-Btn $CardMas "KIEM TRA TRANG THAI (CHECK STATUS)" 20 230 390 { Start-Process "slmgr.vbs" -ArgumentList "/xpr" }

# --- FOOTER ---
$BtnDelKey = New-Object System.Windows.Forms.Button; $BtnDelKey.Text="XOA KEY / HUY KICH HOAT"; $BtnDelKey.Location="20,570"; $BtnDelKey.Size="250,30"; $BtnDelKey.FlatStyle="Flat"; $BtnDelKey.ForeColor="Red"; $BtnDelKey.BackColor=$Theme.Back; $BtnDelKey.Cursor="Hand"
$BtnDelKey.Add_Click({ Start-Process "slmgr.vbs" -ArgumentList "/upk" -Wait; Start-Process "slmgr.vbs" -ArgumentList "/cpky" })
$Form.Controls.Add($BtnDelKey)

$LblCredit = New-Object System.Windows.Forms.Label; $LblCredit.Text="Powered by MAS (Massgrave.dev)"; $LblCredit.ForeColor="DimGray"; $LblCredit.Location="650,580"; $LblCredit.AutoSize=$true; $Form.Controls.Add($LblCredit)

$Form.ShowDialog() | Out-Null
