import 'package:flutter/cupertino.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../auth/application/auth_notifier.dart';
import '../../../application/wishlist_provider.dart';
import '../guest_room_detail_premium.dart';
import 'dart:async' show unawaited;

class GuestMapRoomCard extends ConsumerWidget {
  final dynamic room;
  final NumberFormat currencyFmt;
  final bool isMapCard;
  final LatLng mapCenter;

  const GuestMapRoomCard({
    super.key,
    required this.room,
    required this.currencyFmt,
    this.isMapCard = false,
    required this.mapCenter,
  });

  String _extractImage(dynamic roomImages) {
    if (roomImages == null) return '';
    String imgStr = roomImages.toString();
    if (imgStr.isEmpty) return '';
    String firstImg = imgStr.contains(',')
        ? imgStr.split(',')[0].trim()
        : imgStr.trim();
    if (!firstImg.startsWith('http')) {
      if (!firstImg.startsWith('/')) firstImg = '/$firstImg';
      firstImg = '${ApiClient.baseUrl}$firstImg';
    }
    return firstImg;
  }

  String _extractGeneralAddress(String fullAddress) {
    if (fullAddress.isEmpty) return 'Chưa cập nhật địa chỉ';
    final parts = fullAddress.split(',').map((e) => e.trim()).toList();
    if (parts.isNotEmpty) {
      final firstPart = parts.first.toLowerCase();
      if (RegExp(r'\d').hasMatch(firstPart) ||
          firstPart.startsWith('số') ||
          firstPart.startsWith('ngõ') ||
          firstPart.startsWith('ngách') ||
          firstPart.startsWith('hẻm')) {
        parts.removeAt(0);
      }
    }
    return parts.join(', ');
  }

