import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../security/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;
  final Dio _dio; // ignore: unused_field

  AuthInterceptor(this._secureStorage, this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Không thêm token cho các request auth
    if (options.path.contains('/auth/login') ||
        options.path.contains('/auth/register')) {
      return handler.next(options);
    }

    final token = await _secureStorage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Token expired, handle refresh token
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken != null) {
        try {
          // Xử lý refresh token ở đây (giả lập)
          // final response = await _dio.post('/auth/refresh', data: {'token': refreshToken});
          // await _secureStorage.saveToken(response.data['access_token']);

          // Sau khi có token mới, gửi lại request cũ
          // final opts = err.requestOptions;
          // opts.headers['Authorization'] = 'Bearer ${response.data['access_token']}';
          // final cloneReq = await _dio.fetch(opts);
          // return handler.resolve(cloneReq);
        } catch (e) {
          await _secureStorage.clearAll();
          // Điều hướng về màn hình Login
        }
      }
    }
    return handler.next(err);
  }
}

class LoggingInterceptor extends Interceptor {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.i(
      '=> ${options.method} ${options.uri}\nHeaders: ${options.headers}\nData: ${options.data}',
    );
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.i(
      '<= ${response.statusCode} ${response.requestOptions.uri}\nData: ${response.data}',
    );
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e(
      '!! ERROR ${err.response?.statusCode} ${err.requestOptions.uri}\nMessage: ${err.message}\nData: ${err.response?.data}',
    );
    return super.onError(err, handler);
  }
}
