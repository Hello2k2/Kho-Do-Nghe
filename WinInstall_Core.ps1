<#
  WININSTALL CORE V22.1 (NO-DEPENDENCY EDITION)
  Author: Phat Tan PC

  FIX V22.1:
  1. REMOVE SYSTEM.DRAWING: Sử dụng tên màu (String) thay vì Object Color để tránh lỗi thiếu thư viện trên WinPE.
  2. ROBUST UI: Giao diện vẫn giữ Dark Mode nhưng dùng mã màu Hex/Name an toàn.
  3. SMART ENGINE: Vẫn giữ nguyên logic cài đặt thông minh.
#>

# --- 1. FORCE ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; Exit 
}

# --- GLOBAL VARIABLES ---
$Global:LogPath     = "$env:SystemDrive\WinInstall_V22.log"
$Global:SelSource   = $null
$Global:SelWinPart  = $null
$Global:SelBootPart = $null
$Global:IsoMounted  = $null

# --- HELPER FUNCTIONS ---

function Log-Write { 
    param([string]$Msg) 
    $Time = Get-Date -Format "HH:mm:ss"
    $Line = "[$Time] $Msg"
    try { 
        $Global:TxtLog.AppendText("$Line`r`n")
        $Global:TxtLog.SelectionStart = $Global:TxtLog.Text.Length
        $Global:TxtLog.ScrollToCaret()
    } catch {}
    try { Add-Content -Path $Global:LogPath -Value $Line -Force } catch {} 
}

function Exec-Cmd { 
    param([string]$Command)
    Log-Write "EXEC> $Command"
    $P = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $Command" -NoNewWindow -Wait -PassThru
    return $P.ExitCode
}

