import 'package:dio/dio.dart';

class AppError {
  final String message;
  final int? code;

  AppError(this.message, {this.code});

  factory AppError.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppError("Kết nối quá thời gian chờ. Vui lòng thử lại!");
      case DioExceptionType.badResponse:
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          return AppError(data['message'].toString());
        }
        return AppError("Dữ liệu phản hồi từ máy chủ không hợp lệ.");
      case DioExceptionType.cancel:
        return AppError("Yêu cầu đã bị hủy.");
      case DioExceptionType.connectionError:
        return AppError("Không thể kết nối máy chủ. Vui lòng kiểm tra mạng!");
      default:
        return AppError("Đã xảy ra lỗi hệ thống, vui lòng thử lại sau.");
    }
  }

  factory AppError.generic() => AppError("Đã xảy ra lỗi, vui lòng thử lại.");
}
