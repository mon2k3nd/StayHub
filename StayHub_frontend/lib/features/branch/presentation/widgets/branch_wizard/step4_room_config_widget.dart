import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/dashboard_refresh.dart';
import '../../../../../core/utils/image_url_helper.dart';
import '../../../../../core/utils/toast_utils.dart';
import '../../../application/branch_notifier.dart';
import '../../../data/models/branch_model.dart';
import '../../widgets/facility_config_bottom_sheet.dart';
import '../../widgets/room_config_bottom_sheet.dart';
import 'branch_wizard_theme.dart';
import 'dart:async' show unawaited;

/// BƯỚC 4 — Cấu hình phòng chi tiết.
///
/// Sau khi đã có sơ đồ không gian (Bước 3), chủ nhà tinh chỉnh TỪNG PHÒNG theo ID
/// và TỪNG WC CHUNG với đầy đủ thông số chi tiết.
class Step4RoomConfigWidget extends ConsumerStatefulWidget {
  final BranchModel? branch;
  final ValueChanged<BranchModel> onCompleted;

  const Step4RoomConfigWidget({
    super.key,
    required this.branch,
    required this.onCompleted,
  });

  @override
  ConsumerState<Step4RoomConfigWidget> createState() =>
      _Step4RoomConfigWidgetState();
}

final roomsProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((
  ref,
  branchId,
) async {
  final src = ref.read(branchRemoteDataSourceProvider);
  final res = await src.getRoomsByBranch(branchId);
  // BUGFIX (data): tránh `as List`/`as Map` ném TypeError khi `data` là
  // null/không phải List hoặc phần tử không phải Map.
  final raw = res['data'];
  if (raw is! List) return <Map<String, dynamic>>[];
  return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
});

/// Lấy các khu vực chung loại WC để Bước 4 cấu hình.
///
/// Loại bỏ tài sản chung (ASSET) thay vì chỉ nhận đúng `type == 'WC'`, vì các
/// bản ghi WC cũ (tạo trước khi có cột `type`) có thể mang giá trị null.
final facilitiesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((
      ref,
      branchId,
    ) async {
      final src = ref.read(branchRemoteDataSourceProvider);
      final res = await src.getFacilitiesByBranch(branchId);
      // BUGFIX (data): tránh `as List`/`as Map` ném TypeError khi `data` là
      // null/không phải List hoặc phần tử không phải Map.
      final raw = res['data'];
      if (raw is! List) return <Map<String, dynamic>>[];
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((f) => f['type']?.toString().toUpperCase() != 'ASSET')
          .toList();
    });

class _Step4RoomConfigWidgetState extends ConsumerState<Step4RoomConfigWidget> {
  bool _busy = false;
  final Set<int> _configuredRoomIds = {};
  final Set<int> _configuredFacilityIds = {};

  @override
  void initState() {
    super.initState();
    _refreshFromServer();
  }

