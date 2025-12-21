# =============================================================================
# ANTI-EFS TOOL - GUI NEON EDITION (THE REVENGE OF 200K)
# Author: PHATTANPC
# Tech: PowerShell WinForms + Cyberpunk UI
# =============================================================================

# 1. YÊU CẦU QUYỀN ADMIN (BẮT BUỘC)
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "powershell.exe"
    $processInfo.Arguments = "-File `"$PSCommandPath`""
    $processInfo.Verb = "runas"
    [System.Diagnostics.Process]::Start($processInfo)
    Exit
}

# 2. LOAD ASSEMBLIES
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 3. CẤU HÌNH GIAO DIỆN (THEME CONFIG)
$Script:IsDarkMode = $true

# Màu sắc NEON (Dark Mode)
$Color_Dark_Bg = [System.Drawing.Color]::FromArgb(20, 20, 20)      # Đen sâu
$Color_Dark_Card = [System.Drawing.Color]::FromArgb(40, 40, 40)    # Xám đậm
$Color_Dark_Text = [System.Drawing.Color]::White
$Color_Neon_Cyan = [System.Drawing.Color]::FromArgb(0, 255, 255)   # Xanh Neon
$Color_Neon_Pink = [System.Drawing.Color]::FromArgb(255, 0, 255)   # Hồng Neon

# Màu sắc SÁNG (Light Mode)
$Color_Light_Bg = [System.Drawing.Color]::FromArgb(240, 240, 240)
$Color_Light_Card = [System.Drawing.Color]::White
$Color_Light_Text = [System.Drawing.Color]::Black
$Color_Light_Accent = [System.Drawing.Color]::FromArgb(0, 120, 215) # Xanh Win 10

# 4. KHỞI TẠO FORM CHÍNH
$form = New-Object System.Windows.Forms.Form
$form.Text = "ANTI-EFS TOOL | PHATTANPC"   # <--- Đã đổi tên theo yêu cầu
$form.Size = New-Object System.Drawing.Size(700, 500)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $true

# --- HÀM TẠO CARD (PANEL) ---
function Create-Card {
    param ($x, $y, $title, $desc, $btnText, $btnColor)
    
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point($x, $y)
    $panel.Size = New-Object System.Drawing.Size(200, 220)
    $panel.BorderStyle = "None"
    
    # Title
    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = $title
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $lblTitle.AutoSize = $false
    $lblTitle.Size = New-Object System.Drawing.Size(200, 30)
    $lblTitle.TextAlign = "MiddleCenter"
    $lblTitle.Location = New-Object System.Drawing.Point(0, 20)
    $panel.Controls.Add($lblTitle)

    # Desc
    $lblDesc = New-Object System.Windows.Forms.Label
    $lblDesc.Text = $desc
    $lblDesc.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
    $lblDesc.AutoSize = $false
    $lblDesc.Size = New-Object System.Drawing.Size(180, 80)
    $lblDesc.TextAlign = "TopCenter"
    $lblDesc.Location = New-Object System.Drawing.Point(10, 60)
    $panel.Controls.Add($lblDesc)

    # Button
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $btnText
    $btn.Size = New-Object System.Drawing.Size(140, 40)
    $btn.Location = New-Object System.Drawing.Point(30, 150)
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 2
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $panel.Controls.Add($btn)

    return @{Panel=$panel; Title=$lblTitle; Desc=$lblDesc; Button=$btn}
}

# --- TẠO 3 CÁI CARD (Đã thêm dấu Tiếng Việt) ---
$card1 = Create-Card 20 60 "SCANNER" "Quét ổ C tìm file bị mã hóa EFS (Màu xanh lá). Phát hiện sớm để tránh mất dữ liệu." "QUÉT NGAY" $Color_Neon_Cyan
$card2 = Create-Card 240 60 "DECRYPT" "Giải mã file xanh thành đen. Lưu ý: Chỉ chạy được khi Windows cũ còn vào được!" "GIẢI MÃ" $Color_Neon_Pink
$card3 = Create-Card 460 60 "DISABLE" "Vô hiệu hóa EFS vĩnh viễn. Ngăn chặn Windows tự ý mã hóa file sau này." "TẮT EFS" $Color_Neon_Cyan

$form.Controls.Add($card1.Panel)
$form.Controls.Add($card2.Panel)
$form.Controls.Add($card3.Panel)

# --- KHUNG LOG (OUTPUT) ---
$txtLog = New-Object System.Windows.Forms.RichTextBox
$txtLog.Location = New-Object System.Drawing.Point(20, 300)
$txtLog.Size = New-Object System.Drawing.Size(640, 140)
$txtLog.ReadOnly = $true
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 10)
$txtLog.BorderStyle = "None"
$form.Controls.Add($txtLog)

# --- NÚT CHUYỂN CHẾ ĐỘ (TOGGLE) ---
$btnTheme = New-Object System.Windows.Forms.Button
$btnTheme.Text = "☀ / ☾"
$btnTheme.Size = New-Object System.Drawing.Size(60, 30)
$btnTheme.Location = New-Object System.Drawing.Point(600, 10)
$btnTheme.FlatStyle = "Flat"
$btnTheme.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnTheme)

# --- TITLE LỚN ---
$lblMainTitle = New-Object System.Windows.Forms.Label
$lblMainTitle.Text = "ANTI-EFS PRO"
$lblMainTitle.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$lblMainTitle.AutoSize = $true
$lblMainTitle.Location = New-Object System.Drawing.Point(20, 10)
$form.Controls.Add($lblMainTitle)

# --- HÀM LOGGING ---
function Write-Log {
    param ($msg, $color)
    $txtLog.SelectionStart = $txtLog.Text.Length
    $txtLog.SelectionLength = 0
    $txtLog.SelectionColor = $color
    $txtLog.AppendText("[" + (Get-Date).ToString("HH:mm:ss") + "] " + $msg + "`r`n")
    $txtLog.ScrollToCaret()
}

# --- HÀM APPLY THEME ---
function Apply-Theme {
    if ($Script:IsDarkMode) {
        # DARK NEON THEME
        $form.BackColor = $Color_Dark_Bg
        $form.ForeColor = $Color_Neon_Cyan
        $lblMainTitle.ForeColor = $Color_Neon_Pink
        
        $txtLog.BackColor = [System.Drawing.Color]::Black
        $txtLog.ForeColor = [System.Drawing.Color]::LimeGreen # Màu Matrix

        $cards = @($card1, $card2, $card3)
        foreach ($c in $cards) {
            $c.Panel.BackColor = $Color_Dark_Card
            $c.Title.ForeColor = $Color_Neon_Cyan
            $c.Desc.ForeColor = [System.Drawing.Color]::Silver
            $c.Button.ForeColor = $Color_Neon_Cyan
            $c.Button.FlatAppearance.BorderColor = $Color_Neon_Cyan
            $c.Button.BackColor = $Color_Dark_Card
        }
        # Card 2 màu hồng cho nổi
        $card2.Title.ForeColor = $Color_Neon_Pink
        $card2.Button.ForeColor = $Color_Neon_Pink
        $card2.Button.FlatAppearance.BorderColor = $Color_Neon_Pink
        
        $btnTheme.ForeColor = $Color_Neon_Cyan
        $btnTheme.FlatAppearance.BorderColor = $Color_Neon_Cyan
    } else {
        # LIGHT THEME
        $form.BackColor = $Color_Light_Bg
        $form.ForeColor = $Color_Light_Text
        $lblMainTitle.ForeColor = $Color_Light_Accent

        $txtLog.BackColor = [System.Drawing.Color]::White
        $txtLog.ForeColor = [System.Drawing.Color]::Black

        $cards = @($card1, $card2, $card3)
        foreach ($c in $cards) {
            $c.Panel.BackColor = $Color_Light_Card
            $c.Title.ForeColor = $Color_Light_Accent
            $c.Desc.ForeColor = [System.Drawing.Color]::Gray
            $c.Button.ForeColor = $Color_Light_Accent
            $c.Button.FlatAppearance.BorderColor = $Color_Light_Accent
            $c.Button.BackColor = [System.Drawing.Color]::WhiteSmoke
        }
        
        $btnTheme.ForeColor = $Color_Light_Text
        $btnTheme.FlatAppearance.BorderColor = $Color_Light_Text
    }
}

# --- SỰ KIỆN NÚT BẤM (LOGIC) ---

# 1. Nút Theme
$btnTheme.Add_Click({
    $Script:IsDarkMode = -not $Script:IsDarkMode
    Apply-Theme
})

# 2. Nút SCAN
$card1.Button.Add_Click({
    Write-Log "Đang quét toàn bộ ổ C... (Vui lòng chờ)" [System.Drawing.Color]::Orange
    $form.Refresh()
    
    # Chạy Job ngầm để không đơ GUI (Cơ bản dùng invoke đơn giản)
    try {
        $result = cmd /c cipher /u /n 2>&1
        if ($result) {
            Write-Log "CẢNH BÁO: PHÁT HIỆN FILE BỊ MÃ HÓA!" [System.Drawing.Color]::Red
            Write-Log $result [System.Drawing.Color]::Red
        } else {
            Write-Log "Hệ thống an toàn. Không tìm thấy file EFS." [System.Drawing.Color]::Cyan
        }
    } catch {
        Write-Log "Lỗi khi quét: $_" [System.Drawing.Color]::Red
    }
})

# 3. Nút DECRYPT
$card2.Button.Add_Click({
    $userPath = $env:USERPROFILE
    Write-Log "Đang giải mã thư mục User: $userPath" [System.Drawing.Color]::Magenta
    $form.Refresh()
    
    Start-Process -FilePath "cipher.exe" -ArgumentList "/d /s:`"$userPath`" /i" -NoNewWindow -Wait
    Write-Log "Đã chạy lệnh giải mã xong. Hãy kiểm tra lại file!" [System.Drawing.Color]::Lime
})

