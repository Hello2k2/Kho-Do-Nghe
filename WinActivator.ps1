# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- THEME ENGINE (NEON GLOW) ---
$Theme = @{
    Back      = [System.Drawing.Color]::FromArgb(25, 25, 30)
    Card      = [System.Drawing.Color]::FromArgb(35, 35, 40)
    Text      = [System.Drawing.Color]::FromArgb(240, 240, 240)
    BtnBack   = [System.Drawing.Color]::FromArgb(50, 50, 60)
    BtnHover  = [System.Drawing.Color]::FromArgb(0, 180, 180) 
    Accent    = [System.Drawing.Color]::FromArgb(0, 255, 255)     # Cyan Neon
    GlowColor = [System.Drawing.Color]::FromArgb(0, 255, 255)     # Màu tỏa sáng
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "ACTIVATION CENTER AND ESU ENABLER (MAS 3.9)"
$Form.Size = New-Object System.Drawing.Size(950, 650)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back
$Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "WINDOWS ACTIVATION & ESU MASTER"; $LblT.Font = "Segoe UI, 18, Bold"; $LblT.ForeColor = $Theme.Accent; $LblT.AutoSize = $true; $LblT.Location = "20,15"; $Form.Controls.Add($LblT)
$LblS = New-Object System.Windows.Forms.Label; $LblS.Text = "Powered by MAS 3.9 | Ho tro ESU Update den 2032"; $LblS.ForeColor = "Gray"; $LblS.AutoSize = $true; $LblS.Location = "25,50"; $Form.Controls.Add($LblS)

# --- ADVANCED GLOW PAINTER (Hieu ung Neon Blur) ---
$GlowPaint = {
    param($sender, $e)
    $GlowColor = $Theme.GlowColor
    
    # Ve 4 lop vien mo dan de tao hieu ung Glow/Blur
    for ($i = 1; $i -le 4; $i++) {
        $Alpha = 60 - ($i * 10) # Do trong suot giam dan (50 -> 10)
        if ($Alpha -lt 0) { $Alpha = 0 }
        $PenColor = [System.Drawing.Color]::FromArgb($Alpha, $GlowColor)
        $Pen = New-Object System.Drawing.Pen($PenColor, $i * 2) # Vien day dan
        
        $Rect = $sender.ClientRectangle
        # Tinh toan padding de vien khong bi cat
        $Offset = $i 
        $Rect.X += $Offset; $Rect.Y += $Offset
        $Rect.Width -= ($Offset * 2); $Rect.Height -= ($Offset * 2)
        
        # Bo tron goc (hack nhe bang DrawRectangle)
        $e.Graphics.DrawRectangle($Pen, $Rect)
        $Pen.Dispose()
    }
    
    # Ve vien chinh sac net o trong cung
    $MainPen = New-Object System.Windows.Forms.Pen($GlowColor, 1)
    $RMain = $sender.ClientRectangle
    $RMain.Width-=1; $RMain.Height-=1
    $e.Graphics.DrawRectangle($MainPen, $RMain)
    $MainPen.Dispose()
}

# --- HELPER FUNCTIONS ---
function Add-Card ($X, $Y, $W, $H, $Title) {
    $P = New-Object System.Windows.Forms.Panel
    $P.Location="$X,$Y"; $P.Size="$W,$H"; $P.BackColor=$Theme.Card
    $P.Padding = "2,2,2,2" # Chua cho cho vien
    $P.Add_Paint($GlowPaint) # Gan hieu ung Glow
    
    $L = New-Object System.Windows.Forms.Label; $L.Text=$Title; $L.Font="Segoe UI, 11, Bold"; $L.ForeColor=$Theme.Accent; $L.Location="15,15"; $L.AutoSize=$true
    $P.Controls.Add($L)
    
    $Form.Controls.Add($P); return $P
}

function Add-Btn ($Parent, $Txt, $X, $Y, $W, $Cmd) {
    $B = New-Object System.Windows.Forms.Button; $B.Text=$Txt; $B.Location="$X,$Y"; $B.Size="$W,40"
    $B.FlatStyle="Flat"; $B.Font="Segoe UI, 9, Bold"; $B.BackColor=$Theme.BtnBack; $B.ForeColor=$Theme.Text; $B.Cursor="Hand"
    $B.FlatAppearance.BorderSize = 0
    $B.Add_Click($Cmd)
    # Hover Effect
    $B.Add_MouseEnter({ $this.BackColor=$Theme.BtnHover; $this.ForeColor="Black" })
    $B.Add_MouseLeave({ $this.BackColor=$Theme.BtnBack; $this.ForeColor=$Theme.Text })
    $Parent.Controls.Add($B)
}

# =========================================================================================
# SECTION 1: MANUAL KEY (UU TIEN HANG DAU)
# =========================================================================================
$CardKey = Add-Card 20 80 895 130 "1. NHAP KEY THU CONG (PRIORITY)"

$TxtKey = New-Object System.Windows.Forms.TextBox; $TxtKey.Location="20,50"; $TxtKey.Size="500,30"; $TxtKey.Font="Consolas, 14"; $TxtKey.BackColor="Black"; $TxtKey.ForeColor="Lime"; $TxtKey.BorderStyle="FixedSingle"
$CardKey.Controls.Add($TxtKey)

Add-Btn $CardKey "NAP KEY (INSTALL)" 540 48 150 {
    $K = $TxtKey.Text.Trim()
    if ($K.Length -lt 5) { [System.Windows.Forms.MessageBox]::Show("Nhap Key vao di ban oi!", "Loi"); return }
    Start-Process "slmgr.vbs" -ArgumentList "/ipk $K" -Wait
    Start-Process "slmgr.vbs" -ArgumentList "/ato" -Wait
    [System.Windows.Forms.MessageBox]::Show("Da nap Key xong. Kiem tra thong bao cua Windows.", "Info")
}

Add-Btn $CardKey "XOA KEY (UNINSTALL)" 710 48 160 {
    if ([System.Windows.Forms.MessageBox]::Show("Huy kich hoat & Xoa Key khoi may?", "Confirm", "YesNo") -eq "Yes") {
        Start-Process "slmgr.vbs" -ArgumentList "/upk" -Wait
        Start-Process "slmgr.vbs" -ArgumentList "/cpky" -Wait
        [System.Windows.Forms.MessageBox]::Show("Da xoa Key thanh cong!", "Info")
    }
}
$LblHint = New-Object System.Windows.Forms.Label; $LblHint.Text="* Danh cho Key Ban quyen so, Key Retail hoac MAK."; $LblHint.ForeColor="Gray"; $LblHint.Location="20,90"; $LblHint.AutoSize=$true; $CardKey.Controls.Add($LblHint)


# =========================================================================================
# SECTION 2: CONVERT EDITION (CHUYEN DOI PHIEN BAN)
# =========================================================================================
$CardConv = Add-Card 20 230 435 300 "2. CHUYEN DOI PHIEN BAN WIN (CONVERT)"

$LblConv = New-Object System.Windows.Forms.Label; $LblConv.Text="Chon phien ban muon chuyen doi sang:"; $LblConv.Location="20,50"; $LblConv.AutoSize=$true; $LblConv.ForeColor="White"; $CardConv.Controls.Add($LblConv)

$CbEditions = New-Object System.Windows.Forms.ComboBox; $CbEditions.Location="20,80"; $CbEditions.Size="390,30"; $CbEditions.Font="Segoe UI, 11"; $CbEditions.DropDownStyle="DropDownList"
$Editions = @(
    "IoT Enterprise LTSC (Recommended for ESU)", 
    "Enterprise LTSC 2021",
    "Professional", 
    "Professional Workstation", 
    "Enterprise", 
    "Education",
    "Home"
)
foreach ($E in $Editions) { $CbEditions.Items.Add($E) | Out-Null }
$CbEditions.SelectedIndex = 0
$CardConv.Controls.Add($CbEditions)

Add-Btn $CardConv "TIEN HANH CONVERT (AUTO)" 20 130 390 {
    $Target = $CbEditions.SelectedItem
    $Msg = "Ban dang muon chuyen Win hien tai sang ban: [$Target]`n`n" +
           "Luu y: De an toan nhat, Tool se mo Menu MAS -> Ban hay lam theo huong dan sau:`n" +
           "1. Cua so MAS hien len.`n" +
           "2. Bam so [6] (Extras).`n" +
           "3. Bam so [1] (Change Edition).`n" +
           "4. Chon dung phien ban ban muon."
    
    if ([System.Windows.Forms.MessageBox]::Show($Msg, "Xac nhan", "YesNo", "Information") -eq "Yes") {
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "irm https://get.activated.win | iex"
    }
}

$LblEsu = New-Object System.Windows.Forms.Label; $LblEsu.Text="MEO: De nhan ban cap nhat ESU den nam 2032`n(Win 10), hay chuyen sang ban 'IoT Enterprise LTSC'.`nSau do kich hoat bang HWID o ben phai."; $LblEsu.ForeColor="Gold"; $LblEsu.Location="20,200"; $LblEsu.AutoSize=$true; $CardConv.Controls.Add($LblEsu)


# =========================================================================================
# SECTION 3: MAS 3.9 ACTIVATION (AUTO CRACK)
# =========================================================================================
$CardMas = Add-Card 480 230 435 300 "3. MAS 3.9 - AUTO ACTIVATION & ESU"

# NÚT 1: HWID (WIN)
Add-Btn $CardMas "1. KICH HOAT WINDOWS (HWID)" 20 50 390 {
    if ([System.Windows.Forms.MessageBox]::Show("Kich hoat Ban quyen so vinh vien (HWID) cho Windows?`n(Dung cho moi loai Win tru Server/LTSC 2021)", "Confirm", "YesNo") -eq "Yes") {
        # Chay lenh HWID silent neu MAS ho tro hoac goi menu
        # MAS moi ho tro tham so /hwid
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "irm https://get.activated.win | iex"
        [System.Windows.Forms.MessageBox]::Show("Cua so MAS da mo. Bam phim [1] de kich hoat HWID.", "Huong dan")
    }
}

# NÚT 2: OHOOK (OFFICE)
Add-Btn $CardMas "2. KICH HOAT OFFICE (OHOOK)" 20 100 390 {
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "irm https://get.activated.win | iex"
    [System.Windows.Forms.MessageBox]::Show("Cua so MAS da mo. Bam phim [2] de kich hoat Office (Ohook).", "Huong dan")
}

# NÚT 3: TSFORGE (ESU / CRACK NANG CAO)
Add-Btn $CardMas "3. KICH HOAT ESU / WIN / OFFICE (TSforge)" 20 150 390 {
    $M = "TSforge la phuong phap kich hoat manh me nhat (KMS 38 / ESU).`n`n" +
         "*** QUAN TRONG: De co ESU (Update Win 10 den 2032): ***`n" +
         "1. Chuyen doi Win sang 'IoT Enterprise LTSC' (O muc ben trai).`n" +
         "2. Chon nut nay -> Cua so hien len -> Chon so [3] (TSforge).`n" +
         "3. Chon tiep de kich hoat ESU."
    
    if ([System.Windows.Forms.MessageBox]::Show($M, "Huong dan ESU", "YesNo", "Warning") -eq "Yes") {
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "irm https://get.activated.win | iex"
    }
}

Add-Btn $CardMas "KIEM TRA TRANG THAI (CHECK STATUS)" 20 230 390 { Start-Process "slmgr.vbs" -ArgumentList "/xpr" }

# --- FOOTER ---
$LblCredit = New-Object System.Windows.Forms.Label; $LblCredit.Text="Windows Activation Script (MAS) by Massgrave.dev"; $LblCredit.ForeColor="DimGray"; $LblCredit.Location="20,550"; $LblCredit.AutoSize=$true; $Form.Controls.Add($LblCredit)

$Form.ShowDialog() | Out-Null
