# Yêu cầu chạy quyền Admin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Vui lòng chạy Script với quyền Administrator!"
    Start-Sleep -Seconds 3
    exit
}

# ==========================================
# KHỞI TẠO LOG & KIỂM TRA ĐƯỜNG DẪN
# ==========================================
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
if ([string]::IsNullOrEmpty($ScriptDir)) { $ScriptDir = $PWD.Path }

$global:DebugLogPath = "$env:USERPROFILE\Desktop\PTPC_Debug_v8.1.txt"
if (Test-Path $global:DebugLogPath) { Remove-Item $global:DebugLogPath -Force }
Add-Content -Path $global:DebugLogPath -Value "=== NHẬT KÝ DEBUG PHAT TAN PC v8.1 (ALL-IN-ONE + DEBUG) ===" -Encoding UTF8

# ==========================================
# INJECTION 7-ZIP TỪ BASE64 (DROP-AND-EXECUTE)
# ==========================================
$Base64File = Join-Path $ScriptDir "7z_base64.txt"
$global:Temp7zPath = "$env:TEMP\ptpc_engine_$(Get-Random).exe"

if (Test-Path $Base64File) {
    Add-Content -Path $global:DebugLogPath -Value "[$(Get-Date -f 'HH:mm:ss')] Đang giải mã lõi 7-Zip từ Base64..." -Encoding UTF8
    try {
        $b64String = Get-Content $Base64File -Raw
        $exeBytes = [Convert]::FromBase64String($b64String)
        [IO.File]::WriteAllBytes($global:Temp7zPath, $exeBytes)
        Add-Content -Path $global:DebugLogPath -Value "[$(Get-Date -f 'HH:mm:ss')] Bơm lõi 7-Zip vào Temp thành công! Đường dẫn: $global:Temp7zPath" -Encoding UTF8
    } catch {
        Write-Warning "Lỗi giải mã Base64! Hãy chắc chắn file 7z_base64.txt chuẩn xác."
        exit
    }
} else {
    Write-Warning "KHÔNG TÌM THẤY 7z_base64.txt ở cùng thư mục!"
    exit
}

# ==========================================
# CORE ENGINE C# 
# ==========================================
$global:CSharpCode = @"
using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;

public class PhatTanArchiver_v8_1
{
    private static readonly byte[] MagicHeader = Encoding.UTF8.GetBytes("PTPC"); 

    private static byte[] HashPassword(string password)
    {
        using (SHA512 sha512 = SHA512.Create()) {
            return sha512.ComputeHash(Encoding.UTF8.GetBytes(password + "PHATTAN_QUANTUM_RESISTANT_CORE_2026_PRO"));
        }
    }

    public static string EncryptOnly(string inputFile, string outputFile, string password)
    {
        try {
            byte[] salt = new byte[32]; 
            using (var rng = new RNGCryptoServiceProvider()) { rng.GetBytes(salt); }
            byte[] preHash = HashPassword(password);

            using (var derivedBytes = new Rfc2898DeriveBytes(preHash, salt, 50000)) 
            {
                byte[] key = derivedBytes.GetBytes(32); 
                byte[] iv = derivedBytes.GetBytes(32);  

                using (FileStream fsOut = new FileStream(outputFile, FileMode.Create))
                {
                    fsOut.Write(MagicHeader, 0, MagicHeader.Length);
                    fsOut.Write(salt, 0, salt.Length);
                    fsOut.Write(iv, 0, iv.Length);

                    using (RijndaelManaged cipher = new RijndaelManaged())
                    {
                        cipher.KeySize = 256; cipher.BlockSize = 256; 
                        cipher.Key = key; cipher.IV = iv;
                        cipher.Mode = CipherMode.CBC; cipher.Padding = PaddingMode.PKCS7;

                        using (CryptoStream cryptoStream = new CryptoStream(fsOut, cipher.CreateEncryptor(), CryptoStreamMode.Write))
                        using (FileStream fsIn = new FileStream(inputFile, FileMode.Open)) {
                            fsIn.CopyTo(cryptoStream);
                        }
                    }
                }
            }
            return "SUCCESS";
        } catch (Exception ex) { return "CRASH C#: " + ex.Message; }
    }

