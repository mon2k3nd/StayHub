# 🤖 HƯỚNG DẪN DÀNH CHO ANTIGRAVITY AI TRÊN MÁY MỚI (AUTOMATED SETUP)

Tài liệu này được tạo sẵn để **Antigravity AI trên laptop mới** đọc và tự động hóa 100% quy trình thiết lập dự án StayHub khi người dùng cung cấp link repo.

---

## 🛠️ THÔNG SỐ HỆ THỐNG MẶC ĐỊNH
- **Repository:** `https://github.com/mon2k3nd/StayHub.git`
- **Cơ sở dữ liệu:** PostgreSQL 15 - 18
  - Database: `stayhub_db`
  - Username: `postgres`
  - Password: `12345678`
  - Port: `5432`
  - File Backup: `stayhub_db_backup.sql`
- **Backend:** Java Spring Boot JDK 17, Port: `8080` (thư mục `StayHub_backend/backend/stayhub-api`)
- **Frontend:** Flutter 3.24+ / 3.44+ (thư mục `StayHub_frontend`)
- **AI Module (Option):** Python 3.10+ (thư mục `StayHub_AI`)

---

## 🚀 QUY TRÌNH THỰC THI TỰ ĐỘNG CHO ANTIGRAVITY AI:

Khi người dùng yêu cầu setup hoặc chạy dự án, AI hãy lần lượt thực hiện các bước sau bằng công cụ dòng lệnh:

### 1. Kéo mã nguồn (nếu chưa có trong thư mục hiện tại)
```powershell
git clone https://github.com/mon2k3nd/StayHub.git
cd StayHub
```

### 2. Chạy kịch bản tự động hóa 1-click
Chỉ cần thực thi script có sẵn tại thư mục gốc:
```powershell
.\setup.ps1
```
Script này sẽ tự động:
- Khôi phục `StayHub_frontend/.env.local`
- Kết nối PostgreSQL (trực tiếp hoặc qua Docker) và nạp `stayhub_db_backup.sql`
- Chạy `flutter pub get`
- Kiểm tra Java và Flutter SDK

### 3. Khởi động hệ thống
- Khởi động Backend:
  ```powershell
  cd StayHub_backend/backend/stayhub-api
  ./mvnw spring-boot:run
  ```
- Khởi động Frontend:
  ```powershell
  cd StayHub_frontend
  flutter run -d chrome
  ```
- Hoặc chạy nhanh cả hai:
  ```powershell
  .\run_all.ps1
  ```
