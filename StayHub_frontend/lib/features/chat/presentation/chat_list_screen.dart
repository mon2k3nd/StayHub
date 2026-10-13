import 'dart:ui' show ImageFilter;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/components/bounce_click.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/utils/toast_utils.dart';
import 'thread_message_screen.dart';
import 'branch_group_chat_screen.dart';
import '../../contract/application/contract_notifier.dart';
import '../../branch/application/branch_notifier.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/conversation_provider.dart';
import 'widgets/new_message_sheet.dart';
import '../../../core/utils/string_utils.dart';
import 'dart:async' show unawaited;

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'Tất cả';
  bool _isLoadingThread = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _shimmerController;
  final ScrollController _scrollController = ScrollController();
  bool _isFabExpanded = true;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    unawaited(_shimmerController.repeat());
    _scrollController.addListener(() {
      // BUGFIX (Bug 34): guard `mounted` + `hasClients` — listener có thể bắn
      // trong lúc widget đang dispose (điều hướng ra) → setState after dispose.
      if (!mounted || !_scrollController.hasClients) return;
      if (_scrollController.offset > 50 && _isFabExpanded) {
        setState(() => _isFabExpanded = false);
      } else if (_scrollController.offset <= 50 && !_isFabExpanded) {
        setState(() => _isFabExpanded = true);
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openTenantOwnerChat(int otherUserId, String title) async {
    if (_isLoadingThread) return;
    setState(() => _isLoadingThread = true);
    // BUGFIX (Bug 42): bọc try/finally để cờ `_isLoadingThread` luôn được
    // reset kể cả khi `createOrGetThread` ném exception. Trước đây nếu API
    // lỗi, cờ kẹt ở `true` → mọi lần mở chat sau đó bị chặn (return sớm).
    try {
      final thread = await ref
          .read(conversationProvider.notifier)
          .createOrGetThread(otherUserId, 'TENANT_OWNER');
      if (!mounted) return;
      if (thread != null) {
        await Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) =>
                ThreadMessageScreen(threadId: thread.id, title: title),
          ),
        );
        unawaited(_onRefresh());
      } else {
        ToastUtils.show(
          context,
          'Không mở được cuộc trò chuyện. Vui lòng thử lại.',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('Open tenant-owner chat error: $e');
      if (mounted) {
        ToastUtils.show(
          context,
          'Không mở được cuộc trò chuyện. Vui lòng thử lại.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingThread = false);
    }
  }

  void _openNewMessageSheet() {
    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return NewMessageSheet(
            onChatSelected: (id, name) {
              unawaited(_openTenantOwnerChat(id, name));
            },
          );
        },
      ),
    );
  }

  Future<void> _onRefresh() async {
    ref.invalidate(contractProvider);
    ref.invalidate(branchProvider);
    ref.invalidate(conversationProvider);
    try {
      await Future.wait([
        ref.read(contractProvider.future),
        ref.read(branchProvider.future),
        ref.read(conversationProvider.future),
      ]);
    } catch (e, st) {
      debugPrint('Error on refresh: $e\n$st');
      if (mounted) {
        ToastUtils.show(
          context,
          'Lỗi tải dữ liệu. Vui lòng thử lại sau.',
          isError: true,
        );
      }
    }
  }

  /// Returns config map for context-aware empty state per filter tab.
  Map<String, dynamic> _getEmptyStateConfig(String filter, String userRole) {
    switch (filter) {
      case 'Group':
        return {
          'emoji': '🏠',
          'color': const Color(0xFF6366F1),
          'title': 'Chưa có nhóm dãy nào',
          'subtitle': userRole == 'OWNER'
              ? 'Tạo dãy trọ để có nhóm chat chung với khách thuê.'
              : 'Bạn chưa đang thuê phòng tại dãy nào. Hãy tìm phòng trên Marketplace!',
          'action': userRole == 'OWNER' ? null : null,
          'actionLabel': '',
        };
      case 'Người thuê':
        return {
          'emoji': '👥',
          'color': const Color(0xFF298FFF),
          'title': 'Chưa có khách thuê nào',
          'subtitle':
              'Khi có hợp đồng thuê phòng được tạo, danh sách người thuê sẽ xuất hiện tại đây.',
          'action': null,
          'actionLabel': '',
        };
      case 'Chủ nhà':
        return {
          'emoji': '🔑',
          'color': const Color(0xFF10B981),
          'title': 'Chưa có liên hệ chủ nhà',
          'subtitle':
              'Chủ nhà sẽ xuất hiện ở đây sau khi hợp đồng thuê phòng được kích hoạt.',
          'action': null,
          'actionLabel': '',
        };
      case 'Khách hỏi phòng':
        return {
          'emoji': '🔍',
          'color': const Color(0xFFF59E0B),
          'title': 'Chưa có ai hỏi phòng',
          'subtitle':
              'Khi khách tìm kiếm và nhắn tin hỏi phòng của bạn, họ sẽ xuất hiện tại đây.',
          'action': null,
          'actionLabel': '',
        };
      case 'Hàng xóm':
        return {
          'emoji': '🤝',
          'color': const Color(0xFF8B5CF6),
          'title': 'Chưa có cuộc trò chuyện hàng xóm',
          'subtitle':
              'Kết nối với những người cùng dãy trọ để hỗ trợ nhau trong cuộc sống.',
          'action': null,
          'actionLabel': '',
        };
      case 'Đã rời đi':
        return {
          'emoji': '👋',
          'color': const Color(0xFF9CA3AF),
          'title': 'Chưa có lịch sử dãy nào',
          'subtitle':
              'Các nhóm dãy từ hợp đồng đã kết thúc sẽ được lưu lại ở đây để bạn xem lại.',
          'action': null,
          'actionLabel': '',
        };
      case 'Tin nhắn đã lưu':
        return {
          'emoji': '🔖',
          'color': const Color(0xFF298FFF),
          'title': 'Chưa có tin nhắn nào được lưu',
          'subtitle':
              'Vuốt phải trên bất kỳ cuộc trò chuyện nào để lưu lại và xem sau.',
          'action': null,
          'actionLabel': '',
        };
      case 'Tin nhắn đã xóa':
        return {
          'emoji': '🗑️',
          'color': const Color(0xFFEF4444),
          'title': 'Không có tin nhắn nào bị xóa',
          'subtitle':
              'Các cuộc trò chuyện bạn đã xóa sẽ hiện ở đây. Vuốt trái để xóa một cuộc trò chuyện.',
          'action': null,
          'actionLabel': '',
        };
      default: // 'Tất cả'
        return {
          'emoji': '💬',
          'color': const Color(0xFF298FFF),
          'title': 'Chưa có cuộc trò chuyện nào',
          'subtitle':
              'Bắt đầu kết nối! Nhấn nút ✏️ bên dưới để nhắn tin với chủ nhà hoặc khách thuê.',
          'action': _openNewMessageSheet,
          'actionLabel': 'Tạo tin nhắn mới',
        };
    }
  }

  Widget _buildFab() {
    return Positioned(
      bottom: 24,
      right: 24,
      child: BounceClick(
        onPressed: () {
          unawaited(HapticFeedback.lightImpact());
          _openNewMessageSheet();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          width: _isFabExpanded ? 158 : 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: PremiumGradients.skyBrand,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: AppTheme.kBrand.withValues(alpha: 0.45),
                blurRadius: 22,
                spreadRadius: 1,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.pencil_outline,
                color: Colors.white,
                size: 26,
              ),
              if (_isFabExpanded) ...[
                const SizedBox(width: 8),
                const Text(
                  'Soạn tin',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final userRole = user?.role ?? 'GUEST';

    final contractsAsync = ref.watch(contractProvider);
    final branches = ref.watch(branchProvider);
    final conversationsAsync = ref.watch(conversationProvider);

    List<String> filters = ['Tất cả'];
    if (userRole == 'OWNER') {
      filters.addAll(['Group', 'Người thuê', 'Khách hỏi phòng']);
    } else {
      filters.addAll(['Group', 'Đã rời đi', 'Chủ nhà', 'Hàng xóm']);
    }
    filters.addAll(['Tin nhắn đã lưu', 'Tin nhắn đã xóa']);

    return LiquidGlassScaffold(
      title: 'Tin nhắn',
      useScrollView: false,
      backgroundColors: const Color(0xFFF9FAFB),
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        child: const Icon(
          CupertinoIcons.ellipsis_circle,
          color: AppTheme.kBrandDeep,
          size: 26,
        ),
        onPressed: () {
          unawaited(
            showCupertinoModalPopup(
              context: context,
              builder: (context) => CupertinoActionSheet(
                actions: [
                  CupertinoActionSheetAction(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _selectedFilter = 'Tin nhắn đã lưu');
                    },
                    child: const Text(
                      'Tin nhắn đã lưu',
                      style: TextStyle(color: AppTheme.kBrandDeep),
                    ),
                  ),
                  CupertinoActionSheetAction(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _selectedFilter = 'Tin nhắn đã xóa');
                    },
                    isDestructiveAction: true,
                    child: const Text('Tin nhắn đã xóa'),
                  ),
                ],
                cancelButton: CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ),
            ),
          );
        },
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Search field (glass pill) ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.kBrand.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CupertinoSearchTextField(
                    controller: _searchController,
                    placeholder: 'Tìm kiếm người dùng, phòng...',
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: const BoxDecoration(),
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.kTextPrimary,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                ),
              ),

              if (filters.length > 1)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFFE3F0FF), width: 1),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: filters.map((f) {
                        final isSelected = _selectedFilter == f;
                        return BounceClick(
                          onPressed: () => setState(() => _selectedFilter = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? PremiumGradients.skyBrand
                                  : null,
                              color: isSelected
                                  ? null
                                  : Colors.white.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.kBrand.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: AppTheme.kBrand.withValues(
                                          alpha: 0.06,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : const Color(0xFFE3F0FF),
                              ),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.kBrandDeep,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              Expanded(
                child: contractsAsync.when(
                  loading: () =>
                      const Center(child: CupertinoActivityIndicator()),
                  // BUGFIX (Bug 63): trạng thái lỗi trước đây hiển thị thẳng
                  // exception thô (`Lỗi: $e`) — vừa lộ chi tiết kỹ thuật vừa
                  // không có cách thử lại. Thay bằng thông báo thân thiện +
                  // nút "Thử lại" gọi invalidate provider.
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.exclamationmark_triangle,
                            color: Color(0xFFF59E0B),
                            size: 44,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Không tải được danh sách trò chuyện',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Vui lòng kiểm tra kết nối và thử lại.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 12,
                            ),
                            color: AppTheme.kBrand,
                            borderRadius: BorderRadius.circular(100),
                            onPressed: () {
                              ref.invalidate(contractProvider);
                              ref.invalidate(branchProvider);
                              ref.invalidate(conversationProvider);
                            },
                            child: const Text(
                              'Thử lại',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (contracts) {
                    final activeContracts = contracts
                        .where(
                          (c) => c.status == 'ACTIVE' || c.status == 'PENDING',
                        )
                        .toList();
                    final oldContracts = contracts
                        .where(
                          (c) => c.status != 'ACTIVE' && c.status != 'PENDING',
                        )
                        .toList();

                    final List<Map<String, dynamic>> realChats = [];

                    if (_selectedFilter == 'Tất cả' ||
                        _selectedFilter == 'Group') {
                      // BUGFIX (Bug 19): áp dụng bộ lọc tìm kiếm cho cả nhóm
                      // dãy. Trước đây nhóm dãy luôn hiển thị bất kể từ khoá
                      // tìm kiếm, gây kết quả sai khi người dùng tìm kiếm.
                      bool matchesSearch(String name, String subtitle) {
                        if (_searchQuery.isEmpty) return true;
                        final q = _searchQuery.toLowerCase();
                        return name.toLowerCase().contains(q) ||
                            subtitle.toLowerCase().contains(q);
                      }

                      if (userRole == 'OWNER') {
                        for (var b in branches.value ?? []) {
                          final name = 'Nhóm Dãy: ${b.branchName ?? "Dãy Trọ"}';
                          final subtitle = b.branchName ?? 'Dãy trọ';
                          if (!matchesSearch(name, subtitle)) continue;
                          realChats.add({
                            'id': b.id.toString(),
                            'type': 'BRANCH_GROUP',
                            'name': name,
                            'subtitle': subtitle,
                            'initials': (b.branchName ?? 'G').initials,
                            'lastMessage': 'Nhấn để xem tin nhắn nhóm...',
                            // BUGFIX (Bug 64): xem chú thích ở nhánh OWNER.
                            'time': DateTime.fromMillisecondsSinceEpoch(0),
                            'color': AppTheme.kBrandDeep,
                            'tag': 'Nhóm Dãy',
                            'isReadOnly': false,
                          });
                        }
                      } else {
                        final seenBranches = <int>{};
                        for (var c in activeContracts) {
                          if (c.branchId == null ||
                              seenBranches.contains(c.branchId)) {
                            continue;
                          }
                          final name = 'Nhóm Dãy: ${c.branchName ?? "Dãy Trọ"}';
                          final subtitle =
                              'Đang thuê • ${c.roomName ?? "Phòng ${c.roomId}"}';
                          if (!matchesSearch(name, subtitle)) continue;
                          seenBranches.add(c.branchId!);
                          realChats.add({
                            'id': c.branchId.toString(),
                            'type': 'BRANCH_GROUP',
                            'name': name,
                            'subtitle': subtitle,
                            'initials': (c.branchName ?? 'G').initials,
                            'lastMessage': 'Nhấn để xem tin nhắn nhóm...',
                            // BUGFIX (Bug 64): xem chú thích ở nhánh OWNER.
                            'time': DateTime.fromMillisecondsSinceEpoch(0),
                            'color': AppTheme.kBrandDeep,
                            'tag': 'Nhóm Dãy',
                            'isReadOnly': false,
                          });
                        }
                      }
                    }

                    // BUGFIX (Bug 10): "Đã rời đi" chỉ hiển thị các dãy mà
                    // người dùng ĐÃ rời (hợp đồng cũ) và KHÔNG còn hợp đồng
                    // đang hoạt động. Trước đây không loại trừ dãy đang thuê
                    // → cùng một dãy xuất hiện 2 lần (vừa "Đang thuê" vừa
                    // "Đã rời đi"), và ở tab "Tất cả" cũng lẫn dãy đã rời.
                    if (_selectedFilter == 'Đã rời đi') {
                      final activeBranchIds = <int>{
                        for (final c in activeContracts)
                          if (c.branchId != null) c.branchId!,
                      };
                      final seenOldBranches = <int>{};
                      for (var c in oldContracts) {
                        if (c.branchId == null ||
                            seenOldBranches.contains(c.branchId) ||
                            activeBranchIds.contains(c.branchId)) {
                          continue;
                        }
                        // BUGFIX (Bug 20): áp dụng bộ lọc tìm kiếm cho cả nhóm
                        // dãy "Đã rời đi" — trước đây bỏ qua từ khoá tìm kiếm.
                        final oldName =
                            'Nhóm Dãy: ${c.branchName ?? "Dãy Trọ"}';
                        if (_searchQuery.isNotEmpty &&
                            !oldName.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            )) {
                          continue;
                        }
                        seenOldBranches.add(c.branchId!);
                        realChats.add({
                          'id': c.branchId.toString(),
                          'type': 'BRANCH_GROUP',
                          'name': oldName,
                          'subtitle': 'Đã rời đi • Chỉ xem',
                          'initials': (c.branchName ?? 'G').initials,
                          'lastMessage': 'Chỉ xem tin nhắn cũ',
                          'time': c.endDate,
                          'color': const Color(0xFF9CA3AF),
                          'tag': 'Đã Rời',
                          'isReadOnly': true,
                        });
                      }
                    }

                    if (_selectedFilter == 'Tất cả' ||
                        _selectedFilter == 'Người thuê' ||
                        _selectedFilter == 'Chủ nhà') {
                      final seenUsers = <int>{};
                      // BUGFIX (Bug 22): OWNER chỉ nên thấy khách thuê từ hợp
                      // đồng đang hoạt động (ACTIVE/PENDING). Trước đây dùng
                      // toàn bộ `contracts` (gồm cả hợp đồng đã kết thúc) nên
                      // tab "Người thuê" hiển thị cả người đã rời đi.
                      // BUGFIX (Bug 65): ternary trước đây có hai nhánh giống
                      // hệt nhau (`? activeContracts : activeContracts`) —
                      // rõ ràng là lỗi sao chép. Cả OWNER lẫn TENANT đều chỉ
                      // nên thấy hội thoại từ hợp đồng đang hoạt động.
                      final chatContracts = activeContracts;
                      for (var c in chatContracts) {
                        final otherUserId = userRole == 'OWNER'
                            ? c.tenantId
                            : c.ownerId;
                        if (seenUsers.contains(otherUserId)) continue;

                        final name = userRole == 'OWNER'
                            ? c.tenantName ?? "Khách thuê"
                            : c.ownerName ?? "Chủ nhà";
                        final subtitle = userRole == 'OWNER'
                            ? 'Phòng ${c.roomName ?? c.roomId}'
                            : 'Dãy ${c.branchName ?? ""}';

                        if (_searchQuery.isNotEmpty) {
                          final matchName = name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );
                          final matchSub = subtitle.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );
                          if (!matchName && !matchSub) continue;
                        }

                        DateTime threadTime =
                            DateTime.fromMillisecondsSinceEpoch(0);
                        String lastMsg = 'Bắt đầu trò chuyện...';
                        bool isUnread = false;
                        int? threadId;
                        bool isDeleted = false;
                        bool isSaved = false;

                        if (conversationsAsync is AsyncData) {
                          for (var conv in conversationsAsync.value ?? []) {
                            if (conv.threadType == 'TENANT_OWNER' &&
                                (conv.userId1 == otherUserId ||
                                    conv.userId2 == otherUserId)) {
                              threadTime = conv.updatedAt;
                              threadId = conv.id;
                              // BUGFIX (Bug 67): trước đây fallback `?? 0`
                              // khiến khi user null thì `isDeletedBy(0)` trả
                              // về sai (0 không phải id hợp lệ) → cờ xóa/lưu
                              // sai. Chỉ tính khi có user id thực.
                              final myId = user?.id;
                              isDeleted =
                                  myId != null && conv.isDeletedBy(myId);
                              isSaved = myId != null && conv.isSavedBy(myId);
                              if (conv.lastMessageContent != null) {
                                final senderPrefix =
                                    conv.lastSenderId == user?.id
                                    ? 'Bạn: '
                                    : '';
                                lastMsg =
                                    senderPrefix + conv.lastMessageContent!;
                              } else {
                                lastMsg = 'Có tin nhắn mới...';
                              }

                              final myLastRead = user?.id == conv.userId1
                                  ? conv.user1LastRead
                                  : conv.user2LastRead;
                              if (myLastRead == null ||
                                  myLastRead.isBefore(conv.updatedAt)) {
                                isUnread = true;
                              }
                              break;
                            }
                          }
                        }

                        // BUGFIX (Bug 21): đánh dấu `seenUsers` NGAY sau khi
                        // xác định được otherUserId, trước các bộ lọc. Trước
                        // đây add() nằm sau filter nên khi filter `continue`
                        // thì user không được đánh dấu → cùng một người có thể
                        // xuất hiện nhiều lần (mỗi hợp đồng một dòng).
                        seenUsers.add(otherUserId);

                        if (_selectedFilter == 'Tin nhắn đã xóa') {
                          if (!isDeleted) continue;
                        } else if (_selectedFilter == 'Tin nhắn đã lưu') {
                          if (!isSaved || isDeleted) continue;
                        } else {
                          if (isDeleted) continue;
                        }

                        realChats.add({
                          'id': otherUserId.toString(),
                          'threadId': threadId,
                          'type': 'TENANT_OWNER',
                          'otherUserId': otherUserId,
                          'name': name,
                          'subtitle': subtitle,
                          'initials': (name).initials,
                          'lastMessage': lastMsg,
                          'time': threadTime,
                          'color': AppTheme.kBrand,
                          'tag': userRole == 'OWNER' ? 'Khách Thuê' : 'Chủ Nhà',
                          'isReadOnly': false,
                          'isUnread': isUnread,
                        });
                      }
                    }

                    if (conversationsAsync is AsyncData) {
                      for (var conv in conversationsAsync.value ?? []) {
                        if (conv.threadType == 'TENANT_OWNER') continue;

                        // BUGFIX (Bug 67): xem chú thích ở vòng lặp TENANT_OWNER.
                        final myId = user?.id;
                        bool isDeleted = myId != null && conv.isDeletedBy(myId);
                        bool isSaved = myId != null && conv.isSavedBy(myId);

                        if (_selectedFilter == 'Tin nhắn đã xóa') {
                          if (!isDeleted) continue;
                        } else if (_selectedFilter == 'Tin nhắn đã lưu') {
                          if (!isSaved || isDeleted) continue;
                        } else {
                          if (isDeleted) continue;
                          if (_selectedFilter == 'Khách hỏi phòng' &&
                              conv.threadType != 'INQUIRY') {
                            continue;
                          }
                          if (_selectedFilter == 'Hàng xóm' &&
                              conv.threadType != 'NEIGHBOR') {
                            continue;
                          }
                        }

                        // BUGFIX (Bug 66): `otherUserId` không còn dùng để
                        // hiển thị (trước đây tạo nhãn "Hàng xóm #<id>").
                        final isNeighbor = conv.threadType == 'NEIGHBOR';
                        // BUGFIX (Bug 66): trước đây hiển thị id thô
                        // (`Hàng xóm #$otherUserId`) — vô nghĩa với người
                        // dùng. Backend không trả tên hàng xóm, nên dùng
                        // `lastSenderName` nếu tin nhắn cuối do người kia gửi,
                        // ngược lại dùng nhãn chung dễ hiểu.
                        final neighborName =
                            (conv.lastSenderName != null &&
                                conv.lastSenderId != null &&
                                conv.lastSenderId != user?.id)
                            ? conv.lastSenderName
                            : null;
                        final name = isNeighbor
                            ? (neighborName != null &&
                                      neighborName.trim().isNotEmpty
                                  ? neighborName
                                  : 'Hàng xóm')
                            : 'Khách hỏi phòng';
                        final subtitle = isNeighbor
                            ? 'Hàng xóm dãy trọ'
                            : 'Hỏi về phòng trống';

                        if (_searchQuery.isNotEmpty) {
                          final matchName = name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );
                          final matchSub = subtitle.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );
                          if (!matchName && !matchSub) continue;
                        }

                        final color = isNeighbor
                            ? const Color(0xFF8B5CF6)
                            : const Color(0xFFF59E0B);

                        String lastMsg = 'Có tin nhắn mới...';
                        if (conv.lastMessageContent != null) {
                          final senderPrefix = conv.lastSenderId == user?.id
                              ? 'Bạn: '
                              : '';
                          lastMsg = senderPrefix + conv.lastMessageContent!;
                        }

                        bool isUnread = false;
                        final myLastRead = user?.id == conv.userId1
                            ? conv.user1LastRead
                            : conv.user2LastRead;
                        if (myLastRead == null ||
                            myLastRead.isBefore(conv.updatedAt)) {
                          isUnread = true;
                        }

                        realChats.add({
                          'id': conv.id.toString(),
                          'threadId': conv.id,
                          'type': 'CONVERSATION',
                          'threadType': conv.threadType,
                          'name': name,
                          'subtitle': isNeighbor
                              ? 'Hàng xóm dãy trọ'
                              : 'Hỏi về phòng trống',
                          'initials': isNeighbor ? 'HX' : 'KH',
                          'lastMessage': lastMsg,
                          'time': conv.updatedAt,
                          'color': color,
                          'tag': isNeighbor ? 'Hàng Xóm' : 'Hỏi Phòng',
                          'isReadOnly': false,
                          'isUnread': isUnread,
                        });
                      }
                    }

                    // BUGFIX (Bug 115): tránh cast cứng `as DateTime` — nếu
                    // một mục thiếu/khác kiểu 'time' sẽ ném TypeError làm sập
                    // toàn bộ danh sách. Dùng so sánh an toàn.
                    realChats.sort((a, b) {
                      final timeA = a['time'];
                      final timeB = b['time'];
                      if (timeA is DateTime && timeB is DateTime) {
                        return timeB.compareTo(timeA);
                      }
                      return 0;
                    });

                    if (realChats.isEmpty) {
                      // Context-aware empty state per filter
                      final emptyConfig = _getEmptyStateConfig(
                        _selectedFilter,
                        userRole,
                      );
                      return RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: ListView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                ),
                                child: Column(
                                  children: [
                                    // Animated icon container
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.7, end: 1.0),
                                      duration: const Duration(
                                        milliseconds: 500,
                                      ),
                                      curve: Curves.elasticOut,
                                      builder: (_, scale, child) =>
                                          Transform.scale(
                                            scale: scale,
                                            child: child,
                                          ),
                                      child: Container(
                                        width: 110,
                                        height: 110,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              emptyConfig['color'] as Color,
                                              (emptyConfig['color'] as Color)
                                                  .withValues(alpha: 0.4),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  (emptyConfig['color']
                                                          as Color)
                                                      .withValues(alpha: 0.3),
                                              blurRadius: 32,
                                              spreadRadius: 6,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            // BUGFIX (data): tránh `as String`
                                            // ném TypeError khi emoji null/khác.
                                            (emptyConfig['emoji'] ?? '')
                                                .toString(),
                                            style: const TextStyle(
                                              fontSize: 44,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    Text(
                                      // BUGFIX (data): tránh `as String` ném
                                      // TypeError khi title null/khác.
                                      (emptyConfig['title'] ?? '').toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      // BUGFIX (data): tránh `as String` ném
                                      // TypeError khi subtitle null/khác.
                                      (emptyConfig['subtitle'] ?? '')
                                          .toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                    if (emptyConfig['action'] != null) ...[
                                      const SizedBox(height: 24),
                                      CupertinoButton(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 28,
                                          vertical: 12,
                                        ),
                                        color: AppTheme.kBrand,
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        onPressed:
                                            emptyConfig['action']
                                                as VoidCallback,
                                        child: Text(
                                          // BUGFIX (data): tránh `as String`
                                          // ném TypeError khi actionLabel null.
                                          (emptyConfig['actionLabel'] ?? '')
                                              .toString(),
                                          style: const TextStyle(
                                            color: CupertinoColors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: AppTheme.kBrandDeep,
                      onRefresh: _onRefresh,
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: realChats.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final chat = realChats[index];
                          return _ChatListItem(
                            chat: chat,
                            index: index,
                            onRefresh: _onRefresh,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          if (_isLoadingThread)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                color: AppTheme.kTextPrimary.withValues(alpha: 0.15),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.kSurface1Light,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.kBrand.withValues(alpha: 0.15),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const CupertinoActivityIndicator(radius: 16),
                ),
              ),
            ),

          // BUGFIX (Bug 13): xoá overlay `_isFabOpen` — cờ này không bao giờ
          // được set true nên nhánh if là dead code, và FAB mở sheet trực
          // tiếp (không phải speed-dial) nên không cần lớp phủ.
          _buildFab(),
        ],
      ),
    );
  }
}

class _ChatListItem extends ConsumerStatefulWidget {
  final Map<String, dynamic> chat;
  final int index;
  final VoidCallback onRefresh;

  const _ChatListItem({
    required this.chat,
    required this.index,
    required this.onRefresh,
  });

  @override
  ConsumerState<_ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends ConsumerState<_ChatListItem>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  // BUGFIX (Bug 68): cờ chống double-tap khi vuốt lưu/xóa.
  bool _isSwiping = false;
  // BUGFIX (Bug 91): cờ chống double-tap khi mở hội thoại — trước đây bấm
  // nhanh 2 lần có thể đẩy 2 màn hình trùng lên Navigator.
  bool _isOpening = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    Future.delayed(
      Duration(milliseconds: (50 * widget.index).clamp(0, 500)),
      () {
        if (mounted) unawaited(_animController.forward());
      },
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _openTenantOwnerChat(
    BuildContext context,
    WidgetRef ref,
    int otherUserId,
    String title,
  ) async {
    // BUGFIX (Bug 89): bọc try/catch — trước đây nếu `createOrGetThread` ném
    // exception thì lỗi bị nuốt và người dùng không nhận được phản hồi nào
    // (bấm không có gì xảy ra). Giờ báo toast lỗi thân thiện.
    try {
      final thread = await ref
          .read(conversationProvider.notifier)
          .createOrGetThread(otherUserId, 'TENANT_OWNER');
      if (thread != null && context.mounted) {
        await Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) =>
                ThreadMessageScreen(threadId: thread.id, title: title),
          ),
        );
        widget.onRefresh();
      } else if (context.mounted) {
        ToastUtils.show(
          context,
          'Không mở được cuộc trò chuyện. Vui lòng thử lại.',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('Open tenant-owner chat error: $e');
      if (context.mounted) {
        ToastUtils.show(
          context,
          'Không mở được cuộc trò chuyện. Vui lòng thử lại.',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;
    // BUGFIX (Bug 115): dùng coercion an toàn thay vì cast cứng `as Color`.
    final badgeColor = chat['color'] is Color
        ? chat['color'] as Color
        : AppTheme.kBrand;
    final isReadOnly = chat['isReadOnly'] as bool? ?? false;
    final isUnread = chat['isUnread'] as bool? ?? false;

    // BUGFIX (Bug 11): key phải bao gồm cả `type` vì BRANCH_GROUP dùng
    // branchId còn TENANT_OWNER/CONVERSATION dùng userId/threadId — hai mục
    // khác loại có thể trùng `id` → Dismissible trùng key gây crash
    // "Duplicate GlobalKey/keys must be unique".
    return Dismissible(
      key: Key('${chat['type']}_${chat['id']}'),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          gradient: PremiumGradients.skyBrand,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Icon(
          CupertinoIcons.bookmark_fill,
          color: Colors.white,
          size: 26,
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF87171), Color(0xFFEF4444)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(
          CupertinoIcons.delete_solid,
          color: Colors.white,
          size: 26,
        ),
      ),
      // BUGFIX (Bug 68): trước đây gọi toggleSave/Delete mà không bắt lỗi —
      // nếu API thất bại thì toast vẫn báo "thành công" (sai) và exception
      // bị nuốt. Thêm try/catch + cờ `_isSwiping` chống double-tap khi người
      // dùng vuốt liên tục.
      confirmDismiss: (direction) async {
        if (chat['threadId'] == null) {
          ToastUtils.show(context, 'Chưa có tin nhắn nào để thao tác');
          return false;
        }
        if (_isSwiping) return false;
        _isSwiping = true;
        try {
          if (direction == DismissDirection.startToEnd) {
            await ref
                .read(conversationProvider.notifier)
                .toggleSaveThread(chat['threadId']);
            if (context.mounted) {
              ToastUtils.show(context, 'Đã thay đổi trạng thái Lưu');
            }
          } else {
            await ref
                .read(conversationProvider.notifier)
                .toggleDeleteThread(chat['threadId']);
            if (context.mounted) {
              ToastUtils.show(context, 'Đã cập nhật trạng thái Xóa');
            }
          }
        } catch (e) {
          if (context.mounted) {
            ToastUtils.show(
              context,
              'Thao tác thất bại. Vui lòng thử lại.',
              isError: true,
            );
          }
        } finally {
          _isSwiping = false;
        }
        return false;
      },
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: AnimatedScale(
            scale: _isPressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: !isUnread
                        ? AppTheme.kBrand.withValues(alpha: 0.06)
                        : badgeColor.withValues(alpha: 0.18),
                    blurRadius: !isUnread ? 14 : 26,
                    offset: !isUnread
                        ? const Offset(0, 6)
                        : const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: !isUnread
                          ? Colors.white.withValues(alpha: 0.7)
                          : badgeColor.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: !isUnread
                            ? Colors.white.withValues(alpha: 0.6)
                            : badgeColor.withValues(alpha: 0.5),
                        width: !isUnread ? 1.0 : 1.5,
                      ),
                    ),
                    child: InkWell(
                      // BUGFIX (Bug 91): chống double-tap — bấm nhanh 2 lần
                      // trước đây đẩy 2 màn hình trùng lên Navigator.
                      onTap: () async {
                        if (_isOpening) return;
                        _isOpening = true;
                        try {
                          unawaited(HapticFeedback.lightImpact());
                          if (chat['type'] == 'BRANCH_GROUP') {
                            await Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (_) => BranchGroupChatScreen(
                                  branchId: chat['id']?.toString() ?? '',
                                  branchName: chat['name']?.toString() ?? '',
                                  coverUrl:
                                      'https://ui-avatars.com/api/?name=${chat['initials']}&background=0284C7&color=fff',
                                  isReadOnly: isReadOnly,
                                ),
                              ),
                            );
                            widget.onRefresh();
                          } else if (chat['type'] == 'TENANT_OWNER') {
                            if (chat['threadId'] != null) {
                              // BUGFIX (Bug 18): await markThreadAsRead để
                              // trạng thái "đã đọc" được cập nhật trước khi mở
                              // màn hình, tránh badge chưa đọc còn sót.
                              // BUGFIX (Bug 90): bọc try/catch — trước đây nếu
                              // API đánh dấu đã đọc lỗi thì exception ném ra
                              // ngoài, chặn luôn việc mở hội thoại.
                              try {
                                await ref
                                    .read(conversationProvider.notifier)
                                    .markThreadAsRead(chat['threadId']);
                              } catch (e) {
                                debugPrint('markThreadAsRead error: $e');
                              }
                            }
                            if (context.mounted) {
                              await _openTenantOwnerChat(
                                context,
                                ref,
                                chat['otherUserId'],
                                chat['name'],
                              );
                            }
                          } else if (chat['type'] == 'CONVERSATION') {
                            if (chat['threadId'] != null) {
                              unawaited(
                                ref
                                    .read(conversationProvider.notifier)
                                    .markThreadAsRead(chat['threadId']),
                              );
                            }
                            // BUGFIX (Bug 94): `int.parse(chat['id'])` có thể
                            // ném FormatException nếu id không phải số. Dùng
                            // tryParse và bỏ qua an toàn.
                            final convId = int.tryParse(
                              chat['id']?.toString() ?? '',
                            );
                            if (convId == null) {
                              if (context.mounted) {
                                ToastUtils.show(
                                  context,
                                  'Không mở được cuộc trò chuyện.',
                                  isError: true,
                                );
                              }
                              return;
                            }
                            await Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (_) => ThreadMessageScreen(
                                  threadId: convId,
                                  title: chat['name']?.toString() ?? '',
                                ),
                              ),
                            );
                            widget.onRefresh();
                          }
                        } finally {
                          _isOpening = false;
                        }
                      },
                      onHighlightChanged: (isHighlighted) {
                        setState(() {
                          _isPressed = isHighlighted;
                        });
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    gradient: isReadOnly
                                        ? null
                                        : LinearGradient(
                                            colors: [
                                              badgeColor.withValues(
                                                alpha: 0.22,
                                              ),
                                              badgeColor.withValues(
                                                alpha: 0.08,
                                              ),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                    color: isReadOnly
                                        ? const Color(0xFFF3F4F6)
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isReadOnly
                                          ? const Color(0xFFE5E7EB)
                                          : badgeColor.withValues(alpha: 0.35),
                                      width: 1.5,
                                    ),
                                    boxShadow: isReadOnly
                                        ? null
                                        : [
                                            BoxShadow(
                                              color: badgeColor.withValues(
                                                alpha: 0.2,
                                              ),
                                              blurRadius: 12,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    chat['initials']?.toString() ?? '',
                                    style: TextStyle(
                                      color: isReadOnly
                                          ? const Color(0xFF9CA3AF)
                                          : badgeColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                // BUGFIX (Bug 17): chỉ hiện chấm chưa đọc khi có
                                // threadId hợp lệ (BRANCH_GROUP không có threadId).
                                if (isUnread &&
                                    !isReadOnly &&
                                    chat['threadId'] != null)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: badgeColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: badgeColor.withValues(
                                              alpha: 0.5,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),

                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          chat['name']?.toString() ?? '',
                                          style: TextStyle(
                                            fontWeight: isUnread && !isReadOnly
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            fontSize: 15,
                                            color: isReadOnly
                                                ? const Color(0xFF6B7280)
                                                : const Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Tag badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: badgeColor.withValues(
                                            alpha: isReadOnly ? 0.06 : 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            50,
                                          ),
                                          border: Border.all(
                                            color: badgeColor.withValues(
                                              alpha: isReadOnly ? 0.15 : 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          chat['tag']?.toString() ?? '',
                                          style: TextStyle(
                                            color: isReadOnly
                                                ? const Color(0xFF9CA3AF)
                                                : badgeColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    chat['subtitle'] as String? ?? '',
                                    style: const TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    chat['lastMessage']?.toString() ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isUnread && !isReadOnly
                                          ? badgeColor
                                          : const Color(0xFF64748B),
                                      fontWeight: isUnread && !isReadOnly
                                          ? FontWeight.w800
                                          : FontWeight.normal,
                                      fontStyle: isReadOnly
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (isReadOnly) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                CupertinoIcons.lock,
                                color: Color(0xFFD1D5DB),
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