# 4. Nút DISABLE
$card3.Button.Add_Click({
    Write-Log "Đang tiến hành tắt tính năng EFS..." [System.Drawing.Color]::Orange
    
    # Cách 1: FSUTIL
    $proc = Start-Process -FilePath "fsutil.exe" -ArgumentList "behavior set disableencryption 1" -NoNewWindow -PassThru -Wait
    if ($proc.ExitCode -eq 0) {
        Write-Log "FSUTIL: Thành công." [System.Drawing.Color]::Lime
    } else {
        Write-Log "FSUTIL: Thất bại (Có thể do Win Home)." [System.Drawing.Color]::Red
    }

    # Cách 2: REGISTRY
    try {
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\EFS"
        if (!(Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
        Set-ItemProperty -Path $regPath -Name "EfsConfiguration" -Value 1 -Type DWord -Force
        Write-Log "REGISTRY: Đã khóa EFS trong Registry." [System.Drawing.Color]::Lime
        Write-Log "=> YÊU CẦU: Khởi động lại máy để áp dụng!" [System.Drawing.Color]::Yellow
    } catch {
        Write-Log "Lỗi chỉnh Registry: $_" [System.Drawing.Color]::Red
    }
})

# --- RUN ---
Apply-Theme # Load màu lần đầu
$form.ShowDialog() | Out-Null
