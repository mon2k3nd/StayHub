import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_button.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../auth/application/auth_notifier.dart';
import '../../staff/application/staff_assignment_notifier.dart';
import '../../branch/application/branch_notifier.dart';
import 'dart:async' show unawaited;

class BroadcastScreen extends ConsumerStatefulWidget {
  const BroadcastScreen({super.key});

  @override
  ConsumerState<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends ConsumerState<BroadcastScreen> {
  int? _selectedBranchId;
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _isLoading = false;
  bool _sentSuccess = false;

  // Quick templates
  final List<Map<String, String>> _templates = [
    {
      'title': '⚡ Cắt điện tạm thời',
      'content':
          'Thông báo: Ngày mai từ 8h00 - 12h00 sẽ tạm cắt điện để sửa chữa đường dây. Mong bà con thông cảm!',
    },
    {
      'title': '💧 Cúp nước tạm thời',
      'content':
          'Kính thông báo: Ngày mai sẽ tạm cúp nước để vệ sinh bể chứa. Bà con vui lòng trữ nước từ tối hôm nay.',
    },
    {
      'title': '🗓️ Nhắc đóng tiền phòng',
      'content':
          'Nhắc nhở: Hạn đóng tiền phòng tháng này là ngày 10. Bà con vui lòng đóng đúng hạn để tránh phạt trễ hạn.',
    },
    {
      'title': '🧹 Dọn vệ sinh chung',
      'content':
          'Thông báo: Chủ nhật này từ 7h-9h sẽ tổ chức dọn vệ sinh khu vực chung. Đề nghị bà con cùng tham gia!',
    },
    {
      'title': '🚗 Quy định để xe',
      'content':
          'Nhắc nhở quy định: Mỗi phòng chỉ được để tối đa 2 xe máy tại khu vực gửi xe. Các xe để sai vị trí sẽ bị di chuyển.',
    },
    {
      'title': '🔒 An ninh – Khóa cổng',
      'content':
          'Lưu ý: Cổng khu trọ sẽ đóng lúc 23h00 mỗi ngày. Bà con về trễ vui lòng nhắn tin cho bảo vệ trước.',
    },
  ];

  int get _ownerId {
    final user = ref.read(authProvider).value;
    if (user?.role == 'STAFF') {
      final assignments = ref.read(staffAssignmentProvider).assignments;
      return assignments.isNotEmpty ? assignments.first.ownerId : 0;
    }
    return user?.id ?? 0;
  }

  Future<void> _sendBroadcast() async {
    if (_selectedBranchId == null) {
      _showAlert('Lỗi', 'Vui lòng chọn khu trọ cần gửi!');
      return;
    }
    if (_ownerId == 0) {
      _showAlert(
        'Không xác định được chủ trọ',
        'Tài khoản của bạn chưa gắn với chủ trọ nào. Vui lòng liên hệ quản trị viên.',
      );
      return;
    }
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) {
      _showAlert('Lỗi', 'Tiêu đề và nội dung không được để trống!');
      return;
    }
    setState(() {
      _isLoading = true;
      _sentSuccess = false;
    });
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post(
        '/v1/notifications/owner-broadcast',
        data: {
          'ownerId': _ownerId,
          'branchId': _selectedBranchId,
          'title': _titleCtrl.text.trim(),
          'content': _contentCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      setState(() {
        _sentSuccess = true;
      });
      _titleCtrl.clear();
      _contentCtrl.clear();
    } catch (e) {
      if (mounted) _showAlert('Gửi thất bại', '$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAlert(String title, String msg) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(msg),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchProvider);

    return LiquidGlassScaffold(
      title: 'Gửi Thông Báo Hàng Loạt',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success banner
            if (_sentSuccess)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: Colors.green,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đã gửi thông báo thành công tới toàn bộ cư dân!',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Branch selector
            const Text(
              'CHỌN KHU TRỌ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),

            branchesAsync.when(
              data: (branches) => Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        alignment: Alignment.centerLeft,
                        onPressed: () {
                          if (branches.isEmpty) return;
                          var tempIndex = _selectedBranchId == null
                              ? 0
                              : branches.indexWhere(
                                  (b) => b.id == _selectedBranchId,
                                );
                          if (tempIndex < 0) tempIndex = 0;
                          unawaited(
                            showCupertinoModalPopup(
                              context: context,
                              builder: (popupCtx) => Container(
                                height: 250,
                                color: CupertinoColors.systemBackground,
                                child: Column(
                                  children: [
                                    // All branch option
                                    CupertinoButton(
                                      child: const Text('📢 Tất cả khu trọ'),
                                      onPressed: () {
                                        setState(() => _selectedBranchId = -1);
                                        Navigator.pop(popupCtx);
                                      },
                                    ),
                                    Expanded(
                                      child: CupertinoPicker(
                                        itemExtent: 44,
                                        scrollController:
                                            FixedExtentScrollController(
                                              initialItem: tempIndex,
                                            ),
                                        onSelectedItemChanged: (i) {
                                          tempIndex = i;
                                        },
                                        children: branches
                                            .map(
                                              (b) => Center(
                                                child: Text(b.branchName),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                    CupertinoButton(
                                      child: const Text(
                                        'Xong',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      onPressed: () {
                                        if (tempIndex >= 0 &&
                                            tempIndex < branches.length) {
                                          setState(
                                            () => _selectedBranchId =
                                                branches[tempIndex].id,
                                          );
                                        }
                                        Navigator.pop(popupCtx);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        child: Text(
                          _selectedBranchId == null
                              ? 'Chọn khu trọ...'
                              : _selectedBranchId == -1
                              ? '📢 Tất cả khu trọ'
                              : branches.isEmpty
                              ? 'Chọn khu trọ...'
                              : branches
                                    .firstWhere(
                                      (b) => b.id == _selectedBranchId,
                                      orElse: () => branches.first,
                                    )
                                    .branchName,
                          style: TextStyle(
                            color: _selectedBranchId != null
                                ? CupertinoColors.label
                                : CupertinoColors.systemGrey,
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(
                        CupertinoIcons.chevron_down,
                        size: 16,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const CupertinoActivityIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 20),

            // Quick templates
            const Text(
              'MẪU NHANH',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: _templates.length,
                itemBuilder: (_, i) {
                  final t = _templates[i];
                  return GestureDetector(
                    onTap: () => setState(() {
                      _titleCtrl.text = t['title']!;
                      _contentCtrl.text = t['content']!;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            LiquidGlassColors.tenantAccent.withValues(
                              alpha: 0.15,
                            ),
                            LiquidGlassColors.tenantAccent.withValues(
                              alpha: 0.05,
                            ),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: LiquidGlassColors.tenantAccent.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      child: Text(
                        t['title']!.split(' ').take(2).join(' '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: LiquidGlassColors.tenantAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Compose form
            const Text(
              'SOẠN THÔNG BÁO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: CupertinoTextField(
                controller: _titleCtrl,
                placeholder: 'Tiêu đề thông báo',
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: CupertinoTextField(
                controller: _contentCtrl,
                placeholder: 'Nội dung chi tiết...',
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(),
                maxLines: 5,
                minLines: 4,
              ),
            ),

            const SizedBox(height: 24),
            GlassButton(
              text: '📲 GỬI TỚI TẤT CẢ CƯ DÂN',
              icon: CupertinoIcons.paperplane_fill,
              color: LiquidGlassColors.tenantAccent,
              isLoading: _isLoading,
              onPressed: _sendBroadcast,
            ),

            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Thông báo sẽ xuất hiện ngay trên app của tất cả cư dân.',
                style: TextStyle(
                  fontSize: 11,
                  color: CupertinoColors.systemGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
