import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/viewed_history_service.dart';
import '../../../core/services/wishlist_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/bounce_click.dart';
import '../../../core/components/safe_network_image.dart';
import '../../../core/components/premium_empty_state_widget.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Màn hình "Phòng đã xem" (Guest Mode — lưu cục bộ).
class ViewedHistoryScreen extends StatefulWidget {
  const ViewedHistoryScreen({super.key});

  @override
  State<ViewedHistoryScreen> createState() => _ViewedHistoryScreenState();
}

class _ViewedHistoryScreenState extends State<ViewedHistoryScreen> {
  List<Map<String, dynamic>> _rooms = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await ViewedHistoryService.getHistory();
    if (!mounted) return;
    setState(() {
      _rooms = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _loading = false;
    });
  }

  Future<void> _clear() async {
    await ViewedHistoryService.clearHistory();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return _RoomListScaffold(
      title: 'Phòng đã xem',
      loading: _loading,
      rooms: _rooms,
      emptyIcon: Icons.history_rounded,
      emptyTitle: 'Chưa xem phòng nào',
      emptySubtitle: 'Các phòng bạn xem gần đây sẽ xuất hiện ở đây.',
      onClear: _rooms.isEmpty ? null : _clear,
      onRefresh: _load,
    );
  }
}

/// Màn hình "Phòng đã lưu" (Guest Mode — lưu cục bộ).
class SavedRoomsScreen extends StatefulWidget {
  const SavedRoomsScreen({super.key});

  @override
  State<SavedRoomsScreen> createState() => _SavedRoomsScreenState();
}

class _SavedRoomsScreenState extends State<SavedRoomsScreen> {
  List<Map<String, dynamic>> _rooms = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rooms = await WishlistService.loadLocal();
    if (!mounted) return;
    setState(() {
      _rooms = rooms;
      _loading = false;
    });
  }

  Future<void> _clear() async {
    await WishlistService.clearWishlist(null);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return _RoomListScaffold(
      title: 'Phòng đã lưu',
      loading: _loading,
      rooms: _rooms,
      emptyIcon: Icons.favorite_rounded,
      emptyTitle: 'Chưa lưu phòng nào',
      emptySubtitle: 'Nhấn ♥ ở trang chi tiết phòng để lưu lại.',
      onClear: _rooms.isEmpty ? null : _clear,
      onRefresh: _load,
    );
  }
}

/// Scaffold dùng chung cho danh sách phòng (đã xem / đã lưu).
class _RoomListScaffold extends StatelessWidget {
  final String title;
  final bool loading;
  final List<Map<String, dynamic>> rooms;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final Future<void> Function()? onClear;
  final Future<void> Function() onRefresh;

  const _RoomListScaffold({
    required this.title,
    required this.loading,
    required this.rooms,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onClear,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      background: Container(color: AppTheme.kBackgroundLight),
      appBar: GlassAppBar(
        leading: GlassIconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        actions: [
          if (onClear != null)
            TextButton(
              onPressed: onClear,
              child: const Text(
                'Xoá hết',
                style: TextStyle(
                  color: AppTheme.kError,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.kBrand),
            )
          : rooms.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              color: AppTheme.kBrand,
              onRefresh: onRefresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: rooms.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _RoomTile(room: rooms[i]),
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return PremiumEmptyStateWidget(
      icon: emptyIcon,
      title: emptyTitle,
      message: emptySubtitle,
    );
  }
}

class _RoomTile extends StatelessWidget {
  final Map<String, dynamic> room;

  const _RoomTile({required this.room});

  @override
  Widget build(BuildContext context) {
    final id = room['id'] ?? room['roomId'];
    final title = (room['title'] ?? room['name'] ?? room['roomName'] ?? 'Phòng')
        .toString();
    final img = (room['firstImage'] ?? room['coverImageUrl'] ?? '').toString();
    final price = _num(room['price']);
    final area = _num(room['floorArea'] ?? room['area']);
    final address = (room['address'] ?? '').toString();

    return BounceClick(
      onPressed: () {
        // BUGFIX (không xem chi tiết phòng được): trước đây `int.tryParse`
        // có thể trả null (id không phải số) → route nhận null → màn TRẮNG
        // im lặng. Nay parse khoan dung và báo cho người dùng khi ID hỏng.
        final int? roomId = id is int ? id : int.tryParse(id?.toString() ?? '');
        if (roomId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không mở được chi tiết phòng này')),
          );
          return;
        }
        context.push('/guest-room-detail', extra: {'roomId': roomId});
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.kSurface1Light,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.kPremiumShadowLight,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SafeNetworkImage(
                url: img,
                width: 84,
                height: 84,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (address.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 13,
                          color: AppTheme.kBrand,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.kTextMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        price > 0 ? '${_formatPrice(price)} ₫' : '—',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.kBrand,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (area > 0)
                        Text(
                          '• ${area.toInt()} m²',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.kTextMuted,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.kTextMuted),
          ],
        ),
      ),
    );
  }

  static double _num(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0;
  }

  static String _formatPrice(double value) {
    if (value <= 0) return '—';
    final s = value.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