    public static string DecryptOnly(string inputFile, string outputFile, string password)
    {
        try {
            using (FileStream fsIn = new FileStream(inputFile, FileMode.Open))
            {
                byte[] header = new byte[4];
                fsIn.Read(header, 0, header.Length);
                if (Encoding.UTF8.GetString(header) != "PTPC") return "LỖI C#: File không phải chuẩn PTPC.";

                byte[] salt = new byte[32]; fsIn.Read(salt, 0, salt.Length);
                byte[] iv = new byte[32]; fsIn.Read(iv, 0, iv.Length);
                byte[] preHash = HashPassword(password);

                using (var derivedBytes = new Rfc2898DeriveBytes(preHash, salt, 50000))
                {
                    byte[] key = derivedBytes.GetBytes(32);
                    using (RijndaelManaged cipher = new RijndaelManaged())
                    {
                        cipher.KeySize = 256; cipher.BlockSize = 256;
                        cipher.Key = key; cipher.IV = iv;
                        cipher.Mode = CipherMode.CBC; cipher.Padding = PaddingMode.PKCS7;

                        using (CryptoStream cryptoStream = new CryptoStream(fsIn, cipher.CreateDecryptor(), CryptoStreamMode.Read))
                        using (FileStream fsOut = new FileStream(outputFile, FileMode.Create)) {
                            cryptoStream.CopyTo(fsOut);
                        }
                    }
                }
            }
            return "SUCCESS";
        } catch (Exception ex) { return "CRASH C#: " + ex.Message; }
    }
}
"@

if (-not ("PhatTanArchiver_v8_1" -as [type])) {
    Add-Type -TypeDefinition $global:CSharpCode -Language CSharp
}

