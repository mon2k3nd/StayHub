part of '../../create_branch_screen.dart';

// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api

extension CreateBranchBottomBarExt on _CreateBranchScreenState {
  Widget _buildBottomBar() {
    final isLast = _currentStep == 3;
    // Strict gate: the button is disabled whenever the current step's draft is
    // incomplete/invalid, or a branch-code check is pending/taken. This prevents
    // the "bypass state" bug where an invalid step still looked actionable.
    final isBlocked = !_isCurrentStepValid || _isLoading;

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB).withValues(alpha: 0.92),
            border: const Border(
              top: BorderSide(color: Color(0x12000000), width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  // ── Nút Trở về ──────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF0F2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      borderRadius: BorderRadius.circular(100),
                      onPressed: () {
                        unawaited(HapticFeedback.mediumImpact());
                        if (_currentStep > 0) {
                          unawaited(
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                            ),
                          );
                          setState(() => _currentStep--);
                        } else {
                          context.go('/branch');
                        }
                      },
                      minimumSize: const Size(0, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.chevron_back,
                            size: 16,
                            color: Color(0xFF374151),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _currentStep > 0 ? 'Trở về' : 'Thoát',
                            style: const TextStyle(
                              color: Color(0xFF374151),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // ── Nút Tiếp tục / Hoàn tất ──────────────
                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      onTap: isBlocked
                          ? null
                          : () {
                              unawaited(HapticFeedback.lightImpact());
                              // Final authoritative validation before advancing (defence in depth).
                              if (!_validateCurrentStep()) return;
                              if (_currentStep == 0 && _isBranchCodeTaken) {
                                return;
                              }
                              if (isLast) {
                                showSummaryConfirmDialog();
                              } else {
                                if (_currentStep == 0 && !_hasFetchedPOIs) {
                                  unawaited(_fetchPOIs());
                                }
                                unawaited(
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 350),
                                    curve: Curves.easeOutCubic,
                                  ),
                                );
                                setState(() => _currentStep++);
                              }
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: isBlocked
                              ? null
                              : LinearGradient(
                                  colors: isLast
                                      ? [
                                          const Color(0xFF10B981),
                                          const Color(0xFF059669),
                                        ]
                                      : [
                                          const Color(0xFF0EA5E9),
                                          const Color(0xFF0284C7),
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          color: isBlocked ? const Color(0xFFD1D5DB) : null,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: isBlocked
                              ? []
                              : [
                                  BoxShadow(
                                    color:
                                        (isLast
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFF0EA5E9))
                                            .withValues(alpha: 0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                        ),
                        alignment: Alignment.center,
                        child: _isLoading
                            ? const CupertinoActivityIndicator(
                                color: Colors.white,
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isLast ? '🎉 Hoàn tất' : 'Tiếp tục',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: isBlocked
                                          ? const Color(0xFF9CA3AF)
                                          : Colors.white,
                                    ),
                                  ),
                                  if (!isLast) ...const [
                                    SizedBox(width: 6),
                                    Icon(
                                      CupertinoIcons.chevron_forward,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
