import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/branch_model.dart';
import 'dart:async' show unawaited;

class BranchOptionsSheet extends StatefulWidget {
  final BranchModel branch;
  final VoidCallback onEdit;
  final VoidCallback onMeter;
  final VoidCallback onPools;
  final VoidCallback onHistory;
  final VoidCallback onLeakage;
  final VoidCallback onDelete;

  const BranchOptionsSheet({
    super.key,
    required this.branch,
    required this.onEdit,
    required this.onMeter,
    required this.onPools,
    required this.onHistory,
    required this.onLeakage,
    required this.onDelete,
  });

  @override
  State<BranchOptionsSheet> createState() => BranchOptionsSheetState();
}

class BranchOptionsSheetState extends State<BranchOptionsSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  /// Chi nhánh đang ở trạng thái khởi tạo (chưa hoàn tất 4 bước).
  /// DRAFT → "Hủy" (xóa hẳn, giải phóng mã); ngược lại → "Ngừng hoạt động".
  bool get _isDraft => widget.branch.creationStatus == 'DRAFT';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.building_2_fill,
                      color: Color(0xFF0EA5E9),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.branch.branchName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Quản lý chi nhánh',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: Color(0xFFD1D5DB),
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildAnimatedItem(
                      0,
                      'Chỉnh sửa chi nhánh',
                      'Cập nhật thông tin, bảng giá',
                      CupertinoIcons.pencil_outline,
                      const Color(0xFF0EA5E9),
                      widget.onEdit,
                    ),
                    _buildAnimatedItem(
                      1,
                      'Điện nước',
                      'Ghi chỉ số điện nước hàng tháng',
                      CupertinoIcons.bolt_fill,
                      const Color(0xFFF59E0B),
                      widget.onMeter,
                    ),
                    _buildAnimatedItem(
                      2,
                      'Nhóm tiện ích',
                      'Quản lý giá dịch vụ chung',
                      CupertinoIcons.cube_box_fill,
                      const Color(0xFF8B5CF6),
                      widget.onPools,
                    ),
                    _buildAnimatedItem(
                      3,
                      'Lịch sử đồng hồ',
                      'Xem biến động chỉ số',
                      CupertinoIcons.list_bullet_below_rectangle,
                      const Color(0xFF10B981),
                      widget.onHistory,
                    ),
                    _buildAnimatedItem(
                      4,
                      'Thống kê rò rỉ',
                      'Phân tích thất thoát tiện ích',
                      CupertinoIcons.chart_bar_alt_fill,
                      const Color(0xFFEC4899),
                      widget.onLeakage,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Color(0xFFE5E7EB), height: 1),
                    ),
                    _buildAnimatedItem(
                      5,
                      _isDraft ? 'Hủy chi nhánh' : 'Ngừng hoạt động',
                      _isDraft
                          ? 'Mã chi nhánh sẽ được giải phóng hoàn toàn'
                          : 'Ẩn chi nhánh, giữ lại lịch sử',
                      _isDraft
                          ? CupertinoIcons.xmark_circle_fill
                          : CupertinoIcons.pause_circle_fill,
                      const Color(0xFFEF4444),
                      widget.onDelete,
                      isDestructive: true,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedItem(
    int index,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.1 * index, 1.0, curve: Curves.easeOutBack),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          onTap();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDestructive
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFF3F4F6),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? const Color(0xFFFEF2F2)
                      : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? const Color(0xFFEF4444) : color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDestructive
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDestructive
                            ? const Color(0xFFF87171)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: isDestructive
                    ? const Color(0xFFFCA5A5)
                    : const Color(0xFFD1D5DB),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
