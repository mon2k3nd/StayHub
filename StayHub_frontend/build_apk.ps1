# ============================================================
# StayHub - Build APK Script (PowerShell)
# Run this script to build the Release APK.
#
# IMPORTANT: A release APK does NOT know where the backend is. If you do not
# pass `--dart-define=API_BASE_URL`, the app falls back to `http://10.0.2.2:8080`
# (an address that only exists on the Android Emulator) -> on a real phone the
# app cannot reach the backend and shows wrong/empty data.
#
# There are 2 ways to let the phone reach the backend:
#
#   (A) VIA TUNNEL (RECOMMENDED - works on any network, including 4G):
#       Open another terminal and run:
#         cloudflared.exe tunnel --url http://localhost:8080 --no-autoupdate
#       Copy the printed URL `https://xxxx.trycloudflare.com`, then build:
#         .\build_apk.ps1 -ApiBaseUrl "https://xxxx.trycloudflare.com"
#
#   (B) VIA LAN (only when the phone and the PC are on the SAME WiFi/LAN):
#       Run without arguments; the script auto-detects the LAN IP:
#         .\build_apk.ps1
#       NOTE: if the PC is on Ethernet while the phone is on a different WiFi
#       router, or the router enables AP/client isolation -> this will NOT work.
# ============================================================

param(
    # Allow manual override, e.g.:
    #   .\build_apk.ps1 -ApiBaseUrl "https://xxxx.trycloudflare.com"
    #   .\build_apk.ps1 -ApiBaseUrl "https://api.stayhub.vn"
    [string]$ApiBaseUrl = ""
)

Write-Host "`n[StayHub] Starting Release APK build..." -ForegroundColor Cyan

# 0. Resolve the API base URL
if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    Write-Host "`n[0/4] Detecting this machine's LAN IP..." -ForegroundColor Yellow
    $lanIp = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object {
            $_.IPAddress -notlike '127.*' -and
            $_.IPAddress -notlike '169.254.*' -and
            $_.PrefixOrigin -ne 'WellKnown' -and
            $_.InterfaceAlias -notlike '*Tailscale*'
        } |
        Select-Object -First 1 -ExpandProperty IPAddress)

    if ([string]::IsNullOrWhiteSpace($lanIp)) {
        Write-Host "[ERROR] No LAN IP found. Pass it manually: .\build_apk.ps1 -ApiBaseUrl http://192.168.x.x:8080" -ForegroundColor Red
        exit 1
    }
    $ApiBaseUrl = "http://${lanIp}:8080"
    Write-Host "[WARN] Using LAN IP. If the phone cannot connect, use a tunnel (see header)." -ForegroundColor Yellow
}

Write-Host "API_BASE_URL = $ApiBaseUrl" -ForegroundColor Green

# 1. Clean build cache
Write-Host "`n[1/4] Cleaning old build cache..." -ForegroundColor Yellow
flutter clean

# 2. Get dependencies
Write-Host "`n[2/4] Fetching dependencies..." -ForegroundColor Yellow
flutter pub get

# 3. Run build_runner to regenerate code files
Write-Host "`n[3/4] Regenerating code (build_runner)..." -ForegroundColor Yellow
dart run build_runner build --delete-conflicting-outputs

# 4. Build APK (arm64-v8a only to reduce size).
#
# IMPORTANT: --split-per-abi
#   This is the ONLY reliable way to ship an arm64-only release APK. Neither
#   `ndk { abiFilters }` in build.gradle.kts (the Flutter Gradle plugin injects
#   its own abiFilters for every ABI *after* the build-type block is evaluated,
#   overriding it) nor `--target-platform android-arm64` (only controls the Dart
#   AOT snapshot, not the native plugin .so files) removes the other ABIs.
#   `--split-per-abi` makes Gradle emit one APK per ABI; we then ship the
#   arm64-v8a one (~78 MB) and ignore the armeabi-v7a / x86_64 ones.
#   Debug builds (`flutter run`) are unaffected and keep ALL ABIs, so the app
#   still runs on x86_64 Android emulators.
#
# No --obfuscate: keeping class/string names makes it possible to verify the
# backend URL was embedded correctly and to read logs/crashes when supporting users.
#
# IMPORTANT: --no-tree-shake-icons
#   The app references icons dynamically (IconData passed as variables/params,
#   e.g. `Icon(icon, ...)`), so Flutter's icon tree-shaker cannot detect them and
#   strips almost the entire MaterialIcons/CupertinoIcons font -> ALL icons render
#   as empty boxes on the device. Disabling tree-shaking keeps the full icon fonts.
Write-Host "`n[4/4] Building Release APK (split per ABI)..." -ForegroundColor Yellow
flutter build apk --release --split-per-abi --no-tree-shake-icons --dart-define=API_BASE_URL=$ApiBaseUrl

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[OK] Build succeeded!" -ForegroundColor Green
    # --split-per-abi emits app-<abi>-release.apk; ship the arm64-v8a one.
    $apkPath = "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
    if (Test-Path $apkPath) {
        $apkSize = [math]::Round((Get-Item $apkPath).length / 1MB, 2)
        Write-Host "APK: $apkPath ($apkSize MB)" -ForegroundColor Green

        # Verify the backend URL is embedded in the AOT snapshot.
        try {
            $tmp = Join-Path $env:TEMP ("apkverify_" + [guid]::NewGuid().ToString("N"))
            New-Item -ItemType Directory -Path $tmp | Out-Null
            Copy-Item $apkPath (Join-Path $tmp "a.zip")
            Expand-Archive -Path (Join-Path $tmp "a.zip") -DestinationPath $tmp -Force
            $so = Join-Path $tmp "lib\arm64-v8a\libapp.so"
            if (Test-Path $so) {
                $text = [System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes($so))
                $host_ = ([uri]$ApiBaseUrl).Host
                if ($text.Contains($host_)) {
                    Write-Host "[OK] Verified: backend host '$host_' is embedded in the APK." -ForegroundColor Green
                }
                else {
                    Write-Host "[WARN] Could not find '$host_' in libapp.so. The APK may fall back to the emulator address." -ForegroundColor Yellow
                }
            }
            Remove-Item -Recurse -Force $tmp
        }
        catch {
            Write-Host "[WARN] Could not verify embedded URL: $($_.Exception.Message)" -ForegroundColor Yellow
        }

        # Open output folder
        Start-Process explorer.exe -ArgumentList "build\app\outputs\flutter-apk"
    }
}
else {
    Write-Host "`n[ERROR] Build failed. Check the errors above." -ForegroundColor Red
    exit 1
}
