<#
.SYNOPSIS
    PhattanPC Context Menu Manager Ultimate - RGB Edition (100 FEATURES)
.DESCRIPTION
    Quản lý 100 tính năng chuột phải (10 Tab x 10 Tính năng).
    Giao diện siêu cấp RGB + Log theo thời gian thực + Fallback WinPE.
    Tác giả: Phát Tấn PC
#>

# ==============================================================================
# 1. BẮT BUỘC CHẠY QUYỀN ADMINISTRATOR
# ==============================================================================
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Đang yêu cầu quyền Administrator..."
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# ==============================================================================
# 2. DATABASE TÍNH NĂNG (10 TABS X 10 TÍNH NĂNG = 100 TÍNH NĂNG)
# ==============================================================================
$MenuGroups = @{
    "System"      = @{ Name = "🛠 System"; RootKey = "HKCR:\Directory\Background\shell" } 
    "Fix"         = @{ Name = "🚑 Cứu Hộ"; RootKey = "HKCR:\Directory\Background\shell" }
    "Network"     = @{ Name = "🌐 Network"; RootKey = "HKCR:\Directory\Background\shell" }
    "Dev"         = @{ Name = "💻 Tweak"; RootKey = "HKCR:\Directory\Background\shell" }
    "Gaming"      = @{ Name = "🎮 Gaming"; RootKey = "HKCR:\Directory\Background\shell" }    
    "Apps"        = @{ Name = "🚀 Ứng Dụng"; RootKey = "HKCR:\Directory\Background\shell" }  
    "Personalize" = @{ Name = "🎨 Giao Diện"; RootKey = "HKCR:\Directory\Background\shell" } 
    "FileOps"     = @{ Name = "📁 Xử Lý File"; RootKey = "HKCR:\*\shell" }               
    "FolderOps"   = @{ Name = "📂 Thư Mục"; RootKey = "HKCR:\Directory\shell" }          
    "DriveOps"    = @{ Name = "🖴 Ổ Cứng"; RootKey = "HKCR:\Drive\shell" }                  
}

