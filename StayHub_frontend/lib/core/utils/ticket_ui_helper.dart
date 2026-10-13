import 'package:flutter/cupertino.dart';
import '../enums/ticket_status.dart';

class TicketUIHelper {
  static Color statusColor(String statusStr) {
    final status = TicketStatus.fromString(statusStr);
    switch (status) {
      case TicketStatus.newTicket:
        return CupertinoColors.systemRed;
      case TicketStatus.assigned:
      case TicketStatus.processing:
        return CupertinoColors.systemOrange;
      case TicketStatus.completed:
        return CupertinoColors.systemBlue;
      case TicketStatus.pendingOwnerReview:
        return CupertinoColors.systemBlue;
      case TicketStatus.closed:
        return CupertinoColors.systemGreen;
      case TicketStatus.cancelled:
        return CupertinoColors.systemGrey;
    }
  }

  static String statusText(String statusStr) {
    final status = TicketStatus.fromString(statusStr);
    switch (status) {
      case TicketStatus.newTicket:
        return 'Mới';
      case TicketStatus.assigned:
        return 'Đã phân công';
      case TicketStatus.processing:
        return 'Đang xử lý';
      case TicketStatus.completed:
        return 'Chờ nghiệm thu';
      case TicketStatus.pendingOwnerReview:
        return 'Chờ chủ nhà';
      case TicketStatus.closed:
        return 'Đã xong';
      case TicketStatus.cancelled:
        return 'Đã hủy';
    }
  }

  static IconData categoryIcon(String cat) {
    switch (cat) {
      case 'PLUMBING':
        return CupertinoIcons.drop_fill;
      case 'ELECTRICAL':
        return CupertinoIcons.bolt_fill;
      case 'APPLIANCE':
        return CupertinoIcons.tv_fill;
      case 'STRUCTURAL':
        return CupertinoIcons.building_2_fill;
      case 'PEST_CONTROL':
        return CupertinoIcons.ant_fill;
      case 'CLEANING':
        return CupertinoIcons.sparkles;
      default:
        return CupertinoIcons.wrench_fill;
    }
  }

  /// Returns a premium 3D icon asset for the given ticket category.
  static String categoryAsset(String cat) {
    switch (cat) {
      case 'PLUMBING':
        return 'assets/images/features/utilities_dashboard.png';
      case 'ELECTRICAL':
        return 'assets/images/features/ocr_meter.png';
      case 'APPLIANCE':
        return 'assets/images/features/iot_management.png';
      case 'STRUCTURAL':
        return 'assets/images/features/multi_property.png';
      case 'PEST_CONTROL':
        return 'assets/images/features/local_services.png';
      case 'CLEANING':
        return 'assets/images/features/local_services.png';
      default:
        return 'assets/images/features/video_maintenance.png';
    }
  }

  static String categoryLabel(String cat) {
    const m = {
      'PLUMBING': 'Ống nước',
      'ELECTRICAL': 'Điện',
      'APPLIANCE': 'Thiết bị',
      'STRUCTURAL': 'Kết cấu nhà',
      'PEST_CONTROL': 'Côn trùng',
      'CLEANING': 'Vệ sinh',
      'OTHER': 'Khác',
    };
    return m[cat] ?? cat;
  }
}
