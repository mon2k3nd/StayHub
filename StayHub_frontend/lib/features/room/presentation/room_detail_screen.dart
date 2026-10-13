import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter/material.dart'
    show
        Divider,
        Colors,
        showModalBottomSheet,
        BorderRadius,
        Radius,
        EdgeInsets;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/components/audit_logs_sheet.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../application/room_notifier.dart';
import '../data/models/room_model.dart';
import 'widgets/bulk_clone_room_bottom_sheet.dart';
import 'dart:async' show unawaited;

final _currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

class RoomDetailScreen extends ConsumerStatefulWidget {
  final int roomId;

  const RoomDetailScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  // Bug fix: không dùng _room local state nữa, watch trực tiếp từ provider
  // để đảm bảo UI update realtime khi provider thay đổi.
  bool _isDeleting = false;

  void _confirmDelete() {
    unawaited(HapticFeedback.mediumImpact());
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Xóa Phòng Trọ?'),
          content: const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Bạn có chắc chắn muốn xóa phòng trọ này? Thao tác này không thể hoàn tác.',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Xóa'),
              onPressed: () async {
                Navigator.pop(ctx);
                if (!mounted) return;
                setState(() => _isDeleting = true);
                try {
                  await ref
                      .read(roomProvider.notifier)
                      .deleteRoom(widget.roomId);
                  if (mounted) context.pop();
                } catch (e) {
                  if (mounted) {
                    setState(() => _isDeleting = false);
                    unawaited(
                      showCupertinoDialog(
                        context: context,
                        builder: (_) => CupertinoAlertDialog(
                          title: const Text('Lỗi'),
                          content: Text('Không thể xóa phòng: $e'),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('Đóng'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider để auto-rebuild khi data thay đổi (fix stuck-loading bug)
    final roomsAsync = ref.watch(roomProvider);

    if (_isDeleting) {
      return const LiquidGlassScaffold(
        title: 'Chi Tiết Phòng',
        backgroundColors: AppTheme.kBackgroundLight,
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: 150),
            child: CupertinoActivityIndicator(radius: 16),
          ),
        ),
      );
    }

    return roomsAsync.when(
      loading: () => const LiquidGlassScaffold(
        title: 'Chi Tiết Phòng',
        backgroundColors: AppTheme.kBackgroundLight,
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: 150),
            child: CupertinoActivityIndicator(radius: 16),
          ),
        ),
      ),
      error: (err, _) => LiquidGlassScaffold(
        title: 'Chi Tiết Phòng',
        backgroundColors: AppTheme.kBackgroundLight,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 150),
            child: Text(
              err.toString(),
              style: const TextStyle(color: CupertinoColors.systemRed),
            ),
          ),
        ),
      ),
      data: (rooms) {
        RoomModel? r;
        try {
          r = rooms.firstWhere((e) => e.id == widget.roomId);
        } catch (_) {}
        if (r == null) {
          return const LiquidGlassScaffold(
            title: 'Chi Tiết Phòng',
            backgroundColors: AppTheme.kBackgroundLight,
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(top: 150),
                child: Text(
                  'Không tìm thấy thông tin phòng.',
                  style: TextStyle(color: CupertinoColors.systemRed),
                ),
              ),
            ),
          );
        }
        return _buildContent(r);
      },
    );
  }

  Widget _buildContent(RoomModel r) {
    final priceStr = r.price != null
        ? _currencyFmt.format(r.price)
        : 'Chưa thiết lập';
    final depositStr = r.deposit != null
        ? _currencyFmt.format(r.deposit)
        : 'Chưa thiết lập';

    return LiquidGlassScaffold(
      title: r.roomName,
      backgroundColors: AppTheme.kBackgroundLight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ trạng thái lớn
            _buildStatusHeaderCard(r),
            const SizedBox(height: 24),

            // Thông tin cơ bản
            const Text(
              'THÔNG TIN CƠ BẢN',
              style: TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailRow('Giá thuê', priceStr),
                  const Divider(
                    color: CupertinoColors.separator,
                    height: 24,
                    thickness: 0.5,
                  ),
                  _buildDetailRow('Tiền cọc', depositStr),
                  const Divider(
                    color: CupertinoColors.separator,
                    height: 24,
                    thickness: 0.5,
                  ),
                  _buildDetailRow(
                    'Số người tối đa',
                    r.maxGuests != null
                        ? '${r.maxGuests} người'
                        : 'Không giới hạn',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Chỉ số dịch vụ
            const Text(
              'BẢNG GIÁ DỊCH VỤ',
              style: TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailRow(
                    'Tiền điện',
                    r.electricityPrice != null
                        ? '${_currencyFmt.format(r.electricityPrice)} / kWh'
                        : 'Theo hóa đơn nhà nước',
                  ),
                  const Divider(
                    color: CupertinoColors.separator,
                    height: 24,
                    thickness: 0.5,
                  ),
                  _buildDetailRow(
                    'Tiền nước',
                    r.waterPrice != null
                        ? '${_currencyFmt.format(r.waterPrice)} / m³'
                        : 'Theo hóa đơn nhà nước',
                  ),
                  const Divider(
                    color: CupertinoColors.separator,
                    height: 24,
                    thickness: 0.5,
                  ),
                  _buildDetailRow(
                    'Phí dịch vụ khác',
                    r.serviceFee != null
                        ? '${_currencyFmt.format(r.serviceFee)} / tháng'
                        : 'Miễn phí',
                  ),
                ],
              ),
            ),
            // Thông số vật lý & Tiện nghi nội thất
            const Text(
              'THÔNG SỐ VẬT LÝ & TIỆN NGHI',
              style: TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            _buildPhysicalFeaturesGrid(r),
            const SizedBox(height: 12),
            _buildFurnitureTags(r),
            const SizedBox(height: 24),

            // Mô tả
            if (r.description != null && r.description!.isNotEmpty) ...[
              const Text(
                'MÔ TẢ CHI TIẾT',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Text(
                  r.description!,
                  style: const TextStyle(
                    color: CupertinoColors.black,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Các hành động
            const Text(
              'HÀNH ĐỘNG',
              style: TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                unawaited(HapticFeedback.mediumImpact());
                final allRooms = ref.read(roomProvider).value ?? [];
                unawaited(
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => BulkCloneRoomBottomSheet(
                      sourceRoom: r,
                      allRoomsInBranch: allRooms,
                    ),
                  ),
                );
              },
              child: const GlassContainer(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.square_on_square,
                      color: CupertinoColors.activeBlue,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Nhân bản cấu hình phòng này',
                      style: TextStyle(
                        color: CupertinoColors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    Icon(
                      CupertinoIcons.chevron_right,
                      color: Color(0xFF4B5563),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildActionButtons(r),
            const SizedBox(height: 100),
          ], // end of Column children
        ),
      ),
    );
  }

  Widget _buildStatusHeaderCard(RoomModel r) {
    Color statusColor;
    IconData icon;
    String statusAsset;
    switch (r.status) {
      case 'TRONG':
        statusColor = const Color(0xFF2ECC71);
        icon = CupertinoIcons.house_fill;
        statusAsset = 'assets/images/features/feat_room.png';
        break;
      case 'DA_THUE':
        statusColor = const Color(0xFF3498DB);
        icon = CupertinoIcons.person_fill;
        statusAsset = 'assets/images/features/ai_roommate.png';
        break;
      case 'BAO_TRI':
        statusColor = const Color(0xFFE67E22);
        icon = CupertinoIcons.wrench_fill;
        statusAsset = 'assets/images/features/video_maintenance.png';
        break;
      default:
        statusColor = const Color(0xFF95A5A6);
        icon = CupertinoIcons.lock_fill;
        statusAsset = 'assets/images/features/smart_locker.png';
    }

    return GlassContainer(
      color: statusColor.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Hero(
              tag: 'room_icon_${r.id}',
              child: Image.asset(
                statusAsset,
                width: 34,
                height: 34,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
                errorBuilder: (_, __, ___) =>
                    Icon(icon, color: statusColor, size: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  r.address ?? 'Chưa xác định địa chỉ',
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: CupertinoColors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(RoomModel r) {
    return Column(
      children: [
        // Bug fix: gộp 2 nút QR trùng thành 1, điều kiện rõ ràng hơn
        if (r.status == 'TRONG') ...[
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              unawaited(HapticFeedback.lightImpact());
              unawaited(
                context.push(
                  '/room-qr',
                  extra: {
                    'roomId': r.id,
                    'roomName': r.roomName,
                    'branchId': r.branchId ?? 0,
                    'branchName': r.address ?? '',
                    'price': r.price ?? 0.0,
                  },
                ),
              );
            },
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: const Color(0xFF298FFF).withValues(alpha: 0.07),
              child: const Row(
                children: [
                  Icon(
                    CupertinoIcons.qrcode_viewfinder,
                    color: Color(0xFF298FFF),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Tạo mã QR cho thuê phòng',
                    style: TextStyle(
                      color: Color(0xFF298FFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: Color(0xFF298FFF),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (r.status == 'CHO_KICH_HOAT') ...[
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              unawaited(HapticFeedback.lightImpact());
              unawaited(
                context.push(
                  '/offline-contract-verify',
                  extra: {'roomId': r.id, 'contractId': r.currentContractId},
                ),
              );
            },
            child: GlassContainer(
              color: AppTheme.kWarning.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: const Row(
                children: [
                  Icon(
                    CupertinoIcons.doc_checkmark_fill,
                    color: AppTheme.kWarning,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Kích hoạt Hợp đồng Offline',
                    style: TextStyle(
                      color: Color(0xFFD97706),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: Color(0xFFD97706),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 0),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            unawaited(HapticFeedback.lightImpact());
            unawaited(
              context.push(
                '/room-inventory',
                extra: {'roomId': r.id, 'roomName': r.roomName},
              ),
            );
          },
          child: const GlassContainer(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.cube_box_fill,
                  color: CupertinoColors.systemOrange,
                ),
                SizedBox(width: 12),
                Text(
                  'Kiểm kê tài sản',
                  style: TextStyle(
                    color: CupertinoColors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: Color(0xFF4B5563),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            unawaited(HapticFeedback.lightImpact());
            unawaited(
              context.push(
                '/room/${r.id}/members',
                extra: {'roomName': r.roomName},
              ),
            );
          },
          child: const GlassContainer(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.person_crop_circle_badge_plus,
                  color: Color(0xFF6366F1),
                ),
                SizedBox(width: 12),
                Text(
                  'Thành Viên Phòng',
                  style: TextStyle(
                    color: CupertinoColors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: Color(0xFF4B5563),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            unawaited(HapticFeedback.lightImpact());
            unawaited(
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) =>
                    AuditLogsSheet(entityType: 'ROOM', entityId: r.id),
              ),
            );
          },
          child: const GlassContainer(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(CupertinoIcons.doc_text_search, color: Color(0xFF10B981)),
                SizedBox(width: 12),
                Text(
                  'Truy vết thay đổi (Audit Log)',
                  style: TextStyle(
                    color: CupertinoColors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: Color(0xFF4B5563),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (r.currentContractId != null) ...[
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              unawaited(HapticFeedback.lightImpact());
              unawaited(
                context.push(
                  '/roommates',
                  extra: {
                    'contractId': r.currentContractId!,
                    'roomId': r.id,
                    'roomName': r.roomName,
                  },
                ),
              );
            },
            child: const GlassContainer(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.person_3_fill,
                    color: CupertinoColors.systemBlue,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Quản lý người ở cùng',
                    style: TextStyle(
                      color: CupertinoColors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: Color(0xFF4B5563),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (r.currentTenantId != null) ...[
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              unawaited(HapticFeedback.lightImpact());
              unawaited(
                context.push(
                  '/direct-message/${r.id}',
                  extra: {
                    'roomName': '💬 ${r.roomName}',
                    'otherPersonName': 'Khách thuê',
                  },
                ),
              );
            },
            child: const GlassContainer(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.chat_bubble_2_fill,
                    color: CupertinoColors.systemGreen,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Nhắn tin với khách thuê',
                    style: TextStyle(
                      color: CupertinoColors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: Color(0xFF4B5563),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Wire _showCheckinCodeModal – fix unused_element warning
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              unawaited(HapticFeedback.lightImpact());
              _showCheckinCodeModal(r);
            },
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: AppTheme.kBrand.withValues(alpha: 0.07),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.qrcode, color: AppTheme.kBrand),
                  SizedBox(width: 12),
                  Text(
                    'Mã QR nhận phòng',
                    style: TextStyle(
                      color: AppTheme.kBrand,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: AppTheme.kBrand,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _confirmDelete,
          child: const GlassContainer(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.trash_fill,
                  color: CupertinoColors.systemRed,
                ),
                SizedBox(width: 12),
                Text(
                  'Xóa phòng trọ này',
                  style: TextStyle(
                    color: CupertinoColors.systemRed,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: Color(0xFF4B5563),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCheckinCodeModal(RoomModel r) {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => Container(
          height: 500,
          decoration: const BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Mã Nhận Phòng',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Đưa mã này cho khách để họ quét và bắt đầu nghiệm thu phòng ${r.roomName}.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: 'stayhub://room/${r.id}',
                  version: QrVersions.auto,
                  size: 160.0,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: CupertinoColors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: CupertinoColors.black,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'STH-${r.id}',
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(width: 16),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        unawaited(HapticFeedback.selectionClick());
                        unawaited(
                          Clipboard.setData(ClipboardData(text: 'STH-${r.id}')),
                        );
                        Navigator.pop(ctx);
                      },
                      child: const Icon(
                        CupertinoIcons.doc_on_clipboard_fill,
                        color: AppTheme.kBrand,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Physical Features Grid UI ──────────────────────────────────
  Widget _buildPhysicalFeaturesGrid(RoomModel r) {
    // Helper to translate direction keys
    String getDirectionLabel(String? key) {
      const map = {
        'DONG': 'Hướng Đông',
        'TAY': 'Hướng Tây',
        'NAM': 'Hướng Nam',
        'BAC': 'Hướng Bắc',
        'DONG_NAM': 'Hướng Đông Nam',
        'DONG_BAC': 'Hướng Đông Bắc',
        'TAY_NAM': 'Hướng Tây Nam',
        'TAY_BAC': 'Hướng Tây Bắc',
      };
      return map[key] ?? 'Không xác định hướng';
    }

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildGridItem(
                  CupertinoIcons.square_split_2x2,
                  'Diện tích',
                  r.area != null ? '${r.area} m²' : 'Chưa nhập',
                  imagePath: 'assets/images/features/feat_room.png',
                ),
              ),
              Expanded(
                child: _buildGridItem(
                  CupertinoIcons.chevron_up_circle,
                  'Gác lửng',
                  r.mezzanineArea != null && r.mezzanineArea! > 0
                      ? '${r.mezzanineArea} m²'
                      : 'Không có',
                  imagePath: 'assets/images/features/multi_property.png',
                ),
              ),
            ],
          ),
          const Divider(
            color: CupertinoColors.separator,
            height: 24,
            thickness: 0.5,
          ),
          Row(
            children: [
              Expanded(
                child: _buildGridItem(
                  CupertinoIcons.wind,
                  'Vệ sinh',
                  r.bathroomType == 'RIENG' ? 'Khép kín' : 'Chung',
                  imagePath: 'assets/images/features/utilities_dashboard.png',
                ),
              ),
              Expanded(
                child: _buildGridItem(
                  CupertinoIcons.compass,
                  'Hướng phòng',
                  getDirectionLabel(r.direction),
                  imagePath: 'assets/images/features/feat_discover.png',
                ),
              ),
            ],
          ),
          const Divider(
            color: CupertinoColors.separator,
            height: 24,
            thickness: 0.5,
          ),
          Row(
            children: [
              Expanded(
                child: _buildGridItem(
                  CupertinoIcons.sun_max,
                  'Ban công',
                  r.hasBalcony == true ? 'Có ban công' : 'Không có',
                  imagePath: 'assets/images/features/feat_room.png',
                ),
              ),
              Expanded(
                child: _buildGridItem(
                  CupertinoIcons.sidebar_left,
                  'Cửa sổ',
                  r.hasWindow == true ? 'Có cửa sổ' : 'Không có',
                  imagePath: 'assets/images/features/feat_room.png',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(
    IconData icon,
    String title,
    String value, {
    String? imagePath,
  }) {
    return Row(
      children: [
        if (imagePath != null)
          Image.asset(
            imagePath,
            width: 24,
            height: 24,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
            errorBuilder: (_, __, ___) =>
                Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          )
        else
          Icon(icon, size: 20, color: const Color(0xFF6B7280)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Furniture Tags UI ──────────────────────────────────────────
  Widget _buildFurnitureTags(RoomModel r) {
    List<dynamic> list = [];
    if (r.furniture is List) {
      list = r.furniture as List;
    } else if (r.furniture is Map) {
      list = (r.furniture as Map).keys.toList();
    }

    if (list.isEmpty) {
      return const SizedBox.shrink();
    }

    // Helper map to translate code to name/emoji
    const furnitureMap = {
      'AC': {'label': 'Điều hoà', 'emoji': '❄️'},
      'NUOC_NONG': {'label': 'Nóng lạnh', 'emoji': '🚿'},
      'GIUONG': {'label': 'Giường', 'emoji': '🛏️'},
      'TU_QUAN_AO': {'label': 'Tủ áo', 'emoji': '🗄️'},
      'BAN_HOC': {'label': 'Bàn học', 'emoji': '📚'},
      'TU_LANH': {'label': 'Tủ lạnh', 'emoji': '🧊'},
      'MAY_GIAT': {'label': 'Máy giặt', 'emoji': '🫧'},
      'BEP': {'label': 'Bếp', 'emoji': '🍳'},
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TIỆN NGHI BÀN GIAO SẴN',
            style: TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: list.map((item) {
              final key = item.toString();
              final data = furnitureMap[key] ?? {'label': key, 'emoji': '📦'};
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(data['emoji']!, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      data['label']!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