  @override
  void didUpdateWidget(covariant Step4RoomConfigWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branch?.id != widget.branch?.id) _refreshFromServer();
  }

  /// Bước 3 vừa ghi cấu trúc phòng xuống DB. `roomsProvider` là
  /// FutureProvider.family nên cache theo branchId — nếu Bước 4 từng được dựng
  /// trước đó, cache rỗng sẽ khiến màn hình báo "chưa có phòng". Buộc nạp lại
  /// mỗi lần vào bước để luôn thấy phòng vừa tạo.
  void _refreshFromServer() {
    final b = widget.branch;
    if (b == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(roomsProvider(b.id));
      ref.invalidate(facilitiesProvider(b.id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.branch;
    if (b == null) {
      return const WzStepScaffold(
        title: 'Bước 4 · Cấu hình phòng',
        subtitle: 'Thông số chi tiết từng phòng',
        children: [
          WzNoticeCard(
            tone: WzNoticeTone.warning,
            message: 'Hoàn tất Bước 3 trước khi cấu hình phòng.',
          ),
        ],
      );
    }

    final roomsAsync = ref.watch(roomsProvider(b.id));
    final facilitiesAsync = ref.watch(facilitiesProvider(b.id));

    return WzStepScaffold(
      title: 'Bước 4 · Cấu hình phòng',
      subtitle: 'Cấu hình chi tiết từng phòng theo ID & WC chung',
      bottomBar: _buildActionButton(b, roomsAsync, facilitiesAsync),
      children: [
        const WzInfoCard(
          icon: CupertinoIcons.square_grid_2x2,
          title: 'Cấu hình chi tiết từng phòng',
          description:
              'Chạm vào từng phòng để thiết lập giá thuê, tiền cọc, diện tích, '
              'số người tối đa, chỉ số ban đầu, tài sản bàn giao và WC sử dụng. '
              'Cấu hình riêng cho từng WC chung nếu có.',
        ),
        const SizedBox(height: WzSpacing.lg),
        roomsAsync.when(
          skipLoadingOnReload: true,
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CupertinoActivityIndicator(radius: 14)),
          ),
          error: (e, _) => _buildError(
            'Lỗi tải phòng: $e',
            () => ref.invalidate(roomsProvider(b.id)),
          ),
          data: (rooms) => _buildRoomsSection(b, rooms),
        ),
        facilitiesAsync.when(
          skipLoadingOnReload: true,
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (facilities) => facilities.isEmpty
              ? const SizedBox.shrink()
              : _buildFacilitiesSection(b, facilities),
        ),
        const SizedBox(height: WzSpacing.xl),
      ],
    );
  }

  // ───────────────────────── ROOMS ─────────────────────────

  Widget _buildRoomsSection(BranchModel b, List<Map<String, dynamic>> rooms) {
    if (rooms.isEmpty) {
      return const WzNoticeCard(
        tone: WzNoticeTone.info,
        message: 'Chưa có phòng. Quay lại Bước 3 để tạo sơ đồ phòng trước.',
      );
    }

    final byFloor = <int, List<Map<String, dynamic>>>{};
    for (final r in rooms) {
      final floor = (r['floor'] as num?)?.toInt() ?? 0;
      byFloor.putIfAbsent(floor, () => []).add(r);
    }
    final floors = byFloor.keys.toList()..sort();

    // Thống kê phòng khép kín vs dùng WC chung (đồng bộ với Bước 3).
    final selfContained = rooms.where((r) {
      final shared =
          r['isSharedWc'] == true || (r['bathroomType']?.toString() == 'CHUNG');
      return !shared;
    }).length;
    final usingSharedWc = rooms.length - selfContained;

    final items = <Widget>[
      const WzSectionRow(
        icon: CupertinoIcons.bed_double_fill,
        title: 'Danh sách phòng',
        subtitle: 'Chạm vào phòng để cấu hình chi tiết theo ID.',
      ),
      const SizedBox(height: WzSpacing.sm),
      Row(
        children: [
          _infoChip(CupertinoIcons.lock_fill, '$selfContained khép kín'),
          const SizedBox(width: 8),
          _infoChip(CupertinoIcons.drop_fill, '$usingSharedWc dùng WC chung'),
        ],
      ),
      const SizedBox(height: WzSpacing.sm),
    ];

    for (final floor in floors) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(
            top: WzSpacing.md,
            bottom: WzSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: WzSpacing.md,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: WzColors.brand,
                  borderRadius: BorderRadius.circular(WzRadius.button),
                ),
                child: Text(
                  'Tầng $floor',
                  style: WzText.label.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: WzSpacing.sm),
              Text('${byFloor[floor]!.length} phòng', style: WzText.caption),
            ],
          ),
        ),
      );
      for (final room in byFloor[floor]!) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: WzSpacing.sm),
            child: _buildRoomCard(b, room),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }

  Widget _buildRoomCard(BranchModel b, Map<String, dynamic> room) {
    // BUGFIX (data): coerce an toàn — tránh `as int`/`as num` ném TypeError
    // khi backend trả String/null.
    final rawRoomId = room['id'];
    final roomId = rawRoomId is num
        ? rawRoomId.toInt()
        : int.tryParse(rawRoomId?.toString() ?? '') ?? 0;
    final rawName = '${room['roomName'] ?? roomId}';
    final title = rawName.toLowerCase().startsWith('phòng')
        ? rawName
        : 'Phòng $rawName';
    final roomCode = '${room['roomCode'] ?? '---'}';
    final rawArea = room['floorArea'];
    final area = rawArea is num
        ? rawArea.toStringAsFixed(0)
        : (double.tryParse(rawArea?.toString() ?? '') ?? 0).toStringAsFixed(0);
    final price = room['price'];
    final priceNum = price is num
        ? price.toDouble()
        : double.tryParse(price?.toString() ?? '') ?? 0.0;
    final priceText = priceNum > 0 ? _formatCurrency(priceNum) : 'Chưa có giá';
    final isConfigured =
        room['status'] != 'KHOA_CHO_CAP_NHAT' ||
        _configuredRoomIds.contains(roomId);

    // Xác định phòng khép kín hay dùng WC chung (đồng bộ với Bước 3).
    final bool isSharedWc =
        room['isSharedWc'] == true ||
        (room['bathroomType']?.toString() == 'CHUNG');
    final String? sharedWcCode = _resolveRoomWcCode(b, room);

    String? coverPhoto;
    final imgs = room['roomImages'] ?? room['images'];
    if (imgs is List && imgs.isNotEmpty) {
      coverPhoto = imgs.first.toString();
    } else if (imgs is String && imgs.isNotEmpty) {
      try {
        final decoded = imgs.startsWith('[') ? jsonDecode(imgs) : [imgs];
        if (decoded is List && decoded.isNotEmpty) {
          coverPhoto = decoded.first.toString();
        }
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () => _showRoomConfigSheet(b, room),
      child: Container(
        padding: const EdgeInsets.all(WzSpacing.md),
        decoration: BoxDecoration(
          color: WzColors.surface,
          borderRadius: BorderRadius.circular(WzRadius.card),
          border: Border.all(
            color: isConfigured
                ? WzColors.success.withValues(alpha: 0.4)
                : WzColors.border,
            width: isConfigured ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(WzRadius.tile),
              child: coverPhoto != null && coverPhoto.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: ImageUrlHelper.buildUrl(coverPhoto) ?? '',
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _roomIcon(isConfigured),
                    )
                  : _roomIcon(isConfigured),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: WzText.cardTitle.copyWith(
                            color: WzColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: WzSpacing.sm),
                      if (!isConfigured)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: WzColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(WzRadius.chip),
                          ),
                          child: Text(
                            'CẦN THIẾT LẬP',
                            style: WzText.caption.copyWith(
                              color: WzColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    roomCode,
                    style: WzText.caption.copyWith(
                      color: WzColors.textFaint,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _infoChip(CupertinoIcons.square_split_2x1, '$area m²'),
                      const SizedBox(width: WzSpacing.sm),
                      _infoChip(
                        CupertinoIcons.money_dollar_circle,
                        priceText,
                        isPrice: true,
                        configured: priceText != 'Chưa có giá',
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildWcBadge(isSharedWc, sharedWcCode),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isConfigured
                  ? CupertinoIcons.checkmark_alt_circle_fill
                  : CupertinoIcons.chevron_right,
              size: 18,
              color: isConfigured ? WzColors.success : WzColors.textFaint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _roomIcon(bool isConfigured) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: isConfigured
            ? WzColors.success.withValues(alpha: 0.1)
            : WzColors.surfaceMuted,
        borderRadius: BorderRadius.circular(WzRadius.tile),
      ),
      child: Icon(
        CupertinoIcons.bed_double_fill,
        color: isConfigured ? WzColors.success : WzColors.textFaint,
        size: 24,
      ),
    );
  }

  Widget _infoChip(
    IconData icon,
    String label, {
    bool isPrice = false,
    bool configured = false,
  }) {
    final color = isPrice
        ? (configured ? WzColors.success : WzColors.error)
        : WzColors.textSecondary;
    final bg = isPrice
        ? (configured
              ? WzColors.success.withValues(alpha: 0.12)
              : WzColors.error.withValues(alpha: 0.12))
        : WzColors.surfaceMuted;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WzSpacing.sm,
        vertical: WzSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(WzRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: WzText.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Badge hiển thị phòng khép kín hay dùng WC chung (kèm mã WC).
  Widget _buildWcBadge(bool isSharedWc, String? wcCode) {
    final bool selfContained = !isSharedWc;
    final Color color = selfContained ? WzColors.success : WzColors.brand;
    final Color bg = selfContained
        ? WzColors.success.withValues(alpha: 0.12)
        : WzColors.brand.withValues(alpha: 0.12);
    final IconData icon = selfContained
        ? CupertinoIcons.lock_fill
        : CupertinoIcons.drop_fill;
    final String label = selfContained
        ? 'Khép kín'
        : (wcCode != null && wcCode.isNotEmpty ? 'WC: $wcCode' : 'WC chung');
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WzSpacing.sm,
        vertical: WzSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(WzRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: WzText.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Mã WC chung mà phòng đang dùng — ưu tiên `sharedWcId`, fallback sang
  /// danh sách `sharedFacilities` (ManyToMany) trả về từ backend.
  String? _resolveRoomWcCode(BranchModel b, Map<String, dynamic> room) {
    final direct = room['sharedWcId']?.toString();
    if (direct != null && direct.isNotEmpty) {
      return _fullWcCode(b, direct);
    }
    final shared = room['sharedFacilities'];
    if (shared is List && shared.isNotEmpty) {
      // Bỏ qua tài sản chung (ASSET) — tránh nhầm thành WC. Các WC cũ có thể
      // mang type null nên chỉ loại trừ ASSET thay vì bắt buộc type == 'WC'.
      final wc = shared.firstWhere(
        (f) => f is Map && f['type']?.toString().toUpperCase() != 'ASSET',
        orElse: () => null,
      );
      if (wc is Map) {
        final notes = wc['notes']?.toString();
        if (notes != null && notes.isNotEmpty) return _fullWcCode(b, notes);
      }
    }
    return null;
  }

  /// Mã WC đầy đủ theo đúng logic Bước 3: `{branchCode}_{mã ngắn}` (VD: NHA_WC1A).
  ///
  /// Dùng [BranchModelX.displayCode] để bóc placeholder `__SUSPENDED__...`
  /// (nếu có) — tránh sinh ra mã WC lẫn chuỗi kỹ thuật.
  String _fullWcCode(BranchModel b, String shortCode) {
    if (shortCode.contains('_')) return shortCode; // đã có tiền tố
    final prefix = b.displayCode.isNotEmpty ? b.displayCode : 'CN';
    return '${prefix}_$shortCode';
  }

  // ───────────────────────── FACILITIES ─────────────────────────

  Widget _buildFacilitiesSection(
    BranchModel b,
    List<Map<String, dynamic>> facilities,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: WzSpacing.lg),
        const WzSectionRow(
          icon: CupertinoIcons.drop_fill,
          title: 'WC chung',
          subtitle: 'Cấu hình thiết bị, chỉ số và phòng sử dụng.',
        ),
        const SizedBox(height: WzSpacing.sm),
        ...facilities.map(
          (wc) => Padding(
            padding: const EdgeInsets.only(bottom: WzSpacing.sm),
            child: _buildFacilityCard(b, wc),
          ),
        ),
      ],
    );
  }

  // BUGFIX (data): coerce an toàn id từ backend (có thể là String/null).
  int _asId(dynamic v) =>
      v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

  Widget _buildFacilityCard(BranchModel b, Map<String, dynamic> wc) {
    final wcId = _asId(wc['id']);
    final isConfigured =
        _configuredFacilityIds.contains(wcId) ||
        wc['equipment'] != null ||
        wc['images'] != null;

    String? firstImage;
    final imgs = wc['images'];
    if (imgs is List && imgs.isNotEmpty) {
      firstImage = imgs.first.toString();
    } else if (imgs is String && imgs.isNotEmpty) {
      try {
        final parsed = jsonDecode(imgs);
        if (parsed is List && parsed.isNotEmpty) {
          firstImage = parsed.first.toString();
        }
      } catch (_) {}
    }

    // Mã WC đầy đủ theo đúng logic Bước 3: {branchCode}_{mã ngắn} (VD: NHA_WC1A).
    final shortCode = (wc['notes'] != null && wc['notes'].toString().isNotEmpty)
        ? wc['notes'].toString()
        : 'WC$wcId';
    final code = _fullWcCode(b, shortCode);

    // Danh sách phòng đang dùng WC này (từ quan hệ ManyToMany backend trả về).
    final assignedRooms = _roomsUsingWc(b, wc);

    return GestureDetector(
      onTap: () => _showFacilityConfigSheet(b, wc),
      child: Container(
        padding: const EdgeInsets.all(WzSpacing.md),
        decoration: BoxDecoration(
          color: WzColors.surface,
          borderRadius: BorderRadius.circular(WzRadius.card),
          border: Border.all(
            color: isConfigured
                ? WzColors.success.withValues(alpha: 0.4)
                : WzColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isConfigured
                        ? WzColors.success.withValues(alpha: 0.1)
                        : WzColors.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: firstImage != null && firstImage.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: ImageUrlHelper.buildUrl(firstImage) ?? '',
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Icon(
                              CupertinoIcons.drop_fill,
                              color: isConfigured
                                  ? WzColors.success
                                  : WzColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        )
                      : Icon(
                          CupertinoIcons.drop_fill,
                          color: isConfigured
                              ? WzColors.success
                              : WzColors.textSecondary,
                          size: 20,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề = tên WC (mã ngắn, VD: WC1A) theo logic Bước 3.
                      Text(
                        shortCode,
                        style: WzText.cardTitle.copyWith(
                          color: WzColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mã: $code',
                        style: WzText.caption.copyWith(
                          color: WzColors.textFaint,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isConfigured
                      ? CupertinoIcons.checkmark_alt_circle_fill
                      : CupertinoIcons.chevron_right,
                  size: 18,
                  color: isConfigured ? WzColors.success : WzColors.textFaint,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildWcRoomList(assignedRooms),
          ],
        ),
      ),
    );
  }

  /// Danh sách phòng đang dùng một WC chung — dựa trên `sharedFacilities`
  /// của từng phòng (quan hệ ManyToMany backend trả về).
  List<Map<String, dynamic>> _roomsUsingWc(
    BranchModel b,
    Map<String, dynamic> wc,
  ) {
    final wcId = wc['id'];
    final allRooms = ref.read(roomsProvider(b.id)).value ?? [];
    final result = <Map<String, dynamic>>[];
    for (final r in allRooms) {
      final shared = r['sharedFacilities'];
      if (shared is List && shared.any((f) => f is Map && f['id'] == wcId)) {
        result.add(r);
      }
    }
    return result;
  }

  /// Hiển thị danh sách phòng dùng WC (chip nhỏ) hoặc cảnh báo chưa có phòng.
  Widget _buildWcRoomList(List<Map<String, dynamic>> rooms) {
    if (rooms.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: WzSpacing.sm,
          vertical: WzSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: WzColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(WzRadius.chip),
        ),
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              size: 13,
              color: WzColors.warning,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Chưa có phòng nào dùng WC này',
                style: WzText.caption.copyWith(
                  color: WzColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${rooms.length} phòng đang dùng',
          style: WzText.caption.copyWith(
            color: WzColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: rooms.map((r) {
            final code = '${r['roomCode'] ?? r['roomName'] ?? r['id']}';
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: WzSpacing.sm,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: WzColors.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(WzRadius.chip),
              ),
              child: Text(
                code,
                style: WzText.caption.copyWith(
                  color: WzColors.brandDeep,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ───────────────────────── SHEETS ─────────────────────────

  Future<void> _showRoomConfigSheet(
    BranchModel b,
    Map<String, dynamic> room,
  ) async {
    final roomId = _asId(room['id']);
    final allFacilities = ref.read(facilitiesProvider(b.id)).value ?? [];
    final allRooms = ref.read(roomsProvider(b.id)).value ?? [];

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RoomConfigBottomSheet(
        room: room,
        branch: b,
        defaultPrice: 0,
        allFacilities: allFacilities,
        allRooms: allRooms,
        onSaved: (data, progress) async {
          final src = ref.read(branchRemoteDataSourceProvider);
          await src.configureRoom(roomId, data, onSendProgress: progress);
          if (mounted) {
            setState(() => _configuredRoomIds.add(roomId));
            ref.invalidate(roomsProvider(b.id));
            // Phòng vừa được cấu hình → cập nhật ngay ô "Chưa đăng" trên dashboard.
            refreshOwnerDashboardFromWidget(ref);
          }
          unawaited(HapticFeedback.lightImpact());
        },
        onApplyMultiple: (data, progress) async {
          // Đóng sheet cấu hình phòng trước khi mở hộp thoại áp dụng hàng loạt.
          if (ctx.mounted) Navigator.pop(ctx);
          _showBulkEditDialog(b, data, roomId);
        },
      ),
    );

    if (result == 'OPEN_WC_CONFIG' && mounted) {
      final allFacs = ref.read(facilitiesProvider(b.id)).value ?? [];
      final unconfigured = allFacs
          .where(
            (f) =>
                f['type'] == 'WC' && !_configuredFacilityIds.contains(f['id']),
          )
          .toList();
      final wc = unconfigured.isNotEmpty
          ? unconfigured.first
          : allFacs.where((f) => f['type'] == 'WC').firstOrNull;
      if (wc != null) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _showFacilityConfigSheet(b, wc);
        });
      } else {
        ToastUtils.show(
          context,
          'Không có WC chung nào để cấu hình',
          isError: true,
        );
      }
    }
  }

  void _showFacilityConfigSheet(BranchModel b, Map<String, dynamic> wc) {
    final wcId = _asId(wc['id']);
    final allRooms = ref.read(roomsProvider(b.id)).value ?? [];

    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => FacilityConfigBottomSheet(
          facility: wc,
          allRooms: allRooms,
          onSaved: (data) async {
            final src = ref.read(branchRemoteDataSourceProvider);
            await src.configureFacility(b.id, wcId, data);
            if (mounted) {
              setState(() => _configuredFacilityIds.add(wcId));
              ref.invalidate(facilitiesProvider(b.id));
              ref.invalidate(roomsProvider(b.id));
              refreshOwnerDashboardFromWidget(ref);
            }
            unawaited(HapticFeedback.lightImpact());
            // Đóng ĐÚNG sheet vừa mở (ctx), không dùng `context` của widget —
            // tránh pop nhầm route khi sheet đã bị đóng trong lúc await.
            if (ctx.mounted) Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  void _showBulkEditDialog(
    BranchModel b,
    Map<String, dynamic> configData,
    int sourceRoomId,
  ) {
    final rooms = ref.read(roomsProvider(b.id)).value ?? [];
    final otherRooms = rooms.where((r) => r['id'] != sourceRoomId).toList();
    if (otherRooms.isEmpty) {
      ToastUtils.show(context, 'Không có phòng nào khác để áp dụng');
      return;
    }

    final selectedRoomIds = <int>{};
    bool isApplying = false;

    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (context, setModalState) => Material(
            color: WzColors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(WzRadius.card),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(WzSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Áp dụng cấu hình cho nhiều phòng',
                      style: WzText.screenTitle,
                    ),
                    const SizedBox(height: WzSpacing.sm),
                    Text(
                      'Chọn các phòng bạn muốn sao chép cấu hình này',
                      style: WzText.body.copyWith(
                        color: WzColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: WzSpacing.lg),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: otherRooms.length,
                        itemBuilder: (context, i) {
                          final r = otherRooms[i];
                          final rId = _asId(r['id']);
                          return CheckboxListTile(
                            title: Text(
                              'Phòng ${r['roomName']} (Tầng ${r['floor']})',
                            ),
                            value: selectedRoomIds.contains(rId),
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  selectedRoomIds.add(rId);
                                } else {
                                  selectedRoomIds.remove(rId);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: WzSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: WzColors.brand,
                        onPressed: isApplying || selectedRoomIds.isEmpty
                            ? null
                            : () async {
                                setModalState(() => isApplying = true);
                                try {
                                  final src = ref.read(
                                    branchRemoteDataSourceProvider,
                                  );
                                  await src.configureRoom(
                                    sourceRoomId,
                                    configData,
                                  );
                                  if (mounted) {
                                    setState(
                                      () =>
                                          _configuredRoomIds.add(sourceRoomId),
                                    );
                                  }
                                  for (final rId in selectedRoomIds) {
                                    await src.configureRoom(rId, configData);
                                    if (mounted) {
                                      setState(
                                        () => _configuredRoomIds.add(rId),
                                      );
                                    }
                                  }
                                  ref.invalidate(roomsProvider(b.id));
                                  refreshOwnerDashboardFromWidget(ref);
                                  unawaited(HapticFeedback.lightImpact());
                                  if (sheetCtx.mounted) {
                                    Navigator.pop(sheetCtx);
                                  }
                                  if (!context.mounted) return;
                                  ToastUtils.show(
                                    context,
                                    'Áp dụng thành công!',
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ToastUtils.show(
                                    context,
                                    'Lỗi: $e',
                                    isError: true,
                                  );
                                } finally {
                                  if (mounted) {
                                    setModalState(() => isApplying = false);
                                  }
                                }
                              },
                        child: isApplying
                            ? const CupertinoActivityIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                'Áp dụng (${selectedRoomIds.length} phòng)',
                                style: WzText.button,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── ACTION BAR ─────────────────────────

  Widget _buildActionButton(
    BranchModel b,
    AsyncValue<List<Map<String, dynamic>>> roomsAsync,
    AsyncValue<List<Map<String, dynamic>>> facilitiesAsync,
  ) {
    final rooms = roomsAsync.value ?? [];
    final facilities = facilitiesAsync.value ?? [];

    final totalRooms = rooms.length;
    final doneRooms = rooms
        .where(
          (r) =>
              r['status'] != 'KHOA_CHO_CAP_NHAT' ||
              _configuredRoomIds.contains(_asId(r['id'])),
        )
        .length;

    final totalWcs = facilities.length;
    final doneWcs = facilities
        .where(
          (f) =>
              (f['equipment'] != null || f['images'] != null) ||
              _configuredFacilityIds.contains(_asId(f['id'])),
        )
        .length;

    final allDone =
        totalRooms > 0 &&
        doneRooms == totalRooms &&
        (totalWcs == 0 || doneWcs == totalWcs);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _progressChip(label: 'Phòng', done: doneRooms, total: totalRooms),
            if (totalWcs > 0) ...[
              const SizedBox(width: WzSpacing.sm),
              _progressChip(label: 'WC', done: doneWcs, total: totalWcs),
            ],
          ],
        ),
        const SizedBox(height: WzSpacing.sm),
        WzPrimaryButton(
          label: allDone
              ? 'Hoàn tất Bước 4'
              : 'Còn ${(totalRooms - doneRooms) + (totalWcs - doneWcs)} mục chưa xong',
          icon: allDone
              ? CupertinoIcons.checkmark_alt_circle_fill
              : CupertinoIcons.lock_fill,
          color: allDone ? WzColors.success : WzColors.textFaint,
          loading: _busy,
          enabled: allDone,
          onPressed: allDone ? () => _completeStep(b) : null,
        ),
      ],
    );
  }

  Widget _progressChip({
    required String label,
    required int done,
    required int total,
  }) {
    final allDone = done == total;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WzSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: allDone
            ? WzColors.success.withValues(alpha: 0.12)
            : WzColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(WzRadius.button),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            allDone
                ? CupertinoIcons.checkmark_alt_circle_fill
                : CupertinoIcons.clock_fill,
            size: 12,
            color: allDone ? WzColors.success : WzColors.warning,
          ),
          const SizedBox(width: 5),
          Text(
            '$label $done/$total',
            style: WzText.label.copyWith(
              color: allDone ? WzColors.success : WzColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeStep(BranchModel b) async {
    setState(() => _busy = true);
    try {
      final updated = await ref
          .read(branchProvider.notifier)
          .markStep(b.id, 4, true);
      if (!mounted) return;
      ToastUtils.show(context, 'Đã lưu cấu hình phòng');
      widget.onCompleted(updated ?? b);
    } catch (e) {
      if (mounted) {
        ToastUtils.show(
          context,
          'Không thể lưu cấu hình phòng: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _buildError(String msg, VoidCallback onRetry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 40,
            color: WzColors.error,
          ),
          const SizedBox(height: 12),
          Text(msg, style: WzText.caption, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          CupertinoButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      final m = amount / 1000000;
      return '${m % 1 == 0 ? m.toInt() : m.toStringAsFixed(1)}tr/tháng';
    } else if (amount >= 1000) {
      final k = amount / 1000;
      return '${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(0)}k/tháng';
    }
    return '${amount.toInt()}/tháng';
  }
}
