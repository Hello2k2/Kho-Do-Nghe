# 🚀 PhattanPC PowerShell Tool

> **Giải pháp tất-cả-trong-một (All-in-one)** để kiểm tra, tối ưu hóa, cứu hộ và cài đặt Windows siêu tốc qua dòng lệnh PowerShell.  
> Được thiết kế tối ưu để chạy mượt mà trên mọi môi trường: **WinPE, Windows Lite (bị cắt giảm) và Windows Full.**

---

## 📌 Cách sử dụng nhanh

Mở **PowerShell với quyền Administrator** và dán lệnh sau:

```powershell
irm [https://tinyurl.com/phattanpc](https://tinyurl.com/phattanpc) | iex

✨ Danh sách tính năng chi tiết

​🖥️ Hệ thống & Phần cứng (Hardware Info)
​Check cấu hình chuyên sâu: Quét thông tin CPU, RAM, Mainboard, ổ cứng.
​Tối ưu RAM ảo (Virtual RAM): Tự động tính toán và set Pagefile chuẩn để máy yếu không bị crash.
​Network Setup: Cấu hình IP, DNS, tối ưu băng thông mạng.

​📦 Kho Phần Mềm (App Store)
​Tải App tự động: Menu tích hợp tải nhanh các phần mềm thiết yếu (Chrome, Office, Zalo, UltraView...).
​Silent Install: Hỗ trợ cài đặt tự động không cần thao tác nhiều.

​🔐 Bảo mật & Cứu hộ (Security & Rescue)
​Quét & Tắt Bitlocker: Tự động phát hiện và mở khóa Bitlocker để tránh mất dữ liệu khi cài Win.
​Xử lý EFS: Tắt mã hóa Encrypting File System (tính năng quan trọng cho WinPE/Lite).
​Control Center:
​Bật/Tắt Windows Defender (1-click).
​Bật/Tắt Windows Update.

​💿 Cài đặt Windows & USB Boot
​Tạo USB Boot: Hỗ trợ tạo USB cứu hộ hoặc bộ cài Windows chuẩn UEFI/Legacy.
​Tải ISO Windows Clean: Link tải trực tiếp từ Microsoft.

​Hỗ trợ cài đặt: Nạp boot (BCD), phân vùng Disk cho cả 2 chuẩn GPT/MBR.

​🛠️ Cơ chế hoạt động (Failover - Không bao giờ Crash)
​Script được phát triển với quy tắc ưu tiên độ tương thích tuyệt đối, đảm bảo chạy được trên cả những bản Windows bị cắt giảm module nặng nề nhất:

​🥇 Ưu tiên 1 (CIM): Dùng Get-CimInstance (Nhanh, chuẩn, hiện đại).

​🥈 Ưu tiên 2 (WMI): Nếu CIM lỗi (do máy cũ hoặc Win Lite bị cắt), tự động chuyển sang Get-WmiObject.

​🥉 Ưu tiên 3 (CLI Parse): Nếu WMI hỏng, script sẽ chạy lệnh CMD thuần (diskpart, bcdedit, wmic...) và phân tích text trả về để lấy dữ liệu.

​✅ Tự động nhận diện: Script tự biết đang chạy trên WinPE hay Windows thường để ẩn/hiện tính năng phù hợp.
​👨‍💻 Tác giả

​Phát triển bởi PhattanPC - Tối ưu, Ổn định, Đa nền tảng.
