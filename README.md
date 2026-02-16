# PhattanPC Rescue Toolkit (PRT)

PhattanPC Rescue Toolkit là giải pháp tất-cả-trong-một được phát triển trên nền tảng PowerShell nhằm cung cấp bộ công cụ kiểm tra, tối ưu hóa, cứu hộ và cài đặt Windows chuyên nghiệp. Script được thiết kế để hoạt động ổn định trên mọi môi trường Windows từ WinPE, Windows Lite (đã bị lược bỏ module) đến các bản Windows Full cập nhật mới nhất. Công cụ này không giả định bất kỳ module hay câu lệnh nào luôn tồn tại và luôn tích hợp sẵn các phương án dự phòng (fallback).

---


[![PowerShell](https://img.shields.io/badge/Language-PowerShell-blue?logo=powershell&style=flat-square)](https://microsoft.com/powershell)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20WinPE-0078D6?logo=windows&style=flat-square)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-Stable-green?style=flat-square)]()

> **"Không chỉ là Script, đây là giải pháp sinh tồn cho Windows."**


✅ Chạy mượt mà trên: **WinPE cứu hộ**, **Windows Lite** (bị cắt giảm module) và **Windows Full**.

---

## ⚡ Cài đặt & Sử dụng (Quick Start)

Khởi chạy ngay lập tức chỉ với một dòng lệnh duy nhất (Yêu cầu quyền Administrator):

```powershell
Set-ExecutionPolicy Unrestricted -Scope Process -Force; irm [https://tinyurl.com/phattanpc](https://tinyurl.com/phattanpc) | iex

```
---

## Danh sách tính năng chi tiết

### 1. Chẩn đoán và Thông tin Hệ thống (Hardware Info)
* Quét cấu hình chuyên sâu: Trích xuất thông tin chi tiết về CPU, RAM (Bus, dung lượng), Mainboard và tình trạng sức khỏe ổ cứng thông qua các lớp dữ liệu hệ thống.
  
* Tối ưu RAM ảo (Virtual RAM): Tự động tính toán và thiết lập Pagefile dựa trên dung lượng RAM vật lý thực tế để ngăn chặn tình trạng treo máy trên các thiết bị cấu hình thấp.
  
* Thiết lập mạng (Network Setup): Cấu hình nhanh IP tĩnh/động, thay đổi DNS để tăng tốc độ truy cập và tối ưu hóa băng thông mạng.
  
* Kiểm tra Pin và Ổ cứng: Cung cấp thông tin chi tiết về mức độ chai pin, số giờ hoạt động và tình trạng S.M.A.R.T của SSD/HDD.
  
* Tự động nhận diện hệ thống: Script tự động phát hiện chuẩn Boot UEFI/BIOS và cấu trúc phân vùng GPT/MBR để đưa ra phương án xử lý phù hợp.

### 2. Kho ứng dụng tự động (Silent App Store)

* Tải phần mềm tự động: Menu tích hợp các phần mềm thiết yếu như Google Chrome, Microsoft Office, Zalo, UltraView, Unikey và WinRAR.
  
* Cài đặt im lặng (Silent Install): Hỗ trợ quy trình cài đặt tự động hoàn toàn, giúp tiết kiệm thời gian và giảm thiểu các thao tác xác nhận thủ công.
  
* Quản lý ứng dụng rác: Hỗ trợ gỡ bỏ các ứng dụng Bloatware có sẵn trên Windows để giải phóng tài nguyên và làm nhẹ hệ thống.

### 3. Trung tâm Cứu hộ và Bảo mật (Security and Rescue)

* Quản lý Bitlocker: Tự động phát hiện trạng thái mã hóa, hỗ trợ tạm dừng (suspend) hoặc tắt Bitlocker để tránh khóa ổ cứng khi cài đặt lại hệ thống.
  
* Xử lý mã hóa EFS: Vô hiệu hóa tính năng Encrypting File System để đảm bảo quyền truy cập tệp tin trên các môi trường cứu hộ như WinPE.
  
* Điều khiển bảo mật: Cho phép bật hoặc tắt nhanh Windows Defender và Windows Update chỉ với một thao tác duy nhất.
  
* Khôi phục mật khẩu và Tài khoản: Cung cấp các công cụ kiểm tra và quản lý tài khoản người dùng trong các trường hợp khẩn cấp hoặc quên mật khẩu Admin.

### 4. Công cụ cài đặt Windows và Triển khai

* Tạo USB cứu hộ chuyên nghiệp: Hỗ trợ tạo bộ cài Windows hoặc USB cứu hộ đa năng tương thích với cả máy đời cũ và máy đời mới.
  
* Tải ISO chính chủ: Cung cấp liên kết tải trực tiếp các bản Windows ISO sạch từ máy chủ của Microsoft.
  
* Triển khai hệ thống: Hỗ trợ nạp Boot (BCD), phân chia phân vùng bằng Diskpart và cấu hình bcdboot một cách chính xác cho cả chuẩn GPT và MBR.
  
* Sao lưu và Phục hồi Driver: Cho phép xuất (export) toàn bộ driver của hệ thống hiện tại để tái sử dụng sau khi cài đặt mới Windows.

---

## Cơ chế hoạt động và Độ ổn định (Failover Architecture)

* Điểm khác biệt của PhattanPC Rescue Toolkit nằm ở quy tắc Failover nghiêm ngặt, đảm bảo script không bị crash và luôn hoạt động ngay cả khi hệ thống thiếu hụt module trầm trọng:

1. Ưu tiên 1 (CIM): Sử dụng Get-CimInstance để truy xuất dữ liệu nhanh và hiện đại nhất.
2. Ưu tiên 2 (WMI): Nếu CIM không tồn tại hoặc bị lỗi do máy cũ hoặc bản Windows bị cắt giảm, script tự động chuyển sang Get-WmiObject hoặc [WMI].
3. Ưu tiên 3 (COM/Registry/CLI): Nếu các lớp quản trị trên đều hỏng, script sẽ sử dụng COM, Registry hoặc gọi trực tiếp các lệnh hệ thống như diskpart, wmic, bcdedit và tiến hành phân tích dữ liệu chữ (text parsing).

Mọi bước thực hiện đều tích hợp try/catch, kiểm tra sự tồn tại của câu lệnh (Get-Command) và kiểm tra quyền hạn quản trị để đảm bảo tính an toàn tuyệt đối.

---


  
## Các công cụ can thiệp sâu vào hệ thống để xử lý sự cố.

 * Bitlocker Killer: Tự động quét trạng thái mã hóa. Hỗ trợ tắt/mở khóa Bitlocker hoặc Suspend bảo vệ để cài Win/Ghost máy an toàn mà không mất dữ liệu.
 * EFS Decryptor: Tắt tính năng mã hóa file hệ thống (Encrypting File System) - cực kỳ quan trọng khi làm việc trên môi trường WinPE/Windows Lite.
 * Defender Switch: Bật/Tắt Windows Defender và Windows Update chỉ với 1 cú click (Hiệu quả vĩnh viễn).

## 3. 📦 Silent App Store (Kho phần mềm tự động)

Cài đặt phần mềm chưa bao giờ nhanh đến thế.
 * One-Click Install: Menu tích hợp sẵn các phần mềm thiết yếu: Chrome, WinRAR, Unikey, UltraViewer, Office, Zalo...
 * Silent Mode: Tự động cài đặt ngầm (Silent Install), tự động kích hoạt, không hiện popup quảng cáo, không cần bấm "Next" liên tục.
 * Portable Support: Hỗ trợ chạy các tool Portable ngay trên RAM mà không cần xả nén ra ổ cứng.

## 4. 💿 Deployment Studio (Hỗ trợ cài Win)

 * ISO Downloader: Get link tải file ISO Windows gốc (Clean) trực tiếp từ server Microsoft (tốc độ cao).
 * Boot Master: Hỗ trợ nạp Boot (BCD), sửa lỗi mất boot cho cả 2 chuẩn UEFI (GPT) và Legacy (MBR).
 * USB Maker: Tạo USB Boot cứu hộ đa năng hỗ trợ cả 2 chuẩn boot.

## 🛡️ Kiến trúc Failover (Cơ chế chống Crash)
Đây là "trái tim" làm nên sự khác biệt của PhattanPC Toolkit.
Chúng tôi không giả định môi trường của bạn là hoàn hảo. Script được viết với tư duy "Defensive Programming" (Lập trình phòng thủ):

| Ưu tiên | Phương thức | Mô tả kỹ thuật |
|---|---|---|
| 🥇 Cấp 1 | CIM (Common Information Model) | Sử dụng Get-CimInstance. Đây là chuẩn hiện đại, nhanh và nhẹ nhất. |
| 🥈 Cấp 2 | WMI (Windows Management Instrumentation) | Nếu CIM lỗi (thường gặp trên Win 7 hoặc Win Lite), tự động chuyển sang Get-WmiObject. |
| 🥉 Cấp 3 | Native CLI Parsing | Nếu cả WMI bị hỏng (Class not found), Script sẽ gọi trực tiếp diskpart, bcdedit, wmic và phân tích chuỗi văn bản (Text Parsing) để lấy dữ liệu. |

> ✅ Kết quả: Script KHÔNG BAO GIỜ CRASH dù chạy trên bản Windows bị cắt giảm module nặng nề nhất hay môi trường WinPE thiếu thư viện.

> 
## 📋 Yêu cầu hệ thống & Tương thích

 * OS: Windows 7 / 8.1 / 10 / 11 / Server.
 * Môi trường: Windows Full, Windows Lite, WinPE (Anhdv, DLC, NHV...).
 * PowerShell: Phiên bản 2.0 trở lên.
 * Kết nối mạng: Cần Internet cho lần chạy đầu tiên để tải module lõi.

## 👨‍💻 Thông tin tác giả

 * Developer: PhattanPC
 * Triết lý: "Tối ưu - Ổn định - Đa nền tảng"
* Số điện thoại liên hệ: 0823883028
* Support: https://www.facebook.com/share/189TQ4r4g9/

* Developed with ❤️ and a lot of coffee.

