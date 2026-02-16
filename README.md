
# 🚀 PhattanPC Rescue Toolkit (PRT)

[![PowerShell](https://img.shields.io/badge/Language-PowerShell-blue?logo=powershell&style=flat-square)](https://microsoft.com/powershell)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20WinPE-0078D6?logo=windows&style=flat-square)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-Stable-green?style=flat-square)]()

> **"Không chỉ là Script, đây là giải pháp sinh tồn cho Windows."**

**PhattanPC Toolkit** là công cụ PowerShell đa năng được thiết kế đặc biệt cho Kỹ thuật viên IT và Người dùng nâng cao. Giải pháp tập trung vào **tốc độ**, **sự ổn định** và khả năng **tương thích ngược** tuyệt đối. 

✅ Chạy tốt trên mọi môi trường khắc nghiệt nhất: từ **WinPE cứu hộ**, **Windows Lite** (bị cắt giảm module) đến **Windows Full** cập nhật mới nhất.

---

## ⚡ Cài đặt & Sử dụng (Quick Start)

Khởi chạy ngay lập tức chỉ với một dòng lệnh. Không cần tải file thủ công, không cần cài đặt rườm rà.

1. Mở **PowerShell** với quyền **Administrator** (Run as Admin).
2. Copy và dán lệnh sau:

```powershell
Set-ExecutionPolicy Unrestricted -Scope Process -Force; irm [https://tinyurl.com/phattanpc](https://tinyurl.com/phattanpc) | iex

> 💡 Mẹo: Lệnh trên đã bao gồm tự động mở khóa Policy để tránh lỗi khi chạy script.
>

🔥 Tính năng nổi bật (Feature Highlights)

1. 🖥️ Hardware Inspector (Kiểm tra phần cứng)
Không chỉ hiển thị thông tin, tool thực hiện Deep Scan để đưa ra thông số chính xác nhất.
 * Chi tiết chuyên sâu: Hiển thị Model Mainboard, Serial Number, Bus RAM, tình trạng sức khỏe ổ cứng (Health Status).
 * Phát hiện linh kiện: Nhận diện chính xác CPU, GPU để tránh bị lừa bởi các thủ thuật fake cấu hình.
 * Tối ưu RAM ảo (Smart Pagefile): Tự động tính toán dung lượng RAM thực tế để set RAM ảo (Pagefile) phù hợp, ngăn chặn lỗi Out of Memory trên các máy cấu hình yếu (2GB/4GB RAM).

2. 🔐 Security & Rescue Center (Bảo mật & Cứu hộ)
Các công cụ can thiệp sâu vào hệ thống để xử lý sự cố.
 * Bitlocker Killer: Tự động quét trạng thái mã hóa. Hỗ trợ tắt/mở khóa Bitlocker hoặc Suspend bảo vệ để cài Win/Ghost máy an toàn mà không mất dữ liệu.
 * EFS Decryptor: Tắt tính năng mã hóa file hệ thống (Encrypting File System) - cực kỳ quan trọng khi làm việc trên môi trường WinPE/Windows Lite.
 * Defender Switch: Bật/Tắt Windows Defender và Windows Update chỉ với 1 cú click (Hiệu quả vĩnh viễn).

3. 📦 Silent App Store (Kho phần mềm tự động)
Cài đặt phần mềm chưa bao giờ nhanh đến thế.
 * One-Click Install: Menu tích hợp sẵn các phần mềm thiết yếu: Chrome, WinRAR, Unikey, UltraViewer, Office, Zalo...
 * Silent Mode: Tự động cài đặt ngầm (Silent Install), tự động kích hoạt, không hiện popup quảng cáo, không cần bấm "Next" liên tục.
 * Portable Support: Hỗ trợ chạy các tool Portable ngay trên RAM mà không cần xả nén ra ổ cứng.

4. 💿 Deployment Studio (Hỗ trợ cài Win)
 * ISO Downloader: Get link tải file ISO Windows gốc (Clean) trực tiếp từ server Microsoft (tốc độ cao).
 * Boot Master: Hỗ trợ nạp Boot (BCD), sửa lỗi mất boot cho cả 2 chuẩn UEFI (GPT) và Legacy (MBR).
 * USB Maker: Tạo USB Boot cứu hộ đa năng hỗ trợ cả 2 chuẩn boot.
🛡️ Kiến trúc Failover (Cơ chế chống Crash)
Đây là "trái tim" làm nên sự khác biệt của PhattanPC Toolkit.
Chúng tôi không giả định môi trường của bạn là hoàn hảo. Script được viết với tư duy "Defensive Programming" (Lập trình phòng thủ):
| Ưu tiên | Phương thức | Mô tả kỹ thuật |
|---|---|---|
| 🥇 Cấp 1 | CIM (Common Information Model) | Sử dụng Get-CimInstance. Đây là chuẩn hiện đại, nhanh và nhẹ nhất. |
| 🥈 Cấp 2 | WMI (Windows Management Instrumentation) | Nếu CIM lỗi (thường gặp trên Win 7 hoặc Win Lite), tự động chuyển sang Get-WmiObject. |
| 🥉 Cấp 3 | Native CLI Parsing | Nếu cả WMI bị hỏng (Class not found), Script sẽ gọi trực tiếp diskpart, bcdedit, wmic và phân tích chuỗi văn bản (Text Parsing) để lấy dữ liệu. |
> ✅ Kết quả: Script KHÔNG BAO GIỜ CRASH dù chạy trên bản Windows bị cắt giảm module nặng nề nhất hay môi trường WinPE thiếu thư viện.

> 
📋 Yêu cầu hệ thống & Tương thích
 * OS: Windows 7 / 8.1 / 10 / 11 / Server.
 * Môi trường: Windows Full, Windows Lite, WinPE (Anhdv, DLC, NHV...).
 * PowerShell: Phiên bản 2.0 trở lên.
 * Kết nối mạng: Cần Internet cho lần chạy đầu tiên để tải module lõi.

👨‍💻 Thông tin tác giả
 * Developer: PhattanPC
 * Triết lý: "Tối ưu - Ổn định - Đa nền tảng"
 * Support: [Link Facebook/Zalo của bạn]
Developed with ❤️ and a lot of coffee.

