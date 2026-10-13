# Start Frontend Flutter
$root = $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }
Set-Location (Join-Path $root "StayHub_frontend")
Write-Host "📱 Đang khởi động StayHub Frontend Flutter..." -ForegroundColor Cyan
flutter run -d chrome
