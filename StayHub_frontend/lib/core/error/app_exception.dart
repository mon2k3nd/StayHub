import 'package:dio/dio.dart';

abstract class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException({String? message})
    : super(
        message ??
            'Lỗi kết nối mạng. Vui lòng kiểm tra lại Wi-Fi hoặc 3G/4G/5G.',
      );
}

class TimeoutException extends AppException {
  const TimeoutException({String? message})
    : super(message ?? 'Kết nối quá thời gian chờ. Vui lòng thử lại sau.');
}

class ServerException extends AppException {
  const ServerException({String? message, int? statusCode})
    : super(
        message ??
            'Máy chủ không phản hồi hoặc đang bảo trì. Vui lòng thử lại sau.',
        statusCode: statusCode,
      );
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({String? message})
    : super(
        message ?? 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        statusCode: 401,
      );
}

class ForbiddenException extends AppException {
  const ForbiddenException({String? message})
    : super(
        message ?? 'Bạn không có quyền truy cập tài nguyên này.',
        statusCode: 403,
      );
}

class NotFoundException extends AppException {
  const NotFoundException({String? message})
    : super(
        message ?? 'Tài nguyên yêu cầu không tồn tại trên hệ thống.',
        statusCode: 404,
      );
}

class BadRequestException extends AppException {
  const BadRequestException({String? message})
    : super(
        message ??
            'Yêu cầu không hợp lệ. Vui lòng kiểm tra lại thông tin gửi đi.',
        statusCode: 400,
      );
}

class UnknownException extends AppException {
  const UnknownException({String? message})
    : super(
        message ??
            'Đã xảy ra lỗi hệ thống không xác định. Vui lòng thử lại sau.',
      );
}

/// Exception đặc biệt cho trường hợp sai mật khẩu.
/// Backend trả về 401 kèm `name` và `avatar` để hiển thị màn hình cá nhân hoá.
class WrongPasswordException extends AppException {
  final String? userName;
  final String? userAvatar;

  WrongPasswordException({String? message, this.userName, this.userAvatar})
    : super(
        message ?? 'Mật khẩu không đúng. Vui lòng thử lại.',
        statusCode: 401,
      );
}

class AppExceptionMapper {
  static AppException fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        String? serverMessage;

        if (responseData is Map<String, dynamic>) {
          serverMessage =
              responseData['message']?.toString() ??
              responseData['error']?.toString();
        }

        switch (statusCode) {
          case 400:
            return BadRequestException(message: serverMessage);
          case 401:
            // Nếu backend trả về name/avatar kèm theo → sai mật khẩu (personalised)
            if (responseData is Map<String, dynamic>) {
              final name = responseData['name']?.toString();
              final avatar = responseData['avatar']?.toString();
              if (name != null && name.isNotEmpty) {
                return WrongPasswordException(
                  message:
                      serverMessage ?? 'Mật khẩu không đúng. Vui lòng thử lại.',
                  userName: name,
                  userAvatar: avatar?.isNotEmpty == true ? avatar : null,
                );
              }
            }
            return UnauthorizedException(message: serverMessage);
          case 403:
            return ForbiddenException(message: serverMessage);
          case 404:
            return NotFoundException(message: serverMessage);
          case 500:
          case 502:
          case 503:
          case 504:
            return ServerException(
              message: serverMessage,
              statusCode: statusCode,
            );
          default:
            return UnknownException(message: serverMessage);
        }
      case DioExceptionType.cancel:
        return const UnknownException(message: 'Yêu cầu mạng đã bị hủy bỏ.');
      default:
        return UnknownException(
          message: 'Lỗi hệ thống: ${e.type} - ${e.message} - ${e.error}',
        );
    }
  }

  static AppException fromGeneric(dynamic error) {
    if (error is AppException) return error;
    if (error is DioException) return fromDio(error);

    if (error is TypeError) {
      return const UnknownException(
        message:
            'Dữ liệu máy chủ không khớp định dạng mong muốn. Vui lòng thử lại.',
      );
    }
    if (error is FormatException) {
      return const UnknownException(
        message: 'Lỗi xử lý dữ liệu. Vui lòng thử lại.',
      );
    }
    if (error is NoSuchMethodError) {
      return const UnknownException(
        message: 'Đã xảy ra lỗi tương thích ứng dụng.',
      );
    }

    return UnknownException(
      message:
          'Đã xảy ra lỗi không mong muốn. Đội ngũ kỹ thuật đã được thông báo. \n(${error.toString()})',
    );
  }
}
