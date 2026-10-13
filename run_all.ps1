# Run all StayHub services
$root = $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }

Write-Host "🚀 Đang khởi chạy toàn bộ dịch vụ StayHub..." -ForegroundColor Cyan

# 1. Chạy Backend trong cửa sổ mới
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$root\StayHub_backend\backend\stayhub-api'; ./mvnw spring-boot:run"

# 2. Chờ 5s cho Backend khởi động rồi chạy Frontend
Start-Sleep -Seconds 5
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$root\StayHub_frontend'; flutter run -d chrome"

Write-Host "✅ Đã kích hoạt cả Backend (cổng 8080) và Frontend (Flutter)!" -ForegroundColor Green
