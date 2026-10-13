import 'package:intl/intl.dart';

class TimeUtils {
  static String formatTimeAgo(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.isNegative || diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else {
      return '${diff.inDays} ngày trước';
    }
  }

  static String formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (now.day == time.day &&
        now.month == time.month &&
        now.year == time.year) {
      return DateFormat('HH:mm').format(time);
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE HH:mm', 'vi_VN').format(time);
    } else {
      return DateFormat('dd/MM HH:mm').format(time);
    }
  }

  static String calcDuration(String? startDateStr) {
    if (startDateStr == null) return 'N/A';
    try {
      final start = DateTime.parse(startDateStr);
      final diff = DateTime.now().difference(start);
      final months = (diff.inDays / 30).floor();
      final days = diff.inDays % 30;
      if (months > 0) return '$months tháng $days ngày';
      return '${diff.inDays} ngày';
    } catch (_) {
      return 'N/A';
    }
  }

  static String formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return 'N/A';
    }
  }
}
