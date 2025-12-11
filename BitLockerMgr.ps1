<#
    BITLOCKER MANAGER V9.4 - FINAL STABLE (NO LOOP)
    Features: Stable Loader + Raw Forensic + Key Hunter
#>

# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    try { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit }
    catch { Write-Host "VUI LONG CHAY VOI QUYEN ADMIN!" -F Red; Pause; Exit }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "SilentlyContinue"

# --- 2. C# RAW DISK READER ---
try {
    if (-not ([System.Management.Automation.PSTypeName]'DiskReader').Type) {
        $Code = @"
        using System;
        using System.IO;
        using System.Runtime.InteropServices;
        using Microsoft.Win32.SafeHandles;
        public class DiskReader {
            [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
            public static extern SafeFileHandle CreateFile(string lpFileName, uint dwDesiredAccess, uint dwShareMode, IntPtr lpSecurityAttributes, uint dwCreationDisposition, uint dwFlagsAndAttributes, IntPtr hTemplateFile);
            public static byte[] ReadSector(string drive, long sector, int count) {
                SafeFileHandle handle = CreateFile(drive, 0x80000000, 1|2, IntPtr.Zero, 3, 0, IntPtr.Zero);
                if (handle.IsInvalid) return new byte[0];
                FileStream fs = new FileStream(handle, FileAccess.Read);
                if (sector > 0) fs.Seek(sector * 512, SeekOrigin.Begin);
                byte[] buffer = new byte[512 * count];
                int bytesRead = fs.Read(buffer, 0, buffer.Length);
                fs.Close(); handle.Close();
                if (bytesRead > 0 && bytesRead < buffer.Length) {
                    byte[] actualBuffer = new byte[bytesRead];
                    Array.Copy(buffer, actualBuffer, bytesRead);
                    return actualBuffer;
                }
                if (bytesRead == 0) return null;
                return buffer;
            }
        }
"@
        Add-Type -TypeDefinition $Code -Language CSharp
    }
} catch {}

# --- GUI SETUP ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "BITLOCKER MANAGER V9.4 (STABLE NO LOOP)"
$Form.Size = New-Object System.Drawing.Size(1100, 800)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 30)
$Form.ForeColor = "White"
$Form.FormBorderStyle = "FixedSingle"
$Form.MaximizeBox = $false

$LblT = New-Object System.Windows.Forms.Label; $LblT.Text = "BITLOCKER MASTER CONTROL"; $LblT.Font = "Impact, 22"; $LblT.ForeColor = "Gold"; $LblT.AutoSize = $true; $LblT.Location = "20,15"; $Form.Controls.Add($LblT)
$LblStatus = New-Object System.Windows.Forms.Label; $LblStatus.Text = "Ready"; $LblStatus.ForeColor = "Lime"; $LblStatus.Location = "450,25"; $LblStatus.AutoSize = $true; $Form.Controls.Add($LblStatus)

# --- TAB CONTROL ---
$Tab = New-Object System.Windows.Forms.TabControl; $Tab.Location = "20, 70"; $Tab.Size = "1040, 670"; $Tab.Font = "Segoe UI, 10"
$Form.Controls.Add($Tab)

function Add-Page ($Title) { 
    $P = New-Object System.Windows.Forms.TabPage; $P.Text = "  $Title  "
    $P.BackColor = [System.Drawing.Color]::FromArgb(45,45,50); $Tab.Controls.Add($P); return $P 
}

