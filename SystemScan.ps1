Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CẤU HÌNH API ---
$VT_API_KEY = "DA_KEY_CUA_BAN_VAO_DAY" # Thay bằng API Key thật của bạn

# --- GUI SETUP ---
$SForm = New-Object System.Windows.Forms.Form
$SForm.Text = "SYSTEM HEALTH & SECURITY - PHAT TAN PC"
$SForm.Size = New-Object System.Drawing.Size(700, 580) # Tăng chiều cao thêm tí
$SForm.StartPosition = "CenterScreen"
$SForm.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
$SForm.ForeColor = "Lime"
$SForm.FormBorderStyle = "FixedSingle"
$SForm.MaximizeBox = $false

# Khung Log
$TxtLog = New-Object System.Windows.Forms.TextBox
$TxtLog.Multiline = $true
$TxtLog.ScrollBars = "Vertical"
$TxtLog.Location = New-Object System.Drawing.Point(15, 15)
$TxtLog.Size = New-Object System.Drawing.Size(650, 350)
$TxtLog.BackColor = [System.Drawing.Color]::Black
$TxtLog.ForeColor = "Lime"
$TxtLog.Font = New-Object System.Drawing.Font("Consolas", 10)
$TxtLog.ReadOnly = $true
$SForm.Controls.Add($TxtLog)

# --- HÀM LOGIC ---
function Add-Log ($Msg) {
    $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $Msg`r`n")
    $TxtLog.SelectionStart = $TxtLog.Text.Length
    $TxtLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

# Hàm quét VirusTotal qua File Hash (Nhanh và không cần upload file nặng)
function Scan-VirusTotal {
    $FilePicker = New-Object System.Windows.Forms.OpenFileDialog
    if ($FilePicker.ShowDialog() -eq "OK") {
        $FilePath = $FilePicker.FileName
        Add-Log ">>> DANG KIEM TRA FILE: $FilePath"
        
        try {
            # Tính MD5 Hash của file
            $FileHash = (Get-FileHash $FilePath -Algorithm MD5).Hash
            Add-Log ">>> MD5: $FileHash"

            $Headers = @{ "x-apikey" = $VT_API_KEY }
            $Url = "https://www.virustotal.com/api/v3/files/$FileHash"
            
            $Response = Invoke-RestMethod -Uri $Url -Headers $Headers -Method Get
            
            $Stats = $Response.data.attributes.last_analysis_stats
            $Malicious = $Stats.malicious
            $Undetected = $Stats.undetected

            if ($Malicious -gt 0) {
                Add-Log "!!! CANH BAO: Phat hien $Malicious canh bao nguy hiem tu VirusTotal!"
            } else {
                Add-Log ">>> AN TOAN: File sạch (Dựa trên $Undetected trình diệt virus)."
            }
        } catch {
            Add-Log ">>> LOI: Khong tim thay thong tin file tren VirusTotal (Co the file chua tung duoc upload)."
        }
    }
}

function Run-RealTimeCmd ($Command) {
    $B1.Enabled = $false; $B2.Enabled = $false; $B3.Enabled = $false; $B4.Enabled = $false
    Add-Log ">>> DANG KHOI CHAY: $Command"
    
    $PInfo = New-Object System.Diagnostics.ProcessStartInfo
    $PInfo.FileName = "cmd.exe"
    $PInfo.Arguments = "/c $Command"
    $PInfo.RedirectStandardOutput = $true
    $PInfo.UseShellExecute = $false
    $PInfo.CreateNoWindow = $true
    $Process = New-Object System.Diagnostics.Process
    $Process.StartInfo = $PInfo
    $Process.Start() | Out-Null

    while (-not $Process.StandardOutput.EndOfStream) {
        Add-Log $Process.StandardOutput.ReadLine()
    }
    $Process.WaitForExit()
    Add-Log ">>> HOAN TAT."
    $B1.Enabled = $true; $B2.Enabled = $true; $B3.Enabled = $true; $B4.Enabled = $true
}

# --- BUTTONS ---
$B1 = New-Object System.Windows.Forms.Button
$B1.Text = "1. SFC SCAN"; $B1.Location = "15, 390"; $B1.Size = "210, 50"
$B1.Add_Click({ Run-RealTimeCmd "sfc /scannow" })
$SForm.Controls.Add($B1)

$B2 = New-Object System.Windows.Forms.Button
$B2.Text = "2. CHECK HEALTH"; $B2.Location = "235, 390"; $B2.Size = "210, 50"
$B2.Add_Click({ Run-RealTimeCmd "dism /online /cleanup-image /scanhealth" })
$SForm.Controls.Add($B2)

$B3 = New-Object System.Windows.Forms.Button
$B3.Text = "3. RESTORE HEALTH"; $B3.Location = "455, 390"; $B3.Size = "210, 50"
$B3.Add_Click({ Run-RealTimeCmd "dism /online /cleanup-image /restorehealth" })
$SForm.Controls.Add($B3)

# NÚT MỚI: QUÉT VIRUS
$B4 = New-Object System.Windows.Forms.Button
$B4.Text = "🛡️ 4. QUET FILE (VIRUS TOTAL)"; $B4.Location = "15, 450"; $B4.Size = "650, 60"
$B4.BackColor = "Crimson"; $B4.ForeColor = "White"; $B4.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$B4.Add_Click({ Scan-VirusTotal })
$SForm.Controls.Add($B4)

$SForm.ShowDialog() | Out-Null
