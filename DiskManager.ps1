<#
    DISK MANAGER PRO - PHAT TAN PC (V12.0 DEBUG MODE)
    Feature: Full Logging, Error Trapping, Cyberpunk UI
    Fix: Admin Check for 'iex' execution
#>

# --- 0. DEBUG LOGGER ---
function Log-Info ($Msg) { Write-Host "[INFO] $Msg" -ForegroundColor Cyan }
function Log-Err  ($Msg) { Write-Host "[ERROR] $Msg" -ForegroundColor Red }
function Log-Warn ($Msg) { Write-Host "[WARN] $Msg" -ForegroundColor Yellow }

Clear-Host
Log-Info "Dang khoi dong Disk Manager V12.0..."

# --- 1. ADMIN CHECK (ENHANCED) ---
try {
    $IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (!$IsAdmin) {
        Log-Warn "Phat hien chua chay duoi quyen Administrator."
        if ($PSCommandPath) {
            Log-Info "Dang khoi dong lai voi quyen Admin..."
            Start-Process powershell "-NoP -File `"$PSCommandPath`"" -Verb RunAs
            Exit
        } else {
            # Trường hợp chạy qua IEX (không có file path)
            Log-Err "BAN DANG CHAY QUA MANG (IEX)."
            Log-Err "VUI LONG TAT CUA SO NAY, CHUOT PHAI VAO POWERSHELL -> RUN AS ADMINISTRATOR!"
            Read-Host "Bam Enter de thoat..."
            Exit
        }
    }
    Log-Info "Quyen Admin: OK"
} catch {
    Log-Err "Loi khi kiem tra Admin: $($_.Exception.Message)"
}

# --- 2. LOAD LIBRARIES ---
try {
    Log-Info "Dang tai thu vien do hoa (Windows Forms)..."
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    Log-Info "Tai thu vien: OK"
} catch {
    Log-Err "Khong the tai thu vien GUI. May ban co the thieu .NET Framework."
    Read-Host "Bam Enter de thoat..."
    Exit
}

$ErrorActionPreference = "SilentlyContinue"

# --- THEME CONFIG ---
$Themes = @{
    Dark = @{
        FormBg    = [System.Drawing.Color]::FromArgb(18, 18, 24)
        PanelBg   = [System.Drawing.Color]::FromArgb(30, 30, 35)
        TextMain  = [System.Drawing.Color]::White
        TextDim   = [System.Drawing.Color]::Silver
        Accent    = [System.Drawing.Color]::FromArgb(0, 255, 200)
        Grad1     = [System.Drawing.Color]::FromArgb(30, 30, 40)
        Grad2     = [System.Drawing.Color]::FromArgb(15, 15, 20)
        BtnText   = [System.Drawing.Color]::White
        GridBg    = [System.Drawing.Color]::FromArgb(25, 25, 28)
        GridText  = [System.Drawing.Color]::White
    }
    Light = @{
        FormBg    = [System.Drawing.Color]::WhiteSmoke
        PanelBg   = [System.Drawing.Color]::White
        TextMain  = [System.Drawing.Color]::Black
        TextDim   = [System.Drawing.Color]::DimGray
        Accent    = [System.Drawing.Color]::FromArgb(0, 120, 215)
        Grad1     = [System.Drawing.Color]::White
        Grad2     = [System.Drawing.Color]::FromArgb(230, 230, 240)
        BtnText   = [System.Drawing.Color]::Black
        GridBg    = [System.Drawing.Color]::White
        GridText  = [System.Drawing.Color]::Black
    }
}

$Global:IsDark = $true
$Global:SelectedDisk = $null
$Global:SelectedPart = $null

# --- GUI SETUP ---
Log-Info "Dang dung giao dien (GUI)..."
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "DISK MANAGER PRO V12.0 - DEBUG EDITION"
$Form.Size = New-Object System.Drawing.Size(1200, 800)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# -- FONTS --
$F_Logo = New-Object System.Drawing.Font("Impact", 20)
$F_Bold = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$F_Norm = New-Object System.Drawing.Font("Segoe UI", 9)

# ==================== CUSTOM PAINTING HELPER ====================
function Get-Theme { 
    if ($Global:IsDark) { return $Themes.Dark } else { return $Themes.Light } 
}

$PaintGrad = {
    param($s, $e)
    $T = Get-Theme
    $Br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($s.ClientRectangle, $T.Grad1, $T.Grad2, 90)
    $e.Graphics.FillRectangle($Br, $s.ClientRectangle)
    $Pen = New-Object System.Drawing.Pen($T.Accent, 1)
    $e.Graphics.DrawRectangle($Pen, 0, 0, $s.Width-1, $s.Height-1)
    $Br.Dispose(); $Pen.Dispose()
}

# --- HEADER ---
$PnlHead = New-Object System.Windows.Forms.Panel; $PnlHead.Dock="Top"; $PnlHead.Height=60; $PnlHead.BackColor=[System.Drawing.Color]::Transparent
$Form.Controls.Add($PnlHead)

$LblLogo = New-Object System.Windows.Forms.Label
$LblLogo.Text = "CYBER DISK MANAGER"; $LblLogo.Font = $F_Logo; $LblLogo.AutoSize=$true; $LblLogo.Location="15,10"
$PnlHead.Controls.Add($LblLogo)

$BtnMode = New-Object System.Windows.Forms.Button
$BtnMode.Text = "☯ ĐỔI MÀU"; $BtnMode.Size="120,35"; $BtnMode.Location="1050,12"; $BtnMode.FlatStyle="Flat"
$BtnMode.Cursor="Hand"; $BtnMode.Add_Click({ Switch-Theme })
$PnlHead.Controls.Add($BtnMode)

# --- LAYOUT PANELS ---
$PnlDisk = New-Object System.Windows.Forms.Panel; $PnlDisk.Location="15,70"; $PnlDisk.Size="1155,200"; $PnlDisk.Add_Paint($PaintGrad)
$Form.Controls.Add($PnlDisk)

$PnlPart = New-Object System.Windows.Forms.Panel; $PnlPart.Location="15,285"; $PnlPart.Size="1155,200"; $PnlPart.Add_Paint($PaintGrad)
$Form.Controls.Add($PnlPart)

$PnlTool = New-Object System.Windows.Forms.Panel; $PnlTool.Location="15,500"; $PnlTool.Size="1155,240"; $PnlTool.Add_Paint($PaintGrad)
$Form.Controls.Add($PnlTool)

# --- GRIDS ---
function Make-Grid ($Parent, $Cols) {
    $G = New-Object System.Windows.Forms.DataGridView
    $G.Location="10,30"; $G.Size="$($Parent.Width-20),$($Parent.Height-40)"; $G.BorderStyle="None"
    $G.AllowUserToAddRows=$false; $G.RowHeadersVisible=$false; $G.SelectionMode="FullRowSelect"
    $G.MultiSelect=$false; $G.ReadOnly=$true; $G.AutoSizeColumnsMode="Fill"; $G.EnableHeadersVisualStyles=$false
    foreach ($C in $Cols) { $G.Columns.Add($C[0], $C[1]) | Out-Null; $G.Columns[$G.Columns.Count-1].Width=$C[2] }
    $Parent.Controls.Add($G); return $G
}

$LblD = New-Object System.Windows.Forms.Label; $LblD.Text="1. DANH SÁCH Ổ CỨNG VẬT LÝ"; $LblD.Location="10,8"; $LblD.AutoSize=$true; $PnlDisk.Controls.Add($LblD)
$GridD = Make-Grid $PnlDisk @(@("ID","Disk #",50), @("Mod","Tên Ổ Cứng",200), @("Size","Dung Lượng",100), @("Type","Loại",80), @("Stat","Trạng Thái",100))

$LblP = New-Object System.Windows.Forms.Label; $LblP.Text="2. CHI TIẾT PHÂN VÙNG"; $LblP.Location="10,8"; $LblP.AutoSize=$true; $PnlPart.Controls.Add($LblP)
$GridP = Make-Grid $PnlPart @(@("Let","Ký Tự",60), @("Lab","Tên Ổ (Label)",150), @("FS","Định Dạng",80), @("Tot","Tổng",80), @("Fre","Còn Lại",80), @("Sta","Trạng Thái",100))

# --- CUSTOM ACTION BUTTONS ---
function Add-Btn ($Txt, $Icon, $X, $Y, $Tag, $IsDanger=$false) {
    $B = New-Object System.Windows.Forms.Button; $B.Text="$Icon  $Txt"; $B.Tag=$Tag
    $B.Location="$X,$Y"; $B.Size="210,45"; $B.FlatStyle="Flat"; $B.FlatAppearance.BorderSize=0
    $B.Font=$F_Bold; $B.TextAlign="MiddleLeft"; $B.Cursor="Hand"
    
    $P = New-Object System.Windows.Forms.Panel; $P.Width=5; $P.Dock="Left"; $B.Controls.Add($P)
    
    # Store Danger flag for painting
    $B.Tag = @{Action=$Tag; Danger=$IsDanger}
    
    $B.Add_Click({ Show-Dialog $this.Tag.Action })
    $PnlTool.Controls.Add($B); return $B
}

$L1=New-Object System.Windows.Forms.Label; $L1.Text="CÔNG CỤ CƠ BẢN"; $L1.Location="20,20"; $L1.AutoSize=$true; $PnlTool.Controls.Add($L1)
Add-Btn "Làm Mới (Refresh)" "♻️" 20 50 "Refresh"
Add-Btn "Đổi Tên (Label)" "🏷️" 20 105 "Label"
Add-Btn "Đổi Ký Tự (Letter)" "🔠" 20 160 "Letter"

$L2=New-Object System.Windows.Forms.Label; $L2.Text="HỆ THỐNG & BOOT"; $L2.Location="250,20"; $L2.AutoSize=$true; $PnlTool.Controls.Add($L2)
Add-Btn "Set Active (Boot)" "⚡" 250 50 "Active"
Add-Btn "Nạp Boot (BCD)" "🛠️" 250 105 "FixBoot"
Add-Btn "Convert GPT/MBR" "🔄" 250 160 "Convert"

$L3=New-Object System.Windows.Forms.Label; $L3.Text="SỬA LỖI & QUẢN LÝ"; $L3.Location="480,20"; $L3.AutoSize=$true; $PnlTool.Controls.Add($L3)
Add-Btn "Check Disk (Sửa Lỗi)" "🚑" 480 50 "ChkDsk"
Add-Btn "Thông Tin Chi Tiết" "ℹ️" 480 105 "Info"

$L4=New-Object System.Windows.Forms.Label; $L4.Text="VÙNG NGUY HIỂM"; $L4.Location="750,20"; $L4.AutoSize=$true; $L4.ForeColor=[System.Drawing.Color]::Red; $PnlTool.Controls.Add($L4)
Add-Btn "Format (Định Dạng)" "🧹" 750 50 "Format" $true
Add-Btn "Xóa Phân Vùng" "❌" 750 105 "Delete" $true

# ==================== THEME LOGIC ====================
function Switch-Theme {
    $Global:IsDark = -not $Global:IsDark
    $T = Get-Theme
    
    $Form.BackColor = $T.FormBg; $Form.ForeColor = $T.TextMain
    $BtnMode.BackColor = $T.PanelBg; $BtnMode.ForeColor = $T.TextMain
    $BtnMode.Text = if ($Global:IsDark) { "☀ LIGHT" } else { "🌙 DARK" }
    $LblLogo.ForeColor = $T.Accent
    
    foreach ($P in @($PnlDisk, $PnlPart, $PnlTool)) { $P.Invalidate() }
    
    # Update Labels
    foreach ($L in @($LblD, $LblP, $L1, $L2, $L3)) { $L.ForeColor = $T.TextDim }
    
    # Update Grids
    foreach ($G in @($GridD, $GridP)) {
        $G.BackgroundColor = $T.GridBg; $G.GridColor = $T.Accent
        $G.DefaultCellStyle.BackColor = $T.GridBg; $G.DefaultCellStyle.ForeColor = $T.GridText
        $G.ColumnHeadersDefaultCellStyle.BackColor = $T.PanelBg; $G.ColumnHeadersDefaultCellStyle.ForeColor = $T.TextMain
    }
    
    # Update Buttons
    foreach ($C in $PnlTool.Controls) {
        if ($C -is [System.Windows.Forms.Button]) {
            $C.BackColor = $T.PanelBg; $C.ForeColor = $T.BtnText
            $ColorBar = if($C.Tag.Danger){[System.Drawing.Color]::Crimson}else{$T.Accent}
            $C.Controls[0].BackColor = $ColorBar
        }
    }
}

# ==================== DIALOG SYSTEM ====================
function Create-SubForm ($Title, $H) {
    $T = Get-Theme
    $F = New-Object System.Windows.Forms.Form
    $F.Text = $Title; $F.Size = New-Object System.Drawing.Size(450, $H)
    $F.StartPosition = "CenterParent"; $F.FormBorderStyle = "FixedToolWindow"
    $F.BackColor = $T.FormBg; $F.ForeColor = $T.TextMain
    return $F
}

function Show-Dialog ($Action) {
    Log-Info "User click Action: $Action"
    if ($Action -eq "Refresh") { Load-Data; return }
    if ($Action -eq "FixBoot") { Start-Process "cmd" "/c bcdboot C:\Windows /s C: /f ALL & pause"; return }
    
    $P = $Global:SelectedPart
    if (!$P) { [System.Windows.Forms.MessageBox]::Show("Bạn chưa chọn phân vùng ở bảng dưới!", "Lỗi"); return }
    
    $Did = $P.Did; $Pid = $P.Pid; $Let = $P.Let; $Lab = $P.Lab
    
    # --- SUB-GUI: FORMAT ---
    if ($Action -eq "Format") {
        $F = Create-SubForm "ĐỊNH DẠNG Ổ ĐĨA ($Let)" 280
        
        $L1 = New-Object System.Windows.Forms.Label; $L1.Text="Tên ổ đĩa (Label):"; $L1.Location="20,20"; $L1.AutoSize=$true; $F.Controls.Add($L1)
        $TxtLab = New-Object System.Windows.Forms.TextBox; $TxtLab.Text=$Lab; $TxtLab.Location="20,45"; $TxtLab.Size="380,25"; $F.Controls.Add($TxtLab)
        
        $L2 = New-Object System.Windows.Forms.Label; $L2.Text="Hệ thống tệp (File System):"; $L2.Location="20,80"; $L2.AutoSize=$true; $F.Controls.Add($L2)
        $CbFs = New-Object System.Windows.Forms.ComboBox; $CbFs.Location="20,105"; $CbFs.Size="380,25"; $CbFs.DropDownStyle="DropDownList"
        $CbFs.Items.AddRange(@("NTFS", "FAT32", "EXFAT")); $CbFs.SelectedIndex=0; $F.Controls.Add($CbFs)
        
        $BtnOk = New-Object System.Windows.Forms.Button; $BtnOk.Text="TIẾN HÀNH FORMAT"; $BtnOk.Location="20,160"; $BtnOk.Size="380,45"; $BtnOk.BackColor=[System.Drawing.Color]::Crimson; $BtnOk.ForeColor="White"; $BtnOk.FlatStyle="Flat"
        $BtnOk.DialogResult = "OK"; $F.Controls.Add($BtnOk)
        
        if ($F.ShowDialog() -eq "OK") {
            Run-DP "sel disk $Did`nsel part $Pid`nformat fs=$($CbFs.SelectedItem) label=`"$($TxtLab.Text)`" quick"
        }
    }
    
    # --- SUB-GUI: LABEL ---
    if ($Action -eq "Label") {
        $F = Create-SubForm "ĐỔI TÊN Ổ ĐĨA" 180
        $L = New-Object System.Windows.Forms.Label; $L.Text="Nhập tên mới cho ổ $Let :"; $L.Location="20,20"; $L.AutoSize=$true; $F.Controls.Add($L)
        $Txt = New-Object System.Windows.Forms.TextBox; $Txt.Text=$Lab; $Txt.Location="20,50"; $Txt.Size="380,25"; $F.Controls.Add($Txt)
        $Btn = New-Object System.Windows.Forms.Button; $Btn.Text="XÁC NHẬN"; $Btn.Location="250,90"; $Btn.Size="150,35"; $Btn.BackColor=[System.Drawing.Color]::Orange; $Btn.DialogResult="OK"; $F.Controls.Add($Btn)
        
        if ($F.ShowDialog() -eq "OK") {
            if ($Let) { cmd /c "label $Let $($Txt.Text)"; Load-Data } else { [System.Windows.Forms.MessageBox]::Show("Ổ cần ký tự để đổi tên.","Lỗi") }
        }
    }
    
    # --- SUB-GUI: LETTER ---
    if ($Action -eq "Letter") {
        $F = Create-SubForm "ĐỔI KÝ TỰ Ổ ĐĨA" 180
        $L = New-Object System.Windows.Forms.Label; $L.Text="Chọn ký tự mới cho Partition $Pid:"; $L.Location="20,20"; $L.AutoSize=$true; $F.Controls.Add($L)
        $Cb = New-Object System.Windows.Forms.ComboBox; $Cb.Location="20,50"; $Cb.Size="380,25"; $Cb.DropDownStyle="DropDownList"
        # Logic tìm ký tự trống
        $Used = [IO.DriveInfo]::GetDrives().Name | ForEach { $_.Substring(0,1) }
        65..90 | ForEach { $C=[char]$_; if ($Used -notcontains $C) { $Cb.Items.Add($C) | Out-Null } }
        if($Cb.Items.Count -gt 0){$Cb.SelectedIndex=0}; $F.Controls.Add($Cb)
        
        $Btn = New-Object System.Windows.Forms.Button; $Btn.Text="THAY ĐỔI"; $Btn.Location="250,90"; $Btn.Size="150,35"; $Btn.BackColor=[System.Drawing.Color]::Teal; $Btn.DialogResult="OK"; $F.Controls.Add($Btn)
        
        if ($F.ShowDialog() -eq "OK") {
            Run-DP "sel disk $Did`nsel part $Pid`nassign letter=$($Cb.SelectedItem)"
        }
    }
    
    # --- SIMPLE CONFIRMS ---
    if ($Action -eq "Delete") {
        if ([System.Windows.Forms.MessageBox]::Show("XÓA PHÂN VÙNG $Pid TRÊN DISK $Did?`n`nMẤT DỮ LIỆU VĨNH VIỄN!", "CẢNH BÁO", "YesNo", "Error") -eq "Yes") {
            Run-DP "sel disk $Did`nsel part $Pid`ndelete partition override"
        }
    }
    
    if ($Action -eq "Active") { Run-DP "sel disk $Did`nsel part $Pid`nactive" }
    
    if ($Action -eq "Convert") {
        if ([System.Windows.Forms.MessageBox]::Show("Chuyển đổi Disk $Did sang GPT/MBR?`n(Yêu cầu Disk phải trống/Clean)", "Xác nhận", "YesNo", "Question") -eq "Yes") {
            Run-DP "sel disk $Did`nclean`nconvert gpt" 
        }
    }
    
    if ($Action -eq "ChkDsk") {
        if ($Let) { Start-Process "cmd" "/k chkdsk $Let /f /x" } else { [System.Windows.Forms.MessageBox]::Show("Phân vùng không có ký tự ổ!", "Lỗi") }
    }
}

