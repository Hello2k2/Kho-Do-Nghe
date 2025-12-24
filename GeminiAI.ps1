<#
    GEMINI AI ASSISTANT - UPDATED
    Fixed: Launch bug
    Added: Auto Diagnostics
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
$Form.Text = "GEMINI AI TERMINAL ASSISTANT (FIXED)"
$Form.Size = New-Object System.Drawing.Size(720, 500)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 35)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

# Header
$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "GEMINI AI CLI"; $LblT.Font = "Impact, 20"; $LblT.ForeColor="Cyan"; $LblT.AutoSize=$true; $LblT.Location="20,15"; $Form.Controls.Add($LblT)
$LblDesc = New-Object System.Windows.Forms.Label; $LblDesc.Text = "Tro ly ao AI tich hop - Fix loi & Chan doan tu dong"; $LblDesc.Location="25,55"; $LblDesc.AutoSize=$true; $LblDesc.ForeColor="LightGray"; $Form.Controls.Add($LblDesc)

# --- STATUS AREA ---
$GbStatus = New-Object System.Windows.Forms.GroupBox; $GbStatus.Text = "Trang Thai Môi Trường"; $GbStatus.Location="20,90"; $GbStatus.Size="660,100"; $GbStatus.ForeColor="Yellow"; $Form.Controls.Add($GbStatus)

$LblNode = New-Object System.Windows.Forms.Label; $LblNode.Text="Node.js (v20+): Dang kiem tra..."; $LblNode.Location="20,30"; $LblNode.AutoSize=$true; $GbStatus.Controls.Add($LblNode)
$LblGemini = New-Object System.Windows.Forms.Label; $LblGemini.Text="Gemini CLI Package: Dang kiem tra..."; $LblGemini.Location="20,60"; $LblGemini.AutoSize=$true; $GbStatus.Controls.Add($LblGemini)

# --- ACTION BUTTONS ---
# 1. Nút Cài đặt
$BtnInstall = New-Object System.Windows.Forms.Button; $BtnInstall.Text="1. CÀI ĐẶT / UPDATE"; $BtnInstall.Location="20,210"; $BtnInstall.Size="200,60"; $BtnInstall.BackColor="DimGray"; $BtnInstall.ForeColor="White"; $BtnInstall.Font="Segoe UI, 9, Bold"; $Form.Controls.Add($BtnInstall)

# 2. Nút Chat thường
$BtnLaunch = New-Object System.Windows.Forms.Button; $BtnLaunch.Text="2. CHAT TỰ DO"; $BtnLaunch.Location="230,210"; $BtnLaunch.Size="200,60"; $BtnLaunch.BackColor="SeaGreen"; $BtnLaunch.ForeColor="White"; $BtnLaunch.Font="Segoe UI, 10, Bold"; $BtnLaunch.Enabled=$false; $Form.Controls.Add($BtnLaunch)

# 3. Nút Chẩn đoán (MỚI)
$BtnDiagnose = New-Object System.Windows.Forms.Button; $BtnDiagnose.Text="3. 🔮 AI CHẨN ĐOÁN LỖI"; $BtnDiagnose.Location="440,210"; $BtnDiagnose.Size="240,60"; $BtnDiagnose.BackColor="RoyalBlue"; $BtnDiagnose.ForeColor="White"; $BtnDiagnose.Font="Segoe UI, 10, Bold"; $BtnDiagnose.Enabled=$false; $Form.Controls.Add($BtnDiagnose)

# Hướng dẫn
$TxtHd = New-Object System.Windows.Forms.TextBox; $TxtHd.Multiline=$true; $TxtHd.ReadOnly=$true; $TxtHd.Location="20,290"; $TxtHd.Size="660,150"; $TxtHd.BackColor="Black"; $TxtHd.ForeColor="Lime"; $Form.Controls.Add($TxtHd)
$TxtHd.Text = "LOG HỆ THỐNG:`r`n(Bấm nút 'AI CHẨN ĐOÁN LỖI' để quét log và nạp vào đây...)"

# --- LOGIC ---

