# Hướng Dẫn Triển Khai (Deployment Guide) - StayHub

Tài liệu này cung cấp các bước cần thiết để đóng gói và triển khai ứng dụng StayHub lên môi trường Production (VPS, AWS, Google Cloud, v.v.).

---

## 1. Triển Khai Backend (Spring Boot + PostgreSQL) với Docker

Chúng ta sẽ sử dụng Docker và Docker Compose để thiết lập tự động hóa toàn bộ môi trường (Database + API). Đảm bảo server của bạn đã cài đặt sẵn **Docker** và **Docker Compose**.

### Các bước thực hiện:
1. Clone mã nguồn về máy chủ (hoặc copy thư mục `StayHub_backend` lên server).
2. Mở terminal/cmd tại thư mục `StayHub_backend` (Nơi chứa file `docker-compose.yml`).
3. Chạy lệnh:
   ```bash
   docker-compose up -d --build
   ```
   Lệnh này sẽ:
   - Tải image PostgreSQL và khởi tạo database `stayhub_db`.
   - Build image cho API Spring Boot thông qua multi-stage `Dockerfile`.
   - Chạy cả 2 container và liên kết chúng với nhau ở chế độ nền (detached mode).

4. **Kiểm tra Logs:**
   Để xem log của ứng dụng, chạy:
   ```bash
   docker-compose logs -f stayhub-api
   ```

5. **Dừng hệ thống:**
   ```bash
   docker-compose down
   ```

### Biến Môi Trường (Environment Variables)
Nếu bạn cần thay đổi thông tin kết nối DB, Secret Key JWT hoặc Gemini API Key, hãy chỉnh sửa trực tiếp trong file `docker-compose.yml` (mục `environment` của `stayhub-api`).

---

## 2. Triển Khai Frontend (Flutter) thành file APK

Sau khi deploy Backend thành công và lấy được IP/Domain của server, hãy cập nhật Base URL trong app Flutter rồi tiến hành build bản Release.

### Các bước thực hiện:
1. Cập nhật Base URL của API trong file cấu hình (nếu có, hoặc trong `api_client.dart`) thành Domain/IP thực tế. Ví dụ: `http://123.45.67.89:8080` hoặc `https://api.stayhub.com`.
2. Mở Terminal tại thư mục `StayHub_frontend`.
3. Làm sạch project:
   ```bash
   flutter clean
   flutter pub get
   ```
4. Build APK (dành cho thiết bị Android):
   ```bash
   flutter build apk --release
   ```
   Kết quả: File APK sẽ được tạo ra tại `build/app/outputs/flutter-apk/app-release.apk`.
5. Nếu đưa lên Google Play Store, chạy:
   ```bash
   flutter build appbundle
   ```
   Kết quả: `build/app/outputs/bundle/release/app-release.aab`.

*(Lưu ý: Mặc định Flutter sử dụng debug key cho release build ở máy local. Để đưa lên Google Play, bạn cần tạo keystore và setup `signingConfigs` thật trong `android/app/build.gradle.kts`)*

---

**Chúc bạn vận hành hệ thống thành công!** 🚀
