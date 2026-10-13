import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/dashboard_refresh.dart';
import '../application/branch_notifier.dart';
import 'widgets/room_config_bottom_sheet.dart';
import 'widgets/facility_config_bottom_sheet.dart';
import '../../marketplace/presentation/widgets/guest_room_detail_premium.dart';
import '../../../core/utils/image_url_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'widgets/onboarding_checklist_card.dart';
import '../../room/data/models/room_model.dart';
import 'dart:async' show unawaited;

// ─────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────

final _branchRoomsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((
      ref,
      branchId,
    ) async {
      final src = ref.read(branchRemoteDataSourceProvider);
      final res = await src.getRoomsByBranch(branchId);
      // BUGFIX (data): tránh `as List`/`as Map` ném TypeError khi `data` là
      // null/không phải List hoặc phần tử không phải Map.
      final raw = res['data'];
      if (raw is! List) return <Map<String, dynamic>>[];
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    });

final _branchFacilitiesProvider =
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
          .toList();
    });

// ─────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────

class BranchDetailedConfigScreen extends ConsumerStatefulWidget {
  final int branchId;
  final String branchName;
  final bool isReadOnly;

  const BranchDetailedConfigScreen({
    super.key,
    required this.branchId,
    required this.branchName,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<BranchDetailedConfigScreen> createState() =>
      _BranchDetailedConfigScreenState();
}

class _BranchDetailedConfigScreenState
    extends ConsumerState<BranchDetailedConfigScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isCompleting = false;
  bool _isMatrixView = false;

  // Track which rooms/wcs have been configured locally
  final Set<int> _configuredRoomIds = {};
  final Set<int> _configuredFacilityIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Pre-populate configured sets from server data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final roomsData = ref.read(_branchRoomsProvider(widget.branchId)).value;
      if (roomsData != null) {
        for (final r in roomsData) {
          if (r['status'] != 'KHOA_CHO_CAP_NHAT') {
            // BUGFIX: `id` có thể là String (JSON) hoặc null → ép `as int`
            // sẽ ném TypeError trong post-frame callback, làm sập màn hình.
            final id = r['id'];
            final roomId = id is int ? id : int.tryParse(id?.toString() ?? '');
            if (roomId != null) _configuredRoomIds.add(roomId);
          }
        }
      }
      final facilsData = ref
          .read(_branchFacilitiesProvider(widget.branchId))
          .value;
      if (facilsData != null) {
        // Mark facilities with notes (already configured) as done
        for (final f in facilsData) {
          final notes = f['notes']?.toString() ?? '';
          if (notes.isNotEmpty) {
            final id = f['id'];
            final facId = id is int ? id : int.tryParse(id?.toString() ?? '');
            if (facId != null) _configuredFacilityIds.add(facId);
          }
        }
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Chuyển `id` (có thể là int, String JSON, hoặc null) về int an toàn.
  /// Trả về -1 nếu không parse được (không khớp với id hợp lệ nào).
  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? -1;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }

  DateTime? _getDeletionDate(dynamic b) {
    if (b.updatedAt != null) return b.updatedAt;
    final code = b.branchCode.toString();
    if (code.contains('_OFF_')) {
      final parts = code.split('_OFF_');
      if (parts.length > 1) {
        final msStr = parts[1];
        final ms = int.tryParse(msStr);
        if (ms != null) {
          return DateTime.fromMillisecondsSinceEpoch(ms);
        }
      }
    }
    return null;
  }

  Future<void> _handleComplete() async {
    setState(() => _isCompleting = true);
    try {
      await ref.read(branchProvider.notifier).completeBranch(widget.branchId);
      if (mounted) {
        unawaited(HapticFeedback.heavyImpact());
        // unawaited(Show success then navigate to dashboard)
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('🎉 Hoàn tất!'),
              content: const Text(
                'Chi nhánh đã được kích hoạt. Bạn có muốn đăng bài cho thuê ngay không?',
              ),
              actions: [
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  child: const Text('Để sau'),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    unawaited(context.push('/create-post'));
                  },
                  child: const Text('Đăng bài ngay'),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(_branchRoomsProvider(widget.branchId));
    final facilitiesAsync = ref.watch(
      _branchFacilitiesProvider(widget.branchId),
    );
    final branches = ref.watch(branchProvider).value ?? [];
    final currentBranch = branches
        .where((b) => b.id == widget.branchId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppTheme.kBackgroundLight,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE3F0FF), AppTheme.kBackgroundLight],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.4],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        child: const Icon(
                          CupertinoIcons.back,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              widget.isReadOnly
                                  ? 'Xem chi nhánh'
                                  : 'Cấu hình chi nhánh',
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              widget.branchName,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (currentBranch != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    CupertinoIcons.calendar_today,
                                    size: 12,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Ngày tạo: ${_formatDate(currentBranch.createdAt)}',
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              if (!currentBranch.isActive &&
                                  _getDeletionDate(currentBranch) != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      CupertinoIcons.trash_fill,
                                      size: 12,
                                      color: Color(0xFFEF4444),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Ngày xóa: ${_formatDate(_getDeletionDate(currentBranch))}',
                                      style: const TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 48), // Balance leading button
                    ],
                  ),
                ),

                // Onboarding Checklist
                if (currentBranch != null &&
                    !widget.isReadOnly &&
                    roomsAsync.hasValue)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: OnboardingChecklistCard(
                      branch: currentBranch,
                      rooms: roomsAsync.value!
                          .map((e) => RoomModel.fromJson(e))
                          .toList(),
                    ),
                  ),

