Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- DANH SÁCH ISO ---
$IsoList = [ordered]@{
    "1. Windows 11 24H2 (Moi nhat - Goc MS)"          = "https://archive.org/download/WIN11_24H2/Win11_24H2_EnglishInternational_x64.iso"
    "2. Windows 11 23H2 (On dinh - Goc MS)"           = "https://archive.org/download/win11-23h2-english-international-x-64v-2_202406/Win11_23H2_EnglishInternational_x64v2.iso"
    "3. Windows 10 22H2 (Consumer - Goc MS)"          = "https://archive.org/download/en-us_windows_10_consumer_editions_version_22h2_updated_feb_2023_x64_dvd_c29e4bb3/en-us_windows_10_consumer_editions_version_22h2_updated_feb_2023_x64_dvd_c29e4bb3.iso"
    "4. Windows 10 Enterprise LTSC 2021 (Sieu Nhe)"   = "https://archive.org/download/windows-10-enterprise-ltsc-2021_202111/Windows%2010%20Enterprise%20LTSC%202021.iso"
    "5. Windows 8.1 Pro x64 (Goc MS)"                 = "https://archive.org/download/win8.1_english_iso/Win8.1_EnglishInternational_x64.iso"
    "6. Windows 8.1 Pro x32 (Cho may yeu)"            = "https://archive.org/download/win8.1_english_iso/Win8.1_EnglishInternational_x32.iso"
    "7. Windows 7 Ultimate SP1 x64 (Goc 2013)"        = "https://archive.org/download/win7-sp1-x64-en-us-oct2013/Win7.SP1.x64.en-US.Oct2013.iso"
    "8. Windows XP SP3 (Huyen thoai)"                 = "https://archive.org/download/win-xp-sp-unknown-0_202103/Win%20XP%20%28SP%20Unknown0.iso"
    "---------------------------------------"         = ""
    "9. Office 2021 Pro Plus (Img Goc)"               = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/en-us/ProPlus2021Retail.img"
    "10. Office 2019 Pro Plus (Img Goc)"              = "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/en-us/ProPlus2019Retail.img"
}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "ISO DOWNLOADER - PHAT TAN PC"
$Form.Size = New-Object System.Drawing.Size(650, 400)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

$Lbl = New-Object System.Windows.Forms.Label
$Lbl.Text = "CHON PHIEN BAN WINDOWS / OFFICE CAN TAI:"
$Lbl.AutoSize = $true; $Lbl.Location = New-Object System.Drawing.Point(20, 20)
$Lbl.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$Lbl.ForeColor = "Cyan"
$Form.Controls.Add($Lbl)

$Combo = New-Object System.Windows.Forms.ComboBox
$Combo.Location = New-Object System.Drawing.Point(20, 60); $Combo.Size = New-Object System.Drawing.Size(590, 35)
$Combo.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$Combo.DropDownStyle = "DropDownList"
foreach ($Key in $IsoList.Keys) { $Combo.Items.Add($Key) }
$Combo.SelectedIndex = 0
$Form.Controls.Add($Combo)

$Bar = New-Object System.Windows.Forms.ProgressBar
$Bar.Location = New-Object System.Drawing.Point(20, 180); $Bar.Size = New-Object System.Drawing.Size(590, 30)
$Form.Controls.Add($Bar)

$Status = New-Object System.Windows.Forms.Label
$Status.Text = "Trang thai: San sang."
$Status.AutoSize = $true; $Status.Location = New-Object System.Drawing.Point(20, 150); $Status.Font = "Segoe UI, 10"; $Status.ForeColor = "Yellow"
$Form.Controls.Add($Status)

$Btn = New-Object System.Windows.Forms.Button
$Btn.Text = "BAT DAU TAI (DIRECT LINK)"
$Btn.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$Btn.Location = New-Object System.Drawing.Point(180, 240); $Btn.Size = New-Object System.Drawing.Size(280, 50)
$Btn.BackColor = "LimeGreen"; $Btn.ForeColor = "Black"; $Btn.FlatStyle = "Flat"

$Btn.Add_Click({
    $SelectedName = $Combo.SelectedItem
    $Url = $IsoList[$SelectedName]

    if ($Url -eq "" -or $Url -eq $null) { [System.Windows.Forms.MessageBox]::Show("Vui long chon muc khac!", "Luu y"); return }
    
    $DefaultName = "Windows.iso"
    if ($SelectedName -match "Win 11") { $DefaultName = "Windows11_Original.iso" }
    elseif ($SelectedName -match "Win 10") { $DefaultName = "Windows10_Original.iso" }
    elseif ($SelectedName -match "Win 7") { $DefaultName = "Windows7_SP1.iso" }
    elseif ($SelectedName -match "XP") { $DefaultName = "WindowsXP_SP3.iso" }
    elseif ($SelectedName -match "Office") { $DefaultName = "Office_Install.img" }

    $SaveDlg = New-Object System.Windows.Forms.SaveFileDialog
    $SaveDlg.FileName = $DefaultName
    $SaveDlg.Filter = "ISO Image (*.iso)|*.iso|Disk Image (*.img)|*.img|All Files (*.*)|*.*"
    
    if ($SaveDlg.ShowDialog() -eq "OK") {
        $LocalPath = $SaveDlg.FileName
        $Btn.Enabled = $false; $Combo.Enabled = $false
        
        try {
            Import-Module BitsTransfer
            # Priority High để tải nhanh nhất
            $Job = Start-BitsTransfer -Source $Url -Destination $LocalPath -Asynchronous -DisplayName "PhatTanDownload" -Priority High
            
            while ($Job.JobState -eq "Transferring" -or $Job.JobState -eq "Connecting") {
                # KHÔNG CẦN GET LẠI JOB, BIẾN $JOB TỰ CẬP NHẬT
                
                if ($Job.TotalBytes -gt 0) {
                    $Percent = [Math]::Round(($Job.BytesTransferred / $Job.TotalBytes) * 100)
                    $Bar.Value = $Percent
                    
                    $DaTai = [Math]::Round($Job.BytesTransferred / 1MB, 2)
                    $Tong  = [Math]::Round($Job.TotalBytes / 1MB, 2)
                    $Status.Text = "Dang tai... $Percent% ($DaTai MB / $Tong MB)"
                } else {
                    $Status.Text = "Dang ket noi... (Chua xac dinh dung luong)"
                }
                $Form.Refresh()
                Start-Sleep -Milliseconds 500
            }
            
            Complete-BitsTransfer -JobId $Job.JobId
            $Bar.Value = 100
            $Status.Text = "Tai thanh cong! File luu tai: $LocalPath"
            [System.Windows.Forms.MessageBox]::Show("Da tai xong ISO goc!", "Phat Tan PC")
            
            Invoke-Item (Split-Path $LocalPath)
            
        } catch {
            $Status.Text = "Loi ket noi. Server ban hoac mang yeu."
            [System.Windows.Forms.MessageBox]::Show("Loi: $($_.Exception.Message)", "Error")
        }
        
        $Btn.Enabled = $true; $Combo.Enabled = $true
    }
})

$Form.Controls.Add($Btn)
$Form.ShowDialog() | Out-Null