# [NEW] SMART ENGINE: Native Library vs CLI
function Smart-Apply-Image {
    param($ImagePath, $Index, $ApplyDir)
    
    Log-Write "--- STARTING SMART ENGINE ---"
    
    # Cách 1: Dùng Thư viện PowerShell (Xịn nhất)
    if (Get-Command Expand-WindowsImage -ErrorAction SilentlyContinue) {
        Log-Write "[ENGINE] Using Native PowerShell Library (Expand-WindowsImage)..."
        try {
            Expand-WindowsImage -ImagePath $ImagePath -Index $Index -ApplyPath $ApplyDir -ErrorAction Stop
            Log-Write "[ENGINE] Library Success."
            return
        } catch {
            Log-Write "[ENGINE] Library Error: $_. Switching to DISM..."
        }
    } else {
        Log-Write "[ENGINE] Native Library not found. Using DISM CLI..."
    }

    # Cách 2: DISM truyền thống (Fallback)
    $Res = Exec-Cmd "dism /Apply-Image /ImageFile:`"$ImagePath`" /Index:$Index /ApplyDir:$ApplyDir"
    if ($Res -eq 0) { Log-Write "[ENGINE] DISM Success." } else { Log-Write "[ENGINE] DISM Failed. Code: $Res" }
}

function Mount-All-Partitions {
    Log-Write "System: Scanning & Mounting hidden volumes..."
    try {
        $Vols = Get-WmiObject Win32_Volume
        foreach ($V in $Vols) {
            if ([string]::IsNullOrEmpty($V.DriveLetter)) {
                try { $V.Mount(); Log-Write " + Mounted: $($V.Label) ($($V.FileSystem))" } catch {}
            }
        }
    } catch {}
}

# --- GUI INIT ---
Add-Type -AssemblyName System.Windows.Forms
# KHÔNG ADD SYSTEM.DRAWING NỮA

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "WININSTALL CORE V22.1 (SAFE COLORS)"
$Form.Size = "1100, 750"
$Form.StartPosition = "CenterScreen"
$Form.BackColor = "30, 30, 30" # String Color
$Form.ForeColor = "White"

# Title
$LblTitle = New-Object System.Windows.Forms.Label
$LblTitle.Text = "WININSTALL V22.1 [ULTIMATE]"
$LblTitle.Font = New-Object System.Drawing.Font("Consolas", 24, [System.Drawing.FontStyle]::Bold)
$LblTitle.ForeColor = "Cyan"
$LblTitle.AutoSize = $true
$LblTitle.Location = "20, 15"
$Form.Controls.Add($LblTitle)

# === LAYOUT PANELS ===

# 1. SOURCE PANEL
$PnlSource = New-Object System.Windows.Forms.Panel; $PnlSource.Location="20,70"; $PnlSource.Size="1040,100"; $PnlSource.BackColor="45, 45, 48"; $PnlSource.BorderStyle="FixedSingle"
$Form.Controls.Add($PnlSource)

$LblSrc = New-Object System.Windows.Forms.Label; $LblSrc.Text="1. SOURCE (ISO/WIM)"; $LblSrc.Location="10,10"; $LblSrc.AutoSize=$true; $LblSrc.Font=New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold); $PnlSource.Controls.Add($LblSrc)

$BtnISO = New-Object System.Windows.Forms.Button; $BtnISO.Text="BROWSE"; $BtnISO.Location="10,35"; $BtnISO.Size="100,30"; $BtnISO.FlatStyle="Flat"; $BtnISO.BackColor="DodgerBlue"; $PnlSource.Controls.Add($BtnISO)
$TxtISO = New-Object System.Windows.Forms.TextBox; $TxtISO.Location="120,37"; $TxtISO.Size="650,25"; $TxtISO.BackColor="30, 30, 30"; $TxtISO.ForeColor="White"; $TxtISO.ReadOnly=$true; $PnlSource.Controls.Add($TxtISO)
$BtnMount = New-Object System.Windows.Forms.Button; $BtnMount.Text="MOUNT / LOAD"; $BtnMount.Location="780,35"; $BtnMount.Size="120,30"; $BtnMount.FlatStyle="Flat"; $BtnMount.BackColor="Green"; $PnlSource.Controls.Add($BtnMount)
$CbIndex = New-Object System.Windows.Forms.ComboBox; $CbIndex.Location="120,65"; $CbIndex.Size="650,25"; $CbIndex.DropDownStyle="DropDownList"; $CbIndex.BackColor="30, 30, 30"; $CbIndex.ForeColor="White"; $PnlSource.Controls.Add($CbIndex)

# 2. TARGET PANEL
$PnlTarget = New-Object System.Windows.Forms.Panel; $PnlTarget.Location="20,180"; $PnlTarget.Size="600,400"; $PnlTarget.BackColor="45, 45, 48"; $PnlTarget.BorderStyle="FixedSingle"
$Form.Controls.Add($PnlTarget)

$LblTgt = New-Object System.Windows.Forms.Label; $LblTgt.Text="2. TARGET & BOOT (Right Click to Select)"; $LblTgt.Location="10,10"; $LblTgt.AutoSize=$true; $LblTgt.Font=New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold); $PnlTarget.Controls.Add($LblTgt)

$GridPart = New-Object System.Windows.Forms.DataGridView; $GridPart.Location="10,40"; $GridPart.Size="580,300"; $GridPart.BackgroundColor="30, 30, 30"; $GridPart.ForeColor="Black"; $GridPart.RowHeadersVisible=$false; $GridPart.SelectionMode="FullRowSelect"; $GridPart.ReadOnly=$true; $GridPart.AutoSizeColumnsMode="Fill"
[void]$GridPart.Columns.Add("Ltr","Let"); [void]$GridPart.Columns.Add("Label","Label"); [void]$GridPart.Columns.Add("Size","Size (GB)"); [void]$GridPart.Columns.Add("FS","FS"); [void]$GridPart.Columns.Add("Role","ROLE")
$PnlTarget.Controls.Add($GridPart)

$BtnScan = New-Object System.Windows.Forms.Button; $BtnScan.Text="RE-SCAN DRIVES"; $BtnScan.Location="10,350"; $BtnScan.Size="580,40"; $BtnScan.FlatStyle="Flat"; $BtnScan.BackColor="DodgerBlue"; $PnlTarget.Controls.Add($BtnScan)

# 3. ACTION PANEL
$PnlAct = New-Object System.Windows.Forms.Panel; $PnlAct.Location="640,180"; $PnlAct.Size="420,400"; $PnlAct.BackColor="45, 45, 48"; $PnlAct.BorderStyle="FixedSingle"
$Form.Controls.Add($PnlAct)

$LblAct = New-Object System.Windows.Forms.Label; $LblAct.Text="3. EXECUTION"; $LblAct.Location="10,10"; $LblAct.AutoSize=$true; $LblAct.Font=New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold); $PnlAct.Controls.Add($LblAct)

# Options
$ChkFmt = New-Object System.Windows.Forms.CheckBox; $ChkFmt.Text="Format Target Drive (NTFS)"; $ChkFmt.Location="20,40"; $ChkFmt.AutoSize=$true; $ChkFmt.Checked=$true; $PnlAct.Controls.Add($ChkFmt)
$ChkBoot = New-Object System.Windows.Forms.CheckBox; $ChkBoot.Text="Rebuild Boot (BCDBOOT)"; $ChkBoot.Location="20,70"; $ChkBoot.AutoSize=$true; $ChkBoot.Checked=$true; $PnlAct.Controls.Add($ChkBoot)

# Buttons
$BtnApply = New-Object System.Windows.Forms.Button; $BtnApply.Text="🔥 START DEPLOYMENT (Thợ)"; $BtnApply.Location="20,110"; $BtnApply.Size="380,60"; $BtnApply.FlatStyle="Flat"; $BtnApply.BackColor="DarkRed"; $BtnApply.Font=New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold); $PnlAct.Controls.Add($BtnApply)

$BtnSetup = New-Object System.Windows.Forms.Button; $BtnSetup.Text="💿 RUN SETUP.EXE (Gốc)"; $BtnSetup.Location="20,180"; $BtnSetup.Size="380,50"; $BtnSetup.FlatStyle="Flat"; $BtnSetup.BackColor="Green"; $PnlAct.Controls.Add($BtnSetup)

$BtnWinToHDD = New-Object System.Windows.Forms.Button; $BtnWinToHDD.Text="🛠️ DOWNLOAD WINTOHDD"; $BtnWinToHDD.Location="20,240"; $BtnWinToHDD.Size="380,50"; $BtnWinToHDD.FlatStyle="Flat"; $BtnWinToHDD.BackColor="Gray"; $PnlAct.Controls.Add($BtnWinToHDD)

# Labels for Selection
$LblSelWin = New-Object System.Windows.Forms.Label; $LblSelWin.Text="Target: [NONE]"; $LblSelWin.Location="20,310"; $LblSelWin.AutoSize=$true; $LblSelWin.ForeColor="Yellow"; $PnlAct.Controls.Add($LblSelWin)
$LblSelBoot = New-Object System.Windows.Forms.Label; $LblSelBoot.Text="Boot: [NONE]"; $LblSelBoot.Location="20,340"; $LblSelBoot.AutoSize=$true; $LblSelBoot.ForeColor="Magenta"; $PnlAct.Controls.Add($LblSelBoot)

# 4. LOG PANEL
$Global:TxtLog = New-Object System.Windows.Forms.TextBox; $Global:TxtLog.Location="20,590"; $Global:TxtLog.Size="1040,110"; $Global:TxtLog.Multiline=$true; $Global:TxtLog.BackColor="Black"; $Global:TxtLog.ForeColor="Lime"; $Global:TxtLog.ReadOnly=$true; $Global:TxtLog.ScrollBars="Vertical"; $Global:TxtLog.Font=New-Object System.Drawing.Font("Consolas", 9)
$Form.Controls.Add($Global:TxtLog)

# =========================
#   LOGIC
# =========================

function Load-Grid {
    $GridPart.Rows.Clear()
    Mount-All-Partitions
    $Vols = Get-WmiObject Win32_Volume
    foreach ($V in $Vols) {
        if ($V.DriveLetter) {
            $Size = [math]::Round($V.Capacity / 1GB, 1)
            $Ltr = $V.DriveLetter
            $Status = ""
            if ($Ltr -eq $Global:SelWinPart) { $Status = "WIN TARGET" }
            if ($Ltr -eq $Global:SelBootPart) { $Status = "BOOT SYSTEM" }
            $Row = $GridPart.Rows.Add($Ltr, $V.Label, $Size, $V.FileSystem, $Status)
            
            # Tô màu bằng Style an toàn
            if ($Status -eq "WIN TARGET") { 
                $GridPart.Rows[$Row].DefaultCellStyle.BackColor = "Maroon"
                $GridPart.Rows[$Row].DefaultCellStyle.ForeColor = "White" 
            }
            if ($Status -eq "BOOT SYSTEM") { 
                $GridPart.Rows[$Row].DefaultCellStyle.BackColor = "DarkGreen"
                $GridPart.Rows[$Row].DefaultCellStyle.ForeColor = "White" 
            }
        }
    }
}

# CONTEXT MENU
$Cms = New-Object System.Windows.Forms.ContextMenuStrip
$MiWin = $Cms.Items.Add("Set as WINDOWS Partition (Format & Install)")
$MiBoot = $Cms.Items.Add("Set as BOOT Partition (EFI/System)")

$MiWin.Add_Click({ 
    if($GridPart.SelectedRows.Count -gt 0){ 
        $Global:SelWinPart = $GridPart.SelectedRows[0].Cells[0].Value
        $LblSelWin.Text = "Target: $($Global:SelWinPart)"
        Load-Grid
    } 
})
$MiBoot.Add_Click({ 
    if($GridPart.SelectedRows.Count -gt 0){ 
        $Global:SelBootPart = $GridPart.SelectedRows[0].Cells[0].Value
        $LblSelBoot.Text = "Boot: $($Global:SelBootPart)"
        Load-Grid
    } 
})
$GridPart.ContextMenuStrip = $Cms

# EVENTS
$BtnScan.Add_Click({ Load-Grid })

$BtnISO.Add_Click({ 
    $OFD = New-Object System.Windows.Forms.OpenFileDialog
    $OFD.Filter = "Disk Images|*.iso;*.wim;*.esd"
    if($OFD.ShowDialog() -eq "OK") { $TxtISO.Text = $OFD.FileName } 
})

$BtnMount.Add_Click({
    if(!$TxtISO.Text){return}
    Log-Write "Analyzing Source..."
    $Src = $TxtISO.Text
    
    if ($Src.EndsWith(".iso")) {
        Mount-DiskImage $Src -ErrorAction SilentlyContinue | Out-Null
        $Vol = (Get-DiskImage $Src | Get-Volume).DriveLetter + ":"
        $Global:IsoMounted = $Vol
        Log-Write "ISO Mounted at: $Vol"
        $Wim = "$Vol\sources\install.wim"
        if (!(Test-Path $Wim)) { $Wim = "$Vol\sources\install.esd" }
    } else {
        $Wim = $Src
    }
    
    $Global:SelSource = $Wim
    Log-Write "Install File: $Wim"
    $CbIndex.Items.Clear()
    
    # Get Index Info
    if (Get-Command Get-WindowsImage -ErrorAction SilentlyContinue) {
        $Info = Get-WindowsImage -ImagePath $Wim
        foreach ($I in $Info) { $CbIndex.Items.Add("Index $($I.ImageIndex): $($I.ImageName)") | Out-Null }
    } else {
        # Fallback DISM
        $Raw = cmd /c "dism /Get-WimInfo /WimFile:`"$Wim`""
        $Raw | Select-String "Name :" | % { $CbIndex.Items.Add($_.ToString().Trim()) | Out-Null }
    }
    if($CbIndex.Items.Count -gt 0){$CbIndex.SelectedIndex=0}
})

