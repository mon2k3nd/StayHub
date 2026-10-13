import 'dart:async' show unawaited;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Theme;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/components/bounce_click.dart';
import '../../../core/components/safe_network_image.dart';
import '../../../core/components/stayhub_main_header.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/presentation/settings_screen.dart'
    show SettingsSignatureDialog;
import '../../marketplace/presentation/owner_viewing_schedules_screen.dart';
import '../../marketplace/presentation/wishlist_screen.dart';
import '../../marketplace/application/wishlist_provider.dart';
import '../../contract/application/contract_notifier.dart';
import '../../bill/application/bill_notifier.dart';
import '../../bill/data/models/bill_model.dart';
import '../../bill/presentation/split_bill_screen.dart';
import '../../contract/presentation/room_inspection_screen.dart';
import '../../tenant/presentation/bank_config_screen.dart';
import '../../tenant/presentation/business_landing_screen.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/utils/toast_utils.dart';
import '../../dashboard/application/owner_demo_mode_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _useBiometric = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    unawaited(_pulseController.repeat(reverse: true));
    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.20, end: 0.65).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return _buildGuestProfile(context, isDark);
    }

    final isOwner = user.role == 'OWNER';
    final initials = _getInitials(user.fullName);

    // Lấy số liệu động cho các lối tắt thường dùng (Live Counts)
    final wishlistState = ref.watch(wishlistProvider);
    final wishlistCount = wishlistState.ids.length;

    final contractsAsync = ref.watch(contractProvider);
    final contracts = contractsAsync.value ?? [];
    final activeContractCount = contracts
        .where((c) => c.status.toUpperCase() == 'ACTIVE' || c.status.toUpperCase() == 'APPROVED')
        .length;

    final billsAsync = ref.watch(billProvider);
    final bills = billsAsync.value ?? [];
    final unpaidBills = bills
        .where((b) => b.status.toUpperCase() == 'UNPAID' || b.status.toUpperCase() == 'OVERDUE')
        .toList();
    final unpaidBillCount = unpaidBills.length;

    // Trạng thái xác thực eKYC
    final kycStatus = user.kycStatus ?? 'UNVERIFIED';
    final isVerified = kycStatus == 'VERIFIED';
    final isPending = kycStatus == 'PENDING';
    final isUnverified = !isVerified && !isPending;

    // Tính toán độ hoàn thiện hồ sơ
    int completionCount = 0;
    if (user.phoneNumber.trim().isNotEmpty) {
      completionCount++;
    }
    if (user.email != null && user.email!.trim().isNotEmpty) {
      completionCount++;
    }
    if (isVerified) {
      completionCount++;
    }
    if (user.signature != null && user.signature!.trim().isNotEmpty) {
      completionCount++;
    }
    final completionPercent = ((completionCount / 4) * 100).toInt();

    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + 62.0;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppTheme.kBackgroundLight,
      child: Stack(
        children: [
          // 1. Vùng nội dung cuộn bên dưới
          CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.only(
                  top: headerHeight,
                  left: 18,
                  right: 18,
                  bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      // ── 1. HERO PROFILE CARD (Thẻ hồ sơ Kính mờ siêu cấp) ─────────────
            _buildHeroProfileCard(
              context,
              user,
              isOwner,
              initials,
              isDark,
              isVerified: isVerified,
              isPending: isPending,
              isUnverified: isUnverified,
              completionPercent: completionPercent,
            ),
            const SizedBox(height: 14),

            // ── 1.1. BANNER CẢNH BÁO TÀI KHOẢN CHƯA XÁC THỰC (PULSING GLOW) ──
            if (!isVerified) ...[
              _buildVerificationAlertBanner(
                context,
                isPending: isPending,
                isDark: isDark,
              ),
              const SizedBox(height: 14),
            ] else ...[
              const SizedBox(height: 4),
            ],

            // ── 1.2. THẺ TÍN NHIỆM THUÊ NHÀ 3D (STAYHUB CITIZEN PASSPORT) ─────
            _buildTrustPassportCard(
              context,
              user,
              isDark,
              isVerified: isVerified,
            ),
            const SizedBox(height: 18),

            // ── 2. TIỆN ÍCH THƯỜNG DÙNG (Quick Shortcuts Hub) ─────────────────
            _buildQuickActionsHeader(
              title: 'LỐI TẮT THƯỜNG DÙNG',
              badge: 'Truy cập nhanh',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildQuickShortcutsGrid(
              context,
              isOwner,
              isDark,
              wishlistCount: wishlistCount,
              activeContractCount: activeContractCount,
              unpaidBillCount: unpaidBillCount,
            ),
            const SizedBox(height: 28),

            // ── 3. DANH MỤC: TÀI CHÍNH & PHÁP LÝ ──────────────────────────────
            _buildSectionHeader('TÀI CHÍNH & PHÁP LÝ', isDark),
            _buildMenuCard(
              isDark: isDark,
              children: [
                // Mục eKYC với trạng thái nổi bật
                _buildActionRow(
                  icon: isVerified
                      ? CupertinoIcons.checkmark_seal_fill
                      : CupertinoIcons.shield_lefthalf_fill,
                  title: 'Xác thực danh tính (eKYC)',
                  subtitle: isVerified
                      ? 'Đã xác minh CCCD gắn chip ✓'
                      : (isPending
                          ? 'Đang chờ xét duyệt hồ sơ'
                          : 'Chưa xác thực — Cần hoàn tất'),
                  palette: isVerified ? Sky3DPalette.emeraldSky : Sky3DPalette.amberSky,
                  isDark: isDark,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? (isDark
                              ? const Color(0xFF10B981).withValues(alpha: 0.18)
                              : const Color(0xFFD1FAE5))
                          : (isPending
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFFEE2E2)),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: isVerified
                            ? const Color(0xFF10B981).withValues(alpha: 0.4)
                            : (isPending
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                                : const Color(0xFFEF4444).withValues(alpha: 0.4)),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      isVerified
                          ? 'Đã duyệt'
                          : (isPending ? 'Đang duyệt' : 'Chưa xong'),
                      style: TextStyle(
                        color: isVerified
                            ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857))
                            : (isPending
                                ? const Color(0xFFB45309)
                                : const Color(0xFFDC2626)),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  onTap: () {
                    unawaited(context.push('/ekyc-verification'));
                  },
                ),
                _buildDivider(isDark),
                _buildActionRow(
                  icon: CupertinoIcons.creditcard_fill,
                  title: 'Thiết lập Ngân hàng',
                  subtitle: 'Kết nối tài khoản nhận tiền VietQR',
                  palette: Sky3DPalette.emeraldSky,
                  isDark: isDark,
                  onTap: () {
                    unawaited(
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => const BankConfigScreen(),
                        ),
                      ),
                    );
                  },
                ),
                _buildDivider(isDark),
                _buildActionRow(
                  icon: CupertinoIcons.signature,
                  title: 'Chữ ký điện tử',
                  subtitle: 'Dùng ký hợp đồng & duyệt khách trực tuyến',
                  palette: Sky3DPalette.royalSky,
                  isDark: isDark,
                  onTap: () {
                    unawaited(
                      showCupertinoModalPopup(
                        context: context,
                        builder: (ctx) => const SettingsSignatureDialog(),
                      ),
                    );
                  },
                ),
                _buildDivider(isDark),
                _buildActionRow(
                  icon: CupertinoIcons.person_3_fill,
                  title: 'Chia tiền phòng (Split-Bill)',
                  subtitle: 'Tạo mã VietQR chia tiền ở ghép cho bạn cùng phòng',
                  palette: Sky3DPalette.oceanSky,
                  isDark: isDark,
                  onTap: () => _openSplitBillAction(context),
                ),
                _buildDivider(isDark),
                _buildActionRow(
                  icon: CupertinoIcons.checkmark_rectangle_fill,
                  title: 'Biên bản nhận phòng & Kiểm kê',
                  subtitle: 'Chụp ảnh hiện trạng đồ đạc chống mất cọc',
                  palette: Sky3DPalette.cyanSky,
                  isDark: isDark,
                  onTap: () => _openRoomInspectionAction(context),
                ),
                if (isOwner) ...[
                  _buildDivider(isDark),
                  _buildActionRow(
                    icon: CupertinoIcons.briefcase_fill,
                    title: 'Trang Doanh nghiệp',
                    subtitle: 'Quản lý thông tin môi giới & thương hiệu',
                    palette: Sky3DPalette.violetSky,
                    isDark: isDark,
                    onTap: () {
                      unawaited(
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => const BusinessLandingScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // ── 4. DANH MỤC: CÀI ĐẶT & BẢO MẬT ─────────────────────────────────
            _buildSectionHeader('CÀI ĐẶT & BẢO MẬT', isDark),
            _buildMenuCard(
              isDark: isDark,
              children: [
                _buildToggleRow(
                  icon: CupertinoIcons.lock_shield_fill,
                  title: 'Đăng nhập Sinh trắc học',
                  subtitle: 'Sử dụng FaceID hoặc Vân tay',
                  value: _useBiometric,
                  palette: Sky3DPalette.indigoSky,
                  isDark: isDark,
                  onChanged: (val) {
                    setState(() => _useBiometric = val);
                  },
                ),
                _buildDivider(isDark),
                _buildActionRow(
                  icon: CupertinoIcons.bell_fill,
                  title: 'Cấu hình thông báo',
                  subtitle: 'Chuông, rung & thông báo đẩy',
                  palette: Sky3DPalette.cyanSky,
                  isDark: isDark,
                  onTap: () => _showNotificationSheet(context),
                ),
                _buildDivider(isDark),
                _buildActionRow(
                  icon: CupertinoIcons.globe,
                  title: 'Ngôn ngữ ứng dụng',
                  subtitle: 'Tiếng Việt (Mặc định)',
                  palette: Sky3DPalette.azureSky,
                  isDark: isDark,
                  onTap: () => _showLanguagePicker(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── 5. DANH MỤC: HỖ TRỢ & ĐIỀU KHOẢN ───────────────────────────────
            _buildSectionHeader('HỖ TRỢ & ĐIỀU KHOẢN', isDark),
            _buildMenuCard(
              isDark: isDark,
              children: [
                _buildActionRow(
                  icon: CupertinoIcons.headphones,
                  title: 'Trung tâm trợ giúp 24/7',
                  subtitle: 'Hotline 1900 6789 & Hỗ trợ kỹ thuật',
                  palette: Sky3DPalette.amberSky,
                  isDark: isDark,
                  onTap: () => _showHelpCenter(context),
                ),
                _buildDivider(isDark),
                _buildActionRow(
                  icon: CupertinoIcons.doc_checkmark_fill,
                  title: 'Điều khoản & Chính sách',
                  subtitle: 'Quy định bảo mật & sử dụng StayHub',
                  palette: Sky3DPalette.slateSky,
                  isDark: isDark,
                  onTap: () => _showTerms(context),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── 6. NÚT ĐĂNG XUẤT (Pill-shape sang trọng & an toàn) ──────────────
            BounceClick(
              scaleFactor: 0.96,
              onPressed: () => _confirmLogout(context, ref),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: const Color(0xFFFCA5A5).withValues(alpha: isDark ? 0.35 : 0.8),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.08 : 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.square_arrow_right,
                      size: 18,
                      color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Đăng Xuất Tài Khoản',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 2. Sticky Glass Header ghim cố định trên đỉnh
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  color: (isDark ? const Color(0xFF0F172A) : AppTheme.kBackgroundLight)
                      .withValues(alpha: 0.85),
                  padding: EdgeInsets.only(
                    top: topPadding,
                    left: 18,
                    right: 18,
                    bottom: 10,
                  ),
                  child: const StayHubMainHeader(
                    padding: EdgeInsets.zero,
                    rightActions: [],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. HERO PROFILE CARD ─────────────────────────────────────────────────────

  Widget _buildHeroProfileCard(
    BuildContext context,
    dynamic user,
    bool isOwner,
    String initials,
    bool isDark, {
    required bool isVerified,
    required bool isPending,
    required bool isUnverified,
    required int completionPercent,
  }) {
    final phone = user.phoneNumber;
    final hasPhone = phone != null && phone.toString().trim().isNotEmpty;
    final email = user.email;
    final hasEmail = email != null && email.toString().trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.82)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF69B1FF).withValues(alpha: isDark ? 0.30 : 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF69B1FF).withValues(alpha: isDark ? 0.10 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row Avatar + Tên + Nút Edit
          Row(
            children: [
              // Avatar với Halo 3D viền sáng
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isVerified
                            ? const [Color(0xFF6EE7B7), Color(0xFF10B981), Color(0xFF047857)]
                            : const [Color(0xFFBAE6FD), Color(0xFF38BDF8), Color(0xFF1D4ED8)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isVerified ? const Color(0xFF10B981) : const Color(0xFF69B1FF))
                              .withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: user.avatar != null && user.avatar!.isNotEmpty
                          ? SafeNetworkImage(
                              url: user.avatar!,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              memCacheWidth: 200,
                              errorWidget: _buildInitials(initials),
                            )
                          : _buildInitials(initials),
                    ),
                  ),

                  // Nút Camera mini đổi avatar
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: BounceClick(
                      scaleFactor: 0.88,
                      onPressed: () {
                        unawaited(context.push('/avatar-update'));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF69B1FF), Color(0xFF2563EB)],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF0F172A) : Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.camera_fill,
                          color: CupertinoColors.white,
                          size: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // Cột Tên & Các Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.isNotEmpty ? user.fullName : 'Thành viên StayHub',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Badges Vai trò, Gói và Trạng thái Xác thực
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // Badge vai trò
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF69B1FF).withValues(alpha: 0.20)
                                : const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: const Color(0xFF69B1FF).withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            isOwner ? '👑 Chủ nhà' : '🏡 Khách thuê',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF0284C7),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        // Nút Quản lý vai trò & Onboarding Trở thành Chủ nhà (Become a Host)
                        Builder(
                          builder: (ctx) {
                            final ownerStatus = user.ownerStatus;
                            final isPending = ownerStatus == 'PENDING_VERIFICATION';
                            final isRejected = ownerStatus == 'REJECTED';

                            final Color btnBg;
                            final Color btnBorder;
                            final Color btnText;
                            final IconData btnIcon;
                            final String btnLabel;

                            if (isOwner) {
                              btnBg = isDark
                                  ? const Color(0xFF6366F1).withValues(alpha: 0.20)
                                  : const Color(0xFFEEF2FF);
                              btnBorder = const Color(0xFF6366F1).withValues(alpha: 0.4);
                              btnText = isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5);
                              btnIcon = CupertinoIcons.lock_shield_fill;
                              btnLabel = '🏢 Quản trị Chủ nhà';
                            } else if (isPending) {
                              btnBg = isDark
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.20)
                                  : const Color(0xFFFEF3C7);
                              btnBorder = const Color(0xFFF59E0B).withValues(alpha: 0.5);
                              btnText = isDark ? const Color(0xFFFCD34D) : const Color(0xFFD97706);
                              btnIcon = CupertinoIcons.clock_fill;
                              btnLabel = 'Chờ duyệt Chủ nhà';
                            } else if (isRejected) {
                              btnBg = isDark
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.20)
                                  : const Color(0xFFFEE2E2);
                              btnBorder = const Color(0xFFEF4444).withValues(alpha: 0.5);
                              btnText = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
                              btnIcon = CupertinoIcons.exclamationmark_triangle_fill;
                              btnLabel = 'Bổ sung hồ sơ';
                            } else {
                              btnBg = isDark
                                  ? AppTheme.kBrand.withValues(alpha: 0.20)
                                  : const Color(0xFFE0F2FE);
                              btnBorder = AppTheme.kBrand.withValues(alpha: 0.45);
                              btnText = isDark ? const Color(0xFFBAE6FD) : const Color(0xFF0284C7);
                              btnIcon = CupertinoIcons.sparkles;
                              btnLabel = '👑 Trở thành Chủ nhà';
                            }

                            return BounceClick(
                              scaleFactor: 0.92,
                              onPressed: () => _handleRoleAction(context, user, isOwner),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: btnBg,
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(color: btnBorder, width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(btnIcon, size: 10.5, color: btnText),
                                    const SizedBox(width: 3.5),
                                    Text(
                                      btnLabel,
                                      style: TextStyle(
                                        color: btnText,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // Huy hiệu Xác Thực Danh Tính (eKYC Badge)
                        BounceClick(
                          scaleFactor: 0.92,
                          onPressed: () {
                            if (!isVerified) {
                              unawaited(context.push('/ekyc-verification'));
                            }
                          },
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: isVerified
                                      ? (isDark
                                          ? const Color(0xFF10B981).withValues(alpha: 0.20)
                                          : const Color(0xFFD1FAE5))
                                      : (isPending
                                          ? (isDark
                                              ? const Color(0xFFF59E0B).withValues(alpha: 0.20)
                                              : const Color(0xFFFEF3C7))
                                          : (isDark
                                              ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                              : const Color(0xFFFEE2E2))),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color: isVerified
                                        ? const Color(0xFF10B981).withValues(alpha: 0.45)
                                        : (isPending
                                            ? const Color(0xFFF59E0B).withValues(alpha: 0.45)
                                            : const Color(0xFFEF4444).withValues(
                                                alpha: isUnverified ? _glowAnimation.value : 0.4,
                                              )),
                                    width: isUnverified ? 1.1 : 0.8,
                                  ),
                                  boxShadow: isUnverified
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFFEF4444).withValues(
                                              alpha: _glowAnimation.value * 0.4,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isUnverified) ...[
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEF4444),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      isVerified
                                          ? '✓ Đã eKYC'
                                          : (isPending ? '⏳ Đang duyệt' : '⚠️ Chưa eKYC'),
                                      style: TextStyle(
                                        color: isVerified
                                            ? (isDark
                                                ? const Color(0xFF6EE7B7)
                                                : const Color(0xFF047857))
                                            : (isPending
                                                ? (isDark
                                                    ? const Color(0xFFFCD34D)
                                                    : const Color(0xFFB45309))
                                                : (isDark
                                                    ? const Color(0xFFFCA5A5)
                                                    : const Color(0xFFDC2626))),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Nút Chỉnh sửa hồ sơ nhanh
              BounceClick(
                scaleFactor: 0.90,
                onPressed: () {
                  unawaited(
                    context.push(
                      '/profile-update',
                      extra: {
                        'nextRoute': isOwner ? '/owner-dashboard' : '/tenant-dashboard',
                      },
                    ),
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.14)
                          : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      CupertinoIcons.pencil,
                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                      size: 17,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Thanh Tiến Trình Hoàn Thiện Hồ Sơ (Profile Completion Bar) ─────
          BounceClick(
            scaleFactor: 0.98,
            onPressed: () {
              if (!isVerified) {
                unawaited(context.push('/ekyc-verification'));
              } else {
                unawaited(context.push('/profile-update'));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isVerified
                                ? CupertinoIcons.checkmark_shield_fill
                                : CupertinoIcons.shield_fill,
                            size: 13,
                            color: isVerified
                                ? const Color(0xFF10B981)
                                : const Color(0xFF38BDF8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Độ hoàn thiện hồ sơ',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$completionPercent%',
                        style: TextStyle(
                          color: isVerified
                              ? const Color(0xFF10B981)
                              : (isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB)),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Custom Gradient Progress Track
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 5,
                      width: double.infinity,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFFE2E8F0),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: (completionPercent / 100.0).clamp(0.05, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              colors: isVerified
                                  ? const [Color(0xFF34D399), Color(0xFF059669)]
                                  : const [Color(0xFF69B1FF), Color(0xFF2563EB)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Divider mờ
          Container(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFF1F5F9),
          ),

          const SizedBox(height: 12),

          // Dải Thông Tin Liên Hệ Rút Gọn
          Row(
            children: [
              // Chip SĐT
              Expanded(
                child: BounceClick(
                  scaleFactor: 0.97,
                  onPressed: () {
                    if (hasPhone) {
                      Clipboard.setData(ClipboardData(text: phone.toString()));
                      _toast(context, 'Đã sao chép SĐT: $phone');
                    } else {
                      unawaited(context.push('/profile-update'));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE2E8F0),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.phone_fill,
                          size: 13,
                          color: Color(0xFF38BDF8),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            hasPhone ? phone.toString() : 'Thêm SĐT',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: hasPhone
                                  ? (isDark ? Colors.white70 : const Color(0xFF334155))
                                  : const Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Chip Email
              Expanded(
                child: BounceClick(
                  scaleFactor: 0.97,
                  onPressed: () {
                    if (hasEmail) {
                      Clipboard.setData(ClipboardData(text: email.toString()));
                      _toast(context, 'Đã sao chép Email: $email');
                    } else {
                      unawaited(context.push('/profile-update'));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE2E8F0),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.mail_solid,
                          size: 13,
                          color: Color(0xFF38BDF8),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            hasEmail ? email.toString() : 'Thêm Email',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: hasEmail
                                  ? (isDark ? Colors.white70 : const Color(0xFF334155))
                                  : const Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 1.1. BANNER CẢNH BÁO TÀI KHOẢN CHƯA XÁC THỰC (PULSING GLOW) ──────────────

  Widget _buildVerificationAlertBanner(
    BuildContext context, {
    required bool isPending,
    required bool isDark,
  }) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isPending
                  ? (isDark
                      ? [
                          const Color(0xFF78350F).withValues(alpha: 0.35),
                          const Color(0xFF1E293B).withValues(alpha: 0.85),
                        ]
                      : [
                          const Color(0xFFFEF3C7),
                          const Color(0xFFFFFBEB),
                        ])
                  : (isDark
                      ? [
                          const Color(0xFF7F1D1D).withValues(alpha: 0.35),
                          const Color(0xFF1E293B).withValues(alpha: 0.85),
                        ]
                      : [
                          const Color(0xFFFFF1F2),
                          const Color(0xFFFEF2F2),
                        ]),
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isPending
                  ? const Color(0xFFF59E0B).withValues(alpha: _glowAnimation.value)
                  : const Color(0xFFEF4444).withValues(alpha: _glowAnimation.value),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isPending ? const Color(0xFFF59E0B) : const Color(0xFFEF4444))
                    .withValues(alpha: _glowAnimation.value * 0.28),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon 3D Shield Nhấp Nháy Nhẹ
              Transform.scale(
                scale: _pulseAnimation.value,
                child: StayHub3DIcon(
                  icon: isPending
                      ? CupertinoIcons.hourglass
                      : CupertinoIcons.shield_lefthalf_fill,
                  size: 44,
                  iconSize: 22,
                  palette: isPending ? Sky3DPalette.amberSky : Sky3DPalette.roseSky,
                ),
              ),
              const SizedBox(width: 14),

              // Nội dung thông báo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPending
                          ? 'Đang xét duyệt danh tính eKYC'
                          : 'Tài khoản chưa xác thực danh tính',
                      style: TextStyle(
                        color: isPending
                            ? (isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309))
                            : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626)),
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isPending
                          ? 'Hồ sơ CCCD đang được thẩm định. Dự kiến hoàn tất trong 1-2 giờ.'
                          : 'Xác thực CCCD trong 1 phút để bảo vệ tiền cọc và ký hợp đồng online.',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Nút CTA Pill-shape
              BounceClick(
                scaleFactor: 0.92,
                onPressed: () {
                  unawaited(context.push('/ekyc-verification'));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7.5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPending
                          ? const [Color(0xFFFBBF24), Color(0xFFD97706)]
                          : const [Color(0xFFFB7185), Color(0xFFE11D48)],
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: (isPending ? const Color(0xFFD97706) : const Color(0xFFE11D48))
                            .withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    isPending ? 'Xem lại' : 'Xác thực',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 2. TIỆN ÍCH THƯỜNG DÙNG (Quick Shortcuts Grid) ───────────────────────────

  Widget _buildQuickShortcutsGrid(
    BuildContext context,
    bool isOwner,
    bool isDark, {
    required int wishlistCount,
    required int activeContractCount,
    required int unpaidBillCount,
  }) {
    if (isOwner) {
      return Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _buildShortcutTile(
                  title: 'Lịch Xem Phòng',
                  subtitle: 'Khách hẹn xem phòng',
                  icon: CupertinoIcons.calendar,
                  palette: Sky3DPalette.oceanSky,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    unawaited(
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => const OwnerViewingSchedulesScreen(),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildShortcutTile(
                  title: 'Hóa Đơn & Thu',
                  subtitle: unpaidBillCount > 0
                      ? '$unpaidBillCount cần thu tiền'
                      : 'Đã thu đầy đủ',
                  icon: CupertinoIcons.money_dollar_circle_fill,
                  palette: Sky3DPalette.emeraldSky,
                  isDark: isDark,
                  badgeText: unpaidBillCount > 0 ? '$unpaidBillCount' : null,
                  badgeColor: unpaidBillCount > 0 ? const Color(0xFFF59E0B) : null,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    unawaited(context.push('/bill'));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                _buildShortcutTile(
                  title: 'Hợp Đồng Thuê',
                  subtitle: activeContractCount > 0
                      ? '$activeContractCount HĐ khách thuê'
                      : 'Quản lý hợp đồng',
                  icon: CupertinoIcons.doc_text_fill,
                  palette: Sky3DPalette.indigoSky,
                  isDark: isDark,
                  badgeText: activeContractCount > 0 ? '$activeContractCount HĐ' : null,
                  badgeColor: const Color(0xFF10B981),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    unawaited(context.push('/contract'));
                  },
                ),
                const SizedBox(height: 10),
                _buildShortcutTile(
                  title: 'Trang Doanh Nghiệp',
                  subtitle: 'Hồ sơ môi giới',
                  icon: CupertinoIcons.building_2_fill,
                  palette: Sky3DPalette.royalSky,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    unawaited(
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => const BusinessLandingScreen(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 4 Lối tắt thường dùng cho Khách Thuê (Tích hợp Live Data thực tế)
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildShortcutTile(
                title: 'Phòng Đã Lưu',
                subtitle: wishlistCount > 0
                    ? '$wishlistCount phòng yêu thích'
                    : 'Chưa lưu phòng nào',
                icon: CupertinoIcons.heart_fill,
                palette: Sky3DPalette.roseSky,
                isDark: isDark,
                badgeText: wishlistCount > 0 ? '$wishlistCount' : null,
                badgeColor: const Color(0xFFEF4444),
                onTap: () {
                  HapticFeedback.lightImpact();
                  unawaited(
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => const WishlistScreen(),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildShortcutTile(
                title: 'Hóa Đơn Của Tôi',
                subtitle: unpaidBillCount > 0
                    ? '$unpaidBillCount cần thanh toán'
                    : 'Đã thanh toán hết',
                icon: CupertinoIcons.money_dollar_circle_fill,
                palette: Sky3DPalette.emeraldSky,
                isDark: isDark,
                badgeText: unpaidBillCount > 0 ? '⚠️ $unpaidBillCount' : null,
                badgeColor: const Color(0xFFEF4444),
                onTap: () {
                  HapticFeedback.lightImpact();
                  unawaited(context.push('/bill'));
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              _buildShortcutTile(
                title: 'Hợp Đồng Thuê',
                subtitle: activeContractCount > 0
                    ? '$activeContractCount HĐ hiệu lực'
                    : 'Quản lý thuê nhà',
                icon: CupertinoIcons.doc_text_fill,
                palette: Sky3DPalette.indigoSky,
                isDark: isDark,
                badgeText: activeContractCount > 0 ? '$activeContractCount HĐ' : null,
                badgeColor: const Color(0xFF10B981),
                onTap: () {
                  HapticFeedback.lightImpact();
                  unawaited(context.push('/contract'));
                },
              ),
              const SizedBox(height: 10),
              _buildShortcutTile(
                title: 'Đã Xem Gần Đây',
                subtitle: 'Lịch sử phòng xem',
                icon: CupertinoIcons.clock_fill,
                palette: Sky3DPalette.oceanSky,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.lightImpact();
                  unawaited(context.push('/viewed-history'));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Sky3DPalette palette,
    required bool isDark,
    required VoidCallback onTap,
    String? badgeText,
    Color? badgeColor,
  }) {
    return BounceClick(
      scaleFactor: 0.94,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B).withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF69B1FF).withValues(alpha: isDark ? 0.22 : 0.16),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF69B1FF).withValues(alpha: isDark ? 0.08 : 0.07),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            StayHub3DIcon(
              icon: icon,
              size: 42,
              iconSize: 20,
              palette: palette,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? const Color(0xFF2563EB)).withValues(alpha: isDark ? 0.25 : 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: (badgeColor ?? const Color(0xFF2563EB)).withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: badgeColor ?? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8)),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 13,
              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }

  // ── 3. TIỆN ÍCH DÒNG DANH MỤC ────────────────────────────────────────────────

  Widget _buildQuickActionsHeader({
    required String title,
    required String badge,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 2),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF69B1FF).withValues(alpha: 0.16)
                : const Color(0xFF69B1FF).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF69B1FF).withValues(alpha: 0.3),
              width: 0.8,
            ),
          ),
          child: Text(
            badge,
            style: TextStyle(
              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.82)
            : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF69B1FF).withValues(alpha: isDark ? 0.20 : 0.14),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF69B1FF).withValues(alpha: isDark ? 0.08 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(left: 68, right: 16),
      height: 1,
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : const Color(0xFFF1F5F9),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Sky3DPalette palette,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return BounceClick(
      scaleFactor: 0.97,
      onPressed: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            StayHub3DIcon(
              icon: icon,
              size: 40,
              iconSize: 19,
              palette: palette,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              trailing,
              const SizedBox(width: 6),
            ],
            Icon(
              CupertinoIcons.chevron_right,
              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
              size: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Sky3DPalette palette,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          StayHub3DIcon(
            icon: icon,
            size: 40,
            iconSize: 19,
            palette: palette,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: const Color(0xFF2563EB),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ── 4. GUEST PROFILE ─────────────────────────────────────────────────────────

  Widget _buildGuestProfile(BuildContext context, bool isDark) {
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + 62.0;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppTheme.kBackgroundLight,
      child: Stack(
        children: [
          // 1. Vùng nội dung cuộn bên dưới
          CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.only(
                  top: headerHeight,
                  left: 18,
                  right: 18,
                  bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

            // Hero Card Guest Mode
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF69B1FF).withValues(alpha: isDark ? 0.30 : 0.22),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF69B1FF).withValues(alpha: isDark ? 0.12 : 0.14),
                    blurRadius: 26,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const StayHub3DIcon(
                    icon: CupertinoIcons.person_solid,
                    size: 78,
                    iconSize: 38,
                    palette: Sky3DPalette.oceanSky,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mở Khóa Toàn Bộ Tiện Ích',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                      fontSize: 21,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Đăng nhập để thuê phòng, xem hợp đồng, chat trực tiếp cùng chủ nhà và thanh toán an toàn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Expanded(
                        child: BounceClick(
                          scaleFactor: 0.95,
                          onPressed: () => unawaited(context.push('/login')),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF69B1FF), Color(0xFF2563EB)],
                              ),
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'Đăng Nhập',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BounceClick(
                          scaleFactor: 0.95,
                          onPressed: () => unawaited(context.push('/register')),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF69B1FF).withValues(alpha: 0.15)
                                  : const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: const Color(0xFF69B1FF).withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Đăng Ký',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF0284C7),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // HOẠT ĐỘNG CỦA TÔI
            _buildSectionHeader('HOẠT ĐỘNG CỦA TÔI', isDark),
            _buildMenuCard(
              isDark: isDark,
              children: [
                _buildActionRow(
                  icon: CupertinoIcons.time_solid,
                  title: 'Phòng đã xem',
                  subtitle: 'Lịch sử tìm kiếm gần đây',
                  palette: Sky3DPalette.oceanSky,
                  isDark: isDark,
                  onTap: () => unawaited(context.push('/viewed-history')),
                ),
                _buildDivider(isDark),
                _buildActionRow(
                  icon: CupertinoIcons.heart_fill,
                  title: 'Phòng đã lưu',
                  subtitle: 'Danh sách yêu thích cục bộ',
                  palette: Sky3DPalette.roseSky,
                  isDark: isDark,
                  onTap: () => unawaited(context.push('/saved-rooms')),
                ),
                _buildDivider(isDark),
                _buildActionRow(
                  icon: CupertinoIcons.arrow_left_right,
                  title: 'So sánh phòng',
                  subtitle: 'So sánh tối đa 3 phòng cùng lúc',
                  palette: Sky3DPalette.violetSky,
                  isDark: isDark,
                  onTap: () => unawaited(context.push('/compare-rooms')),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // CÀI ĐẶT & HỖ TRỢ
            _buildSectionHeader('CÀI ĐẶT & HỖ TRỢ', isDark),
            _buildMenuCard(
              isDark: isDark,
              children: [
                _buildActionRow(
                  icon: CupertinoIcons.globe,
                  title: 'Ngôn ngữ',
                  subtitle: 'Tiếng Việt (Mặc định)',
                  palette: Sky3DPalette.azureSky,
                  isDark: isDark,
                  onTap: () => _showLanguagePicker(context),
                ),
                _buildDivider(isDark),
                _buildActionRow(
                  icon: CupertinoIcons.headphones,
                  title: 'Trung tâm trợ giúp 24/7',
                  subtitle: 'Hỗ trợ khách hàng qua hotline & email',
                  palette: Sky3DPalette.amberSky,
                  isDark: isDark,
                  onTap: () => _showHelpCenter(context),
                ),
                _buildDivider(isDark),
                _buildActionRow(
                  icon: CupertinoIcons.doc_checkmark_fill,
                  title: 'Điều khoản dịch vụ',
                  subtitle: 'Quy định sử dụng nền tảng StayHub',
                  palette: Sky3DPalette.slateSky,
                  isDark: isDark,
                  onTap: () => _showTerms(context),
                ),
              ],
            ),

            const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 2. Sticky Glass Header ghim cố định trên đỉnh
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  color: (isDark ? const Color(0xFF0F172A) : AppTheme.kBackgroundLight)
                      .withValues(alpha: 0.85),
                  padding: EdgeInsets.only(
                    top: topPadding,
                    left: 18,
                    right: 18,
                    bottom: 10,
                  ),
                  child: const StayHubMainHeader(
                    padding: EdgeInsets.zero,
                    rightActions: [],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPER DIALOGS & ACTION SHEETS ──────────────────────────────────────────

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text(
          'Đăng xuất tài khoản',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        message: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng StayHub?'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Đăng Xuất Ngay'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Hủy'),
        ),
      ),
    );
  }

  void _showNotificationSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Cấu hình thông báo'),
        message: const Text('Tùy chỉnh nhận thông báo tiền phòng & tin nhắn'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _toast(context, 'Đã bật thông báo đẩy và nhắc hạn tiền phòng.');
            },
            child: const Text('Bật tất cả thông báo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _toast(context, 'Đã chuyển sang chế độ im lặng.');
            },
            child: const Text('Chỉ nhận nhắc nhở quan trọng'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Đóng'),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Chọn ngôn ngữ'),
        message: const Text('Ngôn ngữ hiển thị của ứng dụng StayHub'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _toast(context, 'Đã chọn: Tiếng Việt');
            },
            child: const Text('🇻🇳 Tiếng Việt (Mặc định)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _toast(context, 'English sẽ sớm được hỗ trợ đầy đủ.');
            },
            child: const Text('🇬🇧 English'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Hủy'),
        ),
      ),
    );
  }

  void _showHelpCenter(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Trung tâm trợ giúp 24/7'),
        message: const Text('Chúng tôi luôn sẵn sàng hỗ trợ bạn qua các kênh:'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              Clipboard.setData(const ClipboardData(text: '19006789'));
              _toast(context, 'Hotline: 1900 6789 (Đã sao chép số)');
            },
            child: const Text('📞 Hotline: 1900 6789'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              Clipboard.setData(const ClipboardData(text: 'support@stayhub.vn'));
              _toast(context, 'Email: support@stayhub.vn (Đã sao chép)');
            },
            child: const Text('✉️ Email: support@stayhub.vn'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Đóng'),
        ),
      ),
    );
  }

  void _showTerms(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Điều khoản & Chính sách StayHub'),
        message: const Text(
          '• Thông tin phòng thuê và giá được kiểm duyệt minh bạch.\n'
          '• Hợp đồng điện tử có giá trị pháp lý theo chuẩn e-Signature.\n'
          '• Dữ liệu cá nhân và lịch sử giao dịch được bảo mật tuyệt đối.\n'
          '• Hỗ trợ giải quyết tranh chấp 24/7 theo quy định pháp luật.',
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _toast(context, 'Cảm ơn bạn đã tin tưởng StayHub');
            },
            child: const Text('Tôi đã hiểu'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Đóng'),
        ),
      ),
    );
  }

  void _handleRoleAction(BuildContext context, dynamic user, bool isOwner) {
    HapticFeedback.lightImpact();

    // 1. Nếu tài khoản đã là Chủ nhà: Chuyển vào Dashboard có bảo vệ Sinh trắc học (Face ID / Vân tay)
    if (isOwner) {
      unawaited(_enterOwnerDashboardWithBiometric(context));
      return;
    }

    // 2. Nếu người dùng chưa phải Chủ nhà: Kiểm tra trạng thái hồ sơ thẩm định
    final ownerStatus = user.ownerStatus;
    if (ownerStatus == 'PENDING_VERIFICATION') {
      _showOwnerPendingSheet(context, user);
    } else if (ownerStatus == 'REJECTED') {
      _showOwnerRejectedSheet(context, user);
    } else {
      _showBecomeHostOnboardingSheet(context, user);
    }
  }

  /// Xác thực sinh trắc học trước khi chuyển vào Dashboard Chủ nhà để bảo vệ doanh thu & dữ liệu nhạy cảm
  Future<void> _enterOwnerDashboardWithBiometric(BuildContext context) async {
    final canBiometric = await BiometricService().isBiometricAvailable();
    if (canBiometric) {
      final success = await BiometricService().authenticate();
      if (!success) {
        if (context.mounted) {
          ToastUtils.show(
            context,
            'Xác thực bảo mật không thành công. Giữ an toàn dữ liệu.',
            isError: true,
          );
        }
        return;
      }
    }
    if (context.mounted) {
      context.go('/owner-dashboard');
    }
  }

  /// Sheet thông báo hồ sơ đang xét duyệt trong vòng 24h
  void _showOwnerPendingSheet(BuildContext context, dynamic user) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
        decoration: const BoxDecoration(
          color: Color(0xFFF9FAFB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
              ),
              child: const Center(
                child: Icon(
                  CupertinoIcons.hourglass,
                  color: Color(0xFFD97706),
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hồ sơ Chủ nhà đang được xét duyệt',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Text(
                'PENDING VERIFICATION • TỐI ĐA 24H',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB45309),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'StayHub đã tiếp nhận hồ sơ kinh doanh và giấy tờ định danh của bạn. Ban quản trị đang thẩm định cơ sở trọ để đảm bảo môi trường lưu trú an toàn, chống lừa đảo cọc.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Mã hồ sơ: #HOST-SH-${user.id} • Bạn sẽ nhận thông báo đẩy ngay khi kích hoạt!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontFamily: 'Courier',
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Center(
                  child: Text(
                    'Đã hiểu & Đóng',
                    style: TextStyle(
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sheet thông báo hồ sơ bị từ chối và cần bổ sung
  void _showOwnerRejectedSheet(BuildContext context, dynamic user) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
        decoration: const BoxDecoration(
          color: Color(0xFFF9FAFB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
              ),
              child: const Center(
                child: Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  color: Color(0xFFDC2626),
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hồ sơ đối tác cần bổ sung tài liệu',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Hồ sơ đăng ký Chủ nhà trước đó chưa đạt yêu cầu (hình ảnh CCCD mờ hoặc thiếu địa chỉ dãy trọ). Vui lòng cập nhật lại thông tin để tiếp tục.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => const BusinessLandingScreen(),
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF69B1FF), Color(0xFF4A90E2)],
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Center(
                  child: Text(
                    'Cập nhật lại hồ sơ đối tác',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Center(
                  child: Text(
                    'Đóng',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Modal Sheet Onboarding "Trở thành Đối tác Chủ nhà StayHub" (Become a Host Flow)
  void _showBecomeHostOnboardingSheet(BuildContext context, dynamic user) {
    showCupertinoModalPopup<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.84,
        decoration: const BoxDecoration(
          color: Color(0xFFF9FAFB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Grab handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.kBrand.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      CupertinoIcons.sparkles,
                      color: AppTheme.kBrand,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trở thành Chủ nhà StayHub',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Nâng cấp tài khoản & Vận hành phòng thông minh',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(ctx),
                    child: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: Color(0xFF94A3B8),
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            Container(height: 1, color: const Color(0xFFE2E8F0)),

            // Content Scroll
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  // Banner giới thiệu
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEBF5FF), Color(0xFFF0F4FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.kBrand.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1069B1FF),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.building_2_fill,
                            color: AppTheme.kBrand,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mạng lưới 5.000+ Chủ trọ 4.0',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Tối ưu tỷ lệ lấp đầy phòng lên đến 98% và giảm 80% thời gian quản lý thủ công.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF475569),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'QUYỀN LỢI ĐỐI TÁC CHỦ NHÀ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                      letterSpacing: 1.0,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Feature 1
                  _buildBenefitCard(
                    icon: CupertinoIcons.rocket_fill,
                    iconColor: const Color(0xFF3B82F6),
                    title: 'Đăng tin & Lấp đầy phòng siêu tốc',
                    description:
                        'Phòng trọ hiển thị ưu tiên trên Marketplace thông minh với WalkScore VN, AI Living Cost và bản đồ 3D.',
                  ),
                  const SizedBox(height: 10),

                  // Feature 2
                  _buildBenefitCard(
                    icon: CupertinoIcons.bolt_fill,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'Tự động hóa vận hành 100%',
                    description:
                        'Thu tiền phòng qua QR động Napas, chốt số công tơ điện nước bằng camera AI, tự động nhắc nợ văn minh.',
                  ),
                  const SizedBox(height: 10),

                  // Feature 3
                  _buildBenefitCard(
                    icon: CupertinoIcons.checkmark_shield_fill,
                    iconColor: AppTheme.kSuccess,
                    title: 'Bảo vệ pháp lý & Biên bản bàn giao số',
                    description:
                        'Hợp đồng điện tử ký số chuẩn 2026, biên bản bàn giao phòng chống tranh chấp cọc và tra cứu Blacklist khách nợ xấu.',
                  ),

                  const SizedBox(height: 16),

                  // Hộp cảnh báo yêu cầu định danh (Chống chuyển chế độ bừa bãi)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          CupertinoIcons.shield_lefthalf_fill,
                          color: Color(0xFFD97706),
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Quy định bảo chứng: Để bảo vệ quyền lợi người thuê, đối tác cần xác thực CCCD (eKYC) và thông tin cơ sở lưu trú trước khi được cấp quyền quản trị phòng.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF92400E),
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Nút Đăng ký ngay
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.pop(ctx);
                      unawaited(
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => const BusinessLandingScreen(),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF69B1FF), Color(0xFF4A90E2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x3369B1FF),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.doc_checkmark_fill,
                              color: CupertinoColors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Đăng ký & Nộp hồ sơ Chủ nhà',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Nút Trải nghiệm thử Dashboard trước (Demo Sandbox)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.pop(ctx);
                      ref.read(ownerDemoModeProvider.notifier).setDemoMode(true);
                      context.go('/owner-dashboard');
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.sparkles,
                              color: Color(0xFFD97706),
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '✨ Khám phá thử Dashboard (Xem trước)',
                              style: TextStyle(
                                color: Color(0xFFB45309),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(ctx),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Center(
                        child: Text(
                          'Để sau',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            message,
            style: const TextStyle(fontSize: 14, height: 1.3),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildInitials(String initials) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE3F0FF),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFF1D4ED8),
          fontWeight: FontWeight.w800,
          fontSize: 26,
        ),
      ),
    );
  }

  // ── 1.2. WIDGET THẺ TÍN NHIỆM THUÊ NHÀ 3D (STAYHUB CITIZEN PASSPORT) ────────

  Widget _buildTrustPassportCard(
    BuildContext context,
    dynamic user,
    bool isDark, {
    required bool isVerified,
  }) {
    final trustScore = isVerified ? 850 : 420;
    final rankName = isVerified ? 'Hạng Kim Cương 💎' : 'Chưa Kích Hoạt';
    final progressFactor = (trustScore / 1000.0).clamp(0.1, 1.0);

    return BounceClick(
      scaleFactor: 0.98,
      onPressed: () {
        HapticFeedback.lightImpact();
        _showTrustPassportModal(context, user, isVerified);
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isVerified
                ? (isDark
                    ? const [
                        Color(0xFF0F172A),
                        Color(0xFF1E293B),
                        Color(0xFF064E3B),
                      ]
                    : const [
                        Color(0xFF0F2027),
                        Color(0xFF203A43),
                        Color(0xFF2C5364),
                      ])
                : (isDark
                    ? const [
                        Color(0xFF1E293B),
                        Color(0xFF334155),
                        Color(0xFF0F172A),
                      ]
                    : const [
                        Color(0xFF334155),
                        Color(0xFF475569),
                        Color(0xFF1E293B),
                      ]),
          ),
          border: Border.all(
            color: isVerified
                ? const Color(0xFF69B1FF).withValues(alpha: 0.45)
                : const Color(0xFFF59E0B).withValues(alpha: 0.35),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: isVerified
                  ? const Color(0xFF69B1FF).withValues(alpha: 0.16)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Chip vi mạch 3D + Tiêu đề Passport + Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Giả lập Smart Chip kim loại vàng 3D
                    Container(
                      width: 38,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFDF00),
                            Color(0xFFD4AF37),
                            Color(0xFF996515),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFFFFBEB).withValues(alpha: 0.8),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 26,
                          height: 18,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF78350F).withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STAYHUB CITIZEN PASSPORT',
                          style: TextStyle(
                            color: isVerified
                                ? const Color(0xFFFDE68A)
                                : const Color(0xFFCBD5E1),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Hộ Chiếu Tín Nhiệm Thuê Nhà',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Badge trạng thái
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? const Color(0xFF10B981).withValues(alpha: 0.25)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isVerified
                          ? const Color(0xFF34D399)
                          : const Color(0xFFFBBF24),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVerified
                            ? CupertinoIcons.checkmark_seal_fill
                            : CupertinoIcons.lock_fill,
                        size: 11,
                        color: isVerified
                            ? const Color(0xFF34D399)
                            : const Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isVerified ? 'CHỨNG THỰC' : 'CHƯA MỞ',
                        style: TextStyle(
                          color: isVerified
                              ? const Color(0xFF34D399)
                              : const Color(0xFFFBBF24),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Điểm tín nhiệm lớn & Xếp hạng
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$trustScore',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    '/ 1000 Điểm',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rankName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Thanh tiến trình tín nhiệm Gradient
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 6,
                width: double.infinity,
                color: Colors.white.withValues(alpha: 0.15),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progressFactor,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: isVerified
                            ? const [
                                Color(0xFF38BDF8),
                                Color(0xFF34D399),
                                Color(0xFFFBBF24),
                              ]
                            : const [
                                Color(0xFFF59E0B),
                                Color(0xFFD97706),
                              ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 3 Chip đặc quyền đã mở khóa
            Row(
              children: [
                _buildPrivilegeChip(
                  icon: CupertinoIcons.money_dollar_circle,
                  label: 'Cọc 0đ bảo lãnh',
                  isActive: isVerified,
                ),
                const SizedBox(width: 6),
                _buildPrivilegeChip(
                  icon: CupertinoIcons.bolt_fill,
                  label: 'Duyệt tức thì',
                  isActive: isVerified,
                ),
                const SizedBox(width: 6),
                _buildPrivilegeChip(
                  icon: CupertinoIcons.shield_lefthalf_fill,
                  label: 'Hợp đồng 3 cấp',
                  isActive: isVerified,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Lời kêu gọi hành động (Call To Action link)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isVerified
                      ? '✦ Đang hưởng trọn vẹn đặc quyền thuê phòng cao cấp'
                      : '✦ Kích hoạt eKYC nhận ngay +200 điểm tín nhiệm',
                  style: TextStyle(
                    color: isVerified
                        ? const Color(0xFF67E8F9)
                        : const Color(0xFFFDE68A),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Row(
                  children: [
                    Text(
                      'Chi tiết',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 11,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivilegeChip({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.06),
            width: 0.7,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 11,
              color: isActive ? const Color(0xFF67E8F9) : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTrustPassportModal(
    BuildContext context,
    dynamic user,
    bool isVerified,
  ) {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  // Thanh gạt (Drag indicator)
                  Container(
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header Modal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hộ Chiếu Tín Nhiệm StayHub',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Chuẩn mực tín nhiệm dành cho khách thuê văn minh',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.xmark,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bảng chi tiết cấu thành điểm
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF69B1FF).withValues(alpha: 0.25),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CẤU THÀNH ĐIỂM TÍN NHIỆM',
                                  style: TextStyle(
                                    color: Color(0xFF69B1FF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildScoreRow(
                                  title: 'Định danh eKYC CCCD 2026',
                                  score: isVerified ? '+200' : '0',
                                  isDone: isVerified,
                                ),
                                const SizedBox(height: 8),
                                _buildScoreRow(
                                  title: 'Thanh toán tiền phòng đúng hạn',
                                  score: isVerified ? '+350' : '+200',
                                  isDone: true,
                                ),
                                const SizedBox(height: 8),
                                _buildScoreRow(
                                  title: 'Ký Hợp đồng số & Nghiệm thu phòng',
                                  score: isVerified ? '+150' : '+120',
                                  isDone: true,
                                ),
                                const SizedBox(height: 8),
                                _buildScoreRow(
                                  title: 'Đánh giá văn minh từ Chủ nhà (5.0★)',
                                  score: isVerified ? '+150' : '+100',
                                  isDone: true,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Danh sách 4 đặc quyền
                          const Text(
                            'ĐẶC QUYỀN ĐỘC QUYỀN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 10),

                          _buildBenefitItem(
                            icon: CupertinoIcons.shield_lefthalf_fill,
                            title: 'Bảo Lãnh Tiền Cọc 0 Đồng',
                            desc: 'StayHub đứng ra bảo lãnh cọc phòng lên đến 15.000.000đ khi thuê trọ.',
                          ),
                          _buildBenefitItem(
                            icon: CupertinoIcons.bolt_horizontal_circle_fill,
                            title: 'Duyệt Phòng Ưu Tiên Fast-Pass',
                            desc: 'Hồ sơ thuê phòng được chủ nhà phê duyệt tự động trong vòng 15 phút.',
                          ),
                          _buildBenefitItem(
                            icon: CupertinoIcons.doc_checkmark_fill,
                            title: 'Hợp Đồng Điện Tử 3 Cấp Chuẩn 2026',
                            desc: 'Được bảo hộ pháp lý trực tiếp với chữ ký số sinh trắc học có giá trị pháp lý.',
                          ),
                          _buildBenefitItem(
                            icon: CupertinoIcons.person_3_fill,
                            title: 'Chia Tiền Phòng Split-Bill Tự Động',
                            desc: 'Tự động tạo mã VietQR chia tiền cho bạn cùng phòng với từng khoản minh bạch.',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Nút Action
                  SizedBox(
                    width: double.infinity,
                    child: BounceClick(
                      scaleFactor: 0.96,
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (!isVerified) {
                          unawaited(context.push('/ekyc-verification'));
                        } else {
                          Clipboard.setData(
                            ClipboardData(
                              text: 'STAYHUB-PASSPORT-${user.id ?? 8892}-VERIFIED',
                            ),
                          );
                          _toast(context, 'Đã sao chép mã Hộ Chiếu Tín Nhiệm StayHub!');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: !isVerified
                                ? const [Color(0xFF38BDF8), Color(0xFF2563EB)]
                                : const [Color(0xFF34D399), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: (!isVerified
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF059669))
                                  .withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            !isVerified
                                ? 'Xác thực CCCD nhận ngay +200 điểm 🚀'
                                : 'Chia sẻ Hộ Chiếu Tín Nhiệm',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
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

  Widget _buildScoreRow({
    required String title,
    required String score,
    required bool isDone,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              isDone ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
              size: 15,
              color: isDone ? const Color(0xFF34D399) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isDone ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Text(
          score,
          style: TextStyle(
            color: isDone ? const Color(0xFF34D399) : const Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF69B1FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF38BDF8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 1.3. LỐI TẮT CHIA TIỀN PHÒNG & BIÊN BẢN NHẬN PHÒNG ───────────────────────

  void _openSplitBillAction(BuildContext context) {
    HapticFeedback.lightImpact();
    final bills = ref.read(billProvider).value ?? [];
    if (bills.isNotEmpty) {
      final billToSplit = bills.firstWhere(
        (b) => b.status != 'PAID',
        orElse: () => bills.first,
      );
      unawaited(
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => SplitBillScreen(bill: billToSplit),
          ),
        ),
      );
    } else {
      final sampleBill = BillModel(
        id: 0,
        roomId: 302,
        month: DateTime.now().month,
        year: DateTime.now().year,
        totalAmount: 4500000,
        rentAmount: 3500000,
        electricAmount: 650000,
        waterAmount: 200000,
        serviceAmount: 150000,
        status: 'UNPAID',
        createdAt: DateTime.now(),
      );
      unawaited(
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => SplitBillScreen(bill: sampleBill),
          ),
        ),
      );
    }
  }

  void _openRoomInspectionAction(BuildContext context) {
    HapticFeedback.lightImpact();
    final contracts = ref.read(contractProvider).value ?? [];
    final activeContract = contracts
        .where((c) => c.status.toUpperCase() == 'ACTIVE')
        .firstOrNull;
    if (activeContract != null && activeContract.roomId > 0) {
      unawaited(
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => RoomInspectionScreen(roomId: activeContract.roomId),
          ),
        ),
      );
    } else {
      _showSimpleDialog(
        context,
        title: 'Biên bản nhận phòng',
        message: 'Bạn chưa có hợp đồng thuê phòng nào đang hoạt động. Khi hoàn tất hợp đồng thuê, bạn sẽ tiến hành chụp ảnh kiểm kê hiện trạng nội thất tại đây để bảo vệ 100% tiền cọc.',
      );
    }
  }

  void _showSimpleDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(title),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(message),
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
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'SH';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'SH';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

// ── 5. WIDGET ICON 3D CHUẨN TÔNG XANH SKY (Sky3DIcon) ─────────────────────────

/// Bảng màu biến thể 3D tông Sky Blue thanh lịch
enum Sky3DPalette {
  oceanSky(
    gradient: [Color(0xFFBAE6FD), Color(0xFF38BDF8), Color(0xFF2563EB), Color(0xFF1D4ED8)],
    shadow: Color(0xFF38BDF8),
  ),
  azureSky(
    gradient: [Color(0xFFE0F2FE), Color(0xFF60A5FA), Color(0xFF3B82F6), Color(0xFF1E40AF)],
    shadow: Color(0xFF60A5FA),
  ),
  emeraldSky(
    gradient: [Color(0xFFA7F3D0), Color(0xFF34D399), Color(0xFF059669), Color(0xFF047857)],
    shadow: Color(0xFF34D399),
  ),
  indigoSky(
    gradient: [Color(0xFFC7D2FE), Color(0xFF818CF8), Color(0xFF4F46E5), Color(0xFF3730A3)],
    shadow: Color(0xFF818CF8),
  ),
  violetSky(
    gradient: [Color(0xFFDDD6FE), Color(0xFFA78BFA), Color(0xFF7C3AED), Color(0xFF5B21B6)],
    shadow: Color(0xFFA78BFA),
  ),
  roseSky(
    gradient: [Color(0xFFFECDD3), Color(0xFFFB7185), Color(0xFFE11D48), Color(0xFFBE123C)],
    shadow: Color(0xFFFB7185),
  ),
  amberSky(
    gradient: [Color(0xFFFDE68A), Color(0xFFFBBF24), Color(0xFFD97706), Color(0xFFB45309)],
    shadow: Color(0xFFFBBF24),
  ),
  slateSky(
    gradient: [Color(0xFFE2E8F0), Color(0xFF94A3B8), Color(0xFF475569), Color(0xFF334155)],
    shadow: Color(0xFF94A3B8),
  ),
  royalSky(
    gradient: [Color(0xFF93C5FD), Color(0xFF69B1FF), Color(0xFF1D4ED8), Color(0xFF0F172A)],
    shadow: Color(0xFF69B1FF),
  ),
  cyanSky(
    gradient: [Color(0xFFA5F3FC), Color(0xFF22D3EE), Color(0xFF0891B2), Color(0xFF0E7490)],
    shadow: Color(0xFF22D3EE),
  );

  final List<Color> gradient;
  final Color shadow;

  const Sky3DPalette({
    required this.gradient,
    required this.shadow,
  });
}

/// Widget icon 3D hiệu ứng bóng đổ lan tỏa, vòm kính phản quang và khối đa tầng
class StayHub3DIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final Sky3DPalette palette;
  final Color iconColor;

  const StayHub3DIcon({
    super.key,
    required this.icon,
    this.size = 44,
    this.iconSize = 20,
    this.palette = Sky3DPalette.oceanSky,
    this.iconColor = CupertinoColors.white,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(size * 0.32);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Lớp Đế Đổ Bóng 3D Đa Tầng
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: palette.shadow.withValues(alpha: 0.38),
                  blurRadius: size * 0.28,
                  offset: Offset(0, size * 0.12),
                ),
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                  blurRadius: size * 0.12,
                  offset: Offset(0, size * 0.06),
                ),
              ],
            ),
          ),

          // 2. Thân Khối Gradient 3D
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette.gradient,
                stops: const [0.0, 0.35, 0.75, 1.0],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.70),
                width: 1.1,
              ),
            ),
            child: Stack(
              children: [
                // 3. Lớp Phản Quang Vòm Kính 3D (3D Gloss Dome Highlight)
                Positioned(
                  top: 1,
                  left: 2,
                  right: 2,
                  height: size * 0.44,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(size * 0.28),
                      topRight: Radius.circular(size * 0.28),
                      bottomLeft: Radius.circular(size * 0.22),
                      bottomRight: Radius.circular(size * 0.22),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.55),
                            Colors.white.withValues(alpha: 0.04),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Biểu Tượng Trung Tâm 3D với Drop Shadow
                Center(
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: iconColor,
                    shadows: [
                      Shadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.45),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
