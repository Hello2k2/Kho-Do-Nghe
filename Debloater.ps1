# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"

# --- THEME ENGINE ---
$Theme = @{
    Back      = [System.Drawing.Color]::FromArgb(20, 20, 25)
    Card      = [System.Drawing.Color]::FromArgb(35, 35, 40)
    Text      = [System.Drawing.Color]::FromArgb(240, 240, 240)
    BtnBack   = [System.Drawing.Color]::FromArgb(50, 50, 60)
    BtnHover  = [System.Drawing.Color]::FromArgb(255, 0, 80) # Red Neon cho viec xoa
    Accent    = [System.Drawing.Color]::FromArgb(255, 0, 80)
    Border    = [System.Drawing.Color]::FromArgb(255, 0, 80)
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WINDOWS DEBLOATER PRO (V1.0)"
$Form.Size = New-Object System.Drawing.Size(900, 650)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back
$Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "SYSTEM DEBLOATER (GỠ APP RÁC)"; $LblT.Font = "Impact, 20"; $LblT.ForeColor = $Theme.Accent; $LblT.AutoSize = $true; $LblT.Location = "20,15"; $Form.Controls.Add($LblT)

# --- PAINT HANDLER ---
$GlowPaint = {
    param($sender, $e)
    $Pen = New-Object System.Drawing.Pen($Theme.Accent, 2)
    $Rect = $sender.ClientRectangle; $Rect.Width-=2; $Rect.Height-=2; $Rect.X+=1; $Rect.Y+=1
    $e.Graphics.DrawRectangle($Pen, $Rect); $Pen.Dispose()
}

# --- TAB CONTROL ---
$TabControl = New-Object System.Windows.Forms.TabControl; $TabControl.Location="20,70"; $TabControl.Size="845,450"; $Form.Controls.Add($TabControl)

# Helper UI
function Add-Page ($Title) { $p=New-Object System.Windows.Forms.TabPage; $p.Text=$Title; $p.BackColor=$Theme.Card; $p.ForeColor=$Theme.Text; $TabControl.Controls.Add($p); return $p }

# ==========================================
# TAB 1: SAFE DEBLOAT (APP RÁC THÔNG THƯỜNG)
# ==========================================
$TabSafe = Add-Page "  1. SAFE LIST (KHUYÊN DÙNG)  "

$LvSafe = New-Object System.Windows.Forms.ListView
$LvSafe.Location="15,15"; $LvSafe.Size="805,380"; $LvSafe.View="Details"; $LvSafe.CheckBoxes=$true; $LvSafe.GridLines=$true; $LvSafe.FullRowSelect=$true
$LvSafe.BackColor=$Theme.Back; $LvSafe.ForeColor=$Theme.Text
$LvSafe.Columns.Add("Tên Ứng Dụng", 350); $LvSafe.Columns.Add("Package Name (ID)", 400)
$TabSafe.Controls.Add($LvSafe)

# ==========================================
# TAB 2: ADVANCED (TẤT CẢ APP)
# ==========================================
$TabAdv = Add-Page "  2. ADVANCED (TẤT CẢ APP)  "

$LvAdv = New-Object System.Windows.Forms.ListView
$LvAdv.Location="15,15"; $LvAdv.Size="805,380"; $LvAdv.View="Details"; $LvAdv.CheckBoxes=$true; $LvAdv.GridLines=$true; $LvAdv.FullRowSelect=$true
$LvAdv.BackColor=$Theme.Back; $LvAdv.ForeColor=$Theme.Text
$LvAdv.Columns.Add("Tên Ứng Dụng", 350); $LvAdv.Columns.Add("Package Name (ID)", 400)
$TabAdv.Controls.Add($LvAdv)

# --- ACTION BUTTONS ---
$PnlAct = New-Object System.Windows.Forms.Panel; $PnlAct.Location="20,530"; $PnlAct.Size="845,70"; $PnlAct.BackColor=$Theme.Card; $PnlAct.Add_Paint($GlowPaint); $Form.Controls.Add($PnlAct)

function Add-Btn ($Txt, $X, $Col, $Cmd) {
    $B = New-Object System.Windows.Forms.Button; $B.Text=$Txt; $B.Location="$X,15"; $B.Size="180,40"; $B.FlatStyle="Flat"; $B.Font="Segoe UI, 9, Bold"
    $B.BackColor=$Col; $B.ForeColor="White"; $B.Cursor="Hand"; $B.Add_Click($Cmd)
    $PnlAct.Controls.Add($B)
}

Add-Btn "QUÉT APP (SCAN)" 20 "DimGray" { Load-Apps }
Add-Btn "CHỌN TẤT CẢ" 220 "DimGray" { 
    if ($TabControl.SelectedTab -eq $TabSafe) { foreach($i in $LvSafe.Items){$i.Checked=$true} }
    else { foreach($i in $LvAdv.Items){$i.Checked=$true} }
}
Add-Btn "BỎ CHỌN" 420 "DimGray" { 
    if ($TabControl.SelectedTab -eq $TabSafe) { foreach($i in $LvSafe.Items){$i.Checked=$false} }
    else { foreach($i in $LvAdv.Items){$i.Checked=$false} }
}

$BtnRemove = New-Object System.Windows.Forms.Button; $BtnRemove.Text="GỠ BỎ (REMOVE)"; $BtnRemove.Location="630,15"; $BtnRemove.Size="200,40"; $BtnRemove.FlatStyle="Flat"; $BtnRemove.Font="Segoe UI, 10, Bold"
$BtnRemove.BackColor="Red"; $BtnRemove.ForeColor="White"; $BtnRemove.Cursor="Hand"
$PnlAct.Controls.Add($BtnRemove)

# --- LOGIC ---
# Danh sách Bloatware an toàn để xóa
$BloatList = @(
    "Microsoft.3DBuilder", "Microsoft.BingWeather", "Microsoft.GetHelp", "Microsoft.Getstarted", "Microsoft.Messaging", 
    "Microsoft.Microsoft3DViewer", "Microsoft.MicrosoftOfficeHub", "Microsoft.MicrosoftSolitaireCollection", "Microsoft.MixedReality.Portal",
    "Microsoft.OneConnect", "Microsoft.People", "Microsoft.SkypeApp", "Microsoft.Wallet", "Microsoft.WindowsAlarms", 
    "Microsoft.WindowsFeedbackHub", "Microsoft.WindowsMaps", "Microsoft.WindowsSoundRecorder", "Microsoft.Xbox.TCUI", 
    "Microsoft.XboxApp", "Microsoft.XboxGameOverlay", "Microsoft.XboxGamingOverlay", "Microsoft.XboxIdentityProvider", 
    "Microsoft.XboxSpeechToTextOverlay", "Microsoft.YourPhone", "Microsoft.ZuneMusic", "Microsoft.ZuneVideo",
    "Disney", "Spotify", "Netflix", "TikTok", "Instagram", "Facebook", "Twitter", "CandyCrush"
)

function Load-Apps {
    $Form.Cursor = "WaitCursor"
    $LvSafe.Items.Clear(); $LvAdv.Items.Clear()
    
    # Lấy danh sách App (Non-System)
    $Apps = Get-AppxPackage | Where-Object { $_.NonRemovable -eq $false -and $_.SignatureKind -eq "Store" } | Sort-Object Name
    
    foreach ($App in $Apps) {
        $Item = New-Object System.Windows.Forms.ListViewItem($App.Name)
        $Item.SubItems.Add($App.PackageFullName)
        $Item.Tag = $App.PackageFullName # Lưu ID để xóa
        
        # Phân loại vào Tab Safe hoặc Adv
        $IsBloat = $false
        foreach ($B in $BloatList) { if ($App.Name -match $B) { $IsBloat = $true; break } }
        
        if ($IsBloat) { 
            $LvSafe.Items.Add($Item) 
            # Copy sang Adv luôn để dễ quản lý
            $ItemClone = $Item.Clone(); $LvAdv.Items.Add($ItemClone)
        } else {
            $LvAdv.Items.Add($Item)
        }
    }
    $Form.Cursor = "Default"
    [System.Windows.Forms.MessageBox]::Show("Đã quét xong danh sách ứng dụng!", "Thông báo")
}

$BtnRemove.Add_Click({
    # Xác định Tab đang mở
    $TargetLv = if ($TabControl.SelectedTab -eq $TabSafe) { $LvSafe } else { $LvAdv }
    
    # Lấy danh sách đã check
    $CheckedItems = $TargetLv.CheckedItems
    if ($CheckedItems.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Vui lòng chọn ít nhất 1 App!", "Lỗi"); return }
    
    if ([System.Windows.Forms.MessageBox]::Show("Bạn có chắc muốn GỠ BỎ $($CheckedItems.Count) ứng dụng đã chọn?`n`nHành động này không thể hoàn tác!", "Cảnh báo", "YesNo", "Warning") -eq "Yes") {
        $Form.Cursor = "WaitCursor"
        $Count = 0
        foreach ($Item in $CheckedItems) {
            $PkgName = $Item.Tag
            try {
                Remove-AppxPackage -Package $PkgName -ErrorAction Stop
                $Count++
            } catch {}
        }
        Load-Apps # Refresh lại list
        $Form.Cursor = "Default"
        [System.Windows.Forms.MessageBox]::Show("Đã gỡ bỏ thành công $Count ứng dụng!", "Hoàn tất")
    }
})

$Form.Add_Shown({ Load-Apps })
$Form.ShowDialog() | Out-Null
