import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/bounce_click.dart';
import '../../../core/components/premium_empty_state_widget.dart';
import '../application/room_notifier.dart';
import '../data/models/room_model.dart';
import 'dart:async' show unawaited;

final _currencyFmt = NumberFormat.compactCurrency(locale: 'vi_VN', symbol: 'đ');

class RoomGridScreen extends ConsumerStatefulWidget {
  final int ownerId;
  final int? branchId;
  final String branchName;

  const RoomGridScreen({
    super.key,
    required this.ownerId,
    this.branchId,
    required this.branchName,
  });

  @override
  ConsumerState<RoomGridScreen> createState() => _RoomGridScreenState();
}

class _RoomGridScreenState extends ConsumerState<RoomGridScreen> {
  String? _filterStatus;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  static const _allStatuses = [
    'TRONG',
    'DA_THUE',
    'CHO_KICH_HOAT',
    'BAO_TRI',
    'DONG_CUA',
  ];

  static const _statusLabel = {
    'TRONG': 'Trống',
    'DA_THUE': 'Đã thuê',
    'CHO_KICH_HOAT': 'Chờ kích hoạt',
    'BAO_TRI': 'Bảo trì',
    'DONG_CUA': 'Đóng cửa',
  };

  static const _statusColor = {
    'TRONG': CupertinoColors.systemGreen,
    'DA_THUE': CupertinoColors.systemBlue,
    'CHO_KICH_HOAT': AppTheme.kWarning,
    'BAO_TRI': CupertinoColors.systemOrange,
    'DONG_CUA': Color(0xFF4B5563),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRooms());
  }

  void _loadRooms() {
    final notifier = ref.read(roomProvider.notifier);
    if (widget.branchId != null) {
      unawaited(notifier.loadByBranch(widget.branchId!));
    } else {
      unawaited(notifier.loadByOwner(widget.ownerId));
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<RoomModel> _filtered(List<RoomModel> all) {
    return all.where((r) {
      final matchStatus = _filterStatus == null || r.status == _filterStatus;
      final matchQuery =
          _searchQuery.isEmpty ||
          r.roomName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchStatus && matchQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roomProvider);

    return LiquidGlassScaffold(
      title: widget.branchName,
      backgroundColors: AppTheme.kBackgroundLight,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        child: const Icon(
          CupertinoIcons.add_circled_solid,
          color: AppTheme.kAccentColor,
          size: 28,
        ),
        onPressed: () => context.push(
          '/create-room',
          extra: {
            'ownerId': widget.ownerId,
            'branchId': widget.branchId,
            'branchName': widget.branchName,
          },
        ),
      ),
      child: state.when(
        data: (allRooms) {
          final rooms = _filtered(allRooms);
          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  ref.invalidate(roomProvider);
                  try {
                    await ref.read(roomProvider.future);
                  } catch (e, st) {
                    debugPrint('Error: $e\n$st');
                  }
                },
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: CupertinoTextField(
                        controller: _searchCtrl,
                        placeholder: 'Tìm kiếm phòng...',
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Icon(
                            CupertinoIcons.search,
                            color: AppTheme.kTextSecondary,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.kBorderColor),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                        clearButtonMode: OverlayVisibilityMode.editing,
                      ),
                    ),
                    _buildFilterBar(allRooms),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'SƠ ĐỒ PHÒNG (${rooms.length})',
                            style: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                          _buildLegend(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              if (rooms.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _buildPremiumRoomCard(rooms[i]),
                      childCount: rooms.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.only(top: 150),
            child: CupertinoActivityIndicator(
              radius: 16,
              color: AppTheme.kAccentColor,
            ),
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 150),
            child: Column(
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  color: CupertinoColors.systemRed,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Lỗi: $err',
                  style: const TextStyle(color: CupertinoColors.systemRed),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  color: AppTheme.kAccentColor,
                  onPressed: _loadRooms,
                  child: const Text(
                    'Thử lại',
                    style: TextStyle(
                      color: CupertinoColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(List<RoomModel> all) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _filterChip(null, 'Tất cả (${all.length})', CupertinoColors.black),
          ..._allStatuses.map((s) {
            final count = all.where((r) => r.status == s).length;
            return _filterChip(
              s,
              '${_statusLabel[s]} ($count)',
              _statusColor[s]!,
            );
          }),
        ],
      ),
    );
  }

  Widget _filterChip(String? status, String label, Color accentColor) {
    final selected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => setState(() => _filterStatus = status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: selected
                ? accentColor.withValues(alpha: 0.2)
                : CupertinoColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? accentColor.withValues(alpha: 0.5)
                  : CupertinoColors.white,
              width: 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.2),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : [],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected && status != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? accentColor
                      : CupertinoColors.black.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _allStatuses
          .map(
            (s) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _statusColor[s]!,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _statusLabel[s]!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEmptyState() {
    return PremiumEmptyStateWidget(
      title: 'Chưa có phòng nào',
      message:
          'Khu trọ hiện tại chưa có phòng nào. Hãy tạo phòng mới để bắt đầu quản lý.',
      icon: CupertinoIcons.building_2_fill,
      buttonText: 'Thêm Phòng',
      onButtonPressed: () {
        unawaited(
          context.push(
            '/create-room',
            extra: {
              'ownerId': widget.ownerId,
              'branchId': widget.branchId,
              'branchName': widget.branchName,
            },
          ),
        );
      },
    );
  }

  Widget _buildPremiumRoomCard(RoomModel room) {
    final color = _statusColor[room.status] ?? const Color(0xFF4B5563);
    final priceStr = room.price != null
        ? _currencyFmt.format(room.price)
        : 'Chưa có giá';

    return BounceClick(
      onPressed: () => context.push('/room-detail', extra: {'roomId': room.id}),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: CupertinoColors.white,
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Subtle background gradient
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.1),
                        CupertinoColors.white,
                      ],
                    ),
                  ),
                ),
              ),

              // Decorative circle top right
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: 0.2),
                        color.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Icon + Status Dot
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Hero(
                            tag: 'room_icon_${room.id}',
                            child: Icon(
                              room.isDaThue
                                  ? CupertinoIcons.person_solid
                                  : room.isBaoTri
                                  ? CupertinoIcons.wrench_fill
                                  : room.isDongCua
                                  ? CupertinoIcons.lock_fill
                                  : CupertinoIcons.house_alt_fill,
                              color: color,
                              size: 24,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            room.statusLabel,
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Bottom Row: Room Name & Details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.roomName,
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.money_dollar_circle_fill,
                              color: Color(0xFF6B7280),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                priceStr,
                                style: const TextStyle(
                                  color: Color(0xFF374151),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (room.maxGuests != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                CupertinoIcons.person_2_fill,
                                color: Color(0xFF6B7280),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tối đa ${room.maxGuests} người',
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
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
}