# ==================== CORE ENGINE (WMI + LOGGING) ====================
function Load-Data {
    Log-Info "Dang tai danh sach o cung..."
    $GridD.Rows.Clear(); $GridP.Rows.Clear(); $Global:SelectedPart = $null
    $Form.Cursor = "WaitCursor"; $Form.Refresh()
    
    try {
        $Disks = @(Get-WmiObject Win32_DiskDrive)
        Log-Info "Tim thay $($Disks.Count) o cung vat ly."
        foreach ($D in $Disks) {
            # LOAD DISK
            $GB = [Math]::Round($D.Size / 1GB, 1).ToString() + " GB"
            $RowD = $GridD.Rows.Add($D.Index, $D.Model, $GB, "MBR/GPT", $D.Status)
            $GridD.Rows[$RowD].Tag = $D
        }
    } catch {
        Log-Err "Loi WMI Load Disk: $($_.Exception.Message)"
    }
    
    if ($GridD.Rows.Count -gt 0) { 
        $GridD.Rows[0].Selected=$true
        Load-Partitions $GridD.Rows[0].Tag 
    }
    $Form.Cursor = "Default"
    Log-Info "Hoan tat tai du lieu."
}

function Load-Partitions ($DiskObj) {
    Log-Info "Dang doc phan vung cho Disk $($DiskObj.Index)..."
    $GridP.Rows.Clear(); $Global:SelectedDisk = $DiskObj
    
    try {
        $Query = "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($DiskObj.DeviceID)'} WHERE AssocClass=Win32_DiskDriveToDiskPartition"
        $Parts = @(Get-WmiObject -Query $Query | Sort-Object StartingOffset)
        
        Log-Info "Tim thay $($Parts.Count) phan vung."
        $RealID = 1 # Diskpart ID starts at 1
        foreach ($P in $Parts) {
            $LogDisk = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($P.DeviceID)'} WHERE AssocClass=Win32_LogicalDiskToPartition"
            $Total = [Math]::Round($P.Size / 1GB, 2)
            
            if ($LogDisk) {
                $Let = $LogDisk.DeviceID; $Lab = $LogDisk.VolumeName; $FS = $LogDisk.FileSystem
                $Free = [Math]::Round($LogDisk.FreeSpace / 1GB, 2)
                $Row = $GridP.Rows.Add($Let, $Lab, $FS, "$Total GB", "$Free GB", "OK")
            } else {
                $Let=$null; $Lab="[Hidden]"; $FS="RAW"
                $Row = $GridP.Rows.Add("", "[Hidden/System]", "RAW", "$Total GB", "-", $P.Type)
            }
            
            # Save ID for Diskpart
            $GridP.Rows[$Row].Tag = @{ Did=$DiskObj.Index; Pid=$RealID; Let=$Let; Lab=$Lab }
            $RealID++ 
        }
    } catch { Log-Err "Loi Load Partitions: $($_.Exception.Message)" }
}

# --- EVENTS & RUNNER ---
$GridD.Add_SelectionChanged({ if($GridD.SelectedRows.Count -gt 0){ Load-Partitions $GridD.SelectedRows[0].Tag } })
$GridP.Add_SelectionChanged({ if($GridP.SelectedRows.Count -gt 0){ $Global:SelectedPart = $GridP.SelectedRows[0].Tag } })

function Run-DP ($Cmd) {
    Log-Info "Dang chay lenh Diskpart: $Cmd"
    $F = "$env:TEMP\dp.txt"; [IO.File]::WriteAllText($F, $Cmd)
    Start-Process "diskpart" "/s `"$F`"" -Wait -NoNewWindow
    Remove-Item $F; Load-Data
}

# --- INIT ---
Log-Info "Khoi tao giao dien..."
Switch-Theme # Load màu lần đầu
$Timer = New-Object System.Windows.Forms.Timer; $Timer.Interval=500; $Timer.Add_Tick({$Timer.Stop(); Load-Data}); $Timer.Start()
Log-Info "Hien thi Form..."
$Form.ShowDialog() | Out-Null