$BtnApply.Add_Click({
    if (!$Global:SelSource) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn Source!", "Error"); return }
    if (!$Global:SelWinPart) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn Ổ Windows!", "Error"); return }
    if (!$Global:SelBootPart) { [System.Windows.Forms.MessageBox]::Show("Chưa chọn Ổ Boot!", "Error"); return }

    if ([System.Windows.Forms.MessageBox]::Show("BẠN CÓ CHẮC CHẮN KHÔNG?`n`nDữ liệu trên ổ $($Global:SelWinPart) sẽ bị xóa sạch!", "Confirm", "YesNo", "Warning") -eq "Yes") {
        $Form.Cursor = "WaitCursor"
        $Idx = $CbIndex.SelectedIndex + 1
        
        # 1. Format
        if ($ChkFmt.Checked) {
            Log-Write "Formatting $($Global:SelWinPart)..."
            cmd /c "format $($Global:SelWinPart) /fs:ntfs /q /y /v:Windows"
        }
        
        # 2. Apply (SMART ENGINE)
        Smart-Apply-Image -ImagePath $Global:SelSource -Index $Idx -ApplyDir $Global:SelWinPart
        
        # 3. Boot
        if ($ChkBoot.Checked) {
            Log-Write "Creating Boot Files..."
            Exec-Cmd "bcdboot $($Global:SelWinPart)\Windows /s $($Global:SelBootPart) /f ALL"
        }
        
        Log-Write "ALL DONE. READY TO REBOOT."
        $Form.Cursor = "Default"
        [System.Windows.Forms.MessageBox]::Show("Cài đặt thành công!", "Success")
    }
})

$BtnSetup.Add_Click({
    if ($Global:IsoMounted) {
        $Setup = "$($Global:IsoMounted)\setup.exe"
        if (Test-Path $Setup) { Start-Process $Setup } else { Log-Write "Setup.exe not found!" }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Chưa Mount ISO!", "Error")
    }
})

$BtnWinToHDD.Add_Click({
    $Url = "https://github.com/Hello2k2/Kho-Do-Nghe/releases/download/v1.0/WinToHDD.exe"
    $Dest = "$env:TEMP\WinToHDD.exe"
    Log-Write "Downloading WinToHDD..."
    try { (New-Object System.Net.WebClient).DownloadFile($Url, $Dest); Start-Process $Dest } catch { Log-Write "Download Error." }
})

# Start
Load-Grid
$Form.ShowDialog() | Out-Null
