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
    Accent    = [System.Drawing.Color]::FromArgb(0, 255, 128) # Spring Green cho WinLite
    Warn      = [System.Drawing.Color]::FromArgb(255, 160, 0)
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WINLITE UNINSTALLER PRO (V2.0)"
$Form.Size = New-Object System.Drawing.Size(950, 700)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $Theme.Back
$Form.ForeColor = $Theme.Text
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "WINLITE APP MANAGER (QUÉT SÂU REGISTRY)"; $LblT.Font = "Impact, 18"; $LblT.ForeColor = $Theme.Accent; $LblT.AutoSize = $true; $LblT.Location = "20,15"; $Form.Controls.Add($LblT)

# --- TAB CONTROL ---
$TabControl = New-Object System.Windows.Forms.TabControl; $TabControl.Location="20,60"; $TabControl.Size="895,500"; $Form.Controls.Add($TabControl)

# Helper UI
function Add-Page ($Title) { $p=New-Object System.Windows.Forms.TabPage; $p.Text=$Title; $p.BackColor=$Theme.Card; $p.ForeColor=$Theme.Text; $TabControl.Controls.Add($p); return $p }

# TAB 1: CLASSIC APPS (WIN32/EXE) - QUAN TRỌNG CHO WINLITE
$TabClassic = Add-Page "  1. CLASSIC APPS (WINLITE KHUYÊN DÙNG)  "
$LvClassic = New-Object System.Windows.Forms.ListView
$LvClassic.Location="10,10"; $LvClassic.Size="865,440"; $LvClassic.View="Details"; $LvClassic.CheckBoxes=$true; $LvClassic.GridLines=$true; $LvClassic.FullRowSelect=$true
$LvClassic.BackColor=$Theme.Back; $LvClassic.ForeColor=$Theme.Text
$LvClassic.Columns.Add("Tên Phần Mềm", 350); $LvClassic.Columns.Add("Phiên bản", 100); $LvClassic.Columns.Add("Lệnh Gỡ (Uninstall String)", 350)
$TabClassic.Controls.Add($LvClassic)

# TAB 2: MODERN APPS (STORE)
$TabModern = Add-Page "  2. MODERN APPS (STORE/APPX)  "
$LvModern = New-Object System.Windows.Forms.ListView
$LvModern.Location="10,10"; $LvModern.Size="865,440"; $LvModern.View="Details"; $LvModern.CheckBoxes=$true; $LvModern.GridLines=$true; $LvModern.FullRowSelect=$true
$LvModern.BackColor=$Theme.Back; $LvModern.ForeColor=$Theme.Text
$LvModern.Columns.Add("Tên Ứng Dụng", 350); $LvModern.Columns.Add("Package ID", 450)
$TabModern.Controls.Add($LvModern)

# --- ACTION PANEL ---
$PnlAct = New-Object System.Windows.Forms.Panel; $PnlAct.Location="20,580"; $PnlAct.Size="895,70"; $PnlAct.BackColor=$Theme.Card; $Form.Controls.Add($PnlAct)

function Add-Btn ($Txt, $X, $Col, $Cmd) {
    $B = New-Object System.Windows.Forms.Button; $B.Text=$Txt; $B.Location="$X,15"; $B.Size="160,40"; $B.FlatStyle="Flat"; $B.Font="Segoe UI, 9, Bold"
    $B.BackColor=$Col; $B.ForeColor="Black"; $B.Cursor="Hand"; $B.Add_Click($Cmd)
    $PnlAct.Controls.Add($B)
}

Add-Btn "LÀM MỚI (SCAN)" 20 "Cyan" { Load-All-Apps }
Add-Btn "CHỌN TẤT CẢ" 200 "Silver" { 
    if ($TabControl.SelectedTab -eq $TabClassic) { foreach($i in $LvClassic.Items){$i.Checked=$true} }
    else { foreach($i in $LvModern.Items){$i.Checked=$true} }
}
Add-Btn "BỎ CHỌN" 370 "Silver" { 
    if ($TabControl.SelectedTab -eq $TabClassic) { foreach($i in $LvClassic.Items){$i.Checked=$false} }
    else { foreach($i in $LvModern.Items){$i.Checked=$false} }
}

$BtnRun = New-Object System.Windows.Forms.Button; $BtnRun.Text="GỠ BỎ ĐÃ CHỌN"; $BtnRun.Location="680,15"; $BtnRun.Size="200,40"; $BtnRun.FlatStyle="Flat"; $BtnRun.Font="Segoe UI, 10, Bold"
$BtnRun.BackColor="Red"; $BtnRun.ForeColor="White"; $BtnRun.Cursor="Hand"
$PnlAct.Controls.Add($BtnRun)