$MenuItems = @(
    # --- NHÓM 1: SYSTEM & POWER (10) ---
    @{ Group = "System"; ID = "SafeMode"; Name = "Reboot to Safe Mode"; Cmd = 'cmd.exe /c bcdedit /set {current} safeboot minimal & shutdown /r /t 0' }
    @{ Group = "System"; ID = "SafeModeNet"; Name = "Reboot Safe Mode (Network)"; Cmd = 'cmd.exe /c bcdedit /set {current} safeboot network & shutdown /r /t 0' }
    @{ Group = "System"; ID = "NormalMode"; Name = "Reboot Normal Mode"; Cmd = 'cmd.exe /c bcdedit /deletevalue {current} safeboot & shutdown /r /t 0' }
    @{ Group = "System"; ID = "BootUEFI"; Name = "Boot to UEFI/BIOS"; Cmd = 'cmd.exe /c shutdown /r /fw /t 0' }
    @{ Group = "System"; ID = "RestartExp"; Name = "Restart Explorer"; Cmd = 'cmd.exe /c taskkill /f /im explorer.exe & start explorer.exe' }
    @{ Group = "System"; ID = "ClearClip"; Name = "Clear Clipboard"; Cmd = 'cmd.exe /c echo off | clip' }
    @{ Group = "System"; ID = "LockPC"; Name = "Lock Computer"; Cmd = 'cmd.exe /c rundll32.exe user32.dll,LockWorkStation' } 
    @{ Group = "System"; ID = "HibernatePC"; Name = "Hibernate"; Cmd = 'cmd.exe /c shutdown /h' }
    @{ Group = "System"; ID = "SignOut"; Name = "Sign Out (Log Off)"; Cmd = 'cmd.exe /c logoff' }
    @{ Group = "System"; ID = "SysInfo"; Name = "System Information"; Cmd = 'cmd.exe /k systeminfo' }

    # --- NHÓM 2: CỨU HỘ (10) ---
    @{ Group = "Fix"; ID = "KillNotResp"; Name = "Kill Not Responding Tasks"; Cmd = 'cmd.exe /c taskkill.exe /F /FI "status eq NOT RESPONDING"' }
    @{ Group = "Fix"; ID = "RestSpooler"; Name = "Restart Print Spooler"; Cmd = 'cmd.exe /c net stop spooler & net start spooler' }
    @{ Group = "Fix"; ID = "RebuildIcon"; Name = "Rebuild Icon Cache"; Cmd = 'cmd.exe /c ie4uinit.exe -show & taskkill /F /IM explorer.exe & del /A /F /Q "%localappdata%\IconCache.db" & start explorer.exe' }
    @{ Group = "Fix"; ID = "ClearTemp"; Name = "Clear Temp & Prefetch"; Cmd = 'cmd.exe /c del /q /f /s "%temp%\*" & del /q /f /s "C:\Windows\Prefetch\*" ' }
    @{ Group = "Fix"; ID = "FixWinUpd"; Name = "Fix Windows Update"; Cmd = 'cmd.exe /c net stop wuauserv & net stop bits & rd /s /q "%windir%\SoftwareDistribution" & net start wuauserv & net start bits' }
    @{ Group = "Fix"; ID = "RunSFC"; Name = "Run SFC Scan"; Cmd = 'cmd.exe /k sfc /scannow' }
    @{ Group = "Fix"; ID = "RunDISM"; Name = "Run DISM RestoreHealth"; Cmd = 'cmd.exe /k dism /online /cleanup-image /restorehealth' }
    @{ Group = "Fix"; ID = "RestartDWM"; Name = "Restart DWM (Fix Screen)"; Cmd = 'cmd.exe /c taskkill /f /im dwm.exe' } 
    @{ Group = "Fix"; ID = "ResetStore"; Name = "Reset Windows Store Cache"; Cmd = 'cmd.exe /c wsreset.exe' }
    @{ Group = "Fix"; ID = "FontCache"; Name = "Rebuild Font Cache"; Cmd = 'powershell.exe -WindowStyle Hidden -Command "Stop-Service FontCache -Force; Start-Service FontCache"' }

    # --- NHÓM 3: NETWORK (10) ---
    @{ Group = "Network"; ID = "Ping8888"; Name = "Ping 8.8.8.8 (Test Internet)"; Cmd = 'cmd.exe /k ping 8.8.8.8 -t' }
    @{ Group = "Network"; ID = "FlushDNS"; Name = "Flush DNS Cache"; Cmd = 'cmd.exe /k ipconfig /flushdns' }
    @{ Group = "Network"; ID = "RelRenIP"; Name = "Release / Renew IP"; Cmd = 'cmd.exe /k ipconfig /release & ipconfig /renew' }
    @{ Group = "Network"; ID = "ResetNet"; Name = "Reset Network & Winsock"; Cmd = 'cmd.exe /k netsh winsock reset & netsh int ip reset' }
    @{ Group = "Network"; ID = "ShowWiFi"; Name = "Show Saved Wi-Fi Passwords"; Cmd = 'cmd.exe /k netsh wlan show profile * key=clear' }
    @{ Group = "Network"; ID = "NetConn"; Name = "Network Connections"; Cmd = 'cmd.exe /c ncpa.cpl' } 
    @{ Group = "Network"; ID = "ShowPorts"; Name = "Show Open Ports (netstat)"; Cmd = 'cmd.exe /k netstat -ano' }
    @{ Group = "Network"; ID = "PingGoogle"; Name = "Ping Google.com"; Cmd = 'cmd.exe /k ping google.com -t' }
    @{ Group = "Network"; ID = "TraceGoogle"; Name = "Traceroute 8.8.8.8"; Cmd = 'cmd.exe /k tracert 8.8.8.8' }
    @{ Group = "Network"; ID = "AdvFirewall"; Name = "Advanced Windows Firewall"; Cmd = 'cmd.exe /c wf.msc' }

    # --- NHÓM 4: TWEAK & DEV (10) ---
    @{ Group = "Dev"; ID = "OpenCMDbg"; Name = "Open CMD (Admin) Here"; Cmd = 'cmd.exe /s /k pushd "%V"' }
    @{ Group = "Dev"; ID = "OpenPSbg"; Name = "Open PowerShell (Admin) Here"; Cmd = 'powershell.exe -NoExit -Command "Set-Location -LiteralPath ''%V''"' }
    @{ Group = "Dev"; ID = "TogDark"; Name = "Toggle Dark/Light Mode"; Cmd = 'powershell.exe -WindowStyle Hidden -Command "$p=''HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize''; $v=(Get-ItemProperty $p).AppsUseLightTheme; $nv=if($v -eq 0){1}else{0}; Set-ItemProperty $p -Name AppsUseLightTheme -Value $nv; Set-ItemProperty $p -Name SystemUsesLightTheme -Value $nv"' }
    @{ Group = "Dev"; ID = "TogHide"; Name = "Toggle Hidden Files"; Cmd = 'powershell.exe -WindowStyle Hidden -Command "$p=''HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced''; $v=(Get-ItemProperty $p).Hidden; if($v -eq 1){Set-ItemProperty $p -Name Hidden -Value 2}else{Set-ItemProperty $p -Name Hidden -Value 1}; Stop-Process -Name explorer"' }
    @{ Group = "Dev"; ID = "OffDef"; Name = "Turn Off Defender (Tạm thời)"; Cmd = 'powershell.exe -WindowStyle Hidden -Command "Set-MpPreference -DisableRealtimeMonitoring $true"' }
    @{ Group = "Dev"; ID = "RegEdit"; Name = "Open Registry Editor"; Cmd = 'cmd.exe /c regedit.exe' }
    @{ Group = "Dev"; ID = "GroupPol"; Name = "Open Group Policy (gpedit)"; Cmd = 'cmd.exe /c gpedit.msc' }
    @{ Group = "Dev"; ID = "MSConfig"; Name = "System Configuration (msconfig)"; Cmd = 'cmd.exe /c msconfig.exe' }
    @{ Group = "Dev"; ID = "GodMode"; Name = "Create God Mode Folder"; Cmd = 'cmd.exe /c mkdir "%userprofile%\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}"' }
    @{ Group = "Dev"; ID = "DisHiber"; Name = "Disable Hibernation (Giải phóng ổ C)"; Cmd = 'cmd.exe /k powercfg -h off' }

    # --- NHÓM 5: GAMING (10) ---
    @{ Group = "Gaming"; ID = "PerfPlan"; Name = "High Performance Power Plan"; Cmd = 'cmd.exe /c powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c' }
    @{ Group = "Gaming"; ID = "ClearRAM"; Name = "Clear RAM (Standby List)"; Cmd = 'powershell.exe -WindowStyle Hidden -Command "Clear-RecycleBin -Force; [GC]::Collect(); [GC]::WaitForPendingFinalizers()"' } 
    @{ Group = "Gaming"; ID = "GameMode"; Name = "Windows Game Mode Settings"; Cmd = 'cmd.exe /c start ms-settings:gaming-gamemode' }
    @{ Group = "Gaming"; ID = "XboxBar"; Name = "Xbox Game Bar Settings"; Cmd = 'cmd.exe /c start ms-settings:gaming-gamebar' }
    @{ Group = "Gaming"; ID = "DxDiag"; Name = "DirectX Diagnostic (dxdiag)"; Cmd = 'cmd.exe /c dxdiag' }
    @{ Group = "Gaming"; ID = "NoMouseAcc"; Name = "Disable Mouse Acceleration"; Cmd = 'powershell.exe -WindowStyle Hidden -Command "Set-ItemProperty -Path ''HKCU:\Control Panel\Mouse'' -Name ''MouseSpeed'' -Value ''0''"' }
    @{ Group = "Gaming"; ID = "EnableHAGS"; Name = "Enable GPU Scheduling (HAGS)"; Cmd = 'powershell.exe -WindowStyle Hidden -Command "Set-ItemProperty -Path ''HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'' -Name ''HwSchMode'' -Value 2"' }
    @{ Group = "Gaming"; ID = "DisXboxDVR"; Name = "Disable Xbox DVR"; Cmd = 'powershell.exe -WindowStyle Hidden -Command "Set-ItemProperty -Path ''HKCU:\System\GameConfigStore'' -Name ''GameDVR_Enabled'' -Value 0"' }
    @{ Group = "Gaming"; ID = "NetTuning"; Name = "Gaming Network Tuning (TCP)"; Cmd = 'cmd.exe /k netsh int tcp set global autotuninglevel=normal' }
    @{ Group = "Gaming"; ID = "AdvDisp"; Name = "Advanced Display Settings (Hz)"; Cmd = 'cmd.exe /c start ms-settings:display-advanced' }

    # --- NHÓM 6: ỨNG DỤNG (APPS) (10) ---
    @{ Group = "Apps"; ID = "Appwiz"; Name = "Add/Remove Programs"; Cmd = 'cmd.exe /c appwiz.cpl' }
    @{ Group = "Apps"; ID = "TaskMgr"; Name = "Task Manager"; Cmd = 'cmd.exe /c taskmgr.exe' }
    @{ Group = "Apps"; ID = "Services"; Name = "Services Management"; Cmd = 'cmd.exe /c services.msc' }
    @{ Group = "Apps"; ID = "DevMgmt"; Name = "Device Manager (Driver)"; Cmd = 'cmd.exe /c devmgmt.msc' }
    @{ Group = "Apps"; ID = "CtrlPanel"; Name = "Control Panel"; Cmd = 'cmd.exe /c control' }
    @{ Group = "Apps"; ID = "EvtVwr"; Name = "Event Viewer"; Cmd = 'cmd.exe /c eventvwr.msc' }
    @{ Group = "Apps"; ID = "CompMgmt"; Name = "Computer Management"; Cmd = 'cmd.exe /c compmgmt.msc' }
    @{ Group = "Apps"; ID = "DiskMgmtA"; Name = "Disk Management"; Cmd = 'cmd.exe /c diskmgmt.msc' }
    @{ Group = "Apps"; ID = "UsrMgmt"; Name = "Local Users and Groups"; Cmd = 'cmd.exe /c lusrmgr.msc' }
    @{ Group = "Apps"; ID = "WinFeat"; Name = "Windows Features (Turn On/Off)"; Cmd = 'cmd.exe /c optionalfeatures.exe' }

    # --- NHÓM 7: GIAO DIỆN (PERSONALIZE) (10) ---
    @{ Group = "Personalize"; ID = "DeskIcon"; Name = "Desktop Icon Settings"; Cmd = 'cmd.exe /c desk.cpl ,5' }
    @{ Group = "Personalize"; ID = "DispSet"; Name = "Display Settings"; Cmd = 'cmd.exe /c start ms-settings:display' }
    @{ Group = "Personalize"; ID = "SysProps"; Name = "System Properties (Advanced)"; Cmd = 'cmd.exe /c sysdm.cpl ,3' }
    @{ Group = "Personalize"; ID = "BgSet"; Name = "Background Settings"; Cmd = 'cmd.exe /c start ms-settings:personalization-background' }
    @{ Group = "Personalize"; ID = "ColorSet"; Name = "Colors Settings"; Cmd = 'cmd.exe /c start ms-settings:personalization-colors' }
    @{ Group = "Personalize"; ID = "LockSet"; Name = "Lock Screen Settings"; Cmd = 'cmd.exe /c start ms-settings:personalization-lockscreen' }
    @{ Group = "Personalize"; ID = "ThemeSet"; Name = "Themes Settings"; Cmd = 'cmd.exe /c start ms-settings:personalization-themes' }
    @{ Group = "Personalize"; ID = "TaskSet"; Name = "Taskbar Settings"; Cmd = 'cmd.exe /c start ms-settings:taskbar' }
    @{ Group = "Personalize"; ID = "MouseSet"; Name = "Mouse Pointers Options"; Cmd = 'cmd.exe /c main.cpl' }
    @{ Group = "Personalize"; ID = "SoundSet"; Name = "Sound / Volume Control"; Cmd = 'cmd.exe /c mmsys.cpl' }

    # --- NHÓM 8: XỬ LÝ FILE (FILEOPS) (10) ---
    @{ Group = "FileOps"; ID = "TakeOwnF"; Name = "Take Ownership (Quyền Admin)"; Cmd = 'cmd.exe /c takeown /f "%1" & icacls "%1" /grant administrators:F' }
    @{ Group = "FileOps"; ID = "CopyPathF"; Name = "Copy Path (No Quotes)"; Cmd = 'powershell.exe -WindowStyle Hidden -Command "Set-Clipboard -Value (''%1'' -replace ''\"'','''')"' }
    @{ Group = "FileOps"; ID = "OpenNoteF"; Name = "Open with Notepad"; Cmd = 'notepad.exe "%1"' }
    @{ Group = "FileOps"; ID = "ChkHash"; Name = "Check Hash (MD5/SHA256)"; Cmd = 'powershell.exe -NoExit -Command "Get-FileHash -LiteralPath ''%1''"' }
    @{ Group = "FileOps"; ID = "BlkFire"; Name = "Block File in Firewall"; Cmd = 'cmd.exe /c netsh advfirewall firewall add rule name="Block %~nx1" dir=out program="%1" action=block' }
    @{ Group = "FileOps"; ID = "AlwFire"; Name = "Allow File in Firewall"; Cmd = 'cmd.exe /c netsh advfirewall firewall add rule name="Allow %~nx1" dir=out program="%1" action=allow' }
    @{ Group = "FileOps"; ID = "DeskShort"; Name = "Send to Desktop (Shortcut)"; Cmd = 'powershell.exe -WindowStyle Hidden -Command "$s=(New-Object -COM WScript.Shell).CreateShortcut(''%userprofile%\Desktop\%~nx1.lnk''); $s.TargetPath=''%1''; $s.Save()"' } 
    @{ Group = "FileOps"; ID = "PermDel"; Name = "Permanent Delete (Bypass Trash)"; Cmd = 'cmd.exe /c del /f /q "%1"' }
    @{ Group = "FileOps"; ID = "ExtrMSI"; Name = "Extract MSI / CAB"; Cmd = 'cmd.exe /k msiexec /a "%1" /qb TARGETDIR="%~dp1\Extracted"' }
    @{ Group = "FileOps"; ID = "B64Enc"; Name = "Encode File to Base64 (Clipboard)"; Cmd = 'powershell.exe -WindowStyle Hidden -Command "[Convert]::ToBase64String([IO.File]::ReadAllBytes(''%1'')) | clip"' }

    # --- NHÓM 9: THƯ MỤC (FOLDEROPS) (10) ---
    @{ Group = "FolderOps"; ID = "TakeOwnD"; Name = "Take Ownership & Full Control"; Cmd = 'cmd.exe /c takeown /f "%1" /r /d y & icacls "%1" /grant administrators:F /t' }
    @{ Group = "FolderOps"; ID = "SymLink"; Name = "Create Symlink (Tạo shortcut ảo)"; Cmd = 'cmd.exe /k mklink /D "%1_Symlink" "%1"' }
    @{ Group = "FolderOps"; ID = "QuickShar"; Name = "Quick Share LAN (Read/Write)"; Cmd = 'cmd.exe /c net share "%~nx1"="%1" /GRANT:EVERYONE,FULL' }
    @{ Group = "FolderOps"; ID = "StopShar"; Name = "Stop Sharing LAN"; Cmd = 'cmd.exe /c net share "%~nx1" /delete' }
    @{ Group = "FolderOps"; ID = "OpenCMDD"; Name = "Open CMD (Admin) Here"; Cmd = 'cmd.exe /s /k pushd "%1"' }
    @{ Group = "FolderOps"; ID = "OpenPSD"; Name = "Open PowerShell Here"; Cmd = 'powershell.exe -NoExit -Command "Set-Location -LiteralPath ''%1''"' }
    @{ Group = "FolderOps"; ID = "ExportTree"; Name = "Export Folder Tree to TXT"; Cmd = 'cmd.exe /c tree "%1" /f /a > "%1\FolderTree.txt"' } 
    @{ Group = "FolderOps"; ID = "SupHideD"; Name = "Super Hide Folder (System Level)"; Cmd = 'cmd.exe /c attrib +s +h "%1"' }
    @{ Group = "FolderOps"; ID = "UnHideD"; Name = "Unhide Folder"; Cmd = 'cmd.exe /c attrib -s -h "%1"' }
    @{ Group = "FolderOps"; ID = "DelEmpD"; Name = "Delete All Empty Folders Inside"; Cmd = 'powershell.exe -WindowStyle Hidden -Command "Get-ChildItem -Path ''%1'' -Recurse -Directory | Where-Object { @(Get-ChildItem -LiteralPath $_.FullName).Count -eq 0 } | Remove-Item -Force"' }

    # --- NHÓM 10: Ổ CỨNG (DRIVEOPS) (10) - Click chuột phải vào ổ đĩa ---
    @{ Group = "DriveOps"; ID = "DiskClean"; Name = "Disk Cleanup"; Cmd = 'cmd.exe /c cleanmgr.exe /d "%1"' }
    @{ Group = "DriveOps"; ID = "Chkdsk"; Name = "Check Disk (Sửa lỗi ổ đĩa)"; Cmd = 'cmd.exe /k chkdsk "%1" /f /r' }
    @{ Group = "DriveOps"; ID = "Defrag"; Name = "Optimize/Defrag Drive"; Cmd = 'cmd.exe /c dfrgui.exe' }
    @{ Group = "DriveOps"; ID = "OpenDiskMgmt"; Name = "Open Disk Management"; Cmd = 'cmd.exe /c diskmgmt.msc' }
    @{ Group = "DriveOps"; ID = "BitLocker"; Name = "BitLocker Drive Encryption"; Cmd = 'cmd.exe /c control /name Microsoft.BitLockerDriveEncryption' }
    @{ Group = "DriveOps"; ID = "FormatDrv"; Name = "Format Drive (CMD)"; Cmd = 'cmd.exe /k format "%1"' }
    @{ Group = "DriveOps"; ID = "SysProt"; Name = "System Protection (Restore)"; Cmd = 'cmd.exe /c SystemPropertiesProtection.exe' }
    @{ Group = "DriveOps"; ID = "FSMgmt"; Name = "Shared Folders Management"; Cmd = 'cmd.exe /c fsmgmt.msc' }
    @{ Group = "DriveOps"; ID = "FolderOpt"; Name = "File Explorer Options"; Cmd = 'cmd.exe /c control folders' }
    @{ Group = "DriveOps"; ID = "DrvProps"; Name = "Drive Properties UI"; Cmd = 'powershell.exe -WindowStyle Hidden -Command "(New-Object -COM Shell.Application).NameSpace(''%1'').Self.InvokeVerb(''Properties'')"' }
)

# ==============================================================================
# 3. HỆ THỐNG LOG & ĐĂNG KÝ REGISTRY
# ==============================================================================
$global:IsWPF = $false
$global:WpfLogBox = $null
$global:WinFormsLogBox = $null

function Write-LogBox {
    param($Msg, $Prefix = ">>")
    $LogLine = "[$((Get-Date).ToString('HH:mm:ss'))] $Prefix $Msg"
    if ($global:IsWPF -and $global:WpfLogBox) {
        $global:WpfLogBox.Dispatcher.Invoke({
            $global:WpfLogBox.AppendText("$LogLine`r`n")
            $global:WpfLogBox.ScrollToEnd()
        })
    } elseif ($global:WinFormsLogBox) {
        $global:WinFormsLogBox.AppendText("$LogLine`r`n")
        $global:WinFormsLogBox.ScrollToCaret()
    }
    Write-Host $LogLine
}

function Get-RegistryPath {
    param($Item)
    $GroupInfo = $MenuGroups[$Item.Group]
    $RootName = "PhattanPC_$($Item.Group)"
    return "$($GroupInfo.RootKey)\$RootName\shell\$($Item.ID)"
}

function Test-FeatureState {
    param($Item)
    return (Test-Path (Get-RegistryPath -Item $Item))
}

function Apply-Features {
    param($UIStateData) 
    Write-LogBox "BẮT ĐẦU CẬP NHẬT REGISTRY..." "---"
    
    foreach ($Grp in $MenuGroups.Keys) {
        $RootName = "PhattanPC_$Grp"
        $RootPath = "$($MenuGroups[$Grp].RootKey)\$RootName"
        
        if (-not (Test-Path $RootPath)) {
            New-Item -Path $RootPath -Force | Out-Null
            Set-ItemProperty -Path $RootPath -Name "MUIVerb" -Value $MenuGroups[$Grp].Name -Force
            Set-ItemProperty -Path $RootPath -Name "SubCommands" -Value "" -Force
            Set-ItemProperty -Path $RootPath -Name "Icon" -Value "imageres.dll,-104" -Force
            Write-LogBox "Tạo nhóm Root: $($MenuGroups[$Grp].Name)" "+"
        }
    }

    foreach ($Item in $MenuItems) {
        $IsChecked = $UIStateData[$Item.ID]
        $RegPath = Get-RegistryPath -Item $Item
        
        if ($IsChecked) {
            if (-not (Test-Path $RegPath)) {
                New-Item -Path "$RegPath\command" -Force | Out-Null
                Set-ItemProperty -Path $RegPath -Name "(Default)" -Value $Item.Name -Force
                Set-ItemProperty -Path "$RegPath\command" -Name "(Default)" -Value $Item.Cmd -Force
                Write-LogBox "BẬT: $($Item.Name)" "[ON]"
            }
        } else {
            if (Test-Path $RegPath) {
                Remove-Item -Path $RegPath -Recurse -Force
                Write-LogBox "TẮT: $($Item.Name)" "[OFF]"
            }
        }
    }
    Write-LogBox "HOÀN TẤT CẬP NHẬT 100 TÍNH NĂNG!" "---"
}

# ==============================================================================
# 4. GIAO DIỆN CHIA ĐÔI CÓ LOG & RGB MODE
# ==============================================================================
$UIState = @{}

try {
    Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
    $global:IsWPF = $true
} catch {
    $global:IsWPF = $false
}

if ($global:IsWPF) {
    # ------------------- WPF GUI (100 FEATURES) -------------------
    [xml]$XAML = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            Title="PhattanPC Context Menu Ultimate - RGB Edition" Width="980" Height="600" WindowStartupLocation="CenterScreen">
        
        <Border BorderThickness="3">
            <Border.BorderBrush>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                    <GradientStop Color="#FF00E4" Offset="0.0" />
                    <GradientStop Color="#00B4FF" Offset="0.5" />
                    <GradientStop Color="#00FF72" Offset="1.0" />
                </LinearGradientBrush>
            </Border.BorderBrush>
            
            <Grid Name="MainGrid" Background="#1E1E1E">
                <Grid.RowDefinitions>
                    <RowDefinition Height="50"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="60"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="6*"/>
                    <ColumnDefinition Width="4*"/>
                </Grid.ColumnDefinitions>

                <TextBlock Text="PHÁT TẤN PC - CONTEXT MENU (100 TÍNH NĂNG)" Foreground="White" FontSize="18" FontWeight="Bold" VerticalAlignment="Center" Margin="15,0,0,0" Grid.Row="0" Grid.Column="0"/>
                <Button Name="ThemeBtn" Content="🌗 TOGGLE THEME" Grid.Row="0" Grid.Column="1" HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,15,0" Padding="10,5" Background="#333" Foreground="White" BorderThickness="1" BorderBrush="#00B4FF" Cursor="Hand"/>

                <ScrollViewer Grid.Row="1" Grid.Column="0" Margin="10,0,5,0" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Disabled">
                    <TabControl Name="MainTab" Background="#2D2D30" BorderThickness="0" MinWidth="580">
                    </TabControl>
                </ScrollViewer>

                <Border Grid.Row="1" Grid.Column="1" Margin="5,0,10,0" BorderThickness="1" BorderBrush="#444" Background="#111">
                    <TextBox Name="LogBox" Foreground="#00FF00" Background="Transparent" BorderThickness="0" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="12" Padding="5"/>
                </Border>
                
                <Button Name="ApplyBtn" Grid.Row="2" Grid.ColumnSpan="2" Margin="10,10,10,10" Foreground="White" FontSize="16" FontWeight="Bold" BorderThickness="0" Cursor="Hand">
                    <Button.Background>
                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                            <GradientStop Color="#FF004D" Offset="0.0" />
                            <GradientStop Color="#8A2BE2" Offset="0.5" />
                            <GradientStop Color="#00BFFF" Offset="1.0" />
                        </LinearGradientBrush>
                    </Button.Background>
                    <Button.Content>
                        <TextBlock Text="⚡ XÁC NHẬN CẬP NHẬT (APPLY) ⚡"/>
                    </Button.Content>
                </Button>
            </Grid>
        </Border>
    </Window>
"@
    $Reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $Window = [Windows.Markup.XamlReader]::Load($Reader)
    
    $MainGrid = $Window.FindName("MainGrid")
    $MainTab = $Window.FindName("MainTab")
    $global:WpfLogBox = $Window.FindName("LogBox")
    
    foreach ($Grp in $MenuGroups.Keys) {
        $Tab = New-Object System.Windows.Controls.TabItem
        $Tab.Header = $MenuGroups[$Grp].Name
        
        $Scroll = New-Object System.Windows.Controls.ScrollViewer
        $Scroll.VerticalScrollBarVisibility = [System.Windows.Controls.ScrollBarVisibility]::Auto
        
        $Stack = New-Object System.Windows.Controls.StackPanel
        $Stack.Margin = "10"

        $GroupItems = $MenuItems | Where-Object { $_.Group -eq $Grp }
        foreach ($Item in $GroupItems) {
            $Check = New-Object System.Windows.Controls.CheckBox
            $Check.Content = $Item.Name
            $Check.Name = "chk_$($Item.ID)"
            $Check.Foreground = "White"
            $Check.Margin = "0,6,0,6"
            $Check.IsChecked = (Test-FeatureState -Item $Item)
            
            $UIState[$Item.ID] = $Check
            $Stack.Children.Add($Check) | Out-Null
        }
        $Scroll.Content = $Stack
        $Tab.Content = $Scroll
        $MainTab.Items.Add($Tab) | Out-Null
    }

    $global:IsDark = $true
    $ThemeBtn = $Window.FindName("ThemeBtn")
    $ThemeBtn.Add_Click({
        if ($global:IsDark) {
            $MainGrid.Background = "#F0F0F0"
            $MainTab.Background = "#E6E6E6"
            foreach ($Ctrl in $UIState.Values) { $Ctrl.Foreground = "Black" }
            $global:WpfLogBox.Background = "#FFFFFF"
            $global:WpfLogBox.Foreground = "#0000AA"
            $ThemeBtn.Background = "#DDD"
            $ThemeBtn.Foreground = "Black"
        } else {
            $MainGrid.Background = "#1E1E1E"
            $MainTab.Background = "#2D2D30"
            foreach ($Ctrl in $UIState.Values) { $Ctrl.Foreground = "White" }
            $global:WpfLogBox.Background = "Transparent"
            $global:WpfLogBox.Foreground = "#00FF00"
            $ThemeBtn.Background = "#333"
            $ThemeBtn.Foreground = "White"
        }
        $global:IsDark = -not $global:IsDark
    })

    $ApplyBtn = $Window.FindName("ApplyBtn")
    $ApplyBtn.Add_Click({
        $ApplyData = @{}
        foreach ($Key in $UIState.Keys) { $ApplyData[$Key] = [bool]$UIState[$Key].IsChecked }
        Apply-Features -UIStateData $ApplyData
        [System.Windows.MessageBox]::Show("Cập nhật thành công 100 chức năng! Xem màn hình Log.", "PhattanPC Ultimate", 0, 64)
    })

    Write-LogBox "PhattanPC Ultimate 100 Chức năng sẵn sàng." "INFO"
    $Window.ShowDialog() | Out-Null

} else {
    # ------------------- WINFORMS GUI (FALLBACK PE) -------------------
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = "PhattanPC Context Menu - 100 Features (PE Mode)"
    $Form.Size = New-Object System.Drawing.Size(980,600)
    $Form.StartPosition = "CenterScreen"
    $Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    
    $Split = New-Object System.Windows.Forms.SplitContainer
    $Split.Dock = "Fill"
    $Split.SplitterDistance = 600
    
    $TabControl = New-Object System.Windows.Forms.TabControl
    $TabControl.Dock = "Fill"
    $TabControl.Multiline = $true 

    foreach ($Grp in $MenuGroups.Keys) {
        $Page = New-Object System.Windows.Forms.TabPage
        $Page.Text = $MenuGroups[$Grp].Name
        $Page.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
        $Page.ForeColor = [System.Drawing.Color]::White
        $Page.AutoScroll = $true

        $Y = 15
        $GroupItems = $MenuItems | Where-Object { $_.Group -eq $Grp }
        foreach ($Item in $GroupItems) {
            $Check = New-Object System.Windows.Forms.CheckBox
            $Check.Text = $Item.Name
            $Check.Location = New-Object System.Drawing.Point(15, $Y)
            $Check.Width = 550
            $Check.Checked = (Test-FeatureState -Item $Item)
            
            $UIState[$Item.ID] = $Check
            $Page.Controls.Add($Check)
            $Y += 30
        }
        $TabControl.TabPages.Add($Page)
    }

    $global:WinFormsLogBox = New-Object System.Windows.Forms.TextBox
    $global:WinFormsLogBox.Multiline = $true
    $global:WinFormsLogBox.Dock = "Fill"
    $global:WinFormsLogBox.BackColor = [System.Drawing.Color]::Black
    $global:WinFormsLogBox.ForeColor = [System.Drawing.Color]::LimeGreen
    $global:WinFormsLogBox.ScrollBars = "Vertical"
    $global:WinFormsLogBox.ReadOnly = $true
    $global:WinFormsLogBox.Font = New-Object System.Drawing.Font("Consolas", 10)

    $ApplyBtn = New-Object System.Windows.Forms.Button
    $ApplyBtn.Text = "XÁC NHẬN CẬP NHẬT (APPLY)"
    $ApplyBtn.Dock = "Bottom"
    $ApplyBtn.Height = 50
    $ApplyBtn.BackColor = [System.Drawing.Color]::FromArgb(255, 0, 128) 
    $ApplyBtn.ForeColor = [System.Drawing.Color]::White
    $ApplyBtn.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $ApplyBtn.FlatStyle = "Flat"
    
    $ThemeBtn = New-Object System.Windows.Forms.Button
    $ThemeBtn.Text = "🌗 THEME"
    $ThemeBtn.Dock = "Top"
    $ThemeBtn.Height = 30
    $ThemeBtn.BackColor = [System.Drawing.Color]::Gray

    $global:IsDarkPE = $true
    $ThemeBtn.Add_Click({
        if ($global:IsDarkPE) {
            $Form.BackColor = [System.Drawing.Color]::White
            foreach ($Page in $TabControl.TabPages) {
                $Page.BackColor = [System.Drawing.Color]::WhiteSmoke
                $Page.ForeColor = [System.Drawing.Color]::Black
            }
            $global:WinFormsLogBox.BackColor = [System.Drawing.Color]::White
            $global:WinFormsLogBox.ForeColor = [System.Drawing.Color]::Blue
        } else {
            $Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
            foreach ($Page in $Tab, $TabControl.TabPages) {
                $Page.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
                $Page.ForeColor = [System.Drawing.Color]::White
            }
            $global:WinFormsLogBox.BackColor = [System.Drawing.Color]::Black
            $global:WinFormsLogBox.ForeColor = [System.Drawing.Color]::LimeGreen
        }
        $global:IsDarkPE = -not $global:IsDarkPE
    })

    $ApplyBtn.Add_Click({
        $ApplyData = @{}
        foreach ($Key in $UIState.Keys) { $ApplyData[$Key] = [bool]$UIState[$Key].Checked }
        Apply-Features -UIStateData $ApplyData
        [System.Windows.Forms.MessageBox]::Show("Đã cập nhật PhattanPC Context Menu thành công!", "PhattanPC Ultimate")
    })

    $Split.Panel1.Controls.Add($TabControl)
    $Split.Panel2.Controls.Add($global:WinFormsLogBox)
    $Split.Panel2.Controls.Add($ThemeBtn)

    $Form.Controls.Add($Split)
    $Form.Controls.Add($ApplyBtn)

    Write-LogBox "Đã load WinForms UI (WinPE)." "INFO"
    $Form.ShowDialog() | Out-Null
}
