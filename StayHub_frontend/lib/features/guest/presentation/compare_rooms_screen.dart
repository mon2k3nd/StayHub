import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Theme;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/components/bounce_click.dart';
import '../../../core/components/premium_empty_state_widget.dart';
import '../../../core/components/safe_network_image.dart';
import '../../../core/constants/room_type_codes.dart';
import '../../../core/services/compare_service.dart';
import '../../../core/theme/app_theme.dart';

/// Màn hình so sánh đối đầu 2-3 phòng song song (Top-tier PropTech Comparison).
/// Thiết kế Liquid Glass, nhận diện Sky Blue và highlight phòng tốt nhất.
class CompareRoomsScreen extends StatefulWidget {
  const CompareRoomsScreen({super.key});

  @override
  State<CompareRoomsScreen> createState() => _CompareRoomsScreenState();
}

class _CompareRoomsScreenState extends State<CompareRoomsScreen> {
  List<Map<String, dynamic>> _rooms = [];
  bool _loading = true;
  final _currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rooms = await CompareService.getRooms();
    if (!mounted) return;
    setState(() {
      _rooms = rooms;
      _loading = false;
    });
  }

  Future<void> _remove(String id) async {
    await CompareService.remove(id);
    await _load();
  }

  Future<void> _clearAll() async {
    await CompareService.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassScaffold(
      background: Container(
        color: isDark ? const Color(0xFF0F172A) : AppTheme.kBackgroundLight,
      ),
      appBar: GlassAppBar(
        leading: GlassIconButton(
          icon: const Icon(CupertinoIcons.back, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'So Sánh Đối Đầu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (_rooms.isNotEmpty)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _clearAll,
              child: const Text(
                'Xoá hết',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 16,
                color: Color(0xFF2563EB),
              ),
            )
          : _rooms.isEmpty
              ? _buildEmpty()
              : _buildCompareTable(isDark),
    );
  }

  Widget _buildEmpty() {
    return const PremiumEmptyStateWidget(
      icon: CupertinoIcons.arrow_right_arrow_left,
      title: 'Chưa có phòng để so sánh',
      message:
          'Chọn 2 đến 3 phòng từ Danh sách yêu thích để đối đầu giá thuê, diện tích và tiện ích thực tế.',
    );
  }

  Widget _buildCompareTable(bool isDark) {
    final prices = _rooms
        .map((r) => _num(r['price']))
        .where((v) => v > 0)
        .toList();
    final areas = _rooms
        .map((r) => _num(r['floorArea']))
        .where((v) => v > 0)
        .toList();
    final minPrice = prices.isEmpty ? null : prices.reduce((a, b) => a < b ? a : b);
    final maxArea = areas.isEmpty ? null : areas.reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Tóm Tắt Đối Đầu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.sparkles,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Đang đối đầu ${_rooms.length} phòng được chọn • 👑 Đánh dấu tiêu chí tốt nhất',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Hàng thẻ phòng
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _rooms
                .map((r) => Expanded(child: _buildRoomCard(r, isDark)))
                .toList(),
          ),

          const SizedBox(height: 24),

          // 1. CHI PHÍ & TÀI CHÍNH
          _buildSectionTitle('Chi Phí & Tài Chính', isDark),
          _buildRow(
            'Giá thuê / tháng',
            (r) {
              final v = _num(r['price']);
              return v > 0 ? _currencyFmt.format(v) : '—';
            },
            highlight: (r) {
              final v = _num(r['price']);
              return minPrice != null && v > 0 && v == minPrice;
            },
            badgeText: 'Giá rẻ nhất 👑',
            isDark: isDark,
          ),
          _buildRow(
            'Tiền cọc phòng',
            (r) {
              final dep = _num(r['deposit'] ?? r['depositAmount']);
              return dep > 0 ? _currencyFmt.format(dep) : 'Cọc 1 tháng (Có bảo lãnh 0đ)';
            },
            isDark: isDark,
          ),
          _buildRow(
            'Điện & Nước',
            (r) {
              final elec = r['electricityPrice'] ?? r['electricPrice'] ?? '3.5k/kWh';
              final water = r['waterPrice'] ?? '100k/người';
              return 'Điện: $elec\nNước: $water';
            },
            multiline: true,
            isDark: isDark,
          ),

          const SizedBox(height: 20),

          // 2. KHÔNG GIAN & KẾT CẤU
          _buildSectionTitle('Không Gian & Kết Cấu', isDark),
          _buildRow(
            'Diện tích sử dụng',
            (r) {
              final v = _num(r['floorArea']);
              return v > 0 ? '${v.toInt()} m²' : '—';
            },
            highlight: (r) {
              final v = _num(r['floorArea']);
              return maxArea != null && v > 0 && v == maxArea;
            },
            badgeText: 'Rộng nhất 👑',
            isDark: isDark,
          ),
          _buildRow(
            'Loại phòng',
            (r) {
              final label = RoomTypeCodes.labelOf(r['roomType']?.toString());
              return label.isNotEmpty ? label : 'Phòng trọ';
            },
            isDark: isDark,
          ),
          _buildRow(
            'Phòng ngủ & WC',
            (r) {
              final beds = _num(r['bedrooms']).toInt();
              final baths = _num(r['bathrooms']).toInt();
              return '${beds > 0 ? '$beds PN' : '1 PN'} • ${baths > 0 ? '$baths WC' : 'WC riêng'}';
            },
            isDark: isDark,
          ),
          _buildRow(
            'Vị trí tầng',
            (r) {
              final v = _num(r['floor']);
              return v > 0 ? 'Tầng ${v.toInt()}' : 'Tầng trệt / Lửng';
            },
            isDark: isDark,
          ),

          const SizedBox(height: 20),

          // 3. TIỆN ÍCH NỔI BẬT
          _buildSectionTitle('Tiện Ích & Quy Định', isDark),
          _buildRow(
            'Máy lạnh & Máy giặt',
            (r) => _hasFeature(r, ['máy lạnh', 'điều hòa']) ? '✓ Có máy lạnh' : 'Chưa có',
            isDark: isDark,
          ),
          _buildRow(
            'Ban công / Cửa sổ',
            (r) => _hasFeature(r, ['ban công', 'cửa sổ']) ? '✓ Ban công thoáng' : 'Cửa sổ thường',
            isDark: isDark,
          ),
          _buildRow(
            'Giờ giấc tự do',
            (r) => _hasFeature(r, ['tự do', '24/7', 'khóa vân tay']) ? '✓ 24/7 Tự do' : 'Có giờ đóng cửa',
            isDark: isDark,
          ),
          _buildRow(
            'Nuôi thú cưng',
            (r) => _hasFeature(r, ['thú cưng', 'chó mèo', 'pet']) ? '✓ Cho nuôi pet' : 'Không cho nuôi',
            isDark: isDark,
          ),

          const SizedBox(height: 20),

          // 4. ĐỊA CHỈ & VỊ TRÍ
          _buildSectionTitle('Vị Trí Thực Tế', isDark),
          _buildRow(
            'Địa chỉ phòng',
            (r) => (r['address'] ?? 'Đang cập nhật').toString(),
            multiline: true,
            isDark: isDark,
          ),

          const SizedBox(height: 28),

          // Nút thêm phòng nếu còn chỗ
          if (_rooms.length < CompareService.maxItems)
            BounceClick(
              scaleFactor: 0.96,
              onPressed: () => context.pop(),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: const Color(0xFF69B1FF).withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.plus_circle_fill,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Thêm phòng khác để so sánh',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _hasFeature(Map<String, dynamic> room, List<String> keywords) {
    final text = '${room['tags']} ${room['amenities']} ${room['description']} ${room['title']}'.toLowerCase();
    return keywords.any((k) => text.contains(k));
  }

  Widget _buildRoomCard(Map<String, dynamic> room, bool isDark) {
    final id = (room['id'] ?? room['roomId'] ?? '').toString();
    final img = (room['firstImage'] ?? room['coverImage'] ?? room['image'] ?? '').toString();
    final title = (room['title'] ?? 'Phòng').toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF69B1FF).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF69B1FF).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SafeNetworkImage(
                  url: img,
                  width: double.infinity,
                  height: 96,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: BounceClick(
                  scaleFactor: 0.85,
                  onPressed: () => _remove(id),
                  child: Container(
                    padding: const EdgeInsets.all(4.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          // Nút Xem Phòng
          BounceClick(
            scaleFactor: 0.92,
            onPressed: () {
              if (id.isNotEmpty) {
                context.push('/guest/room/$id');
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF69B1FF), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Center(
                child: Text(
                  'Xem phòng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String Function(Map<String, dynamic>) valueOf, {
    bool Function(Map<String, dynamic>)? highlight,
    String? badgeText,
    bool multiline = false,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFF69B1FF).withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _rooms.map((r) {
              final isBest = highlight?.call(r) ?? false;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isBest && badgeText != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                      Text(
                        valueOf(r),
                        maxLines: multiline ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isBest ? FontWeight.w800 : FontWeight.w600,
                          color: isBest
                              ? const Color(0xFF2563EB)
                              : (isDark ? Colors.white : const Color(0xFF1E293B)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static double _num(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0;
  }
}