# ==========================================
# XAML GUI
# ==========================================
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Phat Tan PC - Quantum Archiver v8.1 (All-In-One Format + Debug)" Height="780" Width="850" WindowStartupLocation="CenterScreen"
        Background="#1E1E1E" x:Name="MainWindow">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#333333"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#2D2D30"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderBrush" Value="#555"/>
            <Setter Property="Padding" Value="5"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
    </Window.Resources>

    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/> <RowDefinition Height="*"/> <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,0,10">
            <Button x:Name="btnLight" Content="Light Mode" Background="#E0E0E0" Foreground="Black"/>
            <Button x:Name="btnDark" Content="Dark Mode" Background="#333" Foreground="White"/>
        </StackPanel>

        <TextBlock Grid.Row="0" Text="PHÁT TẤN PC - ĐA ĐỊNH DẠNG &amp; BẢO MẬT" FontSize="18" FontWeight="Bold" Foreground="#00D2FF" VerticalAlignment="Top"/>

        <GroupBox Grid.Row="1" Header="1. ĐÓNG GÓI &amp; MÃ HÓA" Foreground="#00D2FF" Margin="0,0,0,10" Padding="10">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="110"/> <ColumnDefinition Width="*"/> <ColumnDefinition Width="80"/> <ColumnDefinition Width="80"/>
                </Grid.ColumnDefinitions>

                <TextBlock Grid.Row="0" Grid.Column="0" Text="Nguồn cần nén:"/>
                <TextBox x:Name="txtSrc" Grid.Row="0" Grid.Column="1" Margin="5"/>
                <Button x:Name="btnBrowseSrcFolder" Grid.Row="0" Grid.Column="2" Content="Thư mục"/>
                <Button x:Name="btnBrowseSrcFile" Grid.Row="0" Grid.Column="3" Content="Tệp (File)"/>

                <TextBlock Grid.Row="1" Grid.Column="0" Text="Nơi lưu:"/>
                <TextBox x:Name="txtDest" Grid.Row="1" Grid.Column="1" Margin="5"/>
                <Button x:Name="btnBrowseDest" Grid.Row="1" Grid.Column="2" Grid.ColumnSpan="2" Content="Lưu vào..."/>

                <CheckBox x:Name="cbPTPC" Grid.Row="2" Grid.Column="1" Content="Bật khóa bảo mật Lượng Tử (Tạo file PTPC siêu bảo mật)" IsChecked="True" Foreground="#00FF00" FontWeight="Bold" Margin="5,5,5,5"/>

                <TextBlock Grid.Row="3" Grid.Column="0" Text="Mật khẩu khóa:" Foreground="Orange"/>
                <TextBox x:Name="txtPackPass" Grid.Row="3" Grid.Column="1" Margin="5" ToolTip="Dùng cho PTPC hoặc 7z có pass"/>
                <TextBlock Grid.Row="3" Grid.Column="2" Grid.ColumnSpan="2" Text="(Tùy chọn)" Foreground="Gray" FontStyle="Italic"/>

                <StackPanel Grid.Row="4" Grid.Column="1" Orientation="Horizontal" Margin="5,10,5,5">
                    <TextBlock Text="Mức nén:" Margin="0,0,10,0"/>
                    <ComboBox x:Name="cmbLevel" Width="180" Background="#2D2D30" Foreground="Black">
                        <ComboBoxItem Content="Siêu Tốc (Nhanh)"/>
                        <ComboBoxItem Content="Tiêu chuẩn (Tối ưu)"/>
                        <ComboBoxItem Content="Siêu Nén (Dict 64MB)"/>
                        <ComboBoxItem Content="Tà Đạo (Dict 1024MB)" Foreground="Red" FontWeight="Bold"/>
                    </ComboBox>
                    <Button x:Name="btnPack" Content="BẮT ĐẦU NÉN" Background="#00A86B" Width="150" Margin="20,0,0,0" FontWeight="Bold"/>
                </StackPanel>
            </Grid>
        </GroupBox>

        <GroupBox Grid.Row="2" Header="2. GIẢI NÉN THÔNG MINH (TỰ ĐỘNG NHẬN DIỆN LÕI FILE)" Foreground="#FF003C" Margin="0,0,0,10" Padding="10">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="110"/> <ColumnDefinition Width="*"/> <ColumnDefinition Width="160"/>
                </Grid.ColumnDefinitions>

                <TextBlock Grid.Row="0" Grid.Column="0" Text="Chọn file nén:"/>
                <TextBox x:Name="txtOpen" Grid.Row="0" Grid.Column="1" Margin="5" ToolTip="Hỗ trợ .ptpc, .7z, .rar, .zip hoặc bất kỳ đuôi tự đặt nào!"/>
                <Button x:Name="btnBrowseOpen" Grid.Row="0" Grid.Column="2" Content="Chọn file..."/>

                <TextBlock Grid.Row="1" Grid.Column="0" Text="Nơi bung ra:"/>
                <TextBox x:Name="txtExtract" Grid.Row="1" Grid.Column="1" Margin="5"/>
                <Button x:Name="btnBrowseExtract" Grid.Row="1" Grid.Column="2" Content="Chọn thư mục đích..."/>

                <TextBlock Grid.Row="2" Grid.Column="0" Text="Mật khẩu mở:" Foreground="Orange"/>
                <TextBox x:Name="txtUnpackPass" Grid.Row="2" Grid.Column="1" Margin="5" ToolTip="Nhập mật khẩu nếu file có khóa"/>

                <Button x:Name="btnUnpack" Grid.Row="3" Grid.Column="1" Content="TỰ ĐỘNG BUNG FILE" Background="#D32F2F" Width="170" HorizontalAlignment="Left" Margin="5,10,0,5" FontWeight="Bold"/>
            </Grid>
        </GroupBox>

        <GroupBox Grid.Row="3" Header="NHẬT KÝ HOẠT ĐỘNG (LOGS)" Foreground="Yellow">
            <TextBox x:Name="txtLog" TextWrapping="Wrap" AcceptsReturn="True" VerticalScrollBarVisibility="Auto" IsReadOnly="True" Background="#0C0C0C" Foreground="#00FF00" FontFamily="Consolas"/>
        </GroupBox>

        <ProgressBar x:Name="pbStatus" Grid.Row="4" Height="15" Margin="0,10,0,0" Minimum="0" Maximum="100" IsIndeterminate="False"/>
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $XAML)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Ánh xạ Controls
$txtSrc = $window.FindName("txtSrc")
$txtDest = $window.FindName("txtDest")
$txtOpen = $window.FindName("txtOpen")
$txtExtract = $window.FindName("txtExtract")
$txtPackPass = $window.FindName("txtPackPass")
$txtUnpackPass = $window.FindName("txtUnpackPass")
$txtLog = $window.FindName("txtLog")
$cmbLevel = $window.FindName("cmbLevel")
$btnPack = $window.FindName("btnPack")
$btnUnpack = $window.FindName("btnUnpack")
$pbStatus = $window.FindName("pbStatus")
$cbPTPC = $window.FindName("cbPTPC")

