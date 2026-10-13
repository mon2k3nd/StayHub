# Start Backend Spring Boot
$root = $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }
Set-Location (Join-Path $root "StayHub_backend\backend\stayhub-api")
Write-Host "☕ Đang khởi động StayHub Backend trên cổng 8080..." -ForegroundColor Cyan
./mvnw spring-boot:run
