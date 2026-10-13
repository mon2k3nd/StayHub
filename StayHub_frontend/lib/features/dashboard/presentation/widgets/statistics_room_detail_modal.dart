import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/dashboard_refresh.dart';
import '../../../room/application/room_notifier.dart';
import '../../../room/data/models/room_model.dart';
import 'dart:async' show unawaited;

void showRoomDetailModal(BuildContext context, RoomModel room, WidgetRef ref) {
  final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final isRented = room.status == 'DA_THUE';
  final isNghiemThu = room.status == 'NGHIEM_THU';
  final isTrong = room.status == 'TRONG';
  final isChoduyet = room.status == 'CHO_DUYET';
  final isBaoTri = room.status == 'BAO_TRI';
  final isChoKichHoat = room.status == 'CHO_KICH_HOAT';

  Color statusColor = AppTheme.kTextMuted;
  String statusLabel = room.status;
  IconData statusIcon = CupertinoIcons.house_fill;
  if (isRented) {
    statusColor = CupertinoColors.systemBlue;
    statusLabel = 'Đang thuê';
    statusIcon = CupertinoIcons.person_fill;
  } else if (isTrong) {
    statusColor = CupertinoColors.systemGreen;
    statusLabel = 'Trống';
    statusIcon = CupertinoIcons.house_fill;
  } else if (isNghiemThu) {
    statusColor = CupertinoColors.systemOrange;
    statusLabel = 'Nghiệm thu';
    statusIcon = CupertinoIcons.checkmark_seal_fill;
  } else if (isChoduyet) {
    statusColor = CupertinoColors.systemPurple;
    statusLabel = 'Chờ duyệt';
    statusIcon = CupertinoIcons.timer;
  } else if (isBaoTri) {
    statusColor = CupertinoColors.systemRed;
    statusLabel = 'Bảo trì';
    statusIcon = CupertinoIcons.wrench_fill;
  } else if (isChoKichHoat) {
    statusColor = AppTheme.kWarning;
    statusLabel = 'Chờ kích hoạt';
    statusIcon = CupertinoIcons.doc_checkmark_fill;
  }

  unawaited(
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.kBorderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header: room name + status
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phòng ${room.roomName}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Info grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _infoTile(
                        CupertinoIcons.money_dollar_circle_fill,
                        'Tiền thuê',
                        room.price != null
                            ? '${currencyFmt.format(room.price)}/th'
                            : 'Chưa có',
                        imagePath: 'assets/images/features/feat_payments.png',
                        CupertinoColors.systemGreen,
                      ),
                      const SizedBox(width: 12),
                      _infoTile(
                        CupertinoIcons.shield_fill,
                        'Tiền cọc',
                        room.deposit != null
                            ? currencyFmt.format(room.deposit)
                            : 'Không',
                        imagePath: 'assets/images/features/smart_contract.png',
                        CupertinoColors.systemOrange,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _infoTile(
                        CupertinoIcons.person_2_fill,
                        'Sức chứa',
                        room.maxGuests != null
                            ? 'Tối đa ${room.maxGuests} người'
                            : 'Không giới hạn',
                        imagePath: 'assets/images/features/ai_roommate.png',
                        CupertinoColors.systemBlue,
                      ),
                      const SizedBox(width: 12),
                      _infoTile(
                        CupertinoIcons.bolt_fill,
                        'Điện/Nước',
                        '${room.electricityPrice != null ? '${room.electricityPrice!.toStringAsFixed(0)}đ/kWh' : '--'} · ${room.waterPrice != null ? '${room.waterPrice!.toStringAsFixed(0)}đ/m³' : '--'}',
                        imagePath:
                            'assets/images/features/utilities_dashboard.png',
                        CupertinoColors.systemYellow,
                      ),
                    ],
                  ),
                ),

                if (room.description != null &&
                    room.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.kTextPrimaryDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.kBorderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mô tả',
                            style: TextStyle(
                              color: AppTheme.kTextSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            room.description!,
                            style: const TextStyle(
                              color: CupertinoColors.black,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ── SECTION: Quản lý phòng ──
                _sectionHeader('🏠 QUẢN LÝ PHÒNG'),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _actionButton(
                        icon: CupertinoIcons.settings_solid,
                        label: 'Chỉnh sửa thông tin phòng',
                        color: AppTheme.kAccentColor,
                        imagePath: 'assets/images/features/feat_settings.png',
                        onTap: () {
                          Navigator.pop(ctx);
                          unawaited(
                            context.push(
                              '/room-detail',
                              extra: {'roomId': room.id},
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _actionButton(
                        icon: CupertinoIcons.qrcode,
                        label: 'Mã QR phòng',
                        color: CupertinoColors.systemTeal,
                        imagePath:
                            'assets/images/features/guest_access_code.png',
                        onTap: () {
                          Navigator.pop(ctx);
                          unawaited(
                            context.push(
                              '/room-qr',
                              extra: {
                                'roomId': room.id,
                                'roomName': room.roomName,
                                'branchId': room.branchId ?? 0,
                                'branchName': '',
                                'price': room.price ?? 0.0,
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ── Đổi trạng thái nhanh ──
                const SizedBox(height: 16),
                _sectionHeader('🔄 ĐỔI TRẠNG THÁI NHANH'),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (!isTrong)
                        _statusChip(
                          'Trống',
                          'TRONG',
                          CupertinoColors.systemGreen,
                          ctx,
                          room,
                          ref,
                        ),
                      if (!isBaoTri)
                        _statusChip(
                          'Bảo trì',
                          'BAO_TRI',
                          CupertinoColors.systemRed,
                          ctx,
                          room,
                          ref,
                        ),
                      if (!room.isDongCua)
                        _statusChip(
                          'Đóng cửa',
                          'DONG_CUA',
                          AppTheme.kTextSecondary,
                          ctx,
                          room,
                          ref,
                        ),
                      if (isNghiemThu || isChoduyet)
                        _statusChip(
                          'Huỷ & Xóa trạng thái',
                          'TRONG',
                          CupertinoColors.systemRed,
                          ctx,
                          room,
                          ref,
                        ),
                    ],
                  ),
                ),

                // ── SECTION: Hợp đồng & Tài chính ──
                const SizedBox(height: 20),
                _sectionHeader('📄 HỢP ĐỒNG & TÀI CHÍNH'),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      if (isRented && room.currentContractId != null) ...[
                        _actionButton(
                          icon: CupertinoIcons.doc_text_fill,
                          label: 'Xem hợp đồng hiện tại',
                          color: CupertinoColors.systemIndigo,
                          imagePath:
                              'assets/images/features/smart_contract.png',
                          onTap: () {
                            Navigator.pop(ctx);
                            unawaited(
                              context.push(
                                '/contract-preview',
                                extra: {'contractId': room.currentContractId},
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _actionButton(
                          icon: CupertinoIcons.person_2_fill,
                          label: 'Xem danh sách người ở cùng',
                          color: CupertinoColors.systemPurple,
                          imagePath: 'assets/images/features/ai_roommate.png',
                          onTap: () {
                            Navigator.pop(ctx);
                            unawaited(
                              context.push(
                                '/roommates',
                                extra: {
                                  'contractId': room.currentContractId!,
                                  'roomId': room.id,
                                  'roomName': room.roomName,
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                      _actionButton(
                        icon: CupertinoIcons.doc_plaintext,
                        label: 'Tất cả hợp đồng',
                        color: CupertinoColors.systemBlue,
                        imagePath: 'assets/images/features/auto_pdf_gen.png',
                        onTap: () {
                          Navigator.pop(ctx);
                          unawaited(context.push('/contract'));
                        },
                      ),
                      const SizedBox(height: 8),

                      if (isTrong)
                        _actionButton(
                          icon: CupertinoIcons.add_circled_solid,
                          label: 'Tạo hợp đồng mới',
                          color: CupertinoColors.systemGreen,
                          imagePath: 'assets/images/features/lease_renewal.png',
                          onTap: () {
                            Navigator.pop(ctx);
                            unawaited(context.push('/rental-requests'));
                          },
                        ),

                      _actionButton(
                        icon: CupertinoIcons.money_dollar_circle_fill,
                        label: 'Quản lý hoá đơn',
                        color: CupertinoColors.systemGreen,
                        imagePath: 'assets/images/features/feat_payments.png',
                        onTap: () {
                          Navigator.pop(ctx);
                          unawaited(context.push('/bill'));
                        },
                      ),
                    ],
                  ),
                ),

                // ── SECTION: Tiện ích & Chăm sóc ──
                const SizedBox(height: 20),
                _sectionHeader('🛠️ TIỆN ÍCH & VẬN HÀNH'),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _actionButton(
                        icon: CupertinoIcons.bolt_horizontal_fill,
                        label: 'Nhập chỉ số điện nước',
                        color: CupertinoColors.systemYellow,
                        imagePath: 'assets/images/features/ocr_meter.png',
                        onTap: () {
                          Navigator.pop(ctx);
                          unawaited(context.push('/meter-reading/${room.id}'));
                        },
                      ),
                      const SizedBox(height: 8),
                      _actionButton(
                        icon: CupertinoIcons.ticket_fill,
                        label: 'Sự cố & Bảo trì',
                        color: CupertinoColors.systemOrange,
                        imagePath:
                            'assets/images/features/video_maintenance.png',
                        onTap: () {
                          Navigator.pop(ctx);
                          unawaited(context.push('/ticket'));
                        },
                      ),
                      if (isRented) ...[
                        const SizedBox(height: 8),
                        _actionButton(
                          icon: CupertinoIcons.square_arrow_right_fill,
                          label: 'Danh sách trả phòng',
                          color: CupertinoColors.systemRed,
                          imagePath:
                              'assets/images/features/moveout_settlement.png',
                          onTap: () {
                            Navigator.pop(ctx);
                            unawaited(context.push('/owner/checkout-list'));
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                // Close
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    color: AppTheme.kBackgroundLightGray,
                    borderRadius: BorderRadius.circular(16),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Center(
                      child: Text(
                        'Đóng',
                        style: TextStyle(
                          color: AppTheme.kBorderColorDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _infoTile(
  IconData icon,
  String label,
  String value,
  Color color, {
  String? imagePath,
}) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          imagePath == null
              ? Icon(icon, color: color, size: 18)
              : Image.asset(
                  imagePath,
                  width: 26,
                  height: 26,
                  filterQuality: FilterQuality.high,
                ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.kTextMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: CupertinoColors.black,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

Widget _actionButton({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
  String? imagePath,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: imagePath == null
                ? Icon(icon, color: color, size: 18)
                : Image.asset(
                    imagePath,
                    width: 26,
                    height: 26,
                    filterQuality: FilterQuality.high,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            CupertinoIcons.chevron_right,
            color: color.withValues(alpha: 0.5),
            size: 16,
          ),
        ],
      ),
    ),
  );
}

Widget _sectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Text(
      title,
      style: const TextStyle(
        color: AppTheme.kTextSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
      ),
    ),
  );
}

Widget _statusChip(
  String label,
  String statusValue,
  Color color,
  BuildContext ctx,
  RoomModel room,
  WidgetRef ref,
) {
  return GestureDetector(
    onTap: () async {
      Navigator.pop(ctx);
      final notifier = ref.read(roomProvider.notifier);

      // Cần truyền đủ data của phòng vì Backend dùng PUT (overwrite)
      final fullData = room.toJson();
      fullData['status'] = statusValue;
      // Bỏ các key null để tránh lỗi parser không cần thiết nếu có
      fullData.removeWhere((key, value) => value == null);

      await notifier.updateRoom(room.id, fullData);
      refreshOwnerDashboardFromWidget(ref);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