# >>> TAB 1: DASHBOARD
$Page1 = Add-Page "QUẢN LÝ & MỞ KHÓA"
$Grid = New-Object System.Windows.Forms.DataGridView; $Grid.Location = "15,15"; $Grid.Size = "1005, 280"; $Grid.BackgroundColor = "Black"; $Grid.ForeColor = "Black"; $Grid.AllowUserToAddRows = $false; $Grid.RowHeadersVisible = $false; $Grid.SelectionMode = "FullRowSelect"; $Grid.MultiSelect = $false; $Grid.AutoSizeColumnsMode = "Fill"
$Grid.Columns.Add("Mount", "Ổ"); $Grid.Columns[0].Width = 40
$Grid.Columns.Add("Status", "Trạng Thái"); $Grid.Columns[1].Width = 80
$Grid.Columns.Add("Lock", "Tình Trạng"); $Grid.Columns[2].Width = 80
$Grid.Columns.Add("Key", "Recovery Key"); $Grid.Columns[3].FillWeight = 200; $Grid.Columns[3].DefaultCellStyle.ForeColor = "Blue"
$Grid.Columns.Add("ID", "Protector ID"); $Grid.Columns[4].Width = 250
$Page1.Controls.Add($Grid)

$GbUnlock = New-Object System.Windows.Forms.GroupBox; $GbUnlock.Text = "MỞ KHÓA / PHÂN TÍCH"; $GbUnlock.Location = "15,310"; $GbUnlock.Size = "1005, 80"; $GbUnlock.ForeColor = "Cyan"; $Page1.Controls.Add($GbUnlock)
$TxtManual = New-Object System.Windows.Forms.TextBox; $TxtManual.Location = "20,30"; $TxtManual.Size = "600,30"; $TxtManual.Font = "Consolas, 11"; $GbUnlock.Controls.Add($TxtManual)
$BtnUnlock = New-Object System.Windows.Forms.Button; $BtnUnlock.Text = "UNLOCK"; $BtnUnlock.Location = "640,28"; $BtnUnlock.Size = "150,32"; $BtnUnlock.BackColor = "Green"; $BtnUnlock.ForeColor = "White"; $GbUnlock.Controls.Add($BtnUnlock)
$BtnMeta = New-Object System.Windows.Forms.Button; $BtnMeta.Text = "METADATA"; $BtnMeta.Location = "800,28"; $BtnMeta.Size = "190,32"; $BtnMeta.BackColor = "DarkMagenta"; $BtnMeta.ForeColor = "White"; $GbUnlock.Controls.Add($BtnMeta)

# Manegement Buttons
$BtnBackup = New-Object System.Windows.Forms.Button; $BtnBackup.Text = "LƯU KEY"; $BtnBackup.Location = "15,410"; $BtnBackup.Size = "240,40"; $BtnBackup.BackColor = "Teal"; $Page1.Controls.Add($BtnBackup)
$BtnOff = New-Object System.Windows.Forms.Button; $BtnOff.Text = "TẮT BITLOCKER"; $BtnOff.Location = "270,410"; $BtnOff.Size = "240,40"; $BtnOff.BackColor = "Firebrick"; $Page1.Controls.Add($BtnOff)
$BtnSus = New-Object System.Windows.Forms.Button; $BtnSus.Text = "SUSPEND"; $BtnSus.Location = "525,410"; $BtnSus.Size = "240,40"; $BtnSus.BackColor = "Gray"; $Page1.Controls.Add($BtnSus)
$BtnRef = New-Object System.Windows.Forms.Button; $BtnRef.Text = "REFRESH"; $BtnRef.Location = "780,410"; $BtnRef.Size = "240,40"; $BtnRef.BackColor = "Blue"; $Page1.Controls.Add($BtnRef)
$BtnFixPerm = New-Object System.Windows.Forms.Button; $BtnFixPerm.Text = "FIX LỖI ACCESS DENIED (SỬA QUYỀN NTFS)"; $BtnFixPerm.Location = "15,460"; $BtnFixPerm.Size = "1005,40"; $BtnFixPerm.BackColor = "Purple"; $Page1.Controls.Add($BtnFixPerm)


