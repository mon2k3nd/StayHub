part of '../../create_branch_screen.dart';

// ignore: library_private_types_in_public_api
extension CreateBranchStepperExt on _CreateBranchScreenState {
  Widget _buildStepperHeader() {
    final stepLabels = ['Thông tin', 'Kinh doanh', 'Thiết lập', 'Tài chính'];

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Top bar: back + title + 3-dot menu ──────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  borderRadius: BorderRadius.circular(100),
                  child: const Icon(
                    CupertinoIcons.back,
                    color: Color(0xFF1C1C1E),
                    size: 20,
                  ),
                  onPressed: () => cancel(),
                ),
              ),
              const Text(
                'Tạo chi nhánh mới',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              // ── Ba chấm menu ──────────────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  borderRadius: BorderRadius.circular(100),
                  onPressed: () => _showOptionsMenu(),
                  child: const Icon(
                    CupertinoIcons.ellipsis_vertical,
                    color: Color(0xFF1C1C1E),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ── Step indicators ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStepIndicator(0, stepLabels[0]),
              _buildConnector(0),
              _buildStepIndicator(1, stepLabels[1]),
              _buildConnector(1),
              _buildStepIndicator(2, stepLabels[2]),
              _buildConnector(2),
              _buildStepIndicator(3, stepLabels[3]),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    unawaited(
      showCupertinoModalPopup<void>(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                if (!_isLoading) unawaited(saveDraft());
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.cube_box_fill,
                    color: Color(0xFF007AFF),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Lưu nháp',
                    style: TextStyle(
                      color: Color(0xFF007AFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(ctx);
                cancel();
              },
              child: const Text('Hủy'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ),
      ),
    );
  }

  Widget _buildConnector(int beforeStep) {
    final isActive = _currentStep > beforeStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final dashCount = (constraints.constrainWidth() / 4).floor();
            return Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(dashCount, (_) {
                return SizedBox(
                  width: 2,
                  height: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF0EA5E9)
                          : const Color(0xFFD1D5DB),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title) {
    final isActive = _currentStep >= stepIndex;
    final isPast = _currentStep > stepIndex;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: isActive ? 34 : 30,
          height: isActive ? 34 : 30,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0EA5E9) : const Color(0xFFF3F4F6),
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: isPast
              ? const Icon(
                  CupertinoIcons.checkmark_alt,
                  color: Colors.white,
                  size: 16,
                )
              : Text(
                  '${stepIndex + 1}',
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFF9CA3AF),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: TextStyle(
            color: isActive ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
