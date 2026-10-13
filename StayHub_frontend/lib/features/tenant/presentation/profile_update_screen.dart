import 'package:flutter/cupertino.dart';

import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_background.dart';
import '../../../core/components/glass_button.dart';
import '../../../core/utils/toast_utils.dart';
import '../../auth/application/auth_notifier.dart';
import 'dart:async' show unawaited;

class ProfileUpdateScreen extends ConsumerStatefulWidget {
  final String nextRoute;
  final Map<String, dynamic>? extraData;

  const ProfileUpdateScreen({
    super.key,
    required this.nextRoute,
    this.extraData,
  });

  @override
  ConsumerState<ProfileUpdateScreen> createState() =>
      _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends ConsumerState<ProfileUpdateScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _idCardCtrl = TextEditingController();
  final _cccdIssuePlaceCtrl = TextEditingController();
  final _hometownCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _emergencyContactNameCtrl = TextEditingController();
  final _emergencyContactPhoneCtrl = TextEditingController();
  final _vehicleTypeCtrl = TextEditingController();
  final _licensePlateCtrl = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDateOfBirth;
  DateTime? _selectedCccdIssueDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).value;
      if (user != null) {
        _nameCtrl.text = user.fullName;
        _phoneCtrl.text = user.phoneNumber;
        _emailCtrl.text = user.email ?? '';
        _idCardCtrl.text = user.cccdNumber ?? '';
        _cccdIssuePlaceCtrl.text = user.cccdIssuePlace ?? '';
        _hometownCtrl.text = user.hometown ?? '';
        _occupationCtrl.text = user.occupation ?? '';
        _emergencyContactNameCtrl.text = user.emergencyContactName ?? '';
        _emergencyContactPhoneCtrl.text = user.emergencyContactPhone ?? '';
        _vehicleTypeCtrl.text = user.vehicleType ?? '';
        _licensePlateCtrl.text = user.licensePlate ?? '';
        _selectedGender = user.gender;
        _selectedDateOfBirth = user.dateOfBirth;
        _selectedCccdIssueDate = user.cccdIssueDate;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _idCardCtrl.dispose();
    _cccdIssuePlaceCtrl.dispose();
    _hometownCtrl.dispose();
    _occupationCtrl.dispose();
    _emergencyContactNameCtrl.dispose();
    _emergencyContactPhoneCtrl.dispose();
    _vehicleTypeCtrl.dispose();
    _licensePlateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Validate inputs
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final cccd = _idCardCtrl.text.trim();
    final cccdPlace = _cccdIssuePlaceCtrl.text.trim();
    final hometown = _hometownCtrl.text.trim();
    final occupation = _occupationCtrl.text.trim();
    final emergencyName = _emergencyContactNameCtrl.text.trim();
    final emergencyPhone = _emergencyContactPhoneCtrl.text.trim();
    final vehicleType = _vehicleTypeCtrl.text.trim();
    final licensePlate = _licensePlateCtrl.text.trim();

    if (name.isEmpty ||
        phone.isEmpty ||
        cccd.isEmpty ||
        cccdPlace.isEmpty ||
        hometown.isEmpty ||
        occupation.isEmpty ||
        emergencyName.isEmpty ||
        emergencyPhone.isEmpty ||
        _selectedGender == null ||
        _selectedDateOfBirth == null ||
        _selectedCccdIssueDate == null) {
      _showError('Vui lòng điền đầy đủ tất cả các trường bắt buộc.');
      return;
    }

    if (cccd.length != 12 || int.tryParse(cccd) == null) {
      _showError('Số CCCD phải bao gồm đúng 12 chữ số hợp lệ.');
      return;
    }

    if (phone.length < 10 || phone.length > 11 || int.tryParse(phone) == null) {
      _showError('Số điện thoại không hợp lệ.');
      return;
    }

    if (emergencyPhone.length < 10 ||
        emergencyPhone.length > 11 ||
        int.tryParse(emergencyPhone) == null) {
      _showError('Số điện thoại khẩn cấp không hợp lệ.');
      return;
    }

    try {
      ToastUtils.showLoading(context);
      final user = ref.read(authProvider).value;
      await ref.read(authProvider.notifier).updateProfile({
        'fullName': name,
        'phoneNumber': phone,
        'cccdNumber': cccd,
        'cccdIssuePlace': cccdPlace,
        'hometown': hometown,
        'occupation': occupation,
        'emergencyContactName': emergencyName,
        'emergencyContactPhone': emergencyPhone,
        'vehicleType': vehicleType,
        'licensePlate': licensePlate,
        'gender': _selectedGender!,
        'dateOfBirth': _selectedDateOfBirth!.toIso8601String(),
        'cccdIssueDate': _selectedCccdIssueDate!.toIso8601String(),
        'kycStatus': user?.kycStatus ?? 'UNVERIFIED',
      });
      ToastUtils.hideLoading();

      if (!mounted) return;
      ToastUtils.show(context, 'Cập nhật thông tin thành công!');
      ToastUtils.show(context, 'Cập nhật hồ sơ thành công!');

      // Delay slightly so the toast can be seen
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          context.pushReplacement(widget.nextRoute, extra: widget.extraData);
        }
      });
    } catch (e) {
      ToastUtils.hideLoading();
      if (!mounted) return;
      _showError('Đã xảy ra lỗi khi cập nhật hồ sơ: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Lỗi'),
          content: Text(msg.replaceAll('Exception:', '').trim()),
          actions: [
            CupertinoDialogAction(
              child: const Text('Đóng'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      final user = next.value;
      if (user != null && previous?.value?.kycStatus != user.kycStatus) {
        _nameCtrl.text = user.fullName;
        if (user.cccdNumber != null) _idCardCtrl.text = user.cccdNumber!;
        if (user.cccdIssuePlace != null) {
          _cccdIssuePlaceCtrl.text = user.cccdIssuePlace!;
        }
        if (user.hometown != null) _hometownCtrl.text = user.hometown!;
        if (user.gender != null) _selectedGender = user.gender;
        if (user.dateOfBirth != null) _selectedDateOfBirth = user.dateOfBirth;
        if (user.cccdIssueDate != null) {
          _selectedCccdIssueDate = user.cccdIssueDate;
        }
      }
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final user = authState.value;
    final kycStatus = user?.kycStatus ?? 'UNVERIFIED';
    final hasMissingData =
        user?.cccdNumber == null || user!.cccdNumber!.isEmpty;
    final isKycLocked = kycStatus != 'UNVERIFIED';

    return CupertinoPageScaffold(
      child: LiquidBackground(
        colors: AppTheme.kBackgroundLight,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                CupertinoSliverNavigationBar(
                  largeTitle: const Text(
                    'Cập Nhật Hồ Sơ',
                    style: TextStyle(color: CupertinoColors.black),
                  ),
                  backgroundColor: const Color(0x00000000),
                  border: null,
                  leading: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(
                      CupertinoIcons.back,
                      color: CupertinoColors.black,
                    ),
                    onPressed: () => context.pop(),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const Text(
                        'Để đảm bảo tính pháp lý trước khi ký hợp đồng thuê phòng, bạn bắt buộc phải cung cấp đầy đủ thông tin định danh cá nhân chính xác.',
                        style: TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // KYC Status Banner
                      _buildKycStatusBanner(kycStatus, hasMissingData),
                      const SizedBox(height: 20),

                      _buildTextField(
                        'Họ và tên',
                        _nameCtrl,
                        'Nhập họ và tên đầy đủ',
                        readOnly: isKycLocked && _nameCtrl.text.isNotEmpty,
                        onTap: (isKycLocked && _nameCtrl.text.isNotEmpty)
                            ? () => _showError(
                                'Họ tên đã được đồng bộ từ CCCD, không thể sửa đổi.',
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Số điện thoại',
                        _phoneCtrl,
                        'Nhập số điện thoại liên hệ',
                        isNumber: true,
                        readOnly: true,
                        onTap: () => _showError(
                          'Để thay đổi Số điện thoại, vui lòng xác minh qua mã OTP (Tính năng đang phát triển)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Email',
                        _emailCtrl,
                        'Nhập địa chỉ email',
                        readOnly: true,
                        onTap: () => _showError(
                          'Để thay đổi Email, vui lòng xác minh qua mã OTP (Tính năng đang phát triển)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Số CCCD/CMND',
                        _idCardCtrl,
                        'Nhập 12 số CCCD hợp lệ',
                        isNumber: true,
                        maxLength: 12,
                        readOnly: isKycLocked && _idCardCtrl.text.isNotEmpty,
                        onTap: (isKycLocked && _idCardCtrl.text.isNotEmpty)
                            ? () => _showError(
                                'CCCD đã được hệ thống lưu trữ, không thể thay đổi.',
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Quê quán',
                        _hometownCtrl,
                        'Nhập tỉnh/thành phố quê quán',
                        readOnly: isKycLocked && _hometownCtrl.text.isNotEmpty,
                        onTap: (isKycLocked && _hometownCtrl.text.isNotEmpty)
                            ? () => _showError(
                                'Quê quán đã đồng bộ từ CCCD, không thể sửa đổi.',
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildOccupationSelector(),
                      const SizedBox(height: 16),
                      _buildGenderSelector(
                        isKycLocked && _selectedGender != null,
                      ),
                      const SizedBox(height: 16),
                      _buildDateSelector(
                        isKycLocked && _selectedDateOfBirth != null,
                      ),
                      const SizedBox(height: 32),

                      // Thông tin CCCD
                      const Text(
                        'THÔNG TIN ĐỊNH DANH',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCccdIssueDateSelector(
                        isKycLocked && _selectedCccdIssueDate != null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Nơi cấp CCCD/CMND',
                        _cccdIssuePlaceCtrl,
                        'Ví dụ: Cục cảnh sát QLHC về TTXH',
                        readOnly:
                            isKycLocked && _cccdIssuePlaceCtrl.text.isNotEmpty,
                        onTap:
                            (isKycLocked && _cccdIssuePlaceCtrl.text.isNotEmpty)
                            ? () => _showError(
                                'Nơi cấp đã đồng bộ từ CCCD, không thể sửa đổi.',
                              )
                            : null,
                      ),
                      const SizedBox(height: 32),

                      // Liên hệ khẩn cấp
                      const Text(
                        'LIÊN HỆ KHẨN CẤP (BẮT BUỘC)',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Tên người liên hệ khẩn cấp',
                        _emergencyContactNameCtrl,
                        'Họ tên người thân (Bố, mẹ, v.v)',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'SĐT người liên hệ khẩn cấp',
                        _emergencyContactPhoneCtrl,
                        'Nhập số điện thoại',
                        isNumber: true,
                      ),
                      const SizedBox(height: 32),

                      // Phương tiện (Tùy chọn)
                      const Text(
                        'THÔNG TIN PHƯƠNG TIỆN (TÙY CHỌN)',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Loại xe',
                        _vehicleTypeCtrl,
                        'Ví dụ: Honda AirBlade đỏ',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Biển số xe',
                        _licensePlateCtrl,
                        'Ví dụ: 29A1-123.45',
                      ),
                      const SizedBox(height: 48),
                      GlassButton(
                        text: isLoading
                            ? 'Đang cập nhật...'
                            : 'Cập nhật & Tiếp tục',
                        icon: isLoading
                            ? null
                            : CupertinoIcons.check_mark_circled_solid,
                        color: LiquidGlassColors.tenantAccent,
                        onPressed: isLoading ? null : _submit,
                      ),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKycStatusBanner(String kycStatus, bool hasMissingData) {
    Color bgColor;
    Color iconColor;
    Color textColor;
    IconData icon;
    String title;
    String subtitle;

    switch (kycStatus) {
      case 'APPROVED':
        bgColor = const Color(0xFFD1FAE5);
        iconColor = const Color(0xFF059669);
        textColor = const Color(0xFF064E3B);
        icon = CupertinoIcons.checkmark_seal_fill;
        title = 'Đã xác thực eKYC ✓';
        subtitle = 'Hồ sơ định danh đã được Admin phê duyệt.';
        break;
      case 'PENDING':
        bgColor = const Color(0xFFFEF3C7);
        iconColor = const Color(0xFFD97706);
        textColor = const Color(0xFF92400E);
        icon = CupertinoIcons.clock_fill;
        title = 'Đang chờ xét duyệt...';
        subtitle = 'Hồ sơ đã gửi. Admin sẽ xét duyệt trong 24h làm việc.';
        break;
      default:
        bgColor = const Color(0xFFFEE2E2);
        iconColor = const Color(0xFFDC2626);
        textColor = const Color(0xFF7F1D1D);
        icon = CupertinoIcons.exclamationmark_shield_fill;
        title = 'Chưa xác thực eKYC';
        subtitle = 'Bạn cần xác thực để ký hợp đồng. Nhấn nút bên dưới.';
    }

    if (kycStatus != 'UNVERIFIED' && hasMissingData) {
      bgColor = const Color(0xFFFEE2E2);
      iconColor = const Color(0xFFDC2626);
      textColor = const Color(0xFF7F1D1D);
      icon = CupertinoIcons.exclamationmark_triangle_fill;
      title = 'Lỗi dữ liệu định danh';
      subtitle =
          'Hệ thống bị thiếu thông tin CCCD của bạn. Vui lòng xác thực lại để tự động điền.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (kycStatus == 'UNVERIFIED' ||
              (kycStatus != 'UNVERIFIED' && hasMissingData))
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.push('/ekyc-verification'),
              minimumSize: const Size(0, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  kycStatus == 'UNVERIFIED' ? 'Xác thực' : 'Xác thực lại',
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController ctrl,
    String placeholder, {
    bool isNumber = false,
    int? maxLength,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: CupertinoColors.black,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (readOnly)
              const Icon(
                CupertinoIcons.lock_fill,
                color: Color(0xFF9CA3AF),
                size: 14,
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: readOnly ? onTap : null,
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: readOnly ? const Color(0xFFF3F4F6) : CupertinoColors.white,
            child: CupertinoTextField(
              controller: ctrl,
              placeholder: placeholder,
              keyboardType: isNumber
                  ? TextInputType.number
                  : TextInputType.text,
              maxLength: maxLength,
              readOnly: readOnly,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: null,
              style: TextStyle(
                color: readOnly
                    ? const Color(0xFF6B7280)
                    : CupertinoColors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector(bool isKycLocked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Giới tính',
              style: TextStyle(
                color: CupertinoColors.black,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (isKycLocked)
              const Icon(
                CupertinoIcons.lock_fill,
                color: Color(0xFF9CA3AF),
                size: 14,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildGenderOption('Nam', isKycLocked),
            const SizedBox(width: 16),
            _buildGenderOption('Nữ', isKycLocked),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String value, bool isKycLocked) {
    final isSelected = _selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: isKycLocked
            ? () =>
                  _showError('Giới tính đã đồng bộ từ CCCD, không thể sửa đổi.')
            : () {
                setState(() {
                  _selectedGender = value;
                });
              },
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: isKycLocked
              ? const Color(0xFFF3F4F6)
              : (isSelected
                    ? LiquidGlassColors.tenantAccent.withValues(alpha: 0.15)
                    : CupertinoColors.white),
          border: Border.all(
            color: isSelected
                ? LiquidGlassColors.tenantAccent
                : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected
                    ? CupertinoIcons.checkmark_alt_circle_fill
                    : CupertinoIcons.circle,
                color: isSelected
                    ? LiquidGlassColors.tenantAccent
                    : const Color(0xFF9CA3AF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  color: isKycLocked
                      ? const Color(0xFF6B7280)
                      : (isSelected
                            ? LiquidGlassColors.tenantAccent
                            : CupertinoColors.black),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(bool isKycLocked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ngày sinh',
              style: TextStyle(
                color: CupertinoColors.black,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (isKycLocked)
              const Icon(
                CupertinoIcons.lock_fill,
                color: Color(0xFF9CA3AF),
                size: 14,
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: isKycLocked
              ? () => _showError(
                  'Ngày sinh đã đồng bộ từ CCCD, không thể sửa đổi.',
                )
              : () {
                  _showDatePicker();
                },
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            color: CupertinoColors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDateOfBirth != null
                      ? '${_selectedDateOfBirth!.day.toString().padLeft(2, '0')}/${_selectedDateOfBirth!.month.toString().padLeft(2, '0')}/${_selectedDateOfBirth!.year}'
                      : 'Chọn ngày sinh',
                  style: TextStyle(
                    color: _selectedDateOfBirth != null
                        ? CupertinoColors.black
                        : const Color(0xFF9CA3AF),
                    fontSize: 16,
                  ),
                ),
                const Icon(
                  CupertinoIcons.calendar,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDatePicker() {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (_) => Container(
          height: 250,
          color: const Color.fromARGB(255, 255, 255, 255),
          child: Column(
            children: [
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Xong'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDateOfBirth ?? DateTime(2000, 1, 1),
                  minimumDate: DateTime(1900, 1, 1),
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (val) {
                    setState(() {
                      _selectedDateOfBirth = val;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCccdIssueDateSelector(bool isKycLocked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ngày cấp CCCD/CMND',
              style: TextStyle(
                color: CupertinoColors.black,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (isKycLocked)
              const Icon(
                CupertinoIcons.lock_fill,
                color: Color(0xFF9CA3AF),
                size: 14,
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: isKycLocked
              ? () => _showError(
                  'Ngày cấp đã đồng bộ từ CCCD, không thể sửa đổi.',
                )
              : () {
                  _showCccdIssueDatePicker();
                },
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            color: isKycLocked
                ? const Color(0xFFF3F4F6)
                : CupertinoColors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCccdIssueDate != null
                      ? '${_selectedCccdIssueDate!.day.toString().padLeft(2, '0')}/${_selectedCccdIssueDate!.month.toString().padLeft(2, '0')}/${_selectedCccdIssueDate!.year}'
                      : 'Chọn ngày cấp',
                  style: TextStyle(
                    color: isKycLocked
                        ? const Color(0xFF6B7280)
                        : (_selectedCccdIssueDate != null
                              ? CupertinoColors.black
                              : const Color(0xFF9CA3AF)),
                    fontSize: 16,
                  ),
                ),
                const Icon(
                  CupertinoIcons.calendar,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCccdIssueDatePicker() {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (_) => Container(
          height: 250,
          color: const Color.fromARGB(255, 255, 255, 255),
          child: Column(
            children: [
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Xong'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedCccdIssueDate ?? DateTime.now(),
                  minimumDate: DateTime(1900, 1, 1),
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (val) {
                    setState(() {
                      _selectedCccdIssueDate = val;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOccupationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nghề nghiệp',
          style: TextStyle(
            color: CupertinoColors.black,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showOccupationPicker,
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            color: CupertinoColors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _occupationCtrl.text.isNotEmpty
                      ? _occupationCtrl.text
                      : 'Chọn nghề nghiệp',
                  style: TextStyle(
                    color: _occupationCtrl.text.isNotEmpty
                        ? CupertinoColors.black
                        : const Color(0xFF9CA3AF),
                    fontSize: 16,
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_down,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showOccupationPicker() {
    final occupations = [
      'Sinh viên',
      'Nhân viên VP',
      'Kinh doanh tự do',
      'Công nhân',
      'Nội trợ',
      'Khác',
    ];
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: const Text('Chọn nghề nghiệp'),
          actions: occupations
              .map(
                (occ) => CupertinoActionSheetAction(
                  onPressed: () {
                    setState(() {
                      _occupationCtrl.text = occ;
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    occ,
                    style: const TextStyle(color: CupertinoColors.activeBlue),
                  ),
                ),
              )
              .toList(),
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ),
      ),
    );
  }
}
