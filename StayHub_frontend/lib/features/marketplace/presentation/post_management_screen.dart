import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/toast_utils.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../core/utils/time_utils.dart';

import '../../../core/components/liquid_glass_scaffold.dart';
import 'dart:convert';
import '../../../core/components/premium_card.dart';
import '../../../core/providers/dashboard_refresh.dart';
import '../../room/application/room_notifier.dart';
import '../application/owner_posts_provider.dart';
import '../../branch/application/branch_notifier.dart';
import 'dart:async' show unawaited;

class PostManagementScreen extends ConsumerStatefulWidget {
  const PostManagementScreen({super.key});

  @override
  ConsumerState<PostManagementScreen> createState() =>
      _PostManagementScreenState();
}

class _PostManagementScreenState extends ConsumerState<PostManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// BUGFIX (data): coerce an toàn sang num — tránh `as num` ném TypeError
  /// khi backend trả String ("3000000") hoặc giá trị không phải số.
  num _asNum(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw;
    return num.tryParse(raw.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchProvider);
    final roomsAsync = ref.watch(allOwnerRoomsProvider);
    final postsAsync = ref.watch(ownerPostsProvider);

    final isLoading =
        (branchesAsync.isLoading && !branchesAsync.hasValue) ||
        (roomsAsync.isLoading && !roomsAsync.hasValue) ||
        (postsAsync.isLoading && !postsAsync.hasValue);

    final isRefreshing =
        branchesAsync.isRefreshing ||
        roomsAsync.isRefreshing ||
        postsAsync.isRefreshing;
    final hasError =
        branchesAsync.hasError || roomsAsync.hasError || postsAsync.hasError;

    return LiquidGlassScaffold(
      title: 'Quản Lý Bài Đăng',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: false,
      child: Column(
        children: [
          // Tab Bar
          Container(
            color: CupertinoColors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.kBrand,
              unselectedLabelColor: AppTheme.kTextSecondary,
              indicatorColor: AppTheme.kBrand,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Chưa đăng'),
                Tab(text: 'Đang hiển thị'),
                Tab(text: 'Đã ẩn/Nháp'),
              ],
            ),
          ),
          // Divider
          Container(height: 1, color: const Color(0xFFE5E7EB)),

          Expanded(
            child: isLoading && !isRefreshing
                ? const Center(child: CupertinoActivityIndicator(radius: 16))
                : hasError && (!branchesAsync.hasValue && !roomsAsync.hasValue)
                ? const Center(child: Text('Đã xảy ra lỗi tải dữ liệu.'))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUnpostedTab(
                        branchesAsync.value ?? [],
                        roomsAsync.value ?? [],
                        postsAsync.value ?? [],
                      ),
                      _buildActivePostsTab(
                        branchesAsync.value ?? [],
                        roomsAsync.value ?? [],
                        postsAsync.value ?? [],
                      ),
                      _buildHiddenPostsTab(
                        branchesAsync.value ?? [],
                        roomsAsync.value ?? [],
                        postsAsync.value ?? [],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  dynamic _getPostForRoom(dynamic room, List<dynamic> posts) {
    final roomId = room.id?.toString();
    return posts.firstWhere(
      (p) => p['roomId']?.toString() == roomId,
      orElse: () => null,
    );
  }

  Widget _buildUnpostedTab(
    List<dynamic> branches,
    List<dynamic> allRooms,
    List<dynamic> posts,
  ) {
    // BUGFIX: trước đây liệt kê MỌI phòng chưa có tin — kể cả phòng đã thuê
    // (DA_THUE) / đóng cửa (DONG_CUA) / bảo trì. Những phòng đó KHÔNG được
    // phép đăng marketplace (backend chỉ nhận phòng TRONG/SAP_TRONG), nên
    // hiển thị chúng ở tab "Chưa đăng" là sai và bấm "Đăng tin ngay" sẽ lỗi.
    // Chỉ giữ phòng có thể đăng: TRONG hoặc SAP_TRONG.
    final unpostedRooms = allRooms.where((r) {
      final status = (r.status ?? '').toString();
      final postable = status == 'TRONG' || status == 'SAP_TRONG';
      return postable && _getPostForRoom(r, posts) == null;
    }).toList();

    if (unpostedRooms.isEmpty) {
      return _buildEmptyState(
        'Không có phòng cần đăng',
        'Tuyệt vời! Tất cả các phòng trống đều đã được đăng tin.',
        CupertinoIcons.checkmark_seal_fill,
        AppTheme.kSuccess,
      );
    }
    return _buildVerticalList(unpostedRooms, branches, posts);
  }

  Widget _buildActivePostsTab(
    List<dynamic> branches,
    List<dynamic> allRooms,
    List<dynamic> posts,
  ) {
    final activeRooms = allRooms.where((r) {
      final p = _getPostForRoom(r, posts);
      return p != null && p['status'] == 'ACTIVE';
    }).toList();

    if (activeRooms.isEmpty) {
      return _buildEmptyState(
        'Chưa có tin đang hiển thị',
        'Bạn chưa có bài đăng nào đang public trên cộng đồng.',
        CupertinoIcons.speaker_2_fill,
        AppTheme.kBrandDeep,
      );
    }
    return _buildVerticalList(activeRooms, branches, posts);
  }

  Widget _buildHiddenPostsTab(
    List<dynamic> branches,
    List<dynamic> allRooms,
    List<dynamic> posts,
  ) {
    final hiddenRooms = allRooms.where((r) {
      final p = _getPostForRoom(r, posts);
      return p != null && p['status'] != 'ACTIVE';
    }).toList();

    if (hiddenRooms.isEmpty) {
      return _buildEmptyState(
        'Không có tin ẩn/nháp',
        'Bạn không có tin đăng nào bị ẩn hoặc đang lưu nháp.',
        CupertinoIcons.archivebox_fill,
        AppTheme.kTextMuted,
      );
    }
    return _buildVerticalList(hiddenRooms, branches, posts);
  }

  Widget _buildVerticalList(
    List<dynamic> rooms,
    List<dynamic> branches,
    List<dynamic> posts,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        // Làm mới cả thống kê dashboard để ô "Chưa đăng" khớp với danh sách.
        refreshOwnerDashboardFromWidget(ref);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          final branch = branches
              .where((b) => b.id == room.branchId)
              .firstOrNull;
          final post = _getPostForRoom(room, posts);

          return _buildRoomCard(room, branch, post, context);
        },
      ),
    );
  }

  Widget _buildRoomCard(
    dynamic room,
    dynamic branch,
    dynamic post,
    BuildContext context,
  ) {
    final isPublished = post != null && post['status'] == 'ACTIVE';
    final isHidden = post != null && post['status'] != 'ACTIVE';

    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFF1F5F9),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildImage(
                  (post != null &&
                          (post['coverImageUrl'] ?? '').toString().isNotEmpty)
                      ? post['coverImageUrl']
                      : room.roomImages,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            room.roomName ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.kTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isPublished
                                ? const Color(0xFFD1FAE5)
                                : (isHidden
                                      ? const Color(0xFFF3F4F6)
                                      : const Color(0xFFFEF3C7)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isPublished
                                ? 'Đang hiển thị'
                                : (isHidden ? 'Đã ẩn' : 'Chưa đăng'),
                            style: TextStyle(
                              color: isPublished
                                  ? AppTheme.kSuccess
                                  : (isHidden
                                        ? const Color(0xFF4B5563)
                                        : AppTheme.kWarning),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.building_2_fill,
                          size: 12,
                          color: AppTheme.kTextMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            branch?.branchName ?? 'N/A',
                            style: const TextStyle(
                              color: AppTheme.kTextMuted,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(post?['rentingPrice'] ?? room.price ?? 0)}/tháng',
                      style: const TextStyle(
                        color: AppTheme.kBrandDeep,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isPublished || isHidden) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            CupertinoIcons.doc_text,
                            size: 12,
                            color: AppTheme.kTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              (post['postTitle'] ?? room.roomName ?? '')
                                  .toString(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.kTextSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (post['updatedAt'] != null ||
                              post['createdAt'] != null) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              CupertinoIcons.clock,
                              size: 12,
                              color: AppTheme.kTextSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              TimeUtils.formatTimeAgo(
                                DateTime.tryParse(
                                      (post['updatedAt'] ?? post['createdAt'])
                                          .toString(),
                                    ) ??
                                    DateTime.now(),
                              ),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.kTextSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: isPublished
                      ? const Color(0xFFF1F5F9)
                      : AppTheme.kBrand,
                  borderRadius: BorderRadius.circular(8),
                  onPressed: () {
                    // BUGFIX (data): trước đây ép `(room.price ?? 0) as num`
                    // — nếu backend trả String ("3000000") thì ném TypeError
                    // và nút Đăng bài không hoạt động. Coerce an toàn.
                    final num price = _asNum(room.price);
                    final num area = _asNum(room.area);
                    final images = room.roomImages;
                    int imageCount = 0;
                    if (images != null &&
                        images.toString().trim().isNotEmpty &&
                        images.toString().trim() != '[]') {
                      if (images is List) {
                        imageCount = images.length;
                      } else {
                        imageCount = images.toString().split(',').length;
                      }
                    }

                    if (price <= 0 || area <= 0 || imageCount < 3) {
                      unawaited(
                        showDialog(
                          context: context,
                          builder: (ctx) => CupertinoAlertDialog(
                            title: const Text('Điểm Sức khoẻ Phòng chưa đạt'),
                            content: const Text(
                              'Để đăng bài lên Marketplace, phòng cần đáp ứng:\n• Ít nhất 3 ảnh thực tế\n• Giá thuê > 0\n• Diện tích > 0\n\nVui lòng cập nhật đủ thông tin trong Quản lý Phòng trước khi đăng.',
                            ),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text('Đã hiểu'),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                        ),
                      );
                      return;
                    }

                    unawaited(
                      context.push(
                        '/owner/edit-post',
                        extra: {
                          'room': room,
                          'post': post,
                          'branch': branch,
                          'branchAddress': branch?.address,
                          'branchLat': branch?.latitude,
                          'branchLng': branch?.longitude,
                        },
                      ),
                    );
                  },
                  child: Text(
                    isPublished
                        ? 'Sửa tin'
                        : (isHidden ? 'Sửa / Đăng lại' : 'Đăng tin ngay'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isPublished
                          ? AppTheme.kTextPrimary
                          : CupertinoColors.white,
                    ),
                  ),
                ),
              ),
              if (isPublished) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  height: 38,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(8),
                    onPressed: () async {
                      final postId = post['id']?.toString() ?? '';
                      final link = 'https://stayhub.vn/post/$postId';
                      await Clipboard.setData(ClipboardData(text: link));
                      if (context.mounted) {
                        ToastUtils.show(
                          context,
                          'Đã copy link chia sẻ!',
                          isError: false,
                        );
                      }
                    },
                    child: const Icon(
                      CupertinoIcons.share,
                      size: 18,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String? roomImagesStr) {
    if (roomImagesStr == null || roomImagesStr.isEmpty) {
      return const Center(
        child: Icon(
          CupertinoIcons.bed_double_fill,
          color: Color(0xFF94A3B8),
          size: 30,
        ),
      );
    }
    try {
      String imgPath = '';
      if (roomImagesStr.trim().startsWith('[')) {
        // BUGFIX (data): tránh `as List` ném TypeError khi JSON là object/số,
        // và tránh lấy `.first.toString()` ra chuỗi rác `{...}` khi phần tử là Map.
        final decoded = jsonDecode(roomImagesStr);
        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first;
          if (first is String) {
            imgPath = first;
          } else if (first is Map && first['url'] != null) {
            imgPath = first['url'].toString();
          } else {
            imgPath = first.toString();
          }
        }
      } else {
        imgPath = roomImagesStr.split(',').first.trim();
      }

      if (imgPath.isEmpty) {
        return const Center(
          child: Icon(
            CupertinoIcons.bed_double_fill,
            color: Color(0xFF94A3B8),
            size: 30,
          ),
        );
      }

      if (imgPath.startsWith('data:image/') ||
          (imgPath.length > 200 && !imgPath.startsWith('http'))) {
        final base64Str = imgPath.contains(',')
            ? imgPath.split(',').last
            : imgPath;
        return Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      }
      return Image.network(
        ImageUrlHelper.buildUrl(imgPath) ?? '',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(
            CupertinoIcons.bed_double_fill,
            color: Color(0xFF94A3B8),
            size: 30,
          ),
        ),
      );
    } catch (e) {
      return const Center(
        child: Icon(
          CupertinoIcons.bed_double_fill,
          color: Color(0xFF94A3B8),
          size: 30,
        ),
      );
    }
  }

  Widget _buildEmptyState(
    String message,
    String subMessage,
    IconData icon,
    Color color,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: color),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subMessage,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
