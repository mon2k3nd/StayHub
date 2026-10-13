import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/core_providers.dart';
import 'api_client.dart';
import 'api_interceptors.dart';

final dioProvider = FutureProvider<Dio>((ref) async {
  final secureStorage = ref.watch(secureStorageServiceProvider);

  final dio = Dio(
    BaseOptions(
      // Dùng chung nguồn base URL với ApiClient (trước đây hardcode tunnel URL đã chết).
      baseUrl: '${ApiClient.baseUrl}/v1',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
      responseType: ResponseType.json,
      headers: {'ngrok-skip-browser-warning': 'true'},
    ),
  );

  // Thêm interceptors
  dio.interceptors.add(LoggingInterceptor());
  dio.interceptors.add(AuthInterceptor(secureStorage, dio));

  // Cấu hình Caching (Offline Mode)
  try {
    final dir = await getTemporaryDirectory();
    final cacheStore = HiveCacheStore(
      dir.path,
      hiveBoxName: "stayhub_api_cache",
    );

    final cacheOptions = CacheOptions(
      store: cacheStore,
      policy: CachePolicy.request,
      hitCacheOnErrorExcept: [
        401,
        403,
      ], // Lấy từ cache nếu lỗi mạng (trừ lỗi xác thực)
      maxStale: const Duration(days: 7),
      priority: CachePriority.normal,
      cipher: null,
      keyBuilder: CacheOptions.defaultCacheKeyBuilder,
      allowPostMethod: false,
    );

    dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));
  } catch (e) {
    // Ignore cache setup errors gracefully
  }

  return dio;
});