# >>> TAB 2: RESCUE
$Page2 = Add-Page "QUÉT TÌM KEY (FILE/RAM)"
$BtnScanFile = New-Object System.Windows.Forms.Button; $BtnScanFile.Text = "QUÉT FILE TEXT CHỨA KEY"; $BtnScanFile.Location = "30,30"; $BtnScanFile.Size = "450,50"; $BtnScanFile.BackColor = "DarkOrange"; $Page2.Controls.Add($BtnScanFile)
$BtnScanHiber = New-Object System.Windows.Forms.Button; $BtnScanHiber.Text = "QUÉT RAM (HIBERFIL.SYS)"; $BtnScanHiber.Location = "500,30"; $BtnScanHiber.Size = "450,50"; $BtnScanHiber.BackColor = "Firebrick"; $Page2.Controls.Add($BtnScanHiber)
$TxtLog = New-Object System.Windows.Forms.TextBox; $TxtLog.Multiline = $true; $TxtLog.Location = "30,100"; $TxtLog.Size = "920,450"; $TxtLog.BackColor = "Black"; $TxtLog.ForeColor = "Lime"; $TxtLog.ScrollBars = "Vertical"; $Page2.Controls.Add($TxtLog)

# >>> TAB 3: ONLINE
$Page3 = Add-Page "ONLINE RECOVERY"
$BtnAD = New-Object System.Windows.Forms.Button; $BtnAD.Text = "CHECK ACTIVE DIRECTORY"; $BtnAD.Location = "50,50"; $BtnAD.Size = "800,60"; $BtnAD.BackColor = "RoyalBlue"; $Page3.Controls.Add($BtnAD)
$BtnWeb = New-Object System.Windows.Forms.Button; $BtnWeb.Text = "MICROSOFT CLOUD KEY"; $BtnWeb.Location = "50,130"; $BtnWeb.Size = "800,60"; $BtnWeb.BackColor = "DeepSkyBlue"; $Page3.Controls.Add($BtnWeb)

# >>> TAB 4: BRUTE FORCE
$Page4 = Add-Page "BRUTE FORCE"
$LblBF = New-Object System.Windows.Forms.Label; $LblBF.Text = "Danh sách Password (1 dòng/pass):"; $LblBF.Location = "30,20"; $LblBF.AutoSize = $true; $LblBF.ForeColor = "Yellow"; $Page4.Controls.Add($LblBF)
$TxtPassList = New-Object System.Windows.Forms.TextBox; $TxtPassList.Multiline = $true; $TxtPassList.Location = "30,50"; $TxtPassList.Size = "400,450"; $Page4.Controls.Add($TxtPassList)
$BtnBF = New-Object System.Windows.Forms.Button; $BtnBF.Text = "AUTO TRY >>"; $BtnBF.Location = "450,50"; $BtnBF.Size = "400,60"; $BtnBF.BackColor = "DarkRed"; $Page4.Controls.Add($BtnBF)
$LblBFStat = New-Object System.Windows.Forms.Label; $LblBFStat.Text = "Idle"; $LblBFStat.Location = "450,130"; $LblBFStat.AutoSize = $true; $Page4.Controls.Add($LblBFStat)

# >>> TAB 5: RAW SECTOR SCAN
$Page5 = Add-Page "QUÉT RAW DISK (FORENSIC)"
$LblRaw = New-Object System.Windows.Forms.Label; $LblRaw.Text = "CẢNH BÁO: Quét trực tiếp Sector vật lý. Rất chậm (1TB ~ 3-4 tiếng)."; $LblRaw.Location = "30,20"; $LblRaw.AutoSize = $true; $LblRaw.ForeColor = "Red"; $Page5.Controls.Add($LblRaw)

