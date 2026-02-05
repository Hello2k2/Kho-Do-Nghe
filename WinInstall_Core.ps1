<#
  WININSTALL CORE V18.4 (COMPACT)
  - Auto detect UEFI/BIOS
  - Auto find System partition (EFI FAT32 or NTFS System Reserved)
  - Rebuild boot (bcdboot + optional bootsect)
  - Create WinPE entry with [locate] ramdisk
#>

# --- ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator"
)) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

# --- INIT ---
[Console]::OutputEncoding = [Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$Global:SelectedInstall = $null
$Global:IsoMounted = $null
$Global:WimFile = $null
$Global:CustomXmlPath = ""

# --- THEME ---
$Theme = @{
  Bg=[Drawing.Color]::FromArgb(20,20,25); Text="White"; Cyan="DeepSkyBlue"
}

# --- LOG ---
$TxtLog = New-Object Windows.Forms.TextBox
function Log($m){ $TxtLog.AppendText("[$([DateTime]::Now:HH:mm)] $m`r`n"); $TxtLog.ScrollToCaret() }

# =========================
#   CORE (COMPACT)
# =========================

function Get-FirmwareMode {
  try {
    return @("BIOS","UEFI")[((Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control" -Name PEFirmwareType -EA Stop).PEFirmwareType -eq 2)]
  } catch { return "BIOS" }
}

function DP($scriptText){
  $tmp = Join-Path $env:TEMP ("dp_{0}.txt" -f ([guid]::NewGuid().ToString("N")))
  $scriptText | Set-Content $tmp -Encoding ASCII
  $out = & diskpart /s $tmp 2>&1
  Remove-Item $tmp -Force -EA SilentlyContinue
  return $out
}

function Get-SystemPartition {
  # returns: @{Mode; Letter; WasAssigned}
  $mode = Get-FirmwareMode
  Log "Detect Firmware: $mode"

  $dp = DP "list vol`nexit"
  $lines = ($dp -split "`r?`n") | Where-Object { $_ -match '^ *Volume\s+\d+' }

  # Helper: assign S: by volume number
  function AssignS([int]$volNo){
    $out = DP "select vol $volNo`nassign letter=S`nexit"
    Log ("Assign S: => " + (($out -join ' ') -replace '\s+',' '))
    return "S:"
  }

  if ($mode -eq "UEFI") {
    # Prefer: FAT32 + (System) if present, else any FAT32 50-600MB
    foreach($ln in $lines){
      if ($ln -match 'Volume\s+(\d+)\s+([A-Z]?)\s+.*\sFAT32\s+.*\s+(\d+)\s+MB\s+.*System') {
        $no=[int]$matches[1]; $ltr=$matches[2]; return @{Mode="UEFI"; Letter=($ltr?("$ltr:"):(AssignS $no)); WasAssigned=(-not $ltr)}
      }
    }
    foreach($ln in $lines){
      if ($ln -match 'Volume\s+(\d+)\s+([A-Z]?)\s+.*\sFAT32\s+.*\s+(\d+)\s+MB') {
        $no=[int]$matches[1]; $ltr=$matches[2]; $mb=[int]$matches[3]
        if ($mb -ge 50 -and $mb -le 600) { return @{Mode="UEFI"; Letter=($ltr?("$ltr:"):(AssignS $no)); WasAssigned=(-not $ltr)} }
      }
    }
    throw "Không tìm thấy EFI (FAT32)!"
  }
  else {
    # BIOS: NTFS + Info=System (thường 50-600MB, letter trống)
    foreach($ln in $lines){
      if ($ln -match 'Volume\s+(\d+)\s+([A-Z]?)\s+.*\sNTFS\s+Partition\s+(\d+)\s+MB\s+.*System') {
        $no=[int]$matches[1]; $ltr=$matches[2]
        return @{Mode="BIOS"; Letter=($ltr?("$ltr:"):(AssignS $no)); WasAssigned=(-not $ltr)}
      }
    }
    # fallback: NTFS không letter 50-600MB
    foreach($ln in $lines){
      if ($ln -match 'Volume\s+(\d+)\s+([A-Z]?)\s+.*\sNTFS\s+Partition\s+(\d+)\s+MB') {
        $no=[int]$matches[1]; $ltr=$matches[2]; $mb=[int]$matches[3]
        if (-not $ltr -and $mb -ge 50 -and $mb -le 600) { return @{Mode="BIOS"; Letter=(AssignS $no); WasAssigned=$true} }
      }
    }
    throw "Không tìm thấy System Reserved (NTFS System)!"
  }
}

function Rebuild-Boot([string]$WinDrive){
  $sys = Get-SystemPartition
  Log "System Partition: $($sys.Letter) (Mode=$($sys.Mode))"

  if ($sys.Mode -eq "UEFI") {
    $o = & bcdboot "$WinDrive\Windows" /s $sys.Letter /f UEFI 2>&1
    Log ("bcdboot UEFI => " + (($o -join ' ') -replace '\s+',' '))
  } else {
    try {
      $o1 = & bootsect /nt60 $sys.Letter /mbr 2>&1
      Log ("bootsect => " + (($o1 -join ' ') -replace '\s+',' '))
    } catch { Log "WARN: bootsect thiếu (lite) - skip." }
    $o2 = & bcdboot "$WinDrive\Windows" /s $sys.Letter /f BIOS 2>&1
    Log ("bcdboot BIOS => " + (($o2 -join ' ') -replace '\s+',' '))
  }
  try { & bcdedit /timeout 10 | Out-Null } catch {}
  return $sys
}

function Add-WinPEEntryLocate([string]$WinSourcePath){
  Log "Configuring WinPE BCD (LOCATE)..."
  & bcdedit /create "{ramdiskoptions}" /d "PhatTan Ramdisk" /f | Out-Null
  & bcdedit /set "{ramdiskoptions}" ramdisksdidevice locate | Out-Null
  & bcdedit /set "{ramdiskoptions}" ramdisksdipath "\WinSource_PhatTan\boot\boot.sdi" | Out-Null

  $out = & bcdedit /create /d "PHAT TAN INSTALLER (V18.4 - LOCATE)" /application osloader
  $guid = ([regex]'{[a-z0-9-]{36}}').Match($out).Value
  if(!$guid){ throw "Không lấy được GUID" }

  $dev = "ramdisk=[locate]\WinSource_PhatTan\sources\boot.wim,{ramdiskoptions}"
  & bcdedit /set $guid device $dev | Out-Null
  & bcdedit /set $guid osdevice $dev | Out-Null
  & bcdedit /set $guid path \windows\system32\boot\winload.exe | Out-Null
  & bcdedit /set $guid systemroot \windows | Out-Null
  & bcdedit /set $guid winpe yes | Out-Null
  & bcdedit /set $guid detecthal yes | Out-Null

  try { & bcdedit /displayorder $guid /addfirst | Out-Null } catch {}
  try { & bcdedit /timeout 10 | Out-Null } catch {}

  Log "-> ENTRY OK: $guid"
  Log "-> DEVICE: $dev"
  return $guid
}

# =========================
#   GUI (KEEP IT SIMPLE)
# =========================

$Form = New-Object Windows.Forms.Form
$Form.Text="CORE INSTALLER V18.4 (COMPACT)"
$Form.Size="1000,750"
$Form.StartPosition="CenterScreen"
$Form.BackColor=$Theme.Bg
$Form.ForeColor=$Theme.Text
$Form.FormBorderStyle="FixedSingle"
$Form.MaximizeBox=$false

$LblTitle = New-Object Windows.Forms.Label
$LblTitle.Text="🚀 WINDOWS ULTIMATE INSTALLER V18.4 (COMPACT)"
$LblTitle.Font=New-Object Drawing.Font("Segoe UI",20,[Drawing.FontStyle]::Bold)
$LblTitle.ForeColor=$Theme.Cyan
$LblTitle.AutoSize=$true
$LblTitle.Location="20,15"
$Form.Controls.Add($LblTitle)

# Buttons + Index
$BtnISO = New-Object Windows.Forms.Button
$BtnISO.Text="📂 CHỌN ISO"; $BtnISO.Location="20,70"; $BtnISO.Size="120,30"; $BtnISO.BackColor="DimGray"
$Form.Controls.Add($BtnISO)

$TxtISO = New-Object Windows.Forms.TextBox
$TxtISO.Location="150,72"; $TxtISO.Size="520,25"; $TxtISO.ReadOnly=$true
$Form.Controls.Add($TxtISO)

$BtnMount = New-Object Windows.Forms.Button
$BtnMount.Text="💿 MOUNT"; $BtnMount.Location="680,70"; $BtnMount.Size="110,30"; $BtnMount.BackColor="DarkGreen"
$Form.Controls.Add($BtnMount)

$CbIndex = New-Object Windows.Forms.ComboBox
$CbIndex.Location="20,110"; $CbIndex.Size="770,30"; $CbIndex.DropDownStyle="DropDownList"
$Form.Controls.Add($CbIndex)

# Drive pick (simple: textbox)
$LblTarget = New-Object Windows.Forms.Label
$LblTarget.Text="Ổ CÀI (VD: C)"; $LblTarget.Location="20,150"; $LblTarget.AutoSize=$true
$Form.Controls.Add($LblTarget)

$TxtTarget = New-Object Windows.Forms.TextBox
$TxtTarget.Location="120,147"; $TxtTarget.Size="60,25"; $TxtTarget.Text=($env:SystemDrive.TrimEnd(":"))
$Form.Controls.Add($TxtTarget)

$BtnRun = New-Object Windows.Forms.Button
$BtnRun.Text="MODE 2: HEADLESS DISM (AUTO + REBUILD + LOCATE)"; $BtnRun.Location="20,190"; $BtnRun.Size="770,45"
$BtnRun.BackColor="Orange"; $BtnRun.Font=New-Object Drawing.Font("Segoe UI",10,[Drawing.FontStyle]::Bold)
$Form.Controls.Add($BtnRun)

# Log box
$TxtLog.Location="20,250"; $TxtLog.Size="945,440"
$TxtLog.Multiline=$true; $TxtLog.BackColor="Black"; $TxtLog.ForeColor="Lime"
$TxtLog.ReadOnly=$true; $TxtLog.ScrollBars="Vertical"
$Form.Controls.Add($TxtLog)

# --- EVENTS ---
$BtnISO.Add_Click({
  $ofd=New-Object Windows.Forms.OpenFileDialog
  $ofd.Filter="ISO Files|*.iso"
  if($ofd.ShowDialog() -eq "OK"){ $TxtISO.Text=$ofd.FileName }
})

$BtnMount.Add_Click({
  if([string]::IsNullOrEmpty($TxtISO.Text)){ [Windows.Forms.MessageBox]::Show("Chưa chọn ISO!"); return }
  Log "Mounting ISO..."
  try{
    $img=Get-DiskImage -ImagePath $TxtISO.Text
    if(-not $img.Attached){ Mount-DiskImage -ImagePath $TxtISO.Text -StorageType ISO -EA Stop | Out-Null; Start-Sleep 2 }
    $d=(Get-DiskImage -ImagePath $TxtISO.Text | Get-Volume -EA 0).DriveLetter
    if(-not $d){
      $cd=Get-WmiObject Win32_LogicalDisk -Filter "DriveType=5"
      foreach($drv in $cd){
        if((Test-Path "$($drv.DeviceID)\sources\install.wim") -or (Test-Path "$($drv.DeviceID)\sources\install.esd")){
          $d=$drv.DeviceID.TrimEnd(":"); break
        }
      }
    }
    if(-not $d){ throw "Cannot detect ISO drive letter" }
    $Global:IsoMounted="$d`:"
    Log "Mounted: $Global:IsoMounted"

    $wim="$($Global:IsoMounted)\sources\install.wim"
    if(!(Test-Path $wim)){ $wim="$($Global:IsoMounted)\sources\install.esd" }
    $Global:WimFile=$wim

    $CbIndex.Items.Clear()
    & dism /Get-WimInfo /WimFile:$wim | Select-String "Name :" | ForEach-Object {
      $CbIndex.Items.Add($_.ToString().Split(":")[1].Trim()) | Out-Null
    }
    if($CbIndex.Items.Count -gt 0){ $CbIndex.SelectedIndex=0 }
  } catch { Log "Mount ERR: $_" }
})

$BtnRun.Add_Click({
  if(-not $Global:IsoMounted){ [Windows.Forms.MessageBox]::Show("Chưa Mount ISO!"); return }

  $target = ($TxtTarget.Text.Trim() + ":").ToUpper()
  if($target.Length -ne 2 -or $target[1] -ne ":"){ [Windows.Forms.MessageBox]::Show("Nhập ổ cài dạng: C"); return }

  $index = 1
  if($CbIndex.Items.Count -gt 0 -and $CbIndex.SelectedIndex -ge 0){ $index=$CbIndex.SelectedIndex+1 }

  # pick source drive >8GB free (not target)
  $source = $null
  $dr = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
  foreach($d in $dr){ if($d.DeviceID -ne $target -and $d.FreeSpace -gt 8GB){ $source=$d.DeviceID; break } }
  if(-not $source){ [Windows.Forms.MessageBox]::Show("Cần 1 ổ phụ > 8GB (khác ổ cài)!"); return }

  if([Windows.Forms.MessageBox]::Show("Source: $source -> Target: $target`nIndex: $index`nTiếp tục?","PhatTan", "YesNo","Warning") -ne "Yes"){ return }

  $Form.Cursor="WaitCursor"
  Log "--- START ---"

  try{ Rebuild-Boot -WinDrive $target | Out-Null } catch { Log "WARN rebuild boot: $_" }

  $winSource="$source\WinSource_PhatTan"
  try{
    if(Test-Path $winSource){ Remove-Item $winSource -Recurse -Force }
    New-Item -ItemType Directory -Path "$winSource\sources" -Force | Out-Null
    New-Item -ItemType Directory -Path "$winSource\boot" -Force | Out-Null
  } catch { Log "ERR create WinSource: $_"; $Form.Cursor="Default"; return }

  try{
    Copy-Item "$Global:IsoMounted\sources\boot.wim" "$winSource\sources\boot.wim" -Force
    Copy-Item "$Global:IsoMounted\boot\boot.sdi" "$winSource\boot\boot.sdi" -Force
    Copy-Item "$Global:IsoMounted\setup.exe" "$winSource\setup.exe" -Force

    $inst="$Global:IsoMounted\sources\install.wim"
    $isEsd=$false
    if(!(Test-Path $inst)){ $inst="$Global:IsoMounted\sources\install.esd"; $isEsd=$true }
    if($isEsd){ Copy-Item $inst "$winSource\sources\install.esd" -Force; $img="%~dp0sources\install.esd" }
    else      { Copy-Item $inst "$winSource\sources\install.wim" -Force; $img="%~dp0sources\install.wim" }

    cmd /c "label $target WIN_TARGET" | Out-Null
  } catch { Log "ERR copy/label: $_"; $Form.Cursor="Default"; return }

  $cmd = @"
@echo off
title PHAT TAN V18.4 AUTO INSTALL
setlocal enabledelayedexpansion
for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
  vol %%d: 2>nul | find "WIN_TARGET" >nul && set TARGET=%%d:
)
if "%TARGET%"=="" (echo [ERR] No WIN_TARGET&timeout /t 5>nul&exit /b 1)
format %TARGET% /fs:ntfs /q /y /v:Windows
dism /Apply-Image /ImageFile:"$img" /Index:$index /ApplyDir:%TARGET%
bcdboot %TARGET%\Windows /f ALL
wpeutil reboot
"@
  [IO.File]::WriteAllText("$winSource\AutoInstall.cmd",$cmd,[Text.Encoding]::ASCII)

  $xml=@"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
  <settings pass="windowsPE">
    <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <RunSynchronous>
        <RunSynchronousCommand wcm:action="add">
          <Order>1</Order>
          <Path>cmd /c for %%%%i in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist %%%%i:\WinSource_PhatTan\AutoInstall.cmd call %%%%i:\WinSource_PhatTan\AutoInstall.cmd</Path>
        </RunSynchronousCommand>
      </RunSynchronous>
    </component>
  </settings>
</unattend>
"@
  [IO.File]::WriteAllText("$winSource\autounattend.xml",$xml,[Text.Encoding]::UTF8)

  try{ Add-WinPEEntryLocate -WinSourcePath $winSource | Out-Null } catch { Log "ERR add entry: $_"; $Form.Cursor="Default"; return }

  $Form.Cursor="Default"
  if([Windows.Forms.MessageBox]::Show("Done! Restart ngay?","Success","YesNo") -eq "Yes"){ Restart-Computer -Force }
})

$Form.ShowDialog() | Out-Null