  double _extractPrice(dynamic priceRaw) {
    if (priceRaw == null) return 0.0;
    if (priceRaw is num) return priceRaw.toDouble();
    if (priceRaw is String) return double.tryParse(priceRaw) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.read(authProvider).value;

    final imageUrl = _extractImage(
      room['coverImageUrl'] ??
          room['postImages'] ??
          room['roomImages'] ??
          room['image'],
    );
    final area =
        double.tryParse((room['area'] ?? room['size'] ?? 0).toString()) ?? 0.0;

    String distanceStr = '';
    if (isMapCard && room['latitude'] != null && room['longitude'] != null) {
      try {
        final rLat = double.parse(room['latitude'].toString());
        final rLng = double.parse(room['longitude'].toString());
        final dist = const Distance().as(
          LengthUnit.Meter,
          mapCenter,
          LatLng(rLat, rLng),
        );
        distanceStr =
            ' • Cách ${dist < 1000 ? '${dist.toInt()}m' : '${(dist / 1000).toStringAsFixed(1)}km'}';
      } catch (_) {}
    }

    final roomId = room['id']?.toString() ?? room['roomId']?.toString() ?? '';
    final wishlistState = ref.watch(wishlistProvider);
    final isWishlisted = wishlistState.ids.contains(roomId);

    String statusText = 'SẴN PHÒNG';
    Color statusColor = CupertinoColors.systemGreen;
    final availableFrom = room['availableFrom']?.toString();
    if (availableFrom != null && availableFrom.isNotEmpty) {
      try {
        final date = DateTime.parse(availableFrom);
        final today = DateTime.now();
        final dateOnly = DateTime(date.year, date.month, date.day);
        final todayOnly = DateTime(today.year, today.month, today.day);
        if (dateOnly.isAfter(todayOnly)) {
          statusText =
              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
          statusColor = CupertinoColors.systemOrange;
        }
      } catch (_) {}
    }

    String? badge;
    Color badgeColor = CupertinoColors.systemGreen;
    final createdAt = room['createdAt']?.toString() ?? '';
    if (createdAt.isNotEmpty) {
      try {
        final created = DateTime.parse(createdAt);
        final diff = DateTime.now().difference(created);
        if (diff.inHours < 24) {
          badge = '🆕 Mới đăng';
          badgeColor = CupertinoColors.systemBlue;
        } else if (diff.inDays < 3) {
          badge = '🔥 Hot';
          badgeColor = CupertinoColors.systemOrange;
        }
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () {
        // BUGFIX: `room` là `dynamic`; nếu không phải Map (JSON lỗi) thì
        // `room as Map` ném TypeError. Guard bằng `is Map` trước khi mở sheet.
        if (room is! Map) return;
        unawaited(
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useRootNavigator: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            builder: (context) => DraggableScrollableSheet(
              initialChildSize: 0.95,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) =>
                  GuestRoomDetailPremiumBottomSheet(
                    // BUGFIX (data): guard `room is Map` trước khi ép kiểu để
                    // tránh TypeError khi dữ liệu JSON lỗi (không phải Map).
                    room: room is Map
                        ? Map<String, dynamic>.from(room)
                        : <String, dynamic>{},
                    scrollController: scrollController,
                  ),
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isMapCard ? 0 : 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.kSurface1Light,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.kTextSecondary.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'room_image_$roomId',
                  child: Container(
                    width: isMapCard ? 110 : 90,
                    height: isMapCard ? 110 : 90,
                    decoration: BoxDecoration(
                      color: imageUrl.isEmpty ? AppTheme.kBorderColor : null,
                      gradient: imageUrl.isEmpty
                          ? const LinearGradient(
                              colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      image: imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: imageUrl.isEmpty
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.photo,
                                color: Color(0xFF94A3B8),
                                size: 24,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Chưa có ảnh',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          room['postTitle'] != null &&
                                  room['postTitle'].toString().isNotEmpty
                              ? room['postTitle']
                              : 'Phòng ${room['roomName'] ?? room['name'] ?? 'Trống'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (authUser != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            // BUGFIX: guard `room is Map` trước khi ép kiểu để
                            // tránh TypeError khi dữ liệu JSON lỗi.
                            if (room is! Map) return;
                            final wasLiked = wishlistState.ids.contains(roomId);
                            if (wasLiked) {
                              unawaited(HapticFeedback.mediumImpact());
                            } else {
                              unawaited(HapticFeedback.lightImpact());
                            }
                            await ref
                                .read(wishlistProvider.notifier)
                                .toggle(Map<String, dynamic>.from(room as Map));
                          },
                          child: Icon(
                            isWishlisted
                                ? CupertinoIcons.heart_fill
                                : CupertinoIcons.heart,
                            color: isWishlisted
                                ? CupertinoColors.systemRed
                                : AppTheme.kTextSecondary,
                            size: 20,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (badge != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    currencyFmt.format(_extractPrice(room['price'])),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppTheme.kAccentColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (area > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        'DT: ${area.toInt()} m²',
                        style: const TextStyle(
                          color: AppTheme.kTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.person_crop_circle,
                          size: 12,
                          color: AppTheme.kTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        // BUGFIX (data): `room['ownerName']` là dynamic; nếu
                        // không phải String (JSON lỗi) thì `Text` ném lỗi build.
                        // Ép về String an toàn.
                        Text(
                          (room['ownerName'] ?? 'Đối tác StayHub').toString(),
                          style: const TextStyle(
                            color: AppTheme.kTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          color: CupertinoColors.activeBlue,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.location_solid,
                        size: 12,
                        color: AppTheme.kTextSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          // BUGFIX (data): `room['address']`/`room['region']` là
                          // dynamic; nếu JSON trả về số/object thì phép `+` với
                          // `distanceStr` (String) ném TypeError. Ép về String an
                          // toàn trước khi nối.
                          (authUser != null
                                  ? (room['address'] ??
                                            room['region'] ??
                                            'Chưa cập nhật địa chỉ')
                                        .toString()
                                  : _extractGeneralAddress(
                                      room['address'] ?? room['region'] ?? '',
                                    )) +
                              distanceStr,
                          style: TextStyle(
                            color: authUser != null
                                ? AppTheme.kTextSecondary
                                : AppTheme.kAccentColor,
                            fontSize: 12,
                            fontWeight: authUser != null
                                ? FontWeight.normal
                                : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