$window.Add_Loaded({ $cmbLevel.SelectedIndex = 1 })

Function Write-Log ($Message) {
    $time = (Get-Date).ToString("HH:mm:ss")
    $txtLog.AppendText("[$time] $Message`r`n")
    $txtLog.ScrollToEnd()
}

$window.FindName("btnLight").Add_Click({ $window.Background = "#F5F5F5"; Write-Log "Đã chuyển sang Light Mode." })
$window.FindName("btnDark").Add_Click({ $window.Background = "#1E1E1E"; Write-Log "Đã chuyển sang Dark Mode." })

# --- CÁC NÚT BROWSE ---
$window.FindName("btnBrowseSrcFolder").Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dlg.ShowDialog() -eq "OK") { $txtSrc.Text = $dlg.SelectedPath; Write-Log "Nguồn (Thư mục): $($txtSrc.Text)" }
})
$window.FindName("btnBrowseSrcFile").Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "Tất cả các File (*.*)|*.*"
    if ($dlg.ShowDialog() -eq "OK") { $txtSrc.Text = $dlg.FileName; Write-Log "Nguồn (File): $($txtSrc.Text)" }
})
$window.FindName("btnBrowseDest").Add_Click({
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Filter = "Phat Tan PC Bảo Mật (*.ptpc)|*.ptpc|File Nén 7-Zip (*.7z)|*.7z|Tuỳ ý đặt tên (*.*)|*.*"
    if ($dlg.ShowDialog() -eq "OK") { $txtDest.Text = $dlg.FileName; Write-Log "Nơi lưu: $($txtDest.Text)" }
})
$window.FindName("btnBrowseOpen").Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "Các định dạng hỗ trợ|*.ptpc;*.7z;*.zip;*.rar;*.tar|Phat Tan PC (*.ptpc)|*.ptpc|Mọi định dạng (*.*)|*.*"
    if ($dlg.ShowDialog() -eq "OK") { $txtOpen.Text = $dlg.FileName; Write-Log "Chọn file bung: $($txtOpen.Text)" }
})
$window.FindName("btnBrowseExtract").Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dlg.ShowDialog() -eq "OK") { $txtExtract.Text = $dlg.SelectedPath; Write-Log "Bung vào: $($txtExtract.Text)" }
})