function Check-Env {
    $Form.Cursor = "WaitCursor"
    # Check Node
    try {
        $NodeVer = node -v 2>$null
        if ($NodeVer) {
            $Major = [int]($NodeVer -replace "v","" -split "\.")[0]
            if ($Major -ge 20) { 
                $LblNode.Text = "Node.js: OK ($NodeVer)"; $LblNode.ForeColor="Lime"; $Global:NodeReady = $true
            } else { 
                $LblNode.Text = "Node.js: $NodeVer (Can v20+)"; $LblNode.ForeColor="Red"; $Global:NodeReady = $false 
            }
        } else { $LblNode.Text = "Node.js: Chua cai dat!"; $LblNode.ForeColor="Red"; $Global:NodeReady = $false }
    } catch { $LblNode.Text = "Node.js: Loi check!"; $Global:NodeReady = $false }

    # Check Gemini
    if ($Global:NodeReady) {
        try {
            $GeminiCheck = npm list -g @google/gemini-cli 2>$null
            if ($GeminiCheck -match "@google/gemini-cli") {
                $LblGemini.Text = "Gemini CLI: OK (Ready)"; $LblGemini.ForeColor="Lime"
                $BtnLaunch.Enabled = $true; $BtnLaunch.BackColor="SeaGreen"
                $BtnDiagnose.Enabled = $true; $BtnDiagnose.BackColor="RoyalBlue"
            } else {
                $LblGemini.Text = "Gemini CLI: Chua cai dat."; $LblGemini.ForeColor="Orange"
                $BtnLaunch.Enabled = $false; $BtnLaunch.BackColor="Gray"
                $BtnDiagnose.Enabled = $false; $BtnDiagnose.BackColor="Gray"
            }
        } catch { $LblGemini.Text = "Gemini CLI: Loi check!"; }
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
        Start-Process "cmd.exe" -ArgumentList "/c npm install -g @google/gemini-cli@latest" -Wait
        [System.Windows.Forms.MessageBox]::Show("Xong! Đã cài Gemini CLI.", "Success")
        Check-Env
    }
    $Form.Cursor = "Default"
})

$BtnLaunch.Add_Click({
    # FIX: Dùng cmd /k để giữ cửa sổ và chạy lệnh chat
    Start-Process "cmd.exe" -ArgumentList "/k gemini chat" 
    $Form.Close()
})

$BtnDiagnose.Add_Click({
    $Form.Cursor = "WaitCursor"
    $TxtHd.Text = "Đang quét hệ thống..."
    
    # 1. Lấy thông tin cơ bản
    $Info = Get-ComputerInfo | Select-Object CsName, OsName, WindowsBuildLabEx, CsTotalPhysicalMemory
    $Disk = Get-Volume -DriveLetter C | Select-Object SizeRemaining, Size
    
    # 2. Lấy 15 lỗi gần nhất trong System Log
    $Logs = Get-EventLog -LogName System -EntryType Error -Newest 15 -ErrorAction SilentlyContinue | Select-Object TimeGenerated, Source, Message | Format-Table -AutoSize | Out-String

    # 3. Tạo Prompt
    $Prompt = @"
Tôi đang gặp vấn đề với máy tính. Dưới đây là thông tin và log lỗi hệ thống gần nhất.
Hãy phân tích nguyên nhân và đề xuất cách sửa lỗi cụ thể (dùng tiếng Việt):

--- THÔNG TIN MÁY ---
OS: $($Info.OsName)
RAM: $([math]::Round($Info.CsTotalPhysicalMemory/1GB, 2)) GB
Disk C Free: $([math]::Round($Disk.SizeRemaining/1GB, 2)) GB / $([math]::Round($Disk.Size/1GB, 2)) GB

--- SYSTEM ERROR LOGS (Last 15) ---
$Logs
"@

    # 4. Copy vào Clipboard & Hiển thị
    $TxtHd.Text = "ĐÃ COPY LOG VÀO CLIPBOARD!`r`n`r`nBƯỚC TIẾP THEO:`r`n1. Cửa sổ chat Gemini sẽ hiện ra ngay bây giờ.`r`n2. Nhấn CTRL + V để dán log vào.`r`n3. Nhấn Enter để AI phân tích."
    Set-Clipboard -Value $Prompt
    
    [System.Windows.Forms.MessageBox]::Show("Đã quét log xong và Copy vào bộ nhớ tạm!`nNhấn OK để mở Gemini, sau đó nhấn Ctrl+V để dán log.", "AI Diagnostics")
    
    # Mở Gemini
    Start-Process "cmd.exe" -ArgumentList "/k gemini chat"
    $Form.Cursor = "Default"
})

$Form.Add_Shown({ Check-Env })
$Form.ShowDialog() | Out-Null
