# ========================================================
# StayHub - Automation Setup Script
# Tự động thiết lập môi trường và database trên máy mới
# ========================================================

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "🚀 ĐANG TỰ ĐỘNG THIẾT LẬP DỰ ÁN STAYHUB..." -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$root = $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }

# 1. Khôi phục file .env.local cho Frontend
$envFile = Join-Path $root "StayHub_frontend\.env.local"
if (-not (Test-Path $envFile)) {
    Write-Host "`n[1/4] 🔑 Thiết lập cấu hình API Keys cho Frontend..." -ForegroundColor Yellow
    "GEMINI_API_KEY=" | Out-File -FilePath $envFile -Encoding utf8
    Write-Host "   -> Đã tạo StayHub_frontend\.env.local thành công!" -ForegroundColor Green
} else {
    Write-Host "`n[1/4] 🔑 Cấu hình .env.local đã sẵn sàng." -ForegroundColor Green
}

# 2. Khôi phục Cơ sở dữ liệu PostgreSQL
Write-Host "`n[2/4] 🗄️ Thiết lập Cơ sở dữ liệu PostgreSQL (stayhub_db)..." -ForegroundColor Yellow
$sqlBackup = Join-Path $root "stayhub_db_backup.sql"

$hasDocker = Get-Command docker -ErrorAction SilentlyContinue
$hasPsql = Get-Command psql -ErrorAction SilentlyContinue

if (-not $hasPsql) {
    # Thử tìm psql trong thư mục cài mặc định của PostgreSQL
    $pgBins = Get-ChildItem "C:\Program Files\PostgreSQL" -Directory -ErrorAction SilentlyContinue | ForEach-Object { Join-Path $_.FullName "bin" }
    foreach ($bin in $pgBins) {
        if (Test-Path (Join-Path $bin "psql.exe")) {
            $env:Path = "$bin;" + $env:Path
            $hasPsql = Get-Command psql -ErrorAction SilentlyContinue
            break
        }
    }
}

if ($hasPsql) {
    Write-Host "   -> Tìm thấy PostgreSQL cài đặt trên máy. Đang restore dữ liệu..." -ForegroundColor Green
    $env:PGPASSWORD = "12345678"
    & createdb -U postgres -h localhost -p 5432 stayhub_db 2>$null
    if (Test-Path $sqlBackup) {
        & psql -U postgres -h localhost -p 5432 -d stayhub_db -f $sqlBackup
        Write-Host "   -> Đã khôi phục toàn bộ database 'stayhub_db' thành công!" -ForegroundColor Green
    } else {
        Write-Host "   [!] Không tìm thấy file stayhub_db_backup.sql" -ForegroundColor Red
    }
} elseif ($hasDocker) {
    Write-Host "   -> Không có PostgreSQL trực tiếp, nhưng tìm thấy Docker! Đang khởi động Postgres qua Docker..." -ForegroundColor Green
    docker run --name stayhub-db -e POSTGRES_DB=stayhub_db -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=12345678 -p 5432:5432 -d postgres:15-alpine 2>$null
    Start-Sleep -Seconds 5
    if (Test-Path $sqlBackup) {
        Get-Content $sqlBackup | docker exec -i stayhub-db psql -U postgres -d stayhub_db
        Write-Host "   -> Đã khôi phục dữ liệu qua Docker PostgreSQL thành công!" -ForegroundColor Green
    }
} else {
    Write-Host "   [!] Chưa phát hiện PostgreSQL hoặc Docker. Vui lòng cài đặt PostgreSQL hoặc Docker Desktop để nạp database." -ForegroundColor Red
}

# 3. Tải thư viện Frontend (Flutter)
Write-Host "`n[3/4] 📱 Đang tải dependencies cho Flutter..." -ForegroundColor Yellow
$hasFlutter = Get-Command flutter -ErrorAction SilentlyContinue
if ($hasFlutter) {
    Push-Location (Join-Path $root "StayHub_frontend")
    flutter pub get
    Pop-Location
    Write-Host "   -> Flutter dependencies đã sẵn sàng!" -ForegroundColor Green
} else {
    Write-Host "   [!] Chưa tìm thấy lệnh 'flutter'. Vui lòng cài đặt Flutter SDK và thêm vào PATH." -ForegroundColor Red
}

# 4. Kiểm tra Backend (Maven / Java)
Write-Host "`n[4/4] ☕ Kiểm tra môi trường Backend Java..." -ForegroundColor Yellow
$hasJava = Get-Command java -ErrorAction SilentlyContinue
if ($hasJava) {
    Write-Host "   -> Java đã sẵn sàng!" -ForegroundColor Green
} else {
    Write-Host "   [!] Chưa tìm thấy Java JDK 17+. Vui lòng cài đặt Java JDK 17." -ForegroundColor Red
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "🎉 HOÀN TẤT THIẾT LẬP DỰ ÁN STAYHUB!" -ForegroundColor Green
Write-Host "👉 Để chạy Backend: Chạy lệnh .\run_backend.ps1 hoặc mở thư mục StayHub_backend trong IDE" -ForegroundColor White
Write-Host "👉 Để chạy Frontend: Chạy lệnh .\run_frontend.ps1 hoặc 'cd StayHub_frontend; flutter run'" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan
