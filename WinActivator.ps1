# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- THEME ENGINE (NEON CYAN) ---
$Theme = @{
    Back      = [System.Drawing.Color]::FromArgb(30, 30, 30)
    Card      = [System.Drawing.Color]::FromArgb(40, 40, 43)
    Text      = [System.Drawing.Color]::FromArgb(240, 240, 240)
    BtnBack   = [System.Drawing.Color]::FromArgb(60, 60, 60)
    BtnHover  = [System.Drawing.Color]::FromArgb(0, 150, 150) # Dark Cyan Hover
    Accent    = [System.Drawing.Color]::FromArgb(0, 255, 255)     # Cyan Neon
    Border    = [System.Drawing.Color]::FromArgb(0, 255, 255)
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WINDOWS & OFFICE ACTIVATION CENTER - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(900, 600)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back
$Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "ACTIVATION & ESU MANAGER"; $LblT.Font = "Impact, 22"; $LblT.ForeColor = $Theme.Accent; $LblT.AutoSize = $true; $LblT.Location = "20,15"; $Form.Controls.Add($LblT)
$LblS = New-Object System.Windows.Forms.Label; $LblS.Text = "Powered by MAS (Microsoft Activation Scripts)"; $LblS.ForeColor = "Gray"; $LblS.AutoSize = $true; $LblS.Location = "25,55"; $Form.Controls.Add($LblS)

# --- PAINT HANDLER (VẼ VIỀN NEON) ---
$PaintHandler = {
    param($sender, $e)
    $Pen = New-Object System.Drawing.Pen($Theme.Border, 2)
    $Rect = $sender.ClientRectangle; $Rect.Width-=2; $Rect.Height-=2; $Rect.X+=1; $Rect.Y+=1
    $e.Graphics.DrawRectangle($Pen, $Rect); $Pen.Dispose()
}

# Helper Button
function Add-Btn ($Parent, $Txt, $Loc, $Size, $Cmd) {
    $B = New-Object System.Windows.Forms.Button; $B.Text=$Txt; $B.Location=$Loc; $B.Size=$Size
    $B.FlatStyle="Flat"; $B.Font="Segoe UI, 10, Bold"; $B.BackColor=$Theme.BtnBack; $B.ForeColor=$Theme.Text
    $B.Cursor="Hand"; $B.Add_Click($Cmd)
    # Hover Effect
    $B.Add_MouseEnter({ $this.BackColor=$Theme.BtnHover })
    $B.Add_MouseLeave({ $this.BackColor=$Theme.BtnBack })
    $Parent.Controls.Add($B)
}

# =========================================================================================
# SECTION 1: MANUAL KEY (NHẬP KEY THỦ CÔNG)
# =========================================================================================
$PnlKey = New-Object System.Windows.Forms.Panel; $PnlKey.Location="20,90"; $PnlKey.Size="845,130"; $PnlKey.BackColor=$Theme.Card
$PnlKey.Add_Paint($PaintHandler)
$Form.Controls.Add($PnlKey)

$LblK1 = New-Object System.Windows.Forms.Label; $LblK1.Text="1. KICH HOAT BANG KEY (THU CONG)"; $LblK1.Font="Segoe UI, 11, Bold"; $LblK1.ForeColor=$Theme.Accent; $LblK1.Location="15,15"; $LblK1.AutoSize=$true; $PnlKey.Controls.Add($LblK1)

$TxtKey = New-Object System.Windows.Forms.TextBox; $TxtKey.Location="20,50"; $TxtKey.Size="450,30"; $TxtKey.Font="Consolas, 12"; $TxtKey.Text=""
$PnlKey.Controls.Add($TxtKey)

Add-Btn $PnlKey "NAP KEY (INSTALL)" "490,48" "150,32" {
    $K = $TxtKey.Text.Trim()
    if ($K.Length -lt 5) { [System.Windows.Forms.MessageBox]::Show("Vui long nhap Key hop le!", "Loi"); return }
    Start-Process "slmgr.vbs" -ArgumentList "/ipk $K" -Wait
    Start-Process "slmgr.vbs" -ArgumentList "/ato" -Wait
    [System.Windows.Forms.MessageBox]::Show("Da gui lenh nap Key. Vui long doi thong bao tu Windows.", "Thong bao")
}

Add-Btn $PnlKey "XOA KEY (UNINSTALL)" "660,48" "160,32" {
    if ([System.Windows.Forms.MessageBox]::Show("Ban co chac muon go bo Key hien tai?", "Canh bao", "YesNo") -eq "Yes") {
        Start-Process "slmgr.vbs" -ArgumentList "/upk" -Wait
        Start-Process "slmgr.vbs" -ArgumentList "/cpky" -Wait
        [System.Windows.Forms.MessageBox]::Show("Da xoa Key khoi Registry!", "Info")
    }
}

$LblNote = New-Object System.Windows.Forms.Label; $LblNote.Text="Luu y: Chi dung cho Key chinh hang hoac Key MAK/Retail."; $LblNote.ForeColor="Gray"; $LblNote.Location="20,90"; $LblNote.AutoSize=$true; $PnlKey.Controls.Add($LblNote)


# =========================================================================================
# SECTION 2: MAS ACTIVATION & ESU (TỰ ĐỘNG)
# =========================================================================================
$PnlMas = New-Object System.Windows.Forms.Panel; $PnlMas.Location="20,240"; $PnlMas.Size="845,300"; $PnlMas.BackColor=$Theme.Card
$PnlMas.Add_Paint($PaintHandler)
$Form.Controls.Add($PnlMas)

$LblK2 = New-Object System.Windows.Forms.Label; $LblK2.Text="2. MAS 2.7 - KICH HOAT SO & WINDOWS 10 ESU (2032)"; $LblK2.Font="Segoe UI, 11, Bold"; $LblK2.ForeColor=$Theme.Accent; $LblK2.Location="15,15"; $LblK2.AutoSize=$true; $PnlMas.Controls.Add($LblK2)

# --- Cột Trái: Activation ---
$GbAct = New-Object System.Windows.Forms.GroupBox; $GbAct.Text="KICH HOAT BAN QUYEN"; $GbAct.Location="20,50"; $GbAct.Size="390,230"; $GbAct.ForeColor="White"; $PnlMas.Controls.Add($GbAct)

Add-Btn $GbAct "KICH HOAT WINDOWS (HWID)" "20,40" "350,45" {
    $Form.Cursor = "WaitCursor"
    # Chạy script im lặng (Silent Mode) để kích hoạt Win
    $Script = "irm https://get.activated.win | iex" 
    # Lưu ý: MAS menu mặc định cần tương tác. Để auto, ta gọi menu lên để người dùng chọn phím 1.
    # Hoặc dùng tham số nếu MAS hỗ trợ (hiện tại MAS ưu tiên menu).
    # Giải pháp an toàn nhất: Mở menu MAS trong cửa sổ riêng.
    Start-Process powershell -ArgumentList "-NoExit","-Command",$Script
    $Form.Cursor = "Default"
}
$LblH1 = New-Object System.Windows.Forms.Label; $LblH1.Text="> Ban quyen vinh vien (Digital License).`n> Sau khi cua so hien len, bam phim [1]."; $LblH1.ForeColor="Gray"; $LblH1.Location="25,90"; $LblH1.AutoSize=$true; $GbAct.Controls.Add($LblH1)

Add-Btn $GbAct "KICH HOAT OFFICE (OHOOK)" "20,130" "350,45" {
    $Script = "irm https://get.activated.win | iex"
    Start-Process powershell -ArgumentList "-NoExit","-Command",$Script
}
$LblH2 = New-Object System.Windows.Forms.Label; $LblH2.Text="> Kich hoat Office 2010-2024 vinh vien.`n> Sau khi cua so hien len, bam phim [2]."; $LblH2.ForeColor="Gray"; $LblH2.Location="25,180"; $LblH2.AutoSize=$true; $GbAct.Controls.Add($LblH2)


# --- Cột Phải: ESU / Update ---
$GbEsu = New-Object System.Windows.Forms.GroupBox; $GbEsu.Text="WIN 10 ESU & LTSC (MO RONG 6 NAM)"; $GbEsu.Location="430,50"; $GbEsu.Size="390,230"; $GbEsu.ForeColor="Gold"; $PnlMas.Controls.Add($GbEsu)

$LblEsuDesc = New-Object System.Windows.Forms.Label; $LblEsuDesc.Text="Chuc nang nay chuyen Win 10 Pro/Home`nsang ban IoT Enterprise LTSC 2021.`nGiup nhan Update bao mat den nam 2032."; $LblEsuDesc.Location="20,30"; $LblEsuDesc.AutoSize=$true; $LblEsuDesc.ForeColor="White"; $GbEsu.Controls.Add($LblEsuDesc)

Add-Btn $GbEsu "CONVERT WIN 10 -> IoT LTSC" "20,100" "350,50" {
    $Msg = "De kich hoat ESU (Cap nhat den 2032), ban can chuyen doi phien ban Windows.`n`n" +
           "HUONG DAN:`n" +
           "1. Cua so MAS se hien ra.`n" +
           "2. Bam phim [6] (Extras).`n" +
           "3. Bam phim [1] (Change Windows Edition).`n" +
           "4. Chon [IoT Enterprise LTSC].`n`n" +
           "Ban co muon tien hanh khong?"
           
    if ([System.Windows.Forms.MessageBox]::Show($Msg, "Huong dan ESU", "YesNo", "Information") -eq "Yes") {
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "irm https://get.activated.win | iex"
    }
}

Add-Btn $GbEsu "CHECK TRANG THAI KICH HOAT" "20,170" "350,40" {
    Start-Process "slmgr.vbs" -ArgumentList "/xpr"
}

# --- INIT ---
$Form.ShowDialog() | Out-Null