                // Custom TabBar
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF6B7280),
                    indicator: BoxDecoration(
                      color: const Color(0xFF0EA5E9),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    tabs: [
                      Tab(
                        child: roomsAsync.when(
                          skipLoadingOnReload: true,
                          data: (rooms) {
                            // Count rooms that are configured: status != KHOA
                            // BUGFIX (data): coerce id an toàn — tránh `as int`
                            // ném TypeError khi id là String/null.
                            final configured = rooms.where((r) {
                              if (r['status'] != 'KHOA_CHO_CAP_NHAT') {
                                return true;
                              }
                              final rawId = r['id'];
                              final id = rawId is num
                                  ? rawId.toInt()
                                  : int.tryParse(rawId?.toString() ?? '');
                              return id != null &&
                                  _configuredRoomIds.contains(id);
                            }).length;
                            return Text('Phòng ($configured/${rooms.length})');
                          },
                          loading: () => const Text('Phòng'),
                          error: (_, __) => const Text('Phòng'),
                        ),
                      ),
                      const Tab(text: 'WC Chung'),
                    ],
                  ),
                ),

                // TabBarView Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // ── TAB 1: ROOMS ──
                      roomsAsync.when(
                        skipLoadingOnReload: true,
                        loading: () => const Center(
                          child: CupertinoActivityIndicator(radius: 16),
                        ),
                        error: (e, _) => _buildError(
                          'Lỗi tải phòng: $e',
                          () => ref.invalidate(
                            _branchRoomsProvider(widget.branchId),
                          ),
                        ),
                        data: (rooms) => _buildRoomsTab(rooms),
                      ),
                      // ── TAB 2: FACILITIES ──
                      facilitiesAsync.when(
                        skipLoadingOnReload: true,
                        loading: () => const Center(
                          child: CupertinoActivityIndicator(radius: 16),
                        ),
                        error: (e, _) => _buildError(
                          'Lỗi tải WC: $e',
                          () => ref.invalidate(
                            _branchFacilitiesProvider(widget.branchId),
                          ),
                        ),
                        data: (facilities) => _buildFacilitiesTab(facilities),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.isReadOnly
          ? const SizedBox.shrink()
          : roomsAsync.when(
              skipLoadingOnReload: true,
              data: (rooms) => facilitiesAsync.when(
                skipLoadingOnReload: true,
                data: (facilities) {
                  // All rooms done: status != KHOA or saved this session
                  final totalRooms = rooms.length;
                  final doneRooms = rooms
                      .where(
                        (r) =>
                            r['status'] != 'KHOA_CHO_CAP_NHAT' ||
                            _configuredRoomIds.contains(_asInt(r['id'])),
                      )
                      .length;

                  // All WCs done: has equipment or images (configured)
                  final totalWcs = facilities.length;
                  final doneWcs = facilities
                      .where(
                        (f) =>
                            (f['equipment'] != null || f['images'] != null) ||
                            _configuredFacilityIds.contains(_asInt(f['id'])),
                      )
                      .length;

                  final allDone =
                      totalRooms > 0 &&
                      doneRooms == totalRooms &&
                      (totalWcs == 0 || doneWcs == totalWcs);

                  return Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x0F000000),
                          blurRadius: 20,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Progress summary row
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                _progressChip(
                                  label: 'Phòng',
                                  done: doneRooms,
                                  total: totalRooms,
                                ),
                                const SizedBox(width: 10),
                                if (totalWcs > 0)
                                  _progressChip(
                                    label: 'WC',
                                    done: doneWcs,
                                    total: totalWcs,
                                  ),
                                const Spacer(),
                                if (!allDone)
                                  Text(
                                    'Còn ${(totalRooms - doneRooms) + (totalWcs - doneWcs)} mục chưa xong',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Button
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: allDone
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF10B981),
                                        Color(0xFF059669),
                                      ],
                                    )
                                  : null,
                              color: allDone ? null : const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: allDone
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF10B981,
                                        ).withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              borderRadius: BorderRadius.circular(100),
                              onPressed: (allDone && !_isCompleting)
                                  ? _handleComplete
                                  : null,
                              child: _isCompleting
                                  ? const CupertinoActivityIndicator(
                                      color: Colors.white,
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          allDone
                                              ? CupertinoIcons
                                                    .checkmark_seal_fill
                                              : CupertinoIcons.lock_fill,
                                          size: 18,
                                          color: allDone
                                              ? Colors.white
                                              : const Color(0xFF9CA3AF),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          allDone
                                              ? 'Hoàn tất & Kích hoạt'
                                              : 'Hoàn thành cấu hình trước',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: allDone
                                                ? Colors.white
                                                : const Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => _simpleCompleteBar(),
                error: (_, __) => _simpleCompleteBar(),
              ),
              loading: () => _simpleCompleteBar(),
              error: (_, __) => _simpleCompleteBar(),
            ),
    );
  }

  Widget _progressChip({
    required String label,
    required int done,
    required int total,
  }) {
    final allDone = done == total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: allDone ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            allDone
                ? CupertinoIcons.checkmark_alt_circle_fill
                : CupertinoIcons.clock_fill,
            size: 12,
            color: allDone ? const Color(0xFF059669) : const Color(0xFFD97706),
          ),
          const SizedBox(width: 5),
          Text(
            '$label $done/$total',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: allDone
                  ? const Color(0xFF065F46)
                  : const Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _simpleCompleteBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Center(
            child: Text(
              'Đang tải...',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(String msg, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 48,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(height: 16),
          CupertinoButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildRoomsTab(List<Map<String, dynamic>> rooms) {
    if (rooms.isEmpty) {
      return const Center(
        child: Text(
          'Không có phòng nào',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }

    // Group by floor
    final Map<int, List<Map<String, dynamic>>> byFloor = {};
    for (final room in rooms) {
      final floor = (room['floor'] as num?)?.toInt() ?? 0;
      byFloor.putIfAbsent(floor, () => []).add(room);
    }
    final sortedFloors = byFloor.keys.toList()..sort();

    final configuredCount = rooms.where((r) {
      return r['status'] != 'KHOA_CHO_CAP_NHAT' ||
          _configuredRoomIds.contains(_asInt(r['id']));
    }).length;

    if (_isMatrixView) {
      return _buildRoomsFloorMatrix(
        rooms,
        sortedFloors,
        byFloor,
        configuredCount,
      );
    }

    final List<Widget> items = [];
    // Toggle bar at the top of list view
    items.add(_buildViewToggleBar(rooms.length, configuredCount));

    for (final floor in sortedFloors) {
      // Floor section header
      items.add(
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 10, left: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Tầng $floor',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${byFloor[floor]!.length} phòng',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
            ],
          ),
        ),
      );

      // Room cards in this floor
      for (final room in byFloor[floor]!) {
        final roomId = _asInt(room['id']);
        final rawName = '${room['roomName'] ?? roomId}';
        final title = rawName.toLowerCase().startsWith('phòng')
            ? rawName
            : 'Phòng $rawName';
        final roomCode = '${room['roomCode'] ?? '---'}';
        final area = (room['floorArea'] as num?)?.toStringAsFixed(0) ?? '0';
        final priceNum = room['price'] is num
            ? room['price'] as num
            : num.tryParse(room['price']?.toString() ?? '');
        final priceText = (priceNum != null && priceNum > 0)
            ? _formatCurrency(priceNum.toDouble())
            : 'Chưa có giá';

        final isConfigured =
            room['status'] != 'KHOA_CHO_CAP_NHAT' ||
            _configuredRoomIds.contains(roomId);

        String? coverPhoto;
        final roomImagesRaw = room['roomImages'] ?? room['images'];
        if (roomImagesRaw is List && roomImagesRaw.isNotEmpty) {
          coverPhoto = roomImagesRaw.first.toString();
        } else if (roomImagesRaw is String && roomImagesRaw.isNotEmpty) {
          try {
            final decoded = (roomImagesRaw.startsWith('['))
                ? (roomImagesRaw
                      .replaceAll('[', '')
                      .replaceAll(']', '')
                      .replaceAll('"', '')
                      .replaceAll(r'\', '')
                      .split(','))
                : [roomImagesRaw];
            if (decoded.isNotEmpty) coverPhoto = decoded.first.trim();
          } catch (_) {}
        }

        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildRoomCard(
              roomId: roomId,
              title: title,
              roomCode: roomCode,
              area: area,
              priceText: priceText,
              isConfigured: isConfigured,
              coverPhoto: coverPhoto,
              onTap: () => _showRoomConfigSheet(room),
              onPreview: () => _showPreviewSheet(room),
            ),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: items,
    );
  }

  Widget _buildViewToggleBar(int totalRooms, int configuredRooms) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  size: 13,
                  color: Color(0xFF0EA5E9),
                ),
                const SizedBox(width: 4),
                Text(
                  '$configuredRooms/$totalRooms sẵn sàng',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ],
            ),
          ),
          // Segmented Toggle
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF69B1FF).withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleOption(
                  isSelected: !_isMatrixView,
                  icon: CupertinoIcons.list_bullet,
                  label: 'Danh sách',
                  onTap: () {
                    if (_isMatrixView) {
                      unawaited(HapticFeedback.selectionClick());
                      setState(() => _isMatrixView = false);
                    }
                  },
                ),
                _buildToggleOption(
                  isSelected: _isMatrixView,
                  icon: CupertinoIcons.square_grid_2x2_fill,
                  label: 'Ma trận tầng',
                  onTap: () {
                    if (!_isMatrixView) {
                      unawaited(HapticFeedback.selectionClick());
                      setState(() => _isMatrixView = true);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required bool isSelected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF69B1FF), Color(0xFF0EA5E9)],
                )
              : null,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsFloorMatrix(
    List<Map<String, dynamic>> rooms,
    List<int> sortedFloors,
    Map<int, List<Map<String, dynamic>>> byFloor,
    int configuredCount,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _buildViewToggleBar(rooms.length, configuredCount),
        // Color Legend
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Wrap(
            spacing: 14,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _legendItem(const Color(0xFF10B981), 'Sẵn sàng / Trống'),
              _legendItem(const Color(0xFF0EA5E9), 'Đang ở'),
              _legendItem(const Color(0xFF94A3B8), 'Chờ thiết lập'),
            ],
          ),
        ),
        // Floors
        for (final floor in sortedFloors)
          _buildFloorMatrixCard(floor, byFloor[floor]!),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildFloorMatrixCard(
    int floor,
    List<Map<String, dynamic>> floorRooms,
  ) {
    final total = floorRooms.length;
    final ready = floorRooms.where((r) {
      return r['status'] != 'KHOA_CHO_CAP_NHAT' ||
          _configuredRoomIds.contains(_asInt(r['id']));
    }).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF69B1FF).withValues(alpha: 0.18),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F69B1FF),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'Tầng $floor',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$total phòng',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ready == total
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  '$ready/$total xong',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: ready == total
                        ? const Color(0xFF059669)
                        : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Room Cells Grid
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: floorRooms.map((room) {
              return _buildMatrixRoomCell(room);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixRoomCell(Map<String, dynamic> room) {
    final roomId = _asInt(room['id']);
    final isConfigured = room['status'] != 'KHOA_CHO_CAP_NHAT' ||
        _configuredRoomIds.contains(roomId);
    final statusRaw = (room['status'] ?? '').toString().toUpperCase();
    final isRented = statusRaw == 'DANG_THUE' || statusRaw == 'RENTED';

    final rawName = '${room['roomName'] ?? roomId}';
    final shortName = rawName
        .replaceAll(RegExp(r'^(phòng|phong)\s*', caseSensitive: false), '')
        .trim();
    final area = (room['floorArea'] as num?)?.toStringAsFixed(0) ?? '0';

    final priceNum = room['price'] is num
        ? room['price'] as num
        : num.tryParse(room['price']?.toString() ?? '');
    final priceShort = (priceNum != null && priceNum > 0)
        ? '${(priceNum / 1000000).toStringAsFixed(1)}Tr'
        : '---';

    Color bg;
    Color border;
    Color textColor;
    IconData icon;

    if (isRented) {
      bg = const Color(0xFFEFF6FF);
      border = const Color(0xFF3B82F6);
      textColor = const Color(0xFF1D4ED8);
      icon = CupertinoIcons.person_fill;
    } else if (isConfigured || widget.isReadOnly) {
      bg = const Color(0xFFECFDF5);
      border = const Color(0xFF10B981);
      textColor = const Color(0xFF047857);
      icon = CupertinoIcons.checkmark_seal_fill;
    } else {
      bg = const Color(0xFFF8FAFC);
      border = const Color(0xFFCBD5E1);
      textColor = const Color(0xFF64748B);
      icon = CupertinoIcons.lock_fill;
    }

    return GestureDetector(
      onTap: () {
        unawaited(HapticFeedback.lightImpact());
        if (widget.isReadOnly) {
          _showPreviewSheet(room);
        } else {
          _showRoomConfigSheet(room);
        }
      },
      child: Container(
        width: 78,
        height: 94,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: border.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 12, color: textColor),
                Text(
                  '${area}m²',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            Text(
              'P.$shortName',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                priceShort,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomCard({
    required int roomId,
    required String title,
    required String roomCode,
    required String area,
    required String priceText,
    required bool isConfigured,
    required VoidCallback onTap,
    required VoidCallback onPreview,
    String? coverPhoto,
  }) {
    return GestureDetector(
      onTap: widget.isReadOnly ? onPreview : (isConfigured ? null : onTap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isConfigured || widget.isReadOnly)
                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                : const Color(0xFFE5E7EB),
            width: (isConfigured || widget.isReadOnly) ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (isConfigured || widget.isReadOnly)
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            else
              const BoxShadow(
                color: Color(0x06000000),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            // Avatar: photo thumbnail OR icon
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: coverPhoto != null && coverPhoto.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: ImageUrlHelper.buildUrl(coverPhoto) ?? '',
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          _roomIcon(isConfigured || widget.isReadOnly),
                    )
                  : _roomIcon(isConfigured || widget.isReadOnly),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isConfigured && !widget.isReadOnly)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'CẦN THIẾT LẬP',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    roomCode,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _infoChip(CupertinoIcons.square_split_2x1, '$area m²'),
                      const SizedBox(width: 8),
                      // Price chip: green if price > 0, red if not yet set
                      _infoChip(
                        CupertinoIcons.money_dollar_circle,
                        priceText,
                        isPrice: true,
                        configured:
                            priceText != 'Chưa có giá' || widget.isReadOnly,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (widget.isReadOnly)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: onPreview,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Text(
                        'Xem chi tiết',
                        style: TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else if (isConfigured)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Text(
                        'Chỉnh sửa',
                        style: TextStyle(
                          color: Color(0xFF0EA5E9),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onPreview,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Text(
                        'Xem trước',
                        style: TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              const Icon(
                CupertinoIcons.chevron_right,
                size: 18,
                color: Color(0xFF9CA3AF),
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
            ? const Color(0xFF10B981).withValues(alpha: 0.1)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        CupertinoIcons.bed_double_fill,
        color: isConfigured ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
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
        ? (configured ? const Color(0xFF10B981) : const Color(0xFFEF4444))
        : const Color(0xFF6B7280);
    final bg = isPrice
        ? (configured ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2))
        : const Color(0xFFF3F4F6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
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

  void _showPreviewSheet(Map<String, dynamic> room) {
    // Chi nhánh có thể nằm ở branchProvider (đã hoàn tất) HOẶC
    // draftBranchesProvider (đang ở dạng nháp). Trước đây chỉ đọc
    // branchProvider nên với chi nhánh nháp thì `branch == null` ⇒ phần
    // xem trước mất toàn bộ giá dịch vụ, địa chỉ, tên chi nhánh.
    final branches = ref.read(branchProvider).value ?? [];
    final drafts = ref.read(draftBranchesProvider).value ?? [];
    final branchList = [
      ...branches,
      ...drafts,
    ].where((b) => b.id == widget.branchId).toList();
    final branch = branchList.isNotEmpty ? branchList.first : null;

    final previewRoom = Map<String, dynamic>.from(room);

    // ── Chuẩn hoá dữ liệu phòng cho bottom sheet xem trước ──────────────
    // 1. detailedInfo là nguồn của roomType / featurePhotos / furnitureItems /
    //    orientation / maxVehicles / waterPerPersonPrice… — đảm bảo luôn là Map.
    final info = previewRoom['detailedInfo'];
    final Map<String, dynamic> infoMap = info is Map
        ? Map<String, dynamic>.from(info)
        : (() {
            if (info is String && info.trim().startsWith('{')) {
              try {
                final decoded = jsonDecode(info);
                if (decoded is Map) return Map<String, dynamic>.from(decoded);
              } catch (_) {}
            }
            return <String, dynamic>{};
          })();
    previewRoom['detailedInfo'] = infoMap;

    // 2. roomImages từ backend là JSON string → bottom sheet cần List để
    //    hiển thị đúng ảnh phòng (nếu không sẽ rơi vào ảnh placeholder).
    final roomImagesRaw = previewRoom['roomImages'];
    if (roomImagesRaw is String && roomImagesRaw.trim().startsWith('[')) {
      try {
        final decoded = jsonDecode(roomImagesRaw);
        if (decoded is List) previewRoom['roomImages'] = decoded;
      } catch (_) {}
    }

    // 3. Bổ sung các trường phòng nằm trong detailedInfo nhưng bottom sheet
    //    đọc ở root (roomType, maxVehicles, orientation, furnitureItems…).
    infoMap.forEach((k, v) {
      if (previewRoom[k] == null) previewRoom[k] = v;
    });

    // 4. Gắn ngữ cảnh chi nhánh (tên, địa chỉ, chủ nhà, SĐT, giá dịch vụ).
    previewRoom['branchName'] = widget.branchName;
    if (branch != null) {
      Map<String, dynamic> branchJson;
      try {
        branchJson = Map<String, dynamic>.from(branch.toJson());
      } catch (_) {
        branchJson = <String, dynamic>{};
      }
      previewRoom['branch'] = branchJson;
      previewRoom['branchName'] = branchJson['branchName'] ?? widget.branchName;
      previewRoom['branchAddress'] = branchJson['address'];
      previewRoom['ownerId'] = branchJson['ownerId'];
      previewRoom['ownerFullName'] =
          branchJson['ownerName'] ?? branchJson['ownerFullName'];
      previewRoom['ownerPhone'] =
          branchJson['ownerPhone'] ?? branchJson['phone'];
      previewRoom['phone'] = previewRoom['ownerPhone'];
    }

    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => GuestRoomDetailPremiumBottomSheet(
            room: previewRoom,
            scrollController: scrollController,
            isPreview: true,
          ),
        ),
      ),
    );
  }

  Widget _buildFacilitiesTab(List<Map<String, dynamic>> facilities) {
    if (facilities.isEmpty) {
      return const Center(
        child: Text(
          'Không có WC chung nào',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: facilities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final wc = facilities[i];
        // BUGFIX: `id` có thể là String/null → `as int` ném TypeError.
        final wcId = _asInt(wc['id']);

        final isConfigured =
            _configuredFacilityIds.contains(wcId) ||
            wc['equipment'] != null ||
            wc['images'] != null;

        String? firstImage;
        final imgs = wc['images'];
        if (imgs != null) {
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
        }

        final code = wc['notes'] != null && wc['notes'].toString().isNotEmpty
            ? wc['notes'].toString()
            : 'WC-$wcId';
        return _buildConfigCard(
          icon: CupertinoIcons.drop_fill,
          title: wc['name'] ?? 'WC $wcId',
          subtitle: 'Mã: $code',
          isConfigured: isConfigured,
          imageUrl: firstImage,
          onTap: () => _showFacilityConfigSheet(wc),
        );
      },
    );
  }

  Widget _buildConfigCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isConfigured,
    String? imageUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: widget.isReadOnly ? () {} : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isConfigured
                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                : const Color(0xFFE5E7EB),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isConfigured
                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                    : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? ClipOval(
                      child: imageUrl.startsWith('data:image')
                          ? Image.memory(
                              base64Decode(imageUrl.split(',').last),
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Icon(
                                icon,
                                color: isConfigured
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF6B7280),
                                size: 20,
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: ImageUrlHelper.buildUrl(imageUrl) ?? '',
                              fit: BoxFit.cover,
                              errorWidget: (c, e, s) => Icon(
                                icon,
                                color: isConfigured
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF6B7280),
                                size: 20,
                              ),
                            ),
                    )
                  : Icon(
                      icon,
                      color: isConfigured
                          ? const Color(0xFF10B981)
                          : const Color(0xFF6B7280),
                      size: 20,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isConfigured && !widget.isReadOnly)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.check_mark_circled_solid,
                      color: Color(0xFF10B981),
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Đã xong',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.isReadOnly
                    ? const Color(0xFFF3F4F6)
                    : const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                widget.isReadOnly ? 'Xem chi tiết' : 'Chỉnh sửa',
                style: TextStyle(
                  color: widget.isReadOnly
                      ? const Color(0xFF4B5563)
                      : const Color(0xFF0EA5E9),
                  fontSize: 11,
                  fontWeight: widget.isReadOnly
                      ? FontWeight.w600
                      : FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRoomConfigSheet(Map<String, dynamic> room) async {
    final branches = ref.read(branchProvider).value ?? [];
    final drafts = ref.read(draftBranchesProvider).value ?? [];
    final branchList = [
      ...branches,
      ...drafts,
    ].where((b) => b.id == widget.branchId).toList();
    final branch = branchList.isNotEmpty ? branchList.first : null;

    // BUGFIX: `id` có thể là String/null → `as int` ném TypeError.
    final roomId = _asInt(room['id']);
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) => RoomConfigBottomSheet(
        room: room,
        branch: branch,
        defaultPrice: 0,
        allFacilities:
            ref.read(_branchFacilitiesProvider(widget.branchId)).value ?? [],
        allRooms: ref.read(_branchRoomsProvider(widget.branchId)).value ?? [],
        onSaved: (data, progress) async {
          final src = ref.read(branchRemoteDataSourceProvider);
          await src.configureRoom(roomId, data, onSendProgress: progress);
          if (mounted) {
            setState(() => _configuredRoomIds.add(roomId));
            ref.invalidate(_branchRoomsProvider(widget.branchId));
            // Phòng vừa cấu hình → đồng bộ ngay thống kê "Chưa đăng".
            refreshOwnerDashboardFromWidget(ref);
          }
          unawaited(HapticFeedback.lightImpact());
        },
        onApplyMultiple: (data, progress) async {
          if (mounted) Navigator.pop(context);
          _showBulkEditDialog(data, roomId);
        },
      ),
    );

    if (result == 'OPEN_WC_CONFIG' && mounted) {
      final allFacs =
          ref.read(_branchFacilitiesProvider(widget.branchId)).value ?? [];
      final unconfiguredWcs = allFacs
          .where(
            (f) =>
                f['type'] == 'WC' && !_configuredFacilityIds.contains(f['id']),
          )
          .toList();
      final wc = unconfiguredWcs.isNotEmpty
          ? unconfiguredWcs.first
          : allFacs.firstWhere(
              (f) => f['type'] == 'WC',
              orElse: () => <String, dynamic>{},
            );
      if (wc.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _showFacilityConfigSheet(wc);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không có WC chung nào để cấu hình, vui lòng tạo WC trước!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBulkEditDialog(Map<String, dynamic> configData, int sourceRoomId) {
    final roomsAsync = ref.read(_branchRoomsProvider(widget.branchId));
    if (roomsAsync.value == null) return;
    final allRooms = roomsAsync.value!;
    final otherRooms = allRooms.where((r) => r['id'] != sourceRoomId).toList();

    if (otherRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có phòng nào khác để áp dụng')),
      );
      return;
    }

    final selectedRoomIds = <int>{};
    bool isApplying = false;

    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setModalState) {
            return Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Áp dụng cấu hình cho nhiều phòng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Chọn các phòng bạn muốn sao chép cấu hình này',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: otherRooms.length,
                          itemBuilder: (context, i) {
                            final r = otherRooms[i];
                            // BUGFIX: `id` có thể là String/null → `as int`.
                            final rId = _asInt(r['id']);
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
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          color: const Color(0xFF0EA5E9),
                          onPressed: isApplying || selectedRoomIds.isEmpty
                              ? null
                              : () async {
                                  setModalState(() => isApplying = true);
                                  try {
                                    final src = ref.read(
                                      branchRemoteDataSourceProvider,
                                    );
                                    // Apply to source room first
                                    await src.configureRoom(
                                      sourceRoomId,
                                      configData,
                                    );
                                    setState(
                                      () =>
                                          _configuredRoomIds.add(sourceRoomId),
                                    );

                                    // Apply to selected rooms
                                    for (final rId in selectedRoomIds) {
                                      await src.configureRoom(rId, configData);
                                      setState(
                                        () => _configuredRoomIds.add(rId),
                                      );
                                    }
                                    ref.invalidate(
                                      _branchRoomsProvider(widget.branchId),
                                    );
                                    unawaited(HapticFeedback.lightImpact());
                                    if (ctx.mounted) {
                                      Navigator.pop(ctx);
                                    }
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Áp dụng thành công!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text('Lỗi: $e'),
                                        backgroundColor: Colors.red,
                                      ),
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showFacilityConfigSheet(Map<String, dynamic> wc) {
    // BUGFIX: `id` có thể là String/null → `as int` ném TypeError.
    final wcId = _asInt(wc['id']);
    final roomsAsync = ref.read(_branchRoomsProvider(widget.branchId));
    final allRooms = roomsAsync.value ?? [];

    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        builder: (ctx) => FacilityConfigBottomSheet(
          facility: wc,
          allRooms: allRooms,
          onSaved: (data) async {
            final src = ref.read(branchRemoteDataSourceProvider);
            await src.configureFacility(widget.branchId, wcId, data);
            setState(() => _configuredFacilityIds.add(wcId));
            ref.invalidate(_branchFacilitiesProvider(widget.branchId));
            ref.invalidate(_branchRoomsProvider(widget.branchId));
            unawaited(HapticFeedback.lightImpact());
            if (mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
