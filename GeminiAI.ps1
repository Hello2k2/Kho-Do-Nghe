<#
    GEMINI AI ASSISTANT - ULTIMATE FIX
    Fixed: Interactive Menu Bug (Keyboard input)
    Added: Separate Login Button
#>

# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "GEMINI AI CONTROL PANEL"
$Form.Size = New-Object System.Drawing.Size(720, 520)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "GEMINI AI CONTROLLER"; $LblT.Font = "Segoe UI, 18, Bold"; $LblT.ForeColor="Cyan"; $LblT.AutoSize=$true; $LblT.Location="20,15"; $Form.Controls.Add($LblT)
$LblDesc = New-Object System.Windows.Forms.Label; $LblDesc.Text = "Trợ lý AI dòng lệnh - Fix lỗi tương tác bàn phím"; $LblDesc.Location="25,50"; $LblDesc.AutoSize=$true; $LblDesc.ForeColor="Gray"; $Form.Controls.Add($LblDesc)

# --- STATUS AREA ---
$GbStatus = New-Object System.Windows.Forms.GroupBox; $GbStatus.Text = "Kiểm Tra Môi Trường"; $GbStatus.Location="20,80"; $GbStatus.Size="660,90"; $GbStatus.ForeColor="Yellow"; $Form.Controls.Add($GbStatus)

$LblNode = New-Object System.Windows.Forms.Label; $LblNode.Text="Node.js (v20+): ..."; $LblNode.Location="20,30"; $LblNode.AutoSize=$true; $GbStatus.Controls.Add($LblNode)
$LblGemini = New-Object System.Windows.Forms.Label; $LblGemini.Text="Gemini Core: ..."; $LblGemini.Location="20,55"; $LblGemini.AutoSize=$true; $GbStatus.Controls.Add($LblGemini)

# --- ACTION BUTTONS ---
# 1. Nút Cài đặt
$BtnInstall = New-Object System.Windows.Forms.Button; $BtnInstall.Text="1. CÀI ĐẶT ENVIRONMENT"; $BtnInstall.Location="20,190"; $BtnInstall.Size="320,50"; $BtnInstall.BackColor="DimGray"; $BtnInstall.ForeColor="White"; $BtnInstall.Font="Segoe UI, 9, Bold"; $Form.Controls.Add($BtnInstall)

# 2. Nút Login (QUAN TRỌNG)
$BtnLogin = New-Object System.Windows.Forms.Button; $BtnLogin.Text="2. ĐĂNG NHẬP LẦN ĐẦU (Login)"; $BtnLogin.Location="360,190"; $BtnLogin.Size="320,50"; $BtnLogin.BackColor="DarkOrange"; $BtnLogin.ForeColor="White"; $BtnLogin.Font="Segoe UI, 9, Bold"; $BtnLogin.Enabled=$false; $Form.Controls.Add($BtnLogin)

# 3. Nút Chat
$BtnLaunch = New-Object System.Windows.Forms.Button; $BtnLaunch.Text="3. BẮT ĐẦU CHAT (Chat Mode)"; $BtnLaunch.Location="20,250"; $BtnLaunch.Size="320,50"; $BtnLaunch.BackColor="SeaGreen"; $BtnLaunch.ForeColor="White"; $BtnLaunch.Font="Segoe UI, 10, Bold"; $BtnLaunch.Enabled=$false; $Form.Controls.Add($BtnLaunch)

# 4. Nút Chẩn đoán
$BtnDiagnose = New-Object System.Windows.Forms.Button; $BtnDiagnose.Text="4. AI CHẨN ĐOÁN LỖI PC"; $BtnDiagnose.Location="360,250"; $BtnDiagnose.Size="320,50"; $BtnDiagnose.BackColor="RoyalBlue"; $BtnDiagnose.ForeColor="White"; $BtnDiagnose.Font="Segoe UI, 10, Bold"; $BtnDiagnose.Enabled=$false; $Form.Controls.Add($BtnDiagnose)

# Hướng dẫn
$TxtHd = New-Object System.Windows.Forms.TextBox; $TxtHd.Multiline=$true; $TxtHd.ReadOnly=$true; $TxtHd.Location="20,320"; $TxtHd.Size="660,140"; $TxtHd.BackColor="Black"; $TxtHd.ForeColor="Lime"; $Form.Controls.Add($TxtHd)
$TxtHd.Text = "HƯỚNG DẪN FIX LỖI:`r`n- Nếu chưa từng chạy bao giờ, hãy bấm Nút số 2 (Đăng nhập).`r`n- Một cửa sổ xanh sẽ hiện lên -> Dùng Mũi Tên lên xuống chọn 'Login with Google' -> Enter.`r`n- Sau khi Login xong, tắt cửa sổ đó đi và dùng Nút số 3 hoặc 4 để Chat."

# --- LOGIC ---