# ==========================================
# XỬ LÝ NÉN FILE 
# ==========================================
$btnPack.Add_Click({
    if ($txtSrc.Text -eq "" -or $txtDest.Text -eq "") { Write-Log "LỖI: Hãy chọn đủ đường dẫn!"; return }
    if (!(Test-Path $txtSrc.Text)) { Write-Log "LỖI: Đường dẫn nguồn không tồn tại!"; return }
    
    $levelIndex = $cmbLevel.SelectedIndex
    $isPtpcMode = $cbPTPC.IsChecked
    
    $btnPack.IsEnabled = $false
    $pbStatus.IsIndeterminate = $true
    
    if ($isPtpcMode) { Write-Log "[UI] Bắt đầu Nén LZMA2 & Bọc giáp AES-256 (Chuẩn PTPC)..." } 
    else { Write-Log "[UI] Bắt đầu Nén LZMA2 thông thường (Chuẩn 7-Zip)..." }

    $JobScript = {
        param($src, $dest, $lvlIndex, $pass, $logPath, $enginePath, $codeString, $isPtpcMode)
        Function Write-LogNgam ($msg) { Add-Content -Path $logPath -Value "[$(Get-Date -f 'HH:mm:ss')] $msg" -Encoding UTF8 }
        
        try {
            Write-LogNgam "--- BẮT ĐẦU JOB NÉN ---"
            Write-LogNgam "File đích sẽ xuất ra: $dest"
            
            $lzmaParam = "-mx=5"
            if ($lvlIndex -eq 0) { $lzmaParam = "-mx=1" }
            if ($lvlIndex -eq 2) { $lzmaParam = "-mx=9 -md=64m" }
            if ($lvlIndex -eq 3) { $lzmaParam = "-mx=9 -md=1024m" } 
            
            $isFolder = (Get-Item $src) -is [System.IO.DirectoryInfo]
            $targetPath = if ($isFolder) { "$src\*" } else { $src }

            # NẾU TÍCH BẬT PTPC
            if ($isPtpcMode) {
                Write-LogNgam "Chế độ: PTPC Độc Quyền."
                if (-not ("PhatTanArchiver_v8_1" -as [type])) { Add-Type -TypeDefinition $codeString -Language CSharp }
                
                $temp7zFile = "$env:TEMP\ptpc_temp_lzma_$(Get-Random).7z"
                if (Test-Path $temp7zFile) { Remove-Item $temp7zFile -Force }
                
                $args = @("a", "-t7z", "-m0=lzma2", $lzmaParam, "-r", "-y", "`"$temp7zFile`"", "`"$targetPath`"")
                Write-LogNgam "Đang gọi 7-Zip tạo file tạm: $temp7zFile"
                $process = Start-Process -FilePath $enginePath -ArgumentList $args -WindowStyle Hidden -Wait -PassThru
                
                Write-LogNgam "7-Zip Exit Code: $($process.ExitCode)"
                
                if ($process.ExitCode -eq 0 -and (Test-Path $temp7zFile)) {
                    Write-LogNgam "7-Zip nén thành công, đang bọc PTPC C#..."
                    $finalPass = if ([string]::IsNullOrWhiteSpace($pass)) { "NO_PASSWORD_SET_DEFAULT_KEY_2026" } else { $pass }
                    $res = [PhatTanArchiver_v8_1]::EncryptOnly($temp7zFile, $dest, $finalPass)
                    Remove-Item $temp7zFile -Force
                    Write-LogNgam "C# báo cáo: $res"
                    return $res
                } else {
                    if (Test-Path $temp7zFile) { Remove-Item $temp7zFile -Force }
                    return "LỖI LÕI NÉN (Exit Code: $($process.ExitCode))"
                }
            } 
            # NẾU NÉN 7-ZIP BÌNH THƯỜNG
            else {
                Write-LogNgam "Chế độ: 7-Zip Chuẩn."
                $passArg = if (![string]::IsNullOrWhiteSpace($pass)) { "-p`"$pass`"" } else { "" }
                
                if ($passArg -ne "") {
                    $args = @("a", "-t7z", "-m0=lzma2", $lzmaParam, "-r", "-y", $passArg, "-mhe=on", "`"$dest`"", "`"$targetPath`"")
                } else {
                    $args = @("a", "-t7z", "-m0=lzma2", $lzmaParam, "-r", "-y", "`"$dest`"", "`"$targetPath`"")
                }
                
                Write-LogNgam "Đang gọi 7-Zip nén trực tiếp ra đích..."
                $process = Start-Process -FilePath $enginePath -ArgumentList $args -WindowStyle Hidden -Wait -PassThru
                Write-LogNgam "7-Zip Exit Code: $($process.ExitCode)"
                
                if ($process.ExitCode -eq 0) { return "SUCCESS" }
                else { return "LỖI LÕI NÉN (Exit Code: $($process.ExitCode))" }
            }
        } catch {
            Write-LogNgam "CRASH JOB NÉN: $($_.Exception.Message)"
            return "CRASH: $($_.Exception.Message)"
        }
    }

    Write-Log "[DEBUG] Đang khởi tạo Job ngầm..."
    $CurrentJob = Start-Job -ScriptBlock $JobScript -ArgumentList $txtSrc.Text, $txtDest.Text, $levelIndex, $txtPackPass.Text, $global:DebugLogPath, $global:Temp7zPath, $global:CSharpCode, $isPtpcMode
    Write-Log "[DEBUG] Job ID: $($CurrentJob.Id) đã được tạo."

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(500)
    $timer.Tag = $CurrentJob.Id 

    $timer.Add_Tick({
        $currentTimer = $this
        $trackedJobId = $currentTimer.Tag
        $trackedJob = Get-Job -Id $trackedJobId -ErrorAction SilentlyContinue

        if ($trackedJob -ne $null) {
            # Write-Log "[DEBUG] Đang kiểm tra Job ID $trackedJobId | Trạng thái: $($trackedJob.State)"
            if ($trackedJob.State -ne 'Running') {
                $currentTimer.Stop() 
                Write-Log "[DEBUG] Job đã ngừng chạy. Đang thu thập kết quả..."
                try {
                    $rawResult = Receive-Job -Job $trackedJob -ErrorAction Stop
                    $resultStr = ($rawResult | Out-String).Trim()
                    Write-Log "[DEBUG] Kết quả thô nhận được: '$resultStr'"
                    
                    if ($resultStr -match "SUCCESS") { 
                        Write-Log "HOÀN TẤT: Đã xuất file thành công ra $($txtDest.Text)" 
                    } else { 
                        Write-Log "THẤT BẠI: $resultStr" 
                    }
                    Remove-Job -Id $trackedJobId -Force
                } catch { Write-Log "LỖI HỆ THỐNG ĐỌC JOB: $($_.Exception.Message)" } 
                finally {
                    $btnPack.IsEnabled = $true
                    $pbStatus.IsIndeterminate = $false 
                }
            }
        } else {
            # Nếu Job bị bốc hơi (rất hiếm khi xảy ra)
            $currentTimer.Stop()
            Write-Log "[LỖI NGHIÊM TRỌNG] Mất kết nối với luồng ngầm!"
            $btnPack.IsEnabled = $true
            $pbStatus.IsIndeterminate = $false 
        }
    })
    $timer.Start()
})

# ==========================================
# XỬ LÝ BUNG FILE (SMART DETECT HEADER)
# ==========================================
$btnUnpack.Add_Click({
    if ($txtOpen.Text -eq "" -or $txtExtract.Text -eq "") { Write-Log "LỖI: Hãy chọn đủ đường dẫn!"; return }
    
    $magicHeader = ""
    try {
        $fs = [System.IO.File]::OpenRead($txtOpen.Text)
        $buffer = New-Object byte[] 4
        $fs.Read($buffer, 0, 4) | Out-Null
        $fs.Close()
        $magicHeader = [System.Text.Encoding]::UTF8.GetString($buffer)
    } catch {
        Write-Log "LỖI: Không thể đọc phân tích ruột file."
        return
    }

    $isPtpcFile = ($magicHeader -eq "PTPC")
    
    $btnUnpack.IsEnabled = $false
    $pbStatus.IsIndeterminate = $true 
    
    if ($isPtpcFile) { Write-Log "[UI] Phát hiện Lõi PTPC: Bắt đầu giải mã lượng tử & bung nén..." } 
    else { Write-Log "[UI] Phát hiện định dạng Chuẩn: Gọi thẳng Engine bung nén..." }

    $JobScript = {
        param($openFile, $extractDir, $pass, $logPath, $enginePath, $codeString, $isPtpcFile)
        Function Write-LogNgam ($msg) { Add-Content -Path $logPath -Value "[$(Get-Date -f 'HH:mm:ss')] $msg" -Encoding UTF8 }

        try {
            Write-LogNgam "--- BẮT ĐẦU JOB BUNG FILE ---"
            
            if ($isPtpcFile) {
                Write-LogNgam "Giải mã PTPC mode..."
                if (-not ("PhatTanArchiver_v8_1" -as [type])) { Add-Type -TypeDefinition $codeString -Language CSharp }
                
                $temp7zFile = "$env:TEMP\ptpc_temp_lzma_$(Get-Random).7z"
                $finalPass = if ([string]::IsNullOrWhiteSpace($pass)) { "NO_PASSWORD_SET_DEFAULT_KEY_2026" } else { $pass }
                
                $res = [PhatTanArchiver_v8_1]::DecryptOnly($openFile, $temp7zFile, $finalPass)
                Write-LogNgam "C# Giải mã báo cáo: $res"
                
                if ($res -eq "SUCCESS" -and (Test-Path $temp7zFile)) {
                    Write-LogNgam "Bung file 7z ẩn vào đích..."
                    $args = @("x", "`"$temp7zFile`"", "-o`"$extractDir`"", "-y")
                    $process = Start-Process -FilePath $enginePath -ArgumentList $args -WindowStyle Hidden -Wait -PassThru
                    Remove-Item $temp7zFile -Force
                    
                    Write-LogNgam "Exit Code bung: $($process.ExitCode)"
                    if ($process.ExitCode -eq 0) { return "SUCCESS" }
                    else { return "LỖI BUNG DỮ LIỆU (Exit Code: $($process.ExitCode))" }
                } else {
                    if (Test-Path $temp7zFile) { Remove-Item $temp7zFile -Force }
                    return $res 
                }
            } else {
                Write-LogNgam "Bung file Chuẩn 7-Zip mode..."
                $passArg = if (![string]::IsNullOrWhiteSpace($pass)) { "-p`"$pass`"" } else { "" }
                if ($passArg -ne "") {
                    $args = @("x", "`"$openFile`"", "-o`"$extractDir`"", "-y", $passArg)
                } else {
                    $args = @("x", "`"$openFile`"", "-o`"$extractDir`"", "-y")
                }
                
                $process = Start-Process -FilePath $enginePath -ArgumentList $args -WindowStyle Hidden -Wait -PassThru
                Write-LogNgam "Exit Code bung chuẩn: $($process.ExitCode)"
                
                if ($process.ExitCode -eq 0) { return "SUCCESS" }
                else { return "LỖI BUNG FILE TIÊU CHUẨN (Sai mật khẩu hoặc file hỏng)" }
            }
        } catch {
            Write-LogNgam "CRASH JOB BUNG: $($_.Exception.Message)"
            return "CRASH: $($_.Exception.Message)"
        }
    }

    Write-Log "[DEBUG] Đang khởi tạo Job bung file ngầm..."
    $CurrentJob = Start-Job -ScriptBlock $JobScript -ArgumentList $txtOpen.Text, $txtExtract.Text, $txtUnpackPass.Text, $global:DebugLogPath, $global:Temp7zPath, $global:CSharpCode, $isPtpcFile
    Write-Log "[DEBUG] Job ID: $($CurrentJob.Id) đã được tạo."

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(500)
    $timer.Tag = $CurrentJob.Id

    $timer.Add_Tick({
        $currentTimer = $this
        $trackedJobId = $currentTimer.Tag
        $trackedJob = Get-Job -Id $trackedJobId -ErrorAction SilentlyContinue

        if ($trackedJob -ne $null) {
            if ($trackedJob.State -ne 'Running') {
                $currentTimer.Stop()
                Write-Log "[DEBUG] Job đã ngừng chạy. Đang thu thập kết quả..."
                try {
                    $rawResult = Receive-Job -Job $trackedJob -ErrorAction Stop
                    $resultStr = ($rawResult | Out-String).Trim()
                    Write-Log "[DEBUG] Kết quả thô nhận được: '$resultStr'"
                    
                    if ($resultStr -match "SUCCESS") { 
                        Write-Log "HOÀN TẤT: Đã bung file thành công ra thư mục đích!" 
                    } else { Write-Log "THẤT BẠI: $resultStr" }
                    Remove-Job -Id $trackedJobId -Force
                } catch { Write-Log "LỖI HỆ THỐNG ĐỌC JOB." } 
                finally {
                    $btnUnpack.IsEnabled = $true
                    $pbStatus.IsIndeterminate = $false 
                }
            }
        } else {
            $currentTimer.Stop()
            Write-Log "[LỖI NGHIÊM TRỌNG] Mất kết nối với luồng ngầm!"
            $btnUnpack.IsEnabled = $true
            $pbStatus.IsIndeterminate = $false 
        }
    })
    $timer.Start()
})

$window.Add_Closed({
    if (Test-Path $global:Temp7zPath) { Remove-Item $global:Temp7zPath -Force }
})

Write-Log "Khởi động Phat Tan PC v8.1 (ALL-IN-ONE + DEBUG)..."
Write-Log "Tool đã tích hợp Tracking Log. Sẵn sàng theo dõi mọi luồng ngầm!"

$window.ShowDialog() | Out-Null
