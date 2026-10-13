import 'dart:ui';
import 'package:flutter/cupertino.dart';

import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/stayhub_main_header.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/application/auth_notifier.dart';
import 'dart:async' show unawaited;

class BusinessLandingScreen extends ConsumerStatefulWidget {
  const BusinessLandingScreen({super.key});

  @override
  ConsumerState<BusinessLandingScreen> createState() =>
      _BusinessLandingScreenState();
}

class _BusinessLandingScreenState extends ConsumerState<BusinessLandingScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _branchNameCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _cccdCtrl = TextEditingController();
  final TextEditingController _cccdIssueDateCtrl = TextEditingController();
  final TextEditingController _hometownCtrl = TextEditingController();

  XFile? _cccdFront;
  XFile? _cccdBack;
  XFile? _businessLicense;

  late AnimationController _btnAnimCtrl;
  late Animation<double> _btnScaleAnim;

  @override
  void initState() {
    super.initState();
    _btnAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _btnScaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _btnAnimCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _branchNameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _descCtrl.dispose();
    _fullNameCtrl.dispose();
    _cccdCtrl.dispose();
    _cccdIssueDateCtrl.dispose();
    _hometownCtrl.dispose();
    _btnAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final isGuest = user == null;

    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + 62.0;

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.kBackgroundLight,
      child: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(top: headerHeight, bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLandingSection(),
                if (isGuest)
                  _buildGuestAction(context)
                else
                  _buildRegistrationForm(),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  color: AppTheme.kBackgroundLight.withValues(alpha: 0.85),
                  padding: EdgeInsets.only(
                    top: topPadding,
                    left: 24,
                    right: 24,
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

  Widget _buildGuestAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          const Text(
            'Bạn cần có tài khoản để bắt đầu.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF4B5563), fontSize: 15),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              try {
                unawaited(context.push('/login'));
              } catch (_) {}
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.kBrandLight, AppTheme.kBrandDeep],
                ),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.kBrandDeep.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Đăng nhập / Đăng ký ngay',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandingSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: LiquidGlassColors.ownerAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'DÀNH CHO CHỦ NHÀ',
              style: TextStyle(
                color: LiquidGlassColors.ownerAccent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Khởi Tạo Doanh Nghiệp\nCủa Riêng Bạn.',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tham gia hệ sinh thái StayHub để tối ưu hóa việc quản lý dãy trọ, tăng cường tự động hóa và nâng tầm chuyên nghiệp với các công cụ quản lý toàn diện.',
            style: TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          _buildInfoCard(
            icon: CupertinoIcons.chart_bar_alt_fill,
            title: 'Quản lý Tài chính',
            desc:
                'Theo dõi doanh thu, chi phí và lợi nhuận trực quan qua biểu đồ động 6 tháng.',
            color: AppTheme.kBrand,
            imagePath: 'assets/images/features/ai_financial.png',
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: CupertinoIcons.doc_checkmark_fill,
            title: 'Hợp đồng tự động',
            desc:
                'Ký kết và gia hạn hợp đồng trực tuyến, hoàn toàn không cần giấy tờ.',
            color: AppTheme.kBrand,
            imagePath: 'assets/images/features/smart_contract.png',
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: CupertinoIcons.person_3_fill,
            title: 'Quản lý Khách thuê',
            desc:
                'Kiểm soát thông tin, yêu cầu hỗ trợ và hóa đơn của từng phòng dễ dàng.',
            color: AppTheme.kWarning,
            imagePath: 'assets/images/features/multi_property.png',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    String? imagePath,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(imagePath == null ? 12 : 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: imagePath == null
                ? Icon(icon, color: color, size: 28)
                : Image.asset(
                    imagePath,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                    errorBuilder: (_, __, ___) =>
                        Icon(icon, color: color, size: 28),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Consumer(
        builder: (context, ref, child) {
          final user = ref.watch(authProvider).value;
          final isPending = user?.ownerStatus == 'PENDING_VERIFICATION';

          bool isKycVerified = false;
          if (user != null) {
            if (_fullNameCtrl.text.isEmpty) _fullNameCtrl.text = user.fullName;
            if (_phoneCtrl.text.isEmpty) _phoneCtrl.text = user.phoneNumber;
            if (_emailCtrl.text.isEmpty) _emailCtrl.text = user.email ?? '';
            if (_cccdCtrl.text.isEmpty) _cccdCtrl.text = user.cccdNumber ?? '';
            if (_hometownCtrl.text.isEmpty) {
              _hometownCtrl.text = user.hometown ?? '';
            }
            if (_cccdIssueDateCtrl.text.isEmpty && user.cccdIssueDate != null) {
              _cccdIssueDateCtrl.text = DateFormat(
                'dd/MM/yyyy',
              ).format(user.cccdIssueDate!);
            }
            if (_branchNameCtrl.text.isEmpty) {
              _branchNameCtrl.text = 'StayHub ${user.fullName}';
            }
            isKycVerified =
                user.cccdNumber != null && user.cccdNumber!.isNotEmpty;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPending)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        CupertinoIcons.hourglass_bottomhalf_fill,
                        color: Color(0xFFD97706),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Hồ sơ đăng ký Chủ Nhà của bạn đang chờ Admin StayHub xét duyệt. Xin vui lòng chờ trong vòng 24h.',
                          style: TextStyle(
                            color: Color(0xFF92400E),
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const Text(
                'Hồ sơ đăng ký Chủ nhà',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cung cấp và xác minh thông tin doanh nghiệp/cá nhân của bạn để tạo tài khoản Chủ nhà hợp lệ.',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              const Row(
                children: [
                  Icon(
                    CupertinoIcons.person_crop_square_fill,
                    color: LiquidGlassColors.ownerAccent,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'THÔNG TIN ĐỊNH DANH (KYC)',
                    style: TextStyle(
                      color: Color(0xFF374151),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (isKycVerified)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        color: CupertinoColors.systemGreen,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Định danh của bạn đã được xác minh. Dữ liệu này không thể sửa đổi.',
                          style: TextStyle(
                            color: Color(0xFF166534),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              _buildInput(
                controller: _fullNameCtrl,
                placeholder: 'Họ và tên đầy đủ',
                icon: CupertinoIcons.person_fill,
                isReadOnly: isKycVerified,
              ),
              const SizedBox(height: 16),
              _buildInput(
                controller: _cccdCtrl,
                placeholder: 'Số CCCD/CMND',
                icon: CupertinoIcons.creditcard_fill,
                isReadOnly: isKycVerified,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      controller: _cccdIssueDateCtrl,
                      placeholder: 'Ngày cấp',
                      icon: CupertinoIcons.calendar,
                      isReadOnly: isKycVerified,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInput(
                      controller: _hometownCtrl,
                      placeholder: 'Quê quán',
                      icon: CupertinoIcons.map_pin_ellipse,
                      isReadOnly: isKycVerified,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              const Row(
                children: [
                  Icon(
                    CupertinoIcons.briefcase_fill,
                    color: LiquidGlassColors.ownerAccent,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'THÔNG TIN KINH DOANH',
                    style: TextStyle(
                      color: Color(0xFF374151),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildInput(
                controller: _branchNameCtrl,
                placeholder: 'Tên thương hiệu (Ví dụ: Trọ StayHub)',
                icon: CupertinoIcons.building_2_fill,
              ),
              const SizedBox(height: 16),
              _buildInput(
                controller: _phoneCtrl,
                placeholder: 'Số điện thoại kinh doanh',
                icon: CupertinoIcons.phone_fill,
              ),
              const SizedBox(height: 16),
              _buildInput(
                controller: _emailCtrl,
                placeholder: 'Email liên hệ',
                icon: CupertinoIcons.mail_solid,
              ),
              const SizedBox(height: 16),
              _buildInput(
                controller: _addressCtrl,
                placeholder: 'Địa chỉ dãy trọ chính thức',
                icon: CupertinoIcons.location_solid,
              ),
              const SizedBox(height: 16),
              _buildInput(
                controller: _descCtrl,
                placeholder: 'Mô tả quy mô (ví dụ: Quy mô 50 phòng cao cấp)',
                icon: CupertinoIcons.text_alignleft,
              ),
              const SizedBox(height: 32),

              if (!isKycVerified) ...[
                const Row(
                  children: [
                    Icon(
                      CupertinoIcons.doc_on_doc_fill,
                      color: LiquidGlassColors.ownerAccent,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'TÀI LIỆU XÁC MINH',
                      style: TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildFileUploader(
                        title: 'CCCD Mặt Trước',
                        file: _cccdFront,
                        onTap: () =>
                            _pickImage((f) => setState(() => _cccdFront = f)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFileUploader(
                        title: 'CCCD Mặt Sau',
                        file: _cccdBack,
                        onTap: () =>
                            _pickImage((f) => setState(() => _cccdBack = f)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              _buildFileUploader(
                title: 'Giấy phép KD (Tùy chọn)',
                file: _businessLicense,
                onTap: () =>
                    _pickImage((f) => setState(() => _businessLicense = f)),
              ),
              const SizedBox(height: 40),

              // Submit Button
              GestureDetector(
                onTapDown: (_) => _btnAnimCtrl.forward(),
                onTapUp: (_) {
                  unawaited(_btnAnimCtrl.reverse());
                  if (!isPending) unawaited(_submitUpgradeRequest());
                },
                onTapCancel: () => _btnAnimCtrl.reverse(),
                child: ScaleTransition(
                  scale: _btnScaleAnim,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPending
                            ? [AppTheme.kTextMuted, AppTheme.kTextMuted]
                            : [
                                LiquidGlassColors.ownerAccent,
                                const Color(0xFF1A6FD4),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: isPending
                          ? []
                          : [
                              BoxShadow(
                                color: LiquidGlassColors.ownerAccent.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                    ),
                    child: Center(
                      child: Text(
                        isPending ? 'Đang Chờ Xét Duyệt' : 'Gửi Hồ Sơ Xác Thực',
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    bool isReadOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isReadOnly ? const Color(0xFFF9FAFB) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isReadOnly ? const Color(0xFFE5E7EB) : const Color(0xFFD1D5DB),
        ),
        boxShadow: isReadOnly
            ? []
            : [
                const BoxShadow(
                  color: Color(0x05000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: CupertinoTextField(
        controller: controller,
        readOnly: isReadOnly,
        placeholder: placeholder,
        placeholderStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 15,
        ),
        style: TextStyle(
          color: isReadOnly ? const Color(0xFF6B7280) : const Color(0xFF111827),
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        prefix: Padding(
          padding: const EdgeInsets.only(left: 18),
          child: Icon(
            icon,
            color: isReadOnly
                ? const Color(0xFF9CA3AF)
                : LiquidGlassColors.ownerAccent,
            size: 20,
          ),
        ),
        decoration: null,
      ),
    );
  }

  Widget _buildFileUploader({
    required String title,
    required XFile? file,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: file != null
              ? LiquidGlassColors.ownerAccent.withValues(alpha: 0.05)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: file != null
                ? LiquidGlassColors.ownerAccent.withValues(alpha: 0.5)
                : const Color(0xFFE5E7EB),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              file != null
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.cloud_upload_fill,
              color: file != null
                  ? LiquidGlassColors.ownerAccent
                  : const Color(0xFF9CA3AF),
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              file != null ? 'Đã tải lên' : title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: file != null
                    ? LiquidGlassColors.ownerAccent
                    : const Color(0xFF4B5563),
                fontSize: 13,
                fontWeight: file != null ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(Function(XFile?) onPicked) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) onPicked(file);
  }

  Future<void> _submitUpgradeRequest() async {
    final branchName = _branchNameCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final fullName = _fullNameCtrl.text.trim();
    final cccdNumber = _cccdCtrl.text.trim();
    final phoneNumber = _phoneCtrl.text.trim();
    final user = ref.read(authProvider).value;

    bool isKycVerified =
        user?.cccdNumber != null && user!.cccdNumber!.isNotEmpty;

    if (branchName.isEmpty || address.isEmpty) {
      _showDialog(
        'Thiếu thông tin',
        'Vui lòng nhập tên thương hiệu và địa chỉ kinh doanh.',
      );
      return;
    }

    // BUGFIX (data): trước đây không kiểm tra họ tên / CCCD khi chưa xác minh,
    // nên hồ sơ KYC có thể gửi lên với tên rỗng → admin không thể duyệt.
    if (!isKycVerified && (fullName.isEmpty || cccdNumber.isEmpty)) {
      _showDialog(
        'Thiếu thông tin định danh',
        'Vui lòng nhập họ tên và số CCCD/CMND để hoàn tất định danh.',
      );
      return;
    }

    if (!isKycVerified && (_cccdFront == null || _cccdBack == null)) {
      _showDialog(
        'Thiếu tài liệu',
        'Vui lòng tải lên ảnh CCCD mặt trước và mặt sau để hoàn tất định danh.',
      );
      return;
    }

    try {
      unawaited(
        showCupertinoDialog(
          context: context,
          builder: (ctx) =>
              const Center(child: CupertinoActivityIndicator(radius: 16)),
          barrierDismissible: false,
        ),
      );

      if (user == null) throw Exception('Chưa đăng nhập');

      final client = ref.read(apiClientProvider);

      // BUGFIX (data): trước đây gửi 'fullName': branchName → GHI ĐÈ tên thật
      // của người dùng bằng tên thương hiệu, và KHÔNG gửi cccdNumber → backend
      // không lưu được số CCCD, hồ sơ KYC thiếu dữ liệu. Nay gửi đúng:
      // fullName = họ tên thật, cccdNumber = số CCCD, phoneNumber = SĐT.
      final mapData = <String, dynamic>{
        'userId': user.id.toString(),
        'fullName': fullName.isNotEmpty ? fullName : user.fullName,
        'cccdNumber': cccdNumber,
        'phoneNumber': phoneNumber.isNotEmpty ? phoneNumber : user.phoneNumber,
        'businessAddress': address,
        'branchName': branchName,
      };

      await client.post('/v1/users/register-as-owner', data: mapData);

      if (!mounted) return;
      Navigator.pop(context); // close loader

      _showDialog(
        'Gửi Thành Công',
        'Hồ sơ nâng cấp của bạn đã được gửi. Admin StayHub sẽ kiểm tra và phê duyệt trong vòng 24h.',
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showDialog('Lỗi', 'Không thể gửi yêu cầu: $e');
    }
  }

  void _showDialog(String title, String message) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(message, style: const TextStyle(height: 1.4)),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Đóng'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