$CboDisk = New-Object System.Windows.Forms.ComboBox; $CboDisk.Location = "30,60"; $CboDisk.Size = "300,30"; $Page5.Controls.Add($CboDisk)
try { Get-WmiObject Win32_DiskDrive | ForEach-Object { $CboDisk.Items.Add("$($_.DeviceID) - $($_.Model) ($([Math]::Round($_.Size/1GB)) GB)") } | Out-Null } catch {}
if ($CboDisk.Items.Count -gt 0) { $CboDisk.SelectedIndex = 0 }
$BtnRawScan = New-Object System.Windows.Forms.Button; $BtnRawScan.Text = "BẮT ĐẦU QUÉT FULL DISK"; $BtnRawScan.Location = "350,58"; $BtnRawScan.Size = "300,30"; $BtnRawScan.BackColor = "Crimson"; $BtnRawScan.ForeColor = "White"; $Page5.Controls.Add($BtnRawScan)
$TxtRawLog = New-Object System.Windows.Forms.TextBox; $TxtRawLog.Multiline = $true; $TxtRawLog.Location = "30,110"; $TxtRawLog.Size = "900,450"; $TxtRawLog.BackColor = "Black"; $TxtRawLog.ForeColor = "Orange"; $TxtRawLog.ScrollBars = "Vertical"; $Page5.Controls.Add($TxtRawLog)

