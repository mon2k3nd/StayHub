part of 'ekyc_verification_screen.dart';

/// UI + action helpers for the "verified" and "pending re-verify" states.
///
/// Extracted from [_EkycVerificationScreenState] to keep the state file
/// focused. These members never call `setState`, so they are safe to live
/// in an extension on the state class.
extension _EkycReverifyUi on _EkycVerificationScreenState {
  Future<void> _requestReverify() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.dio.post('/v1/tenant/ekyc/request-reverify');

      final currentUser = ref.read(authProvider).value;
      if (currentUser != null) {
        final updatedUser = UserEntity(
          id: currentUser.id,
          fullName: currentUser.fullName,
          phoneNumber: currentUser.phoneNumber,
          email: currentUser.email,
          role: currentUser.role,
          planType: currentUser.planType,
          bankName: currentUser.bankName,
          bankAccountNumber: currentUser.bankAccountNumber,
          bankAccountName: currentUser.bankAccountName,
          cccdNumber: currentUser.cccdNumber,
          cccdIssueDate: currentUser.cccdIssueDate,
          cccdIssuePlace: currentUser.cccdIssuePlace,
          emergencyContactName: currentUser.emergencyContactName,
          emergencyContactPhone: currentUser.emergencyContactPhone,
          vehicleType: currentUser.vehicleType,
          licensePlate: currentUser.licensePlate,
          hometown: currentUser.hometown,
          gender: currentUser.gender,
          dateOfBirth: currentUser.dateOfBirth,
          occupation: currentUser.occupation,
          ownerStatus: currentUser.ownerStatus,
          status: currentUser.status,
          signature: currentUser.signature,
          kycStatus: 'REVERIFY_REQUESTED',
          trustScore: currentUser.trustScore,
        );
        ref.read(authProvider.notifier).setUser(updatedUser);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã gửi yêu cầu xác thực lại. Vui lòng chờ Admin duyệt.',
            ),
            backgroundColor: CupertinoColors.activeGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: CupertinoColors.destructiveRed,
          ),
        );
      }
    }
  }

  Widget _buildVerifiedScreen(UserEntity user) {
    const skyBlue = Color(0xFF5FAEFF);
    const skyBlueLight = Color(0xFFE3F0FF);

    return LiquidGlassScaffold(
      title: 'Hồ sơ định danh',
      backgroundColors: const Color(0xFFF2F8FF), // Sky Blue 50
      useScrollView: true,
      child: Column(
        children: [
          // ── Hero Banner ──────────────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.kBrand, Color(0xFF1A6FD4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: skyBlue.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar / Icon area
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.checkmark_seal_fill,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đã Xác Thực Danh Tính',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.fullName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.shield_fill,
                              color: Colors.white,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Tin cậy cao',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Info Card ────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: skyBlue.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: skyBlueLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          CupertinoIcons.person_crop_rectangle_fill,
                          color: skyBlue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Thông tin định danh',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.kTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                _buildSkyInfoRow(
                  CupertinoIcons.person_fill,
                  'Họ và tên',
                  user.fullName,
                ),
                _buildSkyInfoRow(
                  CupertinoIcons.creditcard_fill,
                  'Số CCCD',
                  user.cccdNumber ?? 'N/A',
                ),
                _buildSkyInfoRow(
                  CupertinoIcons.calendar,
                  'Ngày sinh',
                  user.dateOfBirth != null
                      ? '${user.dateOfBirth!.day.toString().padLeft(2, '0')}/${user.dateOfBirth!.month.toString().padLeft(2, '0')}/${user.dateOfBirth!.year}'
                      : 'N/A',
                ),
                _buildSkyInfoRow(
                  CupertinoIcons.person_2_fill,
                  'Giới tính',
                  user.gender ?? 'N/A',
                ),
                _buildSkyInfoRow(
                  CupertinoIcons.map_fill,
                  'Quê quán',
                  user.hometown ?? 'N/A',
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Additional Info Card ─────────────────────────────
          if (user.occupation != null || user.cccdIssuePlace != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: skyBlue.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: skyBlueLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            CupertinoIcons.doc_text_fill,
                            color: skyBlue,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Chi tiết CCCD',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.kTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  if (user.cccdIssuePlace != null)
                    _buildSkyInfoRow(
                      CupertinoIcons.location_fill,
                      'Nơi cấp',
                      user.cccdIssuePlace!,
                    ),
                  if (user.cccdIssueDate != null)
                    _buildSkyInfoRow(
                      CupertinoIcons.calendar_badge_plus,
                      'Ngày cấp',
                      '${user.cccdIssueDate!.day.toString().padLeft(2, '0')}/${user.cccdIssueDate!.month.toString().padLeft(2, '0')}/${user.cccdIssueDate!.year}',
                    ),
                  if (user.occupation != null)
                    _buildSkyInfoRow(
                      CupertinoIcons.briefcase_fill,
                      'Nghề nghiệp',
                      user.occupation!,
                      isLast: true,
                    ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // ── Re-verify Button ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                onPressed: () => _showReverifyConfirm(),
                padding: EdgeInsets.zero,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.refresh_circled,
                        color: Color(0xFFEA580C),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Yêu cầu xác thực lại',
                        style: TextStyle(
                          color: Color(0xFFEA580C),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showReverifyConfirm() {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Xác nhận yêu cầu'),
          content: const Text(
            'Bạn có chắc muốn gửi yêu cầu xác thực lại không?\nAdmin sẽ xem xét và phê duyệt trước khi bạn có thể quét lại.',
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Huỷ'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(_requestReverify());
              },
              child: const Text('Gửi yêu cầu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkyInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.kBrand),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppTheme.kTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 48,
            endIndent: 20,
            color: Color(0xFFF1F5F9),
          ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.kTextSecondary, fontSize: 14),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingReverifyScreen() {
    const skyBlue = AppTheme.kBrand;
    const skyBlueLight = Color(0xFFE3F0FF);

    return LiquidGlassScaffold(
      title: 'Hồ sơ định danh',
      backgroundColors: const Color(0xFFF2F8FF),
      useScrollView: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Animated icon container ──────────────────────
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.clock_fill,
                  color: Color(0xFFEA580C),
                  size: 52,
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'Đang Chờ Phê Duyệt',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.kTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Yêu cầu xác thực lại hồ sơ của bạn đã được gửi thành công và đang được Admin xem xét.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // ── Status card ──────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: skyBlueLight),
                  boxShadow: [
                    BoxShadow(
                      color: skyBlue.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildStatusStep(
                      icon: CupertinoIcons.checkmark_circle_fill,
                      color: const Color(0xFF22C55E),
                      title: 'Yêu cầu đã gửi',
                      subtitle: 'Hệ thống đã nhận yêu cầu của bạn',
                      isDone: true,
                    ),
                    const SizedBox(height: 16),
                    _buildStatusStep(
                      icon: CupertinoIcons.hourglass,
                      color: const Color(0xFFEA580C),
                      title: 'Admin xem xét',
                      subtitle: 'Đang trong quá trình phê duyệt',
                      isDone: false,
                      isActive: true,
                    ),
                    const SizedBox(height: 16),
                    _buildStatusStep(
                      icon: CupertinoIcons.lock_open_fill,
                      color: skyBlue,
                      title: 'Mở khoá xác thực',
                      subtitle: 'Bạn sẽ có thể quét CCCD lại',
                      isDone: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Back button ──────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.kBrand, Color(0xFF1A6FD4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: skyBlue.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Về trang chính',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
    );
  }

  Widget _buildStatusStep({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isDone,
    bool isActive = false,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDone || isActive
                ? color.withValues(alpha: 0.12)
                : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isDone || isActive ? color : const Color(0xFFCBD5E1),
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isDone || isActive
                      ? AppTheme.kTextPrimary
                      : const Color(0xFF94A3B8),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDone || isActive
                      ? const Color(0xFF6B7280)
                      : const Color(0xFFCBD5E1),
                ),
              ),
            ],
          ),
        ),
        if (isDone)
          const Icon(
            CupertinoIcons.checkmark_alt_circle_fill,
            color: Color(0xFF22C55E),
            size: 18,
          ),
        if (isActive)
          const Icon(
            CupertinoIcons.ellipsis_circle_fill,
            color: Color(0xFFEA580C),
            size: 18,
          ),
      ],
    );
  }
}