# --- LOGIC FUNCTION ---

function Load-All-Apps {
    $Form.Cursor = "WaitCursor"
    
    # 1. SCAN CLASSIC APPS (REGISTRY) - Fix cho WinLite
    $LvClassic.Items.Clear()
    $RegPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    $ClassicList = @()
    foreach ($Path in $RegPaths) {
        Get-ItemProperty $Path -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -and $_.UninstallString } | ForEach-Object {
            # Lọc bớt các bản update hệ thống
            if ($_.DisplayName -notmatch "^Update for|Security Update|Hotfix") {
                $ClassicList += $_
            }
        }
    }
    
    # Sort và Add vào List
    $ClassicList | Sort-Object DisplayName -Unique | ForEach-Object {
        $Item = New-Object System.Windows.Forms.ListViewItem($_.DisplayName)
        $Item.SubItems.Add([string]$_.DisplayVersion)
        $Item.SubItems.Add($_.UninstallString)
        $Item.Tag = $_.UninstallString # Lưu lệnh gỡ
        $LvClassic.Items.Add($Item)
    }

    # 2. SCAN MODERN APPS (APPX)
    $LvModern.Items.Clear()
    try {
        $Apps = Get-AppxPackage -ErrorAction Stop | Where-Object { $_.NonRemovable -eq $false } | Sort-Object Name
        foreach ($App in $Apps) {
            $Item = New-Object System.Windows.Forms.ListViewItem($App.Name)
            $Item.SubItems.Add($App.PackageFullName)
            $Item.Tag = $App.PackageFullName
            $LvModern.Items.Add($Item)
        }
    } catch {
        $Item = New-Object System.Windows.Forms.ListViewItem("KHÔNG HỖ TRỢ (WINLITE)")
        $Item.ForeColor = "Red"
        $LvModern.Items.Add($Item)
    }

    $Form.Cursor = "Default"
    $TabControl.Text = "Đã quét xong!"
}

# --- UNINSTALL LOGIC ---
$BtnRun.Add_Click({
    if ($TabControl.SelectedTab -eq $TabClassic) {
        # GỠ CLASSIC APP
        $Checked = $LvClassic.CheckedItems
        if ($Checked.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn phần mềm!", "Lỗi"); return }
        
        foreach ($Item in $Checked) {
            $CmdString = $Item.Tag
            $AppName = $Item.Text
            
            # Xử lý lệnh gỡ (MsiExec hoặc Uninstall.exe)
            if ($CmdString -match "MsiExec.exe") {
                # Tự động thêm /quiet nếu là MSI (Cẩn thận)
                # $CmdString = $CmdString -replace "/I", "/X" + " /quiet /norestart"
                Start-Process cmd -ArgumentList "/c $CmdString" -Wait
            } else {
                # Nếu lệnh có dấu ngoặc kép, tách ra chạy
                try {
                    $Proc = Start-Process cmd -ArgumentList "/c `"$CmdString`"" -PassThru
                } catch {
                    [System.Windows.Forms.MessageBox]::Show("Không thể khởi chạy trình gỡ cài đặt của: $AppName", "Lỗi")
                }
            }
            # Bỏ tick sau khi chạy
            $Item.Checked = $false
            $Item.ForeColor = "Gray"
        }
        [System.Windows.Forms.MessageBox]::Show("Đã gọi trình gỡ cài đặt. Vui lòng làm theo hướng dẫn trên màn hình (nếu có).", "Hoàn tất")
    }
    else {
        # GỠ MODERN APP
        $Checked = $LvModern.CheckedItems
        if ($Checked.Count -eq 0) { return }
        if ($Checked[0].Text -eq "KHÔNG HỖ TRỢ (WINLITE)") { return }

        if ([System.Windows.Forms.MessageBox]::Show("Gỡ bỏ $($Checked.Count) ứng dụng Modern?", "Xác nhận", "YesNo") -eq "Yes") {
            $Form.Cursor = "WaitCursor"
            foreach ($Item in $Checked) {
                try {
                    Remove-AppxPackage -Package $Item.Tag -ErrorAction Stop
                    $LvModern.Items.Remove($Item)
                } catch {}
            }
            $Form.Cursor = "Default"
            [System.Windows.Forms.MessageBox]::Show("Đã gỡ xong!", "Hoàn tất")
        }
    }
})

$Form.Add_Shown({ Load-All-Apps })
$Form.ShowDialog() | Out-Null