# --- FUNCTIONS ---
function Log ($M) { $TxtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $M`r`n"); $TxtLog.ScrollToCaret(); [System.Windows.Forms.Application]::DoEvents() }
function RawLog ($M) { $TxtRawLog.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] $M`r`n"); $TxtRawLog.ScrollToCaret(); [System.Windows.Forms.Application]::DoEvents() }

function Show-Report ($Title, $Content) {
    $FRep = New-Object System.Windows.Forms.Form; $FRep.Text = $Title; $FRep.Size = New-Object System.Drawing.Size(800, 600); $FRep.StartPosition = "CenterParent"
    $TxtRep = New-Object System.Windows.Forms.TextBox; $TxtRep.Multiline = $true; $TxtRep.Dock = "Fill"; $TxtRep.ScrollBars = "Vertical"; $TxtRep.Font = "Consolas, 10"; $TxtRep.Text = $Content; $FRep.Controls.Add($TxtRep)
    $FRep.ShowDialog()
}

# --- LOAD DRIVES (STABLE - NO LOOP) ---
function Load-Drives {
    $LblStatus.Text = "Loading..."
    $Grid.Rows.Clear()
    $Form.Cursor = "WaitCursor"
    [System.Windows.Forms.Application]::DoEvents() # Giup UI khong bi do
    
    # 1. Thu dung PowerShell Cmdlet
    $Done = $false
    try {
        $Vols = Get-BitLockerVolume -ErrorAction Stop
        foreach ($V in $Vols) {
            $Stat = if($V.ProtectionStatus -eq "On"){"LOCKED"}else{"Unlocked"}
            $ID = "Unknown"; $RecKey = "Hidden (Locked)"
            foreach($Kp in $V.KeyProtector){ 
                if($Kp.KeyProtectorType -eq "RecoveryPassword"){
                    $ID = $Kp.KeyProtectorId
                    if ($V.VolumeStatus -ne "Locked") { $RecKey = $Kp.RecoveryPassword }
                } 
            }
            $Grid.Rows.Add($V.MountPoint, $V.VolumeStatus, $Stat, $RecKey, $ID) | Out-Null
        }
        $Done = $true
    } catch {}

    # 2. Fallback WMI (Chi chay khi Cmdlet loi)
    if (-not $Done) {
        try {
            $Wmi = Get-WmiObject -Namespace "root\CIMV2\Security\MicrosoftVolumeEncryption" -Class Win32_EncryptableVolume
            foreach ($W in $Wmi) {
                $Stat = if($W.ProtectionStatus -eq 1){"LOCKED"}else{"Unlocked"}
                $IDs = $W.GetKeyProtectors(3).VolumeKeyProtectorID
                $ShowID = if($IDs){$IDs[0]}else{"N/A"}
                $RecKey = "Hidden (Locked)"
                if ($W.ProtectionStatus -eq 0) { try { $RecKey = $W.GetKeyProtectorNumericalPassword($ShowID).NumericalPassword } catch {} }
                $Grid.Rows.Add($W.DriveLetter, "Unknown", $Stat, $RecKey, $ShowID) | Out-Null
            }
        } catch {}
    }
    
    $LblStatus.Text = "Ready"; $Form.Cursor = "Default"
}

$BtnRef.Add_Click({ Load-Drives })

$BtnUnlock.Add_Click({
    if (!$Grid.SelectedRows.Count) { return }
    $Drv = $Grid.SelectedRows[0].Cells[0].Value; $In = $TxtManual.Text.Trim()
    if (!$In) { return }
    $Form.Cursor = "WaitCursor"
    try {
        $P1 = Start-Process "manage-bde" "-unlock $Drv -pw $In" -NoNewWindow -PassThru -Wait
        if ($P1.ExitCode -eq 0) { Load-Drives; [System.Windows.Forms.MessageBox]::Show("Success (Pass)!", "OK") }
        else {
            $P2 = Start-Process "manage-bde" "-unlock $Drv -rp $In" -NoNewWindow -PassThru -Wait
            if ($P2.ExitCode -eq 0) { Load-Drives; [System.Windows.Forms.MessageBox]::Show("Success (Recovery Key)!", "OK") }
            else { [System.Windows.Forms.MessageBox]::Show("Fail!", "Error") }
        }
    } catch {}
    $Form.Cursor = "Default"
})

$BtnMeta.Add_Click({
    if (!$Grid.SelectedRows.Count) { return }
    $Drv = $Grid.SelectedRows[0].Cells[0].Value
    $Status = cmd /c "manage-bde -status $Drv"
    $Protectors = cmd /c "manage-bde -protectors -get $Drv"
    Show-Report "METADATA" "$($Status -join "`r`n")`r`n----------------`r`n$($Protectors -join "`r`n")"
})

$BtnBackup.Add_Click({
    try {
        if (!$Grid.SelectedRows.Count) { return }
        $Row = $Grid.SelectedRows[0]; $Drv = $Row.Cells[0].Value; $Key = $Row.Cells[3].Value
        if ($Key -match "\d{6}-") {
             $Save = New-Object System.Windows.Forms.SaveFileDialog; $Save.FileName="Key_$($Drv.Trim(':')).txt"
             if ($Save.ShowDialog() -eq "OK") { [IO.File]::WriteAllText($Save.FileName, "$Key"); [System.Windows.Forms.MessageBox]::Show("Saved!", "OK") }
        } else { [System.Windows.Forms.MessageBox]::Show("No Key visible.", "Info") }
    } catch {}
})

$BtnOff.Add_Click({ try{ if (!$Grid.SelectedRows.Count) { return }; $Drv = $Grid.SelectedRows[0].Cells[0].Value; Start-Process "manage-bde" "-off $Drv" -WindowStyle Hidden; Load-Drives } catch {} })
$BtnSus.Add_Click({ try{ if (!$Grid.SelectedRows.Count) { return }; $Drv = $Grid.SelectedRows[0].Cells[0].Value; Start-Process "manage-bde" "-protectors -disable $Drv" -WindowStyle Hidden; Load-Drives } catch {} })

$BtnFixPerm.Add_Click({
    try {
        if (!$Grid.SelectedRows.Count) { return }; $Drv = $Grid.SelectedRows[0].Cells[0].Value
        $Form.Cursor="WaitCursor"; Start-Process "icacls" "$Drv\ /grant Everyone:F /T /C /Q" -Wait; Start-Process "takeown" "/f $Drv\ /r /d y" -Wait; $Form.Cursor="Default"; [System.Windows.Forms.MessageBox]::Show("Done!","OK")
    } catch { [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Error") }
})

# --- RAW SECTOR SCANNER (ANTI-CRASH) ---
$BtnRawScan.Add_Click({
    try {
        if ($CboDisk.SelectedIndex -lt 0) { return }
        $DiskInfo = $CboDisk.SelectedItem.ToString().Split(" ")[0]
        
        if (-not ([System.Management.Automation.PSTypeName]'DiskReader').Type) {
            [System.Windows.Forms.MessageBox]::Show("ERROR: C# DiskReader Class could not be loaded.`nRestart script as Admin.", "Critical Error")
            return
        }

        $TxtRawLog.Text = "STARTING FULL RAW SCAN ON $DiskInfo...`r`n"
        $TxtRawLog.AppendText("Target: Entire Disk (ASCII + Unicode Scan)`r`n")
        $BtnRawScan.Enabled = $false; $Form.Cursor = "WaitCursor"
        
        $CurrentSector = 0
        $ChunkSectors = 40960 # Doc 20MB
        $Found = $false
        
        $DiskSizeObj = Get-WmiObject Win32_DiskDrive | Where {$_.DeviceID -eq $DiskInfo}
        $TotalSectors = if($DiskSizeObj){ $DiskSizeObj.TotalSectors } else { 20000000 }

        while ($CurrentSector -lt $TotalSectors) {
            if ($CurrentSector % ($ChunkSectors * 10) -eq 0) {
                $Pct = [Math]::Round(($CurrentSector / $TotalSectors) * 100, 1)
                $LblT.Text = "SCAN: $Pct%"; [System.Windows.Forms.Application]::DoEvents()
            }
            
            $SectorsToRead = $ChunkSectors
            if (($CurrentSector + $ChunkSectors) -gt $TotalSectors) {
                $SectorsToRead = $TotalSectors - $CurrentSector
            }
            if ($SectorsToRead -le 0) { break }

            try {
                $Buffer = [DiskReader]::ReadSector($DiskInfo, $CurrentSector, [int]$SectorsToRead)
            } catch {
                RawLog "Err at $CurrentSector"
                $Buffer = $null
            }
            
            if ($null -eq $Buffer -or $Buffer.Length -eq 0) { break }

            # 1. Check ASCII
            $TextAscii = [System.Text.Encoding]::Default.GetString($Buffer)
            if ($TextAscii -match "\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}") {
                $Key = $Matches[0]
                RawLog "!!! FOUND (ASCII): $Key"
                $Found = $true
                if ([System.Windows.Forms.MessageBox]::Show("TÌM THẤY KEY: $Key`n`nBạn có muốn dừng quét để thử Key này không?", "JACKPOT", "YesNo") -eq "Yes") {
                    $TxtManual.Text = $Key; $Tab.SelectedIndex = 0; $BtnRawScan.Enabled = $true; $Form.Cursor = "Default"; return
                }
            }

            # 2. Check Unicode
            $TextUni = [System.Text.Encoding]::Unicode.GetString($Buffer)
            if ($TextUni -match "\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}") {
                $Key = $Matches[0]
                RawLog "!!! FOUND (UNICODE): $Key"
                $Found = $true
                if ([System.Windows.Forms.MessageBox]::Show("TÌM THẤY KEY: $Key`n`nBạn có muốn dừng quét để thử Key này không?", "JACKPOT", "YesNo") -eq "Yes") {
                    $TxtManual.Text = $Key; $Tab.SelectedIndex = 0; $BtnRawScan.Enabled = $true; $Form.Cursor = "Default"; return
                }
            }

            $CurrentSector += $SectorsToRead
        }
        if (!$Found) { RawLog "Scan Completed. No Key." }
        $BtnRawScan.Enabled = $true; $Form.Cursor = "Default"
    } catch { [System.Windows.Forms.MessageBox]::Show("Error", "FATAL"); $BtnRawScan.Enabled = $true; $Form.Cursor = "Default" }
})

# --- SCANNERS & BF ---
$BtnScanFile.Add_Click({
    try {
        $TxtLog.Text="Scanning Files..."; $Form.Cursor="WaitCursor"
        $Drives = Get-PSDrive -PSProvider FileSystem
        foreach ($D in $Drives) {
            if ((Get-BitLockerVolume -MountPoint $D.Root -ErrorAction SilentlyContinue).VolumeStatus -eq "Locked") { continue }
            Log "Scan $($D.Root)..."; try {
                $Files = Get-ChildItem $D.Root -Include "*.txt","*.html","*.bek" -Recurse -ErrorAction SilentlyContinue | Where {$_.Length -lt 2MB}
                foreach ($F in $Files) {
                    if ((Get-Content $F.FullName -Raw) -match "\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}") {
                        $K=$Matches[0]; Log "FOUND: $K ($($F.Name))"; if ([System.Windows.Forms.MessageBox]::Show("Found: $K`nTry?","Found","YesNo")-eq"Yes"){$TxtManual.Text=$K;$Tab.SelectedIndex=0;return}
                    }
                    [System.Windows.Forms.Application]::DoEvents()
                }
            } catch {}
        }
        Log "Done."; $Form.Cursor="Default"
    } catch { [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Error") }
})
$BtnScanHiber.Add_Click({
    try {
        $TxtLog.Text="Scanning RAM Dump..."; $Form.Cursor="WaitCursor"
        $Drives = Get-PSDrive -PSProvider FileSystem
        foreach ($D in $Drives) {
            $P="$($D.Root)hiberfil.sys"; if (Test-Path $P) {
                Log "Scan $P..."; try {
                    $S=[System.IO.File]::Open($P,[System.IO.FileMode]::Open,[System.IO.FileAccess]::Read,[System.IO.FileShare]::ReadWrite)
                    $R=New-Object System.IO.StreamReader($S); $B=New-Object char[] 10485760
                    while (!$R.EndOfStream) {
                        $C=$R.Read($B,0,10485760); $Chunk=New-Object string($B,0,$C)
                        if ($Chunk -match "\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}-\d{6}") {
                            $K=$Matches[0]; Log "JACKPOT: $K"; $TxtManual.Text=$K; [System.Windows.Forms.MessageBox]::Show("JACKPOT! Key in RAM: $K","Success"); $Tab.SelectedIndex=0; $R.Close(); return
                        }
                        [System.Windows.Forms.Application]::DoEvents()
                    }
                    $R.Close()
                } catch { Log "Error reading file." }
            }
        }
        Log "Done."; $Form.Cursor="Default"
    } catch { [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Error") }
})
$BtnAD.Add_Click({ try{if(Get-Command Get-ADObject -ErrorAction SilentlyContinue){[System.Windows.Forms.MessageBox]::Show("Querying AD...","Info")}else{[System.Windows.Forms.MessageBox]::Show("Need RSAT Tools.","Error")}}catch{} })
$BtnWeb.Add_Click({ Start-Process "https://account.microsoft.com/devices/recoverykey" })
$BtnBF.Add_Click({
    if (!$Grid.SelectedRows.Count) { return }; $Drv=$Grid.SelectedRows[0].Cells[0].Value
    $Lines=$TxtPassList.Text -split "`r`n"; $i=0
    foreach ($P in $Lines) { if(![string]::IsNullOrWhiteSpace($P)){ $i++; $LblBFStat.Text="Try ($i): $P"; [System.Windows.Forms.Application]::DoEvents(); $Pr=Start-Process "manage-bde" "-unlock $Drv -pw $P" -NoNewWindow -PassThru -Wait; if($Pr.ExitCode -eq 0){$LblBFStat.Text="OK";[System.Windows.Forms.MessageBox]::Show("Pass: $P","Success");Load-Drives;return} } }
    [System.Windows.Forms.MessageBox]::Show("Fail all.","Info")
})

# INITIAL LOAD (1 TIME)
Load-Drives

$Form.ShowDialog() | Out-Null