function Check-Env {
    $Form.Cursor = "WaitCursor"
    try {
        $NodeVer = node -v 2>$null
        if ($NodeVer) {
            $Major = [int]($NodeVer -replace "v","" -split "\.")[0]
            if ($Major -ge 20) { 
                $LblNode.Text = "Node.js: OK ($NodeVer)"; $LblNode.ForeColor="Lime"; $Global:NodeReady = $true
            } else { 
                $LblNode.Text = "Node.js: $NodeVer (Cần v20+)"; $LblNode.ForeColor="Red"; $Global:NodeReady = $false 
            }
        } else { $LblNode.Text = "Node.js: Chưa cài đặt!"; $LblNode.ForeColor="Red"; $Global:NodeReady = $false }
    } catch { $LblNode.Text = "Node.js: Lỗi check!"; $Global:NodeReady = $false }

    if ($Global:NodeReady) {
        try {
            $GeminiCheck = npm list -g @google/gemini-cli 2>$null
            if ($GeminiCheck -match "@google/gemini-cli") {
                $LblGemini.Text = "Gemini CLI: Đã cài đặt"; $LblGemini.ForeColor="Lime"
                $BtnLogin.Enabled = $true; $BtnLogin.BackColor="DarkOrange"
                $BtnLaunch.Enabled = $true; $BtnLaunch.BackColor="SeaGreen"
                $BtnDiagnose.Enabled = $true; $BtnDiagnose.BackColor="RoyalBlue"
            } else {
                $LblGemini.Text = "Gemini CLI: Chưa cài đặt"; $LblGemini.ForeColor="Orange"
            }
        } catch { $LblGemini.Text = "Gemini CLI: Lỗi check!"; }
    }
    $Form.Cursor = "Default"
}

# --- BUTTON EVENTS ---

$BtnInstall.Add_Click({
    $Form.Cursor = "WaitCursor"
    if (!$Global:NodeReady) {
        $Ans = [System.Windows.Forms.MessageBox]::Show("Tải Node.js v20+ ?", "Confirm", "YesNo")
        if ($Ans -eq "Yes") {
            $Url = "https://nodejs.org/dist/v20.11.0/node-v20.11.0-x64.msi"; $Dest = "$env:TEMP\node.msi"
            (New-Object System.Net.WebClient).DownloadFile($Url, $Dest)
            Start-Process "msiexec.exe" -ArgumentList "/i `"$Dest`" /quiet /norestart" -Wait
            [System.Windows.Forms.MessageBox]::Show("Đã cài Node. Khởi động lại Tool!", "Info"); $Form.Close(); return
        }
    }
    if ($Global:NodeReady) {
        # Dùng PowerShell window để cài đặt cho mượt
        Start-Process "powershell.exe" -ArgumentList "-NoExit", "-Command", "npm install -g @google/gemini-cli@latest" -Wait
        [System.Windows.Forms.MessageBox]::Show("Xong! Đã cài Gemini CLI.", "Success")
        Check-Env
    }
    $Form.Cursor = "Default"
})

$BtnLogin.Add_Click({
    # FIX QUAN TRỌNG: Chạy lệnh 'gemini' (không có chat) để hiện menu Login
    # Dùng PowerShell riêng biệt để nhận phím mũi tên tốt hơn cmd
    Start-Process "powershell.exe" -ArgumentList "-NoExit", "-Command", "Write-Host 'DÙNG PHÍM MŨI TÊN ĐỂ CHỌN LOGIN WITH GOOGLE -> ENTER' -ForegroundColor Cyan; gemini" 
})

$BtnLaunch.Add_Click({
    # Vào thẳng chế độ Chat
    Start-Process "powershell.exe" -ArgumentList "-NoExit", "-Command", "gemini chat" 
    $Form.Close()
})

$BtnDiagnose.Add_Click({
    $Form.Cursor = "WaitCursor"
    $TxtHd.Text = "Đang quét hệ thống..."
    
    $Info = Get-ComputerInfo | Select-Object CsName, OsName, WindowsBuildLabEx, CsTotalPhysicalMemory
    $Disk = Get-Volume -DriveLetter C | Select-Object SizeRemaining, Size
    $Logs = Get-EventLog -LogName System -EntryType Error -Newest 15 -ErrorAction SilentlyContinue | Select-Object TimeGenerated, Source, Message | Format-Table -AutoSize | Out-String

    $Prompt = @"
Tôi đang gặp vấn đề với máy tính. Phân tích log lỗi sau và đưa ra giải pháp (tiếng Việt):
--- INFO ---
OS: $($Info.OsName)
RAM: $([math]::Round($Info.CsTotalPhysicalMemory/1GB, 2)) GB
Disk C Free: $([math]::Round($Disk.SizeRemaining/1GB, 2)) GB
--- ERROR LOGS ---
$Logs
"@
    Set-Clipboard -Value $Prompt
    [System.Windows.Forms.MessageBox]::Show("Đã Copy Log! Nhấn Ctrl+V vào cửa sổ chat tiếp theo.", "AI Diagnostics")
    
    # Mở Chat
    Start-Process "powershell.exe" -ArgumentList "-NoExit", "-Command", "gemini chat"
    $Form.Cursor = "Default"
})

$Form.Add_Shown({ Check-Env })
$Form.ShowDialog() | Out-Null
