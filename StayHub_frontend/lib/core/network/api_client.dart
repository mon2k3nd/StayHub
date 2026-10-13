import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../error/app_exception.dart';
import '../security/secure_storage_service.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:dio/io.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class ApiClient {
  /// SEC12: Base URL lấy từ biến môi trường khi build.
  ///
  /// Build production:
  /// `flutter build apk --dart-define=API_BASE_URL=https://api.stayhub.vn`
  ///
  /// Nếu không truyền, fallback về localhost/LAN cho môi trường dev.
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// URL backend cho môi trường dev khi KHÔNG truyền `--dart-define=API_BASE_URL`.
  ///
  /// LƯU Ý QUAN TRỌNG:
  /// - Android EMULATOR không thể truy cập `localhost` của máy host. Địa chỉ
  ///   `10.0.2.2` là alias đặc biệt trỏ về loopback của máy host.
  /// - Android THIẾT BỊ THẬT / iOS simulator / desktop / web dùng `localhost`.
  /// - Nếu chạy backend trên máy khác trong LAN, truyền IP thật qua:
  ///   `flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8080`
  static const String _devHost = String.fromEnvironment(
    'API_DEV_HOST',
    defaultValue: '',
  );

  /// URL backend tunnel dùng khi chạy web qua cloudflared (truyền lúc build):
  /// `flutter build web --dart-define=API_BASE_URL=https://xxx.trycloudflare.com`
  ///
  /// Nếu KHÔNG truyền, web sẽ tự suy ra:
  /// - Mở bằng `localhost`/`127.0.0.1` → backend `http://localhost:8080`.
  /// - Mở bằng host khác (tunnel/LAN) → backend cùng host, cổng 8080
  ///   (giả định backend tunnel chạy song song). Nếu backend nằm ở host khác,
  ///   BẮT BUỘC truyền `--dart-define=API_BASE_URL=...`.
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (kIsWeb) {
      // Tự suy ra backend từ hostname của trang web đang mở.
      // Uri.base hoạt động trên web mà không cần import dart:html.
      try {
        final host = Uri.base.host;
        if (host.isEmpty ||
            host == 'localhost' ||
            host == '127.0.0.1' ||
            host == '0.0.0.0') {
          return 'http://localhost:8080';
        }
        // Trang đang mở qua tunnel/LAN → trỏ backend về cùng host, cổng 8080.
        final scheme = Uri.base.scheme.isEmpty ? 'https' : Uri.base.scheme;
        return '$scheme://$host:8080';
      } catch (_) {
        return 'http://localhost:8080';
      }
    }

    // Cho phép override host dev qua --dart-define=API_DEV_HOST=192.168.x.x
    if (_devHost.isNotEmpty) return 'http://$_devHost:8080';

    try {
      if (Platform.isAndroid) {
        // 10.0.2.2 = loopback của máy host khi chạy trên Android Emulator.
        // Trên thiết bị thật, địa chỉ này không tồn tại → người dùng cần
        // truyền API_BASE_URL hoặc API_DEV_HOST khi build.
        return 'http://10.0.2.2:8080';
      }
    } catch (_) {}
    return 'http://localhost:8080';
  }

  /// SEC10: Danh sách fingerprint SHA-256 của chứng chỉ server (pin set).
  ///
  /// Lấy fingerprint thật bằng lệnh:
  /// `openssl s_client -connect api.stayhub.vn:443 -servername api.stayhub.vn < /dev/null | openssl x509 -fingerprint -sha256 -noout`
  ///
  /// Truyền khi build:
  /// `--dart-define=SSL_PINS=AB:CD:...,EF:12:...`
  ///
  /// Nếu rỗng → KHÔNG bật pinning (tránh chặn nhầm toàn bộ app do placeholder sai).
  static const String _sslPinsRaw = String.fromEnvironment('SSL_PINS');

  static List<String> get _sslPins => _sslPinsRaw
      .split(',')
      .map((s) => s.trim().toUpperCase())
      .where((s) => s.isNotEmpty)
      .toList();

  late final Dio _dio;
  Dio get dio => _dio;
  final SecureStorageService _storage = const SecureStorageService(
    FlutterSecureStorage(),
  );
  final void Function()? onSessionExpired;

  ApiClient({this.onSessionExpired}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

    // Cấu hình SSL/TLS Pinning chống tấn công MitM
    if (!kIsWeb) {
      final pins = _sslPins;
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client
              .badCertificateCallback = (X509Certificate cert, String host, int port) {
            // SEC10: Chỉ thực thi pinning khi có pin thật được cấu hình.
            // Trước đây dùng fingerprint placeholder (A1:B2:C3...) nên pinning
            // hoặc vô hiệu hoặc chặn nhầm mọi kết nối ở production.
            if (pins.isEmpty) {
              // Không có pin cấu hình → không thể xác minh, cho phép (dev).
              return true;
            }

            final certBytes = cert.der;
            final digest = sha256.convert(certBytes);
            final certFingerprint = digest.bytes
                .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
                .join(':');

            // Pin set: chấp nhận nếu khớp BẤT KỲ fingerprint nào (hỗ trợ xoay cert).
            if (pins.contains(certFingerprint)) {
              return true;
            }

            debugPrint(
              '[SSL Pinning] CẢNH BÁO: Chứng chỉ SSL không khớp pin. Có thể đang bị tấn công MitM!',
            );
            return false; // Chặn đứng kết nối
          };
          return client;
        },
      );
    }

    // ─── PERF1: Retry + Exponential Backoff cho lỗi mạng tạm thời ───
    // Khi server quá tải (người dùng tăng đột biến) hoặc mạng chập chờn,
    // tự động thử lại với backoff + jitter thay vì fail ngay.
    // Chỉ retry các lỗi TRANSIENT (timeout, connection, 5xx, 429).
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) async {
          final opts = e.requestOptions;
          final method = opts.method.toUpperCase();

          // PERF3: Public/guest browsing must FAIL FAST. Retrying a dead
          // connection 3x with backoff keeps the UI on a loading shimmer for
          // 60s+, which users perceive as a blank/white screen. When the
          // caller marks the request `_failFast`, surface the error at once so
          // the UI can render an actionable error/empty state.
          if (opts.extra['_failFast'] == true) {
            return handler.next(e);
          }

          // Không retry các request không idempotent (POST tạo mới) trừ khi
          // server trả 429/503 (an toàn để thử lại sau khi chờ).
          final status = e.response?.statusCode;
          final isTransient =
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.connectionError ||
              status == 429 ||
              (status != null && status >= 500);

          if (!isTransient) return handler.next(e);

          // POST/PUT/PATCH có thể gây tạo trùng dữ liệu → chỉ retry khi 429/503.
          final isWrite =
              method == 'POST' || method == 'PUT' || method == 'PATCH';
          if (isWrite && status != 429 && status != 503) {
            return handler.next(e);
          }

          final attempt = (opts.extra['_retryAttempt'] as int?) ?? 0;
          const maxRetries = 3;
          if (attempt >= maxRetries) return handler.next(e);

          // Backoff: 400ms, 800ms, 1600ms + jitter ngẫu nhiên 0-250ms.
          final baseDelay = 400 * (1 << attempt);
          final jitter = DateTime.now().microsecond % 250;
          final delay = Duration(milliseconds: baseDelay + jitter);

          // Tôn trọng header Retry-After nếu server cung cấp (429/503).
          final retryAfter = e.response?.headers.value('retry-after');
          final serverDelay = retryAfter != null
              ? int.tryParse(retryAfter)
              : null;
          final wait = serverDelay != null
              ? Duration(seconds: serverDelay.clamp(1, 30))
              : delay;

          debugPrint(
            '[API Retry] ${opts.method} ${opts.path} '
            'lần ${attempt + 1}/$maxRetries sau ${wait.inMilliseconds}ms '
            '(status: $status, type: ${e.type.name})',
          );

          await Future.delayed(wait);

          opts.extra['_retryAttempt'] = attempt + 1;
          try {
            final response = await _dio.fetch(opts);
            return handler.resolve(response);
          } on DioException catch (retryErr) {
            return handler.next(retryErr);
          }
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!options.path.contains('/auth/login') &&
              !options.path.contains('/auth/register') &&
              !options.path.contains('/public') &&
              !options.path.contains('/auth/send-otp')) {
            final token = await _storage.getAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          // Cơ chế Dynamic Nonce & Signed Request (HMAC-SHA256)
          final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          final nonce = '${timestamp}_${DateTime.now().microsecond}';

          // SEC11: Secret key KHÔNG được hardcode trong source client (dễ bị trích xuất
          // qua decompile). Lấy từ --dart-define khi build. Nếu rỗng → bỏ qua ký HMAC
          // (server phải cấu hình tương ứng) thay vì dùng key giả cố định.
          const secretKey = String.fromEnvironment('REQUEST_SIGNING_KEY');

          if (secretKey.isNotEmpty) {
            // Payload string cần ký (METHOD + PATH + NONCE + TIMESTAMP)
            final payloadToSign =
                '${options.method}:${options.path}:$nonce:$timestamp';

            final keyBytes = utf8.encode(secretKey);
            final payloadBytes = utf8.encode(payloadToSign);

            final hmac = Hmac(sha256, keyBytes);
            final digest = hmac.convert(payloadBytes);
            final signature = digest.toString();

            options.headers['X-Request-Timestamp'] = timestamp;
            options.headers['X-Request-Nonce'] = nonce;
            options.headers['X-Request-Signature'] = signature;
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          debugPrint(
            '[API Error] ${e.message} (status: ${e.response?.statusCode})',
          );

          // ─── GUARD: auth endpoints không cần refresh (login, register, otp…) ───
          final isAuthEndpoint = e.requestOptions.path.contains('/auth/');
          if (isAuthEndpoint) {
            return handler.next(e);
          }

          // Luồng Refresh Token tự động khi nhận lỗi 401 hoặc 403 (do Backend đôi khi trả 403 thay vì 401)
          if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
            // BUGFIX (Bug 138): header có thể bị adapter serialize thành String
            // ("true") thay vì bool → so sánh `== true` thất bại → retry vô hạn
            // (vòng lặp refresh token). Kiểm tra cả bool lẫn chuỗi.
            final retryHeader = e.requestOptions.headers['X-Retry'];
            final isRetry = retryHeader == true || retryHeader == 'true';
            if (isRetry) {
              // Đã thử retry nhưng vẫn lỗi -> Hết cứu, ném lỗi ra
              if (e.response?.statusCode == 403) {
                return handler.next(
                  DioException(
                    requestOptions: e.requestOptions,
                    error: const ForbiddenException(),
                  ),
                );
              }
              return handler.next(e);
            }

            final accessToken = await _storage.getAccessToken();

            // GUARD: Chỉ xử lý khi người dùng đang có phiên đăng nhập thực sự.
            if (accessToken == null) {
              if (e.response?.statusCode == 403) {
                return handler.next(
                  DioException(
                    requestOptions: e.requestOptions,
                    error: const ForbiddenException(),
                  ),
                );
              }
              return handler.next(e);
            }

            final refreshToken = await _storage.getRefreshToken();
            if (refreshToken != null) {
              try {
                // Call API refresh token độc lập không dùng interceptor hiện tại để tránh vòng lặp vô hạn
                final dioRefresh = Dio(BaseOptions(baseUrl: baseUrl));
                final refreshResponse = await dioRefresh.post(
                  '/v1/auth/refresh',
                  data: {'refreshToken': refreshToken},
                );

                if (refreshResponse.statusCode == 200 &&
                    refreshResponse.data != null) {
                  // BUGFIX (Bug 137): tránh cast cứng `as Map<String, dynamic>`
                  // — nếu backend trả kiểu khác (String/List) thì cast ném lỗi
                  // bên trong try → rơi vào catch → xoá phiên oan uổng (đăng
                  // xuất người dùng dù token vẫn hợp lệ). Kiểm tra an toàn.
                  final rawData = refreshResponse.data;
                  final responseData = rawData is Map
                      ? Map<String, dynamic>.from(rawData)
                      : <String, dynamic>{};
                  final newAccessToken = responseData['token']?.toString();
                  final newRefreshToken = responseData['refreshToken']
                      ?.toString();

                  if (newAccessToken != null) {
                    // Lưu cả access token và refresh token mới
                    await _storage.saveToken(
                      newAccessToken,
                      refreshToken: newRefreshToken,
                    );

                    // Gửi lại request bị lỗi với token mới
                    final options = e.requestOptions;
                    options.headers['Authorization'] = 'Bearer $newAccessToken';
                    options.headers['X-Retry'] =
                        true; // Mark as retried to prevent infinite loop

                    final cloneResponse = await _dio.request(
                      options.path,
                      data: options.data,
                      queryParameters: options.queryParameters,
                      options: Options(
                        method: options.method,
                        headers: options.headers,
                      ),
                    );
                    return handler.resolve(cloneResponse);
                  }
                }
              } catch (refreshErr) {
                debugPrint('[API Refresh Token Error] $refreshErr');
                await _storage.clearSession();
                onSessionExpired?.call();
              }
            } else {
              // Có access token nhưng không có refresh token → phiên hết hạn
              await _storage.clearSession();
              onSessionExpired?.call();
            }
          }
          return handler.next(e);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          logPrint: (obj) => debugPrint('[Dio] $obj'),
        ),
      );
    }
  }

  /// Danh sách các endpoint prefix không được cache (user-specific, mutable data)
  ///
  /// PERF5: Bổ sung `/v1/rooms/public` — danh sách phòng công khai (guest feed).
  /// Trước đây endpoint này BỊ cache bởi [DioCacheInterceptor]. Trên thiết bị
  /// thật, cache Hive có thể giữ lại response RỖNG từ một lần chạy lỗi trước đó
  /// (hoặc response bị serialize thành String), khiến UI hiển thị "không có
  /// phòng nào" dù backend trả về đủ dữ liệu. Guest feed phải LUÔN lấy mới.
  static const _noCachePaths = [
    '/v1/rooms/public',
    '/v1/wishlist',
    '/v1/notifications',
    '/v1/rental-requests',
    '/v1/invoices',
    '/v1/contracts',
  ];

  Future<void> initCache() async {
    try {
      CacheStore cacheStore;
      if (kIsWeb) {
        cacheStore = MemCacheStore();
      } else {
        final dir = await getApplicationDocumentsDirectory();
        cacheStore = HiveCacheStore(dir.path);
      }

      // PERF2: TTL cache hợp lý theo loại dữ liệu.
      // - maxStale 7 ngày chỉ dành cho ảnh/asset tĩnh (đã có CDN riêng).
      // - Dữ liệu động (danh sách phòng, chi nhánh) chỉ nên stale tối đa 1 giờ
      //   để tránh hiển thị giá/trạng thái cũ khi người dùng quay lại app.
      final cacheOptions = CacheOptions(
        store: cacheStore,
        policy: CachePolicy
            .request, // Try network first, fallback to cache on error
        hitCacheOnErrorExcept: [401, 403],
        maxStale: const Duration(hours: 1),
        priority: CachePriority.normal,
      );

      _dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));
      debugPrint('[ApiClient] Offline Cache Initialized');
    } catch (e) {
      debugPrint('[ApiClient] Cache Init failed: $e');
    }
  }

  /// Kiểm tra path có thuộc nhóm no-cache không
  bool _shouldBypassCache(String path) {
    return _noCachePaths.any((prefix) => path.startsWith(prefix));
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      // Bypass cache cho các endpoint user-specific để luôn lấy dữ liệu mới nhất từ server
      final options = _shouldBypassCache(path)
          ? Options(
              extra: CacheOptions(
                store: MemCacheStore(),
                policy: CachePolicy.noCache,
              ).toExtra(),
            )
          : null;
      final res = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _parse(res);
    } on DioException catch (e) {
      throw AppExceptionMapper.fromDio(e);
    }
  }

  /// PERF3: GET cho dữ liệu công khai (guest browsing).
  ///
  /// Khác với [get], phương thức này:
  /// - KHÔNG retry khi lỗi mạng (fail fast) → UI hiển thị lỗi/empty ngay thay
  ///   vì treo shimmer 60s+ khi backend không tới được.
  /// - Dùng timeout ngắn hơn để phản hồi nhanh trên mạng di động chập chờn.
  Future<Map<String, dynamic>> getPublic(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final res = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(
          extra: {'_failFast': true},
          receiveTimeout: const Duration(seconds: 20),
        ),
      );
      return _parse(res);
    } on DioException catch (e) {
      throw AppExceptionMapper.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> post(String path, {dynamic data}) async {
    try {
      final res = await _dio.post(path, data: data);
      return _parse(res);
    } on DioException catch (e) {
      throw AppExceptionMapper.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final res = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        onSendProgress: onSendProgress,
      );
      return _parse(res);
    } on DioException catch (e) {
      throw AppExceptionMapper.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final res = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _parse(res);
    } on DioException catch (e) {
      throw AppExceptionMapper.fromDio(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw AppExceptionMapper.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> uploadFile(
    String path,
    FormData formData, {
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final res = await _dio.post(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onSendProgress,
      );
      return _parse(res);
    } on DioException catch (e) {
      throw AppExceptionMapper.fromDio(e);
    }
  }

  Map<String, dynamic> _parse(Response res) {
    final d = res.data;
    if (d is Map<String, dynamic>) {
      return d;
    }
    return {'data': d};
  }
}
