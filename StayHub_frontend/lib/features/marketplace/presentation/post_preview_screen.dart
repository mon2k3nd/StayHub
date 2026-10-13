// Trigger IDE refresh
import 'dart:io';
import 'dart:convert';
import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/toast_utils.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/dashboard_refresh.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/marketplace_notifier.dart';
import '../../room/application/public_rooms_provider.dart';
import '../../notification/data/notification_provider.dart';
import 'widgets/guest_feed_view.dart';
import 'dart:async' show unawaited;

class PostPreviewScreen extends ConsumerStatefulWidget {
  final dynamic room;
  final Map<String, dynamic> post;
  final List<dynamic>? previewImages;
  final dynamic branch; // branch object — source of service prices
  final String? branchAddress;

  const PostPreviewScreen({
    super.key,
    required this.room,
    required this.post,
    this.previewImages,
    this.branch,
    this.branchAddress,
  });

  @override
  ConsumerState<PostPreviewScreen> createState() => _PostPreviewScreenState();
}

class _PostPreviewScreenState extends ConsumerState<PostPreviewScreen> {
  bool _isLoading = false;

  Future<void> _publishPost() async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);

      final List<String> finalImages = [];

      if (widget.previewImages != null && widget.previewImages!.isNotEmpty) {
        // Build final images strictly from previewImages to preserve rearranged order
        for (var item in widget.previewImages!) {
          if (item is File) {
            // Mock upload
            finalImages.add(
              'uploaded_mock_url_${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
          } else {
            finalImages.add(item.toString());
          }
        }
      } else {
        // Fallback to post's existing images if no previewImages provided
        final String? cover = widget.post['coverImageUrl'];
        if (cover != null && cover.isNotEmpty) {
          finalImages.add(cover);
        }
        final String? orderStr = widget.post['postImages'];
        if (orderStr != null && orderStr.isNotEmpty) {
          finalImages.addAll(orderStr.split(',').where((s) => s.isNotEmpty));
        }
      }

      final r = widget.room is Map ? widget.room : widget.room.toJson();
      final roomId = r['id'];

      if (finalImages.isNotEmpty) {
        r['roomImages'] = finalImages.join(',');
      }

      final Map<String, dynamic> body = Map<String, dynamic>.from(widget.post);

      body.addAll({
        "roomId": roomId,
        "postTitle": widget.post['postTitle'],
        "postDescription": widget.post['postDescription'],
        "rentingPrice": widget.post['rentingPrice'] ?? widget.room['price'],
        "deposit": widget.post['deposit'] ?? widget.room['deposit'],
        "status": widget.post['status'] ?? "ACTIVE",
        "hasPromotion":
            widget.post['hasPromotion'] ?? widget.room['hasPromotion'] ?? false,
        "discountType": widget.post['discountType'],
        "discountAmount": widget.post['discountAmount'],
        "promotionMonths": widget.post['promotionMonths'],
        "promotionDescription": widget.post['promotionDescription'],
        "coverImageUrl": finalImages.isNotEmpty ? finalImages.first : null,
        "postImages": finalImages.length > 1
            ? finalImages.skip(1).join(',')
            : null,
      });

      // IMPORTANT: Cập nhật lại các thông tin của Phòng (ví dụ: giá, tiền cọc) vào DB trước khi tạo Post
      await dio.put('/v1/rooms/$roomId', data: r);

      if (widget.post['id'] != null) {
        await dio.put('/v1/room-posts/${widget.post['id']}', data: body);
      } else {
        await dio.post('/v1/room-posts/room/$roomId', data: body);
      }

      if (mounted) {
        ToastUtils.show(
          context,
          widget.post['id'] != null
              ? 'Cập nhật tin thành công!'
              : 'Đăng tin thành công!',
          isError: false,
        );
      }

      // unawaited(PUSH SYSTEM NOTIFICATION)
      unawaited(
        ref.read(notificationActionProvider).pushSystemNotification({
          "title": widget.post['id'] != null
              ? "✅ Cập nhật bài thành công!"
              : "✅ Đăng bài hoàn tất!",
          "content": widget.post['id'] != null
              ? "Bài đăng phòng ${widget.post['title'] ?? widget.post['postTitle'] ?? ''} đã được cập nhật thành công."
              : "Phòng ${widget.post['title'] ?? widget.post['postTitle'] ?? ''} đã được đăng lên Marketplace. Mọi người có thể nhìn thấy phòng của bạn ngay từ bây giờ.",
          "type": "SYSTEM_ALERT",
          "actionMetadata": jsonEncode({
            "actionUrl": "/owner-dashboard/post-management",
            "actionLabel": "Xem bài đăng",
          }),
        }),
      );

      // Làm mới dashboard chủ trọ (ô "Chưa đăng" phải giảm NGAY sau khi đăng bài)
      // + các feed công khai. Dùng helper tập trung để không bỏ sót provider nào.
      refreshOwnerDashboardFromWidget(ref);
      ref.invalidate(marketplacePostsProvider);
      ref.invalidate(publicRoomsProvider);

      if (mounted) {
        context.pop(); // Pop preview
        context.pop(); // Pop edit screen
      }
    } catch (e) {
      if (mounted) ToastUtils.show(context, 'Lỗi: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Combine room and post data into a single object for GuestFeedItem
    final rawRoom = widget.room is Map ? widget.room : widget.room.toJson();
    final mockRoomData = <String, dynamic>{};
    // BUGFIX (data): tránh `as Map` ném TypeError nếu `toJson()` trả về
    // non-Map — chỉ duyệt khi thực sự là Map.
    if (rawRoom is Map) {
      rawRoom.forEach((k, v) => mockRoomData[k.toString()] = v);
    }

    // ── Normalize `detailedInfo` (Map hoặc JSON string) và merge lên root ──
    // Toàn bộ cấu hình phòng ở 5 bước tạo chi nhánh nằm trong `detailedInfo`.
    dynamic di = mockRoomData['detailedInfo'];
    if (di is String && di.trim().startsWith('{')) {
      try {
        di = jsonDecode(di);
      } catch (_) {
        di = null;
      }
    }
    if (di is Map) {
      final info = <String, dynamic>{};
      di.forEach((k, v) => info[k.toString()] = v);
      mockRoomData['detailedInfo'] = info;
      // Merge lên root để các widget đọc trực tiếp (không phá giá trị đã có).
      info.forEach((k, v) {
        if (v == null) return;
        final existing = mockRoomData[k];
        if (existing == null || (existing is String && existing.isEmpty)) {
          mockRoomData[k] = v;
        }
      });
    }

    // ── Normalize `roomImages` (List hoặc JSON string) ──
    final ri = mockRoomData['roomImages'];
    if (ri is String && ri.trim().startsWith('[')) {
      try {
        mockRoomData['roomImages'] = jsonDecode(ri);
      } catch (_) {}
    }

    mockRoomData['title'] =
        widget.post['postTitle'] ?? mockRoomData['roomName'];
    mockRoomData['description'] =
        widget.post['postDescription'] ?? mockRoomData['description'];
    mockRoomData['hasPromotion'] = widget.post['hasPromotion'] ?? false;
    mockRoomData['promotionPrice'] = widget.post['promotionPrice'];
    mockRoomData['price'] =
        widget.post['rentingPrice'] ??
        widget.post['price'] ??
        mockRoomData['price'];
    mockRoomData['originalPrice'] =
        widget.post['originalPrice'] ?? mockRoomData['price'];
    mockRoomData['address'] = widget.branchAddress ?? mockRoomData['address'];

    // Inject branch-level service prices so the preview shows the real values.
    final b = widget.branch;
    if (b != null) {
      dynamic bf(String key, String? alias) {
        if (b is! Map) {
          try {
            switch (key) {
              case 'electricityPrice':
                return b.electricityPrice;
              case 'waterPrice':
                return b.waterPrice;
              case 'serviceFee':
                return b.serviceFee;
              case 'internetPrice':
                return b.internetPrice;
              case 'parkingPrice':
                return b.parkingPrice;
              case 'trashPrice':
                return b.trashPrice;
              case 'waterPricingType':
                return b.waterPricingType;
            }
          } catch (_) {}
        }
        final m = b is Map
            ? b
            : (() {
                try {
                  return b.toJson() as Map;
                } catch (_) {
                  return const {};
                }
              })();
        return m[key] ?? (alias != null ? m[alias] : null);
      }

      mockRoomData['electricityPrice'] =
          bf('electricityPrice', null) ?? mockRoomData['electricityPrice'];
      mockRoomData['waterPrice'] =
          bf('waterPrice', null) ?? mockRoomData['waterPrice'];
      mockRoomData['serviceFee'] =
          bf('serviceFee', null) ?? mockRoomData['serviceFee'];
      mockRoomData['internetPrice'] =
          bf('internetPrice', 'internetFee') ?? mockRoomData['internetPrice'];
      mockRoomData['parkingPrice'] =
          bf('parkingPrice', 'parkingFee') ?? mockRoomData['parkingPrice'];
      mockRoomData['trashPrice'] =
          bf('trashPrice', 'garbageFee') ?? mockRoomData['trashPrice'];
      mockRoomData['waterPricingType'] =
          bf('waterPricingType', null) ?? mockRoomData['waterPricingType'];

      // ── Tên chi nhánh + tiện ích chung toà nhà (bước 2 tạo chi nhánh) ──
      final bm = b is Map
          ? b
          : (() {
              try {
                return b.toJson() as Map;
              } catch (_) {
                return const {};
              }
            })();
      final bName = (bm['branchName'] ?? bm['name'] ?? '').toString().trim();
      if (bName.isNotEmpty) mockRoomData['branchName'] = bName;

      // ── Toạ độ toà nhà → dùng cho "Tiện ích xung quanh" (POI) ──
      // BUGFIX: nếu phòng chưa gắn lat/lng, lấy toạ độ chi nhánh để POI hiển thị
      // giống hệt trang đã đăng (tránh preview đúng – published sai).
      final bLat = bm['latitude'] ?? bm['branchLatitude'];
      final bLng = bm['longitude'] ?? bm['branchLongitude'];
      if (mockRoomData['latitude'] == null && bLat != null) {
        mockRoomData['latitude'] = bLat;
      }
      if (mockRoomData['longitude'] == null && bLng != null) {
        mockRoomData['longitude'] = bLng;
      }
      if (bLat != null) mockRoomData['branchLatitude'] = bLat;
      if (bLng != null) mockRoomData['branchLongitude'] = bLng;

      List<dynamic>? bAmenities;
      final direct = bm['branchAmenities'];
      if (direct is List) {
        bAmenities = direct;
      } else {
        final desc = bm['description'];
        dynamic decoded = desc;
        if (desc is String && desc.trim().startsWith('{')) {
          try {
            decoded = jsonDecode(desc);
          } catch (_) {
            decoded = null;
          }
        }
        if (decoded is Map && decoded['branchAmenities'] is List) {
          bAmenities = decoded['branchAmenities'] as List;
        }
      }
      if (bAmenities != null && bAmenities.isNotEmpty) {
        mockRoomData['branchAmenities'] = bAmenities;
        // Gộp tên tiện ích chung vào danh sách tiện ích hiển thị.
        final merged = <dynamic>[];
        final existing = mockRoomData['amenities'];
        if (existing is List) merged.addAll(existing);
        for (final a in bAmenities) {
          if (a is Map) {
            final n = (a['name'] ?? '').toString().trim();
            if (n.isNotEmpty && !merged.contains(n)) merged.add(n);
          }
        }
        if (merged.isNotEmpty) mockRoomData['amenities'] = merged;
      }
    }

    final String? previewCover = widget.post['coverImageUrl'];
    final String? previewImages = widget.post['postImages'];
    if (previewCover != null || previewImages != null) {
      mockRoomData['roomImages'] = [
        if (previewCover != null && previewCover.isNotEmpty) previewCover,
        if (previewImages != null && previewImages.isNotEmpty) previewImages,
      ].join(',');
    }

    // Inject owner info for preview
    final user = ref.watch(authProvider).value;
    if (user != null) {
      mockRoomData['ownerAvatar'] = user.avatar ?? '';
      mockRoomData['ownerName'] = user.fullName;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Feed Item View
          GuestFeedItem(
            isGuest: true,
            isKycVerified: true,
            room: mockRoomData,
            currencyFmt: NumberFormat.currency(
              locale: 'vi_VN',
              symbol: 'đ',
              decimalDigits: 0,
            ),
            isLiked: false,
            bottomInset: 120, // Add padding at bottom for buttons
            onLike: () {},
            onAction: () {},
            previewImages: widget.previewImages,
            isPreview: true, // Enable preview mode
          ),

          // Top Back Button (SafeArea)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          // Bottom Action Buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16,
                24,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black,
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Edit Button
                  Expanded(
                    flex: 1,
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      onPressed: _isLoading ? null : () => context.pop(),
                      child: const Text(
                        'Chỉnh sửa',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Publish Button (Sky Blue Gradient)
                  Expanded(
                    flex: 2,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.kBrandLight,
                            AppTheme.kBrandDeep,
                          ], // Sky Blue
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.kBrand.withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        onPressed: _isLoading ? null : _publishPost,
                        child: _isLoading
                            ? const CupertinoActivityIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                widget.post['id'] != null
                                    ? 'Cập nhật ngay'
                                    : 'Đăng bài ngay',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
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
}
